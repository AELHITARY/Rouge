//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : CTISearchPageController 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 17/10/2019
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
public class CTISearchPageController {
    public PageReference CTIScreenPop() {
        String callerId = ApexPages.currentPage().getParameters().get('Phone_number');
        String callFolderId = ApexPages.currentPage().getParameters().get('Call_Folder_ID');

        // On Recherche en priorité les opportunités existantes avec le numero de dossier transmis par le bandeau 
        if (!String.isBlank(callFolderId) && callFolderId.length() > 2) {
            PageReference resultPage = new PageReference ('/'+callFolderId);
            resultPage.setRedirect(true);
            return resultPage;         
        }
        
        // On Recherche s'il existe des contacts existants avec le numero transmis par le bandeau 
        if (!String.isBlank(callerId) && callerId.length() > 2) {
            List<List<SObject>> searchList = [FIND :callerId IN PHONE FIELDS RETURNING Contact(Id)];
            if (searchList!=null && searchList.size() > 0) {
                List<Contact> contacts = ((List<Contact>)searchList[0]);
                if (contacts != null && contacts.size() > 1) {
                    // Plusieurs contacts trouvés. On dirige vers la page de recherche
                    PageReference searchPage = new PageReference ('/_ui/search/ui/UnifiedSearchResults?searchType=2&str=' + callerId);
                    return searchPage ;
                }
                if (contacts != null && contacts.size() == 1) {
                    // Un seul contact trouvé. On dirige vers la page de contact
                    PageReference contactPage = new ApexPages.StandardController(contacts[0]).view();
                    contactPage.setRedirect(true);
                    return contactPage ;
                }
            }        
        }
        
        // Pas de numéro d'appel ou de dossier trouvé on dirige vers la page de création d'un contact
        String prospectX = PropertiesUtils.getStringValue('account.prospectx.id', '001D000001B0aQiIAJ');
        PageReference unknowAccount = new PageReference ('/'+prospectX);
        unknowAccount.setRedirect(true);
        return unknowAccount ;        
    }
}