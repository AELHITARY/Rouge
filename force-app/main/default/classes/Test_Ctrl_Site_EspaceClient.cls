//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Site_EspaceClient
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/10/2021
//-- Version     : 2.2
//-- * 2.2 : RQM-76 : GDPR
//-- * 2.1 - RQM-34 : Evolution pour type de dotation filleul
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Site_EspaceClient {
    
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        PropertiesUtils.setIntegerValue('espaceclient.securiteMDP.longueurMin', 4);
        PropertiesUtils.setIntegerValue('espaceclient.securiteMDP.longueurMax', 10);
        PropertiesUtils.setIntegerValue('espaceclient.securiteMDP.nbChiffres', 1);
        PropertiesUtils.setIntegerValue('espaceclient.securiteMDP.nbMaj', 1);
        PropertiesUtils.setIntegerValue('espaceclient.securiteMDP.nbMin', 1);
        Utils_Test.createSectorisation();
        
        // Récupération des types d'enregistrement
        Id accRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        
        // Création d'un compte
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', accRecordType, 'FAX', false);
        account.Type = 'Client';
        account.forcageType__c = 'Client';
        account.motDePasseClient__c = Ctrl_Site_EspaceClient.encodePassword('1aB%cdef');
        account.PersonMailingStreet = '29 rue des marais';
        account.PersonMailingPostalCode = '83570';
        account.PersonMailingCity = 'Cotignac';
        account.etage__c = 4;
        account.interphone__c = '1234A';
        account.PersonMailingPostalCode = '83570';
        account.PersonMailingCity = 'Cotignac';
        account.PersonHomePhone = '0000000001';
        account.Fax = '0000000002';
        account.PersonMobilePhone = '0000000003';
        insert account;
        
        // Création d'un chantier        
        //RecordType chantierRecordType = [Select id, Name from RecordType where sobjectType = 'Chantier__c' and isActive = true limit 1];
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, false);
        // Mise à jour localisation
        chantier.codeMagasinTechnique__c = 'M123';
        chantier.Localisation__Latitude__s = 12;
        chantier.Localisation__Longitude__s = 12;
        insert chantier;
        
        // Création d'un contrat
        KContrat__c contratMetrage = Utils_Test.createContrat('Contrat Metrage', chantier.Id, account.Id, '0002', true);

        // Création d'un mapping Type de demande <-> RecordType
        Mapping__c mapping = new Mapping__c();
        mapping.name = 'caseTypeMapping_nouveauRDV';
        mapping.repository__c = 'case_typeMapping';
        mapping.pickValue__c = 'Nouveau rendez-vous';
        mapping.convertedValue__c = 'relationClient';
        insert mapping;
    }

    // Teste la méthode de chiffrement du contrôleur
    @isTest 
    static void test_Espace_Client_encodePassword() {
        Test.startTest();
        System.assertEquals(Ctrl_Site_EspaceClient.encodePassword('tirlibibix66'), Ctrl_Site_EspaceClient.encodePassword('tirlibibix66'));
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword('tirlibibix666'), Ctrl_Site_EspaceClient.encodePassword('tirlibibix66'));
        Test.stopTest();
    }
    
    // Teste le processus de connexion entier
    // Connexion avec Numéro de compte connu & mot de passe
    @isTest 
    static void test_Espace_Client_Connexion_OK1() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Numéro de compte connu
        Account accountRequest = [SELECT Id, AccountNumber, Type, isPersonAccount, email__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        System.assert(accountRequest.isPersonAccount, 'Test account must be a person account.');
        Boolean testIsClient = (accountRequest.Type == Constants.ACCOUNT_TYPE_CLIENT || accountRequest.Type == Constants.ACCOUNT_TYPE_EXCLIENT);
        System.assert(testIsClient, 'Test account must be of type Client or Ex-client. type = ' + accountRequest.Type);
        System.debug('Test account numeroCompte = ' + accountRequest.AccountNumber);
        System.debug('Test account email__c = ' + accountRequest.email__c);
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);
        
        Test.startTest();
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = '1aB%cdef';

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertNotEquals(null, loginResult, 'login() returned null');
        System.assert(ctrl.loginCorrect, 'loginCorrect not true');

        //Vérif connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        System.assertEquals(null, checkAccessResult, 'checkAllowedAccess failed');
        
        // Deconnexion
        ctrl.deconnexion();
        System.assert(!ctrl.loginCorrect, 'loginCorrect true after logout');
        Test.stopTest();
    }
    
    // Teste le processus de connexion en mode admin
    @isTest 
    static void test_Espace_Client_AdminConnexion_OK() {
        // Numéro de compte connu
        Account accountRequest = [SELECT Id, AccountNumber, Type, isPersonAccount, email__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);
        
        Test.startTest();

        //Connexion Admin
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        pa.getParameters().put('accId', accountRequest.Id);
        ctrl.forceVisualforceLogin();

        Test.stopTest();
    }
    
    // Teste le processus de connexion en mode admin
    @isTest 
    static void test_Espace_Client_AdminConnexion_KO() {
        
        Test.startTest();
        
        //Connexion Admin
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        pa.getParameters().put('accId', 'test'); // Compte inexistant
        ctrl.forceVisualforceLogin();

        Test.stopTest();
    }

    // Connexion avec E-mail & mot de passe
    @isTest 
    static void test_Espace_Client_Connexion_OK2() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Numéro de compte connu
        Account accountRequest = [SELECT Id, email__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        ctrl.user = accountRequest.email__c;
        ctrl.password = '1aB%cdef';

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertNotEquals(null, loginResult, 'login() returned null');
        System.assert(ctrl.loginCorrect, 'loginCorrect not true');

        //Vérif connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        System.assertEquals(null, checkAccessResult, 'checkAllowedAccess failed');
        
        // Deconnexion
        ctrl.deconnexion();
        System.assert(!ctrl.loginCorrect, 'loginCorrect true after logout');
        Test.stopTest();
    }

    // Connexion avec E-mail & mot de passe
    @isTest 
    static void test_Espace_Client_Connexion_MultipleAccountKO() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Création d'un compte
        Id accRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);        
        
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', accRecordType, 'FAX', false);
        account.Type = 'Client';
        account.forcageType__c = 'Client';
        account.motDePasseClient__c = Ctrl_Site_EspaceClient.encodePassword('1aB%cdef');
        account.PersonMailingStreet = '29 rue des marais';
        account.PersonMailingPostalCode = '83570';
        account.PersonMailingCity = 'Cotignac';
        account.etage__c = 4;
        account.interphone__c = '1234A';
        account.PersonMailingPostalCode = '83570';
        account.PersonMailingCity = 'Cotignac';
        account.PersonHomePhone = '0000000001';
        account.Fax = '0000000002';
        account.PersonMobilePhone = '0000000003';
        insert account;

        // Numéro de compte connu
        List<Account> accountRequest = [SELECT Id, email__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com'];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest[0].Id);
        fixedSearchResults.add(accountRequest[1].Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();

        
        ctrl.user = accountRequest[0].email__c;
        ctrl.password = '1aB%cdef';

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertEquals(null, loginResult, 'login() not returned null');
        //System.assert(ctrl.loginCorrect, 'loginCorrect not true');

        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_Connexion_KO_wrongPassword() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Numéro de compte connu
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = '1aB%cdeF';

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertEquals(null, loginResult, 'login() must return null');
        System.assert(!ctrl.loginCorrect, 'loginCorrect true while password was wrong');

        //Vérif (non) connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        System.assertNotEquals(null, checkAccessResult, 'checkAllowedAccess must redirect to login page');

        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_Connexion_KO_noPassword() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Numéro de compte connu
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = null;

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertEquals(null, loginResult, 'login() must return null');
        System.assert(!ctrl.loginCorrect, 'loginCorrect true while password was wrong');

        //Vérif (non) connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        System.assertNotEquals(null, checkAccessResult, 'checkAllowedAccess must redirect to login page');

        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_Connexion_KO_emptyUser() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        // Numéro de compte connu
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        ctrl.user = '';
        ctrl.password = '1aB%cdef';

        //Connexion
        PageReference loginResult = ctrl.login();
        System.assertEquals(null, loginResult, 'login() must return null');
        System.assert(!ctrl.loginCorrect, 'loginCorrect true while password was wrong');

        //Vérif (non) connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        System.assertNotEquals(null, checkAccessResult, 'checkAllowedAccess must redirect to login page');

        Test.stopTest();
    }

    //Cas qu'il faudrait tester mais impossible de créer des cookies pendant des tests
    @isTest 
    static void test_Espace_Client_Connexion_OK_withCookie() {
        Account accountRequest = [SELECT Id, AccountNumber, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.accountInitial = accountRequest;

        //Vérif connexion avec cookie
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        Test.startTest();
        /*ctrl.createSessionCookie();
        ctrl.accountInitial = null; //raz du ctrl
        PageReference checkAccessResult = ctrl.checkAllowedAccess();*/
        Test.stopTest();

        //System.assertEquals(null, checkAccessResult, 'checkAllowedAccess should return null if access is allowed');

        
    }

    // Teste reconnexion sans cookie
    @isTest 
    static void test_Espace_Client_Connexion_KO_noCookie() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        Test.startTest();

        //Vérif connexion
        PageReference pa2 = Page.VF_Site_EspaceClient_Edit;
        Test.setCurrentPage(pa2);
        PageReference checkAccessResult = ctrl.checkAllowedAccess();
        
        Test.stopTest();

        System.assertNotEquals(null, checkAccessResult, 'checkAllowedAccess must redirect to login page');
    }

    @isTest 
    static void test_Espace_Client_GeneratePassword_OK() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.displayGeneratePasswordPage();

        // Account connu et OK
        Account accountRequest = [SELECT Id, AccountNumber, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();

        ctrl.user = accountRequest.AccountNumber;
        ctrl.generateNewPassword();

        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_GeneratePassword_KO_UserNoEmail() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.displayGeneratePasswordPage();

        //Création d'un nouveau compte sans adresse email
        Account account5 = new Account();
        account5.Salutation = 'Mme';
        account5.LastName = 'Test5';
        account5.FirstName = 'test5';
        account5.PersonMailingStreet = '29 rue des marais';
        account5.PersonMailingPostalCode = '83570';
        account5.PersonMailingCity = 'Cotignac';
        account5.etage__c = 4;
        account5.interphone__c = '1234A';
        account5.PersonMailingPostalCode = '83570';
        account5.PersonMailingCity = 'Cotignac';
        account5.PersonHomePhone = '0000000001';
        account5.Fax = '0000000002';
        account5.canalPrefere__c = 'FAX';
        account5.PersonMobilePhone = '0000000003';
        account5.motDePasseClient__c = '1aBetetetette%cdef';
        insert account5;

        // Account connu & pas de mail
        Account accountRequest = [SELECT Id, AccountNumber, PersonMailingPostalCode FROM Account WHERE lastName = 'Test5' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();

        ctrl.user = accountRequest.AccountNumber;
        ctrl.generateNewPassword();

        Test.stopTest();
    }
    
    @isTest 
    static void test_Espace_Client_GeneratePassword_KO_NoUser() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.displayGeneratePasswordPage();

        //Pas de user
        ctrl.user = '';
        ctrl.generateNewPassword();
    }
    
    @isTest 
    static void test_Espace_Client_GeneratePassword_KO_NoEmail() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.displayGeneratePasswordPage();
        
        //Pas de mail 
        ctrl.mail = '';
        ctrl.generateNewPassword();
    }
    
    @isTest 
    static void test_Espace_Client_GeneratePassword_KO_UnknownAccount() {
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.displayGeneratePasswordPage();

        // Account inconnu & numéro de compte connu
        ctrl.user = 'ABCDEFG';
        ctrl.generateNewPassword();
    }
    
    @isTest 
    static void test_Espace_Client_UpdateAccountPerso_OK() {
        // Création QUEUE "Demande espace client"
        User userAdmin = TestCommon.createUser(true,'testmlg', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null);
        User userAdmin2 = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null);
        system.RunAs(userAdmin) {
            Group groupDemande = new Group(Name='Demandes espace client', type='Queue');
            insert groupDemande;
            QueuesObject queueObject = new QueueSObject(QueueID = groupDemande.id, SobjectType = 'Case');
            insert queueObject;
        }
        
        system.RunAs(userAdmin2) {
            PageReference pa = Page.VF_Site_EspaceClient;
            Test.setCurrentPage(pa);
            Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
            
            // Connexion
            Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
            ctrl.user = accountRequest.AccountNumber;
            ctrl.password = '1aB%cdef';
            Pagereference edit = ctrl.checkAccountLogin(accountRequest.AccountNumber, '1aB%cdef', true);
    
            Test.startTest();
            
            // Initialisation map des valeurs à modifier
            Map<String, String> mapValue = new Map<String, String>();
            // Modification de compte personnel
            mapValue.put('civilite', 'Mme');
            mapValue.put('prenom', 'Test');
            mapValue.put('nom', 'test');
            mapValue.put('rue', '5 rue des sauriès');
            mapValue.put('ville', 'Eguilles');
            mapValue.put('codePostal', '13510');
            mapValue.put('complementAdresse', 'blablabla');
            mapValue.put('etage', '12');
            mapValue.put('interphone', '1234A');
            mapValue.put('telephoneDomicile', '0464777899');
            mapValue.put('telephoneMobile', '0649182241');
            mapValue.put('autreTelephone', '');
            mapValue.put('fax', '0000000009');
            mapValue.put('canalPrefere', 'FAX');
            mapValue.put('email', 'test@soprasteria.com');
            mapValue.put('optinAdresseEmailKparK', 'true');
            mapValue.put('optinAdresseEmailPartenaire', 'true');
            mapValue.put('optinSMSKparK', 'true');
            mapValue.put('optinSMSPartenaire', 'true');
            mapValue.put('optinTelephoneDomicileKparK', 'true');
            mapValue.put('optinTelephoneDomicilePartenaire', 'true');
            mapValue.put('optinTelephoneMobileKparK', 'true');
            mapValue.put('optinTelephoneMobilePartenaire', 'true');
            mapValue.put('localisationLatitude', '44.05');
            mapValue.put('localisationLongitude', '8.15');
    
            // Modification d'un compte
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
    
            // Force erreur
            KubeException exc = new KubeException();
            Ctrl_Site_EspaceClient.sendEmailErreurModificationAccount(mapValue, accountRequest.AccountNumber, exc);
            
            Test.stopTest();
        }

        /*List<Account> accounts = [SELECT FirstName, etage__c, rue__c, PersonEmail FROM Account WHERE Id = :accountRequest.Id];
        Account updatedAccount = accounts.isEmpty() ? null : accounts.get(0);
        System.assertNotEquals(null, updatedAccount);
        System.assertEquals(mapValue.get('prenom'), updatedAccount.FirstName);
        System.assertEquals(mapValue.get('email'), updatedAccount.PersonEmail);
        System.assertEquals(mapValue.get('rue'), updatedAccount.rue__c);
        System.assertEquals(mapValue.get('etage'), updatedAccount.etage__c.format());
    
        // Modification de compte professionel
        ctrl.account.IsPersonAccount = false;
        ctrl.account.rue = '5 rue des sauriès';
        ctrl.account.ville = 'Eguilles';
        ctrl.account.codePostal = '13510';
        ctrl.account.complementAdresse = 'blablabla';
        ctrl.account.etage = 12;
        ctrl.account.interphone = '1234A';
        ctrl.account.telephoneDomicile = '0464777899';
        ctrl.account.telephoneMobile = '0649182241';
        ctrl.account.autreTelephone = '';
        ctrl.account.Fax = '0000000009';
        ctrl.account.canalPrefere = 'FAX';
        ctrl.account.email = 'leslie.martinez@sopra.com';
        ctrl.account.optinAdresseEmailKparK = true;
        ctrl.account.optinAdresseEmailPartenaire = true;
        ctrl.account.optinSMSKparK = true;
        ctrl.account.optinSMSPartenaire = true;
        ctrl.account.optinTelephoneDomicileKparK = true;
        ctrl.account.optinTelephoneDomicilePartenaire = true;
        ctrl.account.optinTelephoneMobileKparK = true;
        ctrl.account.optinTelephoneMobilePartenaire = true;

        ctrl.updateAccountInformations();

        Contact contact = new Contact();
        contact.LastName = 'blabla';
        contact.Email = 'blabla@blabla.fr';

        insert contact;

        Contact contactRequest = [SELECT Id FROM Contact WHERE Email =: contact.Email LIMIT 1];

        ctrl.account.contactParDefautId = contactRequest.Id;

        ctrl.updateAccountInformations();
		*/
    }
    
    @isTest 
    static void test_Espace_Client_UpdateAccount_KO() {        
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        
        // Connexion
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = '1aB%cdef';
        Pagereference edit = ctrl.login();        
        
        // Initialisation map des valeurs à modifier
        Map<String, String> mapValue = new Map<String, String>();
        // Modification de compte personnel
        mapValue.put('civilite', 'Mme');
        mapValue.put('prenom', 'Test');
        mapValue.put('nom', 'test');
        mapValue.put('rue', '5 rue des sauriès');
        mapValue.put('ville', 'Eguilles');
        mapValue.put('codePostal', '13510');
        mapValue.put('complementAdresse', 'blablabla');
        mapValue.put('etage', '12');
        mapValue.put('interphone', '1234A');
        mapValue.put('telephoneDomicile', '0464777899');
        mapValue.put('telephoneMobile', '0649182241');
        mapValue.put('autreTelephone', '');
        mapValue.put('fax', '0000000009');
        mapValue.put('canalPrefere', 'FAX');
        mapValue.put('email', 'test@soprasteria.com');
        mapValue.put('optinAdresseEmailKparK', 'true');
        mapValue.put('optinAdresseEmailPartenaire', 'true');
        mapValue.put('optinSMSKparK', 'true');
        mapValue.put('optinSMSPartenaire', 'true');
        mapValue.put('optinTelephoneDomicileKparK', 'true');
        mapValue.put('optinTelephoneDomicilePartenaire', 'true');
        mapValue.put('optinTelephoneMobileKparK', 'true');
        mapValue.put('optinTelephoneMobilePartenaire', 'true');
        mapValue.put('localisationLatitude', '44.05');
        mapValue.put('localisationLongitude', '8.15');

        Test.startTest();
        
        // Nom incorrect        
        try {
            mapValue.put('nom', '');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        try {
            mapValue.put('nom', 'dzzdz@zdzjk');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('nom', 'test');
        // Prenom incorrect     
        try {
            mapValue.put('prenom', '');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        try {
            mapValue.put('prenom', 'zdzd@zdz');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('prenom', 'Test');        
        // Code Postal incorrect        
        try {
            mapValue.put('codePostal', '');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        try {
            mapValue.put('codePostal', 'zdezeu');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('codePostal', '13510');
        // Ville incorrect      
        try {
            mapValue.put('ville', '');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('ville', 'Eguilles');
        // Email incorrect      
        try {
            mapValue.put('email', 'tessoprasteria.com');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('email', 'test@soprasteria.com');        
        // Téléphone incorrect      
        try {
            mapValue.put('telephoneDomicile', 'test');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        mapValue.put('telephoneDomicile', '0000000009');            
        try {
            mapValue.put('telephoneMobile', 'test');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }        
        mapValue.put('telephoneMobile', '0000000009');      
        try {
            mapValue.put('telephoneProfessionnel', 'test');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }        
        mapValue.put('telephoneProfessionnel', '0000000009');
        try {
            mapValue.put('fax', 'test');
            Ctrl_Site_EspaceClient.updateAccount(accountRequest.Id, accountRequest.AccountNumber, mapValue);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }        
        mapValue.put('fax', '0000000009');       
        
        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_OK() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'newPwd123';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertEquals(null, response, 'return should be null when success');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must be changed'); 
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_noDigit() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'newPwd';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_tooShort() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'nP1';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_tooLong() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'newPassword123456789';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_noUpperCase() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'newpwd123';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_noLowerCase() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'NEWPWD123';
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_different() {
        String oldPwd = '1aB%cdef';
        String newPwd = 'newPwd123';
        String newPwd2 = newPwd + '%';

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertNotEquals(Ctrl_Site_EspaceClient.encodePassword(newPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_requestNewPassword_oldEqualsNew() {
        String oldPwd = '1aB%cdef';
        String newPwd = oldPwd;
        String newPwd2 = newPwd;

        Id accountId = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].Id;

        Test.startTest();
        String response = Ctrl_Site_EspaceClient.requestNewPassword(accountId, oldPwd, newPwd, newPwd2);
        Test.stopTest();

        System.assertNotEquals(null, response, 'return should contain an error message');
        String actualPwd = [SELECT Id, motDePasseClient__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1].motDePasseClient__c;
        System.assertEquals(Ctrl_Site_EspaceClient.encodePassword(oldPwd), actualPwd, 'password must not be changed');
    }

    @isTest 
    static void test_Espace_Client_booleanToString() {
        Test.startTest();
        System.assertEquals('Oui', Ctrl_Site_EspaceClient.booleanToString(true));
        System.assertEquals('Non', Ctrl_Site_EspaceClient.booleanToString(false));
        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_CreationDemande_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
        
        Test.startTest();

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        
        Test.stopTest();
        
        // Vérification création demande
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];
        system.assertNotEquals(null, caseDemande.Id);
    }
    
    @isTest 
    static void test_Espace_Client_CreationDemande_KO() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
        String errMsg = null;

        Test.startTest();
        
        // Création demande (description vide)
        try {
            Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', '');
        } catch (KubeException e) {
            errMsg = e.getMessage();
        }
        System.assertNotEquals(null, errMsg); //passe s'il y a eu une exception
        errMsg = null;

        // Création demande (type vide)
        try {
            Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, '', '', 'Commercial', 'Test');
        } catch (KubeException e) {
            errMsg = e.getMessage();
        }
        System.assertNotEquals(null, errMsg); //passe s'il y a eu une exception
        Test.stopTest();
    }
    
    @isTest 
    static void test_Espace_Client_CreationDemande_WithFile_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
        // Enregistrement ID des comptes pour test SOSL
        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(accountRequest.Id);
        Test.setFixedSearchResults(fixedSearchResults);
        
        //Connexion
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = '1aB%cdef';
        ctrl.login();
        ctrl.checkAllowedAccess();
                
        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];
        
        Test.startTest();
        
        // Transfert de fichier
        Ctrl_Site_EspaceClient.transfertFichier(caseDemande.Id, null, 'aaaaaaaaaaaaaa', 'Test FileName', 'image/jpeg');
        Attachment att = [SELECT Id FROM Attachment WHERE Name =: 'Test FileName' LIMIT 1];
        Ctrl_Site_EspaceClient.transfertFichier(caseDemande.Id, att.Id, 'aaaaaaaaaaaaaa', 'Test FileName', 'image/jpeg');

        // Récupération pièce jointe        
        pa.getParameters().put('caseId', caseDemande.Id);
        List<Ctrl_Site_EspaceClient.PieceJointe> pj = ctrl.caseAttachmentToDisplay;
        
        Test.stopTest();
        
        // Vérification pièce jointe
        att = [SELECT Id, parentId FROM Attachment WHERE Name =: 'Test FileName' LIMIT 1];
        system.assertNotEquals(null, att.Id);
        system.assertEquals(caseDemande.Id, att.parentId);
        system.assertNotEquals(null, pj);
    }
    
    @isTest 
    static void test_Espace_Client_CreationDemande_WithFile_KO() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
                
        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];
        
        Test.startTest();
        
        // Transfert de fichier (Pas de caseId)
        try {
            Ctrl_Site_EspaceClient.transfertFichier(null, null, 'aaaaaaaaaaaaaa', 'Test FileName', 'image/jpeg');
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }  
        // Transfert de fichier (Pas de body)
        try {
            Ctrl_Site_EspaceClient.transfertFichier(caseDemande.Id, null, null, 'Test FileName', 'image/jpeg');
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }  
        // Transfert de fichier (Mauvais ContentType)
        try {
            Ctrl_Site_EspaceClient.transfertFichier(caseDemande.Id, null, 'aaaaaaaaaaaaaa', 'Test FileName', 'file/pdf');
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        } 
        
        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_postComment_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];

        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        Test.startTest();
        Ctrl_Site_EspaceClient.postComment(caseDemande.Id, 'test comment from test_Espace_Client_postComment_OK');
        Test.stopTest();

        List<CaseComment> comments = [SELECT Id, IsPublished FROM CaseComment WHERE ParentId = :caseDemande.Id AND CommentBody = 'test comment from test_Espace_Client_postComment_OK'];
        System.assertEquals(1, comments.size(), 'Le commentaire n\'a pas été trouvé ou a été posté plusieurs fois.');
        System.assertEquals(true, comments[0].IsPublished, 'Le commentaire est privé.');
    }

    @isTest 
    static void test_Espace_Client_postComment_empty() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];

        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        Test.startTest();
        //Ctrl_Site_EspaceClient.postComment(caseDemande.Id, '');
        Test.stopTest();

        List<CaseComment> comments = [SELECT Id FROM CaseComment WHERE ParentId = :caseDemande.Id AND CommentBody = 'test comment from test_Espace_Client_postComment_OK'];
        System.assertEquals(0, comments.size(), 'Le commentaire vide a été posté.');
    }

    @isTest 
    static void test_Espace_Client_postComment_withoutCase() {
        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        Exception testEx = null;
        Test.startTest();
        try {
            Ctrl_Site_EspaceClient.postComment(null, 'test comment');
        } catch(Exception e) {
            testEx = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, testEx, 'Aucune exception lancée.');
    }

    @isTest 
    static void test_Espace_Client_retrieveComment_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
        
        Test.startTest(); //trick pour raz les limites SOQL (sinon l'insertion des commentaires fait dépasser la limite de 100)

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test1');
        //Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test2');
        List<Case> demandes = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id];
        List<CaseComment> commentList = new List<CaseComment>();
        //Création commentaires
        CaseComment comment1 = new CaseComment();
        comment1.CommentBody = 'comment1';
        comment1.ParentId = demandes[0].Id;
        comment1.IsPublished = true;
        CaseComment comment2 = new CaseComment();
        comment2.CommentBody = 'comment2';
        comment2.ParentId = demandes[0].Id;
        comment2.IsPublished = false;
        CaseComment comment3 = new CaseComment();
        comment3.CommentBody = 'comment3';
        comment3.ParentId = demandes[0].Id;
        comment3.IsPublished = true;
        CaseComment comment4 = new CaseComment();
        comment4.CommentBody = 'comment4';
        comment4.ParentId = demandes[0].Id;
        comment4.IsPublished = true;
        commentList.add(comment1);
        commentList.add(comment2);
        commentList.add(comment3);
        commentList.add(comment4);
        insert commentList;

        //Test
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        List<Ctrl_Site_EspaceClient.Commentaire> results = ctrl.retrieveComments(demandes[0].Id);
        Test.stopTest();

        /*System.assertEquals(2, results.size(), 'Les commentaires récupérés ne sont pas les bons.');
        for(Integer i = 0 ; i < results.size() ; i++)
        {
            System.assertNotEquals('comment2', results[i].texte, 'Un commentaire privé a été récupéré.');
            System.assertNotEquals('comment4', results[i].texte, 'Un commentaire appartenant à une autre requête a été récupéré');
        }*/
    }

    @isTest 
    static void test_Espace_Client_retrieveComment_noComment() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];
        
        Test.startTest(); //trick pour raz les limites SOQL (sinon l'insertion des commentaires fait dépasser la limite de 100)

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test1');
        //Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test2');
        List<Case> demandes = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id];

        //Création commentaires
        List<CaseComment> caseCommentList = new List<CaseComment>();
        CaseComment comment1 = new CaseComment();
        comment1.CommentBody = 'comment1';
        comment1.ParentId = demandes[0].Id;
        comment1.IsPublished = true;
        CaseComment comment3 = new CaseComment();
        comment3.CommentBody = 'comment3';
        comment3.ParentId = demandes[0].Id;
        comment3.IsPublished = true;
        caseCommentList.add(comment1);
        caseCommentList.add(comment3);
        insert caseCommentList;
        //Test
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        List<Ctrl_Site_EspaceClient.Commentaire> results = ctrl.retrieveComments(demandes[0].Id);
        Test.stopTest();

        //System.assertEquals(0, results.size(), 'Des commentaires appartenant à la mauvaise requête ont été récupérés.');
    }

    @isTest 
    static void test_Espace_Client_cloreDemande_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];

        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        Test.startTest();
        Ctrl_Site_EspaceClient.cloreDemande(caseDemande.Id, '');
        Test.stopTest();

        Case caseTest = [SELECT Id, Status FROM Case WHERE Id = :caseDemande.Id];
        System.assertEquals(Constants.REQUETE_STATUS_CLOSED, caseTest.Status, 'Le statut de la demande n\'a pas été mis à jour.');
    }

    @isTest 
    static void test_Espace_Client_cloreDemande_OK_withComment() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];

        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        controller.getTypeDemande();
        controller.getMotifOptions();
        
        Test.startTest();
        Ctrl_Site_EspaceClient.cloreDemande(caseDemande.Id, 'test cloreDemande');
        Test.stopTest();

        Case caseTest = [SELECT Id, Status FROM Case WHERE Id = :caseDemande.Id];
        System.assertEquals(Constants.REQUETE_STATUS_CLOSED, caseTest.Status, 'Le statut de la demande n\'a pas été mis à jour.');
        CaseComment comTest = [SELECT Id, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :caseTest.Id LIMIT 1];
        System.assertNotEquals(null, comTest, 'Le commentaire n\'a pas été inséré (ou a été associé à la mauvaise requête).');
        System.assertEquals('test cloreDemande', comTest.CommentBody, 'Le contenu du commentaire n\'est pas le bon.');
        System.assertEquals(true, comTest.IsPublished, 'Le commentaire est privé.');
    }

    @isTest 
    static void test_Espace_Client_rouvrirDemande_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];


        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber, Status FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];
        
        Test.startTest();

        caseDemande.Status = Constants.REQUETE_STATUS_CLOSED;
        update caseDemande;       

        //Initialisation du contrôleur
        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        Ctrl_Site_EspaceClient.rouvrirDemande(caseDemande.Id, 'test rouvrirDemande');
        Test.stopTest();

        /*Case caseTest = [SELECT Id, Status FROM Case WHERE Id = :caseDemande.Id];
        System.assertNotEquals(Constants.REQUETE_STATUS_CLOSED, caseTest.Status, 'Le statut de la demande n\'a pas été mis à jour.');
        CaseComment comTest = [SELECT Id, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :caseTest.Id LIMIT 1];
        System.assertNotEquals(null, comTest, 'Le commentaire n\'a pas été inséré (ou a été associé à la mauvaise requête).');
        System.assertEquals('test rouvrirDemande', comTest.CommentBody, 'Le contenu du commentaire n\'est pas le bon.');
        System.assertEquals(true, comTest.IsPublished, 'Le commentaire est privé.');*/
    }

    @isTest 
    static void test_Espace_Client_rouvrirDemande_withoutComment() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        Chantier__c chantierRequest = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier 1' LIMIT 1];

        Test.startTest();

        // Création demande
        Ctrl_Site_EspaceClient.creationDemande(accountRequest.Id, chantierRequest.Id, 'Nouveau rendez-vous', null, 'Commercial', 'Test');
        Case caseDemande = [SELECT Id, CaseNumber, Status FROM Case WHERE AccountId =: accountRequest.Id LIMIT 1];
        caseDemande.Status = Constants.REQUETE_STATUS_CLOSED;
        update caseDemande;

        //Initialisation du contrôleur
        Ctrl_Site_EspaceClient controller = new Ctrl_Site_EspaceClient();
        controller.demandeToDisplay = new Ctrl_Site_Espaceclient.Demande();
        
        //Ctrl_Site_EspaceClient.rouvrirDemande(caseDemande.Id, '');
        Test.stopTest();

        Case caseTest = [SELECT Id, Status FROM Case WHERE Id = :caseDemande.Id];
        System.assertEquals(Constants.REQUETE_STATUS_CLOSED, caseTest.Status, 'La demande a été rouverte sans commentaire.');
    }
    
    @isTest 
    static void test_Espace_Client_CreationDemande_Callback_OK() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        
        Test.startTest();
        
        // Callback
        try {
            Ctrl_Site_EspaceClient.sendNotifyTelCallBack('0123456789', accountRequest.Id);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void test_Espace_Client_CreationDemande_Callback_KO() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        
        Test.startTest();
        
        // Callback (Mauvais tel)
        try {
            Ctrl_Site_EspaceClient.sendNotifyTelCallBack('azaz', accountRequest.Id);
        } catch (KubeException e) {
            system.assertNotEquals(null, e.getMessage());
        }
        
        Test.stopTest();
    }

    
    @isTest 
    static void test_Espace_Client_CreationFilleul_OK() {
        Account accountRequest = [SELECT Id, AccountNumber,nom__c,prenom__c,Type,dateAssociationParrain__c,dateEnvoiDotationParrain__c,CreatedDate FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        
        Test.startTest();
        
        String result = Ctrl_Site_EspaceClient.creationFilleul('Filleul', 'Filleul', '1 rue test', '74001', 'PARIS', 'IDF', 'FR', 'test@test.filleul', 
                                                    '0123456789', Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_ELECTRONIQUE, '0.0', '0.0', accountRequest.AccountNumber);
        system.assertNotEquals(null, result);
        System.debug('account created Date :'+accountRequest.CreatedDate);
        Ctrl_Site_EspaceClient.Filleul filleul = new Ctrl_Site_EspaceClient.Filleul(accountRequest);

        //Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();
        
        
        Test.stopTest();
    }
    
    @isTest 
    static void test_Espace_Client_CreationFilleul_KO() {
        Account accountRequest = [SELECT Id, AccountNumber FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        
        Test.startTest();
        
        // Type de dotation requiert un email
        try {
            Ctrl_Site_EspaceClient.creationFilleul('Filleul', 'Filleul', '1 rue test', '74001', 'PARIS', 'IDF', 'FR', '', 
                                                    '0123456789', Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_ELECTRONIQUE, '0.0', '0.0', accountRequest.AccountNumber);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }

        // Pas de nom
        try {
            Ctrl_Site_EspaceClient.creationFilleul('', 'Filleul', '1 rue test', '74001', 'PARIS', 'IDF', 'FR', 'test@test.filleul', 
                                                    '0000', Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER, '0.0', '0.0', accountRequest.AccountNumber);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }

        // Pas de prénom
        try {
            Ctrl_Site_EspaceClient.creationFilleul('Filleul', '', '1 rue test', '74001', 'PARIS', 'IDF', 'FR', 'test@test.filleul', 
                                                    '0000', Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER, '0.0', '0.0', accountRequest.AccountNumber);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        
        // Pas de moyen de joignabilité
        try {
            Ctrl_Site_EspaceClient.creationFilleul('Filleul', '', '1 rue test', '74001', 'PARIS', 'IDF', 'FR', '', 
                                                    '', Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER, '0.0', '0.0', accountRequest.AccountNumber);
        } catch (Exception e) {
            system.assertNotEquals(null, e.getMessage());
        }
        
        Test.stopTest();
    }

    @isTest 
    static void test_Espace_Client_EmailErreur() {
        Account accountRequest = [SELECT Id, AccountNumber, civilite__c, nom__c, prenom__c FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];

        // Création des données
        KubeException ex = new KubeException('Test');
        Map<String, String> mapValue = new Map<String, String>();
        mapValue.put('civilite', accountRequest.civilite__c);
        mapValue.put('nom', accountRequest.nom__c);
        mapValue.put('prenom', accountRequest.prenom__c);

        // Envoi de l'email
        Ctrl_Site_EspaceClient.sendEmailErreurModificationAccount(mapValue, accountRequest.AccountNumber, ex);
    }

    @isTest 
    static void test_Espace_Client_ExportData() {
        Account accountRequest = [SELECT Id, AccountNumber, AccountSource, accountCallSource__c, Type FROM Account WHERE PersonEmail = 'testespaceclient@salesforce.com' LIMIT 1];
        // Création
        Ctrl_GDPR_AdminExportDeDonnees.createCustomMetadata('Account', 'Contact', 1, true, 'Id', 'AccountId');
        
        PageReference pa = Page.VF_Site_EspaceClient;
        Test.setCurrentPage(pa);
        Ctrl_Site_EspaceClient ctrl = new Ctrl_Site_EspaceClient();

        //ctrl.account = new Ctrl_Site_EspaceClient.Compte(ctrl.accountInitial);
        
        // Connexion
        ctrl.user = accountRequest.AccountNumber;
        ctrl.password = '1aB%cdef';
        Pagereference edit = ctrl.checkAccountLogin(accountRequest.AccountNumber, '1aB%cdef', true);

        System.debug('accountRequest.Type : '+accountRequest.Type);
        System.debug('ctrl.accountInitial : '+ctrl.accountInitial);
        System.debug('ctrl.account : '+ctrl.account);

        Test.startTest();

        // Export des données
        String JSONexport = '';
        JSONexport = Ctrl_Site_EspaceClient.jsonExportDonnees(accountRequest.Id);
        
        Test.stopTest();
    }
}