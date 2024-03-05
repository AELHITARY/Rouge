/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-04-10          Class created.
2.0     DPHA            2019-04-26          Modification after comment of FGOU, show only one Service Territory Member
3.0     DPHA            2019-04-30          Use tab instead of a button, so we don't use resource ID 
4.0     DPHA            2019-05-07          Modification after FGOU comment. Modification DebutPlanning and FinPlanning
*/

public class VF_FSL_SR_FromTerritoryController {

    //Contructeur pour afficher les ressources dans la page VisualForce
    public VF_FSL_SR_FromTerritoryController() 
    { 
        createResource();
    } 

    
    //Récupérer et paramétrer la valeur de la date de début d'édition
    public Date debutPlanning
    {
        get
        {
            if(debutPlanning == null)
            {
                debutPlanning = Date.today().addDays(1);                
            }
            return debutPlanning;
        }
        set;
    }
    
    
    //Récupérer et paramétrer la valeur de la date de fin d'édition
    public Date finPlanning
    {
        get
        {
            if(finPlanning == null)
            {
                finPlanning = Date.today().addDays(1);
            }
            return finPlanning;
        }
        set;
    }
    
    
    //Initialisation de la variable permettant de récupérer toutes les ressources cochées.
    public List<ServiceResourceCustom> listServiceResourceCustom {get; set;}
    
    
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
            //Récupération de l'identifiant de la ressource
            //String resourceId = ApexPages.currentPage().getParameters().get('idres');
            //Instantion de la liste à afficher
            listServiceResourceCustom = new List<ServiceResourceCustom>();
            
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
        
            //Obtention des TerritoryMember associés au territoire + Vérifier les conditions avec Sonia
            List<ServiceTerritoryMember> stmChecked = new List<ServiceTerritoryMember>([SELECT  Id,
                                                                                                ServiceResourceId, 
                                                                                                ServiceTerritoryId,
                                                                                                EffectiveEndDate
                                                                                        FROM    ServiceTerritoryMember
                                                                                        WHERE   ServiceTerritoryId IN:idTer
                                                                                        AND     ((EffectiveEndDate = null) OR (EffectiveEndDate > TODAY))
                                                                                        AND     ServiceResource.IsActive = true]);   
        
            /****
            *
            *Correction pour n'afficher qu'une seule ressource au lieu de plusieurs ServiceTerritory Member
            *
            ****/
            
            Set<Id> idRes = new Set<Id>();
            
            if(stmChecked != null)
            {
                for(ServiceTerritoryMember s : stmChecked)
                {
                    idRes.add(s.ServiceResourceId);
                }
            }
        
            List<ServiceResource> listOneServiceResource = new List<ServiceResource>([SELECT id, 
                                                                                             Name,
                                                                                             serviceTerritory__c,
                                                                                             serviceTerritory__r.Name, 
                                                                                             toLabel(job__c) 
                                                                                      FROM   ServiceResource 
                                                                                      WHERE  id IN:idRes 
                                                                                      AND    serviceTerritory__c IN:idTer
                                                                                      ORDER BY serviceTerritory__r.Name ASC, job__c ASC ,Name ASC ]);
        
            if(listOneServiceResource != null)
            {
                for(ServiceResource r : listOneServiceResource)
                {
                    ServiceResourceCustom myResource = new ServiceResourceCustom(r.Name, r.serviceTerritory__r.Name, r.job__c);
                    listServiceResourceCustom.add(myResource);
                    /*if(r.id == resourceId)
                    {
                        myResource.isSelected = true;  
                    }*/
                }
            }
    }
    
        
    //Redirection vers la page pour afficher la feuille de route 
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_FeuilleRoute';
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlRes = '';
        
        //Définition des dates 
        debutPlanning = this.debutPlanning;
        finPlanning = this.finPlanning;
        
        //Formation de l'URL avec les dates 
        link = link + '?start=' + debutPlanning + '&end=' + finPlanning;
        
        //Liste des ressources custo cochées
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