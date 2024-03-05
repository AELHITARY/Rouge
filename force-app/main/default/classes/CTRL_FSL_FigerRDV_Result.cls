/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-25          Class created. Vérification des résultat
*/
public class CTRL_FSL_FigerRDV_Result {
    
    //Constructeur
    public CTRL_FSL_FigerRDV_Result()
    {
        displayListServiceAppointment();
    }
    
    
    //Initialisation de la liste des RDV traités ou non.
    public List<ServiceAppointment> lServiceAppointmentUpdated {get; set;}
    public List<ServiceAppointment> lServiceAppointmentNotUpdated {get; set;}
    
    //Variable contenant le nombre de RDV mis à jour
    public Integer nbSaUpdated 
    {
        get
        {
            Integer nbSaUpdated = this.lServiceAppointmentUpdated.size();
            return nbSaUpdated;
        }
    }
    
    
    //Variable contenant le nombre de RDV non mis à jour
    public Integer nbSaNotUpdated 
    {
        get
        {
            Integer nbSaNotUpdated = this.lServiceAppointmentNotUpdated.size();
            return nbSaNotUpdated;
        }
    }
    
    
    //Variable contenant le type de traitement à effectuer
    public String typeTraitement 
    {
        get
        {
            //String qui contient la liste de territoire, à convertir en type liste
            String typeTraitement = ApexPages.currentPage().getParameters().get('action');
            
            return typeTraitement;
        }
    }
    
    
    //Création de la liste des ressources à afficher avec les RDV 
    @TestVisible
    private void displayListServiceAppointment()
    {
        //Liste à renvoyer
        lServiceAppointmentUpdated = new List<ServiceAppointment>();
        lServiceAppointmentNotUpdated = new List<ServiceAppointment>();
        List<ServiceAppointment> lSa = new List<ServiceAppointment>();
        
        //Récupération de l'utilisateur actuel 
        Id userId = UserInfo.getUserId();
        
        //Traitement selon l'action 
        String urlAction = ApexPages.currentPage().getParameters().get('action');
        
        //Récupération de la liste des RDV
        String urlListSa = ApexPages.currentPage().getParameters().get('listSa');
        List<String> lIdSa = urlListSa.split('~'); 
        
        if(lIdSa != null)
        {
            for(String iS : lIdSa)
            {
                iS.replaceAll('~','');
            }
        }
        
        
        if(lIdSa != null)
        {
            lSa = [SELECT  Id,
                   AppointmentNumber,
                   fsl_externalId__c,
                   Worktype.Name,
                   Status,
                   Subject,
                   SchedStartTime,
                   SchedEndTime,
                   ContratK__r.numeroContrat__c,
                   FSL__Pinned__c,
                   LastModifiedDate,
                   LastModifiedById
                   FROM    ServiceAppointment 
                   WHERE   Id IN: lIdSa
                   ORDER BY SchedStartTime];
        }
        System.debug('--------------------------- lSa ' + lSa);
        
        if(lSa != null)
        {
            
            for(ServiceAppointment sa : lSa)
            {
                if(sa.LastModifiedDate != null)
                {
                    Date saModifiedDate = Date.newInstance(sa.LastModifiedDate.year(), sa.LastModifiedDate.month(), sa.LastModifiedDate.day());        
                    
                    //Si l'action est de figer un ensemble de rendez-vous
                    if(urlAction == 'F')
                    {                        
                        //Si l'action est figer, vérification que l'action a bien eu lieu
                        if(sa.FSL__Pinned__c == true && saModifiedDate == Date.today() && sa.LastModifiedById == userId )
                        {
                            lServiceAppointmentUpdated.add(sa);
                        }
                        else
                        {
                            lServiceAppointmentNotUpdated.add(sa);
                        }
                    }
                    else if(urlAction == 'D')
                    {
                        if(sa.FSL__Pinned__c == false && saModifiedDate == Date.today() && sa.LastModifiedById == userId )
                        {
                            lServiceAppointmentUpdated.add(sa);
                        }
                        else
                        {
                            lServiceAppointmentNotUpdated.add(sa);
                        }
                    }
                }
            }
        }
        
        
    }
}