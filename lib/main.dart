import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const bg=Color(0xff05080f), panel=Color(0xff101a29), cyan=Color(0xff00dfff), green=Color(0xff39ff65), red=Color(0xffff384b), purple=Color(0xffce37ff);
void main()=>runApp(const AlamApp());
class AlamApp extends StatelessWidget {const AlamApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Alam Calculator',theme:ThemeData.dark(useMaterial3:true).copyWith(scaffoldBackgroundColor:bg,colorScheme:const ColorScheme.dark(primary:cyan,surface:panel)),home:const Home());}
String money(num n)=>NumberFormat('#,##0.##').format(n);
class Home extends StatefulWidget {const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home> {
 String input='0',history='';
 final List<String> tokens=[];
 bool fresh=false,sound=true,vibrate=true,justEvaluated=false;
 List<String> logs=[];
 @override void initState(){super.initState();load();}
 Future<void> load() async {final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){sound=p.getBool('sound')??true;vibrate=p.getBool('vibrate')??true;logs=p.getStringList('calcHistory')??[];});}
 Future<void> persist() async {final p=await SharedPreferences.getInstance();await p.setBool('sound',sound);await p.setBool('vibrate',vibrate);await p.setStringList('calcHistory',logs);}
 bool isOperator(String s)=>['+','−','×','÷'].contains(s);
 String fmt(double v){
   if(!v.isFinite)return 'Error';
   if(v==v.roundToDouble()&&v.abs()<1e15)return v.toInt().toString();
   return v.toStringAsPrecision(11).replaceFirst(RegExp(r'0+$'),'').replaceFirst(RegExp(r'\.$'),'');
 }
 double? calculate(List<String> parts){
   if(parts.isEmpty)return null;
   final values=<double>[];
   final ops=<String>[];
   for(var i=0;i<parts.length;i++){
     if(i.isEven){final v=double.tryParse(parts[i]);if(v==null)return null;values.add(v);}
     else {if(!isOperator(parts[i]))return null;ops.add(parts[i]);}
   }
   for(var i=0;i<ops.length;){
     if(ops[i]=='×'||ops[i]=='÷'){
       final v=ops[i]=='×'?values[i]*values[i+1]:values[i]/values[i+1];
       if(!v.isFinite)return null;
       values[i]=v;values.removeAt(i+1);ops.removeAt(i);
     }else{i++;}
   }
   var result=values.first;
   for(var i=0;i<ops.length;i++){result=ops[i]=='+'?result+values[i+1]:result-values[i+1];}
   return result.isFinite?result:null;
 }
 String get expression => [...tokens,input].join(' ');
 String? get liveResult {
   if(tokens.isEmpty || fresh)return null;
   final result=calculate([...tokens,input]);
   return result==null?'Error':fmt(result);
 }
 void tap(String k){
   if(sound)SystemSound.play(SystemSoundType.click);
   if(vibrate)HapticFeedback.selectionClick();
   setState((){
     if(k=='AC'){input='0';tokens.clear();history='';fresh=false;justEvaluated=false;return;}
     if(k=='⌫'){
       if(justEvaluated){justEvaluated=false;history='';}
       if(fresh){if(tokens.isNotEmpty){tokens.removeLast();input=tokens.removeLast();}fresh=false;return;}
       input=input.length<=1?'0':input.substring(0,input.length-1);
       if(input=='-'||input.isEmpty)input='0';return;
     }
     if(k=='%'){
       input=fmt((double.tryParse(input)??0)/100);
       justEvaluated=false;return;
     }
     if(isOperator(k)){
       if(input=='Error')return;
       if(justEvaluated){tokens.clear();history='';justEvaluated=false;}
       if(fresh){if(tokens.isNotEmpty)tokens[tokens.length-1]=k;}
       else {tokens.add(input);tokens.add(k);}
       fresh=true;return;
     }
     if(k=='='){
       if(tokens.isEmpty)return;
       final parts=[...tokens, if(!fresh)input];
       if(parts.isEmpty||isOperator(parts.last))return;
       final result=calculate(parts);
       final line='${parts.join(' ')} = ${result==null?'Error':fmt(result)}';
       history=line;input=result==null?'Error':fmt(result);
       if(result!=null){logs.insert(0,line);if(logs.length>100)logs.removeLast();persist();}
       tokens.clear();fresh=false;justEvaluated=true;return;
     }
     if(input=='Error'||justEvaluated){input='0';tokens.clear();history='';fresh=false;justEvaluated=false;}
     if(fresh){input='0';fresh=false;}
     if(k=='.'){
       if(input.contains('.'))return;
       input='$input.';return;
     }
     if(k=='00'&&input=='0')return;
     if(input=='0')input=k;else if(input.length<20)input+=k;
   });
 }
 void open(Widget page){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>page));}
 @override Widget build(BuildContext context){final keys=['AC','%','÷','⌫','7','8','9','×','4','5','6','−','1','2','3','+','00','0','.','='];return Scaffold(appBar:AppBar(backgroundColor:bg,title:const Text('Alam Calculator',style:TextStyle(color:cyan,fontWeight:FontWeight.bold)),actions:[Padding(padding:const EdgeInsets.all(5),child:CircleAvatar(radius:23,backgroundColor:green,child:CircleAvatar(radius:21,backgroundImage:const AssetImage('assets/profile.jpg')))),Builder(builder:(c)=>IconButton(icon:const Icon(Icons.menu,color:green,size:30),onPressed:()=>Scaffold.of(c).openEndDrawer()))]),endDrawer:Drawer(backgroundColor:panel,child:SafeArea(child:ListView(children:[const DrawerHeader(child:Center(child:Text('ALAM TOOLS',style:TextStyle(color:cyan,fontSize:26,fontWeight:FontWeight.bold)))),ListTile(leading:const Icon(Icons.calculate,color:cyan),title:const Text('Calculator'),onTap:()=>Navigator.pop(context)),ListTile(leading:const Icon(Icons.menu_book,color:green),title:const Text('Smart Notebook'),onTap:()=>open(const Notebook())),ListTile(leading:const Icon(Icons.cake,color:purple),title:const Text('Age Calculator'),onTap:()=>open(const AgePage())),ListTile(leading:const Icon(Icons.account_balance_wallet,color:cyan),title:const Text('BD Money Counter'),onTap:()=>open(const MoneyPage())),ListTile(leading:const Icon(Icons.history,color:cyan),title:const Text('Calculator History'),onTap:()=>open(HistoryPage(logs:logs))),SwitchListTile(title:const Text('Click Sound'),value:sound,onChanged:(v){setState(()=>sound=v);persist();}),SwitchListTile(title:const Text('Vibration'),value:vibrate,onChanged:(v){setState(()=>vibrate=v);persist();})]))),body:SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Expanded(flex:3,child:Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(24),border:Border.all(color:cyan,width:1.5),boxShadow:[BoxShadow(color:cyan.withValues(alpha:.18),blurRadius:20)]),child:Column(mainAxisAlignment:MainAxisAlignment.end,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(tokens.isNotEmpty ? expression : history,style:const TextStyle(color:Colors.white54,fontSize:18),maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:12),FittedBox(fit:BoxFit.scaleDown,child:Text(liveResult ?? input,style:const TextStyle(fontSize:58,color:green,fontWeight:FontWeight.bold)))]))),const SizedBox(height:14),Expanded(flex:7,child:LayoutBuilder(builder:(context,c)=>GridView.builder(physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,mainAxisSpacing:9,crossAxisSpacing:9,childAspectRatio:(c.maxWidth/4)/(c.maxHeight/5)),itemCount:keys.length,itemBuilder:(context,i){final k=keys[i];final color=switch(k){'AC'=>red,'÷'=>cyan,'×'=>const Color(0xffffa500),'−'=>purple,'+'=>green,'='=>cyan,'%'=>green,_=>Colors.white};return NeonKey(label:k,color:color,onTap:()=>tap(k));}))) ]))));}
}
class NeonKey extends StatefulWidget {final String label;final Color color;final VoidCallback onTap;const NeonKey({super.key,required this.label,required this.color,required this.onTap});@override State<NeonKey> createState()=>_NeonKeyState();}
class _NeonKeyState extends State<NeonKey> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.91 : 1.0,
        duration: const Duration(milliseconds: 95),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 95),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? widget.color.withValues(alpha: 0.28) : panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.color.withValues(
                alpha: widget.color == Colors.white ? 0.25 : 1.0,
              ),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: pressed ? 0.65 : 0.17),
                blurRadius: pressed ? 22 : 9,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: widget.label == 'AC' ? 23 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
