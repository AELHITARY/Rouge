//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_EntityVersion 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 05/12/2019
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_EntityVersion {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    
    @testSetup 
    static void setup() {     
        PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', true);   
        // Création entite        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        Account entiteParent = Utils_Test.createEntity('MAGPARENT', 'MAGPARENT', Date.today(), '0123456789', 
                                                 refMag.Id, true);
        
        OperatingHours opHours = new OperatingHours(Name = 'Par Défaut'/*, fsl_dateOuverture__c = date.today()*/);
        insert opHours;
    }
    
    @isTest 
    static void test_EntityVersionCreateObjects() {
        User userTest = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        
        System.runAs(userTest){
            Account entity = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGPARENT' LIMIT 1];
            
            Test.startTest();
            
            EntityVersion__c entityVersion = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today(), SIRET__c = 123);
            insert entityVersion;
            entityVersion.startDate__c = date.today().addDays(-1);
            update entityVersion;
            EntityVersion__c entityVersion2 = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(2), SIRET__c = 123);
            insert entityVersion2;
            EntityVersion__c entityVersion3 = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(4), SIRET__c = 123);
            insert entityVersion3 ;
            
            Test.stopTest();
        }
    }
    
    @isTest 
    static void test_EntityVersionCheckDateKO() {
        User userTest = TestCommon.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        
        System.runAs(userTest){
            Account entity = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGPARENT' LIMIT 1];
            
            Test.startTest();
            
            try {
                EntityVersion__c entityVersion = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today(), postalCode__c= '12345', city__c='TEST');
                insert entityVersion;
                entityVersion.startDate__c = date.today().addDays(-1);
                entityVersion.endDate__c = date.today();
                update entityVersion;
            
                EntityVersion__c entityVersion2 = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(1), postalCode__c= '12345', city__c='TEST', SIRET__c = 123);
                insert entityVersion2;
            } catch(Exception e) {}
            
            Test.stopTest();
        }
    }
    
    @isTest 
    static void test_EntityVersionCheckDateOK() {
        User userTest = TestCommon.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        
        System.runAs(userTest){
            Account entity = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGPARENT' LIMIT 1];
            
            Test.startTest();
            
            EntityVersion__c entityVersion = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(1), postalCode__c= '12345', city__c='TEST', SIRET__c = 123);
            insert entityVersion;
            
            EntityVersion__c entityVersion2 = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(2), postalCode__c= '12345', city__c='TEST', SIRET__c = 123);
            insert entityVersion2;
            
            Test.stopTest();
        }
    }
    
    @isTest 
    static void test_EntityVersionChangeAddress() {
        User userTest = TestCommon.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        
        System.runAs(userTest){
            Account entity = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGPARENT' LIMIT 1];
            
            Test.startTest();
            
            EntityVersion__c entityVersion = new EntityVersion__c(Name = 'TestEntV', entity__c = entity.Id, startDate__c = date.today().addDays(1), postalCode__c= '12345', city__c='TEST', SIRET__c = 123);
            insert entityVersion;
            entityVersion.city__c = 'TEST2';
            update entityVersion;            
            
            Test.stopTest();
        }
    }
}