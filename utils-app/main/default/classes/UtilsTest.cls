@isTest(isParallel=true)
public class UtilsTest {
  @isTest
  static void classNames() {
    Schema.Account acct = (Schema.Account) new TestUtils.AccountMaker()
      .setName('Dummy')
      .setCount(1)
      .make()
      .get(0);

    System.assertEquals('Blob', Utils.getClassName(Blob.valueOf('test')));
    System.assertEquals('Boolean', Utils.getClassName(true));
    System.assertEquals('Date', Utils.getClassName(Date.today()));
    System.assertEquals('Datetime', Utils.getClassName(Datetime.now()));
    System.assertEquals('Decimal', Utils.getClassName(Decimal.valueOf('1')));
    System.assertEquals('Id', Utils.getClassName(acct.Id));
    System.assertEquals('Integer', Utils.getClassName(Integer.valueOf('1')));
    System.assertEquals('List', Utils.getClassName(new List<String>()));
    System.assertEquals('Long', Utils.getClassName(Long.valueOf('1')));
    System.assertEquals('Account', Utils.getClassName(acct));
    System.assertEquals('String', Utils.getClassName('test'));
    System.assertEquals('Entry', Utils.getClassName(new Utils.Entry('test')));
  }

  @isTest
  static void easyDecimal() {
    Utils.EasyDecimal hundred = new Utils.EasyDecimal(100.0);

    System.assertEquals(88.2, hundred.addPct(-10).addPct(-2).decimalValue());
    System.assertEquals(112.2, hundred.addPct(10).addPct(2).decimalValue());
    System.assertEquals(-10, hundred.minus(hundred).minus(10).decimalValue());
    System.assertEquals(100, hundred.multiply(2).divide(2).decimalValue());
    System.assertEquals(40, hundred.multiply(2).pct(20).decimalValue());
    System.assertEquals(40, hundred.pctOf(250));
    System.assertEquals(210, hundred.plus(10).plus(hundred).decimalValue());
    System.assertEquals(70, hundred.rightPctOf(70));
    System.assertEquals(hundred, new Utils.EasyDecimal(100.0));
    System.assertEquals(hundred, hundred.copy());
    System.assert(hundred.toString().contains('100'));

    Set<Utils.EasyDecimal> decimals = new Set<Utils.EasyDecimal>{
      hundred,
      new Utils.EasyDecimal(100.0)
    };

    System.assertEquals(1, decimals.size());
  }

  @isTest
  static void entry() {
    List<Utils.Entry> entries = new List<Utils.Entry>{
      new Utils.Entry('value1', 'label1'),
      new Utils.Entry('value0', 'label0'),
      new Utils.Entry('value9')
    };

    System.assertEquals('value1', entries[0].getValue());
    System.assertEquals('value9', entries[2].getLabel());
    System.assertEquals(entries.size(), 3);

    // This will sort the entries according to their label
    entries.sort();

    System.assertEquals('label0', entries[0].getLabel());

    Set<Utils.Entry> entrySet = new Set<Utils.Entry>(entries);

    // This is not going to be added because it is a duplicate
    entrySet.add(new Utils.Entry('value1', 'label1'));

    System.assertEquals(entries.size(), 3);
  }

