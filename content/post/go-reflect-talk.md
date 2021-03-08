+++
Categories = [
  "Develop",
  "Golang",
]

Description = "谈谈go的reflect"
Tags = [
  "开发",
  "Go语言",
]
date = "2017-06-06T15:16:00+08:00"
title = "谈谈go的relfect"
+++

go的reflect实现了一个运行时反射，它允许程序操纵任意类型的对象


reflect.TypeOf函数能把对象的类型信息，它返回一个relect.Type


reflect.Type.Field模块可以获得**struct**或者**interface**中的字段名，字段类型，字段的tag等信息


reflect.ValueOf可以获得一个对象的值信息，比如它是指针还是实体，值的类型和interface类型下的值，它返回一个reflect.Value


我这里简单谈谈reflect的用法和哪些能做到哪些不能做到


Ps:以下所有代码都包含在这个[测试项目](https://github.com/bigpigeon/Test/tree/master/go/reflect_demo)中

<!--more-->
### 简介

reflect库有3个重要的类型，Type,Value和StructField,分别对应对象类型，对象值，字段对象


Type和Value可以通过TypeOf(obj)和ValueOf(obj)的方法来获取obj的类型属性和值属性


当Type的类型为Struct时可以通过Field，FieldByIndex，FieldByName模块等到里面的StructField


而Value下的Field，FieldByIndex，FieldByName只是获取字段对应的Value

### 普通字段的取值

int类型，其他比如float,uint和complex都是这种，就不举例了


t是*testing.T，因为是在Test函数里面跑，所以用t.Logf来打印日志

```golang
var a int = 20
aVal := reflect.ValueOf(a)
aType := reflect.TypeOf(a)
t.Logf("variable a Value is %v", aVal.Interface())
t.Logf("variable a Type is %s", aType.String())
```

String类型

```golang
var a string = "abcd1234"
aVal := reflect.ValueOf(a)
aType := reflect.TypeOf(a)
t.Logf("variable a Value is %v", aVal.Interface())
t.Logf("variable a Type is %s", aType.String())
t.Logf("variable a length is %d, last character is %c", aVal.Len(), aVal.Index(aVal.Len()-1))
```

list类型

```golang
var a []int = []int{1, 2, 3, 4, 5}
// 当使用append遇到list的空间不足时会重分配n*2的空间，这里只是为了让cap和length不同才这么做
a = append(a, 6)
aVal := reflect.ValueOf(a)
aType := reflect.TypeOf(a)
t.Logf("variable a Value is %v", aVal.Interface())
t.Logf("variable a Type is %s", aType.String())
t.Logf("variable a length is %d,cap is %d, last int is %d", aVal.Len(), aVal.Cap(), aVal.Index(aVal.Len()-1))
```

map类型

```golang
var a map[int]string = map[int]string{1: "a", 2: "b", 3: "c"}
aVal := reflect.ValueOf(a)
aType := reflect.TypeOf(a)
OneVal := reflect.ValueOf(1)
t.Logf("variable a Value is %v", aVal.Interface())
t.Logf("variable a Type is %s", aType.String())
t.Logf("variable a length is %d,one index value is %s", aVal.Len(), aVal.MapIndex(OneVal))
```

修改对象的值

```golang
var a int32 = 10
// 要改变reflect的中的值必须是一个指针的Elem()下的reflect.Value
aVal := reflect.ValueOf(a)
aPointVal := reflect.ValueOf(&a)
t.Logf("variable a set status %v", aVal.CanSet())
t.Logf("variable a in point set status %v", aPointVal.Elem().CanSet())
// 不用担心因为SetInt传入的是一个int64而设置负数会导致不正确，在这个函数中会根据int具体类型而做转换
aPointVal.Elem().SetInt(-20)
t.Logf("variable a changed value %d", aPointVal.Elem().Interface())
// Slice中元素都可以修改
var b []int = []int{1, 2, 3, 4}
bVal := reflect.ValueOf(b)
t.Logf("slice b first element set status %v", bVal.Index(0).CanSet())
// Map中元素都不能直接修改
var c map[int]int = map[int]int{1: 2, 2: 4, 3: 6}
cVal := reflect.ValueOf(c)
oneValue := reflect.ValueOf(1)
fourValue := reflect.ValueOf(4)

t.Logf("map c the 1 key l element set status %v", cVal.MapIndex(oneValue).CanSet())
// 不过可以使用SetMapIndex修改Val的值
cVal.SetMapIndex(oneValue, oneValue)
t.Logf("map c the value with 1 key is %d", cVal.MapIndex(oneValue))
// 也可以对不存在的key设值
cVal.SetMapIndex(fourValue, oneValue)
t.Logf("now map c is %v", cVal)
```

### 结构体字段的取值

创建几个相关联的结构体和模块

```golang
type Application struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	packageData []byte `json:"-"`
}
type MoneyType int

const (
	MoneyTypeUS = MoneyType(iota)
	MoneyTypeCN
)

type Money struct {
	MoneyType MoneyType `json:"money_type" xml:"MoneyType"`
	Number    float64   `json:"number"`
}

type MacApplication struct {
	Application `json:"application"`
	AppleStore  string `json:"apple_store"`
	Favorite    int    `json:"favorite"`
	Money       Money  `json:"money"`
}

func (app Application) GetData() []byte {
	return app.packageData
}
```

并创建对应的对象

```golang
app := MacApplication{
  Application: Application{
    Name:        "sandbox tower defence",
    Description: "a rpg td game",
    packageData: []byte{},
  },
  AppleStore: "https://itunes.apple.com/us/app/example",
  Favorite:   0,
  Money: Money{
    MoneyType: MoneyTypeUS,
    Number:    0,
  },
}
```

通过**reflect.Type下的Field(i)模块函数** 来获取结构体的第i个字段的StructField信息


获得StructField可以获取字段的名字，标签和偏移量和索引信息

```golang
structVal := reflect.TypeOf(app)
for i := 0; i < structVal.NumField(); i++ {
			field := structVal.Field(i)
      // 如果是匿名字段,字段名等于类型名
      t.Logf("%s, this field is a %s and kind is %v", field.Name, field.Type, field.Type.Kind())

}
```

通过StructField.Anonymous判断是否匿名字段，StructField.Type.Kind() == reflect.Struct判断是否结构体，用这种方式来递归读取struct中的结构体信息


下面这个函数带有一个回调，递归读取structType的字段， 并把它下面的每一个field都交给f去处理

```golang
var RecursionGetField func(string, reflect.Type, func(field *reflect.StructField))
RecursionGetField = func(prefix string, structType reflect.Type, f func(field *reflect.StructField)) {
  for i := 0; i < structType.NumField(); i++ {
    field := structType.Field(i)
    field.Name = prefix + "." + field.Name
    f(&field)
    if field.Type.Kind() == reflect.Struct {
      // 匿名结构体字段中的字段当成当前结构体的
      if field.Anonymous == true {
        RecursionGetField(prefix, field.Type, f)
      } else {
        RecursionGetField(field.Name, field.Type, f)
      }
    }
  }
}
```

通过StructField.Tag获取标签相关信息

```golang
structVal := reflect.TypeOf(app)
for i := 0; i < structVal.NumField(); i++ {
     field := structVal.Field(i)
     t.Logf("this field %s,tag is '%s' json field '%s'", field.Name, field.Tag, field.Tag.Get("json"))
}
```


### 应用实现

通过获取Field Name和Type Name来组装创建表的sql语句

```golang
// 这里只是做简单取类型和字段名,不涉及主键和附加属性的处理
// tableFields[table name][field name][field kind name]
tableFields := map[string]map[string]string{}
tables := []string{}
sqlTypeMap := map[reflect.Kind]string{
  reflect.Int:     "integer",
  reflect.String:  "varchar(255)",
  reflect.Float64: "real",
}
structType := reflect.TypeOf(MacApplication{})
var GetTableField func(string, reflect.Type)

GetTableField = func(tName string, structType reflect.Type) {

  if tableFields[tName] == nil {
    tableFields[tName] = map[string]string{}
  }
  for i := 0; i < structType.NumField(); i++ {
    field := structType.Field(i)
    if field.Type.Kind() == reflect.Struct {
      if field.Anonymous == true {
        GetTableField(tName, field.Type)
      } else {
        GetTableField(field.Type.Name(), field.Type)
      }
    } else {
      tableFields[tName][field.Name] = sqlTypeMap[field.Type.Kind()]
    }
  }
}
GetTableField(structType.Name(), structType)
// 通过tableFields表组装sql到tables中
for tName, fields := range tableFields {
  fNameTypeList := []string{}
  for fName, fType := range fields {
    fNameTypeList = append(fNameTypeList, fmt.Sprintf(`"%s" %s`, fName, fType))
  }
  tables = append(tables, fmt.Sprintf(`CREATE TABLE "%s"(%s)`, tName, strings.Join(fNameTypeList, ",")))
}
for _, tab := range tables {
  t.Log(tab)
}
```

根据字段值的指针猜字段名，需要提供对象的指针和对象字段的指针，然后通过偏移量计算出StructField



```golang
structType := reflect.TypeOf(MacApplication{})
offsetmap := map[uintptr]reflect.StructField{}

for i := 0; i < structType.NumField(); i++ {
  field := structType.Field(i)
  offsetmap[field.Offset] = field
}

{
  realFieldName := "Application"
  structVal := reflect.ValueOf(&app)
  ApplicationVal := reflect.ValueOf(&app.Application)
  offset := ApplicationVal.Elem().UnsafeAddr() - structVal.Elem().UnsafeAddr()
  assert.Equal(t, realFieldName, offsetmap[offset].Name)
  t.Logf("I guess this field is %s, real field is %s", offsetmap[offset].Name, realFieldName)
}
{
  realFieldName := "AppleStore"
  structVal := reflect.ValueOf(&app)
  AppleStoreVal := reflect.ValueOf(&app.AppleStore)
  offset := AppleStoreVal.Elem().UnsafeAddr() - structVal.Elem().UnsafeAddr()
  assert.Equal(t, realFieldName, offsetmap[offset].Name)
  t.Logf("I guess this field is %s, real field is %s", offsetmap[offset].Name, realFieldName)
}
```

类型比对

```golang
a := MoneyTypeCN
b := 2
aType := reflect.TypeOf(a)
bType := reflect.TypeOf(b)
// 虽然他们的种类一样但类型不一样(kind翻译为种类是为了不和Type混淆)
t.Logf("a kind is %v, b kind is %v", aType.Kind(), bType.Kind())
t.Logf("a Type is %v, b Type is %v", aType.String(), bType.String())
// 也可以通过转为interface直接比较类型
_, aIsInt := reflect.New(aType).Interface().(int)
t.Logf("a is int?%v", aIsInt)
_, bIsMoneyType := reflect.New(bType).Interface().(MoneyType)
t.Logf("b is MoneyType?%v", bIsMoneyType)
```
