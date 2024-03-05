//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR020_FeedItem 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/10/2021
//-- Version     : 1.1
//-- * 
//-- --------------------------------------------------------------------------------- --
@IsTest
public class Test_TR020_FeedItem {
    
    @isTest 
    public static void testFeedItem(){
      
    // Creation d'un user  
    User pu = Utils_Test.createAdminUser(); 
    
    // Run as User 'pu'
    System.runAs(pu) {        
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);        
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
                
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        
        // Création de comptes
        Account compte = Utils_Test.createAccount('Dupont', 'Jean', 'test@test.fr', accPersoRT, 'Piste', 'Email',true);
        // Creation d'un chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', compte.Id,true);
        // Creation d'un projet
        Opportunity projet= Utils_Test.createOpportunity(compte, chantier, true);

        // Creation d'un FeedItem sur le chantier 'chantier'
        FeedItem fitl = new FeedItem();
        fitl.Body = 'Test Body';
        fitl.ParentId = chantier.Id;
        fitl.ContentData = Blob.valueOf('test');
        fitl.ContentFileName = 'test.txt';

        insert fitl;
        
        // Creation d'un FeedItem sur le compte 'compte'
        FeedItem fitl2 = new FeedItem();
        fitl2.body = 'Test Body';
        fitl2.ParentId = compte.Id;
        fitl2.Title = 'test';
        fitl2.ContentData = Blob.valueOf('test');
        fitl2.ContentFileName = 'test.txt';

        insert fitl2;
        
        // Creation d'un FeedItem sur le compte 'compte'
        /**
        FeedItem fitl3 = new FeedItem();
        fitl3.body = 'Test Body';
        fitl3.ParentId = projet.Id;
        fitl3.ContentFileName = 'test';
        
        // Encoding du body en base64
        String decodedbody3 = 'original String before base64 encoding';
        Blob encodedbody3 = Blob.valueOf(decodedbody3);        
        fitl3.ContentData = encodedbody3;

        insert fitl3;
        **/
        }
    }    
}