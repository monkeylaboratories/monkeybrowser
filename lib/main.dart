import 'package:flutter/material.dart';
import 'package:monkeybrowser/video_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/driver.dart' as driver;

void main() {
  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final List<String> _dispMaxCountList = [
    "20",
    "50",
    "100",
    "200",
    "500"
  ]; // 表示件数リスト
  String _selectDispMaxCount = "20"; // 表示件数（選択）

  List<MovieInfo> _movieList; // 動画リスト
  String _searchWord; // 検索キーワード
  bool _loading = false; // ローディング状態

  // 動画リスト取得処理
  void getMovieList() async {
    // 入力されていない場合は処理なし
    if (_searchWord == null || _searchWord.length == 0) {
      return;
    }

    // ローディング状態にする
    setState(() {
      _loading = true;
    });

    // 検索結果ページを取得
    final url = "https://jp.pornhub.com/video/search?search=" + _searchWord;
    final client = driver.HtmlDriver();
    await client.setDocumentFromUri(Uri.parse(url));

    // 検索件数文章取得
    final searchCountElm = client.document.querySelector(".showingCounter");
    if (searchCountElm == null) {
      // 取得結果無しの場合
      setState(() {
        _loading = false;
      });
      return;
    }

    // 検索結果件数を取得
    int searchCount = 0;
    var regExp = new RegExp('[0-9]{2,}');
    Iterable<Match> matches = regExp.allMatches(searchCountElm.text.trim());
    if (matches.isNotEmpty) {
      searchCount = int.parse(
          matches.last.group(0).toString()); // 検索結果件数：「1~XXを表示中(XXの中から)」から抽出

    }
    // 最大表示件数以上の場合、最大表示件数を設定
    if (searchCount > int.parse(_selectDispMaxCount)) {
      searchCount = int.parse(_selectDispMaxCount);
    }
    // 表示ページ数取得
    int dispPageCount = (searchCount / 20).ceil(); // ページ数：検索結果件数 / 20件 (繰上)

    // 検索結果のリスト取得
    List<MovieInfo> tmpList = new List<MovieInfo>();
    for (var i = 0; i < dispPageCount; i++) {
      // ２ページ目以降の場合、URLを再取得
      if (i > 0) {
        final nextUrl = url + "&page=" + (i + 1).toString();
        await client.setDocumentFromUri(Uri.parse(nextUrl));
      }

      // 動画情報の一覧を取得
      final elements = client.document
          .querySelectorAll("#videoSearchResult > .pcVideoListItem");

      // タイトル、画像、URLを取得
      for (final elem in elements) {
        final titleElm = elem.querySelector(".title");
        final imageElm = elem
            .querySelector(".videoPreviewBg > img")
            .getAttribute('data-src');
        final urlElm = "https://jp.pornhub.com" +
            elem.querySelector("a").getAttribute('href');
        tmpList.add(new MovieInfo(titleElm.text.trim(), urlElm, imageElm));
      }
    }

    // 取得した動画リストを設定
    setState(() {
      _movieList = tmpList;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: HexColor("1B1B1B"),
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Icon(
              Icons.camera,
              color: HexColor("ff9900"),
            ),
          ),
          title: Text(
            "Monkey Browser",
            style: GoogleFonts.mPlus1p(),
            textAlign: TextAlign.justify,
          ),
        ),
        body: Container(
            color: Colors.black,
            child: Column(
              children: <Widget>[
                // *** 検索条件入力部 ***
                Row(
                  children: <Widget>[
                    // 表示件数プルダウン
                    DropdownButton<String>(
                        itemHeight: 55,
                        value: _selectDispMaxCount,
                        selectedItemBuilder: (context) {
                          return _dispMaxCountList.map((String item) {
                            return Center(
                              child: SizedBox(
                                height: 20,
                                width: 35,
                                child: Text(
                                  item,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: _dispMaxCountList.map((String item) {
                          return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ));
                        }).toList(),
                        onChanged: (String newValue) {
                          setState(() {
                            _selectDispMaxCount = newValue;
                          });
                        }),
                    // 検索条件入力蘭
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(3.0),
                        child: Container(
                          height: 40,
                          decoration: new BoxDecoration(
                            color: Colors.white,
                          ),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search),
                              hintText: "input search word.",
                            ),
                            onChanged: (text) {
                              setState(() {
                                _searchWord = text;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    // 検索ボタン
                    Container(
                      height: 45,
                      padding: EdgeInsets.all(3),
                      child: RaisedButton(
                          child: Text(
                            "SEARCH",
                            style: TextStyle(color: HexColor("1B1B1B")),
                          ),
                          color: HexColor("ff9900"),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onPressed: _loading
                              ? null
                              : () {
                            getMovieList(); // 動画リスト取得
                          }),
                    ),
                  ],
                ),
                // *** インジケータ表示部 ***
                _loading ? LinearProgressIndicator() : Container(),
                // *** 動画リスト表示部 ***
                Expanded(
                  child: _movieList == null
                      ? Text(
                    "Please input search word!!",
                    style: TextStyle(color: Colors.white),
                  )
                      : ListView.builder(
                    itemCount: _movieList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: EdgeInsets.all(5.0),
                        // 引数にURLを設定
                        onTap: () async {
                          await Navigator.of(context).pushNamed('/movie',
                              arguments: '${_movieList[index].url}');
                        },
                        // 画像・タイトル表示
                        leading:
                        Image.network('${_movieList[index].image}'),
                        title: Text(
                          '${_movieList[index].title}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        trailing: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.arrow_right,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )),
      ),
      // 画面遷移設定
      // ※PageTransitionを使用
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/movie':
            return PageTransition(
                child: VideoPage(),
                type: PageTransitionType.rightToLeftWithFade,
                settings: settings);
            break;
          default:
            return null;
        }
      },
    );
  }
}

// 動画情報クラス
class MovieInfo {
  final String title, url, image;
  MovieInfo(this.title, this.url, this.image);
}

// カラーコード指定
class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}