//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_SigneaCircuit
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_TR02x_SigneaCircuit {    
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);

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
        // Template Signea
        Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
        temp.Name = 'Modèle standard';
        temp.Signea__Circuit_Name__c = 'Modèle standard';
        temp.Signea__Description__c = 'Le circuit standard';
        temp.Signea__Max_Duration__c = 20;
        temp.Signea__default_template__c = true;
        insert temp;

        Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.isConvertibleAsset__c=true;
        insert prod;
    }
    
    @isTest 
    static void testSales() {
        // Création enregistrement utile
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
    
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Test.startTest();

        // Création devis
        Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Event event = Utils_Test.createEvent('R1',rtRDV,opp.id, opp.Account.PersonContactId,null,'Effectué', false);
        event.resultatDuRDV__c = null;
        insert event;

        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, true);

        // Circuit Devis
        Signea__Circuit__c circuitSignatureDevis = new Signea__Circuit__c();
        circuitSignatureDevis.Name = 'DIPC (' + quote.Name + ')';
        circuitSignatureDevis.Signea__Description__c = 'Circuit de signature du ' + circuitSignatureDevis.Name;
        circuitSignatureDevis.Signea__Account__c = opp.AccountId;
        circuitSignatureDevis.Signea__Status__c = 'Draft';
        insert circuitSignatureDevis;

        // Circuit Contrat
        Signea__Circuit__c circuitSignatureCont = new Signea__Circuit__c();
        circuitSignatureCont.Name = 'Contrat (' + quote.Name + ')';
        circuitSignatureCont.Signea__Description__c = 'Circuit de signature du ' + circuitSignatureCont.Name;
        circuitSignatureCont.Signea__Account__c = opp.AccountId;
        circuitSignatureCont.lancementAutomatique__c = true;
        circuitSignatureCont.Signea__Status__c = 'Draft';
        insert circuitSignatureCont;

        // Lien Devis avec circuit
        quote.circuitSignatureContrat__c = circuitSignatureCont.Id;
        quote.circuitSignatureDevis__c = circuitSignatureDevis.Id;
        update quote;
        
        // Cloture un circuit    
        circuitSignatureDevis.Signea__Status__c = 'Completed';           
        update circuitSignatureDevis;
        circuitSignatureCont.hasBeenLaunched__c  = true;     
        circuitSignatureCont.lancementAutomatique__c = false;       
        circuitSignatureCont.Signea__Status__c = 'Completed';           
        update circuitSignatureCont;

        Test.stopTest();
    }
    
    @isTest 
    static void testCPQ() {
        // Création enregistrement utile
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];

        Test.startTest();

        // Création devis
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);

        // Circuit Devis
        Signea__Circuit__c circuitSignatureDevis = new Signea__Circuit__c();
        circuitSignatureDevis.Name = 'DIPC (' + cpqQuote.Name + ')';
        circuitSignatureDevis.Signea__Description__c = 'Circuit de signature du ' + circuitSignatureDevis.Name;
        circuitSignatureDevis.Signea__Account__c = opp.AccountId;
        circuitSignatureDevis.Signea__Status__c = 'Draft';
        insert circuitSignatureDevis;

        // Circuit Contrat
        Signea__Circuit__c circuitSignatureCont = new Signea__Circuit__c();
        circuitSignatureCont.Name = 'Contrat (' + cpqQuote.Name + ')';
        circuitSignatureCont.Signea__Description__c = 'Circuit de signature du ' + circuitSignatureCont.Name;
        circuitSignatureCont.Signea__Account__c = opp.AccountId;
        circuitSignatureCont.lancementAutomatique__c = true;
        circuitSignatureCont.Signea__Status__c = 'Draft';
        insert circuitSignatureCont;

        // Lien Devis avec circuit
        cpqQuote.circuitSignatureContrat__c = circuitSignatureCont.Id;
        cpqQuote.circuitSignatureDevis__c = circuitSignatureDevis.Id;
        update cpqQuote;
        
        // Cloture un circuit    
        circuitSignatureDevis.Signea__Status__c = 'Completed';           
        update circuitSignatureDevis;
        circuitSignatureCont.hasBeenLaunched__c  = true;    
        circuitSignatureCont.lancementAutomatique__c = false;      
        circuitSignatureCont.Signea__Status__c = 'Completed';           
        update circuitSignatureCont;

        Test.stopTest();
    }
}