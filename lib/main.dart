import 'package:flutter/material.dart';

void main() => runApp(const FruitectivesApp());

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
    home: const WelcomePage(),
  );
}

void go(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
void replace(BuildContext context, Widget page) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key,this.size=58});
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width:size,height:size,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:[BoxShadow(color:green.withOpacity(.08),blurRadius:15)]),child:Center(child:Text('🍎',style:TextStyle(fontSize:size*.52)))),
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
  const Field({super.key,required this.label,required this.hint,required this.icon,this.obscure=false});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),const SizedBox(height:7),
    TextField(obscureText:obscure,decoration:InputDecoration(prefixIcon:Icon(icon,size:19,color:leaf),hintText:hint,filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(vertical:14,horizontal:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:BorderSide.none))),
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
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override Widget build(BuildContext context)=>AuthShell(title:'Welcome back!',subtitle:'Sign in to continue your smart fruit journey.',content:Column(children:[
    const Field(label:'Email Address',hint:'Enter your email address',icon:Icons.mail_outline),
    const Field(label:'Password',hint:'Enter your password',icon:Icons.lock_outline,obscure:true),
    Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>go(context,const ForgotPage()),child:const Text('Forgot Password?',style:TextStyle(color:green,fontSize:12)))),
    PrimaryButton(text:'Log In',onTap:()=>replace(context,const DashboardPage())),
    const SizedBox(height:12),OutlineButtonX(text:'Continue as Guest',icon:Icons.person_outline,onTap:()=>replace(context,const DashboardPage())),
    const SizedBox(height:10),TextButton(onPressed:()=>go(context,const RegisterPage()),child:const Text("Don't have an account? Create Account",style:TextStyle(color:green,fontSize:12))),
  ]));
}
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override Widget build(BuildContext context)=>AuthShell(title:'Create Your Account',subtitle:'Start exploring smarter fruit decisions.',content:Column(children:[
    const Field(label:'Full Name',hint:'Enter your name',icon:Icons.person_outline),
    const Field(label:'Email Address',hint:'Enter your email',icon:Icons.mail_outline),
    const Field(label:'Password',hint:'Create a password',icon:Icons.lock_outline,obscure:true),
    const Field(label:'Confirm Password',hint:'Re-enter your password',icon:Icons.lock_outline,obscure:true),
    PrimaryButton(text:'Create Account',onTap:()=>go(context,const VerifyPage())),
    TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Already have an account? Log in',style:TextStyle(color:green))),
  ]));
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
  @override Widget build(BuildContext context)=>AppPage(tab:4,child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Profile'),const SizedBox(height:16),panel(Row(children:[const CircleAvatar(radius:30,backgroundColor:Color(0xFFE5F0DE),child:Icon(Icons.person,size:34,color:green)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Bryan Carbonilla',style:TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text('Premium User • Demo',style:TextStyle(color:green,fontSize:11)),Text('bryan@example.com',style:TextStyle(color:muted,fontSize:11))])),const Icon(Icons.edit_outlined,color:green)])),const SizedBox(height:20),const Text('ACCOUNT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.person_outline,'Personal Information'),_setting(context,Icons.lock_outline,'App Settings'),_setting(context,Icons.language,'Language'),_setting(context,Icons.notifications_none,'Notifications'),const SizedBox(height:12),const Text('SUPPORT',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(height:8),_setting(context,Icons.help_outline,'Help Center'),_setting(context,Icons.feedback_outlined,'Feedback'),_setting(context,Icons.info_outline,'About Fruitectives 2.0'),const SizedBox(height:20),OutlineButtonX(text:'Log Out',icon:Icons.logout,onTap:()=>replace(context,const LoginPage())),const SizedBox(height:15),const Center(child:Text('FRUITECTIVES 2.0 • UI DEMO',style:TextStyle(color:muted,fontSize:10,letterSpacing:1)))])));
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