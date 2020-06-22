# flutter_pager_list
flutter listview refresh and loading more with pager and page loading，empty，error show 
<br/>
列表封装下拉刷新，加载更多，同时支持设置头部和底部，支持设置页面数据加载中，数据为空或者加载失败显示
<br/>
使用方法：<br/>

    PagerListView(
          headerBuilder: headerBuilder,
          footerBuilder: footerBuilder,
          itemBuilder: itemBuilder,
          pagerBuilder: pageBuilder,
          useLoadMore: true,
          pageSize:20,),
          
    主要看分页数据获取处理pagerBuilder，该回调用来获取指定页数的数据，一般为请求接口数据，例如例子中的延迟模拟数据<br/>
    
    Future<List<String>> pageBuilder(int page,List currentDatas) async {
      await Future.delayed(Duration(seconds: 0, milliseconds: 2000));
      List<String> dummyList = List();
      //测试第三页加载失败
      if(page == 3) {
        throw FormatException('处理失败，请重试');
      }
      // 测试空数据
      //   if(page == 1) {<br/>
       //     return dummyList;<br/>
      //   }
      int start = 0;
      if(currentDatas != null && page > 1) {
        start = currentDatas.length;
      }
      for (int i = start; i < start + 20; i++) {
        dummyList.add('Item $i');
      }
      return dummyList;
      }
        
        
        
效果图如下：<br/>

## Getting Started
![image](https://img-blog.csdnimg.cn/20200622145717550.png)
![image](https://img-blog.csdnimg.cn/20200622145717597.png)
![image](https://img-blog.csdnimg.cn/20200622145717693.png)
![image](https://img-blog.csdnimg.cn/20200622145717696.png)
![image](https://img-blog.csdnimg.cn/20200622145717694.png)
