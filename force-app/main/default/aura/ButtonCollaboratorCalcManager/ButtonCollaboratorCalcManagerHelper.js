({
	handleShowToast : function(cmp, title, message, type) {
        cmp.find('notifLib').showToast({
            "title": title,
            "message": message,
            "variant": type
        });
    }
})