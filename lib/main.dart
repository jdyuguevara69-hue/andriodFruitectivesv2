import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_detector.dart';
import 'roboflow_client.dart';

bool firebaseReady = false;
User? get currentUser => firebaseReady ? FirebaseAuth.instance.currentUser : null;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // reads android/app/google-services.json
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  runApp(const FruitectivesApp());
  LocalFruitDetector.instance.warmUp(); // load the on-device AI model in the background
}

// Turns Firebase error codes into friendly messages.
String authError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email': return 'That email address is not valid.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'email-already-in-use': return 'An account already exists with that email.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      case 'network-request-failed': return 'No internet connection.';
      case 'operation-not-allowed': return 'Email/Password sign-in is not enabled in Firebase.';
    }
    if ((e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase login is not set up yet. In the Firebase console, open Authentication, click Get started, and enable Email/Password.';
    }
    return e.message ?? 'Login failed (${e.code}).';
  }
  return 'Something went wrong: $e';
}
void toast(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

const green = Color(0xFF08783F);
const darkGreen = Color(0xFF075B32);
const leaf = Color(0xFF5BAA45);
const cream = Color(0xFFF8F7F1);
const ink = Color(0xFF292D28);
const muted = Color(0xFF777D75);

class FruitectivesApp extends StatelessWidget {
  const FruitectivesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fruitectives 2.0', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        fontFamily: 'Roboto', appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: ink)),
    home: currentUser != null ? const DashboardPage() : const WelcomePage(),
  );
}

void go(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
void replace(BuildContext context, Widget page) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key,this.size=58});
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width:size,height:size,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:[BoxShadow(color:green.withOpacity(.08),blurRadius:15)]),child:Padding(padding:EdgeInsets.all(size*.14),child:Image.asset('assets/images/logo.png',fit:BoxFit.contain))),
    const SizedBox(height:8),
    const Text('FRUITECTIVES',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.3,fontSize:16)),
    const Text('2.0',style:TextStyle(color:green,fontWeight:FontWeight.w900,fontSize:13)),
  ]);
}

class LeafBackdrop extends StatelessWidget {
  final Widget child; const LeafBackdrop({super.key,required this.child});
  @override Widget build(BuildContext context)=>Stack(children:[
    Positioned(top:-12,left:-18,child:Transform.rotate(angle:-.5,child:const Text('🌿',style:TextStyle(fontSize:82)))),
    Positioned(top:55,right:-28,child:Transform.rotate(angle:2.5,child:const Text('🌿',style:TextStyle(fontSize:78)))),
    SafeArea(child:child),
  ]);
}

// ───────────────────────── WELCOME / GET STARTED (matches Figma design) ─────────────────────────
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Floating "glass" chip drawn over the hero picture (positions are fractions of the picture size)
  Widget _chip(double w, {required double left, required double top, required IconData icon, required String label, required String value}) => Positioned(
    left: w * left, top: w * .787 * top, width: w * .26, height: w * .787 * .155,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: w * .02),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8)]),
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [
        Container(width: 26, height: 26, decoration: const BoxDecoration(color: Color(0xFFE8EFE6), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: const Color(0xFF1F4D2B))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3F8F2A))),
        ]),
        const SizedBox(width: 6),
      ])),
    ),
  );

  Widget _feature(IconData icon, String text) => Expanded(child: Column(children: [
    Container(width: 30, height: 30, decoration: const BoxDecoration(color: Color(0xFFEDEDE8), shape: BoxShape.circle),
      child: Icon(icon, size: 19, color: const Color(0xFF2F3B30))),
    const SizedBox(height: 8),
    Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Color(0xFF333333), height: 1.35)),
  ]));
  Widget _vline() => Container(width: 1, height: 52, color: const Color(0xFFDCDCD6));

  @override Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(children: [
        authLeaves(context),
        SingleChildScrollView(padding: const EdgeInsets.fromLTRB(26, 0, 26, 24), child: Column(children: [
          SizedBox(height: top + 14),
          Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 12, offset: const Offset(0, 5))]),
            child: Padding(padding: const EdgeInsets.all(10), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
          const SizedBox(height: 14),
          const Text('FRUITECTIVES', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: .5, height: 1)),
          const SizedBox(height: 2),
          const Text('2.0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1FA33A), height: 1)),
          const SizedBox(height: 18),
          const Text('Smarter Detection Deeper Insights\nBetter Decisions', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _regBrown, height: 1.45)),
          const SizedBox(height: 28),
          // hero picture with the four result chips
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            return ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(width: w, height: w * .787, child: Stack(children: [
                Positioned.fill(child: Image.asset('assets/images/welcome_hero.png', fit: BoxFit.cover)),
                _chip(w, left: .07, top: .094, icon: Icons.adjust, label: 'Ripeness', value: 'Ripe'),
                _chip(w, left: .67, top: .062, icon: Icons.verified_user_outlined, label: 'Quality', value: 'Good'),
                _chip(w, left: .04, top: .487, icon: Icons.monitor_heart_outlined, label: 'Freshness', value: 'High'),
                _chip(w, left: .71, top: .48, icon: Icons.eco_outlined, label: 'Defects', value: 'None'),
              ])),
            );
          }),
          const SizedBox(height: 28),
          // "Smarter fruit Decisions" card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.fromLTRB(10, 28, 10, 22),
            decoration: BoxDecoration(color: const Color(0xFFF6F6F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD6D6D0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.16), blurRadius: 22, offset: const Offset(0, 12))]),
            child: Column(children: [
              const Text('Smarter fruit Decisions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 26),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _feature(Icons.adjust, 'Ripeness\nDetection'), _vline(),
                _feature(Icons.water_drop_outlined, 'Freshness\nAssessment'), _vline(),
                _feature(Icons.biotech_outlined, 'Defect\nDetection'), _vline(),
                _feature(Icons.edit_calendar_outlined, 'Shelf-life\nPrediction'), _vline(),
                _feature(Icons.lightbulb_outline, 'Smart\nRecommendations'),
              ]),
            ]),
          ),
          const SizedBox(height: 44),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            onPressed: () => go(context, const LoginPage()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006B35), foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
            child: const Text("Let's get started!", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          )),
        ])),
      ]),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text; final VoidCallback onTap; final IconData? icon;
  const PrimaryButton({super.key,required this.text,required this.onTap,this.icon});
  @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:48,child:ElevatedButton(
      onPressed:onTap,style:ElevatedButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),elevation:0),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[if(icon!=null) ...[Icon(icon,size:18),const SizedBox(width:8)],Text(text,style:const TextStyle(fontWeight:FontWeight.w700))])));
}
class OutlineButtonX extends StatelessWidget {
  final String text; final VoidCallback onTap; final IconData? icon;
  const OutlineButtonX({super.key,required this.text,required this.onTap,this.icon});
  @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:46,child:OutlinedButton(onPressed:onTap,style:OutlinedButton.styleFrom(foregroundColor:green,side:const BorderSide(color:green),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[if(icon!=null) ...[Icon(icon,size:18),const SizedBox(width:8)],Text(text,style:const TextStyle(fontWeight:FontWeight.w700))])));
}
class Field extends StatelessWidget {
  final String label; final String hint; final IconData icon; final bool obscure;
  final TextEditingController? controller; final TextInputType? keyboardType;
  const Field({super.key,required this.label,required this.hint,required this.icon,this.obscure=false,this.controller,this.keyboardType});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),const SizedBox(height:7),
    TextField(controller:controller,keyboardType:keyboardType,obscureText:obscure,decoration:InputDecoration(prefixIcon:Icon(icon,size:19,color:leaf),hintText:hint,filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(vertical:14,horizontal:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:BorderSide.none))),
  ]));
}
class AuthShell extends StatelessWidget {
  final String title, subtitle; final Widget content;
  const AuthShell({super.key,required this.title,required this.subtitle,required this.content});
  @override Widget build(BuildContext context)=>Scaffold(body:LeafBackdrop(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,18,24,24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const SizedBox(height:12),const Center(child:Brand(size:44)),const SizedBox(height:25),
    Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:8),
    Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,height:1.5)),const SizedBox(height:24),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white.withOpacity(.96),borderRadius:BorderRadius.circular(22),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.03),blurRadius:20)]),child:content),
  ]))));
}
// ───────────────────────── LOGIN (matches Figma design) ─────────────────────────
const _pageBg = Color(0xFFF6F5F0);
const _darkGreen2 = Color(0xFF166534);

// Corner leaves used on the auth screens
Widget authLeaves(BuildContext context){
  final top=MediaQuery.of(context).padding.top;
  return Stack(children:[
    Positioned(top:top+20,left:0,child:Image.asset('assets/images/leaf_left.png',width:80)),
    Positioned(top:top+6,right:0,child:Image.asset('assets/images/leaf_right.png',width:80)),
  ]);
}

