//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_QuoteLineItem
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/07/2018
//-- Version     : 1.3
//-- * 1.3 : RQM-47 : Calcul de la prime CEE / Isolation des combles
//-- * 1.2 : Ajout fonction de suppression d'options
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR022_QuoteLineItem {

    /**
    * @description Si une ligne de devis est ajoutée/supprimée/modifiée, on change le flag changementProduits__c.
    * Cela change le flag "A configurer" pour les autres lignes
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void changeProductInQuote(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_QuoteLineItem.changeProductInQuote');
        List<QuoteLineItem> quotesLineItem = new List<QuoteLineItem>();
        if (Trigger.isDelete)
            quotesLineItem = (List<QuoteLineItem>) Trigger.old;
        else
            quotesLineItem = (List<QuoteLineItem>) Trigger.new;
        Set<String> quotesId = new Set<String>();
        List<Quote> quotesList = new List<Quote>();

        // On récupère les ID des devis des lignes de devis
        for (QuoteLineItem qli : quotesLineItem) {
            if (!AlreadyUsed.isUsed('TR022_QuoteLineItem.changeProductInQuote', qli.QuoteId)) 
                quotesId.add(qli.QuoteId);
        }

        // On modifie les devis
        for (String quoteId : quotesId) {
            system.debug('## Changement produit pour devis ' + quoteId);    
            // Modification du flag "Changement des Produits"
            Quote devis = new Quote(Id = quoteId, changementProduits__c = true);
            quotesList.add(devis);
        }

        if(!quotesList.isEmpty())
            update quotesList;

        system.debug('### END TR022_QuoteLineItem.changeProductInQuote');   
    }
    
    /**
    * @description Supprime les options si une ligne de devis est supprimée
    * @param qliList Liste des lignes de devis supprimées
    */
    public static void deleteOptionsDeLigneDevis(List<QuoteLineItem> qliList) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_QuoteLineItem.deleteOptionsDeLigneDevis');
        Set<String> QuoteLineItemsId = new Set<String>();
        // On récupère les ID des QLI pour lesquelles il faut supprimer les options
        for (QuoteLineItem qli : qliList) {
            QuoteLineItemsId.add(qli.Id);
        }
        // SOQL - On récupère les options des lignes de devis supprimées
        List<Option__c> optionsList = [SELECT Id FROM Option__c WHERE ligneDevis__c IN :QuoteLineItemsId];
        system.debug('## Options supprimé : '+optionsList.size());
        if(!optionsList.isEmpty())
            delete optionsList;

        system.debug('### END TR022_QuoteLineItem.deleteOptionsDeLigneDevis');  
    }

    /**
    * @description Mise à jour des numéros de ligne avant suppression d'une ligne
    * @param lstlignes Liste des lignes de devis
    */
    public static void changeLinesNumberDelete(List<QuoteLineItem> lstlignes) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_QuoteLineItem.changeLinesNumberDelete');
        Set<String> quoteIds = new Set<String>();
        String numDeleteLine ='';

        // Récupération des IDs des devis
        for (QuoteLineItem ligne : lstlignes) {
            if (!AlreadyUsed.isUsed('TR022_QuoteLineItem.changeLinesNumberDelete', ligne.QuoteId)) {
                quoteIds.add(ligne.QuoteId);
            }
        }
        
        if (quoteIds.isEmpty())
            return;

        // SOQL - SELECT - Liste de toutes les lignes des devis impactés
        List<QuoteLineItem> quoteLineItemBefore = [SELECT Id, QuoteId, NumLigneText__c FROM QuoteLineItem WHERE QuoteId IN :quoteIds];
        for (String devis : quoteIds) {
            system.debug('## Devis : ' + devis);
            // Pour toutes les lignes supprimés, on décremente le compteur
            for (QuoteLineItem line : lstlignes) {
                if(line.QuoteId == devis) {
                    //CRM-461 récupération du numéro de ligne supprimé
                    numDeleteLine = line.NumLigneText__c;
                    system.debug('## Num Ligne supp : ' + numDeleteLine);
                }
            }
            // Variables de stockage
            String lineNumberFormat = '';
            Integer lastLineNumber = 0;
            // CRM-461 réajustement des numéros de ligne après suppression
            for (QuoteLineItem lineBefore : quoteLineItemBefore){
                system.debug('## Supression ligne :' + numDeleteLine + ' ' + lineBefore.NumLigneText__c);
                if(lineBefore.NumLigneText__c > numDeleteLine) {
                    lastLineNumber = Integer.valueOf(lineBefore.NumLigneText__c) - 1;
                    // Formatage pour ajouter un 0 avant si un chiffre
                    String formatNumber = String.valueOf(lastLineNumber);
                    lineNumberFormat = (lastLineNumber >= 1 && lastLineNumber <= 9) ? '0' + formatNumber : formatNumber;
                    // Mise à jour du champ
                    system.debug('## Num Format : ' + lineNumberFormat);
                    lineBefore.NumLigneText__c = lineNumberFormat;
                }
            }
        }

        if(!quoteLineItemBefore.isEmpty())
            update quoteLineItemBefore;
            
        system.debug('### END TR022_QuoteLineItem.changeLinesNumberDelete');
    }

    /**
    * @description Mise à jour des numéros des lignes (NumLigneText__c)
    * @param quoteLineItemsList Liste des lignes de devis
    */
    public static void changeLinesNumber(List<QuoteLineItem> quoteLineItemsList) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_QuoteLineItem.changeLinesNumber');
        // Récupération des IDs des devis
        Set <String> idsQuoteList = new Set<String>();
        for (QuoteLineItem qli : quoteLineItemsList){
            if (!AlreadyUsed.isUsed('TR022_QuoteLineItem.changeLinesNumber', qli.QuoteId)) {
                idsQuoteList.add(qli.QuoteId);
            }
        }
        
        if (idsQuoteList.isEmpty())
            return;

        // Récupération du nombre de lignes par devis
        Map<String, Integer> quoteLineItemsNumber = new Map<String, Integer>();
        for (AggregateResult nbLine : [SELECT QuoteId, COUNT(Id) total FROM QuoteLineItem WHERE QuoteId IN :idsQuoteList GROUP BY QuoteId]) {
            quoteLineItemsNumber.put((String)nbLine.get('QuoteId'), (Integer)nbLine.get('total'));
        }
        system.debug('## quoteLineItemsNumber : ' + quoteLineItemsNumber);

        for (String quote: idsQuoteList) {
            system.debug('## Devis : ' + quote);
            String lineNumberFormat = '';
            Integer lineNumber = (quoteLineItemsNumber.get(quote) == null) ? 0 : quoteLineItemsNumber.get(quote);
            system.debug('## Numero : ' + lineNumber);
            for(QuoteLineItem qli : quoteLineItemsList) {
                if (qli.QuoteId == quote) {
                    lineNumber++;
                    // Formatage pour ajouter un 0 avant si un chiffre
                    String formatNumber = String.valueOf(lineNumber);
                    lineNumberFormat = (lineNumber >= 1 && lineNumber <= 9) ? '0' + formatNumber : formatNumber;
                    // Mise à jour du champ
                    system.debug('## Num Format : ' + lineNumberFormat);
                    qli.NumLigneText__c = lineNumberFormat;
                }
            }
        }
        system.debug('### END TR022_QuoteLineItem.changeLinesNumber');
    }

    /**
    * @description Mise à jour du montant de la prime CEE des devis
    * @param quoteLineItemList Liste des lignes de devis
    */
    public static void setMontantTotalCEE(List<QuoteLineItem> quoteLineItemList) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_QuoteLineItem.setMontantTotalCEE');
        List<Quote> quote = new List<Quote>();
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        Set<String> productIdList = new Set<String>();
        Set<String> tvaTypeList = new Set<String>();
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
        List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
        List<String> quoteIds = new List<String>();
        
        // récupération des devis associés et de toutes leur lignes
        if(quoteLineItemList != null){
            for(QuoteLineItem qli : quoteLineItemList){
                system.debug('qli.montantCEE__c : '+qli.montantCEE__c);
                if (!AlreadyUsed.isUsed('TR022_QuoteLineItem.setMontantTotalCEE', qli.QuoteId)) 
                    quoteIds.add(qli.QuoteId);
            }
            quote = [SELECT Id, zone__c, categorie__c, dateDevis__c, referenceDate__c, nbPersonnes__c, revenusFiscaux__c, Opportunity.chantier__r.heatingMode__c,
                            Opportunity.Chantier__r.codeDVReference__c,
                            (SELECT Id, QuoteId, Quantity, product2Id, PricebookEntry.Product2Id, eligibleCEE__c, TVApourcentage__c 
                            FROM QuoteLineItems WHERE cancelledLine__c = false) 
                        FROM Quote WHERE Id IN :quoteIds];
            if(!quote.isEmpty()){
                for(Quote devis : quote){
                    qliList.addAll(devis.QuoteLineItems);
                }

                for(QuoteLineItem qli : qliList){
                    productIdList.add(qli.product2Id);
                }

                // Récupération des primes présentes dans la base
                ceePrimeList = [SELECT Id, dateDebutValidite__c, dateFinValidite__c, categorie__c, montant__c, produit__c, zone__c FROM CEE_Prime__c];
                tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                                FROM TVA_Produit__c
                                WHERE produit__c IN :productIdList];

                for(TVA_Produit__c tva : tvaList){
                    tvaTypeList.add(tva.Type__c);
                }

                ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                            FROM ESCIncentive__c
                            WHERE type__c IN :tvaTypeList];

                // Calcul de la prime CEE
                String dvElligibles = PropertiesUtils.getStringValue('cee.codesDVElligible', null);
                system.debug('## ceeList: '+ceeList);
                for(Quote q : quote){
                    if(Test.isRunningTest() == false) {
                        if(String.isNotBlank(dvElligibles) && q.Opportunity != null && q.Opportunity.Chantier__r != null && q.Opportunity.Chantier__r.codeDVReference__c != null
                            && dvElligibles.contains(q.Opportunity.Chantier__r.codeDVReference__c))
                        {
                            Utils_CEE.setQuoteCEE(qliList, q, ceeList, tvaList);
                        } else {
                            Utils_CEE.setQuotePrimeCEE(qliList, q, ceePrimeList);
                        }    
                    }
                }

                update quote;
            }
        }
        system.debug('### END TR022_QuoteLineItem.setMontantTotalCEE');
    }
}