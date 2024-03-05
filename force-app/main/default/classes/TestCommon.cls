//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TestCommon
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/06/2017
//-- Version     : 1.3
//-- * Utilisation pricebookentry de test
//-- --------------------------------------------------------------------------------- --
@isTest
public class TestCommon {
    private static final Sectorisation__c IRIS = createSectorisation();
    private static Integer sectNumber = 1;
    private static final Date limiteC2E = Date.newInstance(2015, 09, 03);

    public static Sectorisation__c createSectorisation() {
        Sectorisation__c sectorisation = new Sectorisation__c();

        sectNumber = (sectNumber == null) ? 0 : sectNumber + 1;
        sectorisation.iris__c               = 'IRS_'+sectNumber;
        sectorisation.codeMagasin__c        = 'MAG_0000';
        sectorisation.libelleMagasin__c     = 'Magasin 0000';
        sectorisation.codeDV__c             = 'DV_0000';
        sectorisation.libelleDV__c          = 'Direction des ventes 0000';
        sectorisation.codeRegion__c         = 'DR_0000';
        sectorisation.libelleRegion__c      = 'Région 0000';
        sectorisation.codeDepot__c          = 'DEP_0000';
        sectorisation.libelleDepot__c       = 'Dépôt 0000';
        sectorisation.codeDS__c             = 'DS_0000';
        sectorisation.libelleDS__c          = 'Direction service 0000';

        return sectorisation;
    }

    //CRM 271 - SEO - 23/05/2013 suppression versionEntite => create Sectorisation
    public static Sectorisation__c createSectorisation(String nomSecto, String codeMag, String nomMag, String codeDepot, String nomDepot){
        Sectorisation__c sectorisation = new Sectorisation__c(Name = nomSecto,
                                                                codeMagasin__c  = codeMag,
                                                                libelleMagasin__c = nomMag,
                                                                codeDepot__c = codeDepot,
                                                                libelleDepot__c =nomDepot);
        insert sectorisation;
        return sectorisation;
    }

    //create User
    public static User createUser(boolean bypass,String alias, String userName, String lastName, String firstName, Id ProfileId) {
        System.debug('### Start createUser');
        User u=new User();

        u.UserRoleId=System.Label.RTRole;

        u.ByPassValidationRule__c=bypass;
        u.ByPassWorkflowRule__c=true;
        u.Username= userName;
        u.LastName= lastName;
        u.FirstName= firstName;
        u.Email= userName;
        u.UserPermissionsMarketingUser=true;
        u.Alias= alias;
        u.CommunityNickname= alias;
        u.TimeZoneSidKey='Europe/Paris';
        u.LocaleSidKey='fr_FR_EURO';
        u.EmailEncodingKey='ISO-8859-1';
        if(ProfileId == null)
            u.ProfileId=[SELECT id, name FROM Profile WHERE name = 'System Administrator' OR name = 'Administrateur système' LIMIT 1].Id;
        else
            u.ProfileId = ProfileId;
        System.debug('ProfileId: '+ProfileId);
        u.LanguageLocaleKey='fr';
        u.isActive=true;
        System.debug('user:'+u);

        insert u;
        System.debug('### UserCreatedId:'+u.Id);
        System.debug('### End createUser');
        return u;
    }

    public static User createUser (boolean bypass,String alias, String userName, String lastName, String firstName, Id ProfileId, String CodeDR, String CodeDV, String CodeMagasin) {
        System.debug('### Start createUser');
        User u=new User();

        u.UserRoleId=System.Label.RTRole;

        u.ByPassValidationRule__c=bypass;
        u.ByPassWorkflowRule__c=true;
        u.Username= userName;
        u.LastName= lastName;
        u.FirstName= firstName;
        u.Email= userName;
        u.UserPermissionsMarketingUser=true;
        u.Alias= alias;
        u.CommunityNickname= alias;
        u.TimeZoneSidKey='Europe/Paris';
        u.LocaleSidKey='fr_FR_EURO';
        u.EmailEncodingKey='ISO-8859-1';
        if(ProfileId == null)
            u.ProfileId=[SELECT id, name FROM Profile WHERE name = 'System Administrator' OR name = 'Administrateur système' LIMIT 1].Id;
        else
            u.ProfileId = ProfileId;
        System.debug('ProfileId: '+ProfileId);
        u.LanguageLocaleKey='fr';
        u.CodeDR__c = CodeDR;
        u.CodeDV__c = CodeDV;
        u.CodeMagasin__c = CodeMagasin;
        u.isActive=true;

        System.debug('user: '+u);

        insert u;

        System.debug('### UserCreatedId:'+u.Id);
        System.debug('### End createUser');

        return u;
    }