class LoginPage extends StatefulWidget {
  final String? initialEmail;
  const LoginPage({super.key,this.initialEmail});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage>{
  late final _email=TextEditingController(text:widget.initialEmail??''); final _password=TextEditingController();
  bool _loading=false, _hidePass=true;
  @override void dispose(){_email.dispose();_password.dispose();super.dispose();}

  Future<void> _login() async {
    final email=_email.text.trim(); final password=_password.text;
    if(email.isEmpty||password.isEmpty){toast(context,'Please enter your email and password.');return;}
    setState(()=>_loading=true);
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email:email,password:password);
      if(!mounted) return;
      replace(context,const DashboardPage());
    }catch(e){
      if(mounted) toast(context,authError(e));
    }finally{
      if(mounted) setState(()=>_loading=false);
    }
  }

  Widget _input({required TextEditingController c,required String hint,required IconData icon,TextInputType? type,bool? hidden,VoidCallback? onEye})=>Container(
    height:44,
    margin:const EdgeInsets.only(bottom:12),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(8),border:Border.all(color:const Color(0xFFD4D4D4)),
      boxShadow:[BoxShadow(color:Colors.black.withOpacity(.10),blurRadius:10,offset:const Offset(0,6))]),
    child:TextField(
      controller:c,keyboardType:type,obscureText:hidden??false,
      style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600),
      decoration:InputDecoration(
        border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(vertical:12),
        hintText:hint,hintStyle:const TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w600),
        prefixIcon:Icon(icon,color:green,size:21),
        suffixIcon:onEye==null?null:IconButton(onPressed:onEye,icon:Icon(hidden!?Icons.visibility_off_outlined:Icons.visibility_outlined,color:Colors.grey,size:20)),
      ),
    ),
  );

  @override Widget build(BuildContext context){
    final top=MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor:_pageBg,
      body:Stack(children:[
        authLeaves(context),
        SingleChildScrollView(child:Column(children:[
          SizedBox(height:top+16),
          // logo
          Container(width:64,height:64,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.15),blurRadius:12,offset:const Offset(0,5))]),
            child:Padding(padding:const EdgeInsets.all(9),child:Image.asset('assets/images/logo.png',fit:BoxFit.contain))),
          const SizedBox(height:12),
          const Text('FRUITECTIVES',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:Colors.black,letterSpacing:.5,height:1)),
          const SizedBox(height:4),
          const Text('2.0',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:Color(0xFF1FA33A),height:1)),
          const SizedBox(height:8),
          const Text('Smarter Detection Deeper Insights\nBetter Decisions',textAlign:TextAlign.center,
            style:TextStyle(fontSize:10.5,fontWeight:FontWeight.w700,color:_regBrown,height:1.4)),
          const SizedBox(height:8),
          // hero picture + badge
          Stack(clipBehavior:Clip.none,alignment:Alignment.bottomCenter,children:[
            Image.asset('assets/images/login_hero.png',width:double.infinity,fit:BoxFit.fitWidth),
            Positioned(bottom:-30,child:Container(
              padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
              decoration:BoxDecoration(color:Colors.white.withOpacity(.92),borderRadius:BorderRadius.circular(10),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(.06),blurRadius:10)]),
              child:Row(mainAxisSize:MainAxisSize.min,children:[
                Container(width:34,height:34,decoration:const BoxDecoration(color:Color(0xFFEAF2EA),shape:BoxShape.circle),
                  child:const Icon(Icons.verified_user_outlined,color:_darkGreen2,size:20)),
                const SizedBox(width:10),
                const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('AI-Powered  •  Accurate  •  Reliable',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:_darkGreen2)),
                  SizedBox(height:2),
                  Text('Your pocket expert in fruit quality.',style:TextStyle(fontSize:10,color:muted)),
                ]),
              ]),
            )),
          ]),
          const SizedBox(height:44),
          // grey sheet with the form
          Container(
            width:double.infinity,
            padding:const EdgeInsets.fromLTRB(26,18,26,24),
            decoration:BoxDecoration(color:_regSheet,borderRadius:const BorderRadius.vertical(top:Radius.circular(36)),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(.06),blurRadius:12,offset:const Offset(0,-2))]),
            child:Column(children:[
              const Text('Welcome back!',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:Colors.black)),
              const SizedBox(height:6),
              const Text('Log in to continue your health journey.',style:TextStyle(fontSize:10,color:Colors.black87)),
              const SizedBox(height:18),
              _input(c:_email,hint:'Email Address',icon:Icons.mail_outline,type:TextInputType.emailAddress),
              _input(c:_password,hint:'Password',icon:Icons.lock_outline,hidden:_hidePass,onEye:()=>setState(()=>_hidePass=!_hidePass)),
              Align(alignment:Alignment.centerRight,child:GestureDetector(
                onTap:()=>go(context,const ForgotPage()),
                child:const Padding(padding:EdgeInsets.symmetric(vertical:4),child:Text('Forgot Password?',style:TextStyle(color:_darkGreen2,fontSize:10.5,fontWeight:FontWeight.w800))))),
              const SizedBox(height:6),
              // black pill button
              SizedBox(width:double.infinity,height:44,child:ElevatedButton(
                onPressed:_loading?null:_login,
                style:ElevatedButton.styleFrom(backgroundColor:Colors.black,foregroundColor:Colors.white,disabledBackgroundColor:Colors.black54,shape:const StadiumBorder(),elevation:0),
                child:_loading
                  ?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2.5,color:Colors.white))
                  :const Row(children:[
                      SizedBox(width:24),
                      Expanded(child:Text('Log In',textAlign:TextAlign.center,style:TextStyle(fontSize:19,fontWeight:FontWeight.w700))),
                      CircleAvatar(radius:12,backgroundColor:Colors.white,child:Icon(Icons.chevron_right,color:Colors.black,size:20)),
                    ]),
              )),
              const SizedBox(height:14),
              const Row(children:[
                Expanded(child:Divider(color:Color(0xFFD4D4D4))),
                Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Text('OR',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:muted))),
                Expanded(child:Divider(color:Color(0xFFD4D4D4))),
              ]),
              const SizedBox(height:10),
              // continue as guest
              GestureDetector(
                onTap:()=>replace(context,const DashboardPage()),
                child:Container(
                  width:190,height:36,
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(6),border:Border.all(color:const Color(0xFF22C55E),width:1.5),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(.10),blurRadius:10,offset:const Offset(0,5))]),
                  child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                    Icon(Icons.person,color:Color(0xFF16A34A),size:20),SizedBox(width:12),
                    Text('Continue as Guest',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:Colors.black)),
                  ]),
                ),
              ),
              const SizedBox(height:18),
              // create account card
              InkWell(
                onTap:()=>go(context,const RegisterPage()),
                borderRadius:BorderRadius.circular(8),
                child:Container(
                  padding:const EdgeInsets.symmetric(horizontal:12,vertical:12),
                  decoration:BoxDecoration(color:const Color(0xFFE8E5D6),borderRadius:BorderRadius.circular(8)),
                  child:const Row(children:[
                    Icon(Icons.eco,color:Color(0xFF3F8F2A),size:34),
                    SizedBox(width:16),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text("Don't have an account?",style:TextStyle(fontSize:10.5,color:muted,fontWeight:FontWeight.w600)),
                      SizedBox(height:4),
                      Text('Create Account',style:TextStyle(fontSize:12.5,fontWeight:FontWeight.w800,color:Colors.black)),
                    ])),
                    Icon(Icons.chevron_right,color:Colors.black,size:30),
                  ]),
                ),
              ),
            ]),
          ),
        ])),
      ]),
    );
  }
}

