trigger FSL_AssignedResource_AfterDelete on AssignedResource (after delete) {
    //Création d'une ligne d'historique des ressources assignées quand un enregistrement est supprimé.
    
    List<HistoriqueAttributionRessource__c> histoToInsert = new List<HistoriqueAttributionRessource__c>();
    
    for (AssignedResource ar : Trigger.old )
    {
        HistoriqueAttributionRessource__c har = new HistoriqueAttributionRessource__c();
        
        har.FSL_Rendez_vous_parent__c = ar.ServiceAppointmentId; 
        har.FSL_Ressource_de_service__c = ar.ServiceResourceId;
        har.Temps_de_trajet_estime__c = ar.EstimatedTravelTime;
        har.Temps_de_trajet_reel__c = ar.ActualTravelTime;
        har.Type_de_ressource__c = ar.fsl_typeRessourceAttribuee__c;
        har.Type_de_traitement__c = 'Suppression';
        histoToInsert.add(har);
    }
    
    try {
        if(!histoToInsert.isEmpty()) {
            insert histoToInsert;
        }
    } 
    catch (System.Dmlexception e) 
    {
        System.debug (e);
    }
}