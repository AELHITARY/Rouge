//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : FieldServiceUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/10/2022
//-- Version     : 1.1
//-- Description : Field Service Lightning utils class
//-- --------------------------------------------------------------------------------- --
public class FieldServiceUtils {
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PRO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    
    //Service Territory Type
    public static final String FSL_TERRITORY_PRIMARY = 'P'; 
    public static final String FSL_TERRITORY_SECONDARY = 'S';
    
    // Contrôle de cohérence des dates de validité :
    //- la date de début de l'objet parent doit être antrieure ou égale à celle de l'enfant
    //- la date de fin de l'objet parent doit être ultérieure ou égale à celle de l'enfant    
    public static boolean crlCoherenceDate(Date debutParent, Date finParent, Date debutFils, Date finFils){
        Boolean coherence = true;
        
        if(finParent == null)
            finParent = Date.newInstance(2999, 12, 31);
        if(finFils == null)
            finFils = Date.newInstance(2999, 12, 31);
        if(debutFils < debutParent || finFils > finParent) 
            coherence = false;
        System.debug('########## DEBUG : debutParent = '+debutParent+' - finParent = '+finParent+' - debutFils = '+debutFils+' - finFils = '+finFils+' - Coherence = '+coherence );            
        return coherence;
        
    }
    
    public static boolean crlCoherenceDateTime(DateTime debutParent, DateTime finParent, DateTime debutFils, DateTime finFils){
        Boolean coherence = true;
        
        if(finParent == null){
            finParent = DateTime.newInstance(2999, 12, 31, 23, 59, 59);
        }
        else{
            finParent = DateTime.newInstance(finParent.DateGMT(),Time.newInstance(finParent.hourGMT(),finParent.minuteGMT(),00,00));
        }
        if(finFils == null){
            finFils = DateTime.newInstance(2999, 12, 31, 23, 59, 59);
        }
        else{
            finFils = DateTime.newInstance(finFils.DateGMT(),Time.newInstance(finFils.hourGMT(),finFils.minuteGMT(),00,00));
        }
        
        debutFils = DateTime.newInstance(debutFils.DateGMT(),Time.newInstance(debutFils.hourGMT(),debutFils.minuteGMT(),00,00));
        debutParent = DateTime.newInstance(debutParent.DateGMT(),Time.newInstance(debutParent.hourGMT(),debutParent.minuteGMT(),00,00));
        
        if(debutFils < debutParent || finFils > finParent) 
            coherence = false;
        
        System.debug('########## DEBUG : debutParent = '+debutParent+' - finParent = '+finParent+' - debutFils = '+debutFils+' - finFils = '+finFils+' - Coherence = '+coherence );            
        
        return coherence;
        
    }
    
    // Construire des map pour calculer le chiffre d'affaire des ressources  
    
    public static Map<ID, ServiceAppointment> construireMapServiceAppointment(List<AssignedResource> listeAssignedResource ){
        
        Set<ID> setSAId = new Set<ID>();
        
        for(AssignedResource tmpAR : listeAssignedResource){
            setSAId.add(tmpAR.ServiceAppointmentId);              
        } 
        
        Map<ID, ServiceAppointment> mapServiceAppointment = new Map<ID, ServiceAppointment>([SELECT id, SchedStartTime, SchedEndTime,
                                                                                             fsl_techOrdreExecutionParent__r.status,
                                                                                             fsl_techOrdreExecutionParent__r.fsl_chiffreAffaire__c
                                                                                             FROM ServiceAppointment 
                                                                                             WHERE id IN:setSAId]);
        return mapServiceAppointment;
    }
    
    
    
    public static Map<ID, ServiceResource> construireMapServiceResource(List<AssignedResource> listeAssignedResource){
        
        Set<ID> setSRId = new Set<ID>();
        
        for(AssignedResource tmpAR : listeAssignedResource){                    
            setSRId.add(tmpAR.ServiceResourceId);  
        } 
        
        Map<ID, ServiceResource> mapServiceResource = new Map<ID, ServiceResource>([SELECT id 
                                                                                    FROM ServiceResource 
                                                                                    WHERE id IN:setSRId]);    
        return mapServiceResource;
    }
    
