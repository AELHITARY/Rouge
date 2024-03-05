//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Signea
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2023
//-- Version     : 1.2
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Signea {

    @isTest public static void test_SignatureElectronique() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération des Record Type
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrements utile
            Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            List<Account> accList = new List<Account>();
            Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', accPersoRT, 'Email',false);
            accList.add(acc);
            Account acc2 = Utils_Test.createAccount('Account Deux', 'test2', 'test2@test.fr', accPersoRT, 'Email',false);
            accList.add(acc2);
            insert accList;
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, acc2, chantier,true);

            // Création famille et sous famille
            List<Familles__c> famList = new List<Familles__c>();
            Familles__c fam1 = Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false);
            famList.add(fam1);
            Familles__c fam2 = Utils_Test.createFamilles('Autre','Autre','AUT',false);
            famList.add(fam2);
            insert famList;
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);

            // Creation produits
            List<Product2> prodList = new List<Product2>();
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prodList.add(prod);
            Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,false);
            prodList.add(prod2);
            insert prodList;

            Test.startTest();
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;

            // Coefficient thermique
            List<coeffTh__c> coeffThList = new List<coeffTh__c>();
            coeffTh__c coeffTh1 = Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',false);
            coeffTh__c coeffTh2 = Utils_Test.createCoeffTh(prod2.Id,refOpt.Id,'Sw',1,'T','2',false);
            coeffThList.add(coeffTh1);
            coeffThList.add(coeffTh2);
            insert coeffThList;

            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            devis.ExpirationDate = Date.today().addDays(14);
            insert devis;

            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;
            //Utils_Test.createOption(qli2.Id,'3','Libellé Option 3',refOpt.Id,220,true);

            devis.Status = Constants.StatutDevisNonTransmis;
            //update quote;

            system.debug('devis.Status : '+devis.Status);
            system.debug('devis.lignesConfigurees__c : '+devis.lignesConfigurees__c);
            system.debug('devis.LineItemCount : '+devis.LineItemCount);


            Attachment att = Utils_Test.createAttachment('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);

            PageReference newPage = Page.VF_Signea;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);

            Ctrl_Signea ctrl = new Ctrl_Signea();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';
            ctrl.isTestWithoutErrors = true;          
            ctrl.execute();

            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.numeroDevis__c + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
            circuit.keywords = 'NumDevis=' + devis.numeroDevis__c;
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
            signataire.signerId = acc.Id;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);

            Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
            temp.Name = 'Modèle standard';
            temp.Signea__Circuit_Name__c = 'Modèle standard';
            temp.Signea__Description__c = 'Le circuit standard';
            temp.Signea__Max_Duration__c = 20;
            temp.Signea__default_template__c = true;
            insert temp;

            Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();
            
            // Cloture un circuit    
            Signea__Circuit__c circ = [SELECT Id, Signea__Status__c FROM Signea__Circuit__c LIMIT 1];
            circ.Signea__Status__c = 'Completed';           
            update circ;

            ctrl.storedCircuitContrat = circ;
            ctrl.launchManualCircuit();
            ctrl.createBlobPDFTVA();

            Test.stopTest();
        }
    }

    @isTest public static void test_errors_SignatureElectronique() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération des Record Type
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrements utile
            Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',false);
            acc.contactParDefaut__c = null;
            insert acc;

            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

            // Création famille et sous famille
            List<Familles__c> famList = new List<Familles__c>();
            Familles__c fam1 = Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false);
            famList.add(fam1);
            Familles__c fam2 = Utils_Test.createFamilles('Autre','Autre','AUT',false);
            famList.add(fam2);
            insert famList;
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);

            // Creation produits
            List<Product2> prodList = new List<Product2>();
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prodList.add(prod);
            Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,false);
            prodList.add(prod2);
            insert prodList;

            Test.startTest();
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;


            // Coefficient thermique
            List<coeffTh__c> coeffThList = new List<coeffTh__c>();
            coeffTh__c coeffTh1 = Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',false);
            coeffTh__c coeffTh2 = Utils_Test.createCoeffTh(prod2.Id,refOpt.Id,'Sw',1,'T','2',false);
            coeffThList.add(coeffTh1);
            coeffThList.add(coeffTh2);
            insert coeffThList;

            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);

            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;
            //Utils_Test.createOption(qli2.Id,'3','Libellé Option 3',refOpt.Id,220,true);

            Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
            temp.Name = 'Modèle standard';
            temp.Signea__Circuit_Name__c = 'Modèle standard';
            temp.Signea__Description__c = 'Le circuit standard';
            temp.Signea__Max_Duration__c = 20;
            temp.Signea__default_template__c = true;
            insert temp;

            devis.modeFinancement__c = null;
            devis.delaiInstallationMax__c = null;
            devis.mntAcompteAttendu__c = null;
            devis.acompteRemiseMetreur__c = true;
            devis.acomptePreleveeCompte__c = true;
            devis.naturesTravaux__c = null;
            devis.typeAdresse__c = null;
            update devis;

            system.debug('devis.Status : '+devis.Status);
            system.debug('devis.lignesConfigurees__c : '+devis.lignesConfigurees__c);
            system.debug('devis.LineItemCount : '+devis.LineItemCount);


            Attachment att = Utils_Test.createAttachment('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);

            PageReference newPage = Page.VF_Signea;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);

            Ctrl_Signea ctrl = new Ctrl_Signea();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';        
            ctrl.execute();

            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.numeroDevis__c + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
            circuit.keywords = 'NumDevis=' + devis.numeroDevis__c;
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
            signataire.signerId = acc.Id;      // Id du signataire
            signataire.participantNumber = 1; // Premier participant (seulement pour les signataires !!!)
            signataire.recipientType = 'Distance';
            signataire.signatureType = 'PAD';
            step.signerList.add(signataire);

            Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuit);     
            ctrl.execute();

            Test.stopTest();
        }
    }
    
    @isTest public static void test_errors_DevisTMC() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération des Record Type
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création enregistrements utile
            Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',false);
            acc.contactParDefaut__c = null;
            insert acc;

            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

            // Création famille et sous famille
            List<Familles__c> famList = new List<Familles__c>();
            Familles__c fam1 = Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false);
            famList.add(fam1);
            Familles__c fam2 = Utils_Test.createFamilles('Autre','Autre','AUT',false);
            famList.add(fam2);
            insert famList;
            Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);

            // Creation produits
            List<Product2> prodList = new List<Product2>();
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
            prodList.add(prod);
            Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,false);
            prodList.add(prod2);
            insert prodList;

            Test.startTest();
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;


            // Coefficient thermique
            List<coeffTh__c> coeffThList = new List<coeffTh__c>();
            coeffTh__c coeffTh1 = Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',false);
            coeffTh__c coeffTh2 = Utils_Test.createCoeffTh(prod2.Id,refOpt.Id,'Sw',1,'T','2',false);
            coeffThList.add(coeffTh1);
            coeffThList.add(coeffTh2);
            insert coeffThList;

            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);            
            devis.devisTMC__c = true;
            devis.Dateacceptationclient__c = null;
            devis.Datetransmissionclient__c = null;
            devis.Moyentransmissionclient__c = null;
            insert devis;
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;
            //Utils_Test.createOption(qli2.Id,'3','Libellé Option 3',refOpt.Id,220,true);

            Signea__Circuit_Template__c temp = new Signea__Circuit_Template__c();
            temp.Name = 'Modèle standard';
            temp.Signea__Circuit_Name__c = 'Modèle standard';
            temp.Signea__Description__c = 'Le circuit standard';
            temp.Signea__Max_Duration__c = 20;
            temp.Signea__default_template__c = true;
            insert temp;

            devis.modeFinancement__c = null;
            devis.delaiInstallationMax__c = null;
            devis.mntAcompteAttendu__c = null;
            devis.acompteRemiseMetreur__c = true;
            devis.acomptePreleveeCompte__c = true;
            devis.naturesTravaux__c = null;
            devis.typeAdresse__c = null;
            update devis;


            Attachment att = Utils_Test.createAttachment('DIPC du devis.pdf', devis.id,Blob.valueof('test'),true);

            PageReference newPage = Page.VF_Signea;
            newPage.getParameters().put('quoteId',devis.Id);
            Test.setCurrentPage(newPage);

            Ctrl_Signea ctrl = new Ctrl_Signea();
            ctrl.getmanuscriteList();
            ctrl.getmanuscriteList2();
            ctrl.getManuscriteListVendeur();
            ctrl.documentType = 'DIPC';        
            ctrl.execute();

            // Circuit
            Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();
            circuit.name = 'DIPC (' + devis.numeroDevis__c + ')';
            circuit.description = 'Circuit de signature du ' + circuit.name;
            circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
            circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
            circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
            if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true))
            circuit.keywords = 'NumDevis=' + devis.numeroDevis__c;
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
            signataire.signerId = acc.Id;      // Id du signataire
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