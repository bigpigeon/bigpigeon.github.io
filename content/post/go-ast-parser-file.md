+++
Categories = [
  "Develop",
  "Golang",
]

Description = "使用go/ast来解析go文件"
Tags = [
  "开发",
  "Go语言",
]
date = "2018-05-05T10:07:00+08:00"
title = "使用go/ast来解析go文件"
+++

go/ast是go的type checker 标准包之一(不是编译器的那套工具，编译器用的另外一套)，它定义了抽象语法树(AST)的数据类型和操作ast节点的工具


下面我们来看看如何ast树的结构

```golang
package main

import (
	"go/ast"
	"go/parser"
	"go/token"
)

func main() {
	src := `
package main

// 该声明为GenDecl TOK=token.IMPORT
import "fmt"

// 该声明为GenDecl TOK=token.TYPE
type Product struct {
	Name string
}

// 该声明为GenDecl TOK=token.VAR
var product Product

// 该声明为FunDecl
func main() { //test1
	fmt.Println("Hello, World!") //test2
	a := []int{1,2,3}
	a[1],a[2] = 5,6
}
`
	fset := token.NewFileSet() // 位置是相对于节点
	// 用ParseFile把文件解析成*ast.File节点
	f, err := parser.ParseFile(fset, "", src, 0)
	if err != nil {
		panic(err)
	}

	// 打印ast节点
	ast.Print(fset, f)
}

```

<!--more-->

