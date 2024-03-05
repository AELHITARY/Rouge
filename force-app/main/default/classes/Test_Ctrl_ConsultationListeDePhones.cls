//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_ConsultationListeDePhones
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/10/2021
//-- Version     : 1.1
//-- * 1.1 : Optimisation
//-- * 1.0 : CRM-893 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_ConsultationListeDePhones {
    static Double longitude = 2.3354245000000446;
    static Double latitude = 48.8807489;

    @testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        // Récupération des Record Type
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrement utile
        List<Account> accList = new List<Account>();
        Account acc1 = Utils_Test.createAccount('Dupont', 'Jean', 'test@test.fr', accPersoRT, 'Piste', 'Email',false);
        acc1.Phone = '0123456789';
        acc1.Localisation__Latitude__s = latitude;
        acc1.Localisation__Longitude__s = longitude;
        accList.add(acc1);
        Account acc2 = Utils_Test.createAccount('Dupont', 'Jeanne', 'test2@test.fr', accPersoRT, 'Piste', 'Email',false);
        acc2.Phone = '9876543210';
        acc2.Localisation__Latitude__s = latitude;
        acc2.Localisation__Longitude__s = longitude;
        accList.add(acc2);
        insert accList;
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc1.Id,false);
        chantier.Localisation__Latitude__s = latitude;
        chantier.Localisation__Longitude__s = longitude;
        insert chantier;
        Opportunity opp = Utils_Test.createOpportunity(acc1, chantier, false);
        opp.StageName = 'Analyse';
        insert opp;
        //KContrat__c contrat = Utils_Test.createContrat('Contrat', chantier.Id, acc1.Id, '0001', true);

    }
    
    @isTest
    private static void test_ConsultationListePhone_Filters() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.RunAs(user) {            
            // Récup des comptes
            List<Account> accList = [SELECT id, Name FROM Account];
           	Account acc1 = accList[0];
           	Account acc2 = accList[1];
            
            Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            // Création de la liste de phones
            ListePhoningVendeur__c ldp = Utils_Test.createListePhoningVendeur('Liste 123',user.Id,true);            
            // Création des phones
            PhoningVendeur__c phone = Utils_test.createPhoningVendeur('Phone 123',ldp.Id,acc1.Id,true);            
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            // TEST
            Test.startTest();

            
            // Creation devis avec option
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            insert devis; 
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis;

            Test.stopTest();
            PageReference pageRef = Page.VF_ConsultationListeDePhones;
            Test.setCurrentPage(pageRef);
            Ctrl_ConsultationListeDePhones ctrlAccount = new Ctrl_ConsultationListeDePhones();

            ctrlAccount.insertUserStats();

            Map<String, String> arg = new Map<String, String>();
            arg.put('dr', 'R123');
            arg.put('drName', 'Région 123');
            arg.put('magasin', 'M123');
            arg.put('magasinName', 'Magasin 123');
            arg.put('dv', 'V123');
            arg.put('dvName', 'DV 123');
            arg.put('vendeur', '');
            arg.put('vendeurName', '');
            arg.put('statut', '');
            arg.put('dateDebut', '2111-11-11');
            arg.put('dateFin', '3111-11-11');
            arg.put('ldp', '');
            Ctrl_ConsultationListeDePhones.recuperePhones(arg);
            
            List<String> accountsId = new List<String>();
            accountsId.add(acc1.Id);
            accountsId.add(acc2.Id);
            Ctrl_ConsultationListeDePhones.getPieChartInfos(accountsId);
            
            Ctrl_ConsultationListeDePhones.updatePhone(phone.Id, true, true, '', '', '', 'update');
            Date dateDebut = Date.today().addDays(-1);            
            String dateRDV = dateDebut.year()+'-'+dateDebut.month()+'-'+dateDebut.day();
            Ctrl_ConsultationListeDePhones.updatePhone(phone.Id, true, true, dateRDV, '12:00:00', '2', 'update');
            
            List<String> types = new List<String>();
            types.add('Debriefe');
            types.add('ADebriefer');
            Ctrl_ConsultationListeDePhones.recuperePhonesAvecCoordonnees('M123', accountsId);
            
            ctrlAccount.nomLDP = ldp.Id;
            ctrlAccount.motifAnnulation = 'Test';
            ctrlAccount.cancelListeDePhone();
            ctrlAccount.nouvelleRecherche();
            
            delete phone;
            delete ldp;
            
        }
    }
    
	@isTest static void test_UpdateFields() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.runAs(user) {
            PageReference pageRef = Page.VF_ConsultationListeDePhones;
            Test.setCurrentPage(pageRef);
            Ctrl_ConsultationListeDePhones ctrl = new Ctrl_ConsultationListeDePhones();

            // Création de la liste de phones
            ListePhoningVendeur__c ldp = Utils_Test.createListePhoningVendeur('Liste 123',user.Id,true);  
            
            Test.startTest();
            Date dateDebut = Date.today().addDays(-1);            
            Date dateFin = Date.today();
            ctrl.fieldParamDebut = dateDebut.year()+'-'+dateDebut.month()+'-'+dateDebut.day();
            ctrl.fieldParamFin = dateFin.year()+'-'+dateFin.month()+'-'+dateFin.day();
            // Sans valeurs
           	ctrl.fieldParamDR = '';
            ctrl.fieldParamDV = '';
            ctrl.fieldParamMagasin = '';
            ctrl.fieldParamVendeur = '';
            ctrl.fieldParamLDP = '';
            ctrl.updateFields();
            
			// Avec valeurs
           	ctrl.fieldParamDR = 'DR_0000';
            ctrl.fieldParamDV = 'DV_0000';
            ctrl.fieldParamMagasin = 'M123';
            ctrl.fieldParamVendeur = 'MyTestLastName2';
            ctrl.fieldParamLDP = 'Liste 123';
            ctrl.updateFields();
            
            Test.stopTest();
        }
	}
    
	@isTest static void test_Others() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.runAs(user) {
            PageReference pageRef = Page.VF_ConsultationListeDePhones;
            Test.setCurrentPage(pageRef);
            Ctrl_ConsultationListeDePhones ctrl = new Ctrl_ConsultationListeDePhones();

            // Création de la liste de phones
            ListePhoningVendeur__c ldp = Utils_Test.createListePhoningVendeur('Liste 123',user.Id,true);  
            
            Test.startTest();
            
            Ctrl_ConsultationListeDePhones.getPhoneInfos(ldp.Id);            
			Ctrl_ConsultationListeDePhones.getSectorCoord('Magasin 123');
            
            Test.stopTest();
        }
	}
}