// ───────────────────────── REGISTER (matches Figma design) ─────────────────────────
const _regBrown = Color(0xFF4A2511);
const _regSheet = Color(0xFFEFEFEF);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState()=>_RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage>{
  final _name=TextEditingController(); final _email=TextEditingController();
  final _password=TextEditingController(); final _confirm=TextEditingController();
  bool _hidePass=true, _hideConfirm=true, _agreed=false, _loading=false;

  @override void initState(){super.initState();_password.addListener(()=>setState((){}));}
  @override void dispose(){_name.dispose();_email.dispose();_password.dispose();_confirm.dispose();super.dispose();}

  // Password rules shown in the checklist card
  List<(String,bool)> get _rules {
    final p=_password.text;
    return [
      ('At least 8 characters', p.length>=8),
      ('One uppercase letter (A-Z)', RegExp(r'[A-Z]').hasMatch(p)),
      ('One lowercase letter (a - z)', RegExp(r'[a-z]').hasMatch(p)),
      ('One number (0-9)', RegExp(r'[0-9]').hasMatch(p)),
      (r'One special character (!@#$%^&*)', RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]\\/;]').hasMatch(p)),
    ];
  }

  Future<void> _register() async {
    final name=_name.text.trim(), email=_email.text.trim();
    if(name.isEmpty){toast(context,'Please enter your full name.');return;}
    if(!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)){toast(context,'Please enter a valid email address.');return;}
    if(_rules.any((r)=>!r.$2)){toast(context,'Your password does not meet all the requirements.');return;}
    if(_password.text!=_confirm.text){toast(context,'Passwords do not match.');return;}
    if(!_agreed){toast(context,'Please agree to the Terms & Conditions.');return;}
    setState(()=>_loading=true);
    try{
      final cred=await FirebaseAuth.instance.createUserWithEmailAndPassword(email:email,password:_password.text);
      await cred.user?.updateDisplayName(name);
      if(!mounted) return;
      await FirebaseAuth.instance.signOut(); // Firebase signs in automatically; make the user log in
      if(!mounted) return;
      toast(context,'Account created! Please log in with your new account.');
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>LoginPage(initialEmail:email)),(r)=>r.isFirst);
    }catch(e){
      if(mounted) toast(context,authError(e));
    }finally{
      if(mounted) setState(()=>_loading=false);
    }
  }

  void _showTerms()=>showDialog(context:context,builder:(_)=>AlertDialog(
    title:const Text('Terms & Conditions'),
    content:const SingleChildScrollView(child:Text(
      'By creating a FRUITECTIVES 2.0 account you agree to use the app for personal fruit identification and learning. '
      'Fruit scan results are estimates and should not replace professional food-safety advice. '
      'We store your name and email to manage your account and will not share them with third parties.',
      style:TextStyle(height:1.5))),
    actions:[TextButton(onPressed:(){setState(()=>_agreed=true);Navigator.pop(context);},child:const Text('I Agree',style:TextStyle(color:green)))],
  ));

  Widget _input({required TextEditingController c,required String hint,required IconData icon,TextInputType? type,bool? hidden,VoidCallback? onEye})=>Padding(
    padding:const EdgeInsets.only(bottom:14),
    child:Container(
      height:50,
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10)),
      child:TextField(
        controller:c,keyboardType:type,obscureText:hidden??false,
        style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600),
        decoration:InputDecoration(
          border:InputBorder.none,
          contentPadding:const EdgeInsets.symmetric(vertical:15),
          hintText:hint,hintStyle:const TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w600),
          prefixIcon:Icon(icon,color:green,size:22),
          suffixIcon:onEye==null?null:IconButton(
            onPressed:onEye,
            icon:Icon(hidden!?Icons.visibility_off_outlined:Icons.visibility_outlined,color:Colors.grey,size:21)),
        ),
      ),
    ),
  );

  @override Widget build(BuildContext context){
    final top=MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor:cream,
      body:Stack(children:[
        // corner leaves
        authLeaves(context),
        SingleChildScrollView(child:Column(children:[
          SizedBox(height:top+20),
          // logo
          Container(width:52,height:52,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.12),blurRadius:10,offset:const Offset(0,4))]),
            child:Padding(padding:const EdgeInsets.all(7),child:Image.asset('assets/images/logo.png',fit:BoxFit.contain))),
          const SizedBox(height:8),
          const Text('FRUITECTIVES',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:Colors.black,letterSpacing:.5)),
          const Text('2.0',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:Color(0xFF1FA33A),height:1)),
          const SizedBox(height:14),
          const Text('Create Your Account',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800,color:Colors.black)),
          const SizedBox(height:12),
          const Text('Join FRUITECTIVES 2.0 and start\nyour fruit journey today.',textAlign:TextAlign.center,
            style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w700,color:_regBrown,height:1.4)),
          const SizedBox(height:24),
          // grey sheet with the form
          Container(
            width:double.infinity,
            constraints:BoxConstraints(minHeight:MediaQuery.of(context).size.height*.6),
            padding:const EdgeInsets.fromLTRB(18,34,18,24),
            decoration:BoxDecoration(color:_regSheet,borderRadius:const BorderRadius.vertical(top:Radius.circular(36)),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(.06),blurRadius:12,offset:const Offset(0,-2))]),
            child:Column(children:[
              _input(c:_name,hint:'Full name',icon:Icons.person),
              _input(c:_email,hint:'Email Address',icon:Icons.mail_outline,type:TextInputType.emailAddress),
              _input(c:_password,hint:'Password',icon:Icons.lock_outline,hidden:_hidePass,onEye:()=>setState(()=>_hidePass=!_hidePass)),
              _input(c:_confirm,hint:'Confirm Password',icon:Icons.lock_outline,hidden:_hideConfirm,onEye:()=>setState(()=>_hideConfirm=!_hideConfirm)),
              const SizedBox(height:16),
              // password rules card
              Container(
                width:double.infinity,
                padding:const EdgeInsets.fromLTRB(40,20,20,24),
                decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFDADADA)),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(.12),blurRadius:16,offset:const Offset(0,8))]),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Text('Password must contain:',style:TextStyle(fontSize:10.5,fontWeight:FontWeight.w800,color:_regBrown)),
                  const SizedBox(height:12),
                  for(final r in _rules) Padding(padding:const EdgeInsets.only(bottom:4),child:Row(children:[
                    Icon(r.$2?Icons.check_circle:Icons.check_circle_outline,size:13,color:r.$2?const Color(0xFF22C55E):Colors.grey.shade400),
                    const SizedBox(width:6),
                    Text(r.$1,style:TextStyle(fontSize:10.5,color:r.$2?const Color(0xFF15803D):Colors.grey.shade600)),
                  ])),
                ]),
              ),
              const SizedBox(height:24),
              // terms
              Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                GestureDetector(onTap:()=>setState(()=>_agreed=!_agreed),child:Container(
                  width:16,height:16,
                  decoration:BoxDecoration(shape:BoxShape.circle,color:_agreed?const Color(0xFF16C60C):Colors.white,border:Border.all(color:const Color(0xFF16C60C),width:1.5)),
                  child:_agreed?const Center(child:CircleAvatar(radius:2.5,backgroundColor:Color(0xFF0B5E07))):null)),
                const SizedBox(width:8),
                const Text('I agree to the ',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
                GestureDetector(onTap:_showTerms,child:const Text('Terms & Conditions',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Color(0xFF15803D)))),
              ]),
              const SizedBox(height:18),
              // black pill button
              SizedBox(width:double.infinity,height:52,child:ElevatedButton(
                onPressed:_loading?null:_register,
                style:ElevatedButton.styleFrom(backgroundColor:Colors.black,foregroundColor:Colors.white,disabledBackgroundColor:Colors.black54,shape:const StadiumBorder(),elevation:0),
                child:_loading
                  ?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2.5,color:Colors.white))
                  :const Row(children:[
                      SizedBox(width:24),
                      Expanded(child:Text('Create Account',textAlign:TextAlign.center,style:TextStyle(fontSize:18,fontWeight:FontWeight.w700))),
                      CircleAvatar(radius:12,backgroundColor:Colors.white,child:Icon(Icons.chevron_right,color:Colors.black,size:20)),
                    ]),
              )),
              const SizedBox(height:16),
              Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                const Text('Already have an account? ',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w700,color:_regBrown)),
                GestureDetector(onTap:()=>Navigator.canPop(context)?Navigator.pop(context):replace(context,const LoginPage()),
                  child:const Text('Log in',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w800,color:Color(0xFF15803D)))),
              ]),
            ]),
          ),
        ])),
      ]),
    );
  }
}
// ───────────────────────── FORGOT PASSWORD FLOW (matches Figma design) ─────────────────────────
// NOTE: Firebase cannot email 6-digit codes by itself (it only sends reset links).
// Until a backend is added, the code is generated in the app and shown on screen (DEMO MODE).
const _olive = Color(0xFF4D7C0F);
const _brightGreen = Color(0xFF16C60C);
const _red = Color(0xFFEF4444);

String _demoCode() => (100000 + Random().nextInt(900000)).toString();
void _showDemoCode(BuildContext context, String code) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  duration: const Duration(seconds: 8),
  backgroundColor: _darkGreen2,
  content: Text('DEMO: your verification code is $code'),
));

// Shared pieces
Widget _authScaffold(BuildContext context, List<Widget> children, {Color bg = _pageBg}) => Scaffold(
  backgroundColor: bg,
  body: Stack(children: [
    authLeaves(context),
    SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), child: Column(children: children))),
  ]),
);
Widget _logoBox() => Container(width: 64, height: 64,
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 12, offset: const Offset(0, 5))]),
  child: Padding(padding: const EdgeInsets.all(9), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)));
Widget _title(String t) => Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.black, height: 1.15));
Widget _blackButton(String text, VoidCallback? onTap, {bool circleArrow = true, double radius = 30, bool loading = false}) => SizedBox(
  width: double.infinity, height: 54,
  child: ElevatedButton(
    onPressed: loading ? null : onTap,
    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, disabledBackgroundColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)), elevation: 0),
    child: loading
      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
      : Row(children: [
          const SizedBox(width: 24),
          Expanded(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          circleArrow
            ? const CircleAvatar(radius: 11, backgroundColor: Colors.white, child: Icon(Icons.chevron_right, color: Colors.black, size: 18))
            : const Icon(Icons.chevron_right, color: Colors.white, size: 30),
        ]),
  ),
);
Widget _greenOutlineButton(String text, IconData icon, VoidCallback? onTap) => SizedBox(
  width: double.infinity, height: 54,
  child: OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: _brightGreen, width: 1.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    child: Row(children: [
      Icon(icon, color: onTap == null ? Colors.grey : _darkGreen2, size: 28),
      Expanded(child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onTap == null ? Colors.grey : _olive))),
      const SizedBox(width: 28),
    ]),
  ),
);
Widget _orDivider() => const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Row(children: [
  Expanded(child: Divider(color: Color(0xFFDDDDD5))),
  Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('OR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted))),
  Expanded(child: Divider(color: Color(0xFFDDDDD5))),
]));
String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

// 1) FORGOT PASSWORD
class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});
  @override State<ForgotPage> createState() => _ForgotPageState();
}
class _ForgotPageState extends State<ForgotPage> {
  final _email = TextEditingController();
  @override void dispose() { _email.dispose(); super.dispose(); }

  void _send() {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) { toast(context, 'Please enter a valid email address.'); return; }
    FocusScope.of(context).unfocus();
    go(context, VerifyPage(email: email));
  }

  @override Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(children: [
        authLeaves(context),
        SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(children: [
            SizedBox(height: top + 16),
            _logoBox(),
            const SizedBox(height: 18),
            _title('Forgot Password?'),
            const SizedBox(height: 14),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text(
              "No worries! Enter the email address associated with your account, and we'll send you a 6-digit code to reset your password",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _regBrown, height: 1.45))),
            const SizedBox(height: 18),
            // white sheet
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * .62),
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 14, offset: const Offset(0, -2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(left: 8), child: Text('Email Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black))),
                const SizedBox(height: 12),
                TextField(
                  controller: _email, keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address', hintStyle: const TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600),
                    prefixIcon: const Padding(padding: EdgeInsets.only(left: 18, right: 10), child: Icon(Icons.mail_outline, color: _olive, size: 20)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 24),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFB5B5B5), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: green, width: 1.8)),
                  ),
                ),
                const SizedBox(height: 16),
                _blackButton('Send Code', _send, circleArrow: false, radius: 20),
                _orDivider(),
                _greenOutlineButton('Go Back', Icons.arrow_back, () => Navigator.pop(context)),
                const SizedBox(height: 36),
                // security note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  decoration: BoxDecoration(color: const Color(0xFFF4F4F1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    CircleAvatar(radius: 30, backgroundColor: Color(0xFFE2DED5), child: Icon(Icons.verified_user_outlined, color: _olive, size: 28)),
                    SizedBox(width: 30),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your account security is our priority.', style: TextStyle(fontSize: 10, color: muted)),
                      SizedBox(height: 6),
                      Text("We'll only use your email to reset your password.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black, height: 1.6)),
                    ])),
                  ]),
                ),
              ]),
            ),
          ]),
        )),
      ]),
    );
  }
}