    public static Map<ID,List<ServiceAppointment>> construireMapRessourceIdToListSA(List<AssignedResource> listeAssignedResource ){  
        
        Map<ID, ServiceAppointment> mapServiceAppointment = construireMapServiceAppointment(listeAssignedResource);
        
        Map<ID,List<ServiceAppointment>> mapRessourceIdToListSA = new Map<ID,List<ServiceAppointment>> ();
        
        for (AssignedResource ar : listeAssignedResource ){ 
            
            if(mapServiceAppointment.containsKey(ar.ServiceAppointmentId) && mapServiceAppointment.get(ar.ServiceAppointmentId).SchedStartTime != null){ 
                
                if(mapRessourceIdToListSA.containsKey(ar.ServiceResourceId)){
                    List<ServiceAppointment> listeSA = mapRessourceIdToListSA.get(ar.ServiceResourceId);
                    listeSA.add(mapServiceAppointment.get(ar.ServiceAppointmentId));                
                    mapRessourceIdToListSA.put(ar.ServiceResourceId, listeSA);
                }else {
                    mapRessourceIdToListSA.put(ar.ServiceResourceId, new List<ServiceAppointment> {mapServiceAppointment.get(ar.ServiceAppointmentId)});                            
                }      
            }        
        }
        return  mapRessourceIdToListSA;         
    }
    
    
    
    //Vérification des Date début et fin par rapport à la date actuelle 
    //pour activer/déactiver les types d'activités,les territoires, les horraires et les utilisateurs
    public static Boolean crlDesactivation(Date debut, Date fin, Boolean active){
        Boolean desactiver = null;
        if(debut != null && debut > System.today() && active == true ){
            desactiver = true;                
        }else if (fin != null && fin < System.today() && active == true ){
            desactiver = true;  
        }else if (active == false && debut != null && (debut < System.today() || debut == System.today()) && fin == null){
            desactiver = false;
        }else if (active == false && fin != null && (fin > System.today() || fin == System.today())){
            desactiver = false;
        }
        return desactiver;
    }
    
    //Méthodes utiles pour synchroniser GC et FSL via Platform Event
    
    //Créer le Map de ID Externe du WorkOrder par Workorder    
    public static Map<id,String> createMapExternalIdByWorkOrder(Set<String> WorkOrderIDs){
        Map<id,String> monMap = new Map<id,String>();
        list<WorkOrder> listeWO=[SELECT Id,fsl_externalId__c FROM WorkOrder WHERE Id in:WorkOrderIDs];
        for(WorkOrder wo:listeWO){
            monMap.put(wo.id,wo.fsl_externalId__c);
        }
        return monMap;
    }
    
    //Créer le Map de AssignedResource par ServiceAppointment    
    public static Map<ID,String> createMapRessource(Set<String> serviceAppointmentIDs){
        Map<ID,String> monMap = new Map<ID,String>();
        Map<ID, List<String>> mapRessource= new Map<ID, List<String>>();    
        
        // Pour chaque SA, ajout du dernier utilisateur ayant effectué la dernière modification
        List<ServiceAppointment> listSA = [SELECT Id, LastModifiedById, LastModifiedBy.Name, LastModifiedBy.sgid__c, LastModifiedBy.Matricule__c FROM ServiceAppointment WHERE Id IN :serviceAppointmentIDs];
        
        // Ajout des ressources
        List<AssignedResource> listAR = [SELECT ServiceAppointmentId,ServiceAppointment.parentRecordId, ServiceResource.name, ServiceResource.fsl_matriculeGC__c,ServiceResource.fsl_SGID__c FROM AssignedResource WHERE ServiceAppointmentid in :serviceAppointmentIDs];
        for (Id key:serviceAppointmentIDs){
            mapRessource.put(key,new List<String>());  
        }   
        for(AssignedResource ar:listAR){
            String ressource=ar.ServiceResource.fsl_matriculeGC__c +':'+ar.ServiceResource.fsl_SGID__c+':'+ar.ServiceResource.name;
            list<string> listeRessources= mapRessource.get(ar.ServiceAppointmentId);
            listeRessources.add(ressource);
            String champRessources = '';
            // LastModifiedBy user en premier
            for (ServiceAppointment sa : listSA){
                if(sa.Id == ar.ServiceAppointment.id)
                    champRessources += sa.LastModifiedBy.sgid__c+':'+sa.LastModifiedBy.Matricule__c+':'+sa.LastModifiedBy.Name+';';
            } 
            champRessources += String.join(listeRessources, ';');
            monMap.put(ar.ServiceAppointment.id,champRessources);
        } 
        return monMap;
    }   
    
