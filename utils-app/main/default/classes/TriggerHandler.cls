global class TriggerHandler {
    global enum Recursion {
        DISABLED,
        ENABLED
    }

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

        global virtual Recursion getRecursion() {
            return Recursion.DISABLED;
        }

        private String identifier() {
            return Utils.getClassName(this) + '_' + Trigger.operationType.name();
        }

        global Boolean isReexecuting() {
            return EXECUTIONS.contains(identifier());
        }

        global virtual void pre() {
        }

        global virtual void post() {
        }

        global void execute() {
            if (Recursion.DISABLED == getRecursion() && isReexecuting()) {
                return;
            }

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

            EXECUTIONS.add(identifier());
        }

        global abstract Schema.SObjectType getSObjectType();
    }

    private static final Set<String> EXECUTIONS = new Set<String>();

    global static void execute(Schema.SObjectType stype) {
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
