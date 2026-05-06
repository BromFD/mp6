import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:mp6/provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:mp6/log/logger.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Этот виджет отвечает за пункты меню на стартовом экране
class MenuEntry extends StatefulWidget {
  final VoidCallback? action;
  final Widget? child;
  final BoxDecoration? decoration;

  const MenuEntry({
    super.key,
    required this.child,
    required this.action,
    this.decoration,
  });

  @override
  State<MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<MenuEntry> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.8),
      onTapUp: (_) async {
        await Future.delayed(Duration(milliseconds: 50));
        setState(()  {
          scale = 1.0;
        });
      },
      onTapCancel: () => setState(() => scale = 1.0),
      onTap: () async {
        await Future.delayed(Duration(milliseconds: 100));
        widget.action == null ? null : widget.action!();
      },
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: 50),
        curve: Curves.easeIn,
        child: Container(
            decoration: widget.decoration ?? BoxDecoration(),
            child: widget.child,
        ),
      ),
    );
  }
}

// Этот виджет отвечает за отдельные пункты настроек
class SettingsEntry extends StatelessWidget {
  final Widget? text;
  final Icon? icon;
  final GestureTapCallback? onTap;

  const SettingsEntry({
    super.key,
    required this.text,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints){
          double width = constraints.maxWidth;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: text ?? SizedBox.shrink(),
              ),
              icon ?? SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

//Этот виджет объединяет отдельные пункты настроек воедино
class SettingSector extends StatelessWidget {
  final List<Widget> children;
  const SettingSector({
    super.key,
    required this.children
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Color(0xFF555555),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        )
    );
  }
}

// Этот виджет, визуализация каждого отдельного трека в медиатеке
class MediatekaListTile extends StatefulWidget {
  final int globalIndex;
  final BuildContext context;
  final Color textColor;
  final Color iconColor;
  final bool isUserMakingPlaylist;
  const MediatekaListTile({
    super.key,
    required this.globalIndex,
    required this.context,
    required this.textColor,
    required this.iconColor,
    required this.isUserMakingPlaylist,
  });

  @override
  State<MediatekaListTile> createState() => _MediatekaListTileState();
}

class _MediatekaListTileState extends State<MediatekaListTile> {

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    //final int globalIndex = int.parse((provider.audioSources[widget.index] as IndexedAudioSource).tag.id);
    final Duration duration = Duration(milliseconds: provider.audioFiles[widget.globalIndex]?["duration"].toInt());
    final String minutes = duration.inMinutes.toString();
    final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    bool isSelected = provider.audioSourcesIds.contains(widget.globalIndex);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Container(
          decoration: isSelected ? BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
          ) : BoxDecoration(),
          child: ListTile(
            leading: SizedBox(
              width: width * 0.2,
              child: provider.audioFiles[widget.globalIndex]?["picture"] != null ?
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: MemoryImage(provider.audioFiles[widget.globalIndex]?["picture"].data), fit: BoxFit.fitWidth),
                ),
              ) :
              Icon(Icons.music_note, color: widget.iconColor,),),
            title: SizedBox(
              width: width * 0.625,
              child: Text(provider.audioFiles[widget.globalIndex]?["name"], style: TextStyle(color: widget.textColor),)),
            trailing: SizedBox(
              width: width * 0.175,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    child: Text("$minutes:$seconds", style: TextStyle(color: widget.textColor),)
                  ),
                  SizedBox(
                    width: width * 0.1,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: provider.isUserMakingPlaylist ? SizedBox.shrink() :
                      IconButton(
                        icon: Icon(Icons.more_vert, color: widget.iconColor,),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: provider.themeData["alert"]!["background"],
                                  title: Text("Настройки аудио", style: TextStyle(color: provider.themeData["alert"]!["text"],),),
                                  actions: [

                                    Column(
                                      children: [
                                        TextButton(
                                            onPressed: (){
                                              provider.addedAudio.add(widget.globalIndex);
                                              provider.switchAddToExistingPlaylistFlag();
                                              Navigator.pushNamed(context, "/playlist");
                                            },
                                            child: Text("Добавить аудио в плейлист", style: TextStyle(color: provider.themeData["alert"]!["text"],),)
                                        ),

                                        provider.currentPlaylist != "main" ? TextButton(
                                            onPressed: () async {
                                              await provider.removeFromExistingPlaylist(widget.globalIndex);
                                              Navigator.pop(context);
                                            },
                                            child: Text("Удалить аудио из плейлиста", style: TextStyle(color: provider.themeData["alert"]!["text"],),)
                                        ) : SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                );
                              }
                          );
                        },
                      )
                    ),
                  ),
                ],
              ),
            ),
            onTap: () async {
              if (widget.isUserMakingPlaylist) {
                if (isSelected) {
                  provider.removeAudioFromPlaylist(widget.globalIndex);
                } else {
                  provider.addAudioToPlaylist(widget.globalIndex);
                }
              } else {
                if (provider.readyToSetAudio) {
                  provider.setSources(initialIndex: provider.sourcePositionTracker[widget.globalIndex] ?? 0);
                } else {
                  provider.setAudioFile(provider.sourcePositionTracker[widget.globalIndex] ?? 0);
                }
              }
            },
          ),
        );
      },
    );
  }
}

