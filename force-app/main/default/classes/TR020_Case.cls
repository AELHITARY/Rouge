//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Case
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/04/2023
//-- Version     : 1.9
//-- * 1.10 - Correction de la priorité de la responsabilité client sur les NCP internes
//-- * 1.9 - Correction de la 1.8 pour utiliser rootAsset plutôt qu'asset
//-- * 1.8 - La responsabilité client redevient prioritaire sur le type ECI dans le calcul de type pour les NCP Internes
//-- * 1.7 - Utilisation du champ afterSalesServiceReferenceDate__c au lieu de InstallDate pour le  calcul de type pour les NCP Internes
//-- * 1.6 - Modification du calcul de type pour les NCP Internes
//-- * 1.5 - Ajout gestion NCP
//-- * 1.4 - Mise à jour avec l'utilisation du référentiel
//-- * 1.3 - KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- * 1.2 - Modification pour utilisation de TerritoryUtils pour Email DR
//-- * 1.1 - CRM-956 : Ajout affectation de l'autorisation + Statut + Jalons
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Case {
    private static final String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
    private static final String RT_RELATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RELATIONCLIENT_RT);
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);
    private static final String RT_RDV_COMMERCIAL = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final String RT_RDV_PROSPECTION = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
    private static final String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    
    /**
    * @description Règle de validation
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        List<String> orderItemIdList = new List<String>();
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
        
        System.debug('### DEBUT TR020_Case.applyValidationRules');
        for (Case c : (List<Case>)Trigger.New){
            if(c.providerOrderItem__c != null){
                orderItemIdList.add(c.providerOrderItem__c);
            }
        }

        if(!orderItemIdList.isEmpty()) {
            orderItemMap = New Map<Id, OrderItem>([SELECT Id,productCode__c FROM OrderItem WHERE Id IN :orderItemIdList]);
        }

        if(Trigger.isDelete) {
            for(Case oldCase : oldCases.values()){
                // Ne pas supprimer si pas admin
                if(userContext.getProfile().Name != Constants.PROFIL_ADMIN_SystemE && userContext != null){
                    oldCase.addError(Label.case_msg_DeleteAdminOnly);
                }  
                // Ne pas supprimer si l'asset ou la commande est verrouillé
                if(oldCase.isAssetLocked__c && Trigger.isDelete && Trigger.isBefore){
                    oldCase.addError(Label.asset_msg_cantDeleteCase);
                }
            }
        }

        if(Trigger.isInsert || Trigger.isUpdate){
            for (Case newCase : (List<Case>)Trigger.New){
                // VR actif obligatoire pour les non conformités produit
                OrderItem LDC = orderItemMap.get(newCase.providerOrderItem__c);

                if( 
                    (newCase.recordTypeId == RT_PNC_INTERNALID || 
                    (newCase.recordTypeId == RT_PNC_PROVIDERID && (LDC == null || (LDC != null &&
                    LDC.productCode__c != 'REPRISE_GC')))
                    ) 
                    &&
                    ((String.isBlank(newCase.AssetId) && newCase.isLegacy__c == false) ||
                    (oldCases != null && !oldCases.isEmpty() && oldCases.get(newCase.Id) != null && !String.isBlank(oldCases.get(newCase.Id).AssetId) && String.isBlank(newCase.AssetId) && newCase.isLegacy__c == true)
                    )
                  )
                {
                    newCase.addError('Actif obligatoire pour les non-conformités produit!');
                }
            }
        }
        

        System.debug('### FIN TR020_Case.applyValidationRules');
    }

    /**
    * @description Fonctions pour faire appels aux MAJ des champs et des status
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
          
        System.debug('### DEBUT TR020_Case.applyDataUpdateRules');
        List<Case> newCases = (List<Case>)Trigger.new;  
        List<Case> listCaseChildToInsert = new List<Case>();
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;     
        Map<Id, Account> accounts = new Map<Id, Account>();     
        Map<Id, Account> providers = new Map<Id, Account>(); 
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();
        Map<Id, Asset> assets = new Map<Id, Asset>();
        Map<Id, Order> orders = new Map<Id, Order>();
        Map<Id, Entitlement> autorisations = new Map<Id, Entitlement>();
        Map<String, String> mapRVChantier = new Map<String, String>();
        Map<String, String> mapRVAccount = new Map<String, String>();
        Map<Id, Event> evtAccChantier = new Map<Id, Event>();
        Set<ID> accountIds = new Set<ID>();
        Set<ID> contactIds = new Set<ID>();
        Set<ID> chantierIds = new Set<ID>();
        Set<ID> accChanIds= new Set<ID>();
        Set<ID> orderIds = new Set<ID>();
        Set<ID> assetIds = new Set<ID>();
        Set<ID> providerIds = new Set<ID>();
      
        //** A - Initialisation des données intermédiaires 
        // Recherche des utilisateurs 
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Name, ManagerId, UserRole.Name, codeMagasin__c, codeDV__c, codeDR__c
                                                   FROM User
                                                   WHERE IsActive = TRUE
                                                     AND (UserRole.Name LIKE '% - DR - %' OR UserRole.Name LIKE '% - DV - %' 
                                                            OR UserRole.Name LIKE '% - REF - %' OR UserRole.Name LIKE '% - MAG - %')
                                                   ORDER BY CreatedDate]);

        // Recherche des comptes, caseChas et autorisations associées 
        for (Case newCase : newCases) {
            if (newCase.AccountId != null) {
                accountIds.add(newCase.AccountId);
                accChanIds.add(newCase.AccountId);
            }
            if (newCase.ContactId != null) {
                contactIds.add(newCase.ContactId);
            }
            if (newCase.chantier__c != null) {
                chantierIds.add(newCase.chantier__c);
                accChanIds.add(newCase.chantier__c);
            }
            if (newCase.customerOrder__c != null) {
                orderIds.add(newCase.customerOrder__c);
            }
            if (newCase.AssetId != null) {
                assetIds.add(newCase.AssetId);
            }
            if (newCase.provider__c != null) {
                providerIds.add(newCase.provider__c);
            }
        }
        System.debug('## accountIds: '+accountIds);
        System.debug('## contactIds: '+contactIds);
        System.debug('## chantierIds: '+chantierIds);
        
        // Récupération des contacts
        if(!contactIds.isEmpty()) {
            contacts = new Map<Id, Contact>([SELECT Id, Name, AccountId, Email, Phone, MobilePhone, HomePhone FROM Contact WHERE id IN :contactIds]);
            for (Contact cot : contacts.values()) {
                accountIds.add(cot.AccountId);
            }
        }
        // Récupération des comptes et autorisations
        if(!accountIds.isEmpty()) {
            accounts = new Map<Id, Account>([SELECT Id, Name, codeMagasinActuel__c, codeDVActuel__c, codeRegionActuel__c, RecordTypeId, RecordType.DeveloperName,
                                                    contactParDefaut__c, contactParDefaut__r.Email, billingServiceEntity__c, billingSalesEntity__c,
                                                    personServiceEntity__pc, personSalesEntity__pc, IsPersonAccount
                                                FROM Account WHERE id IN :accountIds]);
            String rtCaseEntitlement = DAL.getRecordTypeIdByDevName('Entitlement', 'CaseEntitlement');
            autorisations = new Map<Id, Entitlement>([SELECT Id, AccountId, Type FROM Entitlement WHERE AccountId IN :accountIds AND Status='Active' AND RecordTypeId = :rtCaseEntitlement]);
        }
        // Récupération des fournisseurs
        if(!providerIds.isEmpty()) {
            providers = new Map<Id, Account>([SELECT Id, Name, emailPro__c, PNCValidationDelay__c, contactParDefaut__c, contactParDefaut__r.Email
                                                FROM Account WHERE id IN :providerIds]);
        }
        // Récupération des assets
        if(!assetIds.isEmpty()) {
            assets  = new Map<Id, Asset>([SELECT Id, customerOrder__c, orderItem__c, orderItem__r.Order.RecordType.DeveloperName, Product2Id, IsInternal,
                                            AccountId, ContactId, chantier__c, 
                                            PurchaseDate, InstallDate, UsageEndDate, IsCompetitorProduct, afterSalesServiceReferenceDate__c,
                                            RootAsset.customerOrder__c, RootAsset.PurchaseDate, RootAsset.InstallDate, RootAsset.UsageEndDate, RootAsset.IsCompetitorProduct, RootAsset.afterSalesServiceReferenceDate__c
                                            FROM Asset WHERE id IN :assetIds]);
            for (Asset ast : assets.values()) {
                orderIds.add(ast.customerOrder__c);
            }
        }
        // Récupération des des commandes
        if(!orderIds.isEmpty()) {
            orders = new Map<Id, Order>([SELECT Id, serviceEntity__c, salesEntity__c, Status FROM Order WHERE Id IN :orderIds]);
        }
        // Récupération du chantier et des RV             
        System.debug('## accChanIds: '+accChanIds);
        if(!accChanIds.isEmpty()) {
            String soqlQuery = 'SELECT Id, proprietaire__c, autreProprietaire__c, locataire__c, autreLocataire__c, occupant__c, autreOccupant__c, '+
                                '    codeMagasinActuel__c, codeDVActuel__c, codeRegionActuel__c, sectorisation__r.emailDepot__c, '+
                                '    sectorisation__r.emailResponsableDepot__c,  sectorisation__r.libelleDepot__c, '+
                                '    sectorisation__r.responsableDepot__c, serviceEntity__c, salesEntity__c FROM Chantier__c';
            if(!chantierIds.isEmpty()) {
                soqlQuery += ' WHERE Id IN :chantierIds';
            } else if(!accountIds.isEmpty()) {
                soqlQuery += ' WHERE proprietaire__c IN :accountIds OR locataire__c IN :accountIds OR occupant__c IN :accountIds '+
                             '   OR autreProprietaire__c IN :accountIds OR autreLocataire__c IN :accountIds OR autreOccupant__c IN :accountIds';
            }      
            System.debug('## Chantier query: '+soqlQuery);      
            List<Chantier__c> lstChantiers = Database.query(soqlQuery);
            System.debug('## lstChantiers: '+lstChantiers); 

            // Récupération des RV
            List<User> usersRVList = new List<User>();
            for(User usr: users.values()) {
                if(usr.UserRole.Name.containsIgnoreCase('% - REF -%')) {
                    usersRVList.add(usr);
                }
            }
            for(Chantier__c chantier : lstChantiers) {
                chantiers.put(chantier.Id, chantier);
                for(User usrRV: usersRVList) {
                    if(String.isNotBlank(chantier.codeMagasinActuel__c) && usrRV.UserRole.Name.containsIgnoreCase(chantier.codeMagasinActuel__c)) {
                        mapRVChantier.put(chantier.Id, usrRV.Id);
                    } 
                }
            }
            for(Account acc : accounts.values()) {
                for(User usrRV: usersRVList) {
                    if(String.isNotBlank(acc.codeMagasinActuel__c) && usrRV.UserRole.Name.containsIgnoreCase(acc.codeMagasinActuel__c)) {
                        mapRVAccount.put(acc.Id, usrRV.Id);
                    } 
                }
            }
        }
        if((chantierIds.isEmpty() && contactIds.isEmpty()) == false) {
            evtAccChantier = new Map<Id, Event>([SELECT Id, OwnerId, Owner.Name, WhatId, WhoId FROM Event 
                                                    WHERE StartDateTime > TODAY AND (WhoId IN :contactIds OR WhatId IN :chantierIds)
                                                    AND (RecordTypeId=:RT_RDV_COMMERCIAL 
                                                    OR (RecordTypeId=:RT_RDV_PROSPECTION AND Type = :Constants.EVENT_TYPE_VISITEPOSE))]);
        }

        // Récupération des entités
        Map<Id, Account> accountsDepot  = new Map<Id, Account>();
        List<Account> mainEntities = new List<Account>();
        List<Account> callEntities = new List<Account>();
        for(Account acc : [SELECT Id, Name, PersonEmail, stageName__c, ParentId, entityType__r.Name, entityType__r.RecordType.DeveloperName, RecordTypeId
                            FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY]){
            if(acc.RecordTypeId == RT_ACC_ENTITY){
                accountsDepot.put(acc.Id, acc);
            }
            if(acc.RecordTypeId == RT_ACC_ENTITY && acc.stageName__c == 'En cours' && acc.ParentId == null){
                mainEntities.add(acc);
            }
            if(acc.RecordTypeId == RT_ACC_ENTITY && acc.stageName__c == 'En cours' && acc.entityType__r.Name == 'Call' && acc.entityType__r.RecordType.DeveloperName == 'EntityType'){
                callEntities.add(acc);
            }
        }
                           
        //** B - Application des règles de mise à jour 
        for(Case newCase : newCases){
            System.debug('## CaseId: '+newCase.Id); 
            Case oldCase = oldCases == null ? null : oldCases.get(newCase.id);
            Asset assetCase = assets.get(newCase.AssetId);
            
            if ((newCase.RecordTypeId == RT_PNC_INTERNALID || newCase.RecordTypeId == RT_PNC_PROVIDERID) && newCase.customerOrder__c == null &&
               newCase.AssetId != null && assetCase.customerOrder__c != null) {
                newCase.customerOrder__c = assetCase.customerOrder__c;
            }
            if ((newCase.RecordTypeId == RT_PNC_INTERNALID || newCase.RecordTypeId == RT_PNC_PROVIDERID) && newCase.providerOrderItem__c == null &&
               newCase.AssetId != null && assetCase.orderItem__c != null && assetCase.orderItem__r.Order.RecordType.DeveloperName == 'ProviderOrder') {
                newCase.providerOrderItem__c = assetCase.orderItem__c;
            }
            if(newCase.AssetId != null && assetCase.Product2Id != null) {
                newCase.ProductId = assetCase.Product2Id;
            }
            if ((newCase.RecordTypeId == RT_PNC_INTERNALID || newCase.RecordTypeId == RT_PNC_PROVIDERID) && newCase.chantier__c == null &&
               newCase.AssetId != null && assetCase.chantier__c != null) {
                newCase.chantier__c = assetCase.chantier__c;
            }
            if ((newCase.RecordTypeId == RT_PNC_INTERNALID || newCase.RecordTypeId == RT_PNC_PROVIDERID) && newCase.AccountId == null &&
               newCase.AssetId != null && assetCase.AccountId != null) {
                newCase.AccountId = assetCase.AccountId;
            }
            if ((newCase.RecordTypeId == RT_PNC_INTERNALID || newCase.RecordTypeId == RT_PNC_PROVIDERID) && newCase.ContactId == null &&
               newCase.AssetId != null && assetCase.ContactId != null) {
                newCase.ContactId = assetCase.ContactId;
            }

            if(newCase.RecordTypeId == RT_PNC_INTERNALID) {
                //* Calcul Type NCP Interne
                
                
                if(newCase.AssetId == null) { // Actif inconnu
                    if (newCase.responsability__c == 'Client' || newCase.detectedWarranty__c == 'Hors garantie' || newCase.detectedWarranty__c == '')
                        newCase.Type = 'SAV hors garantie';
                    else
                        newCase.Type = 'SAV garantie';
                }
                else { // Actif connu
                    if (assetCase.rootAsset.IsCompetitorProduct == true) // Actif de la concurrence -> OBLIGATOIREMENT Hors garantie
                        newCase.Type = 'SAV hors garantie';
                    else { // Actif K par K
                        Date caseDate = newCase.createdDate != null ? newCase.createdDate.date() : Date.today();
                        Integer ASSDelay = newCase.afterSalesServiceDelay__c != null ? Integer.valueOf(newCase.afterSalesServiceDelay__c) : 180;
                    
                        /* >>> F.G., le 24/03/2023 | 1.8 - La responsabilité client redevient prioritaire sur le type ECI dans le calcul de type pour les NCP Internes */
                        if (newCase.responsability__c == 'Client')
                            newCase.Type = 'SAV hors garantie';
                        /* <<< F.G., le 24/03/2023 */
                        else if (assetCase.rootAsset.afterSalesServiceReferenceDate__c == null) {
                            if (assetCase.rootAsset.customerOrder__c != null) // Actif commandé mais sans date de référence = non installé --> Toujours ECI 
                                newCase.Type = 'ECI';
                            else { // Actif non associé à une commande client
                                if (newCase.responsability__c == 'Client' || newCase.detectedWarranty__c == 'Hors garantie')
                                    newCase.Type = 'SAV hors garantie';
                                else if (newCase.detectedWarranty__c == 'Garantie')
                                    newCase.Type = 'SAV garantie';
                                else
                                    newCase.Type = 'ECI';
                            }
                        }                        
                        else if (caseDate <= assetCase.rootAsset.afterSalesServiceReferenceDate__c.addDays(ASSDelay))
                            newCase.Type = 'ECI';
                        else if (assetCase.rootAsset.UsageEndDate < caseDate || newCase.responsability__c == 'Client' || newCase.detectedWarranty__c == 'Hors garantie' || newCase.detectedWarranty__c == '')
                            newCase.Type = 'SAV hors garantie';
                        else
                            newCase.Type = 'SAV garantie';
                    }
                }

                //* Mise à jour automatique de la durée d'intervention du Case
                newCase.interventionDuration__c=newCase.totalInterventionDuration__c;
            }
            
            // Mise à jour du champ standard motif avec la valeur du champ personnalisé 
            if(oldCase == null || oldCase.motif__c != newCase.motif__c) {
                newCase.Reason = newCase.motif__c;
            }

            Chantier__c caseCha = chantiers.get(newCase.chantier__c);
            // Dans le cas d'un compte vide, assignation grâce au contact ou au chantier 
            if(newCase.AccountId == null) {
                System.debug('## ContactId: '+newCase.ContactId); 
                System.debug('## chantier__c: '+newCase.chantier__c); 
                System.debug('## caseCha: '+caseCha); 
                if(newCase.contactId != null && contacts.get(newCase.contactId).AccountId != null) {
                    newCase.AccountId = contacts.get(newCase.contactId).AccountId;
                } else if(newCase.chantier__c != null && caseCha!=null){
                    if(caseCha.proprietaire__c != null) {
                        newCase.AccountId = caseCha.proprietaire__c;
                    } else if(caseCha.autreProprietaire__c != null) {
                        newCase.AccountId = caseCha.autreProprietaire__c;
                    } else if(caseCha.locataire__c != null) {
                        newCase.AccountId = caseCha.locataire__c;
                    } else if(caseCha.autreLocataire__c != null) {
                        newCase.AccountId = caseCha.autreLocataire__c;
                    } else if(caseCha.occupant__c != null) {
                        newCase.AccountId = caseCha.occupant__c;
                    } else if(caseCha.autreOccupant__c != null) {
                        newCase.AccountId = caseCha.autreOccupant__c;
                    }
                } 
                System.debug('## AccountId: '+newCase.AccountId); 
            }
            
            // Dans le cas d'un compte B2B non-vide, alimentation des champs WEB :
            if(newCase.AccountId != null && newCase.SuppliedCompany == null && accounts.get(newCase.AccountId) != null 
                && accounts.get(newCase.AccountId).RecordType.DeveloperName == Constants.ACCOUNT_PRO_RT ) 
            {
                newCase.SuppliedCompany = accounts.get(newCase.AccountId).Name;
            }
            
            // Dans le cas d'un contact non-vide, alimentation des champs WEB :
            if(newCase.ContactId != null && contacts.get(newCase.ContactId) != null) {
                if(contacts.get(newCase.ContactId).MobilePhone != null){
                    newCase.SuppliedPhone = contacts.get(newCase.ContactId).MobilePhone;
                } else if(contacts.get(newCase.ContactId).HomePhone != null){
                    newCase.SuppliedPhone = contacts.get(newCase.ContactId).HomePhone;
                } else if(contacts.get(newCase.ContactId).Phone != null){
                    newCase.SuppliedPhone = contacts.get(newCase.ContactId).Phone;
                }
            }
            if(newCase.ContactId != null && newCase.SuppliedName == null && contacts.get(newCase.ContactId) != null) {
                newCase.SuppliedName = contacts.get(newCase.ContactId).Name;
            }
            if(newCase.ContactId != null && newCase.SuppliedEmail == null && contacts.get(newCase.ContactId) != null) {
                newCase.SuppliedEmail = contacts.get(newCase.ContactId).Email;
            } 
            
            // NON NCP - Si le contact du fournisseur n'est pas vide, on récupère son email
            if(newCase.RecordTypeId != RT_PNC_PROVIDERID && newCase.AccountId != null && accounts.get(newCase.AccountId) != null && accounts.get(newCase.AccountId).contactParDefaut__c != null) {
                newCase.supplierEmail__c = accounts.get(newCase.AccountId).contactParDefaut__r.Email;
            }
            
            // NCP - Si le contact du fournisseur n'est pas vide, on récupère son email
            if(newCase.RecordTypeId == RT_PNC_PROVIDERID && newCase.provider__c != null && providers.get(newCase.provider__c) != null) {
                if(providers.get(newCase.provider__c).contactParDefaut__r.Email != null) {
                    newCase.supplierEmail__c = providers.get(newCase.provider__c).contactParDefaut__r.Email;
                } else {
                    newCase.supplierEmail__c = providers.get(newCase.provider__c).emailPro__c;
                }
            }
            
            // Alimentation du champ entity__c
            if(newCase.serviceConcerne__c == 'Technique'){
                if(String.isNotBlank(newCase.customerOrder__c)){
                    newCase.entity__c = orders.get(newCase.customerOrder__c).serviceEntity__c;  
                } else if(String.isNotBlank(newCase.AssetId) && assetCase.customerOrder__c != null) {
                    newCase.entity__c = orders.get(assetCase.customerOrder__c).serviceEntity__c;
                } else if(String.isNotBlank(newCase.chantier__c)) {
                    newCase.entity__c = chantiers.get(newCase.Chantier__c).serviceEntity__c;
                } else if(String.isNotBlank(newCase.AccountId)) {
                    newCase.entity__c = (accounts.get(newCase.AccountId).IsPersonAccount) ? accounts.get(newCase.AccountId).personServiceEntity__pc : accounts.get(newCase.AccountId).billingServiceEntity__c;
                }
            } else if(newCase.serviceConcerne__c == 'Commercial'){
                if(String.isNotBlank(newCase.customerOrder__c)){
                    newCase.entity__c = orders.get(newCase.customerOrder__c).salesEntity__c;  
                } else if(String.isNotBlank(newCase.AssetId) && assetCase.customerOrder__c != null) {
                    newCase.entity__c = orders.get(assetCase.customerOrder__c).salesEntity__c;
                } else if(String.isNotBlank(newCase.chantier__c)) {
                    newCase.entity__c = chantiers.get(newCase.Chantier__c).salesEntity__c;
                } else if(String.isNotBlank(newCase.AccountId)) {
                    newCase.entity__c = (accounts.get(newCase.AccountId).IsPersonAccount) ? accounts.get(newCase.AccountId).personSalesEntity__pc : accounts.get(newCase.AccountId).billingSalesEntity__c;
                }
            } else if(newCase.serviceConcerne__c == 'Marketing'){
                if(!mainEntities.isEmpty()){
                    newCase.entity__c = mainEntities[0].id;
                }
            } else {
                if(!callEntities.isEmpty()){
                    newCase.entity__c = callEntities[0].id;
                }
            }
   
            //* Si la requête n'a pas de chantier à la création alors alimenter automatiquement le chantier à partir des chantiers du compte
            //* pour requêtes réclamations service ou de gestion de la relation client ou si requête provenant d'un e-mail 
            Account caseAcc = accounts.get(newCase.AccountId);
            System.debug('## Case Acc: '+caseAcc); 
            System.debug('## isReclaOrGestion: '+isReclaOrGestion(newCase)); 
            if(caseAcc != null && newCase.chantier__c == null && (isReclaOrGestion(newCase) || newCase.Origin == 'E-mail')) {
                for(Chantier__c cha : chantiers.values()) {
                    if(cha.proprietaire__c==caseAcc.Id || cha.locataire__c==caseAcc.Id || cha.occupant__c==caseAcc.Id || cha.autreProprietaire__c==caseAcc.Id || cha.autreLocataire__c==caseAcc.Id || cha.autreOccupant__c==caseAcc.Id) {
                        newCase.chantier__c = cha.Id;
                        break;
                    }
                }
                System.debug('## Chantier: '+newCase.chantier__c); 
            }

            // Cas d'un case "A cloturer" : Interdiction de cocher la case "A cloturer" si il n'existe pas de 1ère réponse du client 
            if((oldCase == null || oldCase.aCloturer__c != newCase.aCloturer__c) && newCase.aCloturer__c && 
                newCase.RecordTypeId != RT_PNC_INTERNALID && newCase.RecordTypeId != RT_PNC_PROVIDERID){
                if(newCase.datePremiereReponse__c == null){
                    newCase.addError(Label.case_msg_PremiereReponseRequired);
                }
            }
            
            // Cas où le Service Concerné de la requête passe à Commercial
            if(oldCase != null && oldCase.serviceConcerne__c != Constants.REQUETE_RDV_COMMERCIAL && newCase.serviceConcerne__c == Constants.REQUETE_RDV_COMMERCIAL) {
                if(newCase.chantier__c != null) {
                    if(!mapRVChantier.isEmpty()) {
                        newCase.OwnerId = mapRVChantier.get(newCase.chantier__c);
                    }
                    //newCase.OwnerId = RV du magasin du chantier
                } else if (newCase.AccountId != null) {
                    if(!mapRVAccount.isEmpty()) {
                        newCase.OwnerId = mapRVAccount.get(newCase.AccountId);
                    }
                }
            }
                
            caseCha = chantiers.get(newCase.chantier__c);
            // Chantier obligatoire pour requêtes réclamations service ou de gestion de la relation client : Affichage erreur si pas de chantier affecté 
            if(caseCha == null && isReclaOrGestion(newCase)) {
                newCase.addError(Label.case_msg_ChantierRequired);
            } else {   
                // Affectation autorisation 
                if(newCase.EntitlementId == null){
                    for (Entitlement ent : autorisations.values()) {
                        // Recherche autorisation lié au compte de la requête
                        if(ent.AccountId==newCase.AccountId) {
                            if (ent.Type.containsIgnoreCase('réclamation') && newCase.RecordTypeId==RT_RECLAMATIONID) {
                                newCase.EntitlementId=ent.Id;
                                break;
                            } else if (ent.Type.containsIgnoreCase('relation') && newCase.RecordTypeId==RT_RELATIONID) {
                                newCase.EntitlementId=ent.Id;
                                break;
                            }
                        }
                    }
                    System.debug('## Autorisation: '+newCase.EntitlementId);
                }   

                // Association des champs email dépot avec la sectorisation du chantier 
                if((Trigger.isInsert || (oldCase != null && newCase.entity__c != oldCase.entity__c)) && newCase.entity__c != null && caseCha != null) {
                    if(String.isNotBlank(newCase.entity__r.emailPro__c)) {
                        newCase.emailDepot__c = newCase.entity__r.emailPro__c;
                    } if(String.isNotBlank(caseCha.sectorisation__r.emailResponsableDepot__c)) {
                        newCase.emailResponsableDepot__c = caseCha.sectorisation__r.emailResponsableDepot__c;
                    } 
                    if(String.isBlank(caseCha.sectorisation__r.emailDepot__c) && String.isBlank(caseCha.sectorisation__r.emailResponsableDepot__c) 
                        && String.isNotBlank(caseCha.sectorisation__r.libelleDepot__c)){
                        for(Account depotAcc : accountsDepot.values()){
                            if(depotAcc.Name.contains(caseCha.sectorisation__r.libelleDepot__c)) {
                                newCase.emailDepot__c = depotAcc.PersonEmail;
                                break;
                            }
                        }
                    }
                    System.debug('## Email depot: '+newCase.emailDepot__c);
                    System.debug('## Email responsable depot: '+newCase.emailResponsableDepot__c);
                }

                // Process                
                if (Trigger.isUpdate && newCase.RecordTypeId != RT_PNC_INTERNALID && newCase.RecordTypeId != RT_PNC_PROVIDERID) {
                    System.debug('## isUpdate');  
                    // Affectation des managers si changement de propriétaire 
                    if (newCase.ownerId != null && oldCase != null && newCase.ownerId != oldCase.ownerId) {
                        newCase.utilisateurN__c = null;
                        newCase.utilisateurN1__c = null;
                        newCase.utilisateurN2__c = null;        
                        // Affectation des managers
                        User user = users.get(newCase.ownerId);
                        if (user != null) {
                            affectationManagers(newCase,users,user);
                        }
                        System.debug('## Utilisateur N: '+newCase.utilisateurN__c);
                        System.debug('## Utilisateur N1: '+newCase.utilisateurN1__c);
                        System.debug('## Utilisateur N2: '+newCase.utilisateurN2__c);
                    }
                } else if (Trigger.isInsert && newCase.RecordTypeId != RT_PNC_INTERNALID && newCase.RecordTypeId != RT_PNC_PROVIDERID) {
                    System.debug('## isInsert'); 
                    /* Traitement des statuts */
                    newCase.Status = Constants.REQUETE_STATUS_NEW;
                    /* Association Email DR */                    
                    User drUser = null;
                    if(caseCha != null && String.isNotBlank(caseCha.codeRegionActuel__c)) {
                        drUser = TerritoryUtils.getManager(caseCha.codeRegionActuel__c);                        
                    } 
                    if(drUser == null && caseAcc != null && String.isNotBlank(caseAcc.codeRegionActuel__c)) {
                        drUser = TerritoryUtils.getManager(caseAcc.codeRegionActuel__c);
                    }
                    if(drUser!=null && String.isNotBlank(drUser.Email))
                        newCase.emailDR__c = drUser.Email;

                    /* Si insertion alors recherche du référant du magasin */  
                    Map<String, User> usersParEntite = new Map<String, User>();
                    Map<String, User> usersParName = new Map<String, User>();
                    for (User user : users.values()) {
                        String[] items = user.userRole.name.split(' - ');
                        if ('REF'.equalsIgnoreCase(items[1]) || 'DV'.equalsIgnoreCase(items[1]) || 'DR'.equalsIgnoreCase(items[1])) {
                            String code = items[0].trim().toUpperCase();                            
                            usersParName.put(user.Name, user);
                            if (!usersParEntite.containsKey(code))
                                usersParEntite.put(code, user);
                        }
                    }
                    /* Affectation des utilisateurs par entîté */
                    User user = null;            
                    if (newCase.chantier__c != null) {
                        if(usersParEntite != null && caseCha != null) { 
                            user = usersParEntite.get(caseCha.codeMagasinActuel__c);
                            if (user == null)
                                user = usersParEntite.get(caseCha.codeDVActuel__c);
                            if (user == null)
                                user = usersParEntite.get(caseCha.codeRegionActuel__c);
                        }
                    }
                    else if (newCase.AccountId != null) {
                        if(usersParEntite != null && caseAcc != null) {
                            user = usersParEntite.get(caseAcc.codeMagasinActuel__c);
                            if (user == null)
                                user = usersParEntite.get(caseAcc.codeDVActuel__c);
                            if (user == null)
                                user = usersParEntite.get(caseAcc.codeRegionActuel__c);
                        }
                    } 
                    // Affectation du RV du chantier comme propriétaire
                    if (user != null && (newCase.Type == Constants.REQUETE_ANNULATION_CONTRAT || 
                                            newCase.Type == Constants.REQUETE_RECLAMATION_COMMERCIALE ||
                                                (newCase.typeDeRendezVous__c == Constants.REQUETE_RDV_COMMERCIAL && 
                                                    (newCase.Type == Constants.REQUETE_NOUVEAU_RDV ||
                                                    newCase.Type == Constants.REQUETE_MODIF_RDV ||
                                                    newCase.Type == Constants.REQUETE_ANNULATION_RDV ||
                                                    newCase.Type == Constants.REQUETE_DEMANDE_INFO)))) {
                        /* Pour commerciale, recherche des RDV commerciaux ou de visite de pose du chantier (sinon du compte) dans le futur */
                        if(newCase.typeDeRendezVous__c == Constants.REQUETE_RDV_COMMERCIAL && 
                                (newCase.Type == Constants.REQUETE_MODIF_RDV ||
                                newCase.Type == Constants.REQUETE_ANNULATION_RDV ||
                                newCase.Type == Constants.REQUETE_DEMANDE_INFO)) {
                            List<Event> evtList = new List<Event>();
                            for (Event evt : evtAccChantier.values()) {
                                if(evt.WhoId==newCase.ContactId || evt.WhatId==newCase.chantier__c)
                                    evtList.add(evt);
                            }
                            /* Si un seul RDV trouvé, alors le vendeur du RDV est associé à la requête, sinon le RV du chantier (du compte si pas de chantier) */
                            if(evtList.size()==1) {
                                User usr = usersParName.get(evtList[0].Owner.Name);
                                if(usr != null) user = usersParName.get(evtList[0].Owner.Name);                         
                            }
                        }
                        System.debug('## Owner: '+user.Id+' - '+user.Name);
                        newCase.OwnerId = user.Id; 
                        /* Affectation des managers */
                        affectationManagers(newCase,users,user);
                    }
                    // Affectation du responsable dépot du chantier comme propriétaire
                    else if(user != null && isReclaOrGestion(newCase)){
                        // TODO
                        if(caseCha != null && caseCha.sectorisation__c != null && String.isNotBlank(caseCha.sectorisation__r.responsableDepot__c)){
                            User repDep = usersParName.get(caseCha.sectorisation__r.responsableDepot__c);
                            if(repDep != null) {
                                newCase.OwnerId = repDep.Id;                                            
                                //* Affectation des managers 
                                affectationManagers(newCase,users,repDep);
                            }
                        }
                    }
                    System.debug('## Utilisateur N: '+newCase.utilisateurN__c);
                    System.debug('## Utilisateur N1: '+newCase.utilisateurN1__c);
                    System.debug('## Utilisateur N2: '+newCase.utilisateurN2__c);
                }
            }

        }
        
        /*if(!listCaseChildToInsert.isEmpty()) {
            System.debug('## listCaseChildToInsert.status : ' + listCaseChildToInsert[0].Status);
            insert listCaseChildToInsert;
        }*/
        
        System.debug('### FIN TR020_Case.applyDataUpdateRules');
    }

    /**
    * @description Règle de mise à jour du statut des différents type de requête
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Case : applyStatusUpdateRules');
        
        /** A - Initialisation des données intermédiaires **/
        List<Case> newCases = (List<Case>)Trigger.new;
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        Set<Id> caseFIds = new Set<Id>();
        Set<Id> casePNCId = new Set<Id>();
        List<Order> providerOrdersList = new List<Order>();
        Map<String,List<EmailMessage>> mapCaseEmailMessage = new Map<String,List<EmailMessage>>();

        // Recherche des jalons associés qui n'ont pas été validés 
        Map<String, List<CaseMilestone>> caseCMMAP = new Map<String, List<CaseMilestone>>();
        List<CaseMilestone> cmList = [SELECT Id, CaseId FROM CaseMilestone WHERE CaseId IN :newCases and IsViolated = true]; 
        // Mapping des jalons avec les requêtes
        for(Case newCase : newCases){
            if(newCase.RecordTypeId == RT_PNC_PROVIDERID && String.isNotBlank(newCase.Id)) {
                caseFIds.add(newCase.Id);
            } else if(newCase.RecordTypeId == RT_PNC_INTERNALID && String.isNotBlank(newCase.Id)){
                casePNCId.add(newCase.Id);
            }
            List<CaseMilestone> cmFromCase = new List<CaseMilestone>();
            for(CaseMilestone cm : cmList){
                if(newCase.Id == cm.caseId) {
                    cmFromCase.add(cm);
                }
            }
            caseCMMAP.put(newCase.Id, cmFromCase);
        }
        
        //Récuperation des email lié aux Cases
        // On récupère les EmailMessage des Cases s'il y en a
        if(!caseFIds.isEmpty()) {
            // On met dans une Map, Id order => Liste d'Actif
            for(EmailMessage em : [SELECT Id, ParentId, FromAddress, CreatedDate FROM EmailMessage WHERE ParentId IN: caseFIds]) {
                List<EmailMessage> emAllList = mapCaseEmailMessage.get(em.ParentId);
                if(emAllList == null) {
                    emAllList = new List<EmailMessage>();
                }
                emAllList.add(em);
                mapCaseEmailMessage.put(em.ParentId, emAllList);
            }
        }

        //Récuperation des commandes fournisseurs liées à la NCP Interne
        if(!casePNCId.isEmpty()) {
            providerOrdersList = new List<Order>([SELECT Id, Status, productNonCompliance__c, transmissionDate__c, confirmationDate__c, deliveryDate__c 
                                                    FROM Order WHERE productNonCompliance__c IN :casePNCId]);
        }
        
        // B - Application des règles de mise à jour 
        for (Case newCase : newCases) {
            Case oldCase = oldCases == null ? null : oldCases.get(newCase.id); 
            System.debug('## Case Id: '+newCase.Id);
            System.debug('## Case RecordTypeId: '+newCase.RecordTypeId);

            // Traitement des statuts des requêtes clients
            if (newCase.RecordTypeId != RT_PNC_INTERNALID && newCase.RecordTypeId != RT_PNC_PROVIDERID) {
                if(Trigger.isUpdate && oldCase != null) {
                    if(oldCase.Status == Constants.REQUETE_STATUS_CLOSED && newCase.Status != Constants.REQUETE_STATUS_CLOSED)
                        newCase.aCloturer__c = false;
                }
                if(newCase.Status == Constants.REQUETE_STATUS_CLOSED || newCase.aCloturer__c) {
                    newCase.Status = newCase.Status;
                    newCase.stageName__c = Constants.REQUETE_STEP_CLOSED;
                } else if(newCase.datePremiereReponse__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_INPROGRESS;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(caseCMMAP.get(newCase.Id) != null && caseCMMAP.get(newCase.Id).size() == 1) {
                    newCase.Status = Constants.REQUETE_STATUS_J1_RETARD;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                } else if(caseCMMAP.get(newCase.Id) != null && caseCMMAP.get(newCase.Id).size() == 2) {
                    newCase.Status = Constants.REQUETE_STATUS_J2_ENGAGEMENT;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                } else {
                    newCase.Status = Constants.REQUETE_STATUS_NEW;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                }
                
            // Traitement des statuts des requêtes NCP FOURNISSEUR
            } else if (newCase.RecordTypeId == RT_PNC_PROVIDERID) {
                // Traitement des dernière réponses
                Datetime lastDateKPARK = Datetime.newInstance(1960, 2, 19);
                Datetime lastDateProvider = Datetime.newInstance(1960, 2, 19);
                List<EmailMessage> emList = new List<EmailMessage>();
                if(mapCaseEmailMessage.get(newCase.Id) != null) {
                    emList = mapCaseEmailMessage.get(newCase.Id);
                }
                
                if(emList != null) {
                    for(EmailMessage em : emList) {
                        System.debug('###### TEST1 : ');
                        if(em.FromAddress == null && em.CreatedDate > lastDateKPARK) {
                            System.debug('###### TEST1 : ');
                            lastDateKPARK = em.CreatedDate;
                        }
                        if(em.FromAddress != null) {
                            System.debug('###### TEST2 : ');
                            if((em.FromAddress.contains('kpark') || em.FromAddress == '') && em.CreatedDate > lastDateKPARK) {
                                lastDateKPARK = em.CreatedDate;
                            }
                            if(em.FromAddress == newCase.supplierEmail__c && em.CreatedDate > lastDateProvider) {
                                lastDateProvider = em.CreatedDate;
                            }
                        }
                    }
                }
                System.debug('###### lastDateKPARK : ' + lastDateKPARK);
                System.debug('###### lastDateProvider : ' + lastDateProvider);
                
                if(newCase.cancellingDate__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_CANCELLED;
                    newCase.stageName__c = Constants.REQUETE_STEP_CLOSED;
                } else if(newCase.Status == Constants.REQUETE_STATUS_CLOSED || newCase.processingEndDate__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_CLOSED;
                    newCase.stageName__c = Constants.REQUETE_STEP_CLOSED;
                } else if(newCase.invoicedDate__c != null && newCase.invoicedAmount__c > 0) {
                    newCase.Status = Constants.REQUETE_STATUS_INVOICED;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(newCase.conciliationDate__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_CONCILIATION;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(lastDateProvider < lastDateKPARK && mapCaseEmailMessage.get(newCase.Id) != null && lastDateProvider != Datetime.newInstance(1960, 2, 19)) {
                    newCase.Status = Constants.REQUETE_STATUS_ANSWERKPARK;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(lastDateProvider >= lastDateKPARK && mapCaseEmailMessage.get(newCase.Id) != null && lastDateProvider != Datetime.newInstance(1960, 2, 19)) {
                    newCase.Status = Constants.REQUETE_STATUS_ANSWERPROVIDER;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(newCase.transmissionDate__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_SENT ;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                } else if(newCase.provider__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_NEW;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                }

            // Traitement des statuts des requêtes NCP Interne
            } else if (newCase.RecordTypeId == RT_PNC_INTERNALID) {

                Boolean allProviderOrdersConfirmed = false;
                Boolean allProviderOrdersDelivered = false;
                Boolean unconfirmedOrderDetected = false;
                Boolean undeliveredOrderDetected = false;

                // Si il n'y a aucune commande fournisseur associées, ou que l'une d'elle n'est pas livrée/confirmée, les booléen invalident le statut
                if(!providerOrdersList.isEmpty()){
                    for(Order providerOrder : providerOrdersList){
                        // Si il existe au moins une CF
                        if(providerOrder.productNonCompliance__c == newCase.Id){
                            allProviderOrdersConfirmed = true;
                            allProviderOrdersDelivered = true;
                            if(providerOrder.deliveryDate__c == null){
                                undeliveredOrderDetected = true;
                            }
                            if(providerOrder.confirmationDate__c == null && providerOrder.transmissionDate__c == null){
                                unconfirmedOrderDetected = true;
                            }
                        }
                    }
                    // Si une des CF détectée n'est pas confirmée/livrée
                    if(unconfirmedOrderDetected){
                        allProviderOrdersConfirmed = false;
                    }
                    if(undeliveredOrderDetected){
                        allProviderOrdersDelivered = false;
                    }
                }

                if(newCase.Status == Constants.REQUETE_STATUS_CLOSED || newCase.processingEndDate__c != null || newCase.remotlyResolved__c) {
                    newCase.Status = Constants.REQUETE_STATUS_CLOSED;
                    newCase.stageName__c = Constants.REQUETE_STEP_CLOSED;
                } else if(newCase.diagnosticDate__c != null && (allProviderOrdersDelivered || 
                        (newCase.providerOrderNumber__c != null && newCase.providerOrderNumber__c != 0 && newCase.deliveredProviderOrderNumber__c == newCase.providerOrderNumber__c))) {
                    newCase.Status = Constants.REQUETE_STATUS_DELIVERED;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(newCase.diagnosticDate__c != null && (allProviderOrdersConfirmed || 
                        (newCase.providerOrderNumber__c != null && newCase.providerOrderNumber__c != 0 && newCase.orderedProviderOrderNumber__c == newCase.providerOrderNumber__c))) {
                    newCase.Status = Constants.REQUETE_STATUS_ORDERED;
                    newCase.stageName__c = Constants.REQUETE_STEP_RESOLUTION;
                } else if(newCase.diagnosticDate__c != null) {
                    newCase.Status = Constants.REQUETE_STATUS_DIAGNOSTIC;
                    newCase.stageName__c = Constants.REQUETE_STEP_DIAGNOSTIC;
                } else {
                    newCase.Status = Constants.REQUETE_STATUS_NEW;
                    newCase.stageName__c = Constants.REQUETE_STEP_REGISTERED;
                }
            }
                
            // Si changement de statut 
            if(oldCase != null && oldCase.Status != newCase.Status) {
                // En cas de réouverture de la requête
                if(oldCase.Status == Constants.REQUETE_STATUS_CLOSED && newCase.Status != Constants.REQUETE_STATUS_CLOSED) 
                    newCase.Status = oldCase.statutPrecedent__c; //on remet le statut existant avant la fermeture
                if(oldCase.Status != Constants.REQUETE_STATUS_CLOSED && newCase.Status == Constants.REQUETE_STATUS_CLOSED)
                    newCase.statutPrecedent__c = oldCase.Status; //maj du statut précédent
            }
            System.debug('## Case aCloturer: '+newCase.aCloturer__c);
            System.debug('## Case Status: '+newCase.Status);
        }
        System.debug('### FIN TR020_Case : applyStatusUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour de données pour les requêtes legacy (GC)
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyLegacyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Case : applyLegacyUpdateRules');
        
        List<Case> newCases = new List<Case>();
        List<String> caseAccountIds = new List<String>();
        Map<String, Account> accountsMap = new Map<String, Account>();
        
        // A - Initialisation des données intermédiaires 
        for (Case newCase : (List<Case>)Trigger.new) {
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newCase.legacyReference__c) && String.isNotBlank(newCase.AccountId)) 
            {
                newCases.add(newCase);
                caseAccountIds.add(newCase.AccountId);
            }
            // LEGACY - Status Closed
            if(Trigger.isInsert && Trigger.isBefore && newCase.isLegacy__c && String.isNotBlank(newCase.legacyReference__c) && newCase.ClosedDate != null) {
                newCase.Status = Constants.REQUETE_STATUS_CLOSED;
                newCase.stageName__c = Constants.REQUETE_STEP_CLOSED;
            }
        }       

        // B - Récupération des enregistrements
        if(!caseAccountIds.isEmpty()) {
            for (Account acc : [SELECT Id, contactParDefaut__c FROM Account WHERE Id IN :caseAccountIds]) {
                accountsMap.put(acc.Id, acc);
            }
            System.debug('## accountsMap: ' + accountsMap);
        }
        System.debug('## newCases: ' + newCases);

        for (Case newCase : newCases) {
            // LEGACY - Alimentation ContactId            
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newCase.legacyReference__c) && accountsMap.get(newCase.AccountId) != null) {
                newCase.ContactId = accountsMap.get(newCase.AccountId).contactParDefaut__c;
            }
        }
        System.debug('### FIN TR020_Case : applyLegacyUpdateRules');
    }  
    
    /**
    * @description Méthode pour affecter les différents manager du propriétaire de la requête
    * @param newCase Requête à traiter
    * @param users Map contenant les information de tous les vendeurs/RV/DV/DR
    * @param owner Propriétaire de la requête
    */
    private static void affectationManagers(Case newCase, Map<Id, User> users, User owner) {
        /* Manager N */
        User manager = users.get(owner.ManagerId);              
        if (manager != null) {
            System.debug('## User N: '+manager.Id+' - '+manager.Name);
            newCase.utilisateurN__c = manager.id;
              
            /* Manager N - 1 */
            manager = users.get(manager.managerId);
            if (manager != null) {
                System.debug('## User N+1: '+manager.Id+' - '+manager.Name);
                newCase.utilisateurN1__c = manager.id;
                
                /* Manager N - 2 */            
                manager = users.get(manager.managerId);
                if (manager != null) {
                    System.debug('## User N+2: '+manager.Id+' - '+manager.Name);
                    newCase.utilisateurN2__c = manager.id;
                }
            }
        }
    }

    /**
    * @description Vérifie si la requête est une réclamation de service ("Réclamation métrage", "Réclamation installation", "Réclamation SAV") 
    * ou de gestion de la relation client ("Nouveau rendez-vous", "Modification de rendez-vous", "Annulation de rendez-vous", 
    * "Demande d'information", "Annulation contrat")
    * @param newCase Requête à vérifier
    * @param owner True si c'est une requête de réclamation de service ou de gestion de la relation client
    */
    private static Boolean isReclaOrGestion(Case newCase) {
        return (newCase.Type == Constants.REQUETE_RECLAMATION_METRAGE || 
                newCase.Type == Constants.REQUETE_RECLAMATION_INSTALLATION ||
                newCase.Type == Constants.REQUETE_RECLAMATION_SAV ||
                    ((newCase.typeDeRendezVous__c == Constants.REQUETE_RDV_INSTALLATION ||
                        newCase.typeDeRendezVous__c == Constants.REQUETE_RDV_METRAGE ||
                        newCase.typeDeRendezVous__c == Constants.REQUETE_RDV_SAV) && 
                            (newCase.Type == Constants.REQUETE_NOUVEAU_RDV ||
                                newCase.Type == Constants.REQUETE_MODIF_RDV ||
                                newCase.Type == Constants.REQUETE_ANNULATION_RDV ||
                                newCase.Type == Constants.REQUETE_DEMANDE_INFO)));
    }
}