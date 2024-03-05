//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InsertCommercialCreditMemo
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public class IV_InsertCommercialCreditMemo {
    private static final String CREDITMEMO_INVOICECREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_INVOICECREDITMEMO_RT);
    private static final String CREDITMEMO_COMMERCIALCREDITMEMO_RTID = DAL.getRecordTypeIdByDevName('CreditMemo__c', Constants.CREDITMEMO_COMMERCIALCREDITMEMO_RT);
        
    @InvocableMethod(label='Action Avoir Commercial')
    public static List<FlowOutputParameters> insertCommercialCreditMemo(List<FlowInputParameters> inputList) {
        System.debug('### DEBUT IV_InsertCommercialCreditMemo.insertCommercialCreditMemo');
        List<FlowOutputParameters> outputList = new List<FlowOutputParameters>();
        Order order = null;

        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();
        
        try{
            String recordId = inputList[0].recordId;
            if(String.isBlank(recordId)) {                
                throw new FlowActionException('Id de l\'enregistrement inexistante');
            }
            Date creditMemoDate = inputList[0].creditMemoDate;
            String invoiceId = inputList[0].invoiceId;

            order = [SELECT Id, AccountId, serviceEntity__r.ParentId, serviceEntity__c, chantier__c, SBQQ__Quote__c,
                    SBQQ__Quote__r.montantTVAReduite__c, SBQQ__Quote__r.montantTVAIntermediaire__c,
                    SBQQ__Quote__r.tauxTVAReduite__c, SBQQ__Quote__r.tauxTVAIntermediaire__c, SBQQ__Quote__r.tauxTVAFort__c,
                    quote.tvaReduite__c, quote.tvaIntermediaire__c
                    FROM Order WHERE Id =: recordId];
            
            // Création avoir
            CreditMemo__c creditMemo = new CreditMemo__c();
            creditMemo.recordTypeId = CREDITMEMO_COMMERCIALCREDITMEMO_RTID;
            creditMemo.OwnerId = Label.System_id_user_kpark;
            creditMemo.status__c = Constants.CREDITMEMO_BROUILLON;
            creditMemo.customerOrder__c = recordId;
            creditMemo.autoComputedAmount__c = true;
            System.debug('## CreditMemo: '+creditMemo);    

            insert creditMemo;
            
            // 2 – Alimentation des lignes d'avoir
            // L'avoir annule la totalité des lignes (de 1er niveau de la facture / sans parent) => Recopie des données de la ligne de facture
            CreditMemoLine__c creditMemoLine = new CreditMemoLine__c();
            
            creditMemoLine.creditMemo__c = creditMemo.Id;
            creditMemoLine.lineNumber__c = 1;
            creditMemoLine.reason__c = inputList[0].reason;
            creditMemoLine.label__c = String.isBlank(inputList[0].description) ? 'Avoir commercial' : inputList[0].description;
            //creditMemoLine.description__c = invoiceLine.description__c;
            
            // Elements comptables
            creditMemoLine.amount__c = inputList[0].amount;
            if(order != null && order.SBQQ__Quote__c != null) {
                if(order.SBQQ__Quote__r.montantTVAReduite__c > 0) {
                    creditMemoLine.VATRate__c = order.SBQQ__Quote__r.tauxTVAReduite__c;
                } else if(order.SBQQ__Quote__r.montantTVAIntermediaire__c > 0) {
                    creditMemoLine.VATRate__c = order.SBQQ__Quote__r.tauxTVAIntermediaire__c;
                } else {
                    creditMemoLine.VATRate__c = order.SBQQ__Quote__r.tauxTVAFort__c;
                }
            } else if(order != null && order.quote != null) {
                if(order.quote.tvaReduite__c > 0) {
                    creditMemoLine.VATRate__c = 5.5;
                } else if(order.quote.tvaIntermediaire__c > 0) {
                    creditMemoLine.VATRate__c = 10;
                } else {
                    creditMemoLine.VATRate__c = 20;
                }
            } else { // Pour les test
                creditMemoLine.VATRate__c = 5.5;
            }
            creditMemoLine.pretaxAmount__c = creditMemoLine.amount__c / (1+(creditMemoLine.VATRate__c/100)); // HT = TTC / [1 + (taux de TVA / 100)]
            creditMemoLine.VATAmount__c = creditMemoLine.amount__c - creditMemoLine.pretaxAmount__c;
            creditMemoLine.unitPrice__c = creditMemoLine.pretaxAmount__c;
            creditMemoLine.quantity__c = 1;
            creditMemoLine.unit__c = 'UNIT';
            creditMemoLine.invoice__c = invoiceId;
            
            // Reprise d'historique
            creditMemoLine.legacyReference__c = null;
            
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
            
            System.debug('### FIN IV_InsertCommercialCreditMemo.insertCommercialCreditMemo');
            return outputList;
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id de l\'enregistrement associé' required = true )
        public String recordId;
        @InvocableVariable(label='Montant de l\'avoir' required = true )
        public Decimal amount;
        @InvocableVariable(label='Motif de l\'avoir' required = true )
        public String reason;
        @InvocableVariable(label='Libellé de la ligne d\'avoir' required = false )
        public String description;
        @InvocableVariable(label='Date de l\'avoir' required = false )
        public Date creditMemoDate;
        @InvocableVariable(label='Id de la facture' required = false )
        public String invoiceId;
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