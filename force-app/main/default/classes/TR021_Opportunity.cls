/* ************************************************************************* *
 * Contrats K : Alimentation des indicateurs                                 *
 * ************************************************************************* *
 * Version : 1.01                                                            *
 * Date    : 19/03/2013                                                      *
 *           09/10/2015 - Intérêt marketing                                  * 
 * ************************************************************************* *
 */

public class TR021_Opportunity {
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

      for (Opportunity newOpportunity : (List<Opportunity>) Trigger.new) {
        Opportunity oldOpportunity = (Opportunity) Trigger.oldMap.get(newOpportunity.id);

        Boolean changed1 = newOpportunity.stageName                            !=  oldOpportunity.stageName                            ||
                           newOpportunity.createdDate                          !=  oldOpportunity.createdDate                          ||
                           newOpportunity.datePremierRPlus__c                  !=  oldOpportunity.datePremierRPlus__c                  ||
                           newOpportunity.datePremierR1__c                     !=  oldOpportunity.datePremierR1__c                     ||
                           newOpportunity.datePremierR2__c                     !=  oldOpportunity.datePremierR2__c                     ||
                           newOpportunity.datePremierRDV__c                    !=  oldOpportunity.datePremierRDV__c                    ||
                           newOpportunity.dateDernierRPlus__c                  !=  oldOpportunity.dateDernierRPlus__c                  ||
                           newOpportunity.dateDernierR1__c                     !=  oldOpportunity.dateDernierR1__c                     ||
                           newOpportunity.dateDernierR2__c                     !=  oldOpportunity.dateDernierR2__c                     ||
                           newOpportunity.dateDernierRDV__c                    !=  oldOpportunity.dateDernierRDV__c                    ||
                           newOpportunity.nbRPlusEffectues__c                  !=  oldOpportunity.nbRPlusEffectues__c                  ||
                           newOpportunity.nbRPlusNonEffectues__c               !=  oldOpportunity.nbRPlusNonEffectues__c               ||
                           newOpportunity.nbRPlusNonEffectuesAvecDep__c        !=  oldOpportunity.nbRPlusNonEffectuesAvecDep__c        ||
                           newOpportunity.nbRPlusPris__c                       !=  oldOpportunity.nbRPlusPris__c                       ||
                           newOpportunity.nbRPlusDeplaces__c                   !=  oldOpportunity.nbRPlusDeplaces__c                   ||
                           newOpportunity.nbR1Effectues__c                     !=  oldOpportunity.nbR1Effectues__c                     ||
                           newOpportunity.nbR1NonEffectues__c                  !=  oldOpportunity.nbR1NonEffectues__c                  ||
                           newOpportunity.nbR1NonEffectuesAvecDep__c           !=  oldOpportunity.nbR1NonEffectuesAvecDep__c           ||
                           newOpportunity.nbR1Pris__c                          !=  oldOpportunity.nbR1Pris__c                          ||
                           newOpportunity.nbR1Deplaces__c                      !=  oldOpportunity.nbR1Deplaces__c                      ||
                           newOpportunity.nbR2Effectues__c                     !=  oldOpportunity.nbR2Effectues__c                     ||
                           newOpportunity.nbR2NonEffectues__c                  !=  oldOpportunity.nbR2NonEffectues__c                  ||
                           newOpportunity.nbR2NonEffectuesAvecDep__c           !=  oldOpportunity.nbR2NonEffectuesAvecDep__c           ||
                           newOpportunity.nbR2Pris__c                          !=  oldOpportunity.nbR2Pris__c                          ||
                           newOpportunity.nbR2Deplaces__c                      !=  oldOpportunity.nbR2Deplaces__c                      ||
                           newOpportunity.nbRDVDevisables__c                   !=  oldOpportunity.nbRDVDevisables__c                   ||
                           newOpportunity.statutPremierRPlus__c                !=  oldOpportunity.statutPremierRPlus__c                ||
                           newOpportunity.statutPremierR1__c                   !=  oldOpportunity.statutPremierR1__c                   ||
                           newOpportunity.statutPremierR2__c                   !=  oldOpportunity.statutPremierR2__c                   ||
                           newOpportunity.statutPremierRDV__c                  !=  oldOpportunity.statutPremierRDV__c                  ||
                           newOpportunity.statutDernierRPlus__c                !=  oldOpportunity.statutDernierRPlus__c                ||
                           newOpportunity.statutDernierR1__c                   !=  oldOpportunity.statutDernierR1__c                   ||
                           newOpportunity.statutDernierR2__c                   !=  oldOpportunity.statutDernierR2__c                   ||
                           newOpportunity.statutDernierRDV__c                  !=  oldOpportunity.statutDernierRDV__c;
                          
        Boolean changed2 = newOpportunity.datePremierDevis__c                  !=  oldOpportunity.datePremierDevis__c                  ||
                           newOpportunity.dateDernierDevis__c                  !=  oldOpportunity.dateDernierDevis__c                  ||
                           newOpportunity.statutPremierDevis__c                !=  oldOpportunity.statutPremierDevis__c                ||
                           newOpportunity.statutDernierDevis__c                !=  oldOpportunity.statutDernierDevis__c                ||
                           newOpportunity.totalHTDevisEnAttente__c             !=  oldOpportunity.totalHTDevisEnAttente__c             ||
                           newOpportunity.totalTTCDevisEnAttente__c            !=  oldOpportunity.totalTTCDevisEnAttente__c            ||
                           newOpportunity.totalHTDevisEnregistres__c           !=  oldOpportunity.totalHTDevisEnregistres__c           ||
                           newOpportunity.totalTTCDevisEnregistres__c          !=  oldOpportunity.totalTTCDevisEnregistres__c          ||
                           newOpportunity.totalRemisesEnAttenteEnseigne__c     !=  oldOpportunity.totalRemisesEnAttenteEnseigne__c     ||
                           newOpportunity.totalRemisesEnAttenteVendeur__c      !=  oldOpportunity.totalRemisesEnAttenteVendeur__c      ||
                           newOpportunity.totalRemisesEnregistreesEnseigne__c  !=  oldOpportunity.totalRemisesEnregistreesEnseigne__c  ||
                           newOpportunity.totalRemisesEnregistreesVendeur__c   !=  oldOpportunity.totalRemisesEnregistreesVendeur__c   ||
                           newOpportunity.nbDevisAConfigurer__c                !=  oldOpportunity.nbDevisAConfigurer__c                ||
                           newOpportunity.nbDevisErrones__c                    !=  oldOpportunity.nbDevisErrones__c                    ||
                           newOpportunity.nbDevisNonTransmis__c                !=  oldOpportunity.nbDevisNonTransmis__c                ||
                           newOpportunity.nbDevisResilies__c                   !=  oldOpportunity.nbDevisResilies__c                   ||
                           newOpportunity.nbDevisExpires__c                    !=  oldOpportunity.nbDevisExpires__c                    ||
                           newOpportunity.nbDevisTransmis__c                   !=  oldOpportunity.nbDevisTransmis__c                   ||
                           newOpportunity.nbDevisVendusEnAttente__c            !=  oldOpportunity.nbDevisVendusEnAttente__c            ||
                           newOpportunity.nbDevisVendusEnregistres__c          !=  oldOpportunity.nbDevisVendusEnregistres__c          ||
                           newOpportunity.nbDevisVendusIncontournables__c      !=  oldOpportunity.nbDevisVendusIncontournables__c      ||
                           newOpportunity.datePremierIncontournable__c         !=  oldOpportunity.datePremierIncontournable__c         ||
                           newOpportunity.dateDernierIncontournable__c         !=  oldOpportunity.dateDernierIncontournable__c         ||
                           newOpportunity.statutPremierIncontournable__c       !=  oldOpportunity.statutPremierIncontournable__c       ||
                           newOpportunity.statutDernierIncontournable__c       !=  oldOpportunity.statutDernierIncontournable__c       ||
                           newOpportunity.nbIncontournablesEnCours__c          !=  oldOpportunity.nbIncontournablesEnCours__c          ||
                           newOpportunity.nbIncontournablesEnregistres__c      !=  oldOpportunity.nbIncontournablesEnregistres__c      ||
                           newOpportunity.nbIncontournablesTermines__c         !=  oldOpportunity.nbIncontournablesTermines__c         || 
                           newOpportunity.interetMarketing__c                  !=  oldOpportunity.interetMarketing__c;                           
                                                                              
        if (enabledForceIndicators || newOpportunity.accountId != oldOpportunity.accountId || changed1) {           
          if (newOpportunity.accountId != null && !AlreadyUsed.isUsed('TR021_Opportunity', newOpportunity.accountId))
            accountIds.add(newOpportunity.accountId);
          if (oldOpportunity.accountId != null && !AlreadyUsed.isUsed('TR021_Opportunity', oldOpportunity.accountId))
            accountIds.add(oldOpportunity.accountId);
        }  
        
        if (enabledForceIndicators || newOpportunity.autreCompte__c != oldOpportunity.autreCompte__c || changed1) {           
          if (newOpportunity.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', newOpportunity.autreCompte__c))
            accountIds.add(newOpportunity.autreCompte__c);
          if (oldOpportunity.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', oldOpportunity.autreCompte__c))
            accountIds.add(oldOpportunity.autreCompte__c);          
        }  


        if (enabledForceIndicators || newOpportunity.chantier__c != oldOpportunity.chantier__c || changed1 || changed2) {
          System.debug('#~#~#~# Trace 0');
          if (newOpportunity.chantier__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', newOpportunity.chantier__c))            
            chantierIds.add(newOpportunity.chantier__c);
          if (oldOpportunity.chantier__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', oldOpportunity.chantier__c))
            chantierIds.add(oldOpportunity.chantier__c);    
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
    }
    // Delete
    else if (Trigger.isDelete) {
      List<sObject> data = buildIndicators(Trigger.old);
      if (data != null && !data.isEmpty())
        objectsToUpdate.addAll(data);
    }

    /** B - Sauvegarde des indicateurs **/
    if (!objectsToUpdate.isEmpty())
      update objectsToUpdate;
  }


  /** 02 - Méthodes de calcul **/
  private static List<sObject> incrementIndicators(List<Opportunity> opportunities) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds = new Set<Id>();
    Set<Id> chantierIds = new Set<Id>();

    for (Opportunity opportunity : opportunities) {
      if (opportunity.accountId != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.accountId))
        accountIds.add(opportunity.accountId);
      if (opportunity.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.autreCompte__c))
        accountIds.add(opportunity.autreCompte__c);  
      if (opportunity.chantier__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.chantier__c))
        chantierIds.add(opportunity.chantier__c);
    }

    if (accountIds.isEmpty() && chantierIds.isEmpty())
      return null;

    Map<Id, Account> accounts = new Map<Id, Account>([SELECT datePremierProjet__c, dateDernierProjet__c, interetMarketing__c,
                                                             statutPremierProjet__c, statutDernierProjet__c,
                                                             nbProjetsAnalyse__c, nbProjetsRDV__c, nbProjetsDevis__c, nbProjetsDevisEnvoye__c, nbProjetsEnAttente__c, nbProjetsNegociation__c, nbProjetsReporte__c, nbProjetsVendu__c, nbProjetsRefus__c,
                                                             datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                             dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                             nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                             nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                             nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                             nbRDVDevisables__c,
                                                             statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                             statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                                      FROM account
                                                      WHERE id in :accountIds]);
    Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>([SELECT datePremierProjet__c, dateDernierProjet__c, interetMarketing__c,
                                                                      statutPremierProjet__c, statutDernierProjet__c,
                                                                      nbProjetsAnalyse__c, nbProjetsRDV__c, nbProjetsDevis__c, nbProjetsDevisEnvoye__c, nbProjetsEnAttente__c, nbProjetsNegociation__c, nbProjetsReporte__c, nbProjetsVendu__c, nbProjetsRefus__c,
                                                                      datePremierDevis__c, dateDernierDevis__c,
                                                                      statutPremierDevis__c, statutDernierDevis__c,
                                                                      totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                                                      totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                                                      nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                                                      datePremierIncontournable__c, dateDernierIncontournable__c,
                                                                      statutPremierIncontournable__c, statutDernierIncontournable__c,
                                                                      nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                                      datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                                      dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                                      nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                                      nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                                      nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                                      statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                                      statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                                               FROM chantier__c
                                                               WHERE id in :chantierIds]);

    /** B - Mise à jour des indicateurs **/
    for (Opportunity opportunity : opportunities) {
      if (opportunity.accountId != null && accounts.containsKey(opportunity.accountId))
        incrementIndicators(accounts.get(opportunity.accountId), opportunity);
        
      if (opportunity.autreCompte__c != null && accounts.containsKey(opportunity.autreCompte__c))
        incrementIndicators(accounts.get(opportunity.autreCompte__c), opportunity);  

      if (opportunity.chantier__c != null && chantiers.containsKey(opportunity.chantier__c))
        incrementIndicators(chantiers.get(opportunity.chantier__c), opportunity);
    }

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (accounts != null)
      objectsToUpdate.addAll((List<sObject>) accounts.values());
    if (chantiers != null)
      objectsToUpdate.addAll((List<sObject>) chantiers.values());
    return objectsToUpdate;
  }

