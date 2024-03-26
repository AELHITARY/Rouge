({
    navigateToURL : function(component, response) {
        var recId = component.get("v.recordId");
        var qId = "a2U68000000PAvMEAW";
        window.open('/apex/VF_Site_Questionnaire?qId='+qId+'&newQues=yes&oId='+recId,'_blank');
    }
})