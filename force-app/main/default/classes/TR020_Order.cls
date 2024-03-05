/**
 * @Fichier           : TR020_Order
 * @author            : SOPRA STERIA
 * @last modified on  : 02-13-2024
 * @last modified by  : SOPRA STERIA
**/
public without sharing class TR020_Order {
    private static final String CUSTOMER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final String PROVIDER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final String NCC_IMPOSSIBILITY_RTID = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');    
    
    /**
    * @description Méthode exécutant les règles de validation pour les commandes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Order.applyValidationRules');

        // A - Initialisation des données intermédiaires 
        Map<Id, Order> newOrderMap = (Map<Id, Order>)Trigger.newMap;
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        List<Id> productNonComplianceIds = new List<Id>();
        Map<Id,Case> ncpMap = new Map<Id,Case>();
        Set<String> orderIdList = new Set<String>();
        Map<Id,List<Asset>> firstLevelAssetOrderIdMap = new Map<Id,List<Asset>>();
        List<Asset> firstLevelAssetList = new List<Asset>();
        Set<String> validatedOrderIdList = new Set<String>();
        Set<String> validationErrorOrderList = new Set<String>();
        //Map<Id,ServiceAppointment> saMap = new Map<Id,ServiceAppointment>();
        //Map<Id,Integer> activeImpossibilityNccCountMap = new Map<Id,Integer>();
         
        
        List<Id> parentsOrders = new List<Id>();
        Map<Id, Order> parentOrderMap = new Map<Id, Order>();
        
        for(Order ord : (List<Order>)Trigger.new){
            Order oldOrder = oldOrders == null ? null : oldOrders.get(ord.Id);
            if(String.isNotBlank(ord.productNonCompliance__c)) {
                productNonComplianceIds.add(ord.productNonCompliance__c);
            }
            if(ord.id != null){
                orderIdList.add(ord.Id);
            }
             //on filtre pour recuperer que les commandes qui n'ont pas le champ parentOrder__c vide et on est une sur une commande fournisseur
            if (String.isNotBlank(ord.parentOrder__c) && ord.RecordTypeId == PROVIDER_ORDER_RTID){
                parentsOrders.add(ord.parentOrder__c);
            }
            //Cas validation administrative de la commande
            if(Trigger.isUpdate && ord.administrativeValidation__c && !oldOrder.administrativeValidation__c){
                validatedOrderIdList.Add(ord.Id);
            }
        }
        
        if(!orderIdList.isEmpty() && Trigger.isUpdate){
            firstLevelAssetList = [SELECT Id, installDate, customerOrder__c, Status FROM Asset 
                WHERE customerOrder__c IN :orderIdList AND ParentId = null AND Status != :Constants.ORDER_STATUS_CANCELLED];
        }
        
        for(Asset ast : firstLevelAssetList){
            List<Asset> astList = new List<Asset>();
            if(firstLevelAssetOrderIdMap.get(ast.customerOrder__c) != null){
                astList = firstLevelAssetOrderIdMap.get(ast.customerOrder__c); 
            } 
            astList.add(ast);
            firstLevelAssetOrderIdMap.put(ast.customerOrder__c,astList);
        }

        if(!productNonComplianceIds.isEmpty()) {
            ncpMap = new Map<Id,Case>([SELECT Id,responsability__c 
                                        FROM Case WHERE Id IN :productNonComplianceIds]);
        }
        if (!parentsOrders.isEmpty()) {            
            //on cree une liste de commande et on recupere les champs qui nous interresse ou les id sont dans parentOrdersId
            List<Order> parentOrdersData = [SELECT Id, Status, financingAgreementNumber__c,financingMethod__r.financingType__c
                                            FROM Order
                                            WHERE Id IN :parentsOrders];
            
            //on parcoure la liste parentsOrdersData et on remplie la map                              
            for (Order parentOrder : parentOrdersData) {
                parentOrderMap.put(parentOrder.Id, parentOrder);
            }    
        }
        
        //vérification si possibilité de valider administrativement la commande
        if(!validatedOrderIdList.isEmpty()){
            Set<String> nccErrorOrderList = new Set<String>();
            //Vérification si présence de NCC commandes de type Impossibilité toujours en cours pour chaque commande
            List<OrderNonCompliance__c> activeImpossibilityNccList = [SELECT Id,customerOrder__c FROM OrderNonCompliance__c WHERE status__c = 'En cours' AND RecordTypeId =:NCC_IMPOSSIBILITY_RTID AND customerOrder__c IN :validatedOrderIdList];
            if(!activeImpossibilityNccList.isEmpty()){
                for(OrderNonCompliance__c ncc : activeImpossibilityNccList){
                    if(!nccErrorOrderList.Contains(ncc.customerOrder__c)){
                        nccErrorOrderList.Add(ncc.customerOrder__c);
                    }

                }
            }

            //Vérification si présence des RDV métrage non débriefé associé à chaque commande
            Set<String> saErrorOrderList = new Set<String>();
            List<ServiceAppointment> notDebriefedSaList = [SELECT Id,customerOrder__c FROM ServiceAppointment WHERE Status !=:constants.RDV_FSL_DEBRIEFE AND Status !=:constants.RDV_FSL_ANNULE AND workTypeName__c = 'Métrage' AND customerOrder__c IN :validatedOrderIdList];
            if(!notDebriefedSaList.isEmpty()){
                for(ServiceAppointment sa : notDebriefedSaList){
                    if(!saErrorOrderList.Contains(sa.customerOrder__c)){
                        saErrorOrderList.Add(sa.customerOrder__c);
                    }
                }
            }

            //Erreur à la validation si RDV métrage non débriefé présent ET NCC commandes de type Impossibilité en cours
            for(String orderId : validatedOrderIdList){
                if( nccErrorOrderList.Contains(orderId) && saErrorOrderList.Contains(orderId)) {                    
                    validationErrorOrderList.Add(orderId);
                }
            }
            

        }
        
        // B - Application des règles de validation (NO DELETE) 
        for (Order newOrder : (List<Order>)Trigger.new) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
            if (!AlreadyUsed.isUsed('TR020_Order.applyValidationRules', newOrder.id) && userContext != null) {
                if (Trigger.isBefore) { 
                    if(Trigger.isUpdate){
                        //Commandes fournisseurs
                        if(newOrder.RecordTypeId == PROVIDER_ORDER_RTID){
                            // Si le Profil est: K/K - K par K (Données)
                            if(userContext != null && userContext.getProfile() != null && userContext.getProfile().Name == 'K/K - K par K (Données)'){
                                newOrderMap.get((newOrder.Id)).addError('Votre profil ne dispose pas des droits pour modifier une commande fournisseur');
                            }
                        }
            
                        //Commandes clients
                        if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID){
                            // Si le Profil est: K/K - K par K (Réf/Données)
                            if(userContext != null && userContext.getProfile() != null && userContext.getProfile().Name == 'K/K - K par K (Réf/Données)'){
                                newOrderMap.get((newOrder.Id)).addError('Votre profil ne dispose pas des droits pour modifier une commande client');
                            }

                            /*if((!oldOrder.amendingInProgress__c || !newOrder.amendingInProgress__c || !oldOrder.amending__c || !newOrder.amending__c) &&
                            (oldOrder.BillingCity != newOrder.BillingCity || oldOrder.BillingCountry != newOrder.BillingCountry || oldOrder.BillingPostalCode != newOrder.BillingPostalCode ||
                            oldOrder.BillingState != newOrder.BillingState || oldOrder.BillingStreet != newOrder.BillingStreet) && newOrder.CreatedDate.addMinutes(1) < System.now() &&
                            (String.isNotBlank(oldOrder.BillingCity) && String.isNotBlank(oldOrder.BillingCountry) && String.isNotBlank(oldOrder.BillingPostalCode) && String.isNotBlank(oldOrder.BillingStreet))){
                                newOrderMap.get((newOrder.Id)).addError('La modification de l\'adresse de facturation est interdite (sauf par avenant)');
                            }*/

                        }
                         
                        if (newOrder.RecordTypeId == PROVIDER_ORDER_RTID) {
                            Order parentOrder = parentOrderMap.get(newOrder.parentOrder__c);
                            if (parentOrder != null && parentOrder.financingMethod__c != null &&
                                parentOrder.financingMethod__r.financingType__c == 'Funding' &&
                                String.isBlank(parentOrder.financingAgreementNumber__c) &&
                                newOrder.isValid__c &&
                                parentOrder.Status != constants.ORDER_STATUS_CANCELLED &&
                                parentOrder.Status != constants.ORDER_STATUS_CLOSED) {
                                newOrderMap.get(newOrder.Id).addError(Label.order_msg_impossibleToCreateCustomerOrder);
                            }
                        }             
                    }

                    if(Trigger.isInsert){
                        if(String.isNotBlank(newOrder.productNonCompliance__c)) {
                            //Case ncp = [SELECT Id,responsability__c FROM Case WHERE Id = :newOrder.productNonCompliance__c];
                            Case ncp = ncpMap.get(newOrder.productNonCompliance__c);
                            if(ncp != null && String.isBlank(ncp.responsability__c)){
                                newOrder.addError(Label.order_msg_cantCreateOrderNCPIfNoResponsability);
                            }
                        }
                    }

                    if(Trigger.isInsert || Trigger.isUpdate){
                        if(String.isNotBlank(newOrder.productNonCompliance__c)) {
                            Case ncp = ncpMap.get(newOrder.productNonCompliance__c);
                            if(ncp != null && ncp.responsability__c != newOrder.responsability__c){
                               newOrder.addError(Label.order_msg_cantCreateIOrModifyOrderDiffNCPResponsability);
                            }
                        }
                    }


                    if(Trigger.isUpdate && firstLevelAssetOrderIdMap.get(newOrder.Id) != null 
                        && newOrder.installationCompletionDate__c != null
                        && newOrder.installationCompletionDate__c != oldOrder.installationCompletionDate__c){
                        for (Asset actif : firstLevelAssetOrderIdMap.get(newOrder.Id)){
                            if(actif.status != Constants.ASSET_STATUS_ANNULE && (actif.installDate == null || (actif.installDate != null && newOrder.installationCompletionDate__c < actif.installDate ))){
                                newOrder.addError(Label.order_msg_allAssetShouldBeInstalled);
                            }
                        }
                    }

                    if(Trigger.isUpdate && !validationErrorOrderList.isEmpty()){
                        if(validationErrorOrderList.Contains(newOrder.Id)){
                            newOrder.addError(Label.order_msg_cannotValidateOrder);
                        }
                    }

                    
                }
            }
        }

        System.debug('### FIN TR020_Order.applyValidationRules');
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les commandes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
        
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        for(Order o : (List<Order>)Trigger.new){
            Order oldOrder = oldOrders == null ? null : oldOrders.get(o.Id);
            
            if(Trigger.isUpdate && o.Status == Constants.ORDER_STATUS_VALIDATED && o.RecordTypeId == CUSTOMER_ORDER_RTID 
                && String.isNotBlank(o.tempSalesOwner__c) 
                && (oldOrder.Status == Constants.ORDER_STATUS_REGISTERED || oldOrder.Status == Constants.ORDER_STATUS_AMENDING) 
                && String.isBlank(o.salesOwner__c))
            {
                o.salesOwner__c = o.tempSalesOwner__c;                
            }
        }

        // Recalcul des commissions
        /*if(!quoteIdsListForCommissions.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.debug('launch remVRP commissions calculation for quotes ' + quoteIdsListForCommissions);
            System.enqueueJob(new QA_QuoteProcessCommissions(quoteIdsListForCommissions));
        }*/
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les commandes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Order.applyDataUpdateRules');
        
        List<Order> customerOrder = new List<Order>();
        List<Order> providerOrder = new List<Order>();
        List<Id> orderIdList = new List<Id>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        List<String> accIds = new List<String>();     
        List<String> signeaCircuitIds = new List<String>();     
        List<String> quoteCPQIds = new List<String>(); 
        List<Signea__Signer__c> signeaSignerListComplete = new List<Signea__Signer__c>(); 
        List<Case> casesList = new List<Case>(); 
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, List<Signea__Signer__c>> signeaSignerMap = new Map<Id, List<Signea__Signer__c>>();
        Map<String,List<Case>> caseMap = new Map<String,List<Case>>();

        // A - Initialisation des données intermédiaires 
        for (Order newOrder : (List<Order>)Trigger.new) {            
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
            System.debug(newOrder);
            if(newOrder.Id != null){
                orderIdList.add(newOrder.Id);
            }
            if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID) {
                customerOrder.add(newOrder);
            } else if(newOrder.RecordTypeId == PROVIDER_ORDER_RTID) {
                providerOrder.add(newOrder);
            }

            if (!AlreadyUsed.isUsed('TR020_Order.applyDataUpdateRules', newOrder.id)) {    
                // Mise à jour si commande sur devis SAV
                if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID && Trigger.isBefore && String.isNotBlank(newOrder.SBQQ__Quote__c) 
                    && (Trigger.isInsert || (Trigger.isUpdate && oldOrder != null && oldOrder.SBQQ__Quote__c != newOrder.SBQQ__Quote__c)) 
                    && newOrder.cpqQuoteType__c == 'SAV')
                {
                    quoteCPQIds.add(newOrder.SBQQ__Quote__c);
                }
                // Mise à jour selon le client
                if(Trigger.isBefore && String.isNotBlank(newOrder.AccountId) && (Trigger.isInsert || (Trigger.isUpdate && oldOrder != null && oldOrder.AccountId != newOrder.AccountId)
                                                                                                  || (Trigger.isUpdate && oldOrder != null && newOrder.Name != null && !newOrder.Name.contains(newOrder.OrderNumber))) ) {  
                    accIds.add(newOrder.AccountId);
                }
                if(Trigger.isInsert && newOrder.signeaCircuit__c != null && newOrder.RecordTypeId == CUSTOMER_ORDER_RTID) {
                    signeaCircuitIds.add(newOrder.signeaCircuit__c);
                    System.debug('## Signea Circuit Ids: ' + signeaCircuitIds);
                }
            }
        }
        
        // B - Récupération données intermédiaire
        // Récupération client
        if(!accIds.isEmpty()) {
            accountMap = new Map<Id, Account>([SELECT Id, contactParDefaut__c, BillingAddress, Name, IsPersonAccount, FirstName, LastName,
                                               BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet FROM Account WHERE id IN :accIds]);
        }
        
        // Récupération des circuits de signatures
        if(!signeaCircuitIds.isEmpty()) {
            //signeaCircuitMap = new Map<Id, Signea__Circuit__c>([SELECT Id FROM Signea__Circuit__c WHERE id IN :signeaCircuitIds]);
            signeaSignerListComplete = [SELECT Id, Signea__Circuit__c, Signea__consent_date__c, Signea__User__c, Signea__Account__c,
                                        Signea__Account__r.PersonContactId, Signea__contact__c, Signea__Position__c
                                        FROM Signea__Signer__c WHERE Signea__Circuit__c IN :signeaCircuitIds AND Signea__Status__c = 'Signed'];
            System.debug('## Signea Signer List Complete: ' + signeaSignerListComplete);
            for(Order newOrder : (List<Order>)Trigger.new) {
                List<Signea__Signer__c> signeaSignerList = new List<Signea__Signer__c>();
                for(Signea__Signer__c signeaSigner : signeaSignerListComplete) {
                    if(signeaSigner.Signea__Circuit__c == newOrder.signeaCircuit__c) {
                        signeaSignerList.add(signeaSigner);
                    }
                }
                if(!signeaSignerList.isEmpty()) {
                    signeaSignerMap.put(newOrder.Id, signeaSignerList);
                }
            }
        }

        //TEST DEMO 29/01
        // Récupération requêtes SAV
        /*  for (String qId : quoteCPQIds) {
                List<Case> caseList = new List<Case>();
                for (Case caseT : casesList) {
                    if(caseT.afterSalesServiceQuote__c == qId) {
                        caseList.add(caseT);
                    }
                }
                caseMap.put(qId, caseList);
            }
        }*/
        System.debug('## customerOrder: ' + customerOrder);
        System.debug('## providerOrder: ' + providerOrder);
        System.debug('## accountMap: ' + accountMap);

        // C - Application des règles de mise à jour 
        // Mise à jour pour les commandes fournisseurs
        if(!providerOrder.isEmpty()) {
            for (Order newOrder : providerOrder) { 
                Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);

                system.debug('### newOrder.Name : '+newOrder.Name);
                
                if(Trigger.isInsert){
                    newOrder.OwnerId = Label.system_id_user_kpark;
                }
                
                if(!String.isBlank(newOrder.AccountId) && accountMap.get(newOrder.AccountId) != null){
                    newOrder.Name = newOrder.OrderNumber + ' - ';
                    system.debug('### newOrder.Name : '+newOrder.Name);
                    if(accountMap.get(newOrder.AccountId).IsPersonAccount){
                        newOrder.Name += accountMap.get(newOrder.AccountId).FirstName + ' - ' + accountMap.get(newOrder.AccountId).LastName;
                    } else {
                        newOrder.Name += accountMap.get(newOrder.AccountId).Name;
                    }
                    system.debug('### newOrder.Name : '+newOrder.Name);
                     
                    if(String.isBlank(newOrder.QuoteId) && String.isNotBlank(newOrder.parentOrder__c)){
                        newOrder.QuoteId = newOrder.parentOrderQuoteId__c;
                    }
                }
                system.debug('### newOrder.Name : '+newOrder.Name);
                
                
                // Mise à jour des informations du compte à la création des commandes fournisseurs
                if(Trigger.isBefore && (Trigger.isInsert || (Trigger.isUpdate && oldOrder != null && oldOrder.AccountId != newOrder.AccountId)) 
                ) {
                    if(String.isNotBlank(newOrder.AccountId) && accountMap.get(newOrder.AccountId) != null){

                        if(String.isBlank(newOrder.BillToContactId)) {
                            newOrder.BillToContactId = accountMap.get(newOrder.AccountId).contactParDefaut__c;
                        }
                        if(String.isBlank(newOrder.ShipToContactId)) {
                            newOrder.ShipToContactId = accountMap.get(newOrder.AccountId).contactParDefaut__c;
                        }
                        if(String.isBlank(newOrder.billingName__c)) {
                            newOrder.billingName__c = accountMap.get(newOrder.AccountId).Name;
                        }
                        if(String.isBlank(newOrder.shippingName__c)) {
                            newOrder.shippingName__c = accountMap.get(newOrder.AccountId).Name;
                        }
                        if(newOrder.BillingAddress == null) {
                            newOrder.BillingCity = accountMap.get(newOrder.AccountId).BillingCity;
                            newOrder.BillingCountry = accountMap.get(newOrder.AccountId).BillingCountry;
                            newOrder.BillingPostalCode = accountMap.get(newOrder.AccountId).BillingPostalCode;
                            newOrder.BillingState = accountMap.get(newOrder.AccountId).BillingState;
                            newOrder.BillingStreet = accountMap.get(newOrder.AccountId).BillingStreet;
                        }
                        if(newOrder.ShippingAddress == null) {
                            newOrder.ShippingCity = accountMap.get(newOrder.AccountId).BillingCity;
                            newOrder.ShippingCountry = accountMap.get(newOrder.AccountId).BillingCountry;
                            newOrder.ShippingPostalCode = accountMap.get(newOrder.AccountId).BillingPostalCode;
                            newOrder.ShippingState = accountMap.get(newOrder.AccountId).BillingState;
                            newOrder.ShippingStreet = accountMap.get(newOrder.AccountId).BillingStreet;
                        }
                    }
                }
                    
                // Mise à jour de la date d'activation historique
                if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) && newOrder.ActivatedDate != null && newOrder.firstActivatedDate__c == null ) {
                    newOrder.firstActivatedDate__c = newOrder.ActivatedDate;
                    System.debug('## First ActivatedDate: '+newOrder.firstActivatedDate__c);
                }
                if(Trigger.isBefore && Trigger.isUpdate && newOrder.ActivatedDate != null && newOrder.firstActivatedDate__c != null) {
                    newOrder.ActivatedDate = newOrder.firstActivatedDate__c;
                    System.debug('## New ActivatedDate: '+newOrder.ActivatedDate);
                }
                // Mise à jour champ copie de propriétaire
                newOrder.owner__c = newOrder.OwnerId;

            } 
        }

        if(!customerOrder.isEmpty()) {
            for (Order newOrder : customerOrder) {                
                Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
                System.debug('## Status : '+newOrder.Status);
                System.debug('## orderItemCount__c : '+newOrder.orderItemCount__c);
                System.debug('## orderItemUnderReviewCount__c : '+newOrder.orderItemUnderReviewCount__c);
                System.debug('## approvalReason__c : '+newOrder.approvalReason__c);
                System.debug('## isInApprovalProcess__c : '+newOrder.isInApprovalProcess__c);
                System.debug('## isRefused__c : '+newOrder.isRefused__c);
                System.debug('## isValid__c : '+newOrder.isValid__c);

                // Mise à jour données si signature électronique
                if(Trigger.isInsert && signeaSignerMap != null && signeaSignerMap.get(newOrder.Id) != null) {
                    Date tempCustomerSignedDate;
                    Date tempSignedDate;
                    for(Signea__signer__c signeaSigner : signeaSignerMap.get(newOrder.Id)) {
                        System.debug('## Signea: ' + signeaSigner.Signea__Position__c+' - '+signeaSigner.Signea__Account__c+' - '+signeaSigner.Signea__Contact__c+' - '+signeaSigner.Signea__consent_date__c);
                        Date signedDate = Date.valueOf(signeaSigner.Signea__consent_date__c);
                        if(signeaSigner.Signea__Position__c == 1) {
                            newOrder.companySigned__c = signeaSigner.Signea__User__c;
                            newOrder.companySignedDate__c = (signedDate != null) ? signedDate : newOrder.companySignedDate__c;
                        } else if(signeaSigner.Signea__Position__c == 2){
                            newOrder.customerSigned__c = (signeaSigner.Signea__Account__c != null) ? signeaSigner.Signea__Account__r.PersonContactId : signeaSigner.Signea__Contact__c;
                            tempCustomerSignedDate = signedDate;
                            newOrder.customerSignedDate__c = (signedDate != null) ? signedDate : newOrder.customerSignedDate__c;
                        } else if(signeaSigner.Signea__Position__c > 2){
                            if(tempCustomerSignedDate <= signedDate) {
                                tempCustomerSignedDate = signedDate;
                                newOrder.customerSignedDate__c = (tempCustomerSignedDate != null) ? tempCustomerSignedDate : newOrder.customerSignedDate__c;
                            }
                        }
                        
                        if(tempSignedDate <= Date.valueOf(signeaSigner.Signea__consent_date__c) || tempSignedDate == null) {
                            tempSignedDate = Date.valueOf(signeaSigner.Signea__consent_date__c);
                            newOrder.EffectiveDate = (tempSignedDate != null) ? tempSignedDate : newOrder.EffectiveDate;
                        }
                    }
                }

                System.debug('## quoteCPQLineCount__c : '+newOrder.quoteCPQLineCount__c);

                System.debug('## Status : '+newOrder.Status);
                System.debug('## approvalReason__c : '+newOrder.approvalReason__c);
                System.debug('## QuoteId : '+newOrder.QuoteId);
                System.debug('## orderItemCount__c : '+newOrder.orderItemCount__c);
                System.debug('## orderItemUnderReviewCount__c : '+newOrder.orderItemUnderReviewCount__c);
                System.debug('## SBQQ__Quote__c : '+newOrder.SBQQ__Quote__c);
                System.debug('## orderItemCount__c : '+newOrder.orderItemCount__c);
                System.debug('## quoteCPQLineCount__c : '+newOrder.quoteCPQLineCount__c);
                System.debug('## isValid__c : '+newOrder.isValid__c);
                // Passage au statut Validé si pas d'approval process à exécuter
                if( newOrder.Status == Constants.ORDER_STATUS_REGISTERED && (newOrder.cpqQuoteType__c == 'SAV' || String.isBlank(newOrder.approvalReason__c))
                    && (
                        (String.isNotBlank(newOrder.QuoteId) && newOrder.orderItemCount__c > 0 && newOrder.orderItemUnderReviewCount__c == 0)
                        || (String.isNotBlank(newOrder.SBQQ__Quote__c) && newOrder.orderItemCount__c > 0 && newOrder.orderItemCount__c == newOrder.quoteCPQLineCount__c)
                    )  
                ){
                    System.debug('## No Approval to execute, auto validation: '+newOrder.Id);
                    newOrder.isValid__c = true;
                }

                System.debug('## Status : '+newOrder.Status);
                System.debug('## isValid__c : '+newOrder.isValid__c);
       
                if((newOrder.cpqQuoteType__c == 'SAV')) {
                    newOrder.Type = 'Commande SAV';
                    if(Trigger.isInsert) {
                        newOrder.Status = Constants.ORDER_STATUS_REGISTERED;
                        newOrder.isValid__c = false;
                    }
                    /*List<Case> caseList = caseMap.get(newOrder.SBQQ__Quote__c);
                    for(Case newCase : caseList) {
                        newCase.customerOrder__c = newOrder.Id;
                        casesToUpdate.add(newCase);
                    }*/
                }
                      
                // Mise à jour des informations du compte à la création des commandes client
                if(Trigger.isBefore && (Trigger.isInsert || (Trigger.isUpdate && oldOrder != null && oldOrder.AccountId != newOrder.AccountId)) ) {
                    if(String.isNotBlank(newOrder.AccountId) && accountMap.get(newOrder.AccountId) != null){

                        if(String.isBlank(newOrder.BillToContactId)) {
                            newOrder.BillToContactId = accountMap.get(newOrder.AccountId).contactParDefaut__c;
                        }
                        if(String.isBlank(newOrder.ShipToContactId)) {
                            newOrder.ShipToContactId = accountMap.get(newOrder.AccountId).contactParDefaut__c;
                        }
                        if(String.isBlank(newOrder.billingName__c)) {
                            newOrder.billingName__c = accountMap.get(newOrder.AccountId).Name;
                        }
                        if(String.isBlank(newOrder.shippingName__c)) {
                            newOrder.shippingName__c = accountMap.get(newOrder.AccountId).Name;
                        }
                    }
                }

                // Mise à jour de la date d'activation historique
                if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) && newOrder.ActivatedDate != null && newOrder.firstActivatedDate__c == null ) {
                    newOrder.firstActivatedDate__c = newOrder.ActivatedDate;
                    System.debug('## First ActivatedDate: '+newOrder.firstActivatedDate__c);
                }
                if(Trigger.isBefore && Trigger.isUpdate && newOrder.ActivatedDate != null && newOrder.firstActivatedDate__c != null) {
                    newOrder.ActivatedDate = newOrder.firstActivatedDate__c;
                    System.debug('## New ActivatedDate: '+newOrder.ActivatedDate);
                }
                // Mise à jour champ copie de propriétaire
                newOrder.owner__c = newOrder.OwnerId;

                // Mise à jour au statut pour autorisation en passage en ECI 
                if(newOrder.installationCompletionDate__c != null && newOrder.installationCompletionDate__c >= Date.today().addMonths(-1) && newOrder.installationCompletionDate__c != oldOrder.installationCompletionDate__c){
                    //newOrder.passageECI__c = true;
                }
            }
        }

        if(!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }

        
        System.debug('### FIN TR020_Order.applyDataUpdateRules');        
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les commandes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Order.applyStatusUpdateRules');
        
        List<Order> customerOrder = new List<Order>();
        List<Asset> assetList;
        List<Order> providerOrder = new List<Order>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        Map<String, Referencial__c> referencialMap = new Map<String, Referencial__c>();
        // Données pour les avenants
        Boolean getReferenceDatas = false;        
        String refMotifAvenantValidCode = PropertiesUtils.getStringValue('ref.motifAvenantValide.code', 'R-30');
        String refMotifAvenantRefuseCode = PropertiesUtils.getStringValue('ref.motifAvenantRefuse.code', 'R-31');
        
        // A - Initialisation des données intermédiaires 
        for (Order newOrder : (List<Order>)Trigger.new) {            
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);

            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) 
            {            
                if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID) {
                    customerOrder.add(newOrder);
                } else if(newOrder.RecordTypeId == PROVIDER_ORDER_RTID) {
                    providerOrder.add(newOrder);
                }
                // Si commande client avenant est validé ou refusé, récupération du référentiel
                if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID && newOrder.Type == Constants.ORDER_TYPE_AVENANT 
                    && oldOrder != null && (oldOrder.isValid__c != newOrder.isValid__c || oldOrder.isRefused__c != newOrder.isRefused__c) ) 
                {
                    getReferenceDatas = true;
                }
            }
        }

        // Récupération référentiel
        if(getReferenceDatas) {
            List<String> codeRefList = new List<String>();
            codeRefList.add(refMotifAvenantValidCode);
            codeRefList.add(refMotifAvenantRefuseCode);
            for (Referencial__c ref : [SELECT Id, KparKReference__c FROM Referencial__c WHERE KparKReference__c IN :codeRefList]) {
                referencialMap.put(ref.KparKReference__c, ref);
            }
        }

        // B - Application des règles de mise à jour 
        // Mise à jour pour les commandes fournisseurs
        if(!providerOrder.isEmpty()) {
            for (Order newOrder : providerOrder) { 
                Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
                
                // Vérification des valeurs des Rollups pour le changement de statut
                // productLegacyCount__c permet de ne pas recalculer le statut pour les commandes FRS non lettrée afin de ne pas bloquer l'ajout de lignes
                if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) /*&& newOrder.productLegacyCount__c == 0*/) {   
                    System.debug('## Change status for provider order: ' + newOrder.Id);
                    // Ne pas prendre en compte les lignes annulées
                    Decimal nbOrderItemNotCancelled = newOrder.orderItemCount__c - newOrder.cancelledOrderItemCount__c;
                    if((newOrder.cancelledOrderItemCount__c == newOrder.orderItemCount__c && newOrder.cancelledOrderItemCount__c > 0) 
                        || (newOrder.cancellingDate__c != null)) {
                        System.debug('## status 1');
                        newOrder.Status = Constants.ORDER_STATUS_CANCELLED;
                        newOrder.stageName__c = null;
                        // Alimentation de la date d'annulation si toutes les lignes sont annulées
                        if(newOrder.cancelledOrderItemCount__c == newOrder.orderItemCount__c && newOrder.cancelledOrderItemCount__c > 0) {
                            newOrder.cancellingDate__c = newOrder.maxCancellingDate__c;
                        }
                    } else if(newOrder.legacyInProgress__c) {
                        System.debug('## status 1c');
                        newOrder.Status = Constants.ORDER_STATUS_REGISTERED;
                        newOrder.stageName__c = 'Enregistrement';
                        newOrder.ActivatedDate = null;
                        newOrder.ActivatedBy = null;
                    } else if(newOrder.receivedDate__c != null && newOrder.paidOrderItemCount__c == nbOrderItemNotCancelled && newOrder.paidOrderItemCount__c > 0) {
                        System.debug('## status 2');
                        newOrder.Status = Constants.ORDER_STATUS_PAID;
                        newOrder.stageName__c = 'Facturation';
                    } else if(newOrder.billingDate__c != null && newOrder.billedOrderItemCount__c == nbOrderItemNotCancelled && newOrder.billedOrderItemCount__c > 0 &&
                             newOrder.deliveryOrderItemCount__c == nbOrderItemNotCancelled && newOrder.deliveryOrderItemCount__c > 0) { 
                        System.debug('## status 3');
                        newOrder.Status = Constants.ORDER_STATUS_BILLED;
                        newOrder.stageName__c = 'Facturation';
                    } else if (newOrder.deliveryOrderItemCount__c == nbOrderItemNotCancelled && newOrder.deliveryOrderItemCount__c > 0) {
                        System.debug('## status 4');
                        newOrder.Status = Constants.ORDER_STATUS_DELIVERED;
                        newOrder.stageName__c = 'Livraison';
                    } else if (newOrder.billingDate__c != null && newOrder.billedOrderItemCount__c == nbOrderItemNotCancelled && newOrder.billedOrderItemCount__c > 0 && 
                              newOrder.deliveryOrderItemCount__c == 0) {
                        System.debug('## status 5');
                        newOrder.Status = Constants.ORDER_STATUS_BILLEDNOTDELIVERED;
                        newOrder.stageName__c = 'Livraison';
                    } else if (newOrder.shippedOrderItemCount__c == nbOrderItemNotCancelled && newOrder.shippedOrderItemCount__c > 0) {
                        System.debug('## status 6');
                        newOrder.Status = Constants.ORDER_STATUS_DELIVERING;
                        newOrder.stageName__c = 'Livraison';
                    } else if (newOrder.manufacturedOrderItemCount__c == nbOrderItemNotCancelled && newOrder.manufacturedOrderItemCount__c > 0) {                            
                        System.debug('## status 7');
                        newOrder.Status = Constants.ORDER_STATUS_MANUFACTURED;
                        newOrder.stageName__c = 'Fabrication';
                    } else if (newOrder.inMakingOrderItemCount__c > 0) {                            
                        System.debug('## status 8');
                        newOrder.Status = Constants.ORDER_STATUS_MANUFACTURING;
                        newOrder.stageName__c = 'Fabrication';
                    } else if(newOrder.confirmedOrderItemCount__c == nbOrderItemNotCancelled && newOrder.confirmedOrderItemCount__c > 0) {                            
                        System.debug('## status 9');
                        newOrder.Status = Constants.ORDER_STATUS_CONFIRMED;
                        newOrder.stageName__c = 'Confirmation';
                    } else if (newOrder.transmissionDate__c != null) {
                        System.debug('## status 10');
                        newOrder.Status = Constants.ORDER_STATUS_TRANSMITTED;
                        newOrder.stageName__c = 'Confirmation';
                    } else if (newOrder.ActivatedDate != null) {
                        System.debug('## status 11');
                        newOrder.Status = Constants.ORDER_STATUS_VALIDATED;
                        newOrder.stageName__c = 'Enregistrement';
                    }
                    System.debug('## Order Status: '+newOrder.Status);
                }
            }
        }

        // Mise à jour pour les commandes client
        if(!customerOrder.isEmpty()) {
            for (Order newOrder : customerOrder) {                
                Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
                
                // Vérification des valeurs pour le changement de statut
                if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
                    System.debug('## Change status for customer order: ' + newOrder.Id);
                    // Gestion statut des commandes client non avenant
                    if(newOrder.Type != Constants.ORDER_TYPE_AVENANT) {
                        if(newOrder.cancellingDate__c != null && String.isNotBlank(newOrder.cancellingReason__c)) {
                            System.debug('## status 1');
                            newOrder.Status = Constants.ORDER_STATUS_CANCELLED;
                            newOrder.stageName__c = null;
                        } else if(newOrder.suspendDate__c != null && !newOrder.amendingInProgress__c) {
                            System.debug('## status 1b');
                            newOrder.Status = Constants.ORDER_STATUS_SUSPENDED;
                            newOrder.stageName__c = null;
                        } else if(newOrder.assetCount__c != null  && newOrder.assetCount__c !=0
                                && newOrder.installedOrCancelledAssetCount__c == newOrder.assetCount__c 
                                && newOrder.netBalance__c==0 && newOrder.invoiceAccountingRefCount__c > 0){
                            System.debug('## status 2');
                            newOrder.Status = Constants.ORDER_STATUS_CLOSED;
                        } else if(newOrder.amendingInProgress__c) {
                            System.debug('## status 3');
                            newOrder.Status = Constants.ORDER_STATUS_AMENDING;
                            newOrder.stageName__c = 'Enregistrement';
                            newOrder.ActivatedDate = null;
                            newOrder.ActivatedBy = null;
                        } else if(newOrder.assetCount__c != null  && newOrder.assetCount__c != 0
                                  && newOrder.installedOrCancelledAssetCount__c == newOrder.assetCount__c) {
                            System.debug('## status 4');
                            newOrder.Status = Constants.ORDER_STATUS_INSTALLED;
                            newOrder.stageName__c = 'Installation';
                            newOrder.cancelProcess__c = false;
                        } else if(newOrder.providerOrderCount__c > 0 && newOrder.providerOrderCount__c == newOrder.deliveredProviderOrderCount__c) {
                            System.debug('## status 5');
                            newOrder.Status = Constants.ORDER_STATUS_DELIVERED;
                            newOrder.stageName__c = 'Livraison';
                            newOrder.cancelProcess__c = false;
                        } else if(newOrder.providerOrderCount__c > 0 && newOrder.providerOrderCount__c == newOrder.providerOrderOrderedCount__c) {
                            System.debug('## status 6');
                            newOrder.Status = Constants.ORDER_STATUS_ORDERED;
                            newOrder.stageName__c = 'Commande';
                            newOrder.cancelProcess__c = false;
                        } else if(newOrder.controllableAssetCount__c == newOrder.controlledAssetCount__c && newOrder.controllableAssetCount__c > 0) {
                            System.debug('## status 7');
                            newOrder.Status = Constants.ORDER_STATUS_CONTROLLED;
                            newOrder.stageName__c = 'Contrôle';
                            newOrder.cancelProcess__c = false;
                        } else if (newOrder.isValid__c == true) {
                            System.debug('## status 8');
                            newOrder.Status = Constants.ORDER_STATUS_VALIDATED;
                            newOrder.stageName__c = 'Enregistrement';
                            newOrder.cancelProcess__c = false;
                        } else {
                            System.debug('## status 9');
                            newOrder.Status = Constants.ORDER_STATUS_REGISTERED;
                            newOrder.stageName__c = 'Enregistrement';
                            newOrder.cancelProcess__c = false;
                        }
                    // Gestion statut des commandes client avenant
                    } else {
                        Referencial__c cancellingReasonValided = referencialMap.get(refMotifAvenantValidCode);
                        Referencial__c cancellingReasonRefused = referencialMap.get(refMotifAvenantRefuseCode);
                        if (newOrder.isValid__c == true) {
                            System.debug('## status 1');
                            newOrder.Status = Constants.ORDER_STATUS_CANCELLED;
                            newOrder.stageName__c = null;
                            newOrder.cancellingDate__c = Date.today();
                            if(newOrder.cancellingReason__c == null) {
                                newOrder.cancellingReason__c = (cancellingReasonValided != null) ? cancellingReasonValided.Id : null;
                            }
                        } else if (newOrder.isRefused__c == true) {
                            System.debug('## status 2');
                            newOrder.Status = Constants.ORDER_STATUS_CANCELLED;
                            newOrder.stageName__c = null;
                            newOrder.cancellingDate__c = Date.today();
                            if(newOrder.cancellingReason__c == null) {
                                newOrder.cancellingReason__c = (cancellingReasonRefused != null) ? cancellingReasonRefused.Id : null;
                            }
                        } else if (String.isBlank(newOrder.cancellingReason__c)){
                            System.debug('## status 3');
                            newOrder.Status = Constants.ORDER_STATUS_REGISTERED;
                            newOrder.stageName__c = 'Enregistrement'; 
                            newOrder.cancelProcess__c = false;
                        }
                    }
                    System.debug('## Order Status: '+newOrder.Status);
                }
            }
        }
        System.debug('### FIN TR020_Order.applyStatusUpdateRules');
    }
}