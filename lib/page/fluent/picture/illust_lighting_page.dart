/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:bot_toast/bot_toast.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/component/fluent/ban_page.dart';
import 'package:pixez/component/null_hero.dart';
import 'package:pixez/component/fluent/painter_avatar.dart';
import 'package:pixez/component/fluent/pixiv_image.dart';
import 'package:pixez/component/selectable_html.dart';
import 'package:pixez/component/star_icon.dart';
import 'package:pixez/er/leader.dart';
import 'package:pixez/er/lprinter.dart';
import 'package:pixez/exts.dart';
import 'package:pixez/i18n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/ban_illust_id.dart';
import 'package:pixez/models/ban_tag.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/page/fluent/comment/comment_page.dart';
import 'package:pixez/page/picture/illust_about_store.dart';
import 'package:pixez/page/fluent/picture/illust_row_page.dart';
import 'package:pixez/page/picture/illust_store.dart';
import 'package:pixez/page/fluent/picture/picture_list_page.dart';
import 'package:pixez/page/fluent/picture/tag_for_illust_page.dart';
import 'package:pixez/page/fluent/picture/ugoira_loader.dart';
import 'package:pixez/page/fluent/report/report_items_page.dart';
import 'package:pixez/page/fluent/search/result_page.dart';
import 'package:pixez/page/user/user_store.dart';
import 'package:pixez/page/fluent/user/users_page.dart';
import 'package:pixez/page/fluent/zoom/photo_zoom_page.dart';
import 'package:share_plus/share_plus.dart';

class IllustLightingPage extends StatefulWidget {
  final int id;
  final String? heroString;
  final IllustStore? store;

  const IllustLightingPage(
      {Key? key, required this.id, this.heroString, this.store})
      : super(key: key);

  @override
  State<IllustLightingPage> createState() => _IllustLightingPageState();
}

class _IllustLightingPageState extends State<IllustLightingPage> {
  @override
  Widget build(BuildContext context) {
    switch (userSetting.padMode) {
      case 0:
        MediaQueryData mediaQuery = MediaQuery.of(context);
        final ori = mediaQuery.size.width > mediaQuery.size.height;
        if (ori)
          return _buildRow();
        else
          return _buildVertical();
      case 1:
        return _buildVertical();
      case 2:
        return _buildRow();
      default:
        return Container();
    }
  }

  _buildVertical() {
    return IllustVerticalPage(
      id: widget.id,
      store: widget.store,
      heroString: widget.heroString,
    );
  }

  _buildRow() {
    return IllustRowPage(
      id: widget.id,
      store: widget.store,
      heroString: widget.heroString,
    );
  }
}

class IllustVerticalPage extends StatefulWidget {
  final int id;
  final String? heroString;
  final IllustStore? store;

  const IllustVerticalPage(
      {Key? key, required this.id, this.heroString, this.store})
      : super(key: key);

  @override
  _IllustVerticalPageState createState() => _IllustVerticalPageState();
}

