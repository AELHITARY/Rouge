//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Invoice
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/01/2023
//-- Version     : 1.0
//-- 
//-- -------------------------------------------------------------------------------------- --
public class TR022_Invoice {
        
    /**
    * @description Méthode pour mettre à jour les actifs
    * @param userContext contexte utilisateur
    */
    /*
    public static void updateAssetAfterGeneration(UserContext userContext) {
        
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap; 
        List<String> invIds = new List<String>();
        Map<String,List<InvoiceLine__c>> invLineMap = new Map<String,List<InvoiceLine__c>>();
        for(Invoice__c inv : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(inv.id);
            if(oldInvoice.status__c != inv.status__c && inv.status__c == 'Générée')
                invIds.add(inv.Id);
        }
        Invoice__c inv = [SELECT Id, billAccount__c, billAccount__r.IsPersonAccount, billAccount__r.PersonContactId, issueDate__c,
                            billAccount__r.contactParDefaut__c, billAccount__r.contactParDefaut__r.Salutation, billAccount__r.contactParDefaut__r.LastName,
                            billAccount__r.contactParDefaut__r.FirstName, billAccount__r.Salutation, billAccount__r.LastName, billAccount__r.FirstName 
                            FROM Invoice__c WHERE Id = :recordId];
        //Get invoiceLine
        if(invIds.isEmpty()) {
            for (Invoice__c inv : newInvoices) {
                List<InvoiceLine__c> invLineList = new List<InvoiceLine__c>();
                for (InvoiceLine__c invL : invLineList) {
                    if(invL.invoice__c == inv.Id) invLineList.add(invL);
                }
                invLineMap.put(inv.Id, invLineList);
            }
            
            List<String> assetIds = new List<String>();
            //List<InvoiceLine__c> invLines = [SELECT Id, asset__c FROM InvoiceLine__c WHERE invoice__c =: invIds];
            List<Asset> assets = new List<Asset>();
            List<Asset> assetsToUpdate = new List<Asset>();
            for(Invoice__c inv : newInvoices) {
                List<InvoiceLine__c> invLines = invLineMap.get(inv.id);
                for(InvoiceLine__c invLine : invLines) {
                    assetIds.add(invLine.asset__c);
                }
            }
            if(!assetIds.isEmpty()) {
                assets = [SELECT Id, invoiceDate__c FROM Asset WHERE Id IN:assetIds];
            }
            if(!assets.isEmpty()) {
                for(Asset asst : assets) {
                    asst.invoiceDate__c = Date.Today();
                    assetsToUpdate.add(asst);
                }
            }
            
            if(!assetIds.isEmpty()) {
                update assetsToUpdate;
            }
        }
    }
    */

    /**
    * @description Méthode pour mettre à jour le montant sur les commandes lorsqu'une facture est validée (comptabilisée)
    * @param userContext contexte utilisateur
    */
    public static void updateOrderAfterValidation(UserContext userContext) {
        System.debug('### DEBUT TR022_Invoice.updateOrderAfterValidation');
        
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap; 
        List<String> customerOrderIds = new List<String>();
        List<Order> customerOrdertoUp = new List<Order>();

        for(Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id);
            // Récupération facture comptabilisées
            if(Trigger.isUpdate && oldInvoice != null && String.isNotBlank(newInvoice.invoiceReference__c) 
                && String.isNotBlank(newInvoice.customerOrder__c)
                /*&& (oldInvoice.invoiceReference__c != newInvoice.invoiceReference__c || oldInvoice.status__c != newInvoice.status__c)*/
                //#1269 - Conditions de déclenchement modifié pour se déclencher uniquement à la modif du Montant et Référence de la facture
                && oldInvoice.invoiceReference__c != newInvoice.invoiceReference__c
            ) {
                System.debug('## Invoice Id: '+newInvoice.Id);
                customerOrderIds.add(newInvoice.customerOrder__c);
            }
        }

