//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_CreateFlowMapRecord
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_CreateFlowMapRecord {
    
    @InvocableMethod(label='Créer une Map Standard Id-Objet')
    public static List<CreateMapOutputs> createMap(List<CreateMapInputs> input) {        
        List<Utils_FlowMapRecordClass> flowMap = new List<Utils_FlowMapRecordClass>();
        Set<String> keyExist = new Set<String>();

        for(sObject sObj : input[0].records){
            String keyValue = (String)sObj.get(input[0].keyField);

            // Do not add record if key already existing
            if(keyExist.contains(keyValue) == false) {
                Utils_FlowMapRecordClass obj = new Utils_FlowMapRecordClass();
                obj.key = (String)sObj.get(input[0].keyField);
                obj.record = sObj;
                flowMap.add(obj);
                keyExist.add(keyValue);
            }   
        }

        CreateMapOutputs obj = new CreateMapOutputs();
        obj.flowMap = flowMap;
        
        List<CreateMapOutputs> result = new List<CreateMapOutputs>();
        result.add(obj);
        return result;
    }
    
    /* Input(s) for Invocable method */
    public class CreateMapInputs{
        @InvocableVariable(label='Liste des enregistrements' required=true)
        public List<sObject> records;
        @InvocableVariable(label='Nom API du champ pour la clé' required=true)
        public String keyField;
    }
    
    /* Output(s) for Invocable method */
    public class CreateMapOutputs{
        @InvocableVariable(label='Map')
        public List<Utils_FlowMapRecordClass> flowMap;
    }
}