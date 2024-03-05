//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_AsyncObfuscateFSLDatas 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/01/2019
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_AsyncObfuscateFSLDatas implements Queueable {
    public List<User> userList;
    public Map<Id, Datetime> dateDesacByUser;
    
    /**
    * @description Constructeur
    * @param contratsId Liste des Ids des users
    * @param dateDesacByUser Map contenant les dates de désactivation des utilisateurs (pour sauvegarde et transmission à QA_AsyncObfuscateUser)
    * @return QA_AsyncObfuscateFSLDatas Classe QA_AsyncObfuscateFSLDatas
    */
    public QA_AsyncObfuscateFSLDatas(List<User> userList, Map<Id, Datetime> dateDesacByUser) {
        this.userList= userList;
        this.dateDesacByUser = dateDesacByUser;
    }
    
    /**
    * @description Fonction principal d'exécution du batch Queueable
    * Méthode asynchrone anonymiser les ressources de service de FSL lorsqu'un utilisateur est anonymiser
    * @param context Context du batch
    */
    public void execute(QueueableContext context) {
        system.debug('### DEBUT QA_AsyncObfuscateFSLDatas');   
        
        // Mise à jour de la ressource de service
        List<ServiceResource> serviceResourceList = [SELECT Id, Name, fsl_SGID__c, fsl_matriculeGC__c, FSL__GanttLabel__c, fsl_metier__c, fsl_type__c FROM ServiceResource 
                                                        WHERE RelatedRecordId IN :userList OR fsl_techUtilisateurRattache__c IN :userList];
        system.debug('## serviceResourceList: '+serviceResourceList);
        for(ServiceResource service : serviceResourceList) {
            // Génération alétoire d'un text (les champs doivent être unique)
            Blob blobKey = crypto.generateAesKey(192);
            String name = EncodingUtil.convertToHex(blobKey);
            service.Name = name.substring(0,25);
            service.fsl_matriculeGC__c = name.substring(0,25);
            service.fsl_SGID__c = name.substring(0,25);
            service.FSL__GanttLabel__c = '';
            service.fsl_metier__c = '';
            service.fsl_type__c = '';
        }
        if(!serviceResourceList.isEmpty())
            update serviceResourceList;  
            
        // Suppression des compétences et des territoires
        List<ServiceResourceSkill> serviceResList = [SELECT Id FROM ServiceResourceSkill WHERE ServiceResourceId IN :serviceResourceList];
        List<ServiceTerritoryMember> serviceTerritoryList = [SELECT Id FROM ServiceTerritoryMember WHERE ServiceResourceId IN :serviceResourceList];

        system.debug('## serviceRessList: '+serviceResList);
        system.debug('## serviceTerritoryList: '+serviceTerritoryList);
        if(!serviceResList.isEmpty())
            delete serviceResList;
        if(!serviceTerritoryList.isEmpty())
            delete serviceTerritoryList;        
        
        // Désactivation et Anonymisation du champ email et des champs standard
        system.debug('## Call QA_AsyncObfuscateUser');
        if(!Test.isRunningTest()) //Ajout pour éviter erreur lors des tests (impossible de chainer les job Queuable)
            system.enqueueJob(new QA_AsyncObfuscateUser(userList , false, dateDesacByUser, false));
        
        system.debug('### FIN QA_AsyncObfuscateFSLDatas'); 
    }
}