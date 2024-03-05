/**
 * Created by 4C on 02/03/2021.
 */

 public without sharing class QuoteTransformer {

    private SBQQ__Quote__c cpqQuote;
    private Quote salesQuote;

    public Boolean isCPQ = false;
    public Id OwnerId;
    public Id OppOwnerId;
    public Id Id;
    public String Status;
    public Date ReferenceDate;
    public Date DateTransmissionClient;
    public Date DateAcceptationClient;
    public Boolean AmendmentQuote;
    public String FinancingMethod;
    public Decimal MontantTotalTTC;
    public Decimal CustomerAmount;
    public Decimal QuoteAmount;
    public Decimal TotalHTPostBP;  // = SUM QL SBQQ__PartnerTotal__c (si custAm > 0 & bypassCalc false & type <> SAV & techNoPr true
    public Decimal EcartCotation;
    public Decimal TauxEcartCotation;
    public Id OrderId;
    public String CommissionStatus;
    public Boolean TechRemVrp;
    public Id AmendInitialQuoteId;
    public Id AmendPreviousQuoteId;


    public QuoteTransformer(SBQQ__Quote__c quote) {
        this.isCPQ = true;
        this.cpqQuote = quote;

        this.Id = quote.Id;
        this.OwnerId = quote.opportunityOwner__c; //quote.OwnerId; JMU - 12/12/2022 - SUIVI MEP #400 : Pour les devis Sales, on va désormais récupérer le propriétaire du projet
        //this.OwnerId = quote.OwnerId;
        this.OppOwnerId = quote.opportunityOwner__c;
        this.Status = quote.SBQQ__Status__c;
        this.ReferenceDate = quote.referenceDate__c;
        this.DateTransmissionClient = quote.dateTransmissionClient__c;
        this.DateAcceptationClient = quote.dateAcceptationClient__c;
        this.AmendmentQuote = quote.AmendmentQuote__c;
        this.FinancingMethod = quote.financingMethod__r.Name;  // Use name instead of Id as it match the sales quote values
        this.MontantTotalTTC = quote.MontantTotalTTC__c; //Montant total TTC
        this.CustomerAmount = quote.SBQQ__CustomerAmount__c;
        this.QuoteAmount = (quote.SBQQ__ListAmount__c == null) ? 0 : quote.SBQQ__ListAmount__c; 
        this.TotalHTPostBP = quote.MontantTotalHTpostBP__c; //montant post bonus projet et donc avec remises
        this.EcartCotation = (quote.ecartCotation__c == null) ? 0 : quote.ecartCotation__c; // ecart entre prix net ht et prix de vente
        this.TauxEcartCotation = (quote.ecartCotationPercent__c == null) ? 0 : quote.ecartCotationPercent__c;
        this.OrderId = quote.spilledCustomerOrder__c;
        this.CommissionStatus = quote.commStatus__c;
//        this.TechRemVrp = quote.techRemVRP__c;
        this.AmendInitialQuoteId = quote.amendInitialQuote__c; //Lien vers la toute première quote
        this.AmendPreviousQuoteId = quote.previousQuote__c; //Lien vers l'avenant précédent (ou la quote si premier avenant)
    }

    public QuoteTransformer(Quote quote) {
        this.isCPQ = false;
        this.salesQuote = quote;

        this.Id = quote.Id;
        this.OwnerId = quote.opportunityOwner__c; //quote.OwnerId; JMU - 12/12/2022 - SUIVI MEP #400 : Pour les devis Sales, on va désormais récupérer le propriétaire du projet
        this.OppOwnerId = quote.opportunityOwner__c; 
        String status = quote.Status;
        if (status.startsWithIgnoreCase(Constants.QUOTE_STATUS_SOLD)) status = Constants.QUOTE_STATUS_SOLD;
        this.Status = status;
        this.ReferenceDate = quote.referenceDate__c;
        this.DateTransmissionClient = quote.dateTransmissionClient__c;
        this.DateAcceptationClient = quote.dateAcceptationClient__c;
        this.AmendmentQuote = quote.amendmentQuote__c;
        this.FinancingMethod = quote.modeFinancement__c;   // Picklist to String

        this.MontantTotalTTC = (quote.TotalTTCTarif__c == null) ? 0 : quote.TotalTTCTarif__c.setScale(2);
        this.CustomerAmount = (quote.TotalHTDevis__c == null) ? 0 : quote.TotalHTDevis__c;
        this.QuoteAmount = quote.TotalTTClignes__c;
        this.TotalHTPostBP = (quote.TotalHTTarif__c == null) ? 0 : quote.TotalHTTarif__c;
        this.EcartCotation = Math.Max(0, this.CustomerAmount - this.TotalHTPostBP);
        this.TauxEcartCotation = Math.Max(0, (quote.RemisevendeurglobaleFormule__c == null) ? 0 : quote.RemisevendeurglobaleFormule__c);
        this.OrderId = quote.spilledCustomerOrder__c;

        this.CommissionStatus = quote.commStatus__c;
        this.AmendInitialQuoteId = quote.amendInitialQuote__c;
        this.AmendPreviousQuoteId = quote.previousQuote__c;
    }

}