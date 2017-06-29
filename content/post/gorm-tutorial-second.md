+++
Categories = [
  "Develop",
  "Golang",
]
menu = "main"
Description = "gorm的scopes自定义操作"
Tags = [
  "开发",
  "Go语言",
]
date = "2017-06-23T15:16:00+08:00"
title = "gorm简介[中]"
+++

上篇讲到如何用gorm增删改查，但如果涉及一些复杂的操作又想避免使用字符串就需要借助Scopes模块


### scopes简介

scopes是需要一个自定义的函数**func(db *gorm.DB) *gorm.DB**作为参数，这样就可以在不破坏链式语法的情况下自定义操作了

比如我要查询GreekAlphabet表中LatinName是"Alpha"或 "Omega"的条目可以这样

```golang
chars := []GreekAlphabet{}
db.Model(&GreekAlphabet{}).Where("latin_name in (?)", []string{"Alpha", "Omega"}).Find(&chars)
```

因为查询多个字段的值只能用 **Where("field in (?)", fields)** 这种方法，相当于是自己拼接sql语句了，这种方法非常容易出错，所以我们用Scopes封装这部分操作

```golang
firstAndLast := func(db *gorm.DB) *gorm.DB {
  return db.Where("latin_name in (?)", []string{"Alpha", "Omega"})
}
chars := []GreekAlphabet{}
db.Model(&GreekAlphabet{}).Scopes(firstAndLast).Find(&chars).Error
```

这样只要我们对firstAndLast做充足的单元测试就可以让其他人非常安心的使用了，但这样做还是很不灵活，所以下面我们使用offset来制造一个灵活的socpes查询

<!--more-->
### 使用offset制作一个灵活的Where in查询

首先要构建2个offset的map，用来查询offset对应的字段名(Name)和表字段名(DBName),我把它们放入OffsetSelector变量中

```golang
var OffsetSelector = struct {
	NameMap   map[reflect.Type]map[uintptr]string
	DBNameMap map[reflect.Type]map[uintptr]string
}{
	NameMap:   map[reflect.Type]map[uintptr]string{},
	DBNameMap: map[reflect.Type]map[uintptr]string{},
}
```

然后将Product和GreekAlphabet放入FieldSelector变量中

```golang
var FieldSelector struct {
	Product       Product
	GreekAlphabet GreekAlphabet
}
```

然后构造OffsetSelector中的NameMap和DBNameMap

```golang
// 把FieldSelector解析为reflect.Value这样可以用for循环获取其中的字段
fieldSelectVal := reflect.ValueOf(&FieldSelector).Elem()
for i := 0; i < fieldSelectVal.NumField(); i++ {
  fieldVal := fieldSelectVal.Field(i)
  // 通过gorm.scope来解析字段名(Name)和表字段名(DBName)容易很多
  scope := &gorm.Scope{Value: fieldVal.Interface()}
  // 获取表结构体的reflect.Type
  table := scope.GetModelStruct().ModelType
  // 获取表结构体中所有字段（这里的字段是gorm.Field而不是relfect.Field）
  gormFields := scope.Fields()
  OffsetSelector.NameMap[table] = map[uintptr]string{}
  OffsetSelector.DBNameMap[table] = map[uintptr]string{}
  // 循环拿取表结构体中每一个字段然后把对应的offset和字段名/表字段名分别映射到NameMap/DBNameMap对应的table映射中
  for j := 0; j < len(gormFields); j++ {
    subfield := gormFields[j]
    offset := subfield.StructField.Struct.Offset

    OffsetSelector.NameMap[table][offset] = subfield.Name
    OffsetSelector.DBNameMap[table][offset] = subfield.DBName
  }
}
```

然后我们就可以创建一个通过字段的offset来查询Where In函数了

```golang
WhereIn := func(fieldOffset uintptr, set interface{}) func(db *gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    val := db.Value
    structType := reflect.TypeOf(val)
    // 获取非list或指针的reflect.Type
    for structType.Kind() == reflect.Slice || structType.Kind() == reflect.Ptr {
      structType = structType.Elem()
    }
    // Where的查询语句中用的是表字段名
    dbname, ok := OffsetSelector.DBNameMap[structType][fieldOffset]
    if ok == false {
      db.AddError(errors.New("offset is invalid"))
    }
    query := fmt.Sprintf("%s in (?)", dbname)
    return db.Where(query, set)
  }
}
frequentNames := []string{"Alpha", "Beta", "Gamma", "Delta", "Pi", "Lambda"}
//获取GreekAlphabet.LatinName的offset,记住Offsetof中的参数是表达式，所以不能传参,比如xx := GreekAlphabet{}.LatinName;unsafe.Offsetof(xx)这样是不行的
latinNameOffset := unsafe.Offsetof(GreekAlphabet{}.LatinName)
db.Model(&GreekAlphabet{}).Scopes(WhereIn(latinNameOffset, frequentNames)).Updates(&GreekAlphabet{IsFrequent: true})

frequents := []GreekAlphabet{}
// 查看所有IsFrequent=true的集合
db.Where(&GreekAlphabet{IsFrequent: true}).Find(&frequents)
t.Logf("%10s\t%s\t%s\t%s", "name", "upper", "lower", "frequent")
for _, c := range frequents {
  t.Logf("%10s\t%c\t%c\t%v", c.LatinName, c.UpperCode, c.LowerCode, c.IsFrequent)
}
```

### 使用Offset制作一个灵活的Field Preload

上篇已经讲过利用Preload可以获取嵌套的获取外键关联的字段比如这样

```golang
var product Product
db.Preload("Origin").Where(&Product{Name: "xiaomi6"}).First(&product)
```

但是Preload函数需要提供一个字段名字符串作为参数，所以我们这里通过构造一个利用Offset来查询外键关联字段


使用刚才已经创建的OffsetSelector.NameMap就可以获取offset对应的字段名了

```golang
FieldPreload := func(offset uintptr) func(db *gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    val := db.Value
    structType := reflect.TypeOf(val)
    // 获取非list或指针的reflect.Type
    for structType.Kind() == reflect.Slice || structType.Kind() == reflect.Ptr {
      structType = structType.Elem()
    }
    name, ok := OffsetSelector.NameMap[structType][offset]
    if ok == false {
      db.AddError(errors.New("offset is invalid"))
    }
    t.Log(OffsetSelector.NameMap[structType])
    return db.Preload(name)
  }
}
var product Product
fieldOffset := unsafe.Offsetof(product.Origin)
originPreload := FieldPreload(fieldOffset)
db.Model(&Product{}).Where(&Product{Name: "xiaomi6"}).Scopes(originPreload).First(&product)
// 查看查询结构是否正确
t.Logf("this product name '%s', the address is '%v'", product.Name, product.Origin.Address1)
```

### **结尾**

上面举了2个使用Scopes的使用例子，用来帮助大家在使用gorm时如何更好的保持一致性原则


不过如果有人通过gorm修改了默认表名/默认字符串名创建方式上面的方法就会失效，因为我这边为了易读性就没有用更复杂的写法了


下篇将会解析gorm下的各个数据结构，可能需要很长时间来整理资料