    //Créer le Map de ParentWorkOrder par WorkOrder 
    public static Map<String, ID> createMapParentWorkOrder(set<string> setParentWorkOrder ){
        Map<String, ID> monMap = new Map<String, ID>();
        if (setParentWorkOrder.size()>0){
            List<WorkOrder> myParentWOs = [SELECT id, fsl_externalId__c FROM WorkOrder WHERE fsl_externalId__c IN :setParentWorkOrder];
            for (WorkOrder pwo: myParentWOs){
                monMap.put(pwo.fsl_externalId__c, pwo.Id);
            }            
            System.debug('***SET setParentWorkOrder '+ setParentWorkOrder+' - taille Liste PWO '+ myParentWOs.size() +' *****');
        }
        return monMap;
    }
    
    //Créer le Map de compte par WorkOrder 
    public static Map<String, Account> createMapAccount(set<string> setAccount ){
        Map<String, Account> result = new Map<String, Account>();
        for (Account acc: [SELECT Id, AccountNumber, numeroCompte__c, Name FROM Account 
                            WHERE numeroCompte__c IN :setAccount AND (RecordTypeId = :RT_ACC_PERSO OR RecordTypeId = :RT_ACC_PRO)]){
            result.put(acc.numeroCompte__c, acc);
        }        
        System.debug('***SET setAccount '+ setAccount+' - taille Liste Account '+ result.size() +' *****');
        
        Integer a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        return result;
    }
    
    //Créer le Map de Contrat par WorkOrder 
    public static Map<String, KContrat__c> createMapContrat(Set<string> setContrat ){
        Map<String, KContrat__c> result = new Map<String, KContrat__c>();
        for (KContrat__c ctr: [SELECT Id, compte__c, numeroContrat__c FROM KContrat__c WHERE numeroContrat__c IN :setContrat]){
            result.put(ctr.numeroContrat__c, ctr);
        }
        System.debug('***SET setContrat '+ setContrat+' - taille Liste Contrat '+ result.size() +' *****');
        return result;
    }
    
    //Créer le Map de chantier par compte 
    public static Map<String, Set<ID>> createMapChantier(Map<String, Account> mapAccountIDbyExternalId ){
        Map<String, Set<ID>> monMap = new Map<String, Set<ID>>();
        Set<ID> setAccountId = new Set<ID> ();
        for(Account acc : mapAccountIDbyExternalId.values()){
            setAccountId.add(acc.Id);
        }
        
        List<Chantier__c> myChantiers = [SELECT id, proprietaire__r.AccountNumber, proprietaire__r.numeroCompte__c FROM Chantier__c WHERE proprietaire__c IN : setAccountId];
        for (Chantier__c cht : myChantiers){
            if( monMap.containsKey(cht.proprietaire__r.numeroCompte__c)){
                Set<ID> setCht = monMap.get(cht.proprietaire__r.numeroCompte__c);
                setCht.add(cht.id);                
                monMap.put(cht.proprietaire__c, setCht);                
            }
            else {
                monMap.put(cht.proprietaire__r.numeroCompte__c,  new Set<ID> {cht.id});
            }
        }
        System.debug('***SET setAccount '+ mapAccountIDbyExternalId.values()+' - taille Liste Chantier '+ myChantiers.size() +' *****');
        System.debug('***MAP Chantiers '+ monMap+' *****');
        return monMap;
    }
    
    //Créer le Map de Type d'activité par WorkOrder 
    public static Map<String, ID> createMapWorkType(set<string> setWorkType ){
        Map<String, ID> monMap = new Map<String, ID>();
        List<WorkType> myWorkTypes = [SELECT id, name FROM WorkType WHERE name in :setWorkType];
        for (WorkType wt: myWorkTypes){
            monMap.put(wt.name, wt.Id);
        }
        System.debug('***SET setWorkType '+ setWorkType+' - taille Liste WT '+ myWorkTypes.size() +' *****');
        return monMap;
    }
    
    //Créer le Map de territoire par WorkOrder 
    public static Map<String, ID> createMapServiceTerritory(set<string> setServiceTerritory ){
        Map<String, ID> monMap = new Map<String, ID>();
        List<ServiceTerritory> myServiceTerritories = [SELECT id, KparKReference__c FROM ServiceTerritory WHERE KparKReference__c in :setServiceTerritory];
        for (ServiceTerritory st: myServiceTerritories){
            monMap.put(st.KparKReference__c, st.Id);
        }
        System.debug('***SET setServiceTerritory '+ setServiceTerritory+' - taille Liste ST '+  myServiceTerritories.size() +' *****');
        return monMap;
    }    
    
