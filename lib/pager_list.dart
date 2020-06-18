library flutter_pager_list;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'easy_listview.dart';


typedef PagerBuilder<T> = Future<List<T>> Function(int page,List<T> currentDatas);
typedef ListItemBuilder<T> = Widget Function(BuildContext context, T item, int index);
typedef WidgetErrorBuilder<T> = Widget Function(BuildContext context, String errorMsg);
typedef onError<T> = Function(int page,T error);

//加载状态
enum LoadingState {
  loading,
  success,
  error,
}

/**
 * linbing
 */
class PagerListView<T> extends StatefulWidget {

  PagerListView({
    Key key,
    @required this.pagerBuilder,
    @required this.itemBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.dividerBuilder,
    this.scrollController,
    this.pageSize,
    this.refreshable,
    this.noMoreDataShow,
    this.loadingDataShow,
    this.useLoadMore,
    this.useRefresh,
    this.loadingMoreLoadingBuilder,
    this.loadingMoreErrorBuilder,
    this.loadingMoreNoMoreBuilder,
    this.usePageState,
    this.pageLoadingBuilder,
    this.pageEmptyBuilder,
    this.pageErrorBuilder,
  }) :  assert(pagerBuilder != null),
        assert(itemBuilder != null),
        super(key: key);

  final PagerBuilder pagerBuilder;
  final ListItemBuilder itemBuilder;
  final WidgetBuilder headerBuilder;
  final WidgetBuilder footerBuilder;
  final IndexedWidgetBuilder dividerBuilder;
  final ScrollController scrollController;

  int pageSize = 10;
  bool refreshable = true;

  bool useLoadMore = true; //是否使用加载下一页
  bool useRefresh = true; //是否使用下拉刷新

  //使用默认
  String noMoreDataShow; //自定义没有更多数据的显示
  String loadingDataShow; //自定义加载中显示


  //不使用默认
  final WidgetBuilder loadingMoreLoadingBuilder; //自定义加载下一页底部加载
  final WidgetErrorBuilder loadingMoreErrorBuilder; //自定义加载下一页底部加载失败
  final WidgetBuilder loadingMoreNoMoreBuilder; //自定义加载下一页底部加载没有更多

  bool usePageState = true; //使用页面加载状态，包括加载中，加载失败，空界面
  final WidgetBuilder pageLoadingBuilder; //自定义页面加载
  final WidgetBuilder pageEmptyBuilder; //自定义页面空数据
  final WidgetErrorBuilder pageErrorBuilder; //自定义页面错误

  @override
  State<StatefulWidget> createState() => PagerListViewState();
}


class PagerListViewState extends State<PagerListView> {
  bool hasNextPage = true; //是否有下一页数据
  List datas = new List();
  bool isLoadingMore = false; //是否在加载下一页
  int currentPage = 1; //当前页
  int nextPage = 1;
  int pageSize = 10;
  var loadingState = LoadingState.success; //下一页加载状态
  String errorMsg;//加载下一页错误信息
  bool useLoadMore = true; //是否使用加载下一页
  bool useRefresh = true; //是否使用下拉刷新
  bool usePageState = true; //使用页面加载状态，包括加载中，加载失败，空界面
  bool loadingMoreError = false; //最新一次请求下一页是否出现错误