// Визуализация найденного трека
class SearchTile extends StatefulWidget {
  final int globalIndex;
  final BuildContext context;
  final Color textColor;
  final Color iconColor;
  const SearchTile({
    super.key,
    required this.globalIndex,
    required this.context,
    required this.textColor,
    required this.iconColor,
  });

  @override
  State<SearchTile> createState() => _SearchTileState();
}

class _SearchTileState extends State<SearchTile> {

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    //final int globalIndex = int.parse((provider.audioSources[widget.index] as IndexedAudioSource).tag.id);
    final Duration duration = Duration(milliseconds: provider.audioFiles[widget.globalIndex]?["duration"].toInt());
    final String minutes = duration.inMinutes.toString();
    final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    bool isSelected = provider.audioSourcesIds.contains(widget.globalIndex);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Container(
          decoration: isSelected ? BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
          ) : BoxDecoration(),
          child: ListTile(
            leading: SizedBox(
              width: width * 0.2,
              child: provider.audioFiles[widget.globalIndex]?["picture"] != null ?
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: MemoryImage(provider.audioFiles[widget.globalIndex]?["picture"].data), fit: BoxFit.fitWidth),
                ),
              ) :
              Icon(Icons.music_note, color: widget.iconColor,),),
            title: SizedBox(
                width: width * 0.625,
                child: Text(provider.audioFiles[widget.globalIndex]?["name"], style: TextStyle(color: widget.textColor),)),
            trailing: SizedBox(
              width: width * 0.175,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      child: Text("$minutes:$seconds", style: TextStyle(color: widget.textColor),)
                  ),
                  SizedBox(
                    width: width * 0.1,
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: provider.isUserMakingPlaylist ? SizedBox.shrink() :
                        IconButton(
                          icon: Icon(Icons.more_vert, color: widget.iconColor,),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: provider.themeData["alert"]!["background"],
                                    title: Text("Настройки аудио", style: TextStyle(color: provider.themeData["alert"]!["text"],),),
                                    actions: [

                                      Column(
                                        children: [
                                          TextButton(
                                              onPressed: (){
                                                provider.addedAudio.add(widget.globalIndex);
                                                provider.switchAddToExistingPlaylistFlag();
                                                Navigator.pushNamed(context, "/playlist");
                                              },
                                              child: Text("Добавить аудио в плейлист", style: TextStyle(color: provider.themeData["alert"]!["text"],),)
                                          ),

                                          provider.currentPlaylist != "main" ? TextButton(
                                              onPressed: () async {
                                                await provider.removeFromExistingPlaylist(widget.globalIndex);
                                                Navigator.pop(context);
                                              },
                                              child: Text("Удалить аудио из плейлиста", style: TextStyle(color: provider.themeData["alert"]!["text"],),)
                                          ) : SizedBox.shrink(),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                            );
                          },
                        )
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () async {
                provider.readyToSetAudio ? provider.setSources(initialIndex: provider.sourcePositionTracker[widget.globalIndex]!) : provider.setAudioFile(provider.sourcePositionTracker[widget.globalIndex]!);
                provider.indexesOfSearchedAudios = [];
                FocusManager.instance.primaryFocus?.unfocus();
                provider.setIsInteractingWithInput(false);
                setState(() {
                  provider.isSearchMode = false;
                });
            }
          ),
        );
      },
    );
  }
}

