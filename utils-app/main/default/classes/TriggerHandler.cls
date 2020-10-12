global inherited sharing class TriggerHandler {
    /**
     * The abstract class to create a SObject trigger logic from.
     * The class provides methods that will be be invoked depending on the trigger's operation type.
     * Any of those methods can be overridden by the extending class to implement the needed logic.
     * <p>
     * This class is meant to be used exclusively in the <code>Trigger</code> context because
     * it relies on its <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_context_variables.htm">specific variables</a>.
     *
     * @see TriggerHandler#enable(System.Type) enable
     * @since 1.0.1
     */
    global abstract class Routine {
        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>AFTER_DELETE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void afterDelete(SObject record) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>AFTER_DELETE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void afterInsert(SObject record) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>AFTER_UNDELETE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void afterUndelete(SObject record) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>AFTER_UPDATE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void afterUpdate(SObject stored, SObject memory) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>BEFORE_DELETE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void beforeDelete(SObject record) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>BEFORE_INSERT</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void beforeInsert(SObject record) {
        }

        /**
         * It can be overridden to performs operations on the record passed
         * when the trigger operation is <code>BEFORE_UPDATE</code>.
         * 
         * @param record the record passed by the trigger
         * @since 1.0.1
         */
        global virtual void beforeUpdate(SObject stored, SObject memory) {
        }

        /**
         * It executes the implemented logic on the records passed
         * in the <code>Trigger</code> context.
         * 
         * @since 1.0.1
         */
        global void execute() {
            pre();

            switch on Trigger.operationType {
                when BEFORE_INSERT {
                    for (SObject record : Trigger.new) {
                        beforeInsert(record);
                    }
                }
                when BEFORE_UPDATE {
                    for (SObject record : Trigger.old) {
                        beforeUpdate(record, Trigger.newMap.get(record.Id));
                    }
                }
                when BEFORE_DELETE {
                    for (SObject record : Trigger.old) {
                        beforeDelete(record);
                    }
                }
                when AFTER_INSERT {
                    for (SObject record : Trigger.new) {
                        afterInsert(record);
                    }
                }
                when AFTER_UPDATE {
                    for (SObject record : Trigger.old) {
                        afterUpdate(record, Trigger.newMap.get(record.Id));
                    }
                }
                when AFTER_DELETE {
                    for (SObject record : Trigger.old) {
                        afterDelete(record);
                    }
                }
                when AFTER_UNDELETE {
                    for (SObject record : Trigger.new) {
                        afterUndelete(record);
                    }
                }
            }

            post();
        }

        /**
         * It must be overridden to state the <code>SObject</code> type the trigger logic handles.
         * 
         * @return the <code>SObject</code> type
         * @since 1.0.1
         */
        global abstract Schema.SObjectType getSObjectType();

        /**
         * It returns a set of record ids that have been tagged under the given key.
         * 
         * @param key an arbitrary key string
         * @return the set containing the tagged ids
         * @see #isTagged(Id, String) isTagged
         * @see #tag(Id, String) tag
         * @since 1.0.7
         */
        global Set<Id> getTags(String key) {
            Set<Id> values = TAGS.get(key);

            if (values == null) {
                values = new Set<Id>();

                TAGS.put(key, values);
            }

            return values;
        }

        /**
         * It checks whether a given record id has been tagged.
         * <p>
         * Trigger logic can be tricky to write. A trigger might be invoked multiple times
         * on the same record depending on what the implementing class or other triggers do.
         * To prevent a trigger to be run on a previously processed record it's possible to tag said
         * record id and later check for its presence in order to skip reprocessing it.
         * 
         * @param recordId the record id to check
         * @param key an arbitrary key string to file the id under
         * @return true if the record is tagged, otherwise false
         * @see #tag(Id, String) tag
         * @see #untag(Id, String) tag
         * @since 1.0.3
         */
        global Boolean isTagged(Id recordId, String key) {
            return getTags(key).contains(recordId);
        }

        /**
         * It can be overridden to execute arbitrary logic
         * before the <code>Trigger</code> record looping takes place.
         * 
         * @since 1.0.1
         */
        global virtual void pre() {
        }

        /**
         * It can be overridden to execute arbitrary logic
         * after the <code>Trigger</code> record has taken place.
         * 
         * @since 1.0.1
         */
        global virtual void post() {
        }

        /**
         * It tags a given record id.
         * 
         * @param recordId the record id to check
         * @param key an arbitrary key string to file the id under
         * @see #isTagged(Id, String) isTagged
         * @see #tag(Id, String) tag
         * @since 1.0.3
         */
        global void tag(Id recordId, String key) {
            getTags(key).add(recordId);
        }

        /**
         * It untags a given record id.
         * 
         * @param recordId the record id to check
         * @param key an arbitrary key string to file the id under
         * @see #isTagged(Id, String) isTagged
         * @see #untag(Id, String) untag
         * @since 1.0.3
         */
        global void untag(Id recordId, String key) {
            getTags(key).remove(recordId);
        }
    }

    private static final Map<String, Set<Id>> TAGS = new Map<String, Set<Id>>();

    /**
     * Invokes any <code>TriggerHandler.Routine</code> extending classes that have been enabled,
     * for the SObject. The enabled classes will be retrieved by querying
     * all the <code>Cs_TriggerHandlerRoutine__c</code> custom setting records
     * that match the SObject type parameter.
     *
     * @param stype the <code>SObjectType</code> that will be used collect all the <code>TriggerHandler.Routine</code>, not null
     * @see #enable(System.Type) enable
     * @since 1.0.3
     */
    global static void execute(Schema.SObjectType stype) {
        Utils.requireNonNull(stype, 'Type cannot be null');

        List<Schema.Cs_TriggerHandlerRoutine__c> routines = [
            SELECT ClassName__c
            FROM Cs_TriggerHandlerRoutine__c
            WHERE SObjectType__c = :String.valueOf(stype)
            ORDER BY Sort_Order__c, ClassName__c
        ];

        for (Schema.Cs_TriggerHandlerRoutine__c rtn : routines) {
            System.Type rtype = System.Type.forName(rtn.ClassName__c);

            if (rtype == null || !Routine.class.isAssignableFrom(rtype)) {
                continue;
            }

            ((Routine) rtype.newInstance()).execute();
        }
    }

    /**
     * Disables a <code>TriggerHandler.Routine</code> extending class that,
     * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
     * The method ticks as disabled a corresponding <code>Cs_TriggerHandlerRoutine__c</code>
     * custom setting record that bears the class' name if it exists.
     *
     * @param stype the .class extending the abstract class <code>TriggerHandler.Routine</code>, not null
     * @see #enable(System.Type) enable
     * @since 1.0.3
     */
    global static void disable(System.Type stype) {
        Utils.requireNonNull(stype, 'Type cannot be null');

        Schema.Cs_TriggerHandlerRoutine__c definition = Schema.Cs_TriggerHandlerRoutine__c.getValues(
            new Utils.Hasher().hash(stype.getName())
        );

        if (definition == null || definition.Is_Disabled__c) {
            return;
        }

        definition.Is_Disabled__c = true;

        update definition;
    }

    /**
     * Enables a <code>TriggerHandler.Routine</code> extending class that,
     * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
     * The coupling trigger will have to call <code>TriggerHandler.execute</code>
     * for the class to be invoked.
     * <p>
     * The method creates - if it doesn't exist, or ticks as enabled, a corresponding
     * <code>Cs_TriggerHandlerRoutine__c</code> custom setting record that bears the class' name.
     *
     * @param stype the .class extending the abstract class <code>TriggerHandler.Routine</code>, not null
     * @throws UnsupportedOperationException if the type doesn't extend <code>TriggerHandler.Routine</code>
     * @see #execute(Schema.SObjectType) execute
     * @since 1.0.3
     */
    global static void enable(System.Type stype) {
        Utils.requireNonNull(stype, 'Type cannot be null');

        String sname = stype.getName();
        String snameHashed = new Utils.Hasher().hash(sname);

        if (!Routine.class.isAssignableFrom(stype)) {
            throw new UnsupportedOperationException(
                'Cannot enable ' +
                sname +
                ' because it does not extend TriggerHandler.Routine class'
            );
        }

        Schema.Cs_TriggerHandlerRoutine__c definition = Schema.Cs_TriggerHandlerRoutine__c.getValues(
            snameHashed
        );

        if (definition == null) {
            definition = new Schema.Cs_TriggerHandlerRoutine__c(
                Name = snameHashed,
                ClassName__c = sname,
                SObjectType__c = String.valueOf(((Routine) stype.newInstance()).getSObjectType())
            );
        } else if (!definition.Is_Disabled__c) {
            return;
        }

        definition.Is_Disabled__c = false;

        upsert definition;
    }
}
