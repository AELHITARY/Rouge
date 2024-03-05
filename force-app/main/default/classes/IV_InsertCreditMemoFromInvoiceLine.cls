//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InsertCreditMemoFromInvoiceLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_InsertCreditMemoFromInvoiceLine {
    private static final String CREDITMEMO_INVOICECREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_INVOICECREDITMEMO_RT);
    private static final String CREDITMEMO_COMMERCIALCREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_COMMERCIALCREDITMEMO_RT);
        
    /**
    * @description Action de création d'un avoir depuis une ligne de facture
    * @param inputList Liste des paramètres d'entrée provenant du Flow
    */
    @InvocableMethod(label='Action Avoir depuis ligne de facture')
    public static List<FlowOutputParameters> insertCreditMemoFromInvoiceLine(List<FlowInputParameters> inputList) {
        System.debug('### DEBUT IV_InsertCreditMemoFromInvoiceLine.insertCreditMemoFromInvoiceLine');
        List<FlowOutputParameters> outputList = new List<FlowOutputParameters>();
        String invoiceLineId = inputList[0].invoiceLineId;
        Date creditMemoDate = inputList[0].creditMemoDate;
        InvoiceLine__c invoiceLine;
        System.debug('## invoiceLineId: '+invoiceLineId);
        System.debug('## creditMemoDate: '+creditMemoDate);

        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();

        try{
            if(String.isBlank(invoiceLineId)) {                
                throw new FlowActionException('Id de ligne de facture inexistante');
            }

            // Récupération facture et ligne
            List<InvoiceLine__c> invoiceLineList = [SELECT Id, invoice__c, label__c, product__c, asset__c, orderItem__c, pretaxAmount__c, VATRate__c, VATAmount__c,
                                                    quantity__c, unit__c, unitPrice__c, amount__c, location__c 
                                                    FROM InvoiceLine__c WHERE Id =: invoiceLineId];
            if(invoiceLineList.isEmpty()) {                
                throw new FlowActionException('Ligne de facture inexistante');
            } else {
                invoiceLine = invoiceLineList[0];
            }
        
            Invoice__c invoice = [SELECT Id, customerOrder__c, customerOrder__r.serviceEntity__c, customerOrder__r.chantier__c, billingAccount__c, 
                              customerOrder__r.serviceEntity__r.ParentId, workOrder__c
                              FROM Invoice__c WHERE Id =:invoiceLine.invoice__c];

            // Création avoir
            CreditMemo__c creditMemo = new CreditMemo__c();
            creditMemo.recordTypeId = CREDITMEMO_INVOICECREDITMEMO_RTID;
            creditMemo.OwnerId = Label.System_id_user_kpark;
            creditMemo.customerOrder__c = invoice.customerOrder__c;
            creditMemo.invoice__c = invoice.Id;
            creditMemo.status__c = Constants.CREDITMEMO_BROUILLON;
            creditMemo.workOrder__c = invoice.workOrder__c;
            creditMemo.autoComputedAmount__c = true;
            System.debug('## CreditMemo: '+creditMemo);     
            insert creditMemo;
            
            // 2 – Alimentation des lignes de facture
            // L'avoir annule la totalité des lignes (de 1er niveau de la facture / sans parent) => Recopie des données de la ligne de facture
            CreditMemoLine__c creditMemoLine = new CreditMemoLine__c();

            creditMemoLine.creditMemo__c = creditMemo.Id;
            creditMemoLine.lineNumber__c =0;
            creditMemoLine.reason__c = 'Annulation facture';
            creditMemoLine.label__c = invoiceLine.label__c;
            creditMemoLine.unitPrice__c = invoiceLine.unitPrice__c;
            creditMemoLine.invoice__c = invoiceLine.invoice__c;
            creditMemoLine.invoiceLine__c = invoiceLine.id;
            creditMemoLine.product__c = invoiceLine.product__c;
            creditMemoLine.asset__c = invoiceLine.asset__c;
            creditMemoLine.orderItem__c = invoiceLine.orderItem__c;
            creditMemoLine.location__c = invoiceLine.location__c;
            // Elements comptables
            creditMemoLine.pretaxAmount__c = invoiceLine.pretaxAmount__c;
            creditMemoLine.VATRate__c = invoiceLine.VATRate__c;
            creditMemoLine.VATAmount__c = invoiceLine.VATAmount__c;
            creditMemoLine.amount__c = invoiceLine.amount__c;
            creditMemoLine.quantity__c = invoiceLine.quantity__c;
            creditMemoLine.unit__c = invoiceLine.unit__c;

            System.debug('## CreditMemoLine: '+creditMemoLine);               
            insert creditMemoLine;
            
            // 3 – Validation de l'avoir
            if(creditMemoDate != null) {
                creditMemo.creditMemoDate__c = creditMemoDate;
                update creditMemo; // L’algo alimentera automatiquement le n° fiscal creditMemoReference__c et passera le statut à Validé
            }

            // Alimentation variable de sortie
            FlowOutputParameters out = new FlowOutputParameters();
            out.creditMemoId = creditMemo.Id;
            out.creditMemoName = creditMemo.Name;
            outputList.add(out);
            
            System.debug('### FIN IV_InsertCreditMemoFromInvoiceLine.insertCreditMemoFromInvoiceLine');
            return outputList;
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id de l\'objet ligne de facture' required = true )
        public String invoiceLineId;
        @InvocableVariable(label='Date de l\'avoir' required = false )
        public Date creditMemoDate;
    }
    
    /* Output parameters of the Apex action */
    public class FlowOutputParameters{
        @InvocableVariable(label='Id de l\'avoir')
        public String creditMemoId;
        @InvocableVariable(label='Nom de l\'avoir')
        public String creditMemoName;
    }

    public class FlowActionException extends Exception {}
}