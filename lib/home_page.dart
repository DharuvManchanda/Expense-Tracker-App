import 'dart:convert';
import 'dart:math';

import 'package:expense_tracker_app/expense_model.dart';
import 'package:expense_tracker_app/fund_current_widget.dart';
import 'package:expense_tracker_app/item.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class ExpenseStorage {
  static const String _expensesKey = 'expenses';

  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = expenses.map((expense) => jsonEncode(expense.toJson())).toList();
    await prefs.setStringList(_expensesKey, jsonList);
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_expensesKey);
    if (jsonList == null) {
      return [];
    }
    return jsonList.map((jsonString) => ExpenseModel.fromJson(jsonDecode(jsonString))).toList();
  }
}
final List<String> options = ['Expense', 'Income'];
var currDate = DateFormat.yMMMd().format(DateTime.now());
List<ExpenseModel> items = [];

class _HomePageState extends State<HomePage> {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  int incomeMoney = 0;
  int spentMoney = 0;
  int balanceMoney = 0;
  double ratioMoney = 0;
  String selectedValue = options.first;
  List<ExpenseModel> items = [];

  @override
  void initState() {
    super.initState();
    _loadSavedExpenses();
  }

  Future<void> _loadSavedExpenses() async {
    final expenseStorage = ExpenseStorage();
    items = await expenseStorage.getExpenses();
    for (var expense in items) {
      if (expense.isIncome) {
        incomeMoney += expense.amount;
      } else {
        spentMoney += expense.amount;
      }
    }
    balanceMoney = incomeMoney - spentMoney;
    ratioMoney = calculateRatio(spentMoney, incomeMoney);
    setState(() {});
  }

  double calculateRatio(int expenses, int income) {
    double ratio = expenses / income;
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }

  Future<void> _deleteExpense(int index) async {
    final expenseStorage = ExpenseStorage();
    final expense = items[index];
    setState(() {
      items.removeAt(index);
      if (expense.isIncome) {
        incomeMoney -= expense.amount;
      } else {
        spentMoney -= expense.amount;
      }
      balanceMoney = incomeMoney - spentMoney;
      ratioMoney = calculateRatio(spentMoney, incomeMoney);
    });
    await expenseStorage.saveExpenses(items);
  }

  @override
  Widget build(BuildContext context) {
    final expenseStorage = ExpenseStorage();

    // Group transactions by date
    Map<String, List<ExpenseModel>> groupedItems = {};
    for (var item in items) {
      groupedItems.putIfAbsent(item.date, () => []).add(item);
    }

    // Sort dates
    List<String> sortedDates = groupedItems.keys.toList()..sort((a, b) => DateFormat.yMMMd().parse(a).compareTo(DateFormat.yMMMd().parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "EXPENSE TRACKER",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return SizedBox(
                  height: 400,
                  child: AlertDialog(
                    title: Text("Add Transaction"),
                    actions: [
                      Center(
                        child: Container(
                          width: 200,
                          child: ElevatedButton(
                              onPressed: () async {
                                int dollar = int.parse(amountController.text);
                                final expenseModel = ExpenseModel(
                                  description: descriptionController.text,
                                  amount: dollar,
                                  date: currDate,
                                  isIncome: selectedValue == "Income" ? true : false,
                                );
                                setState(() {
                                  items.add(expenseModel);
                                  if (selectedValue == "Income") {
                                    incomeMoney += expenseModel.amount;
                                  } else {
                                    spentMoney += expenseModel.amount;
                                  }
                                  balanceMoney = incomeMoney - spentMoney;
                                  ratioMoney = calculateRatio(spentMoney, incomeMoney);
                                });
                                await expenseStorage.saveExpenses(items);
                                Navigator.pop(context);
                                amountController.clear();
                                descriptionController.clear();
                              },
                              child: Text("ADD",style: TextStyle(color: Colors.white),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),

                        ),
                      ),
                    ],
                    content: SizedBox(
                      width: 350,
                      height: 400,
                      child: Column(
                        children: [
                          DropdownMenu<String>(
                            width: 350,
                            hintText: "Transaction Type",
                            onSelected: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                selectedValue = value!;
                              });
                            },
                            dropdownMenuEntries: options
                                .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                  value: value, label: value);
                            }).toList(),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(),
                              hintText: "Transaction Description",
                              enabledBorder: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            width: 130,
                            height: 100,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: amountController,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 3, top: 7, right: 0),
                                  child: Text(
                                    '\$',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              });
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: FundCondition(
                      type: "Expense",
                      amount: "$spentMoney",
                      color: "red",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: FundCondition(
                      amount: "$incomeMoney",
                      type: "Income",
                      color: "green",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 8),
                    child: FundCondition(
                      amount: "$balanceMoney",
                      type: "Balance",
                      color: "orange",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.all(5),
                child: LinearPercentIndicator(
                  lineHeight: 40,
                  percent: ratioMoney,
                  progressColor: Colors.red,
                  backgroundColor: Colors.green,
                  barRadius: Radius.circular(20),
                ),
              ),
              //showing items here
              SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    String date = sortedDates[index];
                    List<ExpenseModel> dateItems = groupedItems[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            date,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...dateItems.map((expense) => GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Are you sure you want to Delete?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        await _deleteExpense(items.indexOf(expense));
                                        Navigator.pop(context);
                                      },
                                      child: Text("Delete")
                                    ),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("Cancel"))
                                  ],
                                );
                              },
                            );
                          },
                          child: Item(
                            expenseModel: expense,
                          ),
                        )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


