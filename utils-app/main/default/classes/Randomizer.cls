/**
 * An object that creates rule-based random string values.
 * The object must be created through <code>Randomizer.Builder</code>.
 *
 * @see Randomizer.Builder
 * @since 1.0.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class Randomizer {
  /**
   * A builder for <code>Randomizer</code>.
   * It defines the rules that object will use to create a random string.
   *
   * @see Randomizer
   * @since 1.0.1
   */
  global class Builder {
    private Boolean currentTimeMillis;
    private Integer length;
    private String prefix;
    private Set<Option> prefs;

    /**
     * It toggles the inclusion of current time in millisecs
     * in the string that will be generated.
     *
     * @param flag the toggle
     * @see Randomizer
     * @return the builder instance
     * @since 1.0.1
     */
    global Builder setCurrentTimeMillis(Boolean flag) {
      currentTimeMillis = flag != null && flag;

      return this;
    }

    /**
     * It sets the Options used in the string that will be generated.
     *
     * @param values the Options
     * @see Randomizer.Option
     * @return the builder instance
     * @since 1.0.1
     */
    global Builder setOptions(Set<Option> values) {
      prefs = values;

      return this;
    }

    /**
     * It sets the use a prefix in the string that will be generated.
     * If the value is null no prefix will be added.
     *
     * @param value the prefix value
     * @return the builder instance
     * @since 1.0.1
     */
    global Builder setPrefix(String value) {
      prefix = value;

      return this;
    }

    /**
     * It sets the length of the string that will be generated.
     *
     * @param value the length of the string
     * @return the builder instance
     * @since 1.0.1
     */
    global Builder setLength(Integer value) {
      length = value;

      return this;
    }

    /**
     * It builds a <code>Randomizer</code> instance using the rules currently set.
     *
     * @throws UnsupportedOperationException if not <code>Option</code> was not set or the length was not set or it is lower than 3 or greater than 16
     * @return the <code>Randomizer</code> instance
     * @since 1.0.1
     */
    global Randomizer build() {
      if (prefs == null) {
        throw new System.UnsupportedOperationException('Options cannot be null or empty');
      }

      if (length == null || length < 3 || length > 16) {
        throw new System.UnsupportedOperationException(
          'Length cannot be null and must be comprised between 3 and 16'
        );
      }

      return new Randomizer(this);
    }
  }

  /**
   * It defines the Options used by <code>Builder</code>.
   * in the string that will be generated.
   *
   * @see Randomizer.Builder
   * @since 1.0.1
   */
  global enum Option {
    INCLUDE_LETTER,
    INCLUDE_NUMBER
  }

  private final Boolean currentTimeMillis;
  private final Integer length;
  private final String prefix;
  private final Set<Option> prefs;

  private Randomizer(Builder builder) {
    currentTimeMillis = builder.currentTimeMillis;
    prefix = builder.prefix;
    prefs = builder.prefs;
    length = builder.length;
  }

  /**
   * It generates the random string value based on the rules defined in the object.
   *
   * @return the randomly generated string value
   * @since 1.0.1
   */
  global String generate() {
    String value = prefix != null && prefix.length() > 0 ? prefix + '-' : '';

    Iterator<Option> iter = prefs.iterator();

    for (Integer i = 0; i < length; i++) {
      if (!iter.hasNext()) {
        iter = prefs.iterator();
      }

      Option pref = iter.next();

      switch on pref {
        when INCLUDE_LETTER {
          value += getRandomLetter();
        }
        when INCLUDE_NUMBER {
          value += getRandomNumber();
        }
      }
    }

    if (currentTimeMillis != null && currentTimeMillis) {
      value += '-' + System.currentTimeMillis();
    }

    return value;
  }

  private String getRandomLetter() {
    return String.fromCharArray(new List<Integer>{ getRandomNumber(0, 25) + 65 });
  }

  private Integer getRandomNumber() {
    return getRandomNumber(0, 9);
  }

  private Integer getRandomNumber(Integer min, Integer max) {
    return (Integer) ((Math.random() * ((max - min) + 1)) + min);
  }
}