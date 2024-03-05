/**
 * @author 4C
 * @date 2020-07-23
 * @description Commission management class used to create, update commissions on quote/quotelines
 * 
 */
public without sharing class TR022_SBQQ_Quote_Commission {

    /**
     * @author 4C
     * @date 2020-08-27
     * @description Inner class used as context for commission processing
     */
    public class NRV10CommissionContext {
        public Boolean isCPQ;
        public List<Id> quoteIds = new List<Id>();
        public List<Id> quoteLineIds = new List<Id>();
        public Map<String, List<NRV10Commission__c>> originQuotelineCommissionMap = new Map<String, List<NRV10Commission__c>>();
        public List<Id> amendmentQuoteIds = new List<Id>();
        public Map<Id, List<QuoteTransformer>> amendedOrderQuotesMap = new Map<Id, List<QuoteTransformer>>();

        public Map<Id, List<Order>> quoteOrdersMap = new Map<Id, List<Order>>();
        public Map<Id, Id> quoteLineOrderProductsMap = new Map<Id, Id>();

        public List<Id> ownerIds = new List<Id>();
        public List<Id> oppOwnerIds = new List<Id>();
        public List<QuoteTransformer> quoteInfos = new List<QuoteTransformer>();
        public Map<Id, Collaborator__c> collaboratorsMap = new Map<Id, Collaborator__c>();
        public List<Id> collaboratorIds = new List<Id>();
        public List<Id> managerIds = new List<Id>();
        public List<String> collaboratorSGIds = new List<String>();
        public Map<Id, String> collabIdSgIdMap = new Map<Id, String>();
        public Map<Id, Collaborator__c> managersMap = new Map<Id, Collaborator__c>();
        public Map<Id, String> collaboratorJobHierarchyMap = new Map<Id, String>();
        public List<Id> storeIds = new List<Id>();
        public Map<Id, List<Id>> managerAssignmentsMap = new Map<Id, List<Id>>();
        public Map<Id, List<NRV10RemunerationContract__c>> collaboratorContractMap = new Map<Id, List<NRV10RemunerationContract__c>>();
        public Map<Id, List<NRV10RemunerationContract__c>> collaboratorContractMapFromQuote = new Map<Id, List<NRV10RemunerationContract__c>>();
        public List<Id> ctRevGridIds = new List<Id>();
        public Map<Id, List<QuoteLineTransformer>> quoteQuoteLinesMap = new Map<Id, List<QuoteLineTransformer>>();
        public List<Id> productIds = new List<Id>();
        public Map<Id, NRV10GridRevision__c> contractRevisionsMap = new Map<Id, NRV10GridRevision__c>();
        public List<Id> subRevGridIds = new List<Id>();
        public Map<Id, NRV10GridRevision__c> subRevGridsMap = new Map<Id, NRV10GridRevision__c>();
        public Map<Id, List<NRV10RemunerationRate__c>> remunerationRatesGridMap = new Map<Id, List<NRV10RemunerationRate__c>>();
        public Map<Id, NRV10RemunerationRate__c> remunerationRatesMap = new Map<Id, NRV10RemunerationRate__c>();
        public Map<Id, List<Id>> productRatesMap = new Map<Id, List<Id>>();
        public Map<String, NRV10Commission__c> commissionMap = new Map<String, NRV10Commission__c>();
        public Map<Id, NRV10Commission__c> bonusMap = new Map<Id, NRV10Commission__c>();

        //list of processed sales collaborator to use for bonus commission processing
        public List<Collaborator__c> processedSales;
    }


    /**
     * @author 4C
     * @date 2020-08-27
     * @description Commission calculation processing from Generic Object
     */
    @InvocableMethod(Label='Générer les commissions' Description='Générer les commissions')
    public static void processCommissions(List<SObject> quotes) {
        if (quotes == null || quotes.isEmpty()) return;

        if (quotes.get(0) instanceof SBQQ__Quote__c) {
            processCPQCommissions(quotes);
        } else {
            processSalesCommissions(quotes);
        }
    }

    /**
     * @author 4C
     * @date 2020-08-27
     * @description Commission processing for CPQ Quotes
     */
    public static void processCPQCommissions(List<SBQQ__Quote__c> quotes) {
        List<QuoteTransformer> quotesW = new List<QuoteTransformer>();
        for (SBQQ__Quote__c q : quotes) {
            quotesW.add(new QuoteTransformer(q));
        }

        // Init processing context, load all Rem data, amended quotes, orders etc...
        NRV10CommissionContext context = prepareContext(quotesW);

        //Process remVRP only if quotes has collaborator Ids associated
        if (!context.collaboratorIds.isEmpty()) {
            // Process sales/team commissions creation/update
            TR023_SBQQ_Quote_SalesCommission.processSalesCommissions(quotesW, context);

            // Process sales bonus commissions
            TR023_SBQQ_Quote_BonusCommission.processBonusCommissions(context);
        }
    }

    /**
     * @author 4C
     * @date 2021-03-02
     * @description Commission processing for sales Quotes
     */
    public static void processSalesCommissions(List<Quote> quotes) {
        System.debug('Commissions processing for Sales Quotes');

        List<QuoteTransformer> quotesW = new List<QuoteTransformer>();
        for (Quote q : quotes) {
            quotesW.add(new QuoteTransformer(q));
        }

        // Init processing context, load all Rem data, amended quotes, orders etc...
        NRV10CommissionContext context = prepareContext(quotesW);

        // Process sales/team commissions creation/update
        TR023_SBQQ_Quote_SalesCommission.processSalesCommissions(quotesW, context);

        // Process sales bonus commissions
        TR023_SBQQ_Quote_BonusCommission.processBonusCommissions(context);
    }

    /**
     * @author 4C
     * @date 2020-08-27
     * @description Private method used to initialize all necessary DML results used by the commission calculation process
     * @param quotes List of quote that will be processed
     *
     * @return a context structure
     */
    @TestVisible
    private static NRV10CommissionContext prepareContext(List<QuoteTransformer> quotes) {
        NRV10CommissionContext result = new NRV10CommissionContext();
        result.isCPQ = quotes.size() > 0 ? quotes.get(0).isCPQ : false;

        //parse quotes
        for (QuoteTransformer q : quotes) {
            System.debug('## Check quote parameters');
            System.debug(' --> status: ' + q.Status);
            if (q.Status != null && (q.Status == Constants.QUOTE_STATUS_TO_CONFIGURE
                    || q.Status == Constants.STD_QUOTE_STATUS_TO_CONFIGURE
                    || q.Status == Constants.QUOTE_STATUS_NOT_TRANSMITTED
                    || q.Status == Constants.QUOTE_STATUS_TRANSMITTED
                    || q.Status == Constants.QUOTE_STATUS_SOLD
                    || q.Status == Constants.QUOTE_STATUS_CANCELLED)) 
            {
                result.quoteIds.add(q.Id);
                System.debug(' --> owner: ' + q.OwnerId);
                System.debug(' --> oppOwner: ' + q.OppOwnerId);
                if (q.OppOwnerId != null) {
                    result.ownerIds.add(q.OwnerId);
                    result.oppOwnerIds.add(q.OppOwnerId);
                    result.quoteInfos.add(q);
                }
                System.debug('## quote is amendment? ' + q.AmendmentQuote + ' point to quote ' + q.AmendInitialQuoteId);
                System.debug(' --> amendment?: ' + q.AmendmentQuote);
                if (q.AmendmentQuote && q.AmendPreviousQuoteId != null) {
                    result.amendmentQuoteIds.add(q.AmendPreviousQuoteId);
                }
            }
        }

        //get all collaborators relative context
        fillCollaboratorContext(result);

        //If no collaborator Ids, it is un-necessary to go further
        if (result.collaboratorIds.isEmpty()) {
            return result;
        }

        //get all CPQ quotes relative context
        if (result.isCPQ) {
            fillCPQQuoteContext(result);
            fillExistingCPQCommissions(result);
        } else {
            fillSalesQuoteContext(result);
            fillExistingSalesCommissions(result);
        }
        //deleteExistingCommissions(result);

        // get snapshots dates (last 2 processed dates for CA M-2 and next date
        List<NRV10Calendar__c> lastSnapshotDates;
        Date nextSnapshotDate;
        try {
            lastSnapshotDates = [SELECT Id, commDate__c FROM NRV10Calendar__c WHERE commDate__c <= TODAY
            ORDER BY commDate__c DESC LIMIT 2];
            nextSnapshotDate = [SELECT Id, commDate__c FROM NRV10Calendar__c WHERE commDate__c > TODAY
            ORDER BY commDate__c ASC LIMIT 1].commDate__c;
        } catch (QueryException e) {
            System.debug('## Can\'t find last or next snapshotDate');
        }

        // get M-2 collaborators CA
        for (NRV10Commission__c commission : [SELECT Id, status__c, user__c, comType__c, orderProduct__c,
                quoteLine__c, quoteLineItem__c, remuneration__c, customerOrder__c, quoteCPQ__c, instantDate__c
                FROM NRV10Commission__c WHERE user__c IN :result.collaboratorIds
                AND instantDate__c = NULL AND comType__c = :Constants.COMMISSION_TYPE_BONUS
                AND status__c = :Constants.COMMISSION_STATUS_PREVISIONEL]) {
            result.bonusMap.put(commission.user__c, commission);
        }

        return result;
    }

    /**
     * Prepare le contexte relatif aux devis/avenants
     *
     * @param context Contexte d'entrée à compléter
     */
    private static void fillCPQQuoteContext(NRV10CommissionContext context) {
        System.debug('## Loading quote context');

        //get orders for amendment quotes
        List<Id> amendedOrderIds = new List<Id>();

        //List orders associated to quotes
        System.debug('  -> Load quotes with Ids: ' + context.quoteIds + ' and in amended quoteIds ' + context.amendmentQuoteIds);
        List<Id> quoteAndAmendIds = new List<Id>();
        quoteAndAmendIds.addAll(context.quoteIds);
        quoteAndAmendIds.addAll(context.amendmentQuoteIds);
        for(Order o : [SELECT Id, Name, RecordTypeId, SBQQ__Quote__c, Status, amendmentQuote__c, parentOrder__r.SBQQ__Quote__c, SBQQ__Quote__r.previousQuote__c, providerOrderCount__c,
                confirmedOrderItemCount__c, InitialQuote__c, Type, (SELECT Id, SBQQ__QuoteLine__c FROM OrderItems) FROM Order WHERE SBQQ__Quote__c IN :quoteAndAmendIds OR parentOrder__r.SBQQ__Quote__c IN :quoteAndAmendIds]) {

            System.debug('      Got order ' + o);
            if (o.SBQQ__Quote__c == null) o.SBQQ__Quote__c = o.parentOrder__r.SBQQ__Quote__c;
            if (!context.quoteOrdersMap.containsKey(o.SBQQ__Quote__c)) {
                context.quoteOrdersMap.put(o.SBQQ__Quote__c, new List<Order>());
            }
            for (OrderItem oi : o.OrderItems) {
                if (!context.quoteLineOrderProductsMap.containsKey(oi.SBQQ__QuoteLine__c)) {
                    context.quoteLineOrderProductsMap.put(oi.SBQQ__QuoteLine__c, oi.Id);
                }
            }
            context.quoteOrdersMap.get(o.SBQQ__Quote__c).add(o);
            System.debug('o.Id: ' + o.Id);
            System.debug('o.SBQQ__Quote__c: ' + o.SBQQ__Quote__c);
            System.debug('order: ' + o);
            System.debug('o.amendmentQuote__c: ' + o.amendmentQuote__c);
            System.debug('context.amendmentQuoteIds: ' + context.amendmentQuoteIds);
            System.debug('context.amendmentQuoteIds.contains(o.SBQQ__Quote__c): ' + context.amendmentQuoteIds.contains(o.SBQQ__Quote__c));
            //if the order has a reference to the quote as an amendment, add initial quote ref to a list
            if (o.amendmentQuote__c != null && context.amendmentQuoteIds.contains(o.SBQQ__Quote__c)) {
                if (!amendedOrderIds.contains(o.Id)) amendedOrderIds.add(o.Id);
            }
            if (o.amendmentQuote__c != null && context.amendmentQuoteIds.contains(o.SBQQ__Quote__r.previousQuote__c)) {
                if (!amendedOrderIds.contains(o.Id)) amendedOrderIds.add(o.Id);
            }
        }

        // JMU 12/04/2023 - Equilibrage pour CPQ : Modification de la map amendedOrderQuotesMap pour qu'elle soit plus permissive.
        // Désormais, on va chercher TOUS les devis rattachés à la commande initiale (via champ customerOrder__c)
        // Pour bien annuler ceux des devis précédents

        //load all quotes related to amended orders (including intermediary amendments)
        System.debug('  -> Load amended quotes for orders: ' + amendedOrderIds);
        for (SBQQ__Quote__c qu : [SELECT Id, MontantTotalTTC__c, SBQQ__CustomerAmount__c, SBQQ__ListAmount__c,
                SBQQ__Status__c, AmendmentQuote__c, spilledCustomerOrder__c, commStatus__c,
                dateAcceptationClient__c, amendInitialQuote__c, previousQuote__c, customerOrder__c,
                ecartCotation__c, ecartCotationPercent__c, MontantTotalHTpostBP__c, opportunityOwner__c,
                dateTransmissionClient__c, OwnerId, financingMethod__r.Name, referenceDate__c,
                SBQQ__DistributorDiscount__c FROM SBQQ__Quote__c
                WHERE spilledCustomerOrder__c IN : amendedOrderIds OR customerOrder__c IN : amendedOrderIds]){ //techRemVRP__c,
            //do not add initial processing quotes (amendment quotes) in the amendment quotes map
            if (context.quoteIds.contains(qu.Id)) continue;

            //but add the amended quotes
            System.debug('    -> Adding the quote to the amended list ' + qu);
            if (qu.opportunityOwner__c != null && !context.ownerIds.contains(qu.opportunityOwner__c)) {
                context.ownerIds.add(qu.opportunityOwner__c);
                context.quoteInfos.add(new QuoteTransformer(qu));
            }
            if (!context.amendedOrderQuotesMap.containsKey(qu.customerOrder__c)) {
                context.amendedOrderQuotesMap.put(qu.customerOrder__c, new List<QuoteTransformer>());
            }
            context.amendedOrderQuotesMap.get(qu.customerOrder__c).add(new QuoteTransformer(qu));
            //add quote Id to the list to get amended quotelines
            context.quoteIds.add(qu.Id);
        }

        // get all quotes and related quotelines
        System.debug('  -> Load quote lines for quotes with Ids: ' + context.quoteIds);
        for(SBQQ__QuoteLine__c quoteLine : [SELECT Id, SBQQ__Quote__c, SBQQ__CustomerTotal__c, SBQQ__PackageTotal__c,
                SBQQ__Product__c, QuoteLineNetUnitPrice__c, parentQuoteLine__c, amendInitialQuoteline__c,
                SBQQ__Quantity__c, TauxTVAPercent__c, SBQQ__ProductCode__c, LibelleProduit__c, parentQuoteLine__r.SBQQ__Quote__c
                    FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :context.quoteIds AND SBQQ__Bundle__c = TRUE]) {
        
            if(quoteLine.parentQuoteLine__c == null || (quoteLine.parentQuoteLine__c != null && 
                quoteLine.SBQQ__Quote__c != quoteLine.parentQuoteLine__r.SBQQ__Quote__c)){
                if (!context.quoteQuoteLinesMap.containsKey(quoteLine.SBQQ__Quote__c)) {
                    context.quoteQuoteLinesMap.put(quoteLine.SBQQ__Quote__c, new List<QuoteLineTransformer>());
                }
                System.debug('    -> Add the quote line for quote Id: ' + quoteLine.SBQQ__Quote__c + ' ql: ' + quoteLine);
                context.quoteQuoteLinesMap.get(quoteLine.SBQQ__Quote__c).add(new QuoteLineTransformer(quoteLine));
                if (!context.productIds.contains(quoteLine.SBQQ__Product__c)) context.productIds.add(quoteLine.SBQQ__Product__c);
                context.quoteLineIds.add(quoteLine.Id);
            }
        }
        

        //get all product rates for remuneration rates
        System.debug('  -> Load products used by quotelines with Ids: ' + context.productIds);
        for(NRV10ProductRate__c p : [SELECT Id, product__c, salesrate__c FROM NRV10ProductRate__c WHERE
                product__c IN :context.productIds]) {
            if (!context.productRatesMap.containsKey(p.salesrate__c)) {
                context.productRatesMap.put(p.salesrate__c, new List<Id>());
            }
            context.productRatesMap.get(p.salesrate__c).add(p.product__c);
        }
    }

    /**
     * Prepare le contexte relatif aux devis/avenants sales
     *
     * @param context Contexte d'entrée à compléter
     */
    private static void fillSalesQuoteContext(NRV10CommissionContext context) {
        System.debug('## Loading sales quote context');

        //get orders for amendment quotes
        List<Id> amendedOrderIds = new List<Id>();

        //List orders associated to quotes
        System.debug('  -> Load quotes with Ids: ' + context.quoteIds + ' and in amended quoteIds ' + context.amendmentQuoteIds);
        List<Id> quoteAndAmendIds = new List<Id>();
        quoteAndAmendIds.addAll(context.quoteIds);
        quoteAndAmendIds.addAll(context.amendmentQuoteIds);
        for(Order o : [SELECT Id, Name, RecordTypeId, QuoteId, Status, amendmentQuote__c, ParentOrder__c, parentOrder__r.QuoteId, 
                Quote.previousQuote__c, providerOrderCount__c, Quote.customerOrder__c,
                confirmedOrderItemCount__c, InitialQuote__c, Type, (SELECT Id, QuoteLineItemId FROM OrderItems) FROM Order WHERE QuoteId IN :quoteAndAmendIds OR parentOrder__r.QuoteId IN :quoteAndAmendIds]) {

            System.debug('      Got order ' + o);
            if (o.QuoteId == null) o.QuoteId = o.parentOrder__r.QuoteId;
            if (!context.quoteOrdersMap.containsKey(o.QuoteId)) {
                context.quoteOrdersMap.put(o.QuoteId, new List<Order>());
            }
            for (OrderItem oi : o.OrderItems) {
                if (!context.quoteLineOrderProductsMap.containsKey(oi.QuoteLineItemId)) {
                    context.quoteLineOrderProductsMap.put(oi.QuoteLineItemId, oi.Id);
                }
            }
            // Fix 15/06/2023 JMU : Commandes fournisseurs issues de la commande initiale récupérées
            System.debug('o.parentOrder__r.QuoteId: ' + o.parentOrder__r.QuoteId);
            System.debug('o.parentOrder__c: ' + o.parentOrder__c);
            System.debug('context: ' + context);
            System.debug('context.quoteOrdersMap: ' + context.quoteOrdersMap);
            System.debug('context.quoteOrdersMap.get(o.parentOrder__r.QuoteId): ' + context.quoteOrdersMap.get(o.parentOrder__r.QuoteId));
            if(o.RecordTypeId == TR022_SBQQ_Quote.orderCmdProviderRtId && o.parentOrder__c == o.Quote.customerOrder__c){
                context.quoteOrdersMap.get(o.parentOrder__r.QuoteId).add(o);
            } else {
                context.quoteOrdersMap.get(o.QuoteId).add(o);
            }
            System.debug('o.Id: ' + o.Id);
            System.debug('o.QuoteId: ' + o.QuoteId);
            System.debug('order: ' + o);
            System.debug('o.amendmentQuote__c: ' + o.amendmentQuote__c);
            System.debug('context.amendmentQuoteIds: ' + context.amendmentQuoteIds);
            System.debug('context.amendmentQuoteIds.contains(o.QuoteId): ' + context.amendmentQuoteIds.contains(o.QuoteId));
            System.debug('o.Quote.previousQuote__c: ' + o.Quote.previousQuote__c);
            //if the order has a reference to the quote as an amendment, add initial quote ref to a list
            if (context.amendmentQuoteIds.contains(o.QuoteId)) {
                if (!amendedOrderIds.contains(o.Id)) amendedOrderIds.add(o.Id);
            }
            if (context.amendmentQuoteIds.contains(o.Quote.previousQuote__c)) {
                if (!amendedOrderIds.contains(o.Id)) amendedOrderIds.add(o.Id);
            }
        }

        // JMU 14/12/2022 - SUIVI MEP 402 : Modification de la map amendedOrderQuotesMap pour qu'elle soit plus permissive.
        // Désormais, on va chercher TOUS les devis rattachés à la commande initiale (via champ customerOrder__c)
        // Pour bien annuler ceux des devis précédents

        //load all quotes related to amended orders (including intermediary amendments)
        System.debug('  -> Load amended quotes for orders: ' + amendedOrderIds);
        for (Quote qu : [SELECT Id, TotalTTCTarif__c, TotalHTlignes__c, TotalTTClignes__c,
                Status, amendmentQuote__c, spilledCustomerOrder__c, commStatus__c, RemisevendeurglobaleFormule__c,
                dateAcceptationClient__c, amendInitialQuote__c, previousQuote__c, TotalHTTarif__c,
                TotalHTRemise__c, dateTransmissionClient__c, OwnerId, modeFinancement__c, referenceDate__c, 
                opportunityOwner__c, TotalHTDevis__c, customerOrder__c
                FROM Quote WHERE customerOrder__c IN : amendedOrderIds]){
            //do not add initial processing quotes (amendment quotes) in the amendment quotes map
            if (context.quoteIds.contains(qu.Id)) continue;

            //but add the amended quotes
            System.debug('    -> Adding the quote to the amended list ' + qu);
            if (qu.opportunityOwner__c != null /*&& !context.oppOwnerIds.contains(qu.opportunityOwner__c)*/) {
                //context.oppOwnerIds.add(qu.opportunityOwner__c);
            }
            context.quoteInfos.add(new QuoteTransformer(qu));
            if (!context.amendedOrderQuotesMap.containsKey(qu.customerOrder__c)) {
                context.amendedOrderQuotesMap.put(qu.customerOrder__c, new List<QuoteTransformer>());
            }
            context.amendedOrderQuotesMap.get(qu.customerOrder__c).add(new QuoteTransformer(qu));
            //add quote Id to the list to get amended quotelines
            context.quoteIds.add(qu.Id);
        }

        // get all quotes and related quotelines
        System.debug('  -> Load quote lines for quotes with Ids: ' + context.quoteIds);
        for(QuoteLineItem quoteLineItem : [SELECT Id, QuoteId, TotalTTCligne__c,
                Product2Id, PrixTTCtarif__c, amendInitialQuoteline__c, prixHTTarifRemise__c,
                Quantity, TVApourcentage__c, productCode__c, prixUnitaireHTRemise__c,
                productName__c FROM QuoteLineItem WHERE QuoteId IN :context.quoteIds AND cancelledLine__c = false]) {

            if (!context.quoteQuoteLinesMap.containsKey(quoteLineItem.QuoteId)) {
                context.quoteQuoteLinesMap.put(quoteLineItem.QuoteId, new List<QuoteLineTransformer>());
            }
            System.debug('    -> Add the quote line for quote Id: ' + quoteLineItem.QuoteId + ' ql: ' + quoteLineItem);
            context.quoteQuoteLinesMap.get(quoteLineItem.QuoteId).add(new QuoteLineTransformer(quoteLineItem));
            if (!context.productIds.contains(quoteLineItem.Product2Id)) context.productIds.add(quoteLineItem.Product2Id);
            context.quoteLineIds.add(quoteLineItem.Id);
        }

        //get all product rates for remuneration rates
        System.debug('  -> Load products used by quotelines with Ids: ' + context.productIds);
        for(NRV10ProductRate__c p : [SELECT Id, product__c, salesrate__c FROM NRV10ProductRate__c WHERE
                product__c IN :context.productIds]) {
            if (!context.productRatesMap.containsKey(p.salesrate__c)) {
                context.productRatesMap.put(p.salesrate__c, new List<Id>());
            }
            context.productRatesMap.get(p.salesrate__c).add(p.product__c);
        }
    }

    /**
     * @description Prepare le contexte relatif aux commissions sur quotes amendées
     *
     * @param context Contexte d'entrée à compléter
     */
    private static void deleteExistingCommissions(NRV10CommissionContext context) {
        // get existing commissions on quotelines
        List<NRV10Commission__c> comExistingList = new List<NRV10Commission__c>();
        comExistingList = [SELECT Id 
                            FROM NRV10Commission__c
                            WHERE quoteCPQ__c IN :context.quoteIds
                            OR quote__c IN :context.quoteIds];
        delete comExistingList;
    }

    /**
     * @description Prepare le contexte relatif aux commissions sur quotes amendées
     *
     * @param context Contexte d'entrée à compléter
     */
    private static void fillExistingCPQCommissions(NRV10CommissionContext context) {
        // get existing commissions on quotelines
        for (NRV10Commission__c commission : [SELECT Id, status__c, user__c, comType__c,
                quoteCPQ__c, quoteLine__c,
                quoteLine__r.amendInitialQuoteline__c, quoteLine__r.SBQQ__Quantity__c,
                remuneration__c, customValue__c, ecPercent__c, productRate__c,
                discountCoefficient__c, teamRate__c, salesRem__c, turnoverLevel__c,
                financingMethodName__c, rate__c, quantity__c, unitPrice__c,
                ratingAmount__c, ec__c, repartPercent__c, totalAmountTTC__c, amountHT__c, store__c,
                initialCPQQuote__c, initialCPQQuoteLine__c, orderProduct__c,
                sellingPrice__c, customerOrder__c, instantDate__c FROM NRV10Commission__c WHERE quoteCPQ__c IN :context.quoteIds]) {

            // commission can be attached to a quoteline (sales commission) or a quote (malus)
            Id keyIdOrigin;
            if (commission.initialCPQQuote__c != null || commission.initialCPQQuoteLine__c != null) {
                keyIdOrigin = commission.initialCPQQuoteLine__c != null ?
                        commission.initialCPQQuoteLine__c :
                        commission.initialCPQQuote__c;

                if (commission.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                    if (!context.originQuotelineCommissionMap.containsKey(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c)) {
                        context.originQuotelineCommissionMap.put(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c, new List<NRV10Commission__c>());
                    }
                    System.debug(' add team commission to map related to its initial Quoteline ' + keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c);
                    context.originQuotelineCommissionMap.get(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c).add(commission);
                }else {
                    if (!context.originQuotelineCommissionMap.containsKey(keyIdOrigin + '-' + commission.comType__c)) {
                        context.originQuotelineCommissionMap.put(keyIdOrigin + '-' + commission.comType__c, new List<NRV10Commission__c>());
                    }
                    System.debug(' add commission to map related to its initial Quoteline ' + keyIdOrigin + '-' + commission.comType__c);
                    context.originQuotelineCommissionMap.get(keyIdOrigin + '-' + commission.comType__c).add(commission);
                }
            }

            Id keyId = commission.quoteLine__c;
            if (keyId == null) {
                if (context.isCPQ && commission.quoteCPQ__c != null) {
                    keyId = commission.quoteCPQ__c;
                } else if (!context.isCPQ && commission.quote__c != null) {
                    keyId = commission.quote__c;
                } else {
                    keyId = '';
                }
            }

            if (commission.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                context.commissionMap.put(keyId + '_' + commission.comType__c + '_' + commission.user__c, commission);
            }else {
                context.commissionMap.put(keyId + '_' + commission.comType__c, commission);
            }
        }
    }

    /**
     * @description Prepare le contexte relatif aux commissions sur quotes amendées
     *
     * @param context Contexte d'entrée à compléter
     */
    private static void fillExistingSalesCommissions(NRV10CommissionContext context) {
        // get existing commissions on quotelines
        for (NRV10Commission__c commission : [SELECT Id, status__c, user__c, comType__c,
                quote__c, quoteLineItem__c, quoteCPQ__c,
                quoteLineItem__r.amendInitialQuoteline__c, quoteLineItem__r.Quantity,
                remuneration__c, customValue__c, ecPercent__c, productRate__c,
                discountCoefficient__c, teamRate__c, salesRem__c, turnoverLevel__c,
                financingMethodName__c, rate__c, quantity__c, unitPrice__c,
                ratingAmount__c, ec__c, repartPercent__c, totalAmountTTC__c, amountHT__c, store__c,
                initialQuote__c, initialQuoteline__c, orderProduct__c,
                sellingPrice__c, customerOrder__c, instantDate__c FROM NRV10Commission__c WHERE quote__c IN :context.quoteIds]) {

            // commission can be attached to a quoteline (sales commission) or a quote (malus)
            Id keyIdOrigin;
            if (commission.initialQuote__c != null || commission.initialQuoteline__c != null) {
                keyIdOrigin = commission.initialQuoteline__c != null ?
                        commission.initialQuoteline__c :
                        commission.initialQuote__c;

                if (commission.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                    if (!context.originQuotelineCommissionMap.containsKey(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c)) {
                        context.originQuotelineCommissionMap.put(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c, new List<NRV10Commission__c>());
                    }
                    System.debug(' add team commission to map related to its initial Quoteline ' + keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c);
                    context.originQuotelineCommissionMap.get(keyIdOrigin + '-' + commission.comType__c + '-' + commission.user__c).add(commission);
                }else {
                    if (!context.originQuotelineCommissionMap.containsKey(keyIdOrigin + '-' + commission.comType__c)) {
                        context.originQuotelineCommissionMap.put(keyIdOrigin + '-' + commission.comType__c, new List<NRV10Commission__c>());
                    }
                    System.debug(' add commission to map related to its initial Quoteline ' + keyIdOrigin + '-' + commission.comType__c);
                    context.originQuotelineCommissionMap.get(keyIdOrigin + '-' + commission.comType__c).add(commission);
                }
            }

            Id keyId = commission.quoteLineItem__c;
            if (keyId == null) {
                if (commission.quote__c != null) {
                    keyId = commission.quote__c;
                } else {
                    keyId = '';
                }
            }

            if (commission.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                context.commissionMap.put(keyId + '_' + commission.comType__c + '_' + commission.user__c, commission);
            }else {
                context.commissionMap.put(keyId + '_' + commission.comType__c, commission);
            }
        }
    }

    /**
     * Prepare le contexte relatif aux collaborateurs depuis la liste des oppOwnersIds de ce même contexte
     *
     * @param context Contexte d'entrée à compléter
     */
    @TestVisible
    private static void fillCollaboratorContext(NRV10CommissionContext context) {
        System.debug('## Load collaborator context for collaborators Ids: ' + context.oppOwnerIds);
        //get collaborators associated to quotes
        for (Collaborator__c collaborator : [SELECT Id, user__c, Name, reference__c, job__r.jobHierarchy__r.Name FROM Collaborator__c
                WHERE user__c IN :context.oppOwnerIds]) {
            context.collaboratorsMap.put(collaborator.user__c, collaborator);
            context.collaboratorJobHierarchyMap.put(collaborator.Id, collaborator.job__r.jobHierarchy__r.Name);
            if (collaborator.reference__c != null) context.collaboratorSGIds.add(collaborator.reference__c);
            context.collaboratorIds.add(collaborator.Id);
            if (collaborator.reference__c != null) context.collabIdSgIdMap.put(collaborator.Id, collaborator.reference__c);
        }

        System.debug('  -> load remuneration contracts for ' + context.collaboratorIds.size() + ' collaborators ' + context.collaboratorIds);
        //get collaborators employment contracts
        for (NRV10RemunerationContract__c contract : [SELECT Id, collaborator__c, employmentContractType__c,
                employmentContractType__r.teamGridRevision__c, signatureDate__c, endDate__c, assignedTo__c,
                contract__r.collaborator__c, contract__r.collaborator__r.user__c , startDate__c
             FROM NRV10RemunerationContract__c 
             WHERE contract__r.collaborator__c IN :context.collaboratorIds]) {

            System.debug('## FOR THE CONTRACT: ' + contract);
            Boolean collabAlreadyAdded = false;
            for(QuoteTransformer q : context.quoteInfos){
                System.debug('## collabAlreadyAdded: ' + collabAlreadyAdded);
                System.debug('## q.OwnerId: ' + q.OwnerId);
                System.debug('## q.opportunityOwner__c: ' + q.OppOwnerId);
                System.debug('## contract.contract__r.collaborator__r.user__c: ' + contract.contract__r.collaborator__r.user__c);
                System.debug('## contract.startDate__c: ' + contract.startDate__c);
                System.debug('## q.ReferenceDate: ' + q.ReferenceDate);
                System.debug('## contract.endDate__c: ' + contract.endDate__c);
                if(!collabAlreadyAdded && q.OppOwnerId == contract.contract__r.collaborator__r.user__c  && contract.startDate__c < q.ReferenceDate
                && (contract.endDate__c == null || contract.endDate__c > q.ReferenceDate)){
                    System.debug('      Add remuneration contract to map: ' + contract);
                    if (!context.collaboratorContractMap.containsKey(contract.contract__r.collaborator__c)) {
                        context.collaboratorContractMap.put(contract.contract__r.collaborator__c, new List<NRV10RemunerationContract__c>());
                    }
                    context.collaboratorContractMap.get(contract.contract__r.collaborator__c).add(contract);
                    context.ctRevGridIds.add(contract.employmentContractType__c);
                    context.storeIds.add(contract.assignedTo__c);
                    collabAlreadyAdded = true;
                }
            }
        }

        System.debug('  -> load managers of ' + context.storeIds.size() + ' stores');
        for (NRV10RemunerationContract__c a : [SELECT Id, collaborator__c, employmentContractType__c, startDate__c,
                employmentContractType__r.teamGridRevision__c, signatureDate__c, endDate__c, assignedTo__c,
                contract__r.collaborator__c FROM NRV10RemunerationContract__c WHERE
                contract__r.assignedTo__c IN :context.storeIds AND employmentContractType__r.teamGridRevision__c <> '']) {

            if  (!context.managerAssignmentsMap.containsKey(a.assignedTo__c)) {
                context.managerAssignmentsMap.put(a.assignedTo__c, new List<Id>());
            }
            context.managerAssignmentsMap.get(a.assignedTo__c).add(a.collaborator__c);
            if (!context.managerIds.contains(a.collaborator__c)) context.managerIds.add(a.collaborator__c);

            System.debug('      Add Remuneration contract to map: ' + a);
            if (!context.collaboratorContractMap.containsKey(a.contract__r.collaborator__c)) {
                context.collaboratorContractMap.put(a.contract__r.collaborator__c, new List<NRV10RemunerationContract__c>());
            }
            context.collaboratorContractMap.get(a.contract__r.collaborator__c).add(a);
            context.ctRevGridIds.add(a.employmentContractType__c);
        }

        // list managers collaborator object
        for (Collaborator__c collaborator : [SELECT Id, user__c, Name, reference__c, job__r.jobHierarchy__r.Name FROM Collaborator__c
        WHERE Id IN :context.managerIds]) {
            context.managersMap.put(collaborator.Id, collaborator);
        }

        //get collaborators employment contracts for managers
        System.debug('  -> load remuneration contracts of ' + context.managerIds.size() + ' managers');

        System.debug('  -> load Grid revisions of collaborators contracts for Ids: ' + context.ctRevGridIds);
        //get contracts grid revisions
        for (NRV10GridRevision__c contractRevision : [SELECT Id, salesGridRevision__c, teamGridRevision__c,
                discountGridRevision__c, bonusGridRevision__c, malusGridRevision__c FROM NRV10GridRevision__c
                WHERE Id IN :context.ctRevGridIds]) {
            context.contractRevisionsMap.put(contractRevision.Id, contractRevision);
            if (contractRevision.teamGridRevision__c != null
                    && !context.subRevGridIds.contains(contractRevision.teamGridRevision__c)) {
                context.subRevGridIds.add(contractRevision.teamGridRevision__c);
            }
            if (contractRevision.salesGridRevision__c != null
                    && !context.subRevGridIds.contains(contractRevision.salesGridRevision__c)) {
                context.subRevGridIds.add(contractRevision.salesGridRevision__c);
            }
            if (contractRevision.discountGridRevision__c != null
                    && !context.subRevGridIds.contains(contractRevision.discountGridRevision__c)) {
                context.subRevGridIds.add(contractRevision.discountGridRevision__c);
            }
            if (contractRevision.bonusGridRevision__c != null
                    && !context.subRevGridIds.contains(contractRevision.bonusGridRevision__c)) {
                context.subRevGridIds.add(contractRevision.bonusGridRevision__c);
            }
            if (contractRevision.malusGridRevision__c != null
                    && !context.subRevGridIds.contains(contractRevision.malusGridRevision__c)) {
                context.subRevGridIds.add(contractRevision.malusGridRevision__c);
            }
        }

        System.debug('  -> load associated grid revisions');
        //get linked grid revisions
        for (NRV10GridRevision__c subRev : [SELECT Id, defaultRate__c FROM NRV10GridRevision__c
                WHERE Id IN :context.subRevGridIds]) {
            context.subRevGridsMap.put(subRev.Id, subRev);
        }

        System.debug('  -> load remuneration rates of ' + context.subRevGridIds.size() + ' contracts related grid revisions');
        //get remuneration rates for each grid revision
        System.debug('    -> ids : ' + context.subRevGridIds);
        for(NRV10RemunerationRate__c r : [SELECT Id, gridRevision__c, rate__c, ratingDifference__c,
                discountCoefficient__c, startDate__c, endDate__c, Name, bonusAmount__c, turnoverLevel__c,
                financingMethod__r.Name FROM NRV10RemunerationRate__c
                WHERE gridRevision__c IN :context.subRevGridIds ORDER BY ratingDifference__c ASC]) {
            System.debug('    -> add remuneration rates: ' + r);
            if (!context.remunerationRatesGridMap.containsKey(r.gridRevision__c)) {
                context.remunerationRatesGridMap.put(r.gridRevision__c, new List<NRV10RemunerationRate__c>());
            }
            context.remunerationRatesMap.put(r.Id, r);
            context.remunerationRatesGridMap.get(r.gridRevision__c).add(r);
        }

    }
}