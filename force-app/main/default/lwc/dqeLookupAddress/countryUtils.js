const PAYS_NAME_MAP = {'AFGHANISTAN' : 'AFG',
        'AFRIQUE DU SUD' : 'ZAF',
        'ALBANIE' : 'ALB',
        'ALGÉRIE' : 'DZA',
        'ALLEMAGNE' : 'DEU',
        'ANDORRE' : 'AND',
        'ANGOLA' : 'AGO',
        'ANGUILLA' : 'AIA',
        'ANTIGUA-ET-BARBUDA' : 'ATG',
        'ARGENTINE' : 'ARG',
        'ARMÉNIE' : 'ARM',
        'ARUBA' : 'ABW',
        'AUSTRALIE' : 'AUS',
        'AUTRICHE' : 'AUT',
        'AZERBAÏDJAN' : 'AZE',
        'BAHAMAS' : 'BHS',
        'BAHREÏN' : 'BHR',
        'BANGLADESH' : 'BGD',
        'BARBADE' : 'BRB',
        'BIÉLORUSSIE' : 'BLR',
        'BELGIQUE' : 'BEL',
        'BELIZE' : 'BLZ',
        'BÉNIN' : 'BEN',
        'BERMUDES' : 'BMU',
        'BHOUTAN' : 'BTN',
        'BOLIVIE' : 'BOL',
        'BOSNIE-HERZÉGOVINE' : 'BIH',
        'BOTSWANA' : 'BWA',
        'BRÉSIL' : 'BRA',
        'BRUNEI' : 'BRN',
        'BULGARIE' : 'BGR',
        'BURKINA FASO' : 'BFA',
        'BURUNDI' : 'BDI',
        'ÎLES CAÏMANS' : 'CYM',
        'CAMBODGE' : 'KHM',
        'CAMEROUN' : 'CMR',
        'CANADA' : 'CAN',
        'CAP-VERT' : 'CPV',
        'RÉPUBLIQUE CENTRAFRICAINE' : 'CAF',
        'CHILI' : 'CHL',
        'CHINE' : 'CHN',
        'CHYPRE' : 'CYP',
        'COLOMBIE' : 'COL',
        'COMORES' : 'COM',
        'RÉPUBLIQUE DU CONGO' : 'COG',
        'RÉPUBLIQUE DÉMOCRATIQUE DU CONGO' : 'COD',
        'CORÉE DU SUD' : 'KOR',
        'CORÉE DU NORD' : 'PRK',
        'COSTA RICA' : 'CRI',
        'CÔTE D\'IVOIRE' : 'CIV',
        'CROATIE' : 'HRV',
        'CUBA' : 'CUB',
        'CURAÇAO' : 'CUW',
        'DANEMARK' : 'DNK',
        'DJIBOUTI' : 'DJI',
        'RÉPUBLIQUE DOMINICAINE' : 'DOM',
        'DOMINIQUE' : 'DMA',
        'ÉGYPTE' : 'EGY',
        'SALVADOR' : 'SLV',
        'ÉMIRATS ARABES UNIS' : 'ARE',
        'ÉQUATEUR' : 'ECU',
        'ÉRYTHRÉE' : 'ERI',
        'ESPAGNE' : 'ESP',
        'ESTONIE' : 'EST',
        'ÉTATS-UNIS' : 'USA',
        'ÉTHIOPIE' : 'ETH',
        'ÎLES MALOUINES' : 'FLK',
        'ÎLES FÉROÉ' : 'FRO',
        'FIDJI' : 'FJI',
        'FINLANDE' : 'FIN',
        'FRANCE' : 'FRA',
        'GABON' : 'GAB',
        'GAMBIE' : 'GMB',
        'GÉORGIE' : 'GEO',
        'GHANA' : 'GHA',
        'GRÈCE' : 'GRC',
        'GRENADE' : 'GRD',
        'GUATEMALA' : 'GTM',
        'GUINÉE' : 'GIN',
        'GUINÉE-BISSAU' : 'GNB',
        'GUYANA' : 'GUY',
        'GUYANE' : 'GUF',
        'HAÏTI' : 'HTI',
        'HONDURAS' : 'HND',
        'HONG KONG' : 'HKG',
        'HONGRIE' : 'HUN',
        'INDE' : 'IND',
        'INDONÉSIE' : 'IDN',
        'IRAN' : 'IRN',
        'IRAK' : 'IRQ',
        'IRLANDE' : 'IRL',
        'ISLANDE' : 'ISL',
        'ISRAËL' : 'ISR',
        'ITALIE' : 'ITA',
        'JAMAÏQUE' : 'JAM',
        'JAPON' : 'JPN',
        'JORDANIE' : 'JOR',
        'KAZAKHSTAN' : 'KAZ',
        'KENYA' : 'KEN',
        'KIRIBATI' : 'KIR',
        'KOWEÏT' : 'KWT',
        'LAOS' : 'LAO',
        'LESOTHO' : 'LSO',
        'LETTONIE' : 'LVA',
        'LIBAN' : 'LBN',
        'LIBÉRIA' : 'LBR',
        'LIBYE' : 'LBY',
        'LIECHTENSTEIN' : 'LIE',
        'LITUANIE' : 'LTU',
        'LUXEMBOURG' : 'LUX',
        'MACÉDOINE' : 'MKD',
        'MADAGASCAR' : 'MDG',
        'MALAISIE' : 'MYS',
        'MALAWI' : 'MWI',
        'MALDIVES' : 'MDV',
        'MALI' : 'MLI',
        'MALTE' : 'MLT',
        'MAROC' : 'MAR',
        'MAURICE' : 'MUS',
        'MAURITANIE' : 'MRT',
        'MEXIQUE' : 'MEX',
        'MOLDAVIE' : 'MDA',
        'MONACO' : 'MCO',
        'MONGOLIE' : 'MNG',
        'MONTÉNÉGRO' : 'MNE',
        'MOZAMBIQUE' : 'MOZ',
        'BIRMANIE' : 'MMR',
        'NAMIBIE' : 'NAM',
        'NAURU' : 'NRU',
        'NÉPAL' : 'NPL',
        'NICARAGUA' : 'NIC',
        'NIGER' : 'NER',
        'NIGERIA' : 'NGA',
        'NORVÈGE' : 'NOR',
        'NOUVELLE-CALÉDONIE' : 'NCL',
        'NOUVELLE-ZÉLANDE' : 'NZL',
        'OMAN' : 'OMN',
        'OUZBÉKISTAN' : 'UZB',
        'PAKISTAN' : 'PAK',
        'PANAMA' : 'PAN',
        'PAPOUASIE-NOUVELLE-GUINÉE' : 'PNG',
        'PARAGUAY' : 'PRY',
        'PAYS-BAS' : 'NLD',
        'PÉROU' : 'PER',
        'PHILIPPINES' : 'PHL',
        'POLOGNE' : 'POL',
        'PORTUGAL' : 'PRT',
        'QATAR' : 'QAT',
        'ROUMANIE' : 'ROU',
        'ROYAUME-UNI' : 'GBR',
        'RUSSIE' : 'RUS',
        'RWANDA' : 'RWA',
        'SAINT-CHRISTOPHE-ET-NIÉVÈS' : 'KNA',
        'SAINT-MARIN' : 'SMR',
        'SAINT-PIERRE-ET-MIQUELON' : 'SPM',
        'VATICAN' : 'VAT',
        'SAINT-VINCENT-ET-LES-GRENADINES' : 'VCT',
        'SAINTE-LUCIE' : 'LCA',
        'SALOMON' : 'SLB',
        'SAMOA' : 'WSM',
        'SAO TOMÉ-ET-PRINCIPE' : 'STP',
        'SÉNÉGAL' : 'SEN',
        'SERBIE' : 'SRB',
        'SEYCHELLES' : 'SYC',
        'SIERRA LEONE' : 'SLE',
        'SINGAPOUR' : 'SGP',
        'SLOVAQUIE' : 'SVK',
        'SLOVÉNIE' : 'SVN',
        'SOMALIE' : 'SOM',
        'SOUDAN' : 'SDN',
        'SRI LANKA' : 'LKA',
        'SUÈDE' : 'SWE',
        'SUISSE' : 'CHE',
        'SURINAME' : 'SUR',
        'SWAZILAND' : 'SWZ',
        'SYRIE' : 'SYR',
        'TADJIKISTAN' : 'TJK',
        'TANZANIE' : 'TZA',
        'RÉPUBLIQUE TCHÈQUE' : 'CZE',
        'THAÏLANDE' : 'THA',
        'TIMOR ORIENTAL' : 'TLS',
        'TOGO' : 'TGO',
        'TONGA' : 'TON',
        'TRINITÉ-ET-TOBAGO' : 'TTO',
        'TUNISIE' : 'TUN',
        'TURKMÉNISTAN' : 'TKM',
        'TURQUIE' : 'TUR',
        'TUVALU' : 'TUV',
        'UKRAINE' : 'UKR',
        'URUGUAY' : 'URY',
        'VANUATU' : 'VUT',
        'VENEZUELA' : 'VEN',
        'VIÊT NAM' : 'VNM',
        'WALLIS-ET-FUTUNA' : 'WLF',
        'YÉMEN' : 'YEM',
        'ZAMBIE' : 'ZMB',
        'ZIMBABWE' : 'ZWE'};

