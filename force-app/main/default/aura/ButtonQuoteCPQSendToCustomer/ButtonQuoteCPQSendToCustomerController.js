({
    invoke : function(component, event, helper) {
      //alert(component.get("v.greeting") + ", " + component.get("v.subject"));
   },
    
	closeQA : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})