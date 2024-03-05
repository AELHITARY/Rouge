//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : CTRL_FicheProjet
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/03/2020
//-- Version     : 2.0
//-- * 2.0 : RQM-107 : Fiche projet (Ajout de Description des activités)
//-- * 1.0 : Init (Version de Kerensen)
//-- --------------------------------------------------------------------------------- --
public class CTRL_FicheProjet {

    public static final integer NUM_OF_DISPLAYED_RDV = 4;
    public Opportunity myOpportunity{set; get;}
    public List<HistoriqueRDV> myRdvlist{set; get;}
    public List<Taches> myTachelist{set; get;}


    public Introduction myIntroduction {set; get;}
    public Signataire mySignataire {set; get;}
    public AutreSignataire myAutreSignataire {set; get;}
    public Chantier myChantier {set; get;}
    public Qualification myQualification {set; get;}
    public InteretPrincipal myInteretPrincipal{set; get;}

    public string getPrecisions(){return myOpportunity.precisionsReportRefus__c;}

    public CTRL_FicheProjet(ApexPages.StandardController ctrl)
    {
        Opportunity tmpOpportunity = (Opportunity) ctrl.getRecord();
        if(tmpOpportunity.id !=null)
        {
            myOpportunity =DAL.GetFicheProjetPDFById(tmpOpportunity.id);
            myIntroduction = new Introduction(myOpportunity);
            mySignataire = new Signataire(myOpportunity);
            myAutreSignataire = new AutreSignataire(myOpportunity);
            myChantier = new Chantier(myOpportunity);
            myQualification = new Qualification(myOpportunity);
            myInteretPrincipal = new InteretPrincipal(myOpportunity);
            myRdvlist = CTRL_FicheProjet.GetList(DAL.GetEventByWhatId(myOpportunity.id));
            myTachelist = CTRL_FicheProjet.GetList(DAL.GetTaskByWhatId(myOpportunity.id));
        }
    }

    public static list<HistoriqueRDV> GetList(list<Event> myEventlist)
    {
        system.debug('#################################################' + myEventlist.size());
        list<HistoriqueRDV> RDVList = new list<HistoriqueRDV>();
        integer index=0;
        for(Event e: myEventlist)
        {
                if(index>=NUM_OF_DISPLAYED_RDV)
                break;
            RDVList.add(new HistoriqueRDV(e));
            index++;
        }
        return RDVList;
    }

    public static list<Taches> GetList(list<Task> myTaskslist)
    {
        system.debug('#################################################' + myTaskslist.size());
        list<Taches> TacheList = new list<Taches>();
        integer index=0;
        for(Task e: myTaskslist)
        {
                if(index>=NUM_OF_DISPLAYED_RDV)
                break;
            TacheList.add(new Taches(e));
            index++;
        }
        return TacheList;
    }

    public class Introduction
    {
        public Opportunity opportunity{set; get;}
        public Introduction(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public string getOrigine(){return opportunity.LeadSource;}
        public string getNumeroProjet(){return opportunity.numeroProjet__c;}
        public string getDateCreation(){return opportunity.CreatedDate.format('dd/MM/yyyy');}
        public string getHeureCreation(){return opportunity.CreatedDate.format('HH:mm');}
        public string getStatut(){return opportunity.StageName;}
        public string getVendeur(){return opportunity.CreatedBy.Name;}
        //TODO a voir
        public string getMagasin(){return opportunity.Chantier__r.libelleMagasinActuel__c;}
    }

