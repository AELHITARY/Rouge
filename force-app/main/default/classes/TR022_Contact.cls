/* ************************************************************************* *
 * Contact : Alimentation des contact par défaut pour les comptes B2B         *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 17/04/2013                                                      *
 * ************************************************************************* *
 */

public class TR022_Contact {

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void setDefaultContact(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Calcul **/
    List<Account> accountsToUpdate = new List<Account>();

    // Insert
    if (Trigger.isInsert || Trigger.isUpdate) {
      List<Contact> contacts = (List<Contact>) Trigger.new;
      Map<Id, Account> accounts = new Map<Id, Account>(getAccounts(contacts));
      for (Contact contact : contacts) {
        Account account = accounts.get(contact.accountId);
        if (account != null && account.contactParDefaut__c == null) {
          account.contactParDefaut__c = contact.id;
          accountsToUpdate.add(account);
        }
      }

    }
    // Delete
    else if (Trigger.isDelete) {
      List<Contact>    contacts        = (List<Contact>) Trigger.old;
      Map<Id, Account> accounts        = new Map<Id, Account>(getAccounts(contacts));
      List<Contact>    accountContacts = getContacts(accounts.keySet(), new Map<ID, Contact>(contacts).keySet());
      for (Contact contact : contacts) {
        Account account = accounts.get(contact.accountId);
        if (account != null && (account.contactParDefaut__c == null || account.contactParDefaut__c == contact.id)) {
          account.contactParDefaut__c = null;
          for (Contact accountContact : accountContacts)
            if (accountContact.accountId == account.id) {
              account.contactParDefaut__c = accountContact.id;
              break;
            }
          accountsToUpdate.add(account);
        }
      }
    }

    /** B - Sauvegarde **/
    if (!accountsToUpdate.isEmpty())
      update accountsToUpdate;
  }

  private static List<Account> getAccounts(List<Contact> contacts) {
    Set<Id> accountIds = new Set<Id>();
    for (Contact contact : contacts)
      accountIds.add(contact.accountId);
    return [SELECT contactParDefaut__c FROM account WHERE id IN :accountIds];
  }
  
  private static List<Contact> getContacts(Set<ID> accountIds, Set<ID> contactIds) {
    return [SELECT id, accountId
            FROM contact
            WHERE accountId IN :accountIds
              AND id NOT IN :contactIds];
  }
}