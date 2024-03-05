/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-08          Class created. Recap
*/
public class CTRL_FSL_AbsRec_Recap {
    
    //Constructeur
    public CTRL_FSL_AbsRec_Recap()
    {
        this.setDebutPlanning();
        this.setFinPlanning();
        this.setHeureDebut();
        this.setHeureFin();
        this.setDays();
        this.setTypeAbsSelected();
        this.setListScopeDate();
        this.setNumberLoop();
        this.setListServiceResource();
        
        this.setListAbsence();
    }
    
    //Creation d'absence à afficher sur l'écran
    public class AbsenceCustom
    {
        public Id idRes {get; set;}
        public String resource {get; set;}
        public String typeAbsence {get; set;}
        public Date dateDebut {get; set;}
        public String heureDebut {get; set;}
        public String heureFin {get; set;}
        
        public AbsenceCustom(Id idRes, String resource, String typeAbsence, Date dateDebut, String heureDebut, String heureFin)
        {
            this.idRes = idRes;
            this.resource = resource; 
            this.typeAbsence = typeAbsence;
            this.dateDebut = dateDebut; 
            this.heureDebut = heureDebut;
            this.heureFin = heureFin;
        }
    }

    //Liste des absences à afficher pour le récapitulatif
    public List<AbsenceCustom> lAbsenceCustom {get; set;}   
    
    //Variable permettant de connaitre le nombre d'enregistrement à créer
    public Date debutPlanning {get; set;}
    public Date finPlanning {get; set;}
    public String heureDebut {get; set;}
    public String heureFin {get; set;}
    public List<String> listDays {get; set;}
    public String typeAbsSelected {get; set;}
    public Integer nbAbs {get; set;}
    
    public Integer hdeb {get; set;}
    public Integer mdeb {get; set;}
    public Integer hfin {get; set;}
    public Integer mfin {get; set;}
    
    public List<Date> lScopeDate {get; set;}
    
    public Integer numberLoop {get; set;}
    public Integer intervalle {get; set;}
    
    public List<ServiceResource> lServiceResource {get; set;}

    
    //Récupération de la date de début 
    @TestVisible
    private void setDebutPlanning()
    {
            String sDebutPlanning = ApexPages.currentPage().getParameters().get('start');
            this.debutPlanning = Date.valueOf(sDebutPlanning);     
    }
    
    //Récupération de la date de fin
    @TestVisible
    private void setFinPlanning()
    { 
        String sFinPlanning = ApexPages.currentPage().getParameters().get('end');
        this.finPlanning = Date.valueOf(sFinPlanning);     
    }

    //Heure de début
    @TestVisible
    private void setHeureDebut()
    {
        String sheureDebut = ApexPages.currentPage().getParameters().get('hdeb');
        List<String> splitHeure = sheureDebut.split(':');
        String heure = splitHeure[0];
        String minute = splitHeure[1];
        
        this.heureDebut = heure + 'h' + minute;
        this.hdeb = Integer.valueOf(heure);
        this.mdeb = Integer.valueOf(minute);
    }
    
