//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_AssignedResource
//-- Auteur      : CGI
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/06/2022
//-- Version     : 1.1
//-- Description : Modification/ Suppression d'une affectation de ressource à un rdv
//-- --------------------------------------------------------------------------------- --
public without sharing class TR001_fsl_AssignedResource {

    /**
    * @description Suppression des absences de type 'Renfort' rattachée à la ressource attribuée au rdv
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void supprimerAbsenceLiee(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        //Collecte des absences liées 
        Set<ID> ressourceIds = new Set<ID> ();
        for (AssignedResource assResource : (List<AssignedResource>)Trigger.old){         
            if(assResource.fsl_typeRessourceAttribuee__c == 'Secondaire'){
                ressourceIds.add(assResource.id);
            }
        }
        
        if (!ressourceIds.isEmpty()) {
            List<ResourceAbsence> absenceIds = [SELECT id
                                                FROM ResourceAbsence
                                                WHERE Type = 'Renfort' 
                                                AND assignedResource__r.ServiceAppointment.RecordType.DeveloperName = 'FSL_rendezVousPlanification'
                                                AND assignedResource__c IN :ressourceIds];
            
            //Suppression des absences liées    
            if (!absenceIds.isEmpty()) {
                Database.delete (absenceIds,false);
            }
        }
    }
    
        /**
    * @description Modification des absences de type 'Renfort' pour être rattachées à la nouvelle ressource si l'attibution est modifiée
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void modifierAbsenceLiee(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        //Collecte des absences liées 
        List<ResourceAbsence> absenceToDelete = new List<ResourceAbsence> ();
        List<ResourceAbsence> absenceToInsert = new List<ResourceAbsence> ();
        Set<ID> ressourceIds = new Set<ID> ();
        for (AssignedResource assResource : (List<AssignedResource>)Trigger.old){         
            if(assResource.fsl_typeRessourceAttribuee__c == 'Secondaire'){
                ressourceIds.add(assResource.id);
            }
        }
        
        if (!ressourceIds.isEmpty()) {        
            List<ResourceAbsence> absenceAttribution = [SELECT id, ResourceId, assignedResource__c, Start, End, 
                                                            RecordTypeId, Street, City, PostalCode, Country
                                                            FROM ResourceAbsence
                                                            WHERE Type = 'Renfort' 
                                                                AND AssignedResource__r.ServiceAppointment.RecordType.DeveloperName = 'FSL_rendezVousPlanification'
                                                                AND AssignedResource__c IN :ressourceIds];
            
            //Rattachement des absences liées aux nouvelles ressources
            for (ResourceAbsence abs : absenceAttribution){  
                //Si la ressource rattachée à l'absence est differente de celle rattachée à la nouvelle attribution de ressource
                if(Trigger.newMap.containsKey(abs.assignedResource__c)){
                    AssignedResource ar = (AssignedResource) Trigger.newMap.get(abs.assignedResource__c);
                    if(ar.ServiceResourceId <> abs.ResourceId){
                        // Creation de la nouvelle absence
                        ResourceAbsence newAbs = new ResourceAbsence ();
                        newAbs.ResourceId = ar.ServiceResourceId;
                        newAbs.assignedResource__c = ar.id;
                        newAbs.Type = 'Renfort';
                        newAbs.Start = abs.Start;
                        newAbs.End = abs.End;
                        newAbs.RecordTypeId = abs.RecordTypeId;
                        newAbs.Street = abs.Street;
                        newAbs.City = abs.City;
                        newAbs.PostalCode = abs.PostalCode;
                        newAbs.Country = abs.Country;
                        
                        //Ajout dans les listes
                        absenceToDelete.add(abs);
                        absenceToInsert.add(newAbs);
                    }
                }
            }
        }
        
        if (!absenceToDelete.isEmpty()) {
            Database.delete(absenceToDelete,false);
        }
        if (!absenceToInsert.isEmpty()) {
            Database.insert(absenceToInsert,false);
        }
    }
}