import 'package:mp6/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mp6/custom_widgets.dart';
import 'package:provider/provider.dart';

class SearchAndLoad extends StatefulWidget {
  const SearchAndLoad({super.key});

  @override
  State<SearchAndLoad> createState() => _SearchAndLoadState();
}

class _SearchAndLoadState extends State<SearchAndLoad> {
  late final TextEditingController titleController;
  late final savedProvider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    titleController = TextEditingController();
    savedProvider = Provider.of<PlayerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    if (savedProvider.player.sequenceState?.currentSource?.tag.id[0] == "f") {
      savedProvider.setCurrentPlaylist(savedProvider.currentPlaylist);
      Future.microtask(() => savedProvider.pause());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final backgroundColor = provider.themeData["onlineSearch"]!["background"];
    final iconColor = provider.themeData["onlineSearch"]!["icon"];
    final textColor = provider.themeData["onlineSearch"]!["text"];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Center(child: Text("Скачать аудио", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: provider.themeData["onlineSearch"]?["backgroundImage"] == null ? null :
            DecorationImage(
                fit: BoxFit.cover,
                image: provider.themeData["onlineSearch"]!["backgroundImage"],
            )
        ),
        child: Center(
          child: Column(
            children: [

              SizedBox(
                width: screenWidth * 0.8,
                child: Row(
                  children: [

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.005),
                        child: TextField(
                          controller: titleController,
                          style: TextStyle(color: textColor),
                          cursorColor: textColor,
                          decoration: InputDecoration(
                            hintText: "Введите название трека",
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor!),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor),
                            ),
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                        onPressed: () async {
                          await provider.searchAudioFiles(titleController.text);
                          titleController.clear();
                        },
                        icon: Icon(Icons.search, color: iconColor,)
                    )
                  ],
                ),
              ),

              Padding(padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015)),

              Expanded(
                child: SizedBox(
                  width: screenWidth * 0.8,
                  child: ListView.builder(
                      itemCount: provider.foundAudioFiles.length,
                      itemBuilder: (BuildContext context, int index) {
                        return YTSearchTile(
                          context: context,
                          index: index,
                          iconColor: iconColor!,
                          textColor: textColor,
                        );
                      }
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

