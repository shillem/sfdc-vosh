/**
 * @description A custom implementation of <code>java.util.Queue</code>.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Queue {
  private final List<Object> values;

  global Queue() {
    values = new List<Object>();
  }

  /**
   * @description It appends the element to the end of the queue.
   *
   * @param element the object to be appended
   * @throws System.NullPointerException if the object is null
   * @since 1.1
   */
  global void add(Object element) {
    Utils.requireNonNull(element, 'The queue element cannot be null');

    values.add(element);
  }

  /**
   * @description It appends the elements to the end of the queue.
   *
   * @param elements the objects to be appended
   * @throws System.NullPointerException if the object is null
   * @since 1.1
   */
  global void addAll(List<Object> elements) {
    Utils.requireNonNull(elements, 'The queue element cannot be null');

    values.addAll(elements);
  }

  /**
   * @description It returns whether the queue is empty or not.
   *
   * @return true if the queue is empty
   * @since 1.1
   */
  global Boolean isEmpty() {
    return values.isEmpty();
  }

  /**
   * @description It peeks for the first element of the queue and returns it if the queue is not empty.
   *
   * @return the element at the beginning of the queue or null if the queue is empty
   * @since 1.1
   */
  global Object peek() {
    return isEmpty() ? null : values[0];
  }

  /**
   * @description It removes and returns the element at the beginning of the queue.
   *
   * @return the element at the beginning of the queue or null if the queue is empty
   * @since 1.1
   */
  global Object poll() {
    return isEmpty() ? null : values.remove(0);
  }

  /**
   * @description It returns the queue size.
   *
   * @return the queue size
   * @since 1.1
   */
  global Integer size() {
    return values.size();
  }

  /**
   * @description It returns a new List instance of the queue.
   *
   * @return the queue as List
   * @since 1.1
   */
  global List<Object> toList() {
    return new List<Object>(values);
  }
}
