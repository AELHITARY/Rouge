//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_DQE
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/08/2020
//-- Version     : 1.7
//-- * 1.7 : Ajout fonction générique pour appel des services DQE Address
//-- * 1.6 : Ajout appel WS DQE pour code postal
//-- * 1.5 : RQM-29 - Matrice de dédoublonnage
//-- * 1.4 : CRM-748 - Traitement des retours DQE
//-- * 1.3 : CRM-919 - DQE Dedup Séparation des comptes pro et perso
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_DQE {
    private static final String LICENCEDQE = PropertiesUtils.getStringValue('dqe.adresse.licence', '');
    private static final String ADR_URLDQE = PropertiesUtils.getStringValue('dqe.adresse.server', '');
    private static final String DEDUPCOMPTEPERSO_URLDQE = PropertiesUtils.getStringValue('dqe.dedup.comptePerso.server', '');
    private static final String DEDUPCOMPTEPRO_URLDQE = PropertiesUtils.getStringValue('dqe.dedup.comptePro.server', '');
    private static final String DEDUPCHANTIER_URLDQE = PropertiesUtils.getStringValue('dqe.dedup.chantier.server', '');
    private static final Integer DEDUPLIMITDOUBLON = PropertiesUtils.getIntegerValue('dqe.dedup.doublons.limit', 20);

    /**
    * @description Exécution du WebService RNVP de DQE pour récupération des informations de l'adresse (IRIS)
    * @param complement Complément d'adresse
    * @param codePostal Code postal
    * @param adresse Rue
    * @param lieudit Lieu dit
    * @param ville Ville
    * @param codePays Code du pays (3 lettres)
    * @return List<GeocodeResultType> Liste des propositions d'adresse
    */ 
    public static List<GeocodeResultType> DQEIrisRNVP(String complement, String codePostal, String adresse, String lieudit, String ville, String codePays) {
        System.debug('### DEBUT Utils_DQE.DQEIrisRNVP');
        List<GeocodeResultType> results = new List<GeocodeResultType>();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try{
            String endPoint = ADR_URLDQE+'/RNVP/';
            endPoint += '?Adresse='           + Utils.replaceNullURL(complement);
            endPoint += '|'                   + Utils.replaceNullURL(adresse);
            endPoint += '|'                   + Utils.replaceNullURL(lieudit);
            endPoint += '|'                   + Utils.replaceNullURL(codePostal);
            endPoint += '|'                   + Utils.replaceNullURL(ville);
            endPoint += '&Instance=0&Taille=38';
            endPoint += '&Pays='              + Utils.replaceNullURL(codePays);
            endPoint += '&Licence='           + LICENCEDQE;
            endPoint += '&Proposition=O';
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            Map<String, Object> parser = new Map<String, Object>();
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                System.debug('## Reponse : '+ response.getBody());
                parser = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
               parser = (Map<String, Object>) JSON.deserializeUntyped('{"1": {"Roudis": "1009", "DQECompte": "", "Instance": "0", "CodePostal": "13290", "Status_IrisIlot": "INSEE", '+
                    '"Latitude": "43.47748", "Localite": "AIX EN PROVENCE", "Province": "", "NbNumero": "0", "Complement": "BATIMENT OLYMPE", "Voie": '+
                    '"PIERRE BERTHIER", "Adresse": "550 RUE PIERRE BERTHIER", "Cedex": "", "Numero": "550", "ListeNumero": "", "IDHexaposte": '+
                    '"23", "IDCle": "1300122UST", "LieuDit": "LES MILLES", "ilot": "PEK3", "TypeVoie": "RUE", "DQECodeDetail": "10", "DQELibErreur": "OK", '+
                    '"Longitude": "5.37488", "CompNum": "", "iris": "0906", "IDLocalite": "13001", '+
                    '"DQECodeErreur": "0", "Pays": "FRA", "IDVoie": "190716", "NumSeul": "550", "Ligne2": "", "DQEPourcentErreur": ""}}');
            }
            // Construction objet de résultat
            for(String key : parser.keySet()) {
                GeocodeResultType result = new GeocodeResultType();
                Map<String, Object> content = (Map<String, Object>) parser.get(key);
                result.Numero = (String)content.get('Numero');
                result.Adresse = (String)content.get('Adresse'); // égal à 'NULL' quand vide contrairement aux autres champs qui sont égaux à ''
                if(result.Adresse == 'NULL') result.Adresse = ''; //on uniformise le comportement
                result.Complement = (String)content.get('Complement');
                result.CodePostal = (String)content.get('CodePostal');
                result.Localite = (String)content.get('Localite');
                result.Province = (String)content.get('Province');
                result.Pays = (String)content.get('Pays');
                result.IDVoie = (String)content.get('IDVoie');
                result.IDLocalite = (String)content.get('IDLocalite');
                result.Latitude = (String)content.get('Latitude');
                result.Longitude = (String)content.get('Longitude');
                result.DQECodeErreur = (String)content.get('DQECodeErreur');
                result.iris = (String)content.get('iris');
                results.add(result);
            }
            System.debug('### FIN Utils_DQE.DQEIrisRNVP');
            return results;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException(Label.dqe_msg_errorsWSDQEAddress);
        }
    }

    /**
    * @description Exécution du WebService CP de DQE pour récupération des informations de l'adresse si seulement code postal
    * @param codePostal Code postal
    * @param codePays Code du pays (3 lettres)
    * @return List<GeocodeResultType> Liste des propositions d'adresse
    */
    public static List<GeocodeResultType> DQEPostalCode(String codePostal, String codePays) {
        System.debug('### DEBUT Utils_DQE.DQEPostalCode');
        List<GeocodeResultType> results = new List<GeocodeResultType>();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try{
            String endPoint = ADR_URLDQE+'/CP/';
            endPoint += '?CodePostal='           + Utils.replaceNullURL(codePostal);
            endPoint += '&Alpha=false&Instance=0';
            endPoint += '&Pays='              + Utils.replaceNullURL(codePays);
            endPoint += '&Licence='           + LICENCEDQE;
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            Map<String, Object> parser = new Map<String, Object>();
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                System.debug('## Reponse : '+ response.getBody());
                parser = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
               parser = (Map<String, Object>) JSON.deserializeUntyped('{"1": {"Province": "*", "IDLocalite": "13001", "NbNumero": "", "Pays": "FRA", "IDVoie": "", '+
                '"Latitude": "43.5360708378", "Cedex": "0", "Numero": "", "TypeVoie": "", "Instance": "0", "ListeNumero": "", "CodePostal": "13100", '+
                '"SousLocalite": "", "LieuDit": "", "Nbnumero": "", "Localite": "AIX EN PROVENCE", "Longitude": "5.39857444582", "Complement": "", "Entreprise": ""}}');
            }
            // Construction objet de résultat
            for(String key : parser.keySet()) {
                GeocodeResultType result = new GeocodeResultType();
                Map<String, Object> content = (Map<String, Object>) parser.get(key);
                result.Numero = (String)content.get('Numero');
                result.Complement = (String)content.get('Complement');
                result.CodePostal = (String)content.get('CodePostal');
                result.Localite = (String)content.get('Localite');
                result.Province = (String)content.get('Province');
                result.Pays = (String)content.get('Pays');
                result.IDVoie = (String)content.get('IDVoie');
                result.IDLocalite = (String)content.get('IDLocalite');
                result.Latitude = (String)content.get('Latitude');
                result.Longitude = (String)content.get('Longitude');
                results.add(result);
            }
            System.debug('### FIN Utils_DQE.DQEPostalCode');
            return results;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException(Label.dqe_msg_errorsWSDQEAddress);
        }
    }

    /**
    * @description Exécution du WebService LATLG de DQE pour récupération des inforamtions latitude/longitude
    * @param idVoie ID INSEE de la rue
    * @param numero Numéro de la rue
    * @param codePays Code du pays (3 lettres)
    * @return GeocodeResultType Résultat
    */
    public static GeocodeResultType DQELongLat(String idVoie, String numero, String codePays) {
        System.debug('### DEBUT Utils_DQE.DQELongLat');
        GeocodeResultType result = new GeocodeResultType();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try{
            String endPoint = ADR_URLDQE+'/LATLG/';
            endPoint += '?Pays='           + codePays;
            endPoint += '&IDVoie='         + idVoie;
            endPoint += '&Num='            + numero;
            endPoint += '&Licence='        + LICENCEDQE;
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            Map<String, Object> parser = new Map<String, Object>();
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                System.debug('## Reponse : '+ response.getBody());
                parser = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            }  else {
                parser = (Map<String, Object>) JSON.deserializeUntyped('{"1": {"Latitude": "43.5360708378", "Longitude": "5.39857444582"}}');
            }
            // Construction objet de résultat
            if(!parser.isEmpty()) {
                Map<String, Object> content = (Map<String, Object>) parser.get('1');
                result.Latitude = (String)content.get('Latitude');
                result.Longitude = (String)content.get('Longitude');
            }
            System.debug('### FIN Utils_DQE.DQELongLat');
            return result;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException(Label.dqe_msg_errorsWSDQEAddress);
        }
    }

    /**
    * @description Fonction générique pour exécution d'un service de DQE
    * @param params Map contenant les paramètres et leur valeur
    * @param service Nom du service DQE
    * @return String Response de la requête
    */
    public static String executeDQEAddressRequest(String service, Map<String, String> params){
        System.debug('### DEBUT Utils_DQE.executeDQEAddressRequest');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        String result;

        try{
            String endPoint = ADR_URLDQE+'/'+service+'/?';
            // Création des paramètres selon entrée
            for (String key : params.keySet()) {
                String value = EncodingUtil.urlEncode(params.get(key), 'UTF-8');
                endPoint += key + '=' + value + '&';
            }            
            endPoint += 'Licence=' + LICENCEDQE;
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            // Exécution de la requête
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                result = response.getBody();
            } else {
                result = 'test';
            }
            System.debug('## Response : ' + result);

            // Exécution de la requête
            System.debug('### FIN Utils_DQE.executeDQEAddressRequest');
            return result;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    public class GeocodeResultType {
        public String Numero;
        public String Adresse;
        public String Complement;
        public String CodePostal;
        public String Localite;
        public String Province;
        public String Pays;
        public String IDVoie;
        public String IDLocalite;
        public String DQECodeErreur;
        public String iris;
        public String Latitude;
        public String Longitude;
    }

    /**
    * @description Exécution du WebService DQE pour détection de doublons d'un compte dans la base de données
    * @param codePostal CodePostal
    * @param lastName Nom de famille
    * @param firstName Prénom
    * @param adresse Numéro et nom de la rue
    * @param ville Ville
    * @param fullName Nom et prénom
    * @param isPersonAccount Compte personnel ou professionnel
    * @param personEmail Email
    * @param personHomePhone Téléphone domicile
    * @param personMobilePhone Téléphone mobile
    * @param phone Autre téléphone
    * @param fax Fax
    * @param accId ID du compte
    * @return Liste des chantiers en doublons détectés par DQE
    */
    public static Map<String, Account> DQELookupAccount(String codePostal, String lastName, String firstName, String adresse,
                                                        String ville, String fullName, Boolean isPersonAccount, String personEmail,
                                                        String personHomePhone, String personMobilePhone, String phone, String fax, String accId) {
        System.debug('### DEBUT Utils_DQE.DQELookupAccount');
        Map<String, Account> resultatAcc = new Map<String, Account>();
        Map<String, Account> resultat = new Map<String, Account>();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try{
            String endPoint = (isPersonAccount ? DEDUPCOMPTEPERSO_URLDQE : DEDUPCOMPTEPRO_URLDQE) + '/DQELookupCandidate/';
            endPoint += '?CODEPOSTAL__C='           + Utils.replaceNullURL(codePostal);
            endPoint += '&RUE__C='                  + Utils.replaceNullURL(adresse);
            endPoint += '&VILLE__C='                + Utils.replaceNullURL(ville);
            if(isPersonAccount){
                endPoint += '&LASTNAME='            + Utils.replaceNullURL(lastName);
                endPoint += '&FIRSTNAME='           + Utils.replaceNullURL(firstName);
                endPoint += '&PERSONEMAIL='         + Utils.replaceNullURL(personEmail);
                endPoint += '&PERSONHOMEPHONE='     + Utils.replaceNullURL(personHomePhone);
                endPoint += '&PERSONMOBILEPHONE='   + Utils.replaceNullURL(personMobilePhone);
            } else {
                endPoint += '&NAME='                + Utils.replaceNullURL(fullName);
                endPoint += '&PHONE='               + Utils.replaceNullURL(phone);
                endPoint += '&FAX='                 + Utils.replaceNullURL(fax);
            }
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            // Résultat modifié en objet JSON puis stocké dans un Compte pour envoi vers la page de détails
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                System.debug('## Reponse : '+ response.getBody());
                if(response.getBody() != '{"result": "NOT FOUND"}'){
                    Map<String, Account> resultAccTmp = (Map<String, Account>) JSON.deserialize(response.getBody(), Map<String, Account>.class);
                    Map<String, ObjectJSONCheck> accountJSON = (Map<String, ObjectJSONCheck>) JSON.deserialize(response.getBody(), Map<String, ObjectJSONCheck>.class);
                    Integer index=0;
                    for(String clef : accountJSON.keySet()){
                        if(accountJSON.get(clef) != null && accountJSON.get(clef).ID != accId && index<DEDUPLIMITDOUBLON) {
                            resultatAcc.put(accountJSON.get(clef).ID, resultAccTmp.get(clef));
                            index++;
                        }
                    }
                }
            }
            // SOQL - Retour seulement des enregistrements présent en base
            for(Account rec : [SELECT Id FROM Account WHERE Id IN :resultatAcc.keySet()]) {
                if(resultatAcc.get(rec.Id) != null) resultat.put(rec.Id,resultatAcc.get(rec.Id));
            }
            System.debug('### FIN Utils_DQE.DQELookupAccount');
            return resultat;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException(Label.merge_msg_errorsWebserviceDQE);
        }
    }

    /**
    * @description Exécution du WebService DQE pour détection de doublons d'un chantier dans la base de données
    * @param codePostal CodePostal
    * @param adresse Numéro et nom de la rue
    * @param ville Ville
    * @param complementAdresse Complement d'adresse
    * @param proprietaire Proprietaire
    * @param autreProprietaire Autre proprietaire
    * @param chantierId ID du chantier
    * @return Liste des chantier en doubons détecté par DQE
    */
    public static Map<String, Chantier__c> DQELookupChantier(String adresse, String codePostal, String ville, String complementAdresse, Decimal etage, String chantierId) {
        System.debug('### DEBUT Utils_DQE.DQELookupChantier');
        Map<String, Chantier__c> resultatCha = new Map<String, Chantier__c>();
        Map<String, Chantier__c> resultat = new Map<String, Chantier__c>();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try {
            String endPoint = DEDUPCHANTIER_URLDQE+'/DQELookupCandidate/';
            endPoint += '?RUE__C='                  + Utils.replaceNullURL(adresse);
            endPoint += '&CODEPOSTAL__C='           + Utils.replaceNullURL(codePostal);
            endPoint += '&VILLE__C='                + Utils.replaceNullURL(ville);
            endPoint += '&COMPLEMENTADRESSE__C='    + Utils.replaceNullURL(complementAdresse);
            endPoint += '&ETAGE__C='                + Utils.replaceNull(Integer.valueOf(etage));
            endPoint += '&PROPRIETAIRE__C=';        // CRM-891 / JMU / 05/12/2016 : Champ qui n'est plus utilisé dans la détection
            endPoint += '&AUTREPROPRIETAIRE__C=';   // CRM-891 / JMU / 05/12/2016 : Champ qui n'est plus utilisé dans la détection
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            System.debug('## End Point : '+ endPoint);

            // Résultat modifié en objet JSON puis stocké dans un Chantier pour envoi vers la page de détails
            if(!Test.isRunningTest()){
                response = h.send(req); // Send the request, and return a response
                System.debug('## Reponse : '+ response.getBody());
                if(response.getBody() != '{"result": "NOT FOUND"}'){
                    Map<String, Chantier__c> resultChaTmp = (Map<String, Chantier__c>) JSON.deserialize(response.getBody(), Map<String, Chantier__c>.class);
                    Map<String, ObjectJSONCheck> chantierJSON = (Map<String, ObjectJSONCheck>) JSON.deserialize(response.getBody(), Map<String, ObjectJSONCheck>.class);
                    Integer index=0;
                    for(String clef : chantierJSON.keySet()){
                        if(chantierJSON.get(clef) != null && chantierJSON.get(clef).ID != chantierId && index<DEDUPLIMITDOUBLON) {
                            resultatCha.put(chantierJSON.get(clef).ID, resultChaTmp.get(clef));
                            index++;
                        }
                    }
                }
            }
            // SOQL - Retour seulement des enregistrements présent en base
            for(Chantier__c rec : [SELECT Id, etage__c, rue__c, ville__c, codePostal__c, complementAdresse__c,
                                        proprietaire__c, autreProprietaire__c, autreProprietaire__r.Name, proprietaire__r.Name
                                    FROM Chantier__c WHERE Id IN :resultatCha.keySet()]) {
                resultat.put(rec.Id,rec);
            }
            System.debug('### FIN Utils_DQE.DQELookupChantier');
            return resultat;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException(Label.merge_msg_errorsWebserviceDQE);
        }
    }

    // Objet pour stocker l'ID de l'objet lors du passage en JSON
    public class ObjectJSONCheck{
        public string ID{get;set;}
        public Decimal distance{get;set;}
    }
}