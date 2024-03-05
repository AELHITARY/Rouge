//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_AfterSalesService
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/10/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_AfterSalesService {
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les dossiers SAV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les dossiers SAV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_AfterSalesService.applyDataUpdateRules');
        List<AfterSalesService__c> savsList = (List<AfterSalesService__c>)Trigger.new;
        List<String> chantierIds = new List<String>();
        List<chantier__c> chantiersList = new List<chantier__c>();
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();
        
        /** A - Initialisation des données intermédiaires **/
        for(AfterSalesService__c newSAV : savsList) {
            if(newSAV.workSite__c != null) {
                chantierIds.add(newSAV.workSite__c);
            }
        }
        
        if(!chantierIds.isEmpty()) {
            chantiers = new Map<Id, Chantier__c>([SELECT Id, proprietaire__c FROM Chantier__c WHERE Id IN :chantierIds]);
        }
        
        /** B - Application des règles de mise à jour **/
        for(AfterSalesService__c newSAV : savsList) {
            newSAV.OwnerId = Label.system_id_user_kpark;
            
            if(newSAV.account__c == null && chantiers != null && chantiers.get(newSAV.workSite__c) != null) {
                newSAV.account__c = chantiers.get(newSAV.workSite__c).proprietaire__c;
            }
        }
        
        System.debug('### FIN TR020_AfterSalesService.applyDataUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les dossiers SAV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_AfterSalesService.applyStatusUpdateRules');
        
        /** B - Application des règles de mise à jour **/
        for(AfterSalesService__c newSAV : (List<AfterSalesService__c>)Trigger.new) {
            // Recalcul de statut en fonction des cases rattachés
            if(newSAV.newStatusCaseCount__c > 0) {
				System.debug('## SAV status 1');
                newSAV.status__c = Constants.REQUETE_STATUS_NEW;
                newSAV.stageName__c = Constants.REQUETE_STEP_REGISTERED;
            } else if(newSAV.diagnosticStatusCaseCount__c > 0) {
				System.debug('## SAV status 2');
                newSAV.status__c = Constants.REQUETE_STATUS_DIAGNOSTIC;
                newSAV.stageName__c = Constants.REQUETE_STEP_DIAGNOSTIC;
            } else if(newSAV.inProgressStatusCaseCount__c > 0) {
				System.debug('## SAV status 3');
                newSAV.status__c = Constants.REQUETE_STATUS_INPROGRESS;
                newSAV.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
            } else if(newSAV.closedStatusCaseCount__c > 0) {
				System.debug('## SAV status 4');
                newSAV.status__c = Constants.REQUETE_STATUS_CLOSED;
                newSAV.stageName__c = Constants.REQUETE_STEP_CLOSED;
            } else {
				System.debug('## SAV status 5');
                newSAV.status__c = Constants.REQUETE_STATUS_NEW;
                newSAV.stageName__c = Constants.REQUETE_STEP_REGISTERED;
            }
			System.debug('## SAV Status: '+newSAV.status__c);
        }
        
        System.debug('### FIN TR020_AfterSalesService.applyStatusUpdateRules');
    }
}