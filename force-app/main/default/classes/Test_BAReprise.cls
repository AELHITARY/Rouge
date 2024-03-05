//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BAReprise
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 02/11/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_BAReprise {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    @testSetup 
    static void setup() {
        // Récupération des types d'enregistrement
        //Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        //Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        
        // Création entite        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account ent = Utils_Test.createEntity('Magasin 123', 'M123', Date.today(), '0123456789', refMag.Id, false);     
        //Utils_Test.createEntity('Depot 123', 'D123', Date.today(), '0123456789', refMag.Id, true); 
        
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true); 
        // Création d'un compte
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', rtB2C, 'FAX', false);
        account.sectorisation__c = sect.Id;
        account.PersonMobilePhone= '0606060606';
        List<Account> accList = new List<Account>();
        accList.add(ent);
        accList.add(account);
        insert accList;
        // Création chantiers
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, false);   
        chantier.sectorisation__c = sect.Id;
        insert chantier;  
    }

    @isTest 
    static void test_BA_RepriseChampsAccount() {
        Test.StartTest();
        String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
        Account acc = [SELECT Id, PersonContactId, AccountSource, accountCallSource__c FROM Account LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        Utils_Test.createContrat(quote, true);
        
        // Exécution du test

        BA_RepriseChampsAccount ba = new BA_RepriseChampsAccount();
        Database.executeBatch(ba);

        Test.stopTest();
    }  

    @isTest 
    static void test_BA_RepriseChampsChantier() {
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        
        // Exécution du test
        Test.StartTest();

        BA_RepriseChampsChantier ba = new BA_RepriseChampsChantier();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsCase() {
        String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];        
        
        List<Case> casesList = new List<Case>();
        Case cs = new Case(AccountId = acc.Id, 
                            chantier__c = chantier.Id,
                            ContactId = acc.PersonContactId,
                            Type = 'Réclamation métrage',
                            typeDeRendezVous__c = 'Métrage',
                            RecordTypeId = RT_RECLAMATIONID);
        casesList.add(cs); 
        Case cs2 = new Case(AccountId = acc.Id, 
                            chantier__c = chantier.Id,
                            ContactId = acc.PersonContactId,
                            Type = 'Réclamation commerciale',
                            typeDeRendezVous__c = 'Commercial',
                            RecordTypeId = RT_RECLAMATIONID);
        casesList.add(cs2); 
        Case cs3 = new Case(AccountId = acc.Id, 
                            chantier__c = chantier.Id,
                            ContactId = acc.PersonContactId,
                            Type = 'Réclamation marketing',
                            RecordTypeId = RT_RECLAMATIONID);
        casesList.add(cs3); 
        Test.StartTest();
        Case cs4 = new Case(AccountId = acc.Id, 
                            chantier__c = chantier.Id,
                            ContactId = acc.PersonContactId,
                            RecordTypeId = RT_RECLAMATIONID);
        casesList.add(cs4); 
        insert casesList;
        
          
        cs.Status = 'Clôturé';
        update cs;
        
        // Exécution du test

        BA_RepriseChampsCase ba= new BA_RepriseChampsCase();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsEvent() {
        Test.StartTest();
        Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Id rtProspection = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
        Id rtA = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_Vendeur_RT);
        Id rtB = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_TA_RT);
        //Account acc = [SELECT Id, PersonContactId, AccountSource, accountCallSource__c FROM Account LIMIT 1];
        //Account account = DAL.getAccountById(acc.Id);
        Account B2C1 = Utils_Test.createAccount('Nom', 'Prénom', 'test@kpark.fr', rtB2C,'Email',false);
        B2C1.personHomePhone = '010203ADGJ';
        B2C1.personMobilePhone = '060203ADGJ';
        B2C1.personOtherPhone = '010204TEST';
        B2C1.phone = '010204MPTW';
        B2C1.fax = '010204MPTW';
        B2C1.Localisation__Latitude__s = 0;
        B2C1.Localisation__Longitude__s = 0;
        //B2C1.iris__c = sect.iris__c;
        insert B2C1;
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, true);
        Opportunity prj = [SELECT Id, Account.contactParDefaut__c FROM Opportunity];
        Event evt = Utils_Test.createEvent('R1',rtRDV,projet.id,prj.Account.contactParDefaut__c,null,'Pris', false);
        Event evt2 = Utils_Test.createEvent('R1',rtA,projet.id,prj.Account.contactParDefaut__c,null,'Pris', false);
        Event evt3 = Utils_Test.createEvent('R1',rtB,projet.id,prj.Account.contactParDefaut__c,null,'Pris', false);
        Event event = Utils_Test.createEvent('Prospection physique', rtProspection, projet.Id, prj.Account.contactParDefaut__c, null, 'Effectué', false);
        List<Event> evtList = new List<Event>();
        evtList.add(evt);
        evtList.add(evt2);
        evtList.add(evt3);
        evtList.add(event);
        insert evtList;
        
        // Exécution du test

        BA_RepriseChampsEvent ba= new BA_RepriseChampsEvent();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsKContrat() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        Test.StartTest();
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
        
        
        KContrat__c contrat = Utils_Test.createContrat(quote, true);
        contrat.dateSignature__c = Date.today().addYears(-20);
        update contrat;
        KContrat__c contrat2 = Utils_Test.createContrat(quote, false);
        contrat2.numeroContrat__c = 'TEst';
        insert contrat2;
                
        // Exécution du test

        BA_RepriseChampsKContrat ba= new BA_RepriseChampsKContrat();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsKIncontournable() {
        Test.StartTest();
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        KContrat__c contrat = Utils_Test.createContrat(quote, true);
        KIncontournable__c incontournable = new KIncontournable__c();
        incontournable.devis__c = quote.id;
        incontournable.actif__c = False;
        incontournable.dateEcheance__c = System.today() + 10;
        incontournable.dateIncontournable__c = System.today();
        incontournable.dateEnvoiCourrier__c = System.today();
        incontournable.nImprimeBdC__c = '01234';
        incontournable.nImprimeMdC__c = '98765';
        incontournable.nIncontournable__c = 'ICT/0102030405/01';
        incontournable.statut__c = 'TERMINE';
        insert incontournable;
        
        // Exécution du test

        BA_RepriseChampsKIncontournable ba = new BA_RepriseChampsKIncontournable();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsKInstance() {
        Test.StartTest();
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        KContrat__c contrat = Utils_Test.createContrat(quote, true);
        KInstance__c instance = new KInstance__c();        
        instance.contrat__c = contrat.id;
        instance.actif__c = False;
        instance.dateEcheance__c = System.today() + 10;
        instance.dateEntree__c = System.today() - 1;
        instance.dateSortie__c = System.today();
        instance.nInstance__c = 'IEC/0102030405/01';
        instance.statut__c = 'Terminé';
        insert instance;
        
        
        // Exécution du test

        BA_RepriseChampsKInstance ba= new BA_RepriseChampsKInstance();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsOpportunity() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        projet.CloseDate = Date.Today()+1;
        update projet;
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        
        // Exécution du test
        Test.StartTest();

        BA_RepriseChampsOpportunity ba= new BA_RepriseChampsOpportunity();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsQuote() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        Test.StartTest();
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
        quote.dateExpiration__c = Date.today()+1;
        quote.dateAcceptationClient__c = Date.today();
        quote.Total_TTC_devis__c = 1.0;
        update quote;
        
        // Exécution du test

        BA_RepriseChampsQuote ba= new BA_RepriseChampsQuote();
        Database.executeBatch(ba);

        Test.stopTest();
    }
    @isTest 
    static void test_BA_RepriseChampsQuoteLineItem() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Account account = DAL.getAccountById(acc.Id);
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Opportunity projet = Utils_Test.createOpportunity(account, null, chantier, true);
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        Test.StartTest();
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
        
        // Exécution du test

        BA_RepriseChampsQuoteLineItem ba= new BA_RepriseChampsQuoteLineItem();
        Database.executeBatch(ba);

        Test.stopTest();
    }
    
    @isTest 
    static void test_BA_RepriseChampsTask() {
        Id rtTaskSortant = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_APPEL_SORTANT_RT);
        String PATTERN_APPEL_SORTANT = 'Appel sortant';
        Task task = Utils_Test.createTask(rtTaskSortant,null,null,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);  
        // Exécution du test
        Test.StartTest();

        BA_RepriseChampsTask ba = new BA_RepriseChampsTask();
        Database.executeBatch(ba);

        Test.stopTest();
    }

    @isTest 
    static void test_BA_RepriseChampsProduit() {
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
        prod.ProductCode = '';
        prod.Reference__c= 'FFFETT';
        insert prod;
        
        // Exécution du test
        Test.StartTest();

        BA_RepriseChampsProduit ba = new BA_RepriseChampsProduit();
        Database.executeBatch(ba);

        Test.stopTest();
    }
    
    @isTest 
    static void test_autre() {
        // Exécution du test
        Test.StartTest();
        
        BatchHistory__c batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
        Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored); 

        Test.stopTest();
    }
    
    @isTest 
    static void test_autre2() {
        // Exécution du test
        Test.StartTest();
        
        BatchHistory__c batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, 'TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);

        Test.stopTest();
    }
}