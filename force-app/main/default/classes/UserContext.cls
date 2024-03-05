//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : UserContext
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/02/2023
//-- Version     : 1.1
//-- * 1.1 : Revue suite suppression de rôles
//-- * 1.0 : Ajout de la fonction de récupération des magasins
//-- --------------------------------------------------------------------------------- --
public without sharing class UserContext {
    private User     user;
    private Profile  profile;
    private UserRole role;
    private Boolean  byPassValidationRules = false;
    private Boolean  byPassWorkflowRules   = false;
    private Boolean  byPassTriggers        = false;
    private static Map<Id, UserContext> userContexts = new Map<Id, UserContext>();
    private static Boolean enabledUserCache = PropertiesUtils.getBooleanValue('usercontext.cache.enabled', true);

    public static UserContext getContext() {
        return getContext(userInfo.getUserId());
    }

    public static UserContext getContext(ID userID) {
        if (userID == null) {
            userId = userInfo.getUserId();
        }

        Set<ID> userIDs = new Set<ID>();
        userIDs.add(userID);
        Map<Id, UserContext> contexts = getContexts(userIDs);
        return (contexts.isEmpty() ? null : contexts.get(userID));
    }

    public static Map<Id, UserContext> getContexts(Set<ID> userIDs) {
        if (userIDs == null || userIds.isEmpty()) {
            return new Map<Id, UserContext>();
        }

        Map<Id, UserContext> contexts = new Map<Id, UserContext>();
        Set<ID> usersToFind = new Set<ID>();
        if (enabledUserCache) {
            for (ID userID : userIDs) {
                if (userContexts.containsKey(userId)) {
                    contexts.put(userID, userContexts.get(userID));
                } else {
                    usersToFind.add(userID);
                }
            }
        } else {
            usersToFind.addAll(userIds);
        }

        if (!usersToFind.isEmpty()) {
            List<User> users = getUsers(usersToFind);
            for (User user : users) {
                contexts.put(user.id, new UserContext(user));
            }
        }

        return contexts;
    }

    private static List<User> getUsers(Set<ID> userIDs) {
        System.debug('>>> UserContext >>> requête pour les utilisateurs ' + userIds);
        try {
            return [SELECT id, alias, email, firstName, isActive, lastName, matricule__c, name, userName,
                        byPassTrigger__c, byPassValidationRule__c, byPassWorkflowRule__c, callcenters__c, equipesCall__c, CallCenterId, 
                        codeDR__c, codeDV__c, codeMagasin__c, libelleDR__c, libelleDV__c, libelleMagasin__c,
                        createdDate, lastModifiedDate, lastLoginDate, profileId, profile.name, userRoleId, userRole.name,
                        rue__c, ville__c, codePostal__c, localisationLatitude__c, localisationLongitude__c
                    FROM User
                    WHERE id IN :userIDs];
        } catch(Exception e) {
            System.debug('>>> USER - CONTEXT >>> ERROR # getUsers() ==> ' + e.getMessage());
            return null;
        }
    }

    private UserContext(User userData) {
        user = userData;
        if (user != null) {
            profile = user.profile;
            role = user.userRole;
        }

        // Enregistrement dans le cache
        if (enabledUserCache) {
            userContexts.put(user.id, this);
        }
        System.debug('>>> UserContext >>> nouvelle instance pour l\'ID ' + user.Id);
    }

    public User getUser() {
        return user;
    }

    public Profile getProfile() {
        return profile;
    }

    public UserRole getRole() {
        return role;
    }

    public Boolean isCallUser() {
        if (profile != null && (profile.name == 'K/K - DC'              ||
                                profile.name.startsWith('K/K - TA')     ||
                                profile.name == 'K/K - Superviseur'     ||
                                profile.name == 'K/K - Assistante Call')) {
            return true;
        }
        return false;
    }

    public Boolean isSaleUser() {
        if (profile != null && (profile.name == 'K/K - DR'                   ||
                                profile.name.startsWith('K/K - DV')          ||
                                profile.name.startsWith('K/K - En charge de magasin') ||
                                profile.name == 'K/K - Foire'                ||
                                profile.name == 'K/K - Formateur'            ||
                                profile.name.startsWith('K/K - RV')          ||
                                profile.name.startsWith('K/K - RVJ')         ||
                                profile.name == 'K/K - TP'                   ||
                                profile.name.startsWith('K/K - Vendeur'))) {
            return true;
        }
        if (role != null && (role.name    == 'Foire' ||
                            role.name    == 'Formateur')) {
            return true;
        }
        return false;
    }

    public Boolean isSupportUser() {
        if (profile != null && (profile.name.containsIgnoreCase('Administrat') ||
                                profile.name.containsIgnoreCase('Interface'))) {
            return true;
        }
        return false;
    }
    
    public Boolean isChatterUser() {
        List<PermissionSetAssignment> permissionsList = [SELECT Assignee.Id, Assignee.Name FROM PermissionSetAssignment WHERE assignee.isactive = true 
                                                        AND (permissionset.permissionsChatterOwnGroups = true OR permissionset.permissionsChatterFileLink = true 
                                                            OR permissionset.permissionsChatterInviteExternalUsers = true OR permissionset.permissionsManageChatterMessages = true 
                                                            OR permissionset.permissionsModerateChatter = true OR permissionset.permissionsViewAllData = true 
                                                            OR permissionset.permissionsChatterEnabledforUser = true)];
        for(PermissionSetAssignment permission : permissionsList) {
            if(permission.Assignee.Id == user.Id) {
                return true;
            }
        }
        return false;
    }

    public Boolean canByPassValidationRules() {
        return byPassValidationRules || (user.byPassValidationRule__c == null ? FALSE : user.byPassValidationRule__c);
    }

    public Boolean canByPassWorkflowRules() {
        return  byPassWorkflowRules || (user.byPassWorkflowRule__c == null ? FALSE : user.byPassWorkflowRule__c);
    }

    public Boolean canByPassTrigger(String triggerName) {
        if (String.isBlank(triggerName)) {
            return false;
        }
        return byPassTriggers || (';' + user.byPassTrigger__c + ';').containsIgnoreCase(';' + triggerName.trim() + ';');
    }

    /* Surcharge locale de la configuration de l'utilisateur.
        Utile sur des batchs par exemple qui ont besoin de metre à jour des informations
        sans relancer toutes les règles ou triggers (ex: dédoublonnage qui n'a pas besoin
        de relancer le calcul des indicateurs ou les flux LTV) */
    public void setByPassValidationRules(Boolean byPass) {
        byPassValidationRules = byPass == null ? false : bypass;
    }

    public void setByPassWorkflowRules(Boolean byPass) {
        byPassWorkflowRules = byPass == null ? false : bypass;
    }

    public void setByPassTriggers(Boolean byPass) {
        byPassTriggers = byPass == null ? false : bypass;
    }
    
    /**
    * @description Récupération de la liste des magasins de l'utilisateur en fonction des rôles et de la sectorisation
    * @return Map<String, String> Liste des magasins de l'utilsateur
    */
    public Map<String, String> getMagasins() {
		System.debug('### DEBUT UserContext.getMagasins');
		Map<String, String> result = new Map<String, String>();
		      
    	// 1 - Utilisateur affecté à un magasin
      	if (!String.isBlank(user.codeMagasin__c)) {
        	System.debug('## Step 1');
        	List<UserRole> roles = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE name LIKE 'MAG%'];
        	System.debug('## Roles: ' + roles);
    		// Récupération des magasins selon les roles enfants                                                        
    		Set<String> magasinsToFind = new Set<String>();
    		if(role != null) {
    			magasinsToFind.add(role.Name.left(7));
				fillMagasins(user.userRoleId, roles, magasinsToFind);
        		// Vérification par rapport à la sectorisation
				for (AggregateResult sect : [SELECT codeMagasin__c, libelleMagasin__c FROM Sectorisation__c 
                	                     WHERE codeMagasin__c IN :magasinsToFind
                    	                 GROUP BY codeMagasin__c, libelleMagasin__c 
                        	             ORDER BY libelleMagasin__c ASC]) {
          			result.put((String) sect.get('codeMagasin__c'), (String) sect.get('libelleMagasin__c'));
         		}
    		}
      	}      
      	// 2 - Utilisateur affecté à une DV
      	else if (!String.isBlank(user.codeDV__c)) {
        	System.debug('## Step 2');
        	for (AggregateResult sect : [SELECT codeMagasin__c, libelleMagasin__c FROM Sectorisation__c 
                                     		WHERE codeMagasin__c != '' AND codeDV__c = :user.codeDV__c
                                     		GROUP BY codeMagasin__c, libelleMagasin__c 
                                     		ORDER BY libelleMagasin__c ASC]) { 
          		result.put((String) sect.get('codeMagasin__c'), (String) sect.get('libelleMagasin__c'));
      		}
      	}        
      	// 3 - Utilisateur affecté à une DR
      	else if (!String.isBlank(user.codeDR__c)) {
        	System.debug('## Step 3');
        	for (AggregateResult sect : [SELECT codeMagasin__c, libelleMagasin__c FROM Sectorisation__c 
                                     		WHERE codeMagasin__c != '' AND codeRegion__c = :user.codeDR__c
                                     		GROUP BY codeMagasin__c, libelleMagasin__c 
                                     		ORDER BY libelleMagasin__c ASC]) { 
      			result.put((String) sect.get('codeMagasin__c'), (String) sect.get('libelleMagasin__c'));
			}
      	}
      	// 4 - Utilisateur sans affectation commerciale
      	else {
        	System.debug('## Step 4');
        	for (AggregateResult sect : [SELECT codeMagasin__c, libelleMagasin__c FROM Sectorisation__c 
                                     		WHERE codeMagasin__c != ''
                                     		GROUP BY codeMagasin__c, libelleMagasin__c 
                                     		ORDER BY libelleMagasin__c ASC]) { 
          		result.put((String) sect.get('codeMagasin__c'), (String) sect.get('libelleMagasin__c'));
     		}
      	}
      	System.debug('### FIN UserContext.getMagasins');
      	return result;
	}
    
    /**
    * @description Fonction récursive pour récupérer les roles "Magasin" enfants
    * @param roleID Id du role actuel
    * @param roles Liste des rôles
    * @param magasinsToFind Code du magasin à trouver
    */
    private void fillMagasins(ID roleID, List<UserRole> roles, Set<String> magasinsToFind) {
    	System.debug('## Fill : ' + roleId);
      	for (UserRole role : roles) {
        	if (role.parentRoleId == roleID) {
          		System.debug('## Found : ' + role.id + ' / ' + role.name);
          		magasinsToFind.add(role.Name.left(7));
          		fillMagasins(role.id, roles, magasinsToFind);  
        	}
    	}
    }

    // Méthode pour déterminer si un utilisateur peut bypasser la validation avec une Autorisation personnalisée
    public Boolean utilisateurPeutBypasserValidation(String permissionSetName) {
        // Vérifier si l'utilisateur a l'ensemble de permissions attribué
        List<PermissionSetAssignment> permissionAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                                                                AND PermissionSet.Name  =:permissionSetName LIMIT 1];
    
        return !permissionAssignments.isEmpty();
    }
}