/**
 * @description As Salesforce does not allow real singletons,
 * use queueable to enqueue quote processing
 *
 * Created by 4C on 15/10/2020.
 */
public without sharing class QA_QuoteProcessCommissions implements Queueable {
    private List<Id> quotesIds = new List<Id>();
    private List<Id> salesQuotesIds = new List<Id>();

    public QA_QuoteProcessCommissions(List<Id> ids) {
        for (Id qId : ids) {
            System.debug('## OrderIdCommissionned : '+qId);
            if (qId.getSobjectType().getDescribe().getName().startsWithIgnoreCase('SBQQ')) {
                quotesIds.add(qId);
            } else {
                salesQuotesIds.add(qId);
            }
        }
    }

    public void execute(QueueableContext context) {
        //get all quotes to process
        if (!this.quotesIds.isEmpty()) {
            System.debug('## CPQ quotes not empty, process them');
            List<SBQQ__Quote__c> quotes = [SELECT Id, MontantTotalTTC__c, SBQQ__CustomerAmount__c, SBQQ__ListAmount__c,
                    SBQQ__Status__c, AmendmentQuote__c, spilledCustomerOrder__c, commStatus__c, opportunityOwner__c,
                    dateAcceptationClient__c, amendInitialQuote__c, previousQuote__c, referenceDate__c,
                    ecartCotation__c, ecartCotationPercent__c, MontantTotalHTpostBP__c, SBQQ__DistributorDiscount__c,
                    dateTransmissionClient__c, OwnerId, financingMethod__r.Name, customerOrder__c, customerOrder__r.legacySource__c
                    FROM SBQQ__Quote__c WHERE Id IN :quotesIds /*AND chantier__r.serviceEntity__r.migratedToK3__c = true*/]; // techRemVRP__c,

            System.debug('## CPQ Commission processing launched for ' + quotes.size() + ' quote(s)');
            if (!quotes.isEmpty()) {
                List<SBQQ__Quote__c> quotesToCommission = new List<SBQQ__Quote__c>();
                for(SBQQ__Quote__c q : quotes){
                    if(q.customerOrder__r.legacySource__c != 'GC/Froide' && 
                        q.SBQQ__Status__c != Constants.QUOTE_STATUS_TO_CONFIGURE &&
                        q.SBQQ__Status__c != Constants.QUOTE_STATUS_NOT_TRANSMITTED &&
                        q.SBQQ__Status__c != Constants.QUOTE_STATUS_TRANSMITTED){
                        quotesToCommission.add(q);
                    }
                }
                TR022_SBQQ_Quote_Commission.processCommissions(quotesToCommission);
            }
        }
        if (!this.salesQuotesIds.isEmpty()) {
            System.debug('## Sales quotes not empty, process them');
            if (!this.quotesIds.isEmpty()) {
                // To prevent too many soql, if there was also CPQ quotes, start a new job with sales quote
                System.debug('## CPQ quotes was not empty, enqueue another job');
                System.enqueueJob(new QA_QuoteProcessCommissions(this.quotesIds));
            } else {
                // If there was no cpq quotes, process sales quote now
                System.debug('## CPQ quotes was empty, process the quotes');
                List<Quote> quotes = [SELECT Id, TotalTTCTarif__c, TotalHTlignes__c, TotalTTClignes__c,
                        Status, amendmentQuote__c, spilledCustomerOrder__c, commStatus__c, dateAcceptationClient__c, TotalHTTarif__c,
                        amendInitialQuote__c, previousQuote__c, TotalHTRemise__c, dateTransmissionClient__c, OwnerId, referenceDate__c,
                        modeFinancement__c, TVA__c, RemisevendeurglobaleFormule__c, opportunityOwner__c, TotalHTDevis__c, 
                        customerOrder__c, customerOrder__r.legacySource__c
                        FROM Quote WHERE Id IN :this.salesQuotesIds /*AND opportunity.chantier__r.serviceEntity__r.migratedToK3__c = true*/];

                System.debug('## Sales Commission processing launched for ' + quotes.size() + ' quote(s)');
                if (!quotes.isEmpty()) {
                    List<Quote> quotesToCommission = new List<Quote>();
                    for(Quote q : quotes){
                        if(q.customerOrder__r.legacySource__c != 'GC/Froide' && 
                            q.Status != Constants.STD_QUOTE_STATUS_TO_CONFIGURE &&
                            q.Status != Constants.QUOTE_STATUS_NOT_TRANSMITTED &&
                            q.Status != Constants.QUOTE_STATUS_TRANSMITTED){
                            quotesToCommission.add(q);
                        }
                    }
                    TR022_SBQQ_Quote_Commission.processCommissions(quotesToCommission);
                }
            }
        }
    }
}