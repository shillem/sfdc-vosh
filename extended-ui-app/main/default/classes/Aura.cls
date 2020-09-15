global with sharing class Aura {

    @AuraEnabled(cacheable=true)
    global static String getFieldLabel(String pointer) {
        Utils.Describer describ = Utils.getDescriber();

        return describ.getFieldDescribe(describ.fieldValueOf(pointer)).getLabel();
    }

    @AuraEnabled(cacheable=true)
    global static String getSObjectLabel(String name) {
        Utils.Describer describ = Utils.getDescriber();

        return describ.getObjectDescribe(name).getLabel();
    }

}
