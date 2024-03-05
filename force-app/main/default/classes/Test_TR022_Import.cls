//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR022_Import
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 28/02/2023
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR022_Import {    
    private static final Id refSourceRT = DAL.getRecordTypeIdByDevName('Referencial__c','Source'); 

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refSourceRT, true, true, true, true, false);
        refMag.usableForSales__c = true;
        insert refMag;
        
        PriceBook2 pb2 = new PriceBook2(name = 'Catalogue standard', isActive = True);
        insert pb2;
        
        ReferentielOperation__c operation = new ReferentielOperation__c();
        operation.name = 'FOIRE DE PARIS';
        operation.dateDebut__c = System.today() - 15;
        operation.dateFin__c = System.today()  + 15;
        operation.origine__c = 'FOIRE';
        operation.surfaceDuStand__c = 'HC : Hors-catégorie';
        operation.code_DV__c = 'TST';
        operation.source__c = refMag.Id;
        insert operation;
    }   

    @isTest 
    static void test_import() {
        Boolean locataire = false;
        List<Import__c> importedItems = new List<Import__c>();

        Import__c import1 = buildImport(1, false, false);
        import1.nomFichierSource__c = 'formulaire_site_kpark.fr';
        import1.callSource__c = '';
        import1.source__c = 'WEB';
        
        Import__c import1bis = buildImport(10, false, false);
        import1bis.nomFichierSource__c = 'formulaire_site_kpark.fr';
        import1bis.callSource__c = '';
        import1bis.source__c = 'WEB';
        
        import1bis.quantitePergola__c           = 1;
        import1bis.materiauxPergola__c          = 'Aluminium';
        import1bis.quantiteCarport__c           = 1;
        import1bis.materiauxCarport__c          = 'Aluminium';
        import1bis.quantiteCoulissant__c        = 1;
        import1bis.materiauxCoulissant__c       = 'PVC';
        import1bis.quantiteFenetre__c           = 1;
        import1bis.materiauxFenetre__c          = 'PVC';
        import1bis.quantiteIsolationCombles__c  = 1;
        import1bis.materiauxIsolationCombles__c = 'Laine de roche';
        import1bis.quantiteMoustiquaire__c      = 1;
        import1bis.materiauxMoustiquaire__c     = 'Enroulables';
        import1bis.quantitePersienne__c         = 1;
        import1bis.materiauxPersienne__c        = 'PVC';
        import1bis.quantitePortail__c           = 1;
        import1bis.materiauxPortail__c          = 'PVC';        
        import1bis.quantitePorteBlindee__c      = 1;
        import1bis.materiauxPorteBlindee__c     = 'Palière';
        import1bis.quantitePorteEntree__c       = 1;
        import1bis.materiauxPorteEntree__c      = 'PVC';
        import1bis.quantitePorteInterieur__c    = 1;
        import1bis.materiauxPorteInterieur__c   = 'Bois';
        import1bis.quantitePorteGarage__c       = 1;
        import1bis.materiauxPorteGarage__c      = 'Sectionnelles';
        import1bis.quantitePorteService__c      = 1;
        import1bis.materiauxPorteService__c     = 'PVC';
        import1bis.quantitePorteFenetre__c      = 1;
        import1bis.materiauxPorteFenetre__c     = 'PVC';
        import1bis.quantiteStoreBanne__c        = 1;
        import1bis.materiauxStoreBanne__c       = 'Aucun';
        import1bis.quantiteVoletBattant__c      = 1;
        import1bis.materiauxVoletBattant__c     = 'PVC';
        import1bis.quantiteVoletRoulant__c      = 1;
        import1bis.materiauxVoletRoulant__c     = 'PVC';

        Import__c import2 = buildImport(2, true, false);
        import2.nomFichierSource__c = 'formulaire_site_parrainage';
        import2.callSource__c = '';
        import2.source__c = 'PASSAGE MAGASIN';

        Import__c import3 = buildImport(3, false, true);
        import3.nomFichierSource__c = 'formulaire_site_qts';
        import3.callSource__c = '';
        import3.source__c = 'PASSAGE MAGASIN';

        Import__c import4 = buildImport(4, true, true);
        import4.nomFichierSource__c = 'formulaire_site_affil';
        import4.callSource__c = '';
        import4.source__c = 'PASSAGE MAGASIN';
        import4.integrable__c = false;
        
        Import__c import5 = buildImport(5, false, true);
        import5.dateRDV__c = System.now();        
        import5.source__c = 'FOIRE';

        Import__c import6 = buildImport(6, false, true);
        import6.nomFichierSource__c = 'formulaire_site_qts';
        import6.callSource__c = '';
        import6.source__c = 'PASSAGE MAGASIN';

        List<Import__c> importItems = new List<Import__c>();
        importedItems.add(import1);
        importedItems.add(import1bis);        
        importedItems.add(import2);
        importedItems.add(import3);
        importedItems.add(import4);
        importedItems.add(import5);
        importedItems.add(import6);
        insert importedItems;

        import4.integrable__c = true;
        update import4;

        import6.integrable__c = true;
        update import6;

        importedItems = [SELECT dateIntegration__c, compte__c FROM Import__c WHERE id IN :importedItems];
        for (Import__c importedItem : importedItems) {
            //system.AssertNotEquals(null, importedItem.dateIntegration__c);
            //system.AssertNotEquals(null, importedItem.compte__c);
        }
    }

    private static Import__c buildImport(Integer i, Boolean locataire, Boolean recopieAdresse) {
        Import__c importedItem                        = new Import__c();

        importedItem.dateIntegration__c               = null;
        importedItem.integrable__c                    = true;

        importedItem.civiliteCompte__c                = 'M.';
        importedItem.prenomCompte__c                  = 'Prénom_' + i;
        importedItem.nomCompte__c                     = 'Nom_' + i;

        importedItem.rueCompte__c                     = i+ ' rue félix faure';
        importedItem.codePostalCompte__c              = '76320';
        importedItem.villeCompte__c                   = 'caudebec les elbeuf';
        importedItem.paysCompte__c                    = 'france';

        importedItem.telephoneDomicileCompte__c       = '0102030405';
        importedItem.telephoneMobileCompte__c         = '0602030405';
        importedItem.telephoneProfessionnelCompte__c  = '0102030407';
        importedItem.faxCompte__c                     = '0102030409';
        importedItem.emailCompte__c                   = 'prenom_' + i+ '.nom_' + i+ '@kpark.fr';

        importedItem.locataire__c                     = locataire;

        if (recopieAdresse) {
            importedItem.rueChantier__c                 = i+ ' rue félix faure';
            importedItem.codePostalChantier__c          = '76320';
            importedItem.villeChantier__c               = 'caudebec les elbeuf';
            importedItem.paysChantier__c                = 'france';
        }

        importedItem.materiauxFenetre__c              = 'PVC';
        importedItem.quantiteFenetre__c               = 2;

        return importedItem;
    }
}