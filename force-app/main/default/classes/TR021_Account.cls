/* ************************************************************************* *
 * Compte personnel & professionnel : Mise à jour des propriétaires,         *
 *                                    locataires et occupants des chantiers  *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 24/04/2013                                                      *
 * ************************************************************************* */

public class TR021_Account {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);
  private static final String ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
  private static final String PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);


  public static void UR001_K2_Chantier_setProprietairesLocatairesOccupants(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Initialisation des données intermédiaires **/


    /** B - Application des règles de mise à jour **/
    Set<ID> accountIds = new Set<ID>();
    if (Trigger.isUpdate) {
      List<Account> newAccounts = new List<Account>();      
      Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;

      // Récupération seulement des comptes PRO ou PERSO
      for(Account acc : (List<Account>)Trigger.new) {
          if(acc.RecordTypeId != ENTITY_RTID && acc.RecordTypeId != PROVIDER_RTID) {
              newAccounts.add(acc);
          }
      }
                
      for (Account newAccount : newAccounts) {
        Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
        /**
        if (newAccount.ownerid == oldAccount.ownerid) {   
        **/         
            if (newAccount.isPersonAccount) {
              if ((enabledForceIndicators ||
                   newAccount.salutation != oldAccount.salutation ||
                   newAccount.firstName != oldAccount.firstName ||
                   newAccount.lastName != oldAccount.lastName ||
                   newAccount.personMailingStreet != oldAccount.personMailingStreet ||
                   newAccount.personMailingPostalCode != oldAccount.personMailingPostalCode ||
                   newAccount.personMailingState != oldAccount.personMailingState ||
                   newAccount.personMailingCountry != oldAccount.personMailingCountry ||
                   newAccount.personEmail != oldAccount.personEmail ||
                   newAccount.personHomePhone != oldAccount.personHomePhone ||
                   newAccount.personMobilePhone != oldAccount.personMobilePhone ||
                   newAccount.phone != oldAccount.phone ||
                   newAccount.fichiersOpposition__c != oldAccount.fichiersOpposition__c)
                  &&
                  (!AlreadyUsed.isUsed('TR021_Account', newAccount.id))
                 )
                accountIds.add(oldAccount.id);
            }
            else {
              if ((enabledForceIndicators ||
                   newAccount.name != oldAccount.name ||
                   newAccount.billingStreet != oldAccount.billingStreet ||
                   newAccount.billingPostalCode != oldAccount.billingPostalCode ||
                   newAccount.billingState != oldAccount.billingState ||
                   newAccount.billingCountry != oldAccount.billingCountry ||
                   newAccount.phone != oldAccount.phone ||
                   newAccount.fichiersOpposition__c != oldAccount.fichiersOpposition__c)
                  &&
                  (!AlreadyUsed.isUsed('TR021_Account', newAccount.id))
                 )
                accountIds.add(oldAccount.id);
            }
          /**
          }
          **/          
      }
    }
    else if (Trigger.isDelete) {
      List<Account> oldAccounts = (List<Account>)Trigger.old;
      for (Account oldAccount : oldAccounts) {
        if(oldAccount.RecordTypeId != ENTITY_RTID && oldAccount.RecordTypeId != PROVIDER_RTID) {
          accountIds.add(oldAccount.id);
        }
      }
    }

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
    if (chantiersToUpdate != null && !chantiersToUpdate.isEmpty()) {
      TR020_Chantier.setProprietairesLocatairesOccupants(chantiersToUpdate);
      update chantiersToUpdate;
    }
  }
}