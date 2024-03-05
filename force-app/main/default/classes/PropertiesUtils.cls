//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : PropertiesUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/05/2019
//-- Version     : 2.0
//-- * 2.0 - Ajout de la fonction isUserAllowed
//-- --------------------------------------------------------------------------------- --
public class PropertiesUtils {
    
    public static String getStringValue(String name) {
        return getStringValue(name, null);
    }
    
    public static String getStringValue(String name, String defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.stringValue__c;
    }
    
    public static void setStringValue(String name, String value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.stringValue__c = value;
        upsert properties;
    }
    
    public static Boolean getBooleanValue(String name) {
        return getBooleanValue(name, null);
    }
    
    public static Boolean getBooleanValue(String name, Boolean defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.booleanValue__c;
    }
    
    public static void setBooleanValue(String name, Boolean value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.booleanValue__c = value;
        upsert properties;
    }
    
    public static Date getDateValue(String name) {
        return getDateValue(name, null);
    }
    
    public static Date getDateValue(String name, Date defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.dateValue__c;
    }
    
    public static void setDateValue(String name, Date value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.dateValue__c = value;
        upsert properties;
    }
    
    public static DateTime getDateTimeValue(String name) {
        return getDateTimeValue(name, null);
    }
    
    public static DateTime getDateTimeValue(String name, DateTime defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.dateTimeValue__c;
    }
    
    public static void setDateTimeValue(String name, DateTime value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.dateTimeValue__c = value;
        upsert properties;
    }
    
    public static Integer getIntegerValue(String name) {
        return getIntegerValue(name, null);
    }
    
    public static Integer getIntegerValue(String name, Integer defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.numberValue__c.intValue();
    }
    
    public static void setIntegerValue(String name, Integer value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.numberValue__c = value;
        upsert properties;
    }
    
    public static Double getDoubleValue(String name) {
        return getDoubleValue(name, null);
    }
    
    public static Double getDoubleValue(String name, Double defaultValue) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return defaultValue;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null || !properties.actif__c) // Ne rien faire si URL et autres propriétés non trouvées
            return defaultValue;
        
        return properties.numberValue__c.doubleValue();
    }
    
    public static void setDoubleValue(String name, Double value) {
        if (String.isEmpty(name)) // Ne rien faire si nom invalide
            return;
        
        GlobalProperties__c properties = GlobalProperties__c.getValues(name);
        if (properties == null)
            properties = new GlobalProperties__c(name = name, actif__c = true);
        properties.numberValue__c = value;
        upsert properties;
    }
    
    /**
    * @description Détermine si un utilisateur est autorisé à utiliser une fonctionnalité de Kube via les propriétés par profil
    * @param customSettingName Nom de la propriété
    * @return Boolean Vrai si l'utilisateur à le droit
    */
    public static Boolean isUserAllowed(String customSettingName){
        Boolean isAllowed = false;
        ProfileProperties__c defaultProperties = ProfileProperties__c.getOrgDefaults();
        ProfileProperties__c userProperties = ProfileProperties__c.getValues(UserInfo.getUserId());
        ProfileProperties__c profileProperties = ProfileProperties__c.getValues(UserInfo.getProfileId());
        
        if(userProperties != null)
            isAllowed = (userProperties.get(customSettingName) == null) ? false : Boolean.valueOf(userProperties.get(customSettingName));
        else if(profileProperties != null)
            isAllowed = (profileProperties.get(customSettingName) == null) ? false : Boolean.valueOf(profileProperties.get(customSettingName));
        else             
            isAllowed = (defaultProperties.get(customSettingName) == null) ? false : Boolean.valueOf(defaultProperties.get(customSettingName));
        
        /*        
        Boolean isAllowed = (defaultProperties.get(customSettingName) == null) ? false : Boolean.valueOf(defaultProperties.get(customSettingName));
        system.debug('defaultProperties : ' + isAllowed );
        if(userProperties.default__c != defaultProperties.default__c) {
            isAllowed = (userProperties.get(customSettingName) == null) ? false : Boolean.valueOf(userProperties.get(customSettingName));
        system.debug('userProperties: ' + isAllowed );
        } else if(profileProperties.default__c != defaultProperties.default__c) {
            isAllowed = (profileProperties.get(customSettingName) == null) ? false : Boolean.valueOf(profileProperties.get(customSettingName));
        system.debug('profileProperties: ' + isAllowed );
        }*/
        
        return isAllowed;
    }
}