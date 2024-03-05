//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_LiveChat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/12/2017
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_LiveChat {
    public String accountId {get;set;}
    public String endpoint {get; set;}
    public String clientName {get;set;}
    public String clientFirstName {get;set;}
    public String email {get;set;}
    
    /**
    * @description Constructor
    * @return Ctrl_Site_LiveChat Constructor
    */
    public Ctrl_Site_LiveChat() {
        system.debug('### START Ctrl_Site_LiveChat : Constructor');
        //get the querystring data passed in by the button.  This is the liveagent form action
        //EX: ?endpoint=https%3A%2F%2F1.la1a1.salesforceliveagent.com... etc..
        endpoint = '';
        PageReference pageRef = ApexPages.currentPage();
        if (pageRef.getParameters() != null) {
            if (pageRef.getParameters().containsKey('endpoint')) {
                if (pageRef.getParameters().get('endpoint') != null) {
                    endpoint = pageRef.getParameters().get('endpoint');
                }
            }
        }
        system.debug('## endpoint : '+endpoint);

        system.debug('### END Ctrl_Site_LiveChat : Constructor');
    }

    /**
    * @description Function to create account and case and generate the chat page
    * @return Pagereference Visualforce page
    */
    public Pagereference clickChat() {
        PageReference pr = null;
        initAccount();
        initCase();
        return pr;
    }

    /**
    * @description Create the chat case
    */
    private void initCase(){
        system.debug('### START Ctrl_Site_LiveChat : initCase');

        system.debug('### END Ctrl_Site_LiveChat : initCase');
    }

    /**
    * @description Find account by email or create it
    */
    private void initAccount() {
        system.debug('### START Ctrl_Site_LiveChat : initAccount');
        List<Account> acc = new List<Account>();

        // Vérifie si le compte existe selon l'adresse email
        if(String.isNotBlank(email)) {
            // Requête SOSL pour optimiser performance
            List<List<SObject>> searchList = [FIND :email IN EMAIL FIELDS RETURNING Account (Id, Name) LIMIT 1];
            if (searchList!=null && !searchList.isEmpty()) {
                acc = ((List<Account>)searchList[0]);
            }
        }

        // Si pas de compte existant
        if (acc.isEmpty()) {
            // Création d'un nouveau compte personnel
            Account tpacc = new Account();
            tpacc.LastName = clientName;
            tpacc.FirstName = clientFirstName;
            tpacc.PersonEmail = email;
            tpacc.RecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

            acc.add(tpacc);
            try {
                insert acc;
            } catch(Exception ex) {
            }
            system.debug('## acc : '+String.valueOf(acc[0]));
        }
        accountId = acc[0].Id;
        system.debug('## accountId : '+accountId);
        system.debug('### END Ctrl_Site_LiveChat : initAccount');
    }
}