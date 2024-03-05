//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomAssetLockerWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 11/03/2019
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CustomAssetLockerWizard {
    
    /**
    * @description Récupération de la liste des actifs
    * @param recordId Id de l'enregistrement source
    * @return Liste des actifs associés au recordId
    */
    @AuraEnabled(Cacheable = true)
    public static List<Asset> getAssetsFromRecordId(String recordId){
        System.debug('### DEBUT LWC_CustomAssetLockerWizard.getAssetsFromRecordId'); 
        System.debug('## recordId: '+recordId);
        List<Asset> result = new List<Asset>();

        // Récupération des produits (ASSET)
        if(String.isNotBlank(recordId)) {
            // Provenance d'un asset
            if(String.valueof(recordId).startsWith('02i')){
                for(Asset ast : [SELECT Id, controlDate__c, InstallDate, Product2Id, ProductCode, Name, Status
                                FROM Asset WHERE ((Id = :recordId AND ParentId = null) OR ParentId = :recordId) AND isLocked__c != true]) {
                    result.add(ast);
                    System.debug('## 1: '); 
                }
            // Provenance d'une commande
            } else if(String.valueof(recordId).startsWith('801')){
                for(Asset ast : [SELECT Id, controlDate__c, InstallDate, Product2Id, ProductCode, Name, Status
                                FROM Asset WHERE customerOrder__c = :recordId AND ParentId = null AND isLocked__c != true]) {
                    result.add(ast);
                    System.debug('## 2: '); 
                }
            // Provenance d'un chantier
            } else {
                for(Asset ast : [SELECT  Id, controlDate__c, InstallDate, Product2Id, ProductCode, Name, Status
                                FROM Asset WHERE chantier__c = :recordId AND ParentId = null AND isLocked__c != true]) {
                    result.add(ast);
                    System.debug('## 3: '); 
                }
            }            
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomAssetLockerWizard.getAssetsFromRecordId'); 
        return result;
    }

    /**
    * @description Récupération de la liste des rendez vous de service
    * @param assetIdList Id des actifs
    * @return Liste des rendez vous de service
    */
    @AuraEnabled(Cacheable = true)
    public static List<SAObject> getServiceAppointments(List<String> assetIdList){
        System.debug('### DEBUT LWC_CustomAssetLockerWizard.getServiceAppointments'); 
        System.debug('## assetIdList: '+assetIdList);
        List<SAObject> result = new List<SAObject>();
        List<String> woIdList = new List<String>();
        Map<String,String> woAssetMap = new Map<String,String>();

        // Récupération des WorkOrder
        if(!assetIdList.isEmpty()) {
            for(WorkOrderLineItem woli : [SELECT Id, AssetId, WorkOrderId FROM WorkOrderLineItem WHERE AssetId IN :assetIdList]) {
                if(String.isNotBlank(woli.WorkOrderId)) {
                    woIdList.add(woli.WorkOrderId);
                    woAssetMap.put(woli.WorkOrderId, woli.AssetId);
                }
            }
        }     
        // Récupération des ServiceAppointment
        if(!woIdList.isEmpty()) {
            for(ServiceAppointment sa : [SELECT Id, Status, AppointmentNumber, workTypeName__c, Subject, ParentRecordId, 
                                            fsl_libelleDuree__c, fsl_techOrdreExecutionParent__c, fsl_histoStrategiePlanification__c
                                            FROM ServiceAppointment 
                                            WHERE ParentRecordId IN :woIdList AND Status != :Constants.RDV_FSL_TERMINE AND Status != :Constants.RDV_FSL_DEBRIEFE 
                                                AND Status != :Constants.RDV_FSL_ANNULE AND (WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL 
                                                OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC)]) 
            {
                result.add(new SAObject(sa.Id, sa.AppointmentNumber, sa.Subject, sa.workTypeName__c, 'Aucune action', woAssetMap.get(sa.ParentRecordId), sa.fsl_libelleDuree__c, sa.Status));
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomAssetLockerWizard.getServiceAppointments'); 
        return result;
    }

    /**
    * @description Vérrouillage de l'actif et des RDV
    * @param assetList Liste des Id des actifs à vérrouiller
    * @param saList Liste des actions sur les RDV
    */
    @AuraEnabled
    public static void lockAsset(List<String> assetList, List<SAObject> saList){
        System.debug('### DEBUT LWC_CustomAssetLockerWizard.lockAsset');     
        System.debug('## assetList: '+assetList);   
        System.debug('## saList: '+saList);   
        List<ServiceAppointment> serviceAppointmentToSave = new List<ServiceAppointment>();
        List<WorkOrder> workOrderToSave = new List<WorkOrder>();
        List<Asset> assetToSave = new List<Asset>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        Map<String,WorkOrder> woMap = new Map<String,WorkOrder>();
        List<String> saIdList = new List<String>();
        List<String> woIdList = new List<String>();
        
        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();        
        
        try {     
            // Récupération de la liste des ID des RDVs de service
            for(SAObject sa : saList){
                saIdList.add(sa.Id);
            }
            System.debug('## saIdList: '+saIdList);   

            // Récupération des RDV service
            if(!saIdList.isEmpty()) {
                saToUpdate = [SELECT Id, Status, AppointmentNumber, workTypeName__c, Subject, ParentRecordId, fsl_libelleDuree__c, 
                                        cancellingDate__c, cancellingReason__c, cancellingComment__c
                                FROM ServiceAppointment WHERE Id = :saIdList];
            }
            System.debug('## saToUpdate: '+saToUpdate);   

            // Récupération de la liste des ID des work order
            for(ServiceAppointment sa : saToUpdate){
                woIdList.add(sa.ParentRecordId);
            }
            System.debug('## woIdList: '+woIdList);  
            
            // Récupération des WorkOrder
            if(!woIdList.isEmpty()) {
                woMap = new Map<String,WorkOrder>([SELECT Id, AssetId FROM WorkOrder WHERE Id IN :woIdList]);
            }    
            System.debug('## woMap: '+woMap);   
            
            for(ServiceAppointment sa : saToUpdate){
                for(SAObject saObj : saList){
                    if(saObj.id == sa.Id){
                        // Concordance des Id (Objet en base et objet renvoyé), on effectue l'action associée au RDV
                        /*if(saObj.action == 'Conservation du RDV'){
                            woMap.get(sa.ParentRecordId).AssetId = null;
                            workOrderToSave.add(woMap.get(sa.ParentRecordId));
                        } else*/ if(saObj.action == 'Annulation du RDV'){
                            sa.Status = Constants.RDV_FSL_ANNULE;
                            sa.cancellingDate__c = System.now();
                            sa.cancellingReason__c = 'Autre';
                            sa.cancellingComment__c = 'Annulation du RDV suite au verrouillage de l\'actif associé';
                            serviceAppointmentToSave.add(sa);
                            /*
                            woMap.get(sa.ParentRecordId).AssetId = null;
                            workOrderToSave.add(woMap.get(sa.ParentRecordId));
                            */
                        }
                    }
                }
            }

            // MAJ Actifs
            if(!assetList.isEmpty()) {
                for(String astId : assetList) {
                    assetToSave.add(new Asset(Id = astId, suspendDate__c = Date.today()));
                }
            }
            
            // DML
            /*
            if(!workOrderToSave.isEmpty()) {
                System.debug('## workOrderToSave: ' + workOrderToSave);
                update workOrderToSave;
            }
            */
            if(!serviceAppointmentToSave.isEmpty()) {
                System.debug('## serviceAppointmentToSave: ' + serviceAppointmentToSave);
                update serviceAppointmentToSave;
            }
            if(!assetToSave.isEmpty()) {
                System.debug('## assetToSave: ' + assetToSave);
                update assetToSave;
            }
        
            System.debug('### FIN LWC_CustomAssetLockerWizard.lockAsset');
        }
        catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    public class SAObject {
        @AuraEnabled 
        public String id { get; set; }        
        @AuraEnabled
        public String appointmentNumber { get; set; }        
        @AuraEnabled
        public String subject { get; set; }        
        @AuraEnabled
        public String workType { get; set; }        
        @AuraEnabled
        public String action { get; set; }        
        @AuraEnabled
        public String status { get; set; }        
        @AuraEnabled
        public String parentRecord { get; set; }        
        @AuraEnabled
        public String duration { get; set; }

        public SAObject() {}

        public SAObject(
            String id,
            String appointmentNumber,
            String subject,
            String workType,
            String action,
            String parentRecord,
            String duration,
            String status
        ) {
            this.id = id;
            this.appointmentNumber = appointmentNumber;
            this.subject = subject;
            this.workType = workType;
            this.action = action;
            this.parentRecord = parentRecord;
            this.duration = duration;
            this.status = status;
        }
    }
}