// 2) CHECK YOUR EMAIL (6-digit code)
class VerifyPage extends StatefulWidget {
  final String email;
  const VerifyPage({super.key, required this.email});
  @override State<VerifyPage> createState() => _VerifyPageState();
}
class _VerifyPageState extends State<VerifyPage> {
  final _boxes = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  late String _code;
  int _expires = 600, _resendIn = 45;
  bool _error = false;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _newCode();
    WidgetsBinding.instance.addPostFrameCallback((_) { _showDemoCode(context, _code); _nodes[0].requestFocus(); });
  }
  void _newCode() {
    _code = _demoCode();
    _expires = 600; _resendIn = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_expires > 0) _expires--; if (_resendIn > 0) _resendIn--; });
    });
  }
  @override void dispose() {
    _timer?.cancel();
    for (final c in _boxes) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  void _onDigit(int i, String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) { // pasted a code
      for (var k = 0; k < 6; k++) { _boxes[k].text = k < digits.length ? digits[k] : ''; }
      _nodes[(digits.length >= 6 ? 5 : digits.length)].requestFocus();
    } else {
      _boxes[i].text = digits;
      if (digits.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
      if (digits.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    }
    setState(() => _error = false);
  }

  void _verify() {
    final entered = _boxes.map((c) => c.text).join();
    if (entered.length < 6) { toast(context, 'Please enter all 6 digits.'); return; }
    if (_expires == 0) { toast(context, 'This code has expired. Tap Resend Code.'); return; }
    if (entered != _code) { setState(() => _error = true); return; }
    _timer?.cancel();
    go(context, ResetPage(email: widget.email));
  }

  void _resend() {
    for (final c in _boxes) { c.clear(); }
    setState(() { _error = false; _newCode(); });
    _nodes[0].requestFocus();
    _showDemoCode(context, _code);
  }

  Widget _box(int i) => SizedBox(width: 50, height: 70, child: TextField(
    controller: _boxes[i], focusNode: _nodes[i],
    textAlign: TextAlign.center, keyboardType: TextInputType.number,
    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.black),
    onChanged: (v) => _onDigit(i, v),
    decoration: InputDecoration(
      filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _error ? _red : const Color(0xFFB5B5B5), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _error ? _red : green, width: 1.8)),
    ),
  ));

  @override Widget build(BuildContext context) => _authScaffold(context, [
    const SizedBox(height: 50),
    _title('Check Your Email'),
    const SizedBox(height: 40),
    const Text("We've sent a 6 - digit verification code to", textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: _regBrown)),
    const SizedBox(height: 2),
    Text(widget.email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _regBrown)),
    const SizedBox(height: 14),
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFE5E0D9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 16, offset: const Offset(0, 8))]),
      child: const Row(children: [
        Icon(Icons.verified_user_outlined, color: _olive, size: 28),
        SizedBox(width: 18),
        Expanded(child: Text('Enter the 6-digit code we sent to your email address.', style: TextStyle(fontSize: 11, color: _regBrown, height: 1.4))),
      ]),
    ),
    const SizedBox(height: 26),
    const Align(alignment: Alignment.centerLeft, child: Text('Verification Code', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black))),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, _box)),
    const SizedBox(height: 14),
    Text.rich(TextSpan(style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted), children: [
      const TextSpan(text: 'Code expires in '),
      TextSpan(text: _mmss(_expires), style: TextStyle(color: _expires == 0 ? _red : const Color(0xFF22A33A))),
    ])),
    if (_error) const Padding(padding: EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error, color: _red, size: 20), SizedBox(width: 6),
      Text('Invalid code. Please try again.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _red)),
    ])),
    const SizedBox(height: 24),
    _greenOutlineButton('Resend Code', Icons.sync, _resendIn == 0 ? _resend : null),
    const SizedBox(height: 12),
    _blackButton('Verify Code', _verify, circleArrow: false, radius: 20),
    const SizedBox(height: 10),
    Text.rich(TextSpan(style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted), children: [
      TextSpan(text: _resendIn == 0 ? 'You can resend the code now' : 'Resend code in '),
      if (_resendIn > 0) TextSpan(text: _mmss(_resendIn), style: const TextStyle(color: Color(0xFF22A33A))),
    ])),
    _orDivider(),
    _greenOutlineButton('Go Back to Login', Icons.arrow_back,
      () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false)),
  ]);
}

// 3) CREATE NEW PASSWORD
class ResetPage extends StatefulWidget {
  final String email;
  const ResetPage({super.key, required this.email});
  @override State<ResetPage> createState() => _ResetPageState();
}
class _ResetPageState extends State<ResetPage> {
  final _pass = TextEditingController(), _confirm = TextEditingController();
  bool _hide1 = true, _hide2 = true, _loading = false;
  @override void initState() { super.initState(); _pass.addListener(() => setState(() {})); }
  @override void dispose() { _pass.dispose(); _confirm.dispose(); super.dispose(); }

  List<(String, bool)> get _rules {
    final p = _pass.text;
    return [
      ('At least 8 characters', p.length >= 8),
      ('One uppercase letter (A-Z)', RegExp(r'[A-Z]').hasMatch(p)),
      ('One lowercase letter (a - z)', RegExp(r'[a-z]').hasMatch(p)),
      ('One number (0-9)', RegExp(r'[0-9]').hasMatch(p)),
      (r'One special character (!@#$%^&*)', RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]\\/;]').hasMatch(p)),
    ];
  }
  int get _score => _rules.where((r) => r.$2).length;
  (String, Color) get _strength {
    if (_pass.text.isEmpty) return ('', muted);
    if (_score <= 2) return ('Weak', _red);
    if (_score == 3) return ('Fair', const Color(0xFFF59E0B));
    if (_score == 4) return ('Good', const Color(0xFF84CC16));
    return ('Strong', _darkGreen2);
  }

  Future<void> _update() async {
    if (_score < 5) { toast(context, 'Your password does not meet all the requirements.'); return; }
    if (_pass.text != _confirm.text) { toast(context, 'Passwords do not match.'); return; }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // DEMO: replace with backend call
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PasswordSuccessPage()), (_) => false);
  }

  Widget _passField(TextEditingController c, String hint, bool hidden, VoidCallback onEye, {BorderRadius? radius, bool border = true}) => Container(
    height: 64,
    decoration: BoxDecoration(color: Colors.white, borderRadius: radius ?? BorderRadius.circular(16),
      border: border ? Border.all(color: const Color(0xFFB5B5B5), width: 1.5) : null),
    child: TextField(
      controller: c, obscureText: hidden,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 21),
        hintText: hint, hintStyle: const TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 10), child: Icon(Icons.lock_outline, color: Color(0xFF22A33A), size: 24)),
        suffixIcon: IconButton(onPressed: onEye, icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20)),
      ),
    ),
  );

  @override Widget build(BuildContext context) {
    final (label, color) = _strength;
    return _authScaffold(context, [
      const SizedBox(height: 50),
      _title('Create New\nPassword'),
      const SizedBox(height: 40),
      const Text('Enter your new password below.', style: TextStyle(fontSize: 12, color: _regBrown)),
      const SizedBox(height: 26),
      // new password + strength meter in one bordered card
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFB5B5B5), width: 1.5)),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: const Color(0xFFB5B5B5).withOpacity(.7), width: 1.5))),
            child: _passField(_pass, 'New Password', _hide1, () => setState(() => _hide1 = !_hide1), border: false),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 14), child: Column(children: [
            Row(children: [
              const Text('Password Strength', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _regBrown)),
              const Spacer(),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ]),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(height: 9, color: const Color(0xFFE5E7EB), child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 250),
                  widthFactor: _score / 5,
                  child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [
                    Color(0xFF7DD3FC), Color(0xFF4ADE80), Color(0xFFD9F99D), Color(0xFFFACC15), Color(0xFFFB923C), Color(0xFFF43F5E)]))),
                ),
              )),
            )),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _passField(_confirm, 'Confirm New Password', _hide2, () => setState(() => _hide2 = !_hide2), radius: BorderRadius.circular(12))),
      const SizedBox(height: 20),
      // rules card
      Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        decoration: BoxDecoration(color: const Color(0xFFF4F4F1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDADADA)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 18, offset: const Offset(0, 10))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Password must contain:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _regBrown)),
          const SizedBox(height: 14),
          for (final r in _rules) Padding(padding: const EdgeInsets.only(left: 6, bottom: 5), child: Row(children: [
            Icon(r.$2 ? Icons.check_circle : Icons.check_circle_outline, size: 15, color: r.$2 ? const Color(0xFF16C60C) : Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(r.$1, style: TextStyle(fontSize: 12.5, color: r.$2 ? const Color(0xFF15803D) : Colors.grey.shade600)),
          ])),
        ]),
      ),
      const SizedBox(height: 30),
      _blackButton('Update Password', _update, loading: _loading),
    ]);
  }
}

// 4) PASSWORD CHANGE SUCCESSFUL
class PasswordSuccessPage extends StatelessWidget {
  const PasswordSuccessPage({super.key});
  Widget _sparkle(double size) => CustomPaint(size: Size(size, size), painter: _SparklePainter());
  @override Widget build(BuildContext context) => _authScaffold(context, [
    const SizedBox(height: 30),
    SizedBox(width: 260, height: 210, child: Stack(alignment: Alignment.center, children: [
      Container(width: 176, height: 176, decoration: BoxDecoration(color: const Color(0xFF009B00), shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF009B00).withOpacity(.25), blurRadius: 20, offset: const Offset(0, 8))]),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 130, shadows: [Shadow(color: Color(0xFF005A00), offset: Offset(4, 5))])),
      Positioned(top: 0, right: 30, child: _sparkle(28)),
      Positioned(left: 0, bottom: 50, child: _sparkle(40)),
      Positioned(right: 0, bottom: 10, child: _sparkle(62)),
    ])),
    const SizedBox(height: 40),
    _title('Password Change\nSuccessful!'),
    const SizedBox(height: 12),
    const Text('Your password has been updated\nsuccessfully.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: muted, height: 1.4)),
    const SizedBox(height: 30),
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade500, width: 1.2)),
          child: const Icon(Icons.verified_user, color: Color(0xFF008A00), size: 36)),
        const SizedBox(height: 18),
        const Text('Your account is now more secure.\nYou can now log in using your\nnew password.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: muted, height: 1.5)),
      ]),
    ),
    const SizedBox(height: 60),
    _blackButton('Go to login', () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false)),
  ]);
}
class _SparklePainter extends CustomPainter {
  @override void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, cx = w / 2, cy = h / 2;
    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF2E9E2E));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget heading(String title,{String? sub})=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:ink)),if(sub!=null) ...[const SizedBox(height:4),Text(sub,style:const TextStyle(fontSize:12,color:muted))]]);
