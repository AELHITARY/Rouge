//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR002_Devis
//-- Modifié par : SOPRA STERIA - William DE GAËTANO
//-- Modifié le  : 14/03/2017
//-- Version     : 1.2
//-- * Suppression référence au champ NombreTotalLigneDevis__c
//-- --------------------------------------------------------------------------------- --
public without sharing class TR002_Devis {

    /**
    * @description Mise à jour des numéros de ligne avant suppression d'une ligne
    * @param lstlignes Liste des lignes de devis
    */
    public static void NombreTotalLignesDevisSupprimer(List<QuoteLineItem> lstlignes) {
        if (!Trigger.isExecuting)
            return;

        system.debug('#### START TR002_Devis.NombreTotalLignesDevisSupprimer');
        Set<String> quoteIds = new Set<String>();
        String numDeleteLine ='';

        // Récupération des IDs des devis
        for (QuoteLineItem ligne : lstlignes) {
            if (!AlreadyUsed.isUsed('TR002_Devis.NombreTotalLignesDevisSupprimer', ligne.QuoteId)) {
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
            //CRM-461 réajustement des numéros de ligne après suppression
            for (QuoteLineItem lineBefore : quoteLineItemBefore){
                system.debug('## Supression Ligne :' + numDeleteLine + ' ' + lineBefore.NumLigneText__c);
                if(lineBefore.NumLigneText__c > numDeleteLine) {
                    lastLineNumber = Integer.valueOf(lineBefore.NumLigneText__c) - 1;
                    // Formatage pour ajouter un 0 avant si un chiffre
                    String formatNumber = String.valueOf(lastLineNumber);
                    if (lastLineNumber >= 1 && lastLineNumber <= 9)
                        lineNumberFormat = '0' + formatNumber;
                    else
                        lineNumberFormat = formatNumber;
                    // Mise à jour du champ
                    system.debug('## Num Format : ' + lineNumberFormat);
                    lineBefore.NumLigneText__c = lineNumberFormat;
                }
            }
        }

        if(!quoteLineItemBefore.isEmpty())
            update quoteLineItemBefore;
            
        system.debug('### END TR002_Devis.NombreTotalLignesDevisSupprimer');
    }

    /**
    * @description Mise à jour des numéros des lignes (NumLigneText__c)
    * @param quoteLineItemsList Liste des lignes de devis
    */
    public static void RenseignerLigneDevis(List<QuoteLineItem> quoteLineItemsList) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR002_Devis.RenseignerLigneDevis');
        // Récupération des IDs des devis
        Set <String> idsQuoteList = new Set<String>();
        for (QuoteLineItem qli : quoteLineItemsList){
            if (!AlreadyUsed.isUsed('TR002_Devis.RenseignerLigneDevis', qli.QuoteId)) {
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
            Integer lineNumber;
            if(quoteLineItemsNumber.get(quote) == null)
                lineNumber = 0;
            else
                lineNumber = quoteLineItemsNumber.get(quote);
            system.debug('## Numero : ' + lineNumber);
            String lineNumberFormat = '';
            for(QuoteLineItem qli : quoteLineItemsList) {
                if (qli.QuoteId == quote) {
                    lineNumber++;
                    // Formatage pour ajouter un 0 avant si un chiffre
                    String formatNumber = String.valueOf(lineNumber);
                    if (lineNumber >= 1 && lineNumber <= 9)
                        lineNumberFormat = '0' + formatNumber;
                    else
                        lineNumberFormat = formatNumber;
                    // Mise à jour du champ
                    system.debug('## Num Format : ' + lineNumberFormat);
                    qli.NumLigneText__c = lineNumberFormat;
                }
            }
        }
        system.debug('### END TR002_Devis.RenseignerLigneDevis');
    }
}