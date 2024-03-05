//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_GlobalPipelineGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/01/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_GlobalPipelineGeneratePDF {
    private static final String ONC_IMPOSSIBILITY_RTID = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
    private static final String SERVICEAPPOINTMENT_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String ORDER_CUSTOMER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final String ORDER_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug.pipeline', false);
    private static final String PDF_TEMPLATEID = PropertiesUtils.getStringValue('merkure.pipeline.templateId', '');
    private static final String EXCEL_TEMPLATEID = PropertiesUtils.getStringValue('merkure.pipeline.templateId.excel', '');

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param serviceEntityId Id du dépot
    * @param generationDate Nom de la pièce jointe
    * @param orderStatus Liste des statuts GC à exporter
    * @param docFormat Format du document à générer (PDF ou Excel)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderDocumentPDF(Id serviceEntityId, Date generationDate, List<String> orderStatus, String docFormat) {
        System.debug('### DEBUT LWC_GlobalPipelineGeneratePDF.renderDocumentPDF');
        System.debug('## serviceEntityId: '+serviceEntityId);
        System.debug('## generationDate: '+generationDate);
        System.debug('## orderStatus: '+orderStatus);
        System.debug('## docFormat: '+docFormat);
        PipelineObject data;
        String result;
        Boolean docExist = false;
        List<String> cdocIdList = new List<String>();
        Blob documentBlob = null;
        String filename;

        try {
            // Récupération information entité
            Account entity = [SELECT Id, Name FROM Account WHERE Id = :serviceEntityId];
            // Define the templateId to use            
            String templateId = defineTemplateId(docFormat); 

            String dateFormated = DateTime.newInstance(generationDate.year(),generationDate.month(),generationDate.day()).format('yyyy/MM/dd');
            String docTypeName = (docFormat.equalsIgnoreCase('xlsx')) ? 'EXCEL' : 'PDF';
            filename = 'Pipeline '+docTypeName+' - '+entity.Name+' - '+ dateFormated; 

            // Récupération des infos pour construction de l'objet Pipeline
            data = getPipelineInformation(entity, generationDate, orderStatus);

            // Appel API Merkure API
            documentBlob = Utils_APIMerkure.renderDocument(templateId, data, docFormat, null);
            // Lien du document vers l'enregistrement     
            result = linkDocumentToRecord(entity, filename, docFormat, documentBlob);

            // ONLY FOR DEBUG - Création du JSON en tant que document
            if(API_DEBUG) {
                String payloadString = Utils_APIMerkure.constructHttpPayload(templateId, data, docFormat, null);
                Document d = new Document(Name = filename, 
                                            Body = Blob.valueOf(payloadString),
                                            ContentType = 'text/plain',
                                            FolderId = '00lD0000001ygqO',
                                            Type = 'txt');
                insert d;
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_GlobalPipelineGeneratePDF.renderDocumentPDF');
        return result;
    }

    private static String defineTemplateId(String docFormat) {
        String templateId;
        // Define the templateId to use          
        if(docFormat.equalsIgnoreCase('xlsx')) {
            templateId = EXCEL_TEMPLATEID;
        } else {
            templateId = PDF_TEMPLATEID;
        }
        return templateId;
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF au dépot en tant que Salesforce File (ContentDocument)
    * @param entity Dépot
    * @param docName Nom du document
    * @param docFormat Format du document à générer (PDF ou Excel)
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Account entity, String docName, String docFormat, Blob document) {
        System.debug('### DEBUT LWC_GlobalPipelineGeneratePDF.linkDocumentToRecord');
        System.debug('## serviceEntityId: '+entity.Id); 
        System.debug('## docName: '+docName);
        String result;

        try {  
            // Link the document link a content document            
            String filename = docName + '.' + docFormat;

            // Si un fichier avec le même nom existe déjà lié au record, alors on supprime
            Set<String> docIdToCheck = new Set<String>();
            for(ContentDocumentLink ctLinkToDelete : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :entity.Id]) {
                docIdToCheck.add(ctLinkToDelete.ContentDocumentId);
            }
            System.debug('## docIdToCheck: '+docIdToCheck);
            if(!docIdToCheck.isEmpty()) {
                List<ContentDocument> docToDelete = new List<ContentDocument>();
                for(ContentVersion ctVerToDelete : [SELECT Id, ContentDocumentId FROM ContentVersion 
                                                        WHERE Title = :filename AND ContentDocumentId IN :docIdToCheck]) {
                    System.debug('## Document to delete: '+ctVerToDelete.ContentDocumentId);
                    docToDelete.add(new ContentDocument(Id = ctVerToDelete.ContentDocumentId));
                }
                if(!docToDelete.isEmpty()) {
                    delete docToDelete;
                }
            }

            // Création document et lien
            result = Utils_APIMerkure.createContentDocument(entity.Id, filename, document, 'Pipeline '+docFormat, false);
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_GlobalPipelineGeneratePDF.linkDocumentToRecord');
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les informations des commandes clients et enregistrements enfants en JSON
    * @param entity Dépot pour générer le Pipeline
    * @param generationDate Date de génération
    * @return PipelineObject Objet contenant les informations du pipeline
    */
    public static PipelineObject getPipelineInformation(Account entity, Date generationDate, List<String> orderStatusList) {
        System.debug('### DEBUT LWC_GlobalPipelineGeneratePDF.getQuoteInformation');
        PipelineObject result = new PipelineObject();
        List<Order> ordersList = new List<Order>();
        Set<Id> ordersIdList = new Set<Id>(); // Obligatoire pour récupérer les commentaires
        Map<String, List<Order>> providerOrdersByOrderMap = new Map<String, List<Order>>();
        Map<String, OrderNonCompliance__c> nccOrderMap = new Map<String, OrderNonCompliance__c>();
        Map<String, Asset> lastAssetControlOrderMap = new Map<String, Asset>();
        Map<String, List<Asset>> assetsOrderMap = new Map<String, List<Asset>>();
        Map<String, ServiceAppointment> saControlOrderMap = new Map<String, ServiceAppointment>();
        Map<String, ServiceAppointment> saInstallOrderMap = new Map<String, ServiceAppointment>();
        Map<String, AssignedResource> assignedResOrderMap = new Map<String, AssignedResource>();
        Map<String, List<AccountingPiece__c>> accPiecesAdvOrderMap = new Map<String, List<AccountingPiece__c>>();
        Map<String, List<AccountingPiece__c>> accPiecesDateOrderMap = new Map<String, List<AccountingPiece__c>>();

        // *************** Récupération des données ********************
        // *************************************************************
        if(orderStatusList == null || orderStatusList.isEmpty()) {
            orderStatusList = new List<String>{'Non métrable','Non métré non programmé','Non métré programmé',
                                                'Non commandable','Non commandé','Non confirmé','Non livré non préparé',
                                                'Non livré non programmé','Non livré programmé',
                                                'Non installable', 'Non installé non préparé', 'Non installé non programmé',
                                                'Non installé programmé'}; 
        } 

        // Récupération des commandes clients
        // Si date de génération est aujourd'hui, on récupère les commandes en cours
        // Sinon on récupère par rapport à l'objet OrderStatusHistory__c 
        if(generationDate == Date.today()) {
            for(Order ord : [SELECT Id, OrderNumber, legacyReference__c, serviceEntity__r.KparKReference__c, serviceEntity__r.Name,
                                billingName__c, financingMethod__r.KparKReference__c, financingMethod__c, legacyActivationDate__c, ActivatedDate,
                                pretaxAmount__c, amount__c, expectedAdvancePaymentAmount__c, advancePaymentPercent1__c, advancePaymentPercent2__c,
                                receivedAdvancePaymentAmount__c, salesOwnerName__c, salesOwnerMagName__c, LastModifiedDate, isLegacy__c, Type, oldCompositeStatus__c, 
                                Status, maxCommercialDelay__c, controlComments__c,  orderComments__c, confirmationComments__c,  deliveryComments__c, installComments__c,
                                remunerationComments__c, pendingBalanceComments__c, uncollectedComments__c, cancellationComments__c
                                FROM Order
                                WHERE RecordTypeId = :ORDER_CUSTOMER_RTID AND Type != 'Avenant'
                                AND serviceEntity__c = :entity.Id AND oldCompositeStatus__c IN :orderStatusList]) {
                ordersList.add(ord);
                ordersIdList.add(ord.Id);
            }
        } else {
            // On récupère selon l'objet OrderStatusHistory__c 
            for(OrderStatusHistory__c ordHistory : [SELECT Id, customerOrder__c, oldCompositeStatus__c, status__c, applicationDate__c
                                                        FROM OrderStatusHistory__c WHERE status__c = :orderStatusList 
                                                        AND applicationDate__c >= :generationDate AND applicationDate__c <= :generationDate]) {
                ordersIdList.add(ordHistory.customerOrder__c);
            }
            // Récupération des commandes clients selon l'historique
            if(!ordersIdList.isEmpty()) {
                for(Order ord : [SELECT Id, OrderNumber, legacyReference__c, serviceEntity__r.KparKReference__c, serviceEntity__r.Name,
                                        billingName__c, financingMethod__r.KparKReference__c, financingMethod__c, legacyActivationDate__c, ActivatedDate,
                                        pretaxAmount__c, amount__c, expectedAdvancePaymentAmount__c, advancePaymentPercent1__c, advancePaymentPercent2__c,
                                        receivedAdvancePaymentAmount__c, salesOwnerName__c, salesOwnerMagName__c, LastModifiedDate, isLegacy__c, Type, oldCompositeStatus__c, 
                                        Status, maxCommercialDelay__c, controlComments__c,  orderComments__c, confirmationComments__c,  deliveryComments__c, installComments__c,
                                        remunerationComments__c, pendingBalanceComments__c, uncollectedComments__c, cancellationComments__c
                                    FROM Order
                                    WHERE RecordTypeId = :ORDER_CUSTOMER_RTID AND Type != 'Avenant' 
                                    AND Id = :ordersIdList]) {
                    ordersList.add(ord);
                }
            }
        }
        System.debug('## ordersList: '+ordersList.size());

        if(!ordersList.isEmpty()) {
            // Récupération des commandes fournisseurs pour les commandes clients
            List<Order> providerOrdList = new List<Order>();
            for(Order providerOrd : [SELECT Id, OrderNumber, legacyReference__c, provider__r.KparKReference__c, provider__r.Name, parentOrder__c ,
                                        legacyResponsability__c, Description, transmissionDate__c, confirmationDate__c, maxEstimatedDeliveryDate__c,
                                        estimatedDeliveryDate__c, deliveryDate__c, estimatedTotalCost__c, pretaxAmount__c, controlComments__c,  
                                        orderComments__c, confirmationComments__c,  deliveryComments__c, installComments__c,
                                        remunerationComments__c, pendingBalanceComments__c, uncollectedComments__c, cancellationComments__c
                                FROM Order
                                WHERE RecordTypeId = :ORDER_PROVIDER_RTID AND parentOrder__c IN :ordersList]) {
                if(providerOrdersByOrderMap.get(providerOrd.parentOrder__c) == null) {
                    providerOrdList = new List<Order>();
                } else {
                    providerOrdList = providerOrdersByOrderMap.get(providerOrd.parentOrder__c);
                }
                providerOrdList.add(providerOrd);
                providerOrdersByOrderMap.put(providerOrd.parentOrder__c, providerOrdList);            
                ordersIdList.add(providerOrd.Id); // Pour récupération commentaire
            }
            System.debug('## providerOrdersByOrderMap: '+providerOrdersByOrderMap.size());

            // Récupération des NCC
            for(OrderNonCompliance__c ncc : [SELECT Id, customerOrder__c, Name, CreatedDate 
                                                FROM OrderNonCompliance__c 
                                                WHERE RecordTypeId = :ONC_IMPOSSIBILITY_RTID AND customerOrder__c IN :ordersList
                                                AND closeDate__c = null AND cancellationDate__c = null ORDER BY CreatedDate] ) {
                nccOrderMap.put(ncc.customerOrder__c, ncc);
            }
            System.debug('## nccOrderMap: '+nccOrderMap.size());

            // Récupération des Asset (si pipeline métrage)
            List<Asset> assetsList = new List<Asset>();
            for(Asset assetOrd : [SELECT Id, customerOrder__c, controlDate__c, controlResource__r.user__r.Name
                                    FROM Asset
                                    WHERE customerOrder__c IN :ordersList
                                    AND ParentId = null AND cancellingReason__c = null
                                    ORDER BY controlDate__c DESC] ) {
                lastAssetControlOrderMap.put(assetOrd.customerOrder__c, assetOrd); // Dernier asset métré
                // Liste de tous les assets métrés des commandes
                if(assetsOrderMap.get(assetOrd.customerOrder__c) == null) {
                    assetsList = new List<Asset>();
                } else {
                    assetsList = assetsOrderMap.get(assetOrd.customerOrder__c);
                }
                assetsList.add(assetOrd);
                assetsOrderMap.put(assetOrd.customerOrder__c, assetsList);
            }
            System.debug('## lastAssetControlOrderMap: '+lastAssetControlOrderMap.size());
            System.debug('## assetsOrderMap: '+assetsOrderMap.size());

            // Récupération du prochain RDV Métrage (si pipeline non métré)
            for(ServiceAppointment saControlOrd : [SELECT Id, SchedStartTime, customerOrder__c 
                                    FROM ServiceAppointment WHERE customerOrder__c IN :ordersList AND RecordTypeId = :SERVICEAPPOINTMENT_RTID 
                                    AND (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL)
                                    AND Status NOT IN (:Constants.RDV_FSL_TERMINE, :Constants.RDV_FSL_DEBRIEFE, :Constants.RDV_FSL_ANNULE)
                                    AND SchedStartTime >= TODAY ORDER BY SchedStartTime] ) {
                saControlOrderMap.put(saControlOrd.customerOrder__c, saControlOrd);
            }
            System.debug('## saControlOrderMap: '+saControlOrderMap.size());

            // Récupération du prochain RDV Installation (si pipeline non installé)
            for(ServiceAppointment saControlOrd : [SELECT Id, SchedStartTime, customerOrder__c 
                                    FROM ServiceAppointment WHERE customerOrder__c IN :ordersList AND RecordTypeId = :SERVICEAPPOINTMENT_RTID 
                                    AND (WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION)
                                    AND Status NOT IN (:Constants.RDV_FSL_TERMINE, :Constants.RDV_FSL_DEBRIEFE, :Constants.RDV_FSL_ANNULE)
                                    AND SchedStartTime >= TODAY ORDER BY SchedStartTime] ) {
                saInstallOrderMap.put(saControlOrd.customerOrder__c, saControlOrd);
            }
            System.debug('## saInstallOrderMap: '+saInstallOrderMap.size());

            // Récupération des ressources des RDV
            if(!saControlOrderMap.isEmpty() && !saInstallOrderMap.isEmpty()) {
                for(AssignedResource saAssignedOrd : [SELECT Id, ServiceAppointmentId, ServiceResource.user__r.EmployeeNumber, 
                                                            ServiceResource.user__r.Name, ServiceResource.fsl_SGID__c
                                                        FROM AssignedResource
                                                        WHERE (ServiceAppointmentId IN :saControlOrderMap.values() OR ServiceAppointmentId IN :saInstallOrderMap.values())
                                                        AND fsl_typeRessourceAttribuee__c = 'Principale'] ) {
                    assignedResOrderMap.put(saAssignedOrd.ServiceAppointmentId, saAssignedOrd);
                }
                System.debug('## assignedResOrderMap: '+assignedResOrderMap.size());
            }

            // Récupération des pièces comptables
            List<AccountingPiece__c> accPiecesList = new List<AccountingPiece__c>();
            List<AccountingPiece__c> accPieces2List = new List<AccountingPiece__c>();
            for(AccountingPiece__c accPiece : [SELECT Id, Name, accountingDate__c, netAmount__c, order__c, 
                                                    RecordTypeId, invoice__c
                                                    FROM AccountingPiece__c WHERE order__c IN :ordersList
                                                    ORDER BY Name] ) 
            {
                // Pieces pour calcul des acomptes
                if(String.isBlank(accPiece.invoice__c) && accPiece.accountingDate__c == null) {
                    if(accPiecesAdvOrderMap.get(accPiece.order__c) == null) {
                        accPiecesList = new List<AccountingPiece__c>();
                    } else {
                        accPiecesList = accPiecesAdvOrderMap.get(accPiece.order__c);
                    }
                    accPiecesList.add(accPiece);
                    accPiecesAdvOrderMap.put(accPiece.order__c, accPiecesList);
                }
                // Pieces pour calcul de la date pose 
                if(accPiece.RecordTypeId == DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPT_RT)) {
                    if(accPiecesDateOrderMap.get(accPiece.order__c) == null) {
                        accPieces2List = new List<AccountingPiece__c>();
                    } else {
                        accPieces2List = accPiecesDateOrderMap.get(accPiece.order__c);
                    }
                    accPieces2List.add(accPiece);
                    accPiecesDateOrderMap.put(accPiece.order__c, accPieces2List);
                }
            }
            System.debug('## accPiecesAdvOrderMap: '+accPiecesAdvOrderMap.size());
            System.debug('## accPiecesDateOrderMap: '+accPiecesDateOrderMap.size());
            
            // Récupération des ContentNote (commentaire)
            Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
            Set<String> documentsIdList = new Set<String>();
            List<String> docLinkList = new List<String>();
            for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN :ordersIdList]) {
                if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                    docLinkList = new List<String>();
                } else {
                    docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                }
                docLinkList.add(cdLink.ContentDocumentId);
                documentsIdList.add(cdLink.ContentDocumentId);
                docLinkMap.put(cdLink.LinkedEntityId, docLinkList);
            }
            System.debug('## docLinkMap: '+docLinkMap);
            System.debug('## documentsIdList: '+documentsIdList);
            // Execute SOQL ContentVersion
            Map<String, String> docVersionMap = new Map<String, String>();
            for(ContentVersion cdVersion : [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion 
                                                WHERE ContentDocumentId IN :documentsIdList AND FileType = 'SNOTE' 
                                                AND IsLatest=true ORDER BY LastModifiedDate DESC]) {
                Blob contentFileBody = cdVersion.VersionData;
                String contentAsString = contentFileBody.toString();
                docVersionMap.put(cdVersion.ContentDocumentId, contentAsString.stripHtmlTags());
            }
            System.debug('## docVersionMap: '+docVersionMap);

            // *************** Création objet de sortie ********************
            // *************************************************************
            result.generationDate = System.now();
            result.documentType = 'Pipeline';
            result.entityName = entity.Name;

            // Création de la MAP des groupes de status
            Map<String, String> statusGroupMap = createStatusGroupMap();

            // Pour chaque commande, création d'un record JSON et assignation du groupe de status
            Map<String, List<OrderObject>> orderObjectMapList = new Map<String, List<OrderObject>>();
            List<OrderObject> orderObjectList = new List<OrderObject>();
            for(Order newOrder : ordersList) {
                System.debug('## --------- Order: '+newOrder);
                OrderObject ordObj = constructOrderObject(newOrder, providerOrdersByOrderMap, nccOrderMap, lastAssetControlOrderMap, 
                                                            assetsOrderMap, saControlOrderMap, saInstallOrderMap,assignedResOrderMap,
                                                            accPiecesAdvOrderMap, accPiecesDateOrderMap, docLinkMap, docVersionMap);
                // Assignation de la commande au groupe de statut
                String statusGroup = statusGroupMap.get(newOrder.oldCompositeStatus__c);                
                if(orderObjectMapList.get(statusGroup) == null) {
                    orderObjectList = new List<OrderObject>();
                } else {
                    orderObjectList = orderObjectMapList.get(statusGroup);
                }
                orderObjectList.add(ordObj);
                orderObjectMapList.put(statusGroup, orderObjectList);
            }

            // Création des groupes de status
            List<StatusGroup> statusGrpObjectList = new List<StatusGroup>();
            for(String statusGroupName : orderObjectMapList.keySet()) {
                System.debug('## -- Status Group: '+statusGroupName);
                StatusGroup statGrpObj = new StatusGroup();
                List<OrderObject> orderObjList = orderObjectMapList.get(statusGroupName);
                System.debug('## Nb Order: '+orderObjList.size());
                // Alimentation de l'objet JSON
                statGrpObj.groupName = statusGroupName;
                statGrpObj.CustomerOrders = orderObjList;
                statusGrpObjectList.add(statGrpObj);
            }
            result.StatusGroups = statusGrpObjectList;
        }

        System.debug('### FIN LWC_GlobalPipelineGeneratePDF.getQuoteInformation');
        return result;
    }

    /**
    * @description Fonction pour construire la MAP des groupes de status en fonction du status
    * @return Map<String, String> Map des groupes de status en fonction du status
    */
    public static Map<String, String> createStatusGroupMap() {
        Map<String, String> result = new Map<String, String>();
        String nonMetreGroup = 'Non métrés';
        String nonCommandeGroup = 'Non commandés';
        String nonConfirmeGroup = 'Non confirmés';
        String nonLivreGroup = 'Non livrés';
        String nonInstalleGroup = 'Non installés';

        // Construction map Status/Groupe
        result.put('Non métrable', nonMetreGroup);
        result.put('Non métré non programmé', nonMetreGroup);
        result.put('Non métré programmé', nonMetreGroup);
        result.put('Non commandable', nonCommandeGroup);
        result.put('Non commandé', nonCommandeGroup);
        result.put('Non confirmé', nonConfirmeGroup);
        result.put('Non livré non préparé', nonLivreGroup);
        result.put('Non livré non programmé', nonLivreGroup);
        result.put('Non livré programmé', nonLivreGroup);
        result.put('Non installable', nonInstalleGroup);
        result.put('Non installé non préparé', nonInstalleGroup);
        result.put('Non installé non programmé', nonInstalleGroup);
        result.put('Non installé programmé', nonInstalleGroup);

        return result;
    }
    
    /**
    * @description Fonction pour construire l'objet JSON pour une commande client en fonction de ses enfants
    * @param newOrder Commande client
    * @param providerOrdersByOrderMap Liste des commandes fournisseurs
    * @param nccOrderMap Dernière non conformité commande
    * @param lastAssetControlOrderMap Dernier actif métré
    * @param assetsOrderMap Liste des actifs métrés
    * @param saControlOrderMap Prochain RDV de métrage
    * @param saInstallOrderMap Prochain RDV d'installation
    * @param assignedResOrderMap Ressources des RDV
    * @param accPiecesAdvOrderMap Liste des pièces comptables pour calcul des acomptes
    * @param accPiecesDateOrderMap Liste des pièces comptables pour calcul date de pose
    * @param docLinkMap Liste des liens vers des documents/notes
    * @param docVersionMap Liste des derniers commentaires
    * @return OrderObject Objet contenant les informations d'une commande
    */
    public static OrderObject constructOrderObject(Order newOrder, Map<String, List<Order>> providerOrdersByOrderMap, Map<String, OrderNonCompliance__c> nccOrderMap,
                                                    Map<String, Asset> lastAssetControlOrderMap, Map<String, List<Asset>> assetsOrderMap, Map<String, ServiceAppointment> saControlOrderMap, 
                                                    Map<String, ServiceAppointment> saInstallOrderMap, Map<String, AssignedResource> assignedResOrderMap, 
                                                    Map<String, List<AccountingPiece__c>> accPiecesAdvOrderMap, Map<String, List<AccountingPiece__c>> accPiecesDateOrderMap, 
                                                    Map<String, List<String>> docLinkMap, Map<String, String> docVersionMap) 
    {
        System.debug('### DEBUT LWC_GlobalPipelineGeneratePDF.constructOrderObject');
        OrderObject ordObj = new OrderObject();

        // ** Init + Récupération des enregistrements enfants de la commande
        List<Order> providerOrdersList = providerOrdersByOrderMap.get(newOrder.Id);
        OrderNonCompliance__c nccRec = nccOrderMap.get(newOrder.Id);
        Asset assetRec = lastAssetControlOrderMap.get(newOrder.Id);
        ServiceAppointment saControlRec = saControlOrderMap.get(newOrder.Id);
        AssignedResource controlAssRessRec = null;
        ServiceAppointment saInstallRec = saInstallOrderMap.get(newOrder.Id);
        AssignedResource installAssRessRec = null;
        Date lastDeliveryDate = null;
        Date dateStat = null;
        List<AccountingPiece__c> accPiecesAdvList = accPiecesAdvOrderMap.get(newOrder.Id);
        List<AccountingPiece__c> accPiecesDateList = accPiecesDateOrderMap.get(newOrder.Id);
        List<Asset> assetsList = assetsOrderMap.get(newOrder.Id);

        // ** Date commande client
        if(newOrder.legacyActivationDate__c != null) {
            dateStat = newOrder.legacyActivationDate__c;
        } else if(newOrder.ActivatedDate != null) {
            dateStat = newOrder.ActivatedDate.date();
        }

        // ** Acompte
        Decimal advPaymentExpPercent;
        if(newOrder.advancePaymentPercent1__c != null && newOrder.advancePaymentPercent2__c != null) {
            advPaymentExpPercent = (newOrder.advancePaymentPercent1__c + newOrder.advancePaymentPercent2__c).setScale(2);
        }
        Decimal advPaymentPercent;
        if(newOrder.receivedAdvancePaymentAmount__c != null && newOrder.amount__c != null) {
            advPaymentPercent = ((newOrder.receivedAdvancePaymentAmount__c / newOrder.amount__c) * 100).setScale(2);
        }
        Decimal advPaymentTheoreticalAmount;
        if(accPiecesAdvList != null) {
            System.debug('## Traitement acompte théorique: '+accPiecesAdvList.size());   
            advPaymentTheoreticalAmount = 0;
            for(AccountingPiece__c accPiece : accPiecesAdvList) {
                advPaymentTheoreticalAmount = (accPiece.netAmount__c == null) ? advPaymentTheoreticalAmount : advPaymentTheoreticalAmount + accPiece.netAmount__c;
            }
            System.debug('## advPaymentTheoreticalAmount: '+advPaymentTheoreticalAmount);  
        }
        Decimal advPaymentTheoreticalPercent;
        if(advPaymentTheoreticalAmount != null && newOrder.amount__c != null) {
            advPaymentTheoreticalPercent = ((advPaymentTheoreticalAmount / newOrder.amount__c) * 100).setScale(2);
        }

        // ** Date théorique de pose
        Decimal accPieceTotalAmount;
        Date accPieceExpDateInstall;
        Date assetExpDateInstall;
        if(accPiecesDateList != null) {
            System.debug('## Traitement date théorique pose (AccPiece): '+accPiecesDateList.size());   
            accPieceTotalAmount = 0;
            // Récupération de la date comptable du dernier paiement de la commande
            for(AccountingPiece__c accPiece : accPiecesDateList) {
                accPieceTotalAmount = (accPiece.netAmount__c == null) ? accPieceTotalAmount : accPieceTotalAmount + accPiece.netAmount__c;
                if(accPieceTotalAmount >= newOrder.expectedAdvancePaymentAmount__c && accPieceExpDateInstall == null) {
                    accPieceExpDateInstall = accPiece.accountingDate__c;
                    break;
                }
            }
            System.debug('## accPieceExpDateInstall: '+accPieceExpDateInstall);  
        }
        if(assetsList != null) {
            System.debug('## Traitement date théorique pose (Asset): '+assetsList.size());   
            // Récupération de la date max de métrage
            for(Asset ast : assetsList) {
                if(assetExpDateInstall == null || (ast.controlDate__c != null && assetExpDateInstall < ast.controlDate__c)) {
                    assetExpDateInstall = ast.controlDate__c;
                    break;
                }
            }
            System.debug('## assetExpDateInstall: '+assetExpDateInstall);  
        }
        Date expectedInstallDate;
        // Récupération date max entre pieces ou asset
        if (assetExpDateInstall != null && accPieceExpDateInstall != null) {
            expectedInstallDate = (assetExpDateInstall > accPieceExpDateInstall) ? assetExpDateInstall : accPieceExpDateInstall;
        } else if (assetExpDateInstall != null) {
            expectedInstallDate = assetExpDateInstall;
        } else if (accPieceExpDateInstall != null) {
            expectedInstallDate = accPieceExpDateInstall;
        }
        // Ajout du délai commercial
        if(expectedInstallDate != null && newOrder.maxCommercialDelay__c != null) {
            expectedInstallDate.addDays(Integer.valueOf(newOrder.maxCommercialDelay__c));
        }
        System.debug('## expectedInstallDate: '+expectedInstallDate);  

        // ** NCC (OrderNonCompliance)
        if(nccRec != null) {
            System.debug('## Récupération NCC: '+nccRec);  
            ordObj.oncName = nccRec.Name;
            ordObj.oncDuration = nccRec.CreatedDate.date().daysBetween(Date.today());
        }

        // ** Premier métrage et métreur (Asset)
        if(assetRec != null) {
            System.debug('## Récupération premier métrage et métreur: '+assetRec);    
            ordObj.firstControlDate = assetRec.controlDate__c;
            ordObj.firstControlResource = assetRec.controlResource__r.user__r.Name;
        }

        // ** Prochain métrage (ServiceAppointment)
        if(saControlRec != null) {
            System.debug('## Récupération prochain métrage: '+saControlRec);    
            ordObj.nextControlDate = saControlRec.SchedStartTime.date();
            controlAssRessRec = assignedResOrderMap.get(saControlRec.Id);
        }
        // ** Prochain métreur (AssignedResource)
        if(controlAssRessRec != null) {
            System.debug('## Récupération prochain métreur: '+controlAssRessRec);    
            ordObj.nextControlResource = controlAssRessRec.ServiceResource.user__r.Name;
        }

        // ** Prochaine installation (ServiceAppointment)
        if(saInstallRec != null) {
            System.debug('## Récupération prochaine installation: '+saInstallRec);    
            ordObj.nextInstallDate = saInstallRec.SchedStartTime.date();
            installAssRessRec = assignedResOrderMap.get(saInstallRec.Id);
        }
        // ** Prochain installateur (AssignedResource)
        if(installAssRessRec != null) {
            System.debug('## Récupération prochain installateur: '+installAssRessRec);    
            ordObj.nextInstallResource = installAssRessRec.ServiceResource.fsl_SGID__c;
        }

        // ** Commentaire
        if(docLinkMap.get(newOrder.Id) != null) {
            String docId = docLinkMap.get(newOrder.Id)[0];
            // Récupération du texte
            if(docVersionMap.get(docId) != null) {          
                System.debug('## Récupération dernier commentaire: '+docId);          
                String comment = docVersionMap.get(docId);
                ordObj.comment = comment;
            }
        }

        // ** Liste des commandes fournisseurs
        if(providerOrdersList != null) {
            System.debug('## Traitement des commandes fournisseurs: '+providerOrdersList.size());   
            List<ProviderOrderObject> provOrdersObjList = new List<ProviderOrderObject>();
            for(Order providerOrder : providerOrdersList) {
                ProviderOrderObject provOrdObj = new ProviderOrderObject();
                provOrdObj.providerCode = providerOrder.provider__r.Name;
                provOrdObj.legacyResponsability = providerOrder.legacyResponsability__c;
                provOrdObj.description = providerOrder.Description;
                provOrdObj.transmissionDate = providerOrder.transmissionDate__c;
                provOrdObj.confirmationDate = providerOrder.confirmationDate__c;
                provOrdObj.estimatedDeliveryDate = providerOrder.estimatedDeliveryDate__c;
                provOrdObj.deliveryDate = providerOrder.deliveryDate__c;
                provOrdObj.isDelivered = (providerOrder.deliveryDate__c != null) ? true : false;
                provOrdObj.availableDate = providerOrder.maxEstimatedDeliveryDate__c;
                // Commentaires
                provOrdObj.controlComments = providerOrder.controlComments__c;
                provOrdObj.orderComments = providerOrder.orderComments__c;
                provOrdObj.confirmationComments = providerOrder.confirmationComments__c;
                provOrdObj.deliveryComments = providerOrder.deliveryComments__c;
                provOrdObj.installComments = providerOrder.installComments__c;
                provOrdObj.remunerationComments = providerOrder.remunerationComments__c;
                provOrdObj.pendingBalanceComments = providerOrder.pendingBalanceComments__c;
                provOrdObj.uncollectedComments = providerOrder.uncollectedComments__c;
                provOrdObj.cancellationComments = providerOrder.cancellationComments__c;

                // Calcul derniere date de livraison pour la commande client (date de livraison récente des commandes fournisseurs)
                if(lastDeliveryDate == null || (providerOrder.deliveryDate__c != null && lastDeliveryDate < providerOrder.deliveryDate__c)) {
                    lastDeliveryDate = providerOrder.deliveryDate__c;
                }
                if(lastDeliveryDate == null || (providerOrder.estimatedDeliveryDate__c != null && lastDeliveryDate < providerOrder.estimatedDeliveryDate__c)) {
                    lastDeliveryDate = providerOrder.estimatedDeliveryDate__c;
                }
                System.debug('## lastDeliveryDate: '+lastDeliveryDate);    

                // Commentaire
                if(docLinkMap.get(providerOrder.Id) != null) {
                    String docId = docLinkMap.get(providerOrder.Id)[0];
                    // Récupération du texte
                    if(docVersionMap.get(docId) != null) {          
                        System.debug('## Récupération dernier commentaire fournisseur: '+docId);          
                        String comment = docVersionMap.get(docId);
                        provOrdObj.comment = comment;
                    }
                }
                provOrdersObjList.add(provOrdObj);
            }
            ordObj.providerOrders = provOrdersObjList;
        }

        // ** Construction objet autre valeurs
        ordObj.entityCode = newOrder.serviceEntity__r?.KparKReference__c.right(4);
        ordObj.orderNumber = (newOrder.isLegacy__c) ? newOrder.legacyReference__c : newOrder.OrderNumber;
        ordObj.customer = newOrder.billingName__c;
        ordObj.financingCode = (String.isBlank(newOrder.financingMethod__c)) ? null : newOrder.financingMethod__r.KparKReference__c.right(4);
        ordObj.orderDate = dateStat;
        ordObj.week = (dateStat == null) ? null : dateStat.daysBetween(Date.today()) / 7;
        ordObj.pretaxAmount = newOrder.pretaxAmount__c;
        ordObj.status = newOrder.Status;
        ordObj.oldCompositeStatus = newOrder.oldCompositeStatus__c;
        ordObj.salesOwnerName = newOrder.salesOwnerName__c;
        ordObj.salesOwnerMagName = newOrder.salesOwnerMagName__c;
        ordObj.orderLastModifiedDate = newOrder.LastModifiedDate.date();
        ordObj.isInstall = (saInstallRec != null) ? true : false;
        ordObj.expectedInstallDate = expectedInstallDate;
        // Commentaires
        ordObj.controlComments = newOrder.controlComments__c;
        ordObj.orderComments = newOrder.orderComments__c;
        ordObj.confirmationComments = newOrder.confirmationComments__c;
        ordObj.deliveryComments = newOrder.deliveryComments__c;
        ordObj.installComments = newOrder.installComments__c;
        ordObj.remunerationComments = newOrder.remunerationComments__c;
        ordObj.pendingBalanceComments = newOrder.pendingBalanceComments__c;
        ordObj.uncollectedComments = newOrder.uncollectedComments__c;
        ordObj.cancellationComments = newOrder.cancellationComments__c;
        // Acompte
        ordObj.expectedAdvancePaymentAmount = newOrder.expectedAdvancePaymentAmount__c;
        ordObj.advPaymentExpPercent = advPaymentExpPercent;
        ordObj.receivedAdvancePaymentAmount = newOrder.receivedAdvancePaymentAmount__c;
        ordObj.advPaymentPercent = advPaymentPercent;
        ordObj.advPaymentTheoreticalAmount = advPaymentTheoreticalAmount;
        ordObj.advPaymentTheoreticalPercent = advPaymentTheoreticalPercent;
        // Derniere date de livraison
        ordObj.lastDeliveryDate = lastDeliveryDate;
        ordObj.lastDeliveryWeek = (lastDeliveryDate == null) ? null : lastDeliveryDate.daysBetween(Date.today()) / 7;

        System.debug('## ordObj: '+ordObj);   
        System.debug('### FIN LWC_GlobalPipelineGeneratePDF.constructOrderObject');
        return ordObj;
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
    
    /***************************************************/
    /* OBJECT JSON                                     *
    /***************************************************/
    public class PipelineObject {
        public String documentType;
        public String entityName;
        public Datetime generationDate;
        public List<StatusGroup> StatusGroups;
    }
    public class OrderObject {
        public String entityCode;
        public String orderNumber;
        public String customer;
        public String financingCode;
        public Date orderDate;
        public Date orderLastModifiedDate;
        public String oldCompositeStatus;
        public String status;
        public Integer week;
        public Decimal pretaxAmount;
        public Decimal expectedAdvancePaymentAmount;
        public Decimal advPaymentExpPercent;
        public Decimal receivedAdvancePaymentAmount;
        public Decimal advPaymentPercent;
        public Decimal advPaymentTheoreticalAmount;
        public Decimal advPaymentTheoreticalPercent;
        public String salesOwnerName;
        public String salesOwnerMagName;
        public String oncName;
        public Integer oncDuration;
        public Date lastDeliveryDate;
        public Integer lastDeliveryWeek;
        public Date firstControlDate;
        public String firstControlResource;
        public Date nextControlDate;
        public String nextControlResource;
        public Date nextInstallDate;
        public String nextInstallResource;
        public Boolean isInstall;
        public Date expectedInstallDate;
        public String comment;
        public String controlComments;
        public String orderComments;
        public String confirmationComments;
        public String deliveryComments;
        public String installComments;
        public String remunerationComments;
        public String pendingBalanceComments;
        public String uncollectedComments;
        public String cancellationComments;
        public List<ProviderOrderObject> ProviderOrders;
    }
    public class ProviderOrderObject {
        public String providerCode;
        public String description;
        public String legacyResponsability;
        public Date confirmationDate;
        public Date transmissionDate;
        public Date estimatedDeliveryDate;
        public Date deliveryDate;
        public Date availableDate;
        public Decimal pretaxAmount;
        public Decimal estimatedTotalCostAmount;
        public Decimal estimatedTotalCostPercent;
        public Decimal estimatedCostReOrderAmount;
        public Decimal estimatedCostReOrderPercent;
        public Decimal estimatedCostOrderAmount;
        public Decimal estimatedCostOrderPercent;
        public Boolean isDelivered;
        public String comment;
        public String controlComments;
        public String orderComments;
        public String confirmationComments;
        public String deliveryComments;
        public String installComments;
        public String remunerationComments;
        public String pendingBalanceComments;
        public String uncollectedComments;
        public String cancellationComments;
    }
    public class StatusGroup {
        public String groupName;
        public List<OrderObject> CustomerOrders;
    }
}