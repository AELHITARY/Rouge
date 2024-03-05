//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_InnerClasses
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/08/2017
//-- Version     : 1.0
//-- * Init (Classe contenant les classes internes réutilisables)
//-- --------------------------------------------------------------------------------- --
public class Utils_InnerClasses {

    /*-------------------- TRIPTYQUE -------------------------*/
    /*--------------------------------------------------------*/

    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage de résultat des objectifs d'un vendeur
    */
    public class IndicateursObjectifUser {
        public Decimal objectifContactActif {get;set;}
        public Decimal objectifnbDevisVendu {get;set;}
        public Decimal objectifCADevisVendu {get;set;}
        public Decimal nbContactActif {get;set;}
        public Decimal nbContactActifEff {get;set;}
        public Decimal nbVendeurEffectif {get;set;}
        public Decimal nbDevisVendu {get;set;}
        public Decimal nbCADevisVendu {get;set;}
        public Decimal realisationContactActif {get;set;}
        public Decimal realisationContactActifEffectif {get;set;}
        public Decimal realisationNbDevis {get;set;}
        public Decimal realisationCADevis {get;set;}

        public IndicateursObjectifUser() {}
    }

    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage de résultat des indicateurs d'un vendeur contenant les valeurs hebdomadaires
    */
    public class IndicateursVendeurHebdomadaire {
        public String vendeurId {get;set;}
        public Integer joursTravaille {get;set;}
        public Decimal objectifContactActif {get;set;}          // C01
        public Decimal nbContactActif {get;set;}                // C02
        public Decimal nbContactPassif {get;set;}               // C04
        public Decimal nbRDVTotal {get;set;}                    // C05
        public Decimal nbDevisVendu {get;set;}                  // C06 et V03
        public Decimal nbRDVR1_Pris {get;set;}                  // C07
        public Decimal nbRDVR1_Effec {get;set;}                 // C07
        public Decimal nbRDVR2_Pris {get;set;}                  // C08
        public Decimal nbRDVR2_Effec {get;set;}                 // C08
        public Decimal nbRDVBAL50 {get;set;}                    // C09
        public Decimal nbContactBAL {get;set;}                  // C10
        public Decimal nbRDVTAP51 {get;set;}                    // C11
        public Decimal nbContactTAP {get;set;}                  // C12
        public Decimal nbContactComplement {get;set;}           // C13
        public Decimal nbContactParrainage {get;set;}           // C14
        public Decimal nbRDVPhone55 {get;set;}                  // C15
        public Decimal nbContactPhone {get;set;}                // C16
        public Decimal nbRDVGalerieMarchande {get;set;}         // C17
        public Decimal nbContactGalerieMarchande {get;set;}     // C18
        public Decimal nbRDVFoire {get;set;}                    // C19
        public Decimal nbContactFoire {get;set;}                // C20
        public Decimal nbRDVMarche {get;set;}                   // C21
        public Decimal nbContactMarche {get;set;}               // C22
        public Decimal objectifContactTotal {get;set;}          // C23
        public Decimal nbContactTotal {get;set;}                // C24
        public Decimal nbRDVCreatedRdvDate {get;set;}           // C25
        public Decimal nbRDVDebrief {get;set;}                  // C26
        public Decimal objectifnbDevisVendu {get;set;}          // V01
        public Integer objectifCADevisVendu {get;set;}          // V02
        public Integer nbCADevisVendu {get;set;}                // V04

        // Nombre de RDVs
        public Decimal nbRDVAccompagne {get;set;}               // CRM-610 JMU
        public Decimal nbRDVAccompagnant {get;set;}             // CRM-610 JMU

