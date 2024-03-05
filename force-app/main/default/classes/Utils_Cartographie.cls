//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Cartographie
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/07/2022
//-- Version     : 1.6
//-- * 1.6 - Prise en charge des commandes (Kube3)
//-- * 1.5 - Modification de la classe helper pour ajout de la fonction getAttachmentByMag
//-- --------------------------------------------------------------------------------- --
public with sharing class Utils_Cartographie {

    /**
    * @description Fonction de géocodage d'une adresse à partir du WebService Google Maps
    * Documentation : https://developers.google.com/maps/
    * @param rue Rue complète (avec numéro de rue)
    * @param codePostal Code postal
    * @param ville Ville
    * @return GoogleMapsJSONLatLng Résultat du géocodage de Google
    */
    public static GoogleMapsJSONLatLng getGeoGoogleMaps(String rue, String codePostal, String ville) {
        GoogleMapsJSONComponents latlong = null;
        latlong=getGeoGoogleMaps(rue,codePostal,ville,true);
        if(latlong!=null) 
            return latlong.geometry.location;
        return null;
    }

    /**
    * @description Fonction de géocodage d'une adresse à partir du WebService Google Maps
    * Documentation : https://developers.google.com/maps/
    * @param rue Rue complète (avec numéro de rue)
    * @param codePostal Code postal
    * @param ville Ville
    * @param checkWhitoutRue Si aucune adresse, on vérifie sans la rue
    * @return GoogleMapsJSONComponents Résultat du géocodage de Google
    */
    public static GoogleMapsJSONComponents getGeoGoogleMaps(String rue, String codePostal, String ville, Boolean checkWhitoutRue) {
        system.debug('### DEBUT getGeoGoogleMaps');
        system.debug('## Rue : ' + rue);
        system.debug('## Ville : ' + ville);
        system.debug('## Code postal : ' + codePostal);

        // Vérification des paramètres
        // if (Utils.IsNullOrEmpty(rue) || Utils.IsNullOrEmpty(codePostal) || Utils.IsNullOrEmpty(ville)) {
        if (Utils.IsNullOrEmpty(codePostal) || Utils.IsNullOrEmpty(ville)) {
            system.debug('## ERREUR : Adresse invalide');
            return null;
        }

        String googleAPIKey = PropertiesUtils.getStringValue('google.api.key', '');
        String googleAPIUrl = PropertiesUtils.getStringValue('google.api.url', 'https://maps.googleapis.com');
        GoogleMapsJSONComponents latlong = null;

        // Contruction et appel au webservice REST Google Maps
        // URL du WebService : https://maps.googleapis.com/maps/api/geocode/output?parameters
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        req.setMethod('GET');
        // Génération URL
        String adresseCP = (EncodingUtil.urlEncode(codePostal,'UTF-8').length() == 5) ? EncodingUtil.urlEncode(codePostal,'UTF-8') : '';
        String adresseVilleCP = EncodingUtil.urlEncode(ville,'UTF-8')+',+' + adresseCP;
        String adresse = EncodingUtil.urlEncode(rue,'UTF-8') +',+' + adresseVilleCP;
        String url = googleAPIUrl + '/maps/api/geocode/json?components=postal_code:'+adresseCP+'|locality:'+EncodingUtil.urlEncode(ville,'UTF-8')+'&address=' + EncodingUtil.urlEncode(rue,'UTF-8') +'&region=fr&key=' + googleAPIKey;
        String body;
        HTTPResponse resp;
        // Ajout du Endpoint
        req.setEndpoint(url);
        system.debug('## URL : ' + req.getEndpoint());
        // Récupération de la réponse
        if (!Test.isRunningTest()) {
            resp = http.send(req);
            system.debug('## Reponse HTTP REST : ' + resp);
            body = resp.getBody();
        } else {
            body = '{"status": "ZERO_RESULTS"}';
        }
            
        GoogleMapsJSONResponse gr = (GoogleMapsJSONResponse) JSON.deserialize(body, GoogleMapsJSONResponse.class);
        system.debug('## Google Maps Response : ' + gr);
        if(gr.status == 'ZERO_RESULTS'){
            if(checkWhitoutRue) {
                // Si pas d'adresse trouvée, on tente sans la rue
                url = googleAPIUrl + '/maps/api/geocode/json?address=' + adresseVilleCP +'&region=fr&key=' + googleAPIKey;
                req.setEndpoint(url);
                if (!Test.isRunningTest()) {
                    resp = http.send(req);
                    system.debug('## Reponse HTTP REST : ' + resp);
                    body = resp.getBody();
                } else {
                    body = '{"status": "ZERO_RESULTS"}';
                }
                gr = (GoogleMapsJSONResponse) JSON.deserialize(body, GoogleMapsJSONResponse.class);
                if(gr.status == 'OK'){
                    // Si adresse trouvée, on enregistre les coordonées
                    latlong = gr.results[0];
                } 
            }
        } else if(gr.status == 'OK'){
            // Si adresse trouvée, on enregistre les coordonées
            latlong = gr.results[0];
        }
        system.debug('### FIN getGeoGoogleMaps');
        return latlong;
    }

    /**
    *
    *   Classe d'aide pour parse du JSON de l'API REST de Google Maps - Template pour récupérer certains champs
    *   Vérifier : https://developers.google.com/maps/documentation/geocoding/#Results pour un mapping complet.
    *
    **/
    public class GoogleMapsJSONResponse{
        public String status;
        public List<GoogleMapsJSONComponents> results;
    }
    public class GoogleMapsJSONComponents{
        public String formatted_address;
        public GoogleMapsJSONGeometry geometry;
        public Boolean partial_match;
    }
    public class GoogleMapsJSONGeometry {
        public GoogleMapsJSONLatLng location;
        public String location_type;
    }
    public class GoogleMapsJSONLatLng{
        public Double lat, lng;
    }
    
    /**
    * @description Récupération des coordonées en X et Y du secteur (magasin)
    * @param sectorName Nom du secteur (magasin)
    * @return Sector Objet contenant le nom, code magasin et les points cartographique (WGS84) du secteur
    */
    public static Sector getSectorCoord(string sectorName) {
        try {
            Sector retSector = null;
            Attachment att = null;
            if(String.isNotBlank(sectorName)){
                Sectorisation__c ve = DAL_Cartographie.getSectorByName(sectorName);
                if(ve != null)
                    att = DAL_Cartographie.getAttachmentByMag(ve.codeMagasin__c);
                if(ve.codeMagasin__c != null)
                    retSector = new Sector(ve, att);
            }
            return retSector;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    *
    *   Classe de calcul pour convertir les données Lambert2 en WGS84
    *
    **/
    public class LatLongCoord {
        public Double Latitude   { get; set; }
        public Double Longitude { get; set; }
        public Double X  { get; set; }
        public Double Y  { get; set; }
        private Double Z;
        private final Double R2D = 57.29577951308232088;
        private final Double D2R = 0.01745329251994329577;

        private final Double PI = 3.141592653589793238;
        private final Double TWO_PI = 6.283185307179586477;
        private final Double HALF_PI = 1.570796326794896619;

        private final Double SOURCE_FROM_GREENWICH = 0.04079234433198245;
        private final Double SOURCE_A = 6378249.2;
        private final Double SOURCE_B = 6356515;
        private final Double SOURCE_K0 = 0.99987742;
        private final Double SOURCE_X0 = 600000;
        private final Double SOURCE_Y0 = 2200000;
        private final Double SOURCE_LAT0 = 0.8168140899333461;
        private final Double SOURCE_LAT1 = 0.8168140899333461;
        private Double source_a2;
        private Double source_b2;
        private Double source_es;
        private Double source_e;
        private Double source_ep2;
        private Double source_ns;
        private Double source_rh;
        private Double source_f0;

        private final Double DEST_A = 6378137;
        private final Double DEST_B = 6356752.314245179;
        private Double dest_a2;
        private Double dest_b2;
        private Double dest_es;
        private Double dest_e;
        private Double dest_ep2;

        public LatLongCoord () { this.X = 0; this.Y = 0; this.Z = 0; }
        public LatLongCoord (Double x, Double y) {
            this.X = x;
            this.Y = y;
            this.Z = 0;
            initialize_source(); // Lambert
            initialize_destination(); // WGS84
        }

        public void initialize_source() {
            source_a2 = SOURCE_A * SOURCE_A;          // used in geocentric
            source_b2 = SOURCE_B * SOURCE_B;          // used in geocentric
            source_es = (source_a2-source_b2)/source_a2;  // e ^ 2
            source_ep2 = (source_a2-source_b2)/source_b2; // used in geocentric

            //if (!this.lat2){this.lat2=this.lat0;}//if lat2 is not defined
            //if (!this.k0) this.k0 = 1.0;

            Double temp = SOURCE_B / SOURCE_A;
            source_e = Math.sqrt(1.0 - temp*temp);

            Double sin1 = Math.sin(SOURCE_LAT1);
            Double cos1 = Math.cos(SOURCE_LAT1);
            Double ms1 = msfnz(source_e, sin1, cos1);
            Double ts1 = tsfnz(source_e, SOURCE_LAT1, sin1);

            Double ts0 = tsfnz(source_e, SOURCE_LAT0, Math.sin(SOURCE_LAT0));

            source_ns = sin1;
            source_f0 = ms1 / (source_ns * Math.pow(ts1, source_ns));
            source_rh = SOURCE_A * source_f0 * Math.pow(ts0, source_ns);
        }

        public void initialize_destination() {
            dest_a2 = DEST_A * DEST_A;          // used in geocentric
            dest_b2 = DEST_B * DEST_B;          // used in geocentric
            dest_es = (dest_a2-dest_b2)/dest_a2;  // e ^ 2
            dest_e = Math.sqrt(dest_es);        // eccentricity
            dest_ep2 = (dest_a2-dest_b2)/dest_b2; // used in geocentric
        }

        public void transform() {
            // Convert Cartesian to longlat
            inverse();
            // Adjust for the prime source meridian if necessary
            this.X = this.X + SOURCE_FROM_GREENWICH;
            // Convert datums if needed, and if possible.
            datum_transform();
            // convert radians to decimal degrees
            this.X = this.X*this.R2D;
            this.Y = this.Y*this.R2D;
            // copy lat/long
            this.Latitude = this.Y;
            this.Longitude = this.X;
        }

        // Lambert Conformal Conic inverse equations--mapping x,y to lat/long
        // -----------------------------------------------------------------
        private void inverse() {
            Double rh1, con, ts, theta = 0;
            Double lat, lon;
            Double x = (this.X - this.SOURCE_X0) / this.SOURCE_K0;
            Double y = (this.SOURCE_RH - (this.Y - this.SOURCE_Y0)/this.SOURCE_K0);

            if (this.source_ns > 0) {
                rh1 = Math.sqrt (x * x + y * y);
                con = 1.0;
            } else {
                rh1 = -Math.sqrt (x * x + y * y);
                con = -1.0;
            }
            if (rh1 != 0) {
                theta = Math.atan2((con * x),(con * y));
            }
            if ((rh1 != 0) || (this.source_ns > 0)) {
                con = 1 / this.source_ns;
                ts = rh1/(this.SOURCE_A * this.source_f0);
                ts = Math.pow(ts, con);
                lat = phi2z(this.source_e, ts);
                if (lat == -9999) {
                    system.debug('Error in Latitude == -9999');
                    return;
                }
            } else {
                lat = -this.HALF_PI;
            }
            lon = adjust_lon((Double)(theta/this.source_ns));
            this.X = lon;
            this.Y = lat;
        }

        // Function to compute the latitude angle, phi2, for the inverse of the
        //   Lambert Conformal Conic and Polar Stereographic projections.
        // ----------------------------------------------------------------
        private Double phi2z(Double eccent, Double ts) {
            Double eccnth = 0.5 * eccent;
            Double con, dphi;
            Double phi = this.HALF_PI - 2 * Math.atan(ts);
            for (Integer i = 0; i <= 15; i++) {
                    con = eccent * Math.sin(phi);
                    dphi = this.HALF_PI - 2 * Math.atan(ts *(Math.pow((Double)((1 - con)/(1 + con)), eccnth))) - phi;
                    phi += dphi;
                    if (Math.abs(dphi) <= .0000000001)
                            return phi;
            }
            system.debug('phi2z has NoConvergence');
            return -9999;
        }

        // Function to adjust longitude to -180 to 180; input in radians
        // ----------------------------------------------------------------
        private Double adjust_lon(Double x) {
            // Sign of an argument
            Integer sign;
            if (x < 0.0)
                sign = -1;
            else
                sign = 1;
            x = (Math.abs(x) < this.PI) ? x: (x - (sign*this.TWO_PI) );
            return x;
        }

        // Function to transform in geodetic coordinates (long, lat, height)
        // ----------------------------------------------------------------
        private void datum_transform() {
            // Convert to geocentric coordinates.
            geodetic_to_geocentric();
            // Convert between datums
            this.X += -168;
            this.Y += -60;
            this.Z += 320;
            // Convert back to geodetic coordinates
            geocentric_to_geodetic();
        }

        private void geodetic_to_geocentric() {
            Double Longitude = this.X;
            Double Latitude = this.Y;
            Double Height = this.Z;
            Double X, Y, Z;
            Double Rn;            /*  Earth radius at location  */
            Double Sin_Lat;       /*  Math.sin(Latitude)  */
            Double Sin2_Lat;      /*  Square of Math.sin(Latitude)  */
            Double Cos_Lat;       /*  Math.cos(Latitude)  */

            /*
            ** Don't blow up if Latitude is just a little out of the value
            ** range as it may just be a rounding issue.
            */
            if( Latitude < -this.HALF_PI && Latitude > -1.001 * this.HALF_PI ) {
                Latitude = -this.HALF_PI;
            } else if( Latitude > this.HALF_PI && Latitude < 1.001 * this.HALF_PI ) {
                Latitude = this.HALF_PI;
            } else if ((Latitude < -this.HALF_PI) || (Latitude > this.HALF_PI)) {
                // Latitude out of range
                system.debug('geocent:lat out of range:' + Latitude);
                return;
            }

            if (Longitude > this.PI)
                Longitude -= (2*this.PI);
            Sin_Lat = Math.sin(Latitude);
            Cos_Lat = Math.cos(Latitude);
            Sin2_Lat = Sin_Lat * Sin_Lat;
            Rn = this.SOURCE_A / (Math.sqrt(1 - this.SOURCE_ES * Sin2_Lat));
            X = (Rn + Height) * Cos_Lat * Math.cos(Longitude);
            Y = (Rn + Height) * Cos_Lat * Math.sin(Longitude);
            Z = ((Rn * (1 - this.SOURCE_ES)) + Height) * Sin_Lat;
            this.X = X;
            this.Y = Y;
            this.Z = Z;
        }

        private void geocentric_to_geodetic() {
            Double genau = 0.00000614421;
            Double genau2 = (genau*genau);
            Integer maxiter = 30;
            Double P;        /* distance between semi-minor axis and location */
            Double RR;       /* distance between center and location */
            Double CT;       /* sin of geocentric latitude */
            Double ST;       /* cos of geocentric latitude */
            Double RX, RK;
            Double RN;       /* Earth radius at location */
            Double CPHI0;    /* cos of start or old geodetic latitude in iterations */
            Double SPHI0;    /* sin of start or old geodetic latitude in iterations */
            Double CPHI;     /* cos of searched geodetic latitude */
            Double SPHI;     /* sin of searched geodetic latitude */
            Double SDPHI;    /* end-criterium: addition-theorem of sin(Latitude(iter)-Latitude(iter-1)) */
            Boolean At_Pole;     /* indicates location is in polar region */
            Integer iter;        /* # of continous iteration, max. 30 is always enough (s.a.) */
            Double X = this.X;
            Double Y = this.Y;
            Double Z = this.Z;   //Z value not always supplied
            Double Longitude;
            Double Latitude;
            Double Height;
            At_Pole = false;
            P = Math.sqrt(X*X+Y*Y);
            RR = Math.sqrt(X*X+Y*Y+Z*Z);

            // Special cases for latitude and longitude */
            if (P / this.DEST_A < genau) {
                // Special case, if P=0. (X=0., Y=0.) */
                At_Pole = true;
                Longitude = 0;

                // if (X,Y,Z)=(0.,0.,0.) then Height becomes semi-minor axis  of ellipsoid (=center of mass), Latitude becomes PI/2 */
                if (RR / this.DEST_A < genau) {
                    Latitude = this.HALF_PI;
                    Height   = -DEST_B;
                    return;
                }
            } else {
                //  ellipsoidal (geodetic) longitude. interval: -PI < Longitude <= +PI */
                Longitude = Math.atan2(Y,X);
            }

            /* --------------------------------------------------------------
             * Following iterative algorithm was developped by
             * "Institut f�r Erdmessung", University of Hannover, July 1988.
             * Internet: www.ife.uni-hannover.de
             * Iterative computation of CPHI,SPHI and Height.
             * Iteration of CPHI and SPHI to 10**-12 radian resp.
             * 2*10**-7 arcsec.
             * --------------------------------------------------------------
             */
            CT = Z/RR;
            ST = P/RR;
            RX = 1/Math.sqrt(1-this.dest_es*(2-this.dest_es)*ST*ST);
            CPHI0 = ST*(1-this.dest_es)*RX;
            SPHI0 = CT*RX;
            iter = 0;

            /* loop to find sin(Latitude) resp. Latitude
            * until |sin(Latitude(iter)-Latitude(iter-1))| < genau */
            do {
                iter++;
                RN = this.DEST_A / Math.sqrt(1-this.dest_es*SPHI0*SPHI0);
                //  ellipsoidal (geodetic) height */
                Height = P*CPHI0+Z*SPHI0-RN*(1-this.dest_es*SPHI0*SPHI0);
                RK = this.dest_es*RN/(RN+Height);
                RX = 1.0/Math.sqrt(1-RK*(2-RK)*ST*ST);
                CPHI = ST*(1-RK)*RX;
                SPHI = CT*RX;
                SDPHI = SPHI*CPHI0-CPHI*SPHI0;
                CPHI0 = CPHI;
                SPHI0 = SPHI;
            }
            while (SDPHI*SDPHI > genau2 && iter < maxiter);
            //      ellipsoidal (geodetic) latitude */
            Latitude=Math.atan(SPHI/Math.abs(CPHI));
            this.X = Longitude;
            this.Y = Latitude;
            this.Z = Height;
        }

        private Double msfnz(Double eccent, Double sinphi, Double cosphi) {
            Double con = eccent * sinphi;
            return cosphi/(Math.sqrt(1-con*con));
        }

        private Double tsfnz(Double eccent, Double phi, Double sinphi) {
            Double con = eccent*sinphi;
            Double com = 0.5*eccent;
            con = Math.pow(((1-con)/(1+con)), com);
            return (Math.tan(0.5*(HALF_PI-phi))/con);
        }
    }

    // *********************** wrapper classes for sObjects to send as JSON.
    // NOTE: All type custing (sObject -> JSON wrapper) is done in constructors
    public class Sector {
        public string Id   { get; set; }
        public string Name { get; set; }
        public string WKT  { get; set; }
        public string Code  { get; set; }

        public Sector () { }
        public Sector (Sectorisation__c ve) { Id   = ve.Id; Name = ve.Id;}
        public Sector (Sectorisation__c ve, Attachment att) {
            Id   = ve.Id;
            Name = ve.Id;
            Code = ve.codeMagasin__c;
            if(att != null) WKT  = att.Body.toString();
        }
    }

    /**
    *
    *   Classe d'aide pour parse du JSON pour les contrats/chantiers sur Feuille de route
    *
    **/
    public class ContratFDR {
        public String  id             { get; set; }
        public String  name           { get; set; }
        public String  address        { get; set; }
        public String  postalCode     { get; set; }
        public String  city           { get; set; }
        public String  telephone      { get; set; }
        public String  isOwner        { get; set; }
        public String  contractDate   { get; set; }
        public String  lastSAVdate    { get; set; }
        public Integer SAVnumber      { get; set; }
        public String  lastVendorName { get; set; }
        public String  productList    { get; set; }
        public String  prohibited     { get; set; }
        public String  rdvType        { get; set; }
        public Double  latitude       { get; set; }
        public Double  longitude      { get; set; }

        public ContratFDR (KContrat__c contrat) {
            // Définit les champs partagés
            setSharedFields(contrat.Chantier__r);
            // Définit les champs
            city           = Utils.nullString2emptyString(contrat.Chantier__r.ville__c);
            postalCode     = Utils.nullString2emptyString(contrat.Chantier__r.codePostal__c);
            address        = Utils.nullString2emptyString(contrat.Chantier__r.rue__c);
            contractDate   = (contrat.datesignature__c != null) ? contrat.datesignature__c.format() : null;
            prohibited     = (contrat.Chantier__r.interditProspection__c) ? 'Vrai' : 'Faux';
            if (contrat.nombreInterventionsSAV__c == 0 || contrat.nombreInterventionsSAV__c == null) {
                lastSAVdate = (contrat.derniereInterventionSAV__c != null) ? contrat.derniereInterventionSAV__c.format() : null;
                SAVnumber   = (contrat.nbSAVTotal__c == 0 || contrat.nbSAVTotal__c == null) ? 0 : Integer.valueOf(contrat.nbSAVTotal__c);
            }
            productList = contrat.produits__c;
        }

        public ContratFDR (Order commande) {
            // Définit les champs partagés
            setSharedFields(commande.chantier__r);
            // Définit les champs
            city           = Utils.nullString2emptyString(commande.chantier__r.ville__c);
            postalCode     = Utils.nullString2emptyString(commande.chantier__r.codePostal__c);
            address        = Utils.nullString2emptyString(commande.chantier__r.rue__c);
            contractDate   = (commande.EffectiveDate != null) ? commande.EffectiveDate.format() : null;
            prohibited     = (commande.chantier__r.interditProspection__c) ? 'Vrai' : 'Faux';
            /*if (commande.nombreInterventionsSAV__c == 0 || commande.nombreInterventionsSAV__c == null) {
                lastSAVdate = (commande.derniereInterventionSAV__c != null) ? commande.derniereInterventionSAV__c.format() : null;
                SAVnumber   = (commande.nbSAVTotal__c == 0 || commande.nbSAVTotal__c == null) ? 0 : Integer.valueOf(commande.nbSAVTotal__c);
            }
            productList = commande.produits__c;
            */
        }
        
        public ContratFDR (Chantier__c chantier, String eventType) {
            // Définit les champs partagés
            setSharedFields(chantier);
            // Définit les champs
            city           = Utils.nullString2emptyString(chantier.ville__c);
            postalCode     = Utils.nullString2emptyString(chantier.codePostal__c);
            address        = Utils.nullString2emptyString(chantier.rue__c);
            prohibited     = (chantier.interditProspection__c) ? 'Vrai' : 'Faux';
            rdvType        = eventType;
            SAVnumber      = 0;
        }
        
        public ContratFDR (Chantier__c chantier) {
            // Définit les champs partagés
            setSharedFields(chantier);
            // Définit les champs
            KContrat__c contrat = chantier.chantierContrats__r[0];
            city           = Utils.nullString2emptyString(chantier.ville__c);
            postalCode     = Utils.nullString2emptyString(chantier.codePostal__c);
            address        = Utils.nullString2emptyString(chantier.rue__c);
            prohibited     = (chantier.interditProspection__c) ? 'Vrai' : 'Faux';
            contractDate   = (contrat.datesignature__c != null) ? contrat.datesignature__c.format() : null;
            if (contrat.nombreInterventionsSAV__c == 0 || contrat.nombreInterventionsSAV__c == null) {
                lastSAVdate = (contrat.derniereInterventionSAV__c != null) ? contrat.derniereInterventionSAV__c.format() : null;
                SAVnumber   = (contrat.nbSAVTotal__c == 0 || contrat.nbSAVTotal__c == null) ? 0 : Integer.valueOf(contrat.nbSAVTotal__c);
            }
            productList = contrat.produits__c;
        }
        
        private void setSharedFields(Chantier__c chantier) {
            id = chantier.id;
            latitude = chantier.Localisation__Latitude__s;
            longitude = chantier.Localisation__Longitude__s;
            if((chantier.proprietaire__c!=null) || (chantier.autreProprietaire__c!=null)) {
                name = Utils.nullString2emptyString(chantier.nomProprietaires__c) + ' ' + Utils.nullString2emptyString(chantier.prenomProprietaires__c);
                //CRM-426: LCL Gestion Téléphone
                String telephoneDomicile = chantier.telephoneDomicileProprietaires__c;
                String telephoneMobile = chantier.telephoneMobileProprietaires__c;
                String telephoneAutre = chantier.autreTelephoneProprietaires__c;
                telephone = setTelephone(telephoneDomicile, telephoneMobile, telephoneAutre);
                isOwner = 'Proprietaire';
            }
            else if ((chantier.locataire__c !=null) || (chantier.autreLocataire__c !=null)) {
                name = Utils.nullString2emptyString(chantier.nomLocataires__c) + ' ' + Utils.nullString2emptyString(chantier.prenomLocataires__c);
                //CRM-426: LCL Gestion Téléphone
                String telephoneDomicile = chantier.telephoneDomicileLocataires__c;
                String telephoneMobile = chantier.telephoneMobileLocataires__c;
                String telephoneAutre = chantier.autreTelephoneLocataires__c;
                telephone = setTelephone(telephoneDomicile, telephoneMobile, telephoneAutre);
                isOwner = 'Locataire';
            }
            else if ((chantier.occupant__c !=null) || (chantier.autreOccupant__c !=null)) {
                name = Utils.nullString2emptyString(chantier.nomOccupants__c) + ' ' + Utils.nullString2emptyString(chantier.prenomOccupants__c);
                //CRM-426: LCL Gestion Téléphone
                String telephoneDomicile = chantier.telephoneDomicileOccupants__c;
                String telephoneMobile = chantier.telephoneMobileOccupants__c;
                String telephoneAutre = chantier.autreTelephoneOccupants__c;
                telephone = setTelephone(telephoneDomicile, telephoneMobile, telephoneAutre);
                isOwner = 'Occupant';
            } else {
                name = '';
                telephone = '';
                isOwner = '';
            }           
        }
    }

    public static String setTelephone (String telDomicile, String telMobile, String telAutre) {
        String tel;
        if (!StringUtils.isEmpty(telDomicile)){
            if (!StringUtils.isEmpty(telMobile)){
                if (!StringUtils.isEmpty(telAutre)){
                    tel = telDomicile +'<br/>';
                    tel += telMobile +'<br/>';
                    tel += telAutre +'<br/>';
                } else {
                    tel = (StringUtils.isEmpty(telDomicile)) ? '' : telDomicile +'<br/>';
                    tel += telMobile;
                }
            } else {
                tel = telDomicile;
                if (!StringUtils.isEmpty(telAutre)) tel += '<br/>' + telAutre;
            }
        } else {
            if (!StringUtils.isEmpty(telMobile)){
                if (!StringUtils.isEmpty(telAutre)){
                    tel = telMobile;
                    tel += '<br/>' + telAutre;
                } else
                    tel = telMobile;
            } else
                tel = telAutre;
        }
        return tel;
    }
    
    public static List<ContratFDR> newContratFDRList (List<ServiceAppointment> contratsList) {
        List<ContratFDR> contratList = new List<ContratFDR>();
        List<ContratFDR> orderList = new List<ContratFDR>();        
        List<ContratFDR> result = new List<ContratFDR>();
        List<KContrat__c> kcontratList = new List<KContrat__c>();
        List<Order> customerOrderList = new List<Order>();
        Set<Id> kcontratIdList = new Set<Id>();
        Set<Id> customerOrderIdList = new Set<Id>();

        if (!contratsList.isEmpty()) {
            for (ServiceAppointment rdv : contratsList){
                if (String.isNotBlank(rdv.ContratK__c)) {
                    kcontratIdList.add(rdv.ContratK__c);
                }
                if (String.isNotBlank(rdv.customerOrder__c)) {
                    customerOrderIdList.add(rdv.customerOrder__c);
                }
            }
        }

        // Récupération infos KContrat (Kube2)
        if (!kcontratIdList.isEmpty()) {
            kcontratList = [SELECT Id, datesignature__c, LastModifiedById, LastModifiedBy.Name, chantier__c, chantier__r.OwnerId, 
                                    chantier__r.Localisation__Latitude__s, chantier__r.Localisation__Longitude__s,
                                    chantier__r.interditProspection__c, Chantier__r.Id, Chantier__r.Name,
                                    Chantier__r.nomProprietaires__c, Chantier__r.nomLocataires__c, Chantier__r.nomOccupants__c,
                                    Chantier__r.prenomProprietaires__c, Chantier__r.prenomLocataires__c, Chantier__r.prenomOccupants__c,
                                    Chantier__r.locataire__c, Chantier__r.telephoneDomicileLocataires__c, Chantier__r.telephoneMobileLocataires__c, Chantier__r.locataire__r.name,
                                    Chantier__r.proprietaire__c, Chantier__r.proprietaire__r.name, Chantier__r.telephoneDomicileProprietaires__c, Chantier__r.telephoneMobileProprietaires__c,
                                    Chantier__r.occupant__c, Chantier__r.telephoneDomicileOccupants__c, Chantier__r.telephoneMobileOccupants__c, Chantier__r.occupant__r.name,
                                    Chantier__r.autreProprietaire__c, Chantier__r.autreProprietaire__r.name,
                                    Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c, Chantier__r.autreOccupant__r.name, Chantier__r.autreLocataire__r.name,
                                    Chantier__r.codePostal__c , Chantier__r.ville__c, Chantier__r.rue__c,
                                    Chantier__r.autreTelephoneLocataires__c, Chantier__r.autreTelephoneOccupants__c, Chantier__r.autreTelephoneProprietaires__c,
                                    produits__c, derniereInterventionSAV__c, nbSAVTotal__c, nombreInterventionsSAV__c
                                FROM KContrat__c 
                                WHERE Id IN :kcontratIdList
                                ORDER BY  LastModifiedDate DESC];
            contratList = newContratFDRList(kcontratList);
        }
        
        // Récupération infos commandes (Kube3)
        if (!customerOrderIdList.isEmpty()) {
            customerOrderList = [SELECT Id, EffectiveDate, LastModifiedById, LastModifiedBy.Name, chantier__c, chantier__r.OwnerId, 
                                    chantier__r.Localisation__Latitude__s, chantier__r.Localisation__Longitude__s,
                                    chantier__r.interditProspection__c, Chantier__r.Id, Chantier__r.Name,
                                    Chantier__r.nomProprietaires__c, Chantier__r.nomLocataires__c, Chantier__r.nomOccupants__c,
                                    Chantier__r.prenomProprietaires__c, Chantier__r.prenomLocataires__c, Chantier__r.prenomOccupants__c,
                                    Chantier__r.locataire__c, Chantier__r.telephoneDomicileLocataires__c, Chantier__r.telephoneMobileLocataires__c, Chantier__r.locataire__r.name,
                                    Chantier__r.proprietaire__c, Chantier__r.proprietaire__r.name, Chantier__r.telephoneDomicileProprietaires__c, Chantier__r.telephoneMobileProprietaires__c,
                                    Chantier__r.occupant__c, Chantier__r.telephoneDomicileOccupants__c, Chantier__r.telephoneMobileOccupants__c, Chantier__r.occupant__r.name,
                                    Chantier__r.autreProprietaire__c, Chantier__r.autreProprietaire__r.name,
                                    Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c, Chantier__r.autreOccupant__r.name, Chantier__r.autreLocataire__r.name,
                                    Chantier__r.codePostal__c , Chantier__r.ville__c, Chantier__r.rue__c,
                                    Chantier__r.autreTelephoneLocataires__c, Chantier__r.autreTelephoneOccupants__c, Chantier__r.autreTelephoneProprietaires__c
                                FROM Order 
                                WHERE Id IN :customerOrderIdList
                                ORDER BY  LastModifiedDate DESC];
            orderList = newOrderFDRList(customerOrderList);
        }
        
        // Ajout des deux listes au résultat final
        if (!contratList.isEmpty()) {
            result.addAll(contratList);
        }
        if (!orderList.isEmpty()) {
            result.addAll(orderList);
        }
        return result;
    }

    public static List<ContratFDR> newContratFDRList (List<KContrat__c> contratsList) {
        List<ContratFDR> contratList = new List<ContratFDR>();
        if (contratsList != null) {
            for (KContrat__c contrat : contratsList)
                contratList.add (new ContratFDR(contrat));
        }
        return contratList;
    }
    public static List<ContratFDR> newChantierFDRList (List<Chantier__c> chantiersList, String rdvType) {
        List<ContratFDR> contratList = new List<ContratFDR>();
        if (chantiersList != null) {
            for (Chantier__c chantier : chantiersList)
                contratList.add (new ContratFDR(chantier, rdvType));
        }
        return contratList;
    }
    public static List<ContratFDR> newChantierWithContratFDRList (List<Chantier__c> chantiersList) {
        List<ContratFDR> contratList = new List<ContratFDR>();
        if (chantiersList != null) {
            for (Chantier__c chantier : chantiersList)
                contratList.add (new ContratFDR(chantier));
        }
        return contratList;
    }
    public static List<ContratFDR> newOrderFDRList (List<Order> customerOrderList) {
        List<ContratFDR> contratList = new List<ContratFDR>();
        if (customerOrderList != null) {
            for (Order customerOrder : customerOrderList)
                contratList.add (new ContratFDR(customerOrder));
        }
        return contratList;
    }
    
    /**
    *
    *   Classe d'aide pour parse les contrats/chantiers/RDV sur la cartographie
    *
    **/
    public class DotMap {
        public String  Id             { get; set; }
        public String  ObjectType     { get; set; }
        public String  OwnerId        { get; set; }
        public String  OwnerName      { get; set; }
        public String  Name           { get; set; }
        public String  Address        { get; set; }
        public String  PostalCode     { get; set; }
        public String  City           { get; set; }
        public String  AddressComplete { get; set; }
        public String  ActivityDate   { get; set; }
        public String  RdvType        { get; set; }
        public String  ProjectOrigin  { get; set; }
        public Double  Latitude       { get; set; }
        public Double  Longitude      { get; set; }
        public Decimal  X             { get; set; }
        public Decimal  Y             { get; set; }

        public DotMap (Chantier__c chantier) {
            ObjectType     = 'chantier';
            Id             = chantier.Id;
            OwnerId        = chantier.OwnerId;
            OwnerName      = chantier.Owner.Name;
            Address        = Utils.nullString2emptyString(chantier.rue__c);
            PostalCode     = Utils.nullString2emptyString(chantier.codePostal__c);
            City           = Utils.nullString2emptyString(chantier.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = chantier.Localisation__Latitude__s;
            Longitude      = chantier.Localisation__Longitude__s;
        }
        
        public DotMap (Event event, Chantier__c chantier) {
            ObjectType     = 'chantier';
            Id             = chantier.Id;
            OwnerId        = event.OwnerId;
            OwnerName      = event.Owner.Name;
            Address        = Utils.nullString2emptyString(chantier.rue__c);
            PostalCode     = Utils.nullString2emptyString(chantier.codePostal__c);
            City           = Utils.nullString2emptyString(chantier.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = chantier.Localisation__Latitude__s;
            Longitude      = chantier.Localisation__Longitude__s;
            ActivityDate   = event.ActivityDate.format();
            RdvType        = event.Type;
        }
        
        public DotMap (Event event, Opportunity projet, Chantier__c chantier) {
            ObjectType     = 'chantier';
            Id             = chantier.Id;
            OwnerId        = event.OwnerId;
            OwnerName      = event.Owner.Name;
            Name           = projet.account.Name;
            Address        = Utils.nullString2emptyString(chantier.rue__c);
            PostalCode     = Utils.nullString2emptyString(chantier.codePostal__c);
            City           = Utils.nullString2emptyString(chantier.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = chantier.Localisation__Latitude__s;
            Longitude      = chantier.Localisation__Longitude__s;
            ActivityDate   = event.ActivityDate.format();
            RdvType        = event.Type;
            ProjectOrigin  = projet.LeadSource;
        }

        public DotMap (Event event) {
            ObjectType     = 'event';
            Id             = event.Id;
            OwnerId        = event.OwnerId;
            OwnerName      = event.Owner.Name;
            Name           = event.Type;
            Address        = Utils.nullString2emptyString(event.rue__c);
            PostalCode     = Utils.nullString2emptyString(event.codePostal__c);
            City           = Utils.nullString2emptyString(event.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = event.Localisation__Latitude__s;
            Longitude      = event.Localisation__Longitude__s;
            ActivityDate   = event.ActivityDate.format();
            RdvType        = event.Type;
        }
        
        public DotMap (User utilisateur) {
            Id             = utilisateur.Id;
            Name           = utilisateur.Name;
            Address        = Utils.nullString2emptyString(utilisateur.rue__c);
            PostalCode     = Utils.nullString2emptyString(utilisateur.codePostal__c);
            City           = Utils.nullString2emptyString(utilisateur.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = utilisateur.localisationLatitude__c;
            Longitude      = utilisateur.localisationLongitude__c;
        }
        
        public DotMap (Event event, Account compte) {
            ObjectType     = 'account';
            Id             = compte.Id;
            OwnerId        = compte.OwnerId;
            OwnerName      = compte.Owner.Name;
            Name           = compte.Name;
            Address        = Utils.nullString2emptyString(compte.rue__c);
            PostalCode     = Utils.nullString2emptyString(compte.codePostal__c);
            City           = Utils.nullString2emptyString(compte.ville__c);
            AddressComplete = (Address == '') ? '' : Address + ', ';
            AddressComplete += PostalCode + ' ' + City;
            Latitude       = compte.Localisation__Latitude__s;
            Longitude      = compte.Localisation__Longitude__s;
            ActivityDate   = event.ActivityDate.format();
            RdvType        = event.Type;
        }
    }
}