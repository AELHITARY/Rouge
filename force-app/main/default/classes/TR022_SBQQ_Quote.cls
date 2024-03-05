//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_SBQQ_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/10/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR022_SBQQ_Quote {

    public static final Id orderCmdClientRtId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    public static final Id orderCmdProviderRtId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    
    /**
      * @description Mise à jour des remises CEE
      * @param userContext Contexte de l'utilisateur courant
      */
      public static void setMontantLignesDevisCEE(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<SBQQ__Quote__c> quotes = (List<SBQQ__Quote__c>) Trigger.new;
        Map<Id, SBQQ__Quote__c>  oldQuotes = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
        List<SBQQ__Quote__c> quotesList = new List<SBQQ__Quote__c>();
        Date dateDevisMin = Date.today();
        Date dateDevisMax = dateDevisMin.addDays(-100000);
        List<Decimal> nbPersonneDevisList = new List<Decimal>();
        List<String> zoneGeographiqueDevisList = new List<String>();
        Map<String,Decimal> montantCEEList = new Map<String,Decimal>();
        for(SBQQ__Quote__c quote : quotes) {         
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(quote.Id);
            if ((quote.Zone__c != oldQuote.Zone__c) || (quote.NombrePersonnes__c != oldQuote.NombrePersonnes__c) || // quote.categorie__c != oldQuote.categorie__c ||
                (quote.referenceDate__c != oldQuote.referenceDate__c) || (quote.RevenusFiscaux__c != oldQuote.RevenusFiscaux__c)) {
                quotesList.add(quote);
            }
            // Inforrations pour CEE
            if(quote.referenceDate__c < dateDevisMin)
                dateDevisMin = quote.referenceDate__c;
            if(quote.referenceDate__c > dateDevisMax)
                dateDevisMax = quote.referenceDate__c;
            nbPersonneDevisList.add(quote.NombrePersonnes__c);
            zoneGeographiqueDevisList.add(quote.Zone__c);
        }

        // Mise à jour des remises
        if(!quotesList.isEmpty()){
            System.debug('#### START TR022_SBQQ_Quote.setMontantLignesDevisCEE');
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
            Set<String> quoteIds = new Set<String>();
            List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
            List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
            List<String> productIdList = new List<String>();
            List<String> tvaTypeList = new List<String>();
            
            for(SBQQ__Quote__c q : quotesList){
                quoteIds.add(q.Id);
            }

            qliList = [SELECT Id, SBQQ__Quote__c,
                    Quantite__c, SBQQ__Product__c,
                    SBQQ__Product__r.SousFamille__c,
                    eligibleCEE__c,
                    TauxTVAPercent__c
                        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds]; 
            for(SBQQ__QuoteLine__c qli : qliList){
                productIdList.add(qli.SBQQ__Product__c);
            }

            // Récupération des catégories/primes CEE dans la base, et des lignes de devis
            tvaList = [SELECT Id, type__c, Produit__c, Datedebut__c, Datefin__c, Taux__c
                        FROM TVA_Produit__c
                        WHERE Produit__c IN :productIdList];

            for(TVA_Produit__c tva : tvaList){
                tvaTypeList.add(tva.type__c);
            }

            ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                        FROM ESCIncentive__c
                        WHERE type__c IN :tvaTypeList AND startDate__c < :dateDevisMax 
                                        AND (endDate__c > :dateDevisMin OR endDate__c = null)
                                        AND personNumber__c IN :nbPersonneDevisList
                                        AND geography__c IN :zoneGeographiqueDevisList];

            for(SBQQ__Quote__c q : quotesList){
                Utils_CEE.setQliCEE(qliList, q, ceeList, tvaList);
            }
            update qliList;
            System.debug('#### END TR022_Quote.setMontantLignesDevisCEE');
        }      
    }

    /**
    * @description Mise à jour du statut GC du dossier SAV 
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateAfterSalesServiceGCStatus(UserContext userContext){
        System.debug('### DEBUT TR022_SBQQ_Quote.updateAfterSalesServiceGCStatus');
        if (!Trigger.isExecuting)
            return;
        
        Map<Id, SBQQ__Quote__c> oldQuotes = (Map<Id, SBQQ__Quote__c>)Trigger.oldMap;
        Set<Id> savIdsList = new Set<Id>();
        
        try {
            // A - Initialisation et alimentation des données intermédiaires
            for(SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>)Trigger.new){
                SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);

                //Se déclenche uniquement pour les Devis de type SAV rattachés à un dossier SAV
                //A la création ou a la modif des champs impactant le statut GC : dateAnnulation__c, afterSalesService__c
                System.debug('## newQuote sav:'+newQuote.afterSalesService__c);
                System.debug('## newQuote SBQQ__Type__c:'+newQuote.SBQQ__Type__c);
                System.debug('## newQuote dateAnnulation__c:'+newQuote.dateAnnulation__c);
                if(newQuote.afterSalesService__c !=null && newQuote.SBQQ__Type__c == 'SAV'){
                    String savId =  newQuote.afterSalesService__c;
                    if(Trigger.isInsert || 
                        (Trigger.isUpdate && 
                        (newQuote.dateAnnulation__c != oldQuote.dateAnnulation__c ||
                        newQuote.afterSalesService__c != oldQuote.afterSalesService__c))){
                            if(!savIdsList.contains(savId)){
                                savIdsList.Add(savId);
                                System.debug('### savIdList add sav : '+savId);
                            }
                        }
                }
            }
            
            System.debug('savIdsList : '+savIdsList);

            // B - MAJ
            // LEGACY KUBE 2 : Calcul ancien statut GC
            if(!savIdsList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec queueable update old status GC: ' + savIdsList);
                System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(savIdsList));
            }
        } catch (Exception e) {
            throw e;
        }
        System.debug('### FIN TR022_SBQQ_Quote.updateAfterSalesServiceGCStatus');
    }
    
     /**
    * @description Méthode exécutant les différentes méthode de MAJ de prix pour les devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updatePrice(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }        
        
        // TODO : A REVOIR POUR SAV 
        /*
        System.debug('### DEBUT TR022_SBQQ_Quote : updatePrice');
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        List<String> chantierId = new List<String>();
        Map<Id, SBQQ__Quote__c> oldQuotes = (Map<Id, SBQQ__Quote__c>)Trigger.oldMap;
        List<SBQQ__Quote__c> quotesWithQLI = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesList = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesList2 = new List<SBQQ__Quote__c>();
        List<String> quotesListId = new List<String>();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
        List<TarifProduit__c> tfProduitList = new List<TarifProduit__c>();
        Map<String,List<SBQQ__QuoteLine__c>> qliMap = new Map<String,List<SBQQ__QuoteLine__c>>();
        Map<String,List<SBQQ__Quote__c>> quoteMap = new Map<String,List<SBQQ__Quote__c>>();

        // A - Initialisation des données intermédiaires 
        for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>)Trigger.new) {
            newQuotes.add(newQuote);
            quotesListId.add(newQuote.Id);
            // Récupération des lignes de devis seulement si ligne de devis
            if(newQuote.SBQQ__LineItemCount__c != 0) {
                quotesWithQLI.add(newQuote);
            }
            // Récupération chantier
            if(newQuote.SBQQ__Type__c == 'SAV') {
                chantierId.add(newQuote.chantier__c);
            }
        }
        
        if(!quotesListId.isEmpty()) {
            quotesList2 = [SELECT Id, chantier__c FROM SBQQ__Quote__c WHERE ID in:quotesListId];
        }

        // Récupération des lignes de devis
        if (!quotesWithQLI.isEmpty()) {
            qliList = [SELECT Id, SBQQ__Quote__c, Quantite__c, SBQQ__Product__c, SBQQ__Product__r.SousFamille__c,
                    eligibleCEE__c, TauxTVAPercent__c, caseItem__r.case__r.AssetId, caseItem__r.case__r.Asset.InstallDate,
                    caseItem__r.case__r.Asset.UsageEndDate, caseItem__r.case__r.responsability__c, caseItem__r.case__r.CreatedDate, productType__c,
                    caseItem__r.productOption__r.SBQQ__UnitPrice__c, caseItem__r.productOption__r.TPUnitPriceActive__c,
                    caseItem__r.case__r.Type, laborPrice__c, SBQQ__NetPrice__c, SBQQ__CustomerPrice__c, unitPriceParent__c,
                    laborPriceParent__c, SBQQ__ProductCode__c, LibelleProduit__c
                        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quotesWithQLI];        
            for (SBQQ__Quote__c quote : quotesWithQLI) {
                List<SBQQ__QuoteLine__c> qliListByQuote = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c qli : qliList) {
                    if(qli.SBQQ__Quote__c == quote.Id) qliListByQuote.add(qli);
                }
                qliMap.put(quote.Id, qliListByQuote);
            }
        }
        
        //Récupération des devis associé au chantier
        if(!chantierId.isEmpty()) {
            quotesList = [SELECT Id, chantier__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'SAV' AND 
                          SBQQ__LineItemCount__c = 1 AND FDLineNumber__c = 1];
            for (String chId : chantierId) {
                List<SBQQ__Quote__c> quoteListByQuote = new List<SBQQ__Quote__c>();
                for (SBQQ__Quote__c quote : quotesList) {
                    if(quote.chantier__c == chId) {
                        quoteListByQuote.add(quote);
                    }
                }
                quoteMap.put(chId, quoteListByQuote);
            }
        }
        
        if(!quoteMap.isEmpty()) {
            tfProduitList = [SELECT Id, PrixUnitaireHT__c, maxDistance__c, minDistance__c FROM TarifProduit__c WHERE CodeProduit__c = 'FDD_Test'];
        }

        // Traitement
        for (SBQQ__Quote__c newQuote : quotesList2) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);
            
            /-if(Trigger.isUpdate) {
                List<SBQQ__QuoteLine__c> quoteLineList = qliMap.get(newQuote.Id);
                system.debug('quoteLineList : '+quoteLineList);
                system.debug('oldQuote : '+oldQuote);
                List<SBQQ__Quote__c> quoteList = quoteMap.get(newQuote.chantier__c);
                // Processus de calcul des prix
                if(!quoteLineList.isEmpty() && Trigger.isUpdate) {
                    for(SBQQ__QuoteLine__c qli : quoteLineList) {
                        if(qli.caseItem__r.case__r.AssetId != null && qli.caseItem__r.case__r.Type == 'SAV garantie' && qli.productType__c == 'Component') {
                               qli.SBQQ__Bundled__c = false;
                               qli.SBQQ__ComponentListTotal__c = 0;
                               qli.SBQQ__ProratedListPrice__c = 0;
                               qliToUpdate.add(qli);
                           } else if(qli.caseItem__r.case__r.AssetId != null && qli.productType__c == 'Component') {
                               qli.SBQQ__Bundled__c = false;
                               qli.SBQQ__ProratedListPrice__c  = qli.caseItem__r.productOption__r.TPUnitPriceActive__c;
                               qli.laborPrice__c = qli.caseItem__r.productOption__r.TPUnitPriceActive__c * 0.5;
                               qli.SBQQ__ComponentListTotal__c = qli.caseItem__r.productOption__r.TPUnitPriceActive__c * 0.5;
                               qli.SBQQ__NetPrice__c = qli.caseItem__r.productOption__r.TPUnitPriceActive__c + (qli.caseItem__r.productOption__r.TPUnitPriceActive__c * 0.5);
                               qli.SBQQ__CustomerPrice__c = qli.caseItem__r.productOption__r.TPUnitPriceActive__c + (qli.caseItem__r.productOption__r.TPUnitPriceActive__c * 0.5);
                               
                               qliToUpdate.add(qli);
                           }
                        if(qli.productType__c == 'Carpentry') {
                            qli.SBQQ__Bundled__c = true;
                            //qli.SBQQ__ProratedListPrice__c = qli.unitPriceParent__c;
                            //qli.SBQQ__ComponentListTotal__c = qli.laborPriceParent__c;
                            qliToUpdate.add(qli);
                        }
                        
                        //Si forfait déplacement deja existant
                        if(!quoteList.isEmpty() && qli.productType__c == 'Service') {
                            qli.SBQQ__Bundled__c = false;
                            qli.SBQQ__ComponentListTotal__c = 0;
                            qli.SBQQ__ProratedListPrice__c = 0;
                            qliToUpdate.add(qli);
                        } else if(quoteList.isEmpty() && qli.productType__c == 'Service'){
                            qli.SBQQ__Bundled__c = false;
                            qli.SBQQ__ComponentListTotal__c = 0;
                            qliToUpdate.add(qli);                        
                        }
                    }
                        quoteToUpdate.add(newQuote);
                }
            }-/
        }
        
        if(!qliToUpdate.isEmpty()) {
            update qliToUpdate;
        }
        if(!quoteToUpdate.isEmpty()) {
            update quoteToUpdate;
        }
        for (SBQQ__Quote__c newQuote : newQuotes) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);
            if(Trigger.isUpdate) {
                //Si le statut = à configurer passe en en attente d'approbation ET le devis est SAV ET le montant total vaut 0
                
                if(Trigger.isAfter && Trigger.isUpdate && oldQuote!=null && 
                (oldQuote.SBQQ__Status__c=='À configurer' && newQuote.SBQQ__Status__c=='En attente d\'approbation')
                && (newQuote.SBQQ__Type__c=='SAV')
                && (newQuote.MontantTotalTTC__c == 0 && oldQuote.MontantTotalTTC__c==newQuote.MontantTotalTTC__c)){
                    Approval.ProcessSubmitRequest approvalProcessReq = new Approval.ProcessSubmitRequest();
                    approvalProcessReq.setObjectId(newQuote.Id);
                    approvalProcessReq.setProcessDefinitionNameOrId('QuoteGlobalApprovalProcess');
                    Approval.process(approvalProcessReq);
                }
                

                //Si le statut = non transmis ET le devis est SAV ET le montant total change entre l'ancien et le nouveau devis
                if(Trigger.isAfter && Trigger.isUpdate && oldQuote!=null && 
                (oldQuote.SBQQ__Status__c== Constants.QUOTE_STATUS_NOT_TRANSMITTED && newQuote.SBQQ__Status__c==oldQuote.SBQQ__Status__c)
                && (newQuote.RecordTypeId == DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SAV_RT) && oldQuote.RecordTypeId==newQuote.RecordTypeId)
                && (oldQuote.MontantTotalTTC__c != newQuote.MontantTotalTTC__c)){
                    Approval.ProcessSubmitRequest approvalProcessReq = new Approval.ProcessSubmitRequest();
                    approvalProcessReq.setObjectId(newQuote.Id);
                    approvalProcessReq.setProcessDefinitionNameOrId('QuoteGlobalApprovalProcess');
                    Approval.process(approvalProcessReq);
                    System.debug('## isAfter2 oldQuote.SBQQ__Status__c: '+oldQuote.SBQQ__Status__c);
                    System.debug('## isAfter2 newQuote.SBQQ__Status__c: '+newQuote.SBQQ__Status__c);
                    System.debug('## isAfter2 oldQuote.MontantTotalTTC__c: '+oldQuote.MontantTotalTTC__c);
                    System.debug('## isAfter2 newQuote.MontantTotalTTC__c:'+newQuote.MontantTotalTTC__c);
                }
            }
        }
        if(!quoteToUpdate.isEmpty()) {
            //update quoteToUpdate;
        }
        System.debug('### FIN TR022_SBQQ_Quote : updatePrice');
        */
    }
}