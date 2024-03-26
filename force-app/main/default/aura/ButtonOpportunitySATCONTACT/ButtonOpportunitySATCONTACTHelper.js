({
    navigateToURL : function(component, response) {
        var recId = component.get("v.recordId");
        var qId = "a2U2p0000041Ru1";
        window.open('/apex/VF_Site_Questionnaire?qId='+qId+'&oId='+recId,'_blank');
    }
})