  private static List<sObject> buildIndicators(List<Opportunity> opportunities) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> accountIds = new Set<Id>();
    Set<Id> chantierIds = new Set<Id>();

    for (Opportunity opportunity : opportunities) {
      if (opportunity.accountId != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.accountId))
        accountIds.add(opportunity.accountId);
      if (opportunity.autreCompte__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.autreCompte__c))
        accountIds.add(opportunity.autreCompte__c);  
      if (opportunity.chantier__c != null && !AlreadyUsed.isUsed('TR021_Opportunity', opportunity.chantier__c))
        chantierIds.add(opportunity.chantier__c);
    }

    if (accountIds.isEmpty() && chantierIds.isEmpty())
      return null;

    /** B - Mise à jour des indicateurs **/
    List<sObject> objectsToUpdate = new List<sObject>();
    if (!accountIds.isEmpty())
      objectsToUpdate.addAll(buildAccountIndicators(accountIds));
    if (!chantierIds.isEmpty())
      objectsToUpdate.addAll(buildChantierIndicators(chantierIds));

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return objectsToUpdate;
  }

  private static List<sObject> buildAccountIndicators(Set<ID> accountIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Account> accounts = [SELECT datePremierProjet__c, dateDernierProjet__c, interetMarketing__c,
                                     statutPremierProjet__c, statutDernierProjet__c,
                                     nbProjetsAnalyse__c, nbProjetsRDV__c, nbProjetsDevis__c, nbProjetsDevisEnvoye__c, nbProjetsEnAttente__c, nbProjetsNegociation__c, nbProjetsReporte__c, nbProjetsVendu__c, nbProjetsRefus__c,                                     
                                     datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                     dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                     nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                     nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                     nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                     nbRDVDevisables__c,
                                     statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                     statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c,
                                     (SELECT stageName, createdDate, interetMarketing__c,
                                             datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                             dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                             nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                             nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                             nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                             nbRDVDevisables__c,
                                             statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                             statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                      FROM opportunities
                                      ORDER BY id),
                                     (SELECT stageName, createdDate, interetMarketing__c,                                            
                                             datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                             dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                             nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                             nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                             nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                             nbRDVDevisables__c,
                                             statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                             statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                      FROM autreCompteopportunites__r
                                      ORDER BY id)
                              FROM account
                              WHERE id in :accountIds];
    /** B - Mise à jour des indicateurs **/    
    for (Account account : accounts) {
        List<Opportunity> opportunities = new List<Opportunity>(account.opportunities);
        opportunities.addAll(account.autreCompteopportunites__r);
        buildIndicators(account, opportunities);
    }    

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return accounts;
  }

  private static List<sObject> buildChantierIndicators(Set<ID> chantierIds) {
    /** A - Initialisation des données intermédiaires **/
    List<Chantier__c> chantiers = [SELECT datePremierProjet__c, dateDernierProjet__c, interetMarketing__c,
                                          statutPremierProjet__c, statutDernierProjet__c,
                                          nbProjetsAnalyse__c, nbProjetsRDV__c, nbProjetsDevis__c, nbProjetsDevisEnvoye__c, nbProjetsEnAttente__c, nbProjetsNegociation__c, nbProjetsReporte__c, nbProjetsVendu__c, nbProjetsRefus__c,
                                          datePremierDevis__c, dateDernierDevis__c,
                                          statutPremierDevis__c, statutDernierDevis__c,
                                          totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                          totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                          nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                          datePremierIncontournable__c, dateDernierIncontournable__c,
                                          statutPremierIncontournable__c, statutDernierIncontournable__c,
                                          nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                          datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                          dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                          nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                          nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                          nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                          statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                          statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c,
                                          (SELECT stageName, createdDate, interetMarketing__c,
                                                  datePremierDevis__c, dateDernierDevis__c,
                                                  statutPremierDevis__c, statutDernierDevis__c,
                                                  totalHTDevisEnAttente__c, totalTTCDevisEnAttente__c, totalHTDevisEnregistres__c, totalTTCDevisEnregistres__c,
                                                  totalRemisesEnAttenteEnseigne__c, totalRemisesEnAttenteVendeur__c, totalRemisesEnregistreesEnseigne__c, totalRemisesEnregistreesVendeur__c,
                                                  nbDevisAConfigurer__c, nbDevisErrones__c, nbDevisNonTransmis__c, nbDevisResilies__c, nbDevisTransmis__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c, nbDevisVendusIncontournables__c, nbDevisExpires__c,
                                                  datePremierIncontournable__c, dateDernierIncontournable__c,
                                                  statutPremierIncontournable__c, statutDernierIncontournable__c,
                                                  nbIncontournablesEnCours__c, nbIncontournablesEnregistres__c, nbIncontournablesTermines__c,
                                                  datePremierRPlus__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                  dateDernierRPlus__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                  nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                  nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                  nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                  statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                  statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                           FROM Projets__r
                                           ORDER BY id)
                                   FROM chantier__c
                                   WHERE id in :chantierIds];

    /** B - Mise à jour des indicateurs **/
    for (Chantier__c chantier : chantiers)
        buildIndicators(chantier, chantier.projets__r);

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return chantiers;
  }

  /** 03 - Méthodes de calcul unitaire **/
  private static void incrementIndicators(SObject aObject, Opportunity opportunity) {
    // MAJ date de 1er et dernier projet
    if (opportunity.createdDate != null) {
      if (aObject.get('datePremierProjet__c') == null || opportunity.createdDate.date() < (Date)aObject.get('datePremierProjet__c')) {
        aObject.put('datePremierProjet__c', opportunity.createdDate.date());
        aObject.put('statutPremierProjet__c', opportunity.stageName);
      }
      if (aObject.get('dateDernierProjet__c') == null || opportunity.createdDate.date() >= (Date)aObject.get('dateDernierProjet__c')) {
        aObject.put('dateDernierProjet__c', opportunity.createdDate.date());
        aObject.put('statutDernierProjet__c', opportunity.stageName);
      }
    }

    // MAJ du nombre de projets
    if (opportunity.stageName != null) {
      String fieldName = null;
      if ('Analyse'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsAnalyse__c';
      else if ('RDV'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsRDV__c';
      else if ('Devis'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsDevis__c';
      else if ('Devis envoyé'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsDevisEnvoye__c';
      else if ('En attente de réponse'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsEnAttente__c';
      else if ('Négociation'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsNegociation__c';
      else if ('Reporté'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsReporte__c';
      else if ('Vendu'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsVendu__c';
      else if ('Refus'.equalsIgnoreCase(opportunity.stageName))
        fieldName = 'nbProjetsRefus__c';

      if (fieldName != null)
        aObject.put(fieldName, (aObject.get(fieldName) == null ? 0 : (Double)aObject.get(fieldName)) + 1);
    }
    
    // MAJ date de 1er et dernier RDV
    if (opportunity.datePremierRPlus__c != null) {
      if (aObject.get('datePremierRPlus__c') == null || opportunity.datePremierRPlus__c < (DateTime)aObject.get('datePremierRPlus__c')) {
        aObject.put('datePremierRPlus__c', opportunity.datePremierRPlus__c);
        aObject.put('statutPremierRPlus__c', opportunity.statutPremierRPlus__c);
      }
      if (aObject.get('dateDernierRPlus__c') == null || opportunity.dateDernierRPlus__c >= (DateTime)aObject.get('dateDernierRPlus__c')) {
        aObject.put('dateDernierRPlus__c', opportunity.dateDernierRPlus__c);
        aObject.put('statutDernierRPlus__c', opportunity.statutDernierRPlus__c);
      }
    }
    if (opportunity.datePremierR1__c != null) {
      if (aObject.get('datePremierR1__c') == null || opportunity.datePremierR1__c < (DateTime)aObject.get('datePremierR1__c')) {
        aObject.put('datePremierR1__c', opportunity.datePremierR1__c);
        aObject.put('statutPremierR1__c', opportunity.statutPremierR1__c);
      }
      if (aObject.get('dateDernierR1__c') == null || opportunity.dateDernierR1__c >= (DateTime)aObject.get('dateDernierR1__c')) {
        aObject.put('dateDernierR1__c', opportunity.dateDernierR1__c);
        aObject.put('statutDernierR1__c', opportunity.statutDernierR1__c);
      }
    }
    if (opportunity.datePremierR2__c != null) {
      if (aObject.get('datePremierR2__c') == null || opportunity.datePremierR2__c < (DateTime)aObject.get('datePremierR2__c')) {
        aObject.put('datePremierR2__c', opportunity.datePremierR2__c);
        aObject.put('statutPremierR2__c', opportunity.statutPremierR2__c);
      }
      if (aObject.get('dateDernierR2__c') == null || opportunity.dateDernierR2__c >= (DateTime)aObject.get('dateDernierR2__c')) {
        aObject.put('dateDernierR2__c', opportunity.dateDernierR2__c);
        aObject.put('statutDernierR2__c', opportunity.statutDernierR2__c);
      }
    }
    if (opportunity.datePremierRDV__c != null) {
      if (aObject.get('datePremierRDV__c') == null || opportunity.datePremierRDV__c < (DateTime)aObject.get('datePremierRDV__c')) {
        aObject.put('datePremierRDV__c', opportunity.datePremierRDV__c);
        aObject.put('statutPremierRDV__c', opportunity.statutPremierRDV__c);
      }
      if (aObject.get('dateDernierRDV__c') == null || opportunity.dateDernierRDV__c >= (DateTime)aObject.get('dateDernierRDV__c')) {
        aObject.put('dateDernierRDV__c', opportunity.dateDernierRDV__c);
        aObject.put('statutDernierRDV__c', opportunity.statutDernierRDV__c);
      }
    }
    
    // Intérêt marketing
    if (opportunity.interetMarketing__c) {
      aObject.put('interetMarketing__c', TRUE);
      System.debug('#~#~# TRUE for ' + (aObject.getsObjectType() == Account.sObjectType ? 'Account' : 'Chantier'));
    }
    else System.debug('#~#~# FALSE for ' + (aObject.getsObjectType() == Account.sObjectType ? 'Account' : 'Chantier'));
      

    // MAJ du nombre de RDV
    aObject.put('nbRPlusEffectues__c', (aObject.get('nbRPlusEffectues__c') == null ? 0 : (Double)aObject.get('nbRPlusEffectues__c')) +
                                       (opportunity.nbRPlusEffectues__c    == null ? 0 : opportunity.nbRPlusEffectues__c));
    aObject.put('nbRPlusNonEffectues__c', (aObject.get('nbRPlusNonEffectues__c') == null ? 0 : (Double)aObject.get('nbRPlusNonEffectues__c')) +
                                          (opportunity.nbRPlusNonEffectues__c    == null ? 0 : opportunity.nbRPlusNonEffectues__c));
    aObject.put('nbRPlusNonEffectuesAvecDep__c', (aObject.get('nbRPlusNonEffectuesAvecDep__c') == null ? 0 : (Double)aObject.get('nbRPlusNonEffectuesAvecDep__c')) +
                                                 (opportunity.nbRPlusNonEffectuesAvecDep__c    == null ? 0 : opportunity.nbRPlusNonEffectuesAvecDep__c));
    aObject.put('nbRPlusPris__c', (aObject.get('nbRPlusPris__c') == null ? 0 : (Double)aObject.get('nbRPlusPris__c')) +
                                  (opportunity.nbRPlusPris__c    == null ? 0 : opportunity.nbRPlusPris__c));
    aObject.put('nbRPlusDeplaces__c', (aObject.get('nbRPlusDeplaces__c') == null ? 0 : (Double)aObject.get('nbRPlusDeplaces__c')) +
                                      (opportunity.nbRPlusDeplaces__c    == null ? 0 : opportunity.nbRPlusDeplaces__c));
    aObject.put('nbR1Effectues__c', (aObject.get('nbR1Effectues__c') == null ? 0 : (Double)aObject.get('nbR1Effectues__c')) +
                                    (opportunity.nbR1Effectues__c    == null ? 0 : opportunity.nbR1Effectues__c));
    aObject.put('nbR1NonEffectues__c', (aObject.get('nbR1NonEffectues__c') == null ? 0 : (Double)aObject.get('nbR1NonEffectues__c')) +
                                       (opportunity.nbR1NonEffectues__c    == null ? 0 : opportunity.nbR1NonEffectues__c));
    aObject.put('nbR1NonEffectuesAvecDep__c', (aObject.get('nbR1NonEffectuesAvecDep__c') == null ? 0 : (Double)aObject.get('nbR1NonEffectuesAvecDep__c')) +
                                              (opportunity.nbR1NonEffectuesAvecDep__c    == null ? 0 : opportunity.nbR1NonEffectuesAvecDep__c));
    aObject.put('nbR1Pris__c', (aObject.get('nbR1Pris__c') == null ? 0 : (Double)aObject.get('nbR1Pris__c')) +
                               (opportunity.nbR1Pris__c    == null ? 0 : opportunity.nbR1Pris__c));
    aObject.put('nbR1Deplaces__c', (aObject.get('nbR1Deplaces__c') == null ? 0 : (Double)aObject.get('nbR1Deplaces__c')) +
                                   (opportunity.nbR1Deplaces__c    == null ? 0 : opportunity.nbR1Deplaces__c));
    aObject.put('nbR2Effectues__c', (aObject.get('nbR2Effectues__c') == null ? 0 : (Double)aObject.get('nbR2Effectues__c')) +
                                    (opportunity.nbR2Effectues__c    == null ? 0 : opportunity.nbR2Effectues__c));
    aObject.put('nbR2NonEffectues__c', (aObject.get('nbR2NonEffectues__c') == null ? 0 : (Double)aObject.get('nbR2NonEffectues__c')) +
                                       (opportunity.nbR2NonEffectues__c    == null ? 0 : opportunity.nbR2NonEffectues__c));
    aObject.put('nbR2NonEffectuesAvecDep__c', (aObject.get('nbR2NonEffectuesAvecDep__c') == null ? 0 : (Double)aObject.get('nbR2NonEffectuesAvecDep__c')) +
                                              (opportunity.nbR2NonEffectuesAvecDep__c    == null ? 0 : opportunity.nbR2NonEffectuesAvecDep__c));
    aObject.put('nbR2Pris__c', (aObject.get('nbR2Pris__c') == null ? 0 : (Double)aObject.get('nbR2Pris__c')) +
                               (opportunity.nbR2Pris__c    == null ? 0 : opportunity.nbR2Pris__c));
    aObject.put('nbR2Deplaces__c', (aObject.get('nbR2Deplaces__c') == null ? 0 : (Double)aObject.get('nbR2Deplaces__c')) +
                                   (opportunity.nbR2Deplaces__c    == null ? 0 : opportunity.nbR2Deplaces__c));
                                   
                                   
    if (aObject.getsObjectType() == Account.sObjectType)
      aObject.put('nbRDVDevisables__c', (aObject.get('nbRDVDevisables__c') == null ? 0 : (Double)aObject.get('nbRDVDevisables__c')) +
                                        (opportunity.nbRDVDevisables__c    == null ? 0 : opportunity.nbRDVDevisables__c));

    if (aObject.getSObjectType() == Chantier__c.getSObjectType()) {
      // MAJ date de 1er et dernier devis
      if (opportunity.datePremierDevis__c != null) {
        if (aObject.get('datePremierDevis__c') == null || opportunity.datePremierDevis__c < (Date)aObject.get('datePremierDevis__c')) {
          aObject.put('datePremierDevis__c', opportunity.datePremierDevis__c);
          aObject.put('statutPremierDevis__c', opportunity.statutPremierDevis__c);
        }
        if (aObject.get('dateDernierDevis__c') == null || opportunity.dateDernierDevis__c >= (Date)aObject.get('dateDernierDevis__c')) {
          aObject.put('dateDernierDevis__c', opportunity.dateDernierDevis__c);
          aObject.put('statutDernierDevis__c', opportunity.statutDernierDevis__c);
        }
      }
  
      // MAJ montant des devis
      aObject.put('totalHTDevisEnAttente__c', (aObject.get('totalHTDevisEnAttente__c') == null ? 0 : (Double)aObject.get('totalHTDevisEnAttente__c')) +
                                              (opportunity.totalHTDevisEnAttente__c== null ? 0 : opportunity.totalHTDevisEnAttente__c));
      aObject.put('totalTTCDevisEnAttente__c', (aObject.get('totalTTCDevisEnAttente__c') == null ? 0 : (Double)aObject.get('totalTTCDevisEnAttente__c')) +
                                               (opportunity.totalTTCDevisEnAttente__c== null ? 0 : opportunity.totalTTCDevisEnAttente__c));
      aObject.put('totalHTDevisEnregistres__c', (aObject.get('totalHTDevisEnregistres__c') == null ? 0 : (Double)aObject.get('totalHTDevisEnregistres__c')) +
                                                (opportunity.totalHTDevisEnregistres__c== null ? 0 : opportunity.totalHTDevisEnregistres__c));
      aObject.put('totalTTCDevisEnregistres__c', (aObject.get('totalTTCDevisEnregistres__c') == null ? 0 : (Double)aObject.get('totalTTCDevisEnregistres__c')) +
                                                 (opportunity.totalTTCDevisEnregistres__c== null ? 0 : opportunity.totalTTCDevisEnregistres__c));
      aObject.put('totalRemisesEnAttenteEnseigne__c', (aObject.get('totalRemisesEnAttenteEnseigne__c') == null ? 0 : (Double)aObject.get('totalRemisesEnAttenteEnseigne__c')) +
                                                      (opportunity.totalRemisesEnAttenteEnseigne__c== null ? 0 : opportunity.totalRemisesEnAttenteEnseigne__c));
      aObject.put('totalRemisesEnAttenteVendeur__c', (aObject.get('totalRemisesEnAttenteVendeur__c') == null ? 0 : (Double)aObject.get('totalRemisesEnAttenteVendeur__c')) +
                                                     (opportunity.totalRemisesEnAttenteVendeur__c== null ? 0 : opportunity.totalRemisesEnAttenteVendeur__c));
      aObject.put('totalRemisesEnregistreesEnseigne__c', (aObject.get('totalRemisesEnregistreesEnseigne__c') == null ? 0 : (Double)aObject.get('totalRemisesEnregistreesEnseigne__c')) +
                                                         (opportunity.totalRemisesEnregistreesEnseigne__c== null ? 0 : opportunity.totalRemisesEnregistreesEnseigne__c));
      aObject.put('totalRemisesEnregistreesVendeur__c', (aObject.get('totalRemisesEnregistreesVendeur__c') == null ? 0 : (Double)aObject.get('totalRemisesEnregistreesVendeur__c')) +
                                                        (opportunity.totalRemisesEnregistreesVendeur__c== null ? 0 : opportunity.totalRemisesEnregistreesVendeur__c));
  
      // MAJ du nombre de devis
      aObject.put('nbDevisAConfigurer__c', (aObject.get('nbDevisAConfigurer__c') == null ? 0 : (Double)aObject.get('nbDevisAConfigurer__c')) +
                                           (opportunity.nbDevisAConfigurer__c == null ? 0 : opportunity.nbDevisAConfigurer__c));
      aObject.put('nbDevisErrones__c', (aObject.get('nbDevisErrones__c') == null ? 0 : (Double)aObject.get('nbDevisErrones__c')) +
                                       (opportunity.nbDevisErrones__c== null ? 0 : opportunity.nbDevisErrones__c));
      aObject.put('nbDevisNonTransmis__c', (aObject.get('nbDevisNonTransmis__c') == null ? 0 : (Double)aObject.get('nbDevisNonTransmis__c')) +
                                           (opportunity.nbDevisNonTransmis__c== null ? 0 : opportunity.nbDevisNonTransmis__c));
      aObject.put('nbDevisResilies__c', (aObject.get('nbDevisResilies__c') == null ? 0 : (Double)aObject.get('nbDevisResilies__c')) +
                                        (opportunity.nbDevisResilies__c== null ? 0 : opportunity.nbDevisResilies__c));
      aObject.put('nbDevisExpires__c', (aObject.get('nbDevisExpires__c') == null ? 0 : (Double)aObject.get('nbDevisExpires__c')) +
                                        (opportunity.nbDevisExpires__c== null ? 0 : opportunity.nbDevisExpires__c));
      aObject.put('nbDevisTransmis__c', (aObject.get('nbDevisTransmis__c') == null ? 0 : (Double)aObject.get('nbDevisTransmis__c')) +
                                        (opportunity.nbDevisTransmis__c== null ? 0 : opportunity.nbDevisTransmis__c));
      aObject.put('nbDevisVendusEnAttente__c', (aObject.get('nbDevisVendusEnAttente__c') == null ? 0 : (Double)aObject.get('nbDevisVendusEnAttente__c')) +
                                               (opportunity.nbDevisVendusEnAttente__c== null ? 0 : opportunity.nbDevisVendusEnAttente__c));
      aObject.put('nbDevisVendusEnregistres__c', (aObject.get('nbDevisVendusEnregistres__c') == null ? 0 : (Double)aObject.get('nbDevisVendusEnregistres__c')) +
                                                 (opportunity.nbDevisVendusEnregistres__c== null ? 0 : opportunity.nbDevisVendusEnregistres__c));
      aObject.put('nbDevisVendusIncontournables__c', (aObject.get('nbDevisVendusIncontournables__c') == null ? 0 : (Double)aObject.get('nbDevisVendusIncontournables__c')) +
                                                     (opportunity.nbDevisVendusIncontournables__c== null ? 0 : opportunity.nbDevisVendusIncontournables__c));
  
      // MAJ date de 1er et dernier incontournable
      if (opportunity.datePremierIncontournable__c != null) {
        if (aObject.get('datePremierIncontournable__c') == null || opportunity.datePremierIncontournable__c < (Date)aObject.get('datePremierIncontournable__c')) {
          aObject.put('datePremierIncontournable__c', opportunity.datePremierIncontournable__c);
          aObject.put('statutPremierIncontournable__c', opportunity.statutPremierIncontournable__c);
        }
        if (aObject.get('dateDernierIncontournable__c') == null || opportunity.dateDernierIncontournable__c >= (Date)aObject.get('dateDernierIncontournable__c')) {
          aObject.put('dateDernierIncontournable__c', opportunity.dateDernierIncontournable__c);
          aObject.put('statutDernierIncontournable__c', opportunity.statutDernierIncontournable__c);
        }
      }
  
      // MAJ du nombre d'incontournables
      aObject.put('nbIncontournablesEnCours__c', (aObject.get('nbIncontournablesEnCours__c') == null ? 0 : (Double)aObject.get('nbIncontournablesEnCours__c')) +
                                                 (opportunity.nbIncontournablesEnCours__c    == null ? 0 : opportunity.nbIncontournablesEnCours__c));
      aObject.put('nbIncontournablesEnregistres__c', (aObject.get('nbIncontournablesEnregistres__c') == null ? 0 : (Double)aObject.get('nbIncontournablesEnregistres__c')) +
                                                     (opportunity.nbIncontournablesEnregistres__c    == null ? 0 : opportunity.nbIncontournablesEnregistres__c));
      aObject.put('nbIncontournablesTermines__c', (aObject.get('nbIncontournablesTermines__c') == null ? 0 : (Double)aObject.get('nbIncontournablesTermines__c')) +
                                                  (opportunity.nbIncontournablesTermines__c    == null ? 0 : opportunity.nbIncontournablesTermines__c));                                                        
      
    }
  }

  private static void buildIndicators(SObject aObject, List<Opportunity> opportunities) {
    // Réinitialisation des indicateurs
    aObject.put('datePremierProjet__c', null);
    aObject.put('dateDernierProjet__c', null);
    aObject.put('statutPremierProjet__c', null);
    aObject.put('statutDernierProjet__c', null);
    aObject.put('nbProjetsAnalyse__c', null);
    aObject.put('nbProjetsRDV__c', null);
    aObject.put('nbProjetsDevis__c', null);
    aObject.put('nbProjetsDevisEnvoye__c', null);
    aObject.put('nbProjetsEnAttente__c', null);
    aObject.put('nbProjetsNegociation__c', null);
    aObject.put('nbProjetsReporte__c', null);
    aObject.put('nbProjetsVendu__c', null);
    aObject.put('nbProjetsRefus__c', null);    
    aObject.put('datePremierRPlus__c', null);
    aObject.put('datePremierR1__c', null);
    aObject.put('datePremierR2__c', null);
    aObject.put('datePremierRDV__c', null);
    aObject.put('dateDernierRPlus__c', null);
    aObject.put('dateDernierR1__c', null);
    aObject.put('dateDernierR2__c', null);
    aObject.put('dateDernierRDV__c', null);
    aObject.put('nbRPlusEffectues__c', null);
    aObject.put('nbRPlusNonEffectues__c', null);
    aObject.put('nbRPlusNonEffectuesAvecDep__c', null);
    aObject.put('nbRPlusPris__c', null);
    aObject.put('nbRPlusDeplaces__c', null);
    aObject.put('nbR1Effectues__c', null);
    aObject.put('nbR1NonEffectues__c', null);
    aObject.put('nbR1NonEffectuesAvecDep__c', null);
    aObject.put('nbR1Pris__c', null);
    aObject.put('nbR1Deplaces__c', null);
    aObject.put('nbR2Effectues__c', null);
    aObject.put('nbR2NonEffectues__c', null);
    aObject.put('nbR2NonEffectuesAvecDep__c', null);
    aObject.put('nbR2Pris__c', null);
    aObject.put('nbR2Deplaces__c', null);
    aObject.put('statutPremierRPlus__c', null);
    aObject.put('statutPremierR1__c', null);
    aObject.put('statutPremierR2__c', null);
    aObject.put('statutPremierRDV__c', null);
    aObject.put('statutDernierRPlus__c', null);
    aObject.put('statutDernierR1__c', null);
    aObject.put('statutDernierR2__c', null);
    aObject.put('statutDernierRDV__c', null);
    aObject.put('interetMarketing__c', FALSE);

    if (aObject.getsObjectType() == Account.sObjectType)
      aObject.put('nbRDVDevisables__c', null);
      
    if (aObject.getSObjectType() == Chantier__c.getSObjectType()) {
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
    }  

    // Calcul des indicateurs
    for (Opportunity opportunity : opportunities)
      incrementIndicators(aObject, opportunity);
  }
}