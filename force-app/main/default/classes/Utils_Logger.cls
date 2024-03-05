//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Logger
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/08/2017
//-- Version     : 1.0
//-- * Classe utilitaire pour l'affichage des messages dans les pages VF
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_Logger {

    public Utils_Logger() {
        clear();
    }

    public void clear() {
        StaticMessages = new List<PageMessage>();
    }

    public enum Severity {CONFIRM,INFO,WARN,FATAL,ERROR}
    public class PageMessage {
        private Map<Severity,String> SeverityStrMap = new Map<Severity,String>{
            Severity.CONFIRM => 'confirm',
            Severity.INFO => 'info',
            Severity.WARN => 'warning',
            Severity.FATAL => 'danger',
            Severity.ERROR => 'danger'
        };

        public Severity SeverityLevel { get; set; }
        public String SeverityStr { get; set; }
        public String Message { get; set; }

        public PageMessage (Severity theSeverity, String theMessage) {
            this.SeverityLevel = theSeverity;
            this.Message = theMessage;
            this.SeverityStr = SeverityStrMap.get(theSeverity);
        }
    }
    public  List<PageMessage> StaticMessages { get; set; }
    
    public  void addMessage(PageMessage thePageMessage) {
        StaticMessages.add(thePageMessage);
    }
    public  List<PageMessage> getPageMessages(){
        return StaticMessages;
    }

    public  void addErrorMessage(String theMessage) {
        addMessage(new PageMessage(Severity.ERROR, '<strong>ERREUR :</strong> ' + theMessage));
    }

    public  void addConfirmMessage(String theMessage) {
        addMessage(new PageMessage(Severity.CONFIRM, theMessage));
    }

    public  void addWarnMessage(String theMessage) {
        addMessage(new PageMessage(Severity.WARN, theMessage));
    }

    public static void insertNewConnexionClient(String identifiant, String typeEvenement, String etat, String details, String mdp) {
        ConnexionClient__c newConnexion = new ConnexionClient__c(
            identifiant__c = identifiant,
            eventDateTime__c = System.now(),
            eventType__c = typeEvenement,
            etat__c = etat,
            details__c = details,
            mdpHashEncrypted__c = mdp
        );
        insert newConnexion;
    }
}