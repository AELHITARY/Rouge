/* ************************************************************************* *
 * Alimentation des indicateurs R040                                         *
 * ************************************************************************* *
 * Version : 1.12                                                            *
 * Date    : 04/06/2015                                                      *
 * ************************************************************************* */

public class TR022_R040 {
  private static final Boolean ENABLED = PropertiesUtils.getBooleanValue('function.enabled.r040', false);
  private static final Map<Opportunity, Integer> mapQuoteCount = new Map<Opportunity, Integer>();
  private static final Map<Opportunity, Decimal> mapQuoteTotal = new Map<Opportunity, Decimal>();

  // A - Trigger sur les quotes

  public static void fillR040FromQuotes(UserContext userContext) {
    if (!Trigger.isExecuting || Trigger.isBefore || !ENABLED)
      return;

    List<Quote> quotes = new List<Quote>();
    for (Quote quote : (List<Quote>) (Trigger.isDelete ? Trigger.old : Trigger.new))
      if (!AlreadyUsed.isUsed('TR022_R040', quote.id))
        quotes.add(quote);

    if (quotes.isEmpty())
      return;

    if (Trigger.isInsert)
      fillR040FromInsertedQuotes(quotes);
    if (Trigger.isUpdate)
      fillR040FromUpdatedQuotes(quotes, (Map<Id, Quote>)Trigger.oldMap);
    if (Trigger.isDelete)
      fillR040FromDeletedQuotes(quotes);
  }