  @isTest
  static void hasher() {
    Utils.Hasher hs;

    try {
      hs = new Utils.Hasher('MD6');
    } catch (UnsupportedOperationException e) {
      System.assert(e.getMessage().contains('Algorithm must be'));
    }

    hs = new Utils.Hasher();
    String value = 'Hash Me!';

    System.assertEquals(
      EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(value))),
      hs.hash(value)
    );
  }

  @isTest
  static void mapper() {
    Utils.Entry dummy = new Utils.Entry('value1', 'label1');
    String serializedDummy = JSON.serialize(dummy);

    Utils.Mapper umapper = Utils.deserializeToMapper(serializedDummy);

    System.assert(umapper.containsKey('label'), 'It should have contained label key');
    System.assertEquals(dummy.getLabel(), umapper.getString('label'));
    System.assertEquals(dummy.getValue(), umapper.getString('value'));

    umapper = new Utils.Mapper(
      new Map<String, Object>{
        'bool' => true,
        'int' => 1,
        'list' => new List<String>{ '1', '2' },
        'map' => new Map<String, String>{ 'a' => '1', 'b' => '2' },
        'mapList' => new List<Map<String, Object>>{
          new Map<String, String>{ 'a' => '1', 'b' => '2' }
        },
        'string' => 'value'
      }
    );

    System.assertEquals(true, umapper.getBoolean('bool'));
    System.assertEquals(1, umapper.getInteger('int'));
    System.assertEquals(2, umapper.getStringList('list').size());
    System.assertEquals('2', umapper.getMap('map').values()[1]);
    System.assertEquals('Mapper', Utils.getClassName(umapper.getObjectAsMapper('map')));
    System.assertEquals(1, umapper.getMapList('mapList').size());
    System.assertEquals('value', umapper.getString('string'));
  }

  @isTest
  static void optionals() {
    System.assertEquals(true, Utils.optBooleanOrElse(null, true));
    System.assertEquals(false, Utils.optBooleanOrElse(false, true));

    System.assertEquals(0, Utils.optDecimalOrElse(null, 0));
    System.assertEquals(1.2, Utils.optDecimalOrElse(1.2, 0));

    System.assertEquals(1, Utils.optIntegerOrElse((Integer) null, 1));
    System.assertEquals(1, Utils.optIntegerOrElse(1.2, 1));
    System.assertEquals(2, Utils.optIntegerOrElse(2, 1));

    System.assertEquals('A', Utils.optStringOrElse(null, 'A'));
    System.assertEquals('B', Utils.optStringOrElse('B', 'A'));
  }

  @isTest
  static void queue() {
    Queue q = new Queue();

    System.assertEquals(true, q.isEmpty());
    System.assertEquals(0, q.size());
    System.assertEquals(null, q.peek());

    q.add('FirstIn');
    System.assertEquals(false, q.isEmpty());
    System.assertEquals(1, q.size());
    System.assertEquals('FirstIn', (String) q.peek());

    q.add('SecondIn');
    System.assertEquals(false, q.isEmpty());
    System.assertEquals(2, q.size());
    System.assertEquals('FirstIn', (String) q.peek());

    System.assertEquals('FirstIn', (String) q.poll());
    System.assertEquals('SecondIn', (String) q.poll());
    System.assertEquals(null, (String) q.poll());
    System.assertEquals(true, q.isEmpty());
    System.assertEquals(0, q.size());

    q.addAll(new List<Object>{ 'a', 'b', 'c' });
    System.assertEquals(3, q.size());
  }

  @isTest
  static void requireNonNull() {
    String message = 'Something is required';

    try {
      Utils.requireNonNull((Schema.Account) null, message);

      System.assert(false, 'It should have thrown a NullPointerException');
    } catch (NullPointerException e) {
      System.assertEquals(message, e.getMessage());
    }
  }

  @isTest
  static void sleep() {
    Long start = System.currentTimeMillis();

    Utils.sleep(3);

    Long elapsed = System.currentTimeMillis() - start;

    System.assert(elapsed >= 3000, 'It should have slept for about 3 seconds');
  }

  @isTest
  static void uniquifiers() {
    Utils.ValueUniquifier uni = new Utils.ValueUniquifier();

    uni.addValue('A');
    uni.addValue('B');
    uni.addValue('C');

    System.assertEquals(3, uni.getValues().size());

    System.assert(!uni.addValue('A'), 'It should have prevented the value from being re-added');

    Schema.Contact cnt1 = new Schema.Contact(LastName = 'Contact1', Email = 'example@example.com');
    Schema.Contact cnt2 = new Schema.Contact(LastName = 'Contact2', Email = 'example@example.com');
    Schema.Contact cnt3 = new Schema.Contact(LastName = 'Contact2', Email = 'demo@example.com');
    Utils.RecordValueUniquifier recuni = new Utils.RecordValueUniquifier(Contact.Email);

    System.assertEquals(cnt3.Email, recuni.getRecordValue(cnt3));

    recuni.addRecordValue(cnt1);

    System.assertEquals(1, recuni.getValues().size());
    System.assert(
      recuni.getRecord('example@example.com') != null,
      'It should have returned the record by the email specified'
    );
    System.assert(
      !recuni.addRecordValue(cnt2),
      'It should have prevented the record value from being re-added'
    );

    recuni = new Utils.RecordValueUniquifier(Contact.Email);
    recuni.addRecordValues(new List<Schema.Contact>{ cnt1, cnt2, cnt3 });

    System.assert(
      recuni.getRecord('example@example.com') != null,
      'It should have returned the record by the email specified'
    );
    System.assertEquals(2, recuni.getRecords().size());
  }

  @isTest
  static void urlQuery() {
    Utils.UrlQuery q = new Utils.UrlQuery();

    q.put('hello', '1');
    q.put('bye', '2');

    System.assertEquals('?hello=1&bye=2', q.toString());

    q = new Utils.UrlQuery(new Map<String, String>{ 'param1' => 'true', 'param2' => 'false' });

    System.assertEquals('?param1=true&param2=false', q.toString());
  }
}
