import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Investment Payback Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _investmentController = TextEditingController();
  final _fixedCostController = TextEditingController();
  final _variableCostController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitsSoldController = TextEditingController();

  String _paybackTime = '';
  List<FlSpot> _chartData = [];

  @override
  void dispose() {
    _investmentController.dispose();
    _fixedCostController.dispose();
    _variableCostController.dispose();
    _priceController.dispose();
    _unitsSoldController.dispose();
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<String> writeData(String fileName, String data) async {
    try {
      final file = await _localFile(fileName);
      await file.writeAsString(data);
      return 'Data written successfully';
    } catch (e) {
      return 'Error writing file: $e';
    }
  }

  Future<String> readData(String fileName) async {
    try {
      final file = await _localFile(fileName);
      if (!await file.exists()) {
        return 'File not found';
      }
      return await file.readAsString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  void _calculatePaybackTime() {
    try {
      double investment = double.tryParse(_investmentController.text) ?? 0.0;
      double fixedCost = double.tryParse(_fixedCostController.text) ?? 0.0;
      double variableCost = double.tryParse(_variableCostController.text) ?? 0.0;
      double price = double.tryParse(_priceController.text) ?? 0.0;
      double unitsSoldPerMonth = double.tryParse(_unitsSoldController.text) ?? 0.0;

      if (investment <= 0 || unitsSoldPerMonth <= 0) throw Exception('Values must be greater than zero.');
      if (fixedCost < 0 || variableCost < 0 || price <= 0) {
        throw Exception('Negative or zero values are not allowed for costs and price.');
      }

      double monthlyRevenue = (price - variableCost) * unitsSoldPerMonth;
      double monthlyProfit = monthlyRevenue - fixedCost;

      if (monthlyProfit <= 0) throw Exception('No profit or negative profit.');

      int monthsToPayback = (investment / monthlyProfit).ceil();
      _chartData = calculateChartData(investment, fixedCost, variableCost, price, unitsSoldPerMonth);

      setState(() {
        _paybackTime = '$monthsToPayback months';
      });
    } catch (e) {
      setState(() {
        _paybackTime = 'Error: ${e.toString()}';
      });
    }
  }

  List<FlSpot> calculateChartData(double investment, double fixedCost, double variableCost, double price, double unitsSoldPerMonth) {
    List<FlSpot> spots = [];
    double monthlyRevenue = (price - variableCost) * unitsSoldPerMonth;
    double monthlyProfit = monthlyRevenue - fixedCost;
    double cumulativeProfit = 0;
    int timeUnit = 0;

    while (cumulativeProfit < investment) {
      cumulativeProfit += monthlyProfit;
      spots.add(FlSpot(timeUnit.toDouble(), cumulativeProfit));
      timeUnit++;
    }

    return spots;
  }

  Widget buildChart(List<FlSpot> chartData) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            barWidth: 5,
            colors: [Colors.blue],
            belowBarData: BarAreaData(show: false),
            aboveBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _investmentController.clear();
    _fixedCostController.clear();
    _variableCostController.clear();
    _priceController.clear();
    _unitsSoldController.clear();
    setState(() {
      _paybackTime = '';
      _chartData = [];
    });
  }

  void _showInfoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.asset('assets/info_image.jpg'), // Replace with your image asset
                Text('Your informative text here.'), // Replace with your desired text
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFileNameDialog(bool isSave) {
    TextEditingController _fileNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSave ? 'Enter File Name to Save' : 'Enter File Name to Load'),
          content: TextField(
            controller: _fileNameController,
            decoration: InputDecoration(
              hintText: 'File Name (e.g., data.txt)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(isSave ? 'Save' : 'Load'),
              onPressed: () async {
                Navigator.of(context).pop();
                String fileName = _fileNameController.text;
                if (fileName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a file name')));
                  return;
                }
                if (isSave) {
                  String data = '${_investmentController.text},'
                      '${_fixedCostController.text},'
                      '${_variableCostController.text},'
                      '${_priceController.text},'
                      '${_unitsSoldController.text}';
                  String response = await writeData(fileName, data);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response)));
                } else {
                  String fileContent = await readData(fileName);
                  if (fileContent.startsWith('Error')) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fileContent)));
                  } else {
                    List<String> parts = fileContent.split(',');
                    _investmentController.text = parts[0];
                    _fixedCostController.text = parts[1];
                    _variableCostController.text = parts[2];
                    _priceController.text = parts[3];
                    _unitsSoldController.text = parts[4];
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investment Payback Calculator'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _investmentController,
              decoration: InputDecoration(labelText: 'Investment Value'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _fixedCostController,
              decoration: InputDecoration(labelText: 'Fixed Cost'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _variableCostController,
              decoration: InputDecoration(labelText: 'Variable Cost'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price per Unit'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _unitsSoldController,
              decoration: InputDecoration(labelText: 'Units Sold per Month'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculatePaybackTime,
              child: Text('Calculate Payback Time'),
            ),
            SizedBox(height: 20),
            Text('Payback Time: $_paybackTime'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showFileNameDialog(true),
              child: Text('Save to File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showFileNameDialog(false),
              child: Text('Load from File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearFields,
              child: Text('Clear Fields'),
            ),
            SizedBox(height: 20),
            _chartData.isNotEmpty
                ? Container(
              height: 300,
              child: buildChart(_chartData),
            )
                : Text('No chart data available.'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInfoPopup,
        tooltip: 'Info',
        child: Icon(Icons.info_outline),
      ),
    );
  }
}
