+++
Description = ""
Tags = [
  "Development",
  "React",
]
Categories = [
  "开发",
]
date = "2016-04-21T10:43:00+08:00"
title = "react学习笔记"

+++

### JSX
React可以使用的是独有的JSX语法,包围它的`<script>`标签type值为text/babel


那什么是JSX呢，JSX其实就是JS+XML,在JSX中JS和XML可以同时存在,举个简单例子:

	var a = <div class="green">my color is green</div>

在JSX中这样的写法是完全合法的,这个a可以当成是一个html的element使用


也可以使用react.createElement创建element

``` javascript
var app = React.createElement(
    "div", //标签名或组件对象
    {class:"green"}, //元素属性集
    "my color is green" //子元素
);
```


createElement的更多信息[看这里](https://facebook.github.io/react/docs/top-level-api.html#react.createelement)

<!--more-->
-----

于是乎，我们可以自由组合js和xml了，比如

``` javascript
var names = ['Alice', 'Emily', 'Kate'];
<div>
  {
    names.map(function (name) {
      return React.createElement(
         "div", {key: names.id + name},
         "hello " + name
      )
    })
  }
</div>
```

当React遇到<时就会用xml解析,遇到{时就用js解析

### render
刚才创建的element怎么运用到html中呢,这里就需要用到react的ReactDOM.render函数

* 把a元素加入到id为example的元素中
* a可以是一个html标签，也可以是组件对象

``` javascript
ReactDOM.render(
	a, //标签名或组件对象
	document.getElementById('example')
);
```


### 组件


组件就像是一个会动的element,它有自己的方法和状态,并且可以通过一些内置函数控制element的行为.


可以拿它和c++的类做类比, 赋予的值就是类名,this.props中的就是类的初始化参数,<Message name="pigeon"/>就是实例化一个类


先来看看如何创建和使用一个组件

``` javascript
var Message = React.createClass({
  render: function() {
    return <div>Hello {this.props.name}</div>;
  }
});

ReactDom.render(
  <Message name="pigeon"/>,
  document.getElementById('example')
)
```


**propTypes方法可以强制指定属性类型**

下面该例子将会在浏览器画一个矩形,并且指定x和y属性的类型必须为数字

``` javascript
var Box = React.createClass({
    propTypes: {
      x: React.PropTypes.number.isRequired,
      y: React.PropTypes.number.isRequired,
    },
    render: function() {
      return <svg><rect width={this.props.x} height={this.props.y} /></svg>
    }
});
ReactDOM.render(
    <Box x={100} y={100}/>,
    document.body
)

```

**getDefaultProps可以为属性设置默认值**


下面圆形中的边会变成为绿色

``` javascript
var Circle = React.createClass({
    getDefaultProps : function() {
        return {
            stroke: "green",
            fill: "yellow"
        }
    },
    render: function() {
        return (
        <svg>
        <circle cx="50" cy="50" r={this.props.r} stroke={this.props.stroke} strokeWidth="4" fill={this.props.fill} />
        </svg>);
    }

});
ReactDOM.render(
    <Circle r={50} fill="red"/>,
    document.getElementById("example")
)
```

**获取真实的DOM节点**

组件并不是真实的DOM,
有时候需要获取真实DOM就必须用到ref属性

``` javascript
var MyComponent = React.createClass({
  handleClick: function() {
    this.refs.myTextInput.focus();
  },
  render: function() {
    return (
      <div>
        <input type="text" ref="myTextInput" />
        <input type="button" value="Focus the text input" onClick={this.handleClick} />
      </div>
    );
  }
});

ReactDOM.render(
  <MyComponent />,
  document.getElementById('example')
);
```

**状态**

组件拥有状态，状态和属性的区别在于，属性表示那些不变的值，而状态会和用户交互

``` javascript
var Circle = React.createClass({
    getInitialState: function() {
        return {fill: "pink"}
    },
    handleClick: function(event) {
        if(this.state.fill === "pink") {
            this.setState({fill: "blue"});
        } else {
            this.setState({fill: "pink"});
        }
    },
    getDefaultProps : function() {
        return {
            stroke: "green",
        }
    },
    render: function() {
        return (
            <svg>
                <circle cx="50" cy="50" r={this.props.r} stroke={this.props.stroke} fill={this.state.fill} strokeWidth="4"  onClick={this.handleClick} />
            </svg>
        );
    }
});
ReactDOM.render(
    <Circle r={50} />,
    document.getElementById("example")
);
```

**表单**

用户填入表单的数据react的组件是无法通过this.props读取的，必须通过onChange回调函数等方式:

``` javascript
var MySelect = React.createClass({
    getInitialState: function(){
      return {
          select: "KFC"
      }
    },
    change: function (event) {
        console.log("chang once "+ event.target.value);
        this.setState({select: event.target.value});

    },
    render: function() {
        var select_value = this.state.select;
        return (
        <div>
          <select id="lang" onChange={this.change} defaultValue={select_value}>
            <option value="KFC">KFC</option>
            <option value="mcdonald">mcdonald</option>
          </select>
          <p>supper: {select_value}</p>
        </div>
    )}
});
ReactDOM.render(
    <MySelect />,
    document.getElementById("example")
)
```


**生命周期**

组件有个生命周期的概念，生命周期分为3部分

    Mounting：已插入真实 DOM
    Updating：正在被重新渲染
    Unmounting：已移出真实 DOM

与之对应的N个函数

    getInitialState() 初始化state函数
    componentWillMount() 当组件将被挂载
    componentDidMount() 当组件挂载之后
    componentWillReceiveProps(object nextProps) 当挂载的组件接收新的属性时
    shouldComponentUpdate(object nextProps, object nextState): boolean  组件是否更新的callback,返回false表示不更新
    componentWillUpdate(object nextProps, object nextState) 组件更新之前
    componentDidUpdate(object prevProps, object prevState) 组件更新之后
    componentWillUnmount() 组件卸载之前



**一个异步请求**

在请求未收到前页面会一直处于loading状态,我们通过让组件挂载后调用componentDidMount方法来异步获取github api上的数据


在ajax请求完成前一直显示等待信息,ajax请求到达后通过this.setState去触发页面的重新渲染

``` javascript
var MyList = React.createClass({
    getInitialState: function() {
        return {
            loading: true,
            data: null,
            error: null
        }
    },
    componentDidMount: function(){
        this.props.promise.done(
            msg => {this.setState({loading: false, data:msg});}
        ).fail(
            (jqXHR, textStatus) => {this.setState({loading: false, error: textStatus });}
        )
    },
    render: function () {
        if (this.state.loading) {
            return <span>loading...</span>;
        }
        else if (this.state.error !== null) {
            return <span>Error: {this.state.error}</span>;
        }
        else {
            var repos = this.state.data.items;
            var repoList = repos.map(function (repo){
                return (
                    <li>
                        <a href={repo.html_url}>{repo.name}</a>
                        ({repo.stargazers_count} stars)
                        <br/>
                        {repo.description}
                    </li>
                )
            });
            return (
                <main>
                    <h1>Most Popular JavaScript Projects in Github</h1>
                    <ol>{repoList}</ol>
                </main>
            );
        }
    }
});
ReactDOM.render(
    <MyList promise={$.getJSON("https://api.github.com/search/repositories?q=golang&sort=stars")}/>,
    document.body
);
```


### 好了,总结一下

react想要把元素挂载到真实DOM上必须用**ReactDOM.render**


该函数第一参数是想要挂载的组件或html标签


第二参数则是被挂载的html标签对象


**react的基本函数**

    createElement 创建一个html的标签
    createClass 创建一个React的组件

React的组件和html标签可以互相任意嵌套

**creactClass中有各种各样的内置函数**

    render 在组件被挂载或者更新时调用
    getDefaultProps 设置组件默认属性值
    getInitialState 设置组件默认状态值
    组件生命周期 Mounting, Updating, Unmounting 发生变化前后回调的一些函数

React的组件无法获取用户的交互信息,必须通过回调函数来通知组件.


比如按钮点击,表单信息的修改,


如果React的组件也想触发事件必须先通过this.ref获取真实的DOM,虚拟DOM是无法触发事件的
