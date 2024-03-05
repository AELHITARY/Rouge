//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Configurator
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/12/2020
//-- Version     : 1.4
//-- * 1.4 : Déplacement fonction calcul CEE dans Utils_CEE
//-- * 1.3 : Correction bug de code magasin (caractère * possible)
//-- -------------------------------------------------------------------------------------- --
public without sharing class Utils_Configurator {
    
    public static string getCodeMagasinNum(string codeMag){
        string codeMagNum = codeMag;
        if(codeMag == null || codeMag == '*')
            codeMagNum = '';
        else if(codeMag.startsWith('MAG0'))
            codeMagNum = codeMag.substring(4);
        return codeMagNum;
    }

    public static Boolean isProjetEligible(Quote q, Incentive__c inc){
        if(isContained(inc.OriginesElligibles__c, MappingUtils.getCodeOrigine(q.source__c))) {
            if(inc.DebutValidite__c <= q.referenceDate__c && q.referenceDate__c <= inc.FinValidite__c){
                if (q.opportunity.owner.codeMagasin__c != null && q.opportunity.owner.codeMagasin__c != '*') {
                    if(isContained(inc.Magasinselligibles__c , Integer.valueOf(getCodeMagasinNum(q.opportunity.owner.codeMagasin__c)))){
                        return true;
                    }
                } else
                    return false;
            }
        }
        return false;
    }

    private static boolean isContained(String container, Integer contained){
        if(container == '*')
            return true;
        if(container == null)
            container = '';
        for(string containerStr : container.split('\\|')){
            if(Integer.valueOf(containerStr) == contained)
                return true;
        }
        return false;
    }

    public static void recalculerTarifOptions(Quote q){
        List<Option__c> optList = DAL.getOptionList(q.Id);
        Map<id, ReferentielOptions__c> refOptMap = DAL.getRefOptMap(q, DAL.makeSet(optList, 'option__c'));
        Map<id,IncentivePromotion__c> incentiveMap = initIncentives(q, refOptMap);
        //system.debug('\n\n\n\n\n RECALCULER TARIF '+optList[0]+' \n\n\n\n\n\n');
        for(Option__c opt : optList){
            Decimal oldValorisation = opt.valorisation__c;
            opt.non_configuree__c = true;
            opt.valorisation__c = null;
            ReferentielOptions__c refOpt = refOptMap.get(opt.option__c);
            if(refOpt == null || !afficherOption(q,refOpt,opt.ligneDevis__r))
                    continue;
            Decimal valorisation = (refOpt.Valorisationmodifiable__c) ? oldValorisation : getValorisation(q,refOpt,incentiveMap);
            if(valorisation == null && refOpt.OptionPromotionnelle__c && refOpt.CodeOption__c != Constants.EcoPrime)
                    continue;
            opt.non_configuree__c = false;
            opt.valorisation__c = valorisation;
        }
        update optList;
        changeQuoteLIPrice(optList);
    }

    private static void changeQuoteLIPrice(List<Option__c> optList){
        List<Option__c> optListNew = DAL.getOptionList(optList);
        Map<id,QuoteLineItem> qliMap = new Map<id,QuoteLineItem>();
        for(Option__c o : optListNew){
            o.ligneDevis__r.PrixunitaireHTtarifoptions__c = 0;
            o.ligneDevis__r.Remise_Enseigne__c = 0;
            o.ligneDevis__r.Aconfigurer__c = false;
            o.ligneDevis__r.PrixunitaireHTtarifoptions__c = 0 /* price */;
            o.ligneDevis__r.remise_enseigne__c = 0 /* remiseEnseigne */;
            if(o.ligneDevis__r.unitprice == null)
                    o.ligneDevis__r.unitprice = 0;
            qliMap.put(o.ligneDevis__c, o.ligneDevis__r);
        }

        List<Option__c> optRefPromoList = new List<Option__c>();
        // Pour chaque options, on vérifie si elles sont des promotions, on calcul le prix et on ajoute dans une liste
        for(Option__c o : optListNew) {
            if(isReferencePromotion(o.option__r))
                optRefPromoList.add(o);
            else if((o.PrixHT__c != null) && (Utils_Configurator.isRemiseEnseigne(o)) != true)
                o.ligneDevis__r.PrixunitaireHTtarifoptions__c += o.PrixHT__c;
        }

        // Mise à jour du prix des options si promotion
        for (Option__c o : optRefPromoList)
            o.PrixunitaireHT__c = o.Valorisation__c / 100 * (o.ligneDevis__r.PrixunitaireHTtarifoptions__c + o.ligneDevis__r.unitprice);

        update optRefPromoList;
        update qliMap.values();

        // Calcul de la remise
        qliMap.clear();
        optListNew = DAL.getOptionList(optList);
        ID lastId = null;
        for(Option__c o : optListNew){
            if(isRemiseEnseigne(o) && String.isNotBlank(o.ligneDevis__c)) {
                lastId = o.ligneDevis__c;
                o.ligneDevis__r.remise_enseigne__c = (o.ligneDevis__r.remise_enseigne__c + ((o.PrixHT__c * o.ligneDevis__r.Quantity) * (1 + (o.ligneDevis__r.tvaPourcentage__c / 100)))).setScale(2);
                qliMap.put(o.ligneDevis__c, o.ligneDevis__r);
            }
        }

        // Mise à jour de la ligne de devis
        update qliMap.values();
    }

    public static Map<id,IncentivePromotion__c> initIncentives(Quote q, Map<id, ReferentielOptions__c> refOptMap){
        Map<id,IncentivePromotion__c> incentiveMap = new Map<id,IncentivePromotion__c>();
        List<IncentivePromotion__c> incList = DAL.getIncentivePromoList(q, refOptMap);
        for(IncentivePromotion__c inc : incList)
            incentiveMap.put(inc.CodeOption__c,inc);
        return incentiveMap;
    }

    private static decimal getValorisationSpeciale(Quote q, ReferentielOptions__c refOpt, Map<id,IncentivePromotion__c> incentiveMap){
        IncentivePromotion__c incentivePromo = incentiveMap.get(refOpt.Id);
        if(incentivePromo == null)
            return getTarification(refOpt);
        Decimal valoRef =  getTarification(refOpt), valoIncentive = incentivePromo.ValorisationPromotion__c;
        if(isProjetEligible(q, incentivePromo.Codeincentive__r)){
            if(refOpt.UnitedevalorisationPromotion__c == 1){
                if(incentivePromo.ModeValorisation__c && valoRef != null &&  valoIncentive != null)
                    return (valoRef * valoIncentive) / 100;
                else if(!incentivePromo.ModeValorisation__c && valoIncentive != null)
                    return valoIncentive;
            } else if(refOpt.UnitedevalorisationPromotion__c == 2){
                if(incentivePromo.ModeValorisation__c && valoRef != null &&  valoIncentive != null)
                    return valoRef + ((valoRef * valoIncentive) / 100);
                else if(!incentivePromo.ModeValorisation__c && valoRef != null &&  valoIncentive != null)
                    return valoRef + valoIncentive;
            }
        }
        return null;
    }

    private static decimal getTarification(ReferentielOptions__c refOpt){
        if(refOpt.Tarifs_Option__r.size() > 0 )
            return refOpt.Tarifs_Option__r[0].Valorisationdeloption__c;
        return null;
    }

    public static decimal getValorisation(Quote q, ReferentielOptions__c refOpt, Map<id,IncentivePromotion__c> incentiveMap){
        Decimal result;
        if(valorisationSpeciale(refOpt)){
            result = getValorisationSpeciale(q,refOpt,incentiveMap);
            if(result == 0)
                result = null;
        }
        else
            result = getTarification(refOpt);
        return result;
    }

    private static boolean valorisationSpeciale(ReferentielOptions__c refOpt){
        if(refOpt.OptionPromotionnelle__c && refOpt.CodeOption__c == Constants.EcoPrime)
            return false;
        if(refOpt.OptionPromotionnelle__c)
            return true;
        return false;
    }

    public static boolean afficherOption(Quote q, ReferentielOptions__c refOpt, QuoteLineItem qli){
        if(refOpt.OptionPromotionnelle__c){
            if(refOpt.Debutvalidite__c <= q.referenceDate__c && q.referenceDate__c <= refOpt.FinValidite__c){
                if(refOpt.CodeOption__c == Constants.EcoPrime){
                    return 'Oui'.equalsIgnoreCase(q.C2E__c);
                }
                if(refOpt.TypePromotion__r.TypePromotion__c == Constants.campagneType){
                    if(qli.Code_Promo_Formule__c == null || qli.Code_Promo_Formule__c != refOpt.codeOption__c)
                        return false;
                }
            }
            else
                return false;
        }
        return true;
    }

    // Détermine si l'option est une remise enseigne
    //--------------------------------------------------------
    public static boolean isRemiseEnseigne(Option__c opt){
        return (opt.Option__r.OptionPromotionnelle__c && (opt.Pack__c == Constants.PACKCOMM && opt.Categorie__c != Constants.REMISESLEGALES));
    }

    // Détermine si l'option est référence de promotion
    //--------------------------------------------------------
    public static boolean isReferencePromotion(ReferentielOptions__c refOpt){
        return (refOpt.Typedeloption__c == 2 && refOpt.PrixReferencePromotion__c == 1 && refOpt.OptionPromotionnelle__c);
    }

    // Détermine si l'option est une option de marketing
    //--------------------------------------------------------
    public static boolean isOPMarket(Option__c opt){
        return (opt.Option__r.OptionPromotionnelle__c && opt.Option__r.typePromotion__r.name != Constants.ECOSUBVENT);
    }

    public class MyException extends Exception{}
}