// Виджет представляющий собой мини плеер, будет всплывать снизу экрана
class MiniPlayer extends StatefulWidget {
  final BuildContext context;
  const MiniPlayer({
    super.key,
    required this.context,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final bool isPlaying = provider.player.playing;
    final bool inFavorites = provider.favoriteAudios.contains(provider.currentId);
    final backgroundColor = provider.themeData["mini"]!["background"];
    final iconColor = provider.themeData["mini"]!["icon"];
    final textColor = provider.themeData["mini"]!["text"];

    return Container(
      color: provider.themeData["mini"]?["backgroundImage"] == null ? backgroundColor : null,
      decoration: provider.themeData["mini"]?["backgroundImage"] == null ? null
          : BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.cover,
              image: provider.themeData["mini"]!["backgroundImage"],
          )
      ),
      height: screenHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Padding(padding: EdgeInsetsGeometry.only(top: screenHeight * 0.05)),

          SizedBox(
            height: screenHeight * 0.1,
            width: screenWidth * 0.8,
            child: Marquee(
              text: provider.currentAudioFile!["name"],
              style: TextStyle(color: textColor, fontSize: screenHeight * 0.035,),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: screenWidth * 0.8,
            ),
          ),

        InkWell(
          child: provider.audioFiles[provider.currentId]!["picture"] != null
              ? Container(
            width: screenHeight * 0.4,
            height: screenHeight * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: MemoryImage(provider.audioFiles[provider.currentId]!["picture"].data), fit: BoxFit.cover),
            ),
          )
              : SizedBox(
              width: screenHeight * 0.4,
              height: screenHeight * 0.5,
              child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Icon(Icons.music_note, color: iconColor)
            )
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: provider.themeData["alert"]!["background"],
                  title: Center(child: Text("Настройки трека", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),
                  actions: [
                    SizedBox(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.1,
                      child: SettingsEntry(
                          text: Text("Добавить или изменить\n изображение у трека", style: TextStyle(fontSize: 18, color: provider.themeData["alert"]!["text"],),),
                          onTap: () async {
                            await provider.setAudioPicture();
                          },
                          icon: Icon(Icons.arrow_forward_ios, color: provider.themeData["alert"]!["icon"],)
                      ),
                    ),
                    SizedBox(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.1,
                      child: SettingsEntry(
                          text: Text("Убрать изображение\n у трека", style: TextStyle(fontSize: 18, color: provider.themeData["alert"]!["text"],),),
                          onTap: () async {
                            await provider.removeAudioPicture();
                          },
                          icon: Icon(Icons.arrow_forward_ios, color: provider.themeData["alert"]!["icon"],)
                      ),
                    )
                  ],
              )
            );
          },
        ),

          SizedBox(
            height: screenHeight * 0.1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: MiniPlayerSlider(
                context: context,
                iconColor: iconColor,
                textColor: textColor,
              ),
            ),
          ),

          SizedBox(
            height: screenHeight * 0.075,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                IconButton(
                    onPressed: () {
                      provider.player.loopMode == LoopMode.off ? provider.setLoopMode(LoopMode.one) : provider.setLoopMode(LoopMode.off);
                      showNotification(provider.player.loopMode == LoopMode.one ? 'Включён режим повтора' : "Режим повтора выключен");
                    },
                    icon: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: iconColor!, style: provider.player.loopMode == LoopMode.one ? BorderStyle.solid : BorderStyle.none)
                        ),
                        child: Icon(Icons.repeat_one, color: iconColor, size: screenHeight * 0.04,
                        )
                    )
                ),

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

                IconButton(
                    onPressed: () {
                      if (inFavorites) {
                        provider.removeFromFavorites(provider.currentId!);
                      } else {
                        provider.addToFavorites(provider.currentId!);
                      }
                    },
                    icon: Icon(inFavorites ? Icons.favorite : Icons.favorite_border_outlined, color: iconColor, size: screenHeight * 0.04)
                ),

              ],
            ),
          ),

          SizedBox(
            height: screenHeight * 0.075,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                IconButton(
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
                        child: Icon(Icons.loop, color: iconColor, size: screenHeight * 0.04,
                        )
                    )
                ),

                IconButton(
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
                        child: Icon(Icons.shuffle, color: iconColor, size: screenHeight * 0.04,
                        )
                    )
                ),

              ],
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: screenWidth * 0.15))
        ],
      ),
    );
  }
}