Widget panel(Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFEDEFE8))),child:child);
Widget fruitTile(String emoji,String name,String detail,{VoidCallback? onTap})=>InkWell(onTap:onTap,child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFEDEFE8))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Center(child:Text(emoji,style:const TextStyle(fontSize:35))),const SizedBox(height:5),Text(name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),Text(detail,style:const TextStyle(color:muted,fontSize:10))])));
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:0,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const CircleAvatar(backgroundColor:Color(0xFFE1EED9),child:Text('🌿')),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${greeting()}, ${firstName()}!',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)),const Text('Here’s your fruit overview',style:TextStyle(color:muted,fontSize:11))])),IconButton(onPressed:()=>go(context,const ProfilePage()),icon:const Icon(Icons.notifications_none))]),
    const SizedBox(height:16),const SmartAnalysisCard(),
    const SizedBox(height:12),const FeatureRow(),
    const SizedBox(height:18),const StatsRow(),
    const SizedBox(height:6),
    const SizedBox(height:15),const Text('Recent Analysis',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:10),
    if(currentUser==null) const GuestHistoryCard() else const RecentScans(),
    const SizedBox(height:20),panel(const Row(children:[Icon(Icons.shield_outlined,color:green,size:34),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Make informed choices',style:TextStyle(fontWeight:FontWeight.w800)),Text('Learn how to pick and store your fruits.',style:TextStyle(color:muted,fontSize:11))]))])),
  ])));
}
Widget _stat(String a,String b,IconData i)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:green,size:20),const SizedBox(height:8),Text(b,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:19)),Text(a,style:const TextStyle(color:muted,fontSize:10))]));
Widget _quick(BuildContext c,String emoji,String label,Widget page)=>InkWell(onTap:()=>go(c,page),child:Column(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(15)),child:Center(child:Text(emoji,style:const TextStyle(fontSize:23)))),const SizedBox(height:6),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700))]));
// ───────────────────────── HOME: greeting + Smart Fruit Analysis (matches Figma design) ─────────────────────────
String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}
// First word of the Full Name entered at registration (falls back to the email name, then "Guest")
String firstName() {
  final u = currentUser;
  if (u == null) return 'Guest';
  final full = (u.displayName ?? '').trim();
  if (full.isNotEmpty) return full.split(RegExp(r'\s+')).first;
  final email = u.email ?? '';
  if (email.contains('@')) { final n = email.split('@').first; return n.isEmpty ? 'there' : n[0].toUpperCase() + n.substring(1); }
  return 'there';
}

const _homeGreen = Color(0xFF1F6B2A);
const _homeInk = Color(0xFF14361C);

class SmartAnalysisCard extends StatelessWidget {
  const SmartAnalysisCard({super.key});
  @override Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF0F6EA), Color(0xFFE2EDD6)]),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: Stack(children: [
      // fruit picture on the right, fading into the card on its left edge
      Positioned(right: 0, top: 0, bottom: 0, width: MediaQuery.of(context).size.width * .5,
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.black], stops: [0, .18]).createShader(r),
          blendMode: BlendMode.dstIn,
          child: Image.asset('assets/images/home_fruits.png', fit: BoxFit.cover, alignment: Alignment.centerLeft))),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
        child: FractionallySizedBox(widthFactor: .56, alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome, size: 12, color: _homeGreen), SizedBox(width: 5),
              Text('AI-Powered', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _homeGreen)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Smart Fruit\nAnalysis', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _homeInk, height: 1.1)),
          const SizedBox(height: 10),
          const Text('Detect ripeness, assess freshness, find defects, and get storage & shelf-life recommendations.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF3F4A42), height: 1.45)),
          const SizedBox(height: 16),
          SizedBox(height: 40, child: ElevatedButton(
            onPressed: () => go(context, const UploadPage()),
            style: ElevatedButton.styleFrom(backgroundColor: _homeGreen, foregroundColor: Colors.white, shape: const StadiumBorder(),
              elevation: 4, shadowColor: _homeGreen.withOpacity(.4), padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.photo_camera_outlined, size: 18), SizedBox(width: 8),
              Text('Scan Fruit Now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)), SizedBox(width: 10),
              Icon(Icons.chevron_right, size: 18),
            ]),
          )),
        ])),
      ),
    ]),
  );
}

class FeatureRow extends StatelessWidget {
  const FeatureRow({super.key});
  Widget _item(BuildContext context, IconData icon, String title, String sub) => Expanded(child: InkWell(
    onTap: () => go(context, const UploadPage()),
    borderRadius: BorderRadius.circular(14),
    child: Column(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Icon(icon, color: const Color(0xFF2E8B2E), size: 28)),
      const SizedBox(height: 10),
      SizedBox(height: 30, child: Center(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2)))),
      const SizedBox(height: 4),
      Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: muted, height: 1.35)),
    ]),
  ));
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 14, 6, 14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(18)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _item(context, Icons.center_focus_strong_outlined, 'Identify Fruit', 'What fruit\nis this?'),
      _item(context, Icons.contrast, 'Ripeness', 'Check ripeness\nstage'),
      _item(context, Icons.verified_user_outlined, 'Freshness', 'Assess\nfreshness'),
      _item(context, Icons.pest_control_outlined, 'Defect\nDetection', 'Find visible\ndefects'),
      _item(context, Icons.edit_calendar_outlined, 'Shelf-life\nPrediction', 'Estimate shelf\nlife'),
    ]),
  );
}

// ───────────────────────── GUEST LOCK (guests must log in to use History) ─────────────────────────
void openLogin(BuildContext context) {
  final nav = Navigator.of(context);
  nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false);
  nav.push(MaterialPageRoute(builder: (_) => const LoginPage()));
}
void openRegister(BuildContext context) {
  final nav = Navigator.of(context);
  nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false);
  nav.push(MaterialPageRoute(builder: (_) => const RegisterPage()));
}

class LoginRequired extends StatelessWidget {
  final String title, message;
  const LoginRequired({super.key, required this.title, required this.message});
  @override Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 110, height: 110,
        decoration: BoxDecoration(color: const Color(0xFFE8F2E2), shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: green.withOpacity(.15), blurRadius: 20, offset: const Offset(0, 8))]),
        child: const Icon(Icons.lock_outline_rounded, color: green, size: 52)),
      const SizedBox(height: 26),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: muted, height: 1.5)),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Column(children: [
          _Perk(Icons.history, 'Keep a history of every fruit you scan'),
          _Perk(Icons.insights_outlined, 'Track freshness and ripeness over time'),
          _Perk(Icons.bookmark_border, 'Save results and recommendations'),
        ]),
      ),
      const SizedBox(height: 26),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: () => openLogin(context),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
        child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      )),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 50, child: OutlinedButton(
        onPressed: () => openRegister(context),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF16C60C), width: 1.6), shape: const StadiumBorder()),
        child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF4D7C0F))),
      )),
    ]),
  ));
}
class _Perk extends StatelessWidget {
  final IconData icon; final String text;
  const _Perk(this.icon, this.text);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Icon(icon, color: green, size: 20), const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
  ]));
}

// Shown on Home instead of "Recent Analysis" items when browsing as a guest
class GuestHistoryCard extends StatelessWidget {
  const GuestHistoryCard({super.key});
  @override Widget build(BuildContext context) => InkWell(
    onTap: () => openLogin(context),
    borderRadius: BorderRadius.circular(18),
    child: panel(const Row(children: [
      CircleAvatar(radius: 22, backgroundColor: Color(0xFFE8F2E2), child: Icon(Icons.lock_outline_rounded, color: green)),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log in to see your scans', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 2),
        Text('Guests can scan fruit, but history is only saved for accounts.', style: TextStyle(color: muted, fontSize: 11)),
      ])),
      Icon(Icons.chevron_right, color: green),
    ])),
  );
}

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    heading('AI TOOL',sub:'Explore the Fruitectives features'),const SizedBox(height:7),const Text('Powerful fruit insights, all in one place.',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:18),
    _tool(context,'📸','Fruit Recognition','Identify a fruit from a photo',const UploadPage()),_tool(context,'🟢','Ripeness Classification','Explore ripeness stages',const GuidePage(title:'Ripeness Classification',kind:0)),_tool(context,'💧','Freshness Assessment','Review freshness indicators',const GuidePage(title:'Freshness Assessment Overview',kind:1)),_tool(context,'🔎','Defect Detection','Common visible fruit defects',const GuidePage(title:'Defect Detection',kind:2)),_tool(context,'📅','Shelf-life Prediction','Storage guidance and shelf life',const GuidePage(title:'Shelf-life Prediction Overview',kind:3)),_tool(context,'🥗','Nutrition and Calories','Explore nutrition information',const NutritionPage()),const SizedBox(height:12),panel(const Text('Note: Fruit Recognition uses AI. The other tool pages are general reference guides.',style:TextStyle(color:muted,fontSize:11))),
  ])));
}
Widget _tool(BuildContext c,String e,String t,String d,Widget p)=>Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(onTap:()=>go(c,p),child:panel(Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(14)),child:Center(child:Text(e,style:const TextStyle(fontSize:25)))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(d,style:const TextStyle(color:muted,fontSize:11))])),const Icon(Icons.chevron_right,color:green)]))));

