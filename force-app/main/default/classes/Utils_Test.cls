//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Test 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 25/10/2021
//-- Version     : 1.3
//-- * 1.3 : Ajout supplémentaire Objet Kube 3
//-- * 1.2 : Ajout Objet Kube 3
//-- * 1.1 : Ajout Quote CPQ
//-- --------------------------------------------------------------------------------- --
@IsTest
public class Utils_Test {

    /**************************************************************/
    /***************** Création d'enregistrements *****************/
    /**************************************************************/
    
    /********************** USER OBJECT **********************/
    
    /**
    * @description Fonction générique de création d'un utilisateur
    * @param bypass True = bypass les workflows et les règles de validation
    * @param alias Alias de l'utilisateur
    * @param userName Identifiant de l'utilisateur 
    * @param lastName Nom
    * @param firstName Prénom
    * @param roleId Id du role à utiliser
    * @param profileId Id du profile à utiliser, si null, le profil "Administrateur système" est utilisé
    * @param toInsert Définir à true pour insertion en base
    * @return User Instance de l'objet utilisateur
    */
    public static User createUser(Boolean bypass, String alias, String userName, String lastName, String firstName, Id profileId, Id roleId, Boolean toInsert) {
        User usr = new User();
        usr.ByPassValidationRule__c = bypass;
        usr.ByPassWorkflowRule__c = bypass;
        usr.Username = userName;
        usr.LastName = lastName;
        usr.FirstName = firstName;
        usr.Email = userName;
        usr.UserPermissionsMarketingUser = true;
        usr.Alias = alias;
        usr.CommunityNickname = alias;
        usr.TimeZoneSidKey = 'Europe/Paris';
        usr.LocaleSidKey = 'fr_FR_EURO';
        usr.EmailEncodingKey = 'ISO-8859-1';
        if(profileId == null)
            usr.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'].Id;
        else
            usr.ProfileId = profileId;
        if(roleId == null)
            usr.UserRoleId = System.Label.RTRole;
        else
            usr.UserRoleId = roleId;
        usr.LanguageLocaleKey='fr';
        usr.isActive=true;
        usr.dateEntree__c = Date.newInstance(2017, 1, 1);
        
        if(toInsert) 
            insert usr;
        return usr;
    }
    
    /**
    * @description Fonction générique de création d'un utilisateur avec code magasin, DV et DR
    * @param bypass True = bypass les workflows et les règles de validation
    * @param alias Alias de l'utilisateur
    * @param userName Identifiant de l'utilisateur 
    * @param lastName Nom
    * @param firstName Prénom
    * @param profileId Id du profile à utiliser, si null, le profil "Administrateur système" est utilisé
    * @param roleId Id du role à utiliser
    * @param codeDR Code de la région
    * @param codeDV Code de division de vente
    * @param codeMagasin Code du magasin
    * @param toInsert Définir à true pour insertion en base
    * @return User Instance de l'objet utilisateur
    */
    public static User createUser (Boolean bypass, String alias, String userName, String lastName, String firstName, Id profileId, Id roleId,
                                   String codeDR, String codeDV, String codeMagasin, Boolean toInsert) {
                                       User usr = createUser(bypass, alias, userName, lastName, firstName, profileId, roleId, false);
                                       usr.codeDR__c = codeDR;
                                       usr.codeDV__c = codeDV;
                                       usr.codeMagasin__c = codeMagasin;
                                       
                                       if(toInsert) 
                                           insert usr;
                                       return usr;
                                   }   
    
    /**
    * @description Fonction générique de création d'un utilisateur avec code magasin, DV et DR
    * @param bypass True = bypass les workflows et les règles de validation
    * @param alias Alias de l'utilisateur
    * @param userName Identifiant de l'utilisateur 
    * @param lastName Nom
    * @param firstName Prénom
    * @param profileId Id du profile à utiliser, si null, le profil "Administrateur système" est utilisé
    * @param codeDR Code de la région
    * @param codeDV Code de division de vente
    * @param codeMagasin Code du magasin
    * @param toInsert Définir à true pour insertion en base
    * @return User Instance de l'objet utilisateur
    */
    public static User createUser (Boolean bypass, String alias, String userName, String lastName, String firstName, Id profileId,
                                   String codeDR, String codeDV, String codeMagasin, Boolean toInsert) {
                                       User usr = createUser(bypass, alias, userName, lastName, firstName, profileId, null, codeDR, codeDV, codeMagasin, false);
                                       usr.UserRoleId = null;
                                       
                                       if(toInsert) 
                                           insert usr;
                                       return usr;
                                   }   
    
    /**
    * @description Fonction générique de création d'un utilisateur. 
    * L'enregistrement sera automatiquement enregistré dans la BDD.
    * @param bypass True = bypass les workflows et les règles de validation
    * @param alias Alias de l'utilisateur
    * @param userName Identifiant de l'utilisateur 
    * @param lastName Nom
    * @param firstName Prénom
    * @param profileId Id du profil à utiliser, si null, le profil "Administrateur système" est utilisé
    * @return User Instance de l'objet utilisateur
    */
    public static User createUser(Boolean bypass, String alias, String userName, String lastName, String firstName, Id profileId, Id roleId) {
        return createUser(bypass, alias, userName, lastName, firstName, profileId, roleId, true);
    }   
    
    /**
    * @description Fonction de création d'un utilisateur Administrateur
    * @return User Instance de l'objet utilisateur
    */
    public static User createAdminUser() {
        return createUser(true, 'Test', 'testAD'+randVal()+'@testKparK.fr', 'Test Lastname', 'Test Firstname', null, null, true);
    }
    
    /**
    * @description Fonction de création d'un utilisateur Call (utilisation profil "'K/K - TA")
    * @return User Instance de l'objet utilisateur
    */
    public static User createCallUser() {
        String prfId = [SELECT Id FROM Profile WHERE Name = 'K/K - TA/Entrant'].Id;
        return createUser(false, 'Call', 'testCall'+randVal()+'@testKparK.fr', 'Call Lastname', 'Call Firstname', prfId, null, true);
    }
    
    /**
    * @description Fonction de création d'un utilisateur RV (utilisation profil "K/K - RV")
    * @param codeDR Code de la région
    * @param codeDV Code de division de vente
    * @param codeMagasin Code du magasin
    * @param roleId Id du role
    * @return User Instance de l'objet utilisateur
    */
    public static User createRVUser(String codeDR, String codeDV, String codeMagasin, Id roleId) {
        String prfId = [SELECT Id FROM Profile WHERE Name = 'K/K - RV'].Id;
        return createUser(false, 'RV', 'testRV'+System.now().format('hhmmss')+'@testKparK.fr', 'RV Lastname', 'RV Firstname', prfId, roleId, codeDR, codeDV, codeMagasin, true);
    }
    
    /**
    * @description Fonction de création d'un utilisateur vendeur (utilisation profil "K/K - Vendeur")
    * @param codeDR Code de la région
    * @param codeDV Code de division de vente
    * @param codeMagasin Code du magasin
    * @param roleId Id du role
    * @param toInsert True pour persister l'utilisateur avant de le retourner
    * @return User Instance de l'objet utilisateur
    */
    public static User createVendeurUser(String codeDR, String codeDV, String codeMagasin, Id roleId, Boolean toInsert) {
        String prfId = [SELECT Id FROM Profile WHERE Name = 'K/K - Vendeur'].Id;
        return createUser(false, 'Vendeur', 'testVD'+System.now().format('hhmmss')+'@testKparK.fr', 'Vend Lastname', 'Vend Firstname', prfId, roleId, codeDR, codeDV, codeMagasin, toInsert);
    }
    
    /**
    * @description Fonction de création d'un utilisateur vendeur (utilisation profil "K/K - Vendeur")
    * @param codeDR Code de la région
    * @param codeDV Code de division de vente
    * @param codeMagasin Code du magasin
    * @param roleId Id du role
    * @return User Instance de l'objet utilisateur
    */
    public static User createVendeurUser(String codeDR, String codeDV, String codeMagasin, Id roleId) {
        return createVendeurUser(codeDR, codeDV, codeMagasin, roleId, true);
    }
    
    /********************** REFERENCIAL OBJECT **********************/
    
    /**
    * @description Fonction de création d'un enregistrement référentiel
    * @param name Nom
    * @param ref Référence
    * @param startDate Date de d?but de validité
    * @param endDate Date de d?but de validité
    * @param rtId RecordTypeId
    * @param publicGroup True pour groupe public
    * @param queue
    * @param serviceTerritory
    * @param chatterGroup
    * @param toInsert Définir à true pour insertion en base
    * @return Referencial__c Instance de l'objet Referencial__c
    */
    public static Referencial__c createReferencial(String name, String ref, Date startDate, Date endDate, Id rtId, 
                                                    Boolean publicGroup, Boolean queue, Boolean serviceTerritory, 
                                                    Boolean chatterGroup, Boolean toInsert) {
        Referencial__c referencial = new Referencial__c(Name = Name,
                                                        RecordTypeId = rtId,
                                                        KparKReference__c = ref,
                                                        startDate__c = startDate,
                                                        endDate__c = endDate,
                                                        publicGroup__c = publicGroup,
                                                        queue__c = queue,
                                                        serviceTerritory__c = serviceTerritory,
                                                        chatterGroup__c = chatterGroup,
                                                        category__c = 'AUTRE',
                                                        subCategory__c = 'PARRAINAGES & AUTRES');
        
        // Vérification de la présence d'un OperatingHours (si ServiceTerritory)
        if(serviceTerritory) {
            String opHoursName = PropertiesUtils.getStringValue('fsl.operatingHours.defaultName', 'Par Défaut');
            List<OperatingHours> opHoursList = [SELECT Id, Name FROM OperatingHours WHERE Name = :opHoursName LIMIT 1];
            if(opHoursList.isEmpty()) {
                OperatingHours op = new OperatingHours(Name = opHoursName);
                insert op;
            }
        }
        
        if(toInsert) 
            insert referencial;
        return referencial;
    }