// Слайдер для перемотки аудио
class MiniPlayerSlider extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  const MiniPlayerSlider({
    super.key,
    required this.context,
    required this.iconColor,
    required this.textColor,
  });

  @override
  State<MiniPlayerSlider> createState() => _MiniPlayerSliderState();
}

class _MiniPlayerSliderState extends State<MiniPlayerSlider> {
  double dragValue = 0.0;
  bool isDragged = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    final Duration duration = provider.player.duration ?? Duration.zero;
    return StreamBuilder( // Обновляет слайдер каждый раз как меняется позиция
        stream: provider.player.positionStream,
        builder: (context, asyncSnapshot) {
          return Row(
            children: [

              Text(isDragged ? "${dragValue.toInt() ~/ 60}:${(dragValue.toInt() % 60).toString().padLeft(2, '0')}"
                  : "${provider.player.position.inMinutes}:${(provider.player.position.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(color: widget.textColor),
              ),

              Expanded(
                child: Slider(
                  value: isDragged ? dragValue : provider.player.position.inSeconds.toDouble(), // Текущее положение точки зависит от положения пальца при перемещении и от текущей позиции трека в состоянии поеоя
                  min: 0.0,
                  max: duration.inSeconds.toDouble(),
                  onChangeStart: (value) {
                    isDragged = true;
                    provider.pause();
                  },
                  onChangeEnd: (value) {
                    provider.player.seek(Duration(seconds: dragValue.toInt()));
                    provider.play();
                    isDragged = false;
                  },
                  onChanged: (value) {
                    setState(() {
                      dragValue = value;
                    });
                  },
                  activeColor: widget.iconColor,
                  thumbColor: widget.iconColor,
                ),
              ),

              Text("${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(color: widget.textColor),
              ),

            ],
          );
        }
    );
  }
}

