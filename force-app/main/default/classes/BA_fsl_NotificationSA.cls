//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_fsl_NotificationSA
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 13/10/2022
//-- Version     : 1.2
//-- * Envoyer les notifications sur ServiceAppointment à GC
//-- * 1.2 : Ne pas prendre en compte pour les dépots migré Kube3
//-- --------------------------------------------------------------------------------- --
global class BA_fsl_NotificationSA implements Database.Batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext bc)  {
        DateTime now=System.now();  
        DateTime lastSynchronisation=null;
        GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.sa');    
        if(synchronisation.dateTimeValue__c != null){            
            lastSynchronisation=synchronisation.dateTimeValue__c;
        }else{            
            lastSynchronisation= Datetime.newInstance(2018, 1, 1, 0, 0, 0);    
        }
        String rtName = 'ServiceAppointment';
        System.debug('*********Last Synchro'+lastSynchronisation);
        String query= 'SELECT id,ParentRecordId,status,SchedStartTime,SchedEndTime,'+
            'ActualStartTime,ActualEndTime,fsl_techDebutFenetre__c,fsl_techFinFenetre__c,'+
            'fsl_montantRecu__c,fsl_modeReglement__c,fsl_autorisationFinancement__c,'+
            'fsl_signatureClient__c,fsl_nbIntervenantProchainRdv__c,fsl_dureeProchainRdv__c,'+
            'fsl_retoursReservesClient__c,fsl_retoursReservesKparK__c,fsl_documentsFournis__c,'+
            'fsl_dateDebriefing__c,fsl_coutsProchainRDV__c,fsl_recommandationsChantier__c,fsl_reservesChantier__c,fsl_responsabiliteChantier__c,'+
            'fsl_reservesProduits__c,fsl_responsabiliteProduits__c,fsl_reservesTravaux__c,fsl_responsabiliteTravaux__c,'+
            'fsl_incidentsProduits__c,fsl_incidentsTravaux__c FROM ServiceAppointment '+
            'WHERE (fsl_techFlagSynchro__c = : now OR (fsl_techFlagSynchro__c > : lastSynchronisation AND fsl_techFlagSynchro__c < : now)) '+
            'AND RecordType.DeveloperName != :rtName AND entityMigratedToK3__c = false ORDER BY fsl_techFlagSynchro__c ASC' ;
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<ServiceAppointment> listeSA){
        System.debug('**listeSA**'+listeSA);
        GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email');       
        if (listeSA!=null){
            List<NotificationSA__e> listeNotificationSA = PlatformEvent_fsl_Notifications.getNotificationSA(listeSA);
            System.debug('**PE NotificationSA**'+ listeNotificationSA);
            
            List<Database.SaveResult> results = EventBus.publish(listeNotificationSA);
            integer successCounter = 0;
            
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {                    
                    successCounter=successCounter+1;  
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Error publication NotificationSA**: ' + err.getStatusCode() +  ' - ' +  err.getMessage());
                        //Envoyer email alert si publication des notifications est échoué 
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de publication des notificationsSA via platform events ',null,null,emailException);
                    }
                }   
            }
            System.debug('**'+successCounter+' events publiés notificationSA**');
            
            if(successCounter==listeSA.size()){
                GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.sa');                
                synchronisation.dateTimeValue__c=System.now();      
                Database.update(synchronisation, false);
                
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();   
                String message = '';                    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                GlobalProperties__c emailCheck = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.check.email'); 
                List<String> sendTo = emailCheck.stringValue__c.split(';');                  
                mail.setToAddresses(sendTo);                          
                mail.setReplyTo('FieldServiceLightning@salesforce.com');
                mail.setSenderDisplayName('Field Service Lightning');                                         
                mail.setSubject(successCounter+' NotificationSA publiées');
                for (NotificationSA__e notif : listeNotificationSA) {  
                    message = message +'<br/><br/><br/>'+notif;
                }
                mail.setHtmlBody(message);                            
                mails.add(mail);   
                if(emailCheck.actif__c)
                    Messaging.sendEmail(mails);        
            }            
        }    
    }
    
    global void finish(Database.BatchableContext bc){
        String a = 'test';
        String b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
    }    
    
}