import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Task> tasks = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? taskStrings = prefs.getStringList('tasks');
    if (taskStrings != null) {
      tasks = taskStrings.map((taskString) => Task.fromString(taskString)).toList();
      setState(() {});
    }
  }

  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final taskStrings = tasks.map((task) => task.toString()).toList();
    prefs.setStringList('tasks', taskStrings);
  }

  void addTask(Task task) {
    setState(() {
      tasks.add(task);
      saveTasks();
    });
  }

  void updateTask(int index, Task updatedTask) {
    setState(() {
      tasks[index] = updatedTask;
      saveTasks();
    });
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      saveTasks();
    });
  }

  void onSearchTextChanged(String query) {
    // Filter tasks based on the search query
    setState(() {
      tasks = tasks.where((task) {
        final title = task.title.toLowerCase();
        final description = task.description.toLowerCase();
        final lowercaseQuery = query.toLowerCase();
        return title.contains(lowercaseQuery) || description.contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'To-Do List',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: onSearchTextChanged,
              decoration: InputDecoration(
                labelText: 'Search Tasks',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tasks[index].title),
                  subtitle: Text(tasks[index].description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 30.0),
                    onPressed: () {
                      deleteTask(index);
                    },
                  ),
                  onLongPress: () {
                    deleteTask(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormScreen()),
          );
          if (newTask != null) {
            addTask(newTask);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void onTaskCompleted(int index, bool newValue) {
    setState(() {
      tasks[index] = tasks[index].copyWith(isCompleted: newValue);
      if (newValue) {
        // If the checkbox is checked (task is completed), remove the task
        tasks.removeAt(index);
      }
      saveTasks();
    });
  }
}

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  description: descriptionController.text,
                );
                Navigator.pop(context, newTask);
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String description;
  final bool isCompleted;

  Task({
    required this.title,
    this.description = '',
    this.isCompleted = false,
  });

  Task copyWith({String? title, String? description, bool? isCompleted}) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return '$title|$description|$isCompleted';
  }

  static Task fromString(String taskString) {
    final parts = taskString.split('|');
    return Task(
      title: parts[0],
      description: parts[1],
      isCompleted: parts[2] == 'true',
    );
  }
}
