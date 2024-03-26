({
    navigateToURL : function(component, response) {
        var recordId = component.get("v.recordId");
        window.open('/apex/VF_Signea?quoteId='+recordId);
    }
})