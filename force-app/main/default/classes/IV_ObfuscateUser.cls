//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_ObfuscateUser 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 25/01/2019
//-- Version     : 1.1
//-- * 1.1 : Mise à jour pour prise en charge d'anonymisation des ServiceRessource
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_ObfuscateUser {
    
    /**
    * @description Méthode pour supprimer et anonymiser les champs standards et perso d'un utilisateur qui viens d'être désactivé
    * @param users Utilisateur désactivé
    */
    @InvocableMethod(label='Anonymisation adresse email utilisateur' description='Anonymisation de l\'adresse email de l\'utilisateur et des champs standard')
    public static void obfuscateUser(List<User> users) {
        List<String> usersId = new List<String>();
        for(User u : users){
            usersId.add(u.Id);
        }
        if(!usersId.isEmpty())
            processObfuscateUser(usersId);
    }

    /**
    * @description Méthode pour supprimer et anonymiser les champs standards et perso d'un utilisateur qui viens d'être désactivé
    * @param usersId Id des utilisateurs désactivés
    */
    public static void processObfuscateUser(List<String> usersId){
        system.debug('### DEBUT processObfuscateUser'); 
        List<User> userToUp = new List<User>();

        try {   
            // Anonymisation des champs custom
            if(!usersId.isEmpty()) {            

                // Mise à jour des champs standards et personnalisés
                userToUp = SchemaUtils.executeQuery('User', 'Id', usersId);
                for(User usr : userToUp) {
                    // Supprimer les permissions
                    usr.UserRoleId = null;
                    usr.UserPermissionsMarketingUser = false;
                    usr.UserPermissionsOfflineUser = false;
                    //usr.Sales Anywhere = false;
                    usr.UserPermissionsKnowledgeUser = false;
                    usr.UserPermissionsInteractionUser = false;
                    usr.UserPermissionsSupportUser = false;
                    usr.UserPermissionsMobileUser = false;
                    usr.UserPermissionsSFContentUser = false;
                    // Mise à jour des champs personnalisés
                    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('User').getDescribe().fields.getMap();  
                    for(String fieldName : fieldsMap.keySet()){
                        Schema.DescribeFieldResult fieldInfo = fieldsMap.get(fieldName).getDescribe();
                        if ( fieldName != 'dateDesactivation__c' && fieldName!= 'utilisateurAyantDesactive__c' && fieldInfo.isCustom() && !fieldInfo.isCalculated() 
                            && fieldInfo.isCreateable() && !fieldInfo.isDeprecatedAndHidden()) { 
                            DisplayType fieldType = fieldsMap.get(fieldName).getDescribe().getType();
                            system.debug('## User field: '+fieldName+' / '+fieldType);
                            if(fieldType == DisplayType.Boolean) {
                                usr.put(fieldName, false);
                            } else { 
                                usr.put(fieldName, null);
                            }
                        }    
                    }
                    // Modifie date d'ano
                    usr.dateAnonymisation__c = System.now();
                }            
                update userToUp;
            
                // Supprime les permissions et liens aux groupes sauf ceux de FSL (pour autoriser anonymisation des données FSL)
                List<PermissionSetAssignment> permissionSetList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :usersId 
                                                                    AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE IsOwnedByProfile =false AND (NOT Name LIKE '%FSL%'))];
                List<PermissionSetLicenseAssign> permissionSetLicenseList = [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN :usersId 
                                                                    AND PermissionSetLicenseId IN (SELECT Id FROM PermissionSetLicense WHERE (NOT DeveloperName LIKE '%FieldService%'))];
                List<GroupMember> groupList = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :usersId];
                List<CollaborationGroupMember> collaborationGroupList = [SELECT Id FROM CollaborationGroupMember WHERE MemberId IN :usersId];

                system.debug('## permissionSetList: '+permissionSetList);
                system.debug('## permissionSetLicenseList: '+permissionSetLicenseList);
                system.debug('## groupList: '+groupList);
                system.debug('## collaborationGroupList: '+collaborationGroupList);
                if(!permissionSetList.isEmpty())
                    delete permissionSetList;
                if(!permissionSetLicenseList.isEmpty())
                    delete permissionSetLicenseList;
                if(!groupList.isEmpty())
                    delete groupList;
                if(!collaborationGroupList.isEmpty())
                    delete collaborationGroupList;
                
                // Appel asynchrone pour anonymiser les users (avec suppr des ServiceRessource)
                system.debug('## Call QA_AsyncObfuscateUser');
                system.enqueueJob(new QA_AsyncObfuscateUser(userToUp, true, null, false));
                
            }
            system.debug('### FIN processObfuscateUser'); 
        } catch(Exception e) {
            system.debug('## ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }    
}