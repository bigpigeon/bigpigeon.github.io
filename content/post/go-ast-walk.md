+++
Categories = [
  "Develop",
  "Golang",
]
menu = "main"
Description = "go/types中的Type"
Tags = [
  "开发",
  "Go语言",
]
date = "2018-09-23T12:42:00+08:00"
title = "使用go/ast来解析go文件III"
+++



可能很多人想问types中的Type和Object接口有什么区别


我觉得Object可以理解为有实体的Type或者是对Type的定义，Type则是一个Object的抽象


比如type V1 struct {Name string}  和type V2 struct {Name string} V1和V2属于不同Object但它们的Underlying Type是一样的(Type不一样是因为它们是一个Named Type类型) ,不过type不能通过==来比较，必须用Identical


<!--more-->

**下面所有内容在这个[Example](https://github.com/bigpigeon/Test/blob/master/go/blog_go_walk/main.go)中有对应的测试代码**

我们先来看看go/types中所有的Types实现


类型                 | 说明
|-------------------|----------------------
Array               | 固定长度数组类型
Basic               | 基本类型,比如int,string,float等
Chan                | 通道类型，相当于线程安全的slice
Interface           | 接口类型
Map                 | map类型
Named               | 所有用type起名字的自定义类型
Pointer             | 指针类型
Signature           | 所有函数或者method都属于这个类型
Slice               | slice类型
Struct              | 结构体类型，注意:自定义的结构体是named类型，它的Underlying是Struct类型
Tuple               | 函数的参数和返回值

### Array 类型

array类型中包括它的子类型Elem()和数组长度Len() 2个属性

### Basic 类型

basic类型有Kind()和Info()2个属性，Kind是types.BasicKind类型，用来表示所有go的类型，如果import "C"，所有C.type都是Invalid类型


而Info则是types.BasicInfo类型，使用&运算符比较类型，比如types.IsNumeric& x.Info() 可以知道这个类型是否为数字(数字可以是所有int，float,complex类型)

### Chan 类型

chan类型有Dir()和Elem()方法


其中Dir()返回types.ChanDir,它可以是SendRecv,SendOnly,RecvOnly分别表示 发送接收，只发送，只接收 3中channel类型


### 接口类型


接口类型有ExplicitMethod，Embedded，Method 3个方法，分别对应对应获取自己定义的方法，获取嵌套Interface，获取包含嵌套的所有方法


这3个方法有对应的Num方法拿到它们的总数


### map 类型

map类型有Key和Elem方法，分别对应map的key,value类型

### named 类型

named类型就是用户定义的类型，用户定义所有有名字的类型都是named


named类型有个Obj方法，可以返回它对应的types.TypeName，TypeName是一个types.Object接口实现


named 类型也是唯一使用Underlying方法返回的不是自身，可以说Underlying方法就是因为有named类型强加上去的


named也有Method和NumMethods方法，用于查看该named下所定义的方法


结合named和interface的Method可以非常方便的实现Interface实现扫描

### Pointer 类型

Pointer类型有一个Elem方法返回它的子类型

### Signature 类型

所有方法和函数都属于这个类型，一些go的bulit-in函数和伪函数则不是，它们属于Basic类型


Signature有Params和Results方法返回函数的参数和返回值，Params和Results本身则返回一个Tuple类型


Signature还有一个Recv方法，用于返回方法类型的接收者


### Slice类型

Pointer类型有一个Elem方法返回它的成员类型

### Struct类型

struct类型的Field(int)方法返回结构体中第n个字段，而Tag方法则是对应字段的tag信息


Field方法返回的是types.Var类型，它是type.Object接口的实现


### Tuple类型

Tuple只会出现在Signature的参数和返回值中


它有At(int)返回第n个字段的信息，该信息是types.Var类型，它是type.Object接口的实现


Len方法则返回总字段数



### 比对Type类型

使用types.Identical函数可以比对2个type类型，返回bool值,比对的具体逻辑可以看下面的例子


```

var idName1 struct {
	ID   int
	Name string
}

var idName2 struct {
	ID   int
	Name string
}

var idName3 struct {
	ID   int
	Name []byte
}

type IDName struct {
	ID   int
	Name string
}

var idName4 IDName

```

其中idName1和idName2是相同的类型，和idName3不同类型


idName1和idName4也是不同类型，idName4属于Named type，所以比如和idName1不相等


### 实现扫描

使用types.Implements(T,I)可以判断T类型是否实现了接口I


比如下面的Response就实现了Stringer接口，Implements比如返回true

```golang
type Stringer interface {
	String() string
}

// named 类型包含它的method信息
type Response struct {
	Name  string
	Value string
	Buff  bytes.Buffer
}

func (r Response) String() string {
	return r.Name + " " + r.Value
}

func (r *Response) Write(w io.Writer) {
	r.Buff.WriteTo(w)
}
```

types.Implements也可以对接口与接口之间的扫描，下面的WriteStringer也实现了Stringer

```golang
type Stringer interface {
	String() string
}

type WriteStringer interface {
	String() string
	Writer(writer io.Writer)
}

```

types.AssertableTo(I,T)则是判断T类型能否分配成I接口,可以理解为接口版的types.AssignableTo


伪代码:

> types.AssertableTo(WriteStringer, Stringer) => true

> types.AssertableTo(Stringer, Response) => true

> types.AssertableTo(Stringer, WriteStringer) => false

> types.AssertableTo(WriteStringer, Response) => false


### 类型转换判断

types.ConvertibleTo(T1,T2)可以用来判断T1类型能否转成T2类型


通常使用type T2 T1的类型都可以互相转换，还有一些基本类型比如[]byte和string类型，int和int64/int32类型等


### 赋值转换判断

types.AssignableTo(T1,T2)可以判断T1类型是否可以赋给T2类型


赋值转换和类型转换不同，它是一种软转换，也就是不需要带声明


在go里面所有类型都是强类型，每个对象都有明确的类型标识，而软转换的条件就是不允许转换后的类型信息丢失


所以只有3种情况可以接受转换：

- 同类型的转换

- 普通类型转接口类型或接口类型直接的转换，因为接口类型会携带源类型的信息，所以不算做信息丢失

- 由一个untype类型转成符合条件的type类型比如42转int64,32.0转float64，"abc"转string类型


使用伪代码举几个例子

```golang

var strType string
var interfaceType interface{}

var int64Type int = 24

const unintType = 42

```

> types.AssignableTo(strType, interfaceType) => true

> types.AssignableTo(24, int64Type) => true

> types.AssignableTo(unintType, int64Type) => false // 这个不知道是不是bug,理应能转的


### 末尾

types.Type的所有内容基本都介绍齐了，如有遗漏就遗漏了


我也许还会出一篇关于types.Object介绍，也可能直接出一篇关于ast应用实践的博客，写ast实在是太累的，下期见