class FruitsPage extends StatelessWidget {
  const FruitsPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Supported Fruits',sub:'Browse fruits and learn more'),const SizedBox(height:12),const TextField(decoration:InputDecoration(hintText:'Search fruits...',prefixIcon:Icon(Icons.search),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.all(Radius.circular(14))))),const SizedBox(height:14),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.83,children:[fruitTile('🍌','Banana','Tropical'),fruitTile('🥭','Mango','Tropical'),fruitTile('🍎','Apple','Pome'),fruitTile('🥑','Avocado','Berry'),fruitTile('🍊','Orange','Citrus'),fruitTile('🍐','Pear','Pome'),fruitTile('🍑','Peach','Stone fruit'),fruitTile('🍍','Pineapple','Tropical'),fruitTile('🍇','Grapes','Berry'),fruitTile('🍉','Watermelon','Melon'),fruitTile('🍓','Strawberry','Berry'),fruitTile('🥥','Coconut','Tropical')]) ])));
}
class TipsPage extends StatelessWidget {
  const TipsPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Tips for Best Results',sub:'Get better photos and useful results'),const SizedBox(height:15),_tip(Icons.wb_sunny,'Use good lighting','Natural, even lighting helps you see the fruit clearly.'),_tip(Icons.center_focus_strong,'Focus on one fruit','Keep the fruit centered and in focus.'),_tip(Icons.crop_free,'Keep the background simple','Avoid clutter and strong reflections.'),_tip(Icons.rotate_90_degrees_ccw,'Capture multiple angles','Check all sides for marks and defects.'),_tip(Icons.cleaning_services,'Use a clean surface','Place fruit against a contrasting background.'),const SizedBox(height:14),PrimaryButton(text:'Camera Tips',onTap:()=>go(context,const CameraTipsPage()))])));
}
Widget _tip(IconData i,String t,String d)=>Padding(padding:const EdgeInsets.only(bottom:10),child:panel(Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:40,height:40,decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(12)),child:Icon(i,color:green)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(d,style:const TextStyle(color:muted,fontSize:12,height:1.4))]))])));
class CameraTipsPage extends StatelessWidget {
  const CameraTipsPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('CAMERA TIPS',sub:'Simple ways to improve your fruit photos'),const SizedBox(height:14),...['Lighting','Distance and focus','Background','Multiple angles'].asMap().entries.map((x)=>Padding(padding:const EdgeInsets.only(bottom:12),child:panel(Row(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(backgroundColor:const Color(0xFFEAF3E4),child:Text('${x.key+1}',style:const TextStyle(color:green,fontWeight:FontWeight.w900))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.value,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),const Text('Keep the fruit clearly visible, use a steady hand, and avoid harsh glare.',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:7),const Text('📷  🍎    📷  🥭',style:TextStyle(fontSize:22))]))]))))])));
}
class GuidePage extends StatelessWidget {
  final String title; final int kind;
  const GuidePage({super.key,required this.title,required this.kind});
  @override Widget build(BuildContext context){
    final lists = kind==0 ? [['🟢','Unripe','Firm texture; color still developing'],['🟡','Almost ripe','Color is changing; slightly softer'],['🟠','Ripe','Ready to enjoy; pleasant aroma'],['🔴','Overripe','Very soft; consume soon']] : kind==1 ? [['🟢','Very fresh','Firm appearance and vibrant color'],['🟡','Fresh','Minor changes in appearance'],['🟠','Use soon','Noticeable softening or spots'],['🔴','Not fresh','Widespread discoloration or decay']] : kind==2 ? [['🟠','Dark spots','Inspect whether spots are superficial'],['🟠','Bruising','Handle fruit gently to avoid pressure'],['🟡','Wrinkling','May indicate moisture loss'],['🔴','Mold','Avoid consuming moldy produce']] : [['🟢','Short term','Store ripe fruit for a few days'],['🟡','Room temperature','Allow some fruits to ripen on the counter'],['🟠','Refrigerate','Chill ripe fruit when appropriate'],['🔵','Check daily','Storage life varies by fruit and conditions']];
    return AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(title),const SizedBox(height:8),panel(const Text('A quick visual reference to help you understand common fruit characteristics.',style:TextStyle(color:muted,fontSize:12))),const SizedBox(height:16),Text(kind==2?'Common Defects We Detect':kind==3?'Storage Guide':'Stages and Indicators',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:10),...lists.map((x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:panel(Row(children:[Text(x[0],style:const TextStyle(fontSize:26)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x[1],style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(x[2],style:const TextStyle(color:muted,fontSize:11))]))])))),const SizedBox(height:12),panel(const Text('These are general educational guidelines, not an automated assessment.',style:TextStyle(color:muted,fontSize:11)))])));
  }
}
class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Nutrition and Calories',sub:'Example nutrition profile'),const SizedBox(height:15),panel(Column(children:[const Text('🥭',style:TextStyle(fontSize:72)),const Text('Mango',style:TextStyle(fontWeight:FontWeight.w900,fontSize:22)),const Text('Per 100 g • illustrative values',style:TextStyle(color:muted,fontSize:11)),const SizedBox(height:14),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(15)),child:const Column(children:[Text('60',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900,color:green)),Text('Calories (kcal)',style:TextStyle(color:muted))]))])),const SizedBox(height:14),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.7,crossAxisSpacing:10,mainAxisSpacing:10,children:[_nut('Carbohydrates','15 g'),_nut('Dietary fiber','1.6 g'),_nut('Protein','0.8 g'),_nut('Fat','0.4 g'),_nut('Vitamin C','36 mg'),_nut('Natural sugars','13.7 g')]),const SizedBox(height:12),panel(const Text('Nutrition varies with variety and serving size. Values shown are for demonstration only.',style:TextStyle(color:muted,fontSize:11)))])));
}
Widget _nut(String a,String b)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(b,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:green)),Text(a,style:const TextStyle(fontSize:11,color:muted))]));
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:4,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Profile'),const SizedBox(height:16),panel(Row(children:[const CircleAvatar(radius:30,backgroundColor:Color(0xFFE5F0DE),child:Icon(Icons.person,size:34,color:green)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(currentUser?.displayName ?? (currentUser==null?'Guest':'Fruitectives User'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text(currentUser==null?'Guest mode':'Signed in',style:const TextStyle(color:green,fontSize:11)),Text(currentUser?.email ?? 'Not signed in',style:const TextStyle(color:muted,fontSize:11))])),const Icon(Icons.edit_outlined,color:green)])),const SizedBox(height:20),const Text('ACCOUNT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.person_outline,'Personal Information'),_setting(context,Icons.lock_outline,'App Settings'),_setting(context,Icons.language,'Language'),_setting(context,Icons.notifications_none,'Notifications'),const SizedBox(height:12),const Text('SUPPORT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.help_outline,'Help Center'),_setting(context,Icons.feedback_outlined,'Feedback'),_setting(context,Icons.info_outline,'About Fruitectives 2.0'),const SizedBox(height:20),OutlineButtonX(text:'Log Out',icon:Icons.logout,onTap:() async {if(firebaseReady) await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}),const SizedBox(height:15),const Center(child:Text('FRUITECTIVES 2.0 • UI DEMO',style:TextStyle(color:muted,fontSize:10,letterSpacing:1)))])));
}
Widget _setting(BuildContext c,IconData i,String t)=>Padding(padding:const EdgeInsets.only(bottom:8),child:InkWell(onTap:()=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('$t is a demo setting.'))),child:panel(Row(children:[Icon(i,color:green,size:21),const SizedBox(width:12),Expanded(child:Text(t,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:13))),const Icon(Icons.chevron_right,color:muted)]))));
Widget _score(String t,String n)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(14)),child:Column(children:[Text(n,style:const TextStyle(fontSize:23,color:green,fontWeight:FontWeight.w900)),Text(t,style:const TextStyle(fontSize:11,color:muted))]));

// ───────────────────────── SCANS: per-user storage + stats (saved on the phone) ─────────────────────────
// Each logged-in user has their own list of scans (key: scans_<uid>). Guests' scans are not saved.
// Real scans come from the on-device YOLO model (see local_detector.dart); no internet needed.
class Scan {
  final String id, emoji, fruit, scientific;
  final int ripeness, freshness;
  final DateTime time;
  final String? label; // raw model class, e.g. "Rotten Banana" (null for old/demo scans)
  final double? confidence; // model confidence 0..1
  bool saved;
  Scan({required this.id, required this.emoji, required this.fruit, required this.scientific,
        required this.ripeness, required this.freshness, required this.time, this.label, this.confidence, this.saved = false});

  bool get isDemo => id.startsWith('demo');
  bool get isRotten => freshness < 45;
  bool get isFresh => freshness >= 80;
  String get ripenessLabel => ripeness < 65 ? 'Unripe' : ripeness < 80 ? 'Half ripe' : ripeness < 95 ? 'Ripe' : 'Overripe';
  String get freshnessLabel => freshness >= 85 ? 'Fresh' : freshness >= 70 ? 'Fairly fresh' : isRotten ? 'Rotten' : 'Not fresh';
  String get quality => freshness >= 85 ? 'Good' : freshness >= 70 ? 'Fair' : 'Poor';
  String get shelfLife => freshness >= 85 ? '4–6 days' : freshness >= 70 ? '2–3 days' : isRotten ? 'Discard' : '1 day';
  String get defects => freshness >= 80 ? 'None' : freshness >= 65 ? 'Low' : isRotten ? 'High' : 'Moderate';
  String get recommendation => freshness >= 85
      ? 'Great condition. Store in a cool place and enjoy within the next few days.'
      : freshness >= 70
          ? 'Still good to eat. Best consumed soon; refrigerate to slow ripening.'
          : isRotten
              ? 'Signs of spoilage detected. Do not eat it; discard it or compost it, and keep it away from other fruit.'
              : 'Eat today or use for cooking/smoothies. Check for soft or spoiled spots first.';
  String get whenText {
    final now = DateTime.now();
    final t = '${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
    final d = DateTime(now.year, now.month, now.day).difference(DateTime(time.year, time.month, time.day)).inDays;
    if (d == 0) return 'Today • $t';
    if (d == 1) return 'Yesterday • $t';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[time.month - 1]} ${time.day} • $t';
  }

  Map<String, dynamic> toJson() => {'id': id, 'emoji': emoji, 'fruit': fruit, 'scientific': scientific,
    'ripeness': ripeness, 'freshness': freshness, 'time': time.toIso8601String(), 'saved': saved,
    if (label != null) 'label': label, if (confidence != null) 'confidence': confidence};
  factory Scan.fromJson(Map<String, dynamic> j) => Scan(id: j['id'], emoji: j['emoji'], fruit: j['fruit'], scientific: j['scientific'],
    ripeness: j['ripeness'], freshness: j['freshness'], time: DateTime.parse(j['time']), saved: j['saved'] ?? false,
    label: j['label'] as String?, confidence: (j['confidence'] as num?)?.toDouble());
}

// Fruits the model knows by name. Ripeness-only classes (Matang, Mentah, …) don't name the fruit.
const _fruitInfo = {
  'apple': ('🍎', 'Apple', 'Malus domestica'), 'banana': ('🍌', 'Banana', 'Musa acuminata'),
  'mango': ('🥭', 'Mango', 'Mangifera indica'), 'orange': ('🍊', 'Orange', 'Citrus sinensis'),
  'pear': ('🍐', 'Pear', 'Pyrus communis'), 'peach': ('🍑', 'Peach', 'Prunus persica'),
};

