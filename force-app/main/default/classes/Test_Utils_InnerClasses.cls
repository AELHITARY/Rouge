//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_InnerClasses
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/11/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_InnerClasses {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @isTest 
    static void testVendeurInfos() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Utils_InnerClasses.VendeurInfos test = new Utils_InnerClasses.VendeurInfos();

            System.debug(test.Vendeur);
            System.debug(test.Vendeur);
            System.debug(test.RoleName);
            System.debug(test.UserId);
            System.debug(test.UserName);
            System.debug(test.Distance);
            System.debug(test.isResponsable);
            System.debug(test.Position);
            System.debug(test.Latitude);
            System.debug(test.Longitude);
        }
    }

    @isTest 
    static void testIndicateurs() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Utils_InnerClasses.IndicateursPie test = new Utils_InnerClasses.IndicateursPie();
            Utils_InnerClasses.IndicateursVendeurAll test2 = new Utils_InnerClasses.IndicateursVendeurAll();

            System.debug(test.vendeurAjd);
            System.debug(test.vendeurDemain);
            System.debug(test.vendeurADemain);
            System.debug(test.magasinAjd);
            System.debug(test.magasinDemain);
            System.debug(test.magasinADemain);


            System.debug(test2.vendeurId);
            System.debug(test2.vendeurName);
            System.debug(test2.vendeurActive);
            System.debug(test2.vendeurLastLoginDate);
            System.debug(test2.vendeurNbLogin);
            System.debug(test2.index);
            System.debug(test2.IVM);
            System.debug(test2.IVH);
            System.debug(test2.IVT);
        }
    }

    @isTest 
    static void testIndicateursVendeurHebdomadaire () {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            Utils_InnerClasses.IndicateursVendeurHebdomadaire  test = new Utils_InnerClasses.IndicateursVendeurHebdomadaire ();

            System.debug(test.vendeurId);
            System.debug(test.joursTravaille);
            System.debug(test.objectifContactActif);          // C01
            System.debug(test.nbContactActif);                // C02
            System.debug(test.nbContactPassif);               // C04
            System.debug(test.nbRDVTotal);                    // C05
            System.debug(test.nbDevisVendu);                  // C06 et V03
            System.debug(test.nbRDVR1_Pris);                  // C07
            System.debug(test.nbRDVR1_Effec);                 // C07
            System.debug(test.nbRDVR2_Pris);                  // C08
            System.debug(test.nbRDVR2_Effec);                 // C08
            System.debug(test.nbRDVBAL50);                    // C09
            System.debug(test.nbContactBAL);                  // C10
            System.debug(test.nbRDVTAP51);                    // C11
            System.debug(test.nbContactTAP);                  // C12
            System.debug(test.nbContactComplement);           // C13
            System.debug(test.nbContactParrainage);           // C14
            System.debug(test.nbRDVPhone55);                  // C15
            System.debug(test.nbContactPhone);                // C16
            System.debug(test.nbRDVGalerieMarchande);         // C17
            System.debug(test.nbContactGalerieMarchande);     // C18
            System.debug(test.nbRDVFoire);                    // C19
            System.debug(test.nbContactFoire);                // C20
            System.debug(test.nbRDVMarche);                   // C21
            System.debug(test.nbContactMarche);               // C22
            System.debug(test.objectifContactTotal);          // C23
            System.debug(test.nbContactTotal);                // C24
            System.debug(test.nbRDVCreatedRdvDate);           // C25
            System.debug(test.nbRDVDebrief);                  // C26
            System.debug(test.objectifnbDevisVendu);          // V01
            System.debug(test.objectifCADevisVendu);          // V02
            System.debug(test.nbCADevisVendu);                // V04
            System.debug(test.nbRDVAccompagne);               // CRM-610 JMU
            System.debug(test.nbRDVAccompagnant);             // CRM-610 JMU
            System.debug(test.ratioParJourBAL);               // CRM-610 JMU
            System.debug(test.ratioParContactBAL);            // CRM-610 JMU
            System.debug(test.ratioParJourTAP);               // CRM-610 JMU
            System.debug(test.ratioParContactTAP);            // CRM-610 JMU
            System.debug(test.ratioParJourPhone);             // CRM-610 JMU
            System.debug(test.ratioParContactPhone);          // CRM-610 JMU
            System.debug(test.realisationContact);
            System.debug(test.realisationContactActif);
            System.debug(test.tauxTransformationRDV);
            System.debug(test.tauxTransformationVentes);
            System.debug(test.tauxPartContactBAL);
            System.debug(test.tauxPartContactTAP);
            System.debug(test.tauxPartContactCOMP);
            System.debug(test.tauxPartContactPHONE);
            System.debug(test.tauxPartContactGM);
            System.debug(test.tauxPartContactFOIRE);
            System.debug(test.tauxPartContactMARCHE);
            System.debug(test.panierMoyenObjectifVente);
            System.debug(test.panierMoyenRealiseVente);
        }
    }

    @isTest 
    static void testIndicateursVendeurMensuel() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            Utils_InnerClasses.IndicateursVendeurMensuel  test = new Utils_InnerClasses.IndicateursVendeurMensuel ();

            System.debug(test.vendeurId);
            System.debug(test.joursTravaille);
            System.debug(test.joursTravailleMonth);           // CRM-610
            System.debug(test.objectifDevisVendu);    // M05
            System.debug(test.nbCADevisVendu);        // M06
            System.debug(test.nbContactActif);        // M07
            System.debug(test.nbContactPassif);       // M08
            System.debug(test.valeursMensuelByWeek);      // M01 à M04
            System.debug(test.nbDevisVendu);
            System.debug(test.numberOfWeek);
            System.debug(test.nbRDVBAL50);                    // C09
            System.debug(test.nbContactBAL);                  // C10
            System.debug(test.nbRDVTAP51);                    // C11
            System.debug(test.nbContactTAP);                  // C12
            System.debug(test.nbContactComplement);           // C13
            System.debug(test.nbContactParrainage);           // C14
            System.debug(test.nbRDVPhone55);                  // C15
            System.debug(test.nbContactPhone);                // C16
            System.debug(test.nbRDVGalerieMarchande);         // C17
            System.debug(test.nbContactGalerieMarchande);     // C18
            System.debug(test.nbRDVFoire);                    // C19
            System.debug(test.nbContactFoire);                // C20
            System.debug(test.nbRDVMarche);                   // C21
            System.debug(test.nbContactMarche);               // C22
            System.debug(test.nbRDVAccompagne);               // CRM-610 JMU
            System.debug(test.nbRDVAccompagnant);             // CRM-610 JMU
            System.debug(test.ratioParJourBAL);               // CRM-610 JMU
            System.debug(test.ratioParContactBAL);            // CRM-610 JMU
            System.debug(test.ratioParJourTAP);               // CRM-610 JMU
            System.debug(test.ratioParContactTAP);            // CRM-610 JMU
            System.debug(test.ratioParJourPhone);             // CRM-610 JMU
            System.debug(test.ratioParContactPhone);          // CRM-610 JMU
            System.debug(test.tauxPartContactBAL);            // CRM-610 JMU
            System.debug(test.tauxPartContactTAP);            // CRM-610 JMU
            System.debug(test.tauxPartContactCOMP);           // CRM-610 JMU
            System.debug(test.tauxPartContactPHONE);          // CRM-610 JMU
            System.debug(test.tauxPartContactGM);             // CRM-610 JMU
            System.debug(test.tauxPartContactFOIRE);          // CRM-610 JMU
            System.debug(test.tauxPartContactMARCHE);         // CRM-610 JMU
            System.debug(test.realisationCADevis);
        }
    }

    @isTest 
    static void testIndicateursVendeurTotaux() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Utils_InnerClasses.IndicateursVendeurTotaux test = new Utils_InnerClasses.IndicateursVendeurTotaux();

            System.debug(test.Somme_objectifContactTotal);                // Somme C23
            System.debug(test.Somme_nbContactTotal);                      // Somme C24
            System.debug(test.Somme_objectifContactActif);                // Somme C01
            System.debug(test.Somme_nbContactActif);                      // Somme C02
            System.debug(test.Somme_nbContactPassif);                     // Somme C04
            System.debug(test.Somme_nbRDVTotal);                          // Somme C05
            System.debug(test.Somme_nbDevisVendu);                        // Somme C06 et V03
            System.debug(test.Somme_nbRDVCreatedRdvDate);                 // Somme C25
            System.debug(test.Somme_nbRDVDebrief);                        // Somme C26
            System.debug(test.Somme_nbRDVR1_Pris);                        // Somme C07
            System.debug(test.Somme_nbRDVR1_Effec);                       // Somme C07
            System.debug(test.Somme_nbRDVR2_Pris);                        // Somme C08
            System.debug(test.Somme_nbRDVR2_Effec);                       // Somme C08
            System.debug(test.Somme_nbRDVBAL50);                          // Somme C09
            System.debug(test.Somme_nbContactBAL);                        // Somme C10
            System.debug(test.Somme_nbRDVTAP51);                          // Somme C11
            System.debug(test.Somme_nbContactTAP);                        // Somme C12
            System.debug(test.Somme_nbContactComplement);                 // Somme C13
            System.debug(test.Somme_nbContactParrainage);                 // Somme C14
            System.debug(test.Somme_nbRDVPhone55);                        // Somme C15
            System.debug(test.Somme_nbContactPhone);                      // Somme C16
            System.debug(test.Somme_nbRDVGalerieMarchande);               // Somme C17
            System.debug(test.Somme_nbContactGalerieMarchande);           // Somme C18
            System.debug(test.Somme_nbRDVFoire);                          // Somme C19
            System.debug(test.Somme_nbContactFoire);                      // Somme C20
            System.debug(test.Somme_nbRDVMarche);                         // Somme C21
            System.debug(test.Somme_nbContactMarche);                     // Somme C22
            System.debug(test.Somme_nbRDVHebdoAccompagne);                // CRM-610 JMU
            System.debug(test.Somme_nbRDVHebdoAccompagnant);              // CRM-610 JMU
            System.debug(test.Somme_objectifnbDevisVendu);                // Somme V01
            System.debug(test.Somme_objectifCADevisVendu);                // Somme V02
            System.debug(test.Somme_nbCADevisVendu);                      // Somme V04
            System.debug(test.Somme_nbRDVMensuelAccompagne);              // CRM-610 JMU
            System.debug(test.Somme_nbRDVMensuelAccompagnant);            // CRM-610 JMU
            System.debug(test.Somme_objectifDevisVenduMensuel);           // Somme M05
            System.debug(test.Somme_nbCADevisVenduMensuel);               // Somme M06
            System.debug(test.Somme_nbContactActifMensuel);               // Somme M07
            System.debug(test.Somme_nbContactPassifMensuel);              // Somme M08
            System.debug(test.Somme_valeursMensuelByWeek);        // Somme M01 à M04
            System.debug(test.Somme_nbDevisVenduMensuel);
            System.debug(test.Somme_nbRDVBAL50Mensuel);                   // CRM-610 JMU
            System.debug(test.Somme_nbContactBALMensuel);                 // CRM-610 JMU
            System.debug(test.Somme_nbRDVTAP51Mensuel);                   // CRM-610 JMU
            System.debug(test.Somme_nbContactTAPMensuel);                 // CRM-610 JMU
            System.debug(test.Somme_nbContactComplementMensuel);          // CRM-610 JMU
            System.debug(test.Somme_nbContactParrainageMensuel);          // CRM-610 JMU
            System.debug(test.Somme_nbRDVPhone55Mensuel);                 // CRM-610 JMU
            System.debug(test.Somme_nbContactPhoneMensuel);               // CRM-610 JMU
            System.debug(test.Somme_nbRDVGalerieMarchandeMensuel);        // CRM-610 JMU
            System.debug(test.Somme_nbContactGalerieMarchandeMensuel);    // CRM-610 JMU
            System.debug(test.Somme_nbRDVFoireMensuel);                   // CRM-610 JMU
            System.debug(test.Somme_nbContactFoireMensuel);               // CRM-610 JMU
            System.debug(test.Somme_nbRDVMarcheMensuel);                  // CRM-610 JMU
            System.debug(test.Somme_nbContactMarcheMensuel);              // CRM-610 JMU
            System.debug(test.Somme_realisationContact );                 // [TR] Somme C23 C24
            System.debug(test.Somme_realisationContactActif);             // [TR] Somme C01 C02
            System.debug(test.Somme_realisationContactPassif);            // [TR] Somme C03 C04
            System.debug(test.Somme_panierMoyenObjectifVente);            // [PM] Somme V01 V02
            System.debug(test.Somme_panierMoyenRealiseVente);             // [PM] Somme V03 V04
            System.debug(test.Somme_panierMoyenCAMensuel);                // [PM] Mensuel
        }
    }

    @isTest 
    static void testIndicateursObjectifUser () {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            Utils_InnerClasses.IndicateursObjectifUser test = new Utils_InnerClasses.IndicateursObjectifUser();

            System.debug(test.objectifContactActif);
            System.debug(test.objectifnbDevisVendu);
            System.debug(test.objectifCADevisVendu);
            System.debug(test.nbContactActif);
            System.debug(test.nbContactActifEff);
            System.debug(test.nbVendeurEffectif);
            System.debug(test.nbDevisVendu);
            System.debug(test.nbCADevisVendu);
            System.debug(test.realisationContactActif);
            System.debug(test.realisationContactActifEffectif);
            System.debug(test.realisationNbDevis);
            System.debug(test.realisationCADevis);
        }
    }

    @isTest 
    static void testCustomActivity() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création enregistrement
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);   
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
            Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,acc.PersonContactId, user.Id, Constants.StatutEventAReaffecter, true);
            
            // Exécution du test
            Test.startTest();

            Utils_InnerClasses.CustomActivity test1 = new Utils_InnerClasses.CustomActivity(event0, true);

            Test.stopTest();
        }
    }

    @isTest 
    static void testCustomCompte() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Création enregistrement
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);   
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
            Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,acc.PersonContactId, user.Id, Constants.StatutEventAReaffecter, true);
            // Création de la liste de phones
            ListePhoningVendeur__c ldp = Utils_Test.createListePhoningVendeur('Liste 123',user.Id,true);            
            // Création des phones
            PhoningVendeur__c phone = Utils_test.createPhoningVendeur('Phone 123',ldp.Id,acc.Id,true);
            
            // Exécution du test
            Test.startTest();

            Utils_InnerClasses.CustomCompte test1 = new Utils_InnerClasses.CustomCompte(phone, acc);
            Utils_InnerClasses.CustomCompte test2 = new Utils_InnerClasses.CustomCompte(event0, acc);

            Test.stopTest();
        }
    }
}