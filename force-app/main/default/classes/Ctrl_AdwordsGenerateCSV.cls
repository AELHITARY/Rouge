//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_AdwordsGenerateCSV 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 01/03/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_AdwordsGenerateCSV {
    public List<CSVRow> csvRowValues1 { get; set; }
    public List<CSVRow> csvRowValues2 { get; set; }
    public List<CSVRow> csvRowValues3 { get; set; }

    /**
    * @description Constructeur
    * @return Ctrl_AdwordsGenerateCSV
    */
    public Ctrl_AdwordsGenerateCSV() {
        // Init
        csvRowValues1 = new List<CSVRow>();
        csvRowValues2 = new List<CSVRow>();
        csvRowValues3 = new List<CSVRow>();
    }
    
    /**
    * @description Fonction d'initialisation pour créer et alimenter les lignes du fichier CSV
    * @return VF_AdwordsGenerateCSV Objet référence de la page
    */
    public PageReference init() {
        Integer compteur = 0;
        
        // Traitement des variables pour conversion dans Adwords
        String conversionName = PropertiesUtils.getStringValue('adwords.conversion.name', 'Salesforce');
        String conversionTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ'); //Exemple : 2012-08-14T13:00:00+0500
        String conversionValue = PropertiesUtils.getStringValue('adwords.conversion.value', '1');
        
        // Boucle sur les projet pour ajout d'une ligne dans le CSV
        for (Opportunity projet : [SELECT Id, GCLID__c FROM Opportunity WHERE GCLID__c != '' AND dateEnvoiAdwords__c = TODAY]) {
            compteur++;
            CSVRow row = new CSVRow(projet.GCLID__c, conversionName, conversionTime, conversionValue);
            if(compteur <= 1000)
                csvRowValues1.add(row);
            else if (compteur > 1000 && compteur <= 2000)
                csvRowValues2.add(row);
            else if (compteur > 2000 && compteur <= 3000)
                csvRowValues3.add(row);
        }
        system.debug('## Taille liste export 1: ' + csvRowValues1.size());
        system.debug('## Taille liste export 2: ' + csvRowValues2.size());
        system.debug('## Taille liste export 3: ' + csvRowValues3.size());
        return null;
    }
    
    public class CSVRow {
        public String GCLID {get;set;}
        public String conversionName {get;set;}
        public String conversionTime {get;set;}
        public String conversionValue {get;set;}
        public CSVRow(String GCLID, String conversionName, String conversionTime, String conversionValue) {
            this.GCLID =  GCLID;
            this.conversionName = conversionName;
            this.conversionTime = conversionTime;
            this.conversionValue = conversionValue;
        }
    }
}