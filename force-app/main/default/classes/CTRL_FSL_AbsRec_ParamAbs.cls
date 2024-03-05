public class CTRL_FSL_AbsRec_ParamAbs{
    //Constructeur
    public CTRL_FSL_AbsRec_ParamAbs()
    {
        //radioSelected='C';
        createPageParam();
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
    public Time	heureDebut
    {
        get
        {
            if(heureDebut == null)
            {
                heureDebut = Time.newInstance(8, 0, 0, 0);           
            }
            return heureDebut;
        }
        
        set;
    }
    
    
    //Heure de fin
    public Time	heureFin
    {
        get
        {
            if(heureFin == null)
            {
                heureFin = Time.newInstance(12, 0, 0, 0);           
            }
            return heureFin;
        }
        
        set;
    }
    
    //Commentaire
    public String commentaire{get; set;}
    
    //Variable renvoyant le bouton radio précoché
    //public String radioSelected {get; set;}
    
    //Variable contenant les jours
    public List<String> lDays = new List<String>();
    
    //Variable contenant le nom des territoires sélectionnés 
    public String nameTerritory{get; set;}

    //Variable renvoyée si la date de début et de fin est la même 
    public String sameDate {get; set;}
    
    //Frequence
    public String frequenceSelected{get; set;}
    
    //Type absence
    public String typeAbsSelected{get; set;}
    
    //Variable contenant le nombre de jours entre la date de début et de fin 
    public Integer diffDebFin{
        get
        {
            Integer diffDebFin = this.debutPlanning.daysBetween(this.finPlanning);
            
            return diffDebFin;
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
    
    @TestVisible
    private String checkDate()
    {
        String deb = ApexPages.currentPage().getParameters().get('start');
        String fin = ApexPages.currentPage().getParameters().get('end');
        this.sameDate ='';
        
        if(deb == fin)
        {
            this.sameDate = 'hidden';
        }
        return this.sameDate;
    }
    
    
    public List<SelectOption> getDays()
    {
        List<SelectOption> days = new List<SelectOption>();        
        days.add(new SelectOption('L','Lundi'));
        days.add(new SelectOption('M','Mardi'));
        days.add(new SelectOption('Me','Mercredi'));
        days.add(new SelectOption('J','Jeudi'));
        days.add(new SelectOption('V','Vendredi'));
        days.add(new SelectOption('S','Samedi'));
        
        return days;
    }
    
    //Paramétrage de la liste des jours de la semaine
    public List<String> getlDays()
    {
        return lDays;
    }
    
    public void setlDays(List<String> lDays)
    {
        this.lDays = lDays;
    }
    
    
    //Création de la liste de Service Resource à afficher
    @TestVisible 
    private void createPageParam()
    {
        //Nom des territoires
        this.getTerritory();
        this.checkDate();
    }
    
    //Redirection vers la page suivante
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_AbsRec_TypeRes';
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlRes = '';
        
        //Liste des territoires 
        String listTer = ApexPages.currentPage().getParameters().get('listTer');
        
        //Formation de l'URL avec les dates 
        link = link + '?start=' + this.debutPlanning + '&end=' + this.finPlanning + /*'&action=' + this.radioSelected +*/ '&days=' + this.lDays 
               + '&freq=' + this.frequenceSelected + '&tabs=' + this.typeAbsSelected + '&hdeb=' + this.heureDebut + '&hfin=' + this.heureFin 
               + '&comm=' + this.commentaire + '&listTer=' + listTer;
    
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    }
}