/// Turns one detection from the workflow into a Scan.
/// Model classes: "Fresh <fruit>", "Rotten <fruit>", "Peach", and Indonesian ripeness labels
/// "Mentah" (unripe), "Setengah Matang" (half ripe), "Matang" (ripe), "busuk" (rotten).
Scan scanFromDetection(FruitDetection d, {DateTime? time}) {
  final l = d.label.toLowerCase().trim();
  final c = d.confidence.clamp(0.0, 1.0);
  final key = _fruitInfo.keys.where(l.contains).firstOrNull;
  final f = key == null ? ('🍏', 'Fruit', 'Fruit type not identified') : _fruitInfo[key]!;
  int ripeness, freshness;
  if (l.contains('rotten') || l.contains('busuk')) {
    ripeness = 98; freshness = (40 - 30 * c).round();
  } else if (l.contains('setengah')) {
    ripeness = 72; freshness = 90;
  } else if (l.contains('mentah')) {
    ripeness = 45; freshness = 92;
  } else if (l.contains('matang')) {
    ripeness = 88; freshness = 86;
  } else { // "Fresh <fruit>" or "Peach"
    ripeness = 82; freshness = (70 + 30 * c).round();
  }
  return Scan(id: DateTime.now().microsecondsSinceEpoch.toString(), emoji: f.$1, fruit: f.$2, scientific: f.$3,
    ripeness: ripeness, freshness: freshness, time: time ?? DateTime.now(), label: d.label, confidence: d.confidence);
}

const _sampleFruits = [
  ('🥭', 'Mango', 'Mangifera indica'), ('🍌', 'Banana', 'Musa acuminata'), ('🍎', 'Apple', 'Malus domestica'),
  ('🍊', 'Orange', 'Citrus sinensis'), ('🍐', 'Pear', 'Pyrus communis'), ('🍇', 'Grapes', 'Vitis vinifera'),
  ('🥑', 'Avocado', 'Persea americana'), ('🍉', 'Watermelon', 'Citrullus lanatus'),
];

class ScanStore {
  ScanStore._();
  static final I = ScanStore._();
  final scans = ValueNotifier<List<Scan>>([]);
  String? _uid;

  /// Makes sure the scans of the currently logged-in user are loaded (call freely).
  Future<void> syncUser() async {
    final uid = currentUser?.uid;
    if (uid == _uid) return;
    _uid = uid;
    if (uid == null) { scans.value = []; return; }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('scans_$uid');
      final list = raw == null ? <Scan>[] : (jsonDecode(raw) as List).map((e) => Scan.fromJson(Map<String, dynamic>.from(e))).toList();
      if (_uid == uid) scans.value = list;
    } catch (e) { debugPrint('Could not load scans: $e'); }
  }

  Future<void> _persist() async {
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scans_$_uid', jsonEncode(scans.value.map((s) => s.toJson()).toList()));
    } catch (e) { debugPrint('Could not save scans: $e'); }
  }

  Future<void> add(Scan s) async { if (_uid == null) return; scans.value = [s, ...scans.value]; await _persist(); }
  Future<void> toggleSaved(Scan s) async { s.saved = !s.saved; scans.value = [...scans.value]; await _persist(); }

  int get total => scans.value.length;
  int get fresh => scans.value.where((s) => s.isFresh).length;
  int get saved => scans.value.where((s) => s.saved).length;
}

void _showAnalyzing(BuildContext context) => showDialog(context: context, barrierDismissible: false, builder: (_) => const PopScope(
  canPop: false,
  child: Center(child: Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    child: Padding(padding: EdgeInsets.all(26), child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: green), SizedBox(height: 16),
      Text('Analyzing fruit...', style: TextStyle(fontWeight: FontWeight.w800)),
    ]))))));

void _showScanProblem(BuildContext context, String title, String message) => showDialog(context: context, builder: (d) => AlertDialog(
  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
  content: Text(message),
  actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('OK', style: TextStyle(color: green, fontWeight: FontWeight.w800)))],
));

final _picker = ImagePicker();
final _fruitAi = LocalFruitDetector.instance;

/// Takes a photo (or picks one from the gallery), runs the on-device AI model on it,
/// saves the result for logged-in users, then opens the result page.
Future<void> scanFruit(BuildContext context, ImageSource source) async {
  final where = source == ImageSource.camera ? 'camera' : 'gallery';
  XFile? file;
  try {
    // Downscale on the phone: faster to decode, and the model only sees 416x416 anyway.
    file = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear);
  } on PlatformException catch (e) {
    if (!context.mounted) return;
    final denied = e.code.contains('access_denied');
    _showScanProblem(context, denied ? 'Permission needed' : 'Could not open $where',
      denied ? 'Allow $where access for Fruitectives in your phone Settings, then try again.' : (e.message ?? e.code));
    return;
  }
  if (file == null || !context.mounted) return; // user cancelled
  final bytes = await file.readAsBytes();
  if (!context.mounted) return;

  _showAnalyzing(context);
  FreshnessResult? result;
  String? error;
  try {
    result = await _fruitAi.detectFreshness(bytes);
  } on LocalDetectorException catch (e) {
    error = e.message;
  } catch (e) {
    error = 'Something went wrong: $e';
  }
  if (!context.mounted) return;
  Navigator.pop(context); // close "Analyzing"

  if (error != null) { _showScanProblem(context, 'Analysis failed', error); return; }
  final best = result!.best;
  if (best == null) {
    _showScanProblem(context, 'No fruit detected',
      'Try again with one fruit centred in the frame, in good light, against a plain background.');
    return;
  }
  final scan = scanFromDetection(best);
  await ScanStore.I.add(scan);
  if (!context.mounted) return;
  go(context, ResultPage(scan: scan, photo: bytes, result: result));
}

/// Demo only: shows a simulated result for a sample fruit (not saved to history).
Future<void> runScan(BuildContext context, {String? fruit}) async {
  final r = Random();
  final f = fruit == null ? _sampleFruits[r.nextInt(_sampleFruits.length)] : _sampleFruits.firstWhere((x) => x.$2 == fruit);
  _showAnalyzing(context);
  await Future.delayed(const Duration(milliseconds: 900));
  final scan = Scan(id: 'demo-${DateTime.now().microsecondsSinceEpoch}', emoji: f.$1, fruit: f.$2, scientific: f.$3,
    ripeness: 55 + r.nextInt(44), freshness: 58 + r.nextInt(41), time: DateTime.now());
  if (!context.mounted) return;
  Navigator.pop(context); // close "Analyzing"
  go(context, ResultPage(scan: scan));
}

// Home: Total Scans / Fresh Fruits / Saved
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});
  @override Widget build(BuildContext context) => ValueListenableBuilder<List<Scan>>(
    valueListenable: ScanStore.I.scans,
    builder: (_, __, ___) => Row(children: [
      Expanded(child: _stat('Total Scans', '${ScanStore.I.total}', Icons.camera_alt_outlined)), const SizedBox(width: 9),
      Expanded(child: _stat('Fresh Fruits', '${ScanStore.I.fresh}', Icons.eco_outlined)), const SizedBox(width: 9),
      Expanded(child: _stat('Saved', '${ScanStore.I.saved}', Icons.bookmark_border)),
    ]),
  );
}

Widget _scanTile(BuildContext context, Scan s, {bool big = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: InkWell(onTap: () => go(context, ResultPage(scan: s)), borderRadius: BorderRadius.circular(18), child: panel(Row(children: [
    Text(s.emoji, style: TextStyle(fontSize: big ? 35 : 30)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(s.fruit, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (s.saved) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.bookmark, size: 14, color: green)),
      ]),
      Text(big ? s.whenText : '${s.freshnessLabel} • ${s.ripenessLabel}', style: const TextStyle(color: muted, fontSize: 10.5)),
    ])),
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEAF3E4), borderRadius: BorderRadius.circular(12)),
      child: Text('${s.freshness}%', style: const TextStyle(color: green, fontWeight: FontWeight.w900))),
  ]))),
);

Widget _noScansYet(BuildContext context) => panel(Column(children: [
  const Text('🍃', style: TextStyle(fontSize: 34)), const SizedBox(height: 6),
  const Text('No scans yet', style: TextStyle(fontWeight: FontWeight.w800)),
  const SizedBox(height: 2),
  const Text('Scan your first fruit to see results here.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
  const SizedBox(height: 10),
  TextButton.icon(onPressed: () => switchTab(context, 2), icon: const Icon(Icons.camera_alt_outlined, color: green, size: 18),
    label: const Text('Scan a fruit', style: TextStyle(color: green, fontWeight: FontWeight.w800))),
]));

// Home: 3 most recent scans
class RecentScans extends StatelessWidget {
  const RecentScans({super.key});
  @override Widget build(BuildContext context) => ValueListenableBuilder<List<Scan>>(
    valueListenable: ScanStore.I.scans,
    builder: (context, list, _) => list.isEmpty
      ? _noScansYet(context)
      : Column(children: list.take(3).map((s) => _scanTile(context, s)).toList()),
  );
}

// ───────────────────────── SCAN PAGE ─────────────────────────
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});
  @override Widget build(BuildContext context) => AppPage(tab: 2, child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('Scan a Fruit', sub: 'Take or choose a photo to analyze'),
    const SizedBox(height: 18),
    Container(width: double.infinity, height: 220,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFB8CDB1), width: 1.5)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 62, color: ink), SizedBox(height: 12),
        Text('Add a fruit photo', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: Text('Take a clear photo of one fruit. Our AI checks its type, ripeness and freshness.',
          textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11))),
      ])),
    const SizedBox(height: 14),
    PrimaryButton(text: 'Take Photo', icon: Icons.camera_alt, onTap: () => scanFruit(context, ImageSource.camera)),
    const SizedBox(height: 10),
    OutlineButtonX(text: 'Choose from Gallery', icon: Icons.photo_library_outlined, onTap: () => scanFruit(context, ImageSource.gallery)),
    if (currentUser == null) ...[
      const SizedBox(height: 12),
      const Row(children: [Icon(Icons.info_outline, size: 15, color: muted), SizedBox(width: 6),
        Expanded(child: Text('You are a guest. Results will not be saved to your history.', style: TextStyle(color: muted, fontSize: 11)))]),
    ],
    const SizedBox(height: 20),
    const Text('Try a demo', style: TextStyle(fontWeight: FontWeight.w900)),
    const Text('Simulated results, not saved to history', style: TextStyle(color: muted, fontSize: 11)),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: _sampleFruits.take(6).map((f) => ActionChip(
      onPressed: () => runScan(context, fruit: f.$2),
      backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFDDE8D7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Text('${f.$1}  ${f.$2}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    )).toList()),
    const SizedBox(height: 20),
    panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tips for best results', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10),
      ...['Good lighting', 'Keep fruit in focus', 'Show the whole fruit', 'Use a simple background'].map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [const Icon(Icons.check_circle, color: green, size: 17), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 12))]))),
    ])),
  ])));
}

