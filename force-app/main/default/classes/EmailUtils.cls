//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : EmailUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/10/2021
//-- Version     : 1.1
//-- * Modification pour ajouter multi-destinataire (séparé par une virgule) dans SUPPORT_EMAIL et EXCEPTION_EMAIL
//-- --------------------------------------------------------------------------------- --
public without sharing class EmailUtils {
    private static final String EXCEPTION_EMAIL = PropertiesUtils.getStringValue('email.exception', 'franck.gourdeaux@kpark.fr');
    private static final String SUPPORT_EMAIL   = PropertiesUtils.getStringValue('email.support', 'support@kpark.fr');
  
    public static void mailTo(String title, String message, List<String> sendTo, List<String> copyTo) {
        if (sendTo == null || sendTo.isEmpty())
            return;
            
        // Sélection de l'email d'expédition
        OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'support@kpark.fr'];
            
        // Construction de l'email et envoi
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(title);
        email.setOrgWideEmailAddressId(fromAddress.Id);
        email.setToAddresses(sendTo);
        if (copyTo != null && !copyTo.isEmpty()) email.setCcAddresses(copyTo);
        email.setPlainTextBody(message);
        email.setSaveAsActivity(false);
        if (!Test.isRunningTest()) {   
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
            system.debug('EmailUtils results : ' + results);
        }
    }    
    
    public static void mailTo(String title, String message, List<String> sendTo) {
        mailTo(title, message, sendTo, null);
    }
  
    public static void mailTo(String title, String message, List<User> sendTo) {
        mailTo(title, message, sendTo, null);
    }
  
    public static void mailTo(String title, String message, List<User> sendTo, List<User> copyTo) {
        List<User> sendToUsers = (sendTo == null || sendTo.isEmpty()) ? new List<User>() : [SELECT id, isActive, email FROM user WHERE id IN :sendTo];
        List<User> copyToUsers = (copyTo == null || copyTo.isEmpty()) ? new List<User>() : [SELECT id, isActive, email FROM user WHERE id IN :copyTo];
        mailToUsers(title, message, sendToUsers, copyTousers);
    }
  
    private static void mailToUsers(String title, String message, List<User> sendToUsers, List<User> copyToUsers) {
        List<String> sendTo = new List<String>();
        List<String> copyTo = new List<String>();
    
        if (sendToUsers != null && !sendToUsers .isEmpty()) {
            for (User user : sendToUsers)
            if (user.isActive && !StringUtils.isEmpty(user.email))
                sendTo.add(user.email);
        }
    
        if (copyToUsers != null && !copyToUsers .isEmpty()) {
            for (User user : copyToUsers )
            if (user.isActive && !StringUtils.isEmpty(user.email))
                copyTo.add(user.email);
        }
    
        mailTo(title, message, sendTo, copyTo);
    }
  
    public static void mailTo(String title, String message, List<Profile> profiles) {
        if (profiles!= null && !profiles.isEmpty())
            mailToUsers(title, message, [SELECT id, isActive, email FROM user WHERE profileId IN :profiles], null);
    }
  
    public static void mailTo(String title, String message, List<UserRole> roles) {
        if (roles!= null && !roles.isEmpty())
            mailToUsers(title, message, [SELECT id, isActive, email FROM user WHERE userRoleId IN :roles], null);
    }
  
    public static void mailToITSupport(String title, String message) {
        if (String.isNotBlank(SUPPORT_EMAIL) && String.isNotBlank(message))
            mailTo(title, message, SUPPORT_EMAIL.split(','));
    }
  
    public static void mailToAdministrators(String title, String message) {
        Profile administrator = [SELECT id FROM profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système' LIMIT 1];
        mailTo(title, message, new Profile[]{administrator});
    }
  
    public static void reportException(String title, Exception error) {
        if (error == null)
            return;
      
        String msg = 'Message = ' + error.getMessage() + '\n\n'
                    + 'Type = ' + error.getTypeName() + '\n'
                    + 'Ligne = ' + error.getLineNumber() + '\n\n'
                    + error.getStackTraceString();
                
        reportException(title, msg);
    }
  
    public static void reportException(String title, String error) {
        if (String.isNotBlank(EXCEPTION_EMAIL) && String.isNotBlank(error))
            mailTo(title, error, EXCEPTION_EMAIL.split(','));
    }
    
    public static void reportException(String title, String error, List<String> destinataires) {
        if (!destinataires.isEmpty() && String.isNotBlank(error))
            mailTo(title, error, destinataires);
    }
}