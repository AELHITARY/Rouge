//-- *
//-- Fichier     : TR004_fsl_GenerateurRessource  
//-- Modifié par : CGI - FSL
//-- Modifié le  : 13/04/2018
//-- Description : Classe appelée par TR003_fsl_GenerateurRessource - Ajout des utilisateurs dans le public Group correspondant au dépôt de rattachament
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR004_fsl_GenerateurRessource implements Queueable {
@testVisible
    private static Boolean doChainJob = true;
    
    List<User> userAssigneeList;
    Map<String, fsl_tech_generateurRessource__c> generatorMap;
    Map<String,String> profondeurMap =  FieldServiceUtils.getProfondeurMap();
    List<GroupMember > grpMemberToCreateList ;
    FieldServiceError generatedError ;
    List<FSL__User_Territory__c> userTerritoryToCreateList;
    
    public TR004_fsl_GenerateurRessource(List<User> userParam, Map<String, fsl_tech_generateurRessource__c> generatorParam, List<GroupMember > grpMemberParam, FieldServiceError errorParam, List<FSL__User_Territory__c> userTerritoryParam) {
        this.userAssigneeList = userParam;
        this.generatorMap = generatorParam.deepClone();
        this.grpMemberToCreateList = grpMemberParam;
        this.generatedError = errorParam;
        this.userTerritoryToCreateList = userTerritoryParam;
    }
    
    public void execute(QueueableContext context) {
        system.debug('################## Start - TR004_fsl_GenerateurRessource  '); 

        fsl_tech_generateurRessource__c generator = new fsl_tech_generateurRessource__c();
        try{
            // Etape 10 : Suppression des membres de groupe rattachés
            Set<Id> userIds = (new Map<Id,USer>(userAssigneeList)).keySet();
            List<GroupMember> grpMemberToDelete = [select Id from GroupMember  where UserOrGroupId IN :userIds];
            System.debug('################## DEBUG - GroupMember to delete '+grpMemberToDelete);                 
            if(grpMemberToDelete != null && grpMemberToDelete.size()> 0 )
                generatedError.combineError(FieldServiceUtils.databaseAction('delete','GroupMember',grpMemberToDelete));
            
            // Etape 11 : Création des membres de groupe rattachés
            System.debug('################## DEBUG - GroupMember to create '+grpMemberToDelete);            
            if(grpMemberToCreateList != null && grpMemberToCreateList.size()> 0 )
               generatedError.combineError(FieldServiceUtils.databaseAction('insert','GroupMember',grpMemberToCreateList));
    
            Map<Id, GroupMember> mapGroupMember = FieldServiceUtils.getMapGroupByUserId(grpMemberToCreateList);
            for (User userAssignee : this.userAssigneeList){
                if (userAssignee.id != null && mapGroupMember.containsKey(userAssignee.id)){
                    generator = generatorMap.get(userAssignee.matriculeGC__c);
                    generator.fsl_insertGroupMemberID__c =  (mapGroupMember.get(userAssignee.id)).ID;
                    generatorMap.put(userAssignee.matriculeGC__c, generator);
                }
            }
        } catch (Exception e){
            system.debug('################## DEBUG - TR004_fsl_GenerateurRessource : '+e.getMessage());
                String step = 'TR003_fsl_GenerateurRessource - Gestion des membres de groupe';
                generatedError.addExeptionError(e,step);
        }
  
        // Etape 12 : Modification du Générateur de ressource 
         if(doChainJob) 
        ID jobID = System.enqueueJob(new TR005_fsl_GenerateurRessource(userAssigneeList, generatorMap, generatedError,userTerritoryToCreateList));

        system.debug('################## End - TR004_fsl_GenerateurRessource');
    } 
 }