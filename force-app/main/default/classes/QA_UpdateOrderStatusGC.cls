//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_UpdateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/11/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_UpdateOrderStatusGC implements Queueable {
    Set<Id> orderIdList;
    Boolean isRecoverBatch;
    Integer errorCount;
    Integer successCount;
    String errorMessage;
    BatchHistory__c batchHistoryStored;

    /**
    * @description Constructeur
    * @param orderIds Liste des IDs des devis
    * @return QA_UpdateOrderStatusGC Classe Queueable 
    */
    public QA_UpdateOrderStatusGC(Set<Id> orderIds) {
        this.orderIdList = orderIds;
        this.errorMessage = '';
        this.errorCount = 0;
        this.successCount = 0;
    }

    /**
    * @description Exécution d'un circuit de signature 'Contrat' pour les devis
    * @param context Context classe Queueable 
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_UpdateOrderStatusGC');
        System.debug('## orderIdList: '+orderIdList.size());
        List<String> idsError = new List<String>();

        UserContext uContext = UserContext.getContext();
        if(context != null && uContext.canByPassTrigger('QA_UpdateOrderStatusGC')) {
            return;
        }

        try {
            
            List<ServiceAppointment> SAList = new List<ServiceAppointment>();
            List<ServiceAppointment> saFromWoliList = new List<ServiceAppointment>();
            Set<Id> assetIdList = new Set<Id>();
            Set<Id> assetIdList2 = new Set<Id>();
            Set<Id> woliIdList = new Set<Id>();
            List<Case> pncList = new List<Case>();
            List<Asset> assetList = new List<Asset>();
            List<OrderItem> orderItemList = new List<OrderItem>();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            List<Order> newOrders = new List<Order>();
            List<Order> providerOrderList = new List<Order>();
            List<AccountingPiece__c> accPieceList = new List<AccountingPiece__c>();

            // A - Initialisation des données intermédiaires 
            if(!orderIdList.isEmpty()){
                newOrders = [SELECT Id, oldCompositeStatus__c,firstDiagnosticSADate__c, CreatedDate, cancellingDate__c, installableAssetCount__c,
                                    installedAssetCount__c, internalPNCCount__c, invoiceableAmount__c, netBalance__c, doubtfulAccountingPieceAmount__c,
                                    undiagnosedInternalPNCCount__c, unconfirmedProviderOrderCount__c,
                                    undeliveredProviderOrderCount__c, controllableAssetCount__c, controlledAssetCount__c,
                                    impossibilityCount__c, deliveryDate__c,
                                    isValid__c, ActivatedDate, installationCompletionDate__c
                                FROM Order 
                                WHERE Type !=:Constants.ORDER_TYPE_COMMANDE_SAV AND Id IN :orderIdList];
            }    
            System.debug('## newOrders: '+newOrders.size());        

            if(!orderIdList.isEmpty() && !newOrders.isEmpty()) {
                // Historique
                batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('QA_UpdateOrderStatusGC');
                batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, orderIdList.size());


                providerOrderList = [SELECT Id, confirmationdate__c, status, deliveryDate__c, transmissionDate__c,
                                    parentOrder__c, manufacturingStart__c , manufacturingEnd__c, shippingDate__c, billingDate__c
                                FROM Order 
                                WHERE parentOrder__c IN :orderIdList AND recordtype.developername = 'ProviderOrder'];

                // Récupération des SA pour calcul des indicateurs scheduledInterventionSACount et scheduledInterventionSACount2
                SAList = [SELECT Id, SchedStartTime, parentRecordId, fsl_dateConfirmation__c, customerorder__c, dateConfirmationClient__c,
                                WorkType.Name, Status, dateTransmission__c, fsl_techOrdreExecutionParent__r.subWorkType__c
                            FROM ServiceAppointment 
                            WHERE customerOrder__c IN :orderIdList 
                                AND Status != 'Annulé'
                                ORDER BY SchedStartTime ASC];

                System.debug('SAList : '+SAList);

                // Récupération des Assets
                assetList = [SELECT Id, InstallDate, Status, controldate__c, recordtype.developername, product2.iscontrollable__c, product2.isInstallable__c, customerOrder__c, ParentId
                                FROM Asset
                                WHERE ParentId = null AND Status != 'Annulé' AND customerOrder__c IN :orderIdList];
        
                System.debug('assetList : '+assetList);
                
                // Récupération des PNC
                pncList = [SELECT id, assetId, diagnosticDate__c, inStock__c, Asset.customerOrder__c, aftersalesservice__c, Status
                            FROM Case
                            WHERE RecordType.DeveloperName = 'InternalProductNonCompliance'
                                AND Asset.customerOrder__c IN :orderIdList
                                AND type = 'ECI'
                                AND closedDate = NULL];

                System.debug('pncList : '+pncList);
        
                // Tri des PNC pour récupération de listes d'Assets pour les indicateurs notOrderedPNC et les withoutDiagnosticCount
                for(Case ca : pncList){
                    System.debug('ca.diagnosticDate__c: '+ca.diagnosticDate__c);
                    System.debug('ca.inStock__c : '+ca.inStock__c );
                    //System.debug('ca.requiredOrder__c: '+ca.requiredOrder__c);
                    if(String.isNotBlank(ca.AssetId) && ca.diagnosticDate__c != null && !ca.inStock__c /*&& ca.requiredOrder__c != Constants.NCP_REQUIREDORDER_NON*/){
                        assetIdList.add(ca.AssetId);
                    } else if(String.isNotBlank(ca.AssetId) && ca.diagnosticDate__c == null){
                        assetIdList2.add(ca.AssetId);
                    }
                }
        
                if(!assetIdList.isEmpty()) {
                    // Récupération des OrderItems pour le calcul de l'indicateur notOrderedPNC
                    orderItemList = [SELECT id, asset__c FROM OrderItem
                                WHERE asset__c in :assetIdList 
                                    AND Order.RecordType.DeveloperName = 'ProviderOrder'
                                    AND deliveryDate__c = null 
                                    AND cancellationDate__c = null];
                }

                System.debug('orderItemList : '+orderItemList);
        
                if(!assetIdList2.isEmpty()) {
                    // Récupération des WorkOrderLineItem et SA pour le calcul des indicateurs withoutDiagnosticCount
                    woliList = [SELECT id, assetId, workOrderId FROM WorkOrderLineItem
                                WHERE workType.name = 'Diagnostic'
                                    AND assetId in :assetIdList2];
                }

                System.debug('woliList : '+woliList);
        
                for(WorkOrderLineItem woli : woliList){   
                    if(String.isNotBlank(woli.Id)) {       
                        woliIdList.add(woli.Id);
                    }
                }

                System.debug('woliIdList : '+woliIdList);
        
                if(!woliIdList.isEmpty()) {
                    saFromWoliList = [SELECT id, parentRecordId, fsl_dateConfirmation__c, dateConfirmationClient__c FROM ServiceAppointment
                                    WHERE ParentRecordId in :woliIdList
                                    AND Status != 'Annulé'
                                    AND Status != 'Terminé'
                                    AND Status != 'Débriefé'];
                }

                System.debug('saFromWoliList : '+saFromWoliList);

                accPieceList = [SELECT Id, amount__c , order__c 
                                    FROM AccountingPiece__c 
                                    WHERE isDeleted = false AND recordtype.developername = 'DoubtfulDebt' 
                                    AND accountingdate__c != null AND amount__c != null AND order__c IN :orderIdList];

                System.debug('accPieceList : '+accPieceList);
            }

            // B - Application des règles de mise à jour
            List<Order> ordersToUpdate = new List<Order>();
            for (Order newOrder : newOrders) {                
                System.debug('## Starting Order Status: '+newOrder.Id+' - '+newOrder.oldCompositeStatus__c);
                String oldStatus = newOrder.oldCompositeStatus__c;
                Integer unconfirmedProviderOrderCount = 0;
                Integer undeliveredProviderOrderCount = 0;
                Integer installableAssetCount = 0;
                Integer installedAssetCount = 0;
                Integer controllableAssetCount = 0;
                Integer controlledAssetCount = 0;
                Integer internalPNCCount = 0;
                Integer undiagnosedInternalPNCCount = 0;
                Integer scheduledInterventionSACount = 0;
                Integer scheduledInterventionSACount2 = 0;
                String firstInterventionSAIdent = null;
                Boolean notOrderedPNC = false;
                Integer withoutDiagnosticCount = 0;
                Integer WithoutConfirmedDiagnosticCount = 0;
                Integer WithConfirmedDiagnosticCount = 0;
                Decimal doubtfulAccountingPieceAmount = 0;
                Integer startedInterventionSACount = 0;
                Integer activeAndConfirmedInterventionSACount = 0;
                Integer undebriefedInterventionSACount = 0;
                Integer debriefedInterventionSACount = 0;
                Integer confirmedInterventionSACount = 0;
                Integer transmittedInterventionSACount = 0;
                Integer interventionSACount = 0;
                Integer controlSACount = 0;
                Integer unconfirmedControlSACount = 0;
                Integer providerOrderOrderedCount = 0;
                
                // Calcul des indicateurs provenant des Orders
                for(Order o : providerOrderList){
                    if(o.parentOrder__c == newOrder.Id){
                        if(o.confirmationdate__c == null && o.status != Constants.ORDER_STATUS_CANCELLED && o.manufacturingStart__c == null && o.manufacturingEnd__c == null
                            && o.shippingDate__c == null && o.deliveryDate__c == null && o.billingDate__c == null){
                            unconfirmedProviderOrderCount++;
                        }
                        if(o.confirmationdate__c != null && o.status != Constants.ORDER_STATUS_CANCELLED && 
                            o.deliveryDate__c == null){
                            undeliveredProviderOrderCount++;
                        }
                        if((o.confirmationdate__c != null || o.transmissionDate__c != null) && o.status != Constants.ORDER_STATUS_CANCELLED){
                            providerOrderOrderedCount++;
                        }
                    }
                }

                // Calcul des indicateurs provenant des Assets
                for(Asset a : assetList){
                    if(a.customerOrder__c == newOrder.Id){
                        if(a.Status != Constants.ASSET_STATUS_ANNULE && a.product2.iscontrollable__c
                        && (a.recordtype.developername == Constants.ASSET_CARPENTRY_RT || a.recordtype.developername == 'Service')){
                            controllableAssetCount++;

                            if(a.controldate__c != null){
                                controlledAssetCount++;
                            }
                        }
                    }
                }

                // Calcul des indicateurs provenant des SA
                for(ServiceAppointment sa : SAList){
                    if(sa.customerOrder__c == newOrder.Id){
                        System.debug('sa.Status : '+sa.Status);
                        System.debug('sa.schedstarttime : '+sa.schedstarttime );
                        System.debug('sa.WorkType.Name: '+sa.WorkType.Name);
                        System.debug('sa.fsl_dateConfirmation__c: '+sa.fsl_dateConfirmation__c);
                        System.debug('sa.fsl_techOrdreExecutionParent__r: '+sa.fsl_techOrdreExecutionParent__r.subWorkType__c);
                        System.debug('neworder.firstDiagnosticSADate__c:'+newOrder.firstDiagnosticSADate__c);
                        
                        if((sa.WorkType.Name == 'Intervention' && 
                            (sa.fsl_techOrdreExecutionParent__r.subWorkType__c == 'Pose' || sa.fsl_techOrdreExecutionParent__r.subWorkType__c == 'ECI')) || 
                            (sa.WorkType.Name == 'INSTALLATION' || sa.WorkType.Name == 'INSTALLATION ECI')){
                            if(sa.Status == Constants.RDV_FSL_DEBRIEFE && sa.fsl_dateConfirmation__c != null){
                                if(firstInterventionSAIdent == null && sa.SchedStartTime < System.now()){
                                    firstInterventionSAIdent = sa.Id;
                                }
                                if(sa.SchedStartTime < newOrder.firstDiagnosticSADate__c){
                                    scheduledInterventionSACount2++;
                                }
                            }
                            if(sa.Status != Constants.RDV_FSL_DEBRIEFE){
                                if(sa.SchedStartTime < System.now() && sa.Id != firstInterventionSAIdent){
                                    scheduledInterventionSACount++;
                                }
                            }
                            System.debug('sa.Status : '+sa.Status);
                            System.debug('sa.schedstarttime : '+sa.schedstarttime );
                            if(sa.Status != Constants.RDV_FSL_DEBRIEFE && sa.Status != Constants.RDV_FSL_TERMINE && sa.Status != Constants.RDV_FSL_DEMANDE) {
                                activeAndConfirmedInterventionSACount++;
                            }
                            if(sa.SchedStartTime <= System.now() && (sa.Status == Constants.RDV_FSL_DEBRIEFE || sa.Status == Constants.RDV_FSL_TERMINE 
                                || sa.Status == Constants.RDV_FSL_ENCOURS || sa.Status == Constants.RDV_FSL_ENROUTE || sa.Status == Constants.RDV_FSL_CONFIRME)) {
                                startedInterventionSACount++;
                            }
                            if(sa.Status != Constants.RDV_FSL_DEBRIEFE){
                                undebriefedInterventionSACount++;
                            }
                            if(sa.Status == Constants.RDV_FSL_DEBRIEFE){
                                debriefedInterventionSACount++;
                            }
                            if(sa.fsl_dateconfirmation__c != null){
                                confirmedInterventionSACount++;
                            }
                            if(sa.dateTransmission__c != null){
                                transmittedInterventionSACount++;
                            }
                            interventionSACount++;
                        } else if(sa.WorkType.Name == 'Métrage' || sa.WorkType.Name == 'Contrôle' || sa.WorkType.Name == 'METRAGE'){
                            if(sa.Status != Constants.RDV_FSL_DEBRIEFE){
                                controlSACount++;
                            }
                            if(sa.Status != Constants.RDV_FSL_DEBRIEFE && sa.Status != Constants.RDV_FSL_TERMINE 
                                && sa.dateConfirmationClient__c == null && sa.fsl_dateConfirmation__c == null && sa.dateTransmission__c == null){
                                unconfirmedControlSACount++;
                            }
                        }
                    }
                }

                // Calcul des indicateurs provenant des PNC/OrderItems
                List<Id> assetIdListPerOrder = new List<Id>();
                for(Case ca : pncList){
                    if(ca.Asset.customerOrder__c == newOrder.Id){
                        if(ca.diagnosticDate__c != null && !ca.inStock__c /*&& ca.requiredOrder__c != Constants.NCP_REQUIREDORDER_NON*/){
                            assetIdListPerOrder.add(ca.assetId);
                        }
                        if(ca.aftersalesservice__c == null && ca.Status != Constants.REQUETE_STATUS_CLOSED){
                            internalPNCCount++;
                            if(ca.diagnosticDate__c == null){
                                undiagnosedInternalPNCCount++;
                            }
                        }
                    }
                }
                for(OrderItem oi : orderItemList){
                    for(String assetIdFromList : assetIdListPerOrder){
                        if(oi.asset__c == assetIdFromList){
                            notOrderedPNC = true;
                        }
                    }
                }

                // Calcul des indicateurs provenant des PNC/WOLI/SA
                for(Case ca : pncList){
                    if(ca.Asset.customerOrder__c == newOrder.Id && ca.diagnosticDate__c == null){
                        for(WorkOrderLineItem woli : woliList){
                            if(woli.AssetId == ca.assetId){
                                Boolean saFoundForWOLI = false;
                                for(ServiceAppointment sa : saFromWoliList){
                                    if(sa.ParentRecordId == woli.Id){
                                        saFoundForWOLI = true;
                                        if(sa.fsl_dateConfirmation__c == null){
                                            WithoutConfirmedDiagnosticCount++;
                                        } else {
                                            WithConfirmedDiagnosticCount++;
                                        }
                                    }
                                }
                                if(!saFoundForWOLI){
                                    withoutDiagnosticCount++;
                                }
                            }
                        }
                    }
                }

                // Calcul des indicateurs provenant des pièces comptables
                for(AccountingPiece__c ap : accPieceList){
                    if(ap.order__c == newOrder.Id){
                        doubtfulAccountingPieceAmount = doubtfulAccountingPieceAmount + ap.amount__c;
                    }
                }

                System.debug('Nombre de commandes f. non conf (unconfirmedProviderOrderCount) : '+unconfirmedProviderOrderCount);
                System.debug('Nombre de commandes f. non livrée (undeliveredProviderOrderCount) : '+undeliveredProviderOrderCount);
                System.debug('Nombre d\'actifs controllables (controllableAssetCount) : '+controllableAssetCount);
                System.debug('Nombre d\'actifs controllés (controlledAssetCount) : '+controlledAssetCount);
                System.debug('Nombre de NCP Interne (internalPNCCount) : '+internalPNCCount);
                System.debug('Nombre de NCP Interne non diag (undiagnosedInternalPNCCount) : '+undiagnosedInternalPNCCount);
                System.debug('Montant des créances douteuses (doubtfulAccountingPieceAmount) : '+doubtfulAccountingPieceAmount);
                System.debug('Nombre de RDV pose débuté (startedInterventionSACount) : '+startedInterventionSACount);
                System.debug('Nombre de RDV pose non débriefé (undebriefedInterventionSACount) : '+undebriefedInterventionSACount);
                System.debug('Nombre de RDV pose débriefé (debriefedInterventionSACount) : '+debriefedInterventionSACount);
                System.debug('Nombre de RDV pose en cours (transmittedInterventionSACount) : '+transmittedInterventionSACount);
                System.debug('Nombre de RDV pose actif/en cours (activeAndConfirmedInterventionSACount) : '+activeAndConfirmedInterventionSACount);
                System.debug('Nombre de RDV pose (interventionSACount) : '+interventionSACount);
                System.debug('Nombre de RDV métrage (controlSACount) : '+controlSACount);
                System.debug('Nombre de RDV métrage non confirm (unconfirmedControlSACount) : '+unconfirmedControlSACount);
                System.debug('Nombre de commandes f. commandés (providerOrderOrderedCount) : '+providerOrderOrderedCount);
                System.debug('(scheduledInterventionSACount) : '+scheduledInterventionSACount);
                System.debug('(scheduledInterventionSACount2) : '+scheduledInterventionSACount2);
                

                // Vérification des valeurs pour le changement de statut
                if (newOrder.isValid__c == false) {   
                    newOrder.oldCompositeStatus__c = null;
                } else if (newOrder.CreatedDate > System.now()) {   
                    newOrder.oldCompositeStatus__c = 'Inconnu';
                } else if(newOrder.cancellingDate__c != null){
                    newOrder.oldCompositeStatus__c = 'Résilié';
                } else if(newOrder.installationCompletionDate__c != null && (internalPNCCount == null || internalPNCCount == 0)){
                    system.debug('Passage en branche soldée');
                    if(newOrder.invoiceableAmount__c <= 0 && newOrder.netBalance__c <= 0){
                        if(newOrder.netBalance__c == 0){
                            newOrder.oldCompositeStatus__c = 'Soldé';
                        } else if(newOrder.netBalance__c < 0 || doubtfulAccountingPieceAmount > 0){
                            newOrder.oldCompositeStatus__c = 'Soldé NC';
                        } 
                    } else {
                        newOrder.oldCompositeStatus__c = 'Totalement installé';
                    }
                } else if (startedInterventionSACount > 0){
                    system.debug('Passage en branche ECI');
                    if(debriefedInterventionSACount == 0){
                        newOrder.oldCompositeStatus__c = 'Pose du jour';
                    }
                    else if(scheduledInterventionSACount > 0){
                        newOrder.oldCompositeStatus__c = 'ECI du jour';
                    }
                    else if(scheduledInterventionSACount2 > 0){
                        newOrder.oldCompositeStatus__c = 'ECI en attente d’installation programmé';
                    }
                    else if(undiagnosedInternalPNCCount > 0){ 
                        if(withoutDiagnosticCount > 0){
                            newOrder.oldCompositeStatus__c = 'ECI non diagnostiqué non préparé';
                        } else if(WithoutConfirmedDiagnosticCount > 0){
                            newOrder.oldCompositeStatus__c = 'ECI non diagnostiqué non programmé';
                        } else if(WithConfirmedDiagnosticCount > 0){
                            newOrder.oldCompositeStatus__c = 'ECI non diagnostiqué  programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'ECI non diagnostiqué non préparé';
                        }
                    } else if(notOrderedPNC){
                        if(activeAndConfirmedInterventionSACount > 0){
                            newOrder.oldCompositeStatus__c = 'ECI non commandé programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'ECI non commandé';
                        }
                    } else if(unconfirmedProviderOrderCount > 0){
                        if(activeAndConfirmedInterventionSACount > 0){
                            newOrder.oldCompositeStatus__c = 'ECI non confirmé programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'ECI non confirmé';
                        }
                    } else if(undeliveredProviderOrderCount > 0){
                        if(undebriefedInterventionSACount == null || undebriefedInterventionSACount == 0){
                            newOrder.oldCompositeStatus__c = 'ECI non Livré non préparé';
                        } else if(activeAndConfirmedInterventionSACount > 0 ){
                            newOrder.oldCompositeStatus__c = 'ECI non livré non programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'ECI non livré programmé';
                        }
                    } else if(undebriefedInterventionSACount == null || undebriefedInterventionSACount == 0){
                        newOrder.oldCompositeStatus__c = 'ECI en attente d’installation non préparé';
                    } else if(activeAndConfirmedInterventionSACount == null || activeAndConfirmedInterventionSACount == 0){
                        newOrder.oldCompositeStatus__c = 'ECI en attente d’installation non programmé';
                    } else {
                        newOrder.oldCompositeStatus__c = 'ECI en attente d’installation programmé';
                    }
                } else {
                    system.debug('Passage ELSE');
                    if(controllableAssetCount > 0 &&
                    ((controllableAssetCount > controlledAssetCount) || controlSACount > 0)){
                        if(newOrder.impossibilityCount__c > 0){
                            newOrder.oldCompositeStatus__c = 'Non métrable';
                        } else if(controlSACount == null || controlSACount == 0 || unconfirmedControlSACount > 0){ 
                            newOrder.oldCompositeStatus__c = 'Non métré non programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'Non métré programmé';
                        }
                    } else if(providerOrderOrderedCount == null || providerOrderOrderedCount == 0){
                        if(newOrder.impossibilityCount__c > 0){
                            newOrder.oldCompositeStatus__c = 'Non commandable';
                        } else {
                            newOrder.oldCompositeStatus__c = 'Non commandé';
                        }
                    }
                    else if(unconfirmedProviderOrderCount > 0){
                        newOrder.oldCompositeStatus__c = 'Non confirmé';
                    } else if(newOrder.impossibilityCount__c > 0){
                        newOrder.oldCompositeStatus__c = 'Non installable';
                    } else if(undeliveredProviderOrderCount > 0){
                        if(interventionSACount == null || interventionSACount == 0){
                            newOrder.oldCompositeStatus__c = 'Non livré non préparé';
                        } else if((confirmedInterventionSACount == null || confirmedInterventionSACount == 0) &&
                                  (transmittedInterventionSACount == null || transmittedInterventionSACount == 0)){
                            newOrder.oldCompositeStatus__c = 'Non livré non programmé';
                        } else {
                            newOrder.oldCompositeStatus__c = 'Non livré programmé';
                        }
                    } else if(interventionSACount == null || interventionSACount == 0){
                        newOrder.oldCompositeStatus__c = 'Non installé non préparé';
                    } else if((confirmedInterventionSACount == null || confirmedInterventionSACount == 0) &&
                              (transmittedInterventionSACount == null || transmittedInterventionSACount == 0)){
                        newOrder.oldCompositeStatus__c = 'Non installé non programmé';
                    } else {
                        newOrder.oldCompositeStatus__c = 'Non installé programmé';
                    }
                }

                if(oldStatus != newOrder.oldCompositeStatus__c){
                    ordersToUpdate.add(newOrder);
                }
                
                System.debug('## Ending Order Status: '+newOrder.Id+' - '+newOrder.oldCompositeStatus__c);
            }

            if(!ordersToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(ordersToUpdate, false);

                // Vérification des erreurs
                if(Test.isRunningTest()) {
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, ordersToUpdate);
                }              
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage += '* ' + ordersToUpdate.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        idsError.add(ordersToUpdate.get(index).Id);
                        System.debug('## Error message: '+errorMessage);
                    } else {
                        successCount++;
                    }
                }

                batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
            }

            // Mise à jour des stats
            if(String.isNotBlank(errorMessage)) {
                batchHistoryStored = Utils_HistoriqueBatchs.updateIdsError(batchHistoryStored, idsError);
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage); 
            } else if(!ordersToUpdate.isEmpty()){
                batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            }

            System.debug('### FIN QA_UpdateOrderStatusGC');
        } catch (Exception e) {
            System.debug('ERREUR # QA_UpdateOrderStatusGC : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur exécution QA_UpdateOrderStatusGC', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
}