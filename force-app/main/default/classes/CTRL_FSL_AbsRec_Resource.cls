/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-08          Class created. Parameter :Resource
*/
public class CTRL_FSL_AbsRec_Resource {
    
    //Constructeur
    public CTRL_FSL_AbsRec_Resource()
    {
        createPage();
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

    //Heure de début
    public String heureDebut
    {
        get
        {
            String sheureDebut = ApexPages.currentPage().getParameters().get('hdeb');
            List<String> splitHeure = sheureDebut.split(':');
            String heure = splitHeure[0];
            String minute = splitHeure[1];
            
            String heureDebut = heure + 'h' + minute;
            
            return heureDebut;
        }
    }
    
    //Heure de fin
    public String heureFin
    {
        get
        {
            String sheureFin = ApexPages.currentPage().getParameters().get('hfin');
            List<String> splitHeure = sheureFin.split(':');
            String heure = splitHeure[0];
            String minute = splitHeure[1];
            
            String heureFin = heure + 'h' + minute;
            
            return heureFin;
        }
    }
    
    //Variable contenant le type de traitement à effectuer
    /*public String action 
    {
        get
        {
            //Instanciation de la variable 
            String action ='';
            
            //String qui contient la liste de territoire, à convertir en type liste
            String urlTypeAction = ApexPages.currentPage().getParameters().get('action');
            
            if(urlTypeAction != null)
            {
                if(urlTypeAction == 'C')
                {
                    action = 'Création d\'absences';
                }
                else
                {
                    action = 'Suppression d\'absences';
                }
            }
            
            return action;
        }
    }*/
    
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
    
    //Variable contenant le nom des territoires sélectionnés 
    public String nameTerritory{get; set;}
    
    //Frequence
    public String frequenceSelected
    {
        get
        {
            //Instanciation de la variable 
            String frequence ='';
            
            //String qui contient la liste de territoire, à convertir en type liste
            String urlFreq = ApexPages.currentPage().getParameters().get('freq');
            
            if(urlFreq != null)
            {
                if(urlFreq == 'none')
                {
                    frequence = 'Aucune';
                }
                else if( urlFreq == 'ts')
                {
                    frequence = 'Toutes les semaines';
                }
                else if( urlFreq == 'tss')
                {
                    frequence = 'Toutes les deux semaines';
                }
                else if( urlFreq == 'tsss')
                {
                    frequence = 'Toutes les trois semaines';
                }
                else if( urlFreq == 'tm')
                {
                    frequence = 'Toutes les quatre semaines';
                }
            }
            
            return frequence;
        }
    }
    
    //Type absence
    public String typeAbsSelected
    {
        get
        {
            //Instanciation de la variable 
            String typeAbs ='';
            
            //String qui contient la liste de territoire, à convertir en type liste
            String urlTypeAbs = ApexPages.currentPage().getParameters().get('tabs');
            
            if(urlTypeAbs != null)
            {
                if(urlTypeAbs == 'ta1')
                {
                    typeAbs = 'Férié';
                }
                else if( urlTypeAbs == 'ta2')
                {
                    typeAbs = 'Présence dépôt';
                }
                else if( urlTypeAbs == 'ta3')
                {
                    typeAbs = 'Rendez-vous société';
                }
                else if( urlTypeAbs == 'ta4')
                {
                    typeAbs = 'Indisponibilité poseur';
                }
                else if( urlTypeAbs == 'ta5')
                {
                    typeAbs = 'Réunion';
                }
                else if( urlTypeAbs == 'ta6')
                {
                    typeAbs = 'Formation';
                }
                else if( urlTypeAbs == 'ta7')
                {
                    typeAbs = 'Enregistrement contrat';
                }
                else if( urlTypeAbs == 'ta8')
                {
                    typeAbs = 'RTT';
                }
                else if( urlTypeAbs == 'ta9')
                {
                    typeAbs = 'Autre';
                }
                else if( urlTypeAbs == 'ta10')
                {
                    typeAbs = 'Saisie de commandes';
                }
            }
            
            return typeAbs;
        }
    }
    
    
    //Variable contenant le nom des jours sélectionné 
    public String days {get; set;}
    
    //Variable contenant le type de ressource sélectionné
    public String typeResource {get; set;}
    
    
    
    //Récupération du des jours 
    @TestVisible
    private String getDays()
    {
        this.days ='';
        
        //String qui contient la liste de territoire, à convertir en type liste
        String urlDays = ApexPages.currentPage().getParameters().get('days');
        String[] idDays = urlDays.split(', '); 
        List<String> dayChecked = new List<String>();
        
        if(idDays != null)
        {

                      
            if(idDays.contains('(L') || idDays.contains('(L)'))
            {
                String jour = 'Lundi';
                dayChecked.add(jour);
            } 
            if(idDays.contains('M') || idDays.contains('(M') || idDays.contains('(M)') || idDays.contains('M)') )
            {
                String jour = 'Mardi';
                dayChecked.add(jour);
            } 
            if(idDays.contains('Me') || idDays.contains('(Me') || idDays.contains('(Me)') || idDays.contains('Me)'))
            {
                String jour = 'Mercredi';
                dayChecked.add(jour);
            } 
            if(idDays.contains('J') || idDays.contains('(J') || idDays.contains('(J)') || idDays.contains('J)'))
            {
                String jour = 'Jeudi';
                dayChecked.add(jour);
            } 
            if(idDays.contains('V') || idDays.contains('(V') || idDays.contains('(V)') || idDays.contains('V)'))
            {
                String jour = 'Vendredi';
                dayChecked.add(jour);
            } 
            if(idDays.contains('S)') || idDays.contains('(S)'))
            {
                String jour = 'Samedi';
                dayChecked.add(jour);
            } 
        }
        
        //Création de la chaîne de caractères avec les noms de territoires 
        if(dayChecked != null)
        {
            for(String dc : dayChecked)
            {
                this.days = this.days + ' ' + dc + '   ';
            }
        }
        
        return this.days;
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
        String urlType = ApexPages.currentPage().getParameters().get('tres');
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
    
    //Création de la liste de Service Resource à afficher
    @TestVisible 
    private void createResource()
    {
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
        String urlType = ApexPages.currentPage().getParameters().get('tres');
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

    
    //Chargement de la page
    @TestVisible
    private void createPage()
    {
        this.getTerritory();
        this.getDays();
        this.getType();
        this.createResource();
    }
    
    
    //Redirection vers la page récapitulative
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_AbsRec_Recap';
        //Lien à mettre à former et mettre en forme
        String urlRes = '';
        
        //Liste des variables à ajouter dans l'URL
        String urlTer = ApexPages.currentPage().getParameters().get('listTer');
        String urlDateDebut = ApexPages.currentPage().getParameters().get('start');
        String urlDateFin = ApexPages.currentPage().getParameters().get('end');
        //String urlAction = ApexPages.currentPage().getParameters().get('action');
        String urlDays = ApexPages.currentPage().getParameters().get('days');
        String urlFreq= ApexPages.currentPage().getParameters().get('freq');
        String urlTabs = ApexPages.currentPage().getParameters().get('tabs');
        String urlHdeb = ApexPages.currentPage().getParameters().get('hdeb');
        String urlHfin = ApexPages.currentPage().getParameters().get('hfin');
        String urlComm = ApexPages.currentPage().getParameters().get('comm');
        //String urlTypeRes = ApexPages.currentPage().getParameters().get('tres');
        
        
        //Formation de l'URL avec le territoire et les dates 
        link = link + '?listTer=' + urlTer + '&start=' + urlDateDebut + '&end=' + urlDateFin + /*'&action=' + urlAction +*/ '&days=' + urlDays 
               + '&freq=' + urlFreq + '&tabs=' + urlTabs + '&hdeb=' + urlHdeb + '&hfin=' + urlHfin + '&comm=' + urlComm ;
       
        
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
            link = link + '&lres=' + urlRes;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    } 

    
}