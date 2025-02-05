import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intelligrade/api/llm/llm_api.dart';
import 'package:intelligrade/controller/model/essay_editor.dart';

import '../api/llm/claude_api.dart';
import '../api/llm/openai_api.dart';

// Required Components:
// 2 Dropdowns: 1 for the Grade Level and 1 for the Point Scale
// 3 Text Boxes: Standard/Objective, Assignment Description, Additional Customization for Rubric (Optional)

class EssayGeneration extends StatefulWidget {
  const EssayGeneration({super.key, required this.title});
  final String title;

  @override
  State<EssayGeneration> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<EssayGeneration> {
  // llm options
  //final List<String> llmOptions = ['ChatGPT', 'CLAUDE', 'Perplexity'];

  //API Keys
  final perplexityApiKey = dotenv.env['PERPLEXITY_API_KEY'] ?? '';
  final openApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final claudeApiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';

  dynamic globalRubric;
  dynamic rubricasjson;

  // Get api key for selected LLM
  String getApiKey() {
    switch (selectedLLM) {
      case 'OpenAI':
        return openApiKey;
      case 'Claude':
        return claudeApiKey;
      default:
        return perplexityApiKey;
    }
  }

  //See if button has been pressed or not
  bool _isLoading = false;

  //Holds values for user input fields
  int _selectedPointScale = 3; // Default value
  String _selectedGradeLevel =
      'Advanced'; // Default value for GradeLevelDropdown
  String? selectedLLM = 'OpenAI'; // default

  // Variables to store the text inputs
  final TextEditingController _standardObjectiveController =
      TextEditingController();
  final TextEditingController _assignmentDescriptionController =
      TextEditingController();
  final TextEditingController _additionalCustomizationController =
      TextEditingController();

  // Function to store the selected value
  void _handlePointScaleChanged(int? newValue) {
    setState(() {
      if (newValue != null) {
        _selectedPointScale = newValue;
      }
    });
  }

  // Handle LLM Selection
  void _handleLLMChanged(String? newValue) {
    setState(() {
      if (newValue != null) {
        selectedLLM = newValue;
      }
    });
  }

  // Function to store the selected grade level value
  void _handleGradeLevelChanged(String? newValue) {
    setState(() {
      if (newValue != null) {
        _selectedGradeLevel = newValue;
      }
    });
  }

  //Function to query selected AI to generate a rubric
  Future<dynamic> genRubricFromAi(String inputs) async {
    try {
      setState(() {
        _isLoading = true; // Set loading state to true
      });

      String apiKey =
          getApiKey(); // Get the correct API key based on the selected LLM
      if (apiKey.isEmpty) {
        throw Exception("API key is missing");
      }

      // Dynamically instantiate the appropriate LLM class based on the selectedLLM
      dynamic llmInstance;
      if (selectedLLM == 'OpenAI') {
        llmInstance = OpenAiLLM(openApiKey);
      } else if (selectedLLM == 'Claude') {
        llmInstance = ClaudeAiAPI(claudeApiKey);
      } else if (selectedLLM == 'Perplexity') {
        llmInstance = LlmApi(perplexityApiKey); // Perplexity API class
      } else {
        throw Exception('Invalid LLM selected.');
      }

      String queryPrompt = '''
I am building a program that creates rubrics when provided with assignment information. I will provide you with the following information about the assignment that needs a rubric:
        Difficulty level, point scale, assignment objective, assignment description. You may also receive additional customization rules.
        Using this information, you will reply with a rubric that includes 4-5 criteria. Your reply must only contain the JSON information, and begin with a {.
        Remove any ``` from your output.
 
        You must reply with a representation of the rubric in JSON format that exactly matches this format:
        {
            "criteria": [
                {
                    "description": #CriteriaName,
                    "levels": [
                        { "definition": #CriteriaDef, "score": #ScoreValue },
                    ]
                }
          ]
        }
        #CriteriaName must be replaced with the name of the criteria.
        #CriteriaDef must be replaced with a detailed description of what meeting that criteria would look like for each scale value.
        #ScoreValue must be replaced with a number representing the score. The score for the lowest scale value will be 0, and the scores will increase by 1 for each scale.
        You should create as many "levels" objects as there are point scale values.
        Make sure the levels sections always have the definition key inside. That key should neve be called description.
        Here is the assignment information:
        $inputs
        ''';
      globalRubric = await llmInstance.postToLlm(queryPrompt);
      globalRubric = globalRubric.replaceAll('```', '').trim();
      globalRubric = globalRubric.replaceAll('json', '').trim();
      return jsonDecode(globalRubric);
    } catch (e) {
      print("Error in API request: $e");
      return null;
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state to false
      });
    }
  }

