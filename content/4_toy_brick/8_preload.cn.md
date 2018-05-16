+++
title = "预加载"
+++


预加载需要一个关联字段和一个容器字段(ManyToMany只需要容器字段)


关联字段用来关联主记录和子记录的数据


关联字段可以是一个外键，但不推荐这么做


容器字段用来保存查询出来的子记录，它本身不属于表的任何字段

##### One to one

关联字段在子Model中


关联字段的名字必须是主Model类型名+主Model的主键名

```golang
type User struct {
    toyorm.ModelDefault
    // container field
    Detail  *UserDetail
}

type UserDetail struct {
    ID       int    `toyorm:"primary key;auto_increment"`
    // relation field
    UserID   uint   `toyorm:"index"`
    MainPage string `toyorm:"type:Text"`
}

// load preload
brick = toy.Model(&User{}).Debug().Preload(OffsetOf(User.Detail)).Enter()

```

##### Belong to

关联字段在主Model中


关联字段的名字必须是容器字段名+子Model的主键名


```golang
type User struct {
    toyorm.ModelDefault
    // container field
    Detail   *UserDetail
    // relation field
    DetailID int `toyorm:"index"`
}

type UserDetail struct {
    ID       int    `toyorm:"primary key;auto_increment"`
    MainPage string `toyorm:"type:Text"`
}

```

##### One to many


关联字段在子Model中


关联字段的名字必须是主Model类型名+主Model的主键名


```golang
type User struct {
    toyorm.ModelDefault
    // container field
    Blog    []Blog
}

type Blog struct {
    toyorm.ModelDefault
    // relation field
    UserID  uint   `toyorm:"index"`
    Title   string `toyorm:"index"`
    Content string
}

```

##### Many to many

ManyToMany中不需要指定关联字段，它的关联字段在中间表

```
type User struct {
    toyorm.ModelDefault
    // container field
    Friends    []*User
}
```

##### Load preload

如果你完成了数据的定义，是时候开始构建预加载的数据了

```golang
// create a main brick
brick = toy.Model(&User{})
// create a sub brick
subBrick := brick.Preload(OffsetOf(User.Blog))
// you can editing any attribute what you want, just like editing it on main model
subBrick = subBrick.Where(ExprEqual, OffsetOf(Blog.Title), "my blog")
// finished change ,use Enter() go back the main brick
brick = subBrick.Enter()
```


如果你不喜欢这种关联字段的命名，也可以手动指定它的关系

```golang
// one to one custom
brick.CustomOneToOnePreload(<main container>, <sub relation>, [sub model struct])
// belong to custom
brick.CustomBelongToPreload(<main container>, <main relation>, [sub model struct])
// one to many
brick.CustomOneToManyPreload(<main container>, <sub relation>, [sub model struct])
// many to many
brick.CustomManyToManyPreload(<middle model struct>, <main container>, <main relation>, <sub relation>, [sub model struct])
```

或者使用tag声明来自定义关联字段

```golang
type UserDetail struct {
    ID       int    `toyorm:"primary key;auto_increment"`
    MainID   uint32 `toyorm:"index;one to one:Detail"` // declaration the container field 
    MainPage string `toyorm:"type:Text"`
    Extra    Extra  `toyorm:"type:VARCHAR(1024)"`
}

type Blog struct {
    toyorm.ModelDefault
    MainID  uint32 `toyorm:"index;one to many:Blog"` // declaration the container field 
    Title   string `toyorm:"index"`
    Content string
}

type User struct {
    toyorm.ModelDefault
    Name    string `toyorm:"unique index"`
    Age     int
    Sex     string
    Detail  *UserDetail
    Friends []*User
    Blog    []Blog
}

// now custom relation field is MainID
brick = brick.Preload(Offsetof(User{}.Blog)).Enter()
brick = brick.Preload(Offsetof(User{}.Detail)).Enter()
```
