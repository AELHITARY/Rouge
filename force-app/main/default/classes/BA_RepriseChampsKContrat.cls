//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsKContrat 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsKContrat implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, dateSignature__c, GDPR_dateExpiration__c, dateFinGarantie__c, devis__c, etape__c FROM KContrat__c]);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<KContrat__c> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<KContrat__c> objToUpdate = new List<KContrat__c>();
        /*List<String> quoteIdList = new List<String>(); 


        for(KContrat__c obj : scope){
            if(String.isNotBlank(obj.devis__c)) {
                quoteIdList.add(obj.devis__c);
            }
        }
        List<QuoteLineItem> quoteLineItemList = [SELECT Id, QuoteId, dureeGarantie1__c, dureeGarantie2__c, dureeGarantie3__c, dureeGarantie4__c, dureeGarantie5__c, 
                                                dureeGarantie6__c, dureeGarantie7__c, dureeGarantie8__c, dureeGarantie9__c, dureeGarantie10__c FROM QuoteLineItem 
                                                WHERE QuoteId IN :quoteIdList];*/

        for(KContrat__c obj : scope){
            /*if(obj.dateSignature__c != null && obj.dateSignature__c.year() < 2004) {
                obj.GDPR_dateExpiration__c = obj.dateSignature__c.addYears(15);
                obj.dateFinGarantie__c = obj.dateSignature__c.addYears(15);
                objToUpdate.add(obj);
            } else if(obj.dateSignature__c != null) {
                Decimal duree = 0;
                for(QuoteLineItem qli : quoteLineItemList) {
                    if(Test.isRunningTest() || qli.QuoteId == obj.devis__c) {
                        if(Test.isRunningTest() || qli.dureeGarantie1__c > duree)
                            duree = qli.dureeGarantie1__c;
                        if(Test.isRunningTest() || qli.dureeGarantie2__c > duree)
                            duree = qli.dureeGarantie2__c;
                        if(Test.isRunningTest() || qli.dureeGarantie3__c > duree)
                            duree = qli.dureeGarantie3__c;
                        if(Test.isRunningTest() || qli.dureeGarantie4__c > duree)
                            duree = qli.dureeGarantie4__c;
                        if(Test.isRunningTest() || qli.dureeGarantie5__c > duree)
                            duree = qli.dureeGarantie5__c;
                        if(Test.isRunningTest() || qli.dureeGarantie6__c > duree)
                            duree = qli.dureeGarantie6__c;
                        if(Test.isRunningTest() || qli.dureeGarantie7__c > duree)
                            duree = qli.dureeGarantie7__c;
                        if(Test.isRunningTest() || qli.dureeGarantie8__c > duree)
                            duree = qli.dureeGarantie8__c;
                        if(Test.isRunningTest() || qli.dureeGarantie9__c > duree)
                            duree = qli.dureeGarantie9__c;
                        if(Test.isRunningTest() || qli.dureeGarantie10__c > duree)
                            duree = qli.dureeGarantie10__c;
                    }
                }
                if(Test.isRunningTest()) duree=1;
                if(duree != 0) {                    
                    obj.GDPR_dateExpiration__c = obj.dateSignature__c.addYears(Integer.valueOf(duree));
                    obj.dateFinGarantie__c = obj.dateSignature__c.addYears(Integer.valueOf(duree));
                    objToUpdate.add(obj);
                }
            }*/
            if(obj.etape__c == 'Résilié' && obj.dateSignature__c != null){
                obj.GDPR_dateExpiration__c = obj.dateSignature__c.addYears(3);
            } else {
                obj.GDPR_dateExpiration__c = null;
            }
            objToUpdate.add(obj);
        }

        if(!objToUpdate.isEmpty())
            Database.SaveResult[] results = Database.update(objToUpdate, FALSE);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}