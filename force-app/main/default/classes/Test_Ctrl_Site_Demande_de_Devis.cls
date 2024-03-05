//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Site_Demande_de_Devis
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/10/2021
//-- Version     : 1.1
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Site_Demande_de_Devis {
    
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
    }
    
    @isTest 
    static void test_Demande_de_Devis_EtapeOK(){
        //creation utilisateur
        User user = Utils_Test.createAdminUser();
        System.runAs(user){
            PageReference pa = Page.VF_Site_Demande_de_Devis;
            Test.setCurrentPage(pa);
            Ctrl_Site_Demande_de_Devis ctrl = new Ctrl_Site_Demande_de_Devis();
            Test.startTest();

            // Test Compte OK
            ctrl.civilite = 'M';
            ctrl.nom = 'Test';
            ctrl.prenom = 'Test';
            ctrl.rue = '2 allée Van Gogh';
            ctrl.cp = '13000';
            ctrl.ville = 'Marseille';
            ctrl.departement = '13';
            ctrl.pays = 'France';
            ctrl.tel = '0123456789';
            ctrl.email = 'Test@tt.fr';
            ctrl.radioPersonne = 'l';
            ctrl.boolProjetFenetre = true;
            ctrl.typeHabitation = 'Pavillon';
            ctrl.boolPlusInfo = true;
            ctrl.boolRecevoirOffre = true;
            ctrl.validationEtape1();

            // Passage dans les erreurs
            ctrl.typeHabitation = '';
            ctrl.validationEtape1();

            ctrl.radioPersonne = '';
            ctrl.validationEtape1();

            ctrl.email = 'TATA';
            ctrl.validationEtape1();

            ctrl.email = '';
            ctrl.validationEtape1();

            ctrl.tel = 'ZAZA';
            ctrl.validationEtape1();

            ctrl.tel = '';
            ctrl.validationEtape1();

            ctrl.cp = 'RARA';
            ctrl.validationEtape1();

            ctrl.cp = '';
            ctrl.validationEtape1();

            ctrl.prenom = '';
            ctrl.validationEtape1();

            ctrl.nom = '';
            ctrl.validationEtape1();

            ctrl.civilite = '';
            ctrl.validationEtape1();

            ctrl.adresse_latitude = 4;
            ctrl.adresse_longitude = 2;

            ctrl.civilite = 'M';
            ctrl.nom = 'Test';
            ctrl.prenom = 'Test';
            ctrl.rue = '2 allée Van Gogh';
            ctrl.cp = '13000';
            ctrl.ville = 'Marseille';
            ctrl.departement = '13';
            ctrl.pays = 'France';
            ctrl.tel = '0123456789';
            ctrl.email = 'Test@tt.fr';
            ctrl.radioPersonne = 'l';
            ctrl.boolProjetFenetre = true;
            ctrl.typeHabitation = 'Pavillon';

            Import__c importCompte = new Import__c();
            List<Import__c> importCompteList = [SELECT id FROM Import__c WHERE nomCompte__c = :ctrl.nom 
                                                    AND prenomCompte__c = :ctrl.prenom AND emailCompte__c= :ctrl.email];
            if(!importCompteList.isEmpty()) {
                importCompte = importCompteList[0];
            }
        //  System.assertNotEquals(null, importCompte.Id);

            // Test Etape 2
            PageReference paEtape2 = Page.VF_Site_Demande_de_Devis_Etape2;
            Test.setCurrentPage(paEtape2);
            paEtape2.getParameters().put ('id' , importCompte.id);
            paEtape2.getParameters().put ('p' , '123456');
            ctrl.initVerifParameters();

            // Retour Etape 1
            ctrl.index();
            Test.setCurrentPage(paEtape2);
            paEtape2.getParameters().put ('id' , importCompte.id);
            paEtape2.getParameters().put ('p' , '123456');
            ctrl.initVerifParameters();


            // Test Validation Etape 2
            ctrl.idUtilisateur = importCompte.Id;
            ctrl.projet = '123456';
            ctrl.typeFenetre = '2';
            ctrl.materiauFenetre = '2';
            ctrl.quantiteFenetre = '1';
            ctrl.typeVolet = '2';
            ctrl.materiauVolet = '2';
            ctrl.quantiteVolet = '1';
            ctrl.typeGarage = '2';
            ctrl.quantiteGarage = '1';
            ctrl.materiauPortail = '2';
            ctrl.quantitePortail = '1';
            ctrl.typePorte = '2';
            ctrl.quantitePorte = '1';
            ctrl.typeStore = '2';
            ctrl.quantiteStore = '1';
            ctrl.validationEtape2();

            // Liste des erreurs
            ctrl.quantiteStore = '0';
            ctrl.validationEtape2();

            ctrl.typeStore = null;
            ctrl.validationEtape2();

            ctrl.quantitePorte = '0';
            ctrl.validationEtape2();

            ctrl.typePorte = null;
            ctrl.validationEtape2();

            ctrl.quantitePortail = '0';
            ctrl.validationEtape2();

            ctrl.materiauPortail = null;
            ctrl.validationEtape2();

            ctrl.quantiteGarage = '0';
            ctrl.validationEtape2();

            ctrl.typeGarage = null;
            ctrl.validationEtape2();

            ctrl.quantiteVolet = '0';
            ctrl.validationEtape2();

            ctrl.materiauVolet = null;
            ctrl.validationEtape2();

            ctrl.typeVolet = null;
            ctrl.validationEtape2();

            ctrl.quantiteFenetre = '0';
            ctrl.validationEtape2();

            ctrl.materiauFenetre = null;
            ctrl.validationEtape2();

            ctrl.typeFenetre = null;
            ctrl.validationEtape2();

            ctrl.idUtilisateur = '';
            ctrl.validationEtape2();

            ctrl.idUtilisateur = importCompte.Id;
            ctrl.projet = '123456';
            ctrl.typeFenetre = '1';
            ctrl.materiauFenetre = '1';
            ctrl.quantiteFenetre = '1';
            ctrl.typeVolet = '1';
            ctrl.materiauVolet = '1';
            ctrl.quantiteVolet = '1';
            ctrl.typeGarage = '1';
            ctrl.quantiteGarage = '1';
            ctrl.materiauPortail = '1';
            ctrl.quantitePortail = '1';
            ctrl.typePorte = '1';
            ctrl.quantitePorte = '1';
            ctrl.typeStore = '1';
            ctrl.quantiteStore = '1';
            ctrl.validationEtape2();

            ctrl.typeFenetre = '1';
            ctrl.materiauFenetre = '2';
            ctrl.typeVolet = '1';
            ctrl.materiauVolet = '2';
            ctrl.typePorte = '3';
            ctrl.validationEtape2();

            ctrl.materiauFenetre = '3';
            ctrl.materiauVolet = '3';
            ctrl.typePorte = '4';
            ctrl.validationEtape2();

            ctrl.materiauFenetre = '4';
            ctrl.typeVolet = '2';
            ctrl.materiauVolet = '3';
            ctrl.validationEtape2();

            ctrl.typeFenetre = '4';
            ctrl.materiauFenetre = '1';
            ctrl.typeVolet = '3';
            ctrl.materiauVolet = '2';
            ctrl.validationEtape2();
            ctrl.validationEtape3();

            Test.stopTest();
        }
    }

    @isTest 
    static void test_Demande_de_Devis_Etape2NOK(){
        //creation utilisateur
        User user = Utils_Test.createAdminUser();
        System.runAs(user){
            PageReference pa = Page.VF_Site_Demande_de_Devis;
            Test.setCurrentPage(pa);
            Ctrl_Site_Demande_de_Devis ctrl = new Ctrl_Site_Demande_de_Devis();

            Test.startTest();

            // Test Compte NOM NOK
            ctrl.civilite = 'M';
            ctrl.nom = 'Test2';
            ctrl.prenom = 'Test';
            ctrl.cp = '13000';
            ctrl.ville = 'Marseille';
            ctrl.tel = '0123456789';
            ctrl.email = 'Test@tt.fr';
            ctrl.radioPersonne = 'l';
            ctrl.typeHabitation = 'Pavillon';
            ctrl.boolPlusInfo = true;
            ctrl.boolRecevoirOffre = true;
            ctrl.validationEtape1();

            List<Import__c> importCompteList1 = [SELECT id FROM Import__c WHERE nomCompte__c = :ctrl.nom 
                                                    AND prenomCompte__c = :ctrl.prenom AND emailCompte__c= :ctrl.email];
            System.assertEquals(true, importCompteList1.isEmpty());

            // Test Compte PRENOM NOK
            ctrl.civilite = 'M';
            ctrl.nom = 'Test';
            ctrl.prenom = 'Test2';
            ctrl.cp = '13000';
            ctrl.ville = 'Marseille';
            ctrl.tel = '0123456789';
            ctrl.email = 'Test@tt.fr';
            ctrl.radioPersonne = 'l';
            ctrl.typeHabitation = 'Pavillon';
            ctrl.boolPlusInfo = true;
            ctrl.boolRecevoirOffre = true;
            ctrl.validationEtape1();

            List<Import__c> importCompteList2 = [SELECT id FROM Import__c WHERE nomCompte__c = :ctrl.nom 
                                                    AND prenomCompte__c = :ctrl.prenom AND emailCompte__c= :ctrl.email];
            System.assertEquals(true, importCompteList2.isEmpty());

            Test.stopTest();
        }
    }

    @isTest 
    static void test_Demande_de_Devis_CompteExistant(){
        //creation utilisateur
        User user = Utils_Test.createAdminUser();
        System.runAs(user){
            // Récupération des Record Type
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            // Création d'un compte
            Account compteTest = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', accPersoRT, 'Email',true);
            compteTest = [SELECT id, nom__c, prenom__c, AccountNumber, type FROM Account WHERE id = :compteTest.id];
            compteTest.Type = 'Client';
            compteTest.PersonHomePhone = '0123456789';
            compteTest.PersonMailingPostalCode = '13000';
            compteTest.PersonMailingCity = 'Marseille';
            update compteTest;

            PageReference pa = Page.VF_Site_Demande_de_Devis;
            Test.setCurrentPage(pa);
            Ctrl_Site_Demande_de_Devis ctrl = new Ctrl_Site_Demande_de_Devis();

            Test.startTest();

            // Test Compte OK
            ctrl.civilite = 'M';
            ctrl.nom = 'Test';
            ctrl.prenom = 'Test';
            ctrl.cp = '13000';
            ctrl.ville = 'Marseille';
            ctrl.tel = '0123456789';
            ctrl.email = 'test@test.fr';
            ctrl.radioPersonne = 'l';
            ctrl.typeHabitation = 'Pavillon';
            ctrl.boolPlusInfo = true;
            ctrl.boolRecevoirOffre = true;
            ctrl.validationEtape1();

            List<Import__c> importCompteList = [SELECT id FROM Import__c WHERE nomCompte__c = :ctrl.nom 
                                                    AND prenomCompte__c = :ctrl.prenom AND emailCompte__c= :ctrl.email];
            System.assertEquals(true, importCompteList.isEmpty());

            Test.stopTest();
        }
    }

    @isTest 
    static void test_Demande_de_Devis_Etape2VerifParametreNOK(){
        //creation utilisateur
        User user = Utils_Test.createAdminUser();
        System.runAs(user){
            // Etape 1
            PageReference pa = Page.VF_Site_Demande_de_Devis;
            Test.setCurrentPage(pa);
            Ctrl_Site_Demande_de_Devis ctrl = new Ctrl_Site_Demande_de_Devis();

            Test.startTest();

            // Test Etape 2
            PageReference paEtape2 = Page.VF_Site_Demande_de_Devis_Etape2;
            Test.setCurrentPage(paEtape2);
            String nextPage = ctrl.initVerifParameters().getUrl();
            System.assertEquals(Page.VF_Site_Demande_de_Devis.getUrl(), nextPage);

            Test.stopTest();
        }
    }
}