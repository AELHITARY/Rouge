//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_SATCLI_GenerationManuelle 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/03/2019
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_SATCLI_GenerationManuelle {
    
    public String moisSelected { get; set; }
    public String anneeSelected { get; set; }
    public String usersList { get; set; }
    public List<SelectOption> annee { get; set; }{
        Integer i = 2010;
        annee = new List<SelectOption>();
        for(i=2010;i<=Date.today().year();i++){
            annee.add(new SelectOption(i+'', i+''));
        }
    }

    public List<SelectOption> mois { get; set; }{
        Integer i = 1;
        List<String> moisList = Constants.MONTHS;
        mois = new List<SelectOption>();
        for(i=1;i<=12;i++){
            mois.add(new SelectOption(i+'', moisList[i-1]));
        }
    }
    
    /**
    * @description Constructeur
    * @return Ctrl_SATCLI_GenerationManuelle 
    */
    public Ctrl_SATCLI_GenerationManuelle() {
        String usersList = PropertiesUtils.getStringValue('satcli.csv.toUsers', 'SOPRA Développement');
    }

    /**
    * @description Génération CSV
    * @return PageReference Page Visualforce
    */
    public void executeSATCLI(){
        system.debug('### DEBUT genererSATCLI');
        Date dateToGenerate = date.newInstance(Integer.valueOf(anneeSelected), Integer.valueOf(moisSelected), 1);

        // Exécution du Batch 
        BA_SATCLIBaseCSV batchAcc = new BA_SATCLIBaseCSV(dateToGenerate);
        database.executebatch(batchAcc);
        system.debug('### FIN genererSATCLI');    }

}