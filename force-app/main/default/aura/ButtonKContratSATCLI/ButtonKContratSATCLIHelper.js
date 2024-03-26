({
    navigateToURL : function(component, response) {
        var recId = component.get("v.recordId");
        var qId = "a2U57000001sdHC";
        window.open('/apex/VF_Site_Questionnaire?qId='+qId+'&oId='+recId,'_blank');
    }
})