class HistoryPage extends StatelessWidget {final List<String> logs;const HistoryPage({super.key,required this.logs});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Calculator History')),body:logs.isEmpty?const Center(child:Text('No calculations yet')):ListView.builder(itemCount:logs.length,itemBuilder:(_,i)=>ListTile(title:Text(logs[i]),leading:const Icon(Icons.history,color:cyan))));}
class Notebook extends StatefulWidget {const Notebook({super.key});@override State<Notebook> createState()=>_NotebookState();}
class _NotebookState extends State<Notebook>{Map<String,dynamic> books={};String? selected;@override void initState(){super.initState();load();}Future<void> load()async{final p=await SharedPreferences.getInstance();try{books=Map<String,dynamic>.from(jsonDecode(p.getString('books')??'{}'));}catch(_){books={};}if(books.isNotEmpty)selected=books.keys.first;if(mounted)setState((){});}Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setString('books',jsonEncode(books));}
 Future<String?> ask(String title,{String initial=''})async{final c=TextEditingController(text:initial);final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(hintText:'Name / Description')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),TextButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Save'))]));c.dispose();return value;}
 Future<void> addBook()async{final name=await ask('New Notebook');if(name==null||name.isEmpty)return;setState((){books[name]=books[name]??[];selected=name;});save();}
 Future<void> entry({int? index})async{if(selected==null)return;final entries=List<Map<String,dynamic>>.from((books[selected] as List).map((e)=>Map<String,dynamic>.from(e)));final old=index==null?<String,dynamic>{}:entries[index];final name=TextEditingController(text:old['name']?.toString()??'');final qty=TextEditingController(text:old['qty']?.toString()??'1');final price=TextEditingController(text:old['price']?.toString()??'');final result=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(index==null?'Add Entry':'Edit Entry'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Item / Description')),TextField(controller:qty,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Quantity')),TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Unit price'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))]));if(result==true&&name.text.trim().isNotEmpty){final item={'name':name.text.trim(),'qty':double.tryParse(qty.text)??0,'price':double.tryParse(price.text)??0};setState((){if(index==null){entries.add(item);}else{entries[index]=item;}books[selected!]=entries;});save();}name.dispose();qty.dispose();price.dispose();}
 @override Widget build(BuildContext context){final items=selected==null?<Map<String,dynamic>>[]:List<Map<String,dynamic>>.from((books[selected] as List).map((e)=>Map<String,dynamic>.from(e)));final total=items.fold<double>(0,(s,e)=>s+((e['qty'] as num).toDouble()*(e['price'] as num).toDouble()));return Scaffold(appBar:AppBar(title:const Text('Smart Notebook'),actions:[IconButton(onPressed:addBook,icon:const Icon(Icons.create_new_folder,color:cyan))]),floatingActionButton:selected==null?null:FloatingActionButton(onPressed:()=>entry(),child:const Icon(Icons.add)),body:Column(children:[if(books.isNotEmpty)Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:DropdownButton<String>(isExpanded:true,value:selected,items:books.keys.map((k)=>DropdownMenuItem(value:k,child:Text(k))).toList(),onChanged:(v)=>setState(()=>selected=v))),IconButton(tooltip:'Delete notebook',onPressed:()=>showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Delete notebook?'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),TextButton(onPressed:(){setState((){books.remove(selected);selected=books.isEmpty?null:books.keys.first;});save();Navigator.pop(ctx);},child:const Text('Delete'))])),icon:const Icon(Icons.delete_outline,color:red))])),if(selected==null)Expanded(child:Center(child:FilledButton(onPressed:addBook,child:const Text('Create your first notebook'))))else ...[Container(width:double.infinity,margin:const EdgeInsets.all(12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18),border:Border.all(color:green)),child:Text('TOTAL  ৳${money(total)}',style:const TextStyle(fontSize:27,color:green,fontWeight:FontWeight.bold))),Expanded(child:ListView.builder(itemCount:items.length,itemBuilder:(ctx,i){final e=items[i];final sum=(e['qty'] as num)*(e['price'] as num);return Card(color:panel,child:ListTile(leading:CircleAvatar(child:Text('${i+1}')),title:Text(e['name'].toString()),subtitle:Text('${money(e['qty'] as num)} × ${money(e['price'] as num)}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text('৳${money(sum)}',style:const TextStyle(color:green)),IconButton(onPressed:()=>entry(index:i),icon:const Icon(Icons.edit,color:cyan)),IconButton(onPressed:(){setState((){items.removeAt(i);books[selected!]=items;});save();},icon:const Icon(Icons.delete,color:red))])));})),]]));}}
