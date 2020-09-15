global inherited sharing class MapsApi {
    global interface Location {
    }

    global class Address implements Location {
        global final String addr;

        global Address(String addr) {
            this.addr = addr;
        }

        global override String toString() {
            return addr;
        }
    }

    global class Coordinates implements Location {
        global final Decimal lat;
        global final Decimal lng;

        global Coordinates(Decimal lat, Decimal lng) {
            this.lat = lat;
            this.lng = lng;
        }

        global override String toString() {
            return lat + ',' + lng;
        }
    }

    private abstract class Request {
        virtual String getEndpoint() {
            return 'https://maps.googleapis.com/maps/api';
        }

        abstract String getMethod();

        virtual Utils.UrlQuery getQuery() {
            Utils.UrlQuery query = new Utils.UrlQuery();

            Schema.Cs_MapsApiPrefs__c prefs = Schema.Cs_MapsApiPrefs__c.getValues(
                GOOGLE_PREFS_NAME
            );

            if (prefs == null) {
                throw new System.QueryException(
                    'Could not find ' +
                    GOOGLE_PREFS_NAME +
                    ' Maps API preference record'
                );
            }

            query.put('key', prefs.Key__c);

            return query;
        }

        virtual System.HttpResponse makeRequest() {
            System.HttpRequest req = new System.HttpRequest();

            req.setEndpoint(getEndpoint() + getQuery());
            req.setMethod(getMethod());

            return new Http().send(req);
        }
    }

    global class DistanceRequest extends Request {
        private List<Location> origins;
        private List<Location> destinations;

        global DistanceRequest() {
            origins = new List<Location>();
            destinations = new List<Location>();
        }

        override String getEndpoint() {
            return super.getEndpoint() + '/distancematrix/json';
        }

        override String getMethod() {
            return 'GET';
        }

        override Utils.UrlQuery getQuery() {
            Utils.UrlQuery query = super.getQuery();

            query.put('origins', join(origins));
            query.put('destinations', join(destinations));

            return query;
        }

        private String join(List<Location> values) {
            String value = '';
            String separator = '|';

            for (Location loc : values) {
                value += loc + separator;
            }

            return value.removeEnd(separator);
        }

        override System.HttpResponse makeRequest() {
            if (origins.isEmpty()) {
                throw new UnsupportedOperationException('Origins cannot be empty');
            }

            if (destinations.isEmpty()) {
                throw new UnsupportedOperationException('Destinations cannot be empty');
            }

            return super.makeRequest();
        }

        global DistanceRequest addDestination(Location value) {
            destinations.add(value);

            return this;
        }

        global DistanceRequest addOrigin(Location value) {
            origins.add(value);

            return this;
        }
    }

    global class DistanceResponse extends Response {
        global final List<String> destination_addresses;
        global final List<String> origin_addresses;
        global final List<DistanceResponseRow> rows;
    }

    global class DistanceResponseRow {
        global final List<DistanceResponseRowElement> elements;
    }

    global class DistanceResponseRowElement {
        global final String status;
        global final DistanceResponseRowElementValue distance;
        global final DistanceResponseRowElementValue duration;
    }

    global class DistanceResponseRowElementValue {
        global final Decimal value;
    }

    global virtual class Response {
        global final String status;
        global final String error_message;

        private Response() {
        }
    }

    private static final String GOOGLE_PREFS_NAME = 'Google';

    global static DistanceResponse distance(DistanceRequest req) {
        System.HttpResponse res = req.makeRequest();

        return (DistanceResponse) JSON.deserialize(res.getBody(), DistanceResponse.class);
    }

    global static void setPreferences(String key) {
        Utils.requireNonNull(key, 'Key cannot be null');

        Schema.Cs_MapsApiPrefs__c prefs = Schema.Cs_MapsApiPrefs__c.getValues(GOOGLE_PREFS_NAME);

        if (prefs == null) {
            prefs = new Schema.Cs_MapsApiPrefs__c(Name = GOOGLE_PREFS_NAME);
        }

        prefs.Key__c = key;

        upsert prefs;
    }
}
