// this exception is simply for representation and simplification, make things easier and more readable
//makes grouping and grabbing these exceptions in the future alot easier
class CloudStorageException implements Exception {
  const CloudStorageException();
}

// For the C in CRUD
class CouldNotCreateNoteException extends CloudStorageException {}

// for the R in CRUD
class CouldNotGetAllNotesException extends CloudStorageException {}

// for the U in CRUD
class CouldNotUpdateNoteException extends CloudStorageException {}

// for the D in CRUD
class CouldNotDeleteNoteException extends CloudStorageException {}
