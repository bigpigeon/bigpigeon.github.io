+++
Categories = [
  "Operation",
  "Javascript",
]
menu = "main"
Description = ""
Tags = [
  "开发",
]
date = "2015-12-19T22:00:00+08:00"
title = "pac脚本优化"
+++
最近发现lantern和shadowsocks client自生成pac都一定的性能问题，在url数目上升到一定程度的时候加载速度明显慢了很多.

于是我翻看了它们的实现

- lantern
  - 把所有需要代理的domain组合成一个RegExp，然后在FindProxyForURL时对host做RegExp.exec的操作来判断是否需要代理
- shadowsocks
  -   把domain做成一个{domain:1,...}的字典，然后在FindProxyForURL时对host做domains.hasOwnProperty判断是否在字典内，若不在，则去掉最前面的'.'和之前的内容 继续做domains.hasOwnProperty判断

可以看出lantern的pac会严重影响网页的加载速度，shadowsocks的稍微好点，但在遇到不需要代理的网页时则会消耗更多无谓的判断
<!--more-->
于是我自己实现一个pac优化FindProxyForURL匹配速度

我的思路是:

- 把所有需要代理的url以 '.' 分割成节点
- 然后存入一个dict 格式如下

``` javascript
{
  "com": {
    "google": true,
    "blogspot": {
      "www": true  
    }
  }
}
```

- 在FindProxyForURL中把host也split成list与这个dict match一下

``` javascript
var domains = [
    "google.com",
    "www.blogspot.com",
    ...
];
var domain_dict = {};
for(var i = 0; i < domains.length; i++){
    if(domains[i].endsWith(".")){
        domains[i] = domains[i].slice(0, -1)
    }
    var url_list = domains[i].split('.');

    var domain_node = domain_dict;
    for(var j = url_list.length; j > 0; j--){
        var node_name = url_list[j-1];
        if (!domain_node.hasOwnProperty(node_name)){
            if (j === 1){
                domain_node[node_name] = true;
                break;
            } else {
                domain_node[node_name] = {};
            }
        } else if(domain_node[node_name] === true) {
            break;
        }
        domain_node = domain_node[node_name];
    }
}

var proxy = "SOCKS5 127.0.0.1:1080; SOCKS 127.0.0.1:1080; DIRECT";

var direct = 'DIRECT;';

function FindProxyForURL(url, host) {
    if( host == "localhost" ||
        host == "127.0.0.1") {
        return direct;
    }
    var host_list = host.split('.')
    var domain_node = domain_dict
    for(var i = host_list.length; i > 0; i--){
        var node_name = host_list[i-1]
        if (domain_node.hasOwnProperty(node_name)){
            if(domain_node[node_name] === true){
                return proxy;
            } else {
                domain_node = domain_node[node_name]
            }

        }
        else {
            return direct;
        }
    }
    return direct;
}
```

- 以下是我在nodejs下的性能测试结果 [测试js下载地址](/static/testdata/pac_benchmark.zip)

<div>
<canvas id="bench-chart-10k" width="860" height="500"></canvas>
<canvas id="bench-chart-100k" width="860" height="500"></canvas>
<canvas id="bench-chart-1m" width="860" height="500"></canvas>
<script src="../../js/Chart.min.js"></script>
<script>
var benck10kData = {
  shadowsocks: [3, 2, 6, 3, 5, 4],
  lantern: [4, 32, 2, 39, 18, 47],
  owner: [3, 3, 11, 3, 3, 3]
};
var benck100kData = {
  shadowsocks: [24, 22, 37, 37, 47, 51],
  lantern: [29, 279, 27, 373, 163, 441],
  owner: [27, 23, 29, 24, 29, 24]
};
var benck1mData = {
  shadowsocks: [136, 130, 287, 309, 401, 460],
  lantern: [222, 2776, 258, 3698, 1631, 4420],
  owner: [224, 220, 285, 218, 287, 220]
};

function renderChart(ctx, data) {
  var chart_obj = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['proxy_2_node', 'noproxy_2_node', 'proxy_3_node', 'noproxy_3_node', 'proxy_4_node', 'noproxy_4_node'],
      datasets: [
        {
          type: 'bar',
          label: 'shadowsocks',
          data: data.shadowsocks,
          backgroundColor: "#1C9b47",
        },
        {
          type: 'bar',
          label: 'lantern',
          data: data.lantern,
          backgroundColor: "#00BCD4",
        },
        {
          type: 'bar',
          label: 'owner',
          data: data.owner,
          backgroundColor: "#FF4088",
        }
      ]
    },
    options: {
        title: {
            display: true,
            text: ctx.id
        }
    }
  });
  return chart_obj;
}

renderChart(document.getElementById("bench-chart-10k"), benck10kData);
renderChart(document.getElementById("bench-chart-100k"), benck100kData);
renderChart(document.getElementById("bench-chart-1m"), benck1mData);



</script>
</div>
