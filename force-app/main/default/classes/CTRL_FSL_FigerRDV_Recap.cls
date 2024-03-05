/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-25          Class created. Recapitulatif avant confirmation du figeage des RDV
*/
public class CTRL_FSL_FigerRDV_Recap {
    
    //Constructeur
    public CTRL_FSL_FigerRDV_Recap()
    {
        createListServiceAppointment();
    }
    
    //Récupération de la date de début 
    public Date debutPlanning
    {
        get{
            String sDebutPlanning = ApexPages.currentPage().getParameters().get('start');
            Date debutPlanning = Date.valueOf(sDebutPlanning);
            
            return debutPlanning;           
        }
        
        set{}
    }
    
    
    //Récupération de la date de fin
    public Date finPlanning
    { 
        get
        {
            String sFinPlanning = ApexPages.currentPage().getParameters().get('end');
            Date finPlanning = Date.valueOf(sFinPlanning);     
            
            return finPlanning;           
        }
        
        set{}
    }
    
    //Initialisation de la liste des RDV à traiter.
    public List<ServiceAppointment> lServiceAppointment {get; set;}
    
    
    //Variable contenant le type de traitement à effectuer
    public String typeTraitement 
    {
        get
        {
            //Instanciation de la variable 
            String typeTraitement ='';
            
            //String qui contient la liste de territoire, à convertir en type liste
            String urlTypeAction = ApexPages.currentPage().getParameters().get('action');
            
            if(urlTypeAction != null)
            {
                if(urlTypeAction == 'F')
                {
                    typeTraitement = 'FIGER';
                }
                else
                {
                    typeTraitement = 'DEFIGER';
                }
            }
            
            return typeTraitement;
        }
    }
    
    //Variable contenant le nombre de RDV 
    public Integer nbSa 
    {
        get
        {
            Integer nbSa = this.lServiceAppointment.size();
        	return nbSa;
        }
    }
    
    
    //Création de la liste des ressources à afficher avec les RDV 
    @TestVisible
    private void createListServiceAppointment()
    {
        //Instanciation des variables 
        lServiceAppointment = new List<ServiceAppointment>();

        //String qui contient ma liste d'éléments, à convertir en type liste + Alimentation de la MAP
        String urlRes = ApexPages.currentPage().getParameters().get('listResId');
        List<String> lIdRes = urlRes.split('-'); 
        
        if(lIdRes != null)
        {
            for(String iR : lIdRes)
            {
                iR.replaceAll('-','');
            }
        }
        
        //Obtention de la liste des ressources dont l'ID est dans la liste
        List<ServiceResource> lServiceResource = new List<ServiceResource>();
        
        if(lIdRes != null)
        {
            lServiceResource = [SELECT Id,
                                	   Name
                                FROM   ServiceResource 
                                WHERE  IsActive = true
                                AND    Id IN :lIdRes];
        }
        
        
        //Sélection des ressources attribuées pour les RDV
        List<AssignedResource> lAr = new List<AssignedResource>();
        
        if(lServiceResource != null)
        {
            lAr = [SELECT  Id,
                           ServiceResourceId,
                           ServiceAppointmentId
                   FROM    AssignedResource
                   WHERE   ServiceResourceId IN :lServiceResource
                   AND 	   fsl_typeRessourceAttribuee__c = 'Principale'];
        }
        
        //Liste ID de rdv
        Set<Id> saId = new Set<Id>();
        
        for(AssignedResource ar : lAr)
        {
            saId.add(ar.ServiceAppointmentId);
        }
        
        //Traitement selon l'action 
        String urlAction = ApexPages.currentPage().getParameters().get('action');
        if(urlAction == 'F')
        {
            //Obtention de tous les RDV à figer
            if(saId != null){
                lServiceAppointment = [SELECT  Id,
                                       AppointmentNumber,
                                       fsl_externalId__c,
                                       Worktype.Name,
                                       Status,
                                       Subject,
                                       SchedStartTime,
                                       SchedEndTime,
                                       ContratK__r.numeroContrat__c
                                       FROM    ServiceAppointment 
                                       WHERE   Id IN: saId
                                       AND	   SchedStartTime >= :debutPlanning
                                       AND 	   SchedStartTime <= :finPlanning+1
                                       AND 	   FSL__Pinned__c = false
                                       AND 	   fsl_nbRessourceAssignee__c = 1
                                       ORDER BY SchedStartTime];   
            }
        }
        else if(urlAction == 'D')
        {
            //Obtention de tous les RDV à défiger
            if(saId != null){
                lServiceAppointment = [SELECT  Id,
                                       AppointmentNumber,
                                       fsl_externalId__c,
                                       Worktype.Name,
                                       Status,
                                       Subject,
                                       SchedStartTime,
                                       SchedEndTime,
                                       ContratK__r.numeroContrat__c
                                       FROM    ServiceAppointment 
                                       WHERE   Id IN: saId
                                       AND	   SchedStartTime >= :debutPlanning
                                       AND 	   SchedStartTime <= :finPlanning+1
                                       AND 	   FSL__Pinned__c = true
                                       AND 	   fsl_nbRessourceAssignee__c = 1
                                       ORDER BY SchedStartTime];   
            }
        }
    }
    
    
    //Traitement des rendez-vous après confirmation
    //Redirection vers la page pour afficher la feuille de route 
    public PageReference confirmerUpdate() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_FigerRDV_Result';
        String urlSa = '';
        
        //Liste stockage
        List<ServiceAppointment> lSaToUpdate = new List<ServiceAppointment>();
        List<String> idToUpdate = new List<String>();
        
        
        //Traitement selon l'action 
        String urlAction = ApexPages.currentPage().getParameters().get('action');
        if(urlAction == 'F')
        {
            for(ServiceAppointment sa : this.lServiceAppointment)
            {
                sa.FSL__Pinned__c = true;
                lSaToUpdate.add(sa);
                idToUpdate.add(sa.id);
            }
        }
        else if(urlAction == 'D')
        {
            for(ServiceAppointment sa : this.lServiceAppointment)
            {
                sa.FSL__Pinned__c = false;
                lSaToUpdate.add(sa);
                idToUpdate.add(sa.id);
            }
        }
        
        Database.update(lSaToUpdate, false);
        
        //Formation de l'URL avec le territoire et les dates 
        link = link + '?action=' + urlAction;
        //+ '&listSa=' + idToUpdate
        //Formation de l'URL 
        if(idToUpdate != null)
        {
            for(Integer i=0; i < idToUpdate.size(); i++)
            {
                urlSa = urlSa + idToUpdate[i]+ '~'; 
            }
            link = link + '&listSa=' + urlSa;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    } 
    
}