/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-08          Class created. Parameter : Type Resource
*/

public class CTRL_FSL_AbsRec_TypeRes {

    //Constructeur
    public CTRL_FSL_AbsRec_TypeRes()
    {
        createPage();
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
    
    //Variable contenant le nom des territoires sélectionnés 
    public String nameTerritory{get; set;}
    
    //Initialisation de la variable permettant de récupérer le type
    public List<TypeResourceCustom> listTypeRessourceCustom {get; set;}
    
    
    //Création de l'objet custom
    public class TypeResourceCustom
    {
        public Boolean isSelected {get; set;}
        public String typeResource {get; set;}
        public String idType {get; set;}
        
        public TypeResourceCustom(String nameType, String keyWord)
        {
            isSelected = false;
            this.typeResource = nameType;
            this.idType = keyWord;
        }
    }
    
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
                else if (urlTypeAbs == 'ta10')
                {
                    typeAbs = 'Saisie de commandes';
                }
            }
            
            return typeAbs;
        }
    }
    
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
    
    //Variable contenant le nom des jours sélectionné 
    public String days {get; set;}
    
    
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
  
        List<ServiceTerritory> stChecked = new List<ServiceTerritory>([SELECT		Id, 
                                                                      		  		Name
                                                                       FROM			ServiceTerritory
                                                                       WHERE 		Id IN:idTer
                                                                       ORDER BY 	Name]);
        
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
    
    //Création des options à renvoyer pour les types de ressources 
    @TestVisible
    private List<TypeResourceCustom> createTypeResourceCustom()
    {
        //Instanciation de la variable
        listTypeRessourceCustom = new List<TypeResourceCustom>();
        
        //Création des ressource
        TypeResourceCustom responsable = new TypeResourceCustom('Responsable', 'RS~RSA~RM~RSAV');
        listTypeRessourceCustom.add(responsable);
        TypeResourceCustom metreur = new TypeResourceCustom('Métreur', 'METREUR');
        listTypeRessourceCustom.add(metreur);
        TypeResourceCustom posInt = new TypeResourceCustom('Poseur salarié', 'POSEUR INT.');
        listTypeRessourceCustom.add(posInt);
        TypeResourceCustom posExt = new TypeResourceCustom('Poseur sous-traitant', 'POSEUR EXT.');
        listTypeRessourceCustom.add(posExt);
        TypeResourceCustom tech = new TypeResourceCustom('Technicien SAV', 'TECH. SAV');
        listTypeRessourceCustom.add(tech);
        
        
        return listTypeRessourceCustom;
    }
    
    //Chargement de la page
    @TestVisible
    private void createPage()
    {
        this.getTerritory();
        this.getDays();
        this.createTypeResourceCustom();
    }
    
    //Redirection vers la page de sélection des ressources
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_AbsRec_Resource';
        //Lien à mettre à former et mettre en forme
        String urlTypeRes = '';
        
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
        
        
        //Formation de l'URL avec le territoire et les dates 
        link = link + '?listTer=' + urlTer + '&start=' + urlDateDebut + '&end=' + urlDateFin + /*'&action=' + urlAction +*/ '&days=' + urlDays 
               + '&freq=' + urlFreq + '&tabs=' + urlTabs + '&hdeb=' + urlHdeb + '&hfin=' + urlHfin + '&comm=' + urlComm;
        
        //Liste des types cochés
        List<String> lTypeSelected = new List<String>();

        if(this.listTypeRessourceCustom != null)
        {
            for(TypeResourceCustom trc : this.listTypeRessourceCustom)
            {
                if(trc.isSelected)
                {
                    lTypeSelected.add(trc.idType);
                }
            }            
        }
        
        //Formation de l'URL 
        if(lTypeSelected != null)
        {
            for(Integer i=0; i < lTypeSelected.size(); i++)
            {
                urlTypeRes = urlTypeRes + lTypeSelected[i]+ '~'; 
            }
            link = link + '&tres=' + urlTypeRes;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    } 
    
    
}