    public class Signataire
    {
        public Opportunity opportunity{set; get;}
        public Signataire(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public string getCivilite(){return opportunity.Account.civilite__c;}
        public string getPrenom(){return opportunity.Account.prenom__c;}
        public string getNom(){return opportunity.Account.nom__c;}
        public string getCodePostal(){return opportunity.Account.codePostal__c;}
        public string getVille(){return opportunity.Account.ville__c;}
        public string getPays(){return opportunity.Account.pays__c;}
        public string getCodeAcces(){return opportunity.Account.codeAcces__c;}
        public string getInterphone(){return opportunity.Account.interphone__c;}
        public double getEtage(){return opportunity.Account.etage__c;}
        public string getPhoneNumber(){ return opportunity.Account.telephoneDomicile__c;}
        public string getMailAddr(){return opportunity.Account.email__c;}
        public string getRue(){return opportunity.Account.rue__c;}
        public string getMobilePhoneNumber(){return opportunity.Account.telephoneMobile__c;}
        public string getRole(){
            String role = '';
            if((opportunity.Chantier__r.Proprietaire__c == opportunity.Account.Id) || (opportunity.Chantier__r.autreProprietaire__c == opportunity.Account.Id))
                role = 'Propriétaire';
            if((opportunity.Chantier__r.Locataire__c == opportunity.Account.Id) || (opportunity.Chantier__r.autreLocataire__c == opportunity.Account.Id))
            {
                if(role!='')
                    role = role + ', Locataire';
                else
                    role = 'Locataire';
            }
            if((opportunity.Chantier__r.Occupant__c == opportunity.Account.Id) || (opportunity.Chantier__r.autreOccupant__c == opportunity.Account.Id))
            {
                if(role!='')
                    role = role + ', Occupant';
                else
                    role = 'Occupant';
            }
            return role;
        }
        public string getNumCompte(){return opportunity.Account.AccountNumber;}
    }

    public class AutreSignataire
    {
        public Opportunity opportunity{set; get;}
        public AutreSignataire(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public string getCivilite(){return opportunity.autreCompte__r.civilite__c;}
        public string getPrenom(){return opportunity.autreCompte__r.prenom__c;}
        public string getNom(){return opportunity.autreCompte__r.nom__c;}
        public string getCodePostal(){return opportunity.autreCompte__r.codePostal__c;}
        public string getVille(){return opportunity.autreCompte__r.ville__c;}
        public string getPays(){return opportunity.autreCompte__r.pays__c;}
        public string getCodeAcces(){return opportunity.autreCompte__r.codeAcces__c;}
        public string getInterphone(){return opportunity.autreCompte__r.interphone__c;}
        public double getEtage(){return opportunity.autreCompte__r.etage__c;}
        public string getPhoneNumber(){ return opportunity.autreCompte__r.telephoneDomicile__c;}
        public string getMailAddr(){return opportunity.autreCompte__r.email__c;}
        public string getRue(){return opportunity.autreCompte__r.rue__c;}
        public string getMobilePhoneNumber(){return opportunity.autreCompte__r.telephoneMobile__c;}
        public string getRole(){
            String role = '';
            if((opportunity.Chantier__r.Proprietaire__c == opportunity.autreCompte__r.Id) || (opportunity.Chantier__r.autreProprietaire__c == opportunity.autreCompte__r.Id))
                role = 'Propriétaire';
            if((opportunity.Chantier__r.Locataire__c == opportunity.autreCompte__r.Id) || (opportunity.Chantier__r.autreLocataire__c == opportunity.autreCompte__r.Id))
            {
                if(role!='')
                    role = role + ', Locataire';
                else
                    role = 'Locataire';
            }
            if((opportunity.Chantier__r.Occupant__c == opportunity.autreCompte__r.Id) || (opportunity.Chantier__r.autreOccupant__c == opportunity.autreCompte__r.Id))
            {
                if(role!='')
                    role = role + ', Occupant';
                else
                    role = 'Occupant';
            }
            return role;
        }
        public string getNumCompte(){return opportunity.autreCompte__r.AccountNumber;}
    }

    public class Chantier
    {
        public Opportunity opportunity{set; get;}
        public Chantier(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public string getCodePostal(){return opportunity.Chantier__r.codePostal__c;}
        public string getVille(){return opportunity.Chantier__r.Ville__c;}
        public string getPays(){return opportunity.Chantier__r.pays__c;}
        public double getEtage(){return opportunity.Chantier__r.Etage__c;}
        public string getRue(){return opportunity.Chantier__r.rue__c;}
        public string getNumChantier(){return opportunity.Chantier__r.numeroChantier__c;}
        public string getDescription(){return opportunity.Chantier__r.description__c;}

    }