    //Créer le Map de WorkOrder par son Id Externe 
    public static Map<String, ID> createMapWorkOrderIDbyExternalId(List<WorkOrder> listeWorkOrders){       
        Map<String, ID> monMap = new Map<String, ID>();
        for (WorkOrder wo: listeWorkOrders){
            monMap.put(wo.fsl_externalId__c, wo.Id);
        } 
        return monMap;
    }
    
    //Créer le Map de skill par son nom
   public static Map<String, ID> createMapSkillIdByName(List<DemandeRDV__e> listeDemandesRDV){
        Set<String> skillNames = new Set<String>();
        for (DemandeRDV__e event : listeDemandesRDV) {              
            if (event.fsl_skillExternal__c != null){
                List<String> skills= new List<String>();                 
                skills = event.fsl_skillExternal__c.split(';');                   
                for(integer i=0; i < skills.size(); i++) {    
                    String skillname = skills[i].substringBefore(':'); 
                    skillNames.add(skillname);
                } 
            }  
        }
        Map<String, id> monMap= new Map<String,id>();
        List<Skill> mySkills= [SELECT id, DeveloperName FROM skill WHERE DeveloperName in:skillNames];                 
        For (Skill sk : mySkills){
            monMap.put(sk.DeveloperName,sk.id);
        }
        return monMap;
    }
    
    //Créer le Map de resource par son matricule
    
    public static Map<String, ID> createMapResourceIdByMatricule(List<DemandeRDV__e> listeDemandesRDV){
        Set<String> resourceMatricules = new Set<String>();
        for (DemandeRDV__e event : listeDemandesRDV) {              
            if (event.fsl_RessourcesObligatoires__c != null){
                List<String> resources = new List<String>();                 
                resources = event.fsl_RessourcesObligatoires__c.split(';');             
                for(integer i=0; i < resources.size(); i++) {    
                    String resourcematricule = resources[i].substringBefore(':'); 
                    resourceMatricules.add(resourcematricule);
                } 
            }
            if (event.fsl_RessourcesRecommandees__c != null){
                List<String> resources = new List<String>();                 
                resources = event.fsl_RessourcesRecommandees__c.split(';');             
                for(integer i=0; i < resources.size(); i++) {    
                    String resourcematricule = resources[i].substringBefore(':'); 
                    resourceMatricules.add(resourcematricule);
                } 
            }  
            if (event.fsl_RessourcesInterdites__c != null){
                List<String> resources = new List<String>();                 
                resources = event.fsl_RessourcesInterdites__c.split(';');             
                for(integer i=0; i < resources.size(); i++) {    
                    String resourcematricule = resources[i].substringBefore(':'); 
                    resourceMatricules.add(resourcematricule);
                } 
            }  
        }
        Map<String, id> monMap= new Map<String,id>();
        List<ServiceResource> myResources= [SELECT id, fsl_matriculeGC__c FROM ServiceResource WHERE fsl_matriculeGC__c in:resourceMatricules];                 
        For (ServiceResource sres : myResources){
            monMap.put(sres.fsl_matriculeGC__c,sres.id);
        }
        return monMap;
    }
    
    //Transformer les string dates sous forme de 'jj/mm/aaa hh:mm:ss' en date Salesforce
   public static Datetime conversionStringDate(string inputDate, DemandeRDV__e event,GlobalProperties__c emailException){     
        DateTime outputDate = null;
        try {             
            String stringDate = inputDate.substring(6,10) + '-' + inputDate.substring(3,5) + '-' + inputDate.substring(0,2) + ' ' + inputDate.substring(11,19);
            outputDate = datetime.valueOf(stringDate);
            
        } catch (Exception e) {
            System.debug('**Erreur input Date**'+e.getMessage());
            //Envoyer des erreurs au responsable par email    
            serviceEmailAlert(e,null,'Erreur de conversion des dates via Platform Event',event,null,emailException);
        }               
        
        return outputDate;
    }
    
    //Transformer les dates Salesforce en string date sous forme de 'jj/mm/aaa hh:mm:ss'    
    public static String ConversionDateString(DateTime inputDate){  
        String outputDate = null;
        try {             
            String stringdate = String.valueOf(inputDate);
            outputDate = stringdate.substring(8,10) + '/' + stringdate.substring(5,7) + '/' + stringdate.substring(0,4) + ' ' + stringdate.substring(11,19);
            
        }catch (Exception e) {
            System.debug('**Erreurs output Date**'+e.getMessage());
        }               
        return outputDate;
    }
    