const PAYS_CODE_MAP =
        {'AFG' : 'AFGHANISTAN',
        'ZAF' : 'AFRIQUE DU SUD',
        'ALB' : 'ALBANIE',
        'DZA' : 'ALGÉRIE',
        'DEU' : 'ALLEMAGNE',
        'AND' : 'ANDORRE',
        'AGO' : 'ANGOLA',
        'AIA' : 'ANGUILLA',
        'ATG' : 'ANTIGUA-ET-BARBUDA',
        'ARG' : 'ARGENTINE',
        'ARM' : 'ARMÉNIE',
        'ABW' : 'ARUBA',
        'AUS' : 'AUSTRALIE',
        'AUT' : 'AUTRICHE',
        'AZE' : 'AZERBAÏDJAN',
        'BHS' : 'BAHAMAS',
        'BHR' : 'BAHREÏN',
        'BGD' : 'BANGLADESH',
        'BRB' : 'BARBADE',
        'BLR' : 'BIÉLORUSSIE',
        'BEL' : 'BELGIQUE',
        'BLZ' : 'BELIZE',
        'BEN' : 'BÉNIN',
        'BMU' : 'BERMUDES',
        'BTN' : 'BHOUTAN',
        'BOL' : 'BOLIVIE',
        'BIH' : 'BOSNIE-HERZÉGOVINE',
        'BWA' : 'BOTSWANA',
        'BRA' : 'BRÉSIL',
        'BRN' : 'BRUNEI',
        'BGR' : 'BULGARIE',
        'BFA' : 'BURKINA FASO',
        'BDI' : 'BURUNDI',
        'CYM' : 'ÎLES CAÏMANS',
        'KHM' : 'CAMBODGE',
        'CMR' : 'CAMEROUN',
        'CAN' : 'CANADA',
        'CPV' : 'CAP-VERT',
        'CAF' : 'RÉPUBLIQUE CENTRAFRICAINE',
        'CHL' : 'CHILI',
        'CHN' : 'CHINE',
        'CYP' : 'CHYPRE',
        'COL' : 'COLOMBIE',
        'COM' : 'COMORES',
        'COG' : 'RÉPUBLIQUE DU CONGO',
        'COD' : 'RÉPUBLIQUE DÉMOCRATIQUE DU CONGO',
        'KOR' : 'CORÉE DU SUD',
        'PRK' : 'CORÉE DU NORD',
        'CRI' : 'COSTA RICA',
        'CIV' : 'CÔTE D\'IVOIRE',
        'HRV' : 'CROATIE',
        'CUB' : 'CUBA',
        'CUW' : 'CURAÇAO',
        'DNK' : 'DANEMARK',
        'DJI' : 'DJIBOUTI',
        'DOM' : 'RÉPUBLIQUE DOMINICAINE',
        'DMA' : 'DOMINIQUE',
        'EGY' : 'ÉGYPTE',
        'SLV' : 'SALVADOR',
        'ARE' : 'ÉMIRATS ARABES UNIS',
        'ECU' : 'ÉQUATEUR',
        'ERI' : 'ÉRYTHRÉE',
        'ESP' : 'ESPAGNE',
        'EST' : 'ESTONIE',
        'USA' : 'ÉTATS-UNIS',
        'ETH' : 'ÉTHIOPIE',
        'FLK' : 'ÎLES MALOUINES',
        'FRO' : 'ÎLES FÉROÉ',
        'FJI' : 'FIDJI',
        'FIN' : 'FINLANDE',
        'FRA' : 'FRANCE',
        'GAB' : 'GABON',
        'GMB' : 'GAMBIE',
        'GEO' : 'GÉORGIE',
        'GHA' : 'GHANA',
        'GRC' : 'GRÈCE',
        'GRD' : 'GRENADE',
        'GTM' : 'GUATEMALA',
        'GIN' : 'GUINÉE',
        'GNB' : 'GUINÉE-BISSAU',
        'GUY' : 'GUYANA',
        'GUF' : 'GUYANE',
        'HTI' : 'HAÏTI',
        'HND' : 'HONDURAS',
        'HKG' : 'HONG KONG',
        'HUN' : 'HONGRIE',
        'IND' : 'INDE',
        'IDN' : 'INDONÉSIE',
        'IRN' : 'IRAN',
        'IRQ' : 'IRAK',
        'IRL' : 'IRLANDE',
        'ISL' : 'ISLANDE',
        'ISR' : 'ISRAËL',
        'ITA' : 'ITALIE',
        'JAM' : 'JAMAÏQUE',
        'JPN' : 'JAPON',
        'JOR' : 'JORDANIE',
        'KAZ' : 'KAZAKHSTAN',
        'KEN' : 'KENYA',
        'KIR' : 'KIRIBATI',
        'KWT' : 'KOWEÏT',
        'LAO' : 'LAOS',
        'LSO' : 'LESOTHO',
        'LVA' : 'LETTONIE',
        'LBN' : 'LIBAN',
        'LBR' : 'LIBÉRIA',
        'LBY' : 'LIBYE',
        'LIE' : 'LIECHTENSTEIN',
        'LTU' : 'LITUANIE',
        'LUX' : 'LUXEMBOURG',
        'MKD' : 'MACÉDOINE',
        'MDG' : 'MADAGASCAR',
        'MYS' : 'MALAISIE',
        'MWI' : 'MALAWI',
        'MDV' : 'MALDIVES',
        'MLI' : 'MALI',
        'MLT' : 'MALTE',
        'MAR' : 'MAROC',
        'MUS' : 'MAURICE',
        'MRT' : 'MAURITANIE',
        'MEX' : 'MEXIQUE',
        'MDA' : 'MOLDAVIE',
        'MCO' : 'MONACO',
        'MNG' : 'MONGOLIE',
        'MNE' : 'MONTÉNÉGRO',
        'MOZ' : 'MOZAMBIQUE',
        'MMR' : 'BIRMANIE',
        'NAM' : 'NAMIBIE',
        'NRU' : 'NAURU',
        'NPL' : 'NÉPAL',
        'NIC' : 'NICARAGUA',
        'NER' : 'NIGER',
        'NGA' : 'NIGERIA',
        'NOR' : 'NORVÈGE',
        'NCL' : 'NOUVELLE-CALÉDONIE',
        'NZL' : 'NOUVELLE-ZÉLANDE',
        'OMN' : 'OMAN',
        'UZB' : 'OUZBÉKISTAN',
        'PAK' : 'PAKISTAN',
        'PAN' : 'PANAMA',
        'PNG' : 'PAPOUASIE-NOUVELLE-GUINÉE',
        'PRY' : 'PARAGUAY',
        'NLD' : 'PAYS-BAS',
        'PER' : 'PÉROU',
        'PHL' : 'PHILIPPINES',
        'POL' : 'POLOGNE',
        'PRT' : 'PORTUGAL',
        'QAT' : 'QATAR',
        'ROU' : 'ROUMANIE',
        'GBR' : 'ROYAUME-UNI',
        'RUS' : 'RUSSIE',
        'RWA' : 'RWANDA',
        'KNA' : 'SAINT-CHRISTOPHE-ET-NIÉVÈS',
        'SMR' : 'SAINT-MARIN',
        'SPM' : 'SAINT-PIERRE-ET-MIQUELON',
        'VAT' : 'VATICAN',
        'VCT' : 'SAINT-VINCENT-ET-LES-GRENADINES',
        'LCA' : 'SAINTE-LUCIE',
        'SLB' : 'SALOMON',
        'WSM' : 'SAMOA',
        'STP' : 'SAO TOMÉ-ET-PRINCIPE',
        'SEN' : 'SÉNÉGAL',
        'SRB' : 'SERBIE',
        'SYC' : 'SEYCHELLES',
        'SLE' : 'SIERRA LEONE',
        'SGP' : 'SINGAPOUR',
        'SVK' : 'SLOVAQUIE',
        'SVN' : 'SLOVÉNIE',
        'SOM' : 'SOMALIE',
        'SDN' : 'SOUDAN',
        'LKA' : 'SRI LANKA',
        'SWE' : 'SUÈDE',
        'CHE' : 'SUISSE',
        'SUR' : 'SURINAME',
        'SWZ' : 'SWAZILAND',
        'SYR' : 'SYRIE',
        'TJK' : 'TADJIKISTAN',
        'TZA' : 'TANZANIE',
        'CZE' : 'RÉPUBLIQUE TCHÈQUE',
        'THA' : 'THAÏLANDE',
        'TLS' : 'TIMOR ORIENTAL',
        'TGO' : 'TOGO',
        'TON' : 'TONGA',
        'TTO' : 'TRINITÉ-ET-TOBAGO',
        'TUN' : 'TUNISIE',
        'TKM' : 'TURKMÉNISTAN',
        'TUR' : 'TURQUIE',
        'TUV' : 'TUVALU',
        'UKR' : 'UKRAINE',
        'URY' : 'URUGUAY',
        'VUT' : 'VANUATU',
        'VEN' : 'VENEZUELA',
        'VNM' : 'VIÊT NAM',
        'WLF' : 'WALLIS-ET-FUTUNA',
        'YEM' : 'YÉMEN',
        'ZMB' : 'ZAMBIE',
        'ZWE' : 'ZIMBABWE'};

export { PAYS_NAME_MAP, PAYS_CODE_MAP };