<details>
<summary>
然后我们可以巨量的打印信息
</summary>
```
 0  *ast.File {
 1  .  Package: 2:1
 2  .  Name: *ast.Ident {
 3  .  .  NamePos: 2:9
 4  .  .  Name: "main"
 5  .  }
 6  .  Decls: []ast.Decl (len = 4) {
 7  .  .  0: *ast.GenDecl {
 8  .  .  .  TokPos: 5:1
 9  .  .  .  Tok: import
10  .  .  .  Lparen: -
11  .  .  .  Specs: []ast.Spec (len = 1) {
12  .  .  .  .  0: *ast.ImportSpec {
13  .  .  .  .  .  Path: *ast.BasicLit {
14  .  .  .  .  .  .  ValuePos: 5:8
15  .  .  .  .  .  .  Kind: STRING
16  .  .  .  .  .  .  Value: "\"fmt\""
17  .  .  .  .  .  }
18  .  .  .  .  .  EndPos: -
19  .  .  .  .  }
20  .  .  .  }
21  .  .  .  Rparen: -
22  .  .  }
23  .  .  1: *ast.GenDecl {
24  .  .  .  TokPos: 8:1
25  .  .  .  Tok: type
26  .  .  .  Lparen: -
27  .  .  .  Specs: []ast.Spec (len = 1) {
28  .  .  .  .  0: *ast.TypeSpec {
29  .  .  .  .  .  Name: *ast.Ident {
30  .  .  .  .  .  .  NamePos: 8:6
31  .  .  .  .  .  .  Name: "Product"
32  .  .  .  .  .  .  Obj: *ast.Object {
33  .  .  .  .  .  .  .  Kind: type
34  .  .  .  .  .  .  .  Name: "Product"
35  .  .  .  .  .  .  .  Decl: *(obj @ 28)
36  .  .  .  .  .  .  }
37  .  .  .  .  .  }
38  .  .  .  .  .  Assign: -
39  .  .  .  .  .  Type: *ast.StructType {
40  .  .  .  .  .  .  Struct: 8:14
41  .  .  .  .  .  .  Fields: *ast.FieldList {
42  .  .  .  .  .  .  .  Opening: 8:21
43  .  .  .  .  .  .  .  List: []*ast.Field (len = 1) {
44  .  .  .  .  .  .  .  .  0: *ast.Field {
45  .  .  .  .  .  .  .  .  .  Names: []*ast.Ident (len = 1) {
46  .  .  .  .  .  .  .  .  .  .  0: *ast.Ident {
47  .  .  .  .  .  .  .  .  .  .  .  NamePos: 9:2
48  .  .  .  .  .  .  .  .  .  .  .  Name: "Name"
49  .  .  .  .  .  .  .  .  .  .  .  Obj: *ast.Object {
50  .  .  .  .  .  .  .  .  .  .  .  .  Kind: var
51  .  .  .  .  .  .  .  .  .  .  .  .  Name: "Name"
52  .  .  .  .  .  .  .  .  .  .  .  .  Decl: *(obj @ 44)
53  .  .  .  .  .  .  .  .  .  .  .  }
54  .  .  .  .  .  .  .  .  .  .  }
55  .  .  .  .  .  .  .  .  .  }
56  .  .  .  .  .  .  .  .  .  Type: *ast.Ident {
57  .  .  .  .  .  .  .  .  .  .  NamePos: 9:7
58  .  .  .  .  .  .  .  .  .  .  Name: "string"
59  .  .  .  .  .  .  .  .  .  }
60  .  .  .  .  .  .  .  .  }
61  .  .  .  .  .  .  .  }
62  .  .  .  .  .  .  .  Closing: 10:1
63  .  .  .  .  .  .  }
64  .  .  .  .  .  .  Incomplete: false
65  .  .  .  .  .  }
66  .  .  .  .  }
67  .  .  .  }
68  .  .  .  Rparen: -
69  .  .  }
70  .  .  2: *ast.GenDecl {
71  .  .  .  TokPos: 13:1
72  .  .  .  Tok: var
73  .  .  .  Lparen: -
74  .  .  .  Specs: []ast.Spec (len = 1) {
75  .  .  .  .  0: *ast.ValueSpec {
76  .  .  .  .  .  Names: []*ast.Ident (len = 1) {
77  .  .  .  .  .  .  0: *ast.Ident {
78  .  .  .  .  .  .  .  NamePos: 13:5
79  .  .  .  .  .  .  .  Name: "product"
80  .  .  .  .  .  .  .  Obj: *ast.Object {
81  .  .  .  .  .  .  .  .  Kind: var
82  .  .  .  .  .  .  .  .  Name: "product"
83  .  .  .  .  .  .  .  .  Decl: *(obj @ 75)
84  .  .  .  .  .  .  .  .  Data: 0
85  .  .  .  .  .  .  .  }
86  .  .  .  .  .  .  }
87  .  .  .  .  .  }
88  .  .  .  .  .  Type: *ast.Ident {
89  .  .  .  .  .  .  NamePos: 13:13
90  .  .  .  .  .  .  Name: "Product"
91  .  .  .  .  .  .  Obj: *(obj @ 32)
92  .  .  .  .  .  }
93  .  .  .  .  }
94  .  .  .  }
95  .  .  .  Rparen: -
96  .  .  }
97  .  .  3: *ast.FuncDecl {
98  .  .  .  Name: *ast.Ident {
99  .  .  .  .  NamePos: 16:6
100  .  .  .  .  Name: "main"
101  .  .  .  .  Obj: *ast.Object {
102  .  .  .  .  .  Kind: func
103  .  .  .  .  .  Name: "main"
104  .  .  .  .  .  Decl: *(obj @ 97)
105  .  .  .  .  }
106  .  .  .  }
107  .  .  .  Type: *ast.FuncType {
108  .  .  .  .  Func: 16:1
109  .  .  .  .  Params: *ast.FieldList {
110  .  .  .  .  .  Opening: 16:10
111  .  .  .  .  .  Closing: 16:11
112  .  .  .  .  }
113  .  .  .  }
114  .  .  .  Body: *ast.BlockStmt {
115  .  .  .  .  Lbrace: 16:13
116  .  .  .  .  List: []ast.Stmt (len = 1) {
117  .  .  .  .  .  0: *ast.ExprStmt {
118  .  .  .  .  .  .  X: *ast.CallExpr {
119  .  .  .  .  .  .  .  Fun: *ast.SelectorExpr {
120  .  .  .  .  .  .  .  .  X: *ast.Ident {
121  .  .  .  .  .  .  .  .  .  NamePos: 17:2
122  .  .  .  .  .  .  .  .  .  Name: "fmt"
123  .  .  .  .  .  .  .  .  }
124  .  .  .  .  .  .  .  .  Sel: *ast.Ident {
125  .  .  .  .  .  .  .  .  .  NamePos: 17:6
126  .  .  .  .  .  .  .  .  .  Name: "Println"
127  .  .  .  .  .  .  .  .  }
128  .  .  .  .  .  .  .  }
129  .  .  .  .  .  .  .  Lparen: 17:13
130  .  .  .  .  .  .  .  Args: []ast.Expr (len = 1) {
131  .  .  .  .  .  .  .  .  0: *ast.BasicLit {
132  .  .  .  .  .  .  .  .  .  ValuePos: 17:14
133  .  .  .  .  .  .  .  .  .  Kind: STRING
134  .  .  .  .  .  .  .  .  .  Value: "\"Hello, World!\""
135  .  .  .  .  .  .  .  .  }
136  .  .  .  .  .  .  .  }
137  .  .  .  .  .  .  .  Ellipsis: -
138  .  .  .  .  .  .  .  Rparen: 17:29
139  .  .  .  .  .  .  }
140  .  .  .  .  .  }
141  .  .  .  .  }
142  .  .  .  .  Rbrace: 18:1
143  .  .  .  }
144  .  .  }
145  .  }
146  .  Scope: *ast.Scope {
147  .  .  Objects: map[string]*ast.Object (len = 3) {
148  .  .  .  "Product": *(obj @ 32)
149  .  .  .  "product": *(obj @ 80)
150  .  .  .  "main": *(obj @ 101)
151  .  .  }
152  .  }
153  .  Imports: []*ast.ImportSpec (len = 1) {
154  .  .  0: *(obj @ 12)
155  .  }
156  .  Unresolved: []*ast.Ident (len = 2) {
157  .  .  0: *(obj @ 56)
158  .  .  1: *(obj @ 120)
159  .  }
160  }

```
</details>

