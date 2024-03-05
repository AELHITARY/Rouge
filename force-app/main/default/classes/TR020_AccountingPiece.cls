//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_AccountingPiece
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/05/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_AccountingPiece {
    // Accounts RT
    private static final Id RT_ACC_FUNDINGORG = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_FUNDINGORG_RT);
    
    // Accounting Entries RT
    private static final Id RT_AE_BANKREMITTANCE = DAL.getRecordTypeIdByDevName('AccountingEntry__c',Constants.ACCOUNTINGENTRY_BANKREMITTANCE_RT);
    private static final Id RT_AE_BANKREMITTANCE_CANCELLATION = DAL.getRecordTypeIdByDevName('AccountingEntry__c',Constants.ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RT);
    private static final Id RT_AE_UNPAID = DAL.getRecordTypeIdByDevName('AccountingEntry__c',Constants.ACCOUNTINGENTRY_UNPAID_RT);
    
    // Accounting Pieces RT
    private static final Id RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final Id RT_AP_COMPOSITERECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);
    private static final Id RT_AP_CHECKREQUEST = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_CHECKREQUEST_RT);
    private static final Id RT_AP_REFUND = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_REFUND_RT);
    private static final Id RT_AP_RECEIPTCANCELLATION = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPTCANCELLATION_RT);
    private static final Id RT_AP_UNDELIVEREDRECEIPTCANCELLATION = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_UNDELIVERED_RECEIPTCANCELLATION_RT);
    private static final Id RT_AP_UNPAID = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_UNPAID_RT);

    /**
    * @description Méthode pour les règles de validation de l'objet personnalisé Pièce comptable
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingPiece.applyValidationRules');
        List<AccountingPiece__c> newAccPieces = (List<AccountingPiece__c>)Trigger.new; 
        List<AccountingPiece__c> oldAccPieces = (List<AccountingPiece__c>)Trigger.old;
        
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            for(AccountingPiece__c newAccPiece : newAccPieces){
                // Bypass pour les pièces issues de la reprise d'historique
                if(newAccPiece.isLegacy__c == false){

                    // VR : Valeur parente interdite si RT différent de 'Receipt', 'ReceiptCancellation', 'UndeliveredReceiptCancellation', 'Unpaid'
                    if(newAccPiece.RecordTypeId != RT_AP_RECEIPT && newAccPiece.RecordTypeId != RT_AP_RECEIPTCANCELLATION 
                        && newAccPiece.RecordTypeId != RT_AP_UNDELIVEREDRECEIPTCANCELLATION && newAccPiece.RecordTypeId != RT_AP_UNPAID
                        && newAccPiece.isLegacy__c == false && newAccPiece.parent__c != null )
                    {
                        System.debug('## newAccPiece.parent__c : ' + newAccPiece.parent__c);
                        newAccPiece.addError(Label.accPieces_msg_parentForbiddenForTheseRT);
                    }  
                }
            }
        }

        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
            applyPostUpdateValidationRules(userContext);
        }
        
        System.debug('### FIN TR020_AccountingPiece.applyValidationRules');
    }

    /**
    * @description Méthode pour interdire la suppression d'une pièce comptable pour 4 ans si elle a une date comptable renseignée. 
    * Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotDeleteAccountingPiece(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingPiece.cannotDeleteAccountingPiece');
        
        List<AccountingPiece__c> oldAccPieces = (List<AccountingPiece__c>)Trigger.old;
        for(AccountingPiece__c oldAccPiece : oldAccPieces){
            if(Trigger.isDelete && Trigger.isBefore && oldAccPiece.isAccountingPieceLocked__c) {
                oldAccPiece.addError(Label.accPieces_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_AccountingPiece.cannotDeleteAccountingPiece');
    }

    /**
    * @description Méthode pour interdire la création d'une pièce comptable pour 4 ans si elle a une pièce comptable parente avec une date comptable renseignée. 
    * Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotCreateAccountingPiece(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingPiece.cannotCreateAccountingPiece');
        
        List<AccountingPiece__c> newAccPieces = (List<AccountingPiece__c>)Trigger.new;
        List<String> accPieceParentIdList = new List<String>();
        Map<Id,AccountingPiece__c> accPieceParentMap = new Map<Id,AccountingPiece__c>();
        for(AccountingPiece__c newAccPiece : newAccPieces){
            if(Trigger.isInsert && String.isNotBlank(newAccPiece.parent__c)) {
                accPieceParentIdList.add(newAccPiece.parent__c);
            }
        }

        if(!accPieceParentIdList.isEmpty()) {
            accPieceParentMap = new Map<Id, AccountingPiece__c>([SELECT Id, isAccountingPieceLocked__c FROM AccountingPiece__c WHERE Id IN :accPieceParentIdList]);
            System.debug('## accPieceParentMap: '+accPieceParentMap);

            // Vérification des pieces parent
            for(AccountingPiece__c newAccPiece : newAccPieces){
                System.debug('## Id: '+newAccPiece.Id);
                System.debug('## Parent: '+newAccPiece.parent__c);
                if(Trigger.isInsert && accPieceParentMap != null 
                    && accPieceParentMap.get(newAccPiece.parent__c) != null
                    && accPieceParentMap.get(newAccPiece.parent__c).isAccountingPieceLocked__c)
                {
                    System.debug('## Parent is locked: '+newAccPiece.parent__c);
                    newAccPiece.addError(Label.accPieces_msg_cantCreate);
                }  
            }
        }
        
        System.debug('### FIN TR020_AccountingPiece.cannotCreateAccountingPiece');
    }

    /**
    * @description Fonctions pour faire appels aux MAJ des champs et des status
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }

    /**
    * @description Règle de mise à jour du statut des factures
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingPiece : applyStatusUpdateRules');
        
        // A - Initialisation des données intermédiaires 
        List<AccountingPiece__c> newAccPieces = (List<AccountingPiece__c>)Trigger.new; 
        List<AccountingPiece__c> oldAccPieces = (List<AccountingPiece__c>)Trigger.old;
        
        /**
         Calcul du statut (status__c):
        - Annulé : cancelledAmount__c ≥ amount__c
        - Comptabilisé : Date comptable renseigné
        - En cours : Par défaut
         */

        // B - Application des règles de mise à jour 
        for(AccountingPiece__c newAccPiece : newAccPieces){
            System.debug('## Accounting Piece Id: '+newAccPiece.Id);

            // MAJ du statut
            if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) { 
                System.debug('## Change status for accounting piece: ' + newAccPiece.Id);   
                if(newAccPiece.isInApprovalProcess__c) {  
                    System.debug('## status 1');
                    newAccPiece.status__c = Constants.ACCOUNTINGPIECE_STATUS_APPROVAL;
                } else if(newAccPiece.netAmount__c == 0 || newAccPiece.isRefused__c) {  
                    System.debug('## status 2');
                    newAccPiece.status__c = Constants.ACCOUNTINGPIECE_STATUS_CANCELED;
                } else if(newAccPiece.accountingDate__c != null) {
                    System.debug('## status 3');
                    newAccPiece.status__c = Constants.ACCOUNTINGPIECE_STATUS_COUNTED;
                } else {
                    System.debug('## status 4');
                    newAccPiece.status__c = Constants.ACCOUNTINGPIECE_STATUS_INPROGRESS;
                }
            }  
            System.debug('## Accounting Piece Status: '+newAccPiece.status__c);
        }
        System.debug('### FIN TR020_AccountingPiece : applyStatusUpdateRules');
    }

    /**
    * @description Règles de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
          
        System.debug('### DEBUT TR020_AccountingPiece.applyUpdateRules');
        List<AccountingPiece__c> newAccPieces = (List<AccountingPiece__c>)Trigger.new;  
        Map<Id, AccountingPiece__c> oldAccPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        Map<Id, Order> ordersMap = new Map<Id, Order>();
        Map<Id, AccountingPiece__c> parentsMap = new Map<Id, AccountingPiece__c>();
        Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>();    
        Map<Id, CreditMemo__c> creditMemosMap = new Map<Id, CreditMemo__c>();
        Map<Id, AccountingPiece__c> cancelledPiecesMap = new Map<Id, AccountingPiece__c>();
        List<BankAccountVisibility__c> bkvisList = new List<BankAccountVisibility__c>();
        Set<String> orderIds = new Set<String>();
        Set<String> parentIds = new Set<String>();
        Set<String> invoiceIds = new Set<String>();
        Set<String> orderEntiesId = new Set<String>();  
        Set<String> creditMemoIds = new Set<String>();
        Set<String> cancelledPieceIds = new Set<String>();
      
        // A - Recherche des objets associées 
        for (AccountingPiece__c newAccPiece : newAccPieces) {
            AccountingPiece__c oldAccPiece = oldAccPieces == null ? null : oldAccPieces.get(newAccPiece.id);            

            // Liste des Id des pièces parentes
            if(newAccPiece.parent__c != null){
                parentIds.add(newAccPiece.parent__c);
            }
            // Liste des Id des commandes
            if(newAccPiece.order__c != null){
                orderIds.add(newAccPiece.order__c);
            }
            // Liste des Id des factures
            if(newAccPiece.invoice__c != null){
                invoiceIds.add(newAccPiece.invoice__c);
            }   
            // Liste des Id des avoirs  
            if(newAccPiece.creditMemo__c != null){   
                creditMemoIds.add(newAccPiece.creditMemo__c);    
            }
            // Liste des Id des pièces annulée  
            if(newAccPiece.cancelledPiece__c != null){   
                cancelledPieceIds.add(newAccPiece.cancelledPiece__c);    
            }
        }

        // Récupération des enregistrements d'objets associés
        if(!parentIds.isEmpty()) {
            parentsMap = new Map<Id, AccountingPiece__c>([SELECT Id, inputEntity__c, orderEntity__c, account__c, order__c,
                                                pieceDate__c, dueDate__c, accountingDate__c, entityBankAccount__c, refundReason__c, paymentMethod__c,
                                                externalBank__c, externalReference__c, accountingEntry__c
                                        FROM AccountingPiece__c 
                                        WHERE Id IN :parentIds]);
        }
        if(!cancelledPieceIds.isEmpty()) {
            cancelledPiecesMap = new Map<Id, AccountingPiece__c>([SELECT Id, order__c, amount__c, cancelledAmount__c FROM AccountingPiece__c WHERE Id IN :cancelledPieceIds]);
            // Récupération des ID des commandes des factures
            for (AccountingPiece__c accP : cancelledPiecesMap.values()) {
                if(accP.order__c != null){
                    orderIds.add(accP.order__c);
                }
            }
        }
        // Récupération des factures
        if(!invoiceIds.isEmpty()) { 
            invoicesMap = new Map<Id, Invoice__c>([SELECT Id, customerOrder__c, amount__c FROM Invoice__c WHERE Id IN :invoiceIds]);
            // Récupération des ID des commandes des factures
            for (Invoice__c inv : invoicesMap.values()) {
                if(inv.customerOrder__c != null){
                    orderIds.add(inv.customerOrder__c);
                }
            }
        }       
        // Récupération des avoirs  
        if(!creditMemoIds.isEmpty()) {  
            creditMemosMap = new Map<Id, CreditMemo__c>([SELECT Id, customerOrder__c FROM CreditMemo__c WHERE Id IN :creditMemoIds]);   
            // Récupération des ID des commandes des factures   
            for (CreditMemo__c cred : creditMemosMap.values()) {    
                if(cred.customerOrder__c != null){  
                    orderIds.add(cred.customerOrder__c);    
                }   
            }   
        }  
        // Récupération des commandes
        if(!orderIds.isEmpty()) {
            ordersMap = new Map<Id, Order>([SELECT Id, AccountId, BillToContactId, billingName__c, BillingStreet, BillingPostalCode, BillingCity, Account.Name, BillingState, BillingCountry,
                                                salesEntity__c, salesEntity__r.rue__c, salesEntity__r.codePostal__c, salesEntity__r.ville__c, salesEntity__r.departement__c, chantier__c, amount__c,
                                                salesEntity__r.pays__c, salesEntity__r.Name, salesEntity__r.Ownership, salesEntity__r.complementAdresse__c, ShipToContactId, shippingName__c,
                                                ShippingStreet, ShippingPostalCode, ShippingCity, ShippingState, ShippingCountry, serviceEntity__c, serviceEntity__r.rue__c, serviceEntity__r.codePostal__c, 
                                                serviceEntity__r.ville__c, serviceEntity__r.departement__c, serviceEntity__r.pays__c, serviceEntity__r.Name, serviceEntity__r.complementAdresse__c,
                                                salesEntity__r.email__c, serviceEntity__r.email__c, salesEntity__r.Phone, serviceEntity__r.Phone, billingAdditionalAddress__c, shippingAdditionalAddress__c
                                                   FROM Order 
                                                   WHERE id IN :orderIds]);
            System.debug('## ordersMap: '+ordersMap );
        }   
                           
        // B - Application des règles de mise à jour 
        for (AccountingPiece__c newAccPiece : newAccPieces) {
            System.debug('## Id: '+newAccPiece.Id); 

            if(newAccPiece.order__c == null != null && newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT){
                newAccPiece.order__c = null;
            } 

            // Règle de MAJ de la commande selon le parent/piece annulée/facture/avoir
            if(newAccPiece.order__c == null){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null && parentsMap.get(newAccPiece.parent__c).order__c != null) {
                    newAccPiece.order__c = parentsMap.get(newAccPiece.parent__c).order__c;
                } else if(newAccPiece.cancelledPiece__c != null 
                    && cancelledPiecesMap.get(newAccPiece.cancelledPiece__c) != null 
                    && cancelledPiecesMap.get(newAccPiece.cancelledPiece__c).order__c != null
                ) {
                    newAccPiece.order__c = cancelledPiecesMap.get(newAccPiece.cancelledPiece__c).order__c;
                } else {
                    if(invoicesMap.get(newAccPiece.invoice__c) != null 
                        && invoicesMap.get(newAccPiece.invoice__c).customerOrder__c != null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT)
                    {
                        newAccPiece.order__c = invoicesMap.get(newAccPiece.invoice__c).customerOrder__c;
                    } else if(creditMemosMap.get(newAccPiece.creditMemo__c) != null  
                        && creditMemosMap.get(newAccPiece.creditMemo__c).customerOrder__c != null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT)  
                    {   
                        newAccPiece.order__c = creditMemosMap.get(newAccPiece.creditMemo__c).customerOrder__c;
                    }
                }
                System.debug('## Order: '+newAccPiece.order__c); 
            }

            // Règle de MAJ du compte selon la commande
            if(newAccPiece.account__c == null && newAccPiece.order__c != null 
                && ordersMap.get(newAccPiece.order__c) != null && ordersMap.get(newAccPiece.order__c).AccountId != null 
                && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT
            ){
                newAccPiece.account__c = ordersMap.get(newAccPiece.order__c).AccountId;
                System.debug('## Account: '+newAccPiece.account__c); 
            }

            // Règle de MAJ de l'entité de saisie selon le parent/commande
            if(newAccPiece.inputEntity__c == null){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).inputEntity__c != null){
                        newAccPiece.inputEntity__c = parentsMap.get(newAccPiece.parent__c).inputEntity__c;
                } else {
                    if(ordersMap.get(newAccPiece.order__c) != null && ordersMap.get(newAccPiece.order__c).serviceEntity__c != null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT){
                        newAccPiece.inputEntity__c = ordersMap.get(newAccPiece.order__c).serviceEntity__c;
                    }
                }
                System.debug('## Input Entity: '+newAccPiece.inputEntity__c); 
            }

            // Règle de MAJ de l'entité de commande selon le parent/commande
            if(newAccPiece.orderEntity__c == null ){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).orderEntity__c != null){
                        newAccPiece.orderEntity__c = parentsMap.get(newAccPiece.parent__c).orderEntity__c;
                } else {
                    if(ordersMap.get(newAccPiece.order__c) != null 
                        && ordersMap.get(newAccPiece.order__c).serviceEntity__c != null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT)
                    {
                        newAccPiece.orderEntity__c = ordersMap.get(newAccPiece.order__c).serviceEntity__c;
                    }
                }
                System.debug('## Order Entity: '+newAccPiece.orderEntity__c); 
            }

            // Règle de MAJ de la date de la pièce
            if(newAccPiece.pieceDate__c == null){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).pieceDate__c != null){
                        newAccPiece.pieceDate__c = parentsMap.get(newAccPiece.parent__c).pieceDate__c;
                } else {
                    newAccPiece.pieceDate__c = Date.today();
                }
                System.debug('## Piece Date: '+newAccPiece.pieceDate__c); 
            }

            // Règle de MAJ de l'écriture comptable pour une pièce enfant (demande #1200)(pousser dans la tr022 'updateAccEntryOnNewAccpiece')
            
            if(newAccPiece.accountingEntry__c == null){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).accountingEntry__c != null){ //modified
                        newAccPiece.accountingEntry__c = parentsMap.get(newAccPiece.parent__c).accountingEntry__c;
                } else {                    
                    newAccPiece.accountingEntry__c = null;
                }
            }
            // Règle de MAJ de la date d'échéance seulement pour Receipt
            if(newAccPiece.dueDate__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT)){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).dueDate__c != null){
                        newAccPiece.dueDate__c = parentsMap.get(newAccPiece.parent__c).dueDate__c;
                } else {
                    newAccPiece.dueDate__c = newAccPiece.pieceDate__c;
                }
                System.debug('## Due Date: '+newAccPiece.dueDate__c); 
            }

            // Règle de MAJ de la date comptable
            if(newAccPiece.RecordTypeId != RT_AP_RECEIPT && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT
                && newAccPiece.RecordTypeId != RT_AP_CHECKREQUEST && newAccPiece.RecordTypeId != RT_AP_REFUND 
                && newAccPiece.RecordTypeId != RT_AP_UNDELIVEREDRECEIPTCANCELLATION)
            {
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).accountingDate__c != null
                ){
                    newAccPiece.accountingDate__c = parentsMap.get(newAccPiece.parent__c).accountingDate__c;
                } else {
                    newAccPiece.accountingDate__c = newAccPiece.pieceDate__c;
                }
                System.debug('## Accounting Date: '+newAccPiece.accountingDate__c); 
            }

            //Règle de MAJ de la date comptable lors de l'approbation de demande de chèques
            if(newAccPiece.RecordTypeId == RT_AP_CHECKREQUEST && newAccPiece.accountingDate__c == null && newAccPiece.isValid__c == true){
                newAccPiece.accountingDate__c = System.today();
            }

            // Règle de MAJ du montant pour les Annulation et Impayés
            if(newAccPiece.amount__c == null && newAccPiece.cancelledPiece__c != null 
                && cancelledPiecesMap.get(newAccPiece.cancelledPiece__c) != null 
                && cancelledPiecesMap.get(newAccPiece.cancelledPiece__c).amount__c != null 
                && (newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION || newAccPiece.RecordTypeId == RT_AP_UNPAID 
                || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION)
            ) {
                newAccPiece.amount__c = -1*cancelledPiecesMap.get(newAccPiece.cancelledPiece__c).amount__c.setScale(2);
                System.debug('## Amount: '+newAccPiece.amount__c); 
            }

            // Règle de MAJ du montant pour les Encaissements
            if(newAccPiece.amount__c == null && newAccPiece.RecordTypeId == RT_AP_RECEIPT){
                if(newAccPiece.invoice__c != null && invoicesMap.get(newAccPiece.invoice__c) != null
                    && invoicesMap.get(newAccPiece.invoice__c).amount__c != null
                ){
                    newAccPiece.amount__c = invoicesMap.get(newAccPiece.invoice__c).amount__c.setScale(2);
                } else if(newAccPiece.order__c != null && ordersMap.get(newAccPiece.order__c) != null
                    && ordersMap.get(newAccPiece.order__c).amount__c != null
                ){
                    newAccPiece.amount__c = ordersMap.get(newAccPiece.order__c).amount__c.setScale(2);
                }
                System.debug('## Amount: '+newAccPiece.amount__c); 
            }

            // Règle de MAJ du compte bancaire par rapport au parent
            if(newAccPiece.entityBankAccount__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT 
                || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION || newAccPiece.RecordTypeId == RT_AP_UNPAID 
                || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION)
            )
            {
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null 
                    && parentsMap.get(newAccPiece.parent__c).entityBankAccount__c != null)
                {
                    newAccPiece.entityBankAccount__c = parentsMap.get(newAccPiece.parent__c).entityBankAccount__c;
                } 
                System.debug('## Entity BankAccount: '+newAccPiece.entityBankAccount__c); 
            }

            // Règle de MAJ du motif de remboursement
            if(newAccPiece.refundReason__c == null && 
                (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_CHECKREQUEST)){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).refundReason__c != null){
                        newAccPiece.refundReason__c = parentsMap.get(newAccPiece.parent__c).refundReason__c;
                } 
                System.debug('## Refund Reason: '+newAccPiece.refundReason__c); 
            }

            // Règle de MAJ du mode de règlement
            if(newAccPiece.paymentMethod__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT ||
                newAccPiece.RecordTypeId == RT_AP_CHECKREQUEST || newAccPiece.RecordTypeId == RT_AP_REFUND)){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).paymentMethod__c != null){
                        newAccPiece.paymentMethod__c = parentsMap.get(newAccPiece.parent__c).paymentMethod__c;
                } 
                System.debug('## Payment Method: '+newAccPiece.paymentMethod__c); 
            }

            // Règle de MAJ de Banque externe (Compte)
            if(newAccPiece.externalBank__c == null && newAccPiece.RecordTypeId == RT_AP_RECEIPT){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).externalBank__c != null){
                        newAccPiece.externalBank__c = parentsMap.get(newAccPiece.parent__c).externalBank__c;
                } 
                System.debug('## External Bank: '+newAccPiece.externalBank__c); 
            }

            // Règle de MAJ de Référence externe (Compte)
            if(newAccPiece.externalReference__c == null && newAccPiece.RecordTypeId == RT_AP_RECEIPT){
                if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                    parentsMap.get(newAccPiece.parent__c).externalReference__c != null){
                        newAccPiece.externalReference__c = parentsMap.get(newAccPiece.parent__c).externalReference__c;
                } 
                System.debug('## External Ref: '+newAccPiece.externalReference__c); 
            }
        }
      
        // C - Recherche des comptes bancaires si pas de parent
        for (AccountingPiece__c newAccPiece : newAccPieces) {
            // Liste des Id des entités de la commande
            if(newAccPiece.entityBankAccount__c == null && newAccPiece.orderEntity__c != null && 
                (newAccPiece.RecordTypeId == RT_AP_RECEIPT  || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION 
                || newAccPiece.RecordTypeId == RT_AP_UNPAID  || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION))
            {
                orderEntiesId.add(newAccPiece.orderEntity__c);
            }
        }
        if(!orderEntiesId.isEmpty()) {
            bkvisList = [SELECT Id, startDate__c, endDate__c, bankAccount__c, entity__c FROM BankAccountVisibility__c WHERE entity__c IN :orderEntiesId];
            System.debug('## bkvisList: '+bkvisList);
        
            // D - Second processus pour alimenter les comptes bancaires si pas de parent
            for (AccountingPiece__c newAccPiece : newAccPieces) {
                // Règle de MAJ du compte bancaire par rapport à l'entité de saisie
                if(newAccPiece.entityBankAccount__c == null && newAccPiece.orderEntity__c != null &&
                    (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION 
                    || newAccPiece.RecordTypeId == RT_AP_UNPAID || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION))
                {
                    System.debug('## Search bank account by order entity: '+newAccPiece.orderEntity__c);
                    Integer nbBankAccount = 0;
                    String bankAccountId;
                    for(BankAccountVisibility__c bkvisibility : bkvisList) {
                        if(newAccPiece.orderEntity__c == bkvisibility.entity__c && newAccPiece.pieceDate__c >= bkvisibility.startDate__c
                            && (bkvisibility.endDate__c == null || newAccPiece.pieceDate__c < bkvisibility.endDate__c)) 
                        {
                            nbBankAccount++;        
                            bankAccountId = bkvisibility.bankAccount__c;   
                            System.debug('## Potential bankAccountId: '+bankAccountId);
                        }
                    }                    
                    // Alimentation du compte bancaire seulement s'il existe un seul compte bancaire actif                      
                    if(nbBankAccount == 1) {
                        System.debug('## Update bank account by order entity: '+bankAccountId);
                        newAccPiece.entityBankAccount__c = bankAccountId;
                    } 
                }
            }     
        }
        // E - Règles sur les écritures comptables
        applyAccountingEntriesRules(newAccPieces);   
        
        System.debug('### FIN TR020_AccountingPiece.applyUpdateRules');
    }

    /**
    * @description Règles de mise à jour ou de création des écritures
    * @param newAccPieces Liste des pièces à traiter
    */
    private static void applyAccountingEntriesRules(List<AccountingPiece__c> newAccPieces) {
        System.debug('### DEBUT TR020_AccountingPiece.applyAccountingEntriesRules');
        List<String> bankAccIdToSearch = new List<String>();
        List<Date> accDateToSearch = new List<Date>();
        List<String> accEntriesIds = new List<String>();
        List<AccountingEntry__c> accEntriesList = new List<AccountingEntry__c>();
        List<AccountingEntry__c> accountingEntryToIns = new List<AccountingEntry__c>();
        List<AccountingPiece__c> accPiecesList = new List<AccountingPiece__c>();
        List<String> allPaymentMethodId = new List<String>();
        Map<String,Referencial__c> paymentMethodMap = new Map<String,Referencial__c>();
        List<AccountingPiece__c> accPiecesWithNewAccEnt = new List<AccountingPiece__c>();
        Map<String,AccountingEntry__c> accEntriesToInsertSet = new Map<String,AccountingEntry__c>();

        for(AccountingPiece__c newAccPiece : newAccPieces){
            allPaymentMethodId.add(newAccPiece.paymentMethod__c);
        }

        Map<Id,Referencial__c> allPaymentMethod = New Map<Id,Referencial__c>([SELECT Id, specificAccountingEntry__c FROM Referencial__c WHERE ID IN :allPaymentMethodId]);

        for(AccountingPiece__c newAccPiece : newAccPieces){
            if(allPaymentMethod.get(newAccPiece.paymentMethod__c) != null){
                paymentMethodMap.put(newAccPiece.Id, allPaymentMethod.get(newAccPiece.paymentMethod__c));
            }
            
        }
        
        // A - Recherche des écritures comptables
        for (AccountingPiece__c newAccPiece : newAccPieces) {
            // Liste des Id des écritures comptables si existantes
            if(newAccPiece.accountingEntry__c != null) {
                accEntriesIds.add(newAccPiece.accountingEntry__c);
                accPiecesList.add(newAccPiece);
            }

            // Liste des dates et des comptes nécessaire pour la recherche des écritures
            if(/*newAccPiece.accountingEntry__c == null && */newAccPiece.parent__c == null && newAccPiece.accountingDate__c != null 
                && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT 
                || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION  || newAccPiece.RecordTypeId == RT_AP_UNPAID)
            ) 
            {
                if(newAccPiece.accountingDate__c != null) {
                    accDateToSearch.add(newAccPiece.accountingDate__c);
                }
                if(String.isNotBlank(newAccPiece.entityBankAccount__c)) {
                    bankAccIdToSearch.add(newAccPiece.entityBankAccount__c);
                }
                accPiecesList.add(newAccPiece);
            }
        }  
        if(!accPiecesList.isEmpty() && !bankAccIdToSearch.isEmpty()) {        
            System.debug('## accEntriesIds: '+accEntriesIds);
            System.debug('## accDateToSearch: '+accDateToSearch);
            System.debug('## bankAccIdToSearch: '+bankAccIdToSearch);
            List<AccountingEntry__c> accEntriesToInsert = new List<AccountingEntry__c>();
            accEntriesList = [SELECT Id, RecordTypeId, entryDate__c, entityBankAccount__c, paymentType__c
                                FROM AccountingEntry__c WHERE (Id IN :accEntriesIds 
                                    OR (entryDate__c IN :accDateToSearch AND entityBankAccount__c IN :bankAccIdToSearch))
                                    AND (RecordTypeId = :RT_AE_BANKREMITTANCE OR RecordTypeId = :RT_AE_BANKREMITTANCE_CANCELLATION OR RecordTypeId = :RT_AE_UNPAID)
                                    AND closingDate__c = null];
            System.debug('## accEntriesList: '+accEntriesList);
        
            // B - Traitement des écritures comptables
            for (AccountingPiece__c newAccPiece : accPiecesList) {
                Referencial__c paymentMethod = paymentMethodMap.isEmpty() || paymentMethodMap.get(newAccPiece.Id) == null ? null : paymentMethodMap.get(newAccPiece.Id);
                // Traitement seulement si date comptable et parent
                if(newAccPiece.accountingDate__c != null && newAccPiece.parent__c == null){
                    // Recherche écriture existante
                    for(AccountingEntry__c accEnt : accEntriesList) {
                            if(newAccPiece.accountingDate__c == accEnt.entryDate__c && newAccPiece.entityBankAccount__c == accEnt.entityBankAccount__c 
                                && accEnt.RecordTypeId == mappingRecordType(newAccPiece.RecordTypeId)) 
                            {
                                System.debug('## Update AccountingEntry: '+accEnt);
                                newAccPiece.accountingEntry__c = accEnt.Id;
                            }
                    }               
                    // Si pas d'écriture trouvée, création
                    if((newAccPiece.accountingEntry__c == null || (paymentMethod != null && paymentMethod.specificAccountingEntry__c)) /*ajout #637*/ && newAccPiece.RecordTypeId != RT_AP_UNDELIVEREDRECEIPTCANCELLATION) {
                        System.debug('## Create new AccountingEntry');
                        System.debug('## newAccPiece.entityBankAccount__c:'+newAccPiece.entityBankAccount__c);
                        System.debug('## newAccPiece:'+newAccPiece.Id);
                        AccountingEntry__c accEnt = new AccountingEntry__c(
                            entryDate__c = newAccPiece.accountingDate__c,
                            entityBankAccount__c = newAccPiece.entityBankAccount__c,
                            amount__c = newAccPiece.amount__c,
                            AccPieceTemporaryId__c = newAccPiece.Id // Champ temporaire pour capturer Id de la pièce comptable
                        );
                        // Alimentation champs en fonction des RT
                        if(newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT) {
                            accEnt.RecordTypeId = RT_AE_BANKREMITTANCE;
                            accEnt.label__c = 'Encaissements';
                            accEnt.inputEntity__c = newAccPiece.inputEntity__c; 
                        } else if(newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION) {
                            accEnt.RecordTypeId = RT_AE_BANKREMITTANCE_CANCELLATION;
                            accEnt.label__c = 'Annulations d\'encaissement';
                            accEnt.inputEntity__c = newAccPiece.inputEntity__c;
                        } else if(newAccPiece.RecordTypeId == RT_AP_UNPAID) {
                            accEnt.RecordTypeId = RT_AE_UNPAID;
                            accEnt.label__c = 'Impayés';
                            accEnt.inputEntity__c = newAccPiece.inputEntity__c;
                        }
                        System.debug('## AccountingEntry: '+accEnt);
                        accEntriesToInsert.add(accEnt);
                        accEntriesToInsertSet.put(accEnt.AccPieceTemporaryId__c,accEnt);
                        accPiecesWithNewAccEnt.add(newAccPiece);
                        //insert accEnt;                        
                        //newAccPiece.accountingEntry__c = accEnt.Id;                     
                    }
                }
            }
            if(!accEntriesToInsert.isEmpty()){
                insert accEntriesToInsert;
                // Associer les écritures comptables crées à leurs pièces comptables
                for (AccountingPiece__c accPiece : accPiecesWithNewAccEnt) { 
                    if (accPiece.accountingEntry__c == null) {

                        String accPId = accEntriesToInsertSet.get(accPiece.Id).AccPieceTemporaryId__c;
                        if (accPiece.Id == accPId ) {
                            accPiece.accountingEntry__c = accEntriesToInsertSet.get(accPiece.Id).Id;
                        }
                        else {
                        accPiece.accountingEntry__c = null;
                        }
                    }   
                }                
            }
            

        }       
        
        System.debug('### FIN TR020_AccountingPiece.applyAccountingEntriesRules');
    }
    
    /**
    * @description Permet d'effectuer un mapping entre les RT des pièces et des écritures
    * @param accPieceRTId Id du RT de la pièce
    * @return Id de l'écriture équivalente
    */
    private static String mappingRecordType(String accPieceRTId) {
        String result;
        if(accPieceRTId == RT_AP_RECEIPT || accPieceRTId == RT_AP_COMPOSITERECEIPT) {
            result = RT_AE_BANKREMITTANCE;
        } else if (accPieceRTId == RT_AP_RECEIPTCANCELLATION || accPieceRTId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION) {
            result = RT_AE_BANKREMITTANCE_CANCELLATION;
        } else if (accPieceRTId == RT_AP_UNPAID) {
            result = RT_AE_UNPAID;
        }
        return result;
    }

    /**
    * @description Méthode pour les règles de validation de l'objet personnalisé Pièce comptable executées après traitements automatiques
    * @param userContext contexte utilisateur
    */
    private static void applyPostUpdateValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_AccountingPiece.applyPostUpdateValidationRules');
        
        List<AccountingPiece__c> allAccountingPieces = (List<AccountingPiece__c>)Trigger.new;  
        List<AccountingPiece__c> newAccPieces = new List<AccountingPiece__c>();  
        Map<Id, AccountingPiece__c> oldAccPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        Map<Id, Order> ordersMap = new Map<Id, Order>();
        Map<Id, AccountingPiece__c> parentsMap = new Map<Id, AccountingPiece__c>();
        Map<Id, AccountingPiece__c> cancelsMap = new Map<Id, AccountingPiece__c>();
        Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>();
        Map<Id, CreditMemo__c> creditMemosMap = new Map<Id, CreditMemo__c>();
        Map<Id, Referencial__c> referencialsMap = new Map<Id, Referencial__c>();
        Set<String> orderIds = new Set<String>();
        Set<String> parentIds = new Set<String>();
        Set<String> invoiceIds = new Set<String>();
        Set<String> creditMemoIds = new Set<String>();
        Set<String> accIds = new Set<String>();
        Set<String> refIds = new Set<String>();
        Set<String> cancelIds = new Set<String>();
        Map<Id, Account> accountsEntityVersionMap = new Map<Id, Account>();
        

        List<String> accountinPieceBankAccountsId = new List<String>();
        Map<String,List<BankAccountVisibility__c>> bankIdTovisibilityMap = new Map<String,List<BankAccountVisibility__c>>();

        // Sélection des pièces comptables qui ne sont pas issues de la reprise d'historique
        for (AccountingPiece__c ap : allAccountingPieces) {
            if(!ap.isLegacy__c){
                newAccPieces.add(ap);
            }
        }

        // Recherche des objets associées 
        for (AccountingPiece__c newAccPiece : newAccPieces) {
            AccountingPiece__c oldAccPiece = oldAccPieces == null ? null : oldAccPieces.get(newAccPiece.id);            

            // Liste des Id des pièces parentes (et récupération des potentiels enfants des parents modifiés)
            parentIds.add(newAccPiece.Id);
            if(newAccPiece.parent__c != null){
                parentIds.add(newAccPiece.parent__c);
            }
            // Liste des Id des pièces annulées
            if(newAccPiece.cancelledPiece__c != null){
                cancelIds.add(newAccPiece.cancelledPiece__c);
            }
            // Liste des Id des commandes
            if(newAccPiece.order__c != null){
                orderIds.add(newAccPiece.order__c);
            }
            // Liste des Id des factures
            if(newAccPiece.invoice__c != null){
                invoiceIds.add(newAccPiece.invoice__c);
            }
            // Liste des Id des avoirs  
            if(newAccPiece.creditMemo__c != null){   
                creditMemoIds.add(newAccPiece.creditMemo__c);    
            }
            // Liste des Id des comptes/entités
            if(newAccPiece.inputEntity__c != null){
                accIds.add(newAccPiece.inputEntity__c);
            }
            if(newAccPiece.orderEntity__c != null){
                accIds.add(newAccPiece.orderEntity__c);
            }
            // Liste des Id des référentiels
            if(newAccPiece.entityBankAccount__c != null){
                refIds.add(newAccPiece.entityBankAccount__c);
            }
            if(newAccPiece.refundReason__c != null){
                refIds.add(newAccPiece.refundReason__c);
            }
            if(newAccPiece.paymentMethod__c != null){
                refIds.add(newAccPiece.paymentMethod__c);
            }
            if(String.isNotBlank(newAccPiece.entityBankAccount__c)) {
                accountinPieceBankAccountsId.add(newAccPiece.entityBankAccount__c);
            }           
        }

        // Récupération des enregistrements d'objets associés
        if(!parentIds.isEmpty()) {
            parentsMap = new Map<Id, AccountingPiece__c>([SELECT Id, inputEntity__c, orderEntity__c, account__c, order__c,
                                                pieceDate__c, dueDate__c, accountingDate__c, entityBankAccount__c, refundReason__c, paymentMethod__c,
                                                externalBank__c, externalReference__c, account__r.RecordTypeId, parent__c, invoice__c, RecordTypeId, accountingEntry__c
                                        FROM AccountingPiece__c 
                                        WHERE Id IN :parentIds]);
        }
        if(!cancelIds.isEmpty()) {
            cancelsMap = new Map<Id, AccountingPiece__c>([SELECT Id, amount__c, cancelledAmount__c, entityBankAccount__c FROM AccountingPiece__c 
                                                            WHERE Id IN :cancelIds]);
        }
        if(!orderIds.isEmpty()) {
            ordersMap = new Map<Id, Order>([SELECT Id, AccountId, BillToContactId, billingName__c, BillingStreet, BillingPostalCode, BillingCity, Account.Name, BillingState, BillingCountry,
                                                salesEntity__c, salesEntity__r.rue__c, salesEntity__r.codePostal__c, salesEntity__r.ville__c, salesEntity__r.departement__c, chantier__c,
                                                salesEntity__r.pays__c, salesEntity__r.Name, salesEntity__r.Ownership, salesEntity__r.complementAdresse__c, ShipToContactId, shippingName__c,
                                                ShippingStreet, ShippingPostalCode, ShippingCity, ShippingState, ShippingCountry, serviceEntity__c, serviceEntity__r.rue__c, serviceEntity__r.codePostal__c, 
                                                serviceEntity__r.ville__c, serviceEntity__r.departement__c, serviceEntity__r.pays__c, serviceEntity__r.Name, serviceEntity__r.complementAdresse__c,
                                                salesEntity__r.email__c, serviceEntity__r.email__c, salesEntity__r.Phone, serviceEntity__r.Phone, billingAdditionalAddress__c, shippingAdditionalAddress__c,
                                                ActivatedDate, EffectiveDate, Type
                                                   FROM Order 
                                                   WHERE id IN :orderIds]);
            System.debug('## ordersMap: '+ordersMap ); 
        }
        if(!invoiceIds.isEmpty()) {
            invoicesMap = new Map<Id, Invoice__c>([SELECT Id, customerOrder__c, invoiceReference__c, invoiceDate__c
                                                    FROM Invoice__c 
                                                    WHERE Id IN :invoiceIds]);
        }   
        if(!creditMemoIds.isEmpty()) {
            creditMemosMap = new Map<Id, CreditMemo__c>([SELECT Id, customerOrder__c, creditMemoReference__c, creditMemoDate__c
                                                    FROM CreditMemo__c 
                                                    WHERE Id IN :creditMemoIds]);
        }  
        if(!refIds.isEmpty()) {
            referencialsMap = new Map<Id, Referencial__c>([SELECT Id, startDate__c, endDate__c, requiredExternalBankAccount__c, paymentType__c, unitaryEntry__c, bankRemittance__c
                                                            FROM Referencial__c 
                                                            WHERE Id IN :refIds]);
        }
        if(!accIds.isEmpty()) {
            accountsEntityVersionMap = new Map<Id, Account>([SELECT Id, name,
                                                (SELECT id, name, startDate__c, endDate__c FROM EntitiesVersion__r),
                                                (SELECT id, name, startDate__c, endDate__c FROM BankAccountVisibilities__r)
                                                FROM Account WHERE id IN :accIds]);
        }
        
        // Récupération des Visibilité compte bancaire       
        if(!accountinPieceBankAccountsId.isEmpty()) {
            for(BankAccountVisibility__c bankVisibility : [SELECT Id, entity__c,bankAccount__c, startDate__c, endDate__c 
                                                            FROM BankAccountVisibility__c 
                                                            WHERE bankAccount__c IN :accountinPieceBankAccountsId]){
                System.debug('bankVisibility : '+ bankVisibility);
                List<BankAccountVisibility__c> mapList = new List<BankAccountVisibility__c>();
                if (bankIdTovisibilityMap.get(bankVisibility.bankAccount__c) != null) {
                    mapList = bankIdTovisibilityMap.get(bankVisibility.bankAccount__c);
                    System.debug('bankIdTovisibilityMap.get(bankVisibility.bankAccount__c) : '+ bankIdTovisibilityMap.get(bankVisibility.bankAccount__c));
                }
                mapList.add(bankVisibility);
                bankIdTovisibilityMap.put(bankVisibility.bankAccount__c,mapList);
            }
        }


        for(AccountingPiece__c newAccPiece : newAccPieces){
            // VR : Le compte est obligatoire
            if(newAccPiece.account__c == null){
                System.debug('## Account required: ' + newAccPiece.Id);
                newAccPiece.addError('account__c', Label.accPieces_msg_accountRequired);
            }  

            // VR : Le compte doit être identique à celui de la pièce parente. (sauf organisme de financement et encaissement lié a des encaissement composite)
            if(newAccPiece.parent__c != null && parentsMap != null && parentsMap.get(newAccPiece.parent__c) != null 
                && parentsMap.get(newAccPiece.parent__c).account__c != null
                && parentsMap.get(newAccPiece.parent__c).RecordTypeId != RT_AP_COMPOSITERECEIPT
                && (newAccPiece.account__c != parentsMap.get(newAccPiece.parent__c).account__c ||
                parentsMap.get(newAccPiece.parent__c).account__r.RecordTypeId == RT_ACC_FUNDINGORG)
            ){
                System.debug('## Account diff with parent: ' + newAccPiece.account__c);
                newAccPiece.addError('account__c', Label.accPieces_msg_accountParent);
            }  

            // VR : L'entité de saisie est obligatoire
            if(newAccPiece.inputEntity__c == null){
                System.debug('## Input Entity required: ' + newAccPiece.Id);
                newAccPiece.addError('inputEntity__c', Label.accPieces_msg_inputEntityRequired);
            }  

            // VR : L'entité de saisie doit être active à la date de la pièce (Vérifier la version de l'entité)            
            boolean found = false;
            if (newAccPiece.inputEntity__c != null) {
                for (EntityVersion__c version : accountsEntityVersionMap.get(newAccPiece.inputEntity__c).EntitiesVersion__r){
                    if (newAccPiece.pieceDate__c >= version.startDate__c && 
                        (version.endDate__c == null || newAccPiece.pieceDate__c <= version.endDate__c)) {
                        found = true;
                        break;                    
                    }
                }
                if (!found) {
                    System.debug('## Input Entity active: ' + newAccPiece.inputEntity__c);
                    newAccPiece.addError('inputEntity__c', Label.accPieces_msg_inputEntityActive);
                }                
            }
            

            // VR : L'entité de saisie doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).inputEntity__c != null && 
            newAccPiece.inputEntity__c != parentsMap.get(newAccPiece.parent__c).inputEntity__c){
                System.debug('## Input Entity diff with parent: ' + newAccPiece.inputEntity__c);
                newAccPiece.addError('inputEntity__c', Label.accPieces_msg_inputEntityParent);
            }  

            // VR : La commande est obligatoire
            if(newAccPiece.order__c == null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT){
                System.debug('## Order required: ' + newAccPiece.Id);
                newAccPiece.addError('order__c', Label.accPieces_msg_orderEntityRequired);
            }

            // VR : La commande doit être active à la date de la pièce (Commande NON SAV avec ActivatedDate)
            if(newAccPiece.order__c != null && ordersMap != null 
                && ordersMap.get(newAccPiece.order__c) != null && ordersMap.get(newAccPiece.order__c).Type != Constants.ORDER_TYPE_COMMANDE_SAV && ordersMap.get(newAccPiece.order__c).ActivatedDate != null 
                && (newAccPiece.pieceDate__c < ordersMap.get(newAccPiece.order__c).ActivatedDate.date() 
                    || ordersMap.get(newAccPiece.order__c).ActivatedDate == null)
                )
            {
                System.debug('## Order Activate Date: ' + newAccPiece.order__c);
                newAccPiece.addError('order__c', Label.accPieces_msg_orderEntityActive);
            }  

            // VR : La commande doit être active à la date de la pièce (Commande SAV avec Effectivedate)
            if(newAccPiece.order__c != null && ordersMap != null 
                && ordersMap.get(newAccPiece.order__c) != null && ordersMap.get(newAccPiece.order__c).Type == Constants.ORDER_TYPE_COMMANDE_SAV && ordersMap.get(newAccPiece.order__c).EffectiveDate != null 
                && (newAccPiece.pieceDate__c < ordersMap.get(newAccPiece.order__c).EffectiveDate || ordersMap.get(newAccPiece.order__c).EffectiveDate == null)
                )
            {
                System.debug('## Order Effective Date: ' + newAccPiece.order__c);
                newAccPiece.addError('order__c', Label.accPieces_msg_orderEntityActive);
            }  

            // VR : La commande doit être active à la date de la pièce
            if(newAccPiece.order__c != null && ordersMap != null 
                && ordersMap.get(newAccPiece.order__c) != null && ordersMap.get(newAccPiece.order__c).EffectiveDate != null 
                && (newAccPiece.pieceDate__c < ordersMap.get(newAccPiece.order__c).EffectiveDate 
                    || ordersMap.get(newAccPiece.order__c).EffectiveDate == null)
                )
            {
                System.debug('## Order Effective Date: ' + newAccPiece.order__c);
                newAccPiece.addError('order__c', Label.accPieces_msg_orderEntityActive);
            }  

            // VR : L'entité de commande doit être identique à celle de la pièce parente.   
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).order__c != null && 
            newAccPiece.order__c != parentsMap.get(newAccPiece.parent__c).order__c){
                System.debug('## Order diff with parent: ' + newAccPiece.order__c);
                newAccPiece.addError('order__c', Label.accPieces_msg_orderEntityParent);
            }  

            // VR : L'entité de commande est obligatoire
            /*if(newAccPiece.orderEntity__c == null && newAccPiece.RecordTypeId != RT_AP_COMPOSITERECEIPT){
                System.debug('## Order Entity required: ' + newAccPiece.Id);
                newAccPiece.addError('orderEntity__c', Label.accPieces_msg_orderEntityRequired);
            }*/  

            // VR : L'entité de saisie doit être active à la date de la pièce (Vérifier la version de l'entité)
            if (newAccPiece.orderEntity__c != null) {
                found = false;
                for (EntityVersion__c version : accountsEntityVersionMap.get(newAccPiece.orderEntity__c).EntitiesVersion__r){
                    if (newAccPiece.pieceDate__c >= version.startDate__c && 
                        (version.endDate__c == null || newAccPiece.pieceDate__c <= version.endDate__c)) {
                        found = true;
                        break;                    
                    }
                }
                if (!found) {
                    System.debug('## Order Entity active: ' + newAccPiece.orderEntity__c);
                    newAccPiece.addError('orderEntity__c', Label.accPieces_msg_orderEntityActive);
                }
            }            

            // VR : L'entité de commande doit être identique à celle de la pièce parente.   
            if(newAccPiece.parent__c != null && parentsMap != null && parentsMap.get(newAccPiece.parent__c) != null &&
                parentsMap.get(newAccPiece.parent__c).orderEntity__c != null && 
                newAccPiece.orderEntity__c != parentsMap.get(newAccPiece.parent__c).orderEntity__c)
            {
                System.debug('## Order Entity diff with parent: ' + newAccPiece.orderEntity__c);
                newAccPiece.addError('orderEntity__c', Label.accPieces_msg_orderEntityParent);
            }  

            // VR : La facture est obligatoire si aucune ligne enfant et Status = Brouillon
            /*if(newAccPiece.invoice__c == null && parentsMap.get(newAccPiece.Id) == null && newAccPiece.status__c != Constants.ACCOUNTINGPIECE_STATUS_DRAFT){
                System.debug('## Invoice required: ' + newAccPiece.Id);
                newAccPiece.addError(Label.accPieces_msg_invoiceRequired);
            } */ 

            // VR : Interdire une association à une facture non comptabilisée (si facture renseignée)
            if(newAccPiece.invoice__c != null && invoicesMap != null 
                && invoicesMap.get(newAccPiece.invoice__c) != null && invoicesMap.get(newAccPiece.invoice__c).invoiceDate__c == null) 
            {
                System.debug('## Invoice accounting: ' + newAccPiece.invoice__c);
                newAccPiece.addError('invoice__c', 'La facture doit être comptabilisée!');
            }  

            // VR : Interdire une association à un avoir non comptabilisé (si avoir renseigné)
            if(newAccPiece.creditMemo__c != null && creditMemosMap != null 
                && creditMemosMap.get(newAccPiece.creditMemo__c) != null && creditMemosMap.get(newAccPiece.creditMemo__c).creditMemoDate__c == null) 
            {
                System.debug('## CreditMemo accounting: ' + newAccPiece.creditMemo__c);
                newAccPiece.addError('creditMemo__c', 'L\'avoir doit être comptabilisé!');
            } 

            // VR : La date de la pièce est obligatoire
            if(newAccPiece.pieceDate__c == null){
                System.debug('## Piece Date required: ' + newAccPiece.Id);
                newAccPiece.addError('pieceDate__c', Label.accPieces_msg_pieceDateRequired);
            }  

            // VR : La date de la pièce doit être inférieure ou égale à aujourd'hui
            if(newAccPiece.pieceDate__c > Date.today()){
                System.debug('## Incorrect Piece Date: ' + newAccPiece.pieceDate__c);
                newAccPiece.addError('pieceDate__c', Label.accPieces_msg_pieceDatePast);
            }  

            // VR : La date de la pièce doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                parentsMap.get(newAccPiece.parent__c).pieceDate__c != null && 
                newAccPiece.pieceDate__c != parentsMap.get(newAccPiece.parent__c).pieceDate__c)
            {
                System.debug('## Piece Date diff with parent: ' + newAccPiece.pieceDate__c);
                newAccPiece.addError('pieceDate__c', Label.accPieces_msg_pieceDateParent);
            }  

            // VR : Interdire une date de pièce antérieure à la date comptable de la facture (si facture renseignée)
            if(newAccPiece.invoice__c != null && invoicesMap != null &&
                invoicesMap.get(newAccPiece.invoice__c).invoiceDate__c != null && 
                newAccPiece.pieceDate__c < invoicesMap.get(newAccPiece.invoice__c).invoiceDate__c)
            {
                System.debug('## Piece Date inf with invoice: ' + newAccPiece.pieceDate__c);
                newAccPiece.addError('pieceDate__c', 'La date de la pièce doit être supérieure à la date de la facture!');
            }  

            // VR : Interdire une date de pièce antérieure à la date comptable de la facture (si facture renseignée)
            if(newAccPiece.creditMemo__c != null && creditMemosMap != null &&
                creditMemosMap.get(newAccPiece.creditMemo__c).creditMemoDate__c != null && 
                newAccPiece.pieceDate__c < creditMemosMap.get(newAccPiece.creditMemo__c).creditMemoDate__c)
            {
                System.debug('## Piece Date inf with credit memo: ' + newAccPiece.pieceDate__c);
                newAccPiece.addError('pieceDate__c', 'La date de la pièce doit être supérieure à la date de l\'avoir!');
            }  

            // VR : La date d'échéance est obligatoire pour RT = Receipt
            if(newAccPiece.dueDate__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT)){
                System.debug('## Due Date required: ' + newAccPiece.Id);
                newAccPiece.addError('dueDate__c', Label.accPieces_msg_dueDateRequired);
            }  

            // VR : La date d'échéance doit être supérieure ou égale à la date de la pièce.
            if(newAccPiece.dueDate__c < newAccPiece.pieceDate__c){
                System.debug('## Incorrect Due Date: ' + newAccPiece.dueDate__c);
                newAccPiece.addError('dueDate__c', Label.accPieces_msg_dueDatePast);
            }  

            // VR : La date d'échéance doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).dueDate__c != null && 
            newAccPiece.dueDate__c != parentsMap.get(newAccPiece.parent__c).dueDate__c){
                System.debug('## Due Date diff with parent: ' + newAccPiece.dueDate__c);
                newAccPiece.addError('dueDate__c', Label.accPieces_msg_dueDateParent);
            }  

            // VR : La date comptable doit être comprise entre la date de la pièce et aujourd'hui.
            if(newAccPiece.accountingDate__c < newAccPiece.pieceDate__c && newAccPiece.accountingDate__c < Date.today()){
                System.debug('## Incorrect Accounting Date: ' + newAccPiece.accountingDate__c);
                newAccPiece.addError('accountingDate__c', Label.accPieces_msg_accountingDateBoudaries);
            }  

            // VR : La date comptable doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).accountingDate__c != null && 
            newAccPiece.accountingDate__c != parentsMap.get(newAccPiece.parent__c).accountingDate__c){
                System.debug('## Accounting Date diff with parent: ' + newAccPiece.accountingDate__c);
                newAccPiece.addError('accountingDate__c',Label.accPieces_msg_accountingDateParent);
            }  
            
            // VR : Le compte bancaire est obligatoire pour un RT = Receipt ou RT = ReceiptCancellation ou RT = UndeliveredReceiptCancellation ou RT = Unpaid ou RT = CompositeReceipt
            if(newAccPiece.entityBankAccount__c == null && newAccPiece.accountingDate__c != null
                && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION 
                    || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION || newAccPiece.RecordTypeId == RT_AP_UNPAID || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT)
                )
            {
                System.debug('## Bank Account required: ' + newAccPiece.Id);
                newAccPiece.addError('entityBankAccount__c',Label.accPieces_msg_entityBankAccountRequired);
            }  
            // VR : Le compte bancaire doit être identique entre une piece comptable et la pièce annulée !
            if(newAccPiece.entityBankAccount__c != null && newAccPiece.cancelledPiece__c != null && cancelsMap.get(newAccPiece.cancelledPiece__c) != null && cancelsMap.get(newAccPiece.cancelledPiece__c).entityBankAccount__c != null
                && (newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION  || newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION || newAccPiece.RecordTypeId == RT_AP_UNPAID)  
                && newAccPiece.entityBankAccount__c != cancelsMap.get(newAccPiece.cancelledPiece__c).entityBankAccount__c)
            { 
                System.debug('## Bank Account incorrect: ' + newAccPiece.entityBankAccount__c);
                newAccPiece.addError('entityBankAccount__c',Label.accPieces_msg_entityBankAccountCancelledPiece);
            }

            // VR : Le compte bancaire référencé doit être actif à la date de la pièce
            if(newAccPiece.entityBankAccount__c != null && referencialsMap.get(newAccPiece.entityBankAccount__c) != null 
                && !isValidDate(newAccPiece.pieceDate__c, referencialsMap.get(newAccPiece.entityBankAccount__c).startDate__c,
                                referencialsMap.get(newAccPiece.entityBankAccount__c).endDate__c)
            )
            {
                System.debug('## Bank Account active: ' + newAccPiece.entityBankAccount__c);
                newAccPiece.addError('entityBankAccount__c',Label.accPieces_msg_entityBankAccountActive);
            }  

            // VR : Le compte bancaire doit être identique au parent si celui-ci est renseignée
            if(newAccPiece.entityBankAccount__c != null &&  newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
                parentsMap.get(newAccPiece.parent__c).entityBankAccount__c != null && 
                newAccPiece.entityBankAccount__c != parentsMap.get(newAccPiece.parent__c).entityBankAccount__c)
            {
                System.debug('## Bank Account diff with parent: ' + newAccPiece.entityBankAccount__c);
                newAccPiece.addError('entityBankAccount__c',Label.accPieces_msg_entityBankAccountParent);
            }  

            // VR : Le motif de remboursement est obligatoire pour un RT = Refund ou RT = CheckRequest
            if(newAccPiece.refundReason__c == null && 
                (newAccPiece.RecordTypeId == RT_AP_REFUND || newAccPiece.RecordTypeId == RT_AP_CHECKREQUEST)){
                System.debug('## Refund Reason required: ' + newAccPiece.Id);
                newAccPiece.addError('refundReason__c',Label.accPieces_msg_refundReasonRequired);
            }  

            // VR : Le motif de remboursement référencé doit être actif à la date de la pièce.  
            if(referencialsMap.get(newAccPiece.refundReason__c) != null 
                && !isValidDate(newAccPiece.pieceDate__c, referencialsMap.get(newAccPiece.refundReason__c).startDate__c,
                                referencialsMap.get(newAccPiece.refundReason__c).endDate__c)
            )
            {
                System.debug('## Refund Reason active: ' + newAccPiece.refundReason__c);
                newAccPiece.addError('refundReason__c',Label.accPieces_msg_refundReasonActive);
            }  

            // VR : Le motif de remboursement doit être identique au parent si celui-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).refundReason__c != null && 
            newAccPiece.refundReason__c != parentsMap.get(newAccPiece.parent__c).refundReason__c){
                System.debug('## Refund Reason diff with parent: ' + newAccPiece.refundReason__c);
                newAccPiece.addError('refundReason__c', Label.accPieces_msg_refundReasonParent);
            }  

            // VR : Le mode de règlement est obligatoire pour un RT = Receipt, RT = Refund ou RT = CheckRequest
            if(newAccPiece.paymentMethod__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT 
                || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT
                || newAccPiece.RecordTypeId == RT_AP_REFUND || newAccPiece.RecordTypeId == RT_AP_CHECKREQUEST)
            ){
                System.debug('## Payment Method required: ' + newAccPiece.Id);
                newAccPiece.addError('paymentMethod__c',Label.accPieces_msg_paymentMethodRequired);
            }  

            // VR : Le mode de règlement référencé doit être actif à la date de la pièce.
            if(referencialsMap.get(newAccPiece.paymentMethod__c) != null 
                && !isValidDate(newAccPiece.pieceDate__c, referencialsMap.get(newAccPiece.paymentMethod__c).startDate__c,
                                referencialsMap.get(newAccPiece.paymentMethod__c).endDate__c)
            )
            {
                System.debug('## Payment Method active: ' + newAccPiece.Id);
                newAccPiece.addError('paymentMethod__c',Label.accPieces_msg_paymentMethodActive);
            }  

            // VR : Le mode de règlement doit être identique au parent si celui-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).paymentMethod__c != null && 
            newAccPiece.paymentMethod__c != parentsMap.get(newAccPiece.parent__c).paymentMethod__c){
                System.debug('## Payment Method diff with parent: ' + newAccPiece.paymentMethod__c);
                newAccPiece.addError('paymentMethod__c',Label.accPieces_msg_paymentMethodParent);
            }  

            // VR : La banque externe (compte) est obligatoire pour un RT = Receipt ssi le champ "Compte bancaire requis" du mode de financement est true
            if(newAccPiece.externalBank__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT)
                && referencialsMap !=null && referencialsMap.get(newAccPiece.paymentMethod__c) != null
                && referencialsMap.get(newAccPiece.paymentMethod__c).requiredExternalBankAccount__c)
            {
                System.debug('## External Bank required: ' + newAccPiece.Id);
                newAccPiece.addError('externalBank__c',Label.accPieces_msg_externalBankRequired);
            }   

            // VR : La banque externe (compte) doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).externalBank__c != null && 
            newAccPiece.externalBank__c != parentsMap.get(newAccPiece.parent__c).externalBank__c){
                System.debug('## External Bank diff with parent: ' + newAccPiece.externalBank__c);
                newAccPiece.addError('externalBank__c',Label.accPieces_msg_externalBankParent);
            }  
            
            // VR : La référence externe (compte) est obligatoire pour un RT = Receipt ssi le champ "Compte bancaire requis" du mode de financement est true
            if(newAccPiece.externalReference__c == null && (newAccPiece.RecordTypeId == RT_AP_RECEIPT || newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT)
                && referencialsMap !=null && referencialsMap.get(newAccPiece.paymentMethod__c) != null
                && referencialsMap.get(newAccPiece.paymentMethod__c).requiredExternalBankAccount__c)
            {
                System.debug('## External Reference required: ' + newAccPiece.Id);
                newAccPiece.addError('externalReference__c',Label.accPieces_msg_externalReferenceRequired);
            }  

            // VR : La référence externe (compte) doit être identique au parent si celle-ci est renseignée
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null &&
            parentsMap.get(newAccPiece.parent__c).externalReference__c != null && 
            newAccPiece.externalReference__c != parentsMap.get(newAccPiece.parent__c).externalReference__c){
                System.debug('## External Reference diff with parent: ' + newAccPiece.externalReference__c);
                newAccPiece.addError('externalReference__c',Label.accPieces_msg_externalReferenceParent);
            }  

            // VR : Impossible d'être une pièce parente et enfant en même temps
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null && parentsMap.get(newAccPiece.parent__c).parent__c != null){
                System.debug('## Parent cannot be a child: ' + newAccPiece.parent__c);
                newAccPiece.addError('parent__c',Label.accPieces_msg_cannotBeParentAndChild);
            }

            /*
            // VR : Une pièce de type encaissement avec une facture ne peut avoir de sous-lignes!
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null 
                && parentsMap.get(newAccPiece.parent__c).invoice__c != null
                && parentsMap.get(newAccPiece.parent__c).RecordTypeId == RT_AP_RECEIPT
            )
            {
                System.debug('## Parent Receipt with Invoice no childs: ' + newAccPiece.Id);
                newAccPiece.addError(Label.accPieces_msg_receiptInvoiceNoChild);
            }
            */

            // VR : La pièce enfant doit être de type Receipt et la pièce parent doit être de type CompositeReceipt
            if(newAccPiece.parent__c != null && parentsMap.get(newAccPiece.parent__c) != null 
                && (newAccPiece.RecordTypeId != RT_AP_RECEIPT || parentsMap.get(newAccPiece.parent__c).RecordTypeId != RT_AP_COMPOSITERECEIPT)
            ) {
                System.debug('## Parent Composite Receipt invalid: ' + newAccPiece.Id);
                newAccPiece.addError(Label.accEntries_msg_parentReceiptCompositeError);
            }

            // VR : le montant de l'annulation ajouté au montant déjà annulé de la pièce annulée ne doit pas dépassé le montant initial de la pièce annulée
            if(newAccPiece.cancelledPiece__c != null && (newAccPiece.RecordTypeId == RT_AP_RECEIPTCANCELLATION 
                || newAccPiece.RecordTypeId == RT_AP_UNPAID 
                || newAccPiece.RecordTypeId == RT_AP_UNDELIVEREDRECEIPTCANCELLATION)
                && cancelsMap != null && cancelsMap.get(newAccPiece.cancelledPiece__c) != null
            ){
                AccountingPiece__c canPiece = cancelsMap.get(newAccPiece.cancelledPiece__c);
                Decimal parentPieceAmount = (canPiece.amount__c == null) ? 0 : canPiece.amount__c;
                Decimal parentPieceCanAmount = (canPiece.cancelledAmount__c == null) ? 0 : canPiece.cancelledAmount__c;
                Decimal amount = (newAccPiece.amount__c == null) ? 0 : newAccPiece.amount__c;
                Decimal canAmount = parentPieceAmount + parentPieceCanAmount + amount;
                if(canAmount < 0) {
                    System.debug('## Cancel piece Amount invalid: ' + newAccPiece.amount__c);
                    newAccPiece.addError('amount__c', Label.accPieces_msg_cancePieceAmount);
                } 
            } 

            // VR : Trop perçu interdit pour les enfants
            if(newAccPiece.parent__c != null && newAccPiece.overpaymentAmount__c != 0 && newAccPiece.overpaymentAmount__c != null){
                System.debug('## Overpayment Amount invalid: ' + newAccPiece.parent__c);
                newAccPiece.addError('overpaymentAmount__c',Label.accPieces_msg_overpaymentChildAmountNotAllowed);
            }

            //Retour #1227 - VR visibilité compte bancaire déplacée en after update pour prendre en compte l'entité de saisie renseignée auto dans applyUpdateRule
            // VR : Le compte bancaire séléctionné est non visible par l'entité
            if(!bankIdTovisibilityMap.isEmpty() && String.isNotBlank(newAccPiece.entityBankAccount__c) && newAccPiece.inputEntity__c != null) {
                List<BankAccountVisibility__c> bankVisibilityList = bankIdTovisibilityMap.get(newAccPiece.entityBankAccount__c);
                
                Integer numberOfVisibility = 0;
                for(BankAccountVisibility__c BV : bankVisibilityList){
                    if(newAccPiece.inputEntity__c == BV.entity__c ){
                        numberOfVisibility++;
                        //bypass la règle de validation de contrôle de la date de fin de visibilité du compte bancaire pour utilisateurs nommés                   
                        if (UserContext.utilisateurPeutBypasserValidation('BypassBankVisibility_EndDate')) 
                        {
                            if((newAccPiece.accountingDate__c == null || newAccPiece.accountingDate__c != null 
                            && (BV.startDate__c != null &&  newAccPiece.accountingDate__c < BV.startDate__c))
                            && newAccPiece.pieceDate__c != null && (BV.startDate__c != null &&  newAccPiece.pieceDate__c < BV.startDate__c))
                            {
                                newAccPiece.addError(Label.accPieces_msg_noBankAccountVisibilityForTHisEntity);                         
                            }
                        }else if ((newAccPiece.accountingDate__c == null || newAccPiece.accountingDate__c != null 
                            && (BV.endDate__c != null && newAccPiece.accountingDate__c > BV.endDate__c || BV.startDate__c != null &&  newAccPiece.accountingDate__c < BV.startDate__c))
                            && newAccPiece.pieceDate__c != null && (BV.endDate__c != null && newAccPiece.pieceDate__c > BV.endDate__c || BV.startDate__c != null &&  newAccPiece.pieceDate__c < BV.startDate__c))
                        {
                            newAccPiece.addError(Label.accPieces_msg_noBankAccountVisibilityForTHisEntity);                            
                        }
                    }
                }
                if(numberOfVisibility == 0){
                    newAccPiece.addError(Label.accPieces_msg_noBankAccountVisibilityForTHisEntity);
                }
            }
        }
        
        System.debug('### FIN TR020_AccountingPiece.applyPostUpdateValidationRules');
    }
    
    /**
    * @description Permet de vérifier si une date est comprise dans la plage de dates souhaitées
    * @param dateToCheck Date à vérifier
    * @param startDate Date de début de la plage pour vérification
    * @param endDate Date de fin de la plage pour vérification
    * @return True si la date est dans la plage de vérification, sinon false
    */
    private static Boolean isValidDate(Date dateToCheck, Date startDate, Date endDate) {
        Boolean result = false;
        if(endDate != null && dateToCheck >= startDate && dateToCheck < endDate) {
            result = true;
        } else if (endDate == null && dateToCheck >= startDate) {
            result = true;
        }
        return result;
    }
}