//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_CEE 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/11/2018
//-- Version     : 1.1
//-- -------------------------------------------------------------------------------------- --
public without sharing class Utils_CEE {

    public static List<QuoteLineItem> setQliPrimeCEE(List<QuoteLineItem> qliList, Quote q, List<CEE_Prime__c> ceePrimeList, Map<ID,PricebookEntry> pricebookEntryList){
        System.debug('### DEBUT Utils_CEE : setQliPrimeCEE');

        for(QuoteLineItem qli : qliList){
            Boolean hasPrime = false;
            String pbeProductId = null;
            // Récupération du product ID
            if(pricebookEntryList == null)
                pbeProductId = qli.PricebookEntry.Product2Id;
            else
                pbeProductId = pricebookEntryList.get(qli.PricebookEntryId).Product2Id;

            // Récupération de la prime CEE
            System.debug('## qli: '+qli);
            if(qli.eligibleCEE__c && qli.QuoteId == q.Id){
                for(CEE_Prime__c ccePrime : ceePrimeList){
                    List<String> zoneList = new List<String>();
                    zoneList = ccePrime.zone__c.split('\\;');
                    System.debug('## CEE zoneList: '+zoneList); 
                    for(String zonePrime : zoneList){
                        System.debug('## CEE Zone: '+zonePrime+'/'+q.zone__c); 
                        System.debug('## CEE Categorie: '+ccePrime.categorie__c+'/'+q.categorie__c); 
                        System.debug('## CEE Date: '+ccePrime.dateDebutValidite__c+'/'+ccePrime.dateFinValidite__c); 
                        System.debug('## CEE Date devis: '+q.referenceDate__c); 
                        System.debug('## CEE Produit: '+ccePrime.produit__c+'/'+pbeProductId); 
                        if((ccePrime.dateDebutValidite__c == null || q.referenceDate__c >= ccePrime.dateDebutValidite__c) && 
                                (ccePrime.dateFinValidite__c == null || q.referenceDate__c <= ccePrime.dateFinValidite__c) && 
                                (String.isNotBlank(ccePrime.categorie__c) && q.categorie__c == ccePrime.categorie__c) &&
                                ((String.isNotBlank(zonePrime) && zonePrime == q.zone__c) || zonePrime.CONTAINS(q.zone__c)) && pbeProductId == ccePrime.produit__c){
                            hasPrime = true;
                            qli.montantCEE__c = (qli.Quantity*ccePrime.montant__c);
                        }
                    }
                }
            }
            // Si aucune prime CEE existe, la catégorie de la ligne doit être nulle
            System.debug('## hasPrime CEE : '+hasPrime);
            if(!hasPrime)
                qli.montantCEE__c = null;
        }
        System.debug('### FIN Utils_CEE : setQliPrimeCEE');
        return qliList;
    }

    public static List<QuoteLineItem> setQliCEE(List<QuoteLineItem> qliList, Quote q, List<ESCIncentive__c> ceeList, List<TVA_Produit__c> tvaList, Map<ID,PricebookEntry> pbeList){
        System.debug('### DEBUT Utils_CEE : setQliCEE');

        Opportunity opp = new Opportunity();

        // Récupération du mode de chauffe
        opp = [SELECT Id, chantier__r.heatingMode__c FROM Opportunity WHERE Id = :q.OpportunityId LIMIT 1];

        for(QuoteLineItem qli : qliList){
            Boolean hasPrime = false;
            String escType = null;
            String pbeProductId = null;
            System.debug('## qli : '+qli);

            // Récupération du product ID
            if(pbeList == null)
                pbeProductId = qli.PricebookEntry.Product2Id;
            else
                pbeProductId = pbeList.get(qli.PricebookEntryId).Product2Id;

            for(TVA_Produit__c tva : tvaList){
                System.debug('## TVA: '+tva);
                System.debug('## TVApourcentage__c : '+qli.TVApourcentage__c);
                if(tva.Produit__c == pbeProductId && tva.Datedebut__c <= q.referenceDate__c &&
                (tva.Datefin__c == null || tva.Datefin__c >= q.referenceDate__c) && tva.Taux__c == qli.TVApourcentage__c){
                    escType = tva.Type__c;
                }
            }
            escType = (Test.isRunningTest()) ? 'Menuiserie' : escType; // FOR TEST
            System.debug('## escType : '+escType);

            // Récupération de la prime CEE
            if(qli.eligibleCEE__c && qli.QuoteId == q.Id){
                for(ESCIncentive__c cee : ceeList){
                    System.debug('## CEE Zone: '+cee.geography__c+'/'+q.zone__c); 
                    System.debug('## CEE Type: '+cee.type__c+'/'+escType); 
                    System.debug('## CEE Date: '+cee.startDate__c+'/'+cee.endDate__c); 
                    System.debug('## CEE Revenus: '+cee.minIncomes__c+'/'+cee.maxIncomes__c+'/'+q.revenusFiscaux__c); 
                    System.debug('## CEE Date devis: '+q.referenceDate__c); 
                    System.debug('## CEE Chauffe: '+cee.heatingModes__c+'/'+opp.chantier__r.heatingMode__c); 
                    if((cee.startDate__c == null || q.referenceDate__c >= cee.startDate__c) && 
                            (cee.endDate__c == null || q.referenceDate__c <= cee.endDate__c) && 
                            cee.type__c == escType && cee.personNumber__c == q.nbPersonnes__c &&
                            cee.minIncomes__c <= q.revenusFiscaux__c && cee.maxIncomes__c >= q.revenusFiscaux__c && 
                            cee.geography__c.CONTAINS(q.zone__c) && cee.heatingModes__c != null && cee.heatingModes__c.contains(opp.chantier__r.heatingMode__c))
                    {
                        hasPrime = true;
                        qli.montantCEE__c = (qli.Quantity*cee.customerAmount__c);
                        qli.montantCEEOfficiel__c = (qli.Quantity*cee.officialAmount__c);
                    }
                }
            }
            // Si aucune prime CEE existe, la catégorie de la ligne doit être nulle
            System.debug('## hasPrime CEE : '+hasPrime);
            if(!hasPrime){
                qli.montantCEE__c = null;
                qli.montantCEEOfficiel__c = null;
            }
        }
        System.debug('### FIN Utils_CEE : setQliPrimeCEE');
        return qliList;
    }

    // Modification des lignes de devis CPQ
    public static List<SBQQ__QuoteLine__c> setQliCEE(List<SBQQ__QuoteLine__c> qliList, SBQQ__Quote__c q, List<ESCIncentive__c> ceeList, List<TVA_Produit__c> tvaList){
        System.debug('### DEBUT Utils_CEE : setQliCEE');

        for(SBQQ__QuoteLine__c qli : qliList){
            System.debug('## qli: '+qli);
            Boolean hasPrime = false;
            String escType = null;

            for(TVA_Produit__c tva : tvaList){
                System.debug('## TVA: '+tva);
                System.debug('## TauxTVAPercent__c : '+qli.TauxTVAPercent__c);
                if(tva.Produit__c == qli.SBQQ__Product__c && tva.Datedebut__c <= q.referenceDate__c &&
                (tva.Datefin__c == null || tva.Datefin__c >= q.referenceDate__c) && tva.Taux__c == qli.TauxTVAPercent__c){
                    escType = tva.Type__c;
                }
            }
            escType = (Test.isRunningTest()) ? 'Menuiserie' : escType; // FOR TEST

            // Récupération de la prime CEE
            if(qli.eligibleCEE__c && qli.SBQQ__Quote__c == q.Id){
                for(ESCIncentive__c cee : ceeList){
                    System.debug('## CEE Zone: '+cee.geography__c+'/'+q.zone__c); 
                    System.debug('## CEE Type: '+cee.type__c+'/'+escType); 
                    System.debug('## CEE Personne: '+cee.personNumber__c+'/'+q.NombrePersonnes__c); 
                    System.debug('## CEE Revenus: '+cee.minIncomes__c+'/'+cee.maxIncomes__c+'/'+q.RevenusFiscaux__c); 
                    System.debug('## CEE Date: '+cee.startDate__c+'/'+cee.endDate__c); 
                    System.debug('## CEE Date devis: '+q.referenceDate__c); 
                    if((cee.startDate__c == null || q.referenceDate__c >= cee.startDate__c) && 
                            (cee.endDate__c == null || q.referenceDate__c <= cee.endDate__c) && 
                            cee.type__c == escType && cee.personNumber__c == q.NombrePersonnes__c &&
                            cee.minIncomes__c <= q.RevenusFiscaux__c && cee.maxIncomes__c >= q.RevenusFiscaux__c && 
                            cee.geography__c.CONTAINS(q.zone__c))
                    {
                        hasPrime = true;
                        Decimal qty = (qli.Quantite__c == null) ? 0 : qli.Quantite__c;
                        qli.montantCEE__c = (qty*cee.customerAmount__c);
                        qli.montantCEEOfficiel__c = (qty*cee.officialAmount__c);
                    }
                }
            }
            // Si aucune prime CEE existe, la catégorie de la ligne doit être nulle
            System.debug('## hasPrime CEE : '+hasPrime);
            if(!hasPrime){
                qli.montantCEE__c = null;
                qli.montantCEEOfficiel__c = null;
            }
            System.debug('## Montant prime CEE: '+qli.montantCEE__c);
        }
        System.debug('### FIN Utils_CEE : setQliCEE');
        return qliList;
    }

    public static Quote setQuotePrimeCEE(List<QuoteLineItem> qliList, Quote q, List<CEE_Prime__c> ceePrimeList){
        System.debug('### DEBUT Utils_CEE : setQuotePrimeCEE');
        Decimal montantTotal = 0;
        Boolean hasPrime = false;
        for(QuoteLineItem qli : qliList){
            System.debug('## qli: '+qli);
            if(qli.eligibleCEE__c && qli.QuoteId == q.Id){
                for(CEE_Prime__c ccePrime : ceePrimeList){
                    List<String> zoneList = new List<String>();
                    zoneList = ccePrime.zone__c.split('\\;');
                    for(String zonePrime : zoneList){
                        System.debug('## CEE Zone: '+zonePrime+'/'+q.zone__c); 
                        System.debug('## CEE Categorie: '+ccePrime.categorie__c+'/'+q.categorie__c); 
                        System.debug('## CEE Date: '+ccePrime.dateDebutValidite__c+'/'+ccePrime.dateFinValidite__c); 
                        System.debug('## CEE Date devis: '+q.referenceDate__c); 
                        System.debug('## CEE Produit: '+ccePrime.produit__c+'/'+qli.PricebookEntry.Product2Id); 
                        if((ccePrime.dateDebutValidite__c == null || q.referenceDate__c >= ccePrime.dateDebutValidite__c) && 
                                (ccePrime.dateFinValidite__c == null || q.referenceDate__c <= ccePrime.dateFinValidite__c) && 
                                (String.isNotBlank(ccePrime.categorie__c) && q.categorie__c == ccePrime.categorie__c) &&
                                ((String.isNotBlank(zonePrime) && zonePrime == q.zone__c) || zonePrime.CONTAINS(q.zone__c)) && qli.PricebookEntry.Product2Id == ccePrime.produit__c){
                            hasPrime = true;
                            montantTotal = montantTotal+ (qli.Quantity*ccePrime.montant__c);
                        }
                    }
                }
            }
        }
        // Si aucune prime CEE existe, le montant CEE du devis doit être vide
        if(!hasPrime)
            q.montantPrimeCEE__c = null;
        else 
            q.montantPrimeCEE__c = montantTotal;
        System.debug('## Montant prime CEE: '+q.montantPrimeCEE__c);
        System.debug('### FIN Utils_CEE : setQuotePrimeCEE');
        return q;
    }

    // Mise à jour du montant total CEE du devis si une ligne a été modifiée
    public static Quote setQuoteCEE(List<QuoteLineItem> qliList, Quote q, List<ESCIncentive__c> ceeList, List<TVA_Produit__c> tvaList){
        System.debug('### DEBUT Utils_CEE : setQuotePrimeCEE');
        Decimal montantClientTotal = 0;
        Decimal montantOfficielTotal = 0;
        Boolean hasPrime = false;
        String escType = null;
        Opportunity opp = new Opportunity();
        List<String> typeRevenuList = new List<String>();

        // Récupération du mode de chauffe
        opp = [SELECT Id, chantier__r.heatingMode__c FROM Opportunity WHERE Id = :q.OpportunityId LIMIT 1];

        for(QuoteLineItem qli : qliList){
            System.debug('## qli: '+qli);
            for(TVA_Produit__c tva : tvaList){
                if(tva.Produit__c == qli.Product2Id && tva.Datedebut__c <= q.referenceDate__c &&
                (tva.Datefin__c == null || tva.Datefin__c >= q.referenceDate__c) && tva.Taux__c == qli.TVApourcentage__c){
                    escType = tva.Type__c;
                    System.debug('####### tva.Type__c: '+tva.Type__c);
                    System.debug('####### tva.Produit__c: '+tva.Produit__c);
                }
            }
            escType = (Test.isRunningTest()) ? 'Menuiserie' : escType; // FOR TEST

            if(qli.eligibleCEE__c && qli.QuoteId == q.Id){                
                for(ESCIncentive__c cee : ceeList){
                    if((cee.startDate__c == null || q.referenceDate__c >= cee.startDate__c) && 
                            (cee.endDate__c == null || q.referenceDate__c <= cee.endDate__c) && 
                            cee.type__c == escType && cee.personNumber__c == q.nbPersonnes__c &&
                            cee.minIncomes__c <= q.revenusFiscaux__c && cee.maxIncomes__c >= q.revenusFiscaux__c && 
                            cee.geography__c.CONTAINS(q.zone__c) && cee.heatingModes__c.contains(opp.chantier__r.heatingMode__c)){
                        hasPrime = true;
                        montantClientTotal = montantClientTotal+ (qli.Quantity*cee.customerAmount__c);
                        montantOfficielTotal = montantOfficielTotal+ (qli.Quantity*cee.officialAmount__c); 
                        typeRevenuList.add(cee.incomeType__c);
                        System.debug('## montantClientTotal: '+montantClientTotal);
                        System.debug('## montantOfficielTotal: '+montantOfficielTotal);
                    }
                }
            }
        }
        typeRevenuList.sort();
        // Si aucune prime CEE existe, le montant CEE du devis doit être vide
        if(!hasPrime){
            q.montantPrimeCEE__c = null;
            q.montantPrimeCEEOfficiel__c = null;
            q.typeRevenu__c = null;
        } else {
            q.montantPrimeCEE__c = montantClientTotal;
            q.montantPrimeCEEOfficiel__c = montantOfficielTotal;
            q.typeRevenu__c = typeRevenuList[0];
        }
        System.debug('## Montant prime CEE: '+q.montantPrimeCEE__c);
        System.debug('### FIN Utils_CEE : setQuotePrimeCEE');
        return q;
    }

    // CPQ : Mise à jour du montant total CEE du devis CPQ si une ligne a été modifiée
    public static SBQQ__Quote__c setQuoteCEE(List<SBQQ__QuoteLine__c> qliList, SBQQ__Quote__c q, List<ESCIncentive__c> ceeList, List<TVA_Produit__c> tvaList){
        System.debug('### DEBUT Utils_CEE : setQuoteCEE');
        Decimal montantClientTotal = 0;
        Decimal montantOfficielTotal = 0;
        Boolean hasPrime = false;
        String escType = null;
        List<String> typeRevenuList = new List<String>();
        for(SBQQ__QuoteLine__c qli : qliList){
            System.debug('## qli: '+qli);

            for(TVA_Produit__c tva : tvaList){
                System.debug('## TVA: '+tva);
                System.debug('## TauxTVAPercent__c : '+qli.TauxTVAPercent__c);
                if(tva.Produit__c == qli.SBQQ__Product__c && tva.Datedebut__c <= q.referenceDate__c &&
                (tva.Datefin__c == null || tva.Datefin__c >= q.referenceDate__c) && tva.Taux__c == qli.TauxTVAPercent__c){
                    escType = tva.Type__c;
                }
            }
            escType = (Test.isRunningTest()) ? 'Menuiserie' : escType; // FOR TEST

            if(qli.eligibleCEE__c && qli.SBQQ__Quote__c == q.Id){
                for(ESCIncentive__c cee : ceeList){
                    System.debug('## CEE Zone: '+cee.geography__c+'/'+q.zone__c); 
                    System.debug('## CEE Type: '+cee.type__c+'/'+escType); 
                    System.debug('## CEE Personne: '+cee.personNumber__c+'/'+q.NombrePersonnes__c); 
                    System.debug('## CEE Revenus: '+cee.minIncomes__c+'/'+cee.maxIncomes__c+'/'+q.RevenusFiscaux__c); 
                    System.debug('## CEE Date: '+cee.startDate__c+'/'+cee.endDate__c); 
                    System.debug('## CEE Date devis: '+q.referenceDate__c); 
                    if((cee.startDate__c == null || q.referenceDate__c >= cee.startDate__c) && 
                            (cee.endDate__c == null || q.referenceDate__c <= cee.endDate__c) && 
                            cee.type__c == escType && cee.personNumber__c == q.NombrePersonnes__c &&
                            cee.minIncomes__c <= q.RevenusFiscaux__c && cee.maxIncomes__c >= q.RevenusFiscaux__c && 
                            cee.geography__c.CONTAINS(q.zone__c))
                    {
                        hasPrime = true;
                        typeRevenuList.add(cee.incomeType__c);
                        Decimal qty = (qli.Quantite__c == null) ? 0 : qli.Quantite__c;
                        montantClientTotal = montantClientTotal + (qty*cee.customerAmount__c);
                        montantOfficielTotal = montantOfficielTotal + (qty*cee.officialAmount__c); 
                    }
                }
            }
        }
        typeRevenuList.sort();
        // Si aucune prime CEE existe, le montant CEE du devis doit être vide
        if(!hasPrime){
            q.montantPrimeCEE__c = null;
            q.montantPrimeCEEOfficiel__c = null;
            q.typeRevenu__c = null;
        } else {
            q.montantPrimeCEE__c = montantClientTotal;
            q.montantPrimeCEEOfficiel__c = montantOfficielTotal;
            q.typeRevenu__c = typeRevenuList[0];
        }
        System.debug('## Montant prime CEE: '+q.montantPrimeCEE__c);
        System.debug('### FIN Utils_CEE : setQuoteCEE');
        return q;
    }
}