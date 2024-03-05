//-- *
//-- Fichier     : TR003_fsl_GenerateurRessource  
//-- Modifié par : CGI - FSL
//-- Modifié le  : 09/04/2018
//-- Description : Classe appelée par TR002_fsl_GenerateurRessource - Création des ressources à partir des users puis assignation au dépôt principal
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR003_fsl_GenerateurRessource implements Queueable {
@testVisible
    private static Boolean doChainJob = true;
    
    List<User> userAssigneeList;
    Map<String, fsl_tech_generateurRessource__c> generatorMap;
    Map<String,String> profondeurMap =  FieldServiceUtils.getProfondeurMap();
    FieldServiceError generatedError ;
     
    public TR003_fsl_GenerateurRessource(List<User> userParam, Map<String, fsl_tech_generateurRessource__c>  generatorParam, FieldServiceError errorParam) {
        this.userAssigneeList = userParam;
        this.generatorMap = generatorParam.deepClone();
        this.generatedError = errorParam;
    }
    
    public void execute(QueueableContext context) {
        system.debug('################## Start - TR003_fsl_GenerateurRessource  '); 
        
        List<ServiceResource> resourceToCreateList = new List<ServiceResource>();  
        Map<ID, ServiceResource> resourceMap = new Map<ID, ServiceResource>() ;
        Map<String, User> userMap = new Map <String,User>();
        Map<String, ID> existingResourceMap = new Map<String, ID>();
        Map<String, ServiceTerritory> territoryMap = new Map <String,ServiceTerritory>();
        Map<String, ID> territoryGroupIdMap = new Map <String,ID>();
        fsl_tech_generateurRessource__c generator = new fsl_tech_generateurRessource__c();
        User userResource = new User();
        ServiceTerritory resourceTerritory = new ServiceTerritory();    
        List<ServiceTerritoryMember> memberToCreateList = new  List<ServiceTerritoryMember>();
        ServiceTerritoryMember  memberToCreate = new ServiceTerritoryMember ();
        List<FSL__User_Territory__c> userTerritoryToCreateList = new  List<FSL__User_Territory__c>(); 
        FSL__User_Territory__c  userTerritoryToCreate = new FSL__User_Territory__c ();  
        List<GroupMember > grpMemberToCreateList = new  List<GroupMember >(); 
        
        try{
            // Récupération des ressources existantes
            for(ServiceResource rs :[Select ID, fsl_matriculeGC__c from ServiceResource where fsl_matriculeGC__c IN :generatorMap.keySet()]){
                existingResourceMap.put(rs.fsl_matriculeGC__c, rs.ID) ;
            }
    
            // Récupération de la liste des territoires        
            for (ServiceTerritory str : [select id, KparKReference__c  from serviceTerritory Limit 1000]) {
                territoryMap.put(str.KparKReference__c, str );            
            }
            
            // Récupération de la liste des groupes par territoire     
            for (ServiceTerritoryShare strSh : [select UserOrGroupId, Parent.KparKReference__c from ServiceTerritoryShare where RowCause = 'Manual' and Parent.KparKReference__c IN :territoryMap.keySet()  Limit 1000]) {
                territoryGroupIdMap.put(strSh.Parent.KparKReference__c, strSh.UserOrGroupId );            
            }
        } catch (Exception e){
            system.debug('################## DEBUG - Erreur Chargement des référentiels'+e);
            String step = 'TR003_fsl_GenerateurRessource - Erreur Chargement des référentiels';
            generatedError.addExeptionError(e,step);
            return;
        }
                    system.debug('################## DEBUG - TR003 Ressource'+this.userAssigneeList.size());

        // Etape 5 : Création/Modification des ressources
        for (User userAssignee : this.userAssigneeList ) {
            try{
                if(userAssignee.typePlanification__c.contains('planifiable') && userAssignee.ID != null && !''.equals(generatorMap.get(userAssignee.matriculeGC__c).fsl_insertPermissionID__c)){
                    ServiceResource ressourceToCreate = new ServiceResource();
                    String nom = (userAssignee.FirstName != null && userAssignee.LastName != null ) ? (userAssignee.FirstName +' '+userAssignee.LastName).trim() : userAssignee.LastName ;
                    ressourceToCreate.Name = nom;
                    ressourceToCreate.FSL__GanttLabel__c = nom ;                
                    ressourceToCreate.fsl_matriculeGC__c = userAssignee.matriculeGC__c;
                    ressourceToCreate.job__c  = userAssignee.metier__c;
                    ressourceToCreate.fsl_SGID__c = userAssignee.sgid__c;
                    ressourceToCreate.IsActive = userAssignee.isActive;
                    ressourceToCreate.IsOptimizationCapable = true;
                    ressourceToCreate.RelatedRecordId = userAssignee.id;
                    ressourceToCreate.user__c = userAssignee.id;
                    ressourceToCreate.ResourceType = 'T';
                    
                    if (existingResourceMap.containsKey(ressourceToCreate.fsl_matriculeGC__c))
                        ressourceToCreate.ID = existingResourceMap.get(ressourceToCreate.fsl_matriculeGC__c);
    
                    resourceToCreateList.add(ressourceToCreate);
                }
            } catch (Exception e){
                system.debug('################## DEBUG - Erreur Conversion User en Ressource');
                String step = 'TR003_fsl_GenerateurRessource - Erreur Conversion User en Ressource';
                generatedError.addExeptionError(e,step);            
            }
             
            // Préparation des UserTerritory à créer
            if (territoryMap.containsKey(userAssignee.codeDepot__c)){
                userTerritoryToCreate = new FSL__User_Territory__c();
                userTerritoryToCreate.FSL__ServiceTerritory__c = territoryMap.get(userAssignee.codeDepot__c).id;
                userTerritoryToCreate.FSL__User__c = userAssignee.ID;
                userTerritoryToCreateList.add(userTerritoryToCreate);
            }
            else{
                system.debug('################## DEBUG - Erreur Rattachement de la ressource au dépôt (UserTerritory)');
                String message = 'Erreur Rattachement de la ressource au dépôt (UserTerritory)';
                Exception e = new FieldServiceException(message);
                String step = 'TR003_fsl_GenerateurRessource - '+message;
                generatedError.addExeptionError(e,step);
            } 
            
            // Préparation des ServiceTerritoryMember à créer               
            userMap.put(userAssignee.matriculeGC__c, userAssignee); 
            
            // Préparation des GroupMember à créer  
            GroupMember grpMemberToCreate = new  GroupMember(); 
            if(territoryGroupIdMap.containsKey(userAssignee.codeDepot__c)){
                grpMemberToCreate = new GroupMember();
                grpMemberToCreate.groupId = territoryGroupIdMap.get(userAssignee.codeDepot__c);
                grpMemberToCreate.UserOrGroupId = userAssignee.id;
                grpMemberToCreateList.add(grpMemberToCreate);
            }
            else{
                system.debug('################## DEBUG - Erreur Rattachement de l\'utilisateur au groupe ');
                String message = 'Erreur Rattachement de l\'utilisateur au groupe ';
                Exception e = new FieldServiceException(message);
                String step = 'TR003_fsl_GenerateurRessource - '+message;
                generatedError.addExeptionError(e,step);
            }
        }
        System.debug('################## DEBUG - ServiceResource to upsert '+resourceToCreateList);         
        generatedError.combineError(FieldServiceUtils.databaseAction('upsert','ServiceResource',resourceToCreateList));

        // Etape 6 : Suppression du rattachement des utilisateurs existants
        List<ServiceTerritoryMember> memberToDelete = [select Id from ServiceTerritoryMember where ServiceResource.fsl_matriculeGC__c IN :existingResourceMap.keySet() ];
        if(memberToDelete != null && memberToDelete.size()> 0 ){
            System.debug('################## DEBUG - ServiceTerritoryMember to delete '+memberToDelete);            
            generatedError.combineError(FieldServiceUtils.databaseAction('delete','ServiceTerritoryMember',memberToDelete));
        }
    
        // Etape 7 : Rattachement de la ressource au dépôt 
        for ( ServiceResource member : resourceToCreateList){
            generator = generatorMap.get(member.fsl_matriculeGC__c);
            userResource = userMap.get(member.fsl_matriculeGC__c);
            resourceTerritory = territoryMap.get(userResource.codeDepot__c);
            
            if (member.id != null && generator != null && userResource != null  && resourceTerritory != null ){
                memberToCreate = new ServiceTerritoryMember();
                memberToCreate.EffectiveStartDate = Date.parse(generator.fsl_dateEntreeDepot__c);
                if (generator.fsl_dateSortie__c != null)
                    memberToCreate.EffectiveEndDate  =  Date.parse(generator.fsl_dateSortieDepot__c);
                memberToCreate.ServiceResourceId  = member.id;                  
                memberToCreate.ServiceTerritoryId  = resourceTerritory.id;
                memberToCreate.TerritoryType = FieldServiceUtils.FSL_TERRITORY_PRIMARY;
                memberToCreateList.add(memberToCreate);                
            }
            else {
               system.debug('################## DEBUG - Erreur Rattachement de la ressource au dépôt ');
                String message = 'Erreur Rattachement de la ressource au dépôt';
                Exception e = new FieldServiceException(message);
                String step = 'TR003_fsl_GenerateurRessource - Erreur Rattachement de la ressource au dépôt';
                generatedError.addExeptionError(e,step);
            }
        }
        if(memberToCreateList != null && memberToCreateList.size()> 0 ){
            System.debug('################## DEBUG - ServiceTerritoryMember to create '+memberToCreateList);            
            generatedError.combineError(FieldServiceUtils.databaseAction('insert','ServiceTerritoryMember',memberToCreateList));
        }
        
        // Etape 8 : Suppression des utilisateurs de territoire rattachés
        List<FSL__User_Territory__c> userTerritoryToDelete = [select Id from FSL__User_Territory__c  where FSL__User__r.matriculeGC__c IN :userMap.keySet() ];
        if(userTerritoryToDelete != null && userTerritoryToDelete.size()> 0){
            System.debug('################## DEBUG - FSL__User_Territory__c to delete '+userTerritoryToDelete);
            generatedError.combineError(FieldServiceUtils.databaseAction('delete','FSL__User_Territory__c',userTerritoryToDelete));
        }
        
        // Etape 9 : Création des utilisateurs de territoire rattachés
        /*if(userTerritoryToCreateList != null && userTerritoryToCreateList.size()> 0){
            System.debug('################## DEBUG - FSL__User_Territory__c to create '+userTerritoryToCreateList);
            generatedError.combineError(FieldServiceUtils.databaseAction('insert','FSL__User_Territory__c',userTerritoryToCreateList));
        }*/
        
        // Etape intermédiaire : Stockage des résultats de création/modification dans le générateur de la ressource  
        for (ServiceResource res : resourceToCreateList){
            generator = generatorMap.get(res.fsl_matriculeGC__c);
            generator.fsl_upsertServiceResourceID__c = res.Id;
            generatorMap.put(res.fsl_matriculeGC__c,generator);
        }
        /*
        Map<Id, User> userMapID = FieldServiceUtils.getMapUserId(userAssigneeList);
        for (FSL__User_Territory__c userAssignee : userTerritoryToCreateList){ 
            if (userAssignee.id != null && userMapID.containsKey(userAssignee.id)){
                generator = generatorMap.get(userMapID.get(userAssignee.id).matriculeGC__c);
                generator.fsl_insertUserTerritoryID__c =  userAssignee.id;
                generatorMap.put(userAssignee.FSL__USer__r.matriculeGC__c,generator);
            }
        }*/
        Map<Id, SObject> mapResource = FieldServiceUtils.getObjectMap(resourceToCreateList);
        for (ServiceTerritoryMember mem : memberToCreateList){
            if (mem.ID != null && mapResource.containsKey(mem.ServiceResourceId)){
                generator = generatorMap.get(((ServiceResource) mapResource.get(mem.ServiceResourceId)).fsl_matriculeGC__c);
                generator.fsl_insertTerritoryMemberID__c =  mem.ID;
                generatorMap.put(((ServiceResource) mapResource.get(mem.ServiceResourceId)).fsl_matriculeGC__c,generator);
            }
        }
        
        // Etape 10 : Suppression des membres de groupe rattachés
         if(doChainJob) 
        ID jobID = System.enqueueJob(new TR004_fsl_GenerateurRessource(userAssigneeList, generatorMap,grpMemberToCreateList, generatedError,userTerritoryToCreateList ));

        system.debug('################## End - TR003_fsl_GenerateurRessource');
    } 
 }