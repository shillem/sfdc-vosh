global with sharing class Aura {

    @AuraEnabled(cacheable=true)
    global static String getFieldLabel(String pointer) {
        Describer describ = Describer.getInstance();

        return describ.getFieldDescribe(describ.fieldValueOf(pointer)).getLabel();
    }

    @AuraEnabled(cacheable=true)
    global static String getSObjectLabel(String name) {
        Describer describ = Describer.getInstance();

        return describ.getObjectDescribe(name).getLabel();
    }

}
