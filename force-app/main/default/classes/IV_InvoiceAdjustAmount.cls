//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InvoiceAdjustAmount
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/11/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_InvoiceAdjustAmount {
        
    @InvocableMethod(label='Ajustement des prix des factures')
    public static void adjustInvoicesAmounts(List<FlowInputParameters> inputList) {
        System.debug('### DEBUT IV_InvoiceAdjustAmount.adjustInvoicesAmounts');
        List<InvoiceLine__c> invLinesToUp = new List<InvoiceLine__c>();

        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();
        
        try {
            String invoiceId = inputList[0].invoiceId;
            if(String.isBlank(invoiceId)) {                
                throw new FlowActionException('Id de facture inexistant');
            }
            System.debug('## invoiceId: '+invoiceId);
            
            // 0 – Initialisation des ressources internes
            Invoice__c currentInvoice = [SELECT Id, amount__c, customerOrder__c, customerOrder__r.amount__c, VATAmount__c, pretaxAmount__c,
                                            customerOrder__r.VATAmount__c, customerOrder__r.pretaxAmount__c, autoComputedAmount__c 
                                            FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
            List<InvoiceLine__c> invoiceLines = [SELECT Id, amount__c, VATAmount__c, pretaxAmount__c, invoice__c, orderItemQuantity__c,
                                                    isParentLine__c, orderItem__c, asset__c, label__c, orderItem__r.Quantity, 
                                                    orderItem__r.amount__c, orderItem__r.VATAmount__c, orderItem__r.pretaxAmount__c
                                                    FROM InvoiceLine__c WHERE invoice__c = :currentInvoice.Id];
            
            System.debug('## Invoice Amount: '+currentInvoice.amount__c); 

            // 1 - Calcul différence
            Decimal orderAmount = (currentInvoice.customerOrder__r.amount__c == null) ? 0 : currentInvoice.customerOrder__r.amount__c; 
            Decimal orderVATAmount = (currentInvoice.customerOrder__r.VATAmount__c == null) ? 0 : currentInvoice.customerOrder__r.VATAmount__c;
            Decimal orderPretaxAmount = (currentInvoice.customerOrder__r.pretaxAmount__c == null) ? 0 : currentInvoice.customerOrder__r.pretaxAmount__c;
            Decimal totalAmountLines = 0;
            Decimal totalVATAmountLines = 0;
            Decimal totalPretaxAmountLines = 0;
            Boolean lineQtyGreatThan1 = false;
            for (InvoiceLine__c newInvoiceLine : invoiceLines) {
                if(newInvoiceLine.isParentLine__c) {
                    System.debug('lineId : ' + newInvoiceLine.Id);
                    System.debug('## Total for InvoiceLine: '+newInvoiceLine.orderItem__c+' - '+newInvoiceLine.orderItem__r.VATAmount__c
                                                            +' / '+newInvoiceLine.pretaxAmount__c+' - '+newInvoiceLine.VATAmount__c
                                                            +' - '+newInvoiceLine.amount__c+' - '+newInvoiceLine.orderItemQuantity__c);
                    totalAmountLines = (newInvoiceLine.amount__c == null) ? totalAmountLines : totalAmountLines + newInvoiceLine.amount__c;
                    totalVATAmountLines = (newInvoiceLine.VATAmount__c == null) ? totalVATAmountLines : totalVATAmountLines + newInvoiceLine.VATAmount__c;
                    totalPretaxAmountLines = (newInvoiceLine.pretaxAmount__c == null) ? totalPretaxAmountLines : totalPretaxAmountLines + newInvoiceLine.pretaxAmount__c;
                    // Verifie si des lignes avec QTY > 1 existe pour dispacth en priorité sur ces lignes
                    if(newInvoiceLine.orderItemQuantity__c > 1) {
                        lineQtyGreatThan1 = true;
                    }
                }
            }
            System.debug('## lineQtyGreatThan1: '+lineQtyGreatThan1);

            // Si différence > 10€, alors on ajuste pas
            Decimal diff = orderAmount - currentInvoice.amount__c;
            System.debug('## diff: '+diff);

            if(Math.ABS(diff) < 10) {
                // 2 - Recalcul le montant des lignes pour les lignes de facture d'acompte afin que le montant soit égal à la facture
                Decimal diffAmount = orderAmount - totalAmountLines;
                Decimal diffVATAmount = orderVATAmount - totalVATAmountLines;
                Decimal diffPretaxAmount = orderPretaxAmount - totalPretaxAmountLines;
                System.debug('## Adjust PretaxAmount: '+orderPretaxAmount+' / '+totalPretaxAmountLines+' / '+diffPretaxAmount);
                System.debug('## Adjust Amount: '+orderAmount+' / '+totalAmountLines+' / '+diffAmount);
                System.debug('## VAT: '+orderVATAmount+' / '+totalVATAmountLines+' / '+diffVATAmount);
                // Mise à jour montant ligne parent
                for (InvoiceLine__c newInvoiceLine : invoiceLines) {
                    Boolean isChanged = false;
                    System.debug('## newInvoiceLine: '+newInvoiceLine.isParentLine__c+' - '+newInvoiceLine.orderItemQuantity__c);
                    if(newInvoiceLine.isParentLine__c && ((newInvoiceLine.orderItemQuantity__c > 1 && lineQtyGreatThan1) || !lineQtyGreatThan1)) { // Parent seulement avec plusieurs quantités                    
                        System.debug('## Line Pretax Amount: '+newInvoiceLine.pretaxAmount__c+' - '+newInvoiceLine.orderItem__r.pretaxAmount__c);
                        System.debug('## Line Amount: '+newInvoiceLine.amount__c+' - '+newInvoiceLine.orderItem__r.amount__c);
                        // Montant HT
                        if(orderPretaxAmount != totalPretaxAmountLines && newInvoiceLine.pretaxAmount__c != 0) 
                        {
                            totalPretaxAmountLines = totalPretaxAmountLines + diffPretaxAmount;
                            newInvoiceLine.pretaxAmount__c = newInvoiceLine.pretaxAmount__c + diffPretaxAmount;
                            System.debug('## Modify PretaxAmount: '+newInvoiceLine.Id+' / '+newInvoiceLine.label__c+' / '+newInvoiceLine.pretaxAmount__c);
                            isChanged = true;
                        }
                        // Montant TTC
                        if(orderAmount != totalAmountLines && newInvoiceLine.amount__c != 0) 
                        {
                            totalAmountLines = totalAmountLines + diffAmount;
                            newInvoiceLine.amount__c = newInvoiceLine.amount__c + diffAmount;
                            System.debug('## Modify Amount: '+newInvoiceLine.Id+' / '+newInvoiceLine.label__c+' / '+newInvoiceLine.amount__c);
                            isChanged = true;
                        }

                        if(isChanged) {
                            invLinesToUp.add(newInvoiceLine);
                        }
                    }
                }

                // Mise à jour
                if(!invLinesToUp.isEmpty()) {
                    update invLinesToUp;
                }

                if(Math.ABS(diffVATAmount) > 10){
                    throw new FlowActionException('Une incohérence a été détectée au niveau des montants TVA. Vérifiez le montant TVA de la commande ainsi que celle des produits commandés.');
                }

                // Mise à jour montant TVA facture
                System.debug('## Adjust VATAmount: '+orderVATAmount+' / '+totalVATAmountLines+' / '+diffVATAmount);
                currentInvoice.autoComputedAmount__c = true;
                update currentInvoice;
                invLinesToUp.clear();
                for (InvoiceLine__c newInvoiceLine : invoiceLines) {
                    Boolean isChanged = false;
                    System.debug('## newInvoiceLine: '+newInvoiceLine.isParentLine__c+' - '+newInvoiceLine.orderItemQuantity__c);
                    if(newInvoiceLine.isParentLine__c && ((newInvoiceLine.orderItemQuantity__c > 1 && lineQtyGreatThan1) || !lineQtyGreatThan1)) { // Parent seulement avec plusieurs quantités                    
                        System.debug('## Line VATAmount: '+newInvoiceLine.VATAmount__c+' - '+newInvoiceLine.orderItem__r.VATAmount__c);
                        // Montant TVA
                        if(orderVATAmount != totalVATAmountLines && newInvoiceLine.VATAmount__c != 0 && newInvoiceLine.VATAmount__c != null) 
                        {
                            totalVATAmountLines = totalVATAmountLines + diffVATAmount;
                            newInvoiceLine.VATAmount__c = newInvoiceLine.VATAmount__c + diffVATAmount;
                            System.debug('## Modify VATAmount: '+newInvoiceLine.Id+' / '+newInvoiceLine.label__c+' / '+newInvoiceLine.VATAmount__c);
                            isChanged = true;
                        }
                        invLinesToUp.add(newInvoiceLine);
                    }
                }
            } else {
                // Mise à jour du calcul auto
                currentInvoice.autoComputedAmount__c = true;
                update currentInvoice;
                invLinesToUp.add(invoiceLines[0]);
            }

            // Mise à jour
            if(!invLinesToUp.isEmpty()) {
                update invLinesToUp;
            }
            
            System.debug('### FIN IV_InvoiceAdjustAmount.adjustInvoicesAmounts');
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id de la facture' required = true )
        public String invoiceId;
    }

    public class FlowActionException extends Exception {}
}