import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exception.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  // a static final field that calls the private initialiser
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstances();
  // Private COnstructior
  FirebaseCloudStorage._sharedInstances();
  // We create a factory constructor
  // this talks with teh first static final field
  factory FirebaseCloudStorage() => _shared;

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async {
    try {
      return await notes
          .where(
            ownerUserIdFieldName,
            isEqualTo: ownerUserId,
          )
          .get()
          // after get applied to ecexute the query we get the object the database returns, then using then method which executes after a future
          // we get that value and call docs on it which calls upon all the documents received and on them we call map which maps each one of the document, means we itterate through them
          // and using each document we return an instance of a cloud note.
          // this is going to happen for all the documents returned mathing the where
          .then(
            (value) => value.docs.map(
              (doc) => CloudNote.fromSnapshot(doc),

              //We already had a constructor that did all this so this is not needed
              // the constructior we used is like a more specific one that does what we want automatically
              // CloudNote(
              //   documentId: doc.id,
              //   ownerUserId: doc.data()[ownerUserIdFieldName] as String,
              //   text: doc.data()[textFieldName] as String,
              // );
            ),
          );
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) =>
      // if you want the stream of some data then you need to use the snapshot
      // also seems that from what you get from the snapshots you then go on and get the documents from it, might be getting more thatn one thing
      // for each query snapshot you get the documents
      notes.snapshots().map((events) => events.docs
          .map((doc) => CloudNote.fromSnapshot(doc))
          .where((note) => note.ownerUserId == ownerUserId));

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }
}