从ast树中我们可以看到go/ast的逻辑结构


因为ast的信息繁多且复杂，这里只列举比较重要的几点，有兴趣的可以自行浏览go/ast中的源码


在ast.Files中最重要的部分就是Decls，这里面保存了该文件的全局声明(go中的声明既定义)，而Decl接口中有3种类型

	BadDecl: 有语法错误的声明
	GenDecl: 通用声明，import/type/const/var都属于这种声明
	FuncDecl: 函数和method的定义属于这种声明

而GenDecl的TokPos决定它Specs中的元素类型

	token.IMPORT *ImportSpec 
	token.CONST  *ValueSpec
	token.TYPE   *TypeSpec
	token.VAR    *ValueSpec

FuncDecl，位置，参数和返回值的信息保存FuncDecl.Type中，而函数定义部分保存在FuncDecl.Body中，我们来看看FuncDecl.Body的定义


```
// A BlockStmt node represents a braced statement list.
BlockStmt struct {
	Lbrace token.Pos // position of "{"
	List   []Stmt
	Rbrace token.Pos // position of "}"
}
```


FuncDecl.Body是\*ast.BlockStmt类型，在文件中所有{code...}块都属于\*ast.BlockStmt，包括if condition {...}，switch condition {...}等


\*ast.BlockStmt中的List元素是ast.Stmt接口，有别于全局声明的ast.Decl,函数中支持的语法更多，所以ast.Stmt接口有更多类型,并且Stmt有一个ast.DeclStmt的实现，也就是说，Stmt支持所有Decl表达式


在代码中obj := expr 和 var obj = expr等价，但在ast中这2个表达式分别属于AssignStmt和DeclStmt(GenDecl(token.VAR)),来看看他们的定义


```
// An AssignStmt node represents an assignment or
// a short variable declaration.
//
AssignStmt struct {
	Lhs    []Expr
	TokPos token.Pos   // position of Tok
	Tok    token.Token // assignment token, DEFINE
	Rhs    []Expr
}

// A ValueSpec node represents a constant or variable declaration
// (ConstSpec or VarSpec production).
//
ValueSpec struct {
	Doc     *CommentGroup // associated documentation; or nil
	Names   []*Ident      // value names (len(Names) > 0)
	Type    Expr          // value type; or nil
	Values  []Expr        // initial values; or nil
	Comment *CommentGroup // line comments; or nil
}
```

可以看到他们的子元素通常都是一个Expr，而Expr就是一个表达式，如果用文章来类比的话，Decl相当于段落，Stmt相当于是段落中的句子，而Expr就是句子中的一个词或者分句,而在ast中，Decl构成文件的最外层部分，里面由FuncDecl和GenDecl填充，而我们99%的代码都是FuncDecl的Body中的Stmt,而几乎所有变量和调用和值就是Expr,这样是不是好理解多了


##### 注:可以看到AssignStmt的Lhs是Expr类型而ValueSpec的Names确可以是Ident类型，这是因为所有=的赋值操作也是用AssignStmt来表达，所以Lhs的元素还有可能是一个\*ast.SelectorExpr或\*ast.IndexExpr