        // Ratios sur les nombres d'argument par origine
        public Decimal ratioParJourBAL {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactBAL {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourTAP {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactTAP {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourPhone {get;set;}             // CRM-610 JMU
        public Decimal ratioParContactPhone {get;set;}          // CRM-610 JMU

        // Taux de réalisation : % du réalisé par rapport aux objectifs
        public Decimal realisationContact {get;set;}
        public Decimal realisationContactActif {get;set;}
        // Taux Transformation des RDV : % de RDV par rapport au nombre total de contacts réalisés
        public Decimal tauxTransformationRDV {get;set;}
        // Taux Transformation des ventes : % de ventes par rapport au nombre total de RDV réalisés
        public Decimal tauxTransformationVentes {get;set;}
        // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
        public Decimal tauxPartContactBAL {get;set;}
        public Decimal tauxPartContactTAP {get;set;}
        public Decimal tauxPartContactCOMP {get;set;}
        public Decimal tauxPartContactPHONE {get;set;}
        public Decimal tauxPartContactGM {get;set;}
        public Decimal tauxPartContactFOIRE {get;set;}
        public Decimal tauxPartContactMARCHE {get;set;}

        // Panier moyen de la période observée (CA en K€ / nombre de vente) arrondi à 2 décimales
        public Decimal panierMoyenObjectifVente {get;set;}
        public Decimal panierMoyenRealiseVente {get;set;}

        public IndicateursVendeurHebdomadaire() {}
    }
    
    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage de résultat des indicateurs d'un vendeur contenant les valeurs mensuelles
    */
    public class IndicateursVendeurMensuel {
        public String vendeurId {get;set;}
        public Integer joursTravaille {get;set;}
        public Integer joursTravailleMonth {get;set;}           // CRM-610
        public Decimal objectifDevisVendu {get;set;}    // M05
        public Decimal nbCADevisVendu {get;set;}        // M06
        public Decimal nbContactActif {get;set;}        // M07
        public Decimal nbContactPassif {get;set;}       // M08
        public Map<Integer, List<Integer>> valeursMensuelByWeek {get;set;}      // M01 à M04
        public Decimal nbDevisVendu {get;set;}
        public Integer numberOfWeek {get;set;}
        // Contact par origine // CRM-610 JMU
        public Decimal nbRDVBAL50 {get;set;}                    // C09
        public Decimal nbContactBAL {get;set;}                  // C10
        public Decimal nbRDVTAP51 {get;set;}                    // C11
        public Decimal nbContactTAP {get;set;}                  // C12
        public Decimal nbContactComplement {get;set;}           // C13
        public Decimal nbContactParrainage {get;set;}           // C14
        public Decimal nbRDVPhone55 {get;set;}                  // C15
        public Decimal nbContactPhone {get;set;}                // C16
        public Decimal nbRDVGalerieMarchande {get;set;}         // C17
        public Decimal nbContactGalerieMarchande {get;set;}     // C18
        public Decimal nbRDVFoire {get;set;}                    // C19
        public Decimal nbContactFoire {get;set;}                // C20
        public Decimal nbRDVMarche {get;set;}                   // C21
        public Decimal nbContactMarche {get;set;}               // C22
        // Nombre de RDVs
        public Decimal nbRDVAccompagne {get;set;}               // CRM-610 JMU
        public Decimal nbRDVAccompagnant {get;set;}             // CRM-610 JMU
        // Ratios sur les nombres d'argument par origine
        public Decimal ratioParJourBAL {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactBAL {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourTAP {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactTAP {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourPhone {get;set;}             // CRM-610 JMU
        public Decimal ratioParContactPhone {get;set;}          // CRM-610 JMU
        // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
        public Decimal tauxPartContactBAL {get;set;}            // CRM-610 JMU
        public Decimal tauxPartContactTAP {get;set;}            // CRM-610 JMU
        public Decimal tauxPartContactCOMP {get;set;}           // CRM-610 JMU
        public Decimal tauxPartContactPHONE {get;set;}          // CRM-610 JMU
        public Decimal tauxPartContactGM {get;set;}             // CRM-610 JMU
        public Decimal tauxPartContactFOIRE {get;set;}          // CRM-610 JMU
        public Decimal tauxPartContactMARCHE {get;set;}         // CRM-610 JMU
        // Taux de réalisation : % du réalisé par rapport aux objectifs
        public Decimal realisationCADevis {get;set;}

        public IndicateursVendeurMensuel() {}
    }

    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage de résultat des indicateurs d'un vendeur contenant le total (Hedbo + Mensuel)
    */
    public class IndicateursVendeurTotaux {
        // Hebdo (Contact et RDV)
        public Decimal Somme_objectifContactTotal {get;set;}                // Somme C23
        public Decimal Somme_nbContactTotal {get;set;}                      // Somme C24
        public Decimal Somme_objectifContactActif {get;set;}                // Somme C01
        public Decimal Somme_nbContactActif {get;set;}                      // Somme C02
        public Decimal Somme_nbContactPassif {get;set;}                     // Somme C04
        public Decimal Somme_nbRDVTotal {get;set;}                          // Somme C05
        public Decimal Somme_nbDevisVendu {get;set;}                        // Somme C06 et V03
        public Decimal Somme_nbRDVCreatedRdvDate {get;set;}                 // Somme C25
        public Decimal Somme_nbRDVDebrief {get;set;}                        // Somme C26
        public Decimal Somme_nbRDVR1_Pris {get;set;}                        // Somme C07
        public Decimal Somme_nbRDVR1_Effec {get;set;}                       // Somme C07
        public Decimal Somme_nbRDVR2_Pris {get;set;}                        // Somme C08
        public Decimal Somme_nbRDVR2_Effec {get;set;}                       // Somme C08
        // Hebdo (Contact par origine)
        public Decimal Somme_nbRDVBAL50 {get;set;}                          // Somme C09
        public Decimal Somme_nbContactBAL {get;set;}                        // Somme C10
        public Decimal Somme_nbRDVTAP51 {get;set;}                          // Somme C11
        public Decimal Somme_nbContactTAP {get;set;}                        // Somme C12
        public Decimal Somme_nbContactComplement {get;set;}                 // Somme C13
        public Decimal Somme_nbContactParrainage {get;set;}                 // Somme C14
        public Decimal Somme_nbRDVPhone55 {get;set;}                        // Somme C15
        public Decimal Somme_nbContactPhone {get;set;}                      // Somme C16
        public Decimal Somme_nbRDVGalerieMarchande {get;set;}               // Somme C17
        public Decimal Somme_nbContactGalerieMarchande {get;set;}           // Somme C18
        public Decimal Somme_nbRDVFoire {get;set;}                          // Somme C19
        public Decimal Somme_nbContactFoire {get;set;}                      // Somme C20
        public Decimal Somme_nbRDVMarche {get;set;}                         // Somme C21
        public Decimal Somme_nbContactMarche {get;set;}                     // Somme C22
        // Hebdo (Vente)
        public Decimal Somme_nbRDVHebdoAccompagne {get;set;}                // CRM-610 JMU
        public Decimal Somme_nbRDVHebdoAccompagnant {get;set;}              // CRM-610 JMU
        public Decimal Somme_objectifnbDevisVendu {get;set;}                // Somme V01
        public Decimal Somme_objectifCADevisVendu {get;set;}                // Somme V02
        // public Decimal Somme_nbDevisVendu {get;set;}                     // Somme V03
        public Decimal Somme_nbCADevisVendu {get;set;}                      // Somme V04
        // Mensuel
        public Decimal Somme_nbRDVMensuelAccompagne {get;set;}              // CRM-610 JMU
        public Decimal Somme_nbRDVMensuelAccompagnant {get;set;}            // CRM-610 JMU
        public Decimal Somme_objectifDevisVenduMensuel {get;set;}           // Somme M05
        public Decimal Somme_nbCADevisVenduMensuel {get;set;}               // Somme M06
        public Decimal Somme_nbContactActifMensuel {get;set;}               // Somme M07
        public Decimal Somme_nbContactPassifMensuel {get;set;}              // Somme M08
        public Map<Integer, List<Integer>> Somme_valeursMensuelByWeek {get;set;}        // Somme M01 à M04
        public Decimal Somme_nbDevisVenduMensuel {get;set;}
        // Mensuel (par origine)
        public Decimal Somme_nbRDVBAL50Mensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactBALMensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbRDVTAP51Mensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactTAPMensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbContactComplementMensuel {get;set;}          // CRM-610 JMU
        public Decimal Somme_nbContactParrainageMensuel {get;set;}          // CRM-610 JMU
        public Decimal Somme_nbRDVPhone55Mensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbContactPhoneMensuel {get;set;}               // CRM-610 JMU
        public Decimal Somme_nbRDVGalerieMarchandeMensuel {get;set;}        // CRM-610 JMU
        public Decimal Somme_nbContactGalerieMarchandeMensuel {get;set;}    // CRM-610 JMU
        public Decimal Somme_nbRDVFoireMensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactFoireMensuel {get;set;}               // CRM-610 JMU
        public Decimal Somme_nbRDVMarcheMensuel {get;set;}                  // CRM-610 JMU
        public Decimal Somme_nbContactMarcheMensuel {get;set;}              // CRM-610 JMU

        // Calculs Hebdo (Contact et RDV)
        public Decimal Somme_realisationContact  {get;set;}                 // [TR] Somme C23 C24
        public Decimal Somme_realisationContactActif {get;set;}             // [TR] Somme C01 C02
        public Decimal Somme_realisationContactPassif {get;set;}            // [TR] Somme C03 C04
        // Calculs Hebdo (Vente)
        public Decimal Somme_panierMoyenObjectifVente {get;set;}            // [PM] Somme V01 V02
        public Decimal Somme_panierMoyenRealiseVente {get;set;}             // [PM] Somme V03 V04
        // Calculs Mensuels / Annuels
        public Decimal Somme_panierMoyenCAMensuel {get;set;}                // [PM] Mensuel

        public IndicateursVendeurTotaux(){}
    }

    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage de résultat des indicateurs d'un vendeur pour export PDF
    * Cumulation des classes IndicateursVendeurMensuel,IndicateursVendeurHebdomadaire et IndicateursVendeurTotaux
    */
    public class IndicateursVendeurAll {
        public String vendeurId {get;set;}
        public String vendeurName {get;set;}
        public Boolean vendeurActive {get;set;}
        public Datetime vendeurLastLoginDate {get;set;}
        public Integer vendeurNbLogin {get;set;}
        public Integer index {get;set;}

        public IndicateursVendeurMensuel IVM {get;set;}
        public IndicateursVendeurHebdomadaire IVH {get;set;}
        public IndicateursVendeurTotaux IVT {get;set;}

        public IndicateursVendeurAll(){}
    }

    /**
    * @description Classe interne des TRIPTYQUES
    * Stockage des valeurs des PieCharts (indicateurs) de la page
    */
    public class IndicateursPie {
        public Integer vendeurAjd {get;set;}
        public Integer vendeurDemain {get;set;}
        public Integer vendeurADemain {get;set;}
        public Integer magasinAjd {get;set;}
        public Integer magasinDemain {get;set;}
        public Integer magasinADemain {get;set;}

        public IndicateursPie(){}
    }
    
    /*---------------------- AUTRE ---------------------------*/
    /*--------------------------------------------------------*/

    /**
    * @description Classe interne des pages de détails et d'édition des comptes et contacts
    * Stockage de résultat des indicateurs
    */
    public class IndicateursContactAccount {
        public Decimal nbChantiers {get;set;}
        public Decimal nbProjetsEnCours {get;set;}
        public Decimal nbProjetsGagnes {get;set;}
        public Decimal nbProjetsPerdus {get;set;}
        public Decimal nbDevisTransmis {get;set;}
        public Decimal nbDevisVendus {get;set;}
        public Decimal nbDevisResilies {get;set;}
        public Decimal nbDevisVendu {get;set;}
        public Decimal caDevis {get;set;}
        public Decimal nbTachesEnCours {get;set;}
        public Decimal nbContratsVendus {get;set;}
        public Decimal nbContratsResilies {get;set;}
        public Decimal caContrat {get;set;}
        public Decimal nbNPSSatisfaction {get;set;}
        public Decimal nbNPSRecommandation {get;set;}
        public Decimal nbNPSRecommandationColor {get;set;}
        public Decimal nbNPSSatisfactionColor {get;set;}
        public Integer couleurIndChantier {get;set;}
        public Integer couleurIndProjet {get;set;}
        public Integer couleurIndDevis {get;set;}
        public Integer couleurIndTache {get;set;}
        public Integer couleurIndOptin {get;set;}

        public IndicateursContactAccount() {
            nbChantiers = 0;
            nbProjetsEnCours = 0;
            nbProjetsGagnes = 0;
            nbProjetsPerdus = 0;
            nbDevisTransmis = 0;
            nbDevisVendus = 0;
            nbDevisResilies = 0;
            nbDevisVendu = 0;
            caDevis = 0;
            nbTachesEnCours = 0;
            nbContratsVendus = 0;
            nbContratsResilies = 0;
            caContrat = 0;
            nbNPSSatisfaction = 0;
            nbNPSRecommandation = 0;
            couleurIndChantier = 0;
            couleurIndProjet = 0;
            couleurIndDevis = 0;
            couleurIndTache = 0;
            nbNPSRecommandationColor = 0;
            nbNPSSatisfactionColor = 0;
            couleurIndOptin = 0;
        }
    }

    /**
    * @description Classe interne des pages de détails des chantiers et opportunités
    * Classe Activité personnalisée
    */
    public class CustomActivity {
        public Task task { get; set; }
        public Event event { get; set; }
        public Boolean isSelected { get; set; }
        //recup tous les champs communs aux 2
        public String id { get; set; }
        public String subject { get; set; }
        public String whatId { get; set; }
        public String whoId { get; set; }
        public String whatName { get; set; }
        public String whoName { get; set; }
        public Datetime activityDateTime { get; set; }
        public String activityDate { get; set; }
        public String ownerId { get; set; }
        public String ownerName { get; set; }
        public Boolean isInProgress { get; set; }
        public String statutRDV { get; set;}

        public CustomActivity(Task t, Boolean b) {
            task = t;
            isSelected = b;
            id = t.id;
            subject = t.subject;
            whatId = t.what.id;
            whoId = t.who.id;
            whatName = t.what.name;
            whoName = t.who.name;
            activityDateTime = t.activityDate;
            statutRDV = null;
            if(activityDateTime!=null){
                activityDate = activityDateTime.format('dd/MM/yyyy');
            }
            ownerName = t.owner.name;
            ownerId = t.owner.id;
            if(t.status=='Terminé')
                isInProgress = false;
            else
                isInProgress = true;
        }

        public CustomActivity(Event e,Boolean b) {
            event = e;
            isSelected = b;
            id = e.id;
            subject = e.subject;
            whatId = e.what.id;
            whoId = e.who.id;
            whatName = e.what.name;
            whoName = e.who.name;
            activityDateTime = e.activityDate;
            statutRDV = e.statutRDV__c;
            if(activityDateTime!=null){
                activityDate = activityDateTime.format('dd/MM/yyyy');
                //Europe/London marche pas, 'GMT+01:00' nn plus
                // ne recup pas l'heure ''+e.activityDate => heure à 00:00
            }
            ownerName = e.owner.name;
            ownerId = e.owner.id;
            if(e.activityDate<system.now())
                isInProgress = false;
            else
                isInProgress = true;
        }
    }

    /**
    * @description Classe interne des CALENDRIERS
    * Classe structure pour les informations des vendeurs
    */
    public class VendeurInfos{
        public User Vendeur {get;set;}
        public String RoleName {get;set;}
        public Id UserId {get; set;}
        public String UserName {get; set;}
        public Decimal Distance {get; set;}
        public Boolean isResponsable {get;set;}
        public Integer Position {get;set;}
        public Decimal Latitude {get;set;}
        public Decimal Longitude {get;set;}
    }

    /**
    * @description Classe interne des LISTES DE PHONES
    * Classe d'aide pour parser les comptes/event/phones sur la cartographie
    */
    public class CustomCompte {
        public Account compte           { get; set; }
        public String  Id               { get; set; }
        public String  ObjectType       { get; set; }
        public String  OwnerId          { get; set; }
        public String  OwnerName        { get; set; }
        public String  Name             { get; set; }
        public String  Address          { get; set; }
        public String  PostalCode       { get; set; }
        public String  City             { get; set; }
        public String  AddressComplete  { get; set; }
        public String  ActivityDate     { get; set; }
        public String  RdvType          { get; set; }
        public Double  Latitude         { get; set; }
        public Double  Longitude        { get; set; }
        public Decimal X                { get; set; }
        public Decimal Y                { get; set; }
        public String  TypeCompte       { get; set; }
        public String  Email            { get; set; }
        public String  TelDomicile      { get; set; }
        public String  TelMobile        { get; set; }
        public String  AutreTel         { get; set; }
        public Boolean OptinTelDomicile { get; set; }
        public Boolean OptinTelMobile   { get; set; }
        public Decimal NbPhonings       { get; set; }
        public Decimal NbAppelsSortants { get; set; }
        public Datetime DateDernierAppel{ get; set; }
        public String  NumCompte        { get; set; }
        public String  Profession       { get; set; }
        public String  RueGeocode       { get; set; }
        public Boolean Debriefe         { get; set; }
        
        public CustomCompte (PhoningVendeur__c phone, Account compte) {
            ObjectType     = 'account';
            Id             = compte.Id;
            OwnerId        = compte.OwnerId;
            OwnerName      = compte.Owner.Name;
            Name           = compte.Name;
            Address        = Utils.nullString2emptyString(compte.rue__c);
            PostalCode     = Utils.nullString2emptyString(compte.codePostal__c);
            City           = Utils.nullString2emptyString(compte.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = compte.Localisation__Latitude__s;
            Longitude      = compte.Localisation__Longitude__s;
            X              = compte.x__c;
            Y              = compte.y__c;
            TypeCompte     = compte.Type;
            Email            = compte.email__c;
            TelDomicile      = compte.telephoneDomicile__c;
            TelMobile        = compte.telephoneMobile__c;
            AutreTel         = compte.autreTelephone__c;
            OptinTelDomicile = compte.optinTelephoneDomicileKparK__c;
            OptinTelMobile   = compte.optinTelephoneMobileKparK__c;
            Debriefe         = phone.debriefe__c;
        }
        
        public CustomCompte (Event event, Account compte) {
            if(null != compte) {
                this.compte    = compte;
                ObjectType     = 'account';
                Id             = compte.Id;
                OwnerId        = compte.OwnerId;
                OwnerName      = compte.Owner.Name;
                Name           = compte.Name;
                Address        = Utils.nullString2emptyString(compte.rue__c);
                PostalCode     = Utils.nullString2emptyString(compte.codePostal__c);
                City           = Utils.nullString2emptyString(compte.ville__c);
                AddressComplete = (Address == '') ? '' : Address + ', ';
                AddressComplete += PostalCode + ' ' + City;
                Latitude       = compte.Localisation__Latitude__s;
                Longitude      = compte.Localisation__Longitude__s;
                X              = compte.x__c;
                Y              = compte.y__c;
                TypeCompte     = compte.Type;
                Email            = compte.email__c;
                TelDomicile      = compte.telephoneDomicile__c;
                TelMobile        = compte.telephoneMobile__c;
                AutreTel         = compte.autreTelephone__c;
                OptinTelDomicile = compte.optinTelephoneDomicileKparK__c;
                OptinTelMobile   = compte.optinTelephoneMobileKparK__c;
                NbPhonings       = compte.nbPhonings__c;
                NbAppelsSortants = compte.nbAppelsSortants__c;
                DateDernierAppel = compte.dateDernierAppelSortantKparK__c;
                Profession       = compte.profession__c;
                NumCompte        = compte.AccountNumber;
            }
            if(null != event) {
                ActivityDate   = (event.ActivityDate == null) ? null : event.ActivityDate.format();
                RdvType        = event.Type;
            }
        }
    }
}