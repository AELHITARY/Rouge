//-- *
//-- Fichier     : TR002_fsl_GenerateurRessource
//-- Modifié par : CGI - FSL
//-- Modifié le  : 09/04/2018
//-- Description : Classe appelée par TR001_fsl_GenerateurRessource - Création des users et attribution des autorisations
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --

public with sharing class TR002_fsl_GenerateurRessource  implements Queueable {
@testVisible
    private static Boolean doChainJob = true;
    
    List<User> userAssigneeList ;
    List<User> inUserAssigneeList ;
    Map<String, fsl_tech_generateurRessource__c> generatorMap;
    FieldServiceError generatedError ;

    public TR002_fsl_GenerateurRessource(List<User> userParam, Map<String, fsl_tech_generateurRessource__c>  generatorParam, FieldServiceError errorParam) {
        this.inUserAssigneeList = userParam;
        this.userAssigneeList = new List<User>();
        this.generatorMap = generatorParam.deepClone();
        this.generatedError = errorParam;
    }
    
    public void execute(QueueableContext context) {
        system.debug('################## Start - TR002_fsl_GenerateurRessource_assignationPermissionRessource');
        
        Map<String, List<ID>> mappingLicenseList = new  Map<String, List<ID>>();
        Map<String, List<ID>> mappingPermissionList = new  Map<String, List<ID>>();
        try{
            mappingLicenseList = FieldServiceUtils.loadFslAutorisationMap('License');
            mappingPermissionList = FieldServiceUtils.loadFslAutorisationMap('Permission');
        } catch (Exception e){
            system.debug('################## DEBUG - Erreur Chargement des permissions');
            String step = 'TR002_fsl_GenerateurRessource - Erreur Chargement des permissions';
            generatedError.addExeptionError(e,step);
        } 
        system.debug('################## Start - TR002 REsult : '+generatedError);

        if(inUserAssigneeList != null && inUserAssigneeList.size()> 0 ){
            // Etape 2 : Création / Modification des utilisateurs
            System.debug('################## DEBUG - User to upsert '+inUserAssigneeList);  
            generatedError.combineError(FieldServiceUtils.databaseAction('upsert','User',inUserAssigneeList));
            List<ID> userAssigneeIDList = FieldServiceUtils.getIdList(inUserAssigneeList) ; 
            
            System.debug('################## DEBUG TR002 After - User to upsert '+inUserAssigneeList);  
            System.debug('################## DEBUG After ID - User to upsert '+userAssigneeIDList); 

            // Etape 3 : Suppression des attributions de permission set/License pour les utilisateurs existants
            List<PermissionSetAssignment> permissionToDelete = [select Id from PermissionSetAssignment where PermissionSet.ProfileId = null and  assigneeId IN :userAssigneeIDList ];
            List<PermissionSetLicenseAssign > licenseToDelete = [select Id from PermissionSetLicenseAssign  where AssigneeId IN :userAssigneeIDList];
            if(permissionToDelete != null && permissionToDelete.size()> 0 ){
                System.debug('################## DEBUG - PermissionSetAssignment to delete '+permissionToDelete);                   
                generatedError.combineError(FieldServiceUtils.databaseAction('delete','PermissionSetAssignment',permissionToDelete));
            }
            if(licenseToDelete != null && licenseToDelete.size()> 0 ){
                System.debug('################## DEBUG - PermissionSetLicenseAssign to delete '+licenseToDelete);                   
                generatedError.combineError(FieldServiceUtils.databaseAction('delete','PermissionSetLicenseAssign',licenseToDelete));
            }
                
            // Etape 4 : Attribution des Licenses puis des permissions dans l'ordre                      
            List<PermissionSetAssignment> assignmentLicenseList = new List<PermissionSetAssignment>();    
            List<PermissionSetAssignment> assignmentPermissionList = new List<PermissionSetAssignment>();  
            try{
                for (User userAssignee : inUserAssigneeList ) { 
                    if (userAssignee.ID != null){
                        // Attribution des Licenses
                        for (ID LicenseId : mappingLicenseList.get(userAssignee.typePlanification__c)){
                            PermissionSetAssignment userLicense = new PermissionSetAssignment();
                            userLicense.assigneeId = userAssignee.id;                 
                            userLicense.permissionSetId = LicenseId;
                            assignmentLicenseList.add(userLicense);             
                        }
                        
                        // Attribution des permissions
                        for (ID permissionId : mappingPermissionList.get(userAssignee.typePlanification__c)){
                            PermissionSetAssignment userPermmissions = new PermissionSetAssignment(); 
                            userPermmissions.assigneeId = userAssignee.id;       
                            userPermmissions.permissionSetId = permissionId;               
                            assignmentPermissionList.add(userPermmissions);
                        }                        
                    }
                }
            } catch (Exception e){
                system.debug('################## DEBUG - Erreur Chargement des permissions');
                String subject = 'TR002_fsl_GenerateurRessource - Erreur Chargement des permissions';
                generatedError.addExeptionError(e,subject);
            } 
            
            System.debug('################## DEBUG - PermissionSetAssignment to insert '+assignmentPermissionList);                 
            System.debug('################## DEBUG - PermissionSetAssignmentLicense to insert '+assignmentLicenseList);               
            generatedError.combineError(FieldServiceUtils.databaseAction('insert','PermissionSetAssignment',assignmentPermissionList));
            generatedError.combineError(FieldServiceUtils.databaseAction('insert','PermissionSetAssignment',assignmentLicenseList));
            
            // Exclusion des User non crées/modifiés et suivi de la génération des ressources
            assignmentPermissionList.addAll(assignmentLicenseList);
            Map<Id, String> permissionMap = FieldServiceUtils.getMapByUserId(assignmentPermissionList);
            for(User u : inUserAssigneeList){
                if (u.ID != null){
                    userAssigneeList.add(u);
                    fsl_tech_generateurRessource__c generator = this.generatorMap.get(u.matriculeGC__c);
                    generator.fsl_upsertUserID__c = u.Id;
                    if(permissionMap.containsKey(u.Id))
                        generator.fsl_insertPermissionID__c = permissionMap.get(u.Id);
                    this.generatorMap.put(u.matriculeGC__c,generator);  
                }                   
            }           
            
            // Etape 5 : Création des ressources associées
             if(doChainJob) 
           ID jobID = System.enqueueJob(new TR003_fsl_GenerateurRessource(userAssigneeList, generatorMap, generatedError));
        }          
        system.debug('################## End - TR002_fsl_GenerateurRessource');
    }
}