    public static User createUser (boolean bypass,String alias, String userName, String lastName, String firstName, Id ProfileId, String CodeDR, String CodeDV, String CodeMagasin, String ByPassTrigger) {
        System.debug('### Start createUser');
        User u=new User();

        u.UserRoleId=System.Label.RTRole;

        u.ByPassValidationRule__c=bypass;
        u.ByPassWorkflowRule__c=true;
        u.Username= userName;
        u.LastName= lastName;
        u.FirstName= firstName;
        u.Email= userName;
        u.UserPermissionsMarketingUser=true;
        u.Alias= alias;
        u.CommunityNickname= alias;
        u.TimeZoneSidKey='Europe/Paris';
        u.LocaleSidKey='fr_FR_EURO';
        u.EmailEncodingKey='ISO-8859-1';
        if(ProfileId == null)
            u.ProfileId=[SELECT id, name FROM Profile WHERE name = 'System Administrator' OR name = 'Administrateur système' LIMIT 1].Id;
        else
            u.ProfileId = ProfileId;
        System.debug('ProfileId: '+ProfileId);
        u.LanguageLocaleKey='fr';
        u.isActive=true;
        u.CodeDR__c = CodeDR;
        u.CodeDV__c = CodeDV;
        u.CodeMagasin__c = CodeMagasin;
        u.ByPassTrigger__c = ByPassTrigger;

        System.debug('user: '+u);

        insert u;

        System.debug('### UserCreatedId:'+u.Id);
        System.debug('### End createUser');

        return u;
    }

    //create Account
    public static Account createAccount(boolean isInsert, String name, Id recordtype, String canalprefere, String adresseemail) {
        if (IRIS.Id == null) insert IRIS;
        System.debug('createAccount');
        Account a = new Account(salutation = 'M.',
                                firstName = name,
                                LastName = name,
                                RecordTypeId = recordtype,
                                Canalprefere__c = canalprefere,
                                PersonMailingPostalCode='12345',
                                PersonMailingCity='City123',
                                PersonMailingCountry='Country123',
                                PersonEmail = adresseemail,
                                AccountSource = 'CCM',
                                iris__c = IRIS.iris__c);

        if(isInsert) {
            insert a;
            System.debug('createAccount Id created:'+a.Id);
        }

        System.debug('Owner Id:'+a.OwnerId);
        return a;
    }

    // create Contact
    public static Contact createContact (String name, Id accountId) {
        Contact c = new Contact (LastName = name, accountId = accountId);
        insert c;
        return c;
    }

    // create Chantier
    public static Chantier__c createChantier (String name, Id recordtype) {
        if (IRIS.id == null) insert IRIS;
        System.debug('Create Chantier');
        Chantier__c c = new Chantier__c (Name = name,
                                        RecordTypeId = recordtype,
                                        codepostal__c = '12345',
                                        libelleMagasinReference__c = 'HORS ZNE',
                                        codeMagasinReference__c = '00025',
                                        ville__c = 'City123',
                                        pays__c = 'Country123',
                                        iris__c = IRIS.iris__c);
        insert c;
        System.debug('Chantier Id created: ' + c.Id);
        return c;
    }

