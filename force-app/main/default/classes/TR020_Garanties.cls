//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Garanties 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/06/2022
//-- Version     : 1.1
//-- * 1.1 : Kube3 : Modification pour utiliser la date de référence
//-- * 1.0 : CRM-952 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Garanties {

    /**
    * @description Mise à jour des garanties des lignes de devis
    * @param lignesDevis lignes de devis à mettre à jour
    */
    public static void refreshGaranties(List<QuoteLineItem> lignesDevis) {
        System.debug('### DEBUT TR020_Garanties.refreshGaranties');
        Map<String, Garantie__c> referencielGarantieMap = new Map<String, Garantie__c>();
        Map<String, CategorieGaranties__c> referencielCatGarantieMap = new Map<String, CategorieGaranties__c>();
        List<DureeGarantiesProduit__c> garantieProduitList = new List<DureeGarantiesProduit__c>();
        List<DureeGarantiesOptions__c> garantieOptionList = new List<DureeGarantiesOptions__c>();
        List<Option__c> optionsDeLigne = new List<Option__c>();
        Set<String> optionList = new Set<String>();
        Set<Id> ligneDevisIdList = new Set<Id>();
        Set<Id> pbeIdList = new Set<Id>();
        Set<Id> codeGarantieList = new Set<Id>();
        Map<String,String> refpbeProduct = new Map<String,String>();
        Integer nbFields=0;

        // Stockage de la liste des Ids des lignes de devis et des produits
        for (QuoteLineItem qli : lignesDevis) {
            // Ne pas recalculer les garanties plusieurs fois dans la transaction APEX
            if (String.isNotBlank(qli.Id) && !AlreadyUsed.isUsed('TR020_Garanties.refreshGaranties', qli.Id)) {
                ligneDevisIdList.add(qli.Id);
            }
            pbeIdList.add(qli.PricebookEntryId); // Obligation d'utiliser PricebookEntry (Product2Id toujours null)
        }

        try {
            // SOQL - SELECT - Récupération des codes et garanties options si la liste d'id des ligne n'est pas vide (mode update)
            if (!ligneDevisIdList.isEmpty()) {
                optionsDeLigne = [SELECT Id, Option__c, ligneDevis__c FROM Option__c 
                                    WHERE IsDeleted=false AND ligneDevis__c IN :ligneDevisIdList];
                for (Option__c opt : optionsDeLigne) {
                    optionList.add(opt.Option__c);
                }
                if (!optionList.isEmpty()) {
                    garantieOptionList = [SELECT Id, codeGarantie__c, codeOption__c, dateDebutValidite__c, dateFinValidite__c, codeGarantie__r.code__c, 
                                            duree__c, codeGarantie__r.libelle__c, codeGarantie__r.dateDebutValidite__c, 
                                            codeGarantie__r.dateFinValidite__c, codeGarantie__r.categorie__r.code__c, codeGarantie__r.categorie__r.libelle__c, 
                                            codeGarantie__r.categorie__r.dateDebutValidite__c, codeGarantie__r.categorie__r.dateFinValidite__c 
                                            FROM DureeGarantiesOptions__c WHERE codeOption__c IN :optionList ORDER BY dateDebutValidite__c ASC];
                    for (DureeGarantiesOptions__c infosGarantieOptions : garantieOptionList) {
                        //codeGarantieList.add(infosGarantieOptions.codeGarantie__c);
                        Garantie__c infosGarantie = infosGarantieOptions.codeGarantie__r;
                        CategorieGaranties__c infosCatGarantie = infosGarantieOptions.codeGarantie__r.categorie__r;
                        referencielGarantieMap.put(String.valueOf(infosGarantie.libelle__c + infosGarantie.code__c), infosGarantie);
                        referencielCatGarantieMap.put(String.valueOf(infosGarantie.categorie__r.libelle__c + infosGarantie.categorie__c), infosCatGarantie);
                    }
                }
            }
                
            // SOQL - SELECT - Récupération des garanties produits
            if (!pbeIdList.isEmpty()) {
                for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Id IN :pbeIdList]) {
                    refpbeProduct.put(pbe.Id, pbe.Product2Id);
                }
                if (!refpbeProduct.values().isEmpty()) {
                    garantieProduitList = [SELECT Id, codeProduit__c, dateDebutValidite__c, dateFinValidite__c, codeGarantie__c, codeGarantie__r.code__c, 
                                            duree__c, codeGarantie__r.libelle__c, codeGarantie__r.dateDebutValidite__c, 
                                            codeGarantie__r.dateFinValidite__c, codeGarantie__r.categorie__r.code__c, codeGarantie__r.categorie__r.libelle__c, 
                                            codeGarantie__r.categorie__r.dateDebutValidite__c, codeGarantie__r.categorie__r.dateFinValidite__c 
                                            FROM DureeGarantiesProduit__c WHERE codeProduit__c IN :refpbeProduct.values() ORDER BY dateDebutValidite__c ASC];
                    // Récupération du référenciel des garanties
                    for (DureeGarantiesProduit__c infosGarantieProduits : garantieProduitList) {
                        Garantie__c infosGarantie = infosGarantieProduits.codeGarantie__r;
                        CategorieGaranties__c infosCatGarantie = infosGarantieProduits.codeGarantie__r.categorie__r;
                        referencielGarantieMap.put(String.valueOf(infosGarantie.libelle__c + infosGarantie.code__c), infosGarantie);
                        referencielCatGarantieMap.put(String.valueOf(infosGarantie.categorie__r.libelle__c + infosGarantie.categorie__c), infosCatGarantie);
                    }
                }
            }

            // Calcul du nombre de champs "Garantie" présent sur l'objet
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('QuoteLineItem').getDescribe().fields.getMap();
            for(String key : fieldsMap.keySet()) {
                if(key.containsIgnoreCase('codegarantie'))
                    nbFields++;
            }

            // Tri des catégories et garanties par ordre alphabétique
            List<String> categorieNameList = new List<String>();
            categorieNameList.addAll(referencielCatGarantieMap.keySet());
            categorieNameList.sort();

            List<String> garantieNameList = new List<String>();
            garantieNameList.addAll(referencielGarantieMap.keySet());
            garantieNameList.sort();

            System.debug('## Map de référenciel cat garantie : '+referencielCatGarantieMap);
            System.debug('## Map de référenciel garantie : '+referencielGarantieMap);

            // Pour chaque ligne de devis, on additionne les durées contenues dans les garanties produit/option, classées par garanties de référence
            for (QuoteLineItem qli : lignesDevis) {
                // Assignation de la garantie produit avec chaque ligne de devis (Comparaison entre le produit QLI et la liste de produit extraite pour aller chercher les GarantiesProduit correspondantes)
                Map<String,DureeGarantiesProduit__c> garantieProduitUsedList = new Map<String,DureeGarantiesProduit__c>();
                for (DureeGarantiesProduit__c garPro : garantieProduitList) {
                    // Vérification de la validité des garanties produit par rapport à la date du devis
                    if (garPro.codeProduit__c == refpbeProduct.get(qli.PricebookEntryId) 
                    && qli.referenceDate__c >= garPro.dateDebutValidite__c
                    && (qli.referenceDate__c <= garPro.dateFinValidite__c || garPro.dateFinValidite__c == null)) {
                        // Pour cette ligne, on ajoute toutes les durées garanties produit dont la date de début et plus récente
                        String key = garPro.codeProduit__c+''+garPro.codeGarantie__c;
                        garantieProduitUsedList.put(key, garPro);
                    }
                }
                
                // Assignation des garanties options avec chaque ligne de devis (Comparaison entre les options de ligne et la liste d'options extraite pour aller chercher les GarantiesOption correspondantes)
                Map<String,DureeGarantiesOptions__c> garantieOptionUsedList = new Map<String,DureeGarantiesOptions__c>();
                for (Option__c opt : optionsDeLigne) {
                    if (qli.Id == opt.ligneDevis__c) {
                        for (DureeGarantiesOptions__c garOpt : garantieOptionList) {
                            // Vérification de la validité des garanties options par rapport à la date du devis
                            if (garOpt.codeOption__c == opt.Option__c 
                            && qli.referenceDate__c >= garOpt.dateDebutValidite__c 
                            && (qli.referenceDate__c <= garOpt.dateFinValidite__c || garOpt.dateFinValidite__c == null)) {
                                // Pour cette ligne, on ajoute toutes les durées garanties option dont la date de début et plus récente
                                String key = garOpt.codeOption__c+''+garOpt.codeGarantie__c;
                                garantieOptionUsedList.put(key, garOpt);
                            }
                        }
                    }
                }

                Integer categorieIndex = 0;
                // On boucle sur les garanties référencées pour alimenter les champs de QLI avec toutes les garanties produit/option
                for (String codeCat : categorieNameList) {
                    CategorieGaranties__c categorie=referencielCatGarantieMap.get(codeCat);
                    for (String codeGar : garantieNameList) {
                        if(referencielGarantieMap.get(codeGar).categorie__r == categorie){
                            Decimal duree = 0;
                            Garantie__c garantie=referencielGarantieMap.get(codeGar);
                            if(garantie!=null) {
                                System.debug('## GARANTIE: '+garantie.libelle__c);
                                // Vérification de la validité des garanties par rapport à la date du devis
                                if (qli.referenceDate__c >= garantie.dateDebutValidite__c
                                    && (qli.referenceDate__c <= garantie.dateFinValidite__c || garantie.dateFinValidite__c == null) 
                                    && qli.referenceDate__c >= categorie.dateDebutValidite__c
                                    && (qli.referenceDate__c <= categorie.dateFinValidite__c || categorie.dateFinValidite__c == null)) {
                                    // AJout de la durée garantie produit
                                    for (DureeGarantiesProduit__c dureeGarProduit : garantieProduitUsedList.values()) {
                                        if (dureeGarProduit.codeGarantie__c == garantie.Id) {
                                            System.debug('## AJOUT DE LA DUREE PRODUIT : '+dureeGarProduit.codeGarantie__c+' / '+dureeGarProduit.duree__c);
                                            duree = duree + dureeGarProduit.duree__c;
                                        }
                                    }
                                    // Ajout des durées garanties options
                                    for (DureeGarantiesOptions__c dureeGarOpt : garantieOptionUsedList.values()) {
                                        if (dureeGarOpt.codeGarantie__c == garantie.Id) {
                                            System.debug('## AJOUT DE LA DUREE OPTION : '+dureeGarOpt.codeGarantie__c+' / '+dureeGarOpt.duree__c);
                                            duree = duree + dureeGarOpt.duree__c;
                                        }
                                    }
                                }
                                // Si cette garantie a une durée, on renseigne les 5 champs de la garantie sur la ligne de devis
                                if (duree != 0) {
                                    CategorieCustom qliGarantieList = new CategorieCustom();
                                    System.debug('## DUREE DE '+duree+' POUR LA GARANTIE '+garantie.code__c+' / '+garantie.libelle__c);
                                    qliGarantieList.codeCategorie = referencielCatGarantieMap.get(String.valueOf(garantie.categorie__r.libelle__c + garantie.categorie__c)).code__c;
                                    qliGarantieList.libelleCategorie = referencielCatGarantieMap.get(String.valueOf(garantie.categorie__r.libelle__c + garantie.categorie__c)).libelle__c;
                                    qliGarantieList.codeGarantie = garantie.code__c;
                                    qliGarantieList.libelleGarantie = garantie.libelle__c;
                                    qliGarantieList.dureeGarantie = duree;
                                    categorieIndex++;
                                    if (categorieIndex <= nbFields)
                                        qli = updateMetadataGaranties(qli, qliGarantieList, String.valueOf(categorieIndex));
                                }
                            }
                        }
                    }
                }
                while(categorieIndex < nbFields){
                    categorieIndex++;
                    qli = updateMetadataGaranties(qli, null, String.valueOf(categorieIndex));
                }
            }
            System.debug('### FIN TR020_Garanties.refreshGaranties');
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Mise à jour des metadata pour chaque garantie et pour une ligne de devis
    * @param qli lignes de devis à mettre à jour
    * @param categorieQLI Objet contenant les informations de la garantie
    * @param nbIterationGarantie Itération de la garantie 
    */
    private static QuoteLineItem updateMetadataGaranties(QuoteLineItem qli, CategorieCustom categorieQLI, String nbIterationGarantie) {
        // Mise à jour des champs selon les metadata sur l'objet QLI
        if(categorieQLI != null){
            qli.put('codeCategorieGarantie'+nbIterationGarantie+'__c', categorieQLI.codeCategorie);
            qli.put('libelleCategorieGarantie'+nbIterationGarantie+'__c', categorieQLI.libelleCategorie);
            qli.put('codeGarantie'+nbIterationGarantie+'__c', categorieQLI.codeGarantie);
            qli.put('libelleGarantie'+nbIterationGarantie+'__c', categorieQLI.libelleGarantie);
            qli.put('dureeGarantie'+nbIterationGarantie+'__c', categorieQLI.dureeGarantie);
        } else {
            qli.put('codeCategorieGarantie'+nbIterationGarantie+'__c', null);
            qli.put('libelleCategorieGarantie'+nbIterationGarantie+'__c', null);
            qli.put('codeGarantie'+nbIterationGarantie+'__c', null);
            qli.put('libelleGarantie'+nbIterationGarantie+'__c', null);
            qli.put('dureeGarantie'+nbIterationGarantie+'__c', null);
        }
        return qli;
    }

    // Objet custom pour stcocker l'ensembles des infos d'une catégorie à intégrer dans une ligne de devis
    public class CategorieCustom {
        public String codeCategorie { get; set; }
        public String libelleCategorie { get; set; }
        public String codeGarantie { get; set; }
        public String libelleGarantie { get; set; }
        public Decimal dureeGarantie { get; set; }
        public CategorieCustom() { }
    }
}