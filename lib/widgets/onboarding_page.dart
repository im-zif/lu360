import 'package:flutter/material.dart';

//Displays one individual onboarding screen (image + title + description + next/skip buttons + dots).


class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final bool isLast;
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.isLast,
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60),
      child: Column( //The Column arranges everything vertically.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(image, height: 250),
          Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pageCount,
                      (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: currentPage == dotIndex ? 16 : 6,//This is how you visually show which page is currently active.
                    decoration: BoxDecoration(
                      color: currentPage == dotIndex
                          ? Colors.blue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),  //This builds the small page indicator dots at the bottom.
                      //The active dot becomes wider and blue.
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLast ? "Get Started" : "Next",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Optionally skip onboarding
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
//This snippet creates a horizontal row of page‑indicator “dots”. There are pageCount dots.
// The one corresponding to currentPage is highlighted by being wider (16) and blue; all others are smaller (6) and grey.
// Because it uses AnimatedContainer, when currentPage changes (and thus width and colour change),
// the transition is smooth (over 300ms) rather than abrupt.
