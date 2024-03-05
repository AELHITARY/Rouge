//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TestUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/10/2022
//-- Version     : 1.0
//-- * Ajout du champ obligatoire lors de la création d'un Devis
//-- -------------------------------------------------------------------------------------- --
@IsTest
public class TestUtils {
    private static final Sectorisation__c IRIS = TestCommon.createSectorisation();

    public static QuoteLineItem qli;
    public static PricebookEntry getNewPricebookEntry(){
        PricebookEntry pr = new PricebookEntry();
        pr.UnitPrice = 123;
        pr.Product2Id = TestUtils.getNewProduct2().Id;
        pr.Pricebook2Id = [select Id from Pricebook2 where isStandard=true limit 1][0].Id;
        pr.UseStandardPrice = false;
        pr.IsActive = true;
        insert pr;
        return pr;
    }
    public static Product2 getNewProduct2(){
        Product2 pr2 = new Product2();
        pr2.Name='qew';
        pr2.Longueurminimum1vantail__c = 5;
        pr2.Longueurminimum2vantaux__c = 5;
        insert pr2;
        return pr2;
    }

    public static Option__c getNewOption(Id qliId){
        // CRM-216 - 07/09/2012 - WDO : Ajout champ obligatoire
        String code=String.valueOf(math.round(math.random()*99));
        Option__c q = new Option__c(codeOption__c=code,ligneDevis__c = qliId, PrixunitaireHT__c = 1, Libelleoption__c = 'Libellé Option');
        // CRM-216 - 07/09/2012 - WDO
        insert q;
        return  q;
    }
    public static ReferentielOptions__c getNewReferentielOptions(integer Typedeloption ){
        ReferentielOptions__c q = new ReferentielOptions__c();
        q.Typedeloption__c= Typedeloption;
        insert q;
        return  q;
    }

    public static Contact getNewContact(){
        Contact q = new Contact();
        q.LastName = 'test';
        insert q;
        return  q;
    }
}