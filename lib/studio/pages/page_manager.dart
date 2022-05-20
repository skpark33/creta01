import 'package:creta01/common/util/logger.dart';
import 'package:creta01/model/acc_property.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:sortedmap/sortedmap.dart';

import 'package:creta01/acc/acc_manager.dart';
//import 'package:creta01/constants/strings.dart';
import '../../acc/acc.dart';
import '../../book_manager.dart';
import '../../model/pages.dart';
import '../../model/models.dart';
import '../../model/model_enums.dart';
import '../../common/undo/undo.dart';
//import '../../db/db_actions.dart';

PageManager? pageManagerHolder;

class PageManager extends ChangeNotifier {
  // factory PageManager.singleton() {
  //   return PageManager();
  // }

  int pageIndex = 0;
  Map<String, PageModel> pageMap = <String, PageModel>{};
  SortedMap<int, PageModel> orderMap = SortedMap<int, PageModel>();
  List<Node> nodes = [];

  PropertyType _propertyType = PropertyType.book;
  PropertyType get propertyType => _propertyType;
  void setPropertyType(PropertyType p) {
    _propertyType = p;
  }

  PropertyType _prevPropertyType = PropertyType.book;
  PropertyType get prevPropertyType => _prevPropertyType;
  void setPrevPropertyType(PropertyType p) {
    _prevPropertyType = p;
  }

  Future<void> setAsAcc() async {
    setPrevPropertyType(_propertyType);
    _propertyType = PropertyType.acc;
    notifyListeners();
  }

  Future<void> setAsPage() async {
    setPrevPropertyType(_propertyType);
    _propertyType = PropertyType.page;
    notifyListeners();
  }

  Future<void> setAsContents() async {
    setPrevPropertyType(_propertyType);
    _propertyType = PropertyType.contents;
    notifyListeners();
  }

  Future<void> setAsBook() async {
    setPrevPropertyType(_propertyType);
    _propertyType = PropertyType.book;
    notifyListeners();
  }

  Future<void> setAsSettings() async {
    setPrevPropertyType(_propertyType);
    _propertyType = PropertyType.settings;
    notifyListeners();
  }

  Future<void> back() async {
    _propertyType = prevPropertyType;
    notifyListeners();
  }

  bool isAcc() {
    return _propertyType == PropertyType.acc;
  }

  bool isPage() {
    return _propertyType == PropertyType.page;
  }

  bool isContents() {
    return _propertyType == PropertyType.contents;
  }

  bool isBook() {
    return _propertyType == PropertyType.book;
  }

  bool isSettings() {
    return _propertyType == PropertyType.settings;
  }

  int lastWidth = 1920;
  int lastHeight = 1080;

  String _selectedMid = '';

  void createFirstPage() {
    _selectedMid = createPage();
  }

  String createPage() {
    String retval = '';
    PageModel page = PageModel(bookManagerHolder!.defaultBook!.mid);
    MyChange<PageModel> c = MyChange<PageModel>(page, execute: () {
      retval = pageManagerHolder!.redoCreatePage(page);
    }, redo: () {
      retval = pageManagerHolder!.redoCreatePage(page);
    }, undo: (PageModel old) {
      retval = pageManagerHolder!.undoCreatePage(old); // 값이 동일하다면, 할 필요가 없다.
    });
    mychangeStack.add(c);
    return retval;
  }

  String redoCreatePage(PageModel page) {
    page.order.set(pageIndex, noUndo: true, save: false);
    page.isRemoved.set(false, noUndo: true, save: false);
    logHolder.log('redoCreatePage $pageIndex', level: 6);
    pageMap[page.mid] = page;
    orderMap[page.order.value] = page;
    pageIndex++;
    return page.mid;
  }

  String undoCreatePage(PageModel page) {
    if (isPageSelected(page.mid)) {
      setSelectedFirst();
    }
    pageIndex--;
    logHolder.log('undoCreatePage $pageIndex', level: 6);
    page.isRemoved.set(true, noUndo: true, save: false);
    String mid = page.mid;
    orderMap.remove(page.order.value);
    pageMap.remove(mid);
    return mid;
  }

  void pushPages(List<PageModel> list) {
    logHolder.log('pushPages $pageIndex', level: 5);
    pageMap.clear();
    orderMap.clear();
    int minOrder = 999999999;
    int maxOrder = 0;
    for (PageModel page in list) {
      logHolder.log('page(${page.order.value}) added', level: 5);
      pageMap[page.mid] = page;
      orderMap[page.order.value] = page;
      if (page.order.value <= minOrder) {
        minOrder = page.order.value;
      }
      if (page.order.value > maxOrder) {
        maxOrder = page.order.value;
      }
      if (page.accPropertyList.isNotEmpty) {
        accManagerHolder!.pushACCs(page);
      }
    }
    pageIndex = maxOrder + 1;
    _selectedMid = orderMap[minOrder] != null ? orderMap[minOrder]!.mid : '';
  }

  void makeCopy(String oldBookMid, String newBookMid) {
    for (PageModel page in pageMap.values) {
      if (page.parentMid.value == oldBookMid) {
        PageModel newPage = page.makeCopy(newBookMid);
        accManagerHolder!.makeCopy(page.mid, newPage.mid);
      }
    }
  }

