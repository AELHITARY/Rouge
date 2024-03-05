//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_Trustpilot
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/09/2021
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_Trustpilot {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @isTest static void testKContrat() {
         
        User user = getUser();
        update user;

        System.runAs(user) {
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            Utils_Test.createSectorisation();

            PropertiesUtils.setStringValue('trustpilot.api.apikey', '2PPGjGhXllss8niG0AGYsJhGaC4mPGCo');
            PropertiesUtils.setStringValue('trustpilot.api.businessUnitId', '59c8fb8c0000ff0005abfef7');
            PropertiesUtils.setIntegerValue('trustpilot.api.nbReviewPerPage', 20);
            PropertiesUtils.setStringValue('trustpilot.api.password', 'test');
            PropertiesUtils.setStringValue('trustpilot.api.username', 'test');
                    
            // Récupération des types d'enregistrement
            Id accRecordType = DAL.getRecordTypeIdByDevName(Constants.ACCOUNT_PERSO_RT);
            
            // Création d'un compte
            Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', accRecordType, 'Client', 'FAX', true);
            
            // Création d'un chantier        
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, true);

            // Création d'un projet
            Opportunity opp = Utils_Test.createOpportunity(account, chantier, true);
            
            // Création d'un contrat
            KContrat__c contratMetrage = Utils_Test.createContrat('Contrat Metrage', chantier.Id, account.Id, '0002', true);

            contratMetrage.DateEnvoiAvisTrustpilot__c = null;
            contratMetrage.dateReponseQuestionnaire__c = System.today().addDays(-7);
            contratMetrage.NPSSatisfaction__c = 9;
            contratMetrage.libelleStatutContrat__c = 'Solde';
            contratMetrage.numeroContrat__c = 'CNT/22222221';
            contratMetrage.debutDernierSAV__c = null;
    
            update contratMetrage;

            System.debug('contratMetrage.DateEnvoiAvisTrustpilot__c : '+contratMetrage.DateEnvoiAvisTrustpilot__c);
            System.debug('contratMetrage.dateReponseQuestionnaire__c : '+contratMetrage.dateReponseQuestionnaire__c);
            System.debug('contratMetrage.NPSSatisfaction__c : '+contratMetrage.NPSSatisfaction__c);
            System.debug('contratMetrage.libelleStatutContrat__c : '+contratMetrage.libelleStatutContrat__c);
            System.debug('contratMetrage.numeroContrat__c : '+contratMetrage.numeroContrat__c);
            System.debug('contratMetrage.debutDernierSAV__c : '+contratMetrage.debutDernierSAV__c);

            Test.startTest();
            Database.executeBatch(new BA_TrustPilot_SendNewSoldContrats());
            

            contratMetrage.DateEnvoiAvisTrustpilot__c = Date.today();

            Database.executeBatch(new BA_TrustPilot_GetReactionsCreateCases());

            Schedule_TrustPilot_SendNewSoldContrats schedule = new Schedule_TrustPilot_SendNewSoldContrats();
            String jobId = system.schedule('Test Test_Schedule_TrustPilot_SendContrats', '0 0 23 * * ?', schedule);

            Schedule_TrustPilot_GetReactions schedule2 = new Schedule_TrustPilot_GetReactions();
            String jobId2 = system.schedule('Test Test_Schedule_TrustPilot_GetReactions', '0 0 23 * * ?', schedule2);

            Test.stopTest();

            List<Case> caseResultList = new List<Case>();
            caseResultList = [SELECT Id, AccountId, ContactId, Chantier__c, numeroContrat__c, trustpilotReviewID__c,
                                    Subject, Origin, source__c, Status, Description
                                FROM Case];
            System.debug('caseResultList : '+caseResultList);

            if(!caseResultList.isEmpty()){
                CaseComment newCaseComment = new CaseComment(
                                                                CommentBody = 'Test',
                                                                ParentId = caseResultList[0].Id
                                                            );
                insert newCaseComment;
            }
        }
    }

    private static Chantier__c createChantier(Account proprietaire, Account autreProprietaire, Account locataire, Account autreLocataire, 
                                             Account occupant, Account autreOccupant, Sectorisation__c defaultSectorisation) {
       Chantier__c chantier = new Chantier__c();

       chantier.name = 'CHA - Test';

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

       chantier.Localisation__Latitude__s = 0;
       chantier.Localisation__Longitude__s = 0;
       chantier.iris__c = defaultSectorisation.iris__c;

      System.assertNotEquals(null, chantier.iris__c);

      return chantier;
    }
   

    private static User getUser() {
      UserContext context = UserContext.getContext();
      User user = context.getUser();
      if (StringUtils.isEmpty(user.codeMagasin__c))
        user.codeMagasin__c = 'MAG0000';
      if (StringUtils.isEmpty(user.libelleMagasin__c))
        user.codeMagasin__c = 'Magasin 0000';
      if (StringUtils.isEmpty(user.codeDV__c))
        user.codeMagasin__c = 'DV0000';
      if (StringUtils.isEmpty(user.libelleDV__c))
        user.codeMagasin__c = 'DV 0000';
      if (StringUtils.isEmpty(user.codeDR__c))
        user.codeMagasin__c = 'DV0000';
      if (StringUtils.isEmpty(user.libelleDR__c))
        user.codeMagasin__c = 'DV 0000';
      return user;
    }
}