// Method to return a summary of the selected dropdown and text box values
  String getSelectedResponses() {
    return '''
Selected Difficulty Level: $_selectedGradeLevel
Selected Point Scale: $_selectedPointScale
Standard / Objective: ${_standardObjectiveController.text}
Assignment Description: ${_assignmentDescriptionController.text}
Additional Customization: ${_additionalCustomizationController.text}
    ''';
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the widget tree
    _standardObjectiveController.dispose();
    _assignmentDescriptionController.dispose();
    _additionalCustomizationController.dispose();
    super.dispose();
  }

  _MyHomePageState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          // Using Row to split screen into two sections
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left Column
            Expanded(
              flex:
                  2, // This controls the space for the left side, bigger ratio
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("Essay Generator", style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 16),

                  // Grade Level Dropdown
                  GradeLevelDropdown(
                    selectedGradeLevel: _selectedGradeLevel, // Current value
                    onChanged:
                        _handleGradeLevelChanged, // Update selected value
                  ),
                  const SizedBox(height: 16),

                  // Point Scale Dropdown
                  PointScaleDropdown(
                    selectedPointScale: _selectedPointScale, // Current value
                    onChanged:
                        _handlePointScaleChanged, // Update selected value
                  ),
                  const SizedBox(height: 16),

                  // LLM Selection Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Desired LLM'),
                    value: selectedLLM,
                    onChanged: _handleLLMChanged,
                    items: <String>['Perplexity', 'OpenAI', 'Claude']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  // Standard/Objective TextBox
                  TextBox(
                    label: "Standard / Objective",
                    controller: _standardObjectiveController,
                  ),
                  const SizedBox(height: 16),

                  // Assignment Description TextBox
                  TextBox(
                    label: "Assignment Description",
                    controller: _assignmentDescriptionController,
                  ),
                  const SizedBox(height: 16),

                  // Additional Customization TextBox
                  TextBox(
                    label: "Additional Customization for Rubric (Optional)",
                    controller: _additionalCustomizationController,
                  ),

                  const SizedBox(height: 16),

                  // Generate Essay Button
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null // Disable button when loading
                        : () {
                            setState(() {
                              _isLoading = true; // Start loading
                            });

                            final result = getSelectedResponses();
                            genRubricFromAi(result).then((dynamic results) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EssayEditor(results),
                                ),
                              );
                            }).whenComplete(() {
                              setState(() {
                                _isLoading = false; // End loading
                              });
                            });
                          },
                    child: Text(
                        _isLoading ? 'Generating Essay...' : 'Generate Essay'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32), // Adds space between the two columns
          ],
        ),
      ),
    );
  }
}

// Create Class for Buttons
class Button extends StatelessWidget {
  // Fields in this widget subclass are marked final
  final String type;
  final String text;
  final String filters = "";
  final VoidCallback? onPressed;

  const Button._(this.type, this.text, {this.onPressed});

  factory Button(String type, {VoidCallback? onPressed}) {
    if (type == "assessment") {
      return Button._(type, "Send to Moodle");
    } else if (type == "essay") {
      return Button._(
        type,
        "Generate Essay",
        onPressed: onPressed,
      );
    } else {
      return Button._(type, "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.create), Text(text)],
        ));
  }
}

// Modify TextBox to accept a TextEditingController
class TextBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const TextBox({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Use the persistent controller
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

class PointScaleDropdown extends StatelessWidget {
  final int selectedPointScale;
  // We need to store the value of the int the user inputs
  final ValueChanged<int?> onChanged;

  const PointScaleDropdown({
    super.key,
    required this.selectedPointScale,
    required this.onChanged,
  });

  void _handleValueChanged(int? newValue) {
    // Additional Logic
    onChanged(newValue); // Call the passed onChanged function
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(labelText: "Point Scale"),
      value: selectedPointScale,
      items: [1, 2, 3, 4, 5].map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: _handleValueChanged,
    );
  }
}

class GradeLevelDropdown extends StatelessWidget {
  final String selectedGradeLevel;
  // We need to store the value of the string the user inputs
  final ValueChanged<String?> onChanged;

  const GradeLevelDropdown({
    super.key,
    required this.selectedGradeLevel,
    required this.onChanged,
  });

  void _handleTextChanged(String? newValue) {
    // Additional Logic
    onChanged(newValue); // Call the passed onChanged function
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Difficulty Level"),
      value: selectedGradeLevel,
      items: <String>['Introductory', 'Intermediate', 'Advanced']
          .map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _handleTextChanged,
    );
  }
}
