//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_CreditMemoLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/09/2021
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_CreditMemoLine {
    
    /**
    * @description Méthode exécutant les règles de validation pour les lignes d'avoir
    * @param userContext Contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemoLine.applyValidationRules');
        
        List<CreditMemoLine__c> oldCreditMemoLines = (List<CreditMemoLine__c>)Trigger.old;
        for(CreditMemoLine__c oldCreditMemoLine : oldCreditMemoLines){
            // Ne pas supprimer si la commande est verrouillé
            if(oldCreditMemoLine.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore){
                System.debug('## oldCreditMemoLine.isOrderLocked__c : ' + oldCreditMemoLine.isOrderLocked__c);
                oldCreditMemoLine.addError(Label.order_msg_cantDeleteCreditMemoLine);
            }  
        }
        
        System.debug('### FIN TR020_CreditMemoLine.applyValidationRules');
    }

    /**
    * @description Méthode pour interdire la suppression d'un avoir pour 10 ans si il a un numéro fiscal. Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext Contexte utilisateur
    */
    public static void cannotDeleteCreditMemoLine(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemo.cannotDeleteCreditMemoLine');
        
        List<CreditMemoLine__c> oldCreditMemosLines = (List<CreditMemoLine__c>)Trigger.old;
        for(CreditMemoLine__c oldCreditMemoLine : oldCreditMemosLines) {
            if(oldCreditMemoLine.isCreditMemoLocked__c && Trigger.isDelete && Trigger.isBefore)
            {
                oldCreditMemoLine.addError(Label.creditmemo_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_CreditMemo.cannotDeleteCreditMemoLine');
    }
    
    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
          
        System.debug('### DEBUT TR020_CreditMemoLine.applyUpdateRules');
        /** COMMENTAIRE SUITE DEMANDE #254 SUR AVOIR
        List<CreditMemoLine__c> newCreditMemoLines = (List<CreditMemoLine__c>)Trigger.new;  
        List<String> invoiceLineIds = new List<String>();  
        Map<Id, CreditMemoLine__c> oldCreditMemoLines = (Map<Id, CreditMemoLine__c>)Trigger.oldMap; 
        Map<Id, InvoiceLine__c> invoiceLineMap = new Map<Id, InvoiceLine__c>();  
      
        // A - Initialisation des données intermédiaires 
        for (CreditMemoLine__c newCreditMemoLine : newCreditMemoLines) {
            CreditMemoLine__c oldCreditMemoLine = oldCreditMemoLines == null ? null : oldCreditMemoLines.get(newCreditMemoLine.id); 
            
            // Ligne de commande
            if ((Trigger.isInsert || (Trigger.isUpdate && oldCreditMemoLine.invoiceLine__c != newCreditMemoLine.invoiceLine__c)) 
                    && String.isNotBlank(newCreditMemoLine.invoiceLine__c)) 
            {
                invoiceLineIds.add(newCreditMemoLine.invoiceLine__c);
            }
        }

        // Récupération des enregistrements d'objets associés
        if(!invoiceLineIds.isEmpty()) {
            invoiceLineMap = new Map<Id, InvoiceLine__c>([SELECT Id, product__c, label__c, unitPrice__c,
                                                    asset__c, unit__c, VATRate__c, amount__c, pretaxAmount__c FROM InvoiceLine__c 
                                                   WHERE id IN :invoiceLineIds]);
            System.debug('## invoiceLineMap: '+invoiceLineMap ); 
        }        
                           
        // B - Application des règles de mise à jour 
        for (CreditMemoLine__c newCreditMemoLine : newCreditMemoLines) {
            System.debug('## Id: '+newCreditMemoLine.Id); 
            System.debug('## OrderItem: '+newCreditMemoLine.invoiceLine__c );  
            
            // MAJ des informations par rapport à la ligne de commande
            if (String.isNotBlank(newCreditMemoLine.invoiceLine__c) && invoiceLineMap.get(newCreditMemoLine.invoiceLine__c) != null) {
                InvoiceLine__c invLine = invoiceLineMap.get(newCreditMemoLine.invoiceLine__c);
                System.debug('## MAJ des informations ligne de facture: '+invLine); 
                newCreditMemoLine.product__c = invLine.product__c;
                newCreditMemoLine.unit__c = invLine.unit__c;
                newCreditMemoLine.label__c = invLine.label__c;
                newCreditMemoLine.VATRate__c = invLine.VATRate__c;
                newCreditMemoLine.unitPrice__c = invLine.unitPrice__c;
                newCreditMemoLine.amount__c = invLine.amount__c;
                newCreditMemoLine.pretaxAmount__c = invLine.pretaxAmount__c;
                newCreditMemoLine.asset__c = invLine.asset__c;
            }
        }
        */
        System.debug('### FIN TR020_CreditMemoLine.applyUpdateRules');
    }
}