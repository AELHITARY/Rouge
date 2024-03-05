//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_User
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/12/2018
//-- Version     : 1.0
//-- * 1.0 : Anonymisation des informations
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_User {  

    /**
    * @description Méthode pour supprimer les enregistrements liés à un utilisateur qui viens d'être désactivé
    * @param userContext Information de l'utilisateur courant
    */
    public static void deleteUsersLinkedRecords(List<User> usersToDea) {
        /*if (!Trigger.isExecuting)
          return;

        system.debug('### DEBUT TR022_User.deleteUsersLinkedRecords');
        List<User> newUsers = (List<User>)Trigger.new;
        Map<Id, User> oldUsers = (Map<Id, User>)Trigger.oldMap;
        Map<String, User> usersToDea = new Map<String, User>();
        
        for(User usr : newUsers){
            User oldUser = Trigger.isInsert ? null : oldUsers.get(usr.id);
            if (!AlreadyUsed.isUsed('TR022_User.deleteUsersLinkedRecords', usr.id)) {
                // Désactivation de l'utilisateur, suppression des données
                if(Trigger.isUpdate && usr.IsActive != oldUser.IsActive && usr.IsActive == false) {
                    usersToDea.put(usr.Id, usr);
                }
            }
        }*/

        // Suppression des listes de phone de l'utilisateur réservés/associés à cet utilisateur afin que les comptes redeviennent disponibles pour d’autres listes de phone
        if(!usersToDea.isEmpty()) {
            List<ListePhoningVendeur__c> listePhoningVendeurList = [SELECT Id FROM ListePhoningVendeur__c WHERE user__c IN :usersToDea/*.keySet()*/];
            if(!listePhoningVendeurList.isEmpty())
                delete listePhoningVendeurList;
        }
        system.debug('### FIN TR022_User.deleteUsersLinkedRecords');
    }

    /**
    * @description Méthode pour supprimer les enregistrements systèmes liés à un utilisateur qui viens d'être désactivé
    * @param users Utilisateurs désactivés
    */
    /*private static void processDeleteUsersLinkedRecords(List<User> users){
        system.debug('### DEBUT TR022_User.processDeleteUsersLinkedRecords');

        try {   
            if(!users.isEmpty()) {
                // Parcours les utilisateurs
                for(User u : users){
                    system.debug('## Désactivation: '+u.Id);
                    u.dateDesactivation__c = system.now();
                    u.utilisateurAyantDesactive__c = UserInfo.getUserId();
                    // Supprimer les permissions
                    u.UserRoleId = null;
                    u.UserPermissionsMarketingUser = false;
                    u.UserPermissionsOfflineUser = false;
                    //u.Sales Anywhere = false;
                    u.UserPermissionsKnowledgeUser = false;
                    u.UserPermissionsInteractionUser = false;
                    u.UserPermissionsSupportUser = false;
                    u.UserPermissionsLiveAgentUser = false;
                    u.UserPermissionsMobileUser = false;
                    u.UserPermissionsSFContentUser = false;
                    // Efface les champs
                    u.Alias= 'XXX';
                    u.codePostal__c= null;
                    u.rue__c= null;
                    u.ville__c= null;
                    u.PostalCode = null;
                    u.City = null;
                    u.Country = null;
                    u.Street = null;
                    u.State = null;
                    u.CommunityNickname= null;
                    u.CompanyName= null;
                    u.Department= null;
                    u.Division= null;
                    u.Matricule__c= null;
                    u.EmployeeNumber= null;
                    u.Extension= null;
                    u.Fax= null;
                    u.MobilePhone= null;
                    u.Phone= null;
                    u.Title= null;
                    u.URLFacebook__c= null;                    
                    u.SGID__c= null;              
                    u.dateEntree__c= null;      
                    u.dateSortie__c= null;
                    u.localisation__Latitude__s = null;
                    u.localisation__Longitude__s = null;
                    u.publicationFacebook__c = false;
                }
            
                // Supprime les références
                List<PermissionSetAssignment> permissionSetList = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment 
                                                                    WHERE AssigneeId IN :users AND PermissionSetId IN  (SELECT Id 
                                                                                                                           FROM PermissionSet
                                                                                                                           WHERE IsOwnedByProfile =false)];
                List<PermissionSetLicenseAssign> permissionSetLicenseList = [SELECT Id, PermissionSetLicenseId, AssigneeId 
                                                                                FROM PermissionSetLicenseAssign WHERE AssigneeId IN :users];
                List<GroupMember> groupList = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :users];
                List<CollaborationGroupMember> collaborationGroupList = [SELECT Id FROM CollaborationGroupMember WHERE MemberId IN :users];
                
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
            }
            system.debug('### FIN TR022_User.processDeleteUsersLinkedRecords');   
        } catch(Exception e) {
            system.debug('## ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }    */
}