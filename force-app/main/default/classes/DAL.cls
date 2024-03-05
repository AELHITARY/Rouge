//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : DAL
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/06/2022
//-- Version     : 4.0
//-- * 4.0 : Ajout fonction KUBE3
//-- * 3.9 : Optimisation en ajoutant getRecordTypeIdByDevName sans requête SOQL
//-- * 3.8 : CRM-956 Refonte des requêtes
//-- --------------------------------------------------------------------------------- --
public class DAL {
    
    public static Set<string> makeSet(List<sobject> sobjList, string key){
        Set<string> setToReturn = new Set<string>();
        if(sobjList == null)
            return setToReturn;
        for(Sobject sobj : sobjList){
            if(sobj.get(key) != null)
                setToReturn.add(String.valueOf(sobj.get(key)));
        }
        return setToReturn;
    }
    
    public static EmailTemplate getEmailTemplateByName(string ETName){
        return [Select Body, HtmlValue, Id, Name, Subject
                From  EmailTemplate
                where developerName =: ETName
                limit 1];
    }
    
    public static List<Grille_de_tarif__c> getGrillesTarifs(Set<string> codesTarifs, Date dateDevis){
        return [Select g.Prix6vantaux__c, g.Prix5vantaux__c, g.Prix4vantaux__c, g.Prix3vantaux__c, g.Prix2vantaux__c, g.Prix1vantail__c, g.Dimension__c, g.Datedapplication__c, g.CodeGrilleTarif__c
                From Grille_de_tarif__c g
                where g.CodeGrilleTarif__c in: codesTarifs
                And Datedapplication__c <=: dateDevis
                And (Date_fin_validite__c = null Or Date_fin_validite__c >=: dateDevis)
                And g.actif__c = true
                order by Datedapplication__c DESC, dimension__c ASC];
    }
    
    /**
    * @description Récupération d'un document par son nom API
    * @param devName Nom API du document
    * @return Document Instance de l'objet document
    */
    public static Document getDocumentByName(String devName){
        List<Document> rst = [SELECT Id, DeveloperName FROM Document WHERE DeveloperName=:devName LIMIT 1];
        if(rst.size()>0)
            return rst[0];
        else return null;
    }
    
    /**
    * @description DEPRECATED - Récupération de l'ID d'un record type par son nom API
    * @param devName Nom API du record type
    * @return String ID du record type
    */
    public static String getRecordTypeIdByDevName(String devName){
        List<RecordType> rst = [SELECT Id FROM RecordType WHERE DeveloperName=:devName LIMIT 1];
        if(rst.size()>0)
            return rst[0].Id;
        else return null;
    }
    
    /**
    * @description Récupère l'ID d'un record Type selon le nom de l'objet et l'API Name du record type dans requête SOQL
    * @param sObjectName Nom API de l'objet du record type
    * @param devName Nom API du record type
    * @return String Id du record type, null si aucun existant
    */
    public static String getRecordTypeIdByDevName(String sObjectName, String devName) {
        String rtId = null;
        for(Schema.DescribeSobjectResult res : Schema.describeSObjects(new List<String>{sObjectName})) {
            Map<String,Schema.RecordTypeInfo> rtMapByDevName = res.getRecordTypeInfosByDeveloperName();
            if(rtMapByDevName.get(devName) != null) {
                Schema.RecordTypeInfo rtByDevName = rtMapByDevName.get(devName);
                rtId = rtByDevName.getRecordTypeId();
                break;
            }
        }
        return rtId;
    }

    public static List<BonusProjet__c> getBonusProjet(decimal borneInf, decimal borneSup, Date dateDevis){
        return [select b.Montantplancher__c, b.Montantplafond__c, b.Datedapplication__c, b.Coefficientremise__c
                From BonusProjet__c b
                where b.Montantplancher__c <=: borneInf
                And b.Montantplafond__c >=: borneSup
                And b.Datedapplication__c <=: dateDevis
                order by b.Datedapplication__c desc];
    }
    
