import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    String interruptionMode = provider.ignoreInterruptions ? "Да" : "Нет";
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(child: Text("Настройки", style: TextStyle(color: Colors.white))),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
            child: ListView(
              children: [

                Text("НАСТРОЙКИ ПУТЕЙ", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),

                SettingSector(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.075,
                        child: SettingsEntry(
                            text: Text("Изменить директорию с аудиофайлами", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                            icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                            onTap: () {
                              // provider.pickAudioFilesDirectory();
                            }
                        ),
                      ),
                    ]
                ),

                Text("НАСТРОЙКИ ВНЕШНЕГО ВИДА", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                SettingSector(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.075,
                        child: SettingsEntry(
                            text: Text("Выбрать тему для приложения", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: provider.themeData["alert"]!["background"],
                                      title: Text("Выберите тему приложения", style: TextStyle(color: provider.themeData["alert"]!["text"],),),
                                      actions: [

                                        Align(
                                          alignment: AlignmentGeometry.centerStart,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TextButton(
                                                  onPressed: (){
                                                    provider.setTheme("dark");
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Тёмная", style: TextStyle(color: provider.themeData["alert"]!["text"], fontSize: screenHeight * 0.02),)
                                              ),

                                              TextButton(
                                                  onPressed: () {
                                                    provider.setTheme("light");
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Светлая", style: TextStyle(color: provider.themeData["alert"]!["text"], fontSize: screenHeight * 0.02),)
                                              ),

                                              TextButton(
                                                  onPressed: () {
                                                    provider.setTheme("blueSky");
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Небесная", style: TextStyle(color: provider.themeData["alert"]!["text"], fontSize: screenHeight * 0.02),)
                                              )

                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                              );
                            },
                            icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                        ),
                      )
                    ]
                ),

                Text("РАСШИРЕННЫЕ НАСТРОЙКИ ВНЕШНЕГО ВИДА", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),

                SettingSector(
                    children: [

                      SizedBox(
                        height: screenHeight * 0.075,
                        child: SettingsEntry(
                          text: Text("Настроить тему приложения", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                          onTap: () {

                            showDialog(
                                context: context,
                                builder: (BuildContext context) => ThemeCreationAlertDialog(
                                  context: context
                                )
                            );

                          },
                        ),
                      ),
                    ]
                ),

                Text("НАСТРОЙКИ ПОВЕДЕНИЯ ПЛЕЕРА", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                SettingSector(children: [
                    SizedBox(
                      height: screenHeight * 0.075,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Игнорировать прерывания", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                              SizedBox(
                                width: screenWidth * 0.3,
                                height: screenHeight * 0.05,
                                child: DropdownMenu(
                                  initialSelection: interruptionMode,
                                  textStyle: TextStyle(
                                    color: Colors.white, // Твой основной цвет из темы
                                    fontSize: 14,
                                  ),
                                  inputDecorationTheme: InputDecorationTheme(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    constraints: BoxConstraints(
                                      maxHeight: screenHeight * 0.05,
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry(
                                        value: "Нет",
                                        label: "Нет",
                                    ),

                                    DropdownMenuEntry(
                                      value: "Да",
                                      label: "Да",
                                    )
                                  ],
                                  onSelected: (newValue) {
                                    provider.setInterruptionMode(newValue == "Да" ? true : false);
                                    showNotification("Изменения вступят в силу после перезапуска");
                                  },


                                ),
                              )
                          ]
                        ),
                      ),
                    ),
                  ]
                ),
              ],
            ),
          )
      ),
    );
  }
}
