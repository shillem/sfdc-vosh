public without sharing class PrivacyManager {
    public class Snapshot {
        private final UI.Field name;
        private final UI.Field email;
        private final List<Subscription> subscriptions;

        public Snapshot(Id contactPointEmailId) {
            Schema.ContactPointEmail cpe = [
                SELECT Parent.Name, EmailAddress
                FROM ContactPointEmail
                WHERE Id = :contactPointEmailId
            ];

            name = new UI.FieldSObject(Schema.Individual.Name).setValue(cpe.Parent.Name);
            email = new UI.FieldSObject(Schema.ContactPointEmail.EmailAddress)
                .setValue(cpe.EmailAddress);
            subscriptions = getSubscriptions(cpe);
        }

        private List<Subscription> getSubscriptions(Schema.ContactPointEmail cpe) {
            List<Schema.CommSubscriptionChannelType> channels = [
                SELECT CommunicationSubscriptionId, EngagementChannelType.ContactPointType
                FROM CommSubscriptionChannelType
                WHERE EngagementChannelType.ContactPointType = 'Email'
            ];

            List<Subscription> subs = new List<Subscription>();
            Map<Id, Subscription> subByNameIds = new Map<Id, Subscription>();
            Map<Id, Subscription> subByTypeIds = new Map<Id, Subscription>();

            for (Schema.CommSubscriptionChannelType channel : channels) {
                Subscription sub = new Subscription();

                sub.nameId = channel.CommunicationSubscriptionId;
                sub.type = channel.EngagementChannelType.ContactPointType;
                sub.typeId = channel.EngagementChannelType.Id;

                subs.add(sub);
                subByNameIds.put(sub.nameId, sub);
                subByTypeIds.put(sub.typeId, sub);
            }

            List<Schema.CommSubscription> names = [
                SELECT Name
                FROM CommSubscription
                WHERE Id IN :subByNameIds.keySet()
            ];

            for (Schema.CommSubscription name : names) {
                subByNameIds.get(name.Id).name = name.Name;
            }

            List<Schema.CommSubscriptionConsent> consents = [
                SELECT CommSubscriptionChannelTypeId, EffectiveFromDate, EffectiveToDate
                FROM CommSubscriptionConsent
                WHERE
                    ContactPointId = :cpe.Id
                    AND (EffectiveToDate = null
                    OR EffectiveToDate >= :Date.today())
            ];

            for (Schema.CommSubscriptionConsent consent : consents) {
                Subscription sub = subByTypeIds.get(consent.CommSubscriptionChannelTypeId);

                sub.effectiveFrom = consent.EffectiveFromDate;
                sub.effectiveTo = consent.EffectiveToDate;
            }

            return subs;
        }
    }

    private class SnapshotRequest {
        private final Id referenceId;
    }

    public class Subscription {
        private String name;
        private Id nameId;
        private String type;
        private Id typeId;
        private Date effectiveFrom;
        private Date effectiveTo;
        private String status;
    }

    @AuraEnabled
    public static Boolean auraGenerateAuthorizationCode(Id refId, Boolean force) {
        try {
            Boolean present = AuthorizationCode.lists(refId);

            if (present && !force) {
                return false;
            }

            AuthorizationCode.notify(AuthorizationCode.generate(refId, 60 * 60 * 24));

            return true;
        } catch (System.Exception e) {
            throw new System.AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String auraGetAuthorizationStatus(String authCode, Id refId) {
        try {
            return AuthorizationCode.match(authCode, refId).name();
        } catch (System.Exception e) {
            throw new System.AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String auraGetSnapshot(String payload) {
        try {
            SnapshotRequest request = (SnapshotRequest) JSON.deserialize(
                payload,
                SnapshotRequest.class
            );

            Utils.requireNonNull(request.referenceId, 'Reference Id cannot be null');

            return JSON.serialize(new Snapshot(request.referenceId));
        } catch (System.Exception e) {
            throw new System.AuraHandledException(e.getMessage());
        }
    }
}
