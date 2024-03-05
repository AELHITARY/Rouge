//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_AccountingClosureWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 24/07/2023
//-- Modifie le  : 24/07/2023
//-- Version     : 1.1
//-- * 1.1 - Evolutions demande #1246
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_AccountingClosureWizard {
    
    /**
    * @description Récupération de la liste des dépôts
    * @return Liste des dépôts
    */
    @AuraEnabled(Cacheable = true)
    public static List<Account> getDepotsAccounts(){
        System.debug('### DEBUT LWC_AccountingClosureWizard.getDepotsAccounts'); 
        List<Account> result = new List<Account>();

        // Récupération des dépôts (Account)
        Date oneYearOld = Date.today().addYears(-1);

        for(Account acc : [SELECT Id, Name, stageName__c, endDate__c
                        FROM Account WHERE RecordType.DeveloperName = :Constants.ACCOUNT_ENTITY_RT 
                                        AND entityType__r.Name = 'Dépôt'
                                        AND (stageName__c = 'En cours' 
                                            OR (stageName__c = 'Désactivé' AND endDate__c > :oneYearOld)
                                        )
                                        ORDER BY Name ASC]) {
            result.add(acc);
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_AccountingClosureWizard.getDepotsAccounts'); 
        return result;
    }

    /**
    * @description Récupération de la liste des comptes fournisseurs
    * @return Liste des Comptes
    */
    @AuraEnabled(Cacheable = true)
    public static List<Account> getProviderAccounts(){
        System.debug('### DEBUT LWC_AccountingClosureWizard.getProviderAccounts'); 
        List<Account> result = new List<Account>();

        // Récupération des dépôts (Account)
        Date oneYearOld = Date.today().addYears(-1);

        for(Account acc : [SELECT Id, Name, stageName__c, endDate__c
                        FROM Account WHERE RecordType.DeveloperName = :Constants.ACCOUNT_PROVIDER_RT 
                                        AND (stageName__c = 'En cours' 
                                            OR (stageName__c = 'Désactivé' AND endDate__c > :oneYearOld)
                                        )
                                        ORDER BY Name ASC]) {
            result.add(acc);
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_AccountingClosureWizard.getProviderAccounts'); 
        return result;
    }

    /**
    * @description Récupération de la date du jour ouvré précédant la date du jour
    * @return Liste des Comptes
    */
    @AuraEnabled(Cacheable = true)
    public static Date getPreviousBusinessDayDate(){
        System.debug('### DEBUT LWC_AccountingClosureWizard.getPreviousBusinessDayDate'); 
        Date result = Date.today().addDays(-1);

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        if(bh !=null){
            while(!BusinessHours.isWithin(bh.Id, result)){
                result = result.addDays(-1);
            }
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_AccountingClosureWizard.getPreviousBusinessDayDate'); 
        return result;
    }

    /**
    * @description Récupération de la liste des enregistrements à clôturer
    * @param accountId Id du dépôt concerné
    * @param closingDate Date de clôture sélectionnée
    * @param specificRecordTypes Optionnel - Liste de types d'enregistrement à traiter exclusivement en ignorant les autres types
    * @param accountsProviderId Optionnel - Liste d'Id de comptes fournisseurs à filtrer sur la requète des lignes de commandes fournisseurs
    * @return Objet custom RecapRecordsToUpdateObject contenant toutes les informations des enregistrements à clôturer
    */
    @AuraEnabled
    public static RecapRecordsToUpdateObject retrieveRecordsToClose(String accountId, Date closingDate, List<String> specificRecordTypes, List<String> accountsProviderId){
        System.debug('### DEBUT LWC_AccountingClosureWizard.retrieveRecordsToClose');  
        System.debug('## accountId: '+accountId);   
        System.debug('## closingDate: '+closingDate);
        System.debug('## specificRecordTypes: '+specificRecordTypes);         
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        List<CreditMemo__c> creditMemoList = new List<CreditMemo__c>();
        List<AccountingPiece__c> apList = new List<AccountingPiece__c>();
        List<AccountingEntry__c> aeList = new List<AccountingEntry__c>();
        List<AssignedResource> arList = new List<AssignedResource>();
        List<OrderItem> orderItemList = new List<OrderItem>();    
        List<String> invoiceIdList = new List<String>();
        List<String> creditMemoIdList = new List<String>();
        List<String> accPieceIdList = new List<String>();
        List<String> accEntryIdList = new List<String>();
        List<String> orderItemIdList = new List<String>();
        List<String> assignedResourceIdList = new List<String>();
        Boolean allTypesSelected = false;
        Boolean invoiceSelected = false;
        Boolean creditMemoSelected = false;
        Boolean accPieceSelected = false;
        Boolean accEntrySelected = false;
        Boolean orderItemSelected = false;
        Boolean assignedResourceSelected = false;
        Map<String, String> recordNameByid = new map<String, String>();  
        
        try {
            RecapRecordsToUpdateObject recordsToUpdate = new RecapRecordsToUpdateObject();
            Decimal numberOfInvoices = 0;
            Decimal numberOfCreditMemos = 0;
            Decimal numberOfAccountingPieces = 0;
            Decimal numberOfAccountingEntries = 0;
            Decimal numberOfAssignedResources = 0;
            Decimal numberOfOrderItems = 0;
            Decimal totalHTInvoice = 0;
            Decimal totalHTCreditMemo = 0;
            Decimal totalTTCAccountingPiece = 0;
            Decimal totalTTCAccountingEntry = 0;
            Decimal totalHTAssignedResource = 0;
            Decimal totalHTOrderItem = 0;

            List<String> serviceTerritoryIdList = new List<String>();

            // Récupération des dépôts avec le service territory (Account)
            for(Account acc : [SELECT Id, Name, serviceTerritory__c
                            FROM Account WHERE Id = :accountId]) {
                serviceTerritoryIdList.add(acc.serviceTerritory__c);
            }

            //Gestion type spécifiques renseignés
            if(specificRecordTypes.isEmpty()){
                allTypesSelected =true;
            }
            else{
                for(string recordTypeLabel : specificRecordTypes){
                    switch on recordTypeLabel{
                        when 'Invoice' {
                            invoiceSelected = true;
                        }
                        when 'CreditMemo' {
                            creditMemoSelected = true;
                        }
                        when 'AccountingEntry' {
                            accEntrySelected = true;
                        }
                        when 'AccountingPiece' {
                            accPieceSelected = true;
                        }
                        when 'AssignedResource' {
                            assignedResourceSelected = true;
                        }
                        when 'OrderItem' {
                            orderItemSelected = true;
                        }
                    }
                }
            }

            //requête Facture
            if(allTypesSelected || invoiceSelected){
                invoiceList = getInvoices(accountId, closingDate);

                // Somme du nombre et du montant des factures
                if(!invoiceList.isEmpty()){
                    for(Invoice__c inv : invoiceList){
                        numberOfInvoices++;
                        invoiceIdList.add(inv.Id);
                        if(inv.pretaxAmount__c != null){
                            totalHTInvoice = totalHTInvoice + inv.pretaxAmount__c;
                        }
                        recordNameByid.put(inv.Id, inv.Name);
                    }
                }
            }

            //requête Avoir
            if(allTypesSelected || creditMemoSelected){
                creditMemoList = getCreditMemos(accountId, closingDate);

                // Somme du nombre et du montant des avoirs
                if(!creditMemoList.isEmpty()){
                    for(CreditMemo__c cm : creditMemoList){
                        numberOfCreditMemos++;
                        creditMemoIdList.add(cm.Id);
                        if(cm.pretaxAmount__c != null){
                            totalHTCreditMemo = totalHTCreditMemo + cm.pretaxAmount__c;
                        }
                        recordNameByid.put(cm.Id, cm.Name);
                    }
                }
            }

            //requête Pièce comptable
            if(allTypesSelected || accPieceSelected){
                apList = getAccountingPieces(accountId, closingDate);

                // Somme du nombre et du montant des pièces comptables
                if(!apList.isEmpty()){
                    for(AccountingPiece__c ap : apList){
                        numberOfAccountingPieces++;
                        accPieceIdList.add(ap.Id);
                        if(ap.amount__c != null){
                            totalTTCAccountingPiece = totalTTCAccountingPiece + ap.amount__c;
                        }
                        recordNameByid.put(ap.Id, ap.Name);
                    }
                }
            }

            //requête écritures comptables
            if(allTypesSelected || accEntrySelected){
                aeList = getAccountingEntries(accountId, closingDate);

                // Somme du nombre et du montant des écritures comptables
                if(!aeList.isEmpty()){
                    for(AccountingEntry__c ae : aeList){
                        numberOfAccountingEntries++;
                        accEntryIdList.add(ae.Id);
                        if(ae.amount__c != null){
                            totalTTCAccountingEntry = totalTTCAccountingEntry + ae.amount__c;
                        }
                        recordNameByid.put(ae.Id, ae.Name);
                    }
                }
            }

            //requete Ressources assignées
            if(allTypesSelected || assignedResourceSelected){
                arList = getAssignedResources(serviceTerritoryIdList[0], closingDate);

                // Somme du nombre et du montant des ressources assignées
                if(!arList.isEmpty()){
                    for(AssignedResource ar : arList){
                        numberOfAssignedResources++;
                        assignedResourceIdList.add(ar.Id);
                        if(ar.cost__c != null){
                            totalHTAssignedResource = totalHTAssignedResource + ar.cost__c;
                        }
                        recordNameByid.put(ar.Id, ar.AssignedResourceNumber);
                    }
                }
            }

            //requete Lignes de commande fournisseur
            if(allTypesSelected || orderItemSelected){
                orderItemList = getOrderItems(accountId, closingDate, accountsProviderId);

                // Somme du nombre et du montant des produits commandés
                if(!orderItemList.isEmpty()){
                    for(OrderItem oi : orderItemList){
                        numberOfOrderItems++;
                        orderItemIdList.add(oi.Id);
                        if(oi.productCost__c != null){
                            totalHTOrderItem = totalHTOrderItem + oi.productCost__c;
                        }
                        recordNameByid.put(oi.Id, oi.OrderItemNumber);
                    }
                }
            }

            System.debug('### Invoices to close : '+numberOfInvoices +' with an amount of '+totalHTInvoice);
            System.debug('### CreditMemos to close : '+numberOfCreditMemos +' with an amount of '+totalHTCreditMemo);
            System.debug('### Accounting Pieces to close : '+numberOfAccountingPieces +' with an amount of '+totalTTCAccountingPiece);
            System.debug('### Accounting Entries to close : '+numberOfAccountingEntries +' with an amount of '+totalTTCAccountingEntry);
            System.debug('### Assigned Ressources to close : '+numberOfAssignedResources +' with an amount of '+totalHTAssignedResource);
            System.debug('### OrderItem to close : '+numberOfOrderItems +' with an amount of '+totalHTOrderItem);

            //Renseigne l'objet RecapRecordsToUpdateObject
            recordsToUpdate.numberOfInvoices = String.valueOf(numberOfInvoices);
            recordsToUpdate.numberOfCreditMemos = String.valueOf(numberOfCreditMemos);
            recordsToUpdate.numberOfAccountingPieces = String.valueOf(numberOfAccountingPieces);
            recordsToUpdate.numberOfAccountingEntries = String.valueOf(numberOfAccountingEntries);
            recordsToUpdate.numberOfOrderItems = String.valueOf(numberOfOrderItems);
            recordsToUpdate.numberOfAssignedResources = String.valueOf(numberOfAssignedResources);

            recordsToUpdate.totalHTInvoice = String.valueOf(totalHTInvoice);
            recordsToUpdate.totalHTCreditMemo = String.valueOf(totalHTCreditMemo);
            recordsToUpdate.totalTTCAccountingPiece = String.valueOf(totalTTCAccountingPiece);
            recordsToUpdate.totalTTCAccountingEntry = String.valueOf(totalTTCAccountingEntry);
            recordsToUpdate.totalHTOrderItem = String.valueOf(totalHTOrderItem);
            recordsToUpdate.totalHTAssignedResource = String.valueOf(totalHTAssignedResource);

            recordsToUpdate.invoiceIdList = invoiceIdList;
            recordsToUpdate.creditMemoIdList = creditMemoIdList;
            recordsToUpdate.accPieceIdList = accPieceIdList;
            recordsToUpdate.accEntryIdList = accEntryIdList;
            recordsToUpdate.orderItemIdList = orderItemIdList;
            recordsToUpdate.assignedResourceIdList = assignedResourceIdList;

            recordsToUpdate.recordNameByIdMap = recordNameByid;

            System.debug('## invoiceIdList: '+invoiceIdList);  
            System.debug('## creditMemoIdList: '+creditMemoIdList);  
            System.debug('## accPieceIdList: '+accPieceIdList);  
            System.debug('## accEntryIdList: '+accEntryIdList);  
            System.debug('## orderItemIdList: '+orderItemIdList);  
            System.debug('## assignedResourceIdList: '+assignedResourceIdList);  

            System.debug('### FIN LWC_AccountingClosureWizard.retrieveRecordsToClose');
            return recordsToUpdate;
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
    }

    /**
    * @description Récupération de la liste des enregistrements à clôturer
    * @param closingDate Date de clôture sélectionnée
    * @param invoiceIdList Liste d'Ids de factures à clôturer
    * @param creditMemoIdList Liste d'Ids d'avoirs à clôturer
    * @param accPieceIdList Liste d'Ids de pièces comptables à clôturer
    * @param accEntryIdList Liste d'Ids d'écritures comptables à clôturer
    * @param orderItemIdList Liste d'Ids de lignes de commandes fournisseur à clôturer
    * @param assignedResourceIdList Liste d'Ids de ressources assignées à clôturer
    * @param recordNameByIdMap Map contenant le nom associé à l'Id de chaque enregistrement (pour info en cas d'erreur)
    * @return Objet Custom RecapRecordsUpdated Contenant les infos des enregistrements mis à jour et en erreur
    */
    @AuraEnabled
    public static RecapRecordsUpdated closeRecords(Date closingDate, List<String> invoiceIdList, List<String> creditMemoIdList,
    List<String> accPieceIdList, List<String> accEntryIdList, List<String> orderItemIdList, List<String> assignedResourceIdList, Map<String, String> recordNameByIdMap){
        System.debug('### DEBUT LWC_AccountingClosureWizard.closeRecords');  
        System.debug('## closingDate: '+closingDate);  
        System.debug('## invoiceIdList: '+invoiceIdList);  
        System.debug('## creditMemoIdList: '+creditMemoIdList);  
        System.debug('## accPieceIdList: '+accPieceIdList);  
        System.debug('## accEntryIdList: '+accEntryIdList);  
        System.debug('## orderItemIdList: '+orderItemIdList);  
        System.debug('## assignedResourceIdList: '+assignedResourceIdList);
        System.debug('## recordNameByIdMap: '+recordNameByIdMap);  
        RecapRecordsUpdated nbOfRecordsUpdated = new RecapRecordsUpdated();
        List<Invoice__c> invoiceToSave = new List<Invoice__c>();
        List<CreditMemo__c> creditMemoToSave = new List<CreditMemo__c>();
        List<AccountingPiece__c> apToSave = new List<AccountingPiece__c>();
        List<AccountingEntry__c> aeToSave = new List<AccountingEntry__c>();
        List<AssignedResource> arToSave = new List<AssignedResource>();
        List<OrderItem> orderItemToSave = new List<OrderItem>();  
        Decimal numberOfInvoices = 0;
        Decimal numberOfCreditMemos = 0;
        Decimal numberOfAccountingPieces = 0;
        Decimal numberOfAccountingEntries = 0;
        Decimal numberOfAssignedResources = 0;
        Decimal numberOfOrderItems = 0;
        Decimal numberOfFailedInvoices = 0;
        Decimal numberOfFailedCreditMemos = 0;
        Decimal numberOfFailedAccountingPieces = 0;
        Decimal numberOfFailedAccountingEntries = 0;
        Decimal numberOfFailedAssignedResources = 0;
        Decimal numberOfFailedOrderItems = 0;
        List<RecordUpdateError> recordUpdateErrorList = new List<RecordUpdateError>();
        
        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();        
        
        try {
            //Clôture des factures              
            if(!invoiceIdList.isEmpty()) {
                for(String invId : invoiceIdList) {
                    numberOfInvoices++;
                    Invoice__c inv = new Invoice__c(Id = invId, closingDate__c = closingDate);
                    invoiceToSave.add(inv);
                }
                System.debug('## invoiceToSave: ' + invoiceToSave);
                Database.SaveResult[] results = Database.update(invoiceToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedInvoices++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Facture',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields() + ' Id:' + result.getId() + ' Message:' + error.getMessage());
                        }
                    }
                }
            }

            //Clôture des avoirs
            if(!creditMemoIdList.isEmpty()) {
                for(String cmId : creditMemoIdList) {
                    numberOfCreditMemos++;
                    CreditMemo__c cm = new CreditMemo__c(Id = cmId, closingDate__c = closingDate);
                    creditMemoToSave.add(cm);
                }
                System.debug('## creditMemoToSave: ' + creditMemoToSave);
                Database.SaveResult[] results = Database.update(creditMemoToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedCreditMemos++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Avoir',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }

            //Clôture des pièces comptables
            if(!accPieceIdList.isEmpty()) {
                for(String apId : accPieceIdList) {
                    numberOfAccountingPieces++;
                    AccountingPiece__c ap = new AccountingPiece__c(Id = apId, closingDate__c = closingDate);
                    apToSave.add(ap);
                }
                System.debug('## apToSave: ' + apToSave);
                Database.SaveResult[] results = Database.update(apToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedAccountingPieces++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Pièce Comptable',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }

            //Clôture des écritures comptables
            if(!accEntryIdList.isEmpty()) {
                for(String aeId : accEntryIdList) {
                    numberOfAccountingEntries++;
                    AccountingEntry__c ae = new AccountingEntry__c(Id = aeId, closingDate__c = closingDate);
                    aeToSave.add(ae);
                }
                System.debug('## aeToSave: ' + aeToSave);
                Database.SaveResult[] results = Database.update(aeToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedAccountingEntries++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Ecriture Comptable',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }

            //Clôture des lignes de commandes fournisseurs
            if(!orderItemIdList.isEmpty()) {
                for(String oiId : orderItemIdList) {
                    numberOfOrderItems++;
                    OrderItem oi = new OrderItem(Id = oiId, closingDate__c = closingDate);
                    orderItemToSave.add(oi);
                }
                System.debug('## orderItemToSave: ' + orderItemToSave);
                Database.SaveResult[] results = Database.update(orderItemToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedOrderItems++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Commande fournisseur',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }

            //Clôture des Ressources assignées
            if(!assignedResourceIdList.isEmpty()) {
                for(String arId : assignedResourceIdList) {
                    numberOfAssignedResources++;
                    AssignedResource ar = new AssignedResource(Id = arId, closingDate__c = closingDate);
                    arToSave.add(ar);
                }
                System.debug('## arToSave: ' + arToSave);
                Database.SaveResult[] results = Database.update(arToSave, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        //Cas erreur lors de l'update
                        numberOfFailedAssignedResources++;
                        for(Database.Error error : result.getErrors()) {
                            //renseigne objet custom RecordUpdateError contenant les informatiosn liées à l'erreur (Type,Nom,Message d'erreur)
                            RecordUpdateError errorToSend = new RecordUpdateError('Facture de service',recordNameByIdMap.get(result.getId()), error.getMessage());                      
                            recordUpdateErrorList.Add(errorToSend);
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }

            //rernseigne l'objet de recap RecapRecordsUpdated
            nbOfRecordsUpdated.numberOfClosedInvoices = String.valueOf(numberOfInvoices-numberOfFailedInvoices);
            nbOfRecordsUpdated.numberOfClosedCreditMemos = String.valueOf(numberOfCreditMemos-numberOfFailedCreditMemos);
            nbOfRecordsUpdated.numberOfClosedAccountingPieces = String.valueOf(numberOfAccountingPieces-numberOfFailedAccountingPieces);
            nbOfRecordsUpdated.numberOfClosedAccountingEntries = String.valueOf(numberOfAccountingEntries-numberOfFailedAccountingEntries);
            nbOfRecordsUpdated.numberOfClosedAssignedResources = String.valueOf(numberOfAssignedResources-numberOfFailedAssignedResources);
            nbOfRecordsUpdated.numberOfClosedOrderItems = String.valueOf(numberOfOrderItems-numberOfFailedOrderItems);

            nbOfRecordsUpdated.numberOfFailedInvoices = String.valueOf(numberOfFailedInvoices);
            nbOfRecordsUpdated.numberOfFailedCreditMemos = String.valueOf(numberOfFailedCreditMemos);
            nbOfRecordsUpdated.numberOfFailedAccountingPieces = String.valueOf(numberOfFailedAccountingPieces);
            nbOfRecordsUpdated.numberOfFailedAccountingEntries = String.valueOf(numberOfFailedAccountingEntries);
            nbOfRecordsUpdated.numberOfFailedAssignedResources = String.valueOf(numberOfFailedAssignedResources);
            nbOfRecordsUpdated.numberOfFailedOrderItems = String.valueOf(numberOfFailedOrderItems);

            nbOfRecordsUpdated.errorList = recordUpdateErrorList;
            System.debug('## errorList:'+nbOfRecordsUpdated.errorList);
            System.debug('## errorList size'+nbOfRecordsUpdated.errorList.size());
            System.debug('### FIN LWC_AccountingClosureWizard.closeRecords');

            return nbOfRecordsUpdated;
        }
        catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
    }

    private static List<Invoice__c> getInvoices(String accountId, Date closingDate){
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        invoiceList = [SELECT id, pretaxAmount__c, closingDate__c, Name FROM Invoice__c 
                        WHERE recordType.developerName = :Constants.INVOICE_INVOICE_RT 
                            AND invoiceDate__c != null 
                            AND invoiceDate__c <= :closingDate 
                            AND closingDate__c = null 
                            AND seller__c = :accountId
                            AND isLegacy__c = false];
        return invoiceList;
    }   

    private static List<CreditMemo__c> getCreditMemos(String accountId, Date closingDate){
        List<CreditMemo__c> cmList = new List<CreditMemo__c>();
        cmList = [SELECT id, pretaxAmount__c, closingDate__c, Name FROM CreditMemo__c 
                        WHERE creditMemoDate__c != null 
                            AND creditMemoDate__c <= :closingDate 
                            AND closingDate__c = null 
                            AND seller__c = :accountId
                            AND isLegacy__c = false];
        return cmList;
    }   

    private static List<AccountingPiece__c> getAccountingPieces(String accountId, Date closingDate){
        List<AccountingPiece__c> apList = new List<AccountingPiece__c>();
        apList = [SELECT id, amount__c, closingDate__c, Name FROM AccountingPiece__c 
                        WHERE accountingDate__c != null 
                            AND accountingDate__c <= :closingDate 
                            AND closingDate__c = null 
                            AND orderEntity__c = :accountId
                            AND isLegacy__c = false];
        return apList;
    }   

    private static List<AccountingEntry__c> getAccountingEntries(String accountId, Date closingDate){
        List<AccountingEntry__c> aeList = new List<AccountingEntry__c>();
        aeList = [SELECT id, amount__c, closingDate__c, Name FROM AccountingEntry__c 
                        WHERE entryDate__c != null 
                            AND entryDate__c <= :closingDate 
                            AND closingDate__c = null 
                            AND inputEntity__c = :accountId
                            AND isLegacy__c = false];
        return aeList;
    }   

    private static List<OrderItem> getOrderItems(String accountId, Date closingDate, List<string> accountsProviderId){
        System.debug('##test:'); 
        List<OrderItem> oiList = new List<OrderItem>();
        String PROVIDER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
        string queryOi = 'SELECT id, productCost__c, closingDate__c, product2id, asset__c, legacyReference__c, parentOrderItem__c, billingDate__c, billingNumber__c, order.isLegacy__c, order.legacyReference__c, OrderItemNumber';
        queryOi += ' FROM OrderItem WHERE order.recordTypeId = :PROVIDER_ORDER_RTID';
        queryOi += ' AND billingDate__c != null';
        queryOi += ' AND billingDate__c <= :closingDate';
        queryOi += ' AND closingDate__c = null';
        queryOi += ' AND parentOrderItem__c = null';
        queryOi += ' AND cancellationDate__c = null';
        queryOi += ' AND cancellationReason__c = null';
        queryOi += ' AND order.accountId = :accountId';
        queryOi += ' AND order.legacyReference__c = null';
        queryOi += ' AND order.isLegacy__c = FALSE';
        queryOi += ' AND isLegacy__c = false';
        if(!accountsProviderId.isEmpty()){ 
            queryOi += ' AND (';
            for(Integer i =0; i<accountsProviderId.size()-1; i++){
                queryOi+=' order.provider__c = \''+accountsProviderId[i]+'\' OR';
            }
            queryOi += ' order.provider__c = \''+accountsProviderId[accountsProviderId.size()-1]+'\')';
        }

        oiList = Database.query(queryOi);
        return oiList;
    }   

    private static List<AssignedResource> getAssignedResources(String serviceTerritoryId, Date closingDate){
        List<AssignedResource> arList = new List<AssignedResource>();
        arList = [SELECT id, cost__c, closingDate__c, AssignedResourceNumber FROM AssignedResource 
                        WHERE serviceAppointment.recordType.developerName = 'ServiceAppointment'
                            AND billingDate__c != null 
                            AND billingDate__c <= :closingDate 
                            AND closingDate__c = null 
                            AND serviceAppointment.ServiceTerritoryId = :serviceTerritoryId];
        return arList;
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

    // Objet retourné au composant LWC pour affichage du résumé avant update
    public class RecapRecordsToUpdateObject {
        @AuraEnabled 
        public String numberOfInvoices { get; set; }        
        @AuraEnabled
        public String totalHTInvoice { get; set; }        
        @AuraEnabled
        public String numberOfCreditMemos { get; set; }        
        @AuraEnabled
        public String totalHTCreditMemo { get; set; }        
        @AuraEnabled 
        public String numberOfAccountingPieces { get; set; }        
        @AuraEnabled
        public String totalTTCAccountingPiece { get; set; }        
        @AuraEnabled
        public String numberOfAccountingEntries { get; set; }        
        @AuraEnabled
        public String totalTTCAccountingEntry { get; set; } 
        @AuraEnabled 
        public String numberOfOrderItems { get; set; }        
        @AuraEnabled
        public String totalHTOrderItem { get; set; }        
        @AuraEnabled
        public String numberOfAssignedResources { get; set; }        
        @AuraEnabled
        public String totalHTAssignedResource { get; set; } 
        @AuraEnabled
        public List<String> invoiceIdList { get; set; } 
        @AuraEnabled
        public List<String> creditMemoIdList { get; set; } 
        @AuraEnabled
        public List<String> accPieceIdList { get; set; } 
        @AuraEnabled
        public List<String> accEntryIdList { get; set; } 
        @AuraEnabled
        public List<String> orderItemIdList { get; set; } 
        @AuraEnabled
        public List<String> assignedResourceIdList { get; set; }
        @AuraEnabled
        public Map<String, String> recordNameByIdMap { get; set; }

        public recapRecordsToUpdateObject() {}
    }

    public class RecapRecordsUpdated {
        @AuraEnabled 
        public String numberOfClosedInvoices { get; set; }        
        @AuraEnabled
        public String numberOfFailedInvoices { get; set; }        
        @AuraEnabled
        public String numberOfClosedCreditMemos { get; set; }        
        @AuraEnabled
        public String numberOfFailedCreditMemos { get; set; }        
        @AuraEnabled 
        public String numberOfClosedAccountingPieces { get; set; }        
        @AuraEnabled
        public String numberOfFailedAccountingPieces { get; set; }        
        @AuraEnabled
        public String numberOfClosedAccountingEntries { get; set; }        
        @AuraEnabled
        public String numberOfFailedAccountingEntries { get; set; } 
        @AuraEnabled 
        public String numberOfClosedOrderItems { get; set; }        
        @AuraEnabled
        public String numberOfFailedOrderItems { get; set; }        
        @AuraEnabled
        public String numberOfClosedAssignedResources { get; set; }        
        @AuraEnabled
        public String numberOfFailedAssignedResources { get; set; }
        @AuraEnabled
        public List<RecordUpdateError> errorList { get; set; } 

        public RecapRecordsUpdated() {}
    }

    public class RecordUpdateError {
        @AuraEnabled
        public string recordType { get; set; }
        @AuraEnabled
        public string recordName { get; set; }
        @AuraEnabled
        public string errorMessage { get; set; }

        public RecordUpdateError(String recordTypeValue, String recordNameValue, String errorMessageValue) {
            this.recordType = recordTypeValue;
            this.recordName = recordNameValue;
            this.errorMessage = errorMessageValue;
        }
    }
}