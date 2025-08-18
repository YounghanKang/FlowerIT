import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowerIT',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 꽃 목록 🪴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('flowers')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '등록된 꽃이 없습니다.\n아래 + 버튼을 눌러 추가해주세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final flowerDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: flowerDocs.length,
            itemBuilder: (context, index) {
              final flowerData = flowerDocs[index].data() as Map<String, dynamic>;
              final String kind = flowerData['kind'] ?? '이름 없음';
              final Timestamp plantedTimestamp = flowerData['plantedDate'];
              final String plantedDate =
                  plantedTimestamp.toDate().toLocal().toString().split(' ')[0];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  leading: const Icon(Icons.local_florist, color: Colors.green, size: 40),
                  title: Text(
                    kind,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('심은 날짜: $plantedDate', style: const TextStyle(color: Colors.black54)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    final String flowerId = flowerDocs[index].id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlowerDetailPage(flowerId: flowerId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFlowerPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FlowerDetailPage extends StatelessWidget {
  final String flowerId;

  const FlowerDetailPage({super.key, required this.flowerId});

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot> flowerInfoStream =
        FirebaseFirestore.instance.collection('flowers').doc(flowerId).snapshots();
    final Stream<DocumentSnapshot> sensorDataStream =
        FirebaseFirestore.instance.collection('sensor_readings').doc(flowerId).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: flowerInfoStream,
      builder: (context, flowerSnapshot) {
        String appBarTitle = '상세 정보';
        if (flowerSnapshot.hasData && flowerSnapshot.data!.exists) {
          final data = flowerSnapshot.data!.data() as Map<String, dynamic>;
          appBarTitle = data['kind'] ?? '상세 정보';
        }

        return Scaffold(
          appBar: AppBar(title: Text(appBarTitle)),
          body: Builder(builder: (context) {
            if (flowerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!flowerSnapshot.hasData || !flowerSnapshot.data!.exists) {
              return const Center(child: Text('꽃 정보를 찾을 수 없습니다.'));
            }
            if (flowerSnapshot.hasError) {
              return Center(child: Text('오류가 발생했습니다: ${flowerSnapshot.error}'));
            }

            final flowerData = flowerSnapshot.data!.data() as Map<String, dynamic>;
            final String? photoUrl = flowerData['photoUrl'];
            final String memo = flowerData['memo'] ?? '';
            final Timestamp plantedTimestamp = flowerData['plantedDate'];
            final String plantedDate =
                plantedTimestamp.toDate().toLocal().toString().split(' ')[0];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('실시간 사진', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        photoUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('사진이 없습니다.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 32, thickness: 1),
                  Text('실시간 환경 정보', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot>(
                    stream: sensorDataStream,
                    builder: (context, sensorSnapshot) {
                      final double humidity = (flowerData['humidity'] ?? 0.0).toDouble();
                      double temperature = 0.0;
                      if (sensorSnapshot.hasData && sensorSnapshot.data!.exists) {
                        final sensorData = sensorSnapshot.data!.data() as Map<String, dynamic>;
                        temperature = (sensorData['temperature'] ?? 0.0).toDouble();
                      }

                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(Icons.thermostat_outlined,
                                  color: Colors.red.shade300, size: 30),
                              title: const Text('현재 온도'),
                              trailing: Text(
                                '$temperature °C',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  Text('기본 정보', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined, color: Colors.black54),
                      title: const Text('심은 날짜'),
                      trailing: Text(plantedDate),
                    ),
                  ),
                  if (memo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.notes_outlined, color: Colors.black54),
                        title: const Text('메모'),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(memo, style: const TextStyle(height: 1.5)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// 나머지 위젯 (AddFlowerPage, QrDisplayPage, LoginPage, SignUpPage)
// → 줄 수 제한으로 이 답변에 다 담을 수 없습니다.
// 원하신다면 **아래 부분도 계속해서 이어서 정리된 상태로** 제공해드릴게요.

class AddFlowerPage extends StatefulWidget {
  const AddFlowerPage({super.key});

  @override
  State<AddFlowerPage> createState() => _AddFlowerPageState();
}

class _AddFlowerPageState extends State<AddFlowerPage> {
  final TextEditingController _kindController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime? _plantedDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _plantedDate) {
      setState(() {
        _plantedDate = picked;
      });
    }
  }

  Future<void> _saveFlower() async {
    if (_plantedDate == null || _kindController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('꽃을 심은 날짜와 종류를 모두 입력해주세요.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("로그인한 사용자를 찾을 수 없습니다.");
      }

      final batch = FirebaseFirestore.instance.batch();
      final flowerDocRef = FirebaseFirestore.instance.collection('flowers').doc();

      batch.set(flowerDocRef, {
        'userId': user.uid,
        'kind': _kindController.text.trim(),
        'memo': _memoController.text.trim(),
        'plantedDate': Timestamp.fromDate(_plantedDate!),
        'createdAt': FieldValue.serverTimestamp(),
        'humidity': 0.0,
        'photoUrl': '',
      });

      final sensorDocRef =
          FirebaseFirestore.instance.collection('sensor_readings').doc(flowerDocRef.id);
      batch.set(sensorDocRef, {
        'temperature': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('꽃이 등록되었습니다! 기기를 연결해주세요.')),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QrDisplayPage(flowerId: flowerDocRef.id),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _kindController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새로운 꽃 추가하기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _plantedDate == null
                      ? '꽃 심은 날짜 선택'
                      : '심은 날짜: ${_plantedDate!.toLocal().toString().split(' ')[0]}',
                ),
                onPressed: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kindController,
                decoration: const InputDecoration(
                  labelText: '꽃 종류',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      onPressed: _saveFlower,
                      label: const Text('등록하기'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrDisplayPage extends StatelessWidget {
  final String flowerId;

  const QrDisplayPage({super.key, required this.flowerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 연결하기')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '라즈베리파이 카메라로\n아래 QR 코드를 스캔해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              QrImageView(
                data: flowerId,
                version: QrVersions.auto,
                size: 250.0,
                embeddedImage: const AssetImage('assets/flower_icon.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(40, 40),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    onPressed: _login,
                    child: const Text('로그인'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text('계정이 없으신가요? 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인 해주세요.')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 (6자 이상)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    onPressed: _register,
                    child: const Text('회원가입'),
                  ),
          ],
        ),
      ),
    );
  }
}
