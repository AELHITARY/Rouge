//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EinsteinPipelineCSV
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 28/10/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_EinsteinPipelineCSV implements Database.Batchable<sObject>, Database.Stateful {
    private static final String RT_CUSTOMER_ORDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    global BatchHistory__c batchHistoryStored {get;set;}
    global String finalCSVBody {get;set;}
    global String errorMessage {get;set;}
    global Integer errorCount {get;set;}
    global Integer yearNumber {get;set;}
    global Integer weekNumber {get;set;}
    global String attachmentFileName {get;set;}

    /***** Constructor *****/
    global BA_EinsteinPipelineCSV() {
        errorMessage = '';
        errorCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EinsteinPipelineCSV');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les commandes clients
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('### DEBUT BA_EinsteinPipelineCSV : start');
        try {
            Database.QueryLocator results;
            
            // Variable de date
            yearNumber = Date.today().year(); 
            Datetime dt = Datetime.newInstanceGmt(yearNumber, Date.today().month(), Date.today().day()); 
            weekNumber = Integer.valueOf(dt.formatGmt('w'));
            System.debug('## yearNumber: ' + yearNumber);
            System.debug('## weekNumber: ' + weekNumber);

            // Génération de l'entête 
            attachmentFileName = 'Pipeline ' + yearNumber + ' S'+ weekNumber +'.csv';
            System.debug('## attachmentFileName: ' + attachmentFileName);
            String header = 'Libelle_Secteur_Operationnel,yearnumber,Date Vente,filename,Libelle Region Commerciale Date Vente,Libelle Societe Commerciale Vendeur,Libelle_Region_Commerciale_Vendeur,';
            header+= 'Libelle Magasin,Libelle_Magasin_Vendeur,Libelle etat du contrat,Non-able Categorie Bucket,Non-able Vente Bucket,Non-able Total Bucket,';
            header+= 'Non-able Bucket,Libelle_Depot,No projet Kube,Numero Contrat,Date d\'Enregistrement Contrat,weeknumber,Libelle_Region_Operationnelle,Montant Contrat HT \n';
            finalCSVBody = header;

            // Récupération des commandes
            results = Database.getQueryLocator([SELECT Id, chantier__r.serviceEntity__r.Parent.Parent.Name, EffectiveDate, chantier__r.salesEntity__r.Parent.Parent.Name,
                                                    salesEntity__r.Name, OwnerId, Status, serviceEntity__r.Name, Opportunity.numeroProjet__c, OrderNumber,
                                                    chantier__r.serviceEntity__r.Parent.Name, amount__c, chantier__r.serviceEntity__c,
                                                    isLegacy__c, legacyReference__c, legacyStatus__c
                                            FROM Order WHERE RecordTypeId = :RT_CUSTOMER_ORDER
                                            AND legacyStatus__c NOT IN ('Soldé', 'Soldé NC', 'Totalement installé', 'En SAV depuis le', 'Résilié')]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EinsteinPipelineCSV : start');     
            return results;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE EINSTEIN : Erreur d\'initialisation du fichier CSV', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Order> scope){
        System.debug('### DEBUT BA_EinsteinPipelineCSV : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');

        try {
            List<String> ownersIdList = new List<String>();
            Map<String, User> ownersIdMap = new Map<String, User>();
            Integer successCount = 0;

            if(!scope.isEmpty()) {
                // Récupération des entités
                Map<String, Account> entityHierarchieMap = getEntityHierarchy();

                // Récupération des infos du propriétaire
                for(Order ord: scope) {
                    if(String.valueOf(ord.OwnerId.getSObjectType()) == 'User'){
                        ownersIdList.add(ord.OwnerId); 
                    }
                }
                if(!ownersIdList.isEmpty()) {
                    ownersIdMap = new Map<String, User>([SELECT Id, LibelleMagasin__c, LibelleDR__c FROM User WHERE Id IN :ownersIdList]);
                }

                // Génération du CSV 
                for(Order ord: scope) {
                    System.debug('## Commande: '+ord.Id);
                    User usrOwner = ownersIdMap.get(ord.OwnerId);
                    
                    // Récupération entité DS
                    Account serviceDS = calculateParentEntityByType(ord.chantier__r.serviceEntity__c, 'DS', entityHierarchieMap);
                    // Récupération entité DR
                    Account serviceDR = calculateParentEntityByType(ord.chantier__r.serviceEntity__c, 'DR', entityHierarchieMap);
                    
                    String record = transformNullValue(ord.chantier__r.serviceEntity__r.Parent.Name); //Libelle_Secteur_Operationnel
                    record+=','+ yearNumber; //yearnumber
                    record+=','+ ord.EffectiveDate.format(); //Date Vente
                    record+=','+ attachmentFileName; //filename
                    record+=','+ transformNullValue(ord.chantier__r.salesEntity__r.Parent.Parent.Name); //Libelle Region Commerciale Date Vente
                    record+=',KPARK'; //Libelle Societe Commerciale Vendeur
                    record+= (usrOwner != null) ? ','+transformNullValue(usrOwner.LibelleDR__c) : ','; //Libelle_Region_Commerciale_Vendeur
                    record+=','+ transformNullValue(ord.salesEntity__r.Name); //Libelle Magasin
                    record+= (usrOwner != null) ? ','+transformNullValue(usrOwner.LibelleMagasin__c) : ','; //Libelle_Magasin_Vendeur 
                    record+=','+ transformNullValue(ord.legacyStatus__c); //Libelle etat du contrat
                    record+=','; //Non-able Categorie Bucket
                    record+=','; //Non-able Vente Bucket
                    record+=','; //Non-able Total Bucket
                    record+=','; //Non-able Bucket
                    record+=','+ transformNullValue(ord.serviceEntity__r.Name); //Libelle_Depot = Depot
                    record+=','+ transformNullValue(ord.Opportunity.numeroProjet__c); //No projet Kube
                    if(ord.isLegacy__c) {
                        record+=','+ transformNullValue(ord.legacyReference__c); //Numero Contrat
                    } else {
                        record+=','+ transformNullValue(ord.OrderNumber); //Numero Contrat
                    }
                    record+=','+ ord.EffectiveDate.format(); //Date d'Enregistrement Contrat
                    record+=','+ weeknumber; //weeknumber
                    record+= (serviceDS != null) ? ','+transformNullValue(serviceDS.Name) : ','; //Libelle_Region_Operationnelle (= DS)
                    record+= (ord.amount__c != null) ? ','+ord.amount__c : ',';
                    record+='\n'; 

                    finalCSVBody += record;
                    successCount++;
                }
            }

            // MAJ Stats
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE EINSTEIN : Erreur de génération du fichier CSV', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN BA_EinsteinPipelineCSV : execute');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        System.debug('### DEBUT BA_EinsteinPipelineCSV : finish');    
        List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();          

        try {
            // Piece jointe
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            Blob csvBlob = Blob.valueOf(finalCSVBody);
            emailAttachment.setFileName(attachmentFileName);
            emailAttachment.setBody(csvBlob);

            // Création du document
            if(PropertiesUtils.getBooleanValue('einstein.csv.pipeline.createFile', false)) {
                createContentDocument(UserInfo.getOrganizationId(), attachmentFileName, csvBlob);
            }

            // Construction de l'email et envoi
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String emailSubject = 'Einstein PIPELINE : Fichier CSV '+ yearNumber + ' S'+ weekNumber;
            System.debug('## Email sujet: ' + emailSubject);
            email.setSubject(emailSubject);
            
            OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'support@kpark.fr'];
            email.setOrgWideEmailAddressId(fromAddress.Id);
            email.setSaveAsActivity(false);

            // Defini les destinataires
            String toAddressesString = PropertiesUtils.getStringValue('einstein.csv.pipeline.emailTo', 'cgest@kpark.fr');
            email.setToAddresses(toAddressesString.split(','));
            System.debug('## Email destinataires: ' + toAddressesString);
                                            
            // Genération du body
            email.setPlainTextBody('Envoi');
            email.setFileAttachments(new List<Messaging.EmailFileAttachment> { emailAttachment });
            // Ajout de l'email dans la liste d'envoi
            emailsToSent.add(email);

            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                System.debug('## Envoi de l\'email : ' + result);
            }

            // Mise à jour des stats
            batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EinsteinPipelineCSV : finish');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE EINSTEIN : Erreur de génération du fichier CSV', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction permettant de retourner une valeur vide si null
    * @param value Valeur
    * @return String Valeur vide
    */
    private static String transformNullValue(String value) {
        return (String.isBlank(value) ? '' : value);
    }

    /**
    * @description Méthode récurive permettant de vérifier l'entité parente ayant le type d'entité recherché
    * @param entityId Id de l'entité
    * @param entTypeToSearch Référence du type de l'entité à rechercher
    * @param entityHierarchieMap Objet contenant la hiéarchie des entités
    * @return Account Entité parente avec le type recherché, sinon null
    */
    public static Account calculateParentEntityByType(String entityId, String entTypeToSearch, Map<String, Account> entityHierarchieMap) {
        Account entity = entityHierarchieMap.get(entityId);
        System.debug('## Recherche par type entité: '+entTypeToSearch+' / '+entity); 
        if(entity != null && entity.entityType__r.KparKReference__c == entTypeToSearch) {
            System.debug('## Entité: '+entity);
            return entity;
        } else if(entity != null && String.isNotBlank(entity.ParentId)) {
            // Sinon on effectue une récursivité sur l'entité
            return calculateParentEntityByType(entity.ParentId, entTypeToSearch, entityHierarchieMap);
        } else {
            System.debug('## Pas d\'entité trouvé');
            return null;
        }
    }
    
    /**
    * @description Fonction permettant de créer une pièce jointe (ContentDocument) d'un document PDF et le lier à un enregistrement
    * @param recId Id de l'enregistrement pour le lien
    * @param fileName Nom du fichier
    * @param document Donnée binaire (BLOB) du document PDF
    * @return String Id de l'enregistrement ContentDocumentLink (lien)
    */
    private static String createContentDocument(String recId, String fileName, Blob document) {
        System.debug('### DEBUT BA_EinsteinPipelineCSV : createContentDocument');
        String result = null;

        try {
            // Création de l'objet ContentVersion et ContentDocument (automatiquement avec le ContentVersion)
            ContentVersion contVerFile = new ContentVersion();
            contVerFile.VersionData = document;
            contVerFile.Title = fileName; 
            contVerFile.PathOnClient=fileName;            
            contVerFile.ContentLocation= 'S'; // Indique que le doc est interne à Salesforce
                insert contVerFile;
            System.debug('## ContentVersion: '+contVerFile);
            
            // Récupération de l'ID de l'objet ContentDocument créé automatiquement lors du ContentVersion
            List<ContentVersion> contVerList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contVerFile.Id];
            if(contVerList.isEmpty()) {
                throw new KubeException('Pas de ContentVersion ayant pour Id : '+ contVerFile.Id); // Génère une erreur
            } else {
                String contentDocId = contVerList[0].ContentDocumentId;
                System.debug('## ContentDocumentId: '+contentDocId);
                // Création du lien (ContentDocumentLink)
                ContentDocumentLink cDe = new ContentDocumentLink();
                cDe.ContentDocumentId = contentDocId;
                cDe.LinkedEntityId = recId;
                cDe.ShareType = 'C';
                cDe.Visibility = 'AllUsers';
                insert cDe;
                System.debug('## ContentDocumentLink: ' + cDe);
                result = contentDocId;
            }
        } catch (Exception e) {
            System.debug('ERREUR # BA_EinsteinPipelineCSV.createContentDocument > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN BA_EinsteinPipelineCSV : createContentDocument');
        return result;
    }

    /**
    * @description Méthode permettant de construire la hiéarchie des entités
    * @return Map<String, Account> Retourne une map des entités : Key = Id entité, valeur = entité
    */
    public static Map<String, Account> getEntityHierarchy() {
        Map<String, Account> result = new Map<String, Account>();
        String rtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account acc : [SELECT Id, Name, ParentId, rue__c, codePostal__c, ville__c, departement__c, pays__c, Ownership, complementAdresse__c,
                                emailPro__c, Phone, SIRET__c, shareCapital__c, SIREN__c, RCSNumber__c, RCSCity__c, intracommunityVATNumber__c,
                                entityType__r.KparKReference__c, email__c, KparKReference__c 
                            FROM Account WHERE RecordTypeId = :rtId]) {
            result.put(acc.Id, acc);
        }
        return result;
    }
}