// ───────────────────────── RESULT PAGES ─────────────────────────
final _demoScan = Scan(id: 'demo', emoji: '🥭', fruit: 'Mango', scientific: 'Mangifera indica', ripeness: 85, freshness: 87, time: DateTime(2026));

class ResultPage extends StatelessWidget {
  final Scan? scan;
  final Uint8List? photo; // the photo just analyzed (not stored in history)
  final FreshnessResult? result;
  const ResultPage({super.key, this.scan, this.photo, this.result});
  @override Widget build(BuildContext context) {
    final s = scan ?? _demoScan;
    final r = result;
    return AppPage(tab: 2, child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Result Overview', sub: s.isDemo ? 'Demo result (simulated)' : s.whenText),
      const SizedBox(height: 14),
      panel(Column(children: [
        if (photo != null && r != null && r.imageWidth > 0 && r.imageHeight > 0)
          ConstrainedBox(constraints: const BoxConstraints(maxHeight: 280), child: AspectRatio(
            aspectRatio: r.imageWidth / r.imageHeight,
            child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
              Image.memory(photo!, fit: BoxFit.fill),
              CustomPaint(painter: _DetectionPainter(r)),
            ]))))
        else
          Text(s.emoji, style: const TextStyle(fontSize: 80)),
        if (photo != null) const SizedBox(height: 10),
        Text(s.fruit, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        Text(s.scientific, style: const TextStyle(color: muted, fontSize: 12, fontStyle: FontStyle.italic)),
        if (s.label != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(
          'Detected: ${s.label}${s.confidence != null ? ' • ${(s.confidence! * 100).round()}% confidence' : ''}',
          style: const TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w600))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(s.isRotten ? Icons.warning_amber_rounded : Icons.check_circle, color: s.isRotten ? const Color(0xFFC2410C) : green), const SizedBox(width: 6),
          Text(s.isRotten ? 'Spoilage Detected' : 'Analysis Complete',
            style: TextStyle(color: s.isRotten ? const Color(0xFFC2410C) : green, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 15),
        Row(children: [Expanded(child: _score('Ripeness', '${s.ripeness}%')), const SizedBox(width: 10), Expanded(child: _score('Freshness', '${s.freshness}%'))]),
      ])),
      const SizedBox(height: 14),
      const Text('Quick Insights', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 10),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.7,
        children: [_nut('Quality', s.quality), _nut('Shelf life', s.shelfLife), _nut('Ripeness', s.ripenessLabel), _nut('Defects', s.defects)]),
      const SizedBox(height: 14),
      panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recommendation', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 7),
        Text(s.recommendation, style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
      ])),
      const SizedBox(height: 14),
      // Save / unsave (logged-in users only)
      ValueListenableBuilder<List<Scan>>(valueListenable: ScanStore.I.scans, builder: (context, _, __) => PrimaryButton(
        text: s.saved ? 'Saved ✓  (tap to remove)' : 'Save Result',
        icon: s.saved ? Icons.bookmark : Icons.bookmark_border,
        onTap: () {
          if (s.isDemo) { toast(context, 'Demo results can\'t be saved. Scan a real fruit to save it.'); return; }
          if (currentUser == null) { toast(context, 'Log in to save results to your account.'); return; }
          ScanStore.I.toggleSaved(s);
        },
      )),
      const SizedBox(height: 9),
      OutlineButtonX(text: 'View Ripeness Result', onTap: () => go(context, DetailResultPage(kind: 0, scan: s))),
      const SizedBox(height: 9),
      OutlineButtonX(text: 'View Freshness Result', onTap: () => go(context, DetailResultPage(kind: 1, scan: s))),
      const SizedBox(height: 9),
      OutlineButtonX(text: 'Nutrition Information', onTap: () => go(context, const NutritionPage())),
    ])));
  }
}

/// Draws the model's bounding boxes over the analyzed photo.
class _DetectionPainter extends CustomPainter {
  final FreshnessResult r;
  _DetectionPainter(this.r);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / r.imageWidth, sy = size.height / r.imageHeight;
    for (final d in r.detections) {
      final bad = d.label.toLowerCase().contains('rotten') || d.label.toLowerCase().contains('busuk');
      final color = bad ? const Color(0xFFEA580C) : const Color(0xFF22C55E);
      final rect = Rect.fromCenter(center: Offset(d.x * sx, d.y * sy), width: d.width * sx, height: d.height * sy);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = color);
      final tp = TextPainter(textDirection: TextDirection.ltr, text: TextSpan(
        text: ' ${d.label} ${(d.confidence * 100).round()}% ',
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, backgroundColor: color)))..layout();
      tp.paint(canvas, Offset(rect.left.clamp(0.0, max(0.0, size.width - tp.width)), max(0.0, rect.top - tp.height)));
    }
  }
  @override
  bool shouldRepaint(_DetectionPainter old) => old.r != r;
}

class DetailResultPage extends StatelessWidget {
  final int kind; final Scan? scan;
  const DetailResultPage({super.key, required this.kind, this.scan});
  @override Widget build(BuildContext context) {
    final s = scan ?? _demoScan;
    final score = kind == 0 ? s.ripeness : s.freshness;
    return AppPage(tab: 2, child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading(kind == 0 ? 'Ripeness Result' : 'Freshness Result'),
      const SizedBox(height: 14),
      panel(Column(children: [
        Text(s.emoji, style: const TextStyle(fontSize: 80)),
        Text(s.fruit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _score(kind == 0 ? 'Ripeness Score' : 'Freshness Score', '$score%'),
        const SizedBox(height: 10),
        Text(kind == 0 ? s.ripenessLabel : s.freshnessLabel, style: const TextStyle(color: green, fontWeight: FontWeight.w900, fontSize: 18)),
      ])),
      const SizedBox(height: 14),
      const Text('Assessment details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      ...['Color and appearance', 'Surface condition', 'Texture indicators', 'Overall assessment'].map((x) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: panel(Row(children: [
          const Icon(Icons.check_circle_outline, color: green), const SizedBox(width: 10),
          Expanded(child: Text(x, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(score >= 85 ? 'Good' : score >= 70 ? 'Fair' : 'Check', style: const TextStyle(color: green, fontSize: 11)),
        ])))),
      const SizedBox(height: 12),
      PrimaryButton(text: 'Back to Overview', onTap: () => Navigator.pop(context)),
    ])));
  }
}

// ───────────────────────── HISTORY ─────────────────────────
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext context) => currentUser == null
    ? const AppPage(tab: 3, child: LoginRequired(title: 'Your History is Locked', message: 'Log in or create a free account to save your fruit scans and view your analysis history.'))
    : AppPage(tab: 3, child: ValueListenableBuilder<List<Scan>>(
        valueListenable: ScanStore.I.scans,
        builder: (context, list, _) => SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          heading('My History', sub: list.isEmpty ? 'Your scans will appear here' : '${list.length} scan${list.length == 1 ? '' : 's'} • ${ScanStore.I.saved} saved'),
          const SizedBox(height: 14),
          if (list.isEmpty) _noScansYet(context) else ...list.map((s) => _scanTile(context, s, big: true)),
        ])),
      ));
}

// ───────────────────────── APP SHELL + BOTTOM NAV BAR ─────────────────────────
void switchTab(BuildContext context, int i) {
  const pages = [DashboardPage(), ToolsPage(), UploadPage(), HistoryPage(), ProfilePage()];
  Navigator.pushReplacement(context, PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => pages[i],
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

class AppPage extends StatefulWidget {
  final int tab; final Widget child;
  const AppPage({super.key, required this.tab, required this.child});
  @override State<AppPage> createState() => _AppPageState();
}
class _AppPageState extends State<AppPage> {
  @override void initState() { super.initState(); ScanStore.I.syncUser(); }

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(bottom: false, child: widget.child),
    bottomNavigationBar: FruitNavBar(current: widget.tab, onTap: (i) { if (i != widget.tab) switchTab(context, i); }),
  );
}

class FruitNavBar extends StatelessWidget {
  final int current; final ValueChanged<int> onTap;
  const FruitNavBar({super.key, required this.current, required this.onTap});

  Widget _item(int i, IconData icon, IconData activeIcon, String label, {bool locked = false}) {
    final active = current == i;
    return Expanded(child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 8, vertical: 5),
          decoration: BoxDecoration(color: active ? const Color(0xFFE3F1DC) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
          child: Stack(clipBehavior: Clip.none, children: [
            Icon(active ? activeIcon : icon, size: 23, color: active ? green : const Color(0xFF8A9188)),
            if (locked) const Positioned(right: -6, top: -4, child: CircleAvatar(radius: 7, backgroundColor: Colors.white,
              child: Icon(Icons.lock, size: 9, color: Color(0xFF8A9188)))),
          ]),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? green : const Color(0xFF8A9188))),
      ]),
    ));
  }

  @override Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final scanActive = current == 2;
    return SizedBox(
      height: 98 + bottom,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        // bar
        Positioned(left: 12, right: 12, bottom: 10 + bottom, height: 70, child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 24, offset: const Offset(0, 8))]),
          child: Row(children: [
            _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _item(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Tools'),
            const Expanded(child: Padding(padding: EdgeInsets.only(top: 38), child: Text('Scan', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8A9188))))),
            _item(3, Icons.history_rounded, Icons.history_rounded, 'History', locked: currentUser == null),
            _item(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ]),
        )),
        // raised scan button
        Positioned(bottom: 44 + bottom, child: GestureDetector(
          onTap: () => onTap(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: scanActive ? const [Color(0xFF0B8F45), Color(0xFF05592B)] : const [Color(0xFF1DA851), Color(0xFF08783F)]),
              border: Border.all(color: cream, width: 5),
              boxShadow: [BoxShadow(color: green.withOpacity(.40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 28),
          ),
        )),
      ]),
    );
  }
}
