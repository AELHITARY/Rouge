/* ************************************************************************* *
 * Contrats K : Alimentation des indicateurs                                 *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 12/03/2013                                                      *
 * ************************************************************************* *
 */

public class TR021_KContrat {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Répartition et calcul des indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    // Insert
    if (Trigger.isInsert) {
      List<sObject> data = incrementIndicators(Trigger.new);
      if (data != null && !data.isEmpty())
        objectsToUpdate.addAll(data);
    }
    // Update
    else if (Trigger.isUpdate) {
      Set<ID> accountIds = new Set<ID>();
      Set<ID> chantierIds = new Set<ID>();
      Set<ID> quoteIds = new Set<ID>();

      for (KContrat__c newContrat : (List<KContrat__c>) Trigger.new) {
        KContrat__c oldContrat = (KContrat__c) Trigger.oldMap.get(newContrat.id);

        Boolean changed = newContrat.dateSignature__c        != oldContrat.dateSignature__c        ||
                          newContrat.dateResiliation__c      != oldContrat.dateResiliation__c      ||
                          newContrat.libelleStatutContrat__c != oldContrat.libelleStatutContrat__c ||
                          newContrat.montantHT__c            != oldContrat.montantHT__c            ||
                          newContrat.montantTTC__c           != oldContrat.montantTTC__c           ||
                          newContrat.datePremierIEC__c       != oldContrat.datePremierIEC__c       ||
                          newContrat.dateDernierIEC__c       != oldContrat.dateDernierIEC__c       ||
                          newContrat.nbIECEnCours__c         != oldContrat.nbIECEnCours__c         ||
                          newContrat.nbIECTermines__c        != oldContrat.nbIECTermines__c        ||
                          newContrat.statutPremierIEC__c     != oldContrat.statutPremierIEC__c     ||
                          newContrat.statutDernierIEC__c     != oldContrat.statutDernierIEC__c;

        if (enabledForceIndicators || newContrat.compte__c != oldContrat.compte__c || changed) {
          if (newContrat.compte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', newContrat.compte__c))
            accountIds.add(newContrat.compte__c);
          if (oldContrat.compte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', oldContrat.compte__c))
            accountIds.add(oldContrat.compte__c);
        }

        if (enabledForceIndicators || newContrat.autreCompte__c != oldContrat.autreCompte__c || changed) {
          if (newContrat.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', newContrat.autreCompte__c))
            accountIds.add(newContrat.autreCompte__c);
          if (oldContrat.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', oldContrat.autreCompte__c))
            accountIds.add(oldContrat.autreCompte__c);
        }

        if (enabledForceIndicators || newContrat.chantier__c != oldContrat.chantier__c || changed) {
          if (newContrat.chantier__c != null && !AlreadyUsed.isUsed('TR021_KContrat', newContrat.chantier__c))
            chantierIds.add(newContrat.chantier__c);
          if (oldContrat.chantier__c != null && !AlreadyUsed.isUsed('TR021_KContrat', oldContrat.chantier__c))
            chantierIds.add(oldContrat.chantier__c);
        }

        if (enabledForceIndicators || newContrat.devis__c != oldContrat.devis__c || changed) {
          if (newContrat.devis__c != null && !AlreadyUsed.isUsed('TR021_KContrat', newContrat.devis__c))
            quoteIds.add(newContrat.devis__c);
          if (oldContrat.devis__c != null && !AlreadyUsed.isUsed('TR021_KContrat', oldContrat.devis__c))
            quoteIds.add(oldContrat.devis__c);
        }
      }
      if (!accountIds.isEmpty()) {
        List<sObject> data = buildAccountIndicators(accountIds);
        if (data != null && !data.isEmpty())
          objectsToUpdate.addAll(data);
      }
      if (!chantierIds.isEmpty()) {
        List<sObject> data = buildChantierIndicators(chantierIds);
        if (data != null && !data.isEmpty())
          objectsToUpdate.addAll(data);
      }
      if (!quoteIds.isEmpty()) {
        List<sObject> data = buildQuoteIndicators(quoteIds);
        if (data != null && !data.isEmpty())
          objectsToUpdate.addAll(data);
      }
    }
    // Delete
    else if (Trigger.isDelete) {
      List<sObject> data = buildIndicators(Trigger.old);
      if (data != null && !data.isEmpty())
          objectsToUpdate.addAll(data);
    }

    /** B - Sauvegarde des indicateurs **/
    if (objectsToUpdate != null && !objectsToUpdate.isEmpty())
      update objectsToUpdate;
  }


  /** 02 - Méthodes de calcul **/
  private static List<sObject> incrementIndicators(List<KContrat__c> contrats) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds = new Set<Id>();
    Set<Id> chantierIds = new Set<Id>();
    Set<Id> quoteIds = new Set<Id>();

    for (KContrat__c contrat : contrats) {
      if (contrat.compte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.compte__c))
        accountIds.add(contrat.compte__c);
      if (contrat.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.autreCompte__c))
        accountIds.add(contrat.autreCompte__c);
      if (contrat.chantier__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.chantier__c))
        chantierIds.add(contrat.chantier__c);
      if (contrat.devis__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.devis__c))
        quoteIds.add(contrat.devis__c);
    }

    if (accountIds.isEmpty() && chantierIds.isEmpty() && quoteIds.isEmpty())
      return null;

    Map<Id, Account> accounts = new Map<Id, Account>([SELECT datePremierContrat__c, dateDernierContrat__c,
                                                             statutPremierContrat__c, statutDernierContrat__c,
                                                             totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                             nbContratsResilies__c, nbContratsVendus__c,
                                                             datePremierIEC__c, dateDernierIEC__c,
                                                             nbIECEnCours__c, nbIECTermines__c,
                                                             statutPremierIEC__c, statutDernierIEC__c
                                                      FROM account
                                                      WHERE id in :accountIds]);
    Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>([SELECT datePremierContrat__c, dateDernierContrat__c,
                                                                      statutPremierContrat__c, statutDernierContrat__c,
                                                                      totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                                      nbContratsResilies__c, nbContratsVendus__c,
                                                                      datePremierIEC__c, dateDernierIEC__c,
                                                                      nbIECEnCours__c, nbIECTermines__c,
                                                                      statutPremierIEC__c, statutDernierIEC__c
                                                               FROM chantier__c
                                                               WHERE id in :chantierIds]);
    Map<Id, Quote> quotes = new Map<Id, Quote>([SELECT datePremierContrat__c, dateDernierContrat__c,
                                                       statutPremierContrat__c, statutDernierContrat__c,
                                                       totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                       nbContratsResilies__c, nbContratsVendus__c
                                                FROM Quote
                                                WHERE id in :quoteIds]);

    /** B - Mise à jour des indicateurs **/
    for (KContrat__c contrat : contrats) {
      if (contrat.compte__c != null && accounts.containsKey(contrat.compte__c))
        incrementIndicators(accounts.get(contrat.compte__c), contrat);
      if (contrat.autreCompte__c != null && accounts.containsKey(contrat.autreCompte__c))
        incrementIndicators(accounts.get(contrat.autreCompte__c), contrat);

      if (contrat.chantier__c != null && chantiers.containsKey(contrat.chantier__c))
        incrementIndicators(chantiers.get(contrat.chantier__c), contrat);

      if (contrat.devis__c != null && quotes.containsKey(contrat.devis__c))
        incrementIndicators(quotes.get(contrat.devis__c), contrat);
    }

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (accounts != null)
      objectsToUpdate.addAll((List<sObject>) accounts.values());
    if (chantiers != null)
      objectsToUpdate.addAll((List<sObject>) chantiers.values());
    if (quotes != null)
    objectsToUpdate.addAll((List<sObject>) quotes.values());
    return objectsToUpdate;
  }

  private static List<sObject> buildIndicators(List<KContrat__c> contrats) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds = new Set<Id>();
    Set<Id> chantierIds = new Set<Id>();
    Set<Id> quoteIds = new Set<Id>();

    for (KContrat__c contrat : contrats) {
      if (contrat.compte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.compte__c))
        accountIds.add(contrat.compte__c);
      if (contrat.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.autreCompte__c))
        accountIds.add(contrat.autreCompte__c);
      if (contrat.chantier__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.chantier__c))
        chantierIds.add(contrat.chantier__c);
      if (contrat.devis__c != null && !AlreadyUsed.isUsed('TR021_KContrat', contrat.devis__c))
        quoteIds.add(contrat.devis__c);
    }

    if (accountIds.isEmpty() && chantierIds.isEmpty() && quoteIds.isEmpty())
      return null;

    /** B - Mise à jour des indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (!accountIds.isEmpty())
       objectsToUpdate.addAll(buildAccountIndicators(accountIds));
    if (!chantierIds.isEmpty())
       objectsToUpdate.addAll(buildChantierIndicators(chantierIds));
    if (!quoteIds.isEmpty())
       objectsToUpdate.addAll(buildQuoteIndicators(quoteIds));

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return objectsToUpdate;
  }

  private static List<sObject> buildAccountIndicators(Set<ID> accountIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Account> accounts = [SELECT datePremierContrat__c, dateDernierContrat__c,
                                     statutPremierContrat__c, statutDernierContrat__c,
                                     totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                     nbContratsResilies__c, nbContratsVendus__c,
                                     datePremierIEC__c, dateDernierIEC__c,
                                     nbIECEnCours__c, nbIECTermines__c,
                                     statutPremierIEC__c, statutDernierIEC__c,
                                     (SELECT dateSignature__c, dateResiliation__c, libelleStatutContrat__c,
                                             montantHT__c, montantTTC__c,
                                             datePremierIEC__c, dateDernierIEC__c,
                                             nbIECEnCours__c, nbIECTermines__c,
                                             statutPremierIEC__c, statutDernierIEC__c
                                      FROM compteContrats__r
                                      ORDER BY id),
                                     (SELECT dateSignature__c, dateResiliation__c, libelleStatutContrat__c,
                                             montantHT__c, montantTTC__c,
                                             datePremierIEC__c, dateDernierIEC__c,
                                             nbIECEnCours__c, nbIECTermines__c,
                                             statutPremierIEC__c, statutDernierIEC__c
                                      FROM autreCompteContrats__r
                                      ORDER BY id)
                              FROM account
                              WHERE id in :accountIds];
    /** B - Mise à jour des indicateurs **/
    for (Account account : accounts) {
        List<KContrat__c> contrats = new List<KContrat__c>(account.compteContrats__r);
        contrats.addAll(account.autreCompteContrats__r);
        buildIndicators(account, contrats);
    }

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return accounts;
  }

  private static List<sObject> buildChantierIndicators(Set<ID> chantierIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Chantier__c> chantiers = [SELECT datePremierContrat__c, dateDernierContrat__c,
                                          statutPremierContrat__c, statutDernierContrat__c,
                                          totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                          nbContratsResilies__c, nbContratsVendus__c,
                                          datePremierIEC__c, dateDernierIEC__c,
                                          nbIECEnCours__c, nbIECTermines__c,
                                          statutPremierIEC__c, statutDernierIEC__c,
                                          (SELECT dateSignature__c, dateResiliation__c, libelleStatutContrat__c,
                                                  montantHT__c, montantTTC__c,
                                                  datePremierIEC__c, dateDernierIEC__c,
                                                  nbIECEnCours__c, nbIECTermines__c,
                                                  statutPremierIEC__c, statutDernierIEC__c
                                           FROM chantierContrats__r
                                           ORDER BY id)
                                   FROM chantier__c
                                   WHERE id in :chantierIds];

    /** B - Mise à jour des indicateurs **/
    for (Chantier__c chantier : chantiers)
        buildIndicators(chantier, chantier.chantierContrats__r);

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return chantiers;
  }

  private static List<sObject> buildQuoteIndicators(Set<ID> quoteIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Quote> quotes = [SELECT datePremierContrat__c, dateDernierContrat__c,
                                 statutPremierContrat__c, statutDernierContrat__c,
                                 totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                 nbContratsResilies__c, nbContratsVendus__c,
                                 (SELECT dateSignature__c, dateResiliation__c, libelleStatutContrat__c,
                                         montantHT__c, montantTTC__c,
                                         datePremierIEC__c, dateDernierIEC__c,
                                         nbIECEnCours__c, nbIECTermines__c,
                                         statutPremierIEC__c, statutDernierIEC__c
                                  FROM devisContrats__r
                                  ORDER BY id)
                                 FROM Quote
                                 WHERE id in :quoteIds];

    /** B - Mise à jour des indicateurs **/
    for (Quote quote : quotes)
        buildIndicators(quote, quote.devisContrats__r);

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return quotes;
  }

  /** 03 - Méthodes de calcul unitaire **/
  private static void incrementIndicators(SObject aObject, KContrat__c contrat) {
    // MAJ date de 1er et dernier contrat
    if (contrat.dateSignature__c != null) {
      if (aObject.get('datePremierContrat__c') == null || contrat.dateSignature__c < (Date)aObject.get('datePremierContrat__c')) {
        aObject.put('datePremierContrat__c', contrat.dateSignature__c);
        aObject.put('statutPremierContrat__c', contrat.libelleStatutContrat__c);
      }
      if (aObject.get('dateDernierContrat__c') == null || contrat.dateSignature__c > (Date)aObject.get('dateDernierContrat__c')) {
        aObject.put('dateDernierContrat__c', contrat.dateSignature__c);
        aObject.put('statutDernierContrat__c', contrat.libelleStatutContrat__c);
      }
    }

    // MAJ montant TTC et HT des contrats
    if (contrat.dateResiliation__c == null) {
      aObject.put('totalHTContratsVendus__c',  (aObject.get('totalHTContratsVendus__c')  == null ? 0 : (Double)aObject.get('totalHTContratsVendus__c')) +
                                               (contrat.montantHT__c               == null ? 0 : contrat.montantHT__c));
      aObject.put('totalTTCContratsVendus__c', (aObject.get('totalTTCContratsVendus__c') == null ? 0 : (Double)aObject.get('totalTTCContratsVendus__c')) +
                                               (contrat.montantTTC__c              == null ? 0 : contrat.montantTTC__c));
    }
    else {
      aObject.put('totalHTContratsResilies__c', (aObject.get('totalHTContratsResilies__c')  == null ? 0 : (Double)aObject.get('totalHTContratsResilies__c')) +
                                                (contrat.montantHT__c               == null ? 0 : contrat.montantHT__c));
      aObject.put('totalTTCContratsResilies__c', (aObject.get('totalTTCContratsResilies__c') == null ? 0 : (Double)aObject.get('totalTTCContratsResilies__c')) +
                                                 (contrat.montantTTC__c              == null ? 0 : contrat.montantTTC__c));
    }

    // MAJ du nombre de contrats
    if (contrat.dateResiliation__c == null)
      aObject.put('nbContratsVendus__c', (aObject.get('nbContratsVendus__c') == null ? 0 : (Double)aObject.get('nbContratsVendus__c')) + 1);
    else
      aObject.put('nbContratsResilies__c', (aObject.get('nbContratsResilies__c') == null ? 0 : (Double)aObject.get('nbContratsResilies__c')) + 1);

    if (aObject.getSObjectType() != Quote.getSObjectType()) {
      // MAJ // MAJ date de 1er et dernier IEC
      if (contrat.datePremierIEC__c != null) {
        if (aObject.get('datePremierIEC__c') == null || contrat.datePremierIEC__c < (Date)aObject.get('datePremierIEC__c')) {
          aObject.put('datePremierIEC__c', contrat.datePremierIEC__c);
          aObject.put('statutPremierIEC__c', contrat.statutPremierIEC__c);
        }
        if (aObject.get('dateDernierIEC__c') == null || contrat.dateDernierIEC__c > (Date)aObject.get('dateDernierIEC__c')) {
          aObject.put('dateDernierIEC__c', contrat.datePremierIEC__c);
          aObject.put('statutDernierIEC__c', contrat.statutDernierIEC__c);
        }
      }

      // MAJ nombre d'IEC
      if (contrat.nbIECEnCours__c == null)
        aObject.put('nbIECEnCours__c', (aObject.get('nbIECEnCours__c') == null ? 0 : (Double)aObject.get('nbIECEnCours__c')) + 1);
      if (contrat.nbIECTermines__c == null)
        aObject.put('nbIECTermines__c', (aObject.get('nbIECTermines__c') == null ? 0 : (Double)aObject.get('nbIECTermines__c')) + 1);
    }
  }

  private static void buildIndicators(SObject aObject, List<KContrat__c> contrats) {
    // Réinitialisation des indicateurs
    aObject.put('datePremierContrat__c', null);
    aObject.put('dateDernierContrat__c', null);
    aObject.put('statutPremierContrat__c', null);
    aObject.put('statutDernierContrat__c', null);
    aObject.put('totalHTContratsVendus__c', null);
    aObject.put('totalTTCContratsVendus__c', null);
    aObject.put('totalHTContratsResilies__c', null);
    aObject.put('totalTTCContratsResilies__c', null);
    aObject.put('nbContratsVendus__c', null);
    aObject.put('nbContratsResilies__c', null);

    if (aObject.getSObjectType() != Quote.getSObjectType()) {
      aObject.put('datePremierIEC__c', null);
      aObject.put('statutPremierIEC__c', null);
      aObject.put('dateDernierIEC__c', null);
      aObject.put('statutDernierIEC__c', null);
      aObject.put('nbIECEnCours__c', null);
      aObject.put('nbIECTermines__c', null);
    }

    // Calcul des indicateurs
    for (KContrat__c contrat : contrats)
      incrementIndicators(aObject, contrat);
  }
}