//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Opportunity
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 06/06/2023
//-- Version     : 1.1
//-- * 1.1 - MAJ Kube3
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Opportunity {
    
    /**
    * @description Méthode exécutant les règles de validation pour les projets
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        /** A - Initialisation des données intermédiaires **/
        /*List<Opportunity> newOpportunities = (List<Opportunity>)Trigger.new;
        Map<Id, Opportunity> oldOpportunities = (Map<Id, Opportunity>)Trigger.oldMap;
        
        Set<Id> chantierIds = new Set<Id>();
        Set<Id> operationIds = new Set<Id>();    
        for (Opportunity newOpportunity : newOpportunities) {
        Opportunity oldOpportunity = oldOpportunities == null ? null : oldOpportunities.get(newOpportunity.id);
        
        chantierIds.add(newOpportunity.chantier__c);
        if (newOpportunity.operation__c != null)
        operationIds.add(newOpportunity.operation__c);      
        }
        
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>([SELECT id, codeMagasinActuel__c, libelleMagasinActuel__c FROM Chantier__c WHERE id IN :chantierIds]);
        
        Map<Id, ReferentielOperation__c> operations = new Map<Id, ReferentielOperation__c>([SELECT id, origine__c, dateDebut__c, dateFinSaisie__c FROM ReferentielOperation__c WHERE id IN :operationIds]);    
        
        // B - Application des règles de vérification 
        for (Opportunity newOpportunity : newOpportunities) {
        Opportunity oldOpportunity = oldOpportunities == null ? null : oldOpportunities.get(newOpportunity.id);
        Chantier__c chantier = chantiers.get(newOpportunity.chantier__c);
        
        //VR001_K2_Opportunity_HorsZone
        //   # Impossible avec Validation Rules car Salesforce ne permet pas plus de 10 jointures 
        if ('Administrateur système'.equalsIgnoreCase(userContext.getProfile().name) &&
        'K/K - Marketing'.equalsIgnoreCase(userContext.getProfile().name) &&
        'K/K - Import Lead'.equalsIgnoreCase(userContext.getProfile().name) &&
        'K/K - Interface'.equalsIgnoreCase(userContext.getProfile().name) &&
        Trigger.isInsert &&
        (String.isEmpty(chantier.codeMagasinActuel__c) || 'HORS ZONE'.equalsIgnoreCase(chantier.libelleMagasinActuel__c)))
        newOpportunity.addError('Création impossible d\'un nouveau projet en hors zone!');
        
        ReferentielOperation__c operation = operations.get(newOpportunity.operation__c);  
        Date createdDate = newOpportunity.createdDate.date();
        if (operation != null && (createdDate < operation.dateDebut__c || createdDate > operation.dateFinSaisie__c || newOpportunity.leadSource != operation.origine__c))
        newOpportunity.operation__c.addError('Opération commerciale invalide (Origine ou période de saisie incorrecte)!');
        }*/
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les projets
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        if (Trigger.isInsert) {
            initIndicators(userContext);    
        }

        applyStatusUpdateRules(userContext);
        applyDataUpdateRules(userContext);
    }
    
    private static void initIndicators(UserContext userContext) {
        for (Opportunity opportunity : (List<Opportunity>)Trigger.new) {
            opportunity.datePremierRPlus__c                 = null;
            opportunity.datePremierR1__c                    = null;
            opportunity.datePremierR2__c                    = null;
            opportunity.datePremierRDV__c                   = null;
            opportunity.dateDernierRPlus__c                 = null;
            opportunity.dateDernierR1__c                    = null;
            opportunity.dateDernierR2__c                    = null;
            opportunity.dateDernierRDV__c                   = null;
            opportunity.nbRPlusEffectues__c                 = null;
            opportunity.nbRPlusNonEffectues__c              = null;
            opportunity.nbRPlusNonEffectuesAvecDep__c       = null;
            opportunity.nbRPlusPris__c                      = null;
            opportunity.nbRPlusDeplaces__c                  = null;
            opportunity.nbR1Effectues__c                    = null;
            opportunity.nbR1NonEffectues__c                 = null;
            opportunity.nbR1NonEffectuesAvecDep__c          = null;
            opportunity.nbR1Pris__c                         = null;
            opportunity.nbR1Deplaces__c                     = null;
            opportunity.nbR2NonEffectues__c                 = null;
            opportunity.nbR2Effectues__c                    = null;
            opportunity.nbR2NonEffectuesAvecDep__c          = null;
            opportunity.nbR2Pris__c                         = null;
            opportunity.nbR2Deplaces__c                     = null;
            opportunity.nbRDVDevisables__c                  = null;
            opportunity.statutPremierRPlus__c               = null;
            opportunity.statutPremierR1__c                  = null;
            opportunity.statutPremierR2__c                  = null;
            opportunity.statutPremierRDV__c                 = null;
            opportunity.statutDernierRPlus__c               = null;
            opportunity.statutDernierR1__c                  = null;
            opportunity.statutDernierR2__c                  = null;
            opportunity.statutDernierRDV__c                 = null;
            
            opportunity.datePremierDevis__c                 = null;
            opportunity.dateDernierDevis__c                 = null;
            opportunity.statutPremierDevis__c               = null;
            opportunity.statutDernierDevis__c               = null;
            opportunity.totalHTDevisEnAttente__c            = null;
            opportunity.totalTTCDevisEnAttente__c           = null;
            opportunity.totalHTDevisEnregistres__c          = null;
            opportunity.totalTTCDevisEnregistres__c         = null;
            opportunity.totalRemisesEnAttenteEnseigne__c    = null;
            opportunity.totalRemisesEnAttenteVendeur__c     = null;
            opportunity.totalRemisesEnregistreesEnseigne__c = null;
            opportunity.totalRemisesEnregistreesVendeur__c  = null;
            opportunity.nbDevisAConfigurer__c               = null;
            opportunity.nbDevisErrones__c                   = null;
            opportunity.nbDevisNonTransmis__c               = null;
            opportunity.nbDevisResilies__c                  = null;
            opportunity.nbDevisTransmis__c                  = null;
            opportunity.nbDevisVendusEnAttente__c           = null;
            opportunity.nbDevisVendusEnregistres__c         = null;
            opportunity.nbDevisVendusIncontournables__c     = null;
            
            opportunity.datePremierContrat__c               = null;
            opportunity.dateDernierContrat__c               = null;
            opportunity.statutPremierContrat__c             = null;
            opportunity.statutDernierContrat__c             = null;
            opportunity.totalHTContratsVendus__c            = null;
            opportunity.totalTTCContratsVendus__c           = null;
            opportunity.totalHTContratsResilies__c          = null;
            opportunity.totalTTCContratsResilies__c         = null;
            opportunity.nbContratsVendus__c                 = null;
            opportunity.nbContratsResilies__c               = null;
            
            opportunity.datePremierIncontournable__c        = null;
            opportunity.dateDernierIncontournable__c        = null;
            opportunity.nbIncontournablesEnregistres__c     = null;
            opportunity.nbIncontournablesEnCours__c         = null;
            opportunity.nbIncontournablesTermines__c        = null;
            opportunity.statutPremierIncontournable__c      = null;
            opportunity.statutDernierIncontournable__c      = null;
            
            opportunity.datePremierAppelSortant__c          = null;
            opportunity.dateDernierAppelSortant__c          = null;
            opportunity.nbAppelsSortants__c                 = null;
            opportunity.datePremierTagAppel__c              = null;
            opportunity.dateDernierTagAppel__c              = null;
            opportunity.nbTagsAppel__c                      = null;
            opportunity.datePremierEmail__c                 = null;
            opportunity.dateDernierEmail__c                 = null;
            opportunity.nbEmails__c                         = null;
            opportunity.datePremierPhoning__c               = null;
            opportunity.dateDernierPhoning__c               = null;
            opportunity.nbPhonings__c                       = null;
        }
    }
    
    /**
    * @description Méthode exécutant les règles de mise à jour des champs pour les projets
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Opportunity : applyDataUpdateRules');
        
        /** A - Initialisation des données intermédiaires **/
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Map<Id, Opportunity> oldOpportunities = (Map<Id, Opportunity>)Trigger.oldMap;
        
        Set<Id> codeCouponIds = new Set<Id>();
        Map<Id, CodeCoupon__c> codeCoupons = null;
        Set<Id> chantierIds = new Set<Id>();
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();
        
        for (Opportunity newOpportunity : (List<Opportunity>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_Opportunity.applyDataUpdateRules', newOpportunity.id) || Test.isRunningTest()) {
                Opportunity oldOpportunity = oldOpportunities == null ? null : oldOpportunities.get(newOpportunity.id);
                // Code coupon
                if (newOpportunity.codeCoupon__c != null && newOpportunity.campaignId == null) {
                    codeCouponIds.add(newOpportunity.codeCoupon__c);
                }
                // Chantier
                System.debug('#Insert:'+Trigger.isInsert);
                System.debug('#newOpportunity Chantier :'+newOpportunity.chantier__c);              
                if ((Trigger.isInsert || (Trigger.isUpdate && oldOpportunity != null && oldOpportunity.chantier__c != newOpportunity.chantier__c)) 
                    && String.isNotBlank(newOpportunity.chantier__c)) 
                {
                    chantierIds.add(newOpportunity.chantier__c);
                }
                System.debug('#addOpportunity:'+newOpportunity.Id);                
                newOpportunities.add(newOpportunity);
            }
        }        
        System.debug('## newOpportunities : '+newOpportunities);

        if (newOpportunities.isEmpty())
            return;
        
        if (!codeCouponIds.isEmpty()) {
            codeCoupons = new Map<Id, CodeCoupon__c>([SELECT id, campagne__c FROM Codecoupon__c WHERE id IN :codeCouponIds]);
        }
        
        if (!chantierIds.isEmpty()) {
            chantiers = new Map<Id, Chantier__c>([SELECT id, libelleMagasinActuel__c, libelleDepotActuel__c, ville__c, proprietaire__c, autreProprietaire__c,  
                                                   locataire__c, autreLocataire__c, occupant__c, autreOccupant__c, villeProprietaires__c, nomProprietaires__c, 
                                                   prenomProprietaires__c, villeLocataires__c, nomLocataires__c, prenomLocataires__c, villeOccupants__c, 
                                                   nomOccupants__c, prenomOccupants__c FROM Chantier__c WHERE id IN : chantierIds]);       
        }
        
        /** B - Application des règles de mise à jour **/
        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunities == null ? null : oldOpportunities.get(newOpportunity.id);
            Chantier__c chantier = chantiers.get(newOpportunity.chantier__c);
            System.debug('## chantier:'+chantier);
            /* UR001_K2_Opportunity_Owner = Affectation du propriétaire
                # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur un utilisateur */
            newOpportunity.owner__c = newOpportunity.ownerId;
            
            /* UR001_K2_Opportunity_LastModifyByCall = Dernière modification par call
            UR001_K2_Opportunity_LastModifyBySale = Dernière modification par vente
            # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur un utilisateur */
            if (userContext != null && userContext.isCallUser()) {
                newOpportunity.lastModifiedByCall__c = userContext.getUser().id;
            }
            if (userContext != null && userContext.isSaleUser()) {
                newOpportunity.lastModifiedBySale__c = userContext.getUser().id;
            }
            
            /* UR001_K2_Opportunity_AccountSource
            # Conversion via mapping impossible avec les workflows */
            if (newOpportunity.leadSource == null && newOpportunity.callSource__c != null)
                newOpportunity.leadSource = MappingUtils.getOrigineVenteFromCall(newOpportunity.callSource__c);
            
            /* UR001_K2_Opportunity_1ereSource & UR001_K2_Opportunity_1ereSourceCall
            # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur une valeur spécifique */
            if (newOpportunity.premiereSource__c == null && newOpportunity.leadSource != null) {
                newOpportunity.premiereSource__c = newOpportunity.leadSource;
            }
            if (newOpportunity.premiereSourceCall__c == null && newOpportunity.callSource__c != null) {
                newOpportunity.premiereSourceCall__c = newOpportunity.callSource__c;
            }
            if (oldOpportunity != null && newOpportunity.leadSource != oldOpportunity.leadSource) {
                newOpportunity.nbSources__c = (newOpportunity.nbSources__c == null ? 0 : newOpportunity.nbSources__c) + 1;
            }
            if (oldOpportunity != null && newOpportunity.callSource__c != oldOpportunity.callSource__c) {
                newOpportunity.nbSourcesCall__c = (newOpportunity.nbSourcesCall__c == null ? 0 : newOpportunity.nbSourcesCall__c) + 1;
            }
            
            /* UR001_K2_Opportunity_PriceBook */
            if (newOpportunity.PriceBook2Id == null) {
                newOpportunity.PriceBook2Id = Label.system_id_pricebookentry_standard;
            }
            
            /* UR001_K2_Opportunity_Campaign */
            if (newOpportunity.codeCoupon__c != null && newOpportunity.campaignId == null) {
                newOpportunity.campaignId = codeCoupons.get(newOpportunity.codeCoupon__c).id;
            }
            
            /* UR001_K2_Opportunity_Magasin & UR001_K2_Opportunity_Depot
            # Impossible car Salesforce ne permet pas plus de 10 relations
            sinon magasin = chantier__r.libelleMagasinActuel_c & depot = chantier__r.libelleDepotActuel_c*/
            if (chantier != null) {
                newOpportunity.magasin__c = chantier.libelleMagasinActuel__c;
                newOpportunity.depot__c = chantier.libelleDepotActuel__c;

                // Défini le nom du projet à la création seulement 
                // Si projet créé automatiquement par SAV, alors SAV _ {YYYY] {MMM} _ {compte} _ {ville} _ {type relation chantier}
                // Si projet créé automatiquement suite avenant, alors AVT _ {YYYY] {MMM} _ {compte} _ {ville} _ {type relation chantier}
                if(Trigger.isInsert) {
                    String typeAccount;
                    String villeAccount;
                    String prenomAccount;
                    String nomAccount;
                    String monthValue = getMonthValue(Date.today().month());
                    String type = '';
                    //Type 
                    if(newOpportunity.Type == 'SAV') {
                        type = 'SAV';
                    } else if (newOpportunity.Type == 'Avenant') {
                        type = 'AVT';
                    } else {
                        type = 'PRJ';
                    } 
                    // Autre variables
                    if(newOpportunity.AccountId == chantier.proprietaire__c) {
                        typeAccount = 'Propriétaire';
                        villeAccount = chantier.villeProprietaires__c;
                        nomAccount = chantier.nomProprietaires__c;
                        prenomAccount = chantier.prenomProprietaires__c;
                    } else if(newOpportunity.AccountId == chantier.autreProprietaire__c) {
                        typeAccount = 'Autre propriétaire';
                        villeAccount = chantier.villeProprietaires__c;
                        nomAccount = chantier.nomProprietaires__c;
                        prenomAccount = chantier.prenomProprietaires__c;
                    } else if(newOpportunity.AccountId == chantier.locataire__c) {
                        typeAccount = 'Locataire';
                        villeAccount = chantier.villeLocataires__c;
                        nomAccount = chantier.nomLocataires__c;
                        prenomAccount = chantier.prenomLocataires__c;
                    } else if(newOpportunity.AccountId == chantier.autreLocataire__c) {
                        typeAccount = 'Autre locataire';
                        villeAccount = chantier.villeLocataires__c;
                        nomAccount = chantier.nomLocataires__c;
                        prenomAccount = chantier.prenomLocataires__c;
                    } else if(newOpportunity.AccountId == chantier.occupant__c) {
                        typeAccount = 'Occupant';
                        villeAccount = chantier.villeOccupants__c;
                        nomAccount = chantier.nomOccupants__c;
                        prenomAccount = chantier.prenomOccupants__c;
                    } else if(newOpportunity.AccountId == chantier.autreOccupant__c) {
                        typeAccount = 'Autre occupant';
                        villeAccount = chantier.villeOccupants__c;
                        nomAccount = chantier.nomOccupants__c;
                        prenomAccount = chantier.prenomOccupants__c;
                    }
                    System.debug('#typeAccount:'+typeAccount);
                    if(type != 'PRJ') {
                        String oppName = type+' _ '+Date.today().year()+' '+monthValue+' _ '+prenomAccount+' '+nomAccount+' _ '+villeAccount+' _ '+typeAccount;
                        if(oppName.length() >= 120){
                            oppName = oppName.substring(0, 120); // Limite a 120 caractères (taille max du champ Name)
                        }
                        newOpportunity.Name = oppName;
                        System.debug('## Nom projet: ' + newOpportunity.Name);  
                    }
                }
            }
            
            if (Trigger.isUpdate && oldOpportunity != null && String.isNotBlank(newOpportunity.GCLID__c) && newOpportunity.StageName == 'RDV' 
                && newOpportunity.dateEnvoiAdwords__c == null) 
            { 
                System.debug('## Adwords Opp Id: ' + newOpportunity.Id);  
                newOpportunity.dateEnvoiAdwords__c = Date.today();
            }
            
            System.debug('## new Opp dateRdv: '+newOpportunity.dateDernierRDV__c +' - rappel : '+ newOpportunity.rappelProduitsQuantites__c +' - objection: '+ newOpportunity.objectionPrincipale__c);
            /* Mise à jour des indicateurs de débriefing */
            if /* Détection du contexte */
                (String.isNotBlank(newOpportunity.couplePresent__c)          &&  
                 String.isNotBlank(newOpportunity.rappelProduitsQuantites__c) && 
                 newOpportunity.mntPremiereProposition__c != null          && 
                 newOpportunity.mntDernierPrixLaisse__c != null            && 
                 newOpportunity.pctECV__c != null                          && 
                 newOpportunity.pctRemise__c != null                       && 
                 newOpportunity.tarif__c != null                           && 
                 newOpportunity.objectionPrincipale__c != null             && 
                 String.isNotBlank(newOpportunity.objectionPrincipale__c)     &&
                 /* Détecttion de la saisie du débrief */          
                 (oldOpportunity == null                                                                 ||
                  newOpportunity.couplePresent__c != oldOpportunity.couplePresent__c                     ||
                  newOpportunity.rappelProduitsQuantites__c != oldOpportunity.rappelProduitsQuantites__c || 
                  newOpportunity.mntPremiereProposition__c != oldOpportunity.mntPremiereProposition__c   || 
                  newOpportunity.mntDernierPrixLaisse__c != oldOpportunity.mntDernierPrixLaisse__c       || 
                  newOpportunity.pctECV__c != oldOpportunity.pctECV__c                                   ||
                  newOpportunity.pctRemise__c != oldOpportunity.pctRemise__c                             ||
                  newOpportunity.tarif__c != oldOpportunity.tarif__c                                     || 
                  newOpportunity.objectionPrincipale__c != oldOpportunity.objectionPrincipale__c)) 
            {   
                newOpportunity.dateDebriefing__c = System.now();
                System.debug('## dateDebriefing__c: '+newOpportunity.dateDebriefing__c);
                if(newOpportunity.dateDernierRDV__c != null) {
                    newOpportunity.delaiDebriefing__c = newOpportunity.dateDernierRDV__c.date().daysBetween(newOpportunity.dateDebriefing__c.date());
                } else if(newOpportunity.CreatedDate != null) {
                    newOpportunity.delaiDebriefing__c = newOpportunity.CreatedDate.date().daysBetween(newOpportunity.dateDebriefing__c.date());
                }
                System.debug('## delaiDebriefing__c: '+newOpportunity.delaiDebriefing__c);
            } else {
                newOpportunity.dateDebriefing__c = null; // Actuellement non débriefé, donc initialisation de la date à NULL pour écraser la valeur précédente si elle existait
                newOpportunity.delaiDebriefing__c = null;
            }
        }
        System.debug('### FIN TR020_Opportunity : applyDataUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les projets
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Opportunity : applyStatusUpdateRules');
        
        // A - Initialisation des données intermédiaires
        List<Opportunity> newOpportunities = (List<Opportunity>)Trigger.new;
        
        // B - Application des règles de mise à jour
        for (Opportunity newOpportunity : newOpportunities) {
            System.debug('## Opp Id: '+newOpportunity.Id);
            // UR001_K2_Opportunity_StageName = Calcul de l'étape de l'opportunité
            Double nbDevisTransmis              = newOpportunity.nbDevisTransmis__c == null ? 0 : newOpportunity.nbDevisTransmis__c;
            Double nbDevisVendusEnAttente       = newOpportunity.nbDevisVendusEnAttente__c == null ? 0 : newOpportunity.nbDevisVendusEnAttente__c;
            Double nbDevisVendusEnregistres     = newOpportunity.nbDevisVendusEnregistres__c == null ? 0 : newOpportunity.nbDevisVendusEnregistres__c;
            Double nbDevisVendusIncontournables = newOpportunity.nbDevisVendusIncontournables__c == null ? 0 : newOpportunity.nbDevisVendusIncontournables__c;
            Double nbDevisCPQVendus             = newOpportunity.initialQuoteCPQCount__c == null ? 0 : newOpportunity.initialQuoteCPQCount__c; 
            Double nbTotalDevis                 = newOpportunity.nbTotalDevis__c == null ? 0 : newOpportunity.nbTotalDevis__c;
            Double nbTotalDevisCPQ              = newOpportunity.quoteCPQCount__c == null ? 0 : newOpportunity.quoteCPQCount__c;
            Double nbTotalRDV                   = newOpportunity.nbTotalRDV__c == null ? 0 : newOpportunity.nbTotalRDV__c;
            Double nbContratsVendus             = newOpportunity.nbContratsVendus__c == null ? 0 : newOpportunity.nbContratsVendus__c;
            Double nbContratsResilies           = newOpportunity.nbContratsResilies__c == null ? 0 : newOpportunity.nbContratsResilies__c;
            
            if (newOpportunity.forcageEtape__c != null) {
                newOpportunity.stageName = newOpportunity.forcageEtape__c;
            } else if ((nbDevisVendusEnAttente + nbDevisVendusEnregistres + nbDevisVendusIncontournables + nbContratsVendus  + nbContratsResilies + nbDevisCPQVendus) > 0) {
                newOpportunity.stageName = 'Vendu';
            } else if ('Concurrence'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Prix'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Produit'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Relationnel'.equalsIgnoreCase(newOpportunity.motifRefusReport__c)) {
                newOpportunity.stageName = 'Refus';
            } else if ('Budget'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Maturité du projet'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Non prioritaire'.equalsIgnoreCase(newOpportunity.motifRefusReport__c) || 'Autre'.equalsIgnoreCase(newOpportunity.motifRefusReport__c)) {
                newOpportunity.stageName = 'Reporté';
            } else if (nbDevisTransmis > 0) {
                newOpportunity.stageName = 'Devis envoyé';
            } else if (nbTotalDevis > 0 || nbTotalDevisCPQ > 0) {
                newOpportunity.stageName = 'Devis';
            } else if (nbTotalRDV > 0) {
                newOpportunity.stageName = 'RDV';
            } else {
                newOpportunity.stageName = 'Analyse';
            }
            System.debug('## Opp StageName: '+newOpportunity.StageName);
        }
        System.debug('### FIN TR020_Opportunity : applyStatusUpdateRules');
    }
  
    /**
    * @description Retourne les 3 premières lettres du mois en cours (sauf juin et juillet)
    * @param month Numéro du mois en cours
    * @return String Préfixe du mois
    */
    private static String getMonthValue(Integer month) {
        String monthStr;
        switch on month {
            when 1 { monthStr = 'JAN';}
            when 2 { monthStr = 'FEV'; }
            when 3 { monthStr = 'MAR'; }
            when 4 { monthStr = 'AVR'; }
            when 5 { monthStr = 'MAI'; }
            when 6 { monthStr = 'JUIN'; }
            when 7 { monthStr = 'JUIL'; }
            when 8 { monthStr = 'AOU'; }
            when 9 { monthStr = 'SEP'; }
            when 10 { monthStr = 'OCT'; }
            when 11 { monthStr = 'NOV'; }
            when 12 { monthStr = 'DEC'; }
            when else { monthStr = 'N/A'; }
        }
        return monthStr;
    }
}