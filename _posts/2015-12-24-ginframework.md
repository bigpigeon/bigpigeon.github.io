---
layout: post
title:  "gin框架介绍"
date:   2015-12-24 6:25:00
categories: gin golang 
excerpt: gin是一个高性能的web框架，并且有非常不错的实现，代码清楚易懂
---

#### gin的特性

支持中间层

> - 一个请求过来经过 global middleware,group middleware 最后到该path的middleware处理

大概是这个样子

<svg width="50%" height="50%" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 720">
 <!-- Created with SVG-edit - http://svg-edit.googlecode.com/ -->
 <defs>
  <linearGradient id="svg_61" x1="0" y1="0" x2="1" y2="1">
   <stop offset="0" stop-color="#1855f2"/>
   <stop offset="1" stop-color="#06cc58"/>
  </linearGradient>
  <linearGradient id="svg_64" x1="0" y1="0" x2="1" y2="1">
   <stop offset="0" stop-color="#ff0000"/>
   <stop offset="1" stop-color="#ffff00"/>
  </linearGradient>
  <linearGradient id="svg_67" x1="0" y1="0" x2="1" y2="1">
   <stop offset="0" stop-color="#ff00c3"/>
   <stop offset="1" stop-color="#0000ff"/>
  </linearGradient>
 </defs>
 <g>
  <title>Layer 1</title>
  <path transform="rotate(180 238.03820800781247,326.5081787109375) " id="svg_7" d="m207.32001,325.73959l30.71864,-320.23144l30.71776,320.23144l-15.3591,0l0,321.76859l-30.71864,0l0,-321.76859l-15.35866,0z" stroke-linecap="null" stroke-linejoin="null" stroke-width="5" stroke="#828282" fill="#5b5050"/>
  <g id="svg_71">
   <ellipse fill="url(#svg_61)" stroke="#3ddbc8" stroke-width="5" stroke-linejoin="null" stroke-linecap="null" opacity="0.36" cx="243.50001" cy="364.49999" id="svg_54" rx="318.49999" ry="225.49999" transform="rotate(90 243.49999999999997,364.50000000000006) "/>
   <g id="svg_70">
    <ellipse fill="url(#svg_64)" stroke="#3ddbc8" stroke-width="5" stroke-linejoin="null" stroke-linecap="null" opacity="0.36" cx="240" cy="494" id="svg_63" rx="192" ry="122" transform="rotate(90 239.99999999999997,494.00000000000006) "/>
    <g id="svg_69">
     <ellipse fill="url(#svg_67)" stroke="#3ddbc8" stroke-width="5" stroke-linejoin="null" stroke-linecap="null" opacity="0.36" cx="240" cy="571" id="svg_66" rx="112" ry="80" transform="rotate(90 239.99999999999991,571.0000000000001) "/>
     <text fill="#000000" stroke="#3ddbc8" stroke-width="0" stroke-linejoin="null" stroke-linecap="null" x="238" y="494" id="svg_4" font-size="12" font-family="Fantasy" text-anchor="middle" xml:space="preserve">handle middleware</text>
     <text fill="#000000" stroke="#3ddbc8" stroke-width="0" stroke-linejoin="null" stroke-linecap="null" x="239" y="509" id="svg_5" font-size="12" font-family="Fantasy" text-anchor="middle" xml:space="preserve">path=/click</text>
    </g>
    <text fill="#000000" stroke="#3ddbc8" stroke-width="0" stroke-linejoin="null" stroke-linecap="null" x="289.97143" y="312.33334" id="svg_2" font-size="12" font-family="Fantasy" text-anchor="middle" xml:space="preserve" transform="matrix(1.2068965435028076,0,0,1.799999952316284,-107.96551334857939,-219.59998703002927) ">group middleware</text>
    <text fill="#000000" stroke="#3ddbc8" stroke-width="0" stroke-linejoin="null" stroke-linecap="null" x="239" y="354" id="svg_6" font-size="12" font-family="Fantasy" text-anchor="middle" xml:space="preserve">path=/amount</text>
   </g>
   <text fill="#000000" stroke="#3ddbc8" stroke-width="0" stroke-linejoin="null" stroke-linecap="null" x="314.82313" y="78.11765" id="svg_1" font-size="12" font-family="Fantasy" text-anchor="middle" xml:space="preserve" transform="matrix(1.651685357093811,0,0,2.2666666507720947,-275.988748729229,-84.86666560173035) ">global middleware</text>
  </g>
  <rect id="svg_72" height="37" width="286" y="122" x="101" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="5" stroke="#1bd1c4" fill="#2d3fc6"/>
  <rect id="svg_75" height="43" width="349" y="165" x="71" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="5" stroke="#1348db" fill="#1aef56"/>
  <rect id="svg_78" height="38" width="151" y="358" x="166" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="3" stroke="#35f2dc" fill="#d81549"/>
  <text transform="matrix(1.7638888359069824,0,0,2.200000047683716,-370.4860854148865,-242.4000096321106) " xml:space="preserve" text-anchor="middle" font-family="Fantasy" font-size="12" id="svg_79" y="285.13637" x="347.80314" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="0" stroke="#1bd1c4" fill="#000000">function auth</text>
  <rect id="svg_80" height="29" width="122" y="511" x="181" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="2" stroke="#1bd1c4" fill="#276eba"/>
  <text transform="matrix(1.0229885578155518,0,0,1.5333333015441895,-14.080491662025452,-124.26665925979614) " xml:space="preserve" text-anchor="middle" font-family="Fantasy" font-size="12" id="svg_81" y="427.6087" x="249.34833" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="0" stroke="#1bd1c4" fill="#000000">function amount</text>
  <text transform="matrix(1.7917961062034058,0,0,1.8834476742524937,-218.1318388451736,-165.59681401862179) " xml:space="preserve" text-anchor="middle" font-family="Fantasy" font-size="12" id="svg_73" y="167.35121" x="257.49196" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="0" stroke="#1bd1c4" fill="#000000">function  recovery</text>
  <text transform="matrix(3.902939223805504,0,0,1.8285715429774143,-925.6625175890174,-105.33097001154798) " xml:space="preserve" text-anchor="middle" font-family="Fantasy" font-size="12" id="svg_77" y="163.45282" x="298.13723" opacity="0.36" stroke-linecap="null" stroke-linejoin="null" stroke-width="0" stroke="#1bd1c4" fill="#000000">function logger</text>
  <text transform="matrix(1.369369387626648,0,0,1.5333333015441895,-68.33333671092987,-6.933332920074463) " xml:space="preserve" text-anchor="middle" font-family="Fantasy" font-size="12" id="svg_8" y="25.65217" x="225.16447" stroke-linecap="null" stroke-linejoin="null" stroke-width="0" stroke="#828282" fill="#ff0000">request /amount/click</text>
 </g>
