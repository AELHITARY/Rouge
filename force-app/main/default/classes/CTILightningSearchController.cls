//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : CTILightningSearchController 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 16/11/2020
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
global class CTILightningSearchController extends odigocti.RecordRetrievalLightningInterface_V3 {

    public override SearchResult SearchRecords(string phoneNumber, String internationalPhoneNumber, String localPhoneNumber, String folderId,
                                               String skill, String callId, String type, String IVRNumber)
    {
        
        system.debug('Ctrl_CTILightningSearchController - List of parameters ');
        system.debug('Ctrl_CTILightningSearchController - Phone Number: '+phoneNumber);
        system.debug('Ctrl_CTILightningSearchController - International Phone Number: '+internationalPhoneNumber);
        system.debug('Ctrl_CTILightningSearchController - Local Phone Number: '+localPhoneNumber);
        system.debug('Ctrl_CTILightningSearchController - FolderId: '+folderId);
        system.debug('Ctrl_CTILightningSearchController - Skill: '+skill);
        system.debug('Ctrl_CTILightningSearchController - CallId: '+callId);
        system.debug('Ctrl_CTILightningSearchController - Type: '+type);
        system.debug('Ctrl_CTILightningSearchController - IVRNumber: '+IVRNumber);
        
        SearchResult result = new SearchResult();
        String callerId = localPhoneNumber;
        if (callerId==null) callerId='';
        String callFolderId = folderId;
        if (callFolderId==null) callFolderId='';
        String callType = type;
        if (callType==null) callType ='';
        
        // Récupération du id du dossier et affichage de l'enregistrement associés
        if (String.isNotBlank(callFolderId)) {
            // Vérification de la validation de l'ID
            Boolean isValidId = true;
            try { Id testId = (ID)callFolderId; }
            catch (Exception e) { isValidId = false; }
            // ID valide, on affiche la page
            if(isValidId) {
                system.debug('## Call Folder');
                result.objectType = 'Url';
                Set<String> setIds = new Set<String>();
                setIds.add('/'+callFolderId);

                result.recordIds = setIds;
                return result;
            }
        } 
        
        if (String.isNotBlank(callerId) && callerId.length() > 2) {         
            // On Recherche s'il existe des contacts existants avec le numero transmis par le bandeau 
            List<List<SObject>> searchList = [FIND :callerId IN PHONE FIELDS RETURNING Contact(Id)];
            if (searchList!=null && !searchList.isEmpty()) {
                List<Contact> contacts = ((List<Contact>)searchList[0]);
                if (contacts != null && contacts.size() > 1) {
                    // Plusieurs contacts trouvés. On dirige vers la page de recherche
                    system.debug('## Find more than one contact-> Search page');
                    result.objectType = 'Search';
                    Set<String> setIds = new Set<String>();
                    setIds.add(callerId);
                    result.recordIds = setIds;
                    return result;
                }
                if (contacts != null && contacts.size() == 1) {
                    // Un seul contact trouvé. On dirige vers la page de contact
                    system.debug('## Only one contact -> contact page');
                    result.objectType = 'Contact';
                    Set<String> setIds = new Set<String>();
                    setIds.add(contacts[0].id);
                    result.recordIds = setIds;
                    return result;
                }
            }        
        }
        
        // Pas de numéro d'appel ou de dossier trouvé on dirige vers la page de création d'un contact
        System.debug('No contact -> PROSPECTX contact Page');
        String prospectX = PropertiesUtils.getStringValue('account.prospectx.id', '001D000001B0aQiIAJ');
        result.objectType = 'Account';
        Set<String> setIds = new Set<String>();
        setIds.add(prospectX);
        result.recordIds = setIds;
        return result;  
        
    }
}