        // Somme du montant des factures des commandes
        if(!customerOrderIds.isEmpty()) {
            for (AggregateResult result : [SELECT customerOrder__c, SUM(amount__c) totalAmount FROM Invoice__c 
                                                WHERE customerOrder__c IN :customerOrderIds AND invoiceReference__c != null
                                                GROUP BY customerOrder__c]) {
                System.debug('## MAJ Order Id: '+result.get('customerOrder__c'));
                System.debug('## Total Amount: '+result.get('totalAmount'));
                // Mise à jour de la commande
                customerOrdertoUp.add(new Order(
                    Id = (String)result.get('customerOrder__c'),
                    invoicesAmount__c = (Decimal)result.get('totalAmount') 
                ));
            }

            if(!customerOrdertoUp.isEmpty()) {
                update customerOrdertoUp;
            }
        }

        System.debug('### FIN TR022_Invoice.updateOrderAfterValidation');
    }
        
    /**
    * @description Méthode pour mettre à jour le montant sur les comptes lorsqu'un avoir est validé (comptabilisé)
    * @param userContext contexte utilisateur
    */
    public static void updateAccountAfterValidation(UserContext userContext) {
        System.debug('### DEBUT TR022_Invoice.updateAccountAfterValidation');
        
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap; 
        List<String> accountIds = new List<String>();
        List<Account> accountToUp = new List<Account>();

        for(Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id);
            // Récupération facture comptabilisées
            if(Trigger.isUpdate && oldInvoice != null && String.isNotBlank(newInvoice.invoiceReference__c) 
                && String.isNotBlank(newInvoice.billingaccount__c)
                //&& (oldInvoice.invoiceReference__c != newInvoice.invoiceReference__c || oldInvoice.status__c != newInvoice.status__c)
                //#1269 - Conditions de déclenchement modifié pour se déclencher uniquement à la modif de la référence de l'avoir 
                && oldInvoice.invoiceReference__c != newInvoice.invoiceReference__c
            ) {
                System.debug('## Invoice Id: '+newInvoice.Id);
                accountIds.add(newInvoice.billingaccount__c);
            }
        }

        // Somme du montant des factures des comptes
        if(!accountIds.isEmpty()) {
            for (AggregateResult result : [SELECT billingaccount__c, SUM(amount__c) totalAmount FROM Invoice__c 
                                                WHERE billingaccount__c IN :accountIds AND invoiceReference__c != null
                                                GROUP BY billingaccount__c]) {
                System.debug('## MAJ Account Id: '+result.get('billingaccount__c'));
                System.debug('## Total Amount: '+result.get('totalAmount'));
                // Mise à jour du compte
                accountToUp.add(new Account(
                    Id = (String)result.get('billingaccount__c'),
                    invoicesAmount__c = (Decimal)result.get('totalAmount') 
                ));
            }

            if(!accountToUp.isEmpty()) {
                update accountToUp;
            }
        }
        System.debug('### FIN TR022_Invoice.updateAccountAfterValidation');
    }
 
    /**
    * @description Méthode pour exécuter la classe QA_KMDCEinstein
    * @param userContext contexte utilisateur
    */
    public static void scheduleKMDCEinstein(UserContext userContext) {
        System.debug('### DEBUT TR022_Invoice.scheduleKMDCEinstein');
        
        List<Invoice__c> newInvoices = (List<Invoice__c>)Trigger.new;
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>)Trigger.oldMap; 
        List<Invoice__c> invToUpdate = new List<Invoice__c>();

        for(Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoices == null ? null : oldInvoices.get(newInvoice.id);
            // Récupération facture comptabilisées
            if(Trigger.isUpdate && oldInvoice != null && String.isNotBlank(newInvoice.invoiceReference__c) && 
                (oldInvoice.invoiceDate__c != newInvoice.invoiceDate__c 
                    || oldInvoice.pretaxAmount__c != newInvoice.pretaxAmount__c 
                    || oldInvoice.amount__c != newInvoice.amount__c 
                )
            ) {
                System.debug('## Invoice Id: '+newInvoice.Id);
                invToUpdate.add(newInvoice);
            }
        }

        if(!invToUpdate.isEmpty()) {
            System.enqueueJob(new QA_KMDCEinstein('Invoice', invToUpdate, null, null)); // Alimentation KMDC pour einstein
        }
        System.debug('### FIN TR022_Invoice.scheduleKMDCEinstein');
    }
}