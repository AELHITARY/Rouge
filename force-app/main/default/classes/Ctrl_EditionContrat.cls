//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_EditionContrat
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 29 Septembre 2014
//-- Version     : 1.1
//-- * Correction retour recette
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_EditionContrat {
  public Quote quote {get; set;}
  public List<Option__c> optionsList {get;set;}
  public Map<String, List<Option__c>> mapOptions {get;set;}
  public List<ProductItem> prodListPorteF {get; set;}
  public List<ProductItem> prodListPorteGaragePortail {get; set;}
  public List<QuoteLineItem> prodListAutre {get; set;}

  public Integer nbPortesEtFenetres {get; set;}
  public Decimal partPortesEtFenetresRenoves {get; set;}
  public Boolean forfaitA {get; set;}
  public Boolean forfaitB {get; set;}
  public Boolean forfaitC {get; set;}
  public Decimal prixForfaitA {get; set;}
  public Decimal prixForfaitB {get; set;}
  public Decimal prixForfaitC {get; set;}
  public Boolean isSameAddress {get;set;}
  public Decimal remiseDevis {get;set;}
  public Decimal solde {get; set;}
  public Decimal pourcentageSolde {get; set;}

  public Ctrl_EditionContrat(){
    string quoteId = Apexpages.currentPage().getParameters().get('qId');

    // pctAcompteAttendu__c

    List<Quote> quoteList = [SELECT villeDemandeurs__c, dateDevis__c, BonusprojetPourcentage__c, RemisevendeurglobaleFormule__c, modeFinancement__c, mntAcompteAttendu__c, pctAcompteAttendu__c,
                  Total_TTC_devis__c, Total_TTC_hors_remise_enseigne__c, Remise_Enseigne_Options__c , villeChantier__c, tvaReduite_prv__c,
                  tvaReduite_pb__c, tvaReduite__c, tvaNormal_prv__c, tvaNormal_pb__c, tvaNormal__c, tvaIntermediaire_prv__c, tvaIntermediaire_pb__c,
                  tvaIntermediaire__c, totalTTCContrats__c, totalHTContrats__c, telephoneMobileDemandeurs__c, telephoneMobileChantier__c,
                  telephoneDomicileDemandeurs__c, telephoneDomicileChantier__c, telephoneDemandeurs__c, telephoneChantier__c, rueDemandeurs__c,
                  rueChantier__c, nomDemandeurs__c,nomChantier__c ,prenomDemandeurs__c, prenomChantier__c, paysDemandeurs__c, paysChantier__c,
                  emailDemandeurs__c, emailChantier__c, departementDemandeurs__c, departementChantier__c, codePostalDemandeurs__c, codePostalChantier__c,
                  civiliteDemandeurs__c, civiliteChantier__c, autreTelephoneDemandeurs__c, autreTelephoneChantier__c, compte__r.complementAdresse__c,
                  TotalHTlignes__c ,RemisevendeurglobaleDeviseFormule__c, Bonus_projetFormule__c , Pricebook2Id, OpportunityId, C2E__c, Opportunity.Owner.FirstName, Opportunity.Owner.LastName, Opportunity.Chantier__r.Id,
                  Opportunity.chantier__r.complementAdresse__c, Opportunity.autreCompte__c, Opportunity.chantier__c, Opportunity.chantier__r.chauffages__c,
                  Opportunity.chantier__r.anneeConstruction__c, Opportunity.chantier__r.typeResidence__c, Opportunity.chantier__r.nbPortesEtFenetres__c,
                  Opportunity.chantier__r.typeHabitation__c
                FROM Quote WHERE Id = :quoteId];

    // Si pas de devis, rien faire
    if(quoteList != null && quoteList.size() != 0) {
      quote = quoteList.get(0);
      if(quote.mntAcompteAttendu__c != null){
        solde = quote.Total_TTC_devis__c - quote.mntAcompteAttendu__c;
        pourcentageSolde = 100 - quote.pctAcompteAttendu__c;
      }
      else{
        solde = null;
      }
      // Ligne de devis
      List<QuoteLineItem> qliList = DAL.getQuoteLineItemList(quoteId, 'SortOrder, PricebookEntry.Product2.Name, NumLigneText__c, PricebookEntry.Product2.Family');
      // Options
      optionsList = DAL.getOptionList(quoteId);

      forfaitA = false;
      forfaitB = false;
      forfaitC = false;
      prixForfaitA = 0;
      prixForfaitB = 0;
      prixForfaitC = 0;
      nbPortesEtFenetres = 0;
      partPortesEtFenetresRenoves = 0;
      prodListPorteF = new List<ProductItem>();
      prodListPorteGaragePortail = new List<ProductItem>();
      prodListAutre = new List<QuoteLineItem>();

      // Construction Map
      mapOptions = new Map<String, List<Option__c>>();
      for (QuoteLineItem quoteLineItem : qliList) {
        List<Option__c> optTemp = new List<Option__c>();
        for (Option__c opt : optionsList) {
          if(opt.ligneDevis__c == quoteLineItem.Id)
            optTemp.add(opt);
        }
        mapOptions.put(quoteLineItem.Id, optTemp);
      }

      if((quote.rueChantier__c == quote.rueDemandeurs__c) && (quote.villeChantier__c == quote.villeDemandeurs__c ) && (quote.codePostalChantier__c == quote.codePostalDemandeurs__c ))
        isSameAddress = true;
      else
        isSameAddress = false;

      // Remise
      remiseDevis = 0;
      Decimal remiseVendeur = 0;
      Decimal bonusProjet = 0;
      remiseVendeur = (quote.RemisevendeurglobaleDeviseFormule__c == null) ? 0 : quote.RemisevendeurglobaleDeviseFormule__c;
      bonusProjet = (quote.Bonus_projetFormule__c == null) ? 0 : quote.Bonus_projetFormule__c;
      remiseDevis =  remiseVendeur - bonusProjet;

      List<Familles__c> familles = [Select libelle__c, code__c From Familles__c];
      List<SousFamilles__c> sousFamilles = [Select libelle__c, famille__c,code__c From SousFamilles__c];

      for (QuoteLineItem qli : qliList) {
        //parcours des produits pour trouver le / les forfaits puis recuperation du prix sur la qli associée
        if(qli.PricebookEntry.Product2.Name.equals('FORFAIT A')){
          forfaitA = true;
          // prixForfaitA = qli.TotalTTCligne__c;
          prixForfaitA = qli.prixHTTarif__c;
        }
        if(qli.PricebookEntry.Product2.Name.equals('FORFAIT B')){
          forfaitB = true;
          // prixForfaitB = qli.TotalTTCligne__c;
          prixForfaitB = qli.prixHTTarif__c;
        }
        if(qli.PricebookEntry.Product2.Name.equals('FORFAIT C')){
          forfaitB = true;
          // prixForfaitC = qli.TotalTTCligne__c;
          prixForfaitC = qli.prixHTTarif__c;
        }
        //onparcours les familles pour trouver la bonne
        for(Familles__c famille : familles){
          // Lorsque l'on trouve la famille associée, Si on trouve la bonne famille
          if(qli.PricebookEntry.Product2.Family == famille.libelle__c && !qli.PricebookEntry.Product2.Name.containsIgnoreCase('FORFAIT')) {
            // Si le produit à une hauteur ou largeur, on le classe dans les produits, sinon autre
            if(qli.PricebookEntry.Product2.Longueurminimum1vantail__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum1vantail__c > 0 ||
              qli.PricebookEntry.Product2.Longueurminimum2vantaux__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum2vantaux__c > 0 ||
              qli.PricebookEntry.Product2.Longueurminimum3vantaux__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum3vantaux__c > 0 ||
              qli.PricebookEntry.Product2.Longueurminimum4vantaux__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum4vantaux__c > 0 ||
              qli.PricebookEntry.Product2.Longueurminimum5vantaux__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum5vantaux__c > 0 ||
              qli.PricebookEntry.Product2.Longueurminimum6vantaux__c > 0 || qli.PricebookEntry.Product2.Longueurmaximum6vantaux__c > 0
            ) {
              if(famille.code__c == 'P')
                calculGaragePortail(qli, true);
              else { // Cas des portes / fenetre
                for(SousFamilles__c sousFamille : sousFamilles) {
                  //si on trouve la sous famille
                  if(qli.PricebookEntry.Product2.SousFamille__c == sousFamille.libelle__c && famille.code__c == sousFamille.famille__c){
                    // Porte de garage
                    system.debug(sousFamille.code__c);
                    if(sousFamille.code__c == 'PGAR')
                      calculGaragePortail(qli, false);
                    else {
                      calculPorteFenetre(qli, famille);
                    }
                  }
                }
              }
            }
            else {
              prodListAutre.add(qli);
            }
          }
        }
      }
      if(nbPortesEtFenetres != 0)
        partPortesEtFenetresRenoves = (quote.opportunity.chantier__r.nbPortesEtFenetres__c == 0 || quote.opportunity.chantier__r.nbPortesEtFenetres__c == null) ? 0 : ((nbPortesEtFenetres / quote.opportunity.chantier__r.nbPortesEtFenetres__c) * 100).setScale(0, RoundingMode.HALF_EVEN);
    }
  }

  // Fonction pour traiter les produits de type porte/fenetre et autre (avec hauteur et largeur)
  public void calculPorteFenetre(QuoteLineItem qli, Familles__c famille) {
    ProductItem produit = new ProductItem();
    produit.qli = qli;

    if(famille.code__c == 'FEN') {
      Integer quantite = (qli.Quantity == null) ? 0 : (Integer)qli.Quantity;
      system.debug('nbPortesEtFenetres ' + nbPortesEtFenetres);
      system.debug('quantite ' + quantite);
      nbPortesEtFenetres = nbPortesEtFenetres + quantite;
    }

    // Options
    if(mapOptions != null) {
      List<Option__c> options = new List<Option__c>();
      if(mapOptions.get(qli.Id) != null) options = mapOptions.get(qli.Id);
      for (Option__c option : options) {
        boolean isOther = true;
        // Eco Subvention
        if(option.CodeOption__c != null && option.CodeOption__c.containsIgnoreCase(Constants.EcoPrime)) {
          produit.ecoSubventionMontant = produit.ecoSubventionMontant + Math.abs(option.PrixHT__c);
          produit.ecoSubvention = true;
          isOther = false;
        }
        // Définition des options (case à cocher)
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('OSCILLO')) {
          produit.oscilloBattant = true;
          isOther = false;
        }
        if(option.Libelleoption__c != null && (option.Libelleoption__c.containsIgnoreCase('SEMI RENOVATION') || option.Libelleoption__c.containsIgnoreCase('SEMI-RENOVATION'))) {
          produit.poseSemi = true;
          isOther = false;
        }
        else if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('RENOVATION')) {
          produit.poseExistant = true;
          isOther = false;
        }
        else if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('DEPOSE TOTALE')) {
          produit.poseTotal = true;
          isOther = false;
        }
        // Si ce n'est pas une fenetre ou une porte, on définit l'option INSTALLATION comme autre
        if(famille.code__c != 'FEN' && option.Libelleoption__c != null && option.Pack__c != null && option.Pack__c.containsIgnoreCase('INSTALLATION')) {
          produit.installationAutre = option.Libelleoption__c;
          produit.poseAutre = true;
        }
        // Construction de la liste des autres options
        if(isOther) {
          if(produit.otherOptions == '')
            produit.otherOptions = option.Libelleoption__c;
          else
            produit.otherOptions = produit.otherOptions + ', ' + option.Libelleoption__c;
        }
      }
    }
    prodListPorteF.add(produit);
  }

  // Fonction pour traiter les produits de type garage/portail
  public void calculGaragePortail(QuoteLineItem qli, Boolean portail) {
    ProductItem produit = new ProductItem();
    produit.qli = qli;
    produit.isPortail = portail;

    // Options
    if(mapOptions != null) {
      List<Option__c> options = new List<Option__c>();
      if(mapOptions.get(qli.Id) != null) options = mapOptions.get(qli.Id);
      Decimal ecoSubvention = 0;
      for (Option__c option : options) {
        boolean isOther = true;
        // Eco Subvention
        if(option.CodeOption__c.containsIgnoreCase(Constants.EcoPrime)) {
          produit.ecoSubventionMontant = produit.ecoSubventionMontant + Math.abs(option.PrixHT__c);
          produit.ecoSubvention = true;
          isOther = false;
        }
        // Portail
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('MOTORISATION')){
          produit.motorisation = true;
          isOther = false;
        }
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('PORTAIL COULISSANT')){
          produit.ouvertureCoul = true;
          isOther = false;
        }
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('BATTANT OUVERTURE VERS L\'EXTERIEUR')){
          produit.ouvertureExt = true;
          isOther = false;
        }
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('BATTANT OUVERTURE VERS L\'INTERIEUR')){
          produit.ouvertureInt = true;
          isOther = false;
        }
        // Garage
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('REFOULEMENT LATERAL')){
          produit.refoulementLat = true;
          isOther = false;
        }
        if(option.Libelleoption__c != null && option.Libelleoption__c.containsIgnoreCase('REFOULEMENT PLAFOND')){
          produit.refoulementPlaf = true;
          isOther = false;
        }
        if(qli.PriceBookEntry.product2.Modele__c != null && qli.PriceBookEntry.product2.Modele__c.containsIgnoreCase('ENROULEMENT')){
          produit.enroulement = true;
        }

        if(qli.PriceBookEntry.product2.Modele__c != null && qli.PriceBookEntry.product2.Modele__c.containsIgnoreCase('SECTIONNELLE')){
          produit.sectionnelle = true;
        }
        // Construction de la liste des autres options
        if(isOther) {
          if(produit.otherOptions == '')
            produit.otherOptions = option.Libelleoption__c;
          else
            produit.otherOptions = produit.otherOptions + ', ' + option.Libelleoption__c;
        }
      }
    }
    prodListPorteGaragePortail.add(produit);
  }

  /************************************************
  /******************** SOUS CLASSES **************
  /************************************************/
  public class ProductItem{
    public QuoteLineItem qli {get; set;}
    public String emplacement {get; set;}
    public Boolean isPortail {get; set;}
    public Boolean oscilloBattant {get; set;}
    public String installationAutre {get; set;}
    public Boolean poseAutre {get; set;}
    public Boolean poseExistant {get; set;}
    public Boolean poseSemi {get; set;}
    public Boolean poseTotal {get; set;}
    public Boolean motorisation {get; set;}
    public Boolean ouvertureExt {get; set;}
    public Boolean ouvertureInt {get; set;}
    public Boolean ouvertureCoul {get; set;}
    public Boolean refoulementLat {get; set;}
    public Boolean refoulementPlaf {get; set;}
    public Boolean enroulement {get; set;}
    public Boolean sectionnelle {get; set;}
    public Boolean ecoSubvention {get; set;}
    public Decimal ecoSubventionMontant {get; set;}
    public String otherOptions {get; set;}

    // Constructeurs
    public ProductItem(){
      isPortail = false;
      oscilloBattant = false;
      poseExistant = false;
      poseSemi = false;
      poseTotal = false;
      motorisation = false;
      ouvertureExt = false;
      ouvertureInt = false;
      ouvertureCoul = false;
      refoulementLat = false;
      refoulementPlaf = false;
      enroulement = false;
      sectionnelle = false;
      ecoSubvention = false;
      poseAutre = false;
      ecoSubventionMontant = 0;
      installationAutre = '';
      otherOptions = '';
    }
  }
}