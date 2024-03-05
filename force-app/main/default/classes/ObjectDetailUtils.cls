//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ObjectDetailUtils
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 16/06/2015
//-- Version     : 1.0
//-- * Ajout des fonctions utiles pour les pages de détails des objets
//-- --------------------------------------------------------------------------------- --
global class ObjectDetailUtils {

    /**
    *
    *  Calcul la distance entre deux coordonnées géodésique (Latiture/Longitude)
    *
    **/
    public static Decimal CalculationByDistance(Decimal initialLat, Decimal initialLong, Decimal finalLat, Decimal finalLong) {
        Decimal R = 6371; // km
        Decimal dLat = toRadians(finalLat-initialLat);
        Decimal dLon = toRadians(finalLong-initialLong);
        Decimal lat1 = toRadians(initialLat);
        Decimal lat2 = toRadians(finalLat);

        Decimal a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2);
        Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
    public static Decimal toRadians(Decimal deg) {
        return deg * (Math.PI/180);
    }

    /**
    *
    *  Formatage de la date pour le standard des timeline
    *
    **/
    public static String formatDateForCalendar(Datetime dateToFormat) {
        String dtFormat = 'yyyy-MM-dd';
        String hourFormat = 'HH:mm:ssZ';
        return dateToFormat.format(dtFormat, UserInfo.getTimeZone().getID()) + 'T' + dateToFormat.format(hourFormat, UserInfo.getTimeZone().getID());
    }

    // Stockage des informations des vendeurs pour affectation
    global class Vendeur {
        global Id UserId { get; set; }
        global String UserName { get; set; }
        global String LibelleMagasin { get; set; }
        global Decimal Distance { get; set; }
        global Integer Position { get; set; }
    }

    // Stockage des activités pour le tableaux
    global class Activity {
        global Task task { get; set; }
        global Event event { get; set; }
        global Boolean isSelected { get; set; }
        global Boolean isTask { get; set; }
        //recup tous les champs communs aux 2
        global String id { get; set; }
        global String subject { get; set; }
        global String whatId { get; set; }
        global String whoId { get; set; }
        global String whatName { get; set; }
        global String whoName { get; set; }
        global Datetime activityDateTime { get; set; }
        global String activityDate { get; set; }
        global String startActivityDateTime { get; set; }
        global String endActivityDateTime { get; set; }
        global String ownerId { get; set; }
        global String ownerName { get; set; }
        global String ownerPhotoUrl { get; set; }
        global Boolean isInProgress { get; set; }
        global String statutRDV { get; set; }

        global Activity(Task t, Boolean b, Map<String, User> activitiesUsersPhotos) {
            task = t;
            isSelected = b;
            isTask = true;
            id = t.id;
            subject = t.subject;
            whatId = t.what.id;
            whoId = t.who.id;
            whatName = t.what.name;
            whoName = t.who.name;
            statutRDV = null;
            activityDateTime = t.activityDate;
            if(activityDateTime!=null){
                activityDate = activityDateTime.format('dd/MM/yyyy');
            }
            ownerName = t.owner.name;
            ownerId = t.owner.id;
            if(activitiesUsersPhotos != null || !activitiesUsersPhotos.isEmpty()) {
                if(activitiesUsersPhotos.get(ownerId) != null)
                    ownerPhotoUrl = activitiesUsersPhotos.get(ownerId).SmallPhotoUrl;
            }
            isInProgress = (t.status == 'Terminé') ? false : true;
        }

        global Activity(Event evnt, Boolean b, Map<String, User> activitiesUsersPhotos) {
            event = evnt;
            isSelected = b;
            isTask = false;
            id = evnt.id;
            subject = evnt.subject;
            whatId = evnt.what.id;
            whoId = evnt.who.id;
            whatName = evnt.what.name;
            whoName = evnt.who.name;
            statutRDV = evnt.statutRDV__c;
            activityDateTime = evnt.activityDate;
            if(activityDateTime != null){
                activityDate = activityDateTime.format('dd/MM/yyyy');
            }
            startActivityDateTime = ObjectDetailUtils.formatDateForCalendar(evnt.StartDateTime);
            endActivityDateTime = ObjectDetailUtils.formatDateForCalendar(evnt.EndDateTime);
            ownerName = evnt.owner.name;
            ownerId = evnt.owner.id;
            if(activitiesUsersPhotos != null || !activitiesUsersPhotos.isEmpty()) {
                if(activitiesUsersPhotos.get(ownerId) != null)
                    ownerPhotoUrl = activitiesUsersPhotos.get(ownerId).SmallPhotoUrl;
            }
            isInProgress = (evnt.activityDate < system.now()) ? false : true;
        }
    }
}