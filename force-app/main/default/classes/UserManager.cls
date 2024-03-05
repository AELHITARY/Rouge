//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : UserManager
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 27/02/2023
//-- Version     : 1.3
//-- * 1.3 : Revue suite suppression de rôles
//-- * 1.2 : RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 1.1 : KPKCRM_RQM-87 : Optimisation 
//-- --------------------------------------------------------------------------------- --
public without sharing class UserManager {
    private static final String GENERIC_SUPPORT = 'support@kpark.fr';

    private static final Map<Id, Profile>  profiles = new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
    private static final Map<Id, UserRole> roles    = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole]);

    private static final List<User> activeUsers = [SELECT Id, Name, UserName, FirstName, LastName, Email, IsActive,
                                                        ProfileId, UserRoleId, LastLoginDate, CreatedDate,
                                                        byPassTrigger__c, byPassValIdationRule__c, byPassWorkflowRule__c,
                                                        codeMagasin__c, libelleMagasin__c, codeDV__c, libelleDV__c,
                                                        codeDR__c, libelleDR__c, callCenters__c, equipesCall__c FROM User
                                                    WHERE IsActive = true
                                                    ORDER BY LastLoginDate ASC, CreatedDate ASC NULLS FIRST];

    private List<User> supportUsers = null;
    private List<User> siegeUsers = null;

    private final Id adminProfileId;
    private final Id interfaceProfileId;
    //private final Id DEProfileId;
    //private final Id DAFProfileId;
    private final Id DCProfileId;
    private final Id DVProfileId;
    private final Id DRProfileId;
    private final Id ConsultationProfileId;
    private final Id TAEntrantProfileId;
    private final Id TASortantProfileId;
    private final Id superviseurProfileId;
    private final Id directeurCallProfileId;

    private final Set<Id> profilesIntouchables;

    private final Map<Id, User> activeUserMap;

    /** 
    * @description Constructeur de la classe. 
    * Initialise les variables roles/profils spécifique et les profils intouchable 
    */
    public UserManager() {
        //* Recherche et alimentation de profils spécifiques 
        adminProfileId     = getProfileId(Constants.PROFIL_ADMIN_SYSTEME);
        interfaceProfileId = getProfileId('K/K - Interface');
        //DEProfileId        = getProfileId('K/K - DE');
        //DAFProfileId       = getProfileId('K/K - DAF');
        DCProfileId        = getProfileId('K/K - DC');
        DVProfileId        = getProfileId(Constants.PROFIL_DV);
        DRProfileId        = getProfileId('K/K - DR');
        ConsultationProfileId = getProfileId(Constants.PROFIL_KPK_CONSULTATION);
        TAEntrantProfileId        = getProfileId('K/K - TA/Entrant');
        TASortantProfileId        = getProfileId('K/K - TA/Sortant');
        superviseurProfileId        = getProfileId('K/K - Superviseur');
        directeurCallProfileId        = getProfileId('K/K - DC');

        //* Recherche et alimentation des profils intouchables 
        profilesIntouchables = new Set<Id>();
        String profilesIntParam = PropertiesUtils.getStringValue('maintenance.profilsIntouchables', '');
        if(String.isNotBlank(profilesIntParam)) {
            List<String> profilesIntNames = profilesIntParam.split(';');
            // Récupération des Id selon le nom et ajout dans la liste
            for(String profileInt : profilesIntNames) {
                profilesIntouchables.add(getProfileId(profileInt));
            }
        }

        //* Autres données 
        activeUserMap = new Map<Id, User>(activeUsers);
    }

    /** 
    * @description Retourne l'Id d'un profil selon son nom
    * @param name Nom du profil
    * @return Id Id du profil sinon null si pas de profil trouvé
    */
    public Id getProfileId(String name) {
        if (profiles == null || profiles.isEmpty()) {
            return null;
        }

        for (Profile profile : profiles.values()) {
            if (profile.Name == name) {
                return profile.Id;
            }
        }
        return null;
    }

    /** 
    * @description Retourne l'Id d'un role selon son nom
    * @param name Nom du role
    * @return Id Id du role sinon null si pas de role trouvé
    */
    public Id getRoleId(String name) {
        if (roles == null || roles.isEmpty()) {
            return null;
        }

        for (UserRole role : roles.values()) {
            if (role.Name == name) {
                return role.Id;
            }
        }
        return null;
    }

    /** 
    * @description Retourne tous les utilisateurs actifs
    * @return List<User> Liste de tous les utilisateurs
    */
    public List<User> getUsers() {
        return getUsers((Set<Id>)null, (Set<Id>)null);
    }

    /** 
    * @description Retourne tous les utilisateurs actifs en excluant les profils intouchable ou non
    * @param inclIntouchables Vrai si les utilisateurs des profils intouchables doivent être exclus
    * @return List<User> Liste de tous les utilisateurs
    */
    public List<User> getUsers(Boolean inclIntouchables) {
        return (inclIntouchables == true) ? getUsers() : getUsersExcl(profilesIntouchables, null);
    }

    public List<User> getUsers(Id profile, Id role) {
        Set<Id> profileIds = new Set<Id>();
        if (profile != null) {
            profileIds.add(profile);
        }

        Set<Id> roleIds = new Set<Id>();
        if (role != null) {
            roleIds.add(role);
        }
        return getUsers(profileIds, roleIds);
    }

    public List<User> getUsers(Set<Id> profileIds, Set<Id> roleIds) {
        if ((profileIds == null || profileIds.isEmpty()) && (roleIds == null || roleIds.isEmpty()))
            return activeUsers.clone();

        List<User> users = new List<User>();
        for (User user : activeUsers) {
            if (
                ((user.ProfileId == null && (profileIds == null || profileIds.isEmpty())) || (user.ProfileId != null && profileIds != null && profileIds.contains(user.ProfileId)))
                &&
                ((user.UserRoleId == null && (roleIds == null || roleIds.isEmpty())) || (user.UserRoleId != null && roleIds != null && roleIds.contains(user.UserRoleId)))
                )
            users.add(user);
        }
        return users;
    }

    public List<User> getUsersExcl(Id profile, Id role) {
        Set<Id> profileIds = new Set<Id>();
        if (profile != null) {
            profileIds.add(profile);
        }

        Set<Id> roleIds = new Set<Id>();
        if (role != null) {
            roleIds.add(role);
        }
        return getUsersExcl(profileIds, roleIds);
    }

    public List<User> getUsersExcl(Set<Id> exclProfileIds, Set<Id> exclRoleIds) {
        if ((exclProfileIds == null || exclProfileIds.isEmpty()) && (exclRoleIds == null || exclRoleIds.isEmpty())) {
            return new List<User>();
        }

        Set<Id> inclProfileIds = new Set<Id>();
        Set<Id> inclRoleIds = new Set<Id>();

        for (Id Id : profiles.keySet()) {
            if (exclProfileIds == null || !exclProfileIds.contains(Id)) {
                inclProfileIds.add(Id);
            }
        }
        for (Id Id : roles.keySet()) {
            if (exclRoleIds == null || !exclRoleIds.contains(Id)) {
                inclRoleIds.add(Id);
            }
        }
        return getUsers(inclProfileIds, inclRoleIds);
    }

    public List<String> getUserEmails(List<User> users) {
        if (users == null) {
            return null;
        }

        List<String> emails = new List<String>();
        for (User user : users) {
            if (String.isNotBlank(user.Email)) {
                emails.add(user.email);
            }
        }
        return emails;
    }

    private voId initSupport() {
        User support = getUser(GENERIC_SUPPORT);
        if (support != null) {
            supportUsers = new List<User>();
            supportUsers.add(support);
        } else { // Pas d'utilisateur support générique, donc recherche de tous les utilisateurs ayant le rôle de support
            supportUsers = getUsers(adminProfileId, null);
        }
    }

    private voId initSiege() {
        Set<Id> profileIds = new Set<Id>();
        //ProfileIds.add(DAFProfileId);
        profileIds.add(DCProfileId);
        siegeUsers = getUsers(profileIds, null);
    }

    public List<User> getSupportUsers() {
        if (supportUsers == null) {
            initSupport();
        }
        return supportUsers;
    }

    public List<String> getSupportEmails() {
        return getUserEmails(getSupportUsers());
    }

    public List<User> getSiegeUsers() {
        if (siegeUsers == null) {
            initSiege();
        }
        return siegeUsers;
    }

    public List<String> getSiegeEmails() {
        return getUserEmails(getSiegeUsers());
    }

    public User getUser(Id Id) {
        return activeUserMap.get(Id);
    }

    public User getUser(String UserName) {
        for (User user : activeUsers) {
            // Recherche par 'commence par' plutôt que recherche exacte afin de contrebalancer le suffixe ajouter dans les sandbox
            if (user.UserName.startsWith(UserName)) {
                return user;
            }
        }
        return null;
    }

    public Boolean isSupportUser(User user) {
        if (user == null) {
            return false;
        }
        return (isAdministrator(user) || isInterface(user) || user.UserName.startsWith(GENERIC_SUPPORT));
    }

    public Boolean isCallUser(User user) {
        if (user == null) {
            return false;
        }
        return (isCallDirector(user) || isCallSupervisor(user) || isCallTA(user));
    }

    public Boolean isCallDirector(User user) {
        if (user == null) {
            return false;
        }
        return user.ProfileId == DCProfileId;
    }

    public Boolean isCallSupervisor(User user) {
        if (user == null) {
            return false;
        }
        return (user.ProfileId == superviseurProfileId);
    }

    public Boolean isCallTA(User user) {
        if (user == null) {
            return false;
        }
        return (user.ProfileId == TAEntrantProfileId || user.ProfileId == TASortantProfileId);
    } 

    public Boolean isDV(User user) {
        if (user == null) {
            return false;
        }
        return user.ProfileId == DVProfileId;
    }

    public Boolean isDR(User user) {
        if (user == null) {
            return false;
        }
        return (isKPKConsultation(user) || user.ProfileId == DRProfileId);
    }

    /*public Boolean isDAF(User user) {
        if (user == null)
            return false;
        return user.ProfileId == DAFProfileId;
    }*/

    /*public Boolean isDE(User user) {
        if (user == null)
            return false;
        return user.ProfileId == DEProfileId;
    }*/

    public Boolean isKPKConsultation(User user) {
        if (user == null) {
            return false;
        }
        return user.ProfileId == ConsultationProfileId;
    }

    public Boolean isAdministrator(User user) {
        if (user == null) {
            return false;
        }
        return user.ProfileId == adminProfileId;
    }

    public Boolean isInterface(User user) {
        if (user == null) {
            return false;
        }
        return user.ProfileId == interfaceProfileId;
    }

    public Boolean isIntouchable(User user) {
        if (user == null) {
            return false;
        }
        return profilesIntouchables.contains(user.ProfileId);
    }

    public String getRoleName(User user) {
        if (user == null) {
            return '';
        }
        UserRole role = roles.get(user.UserRoleId);
        return (role == null ? '' : role.Name);
    }

    public String getProfileName(User user) {
        if (user == null) {
            return '';
        }
        Profile profile = profiles.get(user.ProfileId);
        return (profile == null ? '' : profile.Name);
    }
}