import 'package:flutter/material.dart';
import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:provider/provider.dart';
import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:just_audio/just_audio.dart';

class Mediateka extends StatefulWidget {
  const Mediateka({super.key});

  @override
  State<Mediateka> createState() => _MediatekaState();
}

class _MediatekaState extends State<Mediateka> {
  late final TextEditingController searchController;
  late final TextEditingController timeController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchController = TextEditingController();
    timeController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final backgroundColor = provider.colorScheme["background"];
    final iconColor = provider.colorScheme["icon"];
    final textColor = provider.colorScheme["text"];
    final bool isPlaying = provider.player.playing;
    final bool isUserMakingPlaylist = provider.isUserMakingPlaylist;
    return Scaffold(
      backgroundColor: backgroundColor,
      endDrawer: Drawer(
        width: screenWidth,
        backgroundColor: backgroundColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: ListView(
            children: [

              SizedBox(
                height: screenHeight * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Icon(Icons.alarm, color: iconColor,),
                    Text("Установить таймер на", style: TextStyle(color: textColor),),
                    SizedBox(
                        width: screenWidth * 0.075,
                        child: TextField(
                          controller: timeController,
                          style: TextStyle(color: textColor),
                          cursorColor: textColor,
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor!),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor),
                            ),
                          ),
                        ),
                      ),
                    Text("минут", style: TextStyle(color: textColor),),
                    IconButton(
                        onPressed: () {
                          if (int.tryParse(timeController.text) != null) {
                            provider.setSleepTimer(int.parse(timeController.text));
                            showNotification(context, "Таймер сна установлен на ${timeController.text} минут");
                            timeController.clear();
                          } else {
                            showNotification(context, "Молодец, тестировщик");
                            timeController.clear();
                          }
                        },
                        icon: Icon(Icons.check, color: iconColor,),
                    ),
                    IconButton(
                      onPressed: () {
                        provider.denySleepTimer();
                        showNotification(context, "Текущий таймер сна отменён");
                      },
                      icon: Icon(Icons.close, color: iconColor,),
                    ),
                  ],
                ),
              ),

              VolumeSlider(
                  context: context,
                  iconColor: iconColor!,
                  textColor: textColor,
              )

            ],
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        title: Center(child: Text(isUserMakingPlaylist ? "Выбрано(${provider.audioSourcesIndexes.length})" : "Медиатека", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        leading: provider.isUserMakingPlaylist ? SizedBox.shrink() : IconButton(
          onPressed: () {
            Navigator.pushNamed(context, "/");
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              isUserMakingPlaylist ? SizedBox.shrink()
                  : Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: SizedBox(
                  height: screenHeight * 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Row(
                        children: [

                          IconButton(
                              onPressed: (){
                                provider.switchShuffle(true);
                                showNotification(context, "Включено рандомное воспроизведение");
                              },
                              icon: Icon(Icons.shuffle, color: iconColor,)),

                          IconButton(
                              onPressed: (){
                                provider.switchShuffle(false);
                                showNotification(context, "Рандомное воспроизведение выключено");
                              },
                              icon: Icon(Icons.swap_vert, color: iconColor,)),

                          IconButton(
                              onPressed: (){
                                provider.switchShuffle(false);
                                provider.setLoopMode(provider.player.loopMode == LoopMode.all ? LoopMode.off : LoopMode.all);
                                showNotification(context, provider.player.loopMode == LoopMode.all ? "Включён цикличный режим воспроизведения" : "Цикличный режим воспроизведения выключен");
                              },
                              icon: Icon(Icons.loop, color: iconColor,)),
                        ],

                      ),

                      Row(
                        children: [

                          SizedBox(
                            width: screenWidth * 0.4,
                            child: TextField(
                              controller: searchController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "Название песни",
                              ),
                            ),
                          ),

                          IconButton(
                              onPressed: () {
                                provider.showOnlySearched(searchController.text);
                              },
                              icon: Icon(Icons.search, color: iconColor,),),
                        ],
                      ),

                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  itemCount: isUserMakingPlaylist ? provider.audioFiles.length : provider.audioSources.length,
                  itemBuilder: (BuildContext context, int index) {
                    return MediatekaListTile(
                      index: index,
                      context: context,
                      iconColor: iconColor,
                      textColor: textColor,
                      isUserMakingPlaylist: isUserMakingPlaylist,
                    );
                  }, separatorBuilder: (BuildContext context, int index) {
                    return Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 0.005 * screenHeight));
                },
                ),
              ),

              isUserMakingPlaylist ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: TextButton(
                        onPressed: () {
                          provider.addSourcesToPlaylist();
                          Navigator.pushNamedAndRemoveUntil(context, "/playlist", (route) => false);
                          provider.switchPlaylistCreationFlag();
                        },
                        child: Text("Подтвердить", style: TextStyle(color: textColor, fontSize: screenHeight * 0.025,))
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: TextButton(
                        onPressed: () {
                          provider.denyCreation();
                          Navigator.pushNamedAndRemoveUntil(context, "/playlist", (route) => false);
                          provider.switchPlaylistCreationFlag();
                          provider.clearIds();
                        },
                        child: Text("Отменить", style: TextStyle(color: textColor, fontSize: screenHeight * 0.025,))
                    ),
                  )
                ],
              )
              :  (provider.currentAudioFile != null) ? ListTile(
                leading: SizedBox(
                  width: screenWidth * 0.1,
                  child: provider.audioFiles[provider.currentAudioFile!["id"]]["picture"] != null ?
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: MemoryImage(provider.audioFiles[provider.currentAudioFile!["id"]]["picture"].data)),
                    ),
                  ) : Icon(Icons.music_note, color: iconColor, size: screenHeight * 0.04),
                ),
                title: SizedBox(
                  width: screenWidth * 0.625,
                  height: screenHeight * 0.1,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return MiniPlayer(
                              backgroundColor: backgroundColor!,
                              iconColor: iconColor!,
                              textColor: textColor,
                              context: context,
                            );
                          },
                      );
                    },
                    child: Marquee(
                      text: provider.currentAudioFile!["name"],
                      style: TextStyle(color: textColor, fontSize: screenHeight * 0.02),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: screenWidth * 0.6,
                    ),
                  ),
                ),
                trailing: SizedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      IconButton(
                          onPressed: () {
                            provider.playPrevious();
                          },
                          icon: Icon(Icons.skip_previous, color: iconColor, size: screenHeight * 0.04)
                      ),

                      IconButton(
                          onPressed: () {
                            if (isPlaying) {
                              provider.pause();
                            } else {
                              provider.play();
                            }
                          },
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: iconColor, size: screenHeight * 0.04)
                      ),

                      IconButton(
                          onPressed: () {
                            provider.playNext();
                          },
                          icon: Icon(Icons.skip_next, color: iconColor, size: screenHeight * 0.04)
                      ),
                    ],
                  ),
                ),
              ) : SizedBox.shrink(),
            ],
          )
      ),
    );
  }
}

