//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_EditionContrat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/10/2021
//-- Version     : 1.2
//-- *
//-- -------------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_EditionContrat {
    private static final Sectorisation__c IRIS = TestCommon.createSectorisation();

    @testSetup 
    static void setup() {
        // Création famille et sous famille
        Familles__c famille = new Familles__c(Name = 'Fenetre', libelle__c = 'Fenetre', code__c = 'FEN');
        insert famille;
        Familles__c famille2 = new Familles__c(Name = 'PORTAILS', libelle__c = 'PORTAILS', code__c = 'P');
        insert famille2;
        SousFamilles__c ssfamille = new SousFamilles__c(Name = 'PVC', libelle__c = 'PVC', famille__c = 'FEN',code__c = 'PVC');
        insert ssfamille;
        SousFamilles__c ssfamille2 = new SousFamilles__c(Name = 'PORTAILS COULISSANTS', libelle__c = 'PORTAILS COULISSANTS', famille__c = 'P',code__c = 'PCOUL');
        insert ssfamille2;
    }

    @isTest
    static void test_EditionContrat_fenetre() {
        User pu = Utils_Test.createAdminUser();

        System.runAs(pu){
            TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            // Récupération des Record Type
            Id accRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrement utile
            Account acc = Utils_Test.createAccount('AccountUn', 'test', 'test@test.fr', accRTId, 'Email',true);
            Account acc2 = Utils_Test.createAccount('AccountDeux', 'test', 'test2@test.fr', accRTId, 'Email',true);

            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Chantier__c chantier2 = Utils_Test.createChantier('Chantier 2', acc2.Id,true);

            Opportunity opp = Utils_Test.createOpportunity(acc, null, chantier, true);
            Opportunity opp2 = Utils_Test.createOpportunity(acc, null, chantier2, true);

            // Creation produit
            Id pb = Test.getStandardPricebookId();
            Product2 prod = new Product2(Name = 'Produit Test', ProductCode = 'FFFETT', IsActive = true,
                                        Longueurminimum1vantail__c = 50, Family = 'Fenetre', SousFamille__c = 'PVC');
            insert prod;

            /*PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            insert pbe;*/


            // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    C2E__c='Oui',
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    mntAcompteAttendu__c = 560,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            Quote quote2 = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 2',
                                    datedevis__c = Date.today(),
                                    OpportunityId = opp2.Id,
                                    C2E__c='Oui',
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    mntAcompteAttendu__c = 560,
                                    source__c = 'BAL VENDEUR');
            insert quote2;

            //PBE
            PricebookEntry pbe; 
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :prod.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == prod.Id) pbe = pbeSelected;
            }

            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=1,Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=10);
            insert qli;
            Option__c opt = TestUtils.getNewOption(qli.Id);

            QuoteLineItem qli2 = new QuoteLineItem(QuoteId = quote2.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=1,Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=10);
            insert qli2;
            Option__c opt2 = TestUtils.getNewOption(qli2.Id);

            Test.startTest();
            
            // Création de la page et ajout des parametres
            PageReference newPRpage = Page.VF_EditionContrat;
            newPRpage.getParameters().put('qId', quote.Id);
            Test.setCurrentPageReference (newPRpage);

            // Création controleur
            Ctrl_EditionContrat ctrl = new Ctrl_EditionContrat();

            // Verification nombre de QuoteItem
            System.assertEquals(ctrl.prodListPorteF.size(), 1);
            System.assertEquals(ctrl.prodListPorteGaragePortail.size(), 0);
            System.assertEquals(ctrl.prodListAutre.size(), 0);


            // Création de la page et ajout des parametres
            PageReference newPRpage2 = Page.VF_EditionContrat;
            newPRpage2.getParameters().put('qId', quote2.Id);
            Test.setCurrentPageReference (newPRpage2);

            // Création controleur
            Ctrl_EditionContrat ctrl2 = new Ctrl_EditionContrat();

            // Verification nombre de QuoteItem
            System.assertEquals(ctrl2.prodListPorteF.size(), 1);
            System.assertEquals(ctrl2.prodListPorteGaragePortail.size(), 0);
            System.assertEquals(ctrl2.prodListAutre.size(), 0);

            Test.stopTest();
        }
    }

    @isTest
    static void test_EditionContrat_autre() {
        User pu = Utils_Test.createAdminUser();

        System.runAs(pu){
            TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            // Récupération des Record Type
            Id accRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrement utile
            Account acc = Utils_Test.createAccount('AccountUn', 'test', 'test@test.fr', accRTId, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, null, chantier, true);

            // Creation produit
            Id pb = Test.getStandardPricebookId();
            Product2 prod = new Product2(Name = 'Produit Test', ProductCode = 'FFFETT', IsActive = true,
                                            Family = 'Fenetre', SousFamille__c = 'PVC');
            insert prod;
            /*PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            insert pbe;*/

            // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    C2E__c='Oui',
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            //PBE
            PricebookEntry pbe;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :prod.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == prod.Id) pbe = pbeSelected;
            }

            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=1,Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=10);
            insert qli;
            Option__c opt = TestUtils.getNewOption(qli.Id);

            Test.startTest();

            // Création de la page et ajout des parametres
            PageReference newPRpage = Page.VF_EditionContrat;
            newPRpage.getParameters().put('qId', quote.Id);
            Test.setCurrentPage (newPRpage);

            // Création controleur
            Ctrl_EditionContrat ctrl = new Ctrl_EditionContrat();

            // Verification nombre de QuoteItem
            System.assertEquals(ctrl.prodListPorteF.size(), 0);
            System.assertEquals(ctrl.prodListPorteGaragePortail.size(), 0);
            System.assertEquals(ctrl.prodListAutre.size(), 1);

            Test.stopTest();
        }
    }

    @isTest
    static void test_EditionContrat_garage() {
        User pu = Utils_Test.createAdminUser();

        System.runAs(pu){
            TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            // Récupération des Record Type
            Id accRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrement utile
            Account acc = Utils_Test.createAccount('AccountUn', 'test', 'test@test.fr', accRTId, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, null, chantier, true);

            // Creation produit
            Id pb = Test.getStandardPricebookId();
            Product2 prod = new Product2(Name = 'Produit Test', ProductCode = 'P', IsActive = true,
                                            Family = 'PORTAILS', SousFamille__c = 'PCOUL');
            insert prod;
            /*PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            insert pbe;*/

            // Creation devis
            Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                    Name = 'Devis 1',
                                    datedevis__c = Date.today(),
                                    OpportunityId = opp.Id,
                                    C2E__c='Oui',
                                    modeFinancement__c = 'PAIEMENT COMPTANT',
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');
            insert quote;

            //PBE
            PricebookEntry pbe;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :prod.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == prod.Id) pbe = pbeSelected;
            }

            QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,
                                                    Largeur__c=30,Quantity=1,Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVApourcentage__c=10);
            insert qli;
            Option__c opt = TestUtils.getNewOption(qli.Id);

            Test.startTest();

            // Création de la page et ajout des parametres
            PageReference newPRpage = Page.VF_EditionContrat;
            newPRpage.getParameters().put('qId', quote.Id);
            Test.setCurrentPage (newPRpage);

            // Création controleur
            Ctrl_EditionContrat ctrl = new Ctrl_EditionContrat();

            // Verification nombre de QuoteItem
            ctrl.calculGaragePortail(qli, true);

            Test.stopTest();
        }
    }
}