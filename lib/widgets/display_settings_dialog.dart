import 'package:flutter/material.dart';
import 'package:booking_app/providers/theme_provider.dart';
import 'package:booking_app/widgets/color_picker_dialog.dart';
import 'package:provider/provider.dart';

class DisplaySettingsDialog extends StatefulWidget {
  const DisplaySettingsDialog({super.key});

  @override
  State<DisplaySettingsDialog> createState() => _DisplaySettingsDialogState();
}

class _DisplaySettingsDialogState extends State<DisplaySettingsDialog> {
  @override
  Widget build(BuildContext context) {
    const double dimensionColorContainer = 30.0;
    const double borderRadiusContainer = 5.0;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.color_lens),
          SizedBox(width: 10),
          Text('Display Settings')
        ],
      ),
      content: SingleChildScrollView(
          child: Column(
        children: [
          Text('Choose Color For Location'),
          SizedBox(height: 10),
          Row(
            children: [
              Row(
                children: [
                  Text('Port-Louis: '),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      // Open color picker dialog for Port-Louis
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ColorPickerDialog(
                            initialColor: Provider.of<ThemeProvider>(context)
                                .portLouisColor,
                            onColorChanged: (color) {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .updatePortLouisColor(context, color);
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      width: dimensionColorContainer,
                      height: dimensionColorContainer,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(borderRadiusContainer),
                        // Use the portLouisColor from the provider
                        color:
                            Provider.of<ThemeProvider>(context).portLouisColor,
                      ), // Use the portLouisColor
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20),
              Row(
                children: [
                  Text('Quatre-Bornes: '),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      // Open color picker dialog for Quatre-Bornes
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ColorPickerDialog(
                            initialColor: Provider.of<ThemeProvider>(context)
                                .quatreBornesColor,
                            onColorChanged: (color) {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .updateQuatreBornesColor(context, color);
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                        width: dimensionColorContainer,
                        height: dimensionColorContainer,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(borderRadiusContainer),
                          color: Provider.of<ThemeProvider>(context)
                              .quatreBornesColor,
                        )),
                  )
                ],
              )
            ],
          ),
          SizedBox(height: 25),
          Text('Choose Row Color'),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Colour A: '),
                  SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Open color picker dialog for Colour A
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ColorPickerDialog(
                            initialColor:
                                Provider.of<ThemeProvider>(context).colorA,
                            onColorChanged: (color) {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .updateColorA(color);
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      width: dimensionColorContainer,
                      height: dimensionColorContainer,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(borderRadiusContainer),
                        color: Provider.of<ThemeProvider>(context).colorA,
                      ),
                    ),
                  )
                ],
              ),
              Row(children: [
                Text('Colour B: '),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    // Open color picker dialog for Colour B
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ColorPickerDialog(
                          initialColor:
                              Provider.of<ThemeProvider>(context).colorB,
                          onColorChanged: (color) {
                            Provider.of<ThemeProvider>(context, listen: false)
                                .updateColorB(color);
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    width: dimensionColorContainer,
                    height: dimensionColorContainer,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(borderRadiusContainer),
                      color: Provider.of<ThemeProvider>(context).colorB,
                    ),
                  ),
                )
              ]),
            ],
          ),
          SizedBox(
            height: 25,
          ),
          ElevatedButton(
            onPressed: () {
              // Reset the row colors to default
              Provider.of<ThemeProvider>(context, listen: false).resetColorAB();
            },
            child: Text('Reset Row Color'),
          )
        ],
      )),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            // Save the selected colors
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
