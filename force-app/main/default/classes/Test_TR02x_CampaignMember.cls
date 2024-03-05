/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(seeAllData=true)
private class Test_TR02x_CampaignMember {
    private static final RecordType rtB2C = [SELECT id FROM RecordType WHERE name = 'Compte personnel' LIMIT 1];
    private static final Sectorisation__c defaultSectorisation = TestCommon.createSectorisation();

    static testMethod void myUnitTest() {
        insert defaultSectorisation;

        Campaign campaign = new Campaign();
        campaign.Name = 'test123';
        campaign.Datededebutsouscampagne__c = System.today();
        campaign.Datedefinsouscampagne__c = System.today().addDays(1);
        //campaign.RecordTypeId = rt.Id;
        insert campaign;

        // Contact contact = TestUtils.getNewContact();
        Account account = createAccountB2C();
        insert account;
        Contact contact = [SELECT id, accountId FROM Contact WHERE accountId = :account.id];

        CampaignMember CM = new CampaignMember();
        CM.CampaignId = campaign.Id;
        CM.ContactId = contact.Id;
        insert CM;

        CM.Noncibleinitialement__c = true;
        update CM;

        delete CM;
    }

    private static Account createAccountB2C() {
     Account account = new Account(recordTypeId = rtB2C.id);

     account.salutation = 'M.';
     account.lastName = 'Nom';
     account.firstName = 'Prénom';
     account.accountCallSource__c = '17 - JPO';
     account.personMailingStreet = '1 rue félix faure';
     account.personMailingPostalCode = '76320';
     account.personMailingCity = 'Saint-Pierre les Elbeuf';
     account.personMailingCountry = 'F';
     account.personHomePhone = '010203ADGJ';
     account.personMobilePhone = '060203ADGJ';
     account.personOtherPhone = '010204TEST';
     account.phone = '010204MPTW';
     account.fax = '010204MPTW';
     account.personEmail = 'test@kpark.fr';

     account.x__c = 0;
     account.y__c = 0;
     account.Localisation__Latitude__s = 0;
     account.Localisation__Longitude__s = 0;
     account.iris__c = defaultSectorisation.iris__c;

     System.assertNotEquals(null, account.iris__c);

     return account;
   }
}