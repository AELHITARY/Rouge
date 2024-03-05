//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Phototheque
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 05/11/2020
//-- Version     : 1.4
//-- * 1.4 : Modification en utilisant Family
//-- * 1.3 : Intégration de CRM Content et Jssor
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Phototheque{
    //Init
    public PricebookEntry codeproduit {get{ return codeproduit ;}set;}{codeproduit = new PricebookEntry();}
    public String famille{get; set;}
    public String sousfamille{get; set;}
    public String matiere{get; set;}
    public String sousmatiere{get; set;}

    public String codeproduitLibelle{get; set;}
    public String idLigneDevis{get; set;}

    public List<Product2> result {get; set;}
    public List<Product2> ListProduct2 {get; set;}

    // Fonction appelé lors l'ouverture de la page
    public void insertUserStats() {
        insertUserStatsFuture(Userinfo.getUserId());
    }

    // Incrémentation statistique utilisateur
    @future
    public static void insertUserStatsFuture(Id userId) {
        List<UserStats__c> userStats = new List<UserStats__c>();
        UserStats__c stats;
        List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurPhototheque__c
                                            FROM UserStats__c
                                            WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

        if (statsList.isEmpty()) {
            stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                    user__c                 = UserInfo.getUserId(),
                                    date__c                 = System.today(),
                                    compteurPhototheque__c  = 0);
        } else
            stats = statsList[0];

        System.debug('stats.compteurPhototheque__c : ' + stats.compteurPhototheque__c);
        stats.compteurPhototheque__c = stats.compteurPhototheque__c + 1;
        System.debug('stats.compteurPhototheque__c : ' + stats.compteurPhototheque__c);
        userStats.add(stats);

        if (!userStats.isEmpty())
            upsert userStats;
    }

    public Ctrl_Phototheque() {
        try{
            idLigneDevis = ApexPages.currentPage().getParameters().get('quotelineitem');
            codeproduitLibelle = ApexPages.currentPage().getParameters().get('codeproduit');
            if(idLigneDevis != null && idLigneDevis!=''){
                    QuoteLineItem qli = [SELECT Id,PricebookEntry.Product2Id FROM QuoteLineItem WHERE Id=:idLigneDevis];
                    codeproduitLibelle = qli.PricebookEntry.Product2Id;
            }

            if(codeproduitLibelle != null && codeproduitLibelle!=''){
                //on recupere le produit
                Product2 product = [SELECT Id, ProductCode, Family, SousFamille__c, Matiere__c, SousMatiere__c FROM Product2 WHERE Id = :codeproduitLibelle];
                this.codeproduit = new PriceBookEntry();
                this.codeproduit.Product2Id = codeproduitLibelle;
                this.famille = familles__c.getAll().get(product.Family).code__c;
                this.sousfamille = SousFamilles__c.getAll().get(product.SousFamille__c).code__c;
                this.matiere = Matieres__c.getAll().get(product.Matiere__c).code__c;
                this.sousmatiere =  SousMatieres__c.getAll().get(product.SousMatiere__c).code__c;
            }
        }
        catch(Exception e){
            ApexPages.addMessages(e);
        }
    }

    //Requête pour la recherche et le filtre des photos
    @RemoteAction
    public static List<Resultat> recuperephotos(String codeproduit, String famille, String sousfamille, String matiere, String sousmatiere){
        System.debug('### DEBUT Ctrl_Phototheque.recuperephotos');
		System.debug('## codeproduit: '+codeproduit);
		System.debug('## famille: '+famille);
		System.debug('## sousfamille: '+sousfamille);
		System.debug('## matiere: '+matiere);
		System.debug('## sousmatiere: '+sousmatiere);

        try{
            List<Product2> ListProduct2 = new List<Product2>();
            List<String> ListProduct2Id = new List<String>();
            List<String> productsId = new List<String>();
            List<ContentVersion> ReturnedCodes = new List<ContentVersion>();
            List<Resultat> ListId = new List<Resultat>();
            // Le nombre k permet de gérer la position des 'AND' dans la requête
            Integer k = 0;
            Integer l = 0;
            String soqlQuery ='SELECT Name, ProductCode, Family, SousFamille__c, Matiere__c, SousMatiere__c, ';
                    soqlQuery+=' (Select Id, ParentId, Title From CombinedAttachments)';
                    soqlQuery+=' FROM Product2';

            if ((codeproduit == '') && (famille == '') && (sousfamille == '') && (matiere == '') && (sousmatiere == '')){
            }else{
                    soqlQuery+=' WHERE';
                if(codeproduit != ''){
                    soqlQuery+=' ProductCode = ' + '\'' +  codeproduit + '\'';
                    k = 1;
                }
                if(String.isNotBlank(famille)){
                    String familleR = [SELECT libelle__c FROM familles__c WHERE code__c=:famille].libelle__c;
                    if(k == 1){
                        soqlQuery+=' AND';
                    }
                    soqlQuery+=' Family = ' + '\'' + String.escapeSingleQuotes(familleR) + '\'';
                    k = 1;
                }if(String.isNotBlank(sousfamille)){
                    String sousfamilleR = [SELECT libelle__c FROM SousFamilles__c WHERE code__c=:sousfamille].libelle__c;
                    if(k == 1){
                        soqlQuery+=' AND';
                    }
                    soqlQuery+=' SousFamille__c = ' + '\'' +  String.escapeSingleQuotes(sousfamilleR) + '\'';
                    k = 1;
                }if(String.isNotBlank(matiere)){
                    String matiereR = [SELECT libelle__c FROM Matieres__c WHERE code__c=:matiere].libelle__c;
                    if(k == 1){
                        soqlQuery+=' AND';
                    }
                    soqlQuery+=' Matiere__c = ' + '\'' +  String.escapeSingleQuotes(matiereR) + '\'';
                    k = 1;
                }if(String.isNotBlank(sousmatiere)){
                    String sousmatiereR = [SELECT libelle__c FROM SousMatieres__c WHERE code__c=:sousmatiere].libelle__c;
                    if(k == 1){
                        soqlQuery+=' AND';
                    }
                    soqlQuery+=' SousMatiere__c = ' + '\'' +  String.escapeSingleQuotes(sousmatiereR) + '\'';
                    k = 1;
                }
            }
			System.debug('## SOQL Query: '+soqlQuery);

            ListProduct2 = database.query(soqlQuery);
            System.debug(ListProduct2);

            for (Product2 ReturnedProducts : ListProduct2) {
                ListProduct2Id.add(ReturnedProducts.Id);
            }
            System.debug(ListProduct2Id);
            if(!ListProduct2Id.isEmpty()) {
				ReturnedCodes = [SELECT id, Title, Description, FileType, Owner.Name, produit__c, VersionNumber 
									FROM ContentVersion WHERE Origin= 'C' AND (FileType = 'JPG' OR FileType = 'PNG' OR FileType = 'TEXT') AND (produit__c IN :ListProduct2Id)];
            }
            System.debug(ReturnedCodes);
            for (ContentVersion ReturnedCodes2 : ReturnedCodes) {
                productsId.add(ReturnedCodes2.produit__c);
            }
            if(!productsId.isEmpty()) {
                ListProduct2 = [SELECT Name, Id, ProductCode, Family, SousFamille__c, Matiere__c, SousMatiere__c FROM Product2 WHERE Id IN :productsId];
            }
            System.debug(ListProduct2);

            for (Product2 ReturnedProductsCompare : ListProduct2) {
                for (ContentVersion ReturnedCodesCompare : ReturnedCodes) {
                    if(ReturnedCodesCompare.produit__c == ReturnedProductsCompare.Id){
                        Resultat res = new Resultat();
                        res.RRNumber = l;
                        res.RRName = ReturnedProductsCompare.Name;
                        res.RRCodeProduit = ReturnedProductsCompare.ProductCode;
                        res.RRMatiere = ReturnedProductsCompare.Matiere__c;
                        res.RRSousMatiere = ReturnedProductsCompare.SousMatiere__c;
                        res.RRFamille = ReturnedProductsCompare.Family;
                        res.RRSousFamille = ReturnedProductsCompare.SousFamille__c;
                        res.RRId = ReturnedCodesCompare.id;
                        res.RROwner = ReturnedCodesCompare.Owner.Name;
                        System.debug(res);
                        ListId.add(res);
                        l++;
                    }
                }
            }
			System.debug('### FIN Ctrl_Phototheque.recuperephotos');
			System.debug('## result: '+ListId);
            return ListId;
        }catch(exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

	//Récupération des informations du produit
	@RemoteAction
	public static Product2 recupereproduit(String codeproduit){
        System.debug('### DEBUT Ctrl_Phototheque.recupereproduit');
		System.debug('## codeproduit: '+codeproduit);

		try{
			List<Product2> productList = new List<Product2>();
			Product2 product = new Product2();

			productList = [SELECT ProductCode, Family, SousFamille__c, Matiere__c, SousMatiere__c FROM Product2 WHERE ProductCode = :codeproduit];
			if(!productList.isEmpty()) {
				product = productList.get(0);
				product.Family = familles__c.getAll().get(product.Family).code__c;
				product.SousFamille__c = SousFamilles__c.getAll().get(product.SousFamille__c).code__c;
				product.Matiere__c = Matieres__c.getAll().get(product.Matiere__c).code__c;
				product.SousMatiere__c =  SousMatieres__c.getAll().get(product.SousMatiere__c).code__c;
			}
			System.debug('### FIN Ctrl_Phototheque.recupereproduit');
			System.debug('## result: '+product);
			return product;
		} catch(exception e) {
			System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			throw e;
		}
	}

	public List<SelectOption> getFamillesSelectList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', ''));

		// Find all the countries in the custom setting
		Map<String, familles__c> familles = familles__c.getAll();

		// Sort them by name
		List<String> familleNames = new List<String>();
		familleNames.addAll(familles.keySet());
		familleNames.sort();

		// Create the Select Options.
		for (String familleName : familleNames) {
			familles__c famille = familles.get(familleName);
			options.add(new SelectOption(famille.code__c, famille.Name));
		}
		return options;
	}

	// To generate the sousfamilles picklist based on the familles selected by user.
	public List<SelectOption> getsousfamillesSelectList() {
		List<SelectOption> options = new List<SelectOption>();
		Integer k = 0;
		options.add(new SelectOption('', ''));

		List<String> ssFamilleNames;
		// Find all the sousfamille we have in custom settings.
		Map<String, SousFamilles__c> allssFamilles = SousFamilles__c.getAll();

		//if the familly is selected and not empty
		if(this.famille!=null && this.famille!=''){
			// Filter sousfamille that belong to the selected famille
			Map<String, SousFamilles__c> ssFamilles = new Map<String, SousFamilles__c>();
			for(SousFamilles__c sousfamille : allssFamilles.values()) {
				if (sousfamille.famille__c == this.famille) {
					ssFamilles.put(sousfamille.name, sousfamille);
				}
			}

			// Sort them by name
			ssFamilleNames = new List<String>();
			ssFamilleNames.addAll(ssFamilles.keySet());
			ssFamilleNames.sort();



			for (String ssFamilleName : ssFamilleNames) {
				SousFamilles__c sousfamille = ssFamilles.get(ssFamilleName);
				options.add(new SelectOption(sousfamille.code__c, sousfamille.Name));
				k++;
			}
			if(k == 1){
				options.remove(0);
			}
		} else{
			// Sort them by name
			ssFamilleNames = new List<String>();
			ssFamilleNames.addAll(allssFamilles.keySet());
			ssFamilleNames.sort();

			for (String ssFamilleName : ssFamilleNames) {
				SousFamilles__c sousfamille = allssFamilles.get(ssFamilleName);
				options.add(new SelectOption(sousfamille.code__c, sousfamille.Name));
			}
		}
		return options;
	}

	public List<SelectOption> getmatieresSelectList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', ''));

		// Find all the countries in the custom setting
		Map<String, Matieres__c> matieres = Matieres__c.getAll();

		// Sort them by name
		List<String> matiereNames = new List<String>();
		matiereNames.addAll(matieres.keySet());
		matiereNames.sort();

		// Create the Select Options.
		for (String matiereName : matiereNames) {
			Matieres__c matiere = matieres.get(matiereName);
			options.add(new SelectOption(matiere.code__c, matiere.Name));
		}
		return options;
	}

	// To generate the states picklist based on the country selected by user.
	public List<SelectOption> getsousmatieresSelectList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', ''));
		Integer k = 0;

		// Find all the sousfamille we have in custom settings.
		Map<String, SousMatieres__c> allssMatieres = SousMatieres__c.getAll();
		if(this.matiere!=null && this.matiere!=''){
			System.debug('matiere');
			// Filter sousfamille that belong to the selected famille
			Map<String, SousMatieres__c> ssMatieres = new Map<String, SousMatieres__c>();
			for(SousMatieres__c sousmatiere : allssMatieres.values()) {
				if (sousmatiere.matiere__c == this.matiere) {
					ssMatieres.put(sousmatiere.name, sousmatiere);
				}
			}

			// Sort them by name
			List<String> ssMatiereNames = new List<String>();
			ssMatiereNames.addAll(ssMatieres.keySet());
			ssMatiereNames.sort();

			for (String ssMatiereName : ssMatiereNames) {
				SousMatieres__c sousmatiere = ssMatieres.get(ssMatiereName);
				options.add(new SelectOption(sousmatiere.code__c, sousmatiere.Name));
				k++;
			}
			if(k == 1){
				options.remove(0);
			}
		} else{
			List<String> ssMatiereNames = new List<String>();
			ssMatiereNames.addAll(allssMatieres.keySet());
			ssMatiereNames.sort();
			System.debug('pasmatiere');

			for (String ssMatiereName : ssMatiereNames) {
				SousMatieres__c sousmatiere = allssMatieres.get(ssMatiereName);
				options.add(new SelectOption(sousmatiere.code__c, sousmatiere.Name));
			}
		}
		return options;
	}

	public class Resultat {
		public String RRName {get;set;}
		public String RRCodeProduit {get;set;}
		public String RRMatiere { get; set;}
		public String RRSousMatiere {get; set;}
		public String RRFamille {get; set;}
		public String RRSousFamille {get; set;}
		public String RRId {get; set;}
		public String RROwner {get; set;}
		public Integer RRNumber {get; set;}

		public Resultat () {
		}
	}

	public PageReference newSearch(){
		Pagereference VF_recherche = Page.VF_RechercheProduit;
		return VF_recherche;
	}
}