    //SEO 15/07/2013 chantier avec sectorisation
    public static Chantier__c createChantierSecto (String name, Id recordtype, Id compteId) {
        if (IRIS.id == null) insert IRIS;
        System.debug('Create ChantierSecto');
        Sectorisation__c secto = new Sectorisation__c(codeMagasin__c='MAG001');
        insert secto;
        Chantier__c c = new Chantier__c (Name = name,
                                        RecordTypeId = recordtype,
                                        codepostal__c = '13001',
                                        libelleMagasinReference__c = 'HORS ZNE',
                                        codeMagasinReference__c = '00025',
                                        rue__c = 'aa',
                                        ville__c = 'Marseille',
                                        pays__c = 'France',
                                        sectorisation__c = secto.Id,
                                        proprietaire__c=compteId,
                                        iris__c = IRIS.iris__c);
        insert c;
        System.debug('Sectorisation magasin: ' + secto.Id+'__'+secto.codeMagasin__c);
        System.debug('Chantier Id created: ' + c.Id + '___'+ c.codeMagasinActuel__c);
        return c;
    }

    //SEO 15/07/2013 chantier avec proprietaire
    public static Chantier__c createChantierProp (String name, Id recordtype, Id compteId) {
        if (IRIS.id == null) insert IRIS;
        System.debug('createChantierProp');
        Chantier__c c = new Chantier__c (Name = name,
                                        RecordTypeId = recordtype,
                                        codepostal__c = '13001',
                                        libelleMagasinReference__c = 'HORS ZNE',
                                        codeMagasinReference__c = '00025',
                                        rue__c = 'aa',
                                        ville__c = 'Marseille',
                                        pays__c = 'France',
                                        proprietaire__c=compteId,
                                        iris__c = IRIS.iris__c);
        insert c;
        return c;
    }

    // create Opportunity
    public static Opportunity createOpportunity(Id accountId, Id chantierId) {
        system.debug('Create Opportunity');
        Opportunity o = new Opportunity(AccountId = accountId,
                                        name = 'Test Opportunity',
                                        closeDate = System.today(),
                                        stageName = 'Proposition',
                                        Type = 'Nouveau',
                                        LeadSource = 'P',
                                        chantier__c = chantierId);
        insert o;
        system.debug('Opportunity Id created: ' + o.Id);
        return o;
    }

    //Creation opportunity avec opération
    public static Opportunity createOpportunityWithOperation(Id accountId, Id chantierId, Id operationId){
        Opportunity opp = new Opportunity(operation__c = operationId,
                                            AccountId = accountId,
                                            name = 'Test Opportunity',
                                            closeDate = System.today(),
                                            stageName = 'Proposition',
                                            Type = 'Nouveau',
                                            chantier__c = chantierId);
        insert opp;
        System.debug('Opportunity Id created: ' + opp.Id);
        return opp;
    }

    //CRM 271 - SEO - 23/05/2013 => creation contrat
    public static KContrat__c createContrat (boolean isInsert, String name, Id chantierId, Id compteId, String numContrat) {
        KContrat__c contrat = new KContrat__c (Name = name,
                                                chantier__c = chantierId,
                                                compte__c = compteId,
                                                numeroContrat__c=numContrat);
        if(isInsert) {
            insert contrat;
        }
        return contrat;
    }

        //Create Devis
        public static Quote createDevis(String statut, String nom, Date dateDevis, Id opportunityId) {
                System.debug('Create devis');
                Id pb = Test.getStandardPricebookId();

                Quote c = new Quote(Status = statut,
                                    Name = nom,
                                    datedevis__c = dateDevis,
                                    OpportunityId = opportunityId,
                                    C2E__c = (dateDevis <= limiteC2E ? 'Oui' : null),
                                    Total_TTC_devis__c = 1000,
                                    Pricebook2Id = pb,
                                    source__c = 'BAL VENDEUR');

                // CRM-227 - 10/10/2012 – ALT : Si le devis est transmis alors le moyen de transmission doit être renseigné
                if(statut != NULL && statut.compareTo('Transmis') == 0)
                        c.Moyentransmissionclient__c = 'Par email';

                insert c;
                System.debug('Devis Id created: '+c.Id);
                return c;
        }