    public static List<Remise_Incentive__c> getRemiseIncentive(decimal borneInf, decimal borneSup){
        Integer  delai = PropertiesUtils.getIntegerValue('tarif.recherche.validite.incentive', 130); // Délai de recherche sur validité des incentives ~4 mois
        Date dateValidite = System.today().addDays(0 - delai);
        List<Remise_Incentive__c> remIncentives = [SELECT Codeincentive__c, Codeincentive__r.OriginesElligibles__c, Codeincentive__r.DebutValidite__c, Codeincentive__r.FinValidite__c,
                                                   Codeincentive__r.Magasinselligibles__c, MontantPlancher__c, MontantPlafond__c, CoefficientRemise__c
                                                   FROM Remise_Incentive__c
                                                   WHERE Montantplancher__c <=: borneInf
                                                   AND Montantplafond__c >=: borneSup
                                                   AND actif__c = true
                                                   /* >>> F.G., le 20/08/2013 */
                                                   AND Codeincentive__r.actif__c = true
                                                   AND (Codeincentive__r.finValidite__c = null OR Codeincentive__r.finValidite__c >= :dateValidite)
                                                   /* <<< F.G., le 20/08/2013 */
                                                  ];
        system.debug('### getRemiseIncentive : borneInf = ' + borneInf + ' / borneSup = ' + borneSup + 'délai = ' + delai + ' / date = ' + dateValidite + ' / quantité = ' + remIncentives.size());
        return remIncentives;
    }
    
    public static Map<Id, ReferentielOptions__c> getRefOptionsMap(set<Id> referentielOptionsIds){
        return new map<Id, ReferentielOptions__c> ([SELECT Id, Typedeloption__c, PrixReferencePromotion__c, OptionPromotionnelle__c FROM ReferentielOptions__c
                                                    WHERE Id IN :referentielOptionsIds]);
    }
    
    /************* SERVICE APPOINTMENTS **********************/
    public static List<ServiceAppointment> getServiceAppointmentsByIdList(String rdvId){
        return [SELECT Id, ParentRecordId, WorkTypeId, WorkType.Name, AccountId, Account.Name,  Account.FirstName,  Account.LastName, Account.civilite__c, ContactId, Contact.Name,
                    Account.AccountNumber, Account.rue__c, Account.codePostal__c, Account.ville__c, Account.complementAdresse__c, customerOrder__c,
                    Chantier__r.rue__c, Chantier__r.complementAdresse__c, Chantier__r.codePostal__c, Chantier__r.ville__c, SchedStartTime, SchedEndTime, fsl_coutsProchainRDV__c, ServiceTerritoryId,
                    ServiceTerritory.Name, ServiceTerritory.City, ServiceTerritory.PostalCode, ServiceTerritory.Street, ServiceTerritory.State, ServiceTerritory.KparKReference__c,
                    Street, PostalCode, City, fsl_externalId__c, dateConfirmationClient__c
                FROM ServiceAppointment WHERE Id = :rdvId
                ORDER BY CreatedDate DESC];
    }
    
    /************* ACCOUNT **********************/
    public static Account getAccountById(Id id){
        List<Account> accounts = SchemaUtils.executeQuery('Account', id);
        return accounts == null || accounts.isEmpty() ? null : accounts[0];
    }
    
    /************* QUOTE **********************/
    public static Quote getQuoteById(string quoteId){
        Map<String, String> relations = new Map<String, String>();
        relations.put('Quote.Opportunity.Owner', 'User');
        relations.put('Quote.Opportunity.Chantier__r', 'Chantier__c');
        relations.put('Quote.Opportunity', 'Opportunity');
        relations.put('Quote.compte__r', 'Account');
        relations.put('Quote.circuitSignatureDevis__r', 'Signea__Circuit__c');
        relations.put('Quote.circuitSignatureContrat__r', 'Signea__Circuit__c');
        List<Quote> quotes = (List<Quote>) SchemaUtils.executeQuery('Quote',quoteId, relations);
        return quotes == null || quotes.isEmpty() ? null : quotes[0];
    }
    
    /************* QUOTE LINE ITEM **********************/
    // CRM-462 - WDO - Récupération des lignes de devis par ID Quote avec posssibilité de tri (ORDER BY)
    public static List<QuoteLineItem> getQuoteLineItemList(String quoteId, String orderby){
        Map<String, String> relations = new Map<String, String>();
        relations.put('PriceBookEntry.product2', 'Product2');
        relations.put('PriceBookEntry', 'PriceBookEntry');
        return SchemaUtils.executeQuery('QuoteLineItem', 'quoteId', quoteId, relations, orderby);
    }
    // CRM-462 - WDO
    
    // Récupération des lignes de devis par ID Quote
    public static List<QuoteLineItem> getQuoteLineItemList(String quoteId){
        Map<String, String> relations = new Map<String, String>();
        relations.put('PriceBookEntry.product2', 'Product2');
        relations.put('PriceBookEntry', 'PriceBookEntry');
        return SchemaUtils.executeQuery('QuoteLineItem', 'quoteId', quoteId, relations);
    }
    
