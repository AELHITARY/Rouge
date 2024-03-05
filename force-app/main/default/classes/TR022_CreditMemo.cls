//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_CreditMemo
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/11/2022
//-- Version     : 1.0
//-- 
//-- -------------------------------------------------------------------------------------- --
public class TR022_CreditMemo {
        
    /**
    * @description Méthode pour mettre à jour le montant sur les commandes lorsqu'un avoir est validé (comptabilisé)
    * @param userContext contexte utilisateur
    */
    public static void updateOrderAfterValidation(UserContext userContext) {
        System.debug('### DEBUT TR022_CreditMemo.updateOrderAfterValidation');
        
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new;
        Map<Id, CreditMemo__c> oldCreditMemos = (Map<Id, CreditMemo__c>)Trigger.oldMap; 
        List<String> customerOrderIds = new List<String>();
        List<Order> customerOrdertoUp = new List<Order>();

        for(CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            // Récupération avoirs comptabilisées
            if(Trigger.isUpdate && oldCreditMemo != null && String.isNotBlank(newCreditMemo.creditMemoReference__c) 
                && String.isNotBlank(newCreditMemo.customerOrder__c)
                && (oldCreditMemo.creditMemoReference__c != newCreditMemo.creditMemoReference__c || oldCreditMemo.status__c != newCreditMemo.status__c)
            ) {
                System.debug('## CreditMemo Id: '+newCreditMemo.Id);
                customerOrderIds.add(newCreditMemo.customerOrder__c);
            }
        }

        // Somme du montant des avoirs des commandes
        if(!customerOrderIds.isEmpty()) {
            for (AggregateResult result : [SELECT customerOrder__c, SUM(amount__c) totalAmount FROM CreditMemo__c 
                                                WHERE customerOrder__c IN :customerOrderIds AND creditMemoReference__c != null 
                                                AND status__c != :Constants.CREDITMEMO_ANNULE
                                                GROUP BY customerOrder__c]) {
                System.debug('## MAJ Order Id: '+result.get('customerOrder__c'));
                System.debug('## Total Amount: '+result.get('totalAmount'));
                // Mise à jour de la commande
                customerOrdertoUp.add(new Order(
                    Id = (String)result.get('customerOrder__c'),
                    creditMemosAmount__c = (Decimal)result.get('totalAmount') 
                ));
            }

            for(String customerOrderId : customerOrderIds){
                Boolean amountCorrectlyCalculated = false;
                for(Order o : customerOrdertoUp){
                    if(o.Id == customerOrderId){
                        amountCorrectlyCalculated = true;
                    }
                }
                if(!amountCorrectlyCalculated){
                    customerOrdertoUp.add(new Order(
                        Id = customerOrderId,
                        creditMemosAmount__c = 0
                    ));
                }
            }

            if(!customerOrdertoUp.isEmpty()) {
                update customerOrdertoUp;
            }
        }
        System.debug('### FIN TR022_CreditMemo.updateOrderAfterValidation');
    }
        
    /**
    * @description Méthode pour mettre à jour le montant sur les comptes lorsqu'un avoir est validé (comptabilisé)
    * @param userContext contexte utilisateur
    */
    public static void updateAccountAfterValidation(UserContext userContext) {
        System.debug('### DEBUT TR022_CreditMemo.updateAccountAfterValidation');
        
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new;
        Map<Id, CreditMemo__c> oldCreditMemos = (Map<Id, CreditMemo__c>)Trigger.oldMap; 
        List<String> accountIds = new List<String>();
        List<Account> accountToUp = new List<Account>();

        for(CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            // Récupération avoirs comptabilisées
            if(Trigger.isUpdate && oldCreditMemo != null && String.isNotBlank(newCreditMemo.creditMemoReference__c) 
                && String.isNotBlank(newCreditMemo.billingaccount__c)
                && (oldCreditMemo.creditMemoReference__c != newCreditMemo.creditMemoReference__c || oldCreditMemo.status__c != newCreditMemo.status__c)
            ) {
                System.debug('## CreditMemo Id: '+newCreditMemo.Id);
                accountIds.add(newCreditMemo.billingaccount__c);
            }
        }

        // Somme du montant des avoirs des comptes
        if(!accountIds.isEmpty()) {
            for (AggregateResult result : [SELECT billingaccount__c, SUM(amount__c) totalAmount FROM CreditMemo__c 
                                                WHERE billingaccount__c IN :accountIds AND creditMemoReference__c != null 
                                                AND status__c != :Constants.CREDITMEMO_ANNULE
                                                GROUP BY billingaccount__c]) {
                System.debug('## MAJ Account Id: '+result.get('billingaccount__c'));
                System.debug('## Total Amount: '+result.get('totalAmount'));
                // Mise à jour du compte
                accountToUp.add(new Account(
                    Id = (String)result.get('billingaccount__c'),
                    creditMemosAmount__c = (Decimal)result.get('totalAmount') 
                ));
            }

            for(String accountId : accountIds){
                Boolean amountCorrectlyCalculated = false;
                for(Account a : accountToUp){
                    if(a.Id == accountId){
                        amountCorrectlyCalculated = true;
                    }
                }
                if(!amountCorrectlyCalculated){
                    accountToUp.add(new Account(
                        Id = accountId,
                        creditMemosAmount__c = 0
                    ));
                }
            }

            if(!accountToUp.isEmpty()) {
                update accountToUp;
            }
        }
        System.debug('### FIN TR022_CreditMemo.updateAccountAfterValidation');
    }
 
    /**
    * @description Méthode pour exécuter la classe QA_KMDCEinstein
    * @param userContext contexte utilisateur
    */
    public static void scheduleKMDCEinstein(UserContext userContext) {
        System.debug('### DEBUT TR022_CreditMemo.scheduleKMDCEinstein');
        
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new;
        Map<Id, CreditMemo__c> oldCreditMemos = (Map<Id, CreditMemo__c>)Trigger.oldMap; 
        List<CreditMemo__c> credMemoToUpdate = new List<CreditMemo__c>();

        for(CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            // Récupération avoirs comptabilisées
            if(Trigger.isUpdate && oldCreditMemo != null && String.isNotBlank(newCreditMemo.creditMemoReference__c) && 
                (oldCreditMemo.creditMemoDate__c != newCreditMemo.creditMemoDate__c 
                    || oldCreditMemo.pretaxAmount__c != newCreditMemo.pretaxAmount__c 
                    || oldCreditMemo.amount__c != newCreditMemo.amount__c 
                )
            ) {
                System.debug('## CreditMemo Id: '+newCreditMemo.Id);
                credMemoToUpdate.add(newCreditMemo);
            }
        }

        if(!credMemoToUpdate.isEmpty()) {
            System.enqueueJob(new QA_KMDCEinstein('CreditMemo', credMemoToUpdate, null, null)); // Alimentation KMDC pour einstein
        }
        System.debug('### FIN TR022_CreditMemo.scheduleKMDCEinstein');
    }
}