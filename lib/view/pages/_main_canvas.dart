import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:Whiteboard/widgets/_custom_dialog.dart';
import 'package:blur/blur.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pattern_background/pattern_background.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ResponsiveCanvas extends StatefulWidget {
  @override
  _ResponsiveCanvasState createState() => _ResponsiveCanvasState();
}

class _ResponsiveCanvasState extends State<ResponsiveCanvas> {
  double sliderValue = 0.1;
  List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.grey
  ];
  double minScale = 0.1;
  double maxScale = 5.0;
  final GlobalKey _globalKey = GlobalKey();
  TransformationController? _transformationController;
  double _currentScale = 1.0;
  List<Point> points = []; // List of Point objects
  Size originalSize = Size.zero; // Original size of the canvas
  bool isSelecting = false; // Selection mode toggle
  int selectedIndex = 0; // Selected color index

  bool isDrawing = true; // Flag to control drawing state

  List<Point> deletedPoints = []; // List of deleted points

  void _undo() {
    setState(() {
      if (points.isNotEmpty) {
        do {
          deletedPoints.add(points.last);
          points.removeLast();
        } while (points.isNotEmpty && points.last.offset != null);
      }
    });
  }

  void _redo() {
    setState(() {
      if (deletedPoints.isNotEmpty) {
        do {
          points.add(deletedPoints.last);
          deletedPoints.removeLast();
        } while (deletedPoints.isNotEmpty && deletedPoints.last.offset != null);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < points.length; i++) {
        points[i].isSelected = true;
      }
    });
  }

  void _changeColor(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  void _zoomIn() {
    setState(() {
      _currentScale += 0.1;
      _transformationController!.value = Matrix4.identity()
        ..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale -= 0.1;
      if (_currentScale < 1.0) _currentScale = 1.0;
      _transformationController!.value = Matrix4.identity()
        ..scale(_currentScale);
    });
  }

  Future<void> _saveToFile() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Create a new image with white background
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);
      Paint backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          backgroundPaint);

      // Draw the captured image onto the white background
      canvas.drawImage(image, Offset.zero, Paint());

      // Convert the drawn image to PNG bytes
      ui.Image finalImage =
          await recorder.endRecording().toImage(image.width, image.height);
      ByteData? finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List finalPngBytes = finalByteData!.buffer.asUint8List();

      // Save the modified image
      final result = await ImageGallerySaver.saveImage(finalPngBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to gallery: $result')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));


    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Whiteboard'),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
        backgroundColor: CupertinoColors.activeBlue,
        actions: [
          IconButton(
            onPressed: () {
              _zoomIn();
            },
            icon: Icon(Icons.zoom_in,color: Colors.white,),
          ),
          IconButton(
            onPressed: () {
              _zoomOut();
            },
            icon: Icon(Icons.zoom_out,color: Colors.white,),
          ),
          IconButton(
            onPressed: () async {
              showCustomSuccessDialog('Please wait!', context);
              await _saveToFile();
            },
            icon: Icon(Icons.save,color: Colors.white,),
          ),
        ],
      ),
      body: SafeArea(
        child: RepaintBoundary(
          key: _globalKey,
          child: CustomPaint(
            size: Size(width, height),
            painter: DotPainter(
              dotColor: Colors.grey.shade400,
              dotRadius: 1,
              spacing: 5,
            ),
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: minScale,
                    maxScale: maxScale,
                    onInteractionStart: (_) {
                      setState(() {
                        isDrawing = false;
                      });
                    },
                    onInteractionEnd: (_) {
                      setState(() {
                        isDrawing = true;
                      });
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (originalSize == Size.zero) {
                          originalSize = constraints.biggest;
                        }
                        return GestureDetector(
                            onPanUpdate: (details) {
                              if (isDrawing) {
                                setState(() {
                                  RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                                  Offset localPosition = renderBox
                                      .globalToLocal(details.globalPosition);
                                  points.add(Point(localPosition,
                                      colors[selectedIndex], false, sliderValue*15));
                                  // Use currentStrokeWidth here
                                });
                              }
                            },

                          onPanEnd: (details) {
                            if (isDrawing) {
                              points.add(Point(null, colors[selectedIndex],
                                  false, sliderValue*15 )); // Add a null point to separate lines
                            }
                          },
                          onTapDown: (details) {
                            if (isSelecting) {
                              RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                              Offset localPosition = renderBox
                                  .globalToLocal(details.globalPosition);
                              for (int i = 0; i < points.length; i++) {
                                if (points[i].offset != null &&
                                    (points[i].offset! - localPosition)
                                            .distance <
                                        10) {
                                  setState(() {
                                    points[i].isSelected =
                                        !points[i].isSelected;
                                  });
                                }
                              }
                            }
                          },
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: Draw(
                              strokeWidth: sliderValue*15,
                                points: points, originalSize: originalSize),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                isExpanded
                    ? Container(
                        height: 100,
                        width: width,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          // borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Slider(
                                    value: sliderValue,
                                    onChanged: (value) {
                                      setState(() {
                                        sliderValue = value;
                                      });
                                    },
                                  ),
                                  Text(
                                    'Brush Size: ${sliderValue * 15 ~/ 1}', // ~~/1 is used for integer division
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                ],
                              )),
                              const SizedBox(
                                width: 20,
                              ),

                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Clear all',style: GoogleFonts.inter(
                                          fontWeight:FontWeight.bold
                                        ),),
                                        content: Text('Are you sure to clear all drawings? This cannot be undone!',style: GoogleFonts.inter(),),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                points.clear();
                                              });
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      ).frosted(
                                        blur: 50,
                                        frostColor: Colors.grey.shade100,
                                        // borderRadius: BorderRadius.circular(20),
                                        frostOpacity: 0.1,
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.clear_all),
                              ),
                            ],
                          ),
                        )).frosted(
                          blur: 10,
                          frostColor: Colors.grey.shade100,
                          // borderRadius: BorderRadius.circular(20),
                          frostOpacity: 0.1,
                )
                    : SizedBox.shrink(),
                Container(
                  height: 80,
                  // margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  // padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    // borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            // flex: ,
                            child: ListView.builder(
                              itemCount: colors.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _changeColor(index);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                      height: selectedIndex == index ? 50 : 30,
                                      width: selectedIndex == index ? 50 : 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors[index],
                                        border: Border.all(
                                          color: selectedIndex == index
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      margin: const EdgeInsets.all(5),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 50,
                            width: 2,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _undo();
                                  },
                                  icon: Icon(Icons.undo),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _redo();
                                  },
                                  icon: Icon(Icons.redo),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                  icon: isExpanded
                                      ? Icon(Icons.arrow_downward)
                                      : Icon(Icons.arrow_upward),
                                )
                              ],
                            ),
                          )
                        ],
                      )).frosted(
                    blur: 10,
                    frostColor: Colors.grey.shade100,
                    // borderRadius: BorderRadius.circular(20),
                    frostOpacity: 0.1,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isExpanded = false;
}

