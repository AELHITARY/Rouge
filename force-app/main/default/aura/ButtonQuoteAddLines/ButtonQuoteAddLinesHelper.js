({
    navigateToURL : function(component, response) {
        var recordId = component.get("v.recordId");
        window.open('/apex/VF001_Quote_SelectProduct?id='+recordId);
    }
})