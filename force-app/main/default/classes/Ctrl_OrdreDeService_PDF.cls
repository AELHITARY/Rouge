//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_OrdreDeService_PDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 05/02/2020
//-- Version     : 1.0
//-- * 1.0 : Init : Génération d'un ordre de service
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_OrdreDeService_PDF {
    public ServiceAppointment sa {get; set;}
    public AssignedResource ar {get; set;}
    public List<Order> customerOrder {get; set;}
    public List<AssignedResource> arList {get; set;}
    public String SchedStartTimeString { get; set; }
    public String SchedEndTimeString { get; set; }
    public List<Asset> assetList { get; set; }
    public List<Case> ncpList { get; set; }
    public List<String> assetIdList { get; set; }
    public Map<String, Asset> assetMap { get; set; }
    public List<ProductWithPNC> productWithPNCList { get; set; }

    /**
    * @description Constructeur
    * @return Ctrl_OrdreDeService_PDF Controleur
    */
    public Ctrl_OrdreDeService_PDF(ApexPages.StandardController stdController) {
        List<String> assetIdList = new List<String>();
        List<String> assetFirstIdList = new List<String>();
        Map<String, Asset> assetMap = new Map<String, Asset>();
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = new WorkOrder();
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        productWithPNCList = new List<ProductWithPNC>();
        customerOrder = new List<Order>();
        arList = new List<AssignedResource>();
        try {
            // Init
            String saId;
            if(stdController.getRecord().getSObjectType() == Schema.ServiceAppointment.getSObjectType()) {
                sa = (ServiceAppointment)stdController.getRecord();
                saId = sa.Id;
            } else if(stdController.getRecord().getSObjectType() == Schema.AssignedResource.getSObjectType()) {
                ar = (AssignedResource)stdController.getRecord();
                string arId = ar.Id;
                AssignedResource newAR = [SELECT Id, ServiceAppointmentId FROM AssignedResource WHERE Id =: arId];
                saId = newAR.ServiceAppointmentId;
            }
            //String saId = Apexpages.currentPage().getParameters().get('saId');
            List<ServiceAppointment> saList = [SELECT Id, ParentRecordId, WorkTypeId, WorkType.Name, AccountId, Account.Name,  Account.FirstName,  Account.LastName, Account.civilite__c, 
                                                ContactId, Contact.Name, Account.AccountNumber, Account.rue__c, Account.codePostal__c, Account.ville__c, Account.complementAdresse__c, 
                                                customerOrder__c, Chantier__r.rue__c, Chantier__r.complementAdresse__c, Chantier__r.codePostal__c, Chantier__r.ville__c, SchedStartTime, 
                                                SchedEndTime, fsl_coutsProchainRDV__c, ServiceTerritoryId, ServiceTerritory.Name, ServiceTerritory.City, ServiceTerritory.PostalCode, 
                                                ServiceTerritory.Street, ServiceTerritory.State, ServiceTerritory.KparKReference__c, Street, PostalCode, City, 
                                                fsl_externalId__c, dateConfirmationClient__c
                                            FROM ServiceAppointment WHERE Id = :saId];

            // Si pas de devis, rien faire            
            if(String.isBlank(saId)) {
                throw new KubeException('## Rendez-vous de service non existant');
            } else {
                // Get all service appointments
                sa = saList.get(0);
                if(String.valueOf(sa.ParentRecordId).startsWith('0WO')){

                    // Get all WOLI
                    woliList = [SELECT Id, AssetId, WorkOrder.customerOrder__c
                                                FROM WorkOrderLineItem 
                                                WHERE WorkOrderId = :sa.ParentRecordId];
                    for(WorkOrderLineItem woli : woliList){
                        assetFirstIdList.add(woli.AssetId);
                    }
                    String orderId = woliList.get(0).WorkOrder.customerOrder__c;

                    //Get Order
                    customerOrder = [SELECT Id, OrderNumber
                                                FROM Order
                                                WHERE Id = :orderId];
                }

                // Get all ressources
                arList = [SELECT Id, estimatedCost__c, estimatedStandardCost__c, estimatedAdditionalCost__c, cost__c, standardCost__c, additionalCost__c, 
                                    ServiceResourceId, ServiceResource.Name, ServiceResource.AccountId, 
                                    ServiceResource.RelatedRecord.rue__c, ServiceResource.RelatedRecord.codePostal__c, ServiceResource.RelatedRecord.ville__c
                            FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];

                // Get all assets
                if(!assetFirstIdList.isEmpty()) {
                    assetList = [SELECT Id, Name, Product2.Name, leaf__c, height__c, width__c, location__c FROM Asset WHERE Id IN :assetFirstIdList];

                    // Isolate assets Ids
                    if(!assetList.isEmpty()){
                        for(Asset a : assetList){
                            assetIdList.add(a.Id);
                            assetMap.put(a.Id, a);
                        }
                        // Request all PNC from all assets
                        ncpList = [SELECT Id, AssetId, Description FROM Case WHERE AssetId IN :assetIdList];

                        Set<String> ncpAssetId = new Set<String>();
                        if(!ncpList.isEmpty()){
                            // Isolate id of assets with PNC
                            for(Case ncp : ncpList){
                                ncpAssetId.add(ncp.AssetId);
                            }                            
                            // Add all the PNC to the PNC custom object list with asset infos and PNC descriptions to display on VF
                            if(!assetMap.isEmpty()){
                                for(String ast : ncpAssetId){
                                    ProductWithPNC prod = new ProductWithPNC();
                                    prod.id = assetMap.get(ast).Id;
                                    prod.libelle = assetMap.get(ast).Product2.Name;
                                    prod.leaf = Decimal.valueOf(assetMap.get(ast).leaf__c);
                                    prod.width = assetMap.get(ast).width__c;
                                    prod.height = assetMap.get(ast).height__c;
                                    prod.location = assetMap.get(ast).location__c;
                                    prod.description = new List<String>();
                                    if(!ncpList.isEmpty()){
                                        for(Case ncp : ncpList){
                                            if(ncp.AssetId == assetMap.get(ast).Id){
                                                if(ncp.Description != null){
                                                    prod.description.add('- '+ncp.Description);
                                                }
                                            }
                                        }
                                    }
                                    productWithPNCList.add(prod);
                                }      
                            }                  
                        }
                    }
                }
                
                // Get datetimes with correct format
                if(sa.SchedStartTime != null)
                    SchedStartTimeString = sa.SchedStartTime.format('dd/MM/yy HH:mm');
                if(sa.SchedEndTime != null)
                    SchedEndTimeString = sa.SchedEndTime.format('dd/MM/yy HH:mm');
                
            }
        } catch (Exception e){
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            throw e;
        }
    }

    // Parseur de nombre décimal
    public String nombreParseur(Decimal input) {
        String output;
        input = input.setScale(2, RoundingMode.HALF_EVEN);
        output = String.valueOf(input);
        output = output.replace('.', ',');
        if(output.length() > 6 && output.length() <= 9){
            output = output.substring(0, output.length() - 6) + ' ' + output.substring(output.length() - 6);
        } else if(output.length() > 9){
            output = output.substring(0, output.length() - 9) + ' ' + output.substring(output.length() - 9, output.length() - 6) + ' ' + output.substring(output.length() - 6);
        }
        return output;
    }

    public class ProductWithPNC {
        public String id {get; set;}
        public String libelle {get; set;}
        public Decimal leaf {get; set;}
        public Decimal width {get; set;}
        public Decimal height {get; set;}
        public String location {get; set;}
        public List<String> description {get; set;}

        // Constructeurs
        public ProductWithPNC() {
        }
    }
}