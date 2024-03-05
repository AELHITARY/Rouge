//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl017_OverrideEditQli
//-- Modifié par : ALT
//-- Modifié le  : 10/10/2012
//-- Version     : 1.00
//-- *
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl017_OverrideEditQli {

    private QuoteLineItem qli;

    public Ctrl017_OverrideEditQli(Apexpages.standardController con){
        qli = DAL.getQuoteLineItemById(con.getId());
    }

    public pageReference redirectToEditAll(){
        Pagereference pr = Page.VF001_Quote_SelectProductGrid;
        pr.getParameters().put('id',qli.quoteId);
        pr.getParameters().put('retURL','/' + qli.Id);
        return pr;
    }
}