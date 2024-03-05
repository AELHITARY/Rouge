//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR020_Garanties
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/06/2017
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR020_Garanties {    
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);
        Opportunity opp = Utils_Test.createOpportunity('name', acc, null, chantier, true);
        
        // Creation produits
        Id pb = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name = 'Produit Test', ProductCode = 'FFFETT', IsActive = true, Largeurminimum1vantail__c = 50,
                                        Longueurminimum1vantail__c = 50, Family = 'Fenetre', SousFamille__c = 'PVC');
        insert prod;
        Product2 prod2 = new Product2(Name = 'Produit Test 2', ProductCode = 'FFFET2', IsActive = true, Largeurminimum1vantail__c = 50,
                                        Longueurminimum1vantail__c = 50, Family = 'Fenetre', SousFamille__c = 'PVC');
        insert prod2;
        
        // Options référence
        ReferentielOptions__c refOpt = new ReferentielOptions__c(Name='RefOption');
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
        DureeGarantiesProduit__c dureeProd2 = new DureeGarantiesProduit__c(codeGarantie__c=gara2.Id,codeProduit__c=prod2.Id,duree__c=10,
                                                                            code__c='112',dateDebutValidite__c = Date.today().addDays(-1));
        dureeList.add(dureeProd2);
        DureeGarantiesProduit__c dureeProd3 = new DureeGarantiesProduit__c(codeGarantie__c=gara3.Id,codeProduit__c=prod2.Id,duree__c=15,
                                                                            code__c='113',dateDebutValidite__c = Date.today().addDays(-1));
        dureeList.add(dureeProd3);
        insert dureeList;
        DureeGarantiesOptions__c dureeOpt = new DureeGarantiesOptions__c(codeGarantie__c=gara.Id,codeOption__c=refOpt.Id,duree__c=5,
                                                                            code__c='114',dateDebutValidite__c = Date.today().addDays(-1));        
        insert dureeOpt;

        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test' LIMIT 1];           

        Quote quoteTest = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis test',
                                    datedevis__c = Date.today(),
                                    referenceDate__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    mntAcompteAttendu__c = 100,
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
        insert quoteTest;

        QuoteLineItem qliTest = new QuoteLineItem(QuoteId = quoteTest.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=2,
                                                    Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c = 0.2);
        insert qliTest;         
    }

    @isTest 
    static void test_garantieProduit() {
        User userTest = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null);

        System.runAs(userTest) {
            // Récupération données
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test' LIMIT 1];
            Id pb = Test.getStandardPricebookId();
             // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    referenceDate__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    mntAcompteAttendu__c = 100,
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            Test.startTest();

            // Ligne de devis
            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=2,
                                                    Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=0.2);
            insert qli;
            
            Test.stopTest();

            // Test         
            qli = [SELECT Id, dureeGarantie1__c, dureeGarantie2__c FROM QuoteLineItem LIMIT 1];
            //System.assertEquals(5, qli.dureeGarantie1__c);
            System.assertEquals(null, qli.dureeGarantie2__c);
        }
    }

    @isTest 
    static void test_garantieOption() {
        User userTest = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null);

        System.runAs(userTest) {
            // Récupération données
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test' LIMIT 1];
            ReferentielOptions__c refOpt = [SELECT Id FROM ReferentielOptions__c LIMIT 1];
            Id pb = Test.getStandardPricebookId();
             // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    referenceDate__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    mntAcompteAttendu__c = 100,
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            Test.startTest();

            // Ligne de devis
            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=2,
                                                    Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=0.2);
            insert qli;         
            // Options des produits
            Option__c option1 = new Option__c(Option__c=refOpt.Id, ligneDevis__c = qli.Id, PrixunitaireHT__c = 1, 
                                                Libelleoption__c = 'Libellé Option 1', codeOption__c='1');
            insert option1;
            
            Test.stopTest();

            // Test         
            qli = [SELECT Id, dureeGarantie1__c, dureeGarantie2__c FROM QuoteLineItem LIMIT 1];
            //System.assertNotEquals(null, qli.dureeGarantie1__c);
            System.assertEquals(null, qli.dureeGarantie2__c);
        }
    }

    @isTest 
    static void test_garantieTwoGaranties() {
        User userTest = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null);

        System.runAs(userTest) {
            // Récupération données
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test 2' LIMIT 1];
            Id pb = Test.getStandardPricebookId();
             // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    referenceDate__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    mntAcompteAttendu__c = 100,
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            Test.startTest();

            // Ligne de devis
            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=2,
                                                    Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=0.2);
            insert qli;     
            qli.UnitPrice = 57.0;
            update qli;
            
            Test.stopTest();

            // Test         
            qli = [SELECT Id, dureeGarantie1__c, dureeGarantie2__c FROM QuoteLineItem LIMIT 1];
            //System.assertNotEquals(null, qli.dureeGarantie1__c);
            //System.assertNotEquals(null, qli.dureeGarantie2__c);
        }
    }

    @isTest 
    static void test_refreshGaranties(){
        Test.startTest();
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        update qli;
        Test.stopTest();
    }
}