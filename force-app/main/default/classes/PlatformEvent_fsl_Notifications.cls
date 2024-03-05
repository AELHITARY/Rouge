//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : PlatformEvent_fsl_NotificationSA
//-- Modifié par : CGI
//-- Modifié le  : 07/02/2018
//-- Version     : 1.0
//-- Description : Préparer des notifications sur WorkOrder et sur ServiceAppointment pour les envoyer à GC via Platform Event 
//-- --------------------------------------------------------------------------------- --
public class PlatformEvent_fsl_Notifications {
        
    //Préparer les notifications sur ServiceAppointment
    public static List<NotificationSA__e> getNotificationSA(List<ServiceAppointment> listeSA){
        list<NotificationSA__e> listeNotificationSA = new list<NotificationSA__e>();
        Set<string> setSAIds = new Set<string>();
        Set<string> setWOIds = new Set<string>();
        
        for (ServiceAppointment sa:listeSA){
            setSAIds.add(sa.id);
            setWOIds.add(sa.ParentRecordId);
        }
        
        Map<ID,String> mapExternalIdbyWorkOrderId = FieldServiceUtils.createMapExternalIdByWorkOrder(setWOIds);
        Map<ID,String> mapRessourcebyServiceAppointmentId = FieldServiceUtils.createMapRessource(setSAIds);
        
        
        for (ServiceAppointment sa:listeSA){
            NotificationSA__e event = new NotificationSA__e();
            event.fsl_externalId__c = mapExternalIdbyWorkOrderId.get(sa.ParentRecordId);
            if(sa.Status!=null)
                event.fsl_status__c = sa.Status.replace('é', 'e').toUpperCase();
            if(sa.SchedStartTime!=null)
                event.fsl_scheduledStartDate__c = FieldServiceUtils.ConversionDateString(sa.SchedStartTime);
            if(sa.SchedEndTime!=null)
                event.fsl_scheduledEndDate__c = FieldServiceUtils.ConversionDateString(sa.SchedEndTime);
            if(sa.ActualStartTime!=null)
                event.fsl_actualStartDate__c = FieldServiceUtils.ConversionDateString(sa.ActualStartTime);
            if(sa.ActualEndTime!=null)
                event.fsl_actualEndDate__c = FieldServiceUtils.ConversionDateString(sa.ActualEndTime);
            if(sa.fsl_techDebutFenetre__c!=null)
                event.fsl_arrivalWindowStart__c = FieldServiceUtils.ConversionDateString(sa.fsl_techDebutFenetre__c);
            if(sa.fsl_techFinFenetre__c!=null)
                event.fsl_arrivalWindowEnd__c = FieldServiceUtils.ConversionDateString(sa.fsl_techFinFenetre__c);
            if(sa.fsl_dateDebriefing__c!=null)
            event.fsl_dateDebriefing__c = FieldServiceUtils.ConversionDateString(sa.fsl_dateDebriefing__c);
            
            event.fsl_montantRecu__c = sa.fsl_montantRecu__c;     
            event.fsl_modeReglement__c = sa.fsl_modeReglement__c;
            event.fsl_autorisationFinancement__c = sa.fsl_autorisationFinancement__c;            
            event.fsl_signatureClient__c = sa.fsl_signatureClient__c;            
            event.fsl_nbIntervenantProchainRDV__c  = sa.fsl_nbIntervenantProchainRDV__c;
            event.fsl_dureeProchainRDV__c = sa.fsl_dureeProchainRDV__c;
            event.fsl_coutsProchainRDV__c = sa.fsl_coutsProchainRDV__c;                   
            event.fsl_recommandationsChantier__c = sa.fsl_recommandationsChantier__c;            
            event.fsl_reservesChantier__c = sa.fsl_reservesChantier__c;
            event.fsl_responsabiliteChantier__c = sa.fsl_responsabiliteChantier__c;
            event.fsl_reservesProduits__c = sa.fsl_reservesProduits__c;
            event.fsl_responsabiliteProduits__c = sa.fsl_responsabiliteProduits__c;
            event.fsl_reservesTravaux__c = sa.fsl_reservesTravaux__c;
            event.fsl_responsabiliteTravaux__c = sa.fsl_responsabiliteTravaux__c;
            event.fsl_incidentsProduits__c = sa.fsl_incidentsProduits__c;
            event.fsl_incidentsTravaux__c = sa.fsl_incidentsTravaux__c;
            event.fsl_retoursReservesClient__c = sa.fsl_retoursReservesClient__c;           
            event.fsl_retoursReservesKparK__c = sa.fsl_retoursReservesKparK__c;
            event.fsl_documentsFournis__c = sa.fsl_documentsFournis__c;
            event.fsl_ressource__c = mapRessourcebyServiceAppointmentId.get(sa.id);
            listeNotificationSA.add(event);
        }
        system.debug('***'+listeNotificationSA);
        return listeNotificationSA;
        
    }

    //Préparer les notifications sur WorkOrder
    public static List<NotificationWO__e> getNotificationWO(List<WorkOrder> listeWO){
        list<NotificationWO__e> listeNotificationWO = new list<NotificationWO__e>();
        
        for (WorkOrder wo:listeWO){
            NotificationWO__e event = new NotificationWO__e();
            event.fsl_externalId__c = wo.fsl_externalId__c;
            event.fsl_status__c = wo.Status.replace('é', 'e').toUpperCase();
            event.fsl_subject__c =wo.Subject;
            event.fsl_priority__c=wo.Priority;
            event.fsl_accountExternal__c=wo.Account.AccountNumber;
            event.fsl_contratKExternal__c=wo.ContratK__r.numeroContrat__c;
            event.fsl_serviceTerritoryExternal__c=wo.ServiceTerritory.KparKReference__c;
            event.fsl_parentWorkOrderExternal__c=wo.ParentWorkorder.fsl_externalId__c;
            event.fsl_workTypeExternal__c=wo.WorkType.name;
            
            listeNotificationWO.add(event);
        }
        return listeNotificationWO;
    }
    
}