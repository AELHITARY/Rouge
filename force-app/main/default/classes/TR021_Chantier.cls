/* ************************************************************************* *
 * Chantier : Alimentation des indicateurs                                   *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 25/03/2013                                                      *
 * ************************************************************************* *
 */

public class TR021_Chantier {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Répartition et calcul des indicateurs **/
    Set<Id> accountIds = new Set<Id>();

    // Insert
    if (Trigger.isInsert) {
      for (Chantier__c newChantier : (List<Chantier__c>) Trigger.new) {
        if (enabledForceIndicators || newChantier.proprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.proprietaire__c))
          accountIds.add(newChantier.proprietaire__c);
        if (enabledForceIndicators || newChantier.autreProprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreProprietaire__c))
          accountIds.add(newChantier.autreProprietaire__c);
        if (enabledForceIndicators || newChantier.locataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.locataire__c))
          accountIds.add(newChantier.locataire__c);
        if (enabledForceIndicators || newChantier.autreLocataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreLocataire__c))
          accountIds.add(newChantier.autreLocataire__c);
        if (enabledForceIndicators || newChantier.occupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.occupant__c))
          accountIds.add(newChantier.occupant__c);
        if (enabledForceIndicators || newChantier.autreOccupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreOccupant__c))
          accountIds.add(newChantier.autreOccupant__c);
      }
    }
    // Update
    else if (Trigger.isUpdate) {
      for (Chantier__c newChantier : (List<Chantier__c>) Trigger.new) {
        Chantier__c oldChantier = (Chantier__c) Trigger.oldMap.get(newChantier.id);
        
        if (newChantier.proprietaire__c != oldChantier.proprietaire__c) {     
          if (newChantier.proprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.proprietaire__c))
            accountIds.add(newChantier.proprietaire__c); 
          if (oldChantier.proprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.proprietaire__c))
            accountIds.add(oldChantier.proprietaire__c);
        }       
        if (newChantier.autreProprietaire__c != oldChantier.autreProprietaire__c) {     
          if (newChantier.autreProprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreProprietaire__c))
            accountIds.add(newChantier.autreProprietaire__c); 
          if (oldChantier.autreProprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreProprietaire__c))
            accountIds.add(oldChantier.autreProprietaire__c);
        }
        
        if (newChantier.locataire__c != oldChantier.locataire__c) {     
          if (newChantier.locataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.locataire__c))
            accountIds.add(newChantier.locataire__c); 
          if (oldChantier.locataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.locataire__c))
            accountIds.add(oldChantier.locataire__c);
        }       
        if (newChantier.autreLocataire__c != oldChantier.autreLocataire__c) {     
          if (newChantier.autreLocataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreLocataire__c))
            accountIds.add(newChantier.autreLocataire__c); 
          if (oldChantier.autreLocataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreLocataire__c))
            accountIds.add(oldChantier.autreLocataire__c);
        }
        
        if (newChantier.occupant__c != oldChantier.occupant__c) {     
          if (newChantier.occupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.occupant__c))
            accountIds.add(newChantier.occupant__c); 
          if (oldChantier.occupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.occupant__c))
            accountIds.add(oldChantier.occupant__c);
        }       
        if (newChantier.autreOccupant__c != oldChantier.autreOccupant__c) {     
          if (newChantier.autreOccupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', newChantier.autreOccupant__c))
            accountIds.add(newChantier.autreOccupant__c); 
          if (oldChantier.autreOccupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreOccupant__c))
            accountIds.add(oldChantier.autreOccupant__c);
        }
      }
    }
    // Delete
    else if (Trigger.isDelete) {
      for (Chantier__c oldChantier : (List<Chantier__c>) Trigger.old) {
        if (oldChantier.proprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.proprietaire__c))
          accountIds.add(oldChantier.proprietaire__c);
        if (oldChantier.autreProprietaire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreProprietaire__c))
          accountIds.add(oldChantier.autreProprietaire__c);
        if (oldChantier.locataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.locataire__c))
          accountIds.add(oldChantier.locataire__c);
        if (oldChantier.autreLocataire__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreLocataire__c))
          accountIds.add(oldChantier.autreLocataire__c);
        if (oldChantier.occupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.occupant__c))
          accountIds.add(oldChantier.occupant__c);
        if (oldChantier.autreOccupant__c != null && !AlreadyUsed.isUsed('TR021_Chantier', oldChantier.autreOccupant__c))
          accountIds.add(oldChantier.autreOccupant__c);
      }
    }

    if (!accountIds.isEmpty()) {
      List<Account> accountsToUpdate = buildIndicators(accountIds);

      /** B - Sauvegarde des indicateurs **/
      if (accountsToUpdate != null && !accountsToUpdate.isEmpty())
        update accountsToUpdate;
    }
  }


  /** 02 - Méthodes de calcul **/
  private static List<Account> buildIndicators(Set<Id> accountIds ) {
    /** A - Initialisation des données intermédiaires **/
    List<Account> accounts = [SELECT nbChantiersLocataire__c, nbChantiersExLocataire__c,
                                     nbChantiersOccupant__c, nbChantiersExOccupant__c,
                                     nbChantiersProprietaire__c, nbChantiersExProprietaire__c,
                                     nbChantiersUniques__c,
                                     (SELECT id FROM proprietaireChantiers__r),
                                     (SELECT id FROM locataireChantiers__r),
                                     (SELECT id FROM occupantChantiers__r),

                                     (SELECT id FROM autreProprietaireChantiers__r),
                                     (SELECT id FROM autreLocataireChantiers__r),
                                     (SELECT id FROM autreOccupantChantiers__r),

                                     (SELECT id FROM proprietairePrecedentChantiers__r),
                                     (SELECT id FROM locatairePrecedentChantiers__r),
                                     (SELECT id FROM occupantPrecedentChantiers__r)

                              FROM Account
                              WHERE id in :accountIds];

    /** B - Mise à jour des indicateurs **/
    for (Account account : accounts) {
      account.nbChantiersLocataire__c    = (account.locataireChantiers__r      == null ? 0 : account.locataireChantiers__r.size())
                                         + (account.autreLocataireChantiers__r == null ? 0 : account.autreLocataireChantiers__r.size());
      account.nbChantiersExLocataire__c  = account.locatairePrecedentChantiers__r == null ? 0 : account.locatairePrecedentChantiers__r.size();
      account.nbChantiersOccupant__c     = (account.occupantChantiers__r       == null ? 0 : account.occupantChantiers__r.size())
                                         + (account.autreOccupantChantiers__r == null ? 0 : account.autreOccupantChantiers__r.size());
      account.nbChantiersExOccupant__c   = account.occupantPrecedentChantiers__r == null ? 0 : account.occupantPrecedentChantiers__r.size();
      account.nbChantiersProprietaire__c = (account.proprietaireChantiers__r      == null ? 0 : account.proprietaireChantiers__r.size())
                                         + (account.autreProprietaireChantiers__r == null ? 0 : account.autreProprietaireChantiers__r.size());
      account.nbChantiersExProprietaire__c = account.proprietairePrecedentChantiers__r == null ? 0 : account.proprietairePrecedentChantiers__r.size();

      Set<Chantier__c> chantiers = new Set<Chantier__c>();
      chantiers.addAll(account.locataireChantiers__r);
      chantiers.addAll(account.autreLocataireChantiers__r);
      chantiers.addAll(account.locatairePrecedentChantiers__r);
      chantiers.addAll(account.occupantChantiers__r);
      chantiers.addAll(account.autreOccupantChantiers__r);
      chantiers.addAll(account.occupantPrecedentChantiers__r);
      chantiers.addAll(account.proprietaireChantiers__r);
      chantiers.addAll(account.autreProprietaireChantiers__r);
      chantiers.addAll(account.proprietairePrecedentChantiers__r);

      account.nbChantiersUniques__c = chantiers.size();
    }

    /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
    return accounts;
  }
}