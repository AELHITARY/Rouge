//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_GetValueFromMapRecord
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_GetValueFromMapRecord {

    @InvocableMethod(label='Récupérer une valeur avec une clé depuis une Map')
    public static List<GetValueOutputs> getValue(getValueInputs[] input	){
        List<GetValueOutputs> result = new List<GetValueOutputs>();
        
        for(Utils_FlowMapRecordClass loopObj : input[0].flowMap){
            if(loopObj.key == input[0].key){
                GetValueOutputs obj = new GetValueOutputs();
                obj.outputValue = loopObj.record;
                result.add(obj);
            }
        }
        
        return result;        
    }
    
    public class GetValueInputs{
        @InvocableVariable(label='Clé' required=true)
        public string key;
        @InvocableVariable(label='Map' required=true)
        public List<Utils_FlowMapRecordClass> flowMap;
    }
    
    public class GetValueOutputs{
        @InvocableVariable(label='Value' required=true)
        public sObject outputValue;
    }
}