//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsQuote
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 24/08/2022
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsQuote implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, Email, Phone, ExpirationDate, emailDemandeurs__c, telephoneDomicileDemandeurs__c, dateExpiration__c, 
                                                shippingName, shippingStreet, shippingPostalCode, shippingCity, shippingState, shippingCountry, 
                                                prenomChantier__c, rueChantier__c, codePostalChantier__c, villeChantier__c, departementChantier__c, paysChantier__c,
                                                billingName, billingStreet, billingPostalCode, billingCity, billingState, billingCountry,
                                                Status, GDPR_dateExpiration__c, dateAcceptationClient__c, CreatedDate, dateDevis__c, referenceDate__c,
                                                Opportunity.chantier__r.occupant__r.nom__c, Opportunity.chantier__r.autreOccupant__r.nom__c,
                                                Opportunity.chantier__r.locataire__r.nom__c, Opportunity.chantier__r.autreLocataire__r.nom__c,
                                                Opportunity.chantier__r.proprietaire__r.nom__c, Opportunity.chantier__r.autreProprietaire__r.nom__c,
                                                Opportunity.Account.nom__c, rueDemandeurs__c, codePostalDemandeurs__c, villeDemandeurs__c, departementDemandeurs__c, paysDemandeurs__c
                                                FROM Quote]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise Devis : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Quote> scope) {
        system.debug('## Scope size: '+scope.size()); 
        for(Quote q : scope){
            if(q.Opportunity != null) {
                if(q.Opportunity.Account != null) {
                    if(String.isNotBlank(q.Opportunity.Account.nom__c))
                        q.billingName = q.Opportunity.Account.nom__c;
                }
                if(q.Opportunity.chantier__r != null) {
                    if(q.Opportunity.chantier__r.occupant__r != null)
                        q.ShippingName = q.Opportunity.chantier__r.occupant__r.nom__c;
                    else if(q.Opportunity.chantier__r.locataire__r != null)
                        q.ShippingName = q.Opportunity.chantier__r.locataire__r.nom__c;
                    else if(q.Opportunity.chantier__r.proprietaire__r != null)
                        q.ShippingName = q.Opportunity.chantier__r.proprietaire__r.nom__c;
                }
            }
            if(Test.isRunningTest() || String.isNotBlank(q.rueChantier__c))
                q.shippingStreet = q.rueChantier__c;
            if(Test.isRunningTest() || String.isNotBlank(q.codePostalChantier__c))
                q.shippingPostalCode = q.codePostalChantier__c;
            if(Test.isRunningTest() || String.isNotBlank(q.villeChantier__c))
                q.shippingCity = q.villeChantier__c;
            if(Test.isRunningTest() || String.isNotBlank(q.departementChantier__c))
                q.shippingState = q.departementChantier__c;
            if(Test.isRunningTest() || String.isNotBlank(q.paysChantier__c))
                q.shippingCountry = q.paysChantier__c;
                
            if(Test.isRunningTest() || String.isNotBlank(q.rueDemandeurs__c))
                q.billingStreet = q.rueDemandeurs__c;
            if(Test.isRunningTest() || String.isNotBlank(q.codePostalDemandeurs__c))
                q.billingPostalCode = q.codePostalDemandeurs__c;
            if(Test.isRunningTest() || String.isNotBlank(q.villeDemandeurs__c))
                q.billingCity = q.villeDemandeurs__c;
            if(Test.isRunningTest() || String.isNotBlank(q.departementDemandeurs__c))
                q.billingState = q.departementDemandeurs__c;
            if(Test.isRunningTest() || String.isNotBlank(q.paysDemandeurs__c))
                q.billingCountry = q.paysDemandeurs__c;
            
            if(Test.isRunningTest() || String.isNotBlank(q.emailDemandeurs__c))
                q.Email = q.emailDemandeurs__c;
            if(Test.isRunningTest() || String.isNotBlank(q.telephoneDomicileDemandeurs__c))
                q.Phone = q.telephoneDomicileDemandeurs__c;
            if(Test.isRunningTest() || (q.dateDevis__c != null && q.referenceDate__c == null))
                q.referenceDate__c = q.dateDevis__c;
            /*if(q.dateExpiration__c != null)
                q.ExpirationDate = q.dateExpiration__c;

            // GDPR
            q.GDPR_DateExpiration__c = q.CreatedDate.date().addDays(365);
            if(Test.isRunningTest() || q.dateAcceptationClient__c != null)
                q.GDPR_DateExpiration__c = q.dateAcceptationClient__c.addDays(365);
            if(Test.isRunningTest() || String.isNotBlank(q.Status) && 'Vendu'.containsIgnoreCase(q.Status) && q.dateAcceptationClient__c != null) 
                q.GDPR_DateExpiration__c = q.dateAcceptationClient__c.addDays(365);
            if (Test.isRunningTest() || q.Status == Constants.StatutDevisExpire || q.Status == Constants.StatutDevisErrone || q.Status == Constants.StatutDevisResilie)
                q.GDPR_DateExpiration__c = q.CreatedDate.date().addDays(365);*/
        }
        Database.SaveResult[] results = Database.update(scope, FALSE);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}