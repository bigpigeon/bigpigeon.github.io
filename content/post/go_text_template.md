+++
Categories = [
  "go",
]
menu = "main"
Description = ""
Tags = [
  "go",
]
date = "2019-08-04T13:24:00+08:00"
title = "go的text/template源码解析"
+++

go的模板库一直缺少indent的功能，于是我决定自己造个轮子来解决这个问题


为了造出好用，贴近源生态的轮子，所以我决定把text/template的源码熟读一遍


本篇只是粗略的讲解模板的各个模块，不会深入函数细节


首先基本用法开始


#### 基本用法



我们这里用的是text_template中example_test的ExampleTemplate()作为例子


通过一下命令创建一个text模板,其中Must函数表示处理错误并panic，New表示创建一个空模板，解析模板内容的逻辑在Parse函数中


然后通过`t.Execute`把模板渲染出来

```golang
const letter = `
Dear {{.Name}},
{{if .Attended}}
It was a pleasure to see you at the wedding.
{{- else}}
It is a shame you couldn't make it to the wedding.
{{- end}}
{{with .Gift -}}
Thank you for the lovely {{.}}.
{{end}}
Best wishes,
Josie
`

// Prepare some data to insert into the template.
type Recipient struct {
	Name, Gift string
	Attended   bool
}
var recipients = []Recipient{
	{"Aunt Mildred", "bone china tea set", true},
	{"Uncle John", "moleskin pants", false},
	{"Cousin Rodney", "", false},
}

t := template.Must(template.New("letter").Parse(letter))

// Execute the template for each recipient.
for _, r := range recipients {
	err := t.Execute(os.Stdout, r)
	if err != nil {
		log.Println("executing template:", err)
	}
}
```


#### 数据结构

先看看text/template的Template结构，这个是整个template库最重要了结构了，也是我们通过`template.New("letter").Parse(letter)`得到对象


下面我会加入自己的注释，以`// self`开头

```golang
// Template is the representation of a parsed template. The *parse.Tree
// field is exported only for use by html/template and should be treated
// as unexported by all other clients.
type Template struct {
	name string     // self 模板名字
	*parse.Tree     // self 
	*common
	leftDelim  string  //self 左分隔符，一般是 {{ 
	rightDelim string  //self 右分隔符, 一般是 }}
}

// common holds the information shared by related templates.
type common struct {
	tmpl   map[string]*Template // Map from name to defined templates. //self 模板的子模板，在文件中的 {{ define xxx }} {{ end }} 就会创建一个模板
	option option
	// We use two maps, one for parsing and one for execution.
	// This separation makes the API cleaner since it doesn't
	// expose reflection to the client.
	muFuncs    sync.RWMutex // protects parseFuncs and execFuncs 
	parseFuncs FuncMap      //self 以interface{}形式保存的函数对象
	execFuncs  map[string]reflect.Value // self parseFuncs中的函数最终都会转换成reflect.Value形式
}
```

Template中还有一个`parse.Tree` 看看它长什么样子

```golang
// Tree is the representation of a single parsed template.
type Tree struct {
	Name      string    // name of the template represented by the tree.
	ParseName string    // name of the top-level template during parsing, for error messages.
	Root      *ListNode // top-level root of the tree.
	text      string    // text parsed to create the template (or its parent) //self 等待解析的文本
	// Parsing only; cleared after parse.
	funcs     []map[string]interface{}
	lex       *lexer //self 词法解析器，用于解析模板中的关键字,比如 '{{' ,'|', '=', 函数名，表达式，等等
	token     [3]item // three-token lookahead for parser.
	peekCount int
	vars      []string // variables defined at the moment.
	treeSet   map[string]*Tree
}

// ListNode holds a sequence of nodes.
type ListNode struct {
	NodeType  //self 节点类型，没什么好说的
	Pos       //self 该节点在文本中的位置，也可以理解为index
	tr    *Tree //self 该节点在树中的位置
	Nodes []Node // The element nodes in lexical order.
}

// A Node is an element in the parse tree. The interface is trivial.
// The interface contains an unexported method so that only
// types local to this package can satisfy it.
type Node interface {
	Type() NodeType
	String() string
	// Copy does a deep copy of the Node and all its components.
	// To avoid type assertions, some XxxNodes also have specialized
	// CopyXxx methods that return *XxxNode.
	Copy() Node
	Position() Pos // byte position of start of node in full original input string
	// tree returns the containing *Tree.
	// It is unexported so all implementations of Node are in this package.
	tree() *Tree
}


const (
	NodeText       NodeType = iota // Plain text.
	NodeAction                     // A non-control action such as a field evaluation.
	NodeBool                       // A boolean constant.
	NodeChain                      // A sequence of field accesses.
	NodeCommand                    // An element of a pipeline.
	NodeDot                        // The cursor, dot.
	nodeElse                       // An else action. Not added to tree.
	nodeEnd                        // An end action. Not added to tree.
	NodeField                      // A field or method name.
	NodeIdentifier                 // An identifier; always a function name.
	NodeIf                         // An if action.
	NodeList                       // A list of Nodes.
	NodeNil                        // An untyped nil constant.
	NodeNumber                     // A numerical constant.
	NodePipe                       // A pipeline of commands.
	NodeRange                      // A range action.
	NodeString                     // A string constant.
	NodeTemplate                   // A template invocation action.
	NodeVariable                   // A $ variable.
	NodeWith                       // A with action.
)
```



