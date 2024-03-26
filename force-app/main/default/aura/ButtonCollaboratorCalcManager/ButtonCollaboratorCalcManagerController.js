({
    /**
    * Initialisation du composant, appel à la fonction de calcul.
    * @param cmp - Object du composant Lightning principal.
    * @param event - Event du composant Lightning principal.
    * @param helper - Classe Helper du composant Lightning principal.
    */
    doInit: function(cmp, event, helper) {
        var title = "Calcul du responsable";
        
        // Initialisation des paramètres de l'action
        var action = cmp.get("c.calculateManager");
        action.setParams({
            "recordId":cmp.get("v.recordId")
        });

        action.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === 'SUCCESS'){
                var manager = resp.getReturnValue();
                if(resp.getReturnValue()) {
                	// Affichage message OK
                    helper.handleShowToast(cmp, title, "Affectation du responsable "+manager+" réussi", "success");
                } else {
                	// Affichage message OK
                    helper.handleShowToast(cmp, title, "Aucun responsable trouvé", "warning");
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        helper.handleShowToast(cmp, title, errors[0].message, "error");
                    }
                } else {
                    console.log("Unknown error");
                    helper.handleShowToast(cmp, title, "Erreur inconnue", "error");
                }
            }
			$A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
})