import 'package:faruqbase/pages/login/widgets/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Latar belakang putih
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD2E5E9), // Warna gradasi pertama
              Color(0xFFE3ECED), // Warna gradasi kedua
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50), // Tambah jarak agar tidak terlalu atas
              
              // Animasi Lottie
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 150,
                  child: Lottie.asset('assets/lupa.json'),
                ),
              ),

              const SizedBox(height: 20),

              // Deskripsi dengan ikon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, color: Color(0xFF293239), size: 24), // Ubah warna ikon
                  const SizedBox(width: 8),
                  Text(
                    'Masukkan email untuk reset password',
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF293239), // Ubah warna teks menjadi gelap
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Card untuk input email
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "Email Address",
                      hintText: "Masukkan email anda!",
                      labelStyle: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Color(0xFF293239), // Ubah warna label menjadi gelap
                        ),
                      ),
                      hintStyle: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Color(0xff6A6A6A),
                        ),
                      ),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF293239)), // Ubah warna ikon
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Reset Password dengan animasi hover
              InkWell(
                onTap: () async {
                  if (emailController.text.trim().isEmpty) {
                    showSnackBar(context, "Tolong input email anda!");
                    return;
                  }
                  try {
                    await auth.sendPasswordResetEmail(
                      email: emailController.text.trim(),
                    );
                    showSnackBar(
                      context,
                      "Link reset password telah dikirim ke email anda!",
                    );
                    Navigator.pop(context);
                  } catch (error) {
                    showSnackBar(context, error.toString());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF293239), // Ubah warna tombol agar serasi
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Teks kembali ke login
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Kembali ke Login',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF293239), // Teks berwarna gelap
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}