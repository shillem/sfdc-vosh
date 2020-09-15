@isTest(isParallel=true)
public class MapsApiTest {
    @isTest
    static void distance() {
        TestUtils.HttpCalloutMock mock = new TestUtils.HttpCalloutMock()
            .addResponse(
                new TestUtils.HttpResponseMock(Pattern.compile('.*/distancematrix/json.*'))
                    .setBody(
                        '{' +
                        '"destination_addresses" : [ "Milan, Metropolitan City of Milan, Italy" ], ' +
                        '"origin_addresses" : [ "36100 Vicenza, Province of Vicenza, Italy" ], ' +
                        '"rows" : [ { "elements" : [ { "distance" : { "value" : 216285 }, ' +
                        '"duration" : { "value" : 8581 }, "status" : "OK" } ] } ], "status" : "OK" }'
                    )
            );

        Test.startTest();

        Test.setMock(System.HttpCalloutMock.class, mock);

        MapsApi.DistanceResponse dist = MapsApi.distance(
            new MapsApi.DistanceRequest()
                .addOrigin(new MapsApi.Address('Vicenza, Italy'))
                .addDestination(new MapsApi.Address('Milano, Italy'))
        );

        System.assertEquals('OK', dist.status);
        System.assertEquals(1, dist.rows.size());
        System.assertEquals(1, dist.rows[0].elements.size());
        System.assert(dist.rows[0].elements[0].distance.value != null);
        System.assert(dist.rows[0].elements[0].duration.value != null);

        Test.stopTest();
    }
}
