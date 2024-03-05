//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : SchemaUtils
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 09/03/2023
//-- Version     : 1.1
//-- * Mise à jour API 57
//-- * Ajout des fonctions pour requête avec ORDER BY
//-- --------------------------------------------------------------------------------- --
public without sharing class SchemaUtils {
    private static final Map<String,Schema.SObjectType> GLOBAL_DESC = Schema.getGlobalDescribe();
    private static final Set<String> REMOVED_FIELDS = new Set<String>();
    
    {
        // Champs en minuscule
        REMOVED_FIELDS.add('SharingType');
    }

    private static final String SOQL_SELECT  = 'SELECT ';
    private static final String SOQL_FROM    = ' FROM ';
    private static final String SOQL_WHERE   = ' WHERE ';
    private static final String SOQL_GROUPBY = ' GROUP BY ';
    private static final String SOQL_ORDERBY = ' ORDER BY ';
    private static final String SOQL_AND     = ' AND ';
    private static final String SOQL_OR      = ' OR ';
    private static final String SOQL_ID      = 'id';

    private static final Map<String, String> EMPTY_RELATIONS = (Map<String, String>) null;
    private static final Set<String>         EMPTY_IDSET     = (Set<String>) null;
    private static final List<String>        EMPTY_IDLIST    = (List<String>) null;

    private static final String OBJECT_USER        = 'User';
    private static final String OBJECT_LEAD        = 'Lead';
    private static final String OBJECT_ACCOUNT     = 'Account';
    private static final String OBJECT_OPPORTUNITY = 'Opportunity';
    private static final String OBJECT_EVENT       = 'Event';
    private static final String OBJECT_TASK        = 'Task';
    private static final String OBJECT_PROFILE     = 'Profile';
    private static final String OBJECT_ROLE        = 'UserRole';
    private static final String OBJECT_CHANTIER    = 'Chantier__c';

    public static final String PREFIX_USER        =  GLOBAL_DESC.get(OBJECT_USER).getDescribe().getKeyPrefix();
    public static final String PREFIX_LEAD        =  GLOBAL_DESC.get(OBJECT_LEAD).getDescribe().getKeyPrefix();
    public static final String PREFIX_ACCOUNT     =  GLOBAL_DESC.get(OBJECT_ACCOUNT).getDescribe().getKeyPrefix();
    public static final String PREFIX_OPPORTUNITY =  GLOBAL_DESC.get(OBJECT_OPPORTUNITY).getDescribe().getKeyPrefix();
    public static final String PREFIX_EVENT       =  GLOBAL_DESC.get(OBJECT_EVENT).getDescribe().getKeyPrefix();
    public static final String PREFIX_TASK        =  GLOBAL_DESC.get(OBJECT_TASK).getDescribe().getKeyPrefix();
    public static final String PREFIX_PROFILE     =  GLOBAL_DESC.get(OBJECT_PROFILE).getDescribe().getKeyPrefix();
    public static final String PREFIX_ROLE        =  GLOBAL_DESC.get(OBJECT_ROLE).getDescribe().getKeyPrefix();
    public static final String PREFIX_CHANTIER    =  GLOBAL_DESC.get(OBJECT_CHANTIER).getDescribe().getKeyPrefix();

    public static String getObjectPrefix(String name) {
        Schema.SObjectType objectType = GLOBAL_DESC.get(name);
        return objectType == null ? null : objectType.getDescribe().getKeyPrefix();
    }

    private static String getFieldList(String name, String prefix) {
        Schema.SObjectType objectType = GLOBAL_DESC.get(name);

        if (objectType == null)
            return null;

        Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();

        String fieldList;
        prefix = StringUtils.isEmpty(prefix) ? '' : prefix + '.';

        for (String field : fieldsMap.keySet()) {
            // CRM-377 : Exlure les champs de type location
            if (fieldsMap.get(field).getDescribe().getType() != Schema.DisplayType.Location && !(REMOVED_FIELDS.contains(field.toLowerCase()))) {
                if (StringUtils.isEmpty(fieldList)) {
                    fieldList = prefix + field;
                } else {
                    fieldList += ', ' + prefix + field;
                }
            }
        }
        return fieldList;
    }

    public static String buildQuery(String objectName, String whereText, String groupByText, String orderByText, Map<String, String> relations) {
        String soql = SOQL_SELECT + getFieldList(objectName, '');

        if (relations != null && !relations.isEmpty())
            for (String relationName : relations.keySet())
                soql += ', ' + getFieldList(relations.get(relationName), relationName);

        soql += SOQL_FROM   + objectName;

        if (!StringUtils.isEmpty(whereText))
            soql += SOQL_WHERE + whereText;
        if (!StringUtils.isEmpty(groupByText))
            soql += SOQL_GROUPBY + groupByText;
        if (!StringUtils.isEmpty(orderByText))
            soql += SOQL_ORDERBY + orderByText;

        System.debug('>>> SOQL Query >>> ' + soql);
        return soql;
    }

    /** A - Construction et exécution de requêtes SOQL **/
    public static String getQuery(String objectName, Map<String, String> relations) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }

    public static String getQuery(String objectName) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        return buildQuery(objectName, whereText, groupByText, orderByText, EMPTY_RELATIONS);
    }

    public static List<SObject> executeQuery(String objectName, Map<String, String> relations) {
        system.debug('Query : ' + getQuery(objectName, relations));
        return Database.query(getQuery(objectName, relations));
    }

    public static List<SObject> executeQuery(String objectName) {
        return Database.query(getQuery(objectName));
    }

    /** B - Construction et exécution de requêtes SOQL sur un champ de type ID **/
    public static String getQuery(String objectName, String fieldName, ID fieldValue, Map<String, String> relations) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        if (!StringUtils.isEmpty(fieldName) && !StringUtils.isEmpty(fieldValue))
            whereText = fieldName + ' = \'' + fieldValue + '\'';

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }

    public static String getQuery(String objectName, String fieldName, ID fieldValue) {
        return getQuery(objectName, fieldName, fieldValue, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, String fieldName, Set<ID> fieldValues, Map<String, String> relations) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        if (!StringUtils.isEmpty(fieldName) && fieldValues != null && !fieldValues.isEmpty()) {
            String idents = '';
            for (String ident : fieldValues) {
                if (idents.length() != 0)
                    idents += ', ';
                idents += '\'' + ident + '\'';
            }

            whereText = fieldName + ' IN (' + idents + ')';
        }

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }

    public static String getQuery(String objectName, String fieldName, Set<ID> fieldValues) {
        return getQuery(objectName, fieldName, fieldValues, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, String fieldName, List<ID> fieldValues, Map<String, String> relations) {
        Set<ID> idents = new Set<ID>();
        if (fieldValues != null && !fieldValues.isEmpty())
            idents.addAll(fieldValues);
        return getQuery(objectName, fieldName, idents, relations);
    }

    public static String getQuery(String objectName, String fieldName, List<ID> fieldValues) {
        Set<ID> idents = new Set<ID>();
        if (fieldValues != null && !fieldValues.isEmpty())
            idents.addAll(fieldValues);
        return getQuery(objectName, fieldName, idents, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, ID fieldValue, Map<String, String> relations) {
        return getQuery(objectName, SOQL_ID, fieldValue, relations);
    }

    public static String getQuery(String objectName, Set<ID> fieldValues, Map<String, String> relations) {
        return getQuery(objectName, SOQL_ID, fieldValues, relations);
    }

    public static String getQuery(String objectName, List<ID> fieldValues, Map<String, String> relations) {
        Set<ID> idents = new Set<ID>();
        if (fieldValues != null && !fieldValues.isEmpty())
            idents.addAll(fieldValues);
        return getQuery(objectName, SOQL_ID, idents, relations);
    }

    public static String getQuery(String objectName, ID fieldValue) {
        return getQuery(objectName, SOQL_ID, fieldValue, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, Set<ID> fieldValues) {
        return getQuery(objectName, SOQL_ID, fieldValues, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, List<ID> fieldValues) {
        Set<ID> idents = new Set<ID>();
        if (fieldValues != null && !fieldValues.isEmpty())
            idents.addAll(fieldValues);
        return getQuery(objectName, SOQL_ID, idents, EMPTY_RELATIONS);
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, ID fieldValue, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValue, relations));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, ID fieldValue) {
        return Database.query(getQuery(objectName, fieldName, fieldValue));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, Set<ID> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, Set<ID> fieldValues) {
        return Database.query(getQuery(objectName, fieldName, fieldValues));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, List<ID> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, List<ID> fieldValues) {
        return Database.query(getQuery(objectName, fieldName, fieldValues));
    }

    public static List<SObject> executeQuery(String objectName, ID fieldValue, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldValue, relations));
    }

    public static List<SObject> executeQuery(String objectName, Set<ID> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, List<ID> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, ID fieldValue) {
        return Database.query(getQuery(objectName, fieldValue));
    }

    public static List<SObject> executeQuery(String objectName, Set<ID> fieldValues) {
        return Database.query(getQuery(objectName, fieldValues));
        
    }
   
    public static List<SObject> executeQuery(String objectName, List<ID> fieldValues) {
        return Database.query(getQuery(objectName, fieldValues));
    }
    /** C - Construction et exécution de requêtes SOQL sur un champ autre qu'ID **/
    public static String getQuery(String objectName, String fieldName, String fieldValue, Map<String, String> relations) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        if (!StringUtils.isEmpty(fieldName) && !StringUtils.isEmpty(fieldValue))
            whereText = fieldName + ' = \'' + fieldValue + '\'';

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }

    // CRM-462 - WDO - Ajout de getQuery avec posssibilité de tri (ORDER BY)
    public static String getQuery(String objectName, String fieldName, String fieldValue, Map<String, String> relations, String orderby) {
        String whereText   = null;
        String orderByText = orderby;
        String groupByText = null;

        if (!StringUtils.isEmpty(fieldName) && !StringUtils.isEmpty(fieldValue))
            whereText = fieldName + ' = \'' + fieldValue + '\'';

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }
    // CRM-462 - WDO

    public static String getQuery(String objectName, String fieldName, String fieldValue) {
        return getQuery(objectName, fieldName, fieldValue, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, String fieldName, Set<String> fieldValues, Map<String, String> relations) {
        String whereText   = null;
        String orderByText = null;
        String groupByText = null;

        if (!StringUtils.isEmpty(fieldName) && fieldValues != null && !fieldValues.isEmpty()) {
            String idents = '';
            for (String ident : fieldValues) {
                if (idents.length() != 0)
                    idents += ', ';
                idents += '\'' + ident + '\'';
            }

            whereText = fieldName + ' IN (' + idents + ')';
        }

        return buildQuery(objectName, whereText, groupByText, orderByText, relations);
    }

    public static String getQuery(String objectName, String fieldName, Set<String> fieldValues) {
        return getQuery(objectName, fieldName, fieldValues, EMPTY_RELATIONS);
    }

    public static String getQuery(String objectName, String fieldName, List<String> fieldValues, Map<String, String> relations) {
        Set<String> idents = new Set<String>();
        if (fieldValues != null && !fieldValues.isEmpty())
            idents.addAll(fieldValues);
        return getQuery(objectName, fieldName, idents, relations);
    }

    public static String getQuery(String objectName, String fieldName, List<String> fieldValues) {
        return getQuery(objectName, fieldName, fieldValues, EMPTY_RELATIONS);
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, String fieldValue,Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValue, relations));
    }

    // CRM-462 - WDO - Ajout de getQuery avec posssibilité de tri (ORDER BY)
    public static List<SObject> executeQuery(String objectName, String fieldName, String fieldValue,Map<String, String> relations, String orderby) {
        return Database.query(getQuery(objectName, fieldName, fieldValue, relations, orderby));
    }
    // CRM-462 - WDO

    public static List<SObject> executeQuery(String objectName, String fieldName, String fieldValue) {
        return Database.query(getQuery(objectName, fieldName, fieldValue));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, Set<String> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, Set<String> fieldValues) {
        return Database.query(getQuery(objectName, fieldName, fieldValues));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, List<String> fieldValues, Map<String, String> relations) {
        return Database.query(getQuery(objectName, fieldName, fieldValues, relations));
    }

    public static List<SObject> executeQuery(String objectName, String fieldName, List<String> fieldValues) {
        return Database.query(getQuery(objectName, fieldName, fieldValues));
    }

    /** D - Renvoie des objets standards **/

    public static User getUser(ID id) {
        Map<String, String> relations = new Map<String, String>();
        relations.put('profile', 'Profile');
        relations.put('userRole', 'UserRole');
        List<User> users = executeQuery(OBJECT_USER, id, relations);

        return users == null || users.isEmpty() ? null : users[0];
    }

    public static List<User> getUsers() {
        Map<String, String> relations = new Map<String, String>();
        relations.put('profile', 'Profile');
        relations.put('userRole', 'UserRole');

        return (List<User>)executeQuery(OBJECT_USER, relations);
    }

    public static Profile getProfile(ID id) {
        List<Profile> profiles = executeQuery(OBJECT_PROFILE, id);

        return profiles == null || profiles.isEmpty() ? null : profiles[0];
    }

    public static List<Profile> getProfiles() {
        return (List<Profile>)executeQuery(OBJECT_PROFILE);
    }

    public static UserRole getRole(ID id) {
        List<UserRole> roles = executeQuery(OBJECT_ROLE, id);

        return roles == null || roles.isEmpty() ? null : roles[0];
    }

    public static List<UserRole> getRoles() {
        return (List<UserRole>)executeQuery(OBJECT_ROLE);
    }
}