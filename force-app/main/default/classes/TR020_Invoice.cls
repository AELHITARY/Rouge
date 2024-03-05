//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Invoice
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/02/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Invoice {
    private static final Id RT_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT);
    private static final Id RT_ADVANCE_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_ADVANCEINVOICE_RT);
    private static final Id RT_AP_COMPOSITERECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);
    private static final Id RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);

    /**
    * @description Méthode exécutant les règles de validation pour les factures
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Invoice.applyValidationRules');
        
        List<Invoice__c> oldInvoices = (List<Invoice__c>)Trigger.old;
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;

        // DELETE
        if(!oldInvoices.isEmpty()) {
            for(Invoice__c oldInvoice : oldInvoices){
                // Ne pas supprimer si la commande est verrouillé
                if(oldInvoice.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore){
                    System.debug('## oldInvoice.isOrderLocked__c : ' + oldInvoice.isOrderLocked__c);
                    oldInvoice.addError(Label.order_msg_cantDeleteInvoice);
                }  
            }
        }

        // AFTER
        if(newInvoices != null && !newInvoices.isEmpty()) {
            for(Invoice__c newInvoice : newInvoices){
                // Vérification champ headOffice obligatoire
                if(newInvoice.isLegacy__c == false && Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)){
                    System.debug('## Check champ HeadOffice : ' + newInvoice.Id);
                    String errorMsg = 'Champ obligatoire!';
                    if(newInvoice.headOfficeShareCapital__c == null) {
                        newInvoice.headOfficeShareCapital__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.headOfficePostalCode__c)) {
                        newInvoice.headOfficePostalCode__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.headOfficeLegalForm__c)) {
                        newInvoice.headOfficeLegalForm__c.addError(errorMsg);
                    }
                    if(newInvoice.headOfficeSIREN__c == null) {
                        newInvoice.headOfficeSIREN__c.addError(errorMsg);
                    }
                    if(newInvoice.headOfficeSIRET__c == null) {
                        newInvoice.headOfficeSIRET__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.headOfficeName__c)) {
                        newInvoice.headOfficeName__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.headOfficeCity__c)) {
                        newInvoice.headOfficeCity__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.RCSCity__c)) {
                        newInvoice.RCSCity__c.addError(errorMsg);
                    }
                    if(String.isBlank(newInvoice.RCSNumber__c)) {
                        newInvoice.RCSNumber__c.addError(errorMsg);
                    }
                }  
            }  
        }
        
        System.debug('### FIN TR020_Invoice.applyValidationRules');
    }

    /**
    * @description Méthode pour interdire la modification d'une facture comptabilisée. Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void applyNonByPassableRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Invoice.applyNonByPassableRules');

        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap;
        for(Invoice__c newInvoice : (List<Invoice__c>)Trigger.new){
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.Id);
            if(oldInvoice.invoiceDate__c != null && oldInvoice.invoiceDate__c != newInvoice.invoiceDate__c) {
                newInvoice.addError('Impossible de modifier la date de facture d\'une facture déjà comptabilisée');
            }  
        }
        System.debug('### FIN TR020_Invoice.applyNonByPassableRules');
    }

    /**
    * @description Méthode pour interdire la suppression d'une facture pour 10 ans si elle a une numéro fiscal. Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotDeleteInvoice(UserContext userContext) {
        System.debug('### DEBUT TR020_Invoice.cannotDeleteInvoice');
        
        List<Invoice__c> oldInvoices = (List<Invoice__c>)Trigger.old;
        for(Invoice__c oldInvoice : oldInvoices){
            if(oldInvoice.isInvoiceLocked__c && Trigger.isDelete && Trigger.isBefore)
            {
                oldInvoice.addError(Label.invoice_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_Invoice.cannotDeleteInvoice');
    }

    /**
    * @description Fonctions pour faire appels aux MAJ des champs et des status
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
        applyAdvancePaymentUpdateRules(userContext);
    }

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
          
        System.debug('### DEBUT TR020_Invoice.applyDataUpdateRules');
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new; 
        List<InvoiceLine__c> invoiceLinesList = new List<InvoiceLine__c>(); 
        Set<String> orderIds = new Set<String>();  
        Set<String> invoiceIds = new Set<String>();  
        Set<String> notReferencedInvoiceIds = new Set<String>();  
        Set<String> invoiceIdsList = new Set<String>();  
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap; 
        Map<Id, Order> orderMap = new Map<Id, Order>();  
        Map<String, List<AccountingPiece__c>> accPieceInvoiceMap = new Map<String, List<AccountingPiece__c>>();
        Map<String, Account> entityHierarchieMap = new Map<String, Account>();
      
        // A - Initialisation des données intermédiaires 
        String kparkUserId = Label.system_id_user_kpark;

        // Recherche des objets associées 
        for (Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id);   

            if(String.isNotBlank(newInvoice.id) && newInvoice.isLegacy__c == false) {
                invoiceIdsList.add(newInvoice.id);
                invoiceIds.add(newInvoice.Id);
            }

            // MAJ infos de la commande
            if((Trigger.isInsert || (Trigger.isUpdate && newInvoice.customerOrder__c != oldInvoice.customerOrder__c)) && String.isNotBlank(newInvoice.customerOrder__c)) {
                orderIds.add(newInvoice.customerOrder__c);
            }
            // MAJ infos montant acompte facture si pas de référence
            if((Trigger.isInsert || (Trigger.isUpdate && newInvoice.invoiceDate__c != oldInvoice.invoiceDate__c)) 
                && String.isNotBlank(newInvoice.Id) && String.isBlank(newInvoice.invoiceReference__c)
            ) 
            {
                notReferencedInvoiceIds.add(newInvoice.Id);
            }
        }
        
        // Récupération information pour numéro fiscal
        List<Invoice__c> lstInv = [SELECT Id, autoNumber__c FROM Invoice__c WHERE RecordTypeId = :RT_INVOICE 
                                        AND autoNumber__c != null ORDER BY autoNumber__c DESC LIMIT 1];
        Decimal intCounter = 0;
        if(!lstInv.isEmpty()) {
            intCounter = lstInv[0].autoNumber__c; 
        }

        // Récupération des enregistrements d'objets associés
        if(!orderIds.isEmpty()) {
            orderMap = new Map<Id, Order>([SELECT Id, AccountId, BillToContactId, billingName__c, BillingStreet, BillingPostalCode, BillingCity, Account.Name, BillingState, BillingCountry,
                                                salesEntity__c, salesEntity__r.rue__c, salesEntity__r.codePostal__c, salesEntity__r.ville__c, salesEntity__r.departement__c, chantier__c,
                                                salesEntity__r.pays__c, salesEntity__r.Name, salesEntity__r.Ownership, salesEntity__r.complementAdresse__c, ShipToContactId, shippingName__c,
                                                ShippingStreet, ShippingPostalCode, ShippingCity, ShippingState, ShippingCountry, serviceEntity__c, serviceEntity__r.rue__c, serviceEntity__r.codePostal__c, 
                                                serviceEntity__r.ville__c, serviceEntity__r.departement__c, serviceEntity__r.pays__c, serviceEntity__r.Name, serviceEntity__r.complementAdresse__c,
                                                salesEntity__r.emailPro__c, serviceEntity__r.emailPro__c, salesEntity__r.Phone, serviceEntity__r.Phone, billingAdditionalAddress__c, shippingAdditionalAddress__c,
                                                serviceEntity__r.SIRET__c, salesEntity__r.shareCapital__c, salesEntity__r.SIREN__c, salesEntity__r.SIRET__c,
                                                salesEntity__r.RCSNumber__c, salesEntity__r.RCSCity__c, serviceEntity__r.intracommunityVATNumber__c, salesEntity__r.intracommunityVATNumber__c,
                                                Account.contactParDefaut__c
                                                   FROM Order 
                                                   WHERE id IN :orderIds]);
            System.debug('## orderMap: '+orderMap ); 
            // Récupération des entités
            entityHierarchieMap = getEntityHierarchy();
        }

        if(!invoiceIdsList.isEmpty()) {
            invoiceLinesList = [SELECT Id, invoice__c, amount__c, pretaxAmount__c, listPrice__c, priceReduction__c, unitPrice__c
                                    FROM InvoiceLine__c WHERE invoice__c IN :invoiceIdsList AND parentLine__c = null];
        }      

        // Récupération des pièces comptables
        if(!invoiceIds.isEmpty()) {
            // Création d'une map de pièces par factures
            for (AccountingPiece__c accPiece : [SELECT Id, invoice__c, amount__c, accountingDate__c, order__c, RecordTypeId  FROM AccountingPiece__c 
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
        }      
                           
        // B - Application des règles de mise à jour
        for (Invoice__c newInvoice : newInvoices) {
            System.debug('## ------ Id: '+newInvoice.Id); 
            System.debug('## CustomerOrder: '+newInvoice.customerOrder__c ); 
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id);            

            // Alimentation du propriétaire
            if(Trigger.isInsert && kparkUserId != null){
                newInvoice.OwnerId = kparkUserId;
            }
            
            // Alimentation numérotation automatique seulement pour les factures lors du passage au statut "Générée"
            if(newInvoice.RecordTypeId == RT_INVOICE && newInvoice.invoiceDate__c != null && newInvoice.invoiceReference__c == null && intCounter != null && newInvoice.isLegacy__c == false){
                intCounter ++;
                newInvoice.autoNumber__c = intCounter;
                // Formatage de la référence FAC/{0000000} 
                String ref = 'FAC/';
                for(Integer i=0; i < 7 - intCounter.precision(); i++) {
                    ref += '0';
                }
                newInvoice.invoiceReference__c = ref+''+intCounter;
            }

            // Mise à jour montant percu de la facture
            if(String.isNotBlank(newInvoice.Id) && newInvoice.isLegacy__c == false 
                && accPieceInvoiceMap != null && accPieceInvoiceMap.get(newInvoice.Id) != null) 
            {
                Decimal accPieceAmount = 0;
                Date lastAccountingDate;
                for (AccountingPiece__c accPiece : accPieceInvoiceMap.get(newInvoice.Id)) {
                    System.debug('## Amount: '+accPiece.Id+' / '+accPiece.accountingDate__c+' / '+accPiece.amount__c);
                    if(accPiece.accountingDate__c != null && newInvoice.customerOrder__c == accPiece.order__c && accPiece.RecordTypeId == RT_AP_RECEIPT) {
                        accPieceAmount = accPieceAmount + accPiece.amount__c;
                        if(lastAccountingDate == null || lastAccountingDate < accPiece.accountingDate__c){
                            lastAccountingDate = accPiece.accountingDate__c;
                        }
                    }
                }
                System.debug('## Invoice Advance Amount: '+accPieceAmount);
                newInvoice.perceivedAmount__c = accPieceAmount.setScale(2);

                if(newInvoice.perceivedAmount__c >= newInvoice.toPerceiveAmount__c && newInvoice.toPerceiveAmount__c != null && newInvoice.paymentDate__c == null){
                    newInvoice.paymentDate__c = lastAccountingDate;
                }
            }
            
            // Mise à jour des montants de la facture (ROLL UP des lignes avec condition)
            if(newInvoice.autoComputedAmount__c && newInvoice.RecordTypeId == RT_INVOICE && newInvoice.isLegacy__c == false){
                Decimal amount = 0;
                Decimal pretaxAmount = 0;
                Decimal priceReduction = 0;
                Decimal listPrice = 0;
                for (InvoiceLine__c line : invoiceLinesList) {
                    if(line.invoice__c == newInvoice.Id) {
                        amount = (line.amount__c == null) ? amount : amount + line.amount__c.setScale(2);
                        pretaxAmount = (line.pretaxAmount__c == null) ? pretaxAmount : pretaxAmount + line.pretaxAmount__c.setScale(2);
                        priceReduction = (line.priceReduction__c == null) ? priceReduction : priceReduction + line.priceReduction__c.setScale(2);
                        listPrice = (line.unitPrice__c == null) ? listPrice : listPrice + line.unitPrice__c.setScale(2);
                    }
                }
                newInvoice.amount__c = amount;
                newInvoice.pretaxAmount__c = pretaxAmount;
                newInvoice.priceReduction__c = priceReduction;
                newInvoice.listAmount__c = listPrice;
                newInvoice.amountWithoutDiscount__c = amount + priceReduction;
            }
            // Mise à jour des montants de la facture d'acompte (Montant HT = Montant TTC (acompte) - TVA calculé par ligne)
            if(newInvoice.autoComputedAmount__c && newInvoice.RecordTypeId == RT_ADVANCE_INVOICE && newInvoice.isLegacy__c == false){
                Decimal pretaxAmount = newInvoice.amount__c - newInvoice.VATamount__c;
                newInvoice.pretaxAmount__c = (pretaxAmount != null) ? pretaxAmount.setScale(2) : null;
            }
            System.debug('## amount: ' + newInvoice.amount__c);
            System.debug('## pretaxAmount: ' + newInvoice.pretaxAmount__c);

            // Mise à jour des champs de montant pour problème de décimal            
            newInvoice.cancelledAmount__c = (newInvoice.cancelledAmount__c != null) ? newInvoice.cancelledAmount__c.setScale(2) : null;
            
            // Date d'échéance au statut "Générée"
            if(Trigger.isUpdate && newInvoice.dueDate__c == null && newInvoice.invoiceDate__c != null){
                Integer dueDateDelay = PropertiesUtils.getIntegerValue('invoice.core.dueDate.delay', 30);
                newInvoice.dueDate__c = newInvoice.invoiceDate__c.addDays(dueDateDelay);
            }

            // Dé-annulation d'un RDV
            if(Trigger.isUpdate && newInvoice.paymentDate__c != null && newInvoice.status__c != Constants.INVOICE_ANNULEE ) {
                newInvoice.status__c = Constants.INVOICE_ACQUITTEE;
            }

            // MAJ des informations par rapport à la commande client            
            if(String.isNotBlank(newInvoice.customerOrder__c) && orderMap.get(newInvoice.customerOrder__c) != null && newInvoice.isLegacy__c == false) {
                newInvoice.worksite__c = orderMap.get(newInvoice.customerOrder__c).chantier__c;

                // MAJ des informations du compte de facturation
                if(String.isNotBlank(orderMap.get(newInvoice.customerOrder__c).AccountId)) {
                    System.debug('## MAJ des informations du compte de facturation: '+orderMap.get(newInvoice.customerOrder__c).BillToContactId); 
                    newInvoice.billingAccount__c = orderMap.get(newInvoice.customerOrder__c).AccountId;
                    newInvoice.billingContact__c = orderMap.get(newInvoice.customerOrder__c).Account.contactParDefaut__c;
                    newInvoice.billingName__c = orderMap.get(newInvoice.customerOrder__c).billingName__c;
                    newInvoice.billingStreet__c = orderMap.get(newInvoice.customerOrder__c).BillingStreet;
                    newInvoice.billingPostalCode__c = orderMap.get(newInvoice.customerOrder__c).BillingPostalCode;
                    newInvoice.billingCity__c = orderMap.get(newInvoice.customerOrder__c).BillingCity;
                    newInvoice.billingAdditionalAddress__c = orderMap.get(newInvoice.customerOrder__c).billingAdditionalAddress__c;
                    newInvoice.billingState__c = orderMap.get(newInvoice.customerOrder__c).BillingState;
                    newInvoice.billingCountry__c = orderMap.get(newInvoice.customerOrder__c).BillingCountry;
                    System.debug('## MAJ des informations du compte de livraison: '+orderMap.get(newInvoice.customerOrder__c).ShipToContactId); 
                    newInvoice.shippingContact__c = orderMap.get(newInvoice.customerOrder__c).Account.contactParDefaut__c;
                    newInvoice.shippingName__c = orderMap.get(newInvoice.customerOrder__c).shippingName__c;
                    newInvoice.shippingStreet__c = orderMap.get(newInvoice.customerOrder__c).ShippingStreet;
                    newInvoice.shippingPostalCode__c = orderMap.get(newInvoice.customerOrder__c).ShippingPostalCode;
                    newInvoice.shippingCity__c = orderMap.get(newInvoice.customerOrder__c).ShippingCity;
                    newInvoice.shippingAdditionalAddress__c = orderMap.get(newInvoice.customerOrder__c).shippingAdditionalAddress__c;
                    newInvoice.shippingState__c = orderMap.get(newInvoice.customerOrder__c).ShippingState;
                    newInvoice.shippingCountry__c = orderMap.get(newInvoice.customerOrder__c).ShippingCountry;
                }
                // MAJ des informations de l'entité de vente
                if(String.isNotBlank(orderMap.get(newInvoice.customerOrder__c).salesEntity__c)) {
                    System.debug('## MAJ des informations siege social: '+orderMap.get(newInvoice.customerOrder__c).salesEntity__c); 
                    Account headOffice = calculateHeadOffice(orderMap.get(newInvoice.customerOrder__c).salesEntity__c, entityHierarchieMap);
                    if(headOffice != null) {
                        System.debug('## Head Office: '+headOffice.Id);
                        newInvoice.headOffice__c = headOffice.Id;
                        newInvoice.headOfficeName__c = headOffice.Name;
                        newInvoice.headOfficeStreet__c = headOffice.rue__c;
                        newInvoice.headOfficePostalCode__c = headOffice.codePostal__c;
                        newInvoice.headOfficeCity__c = headOffice.ville__c;
                        newInvoice.headOfficeAdditionalAddress__c = headOffice.complementAdresse__c;
                        newInvoice.headOfficeState__c = headOffice.departement__c;
                        newInvoice.headOfficeCountry__c = headOffice.pays__c;
                        newInvoice.headOfficeEmail__c = headOffice.emailPro__c;
                        newInvoice.headOfficePhone__c = headOffice.Phone;
                        newInvoice.headOfficeShareCapital__c = headOffice.shareCapital__c;
                        newInvoice.headOfficeLegalForm__c = headOffice.Ownership;
                        newInvoice.headOfficeSIREN__c = headOffice.SIREN__c;
                        newInvoice.headOfficeSIRET__c = headOffice.SIRET__c;
                        newInvoice.RCSnumber__c = headOffice.RCSNumber__c;
                        newInvoice.RCSCity__c = headOffice.RCSCity__c;
                        newInvoice.intracommunityVATNumber__c= headOffice.intracommunityVATNumber__c;
                    }
                }
                // MAJ des informations de l'entité de service
                if(String.isNotBlank(orderMap.get(newInvoice.customerOrder__c).serviceEntity__c)) {
                    System.debug('## MAJ des informations de l\'entité technique: '+orderMap.get(newInvoice.customerOrder__c).serviceEntity__c); 
                    newInvoice.seller__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__c;
                    newInvoice.sellerName__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.Name;
                    newInvoice.sellerStreet__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.rue__c;
                    newInvoice.sellerPostalCode__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.codePostal__c;
                    newInvoice.sellerCity__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.ville__c;
                    newInvoice.sellerAdditionalAddress__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.complementAdresse__c;
                    newInvoice.sellerState__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.departement__c;
                    newInvoice.sellerCountry__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.pays__c;
                    newInvoice.sellerEmail__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.emailPro__c;
                    newInvoice.sellerPhone__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.Phone;
                    newInvoice.sellerSIRET__c = orderMap.get(newInvoice.customerOrder__c).serviceEntity__r.SIRET__c;
                }      
            } 
        }
        System.debug('### FIN TR020_Invoice.applyDataUpdateRules');
    }

    /**
    * @description Règle de mise à jour du statut des factures
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Invoice : applyStatusUpdateRules');
        
        /** A - Initialisation des données intermédiaires **/
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap;
        
        /** B - Application des règles de mise à jour **/
        for (Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id); 
            System.debug('## Invoice Id: '+newInvoice.Id);

            // MAJ de champ lors d'un changement de statut
            if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) { 
                System.debug('## Change status for invoice: ' + newInvoice.Id);
                if(newInvoice.cancellationDate__c != null || newInvoice.cancelledAmount__c >= newInvoice.amount__c) {
                    System.debug('## status 1');
                    newInvoice.status__c = Constants.INVOICE_ANNULEE;
                    newInvoice.stageName__c = null;
                } else if(newInvoice.paymentDate__c != null) {
                    System.debug('## status 2');
                    newInvoice.status__c = Constants.INVOICE_ACQUITTEE;
                    newInvoice.stageName__c = 'Terminé';
                } else if(Date.today() > newInvoice.dueDate__c && newInvoice.dueDate__c != null) {
                    System.debug('## status 3');
                    newInvoice.status__c = Constants.INVOICE_RETARD_PAIEMENT;
                    newInvoice.stageName__c = 'Recouvrement';
                } else if (newInvoice.publishedDate__c != null) {
                    System.debug('## status 4');
                    newInvoice.status__c = Constants.INVOICE_EMISE;
                    newInvoice.stageName__c = 'Recouvrement';
                } else if (newInvoice.invoiceDate__c != null) {
                    System.debug('## status 5');
                    newInvoice.status__c = Constants.INVOICE_GENEREE;
                    newInvoice.stageName__c = 'Recouvrement';
                } else {
                    System.debug('## status 6');
                    newInvoice.status__c = Constants.INVOICE_BROUILLON;
                    newInvoice.stageName__c = 'Préparation';
                }
            }  
            System.debug('## Invoice Status: '+newInvoice.status__c);
        }
        System.debug('### FIN TR020_Invoice : applyStatusUpdateRules');
    }

    /**
    * @description Règle de mise à jour des acomptes sur les factures
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyAdvancePaymentUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Invoice : applyAdvancePaymentUpdateRules');
        
        // A - Initialisation des données intermédiaires **/
        List<Invoice__c> newInvoices = new List<Invoice__c>();
        List<AccountingPiece__c> apList = new List<AccountingPiece__c>();
        List<CreditMemo__c> cmList = new List<CreditMemo__c>();
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        List<Id> orderIdsList = new List<Id>();

        for (Invoice__c newInvoice : (List<Invoice__c>)Trigger.new) {
            // Récupère seulement les factures (pas les factures d'acompte)
            if(newInvoice.isLegacy__c == false && newInvoice.RecordTypeId == RT_INVOICE) {
                if(String.isNotBlank(newInvoice.customerOrder__c)) {
                    orderIdsList.add(newInvoice.customerOrder__c);
                }
                newInvoices.add(newInvoice);
            }
        }

        if(!orderIdsList.isEmpty()) {
            apList = [SELECT Id, invoice__c, order__c, status__c, accountingDate__c, amount__c FROM AccountingPiece__c 
                                WHERE RecordTypeId = :RT_AP_RECEIPT 
                                    AND order__c IN :orderIdsList
                                    AND status__c = :Constants.ACCOUNTINGPIECE_STATUS_COUNTED
                                    AND invoice__c = null 
                                    AND accountingDate__c != null];
            
            cmList = [SELECT Id, creditMemoDate__c, amount__c, customerOrder__c FROM CreditMemo__c 
                                WHERE customerOrder__c IN :orderIdsList
                                    AND creditMemoDate__c != null AND cancellationDate__c = null AND invoice__c = null];

            invoiceList = [SELECT Id, advancePaymentAmount__c, creditMemoAmount__c, invoiceReference__c, customerOrder__c FROM Invoice__c 
                                    WHERE customerOrder__c IN :orderIdsList
                                        AND RecordTypeId = :RT_INVOICE
                                        AND invoiceDate__c != null AND cancellationDate__c = null];
        }
        
        // B - Application des règles de mise à jour **/
        for (Invoice__c newInvoice : newInvoices) {
            if(newInvoice.amount__c != null) {
                System.debug('## Invoice Id: '+newInvoice.Id);

                // Calcul du montant acompte total
                Decimal montantAcompteTotal = 0;
                if(!apList.isEmpty()){
                    for(AccountingPiece__c ap : apList){
                        if(ap.order__c == newInvoice.customerOrder__c && ap.accountingDate__c <= newInvoice.invoiceDate__c){
                            montantAcompteTotal = montantAcompteTotal+ap.amount__c;
                        }
                    }
                }
                System.debug('## Invoice montantAcompteTotal: '+montantAcompteTotal);

                // Calcul du montant acompte déjà utilisé
                Decimal montantAcompteDejaUtilise = 0;
                if(!invoiceList.isEmpty()){
                    for(Invoice__c inv : invoiceList){
                        if(inv.customerOrder__c == newInvoice.customerOrder__c && inv.invoiceReference__c < newInvoice.invoiceReference__c){
                            montantAcompteDejaUtilise = (inv.advancePaymentAmount__c == null) ? montantAcompteDejaUtilise : montantAcompteDejaUtilise+inv.advancePaymentAmount__c;
                        } 
                    }
                }
                System.debug('## Invoice montantAcompteDejaUtilise: '+montantAcompteDejaUtilise);

                // Calcul du montant acompte disponible
                Decimal montantAcompteDisponible = montantAcompteTotal - montantAcompteDejaUtilise;
                System.debug('## Invoice montantAcompteDisponible: '+montantAcompteDisponible);

                // Alimentation de l'acompte / Montant acompte utilisé 
                newInvoice.advancePaymentAmount__c = Math.min(newInvoice.amount__c, montantAcompteDisponible);
                newInvoice.advancePaymentAmount__c = (newInvoice.advancePaymentAmount__c != null) ? newInvoice.advancePaymentAmount__c.setScale(2) : null;

                // Calcul du montant avoir total
                Decimal montantAvoirTotal = 0;
                if(!apList.isEmpty()){
                    for(CreditMemo__c cm : cmList){
                        if(cm.customerOrder__c == newInvoice.customerOrder__c && cm.creditMemoDate__c <= newInvoice.invoiceDate__c){
                            montantAvoirTotal = montantAvoirTotal+cm.amount__c;
                        }   
                    }
                }
                System.debug('## Invoice montantAvoirTotal: '+montantAvoirTotal);
    
                // Calcul du montant avoir déjà utilisé
                Decimal montantAvoirDejaUtilise = 0;
                if(!invoiceList.isEmpty()){
                    for(Invoice__c inv : invoiceList){
                        if(inv.customerOrder__c == newInvoice.customerOrder__c && inv.invoiceReference__c < newInvoice.invoiceReference__c){
                            montantAvoirDejaUtilise = (inv.creditMemoAmount__c == null) ? montantAvoirDejaUtilise : montantAvoirDejaUtilise+inv.creditMemoAmount__c;
                        } 
                    }
                }
                System.debug('## Invoice montantAvoirDejaUtilise: '+montantAvoirDejaUtilise);
    
                // Calcul du montant avoir disponible
                Decimal montantAvoirDisponible = montantAvoirTotal - montantAvoirDejaUtilise;
                System.debug('## Invoice montantAvoirDisponible: '+montantAvoirDisponible);

                // Alimentation de l'avoir /  du montant avoir utilisé
                newInvoice.creditMemoAmount__c = Math.min(newInvoice.amount__c - newInvoice.advancePaymentAmount__c, montantAvoirDisponible);
                newInvoice.creditMemoAmount__c = (newInvoice.creditMemoAmount__c != null) ? newInvoice.creditMemoAmount__c.setScale(2) : null;

                // Alimentation du montant à percevoir
                newInvoice.toPerceiveAmount__c = newInvoice.amount__c - newInvoice.advancePaymentAmount__c - newInvoice.creditMemoAmount__c;
                newInvoice.toPerceiveAmount__c = (newInvoice.toPerceiveAmount__c != null) ? newInvoice.toPerceiveAmount__c.setScale(2) : null;

                System.debug('## Invoice advancePaymentAmount__c: '+newInvoice.advancePaymentAmount__c);
                System.debug('## Invoice creditMemoAmount__c: '+newInvoice.creditMemoAmount__c);
                System.debug('## Invoice toPerceiveAmount__c: '+newInvoice.toPerceiveAmount__c);
            }
        }
        
        System.debug('### FIN TR020_Invoice : applyAdvancePaymentUpdateRules');
    }
    
    /**
    * @description Méthode récurive permettant de vérifier l'entité parente (celle en premier de la hiearchie)
    * @param entityId Id de l'entité
    * @param entityHierarchieMap Objet contenant la hiéarchie des entités
    * @return Account Entité parente
    */
    private static Account calculateHeadOffice(String entityId, Map<String, Account> entityHierarchieMap) {
        Account entity = entityHierarchieMap.get(entityId);
        System.debug('## Recherche par l\'entité parente: '+entity); 
        if(entity == null || String.isBlank(entity.ParentId)) {
            System.debug('## Entité parente: '+entity);
            return entity;
        } else {
            // Sinon on effectue une récursivité sur l'entité
            return calculateHeadOffice(entity.ParentId, entityHierarchieMap);
        } 
    }

    /**
    * @description Méthode permettant de construire la hiéarchie des entités
    * @return Map<String, Account> Retourne une map des entités : Key = Id entité, valeur = entité
    */
    public static Map<String, Account> getEntityHierarchy() {
        Map<String, Account> result = new Map<String, Account>();
        String rtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account acc : [SELECT Id, Name, ParentId, rue__c, codePostal__c, ville__c, departement__c, pays__c, Ownership, complementAdresse__c,
                                emailPro__c, Phone, SIRET__c, shareCapital__c, SIREN__c, RCSNumber__c, RCSCity__c, intracommunityVATNumber__c,
                                entityType__r.KparKReference__c, email__c, KparKReference__c 
                            FROM Account WHERE RecordTypeId = :rtId]) {
            result.put(acc.Id, acc);
        }
        return result;
    }
}