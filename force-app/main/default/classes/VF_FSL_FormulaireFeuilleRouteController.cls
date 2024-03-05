/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-03-21          Class created.
2.0		DPHA			2019-04-09			Modification to input the territory first, and next the service resource
3.0		DPHA			2019-04-30			Modificaton to create a tab instead of a button
4.0		DPHA			2019-05-07			Modification after FGOU comment

*/
public class VF_FSL_FormulaireFeuilleRouteController {
    
    //Variable statiques Ressource 
    //String resourceId = ApexPages.currentPage().getParameters().get('id');
    
    //Contructeur pour afficher les ressources dans la page VisualForce
    public VF_FSL_FormulaireFeuilleRouteController() { 
    	createListTer();
    } 
    
    //Création de mon Service Territory Custom qui permettra d'afficher la liste avec case à cocher et territoires par défaut
    public class ServiceTerritoryCustom {
        public String nameTerritory {get; set;}
        public Boolean isSelectedTerritory {get; set;}
        
        //Valeurs par défaut 
        public ServiceTerritoryCustom(String nameTerritory){
            isSelectedTerritory = false;
            this.nameTerritory = nameTerritory;
        }
    }
    
    
    //Initialisation de la variable permettant de récupérer tous les territoires cochés
    public List<ServiceTerritoryCustom> listServiceTerritoryCustom {
        get;set;
    }
    
    //Fonction qui créer la liste 
    @TestVisible
    private void createListTer()
    {
        //Instantiation de la variable
        listServiceTerritoryCustom = new List<ServiceTerritoryCustom>();
        
        //Récupération de la liste des territoires 
        List<ServiceTerritory> lTer = new List<ServiceTerritory>();
        lTer = this.getTerritory();
        
        //Récupération de la liste des territoires associé à l'user
        List<ServiceTerritory> lTerUser = new List<ServiceTerritory>(); 
        lTerUser = this.getServiceTerritoryUser();
        
        //Création de la liste d'objet et check par défaut des territoires de l'utilisateur. 
        if(lTer != null)
        {
            for(ServiceTerritory t : lTer)
            {
                ServiceTerritoryCustom myTer = new ServiceTerritoryCustom(t.Name);
                
                if(lTerUser.contains(t)){
                    myTer.isSelectedTerritory = true;
                }
                
                listServiceTerritoryCustom.add(myTer);
            }
        }
    }
    
    //Récupération de tous les territoires
    @TestVisible 
    private List<ServiceTerritory> getTerritory(){
        List<ServiceTerritory> listTerritory = new List<ServiceTerritory>([SELECT  Id, 
                                                                                   Name 
                                                                           FROM    ServiceTerritory 
                                                                           WHERE   IsActive = true
                                                                           AND 	   ParentTerritoryId != null
                                                                           ORDER BY Name]);
        return listTerritory;
    }
    

    
    //Obtenir la liste des territoires théoriquement disponible uniquement pour l'utilisateur en cours
    @TestVisible
    private List<ServiceTerritory> getServiceTerritoryUser(){
        List<ServiceTerritory> territory = new List<ServiceTerritory>();
        
        //Récupérer l'ID de l'utilisateur en cours 
        Id userID = UserInfo.getUserId();
        
         //Récupération des groupes auxquels l'utilisateur appartient        
        List<GroupMember> idGroupForUser = [SELECT  GroupId 
                                            FROM    GroupMember 
                                            WHERE   UserorGroupId =:userID];
        
        Set<Id> lGroupId = new Set<Id>();
        if(idGroupForUser.size()>0)
        {
            for(GroupMember gm : idGroupForUser)
            {
                lGroupId.add(gm.GroupId);
            }
        }
        
        //Récupération des noms des groupes auxquels mon utilisateur appartient. 
        List<Group> groupNameForUser = [SELECT  Name
                                        FROM    Group 
                                        WHERE   Id IN :lGroupId];
        
        List<String> lNameGroup = new List<String>();
        
        if(groupNameForUser.size()>0)
        {
            for(Group g : groupNameForUser)
            {
                lNameGroup.add(g.Name);
            }
        }
        
        List<ServiceTerritory> listTerritory = this.getTerritory();
        
        //Pour chaque Territoire, si le nom du territoire est contenu dans le nom du groupe alors je l'ajoute à la liste à renvoyer
        for(ServiceTerritory t : listTerritory)
        {
            if(lNameGroup.contains(t.Name))
            {
                territory.add(t);
            }
        }
        
        return territory;
        
    }
    
    //Afficher le formulaire qui affiche uniquement les ressources sélectionnées parmi les territoires choisis. 
    public PageReference displayResource() {
        
        //Lien vers la même page avec l'ID des territoires en En-tête
        //String link = '/apex/VF_FSL_SR_FromTerritory?idres=' + this.resourceId ;
        String link = '/apex/VF_FSL_SR_FromTerritory?listTer=';
        //Liste des territoires custo cochées
        List<String> lTerritoryCustomSelected = new List<String>();
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlTer = '';
        //Id des territoires 
        List<String> idTerritory = new List<String>();
        
        
        //Définition des territoires sélectionnés 
        listServiceTerritoryCustom = this.listServiceTerritoryCustom;

        for(ServiceTerritoryCustom stc : listServiceTerritoryCustom)
        {
            if(stc.isSelectedTerritory){
                lTerritoryCustomSelected.add(stc.nameTerritory);
            }
        }
        
        //Obtention les ID des Territoires 
        List<ServiceTerritory> lTerChecked = new List<ServiceTerritory>([SELECT Id, 
                                                                         Name
                                                                         FROM 	ServiceTerritory
                                                                         WHERE 	IsActive = true
                                                                         AND 	Name IN :lTerritoryCustomSelected]);  

        if(lTerChecked != null)
        {
            for(ServiceTerritory ltc : lTerChecked)
            {
                idTerritory.add(ltc.id);
            }
        }
        
        //Formation de l'URL 
        if(idTerritory != null)
        {
            for(Integer i=0; i < idTerritory.size(); i++)
            {
                urlTer = urlTer + idTerritory[i] + '-'; 
            }
            //link = link + '&listTer=' + urlTer;
            link = link + urlTer;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        return pr;
    }
}