#### 创建模板



我们从Parse函数作为入口看看它做了什么


```golang
// Parse parses text as a template body for t.
// Named template definitions ({{define ...}} or {{block ...}} statements) in text
// define additional templates associated with t and are removed from the
// definition of t itself.
//
// Templates can be redefined in successive calls to Parse.
// A template definition with a body containing only white space and comments
// is considered empty and will not replace an existing template's body.
// This allows using Parse to add new named template definitions without
// overwriting the main template body.
func (t *Template) Parse(text string) (*Template, error) {
	t.init()
	t.muFuncs.RLock()
	trees, err := parse.Parse(t.name, text, t.leftDelim, t.rightDelim, t.parseFuncs, builtins)
	t.muFuncs.RUnlock()
	if err != nil {
		return nil, err
	}
	// Add the newly parsed trees, including the one for t, into our common structure.
	for name, tree := range trees {
		if _, err := t.AddParseTree(name, tree); err != nil {
			return nil, err
		}
	}
	return t, nil
}
```

如果在模板使用语法我就不讲了，从注释中我们还可以知道，该函数可以重复调用，新的模板会覆盖旧的，然后我们看看代码


代码大致含义 **parse.Parse** 函数把文本解析成`map[string]*parse.Tree`的树map对象,然后把它append到当前模板的t.temp中


然后看看**parse.Parse**发生了什么

```golang

// Parse returns a map from template name to parse.Tree, created by parsing the
// templates described in the argument string. The top-level template will be
// given the specified name. If an error is encountered, parsing stops and an
// empty map is returned with the error.
func Parse(name, text, leftDelim, rightDelim string, funcs ...map[string]interface{}) (map[string]*Tree, error) {
	treeSet := make(map[string]*Tree)
	t := New(name)
	t.text = text
	_, err := t.Parse(text, leftDelim, rightDelim, treeSet, funcs...)
	return treeSet, err
}
```

我们接着往下看

```golang

// Parse parses the template definition string to construct a representation of
// the template for execution. If either action delimiter string is empty, the
// default ("{{" or "}}") is used. Embedded template definitions are added to
// the treeSet map.
func (t *Tree) Parse(text, leftDelim, rightDelim string, treeSet map[string]*Tree, funcs ...map[string]interface{}) (tree *Tree, err error) {
	defer t.recover(&err)
	t.ParseName = t.Name
	t.startParse(funcs, lex(t.Name, text, leftDelim, rightDelim), treeSet)
	t.text = text
	t.parse()
	t.add()
	t.stopParse()
	return t, nil
}

// lex creates a new scanner for the input string.
func lex(name, input, left, right string) *lexer {
	if left == "" {
		left = leftDelim
	}
	if right == "" {
		right = rightDelim
	}
	l := &lexer{
		name:       name,
		input:      input,
		leftDelim:  left,
		rightDelim: right,
		items:      make(chan item),
		line:       1,
	}
	go l.run()
	return l
}

// startParse initializes the parser, using the lexer.
func (t *Tree) startParse(funcs []map[string]interface{}, lex *lexer, treeSet map[string]*Tree) {
	t.Root = nil
	t.lex = lex
	t.vars = []string{"$"}
	t.funcs = funcs
	t.treeSet = treeSet
}


```

lex就是词法解析器，它不断的读取文本中的关键字，传给`Tree.parse`来解析


`Tree.startParse`并不是真的开始解析，它只是初始化`Tree`的词法解析器等字段


`Tree.parse`会读取从lex中解析的关键词，构建成不同的节点，保存到树中(这个源码我会在下面讲解时才贴)


我们先从lex开始看

