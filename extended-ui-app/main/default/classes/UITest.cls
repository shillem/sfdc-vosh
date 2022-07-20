@isTest(isParallel=true)
public class UITest {
    @isTest
    static void field() {
        // Simple
        UI.Field uiField = new UI.Field('Name', 'System.Label', DisplayType.STRING.name());

        System.assertEquals(uiField.getName(), 'Name');
        System.assertEquals(uiField.getLabel(), 'System.Label');
        System.assertEquals(uiField.getType(), DisplayType.STRING.name());

        UI.Field picklistUiField = new UI.Field(
                'Fruits',
                'What fruit?',
                DisplayType.PICKLIST.name()
            )
            .addOption(new Utils.Entry('Strawberry', 'Strawberry'))
            .addOption(new Utils.Entry('Banana', 'Banana'))
            .addOptions(
                new Set<Utils.Entry>{
                    new Utils.Entry('Apple', 'Apple'),
                    new Utils.Entry('Banana', 'Banana split'),
                    new Utils.Entry('Pineapple', 'Pineapple')
                }
            )
            .setRequired(true);

        // Banana split should be ignored because an exact other value is already present
        System.assertEquals(4, picklistUiField.getOptions().size());
        System.assertEquals(true, picklistUiField.isRequired());
        System.assertEquals(
            'Strawberry',
            picklistUiField.getOptions().iterator().next().getValue()
        );

        // Option sorting
        picklistUiField.sortOptions();
        System.assertEquals('Apple', picklistUiField.getOptions().iterator().next().getValue());

        // Other options
        UI.Field frankUiField = new UI.Field(
                'Frankeinstein',
                'Frankeinstein',
                DisplayType.STRING.name()
            )
            .setReadOnly(true)
            .setValue('Argh');

        System.assertEquals(true, frankUiField.isReadonly());
        System.assertEquals('Argh', frankUiField.getValue());
    }

    @isTest
    static void fieldSObject() {
        SObjectField field = Schema.Account.Type;
        Schema.DescribeFieldResult result = Describer.getInstance().getFieldDescribe(field);
        UI.FieldSObject uiField = new UI.FieldSObject(field);

        // Testing basic options
        System.assertEquals(uiField.getName(), result.getName());
        System.assertEquals(uiField.getLabel(), result.getLabel());
        System.assertEquals(uiField.getHelp(), result.getInlineHelpText());
        System.assertEquals(uiField.getType(), result.getType().name());
        System.assertEquals(uiField.isRequired(), !result.isNillable());

        // Testing picklist options
        uiField.addPicklistOptions();
        System.assert(uiField.getOptions() != null, 'The field should be a picklist field');
        System.assertEquals(uiField.getOptions().size(), result.getPicklistValues().size());
    }

    @isTest
    static void listboxItem() {
        List<UI.ListboxItem> results = new List<UI.ListboxItem>{
            new UI.ListboxItem('value-only'),
            new UI.ListboxItem('value', 'label'),
            new UI.ListboxItem('sport', 'Sport').setIcon('ball').setMeta('basket').setDisabled(true)
        };

        System.assertEquals('value-only', results[0].getLabel());
        System.assertEquals('value-only', results[0].getValue());

        System.assertEquals('label', results[1].getLabel());
        System.assertEquals('value', results[1].getValue());

        System.assertEquals('Sport', results[2].getLabel());
        System.assertEquals('ball', results[2].getIcon());
        System.assertEquals('basket', results[2].getMeta());
        System.assertEquals(true, results[2].getDisabled());

        results.sort();

        System.assertEquals('Sport', results[0].getLabel());
        System.assertEquals('label', results[1].getLabel());
        System.assertEquals('value-only', results[2].getLabel());
    }

    @isTest
    static void sObjectDescriptor() {
        Schema.SObjectType type = Schema.Account.SObjectType;
        UI.SObjectDescriptor descriptor = new UI.SObjectDescriptor(type);

        System.assertEquals(type.getDescribe().getLabel(), descriptor.getLabel());
        System.assertEquals(String.valueOf(type), descriptor.getName());
        System.assert(descriptor.getField('Name') != null);
        System.assertEquals(DisplayType.STRING.name(), descriptor.getField('Name').getType());
        System.assert(!descriptor.getFieldMap().isEmpty(), 'Field map should not have been empty');

        // Testing filter
        descriptor = new UI.SObjectDescriptor(
            type,
            new Set<Schema.SObjectField>{ Account.NumberOfEmployees, Account.Name }
        );

        System.assertEquals(2, descriptor.getFieldMap().size());

        // Testing record values loading
        Schema.Account acct = new Schema.Account(Name = 'Dummy');

        descriptor.setValues(acct);

        System.assertEquals(acct.Name, descriptor.getField(Schema.Account.Name).getValue());

    }
}
