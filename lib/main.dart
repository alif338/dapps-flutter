// import 'package:eth_pk_coin/fluttertoast.dart';
import 'package:eth_pk_coin/logging_client.dart';
import 'package:eth_pk_coin/slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'PKCOIN App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String walletAddress = dotenv.env['WALLET_ADDRESS']!;
  bool hasData = false;
  int myAmount = 0;
  late LoggingClient client;
  late Web3Client ethClient;
  String myData = "";

  @override
  void initState() {
    super.initState();
    client = LoggingClient(Client());
    ethClient = Web3Client(
        'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
        client);
    getBalance(walletAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = dotenv.env['CONTRACT_ADDRESS']!;
    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    print("query called");
    EthPrivateKey credentials =
        EthPrivateKey.fromHex(dotenv.env['PRIVATE_KEY']!);
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        sender: credentials.address,
        contract: contract,
        function: ethFunction,
        params: args);
    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    print("Would get balance for $targetAddress");
    List result = await query("getBalance", []);
    setState(() {
      myData = result[0].toString();
      hasData = true;
    });
  }

  Future sendCoin() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    // showToast(msg: 'Deposited $myAmount PKCOIN');
    return response;
  }

  Future withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("withdrawlBalance", [bigAmount]);

    print("Withdrawed");
    // showToast(msg: 'Withdrawed $myAmount PKCOIN');
    return response;
  }

  Future submit(String functionName, List args) async {
// Need private key
    EthPrivateKey credentials =
        EthPrivateKey.fromHex(dotenv.env['PRIVATE_KEY']!);
    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
      fetchChainIdFromNetworkId: true,
      chainId: 4
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue500
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          "\$PKCOIN".text.white.xl4.bold.center.makeCentered(),
          (context.percentHeight * 5).heightBox,
          VxBox(
                  child: VStack([
            "Balance".text.gray700.xl2.semiBold.makeCentered(),
            10.heightBox,
            hasData
                ? "\$$myData".text.bold.xl6.makeCentered()
                // : CircularProgressIndicator().centered()
                : "No Data".text.makeCentered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          SliderWidget(
            min: 0,
            max: 100,
            onChanged: (val) {
              setState(() {
                myAmount = (val * 100).toInt();
                print(myAmount);
              });
            },
          ).centered(),
          HStack(
            [
              TextButton.icon(
                onPressed: () => getBalance(walletAddress),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ),
                icon: Icon(Icons.refresh, color: Colors.white),
                label: "Refresh".text.white.make(),
              ).h(50),
              TextButton.icon(
                onPressed: () => sendCoin(),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ),
                icon: Icon(Icons.call_made_outlined, color: Colors.white),
                label: "Deposit".text.white.make(),
              ).h(50),
              TextButton.icon(
                onPressed: () => withdrawCoin(),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ),
                icon: Icon(Icons.call_received_outlined, color: Colors.white),
                label: "Withdraw".text.white.make(),
              ).h(50),
            ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16()
        ])
      ]),
    );
  }
}
