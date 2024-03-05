/**
 * Created by 4C on 02/03/2021.
 */

public with sharing class QuoteLineTransformer {

    private SBQQ__QuoteLine__c cpqQuoteLine;
    private QuoteLineItem salesQuoteLine;

    public Id Id;
    public Id AmendInitialQuoteLineId;
    public Id ProductId;
    public Decimal NetTotalHT;
    public String ProductLabel;
    public String ProductCode;
    public Decimal NetUnitPrice;
    public Decimal Quantity;
    public Id Quote;
    public Id Product2Id;

    /**
     * @description Constructor for CPQ quote line
     *
     * @param quoteLine Source CPQ QuoteLine
     */
    public QuoteLineTransformer(SBQQ__QuoteLine__c quoteLine) {
        this.Quote = quoteLine.SBQQ__Quote__c;
        this.Product2Id = quoteLine.SBQQ__Product__c;
        this.cpqQuoteLine = quoteLine;
        this.Id = quoteLine.Id;

        this.ProductId = quoteLine.SBQQ__Product__c;
        this.NetTotalHT = quoteLine.SBQQ__PackageTotal__c; // = Net Price * Qty replace SBQQ__CustomerTotal__c
        this.ProductLabel = quoteLine.LibelleProduit__c;
        this.ProductCode = quoteLine.SBQQ__ProductCode__c;
        this.AmendInitialQuoteLineId = quoteLine.amendInitialQuoteline__c;
        this.NetUnitPrice = quoteLine.QuoteLineNetUnitPrice__c; // = Net Unit Price avec conditions sur bundle et frais de pose
        this.Quantity = quoteLine.SBQQ__Quantity__c;
    }

    /**
     * @description Constructor for Sales quoteline item
     *
     * @param quoteLine Source QuoteLineItem
     */
    public QuoteLineTransformer(QuoteLineItem quoteLine) {
        this.Quote = quoteLine.QuoteId;
        this.Product2Id = quoteLine.Product2Id;
        this.salesQuoteLine = quoteLine;
        this.Id = quoteLine.Id;

        this.ProductId = quoteLine.Product2Id;
        this.NetTotalHT = quoteLine.prixHTTarifRemise__c; //quoteLine.prixUnitaireHTRemise__c * quoteLine.Quantity;
        this.ProductLabel = quoteLine.productName__c;
        this.ProductCode = quoteLine.productCode__c;
        this.AmendInitialQuoteLineId = quoteLine.amendInitialQuoteline__c;
        this.NetUnitPrice = quoteLine.prixUnitaireHTRemise__c;
        this.Quantity = quoteLine.Quantity;
    }
}