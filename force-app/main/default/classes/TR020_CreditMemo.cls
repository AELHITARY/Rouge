//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_CreditMemo
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 05/10/2021
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_CreditMemo {
    private static final Id RT_COMMERCIAL_CREDITMEMO = DAL.getRecordTypeIdByDevName('CreditMemo__c',Constants.CREDITMEMO_COMMERCIALCREDITMEMO_RT);

    /**
    * @description Méthode exécutant les règles de validation pour les avoirs
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemo.applyValidationRules');
        
        List<CreditMemo__c> oldCreditMemos = (List<CreditMemo__c>)Trigger.old;
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new;

        // DELETE
        for(CreditMemo__c oldCreditMemo : oldCreditMemos){
            // Ne pas supprimer si la commande est verrouillée
            if(oldCreditMemo.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore){
                System.debug('## oldCreditMemo.isOrderLocked__c : ' + oldCreditMemo.isOrderLocked__c);
                oldCreditMemo.addError(Label.order_msg_cantDeleteCreditMemo);
            }  
        }

        // BEFORE
        if(newCreditMemos != null && !newCreditMemos.isEmpty()) {
            List<CreditMemoLine__c> cmLineList = new List<CreditMemoLine__c>();
            List<String> cmIdList = new List<String>();

            // Récupération des lignes d'avoir
            for(CreditMemo__c newCreditMemo : newCreditMemos){
                if(String.isNotBlank(newCreditMemo.Id)) {
                    cmIdList.add(newCreditMemo.Id);
                }
            }
            
            if(!cmIdList.isEmpty()) {
                cmLineList = [SELECT Id, invoice__c, creditMemo__c FROM CreditMemoLine__c WHERE creditMemo__c IN :cmIdList];       
    
                for(CreditMemo__c newCreditMemo : newCreditMemos){
                    // Si avoir commercial et non brouillon, alors au moins une ligne d'avoir référencant une facture (interdiction de référencer une ligne de facture)
                    Boolean isOK = false;
                    System.debug('## Check invoice for commercial CreditMemo: '+newCreditMemo.Id);
                    if(newCreditMemo.RecordTypeId == RT_COMMERCIAL_CREDITMEMO && newCreditMemo.status__c != Constants.CREDITMEMO_BROUILLON 
                        && (Trigger.isUpdate || Trigger.isInsert)
                    ){
                        for(CreditMemoLine__c cml : cmLineList){
                            if(cml.creditMemo__c == newCreditMemo.Id && cml.invoice__c != null) {
                                System.debug('## CreditMemo Invoice: '+cml.invoice__c);
                                isOK = true;  
                                break;
                            }
                        }
                        if(!isOK){
                            System.debug('## Error: '+Label.creditMemo_msg_commercialCreditMemoInvLineReq);
                            newCreditMemo.addError(Label.creditMemo_msg_commercialCreditMemoInvLineReq);
                        }
                    }  
                }  
            }
        }

        // AFTER
        if(newCreditMemos != null && !newCreditMemos.isEmpty()) {
            for(CreditMemo__c newCreditMemo : newCreditMemos){
                // Vérification champ headOffice obligatoire
                if(newCreditMemo.isLegacy__c == false && Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)){
                    System.debug('## Check champ HeadOffice: ' + newCreditMemo.Id);
                    String errorMsg = 'Champ obligatoire!';
                    if(newCreditMemo.headOfficeShareCapital__c == null) {
                        newCreditMemo.headOfficeShareCapital__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.headOfficePostalCode__c)) {
                        newCreditMemo.headOfficePostalCode__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.headOfficeLegalForm__c)) {
                        newCreditMemo.headOfficeLegalForm__c.addError(errorMsg);
                    }
                    if(newCreditMemo.headOfficeSIREN__c == null) {
                        newCreditMemo.headOfficeSIREN__c.addError(errorMsg);
                    }
                    if(newCreditMemo.headOfficeSIRET__c == null) {
                        newCreditMemo.headOfficeSIRET__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.headOfficeName__c)) {
                        newCreditMemo.headOfficeName__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.headOfficeCity__c)) {
                        newCreditMemo.headOfficeCity__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.RCSCity__c)) {
                        newCreditMemo.RCSCity__c.addError(errorMsg);
                    }
                    if(String.isBlank(newCreditMemo.RCSNumber__c)) {
                        newCreditMemo.RCSNumber__c.addError(errorMsg);
                    }
                }  
            }
        }
        
        System.debug('### FIN TR020_CreditMemo.applyValidationRules');
    }

    /**
    * @description Méthode pour interdire la suppression d'un avoir pour 10 ans si il a un numéro fiscal. Exigence légale a ne pas désactiver ni bypasser !
    * @param userContext contexte utilisateur
    */
    public static void cannotDeleteCreditMemo(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemo.cannotDeleteCreditMemo');
        
        List<CreditMemo__c> oldCreditMemos = (List<CreditMemo__c>)Trigger.old;
        for(CreditMemo__c oldCreditMemo : oldCreditMemos) {
            if(oldCreditMemo.isCreditMemoLocked__c && Trigger.isDelete && Trigger.isBefore)
            {
                oldCreditMemo.addError(Label.creditmemo_msg_cantDelete);
            }  
        }
        
        System.debug('### FIN TR020_CreditMemo.cannotDeleteCreditMemo');
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
    public static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemo.applyDataUpdateRules');
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new; 
        List<CreditMemoLine__c> creditMemoLinesList = new List<CreditMemoLine__c>();
        Map<Id, CreditMemo__c> oldCreditMemos = (Map<Id, CreditMemo__c>)Trigger.oldMap; 
        Set<String> creditMemoIdsList = new Set<String>(); 
        List<String> orderIds = new List<String>();  
        Map<Id, Order> orderMap = new Map<Id, Order>();  
        Map<String, Account> entityHierarchieMap = new Map<String, Account>();
      
        /** A - Initialisation des données intermédiaires **/
        // Recherche des objets associées 
        for (CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            if(String.isNotBlank(newCreditMemo.Id)) {
                creditMemoIdsList.add(newCreditMemo.Id);
            }
            // MAJ infos de la commande
            if((Trigger.isInsert || (Trigger.isUpdate && newCreditMemo.customerOrder__c != oldCreditMemo.customerOrder__c)) && String.isNotBlank(newCreditMemo.customerOrder__c)) {
                System.debug('## customerOrder :' + newCreditMemo.customerOrder__c);
                orderIds.add(newCreditMemo.customerOrder__c);
            }
        }
        
        // Récupération information pour numéro fiscal
        List<CreditMemo__c> lstCM = [SELECT Id, autoNumber__c FROM CreditMemo__c WHERE autoNumber__c != null ORDER BY autoNumber__c DESC LIMIT 1];
        Decimal intCounter = 0;
        if(!lstCM.isEmpty()) {
            intCounter = lstCM[0].autoNumber__c; 
        }

        // Récupération des enregistrements d'objets associés
        if(!orderIds.isEmpty()) {
            orderMap = new Map<Id, Order>([SELECT Id, AccountId, BillToContactId, billingName__c, BillingStreet, BillingPostalCode, BillingCity, Account.Name, BillingState, BillingCountry,
                                                salesEntity__c, salesEntity__r.rue__c, salesEntity__r.codePostal__c, salesEntity__r.ville__c, salesEntity__r.departement__c, chantier__c,
                                                salesEntity__r.pays__c, salesEntity__r.Name, salesEntity__r.Ownership, salesEntity__r.complementAdresse__c, ShipToContactId, shippingName__c,
                                                ShippingStreet, ShippingPostalCode, ShippingCity, ShippingState, ShippingCountry, serviceEntity__c, serviceEntity__r.rue__c, serviceEntity__r.codePostal__c, 
                                                serviceEntity__r.ville__c, serviceEntity__r.departement__c, serviceEntity__r.pays__c, serviceEntity__r.Name, serviceEntity__r.complementAdresse__c,
                                                salesEntity__r.email__c, serviceEntity__r.email__c, salesEntity__r.Phone, serviceEntity__r.Phone, billingAdditionalAddress__c, shippingAdditionalAddress__c,
                                                serviceEntity__r.SIRET__c, salesEntity__r.shareCapital__c, salesEntity__r.SIREN__c, salesEntity__r.SIRET__c,
                                                salesEntity__r.RCSNumber__c, salesEntity__r.RCSCity__c, serviceEntity__r.intracommunityVATNumber__c, salesEntity__r.intracommunityVATNumber__c,
                                                Account.contactParDefaut__c
                                                   FROM Order 
                                                   WHERE id IN :orderIds]);
            System.debug('## orderMap: '+orderMap ); 
            // Récupération des entités
            entityHierarchieMap = getEntityHierarchy();
        }   

        if(!creditMemoLinesList.isEmpty()) {
            creditMemoLinesList = [SELECT Id, creditMemo__c, amount__c, pretaxAmount__c, invoice__c FROM CreditMemoLine__c WHERE CreditMemo__c IN :creditMemoIdsList];
        }
                           
        /** B - Application des règles de mise à jour **/   
        for (CreditMemo__c newCreditMemo : newCreditMemos) {
            System.debug('## Id: '+newCreditMemo.Id); 
            System.debug('## CustomerOrder: '+newCreditMemo.customerOrder__c ); 
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            
            // Alimentation numérotation automatique
            if(newCreditMemo.creditMemoDate__c != null && newCreditMemo.creditMemoReference__c == null && intCounter != null && newCreditMemo.isLegacy__c == false){
                intCounter ++;
                newCreditMemo.autoNumber__c = intCounter;
                // Formatage de la référence AVR/{0000000} 
                String ref = 'AVR/';
                for(Integer i=0; i < 7 - intCounter.precision(); i++) {
                    ref += '0';
                }
                newCreditMemo.creditMemoReference__c = ref+''+intCounter;
            }    

            // MAJ des informations par rapport à la commande client            
            if(String.isNotBlank(newCreditMemo.customerOrder__c) && orderMap.get(newCreditMemo.customerOrder__c) != null && newCreditMemo.isLegacy__c == false) {
                newCreditMemo.worksite__c = orderMap.get(newCreditMemo.customerOrder__c).chantier__c;

                // MAJ des informations du compte de facturation
                if(String.isNotBlank(orderMap.get(newCreditMemo.customerOrder__c).AccountId)) {
                    System.debug('## MAJ des informations du compte de facturation: '+orderMap.get(newCreditMemo.customerOrder__c).BillToContactId); 
                    newCreditMemo.billingAccount__c = orderMap.get(newCreditMemo.customerOrder__c).AccountId;
                    newCreditMemo.billingContact__c = orderMap.get(newCreditMemo.customerOrder__c).Account.contactParDefaut__c;
                    newCreditMemo.billingName__c = orderMap.get(newCreditMemo.customerOrder__c).billingName__c;
                    newCreditMemo.billingStreet__c = orderMap.get(newCreditMemo.customerOrder__c).BillingStreet;
                    newCreditMemo.billingPostalCode__c = orderMap.get(newCreditMemo.customerOrder__c).BillingPostalCode;
                    newCreditMemo.billingCity__c = orderMap.get(newCreditMemo.customerOrder__c).BillingCity;
                    newCreditMemo.billingAdditionalAddress__c = orderMap.get(newCreditMemo.customerOrder__c).billingAdditionalAddress__c;
                    newCreditMemo.billingState__c = orderMap.get(newCreditMemo.customerOrder__c).BillingState;
                    newCreditMemo.billingCountry__c = orderMap.get(newCreditMemo.customerOrder__c).BillingCountry;
                    System.debug('## MAJ des informations du compte de livraison: '+orderMap.get(newCreditMemo.customerOrder__c).ShipToContactId); 
                    newCreditMemo.shippingContact__c = orderMap.get(newCreditMemo.customerOrder__c).Account.contactParDefaut__c;
                    newCreditMemo.shippingName__c = orderMap.get(newCreditMemo.customerOrder__c).shippingName__c;
                    newCreditMemo.shippingStreet__c = orderMap.get(newCreditMemo.customerOrder__c).ShippingStreet;
                    newCreditMemo.shippingPostalCode__c = orderMap.get(newCreditMemo.customerOrder__c).ShippingPostalCode;
                    newCreditMemo.shippingCity__c = orderMap.get(newCreditMemo.customerOrder__c).ShippingCity;
                    newCreditMemo.shippingAdditionalAddress__c = orderMap.get(newCreditMemo.customerOrder__c).shippingAdditionalAddress__c;
                    newCreditMemo.shippingState__c = orderMap.get(newCreditMemo.customerOrder__c).ShippingState;
                    newCreditMemo.shippingCountry__c = orderMap.get(newCreditMemo.customerOrder__c).ShippingCountry;
                }
                // MAJ des informations de l'entité de vente
                if(String.isNotBlank(orderMap.get(newCreditMemo.customerOrder__c).salesEntity__c)) {
                    System.debug('## MAJ des informations siege social: '+orderMap.get(newCreditMemo.customerOrder__c).salesEntity__c); 
                    Account headOffice = calculateHeadOffice(orderMap.get(newCreditMemo.customerOrder__c).salesEntity__c, entityHierarchieMap);
                    if(headOffice != null) {
                        newCreditMemo.headOffice__c = headOffice.Id;
                        newCreditMemo.headOfficeName__c = headOffice.Name;
                        newCreditMemo.headOfficeStreet__c = headOffice.rue__c;
                        newCreditMemo.headOfficePostalCode__c = headOffice.codePostal__c;
                        newCreditMemo.headOfficeCity__c = headOffice.ville__c;
                        newCreditMemo.headOfficeAdditionalAddress__c = headOffice.complementAdresse__c;
                        newCreditMemo.headOfficeState__c = headOffice.departement__c;
                        newCreditMemo.headOfficeCountry__c = headOffice.pays__c;
                        newCreditMemo.headOfficeEmail__c = headOffice.email__c;
                        newCreditMemo.headOfficePhone__c = headOffice.Phone;
                        newCreditMemo.headOfficeShareCapital__c = headOffice.shareCapital__c;
                        newCreditMemo.headOfficeLegalForm__c = headOffice.Ownership;
                        newCreditMemo.headOfficeSIREN__c = headOffice.SIREN__c;
                        newCreditMemo.headOfficeSIRET__c = headOffice.SIRET__c;
                        newCreditMemo.RCSnumber__c = headOffice.RCSNumber__c;
                        newCreditMemo.RCSCity__c = headOffice.RCSCity__c;
                        newCreditMemo.intracommunityVATNumber__c = headOffice.intracommunityVATNumber__c;
                    }
                }
                // MAJ des informations de l'entité de service
                if(String.isNotBlank(orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__c)) {
                    System.debug('## MAJ des informations de l\'entité technique: '+orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__c); 
                    newCreditMemo.seller__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__c;
                    newCreditMemo.sellerName__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.Name;
                    newCreditMemo.sellerStreet__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.rue__c;
                    newCreditMemo.sellerPostalCode__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.codePostal__c;
                    newCreditMemo.sellerCity__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.ville__c;
                    newCreditMemo.sellerAdditionalAddress__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.complementAdresse__c;
                    newCreditMemo.sellerState__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.departement__c;
                    newCreditMemo.sellerCountry__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.pays__c;
                    newCreditMemo.sellerEmail__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.email__c;
                    newCreditMemo.sellerPhone__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.Phone;
                    newCreditMemo.sellerSIRET__c = orderMap.get(newCreditMemo.customerOrder__c).serviceEntity__r.SIRET__c;
                }      
            }    
        }
        System.debug('### FIN TR020_CreditMemo.applyDataUpdateRules');
    }

    /**
    * @description Règle de mise à jour du statut des avoirs
    * @param userContext Information de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_CreditMemo : applyStatusUpdateRules');
        
        /** A - Initialisation des données intermédiaires **/
        List<CreditMemo__c> newCreditMemos = (List<CreditMemo__c>)Trigger.new;
        Map<Id, CreditMemo__c> oldCreditMemos = (Map<Id, CreditMemo__c>)Trigger.oldMap;
        Map<String, Referencial__c> referencialMap = new Map<String, Referencial__c>();
        Boolean getReferenceDatas = false;        
        String motifAnnulationAdmin = PropertiesUtils.getStringValue('ref.motifAnnulationAdmin.code', 'R-06');

        /** A - Initialisation des données intermédiaires **/
        // Recherche des objets associées 
        for (CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            // MAJ infos refus
            if(Trigger.isUpdate && oldCreditMemo != null && newCreditMemo.isRefused__c != oldCreditMemo.isRefused__c && newCreditMemo.isRefused__c) {
                System.debug('## isRefused :' + newCreditMemo.isRefused__c);
                getReferenceDatas = true;
            }
        }

        // Récupération référentiel
        if(getReferenceDatas) {
            List<String> codeRefList = new List<String>();
            codeRefList.add(motifAnnulationAdmin);
            for (Referencial__c ref : [SELECT Id, KparKReference__c FROM Referencial__c WHERE KparKReference__c IN :codeRefList]) {
                referencialMap.put(ref.KparKReference__c, ref);
            }
        }
        
        /** B - Application des règles de mise à jour **/
        for (CreditMemo__c newCreditMemo : newCreditMemos) {
            CreditMemo__c oldCreditMemo = oldCreditMemos == null ? null : oldCreditMemos.get(newCreditMemo.id);
            System.debug('## CreditMemo Id: '+newCreditMemo.Id);
            Referencial__c cancellingReasonRefused = referencialMap.get(motifAnnulationAdmin);

            // MAJ de champ lors d'un changement de statut
            if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) { 
                System.debug('## Change status for CreditMemo: ' + newCreditMemo.Id);
                if (newCreditMemo.isRefused__c) {
                    System.debug('## status 1');
                    newCreditMemo.status__c = Constants.CREDITMEMO_ANNULE;
                    newCreditMemo.stageName__c = 'Terminé';
                    newCreditMemo.cancellationDate__c = Date.today();
                    if(newCreditMemo.cancellationReason__c == null) {
                        newCreditMemo.cancellationReason__c = (cancellingReasonRefused != null) ? cancellingReasonRefused.Id : null;
                    }
                } else if(newCreditMemo.cancellationDate__c != null) {
                    System.debug('## status 2');
                    newCreditMemo.status__c = Constants.CREDITMEMO_ANNULE;
                    newCreditMemo.stageName__c = 'Terminé';
                } else if (newCreditMemo.refundDate__c != null) {
                    System.debug('## status 3');
                    newCreditMemo.status__c = Constants.CREDITMEMO_ACQUITTE;
                    newCreditMemo.stageName__c = 'Terminé';
                } else if (newCreditMemo.publishedDate__c != null) {
                    System.debug('## status 4');
                    newCreditMemo.status__c = Constants.CREDITMEMO_PUBLIE;
                    newCreditMemo.stageName__c = 'Remboursement';
                }  else if (newCreditMemo.creditMemoDate__c != null) {
                    System.debug('## status 5');
                    newCreditMemo.status__c = Constants.CREDITMEMO_VALIDE;
                    newCreditMemo.isValid__c = true;
                    newCreditMemo.stageName__c = 'Remboursement';
                } else {
                    System.debug('## status 6');
                    newCreditMemo.status__c = Constants.CREDITMEMO_BROUILLON;
                    newCreditMemo.stageName__c = 'Préparation';
                }
                System.debug('## CreditMemo Status: '+newCreditMemo.status__c);
            }   
        }
        System.debug('### FIN TR020_CreditMemo : applyStatusUpdateRules');
    }
    
    /**
    * @description Méthode récurive permettant de vérifier l'entité parente (celle en premier de la hiearchie)
    * @param entityId Id de l'entité
    * @param entityHierarchieMap Objet contenant la hiéarchie des entités
    * @return Account Entité parente
    */
    private static Account calculateHeadOffice(String entityId, Map<String, Account> entityHierarchieMap) {
        Account entity = entityHierarchieMap.get(entityId);
        System.debug('## Recherche par l\'entité parente: '+entity); 
        if(entity == null || String.isBlank(entity.ParentId)) {
            System.debug('## Entité parente: '+entity);
            return entity;
        } else {
            // Sinon on effectue une récursivité sur l'entité
            return calculateHeadOffice(entity.ParentId, entityHierarchieMap);
        } 
    }

    /**
    * @description Méthode permettant de construire la hiéarchie des entités
    * @return Map<String, Account> Retourne une map des entités : Key = Id entité, valeur = entité
    */
    public static Map<String, Account> getEntityHierarchy() {
        Map<String, Account> result = new Map<String, Account>();
        String rtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account acc : [SELECT Id, Name, ParentId, rue__c, codePostal__c, ville__c, departement__c, pays__c, Ownership, complementAdresse__c,
                                emailPro__c, Phone, SIRET__c, shareCapital__c, SIREN__c, RCSNumber__c, RCSCity__c, intracommunityVATNumber__c,
                                entityType__r.KparKReference__c, email__c, KparKReference__c 
                            FROM Account WHERE RecordTypeId = :rtId]) {
            result.put(acc.Id, acc);
        }
        return result;
    }
}