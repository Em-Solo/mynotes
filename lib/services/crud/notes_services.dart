// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:mynotes/extensions/list/filter.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' show join;
// import 'crud_exceptions.dart';

// const idColumn = 'id';
// const emailColumn = 'email';
// const userIdColumn = 'user_id';
// const textColumn = 'text';
// const isSyncedWithCloudColumn = 'is_synced_with_cloud';

// const dbName = 'notes.db';
// const noteTable = 'note';
// const userTable = 'user';

// //sql code for user table creation
// const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
//         "id" INTEGER NOT NULL,
//         "email" TEXT NOT NULL UNIQUE,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       )''';

// //sql code for note table creation
// const craeteNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
//         "id" INTEGER NOT NULL,
//         "user_id" INTEGER NOT NULL,
//         "text" TEXT,
//         "is_synced_with_cloud" INTEGER NOT NULL DEFAULT 0,
//         FOREIGN KEY("user_id") REFERENCES "user"("id"),
//         PRIMARY KEY("id" AUTOINCREMENT)
//       )''';

// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;

//   const DatabaseUser({
//     required this.id,
//     required this.email,
//   });

// // each row is represented by an object of Map<String, Object?>
//   DatabaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() => 'Person, ID = $id, email = $email';

// //using covarient makes it so it says that we can only compare with objects of our class
// //not using it would throw an error saying we are meant to be giving a variable of type object
//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class DatabaseNote {
//   final int id;
//   final int userId;
//   final String text;
//   final bool isSyncedWithCloud;

//   DatabaseNote({
//     required this.id,
//     required this.userId,
//     required this.text,
//     required this.isSyncedWithCloud,
//   });

//   DatabaseNote.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userId = map[userIdColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedWithCloud =
//             (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;
//   //wtf is this sintax ^

//   @override
//   String toString() =>
//       'Note, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

//   @override
//   bool operator ==(covariant DatabaseNote other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class NotesService {
//   Database? _db;

//   // our cache, where we will be keeping the notes that the notes service manipulates.
//   List<DatabaseNote> _notes = [];

//   DatabaseUser? _user;

//   // creating a singleton
//   static final NotesService _shared = NotesService._sharedInstance();
//   // initializer
//   NotesService._sharedInstance() {
//     _notesStreamController =
//         //onLissten callback will be called whenever a new listener is added to the stream
//         // so what will happen is when ever calls the singleton to add new stream the onListen callback will be called and the previes notes will be added to the stream
//         StreamController<List<DatabaseNote>>.broadcast(
//       onListen: () {
//         _notesStreamController.sink.add(_notes);
//       },
//     );
//   }
//   factory NotesService() => _shared;

//   // what this line of code does is
//   // I want to be able to control a stream of a list of databseNotes
//   late final StreamController<List<DatabaseNote>> _notesStreamController;

//   Future<void> _cacheNotes() async {
//     final allNotes = await getAllNotes();

//     _notes = allNotes.toList();

//     // stream is an evolution of a value through time
//     _notesStreamController.add(_notes);
//   }

//   // a stream that subscribes to the stream controller and gets all the notes. its a getter
//   Stream<List<DatabaseNote>> get allNotes =>
//       _notesStreamController.stream.filter(
//         (note) {
//           final currentUser = _user;
//           if (currentUser != null) {
//             return note.userId == currentUser.id;
//           } else {
//             throw UserShouldBeSetBeforeReadingAllNotes();
//           }
//         },
//       );

//   Future<void> open() async {
//     if (_db != null) {
//       throw DatabaseAlreadyOpenException();
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       //opendatabase can also create the database on the instance that it does not exist, otherwise opens it if it already exist, all according to the path
//       final db = await openDatabase(dbPath);
//       _db = db;

//       // create the user table
//       await db.execute(createUserTable);
//       // create note table
//       await db.execute(craeteNoteTable);

//       await _cacheNotes();
//     } on MissingPlatformDirectoryException {
//       throw UnableToGetDocumentsDirectory();
//     }
//   }

//   Future<void> close() async {
//     final db = _db;

//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       await db.close();
//       _db = null;
//     }
//   }

//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       return db;
//     }
//   }

