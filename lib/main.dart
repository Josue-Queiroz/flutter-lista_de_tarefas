import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List todoList = [];
  late Map<String, dynamic> lastRemoved;
  late int lastRemovedPos;

  @override
  void initState() {
    super.initState();

    readData().then((value) {
      setState(() {
        todoList = json.decode(value);
      });
    });
  }

  final TextEditingController todoController = TextEditingController();

  void addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = {};
      newTodo['title'] = todoController.text;
      todoController.text = '';
      newTodo['ok'] = false;

      todoList.add(newTodo);
      saveData();
    });
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      todoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });
    });

    saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: todoController,
                    decoration: const InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                TextButton(
                  style: const ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Colors.blueAccent),
                      padding: MaterialStatePropertyAll(EdgeInsets.all(15))),
                  onPressed: () {
                    addTodo();
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecond.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(todoList[index]['title']),
        value: todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(todoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (bool? value) {
          setState(() {
            todoList[index]['ok'] = value;
            saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(todoList[index]);
          lastRemovedPos = index;

          todoList.removeAt(index);
          saveData();

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Tarefa ${lastRemoved['title']} removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  todoList.insert(lastRemovedPos, lastRemoved);
                  saveData();
                });
              },
            ),
            duration: const Duration(seconds: 5),
          ));
        });
      },
    );
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(todoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return json.encode([{}]);
    }
  }
}
