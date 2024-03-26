//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_SBQQ_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 01/12/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_SBQQ_Quote {
    private static final String RT_SALES_QUOTE = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SALES_RT);
    private static final String RT_SAV_QUOTE = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SAV_RT);

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_SBQQ_Quote : applyUpdateRules');
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldQuotes = (Map<Id, SBQQ__Quote__c>)Trigger.oldMap;
        List<SBQQ__Quote__c> updatedCEEQuoteList = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        List<String> financingMethodIds = new List<String>();
        Date dateDevisMin = Date.today();
        Date dateDevisMax = dateDevisMin.addDays(-100000);
        List<Decimal> nbPersonneDevisList = new List<Decimal>();
        List<String> zoneGeographiqueDevisList = new List<String>();
        Map<String,Decimal> montantCEEList = new Map<String,Decimal>();
        List<String> accountListIds = new List<String>();
        List<String> opportunityListIds = new List<String>();
        List<String> quoteDelayList = new List<String>();
        Map<String, Account> accountsMap = new Map<String, Account>();
        Map<String,Referencial__c> referencialMap = new Map<String,Referencial__c>();
        Map<String,List<SBQQ__QuoteLine__c>> qliMap = new Map<String,List<SBQQ__QuoteLine__c>>();
        Map<String, Opportunity> opportunitiesMap = new Map<String, Opportunity>();
        List<SBQQ__Quote__Share> shareToInsert = new List<SBQQ__Quote__Share>();
        Map<String, Decimal> minCommercialDelayMap = new Map<String, Decimal>();
        Map<String, Decimal> maxCommercialDelayMap = new Map<String, Decimal>();

        // A - Initialisation des données intermédiaires 
        for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>)Trigger.new) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);
            newQuotes.add(newQuote);
                
            // Récupération référentiel
            if((Trigger.isInsert 
                || (Trigger.isUpdate && oldQuote != null && newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE
                    && (
                        (oldQuote.financingMethod__c != newQuote.financingMethod__c) 
                        || (oldQuote.totalAmount__c != newQuote.totalAmount__c)
                        )
                    )
                ) 
                && String.isNotBlank(newQuote.financingMethod__c)) 
            {
                financingMethodIds.add(newQuote.financingMethod__c);
            }

            // Ajout du recalcul des informations CEE
            if (Trigger.isBefore && (Trigger.isInsert && newQuote.RevenusFiscaux__c != null && newQuote.NombrePersonnes__c != null)
                    || ((oldQuote != null && newQuote.RevenusFiscaux__c != oldQuote.RevenusFiscaux__c) || 
                    (oldQuote != null && newQuote.NombrePersonnes__c != oldQuote.NombrePersonnes__c) || 
                    (oldQuote != null && newQuote.SBQQ__ShippingPostalCode__c != oldQuote.SBQQ__ShippingPostalCode__c) || 
                    (oldQuote != null && newQuote.referenceDate__c != oldQuote.referenceDate__c))) {
                updatedCEEQuoteList.add(newQuote);
                nbPersonneDevisList.add(newQuote.NombrePersonnes__c);
                zoneGeographiqueDevisList.add(newQuote.Zone__c);
                if(newQuote.referenceDate__c < dateDevisMin) {
                    dateDevisMin = newQuote.referenceDate__c;
                }
                if(newQuote.referenceDate__c > dateDevisMax) {
                    dateDevisMax = newQuote.referenceDate__c;
                }
            }
            
            // Si nouveau devis, on recupere les informations pour champs adresses
            if(Trigger.isBefore && Trigger.isInsert && String.isNotBlank(newQuote.SBQQ__Account__c) && String.isNotBlank(newQuote.SBQQ__Opportunity2__c) ) 
            {
                accountListIds.add(newQuote.SBQQ__Account__c);
                opportunityListIds.add(newQuote.SBQQ__Opportunity2__c);
            }

            // Récupération délais
            if (Trigger.isBefore && newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE 
                && String.isNotBlank(newQuote.Id)) 
            {
                quoteDelayList.add(newQuote.Id);
            }
        }
       
        // B - Récupération données intermédiaire 
        // Récupération référentiel
        if (!financingMethodIds.isEmpty()) {
            for (Referencial__c ref : [SELECT Id, Name, advancePayment1__c, advancePayment2__c FROM Referencial__c WHERE Id IN :financingMethodIds]) {
                referencialMap.put(ref.Id, ref);
            }
        }
        // Récupération compte
        if (!accountListIds.isEmpty()) {
            accountsMap = new Map<String, Account>([SELECT Id, IsPersonAccount, Name, civilite__c, nom__c, prenom__c, rue__c, ville__c, codePostal__c, pays__c, 
                                                            complementAdresse__c, departement__c FROM Account WHERE Id IN :accountListIds]);
        }
        // Récupération projet/chantier
        if (!opportunityListIds.isEmpty()) {
            opportunitiesMap = new Map<String, Opportunity>([SELECT Id, chantier__r.civiliteProprietaires__c, chantier__r.nomProprietaires__c, chantier__r.prenomProprietaires__c, 
                                                                chantier__r.rue__c, chantier__r.ville__c, chantier__r.codePostal__c, chantier__r.pays__c, 
                                                                chantier__r.complementAdresse__c, chantier__r.departement__c FROM Opportunity WHERE Id IN :opportunityListIds]);
        }
        
        // Récupération des délais enfants
        if(!quoteDelayList.isEmpty()) {
            for (AggregateResult ar : [SELECT SBQQ__Quote__c,
                                MAX(minCommercialDelay__c) minDelay, MAX(maxCommercialDelay__c) maxDelay
                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteDelayList GROUP BY SBQQ__Quote__c]) {
                String quoteId = String.valueOf(ar.get('SBQQ__Quote__c'));
                Decimal minCommercialDelay = (Decimal)ar.get('minDelay');
                Decimal maxCommercialDelay = (Decimal)ar.get('maxDelay');
                minCommercialDelayMap.put(quoteId, minCommercialDelay);
                maxCommercialDelayMap.put(quoteId, maxCommercialDelay);
            }
        }
        System.debug('## minCommercialDelayMap: ' + minCommercialDelayMap);
        System.debug('## maxCommercialDelayMap: ' + maxCommercialDelayMap);

        //* C - Application des règles de mise à jour 
        for (SBQQ__Quote__c newQuote : newQuotes) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);
            
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
                System.debug('## Quote: ' + newQuote.Id);
                System.debug('## Quote Status: ' + newQuote.SBQQ__Status__c);
                System.debug('## Quote Chantier: ' + newQuote.chantier__c);
                System.debug('## Quote Distance (km) : ' + newQuote.chantier__r.serviceEntityDistance__c);
                
                // Mise à jour du propriétaire du devis initial (Doit être fait en APEX car pas faisable par Price Rules)
                if(Trigger.isInsert && String.isBlank(newQuote.initialQuoteOwner__c)) {
                    newQuote.initialQuoteOwner__c = newQuote.initialQuoteOwnerId__c;
                }

                if(newQuote.SBQQ__Status__c == 'Vendu' && newQuote.AmendmentQuote__c == true && newQuote.SBQQ__Primary__c == false) {
                    newQuote.TECHTrigger1__c = System.now() + (61/1440);
                }
                
                // MAJ de date d'expiration MIN(date devis + 14 jours, date de fin de validité produits ou options)
                if((Trigger.isInsert || Trigger.isUpdate && oldQuote.dateDevis__c != newQuote.dateDevis__c ) && newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE /*&& newQuote.AmendmentQuote__c == false*/) {
                    System.debug('## Update Expiration Date');
                    Date dateExpTemp = newQuote.dateDevis__c.addDays(14);
                    System.debug('## Quote Date: ' + newQuote.dateDevis__c);
                    System.debug('## DateValiditeLaPlusProche__c: ' + newQuote.DateValiditeLaPlusProche__c);
                    if(newQuote.DateValiditeLaPlusProche__c != null && newQuote.DateValiditeLaPlusProche__c < dateExpTemp && newQuote.DateValiditeLaPlusProche__c >= newQuote.dateDevis__c) {
                        newQuote.SBQQ__ExpirationDate__c = newQuote.DateValiditeLaPlusProche__c;
                    } else {
                        newQuote.SBQQ__ExpirationDate__c = dateExpTemp;
                    }
                    System.debug('## Expiration Date: ' + newQuote.SBQQ__ExpirationDate__c);
                        
                    newQuote.ComputedExpirationDate__c = newQuote.SBQQ__ExpirationDate__c;

                }
                // Date d'expiration à null lors création avenant
                if(Trigger.isInsert && newQuote.AmendmentQuote__c) {
                    //newQuote.SBQQ__ExpirationDate__c = null;
                }

                // Mise à jour du montant TVA pour pallier aux décalages des price rules
                /*if(Trigger.isUpdate && newQuote.MontantTVA__c != null && newQuote.MontantTVA__c != 0 && 
                    ((newQuote.MontantTVA__c - 0.1 > newQuote.VATAmountDisplay__c) || (newQuote.MontantTVA__c + 0.1 < newQuote.VATAmountDisplay__c))) {
                    if(newQuote.MontantTVAReduite__c != null && newQuote.MontantTVAReduite__c != 0 && newQuote.MontantTVAIntermediaire__c == 0 && newQuote.MontantTVAFort__c== 0 ){
                        newQuote.MontantTVAReduite__c = newQuote.MontantTVA__c;
                    } else if(newQuote.MontantTVAIntermediaire__c != null && newQuote.MontantTVAIntermediaire__c != 0 && newQuote.MontantTVAReduite__c == 0 && newQuote.MontantTVAFort__c== 0){
                        newQuote.MontantTVAIntermediaire__c = newQuote.MontantTVA__c;
                    } else if(newQuote.MontantTVAFort__c != null && newQuote.MontantTVAFort__c != 0 && newQuote.MontantTVAReduite__c == 0 && newQuote.MontantTVAIntermediaire__c== 0){
                        newQuote.MontantTVAFort__c = newQuote.MontantTVA__c;
                    }
                }*/

                // Insertion date de référence sur devis non avenant à l'init
                if(Trigger.isInsert && newQuote.AmendmentQuote__c == false) {
                    newQuote.referenceDate__c = newQuote.dateDevis__c;
                }                
                // Modification date de référence par rapport à la date du devis pour les devis non avenant et non cloné
                if(Trigger.isUpdate && oldQuote != null && newQuote.dateDevis__c != oldQuote.dateDevis__c 
                    && newQuote.AmendmentQuote__c == false && String.isBlank(newQuote.SBQQ__Source__c)) 
                {
                    newQuote.referenceDate__c = newQuote.dateDevis__c;
                } else if(Trigger.isUpdate && oldQuote != null && newQuote.referenceDate__c != oldQuote.referenceDate__c 
                    && newQuote.AmendmentQuote__c == false && String.isBlank(newQuote.SBQQ__Source__c)) 
                {
                    newQuote.dateDevis__c = newQuote.referenceDate__c;
                }                
                               
                // Mise à jour champ "Calcul nécessaire" si des champs ont été modifiés
                if(Trigger.isUpdate && oldQuote != null && newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE 
                    && ( newQuote.dateDevis__c != oldQuote.dateDevis__c || newQuote.OwnerId != oldQuote.OwnerId 
                        || newQuote.sourceRef__c != oldQuote.sourceRef__c || newQuote.typeDeTaux__c != oldQuote.typeDeTaux__c
                        || newQuote.operation__c != oldQuote.operation__c || newQuote.referenceDate__c != oldQuote.referenceDate__c ) 
                ) {
                    System.debug('## Update calculationNeeded__c');
                    newQuote.calculationNeeded__c = true;
                } 

                // Alimentation des champs adresses          
                if(Trigger.isInsert && opportunitiesMap.get(newQuote.SBQQ__Opportunity2__c) != null) {
                    Opportunity opp = opportunitiesMap.get(newQuote.SBQQ__Opportunity2__c);
                    System.debug('## Update Shipping Address');
                    system.debug('## Opportunity: '+opp);
                    System.debug('## Opportunity civiliteProprietaires__c: '+opp.chantier__r.civiliteProprietaires__c);
                    System.debug('## Opportunity prenomProprietaires__c: '+opp.chantier__r.prenomProprietaires__c);
                    System.debug('## Opportunity nomProprietaires__c: '+opp.chantier__r.nomProprietaires__c);
                            
                    newQuote.SBQQ__ShippingName__c = (opp.chantier__r.civiliteProprietaires__c != null ? opp.chantier__r.civiliteProprietaires__c + ' ' : '') +
                                                    (opp.chantier__r.prenomProprietaires__c != null ? opp.chantier__r.prenomProprietaires__c + ' ' : '') +
                                                    (opp.chantier__r.nomProprietaires__c != null ? opp.chantier__r.nomProprietaires__c : '');
                    //newQuote.SBQQ__ShippingName__c = opp.chantier__r.civiliteProprietaires__c?+' '+opp.chantier__r.prenomProprietaires__c+' '+opp.chantier__r.nomProprietaires__c;
                    newQuote.SBQQ__ShippingStreet__c = opp.chantier__r.rue__c; 
                    newQuote.SBQQ__ShippingCity__c = opp.chantier__r.ville__c;
                    newQuote.SBQQ__ShippingPostalCode__c = opp.chantier__r.codePostal__c; 
                    newQuote.SBQQ__ShippingCountry__c = opp.chantier__r.pays__c;
                    newQuote.shippingAdditionalAddress__c = opp.chantier__r.complementAdresse__c;
                    newQuote.SBQQ__ShippingState__c = opp.chantier__r.departement__c;
                }
                if(Trigger.isInsert && Trigger.isBefore && accountsMap.get(newQuote.SBQQ__Account__c) != null) {
                    Account acc = accountsMap.get(newQuote.SBQQ__Account__c);
                    System.debug('## Update Billing Address');  
                    system.debug('## Account: '+acc);   
                    system.debug('## Account civilite__c: '+acc.civilite__c);
                    system.debug('## Account prenom__c: '+acc.prenom__c);
                    system.debug('## Account nom__c: '+acc.nom__c); 
                    newQuote.SBQQ__BillingName__c = (acc.civilite__c != null ? acc.civilite__c + ' ' : '') +
                                                    (acc.prenom__c != null ? acc.prenom__c + ' ' : '') +
                                                    (acc.nom__c != null ? acc.nom__c : '');

                    //newQuote.SBQQ__BillingName__c = acc.civilite__c +' '+acc.prenom__c+' '+acc.nom__c;
                    newQuote.SBQQ__BillingStreet__c = acc.rue__c; 
                    newQuote.SBQQ__BillingCity__c = acc.ville__c;
                    newQuote.SBQQ__BillingPostalCode__c = acc.codePostal__c; 
                    newQuote.SBQQ__BillingCountry__c = acc.pays__c;
                    newQuote.billingAdditionalAddress__c = acc.complementAdresse__c;
                    newQuote.SBQQ__BillingState__c = acc.departement__c;
                }
            }

            // Insertion partage avec propriétaire devis initial si avenant
            if(Trigger.isAfter && Trigger.isInsert) {
                if(Trigger.isAfter && Trigger.isInsert && newQuote.AmendmentQuote__c && newQuote.ownerIsDifferent__c && newQuote.initialQuoteOwnerActive__c) {
                    System.debug('## Création partage avenant: '+newQuote.Id+' / User: '+newQuote.initialQuoteOwnerId__c);
                    SBQQ__Quote__Share quoteSharing  = new SBQQ__Quote__Share();
                    quoteSharing.ParentId = newQuote.Id;
                    quoteSharing.UserOrGroupId = newQuote.initialQuoteOwner__c;
                    quoteSharing.AccessLevel = 'Edit';
                    quoteSharing.RowCause = Schema.SBQQ__Quote__Share.RowCause.InitialQuoteOwner__c;
                    shareToInsert.add(quoteSharing);
                }
            }
            
            // Alimentation des acompte n°1 et 2 
            // Récupération du référentiel mode de financement
            Referencial__c modeFinancement = referencialMap.get(newQuote.financingMethod__c);
            if (newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE && oldQuote != null 
                    && String.isNotBlank(newQuote.financingMethod__c) && modeFinancement != null
                    && (newQuote.MontantAcompteAttendu__c == null || newQuote.totalAmount__c != oldQuote.totalAmount__c ) 
                    && newQuote.totalAmount__c != null /*&& modeFinancement.Name == Constants.QUOTE_PAIEMENT_COMPTANT*/
                    && newQuote.SBQQ__Type__c != 'SAV') 
            {
                // Récupération de l'acompte1 du référentiel
                if(modeFinancement.advancePayment1__c != null) {
                    System.debug('## Update Advance Payment 1');
                    newQuote.montantAcompteAttendu__c = (newQuote.totalAmount__c != null) ? 
                                                        (newQuote.totalAmount__c * modeFinancement.advancePayment1__c) / 100 : 
                                                        null;
                    System.debug('## Advance Payment 1: '+newQuote.montantAcompteAttendu__c);
                }
                // S'il l'acompte 2 on alimente les données, sinon, il est vidé
                if(modeFinancement.advancePayment2__c != null){
                    System.debug('## Update Advance Payment 2');
                    newQuote.montantAcompte2Attendu__c = (newQuote.totalAmount__c != null) ? 
                                                        (newQuote.totalAmount__c * modeFinancement.advancePayment2__c) / 100 : 
                                                        null;
                    System.debug('## Advance Payment 2: '+newQuote.montantAcompte2Attendu__c);
                } else {
                    newQuote.montantAcompte2Attendu__c = null;
                }
            } else if (newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE && oldQuote != null 
                    && String.isNotBlank(newQuote.financingMethod__c) && modeFinancement != null
                    && (newQuote.MontantAcompteAttendu__c == null || newQuote.totalAmount__c != oldQuote.totalAmount__c ) 
                    && newQuote.totalAmount__c != null /*&& modeFinancement.Name == Constants.QUOTE_PAIEMENT_COMPTANT*/
                    && newQuote.SBQQ__Type__c == 'SAV') 
            {
                // L'alimentation automatique de 100% du total si SAV
                System.debug('## Update Advance Payment 1');
                newQuote.montantAcompteAttendu__c = newQuote.totalAmount__c;
                System.debug('## Advance Payment 1: '+newQuote.montantAcompteAttendu__c);
                System.debug('## Update Advance Payment 2');
                newQuote.montantAcompte2Attendu__c = null;
                System.debug('## Advance Payment 2: '+newQuote.montantAcompte2Attendu__c);
            }
            
            // Alimentation des délais
            if (Trigger.isUpdate && newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE) {
                System.debug('## Update Commercial Delay');
                newQuote.minCommercialDelay__c = minCommercialDelayMap.get(newQuote.Id);
                newQuote.maxCommercialDelay__c = maxCommercialDelayMap.get(newQuote.Id);
                System.debug('## Min Commercial: '+newQuote.minCommercialDelay__c);
                System.debug('## Max Commercial: '+newQuote.maxCommercialDelay__c);
            }
        }

        // Mise à jour des informations CEE
        if (!updatedCEEQuoteList.isEmpty()){
            List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
            List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
            List<String> productIdList = new List<String>();
            List<String> tvaTypeList = new List<String>();
            List<mapping__c> mappingList = mapping__c.getall().values();
            List<SBQQ__QuoteLine__c> qliListCEE = new List<SBQQ__QuoteLine__c>();
            for (SBQQ__QuoteLine__c qli : qliList) {
                for(SBQQ__Quote__c q : updatedCEEQuoteList){
                    if(q.Id == qli.SBQQ__Quote__c){
                        qliListCEE.add(qli);
                        productIdList.add(qli.SBQQ__Product__c);
                    }
                }
            }
            // Récupération des catégories/primes CEE dans la base, et des lignes de devis
            tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                        FROM TVA_Produit__c
                        WHERE produit__c IN :productIdList];

            for(TVA_Produit__c tva : tvaList){
                tvaTypeList.add(tva.Type__c);
            }

            ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                        FROM ESCIncentive__c
                        WHERE type__c IN :tvaTypeList AND startDate__c < :dateDevisMax 
                                        AND (endDate__c > :dateDevisMin OR endDate__c = null)
                                        AND personNumber__c IN :nbPersonneDevisList
                                        AND geography__c IN :zoneGeographiqueDevisList];

            for (SBQQ__Quote__c quote : updatedCEEQuoteList) {
                // Recalcul de la zone
                if(String.isNotBlank( quote.SBQQ__ShippingPostalCode__c)) {
                    String codeDepartement = quote.SBQQ__ShippingPostalCode__c.substring(0,2);
                    for(Integer i=0;i<mappingList.size();i++){
                        if(mappingList[i].Repository__c == 'zone_climatique' && mappingList[i].PickValue__c == codeDepartement){
                            quote.Zone__c = mappingList[i].ConvertedValue__c;
                        }
                    }

                    // Recalcul des montants CEE
                    //Utils_CEE.setQuotePrimeCEE(qliListCEE, quote, ceeList);
                    Utils_CEE.setQuoteCEE(qliListCEE, quote, ceeList, tvaList);
                }                
            }
        }

        if(!shareToInsert.isEmpty() && !test.isRunningTest()) {
            insert shareToInsert;
        }
        System.debug('### FIN TR020_SBQQ_Quote : applyUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_SBQQ_Quote.applyStatusUpdateRules');
        
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldQuotes = (Map<Id, SBQQ__Quote__c>)Trigger.oldMap;
        Map<String, Referencial__c> referencialMap = new Map<String, Referencial__c>();
        Boolean getReferenceDatas = false;
        
        // A - Initialisation des données intermédiaires 
        for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>)Trigger.new) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);

            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {            
                newQuotes.add(newQuote);
            }
        }

        // B - Application des règles de mise à jour 
        if(!newQuotes.isEmpty()) {
            for (SBQQ__Quote__c newQuote : newQuotes) { 
                SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);

                if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {   
                    // Changement du statut
                    System.debug('## Change status for Quote: ' + newQuote.Id);
                    if (String.isNotBlank(newQuote.statusFixed__c)){
                        newQuote.SBQQ__Status__c = newQuote.statusFixed__c;
                    } else if (newQuote.dateAnnulation__c != null && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_SOLD) {
                        System.debug('## status 1');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_CANCELLED;
                    } else if(newQuote.dateAcceptationClient__c != null && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_CANCELLED) {
                        System.debug('## status 2');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;         
                        // Si devis non avenant, on génère directement la commande, sinon cela s'effectue par Flow
                        if(newQuote.AmendmentQuote__c == false) {               
                            newQuote.SBQQ__Primary__c = true;
                            newQuote.SBQQ__Ordered__c = true;
                            System.debug('## Create Order '+newQuote.Id);
                        }
                    } else if(newQuote.quoteIsValid__c == true && newQuote.dateTransmissionClient__c != null 
                                && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_CANCELLED) {
                        System.debug('## status 3');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
                        // Si devis non avenant, on le définit en principal
                        if(newQuote.AmendmentQuote__c == false) {               
                            newQuote.SBQQ__Primary__c = true;
                        }
                    } else if (newQuote.quoteIsValid__c == true && newQuote.dateTransmissionClient__c == null 
                                && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_CANCELLED) {
                        System.debug('## status 4');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
                    } else if(newQuote.approvalInProgress__c == true && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_CANCELLED 
                                && newQuote.SBQQ__Status__c != Constants.QUOTE_STATUS_SOLD) {                            
                        System.debug('## status 5');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_APPROVAL;
                    } else {
                        System.debug('## status 6');
                        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_TO_CONFIGURE;
                    }
                    System.debug('## Quote Status: '+newQuote.SBQQ__Status__c);
                    
                    //  Changement du RecordType
                    System.debug('## Change RT for Quote: ' + newQuote.Id);
                    if(newQuote.SBQQ__Type__c == 'SAV'){
                        newQuote.RecordTypeId = RT_SAV_QUOTE;
                    } else {
                        //Empecher la création d'un devis SAV en dehors du flux
                        if(Trigger.isInsert && newQuote.RecordTypeId != null && newQuote.RecordTypeId == RT_SAV_QUOTE){
                            newQuote.addError('Type de Devis invalide. Pour la création de devis SAV il est nécessaire d\'utiliser le bouton "Génération devis SAV", accessible depuis requête, commande, chantier et Dossier SAV');
                        }
                        newQuote.RecordTypeId = RT_SALES_QUOTE;
                    }
                    System.debug('## Quote RecordTypeId: '+newQuote.RecordTypeId);
                }
            }
        }
        System.debug('### FIN TR020_SBQQ_Quote.applyStatusUpdateRules');
    }
}