//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : NotificationWO_fsl_AfterInsert
//-- Modifié par : CGI
//-- Modifié le  : 09/04/2018
//-- Version     : 1.0
//-- Description : Trigger after insert pour vérifier la consommation de notificationWO publiées via Platform Event
//-- --------------------------------------------------------------------------------- --
trigger NotificationWO_fsl_AfterInsert on NotificationWO__e (after insert) {
    
GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.check.email');
    
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();   
                String message = '';                    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
                List<String> sendTo = emailException.stringValue__c.split(';');                  
                mail.setToAddresses(sendTo);                          
                mail.setReplyTo('FieldServiceLightning@salesforce.com');
                mail.setSenderDisplayName('Field Service Lightning');                                         
                mail.setSubject('Consommation de ' +Trigger.New.size() + ' notificationWO');
                for (NotificationWO__e event : Trigger.New) {  
                    message = message +'<br/><br/><br/>'+event;
                }
                mail.setHtmlBody(message);                            
                mails.add(mail); 
    system.debug('Consommation de ' +Trigger.New.size() + ' notificationWO : <br>' + message );
     if(emailException.actif__c)
                Messaging.sendEmail(mails);        
    
}