        // Create Devis avec opération
        public static Quote createDevisWithOperation(String statut, String nom, Date dateDevis, Id opportunityId, ReferentielOperation__c operation) {
                Id pb = Test.getStandardPricebookId();

                Quote quote = new Quote(Status = statut,
                                                        Name = nom,
                                                        datedevis__c = dateDevis,
                                                        OpportunityId = opportunityId,
                                                        C2E__c = (dateDevis <= limiteC2E ? 'Oui' : null),
                                                        Total_TTC_devis__c = 1000,
                                                        Pricebook2Id = pb,
                                                        operation__c = operation.Id);

                // CRM-227 - 10/10/2012 – ALT : Si le devis est transmis alors le moyen de transmission doit être renseigné
                if(statut != NULL && statut.compareTo('Transmis') == 0)
                        quote.Moyentransmissionclient__c = 'Par email';

                insert quote;
                System.debug('Devis Id created: '+ quote.Id);
                return quote;
        }

    //Create Ligne de devis
    public static QuoteLineItem createLigneDevis(Id quoteId,String nombrevantaux,Integer largeur,Integer hauteur,Integer qte,Decimal prixHorsdimension,Id pricbookentryId,Decimal unitprix) {
        System.debug('Create Ligne de devis');
        QuoteLineItem c = new QuoteLineItem(QuoteId = quoteId,Nombredevantaux__c = nombrevantaux,Hauteur__c=hauteur,Largeur__c=largeur,Quantity=qte,Tarifhorsdimension__c=prixHorsdimension,PricebookEntryId=pricbookentryId,UnitPrice=unitprix);
        insert c;
        System.debug('Ligne de devis Id created:'+c.Id);
        return c;
    }

    //Create Ligne de devis
    public static QuoteLineItem createLigneDevis(Id quoteId,String nombrevantaux,Integer largeur,Integer hauteur,Integer qte,Decimal prixHorsdimension,Decimal unitprix) {
        System.debug('Create Product');
        Product2 product2 = createProduct('Produit Test', 'FFFETT');
        System.debug('Create PricebookEntry');
        PricebookEntry pbe = createPricebookEntry(product2);
        System.debug('Create QuoteLineItem');
        QuoteLineItem c = new QuoteLineItem(QuoteId = quoteId,Nombredevantaux__c = nombrevantaux,Hauteur__c=hauteur,Largeur__c=largeur,Quantity=qte,Tarifhorsdimension__c=prixHorsdimension, PricebookEntryId = pbe.Id,UnitPrice=unitprix);
        insert c;
        System.debug('Ligne de devis Id created:'+c.Id);
        return c;
    }

    //create Product
    public static Product2 createProduct(String Nom,String CodeProduit) {
        System.debug('createProduct');
        Product2 produit = new Product2 (Name = Nom, ProductCode = CodeProduit, Reference__c= CodeProduit, IsActive = true);
        insert produit;
        System.debug('produit Id created:'+produit.Id);
        return produit;
    }

    //create Product
    public static Product2 createProduct(String Nom, String CodeProduit, String Famille, String SousFamille) {
        System.debug('createProduct');
        Product2 produit = new Product2 (Name = Nom, ProductCode = CodeProduit, Reference__c= CodeProduit, Family = Famille, SousFamille__c = SousFamille, IsActive = true);
        insert produit;
        System.debug('produit Id created:'+produit.Id);
        return produit;
    }

    //create PricebookEntry
    public static PricebookEntry createPricebookEntry(Product2 p) {
        Id pb = Test.getStandardPricebookId();
        System.debug('createPricebookEntry');
        PricebookEntry Pbe = new PricebookEntry (Pricebook2Id = pb, Product2Id = p.Id, IsActive = true, UnitPrice = 10.0,UseStandardPrice = false);
        insert Pbe;
        System.debug('createPricebookEntry Id created:'+Pbe.Id);
        return Pbe;
    }

