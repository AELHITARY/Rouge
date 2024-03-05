//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_DQEFormAddress
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/11/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_DQEFormAddress {

    /**
    * @description Function to call generic function of DQE
    * @param params Object with parameters information
    * @param service Name of the DQE service
    * @return String Response 
    */
    @AuraEnabled
    public static String executeDQERequest(Map<String, String> params, String service){
        System.debug('### DEBUT LWC_DQEFormAddress.executeDQERequest');
        String result;
        try{
            result = Utils_DQE.executeDQEAddressRequest(service, params);
            System.debug('### FIN LWC_DQEFormAddress.executeDQERequest');
            return result;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Function to save the address in the record and call RNVP service of DQE to get IRIS
    * @param objectAPIName API name of the object
    * @param recordId Id of the record
    * @param street New value of the street
    * @param city New value of the city
    * @param state New value of the region
    * @param zip New value of the zip code
    * @param country New value of the country
    * @param longitude New value of the longitude
    * @param latitude New value of the latitude
    * @param complementAddress New value of the complementAddress
    * @param npai New value of the npai
    * @param etage New value of the etage
    */
    @AuraEnabled
    public static void modifyRecordInformation(String objectAPIName, Id recordId, String street, String city, String state,
                                                String zip, String country, Decimal longitude, Decimal latitude, 
                                                String complementAddress, Decimal etage){
        System.debug('### START_LWC_DQEFormAddress.modifyRecordInformation');
        System.debug('## objectAPIName : '+objectAPIName);
        System.debug('## recordId : '+recordId);
        System.debug('## zip : '+zip);
        System.debug('## city : '+city);
        System.debug('## street : '+street);
        System.debug('## longitude : '+longitude);
        System.debug('## latitude : '+latitude);
        System.debug('## complementAddress : '+complementAddress);
        System.debug('## etage : '+etage);
        try {
            if(String.isNotBlank(recordId) && String.isNotBlank(objectAPIName)) {
                Boolean sauvegardeOk;
                Boolean adresseNonRenseignee = (String.isBlank(street) && String.isBlank(city) && String.isBlank(zip));
                Boolean paysFR = ((String.isBlank(country)) || (country.equalsIgnoreCase('FRANCE')) || (country.equalsIgnoreCase('FRA')) || (country.equalsIgnoreCase('FR')) || (country.equalsIgnoreCase('F')));

                // Process for ACCOUNT
                if(objectAPIName == 'Account') {
                    List<Account> accList = [SELECT Id, PersonMailingStreet, BillingStreet, PersonMailingCity, BillingCity, IsPersonAccount,
                                                Localisation__Latitude__s, Localisation__Longitude__s, PersonMailingPostalCode, PersonMailingCountry,
                                                BillingPostalCode, BillingCountry FROM Account WHERE Id = :recordId];
                    if(!accList.isEmpty()) {
                        Account acc = accList[0];

                        if(acc.IsPersonAccount) {
                            acc.PersonMailingStreet = street;
                            acc.PersonMailingCity = city;
                            acc.PersonMailingState = state;
                            acc.PersonMailingPostalCode = zip;
                            acc.PersonMailingCountry = country;
                        } else {
                            acc.BillingStreet = street;
                            acc.BillingCity = city;
                            acc.BillingState = state;
                            acc.BillingPostalCode = zip;
                            acc.BillingCountry = country;
                        }
                        acc.Localisation__Latitude__s = latitude;
                        acc.Localisation__Longitude__s = longitude;
                        acc.complementAdresse__c = complementAddress;
                        acc.etage__c = etage;
                        // DQE geocodage
                        if (adresseNonRenseignee == false & paysFR) {
                            if(PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false)) {
                                Utils_DQE.GeocodeResultType responseDQE = GeoUtils.geolocationAccountDQE(acc, acc.IsPersonAccount, null);
                                if(responseDQE != null){
                                    sauvegardeOk = true;
                                } else {
                                    sauvegardeOk = false;
                                }
                                acc.methodeGeocodage__c = 'Manuel';
                                if(!sauvegardeOk) {
                                    throw new KubeException(Label.AdresseNonTrouveeGeoloc);
                                } 
                            }
                        }

                        update acc;
                    }			
                }
                // Process for CHANTIER
                if(objectAPIName == 'Chantier__c') {
                    List<Chantier__c> chantierList = [SELECT Id, rue__c, codePostal__c, ville__c, departement__c, complementAdresse__c, 
                                                        Localisation__Latitude__s, Localisation__Longitude__s, pays__c 
                                                        FROM Chantier__c WHERE Id = :recordId];
                    if(!chantierList.isEmpty()) {
                        Chantier__c cha = chantierList[0];
                        cha.rue__c = street;
                        cha.ville__c = city;
                        cha.departement__c = state;
                        cha.codePostal__c = zip;
                        cha.pays__c = country;
                        cha.Localisation__Latitude__s = latitude;
                        cha.Localisation__Longitude__s = longitude;
                        cha.complementAdresse__c = complementAddress;
                        cha.etage__c = etage;
                        // DQE geocodage
                        if (adresseNonRenseignee == false & paysFR) {
                            if(PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false)) {
                                Utils_DQE.GeocodeResultType responseDQE = GeoUtils.geolocationChantierDQE(cha, null);
                                if(responseDQE != null){
                                    sauvegardeOk = true;
                                } else {
                                    sauvegardeOk = false;
                                }
                                cha.methodeGeocodage__c = 'Manuel';
                                if(!sauvegardeOk) {
                                    throw new KubeException(Label.AdresseNonTrouveeGeoloc);
                                } 
                            }
                        }

                        update cha;
                    }			
                }
                // Process for COLLABORATOR
                if(objectAPIName == 'Collaborator__c') {
                    List<Collaborator__c> collabList = [SELECT Id, street__c, postalCode__c, city__c, state__c, addressComplement__c,
                                                        localisation__Latitude__s, localisation__Longitude__s, country__c 
                                                        FROM Collaborator__c WHERE Id = :recordId];
                    if(!collabList.isEmpty()) {
                        Collaborator__c collab = collabList[0];
                        collab.street__c = street;
                        collab.city__c = city;
                        collab.state__c = state;
                        collab.postalCode__c = zip;
                        collab.country__c = country;
                        collab.addressComplement__c = complementAddress;
                        collab.localisation__Latitude__s = latitude;
                        collab.localisation__Longitude__s = longitude;
                        

                        update collab;
                    }			
                }
                // Process for ENTITY VERSION
                if(objectAPIName == 'EntityVersion__c') {
                    List<EntityVersion__c> entVersList = [SELECT Id, street__c, postalCode__c, city__c, addressSupplement__c,
                                                        geolocalisation__Latitude__s, geolocalisation__Longitude__s, country__c 
                                                        FROM EntityVersion__c WHERE Id = :recordId];
                    if(!entVersList.isEmpty()) {
                        EntityVersion__c entVer = entVersList[0];
                        entVer.street__c = street;
                        entVer.city__c = city;
                        entVer.postalCode__c = zip;
                        entVer.country__c = country;
                        entVer.addressSupplement__c = complementAddress;
                        entVer.geolocalisation__Latitude__s = latitude;
                        entVer.geolocalisation__Longitude__s = longitude;

                        update entVer;
                    }			
                }
            }
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}