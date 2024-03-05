//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_CreateWarrantiesRecordsAsync
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/12/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public class QA_CreateWarrantiesRecordsAsync implements Queueable {
    private Set<Id> qliIds;
    
    public QA_CreateWarrantiesRecordsAsync(Set<Id> qliIds) {
        this.qliIds = qliIds;
    }
    
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_CreateWarrantiesRecordsAsync.createWarrantiesRecordsAsync');

        Map<String, Garantie__c> referentielGarantieMap = new Map<String, Garantie__c>();
        Map<String, CategorieGaranties__c> referentielCatGarantieMap = new Map<String, CategorieGaranties__c>();
        List<DureeGarantiesProduit__c> garantieProduitList = new List<DureeGarantiesProduit__c>();
        List<DureeGarantiesOptions__c> garantieOptionList = new List<DureeGarantiesOptions__c>();        
        List<Entitlement> qliWarrantiesList = new List<Entitlement>();
        List<SBQQ__QuoteLine__c> lignesDevis = new List<SBQQ__QuoteLine__c>();
        Set<String> optionList = new Set<String>();
        Set<String> productList = new Set<String>();
        Map<String, Integer> mapNbWarrantiesByLine = new Map<String, Integer>();

        Savepoint sp = Database.setSavepoint();
        try {
            // Récupération des lignes seulement si le devis est au statut "A configurer"
            for (SBQQ__QuoteLine__c qli : [SELECT Id, SBQQ__Product__c, SBQQ__Bundle__c, referenceDate__c, SBQQ__RequiredBy__c, SBQQ__ProductCode__c,  
                                            SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Status__c FROM SBQQ__QuoteLine__c WHERE Id IN :qliIds]) { 
                if(qli.SBQQ__Quote__r.SBQQ__Status__c == Constants.QUOTE_STATUS_TO_CONFIGURE) {
                    lignesDevis.add(qli); 
                }
            }
                                                        
            if (!lignesDevis.isEmpty()) {
                // Récupération des Ids des options et des produits
                for (SBQQ__QuoteLine__c qli : lignesDevis) {
                    System.debug('## Quote line: '+qli.Id);
                    System.debug('## SBQQ__Bundle__c: '+qli.SBQQ__Bundle__c);
                    System.debug('## SBQQ__Product__c: '+qli.SBQQ__Product__c);
                    if(qli.SBQQ__Bundle__c) {
                        productList.add(qli.SBQQ__Product__c); 
                    } else {
                        optionList.add(qli.SBQQ__ProductCode__c); 
                    }
                }
                System.debug('## Products: '+productList);
                // SOQL - SELECT - Récupération des options des lignes parent
                if (!productList.isEmpty()) {
                    for(SBQQ__QuoteLine__c qli : [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c 
                                                    WHERE SBQQ__RequiredBy__c IN :lignesDevis]) {
                        optionList.add(qli.SBQQ__ProductCode__c); 
                    }
                }
                System.debug('## Options: '+optionList);

                // SOQL - SELECT - Récupération des codes et garanties options si la liste d'id des ligne n'est pas vide (mode update)
                if (!optionList.isEmpty()) {
                    garantieOptionList = [SELECT Id, codeGarantie__c, codeOption__c, dateDebutValidite__c, dateFinValidite__c, codeGarantie__r.code__c, 
                                            duree__c, codeGarantie__r.libelle__c, codeGarantie__r.dateDebutValidite__c, codeOption__r.CodeOption__c,
                                            codeGarantie__r.dateFinValidite__c, codeGarantie__r.categorie__r.code__c, codeGarantie__r.categorie__r.libelle__c, 
                                            codeGarantie__r.categorie__r.dateDebutValidite__c, codeGarantie__r.categorie__r.dateFinValidite__c 
                                            FROM DureeGarantiesOptions__c WHERE codeOption__r.CodeOption__c IN :optionList ORDER BY dateDebutValidite__c ASC];
                    for (DureeGarantiesOptions__c infosGarantieOptions : garantieOptionList) {
                        Garantie__c infosGarantie = infosGarantieOptions.codeGarantie__r;
                        CategorieGaranties__c infosCatGarantie = infosGarantieOptions.codeGarantie__r.categorie__r;
                        referentielGarantieMap.put(String.valueOf(infosGarantie.libelle__c + infosGarantie.code__c), infosGarantie);
                        referentielCatGarantieMap.put(String.valueOf(infosGarantie.categorie__r.libelle__c + infosGarantie.categorie__c), infosCatGarantie);
                    }
                }

                // SOQL - SELECT - Récupération des garanties produits
                if (!productList.isEmpty()) {
                    garantieProduitList = [SELECT Id, codeProduit__c, dateDebutValidite__c, dateFinValidite__c, codeGarantie__c, codeGarantie__r.code__c, 
                                            duree__c, codeGarantie__r.libelle__c, codeGarantie__r.dateDebutValidite__c, 
                                            codeGarantie__r.dateFinValidite__c, codeGarantie__r.categorie__r.code__c, codeGarantie__r.categorie__r.libelle__c, 
                                            codeGarantie__r.categorie__r.dateDebutValidite__c, codeGarantie__r.categorie__r.dateFinValidite__c 
                                            FROM DureeGarantiesProduit__c WHERE codeProduit__c IN :productList ORDER BY dateDebutValidite__c ASC];
                    // Récupération du référenciel des garanties
                    for (DureeGarantiesProduit__c infosGarantieProduits : garantieProduitList) {
                        Garantie__c infosGarantie = infosGarantieProduits.codeGarantie__r;
                        CategorieGaranties__c infosCatGarantie = infosGarantieProduits.codeGarantie__r.categorie__r;
                        referentielGarantieMap.put(String.valueOf(infosGarantie.libelle__c + infosGarantie.code__c), infosGarantie);
                        referentielCatGarantieMap.put(String.valueOf(infosGarantie.categorie__r.libelle__c + infosGarantie.categorie__c), infosCatGarantie);
                    }
                }

                // Tri des catégories et garanties par ordre alphabétique
                List<String> categorieNameList = new List<String>();
                categorieNameList.addAll(referentielCatGarantieMap.keySet());
                categorieNameList.sort();

                List<String> garantieNameList = new List<String>();
                garantieNameList.addAll(referentielGarantieMap.keySet());
                garantieNameList.sort();

                System.debug('## Map de référentiel cat garantie: '+referentielCatGarantieMap);
                System.debug('## Map de référentiel garantie: '+referentielGarantieMap);

                // Pour chaque ligne de devis, on additionne les durées contenues dans les garanties produit/option, classées par garanties de référence
                for (SBQQ__QuoteLine__c qli : lignesDevis) {
                    // Assignation de la garantie produit avec chaque ligne de devis (Comparaison entre le produit QLI et la liste de produit extraite pour aller chercher les GarantiesProduit correspondantes)
                    Map<String,DureeGarantiesProduit__c> garantieProduitUsedList = new Map<String,DureeGarantiesProduit__c>();
                    for (DureeGarantiesProduit__c garPro : garantieProduitList) {
                        // Vérification de la validité des garanties produit par rapport à la date du devis
                        if (garPro.codeProduit__c == qli.SBQQ__Product__c 
                        && qli.referenceDate__c >= garPro.dateDebutValidite__c
                        && (qli.referenceDate__c <= garPro.dateFinValidite__c || garPro.dateFinValidite__c == null)) {
                            // Pour cette ligne, on ajoute toutes les durées garanties produit dont la date de début et plus récente
                            String key = garPro.codeProduit__c+''+garPro.codeGarantie__c;
                            garantieProduitUsedList.put(key, garPro);
                        }
                    }
                    
                    // Assignation des garanties options avec chaque ligne de devis (Comparaison entre les options de ligne et la liste d'options extraite pour aller chercher les GarantiesOption correspondantes)
                    Map<String,DureeGarantiesOptions__c> garantieOptionUsedList = new Map<String,DureeGarantiesOptions__c>();
                    for (DureeGarantiesOptions__c garOpt : garantieOptionList) {
                        // Vérification de la validité des garanties options par rapport à la date du devis
                        if (garOpt.codeOption__r.CodeOption__c == qli.SBQQ__ProductCode__c 
                        && qli.referenceDate__c >= garOpt.dateDebutValidite__c 
                        && (qli.referenceDate__c <= garOpt.dateFinValidite__c || garOpt.dateFinValidite__c == null)) {
                            // Pour cette ligne, on ajoute toutes les durées garanties option dont la date de début et plus récente
                            String key = garOpt.codeOption__r.CodeOption__c+''+garOpt.codeGarantie__c;
                            garantieOptionUsedList.put(key, garOpt);
                        }
                    }

                    // On boucle sur les garanties référencées pour alimenter les champs de QLI avec toutes les garanties produit/option
                    Integer nbWarranties = 0;
                    String lineId = (qli.SBQQ__Bundle__c) ? qli.Id : qli.SBQQ__RequiredBy__c;
                    System.debug('## lineId: '+lineId);
                    for (String codeCat : categorieNameList) {
                        CategorieGaranties__c categorie=referentielCatGarantieMap.get(codeCat);
                        for (String codeGar : garantieNameList) {
                            if(referentielGarantieMap.get(codeGar).categorie__r == categorie){
                                Decimal duree = 0;
                                Garantie__c garantie = referentielGarantieMap.get(codeGar);
                                if(garantie != null) {
                                    System.debug('## GARANTIE: '+garantie.libelle__c);
                                    // Vérification de la validité des garanties par rapport à la date du devis
                                    if (qli.referenceDate__c >= garantie.dateDebutValidite__c
                                        && (qli.referenceDate__c <= garantie.dateFinValidite__c || garantie.dateFinValidite__c == null) 
                                        && qli.referenceDate__c >= categorie.dateDebutValidite__c
                                        && (qli.referenceDate__c <= categorie.dateFinValidite__c || categorie.dateFinValidite__c == null)) {
                                        // AJout de la durée garantie produit
                                        for (DureeGarantiesProduit__c dureeGarProduit : garantieProduitUsedList.values()) {
                                            if (dureeGarProduit.codeGarantie__c == garantie.Id) {
                                                System.debug('## AJOUT DE LA DUREE PRODUIT: '+dureeGarProduit.codeGarantie__c+' / '+dureeGarProduit.duree__c);
                                                duree = duree + dureeGarProduit.duree__c;
                                            }
                                        }
                                        // Ajout des durées garanties options
                                        for (DureeGarantiesOptions__c dureeGarOpt : garantieOptionUsedList.values()) {
                                            if (dureeGarOpt.codeGarantie__c == garantie.Id) {
                                                system.debug('## AJOUT DE LA DUREE OPTION: '+dureeGarOpt.codeGarantie__c+' / '+dureeGarOpt.duree__c);
                                                duree = duree + dureeGarOpt.duree__c;
                                            }
                                        }
                                    }
                                    // Si cette garantie a une durée, on créé un nouvel objet Entitlement pour stocker la garantie et la lier à la ligne de devis
                                    if (duree != 0) {
                                        Entitlement qliWarranty = new Entitlement();
                                        System.debug('## DUREE DE '+duree+' POUR LA GARANTIE '+garantie.code__c+' / '+garantie.libelle__c);
                                        // Champ garantie
                                        qliWarranty.categoryReference__c = referentielCatGarantieMap.get(String.valueOf(garantie.categorie__r.libelle__c + garantie.categorie__c)).code__c;
                                        qliWarranty.category__c = referentielCatGarantieMap.get(String.valueOf(garantie.categorie__r.libelle__c + garantie.categorie__c)).libelle__c;
                                        qliWarranty.KparKReference__c = garantie.code__c;
                                        qliWarranty.Name = garantie.libelle__c;
                                        qliWarranty.duration__c = duree;
                                        // Champ commun
                                        qliWarranty.quoteLineCPQ__c = lineId;
                                        qliWarranty.AccountId = qli.SBQQ__Quote__r.SBQQ__Account__c;
                                        qliWarranty.Type = 'Garantie';                           
                                        qliWarranty.RecordTypeId = DAL.getRecordTypeIdByDevName('Entitlement', 'OrderWarranty');      
                                        qliWarrantiesList.add(qliWarranty);    
                                        // Compteur nombre de garanties sur la ligne
                                        nbWarranties++;   
                                    }
                                }
                            }
                        }
                    }
                    // Alimentation MAP nb de garanties sur la ligne
                    if(String.isNotBlank(lineId)) {
                        mapNbWarrantiesByLine.put(lineId, nbWarranties);
                    }
                }

                // Si garantie, on supprime les anciennes avant de les ajouter
                if(!qliWarrantiesList.isEmpty()) {
                    List<Entitlement> warrantiesToDelete = [SELECT Id FROM Entitlement WHERE quoteLineCPQ__c IN :lignesDevis];
                    if(!warrantiesToDelete.isEmpty()) {
                        System.debug('## Suppression des garanties: '+warrantiesToDelete);
                        delete warrantiesToDelete;
                    }
                    System.debug('## Ajout des garanties: '+qliWarrantiesList);
                    insert qliWarrantiesList;
                }

                // MAJ du nombre de garanties sur les lignes
                
                Map<String, Integer> mapWarrantiesLineCounts = new Map<String, Integer>();
                List<AggregateResult> warrantiesLineCount = new List<AggregateResult>();
                List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
                List<SBQQ__QuoteLine__c> quoteLineToUpdate = new List<SBQQ__QuoteLine__c>();
                
                // Récupération des lignes enfants
                if(!qliIds.isEmpty()) {
                    warrantiesLineCount = [SELECT COUNT(ID) cnt , quoteLineCPQ__c FROM Entitlement WHERE quoteLineCPQ__c IN: qliIds GROUP BY quoteLineCPQ__c];
                    quoteLines = [SELECT Id, warrantiesLineCount__c FROM SBQQ__QuoteLine__c WHERE Id IN: qliIds];
                    for (String qId : qliIds) {
                        for(AggregateResult agrR : warrantiesLineCount) {
                            if(qId == agrR.get('quoteLineCPQ__c')) {
                                Integer count = integer.valueOf(agrR.get('cnt'));
                                mapWarrantiesLineCounts.put(qId, count);
                            }
                        }
                    }
                }
                
                /*for(SBQQ__QuoteLine__c newQuoteLineItem : quoteLines) {
                    if(!mapWarrantiesLineCounts.isEmpty()) {
                        if(newQuoteLineItem.warrantiesLineCount__c != mapWarrantiesLineCounts.get(newQuoteLineItem.Id)) {
                            newQuoteLineItem.warrantiesLineCount__c = mapWarrantiesLineCounts.get(newQuoteLineItem.Id);
                            quoteLineToUpdate.add(newQuoteLineItem);
                        }
                    }
                }
                if(!quoteLineToUpdate.isEmpty())
                    update quoteLineToUpdate;*/
                /*if(!mapNbWarrantiesByLine.isEmpty()) {
                    System.debug('## Mise à jour indicateur des lignes');
                    List<SBQQ__QuoteLine__c> qliToUpdate = new List<SBQQ__QuoteLine__c>();
                    for(String lineId : mapNbWarrantiesByLine.keySet()) {
                        Integer nbWarranties = mapNbWarrantiesByLine.get(lineId);
                        System.debug('## QuoteLine: '+lineId+' / '+nbWarranties);
                        qliToUpdate.add(new SBQQ__QuoteLine__c(Id = lineId, warrantiesLineCount__c = nbWarranties));
                    }
                    //update qliToUpdate;
                }*/
            }
        } catch(exception e) {
            Database.rollback(sp);
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN QA_CreateWarrantiesRecordsAsync.createWarrantiesRecordsAsync');
    }
}