    //create Option
    public static Option__c createOption(String qliId, String CodeOption, String LibelleOption) {
        system.debug('createOption');
        Option__c option = new Option__c(ligneDevis__c = qliId, PrixunitaireHT__c = 1, Codeoption__c = CodeOption, Libelleoption__c = LibelleOption);
        insert option;
        system.debug('createOption Id created:' + option.Id);
        return option;
    }

    //creation document
    public static Document createDocument(boolean isInsert, String name, String dvpname) {
        Folder folder = [select Id From Folder][0];
        List<Document> liste = [Select Name, FolderId, DeveloperName from Document where DeveloperName = :dvpname];
        Document doc;
        if(liste.size()==0){
            doc = new Document(Name=name, FolderId=folder.Id, DeveloperName=dvpname);
            if(isInsert) {
                insert doc;
            }
        }
        else{
            doc=liste.get(0);
        }
        return doc;
    }

    //creation operation
    public static ReferentielOperation__c createOperation(boolean isInsert, String name, Date dateDeb, Date dateFin, String ville, Double coutEmp, Double coutMon, Double autrCout, String precisionCout ){
        ReferentielOperation__c opt = new ReferentielOperation__c(
                                                        Name= name,
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
                                                        Code_DV__c='O01');

        if(isInsert)
            insert opt;
        return opt;
    }

    //creation suivi operation
    public static Suivi_operations__c createSuiviOperation(boolean isInsert, String name){
        Suivi_operations__c suiviOpt = new Suivi_operations__c( Name= name );

        if(isInsert) {
            insert suiviOpt;
        }
        return suiviOpt;
    }

    //creation liste operations
    public static Suivi_operations__c createListOperation(boolean isInsert, List<ReferentielOperation__c> opts){
        //creation suiviOP
        Suivi_operations__c suiviOpt = createSuiviOperation(true, 'suiviOptTest');
        Integer nameList = 0;
        //association liste operation au suiviOpt
        for(ReferentielOperation__c op : opts){
            nameList++;
            IntersectionOp_rations__c listOpt = new IntersectionOp_rations__c(IntersectionOperationOperation__c = op.Id, Suivi_des_operations__c = suiviOpt.Id);

            if(isInsert) {
                insert listOpt;
            }
        }
        return suiviOpt;
    }

