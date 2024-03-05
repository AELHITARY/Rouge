//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomWorkOrderWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 17/01/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CustomWorkOrderWizard {

    private static final String ASSET_INSTALLED_EARLIER_THAN_A_MONTH_STRING = 'actif de plus d\'un mois';
    private static final String ASSET_INSTALLED_LATER_THAN_A_MONTH_STRING = 'actif de moins d\'un mois';
    private static final String RDV_DEBRIEFE = Constants.RDV_FSL_DEBRIEFE;
    /**
    * @description Récupération de la liste des actifs mesurable d'une commande
    * @param sContractId Id du contrat
    * @return Liste des actifs du contrat
    */
    @AuraEnabled(Cacheable = true)
    public static void checkPermissions(){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.checkPermissions'); 
    
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Planification_Selection_produits');
        System.debug('## hasCustomPermission: '+hasCustomPermission); 
    
        System.debug('### FIN LWC_CustomWorkOrderWizard.checkPermissions'); 
    }
    
    /**
    * @description Fonction pour définir le type du RDV à créer selon plusieurs paramètre
    * @param recordId Id de l'enregistrement
    * @param objectApiName Nom API de l'objet
    * @return Nom du type du RDV (WorkType)
    */
    @AuraEnabled(Cacheable = true)
    public static WorkType getWorkType(String recordId, String objectApiName, Boolean isCommandeSAV){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getWorkType'); 
        WorkType result = null;
        //String workTypeName = Constants.ACTIVITY_TYPE_CONTROL;
        String workTypeName = '';

        Boolean isControl = false;
        Boolean isIntervention = false;
        Boolean isDiagnostic = false;
        String subWorkType = null;
        System.debug('## recordId: '+recordId); 
        System.debug('## objectApiName: '+objectApiName); 
        System.debug('### isCommandeSAV:'+isCommandeSAV); 
    
        if(String.isNotBlank(recordId)) {
            String assetCRTId = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT); 
            String assetSRTId = DAL.getRecordTypeIdByDevName('Asset', 'Service'); 
            String casePNCIntRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
            List<Asset> assetsList = new List<Asset>();
            // Récupération des produits (ASSET)
            if(objectApiName == 'Order') {
                assetsList = [SELECT  Id, controlDate__c, Status, InstallDate, Product2Id, ProductCode, Name, Product2.isControllable__c,
                                    (SELECT Id, Status, WorkOrder.WorkType.Name FROM WorkOrderLineItems),
                                    (SELECT Id, diagnosticDate__c, IsClosed, Type FROM Cases WHERE RecordTypeId = :casePNCIntRTId)
                                FROM Asset WHERE customerOrder__c = :recordId 
                                    AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId) 
                                    AND isLocked__c = false AND Status != :Constants.ASSET_STATUS_ANNULE];
            } else if(objectApiName == 'Chantier__c' || objectApiName == 'AfterSalesService__c') {
                String chantierId = recordId;
                if(objectApiName == 'AfterSalesService__c') {
                    List<AfterSalesService__c> sav = [SELECT Id, workSite__c FROM AfterSalesService__c WHERE Id = :recordId LIMIT 1];
                    chantierId = sav[0].workSite__c;
                }
                assetsList = [SELECT  Id, controlDate__c, Status, InstallDate, Product2Id, ProductCode, Name, Product2.isControllable__c,
                                    (SELECT Id, Status, WorkOrder.WorkType.Name FROM WorkOrderLineItems),
                                    (SELECT Id, diagnosticDate__c, IsClosed, Type FROM Cases WHERE RecordTypeId = :casePNCIntRTId)
                                FROM Asset WHERE chantier__c = :chantierId 
                                    AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId) 
                                    AND isLocked__c = false AND Status != :Constants.ASSET_STATUS_ANNULE];
            } 
    
            // Récupération des WorkOrderLineItem
            for(Asset ast : assetsList) {
                Integer nbWOControlTotal = 0;
                Integer nbWOControlFinished = 0;
                Integer nbWOIntTotal = 0;
                Integer nbWOIntFinished = 0;
                Integer nbWODiagTotal = 0;
                Integer nbWODiagFinished = 0;
                Integer nbCaseTotal = 0;
                Integer nbCaseNotClosed = 0;
                Integer nbCaseDiag = 0;        
                // Récupération des WorkOrderLineItem
                for(WorkOrderLineItem woli : ast.WorkOrderLineItems) {
                    if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_CONTROL) {
                        nbWOControlTotal++;
                    } else if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_INTERVENTION) {
                        nbWOIntTotal++;
                    } else if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
                        nbWODiagTotal++;
                    }
                    if(woli.Status == Constants.WOLI_FSL_TERMINE) {
                        if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_CONTROL) {
                            nbWOControlFinished++;
                        } else if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_INTERVENTION) {
                            nbWOIntFinished++;
                        } else if(woli.WorkOrder.WorkType.Name == Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
                            nbWODiagFinished++;
                        }
                    }
                }             
                // Récupération des cases pour calcul des NCP
                for(Case newCase : ast.Cases) {
                    nbCaseTotal++;
                    if(newCase.isClosed == false) {
                        nbCaseNotClosed++;
                    }
                    if(newCase.diagnosticDate__c != null && newCase.isClosed == false) {
                        nbCaseDiag++;
                    }
                }
    
                // Défini le type
                // Contrôle : Si il existe au moins un actif, contrôlable et sans date de contrôle 
                //  OU qui n'est pas associé à au moins un RDV de contrôle avec une date de fin réelle non nulle
                if(ast.Product2.isControllable__c && ast.Status == Constants.ASSET_STATUS_VALIDE && (ast.controlDate__c == null || nbWOControlTotal != nbWOControlFinished)) {
                    if(objectApiName != 'AfterSalesService__c' && !isCommandeSAV){
                        System.debug('## Asset contrôlable: ' + ast.Id); 
                        isControl = true;
                        //break;
                    }
                } 
                // Intervention : Si il existe au moins une NCP, installable et sans date d'installation 
                //  OU qui n'est pas associé à au moins un RDV d'installation avec une date de fin réelle non nulle ;
                if((ast.InstallDate == null || nbWOIntTotal != nbWOIntFinished || nbCaseNotClosed != 0) 
                    && ast.Status != Constants.ASSET_STATUS_ANNULE && ast.Status != Constants.ASSET_STATUS_SUSPENDU
                ){
                    System.debug('## Asset installable: ' + ast.Id); 
                    isIntervention = true;
                    //break;
                } 
                // Diagnostic : Si il existe au moins une NCP, sans date de diagnostic 
                //  OU qui n'est pas associé à au moins un RDV de diagnostic avec une date de fin réelle non nulle ;
                if(nbWODiagTotal != nbWODiagFinished || nbCaseDiag != 0) {
                    System.debug('## Asset diagnostic: ' + ast.Id); 
                    isDiagnostic = true;
                    //break;
                } 
            }
            System.debug('## isControl: '+isControl); 
            System.debug('## isIntervention: '+isIntervention); 
            System.debug('## isDiagnostic: '+isDiagnostic); 
    
            // Définition du nom du WorkType
            if(isControl) {
                workTypeName = Constants.ACTIVITY_TYPE_CONTROL;
            } else if(isIntervention) {
                workTypeName = Constants.ACTIVITY_TYPE_INTERVENTION;
            } else if (isDiagnostic) {
                workTypeName = Constants.ACTIVITY_TYPE_DIAGNOSTIC;
            }

            //Gestion valeur par défaut
            if(workTypeName == ''){
                //Intervention pour commande et dossier SAV
                if(objectApiName == 'AfterSalesService__c'|| isCommandeSAV){
                    workTypeName = Constants.ACTIVITY_TYPE_INTERVENTION;
                }
                //Métrage sinon
                else{
                    workTypeName = Constants.ACTIVITY_TYPE_CONTROL;
                }
            }

            // Récupération des infos du WorkType
            if(String.isNotBlank(workTypeName)) {
                result = getWorkTypeDetails(workTypeName);
            }       
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getWorkType'); 
        return result;
    }
    
    /**
    * @description Fonction pour récupérer le détail des types d'activités
    * @param workTypeName Nom de l'activité
    * @return Nom du type du RDV (WorkType)
    */
    @AuraEnabled(Cacheable = true)
    public static WorkType getWorkTypeDetails(String workTypeName){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getWorkTypeDetails'); 
        WorkType result = null;
    
        // Récupération des infos du WorkType
        if(String.isNotBlank(workTypeName)) {
            result = [SELECT Id, Name, Description, EstimatedDuration, DurationType, schedulingPolicy__c, schedulingPolicy__r.Name,
                        MinimumCrewSize, RecommendedCrewSize FROM WorkType WHERE Name = :workTypeName LIMIT 1];
        }  
    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getWorkTypeDetails'); 
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les paramètres de planification par rapport à l'entité et au type de travail
    * @param workTypeId Id de l'activité
    * @param entityId Id de l'entité
    * @return Nom du type du RDV (WorkType)
    */
    @AuraEnabled(Cacheable = true)
    public static EntityWorkTypeParameters__c getEntityWorkTypeParameters(String workTypeId, String entityId){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getEntityWorkTypeParameters'); 
        System.debug('## workTypeId : '+workTypeId); 
        System.debug('## entityId : '+entityId); 
        EntityWorkTypeParameters__c result = null;
        List<EntityWorkTypeParameters__c> entParamList = new List<EntityWorkTypeParameters__c>();
    
        // Récupération des infos 
        if(String.isNotBlank(workTypeId) && String.isNotBlank(entityId)) {
            entParamList = [SELECT Id, Name, workType__c, estimatedDuration__c, schedulingPolicy__c, schedulingPolicy__r.Name, 
                        autoSchedulingDelay__c, entity__c, dueDateDelay__c FROM EntityWorkTypeParameters__c WHERE workType__c = :workTypeId AND entity__c = :entityId];
        }  
        if(!entParamList.isEmpty()) {
            result = entParamList[0];
        } 
    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getEntityWorkTypeParameters'); 
        return result;
        
    }
    
    /**
    * @description Récupération de la liste des actifs d'une commande client ou d'un chantier
    * @param recordId Id de l'enregistrement
    * @param objectApiName Nom API de l'objet
    * @param activityType Type d'activité (controle, installation etc...) 
    * @param applyAssetFilter Applique un filtre sur le statut selon le type d'activité
    * @return Liste des actifs de la commande ou d'un chantier
    */
    @AuraEnabled(Cacheable = true)
    public static List<Asset> getProducts(String recordId, String objectApiName, String activityType, Boolean applyAssetFilter){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getProducts'); 
        List<Asset> result = new List<Asset>();
        System.debug('## recordId: '+recordId); 
        System.debug('## objectApiName: '+objectApiName); 
        System.debug('## activityType: '+activityType); 
        System.debug('## applyAssetFilter: '+applyAssetFilter); 
    
        // Récupération des actifs (ASSET)
        if(String.isNotBlank(recordId)) {
            String assetCRTId = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT); 
            String assetSRTId = DAL.getRecordTypeIdByDevName('Asset', 'Service'); 
            List<Asset> assetsList = new List<Asset>();
            if(objectApiName == 'Order') {
                assetsList = [SELECT  Id, controlDate__c, InstallDate, Product2Id, ProductCode, Name, installCrewSize__c, RootAssetId,
                                Product2.isControllable__c, Product2.isInstallable__c, deliveryDate__c, maxDeliveryDate__c, warrantyMaxDuration__c,
                                maxEstimatedDeliveryDate__c, orderItem__r.eligibleESC__c, SBQQ__OrderProduct__r.eligibleESC__c, controlTime__c, interventionTime__c,
                                    (SELECT Id, Status, WorkOrder.WorkType.Name 
                                        FROM WorkOrderLineItems WHERE Status != :Constants.WOLI_FSL_TERMINE AND WorkOrder.WorkType.Name = :activityType)
                                FROM Asset WHERE customerOrder__c = :recordId 
                                    AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId) 
                                    AND isLocked__c = false AND Status != :Constants.ASSET_STATUS_ANNULE];
            } else if(objectApiName == 'Chantier__c' || objectApiName == 'AfterSalesService__c') {
                String chantierId = recordId;
                if(objectApiName == 'AfterSalesService__c') {
                    List<AfterSalesService__c> sav = [SELECT Id, workSite__c FROM AfterSalesService__c WHERE Id = :recordId LIMIT 1];
                    chantierId = sav[0].workSite__c;
                }
                assetsList = [SELECT  Id, controlDate__c, InstallDate, Product2Id, ProductCode, Name, installCrewSize__c, RootAssetId,
                                Product2.isControllable__c, Product2.isInstallable__c, deliveryDate__c, maxDeliveryDate__c, warrantyMaxDuration__c,
                                maxEstimatedDeliveryDate__c, orderItem__r.eligibleESC__c, SBQQ__OrderProduct__r.eligibleESC__c, controlTime__c, interventionTime__c,
                                    (SELECT Id, Status, WorkOrder.WorkType.Name 
                                        FROM WorkOrderLineItems WHERE Status != :Constants.WOLI_FSL_TERMINE AND WorkOrder.WorkType.Name = :activityType)
                                FROM Asset WHERE chantier__c = :chantierId 
                                    AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId)  
                                    AND isLocked__c = false AND Status != :Constants.ASSET_STATUS_ANNULE];
            }
    
            // Récupération actif enfant et construction map
            Map<String, List<Asset>> mapAssetsChild = new Map<String, List<Asset>>();
            List<Asset> astChildList = new List<Asset>();
            for(Asset ast : [SELECT Id, RootAssetId, controlTime__c, interventionTime__c 
                                FROM Asset WHERE RootAssetId IN :assetsList]) 
            {
                if(mapAssetsChild.get(ast.RootAssetId) == null) {
                    astChildList = new List<Asset>();
                } else {
                    astChildList = mapAssetsChild.get(ast.RootAssetId);
                }
                astChildList.add(ast);
                mapAssetsChild.put(ast.RootAssetId, astChildList);
            }
            
            for(Asset ast : assetsList) {
                System.debug('## Asset: '+ast.Id);
                // Récupération des enfants, pour calcul des temps de métrage/intervention
                Decimal ctrlTimeTotal = 0;
                Decimal interTimeTotal = 0;
                for(Asset astChild : mapAssetsChild.get(ast.Id)) {
                    ctrlTimeTotal += astChild.controlTime__c;
                    interTimeTotal += astChild.interventionTime__c;
                }
                ast.warrantyMaxDuration__c  = ctrlTimeTotal; // Utilisation temporaire du champ pour stocker la valeur de métrage
                ast.installDuration__c = interTimeTotal;
                System.debug('## Duration: '+ast.warrantyMaxDuration__c+' / '+ast.installDuration__c);
    
                if(activityType == Constants.ACTIVITY_TYPE_CONTROL && ast.Product2.isControllable__c) {                    
                    if(applyAssetFilter && ast.controlDate__c == null) {
                        result.add(ast); // Affiche les actifs non métrés pour les RDV controle
                    } else if(!applyAssetFilter) {
                        result.add(ast); // Affiche tous les actifs pour les RDV controle
                    } 
                } else if(activityType == Constants.ACTIVITY_TYPE_INTERVENTION && ast.Product2.isInstallable__c) {
                    if(applyAssetFilter && ast.InstallDate == null) {
                        result.add(ast); // Affiche les actifs installable non installés pour les RDV interv
                    } else if(!applyAssetFilter) {
                        result.add(ast); // Affiche tous les actifs installable pour les RDV interv
                    }
                } else if(activityType == Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
                    // Affiche les actifs non installés pour les RDV diag
                    if(applyAssetFilter && ast.InstallDate != null) {
                        result.add(ast); // Affiche les actifs installés pour les RDV Diag
                    } else if(!applyAssetFilter) {
                        result.add(ast); // Affiche tous les actifs pour les RDV Diag
                    } 
                }
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getProducts'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste des non-conformités produits (NCP ou PNC)
    * @param assetsId Liste des Id des assets
    * @param savId Id du dossier SAV (si dossier SAV)
    * @param activityType Type d'activité (controle, installation etc...) 
    * @param orderId Id de la commande
    * @param isCommandeSAV Liste des Id des Cases issues des commandes
    * @param applyNCPFilter Applique un filtre sur le statut selon le type d'activité
    * @return Liste des non-conformités produits
    */
    @AuraEnabled(Cacheable = true)
    public static List<Case> getProductsNonCompliance(List<String> assetsId, String savId, String activityType, String orderId, Boolean isCommandeSAV, Boolean applyNCPFilter, String quoteId){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getProductsNonCompliance'); 
        List<Case> result = new List<Case>();
        System.debug('## assetsId: '+assetsId); 
        System.debug('## savId: '+savId); 
        System.debug('## activityType: '+activityType);
        System.debug('## orderId: '+orderId);
        System.debug('## isCommandeSAV: '+isCommandeSAV);
        System.debug('## quoteId: '+quoteId);
    
        // If Commande SAV
        List<String> casesId = new List<String>();
        if((isCommandeSAV != null && isCommandeSAV && quoteId != null)){
            System.debug('## Get OrderItems informations');
            /*List<OrderItem> ordersItems = [SELECT Id, case__c FROM OrderItem WHERE OrderId = :orderId];
            for(OrderItem oi : ordersItems){
                System.debug('## OrderItem' + oi);
                if(oi.case__c != null){
                    casesId.add(oi.case__c);
                }
            }*/

            //Récupération NCP liées au devis source
            List<Case> caseList = [SELECT Id, customerOrder__c FROM Case WHERE afterSalesServiceQuote__c = :quoteId];
            for(Case newCase : caseList) {
                casesId.add(newCase.Id);
            }

        } else if (orderId != null) {
            List<Case> caseList = [SELECT Id, customerOrder__c FROM Case WHERE customerOrder__c = :orderId];
            for(Case newCase : caseList) {
                casesId.add(newCase.Id);
            }
        }
    
        String casePNCIntRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT); 
        System.debug('## casePNCIntRTId: '+casePNCIntRTId);
        
        // Construction requête SOQL
        String soqlQuery = 'SELECT Id, CaseNumber, Status, Asset.Name, IsClosed, AssetId, dateTimeReOpen__c, ' +
                            ' interventionDuration__c, interventionCrewSize__c, ClosedDate, CreatedDate, diagnosticDate__c ' +
                            ' FROM Case WHERE RecordTypeId = :casePNCIntRTId AND IsClosed = false ';
    
        // Filtre selon type d'activité
        if(activityType == Constants.ACTIVITY_TYPE_DIAGNOSTIC && applyNCPFilter) {
            soqlQuery += ' AND diagnosticDate__c = null';
        } else if(activityType == Constants.ACTIVITY_TYPE_INTERVENTION && applyNCPFilter) {
            soqlQuery += ' AND diagnosticDate__c != null';
        }
    
        // Filtre selon objet 
        if(String.isNotBlank(savId)) {
            soqlQuery += ' AND afterSalesService__c = :savId';
        }
        else if((isCommandeSAV != null && isCommandeSAV) || orderId != null){
            soqlQuery += ' AND Id IN :casesId';
        }
        else if(!assetsId.isEmpty()) {
            soqlQuery += ' AND AssetId IN :assetsId';
        }
        
        // Exécution        
        System.debug('## Query: '+soqlQuery);      
        result = Database.query(soqlQuery);
    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getProductsNonCompliance'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste des non-conformités produits (NCP ou PNC)
    * @param casesId Liste des Id des cases
    * @param activityType Type d'activité (controle, installation etc...) 
    * @return Liste d'enregistrement par défaut des non-conformités produits
    */
    @AuraEnabled(Cacheable = true)
    public static List<String> getNCPByDefault(List<String> casesId, String activityType){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getNCPByDefault'); 
        List<String> result = new List<String>();
        System.debug('## casesId: '+casesId);  
        System.debug('## activityType: '+activityType);
    
    
        // Cas où le type de RDV est Diagnostic
        if(!casesId.isEmpty() &&  activityType == 'Diagnostic'){
            System.debug('@@@@@@@@@@@@@@@@@@@@@DIAGNOSTIC');
    
            //Requête pour récupérer les Cases sans date de diagnostic
            List<Case> casesNoDiagDate = [SELECT Id FROM Case WHERE Id IN :casesId AND diagnosticDate__c=null];
            System.debug('@@@@@@@@@@@@@@@@@@@@@casesNoDiagDate size :'+casesNoDiagDate.size());
            
            
            
            /*
            ** Map pour savoir si le Case est relié à un WOLI
            ** CaseId -> true/fase
            ** true = relié à un WOLI, false = non relié à un WOLI
            */
            Map<String, Boolean> casesWithWOLI= new Map<String, Boolean>();
    
            //Map pour savoir si le case à une date de diagnostic
            Map<String, Boolean> casesIdNoDiagDate = new Map<String, Boolean>();
    
            /*
            ** Nécessaaire pour faire le lien SA -> WO -> CaseId
            */
            Map<String,Set<String>> WoIdCaseId = new Map<String,Set<String>>();
    
            //Initialisation
            for(String caseId : casesId){
                System.debug('@@@@@@@@@@@@@@@@@@@@@CaseId '+caseId); 
                casesWithWOLI.put(caseId, false);
            }
            
    
            for(Case caseNoDiagDate : casesNoDiagDate){
                casesIdNoDiagDate.put(caseNoDiagDate.id, true);
            }
    
            //Set de CasesID sans date de diagnostic
            Set<String> casesIdWithWoli = casesWithWoli.keySet();
    
            //Regarder les Wolis lié à un case
            List<WorkOrderLineItem> wolis = [SELECT Id, WorkOrderId, productNonCompliance__c 
            FROM WorkOrderLineItem WHERE productNonCompliance__c IN :casesIdWithWoli];
            System.debug('@@@@@@@@@@@@@@@@@@@@@wolis size :'+wolis.size()); 
    
            for(WorkOrderLineItem woli : wolis){
                if(casesWithWoli.containsKey(woli.productNonCompliance__c)){
                    //Case lié à un WOLI
                    casesWithWoli.put(woli.productNonCompliance__c, true);
                    //On met à jour le lien entre le WO et Case
                    if(!WoIdCaseId.containsKey(woli.WorkOrderId)){
                        WoIdCaseId.put(woli.WorkOrderId, new Set<String>());
                        WoIdCaseId.get(woli.WorkOrderId).add(woli.productNonCompliance__c);
                    }
                    else{
                        WoIdCaseId.get(woli.WorkOrderId).add(woli.productNonCompliance__c);
                    }
                }
            }
    
            //Les Cases non lié à un WOLI ET sans date de Diag  , on les ajoute à result
            for(String caseId : casesWithWoli.keySet()){
                if(casesWithWoli.get(caseId)==false && casesIdNoDiagDate.containsKey(caseId)){
                    System.debug('@@@@@@@@@@@@@@@@@@@@@CaseId NoDiag NoWOLI '+caseId); 
                    result.add(caseId);
                }
            }
    
            //Permet de savoir si un WO est lié à un SA
            Map<String, Boolean> WOWithSA= new Map<String, Boolean>();
            for(String WOId : WoIdCaseId.keySet()){
                WOWithSA.put(WOId, false);
            }
    
            Set<String> WOsId = WOWithSA.keySet();
            //Set de WOid avec SA dont le statut est "Terminé"
            Set<ServiceAppointment> SetWOidWithSAStatusTermine = new Set<ServiceAppointment>();
    
            //Requête pour les SA
            List<ServiceAppointment> SAs = [SELECT Id, ParentRecordId, Status FROM ServiceAppointment
                                           WHERE ParentRecordId IN :WOsId];
                                           System.debug('@@@@@@@@@@@@@@@@@@@@@SA size :'+SAs.size()); 
            for(ServiceAppointment sa : SAs){
                if(WOWithSA.containsKey(sa.ParentRecordId)){
                    WOWithSA.put(sa.ParentRecordId, true);
    
                    if(sa.Status=='Terminé' || sa.Status=='Annulé' || sa.Status=='Débriefé'){
                        SetWOidWithSAStatusTermine.add(sa);
                    }
                }
            }
            
            //Si le WO n'est pas lié à un SA ET n'a pas de date de diag, on ajoute tous les Cases lié à ce WO au résultat
            for(String WOId : WOsId){
                //Si le WO n'est pas lié à un SA
                if(WOWithSA.get(WOId)==false){
                    for(String caseId : WoIdCaseId.get(WOId)){
                        //S'il n'a pas de date de diag
                        if(casesIdNoDiagDate.containsKey(caseId)){
                            if(!result.contains(caseId)){
                                result.add(caseId);
                            }
                        }
                    }
                }
            }
            
            //SA Statut terminé et sans date de diag, on met les Cases associé dans result
            for(ServiceAppointment SAStatusTermine: SetWOidWithSAStatusTermine){
                if(WOWithSA.containsKey(SAStatusTermine.ParentRecordId)){
                    for(String caseId : WoIdCaseId.get(SAStatusTermine.ParentRecordId)){
                        if(casesIdNoDiagDate.containsKey(caseId)){
                            if(!result.contains(caseId)){
                                result.add(caseId);
                            }
                        }
                    }
                }
            }
        }
        //*********Cas type de RDV = INTERVENTION
        if(!casesId.isEmpty() &&  activityType == 'Intervention') {
    
            System.debug('@@@@@@@@@@@@@@@@@@@@@INTERVENTION'); 
            /*
            ** Map pour savoir si le Case est relié à un WOLI
            ** CaseId -> true/fase
            ** true = relié à un WOLI, false = non relié à un WOLI
            */
            Map<String, Boolean> casesWithWOLI= new Map<String, Boolean>();
            for(String caseId : casesId){
                System.debug('@@@@@@@@@@@@@@@@@@@@@CaseId '+caseId); 
                casesWithWOLI.put(caseId, false);
            }
    
            /*
            ** Nécessaaire pour faire le lien SA -> WO -> CaseId
            */
            Map<String,Set<String>> WoIdCaseId = new Map<String,Set<String>>();
    
            //Regarder les Wolis lié à un case
            System.debug('@@@@@@@@@@@@@@@@@@@@@Regarder les Wolis lié à un case'); 
            List<WorkOrderLineItem> wolis = [SELECT Id, WorkOrderId, productNonCompliance__c 
            FROM WorkOrderLineItem WHERE productNonCompliance__c IN :casesId];
            for(WorkOrderLineItem woli : wolis){
                //Case lié à un WOLI
                if(casesWithWoli.containsKey(woli.productNonCompliance__c)){
                    System.debug('@@@@@@@@@@@@@@@@@@@@@CASE CONTAIN WOLI (woliId) : '+woli.Id); 
                    casesWithWoli.put(woli.productNonCompliance__c, true);
                    //On met à jour le lien entre le WO et Case
                    if(!WoIdCaseId.containsKey(woli.WorkOrderId)){
                        WoIdCaseId.put(woli.WorkOrderId, new Set<String>());
                        WoIdCaseId.get(woli.WorkOrderId).add(woli.productNonCompliance__c);
                    }
                    else{
                        WoIdCaseId.get(woli.WorkOrderId).add(woli.productNonCompliance__c);
                    }
                }
            }
    
            //Les Cases non lié à un WOLI , on les ajoute à result
            for(String caseId : casesWithWoli.keySet()){
                if(casesWithWoli.get(caseId)==false){
                    System.debug('@@@@@@@@@@@@@@@@@@@@@caseId NON LIE WOLI '+caseId); 
                    result.add(caseId);
                }
            }
    
            //Permet de savoir si un WO est lié à un SA
            Map<String, Boolean> WOWithSA= new Map<String, Boolean>();
            for(String WOId : WoIdCaseId.keySet()){
                WOWithSA.put(WOId, false);
            }
    
            Set<String> WOsId = WOWithSA.keySet();
    
            //Set de WOid avec SA dont le statut est "Terminé"
            Set<ServiceAppointment> SetWOidWithSAStatusTermine = new Set<ServiceAppointment>();
    
            //Get SA linked with our WO
            List<ServiceAppointment> SAs = [SELECT Id, ParentRecordId, Status FROM ServiceAppointment
                                           WHERE ParentRecordId IN :WOsId];
            for(ServiceAppointment sa : SAs){
                if(WOWithSA.containsKey(sa.ParentRecordId)){
                    WOWithSA.put(sa.ParentRecordId, true);
    
                    if(sa.Status=='Terminé'){
                        SetWOidWithSAStatusTermine.add(sa);
                    }
                }
            }
            
            //Si le WO n'est pas lié à un SA, on ajoute tous les Cases lié à ce WO au résultat
            for(String WOId : WOsId){
                if(WOWithSA.get(WOId)==false){
                    for(String caseId : WoIdCaseId.get(WOId)){
                        if(!result.contains(caseId)){
                            result.add(caseId);
                        }
                    }
                }
            }
            
            //SA Statut terminé, on met les Cases associé dans result
            for(ServiceAppointment SAStatusTermine: SetWOidWithSAStatusTermine){
                if(WOWithSA.containsKey(SAStatusTermine.ParentRecordId)){
                    for(String caseId : WoIdCaseId.get(SAStatusTermine.ParentRecordId)){
                        if(!result.contains(caseId)){
                            result.add(caseId);
                        }
                    }
                }
            }
        }
    
        else {
            
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getProductsNonCompliance'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste des compétences pour FSL selon les produits et le type d'activité
    * @param assetsId Liste des Id des assets
    * @param workTypeName Nom du type de travail
    * @param withNCP Le RDV a des NPC, il faut retourner aussi la compétence "SAV"
    * @return Liste des lignes de compétences avec pré-sélection si le produit à la compétence et/ou le type d'activité
    */
    @AuraEnabled(Cacheable = true)
    public static List<SkillResult> getSkills(List<String> assetsId, String workTypeName, Boolean withNCP){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getSkills'); 
        List<SkillResult> result = new List<SkillResult>();
        Map<String, ProductSkill__c> skillsProdList = new Map<String, ProductSkill__c>();
        Map<String, SkillRequirement> skillsReqList = new Map<String, SkillRequirement>();
        System.debug('## assetsId: '+assetsId); 
        System.debug('## workTypeName: '+workTypeName); 
        System.debug('## withNCP: '+withNCP); 
        
        // Récupération des skills requis pour le type d'activité
        for(SkillRequirement reqSkill : [SELECT Id, SkillId, SkillLevel FROM SkillRequirement 
                                            WHERE RelatedRecordId IN (SELECT Id FROM WorkType WHERE Name = :workTypeName)]) {
            skillsReqList.put(reqSkill.SkillId, reqSkill);
        } 
        System.debug('## skillsReqList: '+skillsReqList);     
    
        // Récupération des skills requis pour chaque produits sélectionnés
        List<Product2> prodList = [SELECT Id FROM Product2 WHERE Id IN (SELECT Product2Id FROM Asset WHERE Id IN :assetsId)];
        List<Asset> assetList = [SELECT Id, Product2Id, orderItem__r.eligibleESC__c, SBQQ__OrderProduct__r.eligibleESC__c FROM Asset WHERE Id IN :assetsId]; 
        for(ProductSkill__c prodSkill : [SELECT Id, skill__c, skillLevel__c, product__c FROM ProductSkill__c WHERE product__c IN :prodList]) {
            skillsProdList.put(prodSkill.skill__c, prodSkill);
        }     
        System.debug('## skillsProdList: '+skillsProdList);   
    
        // Récupération des compétences
        for(SKill sk : [SELECT Id, MasterLabel FROM Skill ORDER BY MasterLabel]) {
            Decimal skillLevel = null;
            // Skills requis par le type d'activité
            if(!skillsReqList.isEmpty() && skillsReqList.get(sk.Id) != null) {
                skillLevel = skillsReqList.get(sk.Id).SkillLevel;
            }
            // Skills requis par les produits
            if(!skillsProdList.isEmpty() && skillsProdList.get(sk.Id) != null) {
                skillLevel = skillsProdList.get(sk.Id).skillLevel__c;
            }
            // Skill "SAV" requis supplémentaire s'il y a des NCP
            if(withNCP && sk.MasterLabel == 'SAV') {
                skillLevel = 1;
            }
    
            // Skill "RGE" requis supplémentaire si la ligne de commande est éligible CEE et RDV != Diagnostic
            if(sk.MasterLabel == 'RGE' && workTypeName != Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
                for(Asset ast : assetList){
                    if(((ast.orderItem__c != null && ast.orderItem__r.eligibleESC__c) || 
                    (ast.SBQQ__OrderProduct__c != null && ast.SBQQ__OrderProduct__r.eligibleESC__c))){
                        skillLevel = 1;
                    }
                }
            }
            result.add(new SkillResult(sk.Id, sk.MasterLabel, skillLevel));
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getSkills'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste des intervenants du dépot de la commande client ou d'un chantier
    * @param recordId Id de l'enregistrement
    * @param objectApiName Nom API de l'objet
    * @param activityType Type d'activité (controle, installation etc...) 
    * @param skills Liste des compétences avec leu niveau nécessaire 
    * @return Liste des intervenants du dépot 
    */
    @AuraEnabled(Cacheable = true)
    public static List<ServiceTerritoryMember> getTechnicians(String recordId, String objectApiName, String activityType, List<Map<String, String>> skills){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.getTechnicians'); 
        Set<ServiceTerritoryMember> result = new Set<ServiceTerritoryMember>();
        List<ServiceTerritoryMember> resultFinal = new List<ServiceTerritoryMember>();
        List<ServiceTerritoryMember> servResList = new List<ServiceTerritoryMember>();
        List<String> serviceResourceIds = new List<String>();
        Map<String, List<ServiceResourceSkill>> mapServiceResourceSkill = new Map<String, List<ServiceResourceSkill>>();
        System.debug('## recordId: '+recordId);
        System.debug('## objectApiName: '+objectApiName);
        System.debug('## skills: '+skills);
        System.debug('## activityType: '+activityType);
        String serviceTerritoryId = null; 
    
        // Récupération de l'Id du dépot (territoire de service)
        if(objectApiName == 'Order') {
            List<Order> recordsList = [SELECT Id, serviceEntity__r.serviceTerritory__c FROM Order WHERE Id = :recordId LIMIT 1];
            serviceTerritoryId = recordsList[0].serviceEntity__r.serviceTerritory__c;
        } else if(objectApiName == 'Chantier__c') {
            List<Chantier__c> recordsList = [SELECT Id, serviceEntity__r.serviceTerritory__c FROM Chantier__c WHERE Id = :recordId LIMIT 1];
            serviceTerritoryId = recordsList[0].serviceEntity__r.serviceTerritory__c;
        } else if(objectApiName == 'AfterSalesService__c') {
            List<AfterSalesService__c> sav = [SELECT Id, workSite__c FROM AfterSalesService__c WHERE Id = :recordId LIMIT 1];
            List<Chantier__c> recordsList = [SELECT Id, serviceEntity__r.serviceTerritory__c FROM Chantier__c WHERE Id = :sav[0].workSite__c LIMIT 1];
            serviceTerritoryId = recordsList[0].serviceEntity__r.serviceTerritory__c;
        }
        // Récupération des ressources
        if(serviceTerritoryId != null) {
            // Récupération de toutes les ressources du territoire de service
            System.debug('## serviceTerritoryId: '+serviceTerritoryId); 
            String query = 'SELECT Id, ServiceResource.Name, ServiceResourceId ' +
                            ' FROM ServiceTerritoryMember WHERE ServiceTerritoryId = \''+ serviceTerritoryId + '\' '+
                            ' AND ServiceResource.IsActive = true AND ServiceResource.RelatedRecord.IsActive = true '+
                            ' AND (EffectiveStartDate <= TODAY AND (EffectiveEndDate > TODAY OR EffectiveEndDate = null)) ';
            query += ' ORDER BY ServiceResource.Name';
            System.debug('## query: '+query); 
            servResList = Database.query(query);
            
            for(ServiceTerritoryMember STM : servResList) {
                serviceResourceIds.add(STM.ServiceResourceId);
            }
            
            // Récupération de toutes les compétences des ressources du territoire de service
            for(ServiceResourceSkill srs : [SELECT Id, ServiceResourceId, SkillLevel, SkillId, Skill.DeveloperName 
                                                FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResourceIds]) {
                List<ServiceResourceSkill> SRSAllList = mapServiceResourceSkill.get(srs.ServiceResourceId);
                if(SRSAllList == null) {
                    SRSAllList = new List<ServiceResourceSkill>();
                }
                SRSAllList.add(srs);
                mapServiceResourceSkill.put(srs.ServiceResourceId, SRSAllList);
            }
            System.debug('## mapServiceResourceSkill: '+mapServiceResourceSkill); 
            
            if(activityType != 'ALL' && mapServiceResourceSkill != null) {
                for(ServiceTerritoryMember STM : servResList) {
                    Integer nbOk = 0;
                    if(mapServiceResourceSkill.get(STM.ServiceResourceId) != null) {
                        System.debug('## ServiceTerritoryMember: '+STM.Id+' / '+STM.ServiceResourceId+' / '+STM.ServiceResource.Name); 
                        for(ServiceResourceSkill srs : mapServiceResourceSkill.get(STM.ServiceResourceId)) {
                            for(Map<String,String> skill : skills) {
                                if (skill.get('id') == srs.SkillId && Integer.valueOf(skill.get('value')) <= srs.SkillLevel) {
                                    nbOK++;
                                }
                            }
                        }
                        if(nbOk == skills.size()) {
                            System.debug('## STM.Id : ' + STM.Id);
                            result.add(STM);
                        }
                    }
                }
            } else {
                result.addAll(servResList);
            }         
        }        
        resultFinal.addAll(result);
        System.debug('## result: '+resultFinal); 
        System.debug('### FIN LWC_CustomWorkOrderWizard.getTechnicians'); 
        return resultFinal;
    }
    
    /**
    * @description Fonction de calcul de la date au plus tot pour un chantier
    * @param assetsId Liste des Id des actifs sélectionnés par l'utilisateur
    * @param ncpsId Liste des Id des NCP sélectionnées par l'utilisateur
    * @return Date max de la date au plus tôt de chaque commande client dont un actif participe au RDV
    */
    @AuraEnabled
    public static Date calculateEarliestStartDateChantier(List<String> assetsId, List<String> ncpsId) {
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.earliestStartDateChantier'); 
        Date result = null;
        System.debug('## assetsId: '+assetsId);
        System.debug('## ncpsId: '+ncpsId);
    
        // Récupération des ID des actifs si c'est un dossier SAV
        if(ncpsId != null && !ncpsId.isEmpty()) {
            for(Case newCase : [SELECT Id, AssetId FROM Case WHERE Id IN :ncpsId]) {
                assetsId.add(newCase.AssetId);
            }
        }
        
        // Récupération des dates de commande si actif présent
        if(assetsId != null && !assetsId.isEmpty()) {
            List<Date> earliestDates = new List<Date>();
            for(Asset ast : [SELECT Id, customerOrder__c, customerOrder__r.EffectiveDate FROM Asset WHERE Id IN: assetsId]) {
                System.debug('## Asset: '+ast.Id + ' - ' + ast.customerOrder__c + ' - '+ ast.customerOrder__r.EffectiveDate);
                if(String.isNotBlank(ast.customerOrder__c)) {
                    earliestDates.add(ast.customerOrder__r.EffectiveDate);
                }
            }
            System.debug('## earliestDates: '+earliestDates);
            
            // Si date présentes, on les tri et on récupère la plus grande
            if(!earliestDates.isEmpty()) {
                earliestDates.sort(); 
                result = earliestDates[earliestDates.size()-1];
            }
        }
        System.debug('## result: '+result);
        System.debug('### FIN LWC_CustomWorkOrderWizard.earliestStartDateChantier'); 
        return result;
    }
    
    /**
    * @description Fonction principal de création de la demande de rendez-vous (WorkOrder)
    * @param recordId Id de la commande
    * @param assetsId Liste des Id des assets sélectionnés par l'utilisateur
    * @param skills Liste des lignes de compétences définies par l'utilisateur
    * @param ressources Liste des intervenants définis par l'utilisateur
    * @param ncpsId Liste des Id des NCP sélectionnés par l'utilisateur
    * @param mapParameters Objet contenant les informations saisi depuis l'assistant
    * @return Id de l'enregistrement SA créé sinon null
    */
    @AuraEnabled
    public static String createWorkOrder(String recordId, List<String> assetsId, List<Map<String, String>> skills,
                                            List<Map<String, String>> ressources, List<String> ncpsId, Map<String, String> mapParameters){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createWorkOrder'); 
        String result;        
        Datetime workOrderStartDate;
        Datetime saDueDate;
        String visitingHoursId = null;
        List<Asset> assetsList = new List<Asset>();
        String workOrderId;
        String saId;
        List<String> saIdList = new List<String>();
        List<FSL__Time_Dependency__c> dependenciesToCreate = new List<FSL__Time_Dependency__c>();        
        EntityWorkTypeParameters__c workTypeParameter = new EntityWorkTypeParameters__c();
        Integer nbCaseSAV = 0;
        Integer nbCaseECI = 0;
        System.debug('## recordId: '+recordId); 
        System.debug('## assetsId: '+assetsId); 
        System.debug('## skills: '+skills); 
        System.debug('## ressources: '+ressources); 
        System.debug('## ncpsId: '+ncpsId); 
        System.debug('## mapParameters: '+mapParameters); 
    
        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();
    
        try {
            String wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
            String priceBookId = Label.system_id_pricebookentry_standard;
    
            // Récupération des parametres
            String workTypeParametersId = mapParameters.get('workTypeParametersId');
            String workOrderPriority = mapParameters.get('workOrderPriority');
            String workOrderDurationType = mapParameters.get('workOrderDurationType');
            Integer workOrderDuration = (String.isBlank(mapParameters.get('workOrderDuration'))) ? null : Integer.valueOf(mapParameters.get('workOrderDuration'));
            Integer workOrderMinimumCrewSize = (String.isBlank(mapParameters.get('workOrderMinimumCrewSize'))) ? null : Integer.valueOf(mapParameters.get('workOrderMinimumCrewSize'));
            String workOrderContactId = mapParameters.get('workOrderContactId');
            
            // Processus des dates
            String workOrderEarliestStartDate = mapParameters.get('workOrderEarliestStartDate');
            System.debug('workOrderEarliestStartDate : ' + workOrderEarliestStartDate);
            if(String.isNotBlank(workOrderEarliestStartDate)) {
                workOrderStartDate = Datetime.valueOf(workOrderEarliestStartDate+' 00:00:00');
            } 
    
            // Récupération du worktype et subWorkType
            String workTypeName = mapParameters.get('workType');
            String subWorkType = mapParameters.get('subWorkType');
            WorkType wkType = [SELECT Id, Name, autoSchedulingDelay__c FROM WorkType WHERE Name = :workTypeName LIMIT 1];
            System.debug('## subWorkType: ' + subWorkType);
            System.debug('## Work Type: '+wkType); 
    
            // Récupération     des infos de l'enregistrement
            List<Order> ordersList = [SELECT Id, serviceEntity__c, AccountId, Account.Name, ShipToContactId, chantier__c, OrderNumber,
                                            chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c, chantier__r.pays__c, chantier__r.complementAdresse__c,
                                            ShippingStreet, ShippingCity, ShippingPostalCode, Pricebook2Id, serviceEntity__r.serviceTerritory__c,
                                            chantier__r.occupant__c, chantier__r.autreOccupant__c, chantier__r.locataire__c, chantier__r.autreLocataire__c,
                                            chantier__r.occupant__r.contactParDefaut__c, chantier__r.autreOccupant__r.contactParDefaut__c, 
                                            chantier__r.locataire__r.contactParDefaut__c, chantier__r.autreLocataire__r.contactParDefaut__c,
                                            chantier__r.proprietaire__r.contactParDefaut__c,Type,afterSalesService__c
                                        FROM Order WHERE Id = :recordId LIMIT 1];
            List<Chantier__c> chantiersList = [SELECT Id, serviceEntity__c, proprietaire__c, proprietaire__r.Name, proprietaire__r.contactParDefaut__c,
                                            rue__c, codePostal__c, ville__c, pays__c, complementAdresse__c, serviceEntity__r.serviceTerritory__c,
                                            occupant__r.contactParDefaut__c, autreOccupant__r.contactParDefaut__c, 
                                            locataire__r.contactParDefaut__c, autreLocataire__r.contactParDefaut__c
                                        FROM Chantier__c WHERE Id = :recordId LIMIT 1];
            List<AfterSalesService__c> savsList = [SELECT Id, workSite__r.serviceEntity__c, workSite__r.proprietaire__c, workSite__r.proprietaire__r.Name, 
                                                   workSite__r.proprietaire__r.contactParDefaut__c,
                                                   workSite__r.rue__c, workSite__r.codePostal__c, workSite__r.ville__c, workSite__r.pays__c, 
                                                   workSite__r.serviceEntity__r.serviceTerritory__c, workSite__c
                                        FROM AfterSalesService__c WHERE Id = :recordId LIMIT 1];
            if(workTypeParametersId != null) {
                workTypeParameter = [SELECT Id, autoSchedulingDelay__c, dueDateDelay__c, workType__r.FSL__Due_Date_Offset__c FROM EntityWorkTypeParameters__c WHERE Id = :workTypeParametersId];
            }
                                        
            if(!savsList.isEmpty()) {
                recordId = savsList[0].workSite__c;
                chantiersList = [SELECT Id, serviceEntity__c, proprietaire__c, proprietaire__r.Name, proprietaire__r.contactParDefaut__c,
                                            rue__c, codePostal__c, ville__c, pays__c, serviceEntity__r.serviceTerritory__c, complementAdresse__c
                                        FROM Chantier__c WHERE Id = :recordId LIMIT 1];
            }
            
            System.debug('## Work Order Start Date: '+workOrderStartDate); 
            String workOrderDueDate = mapParameters.get('workOrderDueDate');
            System.debug('workOrderDueDate : ' + workOrderDueDate);
            if(String.isNotBlank(workOrderDueDate)) {
                saDueDate = Datetime.valueOf(workOrderDueDate+' 23:59:59');
            }
            System.debug('## Work Order Due Date: '+saDueDate);
    
            String description = wkType.Name + ' pour les produits suivants :\n';
            if(wkType.Name == 'Intervention' || wkType.autoSchedulingDelay__c == null || workTypeParametersId == null || (workTypeParameter != null && workTypeParameter.autoSchedulingDelay__c == null)) {
                //* Création du RDV sur Commande
                if(!ordersList.isEmpty()) {
                    System.debug('## Création du workOrder via commande');
                    // Processus de gestion des heures de visite
                    String visitingStartHour = mapParameters.get('workOrderVisitingStartHour');
                    String visitingEndHour = mapParameters.get('workOrderVisitingEndHour');
                    if(String.isNotBlank(mapParameters.get('workOrderVisitingDays')) && String.isNotBlank(visitingStartHour) && String.isNotBlank(visitingEndHour)) {
                        List<String> dayNameList = mapParameters.get('workOrderVisitingDays').split(',');
                        visitingHoursId = createAccountOperatingHours(ordersList[0].AccountId, dayNameList, visitingStartHour, visitingEndHour);
                    }
    
                    // Récupération des assets
                    assetsList = [SELECT Id, Product2Id, Name FROM Asset WHERE Id IN :assetsId AND isLocked__c = false];
                    System.debug('## assetsList: '+assetsList); 
                    // Construction de la description
                    for(Asset ast : assetsList) {
                        description += ast.Name + ' ';
                    }
    
                    // Création du work order
                    WorkOrder wk = new WorkOrder(Subject = ordersList[0].Account.Name,
                                                    Description = description,
                                                    StartDate = workOrderStartDate.addHours(3),
                                                    EndDate = saDueDate,
                                                    AccountId = ordersList[0].AccountId,
                                                    ContactId = (String.isBlank(workOrderContactId)) ? ordersList[0].ShipToContactId : workOrderContactId,
                                                    Pricebook2Id = ordersList[0].Pricebook2Id,
                                                    customerOrder__c = ordersList[0].Id,
                                                    ServiceTerritoryId = ordersList[0].serviceEntity__r.serviceTerritory__c,
                                                    RecordTypeId = wkRTId,
                                                    WorkTypeId = wkType.Id,
                                                    FSL__VisitingHours__c = visitingHoursId,
                                                    DurationType = workOrderDurationType,
                                                    Duration = workOrderDuration,
                                                    Priority = workOrderPriority,
                                                    MinimumCrewSize = workOrderMinimumCrewSize,
                                                    RecommendedCrewSize = workOrderMinimumCrewSize,
                                                    chantier__c = ordersList[0].chantier__c,
                                                    PostalCode = ordersList[0].chantier__r.codePostal__c,
                                                    City = ordersList[0].chantier__r.ville__c,
                                                    Country = ordersList[0].chantier__r.pays__c,
                                                    Street = ordersList[0].chantier__r.rue__c,
                                                    additionalAddress__c = ordersList[0].chantier__r.complementAdresse__c,
                                                    fsl_ExternalId__c = ordersList[0].OrderNumber,
                                                    subWorkType__c = subWorkType
                                                    );
                    
                        //Attribution du dossier Sav au RDV si commande SAV
                        if(ordersList[0].Type == 'Commande SAV' && ordersList[0].afterSalesService__c != null){
                            wk.afterSalesService__c = ordersList[0].afterSalesService__c;
                        }
                        if(!savsList.isEmpty()){
                        System.debug('affectation sav workOrder');
                        wk.afterSalesService__c = savsList[0].Id;
                    }
                    System.debug('## wk: '+wk); 
                    insert wk;
                    workOrderId = wk.Id;
                    System.debug('## workOrderId: '+workOrderId); 
    
                    // Création des compétences requises
                    createSkillsRequired(wk.Id, skills);
    
                    // Création des ressources préférées
                    createResourcePreference(wk.Id, ressources);
                    
                    // Création des lignes
                    createWorkOrderLineItems(wk.Id, assetsList, ncpsId);
    
                    // Création du RDV
                    string idChantier;
                    idChantier = ordersList[0].chantier__c;
                    // Si plusieurs intervenants, on créé n RDV par intervenant
                    List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
                    for(Integer i=1 ; i <= workOrderMinimumCrewSize; i++) {
                        ServiceAppointment saToUpdate = new ServiceAppointment();
                        saToUpdate = createServiceAppointment(wk, idChantier, i, mapParameters);
                        saToUpdateList.add(saToUpdate);                        
                    }
                    upsert saToUpdateList;
                    for(ServiceAppointment sa : saToUpdateList){
                        saIdList.add(sa.Id);
                        saId = sa.Id;
                    }
                }
                
                //* Création du RDV sur Chantier 
                if(!chantiersList.isEmpty()) {
                    System.debug('## Création du workOrder via chantier');
                    // Processus de gestion des heures de visite
                    String visitingStartHour = mapParameters.get('workOrderVisitingStartHour');
                    String visitingEndHour = mapParameters.get('workOrderVisitingEndHour');
                    if(String.isNotBlank(mapParameters.get('workOrderVisitingDays')) && String.isNotBlank(visitingStartHour) && String.isNotBlank(visitingEndHour)) {
                        List<String> dayNameList = mapParameters.get('workOrderVisitingDays').split(',');
                        visitingHoursId = createAccountOperatingHours(chantiersList[0].proprietaire__c, dayNameList, visitingStartHour, visitingEndHour);
                    }
                    // Récupération des assets
                    if(assetsId.isEmpty()) {
                        for(Case newCase : [SELECT Id, AssetId FROM Case WHERE Id IN :ncpsId]) {
                            assetsId.add(newCase.AssetId);
                        }
                    }
                    assetsList = [SELECT Id, Product2Id, Name, InstallDate FROM Asset WHERE Id IN :assetsId AND isLocked__c = false];
                    System.debug('## assetsList: '+assetsList);                     
                    // Construction de la description
                    for(Asset ast : assetsList) {
                        description += ast.Name + ' ';
                    }
    
                    // Création du work order
                    WorkOrder wk = new WorkOrder(Subject = chantiersList[0].proprietaire__r.Name,
                                                    Description = description,
                                                    StartDate = workOrderStartDate,
                                                    EndDate = saDueDate,
                                                    AccountId = chantiersList[0].proprietaire__c,
                                                    ContactId = (String.isBlank(workOrderContactId)) ? chantiersList[0].proprietaire__r.contactParDefaut__c : workOrderContactId,
                                                    Pricebook2Id = priceBookId,
                                                    ServiceTerritoryId = chantiersList[0].serviceEntity__r.serviceTerritory__c,
                                                    RecordTypeId = wkRTId,
                                                    WorkTypeId = wkType.Id,
                                                    FSL__VisitingHours__c = visitingHoursId,
                                                    DurationType = workOrderDurationType,
                                                    Duration = workOrderDuration,
                                                    Priority = workOrderPriority,
                                                    MinimumCrewSize = workOrderMinimumCrewSize,
                                                    RecommendedCrewSize = workOrderMinimumCrewSize,
                                                    chantier__c = chantiersList[0].Id,
                                                    PostalCode = chantiersList[0].codePostal__c,
                                                    City = chantiersList[0].ville__c,
                                                    Country = chantiersList[0].pays__c,
                                                    additionalAddress__c = chantiersList[0].complementAdresse__c,
                                                    Street = chantiersList[0].rue__c,
                                                    subWorkType__c = subWorkType
                                                    );
                    if(!savsList.isEmpty()){
                        wk.afterSalesService__c = savsList[0].Id;
                    }
                    System.debug('## wk: '+wk); 
                    insert wk;
                    workOrderId = wk.Id;
                    System.debug('## workOrderId: '+workOrderId); 
    
                    // Création des compétences requises
                    createSkillsRequired(wk.Id, skills);
    
                    // Création des ressources préférées
                    createResourcePreference(wk.Id, ressources);
                    
                    // Création des lignes
                    createWorkOrderLineItems(wk.Id, assetsList, ncpsId);
    
                    // Création du RDV
                    String idChantier;
                    idChantier = chantiersList[0].Id;
                    // Si plusieurs intervenants, on créé n RDV par intervenant
                    List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
                    for(Integer i=1 ; i <= workOrderMinimumCrewSize; i++) {
                        ServiceAppointment saToUpdate = new ServiceAppointment();
                        saToUpdate = createServiceAppointment(wk, idChantier, i, mapParameters);
                        saToUpdateList.add(saToUpdate);                        
                    }
                    upsert saToUpdateList;
                    for(ServiceAppointment sa : saToUpdateList){
                        saIdList.add(sa.Id);
                        saId = sa.Id;
                    }
                }
            } else if((wkType.Name == 'Diagnostic' || wkType.Name == 'Métrage') && workTypeParameter != null && workTypeParameter.autoSchedulingDelay__c == null) {
                if(!ordersList.isEmpty()) {
                    Date todayDate = date.today();
                    Date delayDate;
                    if(workTypeParameter.autoSchedulingDelay__c != null) {
                        delayDate = date.today().addDays(Integer.valueOf(workTypeParameter.autoSchedulingDelay__c));
                    } else {
                        delayDate = date.today().addDays(1);
                    }
                    PendingOperation__c newOperation = new PendingOperation__c(chantier__c = ordersList[0].chantier__c,
                                                                               account__c = ordersList[0].AccountId,
                                                                               operationExecutionDate__c = delayDate,
                                                                               operationScheduleDate__c = delayDate,
                                                                               assetsList__c = JSON.serialize(assetsList),
                                                                               mapParameters__c = JSON.serialize(mapParameters),
                                                                               ncpsId__c = string.valueOf(ncpsId),
                                                                               ressourcePreference__c = JSON.serialize(ressources),
                                                                               skillsRequired__c = JSON.serialize(skills),
                                                                               Mode__c = 'Process',
                                                                               Type__c = 'Planification rendez-vous service',
                                                                               workType__c = wkType.Id);
                    insert newOperation;
                }
                
                if(!chantiersList.isEmpty()) {
                    Date todayDate = date.today();
                    Date delayDate = date.today().addDays(Integer.valueOf(workTypeParameter.autoSchedulingDelay__c));
                    PendingOperation__c newOperation = new PendingOperation__c(chantier__c = chantiersList[0].Id,
                                                                               account__c = chantiersList[0].proprietaire__c,
                                                                               //operationExecutionDate__c = delayDate,
                                                                               operationScheduleDate__c = delayDate,
                                                                               assetsList__c = JSON.serialize(assetsList),
                                                                               mapParameters__c = JSON.serialize(mapParameters),
                                                                               ncpsId__c = string.valueOf(ncpsId),
                                                                               ressourcePreference__c = JSON.serialize(ressources),
                                                                               skillsRequired__c = JSON.serialize(skills),
                                                                               Mode__c = 'Process',
                                                                               Type__c = 'Planification rendez-vous service',
                                                                               workType__c = wkType.Id);
                    insert newOperation;
                }
            }
            
            // Si plusieurs intervenants, on créé une dépendance entre les RDV
            System.debug('## workOrderMinimumCrewSize: '+workOrderMinimumCrewSize); 
            System.debug('## saIdList.size(): '+saIdList.size()); 
            System.debug('## saIdList: '+saIdList); 
            if(workOrderMinimumCrewSize > 1) {
                for(Integer index=0 ; index < saIdList.size(); index++) {
                    System.debug('## index: '+index); 
                    if(index < saIdList.size()-1) { // Si on atteint le dernier RDV de la liste, on ne créé pas de dépendance
                        System.debug('## saIdList[index]: '+saIdList[index]); 
                        dependenciesToCreate.add(new FSL__Time_Dependency__c(FSL__Service_Appointment_1__c = saIdList[index], 
                                                                        FSL__Service_Appointment_2__c = saIdList[index+1], 
                                                                        FSL__Dependency__c = 'Same Start', 
                                                                        FSL__Same_Resource__c = false));
                    }
                }
            }    
            if(!dependenciesToCreate.isEmpty()) {
                insert dependenciesToCreate;
            } 
    
            // Affiche le SA si un seul intervenant sinon la demande
            if(workOrderMinimumCrewSize > 1) {
                result = workOrderId;
            } else {
                result = saId;
            }
            System.debug('## result: '+result); 
            System.debug('### FIN LWC_CustomWorkOrderWizard.createWorkOrder'); 
            return result;
        } catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction de création des heures de visite du compte si définies par l'utilisateur
    * @param accId Id du compte
    * @param dayNameList Liste des noms des jours de visite
    * @param visitingStartHour Heure de début de visite
    * @param visitingEndHour Heure de fin de visite
    * @return Id de l'enregistrement OperatingHours
    */
    public static String createAccountOperatingHours(String accId, List<String> dayNameList, String visitingStartHour, String visitingEndHour){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createAccountOperatingHours'); 
        String result;
    
        try{
            List<TimeSlot> tsToInsert = new List<TimeSlot>();
            // Map conversion des jours
            Map<String, String> dayNameMap = new Map<String, String>{
                'Lundi' => 'Monday',
                'Mardi' => 'Tuesday',
                'Mercredi' => 'Wednesday',
                'Jeudi' => 'Thursday',
                'Vendredi' => 'Friday',
                'Samedi' => 'Saturday'
            };
            // Traduction du temps de String en Time
            List<String> visitingStartHourSplit = visitingStartHour.split(':');
            Time visitingStartHourTime = Time.newInstance(Integer.valueOf(visitingStartHourSplit[0]),Integer.valueOf(visitingStartHourSplit[1]),0,0);  
            List<String> visitingEndHourSplit = visitingEndHour.split(':');
            Time visitingEndHourrTime = Time.newInstance(Integer.valueOf(visitingEndHourSplit[0]),Integer.valueOf(visitingEndHourSplit[1]),0,0);  
            System.debug('## dayNameList: '+dayNameList); 
            System.debug('## visitingStartHourTime: '+visitingStartHourTime); 
            System.debug('## visitingEndHourrTime: '+visitingEndHourrTime); 
    
            // Récupération compte
            Account acc = [SELECT Id, Name, OperatingHoursId FROM Account WHERE Id = :accId LIMIT 1];
            System.debug('## OperatingHoursId: '+acc.OperatingHoursId); 
            // Vérification enregistrement existant
            if(String.isNotBlank(acc.OperatingHoursId)) {
                // Si existe, on supprime les tranches horaire pour les recréer
                List<TimeSlot> tsList = [SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlot WHERE OperatingHoursId = :acc.OperatingHoursId];
                if(!tsList.isEmpty()) {
                    delete tsList;
                }
                result = acc.OperatingHoursId;
            } else {
                // Sinon on crée l'enregistrement des visites
                OperatingHours opHours = new OperatingHours(Name = 'Client ' + acc.Name/*, fsl_dateOuverture__c = Date.today()*/);
                insert opHours;
                System.debug('## New OperatingHoursId: '+opHours.Id); 
                result = opHours.Id;
                // Mise à jour du compte avec l'ID des heures
                update new Account(Id = acc.Id, OperatingHoursId = result);
            }
    
            // Pour chaque jours définis, on créé une tranche horaire
            for(String dayNameFR : dayNameList) {
                String dayNameEN = dayNameMap.get(dayNameFR);
                TimeSlot ts = new TimeSlot(OperatingHoursId = result, DayOfWeek = dayNameEN, StartTime = visitingStartHourTime, EndTime = visitingEndHourrTime);
                System.debug('## TimeSlot: '+dayNameEN + ' - ' + visitingStartHourTime + ' - ' + visitingEndHourrTime); 
                tsToInsert.add(ts);
            }
            if(!tsToInsert.isEmpty()) {
                insert tsToInsert;
            }
    
            System.debug('## result: '+result); 
            System.debug('### FIN LWC_CustomWorkOrderWizard.createAccountOperatingHours'); 
            return result;
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction de création des compétences et association au WorkOrder
    * @param workOrderId Id de la demande de rendez-vous (WorkOrder)
    * @param skills Liste des Ids des compétences avec leur niveau requis
    */
    public static void createSkillsRequired(String workOrderId, List<Map<String, String>> skills){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createSkillsRequired'); 
        List<SkillRequirement> skillRequiredToInsert = new List<SkillRequirement>();
        Map<String, String> actualSkillsMap = new Map<String, String>();
    
        try{
            // Récupération des compétences de la demande
            for(SkillRequirement actSkill : [SELECT Id, SkillId FROM SkillRequirement WHERE RelatedRecordId = :workOrderId]) {
                actualSkillsMap.put(actSkill.SkillId, actSkill.Id);
            }
            System.debug('## Actual skills: '+actualSkillsMap); 
    
            // Pour chaque compétences, on créé une ligne de compétence requise
            for(Map<String,String> skill : skills) {
                SkillRequirement  skillReq = new SkillRequirement (SkillId = skill.get('id'), 
                                                                    RelatedRecordId = workOrderId, 
                                                                    SkillLevel = Integer.valueOf(skill.get('value')));
                // Si la compétence existe déjà, on met à jour l'enregistrement
                if(actualSkillsMap.get(skill.get('id')) != null) {
                    skillReq.Id = actualSkillsMap.get(skill.get('id'));
                }
                System.debug('## Skill: '+skillReq); 
                skillRequiredToInsert.add(skillReq);
            }
            if(!skillRequiredToInsert.isEmpty()) {
                upsert skillRequiredToInsert;
            }
    
            System.debug('### FIN LWC_CustomWorkOrderWizard.createSkillsRequired'); 
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction de création des intervenants et association au WorkOrder
    * @param workOrderId Id de la demande de rendez-vous (WorkOrder)
    * @param resources Liste des Ids des intervenants avec leur présences
    */
    public static void createResourcePreference(String workOrderId, List<Map<String, String>> resources){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createResourcePreference'); 
        List<ResourcePreference> resourcePrefToInsert = new List<ResourcePreference>();
    
        try {
            // Pour chaque intervenant, on créé une préférence
            for(Map<String,String> resource : resources) {
                ResourcePreference ressPref = new ResourcePreference(ServiceResourceId = resource.get('id'), 
                                                                    RelatedRecordId = workOrderId, 
                                                                    PreferenceType = resource.get('value'));
                System.debug('## Ressource: '+ressPref); 
                resourcePrefToInsert.add(ressPref);
            }
            if(!resourcePrefToInsert.isEmpty()) {
                insert resourcePrefToInsert;
            }
    
            System.debug('### FIN LWC_CustomWorkOrderWizard.createResourcePreference'); 
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction de création des ligne du WorkOrder
    * @param workOrderId Id de la demande de rendez-vous (WorkOrder)
    * @param assetsList Liste des actifs sélectionnés par l'utilisateur
    * @param ncpsId Liste des Id des NCP sélectionnés par l'utilisateur
    */
    public static void createWorkOrderLineItems(String workOrderId, List<Asset> assetsList, List<String> ncpsId){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createWorkOrderLineItems'); 
        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        Map<String, String> mapAssetProduct = new Map<String, String>();
        Map<String, List<Case>> mapAssetNCP = new Map<String, List<Case>>();
        Map<String, String> mapProductPriceBook = new Map<String, String>();
        List<Case> npcList = new List<Case>();
        Set<Id> assetIdDuplicate = new Set<Id>();
        System.debug('## workOrderId: '+workOrderId); 
        System.debug('## assetsList: '+assetsList); 
        System.debug('## ncpsId: '+ncpsId); 
    
        try {
            // On récupère les produits des assets
            for(Asset ast : assetsList) {
                mapAssetProduct.put(ast.Id, ast.Product2Id);
            }
    
            // On récupère les NCPs des assets
            System.debug('## npcList: '+npcList); 
            if(!ncpsId.isEmpty()) {
                for(Case ncp : [SELECT Id, AssetId, ProductId FROM Case WHERE Id IN :ncpsId]) {
                    npcList.add(ncp);
                    mapAssetProduct.put(ncp.Id, ncp.ProductId); 
                }
            }
    
            // On récupère les prix catalogue des produits
            System.debug('## mapAssetProduct: '+mapAssetProduct); 
            for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry 
                                        WHERE Product2Id IN : mapAssetProduct.values() AND IsActive = true]) {
                mapProductPriceBook.put(pbe.Product2Id, pbe.Id);
            }
            
            // Pour chaque NCP, on créé une ligne
            if(!npcList.isEmpty()) {
                for(Case ncp : npcList){
                    System.debug('## Case Id: '+ncp.Id); 
                    String prodId = mapAssetProduct.get(ncp.Id);
                    String pbeId = mapProductPriceBook.get(prodId);
                    WorkOrderLineItem woli = new WorkOrderLineItem( AssetId = ncp.AssetId,
                                                                PricebookEntryId = pbeId,
                                                                //Product2Id = prodId,
                                                                WorkOrderId = workOrderId,
                                                                productNonCompliance__c = ncp.Id);
                    System.debug('## WorkOrderLineItem on NCP: '+woli); 
                    woliToInsert.add(woli);
                    assetIdDuplicate.add(ncp.AssetId); // Ajout dans liste pour évite duplication de ligne sur le même actif
                }
            }
    
            // Pour chaque actifs, on créé une ligne
            for(String assetId : mapAssetProduct.keySet()) {
                System.debug('## Asset Id: '+assetId); 
                String prodId = mapAssetProduct.get(assetId);
                String pbeId = mapProductPriceBook.get(prodId);
                // Si Asset et n'est pas déjà dans une WOLI
                if(assetId.startsWith('02i') && !assetIdDuplicate.contains(assetId)) {
                    WorkOrderLineItem woli = new WorkOrderLineItem( AssetId = assetId,
                                                                    PricebookEntryId = pbeId,
                                                                    //Product2Id = prodId,
                                                                    WorkOrderId = workOrderId);
                    System.debug('## WorkOrderLineItem on Asset: '+woli); 
                    woliToInsert.add(woli);
                }
            }
    
            // Insert WOLI
            System.debug('## woliToInsert: '+woliToInsert); 
            if(!woliToInsert.isEmpty()) {
                insert woliToInsert;
            }
    
            System.debug('### FIN LWC_CustomWorkOrderWizard.createWorkOrderLineItems'); 
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction de création du rendez-vous (Service Appointment)
    * @param workOrder Demande de rendez-vous (WorkOrder)
    * @param idChantier Id du chantier
    * @param nbSACreated Nombre de RDV a créé
    * @param mapParameters Objet contenant les informations saisi depuis l'assistant
    * @return Id de l'enregistrement créé
    */
    public static ServiceAppointment createServiceAppointment(WorkOrder workOrder, string idChantier, Integer nbSACreated, Map<String, String> mapParameters){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.createServiceAppointment'); 
        ServiceAppointment result;
    
        try {
            // Récupération des parametres
            String saServiceNote = mapParameters.get('workOrderServiceNote');
            String workOrderPriority = mapParameters.get('workOrderPriority');
            //String saSchedulingPolicyId = mapParameters.get('workOrderSchedulingPolicyId');
            Boolean saMultiDay = (String.isBlank(mapParameters.get('workOrderMultiDay'))) ? false : Boolean.valueOf(mapParameters.get('workOrderMultiDay'));
            Integer workOrderMinimumCrewSize = (String.isBlank(mapParameters.get('workOrderMinimumCrewSize'))) ? null : Integer.valueOf(mapParameters.get('workOrderMinimumCrewSize'));
    
            // Processus sur la criticité
            // if(String.isBlank(saSchedulingPolicyId)) {
            //     FSL__Scheduling_Policy__c schedulingPolicy;
            //     String priorityHg = PropertiesUtils.getStringValue('fsl.wizard.priority.urgence.name', 'CRITIQUE');
            //     String schedulingPolicyName;
            //     if(workOrderPriority == priorityHg) { 
            //         schedulingPolicyName = PropertiesUtils.getStringValue('fsl.wizard.schedPolicy.urgence.name', 'Urgence');
            //     } else {
            //         schedulingPolicyName = PropertiesUtils.getStringValue('fsl.wizard.schedPolicy.normal.name', 'Planification automatique');
            //     }
            //     schedulingPolicy = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = :schedulingPolicyName LIMIT 1];
            //     saSchedulingPolicyId = schedulingPolicy.Id;
            // }
    
    
            String saRTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment'); // TODO
            // Récupération du SA créé automatiquement
            List<ServiceAppointment> saList = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrder.Id];
            if(!saList.isEmpty() && nbSACreated == 1) {
                System.debug('## SA found'); 
                result = new ServiceAppointment(Id = saList[0].Id,
                                            ParentRecordId = workOrder.Id,
                                            fsl_techOrdreExecutionParent__c = workOrder.Id,
                                            //fsl_techCompteRattache__c = workOrder.AccountId,
                                            account__c= workOrder.AccountId,
                                            ContactId = workOrder.ContactId,
                                            chantier__c = idChantier,
                                            Street = workOrder.Street,
                                            City = workOrder.City,
                                            PostalCode = workOrder.PostalCode,
                                            Country = workOrder.Country,
                                            RecordTypeId = saRTId,
                                            ServiceNote = saServiceNote,
                                            //FSL__Scheduling_Policy_Used__c = saSchedulingPolicyId,
                                            FSL__isMultiDay__c = saMultiDay,
                                            fsl_ExternalId__c = workOrder.fsl_ExternalId__c);
            } else {
                System.debug('## New SA'); 
                // Création du Service Appointment (RDV)
                result = new ServiceAppointment(EarliestStartTime = workorder.StartDate,
                                                //DueDate = workOrder.EndDate,
                                                //fsl_techCompteRattache__c = workOrder.AccountId,
                                                account__c=workOrder.AccountId,
                                                ContactId = workOrder.ContactId,
                                                chantier__c = idChantier,
                                                fsl_techOrdreExecutionParent__c = workOrder.Id,
                                                ParentRecordId = workOrder.Id,
                                                RecordTypeId = saRTId,
                                                customerOrder__c = workOrder.customerOrder__c,
                                                Street = workOrder.Street,
                                                City = workOrder.City,
                                                PostalCode = workOrder.PostalCode,
                                                Country = workOrder.Country,
                                                Subject = workOrder.Subject,
                                                Description = workOrder.Description,
                                                DurationType = workOrder.DurationType,
                                                Duration = workOrder.Duration,
                                                ServiceNote = saServiceNote,
                                                //FSL__Scheduling_Policy_Used__c = saSchedulingPolicyId,
                                                //FSL__Auto_Schedule__c = true,
                                                FSL__IsFillInCandidate__c = true,
                                                FSL__isMultiDay__c = saMultiDay,
                                                fsl_ExternalId__c = workOrder.fsl_ExternalId__c);
            }
            if(workOrder.afterSalesService__c != null){
                System.debug('affectation sav serviceApointment');
                result.afterSalesService__c = workOrder.afterSalesService__c;
            }
            System.debug('## result: '+result); 
            System.debug('### FIN LWC_CustomWorkOrderWizard.createServiceAppointment');
            return result; 
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction d'initialisation de la valeur du champ subWorkType
    * @param workTypeName Nom du type de demande de RDV
    * @param assetsList Liste des actifs
    * @param caseList Liste des requêtes
    */
    @AuraEnabled
    public static String initSubWorkType(String workTypeName, List<String> casesIdList, String recordId){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.initSubWorkType');
        final String POSE_STRING = 'Pose';
        final String ECI_STRING = 'ECI';
        final String SAV_STRING = 'SAV';
        final String METRAGE_STRING = 'Métrage';
        
    
        System.debug('## workTypeName: ' + workTypeName);
        System.debug('## casesIdList: ' + casesIdList);
        System.debug('## recordId: ' + recordId);
    
        // initialisation des variables
        String result = 'Inconnu';
        List<Order> chantierOrderList = new List<Order>();
        Order order = null;
        Chantier__c chantier = null;
        Integer notInstalledAssetCount = null;
        Integer nbTotalAssets = null;
        
        // récupération des préfix pour identifier les objet Custom
        Schema.DescribeSObjectResult chantierObject = Chantier__c.sObjectType.getDescribe();
        Schema.DescribeSObjectResult dossierSAVObject = AfterSalesService__c.sObjectType.getDescribe();
		String chantierPrefix = chantierObject.getKeyPrefix();
        String dossierSAVPrefix = dossierSAVObject.getKeyPrefix();
		System.debug('##chantierPrefix:' + chantierPrefix );
        System.debug('##dossierSAVPrefix:' + dossierSAVPrefix );

        // récupération des Commande/Chantier et calcul du nombres d'Assets
        if(recordId.startsWith('801')){
            order = [SELECT Id, installationCompletionDate__c, (SELECT Id, InstallDate FROM AssetsCustomerOrder__r WHERE ParentId = null AND Status != 'Annulé') FROM Order WHERE Id = :recordId LIMIT 1];
            System.debug('## order: ' + order);
            if(order != null && !order.AssetsCustomerOrder__r.isEmpty()){
                nbTotalAssets = order.AssetsCustomerOrder__r.size();
                notInstalledAssetCount = 0;
                for(Asset ast : order.AssetsCustomerOrder__r){
                    if(ast.InstallDate == null){
                        notInstalledAssetCount++;
                    }
                }
            }
        } else if(recordId.startsWith(chantierPrefix)) {
            chantier = [SELECT Id, (SELECT Id, InstallDate FROM Assets__r WHERE ParentId = null AND Status != 'Annulé') FROM Chantier__c WHERE Id = :recordId LIMIT 1];
            System.debug('## chantier: ' + chantier);
            if(chantier != null){
                chantierOrderList = [SELECT Id, installationCompletionDate__c FROM Order WHERE chantier__c = :chantier.Id];
                if(!chantier.Assets__r.isEmpty()){
                    nbTotalAssets = chantier.Assets__r.size();
                    notInstalledAssetCount = 0;
                    for(Asset ast : chantier.Assets__r){
                        if(ast.InstallDate == null){
                            notInstalledAssetCount++;
                        }
                    }
                }
            }
        } else if(recordId.startsWith(dossierSAVPrefix)){
            return SAV_STRING;
        }
        System.debug('## nbTotalAssets: ' + nbTotalAssets);
        System.debug('## notInstalledAssetCount: ' + notInstalledAssetCount);
    
        // Récupération des Requêtes
        List<Case> casesList = [SELECT Id, Type FROM Case WHERE Id IN :casesIdList];
    
        Integer nbCaseSAV = 0;
        Integer nbCaseECI = 0;
    
        // Calcul du nombre de case de type SAV ou ECI
        for(Case cse : casesList){
            if(cse.Type == 'SAV garantie' || cse.Type == 'SAV hors garantie'){
                nbCaseSAV++;
            } else if(cse.Type == 'ECI'){
                nbCaseECI++;
            }
        }
    
        System.debug('## nbCaseSAV: ' + nbCaseSAV);
        System.debug('## nbCaseECI: ' + nbCaseECI);

        // Choix du sous type
        if(workTypeName == Constants.ACTIVITY_TYPE_CONTROL){
            result = METRAGE_STRING;
        }
        else if(workTypeName == Constants.ACTIVITY_TYPE_INTERVENTION) {
            if(nbCaseSAV > 0){
                result = SAV_STRING;
            } else if(nbCaseECI > 0){
                result = ECI_STRING;
            } else {
                if(order != null){
                    if(order != null && order.installationCompletionDate__c != null && order.installationCompletionDate__c.addMonths(1) <= Date.today()){
                        result = SAV_STRING;
                    } else {
                        if(nbTotalAssets != null && notInstalledAssetCount != null && 
                            notInstalledAssetCount >= nbTotalAssets){
                                result = POSE_STRING;
                        }
                        else {
                            result = ECI_STRING;
                        }
                    }
                }
                else if(chantier != null){
                    if(!chantierOrderList.isEmpty()){
                        for(Order ord : chantierOrderList){
                            if(ord.installationCompletionDate__c != null && ord.installationCompletionDate__c.addMonths(1) <= Date.today()){
                                result = SAV_STRING;
                            }
                        }
                    }
                    else {
                        if(nbTotalAssets != null && notInstalledAssetCount != null && 
                            notInstalledAssetCount >= nbTotalAssets){
                                result = POSE_STRING;
                        }
                        else {
                            result = ECI_STRING;
                        }
                    }
                }             
            }
        } else if(workTypeName == Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
            if(nbCaseSAV > 0){
                result = SAV_STRING;
            } else if(nbCaseECI > 0){
                result = ECI_STRING;
            } else {
                if(order != null){
                    if(order.installationCompletionDate__c != null && order.installationCompletionDate__c.addMonths(1) <= Date.today()){
                        result = SAV_STRING;
                    } else {
                        if(nbTotalAssets != null && notInstalledAssetCount != null && 
                            notInstalledAssetCount >= nbTotalAssets){
                                result = POSE_STRING;
                        }
                        else {
                            result = ECI_STRING;
                        }
                    }
                }
                else if(chantier != null){
                    if(!chantierOrderList.isEmpty()){
                        for(Order ord : chantierOrderList){
                            if(ord.installationCompletionDate__c != null && ord.installationCompletionDate__c.addMonths(1) <= Date.today()){
                                result = SAV_STRING;
                            }
                        }
                    }
                    else {
                        result = ECI_STRING;
                    }
                }             
            }
        }
    
        System.debug('## Result: ' + result);
        System.debug('### FIN LWC_CustomWorkOrderWizard.initSubWorkType');
        return result;
    }
    /**
    * @description Fonction d'initialisation de la date d'échéance
    * @param earliestDate Date au plus tôt
    * @param workTypeParametersId Id du workType
    */
    @AuraEnabled
    public static Datetime initDueDate(Date earliestDate, String workTypeParametersId){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.initDueDate');
        System.debug('## earliestDate: '+ earliestDate);
        System.debug('## workTypeParametersId: ' + workTypeParametersId);
        Datetime result = null;
        Datetime workOrderStartDate = Datetime.valueOf(earliestDate+' 00:00:00');
        EntityWorkTypeParameters__c workTypeParameter = new EntityWorkTypeParameters__c();
        
        if(workTypeParametersId != null){
            workTypeParameter = [SELECT Id, dueDateDelay__c, workType__r.FSL__Due_Date_Offset__c FROM EntityWorkTypeParameters__c WHERE Id = :workTypeParametersId];
    
            if(workTypeParameter != null && workTypeParameter.dueDateDelay__c != null){
                result = Datetime.valueOf(workOrderStartDate.addMonths((Integer)workTypeParameter.dueDateDelay__c).format('yyyy-MM-dd hh:mm:ss'));
            } else if (workTypeParameter != null && workTypeParameter.workType__r.FSL__Due_Date_Offset__c != null) {
                result = Datetime.valueOf(workOrderStartDate.addMinutes((Integer)workTypeParameter.workType__r.FSL__Due_Date_Offset__c).format('yyyy-MM-dd hh:mm:ss'));
            }
        }
    
        System.debug('## result: ' + result);
        System.debug('### FIN LWC_CustomWorkOrderWizard.initDueDate');
        return result;
    }
    
    public static Map<String,Integer> countAssets(List<Asset> assetsList){
        System.debug('### DEBUT LWC_CustomWorkOrderWizard.countAssets');
        System.debug('## assetsList: ' + assetsList);
        Map<String,Integer> countAssetMap = new Map<String,Integer>();
        Integer numberOfAsset = assetsList.size();
        Integer numberOfAssetAfterLastMonth = 0;
        Integer numberOfAssetBeforeLastMonth = 0;
        for(Asset asset : assetsList){
            if(asset.InstallDate != null && asset.InstallDate < Date.today().addMonths(-1)){
                numberOfAssetBeforeLastMonth++;
            } else if (asset.InstallDate != null && asset.InstallDate >= Date.today().addMonths(-1)){
                numberOfAssetAfterLastMonth++;
            }
        }
        countAssetMap.put(LWC_CustomWorkOrderWizard.ASSET_INSTALLED_EARLIER_THAN_A_MONTH_STRING,numberOfAssetBeforeLastMonth);
        countAssetMap.put(LWC_CustomWorkOrderWizard.ASSET_INSTALLED_LATER_THAN_A_MONTH_STRING,numberOfAssetAfterLastMonth);
        System.debug('## countAssetMap: ' + countAssetMap);
        System.debug('### FIN LWC_CustomWorkOrderWizard.countAssets');
        return countAssetMap;
    }
    
    /**
    * @description Récupération des liste de la picklist "PreferenceType"
    * @return Map contenant les noms API et les labels des valeurs
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, String> getPreferenceTypePickListValues(){
        Map<String, String> result = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = ResourcePreference.PreferenceType.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            result.put(f.getValue(), f.getLabel());
        }     
        return result;
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
    /**
* @description Fonction pour Vérifier si le dossier SAV a un rdv débrifé
* @return si au moins un rdv débrifé existe et le champ 'à Diagnostiquer' égal à true ==> result = true 
*/
@AuraEnabled
public static Boolean checkForServiceAppointmentDebriefed(String recordId){
    System.debug('### DEBUT LWC_CustomWorkOrderWizard.checkForServiceAppointmentDebriefed'); 
    Boolean result;
    String workTypeName = 'Diagnostic';
    try {        
        //Récipération de WorkType
        WorkType wkType = [SELECT Id, Name, autoSchedulingDelay__c FROM WorkType WHERE Name = :workTypeName LIMIT 1];
        //Récupération de dossier SAV
        List <AfterSalesService__c> Sav = [SELECT Id,toDiagnostic__c FROM AfterSalesService__c WHERE Id =:recordId LIMIT 1];

        //Récupération de RDV débrifé associé.
        List <ServiceAppointment> SA = [SELECT Id FROM ServiceAppointment WHERE afterSalesService__c =:recordId AND Status =:RDV_DEBRIEFE AND
                                        WorkTypeId =: wkType.Id LIMIT 1];

        if (Sav[0].toDiagnostic__c && SA.isEmpty()) {
            result = true; 
        }else {
            result = false;
        }
        System.debug('## result: '+result); 
    } catch(Exception e) {
        System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        throw generateAuraException(e.getMessage());
    }       
    System.debug('### FIN LWC_CustomWorkOrderWizard.checkForServiceAppointmentDebriefed'); 
    return result;
}
    
    public class SkillResult {
        private String id;
        private String name;
        private Decimal value;
    
        public SkillResult(
            String id,
            String name,
            Decimal value
        ) {
            this.id = id;
            this.name = name;
            this.value = value;
        }
    
        @AuraEnabled
        public String getId() {
            return id;
        }
    
        @AuraEnabled
        public String getName() {
            return name;
        }
    
        @AuraEnabled
        public Decimal getValue() {
            return value;
        }
    }
    }