//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : CustomIterable_fsl_Desactivation
//-- Modifié par : CGI
//-- Modifié le  : 05/04/2018
//-- Version     : 1.0
//-- Description : Iterator pour récupérer les SObjects à désactivier
//-- --------------------------------------------------------------------------------- --
global class CustomIterable_fsl_Desactivation implements Iterator<SObject>{
 public Iterator<SObject> iterator() { return this; }  
   List<SObject> sobjs {get; set;} 
   Integer i {get; set;} 
    
   public CustomIterable_fsl_Desactivation(){ 
       sobjs = new List<SObject>();
        
       /*List<OperatingHours> listeOH = [SELECT id, fsl_actif__c, fsl_dateOuverture__c, fsl_dateFermeture__c FROM OperatingHours ]; 
       for( OperatingHours oh : listeOH ) {
           sobjs.add(oh);
       }*/
       
       List<WorkType> listeWT = [SELECT id FROM WorkType LIMIT 50]; 
       for( WorkType wt : listeWT ) {
           sobjs.add(wt);
       }
       
       List<ServiceTerritory> listeST = [SELECT id, IsActive FROM ServiceTerritory LIMIT 50]; 
       for( ServiceTerritory st : listeST ) {
           sobjs.add(st);
       }
       
       Profile[] pf= [Select Id from profile where Name LIKE '%Ressource%']; 
       List<User> listeUser = [SELECT id,ManagerId,Manager.email,IsActive, dateEntree__c, dateSortie__c FROM User where ProfileId IN :pf LIMIT 50]; 
       for( User u : listeUser ) {
           sobjs.add(u);
       }
       
       
       
       i = 0; 
   }   
   global boolean hasNext(){ 
       if(i >= sobjs.size()) 
           return false; 
       else 
           return true; 
   }    
   global SObject next(){ 
       if(i == sobjs.size()){ return null;} 
       i=i+1; 
       return sobjs[i-1]; 
   } 
}