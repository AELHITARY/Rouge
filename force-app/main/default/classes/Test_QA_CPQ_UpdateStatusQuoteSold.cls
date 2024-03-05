//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_CPQ_UpdateStatusQuoteSold
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/07/2023
//-- Version     : 1.0
//-- Description : Classe de tests de QA_CPQ_UpdateStatusQuoteSold
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private with sharing class Test_QA_CPQ_UpdateStatusQuoteSold {
    
    @testSetup 
    static void setup() {
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id RTDevNameReferencial = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
       
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', accPersoRT, null, 'Email', true);
        
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c=secto.Id;
        chantier.heatingMode__c='Collectif';
        insert chantier;

        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
        
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        Referencial__c ref = Utils_Test.createReferencial('ref','ref', Date.today(), Date.today(), RTDevNameReferencial, false, false, false, false, false);
        ref.KparKReference__c= PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
        insert ref;
    }

    @isTest
    private static void testGenerateQuote(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);

        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;

            Test.startTest();            
            
            // Création devis
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp, Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);
            // passage en non transmis
            cpqQuote.quoteIsValid__c = true;            
            cpqQuote.dateTransmissionClient__c = Date.today();
            update cpqQuote;

            // TEST
            Set<Id> quoteIds = new Set<Id>();
            quoteIds.add(cpqQuote.Id);
            System.enqueueJob(new QA_CPQ_UpdateStatusQuoteSold(quoteIds));

            Test.stopTest();
        }
    }
}