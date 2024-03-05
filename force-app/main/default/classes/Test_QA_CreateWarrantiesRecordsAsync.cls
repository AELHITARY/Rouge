//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_CreateWarrantiesRecordsAsync
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_QA_CreateWarrantiesRecordsAsync {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 

    @testSetup 
    static void testSetup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refCgv = Utils_Test.createReferencial('CGV', 'CGV1', Date.today(), null, REF_TERMSANDCONT_RTID, false, false, false, false, false);
        refList.add(refDep);
        refList.add(refMag);
        refList.add(refCgv);
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

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;
                
        // Options référence
        ReferentielOptions__c refOpt = new ReferentielOptions__c(Name='RefOption', CodeOption__c='FFFETT');
        insert refOpt;

        // Categorie garantie
        CategorieGaranties__c cat1 = new CategorieGaranties__c(code__c='100',libelle__c='Cat 1',dateDebutValidite__c = Date.today().addDays(-1));
        insert cat1;
        // Garantie
        List<Garantie__c> garantieList = new List<Garantie__c>();
        Garantie__c gara = new Garantie__c(categorie__c=cat1.Id,code__c='101',libelle__c='Garantie 1',dateDebutValidite__c = Date.today().addDays(-1));
        garantieList.add(gara);
        Garantie__c gara2 = new Garantie__c(categorie__c=cat1.Id,code__c='102',libelle__c='Garantie 2',dateDebutValidite__c = Date.today().addDays(-1));
        garantieList.add(gara2);
        Garantie__c gara3 = new Garantie__c(categorie__c=cat1.Id,code__c='103',libelle__c='Garantie 3',dateDebutValidite__c = Date.today().addDays(-1));
        garantieList.add(gara3);
        insert garantieList;
        // Duree
        List<DureeGarantiesProduit__c> dureeList = new List<DureeGarantiesProduit__c>();
        DureeGarantiesProduit__c dureeProd = new DureeGarantiesProduit__c(codeGarantie__c=gara.Id,codeProduit__c=prod.Id,duree__c=5,
                                                                            code__c='111',dateDebutValidite__c = Date.today().addDays(-1));
        dureeList.add(dureeProd);
        DureeGarantiesProduit__c dureeProd2 = new DureeGarantiesProduit__c(codeGarantie__c=gara2.Id,codeProduit__c=prod.Id,duree__c=10,
                                                                            code__c='112',dateDebutValidite__c = Date.today().addDays(-1));
        dureeList.add(dureeProd2);
        DureeGarantiesProduit__c dureeProd3 = new DureeGarantiesProduit__c(codeGarantie__c=gara3.Id,codeProduit__c=prod.Id,duree__c=15,
                                                                            code__c='113',dateDebutValidite__c = Date.today().addDays(-1));
        dureeList.add(dureeProd3);
        insert dureeList;
        DureeGarantiesOptions__c dureeOpt = new DureeGarantiesOptions__c(codeGarantie__c=gara.Id,codeOption__c=refOpt.Id,duree__c=5,
                                                                            code__c='114',dateDebutValidite__c = Date.today().addDays(-1));        
        insert dureeOpt;
    }

    @isTest 
    static void testProduit() {
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE reference__c = 'FFFETT' LIMIT 1];

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

        System.enqueueJob(new QA_CreateWarrantiesRecordsAsync(new Set<Id>{cpqQuoteLine.Id}));

        Test.stopTest();
    }    

    @isTest 
    static void testOptions() {
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE reference__c = 'FFFETT' LIMIT 1];

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
        SBQQ__QuoteLine__c cpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
        cpqQuoteLine2.SBQQ__RequiredBy__c = cpqQuoteLine.Id;
        insert cpqQuoteLine2;

        System.enqueueJob(new QA_CreateWarrantiesRecordsAsync(new Set<Id>{cpqQuoteLine.Id}));

        Test.stopTest();
    }
}