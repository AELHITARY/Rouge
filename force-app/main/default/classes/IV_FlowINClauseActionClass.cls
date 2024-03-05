//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_FlowINClauseActionClass
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/09/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public class IV_FlowINClauseActionClass {
    
    @InvocableMethod(label='Obtenir des enregistrements avec le filtre IN')
    public static FlowOutputParameters[] filterRecords(FlowInputParameters[] inputList) {
        
        String[] combinedFilterValuesCollection = new String[]{};

        // Récupération des paramètres des précédentes instances du flux
        // Corriger l'erreur : The number of results does not match the number of interviews that were executed etc...
        for( IV_FlowINClauseActionClass.FlowInputParameters input : inputList ){
            for(String s : input.filteringValuesCollection){
                if( !combinedFilterValuesCollection.contains(s) ){
                    combinedFilterValuesCollection.add(s);
                }
            }
        }

        // Conversion de la liste en string
        String filterValuesList='(';
        for(integer i=0 ; i < combinedFilterValuesCollection.size();i++){
            String filterValue = combinedFilterValuesCollection[i];
            filterValuesList += '\''+filterValue+'\'';
            if(i != combinedFilterValuesCollection.size()-1)
                filterValuesList += ',';
        }
        filterValuesList += ')';

        String query = 'SELECT '+ inputList[0].fieldsToQuery + ' FROM ' +  inputList[0].objectApiName + ' WHERE '+inputList[0].filterField +' IN ' + filterValuesList;
        IV_FlowINClauseActionClass.FlowOutputParameters[] outputList = new IV_FlowINClauseActionClass.FlowOutputParameters[]{};

        try{
            SObject [] recordList = database.query(query);
            
            for(FlowInputParameters input : inputList){
                IV_FlowINClauseActionClass.FlowOutputParameters output = new IV_FlowINClauseActionClass.FlowOutputParameters();
                SObject[] filteredRecords = new SObject[]{};
                for(SObject s : recordList){
                    if(input.filteringValuesCollection.contains( (String)s.get(inputList[0].filterField) )){
                        filteredRecords.add(s);
                    }
                }
                output.records = filteredRecords;
                outputList.add( output );
            }
            return outputList;
        }catch(Exception e){
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Nom API de l\'objet' required = true )
        public String objectApiName;
        
        @InvocableVariable(label='Nom API des champs à récupérer (séparée par des virgules)' required = true)
        public String fieldsToQuery;
            
        @InvocableVariable(label='Nom API du champ à filtrer (filtre IN)' required = true)
        public String filterField;
        
        @InvocableVariable(label='Collection de valeurs pour le filtre' required = true)
        public String[] filteringValuesCollection;        
    }
    
    /* Output parameters of the Apex action */
    public class FlowOutputParameters{
        
        @InvocableVariable(label='Collection d\'enregistrement')
        public sObject[] records;
    }
}