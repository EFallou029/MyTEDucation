import 'package:flutter/material.dart';
import 'talk_repository.dart';
import 'models/talk.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDucation',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.title = 'MyTEDucation'
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Talk>> _talks;
  int page = 1;
  bool init = true;

  @override
  void initState() {
    super.initState();
    _talks = initEmptyList();
    init = true;
  }

  void _getTalksByTag() async {
    setState(() {
      init = false;
      _talks = getTalksByTag("education", page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("MyTEDucation"),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: (init)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("Benvenuti in MyTEDucation"),
                    const Text("L'argomento di quest'anno è education"),
                    ElevatedButton(
                      child: const Text('Visualizza Talk'),
                      onPressed: () {
                        page = 1;
                        _getTalksByTag();
                      },
                    ),
                  ],
                )
                : FutureBuilder<List<Talk>>(
                  future: _talks,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Scaffold(
                        body: ListView.builder(
                          padding: const EdgeInsets.all(2),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                        child:
                                          Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.red)
                                            ),
                                            child: 
                                              ListTile(
                                                leading:
                                                  FadeInImage.assetNetwork(
                                                        placeholder: 'assets/images/loader.gif',
                                                        image: snapshot.data![index].imageurl,
                                                      ),
                                                trailing: const Icon(Icons.arrow_right_rounded),
                                                subtitle:
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          overflow: TextOverflow.fade,
                                                          maxLines: 1,
                                                          snapshot.data![index].mainSpeaker
                                                        ),
                                                      ),
                                                      Text(snapshot.data![index].views)
                                                    ],
                                                  ),
                                                title:
                                                  Text(
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    snapshot.data![index].title)),
                                          ),
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyTalk(snapshot.data![index].imageurl, snapshot.data![index].watchnext, snapshot.data![index].title, snapshot.data![index].id)))
                                      );
                          },
                        ),
                        floatingActionButtonLocation:
                          FloatingActionButtonLocation.centerDocked,
                        floatingActionButton: FloatingActionButton(
                          child: const Icon(Icons.arrow_drop_down),
                                    onPressed: () {
                                      imageCache.clear();
                                      imageCache.clearLiveImages();
                                      if (snapshot.data!.length >= 6) {
                                        page = page + 1;
                                        _getTalksByTag();
                                      }
                                    },
                        ),
                        bottomNavigationBar: BottomAppBar(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.home),
                                          onPressed: () {
                                            setState(() {
                                              init = true;
                                              page = 1;
                                              _controller.text = "";
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                  ));
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }

                        return const CircularProgressIndicator();
                        },
                      ),
                    ),
                  );
                }
              }

class MyTalk extends StatefulWidget {
  const MyTalk(this.imageurl, this.watchnext, this.title, this.id, {
    super.key
  });

  final String title;
  final String imageurl;
  final List watchnext;
  final String id;

  @override
  State<MyTalk> createState() => _MyTalkState();
}

class _MyTalkState extends State<MyTalk> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.title;
    String imageurl = widget.imageurl;
    List watchnext = widget.watchnext;
    String id = widget.id;

    
    return Scaffold(
        appBar: AppBar(
          title: const Text("MyTEDucation"),
        ),
        body: 
          Column(
            children: [
              Expanded(
                flex: 4,
                child: 
                  Center(
                    child: 
                      Column(children: [
                        FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loader.gif',
                        image: imageurl,
                      ),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],) 

              )
            ),
              Expanded(
                flex: 6,
                child: 
                  Column(
                    
                    children: [
                      const Text("Video correlati"),
                      for(int i = 0; i < watchnext.length; i++)
                      Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red)
                                    ),
                        child: ListTile(
                          title: Text(watchnext[i]["watch_next_title"]),
                          subtitle: Text("views:\t${watchnext[i]["watch_next_views"]}"),
                          trailing: const Icon(Icons.arrow_right_rounded),
                        ),
                      )
                        
                    ],
                  )
              ),
            ],
          ),
          floatingActionButtonLocation:
                          FloatingActionButtonLocation.centerDocked,
                        floatingActionButton: FloatingActionButton(
                          child: const Icon(Icons.arrow_right_alt_outlined),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyRecommendation(id)))

                        ),
      );
    }
  }
