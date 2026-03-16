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
                              provider.pickAudioFilesDirectory();
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
                                      title: Text("Выберите тему приложения"),
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
                                                  child: Text("Тёмная", style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),)
                                              ),

                                              TextButton(
                                                  onPressed: () {
                                                    provider.setTheme("light");
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Светлая", style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),)
                                              ),

                                              TextButton(
                                                  onPressed: () {
                                                    provider.setTheme("blueSky");
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Небесная", style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),)
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
                          text: Text("Изменить цвет заднего фона", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) => ColorPickerAlertDialog(
                                    title: Text("Изменить цвет заднего фона"),
                                    object: "background",
                                    context: context
                                )
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.075,
                        child: SettingsEntry(
                          text: Text("Изменить цвет иконок", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) => ColorPickerAlertDialog(
                                    title: Text("Изменить цвет иконок"),
                                    object: "icon",
                                    context: context
                                )
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.075,
                        child: SettingsEntry(
                          text: Text("Изменить цвет текста", style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.0175),),
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenHeight * 0.025,),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) => ColorPickerAlertDialog(
                                    title: Text("Изменить цвет текста"),
                                    object: "text",
                                    context: context
                                )
                            );
                          },
                        ),
                      ),

                    ]
                )
              ],
            ),
          )
      ),
    );
  }
}
