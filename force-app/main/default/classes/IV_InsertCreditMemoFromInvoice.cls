//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InsertCreditMemoFromInvoice
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_InsertCreditMemoFromInvoice {
    private static final String CREDITMEMO_INVOICECREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_INVOICECREDITMEMO_RT);
    private static final String CREDITMEMO_COMMERCIALCREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_COMMERCIALCREDITMEMO_RT);
        
    /**
    * @description Action de création d'un avoir depuis une facture et ces lignes
    * @param inputList Liste des paramètres d'entrée provenant du Flow
    */
    @InvocableMethod(label='Création Avoir total')
    public static List<FlowOutputParameters> insertCreditMemoFromInvoice(List<FlowInputParameters> inputList) {  
        System.debug('### DEBUT IV_InsertCreditMemoFromInvoice.insertCreditMemoFromInvoice');
        List<FlowOutputParameters> outputList = new List<FlowOutputParameters>();
        String invoiceId = inputList[0].invoiceId;
        Date creditMemoDate = inputList[0].creditMemoDate;
        Invoice__c invoice;
        System.debug('## invoiceId: '+invoiceId);
        System.debug('## creditMemoDate: '+creditMemoDate);

        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();

        try{
            if(String.isBlank(invoiceId)) {                
                throw new FlowActionException('Id de facture inexistante');
            }

            // Récupération facture et ligne
            List<Invoice__c> invoiceList = [SELECT Id, customerOrder__c, customerOrder__r.serviceEntity__c, customerOrder__r.chantier__c, billingAccount__c, 
                                            customerOrder__r.serviceEntity__r.ParentId, workOrder__c, amount__c
                                            FROM Invoice__c WHERE Id =:invoiceId];
            if(invoiceList.isEmpty()) {                
                throw new FlowActionException('Facture inexistante');
            } else {
                invoice = invoiceList[0];
            }
            System.debug('## InvoiceId: '+invoice);
            
            // Récupération seulement des lignes avec un montant >= 0 (ne pas prendre celles à null)
            List<InvoiceLine__c> invoiceLines = [SELECT Id, invoice__c, lineNumber__c, label__c, product__c, asset__c, orderItem__c, location__c,
                                                 pretaxAmount__c, VATRate__c, quantity__c, unit__c, VATAmount__c, unitPrice__c, amount__c
                                                 FROM InvoiceLine__c WHERE invoice__c =: invoiceId AND parentLine__c = null AND pretaxAmount__c != null];
            
            // Creation Avoir
            CreditMemo__c creditMemo = new CreditMemo__c();
            creditMemo.recordTypeId = CREDITMEMO_INVOICECREDITMEMO_RTID;
            creditMemo.OwnerId = System.Label.System_id_user_kpark;
            creditMemo.customerOrder__c = invoice.customerOrder__c;
            creditMemo.invoice__c = invoice.Id;
            creditMemo.status__c = Constants.CREDITMEMO_BROUILLON;        
            creditMemo.workOrder__c = invoice.workOrder__c;
            creditMemo.autoComputedAmount__c = true;
            System.debug('## CreditMemo: '+creditMemo);       
            insert creditMemo;
            
            // 2 – Alimentation des lignes de facture
            // L'avoir annule la totalité des lignes (de 1er niveau de la facture / sans parent) => Recopie des données de la ligne de facture
            List<CreditMemoLine__c> creditMemoLines = new List<CreditMemoLine__c>();
            
            if(!invoiceLines.isEmpty()) {
                for (InvoiceLine__c invoiceLine : invoiceLines) {
                    CreditMemoLine__c creditMemoLine = new CreditMemoLine__c();
                    
                    creditMemoLine.creditMemo__c = creditMemo.Id;
                    creditMemoLine.lineNumber__c = invoiceLine.lineNumber__c;
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
                    creditMemoLines.add(creditMemoLine);
                }
            }
            
            if(!creditMemoLines.isEmpty()) {
                insert creditMemoLines;
            }
            
            // 3 – Validation de l'avoir
            if(creditMemoDate != null) {
                creditMemo.creditMemoDate__c = creditMemoDate;
                update creditMemo; // L’algo alimentera automatiquement le n° fiscal creditMemoReference__c et passera le statut à Validé
            }

            // 4 - Annulation de la facture
            String codeRef = PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
            List<Referencial__c> refList = [SELECT Id FROM Referencial__c WHERE KparKReference__c = :codeRef LIMIT 1];

            invoice.cancelledAmount__c = invoice.amount__c;
            invoice.cancellationDate__c = creditMemo.creditMemoDate__c;
            invoice.cancellationReason__c = refList[0].Id;
            update invoice;

            // Alimentation variable de sortie
            FlowOutputParameters out = new FlowOutputParameters();
            out.creditMemoId = creditMemo.Id;
            out.creditMemoName = creditMemo.Name;
            outputList.add(out);
            
            System.debug('### FIN IV_InsertCreditMemoFromInvoice.insertCreditMemoFromInvoice');
            return outputList;
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id de l\'objet facture' required = true )
        public String invoiceId;
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