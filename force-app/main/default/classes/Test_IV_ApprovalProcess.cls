//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_ApprovalProcess
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/12/2021
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_ApprovalProcess {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    @testSetup 
    static void setup() {

        List<Referencial__c> refList = new List<Referencial__c>();  
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false);
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, false);
        refList.add(refMag);
        refList.add(refDep);
        insert refList;
        
        // Comptes
        List<Account> accList = new List<Account>();       
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false); 
        Account entMag = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', refMag.Id, false);
        Account entDep = Utils_Test.createEntity('DEPOT', 'DEP', Date.today(), '0123456789', refDep.Id, false);
        entDep.enabledCustomerOrderApprovalProcess__c = true;
        accList.add(entMag);
        accList.add(entDep);
        accList.add(acc);
        insert accList;
        
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('TEST', acc.Id, null, null, null, acc.Id, null, 4, false);
        chantier.serviceEntity__c = entDep.Id;
        chantier.salesEntity__c = entMag.Id;
        insert chantier;
        
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', acc, null, chantier, true);
    }

    @isTest 
    static void testApprovalEvent() {
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);

        // passage en non transmis
        cpqQuote.quoteIsValid__c = true;
        cpqQuote.dateTransmissionClient__c = Date.today();
        cpqQuote.moyenTransmissionClient__c = 'Par email';
        cpqQuote.dateAcceptationClient__c = Date.today();
        cpqQuote.SBQQ__Ordered__c = true;
        update cpqQuote;
            
        // Paramètres
        List<IV_ApprovalProcess.FlowInputParameters> inputList = new List<IV_ApprovalProcess.FlowInputParameters>();
        IV_ApprovalProcess.FlowInputParameters input = new IV_ApprovalProcess.FlowInputParameters();
        input.action = 'Removed';
        input.comment = 'NOK';
        inputList.add(input);

        // Récupération commande
        for(Order ord : [SELECT Id FROM Order LIMIT 1]) {
            input.recordId = ord.Id;
            // Création processus d'approbation
            List<Id> approverId = new List<Id>();
            approverId.add(UserInfo.getUserId());
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(ord.Id);
            req1.setProcessDefinitionNameOrId('PA_Order_Approbation3');
            req1.setSkipEntryCriteria(true);
            req1.setNextApproverIds(approverId);
            Approval.ProcessResult result = Approval.process(req1);
        }
        
        Test.startTest();
        IV_ApprovalProcess.eventApproval(inputList);
        Test.stopTest();
    }

    @isTest 
    static void testException() {
        List<IV_ApprovalProcess.FlowInputParameters> inputList = new List<IV_ApprovalProcess.FlowInputParameters>();
            
        // Testing Exception 
        IV_ApprovalProcess.FlowInputParameters invalidInput = new IV_ApprovalProcess.FlowInputParameters();
        invalidInput.recordId = null;
        inputList.add(invalidInput);
        
        Test.startTest();
        try {
            IV_ApprovalProcess.eventApproval(inputList);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }
}