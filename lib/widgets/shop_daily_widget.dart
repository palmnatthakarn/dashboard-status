// ตัวอย่างการใช้งาน API endpoint ใหม่ /api/dashboard/shop/:shopid/daily

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard_bloc_exports.dart';
import '../models/daily_images.dart';

class ShopDailyWidget extends StatelessWidget {
  final String shopId;

  const ShopDailyWidget({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  // เรียกใช้ API เพื่อดึงข้อมูล daily ของร้านค้า
                  context.read<DashboardBloc>().add(FetchShopDaily(shopId));
                },
                child: Text('ดึงข้อมูล Daily สำหรับร้าน $shopId'),
              ),
              const SizedBox(height: 16),
              if (state is ShopDailyLoaded && state.shopId == shopId)
                _buildDailyImagesList(state.dailyImages),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyImagesList(List<DailyImage> images) {
    if (images.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('ไม่มีรูปภาพในวันนี้'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'รูปภาพประจำวัน (${images.length} รูป)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return ListTile(
                leading: image.imageUrl != null
                    ? Image.network(
                        image.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      )
                    : const Icon(Icons.image),
                title: Text(image.category ?? 'ไม่มีหมวดหมู่'),
                subtitle: Text(image.subcategory ?? 'ไม่มีหมวดหมู่ย่อย'),
                trailing: Text(
                  image.uploadedAt ?? 'ไม่ทราบวันที่',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // แสดงรูปภาพแบบเต็มจอ
                  if (image.imageUrl != null) {
                    _showFullImage(context, image.imageUrl!);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('ดูรูปภาพ'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64),
                            Text('ไม่สามารถโหลดรูปภาพได้'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
