/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-05          Class created. Pin SA. Parameter : Resources
*/

public class CTRL_FSL_FigerRDV_Resource {

    //Constructeur
    public CTRL_FSL_FigerRDV_Resource()
    {
        radioSelected ='F';
        createResource();
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
    
    //Variable contenant le nom des territoires sélectionnés 
    public String nameTerritory{get; set;}
    
    
    //Variable contenant le type de ressource sélectionné
    public String typeResource {get; set;}
    
    
    //Variable renvoyant le bouton radio précoché
    public String radioSelected {get; set;}
    
    
    //Initialisation de la variable permettant de récupérer toutes les ressources cochées.
    public List<ServiceResourceCustom> listServiceResourceCustom {get; set;}
    
    //Variable renvoyée si la date de début et de fin est la même 
    public String sameDate {
        get
        {
            String deb = ApexPages.currentPage().getParameters().get('start');
            String fin = ApexPages.currentPage().getParameters().get('end');
            String sameDate ='';
            
            if(deb == fin)
            {
                sameDate = 'hidden';
            }
            return sameDate;
        }
    }
    
    //Récupération du noms des territoires sélectionnés
    @TestVisible
    private String getTerritory()
    {        
        //Instanciation de la variable 
        this.nameTerritory ='';
        //String qui contient la liste de territoire, à convertir en type liste
        String urlTer = ApexPages.currentPage().getParameters().get('listTer');
        String[] idTer = urlTer.split('-'); 
        
        if(idTer != null)
        {
            for(String iT : idTer)
            {
                iT.replaceAll('-','');
            }
        }
  
        List<ServiceTerritory> stChecked = new List<ServiceTerritory>([SELECT       Id, 
                                                                                    Name
                                                                       FROM         ServiceTerritory
                                                                       WHERE        Id IN:idTer
                                                                       ORDER BY     Name]);
        
        //Création de la chaîne de caractères avec les noms de territoires 
        if(stChecked != null)
        {
            for(ServiceTerritory st : stChecked)
            {
                this.nameTerritory = this.nameTerritory+ ' ' + st.Name + '   ';
            }
        }
        
        return this.nameTerritory;
        
    }
    
    
    @TestVisible
    private String getType()
    {        
        //Instanciation de la variable 
        this.typeResource ='';
        //String qui contient la liste de territoire, à convertir en type liste
        String urlType = ApexPages.currentPage().getParameters().get('type');
        String[] idType = urlType.split('~'); 
        
        if(idType != null)
        {
            for(String iT : idType)
            {
                iT.replaceAll('~','');
            }
        }
        
        
        //Création de la chaîne de caractères avec les noms de territoires 
        for(String t : idType)
        {
            this.typeResource = this.typeResource+ ' ' + t + '   ';
        }
        
        return this.typeResource;
        
    }

    
    //Création de ma ServiceResource Custom pour l'affichage par défaut et les cases à cocher
    public class ServiceResourceCustom 
    {
        public String name {get; set;}
        public Boolean isSelected {get; set;}
        public String territory {get; set;}
        public String job {get; set;}
        
        //Valeurs par défaut
        public ServiceResourceCustom (String name, String territory, String job) 
        {
            isSelected = false;
             
            //Nom
            if(name != null)
            {
                this.name = name;
            }
            
            //Territoire
            if(territory != null)
            {
                this.territory = territory;
            }
            
            //Métier 
            if(job != null)
            {
                this.job = job;
            }
        }        
    }
    
   
    
    //Création de la liste de Service Resource à afficher
    @TestVisible 
    private void createResource()
    {
        //Nom des territoires
        this.getTerritory();
        //Type de ressources
        this.getType();
        
        //Instantion de la liste à afficher
        listServiceResourceCustom = new List<ServiceResourceCustom>();
        
        //String qui contient la liste des territoires sélectionnées
        String urlTer = ApexPages.currentPage().getParameters().get('listTer');
        String[] idTer = urlTer.split('-');
        if(idTer != null)
        {
            for(String iT : idTer)
            {
                iT.replaceAll('-','');
            }
        }
        
        //String qui contient la liste des types de ressources sélectionnés
        String urlType = ApexPages.currentPage().getParameters().get('type');
        String[] keyType = urlType.split('~');
        if(keyType != null)
        {
            for(String kT : keyType)
            {
                kT.replaceAll('~','');
            }           
        }
        
        
        //Sélection des Membre de territoires faisant partie du territoire, dont le métier est celui sélectionné et qui est toujours active et actif sur le territoire.
        List<ServiceTerritoryMember> stmChecked = new List<ServiceTerritoryMember>([SELECT  Id,
                                                                                            ServiceResourceId, 
                                                                                            ServiceTerritoryId,
                                                                                            EffectiveStartDate,
                                                                                            EffectiveEndDate
                                                                                    FROM    ServiceTerritoryMember
                                                                                    WHERE   ServiceTerritoryId IN:idTer
                                                                                    AND     ((EffectiveEndDate = null) OR (EffectiveEndDate > :this.debutPlanning))
                                                                                    AND     EffectiveStartDate < :this.finPlanning
                                                                                    AND     toLabel(ServiceResource.job__c) IN :keyType
                                                                                    AND     ServiceResource.IsActive = true]);   
      System.debug('------------------------ STM CHECKED '+ stmChecked);
        
        //Ajustement pour n'afficher qu'une seule ressource par territory member 
        Set<Id> idRes = new Set<Id>();
        
        if(stmChecked != null)
        {
            for(ServiceTerritoryMember s : stmChecked)
            {
                idRes.add(s.ServiceResourceId);
            }
        }
        
        List<ServiceResource> listOneServiceResource = new List<ServiceResource>([SELECT   id, 
                                                                                           Name,
                                                                                           serviceTerritory__c,
                                                                                           serviceTerritory__r.Name, 
                                                                                           toLabel(job__c) 
                                                                                  FROM     ServiceResource 
                                                                                  WHERE    id IN:idRes 
                                                                                  //AND        serviceTerritory__c IN:idTer
                                                                                  ORDER BY serviceTerritory__r.Name ASC, job__c ASC ,Name ASC ]);
        if(listOneServiceResource != null)
        {
            for(ServiceResource r : listOneServiceResource)
            {
                ServiceResourceCustom myResource = new ServiceResourceCustom(r.Name, r.serviceTerritory__r.Name, r.job__c);
                listServiceResourceCustom.add(myResource);
            }
        }
        
    }
    
    
    
    //Redirection vers la page pour afficher la feuille de route 
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_FigerRDV_Recap';
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlRes = '';
        
        //Formation de l'URL avec les dates 
        link = link + '?start=' + this.debutPlanning + '&end=' + this.finPlanning + '&action=' + this.radioSelected;
        
        //Liste des ressources custom cochées
        Set<String> lResourceCustomSelected = new Set<String>();

        if(this.listServiceResourceCustom != null)
        {
            for(ServiceResourceCustom src : this.listServiceResourceCustom)
            {
                if(src.isSelected)
                {
                    lResourceCustomSelected.add(src.Name);                    
                }
            }            
        }        
        
        //Liste des ressources à sélectionnées
        List<ServiceResource> lServiceResourceSelected = [SELECT id, 
                                                                 Name 
                                                          FROM   ServiceResource 
                                                          WHERE  Name IN: lResourceCustomSelected];
   
        //Formation de l'URL 
        if(lServiceResourceSelected != null)
        {
            for(Integer i=0; i < lServiceResourceSelected.size(); i++)
            {
                urlRes = urlRes + lServiceResourceSelected[i].id + '-'; 
            }
            link = link + '&listResId=' + urlRes;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    }
}