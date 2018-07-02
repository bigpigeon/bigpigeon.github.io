+++
title = "Insert Or Save"
+++

如果你清楚的知道需要插入一个新数据，使用Insert

```golang
type User struct {
	toyorm.ModelDefault
	Name string
}
...
brick := toy.Model(&User{})
data := User{
	Name: "bigpigeon",
}
brick.Insert(&data)
```

如果你比较懒，想让toyorm自动选择插入或者保存，使用Save

```golang
// if have zero primary key, save still use insert into
brick.Save(&User{
	Name: "bigpigeon",
}) // this operation almost same as brick.Insert
// INSERT INTO user(...) VALUES(...,"bigpigeon")

brick.Save(&User{
	ID: 1,
	CreatedAt: now,
	Name: "bigpigeon",
}) // if id existed, will use insert if conflict update operation
// in postgresql dialect, execute code
// INSERT INTO user(...) VALUES(...,"bigpigeon") ON CONFLICT(id) DO UPDATE SET ..., name = Excluded.name 
```

如果映射的表中有unique index属性的字段，使用Save可能导致数据丢失

```golang
type User struct {
	toyorm.ModelDefault
	Name string `toyorm:"unique index"`
}

brick.Save(&User{
	ID: 1,
	CreatedAt: now,
	Name: "bigpigeon",
}) 

brick.Save(&User{
	ID: 2,
	CreatedAt: now,
	Name: "bigpigeon",
}) // in sqlite3 ,this operation will replace ID=1 data and lose it's infomation

```

如果你清楚的知道数据已经存在使用Usave, USave 使用更新操作跟新数据

```golang
type User struct {
	toyorm.ModelDefault
	Name string `toyorm:"unique index"`
}

oldData := User{
	ID: 1,
	CreatedAt: now,
	Name: "bigpigeon",
}

brick.Insert(&oldData) 

brick.Insert(&User{
	ID: 2,
	CreatedAt: now,
	Name: "pigeon",
})

oldData.Name = "pigeon"

report, err := brick.USave(&oldData) // USave will return report's error, because Name field conflict
```

PS: 如果USave的数据没有被改变，也会导致"save failure"错误

```golang
type User struct {
	ID   uint32 `toyorm:"primary key"`
	Name string 
}

oldData := User{
	ID: 1,
	Name: "bigpigeon",
}

brick.Insert(&oldData)
brick.USave(&oldData) // this operation will return "save failure" because data was not change
```

如果包含Cas字段，当数据被第三方修改,保存操作将会失败

```golang
type User struct {
	toyorm.ModelDefault
	Name   string
	Cas    int
}

data := User{
	ID: 1,
	Name: "bigpigeon",
}
brick.Insert(&data) 


data2 := User
data2.Name = "pigeon"
brick.Save(&data2)

data.Name = "benjamin"
brick.Save(&data) // save will failure, because Cas not match
```
