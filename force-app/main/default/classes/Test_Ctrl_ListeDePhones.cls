//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_ListeDePhones
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2020
//-- Version     : 1.3
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_ListeDePhones {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id accProRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtRDVProspection = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
    static void setup() {
        Double longitude = 2.3354245000000446;
        Double latitude = 48.8807489;
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        ImportFiles__c impFile = new ImportFiles__c(Name = 'TESTFILE', nomFichierSource__c = 'TESTFILE', dateImportation__c = Date.today());
        insert impFile;
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        
        // Création de comptes
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
        Opportunity opp = Utils_Test.createOpportunity(acc1, chantier, true);
        KContrat__c contrat = Utils_Test.createContrat('Contrat', chantier.Id, acc1.Id, '0001', true);  
        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);   
        // Options produit
        ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,true);
       
        // Création de document LOGO
        Document doc = Utils_Test.createDocument('Logo', Constants.KparK_logo_NB, true);
    }

    @isTest 
    public static void test_Search() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.RunAs(userTest) {
            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_ListeDePhones;
            Test.setCurrentPage(pageRef);
            Ctrl_ListeDePhones ctrlAccount = new Ctrl_ListeDePhones();

            ctrlAccount.insertUserStats();
            ctrlAccount.refreshImportDate();

            Map<String, String> arg = new Map<String, String>();
            List<String> rues = new List<String>();
            arg.put('typeCompte', 'Piste');
            rues.add('Street1');
            rues.add('Street2');
            rues.add('Street3');
            arg.put('ville', 'City123');
            arg.put('cp', '12345');
            arg.put('typeEnregistrement', accPersoRT);
            arg.put('proprietaire', userTest.Email);
            arg.put('proprietaireId', userTest.Id);
            arg.put('dv', '0');
            arg.put('region', 'R123');
            arg.put('magasin', 'M123');
            arg.put('codeP', 'EXEMPLE');
            arg.put('codeO', 'OFEPVC0025');
            arg.put('dernierAppel', '3 mois');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);

            // Cas avec produit n'existant pas
            arg.put('codeO', '');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);

            // Cas normal
            arg.put('codeP', '');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);
            arg.put('codeO', 'OFEPVC0025');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);
            arg.put('codeO', '');
            arg.put('magasin', '1');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);
            arg.put('dv', '1');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);
            arg.put('region', '1');
            Ctrl_ListeDePhones.recupereCompte(arg, rues);

            //Cas ou on ne rempli aucun champ
            Map<String, String> arg2 = new Map<String, String>();
            arg2.put('typeCompte', '');
            arg2.put('ville', 'Ville');
            arg2.put('cp', 'CP');
            arg2.put('typeEnregistrement', accProRT);
            arg2.put('proprietaire', '');
            arg2.put('dv', '');
            arg2.put('region', '');
            arg2.put('magasin', '');
            arg2.put('codeP', '');
            arg2.put('codeO', '');
            arg2.put('ddappel', '');
            arg.put('dernierAppel', '');
            Ctrl_ListeDePhones.recupereCompte(arg2, rues);

            // Chargement des compteurs
            Ctrl_ListeDePhones.getTodayStats();

            //Créer une tache de call
            Account account = [SELECT id, FirstName FROM Account WHERE FirstName = 'Jeanne' LIMIT 1];
            System.assertEquals('jeanne', account.FirstName.toLowerCase());

            Test.stopTest();
        }
    }

    @isTest 
    public static void test_Export() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.RunAs(userTest) {
            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_ListeDePhones;
            Test.setCurrentPage(pageRef);
            Ctrl_ListeDePhones ctrlAccount = new Ctrl_ListeDePhones();

            // Export null
            ctrlAccount.dataExport = null;
            ctrlAccount.exportPDF();
            ctrlAccount.exportCSV();

            // Export
            // Récupération du compte
            List<Account> comptes = [SELECT Id, Name, FirstName, LastName, isPersonAccount,Type, RecordType.Name, LastModifiedDate, LastModifiedBy.Name, rue__c, codePostal__c,  
                                     ville__c, pays__c,Owner.Name, AccountNumber, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, optinTelephoneDomicileKparK__c, 
                                     optinTelephoneMobileKparK__c,nbAppelsSortants__c, nbPhonings__c, dateDernierAppelSortantKparK__c, Localisation__Latitude__s, Localisation__Longitude__s, 
                                     email__c
                                     FROM Account WHERE FirstName = 'Jeanne' ];
            
            List<String> customComptes = new List<String>();
            for(Account compte : comptes) {
                customComptes.add(compte.Id);
            }
            
            ctrlAccount.dataExport = JSON.serialize(customComptes);
            ctrlAccount.exportPDF();
            ctrlAccount.exportCSV();

            // Vérification de la liste export
            List<Account> liste = ctrlAccount.listAccountsExport1;
            for(Account account : liste){
                System.assertEquals('jeanne', account.FirstName.toLowerCase());
            }

            Test.stopTest();
        }
    } 
    
    @isTest 
    public static void test_Create() {
        // Création d'un utilisateur        
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.RunAs(userTest) {
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, codeDV__c, codeRegion__c, codeMagasin__c FROM Sectorisation__c LIMIT 1];
            // Création de compte professionnels
            Account acc3 = Utils_Test.createAccountPro('Test TestTrois','0123456789', accProRT, null,true);
            Account acc4 = Utils_Test.createAccountPro('Test TestQuatre','0123456789', accProRT, null,true);

            // Récupération des comptes personnels
            Account acc1 = [SELECT Id, Name, FirstName, LastName, isPersonAccount,Type, RecordType.Name, LastModifiedDate, LastModifiedBy.Name, rue__c, codePostal__c, ville__c, pays__c,
                            Owner.Name, AccountNumber, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, optinTelephoneDomicileKparK__c, optinTelephoneMobileKparK__c,
                            Localisation__Latitude__s, Localisation__Longitude__s, email__c, x__c, y__c, profession__c,
                            nbAppelsSortants__c, nbPhonings__c, dateDernierAppelSortantKparK__c, nomFichierSource__c FROM Account WHERE firstName = 'Jean' AND LastName = 'Dupont' LIMIT 1];
            Account acc2 = [SELECT Id, Name, FirstName, LastName, isPersonAccount,Type, RecordType.Name, LastModifiedDate, LastModifiedBy.Name, rue__c, codePostal__c, ville__c, pays__c,
                            Owner.Name, AccountNumber, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, optinTelephoneDomicileKparK__c, optinTelephoneMobileKparK__c,
                            Localisation__Latitude__s, Localisation__Longitude__s, email__c, x__c, y__c, profession__c,
                            nbAppelsSortants__c, nbPhonings__c, dateDernierAppelSortantKparK__c, nomFichierSource__c FROM Account WHERE firstName = 'Jeanne' AND LastName = 'Dupont' LIMIT 1];

            Test.startTest();
            
            Map<String, String> arg = new Map<String, String>();
            List<Utils_InnerClasses.CustomCompte> compteSearched = new List<Utils_InnerClasses.CustomCompte>();
            List<PhoningVendeur__c> phones = new List<PhoningVendeur__c>();
            ListePhoningVendeur__c listeReturn;
            ListePhoningVendeur__c liste;
            
            // Test avec champs obligatoires non présents - compteIds = null
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, null, sec.Id, null);
            System.assertEquals(null, listeReturn);
                        
            Utils_InnerClasses.CustomCompte accCustom1 = new Utils_InnerClasses.CustomCompte(new Event(),acc1);
            Utils_InnerClasses.CustomCompte accCustom2 = new Utils_InnerClasses.CustomCompte(new Event(),acc2);
            compteSearched.add(accCustom1);
            compteSearched.add(accCustom2);
            String compteSearchedJSON=JSON.serialize(compteSearched);
            
            // Test avec arg = null
            listeReturn = Ctrl_ListeDePhones.creerListePhones(null, compteSearchedJSON, null, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];

            System.assertEquals(null, liste.recordType_Filtre__c);
            System.assertEquals(null, liste.typeCompte_Filtre__c);
            System.assertEquals(null, liste.proprietaire_Filtre__c);
            System.assertEquals(null, liste.rue1_Filtre__c);
            System.assertEquals(null, liste.codePostal_Filtre__c);
            System.assertEquals(null, liste.rue2_Filtre__c);
            System.assertEquals(null, liste.rue3_Filtre__c);
            System.assertEquals(null, liste.ville_Filtre__c);
            System.assertEquals(null, liste.dernierAppel_Filter__c);
            System.assertEquals(null, liste.DR_Filtre__c);
            System.assertEquals(null, liste.DV_Filtre__c);
            System.assertEquals(null, liste.magasin_Filtre__c);
            
            // Test avec elements de arg = null
            arg.put('typeEnregistrement', null);
            arg.put('typeCompte', null);
            arg.put('rue', null);
            arg.put('rue2', null);
            arg.put('rue3', null);
            arg.put('ville', null);
            arg.put('cp', null);
            arg.put('proprietaireId', null);
            arg.put('dv', null);
            arg.put('region', null);
            arg.put('magasin', null);
            arg.put('dernierAppel', null);
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, compteSearchedJSON, null, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];
            System.assertEquals(null, liste.recordType_Filtre__c);
            System.assertEquals(null, liste.typeCompte_Filtre__c);
            System.assertEquals(null, liste.proprietaire_Filtre__c);
            System.assertEquals(null, liste.rue1_Filtre__c);
            System.assertEquals(null, liste.codePostal_Filtre__c);
            System.assertEquals(null, liste.rue2_Filtre__c);
            System.assertEquals(null, liste.rue3_Filtre__c);
            System.assertEquals(null, liste.ville_Filtre__c);
            System.assertEquals(null, liste.dernierAppel_Filter__c);
            System.assertEquals(null, liste.DR_Filtre__c);
            System.assertEquals(null, liste.DV_Filtre__c);
            System.assertEquals(null, liste.magasin_Filtre__c);
            
            // Test avec elements de arg vides
            arg = new Map<String, String>();
            arg.put('typeEnregistrement', '');
            arg.put('typeCompte', '');
            arg.put('rue', '');
            arg.put('rue2', '');
            arg.put('rue3', '');
            arg.put('ville', '');
            arg.put('cp', '');
            arg.put('proprietaireId', '');
            arg.put('dv', '');
            arg.put('region', '');
            arg.put('magasin', '');
            arg.put('dernierAppel', '');
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, compteSearchedJSON, null, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];
            System.assertEquals(null, liste.recordType_Filtre__c);
            System.assertEquals(null, liste.typeCompte_Filtre__c);
            System.assertEquals(null, liste.proprietaire_Filtre__c);
            System.assertEquals(null, liste.rue1_Filtre__c);
            System.assertEquals(null, liste.codePostal_Filtre__c);
            System.assertEquals(null, liste.rue2_Filtre__c);
            System.assertEquals(null, liste.rue3_Filtre__c);
            System.assertEquals(null, liste.ville_Filtre__c);
            System.assertEquals(null, liste.dernierAppel_Filter__c);
            System.assertEquals(null, liste.DR_Filtre__c);
            System.assertEquals(null, liste.DV_Filtre__c);
            System.assertEquals(null, liste.magasin_Filtre__c);
            
            // Test avec arg rempli
            arg = new Map<String, String>();
            arg.put('typeEnregistrement', 'typeEnregistrement');
            arg.put('typeCompte', 'typeCompte');
            arg.put('rue', 'rue');
            arg.put('rue2', 'rue2');
            arg.put('rue3', 'rue3');
            arg.put('ville', 'ville');
            arg.put('cp', '12345');
            arg.put('proprietaireId', String.valueOf(userTest.Id));
            arg.put('dv', 'dv');
            arg.put('region', 'region');
            arg.put('magasin', 'magasin');
            arg.put('dernierAppel', 'Aucun');
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, compteSearchedJSON, null, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];
            System.assertEquals('typeEnregistrement', liste.recordType_Filtre__c);
            System.assertEquals('typeCompte', liste.typeCompte_Filtre__c);
            System.assertEquals(String.valueOf(userTest.Id), liste.proprietaire_Filtre__c);
            System.assertEquals('rue', liste.rue1_Filtre__c);
            System.assertEquals(Decimal.valueOf('12345'), liste.codePostal_Filtre__c);
            System.assertEquals('rue2', liste.rue2_Filtre__c);
            System.assertEquals('rue3', liste.rue3_Filtre__c);
            System.assertEquals('ville', liste.ville_Filtre__c);
            System.assertEquals('Aucun', liste.dernierAppel_Filter__c);
            System.assertEquals('region', liste.DR_Filtre__c);
            System.assertEquals('dv', liste.DV_Filtre__c);
            System.assertEquals('magasin', liste.magasin_Filtre__c);
            
            // Test avec comptes personnels & secteurId rempli
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, compteSearchedJSON, sec.Id, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];
            // secteurId != null
            System.assertEquals(sec.codeMagasin__c, liste.magasin_Filtre__c);
            System.assertEquals(sec.codeRegion__c, liste.DR_Filtre__c);
            System.assertEquals(sec.codeDV__c, liste.DV_Filtre__c);
            // phones comptes personnels
            phones = [SELECT Id, name, liste__c, compte__c FROM PhoningVendeur__c WHERE liste__c = :listeReturn.Id];
            System.assertEquals(2, phones.size());
            
            // Test avec comptes professionnels
            compteSearched.clear();
            Utils_InnerClasses.CustomCompte accCustom3 = new Utils_InnerClasses.CustomCompte(new Event(),acc3);
            Utils_InnerClasses.CustomCompte accCustom4 = new Utils_InnerClasses.CustomCompte(new Event(),acc4);
            compteSearched.add(accCustom3);
            compteSearched.add(accCustom4);
            compteSearchedJSON=JSON.serialize(compteSearched);
            listeReturn = Ctrl_ListeDePhones.creerListePhones(arg, compteSearchedJSON, sec.Id, null);
            System.assertNotEquals(null, listeReturn);
            liste = [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                        rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                        DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                        FROM ListePhoningVendeur__c WHERE Id = :listeReturn.Id LIMIT 1];
            phones = [SELECT Id, name, liste__c, compte__c FROM PhoningVendeur__c WHERE liste__c = :listeReturn.Id];
            System.assertEquals(2, phones.size());   
            
            Test.stopTest();
            System.debug('TEST END');
        }
    } 
    
    @isTest 
    public static void test_getAllComptes() {
        // Création d'un utilisateur        
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.RunAs(userTest) {
            Set<Utils_InnerClasses.CustomCompte> objectToReturn;            
            List<String> comptesId = new List<String>();           
            List<Account> accList = new List<Account>();

            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création des comptes
            Contact contact = Utils_Test.createContact('Test','Test',true);
            Account acc1 = Utils_Test.createAccountPro('Test TestUn','0101010101', accProRT,contact.Id,Constants.ACCOUNT_TYPE_PISTE,false);
            acc1.iris__c = sec.iris__c;
            comptesId.add(acc1.Id);
            Account acc2 = Utils_Test.createAccount('TestDeux', 'Test', 'test2@test.fr', accPersoRT,Constants.ACCOUNT_TYPE_CONTACT,'Email',false);
            acc2.iris__c = sec.iris__c;
            comptesId.add(acc2.Id);
            Account acc3 = Utils_Test.createAccountPro('Test TestTrois','0101010101', accProRT,contact.Id,Constants.ACCOUNT_TYPE_PRECONTACT,false);
            acc3.iris__c = sec.iris__c; 
            comptesId.add(acc3.Id); 
            accList.add(acc1); 
            accList.add(acc2); 
            accList.add(acc3);
            insert accList;

            // Création des chantiers
            Chantier__c chantier1 = Utils_Test.createChantier('Chantier1',acc1.Id,null,false);
            chantier1.sectorisation__c = sec.Id;
            Chantier__c chantier2 = Utils_Test.createChantier('Chantier2',acc2.Id,null,false);
            chantier2.sectorisation__c = sec.Id;
            Chantier__c chantier3 = Utils_Test.createChantier('Chantier3',acc3.Id,null,false);
            chantier3.sectorisation__c = sec.Id;
            List<Chantier__c> chantierList = new List<Chantier__c>();
            chantierList.add(chantier1); 
            chantierList.add(chantier2); 
            chantierList.add(chantier3);
            insert chantierList;

            Test.startTest();

            // Création des projets
            Opportunity opp1 = Utils_Test.createOpportunity('Opp1',acc1,null,chantier1,true);
            Opportunity opp2 = Utils_Test.createOpportunity('Opp2',acc2,null,chantier2,true);
            Opportunity opp3 = Utils_Test.createOpportunity('Opp3',acc3,null,chantier3,true);
            
            // Création des événements
            acc2 = DAL.getAccountById(acc2.Id);
            Utils_Test.createEvent('R1', rtRDV, opp1.Id, contact.Id, null, true);
            Utils_Test.createEvent('R2', rtRDV, opp2.Id, acc2.PersonContactId, null, true);
            Utils_Test.createEvent('R+', rtRDV, opp3.Id, contact.Id, null, true);

            // Création Contrats SAV, Pose et Metrage
            Utils_Test.createContrat('Contrat SAV', null, acc1.Id, '456789', null, null, System.today() + 2, true);
            
            // Test avec aucun compte sélectionné
            objectToReturn = Ctrl_ListeDePhones.getAllComptes(new List<String>());
            System.assertEquals(0, objectToReturn.size());
            
            // Test avec tous les comptes sélectionés
            objectToReturn = Ctrl_ListeDePhones.getAllComptes(comptesId);
            //System.assertEquals(3, objectToReturn.size());
            
            Test.stopTest();
        }
    } 
    
    @isTest 
    public static void test_getAllComptes2() {
        // Création d'un utilisateur        
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.RunAs(userTest) {
            Set<Utils_InnerClasses.CustomCompte> objectToReturn;            
            List<String> comptesId = new List<String>();

            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création des comptes
            Contact contact = Utils_Test.createContact('Test','Test',true);
            Account acc4 = Utils_Test.createAccount('TestQuatre', 'Test', 'test2@test.fr', accPersoRT,Constants.ACCOUNT_TYPE_PROSPECT,'Email',false);
            acc4.iris__c = sec.iris__c; insert acc4;
            comptesId.add(acc4.Id);
            Account acc5 = Utils_Test.createAccountPro('Test Test Cinq','0101010101', accProRT,contact.Id,Constants.ACCOUNT_TYPE_CLIENT,false);
            acc5.iris__c = sec.iris__c; insert acc5;
            comptesId.add(acc5.Id);
            Account acc6 = Utils_Test.createAccount('TestSix', 'Test', 'test2@test.fr', accPersoRT,Constants.ACCOUNT_TYPE_EXCLIENT,'Email',false);
            acc6.iris__c = sec.iris__c; insert acc6;
            comptesId.add(acc6.Id);

            Test.startTest();
            
            // Création des événements
            acc4 = DAL.getAccountById(acc4.Id);

            // Création Contrats SAV, Pose et Metrage
            Utils_Test.createContrat('Contrat metrage', null, acc5.Id, '12345', System.today(), null, null, true);
            Utils_Test.createContrat('Contrat pose', null, acc6.Id, '67890', null, System.today() + 1, null, true);
            
            // Test avec aucun compte sélectionné
            objectToReturn = Ctrl_ListeDePhones.getAllComptes(new List<String>());
            System.assertEquals(0, objectToReturn.size());
            
            // Test avec tous les comptes sélectionés
            objectToReturn = Ctrl_ListeDePhones.getAllComptes(comptesId);
            System.assertEquals(3, objectToReturn.size());
            
            Test.stopTest();
        }
    } 
    
    @isTest 
    public static void test_getSectorCoord() {        
        // Création d'un utilisateur        
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.RunAs(userTest) {
            // Sectorisation
            Sectorisation__c secto = [SELECT Id, Name, iris__c FROM Sectorisation__c LIMIT 1];
            // Récupération Cartographie
            Cartographie__c carto = Utils_Test.createCartographie('Test Carto','KPK-Vente', true);
            // Création Attachement pour secteur
            Utils_Test.createAttachment('M123', carto.Id, Blob.valueOf('547031 2523701,547066 2523729,547331 2523900,547450 2523956,547080 2524237'));

            Test.startTest();
            
            Utils_Cartographie.Sector retSector;
            retSector = Ctrl_ListeDePhones.getSectorCoord('Magasin 123');
            System.assertNotEquals(null, retSector);
            System.assertEquals(secto.Id, retSector.Id);
            System.assertEquals(secto.Id, retSector.Name);
            System.assertEquals('M123', retSector.Code);
            System.assertEquals(Blob.valueOf('547031 2523701,547066 2523729,547331 2523900,547450 2523956,547080 2524237').toString(), retSector.WKT);
            
            retSector = Ctrl_ListeDePhones.getSectorCoord(null);
            System.assertEquals(null, retSector);
            
            Test.stopTest();
        }
    } 
    
    @isTest 
    static void test_RemoteAction() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id);

        System.runAs(user) {
            Test.startTest();
            PageReference vf_liste = Page.VF_ListeDePhones;
            Test.setCurrentPageReference (vf_liste);
            Ctrl_ListeDePhones ctrl = new Ctrl_ListeDePhones();
            
            List<String> comptesType = new List<String>{'Piste'};
            /*Ctrl_ListeDePhones.getProspectionsProchaineList('MAG001Test', 547031,547450,2524237,2523701, comptesType);
            Ctrl_ListeDePhones.getComptesRDVbyTypeList('MAG001Test', 547031,547450,2524237,2523701, 'Metrages', comptesType);
            Ctrl_ListeDePhones.getComptesRDVbyTypeList('MAG001Test', 547031,547450,2524237,2523701, 'Installations', comptesType);
            Ctrl_ListeDePhones.getComptesRDVbyTypeList('MAG001Test', 547031,547450,2524237,2523701, 'InterventionsSAV', comptesType);        
			Ctrl_ListeDePhones.getComptesRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R1', comptesType);
			Ctrl_ListeDePhones.getComptesRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R2', comptesType);
			Ctrl_ListeDePhones.getComptesRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R+', comptesType);
            Ctrl_ListeDePhones.getComptesNoRDV('MAG001Test', 547031,547450,2524237,2523701, comptesType);*/
            
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', new List<String>(), '', 547031,547450,2524237,2523701);
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, '', 547031,547450,2524237,2523701); // Recherche par type de compte
            // Recherche par RDV
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', new List<String>(), 'R1', 547031,547450,2524237,2523701); 
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'R1', 547031,547450,2524237,2523701); 
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'R2', 547031,547450,2524237,2523701); 
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'R+', 547031,547450,2524237,2523701); 
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'Prospections', 547031,547450,2524237,2523701); 
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'Metrages', 547031,547450,2524237,2523701);
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'Installations', 547031,547450,2524237,2523701);
            Ctrl_ListeDePhones.getTypeComptes('MAG001Test', comptesType, 'InterventionsSAV', 547031,547450,2524237,2523701);
        
			Test.stopTest();
		}
	}
    
    @isTest 
    public static void test_cancel() {
        // Création d'un utilisateur        
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                    
        System.RunAs(userTest) {
            Test.startTest();
            PageReference consultationListe;
            
            // Test sans retUrl
            consultationListe = Ctrl_ListeDePhones.cancel();
            System.assertNotEquals(null, consultationListe);
            System.assertEquals(Page.VF_ConsultationListeDePhones.getURL(), consultationListe.getURL());
            
            // Test avec retUrl
            ApexPages.currentPage().getParameters().put('retURL', '/apex/vf_consultationlistedephones');
            consultationListe = Ctrl_ListeDePhones.cancel();
            System.assertNotEquals(null, consultationListe);
            System.assertEquals(Page.VF_ConsultationListeDePhones.getURL(), consultationListe.getURL());
            
            Test.stopTest();
        }
    } 
    
    @isTest 
    static void test_otherTests() {
        Test.startTest();

        PageReference vf_liste = Page.VF_ListeDePhones;
        Test.setCurrentPageReference (vf_liste);
        Ctrl_ListeDePhones ctrl = new Ctrl_ListeDePhones();
        
        // Lookup Options
        ReferentielOptions__c opt = [SELECT Id, codeoption__c FROM ReferentielOptions__c WHERE codeoption__c = 'OFEPVC0119' LIMIT 1];
        ctrl.displayOptionId = opt.Id;
        ctrl.optionCode = opt.codeoption__c;
        ReferentielOptions__c opt1 = ctrl.optionSample;
        List<ReferentielOptions__c> baseOptions = ctrl.baseOptions;
        // Lookup Produit
        Product2 prod = [SELECT Id FROM ProducT2 WHERE ProductCode = 'FFFETT' LIMIT 1];
        ctrl.displayProductId = prod.Id;
        Product2 productSample = ctrl.productSample;
        ctrl.displayProductName = 'FFFETT';
        
        // Other
        List<SelectOption> fileNames = ctrl.getfilesName();
        Ctrl_ListeDePhones.redirectToConsultationListe();
        
        Test.stopTest();
    }
}