// class DotPainter extends CustomPainter {
//   final Color dotColor;
//   final double dotRadius;
//   final double spacing;
//
//   DotPainter({
//     required this.dotColor,
//     required this.dotRadius,
//     required this.spacing,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = dotColor
//       ..style = PaintingStyle.fill;
//
//     for (double x = 0; x < size.width; x += spacing) {
//       for (double y = 0; y < size.height; y += spacing) {
//         canvas.drawCircle(Offset(x, y), dotRadius, paint);
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

class Draw extends CustomPainter {
  const Draw({required this.strokeWidth, required this.points, required this.originalSize});
  final double strokeWidth;
  final List<Point> points;
  final Size originalSize;

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / originalSize.width;
    double scaleY = size.height / originalSize.height;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        Offset p1 = Offset(
            points[i].offset!.dx * scaleX, points[i].offset!.dy * scaleY);
        Offset p2 = Offset(points[i + 1].offset!.dx * scaleX,
            points[i + 1].offset!.dy * scaleY);

        Paint paint = Paint()
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth // Use stored stroke width
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1, p2, paint);
      } else if (points[i].offset != null && points[i + 1].offset == null) {
        Offset p1 = Offset(
            points[i].offset!.dx * scaleX, points[i].offset!.dy * scaleY);

        Paint paint = Paint()
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth // Use stored stroke width
          ..strokeCap = StrokeCap.round;

        canvas.drawPoints(PointMode.points, [p1], paint);
      }
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Point {
  final Offset? offset;
  final Color color;
  final double strokeWidth; // New property to store stroke width
  bool isSelected;

  Point(this.offset, this.color, this.isSelected, this.strokeWidth);
}
