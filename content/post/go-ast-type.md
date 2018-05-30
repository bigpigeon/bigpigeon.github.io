+++
Categories = [
  "Develop",
  "Golang",
]
menu = "main"
Description = "使用go/ast来解析go文件II"
Tags = [
  "开发",
  "Go语言",
]
date = "2018-05-23T10:07:00+08:00"
title = "使用go/ast来解析go文件II"
+++

在进行go文件解析经常需要对Ident对象的类型/值进行比较


但go/ast只对单文件进行解析，并不适合用来比较类型，所以这个时候就需要用到另一个库go/types


先来看看全部代码


代码也可以通过[这里](https://github.com/bigpigeon/Test/tree/master/go/blog_go_types)下载，建议在看教程的同时运行这个demo代码

<!--more-->

<details>
<summary>
这是被分析的文件,在data/src.go中
</summary>
```golang
package main

// implicitly import
import "fmt"

import . "unsafe"

type Product struct {
	Name string
}

func (p Product) String() string {
	return "Product:" + p.Name
}

func ImplicitlyNode() {
	var d interface{} = 5
	switch x := d.(type) {
	case int:
		fmt.Println(x)
	default:
		fmt.Println(x)
	}
	var e func(int)
	fmt.Println(e)
}

func SelectionNode() {
	p := Product{Name: "t011"}
	fmt.Println(p.Name)
	fmt.Println(p.String())
	fmt.Println(Product.String(p))
	fmt.Println(Offsetof(p.Name))
}

const MaxRoutines = 100

var CurrentRoutines = 1

func main() { //test1
	fmt.Println("Hello, World!") //test2
	a := []int{1, 2, 3}
	fmt.Println(a)
	b := map[int]string{
		1: "a",
		2: "b",
	}
	fmt.Println(b)

	d := make(chan int, 5)
	fmt.Println(d)

	fmt.Println(MaxRoutines)

}
```
</details>

<details>
<summary>
使用types分析库并打印其中各种信息
</summary>
```golang
package main

import (
	"fmt"
	"go/ast"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"reflect"
	"sort"
)

// 排序规则order by Pos(), End()
func sortNodes(nodes []ast.Node) {
	sort.Slice(nodes, func(i, j int) bool {
		if nodes[i].Pos() == nodes[j].Pos() {
			return nodes[i].End() < nodes[j].End()
		}
		return nodes[i].Pos() < nodes[j].Pos()
	})
}

// map中的元素是无序的，对key排序打印更好查看
func getSortedKeys(m interface{}) []ast.Node {
	mValue := reflect.ValueOf(m)
	nodes := make([]ast.Node, mValue.Len())
	keys := mValue.MapKeys()
	for i := range keys {
		nodes[i] = keys[i].Interface().(ast.Node)
	}
	sortNodes(nodes)
	return nodes
}

func main() {
	fset := token.NewFileSet() // 位置是相对于节点
	// 用ParseFile把文件解析成*ast.File节点
	f, err := parser.ParseFile(fset, "data/src.go", nil, 0)
	if err != nil {
		panic(err)
	}

	// 使用types check
	// 构造config
	config := types.Config{
		// 加载包的方式，可以通过源码或编译好的包，其中编译好的包分为gc和gccgo,前者应该是
		Importer: importer.For("source", nil),
		// 表示允许包里面加载c库 import "c"
		FakeImportC: true,
	}

	info := &types.Info{
		// 表达式对应的类型
		Types: make(map[ast.Expr]types.TypeAndValue),
		// 被定义的标示符
		Defs: make(map[*ast.Ident]types.Object),
		// 被使用的标示符
		Uses: make(map[*ast.Ident]types.Object),
		// 隐藏节点，匿名import包，type-specific时的case对应的当前类型，声明函数的匿名参数如var func(int)
		Implicits: make(map[ast.Node]types.Object),
		// 选择器,只能针对类型/对象.字段/method的选择，package.API这种不会记录在这里
		Selections: make(map[*ast.SelectorExpr]*types.Selection),
		// scope 记录当前库scope下的所有域，*ast.File/*ast.FuncType/... 都属于scope，详情看Scopes说明
		// scope关系: 最外层Universe scope,之后Package scope，其他子scope
		Scopes: make(map[ast.Node]*types.Scope),
		// 记录所有package级的初始化值
		InitOrder: make([]*types.Initializer, 0, 0),
	}
	// 这里第一个path参数觉得当前pkg前缀，和FileSet的文件路径是无关的
	pkg, err := config.Check("", fset, []*ast.File{f}, info)

	if err != nil {
		panic(err)
	}
	// 打印types
	fmt.Println("------------ types -----------")
	for _, node := range getSortedKeys(info.Types) {
		expr := node.(ast.Expr)
		typeValue := info.Types[expr]
		fmt.Printf("%s - %s %T it's value: %v type: %s\n",
			fset.Position(expr.Pos()),
			fset.Position(expr.End()),
			expr,
			typeValue.Value,
			typeValue.Type.String(),
		)
		if typeValue.Assignable() {
			fmt.Print("assignable ")
		}
		if typeValue.Addressable() {
			fmt.Print("addressable ")
		}
		if typeValue.IsNil() {
			fmt.Print("nil ")
		}
		if typeValue.HasOk() {
			fmt.Print("has ok ")
		}
		if typeValue.IsBuiltin() {
			fmt.Print("builtin ")
		}
		if typeValue.IsType() {
			fmt.Print("is type ")
		}
		if typeValue.IsValue() {
			fmt.Print("is value ")
		}
		if typeValue.IsVoid() {
			fmt.Print("void ")
		}
		fmt.Println()
	}
	// 打印defs
	fmt.Println("------------ def -----------")
	for _, node := range getSortedKeys(info.Defs) {
		ident := node.(*ast.Ident)
		object := info.Defs[ident]
		fmt.Printf("%s - %s %T",
			fset.Position(ident.Pos()),
			fset.Position(ident.End()),
			object,
		)
		if object != nil {
			fmt.Printf(" it's object: %s type: %s",
				object,
				object.Type().String(),
			)

		}
		fmt.Println()
	}
	// 打印Uses
	fmt.Println("------------ uses -----------")
	for _, node := range getSortedKeys(info.Uses) {
		ident := node.(*ast.Ident)
		object := info.Uses[ident]
		fmt.Printf("%s - %s %T",
			fset.Position(ident.Pos()),
			fset.Position(ident.End()),
			object,
		)
		if object != nil {
			fmt.Printf(" it's object: %s type: %s",
				object,
				object.Type().String(),
			)

		}
		fmt.Println()
	}
	// 打印Implicits
	fmt.Println("------------ implicits -----------")
	for _, node := range getSortedKeys(info.Implicits) {
		object := info.Implicits[node]
		fmt.Printf("%s - %s %T it's object: %s\n",
			fset.Position(node.Pos()),
			fset.Position(node.End()),
			node,
			object,
		)
	}
	// 打印Selections
	fmt.Println("------------ selections -----------")
	for _, node := range getSortedKeys(info.Selections) {
		sel := node.(*ast.SelectorExpr)
		typeSel := info.Selections[sel]
		fmt.Printf("%s - %s it's selection: %s\n",
			fset.Position(sel.Pos()),
			fset.Position(sel.End()),
			typeSel.String(),
		)
		fmt.Printf("receive: %s index: %v obj: %s\n", typeSel.Recv(), typeSel.Index(), typeSel.Obj())
	}
	// 打印Scopes
	fmt.Println("------------ scopes -----------")
	//打印package scope
	fmt.Printf("package level scope %s\n",
		pkg.Scope().String(),
	)
	// 打印宇宙级scope
	fmt.Printf("universe level scope %s\n",
		pkg.Scope().Parent().String(),
	)
	for _, node := range getSortedKeys(info.Scopes) {
		scope := info.Scopes[node]
		fmt.Printf("%s - %s %T it's scope %s\n",
			fset.Position(node.Pos()),
			fset.Position(node.End()),
			node,
			scope.String(),
		)
	}
	// 打印InitOrder
	fmt.Println("------------ init -----------")
	for _, init := range info.InitOrder {
		fmt.Printf("init %s\n",
			init.String(),
		)
	}
}

```
</details>


#### 构建types.Config

types.Config决定如何去解析go代码，这里**importer.For("source", nil)**表示通过源码的方式解析go库,FakeImportC表示允许加载C库


#### 创建types.Info

types.Info决定要解析哪些信息，给字段赋值后在Config.Check是会对这部分信息进行解析

	Types保存表达式对应的类型，
	Defs保存所有被定义的标示符，包括package name（包名）和带名字的加载库(import _ "package" / import . "package")
	Uses保存所有被使用的标示符
	Implicits保存三种隐藏节点,匿名import 的库(import "package"), type-specific时的case对应类型（switch t := x.(type){case int:}中case节点映射的t类型)
	Selections保存所有类选择器,只能针对类型/对象.字段/method的选择，package.API这种不会记录在这里
	Scopes保存当前库scope下的所有域，*ast.File/*ast.FuncType/... 都属于scope,最外层Universe scope,之后Package scope，其他子scope
	InitOrder保存所有最外部初始化的值

#### config.Check

使用config.Check会填充types.Info的内容


这里第一个path参数决定当前pkg前缀，和FileSet的文件路径是无关的，[]\*ast.File{f}是要解析的go文件，这些go文件必须是同一个pkg的文件

    pkg, err := config.Check("", fset, []*ast.File{f}, info)

pkg包含顶级scope和包名信息，err则是解析文件的语法错误


config.Check过后我们就可以通过types.Info来读取go文件信息了


#### types.Info.Types

types.Info.Types 映射ast.Expr(不包括在types.Info.Defs和types.Info.Users中的\*ast.Ident)到types.TypeAndValue类型


types.TypeAndValue解析expr的类型和它的额外属性，如果expr是一个常量值，TypeAndValue也会解析它的Value


我们来打印一下types.Info.Types的内容

```golang
fmt.Println("------------ types -----------")
for _, node := range getSortedKeys(info.Types) {
	expr := node.(ast.Expr)
	typeValue := info.Types[expr]
	fmt.Printf("%s - %s %T it's value: %v type: %s\n",
		fset.Position(expr.Pos()),
		fset.Position(expr.End()),
		expr,
		typeValue.Value,
		typeValue.Type.String(),
	)
	if typeValue.Assignable() {
		fmt.Print("assignable ")
	}
	if typeValue.Addressable() {
		fmt.Print("addressable ")
	}
	if typeValue.IsNil() {
		fmt.Print("nil ")
	}
	if typeValue.HasOk() {
		fmt.Print("has ok ")
	}
	if typeValue.IsBuiltin() {
		fmt.Print("builtin ")
	}
	if typeValue.IsType() {
		fmt.Print("is type ")
	}
	if typeValue.IsValue() {
		fmt.Print("is value ")
	}
	if typeValue.IsVoid() {
		fmt.Print("void ")
	}
	fmt.Println()
}
```

<details>
<summary>
打印日志
</summary>
```log
------------ types -----------
data/src.go:7:14 - data/src.go:9:2 *ast.StructType it's value: <nil> type: struct{Name string}
is type 
data/src.go:8:7 - data/src.go:8:13 *ast.Ident it's value: <nil> type: string
is type 
data/src.go:11:9 - data/src.go:11:16 *ast.Ident it's value: <nil> type: Product
is type 
data/src.go:11:27 - data/src.go:11:33 *ast.Ident it's value: <nil> type: string
is type 
data/src.go:12:9 - data/src.go:12:19 *ast.BasicLit it's value: "Product:" type: string
is value 
data/src.go:12:9 - data/src.go:12:28 *ast.BinaryExpr it's value: <nil> type: string
is value 
data/src.go:12:22 - data/src.go:12:23 *ast.Ident it's value: <nil> type: Product
assignable addressable is value 
data/src.go:12:22 - data/src.go:12:28 *ast.SelectorExpr it's value: <nil> type: string
assignable addressable is value 
data/src.go:16:8 - data/src.go:16:19 *ast.InterfaceType it's value: <nil> type: interface{}
is type 
data/src.go:16:22 - data/src.go:16:23 *ast.BasicLit it's value: 5 type: int
is value 
data/src.go:17:14 - data/src.go:17:15 *ast.Ident it's value: <nil> type: interface{}
assignable addressable is value 
data/src.go:18:7 - data/src.go:18:10 *ast.Ident it's value: <nil> type: int
is type 
data/src.go:19:3 - data/src.go:19:14 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:19:3 - data/src.go:19:17 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:19:15 - data/src.go:19:16 *ast.Ident it's value: <nil> type: int
assignable addressable is value 
data/src.go:21:3 - data/src.go:21:14 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:21:3 - data/src.go:21:17 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:21:15 - data/src.go:21:16 *ast.Ident it's value: <nil> type: interface{}
assignable addressable is value 
data/src.go:23:8 - data/src.go:23:17 *ast.FuncType it's value: <nil> type: func(int)
is type 
data/src.go:23:13 - data/src.go:23:16 *ast.Ident it's value: <nil> type: int
is type 
data/src.go:24:2 - data/src.go:24:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:24:2 - data/src.go:24:16 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:24:14 - data/src.go:24:15 *ast.Ident it's value: <nil> type: func(int)
assignable addressable is value 
data/src.go:28:7 - data/src.go:28:14 *ast.Ident it's value: <nil> type: Product
is type 
data/src.go:28:7 - data/src.go:28:28 *ast.CompositeLit it's value: <nil> type: Product
is value 
data/src.go:28:21 - data/src.go:28:27 *ast.BasicLit it's value: "t011" type: string
is value 
data/src.go:29:2 - data/src.go:29:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:29:2 - data/src.go:29:21 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:29:14 - data/src.go:29:15 *ast.Ident it's value: <nil> type: Product
assignable addressable is value 
data/src.go:29:14 - data/src.go:29:20 *ast.SelectorExpr it's value: <nil> type: string
assignable addressable is value 
data/src.go:30:2 - data/src.go:30:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:30:2 - data/src.go:30:25 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:30:14 - data/src.go:30:15 *ast.Ident it's value: <nil> type: Product
assignable addressable is value 
data/src.go:30:14 - data/src.go:30:22 *ast.SelectorExpr it's value: <nil> type: func() string
is value 
data/src.go:30:14 - data/src.go:30:24 *ast.CallExpr it's value: <nil> type: string
is value 
data/src.go:31:2 - data/src.go:31:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:31:2 - data/src.go:31:32 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:31:14 - data/src.go:31:21 *ast.Ident it's value: <nil> type: Product
is type 
data/src.go:31:14 - data/src.go:31:28 *ast.SelectorExpr it's value: <nil> type: func(Product) string
is value 
data/src.go:31:14 - data/src.go:31:31 *ast.CallExpr it's value: <nil> type: string
is value 
data/src.go:31:29 - data/src.go:31:30 *ast.Ident it's value: <nil> type: Product
assignable addressable is value 
data/src.go:32:2 - data/src.go:32:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:32:2 - data/src.go:32:31 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:32:14 - data/src.go:32:22 *ast.Ident it's value: <nil> type: invalid type
builtin 
data/src.go:32:14 - data/src.go:32:30 *ast.CallExpr it's value: 0 type: uintptr
is value 
data/src.go:32:23 - data/src.go:32:24 *ast.Ident it's value: <nil> type: Product
assignable addressable is value 
data/src.go:35:21 - data/src.go:35:24 *ast.BasicLit it's value: 100 type: untyped int
is value 
data/src.go:37:23 - data/src.go:37:24 *ast.BasicLit it's value: 1 type: int
is value 
data/src.go:40:2 - data/src.go:40:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:40:2 - data/src.go:40:30 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:40:14 - data/src.go:40:29 *ast.BasicLit it's value: "Hello, World!" type: string
is value 
data/src.go:41:7 - data/src.go:41:12 *ast.ArrayType it's value: <nil> type: []int
is type 
data/src.go:41:7 - data/src.go:41:21 *ast.CompositeLit it's value: <nil> type: []int
is value 
data/src.go:41:9 - data/src.go:41:12 *ast.Ident it's value: <nil> type: int
is type 
data/src.go:41:13 - data/src.go:41:14 *ast.BasicLit it's value: 1 type: int
is value 
data/src.go:41:16 - data/src.go:41:17 *ast.BasicLit it's value: 2 type: int
is value 
data/src.go:41:19 - data/src.go:41:20 *ast.BasicLit it's value: 3 type: int
is value 
data/src.go:42:2 - data/src.go:42:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:42:2 - data/src.go:42:16 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:42:14 - data/src.go:42:15 *ast.Ident it's value: <nil> type: []int
assignable addressable is value 
data/src.go:43:7 - data/src.go:43:21 *ast.MapType it's value: <nil> type: map[int]string
is type 
data/src.go:43:7 - data/src.go:46:3 *ast.CompositeLit it's value: <nil> type: map[int]string
is value 
data/src.go:43:11 - data/src.go:43:14 *ast.Ident it's value: <nil> type: int
is type 
data/src.go:43:15 - data/src.go:43:21 *ast.Ident it's value: <nil> type: string
is type 
data/src.go:44:3 - data/src.go:44:4 *ast.BasicLit it's value: 1 type: int
is value 
data/src.go:44:6 - data/src.go:44:9 *ast.BasicLit it's value: "a" type: string
is value 
data/src.go:45:3 - data/src.go:45:4 *ast.BasicLit it's value: 2 type: int
is value 
data/src.go:45:6 - data/src.go:45:9 *ast.BasicLit it's value: "b" type: string
is value 
data/src.go:47:2 - data/src.go:47:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:47:2 - data/src.go:47:16 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:47:14 - data/src.go:47:15 *ast.Ident it's value: <nil> type: map[int]string
assignable addressable is value 
data/src.go:49:7 - data/src.go:49:11 *ast.Ident it's value: <nil> type: func(chan int, int) chan int
builtin 
data/src.go:49:7 - data/src.go:49:24 *ast.CallExpr it's value: <nil> type: chan int
is value 
data/src.go:49:12 - data/src.go:49:20 *ast.ChanType it's value: <nil> type: chan int
is type 
data/src.go:49:17 - data/src.go:49:20 *ast.Ident it's value: <nil> type: int
is type 
data/src.go:49:22 - data/src.go:49:23 *ast.BasicLit it's value: 5 type: int
is value 
data/src.go:50:2 - data/src.go:50:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:50:2 - data/src.go:50:16 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:50:14 - data/src.go:50:15 *ast.Ident it's value: <nil> type: chan int
assignable addressable is value 
data/src.go:52:2 - data/src.go:52:13 *ast.SelectorExpr it's value: <nil> type: func(a ...interface{}) (n int, err error)
is value 
data/src.go:52:2 - data/src.go:52:26 *ast.CallExpr it's value: <nil> type: (n int, err error)
is value 
data/src.go:52:14 - data/src.go:52:25 *ast.Ident it's value: 100 type: int
is value 
```
</details>


#### types.Info.Defs

Defs保存所有定义的\*ast.Ident，并映射为types.Object


types.Object可以是一个包名，函数，常量，变量,或者标签的接口


当前包的package name也保存在Defs表中，不过它的Object是nil，不知道是不是bug


打印一下Defs的内容

```golang
fmt.Println("------------ def -----------")
for _, node := range getSortedKeys(info.Defs) {
	ident := node.(*ast.Ident)
	object := info.Defs[ident]
	fmt.Printf("%s - %s %T",
		fset.Position(ident.Pos()),
		fset.Position(ident.End()),
		object,
	)
	if object != nil {
		fmt.Printf(" it's object: %s type: %s",
			object,
			object.Type().String(),
		)

	}
	fmt.Println()
}
```


<details>
<summary>
打印日志
</summary>
```log
------------ def -----------
data/src.go:1:9 - data/src.go:1:13 <nil>
data/src.go:5:8 - data/src.go:5:9 *types.PkgName it's object: package . ("unsafe") type: invalid type
data/src.go:7:6 - data/src.go:7:13 *types.TypeName it's object: type Product struct{Name string} type: Product
data/src.go:8:2 - data/src.go:8:6 *types.Var it's object: field Name string type: string
data/src.go:11:7 - data/src.go:11:8 *types.Var it's object: var p Product type: Product
data/src.go:11:18 - data/src.go:11:24 *types.Func it's object: func (Product).String() string type: func() string
data/src.go:15:6 - data/src.go:15:20 *types.Func it's object: func ImplicitlyNode() type: func()
data/src.go:16:6 - data/src.go:16:7 *types.Var it's object: var d interface{} type: interface{}
data/src.go:17:9 - data/src.go:17:10 <nil>
data/src.go:23:6 - data/src.go:23:7 *types.Var it's object: var e func(int) type: func(int)
data/src.go:27:6 - data/src.go:27:19 *types.Func it's object: func SelectionNode() type: func()
data/src.go:28:2 - data/src.go:28:3 *types.Var it's object: var p Product type: Product
data/src.go:35:7 - data/src.go:35:18 *types.Const it's object: const MaxRoutines untyped int type: untyped int
data/src.go:37:5 - data/src.go:37:20 *types.Var it's object: var CurrentRoutines int type: int
data/src.go:39:6 - data/src.go:39:10 *types.Func it's object: func main() type: func()
data/src.go:41:2 - data/src.go:41:3 *types.Var it's object: var a []int type: []int
data/src.go:43:2 - data/src.go:43:3 *types.Var it's object: var b map[int]string type: map[int]string
data/src.go:49:2 - data/src.go:49:3 *types.Var it's object: var d chan int type: chan int
```
</details>

#### types.Info.Uses

Uses保存所有使用的\*ast.Ident，并映射为types.Object


基本在Uses中的Ident也会出现在Types里，这部分逻辑很迷


打印Uses


```golang
fmt.Println("------------ uses -----------")
for _, node := range getSortedKeys(info.Uses) {
	ident := node.(*ast.Ident)
	object := info.Uses[ident]
	fmt.Printf("%s - %s %T",
		fset.Position(ident.Pos()),
		fset.Position(ident.End()),
		object,
	)
	if object != nil {
		fmt.Printf(" it's object: %s type: %s",
			object,
			object.Type().String(),
		)

	}
	fmt.Println()
}
```


<details>
<summary>
打印日志
</summary>
```log
------------ uses -----------
data/src.go:8:7 - data/src.go:8:13 *types.TypeName it's object: type string type: string
data/src.go:11:9 - data/src.go:11:16 *types.TypeName it's object: type Product struct{Name string} type: Product
data/src.go:11:27 - data/src.go:11:33 *types.TypeName it's object: type string type: string
data/src.go:12:22 - data/src.go:12:23 *types.Var it's object: var p Product type: Product
data/src.go:12:24 - data/src.go:12:28 *types.Var it's object: field Name string type: string
data/src.go:17:14 - data/src.go:17:15 *types.Var it's object: var d interface{} type: interface{}
data/src.go:18:7 - data/src.go:18:10 *types.TypeName it's object: type int type: int
data/src.go:19:3 - data/src.go:19:6 *types.PkgName it's object: package fmt type: invalid type
data/src.go:19:7 - data/src.go:19:14 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:19:15 - data/src.go:19:16 *types.Var it's object: var x int type: int
data/src.go:21:3 - data/src.go:21:6 *types.PkgName it's object: package fmt type: invalid type
data/src.go:21:7 - data/src.go:21:14 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:21:15 - data/src.go:21:16 *types.Var it's object: var x interface{} type: interface{}
data/src.go:23:13 - data/src.go:23:16 *types.TypeName it's object: type int type: int
data/src.go:24:2 - data/src.go:24:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:24:6 - data/src.go:24:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:24:14 - data/src.go:24:15 *types.Var it's object: var e func(int) type: func(int)
data/src.go:28:7 - data/src.go:28:14 *types.TypeName it's object: type Product struct{Name string} type: Product
data/src.go:28:15 - data/src.go:28:19 *types.Var it's object: field Name string type: string
data/src.go:29:2 - data/src.go:29:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:29:6 - data/src.go:29:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:29:14 - data/src.go:29:15 *types.Var it's object: var p Product type: Product
data/src.go:29:16 - data/src.go:29:20 *types.Var it's object: field Name string type: string
data/src.go:30:2 - data/src.go:30:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:30:6 - data/src.go:30:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:30:14 - data/src.go:30:15 *types.Var it's object: var p Product type: Product
data/src.go:30:16 - data/src.go:30:22 *types.Func it's object: func (Product).String() string type: func() string
data/src.go:31:2 - data/src.go:31:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:31:6 - data/src.go:31:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:31:14 - data/src.go:31:21 *types.TypeName it's object: type Product struct{Name string} type: Product
data/src.go:31:22 - data/src.go:31:28 *types.Func it's object: func (Product).String() string type: func() string
data/src.go:31:29 - data/src.go:31:30 *types.Var it's object: var p Product type: Product
data/src.go:32:2 - data/src.go:32:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:32:6 - data/src.go:32:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:32:14 - data/src.go:32:22 *types.Builtin it's object: builtin unsafe.Offsetof type: invalid type
data/src.go:32:23 - data/src.go:32:24 *types.Var it's object: var p Product type: Product
data/src.go:32:25 - data/src.go:32:29 *types.Var it's object: field Name string type: string
data/src.go:40:2 - data/src.go:40:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:40:6 - data/src.go:40:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:41:9 - data/src.go:41:12 *types.TypeName it's object: type int type: int
data/src.go:42:2 - data/src.go:42:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:42:6 - data/src.go:42:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:42:14 - data/src.go:42:15 *types.Var it's object: var a []int type: []int
data/src.go:43:11 - data/src.go:43:14 *types.TypeName it's object: type int type: int
data/src.go:43:15 - data/src.go:43:21 *types.TypeName it's object: type string type: string
data/src.go:47:2 - data/src.go:47:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:47:6 - data/src.go:47:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:47:14 - data/src.go:47:15 *types.Var it's object: var b map[int]string type: map[int]string
data/src.go:49:7 - data/src.go:49:11 *types.Builtin it's object: builtin make type: invalid type
data/src.go:49:17 - data/src.go:49:20 *types.TypeName it's object: type int type: int
data/src.go:50:2 - data/src.go:50:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:50:6 - data/src.go:50:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:50:14 - data/src.go:50:15 *types.Var it's object: var d chan int type: chan int
data/src.go:52:2 - data/src.go:52:5 *types.PkgName it's object: package fmt type: invalid type
data/src.go:52:6 - data/src.go:52:13 *types.Func it's object: func fmt.Println(a ...interface{}) (n int, err error) type: func(a ...interface{}) (n int, err error)
data/src.go:52:14 - data/src.go:52:25 *types.Const it's object: const MaxRoutines untyped int type: untyped int
```
</details>


#### types.Info.Implicits

Implicits保存各种隐藏声明的节点,以下节点可能出现在Implicits表中


没有包名的import


type-specific的swtich语句


声明函数时的匿名参数


这个example已经把实现了所有隐藏声明代码，来看看哪些节点会出现在这里

```golang
fmt.Println("------------ implicits -----------")
for _, node := range getSortedKeys(info.Implicits) {
	object := info.Implicits[node]
	fmt.Printf("%s - %s %T it's object: %s\n",
		fset.Position(node.Pos()),
		fset.Position(node.End()),
		node,
		object,
	)
}
```

<details>
<summary>
打印日志
</summary>
```log
------------ implicits -----------
data/src.go:4:8 - data/src.go:4:13 *ast.ImportSpec it's object: package fmt
data/src.go:11:27 - data/src.go:11:33 *ast.Field it's object: var  string
data/src.go:18:2 - data/src.go:19:17 *ast.CaseClause it's object: var x int
data/src.go:20:2 - data/src.go:21:17 *ast.CaseClause it's object: var x interface{}
data/src.go:23:13 - data/src.go:23:16 *ast.Field it's object: var  int
```
</details>


#### types.Info.Selections

Selections保存所有结构体选择表达式像 x.f，它会把\*ast.SelectorExpr映射成\*types.Selection，只有类成员的使用表达式会被映射，库成员的使用则不会


types.Selection有3中类型，对应3种调用方式(这里参考了types源码)

```golang
//	type T struct{ x int; E }
//	type E struct{}
//	func (e E) m() {}
//	var p *T
//
// the following relations exist:
//
//	Selector    Kind          Recv    Obj    Type               Index     Indirect
//
//	p.x         FieldVal      T       x      int                {0}       true
//	p.m         MethodVal     *T      m      func (e *T) m()    {1, 0}    true
//	T.m         MethodExpr    T       m      func m(_ T)        {1, 0}    false
//
```

```golang
fmt.Println("------------ selections -----------")
for _, node := range getSortedKeys(info.Selections) {
	sel := node.(*ast.SelectorExpr)
	typeSel := info.Selections[sel]
	fmt.Printf("%s - %s it's selection: %s\n",
		fset.Position(sel.Pos()),
		fset.Position(sel.End()),
		typeSel.String(),
	)
	fmt.Printf("receive: %s index: %v obj: %s\n", typeSel.Recv(), typeSel.Index(), typeSel.Obj())
}
```

<details>
<summary>
打印日志
</summary>
```log
------------ selections -----------
data/src.go:13:22 - data/src.go:13:28 it's selection: field (Product) Name string
receive: Product index: [0] obj: field Name string
data/src.go:30:14 - data/src.go:30:20 it's selection: field (Product) Name string
receive: Product index: [0] obj: field Name string
data/src.go:31:14 - data/src.go:31:22 it's selection: method (Product) String() string
receive: Product index: [0] obj: func (Product).String() string
data/src.go:32:14 - data/src.go:32:28 it's selection: method expr (Product) String(p Product) string
receive: Product index: [0] obj: func (Product).String() string
data/src.go:33:23 - data/src.go:33:29 it's selection: field (Product) Name string
receive: Product index: [0] obj: field Name string
```
</details>


#### types.Info.Scope


scope 记录当前库scope下的所有域，*ast.File/*ast.FuncType/... 都属于scope，详情看Scopes说明


scope关系: 最外层Universe scope,之后Package scope，其他子scope


打印Universe scope的内容和Package scope的内容

```golang
// 打印宇宙级scope
//打印package scope
fmt.Printf("package level scope %s\n",
	pkg.Scope().String(),
)
// 打印宇宙级scope
fmt.Printf("universe level scope %s\n",
	pkg.Scope().Parent().String(),
)
```

<details>
<summary>
打印日志
</summary>
```log
package level scope package "" scope 0xc42009dbd0 {
.  var CurrentRoutines int
.  func ImplicitlyNode()
.  const MaxRoutines untyped int
.  type Product struct{Name string}
.  func SelectionNode()
.  func main()
}
universe level scope universe scope 0xc42009c320 {
.  builtin append
.  type bool
.  type byte
.  builtin cap
.  builtin close
.  builtin complex
.  type complex128
.  type complex64
.  builtin copy
.  builtin delete
.  type error interface{Error() string}
.  const false untyped bool
.  type float32
.  type float64
.  builtin imag
.  type int
.  type int16
.  type int32
.  type int64
.  type int8
.  const iota untyped int
.  builtin len
.  builtin make
.  builtin new
.  nil
.  builtin panic
.  builtin print
.  builtin println
.  builtin real
.  builtin recover
.  type rune
.  type string
.  const true untyped bool
.  type uint
.  type uint16
.  type uint32
.  type uint64
.  type uint8
.  type uintptr
}
```
</details>

打印所有scope(types.Info.Scope不会包含Package scope和Universe scope)


```golang
for _, node := range getSortedKeys(info.Scopes) {
	scope := info.Scopes[node]
	fmt.Printf("%s - %s %T it's scope: %s\n",
		fset.Position(node.Pos()),
		fset.Position(node.End()),
		node,
		scope.String(),
	)
}
```

<details>
<summary>
打印日志
</summary>
```log
data/src.go:12:1 - data/src.go:12:33 *ast.FuncType it's scope: function scope 0xc421388ff0 {
.  var p Product
}
data/src.go:16:1 - data/src.go:16:22 *ast.FuncType it's scope: function scope 0xc4213890e0 {
.  var d interface{}
.  var e func(int)
}
data/src.go:18:2 - data/src.go:23:3 *ast.TypeSwitchStmt it's scope: type switch scope 0xc421389310 {}

data/src.go:19:2 - data/src.go:20:17 *ast.CaseClause it's scope: case scope 0xc421389360 {
.  var x int
}
data/src.go:21:2 - data/src.go:22:17 *ast.CaseClause it's scope: case scope 0xc421389400 {
.  var x interface{}
}
data/src.go:24:8 - data/src.go:24:17 *ast.FuncType it's scope: function scope 0xc4213894f0 {}

data/src.go:28:1 - data/src.go:28:21 *ast.FuncType it's scope: function scope 0xc421389180 {
.  var p Product
}
data/src.go:40:1 - data/src.go:40:12 *ast.FuncType it's scope: function scope 0xc4213891d0 {
.  var a []int
.  var b map[int]string
.  var d chan int
}
```
</details>


#### types.Info.InitOrder

InitOrder保存当前库最外层的变量


打印当前所有InitOrder内容

```golang
fmt.Println("------------ init -----------")
for _, init := range info.InitOrder {
	fmt.Printf("init %s\n",
		init.String(),
	)
}
```


<details>
<summary>
打印日志
</summary>
```log
init CurrentRoutines = 1
```
</details>

#### types.Object比较

可以使用Object.Pos()模块查找这个Object的声明时的位置，从而比较哪些Object属于同一个对象

#### types.Type比较

可以通过Type.String()来比较这2个Type是不是相同的类型

#### 总结

以上就是就是go/types的全部内容了，下一章继续介绍go/types中实现的Type类型
