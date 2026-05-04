import 'package:chuni_player_revamped/log/logger.dart';
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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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
    final backgroundColor = provider.themeData["mediateka"]!["background"];
    final iconColor = provider.themeData["mediateka"]!["icon"];
    final textColor = provider.themeData["mediateka"]!["text"];
    final drawerBackgroundColor = provider.themeData["drawer"]!["background"];
    final drawerIconColor = provider.themeData["drawer"]!["icon"];
    final drawerTextColor = provider.themeData["drawer"]!["text"];
    final bool isPlaying = provider.player.playing;
    final bool isUserMakingPlaylist = provider.isUserMakingPlaylist;
    final bool isLoaded = provider.loaded;

    return !isLoaded ? Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: CircularProgressIndicator()),
        ],
      ),
    ) : Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        width: screenWidth * 0.5,
        backgroundColor: drawerBackgroundColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [

                DrawerListTile(
                  borderColor: drawerTextColor!,
                  child: Icon(Icons.settings, size: screenHeight * 0.05, color: iconColor,),
                ),

                DrawerListTile(
                  borderColor: drawerTextColor,
                  action: () => Navigator.pushNamed(context, "/settings"),
                  child: Text("Настройки", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
                ),

                DrawerListTile(
                  borderColor: drawerTextColor,
                  action: () => showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: provider.themeData["alert"]!["background"],
                        title: Text("Установить таймер сна", style: TextStyle(color: provider.themeData["alert"]!["text"]),),
                        actions: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm, color: provider.themeData["alert"]!["icon"], size: screenHeight * 0.05,),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                                child: SizedBox(
                                  width: screenWidth * 0.075,
                                  child: TextField(
                                    controller: timeController,
                                    style: TextStyle(color: provider.themeData["alert"]!["text"]),
                                    cursorColor: provider.themeData["alert"]!["text"],
                                    decoration: InputDecoration(
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text("минут", style: TextStyle(color: provider.themeData["alert"]!["text"], fontSize: 0.025 * screenHeight),),
                            ],
                          ),

                          Padding(padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [

                              Container(
                                width: screenWidth * 0.3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: BoxBorder.all(
                                    width: 3,
                                  )
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (int.tryParse(timeController.text) != null) {
                                      provider.setSleepTimer(int.parse(timeController.text));
                                      showNotification("Таймер сна установлен на ${timeController.text} минут");
                                      timeController.clear();
                                    } else {
                                      showNotification("Молодец, тестировщик");
                                      timeController.clear();
                                    }
                                  },
                                  icon: Icon(Icons.check, color: provider.themeData["alert"]!["icon"],),
                                ),
                              ),

                              Container(
                                width: screenWidth * 0.3,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: BoxBorder.all(
                                        width: 3
                                    )
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    provider.denySleepTimer();
                                    showNotification("Текущий таймер сна отменён");
                                  },
                                  icon: Icon(Icons.close, color: provider.themeData["alert"]!["icon"],),
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    ),
                  child: Text("Установить таймер сна", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
                ),

                DrawerListTile(
                  borderColor: drawerTextColor,
                  action: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      backgroundColor: provider.themeData["alert"]!["background"],
                      title: Text("Изменить громкость плеера", style: TextStyle(color: provider.themeData["alert"]!["text"]),),
                      actions: [
                        VolumeSlider(
                            context: context,
                            iconColor: provider.themeData["alert"]!["icon"],
                            textColor: provider.themeData["alert"]!["text"],
                        )
                      ],
                    ),
                  ),
                  child: Text("Изменить громкость плеера", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
                ),

                DrawerListTile(
                  borderColor: drawerTextColor,
                  action: () => showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: provider.themeData["alert"]!["background"],
                        title: Center(child: Text("О нас", style: TextStyle(color: provider.themeData["alert"]!["text"]),)),
                        actions: [
                          Text(
                            "Плеер разработан коммандой mp6 в рамках образовательного проекта\n\n"
                            "Разработчик: Федоров Дмитрий\n\n"
                            "Team Lead: Бочкарёв Виталий\n\n"
                            "Менеджер проекта: Тимофеев Пётр\n\n"
                            "Дизайнеры: Гынга Ярослав, Тимофеев Пётр, Куликов Артём\n\n"
                            "Тестировщики(QA): Бочкарёв Виталий, Смирнов Павел",
                            style: TextStyle(
                              fontSize: 18,
                              color: provider.themeData["alert"]!["text"],
                            ),
                          )
                        ],
                      )
                  ),
                  child: Text("О нас", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
                ),

              ],
            ),
          ),
        ),
      endDrawer: Drawer(
        width: screenWidth * 0.5,
        backgroundColor: drawerBackgroundColor,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [

            DrawerListTile(
              borderColor: drawerTextColor,
              child: Text("Меню", style: TextStyle(color: drawerTextColor, fontSize: 0.035 * screenHeight),),
            ),

            DrawerListTile(
              borderColor: drawerTextColor,
              action: () => Navigator.pushNamed(context, "/playlist"),
              child: Text("Плейлисты", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
            ),

            DrawerListTile(
              borderColor: drawerTextColor,
              action: () => Navigator.pushNamed(context, "/search&load"),
              child: Text("Поиск песни", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
            ),

            DrawerListTile(
              borderColor: drawerTextColor,
              action: () => Navigator.pushNamed(context, "/equalizer"),
              child: Text("Эквалайзер", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
            ),

            DrawerListTile(
              borderColor: drawerTextColor,
              action: () => provider.setCurrentPlaylist("favorite"),
              child: Text("Избранное", style: TextStyle(color: drawerTextColor, fontSize: 0.02 * screenHeight),),
            )

          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        title: Center(child: Text(isUserMakingPlaylist ? "Выбрано(${provider.audioSourcesIds.length})" : "Медиатека", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        leading: provider.isUserMakingPlaylist ? SizedBox.shrink() : IconButton(
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.settings, size: screenHeight * 0.05,),
        ),
        actions: [
          provider.isUserMakingPlaylist ? SizedBox.shrink() : IconButton(
              onPressed: () {
                scaffoldKey.currentState?.openEndDrawer();
              }, 
              icon: Icon(Icons.menu, size: screenHeight * 0.05,)
          )
        ],
      ),
      body: Container(
        color: provider.themeData["mediateka"]?["backgroundImage"] == null ? provider.themeData["mediateka"]!["background"] : null,
        decoration: provider.themeData["mediateka"]?["backgroundImage"] == null ? null
            :BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover,
                image: FileImage(provider.themeData["mediateka"]!["backgroundImage"],
                )
            )
        ),
        child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                isUserMakingPlaylist ? SizedBox.shrink()
                    : Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: SizedBox(
                    height: screenHeight * 0.075,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Row(
                          children: [

                            provider.isInteractingWithInput ? IconButton(
                                onPressed: () {
                                  searchController.text = "";
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  provider.setIsInteractingWithInput(false);
                                  setState(() {
                                    provider.isSearchMode = false;
                                  });
                                },
                                icon: Icon(Icons.close, color: iconColor,),
                            ) : SizedBox.shrink(),

                            provider.isInteractingWithInput ?
                              SizedBox.shrink()
                              : IconButton(
                              onPressed: (){
                                if (provider.shuffleMode) {
                                  provider.setShuffle(false);
                                  showNotification("Рандомное воспроизведение выключено");
                                } else {
                                  provider.setShuffle(true);
                                  showNotification("Включено рандомное воспроизведение");
                                }
                              },
                              icon: Container(
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: iconColor!, style: provider.shuffleMode ? BorderStyle.solid : BorderStyle.none)
                                ),
                                child: Icon(Icons.shuffle, color: iconColor,
                                )
                              )
                            ),

                            provider.isInteractingWithInput ?
                            SizedBox.shrink()
                            : IconButton(
                                onPressed: () {
                                  provider.setLoopMode(provider.player.loopMode == LoopMode.all ? LoopMode.off : LoopMode.all);
                                  showNotification(provider.player.loopMode == LoopMode.all ? "Включён цикличный режим воспроизведения" : "Цикличный режим воспроизведения выключен");
                                },
                                icon: Container(
                                    padding: EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: iconColor!, style: provider.player.loopMode == LoopMode.all ? BorderStyle.solid : BorderStyle.none)
                                    ),
                                    child: Icon(Icons.loop, color: iconColor,
                                )
                              )
                            ),
                          ],

                        ),

                        Row(
                          children: [

                            SizedBox(
                              width: provider.isInteractingWithInput ? screenWidth * 0.625 : screenWidth * 0.5,
                              child: TextField(
                                controller: searchController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: "Название песни",
                                ),
                                onTap: () {
                                  provider.setIsInteractingWithInput(true);
                                },
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

                provider.isSearchMode
                ? Expanded(
                child: ListView.separated(
                  itemCount: provider.indexesOfSearchedAudios.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SearchTile(
                      globalIndex: provider.indexesOfSearchedAudios[index],
                      context: context,
                      iconColor: iconColor!,
                      textColor: textColor,
                    );
                    }, separatorBuilder: (BuildContext context, int index) {
                      return Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 0.005 * screenHeight));
                    },
                  ),
                )
                : Expanded(
                child: ListView.separated(
                  itemCount: isUserMakingPlaylist ? provider.audioFiles.length : provider.audioSources.length,
                  itemBuilder: (BuildContext context, int index) {
                    List<int> playlistIdsList = (provider.playlists[provider.currentPlaylist] ?? provider.favoriteAudios).toList();
                    return MediatekaListTile(
                      globalIndex: playlistIdsList[index],
                      context: context,
                      iconColor: iconColor!,
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
                    child: provider.audioFiles[provider.currentId]!["picture"] != null ?
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(image: MemoryImage(provider.audioFiles[provider.currentId]!["picture"].data), fit: BoxFit.fitWidth),
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
      ),
    );
  }
}

