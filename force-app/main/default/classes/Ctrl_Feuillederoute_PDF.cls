//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Feuillederoute_PDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/03/2020
//-- Version     : 1.3
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Feuillederoute_PDF {
    public Date dateToday {get; set;}
    public String dateTodayFormated { get; set; }
    public String codeMagasin {get; set;}
    public List<User> vendeurForPDF {get; set;}
    public Boolean isDataAvailable {get; set;}
    public User actualUser { get; set; }
    public Map<User, List<Utils_Cartographie.ContratFDR>> posesVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> metragesVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> interventionsVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> r1Vendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> r2Vendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> rPlusVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.DotMap>> prospectionsVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> chantiersSansContratsVendeurs {get; set;}
    public Map<User, List<Utils_Cartographie.ContratFDR>> chantiersAvecContratsVendeurs {get; set;}
    public Map<User, Integer> posesSize {get; set;}
    public Map<User, Integer> metragesSize {get; set;}
    public Map<User, Integer> interventionSize {get; set;}
    public Map<User, Integer> r1Size {get; set;}
    public Map<User, Integer> r2Size {get; set;}
    public Map<User, Integer> rPlusSize {get; set;}
    public Map<User, Integer> prospectionsSize {get; set;}
    public Map<User, Integer> chantiersSansContratsSize {get; set;}
    public Map<User, Integer> chantiersAvecContratsSize {get; set;}
    public Map<User, Integer> informationsVendeurSize {get; set;}
    public Integer nbDisplayVendeur {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_Feuillederoute_PDF
    */
    public Ctrl_Feuillederoute_PDF() {
        // Init
        vendeurForPDF = new List<User>();
        posesVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        metragesVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        interventionsVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        r1Vendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        r2Vendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        rPlusVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        prospectionsVendeurs = new Map<User, List<Utils_Cartographie.DotMap>>();
        chantiersSansContratsVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        chantiersAvecContratsVendeurs = new Map<User, List<Utils_Cartographie.ContratFDR>>();
        posesSize = new Map<User, Integer>();
        metragesSize = new Map<User, Integer>();
        interventionSize = new Map<User, Integer>();
        r1Size = new Map<User, Integer>();
        r2Size = new Map<User, Integer>();
        rPlusSize = new Map<User, Integer>();
        prospectionsSize = new Map<User, Integer>();
        chantiersSansContratsSize = new Map<User, Integer>();
        chantiersAvecContratsSize = new Map<User, Integer>();
        informationsVendeurSize = new Map<User, Integer>();
        isDataAvailable = false;
        codeMagasin = '';
        nbDisplayVendeur = 0;

        actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, profile.Name, IsActive
                        FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true];

        // Date du jour
        dateToday = Date.today();
        dateTodayFormated = DateTime.now().format('dd/MM/yyyy à HH:mm:ss', UserInfo.getTimeZone().getID());
        String userId = ApexPages.currentPage().getParameters().get('userId');
        if(String.isNotBlank(userId)) {
            // Récupération des informations de l'utilisateur
            getVendeurInformation(userId);
            // Traitement des RDV
            getDataByVendeur();
            // Traitement des chantiers aux alentours
            getChantiersNearRDV();
        }
    }

    /**
    * @description Récupération de l'ID du logo KparK
    */
    public Id getLogoKparKId(){
        return DAL.getDocumentByName(Constants.KparK_logo_NB).id;
    }

    /**
    * @description Récupération de la liste des utilisateurs pour générer le PDF
    * @param userId Id de l'utilisateur
    */
    public void getVendeurInformation(String userId) {
        system.debug('### START getVendeurInformation');
        system.debug('## userId: ' + userId);
        UserContext context = UserContext.getContext(userId);
        if(context.isSaleUser()) {
            system.debug('## context: ' + context.getUser());
            codeMagasin = context.getUser().CodeMagasin__c;
            vendeurForPDF = DAL_Cartographie.getVendeursList(codeMagasin, userId);
            system.debug('## codeMagasin: ' + codeMagasin);
        }
        system.debug('### END getVendeurInformation');
    }

    /**
    * @description Récupération des RDV selon les vendeurs du magasin + formatage pour affichage PDF
    */
    public void getDataByVendeur() {
        system.debug('### START getDataByVendeur');
        Decimal x_left = -90; 
        Decimal y_top = 180; 
        Decimal x_right  = 90; 
        Decimal y_bottom = -180;
        // Récupération ID du secteur du magasin
        if(String.isNotBlank(codeMagasin)) {
            isDataAvailable = true;

            // Récupération des poses, métrages et intervention du secteurs pour la journée
            List<ServiceAppointment> contratsList = DAL_Feuillederoute.getContratRDVUsers(vendeurForPDF, codeMagasin, dateToday);
            Map<Event, Chantier__c> r1List = DAL_Feuillederoute.getRDVTodayList(codeMagasin, x_left, y_top, x_right, y_bottom, Constants.EVENT_TYPE_R1);
            Map<Event, Chantier__c> r2List = DAL_Feuillederoute.getRDVTodayList(codeMagasin, x_left, y_top, x_right, y_bottom, Constants.EVENT_TYPE_R2);
            Map<Event, Chantier__c> rPlusList = DAL_Feuillederoute.getRDVTodayList(codeMagasin, x_left, y_top, x_right, y_bottom, Constants.EVENT_TYPE_RP);
            Set<Utils_Cartographie.DotMap> prospectionsList = DAL_Cartographie.getRDVProspectionList(codeMagasin, x_left, y_top, x_right, y_bottom, dateToday, true, actualUser.Id, actualUser.Profile.Name);

            // Construction de la liste des contrats à retourner pour le PDF
            List<ServiceAppointment> posesVendeurList = new List<ServiceAppointment>();
            List<ServiceAppointment> metragesVendeurList = new List<ServiceAppointment>();
            List<ServiceAppointment> interventionsVendeurList = new List<ServiceAppointment>();
            List<Chantier__c> r1VendeurList = new List<Chantier__c>();
            List<Chantier__c> r2VendeurList = new List<Chantier__c>();
            List<Chantier__c> rPlusVendeurList = new List<Chantier__c>();
            List<Utils_Cartographie.DotMap> prospectionsVendeurList = new List<Utils_Cartographie.DotMap>();
            for(User vendeur : vendeurForPDF) {
                system.debug('## Vendeur : ' + vendeur.Name);
                posesVendeurList.clear();
                metragesVendeurList.clear();
                interventionsVendeurList.clear();
                r1VendeurList.clear();
                r2VendeurList.clear();
                rPlusVendeurList.clear();
                prospectionsVendeurList.clear();
                
                // Parcours des poses, métrages et interventions du magasin et récupération de ceux du vendeur
                for(ServiceAppointment contrat : contratsList) {
                    //if(vendeur.Id == contrat.Chantier__r.OwnerId) {
                        if(contrat.SchedStartTime == dateToday && (contrat.WorkType.Name == Constants.WORKTYPE_INSTALLATION || contrat.WorkType.Name == Constants.ACTIVITY_TYPE_INTERVENTION))
                            posesVendeurList.add(contrat);
                        if(contrat.SchedStartTime == dateToday && (contrat.WorkType.Name == Constants.WORKTYPE_METRAGE || contrat.WorkType.Name == Constants.ACTIVITY_TYPE_CONTROL))
                            metragesVendeurList.add(contrat);
                        if(contrat.SchedStartTime == dateToday && (contrat.WorkType.Name == Constants.WORKTYPE_INTERVENTION_SAV || contrat.WorkType.Name == Constants.ACTIVITY_TYPE_DIAGNOSTIC))
                            interventionsVendeurList.add(contrat);
                    //}
                }
                system.debug('## Vendeur poses : ' + posesVendeurList.size());
                posesVendeurs.put(vendeur, Utils_Cartographie.newContratFDRList(posesVendeurList));
                posesSize.put(vendeur, posesVendeurList.size());
                system.debug('## Vendeur métrages : ' + metragesVendeurList.size());
                metragesVendeurs.put(vendeur, Utils_Cartographie.newContratFDRList(metragesVendeurList));
                metragesSize.put(vendeur, metragesVendeurList.size());
                system.debug('## Vendeur interventions : ' + interventionsVendeurList.size());
                interventionsVendeurs.put(vendeur, Utils_Cartographie.newContratFDRList(interventionsVendeurList));
                interventionSize.put(vendeur, interventionsVendeurList.size());
                // Parcours des R1 du magasin et récupération de ceux du vendeur
                for(Event event : r1List.keySet()) {
                    if(vendeur.Id == event.OwnerId)
                        r1VendeurList.add(r1List.get(event));
                }
                system.debug('## Vendeur R1 : ' + r1VendeurList.size());
                r1Vendeurs.put(vendeur, Utils_Cartographie.newChantierFDRList(r1VendeurList, Constants.EVENT_TYPE_R1));
                r1Size.put(vendeur, r1VendeurList.size()); 
                // Parcours des R2 du magasin et récupération de ceux du vendeur
                for(Event event : r2List.keySet()) {
                    if(vendeur.Id == event.OwnerId)
                        r2VendeurList.add(r2List.get(event));
                }
                system.debug('## Vendeur R2 : ' + r2VendeurList.size());
                r2Vendeurs.put(vendeur, Utils_Cartographie.newChantierFDRList(r2VendeurList, Constants.EVENT_TYPE_R2));
                r2Size.put(vendeur, r2VendeurList.size());
                // Parcours des R+ du magasin et récupération de ceux du vendeur
                for(Event event : rPlusList.keySet()) {
                    if(vendeur.Id == event.OwnerId)
                        rPlusVendeurList.add(rPlusList.get(event));
                }
                system.debug('## Vendeur R+ : ' + rPlusVendeurList.size());
                rPlusVendeurs.put(vendeur, Utils_Cartographie.newChantierFDRList(rPlusVendeurList, Constants.EVENT_TYPE_RP));
                rPlusSize.put(vendeur, rPlusVendeurList.size());
                // Parcours des prospections du magasin et récupération de ceux du vendeur
                for(Utils_Cartographie.DotMap event : prospectionsList) {
                    if(vendeur.Id == event.OwnerId)
                        prospectionsVendeurList.add(event);
                }
                system.debug('## Vendeur prospections : ' + prospectionsVendeurList.size());
                prospectionsVendeurs.put(vendeur, prospectionsVendeurList);
                prospectionsSize.put(vendeur, prospectionsVendeurList.size());
                
                // Taille totale par vendeur
                Integer nbInformations = posesVendeurList.size() + metragesVendeurList.size() + interventionsVendeurList.size() + 
                                            r1VendeurList.size() + r2VendeurList.size() + rPlusVendeurList.size() + prospectionsVendeurList.size();
                informationsVendeurSize.put(vendeur, nbInformations);
                
                system.debug('## nbInformations : ' + nbInformations);
                if(nbInformations > 0) nbDisplayVendeur++;
            }
            system.debug('## Taille totale : ' + nbDisplayVendeur);
        }
        system.debug('### END getDataByVendeur');
    }
    
    /**
    * @description Récupération des chantiers dans un périmètre des RDV retournés par la méthode getDataByVendeur
    */
    public void getChantiersNearRDV() {
        Integer fdrDotLimits = Constants.FDR_CHANTIER_LIMITS;
        Decimal perimetre = PropertiesUtils.getIntegerValue('feuillederoute.pdf.searchPerimeter', 50);
        // Passage de mètre en kilomètre
        Decimal perimetreKm = perimetre / 1000;
        // Construction du filtre sur les distances pour tous les RDV
        String soqlFilterDistance = '';
        for(User vendeur : vendeurForPDF) {
            List<Utils_Cartographie.ContratFDR> contratRDVList = new List<Utils_Cartographie.ContratFDR>();
            if(posesVendeurs.get(vendeur)!=null) contratRDVList.addAll(posesVendeurs.get(vendeur));
            if(metragesVendeurs.get(vendeur)!=null) contratRDVList.addAll(metragesVendeurs.get(vendeur));
            if(interventionsVendeurs.get(vendeur)!=null) contratRDVList.addAll(interventionsVendeurs.get(vendeur));
            if(r1Vendeurs.get(vendeur)!=null) contratRDVList.addAll(r1Vendeurs.get(vendeur));
            if(r2Vendeurs.get(vendeur)!=null) contratRDVList.addAll(r2Vendeurs.get(vendeur));
            if(rPlusVendeurs.get(vendeur)!=null) contratRDVList.addAll(rPlusVendeurs.get(vendeur));
            // Boucle sur les contrats et RDV
            for(Utils_Cartographie.ContratFDR obj : contratRDVList) {
                if(obj.latitude != null && obj.longitude != null)
                    soqlFilterDistance +=' DISTANCE(Localisation__c, GEOLOCATION ('+obj.latitude+','+obj.longitude+'), \'km\') < '+ perimetreKm + ' OR ';
            }
            // Boucle su les prospections
            if(prospectionsVendeurs.get(vendeur)!=null) {
                for(Utils_Cartographie.DotMap rdv : prospectionsVendeurs.get(vendeur)) {
                    if(rdv.latitude != null && rdv.longitude != null)
                        soqlFilterDistance +=' DISTANCE(Localisation__c, GEOLOCATION ('+rdv.Latitude+','+rdv.Longitude+'), \'km\') < '+ perimetreKm + ' OR ';
                }
            }
        }
        // Récupération des chantier
        if(soqlFilterDistance != '') {
            soqlFilterDistance = soqlFilterDistance.removeEnd(' OR ');
            system.debug('Filtre chantier distance : ' + soqlFilterDistance);
            
            
            String soqlQuery ='SELECT Id, Name, rue__c, codePostal__c, ville__c, interditProspection__c, nbContratsResilies__c, nbContratsVendus__c, nomProprietaires__c, nomLocataires__c, nomOccupants__c, ';
            soqlQuery +=' prenomProprietaires__c, prenomLocataires__c, prenomOccupants__c, locataire__c, telephoneDomicileLocataires__c, telephoneMobileLocataires__c, locataire__r.name, ';
            soqlQuery +=' proprietaire__c, proprietaire__r.name, telephoneDomicileProprietaires__c, telephoneMobileProprietaires__c, occupant__c, telephoneDomicileOccupants__c, ';
            soqlQuery +=' telephoneMobileOccupants__c, occupant__r.name, autreProprietaire__c, autreProprietaire__r.name, autreLocataire__c, autreOccupant__c, autreOccupant__r.name, autreLocataire__r.name,';
            soqlQuery +=' autreTelephoneLocataires__c, autreTelephoneOccupants__c, autreTelephoneProprietaires__c, OwnerId, Localisation__Latitude__s, Localisation__Longitude__s ,';
            soqlQuery +=' (SELECT Id, datesignature__c, nombreInterventionsSAV__c, derniereInterventionSAV__c, nbSAVTotal__c, produits__c FROM ChantierContrats__r ORDER BY LastModifiedDate DESC LIMIT 1) ';
            soqlQuery +=' FROM Chantier__c ';
            soqlQuery +=' WHERE (';
            
            String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
            for (Integer i = 0; i < codeMagasins.size(); i++) {
              String codeMagasin = codeMagasins[i];
              if (i == 0)
                 soqlQuery += 'codeMagasintechnique__c =\''+ codeMagasin +'\'';
              else
                 soqlQuery += ' OR codeMagasintechnique__c =\''+ codeMagasin +'\'';
            }
            soqlQuery +=') AND ('+ soqlFilterDistance + ') ORDER BY LastModifiedDate DESC LIMIT ' + fdrDotLimits;
            // Exécution requête            
            system.debug('Requête : ' + soqlQuery);
            List<Chantier__c> chantiersList = Database.query(soqlQuery);
            system.debug('Taille chantiers alentours : ' + chantiersList.size());
            // Traitement chantiers avec ou sans contrats par vendeur
            List<Chantier__c> chantiersContrats = new List<Chantier__c>();
            List<Chantier__c> chantiersNotContrats = new List<Chantier__c>();
            for(User vendeur : vendeurForPDF) {
                chantiersContrats.clear();
                chantiersNotContrats.clear();
                for(Chantier__c chantier : chantiersList) {
                    if(chantier.OwnerId == vendeur.Id) {
                        if(chantier.nbContratsResilies__c > 0 || chantier.nbContratsVendus__c > 0)
                            chantiersContrats.add(chantier);
                        if((chantier.nbContratsResilies__c == 0  || chantier.nbContratsResilies__c == null) 
                            && (chantier.nbContratsVendus__c ==0  || chantier.nbContratsVendus__c == null))
                            chantiersNotContrats.add(chantier);
                    }
                }
                chantiersAvecContratsVendeurs.put(vendeur, Utils_Cartographie.newChantierWithContratFDRList(chantiersContrats));
                chantiersAvecContratsSize.put(vendeur, chantiersContrats.size());
                chantiersSansContratsVendeurs.put(vendeur, Utils_Cartographie.newChantierFDRList(chantiersNotContrats, ''));
                chantiersSansContratsSize.put(vendeur, chantiersNotContrats.size());
            }
        }           
    }
}