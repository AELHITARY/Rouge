//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_GeneratePipeline
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/01/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class BA_GeneratePipeline implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private static final String ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    global String serviceEntityId {get;set;}
    global Date generationDate {get;set;}
    global String docFormat {get;set;}
    global Boolean sendEmail {get;set;}

    /***** Constructor *****/
    global BA_GeneratePipeline(String serviceEntityId, Date generationDate, String docFormat, Boolean sendEmail) {
        this.serviceEntityId = serviceEntityId; 
        this.generationDate = generationDate;
        this.docFormat = docFormat;
        this.sendEmail = sendEmail;
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer l'entité
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('### DEBUT BA_GeneratePipeline : start');
        try {
            Database.QueryLocator results;

            // Si le paramètre d'entrée "serviceEntityId" est vide, on récupère tous les dépots migrés Kube3. 
            // Sinon on récupère que le dépot en entrée
            if(String.isBlank(this.serviceEntityId)) {
                results = Database.getQueryLocator([SELECT Id, Name FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID
                                                        AND entityType__r.KparKReference__c = 'DEP'
                                                        AND isActive__c = true
                                                        AND migratedToK3__c = true]);
            } else {
                results = Database.getQueryLocator([SELECT Id, Name FROM Account WHERE Id = :this.serviceEntityId]);
            }

            // Fin de l'init
            Database.QueryLocatorIterator it =  results.iterator();
            System.debug('### FIN BA_GeneratePipeline : start');     
            return results;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE : Erreur d\'initialisation du batch', e);
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Account> scope){
        System.debug('### DEBUT BA_GeneratePipeline : execute');
        System.debug('## scope (' + scope.size() +')');
        System.debug('## this.generationDate: '+this.generationDate);
        System.debug('## this.docFormat: '+this.docFormat);
        System.debug('## this.sendEmail: '+this.sendEmail);

        try {
            if(!scope.isEmpty()) {                
                // Appel à la méthode de génération pour chaque entité
                for(Account ent : scope) {
                    System.debug('## Generate for: '+ent.Id+' - '+ent.Name);
                    LWC_GlobalPipelineGeneratePDF.renderDocumentPDF(ent.Id, this.generationDate, null, this.docFormat);
                }
            }
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE : Erreur de génération du fichier ', e);
        }
        System.debug('### FIN BA_GeneratePipeline : execute');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        System.debug('### DEBUT BA_GeneratePipeline : finish');    
        try {
            // Mise à jour des stats
            System.debug('### FIN BA_GeneratePipeline : finish');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] PIPELINE : Erreur de génération du fichier', e);
        }
    }
}