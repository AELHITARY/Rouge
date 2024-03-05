//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_AccountAndChantier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 28/02/2023
//-- Version     : 1.1
//-- * 1.1 : CRM-956 : Test sur création et affectation des autorisations (Jalon)
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_AccountAndChantier {
    private static final Id accProRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Sectorisation__c defaultSectorisation = TestCommon.createSectorisation();

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
    static void setup() {
        TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
    }   
    
    @isTest 
    static void test_accountAndChantier() {
        // Création d'un utilisateur
        User user = TestCommon.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null);
        user.codeMagasin__c = 'MAG0021';
        user.libelleMagasin__c = 'LEVALLOIS';
        user.codeDV__c = 'DV0064';
        user.libelleDV__c = 'PARIS';
        user.codeDR__c = 'RV0018';
        user.libelleDR__c = 'NORD';
        update user;

        System.runAs(user) {
            List<Account> accountsToInsert = new List<Account>();

            Account B2B = createAccountB2B();

            Account B2C = createAccountB2C();

            Account B2C2 = createAccountB2C();
            B2C2.lastName += '2';
            B2C2.firstName += '2';
            B2C2.personHomePhone = B2C2.personMobilePhone;
            B2C2.personMobilePhone = null;

            Account B2C3 = createAccountB2C();
            B2C3.lastName += '3';
            B2C3.firstName += '3';
            B2C3.personMobilePhone = B2C3.personHomePhone;
            B2C3.personHomePhone = null;

            Account B2C4 = createAccountB2C();
            B2C4.lastName += '4';
            B2C4.firstName += '4';
            String phone = B2C4.personHomePhone;
            B2C4.personHomePhone = B2C4.personMobilePhone;
            B2C4.personMobilePhone = phone;
            B2C4.personEmail = null;

            Account B2C5 = createAccountB2C();
            B2C5.lastName += '5';
            B2C5.firstName += '5';
            B2C5.personMailingCountry = 'ALLEMAGNE';
            B2C5.fichiersOpposition__c = 'CNIL';
            B2C5.forcageType__c = 'Client';
            B2C5.accountSource = 'JPO';
            B2C5.personHomePhone = '+44' + account.personHomePhone;
            B2C5.personMobilePhone = '+44' + account.personMobilePhone;
            B2C5.personOtherPhone = '+44' + account.personOtherPhone;
            B2C5.phone = '+44' + account.phone;
            B2C5.fax = '+44' + account.fax;

            accountsToInsert.add(B2B);
            accountsToInsert.add(B2C);
            accountsToInsert.add(B2C2);
            accountsToInsert.add(B2C3);
            accountsToInsert.add(B2C4);
            accountsToInsert.add(B2C5);

            insert accountsToInsert;

            List<Chantier__c> chantiersToInsert = new List<Chantier__c>();
            Chantier__c CHA1 = createChantier(B2B, B2C, B2C2, B2C3, B2C4, B2C5);
            Chantier__c CHA2 = createChantier(B2B, B2B, B2B, B2B, B2B, B2B);
            Chantier__c CHA3 = createChantier(B2C, null, null, null, null, null);
            Chantier__c CHA4 = createChantier(null, B2C, null, B2C3, null, B2C5);

            chantiersToInsert.add(CHA1);
            chantiersToInsert.add(CHA2);
            chantiersToInsert.add(CHA3);
            chantiersToInsert.add(CHA4);

            insert chantiersToInsert;

            Contact cttB2B = createContactB2B(B2B);
            insert cttB2B;

            Test.startTest();

            B2B.name += '_BIS';
            update B2B;

            B2C5.fichiersOpposition__c = null;
            B2C5.firstName += '_BIS';
            B2C5.lastName += '_BIS';
            B2C5.personHomePhone = B2C4.personHomePhone;
            B2C5.personMobilePhone = B2C4.personMobilePhone;
            B2C5.personOtherPhone = B2C4.personOtherPhone;
            B2C5.phone = B2C4.phone;
            B2C5.fax = B2C4.fax;
            B2C5.personEmail = 'bc25@laposte.net';
            update B2C5;

            //Map<Id, Account> accounts = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accountsToInsert)));
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, firstName, lastName, personEmail, fichiersOpposition__c, salutation, accountCallSource__c, personMailingStreet,
                                                                personMailingPostalCode, personMailingCity, personMailingCountry, forcageType__c, accountSource, personHomePhone, personMobilePhone,
                                                                personOtherPhone, phone, fax, x__c, y__c, Localisation__Latitude__s, Localisation__Longitude__s, sectorisation__c, iris__c, RecordTypeId
                                                                FROM Account WHERE Id IN :accountsToInsert]);
            B2B = accounts.get(B2B.id);
            B2C = accounts.get(B2C.id);
            B2C2 = accounts.get(B2C2.id);
            B2C3 = accounts.get(B2C3.id);
            B2C4 = accounts.get(B2C4.id);
            B2C5 = accounts.get(B2C5.id);

            Account B2B2 = B2B.clone(false, true);
            B2B2.Name = B2B2.firstName + ' ' + B2B2.lastName;
            Account B2C6 = B2C2.clone(false, true);
            Account B2C7 = B2C3.clone(false, true);
            Account B2C8 = B2C4.clone(false, true);
            Account B2C9 = B2C5.clone(false, true);
            Account B2C10 = B2C5.clone(false, true);
            accountsToInsert.clear();
            accountsToInsert.add(B2B2);
            accountsToInsert.add(B2C6);
            accountsToInsert.add(B2C7);
            accountsToInsert.add(B2C8);
            accountsToInsert.add(B2C9);
            accountsToInsert.add(B2C10);
            insert accountsToInsert;

            cttB2B.homePhone   = '0111111111';
            cttB2B.mobilePhone = '0666666666';
            cttB2B.otherPhone  = '0222222222';
            cttB2B.phone       = '0333333333';
            cttB2B.email       = 'nom.prenom@kpark.fr';

            update cttB2B;

            CHA1.proprietaire__c = B2B2.id;
            CHA1.autreProprietaire__c = B2C6.id;
            CHA1.locataire__c = B2C7.id;
            CHA1.autreLocataire__c = B2C8.id;
            CHA1.occupant__c = B2C9.id;
            CHA1.autreOccupant__c = B2C10.id;
            update CHA1;

            Chantier__c CHA5 = CHA1.clone(false, true);
            CHA5.Name =+ '2';
            insert CHA5;
            delete CHA5;

            delete B2C5;

            Test.stoptest();
        }
    }

    @isTest 
    static void test_deleteAccountContact() {
        // Création d'un utilisateur
        User user = TestCommon.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null);
        user.codeMagasin__c = 'MAG0021';
        user.libelleMagasin__c = 'LEVALLOIS';
        user.codeDV__c = 'DV0064';
        user.libelleDV__c = 'PARIS';
        user.codeDR__c = 'RV0018';
        user.libelleDR__c = 'NORD';
        update user;

        System.runAs(user) {
            List<Account> accountsToInsert = new List<Account>();

            Account B2B = createAccountB2B();
            insert B2B;
            Contact contact = Utils_Test.createContact('Test','Test',true);

            Test.startTest();

            B2B.contactParDefaut__c = contact.Id;
            update B2B;

            delete contact;
            delete B2B;

            Test.stopTest();
        }
    }
    
    @isTest 
    static void test_emailParrain() {
        // Création d'un utilisateur
        User user = TestCommon.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null);
        user.codeMagasin__c = 'MAG0021';
        user.libelleMagasin__c = 'LEVALLOIS';
        user.codeDV__c = 'DV0064';
        user.libelleDV__c = 'PARIS';
        user.codeDR__c = 'RV0018';
        user.libelleDR__c = 'NORD';
        update user;

        System.runAs(user) {
            List<Account> accountsToInsert = new List<Account>();

            // Création compte
            Account parrain = createAccountB2C();
            parrain.Type = 'Client';
            parrain.forcageType__c = 'Client';

            Account filleul = createAccountB2C();
            filleul.PersonLeadSource = 'PARRAINAGE VENDEUR';
            filleul.lastName += 'testfilleul';
            filleul.firstName += 'testfilleul';
            filleul.personHomePhone = filleul.personMobilePhone;
            filleul.personMobilePhone = null;

            accountsToInsert.add(parrain);
            accountsToInsert.add(filleul);
            insert accountsToInsert;

            Test.startTest();

            // TEST - Ajout du parrain au filleul
            filleul.parrain__c = parrain.id;
            update filleul;
            System.assertEquals(parrain.email__c, filleul.emailParrain__c);
           
            // TEST - Modif email parrain et donc email parrain des filleuls
            parrain.PersonEmail = 'test2@kpark.fr';
            update parrain;

            System.assertEquals(parrain.email__c, filleul.emailParrain__c);            

            Test.stoptest();
        }
    }  

    @isTest 
    static void test_chantier() {
        // Création d'un utilisateur
        User user = TestCommon.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null);
        user.codeMagasin__c = 'MAG0021';
        user.libelleMagasin__c = 'LEVALLOIS';
        user.codeDV__c = 'DV0064';
        user.libelleDV__c = 'PARIS';
        user.codeDR__c = 'RV0018';
        user.libelleDR__c = 'NORD';
        update user;

        System.runAs(user) {

            // Création compte
            Account acc = createAccountB2C();
            insert acc;
            Chantier__c chantier = createChantier(acc, null, null, null, null, null);
            insert chantier;
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier, true);
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            KContrat__c con = Utils_Test.createContrat('Contrat 1', chantier.Id, acc.Id, '12345', true);

            Test.startTest();

            chantier.localisation__longitude__s = 1.099136000000044;
            chantier.localisation__latitude__s = 49.4413062;
            chantier.nbDevisAConfigurer__c  = 1;
            update chantier;

            Test.stoptest();
        }
    }
    
    @isTest 
    static void test_notifyTelCallback() {
        // Création d'un utilisateur
        User user = TestCommon.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null);
        user.codeMagasin__c = 'MAG0021';
        user.libelleMagasin__c = 'LEVALLOIS';
        user.codeDV__c = 'DV0064';
        user.libelleDV__c = 'PARIS';
        user.codeDR__c = 'RV0018';
        user.libelleDR__c = 'NORD';
        update user;

        System.runAs(user) {
            List<Account> accountsToInsert = new List<Account>();

            Test.startTest();

            Account B2C = createAccountB2C();
            insert B2C;
            B2C.accountCallSource__c = '44 - Formulaire site KparK';
            B2C.Phone = '0123456789';
            update B2C;

            TR024_Account.notifyCallBack(B2C);
            TR024_Account.syncSaveCallback(B2C);
            TR024_Account.asyncSaveCallBack(B2C.Id);

            Test.stoptest();
        }
    }
    
    @isTest 
    static void test_updateAsset(){
        Asset asset1 = new Asset(Name='assetTest1');
        Asset asset2 = new Asset(Name='assetTest1');
        
        Account ac1 = createAccountB2B();
        insert ac1;
        Account ac2 = createAccountB2B();
        insert ac2;
        
        Chantier__c chant1 = createChantier(ac1, null, null, null, null, null);
        insert chant1;
        
        asset1.chantier__c = chant1.Id;
        asset2.chantier__c = chant1.Id;
        
        Contact contact1 = new Contact(LastName = 'nomContact1',Firstname = 'prenomContact1');
        contact1.AccountId = ac1.Id;
        insert contact1;
		Contact contact2 = new Contact(LastName = 'nomContact2',Firstname = 'prenomContact2');
        contact2.AccountId =ac2.Id;
        insert contact2;
        
        asset1.ContactId = contact1.Id;
        asset2.ContactId = contact1.Id;
       
        insert asset1;
        insert asset2;
        
        upsert contact2;   
        
        Test.startTest();      

        chant1.proprietaire__c = ac2.Id;
        upsert chant1;
        
        Test.stopTest();
    }

    @isTest 
    static void test_EntityCreateObjects() {
        User uCurrentForecastUser = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        Id rtEntityTypeId = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
        Id rtAccEntityId = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_ENTITY_RT);

        //Group queue = createGroup('','','',true)

        System.runAs(uCurrentForecastUser){
            Test.startTest();
            Referencial__c typeEntity = new Referencial__c(Name = 'TestRef', RecordTypeId = rtEntityTypeId, queue__c = true, chatterGroup__c = true, publicGroup__c = true, KparKReference__c = '1', serviceTerritory__c = true);
            insert typeEntity;
            OperatingHours opHours = new OperatingHours(Name = 'Par Défaut'/*, fsl_dateOuverture__c = date.today()*/);
            insert opHours;
            Account entity = new Account(Name = 'TestEnt', entityType__c = typeEntity.Id, KparKReference__c = '1', startDate__c = date.today(), RecordTypeId = rtAccEntityId);
            /*entity.queueId__c = 
            entity.approvalQueueId__c
            entity.chatterGroupId__c
            entity.publicGroupId__c
            entity.serviceTerritory__c*/
            insert entity;

            //test delete
            delete entity;
            Test.stopTest();
        }
    }

    @isTest 
    static void test_QA_DQEAccountChantier_formatError(){

        Test.startTest();
        Account B2C = createAccountB2C();
        insert B2C;

        Chantier__c CHA = createChantier(B2C, null, null, null, null, null);

        HttpResponse response = new HttpResponse();
        response.setBody('TEST');
        response.setStatusCode(200);
        QA_DQEAccount.formatError('Test message d\'erreur.', 'http://urltest.com', response, B2C);
        QA_DQEChantier.formatError('Test message d\'erreur.', 'http://urltest.com', response, CHA);

        Test.stopTest();
    }

    private static Account createAccountB2B() {
        Account account = new Account(recordTypeId = accProRecordType);

        account.name = 'Compte professionnel';
        account.accountCallSource__c = '15 - Campagne Marketing';
        account.billingStreet = '1200 rue félix faure';
        account.billingPostalCode = '76320';
        account.billingCity = 'Caudebec les Elbeuf';
        account.billingCountry = 'F';
        account.phone = '010203ADGJ';
        account.fax = '010204MPTW';

        account.x__c = 0;
        account.y__c = 0;
        account.Localisation__Latitude__s = 0;
        account.Localisation__Longitude__s = 0;
        account.iris__c = defaultSectorisation.iris__c;

        System.assertNotEquals(null, account.iris__c);

        return account;
    }

    private static Contact createContactB2B(Account account) {
        Contact contact = new Contact(accountId = account.id);

        contact.firstName   = 'prenom';
        contact.lastName    = 'nom';

        contact.homePhone   = '0101010101';
        contact.mobilePhone = '0606060606';
        contact.otherPhone  = '0202020202';
        contact.phone       = '0303030303';
        contact.email       = 'prenon.nom@kpark.fr';

        return contact;
    }

    private static Account createAccountB2C() {
        Account account = new Account(recordTypeId = accPersoRecordType);

        account.salutation = 'M.';
        account.lastName = 'Nom';
        account.firstName = 'Prénom';
        account.accountCallSource__c = '17 - JPO';
        account.personMailingStreet = '1 rue félix faure';
        account.personMailingPostalCode = '76320';
        account.personMailingCity = 'Saint-Pierre les Elbeuf';
        account.personMailingCountry = 'F';
        account.personHomePhone = '010203ADGJ';
        account.personMobilePhone = '060203ADGJ';
        account.personOtherPhone = '010204TEST';
        account.phone = '010204MPTW';
        account.fax = '010204MPTW';
        account.personEmail = 'test@kpark.fr';

        account.x__c = 0;
        account.y__c = 0;
        account.Localisation__Latitude__s = 0;
        account.Localisation__Longitude__s = 0;
        account.sectorisation__c = defaultSectorisation.id;
        account.iris__c = defaultSectorisation.iris__c;

        System.assertNotEquals(null, account.iris__c);

        return account;
    }

    private static Chantier__c createChantier(Account proprietaire, Account autreProprietaire, Account locataire, Account autreLocataire, Account occupant, Account autreOccupant) {
        Chantier__c chantier = new Chantier__c();

        chantier.name = 'CHA - Test';

        chantier.rue__c = '1200 rue félix faure';
        chantier.codePostal__c = '76320';
        chantier.ville__c = 'Saint-Pierre les Elbeuf';
        chantier.pays__c = 'F';
        chantier.anneeConstruction__c = '2000';
        chantier.typeHabitation__c = 'Pavillon';
        chantier.typeResidence__c = 'Principale';

        if (proprietaire != null)
            chantier.proprietaire__c = proprietaire.id;
        if (autreProprietaire != null)
            chantier.autreProprietaire__c = autreProprietaire.id;
        if (locataire != null)
            chantier.locataire__c = locataire.id;
        if (autreLocataire != null)
            chantier.autreLocataire__c = autreLocataire.id;
        if (occupant != null)
            chantier.occupant__c = occupant.id;
        if (autreOccupant != null)
            chantier.autreOccupant__c = autreOccupant.id;

        chantier.x__c = 0;
        chantier.y__c = 0;
        chantier.Localisation__Latitude__s = 0;
        chantier.Localisation__Longitude__s = 0;
        chantier.sectorisation__c = defaultSectorisation.id;
        chantier.iris__c = defaultSectorisation.iris__c;

        System.assertNotEquals(null, chantier.iris__c);

        return chantier;
    }
}