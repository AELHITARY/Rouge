//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_PlatformEvent 
//-- Auteur      : CGI
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/11/2022
//-- Version     : 1.1
//-- Description : Créer/Modifier/Supprimer les WorkOrder via Platform Event
//-- --------------------------------------------------------------------------------- --
public without sharing class TR001_fsl_PlatformEvent {    
    private static final String RT_WORK_ORDER_FSL = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email');
    private static final GlobalProperties__c emailCheck = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.check.email');

    /**
    * @description Créer / mettre à jour la demande de rendez-vous
    * @param listeDemandesRDV Trigger.new
    */
    public static void addOrUpdateWOs(List<DemandeRDV__e> listeDemandesRDV){   
        List<WorkOrder> newWOs=new List<WorkOrder>();         
        //construire les Sets des IDs externes       
        Set<string> setParentWorkOrder = new Set<string>();
        Set<string> setAccount = new Set<string>();
        Set<string> setContrat = new Set<string>();
        Set<string> setWorkType = new Set<string>();
        Set<string> setServiceTerritory = new Set<string>();        
        
        for (DemandeRDV__e event : listeDemandesRDV) {              
            if (event.fsl_parentWorkOrderExternal__c!=null)
                setParentWorkOrder.add(event.fsl_parentWorkOrderExternal__c);            
            if(event.fsl_accountExternal__c!=null)
                setAccount.add(event.fsl_accountExternal__c);           
            if(event.fsl_contratKExternal__c!=null)
                setContrat.add(event.fsl_contratKExternal__c);           
            if(event.fsl_workTypeExternal__c!=null)
                setWorkType.add(event.fsl_workTypeExternal__c);            
            if (event.fsl_serviceTerritoryExternal__c!=null)
                setServiceTerritory.add(event.fsl_serviceTerritoryExternal__c); 
            
            System.debug('**SET PARENT '+setParentWorkOrder+' - SET ACCOUNT '+ setAccount+' - SET CONTRAT '+ setContrat+' - SET WORKTYPE '+ setWorkType+' - SET TERRITOIRE '+ setServiceTerritory+' **');
        }    
        
        //construire des maps par ID externe     
        Map<String, ID> mapParentWorkOrderIDbyExternalId = FieldServiceUtils.createMapParentWorkOrder(setParentWorkOrder); 
        Map<String, Account> mapAccountIDbyExternalId = FieldServiceUtils.createMapAccount(setAccount); 
        Map<String, Set<ID>> mapChantierIDbyAccountId = FieldServiceUtils.createMapChantier(mapAccountIDbyExternalId); 
        Map<String, KContrat__c> mapContratIDbyExternalId = FieldServiceUtils.createMapContrat(setContrat); 
        Map<String, ID> mapWorkTypeIDbyExternalId = FieldServiceUtils.createMapWorkType(setWorkType); 
        Map<String, ID> mapServiceTerritoryIDbyExternalId = FieldServiceUtils.createMapServiceTerritory(setServiceTerritory); 
        
        for (DemandeRDV__e event : listeDemandesRDV) {  
            FieldServiceUtils.serviceEmailAlert(null,null,'Création de la demande de rendez-vous',event,null,emailCheck);
            WorkOrder newWO = new WorkOrder();  
             
            try{             
                if(event.fsl_externalId__c!=null){
                    newWO.fsl_externalId__c = event.fsl_externalId__c;
                } else{
                    throw new FieldServiceException('L\'external Id de la demande n\'est pas renseigné');    
                }                
                
                // Récupération de la demande parent
                if (mapParentWorkOrderIDbyExternalId.containsKey(event.fsl_parentWorkOrderExternal__c)){
                    newWO.ParentWorkOrderId = mapParentWorkOrderIDbyExternalId.get(event.fsl_parentWorkOrderExternal__c);
                } else if(event.fsl_parentWorkOrderExternal__c != null){
                    throw new FieldServiceException('La demande parent '+event.fsl_parentWorkOrderExternal__c+' n\'est pas référencé'); 
                }
                
                // Récupération du compte
                Account acc = mapAccountIDbyExternalId.get(event.fsl_accountExternal__c); 
                if (acc != null){
                    newWO.AccountId = acc.Id;
                } else if (event.fsl_accountExternal__c == null || acc == null){
                    newWO.AccountId = null;
            	}
                /*else if ((event.fsl_contratKExternal__c != null && !mapContratIDbyExternalId.containsKey(event.fsl_contratKExternal__c)) || (event.fsl_accountExternal__c != null && event.fsl_contratKExternal__c == null)){
                    // Notification d'erreurs si compte non référencé pour créer un nouveau contrat   
                    throw new FieldServiceException('Le compte '+event.fsl_accountExternal__c+' n\'est pas référencé'); 
                }*/
                
                // Récupération du contrat       
                KContrat__c contrat = mapContratIDbyExternalId.get(event.fsl_contratKExternal__c);            
                if (contrat != null){
                    newWO.ContratK__c = contrat.Id; 
                    // Alimentation du compte selon le contrat si non trouvé précédemment
                    if (String.isBlank(newWO.AccountId)){
                        newWO.AccountId = contrat.compte__c;
                    }
                } else if (event.fsl_contratKExternal__c == null || contrat == null){
                    newWO.ContratK__c = null;
            	}
                /*else if (event.fsl_contratKExternal__c != null && mapAccountIDbyExternalId.containsKey(event.fsl_accountExternal__c)){
                    // Création d'un ContratK  s'il n'existe pas
                    KContrat__c contratToInsert = new KContrat__c();
                    contratToInsert.numeroContrat__c = event.fsl_contratKExternal__c;                        
                    contratToInsert.Name = mapAccountIDbyExternalId.get(event.fsl_accountExternal__c).name;
                    contratToInsert.compte__c = newWO.accountId;
                    if (mapChantierIDbyAccountId.containsKey(event.fsl_accountExternal__c) && (mapChantierIDbyAccountId.get(event.fsl_accountExternal__c)).size() == 1){
                        Set<ID> chantierListId = new Set<ID>(mapChantierIDbyAccountId.get(event.fsl_accountExternal__c));
                        contratToInsert.chantier__c = new List<ID> (chantierListId).get(0);
                    }
                    
                    Database.SaveResult sr = Database.insert(contratToInsert,false);
                    if (!sr.isSuccess()) {        
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('**Insert Contrat Failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                            String subject = 'Erreur de création de contrat '+event.fsl_contratKExternal__c+ ' via Platform Event';  
                            FieldServiceUtils.serviceEmailAlert(null,err,subject,event,null,emailException); 
                        } 
                    }
                    newWO.ContratK__c = contratToInsert.id ; 
                }*/
                
                // Récupération du type d'activité
                if (mapWorkTypeIDbyExternalId.containsKey(event.fsl_workTypeExternal__c)){
                    newWO.WorkTypeId = mapWorkTypeIDbyExternalId.get(event.fsl_workTypeExternal__c);
                }else{
                    throw new FieldServiceException('Le type d\'activité '+event.fsl_workTypeExternal__c+' n\'est pas référencé');  
                }
                
                // Récupération du territoire
                if (mapServiceTerritoryIDbyExternalId.containsKey(event.fsl_serviceTerritoryExternal__c)){
                    newWO.ServiceTerritoryId = mapServiceTerritoryIDbyExternalId.get(event.fsl_serviceTerritoryExternal__c);   
                }else{
                    throw new FieldServiceException('Le territoire '+event.fsl_serviceTerritoryExternal__c+' n\'est pas référencé');
                }
                
                // Au plus tôt non renseignée
                if (event.fsl_startDate__c != null){
                    newWO.StartDate = FieldServiceUtils.conversionStringDate(event.fsl_startDate__c,event,emailException);
                    if(event.fsl_endDate__c != null)
                        newWO.EndDate = FieldServiceUtils.conversionStringDate(event.fsl_endDate__c,event,emailException);
                }else {
                    if(event.fsl_endDate__c!= null ){
                        newWO.StartDate = System.now();
                        DateTime auPlusTard = FieldServiceUtils.conversionStringDate(event.fsl_endDate__c,event,emailException);
                        System.debug('**auPlusTard :'+auPlusTard);
                        if(auPlusTard < System.now()){
                            System.debug('** date dans le passé');                           
                            newWO.EndDate = System.now().addDays(1);
                            newWO.fsl_techUrgence__c = true;
                        }else{
                            newWO.EndDate = auPlusTard;
                        }
                    } 
                }
                newWO.RecordTypeId = RT_WORK_ORDER_FSL;
                newWO.Duration = event.fsl_duration__c;
                newWO.DurationType = event.fsl_durationType__c;
                newWO.fsl_nombreIntervenants__c = event.fsl_nombreIntervenants__c;
                newWO.fsl_chiffreAffaire__c = event.fsl_chiffreAffaire__c;
                newWO.fsl_montantAttendu__c = event.fsl_montantAttendu__c; 
                newWO.fsl_documentsAttendus__c = event.fsl_documentsAttendus__c;
                newWO.fsl_MontantContrat__c = event.fsl_MontantContrat__c;
                newWO.fsl_SoldeClient__c = event.fsl_SoldeClient__c;
                newWO.Subject = event.fsl_subject__c; 
                newWO.Priority = event.fsl_priority__c;  
                newWO.Street =event.fsl_street__c;
                if(event.fsl_postalCode__c.length() == 4){
                    newWO.PostalCode = '0' + event.fsl_postalCode__c;
                }
                else{
                    newWO.PostalCode = event.fsl_postalCode__c;
                }
                newWO.City = event.fsl_city__c;
                newWO.State = event.fsl_state__c;
                newWO.Country = event.fsl_country__c;
                if(event.fsl_homephone__c != null && event.fsl_homephone__c != 0){
                    //newWO.fsl_homephone__c = '0' + (event.fsl_homephone__c).format();
                    String tel = String.valueOf(event.fsl_homephone__c).leftPad(10, '0');
   					newWO.fsl_homephone__c = tel.subString(0, 2) + ' ' + tel.subString(2, 4) + ' ' + tel.subString(4, 6) + ' ' + tel.subString(6, 8) + ' ' + tel.subString(8, 10);
				} 
                else newWO.fsl_homephone__c = null;

                if(event.fsl_mobilephone__c != null && event.fsl_mobilephone__c != 0){
                	//newWO.fsl_mobilephone__c = '0' + (event.fsl_mobilephone__c).format();
                	String tel = String.valueOf(event.fsl_mobilephone__c).leftPad(10, '0');
   					newWO.fsl_mobilephone__c = tel.subString(0, 2) + ' ' + tel.subString(2, 4) + ' ' + tel.subString(4, 6) + ' ' + tel.subString(6, 8) + ' ' + tel.subString(8, 10);
				} 
                else newWO.fsl_mobilephone__c = null;               
                
                System.debug('**newWO**'+newWO);
                newWOs.add(newWO);                
            } catch (Exception e) {
                System.debug('**upsert WorkOrder failed**'+e.getMessage());                
                //Envoyer des erreurs au responsable par email    
                String subject = 'Erreur de création/modification de WorkOrder '+event.fsl_externalId__c+ ' via Platform Event';  
                FieldServiceUtils.serviceEmailAlert(e,null,subject,event,null,emailException);   
            }            
        }
        
        if(newWOs.size()>0){
            try {     
                Integer counter = 0;
                //Insert Workorder s'il n'existe pas dans Salesforce, update WorkOrder s'il existe déjà.
                Database.UpsertResult[] srList = Database.upsert(newWOs,WorkOrder.Fields.fsl_externalId__c,false);
                for (Database.UpsertResult sr : srList) {
                    if (!sr.isSuccess()) {                                       
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('**Upsert WorkOrder Failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                            String subject = 'Erreur de création/modification de WorkOrder via Platform Event';  
                            FieldServiceUtils.serviceEmailAlert(null,err,subject,listeDemandesRDV[0],null,emailException); 
                        }
                    }else{
                        counter = counter +1;
                    }
                }
                System.debug('counterWO:'+counter+''+newWOs.size());
                //Inserer ou mettre à jour skill requirement et les preference resource
                if(counter == newWOs.size() ){
                   	addOrUpdateSkillRequirement(listeDemandesRDV,newWOs); 
                	addOrUpdateResourcePreference(listeDemandesRDV,newWOs);  
                }
                
            } catch (Exception e) {
                System.debug('**upsert WorkOrder failed**'+e.getMessage());                
                //Envoyer des erreurs au responsable par email    
                FieldServiceUtils.serviceEmailAlert(e,null,'Erreur de création/modification de WorkOrder via Platform Event',listeDemandesRDV[0],null,emailException);   
            }   
        }
    }

    /**
    * @description Ajouter les compétences requises pour la demande de rendez-vous
    * @param listeDemandesRDV Trigger.new
    * @param listeWorkorders Liste des nouveaux WO
    */
    public static void addOrUpdateSkillRequirement(List<DemandeRDV__e> listeDemandesRDV,List<WorkOrder> listeWorkorders ){

        try {  
            //Construire le Map de WorkOrderID par externalID
            Map<String, ID> mapWorkOrderIDbyExternalId = FieldServiceUtils.createMapWorkOrderIDbyExternalId(listeWorkorders);
            //Construire le Map de SkillID par SkillName         
            Map<String, ID> mapSkillIdByName = FieldServiceUtils.createMapSkillIdByName(listeDemandesRDV);
            
            List<SkillRequirement> newListeSRs= new List<skillrequirement>();        
            for (DemandeRDV__e event : listeDemandesRDV) {  
                if (event.fsl_skillExternal__c != null){
                    //construire le Map de SkillLevel par SkillName pour chaque Workorder
                    Map<String,String> mapSkillLevelByName = new Map<String,String>();
                    List<String> skills= new List<String>();                 
                    skills = event.fsl_skillExternal__c.split(';');                   
                    for(integer i=0; i < skills.size(); i++) {   
                        String skillname = skills[i].substringBefore(':');
                        String skilllevel = skills[i].substringAfter(':');                    
                        mapSkillLevelByName.put(skillname, skilllevel);                    
                    } 
                    //créer la liste de SkillRequirement à ajouter               
                    for (string skill:mapSkillLevelByName.keySet()) {   
                        skillrequirement sr = new skillrequirement();
                        sr.RelatedRecordId= mapWorkOrderIDbyExternalId.get(event.fsl_externalId__c);
                        if(mapSkillIdByName.containsKey(skill)){
                            sr.SkillId=mapSkillIdByName.get(skill);                            
                            sr.SkillLevel=decimal.valueOf(mapSkillLevelByName.get(skill));
                            newListeSRs.add(sr);
                        }else{
                            throw new FieldServiceException('La compétence '+skill+' n\'est pas référencée');
                        }                                    
                    }     
                }
            }
            //créer la liste des SkillRequiments à mettre à jour
            List<String> listeRelatedRecordId = mapWorkOrderIDbyExternalId.values();
            Set<String> setWorkTypeId= new Set<String>();
            for(Workorder wo: listeWorkorders){
                setWorkTypeId.add(wo.WorkTypeId);   
            }
            //Skill par défaut lié à WorkType 
            List<SkillRequirement> skillsForWorkType=[SELECT SkillId FROM SkillRequirement WHERE RelatedRecordId IN : setWorkTypeId ];
            Set<String> setSkillId= new Set<String>();
            for(SkillRequirement sr: skillsForWorkType){
                setSkillId.add(sr.SkillId);
            }
            
            List<skillrequirement> oldListeSRs = [SELECT Id FROM SkillRequirement WHERE RelatedRecordId IN :listeRelatedRecordId and SkillId NOT IN :setSkillId];
            for (String idSkill : setSkillId ){
                for(Integer i = 0; i < newListeSRs.size(); i++){
                    if(newListeSRs.get(i).SkillId == idSkill)
                        newListeSRs.remove(i);        
                }
            }        
            System.debug('**Old Skill'+oldListeSRs);
            System.debug('**New Skill'+newListeSRs);
            
            Database.DeleteResult[] srDeleteList = new Database.DeleteResult[]{};
                Database.SaveResult[] srInsertList = new Database.SaveResult[]{};
                    //supprimer les anciens SkillRequirements et insérer les nouveaux SkillRequirements
                    if(newListeSRs.size()>0){   
                        if (oldListeSRs.size()>0){                         
                            srDeleteList = Database.delete(oldListeSRs,false); 
                            srInsertList = Database.insert(newListeSRs,false); 
                        }else{
                            srInsertList = Database.insert(newListeSRs,false); 
                        }
                    }
            
            for (Database.DeleteResult sr : srDeleteList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Delete SkillRequirement failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de modification de SkillRequirements via Platform Event',listeDemandesRDV[0],null,emailException);  
                        
                    }
                }
            }
            for (Database.SaveResult sr : srInsertList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Insert SkillRequirement failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de création de SkillRequirements via Platform Event',listeDemandesRDV[0],null,emailException);  
                        
                    }
                }
            }
        } catch (Exception e) {
            System.debug('**insert SkillRequirements failed**'+e.getMessage());
            //Envoyer des erreurs au responsable par email   
            FieldServiceUtils.serviceEmailAlert(e,null,'Erreur de création de SkillRequirements via Platform Event',listeDemandesRDV[0],null,emailException);  
        } 
    } 
        
    /**
    * @description Ajouter les préferences ressources pour la demande de rendez-vous
    * @param listeDemandesRDV Trigger.new
    * @param listeWorkorders Liste des nouveaux WO
    */
    public static void addOrUpdateResourcePreference(List<DemandeRDV__e> listeDemandesRDV,List<WorkOrder> listeWorkorders ){

        try {  
            //Construire le Map de WorkOrderID par externalID
            Map<String, ID> mapWorkOrderIDbyExternalId = FieldServiceUtils.createMapWorkOrderIDbyExternalId(listeWorkorders);
            //Construire le Map de ResourceID par ResourceName         
            Map<String, ID> mapResourceIdByMatricule = FieldServiceUtils.createMapResourceIdByMatricule(listeDemandesRDV);
            
            List<ResourcePreference> newListeSRes= new List<ResourcePreference>();
            
            for (DemandeRDV__e event : listeDemandesRDV) {
                //construire le Map de ServiceResource par Matricule pour chaque Workorder
                Map<String,String> mapPrefByMatricule = new Map<String,String>();
                
             	if (event.fsl_RessourcesObligatoires__c != null){
                    List<String> resourcesObligatoires= new List<String>();
                    resourcesObligatoires = event.fsl_RessourcesObligatoires__c.split(';'); 
                    
                    for(integer i=0; i < resourcesObligatoires.size(); i++) {    
                        String resourcematricule = resourcesObligatoires[i].substringBefore(':');
                        String resourcepref = 'Required';                    
                        mapPrefByMatricule.put(resourcematricule, resourcepref);                    
                    } 
                
              		if (event.fsl_RessourcesRecommandees__c != null){  
                  		List<String> resourcesRecommandees= new List<String>(); 
                  		resourcesRecommandees = event.fsl_RessourcesRecommandees__c.split(';');
                      
                   		for(integer i=0; i < resourcesRecommandees.size(); i++) {    
                        	String resourcematricule = resourcesRecommandees[i].substringBefore(':');
                        	String resourcepref = 'Preferred';                    
                        	mapPrefByMatricule.put(resourcematricule, resourcepref);                    
                    	}
               			if (event.fsl_RessourcesInterdites__c != null){
                    		List<String> resourcesInterdites= new List<String>(); 
                  			resourcesInterdites = event.fsl_RessourcesInterdites__c.split(';');
                        
                    		for(integer i=0; i < resourcesInterdites.size(); i++) {    
                        		String resourcematricule = resourcesInterdites[i].substringBefore(':');
                        		String resourcepref = 'Excluded';                    
                        		mapPrefByMatricule.put(resourcematricule, resourcepref);                    
                   			}
                        }
                    }
              	
                    //créer la liste de PreferenceResource à ajouter               
                    for (string resource:mapPrefByMatricule.keySet()) {   
                        resourcepreference pres = new resourcepreference();
                        pres.RelatedRecordId= mapWorkOrderIDbyExternalId.get(event.fsl_externalId__c);
                        if(mapResourceIdByMatricule.containsKey(resource)){
                            pres.ServiceResourceId=mapResourceIdByMatricule.get(resource);                            
                            pres.PreferenceType=mapPrefByMatricule.get(resource);
                            newListeSRes.add(pres);
                        }else{
                            throw new FieldServiceException('La ressource '+resource+' n\'est pas référencée');
                        }                                    
                    } 
                }
            }
            //créer la liste des ResourcePreference à mettre à jour
			List<String> listeRelatedRecordId = mapWorkOrderIDbyExternalId.values();
            List<resourcepreference> oldListeSRes = [SELECT Id FROM ResourcePreference WHERE RelatedRecordId IN :listeRelatedRecordId];
                  
            System.debug('**Old Resource'+oldListeSRes);
            System.debug('**New Resource'+newListeSRes);
            
            Database.DeleteResult[] sresDeleteList = new Database.DeleteResult[]{};
            Database.SaveResult[] sresInsertList = new Database.SaveResult[]{};
                    //supprimer les anciens ResourcePreference et insérer les nouveaux ResourcePreference
                    if(newListeSRes.size()>0){   
                        if (oldListeSRes.size()>0){                         
                            sresDeleteList = Database.delete(oldListeSRes,false); 
                            sresInsertList = Database.insert(newListeSRes,false); 
                        }else{
                            sresInsertList = Database.insert(newListeSRes,false); 
                        }
                    }
            
            for (Database.DeleteResult sres : sresDeleteList) {
                if (!sres.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sres.getErrors()) {
                        System.debug('**Delete ServiceResource failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de modification de ServiceResource via Platform Event',listeDemandesRDV[0],null,emailException);  
                        
                    }
                }
            }
            for (Database.SaveResult sres : sresInsertList) {
                if (!sres.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sres.getErrors()) {
                        System.debug('**Insert ServiceResource failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de création de ServiceResource via Platform Event',listeDemandesRDV[0],null,emailException);  
                        
                    }
                }
            }
        }catch (Exception e) {
            System.debug('**insert ServiceResource failed**'+e.getMessage());
            //Envoyer des erreurs au responsable par email   
            FieldServiceUtils.serviceEmailAlert(e,null,'Erreur de création de ServiceResource via Platform Event',listeDemandesRDV[0],null,emailException);  
        } 
    }

    /**
    * @description Supprimer la demande de rendez-vous
    * @param listeSuppressionRDV Trigger.new
    */ 
    public static void deleteWOs(List<SuppressionRDV__e> listeSuppressionRDV){
        Set<string> woNums = new Set<string>();        
        for (SuppressionRDV__e event : listeSuppressionRDV) {         
            woNums.add(event.fsl_externalId__c);
        }
        List<WorkOrder> woASupprimer = [SELECT id FROM WorkOrder WHERE fsl_externalId__c IN :woNums] ;                    
        //supprimer les WorkOrder
        if(woASupprimer.size()>0)  { 
            Database.DeleteResult[] srDeleteList = Database.delete(woASupprimer,false);
            for (Database.DeleteResult sr : srDeleteList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Suppression WO failed**'+ err.getStatusCode() + '- ' + err.getFields() + ' : ' + err.getMessage());   
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de suppression de WorkOrder via Platform Event',null,listeSuppressionRDV[0],emailException) ; 
                        
                    }
                }
            }
        }            
    }   
}