class AgePage extends StatefulWidget {const AgePage({super.key});@override State<AgePage> createState()=>_AgePageState();}
class _AgePageState extends State<AgePage>{DateTime? birth;@override Widget build(BuildContext context){final now=DateUtils.dateOnly(DateTime.now());int years=0,months=0,days=0,until=0,total=0;if(birth!=null){final b=DateUtils.dateOnly(birth!);years=now.year-b.year;months=now.month-b.month;days=now.day-b.day;if(days<0){months--;days+=DateTime(now.year,now.month,0).day;}if(months<0){years--;months+=12;}total=now.difference(b).inDays;DateTime next(int year){final day=b.month==2&&b.day==29&&DateTime(year,3,0).day<29?28:b.day;return DateTime(year,b.month,day);}var n=next(now.year);if(n.isBefore(now))n=next(now.year+1);until=n.difference(now).inDays;}return Scaffold(appBar:AppBar(title:const Text('Age Calculator')),body:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const Icon(Icons.cake,size:75,color:purple),const SizedBox(height:20),FilledButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:birth??DateTime(2000),firstDate:DateTime(1900),lastDate:now);if(d!=null)setState(()=>birth=d);},child:Text(birth==null?'Select Date of Birth':DateFormat('dd MMM yyyy').format(birth!))),if(birth!=null)...[const SizedBox(height:24),resultCard('Your Age','$years years, $months months, $days days'),resultCard('Total Days','$total days'),resultCard('Next Birthday','$until days remaining')]])));}Widget resultCard(String label,String value)=>Card(color:panel,child:ListTile(title:Text(label),subtitle:Text(value,style:const TextStyle(color:cyan,fontSize:22,fontWeight:FontWeight.bold))));}
class MoneyPage extends StatefulWidget {const MoneyPage({super.key});@override State<MoneyPage> createState()=>_MoneyPageState();}
class _MoneyPageState extends State<MoneyPage>{final denom=[1000,500,200,100,50,20,10,5,2,1];final counts=<int,int>{};List<Map<String,dynamic>> records=[];@override void initState(){super.initState();load();}Future<void> load()async{final p=await SharedPreferences.getInstance();try{records=List<Map<String,dynamic>>.from((jsonDecode(p.getString('cashRecords')??'[]') as List).map((e)=>Map<String,dynamic>.from(e)));}catch(_){records=[];}if(mounted)setState((){});}Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setString('cashRecords',jsonEncode(records));}int get total=>denom.fold(0,(s,d)=>s+d*(counts[d]??0));@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('BD Money Counter'),actions:[IconButton(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:ListView(shrinkWrap:true,children:[const ListTile(title:Text('Saved Cash Records')),for(final r in records)ListTile(title:Text('৳${money(r['total'] as num)}'),subtitle:Text(r['date'].toString()),trailing:IconButton(icon:const Icon(Icons.delete,color:red),onPressed:(){setState(()=>records.remove(r));save();Navigator.pop(ctx);} ))]))),icon:const Icon(Icons.history,color:cyan))]),body:Column(children:[Expanded(child:ListView.builder(itemCount:denom.length,itemBuilder:(ctx,i){final d=denom[i];return Container(margin:const EdgeInsets.symmetric(horizontal:12,vertical:4),padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(13),border:Border.all(color:cyan.withValues(alpha:.3))),child:Row(children:[SizedBox(width:70,child:Text('৳$d',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),IconButton(onPressed:()=>setState(()=>counts[d]=((counts[d]??0)-1).clamp(0,999999)),icon:const Icon(Icons.remove_circle_outline,color:red)),Expanded(child:TextFormField(key:ValueKey('$d-${counts[d]??0}'),initialValue:'${counts[d]??0}',textAlign:TextAlign.center,keyboardType:TextInputType.number,decoration:const InputDecoration(isDense:true,border:OutlineInputBorder()),onChanged:(s)=>setState(()=>counts[d]=(int.tryParse(s)??0).clamp(0,999999)))),IconButton(onPressed:()=>setState(()=>counts[d]=(counts[d]??0)+1),icon:const Icon(Icons.add_circle_outline,color:green)),SizedBox(width:86,child:Text('৳${money(d*(counts[d]??0))}',textAlign:TextAlign.end,style:const TextStyle(color:cyan,fontWeight:FontWeight.bold)))]));})),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,border:Border.all(color:cyan)),child:Column(children:[Text('TOTAL  ৳${money(total)}',style:const TextStyle(color:green,fontSize:30,fontWeight:FontWeight.bold)),const SizedBox(height:8),Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[TextButton(onPressed:()=>setState(()=>counts.clear()),child:const Text('Clear')),TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:'BD Money Counter\n${denom.where((d)=>(counts[d]??0)>0).map((d)=>'৳$d × ${counts[d]} = ৳${d*counts[d]!}').join('\n')}\nTotal: ৳$total'));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copied')));},child:const Text('Copy')),FilledButton(onPressed:(){setState(()=>records.insert(0,{'date':DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),'total':total,'counts':counts.map((k,v)=>MapEntry('$k',v))}));save();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved')));},child:const Text('Save Record'))])]))]));}
