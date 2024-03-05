//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_ContentVersion
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/09/2020
//-- Version     : 1.0
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_ContentVersion {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);   
    private static final Id RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);

    @testSetup 
    static void testSetup() {   
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
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
    static void testCPQQuoteLine() {

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.KBMAXSB__Id__c = 1;
        insert prod;
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Devis 
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        // Ligne devis 
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
        // Simulation fichier de KBMAX
        Utils_Test.createFile(cpqQuoteLine.Id+'-TEST.jpg', cpqQuoteLine.Id, EncodingUtil.base64Decode('TEST'), true);

        Test.stopTest();
    }

    @isTest 
    static void testCase() {
        
        Test.startTest();    

        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];  

        // Case
        Case caseTest = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        insert caseTest;

        // Fichier
        Utils_Test.createFile('File.jpg', caseTest.Id, EncodingUtil.base64Decode('TEST'), true);

        ContentVersion ctVer = [SELECT Id, Title FROM ContentVersion LIMIT 1];
        TR022_ContentDocumentLink.createContentDistribution(ctVer);

        Test.stopTest();
    }

    @isTest 
    static void testPhototheque() {

        Test.startTest();

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.KBMAXSB__Id__c = 1;
        insert prod;
        
        // Simulation        
        ContentVersion cVersion = new ContentVersion(ContentLocation = 'S',
                                                    Title = 'File.jpg',
                                                    VersionData = EncodingUtil.base64Decode('TEST'),
                                                    PathOnClient = 'File.jpg',
                                                    produit__c = prod.Id);
        insert cVersion;

        Test.stopTest();
    }
}