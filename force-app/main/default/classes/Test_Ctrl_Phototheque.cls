//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Phototheque
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2020
//-- Version     : 1.2
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Phototheque {

    @testSetup 
    static void setup() {
        // Initialisation et insertion des paramètres personnalisés
        Matieres__c Bois = new Matieres__c(name = 'Bois', code__c = 'BO', libelle__c = 'Bois');
        insert(Bois);
        SousMatieres__c BOISISOLANTE = new SousMatieres__c(name = 'BOIS ISOLANTE', code__c = 'BO_ISO', matiere__c = 'BO', libelle__c = 'BOIS ISOLANTE');
        insert(BOISISOLANTE);
        familles__c Porte = new familles__c(name = 'Porte', code__c = 'POR', libelle__c = 'Porte');
        insert(Porte);
        SousFamilles__c PortedEntree = new SousFamilles__c(name = 'Porte d\'Entree', code__c = 'PENT', famille__c = 'POR', libelle__c = 'Porte d\'Entree');
        insert(PortedEntree);

        // Initialisation et insertion d'un produit de test
        Product2 pr = new Product2(Productcode = 'HAMBOURG',  Reference__c= 'HAMBOURG', sousfamille__c = 'Porte d\'Entree',
                          matiere__c = 'Bois', sousmatiere__c = 'BOIS ISOLANTE', name = 'HAMBOURG', isActive = true,
                          Family='Porte');
        insert(pr);

        ContentVersion doc = new ContentVersion();
        string phototest = 'Testing base 64 encode';
        Blob beforeblob = Blob.valueOf(phototest);
        doc.Title = 'porte-d-entree';
        doc.PathOnClient = 'xyz';
        doc.VersionData = beforeblob;
        doc.produit__c  = pr.Id;
        insert doc;
    }

    @isTest
    static void test() {
        Product2 prd = [SELECT Id FROM Product2 LIMIT 1];

         // Initialisation de la VF
         PageReference pa = Page.VF_Phototheque;
         Test.setCurrentPage(pa);
         pa.getParameters ().put ('codeproduit' , prd.Id);

         // Initialisation du controlleur
         Ctrl_Phototheque ctrl = new Ctrl_Phototheque();
         ctrl.famille = 'POR';
         ctrl.sousfamille = '';
         ctrl.matiere = 'BO';
         ctrl.sousmatiere = '';
         ctrl.codeproduitLibelle = 'HAMBOURG';
         ctrl.idLigneDevis = '';

         // Récupération des champs automatique (lorsque 'matiere' et 'famille' sont vides)
         ctrl.insertUserStats();
         ctrl.getFamillesSelectList();
         ctrl.getsousfamillesSelectList();
         ctrl.getmatieresSelectList();
         ctrl.getsousmatieresSelectList();
         ctrl.newSearch();
    }

    @isTest
    static void testRemote() {

         // Initialisation de la VF
         PageReference pa = Page.VF_Phototheque;
         Test.setCurrentPage(pa);
         pa.getParameters ().put ('codeproduit' , 'HAMBOURG');

         // Initialisation du controlleur
         Ctrl_Phototheque ctrl = new Ctrl_Phototheque();
         ctrl.famille = '';
         ctrl.sousfamille = '';
         ctrl.matiere = '';
         ctrl.sousmatiere = '';
         ctrl.codeproduitLibelle = 'HAMBOURG';
         ctrl.idLigneDevis = '';
   
         // Récupération des photos dans 5 cas différents
         Ctrl_Phototheque.recuperephotos('','','','BO','');
         Ctrl_Phototheque.recuperephotos('HAMBOURG','POR','','','');
         Ctrl_Phototheque.recuperephotos('','','','','');
         Ctrl_Phototheque.recuperephotos('HAMBOURG','','PENT','','');
         Ctrl_Phototheque.recuperephotos('HAMBOURG','POR','PENT','BO','BO_ISO');

         // Récupération des données d'un produit spécifique
         Ctrl_Phototheque.recupereproduit('HAMBOURG');
    }
}