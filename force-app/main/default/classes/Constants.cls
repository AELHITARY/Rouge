//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Constants
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/06/2020
//-- Version     : 2.12
//-- * 2.12 - Ajout des constantes pour les nouveaux rôles/profils
//-- * 2.11 - Ajout RT pour comptes FSL
//-- * 2.10 - Ajout du type R0
//-- * 2.9 - Ajout des status de l'objet historique des batchs
//-- --------------------------------------------------------------------------------- --
public without sharing class Constants {

    public static final Integer typeRegrOptVers = 3;
    public static final Integer typeRegrPack = 4;
    public static final Integer typeRegrCateg = 5;
    public static final Id IdRoot = null;
    public static final String Root = 'ROOT';
    public static final String EcoPrime = 'ECOPRIME';
    public static final String msgNoRevisionPack = 'Nous n\'avons pas trouvé de Revision Pack pour ce produit.';
    public static final String msgLoseModifications = 'Vous êtes sur le point de perdre vos modifications.';
    public static final String msgChooseOpt = 'Vous devez choisir une Option de Version !';
    public static final String msgChooseVersion = 'Vous devez choisir une version !';
    public static final String msgIncompatibleOpt = 'Cette option est incompatible avec les options suivantes: ';
    public static final String msgIncompatibleOptVers = 'Cette option de version est incompatible avec les options suivantes: ';
    public static final String msgUsedCodeCoupon = 'Ce code coupon est déjà utilisé dans un autre projet: ';
    public static final String msgErrorNoRVFound = 'L\'adresse renseignée ne se trouve pas dans votre secteur.\nIl n\'est pas possible de réassigner le lead.';
    public static final String msgErrorTropCodeCoupon = 'Ce code coupon a atteint son nombre maximum d\'utilisation';
    public static final String msgErrorDevisVendu = 'Il existe déjà un devis VENDU pour ce projet. Merci de mettre à jour le statut du devis actuellement VENDU avant de valider cette saisie';
    public static final String msgWarningDevisErrone = 'Votre devis initial va passer au statut Erroné.';
    public static final String campagneType = 'Campagne';
    public static final String KparK_logo_NB = 'KparK_logo_NB';
    public static final String Devis_Pied_de_page = 'Devis_Pied_de_page';
    public static final String KparKLogoBasPage = 'KparKLogoBasPage';

    // PROFILS UTILISATEURS
    public static final String PROFIL_ADMIN_SYSTEME = 'Administrateur système';
    public static final String PROFIL_DV = 'K/K - DV';
    public static final String PROFIL_RV = 'K/K - RV';
    public static final String PROFIL_Vendeur = 'K/K - Vendeur';
    public static final String PROFIL_KPK_CONSULTATION = 'K/K - K par K (Consultation)';
    public static final String PROFIL_KPK_DONNEES = 'K/K - K par K (Données)';
    public static final String PROFIL_KPK_REFERENTIELS = 'K/K - K par K (Référentiels)';
    public static final String PROFIL_KPK_REFDONNEES = 'K/K - K par K (Réf/Données)';
    public static final String PROFIL_KPK_ADMIN = 'K/K - K par K (Administrateur)';

    // ROLES UTILISATEURS K PAR K (GROUPES PUBLIQUES)
    public static final String ROLE_KPK_FORMATEUR = 'ROLE_Formateur';
    public static final String ROLE_KPK_FOIRE = 'ROLE_Foire';
    public static final String ROLE_KPK_TA = 'ROLE_TA';
    public static final String ROLE_KPK_SUP = 'ROLE_Superviseur';
    public static final String ROLE_KPK_AC = 'ROLE_Assistant_Call';
    public static final String ROLE_KPK_DC = 'ROLE_Directeur_Call';
    public static final String ROLE_KPK_MARKETING = 'ROLE_Marketing';
    public static final String ROLE_KPK_CG = 'ROLE_Controleur_de_Gestion';
    public static final String ROLE_KPK_RCG = 'ROLE_Responsable_Controle_de_Gestion';
    public static final String ROLE_KPK_CE = 'ROLE_Controleur_d_Exploitation';
    public static final String ROLE_KPK_RMC = 'ROLE_Responsable_Methode_et_Controle';
    public static final String ROLE_KPK_DAF = 'ROLE_Directeur_Admin_et_Financier';
    public static final String ROLE_KPK_DE = 'ROLE_Directeur_Executif';
    public static final String ROLE_KPK_SUPPORT = 'ROLE_Support_Utilisateur';
    
    // RECORD TYPE REFERENCIAL
    public static final String REFERENCIAL_ENTITY_RT                    = 'EntityType';
    public static final String REFERENCIAL_JOB_RT                       = 'Job';
    public static final String REFERENCIAL_JOBHIERARCHY_RT              = 'JobHierarchy';
    public static final String REFERENCIAL_PUBLICHOLIDAY_RT             = 'PublicHoliday';
    public static final String REFERENCIAL_CATALOGMARGIN_RT             = 'CatalogMargin';
    public static final String REFERENCIAL_PROVIDERDELIVERYDELAY_RT     = 'ProviderDeliveryDelay';
    public static final String REFERENCIAL_REFUNDREASON_RT              = 'RefundReason';
    public static final String REFERENCIAL_TERMSANDCONTITIONS_RT        = 'TermsAndConditions';

    // RECORD TYPE COMPTE
    public static final String ACCOUNT_PERSO_RT   = 'PersonalAccount';
    public static final String ACCOUNT_PRO_RT     = 'BusinessAccount';
    public static final String ACCOUNT_PROVIDER_RT        = 'Provider';
    public static final String ACCOUNT_ENTITY_RT          = 'Entity';
    public static final String ACCOUNT_FUNDINGORG_RT      = 'FundingOrganization';
    public static final String ENTITY_RT          = 'Entity';
    public static final String ACCOUNT_EXTERNE_RT = 'FSLExternalResource';

    // RECORD TYPE COLLABORATEURS (REMVRP)
    public static final String COLLABORATOR_RT_INTERNAL = 'InternalCollaborator';
    public static final String COLLABORATOR_RT_EXTERNAL = 'ExternalCollaborator';
    public static final String COLLABORATORCONTRACT_RT_CONTRACT = 'Contract';

    public static final String COLLABORATOR_TYPE_CDI = 'CDI';
    public static final String COLLABORATOR_TYPE_CDD = 'CDD';
    public static final String COLLABORATOR_TYPE_CTT = 'CTT';
    public static final String COLLABORATOR_TYPE_CUI = 'CUI';
    public static final String COLLABORATOR_TYPE_CAE = 'CAE';
    public static final String COLLABORATOR_TYPE_CIE = 'CIE';
    public static final String COLLABORATOR_TYPE_APPRENTISSAGE = 'Contrat d\'apprentissage';
    public static final String COLLABORATOR_TYPE_PROFESSIONNALISATION = 'Contrat de professionnalisation';

    // RECORD TYPE ORDER
    public static final String ORDER_RT_CUSTOMER = 'CustomerOrder';
    public static final String ORDER_RT_PROVIDER = 'ProviderOrder';
    public static final String ORDER_RT_AMENDMENT = 'AmendmentUnavailable';

    // RECORD TYPE GRILLE REVISION ET REMUNERATION
    public static final String GRID_RT_TEAM = 'teamCommission';
    public static final String GRID_RT_SALES = 'salesCommission';
    public static final String GRID_RT_CONTRACT = 'workingContract';
    public static final String GRID_RT_DISCOUNT = 'discountCommission';
    public static final String GRID_RT_BONUS = 'bonus';
    public static final String GRID_RT_MALUS = 'malus';

    // RECORD TYPE TAUX DE REMUNERATION
    public static final String REMUNERATION_RATE_RT_TEAM = 'teamCommission';
    public static final String REMUNERATION_RATE_RT_DISCOUNT = 'discountCommission';
    public static final String REMUNERATION_RATE_RT_SALES = 'saleCommission';
    public static final String REMUNERATION_RATE_RT_BONUS = 'bonus';
    public static final String REMUNERATION_RATE_RT_MALUS = 'malus';

    // TYPE DE COMMANDE
    public static final String ORDER_TYPE_COMMANDE_CLIENT ='Commande client';
    public static final String ORDER_TYPE_RECOMMANDE_CLIENT = 'Recommande client';
    public static final String ORDER_TYPE_COMMANDE_DE_STOCK = 'Commande de stock';
    public static final String ORDER_TYPE_COMMANDE_SAV = 'Commande SAV';
    public static final String ORDER_TYPE_AVENANT = 'Avenant';

    // TYPE DE COMPTE
    public static final String ACCOUNT_TYPE_DEPOT = 'Dépôt';
    public static final String ACCOUNT_TYPE_EXCLIENT = 'Ex-client';
    public static final String ACCOUNT_TYPE_CLIENT = 'Client';
    public static final String ACCOUNT_TYPE_PROSPECT = 'Prospect';
    public static final String ACCOUNT_TYPE_CONTACT = 'Contact';
    public static final String ACCOUNT_TYPE_PRECONTACT = 'Pré-contact';
    public static final String ACCOUNT_TYPE_PISTE = 'Piste';
    public static final Map<String, Integer> ACCOUNT_TYPE_PRIORITY = new Map<String, Integer>{
        ACCOUNT_TYPE_CLIENT => 1,
        ACCOUNT_TYPE_PROSPECT => 2,
        ACCOUNT_TYPE_CONTACT  => 3,
        ACCOUNT_TYPE_PRECONTACT => 4,
        ACCOUNT_TYPE_PISTE => 5
    };

    // TYPE DOTATION DE COMPTE
    public static final String ACCOUNT_DOTATION_TYPE_CARTE_CADEAU = 'Carte cadeaux';
    public static final String ACCOUNT_DOTATION_TYPE_CHEQUE_ELECTRONIQUE = 'Chèque cadeaux électronique';
    public static final String ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER = 'Chèque cadeaux papier envoyé en recommandé';

    // TYPE DE COMMISSION
    public static final String COMMISSION_TYPE_SALES = 'Vendeur';
    public static final String COMMISSION_TYPE_TEAM = 'Equipe';
    public static final String COMMISSION_TYPE_BONUS = 'Bonus';
    public static final String COMMISSION_TYPE_MALUS = 'Malus';
    public static final String COMMISSION_TYPE_REPORT = 'Report';

    // SOURCE DE CONTACT
    public static final String CONTACT_SOURCE_BAL = 'BAL VENDEUR';
    public static final String CONTACT_SOURCE_TAP = 'PORTE A PORTE VENDEUR';
    public static final String CONTACT_SOURCE_PHONE = 'TELEPHONE VENDEUR';
    public static final String CONTACT_SOURCE_COMPLEMENT = 'COMPLEMENT VENDEUR';
    public static final String CONTACT_SOURCE_PARRAINAGE = 'PARRAINAGE VENDEUR';
    public static final String CONTACT_SOURCE_STANDGM = 'STAND GM';
    public static final String CONTACT_SOURCE_FOIRE = 'FOIRE';
    public static final String CONTACT_SOURCE_MARCHE = 'STAND MARCHE VENDEUR';

    // MOTIF DE REFUS/REPORT DE PROJET
    public static final String OPP_MOTIFREFUS_CONCURRENCE = 'Concurrence';
    public static final String OPP_MOTIFREFUS_PRIX = 'Prix';
    public static final String OPP_MOTIFREFUS_PRODUIT = 'Produit';
    public static final String OPP_MOTIFREFUS_RELATIONNEL = 'Relationnel';
    public static final String OPP_MOTIFREFUS_BUDGET = 'Budget';
    public static final String OPP_MOTIFREFUS_MATURITE = 'Maturité du projet';
    public static final String OPP_MOTIFREFUS_NONPRIO = 'Non prioritaire';
    public static final String OPP_MOTIFREFUS_AUTRE = 'Autre';

    // Type d'enregistrement collaborateur
    public static final String COLLABORATOR_TYPE_INTERN = 'internalCollaborator';
    public static final String COLLABORATOR_TYPE_EXTERN = 'externalCollaborator';

    // STATUT OPPORTUNITE
    public static final String OPP_STATUT_VENDU = 'Vendu';
    public static final String OPP_STATUT_REFUS = 'Refus';
    public static final String OPP_STATUT_REPORTE = 'Reporté';
    public static final String OPP_STATUT_DEVISENV = 'Devis envoyé';
    public static final String OPP_STATUT_DEVIS = 'Devis';
    public static final String OPP_STATUT_RDV = 'RDV';
    public static final String OPP_STATUT_ANALYSE = 'Analyse';
    public static final Map<String, Integer> OPP_STATUT_PRIORITY = new Map<String, Integer>{
        OPP_STATUT_VENDU => 1,
        OPP_STATUT_REFUS => 2,
        OPP_STATUT_REPORTE  => 3,
        OPP_STATUT_DEVISENV => 4,
        OPP_STATUT_DEVIS => 5,
        OPP_STATUT_RDV => 6,
        OPP_STATUT_ANALYSE => 7
    };

    // DEVIS ET CONFIG OPTION
    public static final String QUOTE_TYPECONTRAT_STANDARD = 'Menuiseries (Standard)';
    public static final String QUOTE_TYPECONTRAT_FOIRE = 'Menuiseries (Foires et Salons)';
    public static final String QUOTE_TYPECONTRAT_ISOLATION_STANDARD = 'Isolation (Standard)';
    public static final String QUOTE_TYPECONTRAT_ISOLATION_FOIRE = 'Isolation (Foires et Salons)';
    public static final String QUOTE_TYPECONTRAT_INDICATEUR = 'Indicateur recette';

    public static final String QUOTE_EMAIL_SENDPDF = 'Devis_email_pdf_client';
    public static final String QUOTE_PDF_FILENAME = 'Devis-KparK';
    public static final String MsgConfirmDevisErrone = 'Votre statut est-il erroné ?';
    public static final String LeadDefaultStatus = 'Piste';
    public static final String LeadDefaultNature = 'Particulier';
    public static final String LeadDefaultDateConstr = 'NSP';
    public static final String msgSuccessDevis = 'Le devis a été envoyé avec succès.';
    public static final String msgErrorDevis = 'Une erreur s\'est produite lors de l\'envoi du devis: ';
    public static final String devisTransmisMail = 'Par email';
    public static final String OpportunityDernierRDVobligatoires = 'Aucun RDV réalisé pour ce Projet';
    public static final String msgErrorNoEmail = 'Aucun Email renseigné sur ce Compte';
    public static final String msgErrorQuoteToConfigure = 'Votre devis est au statut \'A configurer\', il ne peut être envoyé.';
    
    public static final String PACKCOMM = 'PACK COMMERCIAL';
    public static final String REMISESLEGALES = 'REMISES LEGALES';
    public static final String ECOSUBVENT = 'ECOSUBVENT';

    // RECORD TYPE EVENT & TASK
    public static final String ACTIVITE_COMMERCIALE_RT    = 'FRA_Activit_commerciale';
    public static final String ACTIVITE_ANNEXE_Vendeur_RT = 'FRAActivitannexeVendeur';
    public static final String ACTIVITE_ANNEXE_TA_RT      = 'FRAActivitannexeTA';
    public static final String ACTIVITE_PROSPECTION_RT    = 'FRAActivitprospection';
    public static final String TASK_PHONING_RT            = 'FRA_Phoning_vendeur';
    public static final String TASK_VENDEUR_RT            = 'FRATtachesvendeur';
    public static final String TASK_APPEL_SORTANT_RT      = 'FRA_Tag_Appel';
    public static final String TASK_APPEL_ENTRANT_RT      = 'FRA_Appel_entrant_hors_si_ge_TA';
    public static final String TASK_A_FAIRE_RT            = 'FRAAfaireTA';
    
    // RECORDTYPE ORDERPAYMENT
    public static final String ORDERPAYMENT_FINANCEMENT_RT    = 'Financement';
    public static final String ORDERPAYMENT_ACOMPTE_RT = 'Acompte';
    public static final String ORDERPAYMENT_SPECIFIC_RT = 'specificInvoicePayment';
    public static final String ORDERPAYMENT_SIMPLE_RT      = 'Simple';

    // RECORDTYPE INVOICE
    public static final String INVOICE_INVOICE_RT = 'Invoice';
    public static final String INVOICE_ADVANCEINVOICE_RT = 'AdvanceInvoice';
    
    // RECORDTYPE CASE 
    public static final String CASE_NCP_INTERNE_RT = 'InternalProductNonCompliance';

    // RECORDTYPE ACCOUNTINGENTRY
    public static final String ACCOUNTINGENTRY_BANKREMITTANCE_CANCELLATION_RT = 'BankRemittanceCancellation';
    public static final String ACCOUNTINGENTRY_OTHEREXPENCE_RT = 'OtherExpence';
    public static final String ACCOUNTINGENTRY_OTHERREVENUE_RT = 'OtherRevenue';
    public static final String ACCOUNTINGENTRY_VATDIFFERENCE_RT = 'VATDifference';
    public static final String ACCOUNTINGENTRY_BANKFEES_RT = 'BankFees';
    public static final String ACCOUNTINGENTRY_UNPAID_RT = 'Unpaid';
    public static final String ACCOUNTINGENTRY_BANKREMITTANCE_RT = 'BankRemittance';
    public static final String ACCOUNTINGENTRY_CASHWITHDRAWAL_RT = 'CashWithdrawal';
    public static final String ACCOUNTINGENTRY_BANKBALANCE_RT = 'BankBalance';
    public static final String ACCOUNTINGENTRY_HEADOFFICE_TRANSFER_RT = 'HeadOfficeTransfer';

    // RECORDTYPE ACCOUNTINGPIECE
    public static final String ACCOUNTINGPIECE_AGIOS_RT = 'Agios';
    public static final String ACCOUNTINGPIECE_UNDELIVERED_RECEIPTCANCELLATION_RT = 'UndeliveredReceiptCancellation';
    public static final String ACCOUNTINGPIECE_RECEIPTCANCELLATION_RT = 'ReceiptCancellation';
    public static final String ACCOUNTINGPIECE_DOUBTFULDEBT_RT = 'DoubtfulDebt';
    public static final String ACCOUNTINGPIECE_CHECKREQUEST_RT = 'CheckRequest';
    public static final String ACCOUNTINGPIECE_PAYMENT_DIFFERENCE_RT = 'PaymentDifference';
    public static final String ACCOUNTINGPIECE_VAT_DIFFERENCE_RT = 'VATDifference';
    public static final String ACCOUNTINGPIECE_RECEIPT_RT = 'Receipt';
    public static final String ACCOUNTINGPIECE_COMPOSITERECEIPT_RT = 'CompositeReceipt';
    public static final String ACCOUNTINGPIECE_UNPAID_RT = 'Unpaid';
    public static final String ACCOUNTINGPIECE_MISCELLANEOUS_OPERATION_RT = 'MiscellaneousOperation';
    public static final String ACCOUNTINGPIECE_PROFITSANDLOSSES_RT = 'ProfitsAndLosses';
    public static final String ACCOUNTINGPIECE_REFUND_RT = 'Refund';
    
    // RECORDTYPE CREDITMEMO
    public static final String CREDITMEMO_INVOICECREDITMEMO_RT = 'InvoiceCreditMemo';
        public static final String CREDITMEMO_COMMERCIALCREDITMEMO_RT = 'CommercialCreditMemo';

    // DEVIS - NATURE DES TRAVAUX
    public static final String QUOTE_NATURETRAVAUX_FONDATIONS = 'Sans impact sur les fondations';
    public static final String QUOTE_NATURETRAVAUX_ELEMENTS = 'Sans impact sur > 5/6 éléments suivants';
    public static final String QUOTE_NATURETRAVAUX_SURFACE = 'Sans augmentation de surface';
    public static final String QUOTE_NATURETRAVAUX_SURELEVATION = 'Sans surélévation, ni construction';

    // DEVIS - LOCALISATION DES TRAVAUX
    public static final String QUOTE_LOCALISATIONTRAVAUX_LOCAL_AFFECTE = 'Local affecté à l\'habitation';
    public static final String QUOTE_LOCALISATIONTRAVAUX_PIECES_HABITAT = 'Pièces d\'habitation (local < 50%)';
    public static final String QUOTE_LOCALISATIONTRAVAUX_PARTIES_COMMUNES = 'Parties communes';
    public static final String QUOTE_LOCALISATIONTRAVAUX_LOCAL_TRANSFORME = 'Local transformé à l\'habitation';

    // DEVIS - NATURE DES LOCAUX
    public static final String QUOTE_NATURELOCAUX_MAISON = 'Maison ou immeuble individuel';
    public static final String QUOTE_NATURELOCAUX_IMMEUBLE = 'Immeuble collectif';
    public static final String QUOTE_NATURELOCAUX_APPARTEMENT = 'Appartement individuel';
    public static final String QUOTE_NATURELOCAUX_AUTRE = 'Autre';

    // DEVIS - MOYEN DE TRASMISSION AU CLIENT
    public static final String QUOTE_TRANSMISSION_SIGN_ELECTRONIQUE = 'Signature électronique';

    // STATUS TASK
    public static final String StatutTaskAFaire = 'A faire';
    public static final String StatutTaskTermine = 'Terminé';

    // STATUS DEVIS
    public static final String StatutDevisNonTransmis = 'Non transmis';
    public static final String StatutDevisTransmis = 'Transmis';
    public static final String StatutDevisAConfigurer = 'A configurer';
    public static final String StatutDevisVenduAttente = 'Vendu en attente d\'enregistrement';
    public static final String StatutDevisVenduEnregistre = 'Vendu enregistré';
    public static final String StatutDevisVenduIncontournable = 'Vendu incontournable';
    public static final String StatutDevisErrone = 'Erroné';
    public static final String StatutDevisResilie = 'Résilié';
    public static final String StatutDevisExpire = 'Expiré';

    // STATUS DEVIS FORMAT CONSTANTES
    public static final String STD_QUOTE_STATUS_TO_CONFIGURE = 'A configurer';
    public static final String QUOTE_STATUS_TO_CONFIGURE = 'À configurer';
    public static final String QUOTE_STATUS_NOT_TRANSMITTED = 'Non Transmis';
    public static final String QUOTE_STATUS_APPROVAL = 'En attente d\'approbation';
    public static final String QUOTE_STATUS_TRANSMITTED = 'Transmis';
    public static final String QUOTE_STATUS_SOLD = 'Vendu';
    public static final String QUOTE_STATUS_CANCELLED = 'Annulé';

    public static final String QUOTE_PAIEMENT_COMPTANT = 'PAIEMENT COMPTANT';
    public static final String QUOTE_PAIEMENT_ECO = 'ECO-PTZ';

    // STATUS COMMANDES
    public static final String ORDER_STATUS_REGISTERED = 'Registered';
    public static final String ORDER_STATUS_CONFIRMED = 'Confirmed';
    public static final String ORDER_STATUS_CANCELLED = 'Cancelled';
    public static final String ORDER_STATUS_CLOSED = 'Closed';
    public static final String ORDER_STATUS_VALIDATED = 'Validated';
    public static final String ORDER_STATUS_TRANSMITTED = 'Transmitted';
    public static final String ORDER_STATUS_AMENDING = 'AmendmentInProgress';
    public static final String ORDER_STATUS_MANUFACTURING = 'Manufacturing';
    public static final String ORDER_STATUS_MANUFACTURED = 'Manufactured';
    public static final String ORDER_STATUS_DELIVERING = 'Delivering';
    public static final String ORDER_STATUS_DELIVERED = 'Delivered';
    public static final String ORDER_STATUS_CONTROLLED = 'Controlled';
    public static final String ORDER_STATUS_ORDERED = 'Ordered';
    public static final String ORDER_STATUS_INSTALLED = 'Installé';
    public static final String ORDER_STATUS_BILLEDNOTDELIVERED = 'BilledNotDelivered';
    public static final String ORDER_STATUS_BILLED = 'Billed';
    public static final String ORDER_STATUS_PAID = 'Paid';
    public static final String ORDER_STATUS_SUSPENDED = 'Suspended';
    
    // STATUS ASSET
    public static final String ASSET_STATUS_VALIDE = 'Validé';
    public static final String ASSET_STATUS_CONTROLE = 'Métré';
    public static final String ASSET_STATUS_COMMANDE = 'Commandé';
    public static final String ASSET_STATUS_LIVRE = 'Livré';
    public static final String ASSET_STATUS_ENSERVICE = 'En service';
    public static final String ASSET_STATUS_TERMINE = 'Terminé';
    public static final String ASSET_STATUS_SAV = 'SAV';
    public static final String ASSET_STATUS_ANNULE = 'Annulé';
    public static final String ASSET_STATUS_SUSPENDU = 'Suspendu';

    // RECORD TYPE ASSET
    public static final String ASSET_CARPENTRY_RT = 'Carpentry';
    public static final String ASSET_COMPONENT_RT = 'Component';

    // STATUS LIGNES DE COMMANDES
    public static final String ORDERITEM_STATUS_REGISTERED = 'Enregistré';
    public static final String ORDERITEM_STATUS_VALIDATED = 'Validé';
    public static final String ORDERITEM_STATUS_TRANSMITTED = 'Transmis';
    public static final String ORDERITEM_STATUS_CONFIRMED = 'Confirmé';
    public static final String ORDERITEM_STATUS_BUILDING = 'En cours de fabrication';
    public static final String ORDERITEM_STATUS_BUILT = 'Fabriqué';
    public static final String ORDERITEM_STATUS_SENT = 'Expédié';
    public static final String ORDERITEM_STATUS_RECEIVED = 'Livré';
    public static final String ORDERITEM_STATUS_BILLEDNOTDELIVERED = 'Facturé non livré';
    public static final String ORDERITEM_STATUS_BILLED = 'Facturé';
    public static final String ORDERITEM_STATUS_PAID = 'Payé';
    public static final String ORDERITEM_STATUS_CANCELLED = 'Annulé';

    public static final String ORDERITEM_STAGE_REGISTERING = 'Enregistrement';
    public static final String ORDERITEM_STAGE_CONFIRM = 'Confirmation';
    public static final String ORDERITEM_STAGE_BUILDING = 'Fabrication';
    public static final String ORDERITEM_STAGE_DELIVERING = 'Livraison';
    public static final String ORDERITEM_STAGE_BILLING = 'Facturation';
    public static final String ORDERITEM_STAGE_CTRL = 'Contrôle';
    public static final String ORDERITEM_STAGE_ORDER = 'Commande';
    public static final String ORDERITEM_STAGE_INSTALLATION = 'Installation';
    public static final String ORDERITEM_STAGE_GUARANTY = 'Garantie';
    public static final String ORDERITEM_STAGE_NO_GUARANTY = 'Hors garantie';
    public static final String ORDERITEM_STAGE_SAV = 'SAV';

    public static final String ORDERITEM_STATUTREVISION_UPDATING = 'En cours de révision';
    public static final String ORDERITEM_STATUTREVISION_UPDATED = 'Révisé';
    public static final String ORDERITEM_STATUTREVISION_ASSETUPDATED = 'Asset Mis à Jour';

    // STATUS COMMISSIONS
    public static final String COMMISSION_STATUS_PREVISIONEL = 'Prévisionnelle';
    public static final String COMMISSION_STATUS_NOT_COMMISSIONABLE = 'Non commissionnable';
    public static final String COMMISSION_STATUS_COMMISSIONABLE = 'Commissionnable';
    public static final String COMMISSION_STATUS_UNCOMMISSIONABLE = 'Décommissionnable';
    public static final String COMMISSION_STATUS_COMMISSIONED = 'Commissionnée';
    public static final String COMMISSION_STATUS_REGULARIZABLE = 'Régularisable';
    public static final String COMMISSION_STATUS_REGULATED = 'Régularisée';
    public static final String COMMISSION_STATUS_CANCELED = 'Annulée';

    public static final String QUOTETOPROCESS_STATUS_PENDING = 'PENDING';
    public static final String QUOTETOPROCESS_STATUS_PROCESSING = 'PROCESSING';
    public static final String QUOTETOPROCESS_STATUS_PROCESSED = 'PROCESSED';

    // STATUS EVENTS
    public static final String StatutEventPris = 'Pris';
    public static final String StatutEventAReaffecter = 'A réaffecter';
    public static final String StatutEventNoneffectue = 'Non effectué';
    public static final String StatutEventEffectue = 'Effectué';
    public static final String StatutEventDeplace = 'Déplacé';
    public static final String StatutEventNonConfirme = 'Non confirmé';
    public static final String StatutEventNoneffectueAvDep = 'Non effectué (avec déplacement)';
    public static final String StatutEventAnnuleCall = 'Annulé Call';

    // STATUS ACCOUNTING PIECE
    public static final String ACCOUNTINGPIECE_STATUS_INPROGRESS = 'En cours';
    public static final String ACCOUNTINGPIECE_STATUS_COUNTED = 'Comptabilisé';
    public static final String ACCOUNTINGPIECE_STATUS_CANCELED = 'Annulé';
    public static final String ACCOUNTINGPIECE_STATUS_APPROVAL = 'En attente d\'approbation';
    
    // EVENTS - COUPLE PRESENT
    public static final String EventCouplePresent = 'Oui';
    public static final String EventCoupleAbsent = 'Non';
    public static final String EventCoupleSeul = 'Seul';
    public static final String EventCoupleAConfirmer = 'A confirmer';
    
    // STATUS LISTE DE PHONES
    public static final String StatutLDPEnCours = 'En cours';
    public static final String StatutLDPAnnulee = 'Annulée';
    public static final String StatutLDPDebriefeePartiellement = 'Débriefée partiellement';
    public static final String StatutLDPDebriefee = 'Débriefée';

    // RECORD TYPE DEVIS
    public static final String RT_QUOTE_ERRONE          = 'FRDevisErrone';
    public static final String RT_QUOTE_NONTRANSMIS     = 'FRA_Devis_Non_Transmis';
    public static final String RT_QUOTE_RO              = 'FRA_Devis_RO';
    public static final String RT_QUOTE_TRANSMISVENDU   = 'FRA_Devis_Transmis_ou_Vendu';
    public static final String RT_QUOTE_ACONFIGURER     = 'FRADevis';
    public static final String QUOTE_SALES_RT    = 'SalesQuote';
    public static final String QUOTE_SAV_RT = 'AfterSalesServiceQuote';

    // EVENEMENTS
    public static final Set<string> EVENT_ACTIVITE_COMMERCIALE_TYPES = new Set<string> { 'R0', 'R1', 'R2', 'R+' };
    public static final Set<string> EVENT_ACTIVITE_ANNEXE_TYPES      = new Set<string> { 'Absent', 'Maladie' };
    public static final Set<String> EVENT_ACTIVITE_CONGE_TYPES       = new Set<String> { 'Congé', 'Maladie', 'Absent', 'JSR', 'Préavis non effectué' };
    public static final String EVENT_TYPE_R0 = 'R0';
    public static final String EVENT_TYPE_R1 = 'R1';
    public static final String EVENT_TYPE_R2 = 'R2';
    public static final String EVENT_TYPE_RP = 'R+';
    public static final String EVENT_TYPE_Conge = 'Congé';
    public static final String EVENT_TYPE_Maladie = 'Maladie';
    public static final String EVENT_TYPE_Absent = 'Absent';
    public static final String EVENT_TYPE_JSR = 'JSR';
    public static final String EVENT_TYPE_PreavisNonEffectue = 'Préavis non effectué';
    public static final String EVENT_TYPE_VISITEPOSE = 'Visite de pose';

    // STATUS CASE
    public static final String REQUETE_STATUS_CLOSED = 'Clôturé';
    public static final String REQUETE_STATUS_TO_CLOSE = 'A clôturer';    
    public static final String REQUETE_STATUS_DIAGNOSTIC = 'Diagnostiqué';  
    public static final String REQUETE_STATUS_DELIVERED = 'Livré';
    public static final String REQUETE_STATUS_ORDERED = 'Commandé';  
    public static final String REQUETE_STATUS_SENT = 'Transmis';    
    public static final String REQUETE_STATUS_EXPERTISE = 'Expertisé';    
    public static final String REQUETE_STATUS_SOLDE = 'Soldé';        
    public static final String REQUETE_STATUS_CANCELLED = 'Annulé';    
    public static final String REQUETE_STATUS_INVOICED = 'Facturé';
    public static final String REQUETE_STATUS_CONCILIATION = 'Conciliation';    
    public static final String REQUETE_STATUS_ANSWERPROVIDER = 'Répondu Fournisseur'; 
    public static final String REQUETE_STATUS_ANSWERKPARK = 'Répondu K par K';
    public static final String REQUETE_STATUS_J1_RETARD = 'Non répondu (J1 / Retard)';
    public static final String REQUETE_STATUS_J2_ENGAGEMENT = 'Non répondu (J2 / Engagement)';
    public static final String REQUETE_STATUS_INPROGRESS = 'En cours';
    public static final String REQUETE_STATUS_NEW = 'Nouveau';
    public static final String REQUETE_STATUS_ESTIMATED = 'Devisé';

    // ETAPE CASE
    public static final String REQUETE_STEP_REGISTERED = 'Enregistrement';
    public static final String REQUETE_STEP_DIAGNOSTIC = 'Diagnostic';
    public static final String REQUETE_STEP_PROVIDER = 'Fournisseur';
    public static final String REQUETE_STEP_RESOLUTION = 'Résolution';
    public static final String REQUETE_STEP_CLOSED = 'Clôture';

    // RECORD TYPE CASE
    public static final String REQUETE_SERVICE_RT       = 'FRA_Fiches_service';
    public static final String REQUETE_CONTACT_RT       = 'FRAFichescontact';
    public static final String REQUETE_COORDONNEES_RT   = 'FRAModificationdecoordonnees';

    public static final String REQUETE_RECLAMATION_RT       = 'reclamation';
    public static final String REQUETE_RELATIONCLIENT_RT    = 'relationClient';
    public static final String REQUETE_PNC_INTERNAL_RT      = 'InternalProductNonCompliance';
    public static final String REQUETE_PNC_PROVIDER_RT      = 'ProviderProductNonCompliance';
    public static final String REQUETE_AUTRE_RT             = 'autreDemande';
    public static final String REQUETE_AQUALIFIER_RT        = 'aQualifier';

    // TYPE CASE
    public static final String REQUETE_ESPACE_CLIENT = 'Accès à l\'espace client';
    public static final String REQUETE_ANNULATION_CONTRAT = 'Annulation contrat';
    public static final String REQUETE_ANNULATION_RDV = 'Annulation de rendez-vous';
    public static final String REQUETE_DEMANDE_ADMIN = 'Demande administrative';
    public static final String REQUETE_DEMANDE_INFO = 'Demande d\'information';
    public static final String REQUETE_DEMANDE_CATALOGUE = 'Demande de catalogue';
    public static final String REQUETE_INSCRIPTION_CNIL = 'Inscription CNIL';
    public static final String REQUETE_MODIF_RDV = 'Modification de rendez-vous';
    public static final String REQUETE_NOUVEAU_RDV = 'Nouveau rendez-vous';
    public static final String REQUETE_RECLAMATION_CENTRE = 'Réclamation centre d\'appel';
    public static final String REQUETE_RECLAMATION_COMMERCIALE = 'Réclamation commerciale';
    public static final String REQUETE_RECLAMATION_INSTALLATION = 'Réclamation installation';
    public static final String REQUETE_RECLAMATION_MARKETING = 'Réclamation marketing';
    public static final String REQUETE_RECLAMATION_METRAGE = 'Réclamation métrage';
    public static final String REQUETE_RECLAMATION_SAV = 'Réclamation SAV';
    public static final String REQUETE_AUTRE = 'Autre';
    public static final String REQUETE_QUESTION = 'Question';
    public static final String REQUETE_ECI = 'ECI';
    public static final String REQUETE_SAV_GARANTIE = 'SAV garantie';
    public static final String REQUETE_SAV_HORS_GARANTIE = 'SAV hors garantie';

    // STATUS RDV DE SERVICE (SERVICE APPOINTMENT)
    public static final String RDV_FSL_DEMANDE = 'Demandé';
    public static final String RDV_FSL_PLANIFIE = 'Planifié';
    public static final String RDV_FSL_CONFIRME = 'Confirmé';
    public static final String RDV_FSL_ENROUTE = 'En route';
    public static final String RDV_FSL_TRANSMIS = 'Transmis';
    public static final String RDV_FSL_VERROUILLE = 'Verrouillé';
    public static final String RDV_FSL_ENCOURS = 'En cours';
    public static final String RDV_FSL_TERMINE = 'Terminé';
    public static final String RDV_FSL_DEBRIEFE = 'Débriefé';
    public static final String RDV_FSL_ANNULE = 'Annulé';

    // STATUS DES ELEMENTS D'ORDRE D'EXECUTION (WORK ORDER LINE ITEMS)
    public static final String WOLI_FSL_NOUVEAU = 'Nouveau';
    public static final String WOLI_FSL_ENCOURS = 'En cours';
    public static final String WOLI_FSL_TERMINE = 'Terminé';
    public static final String WOLI_FSL_EN_ATTENTE = 'En attente';
    public static final String WOLI_FSL_IMPO_TERMINER = 'Impossible de terminer';

    // STATUS DES ELEMENTS D'ORDRE D'EXECUTION (WORK ORDERS)
    public static final String WO_FSL_DEMANDE = 'Demandé';
    public static final String WO_FSL_ENCOURS = 'En cours';
    public static final String WO_FSL_TERMINE = 'Terminé';
    public static final String WO_FSL_ANNULE = 'Annulé';

    // WORKTYPE NAME
    public static final String WORKTYPE_DIAGNOSTIC_ECI = 'DIAGNOSTIC ECI';
    public static final String WORKTYPE_DIAGNOSTIC_INSTALLATION = 'DIAGNOSTIC INSTALLATION';
    public static final String WORKTYPE_DIAGNOSTIC_SAV = 'DIAGNOSTIC SAV';
    public static final String WORKTYPE_INSTALLATION = 'INSTALLATION';
    public static final String WORKTYPE_INSTALLATION_ECI = 'INSTALLATION ECI';
    public static final String WORKTYPE_INTERVENTION_SAV = 'INTERVENTION SAV';
    public static final String WORKTYPE_INTERVENTION_SAV_ECI = 'INTERVENTION SAV ECI';
    public static final String WORKTYPE_METRAGE = 'METRAGE';

    // FSL - WORKTYPE NAME
    public static final String ACTIVITY_TYPE_CONTROL = 'Métrage';
    public static final String ACTIVITY_TYPE_INTERVENTION = 'Intervention';
    public static final String ACTIVITY_TYPE_INSTALLATION = 'INSTALLATION';
    public static final String ACTIVITY_TYPE_DIAGNOSTIC = 'Diagnostic';
    
    // PRODUIT TYPE CALCUL DE PRIX
    public static final String PRODUCT_CALCULPRIX_STANDARD = 'Standard';
    public static final String PRODUCT_CALCULPRIX_SURFACE = 'Surface';

    // RECOMMANDE NPC
    public static final String NCP_REQUIREDORDER_COMMANDE = 'Commande';
    public static final String NCP_REQUIREDORDER_RECOMMANDE = 'Recommande';
    public static final String NCP_REQUIREDORDER_NON = 'Non';

    // TYPE DE RDV CASE
    public static final String REQUETE_RDV_COMMERCIAL = 'Commercial';
    public static final String REQUETE_RDV_INSTALLATION = 'Installation';
    public static final String REQUETE_RDV_METRAGE = 'Métrage';
    public static final String REQUETE_RDV_SAV = 'SAV';

    // TYPE D'EVENT CALL
    public static final String ACTIVITY_EVENT_NEW = 'Nouveau';
    public static final String ACTIVITY_EVENT_DISPLACED = 'Décalé';
    public static final String ACTIVITY_EVENT_CANCELLED = 'Annulé';
    public static final String ACTIVITY_EVENT_CANCELLEDWITHQUALIF = 'Annulé suite qualification';

    // TYPE AUTORISATION
    public static final String ENT_RECLAMATION = 'Requête réclamation';
    public static final String ENT_RELATIONCLIENT = 'Requête relation client';

    // STATUS FACTURE (INVOICE)
    public static final String INVOICE_GENEREE = 'Validée';
    public static final String INVOICE_EMISE = 'Publiée';
    public static final String INVOICE_BROUILLON = 'Brouillon';
    public static final String INVOICE_RETARD_PAIEMENT = 'Retard de paiement';
    public static final String INVOICE_ACQUITTEE = 'Acquittée';
    public static final String INVOICE_ANNULEE = 'Annulée';

    // STATUS AVOIR (CREDIT NOTE)
    public static final String CREDITMEMO_BROUILLON = 'Brouillon';
    public static final String CREDITMEMO_PUBLIE = 'Publié';
    public static final String CREDITMEMO_VALIDE = 'Validé';
    public static final String CREDITMEMO_ACQUITTE = 'Acquitté';
    public static final String CREDITMEMO_ANNULE = 'Annulé';

    // TYPE QUESTION/REPONSE DE FORMULAIRE NPS
    public static final String QUESTIONNAIRE_QUESTION_TYPE_TITRE = 'Titre';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_ETIQUETTE = 'Etiquette';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_TEXTE = 'Texte';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_NUMERO = 'Numéro';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_RADIO = 'Radio';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_CASE = 'Case à cocher';
    public static final String QUESTIONNAIRE_QUESTION_TYPE_MATRICE = 'Matrice';

    // RECORD TYPE IMPORT
    public static final String RT_IMPORT_EXTERNE    = 'importExterne';
    public static final String RT_IMPORT_CONTACT    = 'ficheContact';

    // STATUT HISTORIQUE DES BATCHS
    public static final String BATCHHISTORY_STATUS_DEMARRE = 'Démarré';
    public static final String BATCHHISTORY_STATUS_ENATTENTE = 'En attente';
    public static final String BATCHHISTORY_STATUS_ENCOURS = 'En cours';
    public static final String BATCHHISTORY_STATUS_TERMINE = 'Terminé';
    public static final String BATCHHISTORY_STATUS_ERREUR = 'Erreur';

    // CONSTANTE REGEX VERIFICATION DONNEES
    public static final String CHECK_OTHER  = '0123456789,;:!?./§*%µ^$¨£¤²&~"#{([|`_\\^@';
    public static final String REG_EMAIL    = '^[A-Za-z0-9\\.\\-_]+[@][A-Za-z0-9\\-\\.]+[\\.][A-Za-z]+?$';
    public static final String REG_TEL      = '^0[0-9]{9}$';
    public static final String REG_CP       = '^[0-9]{5}$';

    public static final String CARTO_MAP_NAME    = 'K par K working map';

    public static final Integer MAP_DOT_LIMITS      = PropertiesUtils.getIntegerValue('geoconcept.map.mapDotLimits', 1024);
    public static final Integer AJAX_DOT_SEND_LIMIT = PropertiesUtils.getIntegerValue('geoconcept.map.ajaxDotSendLimit', 1024);
    public static final Integer FDR_CHANTIER_LIMITS      = PropertiesUtils.getIntegerValue('feuillederoute.chantier.limit', 100);

    public static final List<String> MONTHS =  new List<String>
        {'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
    };
    
    // ODIGO VARIABLES
    public static String ODIGO_SKILL           = PropertiesUtils.getStringValue('prosodie.odigo.skill', 'Formulaire');    
    public static String ODIGO_DIM_SKILL       = PropertiesUtils.getStringValue('prosodie.odigo.dimanche.skill', 'FormulairesDIM');

    public static Integer ODIGO_DIM_OUVERTURE  = PropertiesUtils.getIntegerValue('prosodie.odigo.dimanche.ouverture', 00);
    public static Integer ODIGO_DIM_FERMETURE = PropertiesUtils.getIntegerValue('prosodie.odigo.dimanche.fermeture', 18);
    public static Integer ODIGO_TIMEOUT        = PropertiesUtils.getIntegerValue('prosodie.odigo.timeout', 10000);
    public static Integer ODIGO_PRIORITY       = PropertiesUtils.getIntegerValue('prosodie.odigo.priority', 1);

    // Custplace Variables
    public static final Map<String,String> CUSTPLACE_MAG_ID = new Map<String,String>
        {'KparK Paris Blanqui' => '91078',
        'KparK Pontault Combault Pontault-Combault' => '91097',
        'KparK Palaiseau PALAISEAU' => '91098',
        'KparK Avignon Le Pontet LE PONTET' => '91099',
        'KparK Dardilly' => '91100',
        'KparK Grenoble SEYSSINS' => '91101',
        'KparK Paris Rome PARIS' => '91102',
        'KparK Eysines EYSINES' => '91103',
        'KparK Bonneuil BONNEUIL SUR MARNE' => '91104',
        'KparK Montargis Montargis' => '91105',
        'KparK Charenton le Pont CHARENTON LE PONT' => '91106',
        'KparK Rambouillet Rambouillet' => '91107',
        'KparK Calais CALAIS' => '91108',
        'KparK Clermont-Ferrand COURNON-D\'AUVERGNE' => '91109',
        'KparK Clamart CLAMART' => '91110',
        'KparK Saintes Saintes' => '91111',
        'KparK Le Raincy LE RAINCY' => '91112',
        'KparK Evreux EVREUX' => '91113',
        'KparK Nangis Nangis' => '91114',
        'KparK Charleville Charleville-Mézières' => '91115',
        'KparK Lons le Saunier LONS LE SAUNIER' => '91116',
        'KparK Aix les Milles AIX EN PROVENCE' => '91117',
        'KparK Paris La Fayette Paris' => '91118',
        'KparK Douai Douai' => '91119',
        'KparK Dreux Dreux' => '91120',
        'KparK Antibes ANTIBES' => '91121',
        'KparK Montmorency MONTMORENCY' => '91122',
        'KparK Salaise sur Sanne Salaise-sur-Sanne' => '91123',
        'KparK Agen Agen' => '91124',
        'KparK Angers ANGERS' => '91125',
        'KparK Puilboreau Puilboreau' => '91126',
        'KparK Soissons SOISSONS' => '91127',
        'KparK Le Mans LE MANS' => '91128',
        'KparK Paris Popincourt PARIS' => '91129',
        'KparK Tremblay TREMBLAY EN FRANCE' => '91130',
        'KparK Chalon sur Saone CHALON SUR SAONE' => '91131',
        'KparK Neuilly NEUILLY' => '91132',
        'KparK Orange ORANGE' => '91133',
        'KparK Albi ALBI' => '91134',
        'KparK Nice Dante NICE' => '91135',
        'KparK Juvisy JUVISY' => '91136',
        'KparK Nemours Nemours' => '91137',
        'KparK Libourne Libourne' => '91138',
        'KparK Le Havre LE HAVRE' => '91139',
        'KparK Poissy Poissy' => '91140',
        'KparK Limonest LIMONEST' => '91141',
        'KparK Chambray les Tours CHAMBRAY LES TOURS' => '91142',
        'KparK Blois BLOIS' => '91143',
        'KparK Manosque MANOSQUE' => '91144',
        'KparK Chambery Chambéry' => '91145',
        'KparK Saint-Geours SAINT GEOURS DE MAREMNE' => '91146',
        'KparK Dunkerque COUDEKERQUE BRANCHE' => '91147',
        'KparK Toulouse Revel TOULOUSE' => '91148',
        'KparK Nimes Nîmes' => '91149',
        'KparK Orleans Orléans' => '91150',
        'KparK Saint Quentin SAINT QUENTIN' => '91151',
        'KparK Toulouse Ponts Jumeaux TOULOUSE' => '91152',
        'KparK Beziers Béziers' => '91153',
        'KparK Anglet Anglet' => '91154',
        'KparK Sevres Sèvres' => '91155',
        'KparK Chalons en Champagne CHALONS EN CHAMPAGNE' => '91156',
        'KparK Sens Saint-Clément' => '91157',
        'KparK Roanne ROANNE' => '91158',
        'KparK Versailles VERSAILLES' => '91159',
        'KparK Angoulême Angoulême' => '91160',
        'KparK Troyes TROYES' => '91161',
        'KparK Saint-Herblain Vigneux de-Bretagne' => '91162',
        'KparK Gerzat Gerzat' => '91163',
        'KparK Marignane Marignane' => '91164',
        'KparK Saint Etienne SAINT ETIENNE' => '91165',
        'KparK Champigny CHAMPIGNY SUR MARNE' => '91166',
        'KparK Thiais Thiais' => '91167',
        'KparK Valenciennes Girard VALENCIENNES' => '91168',
        'KparK Hyeres Hyères' => '91169',
        'KparK Marseille Banon MARSEILLE' => '91170',
        'KparK Vandœuvre-lès-Nancy' => '91171',
        'KparK Annecy Annecy' => '91172',
        'KparK Salon de Provence Salon-de-Provence' => '91173',
        'KparK Siège Boulogne-Billancourt' => '91174',
        'KparK Ales Alès' => '91175',
        'KparK Saint Priest Saint-Priest' => '91176',
        'KparK Auxerre AUXERRE' => '91177',
        'KparK Toulon Ollioules' => '91178',
        'KparK Chantilly CHANTILLY' => '91179',
        'KparK Paris Blanqui PARIS' => '91180',
        'KparK Montpellier Saint Bres Saint-Brès' => '91181',
        'KparK Agen AGEN' => '91182',
        'KparK Amiens Boves' => '91183',
        'KparK Dijon DIJON' => '91184',
        'KparK Amiens Amiens' => '91185',
        'KparK Montreuil Montreuil' => '91186',
        'KparK Macon Mâcon' => '91187',
        'KparK Montauban Montauban' => '91188',
        'KparK Bordeaux Villenave Villenave-d\'Ornon' => '91189',
        'KparK Vichy VICHY' => '91190',
        'KparK Tours TOURS' => '91191',
        'KparK Le Petit Quevilly Le Petit-Quevilly' => '91192',
        'KparK Brie Comte Robert Brie-Comte-Robert' => '91193',
        'KparK Lyon Lyon' => '91194',
        'KparK Seclin Seclin' => '91195',
        'KparK Caen Mondeville' => '91196',
        'KparK Nogent Le Phaye Nogent-le-Phaye' => '91197',
        'KparK Wambrechies Wambrechies' => '91198',
        'KparK Perpignan Perpignan' => '91199',
        'KparK Bourg en Bresse BOURG EN BRESSE' => '91200',
        'KparK LIMOGES' => '91201',
        'KparK Torcy Torcy' => '91202',
        'KparK Aubagne Aubagne' => '91203',
        'KparK Annemasse Ville-La-Grand' => '91204',
        'KparK Mantes la Jolie MANTES LA JOLIE' => '91205',
        'KparK Paris Garibaldi PARIS' => '91206',
        'KparK Reims REIMS' => '91207',
        'KparK Houilles HOUILLES' => '91208',
        'KparK Coignières COIGNIERES' => '91209',
        'KparK Ecouen Écouen' => '91210',
        'KparK Le Grand Quevilly LE GRAND QUEVILLY' => '91211',
        'KparK La Tour du Pin LA TOUR DU PIN' => '91212',
        'KparK Epernay Épernay' => '91213',
        'KparK Bourg La Reine Bourg La Reine' => '91214',
        'KparK Boulogne Billancourt BOULOGNE BILLANCOURT' => '91215',
        'KparK Marseille Baille MARSEILLE' => '91216',
        'KparK Compiegne Compiègne' => '91217',
        'KparK Saint Loubès SAINT LOUBES' => '91218',
        'KparK Cannes Cannes' => '91219',
        'KparK Fréjus Puget-sur-Argens' => '91220',
        'KparK Toulouse Sud Toulouse' => '91221',
        'KparK Maubeuge MAUBEUGE' => '91222',
        'KparK Albertville ALBERTVILLE' => '91223',
        'KparK Arpajon ARPAJON' => '91224',
        'KparK Meaux MEAUX' => '91225'
    };

    
}