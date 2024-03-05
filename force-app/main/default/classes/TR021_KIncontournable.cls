/* ************************************************************************* *
 * Incontournable K : Alimentation des indicateurs                           *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 13/03/2013                                                      *
 * ************************************************************************* *
 */

public class TR021_KIncontournable {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);
  
  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Répartition et calcul des indicateurs **/
    List<Quote> quotesToUpdate = null;
    // Insert
    if (Trigger.isInsert)
      quotesToUpdate = incrementIndicators(Trigger.new);
    // Update
    else if (Trigger.isUpdate) {
      Set<ID> quoteIds = new Set<ID>();

      for (KIncontournable__c newIncontournable : (List<KIncontournable__c>) Trigger.new) {
        KIncontournable__c oldIncontournable = (KIncontournable__c) Trigger.oldMap.get(newIncontournable.id);

        Boolean changed = newIncontournable.dateIncontournable__c != oldIncontournable.dateIncontournable__c ||
                          newIncontournable.statut__c             != oldIncontournable.statut__c;
        if (enabledForceIndicators || newIncontournable.devis__c != oldIncontournable.devis__c || changed) {
          if (newIncontournable.devis__c != null && !AlreadyUsed.isUsed('TR021_KIncontournable', newIncontournable.devis__c))
            quoteIds.add(newIncontournable.devis__c);
          if (oldIncontournable.devis__c != null && !AlreadyUsed.isUsed('TR021_KIncontournable', oldIncontournable.devis__c))
            quoteIds.add(oldIncontournable.devis__c);
        }                    
      }
      if (!quoteIds.isEmpty())
        quotesToUpdate = buildQuoteIndicators(quoteIds);
    }
    // Delete
    else if (Trigger.isDelete)
      quotesToUpdate = buildIndicators(Trigger.old);

    /** B - Sauvegarde des indicateurs **/
    if (quotesToUpdate != null && !quotesToUpdate.isEmpty())
      update quotesToUpdate;
  }


  /** 02 - Méthodes de calcul **/
  private static List<Quote> incrementIndicators(List<KIncontournable__c> incontournables) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> quoteIds = new Set<Id>();

    for (KIncontournable__c incontournable : incontournables)
      if (!AlreadyUsed.isUsed('TR021_KIncontournable', incontournable.devis__c))
        quoteIds.add(incontournable.devis__c);

    if (quoteIds.isEmpty())
      return null;

    Map<Id, Quote> quotes = new Map<Id, Quote>([SELECT datePremierIncontournable__c, dateDernierIncontournable__c,
                                                       nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                       statutPremierIncontournable__c, statutDernierIncontournable__c
                                                FROM Quote
                                                WHERE id in :quoteIds]);

    /** B - Mise à jour des indicateurs **/
    for (KIncontournable__c incontournable : incontournables)
      if (incontournable.devis__c != null && quotes.containsKey(incontournable.devis__c))
        incrementIndicators(quotes.get(incontournable.devis__c), incontournable);

    /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
    return quotes.values();
  }

  private static List<Quote> buildIndicators(List<KIncontournable__c> incontournables) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> quoteIds = new Set<Id>();

    for (KIncontournable__c incontournable : incontournables)
      if (!AlreadyUsed.isUsed('TR021_KIncontournable', incontournable.devis__c))
        quoteIds.add(incontournable.devis__c);

    if (quoteIds.isEmpty())
      return null;

    /** B - Mise à jour des indicateurs et retour des contrat à sauvegarder **/
    return buildQuoteIndicators(quoteIds);
  }

  private static List<Quote> buildQuoteIndicators(Set<ID> quoteIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Quote> quotes = [SELECT datePremierIncontournable__c, dateDernierIncontournable__c,
                                 nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                 statutPremierIncontournable__c, statutDernierIncontournable__c,
                                 (SELECT dateIncontournable__c, statut__c FROM devisIncontournables__r ORDER BY id)
                          FROM Quote
                          WHERE id in :quoteIds];

    /** B - Mise à jour des indicateurs **/
    for (Quote quote : quotes)
        buildIndicators(quote, quote.devisIncontournables__r);

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return quotes;
  }

  /** 03 - Méthodes de calcul unitaire **/

  private static void incrementIndicators(Quote quote, KIncontournable__c incontournable) {
    // MAJ date et statut de 1er et dernier IEC
    if (incontournable.dateIncontournable__c != null) {
      if (quote.datePremierIncontournable__c == null || incontournable.dateIncontournable__c < quote.datePremierIncontournable__c) {
        quote.datePremierIncontournable__c   = incontournable.dateIncontournable__c;
        quote.statutPremierIncontournable__c = incontournable.statut__c;
      }
      if (quote.dateDernierIncontournable__c == null || incontournable.dateIncontournable__c > quote.dateDernierIncontournable__c) {
        quote.dateDernierIncontournable__c   = incontournable.dateIncontournable__c;
        quote.statutDernierIncontournable__c = incontournable.statut__c;
      }
    }

    // MAJ du nombre de IEC
    if (incontournable.statut__c.equalsIgnoreCase('EN COURS'))
      quote.nbIncontournablesEnCours__c = (quote.nbIncontournablesEnCours__c == null ? 0 : quote.nbIncontournablesEnCours__c) + 1;
    else if (incontournable.statut__c.equalsIgnoreCase('ENREGISTRE'))
      quote.nbIncontournablesEnregistres__c = (quote.nbIncontournablesEnregistres__c == null ? 0 : quote.nbIncontournablesEnregistres__c) + 1;
    else if (incontournable.statut__c.equalsIgnoreCase('TERMINE'))
      quote.nbIncontournablesTermines__c = (quote.nbIncontournablesTermines__c == null ? 0 : quote.nbIncontournablesTermines__c) + 1;
      
    System.debug('### TR021_KIncontournable.incrementIndicators ### ' + incontournable.statut__c + ' / ' + quote.nbIncontournablesEnCours__c + ' / ' + quote.nbIncontournablesEnregistres__c + ' / ' + quote.nbIncontournablesTermines__c);
  }

  private static void buildIndicators(Quote quote, List<KIncontournable__c> incontournables) {
    // Réinitialisation des indicateurs
    quote.datePremierIncontournable__c    = null;
    quote.dateDernierIncontournable__c    = null;
    quote.nbIncontournablesEnregistres__c = null;
    quote.nbIncontournablesEnCours__c     = null;
    quote.nbIncontournablesTermines__c    = null;
    quote.statutPremierIncontournable__c  = null;
    quote.statutDernierIncontournable__c  = null;

    // Calcul des indicateurs
    for (KIncontournable__c incontournable : incontournables)
      incrementIndicators(quote, incontournable);
  }
}