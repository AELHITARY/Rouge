({
    /*navigateToURL : function(component, response) {
        var quoteId = component.get("v.recordId");
        window.open('/apex/VF_AttestationTVA_PDF?qId='+quoteId,'_blank');
    }*/
    
    navigateToURL : function(component, event, helper) {
    
        var urlEvent = $A.get("e.force:navigateToURL");
    	var quoteId = component.get("v.recordId");
        urlEvent.setParams({
          "url": '/apex/VF_AttestationTVA_PDF?qId='+quoteId,
          'isredirect' : "false"
        });
        urlEvent.fire();
    }
})