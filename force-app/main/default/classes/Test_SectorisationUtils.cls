@isTest
private class Test_SectorisationUtils {

   static testMethod void test() {
     List<Sectorisation__c> insertedSectorisations = new List<Sectorisation__c>();
     for (Integer i = 0; i < 100; i++)
       insertedSectorisations.add(new Sectorisation__c(iris__c               = 'Iris' + i,
                                                       codeMagasin__c        = 'MAG' + i,
                                                       libelleMagasin__c     = 'Magasin ' + i,
                                                       codeDV__c             = 'DV' + i,
                                                       libelleDV__c          = 'Direction des ventes ' + i,
                                                       codeRegion__c         = 'DR' + i,
                                                       libelleRegion__c      = 'Région ' + i,
                                                       codeDepot__c          = 'DEP' + i,
                                                       libelleDepot__c       = 'Dépôt ' + i,
                                                       codeDS__c             = 'DS' + i,
                                                       libelleDS__c          = 'Direction service ' + i));
     insert insertedSectorisations;

     Test.startTest();

     Integer count0 = [SELECT count() FROM Sectorisation__c];
     SectorisationUtils.OrganisationKpark org0 = SectorisationUtils.getOrganisation();
     System.debug('count0 : ' + count0);
     System.debug('org0.magasins.size() : ' + org0.magasins.size());
     System.assertEquals(count0, org0.magasins.size());

     Test.stopTest();
   }
}