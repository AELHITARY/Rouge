//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_FinancialCharge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_TR02x_FinancialCharge {    
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);

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
    }

    @isTest 
    static void testDelete() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account entity = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID LIMIT 1];
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,true);
            Collaborator__c collab = Utils_Test.createCollaborator(user.Id, 'TEST', 'TEST', 'EDEDEEE', false);

            FinancialCharge__c charge = new FinancialCharge__c();
            charge.date__c = Date.today();
            charge.entity__c = entity.Id;
            charge.order__c = customerOrder.Id;
            charge.collaborator__c = collab.Id;
            charge.amount__c = 100;
            charge.reason__c = 'Prestation';
            charge.type__c = 'Régularisation';
            insert charge;

            // Test delete
            delete charge;

            Test.stopTest();
        }
    }
}