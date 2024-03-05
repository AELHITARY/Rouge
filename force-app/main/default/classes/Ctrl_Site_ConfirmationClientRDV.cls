//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_ConfirmationClientRDV
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 03/05/2023
//-- Version     : 1.1
//-- * 1.1 - Prise en compte du type de RDV K2/K3 dans la confirmation client
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_ConfirmationClientRDV {
    private static final String RT_RDV_KUBE3 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

    // Parametres
    public String rdvId {get; set;}
    public ServiceAppointment rdv {get; set;}
    public Boolean rdvExist { get; set; }
    public String SchedStartTimeString { get; set; }
    public String SchedEndTimeString { get; set; }

    // ERRORS
    public Utils_logger log {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_Site_ConfirmationClientRDV
    */
    public Ctrl_Site_ConfirmationClientRDV() {
        log = new Utils_logger();
        rdvExist = false;

        // Récupération de l'id dans l'URL. Requête le SA associé.
        rdvId = ApexPages.currentPage().getParameters().get('rdvId');
        List<ServiceAppointment> rdvList = [SELECT Id, WorkType.Name, Street, PostalCode, City, fsl_externalId__c, dateConfirmationClient__c,
                                                ArrivalWindowStartTime, ArrivalWindowEndTime, confirmeParClient__c
                                                FROM ServiceAppointment WHERE Id = :rdvId];
        
        if(!rdvList.isEmpty()){
            rdv = rdvList[0];
            rdvExist = true;

            // Formatage des datetime
            if(rdv.ArrivalWindowStartTime != null) {
                SchedStartTimeString = rdv.ArrivalWindowStartTime.format('dd/MM/yy HH:mm','Europe/Paris');
            }
            if(rdv.ArrivalWindowEndTime != null) {
                SchedEndTimeString = rdv.ArrivalWindowEndTime.format('dd/MM/yy HH:mm','Europe/Paris');
            }
        }
    }

    // Mise à jour asynchrone de la date de confirmation client.
    @RemoteAction
    public static void confirmRDV(String rdvId) {
        System.debug('### DEBUT confirmRDV');
        System.debug('## rdvId: '+rdvId);
        
        try {

            // Récupération du rendez-vous de service
            ServiceAppointment rdv = [SELECT Id, fsl_dateConfirmation__c , dateConfirmationClient__c, 
                                            confirmeParClient__c, RecordTypeId
                                            FROM ServiceAppointment WHERE Id = :rdvId LIMIT 1];

            // Mise à jour de la date de confirmation client
            if (rdv.RecordTypeId == RT_RDV_KUBE3) {
                rdv.fsl_dateConfirmation__c = Date.today();
            } else {
                rdv.dateConfirmationClient__c = Date.today();
            }
            rdv.confirmeParClient__c = true;
            update rdv;
            
            System.debug('### FIN confirmRDV');
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
}