import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario Pagos Online',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyForm(),
    );
  }
}

class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> normalParameters = [
    {'id': 'urlAction', 'label': 'urlAction', 'placeholder': 'https://test.ipg-online.com/connect/gateway/processing', 'value': 'https://test.ipg-online.com/connect/gateway/processing'},
    {'id': 'chargetotal', 'label': 'chargetotal', 'placeholder': '179.00', 'value': '179.00'},
    {'id': 'checkoutoption', 'label': 'checkoutoption', 'placeholder': 'combinedpage', 'value': 'combinedpage'},
    {'id': 'currency', 'label': 'currency', 'placeholder': '484', 'value': '484'},
    {'id': 'hash_algorithm', 'label': 'hash_algorithm', 'placeholder': 'HMACSHA256', 'value': 'HMACSHA256'},
    {'id': 'responseFailURL', 'label': 'responseFailURL', 'placeholder': 'https://pagosonline.mx/DConnect/response.php', 'value': 'https://pagosonline.mx/DConnect/response.php'},
    {'id': 'responseSuccessURL', 'label': 'responseSuccessURL', 'placeholder': 'https://pagosonline.mx/DConnect/response.php', 'value': 'https://pagosonline.mx/DConnect/response.php'},
    {'id': 'storename', 'label': 'storename', 'placeholder': '62666666', 'value': '62666666'},
    {'id': 'timezone', 'label': 'timezone', 'placeholder': 'America/Mexico_City', 'value': 'America/Mexico_City'},
    {'id': 'txndatetime', 'label': 'txndatetime', 'placeholder': 'En caso de estar vacío se calcula', 'value': ''},
    {'id': 'sharedSecret', 'label': 'sharedSecret', 'placeholder': 'i88E-;KYkS', 'value': 'i88E-;KYkS'},
    {'id': 'txntype', 'label': 'txntype', 'placeholder': 'sale', 'value': 'sale'},
  ];

  final List<Map<String, dynamic>> installmentsParams = [
    {'id': 'installmentsInterest', 'label': 'installmentsInterest', 'placeholder': 'false', 'value': 'false'},
    {'id': 'numberOfInstallments', 'label': 'numberOfInstallments', 'placeholder': '3,6,12,18', 'value': ''},
  ];

  final List<Map<String, dynamic>> token1Params = [
    {'id': 'assignToken', 'label': 'assignToken', 'placeholder': 'true', 'value': 'true'},
  ];

  final List<Map<String, dynamic>> token2Params = [
    {'id': 'hosteddataid', 'label': 'hosteddataid', 'placeholder': 'TOKEN_TO_USE', 'value': ''},
  ];

  final List<Map<String, dynamic>> scheduledParams = [
    {'id': 'ponumber', 'label': 'ponumber', 'placeholder': 'PO02220202', 'value': ''},
    {'id': 'recurringInstallmentCount', 'label': 'recurringInstallmentCount', 'placeholder': '12', 'value': ''},
    {'id': 'recurringInstallmentPeriod', 'label': 'recurringInstallmentPeriod', 'placeholder': 'month', 'value': ''},
    {'id': 'recurringInstallmentFrequency', 'label': 'recurringInstallmentFrequency', 'placeholder': '1', 'value': ''},
    {'id': 'recurringComments', 'label': 'recurringComments', 'placeholder': 'Comentarios adicionales (opcional)', 'value': ''},
  ];

  List<Map<String, dynamic>> selectedParameters = [];
  String txndatetimeValue = '';
  String calculatedString = '';
  String calculatedHash = '';

  @override
  void initState() {
    super.initState();
    selectedParameters = normalParameters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect Mobile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButton(
                  value: selectedParameters,
                  items: [
                    DropdownMenuItem(
                      value: normalParameters,
                      child: Text('Venta directa'),
                    ),
                    DropdownMenuItem(
                      value: installmentsParams,
                      child: Text('Meses sin intereses'),
                    ),
                    DropdownMenuItem(
                      value: token1Params,
                      child: Text('Token Parte 1'),
                    ),
                    DropdownMenuItem(
                      value: token2Params,
                      child: Text('Token Parte 2'),
                    ),
                    DropdownMenuItem(
                      value: scheduledParams,
                      child: Text('Calendarizado'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedParameters = value as List<Map<String, dynamic>>;
                    });
                  },
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: selectedParameters == normalParameters
                      ? normalParameters.length
                      : normalParameters.length + selectedParameters.length,
                  itemBuilder: (context, index) {
                    final parameter = selectedParameters == normalParameters
                        ? normalParameters[index]
                        : (normalParameters + selectedParameters)[index];
                    final String id = parameter['id'];
                    final String label = parameter['label'];
                    final String placeholder = parameter['placeholder'];
                    String? value = parameter['value'];
                    return TextFormField(
                      initialValue: value,
                      onSaved: (newValue) {
                        setState(() {
                          value = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: label,
                        hintText: placeholder,
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      selectedParameters.sort((a, b) => a['id'].compareTo(b['id']));

                      calculatedString = '';

                      for (final parameter in selectedParameters) {
                        final String id = parameter['id'];
                        final String? value = parameter['value'];

                        if (id == 'txndatetime' && value!.isEmpty) {
                          final sixHoursAgo = DateTime.now().subtract(Duration(hours: 6));
                          final formattedDate = DateFormat('yyyy:MM:dd-HH:mm:ss').format(sixHoursAgo);
                          calculatedString += '|$formattedDate'; // Modified this line
                          setState(() {
                            txndatetimeValue = formattedDate;
                          });
                        } else if (id != 'urlAction' && id != 'sharedSecret') {
                          calculatedString += '$value|';
                        }
                      }

                      calculatedString = calculatedString.substring(0, calculatedString.length - 1);

                      final secretKey = utf8.encode('i88E-;KYkS'); // Replace with your Shared Secret
                      final message = utf8.encode(calculatedString);

                      final hmacSha256 = Hmac(sha256, secretKey);
                      final digest = hmacSha256.convert(message);
                      calculatedHash = digest.toString();

                      final binaryHash = digest.bytes;
                      final base64Hash = base64.encode(binaryHash);

                      print('Calculated String: $calculatedString');
                      print('Calculated Hash: $binaryHash');
                      print('Base64Hash: $base64Hash');
                    }
                  },
                  child: Text('Generar'),
                ),
                SizedBox(height: 16),
                Text('txndatetime value: $txndatetimeValue'),
                SizedBox(height: 16),
                Text('Calculated String: $calculatedString'),
                SizedBox(height: 16),
                Text('Calculated Hash: $calculatedHash'),
                SizedBox(height: 16),
                Text('Base64Hash: $calculatedString'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