    //Heure de fin
    @TestVisible
    private void setHeureFin()
    {
        String sheureFin = ApexPages.currentPage().getParameters().get('hfin');
        List<String> splitHeure = sheureFin.split(':');
        String heure = splitHeure[0];
        String minute = splitHeure[1];
        
        this.heureFin = heure + 'h' + minute;
        this.hfin = Integer.valueOf(heure);
        this.mfin = Integer.valueOf(minute);
    }
    
    
    //List des Jours sélectionné
    @TestVisible
    private void setDays()
    {
        //String qui contient la liste de territoire, à convertir en type liste
        String urlDays = ApexPages.currentPage().getParameters().get('days');
        String[] idDays = urlDays.split(', ');
        this.listDays = new List<String>();
        
        if(idDays != null)
        {
            if(idDays.contains('(L') || idDays.contains('(L)'))
            {
                String jour = 'Mon';
                this.listDays.add(jour);
            }
            if(idDays.contains('M') || idDays.contains('(M') || idDays.contains('(M)') || idDays.contains('M)'))
            {
                String jour = 'Tue';
                this.listDays.add(jour);
            } 
            if(idDays.contains('Me') || idDays.contains('(Me') || idDays.contains('(Me)') || idDays.contains('Me)'))
            {
                String jour = 'Wed';
                this.listDays.add(jour);
            } 
            if(idDays.contains('J') || idDays.contains('(J') || idDays.contains('(J)') || idDays.contains('J)'))
            {
                String jour = 'Thu';
                this.listDays.add(jour);
            } 
            if(idDays.contains('V') || idDays.contains('(V') || idDays.contains('(V)') || idDays.contains('V)'))
            {
                String jour = 'Fri';
                this.listDays.add(jour);
            } 
            if(idDays.contains('S)') || idDays.contains('(S)'))
            {
                String jour = 'Sat';
                this.listDays.add(jour);
            } 
        }
    }
    
    
    //Type absence
    @TestVisible
    private void setTypeAbsSelected()
    {       
        //String qui contient la liste de territoire, à convertir en type liste
        String urlTypeAbs = ApexPages.currentPage().getParameters().get('tabs');
        
        if(urlTypeAbs != null)
        {
            if(urlTypeAbs == 'ta1')
            {
                this.typeAbsSelected = 'Férié';
            }
            else if( urlTypeAbs == 'ta2')
            {
                this.typeAbsSelected  = 'Présence dépôt';
            }
            else if( urlTypeAbs == 'ta3')
            {
                this.typeAbsSelected  = 'Rendez-vous société';
            }
            else if( urlTypeAbs == 'ta4')
            {
                this.typeAbsSelected  = 'Indisponibilité poseur';
            }
            else if( urlTypeAbs == 'ta5')
            {
                this.typeAbsSelected  = 'Réunion';
            }
            else if( urlTypeAbs == 'ta6')
            {
                this.typeAbsSelected  = 'Formation';
            }
            else if( urlTypeAbs == 'ta7')
            {
                this.typeAbsSelected  = 'Enregistrement contrat';
            }
            else if( urlTypeAbs == 'ta8')
            {
                this.typeAbsSelected  = 'RTT';
            }
            else if( urlTypeAbs == 'ta9')
            {
                this.typeAbsSelected  = 'Autre';
            }
            else if( urlTypeAbs == 'ta10')
            {
                this.typeAbsSelected  = 'Saisie de commandes';
            }
        }
    }
    
    
    //Liste des dates à traiter
    @TestVisible
    private void setListScopeDate()
    {        
        Integer diffDate = this.debutPlanning.daysBetween(this.finPlanning);
        Date debutRebours = this.debutPlanning;
        
        this.lScopeDate = new List<Date>();
        
        if(diffDate < 7)
        {
            while(debutRebours != this.finPlanning+1)
            {
                this.lScopeDate.add(debutRebours);
                debutRebours = (debutRebours+1);
            }
        }
        else
        {
            Date finRebours = (this.debutPlanning+7);
            while(debutRebours != (finRebours))
            {
                this.lScopeDate.add(debutRebours);
                debutRebours = (debutRebours+1);
            }
        }
    }

    
    //Méthode permettant d'initialiser des variables nombres
    @TestVisible
    private void setNumberLoop()
    {
        Integer diffDate = this.debutPlanning.daysBetween(this.finPlanning);
        
        //String qui contient la liste de territoire, à convertir en type liste
        String urlFreq = ApexPages.currentPage().getParameters().get('freq');
        
        if(urlFreq == 'none' )
        {
            this.numberLoop = 0;
            this.intervalle = 0;
        }
        else if( urlFreq == 'ts')
        {
            this.numberLoop = (diffDate/7);
            this.intervalle = 7;
        }
        else if( urlFreq == 'tss')
        {
            this.numberLoop = (diffDate/14);
            this.intervalle = 14;
        }
        else if( urlFreq == 'tsss')
        {
            this.numberLoop = (diffDate/21);
            this.intervalle = 21;
        }
        else if( urlFreq == 'tm')
        {
            this.numberLoop = (diffDate/28);
            this.intervalle = 28;
        }
        
        else
        {
            this.numberLoop = 0;
            this.intervalle = 500;
        }
    }
    
    //Récupération de la liste des ressources cochées
    @TestVisible 
    private void setListServiceResource()
    {
        //String qui contient ma liste d'éléments, à convertir en type liste
        String urlRes = ApexPages.currentPage().getParameters().get('lres');
        List<String> lIdRes = urlRes.split('-'); 
        
        if(lIdRes != null)
        {
            for(String iR : lIdRes)
            {
                iR.replaceAll('-','');
            }
        }
        
        //Obtention de la liste des ressources dont l'ID est dans la liste        
        if(lIdRes != null)
        {
            this.lServiceResource = [SELECT Id,
                                	   Name
                                FROM   ServiceResource 
                                WHERE  IsActive = true
                                AND    Id IN :lIdRes
                                ORDER BY Name];
        }
    }
    
    
    //Méthode pour trier les RDV par Date avant de les afficher
    @TestVisible 
    private List<AbsenceCustom> sortListAbsenceCustom(List<AbsenceCustom> lAbsC)
    {
        Map<String, AbsenceCustom> listUnsorted = new Map<String, AbsenceCustom>();
        Map<String, AbsenceCustom> listAbsSorted = new Map<String, AbsenceCustom>();
        List<String> orderingList = new List<String>();
        List<AbsenceCustom> lAbsSorted = new List<AbsenceCustom>();
        
        for(Integer i=0 ; i<lAbsC.size(); i++)
        {
            listUnsorted.put(String.valueOf(lAbsC[i].dateDebut) + ' ' + i, lAbsC[i]);
        }
        
        //Ajout de tous les éléments dans la list et tri par Date 
        orderingList.addAll(listUnsorted.keySet());
        orderingList.sort();
        
        for(Integer i=0; i < orderingList.size(); i++)
        {
            listAbsSorted.put(orderingList[i], listUnsorted.get(orderingList[i]));
        }
        lAbsSorted = listAbsSorted.values();
        
        return lAbsSorted;
    }
            
