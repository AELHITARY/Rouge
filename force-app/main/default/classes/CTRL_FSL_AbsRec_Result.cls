/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-16          Class created. Résultat création des RDV
*/
public class CTRL_FSL_AbsRec_Result {
    
    //Constructeur
    public CTRL_FSL_AbsRec_Result()
    {
        this.setVariable();
        this.setHeureDebut();
        this.setHeureFin();
        this.setTypeAbsSelected();
        this.displayListAbsence();
    }

    
    //Liste des RDV qui ont été crées 
    public List<ResourceAbsence> lAbsenceResourceCreated {get; set;}
    
    //Nombre des RDV
    public Integer nbExpected {get; set;}
    public Integer nbCreated {get; set;}
    
    //Dates
    public Date debutPlanning {get; set;}
    public Date finPlanning {get; set;}
    
    public Integer hdeb {get; set;}
    public Integer mdeb {get; set;}
    public Integer hfin {get; set;}
    public Integer mfin {get; set;}
    public String typeAbsSelected {get; set;}
    
    
    //Set nombre de RDV total 
    @TestVisible
    private void setVariable()
    {
        this.nbExpected = Integer.valueOf(ApexPages.currentPage().getParameters().get('nb'));
        this.debutPlanning = Date.valueOf(ApexPages.currentPage().getParameters().get('start'));
        this.finPlanning = Date.valueOf(ApexPages.currentPage().getParameters().get('end'));
    }
    
        //Heure de début
    @TestVisible
    private void setHeureDebut()
    {
        String sheureDebut = ApexPages.currentPage().getParameters().get('hdeb');
        List<String> splitHeure = sheureDebut.split(':');
        String heure = splitHeure[0];
        String minute = splitHeure[1];
        
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
        
        this.hfin = Integer.valueOf(heure);
        this.mfin = Integer.valueOf(minute);
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

    //Affichage de la liste des RDV qui ont été crée
	@TestVisible
    private void displayListAbsence()
    {
        lAbsenceResourceCreated = new List<ResourceAbsence>();
        List<ResourceAbsence> lAbsCreated = new List<ResourceAbsence>();
        
        //Récupération de l'utilisateur actuel 
        Id userId = UserInfo.getUserId();
        
        //Récupération de la liste des Id des ressources 
        String urlListRes = ApexPages.currentPage().getParameters().get('lres');
        List<String> lIdRes = urlListRes.split('-');
        
        if(lIdRes != null)
        {
            for(String iR : lIdRes)
            {
                iR.replaceAll('-','');
            }

            lAbsCreated = [SELECT 	Id, 
                                    Resource.Name,
                                    Start,
                                    End,
                                    Type,
                           			CreatedById,
                           			CreatedDate
                           FROM		ResourceAbsence
                           WHERE	Resource.id IN : lIdRes
                           AND		Type = :this.typeAbsSelected 
                           AND		Start >= :this.debutPlanning
                           AND		End <= :this.finPlanning+1
                           AND		CreatedBy.Id = :userId
                          ];
        }
        
        if(lAbsCreated != null)
        {
            for(ResourceAbsence ra : lAbsCreated)
            {
                Date raModifiedDate = Date.newInstance(ra.CreatedDate.year(), ra.CreatedDate.month(), ra.CreatedDate.day());
                
                Integer hDebRa = Integer.valueOf(ra.Start.hour());
                Integer mDebRa = Integer.valueOf(ra.Start.minute()); 
                Integer hFinRa = Integer.valueOf(ra.End.hour());
                Integer mFinRa = Integer.valueOf(ra.End.minute()); 
                
                if(raModifiedDate == Date.today())
                {
                    lAbsenceResourceCreated.add(ra);
                }
            }
        }
        
        
        this.nbCreated = lAbsenceResourceCreated.size();
        
    }
}