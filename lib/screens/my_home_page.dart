import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:basiclayout/firebase_options.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  final List<String> tasks = <String>[];

  final List<bool> checkboxes = List.generate(8, (index) => false);

  bool isChecked = false;

  TextEditingController nameController = TextEditingController();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  FocusNode _textFieldFocusNode = FocusNode();

  void addItemToList() async {
    final String taskName = nameController.text;

    // Add to the Firestore collection
    await db.collection('tasks').add({
      'name': taskName,
      'completed': isChecked,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      tasks.insert(0, taskName);
      checkboxes.insert(0, false);
    });

    clearTextField();
  }

  void removeItem(int index) async {
    // Get the task name to be removed
    String taskNameToRemove = tasks[index];

    // Remove the task from the Firestore collection
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: taskNameToRemove)
        .get();
    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];
      await documentSnapshot.reference.delete();
    }

    // Remove the task from the tasks list and checkboxes list
    setState(() {
      tasks.removeAt(index);
      checkboxes.removeAt(index);
    });
  }

  void clearTextField() {
    setState(() {
      nameController.clear();
    });
  }

  // Asynchronous function to fetch tasks data from Firestore
  Future<void> fetchTasksFromFirestore() async {
    // Get a reference to the 'tasks' collection in Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    // Fetch the documents (tasks) from the collection
    QuerySnapshot querySnapshot = await tasksCollection.get();

    // Create an empty list to store fetched task names
    List<String> fetchedTasks = [];

    // Loop through each document (task) in the query snapshot
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      // Get the task name from the document's data
      String taskName = docSnapshot.get('name');

      // Get the completion status of the task
      bool completed = docSnapshot.get('completed');

      // Add the task name to the list of fetched tasks
      fetchedTasks.add(taskName);
    }

    // Update the state to reflect the fetched tasks
    setState(() {
      tasks.clear(); // Clear the existing tasks list
      tasks.addAll(fetchedTasks); // Add the fetched tasks to the list
    });
  }

  // Asynchronous function to update the completion status of a task in Firestore
  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    // Get a reference to the 'tasks' collection in Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    // Query Firestore for documents (tasks) with the given task name
    QuerySnapshot querySnapshot =
        await tasksCollection.where('name', isEqualTo: taskName).get();

    // If a matching task document is found
    if (querySnapshot.size > 0) {
      // Get a reference to the first matching document
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      // Update the 'completed' field of the document with the new completion status
      await documentSnapshot.reference.update({'completed': completed});
    }

    // Update the state to reflect the new completion status in the UI
    setState(() {
      // Find the index of the task in the tasks list
      int taskIndex = tasks.indexWhere((task) => task == taskName);

      // Update the corresponding checkbox value in the checkboxes list
      checkboxes[taskIndex] = completed;
    });
  }

  // Override the initState method of the State class
  @override
  void initState() {
    super.initState();

    // Call the function to fetch tasks from Firestore when the widget is initialized
    fetchTasksFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset('assets/rdplogo.png'),
            ),
            Text('Daily Planner',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 32,
                )),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[200], // Change the background color
        child: Column(
          children: <Widget>[
            Container(
              height: 300,
              color: Colors.white, // Change the background color
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: TableCalendar(
                    calendarFormat: _calendarFormat,
                    headerVisible: false,
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2022),
                    lastDay: DateTime(2030),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // Update the focused day
                      });
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment(0.00, 0.9999),
                    end: Alignment(0.00, 0.22),
                    colors: <Color>[
                      Colors.white.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstOut,
                child: ListView.builder(
                  padding: const EdgeInsets.all(1),
                  itemCount: tasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: checkboxes[index]
                            ? Colors.green.withOpacity(0.7)
                            : Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: EdgeInsets.all(2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                children: [
                                  Icon(
                                    !checkboxes[index]
                                        ? Icons.manage_history
                                        : Icons.playlist_add_check_circle,
                                    color: !checkboxes[index]
                                        ? Colors.white
                                        : Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(width: 18),
                                  Text(
                                    '${tasks[index]}',
                                    style: checkboxes[index]
                                        ? TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: 20,
                                            color:
                                                Colors.black.withOpacity(0.5),
                                          )
                                        : TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Checkbox(
                            value: checkboxes[index],
                            onChanged: (newValue) {
                              setState(() {
                                checkboxes[index] = newValue!;
                              });
                              updateTaskCompletionStatus(
                                  tasks[index], newValue!);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              removeItem(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, left: 25, right: 25),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: nameController,
                        focusNode: _textFieldFocusNode,
                        maxLength: 20,
                        style: TextStyle(fontSize: 18), // Set the text style
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(
                              16), // Add padding to the input area
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Customize border radius
                          ),
                          labelText: 'Add To-Do List Item',
                          labelStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.blue), // Customize label style
                          hintText: 'Enter your task here', // Placeholder text
                          hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey), // Placeholder style
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2), // Custom focused border
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: clearTextField,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: Text('Add To-Do Item'),
                onPressed: () {
                  _textFieldFocusNode.unfocus();
                  addItemToList();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