  String getFirstPage() {
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        return model.mid;
      }
    }
    return '';
  }

  String getLastPage() {
    String retval = '';
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        retval = model.mid;
      }
    }
    return retval;
  }

  int getLength() {
    int count = 0;
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        count++;
      }
    }
    return count;
  }

  bool removePage(BuildContext context, String mid) {
    if (pageMap[mid] == null) {
      logHolder.log('removePage($mid) is null', level: 5);
      return false;
    }
    if (getLength() <= 1) {
      logHolder.log('last page ($mid) cant be deleted', level: 7);
      return false;
    }
    logHolder.log('removePage($mid)', level: 5);

    mychangeStack.startTrans();
    for (PageModel model in pageMap.values) {
      if (model.order.value > pageMap[mid]!.order.value) {
        model.order.set(model.order.value - 1);
      }
    }
    pageMap[mid]!.isRemoved.set(true);
    for (ACCProperty accProperty in pageMap[mid]!.accPropertyList) {
      accProperty.isRemoved.set(true);
      ACC? acc = accManagerHolder!.getACC(accProperty.mid);
      if (acc != null) {
        acc.accChild.playManager.removeAll();
      }
    } // 아래의 모든 acc 를 삭제.
    mychangeStack.endTrans();
    if (isPageSelected(mid)) {
      setSelectedIndex(context, getFirstPage());
    }
    accManagerHolder!.notifyAll();
    return true;
  }

  changeOrder(int newIndex, int oldIndex) {
    logHolder.log('changeOrder($oldIndex --> $newIndex)', level: 5);
    mychangeStack.startTrans();
    orderMap[newIndex]!.order.set(oldIndex);
    orderMap[oldIndex]!.order.set(newIndex);
    mychangeStack.endTrans();
  }

  bool isPageSelected(String mid) {
    logHolder.log('isPageSelected($mid)');
    return _selectedMid == mid;
  }

  PageModel? getSelected() {
    if (_selectedMid.isEmpty) {
      return null;
    }
    return pageMap[_selectedMid];
  }

  int getPageIndex() {
    if (_selectedMid.isEmpty) {
      return 0;
    }
    int pageNo = 0;
    for (PageModel model in orderMap.values) {
      pageNo++;
      if (_selectedMid == model.mid) {
        return pageNo;
      }
    }
    return pageNo;
  }

  int getPageCount() {
    int pageCount = 0;
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        pageCount++;
      }
    }
    return pageCount;
  }

  Future<void> setSelectedIndex(BuildContext context, String val) async {
    _selectedMid = val;
    pageManagerHolder!.setAsPage(); //setAsPage contain notify();
    PageModel? page = pageManagerHolder!.getSelected();
    if (page != null) {
      await page.waitPageBuild(); // 페이지가 완전히 빌드 될때까지 기둘린다.
      // ignore: use_build_context_synchronously
      accManagerHolder!.showPages(context, val); // page 가 완전히 노출된 후에 ACC 를 그린다.
    }
  }

  Future<void> next(BuildContext context) async {
    PageModel? page = pageManagerHolder!.getSelected();
    if (page == null) {
      return;
    }
    bool matched = false;
    int nextOrder = -1;
    for (int order in orderMap.keys) {
      if (order == page.order.value) {
        matched = true;
        continue;
      }
      if (matched && page.isRemoved.value == false) {
        nextOrder = order;
        break;
      }
    }
    String mid = '';
    if (nextOrder < 0) {
      mid = getFirstPage();
    } else {
      mid = orderMap[nextOrder]!.mid;
    }
    if (mid.isNotEmpty) {
      await setSelectedIndex(context, mid);
    }
  }

  Future<void> prev(BuildContext context) async {
    PageModel? page = pageManagerHolder!.getSelected();
    if (page == null) {
      return;
    }
    int prevOrder = -1;
    for (int order in orderMap.keys) {
      if (order == page.order.value) {
        break;
      }
      if (page.isRemoved.value == false) {
        prevOrder = order;
      }
    }
    String mid = '';
    if (prevOrder < 0) {
      mid = getLastPage();
    } else {
      mid = orderMap[prevOrder]!.mid;
    }
    if (mid.isNotEmpty) {
      await setSelectedIndex(context, mid);
    }
  }

  String setSelectedFirst() {
    _selectedMid = getFirstPage();
    if (pageManagerHolder != null) {
      pageManagerHolder!.setAsPage();
    } //setAsPage contain notify();
    if (accManagerHolder != null) {
      accManagerHolder!.notify();
    } //setAsPage contain notify();
    return _selectedMid;
  }

  void reorderMap() {
    orderMap.clear();
    for (PageModel model in pageMap.values) {
      if (model.isRemoved.value == false) {
        orderMap[model.order.value] = model;
      }
    }
  }

  void notify() {
    notifyListeners();
  }

  List<Node> toNodes(PageModel? selectedModel) {
    //  Node(
    //       label: 'documents',
    //       key: 'docs',
    //       expanded: docsOpen,
    //       // ignore: dead_code
    //       icon: docsOpen ? Icons.folder_open : Icons.folder,
    //       children: [ ]
    //  );
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        String pageNo = (model.order.value + 1).toString().padLeft(2, '0');
        String desc = model.getDescription();
        List<Node> accNodes = accManagerHolder!.toNodes(model);
        nodes.add(Node<AbsModel>(
            key: model.mid,
            label: 'Page $pageNo. $desc',
            data: model,
            expanded: (selectedModel != null && model.mid == selectedModel.mid) || model.expanded,
            children: accNodes));
      }
    }
    return nodes;
  }
}
