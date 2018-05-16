+++
title = "ToyBrick"
description = "ToyBrick usage"
weight=4
alwaysopen = true
+++

ToyBrick 是数据库操作的入口, 使用**Toy.Model(<struct>)**创建它


如果你不知道如何创建 Toy 对象, 请看 [engine] 章节


### Init

使用 Toy.Model 去创建 ToyBrick, 它的第一个参数必须是struct类型或者它的指针类型

{{% code theme="info" header="init" %}}

```golang
// User declaration in database connection section
brick := toy.Model(&User{})
// or
brick := toy.Model(User{})
```
{{% /code %}}


### 构建Sql

所有构建方法都会返回一个新的 **\*ToyBrick** 对象 , 它不会改变当前对象的任意数据


{{% code theme="info" header="构建where条件" %}}
```golang
brick = brick.Where(toyorm.ExprEqual, Offsetof(User{}.Sex), "male")
or use string
brick = brick.Where("=", Offsetof(User{}.Sex), "male")
// WHERE tag = "male"
```
{{% /code %}}


{{% code theme="info" header="事务" %}}
```golang
// start a transaction
brick = brick.Begin()
// do sth
result, err := brick.Insert(user)
...
// if have error rollback else commit
if err != nil {
	err := brick.Rollback()
	if err != nil {
		panic(err)
	}
}else {
	brick.Commit()
}
```
{{% /code %}}



### 数据操作

{{% code theme="info" header="创建表" %}}

```golang
_, err = toy.Model(&User{}).Debug().CreateTable()
// CREATE TABLE user (id BIGINT AUTO_INCREMENT,created_at TIMESTAMP NULL,updated_at TIMESTAMP NULL,deleted_at TIMESTAMP NULL,name VARCHAR(255),age BIGINT ,sex VARCHAR(255) , PRIMARY KEY(id))
// CREATE INDEX idx_user_deletedat ON user(deleted_at)
// CREATE UNIQUE INDEX udx_user_name ON user(name)
```
{{% /code %}}

{{% code theme="info" header="删除表" %}}

```golang
var err error
_, err =toy.Model(&User{}).Debug().DropTable()
// DROP TABLE user
```
{{% /code %}}

{{% code theme="info" header="插入数据" %}} 

```golang
user := &User{
    Name: "bigpigeon",
    Age:  18,
    Sex:  "male",
}
_, err = toy.Model(&User{}).Debug().Insert(&user)
// INSERT INTO user(created_at,updated_at,name,age,sex) VALUES(?,?,?,?,?) , args:[]interface {}{time.Time{wall:0xbe8df5112e7f07c8, ext:210013499, loc:(*time.Location)(0x141af80)}, time.Time{wall:0xbe8df5112e7f1768, ext:210017044, loc:(*time.Location)(0x141af80)}, "bigpigeon", 18, "male"}
// print user format with json
/* {
  "ID": 1,
  "CreatedAt": "2018-01-11T20:47:00.780077+08:00",
  "UpdatedAt": "2018-01-11T20:47:00.780081+08:00",
  "DeletedAt": null,
  "Name": "bigpigeon",
  "Age": 18,
  "Sex": "male",
  "Detail": null,
  "Friends": null,
  "Blog": null
}*/
```
{{% /code %}}

如果主键记录已经存在，保存操作可能会覆盖原有数据

{{% code theme="info" header="保存数据" %}} 

```golang
users := []User{
    {
        ModelDefault: toyorm.ModelDefault{ID: 1},
        Name:         "bigpigeon",
        Age:          18,
        Sex:          "male",
    },
    {
        Name: "fatpigeon",
        Age:  27,
        Sex:  "male",
    },
}
_, err = toy.Model(&User{}).Debug().Save(&user)
// SELECT id,created_at FROM user WHERE id IN (?), args:[]interface {}{0x1}
// REPLACE INTO user(id,created_at,updated_at,name,age,sex) VALUES(?,?,?,?,?,?) , args:[]interface {}{0x1, time.Time{wall:0x0, ext:63651278036, loc:(*time.Location)(nil)}, time.Time{wall:0xbe8dfb5511465918, ext:302600558, loc:(*time.Location)(0x141af80)}, "bigpigeon", 18, "male"}
// INSERT INTO user(created_at,updated_at,name,age,sex) VALUES(?,?,?,?,?) , args:[]interface {}{time.Time{wall:0xbe8dfb551131b7d8, ext:301251230, loc:(*time.Location)(0x141af80)}, time.Time{wall:0xbe8dfb5511465918, ext:302600558, loc:(*time.Location)(0x141af80)}, "fatpigeon", 27, "male"}
```

{{% /code %}}

{{% code theme="info" header="更新" %}}  

```golang
toy.Model(&User{}).Debug().Update(&User{
    Age: 4,
})
// UPDATE user SET updated_at=?,age=? WHERE deleted_at IS NULL, args:[]interface {}{time.Time{wall:0xbe8df4eb81b6c050, ext:233425327, loc:(*time.Location)(0x141af80)}, 4}
```

{{% /code %}}

{{% code theme="info" header="查询一条记录" %}} 

```golang
var user User
_, err = toy.Model(&User{}).Debug().Find(&user}
// SELECT id,created_at,updated_at,deleted_at,name,age,sex FROM user WHERE deleted_at IS NULL LIMIT 1, args:[]interface {}(nil)
// print user format with json
/* {
  "ID": 1,
  "CreatedAt": "2018-01-11T12:47:01Z",
  "UpdatedAt": "2018-01-11T12:47:01Z",
  "DeletedAt": null,
  "Name": "bigpigeon",
  "Age": 4,
  "Sex": "male",
  "Detail": null,
  "Friends": null,
  "Blog": null
}*/
```

{{% /code %}}

{{% code theme="info" header="查询多条记录" %}} 

```golang
var users []User
_, err = brick.Debug().Find(&users)
fmt.Printf("find users %s\n", JsonEncode(&users))

// SELECT id,created_at,updated_at,deleted_at,name,age,sex FROM user WHERE deleted_at IS NULL, args:[]interface {}(nil)
```

{{% /code %}}

{{% code theme="info" header="根据主键删除" %}} 

```golang
_, err = brick.Debug().Delete(&user)
// UPDATE user SET deleted_at=? WHERE id IN (?), args:[]interface {}{(*time.Time)(0xc4200f0520), 0x1}
```

{{% /code %}}


{{% code theme="info" header="根据条件删除" %}} 

```golang
_, err = brick.Debug().Where(toyorm.ExprEqual, Offsetof(User{}.Name), "bigpigeon").DeleteWithConditions()
// UPDATE user SET deleted_at=? WHERE name = ?, args:[]interface {}{(*time.Time)(0xc4200dbfa0), "bigpigeon"}
```

{{% /code %}}



