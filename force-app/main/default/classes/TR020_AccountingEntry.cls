//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_AccountingEntry
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/01/2022
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_AccountingEntry {

    /**
    * @description Méthode pour interdire la suppression d'une écriture comptable pour 4 ans. 
    * Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotDeleteAccountingEntry(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingEntry.cannotDeleteAccountingEntry');
        
        List<AccountingEntry__c> oldAccountingEntries = (List<AccountingEntry__c>)Trigger.old;
        for(AccountingEntry__c oldAccountingEntry : oldAccountingEntries){
            if(Trigger.isDelete && Trigger.isBefore && oldAccountingEntry.isAccountingEntryLocked__c) {
                oldAccountingEntry.addError(Label.accEntries_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_AccountingEntry.cannotDeleteAccountingEntry');
    }

    /**
    * @description Méthode pour vérifier si quand le champ entité unique du compte bancaire est a 
    * vrais toutes les entitées de saisies des pièces comptables associés sont les mêmes !
    * @param userContext contexte utilisateur
    */
    public static void checkUniqueEntity(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingEntry.checkUniqueEntity');
        
        List<String> apIds = new List<String>();
        Map<String,List<AccountingPiece__c>> accEntryIdToAccPiece = new Map<String,List<AccountingPiece__c>>();
        List<AccountingEntry__c> newAccountingEntries = (List<AccountingEntry__c>)Trigger.new;

        for (AccountingEntry__c newAccountingEntry : newAccountingEntries){
            if(newAccountingEntry.Id != null && !apIds.contains(newAccountingEntry.Id)){
                apIds.add(newAccountingEntry.Id);
            }
        }
        
        System.debug('## apIds: ' + apIds);
        
        if(!apIds.isEmpty()){

            List<AccountingPiece__c> allAccPiece = [SELECT Id, inputEntity__c, accountingEntry__c FROM AccountingPiece__c WHERE accountingEntry__c IN :apIds];
            
            Map<Id,AccountingEntry__c> accEntriesInfo = new Map<Id,AccountingEntry__c>([SELECT Id, entityBankAccount__r.singleEntity__c FROM AccountingEntry__c WHERE Id IN :apIds]);
            
    
            for(AccountingPiece__c accPiece : allAccPiece){
                List<AccountingPiece__c> accPieces = new List<AccountingPiece__c>();
                
                if(accEntryIdToAccPiece.get(accPiece.accountingEntry__c) != null){
                    accPieces = accEntryIdToAccPiece.get(accPiece.accountingEntry__c);
                }
    
                accPieces.add(accPiece);
                accEntryIdToAccPiece.put(accPiece.accountingEntry__c, accPieces);
            }
    
            for (AccountingEntry__c newAccEntry : newAccountingEntries){
                if(!accEntriesInfo.isEmpty() && accEntriesInfo.get(newAccEntry.Id) != null && !accEntryIdToAccPiece.isEmpty() && accEntryIdToAccPiece.get(newAccEntry.Id) != null){
                    for (AccountingPiece__c accPiece : accEntryIdToAccPiece.get(newAccEntry.Id)){
                        if(accEntriesInfo.get(newAccEntry.Id).entityBankAccount__r.singleEntity__c && newAccEntry.inputEntity__c != accPiece.inputEntity__c){
                            newAccEntry.addError(Label.accEntries_msg_SingleEntity);
                        }
                    }
                }
            } 
        }
        
        System.debug('### FIN TR020_AccountingEntry.checkUniqueEntity');
    }
}