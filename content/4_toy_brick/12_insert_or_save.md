+++
title = "Insert Or Save"
+++

If you clearly know you want to add new data , use Insert

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

If you lazy want toyorm auto select insert or update, use Save

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

but Save will lose data when related table have unique index

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

use USave if you clearly know data's existed, USave use Update operation to save data

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

if data not change , brick.USave also return "save failure" error

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

if have Cas field, save operation will failure when it's value modified by third party

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
