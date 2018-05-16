+++
title = "Tag declaration"
description = "tag declaration2"
weight=3
+++

declaration format can be \<key:value\> or \<key\>

```golang
type User struct {
     toyorm.ModelDefault
     Name    uint   `toyorm:"index"` // key only tag declaration
     FullName   string `toyorm:"column:fullname"` // key:value tag declaration
}
```

2. the following is special tag declaration

Key           |Value                   |Description
--------------|------------------------|-----------
index         | void or string         | use for optimization when search condition have this field,if you want make a combined,just set same index name with fields
unique index  | void or string         | have unique limit index, other same as index
primary key   | void                   | allow multiple primary key,but some operation not support
\-            | void                    | ignore this field in sql
type          | string                  | sql type
column        | string                  | sql column name
auto_increment| void                    | recommend, if your table primary key have auto_increment attribute must add it
autoincrement | void                    | same as auto_increment
foreign key   | void                   | to add foreign key feature when create table
alias         | string                 | change field name with toyorm
join          | string                 | to select related field when call brick.Join
belong to     | string                 | to select related field when call brick.Preload with BelongTo container
one to one    | string                 | to select related field when call brick.Preload with OneToOne container
one to many   | string                 | to select related field when call brick.Preload with OneToMany container


other custom tag declaration will append to end of CREATE TABLE field

```golang
type User struct {
     toyorm.ModelDefault
     Born time.Time `toyorm:"NULL"`
}
// when call CreateTable the born field have "null" attribute at the end
// CREATE TABLE `user` (... , born TIMESTAMP null, ...)
```
