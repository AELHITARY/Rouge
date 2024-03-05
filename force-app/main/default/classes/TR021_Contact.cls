/* ************************************************************************* *
 * Contact                                                                   *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 25/09/2013                                                      *
 * ************************************************************************* */

public class TR021_Contact {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);


  public static void UR001_K2_Chantier_setProprietairesLocatairesOccupants(UserContext userContext) {
    System.debug('### TR021_Contact : 0 ###');
    if (!Trigger.isExecuting)
      return;

    /** A - Initialisation des données intermédiaires **/
    System.debug('### TR021_Contact : 1 ###');

    /** B - Application des règles de mise à jour **/
    Set<ID> accountIds = new Set<ID>();
    if (Trigger.isUpdate) {
      System.debug('### TR021_Contact : 2 ###');
      List<Contact> newContacts = (List<Contact>)Trigger.new;
      Map<Id, Contact> oldContacts = (Map<Id, Contact>)Trigger.oldMap;
                
      System.debug('### TR021_Contact : 3 ###');          
      for (Contact newContact : newContacts) {
        Contact oldContact = oldContacts == null ? null : oldContacts.get(newContact.id);
        
        System.debug('### TR021_Contact : 4 ### ' + newContact.name);
        if (!newContact.isPersonAccount) {
          System.debug('### TR021_Contact : 5 ### ' + newContact.email       + ' / ' + oldContact.email
                                          + ' ### ' + newContact.homePhone   + ' / ' + oldContact.homePhone
                                          + ' ### ' + newContact.mobilePhone + ' / ' + oldContact.mobilePhone
                                          + ' ### ' + newContact.phone       + ' / ' + oldContact.phone);
          if ((enabledForceIndicators                           ||
               newContact.email       != oldContact.email       ||
               newContact.homePhone   != oldContact.homePhone   ||
               newContact.mobilePhone != oldContact.mobilePhone ||
               newContact.phone       != oldContact.phone)
              &&
              (!AlreadyUsed.isUsed('TR021_Contact', newContact.id)))
            accountIds.add(oldContact.accountId);
        }          
      }
    }
    
    System.debug('### TR021_Contact : 6 ### ' + accountIds);
    if (accountIds.isEmpty())
      return;
    List<Chantier__c> chantiersToUpdate = [SELECT proprietaire__c, autreProprietaire__c, locataire__c, autreLocataire__c, occupant__c, autreOccupant__c,
                                                    civiliteProprietaires__c, nomProprietaires__c, prenomProprietaires__c, rueProprietaires__c, codePostalProprietaires__c, villeProprietaires__c, departementProprietaires__c, paysProprietaires__c, telephoneDomicileProprietaires__c, telephoneMobileProprietaires__c, telephoneProprietaires__c, emailProprietaires__c,
                                                    civiliteLocataires__c, nomLocataires__c, prenomLocataires__c, rueLocataires__c, codePostalLocataires__c, villeLocataires__c, departementLocataires__c, paysLocataires__c, telephoneDomicileLocataires__c, telephoneMobileLocataires__c, telephoneLocataires__c, emailLocataires__c,
                                                    civiliteOccupants__c, nomOccupants__c, prenomOccupants__c, rueOccupants__c, codePostalOccupants__c, villeOccupants__c, departementOccupants__c, paysOccupants__c, telephoneDomicileOccupants__c, telephoneMobileOccupants__c, telephoneOccupants__c, emailOccupants__c
                                           FROM Chantier__c
                                           WHERE proprietaire__c      IN :accountIds
                                              OR autreProprietaire__c IN :accountIds
                                              OR locataire__c         IN :accountIds
                                              OR autreLocataire__c    IN :accountIds
                                              OR occupant__c          IN :accountIds
                                              OR autreOccupant__c     IN :accountIds];
    System.debug('### TR021_Contact : 7 ### size = ' + chantiersToUpdate.size());                                          
    if (chantiersToUpdate != null && !chantiersToUpdate.isEmpty()) {
      System.debug('### TR021_Contact : 8 ###'); 
      TR020_Chantier.setProprietairesLocatairesOccupants(chantiersToUpdate);
      update chantiersToUpdate;
      System.debug('### TR021_Contact : 9 ###'); 
    }
  }
}