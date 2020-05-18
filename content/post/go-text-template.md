+++
Categories = [
  "go",
]
menu = "main"
Description = ""
Tags = [
  "go",
]
date = "2019-10-05T13:24:00+08:00"
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

<!--more-->

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

其中 `l.input[l.start:l.pos]` 表示这次分析的 “词” 对应的位置(`{{,/*,:= `等等也是属于词 )



lex函数解析顺序(TODO)

```
lexText -> lexLeftDelim ->  lexComment -> lexText
						-> lexInsideAction -> 	

lexText -> EOF
```

我们来开开`Tree.parse`拿到item后怎么处理

##### Tree.parse


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


下一步我们来看看textOrAction干了什么

##### textOrAction

```golang
// textOrAction:
//	text | action
func (t *Tree) textOrAction() Node {
	switch token := t.nextNonSpace(); token.typ {
	case itemText:
		return t.newText(token.pos, token.val)
	case itemLeftDelim:
		return t.action()
	default:
		t.unexpected(token, "input")
	}
	return nil
}


func (t *Tree) newText(pos Pos, text string) *TextNode {
	return &TextNode{tr: t, NodeType: NodeText, Pos: pos, Text: []byte(text)}
}

// Action:
//	control
//	command ("|" command)*
// Left delim is past. Now get actions.
// First word could be a keyword such as range.
func (t *Tree) action() (n Node) {
	switch token := t.nextNonSpace(); token.typ {
	case itemBlock:
		return t.blockControl()
	case itemElse:
		return t.elseControl()
	case itemEnd:
		return t.endControl()
	case itemIf:
		return t.ifControl()
	case itemRange:
		return t.rangeControl()
	case itemTemplate:
		return t.templateControl()
	case itemWith:
		return t.withControl()
	}
	t.backup()
	token := t.peek()
	// Do not pop variables; they persist until "end".
	return t.newAction(token.pos, token.line, t.pipeline("command"))
}
```

textOrAction非常简单，就是把item分成2部分，遇到itemText就解析成`TextNode`遇到`{{`就开始action解析


所以继续看几个关键的action函数这部分就算完成了

##### IfNode


```golang
// If:
//	{{if pipeline}} itemList {{end}}
//	{{if pipeline}} itemList {{else}} itemList {{end}}
// If keyword is past.
func (t *Tree) ifControl() Node {
	return t.newIf(t.parseControl(true, "if"))
}

func (t *Tree) newIf(pos Pos, line int, pipe *PipeNode, list, elseList *ListNode) *IfNode {
	return &IfNode{BranchNode{tr: t, NodeType: NodeIf, Pos: pos, Line: line, Pipe: pipe, List: list, ElseList: elseList}}
}

func (t *Tree) parseControl(allowElseIf bool, context string) (pos Pos, line int, pipe *PipeNode, list, elseList *ListNode) {
	defer t.popVars(len(t.vars))
	pipe = t.pipeline(context)
	var next Node
	list, next = t.itemList()
	switch next.Type() {
	case nodeEnd: //done
	case nodeElse:
		if allowElseIf {
			// Special case for "else if". If the "else" is followed immediately by an "if",
			// the elseControl will have left the "if" token pending. Treat
			//	{{if a}}_{{else if b}}_{{end}}
			// as
			//	{{if a}}_{{else}}{{if b}}_{{end}}{{end}}.
			// To do this, parse the if as usual and stop at it {{end}}; the subsequent{{end}}
			// is assumed. This technique works even for long if-else-if chains.
			// TODO: Should we allow else-if in with and range?
			if t.peek().typ == itemIf {
				t.next() // Consume the "if" token.
				elseList = t.newList(next.Position())
				elseList.append(t.ifControl())
				// Do not consume the next item - only one {{end}} required.
				break
			}
		}
		elseList, next = t.itemList()
		if next.Type() != nodeEnd {
			t.errorf("expected end; found %s", next)
		}
	}
	return pipe.Position(), pipe.Line, pipe, list, elseList
}

// itemList:
//	textOrAction*
// Terminates at {{end}} or {{else}}, returned separately.
func (t *Tree) itemList() (list *ListNode, next Node) {
	list = t.newList(t.peekNonSpace().pos)
	for t.peekNonSpace().typ != itemEOF {
		n := t.textOrAction()
		switch n.Type() {
		case nodeEnd, nodeElse:
			return list, n
		}
		list.append(n)
	}
	t.errorf("unexpected EOF")
	return
}
```


