//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_CollaboratorCalcManager 
//-- Modifie par : SOPRA STERIA
//-- Modifié le  : 30/12/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_CollaboratorCalcManager {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);      
    private static final Id REF_JOB_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_JOB_RT);  
    private static final Id REF_JOBHIERARCHY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_JOBHIERARCHY_RT);     
    
    @testSetup 
    static void setup() {        
        // Création entites
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entiteParent = Utils_Test.createEntity('MAGASIN', 'MAG001TEST', Date.today(), '0123456789', refMag.Id, true);
        Account entite = Utils_Test.createEntity('MAGASIN2', 'MAG002TEST', Date.today(), '0123456789', refMag.Id, false);
        entite.ParentId = entiteParent.Id;
        insert entite;  

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
    private static void testBatch() {
        Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'MAG001TEST' LIMIT 1];
        Referencial__c jobVD = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'Vendeur' LIMIT 1];
        Referencial__c jobRV = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'RV' LIMIT 1];

        // Création collaborateurs
        Collaborator__c vd = Utils_Test.createCollaborator(null, 'TEST', 'VENDEUR', 'VENDEUR_MAG001TEST', false);
        Collaborator__c rv = Utils_Test.createCollaborator(null, 'TEST', 'RV', 'RV_MAG001TEST', false);

        Test.startTest();
        
        // Créations contrats
        CollaboratorContract__c contractVD = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = vd.Id, assignedTo__c = ent.Id,
                employedBy__c = ent.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobVD.Id);
        insert contractVD;
        CollaboratorContract__c contractRV = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = rv.Id, assignedTo__c = ent.Id,
                employedBy__c = ent.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobRV.Id);
        insert contractRV;

        // Exécution du Batch 
        BA_CollaboratorCalculateManager ba = new BA_CollaboratorCalculateManager();
        Database.executebatch(ba);

        Test.stopTest();
    }
    
    @isTest
    private static void testSchedule() {
        Account ent = [SELECT Id FROM Account WHERE KparKReference__c = 'MAG001TEST' LIMIT 1];
        Account ent2 = [SELECT Id FROM Account WHERE KparKReference__c = 'MAG002TEST' LIMIT 1];
        Referencial__c jobVD = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'Vendeur' LIMIT 1];
        Referencial__c jobRV = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'RV' LIMIT 1];

        // Création collaborateurs
        Collaborator__c vd = Utils_Test.createCollaborator(null, 'TEST', 'VENDEUR', 'VENDEUR_MAG001TEST', false);
        Collaborator__c rv = Utils_Test.createCollaborator(null, 'TEST', 'RV', 'RV_MAG002TEST', false);

        Test.startTest();

        // Créations contrats
        CollaboratorContract__c contractVD = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = vd.Id, assignedTo__c = ent2.Id,
                employedBy__c = ent2.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobVD.Id);
        insert contractVD;
        CollaboratorContract__c contractRV = new CollaboratorContract__c(signatureDate__c = Date.today(),
                startDate__c = Date.today(), collaborator__c = rv.Id, assignedTo__c = ent.Id,
                employedBy__c = ent.Id, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = jobRV.Id);
        insert contractRV;

        String jobId = System.schedule('Schedule_CollaboratorCalculateManager', '0 0 * * * ?', new Schedule_CollaboratorCalculateManager() );
        Schedule_CollaboratorCalculateManager schedule = new Schedule_CollaboratorCalculateManager();
        schedule.execute(null);

        Test.stopTest();
    }
}