    // Récupération des lignes de devis par ID QuoteLineItem
    public static QuoteLineItem getQuoteLineItemById(String quoteLineItemId){
        Map<String, String> relations = new Map<String, String>();
        relations.put('PriceBookEntry.product2', 'Product2');
        relations.put('PriceBookEntry', 'PriceBookEntry');
        relations.put('Quote', 'Quote');
        List<QuoteLineItem> quoteLineItems = (List<QuoteLineItem>) SchemaUtils.executeQuery('QuoteLineItem', quoteLineItemId, relations);
        return quoteLineItems == null || quoteLineItems.isEmpty() ? null : quoteLineItems[0];
    }
    
    // Récupération des lignes de devis par liste de devis
    public static List<QuoteLineItem> getQLIList(List<Quote> quotes){
        return [SELECT id, Aconfigurer__c, quoteId, quote.Status, Quantity, cancelledLine__c,
                PricebookEntry.Product2.sousFamille__c, PricebookEntry.Product2.sousMatiere__c, PricebookEntry.Product2.Reference__c
                FROM QuoteLineItem WHERE quoteId in :quotes];
    }
    
    // Récupération des lignes de devis par liste de lignes de devis
    public static List<QuoteLineItem> getQLIList(List<QuoteLineItem> qliList){
        return [SELECT quote.opportunity.account.PersonContactId, quoteId, quote.opportunityId
                FROM QuoteLineItem WHERE id in: qliList AND quote.opportunity.account.PersonContactId != null];
    }
    
    public static Map<Id, QuoteLineItem> getQuoteLineItemMap(Set<Id> quoteLineItemIds){
        return new map<Id, QuoteLineItem> ([SELECT Id, Hauteur__c, Largeur__c, PrixunitaireHTtarifoptions__c, Nombredevantaux__c, unitprice, cancelledLine__c
                                            FROM QuoteLineItem WHERE Id IN :quoteLineItemIds]);
    }
    
    /************* OPTION **********************/
    // Récupération des options par ID Quote
    public static List<Option__c> getOptionList(String quoteId){
        Map<String, String> relations = new Map<String, String>();
        relations.put('ligneDevis__r', 'QuoteLineItem');
        relations.put('ligneDevis__r.PriceBookEntry.product2', 'Product2');
        return SchemaUtils.executeQuery('Option__c', 'ligneDevis__r.quoteId', quoteId, relations);
    }
    
    // Récupération des options par liste d'options
    public static List<Option__c> getOptionList(List<Option__c> optList){
        return [SELECT codeoption__c, Quantite__c, Valorisation__c, ligneDevis__r.unitprice, Option__r.Typedeloption__c,
                Option__r.PrixReferencePromotion__c, ligneDevis__r.Aconfigurer__c, non_configuree__c, Categorie__c, pack__c,
                Option__r.OptionPromotionnelle__c, id, PrixHT__c, ligneDevis__c, ligneDevis__r.PrixunitaireHTtarifoptions__c,
                ligneDevis__r.remise_enseigne__c, ligneDevis__r.Quantity, ligneDevis__r.tvaPourcentage__c
                FROM Option__c WHERE id in :optList];
    }
    
    // CRM-466 - WDO - Récupération des options par ID QuoteLineItem
    public static List<Option__c> getOptionListByqli(QuoteLineItem qli){
        return SchemaUtils.executeQuery('Option__c', 'ligneDevis__c', qli.Id);
    }
    // CRM-466 - WDO
    
    // Récupération des options par liste de QuoteLineItem
    public static List<Option__c> getOptionListByqli(List<QuoteLineItem> qliList){
        return [SELECT Quantite__c, PrixunitaireHT__c, PrixHT__c, Pourcentage__c, OwnerId, Option__c, Name, ligneDevis__c,
                Libelleoption__c, IsDeleted, Id, Codeoption__c, valorisation__c, categorie__c, pack__c,  Option__r.Typedeloption__c,
                Option__r.PrixReferencePromotion__c, ligneDevis__r.Aconfigurer__c, Option__r.OptionPromotionnelle__c,
                non_configuree__c
                FROM Option__c WHERE ligneDevis__c in :qliList];
    }
    
