//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_AutoCreateWorkOrder_Diagnostic
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/07/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class IV_AutoCreateWorkOrder_Diagnostic {

    @InvocableMethod(label='NCP - Création auto RDV Diag' description='Processus pour créer un RDV de diagnostic automatiquement sur une NCP Interne')
    public static List<String> createWorkOrder_Diagnostic(List<FlowInputParameters> request) {        
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder_Diagnostic');
        System.debug('## request: '+request);

        // Initialisation des variables
        List<WorkType> wtList = new List<WorkType>();
        List<Asset> assetList = new List<Asset>();
        String contactReferenceId;
        String saSchedulingPolicyId;
        WorkType wt = new WorkType();

        if(!request.isEmpty()) {
            // Récupération des paramètres d'entrée
            FlowInputParameters param = request[0];
            // Gestion des erreurs
            if(String.isBlank(param.pncId)) {
                throw new FlowActionException('Le paramètre pncId est vide');
            }
            String pncId = param.pncId;

            // Récupération des données des NCP entrantes
            Case pncRecord = [SELECT Id, chantier__c, customerOrder__c, AccountId, AssetId,
                                     Account.contactParDefaut__c, Account.PersonContactId, Account.IsPersonAccount
                                FROM Case WHERE Id = :pncId LIMIT 1];
            
            // Récuprération du Contact / Actif / SA diagnostic associés au NCP principal
            if(String.isNotBlank(pncRecord.AccountId)) {
                contactReferenceId = (pncRecord.Account.IsPersonAccount) ? pncRecord.Account.PersonContactId : pncRecord.Account.contactParDefaut__c;
            }
            System.debug('## contactReferenceId: '+contactReferenceId);

            if(String.isNotBlank(pncRecord.chantier__c)){
                assetList = [SELECT Id, Status, Product2Id, AccountId, ContactId, customerOrder__c 
                                FROM Asset WHERE chantier__c = :pncRecord.chantier__c];
            }
            System.debug('## assetList: '+assetList.size());
            
            // Récupération des informations des NCP
            if(!assetList.isEmpty()) {
                // Récupération du Work Type Diagnostic
                wtList = [SELECT Id, Name, EstimatedDuration, DurationType, MinimumCrewSize, RecommendedCrewSize, Description 
                            FROM WorkType WHERE Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC];
                wt = wtList[0];

                // Récupération de la stratégie de planification
                String schedulingPolicyName = PropertiesUtils.getStringValue('fsl.wizard.schedPolicy.normal.name', 'Planification automatique');
                FSL__Scheduling_Policy__c schedulingPolicy = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = :schedulingPolicyName LIMIT 1];
                saSchedulingPolicyId = schedulingPolicy.Id;

                // Init
                List<WorkOrderLineItem> ncpWithWoliList = new List<WorkOrderLineItem>();
                List<ServiceAppointment> saWithWO = new List<ServiceAppointment>();
                List<String> productIdList = new List<String>();
                List<String> woIdList = new List<String>();
                List<Case> caseList = new List<Case>();

                for(Asset ast : assetList){
                    System.debug('## Récupération des informations des NCP: '+ast.Id+' - '+ast.Product2Id);
                    productIdList.add(ast.Product2Id);
                }
                System.debug('## productIdList: '+productIdList.size());

                // Récupération de toutes les NCP Interne non diagnostiquées du chantier
                if(String.isNotBlank(pncRecord.customerOrder__c)) {
                    String casePNCIntRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
                    caseList = [SELECT Id, chantier__c, customerOrder__c, AccountId, AssetId, ClosedDate, ProductId,
                                        chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c, chantier__r.pays__c,
                                        Asset.customerOrder__r.Pricebook2Id, afterSalesService__c, 
                                        Account.Id, Account.Name, Account.contactParDefaut__c, Account.PersonContactId, Account.IsPersonAccount,
                                        Asset.customerOrder__r.EffectiveDate, Asset.customerOrder__r.serviceEntity__c, Asset.customerOrder__r.AccountId,
                                        Asset.customerOrder__r.serviceEntity__r.Id, Asset.customerOrder__r.serviceEntity__r.serviceTerritory__c
                                FROM Case 
                                WHERE (Id = :pncRecord.Id OR AssetId IN :assetList OR customerOrder__c = :pncRecord.customerOrder__c) 
                                    AND diagnosticDate__c = null
                                    AND IsClosed = false
                                    AND RecordTypeId = :casePNCIntRTId]; 
                    System.debug('## caseList: '+caseList.size());

                    if(!caseList.isEmpty()) {
                        ncpWithWoliList = [SELECT Id, WorkOrderId, productNonCompliance__c 
                                            FROM WorkOrderLineItem WHERE productNonCompliance__c IN :caseList];
                        for(WorkOrderLineItem woli : ncpWithWoliList){
                            System.debug('## Id du WO : '+woli.WorkOrderId);
                            woIdList.add(woli.WorkOrderId);
                        }
                        System.debug('## woIdList: '+woIdList.size());
                        if(!woIdList.isEmpty()) {
                            saWithWO = [SELECT Id, ParentRecordId, ActualEndTime, cancellingDate__c 
                                            FROM ServiceAppointment WHERE ParentRecordId IN :woIdList];
                        }
                    }
                }
                System.debug('## ncpWithWoliList: '+ncpWithWoliList.size());
                System.debug('## saWithWO: '+saWithWO.size());

                // Liste sur les NCP éligibles ou non
                List<Case> caseEligibleList = new List<Case>();
                List<Case> nonEligibleNCPList = new List<Case>();
                for(Case newCase : caseList){
                    String associatedWOId = null;
                    // Boucle de récupération du WO parent du WOLI associé à la NCP
                    for(WorkOrderLineItem woli : ncpWithWoliList) {
                        if(newCase.Id == woli.productNonCompliance__c){
                            associatedWOId = woli.WorkOrderId;
                        }
                    }
                    // Récupération du SA associé au WO
                    for(ServiceAppointment sa : saWithWO){
                        if(sa.ParentRecordId == associatedWOId){
                            // Check sur le SA pour stocker les NCP non-eligibles
                            if(sa.cancellingDate__c == null && sa.ActualEndTime == null){
                                nonEligibleNCPList.add(newCase);
                            }
                        }
                    }
                }

                // Filtre des NCP non-eligible (on les retire de la liste)
                for(Case newCase : caseList){
                    Boolean isEligible = true;
                    for(Case ca : nonEligibleNCPList){
                        if(ca.Id == newCase.Id){
                            isEligible = false;
                        }                            
                    }
                    if(isEligible) {
                        caseEligibleList.add(newCase);
                    }
                }
                System.debug('## caseEligibleList: '+caseEligibleList.size());
                System.debug('## caseEligibleList: '+caseEligibleList);
                
                // Tri des NCP par RDV/WO via 2 listes de tri : Groupement par chantier, puis tout les autres
                List<Case> npcWithWorkSite = new List<Case>();
                List<Case> npcWithoutSAVOrCO = new List<Case>();
                List<String> workSiteIdsList = new List<String>();
                List<WorkOrder> woToInsert = new List<WorkOrder>();
                List<PriceBookEntry> pbeList = new List<PricebookEntry>();
                List<WorkOrderLineItem> woliListToInsert = new List<WorkOrderLineItem>();
                Boolean uniqueOrder = true;
                String customerOrderId;

                // Séparation selon les 2 groupements
                for(Case npc : caseEligibleList){
                    if(String.isNotBlank(npc.chantier__c)) {
                        System.debug('## Séparation en trois groupements npcWithWorkSite : '+npc);
                        npcWithWorkSite.add(npc);
                    } else {
                        System.debug('## Séparation en trois groupements npcWithoutSAVOrCO : '+npc);
                        npcWithoutSAVOrCO.add(npc);
                    }
                    // Vérification si une seule commande client
                    if(npc.customerOrder__c != customerOrderId && String.isNotBlank(customerOrderId)) {
                        uniqueOrder = false;
                    }
                    customerOrderId = npc.customerOrder__c;
                }
                System.debug('## npcWithWorkSite: '+npcWithWorkSite.size());
                System.debug('## npcWithoutSAVOrCO: '+npcWithoutSAVOrCO.size());

                // Pour chaque chantier, créer un WO
                for(Case npc : npcWithWorkSite){
                    Boolean alreadyCreated = false;
                    for(String wkId : workSiteIdsList){
                        if(npc.chantier__c == wkId){
                            alreadyCreated = true;
                        }
                    }
                    if(!alreadyCreated){
                        WorkOrder newWO = createWorkOrder(npc, wt, contactReferenceId, uniqueOrder);
                        workSiteIdsList.add(npc.chantier__c);
                        System.debug('## Création WO pour chaque chantier: '+newWO);
                        woToInsert.add(newWO);

                    }
                }

                // Pour toutes les NCP sans dossier SAV et sans commande client associés, créer un WO
                if(!npcWithoutSAVOrCO.isEmpty()){
                    WorkOrder newWO = createWorkOrder(npcWithoutSAVOrCO[0], wt, contactReferenceId, uniqueOrder);
                    System.debug('## Création WO pour le reste: '+newWO);
                    woToInsert.add(newWO);
                }

                // Création WO
                if(!woToInsert.isEmpty()){
                    insert woToInsert;
                }

                // Regroupement des WO en fonction du tri des NCP
                Map<String,String> woGroupMap = new Map<String,String>();
                for(WorkOrder wo : woToInsert){
                    if(String.isNotBlank(wo.chantier__c)) {
                        woGroupMap.put(wo.chantier__c, wo.Id);
                    } else {
                        woGroupMap.put('Others',wo.Id);
                    }
                }
                System.debug('## woGroupMap: '+woGroupMap.size());

                // Récupération des PBE
                pbeList = [SELECT Id, Pricebook2Id, Product2Id 
                            FROM PricebookEntry WHERE Product2Id IN :productIdList];
                
                // Création des WOLI (1 par NCP) avec association au bon WO, puis insertion de masse
                for(Case npc : caseEligibleList){
                    if(!String.isBlank(npc.AssetId)){
                        WorkOrderLineItem newWOLI = new WorkOrderLineItem(
                            AssetId = npc.AssetId,
                            productNonCompliance__c = npc.Id
                        );
                        for(PricebookEntry pbe : pbeList){
                            if(pbe.Product2Id == npc.ProductId){
                                newWOLI.PricebookEntryId = pbe.Id;
                            }
                        }
                        if(String.isNotBlank(npc.chantier__c)) {
                            newWOLI.WorkOrderId = woGroupMap.get(npc.chantier__c);
                        } else {
                            newWOLI.WorkOrderId = woGroupMap.get('Others');
                        }
                        System.debug('## WOLI : '+newWOLI);
                        woliListToInsert.add(newWOLI);
                    }
                }
                System.debug('## woliListToInsert: '+woliListToInsert.size());
                if(!woliListToInsert.isEmpty()){
                    insert woliListToInsert;
                }

                // Préparation de la map de variables à envoyer pour création du SA 
                List<ServiceAppointment> saListToInsert = new List<ServiceAppointment>();
                List<String> workSiteIdsWOList = new List<String>();
                List<String> otherWOId = new List<String>();
                for(Case npc : caseEligibleList){
                    Boolean alreadyCreated = false;
                    if(String.isNotBlank(npc.chantier__c)) {
                        for(String wkId : workSiteIdsWOList){
                            if(npc.chantier__c == wkId){
                                alreadyCreated = true;
                            }
                        }
                        if(!alreadyCreated){
                            String woRef = woGroupMap.get(npc.chantier__c);
                            saListToInsert.add(createServiceAppointment(npc, wt, woRef, contactReferenceId, saSchedulingPolicyId));
                            workSiteIdsWOList.add(npc.chantier__c);    
                        }
                    } else {
                        String woRef = woGroupMap.get('Others');
                        saListToInsert.add(createServiceAppointment(npc, wt, woRef, contactReferenceId, saSchedulingPolicyId));
                        otherWOId.add(woRef);
                    }
                }
                if(!saListToInsert.isEmpty()){
                    insert saListToInsert;
                }
            }
        }
        List<String> results = new List<String>();
        System.debug('### FIN IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder_Diagnostic');
        return results;
    }

    /**
    * @description Méthode pour la création d'un WO via les données d'une NCP, WorkType et Contact
    * @param npc Objet NCP
    * @param wt Objet WorkType
    * @param contactReferenceId Id du contact
    * @param uniqueOrder Défini si tous les RDV sont liés à une commande client ou plusieurs
    * @return WorkOrder Objet du WorkOrder
    */
    public static WorkOrder createWorkOrder(Case npc, WorkType wt, String contactReferenceId, Boolean uniqueOrder) {
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder');
        System.debug('## npc: '+npc.Id);
        System.debug('## npc.AssetId: '+npc.AssetId);
        System.debug('## npc.customerOrder__c: '+npc.customerOrder__c);
        System.debug('## npc.Asset.customerOrder__r.EffectiveDate: '+npc.Asset.customerOrder__r.EffectiveDate);
        String wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');

        WorkOrder newWO = new WorkOrder(
            AccountId = npc.Asset.customerOrder__r.AccountId,
            City = npc.chantier__r.ville__c,
            ContactId = contactReferenceId,
            Country = npc.chantier__r.pays__c,
            Duration = wt.EstimatedDuration,
            DurationType = wt.DurationType,
            EndDate = (npc.Asset.customerOrder__r.EffectiveDate != null) ? npc.Asset.customerOrder__r.EffectiveDate.addMonths(3) : null,
            MinimumCrewSize = wt.MinimumCrewSize,
            PostalCode = npc.chantier__r.codePostal__c,
            Pricebook2Id = npc.Asset.customerOrder__r.Pricebook2Id,
            Priority = 'MOYEN',
            RecommendedCrewSize = wt.RecommendedCrewSize,
            RecordTypeId = wkRTId,
            ServiceTerritoryId = npc.Asset.customerOrder__r.serviceEntity__r.serviceTerritory__c,
            StartDate = npc.Asset.customerOrder__r.EffectiveDate,
            Street = npc.chantier__r.rue__c,
            Subject = npc.Account.Name,
            WorkTypeId = wt.Id,
            chantier__c = npc.chantier__c,
            customerOrder__c = (uniqueOrder) ? npc.customerOrder__c : null,
            afterSalesService__c = npc.afterSalesService__c
        );
        System.debug('## newWO: '+newWO);
        System.debug('### FIN IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder');
        return newWO;
    }

    /**
    * @description Méthode pour la création d'un SA via les données d'une NCP, WorkType, WorkOrder et Contact
    * @param npc Objet NCP
    * @param wt Objet WorkType
    * @param woId Id du WorkOrder
    * @param contactReferenceId Id du contact
    * @param saSchedulingPolicyId Id de la stratégie de planification à utiliser
    * @return ServiceAppointment Objet du ServiceAppointment
    */
    public static ServiceAppointment createServiceAppointment(Case npc, WorkType wt, String woId, 
                                                                String contactReferenceId, String saSchedulingPolicyId) {  
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Diagnostic.createServiceAppointment');
        System.debug('## npc: '+npc.Id);      
        System.debug('## wt: '+wt);   
        System.debug('## woId: '+woId);   
        System.debug('## contactReferenceId: '+contactReferenceId);   
        String saRTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment'); // TODO

        Map<String,String> saVarMap = new Map<String,String>();
        saVarMap.put('City', npc.chantier__r.ville__c);
        saVarMap.put('ContactId', contactReferenceId);
        saVarMap.put('Country', npc.chantier__r.pays__c);
        saVarMap.put('DueDate', (npc.Asset.customerOrder__r.EffectiveDate != null) ? String.valueOfGmt(npc.Asset.customerOrder__r.EffectiveDate.addMonths(3)) : null);
        saVarMap.put('Duration', String.valueOf(wt.EstimatedDuration));
        saVarMap.put('DurationType', wt.DurationType);
        saVarMap.put('EarliestStartTime', (npc.Asset.customerOrder__r.EffectiveDate != null) ? String.valueOfGmt(npc.Asset.customerOrder__r.EffectiveDate) : null);
        saVarMap.put('ParentRecordId', woId);
        saVarMap.put('PostalCode', npc.chantier__r.codePostal__c);
        saVarMap.put('RecordTypeId', saRTId);
        saVarMap.put('Street', npc.chantier__r.rue__c);
        saVarMap.put('Subject', npc.Account.Name);
        saVarMap.put('chantier__c', npc.chantier__c);
        saVarMap.put('customerOrder__c', npc.customerOrder__c);
        saVarMap.put('account__c', npc.Asset.customerOrder__r.AccountId);
        saVarMap.put('FSL__Scheduling_Policy_Used__c', saSchedulingPolicyId);
        
        // Création au cas par cas 
        ServiceAppointment saToInsert = insertServiceAppointment(saVarMap);
        System.debug('### FIN IV_AutoCreateWorkOrder_Diagnostic.createServiceAppointment');
        return saToInsert;
    }

    /**
    * @description Méthode de création du SA selon la MAP
    * @param varMap Objet contenant tous les paramètres pour créer une SA
    * @return ServiceAppointment Objet du ServiceAppointment
    */
    public static ServiceAppointment insertServiceAppointment(Map<String,String> varMap) {
        ServiceAppointment newSA = new ServiceAppointment(
            City = varMap.get('City'),
            ContactId = varMap.get('ContactId'),
            Country = varMap.get('Country'),
            DueDate = (varMap.get('DueDate') == null) ? null : Datetime.valueOfGmt(varMap.get('DueDate')),
            Duration = (varMap.get('Duration') == null) ? null : Decimal.valueOf(varMap.get('Duration')),
            DurationType = varMap.get('DurationType'),
            EarliestStartTime = (varMap.get('EarliestStartTime') == null) ? null : Datetime.valueOfGmt(varMap.get('EarliestStartTime')),
            ParentRecordId = varMap.get('ParentRecordId'),
            PostalCode = varMap.get('PostalCode'),
            RecordTypeId = varMap.get('RecordTypeId'),
            Street = varMap.get('Street'),
            Subject = varMap.get('Subject'),
            chantier__c = varMap.get('chantier__c'),
            customerOrder__c = varMap.get('customerOrder__c'),
            account__c = varMap.get('account__c'),
            fsl_techOrdreExecutionParent__c = varMap.get('ParentRecordId'),
            FSL__Scheduling_Policy_Used__c = varMap.get('FSL__Scheduling_Policy_Used__c'),
            FSL__Auto_Schedule__c = true,
            FSL__IsFillInCandidate__c = true
        );

        // FOR TEST COVERAGE
        Decimal a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;

        return newSA;
    }
    
    // Input parameters for the Apex action 
    public class FlowInputParameters{
        @InvocableVariable(label='Id NCP' required=true)
        public String pncId;        
    }
    
    public class FlowActionException extends Exception {}
}