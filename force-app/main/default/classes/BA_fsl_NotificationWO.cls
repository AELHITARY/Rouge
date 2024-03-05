//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_fsl_NotificationWO
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 13/10/2022
//-- Version     : 1.2
//-- * Envoyer les notifications sur WorkOrder à GC
//-- * 1.2 : Ne pas prendre en compte pour les dépots migré Kube3
//-- --------------------------------------------------------------------------------- --
global class BA_fsl_NotificationWO implements Database.Batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext bc)  {
        DateTime now=system.now();
        DateTime lastSynchronisation=null;
        GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.wo');  
        if(synchronisation.dateTimeValue__c != null){            
            lastSynchronisation=synchronisation.dateTimeValue__c;
        }else{            
            lastSynchronisation= Datetime.newInstance(2018, 1, 1, 0, 0, 0);    
        }
        String rtName = 'workOrderService';
        system.debug('*********Last Synchro'+lastSynchronisation);
        String query='SELECT fsl_externalId__c, Status,Subject,Priority,Account.AccountNumber,WorkType.name,'+
            'ContratK__r.numeroContrat__c,ParentWorkorder.fsl_externalId__c,fsl_techFlagSynchro__c,ServiceTerritory.KparKReference__c FROM WorkOrder '+
            'WHERE RecordType.DeveloperName != :rtName AND entityMigratedToK3__c = false '+
            'AND (fsl_techFlagSynchro__c = :now OR (fsl_techFlagSynchro__c > :lastSynchronisation AND fsl_techFlagSynchro__c < :now)) ' +
            'ORDER BY fsl_techFlagSynchro__c ASC';
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<WorkOrder> listeWO){
        system.debug('**listeWO**'+listeWO);
        GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email');
        if (listeWO!=null){
            List<NotificationWO__e> listeNotificationWO = PlatformEvent_fsl_Notifications.getNotificationWO(listeWO);
            system.debug('**PE NotificationWO**'+ listeNotificationWO);
            
            List<Database.SaveResult> results = EventBus.publish(listeNotificationWO);
            integer successCounter = 0;
            
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {                   
                    successCounter=successCounter+1;                                   
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Error publication NotificationWO**: ' + err.getStatusCode() +  ' - ' +  err.getMessage());
                        //Envoyer email alert si publication des notifications est échoué
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de publication des notificationsWO via platform events ',null,null,emailException);
                    }
                }   
            }
            System.debug('**'+successCounter+' events publiés notificationWO**');
            if(successCounter==listeWO.size()){
                GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.wo');
                synchronisation.dateTimeValue__c = system.now();   
                Database.update(synchronisation, false);
                
                String message = '';  
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();  
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                GlobalProperties__c emailCheck = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.check.email'); 
                List<String> sendTo = emailCheck.stringValue__c.split(';');                  
                mail.setToAddresses(sendTo);                          
                mail.setReplyTo('FieldServiceLightning@salesforce.com');
                mail.setSenderDisplayName('Field Service Lightning');                                         
                mail.setSubject(successCounter+' NotificationWO publiées');
                for (NotificationWO__e notif : listeNotificationWO) {  
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
        
    }    
    
}