    /************* PACK **********************/
    public static List<Pack__c> getPackOptionVersion(List<Option__c> optList, String IdRevision){
        return [select id, codepere__r.Libelleoption__c, codepere__r.codeOption__c, codefils__r.Codeoption__c
                From Pack__c
                where codefils__c in: makeSet(optList, 'option__c')
                and IDRevision__c = : IdRevision
                and TypeRegroupement__c =: Constants.typeRegrOptVers];
    }
    
    public static List<Pack__c> getPackVersion(List<Pack__c> pListOptVers, String IdRevision){
        return [select id, codepere__r.Libelleoption__c, codepere__r.codeOption__c
                From Pack__c
                where codefils__c =: pListOptVers[0].CodePere__c
                and IDRevision__c = : IdRevision];
    }
    
    public static List<Pack__c> getPackVersionList(String IdRevision){
        return [Select p.CodeFils__c, p.CodeFils__r.LibelleOption__c ,p.ModeValorisation__c, p.FilsSubstituable__c, p.FilsAutoselectionnable__c
                From Pack__c p
                where p.CodePere__c =: getIdRoot()
                and p.CodeFils__c != null
                and p.IDRevision__c = : IdRevision
                order By p.Ordredaffichage__c];
    }
    
    /**
    * @description Récupération de l'Id de l'option "ROOT"
    * @return String ID de l'option "ROOT"
    */
    public static Id getIdRoot(){
        List<ReferentielOptions__c> res=[SELECT Id FROM ReferentielOptions__c WHERE codeOption__c = :Constants.Root LIMIT 1];
        if(!res.isEmpty())
            return res[0].Id;
        else return null;
    }
    
    public static List<Pack__c> getPackList(string versionLibelle, String IdRevision){
        return [Select p.CodeFils__c, p.CodeFils__r.LibelleOption__c, p.TypeRegroupement__c, CodePere__c, CodePere__r.LibelleOption__c, p.ModeValorisation__c, p.FilsSubstituable__c, p.FilsAutoselectionnable__c
                From Pack__c p
                where p.CodePere__r.LibelleOption__c =: versionLibelle
                and p.CodeFils__c != null
                and p.IDRevision__c =: IdRevision
                order By p.Ordredaffichage__c];
    }
    
    public static List<Pack__c> getOptionVersionList(Set<id> optVersionIds, String IdRevision){
        return [Select p.CodeFils__c, p.CodeFils__r.LibelleOption__c, p.ModeValorisation__c, p.FilsSubstituable__c,
                p.FilsAutoselectionnable__c, CodePere__c, CodeFils__r.CodeOption__c
                From Pack__c p
                where p.CodePere__c in: optVersionIds
                and p.CodeFils__c != null
                and p.TypeRegroupement__c =: Constants.typeRegrOptVers
                and p.IDRevision__c =: IdRevision
                and p.CodeFils__r.actif__c = true
                order By p.Ordredaffichage__c];
    }
    
    public static List<Pack__c> getCategList(Set<id> packIds, String IdRevision){
        return [Select p.CodeFils__c, p.CodeFils__r.LibelleOption__c, CodePere__c, CodePere__r.LibelleOption__c,p.ModeValorisation__c, p.FilsSubstituable__c, p.FilsAutoselectionnable__c, codeFils__r.codeoption__c
                From Pack__c p
                where p.CodePere__c in: packIds
                and p.CodeFils__c != null
                and p.TypeRegroupement__c =: Constants.typeRegrPack
                and p.IDRevision__c =: IdRevision
                order By p.Ordredaffichage__c];
    }
    
    public static List<Pack__c> getOptionSelectList(Set<id> categIds, String IdRevision){
        return [Select p.CodeFils__c, p.CodeFils__r.LibelleOption__c, CodePere__c, CodePere__r.LibelleOption__c, p.ModeValorisation__c, p.FilsSubstituable__c, p.FilsAutoselectionnable__c, p.codeFils__r.LibelleModifiable__c, p.codeFils__r.Valorisationmodifiable__c, p.codeFils__r.Quantitemodifiable__c, Mode_de_Selection__c, codePere__r.codeoption__c,CodeFils__r.codeOption__c
                From Pack__c p
                where p.CodePere__c in: categIds
                and p.CodeFils__c != null
                and p.TypeRegroupement__c =: Constants.typeRegrCateg
                and p.IDRevision__c =: IdRevision
                order By p.Ordredaffichage__c];
    }
    
