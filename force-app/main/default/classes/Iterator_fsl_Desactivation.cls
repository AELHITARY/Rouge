//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Iterator_fsl_Desactivation 
//-- Modifié par : CGI
//-- Modifié le  : 05/04/2018
//-- Version     : 1.0
//-- Description : Iterator pour récupérer les SObjects à désactivier
//-- --------------------------------------------------------------------------------- --
global class Iterator_fsl_Desactivation implements iterable<SObject>{
    global Iterator<SObject> Iterator(){
        return new CustomIterable_fsl_Desactivation();
    }
}