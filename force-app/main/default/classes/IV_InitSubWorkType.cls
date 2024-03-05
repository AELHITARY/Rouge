//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_InitSubWorkType
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/04/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public class IV_InitSubWorkType {
    
    @InvocableMethod(label='Action Sub Work Type')
    public static List<FlowOutputParameters> initSubWorkType(List<FlowInputParameters> inputList){
        String workTypeName = inputList[0].workTypeName;
        List<String> casesIdList = inputList[0].casesIdList;
        String commandeId = inputList[0].commandeId;

        List<FlowOutputParameters> outputList = new List<FlowOutputParameters>();

        FlowOutputParameters out = new FlowOutputParameters();

        out.subWorkType = LWC_CustomWorkOrderWizard.initSubWorkType(workTypeName,casesIdList,commandeId);

        outputList.add(out);

        return outputList;
    }


    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Nom du WorkType' required = true )
        public String workTypeName;
        @InvocableVariable(label='Liste des Ids des resuêtes liées' required = true )
        public List<String> casesIdList;
        @InvocableVariable(label='Id de la commande' required = true )
        public String commandeId;
    }

    /* Output parameters of the Apex action */
    public class FlowOutputParameters{
        @InvocableVariable(label='Nom du SubWorkType')
        public String subWorkType;
    }
}