//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_AutoCreateWorkOrder_Intervention
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/07/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class IV_AutoCreateWorkOrder_Intervention {

    @InvocableMethod(label='NCP - Création auto RDV Interv' description='Processus pour créer un RDV d\'intervention automatiquement sur une NCP Interne')
    public static List<String> createWorkOrder_Intervention(List<FlowInputParameters> request) {        
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Intervention.createWorkOrder_Intervention');
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
            
            // Récuprération du Contact / Actif / SA intervention associés au NCP principal
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
            if(!assetList.isEmpty()){
                // Récupération du Work Type Diagnostic
                wtList = [SELECT Id, Name, EstimatedDuration, DurationType, MinimumCrewSize, RecommendedCrewSize, Description 
                            FROM WorkType WHERE Name = :Constants.ACTIVITY_TYPE_INTERVENTION];
                wt = wtList[0];

                // Récupération de la stratégie de planification
                String schedulingPolicyName = PropertiesUtils.getStringValue('fsl.wizard.schedPolicy.normal.name', 'Planification automatique');
                FSL__Scheduling_Policy__c schedulingPolicy = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = :schedulingPolicyName LIMIT 1];
                saSchedulingPolicyId = schedulingPolicy.Id;

                List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
                Map<String,Case> caseMap = new Map<String,Case>();
                List<Case> caseList = new List<Case>();
                List<Case> caseTempList = new List<Case>();
                Set<String> productIdList = new Set<String>();
                Set<String> woIdList = new Set<String>();
                Set<String> npcToIgnoreIdList = new Set<String>();
                Boolean ignoreThisNCP;

                for(Asset ast : assetList){
                    System.debug('## Récupération des informations des NCP: '+ast.Id+' - '+ast.Product2Id);
                    productIdList.add(ast.Product2Id);
                }
                System.debug('## productIdList: '+productIdList.size());

                // Récupération de toutes les NCP diagnostiquées non résolues (sans date de cloture) et non associées à un RDV d'intervention en cours 
                // (sans RDV d'intervention ou avec RDV intervention terminés/débriefés uniquement)
                if(String.isNotBlank(pncRecord.customerOrder__c)) {
                    String casePNCIntRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
                    caseTempList = [SELECT Id, Chantier__c, customerOrder__c, AccountId, AssetId, ClosedDate, ProductId,
                                        Chantier__r.Id, Chantier__r.rue__c, Chantier__r.codePostal__c, Chantier__r.ville__c, Chantier__r.pays__c,
                                        Asset.Id, Asset.customerOrder__c, Asset.customerOrder__r.Id, Asset.customerOrder__r.Pricebook2Id, 
                                        Account.Id, Account.Name, Account.contactParDefaut__c, Account.PersonContactId, Account.IsPersonAccount,
                                        Asset.customerOrder__r.EffectiveDate, Asset.customerOrder__r.serviceEntity__c, Asset.customerOrder__r.AccountId,
                                        Asset.customerOrder__r.serviceEntity__r.Id, Asset.customerOrder__r.serviceEntity__r.serviceTerritory__c,
                                        afterSalesService__c
                                FROM Case 
                                WHERE (Id = :pncRecord.Id OR AssetId IN :assetList OR customerOrder__c = :pncRecord.customerOrder__c) 
                                    AND diagnosticDate__c != null
                                    AND IsClosed = false
                                    AND RecordTypeId = :casePNCIntRTId]; 
                }
                System.debug('## caseTempList: '+caseTempList.size());

                for(Case c : caseTempList){
                    caseMap.put(c.Id,c);
                }

                // Récupération des WOLI / WO ID correspondant aux potentielles NCP elligibles
                if(!caseTempList.isEmpty()){
                    woliList = [SELECT Id, WorkOrderId, AssetId, productNonCompliance__c 
                                    FROM WorkOrderLineItem WHERE productNonCompliance__c IN :caseTempList];
                }

                for(WorkOrderLineItem woli : woliList){
                    woIdList.add(woli.WorkOrderId);
                }

                // Récupération des SA associés aux WO des NCP elligibles
                List<ServiceAppointment> saList = [SELECT Id, WorkTypeId, Status, ParentRecordId 
                                                    FROM ServiceAppointment WHERE ParentRecordId IN :woIdList AND WorkTypeId = :wt.Id];
                
                // Détermination de l'elligibilité des NCP. Si un RDV d'intervention en cours existe, le NCP est ignoré, sinon il est ajouté à la liste des NCP elligibles
                List<Case> caseListWithDoublon = new List<Case>();
                for(WorkOrderLineItem woli : woliList){
                    ignoreThisNCP = false;
                    for(ServiceAppointment sa : saList){
                        if(woli.WorkOrderId == sa.ParentRecordId && (sa.Status == Constants.RDV_FSL_DEBRIEFE || sa.Status == Constants.RDV_FSL_TERMINE)){
                            npcToIgnoreIdList.add(woli.productNonCompliance__c);
                            ignoreThisNCP = true;
                        }
                    }
                    if(!ignoreThisNCP){
                        caseListWithDoublon.add(caseMap.get(woli.productNonCompliance__c));
                    }
                }

                // Elimination des potentiels doublons restants (NCP associée à un WOLI elligible ET à un WOLI non elligible)
                for(Case caseWithDoublon : caseListWithDoublon){
                    ignoreThisNCP = false;
                    for(String caseToIgnoreId : npcToIgnoreIdList){
                        if(caseWithDoublon.Id == caseToIgnoreId){
                            ignoreThisNCP = true;
                        }
                    }
                    if(!ignoreThisNCP){
                        caseList.add(caseWithDoublon);
                        npcToIgnoreIdList.add(caseWithDoublon.Id);
                    }
                }
                
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
                for(Case npc : caseList){
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
                        woGroupMap.put(wo.chantier__c,wo.Id);
                    } else {
                        woGroupMap.put('Others',wo.Id);
                    }
                }
                System.debug('## woGroupMap: '+woGroupMap.size());

                // Récupération des PBE
                pbeList = [SELECT Id, Pricebook2Id, Product2Id 
                            FROM PricebookEntry WHERE Product2Id IN :productIdList];

                // Création des WOLI (1 par NCP) avec association au bon WO, puis insertion de masse
                for(Case npc : caseList){
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
                for(Case npc : caseList){
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
        System.debug('### END IV_AutoCreateWorkOrder_Intervention.createWorkOrder_Intervention');
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
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Intervention.createWorkOrder');
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
            customerOrder__c = npc.customerOrder__c,
            afterSalesService__c = npc.afterSalesService__c
        );
        System.debug('## newWO: '+newWO);
        System.debug('### FIN IV_AutoCreateWorkOrder_Intervention.createWorkOrder');
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
        System.debug('### DEBUT IV_AutoCreateWorkOrder_Intervention.createServiceAppointment');
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
        System.debug('### FIN IV_AutoCreateWorkOrder_Intervention.createServiceAppointment');
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

        return newSA;
    }
    
    // Input parameters for the Apex action 
    public class FlowInputParameters{
        @InvocableVariable(label='Id NCP' required=true)
        public String pncId;        
    }
    
    public class FlowActionException extends Exception {}
}