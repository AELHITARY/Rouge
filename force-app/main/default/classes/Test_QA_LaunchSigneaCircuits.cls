//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_LaunchSigneaCircuits
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_QA_LaunchSigneaCircuits {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id EVT_RDV_RT = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @testSetup 
    static void testSetup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        refList.add(refMag);
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
        // Template Signea
        Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
        temp.Name = 'Modèle standard';
        temp.Signea__Circuit_Name__c = 'Modèle standard';
        temp.Signea__Description__c = 'Le circuit standard';
        temp.Signea__Max_Duration__c = 20;
        temp.Signea__default_template__c = true;
        insert temp;
    }
    
    @isTest 
    static void testQuoteCEE() {
        // Création enregistrement utile
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Event event = Utils_Test.createEvent('R1', EVT_RDV_RT, opp.id, opp.Account.PersonContactId, null, 'Effectué', false);
        event.resultatDuRDV__c = null;
        insert event;

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;
        PricebookEntry ceeProduct = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test' LIMIT 1];

        Test.startTest();

        // Création devis
        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, false);
        insert quote;

        // Ligne de devis
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, ceeProduct.Id, false);
        qli.TVApourcentage__c = 5;
        insert qli;

        // Circuit Devis
        Signea.Signea_Entities_v2.SigneaCircuit circuitSignatureDevis = new Signea.Signea_Entities_v2.SigneaCircuit();
        circuitSignatureDevis.name = 'DIPC (' + quote.numeroDevis__c + ')';
        circuitSignatureDevis.description = 'Circuit de signature du ' + circuitSignatureDevis.name;
        circuitSignatureDevis.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
        circuitSignatureDevis.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
        circuitSignatureDevis.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
        if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
            circuitSignatureDevis.keywords = 'NumDevis=' + quote.numeroDevis__c;
        circuitSignatureDevis.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
        Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
        step.name = 'DIPC';                                                     // Nom de l'étape
        step.stepNumber = 1;                                                  // Première étape
        step.maxDuration = 14;
        step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
        step.reminderDays = 3;
        step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
        circuitSignatureDevis.stepList.add(step);
        Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
        signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
        signataire.signerId = opp.AccountId;      // Id du signataire
        signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
        signataire.recipientType = 'Distance';
        signataire.signatureType = 'PAD';
        step.signerList.add(signataire);
        Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuitSignatureDevis);  
        quote.circuitSignatureDevis__c = launchResult.result;

        // Circuit Contrat
        Signea.Signea_Entities_v2.SigneaCircuit circuitSignatureCont = new Signea.Signea_Entities_v2.SigneaCircuit();
        circuitSignatureCont.name = 'Contrat (' + quote.numeroDevis__c + ')';
        circuitSignatureCont.description = 'Circuit de signature du ' + circuitSignatureCont.name;
        circuitSignatureCont.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
        circuitSignatureCont.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
        circuitSignatureCont.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
        if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
            circuitSignatureCont.keywords = 'NumDevis=' + quote.numeroDevis__c;
        circuitSignatureCont.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
        Signea.Signea_Entities_v2.SigneaStep step2 = new Signea.Signea_Entities_v2.SigneaStep();
        step2.name = 'Contrat';                                                     // Nom de l'étape
        step2.stepNumber = 1;                                                  // Première étape
        step2.maxDuration = 14;
        step2.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
        step2.reminderDays = 3;
        step2.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
        circuitSignatureCont.stepList.add(step2);
        Signea.Signea_Entities_v2.SigneaSigner signataire2 = new Signea.Signea_Entities_v2.SigneaSigner();
        signataire2.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
        signataire2.signerId = opp.AccountId;      // Id du signataire
        signataire2.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
        signataire2.recipientType = 'Distance';
        signataire2.signatureType = 'PAD';
        step2.signerList.add(signataire2);
        Signea.Signea_Entities_V2.SigneaServicesResult launchResult2 = Signea.Signea_API_V2.createNlaunchCircuit(circuitSignatureCont);  
        quote.circuitSignatureContrat__c = launchResult2.result;

        // Lien Devis avec circuit
        //update quote;
        
        // Cloture un circuit    
        /*System.debug('quote.circuitSignatureDevis__c : '+quote.circuitSignatureDevis__c);
        System.debug('circuitSignatur : '+[SELECT Id, Signea__Status__c FROM Signea__Circuit__c]);
        Signea__Circuit__c circ = [SELECT Id, Signea__Status__c FROM Signea__Circuit__c WHERE Id = :quote.circuitSignatureDevis__c LIMIT 1];
        circ.Signea__Status__c = 'Completed';           
        update circ;*/

        System.enqueueJob(new QA_LaunchSigneaCircuits(new Set<Id>{quote.Id}));

        Test.stopTest();
    }
}