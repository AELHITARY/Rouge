//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_TrustPilot
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/09/2021
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
public with sharing class Utils_TrustPilot {

    public static void createInvitations(List<KContrat__c> kconList) {
        system.debug('### DEBUT createInvitations');

        system.debug('## kconList : '+kconList);
       
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HTTPResponse();

        String apiURL = PropertiesUtils.getStringValue('trustpilot.api.inv.url', 'https://invitations-api.trustpilot.com/v1/private/business-units/');
        String businessUnitId = PropertiesUtils.getStringValue('trustpilot.api.businessUnitId');

        try {
            String accessToken = getToken();
            system.debug('accessToken : '+accessToken);
                
            for(KContrat__c kcon : kconList){
                system.debug('## COMPTE -- ID : '+kcon.Id+'-- NOM : '+kcon.nomCompte__c+'-- EMAIL : '+kcon.emailCompte__c);
                //String kconId = String.valueOf(kcon.Id).left(0)+String.valueOf(kcon.Id).right(String.valueOf(kcon.Id).length()-1);

                String bodyRaw = '{';
                    bodyRaw += '        "consumerEmail": "'+kcon.emailCompte__c+'",';
                    bodyRaw += '        "referenceNumber": "'+kcon.Id+'",';
                    bodyRaw += '        "consumerName": "'+kcon.nomCompte__c+'",';
                    bodyRaw += '        "locale": "fr-FR",';
                    bodyRaw += '        "senderEmail": "noreply.invitations@trustpilotmail.com",';
                    bodyRaw += '        "serviceReviewInvitation": {';
                    bodyRaw += '            "redirectUri": "http://kpark.fr",';
                    bodyRaw += '            "tags": [';
                    bodyRaw += '            "tag2"';
                    bodyRaw += '            ],';
                    bodyRaw += '            "templateId": "6053398b6b18780001b32ac4"';
                    bodyRaw += '        },';
                    bodyRaw += '        "locationId": "ABC123",';
                    bodyRaw += '        "senderName": "Enquête de satisfaction K par K"';
                    bodyRaw += '    }';
                    bodyRaw += '';
                    
                // Contruction et appel au webservice
                String endPoint = apiURL + businessUnitId + '/email-invitations';
                System.debug('## EndPoint: '+endPoint);
                // Construction de la requête
                req.setEndpoint(endPoint);
                req.setMethod('POST');
                req.setbody(bodyRaw);
                req.setTimeout(120000); // en millisecondes
                // Ajout access token dans le header
                String authorizationHeader = 'Basic MlBQR2pHaFhsbHNzOG5pRzBBR1lzSmhHYUM0bVBHQ286SVpmcFd3TUhJTWNDbWE2RA==';
                req.setHeader('Authorization', authorizationHeader);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('token', accessToken);
                req.setHeader('username', PropertiesUtils.getStringValue('trustpilot.api.username'));
                req.setHeader('password', PropertiesUtils.getStringValue('trustpilot.api.password'));
                req.setHeader('apikey', PropertiesUtils.getStringValue('trustpilot.api.apikey'));
                
                // Récupération de la réponse
                String respBody;
                if (!Test.isRunningTest()) {
                    response = h.send(req);
                    System.debug('## Response HTTP: ' + response);
                    respBody = response.getBody();
                    System.debug('## respBody: ' + respBody);
                } else {
                    respBody = '{}';
                }
                
                // Vérification de la réponse
                if(!Test.isRunningTest() && response.getStatusCode() != 200 && response.getStatusCode() != 202) {
                    throw new KubeException('ERREUR : Code = '+ response.getStatusCode() + ' - Message = '+ response.getStatus()); // Génère une erreur
                } else {
                    System.debug('## Response HTTP: OK');
                } 
            }   
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Trustpilot : Erreur de l\'API de création de l\'invitation', e);
        }
    }

    public static List<Reviews> getInvitationInfo() {
        system.debug('### DEBUT getInvitationInfo');
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HTTPResponse();
        String apiURL = PropertiesUtils.getStringValue('trustpilot.api.url', 'https://api.trustpilot.com/v1/private/business-units/');
        String businessUnitId = PropertiesUtils.getStringValue('trustpilot.api.businessUnitId', '59c8fb8c0000ff0005abfef7');
        List<Reviews> revToVerify = new List<Reviews>();
        
        try {
            // Contruction et appel au webservice
            Integer nbReviewPerPage = PropertiesUtils.getIntegerValue('trustpilot.api.nbReviewPerPage', 20);
            String endPoint = apiURL + businessUnitId + '/reviews?perPage='+nbReviewPerPage;
            System.debug('## EndPoint: '+endPoint);
            // Construction de la requête
            req.setEndpoint(endPoint);
            String accessToken = getToken();
            //accessToken = 'HEZv7ubIdZjJ36qKd6HbtGHvJqO3';
            req.setHeader('apikey', PropertiesUtils.getStringValue('trustpilot.api.apikey'));
            req.setHeader('token', accessToken);
            req.setMethod('GET');
            req.setTimeout(120000); // en millisecondes
            
            // Récupération de la réponse
            String respBody;
            if (!Test.isRunningTest()) {
                response = h.send(req);
                System.debug('## Response HTTP: ' + response);
                respBody = response.getBody();
                ReviewJSON parser = new ReviewJSON();
                parser = (ReviewJSON) System.JSON.deserialize(response.getBody(), ReviewJSON.class);
                System.debug('## Reponse : '+ response.getBody());
                for(Reviews rev : parser.reviews){
                    if(rev != null){
                        if(rev.referenceId != null && rev.referenceId.startsWith('0')){
                            rev.referenceId = 'a'+rev.referenceId;
                        }
                        System.debug('rev.id : '+rev.id);
                        System.debug('rev.title : '+rev.title);
                        System.debug('rev.stars : '+rev.stars);
                        System.debug('rev.referenceId : '+rev.referenceId);
                        System.debug('rev.createdAt : '+rev.createdAt);
                        System.debug('rev.text : '+rev.text);
                        System.debug('rev.findReviewer : '+rev.findReviewer);
                        System.debug('#########################');
                        revToVerify.add(rev);
                    }
                }
            } else {
                ReviewJSON parser = new ReviewJSON();

                Consumer cnsm = new Consumer();
                cnsm.displayLocation = 'Here';
                cnsm.numberOfReviews = 0;
                cnsm.displayName = 'John Doe';
                cnsm.id = 'testIdcnsm1';
                

                BusinessUnit bu = new BusinessUnit();
                bu.identifyingName = 'KparK';
                bu.displayName = 'KparK';
                bu.id = '59c8fb8c0000ff0005abfef7';

                ReportData rd = new ReportData();
                rd.source = 'SF';
                rd.publicComment = null;
                rd.createdAt = null;

                Links lk = new Links();
                lk.href = 'www.kpark.fr';
                lk.method = null;
                lk.rel = null;

                ConsumerResponse cr = new ConsumerResponse();
                cr.referenceId = null;
                cr.name = 'John Doe';
                cr.submittedAt = null;
                cr.phoneNumber = null;
                cr.address = null;
                cr.message = null;
                cr.email = null;

                Tags tag = new Tags();
                tag.group_Z = null;
                tag.value = null;

                Location loc = new Location();
                loc.externalId = null;
                loc.urlFormattedName = null;
                loc.id = null;
                loc.name = null;

                CompanyReply cReply = new CompanyReply();
                cReply.text = null;
                cReply.updatedAt = null;
                cReply.createdAt = null;
                cReply.authorBusinessUserId = null;

                Invitation inv = new Invitation();
                inv.businessUnitId = null;

                Requests rq = new Requests();
                rq.status = null;
                rq.businessUserMessage = null;
                rq.id = null;
                rq.created = null;

                FindReviewer fr = new FindReviewer();
                fr.isEligible = true;

                BusinessUnitHistory buh = new BusinessUnitHistory();
                buh.identifyingName = null;
                buh.displayName = null;
                buh.businessUnitId = null;
                buh.changeDate = null;

                Reviews rev = new Reviews();
                rev.referenceId = '0001000100010001';
                rev.referralEmail = 'test.test@test.com';
                rev.text = 'très satisfait , livraison rapide';
                rev.updatedAt = null;
                rev.numberOfLikes = 0;
                rev.id = '6141af31215cfcced2664f9d';
                rev.createdAt = '2021-09-15T08:30:41Z';
                rev.title = 'très satisfait';
                rev.countsTowardsLocationTrustScore = false;
                rev.source = 'AFSv2';
                rev.location = null;
                rev.stars = 5;
                rev.consumer = cnsm;
                rev.reportData = rd;
                rev.isVerified = false;
                rev.status = 'sent';
                rev.reviewVerificationLevel = 'verified';
                rev.language = 'fr';
                rev.experiencedAt = null;
                revToVerify.add(rev);

                rev.referenceId = null;
                revToVerify.add(rev);
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && response.getStatusCode() != 200) {
                throw new KubeException('ERREUR : Code = '+ response.getStatusCode() + ' - Message = '+ response.getStatus()); // Génère une erreur
            } else {
                System.debug('## Response HTTP: OK');
            }    
            return revToVerify;
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Trustpilot : Erreur de l\'API de récupération de l\'invitation', e);
            return null;
        }
    }

    @future (callout=true)
    public static void replyToReview(String reviewId, String message) {
        system.debug('### DEBUT replyToReview');
        system.debug('## reviewId : '+reviewId);
       
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HTTPResponse();
        String apiURL = PropertiesUtils.getStringValue('trustpilot.api.rev.url', 'https://api.trustpilot.com/v1/private/reviews/');
        String businessUnitId = PropertiesUtils.getStringValue('trustpilot.api.businessUnitId', '59c8fb8c0000ff0005abfef7');

        try {            
            String accessToken = getToken();
            system.debug('accessToken : '+accessToken);

            String bodyRaw = '{';
                bodyRaw += '        "message": "'+message+'",';
                bodyRaw += '        "authorBusinessUserId": "'+reviewId+'",';
                bodyRaw += '  }';
                bodyRaw += '';
                
            // Contruction et appel au webservice
            String endPoint = apiURL + reviewId + '/reply';
            System.debug('## EndPoint: '+endPoint);
            // Construction de la requête
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setbody(bodyRaw);
            req.setTimeout(120000); // en millisecondes
            // Ajout access token dans le header
            String authorizationHeader = 'Basic MlBQR2pHaFhsbHNzOG5pRzBBR1lzSmhHYUM0bVBHQ286SVpmcFd3TUhJTWNDbWE2RA==';
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('token', accessToken);
            req.setHeader('username', PropertiesUtils.getStringValue('trustpilot.api.username'));
            req.setHeader('password', PropertiesUtils.getStringValue('trustpilot.api.password'));
            req.setHeader('apikey', PropertiesUtils.getStringValue('trustpilot.api.apikey'));
            
            // Récupération de la réponse
            String respBody;
            if (!Test.isRunningTest()) {
                response = h.send(req);
                System.debug('## Response HTTP: ' + response);
                respBody = response.getBody();
                System.debug('## respBody: ' + respBody);
            } else {
                respBody = '{}';
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && response.getStatusCode() != 200 && response.getStatusCode() != 201 && response.getStatusCode() != 202) {
                throw new KubeException('ERREUR : Code = '+ response.getStatusCode() + ' - Message = '+ response.getStatus()); // Génère une erreur
            } else {
                System.debug('## Response HTTP: OK');
            } 
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Trustpilot : Erreur de l\'API de TRustpilot pour publier la réponse a un avis', e);
        }
    }

    public static String getToken() {
        system.debug('### DEBUT createInvitations');
       
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse response = new HTTPResponse();

        String bodyRaw = 'grant_type=password&';
                bodyRaw += 'username=julien.morineau@soprasteria.com&';
                bodyRaw += 'password=Crmcsm1$';

        try {

            // Contruction et appel au webservice
            String endPointAccessToken = 'https://api.trustpilot.com/v1/oauth/oauth-business-users-for-applications/accesstoken';
            System.debug('## EndPointAccessToken: '+endPointAccessToken);
            // Construction de la requête
            req.setEndpoint(endPointAccessToken);
            req.setMethod('POST');
            req.setbody(bodyRaw);
            req.setTimeout(120000); // en millisecondes
            // Ajout access token dans le header
            String authorizationHeader = 'Basic MlBQR2pHaFhsbHNzOG5pRzBBR1lzSmhHYUM0bVBHQ286SVpmcFd3TUhJTWNDbWE2RA==';
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            // Récupération de la réponse
            String respBody;
            Map<String, Object> parser = new Map<String, Object>();
            if (!Test.isRunningTest()) {
                response = h.send(req);
                System.debug('## Response HTTP: ' + response);
                //System.debug('## BODY: ' + response.getBody());
                respBody = response.getBody();
                parser = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                respBody = '{';
                respBody += '     "refresh_token_expires_in": "7779999",';
                respBody += '    "refresh_token_status": "approved",';
                respBody += '    "api_product_list": "[trustpilot-client-api, public_data]",';
                respBody += '    "app_enduser": "60acf59c1446f1002af93b36",';
                respBody += '    "api_product_list_json": [';
                respBody += '        "trustpilot-client-api",';
                respBody += '        "public_data"';
                respBody += '    ],';
                respBody += '    "organization_name": "trustpilot",';
                respBody += '     "developer.email": "dev.accounts+developerapps@trustpilot.com",';
                respBody += '    "token_type": "BearerToken",';
                respBody += '     "issued_at": "1631694590276",';
                respBody += '     "client_id": "2PPGjGhXllss8niG0AGYsJhGaC4mPGCo",';
                respBody += '     "access_token": "bgqDlDIUNZe3qnht5GxK99bcFp1y",';
                respBody += '     "refresh_token": "VZoAfjMzyoxP75A0lyZpcLGUm5aglMn7",';
                respBody += '     "application_name": "fa696021-f5c6-4173-bbec-2950109115c7",';
                respBody += '     "scope": "",';
                respBody += '     "refresh_token_issued_at": "1631694590276",';
                respBody += '     "expires_in": "359999",';
                respBody += '     "refresh_count": "0",';
                respBody += '     "status": "approved"';
                respBody += '}';
                parser = (Map<String, Object>) JSON.deserializeUntyped(respBody);
            }       
            // Vérification de la réponse
            if(!Test.isRunningTest() && response.getStatusCode() != 200 && response.getStatusCode() != 201 && response.getStatusCode() != 202) {
                throw new KubeException('ERREUR : Code = '+ response.getStatusCode() + ' - Message = '+ response.getStatus()); // Génère une erreur
            } else {
                System.debug('## Response HTTP: OK');
            }  
            System.debug('## TOKEN: ' + String.valueOf(parser.get('access_token')));  
            return String.valueOf(parser.get('access_token'));
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Trustpilot : Erreur de l\'API de création de l\'invitation', e);
            return null;
        }
    }

    /***************************************************/
    /* OBJETS JSON POUR UNE BUSINESS REVIEW            *
    /***************************************************/
    public class ReviewJSON {
        public List<Reviews> reviews {get;set;} 
        public List<Links> links {get;set;} 
    }
    
    public class CompanyReply {
        public String text {get;set;} 
        public String updatedAt {get;set;} 
        public String createdAt {get;set;} 
        public String authorBusinessUserId {get;set;} 
    }
    
    public class Invitation {
        public String businessUnitId {get;set;} 
    }
    
    public class Requests {
        public String status {get;set;} 
        public ConsumerResponse consumerResponse {get;set;} 
        public String businessUserMessage {get;set;} 
        public String id {get;set;} 
        public String created {get;set;} 
    }
    
    public class FindReviewer {
        public List<Requests> requests {get;set;} 
        public Boolean isEligible {get;set;} 
    }
    
    public class BusinessUnitHistory {
        public String identifyingName {get;set;} 
        public String displayName {get;set;} 
        public String businessUnitId {get;set;} 
        public String changeDate {get;set;} 
    }
    
    public class Reviews {
        public String referenceId {get;set;} 
        public String referralEmail {get;set;} 
        public List<Links> links {get;set;} 
        public String text {get;set;} 
        public String updatedAt {get;set;} 
        public Integer numberOfLikes {get;set;} 
        public String id {get;set;} 
        public String createdAt {get;set;} 
        public String title {get;set;} 
        public Boolean countsTowardsLocationTrustScore {get;set;} 
        public FindReviewer findReviewer {get;set;} 
        public String source {get;set;} 
        public Location location {get;set;} 
        public Integer stars {get;set;} 
        public Boolean isVerified {get;set;} 
        public String status {get;set;} 
        public List<Tags> tags {get;set;} 
        public BusinessUnit businessUnit {get;set;} 
        public List<BusinessUnitHistory> businessUnitHistory {get;set;} 
        public String reviewVerificationLevel {get;set;} 
        public CompanyReply companyReply {get;set;} 
        public List<Object> complianceLabels {get;set;} 
        public ReportData reportData {get;set;} 
        public String language {get;set;} 
        public Boolean countsTowardsTrustScore {get;set;} 
        public String experiencedAt {get;set;} 
        public Invitation invitation {get;set;} 
        public Consumer consumer {get;set;} 
    }
    
    public class Consumer {
        public String displayLocation {get;set;} 
        public Integer numberOfReviews {get;set;} 
        public String displayName {get;set;} 
        public String id {get;set;} 
        public List<Links> links {get;set;} 
    }
    
    public class BusinessUnit {
        public String identifyingName {get;set;} 
        public String displayName {get;set;} 
        public String id {get;set;} 
        public List<Links> links {get;set;} 
    }
    
    public class ReportData {
        public List<Object> reasons {get;set;} 
        public String source {get;set;} 
        public String publicComment {get;set;} 
        public String createdAt {get;set;} 
    }
    
    public class Links {
        public String href {get;set;} 
        public String method {get;set;} 
        public String rel {get;set;} 
    }
    
    public class ConsumerResponse {
        public String referenceId {get;set;} 
        public String name {get;set;} 
        public String submittedAt {get;set;} 
        public String phoneNumber {get;set;} 
        public String address {get;set;} 
        public String message {get;set;} 
        public String email {get;set;} 
    }
    
    public class Tags {
        public String group_Z {get;set;} // in json: group
        public String value {get;set;} 
    }
    
    public class Location {
        public String externalId {get;set;} 
        public String urlFormattedName {get;set;} 
        public String id {get;set;} 
        public String name {get;set;} 
    }
}