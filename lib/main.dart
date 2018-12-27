import 'dart:async';
import 'dart:convert';
import 'package:flutter_sparkline/flutter_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(new MaterialApp(
    home: new HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  var _isLoading = true;
  List data = List<double>.generate(78, (i) => 0);
  var subData = [];
  var tempData = [];
  var watch = [];
  var watchVal = [];
  Map map;
  Map parse;
  Map investments;
  var stocks = [];
  var quant = [];
  var doubList;
  var api = "I99SYY531EJ79C3S";
  Iterable inReverse;
  var doubListInReverse;
  int pos = 0;
  double unIn;
  double last;

  Future<String> getData(date) async {
    var client = new http.Client();
    String jsonData = await DefaultAssetBundle.of(context).loadString("assets/data.json");
    final jsonResult = json.decode(jsonData);
    investments = jsonResult["000001"]["Trading"]["Investments"];
    unIn = jsonResult["000001"]["Trading"]["Uninvested Funds"];
    watch = jsonResult["000001"]["Trading"]["Watchlist"];
    investments.forEach((k,v) {
      stocks.add(k);
      quant.add(v);
    });
    for (var item in stocks) {
      await client.get("https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=" + item +"&interval=5min&outputsize=full&apikey=" + api).then((response) {
        tempData = [];
        map = json.decode(response.body);
        parse = map["Time Series (5min)"];
        void iterateMapEntry(key, value) {
          if (key.contains("2018-12-26")) {
            value = parse[key]["4. close"];
            tempData.add(double.parse(value) * quant[pos]);
          }
        }
        parse.forEach(iterateMapEntry);
        doubList = new List<double>.from(tempData);
        inReverse = doubList.reversed;
        doubListInReverse = inReverse.toList();
        subData.add(doubListInReverse);
      });
      pos++;
    }
    for (var item in watch) {
      await client.get("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=" + item + "&apikey=" + api).then((response) {
        map = json.decode(response.body);
        var val = map["Global Quote"]["05. price"].toString();
        watchVal.add(double.parse(val));
      });
    }
    watchVal = new List<double>.from(watchVal);
    print(watchVal);
    for (var item0 in subData) {
      pos = 0;
      for (var item1 in item0) {
        data[pos] = data[pos] + item1;
        pos++;
      }
    }
    print(subData);
    pos = 0;
    for (var item in data) {
      data[pos] = item + unIn;
      pos++;
      last = item + unIn;
    }
    print(data);
    data.add(last);
    this.setState(() {
      _isLoading = false;
    });
    client.close();
    return "Success!";
  }

  @override
  void initState() {
    super.initState();
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formatted = formatter.format(now);
    this.getData(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child:
        _isLoading
          ? new CircularProgressIndicator()
          : new CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.greenAccent,
            elevation: 0.0,
            pinned: true,
            expandedHeight: 100.0,
            flexibleSpace: FlexibleSpaceBar(

              title: Text("\$" + last.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  //color: Colors.tealAccent,
                  //fontSize: 35
              )),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildGraph(),
              _trading(),
              _watchList(),
              _buildListItem(),
              _buildListItem(),
              _buildListItem(),
            ]),
          )
        ],
      ),
    )
    );
  }

  Widget _buildListItem() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'List header',
              style: Theme.of(context).textTheme.body2,
            ),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.only(top: 8.0),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Nested list item $index',
                style: Theme.of(context).textTheme.body1,
              ),
            );
          },
          itemCount: 4,
          shrinkWrap: true, // todo comment this out and check the result
          physics: ClampingScrollPhysics(), // todo comment this out and check the result
        ),
      ],
    );
  }
  Widget _trading() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'Trading',
              style: Theme.of(context).textTheme.body2,
            ),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.only(top: 8.0),
          itemCount: stocks == null ? 0 : stocks.length,
          itemBuilder: (context, index) {
            return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: new Card(
                  child: Text(
                    stocks[index] + " " + quant[index].toString() + " " + (subData[index][subData[index].length-1]/quant[index]).toString(),
                    style: Theme.of(context).textTheme.body2,
                  ),
                )
            );
          },
          shrinkWrap: true, // todo comment this out and check the result
          physics: ClampingScrollPhysics(), // todo comment this out and check the result
        ),
      ],
    );
  }
  Widget _watchList() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'Watching',
              style: Theme.of(context).textTheme.body2,
            ),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.only(top: 8.0),
          itemCount: watch == null ? 0 : watch.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: new Card(
                child: Text(
                  watch[index] + " " + watchVal[index].toString(),
                  style: Theme.of(context).textTheme.body2,
                ),
              )
            );
          },
          shrinkWrap: true, // todo comment this out and check the result
          physics: ClampingScrollPhysics(), // todo comment this out and check the result
        ),
      ],
    );
  }
  Widget _buildGraph() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Align(
            alignment: Alignment.center,
            child:
            new Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1.0,
                  color: Colors.grey,
                ),
                borderRadius: BorderRadius.all(
                    Radius.circular(4.0),
                ),
              ),
              width: 600.0,
              height: 240.0,
              padding: EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0, bottom: 4.0),
              child: new Sparkline(
                data: data,
                lineColor: Colors.greenAccent,
/*                fillMode: FillMode.below,
                fillGradient: new LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.tealAccent, Colors.transparent],
                ),*/
              ),
            ),
          ),
        ),
      ],
    );
  }
}