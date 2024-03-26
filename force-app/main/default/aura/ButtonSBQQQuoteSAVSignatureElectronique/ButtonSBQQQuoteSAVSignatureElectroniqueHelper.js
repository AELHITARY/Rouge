({
    navigateToURL : function(component, response) {
        var quoteId = component.get("v.recordId");
        window.open('/apex/VF_Signea_CPQ_SAV?quoteId='+quoteId,'_blank');
        console.log('quoteId',quoteId);        
    }
})