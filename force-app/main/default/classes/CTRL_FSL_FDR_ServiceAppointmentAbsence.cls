//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : CTRL_FSL_FDR_ServiceAppointmentAbsence 
//-- Auteur      : CGI
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 06/06/2023
//-- Version     : 1.2
//-- 1.2 - Affichage du sous-type d'activité en complément du type
//-- 1.1 - Mise à jour pour Kube3
//-- 1.0 - Class created. New version of the "Feuille de route". Display : Service Appointment and Absences
//-- --------------------------------------------------------------------------------- --
public class CTRL_FSL_FDR_ServiceAppointmentAbsence {
    //Initialisation des MAP à renvoyer dans la page VF
    public Map<ServiceResource, Set<Date>> mapSrDate {get; set;}
    public Map<Date, List<ServiceAppointmentCustom>> mapDateSac {get; set;}
    //Liste des clés  de la MAP
    public Set<String> keys { get; set;}
    //Error
    public String error {get; set;}

    //Constructeur
    public CTRL_FSL_FDR_ServiceAppointmentAbsence() {
        //Création de la Map Resource / ServiceAppointmentCustom
        createMapResourceSac();
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
    
    /**
    * @description Création de la liste des ressources à afficher avec les RDV 
    */
    @TestVisible
    private void createMapResourceSac() {
        //Instanciation des variables 
        String rtRDVKube3 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
        mapSrDate = new Map<ServiceResource, Set<Date>>();
        mapDateSac = new Map<Date, List<ServiceAppointmentCustom>>();
        //Instanciation de la liste RDV et Absences à renvoyer
        List<ServiceAppointmentCustom> lServiceAppointmentCustom = new List<ServiceAppointmentCustom>();
        List<ServiceAppointment>  lServiceAppointment = new List<ServiceAppointment>();
        List<ResourceAbsence> lResourceAbsence = new List<ResourceAbsence>();
        
        keys= new Set<String>();
        error = '';
        
        //String qui contient ma liste d'éléments, à convertir en type liste + Alimentation de la MAP
        String urlRes = ApexPages.currentPage().getParameters().get('listResId');
        List<String> lIdRes = urlRes.split('-'); 
        
        if(lIdRes != null) {
            for(String iR : lIdRes) {
                iR.replaceAll('-','');
            }
        }
        
        //Récupération des dates
        List<Date> lDate = new List<Date>();
        lDate = this.getListDate();
        
        //Obtention de la liste des ressources dont l'ID est dans la liste
        List<ServiceResource> lServiceResource = new List<ServiceResource>();
        if(lIdRes != null) {
            lServiceResource = [SELECT Id, Name FROM ServiceResource WHERE IsActive = true AND Id IN :lIdRes];
        }
        
        //Sélection des ressources attribuées pour les RDV
        List<AssignedResource> lAr = new List<AssignedResource>();
        if(lServiceResource != null) {
            lAr = [SELECT  Id, ServiceResourceId, ServiceAppointmentId
                   FROM    AssignedResource WHERE   ServiceResourceId IN :lServiceResource
                   AND     fsl_typeRessourceAttribuee__c = 'Principale'];
        }
        
        //Liste ID de rdv
        Set<Id> saId = new Set<Id>();
        for(AssignedResource ar : lAr) {
            saId.add(ar.ServiceAppointmentId);
        }
        
        //Obtention des RDV
        if(saId != null){
            lServiceAppointment = [SELECT  Id, AppointmentNumber, fsl_externalId__c, Worktype.Name, fsl_techOrdreExecutionParent__r.subWorkType__c, Status, Subject,
                                           Duration, SchedStartTime, SchedEndTime, customerOrder__r.OrderNumber,
                                           fsl_chiffreAffaire__c, account__c, fsl_contactClient__c, fsl_SoldeClient__c, Street,
                                           City, Country, PostalCode, fsl_libelleDuree__c, fsl_homephone__c, fsl_mobilephone__c,
                                           Description, Latitude, Longitude, fsl_techDebutFenetre__c,
                                           fsl_techFinFenetre__c, ServiceNote, Contact.HomePhone, Contact.MobilePhone,
                                           fsl_techOrdreExecutionParent__r.fsl_chiffreAffaire__c, RecordTypeId
                                   FROM    ServiceAppointment 
                                   WHERE   Id IN: saId
                                   AND     Status != :Constants.RDV_FSL_DEMANDE
                                   AND     Status != :Constants.RDV_FSL_PLANIFIE
                                   AND     SchedStartTime >= :debutPlanning
                                   AND     SchedStartTime <= :finPlanning+1
                                   ORDER BY SchedStartTime];   
        }

        //Ajout des RDV dans la liste des RDV custom 
        if(lServiceAppointment != null) {
            Map<String, ServiceAppointmentCustom> mapDateSa = new Map<String, ServiceAppointmentCustom>();
            List<ServiceAppointmentCustom> lUniqueSac = new List<ServiceAppointmentCustom>();
            
            for(ServiceAppointment sa : lServiceAppointment) {
                for(AssignedResource ar : lAr){
                    if(ar.ServiceAppointmentId == sa.Id) {
                        String codeGC = (sa.RecordTypeId == rtRDVKube3) ? sa.customerOrder__r.OrderNumber : sa.fsl_externalId__c;
                        Decimal chiffreAffaire = (sa.RecordTypeId == rtRDVKube3) ? sa.fsl_techOrdreExecutionParent__r.fsl_chiffreAffaire__c : sa.fsl_chiffreAffaire__c;
                        
                        String typeAndSubType = sa.Worktype.Name;
                        if(sa.fsl_techOrdreExecutionParent__r.subWorkType__c != null) {
                            typeAndSubType += ' / ' + sa.fsl_techOrdreExecutionParent__r.subWorkType__c;
                        }
                        // Création de l'objet et ajout dans la liste
                        ServiceAppointmentCustom mySac = new ServiceAppointmentCustom(sa.AppointmentNumber, codeGC, sa.Subject, typeAndSubType,
                                                                              sa.fsl_libelleDuree__c, sa.Street, sa.PostalCode, sa.City, sa.Contact.HomePhone,
                                                                              sa.Contact.MobilePhone, sa.Status, chiffreAffaire, sa.fsl_SoldeClient__c,
                                                                              sa.Description, sa.ServiceNote, sa.fsl_techDebutFenetre__c, sa.fsl_techFinFenetre__c,
                                                                              sa.SchedStartTime, sa.SchedEndTime, ar.ServiceResourceId, 'SA');
                        lUniqueSac.add(mySac);
                    }
                }
            }
            
            if(lUniqueSac != null)
            {
                for(Integer i=0; i< lUniqueSac.size(); i++)
                {
                        /*if(mapDateSa.get(usac.schedStart) == null)
                        {
                            mapDateSa.put(usac.schedStart, usac);
                        }
                        else
                        {
                            if(mapDateSa.containsKey(usac.schedStart))
                            {
                                mapDateSa.put(usac.schedStart.addSeconds(1), usac);
                            }
                        }*/
                    mapDateSa.put(String.valueOf(lUniqueSac[i].schedStart)+ ' ' + i, lUniqueSac[i]);
                    
                }
            }
            
            if(mapDateSa != null)
            {
                for(ServiceAppointmentCustom sac : mapDateSa.values())
                {
                    lServiceAppointmentCustom.add(sac);
                }
            }
        }
        
        
        //Obtention des Absences 
        if(lIdRes != null)
        {
            lResourceAbsence = [SELECT  Id, 
                                        AbsenceNumber,
                                        Type,
                                        Description, 
                                        Start, 
                                        End,
                                        Resource.Id,
                                        Street, 
                                        Country,
                                        City,
                                        PostalCode,
                                        FSL__GanttLabel__c,
                                        duration__c,
                                        assignedResource__c
                              FROM      ResourceAbsence
                              WHERE     Resource.Id IN :lIdRes
                              AND       Start >= :debutPlanning
                              AND       Start <= :finPlanning+1 
                              AND       Type != 'Pause'
                              ORDER BY  Start];
        }
        
        //Ajout des Absences dans la liste des RDV custom
        if(lResourceAbsence != null)
        {
            for(ResourceAbsence ra : lResourceAbsence)
            {
                        ServiceAppointmentCustom mySac = new ServiceAppointmentCustom(ra.AbsenceNumber, ra.FSL__GanttLabel__c, '', ra.Type, ra.duration__c,
                                                                                      ra.Street, ra.PostalCode, ra.City, '', '', '', null, null, ra.Description, '',
                                                                                      null, null, ra.Start, ra.End, ra.ResourceId, 'ABS');
                        lServiceAppointmentCustom.add(mySac);
            }
        }
        
        
        //Tri des RDV
        lServiceAppointmentCustom = this.sortListServiceAppointmentCustom(lServiceAppointmentCustom);
        
        //Pour chaque RDV et chaque ressource j'alimente la MAP Date.RDV que je vais ensuite associer à la ressource. 
        for(ServiceResource sr : lServiceResource)
        {
            if(lServiceAppointmentCustom != null)
            {
                for(Date d : lDate){
                    for(ServiceAppointmentCustom sac : lServiceAppointmentCustom)
                    {
                        Date dateCompare = Date.newInstance(sac.schedStart.year(), sac.schedStart.month(), sac.schedStart.day());
                        
                        if(sr.id == sac.assignedResource && d == dateCompare){
                            //Alimentation des différentes MAP 
                            List<ServiceAppointmentCustom> lSac;
                            Set<Date> lDateSac;
                            
                            if(mapDateSac.get(d) != null)
                            {
                                lSac = mapDateSac.get(d);
                            }
                            else
                            {
                                lSac = new List<ServiceAppointmentCustom>();
                            }
                            
                            if(mapSrDate.get(sr) != null)
                            {
                                lDateSac = mapSrDate.get(sr);
                            }
                            else
                            {
                                lDateSac = new Set<Date>();
                            }
                            
                            lSac.add(sac);
                            lDateSac.add(d);
                            mapDateSac.put(d, lSac);
                            keys.add(sr.id);
                            mapSrDate.put(sr, lDateSac);
                        }
                    }
                }
            }
        }
        
        if(lServiceAppointmentCustom.size() == 0)
        {
            //Si il n'y a pas de RDV 
            error = 'AucunRDV';
        }
        
    }

    /**
    * @description Trier les RDV custom par ordre chronologique
    * @param lSac Liste des RDV à trier
    */
    @TestVisible
    private List<ServiceAppointmentCustom> sortListServiceAppointmentCustom(List<ServiceAppointmentCustom> lSac)
    {
        Map<String, ServiceAppointmentCustom> listUnsorted = new Map<String, ServiceAppointmentCustom>();
        Map<String, ServiceAppointmentCustom> listSacSorted = new Map<String, ServiceAppointmentCustom>();
        List<String> orderingList = new List<String>();
        List<ServiceAppointmentCustom> lSacSorted = new List<ServiceAppointmentCustom>();

        for(Integer i=0; i< lSac.size(); i++)
        {
            listUnsorted.put(String.valueOf(lSac[i].schedStart)+ ' ' + i, lSac[i]);
            
        }
        
        //Ajout de tous les éléments dans la liste et tri par date
        orderingList.addAll(listUnsorted.keyset());
        orderingList.sort();
        
        for(Integer i=0; i < orderingList.size(); i++)
        {
            listSacSorted.put(orderingList[i], listUnsorted.get(orderingList[i]));
        }
        
        lSacSorted = listSacSorted.values();
        return lSacSorted;    
    }
    
    /**
    * @description Récupération des objets clés qui seront utilisées pour afficher les paramètres de chaque ressources
    */
    public List<ServiceResource> getListServiceResource()
    {        
        keys = this.keys;
        
        //Liste Object  
        List<ServiceResource> listServiceResource = [SELECT Id, Name FROM ServiceResource WHERE Id IN: keys];                  
        return listServiceResource;
    }
    
    /**
    * @description Récupération des dates 
    */
    public List<Date> getListDate()
    {
        //Paramétrage des dates 
        Date debutPlanning = this.debutPlanning;
        Date finPlanning = this.finPlanning;
        Date finRebours = finPlanning;
        Date debutRebours = debutPlanning;
        List<Date> sampleDate = new List<Date>();
        
        //Alimentation des clés de la MAP  Date/RDV 
        while(debutRebours != (finPlanning+1))
        {
            sampleDate.add(debutRebours);
            debutRebours = debutRebours+1;
        }
        return sampleDate;
    }

    /**
    * @description Renvoie du logo KparK à partir des ressources statiques
    */
    public Id getLogoKparKId(){
        return DAL.getDocumentByName(Constants.KparK_logo_NB).id;
    }   
    
    //Creation d'un type de RDV particulier associant les informations des RDV et des Absences
    public class ServiceAppointmentCustom
    {
        public String saId {get; set;}
        public String codeGC {get; set;}
        public String subject {get; set;}
        public String typeSa {get; set;}
        public String duration {get; set;}
        public String adress {get; set;}
        public String postalCode {get; set;}
        public String city {get; set;}
        public String homePhone {get; set;}
        public String mobilePhone {get; set;}
        public String status {get; set;}
        public Decimal chiffreAffaire {get; set;}
        public Decimal solde {get; set;}
        public String description {get; set;}
        public String serviceNote {get; set;}
        public DateTime debutArrivee {get; set;}
        public DateTime finArrivee {get; set;}
        public DateTime schedStart {get; set;}
        public DateTime schedEnd {get; set;}
        public Id assignedResource {get; set;}
        public String idType {get; set;}
        
        public ServiceAppointmentCustom(String saId, String codeGC, String subject, 
                                        String typeSa, String duration, String adress, 
                                        String postalCode, String city, String homePhone, 
                                        String mobilePhone, String status, Decimal chiffreAffaire,
                                        Decimal solde, String description, String serviceNote, 
                                        DateTime debutArrivee, DateTime finArrivee, DateTime schedStart, 
                                        DateTime schedEnd, Id assignedResource, String idType)
        {
            this.saId = saId; 
            this.codeGC = codeGC;
            this.subject = subject; 
            this.typeSa = typeSa;
            this.duration = duration;
            this.adress = adress;
            this.postalCode = postalCode;
            this.city = city;
            this.homePhone = homePhone;
            this.mobilePhone = mobilePhone;
            this.status = status;
            this.chiffreAffaire = chiffreAffaire;
            this.solde = solde;
            this.description = description;
            this.serviceNote = serviceNote;
            this.debutArrivee = debutArrivee;
            this.finArrivee = finArrivee;
            this.schedStart = schedStart;
            this.schedEnd = schedEnd;
            this.assignedResource = assignedResource;
            this.idType = idType;
        }
    }
}