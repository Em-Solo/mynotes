import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_services.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  // ? makes it optional, becasue it has no value to start with.
  DatabaseNote? _note;

  late final NotesService _notesService;

  late final TextEditingController _textController;

  Future<DatabaseNote> createNewNote() async {
    final existingNote = _note;

    if (existingNote != null) {
      return existingNote;
    }

    // Using ! because we know that if we get to this point its not gonna be null
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    //going from the firebase user to the database one, same thing different saved place.
    final owner = await _notesService.getUser(email: email);

    return await _notesService.createNote(owner: owner);
  }

  void _textControllerListener() async {
    final note = _note;

    if (note == null) {
      return;
    }

    final text = _textController.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );
  }

  // we remove and add incase the function is called multiple times to avoid duplicates
  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;

    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;

    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  @override
  void initState() {
    //singleteon exists so here it will not create another instance of the notes service. but use the one already defined.
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              // .data is the data that is returned from the future, we get them through the snapshot, and we cast it to the type we want.
              _note = snapshot.data as DatabaseNote?;
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                // InputDecoration bundles up all the decoration for the text field
                decoration: const InputDecoration(
                  hintText: 'Start typing your note...',
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