    //--Envoyer Email au responsable PlatformEvent
    public static void serviceEmailAlert(Exception e,Database.Error err,String subject,DemandeRDV__e eventDemande,SuppressionRDV__e eventSuppression,
                                            GlobalProperties__c emailException){
        
        String eventStr = '';           
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();          
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
        List<String> sendTo = emailException.stringValue__c.split(';');                 
        mail.setToAddresses(sendTo);                          
        mail.setReplyTo('FieldServiceLightning@salesforce.com');
        mail.setSenderDisplayName('Field Service Lightning');                                         
        mail.setSubject(subject);
        if (eventDemande != null){
            eventStr = 'WorkOrder External Id = '+ eventDemande.fsl_externalId__c+'<br/>'+
                'Contrat External Id = '+ eventDemande.fsl_contratKExternal__c+'<br/>'+
                'Account External Id = '+ eventDemande.fsl_accountExternal__c+'<br/>'+
                'Parent WorkOrder ExternalId = ' + eventDemande.fsl_parentWorkOrderExternal__c+'<br/>'+
                'WorkType Id  = ' + eventDemande.fsl_workTypeExternal__c+'<br/>'+
                'ServiceTerritory Id  = ' + eventDemande.fsl_serviceTerritoryExternal__c +'<br/>'+ 
                'Au plus tôt  = ' + eventDemande.fsl_startDate__c +'<br/>'+   
                'Au plus tard  = ' + eventDemande.fsl_endDate__c +'<br/>'+   
                'Duration  = ' + eventDemande.fsl_duration__c+'<br/>'+
                'DurationType  = ' + eventDemande.fsl_durationType__c+'<br/>'+
                'fsl_nombreIntervenants__c  = ' + eventDemande.fsl_nombreIntervenants__c+'<br/>'+
                'fsl_chiffreAffaire__c  = ' + eventDemande.fsl_chiffreAffaire__c+'<br/>'+
                'fsl_montantAttendu__c = '+ eventDemande.fsl_montantAttendu__c+'<br/>'+
                'fsl_documentsAttendus__c = '+ eventDemande.fsl_documentsAttendus__c+'<br/>'+
                'Subject = '+ eventDemande.fsl_subject__c+'<br/>'+
                'Priority = '+ eventDemande.fsl_priority__c+'<br/>'+
                'Street = '+ eventDemande.fsl_street__c+'<br/>'+
                'PostalCode = '+ eventDemande.fsl_postalCode__c+'<br/>'+
                'City = '+ eventDemande.fsl_city__c+'<br/>'+
                'State = '+ eventDemande.fsl_state__c+'<br/>'+
                'Country = '+ eventDemande.fsl_country__c+'<br/>'+
                'Skills = '+ eventDemande.fsl_skillExternal__c+'<br/>'+
                'fsl_MontantContrat__c = '+ eventDemande.fsl_MontantContrat__c+'<br/>'+
                'fsl_SoldeClient__c = '+ eventDemande.fsl_SoldeClient__c+'<br/>'+
                'fsl_homephone__c = '+ eventDemande.fsl_homephone__c+'<br/>'+
                'fsl_mobilephone__c = '+ eventDemande.fsl_mobilephone__c+'<br/>'+
                'fsl_RessourcesInterdites__c = '+ eventDemande.fsl_RessourcesInterdites__c+'<br/>'+
                'fsl_RessourcesObligatoires__c = '+ eventDemande.fsl_RessourcesObligatoires__c+'<br/>'+
                'fsl_RessourcesRecommandees__c = '+ eventDemande.fsl_RessourcesRecommandees__c+'<br/>';
        }
        if (eventSuppression != null)
            eventStr = 'WorkOrder External Id = '+ eventDemande.fsl_externalId__c+'<br/>';
        
            
        String message = '';
        if (e != null) {
            System.debug('## FieldServiceUtils.serviceEmailAlert: ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            message = e.getMessage();
        }
        if (err != null) {
            System.debug('## FieldServiceUtils.serviceEmailAlert: ' + err.getMessage());
            message = err.getMessage();
        }
        String body = eventStr+'<br/><br/><br/> Problème : '+message+'<br/>';                               
        mail.setHtmlBody(body);                            
        mails.add(mail); 
        if (Test.isRunningTest())
            return;
        if(emailException.actif__c)
            Messaging.sendEmail(mails);  
    }
    
    // récupération des valeurs GlobalProperties
    public static GlobalProperties__c getGlobalPropertiesValue(String name) {
        GlobalProperties__c properties = GlobalProperties__c.getInstance(name);  
        
        if (properties!= null )
            return properties;
        else 
            throw new FieldServiceException();
    }    
    
    
    // Remplace arg1 avec arg2, si arg1 est null
    public static Datetime replaceIfNull(Datetime s1,Datetime s2) {
        Datetime result = s1;
        if (s1 == null) { result = s2; }
        return result;
    }
    
    // Renvoie la liste des IDs correspondant à la liste d'objets en paramètre
    public static List<Id> getIdList(List<sObject> objectList) {
        List<sObject> objectListID = new List<sObject>();
        for (sObject obj : objectList){
            if (obj.ID != null)
                objectListID.add(obj);
        }
        return new List<Id>(new Map<Id, sObject>(objectListID).keySet());
    }
    
    // Renvoie la Map correspondant à la liste d'objets en paramètre
    public static Map<Id, sObject> getObjectMap(List<sObject> objectList) {
        List<sObject> objectListID = new List<sObject>();
        for (sObject obj : objectList){
            if (obj.ID != null)
                objectListID.add(obj);
        }
        return new Map<Id, sObject>(objectListID);
    }
    
    // Renvoie une Map dont la clé est un user ID
    public static Map<Id, String> getMapByUserId(List<PermissionSetAssignment> objectList) {
        Map<Id, String> permissionMap = new Map<Id, String>();
        for (PermissionSetAssignment obj : objectList){
            if (obj.ID != null){
                if (permissionMap.containsKey(obj.assigneeId))
                    permissionMap.put(obj.assigneeId,(permissionMap.get(obj.assigneeId)+'/'+obj.ID));
                else
                    permissionMap.put(obj.assigneeId,''+obj.ID);
            }
        }
        return permissionMap;
    }
    
    // Renvoie une Map dont la clé est un user ID et la valeur un GroupMember
    public static Map<Id, GroupMember> getMapGroupByUserId(List<GroupMember> objectList) {
        Map<Id, GroupMember> grpMemMap = new Map<Id, GroupMember>();
        for (GroupMember obj : objectList){
            if (obj.ID != null){
                if (!grpMemMap.containsKey(obj.UserOrGroupId))
                    grpMemMap.put(obj.UserOrGroupId,obj);
            }
        }
        return grpMemMap;
    }
    
    // Renvoie une Map dont la clé est un user ID et la valeur un User
    public static Map<Id, User> getMapUserId(List<User> objectList) {
        Map<Id, User> userMap = new Map<Id, User>();
        for (User obj : objectList){
            if (obj.ID != null){
                if (!userMap.containsKey(obj.ID))
                    userMap.put(obj.ID,obj);
            }
        }
        return userMap;
    }
    
    // Récupération de la liste des profondeurs de calcul du CA par métier
    public static Map<String,String> getProfondeurMap() {
        Map<String,String> allProfondeurMap = new Map<String,String>();
        
        for (Mapping__c mapping : [SELECT ConvertedValue__c, PickValue__c FROM Mapping__c 
                                   WHERE name like 'FSLMetierProfondeurCA%' limit 1000]){
                                       allProfondeurMap.put(mapping.PickValue__c,mapping.ConvertedValue__c);                              
                                   }
        return allProfondeurMap;
    }
    
    // Gestion d'actions sur la base de données
    public static FieldServiceError databaseAction(String action, String tableName, List<sObject> recordList) {
        FieldServiceError errorList = new FieldServiceError();
        try {
            System.debug('################## DEBUG - Action "'+action+'" sur la table "'+tableName+ '" demandée');
            Database.SaveResult[] srList ;
            Database.UpsertResult[] srUpList ;
            Database.DeleteResult[] srDelList ;
            if (action.equals('insert')){
                srList = Database.insert(recordList,false);
            }
            else if (action.equals('upsert')){
                srUpList = Database.upsert(recordList,false);
            }
            else if (action.equals('update')){
                srList = Database.update(recordList,false);
            }
            else if (action.equals('delete')){
                srDelList = Database.delete(recordList,false);
            }
            
            // Récupération des erreurs lors des actions insert/update
            if(srList != null){
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {        
                        System.debug('################## DEBUG - Action "'+action+'" sur la table "'+tableName+ '" est en échec !');
                        errorList.addDMLError(sr.getErrors(),action +' '+tableName);
                        System.debug('***DEBUG INSERT'+ sr.getErrors());
                    }
                }
            }
            // Récupération des erreurs lors des actions upsert
            if(srUpList != null){
                for (Database.UpsertResult sr : srUpList) {
                    if (!sr.isSuccess()) {        
                        System.debug('################## DEBUG - Action "'+action+'" sur la table "'+tableName+ '" est en échec !');
                        String subject = 'Erreur Action '+action+' sur la table '+tableName;
                        errorList.addDMLError(sr.getErrors(),action +' '+tableName);
                        System.debug('***DEBUG UPSERT'+ sr.getErrors());
                    }
                }
            }
            // Récupération des erreurs lors des actions delete  
            if(srDelList != null){               
                for (Database.DeleteResult sr : srDelList) {
                    if (!sr.isSuccess()) {        
                        System.debug('################## DEBUG - Action "'+action+'" sur la table "'+tableName+ '" est en échec !');
                        String subject = 'Erreur Action '+action+' sur la table '+tableName;
                        errorList.addDMLError(sr.getErrors(),action +' '+tableName);
                    }
                }  
            }
        } catch (Exception e){
            System.debug('################## DEBUG - Action "'+action+'" sur la table "'+tableName+ '" est en échec : '+e.getMessage());
            String subject = 'Erreur Action '+action+' sur la table '+tableName;
            errorList.addExeptionError(e,action +' '+tableName);
        }
        return errorList;
        
    }
    
