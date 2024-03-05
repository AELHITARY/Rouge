//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_InvoiceLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/11/2022
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_InvoiceLine {
    private static final Id RT_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT);
    
    /**
    * @description Méthode pour calculer le montant et les taux TVA sur la facture selon les infos des lignes
    * @param userContext Contexte utilisateur
    */
    public static void calculateVATAmount(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        System.debug('### DEBUT TR022_InvoiceLine.calculateVATAmount');
        
        Map<Id, InvoiceLine__c> oldInvoiceLines = (Map<Id, InvoiceLine__c>)Trigger.oldMap;
        List<InvoiceLine__c> newInvoiceLines = (List<InvoiceLine__c>)Trigger.new;  
        List<InvoiceLine__c> invoiceLinesList = new List<InvoiceLine__c>();  
        List<String> invoicesIds = new List<String>();  
        Map<String, List<InvoiceLine__c>> invoiceLinesMap = new Map<String, List<InvoiceLine__c>>();
        List<Invoice__c> invoiceToUpdate = new List<Invoice__c>();  
        List<String> linesDeleted = new List<String>();  

        // Selon le type d'exécution, récupération des lignes
        if(Trigger.isDelete) {
            invoiceLinesList = oldInvoiceLines.values();
        } else {
            invoiceLinesList = newInvoiceLines;
        }

        // SOQL - Récupération des factures à mettre à jour
        for(InvoiceLine__c invLine : invoiceLinesList){
            InvoiceLine__c oldInvoiceLine = oldInvoiceLines == null ? null : oldInvoiceLines.get(invLine.id); 
            // Seulement pour les lignes liées à des facture et non historique
            if(String.isNotBlank(invLine.invoice__c) && String.isBlank(invLine.legacyReference__c) && invLine.autoComputedAmount__c &&
                (Trigger.isInsert || Trigger.isDelete || Trigger.isUpdate)
            ) {
                System.debug('## Invoice Id: ' + invLine.invoice__c);
                invoicesIds.add(invLine.invoice__c);
                // Si ligne supprimée, on stocke son ID pour ne pas prendre en compte dans le calcul
                if(Trigger.isDelete) {
                    linesDeleted.add(invLine.Id);
                }
            }  
        }
        
        // Pour chaque factures, récupération des lignes
        if(!invoicesIds.isEmpty()) {
            List<InvoiceLine__c> invLinesList;
            for(InvoiceLine__c line : [SELECT Id, invoice__c, VATRate__c, VATAmount__c FROM InvoiceLine__c 
                                        WHERE invoice__c IN :invoicesIds AND parentLine__c = null AND Id NOT IN :linesDeleted]) {
                // Construction d'une MAP de lignes par factures
                String key = line.invoice__c;
                if(invoiceLinesMap.get(key) == null) {
                    invLinesList = new List<InvoiceLine__c>();
                } else {
                    invLinesList = invoiceLinesMap.get(key);
                }
                invLinesList.add(line);
                invoiceLinesMap.put(key, invLinesList);
            }
            System.debug('## invoiceLinesMap: ' + invoiceLinesMap);
    
            // Pour chaque factures, calcul du montant TVA selon les lignes
            for(String invoiceId : invoiceLinesMap.keySet()) {
                System.debug('## Calultate for invoice Id: ' + invoiceId);
                System.debug('## Lines: ' + invoiceLinesMap.get(invoiceId));
                Map<Decimal, Decimal> montantsTVA = new Map<Decimal, Decimal>();
                // Récupération des montants par taux
                for (InvoiceLine__c line : invoiceLinesMap.get(invoiceId)) {
                    System.debug('## Line: '+line.Id+' / '+line.VATRate__c+' / '+line.VATAmount__c);
                    Decimal montantTVA = montantsTVA.get(line.VATRate__c);
                    if (montantTVA == null) {
                        montantTVA = (line.VATAmount__c == null) ? 0 : line.VATAmount__c.setScale(2);
                    } else {
                        montantTVA += (line.VATAmount__c == null) ? 0 : line.VATAmount__c.setScale(2);
                    }
                    montantsTVA.put(line.VATRate__c, montantTVA);
                }
                // Mise à jour des champs de la facture selon le taux
                List<Decimal> vatRateList = new List<Decimal>(montantsTVA.keySet());
                System.debug('## VAT Rate: ' + vatRateList);
                if(vatRateList != null) {
                    // Création de l'objet facture avec Id existant
                    Invoice__c invoiceUp = new Invoice__c(Id = invoiceId, 
                                                            VATRate1__c=null, VATAmount1__c=null,
                                                            VATRate2__c=null, VATAmount2__c=null,
                                                            VATRate3__c=null, VATAmount3__c=null); 
                    // Mise à jour des champs de facture
                    vatRateList.sort();
                    if (vatRateList.size() >= 1) {
                        invoiceUp.VATRate1__c = vatRateList.get(0);
                        invoiceUp.VATAmount1__c = montantsTVA.get(vatRateList.get(0));
                    }
                    if (vatRateList.size() >= 2) {
                        invoiceUp.VATRate2__c = vatRateList.get(1);
                        invoiceUp.VATAmount2__c = montantsTVA.get(vatRateList.get(1));
                    }
                    if (vatRateList.size() >= 3) {
                        invoiceUp.VATRate3__c = vatRateList.get(2);
                        invoiceUp.VATAmount3__c = montantsTVA.get(vatRateList.get(2));
                    }
                    invoiceUp.VATAmount1__c = (invoiceUp.VATAmount1__c != null) ? invoiceUp.VATAmount1__c.setScale(2) : null;
                    invoiceUp.VATAmount2__c = (invoiceUp.VATAmount2__c != null) ? invoiceUp.VATAmount2__c.setScale(2) : null;
                    invoiceUp.VATAmount3__c = (invoiceUp.VATAmount3__c != null) ? invoiceUp.VATAmount3__c.setScale(2) : null;
                    System.debug('## Invoice to up: ' + invoiceUp.Id);
                    System.debug('## VATAmount1: ' + invoiceUp.VATAmount1__c);
                    System.debug('## VATAmount2: ' + invoiceUp.VATAmount2__c);
                    System.debug('## VATAmount3: ' + invoiceUp.VATAmount3__c);
                    invoiceToUpdate.add(invoiceUp);
                }
            }
        }

        if(!invoiceToUpdate.isEmpty()) {
            update invoiceToUpdate;
        }
        System.debug('### FIN TR022_InvoiceLine.calculateVATAmount');
    }

    /**
    * @description Mise à jour des numéros de ligne avant suppression d'une ligne
    * @param userContext Contexte utilisateur
    */
    public static void updateLinesNumberDelete(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_InvoiceLine.updateLinesNumberDelete');
        Map<Id, InvoiceLine__c> oldInvoiceLines = (Map<Id, InvoiceLine__c>)Trigger.oldMap;
        List<String> invoicesIds = new List<String>();  
        Decimal numDeleteLine=null;

        // Récupération des IDs des factures
        for (InvoiceLine__c invLines : oldInvoiceLines.values()) {
            if (String.isNotBlank(invLines.invoice__c) && String.isBlank(invLines.legacyReference__c) && 
                !AlreadyUsed.isUsed('TR022_InvoiceLine.updateLinesNumberDelete', invLines.invoice__c)) 
            {
                invoicesIds.add(invLines.invoice__c);
            }
        }
                
        if(!invoicesIds.isEmpty()) {
            // SOQL - SELECT - Liste de toutes les lignes des factures impactés
            List<InvoiceLine__c> invoiceLineBefore = [SELECT Id, invoice__c, lineNumber__c FROM InvoiceLine__c WHERE invoice__c IN :invoicesIds];
            for (String invoice : invoicesIds) {
                System.debug('## Invoice: ' + invoice);
                // Pour toutes les lignes supprimés, on décremente le compteur
                for (InvoiceLine__c line : oldInvoiceLines.values()) {
                    if(line.invoice__c == invoice) {
                        // Récupération du numéro de ligne supprimé
                        numDeleteLine = line.lineNumber__c;
                        System.debug('## Num Ligne supp: ' + numDeleteLine);
                    }
                }
                // Variables de stockage
                Decimal lastLineNumber = 0;
                // CRM-461 réajustement des numéros de ligne après suppression
                for (InvoiceLine__c lineBefore : invoiceLineBefore){
                    System.debug('## Supression ligne:' + numDeleteLine + ' ' + lineBefore.lineNumber__c);
                    if(lineBefore.lineNumber__c > numDeleteLine) {
                        // Mise à jour du champ
                        lastLineNumber = lineBefore.lineNumber__c - 1;
                        System.debug('## Num Format: ' + lastLineNumber);
                        lineBefore.lineNumber__c = lastLineNumber;
                    }
                }
            }

            if(!invoiceLineBefore.isEmpty()) {
                update invoiceLineBefore;
            }
        }
        System.debug('### FIN TR022_InvoiceLine.updateLinesNumberDelete');
    }

    /**
    * @description Mise à jour des numéros des lignes
    * @param userContext Contexte utilisateur
    */
    public static void updateLinesNumber(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_InvoiceLine.updateLinesNumber');
        List<InvoiceLine__c> newInvoiceLines = (List<InvoiceLine__c>)Trigger.new;  
        Set<String> invoicesIds = new Set<String>();  

        // Récupération des IDs des factures
        for (InvoiceLine__c invLines : newInvoiceLines) {
            if (String.isNotBlank(invLines.invoice__c) && String.isBlank(invLines.legacyReference__c) && invLines.lineNumber__c == null) 
            {
                invoicesIds.add(invLines.invoice__c);
            }
        }
        
        if(!invoicesIds.isEmpty()) {
            // SOQL - Récupération du nombre de lignes par factures
            Map<String, Integer> invoiceLineNumber = new Map<String, Integer>();
            for (AggregateResult nbLine : [SELECT invoice__c, COUNT(Id) total FROM InvoiceLine__c WHERE invoice__c IN :invoicesIds GROUP BY invoice__c]) {
                invoiceLineNumber.put((String)nbLine.get('invoice__c'), (Integer)nbLine.get('total'));
            }
            System.debug('## invoiceLineNumber: ' + invoiceLineNumber);

            // Mise à jour des champs
            for (String invoice: invoicesIds) {
                System.debug('## Invoice: ' + invoice);
                Integer lineNumber = (invoiceLineNumber.get(invoice) == null) ? 0 : invoiceLineNumber.get(invoice);
                System.debug('## Numero: ' + lineNumber);
                for(InvoiceLine__c line : newInvoiceLines) {
                    if (line.invoice__c == invoice) {
                        // Mise à jour du champ
                        lineNumber++;                        
                        System.debug('## Num Format: ' + lineNumber);
                        line.lineNumber__c = lineNumber;
                    }
                }
            }
        }
        System.debug('### FIN TR022_InvoiceLine.updateLinesNumber');
    }

    public static void calculateAmounts(UserContext userContext) {
        System.debug('### DEBUT TR022_InvoiceLine.calculateAmounts');
        List<InvoiceLine__c> newInvoiceLines = (List<InvoiceLine__c>)Trigger.new;  
        Set<String> invoicesIds = new Set<String>();  
        List<Invoice__c> invoiceListToUpdate = new List<Invoice__c>();

        // Récupération des IDs des factures
        for (InvoiceLine__c invLines : newInvoiceLines) {
            if (!AlreadyUsed.isUsed('TR022_InvoiceLine.calculateAmounts', invLines.Id) 
                && String.isNotBlank(invLines.invoice__c) && String.isBlank(invLines.legacyReference__c) 
                && invLines.invoiceRecordType__c == Constants.INVOICE_INVOICE_RT
            ) 
            {
                invoicesIds.add(invLines.invoice__c);
            }
        }

        if(!invoicesIds.isEmpty()) {
            // SOQL - SELECT - Liste de toutes les lignes des factures impactés
            List<InvoiceLine__c> invoiceLines = [SELECT Id, invoice__c, lineNumber__c, amount__c, pretaxAmount__c, priceReduction__c, listPrice__c, unitPrice__c
                                                    FROM InvoiceLine__c WHERE invoice__c IN :invoicesIds AND parentLine__c = null];
            List<Invoice__c> invoices = [SELECT Id, autoComputedAmount__c, amount__c, pretaxAmount__c, priceReduction__c, listAmount__c, RecordTypeId 
                                            FROM Invoice__c WHERE id IN :invoicesIds];
            // Mise à jour des montants de la facture (ROLL UP des lignes avec condition)
            for (Invoice__c invoice : invoices) {
                System.debug('## Invoice: ' + invoice);
                if(invoice.autoComputedAmount__c && invoice.RecordTypeId == RT_INVOICE){
                    Decimal amount = 0;
                    Decimal pretaxAmount = 0;
                    Decimal priceReduction = 0;
                    Decimal listPrice = 0;
                    for (InvoiceLine__c line : invoiceLines) {
                        if(line.invoice__c == invoice.Id) { 
                            amount = (line.amount__c == null) ? amount : amount + line.amount__c;
                            pretaxAmount = (line.pretaxAmount__c == null) ? pretaxAmount : pretaxAmount + line.pretaxAmount__c;
                            priceReduction = (line.priceReduction__c == null) ? priceReduction : priceReduction + line.priceReduction__c;
                            listPrice = (line.unitPrice__c == null) ? listPrice : listPrice + line.unitPrice__c;
                        }
                    }
                    invoice.amount__c = amount;
                    invoice.pretaxAmount__c = pretaxAmount;
                    invoice.priceReduction__c = priceReduction;
                    invoice.listAmount__c = listPrice;
                    invoice.amount__c = (invoice.amount__c != null) ? invoice.amount__c.setScale(2) : null;
                    invoice.pretaxAmount__c = (invoice.pretaxAmount__c != null) ? invoice.pretaxAmount__c.setScale(2) : null;
                    invoice.priceReduction__c = (invoice.priceReduction__c != null) ? invoice.priceReduction__c.setScale(2) : null;
                    invoice.listAmount__c = (invoice.listAmount__c != null) ? invoice.listAmount__c.setScale(2) : null;
                    invoiceListToUpdate.add(invoice);
                }
            }
        }

        if(!invoiceListToUpdate.isEmpty()) {
            update invoiceListToUpdate;
        }

        System.debug('### FIN TR022_InvoiceLine.calculateAmounts');
    }
}