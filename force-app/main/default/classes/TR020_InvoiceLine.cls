//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_InvoiceLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 31/01/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_InvoiceLine {
    
    /**
    * @description Méthode exécutant les règles de validation pour les lignes de facture
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_InvoiceLine.applyValidationRules');
        
        List<InvoiceLine__c> oldInvoiceLines = (List<InvoiceLine__c>)Trigger.old;
        for(InvoiceLine__c oldInvoiceLine : oldInvoiceLines){
            // Ne pas supprimer si la commande est verrouillée
            if(oldInvoiceLine.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore) {
                System.debug('## oldInvoiceLine.isOrderLocked__c : ' + oldInvoiceLine.isOrderLocked__c);
                oldInvoiceLine.addError(Label.order_msg_cantDeleteInvoiceLine);
            } 
        }
        
        System.debug('### FIN TR020_InvoiceLine.applyValidationRules');
    }

    /**
    * @description Méthode pour interdire la suppression d'une ligne de facture pour 10 ans si elle a une numéro fiscal. Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotDeleteInvoiceLine(UserContext userContext) {
        System.debug('### DEBUT TR020_InvoiceLine.cannotDeleteInvoice');
        
        List<InvoiceLine__c> oldInvoiceLines = (List<InvoiceLine__c>)Trigger.old;
        for(InvoiceLine__c oldInvoiceLine : oldInvoiceLines){
            if(oldInvoiceLine.isInvoiceLocked__c && Trigger.isDelete && Trigger.isBefore) {
                oldInvoiceLine.addError(Label.invoice_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_InvoiceLine.cannotDeleteInvoice');
    }

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
          
        System.debug('### DEBUT TR020_InvoiceLine.applyUpdateRules');
        List<InvoiceLine__c> newInvoiceLines = (List<InvoiceLine__c>)Trigger.new;  
        Map<Id, InvoiceLine__c> oldInvoiceLines = (Map<Id, InvoiceLine__c>)Trigger.oldMap;
        List<String> orderItemIds = new List<String>();  
        List<String> assetIds = new List<String>();  
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();  
        Map<Id, Asset> assetMap = new Map<Id, Asset>(); 
        Decimal invoiceAmount = 0;       
        Decimal totalAdvAmountLines = 0;

        //** A - Initialisation des données intermédiaires
        for (InvoiceLine__c newInvoiceLine : newInvoiceLines) {
            InvoiceLine__c oldInvoiceLine = oldInvoiceLines == null ? null : oldInvoiceLines.get(newInvoiceLine.id); 
            
            // Ligne de commande
            if ((Trigger.isInsert || (Trigger.isUpdate && oldInvoiceLine.orderItem__c != newInvoiceLine.orderItem__c)) 
                    && String.isNotBlank(newInvoiceLine.orderItem__c) && String.isBlank(newInvoiceLine.legacyReference__c)) 
            {
                orderItemIds.add(newInvoiceLine.orderItem__c);
            }
            // Asset
            if ((Trigger.isInsert || (Trigger.isUpdate && oldInvoiceLine.asset__c != newInvoiceLine.asset__c )) 
                    && String.isNotBlank(newInvoiceLine.asset__c) && String.isBlank(newInvoiceLine.legacyReference__c)) 
            {
                assetIds.add(newInvoiceLine.asset__c);
            }
        }

        // Récupération des enregistrements d'objets associés
        if(!orderItemIds.isEmpty()) {
            orderItemMap = new Map<Id, OrderItem>([SELECT Id, Product2Id, name__c, Quantity, discount__c, ListPrice, orderEffectiveDate__c, VATAmount__c,
                                                    unit__c, VATRate__c, UnitPrice, amount__c, pretaxAmount__c, thermalCoefficients__c FROM OrderItem 
                                                   WHERE id IN :orderItemIds]);
            System.debug('## orderItemMap: '+orderItemMap ); 
            for(Asset ast : [SELECT Id, orderItem__c, installResource__c, installResourceCertification__c, installResource__r.user__r.Name, 
                                controlResource__c, controlResourceCertification__c, controlResource__r.user__r.Name, Quantity, locationFormula__c
                                FROM Asset WHERE orderItem__c IN :orderItemIds AND Status != :Constants.ASSET_STATUS_ANNULE]) {
                assetMap.put(ast.orderItem__c, ast);
            }
            System.debug('## assetMap: '+assetMap ); 
        }  
        if(!assetIds .isEmpty()) { 
            for(Asset ast : [SELECT Id, installResource__c, installResourceCertification__c, installResource__r.user__r.Name, 
                                controlResource__c, controlResourceCertification__c, controlResource__r.user__r.Name, Quantity, locationFormula__c
                                FROM Asset WHERE Id IN :assetIds AND Status != :Constants.ASSET_STATUS_ANNULE]) {
                assetMap.put(ast.Id, ast);
            }
            System.debug('## assetMap: '+assetMap ); 
        }       
                           
        //** B - Application des règles de mise à jour **/ 
        for (InvoiceLine__c newInvoiceLine : newInvoiceLines) {
            System.debug('## ------- Id: '+newInvoiceLine.Id); 
            System.debug('## OrderItem: '+newInvoiceLine.orderItem__c);  
            System.debug('## Asset: '+newInvoiceLine.asset__c);  
        
            // MAJ Autre champs si pas ligne legacy
            if (String.isBlank(newInvoiceLine.legacyReference__c)) {
                OrderItem ordItem = orderItemMap.get(newInvoiceLine.orderItem__c);
                // MAJ des informations par rapport à la ligne de commande            
                if (String.isNotBlank(newInvoiceLine.orderItem__c) && ordItem != null) {
                    System.debug('## MAJ des informations ligne de commande: '+ordItem); 
                    newInvoiceLine.product__c = ordItem.Product2Id;
                    newInvoiceLine.unit__c = ordItem.unit__c;
                    newInvoiceLine.label__c = ordItem.name__c;
                    newInvoiceLine.VATRate__c = ordItem.VATRate__c;
                    newInvoiceLine.VATEffectiveDate__c = ordItem.orderEffectiveDate__c;   
                    newInvoiceLine.quantity__c = ordItem.Quantity;
                    newInvoiceLine.listPrice__c = ordItem.ListPrice;
                    newInvoiceLine.thermalCoefficients__c = ordItem.thermalCoefficients__c;
                }
                // MAJ de l'actif selon la ligne de commande
                if (String.isNotBlank(newInvoiceLine.orderItem__c) && assetMap.get(newInvoiceLine.orderItem__c) != null) {
                    Asset ast = assetMap.get(newInvoiceLine.orderItem__c);
                    if(newInvoiceLine.asset__c == null) {
                        newInvoiceLine.asset__c = ast.Id;
                    }
                    newInvoiceLine.quantity__c = ast.Quantity;
                    newInvoiceLine.location__c = ast.locationFormula__c;
                    newInvoiceLine.installResource__c = ast.installResource__c;
                    newInvoiceLine.installResourceCertification__c = ast.installResourceCertification__c;
                    newInvoiceLine.installResourceName__c = ast.installResource__r.user__r.Name;
                    newInvoiceLine.controlResource__c = ast.controlResource__c;
                    newInvoiceLine.controlResourceCertification__c = ast.controlResourceCertification__c;
                    newInvoiceLine.controlResourceName__c = ast.controlResource__r.user__r.Name;
                    System.debug('## MAJ Asset (OrderItem): '+ast);
                }
                // MAJ infos si changement actif
                if (String.isNotBlank(newInvoiceLine.asset__c) && assetMap.get(newInvoiceLine.asset__c) != null) {
                    Asset ast = assetMap.get(newInvoiceLine.asset__c);
                    newInvoiceLine.quantity__c = ast.Quantity;
                    newInvoiceLine.location__c = ast.locationFormula__c;
                    newInvoiceLine.installResource__c = ast.installResource__c;
                    newInvoiceLine.installResourceCertification__c = ast.installResourceCertification__c;
                    newInvoiceLine.installResourceName__c = ast.installResource__r.user__r.Name;
                    newInvoiceLine.controlResource__c = ast.controlResource__c;
                    newInvoiceLine.controlResourceCertification__c = ast.controlResourceCertification__c;
                    newInvoiceLine.controlResourceName__c = ast.controlResource__r.user__r.Name;
                    System.debug('## MAJ infos Asset: '+ast);
                }

                // Calcul prix selon la quantité de la ligne. Si 1, alors on prendre les montants de la ligne, sinon on divise selon quantité
                if (ordItem != null && (ordItem.Quantity == 1 || ordItem.unit__c != 'UNIT')) {
                    System.debug('## MAJ Prix Quantité = 1: '+ordItem); 
                    newInvoiceLine.unitPrice__c = (ordItem.UnitPrice == null) ? 0 : ordItem.UnitPrice;
                    Decimal ordPriceReduction = (ordItem.discount__c == null) ? 0 : (ordItem.discount__c);
                    newInvoiceLine.priceReduction__c = (ordPriceReduction > 0) ? - ordPriceReduction : ordPriceReduction;
                    // Montant total
                    newInvoiceLine.amount__c = (ordItem.amount__c == null) ? 0 : ordItem.amount__c;
                    newInvoiceLine.VATAmount__c = (ordItem.VATAmount__c == null) ? null : ordItem.VATAmount__c;
                    newInvoiceLine.pretaxAmount__c = (ordItem.pretaxAmount__c == null) ? 0 : ordItem.pretaxAmount__c;
                    System.debug('## MAJ PretaxAmount: '+newInvoiceLine.pretaxAmount__c);
                    System.debug('## MAJ VATAmount: '+newInvoiceLine.VATAmount__c);
                    System.debug('## MAJ Amount: '+newInvoiceLine.amount__c);
                } else if (ordItem != null && ordItem.Quantity > 1) {
                    System.debug('## MAJ Prix Quantité > 1: '+ordItem); 
                    newInvoiceLine.unitPrice__c = (ordItem.UnitPrice == null) ? 0 : ordItem.UnitPrice;
                    Decimal ordPriceReduction = (ordItem.discount__c == null) ? 0 : (ordItem.discount__c / ordItem.Quantity);
                    newInvoiceLine.priceReduction__c = (ordPriceReduction > 0) ? - ordPriceReduction : ordPriceReduction;
                    // Montant total
                    /*Decimal pretaxAmount = (newInvoiceLine.unitPrice__c == null || newInvoiceLine.quantity__c == null) ? 
                                            0 : 
                                            (newInvoiceLine.unitPrice__c + newInvoiceLine.priceReduction__c) * newInvoiceLine.quantity__c;
                    newInvoiceLine.pretaxAmount__c = pretaxAmount.setScale(2);
                    System.debug('## MAJ PretaxAmount: '+newInvoiceLine.pretaxAmount__c);
                    Decimal vatAmount = (newInvoiceLine.pretaxAmount__c == null || newInvoiceLine.VATRate__c == null) ? 
                                            0 : 
                                            newInvoiceLine.pretaxAmount__c * newInvoiceLine.VATRate__c;
                    newInvoiceLine.VATAmount__c = (vatAmount == null) ? null : (vatAmount / 100).setScale(2);
                    System.debug('## MAJ VATAmount: '+newInvoiceLine.VATAmount__c);
                    newInvoiceLine.amount__c = (newInvoiceLine.pretaxAmount__c == null || newInvoiceLine.VATAmount__c == null) ? 
                                            0 : 
                                            (newInvoiceLine.pretaxAmount__c + newInvoiceLine.VATAmount__c).setScale(2);
                    System.debug('## MAJ Amount: '+newInvoiceLine.amount__c);*/
                    newInvoiceLine.amount__c = (ordItem.amount__c == null) ? 0 : (ordItem.amount__c / ordItem.Quantity).setScale(2);
                    newInvoiceLine.VATAmount__c = (ordItem.VATAmount__c == null) ? null : (ordItem.VATAmount__c / ordItem.Quantity).setScale(2);
                    newInvoiceLine.pretaxAmount__c = (ordItem.pretaxAmount__c == null) ? 0 : (ordItem.pretaxAmount__c / ordItem.Quantity).setScale(2);
                    System.debug('## MAJ PretaxAmount: '+newInvoiceLine.pretaxAmount__c);
                    System.debug('## MAJ VATAmount: '+newInvoiceLine.VATAmount__c);
                    System.debug('## MAJ Amount: '+newInvoiceLine.amount__c);
                }

                // Traitement spécifique pour les factures d'acompte. On calcule les montants selon le pourcentage de la commande (pas de facture total)
                if(newInvoiceLine.invoiceRecordType__c == Constants.INVOICE_ADVANCEINVOICE_RT && newInvoiceLine.invoicePercentOrderAmount__c != null) {
                    invoiceAmount = newInvoiceLine.invoiceAmount__c; // Total TTC de la facture
                    System.debug('## Advance InvoicePercentOrderAmount: '+newInvoiceLine.invoicePercentOrderAmount__c);
                    Decimal pretaxAmountAdv = (newInvoiceLine.pretaxAmount__c == null) ? 0 : (newInvoiceLine.pretaxAmount__c * newInvoiceLine.invoicePercentOrderAmount__c) / 100;
                    newInvoiceLine.pretaxAmount__c = pretaxAmountAdv.setScale(2);
                    System.debug('## MAJ Advance PretaxAmount: '+newInvoiceLine.pretaxAmount__c);
                    Decimal amountAdv = (newInvoiceLine.amount__c == null) ? 0 : (newInvoiceLine.amount__c * newInvoiceLine.invoicePercentOrderAmount__c) / 100;
                    newInvoiceLine.amount__c = amountAdv.setScale(2);
                    totalAdvAmountLines = totalAdvAmountLines + newInvoiceLine.amount__c;
                    System.debug('## MAJ Advance Amount: '+newInvoiceLine.amount__c);
                    newInvoiceLine.VATAmount__c = (newInvoiceLine.amount__c - newInvoiceLine.pretaxAmount__c).setScale(2);      
                    System.debug('## MAJ Advance VATAmount: '+newInvoiceLine.VATAmount__c);
                }
            }

            // Autre
            if(String.isBlank(newInvoiceLine.parentLine__c)) {
                newInvoiceLine.isParentLine__c = true;
            } else {
                newInvoiceLine.isParentLine__c = false;
            }
        }

        // Recalcul le montant des lignes pour les lignes de facture d'acompte afin que le montant soit égal à la facture
        if(totalAdvAmountLines != 0 && invoiceAmount != 0 && invoiceAmount != totalAdvAmountLines) {
            Decimal diffAmount = invoiceAmount - totalAdvAmountLines;
            System.debug('## Adjust Advance Amount: '+invoiceAmount+' / '+totalAdvAmountLines+' / '+diffAmount);
            for (InvoiceLine__c newInvoiceLine : newInvoiceLines) {
                // Mise à jour montant ligne parent
                if(newInvoiceLine.invoiceRecordType__c == Constants.INVOICE_ADVANCEINVOICE_RT && newInvoiceLine.isParentLine__c 
                    && invoiceAmount != totalAdvAmountLines && newInvoiceLine.amount__c != 0) 
                {
                    totalAdvAmountLines = totalAdvAmountLines + diffAmount;
                    newInvoiceLine.amount__c = newInvoiceLine.amount__c + diffAmount;
                    newInvoiceLine.VATAmount__c = newInvoiceLine.VATAmount__c + diffAmount;
                    newInvoiceLine.pretaxAmount__c = newInvoiceLine.pretaxAmount__c + diffAmount;
                    System.debug('## Modify line: '+newInvoiceLine.asset__c+' / '+newInvoiceLine.orderItem__c+' / '+newInvoiceLine.label__c+' / '+newInvoiceLine.amount__c);
                }
            }
        }
        System.debug('### FIN TR020_InvoiceLine.applyUpdateRules');
    }
}