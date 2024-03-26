({
    navigateToURL : function(component, response) {
        var recId = component.get("v.recordId");
        window.open('/apex/FicheProjet?id='+recId,'_blank');
    }
})