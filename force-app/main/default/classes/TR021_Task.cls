/* ************************************************************************* *
 * Tâche : Mise à jour des indicateurs                                       *
 * ************************************************************************* *
 * Version : 1.10                                                            *
 * Date    : 22/08/2014                                                      *
 * ************************************************************************* *
 * 1.10 : Ajout des indicateurs phoning                                      *
 * ************************************************************************* */

public class TR021_Task {
  private static final Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);
  private static final RecordType RT_Phoning = [SELECT id FROM RecordType WHERE name = 'FRA- Phoning vendeur' LIMIT 1];
  private static final String PATTERN_APPEL_SORTANT = 'Appel sortant';
  private static final String PATTERN_TAG_APPEL = 'Tag Appel';
  // private static final String PATTERN_EMAIL = 'E-mail :';
  private static final String PATTERN_EMAIL = 'E-mail';

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Répartition et calcul des indicateurs **/


    // Indicateurs en cumul uniquement. Sur insertion de tâche
    if (!Trigger.isInsert && !Trigger.isUpdate)
      return;

    List<SObject> objectsToUpdate = incrementIndicators((List<Task>) Trigger.new, (Map<Id, Task>) Trigger.oldMap);

    /** B - Sauvegarde des indicateurs **/
    if (objectsToUpdate != null && !objectsToUpdate.isEmpty())
      update objectsToUpdate;
  }

   /** 02 - Méthodes de calcul **/
  private static Boolean test(Task newTask, Task oldTask, String pattern) {
    return (
            (newTask.subject.startsWithIgnoreCase(pattern)) &&
            (oldTask == null || !oldTask.subject.startsWithIgnoreCase(pattern))
           );
  }
  
  private static Boolean test2(Task newTask, Task oldTask) {
    if (RT_Phoning == null)
      return false;
    return (
            (newTask.recordTypeId == RT_Phoning.id) &&
            (oldTask == null || oldTask.recordTypeId != RT_Phoning.id)
           );
  }


  private static List<SObject> incrementIndicators(List<Task> newTasks, Map<Id, Task> oldTasks) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds     = new Set<Id>();
    Set<Id> contactIds     = new Set<Id>();
    Set<Id> chantierIds    = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();
    Set<Id> quoteIds       = new Set<Id>();
    
    List<Task> tasks = new List<Task>();

    Map<Id, Account> accounts          = null;
    Map<Id, Contact> contacts          = null;
    Map<Id, Chantier__c> chantiers     = null;
    Map<Id, Opportunity> opportunities = null;
    Map<Id, Quote> quotes              = null;

    for (Task task : newTasks) 
      if (!AlreadyUsed.isUsed('TR021_Task', task.id)) {
        Task oldTask = Trigger.isInsert ? null : oldTasks.get(task.id);
        if (test(task, oldTask, PATTERN_APPEL_SORTANT) || test(task, oldTask, PATTERN_TAG_APPEL) || test(task, oldTask, PATTERN_EMAIL) || test2(task, oldTask)) {
          System.debug('>>>>> Step 1');
          if (task.whatId != null) {
            if (task.whatId.getSObjectType() == Chantier__c.getSObjectType())
              chantierIds.add(task.whatId);
            else if (task.whatId.getSObjectType() == Opportunity.getSObjectType())
              opportunityIds.add(task.whatId);
            else if (task.whatId.getSObjectType() == Quote.getSObjectType())
              quoteIds.add(task.whatId);
          }

          if (task.whoId != null) {
            if (task.whoId.getSObjectType() == Account.getSObjectType())
              accountIds.add(task.whoId);
            else if (task.whoId.getSObjectType() == Contact.getSObjectType())
              contactIds.add(task.whoId);
          }
        
          tasks.add(task);
        }
      }

    if (accountIds.isEmpty() && contactIds.isEmpty() && chantierIds.isEmpty() && opportunityIds.isEmpty() && quoteIds.isEmpty())
      return null;

    if (!contactIds.isEmpty()) {
        contacts = new Map<Id, Contact>([SELECT accountId
                                         FROM Contact
                                         WHERE id in :contactIds]);
        for (Contact contact : contacts.values())
          if (contact.accountId != null)
            accountIds.add(contact.accountId);
    }

    if (!accountIds.isEmpty())
        accounts = new Map<Id, Account>([SELECT datePremierAppelSortant__c, dateDernierAppelSortant__c, nbAppelsSortants__c,
                                                datePremierPhoning__c, dateDernierPhoning__c, nbPhonings__c,
                                                datePremierTagAppel__c, dateDernierTagAppel__c, nbTagsAppel__c,
                                                datePremierEmail__c, dateDernierEmail__c, nbEmails__c
                                         FROM Account
                                         WHERE id in :accountIds]);
    if (!chantierIds.isEmpty())
        chantiers = new Map<Id, Chantier__c>([SELECT datePremierAppelSortant__c, dateDernierAppelSortant__c, nbAppelsSortants__c,
                                                     datePremierPhoning__c, dateDernierPhoning__c, nbPhonings__c,
                                                     datePremierTagAppel__c, dateDernierTagAppel__c, nbTagsAppel__c,
                                                     datePremierEmail__c, dateDernierEmail__c, nbEmails__c
                                              FROM Chantier__c
                                              WHERE id in :chantierIds]);
    if (!opportunityIds.isEmpty())
        opportunities = new Map<Id, Opportunity>([SELECT datePremierAppelSortant__c, dateDernierAppelSortant__c, nbAppelsSortants__c,
                                                         datePremierPhoning__c, dateDernierPhoning__c, nbPhonings__c,
                                                         datePremierTagAppel__c, dateDernierTagAppel__c, nbTagsAppel__c,
                                                         datePremierEmail__c, dateDernierEmail__c, nbEmails__c
                                                  FROM Opportunity
                                                  WHERE id in :opportunityIds]);
    if (!quoteIds.isEmpty())
        quotes = new Map<Id, Quote>([SELECT datePremierAppelSortant__c, dateDernierAppelSortant__c, nbAppelsSortants__c,
                                            datePremierPhoning__c, dateDernierPhoning__c, nbPhonings__c,
                                            datePremierTagAppel__c, dateDernierTagAppel__c, nbTagsAppel__c,
                                            datePremierEmail__c, dateDernierEmail__c, nbEmails__c
                                     FROM Quote
                                     WHERE id in :quoteIds]);

    if ((accounts == null || accounts.isEmpty())   &&
        (chantiers == null || chantiers.isEmpty()) &&
        (opportunities == null || opportunities.isEmpty())&&
        (quotes == null || quotes.isEmpty()))
      return null;

    /** B - Mise à jour des indicateurs **/
    for (Task task : tasks) {
      Task oldTask = Trigger.isInsert ? null : oldTasks.get(task.id);
      if (test2(task, oldTask)) {
        if (task.whatId != null) {
          if (task.whatId.getSObjectType() == Chantier__c.getSObjectType()) {
            Chantier__c chantier = chantiers.get(task.whatId);

            if (chantier.datePremierPhoning__c == null)
              chantier.datePremierPhoning__c = task.createdDate;
            chantier.dateDernierPhoning__c = task.createdDate;
            chantier.nbPhonings__c = (chantier.nbPhonings__c == null ? 0 : chantier.nbPhonings__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Opportunity.getSObjectType()) {
            Opportunity opportunity = opportunities.get(task.whatId);

            if (opportunity.datePremierPhoning__c == null)
              opportunity.datePremierPhoning__c = task.createdDate;
            opportunity.dateDernierPhoning__c = task.createdDate;
            opportunity.nbPhonings__c = (opportunity.nbPhonings__c == null ? 0 : opportunity.nbPhonings__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Quote.getSObjectType()) {
            Quote quote = quotes.get(task.whatId);

            if (quote.datePremierPhoning__c == null)
              quote.datePremierPhoning__c = task.createdDate;
            quote.dateDernierPhoning__c = task.createdDate;
            quote.nbPhonings__c = (quote.nbPhonings__c == null ? 0 : quote.nbPhonings__c) + 1;
          }
        }

        if (task.whoId != null) {
          Account account = accounts.get(task.whoId);
          if (account == null)
            account = accounts.get(contacts.get(task.whoId).accountId);

          if (account.datePremierPhoning__c == null)
            account.datePremierPhoning__c = task.createdDate;
          account.dateDernierPhoning__c = task.createdDate;
          account.nbPhonings__c = (account.nbPhonings__c == null ? 0 : account.nbPhonings__c) + 1;
        }
      }

      else if (test(task, oldTask, PATTERN_APPEL_SORTANT)){
        if (task.whatId != null) {
          if (task.whatId.getSObjectType() == Chantier__c.getSObjectType()) {
            Chantier__c chantier = chantiers.get(task.whatId);

            if (chantier.datePremierAppelSortant__c == null)
              chantier.datePremierAppelSortant__c = task.createdDate;
            chantier.dateDernierAppelSortant__c = task.createdDate;
            chantier.nbAppelsSortants__c = (chantier.nbAppelsSortants__c == null ? 0 : chantier.nbAppelsSortants__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Opportunity.getSObjectType()) {
            Opportunity opportunity = opportunities.get(task.whatId);

            if (opportunity.datePremierAppelSortant__c == null)
              opportunity.datePremierAppelSortant__c = task.createdDate;
            opportunity.dateDernierAppelSortant__c = task.createdDate;
            opportunity.nbAppelsSortants__c = (opportunity.nbAppelsSortants__c == null ? 0 : opportunity.nbAppelsSortants__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Quote.getSObjectType()) {
            Quote quote = quotes.get(task.whatId);

            if (quote.datePremierAppelSortant__c == null)
              quote.datePremierAppelSortant__c = task.createdDate;
            quote.dateDernierAppelSortant__c = task.createdDate;
            quote.nbAppelsSortants__c = (quote.nbAppelsSortants__c == null ? 0 : quote.nbAppelsSortants__c) + 1;
          }
        }

        if (task.whoId != null) {
          Account account = accounts.get(task.whoId);
          if (account == null)
            account = accounts.get(contacts.get(task.whoId).accountId);

          if (account.datePremierAppelSortant__c == null)
              account.datePremierAppelSortant__c = task.createdDate;
            account.dateDernierAppelSortant__c = task.createdDate;
            account.nbAppelsSortants__c = (account.nbAppelsSortants__c == null ? 0 : account.nbAppelsSortants__c) + 1;
        }
      }

      else if (test(task, oldTask, PATTERN_TAG_APPEL)){
        if (task.whatId != null) {
          if (task.whatId.getSObjectType() == Chantier__c.getSObjectType()) {
            Chantier__c chantier = chantiers.get(task.whatId);

            if (chantier.datePremierTagAppel__c == null)
              chantier.datePremierTagAppel__c = task.createdDate;
            chantier.dateDernierTagAppel__c = task.createdDate;
            chantier.nbTagsAppel__c = (chantier.nbTagsAppel__c == null ? 0 : chantier.nbTagsAppel__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Opportunity.getSObjectType()) {
            Opportunity opportunity = opportunities.get(task.whatId);

            if (opportunity.datePremierTagAppel__c == null)
              opportunity.datePremierTagAppel__c = task.createdDate;
            opportunity.dateDernierTagAppel__c = task.createdDate;
            opportunity.nbTagsAppel__c = (opportunity.nbTagsAppel__c == null ? 0 : opportunity.nbTagsAppel__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Quote.getSObjectType()) {
            Quote quote = quotes.get(task.whatId);

            if (quote.datePremierTagAppel__c == null)
              quote.datePremierTagAppel__c = task.createdDate;
            quote.dateDernierTagAppel__c = task.createdDate;
            quote.nbTagsAppel__c = (quote.nbTagsAppel__c == null ? 0 : quote.nbTagsAppel__c) + 1;
          }
        }

        if (task.whoId != null) {
          Account account = accounts.get(task.whoId);
          if (account == null)
            account = accounts.get(contacts.get(task.whoId).accountId);

          if (account.datePremierTagAppel__c == null)
            account.datePremierTagAppel__c = task.createdDate;
          account.dateDernierTagAppel__c = task.createdDate;
          account.nbTagsAppel__c = (account.nbTagsAppel__c == null ? 0 : account.nbTagsAppel__c) + 1;
        }
      }

      else if (test(task, oldTask, PATTERN_EMAIL)){
      // else if (task.subject.contains('mail')){
        if (task.whatId != null) {
          if (task.whatId.getSObjectType() == Chantier__c.getSObjectType()) {
            Chantier__c chantier = chantiers.get(task.whatId);

            if (chantier.datePremierEmail__c == null)
              chantier.datePremierEmail__c = task.createdDate;
            chantier.dateDernierEmail__c = task.createdDate;
            chantier.nbEmails__c = (chantier.nbEmails__c == null ? 0 : chantier.nbEmails__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Opportunity.getSObjectType()) {
            Opportunity opportunity = opportunities.get(task.whatId);

            if (opportunity.datePremierEmail__c == null)
              opportunity.datePremierEmail__c = task.createdDate;
            opportunity.dateDernierEmail__c = task.createdDate;
            opportunity.nbEmails__c = (opportunity.nbEmails__c == null ? 0 : opportunity.nbEmails__c) + 1;
          }
          else if (task.whatId.getSObjectType() == Quote.getSObjectType()) {
            Quote quote = quotes.get(task.whatId);

            if (quote.datePremierEmail__c == null)
              quote.datePremierEmail__c = task.createdDate;
            quote.dateDernierEmail__c = task.createdDate;
            quote.nbEmails__c = (quote.nbEmails__c == null ? 0 : quote.nbEmails__c) + 1;
          }
        }

        if (task.whoId != null) {
          Account account = accounts.get(task.whoId);
          if (account == null)
            account = accounts.get(contacts.get(task.whoId).accountId);

          if (account.datePremierEmail__c == null)
            account.datePremierEmail__c = task.createdDate;
          account.dateDernierEmail__c = task.createdDate;
          account.nbEmails__c = (account.nbEmails__c == null ? 0 : account.nbEmails__c) + 1;
        }
      }
    }

    /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
    List<SObject> objectsToUpdate = new List<SObject>();
    if (accounts != null && !accounts.isEmpty())
      objectsToUpdate.addAll((List<SObject>) accounts.values());
    if (chantiers != null && !chantiers.isEmpty())
      objectsToUpdate.addAll((List<SObject>) chantiers.values());
    if (opportunities != null && !opportunities.isEmpty())
      objectsToUpdate.addAll((List<SObject>) opportunities.values());
    if (quotes != null && !quotes.isEmpty())
      objectsToUpdate.addAll((List<SObject>) quotes.values());

    return objectsToUpdate;
  }
}