这个函数内容太多我就跳过细节了


首先ifControl/rangeControl/withControl/rangeControl需要调用parseControl，也可以理解为所有`{{ }}`可以支持语句的都需要通过该函数来解析，比如pipeline `|` 或者函数调用等


`parseControl`逻辑

1. 把 `{{}}`中所有内容解析成`PipeNode`
1. 调用`Tree.itemList`尝试获取ElseNode和EndNode


在最后，我们来看看下面例子生成的node是怎么样的,以下是letter模板生成的Node结构，缩进表示层级

```
testdata/letter.tmpl:1:0 (NodeList)
 testdata/letter.tmpl:1:0 (NodeText)
 testdata/letter.tmpl:1:7 (NodeAction)
  testdata/letter.tmpl:1:7 (NodePipe)
   testdata/letter.tmpl:1:7 (NodeCommand)
    testdata/letter.tmpl:1:7 (NodeField)
 testdata/letter.tmpl:1:14 (NodeText)
 testdata/letter.tmpl:2:5 (NodeIf)
  testdata/letter.tmpl:2:5 (NodePipe)
   testdata/letter.tmpl:2:5 (NodeCommand)
    testdata/letter.tmpl:2:5 (NodeField)
  testdata/letter.tmpl:2:16 (NodeList)
   testdata/letter.tmpl:2:16 (NodeText)
  testdata/letter.tmpl:4:10 (NodeList)
   testdata/letter.tmpl:4:10 (NodeText)
 testdata/letter.tmpl:6:9 (NodeText)
 testdata/letter.tmpl:7:7 (NodeWith)
  testdata/letter.tmpl:7:7 (NodePipe)
   testdata/letter.tmpl:7:7 (NodeCommand)
    testdata/letter.tmpl:7:7 (NodeField)
  testdata/letter.tmpl:8:4 (NodeList)
   testdata/letter.tmpl:8:4 (NodeText)
   testdata/letter.tmpl:8:31 (NodeAction)
    testdata/letter.tmpl:8:31 (NodePipe)
     testdata/letter.tmpl:8:31 (NodeCommand)
      testdata/letter.tmpl:8:31 (NodeDot)
   testdata/letter.tmpl:8:34 (NodeText)
 testdata/letter.tmpl:9:7 (NodeText)
 ```

 总结一下


 text/template通过 lex 将文本解析成一个个item,然后通过`Tree.parse`生成一个有层级关系的node，最后通过 `Execute`生成文本，下面来介绍模板Execute


其实和语言编译原理有点像，词法解析器->语法解析器->编译成一个对象->根据执行参数的不同输出不同结果

#### 模板Execute

execute就很简单了，基本就是该循环循环，该打印打印，


Pipe里面只有当node.Pipe.Decl为0才会把Pipe中的值渲染出来，不然只是一次赋值，


稍微能讲讲的就是node.Pipe