    public class Qualification
    {
        public Opportunity opportunity{set; get;}
        public Qualification(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public string getResidence(){return opportunity.Chantier__r.typeResidence__c;}
        public string getUrbanisme(){return opportunity.Chantier__r.caracteristiquesUrbanisme__c;}
        public string getTypeHabitation(){return opportunity.Chantier__r.typeHabitation__c;}
        public string getDateConstruction(){return opportunity.Chantier__r.anneeConstruction__c;}
        public string getModeChauffe(){return opportunity.Chantier__r.chauffages__c;}
    }

    public class InteretPrincipal
    {
        public Opportunity opportunity{set; get;}
        public InteretPrincipal(Opportunity myOpportunity)
        {
            opportunity = myOpportunity;
        }

        public double getNumFenetre(){return opportunity.quantiteFenetre__c;}
        public string getMatFenetre(){return opportunity.materiauxFenetre__c;}
        public double getNumPorteFenetre(){return opportunity.quantitePorteFenetre__c;}
        public string getMatPorteFenetre(){return opportunity.materiauxPorteFenetre__c;}
        public double getNumCoulissant(){return opportunity.quantiteCoulissant__c;}
        public string getMatCoulissant(){return opportunity.materiauxCoulissant__c;}
        public double getNumVoletRoulant(){return opportunity.quantiteVoletRoulant__c;}
        public string getMatVoletRoulant(){return opportunity.materiauxVoletRoulant__c;}
        public double getNumPortail(){return opportunity.quantitePortail__c;}
        public string getMatPortail(){return opportunity.materiauxPortail__c;}
        public double getNumVoletBattant(){return opportunity.quantiteVoletBattant__c;}
        public string getMatVoletBattant(){return opportunity.materiauxVoletBattant__c;}
        public double getNumPersiennes(){return opportunity.quantitePersienne__c;}
        public string getMatPersiennes(){return opportunity.materiauxPersienne__c;}
        public double getNumMoustiquaire(){return opportunity.quantiteMoustiquaire__c;}
        public string getMatMoustiquaire(){return opportunity.materiauxMoustiquaire__c;}
        public double getNumStoreBanne(){return opportunity.quantiteStoreBanne__c;}
        public string getMatStoreBanne(){return opportunity.materiauxStoreBanne__c;}
        public double getNumPorteInterieur(){return opportunity.quantitePorteInterieur__c;}
        public string getMatPorteInterieur(){return opportunity.materiauxPorteInterieur__c;}
        public double getNumPorteGarage(){return opportunity.quantitePorteGarage__c;}
        public string getMatPorteGarage(){return opportunity.materiauxPorteGarage__c;}
        public double getNumPorteEntree(){return opportunity.quantitePorteEntree__c;}
        public string getMatPorteEntree(){return opportunity.materiauxPorteEntree__c;}
        public double getNumPorteBlindee(){return opportunity.quantitePorteBlindee__c;}
        public string getMatPorteBlindee(){return opportunity.materiauxPorteBlindee__c;}
        public double getNumPorteService(){return opportunity.quantitePorteService__c;}
        public string getMatPorteService(){return opportunity.materiauxPorteService__c;}
    }

    public class Taches
    {
        public Task myTask{set; get;}
        public Taches(Task task)
        {
            myTask = task;
        }

        public string getObjet(){return myTask.Subject;}
        public string getAttribue(){return myTask.Owner == null ? '' : myTask.Owner.Name;}
        public string getEcheance(){return myTask.ActivityDate == null ? '' : myTask.ActivityDate.format();}
        public string getStatut(){return myTask.Status;}
        public string getPriorite(){return myTask.Priority;}
        public string getRappel(){return myTask.ReminderDateTime == null ? '' : myTask.ReminderDateTime.format('dd/MM/yyyy HH:mm');}
        public string getDescription(){return myTask.Description;}

    }

    public class HistoriqueRDV
    {
        public Event myEvent{set; get;}
        public HistoriqueRDV(Event event)
        {
            myEvent = event;
        }

        public string getDate(){return myEvent.StartDateTime.format('dd/MM/yyyy HH:mm');}
        public string getType(){return myEvent.Type;}
        public string getStatutRDV(){return myEvent.StatutRDV__c;}
        public string getLocation(){return myEvent.Location;}
        public string getCouple(){return myEvent.Couplepresent__c;}
        public string getDescription(){return myEvent.Description;}
    }
}