/**
 * Created by Gregory Quinet on 15/09/2020.
 *
 * Traitement par lot des commissions vendeur dans le cadre du cliché.
 * Les commissions commissionnables et régularisables sont prises en compte
 * et modifiées respectivement en commissionné et régularisé. La date de cliché est également positionné.
 * Dans le cas où un vendeur à une commission de prochain cliché négative, une commission régularisable
 * complémentaire est ajoutée pour le calcul du cliché suivant.
 */

global class BA_SalesCommissionInstant implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, store__c, quoteLine__c, ' +
                'customerOrder__r.OrderNumber, quote__r.TotalTTCTarif__c, quote__r.TotalTTClignes__c, ' +
                'productCom__r.SBQQ__Product__r.Name, productCom__r.PrixUnitaire__c, ' +
                'quoteCPQ__r.MontantTotalTTC__c, quoteCPQ__r.SBQQ__ListAmount__c, productCom__r.SBQQ__ProductCode__c, ' +
                'customerOrder__r.customerSigned__r.LastName, customerOrder__r.customerSigned__r.FirstName, ' +
                'customerOrder__r.customerSignedDate__c, productCom__r.SBQQ__Number__c, ' +
                'productCom__r.Quantite__c, rate__c, ecPercent__c, productRate__c, teamRate__c, salesRem__c, ' +
                'turnoverLevel__c, comType__c, financingMethodName__c , discountCoefficient__c, remuneration__c, ' +
                'quoteCPQ__c, instantDate__c, calculationDate__c, user__r.reference__c, store__r.codeMagasinActuel__c, ' +
                'status__c, user__c, user__r.firstName__c, user__r.lastName__c FROM NRV10Commission__c WHERE status__c IN (\'' +
                Constants.COMMISSION_STATUS_COMMISSIONABLE + '\',\'' +
                Constants.COMMISSION_STATUS_PREVISIONEL + '\',\'' +
                Constants.COMMISSION_STATUS_REGULARIZABLE + '\')' +
                ' AND instantDate__c = null ORDER BY user__c';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<NRV10Commission__c> scope) {
        System.debug('Starting RemVrp instant batch');
        List<NRV10Commission__c> toUpsert = new List<NRV10Commission__c>();
        //prepare list of sales collaborators Ids
        //Sum all due and undue commissions per collaborator
        Map<Id, Double> collabCurrentComMap = new Map<Id, Double>();
        Map<Id, Double> collabRegulComMap = new Map<Id, Double>();
        Map<Id, Double> collabReportComMap = new Map<Id, Double>();
        Map<Id, Double> collaboratorCommMap = new Map<Id, Double>();
        Map<Id, Double> collaboratorRegulMap = new Map<Id, Double>();
        Map<Id, Map<String, Map<String, List<NRV10Commission__c>>>> collaboratorCommissionsMap =
                new Map<Id, Map<String, Map<String, List<NRV10Commission__c>>>>();
        Map<String, BA_SalesCommissionInstant.ContractFileStruct> contractFileStructMap =
                new Map<String, BA_SalesCommissionInstant.ContractFileStruct>();
        List<Id> collaboratorIds = new List<Id>();
        for (NRV10Commission__c c : scope) {
            // Preprocess report
            if (c.status__c == Constants.COMMISSION_STATUS_COMMISSIONABLE) {
                if (!collabCurrentComMap.containsKey(c.user__c)) {
                    collabCurrentComMap.put(c.user__c, c.remuneration__c);
                } else {
                    collabCurrentComMap.put(c.user__c, collabCurrentComMap.get(c.user__c) + c.remuneration__c);
                }
            }
            if (c.status__c == Constants.COMMISSION_STATUS_REGULARIZABLE
                    && c.comType__c != Constants.COMMISSION_TYPE_REPORT) {
                if (!collabRegulComMap.containsKey(c.user__c)) {
                    collabRegulComMap.put(c.user__c, c.remuneration__c);
                } else {
                    collabRegulComMap.put(c.user__c, collabRegulComMap.get(c.user__c) + c.remuneration__c);
                }
            }
            if (c.status__c == Constants.COMMISSION_STATUS_REGULARIZABLE
                    && c.comType__c == Constants.COMMISSION_TYPE_REPORT) {
                if (!collabReportComMap.containsKey(c.user__c)) {
                    collabReportComMap.put(c.user__c, c.remuneration__c);
                } else {
                    collabReportComMap.put(c.user__c, collabReportComMap.get(c.user__c) + c.remuneration__c);
                }
            }

            // Update commissions status for sales, team, report and malus
            if ((c.status__c == Constants.COMMISSION_STATUS_REGULARIZABLE
                    || c.status__c == Constants.COMMISSION_STATUS_COMMISSIONABLE)
                    && (c.comType__c == Constants.COMMISSION_TYPE_SALES
                    || c.comType__c == Constants.COMMISSION_TYPE_TEAM
                    || c.comType__c == Constants.COMMISSION_TYPE_MALUS
                    || c.comType__c == Constants.COMMISSION_TYPE_REPORT)) {

                if (!collaboratorIds.contains(c.user__c)) collaboratorIds.add(c.user__c);
                if (c.status__c == Constants.COMMISSION_STATUS_COMMISSIONABLE) {
                    if (!collaboratorCommMap.containsKey(c.user__c)) {
                        collaboratorCommMap.put(c.user__c, c.remuneration__c);
                    } else {
                        collaboratorCommMap.put(c.user__c, collaboratorCommMap.get(c.user__c) + c.remuneration__c);
                    }
                    c.status__c = Constants.COMMISSION_STATUS_COMMISSIONED;
                } else if (c.status__c == Constants.COMMISSION_STATUS_REGULARIZABLE) {
                    if (!collaboratorRegulMap.containsKey(c.user__c)) {
                        collaboratorRegulMap.put(c.user__c, c.remuneration__c);
                    } else {
                        collaboratorRegulMap.put(c.user__c, collaboratorRegulMap.get(c.user__c) + c.remuneration__c);
                    }
                    c.status__c = Constants.COMMISSION_STATUS_REGULATED;
                }
                c.instantDate__c = Date.today();
                toUpsert.add(c);
            }

            // Bonus status
            if (c.status__c == Constants.COMMISSION_STATUS_PREVISIONEL
                    && c.comType__c == Constants.COMMISSION_TYPE_BONUS) {

                c.status__c = Constants.COMMISSION_STATUS_COMMISSIONED;
                toUpsert.add(c);
            }
            if (!collaboratorCommissionsMap.containsKey(c.user__c)) {
                collaboratorCommissionsMap
                        .put(c.user__c, new Map<String, Map<String, List<NRV10Commission__c>>>());
            }
            if (!collaboratorCommissionsMap.get(c.user__c).containsKey(c.comType__c)) {
                collaboratorCommissionsMap.get(c.user__c)
                        .put(c.comType__c, new Map<String, List<NRV10Commission__c>>());
            }
            if (!collaboratorCommissionsMap.get(c.user__c).get(c.comType__c).containsKey(c.status__c)) {
                collaboratorCommissionsMap.get(c.user__c).get(c.comType__c)
                        .put(c.status__c, new List<NRV10Commission__c>());
            }
            collaboratorCommissionsMap.get(c.user__c).get(c.comType__c).get(c.status__c).add(c);

            if (!contractFileStructMap.containsKey(c.customerOrder__r.OrderNumber)) {
                ContractFileStruct struct = new ContractFileStruct();
                struct.conCode = c.customerOrder__r.OrderNumber;
                struct.calcDate = c.calculationDate__c;
                struct.instDate = c.instantDate__c;
                struct.calDeb = c.calculationDate__c;
                struct.conMontantCotation = c.quoteCPQ__r.SBQQ__ListAmount__c != null ? c.quoteCPQ__r.SBQQ__ListAmount__c : c.quote__r.TotalTTClignes__c;
                struct.conMontantTTC = c.quoteCPQ__r.MontantTotalTTC__c != null ? c.quoteCPQ__r.MontantTotalTTC__c : c.quote__r.TotalTTCTarif__c;
                struct.signataireNom = c.customerOrder__r.customerSigned__r.LastName;
                struct.signatairePrenom = c.customerOrder__r.customerSigned__r.FirstName;
                struct.conDecote = c.discountCoefficient__c;
//                struct.conEcRate = c.ecPercent__c;
                struct.ecRate = c.ecPercent__c;
                struct.venCode = c.user__r.reference__c;
                struct.conVente = c.customerOrder__r.customerSignedDate__c;
                struct.remMontant = 0.0;
                //struct.gdeCode = 0.0;

                contractFileStructMap.put(c.customerOrder__r.OrderNumber, struct);
            }
            if (c.comType__c == Constants.COMMISSION_TYPE_SALES) {
                contractFileStructMap.get(c.customerOrder__r.OrderNumber).remMontant += c.remuneration__c;
            }
        }


        //get sales collaborators data and create regul if needed
        for (Id cId : collaboratorIds) {
            Double nextInstant = (collabCurrentComMap.containsKey(cId) ? collabCurrentComMap.get(cId) : 0.0)
                    - (collabRegulComMap.containsKey(cId) ? collabRegulComMap.get(cId) : 0.0)
                    + (collabReportComMap.containsKey(cId) ? collabReportComMap.get(cId) : 0.0);
            if (nextInstant < 0) {
                if (!collaboratorRegulMap.containsKey(cId)) collaboratorRegulMap.put(cId, 0.0);
                collaboratorRegulMap.put(cId, collaboratorRegulMap.get(cId) + nextInstant);

                NRV10Commission__c regulCom = new NRV10Commission__c();
                regulCom.comType__c = Constants.COMMISSION_TYPE_REPORT;
                regulCom.status__c = Constants.COMMISSION_STATUS_REGULARIZABLE;
                regulCom.user__c = cId;
                regulCom.remuneration__c = nextInstant;
                regulCom.calculationDate__c = Date.today();
                toUpsert.add(regulCom);
            }
        }

        upsert toUpsert;


        //Create csv file

        //get snapshot date object
        NRV10Calendar__c cal = [SELECT Id, commDate__c, snapshotFor__c FROM NRV10Calendar__c WHERE commDate__c = TODAY LIMIT 1];

        String headerSales = 'ven_code, cal_cal_deb, rcom_code, mag_code, ven_rptrem_vente, ven_rempdt_vente, ven_rempdt_equipe, gbo_code, rbo_date, ven_bonus_ca, gma_method, rma_date, ven_rempdt_malus, Date instantané, Date de calcul';
        String headerTeam = 'ven_code, geq_code, req_date, eq_rempdt_taux, eq_rempdt_montant, Date instantané, Date de calcul';
        String headerProd = 'cal_cal_deb, con_code, pdt_ligne, fam_code, pdt_prix_unitaire, pdt_quantite, gvp_code, rvp_date, pdt_rempdt_montant_avd, Date instantané, Date de calcul';
        String headerBonus = '';
        String headerMalus = '';
        String headerReport = '';

        List<String> rowsSales = new List<String>();
        List<String> rowsTeam = new List<String>();
        List<String> rowsProd = new List<String>();
        List<String> rowsContract = new List<String>();

        List<String> nibelisRows = new List<String>();
        Map<Id, NibelisFileStruct> nibelisRowsMap = new Map<Id, NibelisFileStruct>();

        for (Id cId : collaboratorCommissionsMap.keySet()) {
            // Init listes de lignes par type de comm
//            List<String> rowsBonus = new List<String>();
//            List<String> rowsMalus = new List<String>();
//            List<String> rowsReport = new List<String>();

            // Parse les collaborateurs
            for (String comType : collaboratorCommissionsMap.get(cId).keySet()) {
                // Parse les types de com du collaborateur
                for (String comStatus : collaboratorCommissionsMap.get(cId).get(comType).keySet()) {
                    // Parse les status du type de com du collaborateur
                    for (NRV10Commission__c c : collaboratorCommissionsMap.get(cId).get(comType).get(comStatus)) {
                        Datetime instDate = c.instantDate__c == null ? null : c.instantDate__c;
                        Datetime calcDate = c.calculationDate__c == null ? null : c.calculationDate__c;

                        if (c.comType__c != Constants.COMMISSION_TYPE_REPORT && !nibelisRowsMap.containsKey(c.user__c)) {
                            NibelisFileStruct nib = new NibelisFileStruct();
                            nib.collabId = c.user__c;
                            nib.collabNumber = c.user__r.reference__c;
                            nib.firstname = c.user__r.firstName__c;
                            nib.lastname = c.user__r.lastName__c;
                            nib.period = cal.snapshotFor__c; //Datetime.newInstance(cal.commDate__c.addMonths(-1), Time.newInstance(0,0,0,0)).format('yyyy-MM');
                            nib.salesCom = 0.0;
                            nib.teamCom = 0.0;
                            nibelisRowsMap.put(c.user__c, nib);
                        }

                        // Complete liste comm vendeur
                        if (c.comType__c == Constants.COMMISSION_TYPE_SALES) {
                            String[] rowSales = new String[] {
                                    c.customerOrder__r.OrderNumber,
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    c.user__r.reference__c,
                                    c.store__r.codeMagasinActuel__c,
                                    '',
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    '','','','','','','',
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsSales.add(String.join(rowSales, ','));

                            String[] rowProd = new String[] {
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    'DONT_KNOW_HOW_TO_GET_FROM_JOB',
                                    String.valueOf(c.productCom__r.SBQQ__Number__c),
                                    c.productCom__r.SBQQ__ProductCode__c,
                                    String.valueOf(c.productCom__r.PrixUnitaire__c),
                                    String.valueOf(c.productCom__r.Quantite__c),
                                    'DONT_KNOW_HOW_TO_GET_FROM_QUOTELINE',
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsProd.add(String.join(rowProd, ','));

                            nibelisRowsMap.get(c.user__c).salesCom += c.remuneration__c;
                        }

                        // Complete liste comm équipe
                        if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) {
                            String[] rowSales = new String[] {
                                    c.customerOrder__r.OrderNumber,
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    c.user__r.reference__c,
                                    c.store__r.codeMagasinActuel__c,
                                    '','',
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    '','','','','','',
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsSales.add(String.join(rowSales, ','));
                            system.debug('rawSales : '+rowSales);

                            String[] row = new String[]{
                                    c.customerOrder__r.OrderNumber,
                                    'DONT_KNOW_HOW_TO_GET_FROM_JOB',
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    String.valueOf(c.teamRate__c),
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsTeam.add(String.join(row, ','));

                            nibelisRowsMap.get(c.user__c).teamCom += c.remuneration__c;
                            system.debug('c.remuneration__c : '+c.remuneration__c);
                        }

                        // Complete liste comm bonus
                        if (c.comType__c == Constants.COMMISSION_TYPE_BONUS) {
                            String[] rowSales = new String[] {
                                    c.customerOrder__r.OrderNumber,
                                    '',
                                    c.user__r.reference__c,
                                    c.store__r.codeMagasinActuel__c,
                                    '','',
                                    '',
                                    String.valueOf(c.turnoverLevel__c),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    '','','',
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsSales.add(String.join(rowSales, ','));

                            nibelisRowsMap.get(c.user__c).salesCom += c.remuneration__c;
                        }

                        // Complete liste comm malus
                        if (c.comType__c == Constants.COMMISSION_TYPE_MALUS) {
                            String[] rowSales = new String[] {
                                    c.customerOrder__r.OrderNumber,
                                    '',
                                    c.user__r.reference__c,
                                    c.store__r.codeMagasinActuel__c,
                                    '','',
                                    '','','','',
                                    c.financingMethodName__c,
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsSales.add(String.join(rowSales, ','));

                            nibelisRowsMap.get(c.user__c).salesCom += c.remuneration__c;
                        }

                        // Complete liste comm report
                        if (c.comType__c == Constants.COMMISSION_TYPE_REPORT) {
                            String[] rowSales = new String[] {
                                    c.customerOrder__r.OrderNumber,
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd'),
                                    c.user__r.reference__c,
                                    c.store__r.codeMagasinActuel__c,
                                    String.valueOf(c.remuneration__c.setScale(2)),
                                    '',
                                    '','','','','','','',
                                    instDate == null ? '' : instDate.format('yyyy-MM-dd'),
                                    calcDate == null ? '' : calcDate.format('yyyy-MM-dd')
                            };
                            rowsSales.add(String.join(rowSales, ','));

                        }
                    }
                }
            }
        }

        String headerContract = 'con_code, cal_cal_deb, ven_code, con_signataire_nom, con_signataire_prenom, con_vente, con_montant_ht, con_ec_taux, gde_code, rde_date, con_remvte_decote, cdt_code, con_montant_finance, ori_code, con_remtype, con_rempdt_montant, con_montant_ttc, con_montant_metreur, con_montant_cotation, tva_code, con_comment, con_ec_taux_vte, con_rempdt_montant_avd, Date instantané, Date de calcul';
//        con_montant_ttc, con_montant_metreur, con_montant_cotation,
//        tva_code, con_comment, con_ec_taux_vte, con_rempdt_montant_avd,
//        Date instantané, Date de calcul'
        for (ContractFileStruct st : contractFileStructMap.values()) {
            String[] row = new String[] {
                    st.conCode,
                    st.calDeb == null ? '' : st.calDeb.format('yyyy-MM-dd'),
                    st.venCode,
                    st.signataireNom,
                    st.signatairePrenom,
                    String.valueOf(st.conVente),
                    String.valueOf(st.montantHt),
                    String.valueOf(st.ecRate),
                    '','',
                    String.valueOf(st.conDecote),
                    '','','','',
                    String.valueOf(st.remMontant),
                    String.valueOf(st.conMontantTTC),
                    '',
                    String.valueOf(st.conMontantCotation),
                    '','','','',
                    st.instDate == null ? '' : st.instDate.format('yyyy-MM-dd'),
                    st.calcDate == null ? '' : st.calcDate.format('yyyy-MM-dd')
            };
            rowsContract.add(String.join(row, ','));
        }

        addFile('vendeur', headerSales, rowsSales, cal.Id);
        addFile('produit', headerProd, rowsProd, cal.Id);
        addFile('equipe', headerTeam, rowsTeam, cal.Id);
        addFile('contrat', headerContract, rowsContract, cal.Id);

        String headerNibelis = 'PERIODE, ID, MATR, NOM, PRENOM, Commission Mag, Commission Perso';
        for (NibelisFileStruct rowStruct : nibelisRowsMap.values()) {
            String[] row = new String[]{
                    rowStruct.period,
                    rowStruct.collabId,
                    rowStruct.collabNumber,
                    rowStruct.lastname,
                    rowStruct.firstname,
                    String.valueOf(rowStruct.teamCom),
                    String.valueOf(rowStruct.salesCom)
            };
            nibelisRows.add(String.join(row, ','));
        }
        addFile('nibelis', headerNibelis, nibelisRows, cal.Id);
    }

    private void addFile(String fName, String csvHeader, List<String> csvRows, Id attachToId) {
        String fileName = 'Instant-' + fName + '-' + Datetime.now().format('yyyy-MM-dd') + '.csv';
        String csvContent = csvHeader + '\n' + String.join(csvRows, '\n');

        //create contentversion and it's content document link to attach it to the snapshot record
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';   //S is for document located in Salesforce; E for External and L for social network
        cv.VersionData = Blob.valueOf(csvContent);
        cv.PathOnClient = fileName;
        cv.Title = fileName;
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocId;
        cdl.LinkedEntityId = attachToId;
        cdl.ShareType = 'I';  // I for Inferred permission (based on profile),  V for Viewer and C for collaborator
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

    private class ContractFileStruct {
        String conCode;
        Datetime calDeb;
        String venCode;
        String signataireNom;
        String signatairePrenom;
        Datetime conVente;
        Double montantHt;
        Double ecRate;
        Double conDecote;
        Double remMontant;
        Double conMontantTTC;
        Double conMontantCotation;
        Datetime calcDate;
        Datetime instDate;
    }

    private class NibelisFileStruct {
        String period;
        String collabId;
        String collabNumber;
        String lastname;
        String firstname;
        Double teamCom;
        Double salesCom;
    }

//    private String buildStringArrayFirstValue(Integer size, String firstValue) {
//        String[] result = new String[size];
//        result[0] = firstValue;
//        for (Integer i = 1; i < size; i++) result[i] = '';
//
//        return String.join(result, ',');
//    }

    global void finish(Database.BatchableContext bc) {
        //Nothing more to do
    }
}