</svg>

基于Radix tree

永不崩溃
> - 处理请求崩溃后会在Recover函数中恢复然后返回500

更多特性请看[官网](https://gin-gonic.github.io/gin/)


### 基本用法

```c
package main

import "github.com/gin-gonic/gin"

func pingPath(c *gin.Context) {
	c.String(200, "pong")
}

func main() {
    r := gin.Default()
	r.GET("ping", pingPath)
	r.Run(":80")
}
```

### 上面的代码是什么意思呢？

#### 先看看gin.Default的源码

```c
func Default() *Engine {
	engine := New()
	engine.Use(Recovery(), Logger())
	return engine
}
```

> - New()是用默认参数构造一个engine
> - engine.Use(...)把Recovery() 和Logger()生成的函数增加值全局handler列
> - engine.Use要在所有handle的middleware绑定之前使用，否则某些绑定的path会不生效(在group的middleware之后加是可以的)


#### 然后我们来看看Recovery干了什么

```c
// Recovery returns a middleware that recovers from any panics and writes a 500 if there was one.
func Recovery() HandlerFunc {
	return RecoveryWithWriter(DefaultWriter)
}

func RecoveryWithWriter(out io.Writer) HandlerFunc {
	var logger *log.Logger
	if out != nil {
		logger = log.New(out, "", log.LstdFlags)
	}
	return func(c *Context) {
		defer func() {
			if err := recover(); err != nil {
				if logger != nil {
					stack := stack(3)
					logger.Printf("Panic recovery -> %s\n%s\n", err, stack)
				}
				c.AbortWithStatus(500)
			}
		}()
		c.Next()
	}
}
```

> - 关于recover的使用可以看<http://blog.golang.org/defer-panic-and-recover>
> - defer的函数会在函数结束后返回前调用
> - c.Next()就是调用下一个handler 就和Nodejs中的http库差不多
> - 大致流程就是 FuncBody -> c.Next -> defer func (一个灾难恢复就这样简单的实现了)

#### 再然后来看看Logger

```c
// Instances a Logger middleware that will write the logs to gin.DefaultWriter
// By default gin.DefaultWriter = os.Stdout
func Logger() HandlerFunc {
	return LoggerWithWriter(DefaultWriter)
}

// Instance a Logger middleware with the specified writter buffer.
// Example: os.Stdout, a file opened in write mode, a socket...
func LoggerWithWriter(out io.Writer) HandlerFunc {
	return func(c *Context) {
		// Start timer
		start := time.Now()
		path := c.Request.URL.Path

		// Process request
		c.Next()

		// Stop timer
		end := time.Now()
		latency := end.Sub(start)

		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()
		statusColor := colorForStatus(statusCode)
		methodColor := colorForMethod(method)
		comment := c.Errors.ByType(ErrorTypePrivate).String()

		fmt.Fprintf(out, "[GIN] %v |%s %3d %s| %13v | %s |%s  %s %-7s %s\n%s",
			end.Format("2006/01/02 - 15:04:05"),
			statusColor, statusCode, reset,
			latency,
			clientIP,
			methodColor, reset, method,
			path,
			comment,
		)
	}
}
```

> - 大致就是输出请求头的数据和处理请求所花费的时间
> - 但听说获取系统时间会有阻塞

#### 再来看看r.GET之后发生了什么

```c
// routergroup file 
func (group *RouterGroup) GET(relativePath string, handlers ...HandlerFunc) IRoutes {
	return group.handle("GET", relativePath, handlers)
}

func (group *RouterGroup) handle(httpMethod, relativePath string, handlers HandlersChain) IRoutes {
	absolutePath := group.calculateAbsolutePath(relativePath)
	handlers = group.combineHandlers(handlers)
	group.engine.addRoute(httpMethod, absolutePath, handlers)
	return group.returnObj()
}
```

> - 这里的类是RouterGroup但上面gin.Default()返回的却是是Engine

#### 于是我们看看Engine的定义

```c
// Engine is the framework's instance, it contains the muxer, middleware and configuration settings.
// Create an instance of Engine, by using New() or Default()
Engine struct {
	RouterGroup
	HTMLRender  render.HTMLRender
	allNoRoute  HandlersChain
	allNoMethod HandlersChain
	noRoute     HandlersChain
	noMethod    HandlersChain
	pool        sync.Pool
	trees       methodTrees
	//忽略一些太长的数据
	...

}
```

> - Engine 是继承于RouteGroup的
> - 其实可以把Engine当成是RouteGroup节点，Group是可以嵌套的

#### 最后看一下handler函数的Context参数

```c
// Context is the most important part of gin. It allows us to pass variables between middleware,
// manage the flow, validate the JSON of a request and render a JSON response for example.
type Context struct {
	writermem responseWriter
	Request   *http.Request
	Writer    ResponseWriter

	Params   Params
	handlers HandlersChain
	index    int8

	engine   *Engine
	Keys     map[string]interface{}
	Errors   errorMsgs
	Accepted []string
}

// Next should be used only inside middleware.
// It executes the pending handlers in the chain inside the calling handler.
// See example in github.
func (c *Context) Next() {
	c.index++
	s := int8(len(c.handlers))
	for ; c.index < s; c.index++ {
		c.handlers[c.index](c)
	}
}

```

> - 这里只展示了Context的定义和Next函数的实现,[详细看源码](https://github.com/gin-gonic/gin/blob/master/context.go)


> - gin的运作原理大概就是这样了,之后讲gin的一些example和[gin的github page](https://github.com/gin-gonic/gin)上的一样

### 包含参数的路径


```c
package main

import "github.com/gin-gonic/gin"
import "net/http"

func main() {
	r := gin.Default()
	// 这种写法只会匹配/user/pigeon ,/user/ 和/user就不会被匹配 
	r.GET("/user/:name", func(c *gin.Context) {
		name := c.Param("name")
		c.String(http.StatusOK, "Hello %s", name)
	})
	//这种写法会匹配 /user/pigeon/ 和/user/pigeon/enter 或 /user/pigeon/to/doing/something
	r.GET("/user/:name/*action", func(c *gin.Context) {
		name := c.Param("name")
		action := c.Param("action")
		message := name + " is " + action
		c.String(http.StatusOK, message)
	})
	r.Run(":80")
}

```

> - 大概规则就是这样

### Query字符串参数


```c
package main

import "github.com/gin-gonic/gin"

func main() {
    router := gin.Default()
	// 注:Query函数获取的值都必定是字符串
    router.GET("/welcome", func(c *gin.Context) {
        firstname := c.DefaultQuery("firstname", "Guest")
        lastname := c.Query("lastname") // shortcut for c.Request.URL.Query().Get("lastname")

        c.String(http.StatusOK, "Hello %s %s", firstname, lastname)
    })
    router.Run(":80")
}
```

> - 请尝试用如下请求路径来请求:  /welcome?firstname=Jane&lastname=Doe
> - 然后查看请求结果

### Model binding and validation

```c
package main

import "github.com/gin-gonic/gin"
import "net/http"

// Binding from JSON
type Login struct {
    User     string `form:"user" json:"user" binding:"required"`
    Password string `form:"password" json:"password" binding:"required"`
}

func main() {
    router := gin.Default()

    // 该例子将绑定一个拥有 user 和 password 键的JSON数据
    router.POST("/loginJSON", func(c *gin.Context) {
        var json Login
        if c.BindJSON(&json) == nil {
            if json.User == "manu" && json.Password == "123" {
                c.JSON(http.StatusOK, gin.H{"status": "you are logged in"})
            } else {
                c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
            }
        }
    })

    // Example for binding a HTML form (user=manu&password=123)
    router.POST("/loginForm", func(c *gin.Context) {
        var form Login
        // 用http头中Content-Type 的值去判定数据类型
        if c.Bind(&form) == nil {
            if form.User == "manu" && form.Password == "123" {
                c.JSON(http.StatusOK, gin.H{"status": "you are logged in"})
            } else {
                c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
            }
        }
    })

    router.Run(":80")
}
```

### 在中间层中使用goroute



```c
package main

import "github.com/gin-gonic/gin"
import "time"
import "log"

func main() {
    r := gin.Default()

    r.GET("/long_async", func(c *gin.Context) {
        // create copy to be used inside the goroutine
        c_cp := c.Copy()
        go func() {
            // simulate a long task with time.Sleep(). 5 seconds
            time.Sleep(5 * time.Second)

            // note than you are using the copied context "c_cp", IMPORTANT
            log.Println("Done! in path " + c_cp.Request.URL.Path)
        }()
    })


    r.GET("/long_sync", func(c *gin.Context) {
        // simulate a long task with time.Sleep(). 5 seconds
        time.Sleep(5 * time.Second)

        // since we are NOT using a goroutine, we do not have to copy the context
        log.Println("Done! in path " + c.Request.URL.Path)
    })

    r.Run(":80")
}
```

> - goroute 中请使用只读的Context,用Context.Copy可以返回一个只读的Context

---


> 先写到这，gin的内容一章写完感觉不切实际

> 更多gin的信息可看这<https://gin-gonic.github.io/gin/>

> PS:redcarpet没法识别golang然后就出就用C的高亮了