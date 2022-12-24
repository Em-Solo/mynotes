// we are adding the T so we can add typing to what we are doing so then we use it in our calculations
// and so we add T on the name of the extension too.
extension Filter<T> on Stream<List<T>> {
  Stream<List<T>> filter(bool Function(T) where) =>
      // what this does is that it goes through all the items and gets the ones where the where functin holds
      map((items) => items.where(where).toList());
}
