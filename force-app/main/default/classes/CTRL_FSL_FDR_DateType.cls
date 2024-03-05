/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-05          Class created. New version of the "Feuille de route". Parameter : Date and Type of resources
2.0     DPHA            2019-07-30          Modification parameter : Type
*/

public class CTRL_FSL_FDR_DateType {
    
    //Constructeur
    public CTRL_FSL_FDR_DateType()
    {
        createDateTypePage();
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
    
    //Variable renvoyée si la date de début et de fin est la même 
    public String sameDate {get; set;}
    
    
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
    
    
    //Création des options à renvoyer pour les types de ressources 
    @TestVisible
    private List<TypeResourceCustom> createTypeResourceCustom()
    {
        //Instanciation de la variable
        listTypeRessourceCustom = new List<TypeResourceCustom>();
        
        //Création des ressource
        TypeResourceCustom responsable = new TypeResourceCustom('Responsable', 'RS~RSA~RM~RSAV~RESPONSABLE'); // TypeResourceCustom responsable = new TypeResourceCustom('Responsable', 'RS~RSA~RM~RSAV');
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
       
    
    //Création de la page
    @TestVisible
    private void createDateTypePage()
    {
        this.getTerritory();
        this.createTypeResourceCustom();
        this.checkDate();
    }
    
    
    //Redirection vers la page pour afficher la feuille de route 
    public PageReference displayPage() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_FDR_Resource';
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlRes = '';
        
        //Ajout dans l'URL des territoires
        String urlTer = ApexPages.currentPage().getParameters().get('listTer');
        
        //Formation de l'URL avec le territoire et les dates 
        link = link + '?listTer=' + urlTer + '&start=' + this.debutPlanning + '&end=' + this.finPlanning;
        
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
                urlRes = urlRes + lTypeSelected[i]+ '~'; 
            }
            link = link + '&type=' + urlRes;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    } 
}