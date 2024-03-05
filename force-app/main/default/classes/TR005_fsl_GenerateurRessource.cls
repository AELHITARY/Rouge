//-- *
//-- Fichier     : TR005_fsl_GenerateurRessource  
//-- Modifié par : CGI - FSL
//-- Modifié le  : 13/04/2018
//-- Description : Classe appelée par TR004_fsl_GenerateurRessource - Modification du Générateur de ressource pour tracer tous les ID des records créés/modifiés
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR005_fsl_GenerateurRessource implements Queueable {

    List<User> userAssigneeList;
    Map<String, fsl_tech_generateurRessource__c> generatorMap;
    FieldServiceError generatedError ;
    List<FSL__User_Territory__c> userTerritoryToCreateList;
    fsl_tech_generateurRessource__c generator = new fsl_tech_generateurRessource__c();
    GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.import.exception.email');   

    public TR005_fsl_GenerateurRessource(List<User> userParam, Map<String,fsl_tech_generateurRessource__c> generatorParam, FieldServiceError errorParam,List<FSL__User_Territory__c> userTerritoryParam ) {
        this.userAssigneeList = userParam;
		this.generatorMap = generatorParam;
        this.generatedError = errorParam;
        this.userTerritoryToCreateList = userTerritoryParam;
    }
    
    public void execute(QueueableContext context) {
        system.debug('################## Start - TR005_fsl_GenerateurRessource  '); 
        
        try{
             // Etape 9 : Création des utilisateurs de territoire rattachés
            if(userTerritoryToCreateList != null && userTerritoryToCreateList.size()> 0){
                System.debug('################## DEBUG - FSL__User_Territory__c to create '+userTerritoryToCreateList);
                generatedError.combineError(FieldServiceUtils.databaseAction('insert','FSL__User_Territory__c',userTerritoryToCreateList));
            }
            
            Map<Id, SObject> mapUser = FieldServiceUtils.getObjectMap (userAssigneeList);
            Map<Id, SObject> mapUserTerr = FieldServiceUtils.getObjectMap(userTerritoryToCreateList);
            for (FSL__User_Territory__c userAssignee : userTerritoryToCreateList){ 
                if (userAssignee.id != null && mapUserTerr.containsKey(userAssignee.id)){
                    system.debug('################## DEBUG - TR005_fsl_GenerateurRessource : '+((User) mapUser.get(userAssignee.FSL__User__c)).matriculeGC__c);
                    generator = generatorMap.get(((User) mapUser.get(userAssignee.FSL__User__c)).matriculeGC__c);
                    generator.fsl_insertUserTerritoryID__c =  userAssignee.id;
                    generatorMap.put(((User) mapUser.get(userAssignee.FSL__User__c)).matriculeGC__c,generator);
                }
            }
        } catch (Exception e){
            system.debug('################## DEBUG - TR005_fsl_GenerateurRessource : '+e.getMessage());
                String step = 'TR005_fsl_GenerateurRessource - Gestion des membres de groupe';
                generatedError.addExeptionError(e,step);
        }        
        // Modification du Générateur : Trace des ID créés/modifiés
        generatedError.combineError(FieldServiceUtils.databaseAction('update','fsl_tech_generateurRessource__c',generatorMap.values()));
        
        String emailSubject = 'Field Service Lightning - Liste des erreurs de génération des utilisateurs et ressources';
        FieldServiceUtils.serviceEmailAlertGenRess(emailSubject, generatedError, emailException);
        
        system.debug('################## End - TR005_fsl_GenerateurRessource');
    } 
 }