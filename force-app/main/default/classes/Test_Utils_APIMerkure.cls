//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_APIMerkure 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 14/08/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_APIMerkure {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);      
    
	@testSetup static void setup() {
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        
        // Création entite        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', 
                                                 refMag.Id, true);
        
        Chantier__c chant = Utils_Test.createChantier('test',entite.Id,true);
        // Creation facture
        Utils_Test.createInvoice('Facture', a.Id, entite.Id, Date.today(), entite.Id, chant.Id, true);        
    }
    
    @isTest
    private static void testRenderDocument() {
        // Creation utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.RunAs(user) {
            Invoice__c inv = [SELECT Id, Name FROM Invoice__c LIMIT 1];        
            Blob doc = Utils_APIMerkure.renderDocumentPDF('3ccd0917f699562cd25ce7c6ae19350dfffe9f69871506f1630d59116db5fd39', inv);
            String res = Utils_APIMerkure.createContentDocument(inv.Id, 'TEST.pdf', doc, 'TEST');
        }
    }

}