+++
Categories = [
  "Develop",
  "Golang",
]

Description = "gorm的增删改查"
Tags = [
  "开发",
  "Go语言",
]
date = "2017-05-29T15:16:00+08:00"
title = "gorm简介[前]"
+++

我们都知道，在正式环境中直接使用sql来查询数据库是很危险的，处理不好就有被注入式攻击的风险


而且组装sql语句也容易出错和减低代码的可维护性


所以需要一个工具来管理数据库语句的组装和操作


gorm是目前比较成熟的go语言数据库管理库,它可以很方便的把go的结构体和数据库表绑定，从而简化获取数据的操作
<!--more-->

**所有gorm的内容在它的[文档](http://jinzhu.me/gorm/)中已经介绍的很详细，所以我这里写的大部分内容可能只是对原文进行了翻译和个人理解上的补充**

### 基本操作

#### **连接数据库**

```golang
package main
import (
	"github.com/jinzhu/gorm"
  //需要连接那个数据库，就import对应的dialect包
	_ "github.com/jinzhu/gorm/dialects/mysql"
	//_ "github.com/jinzhu/gorm/dialects/postgres"
	//_ "github.com/jinzhu/gorm/dialects/sqlite"
  //_ "github.com/jinzhu/gorm/dialects/mssql"
)

func main(){
  db, err := gorm.Open("mysql", "user:password@/dbname?charset=utf8&parseTime=True&loc=Local")
  defer db.close()
  //db, err := gorm.Open("postgres", "host=myhost user=gorm dbname=gorm sslmode=disable password=mypassword")
  //defer db.Close()
  //db, err := gorm.Open("sqlite3", "/tmp/gorm.db")
  //defer db.Close()
  //db, err = gorm.Open("mssql", "sqlserver://username:password@localhost:1433?database=dbname")
  //defer db.Close()
  ...
}
```

#### **创建表**

首先我们来看看如何建立一个和数据库关联的struct

```golang

type Category struct {
	Name        string `gorm:"primary_key"`
	Description string `gorm:"size:255;default:'nothing in here'"`
}

type Email struct {
	ID         int
	UserId     int
	Email      string `gorm:"type:varchar(100);unique_index"`
	Subscribed bool
}

type Origin struct {
	ID        int
	ProductID uint
	Address1  string `gorm:"not null;unique"`
	Address2  string `gorm:"unique"`
}

type Language struct {
	ID   int
	Name string `gorm:"index:idx_name_code"`
	Code string `gorm:"index:idx_name_code"`
}

type Product struct {
	gorm.Model
	Name string `gorm:"index;size:255"`

	Sid         int        `gorm:"unique_index"`
	Categories  []Category `gorm:"many2many:categories_product;"`
	Emails      []Email    `gorm:"ForeignKey:UserId"`
	Origin      *Origin
	Languages   []Language
	Score       *float64 `gorm:"not null;default:1.0"`
	Description string   `gorm:"size:255;default:'nothing in here'"`
}

type GreekAlphabet struct {
	ID         uint   `gorm:"primary_key"`
	LatinName  string `gorm:"unique_index"`
	UpperCode  rune
	LowerCode  rune
	IsFrequent bool `gorm:"index"`
}
```
gorm会go的类型自动转成数据库类型，也可以通过type指定数据库类型
以下是默认情况下go类型和数据库类型对照(这里用postgres举例)

|go类型    |数据库类型   |
|---------|------------|
|int      |integer     |
|uint     |integer     |
|int8-32  |integer     |
|uint8-32 |integer     |
|int64    |bigint      |
|string   |text        |
|bool     |boolean     |
|time.Time|timestamp   |
|float32  |numeric     |
|float64  |numeric     |

**特殊的数组类型**

使用数组类型 默认会当成是一对多模式,可以通过tag修改关系
在一对多模式下，使用数组类型中的类型必须是对应另一个数据表的struct,并且对象struct中要包含名字为**当前表名+ID**的字段，该字段类型最好对应当前表的primary_key类型

---


我们看看Product包含了匿名字段gorm.Model，以下类型都有特殊含义


gorm会在创建和修改，删除时自动填充CreatedAt和UpdatedAt，DeletedAt时自动填充字段值


在gorm中匿名struct中的字段中的Field都会被继承，所以**你也可以像gorm.Model这样把常用字段抽象成一个struct**

ID字段也是默认被当成primary_key的
```golang
package gorm

...

type Model struct {
	ID        uint `gorm:"primary_key"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time `sql:"index"`
}
```


gorm的一大特性就是能用struct的tag来指定栏属性，以下是gorm tag的关键字意义

|关键字                       |属性                                    |
|----------------------------|---------------------------------------|
|通用                                                                |
|index                       |索引                                    |
|index:key_name              |自定义索引名，但2个索引名相同时变为组合索引   |
|unique_index                |唯一索引，组合索引的方法同上                |
|primary_key                 |建立主键，组合的方法同上                   |
|not null                    |指定类型的值不能为空(注意这个not null只是数据库中能否为nil和数据值是否为空没有关系，string一样可以取"")   |
|default                     |默认值                                 |
|-                           |忽略该字段                              |
|数据类型                                                              |
|many2many:must_key_name     |建立多对多的关系，需要声明多对多的表名        |
|ForeignKey:must_key_name    |指定外键名(外键名必须是对应struct的所拥有的字段名)|
|字符串类型                                                            |
|size:255                    |指定长度，一般用于字符串                    |
|type:varchar(100)           |指定类型，不同类型函数的参数不一样            |
|整数字段                                                               |
|AUTO_INCREMENT              |自动增长                                |


然后通过db.CreateTable在数据库中创建对应的数据库

```golang
tables := []interface{}{&Category{}, &Email{}, &Origin{}, &Language{}, &Product{}}
db.DropTableIfExists(tables...)
db.CreateTable(tables...)
```

然后我们可以在数据库看到表的create statement(因为postgres的语法太罗嗦了，所以这里用sqlite举例)

```sqlite
CREATE TABLE "categories" ("name" varchar(255),"description" varchar(255) DEFAULT 'nothing in here' , PRIMARY KEY ("name"))
CREATE TABLE "categories_product" ("product_id" integer,"category_name" varchar(255), PRIMARY KEY ("product_id","category_name"))
CREATE TABLE "emails" ("id" integer primary key autoincrement,"user_id" integer,"email" varchar(100),"subscribed" bool )
CREATE TABLE "languages" ("id" integer primary key autoincrement,"name" varchar(255),"code" varchar(255) )
CREATE TABLE "origins" ("id" integer primary key autoincrement,"product_id" integer,"address1" varchar(255) NOT NULL UNIQUE,"address2" varchar(255) UNIQUE )
CREATE TABLE "products" ("id" integer primary key autoincrement,"created_at" datetime,"updated_at" datetime,"deleted_at" datetime,"name" varchar(255),"sid" integer,"score" real NOT NULL  DEFAULT 1.0,"description" varchar(255) DEFAULT 'nothing in here' )
CREATE TABLE "greek_alphabets" ("id" integer primary key autoincrement,"latin_name" varchar(255),"upper_code" integer,"lower_code" integer,"is_frequent" bool )
```

#### **创建数据**

创建数据比创建表简单多了，我们只需要把数据填入结构体，然后通过db.Create(interface{})来初始化,像这样

```golang
categories := []Category{
	Category{"mobile phone", "a hand-held mobile radiotelephone for use in an area divided into small sections, each with its own short-range transmitter/receiver"},
	Category{"apple", ""},
}
emails := []Email{Email{Email: "example@domain.com", Subscribed: false}}
origin := Origin{Address1: "apple company address", Address2: "test"}
languages := []Language{Language{Name: "中国", Code: "cn"}, Language{Name: "美国", Code: "us"}}
score := float32(0.0)
product := Product{
	Name:       "iphone7",
	Sid:        1211,
	Categories: categories,
	Emails:     emails,
	Origin:     &origin,
	Languages:  languages,
	Score:      &score,
}
err := db.Create(&product).Error
if err != nil {
	t.Error(err)
}
```

相信细心的人已经注意到，我在创建Product时Score字段设为指针，这是因为gorm在创建表时会自动把所有为0值的值忽略(0值的定义可以看[go的介绍](https://golang.org/ref/spec#The_zero_value)),而Score又设置了默认值为1.0。


也就是说，**如果Score如果不是指针字段，它将永远没法设置为0值**


这个规则在下面的查询，插入和更新中也会有，在创建struct时一定要注意这些细节

#### **查询数据**

为了方便查询，我们这里增加几条数据

```golang
categories := []Category{
	Category{"mobile phone", "a hand-held mobile radiotelephone for use in an area divided into small sections, each with its own short-range transmitter/receiver"},
	Category{"xiaomi", ""},
}
emails := []Email{Email{Email: "example2@domain.com", Subscribed: false}}
origin := Origin{Address1: "xiaomi company address", Address2: ""}
languages := []Language{Language{Name: "中国", Code: "cn"}}
score := float32(2.0)
product := Product{
	Name:       "xiaomi6",
	Sid:        1311,
	Categories: categories,
	Emails:     emails,
	Origin:     &origin,
	Languages:  languages,
	Score:      &score,
}
err := db.Create(&product).Error
if err != nil {
	t.Error(err)
}

