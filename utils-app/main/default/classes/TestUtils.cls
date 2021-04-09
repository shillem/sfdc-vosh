/**
 * A helper methods to write tests with less code.
 *
 * @since 1.0.4
 */
@isTest
global class TestUtils {
    /**
     * @since 1.0.4
     */
    global class HttpCalloutMock implements System.HttpCalloutMock {
        private final List<HttpResponseMock> responses;

        /**
         * @since 1.0.4
         */
        global HttpCalloutMock() {
            responses = new List<HttpResponseMock>();
        }

        /**
         * @since 1.0.4
         */
        global HttpCalloutMock addResponse(HttpResponseMock value) {
            responses.add(value);

            return this;
        }

        /**
         * @since 1.0.4
         */
        global System.HTTPResponse respond(System.HTTPRequest req) {
            for (HttpResponseMock res : responses) {
                if (res.rule.matcher(req.getEndpoint()).matches()) {
                    return res.respond();
                }
            }

            throw new UnsupportedOperationException(
                'No response implementation for ' + req.getEndpoint()
            );
        }
    }

    /**
     * @since 1.0.4
     */
    global class HttpResponseMock {
        private final System.Pattern rule;
        private final Integer statusCode;

        private Object body;

        /**
         * @since 1.0.4
         */
        global HttpResponseMock(System.Pattern rule) {
            this(rule, 200);
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock(System.Pattern rule, Integer statusCode) {
            this.rule = rule;
            this.statusCode = statusCode;
        }

        /**
         * @since 1.0.4
         */
        global System.HTTPResponse respond() {
            System.HttpResponse res = new System.HttpResponse();

            res.setStatusCode(statusCode);

            if (body instanceof Blob) {
                res.setBodyAsBlob((Blob) body);
            } else if (body instanceof String) {
                res.setBody((String) body);
            }

            return res;
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock setBody(Blob body) {
            this.body = body;

            return this;
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock setBody(String body) {
            this.body = body;

            return this;
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock setStaticResourceBody(String name) {
            return setStaticResourceBody(name, null);
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock setStaticResourceBody(String name, String key) {
            return setStaticResourceBody(name, key, new List<String>());
        }

        /**
         * @since 1.0.4
         */
        global HttpResponseMock setStaticResourceBody(
            String name,
            String key,
            List<String> variables
        ) {
            Schema.StaticResource resource = [
                SELECT Body
                FROM StaticResource
                WHERE Name = :name
                LIMIT 1
            ];

            String body;

            if (key != null) {
                Map<String, Object> value = (Map<String, Object>) JSON.deserializeUntyped(
                    resource.Body.toString()
                );

                body = JSON.serialize(value.get(key));
            } else {
                body = resource.Body.toString();
            }

            for (Integer i = 0; i < variables.size(); i++) {
                body = ((String) body).replace('{' + i + '}', variables.get(i));
            }

            return this;
        }
    }

    /**
     * A builder that lays the foundation to generate any number of SObject records
     *
     * @since 1.0.4
     */
    global virtual class SObjectMaker {
        private final Schema.SObjectType type;

        private Boolean autoInsert;
        private Integer count;
        private String name;
        private Id ownerId;

        /**
         * It creates an instance that will generate <code>SObject</code> records
         * of the provided <code>SObjectType</code>.
         *
         * @param type the <code>SObjectType</code>
         * @since 1.0.4
         */
        global SObjectMaker(Schema.SObjectType type) {
            this.type = type;

            this.autoInsert = true;
            this.name = String.valueOf(type);
        }

        /**
         * @see #make(Map<Schema.SObjectField, Object>) make
         * @since 1.0.4
         */
        global List<SObject> make() {
            return make(new Map<Schema.SObjectField, Object>());
        }

        /**
         * It generates all the <code>SObject</code> records according to the currently set options.
         * By default the records will be automatically inserted. To prevent this behaviour disable
         * auto-insert.
         * <p>
         * The <code>Name</code> field for records generated will be generate on the basis of
         * the <code>SObjectType</code> followed by the consecutive number of the number of records
         * generated.
         *
         * @param values custom fixed field values
         * @return the <code>SObject</code> records generated
         * @see #setAutoInsert(Boolean) setAutoInsert
         * @see #setCount(Boolean) setCount
         * @see #setName(Boolean) setName
         * @since 1.0.5
         */
        global List<SObject> make(Map<Schema.SObjectField, Object> values) {
            List<SObject> records = new List<SObject>();

            for (Integer i = 0; i < count; i++) {
                records.add(makeOne(i, values));
            }

            if (autoInsert) {
                insert records;
            }

            return records;
        }

        virtual SObject makeOne(Integer index, Map<Schema.SObjectField, Object> values) {
            SObject instance = type.newSObject();

            for (Schema.SObjectField field : values.keySet()) {
                instance.put(field, values.get(field));
            }

            return instance;
        }

        /**
         * It sets the auto-insert options that controls whether the <code>make()</code> method
         * will insert the records or not.
         *
         * @param value the toggle
         * @return the maker instance
         * @since 1.0.4
         */
        global SObjectMaker setAutoInsert(Boolean value) {
            autoInsert = value;
            return this;
        }

        /**
         * It sets the number of records the <code>make()</code> method will create.
         *
         * @param value the count
         * @return the maker instance
         * @since 1.0.4
         */
        global SObjectMaker setCount(Integer value) {
            count = value;
            return this;
        }

        /**
         * It sets the value that will be used to fill out the <code>Name</code> field,
         * along with the consecutive number according to the count set,
         * once the <code>make()</code> is invoked.
         *
         * @param value the count
         * @return the maker instance
         * @since 1.0.4
         */
        global SObjectMaker setName(String value) {
            name = value;
            return this;
        }

        /**
         * It sets the <code>OwnerId</code> field for any record that will be generated
         * by the <code>make()</code> method.
         *
         * @param value the count
         * @return the maker instance
         * @since 1.0.4
         */
        global SObjectMaker setOwnerId(Id value) {
            ownerId = value;
            return this;
        }
    }

    global class AccountMaker extends SObjectMaker {
        global AccountMaker() {
            super(Schema.Account.SObjectType);
        }

        override SObject makeOne(Integer index, Map<Schema.SObjectField, Object> values) {
            Schema.Account obj = (Schema.Account) super.makeOne(index, values);
            obj.Name = name + index;
            return obj;
        }
    }

    global class ContactMaker extends SObjectMaker {
        private String firstName;

        global ContactMaker() {
            super(Schema.Contact.SObjectType);
        }

        override SObject makeOne(Integer index, Map<Schema.SObjectField, Object> values) {
            Schema.Contact obj = (Schema.Contact) super.makeOne(index, values);
            obj.FirstName = firstName;
            obj.LastName = name + index;
            return obj;
        }

        global ContactMaker setFirstName(String value) {
            firstName = value;
            return this;
        }

        global ContactMaker setLastName(String value) {
            setName(value);
            return this;
        }
    }

    global class EventMaker extends SObjectMaker {
        private Id whatId;
        private Id whoId;

        global EventMaker() {
            super(Schema.Event.SObjectType);
        }

        override SObject makeOne(Integer index, Map<Schema.SObjectField, Object> values) {
            Schema.Event obj = (Schema.Event) super.makeOne(index, values);
            obj.StartDateTime = Datetime.now().addDays(index);
            obj.EndDateTime = obj.StartDateTime.addHours(1);
            obj.Subject = name + index;
            obj.WhatId = whatId;
            obj.WhoId = whoId;
            return obj;
        }

        global EventMaker setWhatId(Id value) {
            whatId = value;
            return this;
        }

        global EventMaker setWhoId(Id value) {
            whoId = value;
            return this;
        }
    }

    global class UserMaker extends SObjectMaker {
        private String firstName;
        private Id profileId;
        private String randomain;

        global UserMaker() {
            super(Schema.User.SObjectType);

            randomain = new Utils.RandomizerBuilder()
                .setLength(8)
                .setPreferences(
                    new Set<Utils.RandomizerPreference>{
                        Utils.RandomizerPreference.INCLUDE_LETTER,
                        Utils.RandomizerPreference.INCLUDE_NUMBER
                    }
                )
                .build()
                .generate();
        }

        override SObject makeOne(Integer index, Map<Schema.SObjectField, Object> values) {
            Schema.User obj = (Schema.User) super.makeOne(index, values);
            obj.EmailEncodingKey = 'UTF-8';
            obj.FirstName = firstName;
            obj.LanguageLocaleKey = 'en_US';
            obj.LastName = name + index;
            obj.TimeZoneSidKey = 'Europe/Rome';
            
            obj.Alias = obj.LastName.toLowerCase().right(8);
            obj.Email = obj.LastName.toLowerCase() + '@' + randomain + '.rnd';
            obj.LocaleSidKey = obj.LanguageLocaleKey;
            obj.ProfileId = profileId;

            obj.Username = obj.Email;
            obj.CommunityNickname = obj.Alias + '.' + randomain;
            return obj;
        }

        global UserMaker setFirstName(String value) {
            firstName = value;
            return this;
        }

        global UserMaker setProfileId(String value) {
            profileId = value;
            return this;
        }
    }

    /**
     * It assigns the user the permission set provided.
     *
     * @param name the user id
     * @return the permission set name
     * @since 1.0.9
     */
    global static void assignPermission(String name, Id userId) {
        Schema.PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :name];

        insert new Schema.PermissionSetAssignment(AssigneeId = opUser.id, PermissionSetId = ps.Id);
    }

    /**
     * It returns the profile id of the profile name provided.
     *
     * @param name the profile name
     * @return the profile id
     * @since 1.0.4
     */
    global static Id getProfileId(String name) {
        return getProfileIds(new Set<String>{ name }).get(name);
    }

    /**
     * It returns a map of profile names and respective ids for the names provided.
     *
     * @param names the profile names
     * @return the map with names and ids
     * @since 1.0.4
     */
    global static Map<String, Id> getProfileIds(Set<String> names) {
        Map<String, Id> profiles = new Map<String, Id>();

        for (Schema.Profile record : [SELECT Id, Name FROM Profile WHERE Name IN :names]) {
            profiles.put(record.Name, record.Id);
        }

        return profiles;
    }

    /**
     * It returns the current user <code>User</code> SObject exclusively containing the record id.
     * <p>
     * This method can be useful when running <code>System.runAs()</code>.
     *
     * @return the <code>User</code> SObject
     * @see #getUser(Id) getUser
     * @since 1.0.4
     */
    global static Schema.User getUser() {
        return getUser(UserInfo.getUserId());
    }

    /**
     * @param value the user id
     * @return the <code>User</code> SObject
     * @see #getUser() getUser
     * @since 1.0.4
     */
    global static Schema.User getUser(Id value) {
        return [SELECT Id FROM User WHERE Id = :value];
    }
}
