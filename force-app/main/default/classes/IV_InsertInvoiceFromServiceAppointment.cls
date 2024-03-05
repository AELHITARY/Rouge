//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InsertInvoiceFromServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_InsertInvoiceFromServiceAppointment {
    private static final String SERVICEAPPOINTMENT_SERVICEAPPOINTMENT_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String INVOICE_INVOICE_RTID = DAL.getRecordTypeIdByDevName('Invoice__c', Constants.INVOICE_INVOICE_RT);
        
    @InvocableMethod(label='Action facturation depuis un rendez-vous de service')
    public static List<FlowOutputParameters> insertInvoiceFromServiceAppointment(List<FlowInputParameters> inputList) {
        System.debug('### DEBUT IV_InsertInvoiceFromServiceAppointment.insertInvoiceFromServiceAppointment');
        List<FlowOutputParameters> outputList = new List<FlowOutputParameters>();
        List<String> assetIds = new List<String>();
        List<Asset> serviceAppointmentAssets = new List<Asset>();
        List<Asset> assetChildren = new List<Asset>();

        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();
        
        try {
            String serviceAppointmentId = inputList[0].serviceAppointmentId;
            if(String.isBlank(serviceAppointmentId)) {                
                throw new FlowActionException('Id de RDV inexistante');
            }
            System.debug('## serviceAppointmentId: '+serviceAppointmentId);
            
            // 0 – Initialisation des ressources internes
            ServiceAppointment serviceAppointment = [SELECT Id, customerOrder__c, ParentRecordId, SchedStartTime FROM ServiceAppointment 
                                                        WHERE RecordTypeId =: SERVICEAPPOINTMENT_SERVICEAPPOINTMENT_RTID
                                                        AND Id = :serviceAppointmentId];

            List<WorkOrderLineItem> woliList = [SELECT Id, AssetId FROM WorkOrderLineItem WHERE WorkOrderId = :serviceAppointment.ParentRecordId];
            
            if(!woliList.isEmpty()) {
                for(WorkOrderLineItem woli : woliList) {
                    assetIds.add(woli.AssetId);
                }
            }
            
            if(!assetIds.isEmpty()) {
                serviceAppointmentAssets = [SELECT Id, orderItem__c, locationFormula__c FROM Asset WHERE Id IN:assetIds];
                assetChildren = [SELECT Id, orderItem__c, ParentId, locationFormula__c FROM Asset WHERE ParentId IN:assetIds];
            }

            Invoice__c invoice = new Invoice__c();
            invoice.recordTypeId = INVOICE_INVOICE_RTID;
            invoice.OwnerId = Label.System_id_user_kpark;
            invoice.customerOrder__c = serviceAppointment.customerOrder__c;
            invoice.workOrder__c = serviceAppointment.ParentRecordId;
            invoice.autoComputedAmount__c = true;
            
            // Eléments comptables
            invoice.deliveryDate__c = serviceAppointment.schedStartTime.date();
            invoice.perceivedAmount__c = 0;
            insert invoice;
            
            // 2 – Alimentation des lignes de facture
            
            // 2.1 - Lignes des actifs associés aux WOLI
            List<InvoiceLine__c> invoiceLinesParent = new List<InvoiceLine__c>() ;
            List<InvoiceLine__c> invoiceLinesChild = new List<InvoiceLine__c>() ;
            List<InvoiceLine__c> invoiceLinesAddAfter = new List<InvoiceLine__c>() ;
            
            // Parcours des assets de 1er niveau/parent
            for (Integer i = 0; i < serviceAppointmentAssets.size(); i++) {
                Asset asset = serviceAppointmentAssets.get(i);
                InvoiceLine__c invoiceLine = new InvoiceLine__c();
                
                invoiceLine.invoice__c = invoice.Id;
                invoiceLine.location__c = asset.locationFormula__c;
                invoiceLine.asset__c = asset.Id;
                invoiceLine.orderItem__c = asset.orderItem__c;
                invoiceLine.lineNumber__c = i;
                
                invoiceLinesParent.add(invoiceLine);
            }
            if(!invoiceLinesParent.isEmpty()) {
                insert invoiceLinesParent;
            }
            
            // Parcours des assets de 2nd niveau/fils
            for (Integer j = 0; j < assetChildren.size(); j++) {
                InvoiceLine__c invoiceSubLine = new InvoiceLine__c();
                Asset subAsset = assetChildren.get(j);
                invoiceSubLine.invoice__c = invoice.Id;
                invoiceSubLine.asset__c = subAsset.Id;
                invoiceSubLine.location__c = subAsset.locationFormula__c;
                invoiceSubLine.orderItem__c = subAsset.orderItem__c;
                invoiceSubLine.lineNumber__c = j * 100 + j;
                for(InvoiceLine__c invParent : invoiceLinesParent) {
                    if(invParent.asset__c == subAsset.ParentId) {
                        invoiceSubLine.lineNumber__c = invParent.lineNumber__c * 100 + j;
                        invoiceSubLine.parentLine__c = invParent.Id;
                    }
                }
                
                invoiceLinesChild.add(invoiceSubLine);       
            }
            
            if(!invoiceLinesChild.isEmpty()) {
                insert invoiceLinesChild;
            }
            
            // 2.2 - Lignes de commandes de 1er niveau/parent non convertibles en asset
            List<Asset> orderAssets = [SELECT Id FROM Asset WHERE customerOrder__c =:serviceAppointment.customerOrder__c AND isBillable__c = true];
            for(Integer i = orderAssets.size() - 1; i >= 0; i--) {
                for(Asset toRemove : serviceAppointmentAssets) {
                    if(orderAssets[i].Id == toRemove.Id) {
                        orderAssets.remove(i);
                    }
                }
            }
            
            if (orderAssets.isEmpty()) { // Tous les assets restants à facturer (isBillable__c = true) correspondent aux assets de ce RDV. De ce fait, il reste à facturer les lignes de commande qui ne sont pas convertibles en asset (ex: Echafaudage, grue, etc.)
                List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE orderId = :serviceAppointment.customerOrder__c AND parentOrderItem__c = null AND Product2.isConvertibleAsset__c = false]; // Sous-requête à intégrer dans la requête principale
                    
                    for (Integer i = 0; i < orderItems.size(); i++) {
                        OrderItem orderItem = orderItems.get(i);
                        InvoiceLine__c invoiceLine = new InvoiceLine__c();
                        invoiceLine.invoice__c = invoice.Id;
                        invoiceLine.orderItem__c = orderItem.Id;
                        invoiceLine.lineNumber__c = serviceAppointmentAssets.size() + i;
                        
                        invoiceLinesAddAfter.add(invoiceLine);
                    }
            }
            if(!invoiceLinesAddAfter.isEmpty()) {
                insert invoiceLinesAddAfter;
            }

            // Alimentation variable de sortie
            FlowOutputParameters out = new FlowOutputParameters();
            out.invoiceId = invoice.Id;
            out.invoiceName = invoice.Name;
            outputList.add(out);
            
            System.debug('### FIN IV_InsertInvoiceFromServiceAppointment.insertInvoiceFromServiceAppointment');
            return outputList;
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id du rendez-vous de service' required = true )
        public String serviceAppointmentId;
    }
    
    /* Output parameters of the Apex action */
    public class FlowOutputParameters{
        @InvocableVariable(label='Id de la facture')
        public String invoiceId;
        @InvocableVariable(label='Nom de la facture')
        public String invoiceName;
    }

    public class FlowActionException extends Exception {}
}