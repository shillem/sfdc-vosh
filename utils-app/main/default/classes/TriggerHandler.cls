global class TriggerHandler {

    global abstract class Routine {
        global virtual void afterDelete(SObject record) {
        }

        global virtual void afterInsert(SObject record) {
        }

        global virtual void afterUndelete(SObject record) {
        }

        global virtual void afterUpdate(SObject stored, SObject memory) {
        }

        global virtual void beforeDelete(SObject record) {
        }

        global virtual void beforeInsert(SObject record) {
        }

        global virtual void beforeUpdate(SObject stored, SObject memory) {
        }

        global virtual void pre() {
        }

        global virtual void post() {
        }

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

        global abstract Schema.SObjectType getSObjectType();
    }

    global static void execute(Schema.SObjectType stype) {
        List<Schema.Cs_TriggerHandlerRoutine__c> routines = [
            SELECT Name
            FROM Cs_TriggerHandlerRoutine__c
            WHERE SObjectType__c = :String.valueOf(stype)
            ORDER BY Sort_Order__c, Name
        ];

        for (Schema.Cs_TriggerHandlerRoutine__c rtn : routines) {
            System.Type rtype = System.Type.forName(rtn.Name);

            if (rtype == null || !Routine.class.isAssignableFrom(rtype)) {
                continue;
            }

            ((Routine) rtype.newInstance()).execute();
        }
    }

    global static void disable(System.Type stype) {
        Utils.requireNonNull(stype, 'Type cannot be null');

        Schema.Cs_TriggerHandlerRoutine__c definition = Schema.Cs_TriggerHandlerRoutine__c.getValues(
            stype.getName()
        );

        if (definition == null || definition.Is_Disabled__c) {
            return;
        }

        definition.Is_Disabled__c = true;

        update definition;
    }

    global static void enable(System.Type stype) {
        Utils.requireNonNull(stype, 'Type cannot be null');

        if (!Routine.class.isAssignableFrom(stype)) {
            throw new UnsupportedOperationException(
                'Cannot enable ' +
                stype.getName() +
                ' because it does not extend TriggerHandler.Routine class'
            );
        }

        Schema.Cs_TriggerHandlerRoutine__c definition = Schema.Cs_TriggerHandlerRoutine__c.getValues(
            stype.getName()
        );

        if (definition == null) {
            definition = new Schema.Cs_TriggerHandlerRoutine__c(
                Name = stype.getName(),
                SObjectType__c = String.valueOf(((Routine) stype.newInstance()).getSObjectType())
            );
        } else if (!definition.Is_Disabled__c) {
            return;
        }

        definition.Is_Disabled__c = false;

        upsert definition;
    }
}
