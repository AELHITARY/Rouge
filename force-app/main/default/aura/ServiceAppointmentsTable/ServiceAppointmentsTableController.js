({
    /**
    * Initialisation du tableau avec les données au chargement de la page.
    * @param cmp - Object du composant Lightning principal.
    * @param event - Event du composant Lightning principal.
    * @param helper - Classe Helper du composant Lightning principal.
    */
    doInit : function(cmp, event, helper) {
        
        // Initialisation des colonnes pour les RDV
        let tableColumns = [
            {
                'label':'Début planifié',
                'name':'SchedStartTime',
                'type':'datetime',
                'format':'DD/MM/YYYY HH:mm'
            },
            {
                'label':'Fin planifié',
                'name':'SchedEndTime',
                'type':'datetime',
                'format':'DD/MM/YYYY HH:mm',
                'visible':false
            },
            {
                'label':'Créneau arrivée',
                'name':'creneauArrivee__c',
                'type':'string'
            },
            {
                'label':'Type du RDV',
                'name':'WorkType.Name',
                'type':'string'
            },
            {
                'label':'Nom du client',
                'name':'Account.Name',
                'type':'string'
            },
            {
                'label':'Adresse',
                'name':'Chantier__r.adresseGeolocalisation__c',
                'type':'string'
            },
            {
                'label':'N° contrat',
                'name':'contractNumber__c',
                'type':'string'
            },
            {
                'label':'Vendeur du contrat',
                'name':'ownerName__c',
                'type':'string'
            },
            {
                'label':'Rue',
                'name':'Chantier__r.rue__c',
                'type':'string',
                'visible':false
            },
            {
                'label':'CP',
                'name':'Chantier__r.codePostal__c',
                'type':'string',
                'visible':false
            },
            {
                'label':'Ville',
                'name':'Chantier__r.ville__c',
                'type':'string',
                'visible':false
            },
            {
                'label':'Latitude',
                'name':'Latitude',
                'type':'number',
                'visible':false
            },
            {
                'label':'Longitude',
                'name':'Longitude',
                'type':'number',
                'visible':false
            },
            {
                'label':'Id projet',
                'name':'opportunityId__c',
                'type':'string',
                'visible':false
            },
            {
                'label':'Nom du projet',
                'name':'opportunityName__c',
                'type':'string',
                'visible':false
            },
            {
                'label':'Id contact',
                'name':'Contact.Id',
                'type':'string',
                'visible':false
            },
            {
                'label':'Nom du contact',
                'name':'Contact.Name',
                'type':'string',
                'visible':false
            }
            
        ];
        
        //Configuration de la DataTable
        let tableConfig = {            
            "rowAction":[
                {
                    "label":"Créer RDV de prospection",
                    "type":"url",
                    "id":"createRDV"
                }
            ],
            "rowActionPosition":'right'
        };
            
        
        // Requête SOQL de la fonction Aura du controlleur pour récupérer les RDV de service
        let action = cmp.get("c.getServiceAppointments");
        // Initialisation des paramètres
        action.setParams({
            "codeMagasinActuel":cmp.get("v.codeMagasin"),
            "userRole":cmp.get("v.userRole"),
            "userName":cmp.get("v.userName"),
            "startDatetime":cmp.get("v.startDatetime"),
            "endDatetime":cmp.get("v.endDatetime")
        });
        // Actions effectuées après l'appel
        action.setCallback(this,function(resp){
            let state = resp.getState();
            if(cmp.isValid() && state === 'SUCCESS'){
                //Envoi les résultats dans les lignes du tableau
                cmp.set("v.serviceAppointments",resp.getReturnValue());                
                //Envoi les information des colonnes
                cmp.set("v.tableColumns",tableColumns);                
                //Envoi la configuration
                cmp.set("v.tableConfig",tableConfig);                
                //initialise le tableau
                cmp.find("serviceAppointmentTable").initialize({
                    "order":[0,"desc"]
                });
            }               
        });
        $A.enqueueAction(action);
        
        // Récupération du current user
        let action2 = cmp.get("c.fetchUser");
        action2.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let storeResponse = response.getReturnValue();
                cmp.set("v.userInfo", storeResponse);
            }
        });
        $A.enqueueAction(action2);

        // Récupération de l'ID du type d'enregistrement
        let action3 = cmp.get("c.getEventProspectionRTId");
        action3.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let rtId = response.getReturnValue();
                cmp.set("v.eventProspectionRTId", rtId);
            }
        });
        $A.enqueueAction(action3);
    },

    /**
    * Mise à jour des lignes du tableau lorsque les filtres du calendrier sont changés
    * @param cmp - Object du composant Lightning principal.
    * @param event - Event du composant Lightning principal.
    * @param helper - Classe Helper du composant Lightning principal.
    */
    handleRerenderEvent: function(cmp, event, helper) {

        // Récupération des paramètres de l'évènement lightning et mise à jour des attributs
        cmp.set("v.codeMagasin", event.getParam("codeMagasin")); 
        cmp.set("v.userRole", event.getParam("userRole")); 
        cmp.set("v.userName", event.getParam("userName")); 
        cmp.set("v.startDatetime", event.getParam("startDatetime")); 
        cmp.set("v.endDatetime", event.getParam("endDatetime")); 

        // Initialisation des paramètres de l'action
        let action = cmp.get("c.getServiceAppointments");
        action.setParams({
            "codeMagasinActuel":cmp.get("v.codeMagasin"),
            "userRole":cmp.get("v.userRole"),
            "userName":cmp.get("v.userName"),
            "startDatetime":cmp.get("v.startDatetime"),
            "endDatetime":cmp.get("v.endDatetime")
        });

        action.setCallback(this,function(resp){
            let state = resp.getState();
            if(cmp.isValid() && state === 'SUCCESS'){
                //Envoi les résultats dans les lignes du tableau
                cmp.set("v.serviceAppointments",resp.getReturnValue());
                
                //Mise à jour des lignes du tableau
                cmp.find("serviceAppointmentTable").rerenderRows();
            }
        });
        $A.enqueueAction(action);
    },

    /**
    * Action de création d'un nouveau RDV de prospection selon la ligne du tableau de RDV de service
    * @param cmp - Object du composant Lightning principal.
    * @param event - Event du composant Lightning principal.
    * @param helper - Classe Helper du composant Lightning principal.
    */
    handleTableActionClick: function(cmp, event, helper){
        //get the id of the action being fired
        let actionId = event.getParam('actionId');
        if(actionId == 'createRDV'){
            // Call the function to open create event page
            helper.openCreateEventPage(cmp, event);
        }
    }
})