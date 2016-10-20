+++
Description = ""
Tags = [
  "Development",
  "Golang",
]
Categories = [
  "开发",
]
menu = "main"
date = "2015-12-24T06:25:00+08:00"
title = "gin框架介绍"
+++
### 为何用gin

它是一个轻量级框架，框架简单而且速度很快，它的功能用来做rust api开发已经足够


而因为它的简单我们也能很好的在它上面增加功能或再开发

<!--more-->
### gin的特性
支持中间层

    一个请求过来经过 global middleware,group middleware 最后到该path的middleware处理
    我们可以把处理函数放入global/middleware/group middleware的中

基于Radix tree

灾难恢复

    处理请求崩溃后会在Recover函数中恢复然后返回500

更多特性请看[官网](https://gin-gonic.github.io/gin/)


### 基本用法


``` go
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

``` go
func Default() *Engine {
	engine := New()
	engine.Use(Recovery(), Logger())
	return engine
}
```

- New()是用默认参数构造一个engine
- engine.Use(...)把Recovery() 和Logger()生成的函数增加值全局handler列
- engine.Use要在所有handle的middleware绑定之前使用，否则某些绑定的path会不生效(在group的middleware之后加是可以的)


#### 然后我们来看看Recovery干了什么

``` go
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

- 关于recover的使用可以看<http://blog.golang.org/defer-panic-and-recover>
- defer的函数会在函数结束后返回前调用
- c.Next()就是调用下一个handler 就和Nodejs中的http库差不多
- 大致流程就是 FuncBody -> c.Next -> defer func (一个灾难恢复就这样简单的实现了)

#### 再然后来看看Logger

``` go
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

- 大致就是输出请求头的数据和处理请求所花费的时间
- 但听说获取系统时间会有阻塞

#### 再来看看r.GET之后发生了什么

``` go
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

- 这里的类是RouterGroup但上面gin.Default()返回的却是是Engine

#### 于是我们看看Engine的定义

``` go
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

- Engine 是继承于RouteGroup的
- 其实可以把Engine当成是RouteGroup节点，Group是可以嵌套的

#### 最后看一下handler函数的Context参数

``` go
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

- 这里只展示了Context的定义和Next函数的实现,[详细看源码](https://github.com/gin-gonic/gin/blob/master/context.go)


- gin的运作原理大概就是这样了,之后讲gin的一些example和[gin的github page](https://github.com/gin-gonic/gin)上的一样

### 包含参数的路径


``` go
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

### Query字符串参数


``` go
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

- 请尝试用如下请求路径来请求:  /welcome?firstname=Jane&lastname=Doe
- 然后查看请求结果

### Model binding and validation

``` go
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



``` go
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

- goroute 中请使用只读的Context,用Context.Copy可以返回一个只读的Context

---


**更多gin的信息可看这<https://gin-gonic.github.io/gin/>**
