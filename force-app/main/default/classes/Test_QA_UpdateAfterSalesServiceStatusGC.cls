//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_UpdateAfterSalesServiceStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/01/2024
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_QA_UpdateAfterSalesServiceStatusGC {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService'); 
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private final static String BYPASS_TRIGGER = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR023_ChangeOwner;TR021_Opportunity;TR022_Opportunity;' +
                                                    'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040';
     
    
    @testSetup 
    static void testSetup() {
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', true);
        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,true);

        Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.isConvertibleAsset__c=true;
        insert prod;

        //PricebookEntry pbe = Utils_Test.createPricebookEntry(prod.Id,true);

        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, chantier.Id, accountTest.Id,false);
        newAsset1.controlDate__c = System.today() - 60;
        newAsset1.installDate = System.today() - 10;
        Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test2', null, prod.Id, null, chantier.Id, accountTest.Id,false);
        newAsset1.controlDate__c = System.today() - 60;
        newAsset1.installDate = System.today() - 10;
        Asset newAsset3 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test3', null, prod.Id, null, chantier.Id, accountTest.Id,false);
        newAsset1.controlDate__c = System.today() - 60;
        newAsset1.installDate = System.today() - 10;
        List<Asset> astList = new List<Asset>();
        astList.add(newAsset1);
        astList.add(newAsset2);
        astList.add(newAsset3);
        insert astList;

        AfterSalesService__c dossierSav = new AfterSalesService__c(workSite__c = chantier.Id, description__c = 'TEST');
        AfterSalesService__c dossierSav2 = new AfterSalesService__c(workSite__c = chantier.Id, description__c = 'TEST2');
        AfterSalesService__c dossierSav3 = new AfterSalesService__c(workSite__c = chantier.Id, description__c = 'TEST3');
        List<AfterSalesService__c> dossierSavList = new List<AfterSalesService__c>{dossierSav, dossierSav2, dossierSav3};
        insert dossierSavList;

        Case caseTest1 = Utils_Test.createCase(RT_PNC_INTERNALID, accountTest, chantier.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        caseTest1.chantier__c = chantier.Id;
        caseTest1.AssetId = newAsset1.Id;
        caseTest1.afterSalesService__c = dossierSav.Id;

        Case caseTest2 = Utils_Test.createCase(RT_PNC_INTERNALID, accountTest, chantier.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        caseTest2.chantier__c = chantier.Id;
        caseTest2.AssetId = newAsset2.Id;
        caseTest2.afterSalesService__c = dossierSav2.Id;

        Case caseTest3 = Utils_Test.createCase(RT_PNC_INTERNALID, accountTest, chantier.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        caseTest3.chantier__c = chantier.Id;
        caseTest3.AssetId = newAsset3.Id;
        caseTest3.afterSalesService__c = dossierSav3.Id;


        List<Case> ncpList = new List<Case>{caseTest1, caseTest2, caseTest3};
        insert ncpList;

        // Creation Rendez-vous
        List<WorkType> wtlist = new List<WorkType>();
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
        wtlist.Add(wt1);
        WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
        wtlist.Add(wt2);
        insert wtlist;

        //Demande RDV Diagnostic
        WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
        wo.WorkTypeId = wt1.Id;
        WorkOrder wo2 = Utils_Test.createWorkOrder(wkRTId, false);
        wo2.WorkTypeId = wt1.Id;
        //Demande RDV Intervention
        WorkOrder wo3 = Utils_Test.createWorkOrder(wkRTId, false);
        wo3.WorkTypeId = wt2.Id;
        WorkOrder wo4 = Utils_Test.createWorkOrder(wkRTId, false);
        wo4.WorkTypeId = wt2.Id;
        WorkOrder wo5 = Utils_Test.createWorkOrder(wkRTId, false);
        wo5.WorkTypeId = wt2.Id;
        List<WorkOrder> woList = new List<WorkOrder>{wo, wo2, wo3, wo4, wo5};       
        insert woList;
        
        //RDV diag non confirmé
        ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, SASARTId, false);
        sa1.Status='Demandé';
        //RDV diag confirmé
        ServiceAppointment sa2 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
        sa2.Status='Confirmé';
        sa2.fsl_dateConfirmation__c = Date.today();
        sa2.dateConfirmationClient__c = Date.today();
        sa2.SchedEndTime=Date.today();
        sa2.SchedStartTime=Date.today();
        //RDV intervention non confirmé
        ServiceAppointment sa3 = Utils_Test.createServiceAppointment(wo3.Id, SASARTId, false);
        sa3.Status='Demandé';
        //RDV intervention confirmé
        ServiceAppointment sa4 = Utils_Test.createServiceAppointment(wo4.Id, SASARTId, false);
        sa4.Status='Confirmé';
        sa4.fsl_dateConfirmation__c = Date.today();
        sa4.dateConfirmationClient__c = Date.today();
        sa4.SchedEndTime=Date.today();
        sa4.SchedStartTime=Date.today();
        //RDV intervention débriefé
        ServiceAppointment sa5 = Utils_Test.createServiceAppointment(wo5.Id, SASARTId, false);
        sa5.Status='Débriefé';
        sa5.fsl_dateConfirmation__c = Date.today();
        sa5.dateConfirmationClient__c = Date.today();
        sa5.SchedEndTime=Date.today();
        sa5.SchedStartTime=Date.today();
        sa5.ActualEndTime=Date.today();
        sa5.ActualStartTime=Date.today();
        sa5.fsl_dateDebriefing__c = Date.today();
        List<ServiceAppointment> saList = new List<ServiceAppointment>{sa1, sa2, sa3, sa4, sa5};
        insert saList;
    }

    @isTest
    //test Status non diagnostiqué 
    static void testUndiagnosedNCP() {
        List<AfterSalesService__c> dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        List<Case> caseList = [SELECT Id,AssetId,afterSalesService__c FROM Case];
        ServiceAppointment saDiagUnconfirmed = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE workTypeName__c = 'Diagnostic' AND Status = 'Demandé' LIMIT 1];
        ServiceAppointment saDiagConfirmed = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE workTypeName__c = 'Diagnostic' AND Status = 'Confirmé' LIMIT 1];
        
        
        AfterSalesService__c dossierSav1 = null;
        AfterSalesService__c dossierSav2 = null;
        AfterSalesService__c dossierSav3 = null;
        Case case1 = null;
        Case case2 = null;

        for(AfterSalesService__c dossierSav : dossierSavList){
            if(dossierSav.description__c == 'TEST'){
                dossierSav1 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST2'){
                dossierSav2 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST3'){
                dossierSav3 = dossierSav;
            }
        }

        for(Case ncp : caseList){
            if(ncp.afterSalesService__c == dossierSav2.Id){
                case1 = ncp;
            }
            if(ncp.afterSalesService__c == dossierSav3.Id){
                case2 = ncp;
            }
        }
        Test.startTest();

        WorkOrder woUnconfirmed = new WorkOrder(Id = saDiagUnconfirmed.ParentRecordId, afterSalesService__c = dossierSav2.Id);
        WorkOrder woConfirmed = new WorkOrder(Id = saDiagConfirmed.ParentRecordId, afterSalesService__c = dossierSav3.Id);
        List<WorkOrder> woList = new List<WorkOrder> {woUnconfirmed, woConfirmed};
        update woList;

        WorkOrderLineItem woliUnconfirmed =  Utils_Test.createWorkOrderLineItem(woUnconfirmed.Id, case1.assetId, false);
        woliUnconfirmed.productNonCompliance__c = case1.Id;
        WorkOrderLineItem woliConfirmed =  Utils_Test.createWorkOrderLineItem(woConfirmed.Id, case2.assetId, false);
        woliConfirmed.productNonCompliance__c = case2.Id;
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>{woliUnconfirmed, woliConfirmed};
        insert woliList;
        
        saDiagUnconfirmed.afterSalesService__c = dossierSav2.Id;
        saDiagConfirmed.afterSalesService__c = dossierSav3.Id;
        List<ServiceAppointment> saList = new List<ServiceAppointment>{saDiagUnconfirmed, saDiagConfirmed};
        update saList;

        System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(new Set<Id>{dossierSav1.Id,dossierSav2.Id,dossierSav3.Id}));

        Test.stopTest();

        dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        for(AfterSalesService__c dossier : dossierSavList){
            if(dossier.description__c == 'TEST'){
                //Test SAV Non Diagnostiqué Non préparé
                Assert.areEqual('SAV Non Diagnostiqué Non préparé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST2'){
                //Test SAV Non Diagnostiqué Non programmé
                Assert.areEqual('SAV Non Diagnostiqué Non programmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST3'){
                //Test SAV Non Diagnostiqué programmé
                Assert.areEqual('SAV Non Diagnostiqué programmé', dossier.oldCompositeStatus2__c);
            }
        }
    }

    @isTest
    //test Status liés au devis  
    static void testQuoteStatus() {
        List<AfterSalesService__c> dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        List<Case> caseList = [SELECT Id,AssetId,afterSalesService__c FROM Case];
        Account accountTest = [SELECT Id,AccountSource,accountCallSource__c FROM Account LIMIT 1];
        Chantier__c chantierTest = [SELECT Id FROM Chantier__c LIMIT 1];
        
        //Test non devisé
        AfterSalesService__c dossierSav1 = null;
        //test devis non accepté pour payant
        AfterSalesService__c dossierSav2 = null;
        //test devis non accepté pour non payant
        AfterSalesService__c dossierSav3 = null;
        Case case1 = null;
        Case case2 = null;
        Case case3 = null;

        for(AfterSalesService__c dossierSav : dossierSavList){
            if(dossierSav.description__c == 'TEST'){
                dossierSav1 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST2'){
                dossierSav2 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST3'){
                dossierSav3 = dossierSav;
            }
        }
        Test.startTest();

        //NCP diagnostiqué et commandable
        for(Case ncp : caseList){
            ncp.diagnosticDate__c = Date.today();
            if(ncp.afterSalesService__c == dossierSav1.Id){
                case1 = ncp;
            }
            if(ncp.afterSalesService__c == dossierSav2.Id){
                case2 = ncp;
                ncp.detectedWarranty__c = 'Hors garantie';
            }
            if(ncp.afterSalesService__c == dossierSav3.Id){
                case3 = ncp;
            }
        }
        update caselist;

        //Devis SAV
        Opportunity opp = Utils_Test.createOpportunity(accountTest, chantierTest, false);
        Opportunity opp2 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
        List<Opportunity> oppList = new List<Opportunity>{opp, opp2};
        insert oppList;
        SBQQ__Quote__c devisSav = Utils_Test.createCPQQuote(opp, false);
        devisSav.afterSalesService__c = dossierSav2.Id;
        devisSav.SBQQ__Type__c = 'SAV';
        SBQQ__Quote__c devisSav2 = Utils_Test.createCPQQuote(opp2, false);
        devisSav2.afterSalesService__c = dossierSav3.Id;
        devisSav2.SBQQ__Type__c = 'SAV';
        List<SBQQ__Quote__c> devisSavList = new List<SBQQ__Quote__c>{devisSav, devisSav2};
        insert devisSavList;
        
        System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(new Set<Id>{dossierSav1.Id,dossierSav2.Id,dossierSav3.Id}));

        Test.stopTest();

        dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        for(AfterSalesService__c dossier : dossierSavList){
            if(dossier.description__c == 'TEST'){
                Assert.areEqual('SAV Diagnostiqué Non Devisé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST2'){
                Assert.areEqual('SAV Diagnostiqué Non Accepté', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST3'){
                Assert.areEqual('SAV Attente d\'Interv Non Préparé', dossier.oldCompositeStatus2__c);
            }
        }
    }

    @isTest 
    static void testOrderablePNCWithoutOrder() {
        Account accountTest = [SELECT Id,AccountSource,accountCallSource__c FROM Account LIMIT 1];
        Chantier__c chantierTest = [SELECT Id FROM Chantier__c LIMIT 1];
        List<AfterSalesService__c> dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        List<Case> caseList = [SELECT Id,AssetId,afterSalesService__c FROM Case];
        ServiceAppointment saIntervConfirmed = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Confirmé' LIMIT 1];
        ServiceAppointment saIntervUnconfirmed = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Demandé' LIMIT 1];

        //Test commandable sans commande non programmé
        AfterSalesService__c dossierSav1 = null;
        //test commandable sans commande programmé
        AfterSalesService__c dossierSav2 = null;
        //test non commandable non programmé
        AfterSalesService__c dossierSav3 = null;
        Case case1 = null;
        Case case2 = null;
        Case case3 = null;

        for(AfterSalesService__c dossierSav : dossierSavList){
            if(dossierSav.description__c == 'TEST'){
                dossierSav1 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST2'){
                dossierSav2 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST3'){
                dossierSav3 = dossierSav;
            }
        }

        Test.startTest();

        //NCP diagnostiqué et commandable
        for(Case ncp : caseList){
            ncp.diagnosticDate__c = Date.today();
            //ncp.detectedWarranty__c = 'Hors garantie';
            ncp.requiredOrder__c = 'Commande';
            if(ncp.afterSalesService__c == dossierSav1.Id){
                case1 = ncp;
            }
            if(ncp.afterSalesService__c == dossierSav2.Id){
                case2 = ncp;
            }
            if(ncp.afterSalesService__c == dossierSav3.Id){
                case3 = ncp;
                ncp.requiredOrder__c = 'NON';
            }
        }
        update caselist;

        //Devis SAV
        Opportunity opp = Utils_Test.createOpportunity(accountTest, chantierTest, false);
        Opportunity opp2 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
        Opportunity opp3 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
        List<Opportunity> oppList = new List<Opportunity>{opp, opp2, opp3};
        insert oppList;
        SBQQ__Quote__c devisSav = Utils_Test.createCPQQuote(opp, false);
        devisSav.afterSalesService__c = dossierSav1.Id;
        devisSav.SBQQ__Type__c = 'SAV';
        SBQQ__Quote__c devisSav2 = Utils_Test.createCPQQuote(opp2, false);
        devisSav2.afterSalesService__c = dossierSav2.Id;
        devisSav2.SBQQ__Type__c = 'SAV';
        SBQQ__Quote__c devisSav3 = Utils_Test.createCPQQuote(opp3, false);
        devisSav3.afterSalesService__c = dossierSav3.Id;
        devisSav3.SBQQ__Type__c = 'SAV';
        List<SBQQ__Quote__c> devisSavList = new List<SBQQ__Quote__c>{devisSav, devisSav2, devisSav3};
        insert devisSavList;

        //RDV
        WorkOrder woUnconfirmed = new WorkOrder(Id = saIntervUnconfirmed.ParentRecordId, afterSalesService__c = dossierSav3.Id);
        WorkOrder woConfirmed = new WorkOrder(Id = saIntervConfirmed.ParentRecordId, afterSalesService__c = dossierSav2.Id);
        List<WorkOrder> woList = new List<WorkOrder> {woUnconfirmed, woConfirmed};
        update woList;

        WorkOrderLineItem woliUnconfirmed =  Utils_Test.createWorkOrderLineItem(woUnconfirmed.Id, case3.assetId, false);
        woliUnconfirmed.productNonCompliance__c = case3.Id;
        WorkOrderLineItem woliConfirmed =  Utils_Test.createWorkOrderLineItem(woConfirmed.Id, case2.assetId, false);
        woliConfirmed.productNonCompliance__c = case2.Id;
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>{woliUnconfirmed, woliConfirmed};
        insert woliList;
        
        saIntervConfirmed.afterSalesService__c = dossierSav2.Id;
        saIntervUnconfirmed.afterSalesService__c = dossierSav3.Id;
        List<ServiceAppointment> saList = new List<ServiceAppointment>{saIntervConfirmed, saIntervUnconfirmed};
        update saList;


        Test.stopTest();

        dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        for(AfterSalesService__c dossier : dossierSavList){
            if(dossier.description__c == 'TEST'){
                Assert.areEqual('SAV Non Commandé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST2'){
                Assert.areEqual('SAV Non Commandé Programmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST3'){
                Assert.areEqual('SAV Attente d\'Interv Non Programmé', dossier.oldCompositeStatus2__c);
            }
        }
    }

    @isTest 
    static void testOrderablePNCWithOrder() {
        Account accountTest = [SELECT Id,AccountSource,accountCallSource__c FROM Account LIMIT 1];
        Chantier__c chantierTest = [SELECT Id FROM Chantier__c LIMIT 1];
        List<AfterSalesService__c> dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        List<Case> caseList = [SELECT Id,AssetId,afterSalesService__c FROM Case];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        ServiceAppointment saIntervConfirmed = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Confirmé' LIMIT 1];
        
        //Test avec commande fournisseur non confirmé sans RDV intervention
        AfterSalesService__c dossierSav1 = null;
        //Test avec commande fournisseur non confirmé avec RDV intervention confirmé
        AfterSalesService__c dossierSav2 = null;
        //test avec commande fournisseur confirmé sans RDV intervention
        AfterSalesService__c dossierSav3 = null;
        Case case1 = null;
        Case case2 = null;
        Case case3 = null;

        for(AfterSalesService__c dossierSav : dossierSavList){
            if(dossierSav.description__c == 'TEST'){
                dossierSav1 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST2'){
                dossierSav2 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST3'){
                dossierSav3 = dossierSav;
            }
        }

        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;
        System.runAs(user){

            Test.startTest();

            //NCP diagnostiqué et commandable
            for(Case ncp : caseList){
                ncp.diagnosticDate__c = Date.today();
                //ncp.detectedWarranty__c = 'Hors garantie';
                ncp.responsability__c = 'Client';
                ncp.requiredOrder__c = 'Commande';
                if(ncp.afterSalesService__c == dossierSav1.Id){
                    case1 = ncp;
                }
                if(ncp.afterSalesService__c == dossierSav2.Id){
                    case2 = ncp;
                }
                if(ncp.afterSalesService__c == dossierSav3.Id){
                    case3 = ncp;
                }
            }
            update caselist;

            //Devis SAV
            Opportunity opp = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            Opportunity opp2 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            Opportunity opp3 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            List<Opportunity> oppList = new List<Opportunity>{opp, opp2, opp3};
            insert oppList;
            SBQQ__Quote__c devisSav = Utils_Test.createCPQQuote(opp, false);
            devisSav.afterSalesService__c = dossierSav1.Id;
            devisSav.quoteIsValid__c = true;
            devisSav.dateTransmissionClient__c = Date.today();
            devisSav.SBQQ__Type__c = 'SAV';
            devisSav.dateAcceptationClient__c = Date.Today();
            SBQQ__Quote__c devisSav2 = Utils_Test.createCPQQuote(opp2, false);
            devisSav2.afterSalesService__c = dossierSav2.Id;
            devisSav2.SBQQ__Type__c = 'SAV';
            devisSav2.quoteIsValid__c = true;
            devisSav2.dateTransmissionClient__c = Date.today();
            devisSav2.SBQQ__Type__c = 'SAV';
            SBQQ__Quote__c devisSav3 = Utils_Test.createCPQQuote(opp3, false);
            devisSav3.afterSalesService__c = dossierSav3.Id;
            devisSav3.SBQQ__Type__c = 'SAV';
            devisSav3.quoteIsValid__c = true;
            devisSav3.dateTransmissionClient__c = Date.today();
            devisSav3.SBQQ__Type__c = 'SAV';
            List<SBQQ__Quote__c> devisSavList = new List<SBQQ__Quote__c>{devisSav, devisSav2, devisSav3};
            insert devisSavList;

            //Commande fournisseur
            Order providerOrder = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder.productNonCompliance__c = case1.Id;
            providerOrder.responsability__c = 'Client';
            providerOrder.EffectiveDate = Date.today();
            Order providerOrder2 = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder2.productNonCompliance__c = case2.Id;
            providerOrder2.responsability__c = 'Client';
            providerOrder2.EffectiveDate = Date.today();
            Order providerOrder3 = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder3.productNonCompliance__c = case3.Id;
            providerOrder3.responsability__c = 'Client';
            providerOrder3.EffectiveDate = Date.today();
            List<Order> providerOrderList = new List<Order>{providerOrder, providerOrder2, providerOrder3};
            insert providerOrderList;

            OrderItem oi1 = Utils_test.createOrderItem(providerOrder.Id, pbe.Id, case1.assetId, prod.Id, false);
            OrderItem oi2 = Utils_test.createOrderItem(providerOrder2.Id, pbe.Id, case2.assetId, prod.Id, false);
            OrderItem oi3 = Utils_test.createOrderItem(providerOrder3.Id, pbe.Id, case3.assetId, prod.Id, false);
            oi3.confirmationDate__c = Date.Today();
            List<OrderItem> oiList = new List<OrderItem>{oi1, oi2, oi3};
            insert oiList;

            //RDV
            WorkOrder woConfirmed = new WorkOrder(Id = saIntervConfirmed.ParentRecordId, afterSalesService__c = dossierSav2.Id);
            update woConfirmed;
            WorkOrderLineItem woliConfirmed =  Utils_Test.createWorkOrderLineItem(woConfirmed.Id, case2.assetId, false);
            woliConfirmed.productNonCompliance__c = case2.Id;
            insert woliConfirmed;
            saIntervConfirmed.afterSalesService__c = dossierSav2.Id;
            update saIntervConfirmed;
        }
        Test.stopTest();

        dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        for(AfterSalesService__c dossier : dossierSavList){
            if(dossier.description__c == 'TEST'){
                Assert.areEqual('SAV Non Confirmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST2'){
                Assert.areEqual('SAV Non Confirmé Programmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST3'){
                Assert.areEqual('SAV Non livré Non Préparé', dossier.oldCompositeStatus2__c);
            }
        }
    }

    @isTest 
    static void testPipelineECI() {
        List<AfterSalesService__c> dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        Account accountTest = [SELECT Id,AccountSource,accountCallSource__c FROM Account LIMIT 1];
        Chantier__c chantierTest = [SELECT Id FROM Chantier__c LIMIT 1];
        List<Case> caseList = [SELECT Id,AssetId,afterSalesService__c FROM Case];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        ServiceAppointment saIntervConfirmed = [SELECT Id,ParentRecordId,WorkTypeId,RecordTypeId,dateConfirmationClient__c,fsl_dateConfirmation__c,status,SchedEndTime,SchedStartTime FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Confirmé' LIMIT 1];
        ServiceAppointment saIntervUnConfirmed = [SELECT Id,ParentRecordId,WorkTypeId FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Demandé' LIMIT 1];
        ServiceAppointment saIntervDebriefed = [SELECT Id,ParentRecordId,WorkTypeId,status,fsl_dateConfirmation__c,dateConfirmationClient__c,SchedEndTime,SchedStartTime,ActualEndTime,ActualStartTime,
                                                fsl_dateDebriefing__c, RecordTypeId FROM ServiceAppointment WHERE workTypeName__c = 'Intervention' AND Status = 'Débriefé' LIMIT 1];
        
        //Test ECI avec commande non livrée et RDV intervention non programmé
        AfterSalesService__c dossierSav1 = null;
        //Test ECI non livrée et RDV intervention programmé
        AfterSalesService__c dossierSav2 = null;
        //Test ECI livré et intervention programmée
        AfterSalesService__c dossierSav3 = null;
        Case case1 = null;
        Case case2 = null;
        Case case3 = null;

        for(AfterSalesService__c dossierSav : dossierSavList){
            if(dossierSav.description__c == 'TEST'){
                dossierSav1 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST2'){
                dossierSav2 = dossierSav;
            }
            if(dossierSav.description__c == 'TEST3'){
                dossierSav3 = dossierSav;
            }
        }

        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;
        System.runAs(user){
            Test.startTest();

            //NCP diagnostiqué et commandable
            for(Case ncp : caseList){
                ncp.diagnosticDate__c = Date.today();
                //ncp.detectedWarranty__c = 'Hors garantie';
                ncp.responsability__c = 'Client';
                ncp.requiredOrder__c = 'Commande';
                if(ncp.afterSalesService__c == dossierSav1.Id){
                    case1 = ncp;
                }
                if(ncp.afterSalesService__c == dossierSav2.Id){
                    case2 = ncp;
                }
                if(ncp.afterSalesService__c == dossierSav3.Id){
                    case3 = ncp;
                }
            }
            update caselist;

            //Devis SAV
            Opportunity opp = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            Opportunity opp2 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            Opportunity opp3 = Utils_Test.createOpportunity(accountTest, chantierTest, false);
            List<Opportunity> oppList = new List<Opportunity>{opp, opp2, opp3};
            insert oppList;
            SBQQ__Quote__c devisSav = Utils_Test.createCPQQuote(opp, false);
            devisSav.afterSalesService__c = dossierSav1.Id;
            devisSav.quoteIsValid__c = true;
            devisSav.dateTransmissionClient__c = Date.today();
            devisSav.SBQQ__Type__c = 'SAV';
            devisSav.dateAcceptationClient__c = Date.Today();
            SBQQ__Quote__c devisSav2 = Utils_Test.createCPQQuote(opp2, false);
            devisSav2.afterSalesService__c = dossierSav2.Id;
            devisSav2.SBQQ__Type__c = 'SAV';
            devisSav2.quoteIsValid__c = true;
            devisSav2.dateTransmissionClient__c = Date.today();
            devisSav2.SBQQ__Type__c = 'SAV';
            List<SBQQ__Quote__c> devisSavList = new List<SBQQ__Quote__c>{devisSav, devisSav2};
            insert devisSavList;

            //Commande fournisseur
            Order providerOrder = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder.productNonCompliance__c = case1.Id;
            providerOrder.responsability__c = 'Client';
            providerOrder.EffectiveDate = Date.today();
            Order providerOrder2 = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder2.productNonCompliance__c = case2.Id;
            providerOrder2.responsability__c = 'Client';
            providerOrder2.EffectiveDate = Date.today();
            Order providerOrder3 = Utils_Test.createProviderOrder(accountTest.Id,null,null, false);
            providerOrder3.productNonCompliance__c = case3.Id;
            providerOrder3.responsability__c = 'Client';
            providerOrder3.EffectiveDate = Date.today();
            
            List<Order> providerOrderList = new List<Order>{providerOrder, providerOrder2, providerOrder3};
            insert providerOrderList;

            OrderItem oi1 = Utils_test.createOrderItem(providerOrder.Id, pbe.Id, case1.assetId, prod.Id, false);
            oi1.confirmationDate__c = Date.Today();
            OrderItem oi2 = Utils_test.createOrderItem(providerOrder2.Id, pbe.Id, case2.assetId, prod.Id, false);
            oi2.confirmationDate__c = Date.Today();
            OrderItem oi3 = Utils_test.createOrderItem(providerOrder3.Id, pbe.Id, case3.assetId, prod.Id, false);
            oi3.confirmationDate__c = Date.Today();
            oi3.deliveryDate__c = Date.Today();
            List<OrderItem> oiList = new List<OrderItem>{oi1, oi2, oi3};
            insert oiList;

            //RDV

            WorkOrder woDebriefed2 = Utils_Test.createWorkOrder(wkRTId, false);
            woDebriefed2.WorkTypeId = saIntervDebriefed.WorkTypeId;
            WorkOrder woDebriefed3 = Utils_Test.createWorkOrder(wkRTId, false);
            woDebriefed3.WorkTypeId = saIntervDebriefed.WorkTypeId;
            WorkOrder woConfirmedWithDate = Utils_Test.createWorkOrder(wkRTId, false);
            woConfirmedWithDate.WorkTypeId = saIntervDebriefed.WorkTypeId;
            List<WorkOrder> woListToInsert = new List<WorkOrder>{woDebriefed2,woDebriefed3,woConfirmedWithDate};
            insert woListToInsert;

            ServiceAppointment saIntervDebriefed2 = saIntervDebriefed.clone(false,false,false,false);
            saIntervDebriefed2.ParentRecordId = woDebriefed2.Id;
            ServiceAppointment saIntervDebriefed3 = saIntervDebriefed.clone(false,false,false,false);
            saIntervDebriefed3.ParentRecordId = woDebriefed3.Id; 
            ServiceAppointment saIntervConfirmedWithDate = saIntervConfirmed.clone(false,false,false,false);
            saIntervConfirmedWithDate.fsl_dateConfirmation__c = Date.Today();
            saIntervConfirmedWithDate.ParentRecordId = woConfirmedWithDate.Id;
            List<ServiceAppointment> saListToInsert = new List<ServiceAppointment>{saIntervDebriefed2, saIntervDebriefed3, saIntervConfirmedWithDate};
            insert saListToInsert;

            WorkOrder woUnconfirmed = new WorkOrder(Id = saIntervUnconfirmed.ParentRecordId, afterSalesService__c = dossierSav1.Id);
            WorkOrder woDebriefed = new WorkOrder(Id = saIntervDebriefed.ParentRecordId, afterSalesService__c = dossierSav1.Id);
            WorkOrder woConfirmed = new WorkOrder(Id = saIntervConfirmed.ParentRecordId, afterSalesService__c = dossierSav2.Id);
            woDebriefed2.afterSalesService__c = dossierSav2.Id;
            woDebriefed3.afterSalesService__c = dossierSav3.Id;
            woConfirmedWithDate.afterSalesService__c = dossierSav3.Id;
            List<WorkOrder> woList = new List<WorkOrder> {woUnconfirmed, woConfirmed, woDebriefed, woDebriefed2, woDebriefed3, woConfirmedWithDate};
            update woList;

            WorkOrderLineItem woliUnconfirmed =  Utils_Test.createWorkOrderLineItem(woUnconfirmed.Id, case1.assetId, false);
            woliUnconfirmed.productNonCompliance__c = case1.Id;
            WorkOrderLineItem woliDebriefed =  Utils_Test.createWorkOrderLineItem(woDebriefed.Id, case1.assetId, false);
            woliDebriefed.productNonCompliance__c = case1.Id;
            WorkOrderLineItem woliConfirmed =  Utils_Test.createWorkOrderLineItem(woConfirmed.Id, case2.assetId, false);
            woliConfirmed.productNonCompliance__c = case2.Id;
            WorkOrderLineItem woliDebriefed2 =  Utils_Test.createWorkOrderLineItem(woDebriefed2.Id, case2.assetId, false);
            woliDebriefed2.productNonCompliance__c = case2.Id;
            WorkOrderLineItem woliDebriefed3 =  Utils_Test.createWorkOrderLineItem(woDebriefed3.Id, case3.assetId, false);
            woliDebriefed3.productNonCompliance__c = case3.Id;
            WorkOrderLineItem woliConfirmedWithDate =  Utils_Test.createWorkOrderLineItem(woConfirmedWithDate.Id, case3.assetId, false);
            woliConfirmedWithDate.productNonCompliance__c = case3.Id;
            
            List<WorkOrderLineItem> woliDebriefedList = new List<WorkOrderLineItem>{woliDebriefed, woliDebriefed2, woliDebriefed3};
            insert woliDebriefedList;
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>{woliUnconfirmed, woliConfirmed, woliConfirmedWithDate};
            insert woliList;
            
            saIntervUnconfirmed.afterSalesService__c = dossierSav1.Id;
            saIntervDebriefed.afterSalesService__c = dossierSav1.Id;
            saIntervConfirmed.afterSalesService__c = dossierSav2.Id;
            saIntervDebriefed2.afterSalesService__c = dossierSav2.Id;
            saIntervDebriefed3.afterSalesService__c = dossierSav3.Id;
            saIntervConfirmedWithDate.afterSalesService__c = dossierSav3.Id;

            List<ServiceAppointment> saList = new List<ServiceAppointment>{saIntervConfirmed, saIntervUnconfirmed, saIntervDebriefed, saIntervDebriefed2, saIntervDebriefed3, saIntervConfirmedWithDate};
            update saList;
        } 
        Test.stopTest();
        dossierSavList = [SELECT Id,oldCompositeStatus2__c,description__c FROM AfterSalesService__c];
        for(AfterSalesService__c dossier : dossierSavList){
            if(dossier.description__c == 'TEST'){
                Assert.areEqual('SAV ECI Non Livré Non Programmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST2'){
                Assert.areEqual('SAV ECI Non Livré Programmé', dossier.oldCompositeStatus2__c);
            }
            if(dossier.description__c == 'TEST3'){
                Assert.areEqual('SAV ECI Attente d\'Interv programmée', dossier.oldCompositeStatus2__c);
            }
        }
    }



}