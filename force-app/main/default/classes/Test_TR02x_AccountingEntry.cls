//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_AccountingEntry
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 09/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_AccountingEntry {
    private static final String RT_AE_BANKREMITTANCE = DAL.getRecordTypeIdByDevName('AccountingEntry__c',Constants.ACCOUNTINGENTRY_BANKREMITTANCE_RT);
    private static final String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String RT_REF_BANKACCOUNT = DAL.getRecordTypeIdByDevName('Referencial__c', 'BankAccount');  

    @testSetup 
    static void setup() {
        String refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

        // Création entite     
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, true);
        // Création banque
        Utils_Test.createBankAccount('Bank', 'BANK', Date.today(), null, true);
    }   

    @isTest
    private static void testDelete() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            List<Account> accEntity = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            List<Referencial__c> refBankAcc = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :RT_REF_BANKACCOUNT LIMIT 1];

            // Create new AccountingEntry
            AccountingEntry__c accEnt = new AccountingEntry__c(
                entryDate__c = Date.today(),
                entityBankAccount__c = refBankAcc[0].Id,
                amount__c = 100,
                RecordTypeId = RT_AE_BANKREMITTANCE,
                label__c = 'Encaissements',
                inputEntity__c = accEntity[0].Id
            );
            insert accEnt;

            // Test
            Test.startTest();

            try {
                delete accEnt;
            } catch(Exception ex) {

            }

            Test.stopTest();
        }
    }
}