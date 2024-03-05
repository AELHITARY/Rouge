//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CreateGlobalWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/08/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CreateGlobalWizard {
    private static final Boolean GEOENABLED = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
    private static final Integer DELAIEXPIRATION = PropertiesUtils.getIntegerValue('maintenance.devis.delaiExpiration', 14);
    private static final String ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String QUOTE_ACONF_RTID = DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_ACONFIGURER);
    private static final String QUOTECPQ_SALES_RTID = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SALES_RT);
    private static final String REF_SOURCE_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', 'Source');
    
    /**
    * @description Function to save all objects filled in the component form
    * @param accParams Object with account information
    * @param chaParams Object with chantier information
    * @param oppParams Object with opportunity information
    * @param quoParams Object with quote information
    * @param quoCPQParams Object with quote CPQ information
    * @param objectsParams Object with misc information
    * @return String Id of the last object created 
    */
    @AuraEnabled
    public static String saveAllObjects(Map<String, String> accParams, Map<String, String> chaParams, 
                                        Map<String, String> oppParams, Map<String, String> quoParams,
                                        Map<String, String> quoCPQParams,  Map<String, Boolean> objectsParams){
        System.debug('### DEBUT LWC_CreateGlobalWizard.saveAllObjects');
        System.debug('## accParams: '+accParams);
        System.debug('## chaParams: '+chaParams);
        System.debug('## oppParams: '+oppParams);
        System.debug('## quoParams: '+quoParams);
        System.debug('## quoCPQParams: '+quoCPQParams);
        System.debug('## objectsParams: '+objectsParams);

        String result;
        Account accToUpsert = new Account();
        Chantier__c chaToUpsert = new Chantier__c();
        Opportunity oppToUpsert = new Opportunity();
        Quote quoToUpsert = new Quote();
        SBQQ__Quote__c quoCPQToUpsert = new SBQQ__Quote__c();

        // Sauvegarde
        Savepoint sp = Database.setSavepoint();

        try{
            String accId = accParams.get('accId');
            System.debug('## accId: '+accId);
            // If there is a selected existing Account
            if(String.isNotBlank(accId)){
                List<Account> accList = [SELECT Id,Salutation,FirstName,LastName,AccountSource,accountCallSource__c, 
                                                RecordTypeId, PersonMailingStreet, PersonMailingCity,PersonMailingPostalCode,
                                                PersonMailingState,PersonMailingCountry,PersonEmail,complementAdresse__c,
                                                PersonHomePhone,PersonMobilePhone,etage__c,Localisation__Latitude__s,
                                                Localisation__Longitude__s
                                        FROM Account 
                                        WHERE Id = :accId];

                if(!accList.isEmpty()){
                    updateAccountValues(accList[0], accParams);
                    accToUpsert = accList[0];
                    System.debug('## Update Account: '+accToUpsert);
                    update accToUpsert;
                } 
            // Otherwise, create a new one   
            } else {
                updateAccountValues(accToUpsert, accParams);
                System.debug('## New Account: '+accToUpsert);
                insert accToUpsert;
            }
            result = accToUpsert.Id;

            // Chantier creation
            if(objectsParams.get('hasChantier')){
                String chaId = chaParams.get('chaId');
                System.debug('## chaId: '+chaId);
                // If there is a selected existing Chantier
                if(String.isNotBlank(chaId)){
                    List<Chantier__c> chaList = [SELECT Id,rue__c,codePostal__c,ville__c,departement__c,pays__c,                
                                                    complementAdresse__c, nbPortesEtFenetres__c,typeHabitation__c,typeResidence__c,
                                                    Localisation__Latitude__s, Localisation__Longitude__s,Name,proprietaire__c, iris__c,
                                                    codeCommune__c, adresseGeolocalisation__c, methodeGeocodage__c
                                                FROM Chantier__c 
                                                WHERE Id = :chaId];

                    if(!chaList.isEmpty()){
                        updateChantierValues(chaList[0], chaParams, accToUpsert);
                        chaToUpsert = chaList[0];
                        System.debug('## Update Chantier: '+chaToUpsert);
                        update chaToUpsert;
                    } 
                // Otherwise, create a new one   
                } else {
                    updateChantierValues(chaToUpsert, chaParams, accToUpsert);
                    if(chaParams.get('chaPostalcode') != null) {
                        List<Sectorisation__c> sectList = new List<Sectorisation__c>();
                        sectList = [SELECT Id, iris__c, codeCommuneAdm__c, codePostalAdm__c FROM Sectorisation__c 
                                        WHERE codePostalAdm__c = :chaParams.get('chaPostalcode')];
                        //DQE 
                        if(GEOENABLED){
                            chaToUpsert.methodeGeocodage__c = 'Batch';
                            Utils_DQE.GeocodeResultType checkAdress = new Utils_DQE.GeocodeResultType();
                            checkAdress = GeoUtils.geolocationChantierDQE(chaToUpsert, sectList);
                            if(checkAdress == null) {
                                chaToUpsert.Localisation__Latitude__s = null;
                                chaToUpsert.Localisation__Longitude__s = null;
                            }
                        }
                    }
                    System.debug('## New Chantier: '+chaToUpsert);
                    insert chaToUpsert;
                }
                result = chaToUpsert.Id;

                // Opportunity creation
                if(objectsParams.get('hasOpportunity')){
                    String oppId = oppParams.get('oppId');
                    System.debug('## oppId: '+oppId);
                    // If there is a selected existing Opportunity
                    if(String.isNotBlank(oppId)){
                        List<Opportunity> oppList = [SELECT Id,Name,AccountId,Type,StageName,chantier__c,CloseDate,
                                                        campagneCall__c, operation__r.Id, operation__r.Name, ContactId
                                                    FROM Opportunity 
                                                    WHERE Id = :oppId];

                        if(!oppList.isEmpty()){
                            updateOpportunityValues(oppList[0], oppParams, accToUpsert, chaToUpsert);
                            oppToUpsert = oppList[0];
                            System.debug('## Update Opportunity: '+oppToUpsert);
                            update oppToUpsert;
                        } 
                    // Otherwise, create a new one   
                    } else {
                        updateOpportunityValues(oppToUpsert, oppParams, accToUpsert, chaToUpsert);
                        System.debug('## New Opportunity: '+oppToUpsert);
                        insert oppToUpsert;
                    }
                    result = oppToUpsert.Id;
    
                    // Quote creation
                    if(objectsParams.get('hasQuote')){
                        // Create Quote CPQ
                        if(objectsParams.get('createQuoteCPQ')){ 
                            // If there is a selected existing Quote CPQ
                            String quoCPQId = quoCPQParams.get('quoId');
                            System.debug('## quoCPQId: '+quoCPQId);
                            if(String.isNotBlank(quoCPQId)){
                                List<SBQQ__Quote__c> quoCPQList = [SELECT Id,Name,dateDevis__c,referenceDate__c,SBQQ__Account__c, 
                                                                        RecordTypeId, SBQQ__Status__c, totalAmount__c,
                                                                        financingMethod__c, financingMethod__r.Name, 
                                                                        termsAndConditions__c,termsAndConditions__r.Name,
                                                                        sourceRef__c, sourceRef__r.Name
                                                        FROM SBQQ__Quote__c 
                                                        WHERE Id = :quoCPQId];

                                if(!quoCPQList.isEmpty()){
                                    updateQuoteCPQValues(quoCPQList[0], quoParams, accToUpsert, chaToUpsert, oppToUpsert);
                                    quoCPQToUpsert = quoCPQList[0];
                                    System.debug('## Update Quote CPQ: '+quoCPQToUpsert);
                                    update quoCPQToUpsert;
                                } 
                            // Otherwise, create a new one   
                            } else {
                                updateQuoteCPQValues(quoCPQToUpsert, quoCPQParams, accToUpsert, chaToUpsert, oppToUpsert);
                                insert quoCPQToUpsert;
                                System.debug('## New Quote CPQ: '+quoCPQToUpsert);
                            }
                            result = quoCPQToUpsert.Id;
                        // Create Quote
                        } else {
                            // If there is a selected existing Quote
                            String quoId = quoParams.get('quoId');
                            System.debug('## quoId: '+quoId);
                            if(String.isNotBlank(quoId)){
                                List<Quote> quoList = [SELECT Id,OpportunityId,Name,dateDevis__c,referenceDate__c,compte__c,
                                                            total_TTC_devis__c,typeContrat__c, modeFinancement__c,RecordTypeId,Status,ExpirationDate
                                                        FROM Quote 
                                                        WHERE Id = :quoId];

                                if(!quoList.isEmpty()){
                                    updateQuoteValues(quoList[0], quoParams, accToUpsert, chaToUpsert, oppToUpsert);
                                    quoToUpsert = quoList[0];
                                    System.debug('## Update Quote: '+quoToUpsert);
                                    update quoToUpsert;
                                } 
                            // Otherwise, create a new one   
                            } else {
                                updateQuoteValues(quoToUpsert, quoParams, accToUpsert, chaToUpsert, oppToUpsert);
                                insert quoToUpsert;
                                System.debug('## New Quote: '+quoToUpsert);
                            }
                            result = quoToUpsert.Id;
                        }
                    }
                }
            } 
            System.debug('## result: '+result);
            System.debug('### FIN LWC_CreateGlobalWizard.saveAllObjects');
            return result;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Function to retrieve information from a selected account
    * @param accId Id de l'enregistrement
    * @return Account infos
    */
    @AuraEnabled(Cacheable = true)
    public static Account getAccount(String accId){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getAccount'); 
        System.debug('## accId: '+accId); 
        Account result = null;

        if(String.isNotBlank(accId)) {
            List<Account> accList = new List<Account>();
            accList = [SELECT Id,Salutation,FirstName,LastName,AccountSource,accountCallSource__c,RecordTypeId,PersonMailingStreet,
                            PersonMailingCity,PersonMailingPostalCode,PersonMailingState,PersonMailingCountry,PersonEmail,complementAdresse__c,
                            PersonHomePhone,PersonMobilePhone,etage__c,Localisation__Latitude__s,
                            Localisation__Longitude__s 
                        FROM Account 
                        WHERE Id = :accId AND recordTypeId = :ACC_PERSO_RTID];

            if(!accList.isEmpty()){
                result = accList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getAccount'); 
        return result;
    }

    /**
    * @description Function to retrieve information from a selected chantier
    * @param chaId Id de l'enregistrement
    * @return Chantier infos
    */
    @AuraEnabled(Cacheable = true)
    public static Chantier__c getChantier(String chaId){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getChantier'); 
        System.debug('## chaId: '+chaId); 
        Chantier__c result = null;

        if(String.isNotBlank(chaId)) {
            List<Chantier__c> chaList = new List<Chantier__c>();
            chaList = [SELECT Id,rue__c,codePostal__c,ville__c,departement__c,pays__c,complementAdresse__c,
                                nbPortesEtFenetres__c,typeHabitation__c,typeResidence__c,Localisation__Latitude__s,
                                Localisation__Longitude__s,Name,proprietaire__c 
                        FROM Chantier__c 
                        WHERE Id = :chaId];
            if(!chaList.isEmpty()){
                result = chaList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getChantier'); 
        return result;
    }

    /**
    * @description Function to retrieve information from a selected opportunity
    * @param oppId Id de l'enregistrement
    * @return Opportunity infos
    */
    @AuraEnabled(Cacheable = true)
    public static Opportunity getOpportunity(String oppId){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getOpportunity'); 
        System.debug('## oppId: '+oppId); 
        Opportunity result = null; 

        if(String.isNotBlank(oppId)) {
            List<Opportunity> oppList = new List<Opportunity>();
            oppList = [SELECT Id,Name,AccountId,Type,StageName,chantier__c,CloseDate, 
                                campagneCall__c, operation__c, operation__r.Id, operation__r.Name
                        FROM Opportunity 
                        WHERE Id = :oppId];
            
            if(!oppList.isEmpty()){
                result = oppList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getOpportunity'); 
        return result;
    }

    /**
    * @description Function to retrieve information from a selected quote
    * @param quoId Id de l'enregistrement
    * @return Quote infos
    */
    @AuraEnabled(Cacheable = true)
    public static Quote getQuote(String quoId){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getQuote'); 
        System.debug('## quoId: '+quoId); 
        Quote result = null; 

        if(String.isNotBlank(quoId)) {
            List<Quote> quoList = new List<Quote>();
            quoList = [SELECT Id,OpportunityId,Name,dateDevis__c,referenceDate__c,compte__c,total_TTC_devis__c,typeContrat__c,
                                modeFinancement__c,RecordTypeId,Status
                        FROM Quote 
                        WHERE Id = :quoId];
            
            if(!quoList.isEmpty()){
                result = quoList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getQuote'); 
        return result;
    }

    /**
    * @description Function to retrieve information from a selected quote
    * @param quoId Id de l'enregistrement
    * @return SBQQ__Quote__c infos
    */
    @AuraEnabled(Cacheable = true)
    public static SBQQ__Quote__c getQuoteCPQ(String quoId){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getQuoteCPQ'); 
        System.debug('## quoId: '+quoId); 
        SBQQ__Quote__c result = null; 

        if(String.isNotBlank(quoId)) {
            List<SBQQ__Quote__c> quoList = new List<SBQQ__Quote__c>();
            quoList = [SELECT Id, totalAmount__c, financingMethod__c, financingMethod__r.Name, 
                                termsAndConditions__c,termsAndConditions__r.Name,
                                sourceRef__c, sourceRef__r.Name
                        FROM SBQQ__Quote__c 
                        WHERE Id = :quoId];
            
            if(!quoList.isEmpty()){
                result = quoList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getQuoteCPQ'); 
        return result;
    }
    /**
    * @description Function to retrieve information from source on referencial object
    * @param sourceName Name of the source
    * @return Referencial__c infos
    */
    @AuraEnabled(Cacheable = true)
    public static Referencial__c getSourceRef(String sourceName){
        System.debug('### DEBUT LWC_CreateGlobalWizard.getSourceRef'); 
        System.debug('## sourceName: '+sourceName); 
        Referencial__c result = null;

        if(String.isNotBlank(sourceName)) {
            List<Referencial__c> refList = new List<Referencial__c>();
            refList = [SELECT Id,Name,KparKReference__c
                        FROM Referencial__c 
                        WHERE Name = :sourceName AND RecordTypeId = :REF_SOURCE_RTID LIMIT 1];

            if(!refList.isEmpty()){
                result = refList[0];
            }    
        }    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CreateGlobalWizard.getSourceRef'); 
        return result;
    }

    public static void updateAccountValues(Account accToUpdate, Map<String, String> accParams)
    {
        accToUpdate.Salutation = accParams.get('civility');
        accToUpdate.FirstName = accParams.get('firstName');
        accToUpdate.LastName = accParams.get('lastName');
        accToUpdate.RecordTypeId = ACC_PERSO_RTID;
        accToUpdate.AccountSource = accParams.get('source');
        accToUpdate.accountCallSource__c = accParams.get('sourceCall');
        accToUpdate.PersonMailingStreet = accParams.get('accStreet');
        accToUpdate.PersonMailingCity = accParams.get('accCity');
        accToUpdate.PersonMailingPostalCode = accParams.get('accPostalcode');
        accToUpdate.PersonMailingState = accParams.get('accState');
        accToUpdate.PersonMailingCountry = accParams.get('accCountry');
        accToUpdate.PersonEmail = accParams.get('email');
        accToUpdate.complementAdresse__c = accParams.get('accComplementAddress');
        accToUpdate.PersonHomePhone = accParams.get('telDomicile');
        accToUpdate.PersonMobilePhone = accParams.get('telMobile');
        accToUpdate.etage__c = String.isBlank(accParams.get('etage')) ? null : Decimal.valueOf(accParams.get('etage'));
        accToUpdate.Localisation__Latitude__s = String.isBlank(accParams.get('accLatitude')) ? null : Decimal.valueOf(accParams.get('accLatitude'));
        accToUpdate.Localisation__Longitude__s = String.isBlank(accParams.get('accLongitude')) ? null : Decimal.valueOf(accParams.get('accLongitude'));
    }

    public static void updateChantierValues(Chantier__c chaToUpdate, Map<String, String> chaParams, Account accToUpsert)
    {
        chaToUpdate.Name = ('CHA _ ' +Date.today().year()+''+Date.today().month()+' _ '+accToUpsert.FirstName+' '+accToUpsert.LastName+' _ '+chaParams.get('chaCity')).abbreviate(255);
        chaToUpdate.rue__c = chaParams.get('chaStreet');
        chaToUpdate.codePostal__c = chaParams.get('chaPostalcode');
        chaToUpdate.ville__c = chaParams.get('chaCity');
        chaToUpdate.departement__c = chaParams.get('chaState');
        chaToUpdate.pays__c = chaParams.get('chaCountry');
        chaToUpdate.complementAdresse__c = chaParams.get('chaComplementAddress');
        chaToUpdate.nbPortesEtFenetres__c = String.isBlank(chaParams.get('nbPortesFenetres')) ? null : Decimal.valueOf(chaParams.get('nbPortesFenetres'));
        chaToUpdate.typeHabitation__c = chaParams.get('typeHabitation');
        chaToUpdate.typeResidence__c = chaParams.get('typeResidence');
        chaToUpdate.Localisation__Latitude__s = String.isBlank(chaParams.get('chaLatitude')) ? null : Decimal.valueOf(chaParams.get('chaLatitude'));
        chaToUpdate.Localisation__Longitude__s = String.isBlank(chaParams.get('chaLongitude')) ? null : Decimal.valueOf(chaParams.get('chaLongitude'));
        chaToUpdate.proprietaire__c = accToUpsert.Id;
    }

    public static void updateOpportunityValues(Opportunity oppToUpdate, Map<String, String> oppParams, 
                                                Account accToUpsert, Chantier__c chaToUpsert)
    {
        oppToUpdate.Name = ('PRJ _ ' +Date.today().year()+''+Date.today().month()+' _ '+accToUpsert.FirstName+' '+accToUpsert.LastName+' _ '+chaToUpsert.ville__c).abbreviate(255);
        oppToUpdate.AccountId = accToUpsert.Id;
        oppToUpdate.Type = oppParams.get('type');
        oppToUpdate.StageName = 'Analyse';
        oppToUpdate.chantier__c = chaToUpsert.Id;
        oppToUpdate.LeadSource = accToUpsert.AccountSource;
        oppToUpdate.callSource__c = accToUpsert.accountCallSource__c;
        oppToUpdate.CloseDate = date.valueOf(oppParams.get('datePrevisionelleSignature'));
        oppToUpdate.operation__c = oppParams.get('opeId');
        oppToUpdate.campagneCall__c = oppParams.get('campagneCall');
    }

    public static void updateQuoteValues(Quote quoToUpsert, Map<String, String> quoParams, 
                                            Account accToUpsert, Chantier__c chaToUpsert, Opportunity oppToUpsert)
    {
        quoToUpsert.Name = ('DVS _ ' +Date.today().year()+''+Date.today().month()+' _ '+accToUpsert.FirstName+' '+accToUpsert.LastName+' _ '+chaToUpsert.ville__c).abbreviate(255);
        quoToUpsert.OpportunityId = oppToUpsert.Id;
        quoToUpsert.dateDevis__c = Date.valueOf(quoParams.get('dateDevis'));
        quoToUpsert.referenceDate__c = Date.valueOf(quoParams.get('dateDevis'));
        quoToUpsert.ExpirationDate = quoToUpsert.dateDevis__c.addDays(DELAIEXPIRATION);
        quoToUpsert.compte__c = accToUpsert.Id;
        quoToUpsert.source__c = accToUpsert.AccountSource;
        quoToUpsert.callSource__c = accToUpsert.accountCallSource__c;
        quoToUpsert.total_TTC_devis__c = String.isBlank(quoParams.get('montant')) ? null : Decimal.valueOf(quoParams.get('montant'));
        quoToUpsert.typeContrat__c = quoParams.get('typeContrat');
        quoToUpsert.modeFinancement__c = quoParams.get('modeFinancement');
        quoToUpsert.RecordTypeId = QUOTE_ACONF_RTID;
        quoToUpsert.Status = Constants.StatutDevisAConfigurer;
    }

    public static void updateQuoteCPQValues(SBQQ__Quote__c quoToUpsert, Map<String, String> quoParams, 
                                            Account accToUpsert, Chantier__c chaToUpsert, Opportunity oppToUpsert)
    {
        quoToUpsert.nomDevis__c = ('CPQ _ ' +Date.today().year()+''+Date.today().month()+' _ '+accToUpsert.FirstName+' '+accToUpsert.LastName+' _ '+chaToUpsert.ville__c).abbreviate(255);
        quoToUpsert.SBQQ__Opportunity2__c = oppToUpsert.Id;
        quoToUpsert.dateDevis__c = Date.valueOf(quoParams.get('dateDevis'));
        quoToUpsert.referenceDate__c = Date.valueOf(quoParams.get('dateDevis'));
        quoToUpsert.SBQQ__ExpirationDate__c = quoToUpsert.dateDevis__c.addDays(DELAIEXPIRATION);
        quoToUpsert.SBQQ__Account__c = accToUpsert.Id;
        quoToUpsert.SBQQ__PrimaryContact__c = oppToUpsert.ContactId;
        quoToUpsert.chantier__c = chaToUpsert.Id;
        quoToUpsert.sourceRef__c = quoParams.get('source');
        quoToUpsert.termsAndConditions__c = quoParams.get('termsAndConditions');
        quoToUpsert.financingMethod__c = quoParams.get('financingMethod');
        quoToUpsert.RecordTypeId = QUOTECPQ_SALES_RTID;
        quoToUpsert.SBQQ__Status__c = Constants.QUOTE_STATUS_TO_CONFIGURE;
        quoToUpsert.SBQQ__Primary__c = true;
        quoToUpsert.typeDeTaux__c = 'Réduit';
        quoToUpsert.SBQQ__PricebookId__c = Label.system_id_pricebookentry_standard;

    }
}