    public static List<Revision_Pack__c> getRevisionPackList(QuoteLineItem qli){
        return [select id from Revision_Pack__c
                where CodeProduit__c=:qli.PricebookEntry.Product2Id
                and  Datedapplication__c <=: qli.quote.referenceDate__c
                order by Datedapplication__c DESC NULLs LAST
                limit 1];
    }
    
    public static List<IncentivePromotion__c> getIncentivePromoList(Map<id, ReferentielOptions__c> refOptMap){
        return [Select i.Codeincentive__c, i.CodeOption__c, i.Actif__c, Codeincentive__r.OriginesElligibles__c, Codeincentive__r.DebutValidite__c, Codeincentive__r.FinValidite__c, Codeincentive__r.Magasinselligibles__c, ValorisationPromotion__c, ModeValorisation__c
                From IncentivePromotion__c i
                where i.Codeincentive__c != null
                And i.CodeOption__c in: refOptMap.keySet()
                And i.actif__c = true];
    }
    
    public static List<IncentivePromotion__c> getIncentivePromoList(Quote q, Map<id, ReferentielOptions__c> refOptMap){
        string origines = '';
        string mag = '';
        
        if (!StringUtils.isEmpty(q.source__c)) {
            Integer i = MappingUtils.getCodeOrigine(q.source__c);
            origines = i <= 9 ? '0' + String.valueOf(i) : String.valueOf(i);
        }
        
        if (!Utils.IsNullOrEmpty(q.opportunity.owner.codeMagasin__c)){
            mag = q.opportunity.owner.codeMagasin__c.right(3);
        }
        return [Select i.Codeincentive__c, i.CodeOption__c, i.Actif__c, Codeincentive__r.OriginesElligibles__c, Codeincentive__r.DebutValidite__c, Codeincentive__r.FinValidite__c, Codeincentive__r.Magasinselligibles__c, ValorisationPromotion__c, ModeValorisation__c
                From IncentivePromotion__c i
                where i.Codeincentive__c != null
                And i.CodeOption__c in: refOptMap.keySet()
                And i.actif__c = true
                And i.Codeincentive__r.DebutValidite__c <=: q.referenceDate__c
                And i.Codeincentive__r.FinValidite__c >=: q.referenceDate__c
                And (i.Codeincentive__r.OriginesElligibles__c = '*'
                     or i.Codeincentive__r.OriginesElligibles__c like: '%' + origines + '%')
                And (i.Codeincentive__r.Magasinselligibles__c = '*'
                     or i.Codeincentive__r.Magasinselligibles__c like: '%' + mag + '%')];
    }
    
    public static List<Incompatibilit_Options__c> getIncompatibilitesOptions(List<Pack__c> optList){
        Set<String> setOptIds = makeSet(optList, 'codefils__c');
        return [Select i.CodePere__c, i.CodeFils__c, i.CodePere__r.codeOption__c, i.CodeFils__r.codeOption__c
                From Incompatibilit_Options__c i
                where i.CodePere__c in: setOptIds
                And i.CodeFils__c in: setOptIds
                And i.actif__c = true];
    }
    
    public static Map<id,ReferentielOptions__c> getRefOptMap(QuoteLineItem qli, set<String> idOptSet){
        return new Map<id,ReferentielOptions__c>([Select CodeOption__c, r.Id, TypePromotion__r.TypePromotion__c, OptionPromotionnelle__c, Debutvalidite__c, Finvalidite__c, UnitedevalorisationPromotion__c, Valorisationmodifiable__c,
                                                  (Select Datedapplication__c, Valorisationdeloption__c
                                                   From Tarifs_Option__r
                                                   where Datedapplication__c <=: qli.quote.referenceDate__c
                                                   And actif__c = true
                                                   order by Datedapplication__c desc nulls last
                                                   limit 1)
                                                  From ReferentielOptions__c r
                                                  where id in: idOptSet
                                                  And r.actif__c = true]);
    }
    
    public static Map<id,ReferentielOptions__c> getRefOptMap(Quote q, set<String> idOptSet){
        return new Map<id,ReferentielOptions__c>([Select CodeOption__c, r.Id, TypePromotion__r.TypePromotion__c, OptionPromotionnelle__c, Debutvalidite__c, Finvalidite__c, UnitedevalorisationPromotion__c, Valorisationmodifiable__c,
                                                  (Select Datedapplication__c, Valorisationdeloption__c
                                                   From Tarifs_Option__r
                                                   where Datedapplication__c <=: q.referenceDate__c
                                                   And actif__c = true
                                                   order by Datedapplication__c desc nulls last
                                                   limit 1)
                                                  From ReferentielOptions__c r
                                                  where id in: idOptSet
                                                  And r.actif__c = true]);
    }
    
