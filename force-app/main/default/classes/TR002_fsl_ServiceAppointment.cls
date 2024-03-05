//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR002_fsl_ServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/06/2022
//-- Version     : 1.1
//-- Description : Calcul de la fenêtre d'arrivée
//-- --------------------------------------------------------------------------------- --

public without sharing class TR002_fsl_ServiceAppointment {

    private static final String serviceRDV_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'serviceRDV');
    private static final String FSL_RDV_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    

    /**
    * @description Déclenche d'une erreur si un rdv confirmé ne possède aucune ressource attribuée
    * @param Trigger.new
    * @return Message d'erreur
    */
    public static void  calculFenetreArrivee(UserContext userContext) {
        System.debug('### DEBUT TR002_fsl_ServiceAppointment : calculFenetreArrivee');
        if (!Trigger.isExecuting)
            return;
                
        Map<Id,ServiceAppointment> oldSAs = (Map<Id,ServiceAppointment>) Trigger.oldMap;   
        List<ServiceAppointment> newSAs = (List<ServiceAppointment>) Trigger.new;   
            
        System.debug('############# DEBUG - Ancien RDV : '+oldSAs);
        System.debug('############# DEBUG - Nouveau RDV : '+newSAs);
        
        for(ServiceAppointment newSA : newSAs){
            ServiceAppointment oldSA = oldSAs.get(newSA.id); 
            
            // Statut modifié à "Demandé ou Annulé"
            if (newSA.RecordTypeId == FSL_RDV_RTID && (oldSA.status != null && !oldSA.status.equals('Demandé') && newSA.status != null && newSA.status.equals('Demandé')) ||
                (oldSA.status != null && newSA.status == null) ||
                (oldSA.status != null && !oldSA.status.equals('Annulé') && newSA.status != null && newSA.status.equals('Annulé')) ||            
                (oldSA.cancellingDate__c == null && newSA.cancellingDate__c != null)){
                
                // Réinitialisation début et fin de la fenêtre d'arrivée
                if(oldSA.fsl_techDebutFenetre__c != null){
                    newSA.fsl_techDebutFenetre__c = null;
                }
                if(oldSA.fsl_techFinFenetre__c != null){
                    newSA.fsl_techFinFenetre__c = null;
                }
                if(oldSA.ArrivalWindowStartTime != null){
                    newSA.ArrivalWindowStartTime = null;
                }
                if(oldSA.ArrivalWindowEndTime != null){
                    newSA.ArrivalWindowEndTime = null;
                } 
                break;
            }

            // Statut modifié de "Confirmé" à "Planifié"
            if (newSA.RecordTypeId == FSL_RDV_RTID && oldSA.status != null && newSA.status != null && newSA.status.equals('Planifié') && oldSA.status.equals('Confirmé')){
                
                // Réinitialisation début et fin de la fenêtre d'arrivée
                if(oldSA.ArrivalWindowStartTime != null){
                    newSA.ArrivalWindowStartTime = null;
                }
                if(oldSA.ArrivalWindowEndTime != null){
                    newSA.ArrivalWindowEndTime = null;
                } 
            }           
            
            // Statut "Planifié", Rdv non confirmé et Date de début planifiée modifiée
            
            if (newSA.RecordTypeId == FSL_RDV_RTID && ((newSA.status == null || newSA.status.equals('Confirmé') || newSA.status.equals('Planifié') || newSA.status.equals('Demandé') || newSA.FSL__Schedule_Mode__c.equals('Optimization'))) &&
                (newSA.SchedStartTime != null && oldSA.SchedStartTime != newSA.SchedStartTime )){        
            
                 System.debug('############# DEBUG - Maj Fenetre - newSA.status: '+newSA.status);
                 System.debug('############# DEBUG - Maj Fenetre - newSA.FSL__Schedule_Mode__c: '+newSA.FSL__Schedule_Mode__c);
                 System.debug('############# DEBUG - Maj Fenetre - newSA.cancellingDate__c: '+newSA.cancellingDate__c);
                 System.debug('############# DEBUG - Maj Fenetre - newSA.SchedStartTime: '+newSA.SchedStartTime);
                 System.debug('############# DEBUG - Maj Fenetre - oldSA.SchedStartTime: '+oldSA.SchedStartTime);
                // Calcul début et fin de la fenêtre d'arrivée
                List<Datetime> calculDebutFinArrivee = calculDebutFinArrivee(newSA.SchedStartTime);
                DateTime arrivalStart = calculDebutFinArrivee[0];
                newSA.fsl_techDebutFenetre__c = arrivalStart;
                newSA.fsl_techFinFenetre__c = calculDebutFinArrivee[1];
                    
                // Statut "Confirmé" non modifié
                if (newSA.status.equals('Confirmé'))
                {
                    newSA.ArrivalWindowStartTime = newSA.fsl_techDebutFenetre__c;
                    newSA.ArrivalWindowEndTime = newSA.fsl_techFinFenetre__c;
                }
            }   

            // Statut Planifié/Confirmé/En cours/Terminé
            if (newSA.status != null && (newSA.status.equals('Confirmé') || newSA.status.equals('Planifié') || newSA.status.equals('En cours') || newSA.status.equals('Terminé')) &&
                newSA.RecordTypeId != FSL_RDV_RTID){        
                 System.debug('############# DEBUG - Maj Fenetre - newSA.status: '+newSA.status);
                // Calcul début et fin de la fenêtre d'arrivée
                //if(newSA.fsl_techDebutFenetre__c == null){
                    List<Datetime> calculDebutFinArrivee = calculDebutFinArrivee(newSA.SchedStartTime);
                    DateTime arrivalStart = calculDebutFinArrivee[0];
                    DateTime arrivalWindowStart = calculDebutFinArrivee[0];
                    newSA.fsl_techDebutFenetre__c = arrivalStart;
                    newSA.fsl_techFinFenetre__c = calculDebutFinArrivee[1];
                    newSA.ArrivalWindowStartTime = arrivalStart;
                    newSA.ArrivalWindowEndTime = calculDebutFinArrivee[1];
                //}
            }   
            System.debug('############# DEBUG - Début planifié : '+newSA.SchedStartTime );
            System.debug('############# DEBUG - Début arrivée : '+newSA.fsl_techDebutFenetre__c );
            System.debug('############# DEBUG - Fin arrivée : '+newSA.fsl_techFinFenetre__c );

            // Alimentation du texte fenetre d'arrivé
            if(newSA.ArrivalWindowStartTime != null && newSA.ArrivalWindowEndTime != null) {
                System.debug('############# DEBUG - Maj Arrival Window');
                Datetime startDate = newSA.ArrivalWindowStartTime;
                Datetime endDate = newSA.ArrivalWindowEndTime;
                System.debug('## startDate: '+startDate);
                System.debug('## endDate: '+endDate);
                // Jour
                Map<String, String> dayWeekMap = new Map<String, String>{'1'=>'lundi','2'=>'mardi','3'=>'mercredi','4'=>'jeudi',
                                                                            '5'=>'vendredi','6'=>'samedi','7'=>'dimanche'};
                String dayWeekString = dayWeekMap.get(startDate.format('u'));
                System.debug('## dayWeekString: '+dayWeekString);
                // Mois
                Map<Integer, String> monthMap = new Map<Integer, String>{1=>'janvier',2=>'février',3=>'mars',4=>'avril',5=>'mai',6=>'juin',
                                                                        7=>'juillet',8=>'août',9=>'septembre',10=>'octobre',11=>'novembre',12=>'décembre'};
                String monthString = monthMap.get(startDate.month());
                System.debug('## monthString: '+monthString);
                // Formatage texte
                String valueString = dayWeekString+' '+startDate.day()+' '+monthString+' entre '+
                                        startDate.format('HH')+'h'+startDate.format('mm')+' et '+endDate.format('HH')+'h'+endDate.format('mm');
                System.debug('## Arrival Window: '+valueString);
                newSA.arrivalWindowText__c = valueString;
            } else {
                newSA.arrivalWindowText__c = '';
            }
        }
        System.debug('### FIN TR002_fsl_ServiceAppointment : calculFenetreArrivee');
    }

    /* Algorithme de la fenêtre d’arrivée 
    Resultat : [fenetre date heure début, fenetre date heure fin]
    */
    public static List<DateTime> calculDebutFinArrivee(DateTime debutPlanifie) {
        System.debug('### DEBUT TR002_fsl_ServiceAppointment : calculDebutFinArrivee');
        List<DateTime> listeDebutFin= new List<Datetime>();
        DateTime arriveeCalculee = null ;
        DateTime finCalculee = null ;

        Integer yearFR = debutPlanifie.year();
        Integer monthFR = debutPlanifie.month();
        Integer dayFR = debutPlanifie.day();
        Integer debutHeureFR = debutPlanifie.hour();
        Integer debutMinuteFR =debutPlanifie.minute();

        //Début plannif entre 0h inclus et 8h exclus
        if(debutHeureFR>=0 && debutHeureFR<8){
            arriveeCalculee=DateTime.newInstance(yearFR, monthFR, dayFR, 0, 0, 0);
            finCalculee=arriveeCalculee.addHours(8);
        }
        //Début plannif entre 17h inclus et 0h exclus
        else if(debutHeureFR>=17){
            arriveeCalculee=DateTime.newInstance(yearFR, monthFR, dayFR, 17, 0, 0);
            finCalculee=arriveeCalculee.addHours(7);
        }
        //Début plannif entre 8h inclus et 17h exclus
        else if(debutHeureFR>=8 && debutHeureFR<17){
            //Avant 12h OU en dessous de 12h30
            if(debutHeureFR<12 || (debutHeureFR==12 && debutMinuteFR<30)){
                arriveeCalculee=DateTime.newInstance(yearFR, monthFR, dayFR, 8, 0, 0);
                finCalculee=arriveeCalculee.addMinutes(270);
            }
            // Après 12h30
            else{
                arriveeCalculee=DateTime.newInstance(yearFR, monthFR, dayFR, 12, 30, 0);
                finCalculee=arriveeCalculee.addMinutes(270);
            }
        }
        listeDebutFin.add(arriveeCalculee);
        listeDebutFin.add(finCalculee);
        System.debug('### FIN TR002_fsl_ServiceAppointment : calculDebutFinArrivee');
        return listeDebutFin;
    }

    /*
    public static DateTime calculDebutArrivee(DateTime debutPlanifie) {
        DateTime arriveeCalculee = null ;
            for (Integer i = 0; i < 24 ; i = i + 2){
                t = Time.newInstance(i, 00, 00, 00);
                if( t.hour() < 22 &&  (debutPlanifie.timeGmt() >= t) && (debutPlanifie.timeGmt() < t.addHours(2))){
                    arriveeCalculee  = DateTime.newInstanceGmt(debutPlanifie.dateGMT(),t);
                }        
                else if((debutPlanifie.timeGmt() >= t) && (debutPlanifie.timeGmt() <= t.addHours(1).addMinutes(59))){
                    arriveeCalculee = DateTime.newInstanceGmt(debutPlanifie.dateGMT(),t);
                }
            }
        return arriveeCalculee ;
    }
    */

}