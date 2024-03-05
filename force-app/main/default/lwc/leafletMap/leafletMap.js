/* eslint-disable no-console */
/* eslint-disable no-undef */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import LEAFLET_JS from '@salesforce/resourceUrl/leaflet';
import LEAFLET_ICONS from '@salesforce/resourceUrl/leaflet_icons';

export default class LeafletMap extends LightningElement {
    @api leafletInitialized = false;    
    @api longitude;
    @api latitude;
    @api markersArray = [];
    @api polygonsArray = [];
    // Config variables
    @api mapHeight;

    // Internal variables
    @track map;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        
        this.markersArray = [];
        this.polygonsArray = [];
    }
    
    /**
     * connectedCallback of the LWC.
     * @connectedCallback
     */
    connectedCallback() {
        console.debug("LeafletMap : connectedCallback");
        /*if (this.leafletInitialized) {
            return;
        }*/

        // Load the JS of LEAFLET in ASYNC method and call the init function
        loadScript(this, LEAFLET_JS + '/leaflet.js')
        .then(() => {
            this.initializeLeaflet();
            this.leafletInitialized = true;
            // Dispatch this event on the parent component to indicates that the component is loaded
            this.dispatchEvent(new CustomEvent('initialized'));
        })
        .catch(error => {
            console.error("## ERROR: "+error.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur au chargement de Leaflet',
                    message: error.message,
                    variant: 'error'
                })
            );
        });
        // Load the CSS Style of LEAFLET in ASYNC method
        loadStyle(this, LEAFLET_JS + '/leaflet.css');
    }

    /* ========== JS METHODS ========== */

    /**
     * Initialize Leaflet map.
     */
    initializeLeaflet() {
        console.debug("LeafletMap : initializeLeaflet");
        // Initialise variables
        const latlngInit = L.latLng(39.7392, -104.991531);
        const zoomInit = 14;

        // Initialize map
        const mapRoot = this.template.querySelector(".map-root");
        this.map = L.map(mapRoot, { zoomControl: false, tap: false }
        ) //disable zoomControl when initializing map (which is topleft by default)
        .setView(latlngInit, zoomInit); 

        // Add zoom control in top right
        L.control.zoom({
            position:'topright'
        }).addTo(this.map);

        // create the tile layer with correct attribution
        const osmUrl='https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
        const osmAttrib='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
        const tileLayer = new L.TileLayer(osmUrl, {
            minZoom: 7, 
            maxZoom: 18, 
            attribution: osmAttrib
        });

        // Start the map 
        this.map.addLayer(tileLayer);
    }
    
    /**
     * Function to center the map on the polygon (sector).
     * @param {object} polygon - sector to center.
     */
    autoCenter(polygon) {
        //  Fit these bounds to the map
        this.map.fitBounds(polygon.getBounds());
    }

    /* ========== API METHODS ========== */

    /**
     * Function to create a marker on the map with custom icon.
     * @param {string} markerType - Type of the marker.
     * @param {object} latitude - Latitude of the marker.
     * @param {object} longitude - Longitude of the marker.
     * @param {object} iconName - Path of the icon in the static ressource "leaflet_icons".
     * @param {object} iconSize - Size of the icon.
     * @param {object} iconAnchor - Anchor of the icon on the map.
     * @param {object} popupAnchor - Anchor of the popup on the map.
     */
    @api
    addMarkerWithIcon(markerType, latitude, longitude, iconName, autoCenter = true, iconSize=[32,37], iconAnchor=[16,37], popupAnchor=[0, -37]) {
        let marker;
        let location = L.latLng(latitude, longitude);
        if(location && iconName) {
            // Create the marker with icon
            let iconURL = LEAFLET_ICONS + '/' + iconName;
            let markIcon = L.icon({
                iconUrl: iconURL,
                iconSize:     iconSize, // size of the icon
                iconAnchor:   iconAnchor, // point of the icon which will correspond to marker's location
                popupAnchor:  popupAnchor // point from which the popup should open relative to the iconAnchor
            });
            marker = L.marker(location, {icon: markIcon}).addTo(this.map);
            // Center on the marker
            if(autoCenter) {
                this.map.panTo(location); 
            }
        
            // Add the marker in the array
            if(this.markersArray[markerType] === undefined) {
                this.markersArray[markerType] = [];
            }
            this.markersArray[markerType].push(marker);
        }
        return marker;
    }

    /**
     * Function to create a simple marker on the map.
     * @param {string} markerType - Type of the marker.
     * @param {object} latitude - Latitude of the marker.
     * @param {object} longitude - Longitude of the marker.
     * @param {boolean} autoCenter - Auto Center on the marker (default value = true).
     */
    @api
    addMarker(markerType, latitude, longitude, autoCenter = true) {
        let marker;
        let location = L.latLng(latitude, longitude);
        if(location) {
            // Create the marker 
            marker = L.marker(location).addTo(this.map);
            // Center on the marker
            if(autoCenter) {
                this.map.panTo(location); 
            }

            // Add the marker in the array
            if(this.markersArray[markerType] === undefined) {
                this.markersArray[markerType] = [];
            }
            this.markersArray[markerType].push(marker);
        }
        return marker;
    }

    /**
     * Function to attach a tooltip on the marker on the map.
     * @param {object} marker - The marker.
     * @param {string} content - Content of the tooltip.
     * @param {object} options - Options of the tooltip.
     */
    @api
    addPopupOnMarker(marker, content, options) {    
        // Add popup on marker
        //L.DomEvent.on(marker, 'click', function (ev) {
            marker.bindPopup(content, options);
            //L.DomEvent.stopPropagation(ev);
        //});
    
        return marker;
    }

    /**
     * Function that delete all markers and sectors.
     */
    @api
    deleteAll() {
        // Delete sectors
        if(this.polygonsArray) {
            for (var i = 0; i < this.polygonsArray.length; i++ ) {
                this.map.removeLayer(this.polygonsArray[i]);
            }
            this.polygonsArray = [];
        }
    
        // Delete markers
        if(this.markersArray) {
            for(var key in this.markersArray) {
                for (var i = 0; i < this.markersArray[key].length; i++ ) {
                    this.map.removeLayer(this.markersArray[key][i]);
                }
            }
            this.markersArray = [];
        }
    }

    /* Fonction permettant de construire l'objet contenant les points du secteur    */
    /*------------------------------------------------------------------------------*/
    @api
    addSectorPolygon(latLongStr, color, isFSLPoylon, autoCenter = false) {
        let sectorPolygon = null;

        if (latLongStr) {
            // Options of the sector
            let optionSector = {
                color: 'red',
                weight: 3,
                fillColor: color
            };

            // Create the sector array 
            let sectorsCoords;     
            // Process to create the new sector
            if(isFSLPoylon) {
                sectorsCoords = this.processFSLSector(latLongStr);
            } else {
                sectorsCoords = this.processStandardSector(latLongStr);
            }

            // Create the polygon object
            sectorPolygon = L.polygon(sectorsCoords, optionSector);
            if(sectorPolygon) {
                // Add polygon in the map
                sectorPolygon.addTo(this.map);               
                // Center on the marker
                if(autoCenter) {
                    this.map.fitBounds(sectorPolygon.getBounds()); 
                }
                // Add the marker in the array
                this.polygonsArray.push(sectorPolygon);
            }
        }
        return sectorPolygon;
    }

    /**
     * Function to geocode address
     * @param {string} address - Address to geocode.
     * @return callback callback function.
     */
    @api
    geocodeAddress(address, callback) {
        // Geocode the address
        var geocoder = new L.Control.Geocoder.Nominatim({serviceUrl: "https://nominatim.openstreetmap.org/"});
        geocoder.geocode(address, function(results) {
            callback(results);
        });
    }

    /* ========== JS METHODS ========== */

    /**
     * Function that process the no-FSL coordinate string into a Latlng object of Leaflet.
     * @param {string} latLongStr - String with coordinates.
     * @return Array with leaflet coordinates.
     */
    processStandardSector(latLongStr) {
        // Init
        let sectorsCoords = []; 
        // Split to get all sectors
        let sectorArray = latLongStr.split('\n');
        for(let j = 0; j < sectorArray.length; ++j){    
            let sect = sectorArray[j].split(',');
            let sectorCoords = [];
            for(let i = 0; i < (sect.length-1); ++i){
                // Split to get the latitude and longitude data
                let latLong = sect[i].split(' ');
                let lat = latLong[1].trim();
                let long = latLong[0].trim();
                // Create a Latitude/longitude object for Leaflet
                let latlng = L.latLng(lat, long);
                // Add coord in the array
                sectorCoords.push(latlng);
            }
            // Add sector in the array
            sectorsCoords.push(sectorCoords);
        }
        return sectorsCoords;
    }

    /**
     * Function that process the FSL coordinate string into a Latlng object of Leaflet.
     * @param {string} latLongStr - String with coordinates.
     * @return Array with leaflet coordinates.
     */
    processFSLSector(latLongStr) {
        // Init
        let sectorCoords = [];
        // Each lines are a coordinate
        let sectorArray = latLongStr.split('\n');
        for(let i = 0; i < sectorArray.length; ++i){
            // Split to get the latitude and longitude data
            let latLong = sectorArray[i].split(',');
            let lat = latLong[1].trim();
            let long = latLong[0].trim();
            // Create a Latitude/longitude object for Leaflet
            let latlng = L.latLng(lat, long);
            // Add in the array
            sectorCoords.push(latlng);
        }
        return sectorCoords;
    }

    /* ========== EVENT METHODS ========== */

    get cssStyle() { 
        return 'height: '+this.mapHeight+'px;';
    }
}