  @override
  void initState() {
    super.initState();

    this.init();
    this.loadPageDatas(1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void init() {
    if(widget.pageSize != null) {
      this.pageSize = widget.pageSize;
    }

    if(widget.useLoadMore != null) {
      this.useLoadMore = widget.useLoadMore;
    }

    if(widget.useRefresh != null) {
      this.useRefresh = widget.useRefresh;
    }

    if(widget.usePageState != null) {
      this.usePageState = widget.usePageState;
    }
  }

  Widget defaultDividerBuilder(context, index) => Divider(
    color: Colors.grey,
    height: 1.0,
  );

  Widget itemBuilder(context, index) {
    var data = this.datas[index];
    return widget.itemBuilder(context,data,index);
  }

  Widget loadMoreItemBuilder(context){
    switch(this.loadingState) {
      case LoadingState.success:
        return loadMoreSuccessItemBuilder(context);
        break;
      case LoadingState.error:
        return loadMoreErrorItemBuilder(context);
        break;
      default: //loading
        return loadMoreLoadingItemBuilder(context);
        break;
    }

  }

  Widget loadMoreLoadingItemBuilder(context){
    if(widget.loadingMoreLoadingBuilder != null) {
      return widget.loadingMoreLoadingBuilder(context);
    }
    var msg =  "加载中...";
    if(widget.loadingDataShow != null) {
      msg = widget.loadingDataShow;
    }
    return Container(
        height: 40,
        color: Colors.white,
        alignment: AlignmentDirectional.center,
        child: Row(
          mainAxisAlignment:MainAxisAlignment.center ,
          children: <Widget>[
            Container(
              height: 20,
              width: 20,
              child:CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: Color(0xFFeeeeee),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey) ,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                  msg,
                  style:TextStyle(fontSize: 10,color: Color(0xFF000000))
              ),
            )
          ],
        )
    );
  }

  Widget loadMoreErrorItemBuilder(context){
    if(widget.loadingMoreErrorBuilder != null) {
      return widget.loadingMoreErrorBuilder(context,errorMsg);
    }
    var msg =  "加载失败，请重试！";
    if(errorMsg != null) {
      msg = errorMsg;
    }
    return Container(
      height: 40,
      color: Colors.white,
      alignment: AlignmentDirectional.center,
      child:Text(
          msg,
          style:TextStyle(fontSize: 10,color: Color(0xFF000000))
      ),
    );
  }

