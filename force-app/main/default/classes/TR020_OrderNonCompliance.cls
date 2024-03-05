//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_OrderNonCompliance
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/06/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_OrderNonCompliance {

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les non-conformités de commande
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
    * @description Méthode exécutant les différentes méthode de MAJ pour les non-conformités de commande
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {          
        System.debug('### DEBUT TR020_OrderNonCompliance.applyDataUpdateRules');
        
        System.debug('### FIN TR020_OrderNonCompliance.applyDataUpdateRules');
    }
    
    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les non-conformités commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_OrderNonCompliance : applyStatusUpdateRules');
		
        List<OrderNonCompliance__c> newOrderNonCompliances = (List<OrderNonCompliance__c>)Trigger.new;  
        
        for (OrderNonCompliance__c newONC : newOrderNonCompliances) {
            // Vérification des valeurs pour le changement de statut
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
                System.debug('## Change status for OrderNonCompliance__c: ' + newONC.Id);
                
                //Mise à jour statut
                if(newONC.closeDate__c != null) {
                    newONC.status__c = 'Clôturé';
                } else if(newONC.cancellationDate__c != null) {
                    newONC.status__c = 'Annulé';
                } else if(Date.today() > newONC.expirationDate__c) {
                    newONC.status__c = 'Expiré';
                } else {
                    newONC.status__c = 'En cours';
                }
                System.debug('## OrderNonCompliance__c Status: '+newONC.status__c);
            }
        }
        
        System.debug('### FIN TR020_OrderNonCompliance : applyStatusUpdateRules');
    }
}