    // Récupération de toutes les permissions dédiées aux utilisateurs FSL
    public static Map<String,Id> getFslAutorisationMap() {
        Map<String,Id> allAutorisationMap = new Map<String,Id>();
        
        for (PermissionSet perm : [SELECT Id, Name FROM PermissionSet 
                                   WHERE  name like 'FSL%']){
                                       allAutorisationMap.put(perm.Name,perm.id);                              
                                   }
        return allAutorisationMap;
    }
    
    // Récupération de tous les profils dédiés aux utilisateurs FSL
    public static Map<String,Id> getFslProfileMap() {
        Map<String,Id> allProfileMap = new Map<String,Id>();
        
        for (Profile prf : [SELECT Id, Name FROM Profile WHERE  name like '%FSL%']){           
            allProfileMap.put(prf.Name,prf.id);                              
        }        
        return allProfileMap;
    }
    
    // Récupération de toutes les autorisations dédiées aux utilisateurs FSL dans une Map
    public static Map<String, List<ID>> loadFslAutorisationMap(String typeAutorisation) {
        Map<String,List<ID>> autorisationMap = new Map<String,List<ID>>();
        Map<String,ID> allAutorisationMap = getFslAutorisationMap();
        
        String newSearchText = '%'+typeAutorisation+'%';
        if(allAutorisationMap != null && allAutorisationMap.size() > 0){
            for (Mapping__c mapping : [SELECT  PickValue__c, ConvertedValue__c FROM mapping__c 
                                       WHERE Repository__c = 'FSLAutorisation' and ConvertedValue__c like :newSearchText order by PickValue__c limit 1000]) 
            {
                if (autorisationMap.containsKey(mapping.PickValue__c) && allAutorisationMap.containsKey(mapping.ConvertedValue__c)){ 
                    autorisationMap.get(mapping.PickValue__c).add(allAutorisationMap.get(mapping.ConvertedValue__c));  
                }
                else if (allAutorisationMap.containsKey(mapping.ConvertedValue__c)){
                    autorisationMap.put(mapping.PickValue__c, new List<ID> {allAutorisationMap.get(mapping.ConvertedValue__c)});
                }   
            }
        }
        return autorisationMap;
    }
    
