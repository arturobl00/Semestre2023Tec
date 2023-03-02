import 'package:flutter/material.dart';

class WListViewBC extends StatelessWidget {
  WListViewBC({super.key});

  final List _post = [
          "Be sure to tune in and watch Donald Trump on Late Night with David Letterman as he presents the Top Ten List tonight!",
          "Donald Trump will be appearing on The View tomorrow morning to discuss Celebrity Apprentice and his new book Think Like A Champion!",
          "Donald Trump reads Top Ten Financial Tips on Late Show with David Letterman: http://tinyurl.com/ooafwn - Very funny!",
          "New Blog Post: Celebrity Apprentice Finale and Lessons Learned Along the Way: http://tinyurl.com/qlux5e",
          "My persona will never be that of a wallflower - I’d rather build walls than cling to them\" --Donald J. Trump",
          "Miss USA Tara Conner will not be fired - \"I've always been a believer in second chances.\" says Donald Trump",
          "Listen to an interview with Donald Trump discussing his new book, Think Like A Champion: http://tinyurl.com/qs24vl",
          "Strive for wholeness and keep your sense of wonder intact.\" --Donald J. Trump http://tinyurl.com/pqpfvm",
          "Enter the \"Think Like A Champion\" signed book and keychain contest: http://www.trumpthinklikeachampion.com/contest/",
          "When the achiever achieves, it's not a plateau, it’s a beginning.\" --Donald J. Trump http://tinyurl.com/pqpfvm",
          "Don’t be afraid of being unique - it's like being afraid of your best self.\" --Donald J. Trump http://tinyurl.com/pqpfvm",
          "We win in our lives by having a champion's view of each moment.\" --Donald J. Trump http://tinyurl.com/pqpfvm",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("List View"),
        ),
        body: Column(
          children: [
            Container(
              height: 200,
              color: Colors.blue,
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                  itemCount: _post.length,
                  itemBuilder: (context, index) {
                    return MyBlock1(
                      child: _post[index],
                    );
                  }),
            ),
          ],
        ));
  }
}

class MyBlock1 extends StatelessWidget {
  final String child;
  const MyBlock1({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          child,
          style: const TextStyle(fontSize: 20),
        ));
  }
}
