//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_UpdateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 05/09/2023
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_QA_UpdateOrderStatusGC {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);         
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService'); 
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String RT_AP_DOUBTFULDEBT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_DOUBTFULDEBT_RT);
    private final static String BYPASS_TRIGGER = 'TR020_Account;TR021_Chantier;TR022_Chantier;TR023_Chantier;TR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;' +
            'TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040';

    @testSetup 
    static void testSetup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false));
        refList.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
        insert accList;
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c = secto.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
    }

    @isTest 
    static void test1() {
    
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;
        System.runAs(user){
        
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prod.iscontrollable__c = true;
            insert prod;
            
            // Objets de base
            //Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Account a = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            //SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            //Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            insert provider1;
            
            // Création banque
            Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            Referencial__c bankAccount = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
            BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bankAccount.Id, entity__c=ent.Id, startDate__c = Date.today());
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            
            // listes d'insertion
            List<Asset> assetList = new List<Asset>();
            List<Case> caseList = new List<Case>();
            List<WorkOrder> woList = new List<WorkOrder>();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            
            // passage en non transmis
            /*cpqQuote.quoteIsValid__c = true;
            update cpqQuote;
    
            // puis passage en vendu
            cpqQuote.dateAcceptationClient__c = Date.today();
            update cpqQuote;*/
            
            Test.startTest();
            
            // Commandes
            List<Order> orderList = new List<Order>();
            //Test commande non métré non programmé
            Order ord = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            orderList.add(ord);

            //test commande non validée - Statut GC null
            Order ordNotValidated = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            orderList.add(ordNotValidated);

            //test commande annulée - Statut GC résilié
            Order ordCancelled = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            orderList.add(ordCancelled);

            insert orderList;

            ordCancelled.isValid__c = true;
            ordCancelled.cancellingDate__c = Date.today();
            ord.isValid__c = true;
            ord.cancellingDate__c = null;
            update orderList;
            
            Order newProviderOrder1 = Utils_Test.createProviderOrder(a.Id, ord.Id, provider1.Id ,true);
            
            // Actifs
            Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset1.customerOrder__c = ord.Id;
            asset1.chantier__c = chantier.Id;
            assetList.add(asset1);
            
            Asset asset2 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset2.customerOrder__c = ord.Id;
            asset2.chantier__c = chantier.Id;
            assetList.add(asset2);
            
            insert assetList;
            
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :prod.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == prod.Id) pbEntry = pbeSelected;                
            }
    
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, asset2.Id, prod.Id, false);
            newOrderItem1.confirmationDate__c = Date.today();
            insert newOrderItem1;
        
            // NPC
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case1.AssetId=asset1.Id;
            case1.type = 'ECI';
            caseList.add(case1);
            
            Case case2 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case2.AssetId=asset2.Id;
            case2.diagnosticDate__c = Date.today();
            case2.inStock__c = false;
            case2.requiredOrder__c = Constants.NCP_REQUIREDORDER_RECOMMANDE;
            case2.type = 'ECI';
            caseList.add(case2);
            
            insert caseList;
    
            // Creation Rendez-vous
            List<WorkType> wkLlist = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wkLlist.add(wt1);
            wkLlist.add(wt2);
            wkLlist.add(wt3);
            insert wkLlist;           
            
            WorkOrder wo1 = Utils_Test.createWorkOrder(wkRTId, false);
            wo1.customerOrder__c = ord.Id;
            wo1.WorkTypeId = wt1.Id;
            wo1.subWorkType__c = 'Pose';
            woList.add(wo1);
            
            WorkOrder wo2 = Utils_Test.createWorkOrder(wkRTId, false);
            wo2.customerOrder__c = ord.Id;
            wo2.WorkTypeId = wt2.Id;
            woList.add(wo2);
    
            WorkOrder wo3 = Utils_Test.createWorkOrder(wkRTId, false);
            wo3.customerOrder__c = ord.Id;
            wo3.WorkTypeId = wt3.Id;
            woList.add(wo3);
            
            WorkOrder wo4 = Utils_Test.createWorkOrder(wkRTId, false);
            wo4.customerOrder__c = ord.Id;
            wo4.WorkTypeId = wt2.Id;
            woList.add(wo4);
            
            insert woList;
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo1.Id, SASARTId, false);
            sa1.Status='En cours';
            sa1.customerOrder__c = ord.Id;
            sa1.ActualStartTime=Date.today()-1;
            sa1.SchedEndTime=Date.today()+1;
            sa1.SchedStartTime=Date.today()-1;
            sa1.fsl_techOrdreExecutionParent__c = wo1.Id;
            saList.add(sa1);
            
            ServiceAppointment sa2 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
            sa2.Status='Confirmé';
            sa2.customerOrder__c = ord.Id;
            sa2.fsl_dateConfirmation__c=Date.today()-1;
            sa2.dateConfirmationClient__c=Date.today()-1;
            sa2.SchedEndTime=Date.today()+1;
            sa2.SchedStartTime=Date.today()-1;
            sa2.fsl_techOrdreExecutionParent__c = wo2.Id;
            saList.add(sa2);
            
            ServiceAppointment sa3 = Utils_Test.createServiceAppointment(wo3.Id, SASARTId, false);
            sa3.Status='En cours';
            sa3.customerOrder__c = ord.Id;
            sa3.ActualStartTime=Date.today()-1;
            sa3.fsl_dateConfirmation__c=Date.today()-1;
            sa3.dateConfirmationClient__c=Date.today()-1;
            sa3.SchedEndTime=Date.today()+1;
            sa3.SchedStartTime=Date.today()-1;
            saList.add(sa3);
            
            ServiceAppointment sa4 = Utils_Test.createServiceAppointment(wo4.Id, SASARTId, false);
            sa4.Status=Constants.RDV_FSL_DEBRIEFE;
            sa4.customerOrder__c = ord.Id;
            sa4.ActualStartTime=Date.today()-1;
            sa4.fsl_dateConfirmation__c=Date.today()-1;
            sa4.dateConfirmationClient__c=Date.today()-1;
            sa4.SchedEndTime=Date.today()+1;
            sa4.SchedStartTime=Date.today()-1;
            sa4.ActualEndTime=Date.today()-1;
            sa4.fsl_dateDebriefing__c=Date.today()-1;
            saList.add(sa4);
            
            insert saList;
            
            WorkOrderLineItem woli11 = Utils_Test.createWorkOrderLineItem(wo1.Id, asset1.Id, false);
            woli11.WorkTypeId = wt3.Id;
            WorkOrderLineItem woli12 = Utils_Test.createWorkOrderLineItem(wo1.Id, asset2.Id, false);
            WorkOrderLineItem woli21 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset1.Id, false);
            WorkOrderLineItem woli22 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset2.Id, false);
            WorkOrderLineItem woli31 = Utils_Test.createWorkOrderLineItem(wo3.Id, asset1.Id, false);
            WorkOrderLineItem woli32 = Utils_Test.createWorkOrderLineItem(wo3.Id, asset2.Id, false);
            WorkOrderLineItem woli41 = Utils_Test.createWorkOrderLineItem(wo4.Id, asset1.Id, false);
            WorkOrderLineItem woli42 = Utils_Test.createWorkOrderLineItem(wo4.Id, asset2.Id, false);
            woliList.add(woli11);
            woliList.add(woli12);
            woliList.add(woli21);
            woliList.add(woli22);
            woliList.add(woli31);
            woliList.add(woli32);
            woliList.add(woli41);
            woliList.add(woli42);
            insert woliList;

            ServiceAppointment saWoli = Utils_Test.createServiceAppointment(woli11.Id, SASARTId, false);
            saWoli.Status='En cours';
            saWoli.customerOrder__c = ord.Id;
            saWoli.ActualStartTime=Date.today()-1;
            saWoli.fsl_dateConfirmation__c=Date.today()-1;
            saWoli.dateConfirmationClient__c=Date.today()-1;
            saWoli.SchedEndTime=Date.today()+1;
            saWoli.SchedStartTime=Date.today()-1;
            saWoli.fsl_techOrdreExecutionParent__c = wo1.Id;
            insert saWoli;
     
            asset1.controldate__c=Date.today();
            asset1.Status = 'Métré';
            asset2.controldate__c=Date.today();
            asset2.Status = 'Métré';
            
            update assetList;
            
            AccountingPiece__c ap = Utils_Test.createAccountingPiece(RT_AP_DOUBTFULDEBT, ord.Id, ent.Id, ent.Id, bankAccount.Id, paymentMethod.Id, null, null, 100, Date.today(), null, Date.today(), true);
            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ord.Id,ordNotValidated.Id,ordCancelled.Id}));
            
            Test.stopTest();

            ord = [SELECT oldCompositeStatus__c FROM Order WHERE Id =:ord.Id];
            ordNotValidated = [SELECT oldCompositeStatus__c FROM Order WHERE Id =:ordNotValidated.Id];
            ordCancelled = [SELECT oldCompositeStatus__c FROM Order WHERE Id =:ordCancelled.Id];

            Assert.areEqual(null,ordNotValidated.oldCompositeStatus__c);
            Assert.areEqual('Résilié',ordCancelled.oldCompositeStatus__c);
            Assert.areEqual('Non métré non programmé',ord.oldCompositeStatus__c);
        }        
    }

    @isTest
    static void testPassageSoldee() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;


        System.runAs(user){
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prod.iscontrollable__c = true;
            prod.isInstallable__c = true;
            insert prod;

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Account a = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            List<Asset> assetList = new List<Asset>();

            Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

            // passage en non transmis
            cpqQuote.quoteIsValid__c = true;
            update cpqQuote;

            // puis passage en vendu
            cpqQuote.dateAcceptationClient__c = Date.today();
            update cpqQuote;

            Test.startTest();
            
            //Commande avec toutes les actifs installées
            List<Order> orderList = new List<Order>();
            //test commande soldé
            Order ordSolde = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ordSolde.isValid__c = true;
            ordSolde.installationCompletionDate__c = Date.today();
            ordSolde.amount__c = 100;
            ordSolde.invoicesAmount__c  = 100;
            ordSolde.creditMemosAmount__c = 0;
            ordSolde.recordedAccountingPiecesAmount__c = 100;
            orderList.Add(ordSolde);

            //test commande soldé NC
            Order ordSoldeNC = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ordSoldeNC.isValid__c = true;
            ordSoldeNC.installationCompletionDate__c = Date.today();
            ordSoldeNC.amount__c = 100;
            ordSoldeNC.invoicesAmount__c  = 100;
            ordSoldeNC.creditMemosAmount__c = 0;
            ordSoldeNC.recordedAccountingPiecesAmount__c = 200;
            orderList.add(ordSoldeNC);

            //test commande totalament installé
            Order ordInstalled = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ordInstalled.isValid__c = true;
            ordInstalled.installationCompletionDate__c = Date.today();
            orderList.add(ordInstalled);
            
            insert orderList;

            Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', ordSolde.Id, prod.Id, a.Id, false);
            asset1.customerOrder__c = ordSolde.Id;
            asset1.chantier__c =  chantier.Id;
            asset1.installdate = Date.Today();
            assetList.add(asset1);
            
            Asset asset2 = Utils_Test.createAsset(assetEntityRT, 'Test2', ordSoldeNC.Id, prod.Id, a.Id, false);
            asset2.customerOrder__c = ordSoldeNC.Id;
            asset2.chantier__c =  chantier.Id;
            asset2.installdate = Date.Today();
            assetList.add(asset2);

            Asset asset3 = Utils_Test.createAsset(assetEntityRT, 'Test3', ordInstalled.Id, prod.Id, a.Id, false);
            asset3.customerOrder__c = ordInstalled.Id;
            asset3.chantier__c =  chantier.Id;
            asset3.installdate = Date.Today();
            assetList.add(asset3);
            
            insert assetList;

            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ordSolde.Id,ordSoldeNC.Id,ordInstalled.Id}));
            
            Test.stopTest();

            ordSolde = [SELECT oldCompositeStatus__c,invoiceableAmount__c,netBalance__c FROM Order WHERE id =:ordSolde.Id]; 
            ordSoldeNC = [SELECT oldCompositeStatus__c,invoiceableAmount__c,netBalance__c FROM Order WHERE id =:ordSoldeNC.Id]; 
            ordInstalled = [SELECT oldCompositeStatus__c FROM Order WHERE id =:ordInstalled.Id]; 

            Assert.areEqual('Soldé',ordSolde.oldCompositeStatus__c);
            Assert.areEqual('Soldé NC',ordSoldeNC.oldCompositeStatus__c);
            Assert.areEqual('Totalement installé',ordInstalled.oldCompositeStatus__c);
        }
    }
    
    @isTest 
    static void interventionEnCours() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;

        System.runAs(user){
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prod.iscontrollable__c = true;
            prod.isInstallable__c = true;
            insert prod;

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Account a = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            insert provider1;
            
            // Création banque
            Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];        
            
            List<Asset> assetList = new List<Asset>();
            List<Case> caseList = new List<Case>();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            List<WorkOrder> woList = new List<WorkOrder>();
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            
            // passage en non transmis
            cpqQuote.quoteIsValid__c = true;
            update cpqQuote;

            // puis passage en vendu
            cpqQuote.dateAcceptationClient__c = Date.today();
            update cpqQuote;

            Test.startTest();
            
            List<Order> orderList = new List<Order>();
            //Test ECI du jour
            Order ord = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ord.isValid__c = true;
            ord.firstDiagnosticSADate__c = Date.Today();
            orderList.add(ord);

            //Test Pose du jour
            Order ordPoseduJour = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ordPoseduJour.isValid__c = true;
            orderList.add(ordPoseduJour);

            //Test ECI en attente d’installation programmé
            Order ordECIAttenteInstallProg = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            ordECIAttenteInstallProg.isValid__c = true;
            ordECIAttenteInstallProg.firstDiagnosticSADate__c = Date.today();
            orderList.add(ordECIAttenteInstallProg);

            insert orderList;
            
            Order newProviderOrder1 = Utils_Test.createProviderOrder(a.Id, ord.Id, provider1.Id ,false);
            insert newProviderOrder1;
        
            Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset1.customerOrder__c = ord.Id;
            asset1.chantier__c =  chantier.Id;
            asset1.installdate = Date.Today();
            asset1.controldate__c = Date.Today();
            assetList.add(asset1);
            
            Asset asset2 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset2.customerOrder__c = ord.Id;
            asset2.chantier__c =  chantier.Id;
            assetList.add(asset2);
            
            insert assetList;

            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case1.AssetId=asset1.Id;
            case1.diagnosticDate__c = Date.today();
            caseList.add(case1);
            
            Case case2 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case2.AssetId=asset2.Id;
            case2.diagnosticDate__c = Date.today();
            case2.inStock__c = false;
            case2.requiredOrder__c = Constants.NCP_REQUIREDORDER_RECOMMANDE;
            case2.diagnosticDate__c = Date.today();
            caseList.add(case2);
            
            insert caseList;

            // Creation Rendez-vous
            List<WorkType> wkLlist = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wkLlist.add(wt1);
            wkLlist.add(wt2);
            wkLlist.add(wt3);
            insert wkLlist;
            
            WorkOrder wo1 = Utils_Test.createWorkOrder(wkRTId, false);
            wo1.customerOrder__c = ord.Id;
            wo1.WorkTypeId = wt2.Id;
            wo1.subWorkType__c = 'Pose';
            woList.add(wo1);
            
            WorkOrder wo2 = Utils_Test.createWorkOrder(wkRTId, false);
            wo2.customerOrder__c = ord.Id;
            wo2.WorkTypeId = wt2.Id;
            wo2.subWorkType__c = 'ECI';
            woList.add(wo2);
            
            insert woList;
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo1.Id, SASARTId, false);
            sa1.Status=Constants.RDV_FSL_DEBRIEFE;
            sa1.customerOrder__c = ord.Id;
            sa1.ActualStartTime=Date.today()-1;
            sa1.fsl_dateConfirmation__c=Date.today()-1;
            sa1.dateConfirmationClient__c=Date.today()-1;
            sa1.SchedEndTime=Date.today()+1;
            sa1.SchedStartTime=Date.today()-1;
            sa1.ActualEndTime=Date.today()-1;
            sa1.fsl_dateDebriefing__c=Date.today()-1;
            sa1.fsl_techOrdreExecutionParent__c = wo1.Id;
            sa1.dateTransmission__c = Date.Today();
            saList.add(sa1);

            ServiceAppointment sa1Doublon = sa1.clone(false,true,false,false);
            insert sa1Doublon;

            
            ServiceAppointment sa2 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
            sa2.Status='En cours';
            sa2.customerOrder__c = ord.Id;
            sa2.ActualStartTime=Date.today()-1;
            sa2.fsl_dateConfirmation__c=Date.today()-1;
            sa2.dateConfirmationClient__c=Date.today()-1;
            sa2.SchedEndTime=Date.today()+1;
            sa2.SchedStartTime=Date.today()-1;
            sa2.fsl_techOrdreExecutionParent__c = wo2.Id;
            saList.add(sa2);

            ServiceAppointment sa3 = Utils_Test.createServiceAppointment(wo1.Id, SASARTId, false);
            sa3.Status='En cours';
            sa3.customerOrder__c = ordPoseduJour.Id;
            sa3.ActualStartTime=Date.today()-1;
            sa3.fsl_dateConfirmation__c=Date.today()-1;
            sa3.dateConfirmationClient__c=Date.today()-1;
            sa3.SchedEndTime=Date.today()+1;
            sa3.SchedStartTime=Date.today()-1;
            sa3.fsl_techOrdreExecutionParent__c = wo1.Id;
            saList.add(sa3);

            ServiceAppointment sa4 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
            sa4.Status=Constants.RDV_FSL_DEBRIEFE;
            sa4.customerOrder__c = ordECIAttenteInstallProg.Id;
            sa4.ActualStartTime=Date.today()-1;
            sa4.SchedEndTime=Date.today()+1;
            sa4.SchedStartTime=Date.today()-1;
            sa4.fsl_dateConfirmation__c = Date.today()-1;
            sa4.fsl_techOrdreExecutionParent__c = wo2.Id;
            saList.add(sa4);
            
            insert saList;

            WorkOrderLineItem woli21 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset1.Id, false);
            WorkOrderLineItem woli22 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset2.Id, false);
            woliList.add(woli21);
            woliList.add(woli22);

            insert woliList;
    
            asset1.controldate__c=Date.today();
            asset1.Status = 'Métré';
            update asset1;
            asset2.controldate__c=Date.today();
            asset2.Status = 'Métré';
            update asset2;
            
            ord.providerOrderOrderedCount__c = 1;
            update ord;
            
            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ord.Id,ordPoseduJour.Id,ordECIAttenteInstallProg.Id}));
            Test.stopTest();

            ord = [SELECT oldCompositeStatus__c FROM Order WHERE id =: ord.Id];
            ordPoseduJour = [SELECT oldCompositeStatus__c FROM Order WHERE id =: ordPoseduJour.Id];
            ordECIAttenteInstallProg  = [SELECT oldCompositeStatus__c FROM Order WHERE id =: ordECIAttenteInstallProg.Id];

            Assert.areEqual('ECI du jour', ord.oldCompositeStatus__c);
            Assert.areEqual('Pose du jour', ordPoseduJour.oldCompositeStatus__c);
            Assert.areEqual('ECI en attente d’installation programmé', ordECIAttenteInstallProg.oldCompositeStatus__c);
            
        }
    }
    
    @isTest 
    static void interventionPlanifie() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        insert user;

        System.runAs(user){
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prod.iscontrollable__c = true;
            insert prod;

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Account a = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            insert provider1;
            
            // Création banque
            Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];        
            
            List<Asset> assetList = new List<Asset>();
            List<Case> caseList = new List<Case>();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            
            // passage en non transmis
            cpqQuote.quoteIsValid__c = true;
            update cpqQuote;

            // puis passage en vendu
            cpqQuote.dateAcceptationClient__c = Date.today();
            update cpqQuote;
            
            Test.startTest();
            
            List<Order> orderList = new List<Order>();
            Order ord = Utils_Test.createCustomerOrder(a.Id, chantier.Id, ent.id, ent.id, false);
            orderList.add(ord);
            
            Order newProviderOrder1 = Utils_Test.createProviderOrder(a.Id, ord.Id, provider1.Id ,false);
            
            orderList.add(newProviderOrder1);
            insert orderList;

            Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset1.customerOrder__c = ord.Id;
            asset1.chantier__c = chantier.Id;
            assetList.add(asset1);
            
            Asset asset2 = Utils_Test.createAsset(assetEntityRT, 'Test', ord.Id, prod.Id, a.Id, false);
            asset2.customerOrder__c = ord.Id;
            asset2.chantier__c = chantier.Id;
            assetList.add(asset2);
            
            insert assetList;

            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case1.AssetId=asset1.Id;
            case1.customerOrder__c = ord.Id;
            caseList.add(case1);
            
            Case case2 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, chantier.Id, false);
            case2.AssetId=asset2.Id;
            case2.customerOrder__c = ord.Id;
            case2.diagnosticDate__c = Date.today();
            case2.inStock__c = false;
            case2.requiredOrder__c = Constants.NCP_REQUIREDORDER_RECOMMANDE;
            caseList.add(case2);
            
            insert caseList;

            // Creation Rendez-vous
            List<WorkType> wkLlist = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wkLlist.add(wt1);
            wkLlist.add(wt2);
            wkLlist.add(wt3);
            insert wkLlist;
            
            WorkOrder wo2 = Utils_Test.createWorkOrder(wkRTId, false);
            wo2.customerOrder__c = ord.Id;
            wo2.WorkTypeId = wt2.Id;
            insert wo2;
            
            ServiceAppointment sa2 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
            sa2.Status='Confirmé';
            sa2.customerOrder__c = ord.Id;
            sa2.fsl_dateConfirmation__c=Date.today()-1;
            sa2.dateConfirmationClient__c=Date.today()-1;
            sa2.SchedEndTime=Date.today()+1;
            sa2.SchedStartTime=Date.today()+1;
            insert sa2;
            
            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ord.Id}));
            
            WorkOrderLineItem woli21 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset1.Id, false);
            WorkOrderLineItem woli22 = Utils_Test.createWorkOrderLineItem(wo2.Id, asset2.Id, false);
            woliList.add(woli21);
            woliList.add(woli22);

            insert woliList;
    
            
            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ord.Id}));

            asset1.controldate__c=Date.today();
            asset1.Status = 'Métré';
            update asset1;
            asset2.controldate__c=Date.today();
            asset2.Status = 'Métré';
            update asset2;
            
            ord.providerOrderOrderedCount__c = 1;
            update ord;
            
            System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{ord.Id}));

            Test.stopTest();
        }
    }

    
}