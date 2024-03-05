//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_DQEAccount
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/07/2018
//-- Version     : 1.4
//-- * 1.4 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.2 : Modification du timeout à 120 secondes + formatage erreur
//-- * 1.3 : Gestion de la synchronisation des comptes via batch (CRM-954)
//-- --------------------------------------------------------------------------------- --
public class QA_DQEAccount implements Queueable, Database.AllowsCallouts {
    public List<Account> accounts;
    public String actionType;
    public Boolean isBatch;
    public BatchHistory__c batchHistorique;
    private static final Decimal DEDUPSYNCHROMAX = PropertiesUtils.getIntegerValue('dqe.synchro.nbTentatives', 3);

    /**
    * @description Constructeur
    * @param accList List des comptes
    * @param actionRequise Type d'action pour les comptes (ajout, suppression, mise à jour)
    * @return Contexte du job Queueable
    */
    public QA_DQEAccount(List<Account> accList, String actionRequise, Boolean isBatchValue, BatchHistory__c batchHistoriqueActuel) {
        accounts = accList;
        actionType = actionRequise; // Add, Update ou Delete
        isBatch = isBatchValue; // true si batch de synchronisation
        batchHistorique = batchHistoriqueActuel;
    }

    /**
    * @description Lancement de l'appel WebService vers DQE pour mettre à jour la base de données DQE
    * @param context Contexte du job Queueable
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_DQEAccount');
        List<Account> accList = new List<Account>();
        List<Account> errorList = new List<Account>();
        Integer successCount = 0;
        
        try {
            String dedupDQEAddressComptePerso = PropertiesUtils.getStringValue('dqe.dedup.comptePerso.server', '');
            String dedupDQEAddressComptePro = PropertiesUtils.getStringValue('dqe.dedup.comptePro.server', '');
            if(actionType.equalsIgnoreCase('Delete'))
                accList = accounts;
            else {
                accList = [SELECT Id, codePostal__c, LastName, FirstName, rue__c, ville__c, Name, PersonEmail, 
                                PersonHomePhone, PersonMobilePhone, Phone, Fax, isPersonAccount, 
                                aSynchroniserDQE__c, erreurSynchronisationDQE__c
                                FROM Account WHERE Id IN :accounts];
            }

            for(Account acc : accList){
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                HttpResponse response;
                String endPoint = acc.isPersonAccount ? dedupDQEAddressComptePerso : dedupDQEAddressComptePro;
                if(actionType.equalsIgnoreCase('Add')){
                    endPoint += '/DQEAddCandidate/';
                } else if(actionType.equalsIgnoreCase('Update')) {
                    endPoint += '/DQEUpdateCandidate/';
                } else if(actionType.equalsIgnoreCase('Delete')) {
                    endPoint += '/DQEDeleteCandidate/';
                }
                endPoint     += '?CODEPOSTAL__C='       + Utils.replaceNullURL(acc.codePostal__c);
                endPoint     += '&RUE__C='              + Utils.replaceNullURL(acc.rue__c);
                endPoint     += '&VILLE__C='            + Utils.replaceNullURL(acc.ville__c);
                if(acc.isPersonAccount){
                    endPoint += '&LASTNAME='            + Utils.replaceNullURL(acc.LastName);
                    endPoint += '&FIRSTNAME='           + Utils.replaceNullURL(acc.FirstName);
                    endPoint += '&PERSONEMAIL='         + Utils.replaceNullURL(acc.PersonEmail);
                    endPoint += '&PERSONHOMEPHONE='     + Utils.replaceNullURL(acc.PersonHomePhone);
                    endPoint += '&PERSONMOBILEPHONE='   + Utils.replaceNullURL(acc.PersonMobilePhone);
                } else {
                    endPoint += '&NAME='                + Utils.replaceNullURL(acc.Name);
                    endPoint += '&PHONE='               + Utils.replaceNullURL(acc.Phone);
                    endPoint += '&FAX='                 + Utils.replaceNullURL(acc.Fax);
                }
                endPoint     += '&ID='                  + acc.Id;
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
                    else if(acc.aSynchroniserDQE__c != null && acc.aSynchroniserDQE__c != 0){
                        // Suppression erreur synchro
                        acc.aSynchroniserDQE__c = null;
                        acc.erreurSynchronisationDQE__c = null;
                        errorList.add(acc);
                        successCount++;
                    }
                } catch(Exception e) {
                    // Mise à jour champ erreur du compte
                    if(acc.aSynchroniserDQE__c == null && !isBatch) 
                        acc.aSynchroniserDQE__c = DEDUPSYNCHROMAX;
                    else if(acc.aSynchroniserDQE__c != 0 && isBatch) 
                        acc.aSynchroniserDQE__c = (acc.aSynchroniserDQE__c==null) ? DEDUPSYNCHROMAX-1 : acc.aSynchroniserDQE__c - 1;
                    if(!Test.isRunningTest()) acc.erreurSynchronisationDQE__c = 'URL: '+endPoint+'\n'+e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                    if(batchHistorique != null) {
                        batchHistorique.nombreTraite__c = successCount;
                        batchHistorique.traceErreurs__c +=' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                        batchHistorique.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
                    }
                    errorList.add(acc);
                    // Envoi email
                    e.setMessage(formatError(e.getMessage(),endPoint,response,acc));
                    EmailUtils.reportException('[KUBE] Dedup Account : Erreur de synchronisation avec le serveur DQE', e);
                }
            }
            if(batchHistorique != null) update batchHistorique;
            // Mise à jour des comptes (erreur)
            if(!errorList.isEmpty())  
                update errorList;
            // Mise à jour de l'historique du batch (dans le cas d'un batch)
            if(isBatch && batchHistorique != null){
                batchHistorique.nombreTraite__c = successCount;
                update batchHistorique;
            }
            System.debug('### FIN QA_DQEAccount');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            if(batchHistorique != null)  {
                batchHistorique.traceErreurs__c +=' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString();
                batchHistorique.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
                update batchHistorique;
            }
            EmailUtils.reportException('[KUBE] Dedup Account : Erreur générique de synchronisation avec le serveur DQE', e);
        }
    }
    
    /**
    * @description Formatage du message d'erreur
    * @param erreur Message d'erreur de l'exception
    * @param url URL de l'appel au WS
    * @param response Réponse de la requête HTTP
    * @param acc Compte
    * @return String Le message d'erreur
    */
    public static String formatError(String erreur,String url,HttpResponse response,Account acc) {
        String msg='\n\nErreur: '+erreur;
        msg+='\n\nURL: '+url;
        if(response!=null) {
            msg+='\nStatut de la requête HTTP: '+response.getStatus();
            msg+='\nCode HTTP: '+response.getStatusCode();
            msg+='\nRéponse HTTP: '+response.getBody();
        }
        msg+='\n\nValeurs envoyés: ';
        msg+='\nCODEPOSTAL__C= '+acc.codePostal__c;
        msg+='\nRUE__C= '+acc.rue__c;
        msg+='\nVILLE__C= '+acc.ville__c;
        if(acc.isPersonAccount){
            msg+='\nLASTNAME= '+acc.LastName;
            msg+='\nFIRSTNAME= '+acc.FirstName;
            msg+='\nPERSONEMAIL= '+acc.PersonEmail;
            msg+='\nPERSONHOMEPHONE= '+acc.PersonHomePhone;
            msg+='\nPERSONMOBILEPHONE= '+acc.PersonMobilePhone;
        } else {
            msg+='\nNAME= '+acc.Name;
            msg+='\nPHONE= '+acc.Phone;
            msg+='\nFAX= '+acc.Fax;
        }
        msg+='\nID= '+ acc.Id;
        return msg;
    }
}