```

```golang
categories := []Category{
  Category{"food", " sth solid for eating"},
  Category{"meat", ""},
}
emails := []Email{Email{Email: "example3@domain.com", Subscribed: false}}
origin := Origin{Address1: "163 company address", Address2: "163 company address2"}
languages := []Language{Language{Name: "中国", Code: "cn"}}
score := float32(3.0)
product := Product{
  Name:       "wild boar meat",
  Sid:        9999,
  Categories: categories,
  Emails:     emails,
  Origin:     &origin,
  Languages:  languages,
  Score:      &score,
}
err := db.Create(&product).Error
if err != nil {
  t.Error(err)
}
```

**Where查询**

如果我想查询Product.Name = "xiaomi6"，可以这样写

```golang
var product Product
// 因为我知道xiaomi6只有一个结果，所以直接这样写
db.Where(&Product{Name: "xiaomi6"}).First(&product)
```

Where这里的参数和上面Create中提到的规则一样，为空值的字段不会被当成查询条件，所以想查询比如Score为0，字段必须是指针字段


First就是获取第一个查询结果，下面会讲到

**获取**

First函数就是获取第一个查询的结果

```golang
var product Product
db.First(&product)
```

相对的查询最后一个结果,用Last函数

```golang
var product Product
db.Last(&product)
```

这里说明一点，这里调用Last和First所需要的product指针最好是一个内容为空的对象，因为若product.ID不为空，则只会把对象更新为该ID对应的对象，若其他字段不为空就有可能污染查询到的结果


查询全部则用Find

```golang
var products []Product
db.Find(&products)
```

gorm默认不会查询外键对象，如果想把结构体字段的内容也查询出来，可以使用Preload函数预加载这个结构体,像下面这样

```golang
var product Product
db.Preload("Origin").Where(&Product{Name: "xiaomi6"}).First(&product)
```

虽然可以查出Origin字段的数据，不过却使用到了字符串，这样也导致人为拼写错误的可能和增加维护成本，我们可以使用go的反射来解决这个问题，这里就不细说了

---

#### **更新数据**

**Save**

Save更新不会忽略0值，但每次只能更新一条数据

```golang
var xiaomi Product
db.Where(&Product{Name: "xiaomi6"}).First(&xiaomi)
xiaomi.Sid = 0
db.Save(&xiaomi)
var product Product
db.Where(&Product{Name: "xiaomi6"}).First(&product)
//查看product有无更新成功
```

**Update**

使用Updates可以进行批量更新，空值依然会被忽略

```golang
db.Model(&Product{}).Updates(&Product{Description: "also nothing here"})
products := []Product{}
db.Find(&products)
for _, p := range products {
	t.Log(p.Name, p.Description)
}
```


#### **删除数据**

删除数据时要保证被删除数据的主键不能为空，不然会吧整个表的数据都删掉

```golang
var meat Product
db.Where(&Product{Name: "wild boar meat"}).First(&meat)

var product Product
db.Where(&Product{Name: "wild boar meat"}).First(&product)
// 这时查到的product应该为空
```

因为product中包含DeleteAt字段，所以并不会数据并不会真的被删除，只是设置了DeleteAt为当前时间

---

如果数据表没有DeletedAt字段，那么调用Delete会物理删除数据

```golang
var email Email
db.First(&email)
id := email.ID
db.Delete(&email)
// 打印id
...
```

#### **总结**

**优点**

- 支持多种sql数据库

- 支持struct到数据表的映射

- 知道struct tag的到字段属性的映射

- 支持Scope自定义操作，以补充该库功能上的不足(以后会讲到)

**缺点**

- 受限于go的struct，在gorm的查询无法查询0值，而使用指针会让结构体变的异常丑陋

- 条件查询,嵌套查询等操作还是要借助字符串表达式

总的来说gorm还是一个不错orm,用来做简单数据的增删改查还是非常方便，在日常请求的逻辑处理基本是够用的


#### **链接**

[gorm官方文档](http://jinzhu.me/gorm/)

[测试代码地址](https://github.com/bigpigeon/Test/tree/master/go/gorm_demo)