    /**
    * @description Fonction de création d'un enregistrement référentiel de type BankAccount
    * @param name Nom
    * @param ref Référence
    * @param startDate Date de d?but de validité
    * @param endDate Date de d?but de validité
    * @param toInsert Définir à true pour insertion en base
    * @return Referencial__c Instance de l'objet Referencial__c
    */
    public static Referencial__c createBankAccount(String name, String ref, Date startDate, Date endDate, Boolean toInsert) {
        Referencial__c referencial = new Referencial__c(Name = Name,
                                                        RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'BankAccount'),
                                                        KparKReference__c = ref,
                                                        startDate__c = startDate,
                                                        endDate__c = endDate,
                                                        BIC__c='CCBPFRPPVER', 
                                                        iban__c='FR6012739000709676238612A65');
        if(toInsert) 
            insert referencial;
        return referencial;
    }

    /**
    * @description Fonction de création d'un enregistrement référentiel de type PaymentMethod
    * @param name Nom
    * @param ref Référence
    * @param startDate Date de d?but de validité
    * @param endDate Date de d?but de validité
    * @param toInsert Définir à true pour insertion en base
    * @return Referencial__c Instance de l'objet Referencial__c
    */
    public static Referencial__c createPaymentMethod(String name, String ref, Date startDate, Date endDate, Boolean toInsert) {
        Referencial__c referencial = new Referencial__c(Name = Name,
                                                        RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'PaymentMethod'),
                                                        KparKReference__c = ref,
                                                        startDate__c = startDate,
                                                        endDate__c = endDate);
        if(toInsert) 
            insert referencial;
        return referencial;
    }

    public static Referencial__c findOrCreateReferencial(String name, String ref, Date startDate, Date endDate, Id rtId,
            Boolean publicGroup, Boolean queue, Boolean serviceTerritory,
            Boolean chatterGroup, Boolean toInsert) {

        Referencial__c[] referencial = [SELECT Name, RecordTypeId, KparKReference__c, startDate__c,
                endDate__c, publicGroup__c, queue__c, serviceTerritory__c,
                chatterGroup__c FROM Referencial__c WHERE KparKReference__c = :ref];

        if (referencial == null || referencial.size() < 1) {
            referencial.add(createReferencial(name, ref, startDate, endDate, rtId, publicGroup, queue,
                    serviceTerritory, chatterGroup, toInsert));
        }
        return referencial[0];
    }

    /********************** ACCOUNT OBJECT **********************/
    
    /**
    * @description Fonction de création d'un compte personnel
    * @param lastName Nom de famille 
    * @param firstName Pr?nom
    * @param addEmail Adresse mail pour le champ "PersonEmail"
    * @param rtId RecordTypeId du compte ? Créer
    * @param type Type du compte
    * @param canalPrefere Canal de communication de pRéférence
    * @param toInsert Définir à true pour insertion en base
    * @return Account Instance de l'objet compte
    */
    public static Account createAccount(String lastName, String firstName, String addEmail, Id rtId, String type, String canalPrefere, Boolean toInsert) {
        Account acc = new Account(Salutation = 'M.',
                                  FirstName = firstName,
                                  LastName = lastName,
                                  RecordTypeId = rtId,
                                  PersonMailingPostalCode = '12345',
                                  PersonMailingCity = 'City123',
                                  PersonMailingCountry = 'Country123',
                                  PersonEmail = addEmail,
                                  AccountSource = 'BAL VENDEUR',
                                  Type = type,
                                  canalPrefere__c = canalPrefere,
                                  accountCallSource__c = null,
                                  SIRET__c = 1234);

        if (toInsert) {
            insert acc;
        }
        return acc;
    }
    
    /**
    * @description Fonction de création d'un compte personnel avec d?finition du canal pr?f?r?
    * @param lastName Nom de famille 
    * @param firstName Pr?nom
    * @param addEmail Adresse mail pour le champ "PersonEmail"
    * @param rtId RecordTypeId du compte ? Créer
    * @param canalPrefere Canal de communication de pRéférence
    * @param toInsert Définir à true pour insertion en base
    * @return Account Instance de l'objet compte
    */
    public static Account createAccount(String lastName, String firstName, String addEmail, Id rtId, String canalPrefere, Boolean toInsert) {
        return createAccount(lastName, firstName, addEmail, rtId, null, canalPrefere, toInsert);
    }
    
    /**
    * @description Fonction de création d'un compte professionnel
    * @param name Nom 
    * @param phone Num?ro de t?l?phone du compte
    * @param rtId RecordTypeId du compte ? Créer
    * @param contact Id du contact par d?faut
    * @param type Type du compte
    * @param toInsert Définir à true pour insertion en base
    * @return Account Instance de l'objet compte
    */
    public static Account createAccountPro(String name, String phone, Id rtId, Id contact, String type, Boolean toInsert) {
        Account acc = new Account(Name = name,
                                  RecordTypeId = rtId,
                                  ShippingPostalCode = '12345',
                                  ShippingCity = 'City123',
                                  ShippingCountry = 'Country123',
                                  BillingPostalCode = '12345',
                                  BillingCity = 'City123',
                                  BillingCountry = 'Country123',
                                  AccountSource = 'CCM',
                                  Phone = phone,
                                  Type = type,
                                  contactParDefaut__c = contact,
                                  accountCallSource__c = null
                                  );

        if (toInsert) {
            insert acc;
        }
        return acc;
    }
    
    /**
    * @description Fonction de création d'un compte professionnel
    * @param name Nom 
    * @param phone Num?ro de t?l?phone du compte
    * @param rtId RecordTypeId du compte ? Créer
    * @param contact Id du contact par d?faut
    * @param toInsert Définir à true pour insertion en base
    * @return Account Instance de l'objet compte
    */
    public static Account createAccountPro(String name, String phone, Id rtId, Id contact, Boolean toInsert) {        
        return createAccountPro(name,phone,rtId,contact,null,toInsert);
    }
    
    /**
    * @description Fonction de création d'une entité (magasin, d?pot etc...)
    * @param name Nom
    * @param ref Référence de l'entité
    * @param startDate Date de d?but de validité
    * @param phone Num?ro de t?l?phone du compte
    * @param entityType Type de l'entité
    * @param toInsert Définir à true pour insertion en base
    * @return Account Instance de l'objet compte
    */
    public static Account createEntity(String name, String ref, Date startDate, String phone, Id entityType, Boolean toInsert) {
        Account acc = new Account(Name = name,
                                  RecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT),
                                  KparKReference__c = ref,
                                  ShippingPostalCode = '12345',
                                  ShippingCity = 'City123',
                                  ShippingCountry = 'Country123',
                                  BillingPostalCode = '12345',
                                  BillingCity = 'City123',
                                  BillingCountry = 'Country123',
                                  startDate__c = startDate,
                                  Phone = phone,
                                  entityType__c = entityType,
                                  RCSCity__c = 'Paris',
                                  RCSNumber__c = '12345',
                                  shareCapital__c = 12345,
                                  Ownership = 'SARL',
                                  SIRET__c = 1234,
                                  SIREN__c=1234);

        if (toInsert) {
            insert acc;
        }
        return acc;
    }
    
    /********************** CONTACT OBJECT **********************/
    
    public static Contact createContact(String lastName, String firstName, Boolean toInsert) {
        Contact co = new Contact(LastName = lastName,
                                 FirstName = firstName);
        if(toInsert) insert co;
        return co;
    }
    
    /********************** CHANTIER__c OBJECT **********************/

     /**
    * @description 
    * @param name 
    * @param prop 
    * @param autProp 
    * @param loca 
    * @param autLoca 
    * @param occp 
    * @param autOccp 
    * @param toInsert 
    * @param nbPortesEtFenetres
    * @return Chantier__c 
    */
    public static Chantier__c createChantier(String name, Id prop, Id autProp, Id loca, Id autLoca, Id occp, Id autOccp, Integer nbPortesEtFenetres,Boolean toInsert) {
        Chantier__c chantier = new Chantier__c(//rue__c = '1200 rue f?lix faure',
            codePostal__c = '76320',
            ville__c = 'Saint-Pierre les Elbeuf',
            pays__c = 'F',
            anneeConstruction__c = '2000',
            typeHabitation__c = 'Pavillon',
            typeResidence__c = 'Principale',
            Localisation__Latitude__s = 0,
            Localisation__Longitude__s = 0,
            iris__c = 'test',
            Name = name);
        if (prop != null) {
            chantier.proprietaire__c = prop;
        }
        if (autProp != null) {
            chantier.autreProprietaire__c = autProp;
        }
        if (loca != null) {
            chantier.locataire__c = loca;
        }
        if (autLoca != null) {
            chantier.autreLocataire__c = autLoca;
        }
        if (occp != null) {
            chantier.occupant__c = occp;
        }
        if (autOccp != null) {
            chantier.autreOccupant__c = autOccp;
        }
        chantier.nbPortesEtFenetres__c=nbPortesEtFenetres;

        if (toInsert) {
            insert chantier;
        }
        return chantier;
    }
    
    /**
    * @description 
    * @param name 
    * @param prop 
    * @param autProp 
    * @param loca 
    * @param autLoca 
    * @param occp 
    * @param autOccp 
    * @param toInsert 
    * @return Chantier__c 
    */
    public static Chantier__c createChantier(String name, Id prop, Id autProp, Id loca, Id autLoca, Id occp, Id autOccp, Boolean toInsert) {
        return createChantier(name, prop, autProp, loca, autLoca, occp, autOccp, 1, toInsert);
    }   
    
    /**
    * @description 
    * @param name 
    * @param prop
    * @param loca
    * @param toInsert
    * @return Chantier__c 
    */
    public static Chantier__c createChantier(String name, Id prop, Id loca, Boolean toInsert) {
        return createChantier(name, prop,loca,null,null,null,null,toInsert);
    }
    
    /**
    * @description 
    * @param name 
    * @param prop
    * @param toInsert
    * @return Chantier__c 
    */
    public static Chantier__c createChantier(String name, Id prop, Boolean toInsert) {
        return createChantier(name, prop,null,null,null,null,null,toInsert);
    }
    
    /********************** OPPORTUNITY OBJECT **********************/
    
    /**
    * @description Crée une opportunité pouvant ?tre associ?e ? 2 comptes et un chantier
    * @param name 
    * @param acc 
    * @param autreAcc 
    * @param cha 
    * @param toInsert 
    * @return Opportunity 
    */
    public static Opportunity createOpportunity(String name, Account acc, Account autreAcc, Chantier__c cha, Boolean toInsert) {
        Opportunity opp = new Opportunity(Name = name,
                                          AccountId = acc.Id,
                                          Type = 'Nouveau',
                                          StageName = 'Analyse',
                                          chantier__c = cha.Id,
                                          CloseDate = System.today() + 10,
                                          Probability = 10, Pricebook2Id = Test.getStandardPricebookId());
        if (autreAcc != null)
            opp.autreCompte__c = autreAcc.Id;
        opp.LeadSource = (acc.AccountSource != null) ? acc.AccountSource : ((autreAcc != null && autreAcc.AccountSource != null) ? autreAcc.AccountSource : 'JPO');
            opp.callSource__c = acc.accountCallSource__c != null ? acc.accountCallSource__c : ((autreAcc != null && autreAcc.accountCallSource__c != null) ? autreAcc.accountCallSource__c : null);
                
                if(toInsert) 
                insert opp;
        return opp;
    }
    
    /**
    * @description Crée une opportunité pouvant ?tre associ?e ? 2 comptes et un chantier
    * @param acc 
    * @param autreAcc 
    * @param cha 
    * @param toInsert 
    * @return Opportunity 
    */
    public static Opportunity createOpportunity(Account acc, Account autreAcc, Chantier__c cha, Boolean toInsert) {
        return createOpportunity('PRJ - Test', acc, autreAcc, cha, toInsert);
    }

     /**
     * @description Crée une opportunité pouvant ?tre associ?e ? 2 comptes et un chantier avec le pricebook d?fini
     * @param acc
     * @param autreAcc
     * @param cha
     * @param pricebookId
     * @param toInsert
     *
     * @return opportunité créée
     */
    public static Opportunity createOpportunityWithPricebook(Account acc, Account autreAcc, Chantier__c cha, Id pricebookId, Boolean toInsert) {
        Opportunity op = createOpportunity('PRJ - Test', acc, autreAcc, cha, toInsert);
        op.Pricebook2Id = pricebookId;
        if (toInsert) update op;
        return op;
    }

    /**
    * @description Crée une opportunité pouvant ?tre associ?e à un compte et un chantier
    * @param acc 
    * @param cha 
    * @param toInsert 
    * @return Opportunity 
    */
    public static Opportunity createOpportunity(Account acc, Chantier__c cha, Boolean toInsert) {
        return createOpportunity(acc, null, cha,toInsert);
    }
    
    /**
    * @description Crée une opportunité pouvant ?tre associ?e à un compte, un chantier et une op?ration
    * @param name 
    * @param acc 
    * @param autreAcc 
    * @param cha
    * @param operationId
    * @param toInsert 
    * @return Opportunity 
    */
    public static Opportunity createOpportunity(String name, Account acc, Account autreAcc, Chantier__c cha, Id operationId, Boolean toInsert)
    {
        Opportunity opp = createOpportunity(name, acc, autreAcc, cha, false);
        opp.operation__c = operationId;
        if(toInsert) insert opp;
        return opp;
    }
    
    /********************** EMAILMESSAGE OBJECT **********************/
    
    // Create Email Message
    public static EmailMessage createEmailMessage(boolean isInsert, String fromAddress, String toAddress, String subject, String textBody, String parentId) {
        EmailMessage email = new EmailMessage( incoming = true,
                                              fromAddress = fromAddress,
                                              toAddress= toAddress,
                                              subject = subject,
                                              textBody = textBody,
                                              HtmlBody = textBody,
                                              parentId = parentId);
        if(isInsert) {
            insert email;
        }
        return email;
    }
    
    /********************** CASE OBJECT **********************/
    
    public static Case createCase(Id rtId, Account acc, Id contactId, Id chantier, Boolean toInsert) {
        Case req = new Case(AccountId = acc.Id, 
                            chantier__c = chantier,
                            ContactId = contactId);
        if(rtId != null) req.RecordTypeId = rtId;
        
        if(toInsert) insert req;
        return req;
    }
    
    /**
    * @description Crée une requ?te associ?e à un compte et un chantier
    * @param rtId 
    * @param acc 
    * @param chantier 
    * @param toInsert 
    * @return Case Requ?te créée 
    */
    public static Case createCase(Id rtId, Account acc, Id chantier, Boolean toInsert) {
        return createCase(rtId,acc,acc.PersonContactId,chantier,toInsert);
    }
    
    /**
    * @description Crée une requ?te associ?e à un compte et un chantier. D?finit les champs de type
    * @param recordtype
    * @param acc
    * @param chantier
    * @param typeDemande
    * @param typeRDV
    * @param motif
    * @param toInsert 
    * @return Case Requ?te créée 
    */
    public static Case createCase(Id recordtype, Account acc, Id chantier, String typeDemande, String typeRDV, String motif, Boolean toInsert)
    {
        Case req = createCase(recordType, acc, chantier, false);
        req.Type = typeDemande;
        if(typeRDV != null) req.typeDeRendezVous__c = typeRDV;
        if(motif != null) req.motif__c = motif;
        
        if(toInsert) insert req;
        return req;
    }
    
    /**
    * @description Crée une requ?te associ?e à un compte et un chantier
    * @param recordtype 
    * @param acc 
    * @param chantier 
    * @param toInsert 
    * @return Case Requ?te créée 
    */
    public static Case createCase(Id recordtype, Account acc, Id chantier, String typeDemande, String typeRDV, String motif, 
                                  String origin, String description, Boolean toInsert) 
    {
        Case req = createCase(recordType, acc, chantier, typeDemande, typeRDV, motif, false);
        req.Origin = origin;
        req.Description = description;
        
        if(toInsert) insert req;
        return req;
    }
    
    public static Case createCase(Id recordtype, Account acc, Id chantier, String typeDemande, String typeRDV, String motif, 
                                  String origin, String description) 
    {
        return createCase(recordType, acc, chantier, typeDemande, typeRDV, motif, origin, description, true);
    }
    
    /**
    * @description Crée une requ?te associ?e ? un contact
    * @param recordtype 
    * @param contactId 
    * @param toInsert 
    * @return Case Requ?te créée 
    */
    public static Case createCaseWithContact(Id recordtype, Id contactId, Boolean toInsert) {
        Case req = new Case(ContactId = contactId);
        if(recordType != null) req.RecordTypeId = recordtype;
        
        if(toInsert) insert req;
        return req;
    }
    
    /********************** EVENT OBJECT **********************/
    
    /**
    * @description 
    * @param type 
    * @param rtId 
    * @param what 
    * @param who
    * @param ownerId
    * @param statutRDV
    * @param activityDate 
    * @param start 
    * @param end 
    * @param toInsert 
    * @return Event 
    */
    public static Event createEvent(String type, Id rtId, Id what, Id who, Id ownerId, String statutRDV, 
                                    Date activityDate, Datetime debut, Datetime fin, String loc, Boolean toInsert) 
    {
        Event evt = new Event(RecordTypeId = rtId,
                              Type = type,
                              ActivityDate = activityDate,
                              StartDateTime = debut,
                              EndDateTime = fin,
                              WhatId = what,
                              WhoId = who,
                              couplePresent__c = 'Oui',
                              decisionnaire__c = true,
                              statutRDV__c = statutRDV,
                              Location = loc);
        if(ownerId != null) evt.OwnerId = ownerId;
        if(statutRDV == 'Effectué') evt.resultatDuRDV__c = 'Devisable';
        
        if(toInsert) 
            insert evt;
        return evt;
    }
    
    /**
    * @description 
    * @param type 
    * @param rtId 
    * @param what 
    * @param who
    * @param ownerId
    * @param statutRDV
    * @param toInsert 
    * @return Event 
    */
    public static Event createEvent(String type, Id rtId, Id what, Id who, Id ownerId, String statutRDV, Boolean toInsert) {
        return createEvent(type, rtid, what, who, ownerId, statutRDV, System.today(), System.now(), System.now(), null, toInsert);
    }
    
    /**
    * @description 
    * @param type 
    * @param rtId 
    * @param what 
    * @param who
    * @param ownerId
    * @param toInsert
    * @return Event 
    */
    public static Event createEvent(String type, Id rtId, Id what, Id who, Id ownerId, Boolean toInsert) {
        return createEvent(type, rtId, what, who, ownerId, 'Effectué', toInsert);
    }
    
    /**
    * @description 
    * @param type 
    * @param rtId 
    * @param what 
    * @param who 
    * @param ownerId
    * @param statutRDV
    * @param nbBAL50 
    * @param NbTAP51 
    * @param NbPhone55 
    * @param toInsert 
    * @return Event 
    */
    public static Event createEvent(String type, Id rtId, Id what, ID who, Id ownerId, String statutRDV, 
                                    Integer nbBAL50, Integer NbTAP51, Integer NbPhone55, Boolean toInsert) 
    {
        Event evt = createEvent(type, rtId, what, who, ownerId, statutRDV, false);
        evt.nbBAL50__c = nbBAL50;
        evt.NbTAP51__c = NbTAP51;
        evt.NbPhone55__c = NbPhone55;
        
        if(toInsert) 
            insert evt;
        return evt;
    }
    
    // Fonction de création d'?v?nements
    public static Event createEvent(Id what, Account demandeur, String typeRDV, String statutRDV, String rt, String loc, Boolean toInsert) {
        return Utils_Test.createEvent(typeRDV, rt, what, demandeur.PersonContactId, null, statutRDV, System.today(), System.now(), System.now().addHours(2), loc, toInsert);
    }
    
    
    /********************** QUOTE OBJECT **********************/    
    
    /**
    * @description Crée un devis attaché à une opportunité et ? une op?ration
    * @param name
    * @param rtId
    * @param opp
    * @param status
    * @param operationId
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static Quote createQuote(String name, Id rtId, Opportunity opp, String status, Date dateDevis, Integer totalTTC, Integer acompteAttendu, 
                                    String source, Id operationId, Boolean toInsert) {
                                        Quote devis = new Quote(OpportunityId = opp.Id,
                                                                Pricebook2Id = Test.getStandardPricebookId(),
                                                                Name = name,
                                                                dateDevis__c = dateDevis,
                                                                referenceDate__c = dateDevis,
                                                                compte__c = opp.AccountId,
                                                                source__c = source,
                                                                typeContrat__c = Constants.QUOTE_TYPECONTRAT_STANDARD,
                                                                moyenTransmissionClient__c = 'Par email',
                                                                autreCompte__c = opp.autreCompte__c,
                                                                modeFinancement__c = 'PAIEMENT COMPTANT',
                                                                total_TTC_devis__c = totalTTC,
                                                                mntAcompteAttendu__c = acompteAttendu,
                                                                operation__c = operationId);
                                        
                                        if(rtId != null) 
                                            devis.RecordTypeId = rtId;
                                        if(String.isNotBlank(status)) {
                                            devis.Status = status;
                                            devis.forcageEtat__c = status;
                                        }
                                        
                                        if(toInsert) 
                                            insert devis;
                                        return devis;
                                    }
    
    /**
    * @description Crée un devis attaché à une opportunité avec une date de devis
    * @param name
    * @param rtId RecordTypeId, mettre ? null pour ne pas le d?finir
    * @param opp
    * @param status Statut du devis. Mettre ? null pour ne pas le d?finir, si dif?rent de null on force l'?tat.
    * @param dateDevis
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static Quote createQuote(String name, Id rtId, Opportunity opp, String status, Date dateDevis, Boolean toInsert) {
        return createQuote(name, rtId, opp, status, dateDevis, 50, 50, null, null, toInsert);
    }
    
    /**
    * @description Crée un devis attaché à une opportunité avec une date de devis et un totalTTC
    * @param name
    * @param rtId RecordTypeId, mettre ? null pour ne pas le d?finir
    * @param opp
    * @param status Statut du devis. Mettre ? null pour ne pas le d?finir, si dif?rent de null on force l'?tat.
    * @param dateDevis
    * @param totalTTC
    * @param acompteAttendu
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static Quote createQuote(String name, Id rtId, Opportunity opp, String status, Date dateDevis, 
                                    Integer totalTTC, Integer acompteAttendu, Boolean toInsert) 
    {
        return createQuote(name, rtId, opp, status, dateDevis, totalTTC, acompteAttendu, Constants.CONTACT_SOURCE_BAL, null, toInsert);
    }
    
    /**
    * @description Crée un devis attaché à une opportunité.
    * @param rtId
    * @param opp
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static Quote createQuote(Id rtId, Opportunity opp, Boolean toInsert) {
        return createQuote('Devis test', rtId, opp, null, Date.today(), 50, 10, null, null, toInsert);
    }
    
    /********************** CPQ QUOTE OBJECT **********************/    

    /**
    * @description Crée un devis attaché à une opportunité et ? une op?ration
    * @param name
    * @param rtId
    * @param opp
    * @param status
    * @param operationId
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static SBQQ__Quote__c createCPQQuote (String name, Id rtId, Opportunity opp, String status, Date dateDevis, Integer totalTTC, Integer acompteAttendu, 
                                                 String source, Id operationId, Boolean toInsert) 
    {
        List<Referencial__c> financialRefList = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];
        String financialRef = (financialRefList.isEmpty()) ? null : financialRefList[0].Id;

        List<Referencial__c> sourceRefList = [SELECT Id FROM Referencial__c WHERE Name = :source];
        String sourceRef = (sourceRefList.isEmpty()) ? null : sourceRefList[0].Id;

        SBQQ__Quote__c devis = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,
                                                // Pricebook2Id = Test.getStandardPricebookId(),
                                                NomDevis__c = name,
                                                CreatedDate__c = dateDevis,
                                                dateDevis__c = dateDevis,
                                                referenceDate__c = dateDevis,
                                                SBQQ__Account__c = opp.AccountId,
                                                sourceRef__c = sourceRef,
                                                moyenTransmissionClient__c = 'Par email',
                                                autreCompte__c = opp.autreCompte__c,
                                                chantier__c = opp.chantier__c,
                                                financingMethod__c = financialRef,
                                                TotalTTCDevis__c = totalTTC,
                                                MontantAcompteAttendu__c = acompteAttendu,
                                                SBQQ__Primary__c = true,
                                                AmendmentQuote__c = false,
                                                SBQQ__PricebookId__c = Test.getStandardPricebookId(),
                                                SBQQ__ExpirationDate__c = Date.today().addDays(14),
                                                operation__c = operationId);

        if(rtId != null) 
            devis.RecordTypeId = rtId;
        if(String.isNotBlank(status)) {
            devis.SBQQ__Status__c = status;
            devis.statusFixed__c = status;
        }

        if(toInsert) 
            insert devis;
        return devis;
    }    
    
    /**
    * @description Crée un devis attaché à une opportunité et ? une op?ration
    * @param name
    * @param rtId
    * @param opp
    * @param status
    * @param operationId
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static SBQQ__Quote__c createCPQQuote(Opportunity opp,Date dateDevis,Integer acompteAttendu, Boolean toInsert) {
        String nom = 'Devis ' + dateDevis.year() + '-' + dateDevis.month() + '-' + dateDevis.day();
        return createCPQQuote(nom, null, opp, null, dateDevis, null, acompteAttendu, null, null, toInsert);
    }

    /**
    * @description Crée un devis attaché à une opportunité avec une date de devis et un totalTTC
    * @param name
    * @param rtId RecordTypeId, mettre ? null pour ne pas le d?finir
    * @param opp
    * @param status Statut du devis. Mettre ? null pour ne pas le d?finir, si dif?rent de null on force l'?tat.
    * @param dateDevis
    * @param totalTTC
    * @param acompteAttendu
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static SBQQ__Quote__c createCPQQuote(String name, Id rtId, Opportunity opp, String status, Date dateDevis, 
                                                Integer totalTTC, Integer acompteAttendu, Boolean toInsert) 
    {
        return createCPQQuote(name, rtId, opp, status, dateDevis, totalTTC, acompteAttendu, null, null, toInsert);
    }
    
    /**
    * @description Crée un devis attaché à une opportunité avec une date de devis
    * @param opp
    * @param status Statut du devis. Mettre ? null pour ne pas le d?finir, si dif?rent de null on force l'?tat.
    * @param dateDevis
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static SBQQ__Quote__c createCPQQuote(Opportunity opp,Date dateDevis, Boolean toInsert) {
        return createCPQQuote(opp, dateDevis, 50,toInsert);
    }
    
    /**
    * @description Crée un devis attaché à une opportunité.
    * @param opp
    * @param toInsert Définir à true pour insertion en base
    * @return Quote Instance du devis
    */
    public static SBQQ__Quote__c createCPQQuote(Opportunity opp, Boolean toInsert) {
        return createCPQQuote(opp,Date.today(), 50,toInsert);
    }
    
    /********************** PRODUCT2 OBJECT **********************/
    
    /**
    * @description Crée un produit
    * @param name
    * @param codeProduit
    * @param toInsert Définir à true pour insertion en base
    * @return Product2 Instance du produit
    */
    public static Product2 createProduct(String name, String codeProduit, Boolean toInsert) 
    {
        Product2 produit = new Product2 (Name = name, 
                                         ProductCode = codeProduit, 
                                         Reference__c = codeProduit, 
                                         productType__c = 'Carpentry', 
                                         IsActive = true);
        
        if(toInsert) 
            insert produit;
        return produit;
    }
    
    public static Product2 createProduct(String name, String codeProduit) {
        return createProduct(name, codeProduit, true);
    }
    
    /**
    * @description Crée un produit et remplit les champs Famille et SousFamille
    * @param name
    * @param codeProduit
    * @param famille
    * @param sousFamille
    * @param larMinimumvantail1 Largeur minimal du produit si 1 vantail
    * @param longMinimumvantail1 Longueur minimal du produit si 1 vantail
    * @param toInsert Définir à true pour insertion en base
    * @return Product2 Instance du produit
    */
    public static Product2 createProduct(String name, String codeProduit, String famille, String sousFamille, 
                                         Integer larMinimumvantail1, Integer longMinimumvantail1, Boolean toInsert) 
    {
        Product2 produit = createProduct(name, codeProduit, false);
        produit.Family = famille; 
        produit.SousFamille__c = sousFamille; 
        produit.Largeurminimum1vantail__c = larMinimumvantail1;
        produit.Longueurminimum1vantail__c = longMinimumvantail1;
        if(toInsert) 
            insert produit;
        return produit;
    }
    
    public static Product2 createProduct(String name, String code, String fam, String sFam) {
        return createProduct(name, code, fam, sFam, 50, 50,true);
    }

    public static Product2 createOneTimeProduct(String name, String codeProduit, String famille, String sousFamille,
            Integer larMinimumvantail1, Integer longMinimumvantail1, Boolean toInsert) {
        Product2 produit = new Product2(
                Name = name,
                ProductCode = codeProduit,
                Reference__c= codeProduit,
                IsActive = true,
                Family = famille,
                SousFamille__c = sousFamille,
                Largeurminimum1vantail__c = larMinimumvantail1,
                Longueurminimum1vantail__c = longMinimumvantail1,
                SBQQ__ChargeType__c = 'One-Time',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__ConfigurationType__c = 'Allowed',
                SBQQ__ConfigurationEvent__c= 'Always',
                isControllable__c = true,
                isConvertibleAsset__c = true);
        if (toInsert) insert produit;
        return produit;
    }
    
    /********************** TVA_Produit__c OBJECT **********************/
    
    /**
    * @description Crée une Référence de TVA pour un produit
    * @param produit Id du produit
    * @param dateDebut Date de d?but de prise en compte de la TVA
    * @param taux Taux de la TVA en pourcentage
    * @param idTiers Id externe de la TVA pour import
    * @param toInsert Définir à true pour insertion en base
    * @return TVA_Produit__c Instance de l'objet TVA Produit
    */
    public static TVA_Produit__c createTVAProduit(String produit, Date dateDebut, Decimal taux, String idTiers, Boolean toInsert) {
        TVA_Produit__c tvp = new TVA_Produit__c (produit__c = produit, 
                                                 datedebut__c = dateDebut,
                                                 idTiers__c = idTiers, 
                                                 type__c = 'Menuiserie',
                                                 taux__c = taux);
        if(toInsert) 
            insert tvp;
        return tvp;
    }
    
    /********************** PRICEBOOK ENTRY OBJECT **********************/
    
    /**
    * @description Crée une pricebook entry ? partir d'un produit
    * @param productId
    * @param toInsert Définir à true pour insertion en base
    * @return Product2 Instance du produit
    */
    public static PricebookEntry createPricebookEntry(Id productId, Boolean toInsert) {
        Id pb = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb, 
                                                Product2Id = productId, 
                                                IsActive = true, 
                                                UnitPrice = 10.0, 
                                                UseStandardPrice = false);
        
        if(toInsert)
            insert pbe;
        return pbe;
    }

    /********************** QuoteLineItem OBJECT **********************/
    
    /**
    * @description Crée une ligne de devis associ?e ? la pricebookEntry pass?e en param?tre.
    * @param quoteId
    * @param nombrevantaux
    * @param largeur
    * @param hauteur
    * @param qte
    * @param prixHorsdimension
    * @param unitprix
    * @param pricbookentryId
    * @param toInsert Définir à true pour insertion en base
    * @return QuoteLineItem Instance de l'objet QuoteLineItem
    */
    public static QuoteLineItem createQuoteLineItem(Id quoteId, String nombrevantaux, Integer largeur, Integer hauteur, Integer qte, 
                                                    Decimal prixHorsdimension, Decimal unitprix, Id pricbookentryId, Boolean toInsert) 
    {
        QuoteLineItem c = new QuoteLineItem(QuoteId = quoteId,
                                            Nombredevantaux__c = nombrevantaux,
                                            Hauteur__c = hauteur,
                                            Largeur__c = largeur,
                                            Quantity = qte,
                                            Tarifhorsdimension__c = prixHorsdimension,
                                            PricebookEntryId = pricbookentryId,
                                            UnitPrice = unitprix,
                                            TVA__c = '5%',
                                            TVApourcentage__c = 5.5,
                                            eligibleCEE__c = true);
        
        if(toInsert) 
            insert c;
        return c;
    }
    
    /**
    * @description Crée une ligne de devis en r?cup?rant la pricebookEntry standard du produit pass? en param?tre.
    * @param quoteId
    * @param nombrevantaux
    * @param largeur
    * @param hauteur
    * @param qte
    * @param prixHorsdimension
    * @param unitprix
    * @param productId
    * @param toInsert Définir à true pour insertion en base
    * @return QuoteLineItem Instance de l'objet QuoteLineItem
    */
    public static QuoteLineItem createQuoteLineItem(Id quoteId, String nombrevantaux, Integer largeur, Integer hauteur, Integer qte, 
                                                    Decimal prixHorsdimension, Decimal unitprix, Product2 product, Boolean toInsert) 
    {
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pbId AND Product2Id = :product.Id];
        return createQuoteLineItem(quoteId, nombrevantaux, largeur, hauteur, qte, prixHorsdimension, unitprix, pbe.Id, toInsert);
    }
    
    /**
    * @description Crée une ligne de devis, un produit et une pricebookEntry sont ?galement cr??s et associ?s ? la ligne de devis.
    * @param quoteId 
    * @param nombrevantaux 
    * @param largeur 
    * @param hauteur
    * @param qte
    * @param prixHorsdimension
    * @param unitprix
    * @param toInsert Définir à true pour insertion en base
    * @return QuoteLineItem Instance de l'objet QuoteLineItem
    */
    public static QuoteLineItem createQuoteLineItem(Id quoteId, String nombrevantaux, Integer largeur, Integer hauteur, Integer qte, 
                                                    Decimal prixHorsdimension, Decimal unitprix, Boolean toInsert) 
    {
        Product2 product2 = createProduct('Produit Test', 'FFFETT');
        PricebookEntry pbe = createPricebookEntry(product2.Id,true);
        
        return createQuoteLineItem(quoteId, nombrevantaux, largeur, hauteur, qte, prixHorsdimension, unitprix, pbe.Id, toInsert);
    }

    /********************** CPQ QuoteLineItem OBJECT **********************/
    
    /**
    * @description Crée une ligne de devis associ?e ? la pricebookEntry pass?e en param?tre.
    * @param quoteId
    * @param largeur
    * @param hauteur
    * @param qte
    * @param product
    * @param toInsert Définir à true pour insertion en base
    * @return QuoteLineItem Instance de l'objet QuoteLineItem
    */
    public static SBQQ__QuoteLine__c createCPQQuoteLineItem(Id quoteId,Integer largeur, Integer hauteur, Integer qte, Product2 product, Boolean toInsert)
    {
        SBQQ__QuoteLine__c c = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteId,
                Hauteur__c = hauteur,
                Largeur__c = largeur,
                SBQQ__Product__c = product.id,
                productType__c = 'Carpentry',
                SBQQ__Quantity__c = qte);
        
        if(toInsert) 
            insert c;
        return c;
    }
    
    
    /**
    * @description Crée une ligne de devis, un produit et une pricebookEntry sont ?galement cr??s et associ?s ? la ligne de devis.
    * @param quoteId 
    * @param largeur 
    * @param hauteur
    * @param qte
    * @param toInsert Définir à true pour insertion en base
    * @return QuoteLineItem Instance de l'objet QuoteLineItem
    */
    public static SBQQ__QuoteLine__c createCPQQuoteLineItem(Id quoteId,Integer largeur, Integer hauteur, Integer qte,Boolean toInsert) 
    {
        Product2 product2 = createProduct('Produit Test', 'FFFETT');
        return createCPQQuoteLineItem(quoteId,largeur, hauteur, qte,product2, toInsert);
    }
    
    /********************** CPQ OPTION OBJECT **********************/
    
    /**
    * @description Crée une option associ?e ? la ligne de devis dont l'Id est pass? en param?tre
    * @param qliId Id de la ligne de devis ? associer
    * @param codeOption Code de l'option de la ligne de devis
    * @param libelleOption Libell? de l'option de la ligne de devis
    * @param refOptId Id de la r?f?nrece de l'option (ReferentielOptions__c)
    * @param prixunitaireHT Prix unitaire HT de l'option
    * @param toInsert Définir à true pour insertion en base
    * @return Option__c Instance de l'option
    */
    public static SBQQ__QuoteLine__c createCPQOption(Id qliId,Id quoteId,Integer largeur, Integer hauteur, Integer qte,Product2 product,Boolean toInsert) {
        SBQQ__QuoteLine__c option = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c = qliId,
                                                           SBQQ__Quote__c = quoteId,
                                                           Hauteur__c = hauteur,
                                                           Largeur__c = largeur,
                                                           SBQQ__Product__c = product.id,
                                                           productType__c = 'Carpentry',
                                                           SBQQ__Quantity__c = qte);
        
        if(toInsert) insert option;
        return option;
    }
    
    /********************* OPTION__c OBJECT **********************/
    
    /**
    * @description Crée une option associ?e ? la ligne de devis dont l'Id est pass? en param?tre
    * @param qliId Id de la ligne de devis ? associer
    * @param codeOption Code de l'option de la ligne de devis
    * @param libelleOption Libell? de l'option de la ligne de devis
    * @param refOptId Id de la r?f?nrece de l'option (ReferentielOptions__c)
    * @param prixunitaireHT Prix unitaire HT de l'option
    * @param toInsert Définir à true pour insertion en base
    * @return Option__c Instance de l'option
    */
    public static Option__c createOption(Id qliId, String codeOption, String libelleOption, Id refOptId, Decimal prixunitaireHT, Boolean toInsert) {
        Option__c option = new Option__c(lignedevis__c = qliId, 
                                         prixunitaireHT__c = prixunitaireHT, 
                                         codeoption__c = codeOption, 
                                         libelleoption__c = libelleOption,
                                         Quantite__c = 1,
                                         option__c = refOptId);
        
        if(toInsert) insert option;
        return option;
    }
    
    
    /********************** ReferentielOptions__c OBJECT **********************/
    
    /**
    * @description Crée un référentiel options
    * @param name Nom de l'option 
    * @param libelle Libell? de l'option
    * @param codeOption 
    * @param typeOption 
    * @param toInsert Définir à true pour insertion en base
    * @return ReferentielOptions__c
    */
    public static ReferentielOptions__c createRefOption(String name, String libelle, String codeOption, Double typeOption, Boolean toInsert) {
        ReferentielOptions__c option = new ReferentielOptions__c(Name=name,
                                                                 codeOption__c = codeOption, 
                                                                 typedeloption__c = typeOption, 
                                                                 libelleOption__c = libelle,
                                                                 actif__c = true);
        if(toInsert) insert option;
        return option;
    }
    
    /********************** PACK__c OBJECT **********************/
    
    /**
    * @description Crée un référentiel options
    * @param codePereId 
    * @param codeFilsId 
    * @param typeRegroupement 
    * @param revisionId
    * @param toInsert Définir à true pour insertion en base
    * @return Pack__c
    */
    public static Pack__c createPack(Id codePereId, Id codeFilsId, Integer typeRegroupement, Id revisionId, Boolean toInsert) {
        Pack__c p = new Pack__c();
        p.CodePere__c = codePereId;
        p.CodeFils__c = codeFilsId;
        p.TypeRegroupement__c = typeRegroupement;
        p.IDRevision__c = revisionId;
        
        if(toInsert) 
            insert p;
        return p;
    }
    
    public static Pack__c createPack(Id codePereId, Id codeFilsId, Integer typeRegroupement, Id revisionId) {
        return createPack(codePereId, codeFilsId, typeRegroupement, revisionId, true);
    }
    
    /********************** FAMILLES__c OBJECT **********************/
    
    /**
    * @description Crée une famille de produit dans le custom setting "Famille"
    * @param Name nom technique de la famille
    * @param libelle Libell? de la famille
    * @param code Code technique de la famille
    * @param toInsert Définir à true pour insertion en base
    * @return Familles__c
    */
    public static Familles__c createFamilles(String name, String libelle, String code, Boolean toInsert) {
        Familles__c famille = new Familles__c(Name = name, libelle__c = libelle, code__c = code);
        if(toInsert) insert famille;
        return famille;
    }
    
    /********************** SOUSFAMILLES__c OBJECT **********************/
    
    /**
    * @description Crée une sous famille de produit dans le custom setting "Sous Famille"
    * @param Name nom technique de la sous famille
    * @param libelle Libell? de la sous famille
    * @param code Code technique de la sous famille
    * @param famillyName nom technique de la famille parent
    * @param toInsert Définir à true pour insertion en base
    * @return SousFamilles__c
    */
    public static SousFamilles__c createSousFamilles(String name, String libelle, String code, String famillyName, Boolean toInsert) {
        SousFamilles__c ssfamille = new SousFamilles__c(Name = name, libelle__c = libelle,
                                                        famille__c = famillyName, code__c = code);
        if(toInsert) insert ssfamille;
        return ssfamille;
    }
    
    /********************** MATIERES__c OBJECT **********************/
    
    /**
    * @description Crée une mati?re de produit dans le custom setting "Mati?res"
    * @param Name nom technique de la mati?re
    * @param libelle Libell? de la mati?re
    * @param code Code technique de la mati?re
    * @param toInsert Définir à true pour insertion en base
    * @return Matieres__c
    */
    public static Matieres__c createMatieres(String name, String libelle, String code, Boolean toInsert) {
        Matieres__c mat = new Matieres__c(Name = name, libelle__c = libelle, code__c = code);
        if(toInsert) insert mat;
        return mat;
    }
    
    /********************** SOUSMATIERES__c OBJECT **********************/
    
    /**
    * @description Crée une sous mati?re de produit dans le custom setting "Sous Mati?res"
    * @param Name nom technique de la sous mati?re
    * @param libelle Libell? de la sous mati?re
    * @param code Code technique de la sous mati?re
    * @param matiereName nom technique de la famille parent
    * @param toInsert Définir à true pour insertion en base
    * @return SousMatieres__c
    */
    public static SousMatieres__c createSousMatieres(String name, String libelle, String code, String matiereName, Boolean toInsert) {
        SousMatieres__c sousMat = new SousMatieres__c(Name = name, libelle__c = libelle, code__c = code,matiere__c=matiereName);
        if(toInsert) insert sousMat;
        return sousMat;
    }
    
    /********************** COEFFTH__c OBJECT **********************/
    
    /**
    * @description Crée un coefficient thermique pour un produit
    * @param famille Id du produit
    * @param option1 Id de l'option 1 du produit
    * @param coef1 Nom du coeffcient de l'option 1
    * @param valeurCoef1 Valeur du coefficient de l'option 1
    * @param unite1 Unit? du co?fficient de l'option 1
    * @param option2 Id de l'option 2 du produit
    * @param coef2 Nom du coeffcient de l'option 2
    * @param valeurCoef2 Valeur du coefficient de l'option 2
    * @param unite2 Unit? du co?fficient de l'option 2
    * @param idTiers Id externe du coefficient
    * @param toInsert Définir à true pour insertion en base
    * @return coeffTh__c
    */
    public static coeffTh__c createCoeffTh(String famille, String option1, String coef1, Double valeurCoef1,  String unite1, 
                                           String option2, String coef2, Double valeurCoef2, String unite2, String idTiers, Boolean toInsert) {
                                               
                                               coeffTh__c coef = new coeffTh__c(dateDebut__c = Date.today().addDays(-1), 
                                                                                famille__c = famille, 
                                                                                option1__c = option1, 
                                                                                option2__c = option2,
                                                                                coef1__c=coef1, 
                                                                                valeurCoef1__c=valeurCoef1, 
                                                                                unite1__c=unite1, 
                                                                                coef2__c=coef2, 
                                                                                valeurCoef2__c=valeurCoef2, 
                                                                                unite2__c=unite2, 
                                                                                idTiers__c=idTiers);
                                               if(toInsert) insert coef;
                                               return coef;
                                           }
    
    /**
    * @description Crée un coefficient thermique pour un produit
    * @param famille Id du produit
    * @param option1 Id de l'option 1 du produit
    * @param coef1 Nom du coeffcient de l'option 1
    * @param valeurCoef1 Valeur du coefficient de l'option 1
    * @param unite1 Unit? du co?fficient de l'option 1
    * @param idTiers Id externe du coefficient
    * @param toInsert Définir à true pour insertion en base
    * @return coeffTh__c
    */
    public static coeffTh__c createCoeffTh(String famille, String option1, String coef1, Double valeurCoef1, String unite1, String idTiers, Boolean toInsert) {
        return createCoeffTh(famille,option1,coef1,valeurCoef1,unite1,null,null,null,null,idTiers,toInsert);
    }
    
    /********************** CATEGORIE CEE OBJECT **********************/
    
    /**
    * @description Crée une cat?gorie CEE.
    * @param debutValidite
    * @param finValidite
    * @param nbPersonnes
    * @param zone
    * @param pivotAB
    * @param pivotBC
    * @param toInsert Définir à true pour insertion en base
    * @return CEE_Categorie__c Instance de l'objet CEE_Categorie__c
    */
    public static CEE_Categorie__c createCEECategorie(Date debutValidite, Date finValidite, Integer nbPersonnes, String zone, Integer pivotAB, 
                                                      Decimal pivotBC, Boolean toInsert) 
    {
        CEE_Categorie__c c = new CEE_Categorie__c(debutValidite__c = debutValidite,
                                                  finValidite__c = finValidite,
                                                  nbPersonnes__c = nbPersonnes,
                                                  zone__c = zone,
                                                  pivotAB__c = pivotAB,
                                                  pivotBC__c = pivotBC);
        
        if(toInsert) 
            insert c;
        return c;
    }
    
    /********************** PRIME CEE OBJECT **********************/
    
    /**
    * @description Crée une prime CEE.
    * @param debutValidite
    * @param finValidite
    * @param categorie
    * @param zone
    * @param produit
    * @param montant
    * @param toInsert Définir à true pour insertion en base
    * @return CEE_Prime__c Instance de l'objet CEE_Prime__c
    */
    public static CEE_Prime__c createCEEPrime(Date debutValidite, Date finValidite, String categorie, String zone, String produit, 
                                              Decimal montant, Boolean toInsert) 
    {
        CEE_Prime__c c = new CEE_Prime__c(dateDebutValidite__c = debutValidite,
                                          dateFinValidite__c = finValidite,
                                          categorie__c = categorie,
                                          zone__c = zone,
                                          produit__c = produit,
                                          montant__c = montant);
        
        if(toInsert) 
            insert c;
        return c;
    }
    
    /********************** KCONTRAT__c OBJECT **********************/
    
    /**
    * @description Crée un contrat rattach? à un compte et un chantier
    * @param name 
    * @param chantierId 
    * @param compteId 
    * @param numContrat 
    * @param toInsert Définir à true pour insertion en base
    * @return KContrat__c Instance de l'objet KContrat
    */
    public static KContrat__c createContrat(String name, Id chantierId, Id compteId, String numContrat, Boolean toInsert) {
        KContrat__c contrat = new KContrat__c (Name = name,
                                               chantier__c = chantierId,
                                               compte__c = compteId,
                                               numeroContrat__c=numContrat);
        if(toInsert) insert contrat;
        return contrat;
    }
    
    /**
    * @description Crée un contrat rattach? à un compte et un chantier
    * @param name 
    * @param chantierId 
    * @param compteId 
    * @param numContrat 
    * @param toInsert Définir à true pour insertion en base
    * @return KContrat__c Instance de l'objet KContrat
    */
    public static KContrat__c createContrat(String name, Id chantierId, Id compteId, String numContrat, 
                                            Date prochainMetrage, Date prochaineInstallation, Date prochainSAV, Boolean toInsert) {
                                                KContrat__c contrat = new KContrat__c (Name = name,
                                                                                       chantier__c = chantierId,
                                                                                       compte__c = compteId,
                                                                                       numeroContrat__c=numContrat,
                                                                                       prochainMetrage__c = prochainMetrage,
                                                                                       prochaineInstallation__c = prochaineInstallation,
                                                                                       prochainSAV__c = prochainSAV);
                                                if(toInsert) insert contrat;
                                                return contrat;
                                            }
    
    /**
    * @description Crée un contrat rattaché à un devis, le compte du contrat devient celui du devis
    * @param devis 
    * @param toInsert Définir à true pour insertion en base
    * @return KContrat__c Instance de l'objet KContrat
    */
    public static KContrat__c createContrat(Quote devis, Boolean toInsert) {
        KContrat__c contrat = new KContrat__c();
        contrat.compte__c = devis.compte__c;
        contrat.autreCompte__c = devis.autreCompte__c;
        contrat.devis__c = devis.id;
        contrat.montantECS__c = -50;
        contrat.montantHT__c = 5000;
        contrat.montantTTC__c = 7000;
        contrat.dateSignature__c = System.today();
        contrat.numeroContrat__c = 'CNT/0102030405';
        contrat.libelleStatutContrat__c = 'Test';
        
        if(toInsert) insert contrat;
        return contrat;
    }
    
    /********************** KIncontournable__c OBJECT **********************/
    
    
    /**
    * @description Crée un incontournable rattaché à un devis
    * @param devis 
    * @param toInsert Définir à true pour insertion en base
    * @return KContrat__c Instance de l'objet KContrat
    */
    public static KIncontournable__c createIncontournable(Quote devis, Boolean toInsert) {
        KIncontournable__c inc = new KIncontournable__c();
        inc.devis__c = devis.id;
        inc.actif__c = false;
        inc.dateEcheance__c = System.today() + 10;
        inc.dateIncontournable__c = System.today();
        inc.dateEnvoiCourrier__c = System.today();
        inc.nImprimeBdC__c = '01234';
        inc.nImprimeMdC__c = '98765';
        inc.nIncontournable__c = 'ICT/0102030405/01';
        inc.statut__c = 'EN COURS';
        
        if(toInsert) insert inc;
        return inc;
    }
    
    /********************** Import__c OBJECT **********************/
    
    /**
    * @description Crée un enregistrement "Import"
    * @param rtId Id du type d'enregistrement
    * @param nomCompte Nom du compte
    * @param prenomCompte Pr?nom du compte
    * @param rueCompte Rue du compte
    * @param villeCompte Ville du compte
    * @param cpCompte Code postal du compte
    * @param phoneDomCompte T?l?phone domicile du compte
    * @param emailCompte Email du compte
    * @param comment Commentaire
    * @param datePros Date de prospection
    * @param toInsert Définir à true pour insertion en base
    * @return Import__c Instance de l'import
    */
    public static Import__c createImport(Id rtId, String nomCompte, String prenomCompte, String rueCompte, String villeCompte, String cpCompte, String phoneDomCompte, 
                                         String emailCompte, String comment, Date datePros, Boolean toInsert) {
                                             Import__c imp = new Import__c(recordTypeId = rtId,villeCompte__c=villeCompte,nomCompte__c=nomCompte,telephoneDomicileCompte__c=phoneDomCompte,
                                                                           emailCompte__c=emailCompte ,observationsComplementaires__c=comment,codePostalCompte__c =cpCompte,
                                                                           dateDeProspection__c=datePros,prenomCompte__c=prenomCompte,rueCompte__c=rueCompte,civiliteCompte__c='M.',source__c='CCM');
                                             if(toInsert) insert imp;
                                             return imp;
                                         }
    
    /********************** Tabviews__c OBJECT **********************/
    
    /**
    * @description Crée un enregistrement de configuiration pour les onglets VF
    * @param name Nom de la configuration
    * @param description Description de la configuration
    * @param obj Nom API de l'objet Salesforce
    * @param whereFilter Crit?re de filtrage
    * @param order Crit?re sur le tri
    * @param toInsert Définir à true pour insertion en base
    * @return Tabviews__c Instance de l'objet Tabviews__c
    */
    public static Tabviews__c createTabviews(String name, String description, String obj, String whereFilter, String order, Boolean toInsert) {
        Tabviews__c tabConf = new Tabviews__c(Object__c=obj,
                                              description__c = description,
                                              Name=name,
                                              where__c=whereFilter, 
                                              orderBy__c = order, 
                                              Default__c=true);
        
        if(toInsert) insert tabConf;
        return tabConf;
    }
    
    /********************** SECTORISATION__c OBJECT **********************/
    
    /**
    * @description Crée une sectorisation
    * @param iris  
    * @param codeMag 
    * @param nomMag 
    * @param codeDepot 
    * @param nomDepot 
    * @param toInsert Définir à true pour insertion en base
    * @return Sectorisation__c Instance de l'objet sectorisation
    */
    public static Sectorisation__c createSectorisation(String iris, String codeMag, String nomMag, String codeDepot, String nomDepot, 
                                                       String codePostalAdm, String nomCommuneAdm, Boolean toInsert){
                                                           Sectorisation__c sect = new Sectorisation__c(iris__c = iris,
                                                                                                        codeMagasin__c  = codeMag,
                                                                                                        libelleMagasin__c = nomMag,
                                                                                                        codeDepot__c = codeDepot,
                                                                                                        libelleDepot__c =nomDepot,
                                                                                                        codeDV__c = 'DV_0000',
                                                                                                        libelleDV__c = 'Direction des ventes 0000',
                                                                                                        codeRegion__c = 'RV_0000',
                                                                                                        libelleRegion__c = 'région 0000',
                                                                                                        codeDS__c = 'DS_0000',
                                                                                                        libelleDS__c = 'Direction service 0000',
                                                                                                        codePostalAdm__c = codePostalAdm,
                                                                                                        nomCommuneAdm__c = nomCommuneAdm);
                                                           
                                                           if(toInsert)
                                                               insert sect;
                                                           return sect;
                                                       }
    
    /**
    * @description Crée une sectorisation
    * @param codeMag 
    * @param nomMag 
    * @param codeDepot 
    * @param nomDepot 
    * @param toInsert Définir à true pour insertion en base
    * @return Sectorisation__c Instance de l'objet sectorisation
    */
    public static Sectorisation__c createSectorisation(String codeMag, String nomMag, String codeDepot, String nomDepot, Boolean toInsert){
        return createSectorisation('IRIS_'+randVal(),codeMag,nomMag,codeDepot,nomDepot,'74001','PARIS',toInsert);
    }
    
    /**
    * @description Crée une sectorisation par d?faut
    * @param toInsert Définir à true pour insertion en base
    * @return Sectorisation__c 
    */
    public static Sectorisation__c createSectorisation(Boolean toInsert) {
        return createSectorisation('MAG_0000','Magasin 0000','DEP_0000','D?p?t 0000',toInsert);
    }
    
    /**
    * @description Crée et ins?re une sectorisation par d?faut
    * @return Sectorisation__c 
    */
    public static Sectorisation__c createSectorisation() {
        return createSectorisation(true);
    }
    
    /********************** OBJECTIFSVENDEUR__c OBJECT **********************/
    
    /**
    * @description 
    * @param usrId 
    * @param year 
    * @param month 
    * @param nbCoAcS1 
    * @param nbVenteS1 
    * @param caS1 
    * @param toInsert 
    * @return ObjectifsVendeur__c 
    */
    public static ObjectifsVendeur__c createObjVendeur(Id usrId, Integer year, String month, Integer nbCoAcS1, Integer nbVenteS1, 
                                                       Integer caS1, Boolean toInsert) {
                                                           
                                                           ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = year, 
                                                                                                             vendeur__c = usrId, 
                                                                                                             moisObjectif__c = month,
                                                                                                             nbContactsActifsS1__c = nbCoAcS1,
                                                                                                             nbVentesS1__c = nbVenteS1, 
                                                                                                             chiffreAffaireVenduS1__c = caS1);
                                                           if(toInsert) 
                                                               insert obj;
                                                           return obj;
                                                       }
    
    /********************** DOCUMENT OBJECT **********************/
    
    /**
    * @description Fonction de création d'un document
    * @param name Libell?
    * @param dvpName Nom d?veloppeur (API)
    * @param toInsert Définir à true pour insertion en base
    * @return Document Instance de l'objet document
    */
    public static Document createDocument(String name, String dvpName, Boolean toInsert) {
        Document doc = new Document(DeveloperName = dvpName,
                                    Name = name,
                                    FolderId = Userinfo.getUserId(),
                                    AuthorId = Userinfo.getUserId());
        if(toInsert)
            insert doc;
        return doc;
    }
    
    /********************** Cartographie__c OBJECT **********************/
    
    /**
    * @description Fonction de création d'un objet de cartographie
    * @param name Libell?
    * @param idTiers Id externe de l'objet
    * @param toInsert Définir à true pour insertion en base
    * @return Cartographie__c Instance de l'objet cartographie
    */
    public static Cartographie__c createCartographie(String name, String idTiers, Boolean toInsert) {
        Cartographie__c carto = new Cartographie__c(Name = name, 
                                                    IDTiers__c = idTiers);
        if(toInsert)
            insert carto;
        return carto;
    }
    
    /********************** ReferentielOperation__c OBJECT **********************/
    
    /**
    * @description 
    * @param name
    * @param dateDeb
    * @param dateFin
    * @param ville
    * @param coutEmp
    * @param coutMon
    * @param autrCout
    * @param precisionCout
    * @param toInsert Définir à true pour insertion en base
    * @return ReferentielOperation__c 
    */
    public static ReferentielOperation__c createOperation(String name, Date dateDeb, Date dateFin, String ville, 
                                                          Double coutEmp, Double coutMon, Double autrCout, String precisionCout, String origine, Boolean toInsert) 
    {
        ReferentielOperation__c opt = new ReferentielOperation__c(
            Name = name,
            Datedebut__c = dateDeb,
            Datefin__c = dateFin,
            SurfaceduStand__c = 'G4 : Stand GM',
            Ville__c = ville,
            Coutemplacement__c = coutEmp,
            Coutsmontagedemontage__c = coutMon,
            Autrescouts__c = autrCout,
            Precisions_autres_couts__c = precisionCout,
            Magasins_DR_Est__c= 'ALBERTVILLE',
            Magasins_DR_IDF__c = 'ARPAJON',
            Magasins_DR_Nord__c = 'CHANTILLY',
            Magasins_DR_Ouest__c = 'AGEN',
            Code_DV__c='O01',
            origine__c=origine);
        
        if(toInsert)
            insert opt;
        return opt;
    }
    
    /********************** Suivi_operations__c OBJECT **********************/
    
    /**
    * @description Crée et ins?re un suivi d'op?ration ? partir d'une liste d'op?rations.
    * @param name Nom du suivi de l'op?ration
    * @param toInsert Définir à true pour insertion en base
    * @return Suivi_operations__c 
    */
    public static Suivi_operations__c createSuiviOperation(String name, Boolean toInsert) {
        Suivi_operations__c suiviOpt = new Suivi_operations__c(Name = name);
        
        if(toInsert)
            insert suiviOpt;
        return suiviOpt;
    }
    
    /**
    * @description Crée et ins?re un suivi d'op?ration ? partir d'une liste d'op?rations. Crée ?galement les objets IntersectionOp composant la liste du suivi
    * @param name Nom du suivi de l'op?ration
    * @param opts Liste d'op?rations
    * @return Suivi_operations__c
    */
    public static Suivi_operations__c createSuiviOperation(String name, List<ReferentielOperation__c> opts) {
        //creation suiviOP
        Suivi_operations__c suiviOpt = createSuiviOperation(name, true);
        
        //association liste operation au suiviOpt
        List<IntersectionOp_rations__c> interOpList = new List<IntersectionOp_rations__c>();
        for(ReferentielOperation__c op : opts) {
            interOpList.add(new IntersectionOp_rations__c(IntersectionOperationOperation__c = op.Id, Suivi_des_operations__c = suiviOpt.Id));
        }
        //insertion des IntersectionOp_rations__c
        insert interOpList;
        
        return suiviOpt;
    }
    
    
    /********************** Task OBJECT **********************/
    
    /**
    * @description Crée une t?che
    * @param rtId Id du type d'enregistrement
    * @param whoId Id du champ "Nom"
    * @param whatId Id du champ "Associ? ?"
    * @param subject Objet de la t?che
    * @param status Status de la t?che
    * @param ownerId Id du propri?taire
    * @param rtId Id du propri?taire
    * @param toInsert Définir à true pour insertion en base
    * @return Task T?che créée
    */
    public static Task createTask(Id rtId, Id whoId, Id whatId, String subject, String status, Id ownerId, Date actDate, Boolean toInsert) {
        Task task = new Task(Subject = subject, 
                             Priority = 'Normal', 
                             OwnerId = ownerId,
                             WhoId = whoId, 
                             WhatId = whatId,
                             Status = status, 
                             ActivityDate = actDate,
                             RecordTypeId = rtId);
        if(rtId == null) task.RecordTypeId = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_A_FAIRE_RT);
        if(toInsert) insert task;
        return task;
    }
    
    /**
    * @description Crée une t?che
    * @param whoId Id du champ "Nom"
    * @param whatId Id du champ "Associ? ?"
    * @param status Status de la t?che
    * @param ownerId Id du propri?taire
    * @param toInsert Définir à true pour insertion en base
    * @return Task T?che créée
    */
    public static Task createTask(Id whoId, Id whatId, String status, Id ownerId, Date actDate, Boolean toInsert) {
        return createTask(null,whoId,whatId,'Appel',status,ownerId,actDate,toInsert);
    }
    
    /********************** ATTACHMENT OBJECT **********************/
    
    /**
    * @description Crée une pièce jointe
    * @param name
    * @param parent
    * @param body
    * @return Attachment pièce jointe créée
    */
    public static Attachment createAttachment(String name, Id parent, Blob body, Boolean toInsert) {
        Attachment att = new Attachment(Name = name, ParentId = parent, Body = body);
        if(toInsert) insert att;
        return att;
    }
    
    public static Attachment createAttachment(String name, Id parent, Blob body) {
        return createAttachment(name, parent, body, true);
    }
    
    /********************** FILE OBJECT **********************/
    
    /**
    * @description Crée une pièce jointe (ContentDocument)
    * @param name Nom du fichier
    * @param parent Id de l'enregistrement associé
    * @param body Contenu du fichier
    * @param toInsert Définir à true pour insertion en base
    * @return ContentDocument créée
    */
    public static ContentDocumentLink createFile(String name, Id parent, Blob body, Boolean toInsert) {
        ContentVersion cVersion = new ContentVersion(ContentLocation = 'S',
                                                    Title = Name,
                                                    VersionData = body,
                                                    PathOnClient = Name);
        ContentDocumentLink file = new ContentDocumentLink();
        if(toInsert) {
            insert cVersion; 
            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
            file = new ContentDocumentLink(ContentDocumentId = conDocument,LinkedEntityId = parent,ShareType = 'I');
            insert file;
        }
        return file;
    }
    
    /**
    * @description Crée une pièce jointe (ContentDocument)
    * @param name Nom du fichier
    * @param parent Id de l'enregistrement associé
    * @param body Contenu du fichier
    * @return ContentDocument créée
    */
    public static ContentDocumentLink createFile(String name, Id parent, Blob body) {
        return createFile(name, parent, body, true);
    }
    
    /********************** ContentDistribution OBJECT **********************/
    /**
    * @description Crée un ContentDistribution
    * @param name Nom du fichier
    * @param contentVersionId Id de la ContentVersion
    * @param toInsert Définir à true pour insertion en base
    * @return ContentDistribution créé
    */
    public static ContentDistribution createContentDistribution(String name, String contentVersionId, Boolean toInsert){
        ContentDistribution cdistrib = new ContentDistribution(ContentVersionId=contentVersionId, Name='test');
        if(toInsert){
            insert cdistrib;
        }
        return cdistrib;
    }
    
    /********************** NOTE OBJECT **********************/
    
    /**
    * @description Crée une note
    * @param name Nom de la note
    * @param parent Id de l'enregistrement associé
    * @param body Contenu de la note
    * @param toInsert Définir à true pour insertion en base
    * @return Note Note créée
    */
    public static Note createNote(String name, Id parent, String body, Boolean toInsert) {
        Note note = new Note(Title = name, ParentId = parent, Body = body);
        if(toInsert) insert note;
        return note;
    }
    
    /********************** ListePhoningVendeur__c OBJECT **********************/
    
    /**
    * @description Crée une liste de phones pour le vendeur
    * @param name Nom de la liste
    * @param user Id du créateur de la liste
    * @param toInsert Définir à true pour insertion en base
    * @return ListePhoningVendeur__c Instance de l'objet ListePhoningVendeur__c
    */
    public static ListePhoningVendeur__c createListePhoningVendeur(String name, Id user, Boolean toInsert) {
        ListePhoningVendeur__c ldp = new ListePhoningVendeur__c(Name= name, 
                                                                proprietaire_Filtre__c= user, 
                                                                DR_Filtre__c= name,
                                                                DV_Filtre__c= name,
                                                                magasin_Filtre__c= name, 
                                                                user__c= user);
        if(toInsert) insert ldp;
        return ldp;
    }
    
    /********************** PhoningVendeur__c OBJECT **********************/
    
    /**
    * @description Crée un objet de phone pour le vendeur
    * @param name Nom de la t?che phone
    * @param listeId Id de la liste de phones
    * @param accId Id du compte
    * @param toInsert Définir à true pour insertion en base
    * @return PhoningVendeur__c Instance de l'objet PhoningVendeur__c
    */
    public static PhoningVendeur__c createPhoningVendeur(String name, Id listeId, Id accId, Boolean toInsert) {        
        PhoningVendeur__c phone = new PhoningVendeur__c(Name= name, 
                                                        liste__c= listeId, 
                                                        compte__c= accId);
        if(toInsert) insert phone;
        return phone;
    }
    
    /********************** ContentVersion OBJECT **********************/
    
    /**
    * @description Crée un objet Content Version (document dans bliblioth?que)
    * @param title Nom du document
    * @param pathOnClient Nom du fichier
    * @param content Contenu
    * @param libId Id de la bliblioth?que
    * @param toInsert Définir à true pour insertion en base
    * @return ContentVersion Instance de l'objet ContentVersion
    */
    public static ContentVersion createContentVersion(String title, String pathOnClient, String content, Id libId, Boolean toInsert) {          
        Blob beforeblob = Blob.valueOf(content);
        ContentVersion doc = new ContentVersion(Title = title,
                                                PathOnClient = pathOnClient,
                                                VersionData = beforeblob,
                                                Origin = 'C',
                                                FirstPublishLocationId = libId);
        if(toInsert) insert doc;
        return doc;
    }
    
    /********************** Question_questionnaire__c OBJECT **********************/
    
    /**
    * @description Crée un objet Question Questionnaire (pour les questionnaires dynamiques)
    * @param questionnaireId Id du questionnaire associ?
    * @param typeReponse type de réponse
    * @param question valeur de la question
    * @param page num?ro de page
    * @param ordre num?ro d'ordre
    * @param obligatoire Définir à true pour question obligatoire
    * @param commentaire commentaire
    * @param toInsert Définir à true pour insertion en base
    * @return qq Instance de l'objet Question_questionnaire__c
    */
    public static Question_questionnaire__c createQuestionQuestionnaire(String questionnaireId, String typeReponse, String question, Integer page, Integer ordre, 
                                                                        Boolean obligatoire, String commentaire, Boolean toInsert) {
                                                                            Question_questionnaire__c qq = new Question_questionnaire__c(obligatoire__c = obligatoire,
                                                                                                                                         page__c = page,
                                                                                                                                         ordre__c = ordre,
                                                                                                                                         question__c = question,
                                                                                                                                         questionnaire__c = questionnaireId,
                                                                                                                                         typeReponse__c = typeReponse,
                                                                                                                                         commentaire__c = commentaire,
                                                                                                                                         actif__c = true);
                                                                            if(toInsert) 
                                                                                insert qq;
                                                                            return qq;
                                                                        }
    
    /********************** Option_de_reponse__c OBJECT **********************/
    
    /**
    * @description Crée un objet Option de réponse (pour les questionnaires dynamiques)
    * @param questionId id de la question associ?e
    * @param valeur valeur de la réponse
    * @param position position de la réponse
    * @param poids poids de la réponse
    * @param toInsert Définir à true pour insertion en base
    * @return odr Instance de l'objet Option_de_reponse__c
    */
    public static Option_de_reponse__c createOptionDeReponse(String questionId, String valeur, Integer position, Integer poids, Boolean toInsert) {
        Option_de_reponse__c odr = new Option_de_reponse__c(questionQuestionnaire__c = questionId,
                                                            position__c = position,
                                                            valeur__c = valeur,
                                                            poids__c = poids);
        if(toInsert) 
            insert odr;
        return odr;
    }
    
    /********************** INVOICE OBJECT **********************/
    
    /**
    * @description Fonction de création d'un enregistrement facture
    * @param name Nom de la facture
    * @param accountId Id du compte
    * @param entityId Id de la société mere
    * @param invoiceDate Date de la facture 
    * @param sellerId Id de l'entité magasin
    * @param chantierId Id du chantier
    * @param orderId Id de la commande
    * @param rtId Id du type d'enregistrement
    * @param toInsert Définir à true pour insertion en base
    * @return Invoice__c Instance de l'objet facture
    */
    public static Invoice__c createInvoice(String name, Id accountId, Id entityId, Date invoiceDate, Id sellerId, Id chantierId, Id orderId, Id rtId, Boolean toInsert) {
        Invoice__c inv = new Invoice__c(invoiceDate__c = invoiceDate,
                                        headOffice__c = entityId,
                                        billingAccount__c = accountId,
                                        customerOrder__c = orderId,
                                        billingCity__c = 'test', 
                                        billingName__c = 'test', 
                                        billingPostalCode__c = '12345', 
                                        seller__c = sellerId, 
                                        sellerSIRET__c = 12345, 
                                        worksite__c = chantierId,
                                        shippingName__c = 'test', 
                                        shippingPostalCode__c = '12345', 
                                        shippingCity__c = 'test', 
                                        sellerName__c = 'test', 
                                        sellerCity__c = 'test', 
                                        sellerPostalCode__c = '12345',
                                        RecordTypeId = rtId,
                                        stageName__c = 'Préparation'
                                        );
        
        if(toInsert) 
            insert inv;
        return inv;
    }
    
    /**
    * @description Fonction de création d'un enregistrement facture
    * @param name Nom de la facture
    * @param accountId Id du compte
    * @param entityId Id de la société mere
    * @param invoiceDate Date de la facture 
    * @param sellerId Id de l'entité magasin
    * @param chantierId Id du chantier
    * @param toInsert Définir à true pour insertion en base
    * @return Invoice__c Instance de l'objet facture
    */
    public static Invoice__c createInvoice(String name, Id accountId, Id entityId, Date invoiceDate, Id sellerId, Id chantierId, Boolean toInsert) {
        return createInvoice(name, accountId, entityId, invoiceDate, sellerId, chantierId, null, DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT), toInsert);
    }

    /**
    * @description Fonction de création d'un enregistrement ligne de facture
    * @param invoiceId Id de la facture
    * @param parentLineId Id de la ligne parent
    * @param assetId Id de l'actif
    * @param orderItemId Id de la ligne de commande
    * @param location Emplacement
    * @param lineNumber Numéro de la ligne
    * @param toInsert Définir à true pour insertion en base
    * @return InvoiceLine__c Instance de la ligne facture
    */
    public static InvoiceLine__c createInvoiceLine(Id invoiceId, Id parentLineId, Id assetId, Id orderItemId, String location, 
                                                    Decimal pretaxAmount, Decimal amount, Integer lineNumber, Boolean toInsert) {
        InvoiceLine__c invLine = new InvoiceLine__c(invoice__c = invoiceId,
                                                location__c = location,
                                                asset__c = assetId,
                                                quantity__c = 1,
                                                VATRate__c = 10,
                                                VATAmount__c = 2,
                                                pretaxAmount__c = pretaxAmount,
                                                amount__c = amount,
                                                orderItem__c = orderItemId,
                                                parentLine__c = parentLineId,
                                                lineNumber__c = lineNumber                            
                                            );
        
        if(toInsert) 
            insert invLine;
        return invLine;
    }
    
    /********************** CREDIMEMO OBJECT **********************/
    
    /**
    * @description Fonction de création d'un enregistrement avoir
    * @param accountId Id du compte
    * @param entityId Id de l'entité magasin
    * @param invoiceId Id de la facture 
    * @param chantierId Id du chantier 
    * @param creditMemoDate Date de l'avoir 
    * @param orderId Id de la commande
    * @param rtId Id du type d'enregistrement
    * @param toInsert Définir à true pour insertion en base
    * @return CreditMemo__c Instance de l'objet avoir
    */
    public static CreditMemo__c createCreditMemo(Id accountId, Id entityId, Id invoiceId, Id chantierId, Date creditMemoDate, Id orderId, Id rtId, Boolean toInsert) {
        CreditMemo__c credMem = new CreditMemo__c(creditMemoDate__c = creditMemoDate,
                                        seller__c = entityId,
                                        headOffice__c = entityId,
                                        invoice__c = invoiceId,
                                        billingAccount__c = accountId,
                                        customerOrder__c = orderId,
                                        worksite__c=chantierId, 
                                        shippingCity__c='TEST', 
                                        shippingPostalCode__c='TEST', 
                                        shippingName__c='TEST', 
                                        billingCity__c='TEST', 
                                        billingName__c='TEST', 
                                        billingPostalCode__c='TEST', 
                                        sellerCity__c='TEST', 
                                        sellerName__c='TEST', 
                                        sellerPostalCode__c='TEST', 
                                        sellerSIRET__c=2222,
                                        RecordTypeId = rtId);
        
        if(toInsert) 
            insert credMem;
        return credMem;
    }
    
    /**
    * @description Fonction de création d'un enregistrement avoir
    * @param accountId Id du compte
    * @param entityId Id de l'entité magasin
    * @param invoiceId Id de la facture 
    * @param chantierId Id du chantier 
    * @param creditMemoDate Date de l'avoir 
    * @param toInsert Définir à true pour insertion en base
    * @return CreditMemo__c Instance de l'objet avoir
    */
    public static CreditMemo__c createCreditMemo(Id accountId, Id entityId, Id invoiceId, Id chantierId, Date creditMemoDate, Boolean toInsert) {
        return createCreditMemo(accountId, entityId, invoiceId, chantierId, creditMemoDate, null, DAL.getRecordTypeIdByDevName('CreditMemo__c',Constants.CREDITMEMO_INVOICECREDITMEMO_RT), toInsert);
    }
    
    /**
    * @description Fonction de création d'un enregistrement avoir
    * @param accountId Id du compte
    * @param entityId Id de l'entité magasin
    * @param invoiceId Id de la facture 
    * @param chantierId Id du chantier 
    * @param creditMemoDate Date de l'avoir 
    * @param toInsert Définir à true pour insertion en base
    * @return CreditMemo__c Instance de l'objet avoir
    */
    public static CreditMemo__c createCreditMemoLine(Id accountId, Id entityId, Id invoiceId, Id chantierId, Date creditMemoDate, Boolean toInsert) {
        return createCreditMemo(accountId, entityId, invoiceId, chantierId, creditMemoDate, null, DAL.getRecordTypeIdByDevName('CreditMemo__c',Constants.CREDITMEMO_INVOICECREDITMEMO_RT), toInsert);
    }

    /**
    * @description Fonction de création d'un enregistrement ligne d'avoir
    * @param creditMemoId Id de l'avoir
    * @param invoiceId Id de la facture
    * @param invoiceLineId Id de la ligne de facture
    * @param assetId Id du produit
    * @param assetId Id de l'actif
    * @param orderItemId Id de la ligne de commande
    * @param location Emplacement
    * @param pretaxAmount Montant HT
    * @param amount Montant TTC
    * @param toInsert Définir à true pour insertion en base
    * @return CreditMemoLine__c Instance de la ligne facture
    */
    public static CreditMemoLine__c createCreditMemoLine(Id creditMemoId, Id invoiceId, Id invoiceLineId, Id productId, Id assetId, Id orderItemId, 
                                                        String location, Decimal pretaxAmount, Decimal amount, Boolean toInsert) 
    {
        CreditMemoLine__c creditMemoLine = new CreditMemoLine__c( creditMemo__c = creditMemoId,
                                                lineNumber__c =0,
                                                reason__c = 'Annulation facture',
                                                label__c = 'TEST',
                                                unitPrice__c = 2,
                                                invoice__c = invoiceId,
                                                invoiceLine__c = invoiceLineId,
                                                product__c = productId,
                                                asset__c = assetId,
                                                orderItem__c = orderItemId,
                                                location__c = location,
                                                pretaxAmount__c = pretaxAmount,
                                                VATRate__c = 10,
                                                VATAmount__c = 2,
                                                amount__c = amount,
                                                quantity__c = 1,
                                                unit__c = 'UNIT');
            
        if(toInsert) 
            insert creditMemoLine;
        return creditMemoLine;
    }
    
    /********************** COLLABORATOR OBJECT **********************/

    /**
     * @description Création d'un collaborateur associé à un utilisateur Salesforce
     * @param sfUser Id de l'utilisateur Salesforce
     * @param firstname Prénom
     * @param lastname Nom
     * @param sgId SGID     
     * @param employedById Id de l'entité employé par
     * @param jobId Id du métier
     * @param isExternal Si true, collaborateur externe
     * @return Collaborator
     */
    public static Collaborator__c createCollaborator(Id sfUser, String firstname, String lastname, String sgId, String employedById, String jobId, Boolean isExternal, Boolean toInsert) {
        Id collabRT;
        if (null != isExternal && isExternal) {
            collabRT = DAL.getRecordTypeIdByDevName('Collaborator__c', Constants.COLLABORATOR_RT_EXTERNAL);
        } else {
            collabRT = DAL.getRecordTypeIdByDevName('Collaborator__c', Constants.COLLABORATOR_RT_INTERNAL);
        }

        Collaborator__c collab = new Collaborator__c(user__c = sfUser,
                                                Name = lastname, 
                                                lastName__c = lastname, 
                                                firstName__c = firstname, 
                                                RecordTypeId = collabRT, 
                                                job__c = jobId,
                                                employedBy__c = employedById,
                                                reference__c = sgId);
            
        if(toInsert) 
            insert collab;
        return collab;
    }

    /**
     * @description Création d'un collaborateur associé à un utilisateur Salesforce
     * @param sfUser Id de l'utilisateur Salesforce
     * @param firstname Prénom
     * @param lastname Nom
     * @param sgId SGID     
     * @param isExternal Si true, collaborateur externe
     * @return Collaborator
     */
    public static Collaborator__c createCollaborator(Id sfUser, String firstname, String lastname, String sgId, Boolean isExternal) {
        return createCollaborator(sfUser, firstname, lastname, sgId, null, null, isExternal, true);
    }

    /**************************************************************/
    /**************** Autres fonctions utilitaires ****************/
    /**************************************************************/
    
    /**
    * @description Initialise les propri?t?s globales
    * @param geocoderEnabled
    * @param geocoderMin
    * @param ltvFilEnabled
    * @param ltvLtcEnabled
    * @param ltvParEnabled
    * @param tabSearchMax
    * @param tabViewMax
    * @param userCacheEnabled
    */
    public static void createGlobalProperties(Boolean geocoderEnabled, Integer geocoderMin, 
                                              Boolean ltvFilEnabled, Boolean ltvLtcEnabled, Boolean ltvParEnabled, 
                                              Integer tabSearchMax, Integer tabViewMax, Boolean userCacheEnabled) 
    {
        // création des param?tres globaux
        PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', geocoderEnabled);
        PropertiesUtils.setBooleanValue('geoconcept.geocoder.enabled', geocoderEnabled);
        PropertiesUtils.setIntegerValue('geoconcept.geocoder.minscore', geocoderMin);
        PropertiesUtils.setIntegerValue('tabview.search.maxcount', tabSearchMax);
        PropertiesUtils.setIntegerValue('tabview.view.maxcount', tabViewMax);
        PropertiesUtils.setBooleanValue('usercontext.cache.enabled', userCacheEnabled);
    }
    private static Double randVal() {
        return Math.floor(Math.random()*10);
    }




    /**************************************************************/
    /*************** Fonctions rémunération VRP *******************/

    /**
     * @description Create a GridRevision with its RemunerationGrid
     *
     * @param gridRecordTypeName Record Type name of GridRevision to create
     * @param gridName Grid name
     * @param defaultRate Default rate (required for Team RT)
     * @param startDate Revision start date
     * @param endDate Revision end date (if null, no end date)
     *
     * @return Created GridRevision
     */
    public static NRV10GridRevision__c createGridRevision(String gridRecordTypeName, String gridName,
            Double defaultRate, Date startDate, Date endDate) {

        if (gridRecordTypeName != Constants.GRID_RT_CONTRACT) {
            return createGridRevision(gridRecordTypeName, gridName, defaultRate, startDate, endDate,
                    null, null, null, null, null);
        }
        return null;
    }


    /**
     * @description Create a GridRevision with its RemunerationGrid
     *
     * @param gridRecordTypeName Record Type name of GridRevision to create
     * @param gridName Grid name
     * @param defaultRate Default rate (required for Team RT)
     * @param startDate Revision start date
     * @param endDate Revision end date (if null, no end date)
     * @param discountGridId Id of the discount grid
     * @param teamGridId Id of the team grid
     * @param salesGridId Id of the sales grid
     * @param bonusGridId Id of the bonus grid
     * @param malusGridId Id of the malus grid
     *
     * @return Created Gridrevision
     */
    public static NRV10GridRevision__c createGridRevision(String gridRecordTypeName, String gridName,
            Double defaultRate, Date startDate, Date endDate, Id discountGridId, Id teamGridId,
            Id salesGridId, Id bonusGridId, Id malusGridId) {

        Id gridRevRT = DAL.getRecordTypeIdByDevName('NRV10GridRevision__c', gridRecordTypeName);

        NRV10GridRevision__c gridRev = new NRV10GridRevision__c(RecordTypeId = gridRevRT,
                startDate__c = startDate, Name = gridName);
        if (gridRecordTypeName == Constants.GRID_RT_CONTRACT) {
            if (discountGridId != null) gridRev.discountGridRevision__c = discountGridId;
            if (salesGridId != null) gridRev.salesGridRevision__c = salesGridId;
            if (teamGridId != null) gridRev.teamGridRevision__c = teamGridId;
            if (bonusGridId != null) gridRev.bonusGridRevision__c = bonusGridId;
            if (malusGridId != null) gridRev.malusGridRevision__c = malusGridId;
        } else if ((gridRecordTypeName == Constants.GRID_RT_SALES || gridRecordTypeName == Constants.GRID_RT_TEAM)
                && defaultRate != null) {
            gridRev.defaultRate__c = defaultRate;
        }
        if (endDate != null) gridRev.endDate__c = endDate;

        insert gridRev;
        return gridRev;
    }

    /**
     * @description Create a remuneration rate and associate it to the sepcified GridRevision
     *
     * @param rtName Record type name of the RemunerationRate
     * @param gridRev Id of the GridRevision to associate the object to
     * @param name Name of the remuneration rate
     * @param coef_level discount coefficient for type Discount
     * @param ratingDiff rating difference for type Discount
     * @param rate_amount rate value for type Sales
     * @param startDate Start date of the remuneration rate
     * @param endDate End date of the remuneration rate (if null, no end date)
     * @param financingMethod Id of the financing method
     *
     * @return Created remuneration rate
     */
    public static NRV10RemunerationRate__c addRemRate(String rtName, Id gridRev, String name, Double coef_level,
            Double ratingDiff, Double rate_amount, Date startDate, Date endDate, Id financingMethod) {

        Id gridRevRT = DAL.getRecordTypeIdByDevName('NRV10RemunerationRate__c', rtName);

        NRV10RemunerationRate__c remRate = new NRV10RemunerationRate__c(RecordTypeId = gridRevRT,
                startDate__c = startDate, gridRevision__c = gridRev);
        if (rtName == Constants.REMUNERATION_RATE_RT_DISCOUNT) {
            remRate.discountCoefficient__c = coef_level;
            remRate.ratingDifference__c = ratingDiff;
        }else if (rtName == Constants.REMUNERATION_RATE_RT_SALES) {
            remRate.rate__c = rate_amount;
        }else if (rtName == Constants.REMUNERATION_RATE_RT_BONUS) {
            remRate.turnoverLevel__c = coef_level;
            remRate.bonusAmount__c = rate_amount;
        }else if (rtName == Constants.REMUNERATION_RATE_RT_MALUS) {
            remRate.financingMethod__c = financingMethod;
            remRate.turnoverLevel__c = coef_level;
            remRate.bonusAmount__c = rate_amount;
        }
        if (endDate != null) remRate.endDate__c = endDate;
        insert remRate;
        return remRate;
    }


    /**
     * @description Add an employment contract for the specified collaborator on specified period/Grid
     *
     * @param name Name of the employment contract
     * @param startDate Start date of the contract
     * @param endDate End date of the contract (no end date if null)
     * @param collaboratorId Id of the collaborator
     * @param gridRevId Id of the GridRevision
     * @param storeId Id of the store collaborator is assigned to
     * @param refJobId Id of the Referencial job
     *
     * @return Created employment contract
     */
    public static NRV10RemunerationContract__c createEmploymentContract(String name, Date startDate, Date endDate,
            Id collaboratorId, Id gridRevId, Id storeId, Id refJobId) {

        CollaboratorContract__c contract = new CollaboratorContract__c(signatureDate__c = startDate,
                startDate__c = startDate, collaborator__c = collaboratorId, assignedTo__c = storeId,
                employedBy__c = storeId, type__c = Constants.COLLABORATOR_TYPE_CDI, job__c = refJobId);
        if (endDate != null) contract.endDate__c = endDate;
        insert contract;
        NRV10RemunerationContract__c remContract = new NRV10RemunerationContract__c(contract__c = contract.Id, employmentContractType__c = gridRevId);
        insert remContract;
        return remContract;
    }

    /**
     * @description Creation d'une ?quipe RemVRP sur un magasin avec une fiche collaborateur
     *                  pour un vendeur et un manager et un ?ventuel taux sp?cifique sur un produit
     * @param storeId Id du magasin auquel attacher l'?quipe
     * @param managerId Id du user SF qui sera manager de l'?quipe (si null, pas de manager)
     * @param salesId Id du user SF qui sera vendeur de l'?quipe
     * @param productId Id du produit sur lequel applkiquer un taux sp?cifique (si null, pas de taux sp?cifique)
     * @param withContract If true, create the employment contract for the sales
     * @param financing Id of the financing method
     *
     * @return Created team
     */
    public static Collaborator__c createTeamTest(Id storeId, Id managerId, Id salesId, Id productId, Boolean withContract, Id financing) {
        System.debug('@REMVRP team creation');

        System.debug('  @REMVRP create grid revisions');
        // création des r?visions de grille pour le contrat
        NRV10GridRevision__c salesGridRev = createGridRevision(Constants.GRID_RT_SALES, 'sales1 GR',
                20, Date.today().addMonths(-12), null);
        NRV10GridRevision__c discountGridRev = createGridRevision(Constants.GRID_RT_DISCOUNT, 'discount GR',
                null, Date.today().addMonths(-12), null);
        NRV10GridRevision__c teamGridRev = createGridRevision(Constants.GRID_RT_TEAM, 'team GR', 3,
                Date.today().addMonths(-12), null);
        NRV10GridRevision__c bonusGridRev = createGridRevision(Constants.GRID_RT_BONUS, 'bonus GR',
                null, Date.today().addMonths(-12), null);
        NRV10GridRevision__c malusGridRev = createGridRevision(Constants.GRID_RT_MALUS, 'malus GR',
                null, Date.today().addMonths(-12), null);

        System.debug('  @REMVRP create remuneration rates');
        // Ajout des taux de rémunération aux grilles
        addRemRate(Constants.REMUNERATION_RATE_RT_DISCOUNT, discountGridRev.Id, 'decote 40', 40,
                10, null, Date.today().addMonths(-12), null, null);
        addRemRate(Constants.REMUNERATION_RATE_RT_DISCOUNT, discountGridRev.Id, 'decote 60', 60,
                15, null, Date.today().addMonths(-12), null, null);
        NRV10RemunerationRate__c salesRemRate = addRemRate(Constants.REMUNERATION_RATE_RT_SALES, salesGridRev.Id,
                'Rate .5', null, null, (Double)0.5, Date.today().addMonths(-12),
                null, null);
        addRemRate(Constants.REMUNERATION_RATE_RT_BONUS, bonusGridRev.Id, 'first step', 100,
                null, 15, Date.today().addMonths(-12), null, null);
        addRemRate(Constants.REMUNERATION_RATE_RT_BONUS, bonusGridRev.Id, 'second step', 500,
                null, 30, Date.today().addMonths(-12), null, null);
        addRemRate(Constants.REMUNERATION_RATE_RT_MALUS, malusGridRev.Id, 'malus step', 100,
                null, -12, Date.today().addMonths(-12), null, financing);

        System.debug('  @REMVRP create product rate');
        // ajout d'un taux de produit sp?cifique
        if (productId != null) {
            NRV10ProductRate__c salesProdRate = new NRV10ProductRate__c(salesrate__c = salesRemRate.Id, product__c = productId);
            insert salesProdRate;
        }

        System.debug('  @REMVRP create contract grid revision');
        // création de la r?vision de grille type contrat vendeur
        NRV10GridRevision__c ctGridRev = createGridRevision(Constants.GRID_RT_CONTRACT,'Contract1',
                null, Date.today().addMonths(-12), null, discountGridRev.Id, null,
                salesGridRev.Id, bonusGridRev.Id, malusGridRev.Id);

        // création de la r?vision de grille type contrat manager
        NRV10GridRevision__c ctGridRevMgr = createGridRevision(Constants.GRID_RT_CONTRACT,'ContractMgr1',
                null, Date.today().addMonths(-12), null, null, teamGridRev.Id,
                null, null, null);

        // création des référentiels Job RV Et vendeur
        Id refRT = DAL.getRecordTypeIdByDevName('Referencial__c', 'Job');
        Referencial__c refJobRv = findOrCreateReferencial('RV', 'RV', Date.today().addMonths(-12), null,
                refRT, true, true, true, true, true);
        Referencial__c refJobVendeur = findOrCreateReferencial('Vendeur', 'Vendeur', Date.today().addMonths(-12),
                null, refRT, true, true, true, true, true);

        // création du manager, de son contrat et affectation au magasin si besoin
        if (managerId != null) {
            Collaborator__c manager = createCollaborator(managerId, 'test', 'manager', 'mng1', false);
            if (withContract) {
                createEmploymentContract('contract 1m', Date.today().addMonths(-12),
                        null, manager.Id, ctGridRevMgr.Id, storeId, refJobRv.Id);
            }
        }

        // création du vendeur et de son contrat
        System.debug('  @REMVRP create sales collaborator and his employment contract using contract grid rev');
        // création du vendeur et association avec le contrat cr??
        Collaborator__c collaborator = createCollaborator(salesId, 'test', 'sales',
                'sl1', false);
        if (withContract) {
            createEmploymentContract('contract 1', Date.today().addMonths(-12), null,
                    collaborator.Id, ctGridRev.Id, storeId, refJobVendeur.Id);
        }

        return collaborator;
    }

    /**
     * @description création d'une commission restreinte au collbaorateur (quel que soit le type)
     * @param collabId Id du collaborateur ? qui appartient cette commission
     * @param status Statut de la commission
     * @param cType Type de commission
     * @param rem Montant de la rémunération
     * @param calcDate Date de calcul de la commission
     * @param isInstant Si true, set la date de clich? ? la date de clacul
     * @param toInsert Si true persiste la commission avant de la retourner
     *
     * @return La commission g?n?r?e
     */
    public static NRV10Commission__c createCollaboratorCommission(Id collabId, String status, String cType,
            Double rem, Date calcDate, Boolean isInstant, Boolean toInsert) {

        NRV10Commission__c result = new NRV10Commission__c(user__c = collabId, Status__c = status,
                comType__c = cType, remuneration__c = rem, calculationDate__c = calcDate);
        if (isInstant) {
            result.instantDate__c = calcDate;
        }

        if (toInsert) {
            insert result;
        }
        return result;
    }

    /**
     * @description création d'une commission non restreinte au collbaorateur (quel que soit le type)
     *
     * @param collabId Id du collaborateur ? qui appartient cette commission
     * @param status Statut de la commission
     * @param cType Type de commission
     * @param rem Montant de la rémunération
     * @param calcDate Date de calcul de la commission
     * @param quoteId Id de la quote ? laquelle se r?f?re la commission
     * @param productId Id du la ligne de quote ? laquelle se r?f?re la commission
     * @param storeId Id du magasin dont le collaborateur d?pend
     * @param isInstant Si true, set la date de clich? ? la date de clacul
     * @param toInsert Si true persiste la commission avant de la retourner
     *
     * @return La commission g?n?r?e
     */
    public static NRV10Commission__c createCommission(Id collabId, String status, String cType, Double rem,
            Date calcDate, Id quoteId, Id productId, Id storeId, Boolean isInstant, Boolean toInsert) {

        NRV10Commission__c result = new NRV10Commission__c(user__c = collabId, status__c = status, comType__c = cType,
                remuneration__c = rem, calculationDate__c = calcDate, quoteCPQ__c = quoteId, quoteLine__c = productId,
                store__c = storeId);
        if (isInstant) {
            result.instantDate__c = calcDate;
        }

        if (toInsert) {
            insert result;
        }
        return result;
    }

    /**
     * @description création d'une opportunité et des ?l?ments n?cessaires pour la création d'un devis
     *
     * @param priceBookId Id du pricebook
     * @return L'opportunité créée
     */
    public static Opportunity createSBQQQuoteOpportunity(Id priceBookId) {
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr',
                accPersoRT, 'Email',false);
        Account acc2 = Utils_Test.createAccount('Account Deux', 'test2', 'test2@test.fr',
                accPersoRT, 'Email',false);
        List<Account> accList = new List<Account>();
        accList.add(acc);
        accList.add(acc2);
        insert accList;
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunityWithPricebook(acc, acc2, chantier, priceBookId, true);

        // création famille et sous famille
        Familles__c fam1 = Utils_Test.createFamilles('Fenetre','Fenetre','FEN',false);
        Familles__c fam2 = Utils_Test.createFamilles('Autre','Autre','AUT',false);
        List<Familles__c> famList = new List<Familles__c>();
        famList.add(fam1);
        famList.add(fam2);
        insert famList;
        Utils_Test.createSousFamilles('PVC','PVC','PVC','FEN',true);

        return opp;
    }

    /**
     * @description création d'une Quote avec une quoteline
     *
     * @param opp Opportunity to associate the quote to
     * @param userSalesId Id du vendeur
     * @param priceBookId Id du pricebook
     * @param priceBookEntryId Id de la pricebook entry
     * @param prod Produit ? associer ? la quote
     *
     * @return La quote créée en sttaut "Non transmis"
     */
    public static SBQQ__Quote__c createSBQQQuote(Opportunity opp, Id userSalesId, Id priceBookId, Id priceBookEntryId, Product2 prod) {
        return createSBQQQuote(opp, userSalesId, priceBookId, priceBookEntryId, prod, true, null, true);
    }

    /**
     * @description création d'une Quote avec une quoteline
     *
     * @param opp Opportunity to associate the quote to
     * @param userSalesId Id du vendeur
     * @param priceBookId Id du pricebook
     * @param priceBookEntryId Id de la pricebook entry
     * @param prod Produit ? associer ? la quote
     * @param isPrimary True pour Créer un devis primaire, false pour un amendement
     * @param order seulement si isPrimary = true, Commande associ?e au devis ? mettre ? amender
     * @param withQuoteLine If true, add a quoteline to the quote
     *
     * @return La quote créée en statut "Non transmis"
     */
    public static SBQQ__Quote__c createSBQQQuote(Opportunity opp, Id userSalesId, Id priceBookId, Id priceBookEntryId,
            Product2 prod, Boolean isPrimary, Order order, Boolean withQuoteLine) {

        Id modifiableQuoteRT = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SALES_RT);
        String suffix = isPrimary ? '_initial' : '_amend';

        // Creation devis
        SBQQ__Quote__c quote = Utils_Test.createCPQQuote('Test' + suffix, modifiableQuoteRT, opp, null,
                Date.today(), 125, 50, null, null, false);
        quote.SBQQ__Primary__c = isPrimary;
        quote.AmendmentQuote__c = !isPrimary;
        quote.SBQQ__PricebookId__c = priceBookId;
        quote.initialQuoteOwner__c = userSalesId;
        quote.SBQQ__ExpirationDate__c = Date.today().addDays(14);
        quote.OwnerId = userSalesId;
        if(order != null) quote.customerOrder__c = order.Id;
        if (!isPrimary) quote.spilledCustomerOrder__c = order.Id;
        insert quote;
        System.debug('Insertion of Quote ' + quote);

        if (!isPrimary) {
            order.Status = Constants.ORDER_STATUS_AMENDING;
            order.InitialQuote__c = order.SBQQ__Quote__c;
            order.amendmentQuote__c = quote.Id;
            order.amending__c = true;

            update order;
            System.debug('quote is an amendment, update order ' + order);
        }

        if (withQuoteLine) {
            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(quote.Id, 80, 110, 1,
                    prod, false);
            qli.SBQQ__PricebookEntryId__c = priceBookEntryId;
            qli.SBQQ__CustomerPrice__c = 125.0;
            qli.SBQQ__ProratedListPrice__c = 125.0;
            qli.SBQQ__Quantity__c = isPrimary ? 3 : 1;
            qli.SBQQ__CarryoverLine__c = false;
            qli.SBQQ__Existing__c = false;
            qli.productType__c = 'Carpentry';
            insert qli;
            System.debug('Insertion of a quoteline for the quote ' + qli);
        }

        // Recharge devis et quoteline pour application des formules de calcul
        quote = [SELECT Id, MontantTotalTTC__c, SBQQ__CustomerAmount__c, SBQQ__ListAmount__c, spilledCustomerOrder__c,
                SBQQ__Status__c, SBQQ__LineItemCount__c, dateTransmissionClient__c, OwnerId, quoteIsValid__c,
                ecartCotation__c, ecartCotationPercent__c, MontantTotalHTpostBP__c, SBQQ__DistributorDiscount__c,
                AmendmentQuote__c, dateAcceptationClient__c, commStatus__c, amendInitialQuote__c, previousQuote__c, opportunityOwner__c,
                techQLValidated__c, SBQQ__Account__c, financingMethod__r.Name FROM SBQQ__Quote__c WHERE Id = :quote.Id]; //techRemVRP__c,
        System.debug('Reload quote to get updated formula fields ' + quote);

        System.debug('Update quote status');
        // Passage en non transmis
        quote.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
        //copy customerAmount to TotalHTPostBP
        quote.MontantTotalHTpostBP__c = quote.SBQQ__CustomerAmount__c;
        update quote;

        // Recharge devis et quoteline pour application des formules de calcul
        quote = [SELECT Id, MontantTotalTTC__c, SBQQ__CustomerAmount__c, SBQQ__ListAmount__c, spilledCustomerOrder__c,
                SBQQ__Status__c, SBQQ__LineItemCount__c, dateTransmissionClient__c, OwnerId, quoteIsValid__c,
                ecartCotation__c, ecartCotationPercent__c, MontantTotalHTpostBP__c, SBQQ__DistributorDiscount__c,
                AmendmentQuote__c, dateAcceptationClient__c, commStatus__c, amendInitialQuote__c, previousQuote__c, opportunityOwner__c,
                techQLValidated__c, SBQQ__Account__c, financingMethod__r.Name, referenceDate__c  FROM SBQQ__Quote__c WHERE Id = :quote.Id]; // techRemVRP__c,
        System.debug('Reload quote to get updated formula fields ' + quote);

        return quote;
    }

    public static Order createSBQQQuoteOrder(SBQQ__Quote__c quote, Product2 prod, Pricebook2 priceBook,
            PricebookEntry pricebookEntry, Account store) {

        Order o = new Order();
        o.SBQQ__Quote__c = quote.Id;
        o.AccountId = store.Id;
        o.Pricebook2Id = priceBook.Id;
        o.EffectiveDate = Date.today();
        o.Status = Constants.ORDER_STATUS_REGISTERED;
        insert o;

        // link quote to order
        quote.spilledCustomerOrder__c = o.Id;
        update quote;

        SBQQ__QuoteLine__c qli = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];

        OrderItem oi = new OrderItem(OrderId = o.Id, PricebookEntryId = pricebookEntry.Id,
                Product2Id = prod.Id, width__c = 80, height__c = 110, leaf__c = '2',
                productType__c = 'Carpentry',
                SBQQ__QuotedQuantity__c = 1, SBQQ__QuoteLine__c = qli.Id, UnitPrice = 125.0, Quantity = 1);
        insert oi;

        o.Status = Constants.ORDER_STATUS_CONFIRMED;
        o.isInApprovalProcess__c = false;
        o.isRefused__c = false;
        update o;

        return o;
    }

    /********************** ORDER OBJECT **********************/

    /**
     * @description création d'une commande client
     * @param accountId Compte associé 
     * @param chantierId Chantier
     * @param salesEntityId Entité de vente (Magasin)
     * @param serviceEntityId Entité de service (Dépot)
     * @param toInsert Définir à true pour insertion en base
     * @return Order La commande cliente créée 
     */
    public static Order createCustomerOrder(String accountId, String chantierId, String salesEntityId, String serviceEntityId, Boolean toInsert){
        Order newCustomerOrder = new Order(
            //Status = 'Registered', 
            AccountId = accountId, 
            salesEntity__c = salesEntityId,
            serviceEntity__c = serviceEntityId,
            chantier__c = chantierId,
            EffectiveDate = Date.today(), 
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER),
            shippingName__c ='TEST', 
            billingName__c ='TEST', 
            ShippingCity ='Paris', 
            ShippingPostalCode ='75000', 
            BillingCity ='Paris', 
            BillingPostalCode ='75000',
            Status = Constants.ORDER_STATUS_REGISTERED 
        );

        if(toInsert){
            insert newCustomerOrder;
        }
        return newCustomerOrder;
    }

    /**
     * @description création d'une commande client
     * @param accountId Compte associé 
     * @param toInsert Définir à true pour insertion en base
     * @return Order La commande cliente créée 
     */
    public static Order createCustomerOrder(String accountId, Boolean toInsert){
        return createCustomerOrder(accountId, null, null, null, toInsert);
    }
    
    /**
     * @description création d'une commande fournisseur
     * @param accountId Compte associé à la commande
     * @param parentOrder Commande parente à la commande
     * @param providerId Fournisseur associé à la commande
     * @param toInsert Définir à true pour insertion en base
     * @return La commande fournisseur créée en statut "Enregistré"
     */
    public static Order createProviderOrder(Id accountId, Id parentOrderId ,Id providerId, Boolean toInsert){
        String providerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);

        Order newProviderOrder = new Order( 
            Status = Constants.ORDER_STATUS_REGISTERED, 
            AccountId = accountId, 
            EffectiveDate = Date.today(), 
            provider__c = providerId,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = providerOrderRTId,
            parentOrder__c = parentOrderId);

        if(toInsert){
            insert newProviderOrder;
        }
        return newProviderOrder;
    }

    /**
     * @description création d'une commande fournisseur
     * @param accountId Compte associé à la commande
     * @param providerId Fournisseur associé à la commande
     * @param toInsert Définir à true pour insertion en base
     * @return La commande fournisseur créée en statut "Enregistré"
     */
    public static Order createProviderOrder(Id accountId, Id providerId, Boolean toInsert){
        return createProviderOrder(accountId, null, providerId, toInsert);
    }

    /********************** OrderNonCompliance OBJECT **********************/

    /**
     * @description Création d'une non conformité de commande
     * @param name Nom de la NCC 
     * @param ordId Commande parente
     * @param rtId Type d'enregistrement 
     * @param toInsert Définir à true pour insertion en base
     * @return OrderNonCompliance__c Non conformité de commande
     */
    public static OrderNonCompliance__c createOrderNonCompliance(String name, String orderId, String rtId, Boolean toInsert){
        OrderNonCompliance__c orderNonComp = new OrderNonCompliance__c(
            Name = name, 
            customerOrder__c = orderId,
            startDate__c = Date.today(),
            RecordTypeId = rtId
        );        
        if(toInsert){
            insert orderNonComp;
        }
        return orderNonComp;
    }

    /********************** OrderItem OBJECT **********************/

    /**
     * @description création d'une ligne de commande
     *
     * @param ordId Commande parente
     * @param pbeId 
     * @param assetId 
     * @param product2Id 
     * @param toInsert Définir à true pour insertion en base
     * @return Un actif lié à un produit et à un compte
     */
    public static OrderItem createOrderItem(Id ordId, Id pbeId, Id assetId, Id product2Id, Boolean toInsert){
        OrderItem newOrderItem = new OrderItem(OrderId = ordId, UnitPrice = 0, Quantity = 1, product2Id=product2Id,
                                                PriceBookEntryId=pbeId, /*confirmationDate__c = date.today(),*/ asset__c =assetId,
                                                status__c = Constants.ORDERITEM_STATUS_REGISTERED, productType__c = 'Carpentry', stageName__c = 'Enregistrement');
        if(toInsert){
            insert newOrderItem;
        }
        return newOrderItem;
    }

    /********************** WorkOrder OBJECT **********************/

    /**
     * @description création d'une demande de RDV
     * @param rtId RecordType
     * @param customerOrder Id de la commande client
     * @param toInsert Définir à true pour insertion en base
     * @return Une demande de rendez-vous
     */
    public static WorkOrder createWorkOrder(Id rtId, String customerOrder, Boolean toInsert){
        WorkOrder wo = new WorkOrder(RecordTypeId=rtId, 
                                    Duration=120, 
                                    DurationType='Minutes',
                                    customerOrder__c = customerOrder);
        if(toInsert){
            insert wo;
        }
        return wo;
    }

    /**
     * @description création d'une demande de RDV
     * @param rtId RecordType
     * @param toInsert Définir à true pour insertion en base
     * @return Une demande de rendez-vous
     */
    public static WorkOrder createWorkOrder(Id rtId, Boolean toInsert){
        return createWorkOrder(rtId, null, toInsert);
    }

    /********************** WorkOrderLineItem OBJECT **********************/

    /**
     * @description création d'une ligne de demande de RDV
     *
     * @param WorkOrderId Demande de rendez-vous parent
     * @param AssetId Actif associ? au WOLI
     * @param toInsert Définir à true pour insertion en base
     * 
     * @return Une ligne de demande de rendez-vous
     */
    public static WorkOrderLineItem createWorkOrderLineItem(Id WorkOrderId, Id AssetId, Boolean toInsert){
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId=WorkOrderId, AssetId=AssetId, Duration=120, DurationType='Minutes');
        if(toInsert){
            insert woli;
        }
        return woli;
    }

    /********************** Asset OBJECT **********************/

    /**
     * @description création d'un Asset
     * 
     * @param rtId RecordType de l'Asset
     * @param name Nom de l'actif
     * @param customerOrderId Commande cliente lié à l'actif
     * @param product2Id Produit lié à l'actif
     * @param orderItemId Ligne de commande client
     * @param accountId Compte lié à l'actif
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Un actif lié à un produit et à un compte
     */
    public static Asset createAsset(Id rtId, String name, Id customerOrderId, Id product2Id, Id orderItemId, Id chantierId, Id accountId, Boolean toInsert){
        Asset newAsset = new Asset(RecordTypeId = rtId, 
                                    customerOrder__c = customerOrderId, 
                                    Product2Id=product2Id, 
                                    chantier__c = chantierId, 
                                    Name = name, 
                                    Quantity = 1,
                                    orderItem__c = orderItemId,
                                    AccountId = accountId);
        if(toInsert){
            insert newAsset;
        }
        return newAsset;
    }

    /**
     * @description création d'un Asset
     * 
     * @param rtId RecordType de l'Asset
     * @param name Nom de l'actif
     * @param customerOrderId Commande cliente lié à l'actif
     * @param product2Id Produit lié à l'actif
     * @param accountId Compte lié à l'actif
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Un actif lié à un produit et à un compte
     */
    public static Asset createAsset(Id rtId, String name, Id customerOrderId, Id product2Id, Id accountId, Boolean toInsert){
        return createAsset(rtId, name, customerOrderId, product2Id, null, null, accountId, toInsert);
    }

    /**
     * @description création d'un Asset
     *
     * @param name Nom de l'actif
     * @param customerOrderId Commande cliente lié à l'actif
     * @param product2Id Produit lié à l'actif
     * @param chantierId Chantier lié à l'actif
     * @param accountId Compte lié à l'actif
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Un actif lié à un produit et à un compte
     */
    public static Asset createAsset(String name, Id customerOrderId, Id product2Id, Id chantierId, Id accountId, Boolean toInsert){
        return createAsset(null, name, customerOrderId, product2Id, null, chantierId, accountId, toInsert);
    }

    /**
     * @description création d'un Asset
     *
     * @param name Nom de l'actif
     * @param customerOrderId Commande cliente lié à l'actif
     * @param product2Id Produit lié à l'actif
     * @param accountId Compte lié à l'actif
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Un actif lié à un produit et à un compte
     */
    public static Asset createAsset(String name, Id customerOrderId, Id product2Id, Id accountId, Boolean toInsert){
        return createAsset(null, name, customerOrderId, product2Id, null, null, accountId, toInsert);
    }

    /********************** Product_Provider__c OBJECT **********************/

    /**
     * @description création d'un Product_Provider (lien entre le produit et son fournisseur)
     *
     * @param providerId 
     * @param productId
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Product_provider__c
     */
    public static Product_Provider__c createProductProvider(Id providerId, Id productId, Boolean toInsert){
        Product_Provider__c pp = new Product_Provider__c(provider__c=providerId, product__c=productId, startDate__c= date.today());
        if(toInsert){
            insert pp;
        }
        return pp;
    }

    /********************** ServiceAppointment OBJECT **********************/

    /**
     * @description création d'un Rendez-vous
     *
     * @param ParentRecordId Parent du SA
     * @param rtId RecordType
     * @param toInsert Définir à true pour insertion en base
     *
     * @return Un Rendez-vous
     */
    public static ServiceAppointment createServiceAppointment(Id ParentRecordId, Id rtId, Boolean toInsert){
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId=ParentRecordId, RecordTypeId=rtId, Duration=120, DurationType='Minutes');
        if(toInsert){
            insert sa;
        }
        return sa;
    }
    
    /********************** WorkType OBJECT **********************/
    public static WorkType createWorkType(String name, Boolean toInsert){
        WorkType wt1 = new WorkType(Name=name, EstimatedDuration=2, DurationType='Hours');
        if(toInsert){
            insert wt1;
        }
        return wt1;
    }

    /********************** Product Skill OBJECT **********************/
    public static ProductSkill__c createProductSkill(String skillId, Integer skillLevel, String productId, Boolean isInsert){
        ProductSkill__c pk1 = new ProductSkill__c(skill__c=skillId, skillLevel__c=skillLevel, product__c=productId);
        if(isInsert){
            insert pk1;
        }
        return pk1;
    }
    

    /********************** Skill Requierement OBJECT **********************/
    public static SkillRequirement createSkillRequirement(String skillId, Integer skillLevel, String relatedRecordId, Boolean isInsert){
        SkillRequirement reqSkill = new SkillRequirement(SkillId=skillId, SkillLevel=skillLevel, RelatedRecordId=relatedRecordId);
        if(isInsert){
            insert reqSkill;
        }
        return reqSkill;
    }

    /********************** FSL Scheduling Policy OBJECT **********************/
    public static FSL__Scheduling_Policy__c createSchedulingPolicy(String name, Boolean isInsert){
        FSL__Scheduling_Policy__c fslSp1 = new FSL__Scheduling_Policy__c(Name=name);
        if(isInsert){
            insert fslSp1;
        }
        return fslSp1; 
    }

    /********************** Group OBJECT **********************/
    public static Group createGroup(String type, String name, String developerName, Boolean isInsert){
        Group newGroup = new Group(
            Type=type, 
            Name=name, 
            DeveloperName =developerName);
        if(isInsert){insert newGroup;}
        return newGroup;
    }

    /********************** ACCOUNTINGPIECE OBJECT **********************/

    /**
     * @description création d'une piece comptable
     * @param rtId RecordType 
     * @param orderId Commande cliente lié à l'actif
     * @param orderEntity Entité de la commande
     * @param inputEntity Entité de sasie
     * @param bankAccount Compte bancaire
     * @param paymentMethod Id méthode de reglement
     * @param cancelledPiece Id piece annulée
     * @param parent Id parent
     * @param amount Montant
     * @param pieceDate Date de la piece
     * @param dueDate Date d'échéance
     * @param dueDate Date comptable
     * @param toInsert Définir à true pour insertion en base
     * @return Une piece comptable
     */
    public static AccountingPiece__c createAccountingPiece(Id rtId, String orderId, String orderEntity, String inputEntity, String bankAccount, String paymentMethod, 
                                                            String cancelledPiece, String parent, Decimal amount, Date pieceDate, Date dueDate, Date accountingDate, Boolean toInsert)
    {
        AccountingPiece__c accPiece = new AccountingPiece__c(RecordTypeId = rtId,
                                order__c = orderId,
                                orderEntity__c = orderEntity,
                                inputEntity__c = inputEntity,
                                entityBankAccount__c = bankAccount,
                                cancelledPiece__c = cancelledPiece,
                                parent__c = parent,
                                pieceDate__c = pieceDate,
                                dueDate__c = dueDate,
                                accountingDate__c = accountingDate,
                                paymentMethod__c = paymentMethod,
                                amount__c = amount,
                                externalBank__c = 'TEST',
                                externalReference__c = 'TEST');
        if(toInsert){
            insert accPiece;
        }
        return accPiece;
    }

        /********************** PASSIVECONTACTRECIPIENT OBJECT **********************/

    /**
     * @description création d'un Destinataire Contact Passif
     * @param entite Entité commerciale liée au destinataire
     * @param recipientType Type de destinataire (REF,DVA,DV,DO)
     * @param startDate Date de début de validité
     * @param toInsert Définir à true pour insertion en base
     * @return Une piece comptable
     */
    public static PassiveContactRecipient__c createPassiveContactRecipient(Id entiteId, String recipientType,Date startDate, Boolean toInsert)
    {
        PassiveContactRecipient__c passiveContact = new PassiveContactRecipient__c(
                                        entity__c = entiteId,
                                        startDate__c = startDate,
                                        recipientType__c = recipientType

        );
        if(toInsert){
            insert passiveContact;
        }
        return passiveContact;
    }
}