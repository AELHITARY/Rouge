//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_UpdateAfterSalesServiceStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/01/2024
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_UpdateAfterSalesServiceStatusGC implements Queueable {
    //#region staticVariables
	Set<Id> savIdList;
    Integer errorCount;
    Integer successCount;
    String errorMessage;
    BatchHistory__c batchHistoryStored;
    String RDV_DEBRIEFE = Constants.RDV_FSL_DEBRIEFE;
    String RDV_TERMINE = Constants.RDV_FSL_TERMINE;
    String RDV_ANNULE = Constants.RDV_FSL_ANNULE;
    String RDV_DEMANDE = Constants.RDV_FSL_DEMANDE; 
    String ORDER_RT_PROVIDER = Constants.ORDER_RT_PROVIDER;
    //#endregion

    //#region Constructor
    /**
    * @description Constructeur
    * @param orderIds Liste des IDs des devis
    * @return QA_UpdateAfterSalesServiceStatusGC Classe Queueable 
    */
    public QA_UpdateAfterSalesServiceStatusGC(Set<Id> savIds) {
        this.savIdList = savIds;
        this.errorMessage = '';
        this.errorCount = 0;
        this.successCount = 0;
    }
    //#endregion

    /**
    * @description Exécution d'un circuit de signature 'SAV' pour les dossiers SAv
    * @param context Context classe Queueable 
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_UpdateAfterSalesServiceStatusGC');
        System.debug('## savIdList: '+savIdList.size());
        List<String> idsError = new List<String>();

        UserContext uContext = UserContext.getContext();
        if(context != null && uContext.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')) {
            return;
        }

        try {
            // Historique
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('QA_UpdateAfterSalesServiceStatusGC');
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, savIdList.size());

            //#region variableDeclaration
            List<AfterSalesService__c> newSavList = new List<AfterSalesService__c>();
            List<Case> pncList = new List<Case>();
            List<SBQQ__Quote__c> quoteSavList = new List<SBQQ__Quote__c>();
            list<Order> orderSavList = new List<Order>();            
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            List<OrderItem> providerOrderItemList = new List<OrderItem>();
            //#endregion

            //#region dataquerying
            //Récupération des informations 
            if(!savIdList.isEmpty()){

                //Dossier SAV
                newSavList = [SELECT Id,CreatedDate,oldCompositeStatus2__c
                                FROM AfterSalesService__c 
                                WHERE Id IN :savIdList];

                //NPC Interne non cloturée 
                pncList = [SELECT id, aftersalesservice__c, detectedWarranty__c, closedDate, requiredOrder__c, diagnosticDate__c, Status
                    FROM Case
                    WHERE RecordType.DeveloperName = 'InternalProductNonCompliance'
                    AND afterSalesService__c IN :savIdList];
                        
                //Devis SAV
                quoteSavList = [SELECT id, dateAnnulation__c, afterSalesService__c, dateAcceptationClient__c
                    FROM SBQQ__Quote__c
                    WHERE SBQQ__Type__c = 'SAV'
                    AND afterSalesService__c IN :savIdList];

                //Commande SAV
                orderSavList = [SELECT id, netBalance__c, installationCompletionDate__c, cancellingDate__c, afterSalesService__c
                    FROM Order
                    WHERE Type =:Constants.ORDER_TYPE_COMMANDE_SAV  AND afterSalesService__c IN :savIdList];

                //RDV lié au Dossier SAV
                saList = [SELECT Id,workType.name,fsl_dateConfirmation__c,schedStartTime,Status,ParentRecordId,afterSalesService__c,fsl_dateDebriefing__c 
                    FROM ServiceAppointment
                    WHERE recordType.developerName = 'ServiceAppointment'
                    AND afterSalesService__c IN : savIdList];

                //Element de Demande de RDV associés aux NCP
                woliList = [SELECT id, workOrderId, productNonCompliance__c,workTypeName__c
                    FROM WorkOrderLineItem
                    WHERE productNonCompliance__c IN :pncList];
                
                //Lignes de Commandes fournisseurs confirmés non annulées avec une date de commande associées aux NCP ou au dossier SAV
                providerOrderItemList = [SELECT Id, order.productNonCompliance__c,confirmationDate__c,deliveryDate__c,CreatedDate
                    FROM OrderItem
                    WHERE (order.productNonCompliance__c IN :pncList OR order.afterSalesService__c IN :savIdList)
                    AND order.RecordType.DeveloperName = :ORDER_RT_PROVIDER
                    AND orderDate__c != null
                    AND cancellationDate__c = null];

            }    
            System.debug('## newOrders: '+newSavList.size());
            //#endregion        

            //#region datamapping
            // B - Application des règles de mise à jour
            List<AfterSalesService__c> savToUpdate = new List<AfterSalesService__c>();
            List<Order> orderSavToUpdate = new List<Order>();
            for (AfterSalesService__c newSav : newSavList) {
                String oldStatus = newSav.oldCompositeStatus2__c;
                //#region processIndicators
                //Calcul des indicateurs
                Boolean outOfWarranty = false;
                Integer internalPNCCount =0;
                Integer savquoteCount = 0;
                Integer savQuoteCancelledCount = 0;
                Integer orderSavCount = 0;
                Integer orderPaidCount = 0;
                Integer orderClosedCount = 0;
                Integer startedInterventionSACount = 0;
                Integer diagnosedPNCWithoutInterventionSACount = 0;
                Integer diagnosedPNCWithConfirmedInterventionSACount = 0;
                Integer diagnosedPNCWithoutConfirmedInterventionSACount = 0;
                Integer undiagnosedPNCwithoutDiagnosticSACount = 0;
                Integer undiagnosedPNCwithoutConfirmedDiagnosticSACount = 0 ;
                Integer undiagnosedPNCwithConfirmedDiagnosticSACount = 0;
                Integer orderablePNCWithoutOrderCount = 0;
                Integer orderablePNCWithUnconfirmedOrderCount = 0;
                Integer orderablePNCWithUndeliveredOrderCount = 0;
                Integer confirmedInterventionSACount = 0;
                Integer undebriefedInterventionSACount = 0;
                Integer savQuoteWithoutCustomerOrder = 0;
                DateTime lastDebriefingDate = null;
                Integer advancedStatusCaseCount = 0;
                Boolean isOldcontext = false;

                //calcul des indicateurs provenant des RDV
                for(ServiceAppointment sa : saList){
                    if(sa.afterSalesService__c == newSav.Id){
                        //RDV intervention existant en cours
                        if(sa.WorkType.name == 'Intervention' &&  sa.status!= RDV_ANNULE && sa.status != RDV_DEBRIEFE){
                            if(sa.Status != RDV_TERMINE){                                
                                if(/*sa.status != RDV_DEMANDE*/ sa.fsl_dateConfirmation__c != null){
                                    confirmedInterventionSACount++;
                                }
                            }
                            undebriefedInterventionSACount++;
                        }
                        //Passage en ECI
                        if(sa.WorkType.name == 'Intervention' && sa.Status == RDV_DEBRIEFE){
                            if(lastDebriefingDate == null || lastDebriefingDate > sa.fsl_dateDebriefing__c){
                                lastDebriefingDate = sa.fsl_dateDebriefing__c;
                            }
                            startedInterventionSACount++;
                        }
                        
                    }
                }

                //Calcul des indicateurs provenant des NCP
                for(Case pnc : pncList){
                    if(pnc.afterSalesService__c == newSav.Id){
                        if(pnc.detectedWarranty__c == 'Hors garantie'){
                            outOfWarranty = true;
                        }
                        if(pnc.closedDate == null){
                            internalPNCCount++;
                            Boolean saFound = false;
                            //Cas NCP diagnostiquée 
                            if(pnc.diagnosticDate__c != null){
                                //recherche de Commande fournisseur
                                if(pnc.requiredOrder__c != null && pnc.requiredOrder__c != Constants.NCP_REQUIREDORDER_NON){
                                    Boolean orderItemFound = false;
                                    for(OrderItem oi : providerOrderItemList){                                        
                                        if(oi.order.productNonCompliance__c == pnc.Id || oi.order.productNonCompliance__c == null){
                                            //Dans le cas d'un ECI vérifier uniquement les commandes crées après le dernier débriefing
                                            if(startedInterventionSACount == 0 || (lastDebriefingDate != null && oi.CreatedDate > lastDebriefingDate)){
                                                orderItemFound = true;
                                                if(oi.confirmationDate__c == null){
                                                    //commande fournisseur non confirmé 
                                                    orderablePNCWithUnconfirmedOrderCount++;
                                                }
                                                else if(oi.deliveryDate__c == null){
                                                    //commande fournisseur non livré 
                                                    orderablePNCWithUndeliveredOrderCount++;
                                                }
                                            }
                                        }
                                    }
                                    if(!orderItemFound){
                                        //pas de commande fournisseur
                                        orderablePNCWithoutOrderCount ++;
                                    }
                                }
                                //recherche woli intervention associé à la NCP
                                for(WorkOrderLineItem woli : woliList){
                                    if(woli.productNonCompliance__c == pnc.Id && woli.workTypeName__c == 'Intervention'){
                                        //recherche RDV nn finalisé associé au woli                                        
                                        for(ServiceAppointment sa : saList){
                                            if(woli.workOrderId == sa.ParentRecordId && sa.status!= RDV_ANNULE && sa.status != RDV_DEBRIEFE && sa.Status != RDV_TERMINE){
                                                saFound = true;
                                                //RDV non confirmé
                                                if(sa.fsl_dateConfirmation__c == null){
                                                    diagnosedPNCWithoutConfirmedInterventionSACount++;
                                                }
                                                //RDV confirmé
                                                else{
                                                    diagnosedPNCWithConfirmedInterventionSACount++;
                                                }
                                            }
                                        }
                                    }
                                }
                                if(!saFound){
                                    diagnosedPNCWithoutInterventionSACount++;
                                }
                            }
                            //Cas NCP non diagnostiquée
                            else{
                                //recherche woli intervention associé à la NCP
                                for(WorkOrderLineItem woli : woliList){
                                    if(woli.productNonCompliance__c == pnc.Id && woli.workTypeName__c == 'Diagnostic'){
                                        //recherche RDV nn finalisé associé au woli                                        
                                        for(ServiceAppointment sa : saList){
                                            if(woli.workOrderId == sa.ParentRecordId && sa.status!= RDV_ANNULE && sa.status != RDV_DEBRIEFE && sa.Status != RDV_TERMINE){
                                                saFound = true;
                                                //RDV non confirmé
                                                if(sa.fsl_dateConfirmation__c == null){
                                                    undiagnosedPNCwithoutConfirmedDiagnosticSACount++;
                                                }
                                                //RDV confirmé
                                                else{
                                                    undiagnosedPNCwithConfirmedDiagnosticSACount++;
                                                }
                                            }
                                        }
                                    }
                                }
                                if(!saFound){
                                    undiagnosedPNCwithoutDiagnosticSACount++;
                                }
                            }
                        }
                        if(pnc.Status == 'En cours' || pnc.Status == 'Commandé' || pnc.Status == 'Livré'){
                            advancedStatusCaseCount++;
                        }
                    }
                }
                
                //Calcul des indicateurs provenant des devis SAV
                for(SBQQ__Quote__c quoteSav : quoteSavList){
                    if(quoteSav.afterSalesService__c == newSav.Id){
                        if(quoteSav.dateAnnulation__c != null){
                            savQuoteCancelledCount++;
                        }
                        else {
                            savquoteCount++;
                            if(quoteSav.dateAcceptationClient__c == null){
                                savQuoteWithoutCustomerOrder++;
                            }
                        }
                    }
                }

                //Calcul des indicateurs provenant des commandes
                for(Order orderSav : orderSavList){
                    if(orderSav.afterSalesService__c == newSav.Id){
                        orderSavCount++;
                        if(orderSav.netBalance__c == 0){
                            orderPaidCount++;
                        }
                        if(orderSav.installationCompletionDate__c != null || orderSav.cancellingDate__c != null){
                            orderClosedCount++;
                        }
                    }
                }

                //indicateur ancien contexte
                if(orderSavCount == 0 && advancedStatusCaseCount > 0){
                    isOldcontext = true;
                } 

                
                System.debug('## outOfWarranty: '+outOfWarranty);
                System.debug('## Nombre de NCP non cloturée (internalPNCCount) : '+internalPNCCount);
                System.debug('## Nombre de devis SAV non annulés (savquoteCount) : '+(savquoteCount-savQuoteCancelledCount));
                System.debug('## Nombre de commande SAV totales (orderSavCount) : '+orderSavCount);
                System.debug('## Nombre de commande SAV cloturées Ou annulées (orderClosedCount) : '+orderClosedCount);
                System.debug('## Nombre de commande SAV soldées (orderPaidCount) : '+orderPaidCount);
                System.debug('## Nombre de RDV Intervention démarrés (startedInterventionSACount) : '+startedInterventionSACount);
                System.debug('## Nombre de NCP diagnostiqué sans RDV intervention (diagnosedPNCWithoutInterventionSACount) : '+diagnosedPNCWithoutInterventionSACount);
                System.debug('## Nombre de NCP diagnostiqué avec RDV intervention confirmé (diagnosedPNCWithConfirmedInterventionSACount) : '+diagnosedPNCWithConfirmedInterventionSACount);
                System.debug('## Nombre de NCP diagnostiqué avec RDV intervention confirmé (diagnosedPNCWithoutConfirmedInterventionSACount) : '+diagnosedPNCWithoutConfirmedInterventionSACount);
                System.debug('## Nombre de NCP non diagnostiqué sans RDV Diagnostic (undiagnosedPNCwithoutDiagnosticSACount) : '+undiagnosedPNCwithoutDiagnosticSACount);
                System.debug('## Nombre de NCP non diagnostiqué sans RDV Diagnostic confirmé (undiagnosedPNCwithoutConfirmedDiagnosticSACount) : '+undiagnosedPNCwithoutConfirmedDiagnosticSACount);
                System.debug('## Nombre de NCP non diagnostiqué avec RDV Diagnostic confirmé (undiagnosedPNCwithConfirmedDiagnosticSACount) : '+undiagnosedPNCwithConfirmedDiagnosticSACount);
                System.debug('## Nombre de NCP commandable sans commande fournisseur  (orderablePNCWithoutOrderCount) : '+orderablePNCWithoutOrderCount);
                System.debug('## Nombre de NCP commandable sans commande fournisseur confirmée (orderablePNCWithUnconfirmedOrderCount) : '+orderablePNCWithUnconfirmedOrderCount);
                System.debug('## Nombre de NCP commandable sans commande fournisseur livrée (orderablePNCWithUndeliveredOrderCount) : '+orderablePNCWithUndeliveredOrderCount);
                System.debug('## Nombre de RDV Intervention non terminé avec statut > Demandé (confirmedInterventionSACount) : '+confirmedInterventionSACount);
                System.debug('## Nombre de RDV Intervention terminé non débriefé (undebriefedInterventionSACount) : '+undebriefedInterventionSACount);
                System.debug('## Nombre de devis SAv non accepté (savQuoteWithoutCustomerOrder) : '+savQuoteWithoutCustomerOrder);
                
                //#endregion

                //#region statusMapping
                //Attribution du statut
                
                if(newSav.CreatedDate > System.now()) {
                    //« 20 » /* Etat Inconnu */
                    newSav.oldCompositeStatus2__c = 'Etat Inconnu';
                }
                else if(outOfWarranty && savQuoteCancelledCount > 0 && savquoteCount == 0){
                    //SAV payant avec tout les devis annulés
                    //« 160 » /* SAV Terminé Refusé */
                    newSav.oldCompositeStatus2__c = 'SAV Terminé Refusé';
                }
                //Cas SAV terminé (Toutes les NCP et commande cloturées)
                else if(internalPNCCount == 0){ 
                    if(orderSavCount !=0 && orderClosedCount > 0 && orderClosedCount == orderSavCount){
                        //Sav Payant et tt les commandes ne sont pas soldés 
                        if(outOfWarranty && (orderPaidCount == 0 || orderPaidCount < orderSavCount)){
                            //« 161 » /* SAV Terminé Non Soldé */
                            newSav.oldCompositeStatus2__c = 'SAV Terminé Non Soldé';
                        }
                        //Payant soldé ou Non payant 
                        else{
                            //« 162 » /* SAV Terminé */
                            newSav.oldCompositeStatus2__c = 'SAV Terminé';
                        }
                    }else if(orderSavCount == 0){
                        //« 162 » /* SAV Terminé */
                        newSav.oldCompositeStatus2__c = 'SAV Terminé';
                    }
                }
                //Pas de RDV d'intervention démarré - Pipeline SAV 
                else if(startedInterventionSACount == 0){
                    if(undiagnosedPNCWithoutDiagnosticSACount > 0){
                        //« 100 » /* SAV Non Diagnostiqué Non préparé */
                        newSav.oldCompositeStatus2__c = 'SAV Non Diagnostiqué Non préparé';                        
                    }
                    else if(undiagnosedPNCWithoutConfirmedDiagnosticSACount > 0){
                        //« 101 » /* SAV Non Diagnostiqué Non programmé */
                        newSav.oldCompositeStatus2__c = 'SAV Non Diagnostiqué Non programmé';                       
                    }
                    else if(undiagnosedPNCWithConfirmedDiagnosticSACount > 0){
                        //« 102 » /* SAV Non Diagnostiqué programmé */
                        newSav.oldCompositeStatus2__c = 'SAV Non Diagnostiqué programmé';
                    }
                    else if(!isOldcontext && savquoteCount == 0){
                        //« 103 » /* SAV Diagnostiqué Non Devisé */
                        newSav.oldCompositeStatus2__c = 'SAV Diagnostiqué Non Devisé';
                    }
                    else if(!isOldcontext && outOfWarranty && savQuoteWithoutCustomerOrder > 0){
                        //« 103 » /* SAV Diagnostiqué Non Accepté */
                        newSav.oldCompositeStatus2__c = 'SAV Diagnostiqué Non Accepté';
                    }
                    else if(orderablePNCWithoutOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 105 » /* SAV Non Commandé Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV Non Commandé Programmé';
                        }
                        else{
                            //« 104 » /* SAV Non Commandé */
                            newSav.oldCompositeStatus2__c = 'SAV Non Commandé';
                        }
                    }
                    else if(orderablePNCWithUnconfirmedOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 107 » /* SAV Non Confirmé Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV Non Confirmé Programmé';
                        }
                        else{
                            //« 106 » /* SAV Non Confirmé */
                            newSav.oldCompositeStatus2__c = 'SAV Non Confirmé';
                        }
                    }
                    else if(orderablePNCWithUndeliveredOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 110 » /* SAV Non livré Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV Non livré Programmé';                           
                        }
                        else if(undebriefedInterventionSACount > 0){
                            //« 109 » /* SAV Non livré Non Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV Non livré Non Programmé';
                        }
                        else{
                            //« 108 » /* SAV Non livré Non Préparé */
                            newSav.oldCompositeStatus2__c = 'SAV Non livré Non Préparé';                                                       
                        }
                    }
                    //cas toutes les commande fournisseur livrés
                    else{
                        if(confirmedInterventionSACount > 0){
                            //« 113 » /* SAV Attente d’Interv programmée */
                            newSav.oldCompositeStatus2__c = 'SAV Attente d\'Intervention programmée';
                        }
                        else if(undebriefedInterventionSACount > 0){
                            //« 112 » /* SAV Attente d’Interv Non Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV Attente d\'Interv Non Programmé';
                        }
                        else{
                            //« 111 » /* SAV Attente d’Interv Non Préparé */
                            newSav.oldCompositeStatus2__c = 'SAV Attente d\'Interv Non Préparé';
                        }
                    }
                }
                else{
                    //Dès qu'un premier RDV intervention est démarré - Pipeline SAV ECI
                    if(undiagnosedPNCWithoutDiagnosticSACount > 0){
                        //« 130 » /* ECI Non Diagnostiqué Non Préparé */
                        newSav.oldCompositeStatus2__c = 'SAV ECI Non Diagnostiqué Non Préparé';
                    }
                    else if(undiagnosedPNCWithoutConfirmedDiagnosticSACount > 0){
                        //« 131 » /* ECI Non Diagnostiqué Non Programmé */
                        newSav.oldCompositeStatus2__c = 'SAV ECI Non Diagnostiqué Non Programmé';
                    }
                    else if(undiagnosedPNCWithConfirmedDiagnosticSACount > 0){
                        //« 132 » /* ECI Non Diagnostiqué Programmé */
                        newSav.oldCompositeStatus2__c = 'SAV ECI Non Diagnostiqué Programmé';
                    }
                    else if(orderablePNCWithoutOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 134 » /* ECI Non Commandé Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Commandé Programmé';
                        }
                        else{
                            //« 133 » /* ECI Non Commandé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Commandé';
                        }
                    }
                    else if(orderablePNCWithUnconfirmedOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 136 » /* ECI Non Confirmé Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Confirmé Programmé';
                        }
                        else{
                            //« 135 » /* ECI Non Confirmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Confirmé';
                        }
                    }
                    else if(orderablePNCWithUndeliveredOrderCount > 0){
                        if(confirmedInterventionSACount > 0){
                            //« 139 » /* ECI Non Livré Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Livré Programmé';
                        }
                        else if(undebriefedInterventionSACount > 0){
                            //« 138 » /* ECI Non Livré Non Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Livré Non Programmé';
                        }
                        else{
                            //« 137 » /* ECI Non Livré Non Préparé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Non Livré Non Préparé';
                        }
                    }
                    else{
                        if(confirmedInterventionSACount > 0){
                            //« 142 » /* ECI Attente d’Interv programmée */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Attente d\'Interv programmée';
                        }
                        else if(undebriefedInterventionSACount > 0){
                            //« 141 » /* ECI Attente d’Interv Non Programmé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Attente d\'Interv Non Programmé';
                        }
                        else{
                            //« 140» /* ECI Attente d’Interv Non Préparé */
                            newSav.oldCompositeStatus2__c = 'SAV ECI Attente d\'Interv Non Préparé';
                        }
                    }
                }
                //#endregion

                if(oldStatus != newSav.oldCompositeStatus2__c){
                    savToUpdate.add(newSav);
                    for(Order order : orderSavList){
                        if(order.afterSalesService__c == newSav.Id){
                            //Order newOrder = new Order(Id = order.Id, oldCompositeStatus__c = newSav.oldCompositeStatus2__c, afterSalesService__c = newSav.Id);
                            System.debug('## save order: '+order.Id + ' with status :'+newSav.oldCompositeStatus2__c);
                            order.oldCompositeStatus__c = newSav.oldCompositeStatus2__c;
                            orderSavToUpdate.Add(order);
                        }
                    }
                    
                }
            }
            

            //#region dataSave
            // Sauvegarde en base et gestion des erreurs 
            if(!savToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(savToUpdate, false);

                // Vérification des erreurs
                if(Test.isRunningTest()) {
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, savToUpdate);
                }              
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage += '* ' + savToUpdate.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        idsError.add(savToUpdate.get(index).Id);
                        System.debug('## Error message: '+errorMessage);
                    } else {
                        successCount++;
                    }
                }

                if(!orderSavToUpdate.isEmpty()){
                    //pour ne pas update les commandes liés à des SAV en erreur
                    if(errorCount > 0){
                        List<Order> ordertoUpdateFinal = new List<Order>(); 
                        for(Order o : orderSavToUpdate){
                            Boolean error = false;
                            for(String idsav : idsError){
                                if(idSav == o.afterSalesService__c){
                                    error = true;
                                }
                            }
                            if(!error){
                                ordertoUpdateFinal.Add(o);
                            }
                        }
                        if(!ordertoUpdateFinal.isEmpty()){
                            Database.update(ordertoUpdateFinal, false);
                        }
                    }
                    else{
                        Database.update(orderSavToUpdate, false);
                    }
                }

                batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
            }
            //#endregion

            //#region batchUtils
            // Mise à jour des stats
            if(String.isNotBlank(errorMessage)) {
                batchHistoryStored = Utils_HistoriqueBatchs.updateIdsError(batchHistoryStored, idsError);
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage); 
            } else {
                batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            }
            //#endregion
        } catch (Exception e) {
            System.debug('ERREUR # QA_UpdateAfterSalesServiceStatusGC : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur exécution QA_UpdateAfterSalesServiceStatusGC', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
}