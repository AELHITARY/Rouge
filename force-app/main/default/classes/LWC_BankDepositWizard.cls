//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_BankDepositWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 12/04/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_BankDepositWizard {
    
    /**
    * @description Récupération de la liste des commandes client
    * @param inputEntityId Id de l'entité de saisie
    * @param bankAccountId Id de la banque
    * @param accountingDate Date comptable
    * @param applyDueDateFilter Vrai si le filtre sur la date d'échéance doit être appliqué
    * @param applyEntityFilter Vrai si le filtre sur l'entité doit être appliqué
    * @return Liste des pièces
    */
    @AuraEnabled(cacheable = true)
    public static List<AccountingPiece__c> getAccountingPieces(String inputEntityId, String bankAccountId, Date accountingDate,
                                                                Boolean applyDueDateFilter, Boolean applyEntityFilter){
       System.debug('### DEBUT LWC_BankDepositWizard.getAccountingPieces'); 
       System.debug('## inputEntityId: '+inputEntityId); 
       System.debug('## bankAccountId: '+bankAccountId); 
       System.debug('## accountingDate: '+accountingDate); 
       System.debug('## applyDueDateFilter: '+applyDueDateFilter); 
       System.debug('## applyEntityFilter: '+applyEntityFilter); 
       List<AccountingPiece__c> result = new List<AccountingPiece__c>();

        try {
            String receiptRTId = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPT_RT);    
            // Construction requête SOQL
            String soqlQuery = 'SELECT  Id, Name, account__c, accountingDate__c, amount__c, paymentMethod__c, pieceDate__c, dueDate__c,';
            soqlQuery += ' paymentMethod__r.Name, account__r.Name, externalReference__c, externalBank__c';
            soqlQuery += ' FROM AccountingPiece__c WHERE RecordTypeId = :receiptRTId AND accountingDate__c = null';
            soqlQuery += ' AND (entityBankAccount__c = :bankAccountId OR entityBankAccount__c = null)';
            soqlQuery += ' AND status__c = \'En cours\'';
            soqlQuery += ' AND pieceDate__c > 2022-03-23'; // CORRECTIF TEMPORAIRE
            soqlQuery += ' AND paymentMethod__r.Name != \'VIREMENT BANCAIRE\'';
            if(applyDueDateFilter) {
                soqlQuery += ' AND dueDate__c <= :accountingDate';
            }
            if(applyEntityFilter) {
                soqlQuery += ' AND inputEntity__c = :inputEntityId';
            }
            soqlQuery += ' ORDER BY Name';
            // Limite à 100 pour les tests pour éviter erreur de limites Salesforce
            if(Test.isRunningTest()) {
                soqlQuery += ' LIMIT 100';
            }
            // Exécution
            System.debug('## SOQL Query: '+soqlQuery);
            result = Database.query(soqlQuery);
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_BankDepositWizard.getAccountingPieces'); 
        return result;
    }
    
    /**
    * @description Récupération de la bankAccountId
    * @param inputEntityId Id de l'entité
    * @return bankAccountId
    */
    @AuraEnabled(cacheable = true)
    public static String getBankAccount(String inputEntityId) {
        System.debug('### DEBUT LWC_BankDepositWizard.getBankAccount'); 
        System.debug('## inputEntityId: '+inputEntityId);
        String bankAccId = null;
        Integer nbBankAccount = 0;
        String bankAccountId;
        
        for(BankAccountVisibility__c bkvisibility : [SELECT Id, startDate__c, endDate__c, bankAccount__c, entity__c, bankAccount__r.Name 
                                                        FROM BankAccountVisibility__c WHERE entity__c =: inputEntityId 
                                                        AND startDate__c <= TODAY AND (endDate__c > TODAY OR endDate__c = null)]) 
        {
            nbBankAccount++;        
            bankAccountId = bkvisibility.bankAccount__c;   
            System.debug('## Potential bankAccountId: '+bankAccountId);
        }                    
        // Alimentation du compte bancaire seulement s'il existe un seul compte bancaire actif                      
        if(nbBankAccount == 1) {
            System.debug('## Update bank account by order entity: '+bankAccountId);
            bankAccId = bankAccountId;
        } else if(nbBankAccount > 1) {
            bankAccId = 'MoreThanOne';
        }
        System.debug('### FIN LWC_BankDepositWizard.getBankAccount'); 
        return bankAccId;
    }  
    
    /**
    * @description Récupération de la bankAccountName
    * @param bankAccountId Id de la banque
    * @return bankAccountId
    */
    @AuraEnabled(cacheable = true)
    public static String getBankAccountName(String bankAccountId) {
        Referencial__c bankAccount = [SELECT Id, Name FROM Referencial__c WHERE id =: bankAccountId];
        String bankAccountName = bankAccount.Name;
        return bankAccountName;
    }   

    /**
    * @description Création des pièces comptables
    * @param selectedPieceRecordsId Liste des ids des pièces à mettre à jour
    * @param bankAccountId Id de la banque
    * @param inputEntityId Id de l'entité
    * @param accountingDate Date comptable
    * @return Id du PDF
    */
    @AuraEnabled
    public static String updateAccountingPieces(List<String> selectedPieceRecordsId, String bankAccountId, String inputEntityId, Date accountingDate, String bankRemittanceNumber) {
        System.debug('### DEBUT LWC_BankDepositWizard.updateAccountingPieces'); 
        System.debug('## selectedPieceRecordsId: '+ selectedPieceRecordsId);
        System.debug('## bankAccountId: '+ bankAccountId);
        System.debug('## accountingDate: '+ accountingDate);
        System.debug('## inputEntityId: '+inputEntityId);
        
        String result = null; 
        List<AccountingPiece__c> piecesToUp = new List<AccountingPiece__c>();

        Savepoint sp = Database.setSavepoint();

        try{
            if(!selectedPieceRecordsId.isEmpty() || Test.isRunningTest()){
                // Mise à jour des pieces
                for(String accPieceId : selectedPieceRecordsId) {
                    AccountingPiece__c accPiece = new AccountingPiece__c(
                        Id = accPieceId,
                        entityBankAccount__c = bankAccountId,
                        accountingDate__c = accountingDate,
                        bankRemittanceNumber__c = bankRemittanceNumber,
                        bankRemittanceDate__c = System.now()
                    );
                    piecesToUp.add(accPiece);
                    System.debug('## Accounting Piece: '+ accPiece);
                }

                if(!piecesToUp.isEmpty()) {
                    update piecesToUp;
                }

                // Création du PDF
                result = createDocumentPDF(selectedPieceRecordsId, bankAccountId, inputEntityId, accountingDate, bankRemittanceNumber);
            }
        }
        catch(Exception e) {
            Database.rollback(sp); // Rollback des modifications
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_BankDepositWizard.updateAccountingPieces');
        return result;
         
    }

    /**
    * @description Fonction pour générer le document PDF 
    * @param selectedPieceRecordsId Liste des ids des pièces à mettre à jour
    * @param bankAccountId Id de la banque
    * @param inputEntityId Id de l'entité
    * @param accountingDate Date comptable
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String createDocumentPDF(List<String> selectedPieceRecordsId, String bankAccountId, String inputEntityId, Date accountingDate, String bankRemittanceNumber) {
        System.debug('### DEBUT LWC_BankDepositWizard.createDocumentPDF');
        String result;
        try {
            // Init
            String idsParameter = String.join(selectedPieceRecordsId, ',');           
            // RBQ / <compte bancaire> / <date comptable> / <entité saisie>
            List<Account> entityList = [SELECT Id, Name FROM Account WHERE Id = :inputEntityId LIMIT 1];
            List<Referencial__c> bankList = [SELECT Id, Name FROM Referencial__c WHERE Id = :bankAccountId LIMIT 1]; 
            //String dateFormated = DateTime.newInstance(accountingDate.year(),accountingDate.month(),accountingDate.day()).format('yyyy/MM/dd');
            String dateFormated = System.NOW().format('yyyy/MM/dd');
            String filename = '';
            if(!String.isBlank(bankRemittanceNumber) && bankRemittanceNumber != null && bankRemittanceNumber != 'undefined'){
                filename = 'RBQ / '+bankList[0].Name+' / '+dateFormated+' / '+entityList[0].Name+' / '+bankRemittanceNumber+'.pdf';
            } else {
                filename = 'RBQ / '+bankList[0].Name+' / '+dateFormated+' / '+entityList[0].Name+'.pdf';   
            }
            System.debug('## idsParameter: '+idsParameter);
            System.debug('## filename: '+filename);
            // Creation PDF
            Blob documentBlob;            
            PageReference pagePDF = Page.VF_BankDepositPDF;
            pagePDF.getParameters().put('ids', idsParameter);
            pagePDF.getParameters().put('brm', bankRemittanceNumber);
            if (Test.isRunningTest()) {
                documentBlob = Blob.valueof('test');
            } else {
                documentBlob = pagePDF.getContentAsPDF();
            }
            // Lien du PDF avec le compte bancaire
            result = Utils_APIMerkure.createContentDocument(bankAccountId, filename, documentBlob, '');  
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_BankDepositWizard.createDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}