// Виджет отображающий созданный плейлист
class PlaylistTile extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  final int index;
  const PlaylistTile({
    super.key,
    required this.textColor,
    required this.iconColor,
    required this.context,
    required this.index,
  });

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final String name = provider.playlists.keys.elementAt(widget.index);
    final isUserAddToExistingPlaylist = provider.isUserAddToExistingPlaylist;
    return ListTile(
      leading: Icon(Icons.playlist_play, color: widget.iconColor, size: screenHeight * 0.05,),
      title: Text(name, style: TextStyle(color: widget.textColor, fontSize: screenHeight * 0.025),),
      trailing: isUserAddToExistingPlaylist ? SizedBox.shrink() :
      IconButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: provider.themeData["alert"]!["background"],
                    title: Center(child: Text("Настройки плейлиста", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),
                    actionsAlignment: MainAxisAlignment.start,
                    actions: [

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                              onPressed: () {

                                Navigator.pop(context);
                                showDialog(context: context,
                                    builder: (context){
                                      return AlertDialog(
                                        backgroundColor: provider.themeData["alert"]!["background"],
                                        title: Center(child: Text("Вы действительно хотите удалить плейлист $name?", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),
                                        actions: [

                                          TextButton(
                                              onPressed: () {
                                                provider.deletePlaylist(name);
                                                Navigator.pop(context);
                                              },
                                              child: Text("Да", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),

                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text("Нет", style: TextStyle(color: provider.themeData["alert"]!["text"],),))

                                        ],
                                      );
                                    }
                                );

                              },
                            child: Text("Удалить плейлист", style: TextStyle(color: provider.themeData["alert"]!["text"],),)
                          ),

                          TextButton(
                              onPressed: () {

                                Navigator.pop(context);
                                showDialog(context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: provider.themeData["alert"]!["background"],
                                        title: Center(child: Text("Переименуйте ваш плейлист $name", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),
                                        actions: [

                                          Column(
                                            children: [

                                              SizedBox(
                                                width: screenWidth * 0.5,
                                                child: TextField(
                                                  controller: nameController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Введите имя плейлиста',
                                                    border: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
                                                    ),
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
                                                    ),
                                                  ),
                                                  style: TextStyle(color: provider.themeData["alert"]!["text"]),
                                                  cursorColor: provider.themeData["alert"]!["text"],
                                                ),
                                              ),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [

                                                  TextButton(
                                                      onPressed: () async {
                                                        await provider.renamePlaylist(name, nameController.text);
                                                        nameController.clear();
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Подтвердить", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),

                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        nameController.clear();
                                                      },
                                                      child: Text("Отмена", style: TextStyle(color: provider.themeData["alert"]!["text"],),)),

                                                ],
                                              ),

                                            ],
                                          )

                                        ],
                                      );
                                    }
                                );
                              },
                              child: Text("Переименовать плейлист", style: TextStyle(color: provider.themeData["alert"]!["text"]),)
                          ),
                        ],
                      ),

                    ],
                  );
                }
            );
          },
          icon: Icon(Icons.more_vert, color: widget.iconColor, size: screenHeight * 0.05,)
      ),
      onTap: () async {

        if (isUserAddToExistingPlaylist) {
          provider.addedAudio.add(name);
          provider.addToExistingPlaylist();
          Navigator.pushNamedAndRemoveUntil(widget.context, "/", (route) => false);
          provider.switchAddToExistingPlaylistFlag();
        } else {
          await provider.setCurrentPlaylist(name);
          await provider.disableShuffle();
          Navigator.pushNamed(widget.context, "/");
        }
      },
    );
  }
}

// Вызывает уведомление с каким-то определённым сообщением
Future<void> showNotification(String message) async {
  final currentState = navigatorKey.currentState;
  print(currentState);
  if (currentState == null) return;
  OverlayState? overlayState = currentState.overlay;
  OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          top: screenHeight * 0.025,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: -100.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(screenHeight * 0.02),
                      child: Text(message, style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),),
                    )
                ),
              ),
            ),
          ),
        );
      }
  );
  overlayState!.insert(overlayEntry);
  await Future.delayed(Duration(seconds: 2));
  overlayEntry.remove();
}

// Слайдер громкости
class VolumeSlider extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  const VolumeSlider({
    super.key,
    required this.context,
    required this.iconColor,
    required this.textColor,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    return StreamBuilder( // Обновляет слайдер каждый раз как меняется громкость
        stream: provider.player.volumeStream,
        builder: (context, asyncSnapshot) {
          return Row(
            children: [
              Icon(Icons.volume_down, color: widget.iconColor,),
              
              Expanded(
                child: Slider(
                  value: provider.player.volume, // Текущее положение точки зависит от положения пальца при перемещении и от текущей громкости трека
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      provider.player.setVolume(value);
                    });
                  },
                  activeColor: widget.iconColor,
                  thumbColor: widget.iconColor,
                ),
              ),
              
              Text("${(provider.player.volume * 100)~/1}", style: TextStyle(color: widget.textColor),)
              
            ],
          );
        }
    );
  }
}

