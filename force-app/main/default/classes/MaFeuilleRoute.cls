public class MaFeuilleRoute {
        
    //Contructeur 
    public MaFeuilleRoute() {
        createMapResourceSA();
    }
    
    
    //Récupération de la date de début 
    public Date debutPlanning{
        get{
            String sDebutPlanning = ApexPages.currentPage().getParameters().get('start');
            Date debutPlanning = Date.valueOf(sDebutPlanning);
            
            return debutPlanning;           
        }
    }
    
    //Récupération de la date de fin
    public Date finPlanning{ 
        get
        {
            String sFinPlanning = ApexPages.currentPage().getParameters().get('end');
            Date finPlanning = Date.valueOf(sFinPlanning);     
            
            return finPlanning;           
        }
    }
        
    //Initialisation de la variable permettant de récupérer toutes les ressources qu'on a cochées et leurs RDV
    public Map<ServiceResource, List<ServiceAppointment>> mapSrSA {get;set;}
    
    //Récupération du nombre de RDV par ressources
    public Map<ServiceResource, Integer> mapSrNbSA {get; set;}
    
    //Liste des clés  de la MAP
    public Set<String> keys { get; set;}
    
    
    //Création de la liste de Service Resource à afficher
    @TestVisible
    private void createMapResourceSA()
    {
        //Instantion des variables 
        mapSrSA = new Map<ServiceResource, List<ServiceAppointment>>();
        mapSrNbSA = new Map<ServiceResource, Integer>();
        
        keys = new Set<String>();
        //String qui contient ma liste d'éléments, à convertir en type liste
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
        
        //Instanciation de la liste à renvoyer
        List<ServiceAppointment> lServiceAppointment = new List<ServiceAppointment>();
        //Paramétrage des dates 
        Date debutPlanning = this.debutPlanning;
        Date finPlanning = this.finPlanning;
        
        List<AssignedResource> lAr = new List<AssignedResource>();
        
        if(lServiceResource != null)
        {
            lAr = [SELECT  Id,
                           ServiceResourceId,
                           ServiceAppointmentId
                   FROM    AssignedResource
                   WHERE   ServiceResourceId IN :lServiceResource];
            System.debug('--------------------- lAr' + lAr);
        }
        
        //Liste ID de rdv
        Set<Id> saId = new Set<Id>();
        
        //Map<Id,AssignedResource> mapAr = new Map<Id,AssignedResource>();
        
        for(AssignedResource ar : lAr)
        {
            //mapAr.put(ar.id, ar);
            saId.add(ar.ServiceAppointmentId);
        }
        System.debug('--------------------- saId' + saId);
        
        if(saId != null){
            lServiceAppointment = [SELECT  Id,
                                           AppointmentNumber,
                                           fsl_externalId__c,
                                           Worktype.Name,
                                           Status,
                                           Subject,
                                           Duration,
                                           SchedStartTime,
                                           SchedEndTime,
                                           fsl_chiffreAffaire__c,
                                           //fsl_techCompteRattache__c,
                                           account__c,
                                           fsl_contactClient__c,
                                           fsl_SoldeClient__c,
                                           Street,
                                           City,
                                           Country,
                                           PostalCode,
                                           fsl_libelleDuree__c,
                                           fsl_homephone__c,
                                           fsl_mobilephone__c,
                                           Description,
                                           Latitude,
                                           Longitude,
                                           fsl_techDebutFenetre__c,
                                           fsl_techFinFenetre__c,
                                           ServiceNote,
                                           Contact.HomePhone,
                                           Contact.MobilePhone
                                   FROM    ServiceAppointment 
                                   WHERE   Id IN: saId
                                   AND     Status != 'Demandé'
                                   AND     Status != 'Planifié'
                                   AND     SchedStartTime >= :debutPlanning
                                   AND     SchedStartTime <= :finPlanning+1
                                   ORDER BY SchedStartTime];
            System.debug('--------------------- lServiceAppointment' + lServiceAppointment);
        }
        
        for(ServiceResource sr : lServiceResource )
        {
            if(lServiceAppointment != null) 
            {
                for(ServiceAppointment sa : lServiceAppointment)
                {                       
                    for(AssignedResource ar : lAr)
                    {
                        if(ar.ServiceResourceId == sr.id && ar.ServiceAppointmentId == sa.id)
                        {
                            /*if(mapSrSA.get(sr) != null)
                            {
                                List<ServiceAppointment> lSa = mapSrSA.get(sr);
                                lSa.add(sa);
                                mapSrSA.put(sr, lSa);
                                keys.add(sr.id);
                                mapSrNbSA.put(sr, lSa.size());
                            }
                            else
                            {
                                List<ServiceAppointment> lSa = new List<ServiceAppointment>();
                                lSa.add(sa);
                                mapSrSA.put(sr, lSa);
                                keys.add(sr.id);
                                mapSrNbSA.put(sr, lSa.size());
                            }*/
                            List<ServiceAppointment> lsa;
                            if(mapSrSA.get(sr) != null)
                            {
                                lSa = mapSrSA.get(sr);
                            }else{
                                lSa = new List<ServiceAppointment>();
                            }
                            lSa.add(sa);
                            mapSrSA.put(sr, lSa);
                            keys.add(sr.id);
                            mapSrNbSA.put(sr, lSa.size());
                        }
                    }
                }
            }
        }
    }
    
    //Récupération des objets clés qui seront utilisées pour afficher les paramètres de chaque ressources
    public List<ServiceResource> getListServiceResource(){
        
        keys = this.keys;
        
        //Liste Object  
        List<ServiceResource> listServiceResource = [SELECT Id, Name FROM ServiceResource WHERE Id IN: keys];                  
        return listServiceResource;
    }

    
    //Renvoie du logo KparK à partir des ressources statiques
    public Id getLogoKparKId(){
        return DAL.getDocumentByName(Constants.KparK_logo_NB).id;
    }   
    

}