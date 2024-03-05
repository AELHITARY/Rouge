//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TerritoryUtils
//-- Modifié par : K PAR K
//-- Modifié le  : 03/05/2018
//-- Version     : 1.2
//-- * 1.2 - Correction bug si aucun utilisateurs actif dans un role
//-- * 1.1 - CRM-769 : Réaffectation owner
//-- --------------------------------------------------------------------------------- --
public without sharing class TerritoryUtils {

    private static final String REPOSITORY = 'k-store.territory';
    private static Map<String, User> KPARK_Managers = null;

    private static Map<Id, UserRole> ROLES = new Map<Id, UserRole>([select id, name, parentroleid,
                                                                           (select id,
                                                                                   firstName, lastName, Name, email, phone, mobilePhone, smallPhotoUrl, effectueVentes__c, 
                                                                                   localisation__longitude__s, localisation__latitude__s, isActive,
                                                                                   userRoleId, userRole.name, profileId, profile.name, localisationLongitude__c, localisationLatitude__c,
                                                                                   codeMagasin__c, libelleMagasin__c, codeDV__c, libelleDV__c, codeDR__c, libelleDR__c
                                                                            from users
                                                                            where isActive = true
                                                                            limit 1)
                                                                    from userrole
                                                                    where name like '% - MAG - %'
                                                                       or name like '% - REF - %'
                                                                       or name like '% - DV - %'
                                                                       or name like '% - DR - %']);

    /**
    * @description Fonction pour retourner les codes KStore pour un magasin
    * @param code Code du magasin
    * @return Liste des codes magasins lié à un magasin ou à un KStore
    */
    public static String[] getMagasinsKStore(final String code) {
        if (String.isBlank(code))
            return new String[0];

        List<String> magasins = new List<String>();
        magasins.add(code);

        Map<String, Mapping__c> mappings = Mapping__c.getAll();
        for (Mapping__c mapping : mappings.values())
            if (REPOSITORY.equalsIgnoreCase(mapping.repository__c) && code.equalsIgnoreCase(mapping.pickValue__c))
                magasins.add(mapping.convertedValue__c);

        return magasins;
    }

/**
    public static User getManager(final User user) {
        UserRole role = ROLES.get(user.userRoleId);
        return role == null ? null : getManager(role.parentRoleId);
    }
**/

    public static User getManager(final User user) {
        System.debug('### getManager:User(' + user +')');
        if (user == null)
          System.debug('### getManager:User = NULL!!!');
        else
          System.debug('### getManager:User = OK!!! / ' + user.userRoleId);

        UserRole role = ROLES.get(user.userRoleId);
        UserRole parentRole = (role == null) ? null : ROLES.get(role.parentRoleId);

        System.debug('### getManager:User = ' + role + ' / ' + parentRole);

        User manager = (parentRole == null) ? null : getManager(parentRole);
        System.debug('### getManager:User(' + user +') ==> ' + manager);

        return manager;
    }


    public static User getManager(final String codeEntite) {
      String magasinPattern = codeEntite + ' - REF - %';
      String DVPattern = codeEntite + ' - DV - %';
      String RVPattern = codeEntite + ' - DR - %';

      List<UserRole> roles = [select id, name, parentroleid
                              from userrole
                              where name like :magasinPattern
                                 or name like :DVPattern
                                 or name like :RVPattern
                              limit 1];

      return roles.isEmpty() ? null : getManager(roles[0]);
    }

    private static User getManager(UserRole role) {
      role = ROLES.get(role.id);
      while (role != null) {
        if (!role.users.isEmpty())   // 1 responsable rattaché
            return role.users[0];

        role = ROLES.get(role.parentRoleId);
      }
      return null;
    }
}