+++
title = "Tag声明"
description = "tag declaration2"
weight=3
+++

声明格式可以是 \<key:value\> 或 \<key\>

```golang
type User struct {
     toyorm.ModelDefault
     Name    uint   `toyorm:"index"` // 只有key的声明
     FullName   string `toyorm:"column:fullname"` // 键值声明
}
```

2. 下面这些是特殊tag声明

键            |值                       | 说明
--------------|------------------------|-----------
index         | void or string         | 为字段增加索引,如果你想声明一个组合索引，只要在字段之间使用相同的索引名即可
unique index  | void or string         | 唯一索引声明, 用法同上
primary key   | void                   | 主键声明,允许但不建议多主键，因为一些操作可能不支持
\-            | void                    | 在sql操作中忽略该字段
type          | string                  | 声明sql字段类型
column        | string                  | 声明sql字段名
auto_increment| void                    | 如果你的主键有 auto_increment 属性，请添加它
autoincrement | void                    | 和auto_increment一样
foreign key   | void                   | 外键声明，不推荐使用
alias         | string                 | 声明字段名
join          | string                 | 用于选择Join容器的关联字段
belong to     | string                 | 用于选择BelongTo预加载的关联字段
one to one    | string                 | 用于选择OneToOne预加载的关联字段
one to many   | string                 | 用于选择OneToMany预加载的关联字段


额外的tag声明会在创建表时附加到字段末尾

```golang
type User struct {
     toyorm.ModelDefault
     Born time.Time `toyorm:"NULL"`
}
// when call CreateTable the born field have "null" attribute at the end
// CREATE TABLE `user` (... , born TIMESTAMP null, ...)
```