```golang
// lex creates a new scanner for the input string.
func lex(name, input, left, right string) *lexer {
	if left == "" {
		left = leftDelim
	}
	if right == "" {
		right = rightDelim
	}
	l := &lexer{
		name:       name,
		input:      input,
		leftDelim:  left,
		rightDelim: right,
		items:      make(chan item),
		line:       1,
	}
	go l.run()
	return l
}

// run runs the state machine for the lexer.
func (l *lexer) run() {
	for state := lexText; state != nil; {
		state = state(l)
	}
	close(l.items)
}


// lexText scans until an opening action delimiter, "{{".
func lexText(l *lexer) stateFn {
	l.width = 0
	if x := strings.Index(l.input[l.pos:], l.leftDelim); x >= 0 {
		ldn := Pos(len(l.leftDelim))
		l.pos += Pos(x)
		trimLength := Pos(0)
		if strings.HasPrefix(l.input[l.pos+ldn:], leftTrimMarker) {
			trimLength = rightTrimLength(l.input[l.start:l.pos])
		}
		l.pos -= trimLength
		if l.pos > l.start {
			l.emit(itemText)
		}
		l.pos += trimLength
		l.ignore()
		return lexLeftDelim
	} else {
		l.pos = Pos(len(l.input))
	}
	// Correctly reached EOF.
	if l.pos > l.start {
		l.emit(itemText)
	}
	l.emit(itemEOF)
	return nil
}
```

`lex`函数通过`go l.run`异步执行单词解析，并通过`items chan`传给外面


`lexer.Run`通过不断执行 `stateFn`直到它返回一个空值


第一个被执行的`stateFn`是lexText，它负责扫描遇到 `{{`符号之前的所有字符，也就是模板语法之外的文本


`l.emit`就是往 `l.items`发送一个 item，我们看看l.emit是怎么样的

```golang
// emit passes an item back to the client.
func (l *lexer) emit(t itemType) {
	l.items <- item{t, l.start, l.input[l.start:l.pos], l.line}
	// Some items contain text internally. If so, count their newlines.
	switch t {
	case itemText, itemRawString, itemLeftDelim, itemRightDelim:
		l.line += strings.Count(l.input[l.start:l.pos], "\n")
	}
	l.start = l.pos
}
```

其中 `l.input[l.start:l.pos]` 表示这次分析的 “词” 对线的值(我这里用引号是因为它并不是英文的word,而是lexer解析出来的对象，比如`{{,/*,:= `等等 )



lex函数解析顺序(TODO)

```
lexText -> lexLeftDelim ->  lexComment -> lexText
						-> lexInsideAction -> 	

lexText -> EOF
```

我们来开开`Tree.parse`拿到item后怎么处理


```golang
// parse is the top-level parser for a template, essentially the same
// as itemList except it also parses {{define}} actions.
// It runs to EOF.
func (t *Tree) parse() {
	t.Root = t.newList(t.peek().pos)
	for t.peek().typ != itemEOF {
		if t.peek().typ == itemLeftDelim {
			delim := t.next()
			if t.nextNonSpace().typ == itemDefine {
				newT := New("definition") // name will be updated once we know it.
				newT.text = t.text
				newT.ParseName = t.ParseName
				newT.startParse(t.funcs, t.lex, t.treeSet)
				newT.parseDefinition()
				continue
			}
			t.backup2(delim)
		}
		switch n := t.textOrAction(); n.Type() {
		case nodeEnd, nodeElse:
			t.errorf("unexpected %s", n)
		default:
			t.Root.append(n)
		}
	}
}
```

首先parse这个函数的目的是把lex解析出来的item进一步解析成`parse.Node`然后放入t.Root中


在解释这个函数之前我也简单说说 `peek`,`next`,`backup`,`backup2` 这几个函数的含义

- peek: 查看栈的最后一个item
- next: 拿出栈的最后一个item
- backend: 把最后一个拿出来的item塞到栈尾
- backend2: 把最后一个拿出来的item塞到栈尾，并额外塞一个进去
- backend3: 和backend2同理，塞2个进去

好了理解了这些我们就基本能看到这个函数在干什么了


1. 用第0个item.pos来初始化`t.Root`
1. for循环遍历item，直到遇到`itemEOF`这个结束符item为止
1. 遇到 左分隔符(也就是"{{")判断这个分隔符中的是不是 itemDefine(也就是{{define subTemp}}来定义额外的模板树)，如果是，开始解析子模板树并跳过这一轮循环，如果不是回到itemLeftDelim之前从新解析
1. 通过`Tree.textOrAction`返回下一个Node放入`t.Root`中