```golang
// Execute applies a parsed template to the specified data object,
// and writes the output to wr.
// If an error occurs executing the template or writing its output,
// execution stops, but partial results may already have been written to
// the output writer.
// A template may be executed safely in parallel, although if parallel
// executions share a Writer the output may be interleaved.
//
// If data is a reflect.Value, the template applies to the concrete
// value that the reflect.Value holds, as in fmt.Print.
func (t *Template) Execute(wr io.Writer, data interface{}) error {
	return t.execute(wr, data)
}

func (t *Template) execute(wr io.Writer, data interface{}) (err error) {
	defer errRecover(&err)
	value, ok := data.(reflect.Value)
	if !ok {
		value = reflect.ValueOf(data)
	}
	state := &state{
		tmpl: t,
		wr:   wr,
		vars: []variable{{"$", value}},
	}
	if t.Tree == nil || t.Root == nil {
		state.errorf("%q is an incomplete or empty template", t.Name())
	}
	state.walk(value, t.Root)
	return
}

// Walk functions step through the major pieces of the template structure,
// generating output as they go.
func (s *state) walk(dot reflect.Value, node parse.Node) {
	s.at(node)
	switch node := node.(type) {
	case *parse.ActionNode:
		// Do not pop variables so they persist until next end.
		// Also, if the action declares variables, don't print the result.
		val := s.evalPipeline(dot, node.Pipe)
		if len(node.Pipe.Decl) == 0 {
			s.printValue(node, val)
		}
	case *parse.IfNode:
		s.walkIfOrWith(parse.NodeIf, dot, node.Pipe, node.List, node.ElseList)
	case *parse.ListNode:
		for _, node := range node.Nodes {
			s.walk(dot, node)
		}
	case *parse.RangeNode:
		s.walkRange(dot, node)
	case *parse.TemplateNode:
		s.walkTemplate(dot, node)
	case *parse.TextNode:
		if _, err := s.wr.Write(node.Text); err != nil {
			s.writeError(err)
		}
	case *parse.WithNode:
		s.walkIfOrWith(parse.NodeWith, dot, node.Pipe, node.List, node.ElseList)
	default:
		s.errorf("unknown node: %s", node)
	}
}

```


我们来看看Pipe的解析时怎么样的


执行里面的cmds，然后跳过`interface{}`对象拿里面的值

```golang
// Eval functions evaluate pipelines, commands, and their elements and extract
// values from the data structure by examining fields, calling methods, and so on.
// The printing of those values happens only through walk functions.

// evalPipeline returns the value acquired by evaluating a pipeline. If the
// pipeline has a variable declaration, the variable will be pushed on the
// stack. Callers should therefore pop the stack after they are finished
// executing commands depending on the pipeline value.
func (s *state) evalPipeline(dot reflect.Value, pipe *parse.PipeNode) (value reflect.Value) {
	if pipe == nil {
		return
	}
	s.at(pipe)
	value = missingVal
	for _, cmd := range pipe.Cmds {
		value = s.evalCommand(dot, cmd, value) // previous value is this one's final arg.
		// If the object has type interface{}, dig down one level to the thing inside.
		if value.Kind() == reflect.Interface && value.Type().NumMethod() == 0 {
			value = reflect.ValueOf(value.Interface()) // lovely!
		}
	}
	for _, variable := range pipe.Decl {
		if pipe.IsAssign {
			s.setVar(variable.Ident[0], value)
		} else {
			s.push(variable.Ident[0], value)
		}
	}
	return value
}


func (s *state) evalCommand(dot reflect.Value, cmd *parse.CommandNode, final reflect.Value) reflect.Value {
	firstWord := cmd.Args[0]
	switch n := firstWord.(type) {
	case *parse.FieldNode:
		return s.evalFieldNode(dot, n, cmd.Args, final)
	case *parse.ChainNode:
		return s.evalChainNode(dot, n, cmd.Args, final)
	case *parse.IdentifierNode:
		// Must be a function.
		return s.evalFunction(dot, n, cmd, cmd.Args, final)
	case *parse.PipeNode:
		// Parenthesized pipeline. The arguments are all inside the pipeline; final is ignored.
		return s.evalPipeline(dot, n)
	case *parse.VariableNode:
		return s.evalVariableNode(dot, n, cmd.Args, final)
	}
	s.at(firstWord)
	s.notAFunction(cmd.Args, final)
	switch word := firstWord.(type) {
	case *parse.BoolNode:
		return reflect.ValueOf(word.True)
	case *parse.DotNode:
		return dot
	case *parse.NilNode:
		s.errorf("nil is not a command")
	case *parse.NumberNode:
		return s.idealConstant(word)
	case *parse.StringNode:
		return reflect.ValueOf(word.Text)
	}
	s.errorf("can't evaluate command %q", firstWord)
	panic("not reached")
}
```

go模板就写到这里，里面代码给人一种零乱的感觉，但是代码意图和注释还是很清晰的，看函数名和注释能猜到个大概


抛开代码结构不说，go的template的语法自成一派让人用起来很不舒服，每次使用都得查查文档，如果能和go语法统一就好了