// Элемент списка найденный в интернете песен
class YTSearchTile extends StatelessWidget {
  final BuildContext context;
  final int index;
  final Color textColor;
  final Color iconColor;
  const YTSearchTile({
    super.key,
    required this.context,
    required this.index,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    return LayoutBuilder(
      builder: (context, constraints){
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        return ListTile(
          title: Text(provider.foundAudioFiles[index]["name"] ?? "Not found", style: TextStyle(color: textColor),),
          subtitle: Text("Автор: ${provider.foundAudioFiles[index]["artist"] ?? "Not Found"}", style: TextStyle(color: textColor),),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              IconButton(
                  onPressed: () async {
                    await provider.downloadAudio(provider.foundAudioFiles[index]["trackPageUrl"]!, provider.foundAudioFiles[index]["name"]!, index);
                  },
                  icon: provider.indexOfDownloaded == index && provider.downloadProgress != 0 ?
                      CircularProgressIndicator(
                        value: provider.downloadProgress,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      )
                      : Icon(Icons.download, color: iconColor,),
              ),

              IconButton(
                onPressed: () async {
                  if (provider.player.sequenceState.currentSource?.tag.id != "f$index") {
                    await provider.playFound(provider.foundAudioFiles[index]["trackPageUrl"]!, provider.foundAudioFiles[index]["name"]!, index);
                  } else {
                    if (provider.player.playing) {
                      provider.pause();
                    } else {
                      provider.play();
                    }
                  }
                },
                icon: Icon(provider.player.playing && provider.player.sequenceState.currentSource?.tag.id == "f$index" ? Icons.pause : Icons.play_arrow, color: iconColor,),
              ),

            ],
          ),
          trailing: Text(
              "${provider.foundAudioFiles[index]["duration"]}",
              style: TextStyle(color: textColor)
          ),
        );
      },
    );
  }
}

// Слайдер полосы эквалайзера
class BandSlider extends StatefulWidget {
  final BuildContext context;
  final AndroidEqualizerBand band;
  final Color textColor;
  final Color iconColor;
  const BandSlider({
    super.key,
    required this.context,
    required this.band,
    required this.textColor,
    required this.iconColor
  });

  @override
  State<BandSlider> createState() => _BandSliderState();
}

class _BandSliderState extends State<BandSlider> {
  double dragValue = 0.0;
  bool isDragged = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    return StreamBuilder( // Обновляет слайдер каждый раз как меняется позиция
        stream: widget.band.gainStream,
        builder: (context, asyncSnapshot) {
          return RotatedBox(
            quarterTurns: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    dragValue == 0 ? widget.band.gain.toStringAsFixed(2) : dragValue.toStringAsFixed(2),
                    style: TextStyle(color: widget.textColor,
                    ),
                  ),
                ),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 15.0,
                    thumbSize: WidgetStateProperty.fromMap(WidgetStateMap.from({
                      WidgetState.any : Size(15, 35)
                    })),
                    thumbShape: HandleThumbShape(),
                    trackGap: 10,
                    trackShape: GappedSliderTrackShape(),
                  ),
                  child: SizedBox(
                    width: screenHeight * 0.5,
                    child: Slider(
                      value: dragValue == 0 ? widget.band.gain : dragValue,
                      // Текущее положение точки зависит от положения пальца при перемещении и от текущей позиции трека в состоянии поеоя
                      min: provider.parameters!.minDecibels,
                      max: provider.parameters!.maxDecibels,
                      onChangeStart: (value) {
                        isDragged = true;
                      },
                      onChangeEnd: (value) {
                        widget.band.setGain(dragValue);
                        dragValue = 0;
                        isDragged = false;
                      },
                      onChanged: (value) {
                        setState(() {
                          dragValue = value;
                        });
                      },
                      activeColor: widget.iconColor,
                      thumbColor: widget.iconColor,
                    ),
                  ),
                ),

                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    '${
                        widget.band.centerFrequency.toStringAsFixed(0).length > 3
                            ? (widget.band.centerFrequency / 1000).toStringAsFixed(1)
                            : widget.band.centerFrequency.toStringAsFixed(0)} '
                        '${widget.band.centerFrequency.toStringAsFixed(0).length > 3
                            ? 'кГц'
                            : 'Гц'}',
                    style: TextStyle(color: widget.textColor,
                    ),
                  ),
                ),

              ],
            ),
          );
        }
    );
  }
}

