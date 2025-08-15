import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart';


class TeacherClassStudents extends StatefulWidget {
  final String userId;
  final String roleId; // Added roleId since it's needed for the API call
  final String token;

  const TeacherClassStudents({
    super.key,
    required this.userId,
    required this.roleId,
    required this.token,
  });

  @override
  State<TeacherClassStudents> createState() => _TeacherClassStudentsState();
}

class _TeacherClassStudentsState extends State<TeacherClassStudents>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);

  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _loadClassStudents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClassStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use roleId instead of userId for the API call
      final students = await ApiService().getTeacherClassStudents(widget.roleId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        _showErrorSnackbar('Session expired. Please login again.');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapErrorToMessage(e);
        });
        _showErrorSnackbar(_mapErrorToMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred';
        });
        _showErrorSnackbar('An unexpected error occurred');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  String _mapErrorToMessage(ApiException e) {
    if (e.statusCode == 400) return 'Invalid request. Please try again.';
    if (e.statusCode == 401) return 'Session expired. Please login again.';
    if (e.statusCode == 404) return 'Data not found.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    return 'Error: ${e.message}';
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'student-avatar-${student['childID']}',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      student['fullname'][0],
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['fullname'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade: ${student['grade']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: student['gender'] == 'Male' 
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: student['gender'] == 'Male'
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.pink.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  student['gender'],
                  style: TextStyle(
                    color: student['gender'] == 'Male'
                        ? Colors.blue
                        : Colors.pink,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadClassStudents,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Students'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClassStudents,
        color: _primaryColor,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class: ${_students.isNotEmpty ? _students.first['grade'] ?? 'N/A' : 'Loading...'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Students: ${_students.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  SliverFillRemaining(child: _buildErrorState(_errorMessage!))
                else if (_isLoading && _students.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                  )
                else if (_students.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No students in this class',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildStudentCard(_students[index], index),
                      childCount: _students.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (_isLoading && _students.isNotEmpty)
              const Center(
                child: CircularProgressIndicator(color: _primaryColor)),
          ],
        ),
      ),
    );
  }
}