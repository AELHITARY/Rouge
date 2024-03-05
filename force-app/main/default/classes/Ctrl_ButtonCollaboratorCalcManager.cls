//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ButtonCollaboratorCalcManager
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/12/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public with sharing class Ctrl_ButtonCollaboratorCalcManager {

    @AuraEnabled
    public static String calculateManager(String recordId) {
        System.debug('### DEBUT Ctrl_ButtonCollaboratorCalcManager.calculateManager');
        System.debug('## recordId: '+recordId);
        try {    
            String result = null;
            Collaborator__c collab = [SELECT Id, Name FROM Collaborator__c WHERE Id = :recordId]; 
            // Récupération du manager
            Collaborator__c manager = Utils_Collaborator.getManager(collab, Date.today());
            if(manager != null) {
                // MAJ du collab
                collab.manager__c = manager.Id;
                result = manager.Name;
                update collab;
            }
            System.debug('### FIN Ctrl_ButtonCollaboratorCalcManager.calculateManager');
            return result;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}