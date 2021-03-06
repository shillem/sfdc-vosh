/**
 * An object that builds <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dynamic_soql.htm">dynamic SOQLs</a>.
 * <p>
 * The objects provides helper methods that execute the query or its COUNT() counterpart.
 * It can also simply return the both queries as strings to be further inspected or used.
 * <p>
 * It supports variable binding but cannot overcome the Salesforce impositions in that regard.
 * field-level-security is also honored and can be used in 2 ways:
 * either by throwing an exception or by dropping those fields that are inaccessible from the query.
 *
 * @since 1.0.4
 */
global inherited sharing class Soqler {
    private abstract class A {
        void requireNonNull(Object obj, String message) {
            Utils.requireNonNull(
                obj,
                String.format('[{0}]: {1}', new List<String>{ Utils.getClassName(this), message })
            );
        }

        void throwUnsupported(String message) {
            throw new UnsupportedOperationException(
                String.format('[{0}]: {1}', new List<String>{ Utils.getClassName(this), message })
            );
        }

        abstract String build();
    }

    private virtual class Converter {
        virtual String convertName(String value) {
            return value;
        }

        virtual String convertValue(Object value) {
            return String.valueOf(value);
        }

        String convertValues(List<Object> values) {
            Iterator<Object> iter = values.iterator();
            Boolean hasNext = iter.hasNext();

            String result = '(';

            while (hasNext) {
                Object value = iter.next();
                hasNext = iter.hasNext();
                result += convertValue(value) + (hasNext ? ',' : ')');
            }

            return result;
        }
    }

    private class ConverterDateTime extends Converter {
        override String convertValue(Object value) {
            return JSON.serialize(value).removeStart('"').removeEnd('"');
        }
    }

    private class ConverterDateTimeDate extends Converter {
        override String convertName(String value) {
            return 'DAY_ONLY(' + value + ')';
        }

        override String convertValue(Object value) {
            return JSON.serialize(((Datetime) value).dateGmt()).removeStart('"').removeEnd('"');
        }
    }

    private class ConverterString extends Converter {
        override String convertValue(Object value) {
            return '\'' + String.escapeSingleQuotes((String) value) + '\'';
        }
    }

    private abstract class F extends A {
        private final Schema.SObjectField field;
        private final String crossReference;

        F(Schema.SObjectField field) {
            this(null, field);
        }

        F(String crossReference, Schema.SObjectField field) {
            requireNonNull(field, 'Field cannot be null');

            this.field = field;
            this.crossReference = crossReference;
        }

        virtual override String build() {
            return (crossReference != null ? crossReference + '.' : '') + String.valueOf(field);
        }
    }

    private interface I {
    }

    global interface IField extends I {
    }

    global class IFieldName extends F implements IField {
        private final Boolean droppable;

        global IFieldName(Schema.SObjectField field) {
            this(field, false);
        }

        global IFieldName(Schema.SObjectField field, Boolean droppable) {
            this(null, field, droppable);
        }

        global IFieldName(String crossReference, Schema.SObjectField field) {
            this(crossReference, field, false);
        }

        global IFieldName(String crossReference, Schema.SObjectField field, Boolean droppable) {
            super(crossReference, field);

            requireNonNull(droppable, 'Droppable cannot be null');

            this.droppable = droppable;
        }

        override String build() {
            return Fls.audit(field, System.AccessType.READABLE, !droppable) ? super.build() : null;
        }
    }

    private class IFieldQuery extends A implements IField {
        private final Soqler instance;

        IFieldQuery(Soqler query, Schema.SObjectType superType) {
            instance = query.setAsSubquery(
                Utils.getDescriber().getObjectRelationshipName(superType, query.getType())
            );
        }

        override String build() {
            return '(' + instance.build() + ')';
        }
    }

    global class IFieldTypeOf extends A implements IField {
        private final String name;
        private final Map<Schema.SObjectType, Map<Schema.SObjectField, Boolean>> cases;

        global IFieldTypeOf(String name) {
            requireNonNull(name, 'Name cannot be null');

            this.name = name;
            this.cases = new Map<Schema.SObjectType, Map<Schema.SObjectField, Boolean>>();
        }

        global IFieldTypeOf when(Schema.SObjectType type, Set<Schema.SObjectField> fields) {
            requireNonNull(type, 'Type cannot be null');

            if (fields == null || fields.isEmpty()) {
                throwUnsupported('There must be at least one field set');
            }

            Map<Schema.SObjectField, Boolean> cases = new Map<Schema.SObjectField, Boolean>();

            for (Schema.SObjectField field : fields) {
                cases.put(field, false);
            }

            this.cases.put(type, cases);

            return this;
        }

        global IFieldTypeOf when(
            Schema.SObjectType type,
            Map<Schema.SObjectField, Boolean> fields
        ) {
            requireNonNull(type, 'Type cannot be null');

            if (fields == null || fields.isEmpty()) {
                throwUnsupported('There must be at least one field set');
            }

            cases.put(type, fields);

            return this;
        }

        override String build() {
            String value = '';

            for (Schema.SObjectType type : cases.keySet()) {
                String partial = build(cases.get(type));

                if (partial != null) {
                    value += ' WHEN ' + type + ' THEN ' + partial;
                }
            }

            return value.length() > 0 ? 'TYPEOF ' + name + value + ' ELSE Id END' : null;
        }

        private String build(Map<Schema.SObjectField, Boolean> fields) {
            String value = '';
            String separator = ', ';

            for (Schema.SObjectField field : fields.keySet()) {
                if (Fls.audit(field, System.AccessType.READABLE, !fields.get(field))) {
                    value += field + separator;
                }
            }

            return value.length() > 0 ? value.removeEnd(separator) : null;
        }
    }

    global interface IOrder extends I {
    }

    global class IOrderLocation extends F implements IOrder {
        private final Decimal lat;
        private final Decimal lng;
        private final Boolean descendingOrder;

        global IOrderLocation(Schema.SObjectField field, Decimal lat, Decimal lng) {
            this(field, lat, lng, false);
        }

        global IOrderLocation(
            Schema.SObjectField field,
            Decimal lat,
            Decimal lng,
            Boolean descendingOrder
        ) {
            this(null, field, lat, lng, descendingOrder);
        }

        global IOrderLocation(
            String crossReference,
            Schema.SObjectField field,
            Decimal lat,
            Decimal lng
        ) {
            this(crossReference, field, lat, lng, false);
        }

        global IOrderLocation(
            String crossReference,
            Schema.SObjectField field,
            Decimal lat,
            Decimal lng,
            Boolean descendingOrder
        ) {
            super(crossReference, field);

            requireNonNull(lat, 'Latitude cannot be null');
            requireNonNull(lng, 'Longitude cannot be null');
            requireNonNull(descendingOrder, 'Descending order cannot be null');

            this.lat = lat;
            this.lng = lng;
            this.descendingOrder = descendingOrder;
        }

        override String build() {
            return String.format(
                'DISTANCE({0}, GEOLOCATION({1}, {2}), \'\'km\'\'){3}',
                new List<Object>{ super.build(), lat, lng, descendingOrder ? ' DESC' : '' }
            );
        }
    }

    global class IOrderName extends F implements IOrder {
        private final Boolean descendingOrder;

        global IOrderName(Schema.SObjectField field) {
            this(field, false);
        }

        global IOrderName(Schema.SObjectField field, Boolean descendingOrder) {
            this(null, field, descendingOrder);
        }

        global IOrderName(String crossReference, Schema.SObjectField field) {
            this(crossReference, field, false);
        }

        global IOrderName(
            String crossReference,
            Schema.SObjectField field,
            Boolean descendingOrder
        ) {
            super(crossReference, field);

            requireNonNull(descendingOrder, 'Descending order cannot be null');

            this.descendingOrder = descendingOrder;
        }

        override String build() {
            return super.build() + (descendingOrder ? ' DESC' : '');
        }
    }

    global interface IWhere extends I {
    }

    global class IWhereGroup extends A implements IWhere {
        private final LWhere whrs;

        global IWhereGroup() {
            whrs = new LWhere();
        }

        override String build() {
            return '(' + whrs.build() + ')';
        }

        global LWhere wheres() {
            return whrs;
        }
    }

    global class IWhereLocation extends F implements IWhere {
        private final Decimal lat;
        private final Decimal lng;
        private final Decimal kmRadius;
        private final String co;

        global IWhereLocation(
            Schema.SObjectField field,
            Decimal lat,
            Decimal lng,
            String co,
            Decimal kmRadius
        ) {
            this(null, field, lat, lng, co, kmRadius);
        }

        global IWhereLocation(
            String crossReference,
            Schema.SObjectField field,
            Decimal lat,
            Decimal lng,
            String co,
            Decimal kmRadius
        ) {
            super(crossReference, field);

            requireNonNull(lat, 'Latitude cannot be null');
            requireNonNull(lng, 'Longitude cannot be null');
            requireNonNull(co, 'Comparison operator cannot be null');
            requireNonNull(kmRadius, 'Km radius cannot be null');

            this.co = co.trim();

            switch on (this.co) {
                when '<', '>' {
                    // Supported
                }
                when else {
                    throwUnsupported(this.co + ' comparison operator is not supported');
                }
            }

            this.lat = lat;
            this.lng = lng;
            this.kmRadius = kmRadius;
        }

        override String build() {
            return String.format(
                'DISTANCE({0}, GEOLOCATION({1}, {2}), \'\'km\'\') {3} {4}',
                new List<Object>{ super.build(), lat, lng, co, kmRadius }
            );
        }
    }

    private class IWhereLogic extends A implements IWhere {
        private final String name;

        IWhereLogic(String name) {
            this.name = name;
        }

        override String build() {
            return ' ' + name + ' ';
        }
    }

    global class IWhereName extends F implements IWhere {
        private final String co;
        private final Object value;

        global IWhereName(Schema.SObjectField field, String co, Object value) {
            this(null, field, co, value);
        }

        global IWhereName(
            String crossReference,
            Schema.SObjectField field,
            String co,
            Object value
        ) {
            super(crossReference, field);

            requireNonNull(co, 'Comparison operator cannot be null');

            this.co = co.trim();

            switch on (this.co) {
                when '<', '<=', '=', '>=', '>', '!=' {
                    if (value instanceof List<Object>) {
                        throwUnsupported(this.co + ' comparison operator is not supported');
                    }
                }
                when 'IN', 'NOT IN' {
                    if (!(value instanceof List<Object>)) {
                        throwUnsupported(
                            'Either ' +
                            this.co +
                            ' is not a valid comparison operator or,' +
                            ' if the provided value was a Set<?>, it must be wrapped with List<?>'
                        );
                    } else if (((List<Object>) value).isEmpty()) {
                        throwUnsupported('There must be at least one value for ' + field);
                    }
                }
                when 'LIKE' {
                    if (!(value instanceof String)) {
                        throwUnsupported(this.co + ' comparison operator is not supported');
                    }
                }
                when else {
                    throwUnsupported(this.co + ' comparison operator is not supported');
                }
            }

            this.value = value;
        }

        override String build() {
            Converter cvt;
            String stringValue;

            if (value instanceof List<Object>) {
                List<Object> values = (List<Object>) value;
                cvt = getValueConverter(field, values[0]);
                stringValue = cvt.convertValues(values);
            } else {
                cvt = getValueConverter(field, value);
                stringValue = cvt.convertValue(value);
            }

            return cvt.convertName(super.build()) + ' ' + co + ' ' + stringValue;
        }
    }

    private class IWhereQuery extends F implements IWhere {
        private final Soqler instance;

        IWhereQuery(Schema.SObjectField field, Soqler query) {
            this(null, field, query);
        }

        IWhereQuery(String crossReference, Schema.SObjectField field, Soqler query) {
            super(crossReference, field);

            instance = query.setAsSubquery(null);
        }

        override String build() {
            return super.build() + ' IN (' + instance.build() + ')';
        }
    }

    global class IWhereTypeOf extends A implements IWhere {
        private final String name;
        private final String co;
        private final Set<Schema.SObjectType> types;

        global IWhereTypeOf(String name, String co, Set<Schema.SObjectType> types) {
            requireNonNull(name, 'Name cannot be null');
            requireNonNull(co, 'Comparison operator cannot be null');

            this.co = co.trim();

            switch on (this.co) {
                when 'IN', 'NOT IN' {
                    // It's good
                }
                when else {
                    throwUnsupported(this.co + ' comparison operator is not supported');
                }
            }

            if (types == null || types.isEmpty()) {
                throwUnsupported('There must be at least one type set for ' + name);
            }

            this.name = name;
            this.types = types;
        }

        override String build() {
            String value = '';
            String separator = ', ';

            for (Schema.SObjectType type : types) {
                value += '\'' + type + '\'' + separator;
            }

            return name + '.Type' + ' ' + co + ' ' + '(' + value.removeEnd(separator) + ')';
        }
    }

    global class IWhereVariable extends F implements IWhere {
        private final String co;
        private final String variable;

        global IWhereVariable(Schema.SObjectField field, String co, String variable) {
            this(null, field, co, variable);
        }

        global IWhereVariable(
            String crossReference,
            Schema.SObjectField field,
            String co,
            String variable
        ) {
            super(crossReference, field);

            requireNonNull(co, 'Comparison operator cannot be null');
            requireNonNull(variable, 'Variable cannot be null');

            this.co = co;
            this.variable = variable;
        }

        override String build() {
            return super.build() + ' ' + co + ' ' + ':' + variable;
        }
    }

    private abstract class L extends A {
        final List<I> instructions;

        L() {
            instructions = new List<I>();
        }

        override String build() {
            String value = '';
            String separator = getSeparator();

            for (I instruction : instructions) {
                String partial = ((A) instruction).build();

                if (partial != null) {
                    value += partial + separator;
                }
            }

            return value.length() > 0 ? value.removeEnd(separator) : null;
        }

        virtual String getSeparator() {
            return ', ';
        }
    }

    /**
     * It represents the object holding the list of instructions
     * that will compose the SELECT part of the query.
     *
     * @since 1.0.4
     */
    global class LField extends L {
        private final Soqler query;

        LField(Soqler query) {
            super();

            this.query = query;
        }

        /**
         * It adds a SELECT instruction to the list.
         *
         * @param instruction the instruction to be added to the list, not null
         * @return this SELECT field list instance
         * @see Soqler.IField
         * @since 1.0.4
         */
        global LField add(IField instruction) {
            requireNonNull(instruction, 'Instruction cannot be null');

            instructions.add(instruction);

            return this;
        }

        /**
         * It adds a dynamic SOQL as <code>IFieldQuery</code> subquery
         * to the SELECT instruction list.
         *
         * @param subquery the query, not null
         * @return this SELECT field list instance
         * @see Soqler.IFieldQuery
         * @since 1.0.4
         */
        global LField add(Soqler subquery) {
            requireNonNull(subquery, 'Subquery cannot be null');

            add(new IFieldQuery(subquery, query.getType()));

            return this;
        }

        /**
         * It adds a <code>IFieldName</code> SELECT instruction
         * based on <code>Schema.SObjectField</code> to the list.
         * <p>
         * When the query will be built, or run, the field will be checked
         * for field-level-security and throw an error if unauthorized.
         *
         * @param field the field used to compose the instruction to be added to the list, not null
         * @return this SELECT field list instance
         * @see Soqler.IFieldName
         * @see #add(Schema.SObjectField, Boolean) add
         * @since 1.0.4
         */
        global LField add(Schema.SObjectField field) {
            add(field, false);

            return this;
        }

        /**
         * It adds a <code>IFieldName</code> SELECT instruction
         * based on <code>Schema.SObjectField</code> to the list.
         * <p>
         * When the query will be built, or run,
         * if the field-level-security check fails for the field and droppable is true the query
         * will still work but not return the field value, otherwise it will throw an exception.
         *
         * @param field the field used to compose the instruction to be added to the list, not null
         * @param droppable the option to specify whether the field is droppable or not, not null
         * @return this SELECT field list instance
         * @see Soqler.IFieldName
         * @see #add(Schema.SObjectField) add
         * @since 1.0.4
         */
        global LField add(Schema.SObjectField field, Boolean droppable) {
            add(new IFieldName(field, droppable));

            return this;
        }

        /**
         * It adds a <code>IFieldName</code> SELECT instruction for all the fields
         * associated with the <code>SObject</code> the Soqler is based on.
         * <p>
         * When the query will be built, or run, the field will be checked
         * for field-level-security and throw an error if unauthorized.
         *
         * @return this SELECT field list instance
         * @see #add(Schema.SObjectField) add
         * @since 1.0.4
         */
        global LField addAll() {
            return addAll(
                new Set<Schema.SObjectField>(
                    Utils.getDescriber().getObjectFieldMap(query.getType()).values()
                )
            );
        }

        /**
         * It adds a <code>IFieldName</code> SELECT instruction for all the fields
         * specified in the set.
         * <p>
         * When the query will be built, or run, the field will be checked
         * for field-level-security and throw an error if unauthorized.
         *
         * @param fields the field set, not null
         * @return this SELECT field list instance
         * @see #add(Schema.SObjectField) add
         * @since 1.0.4
         */
        global LField addAll(Set<Schema.SObjectField> fields) {
            requireNonNull(fields, 'Fields cannot be null');

            for (Schema.SObjectField field : fields) {
                add(field);
            }

            return this;
        }
    }

    /**
     * It represents the object holding the list of instructions
     * that will compose the ORDER part of the query.
     *
     * @since 1.0.4
     */
    global class LOrder extends L {
        /**
         * It adds a ORDER instruction to the list.
         *
         * @param instruction the instruction to be added to the list, not null
         * @see Soqler.IOrder
         * @since 1.0.4
         */
        global LOrder add(IOrder instruction) {
            requireNonNull(instruction, 'Instruction cannot be null');

            instructions.add(instruction);

            return this;
        }

        /**
         * It adds a <code>IOrderName</code> ORDER instruction
         * based on <code>Schema.SObjectField</code> to the list.
         * The order applied will be ascending.
         *
         * @param field the field used to compose the instruction to be added to the list, not null
         * @see Soqler.IOrderName
         * @since 1.0.4
         */
        global LOrder add(Schema.SObjectField field) {
            return add(field, false);
        }

        /**
         * It adds a <code>IOrderName</code> ORDER instruction
         * based on <code>Schema.SObjectField</code> to the list.
         * The order applied will be ascending.
         *
         * @param field the field used to compose the instruction to be added to the list, not null
         * @param descendingOrder the order applied, descending if true, ascending if false, not null
         * @see Soqler.IOrderName
         * @since 1.0.4
         */
        global LOrder add(Schema.SObjectField field, Boolean descendingOrder) {
            return add(new IOrderName(field, descendingOrder));
        }
    }

    /**
     * It represents the object holding the list of instructions
     * that will compose the WHERE part of the query.
     *
     * @since 1.0.4
     */
    global class LWhere extends L {
        private LWhere add(IWhereLogic concatenator, IWhere instruction) {
            requireNonNull(instruction, 'Instruction cannot be null');

            if (!instructions.isEmpty()) {
                instructions.add(concatenator);
            }

            instructions.add(instruction);

            return this;
        }

        /**
         * It adds a WHERE instruction to the list
         * using the AND operator to concatenate the previous instruction if present.
         *
         * @param instruction the instruction to be added to the list, not null
         * @see Soqler.IWhere
         * @since 1.0.4
         */
        global LWhere addAnd(IWhere instruction) {
            return add(I_WHERE_AND, instruction);
        }

        /**
         * It adds a dynamic SOQL as <code>IWhereQuery</code> subquery to the WHERE instruction list
         * using the AND operator to concatenate the previous instruction if present.
         *
         * @param field the field the subquery to be run against, not null
         * @param subquery the query, not null
         * @see Soqler.IWhereQuery
         * @since 1.0.4
         */
        global LWhere addAnd(Schema.SObjectField field, Soqler subquery) {
            return addAnd(new IWhereQuery(field, subquery));
        }

        /**
         * It adds a WHERE instruction to the list
         * using the OR operator to concatenate the previous instruction if present.
         *
         * @param instruction the instruction to be added to the list, not null
         * @see Soqler.IWhere
         * @since 1.0.4
         */
        global LWhere addOr(IWhere instruction) {
            return add(I_WHERE_OR, instruction);
        }

        /**
         * It adds a dynamic SOQL as <code>IWhereQuery</code> subquery to the WHERE instruction list
         * using the OR operator to concatenate the previous instruction if present.
         *
         * @param field the field the subquery to be run against, not null
         * @param subquery the query, not null
         * @see Soqler.IWhereQuery
         * @since 1.0.4
         */
        global LWhere addOr(Schema.SObjectField field, Soqler subquery) {
            return addOr(new IWhereQuery(field, subquery));
        }

        override String getSeparator() {
            return '';
        }
    }

    private static final Converter C_DATE_TIME = new ConverterDateTime();
    private static final Converter C_DATE_TIME_DATE = new ConverterDateTimeDate();
    private static final Converter C_OBJECT = new Converter();
    private static final Converter C_STRING = new ConverterString();

    private static final IWhereLogic I_WHERE_AND = new IWhereLogic('AND');
    private static final IWhereLogic I_WHERE_OR = new IWhereLogic('OR');

    private final Schema.SObjectType type;
    private final LField flds;
    private String subquery;

    private LWhere whrs;
    private LOrder ords;
    private Integer maxCount;
    private Integer offset;

    /**
     * It creates an instance that will produce a dynamic SOQL
     * based on the <code>SObjectType</code> provide.
     *
     * @param type the SOQL <code>SObjectType</code>
     * @since 1.0.4
     */
    global Soqler(Schema.SObjectType type) {
        Utils.requireNonNull(type, 'Type cannot be null');

        this.type = type;
        this.flds = new LField(this);
    }

    private String build() {
        String fb = flds.build();
        String wb = whrs != null ? whrs.build() : null;
        String ob = ords != null ? ords.build() : null;

        return String.format(
            'SELECT {0} FROM {1}{2}{3}{4}{5}',
            new List<String>{
                fb,
                (subquery != null ? subquery : String.valueOf(type)),
                wb == null ? '' : ' WHERE ' + wb,
                ob == null ? '' : ' ORDER BY ' + ob,
                maxCount == null ? '' : ' LIMIT ' + maxCount,
                offset == null ? '' : ' OFFSET ' + offset
            }
        );
    }

    /**
     * It returns the instruction list that will compose the SELECT part of the query.
     *
     * @return the field instruction list
     * @see Soqler.LField
     * @since 1.0.4
     */
    global LField fields() {
        return flds;
    }

    /**
     * It returns the dynamic SOQL <code>SObjectType</code>.
     *
     * @return the dynamic SOQL <code>SObjectType</code>
     * @since 1.0.4
     */
    global Schema.SObjectType getType() {
        return type;
    }

    /**
     * It returns the dynamic SOQL LIMIT part of the query if present.
     *
     * @return the dynamic SOQL limit if present, otherwise null
     * @see #setMaxCount(Integer) setMaxCount
     * @since 1.0.4
     */
    global Integer maxCount() {
        return maxCount;
    }

    /**
     * It returns the dynamic SOQL OFFSET part of the query if present.
     *
     * @return the dynamic SOQL offset if present, otherwise null
     * @see #setOffset(Integer) setOffset
     * @since 1.0.4
     */
    global Integer offset() {
        return offset;
    }

    /**
     * It returns the instruction list that will compose the ORDER part of the query.
     *
     * @return the order instruction list
     * @see Soqler.LOrder
     * @since 1.0.4
     */
    global LOrder orders() {
        if (ords == null) {
            ords = new LOrder();
        }

        return ords;
    }

    /**
     * It runs the dynamic SOQL currently composed.
     *
     * @return a list of the records matching the dynamic SOQL
     * @throws Fls.AuditException if not-droppable SELECT fields were specified and are inaccessible
     * @see #queryToString() queryToString
     * @since 1.0.4
     */
    global List<SObject> query() {
        return (List<SObject>) Database.query(queryToString());
    }

    /**
     * It runs the COUNT() version of the dynamic SOQL currently composed.
     *
     * @return the count of the records matching the dynamic SOQL
     * @see #queryCountToString() queryCountToString
     * @since 1.0.4
     */
    global Integer queryCount() {
        return Database.countQuery(queryCountToString());
    }

    /**
     * It returns the query locator object for Salesforce processing.
     *
     * @return the query locator
     * @see #queryToString() queryToString
     * @since 1.0.4
     */
    global Database.QueryLocator queryLocator() {
        return Database.getQueryLocator(queryToString());
    }

    /**
     * It returns the dynamic SOQL string currently composed.
     *
     * @return the dynamic SOQL string
     * @throws UnsupportedOperationException if the query was passed as subquery of another query
     * @throws Fls.AuditException if not-droppable SELECT fields were specified and are inaccessible
     * @see #query() query
     * @since 1.0.4
     */
    global String queryToString() {
        if (subquery != null) {
            throw new UnsupportedOperationException('Cannot run a query tagged as subquery');
        }

        return build();
    }

    /**
     * It returns the COUNT() version dynamic SOQL string currently composed.
     *
     * @return the COUNT() dynamic SOQL string
     * @throws UnsupportedOperationException if the query was passed as subquery of another query
     * @see #queryCount() queryCount
     * @since 1.0.4
     */
    global String queryCountToString() {
        if (subquery != null) {
            throw new UnsupportedOperationException('Cannot run a query tagged as subquery');
        }

        String wb = whrs != null ? whrs.build() : null;

        return String.format(
            'SELECT COUNT() FROM {0}{1}{2}',
            new List<String>{
                String.valueOf(type),
                wb == null ? '' : ' WHERE ' + wb,
                maxCount == null ? '' : ' LIMIT ' + maxCount
            }
        );
    }

    private Soqler setAsSubquery(String value) {
        subquery = value;

        return this;
    }

    /**
     * It sets the dynamic SOQL LIMIT part of the query if present.
     * If the passed value is null LIMIT will be unset.
     *
     * @return the dynamic SOQL instance
     * @throws UnsupportedOperationException if the passed value is lower than 1
     * @see #getMaxCount() getMaxCount
     * @since 1.0.4
     */
    global Soqler setMaxCount(Integer value) {
        if (value != null && value < 1) {
            throw new UnsupportedOperationException('Query max count cannot be lower than 1');
        }

        maxCount = value;

        return this;
    }

    /**
     * It sets the dynamic SOQL OFFSET part of the query if present.
     * If the passed value is null OFFSET will be unset.
     *
     * @return the dynamic SOQL instance
     * @throws UnsupportedOperationException if the passed value is lower than 1
     * @see #getOffset() getOffset
     * @since 1.0.4
     */
    global Soqler setOffset(Integer value) {
        if (value != null && value < 1) {
            throw new UnsupportedOperationException('Offset cannot be lower than 1');
        }

        offset = value;

        return this;
    }

    /**
     * It returns the instruction list that will compose the WHERE part of the query.
     *
     * @return the where instruction list
     * @see Soqler.LWhere
     * @since 1.0.4
     */
    global LWhere wheres() {
        if (whrs == null) {
            whrs = new LWhere();
        }

        return whrs;
    }

    private static Converter getValueConverter(Schema.SObjectField field, Object value) {
        if (value instanceof Date) {
            return Utils.getDescriber().getFieldDescribe(field).getType() == DisplayType.DATETIME
                ? C_DATE_TIME_DATE
                : C_DATE_TIME;
        }

        if (value instanceof Datetime) {
            return C_DATE_TIME_DATE;
        }

        if (value instanceof String) {
            return C_STRING;
        }

        return C_OBJECT;
    }
}
