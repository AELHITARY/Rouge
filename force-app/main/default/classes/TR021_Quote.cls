/* ************************************************************************* *
 * Quote : Alimentation des indicateurs                                      *
 * ************************************************************************* *
 * Version : 1.02                                                            *
 * Date    : 25/03/2013                                                      *
 *           09/10/2015 - Intérêt marketing                                  * 
 * ************************************************************************* *
 */

public class TR021_Quote {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    System.debug('### DEBUT TR021_Quote : calculateIndicators');
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
      Set<ID> accountIds     = new Set<ID>();
      Set<ID> opportunityIds = new Set<ID>();

      for (Quote newQuote : (List<Quote>) Trigger.new) {
        Quote oldQuote = (Quote) Trigger.oldMap.get(newQuote.id);

        Boolean changed = newQuote.dateDevis__c                         != oldQuote.dateDevis__c                         ||
                          newQuote.status                               != oldQuote.status                               ||
                          newQuote.TotalTTCdevis__c                     != oldQuote.TotalTTCdevis__c                     ||
                          newQuote.TotalHTdevis__c                      != oldQuote.TotalHTdevis__c                      ||
                          newQuote.Remise_Enseigne_Options__c           != oldQuote.Remise_Enseigne_Options__c           ||
                          newQuote.RemisevendeurglobaleDeviseFormule__c != oldQuote.RemisevendeurglobaleDeviseFormule__c ||
                          newQuote.datePremierIncontournable__c         != oldQuote.datePremierIncontournable__c         ||
                          newQuote.dateDernierIncontournable__c         != oldQuote.dateDernierIncontournable__c         ||
                          newQuote.statutPremierIncontournable__c       != oldQuote.statutPremierIncontournable__c       ||
                          newQuote.statutDernierIncontournable__c       != oldQuote.statutDernierIncontournable__c       ||
                          newQuote.nbIncontournablesEnCours__c          != oldQuote.nbIncontournablesEnCours__c          ||
                          newQuote.nbIncontournablesEnregistres__c      != oldQuote.nbIncontournablesEnregistres__c      ||
                          newQuote.nbIncontournablesTermines__c         != oldQuote.nbIncontournablesTermines__c         ||
                          newQuote.datePremierContrat__c                != oldQuote.datePremierContrat__c                ||
                          newQuote.dateDernierContrat__c                != oldQuote.dateDernierContrat__c                ||
                          newQuote.statutPremierContrat__c              != oldQuote.statutPremierContrat__c              ||
                          newQuote.statutDernierContrat__c              != oldQuote.statutDernierContrat__c              ||
                          newQuote.totalHTContratsResilies__c           != oldQuote.totalHTContratsResilies__c           ||
                          newQuote.totalTTCContratsResilies__c          != oldQuote.totalTTCContratsResilies__c          ||
                          newQuote.totalHTContratsVendus__c             != oldQuote.totalHTContratsVendus__c             ||
                          newQuote.totalTTCContratsVendus__c            != oldQuote.totalTTCContratsVendus__c            ||
                          newQuote.nbContratsResilies__c                != oldQuote.nbContratsResilies__c                ||
                          newQuote.nbContratsVendus__c                  != oldQuote.nbContratsVendus__c                  ||
                          newQuote.interetMarketing__c                  != oldQuote.interetMarketing__c;
        if (enabledForceIndicators || newQuote.compte__c != oldQuote.compte__c || changed) {
          if (newQuote.compte__c != null && !AlreadyUsed.isUsed('TR021_Quote', newQuote.compte__c))
            accountIds.add(newQuote.compte__c);
          if (oldQuote.compte__c != null && !AlreadyUsed.isUsed('TR021_Quote', oldQuote.compte__c))
            accountIds.add(newQuote.compte__c);
        }

        if (enabledForceIndicators || newQuote.autreCompte__c != oldQuote.autreCompte__c || changed) {
          if (newQuote.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Quote', newQuote.autreCompte__c))
            accountIds.add(newQuote.autreCompte__c);
          if (oldQuote.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Quote', oldQuote.autreCompte__c))
            accountIds.add(newQuote.autreCompte__c);
        }

        if (enabledForceIndicators || newQuote.opportunity != oldQuote.opportunity || changed) {
          if (newQuote.opportunityId != null && !AlreadyUsed.isUsed('TR021_Quote', newQuote.opportunityId))
            opportunityIds.add(newQuote.opportunityId);
          if (oldQuote.opportunityId != null && !AlreadyUsed.isUsed('TR021_Quote', oldQuote.opportunityId))
            opportunityIds.add(oldQuote.opportunityId);
        }
      }

      if (!accountIds.isEmpty()) {
        List<sObject> data = buildAccountIndicators(accountIds);
        if (data != null && !data.isEmpty())
          objectsToUpdate.addAll(data);
      }

      if (!opportunityIds.isEmpty()) {
        List<sObject> data = buildOpportunityIndicators(opportunityIds);
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
  private static List<Opportunity> incrementIndicators(List<Quote> quotes) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds     = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();

    for (Quote quote : quotes) {
      if (quote.compte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', quote.compte__c))
        accountIds.add(quote.compte__c);
      if (quote.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', quote.autreCompte__c))
        accountIds.add(quote.autreCompte__c);
      if (quote.opportunityId != null && !AlreadyUsed.isUsed('TR021_Opportunity', quote.opportunityId))
        opportunityIds.add(quote.opportunityId);
    }

    if (accountIds.isEmpty() && opportunityIds.isEmpty())
      return null;

    Map<Id, Account> accounts = new Map<Id, Account>([SELECT datePremierDevis__c, dateDernierDevis__c, interetMarketing__c,
                                                             statutPremierDevis__c, statutDernierDevis__c,
                                                             totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                                             totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                                             nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                                             datePremierIncontournable__c, dateDernierIncontournable__c,
                                                             statutPremierIncontournable__c, statutDernierIncontournable__c,
                                                             nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                             datePremierContrat__c, dateDernierContrat__c,
                                                             statutPremierContrat__c, statutDernierContrat__c,
                                                             totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                             nbContratsResilies__c, nbContratsVendus__c
                                                      FROM Account
                                                      WHERE id in :accountIds]);

    Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([SELECT datePremierDevis__c, dateDernierDevis__c, interetMarketing__c,
                                                                          statutPremierDevis__c, statutDernierDevis__c,
                                                                          totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                                                          totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                                                          nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                                                          datePremierIncontournable__c, dateDernierIncontournable__c,
                                                                          statutPremierIncontournable__c, statutDernierIncontournable__c,
                                                                          nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                                          datePremierContrat__c, dateDernierContrat__c,
                                                                          statutPremierContrat__c, statutDernierContrat__c,
                                                                          totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                                          nbContratsResilies__c, nbContratsVendus__c
                                                                   FROM Opportunity
                                                                   WHERE id in :opportunityIds]);

    /** B - Mise à jour des indicateurs **/
    for (Quote quote : quotes)  {
      if (quote.compte__c != null && accounts.containsKey(quote.compte__c))
        incrementIndicators(accounts.get(quote.compte__c), quote);

      if (quote.autreCompte__c != null && accounts.containsKey(quote.autreCompte__c))
        incrementIndicators(accounts.get(quote.autreCompte__c), quote);

      if (quote.opportunityId != null && opportunities.containsKey(quote.opportunityId))
        incrementIndicators(opportunities.get(quote.opportunityId), quote);
    }

    /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (accounts != null)
      objectsToUpdate.addAll((List<sObject>) accounts.values());
    if (opportunities != null)
      objectsToUpdate.addAll((List<sObject>) opportunities.values());
    return objectsToUpdate;
  }

  private static List<Opportunity> buildIndicators(List<Quote> quotes) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();

    for (Quote quote : quotes) {
      if (!AlreadyUsed.isUsed('TR021_Quote', quote.compte__c))
        accountIds.add(quote.compte__c);
      if (!AlreadyUsed.isUsed('TR021_Quote', quote.autreCompte__c))
        accountIds.add(quote.autreCompte__c);
      if (!AlreadyUsed.isUsed('TR021_Quote', quote.opportunityId))
        opportunityIds.add(quote.opportunityId);
    }

    if (accountIds.isEmpty() && opportunityIds.isEmpty())
      return null;

    /** B - Mise à jour des indicateurs et retour des contrat à sauvegarder **/
    return buildOpportunityIndicators(opportunityIds);

    /** B - Mise à jour des indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (!accountIds.isEmpty())
      objectsToUpdate.addAll(buildAccountIndicators(accountIds));
    if (!opportunityIds.isEmpty())
      objectsToUpdate.addAll(buildOpportunityIndicators(opportunityIds));

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return objectsToUpdate;
  }

  private static List<SObject> buildAccountIndicators(Set<ID> accountIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Account> accounts = [SELECT datePremierDevis__c, dateDernierDevis__c, interetMarketing__c,
                                     statutPremierDevis__c, statutDernierDevis__c,
                                     totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                     totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                     nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                     datePremierIncontournable__c, dateDernierIncontournable__c,
                                     statutPremierIncontournable__c, statutDernierIncontournable__c,
                                     nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                     (SELECT createdDate, dateDevis__c, status, interetMarketing__c,
                                             TotalTTCdevis__c, TotalHTdevis__c, Remise_Enseigne_Options__c, RemisevendeurglobaleDeviseFormule__c,
                                             datePremierIncontournable__c, dateDernierIncontournable__c,
                                             statutPremierIncontournable__c, statutDernierIncontournable__c,
                                             nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c
                                      FROM compteDevis__r
                                      ORDER BY id),
                                     (SELECT createdDate, dateDevis__c, status, interetMarketing__c,
                                             TotalTTCdevis__c, TotalHTdevis__c, Remise_Enseigne_Options__c, RemisevendeurglobaleDeviseFormule__c,
                                             datePremierIncontournable__c, dateDernierIncontournable__c,
                                             statutPremierIncontournable__c, statutDernierIncontournable__c,
                                             nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c
                                      FROM autreCompteDevis__r
                                      ORDER BY id)
                              FROM Account
                              WHERE id in :accountIds];

    /** B - Mise à jour des indicateurs **/
    for (Account account : accounts) {
        List<Quote> quotes = new List<Quote>(account.compteDevis__r);
        quotes.addAll(account.autreCompteDevis__r);
        buildIndicators(account, quotes);
    }

    /** C - Retour des objets (account) dont il faut sauvegarder les indicateurs **/
    return accounts;
  }

  private static List<SObject> buildOpportunityIndicators(Set<ID> opportunityIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Opportunity> opportunities = [SELECT datePremierDevis__c, dateDernierDevis__c, interetMarketing__c,
                                              statutPremierDevis__c, statutDernierDevis__c,
                                              totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                              totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                              nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                              datePremierIncontournable__c, dateDernierIncontournable__c,
                                              statutPremierIncontournable__c, statutDernierIncontournable__c,
                                              nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                              datePremierContrat__c, dateDernierContrat__c,
                                              statutPremierContrat__c, statutDernierContrat__c,
                                              totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                              nbContratsResilies__c, nbContratsVendus__c,
                                              (SELECT createdDate, dateDevis__c, status, interetMarketing__c,
                                                      TotalTTCdevis__c, TotalHTdevis__c, Remise_Enseigne_Options__c, RemisevendeurglobaleDeviseFormule__c,
                                                      datePremierIncontournable__c, dateDernierIncontournable__c,
                                                      statutPremierIncontournable__c, statutDernierIncontournable__c,
                                                      nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                      datePremierContrat__c, dateDernierContrat__c,
                                                      statutPremierContrat__c, statutDernierContrat__c,
                                                      totalHTContratsResilies__c, totalTTCContratsResilies__c, totalHTContratsVendus__c, totalTTCContratsVendus__c,
                                                      nbContratsResilies__c, nbContratsVendus__c
                                               FROM quotes
                                               ORDER BY id)
                                       FROM Opportunity
                                       WHERE id in :opportunityIds];

    /** B - Mise à jour des indicateurs **/
    for (Opportunity opportunity : opportunities)
        buildIndicators(opportunity, opportunity.quotes);

    /** C - Retour des objets dont il faut sauvegarder les indicateurs **/
    return opportunities;
  }

  /** 03 - Méthodes de calcul unitaire **/
  private static void incrementIndicators(SObject aObject, Quote quote) {
    // MAJ date de 1er et dernier devis
    if (quote.dateDevis__c != null) {
      if (aObject.get('datePremierDevis__c') == null || quote.dateDevis__c < (Date)aObject.get('datePremierDevis__c')) {
        aObject.put('datePremierDevis__c', quote.dateDevis__c);
        aObject.put('statutPremierDevis__c', quote.status);
      }
      if (aObject.get('dateDernierDevis__c') == null || quote.dateDevis__c >= (Date)aObject.get('dateDernierDevis__c')) {
        aObject.put('dateDernierDevis__c', quote.dateDevis__c);
        aObject.put('statutDernierDevis__c', quote.status);
        System.debug('### TRACE ### ' + aObject.get('id') + ' # ' + quote.id + ' / ' + quote.createdDate + ' / ' + quote.dateDevis__c + ' / ' + quote.status);
      }
    }

    // MAJ montant des devis
    if (quote.status != null && 'Vendu en attente d\'enregistrement'.equalsIgnoreCase(quote.status)) {
      aObject.put('totalHTDevisEnAttente__c', (aObject.get('totalHTDevisEnAttente__c') == null ? 0 : (Double)aObject.get('totalHTDevisEnAttente__c')) +
                                              (quote.TotalHTdevis__c       == null ? 0 : quote.TotalHTdevis__c));
      aObject.put('totalTTCDevisEnAttente__c', (aObject.get('totalTTCDevisEnAttente__c') == null ? 0 : (Double)aObject.get('totalTTCDevisEnAttente__c')) +
                                               (quote.TotalTTCdevis__c       == null ? 0 : quote.TotalTTCdevis__c));
      aObject.put('totalRemisesEnAttenteEnseigne__c', (aObject.get('totalRemisesEnAttenteEnseigne__c') == null ? 0 : (Double)aObject.get('totalRemisesEnAttenteEnseigne__c')) +
                                                      (quote.Remise_Enseigne_Options__c    == null ? 0 : quote.Remise_Enseigne_Options__c));
      aObject.put('totalRemisesEnAttenteVendeur__c', (aObject.get('totalRemisesEnAttenteVendeur__c') == null ? 0 : (Double)aObject.get('totalRemisesEnAttenteVendeur__c')) +
                                                     (quote.RemisevendeurglobaleDeviseFormule__c == null ? 0 : quote.RemisevendeurglobaleDeviseFormule__c));
    }
    else if (quote.status != null && 'Vendu enregistré'.equalsIgnoreCase(quote.status)) {
      aObject.put('totalHTDevisEnregistres__c', (aObject.get('totalHTDevisEnregistres__c') == null ? 0 : (Double)aObject.get('totalHTDevisEnregistres__c')) +
                                                (quote.TotalHTdevis__c       == null ? 0 : quote.TotalHTdevis__c));
      aObject.put('totalTTCDevisEnregistres__c', (aObject.get('totalTTCDevisEnregistres__c') == null ? 0 : (Double)aObject.get('totalTTCDevisEnregistres__c')) +
                                                 (quote.TotalTTCdevis__c       == null ? 0 : quote.TotalTTCdevis__c));
      aObject.put('totalRemisesEnregistreesEnseigne__c', (aObject.get('totalRemisesEnregistreesEnseigne__c') == null ? 0 : (Double)aObject.get('totalRemisesEnregistreesEnseigne__c')) +
                                                         (quote.Remise_Enseigne_Options__c    == null ? 0 : quote.Remise_Enseigne_Options__c));
      aObject.put('totalRemisesEnregistreesVendeur__c', (aObject.get('totalRemisesEnregistreesVendeur__c') == null ? 0 : (Double)aObject.get('totalRemisesEnregistreesVendeur__c')) +
                                                        (quote.RemisevendeurglobaleDeviseFormule__c == null ? 0 : quote.RemisevendeurglobaleDeviseFormule__c));
    }

    // MAJ du nombre de projets
    if (quote.status != null) {
      String fieldName = null;
      if ('Non transmis'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisNonTransmis__c';
      else if ('Transmis'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisTransmis__c';
      else if ('Vendu en attente d\'enregistrement'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisVendusEnAttente__c';
      else if ('Vendu enregistré'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisVendusEnregistres__c';
      else if ('Vendu incontournable'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisVendusIncontournables__c';
      else if ('Résilié'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisResilies__c';
      else if ('Erroné'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisErrones__c';
      else if ('A configurer'.equalsIgnoreCase(quote.status))
        fieldName = 'nbDevisAConfigurer__c';
      else if ('Expiré'.equalsIgnoreCase(quote.status))  
        fieldName = 'nbDevisExpires__c';

      if (fieldName != null)
        aObject.put(fieldName, (aObject.get(fieldName) == null ? 0 : (Double)aObject.get(fieldName)) + 1);
    }

    // MAJ date et statut de 1er et dernier incontournable
    if (quote.datePremierIncontournable__c != null) {
      if (aObject.get('datePremierIncontournable__c') == null || quote.datePremierIncontournable__c < (Date)aObject.get('datePremierIncontournable__c')) {
        aObject.put('datePremierIncontournable__c', quote.datePremierIncontournable__c);
        aObject.put('statutPremierIncontournable__c', quote.statutPremierIncontournable__c);
      }
      if (aObject.get('dateDernierIncontournable__c') == null || quote.dateDernierIncontournable__c >= (Date)aObject.get('dateDernierIncontournable__c')) {
        aObject.put('dateDernierIncontournable__c', quote.dateDernierIncontournable__c);
        aObject.put('statutDernierIncontournable__c', quote.statutDernierIncontournable__c);
      }
    }

    // MAJ du nombres d'incontournables
    aObject.put('nbIncontournablesEnCours__c', (aObject.get('nbIncontournablesEnCours__c') == null ? 0 : (Double)aObject.get('nbIncontournablesEnCours__c')) +
                                               (quote.nbIncontournablesEnCours__c       == null ? 0 : quote.nbIncontournablesEnCours__c));
    aObject.put('nbIncontournablesEnregistres__c', (aObject.get('nbIncontournablesEnregistres__c') == null ? 0 : (Double)aObject.get('nbIncontournablesEnregistres__c')) +
                                                   (quote.nbIncontournablesEnregistres__c       == null ? 0 : quote.nbIncontournablesEnregistres__c));
    aObject.put('nbIncontournablesTermines__c', (aObject.get('nbIncontournablesTermines__c') == null ? 0 : (Double)aObject.get('nbIncontournablesTermines__c')) +
                                                (quote.nbIncontournablesTermines__c       == null ? 0 : quote.nbIncontournablesTermines__c));

    // MAJ date et statut de 1er et dernier contrat
    if (aObject.getSObjectType() == Opportunity.getSObjectType()) {
      if (quote.datePremierContrat__c != null) {
        if (aObject.get('datePremierContrat__c') == null || quote.datePremierContrat__c < (Date)aObject.get('datePremierContrat__c')) {
          aObject.put('datePremierContrat__c', quote.datePremierContrat__c);
          aObject.put('statutPremierContrat__c', quote.statutPremierContrat__c);
        }
        if (aObject.get('dateDernierContrat__c') == null || quote.dateDernierContrat__c >= (Date)aObject.get('dateDernierContrat__c')) {
          aObject.put('dateDernierContrat__c', quote.dateDernierContrat__c);
          aObject.put('statutDernierContrat__c', quote.statutDernierContrat__c);
        }
      }

      // MAJ du montant des contrats
      aObject.put('totalTTCContratsResilies__c', (aObject.get('totalTTCContratsResilies__c') == null ? 0 : (Double)aObject.get('totalTTCContratsResilies__c')) +
                                                 (quote.totalTTCContratsResilies__c       == null ? 0 : quote.totalTTCContratsResilies__c));
      aObject.put('totalHTContratsResilies__c', (aObject.get('totalHTContratsResilies__c') == null ? 0 : (Double)aObject.get('totalHTContratsResilies__c')) +
                                                (quote.totalHTContratsResilies__c       == null ? 0 : quote.totalHTContratsResilies__c));
      aObject.put('totalTTCContratsVendus__c', (aObject.get('totalTTCContratsVendus__c') == null ? 0 : (Double)aObject.get('totalTTCContratsVendus__c')) +
                                               (quote.totalTTCContratsVendus__c       == null ? 0 : quote.totalTTCContratsVendus__c));
      aObject.put('totalHTContratsVendus__c', (aObject.get('totalHTContratsVendus__c') == null ? 0 : (Double)aObject.get('totalHTContratsVendus__c')) +
                                              (quote.totalHTContratsVendus__c       == null ? 0 : quote.totalHTContratsVendus__c));

      // MAJ du nombres de contrats
      aObject.put('nbContratsResilies__c', (aObject.get('nbContratsResilies__c') == null ? 0 : (Double)aObject.get('nbContratsResilies__c')) +
                                           (quote.nbContratsResilies__c       == null ? 0 : quote.nbContratsResilies__c));
      aObject.put('nbContratsVendus__c', (aObject.get('nbContratsVendus__c') == null ? 0 : (Double)aObject.get('nbContratsVendus__c')) +
                                         (quote.nbContratsVendus__c       == null ? 0 : quote.nbContratsVendus__c));
    }
    
    // Intérêt marketing
    if (quote.interetMarketing__c)
      aObject.put('interetMarketing__c', TRUE);
  }

  private static void buildIndicators(SObject aObject, List<Quote> quotes) {
    // Réinitialisation des indicateurs
    aObject.put('datePremierDevis__c', null);
    aObject.put('dateDernierDevis__c', null);
    aObject.put('statutPremierDevis__c', null);
    aObject.put('statutDernierDevis__c', null);
    aObject.put('totalHTDevisEnAttente__c', null);
    aObject.put('totalTTCDevisEnAttente__c', null);
    aObject.put('totalHTDevisEnregistres__c', null);
    aObject.put('totalTTCDevisEnregistres__c', null);
    aObject.put('totalRemisesEnAttenteEnseigne__c', null);
    aObject.put('totalRemisesEnAttenteVendeur__c', null);
    aObject.put('totalRemisesEnregistreesEnseigne__c', null);
    aObject.put('totalRemisesEnregistreesVendeur__c', null);
    aObject.put('nbDevisAConfigurer__c', null);
    aObject.put('nbDevisErrones__c', null);
    aObject.put('nbDevisNonTransmis__c', null);
    aObject.put('nbDevisResilies__c', null);
    aObject.put('nbDevisExpires__c', null);
    aObject.put('nbDevisTransmis__c', null);
    aObject.put('nbDevisVendusEnAttente__c', null);
    aObject.put('nbDevisVendusEnregistres__c', null);
    aObject.put('nbDevisVendusIncontournables__c', null);

    aObject.put('datePremierIncontournable__c', null);
    aObject.put('dateDernierIncontournable__c', null);
    aObject.put('statutPremierIncontournable__c', null);
    aObject.put('statutDernierIncontournable__c', null);
    aObject.put('nbIncontournablesEnCours__c', null);
    aObject.put('nbIncontournablesEnregistres__c', null);
    aObject.put('nbIncontournablesTermines__c', null);
    aObject.put('interetMarketing__c', FALSE);

    if (aObject.getSObjectType() == Opportunity.getSObjectType()) {
      aObject.put('datePremierContrat__c', null);
      aObject.put('statutPremierContrat__c', null);
      aObject.put('dateDernierContrat__c', null);
      aObject.put('statutDernierContrat__c', null);
      aObject.put('totalTTCContratsResilies__c', null);
      aObject.put('totalHTContratsResilies__c', null);
      aObject.put('totalTTCContratsVendus__c', null);
      aObject.put('totalHTContratsVendus__c', null);
      aObject.put('nbContratsResilies__c', null);
      aObject.put('nbContratsVendus__c', null);
    }

    // Calcul des indicateurs
    for (Quote quote : quotes) {
      incrementIndicators(aObject, quote);
    }
    System.debug('### FIN TR021_Quote : calculateIndicators');
  }
}