//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_AccountingPiece
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 06/03/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_AccountingPiece {
    private static final Id RT_AP_COMPOSITERECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);
    private static final Id RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final Id RT_AP_CHECKREQUEST = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_CHECKREQUEST_RT);
    private static final Id RT_AP_REFUND = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_REFUND_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PRO = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PRO_RT);

    /**
    * @description Processus pour mettre à jour les écritures comptables liés à des pièces avec la sommes de tous les pièces
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateEntryAmountbyAccPiece(UserContext userContext) {
        System.debug('### DEBUT TR022_AccountingPiece.updateEntryAmountbyAccPiece');
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new; 
        Map<Id, AccountingPiece__c> oldAccountingPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        List<String> accEntriesIds = new List<String>();
        Set<AccountingEntry__c> newAccEntryToUp = new Set<AccountingEntry__c>();
        List<AccountingEntry__c> newAccEntryListToUp = new List<AccountingEntry__c>();
      
        // A - Initialisation des données intermédiaires 
        for (AccountingPiece__c newAccountingPiece : newAccountingPieces) {
            AccountingPiece__c oldAccountingPiece = oldAccountingPieces == null ? null : oldAccountingPieces.get(newAccountingPiece.id);  

            // Liste des Id des écritures
            if(Trigger.isAfter){
                if(newAccountingPiece.accountingEntry__c != null 
                    && (Trigger.isInsert || (Trigger.isUpdate && (newAccountingPiece.accountingEntry__c != oldAccountingPiece.accountingEntry__c 
                        || newAccountingPiece.amount__c != oldAccountingPiece.amount__c || newAccountingPiece.accountingDate__c != oldAccountingPiece.accountingDate__c))))
                {
                    if(Trigger.isUpdate && oldAccountingPiece != null && oldAccountingPiece.accountingEntry__c != null 
                        && newAccountingPiece.accountingEntry__c != oldAccountingPiece.accountingEntry__c){
                        accEntriesIds.add(oldAccountingPiece.accountingEntry__c);
                    }
                    accEntriesIds.add(newAccountingPiece.accountingEntry__c);
                }
                else if(Trigger.isUpdate && newAccountingPiece.accountingEntry__c == null 
                    && oldAccountingPiece != null && oldAccountingPiece.accountingEntry__c != null){
                    accEntriesIds.add(oldAccountingPiece.accountingEntry__c);
                }
            }
        }
        System.debug('## accEntriesIds: '+accEntriesIds);

        // Récupération des pièces pour chaque écriture (exclure les pièces composites)
        List<accountingEntry__c> accEntList = new List<accountingEntry__c>();
        if(!accEntriesIds.isEmpty()) {
            accEntList = [SELECT id, name, amount__c, customerOrderAmount__c, afterSalesServiceAmount__c,
                (select id, distribution__c, amount__c,RecordTypeId 
                        FROM AccountingPieces__r 
                        WHERE status__c != 'Annulé')
            FROM AccountingEntry__c
            WHERE Id IN :accEntriesIds];
        }

        if(!accEntList.isEmpty()){
            for (AccountingEntry__c accEntry : accEntList) {
                System.debug('## Entry Id: '+accEntry.Id); 
    
                if(accEntry.AccountingPieces__r.isEmpty() != null) {
                    System.debug('## Change amount for AE: '+accEntry.Id); 
                    Decimal totalAmount = 0;
                    Decimal customerOrderAmount = 0;
                    Decimal afterSalesServiceAmount = 0;
                    for(AccountingPiece__c ap : accEntry.AccountingPieces__r){
                        if (ap.Distribution__c != null) {
                            System.debug('prix pièce : ' + ap.amount__c);
                            System.debug('Distribution__c : ' + ap.Distribution__c);
                            System.debug('Distribution__c : ' + ap.Id);                        
                            totalAmount = totalAmount + ap.amount__c;                       
                            if(ap.Distribution__c == 'Commande' ){
                                customerOrderAmount = customerOrderAmount + ap.amount__c;
                            } else if ( ap.Distribution__c == 'SAV' ){
                                afterSalesServiceAmount = afterSalesServiceAmount + ap.amount__c; 
                            }                            
                        }
                                          
                    }
                    System.debug('## New amount: '+totalAmount);
                    if (totalAmount != 0) {
                        newAccEntryToUp.add(new AccountingEntry__c(
                        Id = accEntry.Id, 
                        amount__c = totalAmount.setScale(2),
                        customerOrderAmount__c = customerOrderAmount.setScale(2),
                        afterSalesServiceAmount__c = afterSalesServiceAmount.setScale(2),
                        bypassValidation__c = true //Activation bypass VR
                    ));
                    }
                    
                }
            }
        }
        System.debug('## newAccEntryToUp: '+newAccEntryToUp); 
        // Transformation SET to LIST
        if(!newAccEntryToUp.isEmpty()) {        
            newAccEntryListToUp.addAll(newAccEntryToUp);
        }
        
        if(!newAccEntryListToUp.isEmpty()) {
            update newAccEntryListToUp;
        }
                    
        // C - Mise à jourde des entrées pour enlever flag de bypass
        for (AccountingEntry__c accEnt : newAccEntryListToUp) {
            accEnt.bypassValidation__c = false;
        }
        if(!newAccEntryListToUp.isEmpty()) {       
            update newAccEntryListToUp;
        }

        System.debug('### FIN TR022_AccountingPiece.updateEntryAmountbyAccPiece');
    }

    /**
    * @description Processus pour mettre à jour les champs quantité et montant sur les parents et les pièces annulée
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateParentAndCancelFieldsRollup(UserContext userContext) {
        System.debug('### DEBUT TR022_AccountingPiece.updateParentAndCancelFieldsRollup');
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new;
        List<AccountingPiece__c> oldAccountingPieces = (List<AccountingPiece__c>)Trigger.old;
        Map<Id, AccountingPiece__c> oldAccountingPiecesMap = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        Set<Id> parentIds = new Set<Id>();
        Set<Id> cancelIds = new Set<Id>();
        List<AccountingPiece__c> parentToUpdate = new List<AccountingPiece__c>();
        List<AccountingPiece__c> cancelToUpdate = new List<AccountingPiece__c>();
        System.debug('##oldAccountingPieces : '+oldAccountingPieces);
        System.debug('##oldAccountingPiecesMap : '+oldAccountingPiecesMap);

        //Déclenchement à la création / supression / Dé-suppression / update
        if(Trigger.isInsert || Trigger.isUpdate){
            for(AccountingPiece__c accPiece : newAccountingPieces){
                AccountingPiece__c oldAccPiece = oldAccountingPiecesMap == null ? null : oldAccountingPiecesMap.get(accPiece.id);
                //#1269 - modifications Optimisation et amélioration des performances
                //restreindre le Déclenchement à l'update uniquement dans 2 cas
                //  -montant modifié 
                //  -pièce parent renseigné et statut modifié d'un autre statut à annulé ou depuis annulé à un autre statut
                if(Trigger.isInsert || Trigger.isUpdate && (accPiece.amount__c != oldAccPiece.amount__c || 
                (accPiece.status__c != oldAccPiece.status__c && String.isNotBlank(accPiece.parent__c) &&
                (accPiece.status__c == Constants.ACCOUNTINGPIECE_STATUS_CANCELED || oldAccPiece.status__c == Constants.ACCOUNTINGPIECE_STATUS_CANCELED)))){
                    // Récupération ID Parent si record create/update
                    if(String.isNotBlank(accPiece.parent__c)) {
                        parentIds.add(accPiece.parent__c);
                    }
                    // Récupération ID Cancel si record create/update
                    if(String.isNotBlank(accPiece.cancelledPiece__c)) {
                        cancelIds.add(accPiece.cancelledPiece__c);
                    }
                }
            }
        }
        if(Trigger.isDelete){
            for(AccountingPiece__c accPiece : oldAccountingPieces){
                // Récupération ID Parent si record delete
                System.debug('##accPiece.parent__c: '+accPiece.parent__c);
                if(String.isNotBlank(accPiece.parent__c)) {
                    parentIds.add(accPiece.parent__c);
                }
                // Récupération ID Cancel si record delete
                if(String.isNotBlank(accPiece.cancelledPiece__c)) {
                    cancelIds.add(accPiece.cancelledPiece__c);
                }
            }
        }
        System.debug('## parentIds: '+parentIds); 
        System.debug('## cancelIds: '+cancelIds); 
        
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete){
            // Mise à jour des champs du parent
            if(!parentIds.isEmpty()){
                for(AggregateResult result : [SELECT parent__c, COUNT(Id) nb, SUM(amount__c) amount FROM AccountingPiece__c 
                                                WHERE status__c != :Constants.ACCOUNTINGPIECE_STATUS_CANCELED AND parent__c IN :parentIds GROUP BY parent__c]){
                    System.debug('## Parent Result: '+result); 
                    AccountingPiece__c parentRecord = new AccountingPiece__c(
                        Id = (String)result.get('parent__c'),
                        lineAmount__c = (Decimal)result.get('amount'),
                        lineQuantity__c = (Decimal)result.get('nb')
                    );
                    parentToUpdate.add(parentRecord);
                }
            }
            // Mise à jour des champs de la pièce annulée
            if(!cancelIds.isEmpty()){
                for(AggregateResult result : [SELECT cancelledPiece__c, COUNT(Id) nb, SUM(amount__c) amount FROM AccountingPiece__c 
                                                WHERE cancelledPiece__c IN :cancelIds GROUP BY cancelledPiece__c]){
                    System.debug('## Cancel Result: '+result); 
                    AccountingPiece__c cancelRecord = new AccountingPiece__c(
                        Id = (String)result.get('cancelledPiece__c'),
                        cancelledAmount__c = (Decimal)result.get('amount'),
                        cancelledQuantity__c = (Decimal)result.get('nb')
                    );
                    cancelToUpdate.add(cancelRecord);
                }     
            }
        }
        System.debug('## parentToUpdate: '+parentToUpdate);
        System.debug('## cancelToUpdate: '+cancelToUpdate);

        //Cas spécifique pour gérer la supression ou l'annulation de la dernière pièce enfant d'une pièce parent
        //Dans le cas supression ou update si tout les parents n'ont pas été update 
        if((Trigger.isUpdate || Trigger.isDelete) && !parentIds.isEmpty() && parentToUpdate.size() != parentIds.size()){
           for(string id : parentIds){
                Boolean parentUpdated = false;
                for(AccountingPiece__c parentRecord : parentToUpdate){
                    if(parentrecord.Id == id){
                        parentUpdated = true;
                    }
                }
                // parent non update (sans enfants) vide montant et quantité
                if(parentUpdated == false){
                    AccountingPiece__c parentToReset = new AccountingPiece__c(
                        Id = id,
                        lineAmount__c = null,
                        lineQuantity__c = null
                    );
                    parentToUpdate.add(parentToReset);
                    System.debug('## parentToReset: '+parentToReset.Id); 
                }
           }
        }

        //Cas spécifique pour gérer la mise à jour d'une pièce annulée avec une seule annulation quand elle est supprimée
        //dans le cas supression si toutes les pièces annulées n'ont pas été update
        if(Trigger.isDelete && !cancelIds.isEmpty() && cancelToUpdate.size() != cancelIds.size()){
            for(string id : cancelIds){
                Boolean cancelledPieceUpdated = false;
                for(AccountingPiece__c cancelledPiece : cancelToUpdate){
                    if(cancelledPiece.Id == id){
                        cancelledPieceUpdated = true;
                    }
                }
                //Si pièce annulé non update (plus d'annulation existante sur la pièce) alors vide montant et quantité
                if(cancelledPieceUpdated == false){
                    AccountingPiece__c cancelRecord = new AccountingPiece__c(
                        Id = id,
                        cancelledAmount__c = null,
                        cancelledQuantity__c = null
                    );
                    cancelToUpdate.add(cancelRecord);   
                    System.debug('## cancelled: '+cancelRecord.Id); 
                }
           }
        }

        if(!parentToUpdate.isEmpty()) {
            update parentToUpdate;
        }

        if(!cancelToUpdate.isEmpty()) {
            update cancelToUpdate;
        }
        System.debug('### FIN TR022_AccountingPiece.updateParentAndCancelFieldsRollup');
    }

    /**
    * @description Méthode pour mettre à jour le montant sur les commandes/comptes lorsqu'une pièce est créée ou validée (comptabilisé)
    * @param userContext contexte utilisateur
    */
    public static void updateOrderAndAccountAmount(UserContext userContext) {
        System.debug('### DEBUT TR022_AccountingPiece.updateOrderAndAccountAmount');
        
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new;
        Map<Id, AccountingPiece__c> oldAccountingPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        Set<String> customerOrderIds = new Set<String>();
        List<Order> customerOrdertoUp = new List<Order>();
        Map<String, List<AccountingPiece__c>> accPieceOrderMap = new Map<String, List<AccountingPiece__c>>();
        Set<String> accountIds = new Set<String>();
        List<Account> accountToUp = new List<Account>();
        Map<String, List<AccountingPiece__c>> accPieceAccountMap = new Map<String, List<AccountingPiece__c>>();

        for(AccountingPiece__c newAccPiece : newAccountingPieces) {
            AccountingPiece__c oldAccPiece = oldAccountingPieces == null ? null : oldAccountingPieces.get(newAccPiece.id);
            System.debug('## AccountingPiece Id: '+newAccPiece.Id);
            
            if(String.isNotBlank(newAccPiece.order__c) && newAccPiece.amount__c != null && (Trigger.isInsert 
                || (Trigger.isUpdate && oldAccPiece != null && (oldAccPiece.amount__c != newAccPiece.amount__c || oldAccPiece.accountingDate__c != newAccPiece.accountingDate__c))) 
            ) {
                System.debug('## Order Id: '+newAccPiece.order__c);
                customerOrderIds.add(newAccPiece.order__c);
            }
            if(String.isNotBlank(newAccPiece.account__c) && newAccPiece.amount__c != null && (Trigger.isInsert 
                || (Trigger.isUpdate && oldAccPiece != null && (oldAccPiece.amount__c != newAccPiece.amount__c || oldAccPiece.accountingDate__c != newAccPiece.accountingDate__c))) 
            ) {
                System.debug('## Account Id: '+newAccPiece.account__c);
                accountIds.add(newAccPiece.account__c);
            }
        }

        if(!customerOrderIds.isEmpty()) {
            // Création d'une map de pièces par commandes
            for (AccountingPiece__c accPiece : [SELECT Id, order__c, amount__c, accountingDate__c FROM AccountingPiece__c 
                                                WHERE order__c IN :customerOrderIds AND amount__c != null AND RecordTypeId != :RT_AP_COMPOSITERECEIPT]) {
                List<AccountingPiece__c> accPiecesList;
                // Vérification liste temporaire des commandes
                if(accPieceOrderMap.get(accPiece.order__c) == null) {
                    accPiecesList = new List<AccountingPiece__c>();
                } else {
                    accPiecesList = accPieceOrderMap.get(accPiece.order__c);
                }
                // Mise à jour de la liste des pieces par commandes
                accPiecesList.add(accPiece);
                accPieceOrderMap.put(accPiece.order__c, accPiecesList);
            }
            System.debug('## accPieceOrderMap: '+accPieceOrderMap);

            // Sommmes des montants des pieces par commande
            for (String orderId : accPieceOrderMap.keySet()) {
                System.debug('## MAJ Order Id: '+orderId);
                Decimal unrecordedAccPieceAMount = 0;
                Decimal recordedAccPieceAMount = 0;
                for (AccountingPiece__c accPiece : accPieceOrderMap.get(orderId)) {
                    System.debug('## Amount: '+accPiece.Id+' / '+accPiece.accountingDate__c+' / '+accPiece.amount__c);
                    if(accPiece.accountingDate__c == null) {
                        unrecordedAccPieceAMount = unrecordedAccPieceAMount + accPiece.amount__c;
                    } else {
                        recordedAccPieceAMount = recordedAccPieceAMount + accPiece.amount__c;
                    }
                }
                System.debug('## Unrecorded Amount: '+unrecordedAccPieceAMount);
                System.debug('## Recorded Amount: '+recordedAccPieceAMount);
                // Mise à jour de la commande
                customerOrdertoUp.add(new Order(
                    Id = orderId,
                    unrecordedAccountingPiecesAmount__c = unrecordedAccPieceAMount.setScale(2),
                    recordedAccountingPiecesAmount__c = recordedAccPieceAMount.setScale(2)
                ));
            }

            if(!customerOrdertoUp.isEmpty()) {
                update customerOrdertoUp;
            }
        }

        if(!accountIds.isEmpty()) {
            // Création d'une map de pièces par compte
            for (AccountingPiece__c accPiece : [SELECT Id, account__c, amount__c, accountingDate__c, account__r.RecordTypeId
                                                FROM AccountingPiece__c WHERE account__c IN :accountIds 
                                                AND amount__c != null AND RecordTypeId != :RT_AP_COMPOSITERECEIPT]) {
                List<AccountingPiece__c> accPiecesList;
                // Vérification liste temporaire des comptes
                if(accPieceAccountMap.get(accPiece.account__c) == null) {
                    accPiecesList = new List<AccountingPiece__c>();
                } else {
                    accPiecesList = accPieceAccountMap.get(accPiece.account__c);
                }
                // Mise à jour de la liste des pieces par comptes
                if(accPiece.account__r.RecordTypeId == RT_ACC_PERSO || accPiece.account__r.RecordTypeId == RT_ACC_PRO){
                    accPiecesList.add(accPiece);
                    accPieceAccountMap.put(accPiece.account__c, accPiecesList);
                }
            }
            System.debug('## accPieceAccountMap: '+accPieceAccountMap);

            // Sommmes des montants des pieces par comptes
            for (String accountId : accPieceAccountMap.keySet()) {
                System.debug('## MAJ Account Id: '+accountId);
                Decimal unrecordedAccPieceAMount = 0;
                Decimal recordedAccPieceAMount = 0;
                for (AccountingPiece__c accPiece : accPieceAccountMap.get(accountId)) {
                    System.debug('## Amount: '+accPiece.Id+' / '+accPiece.accountingDate__c+' / '+accPiece.amount__c);
                    if(accPiece.accountingDate__c == null) {
                        unrecordedAccPieceAMount = unrecordedAccPieceAMount + accPiece.amount__c;
                    } else {
                        recordedAccPieceAMount = recordedAccPieceAMount + accPiece.amount__c;
                    }
                }
                System.debug('## Unrecorded Amount: '+unrecordedAccPieceAMount);
                System.debug('## Recorded Amount: '+recordedAccPieceAMount);
                // Mise à jour de la commande
                accountToUp.add(new Account(
                    Id = accountId,
                    unrecordedAccountingPiecesAmount__c = unrecordedAccPieceAMount.setScale(2),
                    recordedAccountingPiecesAmount__c = recordedAccPieceAMount.setScale(2)
                ));
            }

            if(!accountToUp.isEmpty()) {
                update accountToUp;
            }
        }
        System.debug('### FIN TR022_AccountingPiece.updateOrderAndAccountAmount');
    }

    /**
    * @description Méthode pour mettre à jour le montant percu sur les factures lorsqu'une pièce est créée ou validée (comptabilisé)
    * @param userContext contexte utilisateur
    */
    public static void updateInvoiceAdvanceAmount(UserContext userContext) {
        System.debug('### DEBUT TR022_AccountingPiece.updateInvoiceAdvanceAmount');
        
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new;
        Map<Id, AccountingPiece__c> oldAccountingPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap; 
        Set<String> invoiceIds = new Set<String>();
        List<invoice__c> invoicetoUp = new List<invoice__c>();
        Map<String, List<AccountingPiece__c>> accPieceInvoiceMap = new Map<String, List<AccountingPiece__c>>();

        for(AccountingPiece__c newAccPiece : newAccountingPieces) {
            AccountingPiece__c oldAccPiece = oldAccountingPieces == null ? null : oldAccountingPieces.get(newAccPiece.id);
            System.debug('## AccountingPiece Id: '+newAccPiece.Id);
            
            if(String.isNotBlank(newAccPiece.invoice__c) && newAccPiece.amount__c != null && (Trigger.isInsert 
                || (Trigger.isUpdate && oldAccPiece != null && (oldAccPiece.amount__c != newAccPiece.amount__c || oldAccPiece.accountingDate__c != newAccPiece.accountingDate__c))) 
            ) {
                System.debug('## Invoice Id: '+newAccPiece.invoice__c);
                invoiceIds.add(newAccPiece.invoice__c);
            }
        }

        if(!invoiceIds.isEmpty()) {
            // Récupération infos des factures
            Map<String, invoice__c> invoicesMap = new Map<String, invoice__c>([SELECT Id, invoiceDate__c, invoiceReference__c, customerOrder__c,
                                                                                toPerceiveAmount__c, paymentDate__c FROM invoice__c WHERE Id IN :invoiceIds]);
            // Création d'une map de pièces par factures
            for (AccountingPiece__c accPiece : [SELECT Id, invoice__c, amount__c, accountingDate__c, RecordTypeId, order__c FROM AccountingPiece__c 
                                                WHERE invoice__c IN :invoiceIds AND amount__c != null AND RecordTypeId != :RT_AP_COMPOSITERECEIPT]) {
                List<AccountingPiece__c> accPiecesList;
                // Vérification liste temporaire des factures
                if(accPieceInvoiceMap.get(accPiece.invoice__c) == null) {
                    accPiecesList = new List<AccountingPiece__c>();
                } else {
                    accPiecesList = accPieceInvoiceMap.get(accPiece.invoice__c);
                }
                // Mise à jour de la liste des pieces par factures
                accPiecesList.add(accPiece);
                accPieceInvoiceMap.put(accPiece.invoice__c, accPiecesList);
            }
            System.debug('## accPieceInvoiceMap: '+accPieceInvoiceMap);

            // Sommmes des montants des pieces par factures
            for (String invoiceId : accPieceInvoiceMap.keySet()) {
                System.debug('## MAJ Invoice Id: '+invoiceId);
                Decimal accPieceAmount = 0;
                Date lastAccountingDate;
                invoice__c inv = invoicesMap.get(invoiceId);

                // Calcul montant
                for (AccountingPiece__c accPiece : accPieceInvoiceMap.get(invoiceId)) {
                    System.debug('## Amount: '+accPiece.Id+' / '+accPiece.accountingDate__c+' / '+accPiece.amount__c);
                    if(accPiece.accountingDate__c != null && inv.customerOrder__c == accPiece.order__c && accPiece.RecordTypeId == RT_AP_RECEIPT) {
                        accPieceAmount = accPieceAmount + accPiece.amount__c;
                        if(lastAccountingDate == null || lastAccountingDate < accPiece.accountingDate__c){
                            lastAccountingDate = accPiece.accountingDate__c;
                        }
                    }
                }
                System.debug('## Invoice Advance Amount: '+accPieceAmount);
                inv.perceivedAmount__c = accPieceAmount.setScale(2);

                if(inv.perceivedAmount__c >= inv.toPerceiveAmount__c && inv.paymentDate__c == null){
                    inv.paymentDate__c = lastAccountingDate;
                }

                // Mise à jour de la facture
                if(accPieceAmount != 0) {
                    invoicetoUp.add(inv);
                }
                System.debug('## Invoice Updated: '+invoiceId);
            }

            if(!invoicetoUp.isEmpty()) {
                update invoicetoUp;
            }
        }

        System.debug('### FIN TR022_AccountingPiece.updateInvoiceAdvanceAmount');
    }

    /**
    * @description Méthode pour exécuter les processus d'approbation sur des demandes de remboursement
    * @param userContext contexte utilisateur
    */
    public static void executeApprovalProcess(UserContext userContext) {
        System.debug('### DEBUT TR022_AccountingPiece.executeApprovalProcess');
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new; 

        // F - Demande d'approbation
        for (AccountingPiece__c newAccountingPiece : newAccountingPieces) {
            if(String.isNotBlank(newAccountingPiece.Id) && Trigger.isAfter && Trigger.isInsert 
                && (newAccountingPiece.RecordTypeId == RT_AP_CHECKREQUEST || newAccountingPiece.RecordTypeId == RT_AP_REFUND)
                && !newAccountingPiece.isLegacy__c && !newAccountingPiece.isPositiveCheckRequest__c
            ) 
            {
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setObjectId(newAccountingPiece.id);
                req1.setProcessDefinitionNameOrId('AccountingPiece_ApprovalProcess_V1');
                Approval.ProcessResult result = Approval.process(req1);
            }
        }
        System.debug('### FIN TR022_AccountingPiece.executeApprovalProcess');
    }

    /**
    * @description Méthode pour créer la pièce de demande de chèque positive lors de l'approbation de la demande négative si elle n'existe pas
    * @param userContext contexte utilisateur
    */
    public static void createCheckRequestOnApprobation(UserContext userContext){
        System.debug('### DEBUT TR022_AccountingPiece.createCheckRequestOnApprobation');
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new;
        Map<Id, AccountingPiece__c> oldAccountingPieces = (Map<Id, AccountingPiece__c>)Trigger.oldMap;
        List<AccountingPiece__c> tempCheckRequestToCopyList = new List<AccountingPiece__c>(); 
        List<AccountingPiece__c> checkRequestToCopyList = new List<AccountingPiece__c>();
        List<Id> checkRequestToCopyIds = new List<Id>();
        //Set<Id> relatedCreditMemo = new Set<Id>();
        Set<Id> relatedOrder = new Set<Id>();
        List<AccountingPiece__c> checkRequestToCreateList = new List<AccountingPiece__c>();
        List<AccountingPiece__c> checkRequestToUpdateList = new List<AccountingPiece__c>();
        List<String> fieldNameList = new List<String>{
            'inputEntity__c',
            'orderEntity__c',
            'account__c',
            'order__c',
            'creditMemo__c',
            'pieceDate__c',
            'refundReason__c',
            'paymentMethod__c',
            'externalBank__c',
            'comments__c',
            'externalReference__c'
        };


        for (AccountingPiece__c newAccountingPiece : newAccountingPieces) {
            AccountingPiece__c oldAccountingPiece = oldAccountingPieces == null ? null : oldAccountingPieces.get(newAccountingPiece.id);

            System.debug('## oldAccountingPiece.isValid__c:' + oldAccountingPiece.isValid__c);
            System.debug('## newAccountingPiece.isValid__c:' + newAccountingPiece.isValid__c);
            System.debug('## newAccountingPiece.isLegacy__c:' + newAccountingPiece.isLegacy__c);
            System.debug('## newAccountingPiece.isPositiveCheckRequest__c:' + newAccountingPiece.isPositiveCheckRequest__c);


            //Déclenchement à la validation par le process d'approbation d'une pièce de type Demande de chèque non positive
            if(String.isNotBlank(newAccountingPiece.Id) && Trigger.isAfter && Trigger.isUpdate
            && newAccountingPiece.RecordTypeId == RT_AP_CHECKREQUEST
            && !newAccountingPiece.isLegacy__c
            && !newAccountingPiece.isPositiveCheckRequest__c
            && oldAccountingPiece.isValid__c != newAccountingPiece.isValid__c 
            && newAccountingPiece.isValid__c){
                tempCheckRequestToCopyList.Add(newAccountingPiece);
                //relatedCreditMemo.Add(newAccountingPiece.creditMemo__c);
                relatedOrder.Add(newAccountingPiece.order__c);
                checkRequestToCopyIds.Add(newAccountingPiece.Id);
            }
        }

        System.debug('## tempCheckRequestToCopyList :'+tempCheckRequestToCopyList);
        System.debug('## relatedOrder :'+relatedOrder);
        System.debug('## checkRequestToCopyIds :'+checkRequestToCopyIds);

        if(!tempCheckRequestToCopyList.isEmpty()){
            string accountingPieceQuery = SchemaUtils.getQuery('AccountingPiece__c', 'order__c', relatedOrder);
            accountingPieceQuery += 'AND isLegacy__c = false AND isPositiveCheckRequest__c != true'; 
            //AND Id NOT IN :checkRequestToCopyIds';
            accountingPieceQuery += ' AND ';
            for(Integer i =0; i<checkRequestToCopyIds.size()-1; i++){
                accountingPieceQuery+='Id != \''+checkRequestToCopyIds[i]+'\' AND ';
            }
            accountingPieceQuery += 'Id != \''+checkRequestToCopyIds[checkRequestToCopyIds.size()-1]+'\'';

            List<AccountingPiece__c> checkRequestOnSameOrderList = Database.query(accountingPieceQuery);                                                           
            
            
            for(AccountingPiece__c checkRequest : tempCheckRequestToCopyList){
                Boolean existingInvertedCheckRequest = false;
                if(checkRequestOnSameOrderList !=null && !checkRequestOnSameOrderList.isEmpty()){
                    for(AccountingPiece__c checkRequestOnSameOrder : checkRequestOnSameOrderList){                       
                        //vérifier si une pièce avec les mêmes valeurs dans les champs listés et le montant inversé existe
                        if(checkIfSameValueOnField(checkRequest, checkRequestOnSameOrder, fieldNameList) && checkRequest.amount__c + checkRequestOnSameOrder.amount__c == 0){
                            existingInvertedCheckRequest = true;
                            System.debug('## Pièce positive trouvée');
                            //Met le champ isPositiveCheckRequest__c sur True si il ne l'est pas pour indiquer que c'est une demande de chèque positive
                            if(checkRequestOnSameOrder.isPositiveCheckRequest__c != true){
                                checkRequestOnSameOrder.isPositiveCheckRequest__c = true;
                                checkRequestOnSameOrder.accountingDate__c = System.Today();
                                checkRequestToUpdateList.Add(checkRequestOnSameOrder);
                            }
                        }
                    }
                }
                //Si aucune pièce n'existe on ajoute dans la liste des pièces à créer
                if(!existingInvertedCheckRequest){
                    checkRequestToCopyList.Add(checkRequest);
                }
            }

            System.debug('## checkRequestToUpdateList'+checkRequestToUpdateList);
            System.debug('## checkRequestToCopyList'+checkRequestToCopyList);

            if(!checkRequestToUpdateList.isEmpty()){
                update checkRequestToUpdateList;
            }
            
            if(!checkRequestToCopyList.isEmpty()){
                //Création pièce identique mais avec montant inversé
                for(AccountingPiece__c checkRequest : checkRequestToCopyList){
                    AccountingPiece__c checkRequestToCreate = new AccountingPiece__c( RecordTypeId = RT_AP_CHECKREQUEST, 
                                                                                order__c = checkRequest.order__c, 
                                                                                amount__c = -1* checkRequest.amount__c, isPositiveCheckRequest__c = true, accountingDate__c = System.today());
                    checkRequestToCreate = copyValuesOnListedFields(checkRequestToCreate, checkRequest, fieldNameList);
                    checkRequestToCreateList.Add(checkRequestToCreate);
                }

                System.debug('## checkRequestToCreate'+checkRequestToCreateList);

                insert checkRequestToCreateList;
            }

        }
    }

    /**
    * @description Méthode pour comparer les valeurs de chaques champs entre les deux objets
    * @param accPiece1 premier objet à comparer
    * @param accPiece2 deuxième objet à comparer
    * @param fieldNameList liste des noms API des champs à comparer
    * @return True si tout les champs ont la même valeur entre les deux objets, False sinon 
    */
    public static Boolean checkIfSameValueOnField(AccountingPiece__c accPiece1, AccountingPiece__c accPiece2, List<String> fieldNameList){
        for(String fieldName : fieldNameList){
            if(accPiece1.get(fieldName) != accPiece2.get(fieldName)){
                return false;
            }
        }
        return true;        
    }

    /**
    * @description Méthode pour comparer les valeurs de chaques champs entre les deux objets
    * @param accPiece1 premier objet à comparer
    * @param accPiece2 deuxième objet à comparer
    * @param fieldNameList liste des noms API des champs à comparer
    * @return True si tout les champs ont la même valeur entre les deux objets, False sinon 
    */
    public static AccountingPiece__c copyValuesOnListedFields(AccountingPiece__c accPiecetoCreate, AccountingPiece__c accPiecetoCopy, List<String> fieldNameList){
        for(String fieldName : fieldNameList){
            accPiecetoCreate.put(fieldName, accPiecetoCopy.get(fieldName));
        }
        return accPiecetoCreate;        
    }

    /**
    * @description Méthode pour alimenter les écritures comptables sur les pièces enfants (demande 1200)
    * @param accPieceEnfants Liste des pièces comptables enfants
    * @param childRecordsToUpdate Liste des pièces comptables enfants à modifier
    * @param parentIds Set des Id des pièces parents 
    */
    public static void updateAccEntryOnNewAccpiece(UserContext userContext) {
        
        System.debug('## Debut updateAccEntryOnNewAccpiece');
        List<AccountingPiece__c> newAccountingPieces = (List<AccountingPiece__c>)Trigger.new;
        Map<Id,AccountingPiece__c> newAccountingPiecesMap = (Map<Id,AccountingPiece__c>)Trigger.newMap;        
        List<AccountingPiece__c> childRecordsToUpdate = new List<AccountingPiece__c>();
        Set<Id> parentIds = new Set<Id>();
        
        // Recupération des Ids des pieces parents 
        for (AccountingPiece__c newAccPiece : newAccountingPieces) {
            if (newAccPiece.parent__c == null && newAccPiece.RecordTypeId == RT_AP_COMPOSITERECEIPT) {
                parentIds.add(newAccPiece.Id);
            }
        }
        if (!parentIds.isEmpty()) {
            // Récupérer les pièces enfants à partir des parents
            List<AccountingPiece__c> accPieceEnfants = [SELECT Id, parent__c, accountingEntry__c, accountingDate__c FROM AccountingPiece__c WHERE parent__c IN :parentIds];

            if (!accPieceEnfants.isEmpty()) {
                for (AccountingPiece__c enfant : accPieceEnfants) {
                    // Alimenter le champ d'écriture comptable des pièces enfants
                    if (enfant.accountingEntry__c != newAccountingPiecesMap.get(enfant.parent__c).accountingEntry__c ) {
                        enfant.accountingEntry__c = newAccountingPiecesMap.get(enfant.parent__c).accountingEntry__c;
                        if (enfant.accountingDate__c == null)
                           enfant.accountingDate__c = newAccountingPiecesMap.get(enfant.parent__c).accountingDate__c;
                        childRecordsToUpdate.add(enfant);
                        System.debug('Ecriture comptable : '+enfant.accountingEntry__c);                        
                    }                    
                }
                // update la liste des pièces enfants
                if (!childRecordsToUpdate.isEmpty()) {
                    update childRecordsToUpdate;
                }                
            }          
        }                   
    } 
}