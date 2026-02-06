import 'package:flutter/material.dart';
import 'package:lu_360/widgets/onboarding_page.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();//PageController lets you control which onboarding page is currently visible
  int _currentPage = 0;//_currentPage keeps track of the index of the visible page (0, 1, 2, 3, etc).

  final List<Map<String, String>> onboardingData = [    //List<Map<String, String>> declares the type: a list where each element is a Map
    // whose keys are String and whose values are String.
    //onboardingData is the variable name holding this list of maps.
    {                                                   //The = followed by [ begins the list literal (array of items) initialization.
      "image": "images/map.png",                  //list stores the content for each page — image, title, and description.
      //The PageView.builder later uses this list to build each screen dynamically.
      "title": "Never Get Lost Again",
      "description":
      "Easily find lecture halls, labs, and canteens with our interactive map."
    },
    {
      "image": "images/cal.png",
      "title": "Your Schedule, Simplified",
      "description":
      "Organize your class routine and upcoming events in one clean calendar."
    },
    {
      "image": "images/bus.png",
      "title": "Stay on Time, Every Time",
      "description":
      "Real-time bus tracking and smart notifications for campus travel."
    },
    {
      "image": "images/student.png",
      "title": "Ready to Ace Your Campus Life?",
      "description":
      "Let's get you set up for an organized semester ahead!"
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {//If the user is not on the last page → it slides to the next one.
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to main app or home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Get Started!")),//If it’s the last page → currently just shows a “Get Started!” SnackBar.
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: onboardingData.length,//onboardingData.length is the number of pages in your onboarding list.
        // (From  earlier code onboardingData = [ … ] with 4 maps so length =4).
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final data = onboardingData[index];
          return OnboardingPage(
            image: data["image"]!,
            title: data["title"]!,
            description: data["description"]!,
            isLast: index == onboardingData.length - 1,
            currentPage: _currentPage,
            pageCount: onboardingData.length,
            onNext: _nextPage,
          );
        },
      ),
    );
  }
}