    // Récupération de tous les profils dédiés aux utilisateurs FSL dans une Map
    public static Map<String,ID> loadFslProfileMap() { 
        Map<String,ID> profileMap = new Map<String,ID>();
        Map<String,ID> allProfileMap = getFslProfileMap();       
        if(allProfileMap != null && allProfileMap.size() > 0){           
            for (Mapping__c mapping : [SELECT  PickValue__c, ConvertedValue__c FROM mapping__c  WHERE Repository__c = 'FSLProfil' limit 1000]) {
                if (allProfileMap.containsKey(mapping.ConvertedValue__c)){                     
                    profileMap.put(mapping.PickValue__c, allProfileMap.get(mapping.ConvertedValue__c));
                }   
            }
        }
        return profileMap;
    }    
    
    //--Envoyer Email au responsable Génération des users
    public static void serviceEmailAlertGenRess(String subject, FieldServiceError  errList, GlobalProperties__c emailException){
        
        if ( errList != null && (errList.errorDML != null || errList.errorException != null)){
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();          
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
            List<String> sendToList = emailException.stringValue__c.split(';');                 
            mail.setToAddresses(sendToList);                          
            mail.setReplyTo('FieldServiceLightning@salesforce.com');
            mail.setSenderDisplayName('Field Service Lightning');                                         
            mail.setSubject(subject);
            
            String message = errList.getMessage();
            String body = ' Liste des erreurs : \n'+message+' \n';                               
            mail.setPlainTextBody(body);                            
            mails.add(mail); 
            if (Test.isRunningTest())
            return;
            if(emailException.actif__c)
                Messaging.sendEmail(mails);  
        }
    }
    
