//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_KMDCEinstein 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/06/2022
//-- Version     : 1.0
//-- Description : Classe pour mettre à jour les objets KMDC et KFacture pour Einstein
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_KMDCEinstein implements Queueable {
    public String actionType;
    public List<String> recordsIdList;
    public Decimal totalAmountCustomerOrder;
    public Decimal pretaxAmountCustomerOrder;

    /**
    * @description Constructeur
    * @param actionRequise Type d'action
    * @param recordsList Liste des enregistrements
    * @return Contexte du job Queueable
    */
    public QA_KMDCEinstein(String actionType, List<SObject> recordsList, Decimal totalAmountCustomerOrder, Decimal pretaxAmountCustomerOrder) {
        this.recordsIdList = new List<String>();
        for(SObject obj : recordsList) {
            this.recordsIdList.add((String)obj.get('Id'));
        }
        this.actionType = actionType;
        this.totalAmountCustomerOrder = totalAmountCustomerOrder;
        this.pretaxAmountCustomerOrder = pretaxAmountCustomerOrder;
    }

    /**
    * @description Fonction principal d'exécution du job Queueable
    * Méthode asynchrone pour alimenter les objets KMDC ou KFacture lors de la création/MAJ d'un devis, d'une facture ou d'un avoir
    * @param context Context job Queueable
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_KMDCEinstein.execute()');    
        List<KFacture__c> kFactureToUps = new List<KFacture__c>(); 
        List<KMDC__c> kMDCToUps = new List<KMDC__c>(); 
        Integer successCount = 0;   
        System.debug('## actionType: '+actionType);    
        System.debug('## recordsIdList: '+recordsIdList); 
        System.debug('## totalAmountCustomerOrder: '+totalAmountCustomerOrder); 
        System.debug('## pretaxAmountCustomerOrder: '+pretaxAmountCustomerOrder); 

        try {
            // Récupération des entités
            Map<String, Account> entityHierarchieMap = getEntityHierarchy();

            // Alimentation KFacture pour les factures
            if(actionType == 'Invoice') {
                for(Invoice__c invoice : [SELECT Id, invoiceReference__c, customerOrder__r.OrderNumber, seller__r.KparKReference__c, 
                                            Name, invoiceDate__c, pretaxAmount__c, amount__c, seller__r.Name, seller__c
                                            FROM Invoice__c WHERE Id IN :recordsIdList 
                                                AND legacyReference__c = null 
                                                AND invoiceReference__c != null
                                                AND customerOrder__r.Type != 'Commande SAV']) 
                {
                    Map<String, String> kFacturesMap = new Map<String, String>();
                    
                    // Récupération KMDC existant
                    for(KFacture__c kfac : [SELECT Id, codeFacture__c FROM KFacture__c WHERE codeFacture__c = :invoice.invoiceReference__c]) {
                        kFacturesMap.put(kfac.codeFacture__c, kfac.Id);
                    }

                    KFacture__c obj = new KFacture__c(
                        codeContrat__c = invoice.customerOrder__r.OrderNumber,
                        codeDepot__c = invoice.seller__r.KparKReference__c,
                        codeFacture__c = invoice.invoiceReference__c,
                        dateFacture__c = invoice.invoiceDate__c,
                        MontantHT__c = invoice.pretaxAmount__c,
                        MontantTTC__c = invoice.amount__c,
                        nomDepot__c = invoice.seller__r.Name,
                        typeFacture__c = true
                    );
                    // Lien avec KMDC existant                            
                    if(kFacturesMap != null && kFacturesMap.get(invoice.invoiceReference__c) != null) {
                        obj.Id = kFacturesMap.get(invoice.invoiceReference__c);
                    }
                    // Récupération entité DS
                    Account invoiceDS = calculateParentEntityByType(invoice.seller__c, 'DS', entityHierarchieMap);
                    if(invoiceDS != null) {obj.codeDS__c = invoiceDS.KparKReference__c;obj.nomDS__c = invoiceDS.Name;}
                    // Récupération entité DR
                    Account invoiceDR = calculateParentEntityByType(invoice.seller__c, 'DR', entityHierarchieMap);
                    if(invoiceDR != null) {obj.codeDR__c = invoiceDR.KparKReference__c;obj.nomDR__c = invoiceDR.Name;}
                    System.debug('## KFacture Invoice: '+obj); 
                    kFactureToUps.add(obj);
                }
            }

            // Alimentation KFacture pour les avoirs
            if(actionType == 'CreditMemo') {
                for(CreditMemo__c crediMemo : [SELECT Id, customerOrder__r.OrderNumber, creditMemoReference__c, creditMemoDate__c, 
                                                pretaxAmount__c, amount__c, seller__r.KparKReference__c, seller__r.Name, seller__c
                                            FROM CreditMemo__c WHERE Id IN :recordsIdList 
                                                AND legacyReference__c = null 
                                                AND creditMemoReference__c != null
                                                AND customerOrder__r.Type != 'Commande SAV']) 
                {
                    Map<String, String> kFacturesMap = new Map<String, String>();
                    // Récupération KMDC existant
                    for(KFacture__c kfac : [SELECT Id, codeFacture__c FROM KFacture__c WHERE codeFacture__c = :crediMemo.creditMemoReference__c]) {
                        kFacturesMap.put(kfac.codeFacture__c, kfac.Id);
                    }
                    KFacture__c obj = new KFacture__c(
                        codeContrat__c = crediMemo.customerOrder__r.OrderNumber,
                        codeDepot__c = crediMemo.seller__r.KparKReference__c,
                        codeFacture__c = crediMemo.creditMemoReference__c,
                        dateFacture__c = crediMemo.creditMemoDate__c,
                        MontantHT__c = crediMemo.pretaxAmount__c,
                        MontantTTC__c = crediMemo.amount__c,
                        nomDepot__c = crediMemo.seller__r.Name,
                        typeFacture__c = false
                    );
                    // Lien avec KMDC existant                            
                    if(kFacturesMap != null && kFacturesMap.get(crediMemo.creditMemoReference__c) != null) {
                        obj.Id = kFacturesMap.get(crediMemo.creditMemoReference__c);
                    }
                    // Récupération entité DS
                    Account crediMemoDS = calculateParentEntityByType(crediMemo.seller__c, 'DS', entityHierarchieMap);
                    if(crediMemoDS != null) {obj.codeDS__c = crediMemoDS.KparKReference__c;obj.nomDS__c = crediMemoDS.Name;
                    }
                    // Récupération entité DR
                    Account crediMemoDR = calculateParentEntityByType(crediMemo.seller__c, 'DR', entityHierarchieMap);
                    if(crediMemoDR != null) {obj.codeDR__c = crediMemoDR.KparKReference__c;obj.nomDR__c = crediMemoDR.Name;
                    }
                    System.debug('## KFacture CreditMemo: '+obj); 
                    kFactureToUps.add(obj);
                }
            }

            // Alimentation KMDC pour les devis/commandes
            if(actionType == 'Quote' || actionType == 'QuoteValidation' || actionType == 'QuoteAmendmentValidation') {
                Map<String, User> ownersMap = new Map<String, User>();
                Map<String, Order> ordersMapCPQ = new Map<String, Order>();                
                Map<String, Order> ordersMapSales = new Map<String, Order>();
                Map<String, Integer> kmdcsExistsMap = new Map<String, Integer>();
                List<String> ownersIdList = new List<String>();
                List<String> oppOwnersIdList = new List<String>();
                List<SBQQ__Quote__c> devisCPQList = new List<SBQQ__Quote__c>();
                List<SBQQ__Quote__c> devisAvenantCPQList = new List<SBQQ__Quote__c>();
                
                List<Quote> devisSalesList = new List<Quote>();
                List<Quote> devisAvenantSalesList = new List<Quote>();
                Set<String> initialOrderIdList = new Set<String>();
                Set<String> ordNumberList = new Set<String>();

                // Récupération des commandes
                for(Order ord : [SELECT Id, OrderNumber, SBQQ__Quote__c, customerSignedDate__c, EffectiveDate, salesEntity__c, serviceEntity__c, Type,
                                    parentOrder__c, parentOrder__r.OrderNumber, QuoteId, activatedDate, cancellingDate__c, isValid__c, isReopen__c,
                                    firstDateStats__c, firstAssignedClosing__c, isLegacy__c, parentOrder__r.isLegacy__c, legacyReference__c, parentOrder__r.legacyReference__c, 
                                    Quote.dateAcceptationClient__c, SBQQ__Quote__r.dateAcceptationClient__c,
                                    chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c,
                                    chantier__r.telephoneDomicileProprietaires__c, chantier__r.telephoneMobileProprietaires__c,
                                    chantier__r.telephoneProprietaires__c, chantier__r.autreTelephoneProprietaires__c, pretaxAmount__c, amount__c,
                                    parentOrder__r.pretaxAmount__c, parentOrder__r.amount__c,
                                    (SELECT Id, CreatedDate, spilledCustomerOrder__c FROM AmendmentQuotes__r 
                                        WHERE amendmentQuote__c = true AND Status LIKE 'Vendu%'
                                        ORDER BY CreatedDate DESC ) 
                                FROM Order
                                WHERE Id IN :recordsIdList AND isValid__c = true
                                AND RecordTypeId = :DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER)
                                AND Type != 'Commande SAV']) 
                {
                    if(String.isNotBlank(ord.SBQQ__Quote__c)) {
                        ordersMapCPQ.put(ord.SBQQ__Quote__c, ord);
                    } else {
                        ordersMapSales.put(ord.QuoteId, ord);
                    }
                    // Récupération ID des commandes initiales
                    String initialOrderId = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__c : ord.Id; 
                    initialOrderIdList.add(initialOrderId);
                    // Récupération code commande pour récupérer les KMDC existant                    
                    String ordNumber = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__r.OrderNumber : ord.OrderNumber; 
                    ordNumberList.add(ordNumber);
                }
                System.debug('## initialOrderIdList: '+initialOrderIdList); 
                System.debug('## ordNumberList: '+ordNumberList); 
                System.debug('## ordersMapCPQ: '+ordersMapCPQ); 
                System.debug('## ordersMapSales: '+ordersMapSales);

                // Récupération devis CPQ
                if(!ordersMapCPQ.keySet().isEmpty()) {
                    // Récupération des devis CPQ
                    devisCPQList = [SELECT Id, NDevis__c, SBQQ__Primary__c, chantier__r.serviceEntity__r.KparKReference__c, amendmentQuote__c,
                                            OwnerId, ecartCotation__c, ecartCotationPercent__c, chantier__r.salesEntity__r.KparKReference__c, 
                                            pretaxTotalAmount__c, totalAmount__c, sourceTexte__c, financingMethod__r.KparKReference__c, financingMethod__r.Name, 
                                            chantier__r.serviceEntity__r.Name, chantier__r.salesEntity__r.Name, CircuitSignatureDevis__c,
                                            sourceRef__r.Name, amendInitialQuote__r.NDevis__c, VATAmountWithoutDiscount__c, previousQuote__r.totalAmount__c, 
                                            previousQuote__r.pretaxTotalAmount__c, previousQuote__r.VATAmountWithoutDiscount__c, OpportunityOwner__c,
                                            previousQuote__r.ecartCotation__c, previousQuote__r.ecartCotationPercent__c, customerOrder__r.Status, 
                                            customerOrder__r.isReopen__c, spilledCustomerOrder__r.Status, spilledCustomerOrder__r.isReopen__c, customerOrder__r.cancellingDate__c,
                                            spilledCustomerOrder__r.amount__c, spilledCustomerOrder__r.pretaxAmount__c,
                                            customerOrder__r.pretaxAmount__c, customerOrder__r.amount__c, spilledCustomerOrder__c, customerOrder__c
                                        FROM SBQQ__Quote__c 
                                        WHERE Id IN :ordersMapCPQ.keySet() 
                                        AND SBQQ__Status__c = 'Vendu'
                                        ORDER BY CreatedDate DESC];
                    // Récupération des devis avenant CPQ
                    devisAvenantCPQList = [SELECT Id, CreatedDate, spilledCustomerOrder__c, amendInitialQuote__r.customerOrder__c, 
                                                customerOrder__c, amendmentQuote__c, OpportunityOwner__c,
                                                previousQuote__r.totalAmount__c, previousQuote__r.pretaxTotalAmount__c, previousQuote__r.VATAmountWithoutDiscount__c,
                                                previousQuote__r.ecartCotation__c, previousQuote__r.ecartCotationPercent__c, spilledCustomerOrder__r.amount__c, spilledCustomerOrder__r.pretaxAmount__c,
                                                customerOrder__r.pretaxAmount__c, customerOrder__r.amount__c
                                            FROM SBQQ__Quote__c 
                                            WHERE amendmentQuote__c = true AND SBQQ__Status__c = 'Vendu'
                                            AND customerOrder__c IN :initialOrderIdList
                                            ORDER BY CreatedDate DESC];
                    
                    if(!devisCPQList.isEmpty()) {
                        // Récupération des infos Owner
                        for(SBQQ__Quote__c devis : devisCPQList) {
                            ownersIdList.add(devis.OwnerId);
                            oppOwnersIdList.add(devis.OpportunityOwner__c);
                        }
                        for(User usr : [SELECT Id, CodeDR__c, CodeDV__c, CodeMagasin__c, EmployeeNumber, LibelleDR__c, 
                                            LibelleDV__c, LibelleMagasin__c, Name, SGID__c FROM User WHERE Id IN :ownersIdList OR Id IN :oppOwnersIdList]) {
                            ownersMap.put(usr.Id.to15(), usr);
                        }
                    }
                }

                // Récupération devis Sales
                if(!ordersMapSales.keySet().isEmpty()) {
                    // Récupération des devis Sales
                    devisSalesList = [SELECT Id, numeroDevis__c, amendmentQuote__c, Opportunity.chantier__r.serviceEntity__r.KparKReference__c, Status,
                                            OwnerId, RemisevendeurglobaleDeviseFormule__c, RemisevendeurglobaleFormule__c, OpportunityOwner__c,
                                            Opportunity.chantier__r.salesEntity__r.KparKReference__c, TotalHTTarif__c, TotalHTDevis__c, Total_TTC_devis__c, 
                                            modeFinancement__c, Opportunity.chantier__r.serviceEntity__r.Name, Opportunity.chantier__r.salesEntity__r.Name, 
                                            circuitSignatureDevis__c,source__c, amendInitialQuote__r.numeroDevis__c, previousQuote__r.TotalHTTarif__c, 
                                            previousQuote__r.TotalHTDevis__c, previousQuote__r.Total_TTC_devis__c, previousQuote__r.RemisevendeurglobaleFormule__c, 
                                            previousQuote__r.RemisevendeurglobaleDeviseFormule__c, customerOrder__r.Status, customerOrder__r.isReopen__c, 
                                            spilledCustomerOrder__r.Status, spilledCustomerOrder__r.isReopen__c, customerOrder__r.cancellingDate__c,
                                            spilledCustomerOrder__r.amount__c, spilledCustomerOrder__r.pretaxAmount__c,
                                            customerOrder__r.amount__c, customerOrder__r.pretaxAmount__c
                                        FROM Quote 
                                        WHERE Id IN :ordersMapSales.keySet() 
                                        AND (Status LIKE 'Vendu%' OR (Status = 'Résilié' AND customerOrder__r.isReopen__c = true))
                                        ORDER BY CreatedDate DESC];
                    // Récupération des devis avenant Sales
                    devisAvenantSalesList = [SELECT Id, numeroDevis__c, CreatedDate, spilledCustomerOrder__c, amendInitialQuote__r.customerOrder__c, 
                                                customerOrder__c, amendmentQuote__c, OpportunityOwner__c,
                                                spilledCustomerOrder__r.pretaxAmount__c, spilledCustomerOrder__r.amount__c,
                                                customerOrder__r.amount__c, customerOrder__r.pretaxAmount__c
                                            FROM Quote 
                                            WHERE amendmentQuote__c = true AND Status = 'Vendu enregistré'
                                            AND customerOrder__c IN :initialOrderIdList
                                            ORDER BY CreatedDate DESC];
                    
                    if(!devisSalesList.isEmpty()) {
                        // Récupération des infos Owner
                        for(Quote devis : devisSalesList) {
                            ownersIdList.add(devis.OwnerId);
                            oppOwnersIdList.add(devis.OpportunityOwner__c);
                        }
                        for(User usr : [SELECT Id, CodeDR__c, CodeDV__c, CodeMagasin__c, EmployeeNumber, LibelleDR__c, 
                                            LibelleDV__c, LibelleMagasin__c, Name, SGID__c FROM User WHERE Id IN :ownersIdList OR Id IN :oppOwnersIdList]) {
                            ownersMap.put(usr.Id.to15(), usr);
                        }
                    }
                }

                // Récupération KMDC existant par commande pour calcul nombre MDC
                if(!ordNumberList.isEmpty()) {
                    for(AggregateResult res : [SELECT COUNT(Id) nb, codeContrat__c FROM KMDC__c WHERE codeContrat__c IN :ordNumberList GROUP BY codeContrat__c]){
                        kmdcsExistsMap.put((String)res.get('codeContrat__c'), (Integer)res.get('nb'));
                    }                     
                }

                // * Création KMDC - CPQ
                for(SBQQ__Quote__c devis : devisCPQList) {
                    System.debug('## Devis CPQ: '+devis); 
                    User usr = ownersMap.get(devis.OpportunityOwner__c);
                    Order ord = ordersMapCPQ.get(devis.Id);
                    Integer codeOrigine = MappingUtils.getCodeOrigine(devis.sourceRef__r.Name);
                    String codeFinancement = getNumberFromCode(devis.financingMethod__r.KparKReference__c);
                    Integer numeroMDC = 1;
                    String nbDevis = devis.NDevis__c;

                    // Calcul du nombre de KMDC sur la commande
                    Integer numberTotalOfKMDC = 0;
                    String ordNumber = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__r.OrderNumber : ord.OrderNumber;
                    if(kmdcsExistsMap.get(ordNumber) != null) {
                        numberTotalOfKMDC = kmdcsExistsMap.get(ordNumber);
                    }
                    System.debug('## Nombre de KMDC: '+numberTotalOfKMDC); 

                    // Calcul du numéro de modification (MDC)
                    /*if(devis.amendmentQuote__c == false && devis.customerOrder__r.Status != Constants.ORDER_STATUS_CANCELLED&& devis.customerOrder__r.isReopen__c == false) {
                        numeroMDC = 1;
                    } else if(devis.customerOrder__r.Status == Constants.ORDER_STATUS_CANCELLED && devis.customerOrder__r.isReopen__c == false){
                        numeroMDC = numberTotalOfKMDC; numeroMDC++;
                    } else if(devis.customerOrder__r.Status != Constants.ORDER_STATUS_CANCELLED&& devis.customerOrder__r.isReopen__c){
                        numeroMDC = numberTotalOfKMDC;
                        numeroMDC++;
                    } else {
                        nbDevis = devis.amendInitialQuote__r.NDevis__c;
                        numeroMDC = numberTotalOfKMDC;
                        // Augmentation par rapport au numéro de l'avenants
                        System.debug('## devis.totalAmount__c: '+devis.totalAmount__c);
                        System.debug('## devis.previousQuote__r.totalAmount__c: '+devis.previousQuote__r.totalAmount__c);
                        System.debug('## devis.pretaxTotalAmount__c: '+devis.pretaxTotalAmount__c);
                        System.debug('## devis.previousQuote__r.pretaxTotalAmount__c: '+devis.previousQuote__r.pretaxTotalAmount__c);
                        if(devisAvenantCPQList != null && (devis.totalAmount__c != devis.previousQuote__r.totalAmount__c || devis.pretaxTotalAmount__c != devis.previousQuote__r.pretaxTotalAmount__c)) {
                            Integer index = numeroMDC;
                            for(SBQQ__Quote__c devAvenant : devisAvenantCPQList ) {
                                if(devAvenant.customerOrder__c == ord.parentOrder__c) {
                                    //numeroMDC++;
                                }
                                index++;
                                numeroMDC++;
                            }
                            System.debug('## index: '+index);
                        }
                    }*/
                    // 21-12-2023 JMU : MAJ pour que l'incrémentation soit simple avec une incrémentation de 1 à chaque fois
                    numeroMDC = numberTotalOfKMDC+1;
                    System.debug('## numeroMDC: '+numeroMDC);
                    
                    String IDTiers = nbDevis + '/' + numeroMDC;
                    System.debug('## IDTiers: '+IDTiers);
        
                    // Ecart Cotation TTC (€) : SBQQ__Quote__r.totalAmount__c - équivalent TTC du champ HT MontantTotalHTpostBP__c (montant TTC post bonus projet mais pré remise vendeur), 
                    //Ne connaissant pas suffisamment CPQ, je ne sais pas à quel champ cela correspond si ce champ existge sur l'entête, ni quel champ sommer sur les lignes.

                    // Objet KMDC CPQ
                    if(actionType != 'QuoteAmendmentValidation'){
                        if(totalAmountCustomerOrder == null)
                            totalAmountCustomerOrder = 0;
                        if(pretaxAmountCustomerOrder == null)
                            pretaxAmountCustomerOrder = 0;
                    }
                    Decimal ecartCotation = (devis.amendmentQuote__c) ? devis.ecartCotation__c - devis.previousQuote__r.ecartCotation__c : (devis.ecartCotation__c == null) ? 0 : devis.ecartCotation__c;
                    Decimal ecartCotationPercent = (devis.amendmentQuote__c) ? devis.ecartCotationPercent__c - devis.previousQuote__r.ecartCotationPercent__c : (devis.ecartCotationPercent__c == null) ? 0 : devis.ecartCotationPercent__c;
                    Decimal pretaxTotalAmount = (devis.amendmentQuote__c) ? devis.spilledCustomerOrder__r.pretaxAmount__c - pretaxAmountCustomerOrder : (devis.spilledCustomerOrder__r.pretaxAmount__c == null) ? 0 : devis.spilledCustomerOrder__r.pretaxAmount__c;
                    Decimal totalAmount = (devis.amendmentQuote__c) ? devis.spilledCustomerOrder__r.amount__c - totalAmountCustomerOrder : (devis.spilledCustomerOrder__r.amount__c == null) ? 0 : devis.spilledCustomerOrder__r.amount__c;
                    Decimal VATAmountWithoutDiscount = (devis.amendmentQuote__c) ? devis.VATAmountWithoutDiscount__c - devis.previousQuote__r.VATAmountWithoutDiscount__c : (devis.VATAmountWithoutDiscount__c == null) ? 0 : devis.VATAmountWithoutDiscount__c;
                    Decimal ecsTTC = ecartCotation + VATAmountWithoutDiscount;
                    ecsTTC = (devis.amendmentQuote__c) ? ecartCotation + VATAmountWithoutDiscount : (ecsTTC != null) ? ecsTTC.setScale(2) : ecsTTC;
                    
                    System.debug('## Montant TTC: '+totalAmount );
                    System.debug('## Montant HT: '+pretaxTotalAmount );

                    // Lors de l'annulation de la commande associée
                    if(devis.customerOrder__r.cancellingDate__c != null){
                        totalAmount = devis.spilledCustomerOrder__r.amount__c * -1;
                        pretaxTotalAmount = devis.spilledCustomerOrder__r.pretaxAmount__c * -1;
                    }

                    KMDC__c obj = new KMDC__c();

                    System.debug('## Montant TTC2: '+totalAmount );
                    System.debug('## Montant HT2: '+pretaxTotalAmount );

                    System.debug('## Montant TTC spilled: '+devis.spilledCustomerOrder__r.amount__c);
                    System.debug('## Montant HT spilled: '+devis.spilledCustomerOrder__r.pretaxAmount__c);
                    System.debug('## Montant TTC customerOrder: '+devis.customerOrder__r.amount__c);
                    System.debug('## Montant HT customerOrder: '+devis.customerOrder__r.pretaxAmount__c);

                    if(actionType == 'Quote'){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                    devis.chantier__r.serviceEntity__r.KparKReference__c, 
                                                    devis.chantier__r.salesEntity__r.KparKReference__c, 
                                                    devis.chantier__r.serviceEntity__r.Name, 
                                                    devis.chantier__r.salesEntity__r.Name, 
                                                    devis.sourceTexte__c, String.valueOf(codeFinancement), devis.financingMethod__r.Name, 
                                                    devis.CircuitSignatureDevis__c, devis.Id, pretaxTotalAmount, totalAmount, 
                                                    ecartCotation, ecartCotationPercent, ecsTTC, 
                                                    usr, ord, entityHierarchieMap);

                    } else if(actionType == 'QuoteValidation'){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                    devis.chantier__r.serviceEntity__r.KparKReference__c, 
                                                    devis.chantier__r.salesEntity__r.KparKReference__c, 
                                                    devis.chantier__r.serviceEntity__r.Name, 
                                                    devis.chantier__r.salesEntity__r.Name, 
                                                    devis.sourceTexte__c, String.valueOf(codeFinancement), devis.financingMethod__r.Name, 
                                                    devis.CircuitSignatureDevis__c, devis.Id, pretaxTotalAmount, totalAmount, 
                                                    ecartCotation, ecartCotationPercent, ecsTTC, 
                                                    usr, ord, entityHierarchieMap);
                    
                    } else if(actionType == 'QuoteAmendmentValidation' && (devis.spilledCustomerOrder__r.amount__c != totalAmountCustomerOrder 
                                                                            || devis.spilledCustomerOrder__r.pretaxAmount__c != pretaxAmountCustomerOrder)){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                    devis.chantier__r.serviceEntity__r.KparKReference__c, 
                                                    devis.chantier__r.salesEntity__r.KparKReference__c, 
                                                    devis.chantier__r.serviceEntity__r.Name, 
                                                    devis.chantier__r.salesEntity__r.Name, 
                                                    devis.sourceTexte__c, String.valueOf(codeFinancement), devis.financingMethod__r.Name, 
                                                    devis.CircuitSignatureDevis__c, devis.Id, pretaxTotalAmount, totalAmount, 
                                                    ecartCotation, ecartCotationPercent, ecsTTC, 
                                                    usr, ord, entityHierarchieMap);
                        // Alimentation du type__c sur KMDC
                        if(totalAmountCustomerOrder < devis.spilledCustomerOrder__r.amount__c && devis.customerOrder__r.cancellingDate__c == null){
                            obj.type__c = 'Majoration';
                        }

                        if(totalAmountCustomerOrder > devis.spilledCustomerOrder__r.amount__c && devis.customerOrder__r.cancellingDate__c == null){
                            obj.type__c = 'Minoration';
                        }

                        if(totalAmountCustomerOrder == devis.spilledCustomerOrder__r.amount__c && pretaxAmountCustomerOrder != devis.spilledCustomerOrder__r.pretaxAmount__c && devis.customerOrder__r.cancellingDate__c == null){
                            obj.type__c = 'Variation HT';
                        }                        
                    }

                    kMDCToUps.add(obj);
                }

                // * Création KMDC - Sales
                for(Quote devis : devisSalesList) {
                    System.debug('## Devis Sales: '+devis); 
                    System.debug('## Devis Sales Status: '+devis.Status); 
                    User usr = ownersMap.get(devis.OpportunityOwner__c);
                    Order ord = ordersMapSales.get(devis.Id);
                    Integer codeOrigine = MappingUtils.getCodeOrigine(devis.source__c);                    
                    Integer codeFinancement = MappingUtils.getCodeCredit(devis.modeFinancement__c);
                    String nbDevis = devis.numeroDevis__c;
                    Integer numeroMDC = 1;

                    // Calcul du nombre de KMDC sur la commande
                    Integer numberTotalOfKMDC = 0;
                    String ordNumber = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__r.OrderNumber : ord.OrderNumber; 
                    if(kmdcsExistsMap.get(ordNumber) != null) {
                        numberTotalOfKMDC = kmdcsExistsMap.get(ordNumber);
                    }
                    System.debug('## Nombre de KMDC: '+numberTotalOfKMDC); 

                    // Calcul du numéro de modification (MDC)
                    /*if(devis.amendmentQuote__c == false && devis.customerOrder__r.Status != Constants.ORDER_STATUS_CANCELLED
                        && devis.customerOrder__r.isReopen__c == false) 
                    {
                        numeroMDC = 1;
                    } else if(devis.customerOrder__r.Status == Constants.ORDER_STATUS_CANCELLED && devis.customerOrder__r.isReopen__c == false)
                    {
                        numeroMDC = numberTotalOfKMDC;
                        numeroMDC++;
                    } else if(devis.customerOrder__r.Status != Constants.ORDER_STATUS_CANCELLED && devis.customerOrder__r.isReopen__c)
                    {
                        numeroMDC = numberTotalOfKMDC;
                        numeroMDC++;
                    } else {
                        nbDevis = devis.amendInitialQuote__r.numeroDevis__c;
                        numeroMDC = numberTotalOfKMDC;
                        // Augmentation par rapport au numéro de l'avenant
                        if(devisAvenantSalesList != null && (devis.Total_TTC_devis__c != devis.previousQuote__r.Total_TTC_devis__c || devis.TotalHTDevis__c != devis.previousQuote__r.TotalHTDevis__c)) {
                            Integer index = numeroMDC;
                            for(Quote devAvenant : devisAvenantSalesList) {
                                if(devAvenant.customerOrder__c == ord.parentOrder__c) {
                                    numeroMDC++;
                                }
                                index++;
                            }
                        }
                    }*/
                    // 21-12-2023 JMU : MAJ pour que l'incrémentation soit simple avec une incrémentation de 1 à chaque fois
                    numeroMDC = numberTotalOfKMDC+1;
                    System.debug('## numeroMDC: '+numeroMDC);

                    String IDTiers = nbDevis + '/' + numeroMDC;
                    System.debug('## IDTiers: '+IDTiers);

                    // Objet KMDC Sales
                    if(actionType != 'QuoteAmendmentValidation'){
                        if(totalAmountCustomerOrder == null)
                            totalAmountCustomerOrder = 0;
                        if(pretaxAmountCustomerOrder == null)
                            pretaxAmountCustomerOrder = 0;
                    }
                    Decimal TotalHTDevis = (devis.amendmentQuote__c) ? devis.spilledCustomerOrder__r.pretaxAmount__c - pretaxAmountCustomerOrder : (devis.spilledCustomerOrder__r.pretaxAmount__c == null) ? 0 : devis.spilledCustomerOrder__r.pretaxAmount__c;
                    Decimal Total_TTC_devis = (devis.amendmentQuote__c) ? devis.spilledCustomerOrder__r.amount__c - totalAmountCustomerOrder :  (devis.spilledCustomerOrder__r.amount__c == null) ? 0 : devis.spilledCustomerOrder__r.amount__c;
                    Decimal RemisevendeurglobaleFormule = (devis.amendmentQuote__c) ? devis.RemisevendeurglobaleFormule__c - devis.previousQuote__r.RemisevendeurglobaleFormule__c :  (devis.RemisevendeurglobaleFormule__c == null) ? 0 : devis.RemisevendeurglobaleFormule__c;
                    Decimal RemisevendeurglobaleDeviseFormule = (devis.amendmentQuote__c) ? devis.RemisevendeurglobaleDeviseFormule__c - devis.previousQuote__r.RemisevendeurglobaleDeviseFormule__c :  (devis.RemisevendeurglobaleDeviseFormule__c == null) ? 0 : devis.RemisevendeurglobaleDeviseFormule__c;
                    Decimal ecsHT = Total_TTC_devis + TotalHTDevis;
                    ecsHT = (ecsHT != null) ? ecsHT.setScale(2) : ecsHT;
                    ecsHT = (devis.amendmentQuote__c) ? Total_TTC_devis + TotalHTDevis : (ecsHT != null) ? ecsHT.setScale(2) : ecsHT;

                    System.debug('## Montant HT: '+TotalHTDevis);
                    System.debug('## Montant TTC: '+Total_TTC_devis);
                    
                    // Lors de l'annulation de la commande associée
                    if(devis.customerOrder__r.cancellingDate__c != null){
                        TotalHTDevis = devis.spilledCustomerOrder__r.pretaxAmount__c * -1;
                        Total_TTC_devis = devis.spilledCustomerOrder__r.amount__c * -1;
                    }

                    KMDC__c obj = new KMDC__c();

                    if(actionType == 'Quote'){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.Name, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.Name, 
                                                        devis.source__c, String.valueOf(codeFinancement), devis.modeFinancement__c, 
                                                        devis.circuitSignatureDevis__c, devis.Id, TotalHTDevis, Total_TTC_devis, ecsHT, 
                                                        RemisevendeurglobaleFormule, RemisevendeurglobaleDeviseFormule,
                                                        usr, ord, entityHierarchieMap);

                    } else if(actionType == 'QuoteValidation'){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.Name, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.Name, 
                                                        devis.source__c, String.valueOf(codeFinancement), devis.modeFinancement__c, 
                                                        devis.circuitSignatureDevis__c, devis.Id, TotalHTDevis, Total_TTC_devis, ecsHT, 
                                                        RemisevendeurglobaleFormule, RemisevendeurglobaleDeviseFormule,
                                                        usr, ord, entityHierarchieMap);

                    } else if(actionType == 'QuoteAmendmentValidation' && (devis.spilledCustomerOrder__r.amount__c != totalAmountCustomerOrder || 
                                                                             devis.spilledCustomerOrder__r.pretaxAmount__c != pretaxAmountCustomerOrder)){
                        obj = createKMDCObject(IDTiers, numeroMDC, codeOrigine, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.KparKReference__c, 
                                                        devis.Opportunity.chantier__r.serviceEntity__r.Name, 
                                                        devis.Opportunity.chantier__r.salesEntity__r.Name, 
                                                        devis.source__c, String.valueOf(codeFinancement), devis.modeFinancement__c, 
                                                        devis.circuitSignatureDevis__c, devis.Id, TotalHTDevis, Total_TTC_devis, ecsHT, 
                                                        RemisevendeurglobaleFormule, RemisevendeurglobaleDeviseFormule,
                                                        usr, ord, entityHierarchieMap);

                            // Alimentation du type__c sur KMDC
                            if(totalAmountCustomerOrder < devis.spilledCustomerOrder__r.amount__c && devis.customerOrder__r.cancellingDate__c == null){
                                obj.type__c = 'Majoration';
                            }

                            if(totalAmountCustomerOrder > devis.spilledCustomerOrder__r.amount__c && devis.customerOrder__r.cancellingDate__c == null){
                                obj.type__c = 'Minoration';
                            }

                            if(totalAmountCustomerOrder == devis.spilledCustomerOrder__r.amount__c && pretaxAmountCustomerOrder != devis.spilledCustomerOrder__r.pretaxAmount__c&& devis.customerOrder__r.cancellingDate__c == null){
                                obj.type__c = 'Variation HT';
                            }
                    }  
                
                    kMDCToUps.add(obj);
                }
            }

            // Upsert des données
            if(!kFactureToUps.isEmpty()) {
                upsert kFactureToUps;
            }
            if(!kMDCToUps.isEmpty()) {
                upsert kMDCToUps;
            }

            System.debug('### FIN QA_KMDCEinstein.execute()');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    /**
    * @description Méthode pour créer l'objet KMDC avec les valeurs
    * @return KMDC__c Objet KMDC avec les valeurs
    */
    public static KMDC__c createKMDCObject(String IDTiers, Integer numeroMDC, Integer codeOrigine, String codeDepotChantier, 
                                            String codeMagasinChantier, String nomDepotChantier, String nomMagasinChantier, 
                                            String source, String codeFinancement, String nomFinancement, String circuitSign,
                                            String devisId, Decimal pretaxAmount, Decimal amount,                                             
                                            Decimal ecsHT, Decimal ecsTaux, Decimal ecsTTC,
                                            User usr, Order ord, Map<String, Account> entityHierarchieMap) 
    {       
        // Création objet   
        KMDC__c obj = new KMDC__c(
            IDTiers__c = IDTiers,
            codeOrigine__c = codeOrigine,
            depotChantier__c = codeDepotChantier,
            magasinChantier__c = codeMagasinChantier,
            ECS_HT__c = ecsHT,
            ECS_Taux__c = ecsTaux,
            ECS_TTC__c = ecsTTC,
            montantHT__c = pretaxAmount,
            montantTTC__c = amount,
            numeroMDC__c = numeroMDC,
            origine__c = source,
            codeFinancement__c = codeFinancement,
            financement__c = nomFinancement,
            nomDepotChantier__c = nomDepotChantier,
            nomMagasinChantier__c = nomMagasinChantier,
            typeSignature__c = (String.isBlank(circuitSign)) ? 'Manuel' : 'Electronique',
            devis__c = devisId,
            Id = null,
            suppliedBy__c = 'Automatique'
        );

        //Formatage  codification Magasin, Dépot et Financement
        if(codeMagasinChantier != null){
            obj.magasinChantier__c = getNumberFromCode(codeMagasinChantier);
        }
        if(codeDepotChantier != null){
            obj.depotChantier__c = getNumberFromCode(codeDepotChantier);
        }

        if(usr != null) {
            obj.DRvendeur__c = (usr.CodeDR__c != null) ? getNumberFromCode(usr.CodeDR__c) : obj.DRVenteChantier__c;
            obj.DVVendeur__c = (usr.CodeDV__c != null) ? getNumberFromCode(usr.CodeDV__c) : obj.DVChantier__c;
            obj.magasinVendeur__c = (usr.CodeMagasin__c != null) ? getNumberFromCode(usr.CodeMagasin__c) : obj.magasinChantier__c;
            obj.nomDRvendeur__c = (usr.LibelleDR__c != null) ? usr.LibelleDR__c : obj.nomDRVenteChantier__c;
            obj.nomDVVendeur__c = (usr.LibelleDV__c != null) ? usr.LibelleDV__c : obj.nomDVChantier__c;
            obj.nomMagasinVendeur__c = (usr.LibelleMagasin__c != null) ? usr.LibelleMagasin__c : obj.nomMagasinChantier__c;
            
            String usrName = usr.Name;
            if(String.isNotBlank(usr.SGID__c)){
                List<Collaborator__c> collaboratorList = [SELECT Id, reference__c, Name, user__r.SGID__c FROM Collaborator__c WHERE reference__c = :usr.SGID__c];
                if(!collaboratorList.isEmpty()){
                    usrName = collaboratorList[0].Name;
                } 
            } 
            /* INVERSION ALIMENTATION SGID ET VENDEUR CAR EINSTEIN ATTEND LE NOM DANS SGID ET SGID DANS NOM
            obj.vendeur__c = usrName;
            obj.SGID__c = usr.sgid__c;
            */
            obj.vendeur__c = usr.sgid__c;
            obj.SGID__c = usrName;
            System.debug('## Vendeur: ' + obj.vendeur__c);
            System.debug('## SGID: ' + obj.SGID__c);
        }

        if(ord != null) {                        
            // Si Avenant, on alimente avec le code de la commande initiale
            if(ord.isLegacy__c){
                obj.codeContrat__c = 'CNT/' + ord.legacyReference__c;
            } else if (ord.parentOrder__r.isLegacy__c){
                obj.codeContrat__c = 'CNT/' + ord.parentOrder__r.legacyReference__c;
            } else {
                obj.codeContrat__c = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__r.OrderNumber : ord.OrderNumber; 
            }
            obj.customerOrder__c = (String.isNotBlank(ord.parentOrder__c)) ? ord.parentOrder__c : ord.Id;
            // Récupération entité service DR
            Account serviceChantierDR = calculateParentEntityByType(ord.serviceEntity__c, 'DR', entityHierarchieMap);
            if(serviceChantierDR != null) {
                obj.DRServiceChantier__c = getNumberFromCode(serviceChantierDR.KparKReference__c);
                obj.nomDRServiceChantier__c = serviceChantierDR.Name;
            }
            // Récupération entité service DS
            Account serviceChantierDS = calculateParentEntityByType(ord.serviceEntity__c, 'DS', entityHierarchieMap);
            if(serviceChantierDS != null) {
                obj.DSChantier__c = getNumberFromCode(serviceChantierDS.KparKReference__c);
                obj.nomDSChantier__c = serviceChantierDS.Name;
            }
            // Récupération entité sales DR
            Account salesChantierDR = calculateParentEntityByType(ord.salesEntity__c, 'DRV', entityHierarchieMap);
            if(salesChantierDR != null) {
                obj.DRVenteChantier__c = getNumberFromCode(salesChantierDR.KparKReference__c); 
                obj.nomDRVenteChantier__c = salesChantierDR.Name;
            }
            // Récupération entité sales DV
            Account salesChantierDV = calculateParentEntityByType(ord.salesEntity__c, 'DV', entityHierarchieMap);
            if(salesChantierDV != null) {
                obj.DVChantier__c = getNumberFromCode(salesChantierDV.KparKReference__c);
                obj.nomDVChantier__c = salesChantierDV.Name;
            }

            // Récupération Clôture K/K
            List<CustomClosing__c> cstCloList = new List<CustomClosing__c>();
            if(ord != null){
                cstCloList = [SELECT Id, businessStartDate__c, businessEndDate__c, Name 
                            FROM CustomClosing__c
                            WHERE (businessStartDate__c <= :System.now()) AND (businessEndDate__c >= :System.now())];

                if(!cstCloList.isEmpty()){
                    obj.assignedClosing__c = cstCloList[0].Id;
                }
            }
            System.debug('## Clôture : '+obj.assignedClosing__c);

            // Alimentation de la dateStats__c et Type
            // Approbation d'une commande
            if(ord.isValid__c && ord.isReopen__c == false && (ord.cancellingDate__c == null || ord.Type == Constants.ORDER_TYPE_AVENANT) && System.now() > cstCloList[0].businessStartDate__c){
                obj.dateStats__c = getMaxDate(cstCloList[0].businessStartDate__c.date(),ord.EffectiveDate);
                obj.type__c = 'Création';
                obj.dateVente__c = ord.EffectiveDate;
                System.debug('## DATESTATS APP: '+obj.dateStats__c); 
            // Annulation d'une commande
            } else if (ord.cancellingDate__c != null && ord.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT && System.now() > cstCloList[0].businessStartDate__c) {
                obj.dateStats__c = getMaxDate(cstCloList[0].businessStartDate__c.date(), ord.cancellingDate__c);
                obj.type__c = 'Résiliation';
                obj.dateVente__c = getMaxDate(cstCloList[0].businessStartDate__c.date(), ord.cancellingDate__c);
                System.debug('## DATESTATS RES: '+obj.dateStats__c);            
            // Réouverture d'une commande
            } else if (ord.isReopen__c && System.now() > cstCloList[0].businessStartDate__c) {
                obj.dateStats__c = Date.today();
                obj.type__c = 'Recréditation';
                obj.dateVente__c = Date.today();
                System.debug('## DATESTATS REOUV: '+obj.dateStats__c);
            } else {
                obj.dateStats__c = cstCloList[0].businessStartDate__c.date();
                obj.dateVente__c = ord.EffectiveDate;
                System.debug('## DATESTATS: '+obj.dateStats__c);
            }

            // Récupération Clôture K/K cas particulier d'une génération de KMDC un mardi
            List<CustomClosing__c> cstCloList2 = new List<CustomClosing__c>();
            if(obj.dateStats__c == cstCloList[0].businessEndDate__c.date()){
                cstCloList2 = [SELECT Id, businessStartDate__c, businessEndDate__c, Name 
                            FROM CustomClosing__c
                            WHERE DAY_ONLY(businessStartDate__c) = :obj.dateStats__c];

                if(!cstCloList2.isEmpty()){
                    obj.assignedClosing__c = cstCloList2[0].Id;
                    System.debug('## CLOTURE: '+obj.assignedClosing__c );
                }
            }            
        }

        // Alimentation du teleacteur
        // Cas d'un teleacteur existant
        List<KMDC__c> existingKMDC = new List<KMDC__c>();
        existingKMDC = [SELECT Id, teleacteur__c 
            FROM KMDC__c
            WHERE customerOrder__c = :ord.Id OR (customerOrder__c = :ord.parentOrder__r.Id AND customerOrder__c != null)
            ORDER BY createdDate DESC LIMIT 1];
        if(!existingKMDC.isEmpty()){
            obj.teleacteur__c = existingKMDC[0].teleacteur__c;
            System.debug('## existingKMDC: '+existingKMDC); 
        } else {
            // Cas de recherche d'un TA via Events

            System.debug('## obj.dateVente__c: '+obj.dateVente__c); 
            System.debug('## ord.chantier__r.rue__c: '+ord.chantier__r.rue__c); 
            System.debug('## ord.chantier__r.codePostal__c: '+ord.chantier__r.codePostal__c); 
            System.debug('## ord.chantier__r.ville__c: '+ord.chantier__r.ville__c); 
            System.debug('## ord.chantier__r.telephoneDomicileProprietaires__c: '+ord.chantier__r.telephoneDomicileProprietaires__c); 
            System.debug('## ord.chantier__r.telephoneMobileProprietaires__c: '+ord.chantier__r.telephoneMobileProprietaires__c); 
            System.debug('## ord.chantier__r.telephoneProprietaires__c: '+ord.chantier__r.telephoneProprietaires__c); 
            System.debug('## ord.chantier__r.autreTelephoneProprietaires__c: '+ord.chantier__r.autreTelephoneProprietaires__c); 

            List<Event> eventList = new List<Event>();
            eventList = [SELECT id, CreatedById, chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c, 
                                chantier__r.telephoneDomicileProprietaires__c, chantier__r.telephoneMobileProprietaires__c
            FROM Event
            WHERE createdDate <= :obj.dateVente__c
            AND createdDate >= :(obj.dateVente__c - 183)
            AND (typeCall__c = :Constants.ACTIVITY_EVENT_NEW OR
                typeCall__c = :Constants.ACTIVITY_EVENT_DISPLACED OR
                typeCall__c = :Constants.ACTIVITY_EVENT_CANCELLED OR
                typeCall__c = :Constants.ACTIVITY_EVENT_CANCELLEDWITHQUALIF)
            AND (
                (chantier__r.rue__c = :ord.chantier__r.rue__c AND 
                    (chantier__r.codePostal__c = :ord.chantier__r.codePostal__c OR
                    chantier__r.ville__c = :ord.chantier__r.ville__c))
                    OR (chantier__r.telephoneDomicileProprietaires__c = :ord.chantier__r.telephoneDomicileProprietaires__c AND chantier__r.telephoneDomicileProprietaires__c != null)
                    OR (chantier__r.telephoneMobileProprietaires__c = :ord.chantier__r.telephoneMobileProprietaires__c AND chantier__r.telephoneMobileProprietaires__c != null)
                    OR (chantier__r.telephoneMobileProprietaires__c = :ord.chantier__r.telephoneProprietaires__c AND chantier__r.telephoneMobileProprietaires__c != null)
                    OR (chantier__r.telephoneMobileProprietaires__c = :ord.chantier__r.autreTelephoneProprietaires__c AND chantier__r.telephoneMobileProprietaires__c != null))
            ORDER BY createdDate DESC];

            if(!eventList.isEmpty()){
                // Recherche stricte (adresse + téléphone) d'un TA via les Events
                System.debug('## eventList: '+eventList); 
                Boolean TAstrictFound = false;
                for(Event ev : eventList){
                    if(!TAstrictFound && ev.chantier__r.rue__c == ord.chantier__r.rue__c &&
                        ev.chantier__r.codePostal__c == ord.chantier__r.codePostal__c &&
                        ev.chantier__r.ville__c == ord.chantier__r.ville__c &&
                        ev.chantier__r.telephoneDomicileProprietaires__c == ord.chantier__r.telephoneDomicileProprietaires__c &&
                        (ev.chantier__r.telephoneMobileProprietaires__c == ord.chantier__r.telephoneMobileProprietaires__c ||
                        ev.chantier__r.telephoneMobileProprietaires__c == ord.chantier__r.telephoneProprietaires__c ||
                        ev.chantier__r.telephoneMobileProprietaires__c == ord.chantier__r.autreTelephoneProprietaires__c)
                    ){
                        TAstrictFound = true;
                        obj.teleacteur__c = ev.CreatedById;
                    }
                }

                // Recherche souple (adresse + téléphone) d'un TA via les Events
                if(!TAstrictFound){
                    obj.teleacteur__c = eventList[0].CreatedById;
                    System.debug('#### eventList: '+eventList); 
                }
            }
        }

        if(ord != null && obj.type__c == 'Création'){
            ord.firstDateStats__c = obj.dateStats__c;
            ord.firstAssignedClosing__c = obj.assignedClosing__c;
            update ord;
        }

        System.debug('## KMDC: '+obj); 
        return obj;
    }

    /**
    * @description Méthode pour récupérer seulement la partie nombre d'un code magasin/dépot
    * @param value Valeur à extraire 
    * @param key Clé pour séparation entre texte et nombre
    * @return String Partie nombre du code
    */
    public static String getNumberFromCode(String value) {   
        String result;
        if(String.isNotBlank(value)) {
            Integer zeroPosition = value.indexOf('0');
            String codeStr = value.substring(zeroPosition, value.length());
            Integer codeInteger = Integer.valueOf(codeStr);
            result = String.valueOf(codeInteger);
        }
        return result;
    }

    /**
    * @description Méthode récurive permettant de vérifier l'entité parente ayant le type d'entité recherché
    * @param entityId Id de l'entité
    * @param entTypeToSearch Référence du type de l'entité à rechercher
    * @param entityHierarchieMap Objet contenant la hiéarchie des entités
    * @return Account Entité parente avec le type recherché, sinon null
    */
    public static Account calculateParentEntityByType(String entityId, String entTypeToSearch, Map<String, Account> entityHierarchieMap) {
        Account entity = entityHierarchieMap.get(entityId);
        System.debug('## Recherche par type entité: '+entTypeToSearch+' / '+entity); 
        if(entity != null && entity.entityType__r.KparKReference__c == entTypeToSearch) {
            System.debug('## Entité: '+entity);
            return entity;
        } else if(entity != null && String.isNotBlank(entity.ParentId)) {
            // Sinon on effectue une récursivité sur l'entité
            return calculateParentEntityByType(entity.ParentId, entTypeToSearch, entityHierarchieMap);
        } else {
            System.debug('## Pas d\'entité trouvé');
            return null;
        }
    }

    /**
    * @description Méthode permettant de construire la hiéarchie des entités
    * @return Map<String, Account> Retourne une map des entités : Key = Id entité, valeur = entité
    */
    public static Map<String, Account> getEntityHierarchy() {
        Map<String, Account> result = new Map<String, Account>();
        String rtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account acc : [SELECT Id, Name, ParentId, rue__c, codePostal__c, ville__c, departement__c, pays__c, Ownership, complementAdresse__c,
                                emailPro__c, Phone, SIRET__c, shareCapital__c, SIREN__c, RCSNumber__c, RCSCity__c, intracommunityVATNumber__c,
                                entityType__r.KparKReference__c, email__c, KparKReference__c 
                            FROM Account WHERE RecordTypeId = :rtId]) {
            result.put(acc.Id, acc);
        }
        return result;
    }

    public static Date getMaxDate(Date d1, Date d2){
        Date maxDate = d1;
        if(d1 < d2){
            maxDate = d2;
        }
        return maxDate;
    }
}