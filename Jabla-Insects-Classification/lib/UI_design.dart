import 'package:flutter/material.dart';

const Color kDarkBackground = Color(0xFF10091E);
const Color kPrimaryColor = Color(0xFF5D3DFD);
const Color kSecondaryColor = Color(0xFFC764FF);
const Color kAccentBorderColor = Color(0xFF332749);
const Color kTextColor = Colors.white;
const Color kLightTextColor = Color(0xFFD6D6D6);

class InsectClassificationScreen extends StatefulWidget {
  const InsectClassificationScreen({super.key});

  @override
  State<InsectClassificationScreen> createState() => _InsectClassificationScreenState();
}

class _InsectClassificationScreenState extends State<InsectClassificationScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kDarkBackground,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bug_report, color: kPrimaryColor),
          SizedBox(width: 8),
          Text(
            'Insect Identifier',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: kTextColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: kDarkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kDarkBackground),
            child: Row(
              children: const [
                Icon(Icons.bug_report, color: kPrimaryColor, size: 28),
                SizedBox(width: 8),
                Text('InsectID',
                    style: TextStyle(color: kTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _styledTile(icon: Icons.verified, label: 'Accurate Result', selected: true),
          _styledTile(icon: Icons.bar_chart, label: 'Graph', selected: false),
          _styledTile(icon: Icons.grid_view, label: 'Insect Classes', selected: false),
        ],
      ),
    );
  }

  Widget _styledTile({required IconData icon, required String label, required bool selected}) {
    final bg = selected ? const Color(0xFF1E1436) : Colors.transparent;
    final borderColor = selected ? kPrimaryColor : kAccentBorderColor;
    final iconColor = selected ? kPrimaryColor : kLightTextColor;
    final textStyle =
        TextStyle(color: kTextColor, fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: textStyle)),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeaderSection(),
          const SizedBox(height: 40),
          _buildImageUploadArea(),
          const SizedBox(height: 30),
          _buildClassificationResultArea(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kSecondaryColor, kDarkBackground],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                children: [
                  TextSpan(
                      text: 'Insect\n',
                      style: TextStyle(color: kTextColor),
                    ),
                  TextSpan(
                      text: 'Classification\nProcess',
                      style: TextStyle(color: kPrimaryColor),
                    ),
                ],
              ),
            ),
              SizedBox(height: 10),
              Text(
                'Use your camera or gallery to identify insects.',
                style: TextStyle(
                  color: kLightTextColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: kDarkBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kAccentBorderColor,
          width: 2,
        ),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.camera_alt_outlined,
            color: kAccentBorderColor,
            size: 60,
          ),
          SizedBox(height: 10),
          Text(
            'No image selected',
            style: TextStyle(
              color: kLightTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Upload an image to start the classification process',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kAccentBorderColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationResultArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.grid_view_outlined, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'Classification Result',
              style: TextStyle(
                color: kTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1436),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: const [
              Icon(
                Icons.manage_search_rounded,
                color: kAccentBorderColor,
                size: 60,
              ),
              SizedBox(height: 10),
              Text(
                'Awaiting analysis...',
                style: TextStyle(
                  color: kAccentBorderColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: const Color(0xFF1C132E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(Icons.image_outlined, 0),
          _buildNavItem(Icons.person_outline, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? kPrimaryColor : kAccentBorderColor,
        size: 30,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kSecondaryColor, kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.camera_alt_outlined, color: kTextColor, size: 30),
        onPressed: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
    );
  }
}

