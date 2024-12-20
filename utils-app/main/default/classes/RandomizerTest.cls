@isTest(isParallel=true)
public with sharing class RandomizerTest {
  @isTest
  static void generate() {
    Randomizer.Builder builder;
    String random;
    List<String> components;

    builder = new Randomizer.Builder();
    random = builder
      .setCurrentTimeMillis(true)
      .setLength(6)
      .setOptions(
        new Set<Randomizer.Option>{
          Randomizer.Option.INCLUDE_LETTER,
          Randomizer.Option.INCLUDE_NUMBER
        }
      )
      .setPrefix('TEST')
      .build()
      .generate();
    components = random.split('-');

    System.assertEquals(
      3,
      components.size(),
      'The random components should have been 3: ' + random
    );
    System.assertEquals('TEST', components[0]);
    System.assertEquals(6, components[1].length());
    System.assert(
      components[1].isAlphanumeric(),
      'The 2nd component should have been alphanumeric ' + components[1]
    );

    builder = new Randomizer.Builder();
    random = builder
      .setOptions(new Set<Randomizer.Option>{ Randomizer.Option.INCLUDE_NUMBER })
      .setLength(3)
      .build()
      .generate();
    components = random.split('-');

    System.assertEquals(3, components[0].length());
    System.assert(
      !components[0].isAlpha(),
      'The component should not have contained letters: ' + components[0]
    );
  }

  @isTest
  static void randoms() {
    Assert.isTrue(Randomizer.getRandomLetter().length() == 1);

    {
      final Integer randomNumber = Randomizer.getRandomNumber();

      Assert.isTrue(randomNumber >= 0 && randomNumber <= 9);
    }

    {
      final Integer minValue = 150;
      final Integer maxValue = 175;
      final Integer randomNumber = Randomizer.getRandomNumber(minValue, maxValue);

      Assert.isTrue(randomNumber >= minValue && randomNumber <= maxValue);
    }
  }
}
