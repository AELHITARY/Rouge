public class MappingUtils {
  public static Integer getCodeOrigine(String origine) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();
    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('origine') && mapping.pickValue__c.equalsIgnoreCase(origine))
        return Integer.valueOf(mapping.convertedValue__c);

    return null;
  }

  public static String getOrigineVenteFromCall(String origine) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();
    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('call') && mapping.pickValue__c.equalsIgnoreCase(origine))
        return mapping.convertedValue__c+'';

    return null;
  }

  public static Integer getCodeCredit(String credit) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();

    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('credit') && mapping.pickValue__c.equalsIgnoreCase(credit))
        return Integer.valueOf(mapping.convertedValue__c);

    return null;
  }

  // JMU 15/06/2020 Code mis en commentaire car non couvert (pas d'appel dans le code) suite au déploiement de la RQM-236  
  /*
  public static Integer getAcompte(String credit) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();

    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('acompte') && mapping.pickValue__c.equalsIgnoreCase(credit))
        return Integer.valueOf(mapping.convertedValue__c);

    return null;
  }*/
  
  public static String getAcompteString(String credit) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();

    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('acompte') && mapping.pickValue__c.equalsIgnoreCase(credit))
        return String.valueOf(mapping.convertedValue__c);

    return null;
  }

  public static String getCaseRecordTypeFromType(String caseType) {
    Map<String, Mapping__c> mappings = Mapping__c.getAll();
    for (Mapping__c mapping : mappings.values())
      if (mapping.repository__c.equalsIgnoreCase('case_typeMapping') && mapping.pickValue__c.equalsIgnoreCase(caseType))
        return mapping.convertedValue__c+'';

    return null;
  }
}