// Элемент drawer в Медиатеке
class DrawerListTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? action;
  final Color borderColor;
  const DrawerListTile({
    super.key,
    required this.child,
    required this.borderColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      style: ListTileStyle.drawer,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      title: child,
      onTap: action,
    );
  }
}

// ВСЁ АЛЕРТ ДИАЛОГИ

// Этот виджет - всплывающее окно, вызывается когда пользователь нажимает на пункты настроек с выбором цвета
class ThemeCreationAlertDialog extends StatefulWidget {
  final BuildContext context;
  const ThemeCreationAlertDialog({
    super.key,
    required this.context,
  });

  @override
  State<ThemeCreationAlertDialog> createState() => _ThemeCreationAlertDialogState();
}

class _ThemeCreationAlertDialogState extends State<ThemeCreationAlertDialog> {
  Color pickerColor = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(widget.context).size.width;
    double screenHeight = MediaQuery.of(widget.context).size.height;
    final provider = widget.context.watch<PlayerProvider>();
    final segmentMap = {
      "Медиатека": "mediateka",
      "Боковые меню" : "drawer",
      "Плейлисты" : "playlist",
      "Поиск песни" : "onlineSearch",
      "Эквалайзер" : "equalizer",
      "Всплывающие окна" : "alert",
      "Мини плеер" : "mini",
    };
    final elementMap = {
      Icons.format_paint : "background",
      Icons.wallpaper : "backgroundImage",
      Icons.text_format : "text",
      Icons.music_note : "icon",
    };
    return Dialog(
      backgroundColor: provider.themeData["alert"]!["background"],
      insetPadding: EdgeInsets.all(10),
      child: SizedBox(
        height: screenHeight * 0.8,
        width: screenWidth * 0.8,
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.035, bottom: screenHeight * 0.05, left: screenWidth * 0.075, right: screenWidth * 0.075),
              child: Text("Тут можно изменить цвет фона, фоновое изображение, цвет текста и цвет иконок для каждого отдельного раздела приложения", style: TextStyle(fontSize: screenHeight * 0.0225, color: provider.themeData["alert"]!["text"],),),
            ),
            for (String segment in ["Медиатека", "Боковые меню", "Плейлисты", "Поиск песни", "Эквалайзер", "Мини плеер", "Всплывающие окна"]) ...[

              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text(segment, style: TextStyle(fontSize: screenHeight * 0.03, color: provider.themeData["alert"]!["text"],),)),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (IconData element in [Icons.format_paint, Icons.wallpaper, Icons.text_format, Icons.music_note]) ...[
                    if (!((segmentMap[segment] == "alert" || segmentMap[segment] == "drawer")  && elementMap[element] == "backgroundImage"))
                      Container(
                        width: screenWidth * 0.175,
                        height: screenWidth * 0.175,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 3,
                              color: elementMap[element] == "backgroundImage" ? provider.themeData["alert"]!["background"].computeLuminance() > 0.5 ? Colors.black : Colors.white : provider.themeData[segmentMap[segment]]![elementMap[element]],
                            )
                        ),
                        child: InkWell(
                          child: Icon(element, color: provider.themeData["alert"]!["background"].computeLuminance() > 0.5 ? Colors.black : Colors.white),
                          onTap: () async {
                            if (elementMap[element] == "backgroundImage") {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: provider.themeData["alert"]!["background"],
                                    title: Text("Изменение заднего фона", style: TextStyle(color: provider.themeData["alert"]!["text"]),),
                                    actions: [

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [

                                          TextButton(
                                            onPressed: () async {
                                              await provider.changeThemeData(null, segmentMap[segment]!, elementMap[element]!, context);
                                              Navigator.pop(context);
                                            },
                                            child: Text("Убрать", style: TextStyle(color: provider.themeData["alert"]!["text"]),),
                                          ),

                                          TextButton(
                                            onPressed: () async {
                                              FilePickerResult? chosenFile = await FilePicker.platform.pickFiles(
                                                type: FileType.image,
                                              );

                                              if (chosenFile != null) {
                                                Directory appDir = await getApplicationDocumentsDirectory();
                                                String imageName = chosenFile.files.first.name;
                                                String backgroundImage = "${appDir.path}/$imageName";
                                                await File(chosenFile.files.first.path!).copy(backgroundImage);
                                                await provider.changeThemeData(backgroundImage, segmentMap[segment]!, elementMap[element]!, context);
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: Text("Поставить", style: TextStyle(color: provider.themeData["alert"]!["text"]),),
                                          )

                                        ],
                                      )

                                    ],
                                  )
                              );
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setInnerState) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        child: SizedBox(
                                          height: screenHeight * 0.8,
                                          width: screenWidth * 0.8,
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: Center(child: Text("Выберите цвет", style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.03),),),
                                              ),

                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ColorPicker(
                                                          pickerColor: pickerColor,
                                                          onColorChanged: (color) {
                                                            changeColor(color);
                                                            setInnerState(() {});
                                                          },
                                                        ),
                                                        Padding(
                                                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0225),
                                                          child: ColorPickerInput(
                                                            pickerColor,
                                                            (color) {
                                                              changeColor(color);
                                                              setInnerState(() {});
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              ElevatedButton(
                                                child: Text('Подтвердить', style: TextStyle(color: Colors.black),),
                                                onPressed: () async {
                                                  final hexCode = '0x${pickerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
                                                  await provider.changeThemeData(int.parse(hexCode), segmentMap[segment]!, elementMap[element]!, context);
                                                  Navigator.of(context).pop();
                                                },
                                              ),

                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  )
                            );
                          }
                        },
                      ),
                    )
                  ]
                ],
              ),

              Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.05),)
            ],
          ],
        ),
      ),
    );
  }
}

