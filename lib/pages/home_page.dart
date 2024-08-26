import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo/utils/todo_lis.dart';
import '../utils/database_helper.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> toDoList = [];
  DateTime _selectedDate = DateTime.now();
  late CalendarFormat _calendarFormat;
  DateTime _calendarPopupDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _loadTodos();
  }

  void _loadTodos() async {
    final dbHelper = DatabaseHelper();
    final todos = await dbHelper.getTodosForDate(_selectedDate);
    setState(() {
      toDoList = todos;
    });
  }

  void checkBoxChanged(int index) async {
    final dbHelper = DatabaseHelper();
    final updatedTodo = {
      'id': toDoList[index]['id'],
      'title': toDoList[index]['title'],
      'isDone': toDoList[index]['isDone'] == 0 ? 1 : 0,
      'date': toDoList[index]['date'],
    };
    await dbHelper.updateTodo(updatedTodo);
    _loadTodos();
  }

  void saveNewTask() async {
    if (_controller.text.isNotEmpty) {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertTodo(
        title: _controller.text,
        isDone: false,
        date: _selectedDate, // Save with the selected date
      );
      _controller.clear();
      _loadTodos();
    }
  }

  void deleteTask(int index) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTodo(toDoList[index]['id']);
    _loadTodos();
  }

  void _editTask(int index) {
    _controller.text = toDoList[index]['title'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Update ToDo"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  final dbHelper = DatabaseHelper();
                  final updatedTodo = {
                    'id': toDoList[index]['id'],
                    'title': _controller.text,
                    'isDone': toDoList[index]['isDone'],
                    'date': toDoList[index]['date'],
                  };
                  await dbHelper.updateTodo(updatedTodo);
                  _controller.clear();
                  Navigator.of(context).pop();
                  _loadTodos();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCalendar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: TableCalendar(
                focusedDay: _calendarPopupDate,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2123, 12, 31),
                calendarFormat: _calendarFormat,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left),
                  rightChevronIcon: Icon(Icons.chevron_right),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _calendarPopupDate = selectedDay;
                    _selectedDate = selectedDay;
                    _loadTodos();
                  });
                  Navigator.of(context).pop();
                },
                selectedDayPredicate: (day) => isSameDay(day, _calendarPopupDate),
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      appBar: AppBar(
        title: const Text("ToDo"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendar,
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: toDoList.length,
              itemBuilder: (BuildContext context, index) {
                return GestureDetector(
                  onLongPress: () => _editTask(index),
                  child: TodoList(
                    taskName: toDoList[index]['title'],
                    taskCompleted: toDoList[index]['isDone'] == 1,
                    onChanged: (value) => checkBoxChanged(index),
                    deleteFunction: (context) => deleteTask(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Add New ToDo Items',
                      filled: true,
                      fillColor: Colors.deepPurple.shade200,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                    onPressed: saveNewTask,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
