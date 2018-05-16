+++
title = "Preload"
+++


preload need have relation field and container field(ManyToMany just need container field)


relations field is used to link the main record and sub record


relation field can be Foreign key, but not recommend


container field is used to save sub record, it does not belong to a table field

##### One to one

relation field at sub model


relation field name must be main model type name + main model primary key name

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

relation field at main model


relation field name must be container field name + sub model primary key name

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

relation field at sub model



relation field name must be main model type name + main model primary key name


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

many to many not need to specified the relation field,it relation field at middle model

```
type User struct {
    toyorm.ModelDefault
    // container field
    Friends    []*User
}
```

##### Load preload

when you finish model definition, it time to load preload

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


if you not like relation field name rule,use custom module to create it

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

or use tag declaration 

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