// Окно высплывающее при создании плейлиста
class PlaylistCreationAlertDialog extends StatefulWidget {
  final BuildContext context;
  const PlaylistCreationAlertDialog({
    super.key,
    required this.context,
  });

  @override
  State<PlaylistCreationAlertDialog> createState() => _PlaylistCreationAlertDialogState();
}

class _PlaylistCreationAlertDialogState extends State<PlaylistCreationAlertDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nameController = TextEditingController();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(widget.context).size.width;
    double screenHeight = MediaQuery.of(widget.context).size.width;
    final provider = widget.context.watch<PlayerProvider>();
    return AlertDialog(
      title: Text("Создать новый плейлист", style: TextStyle(color: provider.themeData["alert"]!["text"],),),
      backgroundColor: provider.themeData["alert"]!["background"],
      actions: <Widget>[
        SizedBox(
          width: screenWidth * 0.5,
          child: TextField(
            controller: nameController,
            style: TextStyle(color: provider.themeData["alert"]!["text"]),
            cursorColor: provider.themeData["alert"]!["text"],
            decoration: InputDecoration(
              labelText: 'Введите название вашего плейлиста',
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: provider.themeData["alert"]!["text"]),
                ),
              ),
            ),
          ),
        IconButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.switchPlaylistCreationFlag();
              provider.createPlaylist(nameController.text);
              nameController.clear();
              Navigator.pushNamed(context, "/");
            },
            icon: Icon(Icons.check, color: provider.themeData["alert"]!["icon"],)
        ),
      ],
    );
  }
}