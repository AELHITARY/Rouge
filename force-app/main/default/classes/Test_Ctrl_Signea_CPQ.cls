//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Signea_CPQ
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 12/07/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Signea_CPQ {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id CPQ_DEVIS_RTID = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', 'SalesQuote');
    private static final Id CPQ_SAV_RTID = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', 'AfterSalesServiceQuote');

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
    public static void test_SignatureElectronique() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'TR020_Account;TR021_Account;TR022_Account;TR022_SBQQ_QuoteLine;QA_KMDCEinstein;TR022_SBQQ_Quote;TR022_ContentVersion';
        update user;

        System.runAs(user){
            // Création enregistrements utile
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            
            // Création famille et sous famille
            List<Familles__c> famList = new List<Familles__c>();
            famList.add(Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false));
            famList.add(Utils_Test.createFamilles('Autre','Autre','AUT',false));
            insert famList;
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);
            
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            Test.startTest();
            
            // Creation devis
            SBQQ__Quote__c devis = Utils_Test.createCPQQuote(opp,Date.today(),0,false);
            devis.SBQQ__ExpirationDate__c = Date.today().addDays(14);
            insert devis;
            
            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(devis.Id,30, 100, 2, prod,true);
            
            // Options des produits
            List<SBQQ__QuoteLine__c> optList = new List<SBQQ__QuoteLine__c>();
            optList.add(Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod, false));
            optList.add(Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod, false));
            insert optList;

            // passage en non transmis
            devis.quoteIsValid__c = true;
            update devis;
            
            ContentDocumentLink att = Utils_Test.createFile('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);
            
            PageReference newPage = Page.VF_Signea_CPQ;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);
            
            Ctrl_Signea_CPQ ctrl = new Ctrl_Signea_CPQ();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';
            ctrl.isTestWithoutErrors = true;          
            ctrl.execute();
            
            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.Name + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
                circuit.keywords = 'NumDevis=' + devis.Name;
            circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
            
            // Document à signer
            Signea.Signea_Entities_v2.SigneaDocument document = new Signea.Signea_Entities_v2.SigneaDocument();
            document.id = att.Id;
            circuit.documentList.add(document);
            
            Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
            step.name = 'DIPC';                                                     // Nom de l'étape
            step.stepNumber = 1;                                                  // Première étape
            step.maxDuration = 14;
            step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
            step.reminderDays = 3;
            step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
            circuit.stepList.add(step);
            
            Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
            signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
            signataire.signerId = opp.AccountId;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);
            
            /*Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();
            
            // Cloture un circuit    
            Signea__Circuit__c circ = [SELECT Id, Signea__Status__c FROM Signea__Circuit__c LIMIT 1];
            circ.Signea__Status__c = 'Completed';           
            update circ;
            
            ctrl.storedCircuitContrat = circ;
            ctrl.launchManualCircuit();*/
            
            Test.stopTest();
        }
    }

    @isTest 
    public static void test_SignatureElectroniqueSAV() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'TR020_Account;TR021_Account;TR022_Account;TR022_SBQQ_QuoteLine;QA_KMDCEinstein;TR022_SBQQ_Quote;TR022_ContentVersion';
        update user;

        System.runAs(user){
            // Création enregistrements utile
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            
            // Création famille et sous famille
            List<Familles__c> famList = new List<Familles__c>();
            famList.add(Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false));
            famList.add(Utils_Test.createFamilles('Autre','Autre','AUT',false));
            insert famList;
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);
            
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            
            Test.startTest();
            
            // Creation devis
            // SBQQ__Quote__c devis = Utils_Test.createCPQQuote(opp,Date.today(),0,false);
            Date dateDevis = Date.today();            
            String nom = 'Devis SAV - ' + dateDevis.year() + '-' + dateDevis.month() + '-' + dateDevis.day();
            SBQQ__Quote__c devis = Utils_Test.createCPQQuote(nom, CPQ_SAV_RTID, opp, null, dateDevis, null, 0, null, null, false);
            devis.SBQQ__ExpirationDate__c = Date.today().addDays(14);
            insert devis;
           
            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(devis.Id,30, 100, 2, prod,true);
            
            // Options des produits
            List<SBQQ__QuoteLine__c> optList = new List<SBQQ__QuoteLine__c>();
            optList.add(Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod, false));
            optList.add(Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod, false));
            insert optList;

            // passage en non transmis
            devis.quoteIsValid__c = true;
            update devis;
            
            ContentDocumentLink att = Utils_Test.createFile('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);
            
            PageReference newPage = Page.VF_Signea_CPQ;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);
            
            Ctrl_Signea_CPQ ctrl = new Ctrl_Signea_CPQ();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';
            ctrl.isTestWithoutErrors = true;          
            ctrl.execute();
            
            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.Name + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
                circuit.keywords = 'NumDevis=' + devis.Name;
            circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
            
            // Document à signer
            Signea.Signea_Entities_v2.SigneaDocument document = new Signea.Signea_Entities_v2.SigneaDocument();
            document.id = att.Id;
            circuit.documentList.add(document);
            
            Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
            step.name = 'DIPC';                                                     // Nom de l'étape
            step.stepNumber = 1;                                                  // Première étape
            step.maxDuration = 14;
            step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
            step.reminderDays = 3;
            step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
            circuit.stepList.add(step);
            
            Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
            signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
            signataire.signerId = opp.AccountId;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);
            
            /*Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();
            
            // Cloture un circuit    
            Signea__Circuit__c circ = [SELECT Id, Signea__Status__c FROM Signea__Circuit__c LIMIT 1];
            circ.Signea__Status__c = 'Completed';           
            update circ;
            
            ctrl.storedCircuitContrat = circ;
            ctrl.launchManualCircuit();*/
            
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void test_errors_SignatureElectronique() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            
            // Création famille et sous famille
            Utils_Test.createFamilles('Fenetre','Fenetre','FEN',true);
            Utils_Test.createFamilles('Autre','Autre','AUT',true);
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);
            
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            
            Test.startTest();
            
            // Creation devis
            SBQQ__Quote__c devis = Utils_Test.createCPQQuote(opp,Date.today(), 0, true);
            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(devis.Id, 30, 100, 2,prod,true);
            
            // Options des produits
            Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod,true);
            Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod,true);
            
            Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
            temp.Name = 'Modèle standard';
            temp.Signea__Circuit_Name__c = 'Modèle standard';
            temp.Signea__Description__c = 'Le circuit standard';
            temp.Signea__Max_Duration__c = 20;
            temp.Signea__default_template__c = true;
            insert temp;
            
            devis.financingMethod__c = null;
            devis.minCommercialDelay__c  = null;
            devis.MontantAcompteAttendu__c = null;
            devis.natureTravaux__c = null;
            devis.typeAdresse__c = null;
            update devis;
            
            system.debug('devis.Status : '+devis.SBQQ__Status__c);
            system.debug('devis.LineItemCount : '+devis.SBQQ__LineItemCount__c);
            
            ContentDocumentLink att = Utils_Test.createFile('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);
            
            PageReference newPage = Page.VF_Signea_CPQ;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);
            
            Ctrl_Signea_CPQ ctrl = new Ctrl_Signea_CPQ();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';        
            ctrl.execute();
            
            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.Name + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
                circuit.keywords = 'NumDevis=' + devis.Name;
            circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
            
            // Document à signer
            Signea.Signea_Entities_v2.SigneaDocument document = new Signea.Signea_Entities_v2.SigneaDocument();
            document.id = att.Id;
            circuit.documentList.add(document);
            
            Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
            step.name = 'DIPC';                                                     // Nom de l'étape
            step.stepNumber = 1;                                                  // Première étape
            step.maxDuration = 14;
            step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
            step.reminderDays = 3;
            step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
            circuit.stepList.add(step);
            
            Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
            signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
            signataire.signerId = opp.AccountId;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);
            
            Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();
            
            Test.stopTest();
        }
    }

    @isTest 
    public static void test_errors_SignatureElectroniqueSAV() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            
            // Création famille et sous famille
            Utils_Test.createFamilles('Fenetre','Fenetre','FEN',true);
            Utils_Test.createFamilles('Autre','Autre','AUT',true);
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);
            
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            
            Test.startTest();
            
            // Creation devis
            // SBQQ__Quote__c devis = Utils_Test.createCPQQuote(opp,Date.today(), 0, true);            
            Date dateDevis = Date.today();            
            String nom = 'Devis SAV - ' + dateDevis.year() + '-' + dateDevis.month() + '-' + dateDevis.day();
            SBQQ__Quote__c devis = Utils_Test.createCPQQuote(nom, CPQ_SAV_RTID, opp, null, dateDevis, null, 0, null, null, true);

            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(devis.Id, 30, 100, 2,prod,true);
            
            // Options des produits
            Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod,true);
            Utils_Test.createCPQOption(qli.Id,devis.Id,30, 100, 2, prod,true);
            
            Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
            temp.Name = 'Modèle standard';
            temp.Signea__Circuit_Name__c = 'Modèle standard';
            temp.Signea__Description__c = 'Le circuit standard';
            temp.Signea__Max_Duration__c = 20;
            temp.Signea__default_template__c = true;
            insert temp;
            
            devis.financingMethod__c = null;
            devis.minCommercialDelay__c  = null;
            devis.MontantAcompteAttendu__c = null;
            devis.natureTravaux__c = null;
            devis.typeAdresse__c = null;
            update devis;
            
            system.debug('devis.Status : '+devis.SBQQ__Status__c);
            system.debug('devis.LineItemCount : '+devis.SBQQ__LineItemCount__c);
            
            ContentDocumentLink att = Utils_Test.createFile('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);
            
            PageReference newPage = Page.VF_Signea_CPQ;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);
            
            Ctrl_Signea_CPQ ctrl = new Ctrl_Signea_CPQ();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';        
            ctrl.execute();
            
            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.Name + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
                circuit.keywords = 'NumDevis=' + devis.Name;
            circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
            
            // Document à signer
            Signea.Signea_Entities_v2.SigneaDocument document = new Signea.Signea_Entities_v2.SigneaDocument();
            document.id = att.Id;
            circuit.documentList.add(document);
            
            Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
            step.name = 'DIPC';                                                     // Nom de l'étape
            step.stepNumber = 1;                                                  // Première étape
            step.maxDuration = 14;
            step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
            step.reminderDays = 3;
            step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
            circuit.stepList.add(step);
            
            Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
            signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
            signataire.signerId = opp.AccountId;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);
            
            Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();
            
            Test.stopTest();
        }
    }
   
}