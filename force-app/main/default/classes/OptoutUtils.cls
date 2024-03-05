public class OptoutUtils {
  public static void updateAccounts(List<Account> accounts) {
    updateAccounts((new Map<Id, Account>(accounts)).keySet());
  }

  public static void updateAccounts(Set<Id> accountIds) {
    Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                               - Math.max(Limits.getCallouts(), Limits.getFutureCalls());          // Nombre actuel d'appels (out et/ou future)

    if (availableCallCount <= 0)
      return;

    Set<Id> smallList = new Set<Id>();
    for (Id accountId : accountIds)
      if (!AlreadyUsed.isUsed('OptoutUtils', accountId)) {
        smallList.add(accountId);
        if (smallList.size() >= availableCallCount)
          break;
      }
    if(!Test.isRunningTest() && !smallList.isEmpty() && !System.isFuture())
      calcAccountOptouts(smallList);
  }

  @future(callout=true)
  private static void calcAccountOptouts(Set<Id> accountIds) {
    // Bypass des règles de traitements
    /**
    UserContext userCtx = UserContext.getContext(); // Aucun impacts sur les autres données ou les indicateurs ==> Désactiver pour ne pas consommer les Governor Limits
    userCtx.setByPassValidationRules(TRUE);
    userCtx.setByPassWorkflowRules(TRUE);
    userCtx.setByPassTriggers(TRUE);
    **/

    // Traitement
    List<Account> accounts = [SELECT id, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, phone, fax
                              FROM Account
                              WHERE id IN :accountIds];
    List<Account> accountsToUpdate = new List<Account>();                          
    Set<String> telephones = new Set<String>();
    
    for (Account account : accounts) {
      if (!String.isEmpty(account.telephoneDomicile__c))
        telephones.add(account.telephoneDomicile__c);
      if (!String.isEmpty(account.telephoneMobile__c))
        telephones.add(account.telephoneMobile__c);
      if (!String.isEmpty(account.autreTelephone__c))
        telephones.add(account.autreTelephone__c);
      if (!String.isEmpty(account.phone))
        telephones.add(account.phone);
      if (!String.isEmpty(account.fax))
        telephones.add(account.fax);
    }
        
    Map<String, String> oppositionsParTelephone= new Map<String, String>(); // Key: Numéro de téléphone, Value: Liste des fichiers d'opposition séparé par un point virgule ;
    
    /* ??????????????????????????????????????????????????????????????????????? *
     * APPEL DU WEB SERVICE (1 appel pour tous les téléphones)                 *
     * ??????????????????????????????????????????????????????????????????????? */
     
    // Génération de la liste des fichiers d'opposition pour chacun des comptes 
    Set<String> oppositions = new Set<String>(); 
    for (Account account : accounts) {
      oppositions .clear();
      
      if (!String.isEmpty(account.telephoneDomicile__c) && oppositionsParTelephone.containsKey(account.telephoneDomicile__c))
        oppositions .addAll(oppositionsParTelephone.get(account.telephoneDomicile__c).split(';'));
      if (!String.isEmpty(account.telephoneMobile__c) && oppositionsParTelephone.containsKey(account.telephoneMobile__c))
        oppositions .addAll(oppositionsParTelephone.get(account.telephoneMobile__c).split(';'));
      if (!String.isEmpty(account.autreTelephone__c) && oppositionsParTelephone.containsKey(account.autreTelephone__c))
        oppositions .addAll(oppositionsParTelephone.get(account.autreTelephone__c).split(';'));
      if (!String.isEmpty(account.phone) && oppositionsParTelephone.containsKey(account.phone))
        oppositions .addAll(oppositionsParTelephone.get(account.phone).split(';'));
      if (!String.isEmpty(account.fax) && oppositionsParTelephone.containsKey(account.fax))
        oppositions .addAll(oppositionsParTelephone.get(account.fax).split(';'));
      
      if (!oppositions .isEmpty()) {                
        String s = '';
        for (String opposition: oppositions )
          s += ';' + opposition;
        account.fichiersOpposition__c = s.subString(1);
        accountsToUpdate.add(account);  
      }   
    }      
     

    if (!accountsToUpdate.isEmpty())
      Database.SaveResult[] results = Database.update(accountsToUpdate, false);      
  }
}