//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Odigo 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 18/10/2021
//-- Version     : 1.1
//-- * 1.1 : Ajout des appels API REST Odigo
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_Odigo { 
    public static wsOdigoProsodie36AdministrationBeanModel.UserBean USER;

    // ODIGO VARIABLES
    public static final String ODIGO_LOGIN      = PropertiesUtils.getStringValue('prosodie.odigo.login', 'WEBTASKPANEL');
    public static final String ODIGO_PASSWORD   = PropertiesUtils.getStringValue('prosodie.odigo.password', 'WEBTASKPANEL');
    public static final Boolean ODIGO_ACTIVE    = PropertiesUtils.getBooleanValue('prosodie.odigo.enabled', false);
    public static final String ODIGO_SKILL            = PropertiesUtils.getStringValue('prosodie.odigo.skill', 'Formulaire');    
    public static final String ODIGO_DIM_SKILL        = PropertiesUtils.getStringValue('prosodie.odigo.dimanche.skill', 'FormulairesDIM');

    public static final Integer ODIGO_DIM_OUVERTURE   = PropertiesUtils.getIntegerValue('prosodie.odigo.dimanche.ouverture', 00);
    public static final Integer ODIGO_DIM_FERMETURE   = PropertiesUtils.getIntegerValue('prosodie.odigo.dimanche.fermeture', 18);
    public static final Integer ODIGO_TIMEOUT         = PropertiesUtils.getIntegerValue('prosodie.odigo.timeout', 30000);
    public static final Integer ODIGO_PRIORITY        = PropertiesUtils.getIntegerValue('prosodie.odigo.priority', 1);
    
    // Récupération paramètres de l'API
    public static final String ODIGO_API_HOST = PropertiesUtils.getStringValue('prosodie.odigo.api.host', 'https://api-kpark-depots.odigo.cx');
    public static final String ODIGO_CAMPAIGN_PATH = PropertiesUtils.getStringValue('prosodie.odigo.api.campaign.path', '/outbound/v1/campaigns');
    
    public static final String ODIGO_PRODUCTUID = PropertiesUtils.getStringValue('prosodie.odigo.api.productUID', 'routing_kpk01');
    public static final String ODIGO_TECHUSERUID = PropertiesUtils.getStringValue('prosodie.odigo.api.techUserUID', 'webservices_projet@kpark.com');
    public static final String ODIGO_TECHAPPUID = PropertiesUtils.getStringValue('prosodie.odigo.api.techUAppUID', 'jho2I4oubpWmD8oA');
    public static final String ODIGO_USERUID = PropertiesUtils.getStringValue('prosodie.odigo.api.userUID', '');
    public static final String ODIGO_APPUID = PropertiesUtils.getStringValue('prosodie.odigo.api.appUID', '');
    
    
    /**
    * @description Fonction de récupération de la variable "accessToken" nécessaire pour les appels à l'API Odigo
    * @param userUID Valeur de la variable userUID de l'application
    * @param appUID Valeur de la variable appUID de l'application
    * @return String Valeur de l'access token
    */
    public static String getAccessToken(String userUID, String appUID) {
        System.debug('### DEBUT Utils_Odigo : getAccessToken');
        String accessToken = '';
        
        try {
            // Récupération paramètres de l'API
            String apiPath = PropertiesUtils.getStringValue('prosodie.odigo.api.oauth.path', '/auth/v2/'+ODIGO_PRODUCTUID+'/direct-access-claim-sets');
            // Construction clé d'authorisation
            String authKey = EncodingUtil.base64Encode(Blob.valueof(ODIGO_TECHUSERUID+':'+ODIGO_TECHAPPUID));
            System.debug('## authKey: ' + authKey);
            // Contruction et appel au webservice Oauth Odigo
            String url = ODIGO_API_HOST + apiPath;
            String payload = '{ "userUid" : "'+userUID+'", "appUid" : "'+appUID+'", "ttl" : 3600 }';
            System.debug('## payload: ' + payload);
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            HTTPResponse resp = new HTTPResponse();
            req.setMethod('POST');
            req.setEndpoint(url);
            req.setBody(payLoad);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Basic '+authKey);
            System.debug('## URL: ' + req.getEndpoint());
            
            // Récupération de la réponse
            String respBody;
            if (!Test.isRunningTest()) {
                resp = http.send(req);
                System.debug('## Response HTTP: ' + resp);
                respBody = resp.getBody();
            } else {
                respBody = '{"accessToken":"test"}';
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && resp.getStatusCode() != 200) {
                throw new OdigoKparKException('ERREUR OAuth: '+resp.getStatusCode() + ' - Message = '+ resp.getStatus()); // Génère une erreur
            } else {
                System.debug('## respBody: ' + respBody);
                AuthentificationResponse result = (AuthentificationResponse) JSON.deserialize(respBody, AuthentificationResponse.class);
                System.debug('## Response: ' + result);
                if(result != null) {
                    accessToken = result.accessToken;
                }
            }
            System.debug('### FIN Utils_Odigo : getAccessToken');
        } catch (Exception e) {
            System.debug('ERREUR # Utils_Odigo.getAccessToken > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        return accessToken;
    }
    
    /**
    * @description Fonction pour faire appel à l'API REST Odigo pour récupérer l'ID d'une campagne depuis le label
    * @param label Nom de la campagne ODIGO
    * @return Integer Id de la campagne ODIGO
    */
    public static Integer getCampaignIdByLabel(String label) {
        System.debug('### DEBUT Utils_Odigo : getCampaignIdByLabel');
        Integer result = null;
        String url;
        
        try {
            // Authentification à l'API (access token)
            String accessToken = getAccessToken(ODIGO_USERUID, ODIGO_APPUID);
            
            // Contruction et appel au webservice Odigo
            url = ODIGO_API_HOST + ODIGO_CAMPAIGN_PATH + '?searchText='+EncodingUtil.urlEncode(label.trim(), 'UTF-8');
            HttpRequest req = constructHttpHeader(url, 'GET', accessToken);
            
            // Récupération de la réponse
            String respBody;
            Http http = new Http();
            HTTPResponse resp = new HTTPResponse();
            if (!Test.isRunningTest()) {
                resp = http.send(req);
                System.debug('## Response HTTP: ' + resp);
                respBody = resp.getBody();
            } else {
                respBody = '{ "campaignList" : [ { "campaignId" : 0 } ] }';
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && resp.getStatusCode() != 200) {
                throw new OdigoKparKException('ERREUR getCampaignIdByLabel: Code = '+ resp.getStatusCode() + ' - Message = '+ resp.getStatus()); // Génère une erreur générique
            } else {
                System.debug('## respBody: ' + respBody);
                CampaignSearchResponse resultWS = (CampaignSearchResponse) JSON.deserialize(respBody, CampaignSearchResponse.class);
                System.debug('## Response: ' + result);
                // Récupération id campagne    
                if(resultWS != null && resultWS.campaignList != null && !resultWS.campaignList.isEmpty()) {           
                    result = resultWS.campaignList[0].campaignId;
                }
            }
            System.debug('## Campaign Id: ' + result);
            System.debug('### FIN Utils_Odigo : getCampaignIdByLabel');
        } catch (Exception e) {
            throw e;
        } 
        return result;
    }
    
    /**
    * @description Fonction pour faire appel à l'API REST Odigo afin d'envoyer des callback dans une campagne
    * @param campaignId Id de la campagne Odigo
    * @param callbackListObj Objet contenant les informations des demandes d'appels (callback)
    * @return String Ok si pas d'erreur
    */
    public static String uploadCallback(Integer campaignId, List<WebCallBackContactList> callbackListObj) {
        System.debug('### DEBUT Utils_Odigo : uploadCallback');
        String result = null;
        String url;
        
        try {
            // Authentification à l'API (access token)
            String accessToken = getAccessToken(ODIGO_USERUID, ODIGO_APPUID);
            
            // Contruction et appel au webservice Odigo
            url = ODIGO_API_HOST + ODIGO_CAMPAIGN_PATH + '/' + String.valueOf(campaignId) +'/contactInfo';
            HttpRequest req = constructHttpHeader(url, 'POST', accessToken);
            // Création objet WebCallBack
            WebCallBackBean payloadObj = new WebCallBackBean(callbackListObj);
            String payload = JSON.serialize(payloadObj);
            System.debug('## payload: ' + payload);
            req.setBody(payLoad);
            
            // Récupération de la réponse
            String respBody;
            Http http = new Http();
            HTTPResponse resp = new HTTPResponse();
            if (!Test.isRunningTest()) {
                resp = http.send(req);
                System.debug('## Response HTTP: ' + resp);
                respBody = resp.getBody();
            } else {
                respBody = '{ "message": "Contacts added successfully to the campaign" }';
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && resp.getStatusCode() != 201) {
                throw new OdigoKparKException('ERREUR uploadCallback: Code = '+ resp.getStatusCode() + ' - Message = '+ resp.getStatus()); // Génère une erreur générique
            } else {
                System.debug('## respBody: ' + respBody);
                result = 'OK';
            }
            System.debug('### FIN Utils_Odigo : uploadCallback');
        } catch (Exception e) {
            throw e;
        } 
        return result;
    }

    /**
    * @description Configure un callback pour une campagne d'appel selon les numéros de téléphone du compte
    * @param acc Compte (champs Phone, telephoneDomicile__c, telephoneMobile__c et autreTelephone__c obligatoire)
    * @param priority Priorité de l'appel
    * @return WebCallBackContactList Callback
    */
    public static WebCallBackContactList configureCallback(Account acc, String priority) {
        System.debug('### DEBUT Utils_Odigo : configureCallback');
        Utils_Odigo.WebCallBackContactList result = null;
        
        try {
            // Ajout des numéros de téléphone au callback 
            List<String> numTelList = new List<String>();
            if (String.isNotBlank(acc.telephoneDomicile__c)) {
                numTelList.add(acc.telephoneDomicile__c);
            }
            if (String.isNotBlank(acc.telephoneMobile__c)) {
                numTelList.add(acc.telephoneMobile__c);
            }
            if (String.isNotBlank(acc.autreTelephone__c)) {
                numTelList.add(acc.autreTelephone__c);
            }
            if (String.isNotBlank(acc.Phone)) {
                numTelList.add(acc.Phone);
            }
            if (!numTelList.isEmpty()) {         
                // Configuration du callback    
                result = new Utils_Odigo.WebCallBackContactList();                
                List<Utils_Odigo.WebCallBackContact> contactsInfoList = new List<Utils_Odigo.WebCallBackContact>();
                contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER1', numTelList[0]));
                if(numTelList.size() > 1) {
                    if (String.isNotBlank( numTelList[1] )) {
                        contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER2', numTelList[1]));
                    }
                    if ( numTelList.size() > 2 && String.isNotBlank( numTelList[2] ) ) {
                        contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER3', numTelList[2]));
                    }
                    if ( numTelList.size() > 3 && String.isNotBlank( numTelList[3] ) ) {
                        contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER4', numTelList[3]));
                    }
                    if ( numTelList.size() > 4 && String.isNotBlank( numTelList[4] ) ) {
                        contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER5', numTelList[4]));
                    }
                }
                contactsInfoList.add(new Utils_Odigo.WebCallBackContact('CUSTOMERIDENTITY', acc.Id));
                contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PRIORITY', priority));
                result.contactFields = contactsInfoList;
                System.debug('## contactsInfoList: '+contactsInfoList);
            }
            System.debug('### FIN Utils_Odigo : configureCallback');
        } catch (Exception e) {
            throw e;
        } 
        return result;
    }

    /**
    * @description Configure un callback pour une campagne d'appel selon les numéros de téléphone du compte
    * @param acc Compte (champs Phone, telephoneDomicile__c, telephoneMobile__c et autreTelephone__c obligatoire)
    * @return WebCallBackContactList Callback
    */
    public static WebCallBackContactList configureCallback(Account acc) {
        Utils_Odigo.WebCallBackContactList result = null;
        try {
            result = configureCallback(acc, String.valueOf(ODIGO_PRIORITY));
        } catch (Exception e) {
            throw e;
        } 
        return result;
    }

    /*
    public static wsOdigoProsodie36AdministrationBeanModel.UserBean getUser() {
        if (USER == null) {
            USER = new wsOdigoProsodie36AdministrationBeanModel.UserBean();
            USER.login = ODIGO_LOGIN;
            USER.password = ODIGO_PASSWORD;
        }
        return USER;
    }
    */

    /**
    * @description Vérifie si le callback est correctement pris en charge par Odigo
    * @param returnCode Code d'erreur retourné par Odigo
    * @param data Donnée attaché au callback
    * @return String Message d'erreur
    */
    /*
    public static String checkCallback(Integer returnCode, String data) {
        /* 1 : Le rappel est autorisé pour cette compétence. Il n'y a pas d'appels en attente sur ce groupe de trafic.
           2 : Le rappel est autorisé pour cette compétence. Il y a au moins un appel en attente sur ce groupe de trafic.
           3 : Demande est rejetée pour une des raisons suivantes :
               - Le call back n'est pas activé sur le groupe de trafic correspondant à la compétence.
               - Le calendrier de dépôt de rappel est fermé.
               - Le nombre maximum de rappels autorisé a été atteint. 
           4 : Demande rejetée car la compétence donnée n'existe pas ou elle n'est pas affectée à un groupe de trafic.
           5 : Format de paramètre invalide.
          33 : Mauvais protocole HTTP/HTTPS.
         100 : Utilisateur non autorisé à utiliser le web service pour une des raisons suivantes:
               - Login inexistant
               - Mot de passe invalide
               - Login désactivé
               - Utilisateur non autorisé à utiliser le web service 
         101 : Le paramètre "skill" est vide ou null.
         102 : Problème technique       
         112 : Problème technique ne permettant pas de satisfaire la demande */
        /*System.debug('## Utils_Odigo : checkCallback - returnCode = ' + returnCode);
        String messageReturn='ERREUR ODIGO # ';
    
        if (returnCode == 1) 
            messageReturn='OK';
        else if (returnCode == 2)
            messageReturn+='Callback rejeté car au moins un appel en attente sur ce groupe de trafic !';
        else if (returnCode == 3)
            messageReturn+='Callback rejeté car callback inactif, calendrier de dépôt fermé ou nombre maximum de rappel atteint !';
        else if (returnCode == 4)  
            messageReturn+='Callback rejeté car compétence inexistante ou non affectée au groupe de trafic !';
        else if (returnCode == 5)  
            messageReturn+='Format de paramêtre invalide (Data: ' + (data == null ? '' : data) + ') !';
        else if (returnCode == 33)
            messageReturn+='Mauvais protocole HTTP/HTTPS! ';
        else if (returnCode == 100)
            messageReturn+='Utilisateur non autorisé à utiliser le web service !';
        else if (returnCode == 101)
            messageReturn+='Le paramètre "skill" est vide ou null.';  
        else if (returnCode == 102)  
            messageReturn+='Problème technique #102 ne permettant pas de satisfaire la demande !';  
        else if (returnCode == 112)  
            messageReturn+='Problème technique #112 ne permettant pas de satisfaire la demande !';
        else
            messageReturn+='Erreur inconnue #' + returnCode;
        return messageReturn;
    }
    */

    /**
    * @description Configure un callback pour une campagne d'appel selon les numéros de téléphone du compte
    * @param acc Compte (champs Phone, telephoneDomicile__c, telephoneMobile__c et autreTelephone__c obligatoire)
    * @param obj Objet Salesforce pour déterminer le numéro à présenter (compte, contact, projet, devis)
    * @return wsOdigoProsodie36WebcallbackBeanModel.CampaignCallBackWS Callback
    */
    /*
    public static wsOdigoProsodie36WebcallbackBeanModel.CampaignCallBackWS configureCampaignCallback(Account acc, sObject obj) {
        System.debug('### DEBUT Utils_Odigo : configureCampaignCallback');
        wsOdigoProsodie36WebcallbackBeanModel.CampaignCallBackWS callBack = null;

        // Ajout des numéros de téléphone au callback 
        List<String> numTelList = new List<String>();
        if (String.isNotBlank(acc.telephoneDomicile__c))
            numTelList.add(acc.telephoneDomicile__c);
        if (String.isNotBlank(acc.telephoneMobile__c))
            numTelList.add(acc.telephoneMobile__c);
        if (String.isNotBlank(acc.autreTelephone__c))
            numTelList.add(acc.autreTelephone__c);
        if (String.isNotBlank(acc.Phone))
            numTelList.add(acc.Phone);
        if (!numTelList.isEmpty()) {         
            // Configuration du callback    
            callBack = new wsOdigoProsodie36WebcallbackBeanModel.CampaignCallBackWS();   
            callBack.phoneNumber = numTelList[0];
            if(numTelList.size() > 1) {
                if (String.isNotBlank( numTelList[1] )) callBack.phoneNumber2 = numTelList[1];
                if ( numTelList.size() > 2 && String.isNotBlank( numTelList[2] ) ) callBack.phoneNumber3 = numTelList[2];
                if ( numTelList.size() > 3 && String.isNotBlank( numTelList[3] ) ) callBack.phoneNumber4 = numTelList[3];
                if ( numTelList.size() > 4 && String.isNotBlank( numTelList[4] ) ) callBack.phoneNumber5 = numTelList[4];
            }
        }
        System.debug('### FIN Utils_Odigo : configureCampaignCallback');
        return callBack;
    }
    */

    public static Boolean isCallBackAuthorized() {
        if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            return false;
        }
        return true;  
        // Envoi de la vérification
        /*wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint endPoint = new wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint();
        endPoint.timeout_x = ODIGO_TIMEOUT;  
        Integer returnCode;   
        if(Test.isRunningTest()) // WS impossible en test 
          returnCode=1;
        else
          returnCode = endPoint.isCallBackAuthorized(ODIGO_SKILL, getUser());
        
        checkCallback(returnCode,null);
        
        return returnCode == 1;  */  
    }
    
    /**
    * @description Fonction permettant de construire l'objet pour requête HTTP avec l'entete
    * @param url URL a appeler
    * @param method Méthode de la requête HTTP (GET ou POST)
    * @param accessToken Le token d'accès OAuth
    * @return HttpRequest Objet contenant les informations de la requête HTTP
    */
    public static HttpRequest constructHttpHeader(String url, String method, String accessToken) {
        HttpRequest req = new HttpRequest();
        try {
            req.setMethod(method);
            req.setTimeout(ODIGO_TIMEOUT);
            req.setEndpoint(url); // Ajout URL
            // Ajout access token
            req.setHeader('X-API-TOKEN', accessToken);
            // Ajout header         
            req.setHeader('X-WS-INSTANCE', ODIGO_PRODUCTUID);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/json');
            System.debug('## URL: ' + req.getEndpoint());
        } catch (Exception e) {
            System.debug('ERREUR # Utils_Odigo.constructHttpHeader > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        return req;
    }
        
    /***************************************************/
    /* OBJETS JSON                                     *
    /***************************************************/    
    public class AuthentificationResponse {
        public String accesstoken;
        public String claimSetUid;
        public Integer expTime;
    }
    
    public class CampaignSearchResponse {
        public List<CampaignResponse> campaignList;
    }
    
    public class CampaignResponse {
        public Integer campaignId;
        public String label;
    }

    public class WebCallBackBean {
        public WebCallBackDeduplicationRules deduplicationRules;
        public WebCallBackContactList[] contactList;

        public WebCallBackBean(List<WebCallBackContactList> contacts) {
            deduplicationRules = new WebCallBackDeduplicationRules();
            deduplicationRules.index = 0;
            deduplicationRules.criterias = new List<WebCallBackCriterias>();
            deduplicationRules.selectedcriterias = new List<WebCallBackSelectedcriterias>();
            deduplicationRules.unmappedCriterias = new List<WebCallBackUnmappedCriterias>();
            contactList = contacts;
        }
    }
    public class  WebCallBackDeduplicationRules {
        public Integer index;   //0
        public WebCallBackCriterias[] criterias;
        public WebCallBackSelectedcriterias[] selectedcriterias;
        public WebCallBackUnmappedCriterias[] unmappedCriterias;
    }
    public class WebCallBackCriterias { }
    public class WebCallBackSelectedcriterias { }
    public class WebCallBackUnmappedCriterias { }
    public class WebCallBackContactList {
        public WebCallBackContact[] contactFields;
    }
    public class WebCallBackContact {
        public String webServiceId; //PHONENUMBER1
        public String value;    //0123456789
        
        public WebCallBackContact(String webServiceId, String value) {
            this.webServiceId = webServiceId;
            this.value = value;
        }
    }
    
    public class OdigoKparKException extends Exception { }
}