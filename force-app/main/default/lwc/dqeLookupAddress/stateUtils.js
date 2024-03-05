const STATE_NAME = [
    'Ain', 'Aisne', 'Allier', 'Alpes de Hautes-Provence', 'Hautes-Alpes', 'Alpes-Maritimes', 'Ardèche',
    'Ardennes', 'Ariège', 'Aube', 'Aude', 'Aveyron', 'Bouches-du-Rhône', 'Calvados', 'Cantal', 'Charente',
    'Charente-Maritime', 'Cher', 'Corrèze', "Corse", 'Côte-d\'Or', 'Côtes-d\'Armor', 'Creuse', 'Dordogne',
    'Doubs', 'Drôme', 'Eure', 'Eure-et-Loir', 'Finistère', 'Gard', 'Haute-Garonne', 'Gers', 'Gironde',
    'Hérault', 'Ille-et-Vilaine', 'Indre', 'Indre-et-Loire', 'Isère', 'Jura', 'Landes', 'Loir-et-Cher',
    'Loire', 'Haute-Loire', 'Loire-Atlantique', 'Loiret', 'Lot', 'Lot-et-Garonne', 'Lozère', 'Maine-et-Loire',
    'Manche', 'Marne', 'Haute-Marne', 'Mayenne', 'Meurthe-et-Moselle', 'Meuse', 'Morbihan', 'Moselle',
    'Nièvre', 'Nord', 'Oise', 'Orne', 'Pas-de-Calais', 'Puy-de-Dôme', 'Pyrénées-Atlantiques', 'Hautes-Pyrénées',
    'Pyrénées-Orientales', 'Bas-Rhin', 'Haut-Rhin', 'Rhône', 'Haute-Saône', 'Saône-et-Loire', 'Sarthe',
    'Savoie', 'Haute-Savoie', 'Paris', 'Seine-Maritime', 'Seine-et-Marne', 'Yvelines', 'Deux-Sèvres',
    'Somme', 'Tarn', 'Tarn-et-Garonne', 'Var', 'Vaucluse', 'Vendée', 'Vienne', 'Haute-Vienne', 'Vosges',
    'Yonne', 'Territoire de Belfort', 'Essonne', 'Hauts-de-Seine', 'Seine-Saint-Denis', 'Val-de-Marne', 'Val-d\'Oise'
];
const DOMTOM = {'971': 'Guadeloupe', '972': 'Martinique', '973': 'Guyane', '974': 'La Réunion', '975': 'St Pierre et Miquelon', '976': 'Mayotte', 
                '977': 'Saint-Barthélemy', '978': 'Saint-Martin', '984': 'Terres Australes et Antarctiques', '986': 'Wallis et Futuna', 
                '987': 'Polynésie Française', '988': 'Nouvelle Calédonie', '989': 'Clipperton'};
const REGION_NAME = [
	'Auvergne-Rhône-Alpes', 
	'Bourgogne-Franche-Comté', 
	'Bretagne', 
	'Centre-Val de Loire', 
	'Corse', 
	'Grand Est', 
	'Hauts-de-France',
	'Île-de-France', 
	'Normandie', 
	'Nouvelle-Aquitaine', 
	'Occitanie',
	'Pays de la Loire',
	'Provence-Alpes-Côte d\'Azur'
];  
const REGION = [0, 6, 0, 12, 12, 12, 0, 4, 10, 4, 10, 10, 12, 7, 0, 8, 8, 2, 
                8, 3, 0, 1, 8, 8, 0, 0, 7, 2, 1, 10, 10, 10, 8, 10, 1, 2, 2, 
                0, 0, 8, 2, 0, 0, 11, 2, 10, 8, 10, 11, 7, 4, 4, 11, 4, 4, 1, 
                4, 0, 6, 6, 7, 6, 0, 8, 10, 10, 4, 4, 0, 0, 0, 11, 0, 0, 7, 
                7, 7, 7, 8, 6, 10, 10, 12, 12, 11, 8, 8, 4, 0, 0, 7, 7, 7, 7, 7];

export { STATE_NAME, DOMTOM, REGION_NAME, REGION };