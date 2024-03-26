({
    navigateToURL : function(component, event, helper) {
    
        var urlEvent = $A.get("e.force:navigateToURL");
    	var quoteId = component.get("v.recordId");
        urlEvent.setParams({
          "url": '/apex/VF_DevisContrat_PDF?qId='+quoteId+'&doc=sansnum&type=DevisDepot',
          'isredirect' : "false"
        });
        urlEvent.fire();
    }
})