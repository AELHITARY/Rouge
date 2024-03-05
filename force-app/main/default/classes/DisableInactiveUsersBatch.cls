/**
 * @description       : Batch class to freeze inactive users (users that didn't login in last 30 days)
 * @author            : MA
 * @last modified on  : 01-27-2024
 * @last modified by  : MA
 * @version           : 1.0
**/

global class DisableInactiveUsersBatch implements Database.Batchable<sObject>, Database.Stateful {

    // Lists to keep track of successful updates and errors
    private List<UserLogin> usrLoginScope = new List<UserLogin>();
	private List<UserLogin> usrLoginSuccessList = new List<UserLogin>();
    private List<User> successList = new List<User>();
    private List<UserLogin> usrLoginErrrorList = new List<UserLogin>();
    private List<User> errorList = new List<User>();
	private Set<Id> scopeUsrIds = new Set<Id>();
	private Set<Id> succesUserIds = new Set<Id>();
	private Set<Id> errorUserIds = new Set<Id>();
	private Map<Id,String> errorsMap = new Map<Id,String>(); // to show the error associated with each User
	private Boolean isResultEmpty = true;

    // Start method to define the query for the batch process
    global Database.QueryLocator start(Database.BatchableContext batchC) {
        // Query to select inactive users, defined in a Custom Label for easy maintenance
        String query = Test.isRunningTest() ? System.Label.TestSOQLDisableInactiveUsersBatch : System.Label.SOQLDisableInactiveUsersBatch;
        return Database.getQueryLocator(query);
    }
 
    // Execute method called for each batch of records
    global void execute(Database.BatchableContext batchC, List<User> scope) {

		for (User usr : scope) {
			scopeUsrIds.add(usr.Id);
		}

		usrLoginScope = [ SELECT Id, UserId FROM UserLogin WHERE IsFrozen = false AND UserId IN : scopeUsrIds];

        // Set users as inactive
        for (UserLogin usrLogin : usrLoginScope) {
            usrLogin.IsFrozen = true;
        }

        // Perform update operation with partial success allowed
        Database.SaveResult[] saveResults = Database.update(usrLoginScope, false);

		if (!saveResults.isEmpty()) {
			isResultEmpty = false;
			// Iterate through each result to categorize into success or error
			for (Integer i = 0; i < saveResults.size(); i++) {
				if (saveResults[i].isSuccess()) {
					// Add successful updates to the success list
					usrLoginSuccessList.add(usrLoginScope[i]);
					succesUserIds.add(usrLoginScope[i].UserId);
				} else {
					// Add errors to the error list
					usrLoginErrrorList.add(usrLoginScope[i]);
					errorUserIds.add(usrLoginScope[i].UserId);
					for(Database.Error err : saveResults[i].getErrors()) {
						system.debug('Error on user with Id ' + usrLoginScope[i].UserId + ': ' + err.getMessage());
						errorsMap.put(usrLoginScope[i].UserId, err.getMessage());
					}
				}
			}
	
			if (!succesUserIds.isEmpty()) {
				successList = [SELECT Id, Name FROM User WHERE Id IN: succesUserIds];	
			}
	
			if (!errorUserIds.isEmpty()) {
				errorList = [SELECT Id, Name FROM User WHERE Id IN: errorUserIds];
			}
	
			System.debug('successList: '+successList);
			System.debug('errorList: '+errorList);
		}

    }
 
    // Finish method called after all batches are processed
    global void finish(Database.BatchableContext batchC) {
        // Send an email summarizing the batch process results
        sendEmail();
    }

    // Helper method to send an email notification
    private void sendEmail() {
        // Create a new email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String subject = System.Label.subjectDisableInactiveUsersBatch ;

        String body = System.Label.body1DisableInactiveUsersBatch + '\n \n' ;

		if (isResultEmpty) {
			body += System.Label.body3DisableInactiveUsersBatch;
		} else {
			// Adding details of successful updates
			if (!successList.isEmpty()) {
				body += System.Label.body2DisableInactiveUsersBatch  + successList.size() + '):\n';
				for (User usr : successList) {
					body += ' - Nom: ' + usr.Name + ', ID: ' + usr.Id + '\n';
				}
				body += '\n';
			}

			// Adding details of errors
			if (!errorList.isEmpty()) {
				body += 'Erreurs (' + errorList.size() + '):\n';
				for (User usr : errorList) {
					body += ' - Nom: ' + usr.Name + ', ID: ' + usr.Id  + ', Erreur: ' + errorsMap.get(usr.Id) + '\n';
				}
			}
		}

        // Set email subject and body
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        List<String> sendTo = new List<String>();
		sendTo.addAll((System.Label.EmailDisableInactiveUsersBatch).split(';'));
		System.debug('sendTo: '+sendTo);
        // Set the recipient - replace with actual email address
        mail.setToAddresses(sendTo);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}