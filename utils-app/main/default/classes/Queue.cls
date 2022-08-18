/**
 * @description A custom implementation of <code>java.util.Queue</code>.
 *
 * @since 1.0.23
 */
public inherited sharing class Queue {
  private final List<Object> queue;

  public Queue() {
    queue = new List<Object>();
  }

  /**
   * @description It appends the element to the end of the queue.
   *
   * @param element the object to be appended
   * @throws System.NullPointerException if the object is null
   * @since 1.0.23
   */
  public void add(Object element) {
    Utils.requireNonNull(element, 'The queue element cannot be null');

    queue.add(element);
  }

  /**
   * @description It appends the elements to the end of the queue.
   *
   * @param elements the objects to be appended
   * @throws System.NullPointerException if the object is null
   * @since 1.0.23
   */
  public void addAll(List<Object> elements) {
    Utils.requireNonNull(elements, 'The queue element cannot be null');

    queue.addAll(elements);
  }

  /**
   * @description It peeks for the first element of the queue and returns it if the queue is not empty.
   *
   * @return the element at the beginning of the queue or null if the queue is empty
   * @since 1.0.23
   */
  public Object peek() {
    return isEmpty() ? null : queue[0];
  }

  /**
   * @description It removes and returns the element at the beginning of the queue.
   *
   * @return the element at the beginning of the queue or null if the queue is empty
   * @since 1.0.23
   */
  public Object poll() {
    return isEmpty() ? null : queue.remove(0);
  }

  /**
   * @description It returns the queue size.
   *
   * @return the queue size
   * @since 1.0.23
   */
  public Integer size() {
    return queue.size();
  }

  /**
   * @description It returns whether the queue is empty or not.
   *
   * @return true if the queue is empty
   * @since 1.0.23
   */
  public Boolean isEmpty() {
    return queue.isEmpty();
  }
}