  private static void fillR040FromInsertedQuotes(List<Quote> quotes) {
    Set<ID> opportunityIds = new Set<ID>();
    for (Quote quote : quotes)
      if (!String.isEmpty(quote.status) && quote.status.startsWith('Vendu'))
        opportunityIds.add(quote.opportunityId);

    if (opportunityIds.isEmpty())
      return;

    Map<ID, Opportunity> opportunities = new Map<ID, Opportunity>([SELECT id, ownerId
                                                                   FROM Opportunity
                                                                   WHERE id IN :opportunityIds]);

    if (opportunities.isEmpty())
      return;

    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities.values())
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Quote quote : quotes)
      if (!String.isEmpty(quote.status) && quote.status.startsWith('Vendu')) {
        Opportunity opportunity = opportunities.get(quote.opportunityId);
        if (opportunity != null) {
          User user = users.get(opportunity.ownerId);
          if (user != null) {
            reset(user);
            user.nombre_devis__c++;
            user.CA_genere__c += (quote.totalHTDevis__c == null ? 0 : quote.totalHTDevis__c);

            UserStats__c stats = userStats.get(user.id);
            if (stats == null) {
              // stats = new UserStats__c(user__c = user.id, date__c = TODAY);
              stats = createUserStats(user);
              userStats.put(user.id, stats);
            }
            stats.nombreDevis__c++;
            stats.CAGenere__c += (quote.totalHTDevis__c == null ? 0 : quote.totalHTDevis__c);
            stats.CADevisGeneres__c += (quote.totalHTDevis__c == null ? 0 : quote.totalHTDevis__c);
          }
        }
      }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromUpdatedQuotes(List<Quote> newQuotes, Map<Id, Quote> oldQuotes) {
    Set<ID> opportunityIds = new Set<ID>();
    for (Quote newQuote : newQuotes) {
      Quote oldQuote = oldQuotes.get(newQuote.id);

      if (newQuote.opportunityId != null)
        opportunityIds.add(newQuote.opportunityId);
      if (oldQuote.opportunityId != null)
        opportunityIds.add(oldQuote.opportunityId);
    }

    if (opportunityIds.isEmpty())
      return;

    Map<ID, Opportunity> opportunities = new Map<ID, Opportunity>([SELECT id, ownerId
                                                                   FROM Opportunity
                                                                   WHERE id IN :opportunityIds]);

    if (opportunities.isEmpty())
      return;

    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities.values())
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Quote newQuote : newQuotes) {
      Quote oldQuote = oldQuotes.get(newQuote.id);
      Opportunity newOpportunity = opportunities.get(newQuote.opportunityId);
      Opportunity oldOpportunity = opportunities.get(oldQuote.opportunityId);
      Decimal newMontant = (newQuote.totalHTDevis__c == null ? 0 : newQuote.totalHTDevis__c);
      Decimal oldMontant = (oldQuote.totalHTDevis__c == null ? 0 : oldQuote.totalHTDevis__c);

      if (!String.isEmpty(newQuote.status) &&
          (( newQuote.status.startsWith('Vendu') && !oldQuote.status.startsWith('Vendu')) ||
           (!newQuote.status.startsWith('Vendu') &&  oldQuote.status.startsWith('Vendu')) ||
           ( newQuote.status.startsWith('Vendu') &&  oldQuote.status.startsWith('Vendu') &&
             /**
             (newOpportunity.ownerId != oldOpportunity.ownerId || newMontant != oldMontant)
             **/
             newOpportunity.ownerId != oldOpportunity.ownerId
           )
          )) {
        User newUser = users.get(newOpportunity.ownerId);
        User oldUser = users.get(oldOpportunity.ownerId);

        if (newUser != null && ((newQuote.status.startsWith('Vendu') && !oldQuote.status.startsWith('Vendu'))
                                ||
                                (newOpportunity.ownerId != oldOpportunity.ownerId)
                                ||
                                (newMontant != oldMontant)
                               )) {
          reset(newUser);
          newUser.nombre_devis__c++;
          newUser.CA_genere__c += newMontant;

          UserStats__c stats = userStats.get(newUser.id);
          if (stats == null) {
            // stats = new UserStats__c(user__c = newUser.id, date__c = TODAY);
            stats = createUserStats(newUser);
            userStats.put(newUser.id, stats);
          }
          stats.nombreDevis__c++;
          stats.CAGenere__c += newMontant;
          stats.CADevisGeneres__c += newMontant;
        }

        if (oldUser != null && ((!newQuote.status.startsWith('Vendu') &&  oldQuote.status.startsWith('Vendu'))
                                ||
                                (newOpportunity.ownerId != oldOpportunity.ownerId)
                                ||
                                (newMontant != oldMontant)
                               )) {
          reset(oldUser);
          oldUser.nombre_devis__c--;
          oldUser.CA_genere__c -= oldMontant;

          UserStats__c stats = userStats.get(oldUser.id);
          if (stats == null) {
            // stats = new UserStats__c(user__c = oldUser.id, date__c = TODAY);
            stats = createUserStats(oldUser);
            userStats.put(oldUser.id, stats);
          }
          stats.nombreDevis__c--;
          stats.CAGenere__c -= oldMontant;
          if ((newOpportunity.ownerId != oldOpportunity.ownerId) || (newMontant != oldMontant))
            stats.CADevisGeneres__c -= oldMontant;
        }
      }
    }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromDeletedQuotes(List<Quote> quotes) {
    Set<ID> opportunityIds = new Set<ID>();
    for (Quote quote : quotes)
      if (!String.isEmpty(quote.status) && quote.status.startsWith('Vendu'))
        opportunityIds.add(quote.opportunityId);

    if (opportunityIds.isEmpty())
      return;

    Map<ID, Opportunity> opportunities = new Map<ID, Opportunity>([SELECT id, ownerId
                                                                   FROM Opportunity
                                                                   WHERE id IN :opportunityIds]);

    if (opportunities.isEmpty())
      return;

    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities.values())
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Quote quote : quotes)
      if (!String.isEmpty(quote.status) && quote.status.startsWith('Vendu')) {
        Opportunity opportunity = opportunities.get(quote.opportunityId);
        if (opportunity != null) {
          User user = users.get(opportunity.ownerId);
          if (user != null) {
            reset(user);
            user.nombre_devis__c--;
            user.CA_genere__c -= (quote.totalHTDevis__c == null ? 0 : quote.totalHTDevis__c);

            UserStats__c stats = userStats.get(user.id);
            if (stats == null) {
              stats = createUserStats(user);
              userStats.put(user.id, stats);
            }
            stats.nombreDevis__c--;
            stats.CAGenere__c -= (quote.totalHTDevis__c == null ? 0 : quote.totalHTDevis__c);
          }
        }
      }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  // B - Trigger sur les opportunities
  public static void countR040FromDeletedOpportunities(UserContext userContext) {
    if (!Trigger.isExecuting || Trigger.isAfter || !Trigger.isDelete || !ENABLED)
      return;

    List<Opportunity> opportunities = (List<Opportunity>)Trigger.old;

    List<Quote> quotes = [SELECT id, opportunityId, totalHTDevis__c
                          FROM Quote
                          WHERE opportunityId IN :opportunities
                            AND status LIKE 'Vendu%'];

    for (Opportunity opportunity : opportunities) {
      Integer quoteCount = mapQuoteCount.containsKey(opportunity) ? mapQuoteCount.get(opportunity) : 0;
      Decimal quoteTotal = mapQuoteTotal.containsKey(opportunity) ? mapQuoteTotal.get(opportunity) : 0;
      for (Quote quote : quotes)
        if (quote.opportunityId == opportunity.id) {
          quoteCount++;
          quoteTotal += quote.totalHTDevis__c;
        }
      mapQuoteCount.put(opportunity, quoteCount);
      mapQuoteTotal.put(opportunity, quoteTotal);
    }
  }

  public static void fillR040FromOpportunities(UserContext userContext) {
    if (!Trigger.isExecuting || Trigger.isBefore || !ENABLED)
      return;

    List<Opportunity> opportunities = new List<Opportunity>();
    for (Opportunity opportunity : (List<Opportunity>) (Trigger.isDelete ? Trigger.old : Trigger.new))
      if (!AlreadyUsed.isUsed('TR022_R040', opportunity.id))
        opportunities.add(opportunity);

    if (opportunities.isEmpty())
      return;

    if (Trigger.isInsert)
      fillR040FromInsertedOpportunities(opportunities);
    if (Trigger.isUpdate)
      fillR040FromUpdatedOpportunities(opportunities, (Map<Id, Opportunity>)Trigger.oldMap);
    if (Trigger.isDelete)
      fillR040FromDeletedOpportunities(opportunities);
  }

  private static void fillR040FromInsertedOpportunities(List<Opportunity> opportunities) {
    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities)
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Opportunity opportunity : opportunities) {
      User user = users.get(opportunity.ownerId);
      if (user != null) {
        reset(user);
        if (opportunity.callSource__c != null)
          user.nombre_projets_call__c++;
        else
          user.nombre_projets__c++;

        UserStats__c stats = userStats.get(user.id);
        if (stats == null) {
          stats = createUserStats(user);
          userStats.put(user.id, stats);
        }
        if (opportunity.callSource__c != null)
          stats.nombreProjetsCall__c++;
        else
          stats.nombreProjets__c++;
      }
    }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromUpdatedOpportunities(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
    Set<ID> userIds = new Set<ID>();
    for (Opportunity newOpportunity : newOpportunities) {
      Opportunity oldOpportunity = oldOpportunities.get(newOpportunity.id);
      if (newOpportunity.ownerId != oldOpportunity.ownerId) {
        if (newOpportunity.ownerId != null)
          userIds.add(newOpportunity.ownerId);
        if (oldOpportunity.ownerId != null)
          userIds.add(oldOpportunity.ownerId);
      }
    }

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    List<Quote> quotes = [SELECT id, opportunityId, totalHTDevis__c
                          FROM Quote
                          WHERE opportunityId IN :newOpportunities
                            AND status LIKE 'Vendu%'];

    for (Opportunity newOpportunity : newOpportunities) {
      Opportunity oldOpportunity = oldOpportunities.get(newOpportunity.id);
      if (newOpportunity.ownerId != oldOpportunity.ownerId) {
        User newUser = users.get(newOpportunity.ownerId);
        User oldUser = users.get(oldOpportunity.ownerId);

        Integer quoteCount = 0;
        Decimal quoteTotal = 0;
        for (Quote quote : quotes)
          if (quote.opportunityId == newOpportunity.id) {
            quoteCount++;
            quoteTotal += quote.totalHTDevis__c;
          }

        if (newUser != null) {
          reset(newUser);
          if (newOpportunity.callSource__c != null)
            newUser.nombre_projets_call__c++;
          else
            newUser.nombre_projets__c++;
          newUser.nombre_devis__c += quoteCount;
          newUser.CA_genere__c += quoteTotal;

          UserStats__c stats = userStats.get(newUser.id);
          if (stats == null) {
            // stats = new UserStats__c(user__c = newUser.id, date__c = TODAY);
            stats = createUserStats(newUser);
            userStats.put(newUser.id, stats);
          }
          if (newOpportunity.callSource__c != null)
            stats.nombreProjetsCall__c++;
          else
            stats.nombreProjets__c++;
          stats.nombreDevis__c += quoteCount;
          stats.CAGenere__c += quoteTotal;
        }

        if (oldUser != null) {
          reset(oldUser);
          if (oldOpportunity.callSource__c != null)
            oldUser.nombre_projets_call__c--;
          else
            oldUser.nombre_projets__c--;
          oldUser.nombre_devis__c -= quoteCount;
          oldUser.CA_genere__c -= quoteTotal;

          UserStats__c stats = userStats.get(oldUser.id);
          if (stats == null) {
            // stats = new UserStats__c(user__c = oldUser.id, date__c = TODAY);
            stats = createUserStats(oldUser);
            userStats.put(oldUser.id, stats);
          }
          if (oldOpportunity.callSource__c != null)
            stats.nombreProjetsCall__c--;
          else
            stats.nombreProjets__c--;
          stats.nombreDevis__c -= quoteCount;
          stats.CAGenere__c -= quoteTotal;
        }
      }
    }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromDeletedOpportunities(List<Opportunity> opportunities) {
    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities)
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Opportunity opportunity : opportunities) {
      User user = users.get(opportunity.ownerId);

      Integer quoteCount = mapQuoteCount.containsKey(opportunity) ? mapQuoteCount.get(opportunity) : 0;
      Decimal quoteTotal = mapQuoteTotal.containsKey(opportunity) ? mapQuoteTotal.get(opportunity) : 0;

      if (user != null) {
        reset(user);
        if (opportunity.callSource__c != null)
          user.nombre_projets_call__c--;
        else
          user.nombre_projets__c--;
        user.nombre_devis__c -= quoteCount;
        user.CA_genere__c -= quoteTotal;

        UserStats__c stats = userStats.get(user.id);
        if (stats == null) {
          stats = createUserStats(user);
          userStats.put(user.id, stats);
        }
        if (opportunity.callSource__c != null)
          stats.nombreProjetsCall__c--;
        else
          stats.nombreProjets__c--;
        stats.nombreDevis__c -= quoteCount;
        stats.CAGenere__c -= quoteTotal;
      }
    }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  // C - Trigger sur les événements
  public static void fillR040FromEvents(UserContext userContext) {
    if (!Trigger.isExecuting || Trigger.isBefore || !ENABLED)
      return;

    List<Event> events = new List<Event>();
    for (Event event : (List<Event>) (Trigger.isDelete ? Trigger.old : Trigger.new))
      if (!AlreadyUsed.isUsed('TR022_R040', event.id) && ('R1'.equalsIgnoreCase(event.type) || 'R2'.equalsIgnoreCase(event.type) || 'R+'.equalsIgnoreCase(event.type)))
        events.add(event);

    if (events.isEmpty())
      return;

    if (Trigger.isInsert)
      fillR040FromInsertedEvents(events);
    if (Trigger.isUpdate)
      fillR040FromUpdatedEvents(events, (Map<Id, Event>)Trigger.oldMap);
    if (Trigger.isDelete)
      fillR040FromDeletedEvents(events);
  }

  private static void fillR040FromInsertedEvents(List<Event> events) {
    Set<ID> userIds = new Set<ID>();
    for (Event event : events)
      if (event.ownerId != null && 'Effectué'.equalsIgnoreCase(event.statutRDV__c))
        userIds.add(event.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Event event : events)
      if (event.ownerId != null && 'Effectué'.equalsIgnoreCase(event.statutRDV__c)) {
        User user = users.get(event.ownerId);
        if (user != null) {
          reset(user);
          user.nombre_RDV_effectues__c++;
          if ('R1'.equalsIgnoreCase(event.type))
            user.nombre_R1_effectues__c++;

          UserStats__c stats = userStats.get(user.id);
          if (stats == null) {
            stats = createUserStats(user);
            userStats.put(user.id, stats);
          }
          stats.nombreRDVEffectues__c++;
          if ('R1'.equalsIgnoreCase(event.type))
            stats.nombreR1Effectues__c++;
        }
      }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromUpdatedEvents(List<Event> newEvents, Map<Id, Event> oldEvents) {
    Set<ID> userIds = new Set<ID>();
    for (Event newEvent : newEvents) {
      Event oldEvent = oldEvents.get(newEvent.id);
      if (newEvent.ownerId != null)
        userIds.add(newEvent.ownerId);
      if (oldEvent.ownerId != null)
        userIds.add(oldEvent.ownerId);
    }

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Event newEvent : newEvents) {
      Event oldEvent = oldEvents.get(newEvent.id);
      User newUser = users.get(newEvent.ownerId);
      User oldUser = users.get(oldEvent.ownerId);

      if (newUser != null && 'Effectué'.equalsIgnoreCase(newEvent.statutRDV__c)) {
        reset(newUser);
        newUser.nombre_RDV_effectues__c++;
        if ('R1'.equalsIgnoreCase(newEvent.type))
          newUser.nombre_R1_effectues__c++;

        UserStats__c stats = userStats.get(newUser.id);
        if (stats == null) {
          // stats = new UserStats__c(user__c = newUser.id, date__c = TODAY);
          stats = createUserStats(newUser);
          userStats.put(newUser.id, stats);
        }
        stats.nombreRDVEffectues__c++;
        if ('R1'.equalsIgnoreCase(newEvent.type))
          stats.nombreR1Effectues__c++;
      }

      if (oldUser != null && 'Effectué'.equalsIgnoreCase(oldEvent.statutRDV__c)) {
        reset(oldUser);
        oldUser.nombre_RDV_effectues__c--;
        if ('R1'.equalsIgnoreCase(oldEvent.type))
          oldUser.nombre_R1_effectues__c--;

        UserStats__c stats = userStats.get(oldUser.id);
        if (stats == null) {
          // stats = new UserStats__c(user__c = oldUser.id, date__c = TODAY);
          stats = createUserStats(oldUser);
          userStats.put(oldUser.id, stats);
        }
        stats.nombreRDVEffectues__c--;
        if ('R1'.equalsIgnoreCase(oldEvent.type))
          stats.nombreR1Effectues__c--;
      }
    }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromDeletedEvents(List<Event> events) {
    Set<ID> userIds = new Set<ID>();
    for (Event event : events)
      if (event.ownerId != null && 'Effectué'.equalsIgnoreCase(event.statutRDV__c))
        userIds.add(event.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (Event event : events)
      if (event.ownerId != null && 'Effectué'.equalsIgnoreCase(event.statutRDV__c)) {
        User user = users.get(event.ownerId);
        if (user != null) {
          reset(user);
          user.nombre_RDV_effectues__c--;
          if ('R1'.equalsIgnoreCase(event.type))
            user.nombre_R1_effectues__c--;

          UserStats__c stats = userStats.get(user.id);
          if (stats == null) {
            stats = createUserStats(user);
            userStats.put(user.id, stats);
          }
          stats.nombreRDVEffectues__c--;
          if ('R1'.equalsIgnoreCase(event.type))
            stats.nombreR1Effectues__c--;
        }
      }

    if (!users.isEmpty())
      Database.update(users.values(), FALSE);
    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  // E - Trigger sur les contrats
  public static void fillR040FromKContrats(UserContext userContext) {
    if (!Trigger.isExecuting || Trigger.isBefore || Trigger.isDelete || !ENABLED)
      return;

    List<KContrat__c> contrats = new List<KContrat__c>();
    for (KContrat__c contrat : (List<KContrat__c>) (Trigger.new))
      if (!AlreadyUsed.isUsed('TR022_R040', contrat.id))
        contrats.add(contrat);

    if (contrats.isEmpty())
      return;

    if (Trigger.isInsert)
      fillR040FromInsertedKContrats(contrats);
    else if (Trigger.isUpdate)
      fillR040FromUpdatedKContrats(contrats, (Map<Id, KContrat__c>)Trigger.oldMap);
  }

  private static void fillR040FromInsertedKContrats(List<KContrat__c> contrats) {
    // 1 - Recherche des devis associés aux contrats
    Set<ID> quoteIds = new Set<ID>();
    for (KContrat__c contrat : contrats)
      if (contrat.devis__c != null)
        quoteIds.add(contrat.devis__c);

    if (quoteIds.isEmpty())
      return;

    Map<ID, Quote> quotes = new Map<ID, Quote>([SELECT id, opportunityId
                                                FROM Quote
                                                WHERE id IN :quoteIds]);

    if (quotes.isEmpty())
      return;

    // 2 - Recherche des projets associés aux devis des contrats
    Set<ID> opportunityIds = new Set<ID>();
    for (Quote quote : quotes.values())
      opportunityIds.add(quote.opportunityId);

    if (opportunityIds.isEmpty())
      return;

    Map<ID, Opportunity> opportunities = new Map<ID, Opportunity>([SELECT id, ownerId
                                                                   FROM Opportunity
                                                                   WHERE id IN :opportunityIds]);

    if (opportunities.isEmpty())
      return;

    // 3 - Recherche des propriétaires des projets associés aux devis des contrats
    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities.values())
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (KContrat__c contrat : contrats) {
      Quote quote = quotes.get(contrat.devis__c);
      if (quote != null) {
        Opportunity opportunity = opportunities.get(quote.opportunityId);
        if (opportunity != null) {
          User user = users.get(opportunity.ownerId);
          if (user != null) {
            UserStats__c stats = userStats.get(user.id);
            if (stats == null) {
              stats = createUserStats(user);
              userStats.put(user.id, stats);
            }
            if (!'Contrats resilies'.equalsIgnoreCase(contrat.libelleStatutContrat__c))
              stats.CAContratsCrees__c += contrat.montantTTC__c == null ? 0 : contrat.montantTTC__c;
          }
        }
      }
    }

    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  private static void fillR040FromUpdatedKContrats(List<KContrat__c> newContrats, Map<Id, KContrat__c> oldContrats) {
    // 1 - Recherche des devis associés aux contrats
    Set<ID> quoteIds = new Set<ID>();
    for (KContrat__c newContrat : newContrats) {
      if (newContrat.devis__c != null)
        quoteIds.add(newContrat.devis__c); // Le devis de l'ancien et du nouveau contrat sont obligatoirement les mêmes car donneé non modifiable en GC
    }

    if (quoteIds.isEmpty())
      return;

    Map<ID, Quote> quotes = new Map<ID, Quote>([SELECT id, opportunityId
                                                FROM Quote
                                                WHERE id IN :quoteIds]);

    if (quotes.isEmpty())
      return;

    // 2 - Recherche des projets associés aux devis des contrats
    Set<ID> opportunityIds = new Set<ID>();
    for (Quote quote : quotes.values())
      opportunityIds.add(quote.opportunityId);

    if (opportunityIds.isEmpty())
      return;

    Map<ID, Opportunity> opportunities = new Map<ID, Opportunity>([SELECT id, ownerId
                                                                   FROM Opportunity
                                                                   WHERE id IN :opportunityIds]);

    if (opportunities.isEmpty())
      return;

    // 3 - Recherche des propriétaires des projets associés aux devis des contrats
    Set<ID> userIds = new Set<ID>();
    for (Opportunity opportunity : opportunities.values())
      if (opportunity.ownerId != null)
        userIds.add(opportunity.ownerId);

    if (userIds.isEmpty())
      return;

    Map<ID, User> users = getUsers(userIds);

    if (users.isEmpty())
      return;

    Map<ID, UserStats__c> userStats = getUserStats(users.keySet());

    for (KContrat__c newContrat : newContrats) {
      KContrat__c oldContrat = oldContrats.get(newContrat.id);

      Double newMontant = 'Contrats resilies'.equalsIgnoreCase(newContrat.libelleStatutContrat__c) ? 0 : (newContrat.montantTTC__c == null ? 0 : newContrat.montantTTC__c);
      Double oldMontant = 'Contrats resilies'.equalsIgnoreCase(oldContrat.libelleStatutContrat__c) ? 0 : (oldContrat.montantTTC__c == null ? 0 : oldContrat.montantTTC__c);
      Double delta = newMontant - oldMontant;

      if (delta != 0) {
        Quote newQuote = quotes.get(newContrat.devis__c);
        if (newQuote != null) {
          Opportunity newOpportunity = opportunities.get(newQuote.opportunityId);
          if (newOpportunity != null) {
            User newUser = users.get(newOpportunity.ownerId);

            if (newUser != null) { 
              UserStats__c stats = userStats.get(newUser.id);
              if (stats == null) {
                stats = createUserStats(newUser);
                userStats.put(newUser.id, stats);
              }
              stats.CAContratsModifies__c += delta;
            }
          }
        }
      }
    }

    if (!userStats.isEmpty())
      Database.upsert(userStats.values(), FALSE);
  }

  // X - Fonctions utilitaires

  private static void reset(User user) {
    if (user.date_stat__c == null || user.date_stat__c < System.today()) {
      user.nombre_leads_convertis__c      = 0;
      user.nombre_leads_generes__c        = 0;
      user.nombre_projets__c              = 0;
      user.nombre_devis__c                = 0;
      user.nombre_projets_call__c         = 0;
      user.nombre_leads_convertis_call__c = 0;
      user.nombre_leads_generes_call__c   = 0;
      user.CA_genere__c                   = 0;
      user.nombre_RDV_effectues__c        = 0;
      user.nombre_R1_effectues__c         = 0;
      user.date_stat__c                   = System.today();
    }
  }

  private static Map<Id, User> getUsers(Set<ID> userIds) {
    return new Map<ID, User>([SELECT id, name, date_stat__c,
                                     nombre_leads_generes_call__c, nombre_leads_generes__c,
                                     nombre_leads_convertis_call__c, nombre_leads_convertis__c,
                                     nombre_projets_call__c, nombre_projets__c,
                                     nombre_devis__c, CA_genere__c,
                                     nombre_RDV_effectues__c, nombre_R1_effectues__c
                              FROM User
                              WHERE id IN :userIds
                                AND isActive = TRUE
                                AND profile.name IN ('K/K - RV',
                                                     'K/K - RV - Mobile',
                                                     'K/K - RVJ',
                                                     'K/K - RVJ - Mobile',                                                     
                                                     'K/K - Vendeur',
                                                     'K/K - Vendeur - Mobile',                                                     
                                                     'K/K - En charge de magasin',
                                                     'K/K - En charge de magasin - Mobile')
                                                     ]);
  }

  private static Map<Id, UserStats__c> getUserStats(Set<ID> userIds) {
    List<UserStats__c> userStatsList = [SELECT id, name, user__c, date__c,                                               
                                               compteurCartographie__c, compteurFeuilleRoute__c,
                                               nombreDevis__c, nombreProjets__c, nombreProjetsCall__c, nombreR1Effectues__c, nombreRDVEffectues__c,
                                               CAGenere__c, CADevisGeneres__c, CAContratsCrees__c, CAContratsModifies__c
                                        FROM UserStats__c
                                        WHERE user__c IN :userIds
                                          AND date__c = TODAY];

    Map<ID, UserStats__c> userStatsMap = new Map<ID, UserStats__c>();

    for (UserStats__c stats : userStatsList)
      userStatsMap.put(stats.user__c, stats);

    return userStatsMap;
  }

  private static UserStats__c createUserStats(User user) {
    return new UserStats__c(name                    = user.name + ' / ' + System.today(),
                            user__c                 = user.id,
                            date__c                 = System.today(),
                            CAGenere__c             = 0,
                            compteurCartographie__c = 0,
                            compteurFeuilleRoute__c = 0,
                            nombreDevis__c          = 0,
                            nombreProjets__c        = 0,
                            nombreProjetsCall__c    = 0,
                            nombreR1Effectues__c    = 0,
                            nombreRDVEffectues__c   = 0,
                            CADevisGeneres__c       = 0,
                            CAContratsCrees__c      = 0,
                            CAContratsModifies__c   = 0);
  }
}