    //Fonction permettant d'alimenter la liste des Absences à créer 
    public void setListAbsence()
    {
        //Instanciation de la variable contenant la liste des absences 
        List<AbsenceCustom> stockAbsenceCustom = new List<AbsenceCustom>();
        
        //Ressources sélectionnées
        List<ServiceResource> lServiceResourceSelected = this.lServiceResource;
        //Commentaire
        String comm = ApexPages.currentPage().getParameters().get('comm');
        
        
        if(this.lScopeDate != null)
        {
            for(Date lcd : this.lScopeDate)
            {           
                if(!this.listDays.isEmpty())
                {
                    DateTime dtToDateTime = DateTime.newInstance(lcd.year(), lcd.month(), lcd.day());
                    String dayDate = dtToDateTime.format('EEE');
                    
                    if(this.listDays.contains(dayDate))
                    {
                        Date debutRebours = lcd;
                        
                        for(Integer init=0 ;init < this.numberLoop+1; init++)
                        {
                            if(debutRebours <= this.finPlanning)
                            {
                                for(ServiceResource sr : lServiceResourceSelected)
                                {
                                    AbsenceCustom ac = new AbsenceCustom(sr.id, sr.name, this.typeAbsSelected , debutRebours, this.heureDebut, this.heureFin);
                                    stockAbsenceCustom.add(ac);
                                }
                                if(this.intervalle == 500)
                                {
                                    debutRebours = this.finPlanning;
                                }
                                else
                                {
                                    debutRebours = debutRebours + this.intervalle;
                                }
                            }
                        }
                    } 
                }
                else
                {
                    //Traitement si le jour de début est égale au jour de fin
                    for(ServiceResource sr : lServiceResourceSelected)
                    {
                        AbsenceCustom ac = new AbsenceCustom(sr.id, sr.name, this.typeAbsSelected, lcd, this.heureDebut, this.heureFin);
                        stockAbsenceCustom.add(ac);
                    }
                }
            }
        }
       
        this.lAbsenceCustom = this.sortListAbsenceCustom(stockAbsenceCustom);
        this.nbAbs = stockAbsenceCustom.size();
    }
    
    //Traitement des rendez-vous après confirmation
    //Redirection vers la page pour afficher la feuille de route 
    public PageReference confirmerCreate() 
    {
        //Lien de base vers les feuilles de routes sélectionnées
        String link =  '/apex/VF_FSL_AbsRec_Result';
        
        //Liste des variables à ajouter dans l'URL
        String urlDateDebut = ApexPages.currentPage().getParameters().get('start');
        String urlDateFin = ApexPages.currentPage().getParameters().get('end');
        String urlTabs = ApexPages.currentPage().getParameters().get('tabs');
        String urlRes = ApexPages.currentPage().getParameters().get('lres');
        String urlNbAbs = String.valueOf(this.nbAbs);
        String urlHdeb = ApexPages.currentPage().getParameters().get('hdeb');
        String urlHfin = ApexPages.currentPage().getParameters().get('hfin');
        
        
        //Formation de l'URL avec le territoire et les dates 
        link = link + '?start=' + urlDateDebut + '&end=' + urlDateFin + '&tabs=' + urlTabs + '&lres=' + urlRes + '&nb=' + urlNbAbs + '&hdeb=' + urlHdeb + '&hfin=' + urlHfin;
        
        //Liste stockage
        List<ResourceAbsence> lAbsToCreate = new List<ResourceAbsence>();
        
        RecordType rt = [SELECT id FROM RecordType WHERE Name = 'Non Availability'];
        
        
        //Traitement
        for(AbsenceCustom ac : this.lAbsenceCustom)
        {     
            ResourceAbsence abs = new ResourceAbsence(
                RecordTypeId = rt.id,
                ResourceId = ac.idRes,
                Type = ac.typeAbsence, 
                Start = DateTime.newInstance(ac.dateDebut.year(), ac.dateDebut.month(), ac.dateDebut.day(), this.hdeb, this.mdeb, 0),
                End = DateTime.newInstance(ac.dateDebut.year(), ac.dateDebut.month(), ac.dateDebut.day(), this.hfin, this.mfin, 0),
                FSL__GanttLabel__c = ApexPages.currentPage().getParameters().get('comm')
                
            );
            
            lAbsToCreate.add(abs);
        }
        
        if(lAbsToCreate != null)
        {
            Database.insert(lAbsToCreate, false);
        }
        
        PageReference pr = new PageReference(link);
        pr.setRedirect(true);
        
        return pr;
    } 
    
}