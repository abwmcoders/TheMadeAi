import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:the_made_ai/request/request_service.dart';

import '../constants/assets.dart';
import '../constants/secret.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController controller = TextEditingController(text: "");
  final SpeechToText speechToText = SpeechToText();
  String recordedAudioText = "";
  bool isLoading = false;
  String modeOpenAi = "chat";
  String imageUrl = "";
  String answerText = "";
  final TextToSpeech textToSpeech = TextToSpeech();
  bool playAudio = true;

  initializeSpechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  void startListening() async {
    FocusScope.of(context).unfocus();
    await speechToText.listen(onResult: onSpeechTextResult);
    setState(() {});
  }

  void stopListening() async {
    FocusScope.of(context).unfocus();
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioText = recognitionResult.recognizedWords;
    speechToText.isListening ? null : sendRequestToOpenAi(recordedAudioText);
    print("speech result ---> $recordedAudioText");
  }

  Future<void> sendRequestToOpenAi(String userInput) async {
    stopListening();
    setState(() {
      isLoading = true;
    });

    //! send request to open ai
    await RequestService()
        .requestOpenAi(userInput, modeOpenAi, openAIAPIKey, 2)
        .then((value) {
      print("about to make request");
      print("value from request ===> $value");
      print("value body --> ${value.body}");
      setState(() {
        isLoading = false;
      });
      if (value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Api key you are using has expired or not valid"),
          ),
        );
      }
      controller.clear();
      var response = jsonDecode(value.body);
      if (modeOpenAi == "chat") {
        setState(() {
          answerText =
              utf8.decode(response["choices"][0]["text"].toString().codeUnits);
          print("answer from chat gpt ---> ${answerText}");
        });

        if (playAudio == true) {
          textToSpeech.speak(answerText);
        }
      } else {
        //! image generation
        setState(() {
          imageUrl = response["data"][0]["url"];
        });
        print(imageUrl);
      }
    }).catchError((onError) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An Error occured ---> ${onError.toString()}"),
        ),
      );
    });
  }

  @override
  void initState() {
    initializeSpechToText();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.indigoAccent.shade100, Colors.indigo])),
        ),
        title: Image.asset(
          logo,
          width: 140,
        ),
        titleSpacing: 10,
        centerTitle: false,
        actions: [
          //! chat
          Padding(
            padding: const EdgeInsets.all(5),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAi = "chat";
                });
              },
              child: Icon(
                Icons.chat,
                size: 20,
                color: modeOpenAi == "chat" ? Colors.green : Colors.white,
              ),
            ),
          ),
          //! image
          Padding(
            padding: const EdgeInsets.all(5),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAi = "image";
                });
              },
              child: Icon(
                Icons.image,
                size: 20,
                color: modeOpenAi == "image" ? Colors.green : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            //! image
            Center(
              child: InkWell(
                onTap: () {
                  speechToText.isListening ? stopListening() : startListening();
                },
                child: speechToText.isListening
                    ? Center(
                        child: LoadingAnimationWidget.beat(
                          size: 300,
                          color: speechToText.isListening
                              ? Colors.indigo
                              : isLoading
                                  ? Colors.indigo.shade400
                                  : Colors.indigo.shade200,
                        ),
                      )
                    : Image.asset(
                        ass,
                        height: 300,
                        width: 300,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            //! text field
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "How can i help you ?"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    if (controller.text != "") {
                      sendRequestToOpenAi(controller.text.toString());
                    }
                  },
                  child: AnimatedContainer(
                    padding: const EdgeInsets.all(15),
                    curve: Curves.bounceInOut,
                    decoration: const BoxDecoration(
                        shape: BoxShape.rectangle, color: Colors.indigoAccent),
                    duration: const Duration(milliseconds: 1000),
                    child: const Icon(
                      Icons.send,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            //! display result
            const SizedBox(height: 30),
            modeOpenAi == "chat"
                ? SelectableText(
                    answerText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                : modeOpenAi == "image" && imageUrl.isNotEmpty
                    ? Column(
                        children: [
                          //! display image here
                          Image.network(imageUrl),
                          //! display download option here
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () async {
                              String? downloadStatus =
                                  await ImageDownloader.downloadImage(imageUrl);

                              if (downloadStatus != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Image downloaded successfully"),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo),
                            child: Text(
                              "Download",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isLoading) {
            setState(() {
               playAudio = !playAudio;
            });
           
          }
          textToSpeech.stop();
        },
        backgroundColor: Colors.white,
        child: playAudio ? Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(sound),
        ): Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(mute),
        ),
      ),
    );
  }
}