汇总一下Stmt和Expr的实现


<details>
<summary>
Stmt实现
</summary>

|Stmt类型     | 说明                 | 例子|
|------------|----------------------|----|
|BadStmt	    |错误的语句      	   |  -
|DeclStmt    |继承Decl              |  -
|EmptyStmt	|空语句                 |  ;;
|LabeledStmt | 定义标签用让goto/break/continue可跳到此处 | MainLoop:
|ExprStmt    | 纯表达式，一些不取函数返回值的调用都属于这部分  | a.Call()
|SendStmt    | channel的<-传值语句   | a <- b
|IncDecStmt  | 自增/自减语句         | a++ or a--
|AssignStmt  | 赋值语句             | a := 2 or a = 2
|GoStmt      | go协程语句           | go myfunc()
|DeferStmt   | defer语句           |defer myfunc()
|ReturnStmt  | 函数返回             |return xxx
|BranchStmt  | 循环控制             |  break [branch]/continue [branch]/goto branch/fallthrough
|BlockStmt   | 块语句               |{stmt...}
|IfStmt      | if语句包含BlockStmt   |if condition {stmt...}
|CaseClause  | case语句包含stmt      | case expr1,expr2: stmt...
|SwitchStmt  | switch语句包含BlockStmt| switch expr {stmt...}
|TypeSwitchStmt | 类型转换的switch    | switch x.(type){stmt...} or switch y := x.(type){stmt...}
|CommClause  | select中的case语句    | case a <-b: stmt...
|SelectStmt  | select语句            | select expr{stmt...}
|ForStmt     | for 语句              | for assign;condition;stmt {stmt...}
|RangeStmt   | for ... range语句     | for k,v :=range kayVal{stmt...}

</details>


<details>
<summary>
Expr实现
</summary>

|Expr类型     | 说明                  | 场景
|------------|-----------------------|-----|
|BadExpr     | 错误表达式             | -   
|Ident       | 标示符，最基本的表达式   | a := myfunc()中的a是ident
|Ellipsis    | 可变长度参数            | myfunc(args...)中的args
|BasicLit    | literal常量            | a := 22 中的22
|FuncLit     | 函数literal常量         | var fun = func(){}中的fun
|CompositeLit| 容器literal常量         | a := []int{1,2,3} 中的[]int{1,2,3} 或 b := map[int]string{}中的map[int]string{}
|ParenExpr   | 括号表达式              | a + (b*c)中的(b*c)
|SelectorExpr| 选择表达式             | a.Method()中的a.Method
|IndexExpr   | 索引表达式              | a[2] or a["a"]
|SliceExpr   | 切片表达式              |a[1:2] or a[1:2:1]
|TypeAssertExpr | 类型转换表达式        | b := a.(int)中的 a.(int)
|CallExpr    | 函数调用表达式          | a.Call()
|StarExpr    | 星表达式，去地址中的值或者定义指针变量 | \*pa = 2 or var pa \*int
|UnaryExpr   | 一元操作符，除了\*外都用这个 | return &a中的&a
|BinaryExpr  | 条件表达式             | if a > b {}中的 a > b，是的这个是expr不是stmt
|KeyValueExpr | 初始化map赋值时会用到  | m := map[int]string{1:"a", 2: "b"}
|ArrayType   | 容器类型               | a := []int{1,2,3} 中的[]int
|StructType  | 结构体类型             | type Product struct { Name string }中的struct { Name string }
|InterfaceType| 接口类型              | var d interface{} = 5中的interface{}
|MapType      | map类型              | b := map[int]string{}中的map[int]string
|ChanType     | chan类型             | d := make(chan int,5)中的chan int

</details>


##### PS: 我个人认为stmt和expr直接的定义是模糊的，一些expr当成stmt也是没有问题的

好了，ast的类型部分基本介绍完了，我们可以开始解析源码做一些生成器或者type check工具了吗？


并不，因为无论parser.ParserFile或parser.ParserDir都是对单个go文件做解析的，go文件之间没有关联，而且也不会解析import的包，为了对go代码进行更准确解析需要用到另一个库go/types,不过这些我会留到下一章再讲


### Ref

[go/ast](https://golang.org/pkg/go/ast)

[go/types](https://github.com/golang/example/tree/master/gotypes)