  Widget loadMoreSuccessItemBuilder(context){
    if(!hasNextPage) {
      if(widget.loadingMoreNoMoreBuilder != null) {
        return widget.loadingMoreNoMoreBuilder(context);
      }
      var msg =  "无更多数据";
      if(widget.noMoreDataShow != null) {
        msg = widget.noMoreDataShow;
      }
      return Container(
        height: 40,
        color: Colors.white,
        alignment: AlignmentDirectional.center,
        child:Text(
            msg,
            style:TextStyle(fontSize: 10,color: Color(0xFF000000))
        ),
      );
    }
    return Container(
      height: 40,
      color: Colors.white,
      alignment: AlignmentDirectional.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    if(this.useRefresh) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildList(context),
      );
    }
    return _buildList(context);
  }

  //页面加载中，空界面和加载失败
  Widget _buildPageState(BuildContext context) {
    if(!this.usePageState) {
      return null;
    }
    //页面加载
    if(this.currentPage == 1
        && this.datas.length == 0
        && this.loadingState == LoadingState.success
        && this.hasNextPage == true) {
      return _buildPageLoadingState(context);
    }

    //页面空数据
    if(this.currentPage == 1
        && this.datas.length == 0
        && this.loadingState == LoadingState.success
        && this.hasNextPage == false) {
      return _buildPageEmptyState(context);
    }

    //页面错误
    if(this.currentPage == 1
        && this.datas.length == 0
        && this.loadingState == LoadingState.error
        && this.hasNextPage == true) {
      return _buildPageErrorState(context);
    }
  }

  Widget _buildPageLoadingState(BuildContext context) {
    if(widget.pageLoadingBuilder != null) {
      return widget.pageLoadingBuilder(context);
    }

    var msg =  "加载中...";
    if(widget.loadingDataShow != null) {
      msg = widget.loadingDataShow;
    }
    return
      Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
                color: Colors.transparent,
                alignment: AlignmentDirectional.center,
                child: Column(
                  mainAxisAlignment:MainAxisAlignment.center ,
                  children: <Widget>[
                    Container(
                      height: 20,
                      width: 20,
                      child:CircularProgressIndicator(
                        strokeWidth: 3,
                        backgroundColor: Color(0xFFeeeeee),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey) ,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                          msg,
                          style:TextStyle(fontSize: 15,color: Color(0xFF000000))
                      ),
                    )
                  ],
                )
            ),
          )
        ],
      );

  }

  Widget _buildPageEmptyState(BuildContext context) {
    if(widget.pageEmptyBuilder != null) {
      return widget.pageEmptyBuilder(context);
    }
    var msg =  "空空如也";
    return
      Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: onRetry,
                  child: Container(
                      color: Colors.transparent,
                      alignment: AlignmentDirectional.center,
                      child: Column(
                        mainAxisAlignment:MainAxisAlignment.center ,
                        children: <Widget>[
                          Image.asset('imgs/empty.png'),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                                msg,
                                style:TextStyle(fontSize: 15,color: Color(0xFF000000))
                            ),
                          )
                        ],
                      )
                  ),
                )
            )
         ]);
  }

  Widget _buildPageErrorState(BuildContext context) {
    if(widget.pageErrorBuilder != null) {
      return widget.pageErrorBuilder(context,errorMsg);
    }
    var msg =  "出现错误了，请重试";
    if(errorMsg != null) {
      msg = errorMsg;
    }
    return
      Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Expanded(
                flex: 1,
                child:
                GestureDetector(
                  onTap: onRetry,
                  child:Container(
                      color: Colors.transparent,
                      alignment: AlignmentDirectional.center,
                      child: Column(
                        mainAxisAlignment:MainAxisAlignment.center ,
                        children: <Widget>[
                          Image.asset('imgs/error.png'),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                                msg,
                                style:TextStyle(fontSize: 15,color: Color(0xFF000000))
                            ),
                          )
                        ],
                      )
                  ),
                )

            )
        ]);
  }


  Widget _buildList(BuildContext context) {
    IndexedWidgetBuilder dividerBuilder =  widget.dividerBuilder;
    if(dividerBuilder == null) {
      dividerBuilder = defaultDividerBuilder;
    }
    var  foregroundWidget = _buildPageState(context);

    return EasyListView(
//        physics: BouncingScrollPhysics(),
        controller: widget.scrollController,
//          headerSliverBuilder: headerSliverBuilder,
        headerBuilder: widget.headerBuilder,
        footerBuilder: widget.footerBuilder,
        itemCount: datas.length,
        // 1 for custom scroll view example.
        itemBuilder: itemBuilder,
        dividerBuilder: dividerBuilder,
        loadMore: useLoadMore,
        loadMoreWhenNoData:true,
        onLoadMore: onLoadMore,
        loadMoreItemBuilder:loadMoreItemBuilder,
        foregroundWidget:foregroundWidget,
      );

  }

  Future _onRefresh() async {
    await this.loadPageDatas(1);
  }

  loadPageDatas(page) async{
    await this.widget.pagerBuilder(page,datas).then((lists) {
      bool hasNext = true;
      var loadingState = LoadingState.loading;
      if(lists == null || lists.length < this.pageSize) {
        hasNext = false;
        loadingState = LoadingState.success;
      }

      if(page > 1) {
        this.currentPage = this.currentPage + 1;
      }else {
        this.currentPage = 1;
        this.datas.clear();
      }

      if(lists != null) {
        this.datas.addAll(lists);
      }
      this.loadingState = loadingState;
      this.hasNextPage = hasNext;
      this.setState(() {
        hasNextPage = hasNext;
        datas = this.datas;
        loadingState = loadingState;
      });
      this.isLoadingMore = false;
    }).catchError((error) {
      String msg = "加载失败，请重试！";
      try {
        if(error != null && error.message != null) {
          msg = error.message;
        }
      }catch(e) {
      }

      if(page > 1) {
        this.loadingMoreError = true;
      }
      this.setState(() {
        loadingState = LoadingState.error;
        errorMsg = msg;
      });
      this.isLoadingMore = false;
    });

  }


  onLoadMore() {
      if(this.isLoadingMore == true) {
        return;
      }
      this.isLoadingMore = true;
      this.setState(() {
        loadingState=LoadingState.loading;
      });
      this.nextPage = this.currentPage + 1;
      this.loadPageDatas(this.nextPage);
  }

  onRetry() {
    this.setState(() {
      loadingState=LoadingState.success;
      hasNextPage=true;
    });
    this.loadPageDatas(1);
  }








}
