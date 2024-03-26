({
	doInit: function(component, event, helper) {    
        helper.toggleSpinner(true,component); // loading  
        // Liste des metadatas
        helper.getMetadatas(component,helper);
        helper.setPickListObject(component,event,helper);
    },

    objectStructureLoad: function(component, event, helper) { 
        var searchObjectName = component.get("v.searchObjectName");  
        helper.getStructure(component, event, helper, searchObjectName);
    },
    
    doDeleteMetadata: function(component, event, helper) {        
        if(confirm('Êtes-vous sûr de vouloir supprimer cette règle ?')) {           
            // Affiche le bouton de création et cache les éléments de création/modification
            component.set("v.showButtonCreate",true);
            component.set("v.showAddTable",false);
            component.set("v.showModifyTable",false);
            // Supprimer la règle
    		helper.deleteMetadata(component, event, helper);   
        }
	},
    
    /**
     * MODE CREATION - Méthode exécutée quand l'objet de principal est modifié.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    objectNamedChange : function(component, event, helper) {
        var objectName = event.getSource().get("v.value");
        component.set("v.objetJointure", "");         
        component.set("v.picklistVal_ChampJointure", "");
        component.set("v.picklistVal_ChampJointure","");
        component.set("v.defaultOptions2", []);
        helper.getFieldValues(component, event, helper, objectName);
        helper.getObjectDepedencies(component, event, helper, objectName);
    },
    
    /**
     * MODE CREATION - Méthode exécutée quand l'objet de jointure est modifié.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    objectJointChanged : function(component, event, helper) {
        var objectParentName = event.getSource().get("v.value");
        var objectChildName = component.find('propNomObjet').get("v.value");
        // Si pas de sélection d'objet de jointure, supprime les champ de jointure
        if($A.util.isUndefinedOrNull(objectParentName) || objectParentName == "") {
            component.set("v.picklistVal_ChampJointure","");
            component.set("v.defaultOptions2", []);
        } else {        
            // Sinon mise à jour des champs
            helper.objectJointChanged(component, helper, objectParentName, objectChildName, null);
        }
    },
    
    /**
     * MODE EDITION - Méthode exécutée quand l'objet de jointure est modifié.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    objectJointChangedModify : function(component, event, helper) {
        var objectParentName = event.getSource().get("v.value");
        var objectChildName = component.get("v.metadataToModify.nomObjet__c");
        // Si pas de sélection d'objet de jointure, supprime les champ de jointure
        if($A.util.isUndefinedOrNull(objectParentName) || objectParentName == "") {
            component.set("v.picklistVal_ChampJointure","");
            component.set("v.defaultOptions2Modif", []);
        } else {        
            // Sinon mise à jour des champs
            helper.objectJointChanged(component, helper, objectParentName, objectChildName, null);
        }
    },
    
    /**
     * MODE Création - Méthode exécutée quand l'utilisateur sélectionne des champs de jointure.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     */
    champJointureChange: function (component, event) {
        // Récupère les enregistrements sélectionné dans les champs
        var selectedOptionValue = event.getParam("value");
        component.set("v.defaultOptions2", selectedOptionValue);
    },
    
    /**
     * MODE EDITION - Méthode exécutée quand l'utilisateur sélectionne des champs de jointure.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     */
    champJointureChangeModify: function (component, event) {
        // Récupère les enregistrements sélectionné dans les champs
        var selectedOptionValue = event.getParam("value");
        component.set("v.defaultOptions2Modif", selectedOptionValue);
    },
    
    /**
     * MODE CREATION - Méthode pour ouvrir le panneau en mode CREATION.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */    
    doOpenTable: function(component, event, helper) {
        helper.toggleSpinner(true,component); // loading 
        helper.resetData(component); // RAZ des champs
        // Affiche le tableau de création et cache les boutons de création/modification
        component.set("v.showButtonCreate",false);
        component.set("v.showAddTable",true);
        component.set("v.showModifyTable",false);
        helper.toggleSpinner(false,component);
    },
    
    /**
     * MODE CREATION - Méthode pour éxécuter la création de la règle.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    doCreateMetadata : function(component, event, helper) {
        helper.toggleSpinner(true,component); // loading   
        helper.displayError("",component);
        helper.newMetadata(component, event, helper);   
        component.set("v.showButtonCreate",true);
    },
    
    /**
     * MODE EDITION - Méthode pour ouvrir le panneau en mode EDITION.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    doOpenModifyTable: function(component, event, helper) {
        helper.toggleSpinner(true,component); // loading 
        helper.resetData(component); // RAZ des champs
        // Affiche le bouton de création et éléments de modification et cache les éléments de création
        component.set("v.showModifyTable",true);
        component.set("v.showAddTable",false);
        component.set("v.showButtonCreate",true);
        // Récupère les infos de la règle à modifier
        var param = event.getSource().get("v.name").split(";");
        var paramId = param[0];
        component.set("v.metadataId", paramId);
        helper.getMetadataById(component, event, helper, paramId);
        var objectName = param[1];
        var objectChildName = param[2];
        var champsExclus = param[3].split(",");
        var champJointure = param[4].split(",");
        // Alimente le champ "Champ Exclus"
        helper.getFieldValues(component, event, helper, objectName);
        // Alimente le champ "Objet dépendant"
        helper.getObjectDepedencies(component, event, helper, objectName);
        component.set('v.objetJointure', objectChildName);
        component.set("v.defaultOptionsModif",champsExclus);
        // Alimente le champ "Champs de jointure"
        helper.objectJointChanged(component, helper, objectChildName, objectName, champJointure);
        // Alimente les autre champs
        component.find("propActifModif").set("v.checked", param[5]);
        component.find("propPrioriteModif").set("v.value", param[6]);
        helper.toggleSpinner(false,component);
    },
    
    /**
     * MODE EDITION - Méthode pour éxécuter la modification de la règle.
     * @param component - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */
    doModifyMetadata : function(component, event, helper) {
        helper.toggleSpinner(true,component); // loading 
        helper.displayError("",component);
        var paramId = component.get("v.metadataId");
        helper.modifyMetadataById(component, event, helper, paramId);
        component.set("v.showModifyTable",false);
        helper.toggleSpinner(false,component); 
    }
})