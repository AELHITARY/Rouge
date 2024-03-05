//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : CTRL_FSL_AbsRec_TerritoryDate 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 25/01/2021
//-- Version     : 1.1
//-- * 1.1 : Modification suite modification groupe public
//-- * 1.0 : Class created. Parameter : Territory + Date
//-- --------------------------------------------------------------------------------- --
public class CTRL_FSL_AbsRec_TerritoryDate {
    //Initialisation de la variable permettant de récupérer tous les territoires cochés
    public List<ServiceTerritoryCustom> listServiceTerritoryCustom { get; set;}
    
    /**
    * @description Création d'un objet Service Territory Custom permettant d'afficher 
    * la liste des territoires avec un bouton permettant de sélectionner tous les territoires si besoin.
    */
    public class ServiceTerritoryCustom
    {
        public String nameTerritory { get; set;}
        public Boolean isSelectedTerritory {get; set;}
        
        //Valeurs par défaut 
        public ServiceTerritoryCustom(String nameTerritory)
        {
            isSelectedTerritory = false;
            this.nameTerritory = nameTerritory;
        }
    }
    
    /**
    * @description Constructeur pour afficher la liste des Territoires selon l'utilisateur en cours
    */
    public CTRL_FSL_AbsRec_TerritoryDate()
    {
        createListTerritory();
    }
    
    /**
    * @description Récupérer et paramétrer la valeur de la date de début d'édition
    */
    public Date debutPlanning {
        get
        {
            if(debutPlanning == null)
            {
                debutPlanning = Date.today();           
            }
            return debutPlanning;
            
        }
        set;
    }
    
    /**
    * @description Récupérer et paramétrer la valeur de la date de fin d'édition
    */
    public Date finPlanning {
        get
        {
            if(finPlanning == null)
            {
                finPlanning = Date.today();
            }
            return finPlanning;
        }
        set;
    }
    
    /**
    * @description Affichage de la liste des territoires pour l'utilisateur en cours
    */
    @TestVisible
    private void createListTerritory()
    {
        //Instantiation de la variable
        listServiceTerritoryCustom = new List<ServiceTerritoryCustom>();
        
        //Récupération de la liste des territoires associé à l'user
        List<ServiceTerritory> lTerUser = new List<ServiceTerritory>(); 
        lTerUser = this.getServiceTerritoryUser();
        
        if(lTerUser != null)
        {
            for(ServiceTerritory t : lTerUser)
            {
                ServiceTerritoryCustom myTer = new ServiceTerritoryCustom(t.Name);    
                
                if(lTerUser.contains(t) && lTerUser.size() == 1){
                    myTer.isSelectedTerritory = true;
                }
                
                listServiceTerritoryCustom.add(myTer);
            }
        }
        
    }
    
    /**
    * @description Récupération de tous les territoires
    */
    @TestVisible 
    private List<ServiceTerritory> getTerritory()
    {
        List<ServiceTerritory> listTerritory = new List<ServiceTerritory>([SELECT  Id, 
                                                                                   Name 
                                                                           FROM    ServiceTerritory 
                                                                           WHERE   IsActive = true
                                                                           AND     ParentTerritoryId != null
                                                                           ORDER BY Name]);
        return listTerritory;
    }
    
    /**
    * @description Fonction permettant de créer la liste de tous les territoires pour l'utilisateur en cours
    */
    @TestVisible
    private List<ServiceTerritory> getServiceTerritoryUser() {        
        //Liste stockant les territoires associés à l'utilisateur
        List<ServiceTerritory> territory = new List<ServiceTerritory>();
        //Label à utiliser pour les vérifications 
        String idProfilAdmin = Label.FSL_FDR_idFullTerritory;
        List<String> labelPermissionSet = Label.FSL_FDR_Label_PermissionSet.split(';');
        Boolean checkPermissionSet = false; 
        
        //Récupérer l'ID de l'utilisateur en cours 
        Id userID = UserInfo.getUserId();     
        //Récupération du profil 
        Id profilUser = UserInfo.getProfileId();        
        
        //Récupération des Permission Set
        List<PermissionSetAssignment> permissionSetUser = new List<PermissionSetAssignment>([SELECT PermissionSet.Label, 
                                                                                                    PermissionSet.Name 
                                                                                             FROM   PermissionSetAssignment 
                                                                                             WHERE  AssigneeId = :userID]);
                                                                                             
        if(permissionSetUser.size()>0) {
            for(PermissionSetAssignment p : permissionSetUser){
                if(labelPermissionSet.contains(p.PermissionSet.Label)) {
                    checkPermissionSet = true;
                    break;
                }
            }  
        }
        
        //Récupération des groupes
        List<GroupMember> idGroupForUser = [SELECT  GroupId 
                                            FROM    GroupMember 
                                            WHERE   UserorGroupId =:userID];
        
        Set<Id> lGroupId = new Set<Id>();
        if(idGroupForUser.size()>0)  {
            for(GroupMember gm : idGroupForUser) {
                lGroupId.add(gm.GroupId);
            }
        }

        
        // Récupération des noms des groupes auxquels mon utilisateur appartient. 
        List<Group> groupNameForUser = [SELECT  Name
                                        FROM    Group 
                                        WHERE   Id IN :lGroupId];
        
        List<String> lNameGroup = new List<String>();
        if(groupNameForUser.size()>0) {
            for(Group g : groupNameForUser) {
                lNameGroup.add(g.Name);
            }
        }
        
        
        //Vérification et affichage des ressources
        //Si l'utilisateur est Administrateur Système ou si il possède un Permission Set FSL Admin alors j'affiche toute les ressources. 
        //Sinon je vérifie ses groupes et j'affiche uniquement la liste des territoires auxquels il appartient. 
        if(idProfilAdmin == profilUser || checkPermissionSet) {
             territory = this.getTerritory();
        } else {
            List<ServiceTerritory> listTerritory = this.getTerritory();
            
            for(ServiceTerritory t : listTerritory) {
                for(String groupName : lNameGroup) {
                    if(groupName.contains(t.Name)) {
                        territory.add(t);
                    }
                }
            }
        }
        return territory;
    }
    
    //Afficher le formulaire qui affiche uniquement les ressources sélectionnées parmi les territoires choisis. 
    public PageReference displayParam() {
        //Lien vers la même page avec l'ID des territoires en En-tête
        String link = '/apex/VF_FSL_AbsRec_ParamAbs';
        //Liste des territoires custo cochées
        List<String> lTerritoryCustomSelected = new List<String>();
        //Lien à mettre à former et mettre en forme (Liste des territoires)
        String urlTer = '';
        //Id des territoires 
        List<String> idTerritory = new List<String>();
        
        //Définition des dates 
        debutPlanning = this.debutPlanning;
        finPlanning = this.finPlanning;
        
        
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
                                                                         FROM   ServiceTerritory
                                                                         WHERE  IsActive = true
                                                                         AND    Name IN :lTerritoryCustomSelected]);  
        
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
            //Formation de l'URL avec le territoire et les dates 
            link = link + '?start=' + debutPlanning + '&end=' + finPlanning + '&listTer=' + urlTer;
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        return pr;
    }
    
}