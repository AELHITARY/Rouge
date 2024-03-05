//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_ExportAccountingReportPDF
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 30/08/2023
//-- Version     : 1.1
//-- * 1.1 - Retour #1050-1068
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --

public class LWC_ExportAccountingReportPDF {
    private static final String PDF_TEMPLATEID = PropertiesUtils.getStringValue('merkure.accountingReport.templateId', '');
    private static final String ORDER_CUSTOMER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final String ACCOUNTINGPIECE_COMPOSITERECEIPT_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);
    private static final String ACCOUNTINGPIECE_DOUBTFULDEBT_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_DOUBTFULDEBT_RT);
    private static final String ACCOUNTINGPIECE_UNPAID_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_UNPAID_RT);
    private static final String ACCOUNTINGPIECE_RECEIPT_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final String ACCOUNTINGPIECE_RECEIPTCANCELLATION_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPTCANCELLATION_RT);
    private static final String ACCOUNTINGENTRY_BANKREMITTANCE_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_BANKREMITTANCE_RT);
    private static final String ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RT);
    private static final String ACCOUNTINGENTRY_UNPAID_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_UNPAID_RT);
    
    private static final Date DEPTH_DATE = PropertiesUtils.getDateValue('export.nonCollecte.dateProfondeur');
    private static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug.accounting', false);
    private static final List<String> VALID_ACCOUNTING_PIECE_TYPE = new List<String>{
        'Agios',
        'DoubtfulDebt',
        'MiscellaneousOperation',
        'PaymentDifference',
        'ProfitsAndLosses',
        'ReceiptCancellation',
        'UndeliveredReceiptCancellation',
        'Refund',
        'VATDifference'
    };


    /***************************************************/
    /* AURA ENABLED                                *
    /***************************************************/
    //#region auraenabled

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param exportType Type d'export selectionné
    * @param serviceEntityId Id du dépot sélectionné
    * @param serviceEntityName Nom du dépot sélectionné
    * @param startDate Date de début de période d'observation
    * @param endDate Date de fin de période d'observation
    * @param jsonObject Objet JSON contenant les infos du rapport à exporter
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderDocumentPDF(string exportType, Id serviceEntityId, String serviceEntityName, Date startDate, Date endDate, String jsonObject) {
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.renderDocumentPDF');
        System.debug('## exportType: '+exportType);
        System.debug('## serviceEntityId: '+serviceEntityId);
        System.debug('## serviceEntityName: '+serviceEntityName);
        System.debug('## startDate: '+startDate);
        System.debug('## endDate: '+endDate);
        System.debug('## jsonObject: '+jsonObject);
        String result;
        Blob documentBlob = null;
        String filename;
        string docFormat = 'pdf';
        string docTypeName = 'PDF';
        Object reportData = null;

        try {

            //Nom du fichier
            filename = exportType + ' ' + docTypeName+' - ';
            filename += serviceEntityName + ' - ';
            
            //gestion Type = Non collecté/Acompte
            if(exportType=='Non collecté') {
                Date observationDate = null;
                if(endDate!=null){
                    observationDate = endDate;
                }
                else {
                    observationDate = startDate;
                }
                
                DateTime observationDateTime = DateTime.newInstance(observationDate.year(), observationDate.month(), observationDate.day());

                filename += observationDateTime.format('YYYY/MM/dd');

                reportData = JSON.deserialize(jsonObject, NotCollectedReportObject.class);
                System.debug('## reportDataNotCollected : '+reportData);

            }
            //Autres type
            else{
                if(endDate == null){
                    endDate = Date.today();
                }

                DateTime startDateTime = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day());
                DateTime endDateTime = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day());
                filename += startDateTime.format('YYYY/MM/dd') + ' au ' + endDateTime.format('YYYY/MM/dd');

                if(exportType=='Journal des banques'){
                    reportData = JSON.deserialize(jsonObject, BankReportObject.class);
                }
                else {
                    reportData = JSON.deserialize(jsonObject, OtherTypeReportObject.class);
                }
                System.debug('## reportDataOtherTypes : '+reportData);
            }

            
            // Appel API Merkure API
            documentBlob = Utils_APIMerkure.renderDocument(PDF_TEMPLATEID, reportData, docFormat, null);
            // Lien du document vers l'enregistrement     
            result = linkDocumentToRecord(serviceEntityId, filename, docFormat, documentBlob);

            // ONLY FOR DEBUG - Création du JSON en tant que document
            if(API_DEBUG) {
                String payloadString = Utils_APIMerkure.constructHttpPayload(PDF_TEMPLATEID, reportData, docFormat, null);
                System.debug('## Payload: ' + payloadString);

                Document d = new Document(Name = filename, 
                                            Body = Blob.valueOf(payloadString),
                                            ContentType = 'text/plain',
                                            FolderId = '00lD0000001ygqO',
                                            Type = 'txt');
                insert d;
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_ExportAccountingReportPDF.renderDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON correspondant au type d'export
    * @param exportType Type d'export selectionné
    * @param serviceEntityName Nom du dépot sélectionné
    * @param startDate Date de début de période d'observation
    * @param endDate Date de fin de période d'observation
    * @return String de l'objet JSON sérialisé
    */
    @AuraEnabled
    public static String generateJsonObject(string exportType, Id serviceEntityId, String serviceEntityName, Date startDate, Date endDate, String[] bankAccounts){
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.generateJsonObject');
        System.debug('## exportType: '+exportType);
        System.debug('## serviceEntityName: '+serviceEntityName);
        System.debug('## startDate: '+startDate);
        System.debug('## endDate: '+endDate);
        NotCollectedReportObject reportDataNotCollected;
        OtherTypeReportObject reportDataOtherType;
        BankReportObject reportDataBank;
        String result;               
        try {
            //gestion Type = Non collecté/Acompte
            if(exportType=='Non collecté') {
                Date observationDate = null;
                if(endDate!=null){
                    observationDate = endDate;
                }
                else {
                    observationDate = startDate;
                }
                
                DateTime observationDateTime = DateTime.newInstance(observationDate.year(), observationDate.month(), observationDate.day());

                //Récupération des commandes pour le type non collecté/Acompte
                //construction de l'objet JSON
                reportDataNotCollected = getCustomerOrdersNotCollectedInformations(serviceEntityName, observationDate);
                System.debug('## jsonObject: '+reportDataNotCollected);
                return JSON.serialize(reportDataNotCollected);
            }
            //Autres types
            else{
                if(endDate == null){
                    endDate = Date.today();
                }
                if(exportType=='Journal des banques'){
                    reportDataBank = getBankReportObjectsInformations(serviceEntityId, startDate, endDate, bankAccounts);
                    System.debug('## jsonObject: '+reportDataBank);
                    result = JSON.serialize(reportDataBank);
                }
                else{
                    reportDataOtherType = getAccountingObjectsInformations(exportType, serviceEntityId, startDate, endDate);
                    System.debug('## jsonObject: '+reportDataOtherType);
                    result = JSON.serialize(reportDataOtherType);
                }
                return result;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Fonction pour la liste des dépôts actifs ou fermés depuis moins d'un an
    * @return Map contenant le nom du dépôt et l'Id suivi du nom sous la forme Id/Nom
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, String> getEntityAccounts(){
        Date oneYearOld = Date.today().addYears(-1);

        Map<String, String> result = new Map<String, String>(); 
        for(Account account : [SELECT Id,Name FROM Account WHERE entityType__r.KparKReference__c='DEP' 
                                AND RecordType.DeveloperName = :Constants.ACCOUNT_ENTITY_RT
                                AND migratedToK3__c=true
                                AND (stageName__c = 'En cours' OR (stageName__c = 'Désactivé' AND endDate__c > :oneYearOld)) 
                                ORDER BY Name]){
            result.put(account.Name, account.Id+'/'+account.Name);
        }
        return result;
    }

    /**
    * @description Fonction pour la liste des comptes bancaires en fonction des visibilités présentes sur le dépôt
    * @return Map contenant le nom du dépôt et l'Id suivi du nom sous la forme Id/Nom
    */
    @AuraEnabled
    public static Map<String, String> getBankAccounts(Id serviceEntityId, Date startDate, Date endDate){
        //Date oneYearOld = Date.today().addYears(-1);
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.getBankAccounts');
        System.debug('## serviceEntityId:'+serviceEntityId);
        System.debug('## startDate:'+startDate);
        System.debug('## endDate:'+endDate);

        Map<String, String> result = new Map<String, String>(); 
        for(BankAccountVisibility__c bankAccountVisibility : [SELECT bankAccount__c, bankAccount__r.Name FROM BankAccountVisibility__c WHERE entity__c= :serviceEntityId
                                                                AND (endDate__c >= :startDate OR endDate__c = null) AND startDate__c <= :endDate 
                                                                ORDER BY bankAccount__r.Name]){
            result.put(bankAccountVisibility.bankAccount__r.Name, bankAccountVisibility.bankAccount__c+'/'+bankAccountVisibility.bankAccount__r.Name);
        }
        System.debug('## result:'+result);
        System.debug('### FIN LWC_ExportAccountingReportPDF.getBankAccounts');
        return result;
        
    }

    //#endregion

    /***************************************************/
    /* CONSTRUCTION OBJET JSON                                *
    /***************************************************/

    //#region constructjson

    /**
    * @description Fonction pour récupérer les informations des commandes clients et enregistrements enfants en JSON
    * @param serviceEntityName Nom du Dépot séléctionné
    * @param observationDate Date d'observation
    * @return NotCollectedReportObject Objet contenant les informations des commandes
    */
    public static NotCollectedReportObject getCustomerOrdersNotCollectedInformations(String serviceEntityName, Date observationDate) {
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.getCustomerOrdersNotCollectedInformations');
        System.debug('## serviceEntityName :'+ serviceEntityName);
        System.debug('## observationDate :'+ observationDate);

        NotCollectedReportObject result = new NotCollectedReportObject();       
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        List<CreditMemo__c> creditMemoList = new List<CreditMemo__c>();
        List<AccountingPiece__c> accountingPieceList = new List<AccountingPiece__c>();
        List<CustomerOrderObject> customerOrderNotCollectedObjectList = new List<CustomerOrderObject>();

        // *************** Récupération des données ********************
        // *************************************************************
        
        //Récupération des factures
        string invoiceQuery = 'SELECT Id, customerOrder__c, amount__c FROM Invoice__c WHERE customerOrder__r.serviceEntity__r.Name = :serviceEntityName';
        invoiceQuery += ' AND customerOrder__r.RecordTypeId = :ORDER_CUSTOMER_RTID AND customerOrder__r.Type != \'Avenant\'';
        invoiceQuery += ' AND customerOrder__r.effectiveDate <= :observationDate AND customerOrder__r.effectiveDate >= :DEPTH_DATE';
        invoiceQuery += ' AND invoiceDate__c <= :observationDate AND customerOrder__r.legacySource__c !=\'GC/Froide\'';
        invoiceList = Database.query(invoiceQuery);
        System.debug('## invoiceList: '+invoiceList);
        System.debug('## invoiceList.size: '+invoiceList.size());

        //Map to avoid nested loop
        Map<Id, List<Invoice__c>> invoicesMap = new Map<Id, List<Invoice__c>>();
        for(Invoice__c invoice : invoiceList){
            if(invoicesMap.containsKey(invoice.customerOrder__c)){
                invoicesMap.get(invoice.customerOrder__c).add(invoice);
            }
            else {
                List<Invoice__c> newValue = new List<Invoice__c>{invoice};
                invoicesMap.put(invoice.customerOrder__c, newValue);
            }
        }

        //récupération des avoirs
        string creditMemoQuery = 'SELECT Id, customerOrder__c, amount__c FROM CreditMemo__c WHERE customerOrder__r.serviceEntity__r.Name = :serviceEntityName';
        creditMemoQuery += ' AND customerOrder__r.RecordTypeId = :ORDER_CUSTOMER_RTID AND customerOrder__r.Type != \'Avenant\'';
        creditMemoQuery += ' AND customerOrder__r.effectiveDate <= :observationDate AND customerOrder__r.effectiveDate >= :DEPTH_DATE';
        creditMemoQuery += ' AND status__c != \'Annulé\' AND creditMemoDate__c <= :observationDate AND customerOrder__r.legacySource__c !=\'GC/Froide\'';
        creditMemoList = Database.query(creditMemoQuery);
        System.debug('## creditMemoList: '+creditMemoList);
        System.debug('## creditMemoList.size: '+creditMemoList.size());

        //Map to avoid nested loop
        Map<Id, List<CreditMemo__c>> creditMemosMap = new Map<Id, List<CreditMemo__c>>();
        for(CreditMemo__c creditMemo : creditMemoList){
            if(creditMemosMap.containsKey(creditMemo.customerOrder__c)){
                creditMemosMap.get(creditMemo.customerOrder__c).add(creditMemo);
            }
            else {
                List<CreditMemo__c> newValue = new List<CreditMemo__c>{creditMemo};
                creditMemosMap.put(creditMemo.customerOrder__c, newValue);
            }
        }

        //Récupération des pièces comptables
        string accountingPieceQuery = 'SELECT Id, RecordTypeId, amount__c, order__c, accountingDate__c, pieceDate__c FROM AccountingPiece__c WHERE order__r.serviceEntity__r.Name = :serviceEntityName';
        accountingPieceQuery += ' AND order__r.RecordTypeId = :ORDER_CUSTOMER_RTID AND order__r.Type != \'Avenant\'';
        accountingPieceQuery += ' AND order__r.effectiveDate <= :observationDate AND order__r.effectiveDate >= :DEPTH_DATE';
        accountingPieceQuery += ' AND RecordTypeId != :ACCOUNTINGPIECE_COMPOSITERECEIPT_RTID AND order__r.legacySource__c !=\'GC/Froide\'';
        accountingPieceList = Database.query(accountingPieceQuery);
        System.debug('## accountingPieceList: '+accountingPieceList);
        System.debug('## accountingPieceList.size: '+accountingPieceList.size());

        //Map to avoid nested loop
        Map<Id, List<AccountingPiece__c>> accountingPiecesMap = new Map<Id, List<AccountingPiece__c>>();
        for(AccountingPiece__c accountingPiece : accountingPieceList){
            if(accountingPiecesMap.containsKey(accountingPiece.order__c)){
                accountingPiecesMap.get(accountingPiece.order__c).add(accountingPiece);
            }
            else {
                List<AccountingPiece__c> newValue = new List<AccountingPiece__c>{accountingPiece};
                accountingPiecesMap.put(accountingPiece.order__c, newValue);
            }
        }

        //Récupération des commandes
        for(Order neworder : [SELECT Id, OrderNumber, legacyReference__c, billingName__c, EffectiveDate, oldCompositeStatus__c, firstInvoiceDate__c, pretaxAmount__c FROM Order
                                WHERE serviceEntity__r.Name = :serviceEntityName  AND RecordTypeId = :ORDER_CUSTOMER_RTID AND Type != 'Avenant'
                                    AND effectiveDate <= :observationDate AND effectiveDate >= :DEPTH_DATE AND legacySource__c != 'GC/Froide']){
            CustomerOrderObject customerOrderNotCollectedObject = constructCustomerOrderNotCollectedObject(newOrder, observationDate, invoicesMap, creditMemosMap, accountingPiecesMap);
            customerOrderNotCollectedObjectList.Add(customerOrderNotCollectedObject);
        }

        result.Orders = customerOrderNotCollectedObjectList;
        System.debug('### result:'+result);
        System.debug('### FIN LWC_ExportAccountingReportPDF.getCustomerOrdersNotCollectedInformations');
        return result;
    }

    
    /**
    * @description Fonction pour construire l'objet JSON pour une commande client pour le type de rapport non collecté/Acompte
    * @param newOrder Commande client
    * @return OrderObject Objet contenant les informations d'une commande
    */
    public static CustomerOrderObject constructCustomerOrderNotCollectedObject(Order newOrder, Date observationDate, Map<Id, List<Invoice__c>> invoiceList, Map<Id, List<CreditMemo__c>> creditMemoList, Map<Id, List<AccountingPiece__c>> accountingPieceList) {
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.constructCustomerOrderNotCollectedObject');
        CustomerOrderObject result = new CustomerOrderObject();

        result.orderNumber = newOrder.OrderNumber;
        result.legacyReference = newOrder.legacyReference__c;
        result.billingName = newOrder.billingName__c;
        result.effectiveDate = newOrder.EffectiveDate;
        result.oldCompositeStatus = newOrder.oldCompositeStatus__c;
        //Age = Date d'observation - date première facture
        if(newOrder.firstInvoiceDate__c != null) {
            result.age = newOrder.firstInvoiceDate__c.daysBetween(observationDate);
            result.category = getCategoryFromAge(result.age);
        }
        result.pretaxAmount = newOrder.pretaxAmount__c;
        result.invoicesAmount = getSumAmountInvoices(newOrder.Id, invoiceList);
        result.creditMemosAmount = getSumAmountCreditMemos(newOrder.Id, creditMemoList);
        //débit = Montant facturé - Avoir
        result.debit = result.invoicesAmount - result.creditMemosAmount;
        List<Decimal> amountAccountingPiecesList = getSumAmountAccountingPieces(newOrder.Id, accountingPieceList, observationDate);
        result.recordedAccountingPiecesAmount = amountAccountingPiecesList[0];
        result.unrecordedAccountingPiecesAmount = amountAccountingPiecesList[1];
        result.doubtfulAccountingPieceAmount = amountAccountingPiecesList[2];
        //Solde = debit - montant encaissé
        result.balance = result.debit - result.recordedAccountingPiecesAmount;

        if((result.balance!=0 || result.unrecordedAccountingPiecesAmount !=0) && result.debit == 0){
            result.ventilation = 'acompte';
        }
        else if(result.debit !=0 && (result.balance !=0 || result.doubtfulAccountingPieceAmount !=0)){
            result.ventilation = 'non collecté';
        }
        
        System.debug('## result: '+result);   
        System.debug('### FIN LWC_ExportAccountingReportPDF.constructCustomerOrderNotCollectedObject');
        return result;
    }

    /**
    * @description Fonction pour récupérer les informations des enregistrements comptables et les convertir en objets JSON
    * @param exportType Type d'export (ventes, OD)
    * @param serviceEntityId Id du Dépot séléctionné
    * @param startDate Date de début d'observation
    * @param endDate Date de fin d'observation
    * @return otherTypeReportObject Objet contenant les informations des enregistrements comptables
    */
    public static OtherTypeReportObject getAccountingObjectsInformations(string exportType, Id serviceEntityId, Date startDate, Date endDate){
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.getAccountingObjectsInformations');
        System.debug('## serviceEntityId :'+ serviceEntityId);
        System.debug('## startDate :'+ startDate);
        System.debug('## endDate :'+ endDate);

        OtherTypeReportObject result = new OtherTypeReportObject();
        List<AccountingObject> accountingObjectList = new List<AccountingObject>();
        
        // *************** Récupération des données ********************
        // *************************************************************

        // --- Cas Journal des ventes ---
        if(exportType=='Journal des ventes'){
            //Récupération des avoirs
            Map<String, String> relations = new Map<String, String>();
            relations.put('CreditMemo__c.RecordType', 'RecordType'); 
            relations.put('CreditMemo__c.refundReason__r', 'Referencial__c');
            relations.put('CreditMemo__c.customerOrder__r', 'Order'); 
            string creditMemoQuery = SchemaUtils.getQuery('CreditMemo__c', 'seller__c', serviceEntityId, relations);
            creditMemoQuery += ' AND creditMemoDate__c >= :startDate AND creditMemoDate__c <= :endDate';
            creditMemoQuery += ' AND creditMemoReference__c != \'\' ';
            List<CreditMemo__c> creditMemoList = Database.query(creditMemoQuery);
            System.debug('## creditMemoList: '+creditMemoList);
            System.debug('## creditMemoList.size: '+creditMemoList.size());

            if(!creditMemoList.isEmpty()){
                for(CreditMemo__c creditMemo : creditMemoList){
                    AccountingObject accountingObject = createAccountingObjectFromCreditMemo(creditMemo);
                    accountingObjectList.Add(accountingObject);
                }
            }

            //Récupération des factures
            Map<String, String> relations2 = new Map<String, String>();
            relations2.put('Invoice__c.RecordType', 'RecordType'); 
            relations2.put('Invoice__c.customerOrder__r', 'Order');
            relations2.put('Invoice__c.customerOrder__r.installResource__r', 'ServiceResource'); 
            
            string invoiceQuery = SchemaUtils.getQuery('Invoice__c', 'seller__c', serviceEntityId, relations2);
            invoiceQuery += ' AND invoiceDate__c >= :startDate AND invoiceDate__c <= :endDate';
            invoiceQuery += ' AND RecordType.developerName = \'Invoice\' AND invoiceReference__c != \'\'';
            //DEBUG
            List<Invoice__c> invoiceList = Database.query(invoiceQuery);
            System.debug('## invoiceList: '+invoiceList);
            System.debug('## invoiceList.size: '+invoiceList.size());
            
            if(!invoiceList.isEmpty()){
                for(Invoice__c invoice : invoiceList){
                    AccountingObject accountingObject = createAccountingObjectFromInvoice(invoice);
                    accountingObjectList.Add(accountingObject);
                }
            }
        }
        // --- Cas Journal des OD ---
        else if(exportType == 'Journal des OD'){
            //Récupération des pièces comptables
            Map<String, String> relations = new Map<String, String>();
            relations.put('AccountingPiece__c.RecordType', 'RecordType'); 
            relations.put('AccountingPiece__c.orderEntity__r', 'Account');
            relations.put('AccountingPiece__c.inputEntity__r', 'Account');
            relations.put('AccountingPiece__c.entityBankAccount__r', 'Referencial__c');
            relations.put('AccountingPiece__c.Order__r', 'Order'); 
            relations.put('AccountingPiece__c.Order__r.salesEntity__r.Parent', 'Account');
            relations.put('AccountingPiece__c.Order__r.salesEntity__r', 'Account');
            relations.put('AccountingPiece__c.Order__r.afterSalesService__r', 'AfterSalesService__c');
            string accountingPieceQuery = SchemaUtils.getQuery('AccountingPiece__c', 'inputEntity__c', serviceEntityId, relations);
            accountingPieceQuery += ' AND accountingDate__c >= :startDate AND accountingDate__c <= :endDate';
            //accountingPieceQuery += ' AND RecordType.developerName IN :VALID_ACCOUNTING_PIECE_TYPE';
            accountingPieceQuery += ' AND (';
            for(Integer i =0; i<VALID_ACCOUNTING_PIECE_TYPE.size()-1; i++){
                accountingPieceQuery+=' RecordType.developerName = \''+VALID_ACCOUNTING_PIECE_TYPE[i]+'\' OR';
            }
            accountingPieceQuery += ' RecordType.developerName = \''+VALID_ACCOUNTING_PIECE_TYPE[VALID_ACCOUNTING_PIECE_TYPE.size()-1]+'\')';
            List<AccountingPiece__c> accountingPieceList = Database.query(accountingPieceQuery);
            System.debug('## accountingPieceList: '+accountingPieceList);
            System.debug('## accountingPieceList.size: '+accountingPieceList.size());

            if(!accountingPieceList.isEmpty()){
                for(AccountingPiece__c accountingPiece : accountingPieceList){
                    AccountingObject accountingObject = createAccountingObjectFromAccountingPiece(accountingPiece);
                    accountingObjectList.Add(accountingObject);
                }
            }
        }

        result.accountingObjects = accountingObjectList;
        System.debug('### result:'+result);
        System.debug('### FIN LWC_ExportAccountingReportPDF.getAccountingObjectsInformations');
        return result;
    }

    /**
    * @description Fonction pour récupérer les informations des enregistrements comptables et les convertir en objets JSON, spécifique au journal des banques
    * @param serviceEntityId Id du Dépot séléctionné
    * @param startDate Date de début d'observation
    * @param endDate Date de fin d'observation
    * @param bankAccounts Liste des comptes bancaires sélectionnés
    * @return otherTypeReportObject Objet contenant les informations des enregistrements comptables
    */
    public static BankReportObject getBankReportObjectsInformations(Id serviceEntityId, Date startDate, Date endDate, String[] bankAccounts){
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.getBankReportObjectsInformations');
        System.debug('## serviceEntityId :'+ serviceEntityId);
        System.debug('## startDate :'+ startDate);
        System.debug('## endDate :'+ endDate);

        BankReportObject result = new BankReportObject();
        List<BankReportLine> listBankReportLine = new List<BankReportLine>();
        List<String> bankAccountNameList = new List<String>();
        Map<String,List<AccountingObject>> detailsByBankMap = new Map<String,List<AccountingObject>>();
        Map<String,List<AccountingObject>> distributionByBankMap = new Map<String,List<AccountingObject>>();
        Set<Id> bankAccountIds = new Set<Id>();


        if(bankAccounts.size() > 0){
            for(String bankAccount : bankAccounts){
                bankAccountIds.Add(bankAccount.substringBefore('/'));
            }
        }

        System.debug('## bankAccountIds :'+bankAccountIds);
        
        
        // *************** Récupération des données ********************
        // *************************************************************

        // --- Cas Journal des banques ---
        //Récupération des écritures comptables - Détails
        Map<String, String> relations = new Map<String, String>();
        relations.put('AccountingEntry__c.RecordType', 'RecordType'); 
        relations.put('AccountingEntry__c.inputEntity__r', 'Account');
        relations.put('AccountingEntry__c.entityBankAccount__r', 'Referencial__c');
        //string accountingEntryQuery = SchemaUtils.getQuery('AccountingEntry__c', 'inputEntity__c', serviceEntityId, relations);
        string accountingEntryQuery = SchemaUtils.getQuery('AccountingEntry__c', 'entityBankAccount__c', bankAccountIds, relations);
        accountingEntryQuery += ' AND entryDate__c >= :startDate AND entryDate__c <= :endDate';
        List<AccountingEntry__c> accountingEntryList = Database.query(accountingEntryQuery);
        Set<Id> accountingEntryIds = new Set<Id>();
        System.debug('## accountingEntryList: '+accountingEntryList);
        System.debug('## accountingEntryList.size: '+accountingEntryList.size());

        if(!accountingEntryList.isEmpty()){
            for(AccountingEntry__c accountingEntry : accountingEntryList){
                accountingEntryIds.Add(accountingEntry.Id);
                AccountingObject accountingObject = createAccountingObjectFromAccountingEntry(accountingEntry);
                if(detailsByBankMap.containsKey(accountingObject.entityBankAccount)){
                    detailsByBankMap.get(accountingObject.entityBankAccount).add(accountingObject);
                }
                else{
                    bankAccountNameList.Add(accountingObject.entityBankAccount);
                    List<AccountingObject> newValue = new List<AccountingObject>{accountingObject};
                    detailsByBankMap.put(accountingObject.entityBankAccount, newValue);
                }
            }
        }

        //Récupération des pièces comptables - Distribution
        //Somme des montants des pièces comptables regroupés par Banque / Entité de service de la commande /Type de commande / Type de pièce
        List<String> validRecordTypeIdList = new List<String>{ ACCOUNTINGPIECE_UNPAID_RTID, ACCOUNTINGPIECE_RECEIPT_RTID, ACCOUNTINGPIECE_RECEIPTCANCELLATION_RTID};
        AggregateResult[] aggregateAccountingPiecesQuery = [SELECT entityBankAccount__r.Name bankAccount, order__r.serviceEntity__r.Name orderServiceEntity, order__r.Type orderType, RecordType.Name recordType, sum(amount__c) sumAmount FROM AccountingPiece__c WHERE
                                                    accountingDate__c >= :startDate AND
                                                    accountingDate__c <= :endDate AND
                                                    //RecordTypeId IN :validRecordTypeIdList AND
                                                    (RecordTypeId =: ACCOUNTINGPIECE_UNPAID_RTID OR RecordTypeId =: ACCOUNTINGPIECE_RECEIPT_RTID OR RecordTypeId =: ACCOUNTINGPIECE_RECEIPTCANCELLATION_RTID) AND
                                                    order__c != null AND
                                                    accountingEntry__c IN :accountingEntryIds
                                                    GROUP BY entityBankAccount__r.name, order__r.serviceEntity__r.Name, order__r.Type, RecordType.Name];
        if(aggregateAccountingPiecesQuery!=null){
            for(AggregateResult accountingPieceSum : aggregateAccountingPiecesQuery){
                AccountingObject accountingObject = createAccountingObjectFromAggregateResult(accountingPieceSum, 'AccountingPiece__c');
                if(distributionByBankMap.containsKey(accountingObject.entityBankAccount)){
                    distributionByBankMap.get(accountingObject.entityBankAccount).add(accountingObject);
                }
                else{
                    if(!bankAccountNameList.Contains(accountingObject.entityBankAccount)) {
                        bankAccountNameList.Add(accountingObject.entityBankAccount);
                    }
                    List<AccountingObject> newValue = new List<AccountingObject>{accountingObject};
                    distributionByBankMap.put(accountingObject.entityBankAccount, newValue);
                }
            }
        }

        //Récupération des Ecritures comtpables manuelles - Distribution
        List<String> invalidRecordTypeIdList = new List<String>{ ACCOUNTINGENTRY_BANKREMITTANCE_RTID , ACCOUNTINGENTRY_UNPAID_RTID, ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RTID };
        AggregateResult[] aggregateAccountingEntryQuery = [SELECT entityBankAccount__r.Name bankAccount, inputEntity__r.Name inputEntity, RecordType.Name recordType, sum(amount__c) sumAmount FROM AccountingEntry__c WHERE
                                                    entryDate__c >= :startDate AND
                                                    entryDate__c <= :endDate AND
                                                    //RecordTypeId NOT IN :invalidRecordTypeIdList AND
                                                    RecordTypeId !=:ACCOUNTINGENTRY_BANKREMITTANCE_RTID AND RecordTypeId !=:ACCOUNTINGENTRY_UNPAID_RTID AND RecordTypeId !=:ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RTID AND
                                                    //inputEntity__c = :serviceEntityId
                                                    entityBankAccount__c IN :bankAccountIds
                                                    GROUP BY entityBankAccount__r.name, inputEntity__r.Name, RecordType.Name];
        if(aggregateAccountingEntryQuery!=null){
            for(AggregateResult accountingEntrySum : aggregateAccountingEntryQuery){
                AccountingObject accountingObject = createAccountingObjectFromAggregateResult(accountingEntrySum, 'AccountingEntry__c');
                if(distributionByBankMap.containsKey(accountingObject.entityBankAccount)){
                    distributionByBankMap.get(accountingObject.entityBankAccount).add(accountingObject);
                }
                else{
                    if(!bankAccountNameList.Contains(accountingObject.entityBankAccount)) {
                        bankAccountNameList.Add(accountingObject.entityBankAccount);
                    }
                    List<AccountingObject> newValue = new List<AccountingObject>{accountingObject};
                    distributionByBankMap.put(accountingObject.entityBankAccount, newValue);
                }
            }
        }

        //Création bankReportLines
        for(String bankAccountName : bankAccountNameList){
            BankReportLine newLine = new BankReportLine();
            newLine.bankAccountName = bankAccountName;
            newLine.details = detailsByBankMap.get(bankAccountName);
            newLine.distribution = distributionByBankMap.get(bankAccountName);
            listBankReportLine.Add(newLine);
        }
        if(!listBankReportLine.isEmpty()){
            result.bankAccountLines = listBankReportLine;
        }
        System.debug('### result:'+result);
        System.debug('### FIN LWC_ExportAccountingReportPDF.getBankReportObjectsInformations');
        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON à partir d'un avoir
    * @param creditMemo enregistrement Avoir
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObjectFromCreditMemo(CreditMemo__c creditMemo){
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.createAccountingObjectFromCreditMemo');
        System.debug('## recordType :'+creditMemo.RecordTypeId);
        System.debug('## recordType Name :'+creditMemo.RecordType.Name);

        AccountingObject result = createAccountingObject(creditMemo.Id, creditMemo.RecordType.Name, creditMemo.Name, creditMemo.amount__c);

        result.billingName = creditMemo.billingName__c;
        result.reference = creditMemo.creditMemoReference__c;
        result.status = creditMemo.Status__c;
        result.accountingDate = creditMemo.creditMemoDate__c;
        result.refundDate = creditMemo.refundDate__c;
        result.refundReason = creditMemo.refundReason__r.Name;
        result.pretaxAmount = creditMemo.pretaxAmount__c;
        result.VATAmount = creditMemo.VATAmount__c;
        result.VATAmount1 = creditMemo.VATAmount1__c;
        result.VATRate1 = creditMemo.VATRate1__c;
        result.VATAmount2 = creditMemo.VATAmount2__c;
        result.VATRate2 = creditMemo.VATRate2__c;
        result.VATAmount3 = creditMemo.VATAmount3__c;
        result.VATRate3 = creditMemo.VATRate3__c;
        result.orderNumber = creditMemo.customerOrder__r.OrderNumber;
    
        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON à partir d'une facture
    * @param invoice enregistrement Facture
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObjectFromInvoice(Invoice__c invoice){
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.createAccountingObjectFromInvoice');
        AccountingObject result = createAccountingObject(invoice.Id, invoice.recordType.Name, invoice.Name, invoice.amount__c);

        result.billingName = invoice.billingName__c;
        result.reference = invoice.invoiceReference__c;
        result.status = invoice.Status__c;
        result.accountingDate = invoice.invoiceDate__c;
        result.paymentDate = invoice.paymentDate__c;
        result.pretaxAmount = invoice.pretaxAmount__c;
        result.VATAmount = invoice.VATAmount__c;
        result.VATAmount1 = invoice.VATAmount1__c;
        result.VATRate1 = invoice.VATRate1__c;
        result.VATAmount2 = invoice.VATAmount2__c;
        result.VATRate2 = invoice.VATRate2__c;
        result.VATAmount3 = invoice.VATAmount3__c;
        result.VATRate3 = invoice.VATRate3__c;
        result.orderNumber = invoice.customerOrder__r.OrderNumber;
        result.installResource = invoice.customerOrder__r.installResource__r.Name;

        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON à partir d'une pièce comptable
    * @param accountingPiece enregistrement Pièce comptable
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObjectFromAccountingPiece(AccountingPiece__c accountingPiece){
        AccountingObject result = createAccountingObject(accountingPiece.Id, accountingPiece.RecordType.Name, accountingPiece.Name, accountingPiece.amount__c);

        result.billingName = accountingPiece.Order__r.billingName__c;
        result.accountingDate = accountingPiece.accountingDate__c;
        result.pieceDate = accountingPiece.pieceDate__c;
        result.miscellaneousOperationType = accountingPiece.miscellaneousOperationType__c;
        result.entityBankAccount = accountingPiece.entityBankAccount__r.Name;
        result.inputEntity = accountingPiece.inputEntity__r.Name;
        result.orderEntity = accountingPiece.orderEntity__r.Name;
        result.orderType = accountingPiece.Order__r.Type;
        result.orderNumber = accountingPiece.Order__r.OrderNumber;
        result.activatedDate = accountingPiece.Order__r.activatedDate;

        result.comment = accountingPiece.comments__c;
        result.accountingCurrency = accountingPiece.currency__c;
        result.externalBank = accountingPiece.externalBank__c;
        result.salesEntity = accountingPiece.order__r.salesEntity__r.Name;
        result.parentSalesEntity = accountingPiece.order__r.salesEntity__r.Parent.Name;
        result.afterSalesService = accountingPiece.order__r.afterSalesService__r.Name;
        result.effectiveDate = accountingPiece.order__r.effectiveDate;
        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON à partir d'une écriture comptable
    * @param accountingEntry enregistrement écriture comptable
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObjectFromAccountingEntry(AccountingEntry__c accountingEntry){
        AccountingObject result = createAccountingObject(accountingEntry.Id, accountingEntry.RecordType.Name, accountingEntry.Name, accountingEntry.amount__c);

        result.reference = accountingEntry.KparKReference__c;
        result.label = accountingEntry.label__c;
        result.accountingDate = accountingEntry.entryDate__c;
        result.category = getCategoryFromType(accountingEntry.type__c);
        result.type = accountingEntry.type__c;
        result.bank = accountingEntry.entityBankAccount__r.bank__c;
        result.entityBankAccount = accountingEntry.entityBankAccount__r.Name;
        result.inputEntity = accountingEntry.inputEntity__r.Name;

        return result;
    }

    /**
    * @description Fonction pour initialiser l'objet JSON Accountingobject avec les valeurs de base communes à chaque objet
    * @param recordId Id de l'enregistrement
    * @param recordTypeName Type de l'enregistrement
    * @param recordName Nom de l'enregistrement (numéro)
    * @param recordAmount Montant (TTC)
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObject(Id recordId, String recordTypeName, String recordName, Decimal recordAmount){
        AccountingObject result = new AccountingObject();
        result.Id = recordId;
        result.recordType = recordTypeName;
        result.name = recordName;
        result.amount = recordAmount;

        return result;
    }

    /**
    * @description Fonction pour construire l'objet JSON à partir d'une aggrégation de pièces ou écritures comptables
    * @param sumAccountingPieceResult résultat d'une requete d'aggrégation de pièces comptables regroupées par Compte bancaire, Entité de service de la commande, Type de commande, Type de pièce
    * @return AccountingObject Objet JSON représentant les objets comptables
    */
    public static AccountingObject createAccountingObjectFromAggregateResult(AggregateResult sumAccountingPieceResult, String objectName){
        AccountingObject result = new AccountingObject();
        result.recordType = (string)sumAccountingPieceResult.get('recordType');
        result.amount = (Decimal)sumAccountingPieceResult.get('sumAmount');
        result.entityBankAccount = (string)sumAccountingPieceResult.get('bankAccount');
        result.distributionType = 'Dont Contrat';
        result.type = getTypeFromAccountingRtName(result.recordType);

        //Cas aggrégation de pièces comptables
        if(objectName == 'AccountingPiece__c'){
            result.distributionEntity = (string)sumAccountingPieceResult.get('orderServiceEntity');

            if(sumAccountingPieceResult.get('orderType') != 'Commande client'){
                result.distributionType = 'Dont SAV';
            }
        }
        //Cas aggrégation d'écritures comptables
        else if(objectName == 'AccountingEntry__c'){
            result.distributionEntity = (string)sumAccountingPieceResult.get('inputEntity');
        }

        result.category = getCategoryFromType(result.type);
               
        return result;
    }

    //#endregion

    /***************************************************/
    /* VALEURS CALCULEES                                *
    /***************************************************/

    //#region calculatedvalues
    
    /**
    * @description Fonction pour déterminer la catégorie à attribuer en fonction de l'age
    * @param age Age en nombre de jours
    * @return string contenant le libellé de la catégorie
    */
    public static string getCategoryFromAge(Integer age){
        if(age < 15){
            return '0 – 15 jours';
        }
        else if(age < 30.5){
            return '15 jours – 1 mois';
        }
        else if(age < 61){
            return '1 – 2 mois';
        }
        else if(age < 91.5){
            return '2 – 3 mois';
        }
        else if(age < 183){
            return '3 – 6 mois';
        }
        else if(age < 274.5){
            return '6 – 9 mois';
        }
        else{
            return '> 9 mois';
        }
    }

    /**
    * @description Fonction pour déterminer la catégorie à attribuer en fonction du type
    * @param type type de l'écriture comptable
    * @return string contenant le libellé de la catégorie
    */
    public static string getCategoryFromType(String type){
        if(type == '1 - Client' || type == '2 - Autre recette'){
            return 'Recettes';
        }
        else{
            return 'Dépenses';
        }
    }

    /**
    * @description Fonction pour déterminer le type à attribuer en fonction du type de l'enregistrement
    * @param recordTypeName Libellé du type de l'enregistrement
    * @return string contenant le libellé du type
    */
    public static string getTypeFromAccountingRtName(string recordTypeName){
        switch on recordTypeName{
            //Pièces comptables
            when 'Encaissement' {
                return '1 - Client';
            }
            when 'Annulation encaissement remis' {
                return '7 - Annulation remise';
            }
            when 'Impayé bancaire' {
                return '3 - Impayé';
            }
            //Ecritures comptables     
            when 'Autre recette'{
                return '2 - Autre recette';
            }
            when 'Frais bancaire'{
                return '4 - Frais bancaire';
            }
            when 'Retrait espèce'{
                return '5 - Retrait espèce';
            }
            when 'Virement siège'{
                return '6 - Virement siège';
            }
            when 'Autre dépense'{
                return '8 - Ecart conversion';
            }
            when 'Ecart conversion'{
                return '9 - Autre dépense';
            }
        }

        return '';
    }

    /**
    * @description Fonction pour calculer le montant total facturé d'une commande
    * @param orderId Id de la commande client
    * @param invoiceList Liste des factures
    * @return Somme des montant TTC des factures associées à la commande
    */
    public static decimal getSumAmountInvoices(Id orderId, Map<Id, List<Invoice__c>> invoiceList){
        Decimal result = 0;

        if(!invoiceList.isEmpty()){
            if(invoiceList.containsKey(orderId)){
                List<Invoice__c> relatedInvoices = invoiceList.get(orderId);
                for(Invoice__c invoice : relatedInvoices){
                    if(invoice.amount__c !=null){
                        result += invoice.amount__c;
                    }
                }
            }
        }
        return result;
    }

    /**
    * @description Fonction pour calculer le montant total des avoirs d'une commande
    * @param orderId Id de la commande client
    * @param invoiceList Liste des avoirs
    * @return Somme des montant des avoirs associées à la commande
    */
    public static decimal getSumAmountCreditMemos(Id orderId, Map<Id, List<CreditMemo__c>> creditMemoList){
        Decimal result = 0;

        if(!creditMemoList.isEmpty()){
            if(creditMemoList.containsKey(orderId)){
                List<CreditMemo__c> relatedCreditMemos = creditMemoList.get(orderId);
                for(CreditMemo__c creditMemo : relatedCreditMemos){
                    if(creditMemo.amount__c !=null){
                        result += creditMemo.amount__c;
                    }
                }
            }
        }
        return result;
    }

    /**
    * @description Fonction pour calculer le montant encaissé, le montant portefeuille et le montant CD à partir des pièces comptables de la commande
    * @param orderId Id de la commande client
    * @param invoiceList Liste des pièces comptables
    * @param observationDate Date d'observation
    * @return Liste de montants contenant dans cet ordre le montant encaissé,portefeuille et CD
    */
    public static List<decimal> getSumAmountAccountingPieces(Id orderId, Map<Id, List<AccountingPiece__c>> accountingPieceList, Date observationDate){
        List<Decimal> results = new List<Decimal>();
        //Montant encaissé (sommes des montants des pièces non CD et non encaissement composite ayant une date comptable inférieure ou égale à la date d'observation)
        Decimal amountRecordedAccountingPieces = 0;
        //Montant portefeuille (somme des montants des pièces non encaissement composite n'ayant pas de date comptable ou une date supérieure à la date d'observation)
        Decimal amountUnecordedAccountingPieces = 0;
        //Montant CD (somme des motnants des pièces de type Créance douteuse ayant une date comptable inférieure ou égale à la date d'observation)
        Decimal amountDoubtfulAccountingPieces = 0;

        if(!accountingPieceList.isEmpty()){
            if(accountingPieceList.containsKey(orderId)){
                List<AccountingPiece__c> relatedAccountingPieces = accountingPieceList.get(orderId);
                for(AccountingPiece__c accountingPiece : relatedAccountingPieces){
                    if(accountingPiece.amount__c !=null){
                        if(accountingPiece.RecordTypeId != ACCOUNTINGPIECE_COMPOSITERECEIPT_RTID){
                            if(accountingPiece.accountingDate__c !=null && accountingPiece.accountingDate__c <= observationDate){
                                if(accountingPiece.RecordTypeId != ACCOUNTINGPIECE_DOUBTFULDEBT_RTID){
                                    amountRecordedAccountingPieces += accountingPiece.amount__c;
                                }
                                else{
                                    amountDoubtfulAccountingPieces += accountingPiece.amount__c;
                                }
                            }
                            else if(accountingPiece.pieceDate__c <= observationDate){
                                amountUnecordedAccountingPieces += accountingPiece.amount__c;
                            }
                        }
                    }
                }
            }
        }
        results.Add(amountRecordedAccountingPieces);
        results.Add(amountUnecordedAccountingPieces);
        results.Add(amountDoubtfulAccountingPieces);

        return results;
    }

    //#endregion

    /***************************************************/
    /* GESTION DOCUMENT                                *
    /***************************************************/

    //#region documentHelper

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF au dépot en tant que Salesforce File (ContentDocument)
    * @param serviceEntityId Id du Dépot
    * @param docName Nom du document
    * @param docFormat Format du document à générer (PDF ou Excel)
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Id serviceEntityId, String docName, String docFormat, Blob document) {
        System.debug('### DEBUT LWC_ExportAccountingReportPDF.linkDocumentToRecord');
        System.debug('## serviceEntityId: '+serviceEntityId); 
        System.debug('## docName: '+docName);
        String result;

        try {  
            // Link the document link a content document            
            String filename = docName + '.' + docFormat;

            // Si un fichier avec le même nom existe déjà lié au record, alors on supprime
            Set<String> docIdToCheck = new Set<String>();
            for(ContentDocumentLink ctLinkToDelete : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :serviceEntityId]) {
                docIdToCheck.add(ctLinkToDelete.ContentDocumentId);
            }
            System.debug('## docIdToCheck: '+docIdToCheck);
            if(!docIdToCheck.isEmpty()) {
                List<ContentDocument> docToDelete = new List<ContentDocument>();
                for(ContentVersion ctVerToDelete : [SELECT Id, ContentDocumentId FROM ContentVersion 
                                                        WHERE Title = :filename AND ContentDocumentId IN :docIdToCheck]) {
                    System.debug('## Document to delete: '+ctVerToDelete.ContentDocumentId);
                    docToDelete.add(new ContentDocument(Id = ctVerToDelete.ContentDocumentId));
                }
                if(!docToDelete.isEmpty()) {
                    delete docToDelete;
                }
            }

            // Création document et lien
            result = Utils_APIMerkure.createContentDocument(serviceEntityId, filename, document, 'NotCollectedReport '+docFormat, false);
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_ExportAccountingReportPDF.linkDocumentToRecord');
        return result;
    }

    //#endregion

    /***************************************************/
    /* UTILITAIRE                                *
    /***************************************************/

    //#region utility

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

    //#endregion

    /***************************************************/
    /* OBJECT JSON                                     *
    /***************************************************/

    //#region jsonObject

    public class NotCollectedReportObject {
        public List<CustomerOrderObject> Orders;
    }

    public class BankReportObject {
        public List<BankReportLine> bankAccountLines; 
    }

    public class OtherTypeReportObject{
        public List<AccountingObject> accountingObjects;
    }
    
    public class BankReportLine {
        public string bankAccountName; 
        public List<AccountingObject> details;
        public List<AccountingObject> distribution;
    }

    public class CustomerOrderObject {
        //N° de commande
        public string orderNumber;
        //Contrat GC
        public string legacyReference;
        //Nom du client
        public string billingName;
        //Début de la commande
        public Date effectiveDate;
        //Statut
        public string oldCompositeStatus;
        //Age
        public Integer age;
        //Catégorie
        public string category;
        //Montant HT
        public Decimal pretaxAmount;
        //Montant Facturé
        public Decimal invoicesAmount;
        //Montant Avoir
        public Decimal creditMemosAmount;
        //Débit
        public Decimal debit;
        //Montant encaissé
        public Decimal recordedAccountingPiecesAmount;
        //Montant portefeuille
        public Decimal unrecordedAccountingPiecesAmount;
        //Montant CD
        public Decimal doubtfulAccountingPieceAmount;
        //Solde
        public Decimal balance;
        //Ventilation
        public string ventilation;
    }

    public class AccountingObject {
        //Id
        public string id;
        //Type d'enregistrement
        public string recordType;
        //Nom de facturation
        public string billingName;
        //Numéro
        public string name;
        //Référence
        public string reference;
        //Statut
        public string status;
        //Date comptable
        public Date accountingDate;
        //Date de la pièce
        public Date pieceDate;
        //Date de paiement
        public Date paymentDate; 
        //Date de remboursement
        public Date refundDate;
        //Date d'activation
        public DateTime activatedDate;
        //Motif de remboursement
        public string refundReason;
        //Montant (HT)
        public Decimal pretaxAmount;
        //Montant (TTC)
        public Decimal amount;
        //Montant TVA
        public Decimal VATAmount;
        //Montant TVA 1
        public Decimal VATAmount1;
        //Taux TVA 1
        public Decimal VATRate1;
        //Montant TVA 2
        public Decimal VATAmount2;
        //Taux TVA 2
        public Decimal VATRate2;
        //Montant TVA 3
        public Decimal VATAmount3;
        //Taux TVA 3
        public Decimal VATRate3;
        //Numéro de commande
        public string orderNumber;
        //Ressource d'installation
        public string installResource;
        //Type opération Diverse
        public string miscellaneousOperationType;
        //Compte bancaire
        public string entityBankAccount;
        //Banque
        public string bank;
        //Entité de saisie
        public string inputEntity;
        //Entité de la commande
        public string orderEntity;
        //Type de commande
        public string orderType;
        //Libellé
        public string label;
        //Catégorie
        public string category;
        //Type
        public string type;
        //Entité de répartition
        public string distributionEntity;
        //Type de répartition
        public string distributionType;
        //Commentaires
        public string comment;
        //Devise
        public string accountingCurrency;
        //Banque externe
        public string externalBank;
        //Entité commerciale
        public string salesEntity;
        //Entité commerciale parente
        public string parentSalesEntity;
        //Dossier SAV
        public string afterSalesService;
        //Date de début de la commande
        public Date effectiveDate;
    }

    //#endregion

}