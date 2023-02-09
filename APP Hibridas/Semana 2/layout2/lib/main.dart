import 'package:flutter/material.dart';

void main() {
  runApp(const Midiseno());
}

class Midiseno extends StatelessWidget {
  const Midiseno({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Image.asset("assets/imagen1.jpg"),
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: const [
                      Text(
                        "El Gradioso Cerro Colorado",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Perteneciente a la Ciudad de Tehuacán",
                        style: TextStyle(color: Colors.black26),
                      )
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(
                        Icons.star,
                        color: Colors.red,
                      ),
                      Text("41")
                    ],
                  )
                ],
              ),
            ),
            const MiBarra(),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "El cerro colorado es de tehacán famoso por la santa cruz"
                "iojasdji asdoij asdoija dsoijasd oiasdj oiasdj oiasdj oasdj"
                "oiasjd oiasjd osaijd oiasjd oiasj doiasjd oiasj doiasj oasd"
                "oiasjd  asdjoi adsij asodij oasidj oasd oasd aoolaoaoaoaaad"
                "j sadj dsaoj dasioj dsajo iasdo asdoidj oaisdj asdo as oaas"
                "asd joasd joasj doiasj doiasjd oiasj doiasj doiasj asoji da",
                textAlign: TextAlign.justify,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MiBarra extends StatelessWidget {
  const MiBarra({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: const [
            Icon(
              Icons.call,
              color: Colors.blue,
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "CALL",
                style: TextStyle(color: Colors.blue),
              ),
            )
          ],
        ),
        Column(
          children: const [
            Icon(
              Icons.send,
              color: Colors.blue,
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "SEND",
                style: TextStyle(color: Colors.blue),
              ),
            )
          ],
        ),
        Column(
          children: const [
            Icon(
              Icons.share,
              color: Colors.blue,
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "SHARE",
                style: TextStyle(color: Colors.blue),
              ),
            )
          ],
        )
      ],
    );
  }
}