    public static Date calculDebutCalendarService(){        
        
        Date debutService = null;
        
        Period periodeFiscal1 = [SELECT Id, StartDate, EndDate, PeriodLabel, FiscalYearSettings.Name FROM Period WHERE type = 'Month' and (StartDate < today or StartDate = today) and (EndDate > today or EndDate = today) LIMIT 1 ];
        Period periodeFiscal2 = [SELECT Id, StartDate, EndDate, PeriodLabel, FiscalYearSettings.Name FROM Period WHERE type = 'Month' and (StartDate < tomorrow or StartDate = tomorrow) and (EndDate > tomorrow or EndDate = tomorrow) LIMIT 1 ];
        
        if (periodeFiscal1.Id == periodeFiscal2.Id){
            debutService = periodeFiscal1.StartDate.addDays(-1);         
        }else{
            debutService = periodeFiscal2.StartDate.addDays(-1);           
        }
        return debutService;
    } 
    
    public static Date calculFinCalendarService(Integer profondeur){   
        
        Date finService = null;
        
        Period periodeFiscal1 = [SELECT Id, Number, StartDate, EndDate, FiscalYearSettingsId FROM Period WHERE type = 'Month' and (StartDate < today or StartDate = today) and (EndDate > today or EndDate = today) LIMIT 1 ];
        Period periodeFiscal2 = [SELECT Id, Number, StartDate, EndDate, FiscalYearSettingsId FROM Period WHERE type = 'Month' and (StartDate < tomorrow or StartDate = tomorrow) and (EndDate > tomorrow or EndDate = tomorrow) LIMIT 1 ];
        
        if (periodeFiscal1.Id == periodeFiscal2.Id){ 
            if(profondeur==1)
                finService = periodeFiscal1.EndDate.addDays(-1); 
            if(profondeur==3){
                Integer numPeriod1 = periodeFiscal1.Number + 2;
                period periodeFiscal3 = [SELECT Id, StartDate, EndDate FROM Period WHERE type = 'Month' and Number =:numPeriod1 and FiscalYearSettingsId = :periodeFiscal1.FiscalYearSettingsId ];
                finService = periodeFiscal3.EndDate.addDays(-1);
            }
            
        }else{
            if(profondeur==1)
                finService = periodeFiscal2.EndDate.addDays(-1);   
            if(profondeur==3){
                Integer numPeriod2 = periodeFiscal2.Number + 2;
                period periodeFiscal4 = [SELECT Id, StartDate, EndDate FROM Period WHERE type = 'Month' and Number =:numPeriod2 and FiscalYearSettingsId = :periodeFiscal2.FiscalYearSettingsId ];
                finService = periodeFiscal4.EndDate.addDays(-1);
            }
        }
        
        return finService;
    }
    
    public static Boolean ifInPeriodeCalendarService(Date datePlanif, Date debutPeriode,Date finPeriode){  
        Boolean isInPeriode;
        if(datePlanif == debutPeriode || datePlanif == finPeriode || (datePlanif > debutPeriode && datePlanif < finPeriode))
            isInPeriode = true;
        if(datePlanif < debutPeriode || datePlanif > finPeriode)
            isInPeriode = false;
        return isInPeriode;
    }
    
    public static Date definirFinPeriodeSelonProfondeur(Decimal profondeur, Date finUnePeriode,Date finTroisPeriodes){  
        Date finPeriode;
        if(profondeur == 1 )
            finPeriode = finUnePeriode;
        if(profondeur == 3 )
            finPeriode = finTroisPeriodes;
        return finPeriode;
    }
}