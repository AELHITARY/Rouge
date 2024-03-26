({
    navigateToURL : function(component, response) {
        var recordId = component.get("v.recordId");
        window.open('/apex/VF_Site_Questionnaire?oId='+recordId+'&qId=a2U6E000000KemT');
        $A.get("e.force:closeQuickAction").fire();
    }
})