import 'package:flutter/material.dart';

class PPOBMenu extends StatelessWidget {
  const PPOBMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ppobItems = [
      {'icon': Icons.phone_android_rounded, 'label': 'Pulsa'},
      {'icon': Icons.electric_bolt_rounded, 'label': 'Listrik'},
      {'icon': Icons.water_drop_rounded, 'label': 'Air / PDAM'},
      {'icon': Icons.health_and_safety_rounded, 'label': 'BPJS'},
      {'icon': Icons.wifi_rounded, 'label': 'Internet'},
      {'icon': Icons.more_horiz_rounded, 'label': 'Lainnya'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Layanan & Tagihan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: ppobItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {},
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            ppobItems[index]['icon'] as IconData,
                            color: Theme.of(context).colorScheme.primary,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ppobItems[index]['label'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
