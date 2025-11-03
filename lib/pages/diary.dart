import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // DELETE: Remove diary entry
  Future<void> _deleteDiaryEntry(String entryId) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('diary_entries').doc(entryId).delete();
      _showSnackBar('Entry deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting entry: $e');
    }
  }

  // Show confirmation dialog for delete
  void _showDeleteDialog(String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteDiaryEntry(entryId);
              _deleteDiaryEntry(entryId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        body: const Center(child: Text('Please login to view your diary')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 100, 8, 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('diary_entries')
              .where('userId', isEqualTo: _userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data?.docs ?? [];

            if (entries.isEmpty) {
              return const Center(
                child: Text(
                  'No diary entries yet.\nTap + to add your first entry!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // Sort entries manually by createdAt
            final sortedEntries = List<QueryDocumentSnapshot>.from(entries);
            sortedEntries.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime); // Descending order
            });

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final data = entry.data() as Map<String, dynamic>;
                final entryId = entry.id;
                final title = data['title'] ?? 'Untitled';
                final content = data['content'] ?? '';
                final createdAt = data['createdAt'] as Timestamp?;
                final dateStr = createdAt != null
                    ? DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(createdAt.toDate())
                    : 'No date';

                return Card(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary, // 💡 change icon color here
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryEntryFormPage(
                                entryId: entryId,
                                title: title,
                                content: content,
                              ),
                            ),
                          );
                        } else if (value == 'delete') {
                          _showDeleteDialog(entryId);
                        }
                      },
                    ),
                    onTap: () {
                      // Navigate to view full entry
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryEntryViewPage(
                            title: title,
                            content: content,
                            dateStr: dateStr,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DiaryEntryFormPage()),
          );
        },
        elevation: 8, // 🔹 increases shadow depth (default is 6)
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.secondaryContainer,
          size: 50,
        ),
      ),
    );
  }
}

// Separate page for creating/editing diary entries
class DiaryEntryFormPage extends StatefulWidget {
  final String? entryId;
  final String? title;
  final String? content;

  const DiaryEntryFormPage({Key? key, this.entryId, this.title, this.content})
    : super(key: key);

  @override
  State<DiaryEntryFormPage> createState() => _DiaryEntryFormPageState();
}

class _DiaryEntryFormPageState extends State<DiaryEntryFormPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  String? get _userId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.title != null) _titleController.text = widget.title!;
    if (widget.content != null) _contentController.text = widget.content!;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveEntry() async {
    if (_userId == null) {
      _showSnackBar('Please login first');
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnackBar('Please fill in both title and content');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.entryId == null) {
        // Create new entry
        await _firestore.collection('diary_entries').add({
          'userId': _userId,
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _showSnackBar('Entry added successfully');
      } else {
        // Update existing entry
        await _firestore
            .collection('diary_entries')
            .doc(widget.entryId)
            .update({
              'title': _titleController.text.trim(),
              'content': _contentController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        _showSnackBar('Entry updated successfully');
      }

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error saving entry: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.entryId == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveEntry),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.inversePrimary, // label color
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .inversePrimary, // border color when active
                        width: 2,
                      ),
                    ),
                  ),
                  cursorColor: Theme.of(
                    context,
                  ).colorScheme.inversePrimary, // blinking cursor color
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary, // text color
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.inversePrimary, // label color
                      ),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary, // border color when active
                          width: 2,
                        ),
                      ),
                    ),
                    cursorColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary, // blinking cursor color
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.inversePrimary, // text color
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Separate page for viewing full diary entry
class DiaryEntryViewPage extends StatelessWidget {
  final String title;
  final String content;
  final String dateStr;

  const DiaryEntryViewPage({
    Key? key,
    required this.title,
    required this.content,
    required this.dateStr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diary Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 32),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
