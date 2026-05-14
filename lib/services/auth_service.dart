import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String googleSignInCancelledCode = 'GOOGLE_SIGN_IN_CANCELLED';

  static const String _webClientId =
      '269471985170-f8tunf05qdkg238jgp004j6ohvil7947.apps.googleusercontent.com';

  User? get currentUser {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.sendEmailVerification();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'photoUrl': user.photoURL,
          'provider': 'email_password',
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _auth.signOut();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi đăng ký tài khoản: $e');
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.reload();

        final User? refreshedUser = _auth.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          await _auth.signOut();

          throw Exception(
            'Tài khoản chưa xác minh email. Vui lòng vào Gmail và bấm xác minh trước khi đăng nhập.',
          );
        }

        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e.toString().contains('Tài khoản chưa xác minh email')) {
        rethrow;
      }

      throw Exception('Đã xảy ra lỗi khi đăng nhập: $e');
    }
  }

  Future<void> resendEmailVerification({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Không tìm thấy tài khoản.');
      }

      await user.reload();

      final User? refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        await _firestore.collection('users').doc(refreshedUser.uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _auth.signOut();

        throw Exception('Email này đã được xác minh. Bạn có thể đăng nhập.');
      }

      await refreshedUser?.sendEmailVerification();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _webClientId,
      );

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        final DocumentReference userDoc =
            _firestore.collection('users').doc(user.uid);

        final DocumentSnapshot docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Người dùng',
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'provider': 'google',
            'emailVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.update({
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'provider': 'google',
            'emailVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } on GoogleSignInException catch (e) {
      final String errorCode = e.code.name.toLowerCase();
      final String errorDescription = e.description?.toLowerCase() ?? '';

      if (errorCode.contains('cancel') ||
          errorDescription.contains('cancel')) {
        throw Exception(googleSignInCancelledCode);
      }

      throw Exception('Không thể đăng nhập bằng Google. Vui lòng thử lại.');
    } catch (e) {
      final String errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('cancel')) {
        throw Exception(googleSignInCancelledCode);
      }

      throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Nếu user không đăng nhập bằng Google thì bỏ qua.
    }

    await _auth.signOut();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trên Firebase.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng nhập ít nhất 6 ký tự.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được đăng ký bằng phương thức đăng nhập khác.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra Internet.';
      default:
        return 'Lỗi xác thực: $code';
    }
  }
}