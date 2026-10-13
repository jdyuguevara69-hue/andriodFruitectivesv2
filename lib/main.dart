import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(body:LeafBackdrop(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[
    const SizedBox(height:22),const Brand(size:54),const SizedBox(height:16),
    const Text('Smarter Detection. Deeper Insights.',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w800,fontSize:15)),
    const Text('Better Decisions.',style:TextStyle(color:muted,fontSize:13)),
    const SizedBox(height:18),
    Expanded(child:Container(width:double.infinity,decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:LinearGradient(colors:[Colors.white,Color(0xFFE9F3E4)])),child:const Center(child:Text('🥭  🍎  🍐\n\n🍊  🍇  🥑',textAlign:TextAlign.center,style:TextStyle(fontSize:48,height:1.6))))),
    const SizedBox(height:18),
    Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:const Column(children:[Text('Smart Fruit Decisions',style:TextStyle(fontWeight:FontWeight.w800)),SizedBox(height:8),Text('Identify fruits, explore freshness, ripeness and nutrition in one place.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:12))])),
    const SizedBox(height:16),PrimaryButton(text:"Let's get started",onTap:()=>go(context,const LoginPage())),
  ]))));
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
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage>{
  final _email=TextEditingController(); final _password=TextEditingController();
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
      toast(context,'Account created! Welcome, $name.');
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const DashboardPage()),(_)=>false);
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
class ForgotPage extends StatelessWidget {
  const ForgotPage({super.key});
  @override Widget build(BuildContext context)=>AuthShell(title:'Forgot Password?',subtitle:"No worries! Enter your email address and we'll send you a code to reset your password.",content:Column(children:[
    const Field(label:'Email Address',hint:'Enter your email address',icon:Icons.mail_outline),
    PrimaryButton(text:'Send Code',onTap:()=>go(context,const VerifyPage())),
    const SizedBox(height:10),OutlineButtonX(text:'Go Back',icon:Icons.arrow_back,onTap:()=>Navigator.pop(context)),
  ]));
}
class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});
  @override Widget build(BuildContext context)=>AuthShell(title:'Check Your Email',subtitle:'We sent a 6-digit verification code to your email address.',content:Column(children:[
    Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(14)),child:const Text('🔐  Your verification code is ready to enter.',textAlign:TextAlign.center,style:TextStyle(fontSize:12))),
    const SizedBox(height:20),
    Row(children:List.generate(6,(i)=>Expanded(child:Padding(
      padding:const EdgeInsets.symmetric(horizontal:3),
      child:TextField(
        textAlign:TextAlign.center,
        maxLength:1,
        keyboardType:TextInputType.number,
        decoration:InputDecoration(
          counterText:'',
          filled:true,
          fillColor:cream,
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none),
        ),
      ),
    )))),
    const SizedBox(height:16),OutlineButtonX(text:'Resend Code',icon:Icons.refresh,onTap:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Demo only — no email sent.')))),
    const SizedBox(height:12),PrimaryButton(text:'Verify Code',onTap:()=>go(context,const ResetPage())),
    TextButton(onPressed:()=>replace(context,const LoginPage()),child:const Text('Go Back to Login',style:TextStyle(color:green))),
  ]));
}
class ResetPage extends StatelessWidget {
  const ResetPage({super.key});
  @override Widget build(BuildContext context)=>AuthShell(title:'Create New Password',subtitle:'Enter your new password below.',content:Column(children:[
    const Field(label:'New Password',hint:'Enter new password',icon:Icons.lock_outline,obscure:true),
    const Field(label:'Confirm New Password',hint:'Confirm new password',icon:Icons.lock_outline,obscure:true),
    PrimaryButton(text:'Update Password',onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Password updated'),content:const Text('This is a frontend demo screen.'),actions:[TextButton(onPressed:()=>replace(context,const LoginPage()),child:const Text('Go to login'))]))),
  ]));
}

class AppPage extends StatefulWidget {
  final int tab; final Widget child;
  const AppPage({super.key,required this.tab,required this.child});
  @override State<AppPage> createState()=>_AppPageState();
}
class _AppPageState extends State<AppPage>{
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:widget.child),bottomNavigationBar:NavigationBar(height:66,selectedIndex:widget.tab,onDestinationSelected:(i){
    final pages=[const DashboardPage(),const ToolsPage(),const UploadPage(),const HistoryPage(),const ProfilePage()];
    replace(context,pages[i]);
  },destinations:const [
    NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
    NavigationDestination(icon:Icon(Icons.grid_view_rounded),selectedIcon:Icon(Icons.grid_view),label:'Tools'),
    NavigationDestination(icon:Icon(Icons.camera_alt_outlined),selectedIcon:Icon(Icons.camera_alt),label:'Scan'),
    NavigationDestination(icon:Icon(Icons.history),label:'History'),
    NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile'),
  ]));
}
Widget heading(String title,{String? sub})=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:ink)),if(sub!=null) ...[const SizedBox(height:4),Text(sub,style:const TextStyle(fontSize:12,color:muted))]]);
Widget panel(Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFEDEFE8))),child:child);
Widget fruitTile(String emoji,String name,String detail,{VoidCallback? onTap})=>InkWell(onTap:onTap,child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFEDEFE8))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Center(child:Text(emoji,style:const TextStyle(fontSize:35))),const SizedBox(height:5),Text(name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),Text(detail,style:const TextStyle(color:muted,fontSize:10))])));
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:0,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const CircleAvatar(backgroundColor:Color(0xFFE1EED9),child:Text('🌿')),const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Good morning, Bryan!',style:TextStyle(fontWeight:FontWeight.w800,fontSize:15)),Text('Here’s your fruit overview',style:TextStyle(color:muted,fontSize:11))])),IconButton(onPressed:()=>go(context,const ProfilePage()),icon:const Icon(Icons.notifications_none))]),
    const SizedBox(height:16),Container(width:double.infinity,padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFFE7F3DE),Color(0xFFF9F7E9)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SMART FRUIT ANALYSIS',style:TextStyle(color:green,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:7),const Text('Know your fruit better.',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Explore ripeness, freshness and nutrition.',style:TextStyle(fontSize:12,color:muted)),const SizedBox(height:12),Align(alignment:Alignment.centerLeft,child:ElevatedButton.icon(onPressed:()=>go(context,const UploadPage()),icon:const Icon(Icons.camera_alt,size:16),label:const Text('Analyze Fruit'),style:ElevatedButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white)))])),
    const SizedBox(height:18),Row(children:[Expanded(child:_stat('Total Scans','24',Icons.camera_alt_outlined)),const SizedBox(width:9),Expanded(child:_stat('Fresh Fruits','18',Icons.eco_outlined)),const SizedBox(width:9),Expanded(child:_stat('Saved','12',Icons.bookmark_border))]),
    const SizedBox(height:22),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Quick Access',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),TextButton(onPressed:()=>go(context,const ToolsPage()),child:const Text('View all'))]),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,mainAxisSpacing:12,crossAxisSpacing:8,childAspectRatio:.8,children:[
      _quick(context,'📸','Scan Fruit',const UploadPage()),_quick(context,'🍊','Fruits',const FruitsPage()),_quick(context,'💡','Tips',const TipsPage()),_quick(context,'🥗','Nutrition',const NutritionPage()),
    ]),
    const SizedBox(height:15),const Text('Recent Analysis',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:10),
    ...[['🥭','Mango','Fresh • Ripe','Today'],['🍌','Banana','Fresh • Ready to eat','Yesterday'],['🍎','Apple','Good quality','Oct 5']].map((x)=>Padding(padding:const EdgeInsets.only(bottom:9),child:panel(Row(children:[Text(x[0],style:const TextStyle(fontSize:30)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x[1],style:const TextStyle(fontWeight:FontWeight.w800)),Text(x[2],style:const TextStyle(color:muted,fontSize:11))])),Text(x[3],style:const TextStyle(color:muted,fontSize:10))])))),
    const SizedBox(height:20),panel(const Row(children:[Icon(Icons.shield_outlined,color:green,size:34),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Make informed choices',style:TextStyle(fontWeight:FontWeight.w800)),Text('Learn how to pick and store your fruits.',style:TextStyle(color:muted,fontSize:11))]))])),
  ])));
}
Widget _stat(String a,String b,IconData i)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:green,size:20),const SizedBox(height:8),Text(b,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:19)),Text(a,style:const TextStyle(color:muted,fontSize:10))]));
Widget _quick(BuildContext c,String emoji,String label,Widget page)=>InkWell(onTap:()=>go(c,page),child:Column(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(15)),child:Center(child:Text(emoji,style:const TextStyle(fontSize:23)))),const SizedBox(height:6),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700))]));
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:1,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    heading('AI TOOL',sub:'Explore the Fruitectives features'),const SizedBox(height:7),const Text('Powerful fruit insights, all in one place.',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:18),
    _tool(context,'📸','Fruit Recognition','Identify a fruit from a photo',const UploadPage()),_tool(context,'🟢','Ripeness Classification','Explore ripeness stages',const GuidePage(title:'Ripeness Classification',kind:0)),_tool(context,'💧','Freshness Assessment','Review freshness indicators',const GuidePage(title:'Freshness Assessment Overview',kind:1)),_tool(context,'🔎','Defect Detection','Common visible fruit defects',const GuidePage(title:'Defect Detection',kind:2)),_tool(context,'📅','Shelf-life Prediction','Storage guidance and shelf life',const GuidePage(title:'Shelf-life Prediction Overview',kind:3)),_tool(context,'🥗','Nutrition and Calories','Explore nutrition information',const NutritionPage()),const SizedBox(height:12),panel(const Text('Note: Tool pages are visual demonstrations. No AI inference is connected.',style:TextStyle(color:muted,fontSize:11))),
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
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:2,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Upload Fruit Photo',sub:'Choose a photo to start a demo analysis'),const SizedBox(height:18),Container(width:double.infinity,height:245,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFB8CDB1),width:1.5)),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.add_photo_alternate_outlined,size:65,color:ink),SizedBox(height:12),Text('Add a fruit photo',style:TextStyle(fontWeight:FontWeight.w800)),Text('Image selection is not connected in this UI demo',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11))])),const SizedBox(height:14),PrimaryButton(text:'Take Photo',icon:Icons.camera_alt,onTap:()=>_demo(context)),const SizedBox(height:10),OutlineButtonX(text:'Choose from Gallery',icon:Icons.photo_library_outlined,onTap:()=>_demo(context)),const SizedBox(height:20),panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tips for best results',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:10),...['Good lighting','Keep fruit in focus','Show the whole fruit','Use a simple background'].map((s)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[const Icon(Icons.check_circle,color:green,size:17),const SizedBox(width:8),Text(s,style:const TextStyle(fontSize:12))])))])),const SizedBox(height:16),const Text('Try a sample',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:8),const Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Text('🥭 Mango',style:TextStyle(fontSize:14)),Text('🍌 Banana',style:TextStyle(fontSize:14)),Text('🍎 Apple',style:TextStyle(fontSize:14))]) ])));
}
void _demo(BuildContext c)=>showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Frontend demo'),content:const Text('Camera and gallery access are intentionally not connected. You can explore the sample result screens from History.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]));
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:3,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('My History',sub:'Your recent sample analyses'),const SizedBox(height:14),...[
    ['🥭','Mango','Today • 10:42 AM','85%'],['🍌','Banana','Today • 9:15 AM','92%'],['🍎','Apple','Yesterday • 5:21 PM','90%'],['🍐','Pear','Oct 6 • 4:30 PM','88%'],['🍉','Watermelon','Oct 5 • 1:20 PM','91%'],['🍇','Grapes','Oct 4 • 11:08 AM','86%']
  ].map((x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(onTap:()=>go(context,const ResultPage()),child:panel(Row(children:[Text(x[0],style:const TextStyle(fontSize:35)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x[1],style:const TextStyle(fontWeight:FontWeight.w800)),Text(x[2],style:const TextStyle(color:muted,fontSize:10))])),Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(12)),child:Text(x[3],style:const TextStyle(color:green,fontWeight:FontWeight.w900)))])))))])));
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:4,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Profile'),const SizedBox(height:16),panel(Row(children:[const CircleAvatar(radius:30,backgroundColor:Color(0xFFE5F0DE),child:Icon(Icons.person,size:34,color:green)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(currentUser?.displayName ?? (currentUser==null?'Guest':'Fruitectives User'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text(currentUser==null?'Guest mode':'Signed in',style:const TextStyle(color:green,fontSize:11)),Text(currentUser?.email ?? 'Not signed in',style:const TextStyle(color:muted,fontSize:11))])),const Icon(Icons.edit_outlined,color:green)])),const SizedBox(height:20),const Text('ACCOUNT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.person_outline,'Personal Information'),_setting(context,Icons.lock_outline,'App Settings'),_setting(context,Icons.language,'Language'),_setting(context,Icons.notifications_none,'Notifications'),const SizedBox(height:12),const Text('SUPPORT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.help_outline,'Help Center'),_setting(context,Icons.feedback_outlined,'Feedback'),_setting(context,Icons.info_outline,'About Fruitectives 2.0'),const SizedBox(height:20),OutlineButtonX(text:'Log Out',icon:Icons.logout,onTap:() async {if(firebaseReady) await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}),const SizedBox(height:15),const Center(child:Text('FRUITECTIVES 2.0 • UI DEMO',style:TextStyle(color:muted,fontSize:10,letterSpacing:1)))])));
}
Widget _setting(BuildContext c,IconData i,String t)=>Padding(padding:const EdgeInsets.only(bottom:8),child:InkWell(onTap:()=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('$t is a demo setting.'))),child:panel(Row(children:[Icon(i,color:green,size:21),const SizedBox(width:12),Expanded(child:Text(t,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:13))),const Icon(Icons.chevron_right,color:muted)]))));
class ResultPage extends StatelessWidget {
  const ResultPage({super.key});
  @override Widget build(BuildContext context)=>AppPage(tab:2,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Result Overview',sub:'Sample result • UI demonstration'),const SizedBox(height:14),panel(Column(children:[const Text('🥭',style:TextStyle(fontSize:80)),const Text('Mango',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),const Text('Mangifera indica',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:10),const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.check_circle,color:green),SizedBox(width:6),Text('Analysis Complete',style:TextStyle(color:green,fontWeight:FontWeight.w800))]),const SizedBox(height:15),Row(children:[Expanded(child:_score('Ripeness','85%')),const SizedBox(width:10),Expanded(child:_score('Freshness','87%'))])])),const SizedBox(height:14),const Text('Quick Insights',style:TextStyle(fontWeight:FontWeight.w900,fontSize:16)),const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.7,children:[_nut('Quality','Good'),_nut('Shelf life','3–5 days'),_nut('Calories','60 kcal'),_nut('Defects','Low')]),const SizedBox(height:14),panel(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Recommendation',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:7),Text('Enjoy soon for best taste. Store appropriately and check the fruit before eating.',style:TextStyle(color:muted,fontSize:12,height:1.5))])),const SizedBox(height:14),PrimaryButton(text:'View Ripeness Result',onTap:()=>go(context,const DetailResultPage(kind:0))),const SizedBox(height:9),OutlineButtonX(text:'View Freshness Result',onTap:()=>go(context,const DetailResultPage(kind:1))),const SizedBox(height:9),OutlineButtonX(text:'Nutrition Information',onTap:()=>go(context,const NutritionPage()))])));
}
Widget _score(String t,String n)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xFFEAF3E4),borderRadius:BorderRadius.circular(14)),child:Column(children:[Text(n,style:const TextStyle(fontSize:23,color:green,fontWeight:FontWeight.w900)),Text(t,style:const TextStyle(fontSize:11,color:muted))]));
class DetailResultPage extends StatelessWidget {
  final int kind; const DetailResultPage({super.key,required this.kind});
  @override Widget build(BuildContext context)=>AppPage(tab:2,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(kind==0?'Ripeness Result':'Freshness Result'),const SizedBox(height:14),panel(Column(children:[const Text('🥭',style:TextStyle(fontSize:80)),const Text('Mango',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),_score(kind==0?'Ripeness Score':'Freshness Score',kind==0?'85%':'87%'),const SizedBox(height:10),Text(kind==0?'Ripe':'Fresh',style:const TextStyle(color:green,fontWeight:FontWeight.w900,fontSize:18))])),const SizedBox(height:14),const Text('Assessment details',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:10),...['Color and appearance','Surface condition','Texture indicators','Overall assessment'].map((x)=>Padding(padding:const EdgeInsets.only(bottom:9),child:panel(Row(children:[const Icon(Icons.check_circle_outline,color:green),const SizedBox(width:10),Expanded(child:Text(x,style:const TextStyle(fontWeight:FontWeight.w700))),const Text('Good',style:TextStyle(color:green,fontSize:11))])))),const SizedBox(height:12),PrimaryButton(text:'Back to Overview',onTap:()=>Navigator.pop(context))])));
}