class _IllustVerticalPageState extends State<IllustVerticalPage>
    with AutomaticKeepAliveClientMixin {
  UserStore? userStore;
  late IllustStore _illustStore;
  late IllustAboutStore _aboutStore;
  late ScrollController _scrollController;
  late EasyRefreshController _refreshController;
  bool tempView = false;

  @override
  void initState() {
    // widget.relay.more =
    //     () => buildshowBottomSheet(context, _illustStore.illusts!);

    _refreshController = EasyRefreshController(
        controlFinishLoad: true, controlFinishRefresh: true);
    _scrollController = ScrollController();
    _illustStore = widget.store ?? IllustStore(widget.id, null);
    _illustStore.fetch();
    _aboutStore =
        IllustAboutStore(widget.id, refreshController: _refreshController);

    // Load More Detecter
    _scrollController.addListener(() {
      if (_scrollController.position.pixels + 300 >
          _scrollController.position.maxScrollExtent) {
        _refreshController.callLoad();
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant IllustVerticalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _illustStore = widget.store ?? IllustStore(widget.id, null);
      _illustStore.fetch();
      _aboutStore = IllustAboutStore(widget.id);
      LPrinter.d("state change");
    }
  }

  void _loadAbout() {
    if (mounted &&
        _scrollController.hasClients &&
        _scrollController.offset + 220 >=
            _scrollController.position.maxScrollExtent &&
        _aboutStore.illusts.isEmpty) _aboutStore.fetch();
  }

  @override
  void dispose() {
    _illustStore.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      content: Observer(builder: (_) {
        if (!tempView)
          for (var i in muteStore.banillusts) {
            if (i.illustId == widget.id.toString()) {
              return BanPage(
                name: "${I18n.of(context).illust}\n${i.name}\n",
                onPressed: () {
                  setState(() {
                    tempView = true;
                  });
                },
              );
            }
          }
        if (!tempView && _illustStore.illusts != null) {
          for (var j in muteStore.banUserIds) {
            if (j.userId == _illustStore.illusts!.user.id.toString()) {
              return BanPage(
                name: "${I18n.of(context).painter}\n${j.name}\n",
                onPressed: () {
                  setState(() {
                    tempView = true;
                  });
                },
              );
            }
          }
          for (var t in muteStore.banTags) {
            for (var t1 in _illustStore.illusts!.tags) {
              if (t.name == t1.name)
                return BanPage(
                  name: "${I18n.of(context).tag}\n${t.name}\n",
                  onPressed: () {
                    setState(() {
                      tempView = true;
                    });
                  },
                );
            }
          }
        }
        return Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            _buildContent(context, _illustStore.illusts),
            Container(
              margin: EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: ContextMenuArea(
                child: ButtonTheme(
                  child: IconButton(
                    icon: Observer(
                      builder: (_) => StarIcon(
                        state: _illustStore.state,
                      ),
                    ),
                    onPressed: _illustStore.star,
                  ),
                  data: ButtonThemeData(
                    iconButtonStyle: ButtonStyle(
                      backgroundColor: ButtonState.all(
                        FluentTheme.of(context).inactiveBackgroundColor,
                      ),
                      shadowColor: ButtonState.all(
                        FluentTheme.of(context).shadowColor,
                      ),
                      shape: ButtonState.all(CircleBorder()),
                    ),
                  ),
                ),
                builder: (context) => [
                  ListTile(
                    onPressed: _showBookMarkTag,
                    title: Text(I18n.of(context).favorited_tag),
                  ),
                ],
              ),
            )
          ],
        );
      }),
    );
  }

  Widget colorText(String text, BuildContext context) => Container(
        child: Text(
          text,
          style: TextStyle(color: FluentTheme.of(context).accentColor),
        ),
      );

  ScrollController scrollController = ScrollController();

  Widget _buildContent(BuildContext context, Illusts? data) {
    if (_illustStore.errorMessage != null) return _buildErrorContent(context);
    if (data == null)
      return Container(
        child: Center(
          child: ProgressRing(),
        ),
      );
    return EasyRefresh(
      controller: _refreshController,
      onLoad: () {
        _aboutStore.next();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (userSetting.isBangs || ((data.width / data.height) > 5))
            SliverToBoxAdapter(
                child: Container(height: MediaQuery.of(context).padding.top)),
          ..._buildPhotoList(data),
          SliverToBoxAdapter(
            child: _buildNameAvatar(context, data),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SelectionContainer.disabled(
                          child: Text(I18n.of(context).illust_id)),
                      Container(
                        width: 10.0,
                      ),
                      colorText(data.id.toString(), context),
                      Container(
                        width: 20.0,
                      ),
                      SelectionContainer.disabled(
                          child: Text(I18n.of(context).pixel)),
                      Container(
                        width: 10.0,
                      ),
                      colorText("${data.width}x${data.height}", context)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SelectionContainer.disabled(
                          child: Text(I18n.of(context).total_view)),
                      Container(
                        width: 10.0,
                      ),
                      colorText(data.totalView.toString(), context),
                      Container(
                        width: 20.0,
                      ),
                      SelectionContainer.disabled(
                          child: Text(I18n.of(context).total_bookmark)),
                      Container(
                        width: 10.0,
                      ),
                      colorText("${data.totalBookmarks}", context)
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 0,
                children: [
                  if (data.illustAIType == 2)
                    Text("${I18n.of(context).ai_generated}",
                        style: FluentTheme.of(context)
                            .typography
                            .caption!
                            .copyWith(
                                color: FluentTheme.of(context).accentColor)),
                  for (var f in data.tags) buildRow(context, f)
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableHtml(
                  data: data.caption.isEmpty ? "~" : data.caption,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectionContainer.disabled(
                child: HyperlinkButton(
                  child: Text(
                    I18n.of(context).view_comment,
                    textAlign: TextAlign.center,
                    style: FluentTheme.of(context).typography.body!,
                  ),
                  onPressed: () {
                    Leader.push(context, CommentPage(id: data.id),
                        icon: Icon(FluentIcons.comment),
                        title: Text(I18n.of(context).view_comment));
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(I18n.of(context).about_picture),
            ),
          ),
          SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  var list = _aboutStore.illusts
                      .map((element) => IllustStore(element.id, element))
                      .toList();
                  return ContextMenuArea(
                    child: IconButton(
                      onPressed: () {
                        Leader.push(
                            context,
                            PictureListPage(
                              iStores: list,
                              lightingStore: null,
                              store: list[index],
                            ));
                      },
                      icon: PixivImage(
                        _aboutStore.illusts[index].imageUrls.squareMedium,
                        enableMemoryCache: false,
                      ),
                    ),
                    builder: (context) => [
                      ListTile(
                        onPressed: () =>
                            saveStore.saveImage(_aboutStore.illusts[index]),
                        title: Text(
                          I18n.of(context).save,
                        ),
                      )
                    ],
                  );
                },
                childCount: _aboutStore.illusts.length,
              ),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3))
        ],
      ),
    );
  }

  List<Widget> _buildPhotoList(Illusts data) {
    final height = data != null
        ? ((data.height.toDouble() / data.width) *
            MediaQuery.of(context).size.width)
        : 150.0;
    return [
      if (data.type == "ugoira")
        SliverToBoxAdapter(
          child: NullHero(
            tag: widget.heroString,
            child: UgoiraLoader(
              id: widget.id,
              illusts: data,
            ),
          ),
        ),
      if (data.type != "ugoira")
        data.pageCount == 1
            ? SliverList(
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                String url = userSetting.pictureQuality == 1
                    ? data.imageUrls.large
                    : data.imageUrls.medium;
                if (data.type == "manga") {
                  if (userSetting.mangaQuality == 0)
                    url = data.imageUrls.medium;
                  else if (userSetting.mangaQuality == 1)
                    url = data.imageUrls.large;
                  else
                    url = data.metaSinglePage!.originalImageUrl!;
                }
                Widget placeWidget = Container(height: height);
                return ContextMenuArea(
                  child: IconButton(
                    onPressed: () {
                      Leader.push(
                        context,
                        PhotoZoomPage(
                          index: 0,
                          illusts: data,
                        ),
                        icon: Icon(FluentIcons.picture),
                        title:
                            Text(I18n.of(context).illust_id + ': ${data.id}'),
                      );
                    },
                    icon: NullHero(
                      tag: widget.heroString,
                      child: PixivImage(
                        url,
                        fade: false,
                        width: MediaQuery.of(context).size.width,
                        placeWidget: (url != data.imageUrls.medium)
                            ? PixivImage(
                                data.imageUrls.medium,
                                width: MediaQuery.of(context).size.width,
                                placeWidget: placeWidget,
                                fade: false,
                              )
                            : placeWidget,
                      ),
                    ),
                  ),
                  builder: (context) => [
                    if (data.metaPages.isNotEmpty)
                      ListTile(
                        title: Text(I18n.of(context).muti_choice_save),
                        leading: Icon(
                          FluentIcons.save,
                        ),
                        onPressed: () async {
                          await _showMutiChoiceDialog(data, context);
                        },
                      ),
                    ListTile(
                      leading: Icon(FluentIcons.save),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        saveStore.saveImage(data, index: 0);
                      },
                      title: Text(I18n.of(context).save),
                    ),
                    ListTile(
                      title: Text(I18n.of(context).copymessage),
                      leading: Icon(
                        FluentIcons.library,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                            text:
                                'title:${data.title}\npainter:${data.user.name}\nillust id:${widget.id}'));
                        BotToast.showText(
                            text: I18n.of(context).copied_to_clipboard);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).share),
                      leading: Icon(
                        FluentIcons.share,
                      ),
                      onPressed: () {
                        Share.share(
                            "https://www.pixiv.net/artworks/${widget.id}");
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        FluentIcons.link,
                      ),
                      title: Text(I18n.of(context).link),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                            text:
                                "https://www.pixiv.net/artworks/${widget.id}"));
                        BotToast.showText(
                            text: I18n.of(context).copied_to_clipboard);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).ban),
                      leading: Icon(FluentIcons.brightness),
                      onPressed: () {
                        muteStore.insertBanIllusts(BanIllustIdPersist(
                            illustId: widget.id.toString(), name: data.title));
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).report),
                      leading: Icon(FluentIcons.report_document),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return ContentDialog(
                              title: Text(I18n.of(context).report),
                              content: Text(I18n.of(context).report_message),
                              actions: <Widget>[
                                HyperlinkButton(
                                  child: Text(I18n.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop("CANCEL");
                                  },
                                ),
                                HyperlinkButton(
                                  child: Text(I18n.of(context).ok),
                                  onPressed: () {
                                    Navigator.of(context).pop("OK");
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                );
              }, childCount: 1))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                return ContextMenuArea(
                  child: IconButton(
                    onPressed: () {
                      Leader.push(
                        context,
                        PhotoZoomPage(
                          index: index,
                          illusts: data,
                        ),
                        icon: Icon(FluentIcons.picture),
                        title:
                            Text(I18n.of(context).illust_id + ': ${data.id}'),
                      );
                    },
                    icon: _buildIllustsItem(index, data, height),
                  ),
                  builder: (context) => [
                    if (data.metaPages.isNotEmpty)
                      ListTile(
                        title: Text(I18n.of(context).muti_choice_save),
                        leading: Icon(
                          FluentIcons.save,
                        ),
                        onPressed: () async {
                          await _showMutiChoiceDialog(data, context);
                        },
                      ),
                    ListTile(
                      leading: Icon(FluentIcons.save),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        saveStore.saveImage(data, index: index);
                      },
                      title: Text(I18n.of(context).save),
                    ),
                    ListTile(
                      title: Text(I18n.of(context).copymessage),
                      leading: Icon(
                        FluentIcons.library,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                            text:
                                'title:${data.title}\npainter:${data.user.name}\nillust id:${widget.id}'));
                        BotToast.showText(
                            text: I18n.of(context).copied_to_clipboard);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).share),
                      leading: Icon(
                        FluentIcons.share,
                      ),
                      onPressed: () {
                        Share.share(
                            "https://www.pixiv.net/artworks/${widget.id}");
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        FluentIcons.link,
                      ),
                      title: Text(I18n.of(context).link),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                            text:
                                "https://www.pixiv.net/artworks/${widget.id}"));
                        BotToast.showText(
                            text: I18n.of(context).copied_to_clipboard);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).ban),
                      leading: Icon(FluentIcons.brightness),
                      onPressed: () {
                        muteStore.insertBanIllusts(BanIllustIdPersist(
                            illustId: widget.id.toString(), name: data.title));
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: Text(I18n.of(context).report),
                      leading: Icon(FluentIcons.report_document),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return ContentDialog(
                              title: Text(I18n.of(context).report),
                              content: Text(I18n.of(context).report_message),
                              actions: <Widget>[
                                HyperlinkButton(
                                  child: Text(I18n.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop("CANCEL");
                                  },
                                ),
                                HyperlinkButton(
                                  child: Text(I18n.of(context).ok),
                                  onPressed: () {
                                    Navigator.of(context).pop("OK");
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                );
              }, childCount: data.metaPages.length)),
    ];
  }

  Center _buildErrorContent(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(':(', style: FluentTheme.of(context).typography.title),
          ),
          Text(
            '${_illustStore.errorMessage}',
            maxLines: 5,
          ),
          FilledButton(
            onPressed: () {
              _illustStore.fetch();
            },
            child: Text(I18n.of(context).refresh),
          )
        ],
      ),
    );
  }

  Widget _buildIllustsItem(int index, Illusts illust, double height) {
    if (illust.type == "manga") {
      String url;
      if (userSetting.mangaQuality == 0)
        url = illust.metaPages[index].imageUrls!.medium;
      else if (userSetting.mangaQuality == 1)
        url = illust.metaPages[index].imageUrls!.large;
      else
        url = illust.metaPages[index].imageUrls!.original;
      if (index == 0)
        return NullHero(
          child: PixivImage(
            url,
            placeWidget: PixivImage(
              illust.metaPages[index].imageUrls!.medium,
              width: MediaQuery.of(context).size.width,
              fade: false,
            ),
            width: MediaQuery.of(context).size.width,
            fade: false,
          ),
          tag: widget.heroString,
        );
      return PixivImage(
        url,
        fade: false,
        width: MediaQuery.of(context).size.width,
        placeWidget: Container(
          height: height,
          child: Center(
            child:
                Text('$index', style: FluentTheme.of(context).typography.title),
          ),
        ),
      );
    }
    return index == 0
        ? (userSetting.pictureQuality == 1
            ? NullHero(
                child: PixivImage(
                  illust.metaPages[index].imageUrls!.large,
                  placeWidget: PixivImage(
                    illust.metaPages[index].imageUrls!.medium,
                    fade: false,
                  ),
                  fade: false,
                ),
                tag: widget.heroString,
              )
            : NullHero(
                child: PixivImage(
                  illust.metaPages[index].imageUrls!.medium,
                  fade: false,
                ),
                tag: widget.heroString,
              ))
        : PixivImage(
            userSetting.pictureQuality == 0
                ? illust.metaPages[index].imageUrls!.medium
                : illust.metaPages[index].imageUrls!.large,
            fade: false,
            placeWidget: Container(
              height: 150,
              child: Center(
                child: Text('$index',
                    style: FluentTheme.of(context).typography.title),
              ),
            ),
          );
  }

  Widget buildRow(BuildContext context, Tags f) {
    return ContextMenuArea(
      child: GestureDetector(
        onTap: () {
          Leader.push(
            context,
            ResultPage(
              word: f.name,
              translatedName: f.translatedName ?? "",
            ),
            icon: Icon(FluentIcons.show_results),
            title: Text(I18n.of(context).tag + ' #${f.name}'),
          );
        },
        child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
                text: "#${f.name}",
                children: [
                  TextSpan(
                    text: " ",
                    style: FluentTheme.of(context).typography.caption,
                  ),
                  TextSpan(
                      text: "${f.translatedName ?? "~"}",
                      style: FluentTheme.of(context).typography.caption)
                ],
                style: FluentTheme.of(context)
                    .typography
                    .caption!
                    .copyWith(color: FluentTheme.of(context).accentColor))),
      ),
      builder: (context) => [
        ListTile(
          title: Text(I18n.of(context).ban),
          onPressed: () {
            muteStore.insertBanTag(BanTagPersist(
                name: f.name, translateName: f.translatedName ?? ""));
          },
        ),
        ListTile(
          title: Text(I18n.of(context).bookmark),
          onPressed: () {
            bookTagStore.bookTag(f.name);
          },
        ),
        ListTile(
          title: Text(I18n.of(context).copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: f.name));
            showSnackbar(
                context,
                Snackbar(
                  content: Text(I18n.of(context).copied_to_clipboard),
                ));
          },
        ),
      ],
    );
  }

  Widget _buildNameAvatar(BuildContext context, Illusts illust) {
    if (userStore == null)
      userStore = UserStore(illust.user.id, user: illust.user);
    return Observer(builder: (_) {
      Future.delayed(Duration(seconds: 2), () {
        _loadAbout();
      });
      return ContextMenuArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
                child: Container(
                  height: 70,
                  width: 70,
                  child: Stack(
                    children: <Widget>[
                      Center(
                        child: SizedBox(
                          height: 70,
                          width: 70,
                          child: Container(
                            decoration: illust != null
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: userStore!.isFollow
                                        ? Colors.yellow
                                        : FluentTheme.of(context).accentColor,
                                  )
                                : BoxDecoration(),
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: illust.user.profileImageUrls.medium +
                              this.hashCode.toString(),
                          child: PainterAvatar(
                            url: illust.user.profileImageUrls.medium,
                            id: illust.user.id,
                            onTap: () async {
                              await Leader.push(
                                context,
                                UsersPage(
                                  id: illust.user.id,
                                  userStore: userStore,
                                  heroTag: this.hashCode.toString(),
                                ),
                                icon: Icon(FluentIcons.account_browser),
                                title: Text(I18n.of(context).painter_id +
                                    '${illust.user.id}'),
                              );
                              _illustStore.illusts!.user.isFollowed =
                                  userStore!.isFollow;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(8.0)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      illust.title,
                      style:
                          TextStyle(color: FluentTheme.of(context).accentColor),
                    ),
                    Container(
                      height: 4.0,
                    ),
                    Hero(
                      tag: illust.user.name + this.hashCode.toString(),
                      child: Text(
                        illust.user.name,
                        style: FluentTheme.of(context).typography.body,
                      ),
                    ),
                    Text(
                      illust.createDate.toShortTime(),
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        builder: (context) => [
          ListTile(
            title: Text(I18n.of(context).follow),
            onPressed: userStore!.follow,
          ),
        ],
      );
    });
  }

  Future _showMutiChoiceDialog(Illusts illust, BuildContext context) async {
    List<bool> indexs = [];
    bool allOn = false;
    for (int i = 0; i < illust.metaPages.length; i++) {
      indexs.add(false);
    }
    final result = await showBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(illust.title),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        itemBuilder: (context, index) {
                          final data = illust.metaPages[index];
                          return Container(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ContextMenuArea(
                                child: IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      indexs[index] = !indexs[index];
                                    });
                                  },
                                  icon: Stack(
                                    children: [
                                      PixivImage(
                                        data.imageUrls!.squareMedium,
                                        placeWidget: Container(
                                          child: Center(
                                            child: Text(index.toString()),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Visibility(
                                          visible: indexs[index],
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(
                                              FluentIcons.checkbox,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                builder: (context) => [
                                  ListTile(
                                    title: Text('Open in zoom'),
                                    onPressed: () => Leader.push(
                                      context,
                                      PhotoZoomPage(
                                          index: index, illusts: illust),
                                      icon: Icon(FluentIcons.picture),
                                      title: Text(I18n.of(context).illust_id +
                                          '${illust.id}'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: illust.metaPages.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3),
                      ),
                    ),
                    ListTile(
                      leading: Icon(!allOn
                          ? FluentIcons.checkbox_fill
                          : FluentIcons.checkbox),
                      title: Text(I18n.of(context).all),
                      onPressed: () {
                        allOn = !allOn;
                        for (var i = 0; i < indexs.length; i++) {
                          indexs[i] = allOn;
                        }
                        setDialogState(() {});
                      },
                    ),
                    ListTile(
                      leading: Icon(FluentIcons.save),
                      title: Text(I18n.of(context).save),
                      onPressed: () {
                        Navigator.of(context).pop("OK");
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        });
    switch (result) {
      case "OK":
        {
          saveStore.saveChoiceImage(illust, indexs);
        }
    }
  }

  Future<void> _showBookMarkTag() async {
    final result =
        await Leader.pushWithScaffold(context, TagForIllustPage(id: widget.id));
    if (result is Map) {
      LPrinter.d(result);
      String restrict = result['restrict'];
      List<String>? tags = result['tags'];
      _illustStore.star(restrict: restrict, tags: tags, force: true);
    }
  }

  @override
  bool get wantKeepAlive => false;
}
