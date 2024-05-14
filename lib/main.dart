import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:intl/intl.dart';

import 'LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'VCFFIPtyiWVYAnI9DbOy3xiSUu4SphqOzMWgP7Qk';
  final keyClientKey = 'FKsWWniUV15bV0dpcECFNVcPShKBEalhNxhoVvBQ';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      routes: {
        '/taskdetails': (context) => TaskDetailsScreen(),
      },
    );
  }
}

class TaskDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ParseObject? task = ModalRoute.of(context)?.settings.arguments as ParseObject?;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Task Details"),
        ),
        body: Center(
          child: Text("No task data provided."),
        ),
      );
    }

    final String title = task.get<String>('title') ?? "Task Details";
    final String description = task.get<String>('description') ?? "No description";
    final String status = task.get<String>('status') ?? "Pending";
    final DateTime? date = task.get<DateTime>('date');

    String formattedDateTime = '';
    if (date != null) {
      // Convert to local timezone
      final localDate = date.toLocal();
      // Format date and time
      formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(localDate);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Description:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Status:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    status,
                    style: TextStyle(fontSize: 16),
                  ),
                  if (date != null) ...[
                    SizedBox(height: 16),
                    Text(
                      "Due Date:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      formattedDateTime,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void addToDo() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Missing Information'),
            content: Text('Please fill in all fields.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    await saveTodo(
        titleController.text, descriptionController.text, selectedDate);
    setState(() {
      titleController.clear();
      descriptionController.clear();
      dateController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks List"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "New Task",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 12.0),
            GestureDetector(
              onTap: () {
                _selectDate(context);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: "Select Due Date",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  ),
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: addToDo,
              child: Text("ADD"),
            ),
            Expanded(
              child: FutureBuilder<List<ParseObject>>(
                future: getTodo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error..."));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No Data..."));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final task = snapshot.data![index];
                        final isDone =
                            task.get<String>('status') == 'Completed';
                        return ListTile(
                          title: Text(task.get<String>('title')!),
                          subtitle: Text(task.get<String>('description')!),
                          leading: CircleAvatar(
                            backgroundColor:
                            isDone ? Colors.green : Colors.blue,
                            child: Icon(isDone ? Icons.check : Icons.error),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isDone,
                                onChanged: (value) async {
                                  await updateTodo(
                                      task.objectId!, value!, selectedDate);
                                  setState(() {
                                    // Refresh UI
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteTodo(task.objectId!);
                                  setState(() {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content:
                                        Text("Task deleted!")));
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/taskdetails',
                                arguments: task);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Task Screen
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.day,
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
        });
      }
    }
  }

  Future<void> saveTodo(
      String title, String description, DateTime selectedDate) async {
    final todo = ParseObject('Task')
      ..set('title', title)
      ..set('description', description)
      ..set('date', selectedDate);
    await todo.save();
  }

  Future<List<ParseObject>> getTodo() async {
    QueryBuilder<ParseObject> queryTodo =
    QueryBuilder<ParseObject>(ParseObject('Task'));
    final ParseResponse apiResponse = await queryTodo.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> updateTodo(
      String id, bool done, DateTime selectedDate) async {
    final status = done ? 'Completed' : 'Pending';
    final todo = ParseObject('Task')
      ..objectId = id
      ..set('status', status)
      ..set('date', selectedDate);
    await todo.save();
  }

  Future<void> deleteTodo(String id) async {
    final todo = ParseObject('Task')..objectId = id;
    await todo.delete();
  }
}
