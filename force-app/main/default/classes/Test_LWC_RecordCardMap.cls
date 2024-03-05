//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_RecordCardMap
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/09/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_RecordCardMap
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_RecordCardMap {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

    @testSetup 
    static void setup() {        
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        
        
        // Creation FSL
        User [] u = TestData_fsl_Setup.createUser();
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh);  
    }

    @isTest
    private static void testAccount() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création entite        
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Account entiteParent = Utils_Test.createEntity('MAGPARENT', 'MAGPARENT', Date.today(), '0123456789', 
                                                           refMag.Id, true);
            Account entite = Utils_Test.createEntity('MAGENFANT', 'MAGENFANT', Date.today(), '0123456789', 
                                                     refMag.Id, false);
            entite.ParentId = entiteParent.Id;
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            acc.Localisation__Latitude__s = 2;
            acc.Localisation__Longitude__s = 45;
            acc.personSalesEntity__pc = entiteParent.Id;
            acc.personServiceEntity__pc = entiteParent.Id;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            accList.add(entite);
            Test.startTest();
            insert accList;
            
            // Creation chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);

            
            LWC_RecordCardMap.getRecordLocAndInfos('Account', acc.Id, 'AccountNumber');
            LWC_RecordCardMap.getEntitiesLocAndInfos('Account', acc.Id, 'personSalesEntity__pc', 'personServiceEntity__pc', 'AccountNumber');
            LWC_RecordCardMap.getEntitiesLocAndInfos('Account', acc.Id, 'personSalesEntity__pc', '', 'AccountNumber');
            LWC_RecordCardMap.getEntitiesLocAndInfos('Account', acc.Id, '', 'personServiceEntity__pc', 'AccountNumber');

            Test.stopTest();
        }
    }

    @isTest
    private static void testParentEntity() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création entite        
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Account entiteParent = Utils_Test.createEntity('MAGPARENT', 'MAGPARENT', Date.today(), '0123456789', 
                                                           refMag.Id, true);
            Account entite = Utils_Test.createEntity('MAGENFANT', 'MAGENFANT', Date.today(), '0123456789', 
                                                     refMag.Id, false);
            entite.ParentId = entiteParent.Id;
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            acc.Localisation__Latitude__s = 2;
            acc.Localisation__Longitude__s = 45;
            acc.personSalesEntity__pc = entiteParent.Id;
            acc.personServiceEntity__pc = entiteParent.Id;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            accList.add(entite);
            Test.startTest();
            insert accList;
            
            // Creation chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);

            
            LWC_RecordCardMap.getRecordLocAndInfos('Account', entite.Id, 'AccountNumber');
            LWC_RecordCardMap.Localisation loc = LWC_RecordCardMap.getParentRecordLocAndInfos('Account', entite.Id, 'AccountNumber');
            loc.getLatitude();
            loc.getLongitude();
            loc.getRecord();

            Test.stopTest();
        }
    }

    @isTest
    private static void testRelated() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création entite        
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Account entiteParent = Utils_Test.createEntity('MAGPARENT', 'MAGPARENT', Date.today(), '0123456789', 
                                                           refMag.Id, true);
            Account entite = Utils_Test.createEntity('MAGENFANT', 'MAGENFANT', Date.today(), '0123456789', 
                                                     refMag.Id, false);
            entite.ParentId = entiteParent.Id;
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            acc.Localisation__Latitude__s = 2;
            acc.Localisation__Longitude__s = 45;
            acc.personSalesEntity__pc = entiteParent.Id;
            acc.personServiceEntity__pc = entiteParent.Id;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            accList.add(entite);
            Test.startTest();
            insert accList;
            
            // Creation chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);

            
            LWC_RecordCardMap.getRecordLocAndInfos('Chantier__c', chantier.Id, 'owner__c');
            LWC_RecordCardMap.getRelatedRecordLocAndInfos('Chantier__c', chantier.Id, 'Account', 'owner__c', 'AccountNumber');

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testRecordGeolocalisation() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création entite        
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Account entiteParent = Utils_Test.createEntity('MAGPARENT', 'MAGPARENT', Date.today(), '0123456789', 
                                                           refMag.Id, true);
            Account entite = Utils_Test.createEntity('MAGENFANT', 'MAGENFANT', Date.today(), '0123456789', 
                                                     refMag.Id, false);
            entite.ParentId = entiteParent.Id;
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            acc.Localisation__Latitude__s = 2;
            acc.Localisation__Longitude__s = 45;
            acc.personSalesEntity__pc = entiteParent.Id;
            acc.personServiceEntity__pc = entiteParent.Id;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            accList.add(entite);
            Test.startTest();
            insert accList;
            
            // Creation chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);

            
            LWC_RecordCardMap.forceRecordGeolocalisation('Account', acc.Id);
            LWC_RecordCardMap.forceRecordGeolocalisation('Chantier__c', chantier.Id);

            Test.stopTest();
        }
    }

    @isTest
    private static void testFSL() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
            ServiceTerritoryMember stm = [SELECT Id FROM ServiceTerritoryMember LIMIT 1];

            
            LWC_RecordCardMap.getServiceTerritoryRecordLocAndInfos('ServiceTerritoryMember', stm.Id, 'Name');
            LWC_RecordCardMap.getRecordLocAndInfos('ServiceTerritoryMember', stm.Id, 'CreatedDate');
            LWC_RecordCardMap.getFSLMapPolygonInfos('ServiceTerritory', st.Id);
            LWC_RecordCardMap.getFSLMapPolygonInfos('ServiceTerritoryMember', stm.Id);

            LWC_RecordCardMap.SectorFSL sec = new LWC_RecordCardMap.SectorFSL('TEST','#fff','48',st);
            sec.getName();
            sec.getColor();
            sec.getLatLongCoordinates();
            sec.getRecord();

            Test.stopTest();
        }
    }
}