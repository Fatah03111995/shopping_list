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
  List<GroceryItem> _groceryItems = [];
  Uri uriShopee = Uri.https(db, 'shopee.json');
  @override
  void initState() {
    _loadItem();
    super.initState();
  }

  void _loadItem() async {
    print('LOAD WORK');
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

    setState(() {
      _groceryItems = allData;
    });
  }

  void _addItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    _loadItem();
  }

  void _removeItem(GroceryItem item) async {
    GroceryItem keepItem = item;
    setState(() {
      _groceryItems.remove(item);
    });
    try {
      Uri uriShopee = Uri.https(db, 'shopee/${item.id}.json');
      await http.delete(uriShopee);
    } catch (e) {
      setState(() {
        _groceryItems.add(keepItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
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
  }
}
