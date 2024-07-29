import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/data/constant.dart';
import 'package:shopping_list/models/category.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  Uri uriShopee = Uri.https(db, 'shopee.json');
  @override
  void initState() {
    _loadItem();
    super.initState();
  }

  Future<List<GroceryItem>> _loadItem() async {
    final response = await http.get(uriShopee);
    final Map decode = jsonDecode(response.body);
    List<GroceryItem> allData = [];
    for (final itemEntry in decode.entries) {
      Category category = categories.entries.firstWhere((category) {
        return category.value.title == itemEntry.value['category'];
      }).value;

      allData.add(
        GroceryItem(
          id: itemEntry.key,
          name: itemEntry.value['name'] ?? '',
          quantity: itemEntry.value['quantity'] ?? 0,
          category: category,
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 1000));
    return allData;
  }

  void _addItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    List<GroceryItem> item = await _loadItem();
    setState(() {
      groceryItems = item;
    });
  }

  void _removeItem(GroceryItem item) async {
    GroceryItem keepItem = item;
    setState(() {
      groceryItems.remove(item);
    });
    try {
      Uri uriShopee = Uri.https(db, 'shopee/${item.id}.json');
      await http.delete(uriShopee);
    } catch (e) {
      setState(() {
        groceryItems.add(keepItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadItem(),
      builder: (context, snapshot) {
        print(snapshot.connectionState);
        Widget content = const Center(child: Text('No items added yet.'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
        if (snapshot.hasData) {
          groceryItems = snapshot.data!;

          content = ListView.builder(
            itemCount: groceryItems.length,
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(groceryItems[index]);
              },
              key: ValueKey(groceryItems[index].id),
              child: ListTile(
                title: Text(groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: groceryItems[index].category.color,
                ),
                trailing: Text(
                  groceryItems[index].quantity.toString(),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Groceries'),
            actions: [
              IconButton(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
