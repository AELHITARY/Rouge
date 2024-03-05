//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_SendCPQQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/10/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_SendCPQQuote {
    
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        
        // Récupération record type
        String accPersonRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        
        // Création enregistrement utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersonRTId, 'Email',true);
        Account acc2 = Utils_Test.createAccount('Account 2', 'test deux', 'test2@test.fr', accPersonRTId, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
        
        // Creation devis
        SBQQ__Quote__c devis = Utils_Test.createCPQQuote('Devis 1', null, opp,null, Date.today(), 1000, 100, false);
        devis.autreCompte__c = acc2.Id;
        insert devis;
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(devis.Id ,100, 100, 1,true);

        ContentDocumentLink cdl = Utils_Test.createFile('test', cpqQuoteLine.Id, Blob.valueOf('content'), true);
        Id contentVer = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].Id;
        
        ContentDistribution cdistrib = Utils_Test.createContentDistribution('test', contentVer, true);
    }
    
    @isTest
    private static void sendOk() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false, 'Sales1', 'sales1@test.remvrp.com', 'sal', 'es', null, null);
        
        System.runAs(user){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            // Récupération enregistrement du devis 
            SBQQ__Quote__c devis = [SELECT Id, statusFixed__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
            devis.statusFixed__c = Constants.StatutDevisNonTransmis;
            devis.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update devis;
            
            Test.startTest();
            
            // Envoi car statut OK
            try{
            	LWC_SendCPQQuote.sendPDF(devis.Id);
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
    
    @isTest
    private static void sendNOK() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            String idUser = user.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            // Récupération enregistrement du devis 
            SBQQ__Quote__c devis = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            
            Test.startTest();
            
            // Pas d'envoi car a configuré
            try{
            	LWC_SendCPQQuote.sendPDF(devis.Id);
            }
			catch(Exception e){}
            Test.stopTest();
        }
    }
}