    //creation event
    public static Event createEvent(boolean isInsert, String nameRecordType, String typeEvent, SObject associe, SObject nom, User owner){
        RecordType rt = [select Id from  RecordType where name = :nameRecordType limit 1][0];
        Event event = new Event();
        if(associe==null){
            if(nom==null){
                event = new Event(RecordTypeId=rt.Id,
                                                Type=typeEvent,
                                                StatutRDV__c='Effectué',
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=owner.Id);

            }
            if(nom!=null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhoId=nom.Id,
                                                Type=typeEvent,
                                                StatutRDV__c='Effectué',
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=owner.Id);
            }
        }
        if(associe!=null){
            if(nom==null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhatId=associe.Id,
                                                Type=typeEvent,
                                                StatutRDV__c='Effectué',
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=owner.Id);
            }
            if(nom!=null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhatId=associe.Id,
                                                WhoId=nom.Id,
                                                Type=typeEvent,
                                                StatutRDV__c='Effectué',
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=owner.Id);
            }
        }

        if(isInsert) {
            insert event;
        }
        return event;
    }

    public static Event createEvent(boolean isInsert, String nameRecordType, String typeEvent, String statutRDV, SObject associe, SObject nom, Id ownerId){
        RecordType rt = [select Id from  RecordType where name = :nameRecordType limit 1][0];
        Event event = new Event();
        if(associe==null){
            if(nom==null){
                event = new Event(RecordTypeId=rt.Id,
                                                Type=typeEvent,
                                                StatutRDV__c= statutRDV,
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=ownerId);

            }
            if(nom!=null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhoId=nom.Id,
                                                Type=typeEvent,
                                                StatutRDV__c= statutRDV,
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=ownerId);
            }
        }
        if(associe!=null){
            if(nom==null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhatId=associe.Id,
                                                Type=typeEvent,
                                                StatutRDV__c= statutRDV,
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=ownerId);
            }
            if(nom!=null){
                event = new Event(RecordTypeId=rt.Id,
                                                WhatId=associe.Id,
                                                WhoId=nom.Id,
                                                Type=typeEvent,
                                                StatutRDV__c= statutRDV,
                                                Couplepresent__c='Oui',
                                                StartDateTime=date.today(),
                                                EndDateTime=date.today(),
                                                ResultatduRDV__c='Devisable',
                                                OwnerId=ownerId);
            }
        }

        if(isInsert) {
            insert event;
        }
        return event;
    }

    public static ReferentielOptions__c createRefOpt(String codeOption, Double typeOption, string libelle){
        ReferentielOptions__c option = new ReferentielOptions__c(codeOption__c = codeOption);
        option.Typedeloption__c = typeOption;
        option.LibelleOption__c = libelle;
        option.actif__c = true;
        insert option;
        return option;
    }

    public static Pack__c createPack(id codePereId, id codeFilsId, Integer typeRegroupement, Id RevisionId){
        Pack__c p = new Pack__c();
        p.CodePere__c = codePereId;
        p.CodeFils__c = codeFilsId;
        p.TypeRegroupement__c = typeRegroupement;
        p.IDRevision__c = RevisionId;
        insert p;
        return p;
    }

    //CRM 381 - SEO - 02/08/2013
    public static Task createTask(Id whoId, Id whatId, String statut, Id ownerId, Boolean toInsert){
        Task task = new Task(Subject = 'Appel', Priority = 'Normal', OwnerId = ownerId,
        WhoId = whoId, WhatId = whatId, Status = statut );
        if(toInsert == true) {
            insert task;
        }
        return task;
    }

    // CRM-490 WDO :récupération des listes associés
    public static Attachment createAttachment(String name, String parentId, Blob bodyBlob) {
        Attachment att = new Attachment(Name = name, ParentId = parentId, Body = bodyBlob);
        insert att;
        return att;
    }

    // CRM-490 WDO :récupération des listes associés
    public static Note createNote(String name, String parentId, String body) {
        Note note = new Note(Title = name, ParentId = parentId, Body = body);
        insert note;
        return note;
    }

    // CRM-490 WDO :récupération des listes associés
    public static Case createCase(Id recordtype, String accountId, String chantierId) {
        Case cases = new Case(accountId = accountId, recordTypeId = recordtype, chantier__c = chantierId);
        insert cases;
        return cases;
    }

    public static void createGlobalProperties(boolean geocoderEnabled, Integer geocoderMin, boolean ltvFilEnabled, boolean ltvLtcEnabled, boolean ltvParEnabled, Integer tabSearchMax, Integer tabViewMax, boolean userCacheEnabled) {
        // Création des paramètres globaux
        PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', geocoderEnabled);
        PropertiesUtils.setBooleanValue('geoconcept.geocoder.enabled', geocoderEnabled);
        PropertiesUtils.setIntegerValue('geoconcept.geocoder.minscore', geocoderMin);
        PropertiesUtils.setIntegerValue('tabview.search.maxcount', tabSearchMax);
        PropertiesUtils.setIntegerValue('tabview.view.maxcount', tabViewMax);
        PropertiesUtils.setBooleanValue('usercontext.cache.enabled', userCacheEnabled);
    }
    
    public static ListePhoningVendeur__c getListeById(string id) {
        return [SELECT Id, name, user__c, recordType_Filtre__c, typeCompte_Filtre__c, proprietaire_Filtre__c, 
                                                    rue1_Filtre__c, codePostal_Filtre__c, rue2_Filtre__c, rue3_Filtre__c, ville_Filtre__c, dernierAppel_Filter__c, 
                                                    DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c 
                                                    FROM ListePhoningVendeur__c WHERE Id = :id LIMIT 1];
    }
}