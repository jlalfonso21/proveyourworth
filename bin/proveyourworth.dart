import 'dart:io';

import 'package:image/image.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

const NAME = 'Jorge Luis Alfonso Chavez';
const EMAIL = 'jlalfonso21@gmail.com';
const ABOUTME = ''' A brief history of you ''';
const String baseURL = 'https://www.proveyourworth.net/level3/';
const String basePath = './';

String postBackTo;
File imageFile;

var resume = MultipartFile.fromPath('resume', './resume.pdf');
var code = MultipartFile.fromPath('code', './bin/proveyourworth.dart');

Map<String, String> params = {};
Map<String, String> headers = {};
Client client = Client();

void updateCookie(Response response) {
  print('updating the cookie');
  var rawcookie = response.headers['set-cookie'];
  if (rawcookie == null) return;
  rawcookie = rawcookie.split(';')[0];
  headers['cookie'] = rawcookie;
}

Future<String> getPayloadUrl() async {
  print('getting payload url');
  // while (true) {
  var response = await client.get(baseURL, headers: headers);
  updateCookie(response);
  if (response.statusCode == 200) {
    var document = parse(response.body);
    var inputs = document.getElementsByTagName('input');
    inputs.forEach((Element element) {
      if (element.attributes['name'] == 'statefulhash') {
        params['username'] = NAME;
        params['statefulhash'] = element.attributes['value'];
      }
    });
    response = await client.get(
        baseURL +
            'activate?statefulhash=${params['statefulhash']}&username=$NAME',
        headers: headers);
    updateCookie(response);
    if (response.headers.containsKey('X-Payload-URL'.toLowerCase())) {
      return response.headers['X-Payload-URL'.toLowerCase()];
    }
  }
  return '';
  // }
}

Future<Image> getImage(String url) async {
  print('getting the image from payload');
  var response = await client.get(url, headers: headers);
  postBackTo = response.headers['x-post-back-to'];
  updateCookie(response);
  var img = await File('./bmw_for_life.jpg').writeAsBytes(response.bodyBytes);
  return decodeImage(img.readAsBytesSync());
}

Future<Image> signImage(Image image) async {
  print('signing the image');
  image = drawString(
    image,
    arial_14,
    20,
    20,
    '$NAME',
  );
  image = drawString(
    image,
    arial_14,
    20,
    40,
    '$EMAIL',
  );
  image = drawString(
    image,
    arial_14,
    20,
    60,
    '${params['statefulhash']}',
  );
  imageFile =
      await File('./image.jpg').writeAsBytes(JpegEncoder().encodeImage(image));
  return image;
}

Future<void> postData() async {
  print('posting the data to $postBackTo');

  // var uri = Uri.parse(postBackTo); // 301 - permanent redirect
  var uri = Uri.parse('https://www.proveyourworth.net/level3/reaper');
  var request = MultipartRequest('POST', uri);

  var image = await MultipartFile.fromPath('image', imageFile.path);

  request.fields['name'] = NAME;
  request.fields['email'] = EMAIL;
  request.fields['aboutme'] = ABOUTME;

  // request.files.addAll([image, code, resume]);
  request.files.addAll([image, await code]);

  request.headers['cookie'] = headers['cookie'];

  var response = await request.send();
  print(response.statusCode);
  response.stream.listen((value) {
    print(String.fromCharCodes(value));
  });
}

Future<void> main() async {
  var payloadURL = await getPayloadUrl();
  var image = await getImage(payloadURL);
  image = await signImage(image);
  await postData();

  print(params);
  print(headers);
}
