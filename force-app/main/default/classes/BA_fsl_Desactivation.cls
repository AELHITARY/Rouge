//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_fsl_Desactivation
//-- Modifié par : CGI 
//-- Modifié le  : 19/03/2018
//-- Version     : 1.1
//-- * Activation / Désactivation référentielle par rapport aux dates de validité
//-- --------------------------------------------------------------------------------- --
global class BA_fsl_Desactivation implements Database.Batchable<sObject>, Database.Stateful{
    
    global List<WorkType> listeWT= new List<WorkType> ();
    global List<WorkType> listeWTaDesactiver = new List<WorkType> ();
    global List<WorkType> listeWTaActiver = new List<WorkType> ();
    
    global List<ServiceTerritory> listeST = new List<ServiceTerritory> ();
    global List<ServiceTerritory> listeSTaDesactiver = new List<ServiceTerritory> ();
    global List<ServiceTerritory> listeSTaActiver = new List<ServiceTerritory> ();
    
    global List<OperatingHours> listeOH = new List<OperatingHours> ();
    global List<OperatingHours> listeOHaDesactiver = new List<OperatingHours> ();
    global List<OperatingHours> listeOHaActiver = new List<OperatingHours> (); 
    
    global List<User> listeUser= new List<User> ();
    global List<User> listeUaDesactiver = new List<User> ();
    global List<User> listeUaActiver = new List<User> ();
    
  
    global Iterable<Sobject> start(Database.BatchableContext bc){
        system.debug('START');
        return new Iterator_fsl_Desactivation();
        
    } 
    
    global void execute(Database.BatchableContext bc, List<Sobject> listeSObject){
        system.debug('EXECUTE');      
        
        for (SObject objet : listeSObject){
            
            if (objet instanceof WorkType){
                WorkType wt = (WorkType)objet;
                system.debug('WorkType'+wt);                
                listeWT.add(wt);
            }
            
            if (objet instanceof OperatingHours){
                OperatingHours oh = (OperatingHours)objet;
                system.debug('OperatingHours'+oh);                 
                listeOH.add(oh);                       
            }
            
            if (objet instanceof ServiceTerritory){
                ServiceTerritory st = (ServiceTerritory)objet;
                system.debug('ServiceTerritory'+st);                 
                listeST.add(st);
            }      
            
           
            if (objet instanceof User){
                User u = (User)objet;
                system.debug('User'+u);                
                listeUser.add(u);
            }                                      
        }
        
        for(WorkType wt : listeWT){
            // Refonte GC : Calcul obsolète après suppression des dates d'ouverture et fermeture
            /*Boolean desactiverWT = FieldServiceUtils.crlDesactivation(wt.fsl_dateOuverture__c,wt.fsl_dateFermeture__c,wt.fsl_actif__c);
            system.debug('BOOLEAN '+desactiverWT);
            if(desactiverWT != null && desactiverWT == true){                    
                listeWTaDesactiver.add(wt);
            }else if (desactiverWT != null && desactiverWT == false){                    
                listeWTaActiver.add(wt);                
            }*/                              
        }
        
        /*for(operatingHours oh : listeOH){
            Boolean desactiverOH = FieldServiceUtils.crlDesactivation(oh.fsl_dateOuverture__c,oh.fsl_dateFermeture__c,oh.fsl_actif__c);
            system.debug('BOOLEAN '+desactiverOH);
            if(desactiverOH != null && desactiverOH == true){   
                listeOHaDesactiver.add(oh);
            }else if (desactiverOH != null && desactiverOH == false){                      
                listeOHaActiver.add(oh);                
            }         
        }*/
        
        /*for(ServiceTerritory st : listeST){
            Boolean desactiverST = FieldServiceUtils.crlDesactivation(st.fsl_dateOuverture__c,st.fsl_dateFermeture__c,st.IsActive);
            system.debug('BOOLEAN '+desactiverST);
            if(desactiverST != null && desactiverST == true){
                st.IsActive = false; 
                listeSTaDesactiver.add(st);
            }else if (desactiverST != null && desactiverST == false){
                st.IsActive = true;
                listeSTaActiver.add(st);                
            }           
        } */
        
        
        for(User u : listeUser){
            system.debug('User'+u);   
            Boolean desactiverUser = FieldServiceUtils.crlDesactivation(u.dateEntree__c,u.dateSortie__c,u.IsActive);
            system.debug('BOOLEAN '+desactiverUser);
            
            if(desactiverUser != null && desactiverUser == true){
                u.IsActive = false; 
                listeUaDesactiver.add(u);
            }else if (desactiverUser != null && desactiverUser == false){
                u.IsActive = true;
                listeUaActiver.add(u);                
            }                              
        }
        
        
        Database.update (listeWTaDesactiver,false);
        Database.update (listeWTaActiver,false);
        Database.update (listeSTaDesactiver,false);
        Database.update (listeSTaActiver,false);
        Database.update (listeOHaDesactiver,false);
        Database.update (listeOHaActiver,false);        
    }
    
    
    global void finish(Database.BatchableContext bc){
        system.debug('FINISH');
        system.debug('listeWT :'+listeWT.size()); 
        system.debug('listeOH :'+listeOH.size()); 
        system.debug('listeST :'+listeST.size());        
        system.debug('listeUser :'+listeUser.size());
        system.debug('listeWTaDesactiver :'+listeWTaDesactiver.size()+' '+listeWTaDesactiver);
        system.debug('listeWTaActiver :'+listeWTaActiver.size()+' '+listeWTaActiver);
        system.debug('listeSTaDesactiver :'+listeSTaDesactiver.size()+' '+listeSTaDesactiver);
        system.debug('listeSTaActiver :'+listeSTaActiver.size()+' '+listeSTaActiver);
        system.debug('listeOHaDesactiver :'+listeOHaDesactiver.size()+' '+listeOHaDesactiver);
        system.debug('listeOHaActiver :'+listeOHaActiver.size()+' '+listeOHaActiver);       
        system.debug('listeUaDesactiver'+listeUaDesactiver.size()+' '+listeUaDesactiver);
        system.debug('listeUaActiver'+listeUaActiver.size()+' '+listeUaActiver);
        Database.update (listeUaDesactiver,false);
        Database.update (listeUaActiver,false);
    }    
    
}