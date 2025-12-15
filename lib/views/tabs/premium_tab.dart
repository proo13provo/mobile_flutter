import 'package:flutter/material.dart';

class PremiumTab extends StatelessWidget {
  const PremiumTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildReasonsCard(),
          ),
          const SizedBox(height: 32),
          _buildAvailablePlansSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7C7CFF), Color(0xFF3B3B8F), Colors.black],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Trải nghiệm âm nhạc đỉnh\ncao với Premium\nIndividual.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 16,
                  color: Color(0xFF1DB954),
                ),
                SizedBox(width: 6),
                Text(
                  'Ưu đãi có hạn',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn không thể nâng cấp lên Premium trong ứng dụng này. '
            'Chúng tôi biết điều này thật bất tiện.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lý do nên dùng gói Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _reasonItem(Icons.volume_off, 'Nghe nhạc không quảng cáo'),
          _reasonItem(Icons.download, 'Tải xuống để nghe không cần mạng'),
          _reasonItem(Icons.shuffle, 'Phát nhạc theo thứ tự bất kỳ'),
          _reasonItem(Icons.headphones, 'Chất lượng âm thanh cao'),
          _reasonItem(Icons.group, 'Nghe cùng bạn bè theo thời gian thực'),
        ],
      ),
    );
  }

  Widget _reasonItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các gói có sẵn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAvailablePlanCard(
            badge: 'Ưu đãi 3 tháng',
            title: 'Individual',
            titleColor: Color(0xFFFFC0CB),
            benefits: const [
              '1 tài khoản Premium',
              'Hủy bất cứ lúc nào',
              'Đăng ký hoặc thanh toán một lần',
            ],
          ),
          const SizedBox(height: 16),
          _buildAvailablePlanCard(
            title: 'Student',
            titleColor: Color(0xFFB39DDB),
            benefits: const [
              '1 tài khoản Premium đã xác minh',
              'Giảm giá cho sinh viên đủ điều kiện',
              'Hủy bất cứ lúc nào',
              'Đăng ký hoặc thanh toán một lần',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlanCard({
    String? badge,
    required String title,
    required Color titleColor,
    required List<String> benefits,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD6D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn không thể nâng cấp lên Premium trong ứng dụng này. '
            'Chúng tôi biết điều này thật bất tiện.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
