import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:ebooks/models/pdf_tile.dart';
import 'package:ebooks/pages/nav_pdf.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/models/get_books_info_02.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailBookPage extends StatefulWidget {
  final Books2 bookInfo;
  final int index;
  const DetailBookPage({Key? key, required this.bookInfo, required this.index})
      : super(key: key);

  @override
  State<DetailBookPage> createState() => _DetailBookPageState();
}

class _DetailBookPageState extends State<DetailBookPage> {
  String mainHost = CallApi().getHost();
  double _diskSpace = 0;
  bool lowStorage = false;
  var parts = [];
  var chapters = [];
  var lessons = [];
  var bookCoverUrl = '';
  bool isButtonEnabled = true;
  bool isButtonEnabled2 = true;
  List<Future<void>> futures = [];
  var lessonLength = 0;
  var existBook = false;

  checkIfBookExist() async {
    if (mounted) {
      existBook = await fileExist(widget.bookInfo.title);
    }
  }

  Future<void> initDiskSpacePlus() async {
    double diskSpace = 0;

    diskSpace = await DiskSpacePlus.getFreeDiskSpace ?? 0;

    setState(() {
      _diskSpace = diskSpace;
      if (_diskSpace < 1000.00) {
        setState(() {
          lowStorage = true;
        });
      } else {
        lowStorage = false;
      }
    });
  }

  @override
  void initState() {
    getToken();
    initDiskSpacePlus();
    _fetchParts();
    checkIfBookExist();
    super.initState();
  }

  getToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final json = preferences.getString('token');
    if (json == null || json.isEmpty) {
      redirectToSignIn();
    }
  }

  void redirectToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
        (Route<dynamic> route) => false);
  }

  Future<bool> fileExist(String folderName) async {
    final Directory appDir = await getApplicationSupportDirectory();
    // const folderName = 'SampleBook';
    final Directory appDirFolder = Directory("${appDir.path}/$folderName/");
    if (await appDirFolder.exists()) {
      // File imageFile = File("$appDir/${widget.bookInfo.title}/cover_image");
      // if (await imageFile.exists()) {
      //   setState(() {
      //     imgPathLocal = imageFile.path;
      //   });
      // }
      //if folder already exists return path
      return true;
    } else {
      //if folder not exists create folder and then return its path
      return false;
    }
  }

  downloadImage(String foldr, String filename, String imgUrl) async {
    String host = "$mainHost$imgUrl";
    var savePath = '$foldr$filename';
    // print(savePath);
    var dio = Dio();
    dio.interceptors.add(LogInterceptor());
    try {
      var response = await dio.get(
        host,
        //Received data with List<int>
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      var file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
      // print("image dowloaded successfully");
    } catch (e) {
      debugPrint(e.toString());
      // print("image failed to download");
    }
  }

  _fetchParts() async {
    CallApi().getPublicData('bookchapter2/${widget.bookInfo.bookid}').then(
      (response) {
        if (mounted) {
          setState(
            () {
              var results = json.decode(response.body);
              // print(results);
              parts = results['parts'] ?? [];
              // print(parts);
              chapters = results['chapters'] ?? [];
              // print(chapters);
              lessons = results['lessons'] ?? [];
              bookCoverUrl = results['bookcover'] ?? '';
              // print(bookCoverUrl);
              // print(lessons);
              lessonLength = lessons.length;
              // print(lessonLength);
            },
          );
        }
      },
    );
  }

  String getFileExtension(String url) {
    // Find the last occurrence of the dot (.)
    int dotIndex = url.lastIndexOf('.');

    // If a dot is found and it's not the last character of the URL, return the extension
    if (dotIndex != -1 && dotIndex < url.length - 1) {
      String extension = url.substring(dotIndex);
      return extension;
    }

    // If no dot is found or it's the last character, return an empty string as the extension
    return '';
  }

  _downloadPdf() async {
    try {
      final Directory appDir = await getApplicationSupportDirectory();
      var imgPathLocal = "${appDir.path}/${widget.bookInfo.title}/cover_image";
      if (existBook) {
        EasyLoading.show(status: "Preparing...");
        saveCurrentBook(widget.bookInfo.title);
        navigateToMainNav(imgPathLocal);
      } else {
        final Directory appDirFolder =
            Directory("${appDir.path}/${widget.bookInfo.title}/");
        final Directory bookNewFolder =
            await appDirFolder.create(recursive: true);
        downloadImage(bookNewFolder.path, "cover_image", bookCoverUrl);

        if (parts.isNotEmpty) {
          for (var part in parts) {
            // print(part);
            final Directory partDirFolder =
                Directory("${bookNewFolder.path}${part['title']}/");
            final Directory newPart =
                await partDirFolder.create(recursive: true);
            if (chapters.isNotEmpty) {
              for (var chapter in chapters) {
                if (chapter['partid'] != null &&
                    chapter['partid'] == part['id']) {
                  final Directory chapDirFolder =
                      Directory("${newPart.path}${chapter['title']}/");
                  final Directory newChap =
                      await chapDirFolder.create(recursive: true);
                  if (lessons.isNotEmpty) {
                    for (var lesson in lessons) {
                      if (lesson['chapterid'] != null &&
                          lesson['chapterid'] == chapter['id']) {
                        if (lesson['path'] != null &&
                            lesson['path'].isNotEmpty) {
                          for (var lessonFileItem in lesson['path']) {
                            if (getFileExtension(lessonFileItem['filepath'])
                                    .toLowerCase() ==
                                '.pdf') {
                              EasyLoading.show(
                                  status:
                                      "Downloading ${lessonFileItem['content']}");
                              if (mounted) {
                                setState(() {
                                  futures.add(
                                    downloadPdFiles(
                                      lessonFileItem['filepath'],
                                      lessonFileItem['content'],
                                      '${newChap.path}${lessonFileItem['content']}',
                                    ),
                                  );
                                });
                              }
                            } else {
                              print("Skipping not a pdf!");
                            }
                          }
                          if (futures.isNotEmpty) {
                            await Future.wait(futures);
                          } else {
                            EasyLoading.showToast("No Content");
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          EasyLoading.dismiss();
          saveCurrentBook(widget.bookInfo.title);
          navigateToMainNav("${bookNewFolder.path}cover_image");
        } else {
          if (chapters.isNotEmpty) {
            for (var chapter in chapters) {
              final Directory chapDirFolder =
                  Directory("${bookNewFolder.path}${chapter['title']}/");
              final Directory newChap =
                  await chapDirFolder.create(recursive: true);
              if (lessons.isNotEmpty) {
                for (var lesson in lessons) {
                  if (lesson['chapterid'] != null &&
                      lesson['chapterid'] == chapter['id']) {
                    if (lesson['path'] != null && lesson['path'].isNotEmpty) {
                      for (var lessonFileItem in lesson['path']) {
                        EasyLoading.show(
                            status: "Downloading ${lessonFileItem['content']}");
                        if (mounted) {
                          setState(() {
                            futures.add(
                              downloadPdFiles(
                                lessonFileItem['filepath'],
                                lessonFileItem['content'],
                                '${newChap.path}${lessonFileItem['content']}',
                              ),
                            );
                          });
                        }
                      }
                      if (futures.isNotEmpty) {
                        await Future.wait(futures);
                      } else {
                        EasyLoading.showToast("No Content");
                      }
                    }
                  }
                }
              }
            }
            saveCurrentBook(widget.bookInfo.title);
            navigateToMainNav("${bookNewFolder.path}cover_image");
          } else {
            // print('chapters empty');
          }
        }
        EasyLoading.dismiss();
      }
      if (mounted) {
        setState(() {
          existBook = true;
          isButtonEnabled2 = true;
        });
      }
    } catch (e) {
      // Handle the exception
      // print('Error occurred: $e');
      EasyLoading.showError('Error occurred: $e');
      // You can handle the error message or show a toast or any other error handling mechanism you prefer.
      // Example: showToast('An error occurred while downloading the PDF');
      // showToast is a custom function that shows a toast message using fluttertoast package or any other similar package.
    }
  }

  navigateToMainNav(String path) {
    EasyLoading.dismiss();
    if (mounted) {
      setState(() {
        isButtonEnabled = true;
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavPdf(
          books: PdfTile(
            title: widget.bookInfo.title,
            path: path,
            isExpanded: false,
          ),
          path: '',
        ),
      ),
    );
  }

  Future<void> saveCurrentBook(bookName) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.setString('currentBook', bookName);
  }

  Future<void> downloadPdFiles(
    String url,
    String filename,
    String bookFolderDir,
  ) async {
    String host = "$mainHost$url";
    var savePath = bookFolderDir;
    // print(savePath);
    var dio = Dio();
    dio.interceptors.add(LogInterceptor());
    try {
      // print("Downloading...");
      var response = await dio.get(
        host,
        //Received data with List<int>
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 300),
        ),
      );
      var file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> showDonwloadConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download ${widget.bookInfo.title}?'),
          content:
              const Text('Don\'t interrupt while book is being downloaded.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog and do nothing (cancel logout)
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    isButtonEnabled = false;
                  });
                }
                _downloadPdf();
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showClearConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove ${widget.bookInfo.title}?'),
          content: const Text(
              'This will remove the book and its associated lessons from your phone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog and do nothing (cancel logout)
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    isButtonEnabled2 = false;
                  });
                }
                // _downloadPdf();
                deleteSpecificFolder();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteSpecificFolder() async {
    try {
      // Get the application support directory
      Directory appSupportDir = await getApplicationSupportDirectory();

      // Create the path of the specific folder you want to delete
      String specificFolderPath =
          '${appSupportDir.path}/${widget.bookInfo.title}';

      // Check if the folder exists
      if (await Directory(specificFolderPath).exists()) {
        // Delete the folder and all its contents
        await Directory(specificFolderPath).delete(recursive: true);
        if (mounted) {
          setState(() {
            existBook = false;
          });
        }
        EasyLoading.showToast("Cleared successfully");
        // print('Specific folder and its contents deleted successfully.');
      } else {
        EasyLoading.showToast("The specific folder does not exist.");
        // print('The specific folder does not exist.');
      }
    } catch (e) {
      EasyLoading.showToast("Error while deleting the specific folder: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              titleSpacing: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff500a34), Color(0xffcf167f)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // backgroundColor: const Color(0xff500a34),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.bookInfo.title,
                      style: GoogleFonts.prompt(
                        textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            body: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    Row(
                      children: [
                        Material(
                          elevation: 0.0,
                          child: widget.bookInfo.picurl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl:
                                      '$mainHost${widget.bookInfo.picurl}',
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    height: 200,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 8,
                                            blurRadius: 10,
                                            offset: const Offset(0, 3))
                                      ],
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 200,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 8,
                                            blurRadius: 10,
                                            offset: const Offset(0, 3))
                                      ],
                                      image: const DecorationImage(
                                        image: AssetImage("img/CK_logo.png"),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    image: const DecorationImage(
                                      image: AssetImage("img/CK_logo.png"),
                                    ),
                                  ),
                                ),
                        ),
                        Container(
                          width: screenWidth - 30 - 180 - 20,
                          margin: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                widget.bookInfo.title,
                                style: GoogleFonts.prompt(
                                  textStyle: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Lessons: ",
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black38,
                                    ),
                                  ),
                                  lessonLength > 0
                                      ? Text(
                                          "$lessonLength items",
                                          style: GoogleFonts.prompt(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        )
                                      : SizedBox(
                                          width:
                                              10.0, // Set the desired width of the CircularProgressIndicator
                                          height:
                                              10.0, // Set the desired height of the CircularProgressIndicator
                                          child: CircularProgressIndicator(
                                            strokeWidth:
                                                3, // You can adjust the thickness of the progress indicator
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Colors.blue),
                                            backgroundColor: Colors.grey[300],
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                "CK Children's Publishing",
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    const Divider(
                      endIndent: 20,
                      color: Color(0xFF7b8ea3),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Text(
                          "Details",
                          style: GoogleFonts.prompt(
                            textStyle: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        'This book is brought to you by CK Children\'s Publishing. Your Access to Visual Learning and Integration',
                        style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black54),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: isButtonEnabled
                                ? () {
                                    if (existBook) {
                                      if (mounted) {
                                        setState(() {
                                          isButtonEnabled = false;
                                        });
                                      }
                                      _downloadPdf();
                                    } else {
                                      if (lowStorage) {
                                        EasyLoading.showInfo(
                                            'Not enough storage. Please clean your phone!');
                                      } else {
                                        showDonwloadConfirmationDialog(context);
                                      }
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: isButtonEnabled
                                    ? Colors.green
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  top: 10.0,
                                  bottom: 10.0,
                                ),
                                alignment: Alignment.center),
                            child: Text(
                              "View Book",
                              style: GoogleFonts.prompt(
                                textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (existBook)
                            ElevatedButton(
                              onPressed: isButtonEnabled2
                                  ? () {
                                      showClearConfirmationDialog(context);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: isButtonEnabled2
                                      ? Colors.red
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.only(
                                    left: 15.0,
                                    right: 15.0,
                                    top: 10.0,
                                    bottom: 10.0,
                                  ),
                                  alignment: Alignment.center),
                              child: Text(
                                "Clear Book",
                                style: GoogleFonts.prompt(
                                  textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // const Divider(color: Color(0xFF7b8ea3)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