//   Future<void> _ensureDbIsOpen() async {
//     try {
//       await open();
//     } on DatabaseAlreadyOpenException {
//       // empty
//     }
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );

//     if (results.isNotEmpty) {
//       throw UserAlreadyExists();
//     }

//     final userId = await db.insert(userTable, {
//       emailColumn: email.toLowerCase(),
//     });

//     return DatabaseUser(id: userId, email: email);
//   }

//   Future<DatabaseUser> getOrCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     try {
//       final user = await getUser(email: email);
//       if (setAsCurrentUser) {
//         _user = user;
//       }
//       return user;
//     } on CouldNotFindUser {
//       final createdUser = await createUser(email: email);
//       if (setAsCurrentUser) {
//         _user = createdUser;
//       }
//       return createdUser;
//     } catch (e) {
//       // catches the expetion and throws it back to the caller/ call site for debugging
//       rethrow;
//     }
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );

//     if (results.isEmpty) {
//       throw CouldNotFindUser();
//     }

//     return DatabaseUser.fromRow(results.first);
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );

//     // we made email unique so when we give in an email that is included in the table then it should return 1
//     // so if its not 1 it means that something is wrong
//     if (deletedCount != 1) {
//       throw CouldNotDeleteUser();
//     }
//   }

//   Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     // make sure owner exists in the database with the correct id
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) {
//       throw CouldNotFindUser();
//     }

//     const text = '';

//     // create the note
//     final noteID = await db.insert(noteTable, {
//       userIdColumn: owner.id,
//       textColumn: text,
//       isSyncedWithCloudColumn: 1,
//     });
//     // each map represent one row keys being the column labels and values what they get populated with

//     final note = DatabaseNote(
//       id: noteID,
//       userId: owner.id,
//       text: text,
//       isSyncedWithCloud: true,
//     );

//     //we now add this new note to the cache list and then add the list to the stream controller to update its condition
//     _notes.add(note);
//     _notesStreamController.add(_notes);

//     return note;
//   }

//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     final notes = await db.query(
//       noteTable,
//       limit: 1,
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (notes.isEmpty) {
//       throw CouldNotFindNote();
//     }

//     final note = DatabaseNote.fromRow(notes.first);

//     _notes.removeWhere((note) => note.id == id);
//     _notes.add(note);
//     _notesStreamController.add(_notes);

//     return note;
//   }

//   Future<Iterable<DatabaseNote>> getAllNotes() async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     final notes = await db.query(noteTable);

//     // goes through alll the items in the thing you call maps on and executes a function that takes as its parameter each object
//     // of the thing you call map on and once the function executes the result is added into an iterable.
//     return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
//   }

//   Future<DatabaseNote> updateNote({
//     required DatabaseNote note,
//     required String text,
//   }) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     // make sure note exists
//     // we are calling upon this method not becayse we want its result but mainly so it throws its exception if the note does not exist
//     await getNote(id: note.id);

//     // update DB
//     final updatesCount = await db.update(
//       noteTable,
//       {
//         textColumn: text,
//         isSyncedWithCloudColumn: 0,
//       },
//       where: 'id = ?',
//       whereArgs: [note.id],
//     );

//     if (updatesCount == 0) {
//       throw CouldNotUpdateNote();
//     }

//     final updatedNote = await getNote(id: note.id);

//     _notes.removeWhere((note) => note.id == updatedNote.id);
//     _notes.add(updatedNote);
//     _notesStreamController.add(_notes);

//     return updatedNote;
//   }

//   Future<void> deleteNote({required int id}) async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     final deletedCount = await db.delete(
//       noteTable,
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (deletedCount == 0) {
//       throw CouldNotDeleteNote();
//     }
//     _notes.removeWhere((note) => note.id == id);
//     _notesStreamController.add(_notes);
//   }

//   // returns an int number that represents how many notes have been deleted
//   Future<int> deleteAllNotes() async {
//     await _ensureDbIsOpen();

//     final db = _getDatabaseOrThrow();

//     // this command will delete the entirity of the database table, and retunr the amount of rows tha have been deleted
//     final numberOfDeletions = await db.delete(noteTable);

//     _notes = [];
//     _notesStreamController.add(_notes);

//     return numberOfDeletions;
//   }
// }
