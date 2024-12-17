import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map myMap = Map();
  List<Flowers> flores = [];
  List? _outputs;
  File? _image;
  bool isLoading = false;

  Future <Map<String, dynamic>> fetchData() async{
    final response = await http.get(Uri.parse("https://raw.githubusercontent.com/Azazel17/pokehub/master/flores.json"));
    print(response.statusCode);
    if (response.statusCode == 200){
      myMap = json.decode(response.body);
      print("Descarga");
      print(response.body);
      Iterable i = myMap["Flowers"];
      flores = i.map((m) => Flowers.FromJson(m)).toList();
    } else {
      throw Exception("Failed to fetch data");
    }
    throw '';
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    loadModel().then((value) {
      setState(() {
        isLoading = false;
      });
    });
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Teacheable Machine"),
        centerTitle: true,
      ),
      body: isLoading
          ? Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      )
          : Container(

        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null ? Container() : Image.file(_image!),
            SizedBox(
              height: 20,
            ),
            _outputs!= null
                ? Text(
              "${flores[_outputs![0]["index"]].name} \n ${flores[_outputs![0]["index"]].description} \n ${_outputs![0]["confidence"]}",
              style: TextStyle(
                color: Colors.black,
                fontSize: 30.0,
                background: Paint()..color = Colors.white,
              ),
            )
                : Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickedImage,
        child: const Icon(Icons.image),
      ),
    );
  }

  //cargar modelo
  loadModel() async {
    await Tflite.loadModel(model: "assets/model_unquant.tflite", labels: "labels.txt");
  }

  // cargar imagen
  pickedImage() async {
    final ImagePicker _picker = ImagePicker();
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }
    setState(() {
      isLoading = true;
      _image = File (image.path.toString());
    });
    classifyImage(File(image.path));
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);
    setState(() {
      isLoading = false;
      _outputs = output!;
      print(_outputs);
      print(_outputs![0]["index"]);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Tflite.close();
    super.dispose();
  }
}
class Flowers{
  String? id;
  String? name;
  String? description;

  Flowers({required this.id, required this.name, required this.description});
  Flowers.FromJson(Map<String, dynamic> json){
    id = json["id"];
    name = json["name"];
    description = json["description"];
  }
  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;

    return data;
  }
}
