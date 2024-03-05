//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_QuoteCPQCalculateManagers
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_IV_QuoteCPQCalculateManagers {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);
    private static final Id REF_JOB_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_JOB_RT);  
    private static final Id REF_JOBHIERARCHY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_JOBHIERARCHY_RT);    

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

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

        // Hierarchie métiers
        Referencial__c supJobHRESP = Utils_Test.createReferencial('Resp', 'HJOB-RESP', Date.today().addMonths(-12), null, REF_JOBHIERARCHY_RTID, false, false, false, false, true);
        Referencial__c supJobHVRP = Utils_Test.createReferencial('VRP', 'HJOB-VRP', Date.today().addMonths(-12), null, REF_JOBHIERARCHY_RTID, false, false, false, false, false);
        supJobHVRP.parent__c = supJobHRESP.Id;
        insert supJobHVRP;
        // Métier
        Referencial__c rvJob = Utils_Test.createReferencial('RV', 'RV', Date.today().addMonths(-12), null, REF_JOB_RTID, false, false, false, false, false);
        rvJob.jobHierarchy__c = supJobHRESP.Id;
        insert rvJob;
        Referencial__c vdJob = Utils_Test.createReferencial('Vendeur', 'Vendeur', Date.today().addMonths(-12), null, REF_JOB_RTID, false, false, false, false, false);
        vdJob.jobHierarchy__c = supJobHVRP.Id;
        insert vdJob;
    }

    @isTest 
    static void testManager() {
        Test.startTest();
        Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Referencial__c jobVD = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'Vendeur' LIMIT 1];
        Referencial__c jobRV = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'RV' LIMIT 1];

        // Création collaborateurs
        Collaborator__c vd = Utils_Test.createCollaborator(UserInfo.getUserId(), 'TEST', 'VENDEUR', 'VENDEUR_MAG001TEST', false);
        Collaborator__c rv = Utils_Test.createCollaborator(null, 'TEST', 'RV', 'RV_MAG002TEST', false);
        // Créations contrats
        CollaboratorContract__c contractVD = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = vd.Id, assignedTo__c = ent.Id,
                employedBy__c = ent.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobVD.Id);
        insert contractVD;
        CollaboratorContract__c contractRV = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = rv.Id, assignedTo__c = ent.Id,
                employedBy__c = ent.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobRV.Id);
        insert contractRV;

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);

        IV_QuoteCPQCalculateManagers.calculateManagers(new List<String>{cpqQuote.Id});

        Test.stopTest();
    }
}