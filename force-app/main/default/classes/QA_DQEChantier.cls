//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_DQEChantier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.4
//-- * 1.4 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.2 : Modification du timeout à 120 secondes + formatage erreur
//-- * 1.3 : Gestion de la synchronisation des comptes via batch (CRM-954)
//-- --------------------------------------------------------------------------------- --
public class QA_DQEChantier implements Queueable, Database.AllowsCallouts {
    public List<Chantier__c> chantiers;
    public String actionType;
    public Boolean isBatch;
    public BatchHistory__c batchHistorique;
    private static final Decimal DEDUPSYNCHROMAX = PropertiesUtils.getIntegerValue('dqe.synchro.nbTentatives', 3);

    /**
    * @description Constructeur
    * @param chantierList List des chantiers
    * @param actionRequise Type d'action pour les chantiers (ajout, suppression, mise à jour)
    * @return Contexte du job Queueable
    */
    public QA_DQEChantier(List<Chantier__c> chantierList, String actionRequise, Boolean isBatchValue, BatchHistory__c batchHistoriqueActuel) {
        chantiers = chantierList;
        actionType = actionRequise; // Add, Update ou Delete
        isBatch = isBatchValue;
        batchHistorique = batchHistoriqueActuel;
    }

    /**
    * @description Lancement de l'appel WebService vers DQE pour mettre à jour la base de données DQE
    * @param context Contexte du job Queueable
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_DQEChantier');
        List<Chantier__c> chantierList = new List<Chantier__c>();       
        List<Chantier__c> errorList = new List<Chantier__c>(); 
        Integer successCount = 0;    

        try {
            String dedupDQEAddress = PropertiesUtils.getStringValue('dqe.dedup.chantier.server', '');
            if(actionType.equalsIgnoreCase('Delete'))
                chantierList = chantiers;
            else {
                chantierList = [SELECT Id, codePostal__c, rue__c, ville__c, complementAdresse__c, etage__c, 
                                proprietaire__c,autreProprietaire__c, aSynchroniserDQE__c, erreurSynchronisationDQE__c 
                                FROM Chantier__c WHERE Id IN :chantiers];
            }

            for(Chantier__c cha : chantierList){
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                String endPoint = dedupDQEAddress;
                HttpResponse response;
                if(actionType == 'Add'){
                    endPoint += '/DQEAddCandidate/';
                } else if(actionType == 'Update') {
                    endPoint += '/DQEUpdateCandidate/';
                } else if(actionType == 'Delete') {
                    endPoint += '/DQEDeleteCandidate/';
                }
                endPoint     += '?CODEPOSTAL__C='       + Utils.replaceNullURL(cha.codePostal__c);
                endPoint     += '&RUE__C='              + Utils.replaceNullURL(cha.rue__c);
                endPoint     += '&VILLE__C='            + Utils.replaceNullURL(cha.ville__c);
                endPoint     += '&COMPLEMENTADRESSE__C='+ Utils.replaceNullURL(cha.complementAdresse__c);
                endPoint     += '&ETAGE__C='            + Utils.replaceNullURL(Integer.valueOf(cha.etage__c));
                endPoint     += '&ID='                  + cha.Id;
                endPoint     += '&PROPRIETAIRE__C=';        // CRM-891 / JMU / 05/12/2016 : Champ qui n'est plus utilisé dans la détection
                endPoint     += '&AUTREPROPRIETAIRE__C=';   // CRM-891 / JMU / 05/12/2016 : Champ qui n'est plus utilisé dans la détection              
                req.setEndpoint(endPoint);
                req.setMethod('GET');
                req.setTimeout(120000); // en millisecondes
                System.debug('## End Point : '+ endPoint);
                try {
                    if(!Test.isRunningTest())
                        response = h.send(req); // Send the request, and return a response
                    System.debug('## Reponse : '+ response.getBody());
                    // Erreur synchro
                    if(response.getBody()!='true') throw new KubeException();
                    else if(cha.aSynchroniserDQE__c != null && cha.aSynchroniserDQE__c != 0){
						// Suppression erreur synchro
                        cha.aSynchroniserDQE__c = null;
                        cha.erreurSynchronisationDQE__c = null;
                        errorList.add(cha);
                        successCount++;
                    }
                } catch(Exception e) {
                    // Mise à jour champ erreur du compte
                    if(cha.aSynchroniserDQE__c == null && !isBatch) 
                        cha.aSynchroniserDQE__c = DEDUPSYNCHROMAX;
                    else if(cha.aSynchroniserDQE__c != 0 && isBatch) 
                        cha.aSynchroniserDQE__c = (cha.aSynchroniserDQE__c==null) ? DEDUPSYNCHROMAX-1 : cha.aSynchroniserDQE__c - 1;
                    if(!Test.isRunningTest()) cha.erreurSynchronisationDQE__c = 'URL: '+endPoint+'\n'+e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                    if(batchHistorique != null) {
                        batchHistorique.nombreTraite__c = successCount;
                        batchHistorique.traceErreurs__c +=' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                        batchHistorique.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
                    }
                    errorList.add(cha);
                    // Envoi email
                    e.setMessage(formatError(e.getMessage(),endPoint,response,cha));
                    EmailUtils.reportException('[KUBE] Dedup Chantier : Erreur de synchronisation avec le serveur DQE', e);
                }
            }
            if(batchHistorique != null) update batchHistorique;
            // Mise à jour des chantiers (erreur)
            if(!errorList.isEmpty())  
                update errorList;
            // Mise à jour de l'historique du batch (dans le cas d'un batch)
            if(isBatch && batchHistorique != null){
                batchHistorique.nombreTraite__c = successCount;
                update batchHistorique;
            }
            System.debug('### FIN QA_DQEChantier');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            if(batchHistorique != null) {
                batchHistorique.traceErreurs__c +=' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                batchHistorique.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
                update batchHistorique;
            }
            EmailUtils.reportException('[KUBE] Dedup Chantier : Erreur générique de synchronisation avec le serveur DQE', e);
        }
    }
    
    /**
    * @description Formatage du message d'erreur
    * @param erreur Message d'erreur de l'exception
    * @param url URL de l'appel au WS
    * @param response Réponse de la requête HTTP
    * @param cha Chantier
    * @return String Le message d'erreur
    */
    public static String formatError(String erreur,String url,HttpResponse response,Chantier__c cha) {
        String msg='\n\nErreur: '+erreur;
        msg+='\n\nURL: '+url;
        if(response!=null) {
            msg+='\nStatut de la requête HTTP: '+response.getStatus();
            msg+='\nCode HTTP: '+response.getStatusCode();
            msg+='\nRéponse HTTP: '+response.getBody();
        }
        msg+='\n\nValeurs envoyés: ';
        msg+='\nCODEPOSTAL__C= '       + cha.codePostal__c;
        msg+='\nRUE__C= '              + cha.rue__c;
        msg+='\nVILLE__C= '            + cha.ville__c;
        msg+='\nCOMPLEMENTADRESSE__C= '+ cha.complementAdresse__c;
        msg+='\nETAGE__C= '            + Integer.valueOf(cha.etage__c);
        msg+='\nID= '                  + cha.Id;
        return msg;
    }
}