//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_KContrat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/11/2018
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_KContrat {

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
          
        system.debug('### DEBUT TR020_KContrat.applyUpdateRules');
        List<KContrat__c> newKcontrat = (List<KContrat__c>)Trigger.new;  
        List<String> quoteIdList = new List<String>(); 
        List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();
        /** A - Initialisation des données intermédiaires **/
        for(KContrat__c contrat : newKcontrat){
            if(Trigger.isInsert && String.isNotBlank(contrat.devis__c)) {
                quoteIdList.add(contrat.devis__c);
            }
        }

        /* Recherche des données intermédiaire */
        /*if(!quoteIdList.isEmpty()) {
	        quoteLineItemList = [SELECT Id, QuoteId, dureeGarantie1__c, dureeGarantie2__c, dureeGarantie3__c, dureeGarantie4__c, dureeGarantie5__c, 
	                                                dureeGarantie6__c, dureeGarantie7__c, dureeGarantie8__c, dureeGarantie9__c, dureeGarantie10__c FROM QuoteLineItem 
	                                                WHERE QuoteId IN :quoteIdList];
        }*/
        
        // Mise à jour de la date de fin de garantie et de l'expiration GDPR
        for(KContrat__c contrat : newKcontrat){
            /*if(contrat.dateSignature__c != null && contrat.dateSignature__c.year() < 2004) {
                contrat.GDPR_dateExpiration__c = contrat.dateSignature__c.addYears(15);
                contrat.dateFinGarantie__c = contrat.dateSignature__c.addYears(15);
            } else if(contrat.dateSignature__c != null) {
                Decimal duree = 0;
                for(QuoteLineItem qli : quoteLineItemList) {
                    if(qli.QuoteId == contrat.devis__c) {
                        if(qli.dureeGarantie1__c > duree)
                            duree = qli.dureeGarantie1__c;
                        if(qli.dureeGarantie2__c > duree)
                            duree = qli.dureeGarantie2__c;
                        if(qli.dureeGarantie3__c > duree)
                            duree = qli.dureeGarantie3__c;
                        if(qli.dureeGarantie4__c > duree)
                            duree = qli.dureeGarantie4__c;
                        if(qli.dureeGarantie5__c > duree)
                            duree = qli.dureeGarantie5__c;
                        if(qli.dureeGarantie6__c > duree)
                            duree = qli.dureeGarantie6__c;
                        if(qli.dureeGarantie7__c > duree)
                            duree = qli.dureeGarantie7__c;
                        if(qli.dureeGarantie8__c > duree)
                            duree = qli.dureeGarantie8__c;
                        if(qli.dureeGarantie9__c > duree)
                            duree = qli.dureeGarantie9__c;
                        if(qli.dureeGarantie10__c > duree)
                            duree = qli.dureeGarantie10__c;
                        break;
                    }
                }
                if(duree != 0) {                    
                    contrat.GDPR_dateExpiration__c = contrat.dateSignature__c.addYears(Integer.valueOf(duree));
                    contrat.dateFinGarantie__c = contrat.dateSignature__c.addYears(Integer.valueOf(duree));
                }
            }*/

            if(contrat.etape__c == 'Résilié'){
                contrat.GDPR_dateExpiration__c = contrat.dateSignature__c.addYears(3);
            } else {
                contrat.GDPR_dateExpiration__c = null;
            }
        }
    }
}