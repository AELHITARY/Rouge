//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : SectorisationUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/07/2017
//-- Version     : 1.1
//-- * 1.1 : Ajout de la fonction générique getSectorisation pour compte et chantier
//-- --------------------------------------------------------------------------------- --
public without sharing class SectorisationUtils {

    private static OrganisationKparK organisation;

    public class OrganisationKparK{
        public Map<String, String> regions  = new Map<String, String>();
        public Map<String, String> DVs      = new Map<String, String>();
        public Map<String, String> magasins = new Map<String, String>();
        public Map<String, String> DSs      = new Map<String, String>();
        public Map<String, String> depots   = new Map<String, String>();

        private OrganisationKparK() {
            for(AggregateResult ar : [select libelleRegion__c, codeRegion__c from Sectorisation__c GROUP BY libelleRegion__c, codeRegion__c]){
                if (ar.get('codeRegion__c') != null && ar.get('libelleRegion__c') != null)
                    regions.put(String.valueOf(ar.get('codeRegion__c')), String.valueOf(ar.get('libelleRegion__c')));
            }
            for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c GROUP BY libelleDV__c, codeDV__c]){
                if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                    DVs.put(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c')));
            }
            for(AggregateResult ar : [select libelleMagasin__c, codeMagasin__c from Sectorisation__c GROUP BY libelleMagasin__c, codeMagasin__c]){
                if (ar.get('codeMagasin__c') != null && ar.get('libelleMagasin__c') != null)
                    magasins.put(String.valueOf(ar.get('codeMagasin__c')), String.valueOf(ar.get('libelleMagasin__c')));
            }
            for(AggregateResult ar : [select libelleDS__c, codeDS__c from Sectorisation__c GROUP BY libelleDS__c, codeDS__c]){
                if (ar.get('codeDS__c') != null && ar.get('libelleDS__c') != null)
                    DSs.put(String.valueOf(ar.get('codeDS__c')), String.valueOf(ar.get('libelleDS__c')));
            }
            for(AggregateResult ar : [select codeDepot__c, libelleDepot__c from Sectorisation__c GROUP BY libelleDepot__c, codeDepot__c]){
                if (ar.get('codeDepot__c') != null && ar.get('libelleDepot__c') != null)
                    depots.put(String.valueOf(ar.get('codeDepot__c')), String.valueOf(ar.get('libelleDepot__c')));
            }
        }
    }

    public static OrganisationKparK getOrganisation() {
        if (organisation == null)
            organisation = new OrganisationKparK();
        return organisation;
    }  

    /**
    * @description Retourne l'Id de la sectorisation pour un compte ou chantier selon le code IRIS
    * @param newObj Objet contenant les données aprés la modification
    * @param oldObj Objet contenant les données avant la modification
    * @param sectorisationsByIris Map des sectorisations par IRIS
    * @param sectorisationsKStore Map des sectorisations pour les k-store
    * @param mappingKStore Mapping des k-store selon le code magasin
    * @return String Id de la sectorisation
    */
    public static String getSectorisation(SObject newObj,SObject oldObj, Map<String, Sectorisation__c> sectorisationsByIris,
                                            Map<String, Id> sectorisationsKStore, Set<String> mappingKStore) {
        UserContext newOwnerContext = UserContext.getContext(String.valueOf(newObj.get('OwnerId')));
        UserContext oldOwnerContext = oldObj == null ? null : UserContext.getContext(String.valueOf(oldObj.get('OwnerId')));
        String newObjIris=String.valueOf(newObj.get('iris__c'));
        String newObjCC=String.valueOf(newObj.get('codeCommune__c'));
        String newObjCP=String.valueOf(newObj.get('codePostal__c'));
        String newObjSect=String.valueOf(newObj.get('sectorisation__c'));
        String oldObjIris=oldObj == null ? null : String.valueOf(oldObj.get('iris__c'));
        String sectId = (String.isBlank(newObjSect)) ? null : newObjSect;

        system.debug('## Code newObj: ' + newObj);
        system.debug('## Code oldObj: ' + oldObj);
        system.debug('## Code sectorisationsByIris: ' + sectorisationsByIris);
        system.debug('## Code sectorisationsKStore: ' + sectorisationsKStore);
        system.debug('## Code mappingKStore: ' + mappingKStore);

        // Récupération code magasin
        String codeMagasin = String.valueOf(newObj.get('codeMagasinActuel__c'));
        if (codeMagasin == null && sectorisationsByIris.containsKey(newObjIris))
            codeMagasin = sectorisationsByIris.get(newObjIris).codeMagasin__c;
        codeMagasin += ':' + newOwnerContext.getuser().codeMagasin__c;
        system.debug('## Code Magasin: ' + codeMagasin);

        // Traitement recherche sectorisation
        system.debug('## INSEE: '+newObjCC+' / CP: '+newObjCP);
        if (mappingKStore.contains(codeMagasin) && newOwnerContext.isSaleUser() && (Trigger.isInsert || !oldOwnerContext.isSaleUser())) {
            sectId = sectorisationsKStore.get(newOwnerContext.getuser().codeMagasin__c);
            system.debug('## Sectorisation KStore '+sectId);
        }
        else if (Trigger.isInsert || newObjIris != oldObjIris || newObjSect == null) {
            if(sectorisationsByIris.containsKey(newObjIris)) {
                sectId = sectorisationsByIris.get(newObjIris).id;
                system.debug('## Sectorisation standard '+sectId);
            } else {
                // Recherche du 1er enregistrement de sectorisation__c dont le code commune correspond à celui recherché
                if(String.isNotBlank(newObjCC)){
                    for(Sectorisation__c  sector : sectorisationsByIris.values()) {
                        if(sector.codeCommuneAdm__c == newObjCC && !sector.iris__c.contains('MAG')) { // Recherche dégradée sur le code commune
                            sectId = sector.Id;
                            system.debug('## Sectorisation dégradé - Commune '+sectId);
                            break;
                        }
                    }
                }
                if(String.isNotBlank(newObjCP) && String.isBlank(sectId)){
                    // Recherche du 1er enregistrement de sectorisation__c dont le code postal correspond à celui recherché
                    for(Sectorisation__c  sector : sectorisationsByIris.values()) {
                        if(sector.codePostalAdm__c == newObjCP && !sector.iris__c.contains('MAG')) { // Recherche dégradée sur le code postal
                            sectId = sector.Id;
                            system.debug('## Sectorisation dégradé - CP '+sectId);
                            break;
                        }
                    }
                }
            }
        } 
        return sectId;
    }    
}