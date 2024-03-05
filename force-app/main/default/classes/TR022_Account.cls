//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Account
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/11/2020
//-- Version     : 1.5
//-- * 1.5 : Ajout des fonctions pour la gestion des entités
//-- * 1.4 : CRM-956 : Création et affectation des autorisations (Jalon)
//-- * 1.3 : Ajout de la fonction pour les notifications
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Account {
    private static final Integer GROUP_NAME_MAXLENGTH = 40;
    private static final String ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final String EXRESOURCE_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_EXTERNE_RT);

    /**
    * @description Mise à jour des champs "Email du parrain" de tous les filleuls
    * @param userContext Information de l'utilisateur courant
    */
    public static void setEmailParrain(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        System.debug('### DEBUT TR022_Account.setEmailParrain');
        List<Account> newAccounts = (List<Account>)Trigger.new;
        Map<Id, Account>  oldAccounts = (Map<Id, Account>) Trigger.oldMap;
        List<Id> idNewAccounts = new List<Id>();

        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
            Boolean isCustomerRT = (newAccount.RecordTypeId == ENTITY_RTID || newAccount.RecordTypeId == PROVIDER_RTID || newAccount.RecordTypeId == EXRESOURCE_RTID) ? false : true;
            
            // Modification des filleuls pour un parrain
            if(isCustomerRT && String.isNotBlank(newAccount.parrain__c) 
                && (Trigger.isInsert || (Trigger.isUpdate && (newAccount.parrain__c != oldAccount.parrain__c || newAccount.email__c != oldAccount.email__c)))) 
            {
                idNewAccounts.add(newAccount.Id);
            }
        }

        System.debug('## Parrain: '+idNewAccounts.size());
        if (idNewAccounts.isEmpty()) {
            return;
        }

        // On recupere la liste des filleuls concernés
        if (!idNewAccounts.isEmpty()) {
            List<Account> listFilleul = [SELECT id,emailParrain__c, parrain__c FROM Account WHERE parrain__c IN :idNewAccounts];
            // On met a jour l'email parrain dans les comptes filleuls
            for(Account filleul : listFilleul){
                for(Account parrain : newAccounts){
                    if(filleul.parrain__c == parrain.id){
                        filleul.emailParrain__c = parrain.email__c;
                    }
                }
            }
            update listFilleul;
        }
        System.debug('### FIN TR022_Account.setEmailParrain');
    }
        
    /**
    * @description Créer les processus d'autorisation pour les comptes PERSO ou PRO
    * @param userContext Information de l'utilisateur courant
    */
    public static void createAutorisation(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        System.debug('### DEBUT TR022_Account.createAutorisation');
        List<Account> newAccounts = new List<Account>();
        List<Entitlement> newEntitlementList = new List<Entitlement>();
        String entitlementRTId = DAL.getRecordTypeIdByDevName('Entitlement', 'CaseEntitlement');

        // Récupération seulement des comptes PRO ou PERSO
        for(Account newAccount : (List<Account>)Trigger.new) {
            Boolean isCustomerRT = (newAccount.RecordTypeId == ENTITY_RTID || newAccount.RecordTypeId == PROVIDER_RTID || newAccount.RecordTypeId == EXRESOURCE_RTID) ? false : true;

            if(isCustomerRT) {
                newAccounts.add(newAccount);
            }
        }

        if(!newAccounts.isEmpty()) {
            // Boucle sur tous les processus d'autorisation actif et par défaut
            for(SlaProcess slaContrat : [SELECT Id, Name FROM SlaProcess WHERE IsActive=true AND IsVersionDefault=true]) {
                String slaType = (slaContrat.Name.containsIgnoreCase('réclamation')) ? Constants.ENT_RECLAMATION : Constants.ENT_RELATIONCLIENT;
                // Création des autorisations
                for(Account newAcc : newAccounts) {
                    System.debug('## Création autorisation: '+slaContrat.Id+' - Compte: '+newAcc.Id);
                    Entitlement ent = new Entitlement(Name=newAcc.AccountNumber+' - '+slaContrat.Name,
                                                        AccountId=newAcc.Id, 
                                                        SlaProcessId=slaContrat.Id,
                                                        Type=slaType,
                                                        StartDate=Date.today(),
                                                        RecordTypeId = entitlementRTId);
                    newEntitlementList.add(ent);
                }
            }
        }

        // Insertion des autorisations pour requêtes
        if (!newEntitlementList.isEmpty()) {
            insert newEntitlementList;
        }
        System.debug('### FIN TR022_Account.createAutorisation');
    }

    /**
    * @description Créer les processus d'autorisation pour les comptes
    * @param userContext Information de l'utilisateur courant
    *//*
    @future
    public static void createAutorisation(Map<String,String> accountsMap) {
        List<Entitlement> newEntitlementList = new List<Entitlement>();
        // Boucle sur tous les processus d'autorisation actif et par défaut
        for(SlaProcess slaContrat : [SELECT Id, Name FROM SlaProcess WHERE IsActive=true AND IsVersionDefault=true]) {
            String slaType = (slaContrat.Name.containsIgnoreCase('réclamation')) ? Constants.ENT_RECLAMATION : Constants.ENT_RELATIONCLIENT;
            // Création des autorisations
            for(String newAccId : accountsMap.keySet()) {
                System.debug('## Création autorisation: '+slaContrat.Id+' - Compte: '+newAccId);
                Entitlement ent = new Entitlement(Name=accountsMap.get(newAccId)+' - '+slaContrat.Name,
                                                    AccountId=newAccId, 
                                                    SlaProcessId=slaContrat.Id,
                                                    Type=slaType,
                                                    StartDate=Date.today());
                newEntitlementList.add(ent);
            }
        }

        // Insertion des autorisations pour requêtes
        if (!newEntitlementList.isEmpty()) {
            insert newEntitlementList;
        }
    }*/

    /**
    * @description Supprime les processus d'autorisation lors de la suppression des comptes
    * @param userContext Information de l'utilisateur courant
    */
    public static void deleteAutorisation(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        System.debug('### DEBUT TR022_Account.deleteAutorisation');
        // Sauvegarde
        Savepoint sp = Database.setSavepoint();
        try {
            Database.delete([SELECT Id FROM Entitlement WHERE AccountId IN :Trigger.old], false);
            System.debug('### FIN TR022_Account.deleteAutorisation');
        } catch(Exception e) {
            // Rollback
            Database.rollback(sp);
        }
    }
    
    /**
    * @description Méthode pour créer les files d'attente, groupes et territoire
    * @param newEntities Liste des entités
    */
    public static void createEntityRecords(List<Account> newEntities) {
        System.debug('### DEBUT TR022_Account.createEntityRecords');
        
        try{
            List<Group> queuesToInsert = new List<Group>();
            List<UserRole> rolesToUpdate = new List<UserRole>();
            Map<String, String> rolesMapToInsert = new Map<String, String>();
            List<CollaborationGroup> chatterGroupToInsert = new List<CollaborationGroup>();
            List<Group> publicGroupToInsert = new List<Group>();
            List<Account> entitiesToUpdate = new List<Account>();
            List<ServiceTerritory> serviceTerritoryToInsert = new List<ServiceTerritory>();
            List<OperatingHours> opHoursList = [SELECT Id, Name FROM OperatingHours 
                                                WHERE Name = :PropertiesUtils.getStringValue('fsl.operatingHours.defaultName', 'Par Défaut') LIMIT 1];

            // Map of temporary associated obj names
            Map<String, String> groupsNameList = new Map<String, String>();
            Map<String, String> stGroupsNameList = new Map<String, String>();
            Map<String, String> apiNameList = new Map<String, String>();
            Map<String, String> apiAppQueueNameList = new Map<String, String>();
            Map<String, String> appQueueNameList = new Map<String, String>();
            Map<String, String> roleApiNameList = new Map<String, String>();

            // SOQL - Récupération des infos d'entité
            List<Account> entities = [SELECT Id, Name, KparKReference__c, BillingStreet, BillingPostalCode, BillingCity, BillingCountry,
                                        Localisation__Latitude__s, Localisation__Longitude__s, emailPro__c , Phone, startDate__c,
                                        entityType__c, entityType__r.Name, entityType__r.queue__c, entityType__r.approvalQueue__c,
                                        entityType__r.chatterGroup__c, entityType__r.publicGroup__c, entityType__r.serviceTerritory__c, 
                                        ParentId, Parent.userRoleDevName__c, entityType__r.userRole__c, entityType__r.KparKReference__c 
                                        FROM Account WHERE Id IN :newEntities];

            // Pour chaque entités, on définis les noms pour les groupes et le ST
            for (Account entity : entities) {
                System.debug('## Entité: ' + entity.Id);
                // Construction nom des objets
                String nameForCreation = '['+entity.entityType__r.Name + '] ' + entity.Name;
                String groupNameForCreation = (nameForCreation.length() > GROUP_NAME_MAXLENGTH) ? nameForCreation.substring(0, GROUP_NAME_MAXLENGTH) : nameForCreation;
                String stNameForCreation = (nameForCreation.length() > 255) ? nameForCreation.substring(0, 255) : nameForCreation;
                String roleNameAPIForCreation = entity.KparKReference__c+'_'+entity.entityType__r.KparKReference__c+'_'+entity.Name;
                roleNameAPIForCreation = roleNameAPIForCreation.replaceAll('[^a-zA-Z0-9]', ''); // Supprime les caractères spéciaux 
                String nameAPIForCreation = entity.entityType__r.Name + '_' + entity.KparKReference__c;
                nameAPIForCreation = nameAPIForCreation.replaceAll('[^a-zA-Z0-9]', '_'); // Remplace les caractères spéciaux en _
                String nameAPIAppQueueForCreation = 'Approbation_' + entity.KparKReference__c;
                nameAPIAppQueueForCreation = nameAPIAppQueueForCreation.replaceAll('[^a-zA-Z0-9]', '_'); // Remplace les caractères spéciaux en _
                String nameAppQueue = '[Approbation] ' + entity.Name;
                String nameAppQueueForCreation = (nameAppQueue.length() > GROUP_NAME_MAXLENGTH) ? nameAppQueue.substring(0, GROUP_NAME_MAXLENGTH) : nameAppQueue;
                // Add in list
                apiNameList.put(entity.Id, nameAPIForCreation);
                apiAppQueueNameList.put(entity.Id, nameAPIAppQueueForCreation);
                appQueueNameList.put(entity.Id, nameAppQueueForCreation);
                roleApiNameList.put(entity.Id, roleNameAPIForCreation);
                groupsNameList.put(entity.Id, groupNameForCreation);
                stGroupsNameList.put(entity.Id, stNameForCreation);            
                System.debug('## API Name to check: ' + nameAPIForCreation); 
                System.debug('## API App Queue Name to check: ' + nameAPIAppQueueForCreation);
                System.debug('## Group Name to check: ' + groupNameForCreation);
                System.debug('## ST Name to check: ' + stNameForCreation);
                System.debug('## Role API Name to check: ' + roleNameAPIForCreation);
            }

            // Queries to look for already existing linked records
            List<Group> existingGroups = new List<Group>();
            List<UserRole> existingUserRoles = new List<UserRole>();
            List<CollaborationGroup> existingCollaborationGroups = new List<CollaborationGroup>();
            List<ServiceTerritory> existingServiceTerritory = new List<ServiceTerritory>();
            if(!apiNameList.isEmpty()){
                existingGroups = [SELECT Id, DeveloperName, Type FROM Group WHERE (DeveloperName IN :apiNameList.values() OR DeveloperName IN :apiAppQueueNameList.values())];
            }
            if(!groupsNameList.isEmpty()){
                existingCollaborationGroups = [SELECT Id, Name FROM CollaborationGroup WHERE Name IN :groupsNameList.values()];
            }
            if(!stGroupsNameList.isEmpty()){
                existingServiceTerritory = [SELECT Id, Name FROM ServiceTerritory WHERE Name IN :stGroupsNameList.values()];
            }
            if(!roleApiNameList.isEmpty()){
                existingUserRoles = [SELECT Id, Name, DeveloperName FROM UserRole WHERE DeveloperName IN :roleApiNameList.values()];
            }
            System.debug('## Existing Group: ' + existingGroups.size());
            System.debug('## Existing UserRole: ' + existingUserRoles.size());
            System.debug('## Existing Chatter Group: ' + existingCollaborationGroups.size());
            System.debug('## Existing ST: ' + existingServiceTerritory.size());

            // Pour chaque entités, on créé les enregistrements liés
            for (Account entity : entities) {
                Boolean queueAlreadyExist = false;
                Boolean appQueueAlreadyExist = false;
                Boolean roleAlreadyExist = false;
                Boolean publicGroupAlreadyExist = false;
                Boolean chatterGroupAlreadyExist = false;
                Boolean serviceTerritoryAlreadyExist = false;
                System.debug('## Entité: ' + entity.Id);
                String groupNameForCreation = groupsNameList.get(entity.Id);
                String stNameForCreation = stGroupsNameList.get(entity.Id);
                String nameAPIForCreation = apiNameList.get(entity.Id);
                String nameAPIAppQueueForCreation = apiAppQueueNameList.get(entity.Id);
                String nameAppQueueForCreation = appQueueNameList.get(entity.Id);
                String roleNameAPIForCreation = roleApiNameList.get(entity.Id);
                System.debug('## Nom API: ' + nameAPIForCreation);
                System.debug('## Nom Role API: ' + roleNameAPIForCreation);
                
                // File d'attente
                for(Group grp : existingGroups){
                    if(grp.DeveloperName == nameAPIForCreation && grp.Type == 'Queue'){
                        queueAlreadyExist = true;
                        queuesToInsert.add(grp);
                    }
                }
                if (entity.entityType__r.queue__c && !queueAlreadyExist) {
                    Group newQueue = new Group(Type='Queue', Name=groupNameForCreation, DeveloperName = nameAPIForCreation, Email = entity.emailPro__c);
                    System.debug('## newQueue: ' + newQueue);
                    queuesToInsert.add(newQueue);
                }

                // File d'attente d'approbation
                for(Group grp : existingGroups){
                    if(grp.DeveloperName == nameAPIAppQueueForCreation && grp.Type == 'Queue'){
                        appQueueAlreadyExist = true;
                        queuesToInsert.add(grp);
                    }
                }
                if (entity.entityType__r.approvalQueue__c && !appQueueAlreadyExist) {
                    Group newApprovalQueue = new Group(Type='Queue', Name=nameAppQueueForCreation, DeveloperName = nameAPIAppQueueForCreation, Email = entity.emailPro__c);
                    System.debug('## newApprovalQueue: ' + newApprovalQueue);
                    queuesToInsert.add(newApprovalQueue);
                }

                // Role
                for(UserRole usrRole : existingUserRoles){
                    if(usrRole.DeveloperName == roleNameAPIForCreation){
                        roleAlreadyExist = true;
                        rolesToUpdate.add(usrRole);
                    }
                }
                if (entity.entityType__r.userRole__c && !roleAlreadyExist) {
                    rolesMapToInsert.put(entity.Id, roleNameAPIForCreation);
                }

                // Groupe Chatter
                for(CollaborationGroup cg : existingCollaborationGroups){
                    if(cg.Name == groupNameForCreation){
                        chatterGroupAlreadyExist = true;
                        chatterGroupToInsert.add(cg);
                    }
                }
                if (entity.entityType__r.chatterGroup__c && !chatterGroupAlreadyExist) {
                    CollaborationGroup newChatterGroup = new CollaborationGroup(CollaborationType='Public', Name=groupNameForCreation);
                    System.debug('## newChatterGroup: ' + newChatterGroup);
                    chatterGroupToInsert.add(newChatterGroup);
                }

                // Groupe public
                for(Group grp : existingGroups){
                    if(grp.DeveloperName == nameAPIForCreation && grp.Type == 'Regular'){
                        publicGroupAlreadyExist = true;
                        publicGroupToInsert.add(grp);
                    }
                }
                if (entity.entityType__r.publicGroup__c && !publicGroupAlreadyExist) {
                    Group newPublicGroup = new Group(Type='Regular', Name=groupNameForCreation, DeveloperName = nameAPIForCreation);
                    System.debug('## newPublicGroup: ' + newPublicGroup);
                    publicGroupToInsert.add(newPublicGroup);
                }

                // Territoire de service
                for(ServiceTerritory st : existingServiceTerritory){
                    if(st.Name == stNameForCreation){
                        serviceTerritoryAlreadyExist = true;
                        serviceTerritoryToInsert.add(st);
                    }
                }
                if (entity.entityType__r.serviceTerritory__c && !serviceTerritoryAlreadyExist) {
                    ServiceTerritory newServiceTerritory = new ServiceTerritory(Name = stNameForCreation, 
                                                                                Street = entity.BillingStreet,
                                                                                PostalCode = entity.BillingPostalCode,
                                                                                City = entity.BillingCity,
                                                                                Country = entity.BillingCountry,
                                                                                Latitude = entity.Localisation__Latitude__s,
                                                                                Longitude = entity.Localisation__Longitude__s,
                                                                                KparKReference__c = entity.KparKReference__c, 
                                                                                OwnerId = System.Label.system_id_user_kpark);
                    if(!opHoursList.isEmpty()) {
                        newServiceTerritory.OperatingHoursId = opHoursList[0].Id;
                    }
                    System.debug('## newServiceTerritory: ' + newServiceTerritory);
                    serviceTerritoryToInsert.add(newServiceTerritory);
                }
                entitiesToUpdate.add(entity);
            }
            
            // Création des enregistrement et mise à jour des entités
            Map<String, String> publicAPINameIdMap = new Map<String, String>();
            Map<String, String> queuePublicGroupMap = new Map<String, String>();
            if(!publicGroupToInsert.isEmpty()) {
                Database.upsert(publicGroupToInsert, true);
                for(Group publicGroup : publicGroupToInsert) {
                    for (Account entity : entities) {
                        // Vérification
                        String nameAPIForCreation = apiNameList.get(entity.Id); 
                        if(publicGroup.DeveloperName == nameAPIForCreation ) {
                            entity.publicGroupId__c = publicGroup.Id;
                            System.debug('## Role - MAJ Public Group : ' + entity.Id+' - '+publicGroup.Id);
                            publicAPINameIdMap.put(nameAPIForCreation, publicGroup.Id); // Construction map des ID des groupes public
                            break;
                        }
                    }
                }
            }
            if(!queuesToInsert.isEmpty()) {
                Database.upsert(queuesToInsert, true);
                for(Group queue : queuesToInsert) {
                    for (Account entity : entities) {
                        // Vérification Queue
                        String nameAPIForCreation = apiNameList.get(entity.Id); 
                        if(queue.DeveloperName == nameAPIForCreation ) {
                            entity.queueId__c = queue.Id;
                            System.debug('## Role - MAJ Queue : ' + entity.Id+' - '+queue.Id);
                            // Ajout du groupe public comme membre de la file d'attente s'il existe
                            if(publicAPINameIdMap.get(nameAPIForCreation) != null) {
                                queuePublicGroupMap.put(queue.Id, publicAPINameIdMap.get(nameAPIForCreation)); // Construction map des ID des groupes public
                            }
                        }
                        // Vérification App Queue
                        String nameAPIAppQueueForCreation = apiAppQueueNameList.get(entity.Id); 
                        if(queue.DeveloperName == nameAPIAppQueueForCreation ) {
                            entity.approvalQueueId__c = queue.Id;
                        }
                    }
                }
            }
            if(!chatterGroupToInsert.isEmpty()) {
                Database.upsert(chatterGroupToInsert, true);
                for(CollaborationGroup chatterGroup : chatterGroupToInsert) {
                    for (Account entity : entities) {
                        // Vérification
                        String nameForCreation = groupsNameList.get(entity.Id);                        
                        if(chatterGroup.Name == nameForCreation) {
                            entity.chatterGroupId__c = chatterGroup.Id;
                            System.debug('## Role - MAJ Chatter Group : ' + entity.Id+' - '+chatterGroup.Id);
                            break;
                        }
                    }
                }
            }
            if(!serviceTerritoryToInsert.isEmpty()) {
                Database.upsert(serviceTerritoryToInsert, true);
                for(ServiceTerritory serviceTerritory : serviceTerritoryToInsert) {
                    for (Account entity : entities) {
                        // Vérification
                        String nameForCreation = stGroupsNameList.get(entity.Id);
                        if(serviceTerritory.Name == nameForCreation) {
                            entity.serviceTerritory__c = serviceTerritory.Id;
                            System.debug('## Role - MAJ Service Territory : ' + entity.Id+' - '+serviceTerritory.Id);
                            break;
                        }
                    }
                }
            }
            if(!rolesToUpdate.isEmpty()) {
                for(UserRole usrRole : rolesToUpdate) {
                    for (Account entity : entities) {
                        // Vérification
                        String nameAPIForCreation = roleApiNameList.get(entity.Id);
                        if(usrRole.DeveloperName == nameAPIForCreation) {
                            entity.userRoleDevName__c = usrRole.DeveloperName;
                            System.debug('## Role - MAJ entité : ' + entity.Id+' - '+usrRole.Id);
                            break;
                        }
                    }
                }
            }
            if(!rolesMapToInsert.isEmpty()) {
                for (String entityId : rolesMapToInsert.keySet()) {
                    for (Account entity : entities) {
                        // Vérification
                        if(entity.Id == entityId) {
                            String roleApiName = rolesMapToInsert.get(entityId);
                            entity.userRoleDevName__c = roleApiName;
                            System.debug('## Role - MAJ entité : ' + entity.Id+' - '+roleApiName);
                            break;
                        }
                    }
                }
            }

            // Création des membres des queues en asynchrone
            if(!queuePublicGroupMap.isEmpty()) {
                createQueueMembers(queuePublicGroupMap);
            }
            // Création des roles en asynchrone
            if(!rolesMapToInsert.isEmpty()) {
                createUserRoles(rolesMapToInsert);
            }
            // Mise à jour des entités
            if(!entitiesToUpdate.isEmpty()) {
                update entitiesToUpdate;
            }
            System.debug('### FIN TR022_Account.createEntityRecords');
        } catch(exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Méthode pour créer les membres des files d'attente en asynchrone (afin d'éviter l'erreur MixedDMLOperation)
    * @param queuePublicGroupMap Map des Id de la queue et du groupe public
    */
    @future
    public static void createQueueMembers(Map<String, String> queuePublicGroupMap) {
        System.debug('### DEBUT TR022_Account.createQueueMembers');
        List<GroupMember> queueMembersToInsert = new List<GroupMember>();

        for(String queueId : queuePublicGroupMap.keySet()) {
            GroupMember queueMember = new GroupMember();
            queueMember.UserOrGroupId = queuePublicGroupMap.get(queueId);
            queueMember.GroupId = queueId;
            queueMembersToInsert.add(queueMember);
        }
        // Ajout des membres des files d'attente             
        if(!queueMembersToInsert.isEmpty()) {
            Database.insert(queueMembersToInsert, true);
        }
        System.debug('### FIN TR022_Account.createQueueMembers');
    }

    /**
    * @description Méthode pour créer les roles en asynchrone (afin d'éviter l'erreur MixedDMLOperation)
    * @param mapRoleToInsert Collection ayant pour Key l'ID des entités et comme valeurs le nom API des roles à créer
    */
    @future
    public static void createUserRoles(Map<String, String> mapRoleToInsert) {
        System.debug('### DEBUT TR022_Account.createUserRoles');
        List<UserRole> rolesToInsert = new List<UserRole>();
        List<String> parentRoleName = new List<String>();
        Map<String, String> parentRoleMap = new Map<String, String>();

        // SOQL - Récupération des infos d'entité
        List<Account> entities = [SELECT Id, Name, KparKReference__c, entityType__c, ParentId, Parent.userRoleDevName__c, userRoleDevName__c,
                                    entityType__r.userRole__c, entityType__r.KparKReference__c FROM Account WHERE Id IN :mapRoleToInsert.keySet()];
        
        // SOQL - Récupération des roles parents
        for(Account ent : entities) {
            if(String.isNotBlank(ent.ParentId) && String.isNotBlank(ent.Parent.userRoleDevName__c)) {
                parentRoleName.add(ent.Parent.userRoleDevName__c);
            }
        }
        if(!parentRoleName.isEmpty()) {
            for(UserRole role : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :parentRoleName]) {
                parentRoleMap.put(role.DeveloperName, role.Id);
            }
        }
        
        // Pour chaque entités, on créé les enregistrements liés
        for (Account entity : entities) {
            String roleNameAPIForCreation = mapRoleToInsert.get(entity.Id);
            String roleNameForCreation = entity.KparKReference__c+' - '+entity.entityType__r.KparKReference__c+' - '+entity.Name;
            UserRole newRole = new UserRole(Name=roleNameForCreation, 
                                            DeveloperName = roleNameAPIForCreation, 
                                            CaseAccessForAccountOwner = 'Edit',
                                            OpportunityAccessForAccountOwner = 'Edit',
                                            ParentRoleId = parentRoleMap.get(entity.Parent.userRoleDevName__c),
                                            RollupDescription = roleNameForCreation
                                            );
            System.debug('## newRole: ' + newRole);
            rolesToInsert.add(newRole);
        }

        // Création des roles et maj des entités
        if(!rolesToInsert.isEmpty()) {
            Database.insert(rolesToInsert, true);
        }

        System.debug('### FIN TR022_Account.createUserRoles');
    }

    /**
    * @description Méthode pour mettre à jour les files d'attente, groupes et territoire
    * @param newEntities Liste des entités
    */
    public static void updateEntityRecords(List<Account> newEntities) {
        System.debug('### DEBUT TR022_Account.updateEntityRecords');
        
        List<Group> queuesToUp = new List<Group>();
        List<UserRole> rolesToUp = new List<UserRole>();
        List<CollaborationGroup> chatterGroupToUp = new List<CollaborationGroup>();
        List<Group> publicGroupToUp = new List<Group>();
        List<ServiceTerritory> serviceTerritoryToUp = new List<ServiceTerritory>();
        List<String> entityTypeId = new List<String>();
        Map<String, Referencial__c> entityTypeName = new Map<String, Referencial__c>();
        List<String> roleDevName = new List<String>();
        Map<String, String> roleMap = new Map<String, String>();
        
        // Récupération du nom du type d'entité
        for(Account ent : newEntities) {
            if(String.isNotBlank(ent.entityType__c)) {
                entityTypeId.add(ent.entityType__c);
            }
        }

        // SOQL - Récupération du nom du type d'entité
        for(Referencial__c ref : [SELECT Id, Name, KparKReference__c FROM Referencial__c WHERE Id IN :entityTypeId]) {
            entityTypeName.put(ref.Id, ref);
        }
        // SOQL - Récupération des roles 
        /*
        for(Account ent : newEntities) {
            if(String.isNotBlank(ent.userRoleDevName__c)) {
                roleDevName.add(ent.userRoleDevName__c);
            }
        }
        if(!roleDevName.isEmpty()) {
            for(UserRole role : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :roleDevName]) {
                roleMap.put(role.DeveloperName, role.Id);
            }
        }
        */
        
        // Pour chaque entités, on modifie les enregistrements liés
        for (Account entity : newEntities) {
            System.debug('## Entité: ' + entity.Id);
            String entTypeName = entityTypeName.get(entity.entityType__c).Name;
            String entTypeRef = entityTypeName.get(entity.entityType__c).KparKReference__c;
            String recordName = '['+entTypeName + '] ' + entity.Name;
            String groupRecordName = (recordName.length() > GROUP_NAME_MAXLENGTH) ? recordName.substring(0, GROUP_NAME_MAXLENGTH) : recordName;
            String stRecordName = (recordName.length() > 255) ? recordName.substring(0, 255) : recordName;
            String appQueueName = '[Approbation] ' + entity.Name;
            String appQueueRecordName = (appQueueName.length() > GROUP_NAME_MAXLENGTH) ? appQueueName.substring(0, GROUP_NAME_MAXLENGTH) : appQueueName;
            //String roleNameForCreation = entity.KparKReference__c+' - '+entTypeRef+' - '+entity.Name;
            System.debug('## Nom des enregistrements: ' + recordName);

            // File d'attente
            if(String.isNotBlank(entity.queueId__c)) {
                System.debug('## Queue: ' + entity.queueId__c);
                queuesToUp.add(new Group(Id=entity.queueId__c, Name=groupRecordName, Email = entity.email__c));
            }
            // File d'attente d'approbation
            if(String.isNotBlank(entity.approvalQueueId__c)) {
                System.debug('## Approval Queue: ' + entity.approvalQueueId__c);
                queuesToUp.add(new Group(Id=entity.approvalQueueId__c, Name=appQueueRecordName, Email = entity.email__c));
            }
            // Role
            /*if(String.isNotBlank(entity.userRoleDevName__c)) {
                System.debug('## Role: ' + entity.userRoleDevName__c);
                queuesToUp.add(new UserRole(Id=roleMap.get(entity.userRoleDevName__c), Name = roleNameForCreation));
            }*/
            // Groupe Chatter
            if(String.isNotBlank(entity.chatterGroupId__c)) {
                System.debug('## Chatter Group: ' + entity.chatterGroupId__c);
                chatterGroupToUp.add(new CollaborationGroup(Id=entity.chatterGroupId__c, Name=groupRecordName));
            }
            // Groupe public
            if(String.isNotBlank(entity.publicGroupId__c)) {
                System.debug('## Public Group: ' + entity.publicGroupId__c);
                publicGroupToUp.add(new Group(Id=entity.publicGroupId__c, Name=groupRecordName));
            }
            // Territoire de service
            if(String.isNotBlank(entity.serviceTerritory__c)) {
                System.debug('## Service Territory: ' + entity.serviceTerritory__c);
                System.debug('## stRecordName: ' + stRecordName);
                serviceTerritoryToUp.add(new ServiceTerritory(Id= entity.serviceTerritory__c, 
                                                                Name=stRecordName,
                                                                Street = entity.BillingStreet,
                                                                PostalCode = entity.BillingPostalCode,
                                                                City = entity.Billingcity,
                                                                Country = entity.BillingCountry,
                                                                Latitude = entity.Localisation__Latitude__s,
                                                                Longitude = entity.Localisation__Longitude__s,
                                                                IsActive = entity.isActive__c));
            }
        }
        
        // Mise à jour des enregistrements
        if(!queuesToUp.isEmpty()) {
            Database.update(queuesToUp, false);
        }        
        if(!chatterGroupToUp.isEmpty()) {
            Database.update(chatterGroupToUp, false);
        }
        if(!publicGroupToUp.isEmpty()) {
            Database.update(publicGroupToUp, false);
        }
        if(!serviceTerritoryToUp.isEmpty()) {
            Database.update(serviceTerritoryToUp, true);
        }
        System.debug('### FIN TR022_Account.updateEntityRecords');
    }

    /**
    * @description Supression des enregistrements enfant si une entité est supprimée.
    * @param accList Liste des comptes supprimées
    */
    public static void processDeleteEntity(List<Account> accList) {
        if (!Trigger.isExecuting)
            return;

        System.debug('### DEBUT TR022_Account.processDeleteEntity');

        List<Account> entityList = new List<Account>();
        List<String> queueIdList = new List<String>();
        List<String> chatterGroupIdList = new List<String>();
        List<String> publicGroupIdList = new List<String>();
        List<String> serviceTerritoryIdList = new List<String>();
        Id accEntityRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

        // Get only Entities
        for(Account acc : accList){
            if(acc.RecordTypeId == accEntityRTId){
                entityList.add(acc);
            }
        }

        // Sauvegarde
        Savepoint sp = Database.setSavepoint();
        
        try {
            if(!entityList.isEmpty()) {
                // Get Records Id
                for(Account ent : entityList){
                    if(String.isNotBlank(ent.queueId__c)) {
                        queueIdList.add(ent.queueId__c);
                        System.debug('## Queue: ' + ent.queueId__c);
                    }
                    if(String.isNotBlank(ent.approvalQueueId__c)) {
                        queueIdList.add(ent.approvalQueueId__c);
                        System.debug('## Approval Queue: ' + ent.approvalQueueId__c);
                    }
                    if(String.isNotBlank(ent.chatterGroupId__c)) {
                        chatterGroupIdList.add(ent.chatterGroupId__c);
                        System.debug('## Chatter Group: ' + ent.chatterGroupId__c);
                    }
                    if(String.isNotBlank(ent.publicGroupId__c)) {
                        publicGroupIdList.add(ent.publicGroupId__c);
                        System.debug('## Public Group: ' + ent.publicGroupId__c);
                    }
                    if(String.isNotBlank(ent.serviceTerritory__c)) {
                        serviceTerritoryIdList.add(ent.serviceTerritory__c);
                        System.debug('## Service Territory: ' + ent.serviceTerritory__c);
                    }
                }
                // Get group/queues and group/regular
                List<Group> groupList = [SELECT Id FROM Group WHERE Id IN :queueIdList OR Id IN :publicGroupIdList];
                // Get chatter groups
                List<CollaborationGroup> chatterGroupList = [SELECT Id FROM CollaborationGroup WHERE Id IN :chatterGroupIdList];
                // Get service territories
                List<ServiceTerritory> serviceTerritoryList = [SELECT Id FROM ServiceTerritory WHERE Id IN :serviceTerritoryIdList];

                // Delete
                if(!groupList.isEmpty()) {
                    System.debug('## Group: ' + groupList);
                    Database.delete(groupList, false);
                }
                if(!chatterGroupList.isEmpty()) {
                    System.debug('## Chatter Group: ' + chatterGroupList);
                    Database.delete(chatterGroupList, false);
                }
                if(!serviceTerritoryList.isEmpty()) {
                    System.debug('## Service Territory: ' + serviceTerritoryList);
                    Database.delete(serviceTerritoryList, false);
                }
            }     
            System.debug('### FIN TR022_Account.processDeleteEntity');       
        } catch(exception e) {
            // Rollback
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

}