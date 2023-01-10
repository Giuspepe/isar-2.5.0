import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

part 'main.g.dart';

part 'main.freezed.dart';

mixin IsarId {
  int? get id;
}

@freezed
@Collection()
class Post with _$Post, IsarId {
  const Post._();

  const factory Post(
    String title,
    DateTime date,
  ) = _Post;

  factory Post.fromJson(Map<String, Object?> json) => _$PostFromJson(json);

  @override
  int? get id => Isar.autoIncrement;
}

late Isar isar;

late Future<List<Post>> posts;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  isar = kIsWeb
      ? await Isar.open(
          schemas: [PostSchema],
          inspector:
              true, // if you want to enable the inspector for debug builds
        )
      : await Isar.open(
          schemas: [PostSchema],
          directory: (await getApplicationSupportDirectory()).path,
          inspector:
              true, // if you want to enable the inspector for debug builds
        );

  final newPosts =
      List.generate(100, (index) => Post('title $index', DateTime.now()));
  await isar.writeTxn((isar) async => {await isar.posts.putAll(newPosts)});

  posts = isar.posts.where().findAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder(
            future: posts,
            builder: (context, data) {
              if (data.hasData) {
                return SingleChildScrollView(
                  child: DataTable(columns: const [
                    DataColumn(label: Text('title')),
                    DataColumn(label: Text('date'))
                  ], rows: [
                    for (final post in data.data!)
                      DataRow(cells: [
                        DataCell(Text(post.title)),
                        DataCell(Text(post.date.toString())),
                      ])
                  ]),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}