    //CRM-271 SEO 11/07/2013 (anciennes fonctions DAL_FicheCOntact)
    public static Opportunity GetFicheProjetPDFById(String myID) {
        List<Opportunity> myOpportunityList = [SELECT LeadSource, numeroProjet__c,CreatedBy.Name, CreatedDate, StageName, Account.civilite__c,
                                               Account.Id, Account.prenom__c, Account.nom__c, Account.Rue__c,
                                               Account.codeAcces__c, Account.interphone__c, Account.etage__c, Account.Phone,
                                               Account.Telephonedomicile__c, Account.TelephoneMobile__c, Account.email__c,
                                               Account.pays__c, Account.situationFamiliale__c , Account.profession__c,
                                               Account.codePostal__c, Account.ville__c, Account.AccountNumber,
                                               autreCompte__r.civilite__c, autreCompte__r.AccountNumber,
                                               autreCompte__r.Id, autreCompte__r.prenom__c, autreCompte__r.nom__c, autreCompte__r.Rue__c,
                                               autreCompte__r.codeAcces__c, autreCompte__r.interphone__c, autreCompte__r.etage__c, autreCompte__r.Phone,
                                               autreCompte__r.Telephonedomicile__c, autreCompte__r.TelephoneMobile__c, autreCompte__r.email__c,
                                               autreCompte__r.pays__c, autreCompte__r.situationFamiliale__c, autreCompte__r.profession__c,
                                               autreCompte__r.codePostal__c, autreCompte__r.ville__c,
                                               Chantier__r.libelleMagasinActuel__c, Chantier__r.numeroChantier__c,
                                               Chantier__r.Interphone__c, Chantier__r.Etage__c, Chantier__r.pays__c, Chantier__r.ville__c,
                                               Chantier__r.typeResidence__c, Chantier__r.codePostal__c, Chantier__r.rue__c,
                                               Chantier__r.caracteristiquesUrbanisme__c, Chantier__r.typeHabitation__c, Chantier__r.anneeConstruction__c,
                                               Chantier__r.chauffages__c, Chantier__r.Proprietaire__c, Chantier__r.Locataire__c, Chantier__r.Occupant__c,
                                               Chantier__r.autreProprietaire__c, Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c,
                                               Chantier__r.presenceGarage__c, Chantier__r.presencePortail__c, Chantier__r.presenceTerrasse__c, Chantier__r.codeAcces__c,
                                               Chantier__r.anneeAchat__c, Chantier__r.description__c,
                                               quantiteFenetre__c, quantitePorteFenetre__c, quantiteCoulissant__c, quantiteVoletRoulant__c, quantitePortail__c, quantiteVoletBattant__c, quantitePersienne__c,
                                               quantiteMoustiquaire__c, quantiteStoreBanne__c, quantitePorteInterieur__c, quantitePorteGarage__c, quantitePorteEntree__c, quantitePorteBlindee__c,
                                               quantitePorteService__c, materiauxFenetre__c, materiauxPorteFenetre__c, materiauxCoulissant__c, materiauxVoletRoulant__c,
                                               materiauxPortail__c, materiauxVoletBattant__c, materiauxPersienne__c, materiauxMoustiquaire__c,
                                               materiauxStoreBanne__c, materiauxPorteInterieur__c, materiauxPorteGarage__c, materiauxPorteEntree__c,
                                               materiauxPorteBlindee__c, materiauxPorteService__c, precisionsReportRefus__c, Description
                                               FROM Opportunity WHERE ID = :myID];
        if(myOpportunityList.size() > 0)
            return myOpportunityList[0];
        return null;
    }
    
    public static List<Event> GetEventByWhatId(String myID) {
        System.debug('***********************************************************' + myID);
        return [SELECT StartDateTime, Type, StatutRDV__c, Location, Couplepresent__c, Description FROM Event WHERE WhatId = :myID limit 50];
    }
    
    public static List<Task> GetTaskByWhatId(String myID) {
        System.debug('***********************************************************' + myID);
        return [SELECT Subject, Owner.Name, ActivityDate, Status, Priority, ReminderDateTime, Description FROM Task WHERE WhatId = :myID limit 50];
    }
}