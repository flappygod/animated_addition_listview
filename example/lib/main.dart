import 'package:animated_addition_listview/animated_addition_listview.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnimatedAdditionTest(),
    );
  }
}

///animated addition test page
class AnimatedAdditionTest extends StatefulWidget {
  const AnimatedAdditionTest({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AnimatedAdditionTestState();
  }
}

///animated addition test page state
class _AnimatedAdditionTestState extends State<AnimatedAdditionTest> {
  ///controller
  late AnimatedAdditionListViewController<String> _controller;

  @override
  void initState() {
    ///init controller
    _controller = AnimatedAdditionListViewController<String>(
      ///provide head data
      tailDataProvider: (String? current, int count) async {
        int number = (current != null ? int.parse(current) : 0) + 1;
        List<String> dataList = [];
        for (int s = number; s < number + count; s++) {
          dataList.add(s.toString());
        }
        return dataList;
      },

      ///provide current data
      headDataProvider: (String? current, int count) async {
        int number = (current != null ? int.parse(current) : 0);
        List<String> dataList = [];
        for (int s = number - count; s < number; s++) {
          dataList.add(s.toString());
        }
        dataList.removeWhere((e) => int.parse(e) <= 0);
        return dataList;
      },

      ///data list
      dataList: ["81", "82", "83", "84", "85", "86", "87", "88", "89", "90"],

      ///delta offset
      anchorOffset: 85 * 3,
    );

    ///load next items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadHeadItems();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            _buildTestPage(),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _controller.animateToItem("10010");
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(30, 10, 30, 50),
          height: 30,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  ///build test page
  Widget _buildTestPage() {
    return AnimatedAdditionListView(
      controller: _controller,
      padding: EdgeInsets.zero,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder:
          (BuildContext context, int index, Animation<double> animation) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(-1, 0),
              end: const Offset(0, 0),
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 0.3),
              ),
            ),
            height: 85,
            child: Text(
              _controller.dataList[index],
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
      onItemShow: (List<String> dataList) {
        print(dataList.join(","));
      },
    );
  }
}
