//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_SATCLIBaseCSV
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/02/2019
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-93 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_SATCLIBaseCSV implements Database.Batchable<sObject>, Database.Stateful {
    global BatchHistory__c batchHistoryStored {get;set;}
    global List<String> nomQuestions {get;set;}
    global Date dateDuFichier {get;set;}

    /***** Constructor *****/
    global BA_SATCLIBaseCSV(Date dateManuelle) {
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_SATCLIBaseCSV');
        }
        nomQuestions = new List<String>{'Q1-1','Q1-2','Q1-3','Q1-4','Q2-1','Q2-2-1','Q2-2-2','Q2-2-3','Q2-2-4','Q2-2-5','Q2-2-6','Q2-2-7','Q2-2-8','Q2-2-9',
            'Q2-3-1','Q2-3-2','Q2-3-3','Q2-3-4','Q2-3-5','Q3-1','Q3-2-1','Q3-2-2','Q3-2-3','Q3-2-4','Q3-2-5','Q4-1','Q4-2-1','Q4-2-2','Q4-2-3','Q4-2-4','Q4-2-5','Q4-2-6','Q4-2-7','Q4-2-8',
            'Q5-1-1','Q5-1-2','Q5-1-3','Q5-2','Q5-3','Q6-1','Q6-2','Q6-3'};
        system.debug('dateManuelle : '+dateManuelle);
        if(dateManuelle != null)
            dateDuFichier = dateManuelle;
        system.debug('dateDuFichier : '+dateDuFichier);
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les utilisateurs destinataires
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global List<User> start(Database.BatchableContext BC){
        system.debug('#### START BA_SATCLIBaseCSV.start()');
        try {
            String toUsersString = PropertiesUtils.getStringValue('satcli.csv.toUsers', 'tma.development.team.kpark@soprasteria.com');
            List<String> toUsersList = toUsersString.split(',');
            system.debug('toUsersList : '+toUsersList);
            List<User> usersToSend = [SELECT Id, Name, libelleMagasin__c, UserRoleId, UserRole.Name, CodeMagasin__c, FirstName, LastName, Email FROM User Where Email IN :toUsersList AND IsActive = true];
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            return usersToSend;
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] SATCLI : Erreur d\'initialisation d\'envoi du fichier de base SATCLI', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<User> scope){
        system.debug('#### START BA_SATCLIBaseCSV.execute()');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        try {
            List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
            List<String> sectoIdList = new List<String>();
            List<SatcliInfos> satcliInfosList = new List<SatcliInfos>();
            List<Resume_Questionnaire__c> resumeListFiltered = new List<Resume_Questionnaire__c>();
            Date startDate = Date.newInstance(1900, 1, 1);
            Map<String, List<Reponse_Questionnaire__c>> mapReponsesByRes = new Map<String, List<Reponse_Questionnaire__c>>();
            List<Sectorisation__c> sectoList = new List<Sectorisation__c>();

            Date monthToCheck = (dateDuFichier == null) ? Date.today().addDays(-10) : dateDuFichier;
            batchHistoryStored.nombreATraiter__c = 0;  

            for(Resume_Questionnaire__c resume : [SELECT Id, canalSaisie__c, compte__c, contrat__c, contrat__r.chantier__r.sectorisation__c, dateQuestionnaire__c, 
                                                                    contrat__r.derniereInstallation__c, contrat__r.chantier__r.codePostal__c, projet__c, questionnaire__c, requete__c
                                                        FROM Resume_Questionnaire__c 
                                                        WHERE CALENDAR_MONTH(dateQuestionnaire__c) = :monthToCheck.month() AND CALENDAR_YEAR(dateQuestionnaire__c) = :monthToCheck.year()]){
                resumeListFiltered.add(resume);
                sectoIdList.add(resume.contrat__r.chantier__r.sectorisation__c);
            }

            // Construction map des réponses par résumés
            for(Reponse_Questionnaire__c  rep : [SELECT Id, resume__c, reponseNumero__c, reponseTexte__c, type__c, question__c, question__r.numQuestion__c
                                                        FROM Reponse_Questionnaire__c WHERE resume__c IN :resumeListFiltered]) {
                List<Reponse_Questionnaire__c> listReponse;
                if(mapReponsesByRes.get(rep.resume__c) != null) {
                    listReponse = mapReponsesByRes.get(rep.resume__c);
                } else {
                    listReponse = new List<Reponse_Questionnaire__c>();
                } 
                listReponse.add(rep);
                mapReponsesByRes.put(rep.resume__c, listReponse);
                listReponse = null;
            }

            if(!sectoIdList.isEmpty())
                sectoList = [SELECT Id, libelleDepot__c, libelleDV__c, libelleRegion__c
                                                        FROM Sectorisation__c WHERE Id IN :sectoIdList];

            // Construction de l'objet réponse
            for(Resume_Questionnaire__c resu : resumeListFiltered){
                SatcliInfos ligneSatcliInfos = new SatcliInfos();
                Map<String,String> mapTemp = new Map<String,String>();

                String dateFormattedMonth = String.valueOf(resu.dateQuestionnaire__c.year());
                if(resu.dateQuestionnaire__c.month() < 10){
                    dateFormattedMonth += '0';
                }
                dateFormattedMonth += String.valueOf(resu.dateQuestionnaire__c.month());

                ligneSatcliInfos.accountId = (resu.compte__c == null) ? '' : resu.compte__c;
                ligneSatcliInfos.mois = (resu.dateQuestionnaire__c == null) ? '' : dateFormattedMonth;
                ligneSatcliInfos.dateDePose = (resu.contrat__r.derniereInstallation__c == null) ? '' : String.valueOf(resu.contrat__r.derniereInstallation__c.day()) + '/' 
                + String.valueOf(resu.contrat__r.derniereInstallation__c.month())  + '/' + String.valueOf(resu.contrat__r.derniereInstallation__c.year());
                ligneSatcliInfos.dateP2 = (resu.dateQuestionnaire__c == null) ? '' : String.valueOf(startDate.daysBetween(resu.dateQuestionnaire__c));             
                ligneSatcliInfos.codePostal = (resu.contrat__r.chantier__r.codePostal__c == null) ? '' : resu.contrat__r.chantier__r.codePostal__c;

                if(mapReponsesByRes.get(resu.Id) != null) {
                    for(Reponse_Questionnaire__c rep : mapReponsesByRes.get(resu.Id)){
                        if(String.isNotBlank(rep.question__c) && String.isNotBlank(rep.question__r.numQuestion__c) && String.isNotBlank(rep.type__c)) {
                            if(rep.type__c == 'Texte' && String.isNotBlank(rep.reponseTexte__c))
                                mapTemp.put(rep.question__r.numQuestion__c,rep.reponseTexte__c);
                            else if(rep.type__c == 'Radio' && String.isNotBlank(rep.reponseTexte__c)){
                                if(rep.reponseTexte__c == 'Très satisfait(e)') mapTemp.put(rep.question__r.numQuestion__c,'1');
                                else if(rep.reponseTexte__c == 'Satisfait(e)') mapTemp.put(rep.question__r.numQuestion__c,'2');
                                else if(rep.reponseTexte__c == 'Insatisfait(e)') mapTemp.put(rep.question__r.numQuestion__c,'3');
                                else if(rep.reponseTexte__c == 'Très insatisfait(e)') mapTemp.put(rep.question__r.numQuestion__c,'4');
                                else if(rep.reponseTexte__c == 'Oui') mapTemp.put(rep.question__r.numQuestion__c,'1');
                                else if(rep.reponseTexte__c == 'Non') mapTemp.put(rep.question__r.numQuestion__c,'0');
                                else mapTemp.put(rep.question__r.numQuestion__c,String.valueOf(rep.reponseNumero__c));
                            } else if(rep.type__c == 'Case à cocher' && String.isNotBlank(rep.reponseTexte__c)){
                                if(rep.reponseTexte__c.contains('Des modalités de paiement et des crédits offerts par notre partenaire Cetelem')) mapTemp.put(rep.question__r.numQuestion__c+'-1','1');
                                else mapTemp.put(rep.question__r.numQuestion__c+'-1','2');
                                if(rep.reponseTexte__c.contains('Des garanties K par K')) mapTemp.put(rep.question__r.numQuestion__c+'-2','1');
                                else mapTemp.put(rep.question__r.numQuestion__c+'-2','2');
                                if(rep.reponseTexte__c.contains('Des labels de qualité produits')) mapTemp.put(rep.question__r.numQuestion__c+'-3','1');
                                else mapTemp.put(rep.question__r.numQuestion__c+'-3','2');
                                if(rep.reponseTexte__c.contains('Du programme de parrainage')) mapTemp.put(rep.question__r.numQuestion__c+'-4','1');
                                else mapTemp.put(rep.question__r.numQuestion__c+'-4','2');
                                if(rep.reponseTexte__c.contains('De la certification')) mapTemp.put(rep.question__r.numQuestion__c+'-5','1');
                                else mapTemp.put(rep.question__r.numQuestion__c+'-5','2');
                            } else
                                mapTemp.put(rep.question__r.numQuestion__c,String.valueOf(rep.reponseNumero__c));
                        }
                    }
                }
                ligneSatcliInfos.reponsesMap = mapTemp;

                ligneSatcliInfos.libelleSecteurCommercial = '';
                ligneSatcliInfos.depot = '';
                ligneSatcliInfos.dv = '';
                ligneSatcliInfos.drdv = '';
                ligneSatcliInfos.drdepot = '';
                for(Sectorisation__c sec : sectoList){
                    if(sec.Id == resu.contrat__r.chantier__r.sectorisation__c) {
                        ligneSatcliInfos.libelleSecteurCommercial = (sec.libelleRegion__c == null) ? '' : sec.libelleRegion__c;
                        ligneSatcliInfos.depot = (sec.libelleDepot__c == null) ? '' : sec.libelleDepot__c;
                        ligneSatcliInfos.dv = (sec.libelleDV__c == null) ? '' : sec.libelleDV__c;
                        ligneSatcliInfos.drdv = (sec.libelleRegion__c == null) ? '' : sec.libelleRegion__c;
                        ligneSatcliInfos.drdepot = '';
                    }
                }
                satcliInfosList.add(ligneSatcliInfos);
            }

            // Génération du CSV de l'utilisateur
            String dateOfDayFormat = monthToCheck.month()+'/'+monthToCheck.year();
            String dateOfDayTexte = monthToCheck.month()+''+monthToCheck.year();
            String header = 'MOIS,ID,DATE_DE_POSE,LIB_SECT_COMMERC,DATE_P2,';
            for(String nomQ : nomQuestions){
                header+= nomQ+',';
            }
            header+= 'CP,DEPOT,DV,DR DV,DR DEPOT \n';
            String emailSubject = 'Fichier de base SATCLI du ' + dateOfDayFormat;
            String attachmentFileName = 'satcli_base_' + dateOfDayTexte + '.csv';
            system.debug('Email sujet : ' + emailSubject);
            system.debug('Pièce jointe : ' + attachmentFileName);
            String finalCSVBody = header;
            for(SatcliInfos si: satcliInfosList) {
               String record = si.mois+','+si.accountId+','+si.dateDePose+','+si.libelleSecteurCommercial+','+si.dateP2+',';
               for(String nomQ : nomQuestions){
                    if(si.reponsesMap.get(nomQ) != null)
                        record += si.reponsesMap.get(nomQ).replace('\n',' ').replace(',',' ')+',';
                    else
                        record += ' ,';
                }
               record += si.codePostal+','+si.depot+','+si.dv+','+si.drdv+','+si.drdepot +'\n';
               finalCSVBody += record;
            }

            // Envoi email par destinataires
            User destinataire = null;
            for (User usr : scope) {
                if(usr.Email != null) 
                    destinataire = usr;
            }

            if(!scope.isEmpty() && destinataire.Email != null) {
                Blob satcliBaseCSV = null;
                
                // Selection du modèle d'email
                List<EmailTemplate> emailTemplateTemp = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName ='SATCLI_Base'];
                EmailTemplate emailTemplate = emailTemplateTemp[0];
                batchHistoryStored.nombreATraiter__c++;

                // Piece jointe
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                blob csvBlob = Blob.valueOf(finalCSVBody);
                emailAttachment.setFileName(attachmentFileName);
                emailAttachment.setBody(csvBlob);

                // Construction de l'email et envoi
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
                email.setSubject(emailSubject);
                //email.setFileAttachments(new Messaging.EmailFileAttachment[]{emailAttachment});
                
                OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'support@kpark.fr'];
                email.setOrgWideEmailAddressId(fromAddress.Id);
                email.setTargetObjectId(destinataire.Id);
                email.setSaveAsActivity(false);

                // Defini les destinataires
                String toAddressesString = PropertiesUtils.getStringValue('satcli.csv.toUsers', 'tma.development.team.kpark@soprasteria.com');
                email.setToAddresses(toAddressesString.split(','));
                
                // Defini les destinataires en copie caché
                String bccAddressesString = PropertiesUtils.getStringValue('satcli.csv.bccAddresses', 'tma.development.team.kpark@soprasteria.com');
                email.setBccAddresses(bccAddressesString.split(','));
                
                // Genération du body
                Map<String, String> mapBodyParams = new Map<String, String> {
                    '{!Date}' => dateOfDayFormat
                };
                String htmlBody = emailTemplate.HtmlValue;
                String plainBody = emailTemplate.Body;
                for (String key : mapBodyParams.keySet()) {
                    htmlBody = htmlBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                    htmlBody = htmlBody.replace(']]>', '');
                    htmlBody = htmlBody.replace('<![CDATA[', '');
                    plainBody = plainBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                }
                email.setHtmlBody(htmlBody);
                email.setPlainTextBody(plainBody);
                email.setFileAttachments(new List<Messaging.EmailFileAttachment> { emailAttachment });
                // Ajout de l'email dans la liste d'envoi
                emailsToSent.add(email);
            }

            batchHistoryStored.nombreTraite__c = emailsToSent.size();   
            
            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                system.debug('result : ' + result);

                Integer successCount = 0;
                for (Messaging.SendEmailResult savedResult : result) {
                    if (savedResult.isSuccess()) {
                        successCount++;
                    } else {
                        batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, savedResult.getErrors() + '\n');
                    }
                }
                batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
            }
        }
        catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] SATCLI : Erreur d\'initialisation d\'envoi du fichier de base SATCLI', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        system.debug('#### END BA_SATCLIBaseCSV.execute()');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        system.debug('#### START BA_SATCLIBaseCSV.finish()');
        // Mise à jour des stats
        batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        system.debug('#### END BA_SATCLIBaseCSV.finish()');
    }

    // Classe structure pour les informations des objets automatiquement créés
    public class SatcliInfos{
        public Id accountId {get; set;}
        public String mois {get; set;}
        public String dateDePose {get; set;}
        public String libelleSecteurCommercial {get; set;}
        public String dateP2 {get; set;}
        public Map<String,String> reponsesMap {get; set;}
        public String codePostal {get; set;}
        public String depot {get; set;}
        public String dv {get; set;}
        public String drdv {get; set;}
        public String drdepot {get; set;}
    }
}