/* ************************************************************************* *
 * Instances en cours K : Alimentation des indicateurs                       *
 * ************************************************************************* *
 * Version : 1.00                                                            *
 * Date    : 13/03/2013                                                      *
 * ************************************************************************* *
 */

public class TR021_KInstance {
  private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', False);

  /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
  public static void calculateIndicators(UserContext userContext) {
    if (!Trigger.isExecuting)
      return;

    /** A - Répartition et calcul des indicateurs **/
    List<KContrat__c> contratsToUpdate = null;
    // Insert
    if (Trigger.isInsert)
      contratsToUpdate = incrementIndicators(Trigger.new);
    // Update
    else if (Trigger.isUpdate) {
      Set<ID> contratIds = new Set<ID>();

      for (KInstance__c newInstance : (List<KInstance__c>) Trigger.new) {
        KInstance__c oldInstance = (KInstance__c) Trigger.oldMap.get(newInstance.id);

        Boolean changed = newInstance.dateEntree__c != oldInstance.dateEntree__c ||
                          newInstance.statut__c     != oldInstance.statut__c;
        if (enabledForceIndicators || newInstance.contrat__c != oldInstance.contrat__c || changed) {    
          if (newInstance.contrat__c != null && !AlreadyUsed.isUsed('TR021_KInstance', newInstance.contrat__c))
            contratIds.add(newInstance.contrat__c);
          if (oldInstance.contrat__c != null && !AlreadyUsed.isUsed('TR021_KInstance', oldInstance.contrat__c))
            contratIds.add(oldInstance.contrat__c);
        }                            
      }
      if (!contratIds.isEmpty())
        contratsToUpdate = buildContratIndicators(contratIds);
    }
    // Delete
    else if (Trigger.isDelete)
      contratsToUpdate = buildIndicators(Trigger.old);

    /** B - Sauvegarde des indicateurs **/
    if (contratsToUpdate != null && !contratsToUpdate.isEmpty())
      update contratsToUpdate;
  }


  /** 02 - Méthodes de calcul **/
  private static List<KContrat__c> incrementIndicators(List<KInstance__c> instances) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> contratIds = new Set<Id>();

    for (KInstance__c instance : instances)
      if (!AlreadyUsed.isUsed('TR021_KInstance', instance.contrat__c))
        contratIds.add(instance.contrat__c);

    if (contratIds.isEmpty())
      return null;

    Map<Id, KContrat__c> contrats = new Map<Id, KContrat__c>([SELECT datePremierIEC__c, dateDernierIEC__c,
                                                                     nbIECEnCours__c, nbIECTermines__c,
                                                                     statutPremierIEC__c, statutDernierIEC__c
                                                              FROM KContrat__c
                                                              WHERE id in :contratIds]);

    /** B - Mise à jour des indicateurs **/
    for (KInstance__c instance : instances)
      if (instance.contrat__c != null && contrats.containsKey(instance.contrat__c))
        incrementIndicators(contrats.get(instance.contrat__c), instance);

    /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
    return contrats.values();
  }

  private static List<KContrat__c> buildIndicators(List<KInstance__c> instances) {
    /** A - Initialisation des données intermédiaires **/
    Set<Id> contratIds = new Set<Id>();

    for (KInstance__c instance : instances)
      if (!AlreadyUsed.isUsed('TR021_KInstance', instance.contrat__c))
        contratIds.add(instance.contrat__c);

    if (contratIds.isEmpty())
      return null;

    /** B - Mise à jour des indicateurs et retour des contrat à sauvegarder **/
    return buildContratIndicators(contratIds);
  }

  private static List<KContrat__c> buildContratIndicators(Set<ID> contratIds) {
    /** A - Initialisation des données intermédiaires **/
    List<KContrat__c> contrats = [SELECT datePremierIEC__c, dateDernierIEC__c,
                                         nbIECEnCours__c, nbIECTermines__c,
                                         statutPremierIEC__c, statutDernierIEC__c,
                                         (SELECT dateEntree__c, statut__c FROM contratInstances__r ORDER BY id)
                                  FROM KContrat__c
                                  WHERE id in :contratIds];

    /** B - Mise à jour des indicateurs **/
    for (KContrat__c contrat : contrats)
        buildIndicators(contrat, contrat.contratInstances__r);

    /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
    return contrats;
  }

  /** 03 - Méthodes de calcul unitaire **/

  private static void incrementIndicators(KContrat__c contrat, KInstance__c instance) {
    // MAJ date et statut de 1er et dernier IEC
    if (instance.dateEntree__c != null) {
      if (contrat.datePremierIEC__c == null || instance.dateEntree__c < contrat.datePremierIEC__c) {
        contrat.datePremierIEC__c   = instance.dateEntree__c;
        contrat.statutPremierIEC__c = instance.statut__c;
      }
      if (contrat.dateDernierIEC__c == null || instance.dateEntree__c > contrat.dateDernierIEC__c) {
        contrat.dateDernierIEC__c   = instance.dateEntree__c;
        contrat.statutDernierIEC__c = instance.statut__c;
      }
    }

    // MAJ du nombre de IEC
    if (instance.statut__c.equalsIgnoreCase('En cours'))
      contrat.nbIECEnCours__c = (contrat.nbIECEnCours__c == null ? 0 : contrat.nbIECEnCours__c) + 1;
    else if (instance.statut__c.equalsIgnoreCase('Terminé'))
      contrat.nbIECEnCours__c = (contrat.nbIECEnCours__c == null ? 0 : contrat.nbIECEnCours__c) + 1;
  }

  private static void buildIndicators(KContrat__c contrat, List<KInstance__c> instances) {
    // Réinitialisation des indicateurs
    contrat.datePremierIEC__c   = null;
    contrat.dateDernierIEC__c   = null;
    contrat.nbIECEnCours__c     = null;
    contrat.nbIECTermines__c    = null;
    contrat.statutPremierIEC__c = null;
    contrat.statutDernierIEC__c = null;

    // Calcul des indicateurs
    for (KInstance__c instance : instances)
      incrementIndicators(contrat, instance);
  }
}