import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class DosaAddonsResult {
  final int dosaCount;
  final bool chutney;
  final bool redChutney;
  final bool sambar;

  const DosaAddonsResult({
    required this.dosaCount,
    required this.chutney,
    required this.redChutney,
    required this.sambar,
  });
}

class DosaAddonsScreen extends StatefulWidget {
  const DosaAddonsScreen({super.key});

  @override
  State<DosaAddonsScreen> createState() => _DosaAddonsScreenState();
}

class _DosaAddonsScreenState extends State<DosaAddonsScreen> {
  int dosaCount = 1;
  bool chutney = true;
  bool redChutney = false;
  bool sambar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Dosa')),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of Dosa',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      dosaCount > 1 ? () => setState(() => dosaCount--) : null,
                ),
                Text(
                  dosaCount.toString(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => dosaCount++),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Add-ons',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Coconut Chutney'),
              value: chutney,
              onChanged: (v) => setState(() => chutney = v),
            ),
            SwitchListTile(
              title: const Text('Red Chutney'),
              value: redChutney,
              onChanged: (v) => setState(() => redChutney = v),
            ),
            SwitchListTile(
              title: const Text('Sambar'),
              value: sambar,
              onChanged: (v) => setState(() => sambar = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    DosaAddonsResult(
                      dosaCount: dosaCount,
                      chutney: chutney,
                      redChutney: redChutney,
                      sambar: sambar,
                    ),
                  );
                },
                child: Text(
                  'Apply',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
