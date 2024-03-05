//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_OdigoSendCallback 
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 18/10/2021
//-- Version     : 1.1
//-- * 1.2 : Modification pour appels des API REST Odigo
//-- * 1.1 - KPKCRM_RQM-84 : Nouveau questionnaire SATContact
//-- * 1.0 - RQM-74 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_OdigoSendCallback implements Queueable, Database.AllowsCallouts {
    public List<String> objectsId;
    public String odigoCampaignName;
    
    /**
    * @description Constructeur
    * @param objectsId Liste des Ids des contrats
    * @param odigoCampaignName Nom de la campagne d'appels sortant pour ajouter le callback
    * @return QA_OdigoSendCallback Classe QA_OdigoSendCallback 
    */
    public QA_OdigoSendCallback (List<String> objectsId, String odigoCampaignName) {
        this.objectsId= objectsId;
        this.odigoCampaignName= odigoCampaignName;
    }
    
    /**
    * @description Fonction principal d'exécution du batch Queueable
    * Méthode asynchrone pour faire appel au WS WebCallback d'Odigo pour envoyer une tâche d'appel (callback)
    * @param context Context du batch
    */
    public void execute(QueueableContext context) {
        system.debug('### START QA_OdigoSendCallback');   
        Integer ODIGO_CAMPAIGNID;
        List<Utils_Odigo.WebCallBackContactList> callbackList = new List<Utils_Odigo.WebCallBackContactList>();
        List<SObject> objectsList = new List<SObject>();
        List<SObject> objectsToUpdate = new List<SObject>();
        Map<String,Account> accMap = new Map<String,Account>();

        if((Limits.getCallouts() + 2) > Limits.getLimitCallouts()) { // S'assure que les 2 appels WS seront traitées
          throw new KubeException('ERREUR # Callback non transmis (Limite(s) atteinte(s): ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts() + ') !');
        }

        Id objId = objectsId[0];
        Schema.SObjectType objectType = objId.getSObjectType();
        String objectAPIName = String.valueOf(objectType);
        
        if(objectAPIName == 'KContrat__c'){
            // Récupération info des contrats et des comptes
            List<KContrat__c> contratsList = new List<KContrat__c>();
            contratsList = [SELECT Id, compte__c, compte__r.Id, compte__r.autreTelephone__c, compte__r.Phone, compte__r.telephoneDomicile__c, compte__r.telephoneMobile__c, 
                                compte__r.IsPersonAccount, dateEnvoiOdigoSATCLI__c FROM KContrat__c WHERE Id IN :objectsId];
            objectsList = contratsList;
            for(KContrat__c con : contratsList){
                accMap.put(con.Id, con.compte__r);
            }
        } else if(objectAPIName == 'Opportunity'){
            // Récupération info des projets et des comptes
            List<Opportunity> opportunitiesList = new List<Opportunity>();
            opportunitiesList = [SELECT Id, AccountId, Account.autreTelephone__c, Account.Phone, Account.telephoneDomicile__c, Account.telephoneMobile__c, 
                                    Account.IsPersonAccount FROM Opportunity WHERE Id IN :objectsId];
            objectsList = opportunitiesList;
            for(Opportunity opp : opportunitiesList){
                accMap.put(opp.Id, opp.Account);
            }
        } else {
            // Exception
            throw new KubeException('ERREUR # Objet non pris en charge');
        }

        try {   
            if(!objectsList.isEmpty()) {
                 
                // Récupération de l'ID de la campagne d'appels sortants 
                if(!Test.isRunningTest()) {
                    Integer campaignId = Utils_Odigo.getCampaignIdByLabel(odigoCampaignName);
                    if(campaignId == null) {
                        throw new KubeException('ERREUR # Problème lors de la récupération de l\'ID de la campagne Odigo');
                    }
                    ODIGO_CAMPAIGNID = campaignId;
                } 
                System.debug('## ID: '+ODIGO_CAMPAIGNID);  

                // Création des callback et envoi à Odigo
                for(SObject obj : objectsList) { 
                    // Configuration du callback       
                    Utils_Odigo.WebCallBackContactList callBack = Utils_Odigo.configureCallback(accMap.get(obj.Id)); 
                    // Si callback possède un numéro de téléphone (différent de null)
                    if (callBack!=null) {         
                        callbackList.add(callBack);
                        
                        // Mise à jour des champs du record
                        if(objectAPIName == 'KContrat__c') {
                            obj.put('dateEnvoiOdigoSATCLI__c',System.now());
                        }
                        objectsToUpdate.add(obj);
                    }
                }
                System.debug('## Taille callback: '+callbackList.size());  

                // Envoi de la campagne dans odigo
                if(!callbackList.isEmpty()){
                    if(!Test.isRunningTest() && Utils_Odigo.ODIGO_ACTIVE) {                     
                        System.debug('## Envoi à ODIGO');  
                        String retWS = Utils_Odigo.uploadCallback(ODIGO_CAMPAIGNID, callbackList);
                        if(retWS != 'OK') {
                            System.debug('ERREUR # Problème lors de l\'envoi des callbacks dans la campagne: '+retWS);
                            //throw new KubeException('ERREUR # Problème lors de l\'envoi des callbacks dans la campagne. Code erreur Odigo : '+retWS.errorCode);
                        }
                    } 
                }
                // Mise à jour des contrats
                if (!objectsToUpdate.isEmpty()) {                    
                    Database.SaveResult[] srList = Database.update(objectsToUpdate, false); 
                    /*for (Database.SaveResult sr : srList) {
                        if (!sr.isSuccess()) {
                            // Erreurs      
                            system.debug('ERREUR # Contrat Id: '+sr.getId());          
                            for(Database.Error err : sr.getErrors()) {                  
                                system.debug(+ '\n' +err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }*/
                }                 
            } 
            System.debug('### FIN QA_OdigoSendCallback');   
        } catch(Exception e) {
            //system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            //throw e;
            EmailUtils.reportException('[KUBE] Relance Odigo '+odigoCampaignName+': Erreur lors de l\'appel API', e);
        }
    }    
}