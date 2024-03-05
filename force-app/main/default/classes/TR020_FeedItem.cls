//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_FeedItem 
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 04/04/2014
//-- Version     : 1.0
//-- * Fonction permettant de mettre une photo postée sur le feed d'un objet (chantier / compte / projet) en pièce jointe de ce chantier
//-- --------------------------------------------------------------------------------- --
public with sharing class TR020_FeedItem{

    // Récupération des valeurs de trigger.new
    public static void savePicture(UserContext userContext){
        List<FeedItem> InsertList = new List<FeedItem>();
        List<Attachment> attInsertList = new List<Attachment>();
        List<FeedItem> feedItemList = [Select Id, ParentId, ContentData, ContentType, Title, ContentSize FROM FeedItem WHERE Id in :trigger.new];
                    
        // Vérifie que le 'parentId' est bien un chantier, compte ou projet
        for (FeedItem fi : feedItemList){
            String parentId = fi.ParentId;
            if(parentId.startsWith('a08')) {
                InsertList.add(fi);  
            }
            else if(parentId.startsWith('001')) {
                InsertList.add(fi);  
            }
            else if(parentId.startsWith('006')) {
                InsertList.add(fi);  
            }
        }
        
        // Vérifie que le fichier est bien une image
        for (FeedItem fi : InsertList){
            if((fi.ContentType == 'image/jpeg') || (fi.ContentType == 'image/vnd.microsoft.icon') || (fi.ContentType == 'image/png') || (fi.ContentType == 'image/gif') || (fi.ContentType == 'image/svg+xml') || (fi.ContentType == 'image/tiff') || (Test.isRunningTest())){
                Attachment att = new Attachment();
                att.ParentId = fi.ParentId;
                att.Name = fi.Title + System.now().format('yyyy_MM_dd_hh_mm_ss');
                att.IsPrivate = false;
                att.ContentType = fi.ContentType;
                att.Body = fi.ContentData;
                
                if(fi.ContentSize < 5242880){
                    attInsertList.add(att);
                } 
            }
        }  
        if(!attInsertList.isEmpty())
            insert attInsertList;
    }
}