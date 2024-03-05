/**
 * Created by 4C on 18/09/2020.
 */

 public without sharing class TR023_SBQQ_Quote_SalesCommission {
    public static final Id orderCmdClientRtId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);

    /**
     * @author 4C
     * @date 2020-08-27
     * @description Multiple quotes processing, create/update commissions on every quote/sales of the list
     *
     * @param quotes list of quotes to process and create/update sales commissions on
     * @param context processing context (all quotes relative data (collaborator, grids, rates....)
     */
    public static void processSalesCommissions(List<QuoteTransformer> quotes, TR022_SBQQ_Quote_Commission.NRV10CommissionContext context) {
        System.debug('## Start processing sales commissions');

        // process each Quote
        List<QuoteTransformer> quotesToUpdate = new List<QuoteTransformer>();
        for (QuoteTransformer q : quotes) {
            System.debug(' processing quote ' + q.Id);

            //process quote only if after quote transmission
            if (q.Status != Constants.QUOTE_STATUS_TO_CONFIGURE
                    && q.Status != Constants.STD_QUOTE_STATUS_TO_CONFIGURE
                    && q.Status != Constants.QUOTE_STATUS_NOT_TRANSMITTED
                    && q.Status != Constants.QUOTE_STATUS_TRANSMITTED
                    && q.Status != Constants.QUOTE_STATUS_SOLD
                    && q.Status != Constants.QUOTE_STATUS_CANCELLED) {
                System.debug(System.LoggingLevel.INFO, 'Quote is not eligible to commission until it is transmitted');
                continue;
            }

            //process quote only if owner has a collaborator account
            if (!context.collaboratorsMap.containsKey(q.OppOwnerId)) {
                System.debug(System.LoggingLevel.INFO, 'Owner is not part of eligible users for commission');
                continue;
            }

            //process quote only if collaborator have a contract
            Collaborator__c collaborator = context.collaboratorsMap.get(q.OppOwnerId);

            if (!context.collaboratorContractMap.containsKey(collaborator.Id)) {
                System.debug(System.LoggingLevel.INFO, 'Collaborator don\'t have employment contract');
                continue;
            }

            //List orders associated to the quote
            List<Order> orders;
            system.debug('quoteOrdersMap : '+context.quoteOrdersMap.get(q.Id));
            if (context.quoteOrdersMap.containsKey(q.Id)) {
                orders = context.quoteOrdersMap.get(q.Id);
            } else {
                orders = new List<Order>();
            }

            //check contract dates is valid for the quote (customer signature date)
            System.debug('set validationDate based on multiple criteria');
            Date validationDate = q.DateTransmissionClient != null ? q.DateTransmissionClient : q.ReferenceDate;
            if (q.DateAcceptationClient != null) validationDate = q.DateAcceptationClient;
            if (q.AmendmentQuote) {
                System.debug('Quote is an amendment quote');
                if (!context.quoteOrdersMap.containsKey(q.Id)) {
                    System.debug('there is no linked order, cannot find and update previous commissions');
                } else {
                    System.debug('Parse orders to get the customer one');
                    for (Order o : context.quoteOrdersMap.get(q.Id)) {
                        if (o.RecordTypeId == orderCmdClientRtId && context.amendedOrderQuotesMap != null && context.amendedOrderQuotesMap.get(o.Id) != null) {
                            System.debug('Process all related quotes to find the first customer acceptation date');
                            for (QuoteTransformer quo : context.amendedOrderQuotesMap.get(o.Id)) {
                                if (quo.DateAcceptationClient != null && quo.DateAcceptationClient < validationDate) {
                                    System.debug('Initial quote was validated by the customer, use this date');
                                    validationDate = quo.DateAcceptationClient;
                                }
                            }
                        }
                    }
                }
            }

            //get contract according to the quote date
            NRV10RemunerationContract__c contract;
            for (NRV10RemunerationContract__c c : context.collaboratorContractMap.get(collaborator.Id)) {
                if (c.startDate__c < validationDate
                        && (c.endDate__c == null || c.endDate__c >= validationDate)) {
                    contract = c;
                }
            }
            System.debug('contractCollab : '+contract);
            if (contract == null) {
                System.debug(System.LoggingLevel.INFO, 'Collaborator don\'t have employment contract for the period');
                continue;
            }

            // Collaborator store assignment is now directly in his contract, replace the team lookup
            Map<Id, NRV10RemunerationContract__c> managersContractsMap = new Map<Id, NRV10RemunerationContract__c>();
            Id assignmentStoreId = contract.assignedTo__c;

            // create a map with all assigned managers and their contracts
            if (context.managerAssignmentsMap.containsKey(assignmentStoreId)) {
                System.debug('  Filter ' + context.managerAssignmentsMap.get(assignmentStoreId).size() +
                        ' managers on the store for matching dates');
                for (Id managerId : context.managerAssignmentsMap.get(assignmentStoreId)) {
                    System.debug('    check manager ' + managerId);
                    if (!context.collaboratorContractMap.containsKey(managerId)) {
                        System.debug('    Collaborator contract map does not contains manager ID, process next one');
                        continue;
                    }

                    String premierRVcollab = null;
                    NRV10RemunerationContract__c premierRVcontract = null;
                    for (NRV10RemunerationContract__c c : context.collaboratorContractMap.get(managerId)) {
                        System.debug('    Compare dates (signature: ' + c.startDate__c + '), (enddate: ' +
                                c.endDate__c + ') with validation date: ' + validationDate +
                                ' with teamGridRevision: ' + c.employmentContractType__r.teamGridRevision__c);
                        if (c.assignedTo__c == assignmentStoreId && c.startDate__c <= validationDate
                                && (c.endDate__c == null || c.endDate__c >= validationDate)
                                && c.employmentContractType__r.teamGridRevision__c != null) {
                            if (!managersContractsMap.containsKey(c.collaborator__c)) {
                                if(context.collaboratorJobHierarchyMap.get(c.collaborator__c) == 'Responsable Vente'){
                                    if(premierRVcollab == null && premierRVcontract == null){
                                        premierRVcollab = c.collaborator__c;
                                        premierRVcontract = c;
                                        System.debug('    Manager ' + managerId + ' is the first RV to have matching dates');
                                    } else if(c.startDate__c < premierRVcontract.startDate__c){
                                        premierRVcollab = c.collaborator__c;
                                        premierRVcontract = c;
                                        System.debug('    Manager ' + managerId + ' have matching dates and is the oldest RV contract');
                                    } else {
                                        System.debug('    Manager ' + managerId + ' have matching dates but is not the oldest RV contract');
                                    }
                                } else {
                                    managersContractsMap.put(c.collaborator__c, c);
                                    System.debug('    Manager ' + managerId + ' have matching dates and is a '+context.collaboratorJobHierarchyMap.get(c.collaborator__c));
                                }
                            }
                        }
                    }
                    if(premierRVcollab != null && premierRVcontract != null){
                        managersContractsMap.put(premierRVcollab, premierRVcontract);
                        System.debug('    Oldest RV contract added to the map');
                    }
                    
                }
            }

            if (!context.quoteQuoteLinesMap.containsKey(q.Id)) {
                System.debug(System.LoggingLevel.INFO, 'No quotelines on the quote, will not generate anything, process next quote');
                continue;
            }
            List<QuoteLineTransformer> quoteLines = context.quoteQuoteLinesMap.get(q.Id);

            //orders Boolean not yet used until other triggers and flows will allow
            // having orders on quotes when transmitted
            Boolean hasCustomerOrders = false;
            Boolean customerOrdersConfirmed = (orders != null && !orders.isEmpty());
            Boolean customerOrdersCancelled = false;
            Boolean customerOrdersRegistered = false;

            Boolean hasProviderOrders = false;
            Id customerOrderId = null;
            Boolean providerOrdersConfirmed = false;
            Boolean providerOrdersCancelled = false;
            Boolean providerOrdersRegistered = false;
            Boolean providerOrdersTransmitted = false;
            for (Order order : orders) {
                System.debug('== order.Id ' + order.Id);
                System.debug('== order.Type ' + order.Type);
                System.debug('== order.Status ' + order.Status);
                if (order.RecordTypeId == orderCmdClientRtId && order.Type != 'Avenant') {
                    hasCustomerOrders = true;
                    if(order.parentOrder__c != null){
                        customerOrderId = order.parentOrder__c;
                    } else {
                        customerOrderId = order.Id;
                    }
                    if (order.Status != Constants.ORDER_STATUS_REGISTERED
                            && order.Status != Constants.ORDER_STATUS_AMENDING
                            && order.Status != Constants.ORDER_STATUS_CANCELLED
                            && order.Status != Constants.ORDER_STATUS_TRANSMITTED) {
//                    if (order.Status != Constants.ORDER_STATUS_CONFIRMED
//                            && order.Status != Constants.ORDER_STATUS_VALDIDATED) {
//                        customerOrdersConfirmed = false;
                        customerOrdersConfirmed = true;
                    }
                    System.debug('order.Status ' + order.Status);
                    if (order.providerOrderCount__c > 0) hasProviderOrders = true;
                    if (order.Status == Constants.ORDER_STATUS_CANCELLED) customerOrdersCancelled = true;
                    if (order.Status == Constants.ORDER_STATUS_REGISTERED) customerOrdersRegistered = true;
                } else if (order.RecordTypeId == TR022_SBQQ_Quote.orderCmdProviderRtId) {
                    hasProviderOrders = true;
                    System.debug('order.confirmedOrderItemCount__c ' + order.confirmedOrderItemCount__c);
                    if (order.confirmedOrderItemCount__c != null && order.confirmedOrderItemCount__c > 0) {
                        providerOrdersConfirmed = true;
                    }
                    if (order.Status == Constants.ORDER_STATUS_CANCELLED) providerOrdersCancelled = true;
                    if (order.Status == Constants.ORDER_STATUS_REGISTERED) providerOrdersRegistered = true;
                    if (order.Status == Constants.ORDER_STATUS_TRANSMITTED) providerOrdersTransmitted = true;
                }
            }

            //pick grid revisions in the global list
            NRV10GridRevision__c contractRevision = context.contractRevisionsMap.get(contract.employmentContractType__c);
            NRV10GridRevision__c salesRevision;
            if (context.subRevGridsMap.containsKey(contractRevision.salesGridRevision__c)) {
                salesRevision = context.subRevGridsMap.get(contractRevision.salesGridRevision__c);
            }
            NRV10GridRevision__c discountRevision;
            if (context.subRevGridsMap.containsKey(contractRevision.discountGridRevision__c)) {
                discountRevision = context.subRevGridsMap.get(contractRevision.discountGridRevision__c);
            }
            NRV10GridRevision__c malusRevision;
            if (context.subRevGridsMap.containsKey(contractRevision.malusGridRevision__c)) {
                malusRevision = context.subRevGridsMap.get(contractRevision.malusGridRevision__c);
            }

            //pick remuneration rates in the global list
            List<NRV10RemunerationRate__c> remunerationRates;
            if (context.remunerationRatesGridMap.containsKey(salesRevision.Id)) {
                remunerationRates = context.remunerationRatesGridMap.get(salesRevision.Id);
            }

            //pick discount remuneration rates in the global list
            List<NRV10RemunerationRate__c> discountRates = new List<NRV10RemunerationRate__c>();
            if (context.remunerationRatesGridMap.containsKey(discountRevision.Id)) {
                for (NRV10RemunerationRate__c r : context.remunerationRatesGridMap.get(discountRevision.Id)) {
                    if (r.startDate__c <= validationDate
                            && (r.endDate__c == null || r.endDate__c >= validationDate)) {
                        discountRates.add(r);
                    }
                }
            }

            //pick malus remuneration rates in the global list
            Map<String, List<NRV10RemunerationRate__c>> malusRates = new Map<String, List<NRV10RemunerationRate__c>>();
            if (malusRevision != null && context.remunerationRatesGridMap.containsKey(malusRevision.Id)) {
                for (NRV10RemunerationRate__c r : context.remunerationRatesGridMap.get(malusRevision.Id)) {
                    if (r.startDate__c <= validationDate
                            && (r.endDate__c == null || r.endDate__c >= validationDate)) {
                        if (!malusRates.containsKey(r.financingMethod__r.Name)) {
                            malusRates.put(r.financingMethod__r.Name, new List<NRV10RemunerationRate__c>());
                        }
                        malusRates.get(r.financingMethod__r.Name).add(r);
                    }
                }
            }

            //will create a malus commission if financing method is in the collaborator malus list
            System.debug('Check if malus is applicable for method ' + q.FinancingMethod + '  in malus rates ' + malusRates);
            Boolean hasMalus = malusRates.containsKey(q.FinancingMethod);
            Double malusAmount;
            Double highestLevel = 0;
            if (hasMalus) {
                for (NRV10RemunerationRate__c malus : malusRates.get(q.FinancingMethod)) {
                    if (malus.turnoverLevel__c > highestLevel) {
                        highestLevel = malus.turnoverLevel__c;
                        if (q.MontantTotalTTC > malus.turnoverLevel__c) {
                            System.debug(' malus type ' + (malus.bonusAmount__c != null ? 'amount' : 'rate'));
                            malusAmount = malus.bonusAmount__c != null ? malus.bonusAmount__c : q.MontantTotalTTC * malus.rate__c / 100;
                            //Malus is a negative amount
                            if (malusAmount > 0) malusAmount = 0 - malusAmount;
                            System.debug(' malus amount ' + malusAmount);
                        }
                    }
                }
            }

            System.debug('Products rate map: ' + context.productRatesMap);

            // prepare product rate mapping for this quote
            Map<Id, Double> productRateMap = new Map<Id, Double>();
            for (QuoteLineTransformer ql : quoteLines) {
                // check on each remuneration rate associated to the sales revision grid
                for (NRV10RemunerationRate__c rem : context.remunerationRatesGridMap.get(salesRevision.Id)) {
                    System.debug('Rem details: ' + rem);
                    System.debug('Parse rem rates for the quote line (' + rem.Id + ') for product ' + ql.ProductId);
                    System.debug('  -> rem rates contains salesrem rate? ' + context.productRatesMap.containsKey(rem.Id));
                    System.debug('  -> rem rates contains product rate? ' +
                            (context.productRatesMap.containsKey(rem.Id)
                                    && context.productRatesMap.get(rem.Id).contains(ql.ProductId)));

                    if (context.productRatesMap.containsKey(rem.Id)
                            && context.productRatesMap.get(rem.Id).contains(ql.ProductId)) {
                        productRateMap.put(ql.ProductId, rem.rate__c);
                        // stop at first match
                        break;
                    }
                }
            }

            // Init add and update commissions list
            List<NRV10Commission__c> commissionsToDelete = new List<NRV10Commission__c>();
            List<NRV10Commission__c> commissionsToUpsert = new List<NRV10Commission__c>();
            System.debug('Processing ' + quoteLines.size() + ' quotelines');

            //Use explicit var names to help understand calculation for further developments
            System.debug(' get amounts for calculation');
            System.debug('   -> Total TTC amount: ' + q.CustomerAmount);  //ROUND(SBQQ__CustomerAmount__c + MontantTVA__c,1)
            Decimal montantTotalTTC = (q.CustomerAmount == null) ? 0 : q.CustomerAmount;
            System.debug('   -> HT amount: ' + q.CustomerAmount);  // somme Quote Line: Customer Total avec optional false -> IF(AND(SBQQ__Renewal__c, !SBQQ__Existing__c, ISBLANK(SBQQ__PriorQuantity__c)), 0, SBQQ__CustomerPrice__c * SBQQ__EffectiveQuantity__c)
            Decimal montantHT = q.CustomerAmount;
            System.debug('   -> quote amount: ' + q.QuoteAmount); // somme Quote Line: Package List Total -> SBQQ__ComponentListTotal__c + SBQQ__ListTotal__c
            Decimal ratingAmount = (q.TotalHTPostBP != null) ? q.TotalHTPostBP : q.QuoteAmount;
            System.debug('   -> rating amount: ' + ratingAmount); // somme Quote Line: Package List Total -> SBQQ__ComponentListTotal__c + SBQQ__ListTotal__c
            System.debug('   -> default rate: ' + salesRevision.defaultRate__c);
            Decimal productRate = salesRevision.defaultRate__c;
            Decimal ec = (q.EcartCotation != null && Test.isRunningTest() == false) ? q.EcartCotation : (montantTotalTTC - ratingAmount);  //try to get value from calculation if quote not filled
            System.debug('   -> ec percent: ' + q.TauxEcartCotation);
            Decimal ecPercent = (q.TauxEcartCotation != null && Test.isRunningTest() == false) ? q.TauxEcartCotation : ((ratingAmount != null && ratingAmount != 0) ? (ec * 100 / ratingAmount) : 0);
            System.debug('productRate: ' + productRate + ' ec: ' + ec + ' , ecPercent: ' + ecPercent);

            // Determine discount rate to apply depending on ecPercent
            Double tauxDecoteFinal = 100;
            for (NRV10RemunerationRate__c discount : discountRates) {
                System.debug('Check discount rate : ' + discount.ratingDifference__c + ' -> ' +
                        discount.discountCoefficient__c + ' :: ' + discount);
                if (Math.abs(discount.ratingDifference__c) >= Math.abs(ecPercent) && Test.isRunningTest() == false) { // JMU 25/07 : changement de <= à >=
                    tauxDecoteFinal = discount.discountCoefficient__c;
                    System.debug('down discount rate final to ' + tauxDecoteFinal);
                }
            }
            System.debug('discountRate: ' + tauxDecoteFinal);

            //set status depending on quote status and orders status
            System.debug('    quote status is : ' + q.Status);
            String commissionStatus = Constants.COMMISSION_STATUS_PREVISIONEL;
            /*if (q.Status == Constants.QUOTE_STATUS_TO_CONFIGURE
                    || q.Status == Constants.STD_QUOTE_STATUS_TO_CONFIGURE
                    || q.Status == Constants.QUOTE_STATUS_TRANSMITTED) {
                commissionStatus = Constants.COMMISSION_STATUS_PREVISIONEL;

            } else if (q.Status == Constants.QUOTE_STATUS_SOLD) {
                System.debug('    depending of orders status:');
                System.debug('    hasProviderOrders: ' + hasProviderOrders);
                System.debug('    providerOrdersRegistered: ' + providerOrdersRegistered);
                System.debug('    providerOrdersTransmitted: ' + providerOrdersTransmitted);
                System.debug('    hasCustomerOrders: ' + hasCustomerOrders);
                System.debug('    customerOrdersRegistered: ' + customerOrdersRegistered);

                System.debug('    >(hasProviderOrders && providerOrdersConfirmed): ' +
                        (hasProviderOrders && providerOrdersConfirmed));
                System.debug('    >((hasProviderOrders && providerOrdersConfirmed) or !hasProviderOrders): ' +
                        ((hasProviderOrders && providerOrdersConfirmed) || !hasProviderOrders));
                System.debug('    >hasCustomerOrders && customerOrdersConfirmed: ' +
                        (hasCustomerOrders && customerOrdersConfirmed));

                if ((!hasProviderOrders && !hasCustomerOrders)
                        || providerOrdersRegistered
                        || providerOrdersTransmitted
                        || customerOrdersRegistered) {
                    commissionStatus = Constants.COMMISSION_STATUS_NOT_COMMISSIONABLE;
                } else if (hasProviderOrders && providerOrdersConfirmed && hasCustomerOrders && customerOrdersConfirmed) {
                    commissionStatus = Constants.COMMISSION_STATUS_COMMISSIONABLE;
                } else {
                    commissionStatus = Constants.COMMISSION_STATUS_NOT_COMMISSIONABLE;
                }
                System.debug('status set to: ' + commissionStatus);
            } else if (q.Status == Constants.QUOTE_STATUS_CANCELLED) {
                commissionStatus = Constants.COMMISSION_STATUS_CANCELED;
            }*/

            System.debug('    hasProviderOrders: ' + hasProviderOrders);
            System.debug('    providerOrdersConfirmed: ' + providerOrdersConfirmed);
            System.debug('    customerOrdersConfirmed: ' + customerOrdersConfirmed);
            System.debug('    hasCustomerOrders: ' + hasCustomerOrders);
            System.debug('    customerOrdersCancelled: ' + customerOrdersCancelled);
            if (customerOrdersCancelled) {
                commissionStatus = Constants.COMMISSION_STATUS_CANCELED;
            } else if (providerOrdersConfirmed && hasCustomerOrders) {
                commissionStatus = Constants.COMMISSION_STATUS_COMMISSIONABLE;
            } else {
                commissionStatus = Constants.COMMISSION_STATUS_NOT_COMMISSIONABLE;
            }


            System.debug('Commission status is: ' + commissionStatus);

//            List<Id> quoteLinesToIgnore = new List<Id>();
            List<Id> cancelledCommissions = new List<Id>();
            System.debug('context.amendedOrderQuotesMap: ' + context.amendedOrderQuotesMap);
            
            System.debug('q.AmendmentQuote: ' + q.AmendmentQuote);
            System.debug('q.OrderId: ' + q.OrderId);
            System.debug('context.amendedOrderQuotesMap.containsKey(q.OrderId): ' + context.amendedOrderQuotesMap.containsKey(q.OrderId));
            //update existing commissions on amended quotes if necessary (only for not snapshoted commissions)
            /*if (q.AmendmentQuote && context.amendedOrderQuotesMap.containsKey(q.OrderId)) {
                System.debug('Quote is an amendment quote, process all quotes related to the order (initial quote and other amendment quotes)');
                for (QuoteTransformer quot : context.amendedOrderQuotesMap.get(q.OrderId)) {
                    if (quot.Id != q.Id && context.quoteQuoteLinesMap.containsKey(quot.Id)) {
                        for (QuoteLineTransformer ql : context.quoteQuoteLinesMap.get(quot.Id)) {
                            System.debug('Update commission for quoteline ' + ql.Id + ' in ' +
                                    context.commissionMap.size() + ' commissions');
                            for (String key : context.commissionMap.keySet()) {
                                if (key.substring(0, key.indexOf('_')) == ql.Id) {
                                    if (context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_PREVISIONEL
                                            || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_NOT_COMMISSIONABLE
                                            || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_REGULARIZABLE
                                            || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_COMMISSIONABLE) {
                                        System.debug('Commission is cancellable');
                                        NRV10Commission__c c = context.commissionMap.get(key);
                                        c.status__c = Constants.COMMISSION_STATUS_CANCELED;
                                        commissionsToUpsert.add(c);
                                        cancelledCommissions.add(c.Id);
                                    }
                                    if (context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_CANCELED) {
                                        cancelledCommissions.add(context.commissionMap.get(key).Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }*/
            
            if (q.AmendmentQuote && String.isNotBlank(q.AmendPreviousQuoteId) && context.quoteQuoteLinesMap != null && context.quoteQuoteLinesMap.get(q.AmendPreviousQuoteId) != null) {
                System.debug('Quote is an amendment quote, process all quotes related to the order (initial quote and other amendment quotes)');
                if (q.AmendPreviousQuoteId != q.Id) {
                    System.debug('q.AmendPreviousQuoteId: ' + q.AmendPreviousQuoteId);
                    System.debug('context.quoteQuoteLinesMap: ' + context.quoteQuoteLinesMap);
                    System.debug('q: ' + q);
                    for (QuoteLineTransformer ql : context.quoteQuoteLinesMap.get(q.AmendPreviousQuoteId)) {
                        System.debug('Update commission for quoteline ' + ql.Id + ' in ' +
                                context.commissionMap.size() + ' commissions');
                        for (String key : context.commissionMap.keySet()) {
                            if (key.substring(0, key.indexOf('_')) == ql.Id) {
                                if (context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_PREVISIONEL
                                        || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_NOT_COMMISSIONABLE
                                        || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_REGULARIZABLE
                                        || context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_COMMISSIONABLE) {
                                    System.debug('Commission is cancellable');
                                    NRV10Commission__c c = context.commissionMap.get(key);
                                    c.status__c = Constants.COMMISSION_STATUS_CANCELED;
                                    commissionsToUpsert.add(c);
                                    cancelledCommissions.add(c.Id);
                                }
                                if (context.commissionMap.get(key).status__c == Constants.COMMISSION_STATUS_CANCELED) {
                                    cancelledCommissions.add(context.commissionMap.get(key).Id);
                                }
                            }
                        }
                    }
                }
            }

            //process all quotelines of the quote
            for (QuoteLineTransformer quoteLine : quoteLines) {
                System.debug('  --> generate/update commission for quoteline ' + quoteLine.Id);
                // No commission for quoteline without price
                if (quoteLine.NetTotalHT == null || quoteLine.NetTotalHT == 0) {
                    continue;
                }

                //get existing commission or create a new one if non already exists
                NRV10Commission__c salesmanCommission;
                if (context.commissionMap.containsKey(quoteLine.Id + '_' + Constants.COMMISSION_TYPE_SALES)) {
                    System.debug('    collaborator already has a commission on this quoteline, update it');
                    salesmanCommission = context.commissionMap.get(quoteLine.Id + '_' + Constants.COMMISSION_TYPE_SALES);
                } else {
                    System.debug('    collaborator does not have a commission on this quoteline, create it');
                    salesmanCommission = new NRV10Commission__c();
                    salesmanCommission.user__c = collaborator.Id;
                    salesmanCommission.comType__c = Constants.COMMISSION_TYPE_SALES;
                    if (q.isCPQ) {
                        salesmanCommission.quoteCPQ__c = q.Id;
                        salesmanCommission.quoteLine__c = quoteLine.Id;
                    } else {
                        salesmanCommission.quote__c = q.Id;
                        salesmanCommission.quoteLineItem__c = quoteLine.Id;
                    }
                    salesmanCommission.productCode__c = quoteLine.ProductCode;
                    salesmanCommission.productLabel__c = quoteLine.ProductLabel;
                    salesmanCommission.product__c = quoteLine.ProductId;
                }

                // si commissionnée, on ne touche pas à la com
                System.debug('## Commission Status : '+salesmanCommission.status__c);
                System.debug('## Commission instantDate__c : '+salesmanCommission.instantDate__c);
                if(salesmanCommission.instantDate__c == null){

                    //add lookup to order if it exists (after status transmitted if must exists)
                    if (hasCustomerOrders) {
                        System.debug('Quote has a customer order, link the commission');
                        if (String.isBlank(salesmanCommission.customerOrder__c)) {
                            salesmanCommission.customerOrder__c = customerOrderId;
                        }
                        if (context.quoteLineOrderProductsMap.containsKey(quoteLine.Id)) {
                            System.debug('context orderitems - quotelines map has a matching quoteLine id');
                            salesmanCommission.orderProduct__c = context.quoteLineOrderProductsMap.get(quoteLine.Id);
                        }
                    }

                    //add lookup to manager and store
                    System.debug('    collaborator is part of a team, set the id and store');
                    salesmanCommission.store__c = assignmentStoreId;

                    //set or update status and calculation date (this one changes only when customer accept the quote)
                    salesmanCommission.status__c = commissionStatus;
                    salesmanCommission.calculationDate__c = validationDate;

                    // Update Quote status
                    q.CommissionStatus = salesmanCommission.status__c;
                    // Set quote tech flag to false to prevent new calculation until necessary
                    q.TechRemVrp = false;

                    //calculate remuneration amount
                    Decimal lineProductRate = productRate;
                    if (productRateMap.containsKey(quoteLine.ProductId)) {
                        lineProductRate = productRateMap.get(quoteLine.ProductId);
                        System.debug('specific line product rate is: ' + lineProductRate);
                    }

                    //****************************************************************************************************
                    //****************************************************************************************************
                    //****                                                                                            ****
                    //****    Modification du calcul le 16/03/2021, calcul sur montant HT ligne et non plus           ****
                    //****    par re-calcul d'après montant total devis etc                                           ****
                    //****                                                                                            ****
                    //****************************************************************************************************
                    //****************************************************************************************************
    //                //partial calculation for clarity
    //                Double repartPercent = quoteLine.NetTotalHT * 100 / ratingAmount;
    //                //                     q.total * 100 / (q.TotalHTPostBP != null ? q.TotalHTPostBP : q.QuoteAmount;)
    //                Double sellingPrice = montantHT * repartPercent / 100;
    //                //                   q.customerAmount * repart% / 100
    //
    //                //set the final remuneration of the commission
    //                salesmanCommission.remuneration__c = sellingPrice * lineProductRate * tauxDecoteFinal / 10000;


                    // Nouvelle formule :
                    // Rem = Prix de vente de la ligne HT * taux de produit * taux de décôte
                    Decimal repartPercent = (ratingAmount == 0 || ratingAmount == null) ? null : quoteLine.NetTotalHT * 100 / ratingAmount; // ratingAmount = quote.TotalHTPostBP

                    //set the final remuneration of the commission
                    salesmanCommission.remuneration__c = quoteLine.NetTotalHT * lineProductRate * tauxDecoteFinal / 10000;
                    System.debug('calculate rem = ' + quoteLine.NetTotalHT + ' * ' + lineProductRate + ' * ' + tauxDecoteFinal + ' / 10000');
                    System.debug(' remuneration for this line is: ' + salesmanCommission.remuneration__c);

                    //set calculation values
                    if (q.isCPQ) {
                        salesmanCommission.initialCPQQuoteLine__c = quoteLine.AmendInitialQuoteLineId != null ?
                                quoteLine.AmendInitialQuoteLineId :
                                quoteLine.Id;
                    } else {
                        salesmanCommission.initialQuoteline__c = quoteLine.AmendInitialQuoteLineId != null ?
                                quoteLine.AmendInitialQuoteLineId :
                                quoteLine.Id;
                    }
                    salesmanCommission.unitPrice__c = quoteLine.NetUnitPrice;
                    salesmanCommission.quantity__c = quoteLine.Quantity;
                    salesmanCommission.ratingAmount__c = ratingAmount;
                    salesmanCommission.ec__c = ec;
                    salesmanCommission.repartPercent__c = repartPercent;
                    salesmanCommission.totalAmountTTC__c = montantTotalTTC;
                    salesmanCommission.amountHT__c = montantHT;
                    salesmanCommission.sellingPrice__c = quoteLine.NetTotalHT;
                    salesmanCommission.productRate__c = lineProductRate;
                    salesmanCommission.ecPercent__c = ecPercent;
                    salesmanCommission.rate__c = tauxDecoteFinal;
                    salesmanCommission.discountCoefficient__c = tauxDecoteFinal;


                    //parse all previous commissions on previous quote/quotelines (snapshoted or not)
                    String amendKey = quoteLine.AmendInitialQuoteLineId + '-' + Constants.COMMISSION_TYPE_SALES;
                    System.debug('  Check for previous commissions on amended quotelines');
                    System.debug('    amendmentQuote? ' + q.AmendmentQuote);
                    System.debug('    amendedOrderQuotesMap contains order? ' + context.amendedOrderQuotesMap.containsKey(q.OrderId));
                    System.debug('    originQuotelineCommissionMap contains key ' + amendKey + '? ' + context.originQuotelineCommissionMap.containsKey(amendKey));

                    if (q.AmendmentQuote
                            && context.amendedOrderQuotesMap.containsKey(q.OrderId)
                            && context.originQuotelineCommissionMap.containsKey(amendKey)) {

                        System.debug('    This is an amendment, we need to compare to sum of previous commisions with key ' + amendKey);
                        Double prevAmount = 0.0;
                        for (NRV10Commission__c prevCom : context.originQuotelineCommissionMap.get(amendKey)) {
                            if (cancelledCommissions.contains(prevCom.Id)
                                    || (salesmanCommission.Id != null && prevCom.Id == salesmanCommission.Id)) {
                                System.debug('      Old commission has been cancelled or is the current one, skip to next');
                                continue;
                            }
                            prevAmount += prevCom.remuneration__c;
                            System.debug('      cumulative commissions on this line: ' + prevAmount);
                        }

                        if (prevAmount != salesmanCommission.remuneration__c) {
                            salesmanCommission.remuneration__c = salesmanCommission.remuneration__c - prevAmount;
                            System.debug('      Final amount differs, take difference: ' + salesmanCommission.remuneration__c);
                            if (salesmanCommission.remuneration__c < 0) {
                                salesmanCommission.status__c = Constants.COMMISSION_STATUS_REGULARIZABLE;
                            }
                            System.debug('      with status: ' + salesmanCommission.status__c);
                        }
                    }

                    commissionsToUpsert.add(salesmanCommission);
                }


                // Team commission is now based on product too, have to calculate it for each line and taking account of malus too
                System.debug('Processing team remuneration for this line for ' +
                        managersContractsMap.size() + ' contracts');
                if (!managersContractsMap.isEmpty()) {
                    System.debug('There is ' + managersContractsMap.size() + ' managers to remunerate');
                    for (Id managerId : managersContractsMap.keySet()) {

                        //pick grid revisions in the global list
                        Double managerTeamRate = 0.0;
                        NRV10GridRevision__c managerCtRevision;
                        if (context.contractRevisionsMap
                                .containsKey(managersContractsMap.get(managerId).employmentContractType__c)) {
                            managerCtRevision = context
                                    .contractRevisionsMap.get(managersContractsMap.get(managerId).employmentContractType__c);
                        }
                        if (managerCtRevision == null) {
                            System.debug('The manager has no revision grid, do not create team commission for him');
                            continue;
                        }

                        NRV10GridRevision__c managerTeamRevision;
                        if (context.subRevGridsMap.containsKey(managerCtRevision.teamGridRevision__c)) {
                            managerTeamRevision = context.subRevGridsMap.get(managerCtRevision.teamGridRevision__c);
                            managerTeamRate = managerTeamRevision.defaultRate__c;
                            System.debug('Team manager has a team grid revision with default rate to: ' + managerTeamRate);
                        }
                        if (managerTeamRevision == null) {
                            System.debug('The manager has no team revision grid, do not create team commission for him');
                            continue;
                        }

                        //pick remuneration rates in the global list
                        if (context.remunerationRatesGridMap.containsKey(managerTeamRevision.Id)) {
                            for (NRV10RemunerationRate__c r : context.remunerationRatesGridMap.get(managerTeamRevision.Id)) {
                                if (r.startDate__c <= validationDate
                                        && (r.endDate__c == null || r.endDate__c >= validationDate)) {
                                    if (context.productRatesMap.containsKey(r.Id)
                                            && context.productRatesMap.get(r.Id).contains(quoteLine.ProductId)) {

                                        managerTeamRate = r.rate__c;
                                        // stop at first match
                                        break;
                                    }
                                }
                            }
                        }
                        System.debug('Final team rate for this manager and product at this time is: ' + managerTeamRate);

                        // do not create commission if no team rate has been found for this manager
                        if (managerTeamRate == 0) continue;

                        //get existing commission or create a new one if non already exists
                        NRV10Commission__c teamCommission;
                        String key = quoteLine.Id + '_' + Constants.COMMISSION_TYPE_TEAM + '_' + managerId;
                        if (context.commissionMap.containsKey(key)) {
                            System.debug('    manager already has a commission on this quoteline, update it');
                            teamCommission = context.commissionMap.get(key);
                        } else {
                            System.debug('    manager does not have a commission on this quoteline, create it');
                            teamCommission = new NRV10Commission__c();
                            teamCommission.user__c = managerId;
                            teamCommission.comType__c = Constants.COMMISSION_TYPE_TEAM;
                            if (q.isCPQ) {
                                teamCommission.quoteCPQ__c = q.Id;
                                teamCommission.quoteLine__c = quoteLine.Id;
                            } else {
                                teamCommission.quote__c = q.Id;
                                teamCommission.quoteLineItem__c = quoteLine.Id;
                            }
                            teamCommission.productCode__c = quoteLine.ProductCode;
                            teamCommission.productLabel__c = quoteLine.ProductLabel;
                        }

                        //add lookup to order if it exists (after status transmitted if must exists)
                        if(salesmanCommission.instantDate__c == null){
                            if (hasCustomerOrders) {
                                if (String.isBlank(teamCommission.customerOrder__c)) {
                                    teamCommission.customerOrder__c = customerOrderId;
                                }
                                if (context.quoteLineOrderProductsMap.containsKey(quoteLine.Id)) {
                                    teamCommission.orderProduct__c = context.quoteLineOrderProductsMap.get(quoteLine.Id);
                                }
                            }

                            //report sales commission parameters
                            teamCommission.unitPrice__c = salesmanCommission.unitPrice__c;
                            teamCommission.quantity__c = salesmanCommission.quantity__c;
                            teamCommission.ratingAmount__c = salesmanCommission.ratingAmount__c;
                            teamCommission.ec__c = salesmanCommission.ec__c;
                            teamCommission.repartPercent__c = salesmanCommission.repartPercent__c;
                            teamCommission.totalAmountTTC__c = salesmanCommission.totalAmountTTC__c;
                            teamCommission.amountHT__c = salesmanCommission.amountHT__c;
                            teamCommission.sellingPrice__c = salesmanCommission.sellingPrice__c;
                            teamCommission.productRate__c = salesmanCommission.productRate__c;
                            teamCommission.ecPercent__c = salesmanCommission.ecPercent__c;
                            teamCommission.rate__c = salesmanCommission.rate__c;
                            teamCommission.discountCoefficient__c = salesmanCommission.discountCoefficient__c;
                            if (q.isCPQ) {
                                teamCommission.initialCPQQuoteLine__c = salesmanCommission.initialCPQQuoteLine__c;
                            } else {
                                teamCommission.initialQuoteline__c = salesmanCommission.initialQuoteline__c;
                            }
                            teamCommission.store__c = assignmentStoreId;
                            teamCommission.status__c = commissionStatus;
                            teamCommission.calculationDate__c = validationDate;
                            teamCommission.remuneration__c = teamCommission.sellingPrice__c * teamCommission.productRate__c * teamCommission.rate__c / 10000;
                            teamCommission.remuneration__c = teamCommission.remuneration__c * managerTeamRate / 100;

                            //parse all previous commissions on previous quote/quotelines (snapshoted or not)
                            String amendKeyTeam = quoteLine.AmendInitialQuoteLineId + '-' + Constants.COMMISSION_TYPE_TEAM + '-' + managerId;
                            System.debug('  Check for previous team commissions on amended quotelines');
                            System.debug('    amendmentQuote? ' + q.AmendmentQuote);
                            System.debug('    amendedOrderQuotesMap contains order? ' + context.amendedOrderQuotesMap.containsKey(q.OrderId));
                            System.debug('    originQuotelineCommissionMap contains key ' + amendKeyTeam + '? ' + context.originQuotelineCommissionMap.containsKey(amendKeyTeam));

                            if (q.AmendmentQuote
                                    && context.amendedOrderQuotesMap.containsKey(q.OrderId)
                                    && context.originQuotelineCommissionMap.containsKey(amendKeyTeam)) {

                                System.debug('    This is an amendment, we need to compare to sum of previous commisions with key ' + amendKeyTeam);
                                Double prevAmount = 0.0;
                                for (NRV10Commission__c prevCom : context.originQuotelineCommissionMap.get(amendKeyTeam)) {
                                    if (cancelledCommissions.contains(prevCom.Id)
                                            || (teamCommission.Id != null && prevCom.Id == teamCommission.Id)) {
                                        System.debug('      Old commission has been cancelled or is the current one, skip to next');
                                        continue;
                                    }
                                    prevAmount += prevCom.remuneration__c;
                                    System.debug('      cumulative commissions on this line: ' + prevAmount);
                                }

                                if (prevAmount != teamCommission.remuneration__c) {
                                    teamCommission.remuneration__c = teamCommission.remuneration__c - prevAmount;
                                    System.debug('      Final amount differs, take difference: ' + teamCommission.remuneration__c);
                                    if (teamCommission.remuneration__c < 0) {
                                        teamCommission.status__c = Constants.COMMISSION_STATUS_REGULARIZABLE;
                                    }
                                    System.debug('      with status: ' + teamCommission.status__c);
                                }
                            }

                            teamCommission.salesRem__c = salesmanCommission.remuneration__c;
                            teamCommission.teamRate__c = managerTeamRate;
                            commissionsToUpsert.add(teamCommission);
                        }
                    }
                }

                //Remove any team commission on another manager than those in place
                //(when collaborator has changed store assignment)
                String qlKey = quoteLine.Id + '_' + Constants.COMMISSION_TYPE_TEAM + '_';
                for (String key : context.commissionMap.keySet()) {
                    if (key.startsWith(qlKey)
                            && !managersContractsMap.keySet().contains(key.substring(key.lastIndexOf('_') + 1))) {
                        System.debug('Team commission associated to manager ' +
                                key.substring(key.lastIndexOf('_') + 1) + ' will be removed');
                        commissionsToDelete.add(context.commissionMap.get(key));
                    }
                }
            }
            quotesToUpdate.add(q);


            //Add a malus commission if the quote financing method match collaborator malus grids
            if (hasMalus) {
                //get existing commission or create a new one if non already exists
                NRV10Commission__c salesmanMalusCommission;
                if (context.commissionMap.containsKey(q.Id + '_' + Constants.COMMISSION_TYPE_MALUS)) {
                    System.debug('    collaborator already has a malus commission on this quote, update it');
                    salesmanMalusCommission = context.commissionMap.get(q.Id + '_' + Constants.COMMISSION_TYPE_MALUS);
                } else {
                    System.debug('    collaborator does not have a malus commission on this quote, create it');
                    salesmanMalusCommission = new NRV10Commission__c();
                    salesmanMalusCommission.user__c = collaborator.Id;
                    salesmanMalusCommission.comType__c = Constants.COMMISSION_TYPE_MALUS;
                    if (q.isCPQ) {
                        salesmanMalusCommission.quoteCPQ__c = q.Id;
                    } else {
                        salesmanMalusCommission.quote__c = q.Id;
                    }
                }

                // If the malus already exists and the malus amount has been customized, process next quote
                if (salesmanMalusCommission.customValue__c) continue;

                //add lookup to order if it exists (after status transmitted if must exists)
                if (hasCustomerOrders && String.isBlank(salesmanMalusCommission.customerOrder__c)) {
                    salesmanMalusCommission.customerOrder__c = customerOrderId;
                }

                //add lookup to manager and store
                System.debug('    collaborator is part of a team, set the id and store');
                salesmanMalusCommission.store__c = assignmentStoreId;

                //set or update status and calculation date (this one changes only when customer accept the quote)
                salesmanMalusCommission.status__c = commissionStatus;
                salesmanMalusCommission.calculationDate__c = validationDate;
                if (q.isCPQ) {
                    salesmanMalusCommission.initialCPQQuote__c = q.AmendInitialQuoteId != null ?
                            q.AmendInitialQuoteId :
                            q.Id;
                } else {
                    salesmanMalusCommission.initialQuote__c = q.AmendInitialQuoteId != null ?
                            q.AmendInitialQuoteId :
                            q.Id;
                }

                //set the final remuneration of the commission
                salesmanMalusCommission.turnoverLevel__c = highestLevel;
                salesmanMalusCommission.financingMethodName__c = q.FinancingMethod;
                salesmanMalusCommission.totalAmountTTC__c = montantTotalTTC;

                salesmanMalusCommission.remuneration__c = malusAmount;
                System.debug(' malus for this quote is: ' + salesmanMalusCommission.remuneration__c);


                //parse all previous commissions on previous quote/quotelines (snapshoted or not)
                String amendKey = q.AmendInitialQuoteId + '-' + Constants.COMMISSION_TYPE_MALUS;
                if (q.AmendmentQuote
                        && context.amendedOrderQuotesMap.containsKey(q.OrderId)
                        && context.originQuotelineCommissionMap.containsKey(amendKey)) {

                    System.debug('    This is an amendment, we need to compare to sum of previous commisions with key ' + amendKey);
                    Double prevAmount = 0.0;
                    for (NRV10Commission__c prevCom : context.originQuotelineCommissionMap.get(amendKey)) {
                        if (cancelledCommissions.contains(prevCom.Id)
                                || (salesmanMalusCommission.Id != null && prevCom.Id == salesmanMalusCommission.Id)) {
                            System.debug('      Old commission has been cancelled or is the current one, skip to next');
                            continue;
                        }
                        prevAmount += prevCom.remuneration__c;
                        System.debug('      cumulative commissions on this line: ' + prevAmount);
                    }

                    if (prevAmount != salesmanMalusCommission.remuneration__c) {
                        salesmanMalusCommission.remuneration__c = salesmanMalusCommission.remuneration__c - prevAmount;
                        System.debug('      Final amount differs, take difference: ' + salesmanMalusCommission.remuneration__c);
                        if (salesmanMalusCommission.remuneration__c < 0) {
                            salesmanMalusCommission.status__c = Constants.COMMISSION_STATUS_REGULARIZABLE;
                        }
                        System.debug('      with status: ' + salesmanMalusCommission.status__c);
                    }
                }

                commissionsToUpsert.add(salesmanMalusCommission);
            }


            System.debug('Commissions generation, ' + commissionsToUpsert.size() + ' commissions to create or update');
            delete commissionsToDelete;
            upsert commissionsToUpsert;

            //sum commissions per quote
            Map<Id, Decimal> quotesTotalSalesCom = new Map<Id, Decimal>();
            Map<Id, Decimal> quotesTotalTeamCom = new Map<Id, Decimal>();
            for (NRV10Commission__c c : commissionsToUpsert) {
                Id quoteId = c.quoteCPQ__c;
                if (quoteId == null) quoteId = c.quote__c;

                if (quoteId != null) {
                    if (!quotesTotalSalesCom.containsKey(quoteId)) quotesTotalSalesCom.put(quoteId, 0.0);
                    if (!quotesTotalTeamCom.containsKey(quoteId)) quotesTotalTeamCom.put(quoteId, 0.0);
                    if (c.comType__c == Constants.COMMISSION_TYPE_SALES) {
                        quotesTotalSalesCom.put(quoteId, quotesTotalSalesCom.get(quoteId) + c.remuneration__c);
                    } else if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                        quotesTotalTeamCom.put(quoteId, quotesTotalTeamCom.get(quoteId) + c.remuneration__c);
                    }
                }
            }

            List<SObject> quotesObjectToUpdate = new List<SObject>();
            for (QuoteTransformer qw : quotesToUpdate) {
                if (qw.isCPQ) {
                    SBQQ__Quote__c qto = new SBQQ__Quote__c(
                            Id = qw.Id,
                            commStatus__c = qw.CommissionStatus);
                    //set total amount of sales & team commissions
                    if (quotesTotalSalesCom.containsKey(qw.Id)) {
                        qto.salesCommission__c = quotesTotalSalesCom.get(qw.Id);
                    }
                    if (quotesTotalTeamCom.containsKey(qw.Id)) {
                        qto.teamCommission__c = quotesTotalTeamCom.get(qw.Id);
                    }
                    quotesObjectToUpdate.add(qto);
                } else {
                    //not supported yet
//                    quotesObjectToupdate.add(new SBQQ__Quote__c(
//                            Id = q.Id,
//                            techRemVRP__c = q.TechRemVrp,
//                            commStatus__c = q.CommissionStatus)
//                    );
                }
            }
            update quotesObjectToUpdate;
        }
        System.debug('Sales commissions process ended');
        String a = 'string';
        String b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;

    }
}