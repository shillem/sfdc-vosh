/**
 * @description A collection of utility methods focusing on collections.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
 global inherited sharing class Collections {
  /**
   * @description It returns a flattened list of the list of lists passed
   *
   * @param lists the lists, not null
   * @throws IllegalArgumentException if lists is empty
   * @since 1.1
   */
  global static List<Object> flatten(List<List<Object>> lists) {
    Utils.requireNonNull(lists, 'Lists cannot be null');

    if (lists.isEmpty()) {
        throw new IllegalArgumentException('Lists cannot be empty');
    }

    final List<Object> flattened = lists[0].clone();

    for (Integer i = 1; i < lists.size(); i++) {
        flattened.addAll(lists[i]);
    }

    return flattened;
  }

  /**
   * @description It returns a sublist of the passed list according to the start and end index passed
   *
   * @param l the list, not null
   * @param startIndex the start index, not null
   * @param endIndex the start index, not null
   * @throws IllegalArgumentException if start and end index values are out of bounds
   * @since 1.1
   */
  global static List<Object> subList(List<Object> l, Integer startIndex, Integer endIndex) {
    Utils.requireNonNull(l, 'List cannot be null');
    Utils.requireNonNull(startIndex, 'Start index cannot be null');
    Utils.requireNonNull(endIndex, 'End index cannot be null');

    if (startIndex < 0) {
      throw new IllegalArgumentException('Start index cannot be lower than 0');
    }

    if (startIndex > endIndex) {
      throw new IllegalArgumentException('Start index cannot be greater than end index');
    }

    if (endIndex > l.size() - 1) {
      throw new IllegalArgumentException('End index cannot be greater than the list size - 1');
    }

    final List<Object> c = l.clone();

    c.clear();

    for (Integer i = startIndex; i <= endIndex; i++) {
      c.add(l[i]);
    }

    return c;
  }
}
