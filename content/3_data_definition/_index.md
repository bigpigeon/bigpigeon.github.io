+++
title = "Data Definition"
description = "data definition"
weight=3
alwaysopen = true
+++

toyorm use struct type to declaration table infomation


inherit toyorm.ModelDefault will add ID,CreatedAt,UpdatedAt,DeletedAt field


like this 

```golang
type Blog struct {
     toyorm.ModelDefault
     UserID  uint   `toyorm:"index"`
     Title   string `toyorm:"index"`
     Content string
}
```


if you want define custom field, implement sql.Scan and sql.Value interface{} in field type and declaration its sql type in **type** tag


```golang
// e.g create custom field
type Extra map[string]interface{}

// implement sql.Scaner interface{}
func (e Extra) Scan(value interface{}) error {
     switch v := value.(type) {
     case string:
          return json.Unmarshal([]byte(v), e)
     case []byte:
          return json.Unmarshal(v, e)
     default:
          return errors.New("not support type")
     }
}

// implement sql.Valuer interface{}
func (e Extra) Value() (driver.Value, error) {
     return json.Marshal(e)
}

type UserDetail struct {
     ID       int  `toyorm:"primary key;auto_increment"`
     UserID   uint `toyorm:"index"`
     MainPage string
     Extra    Extra `toyorm:"type:VARCHAR(1024)"`// field with map type was not match in sql, need declaration its type
}

```

define struct with group by

```golang
// use by group by
type ProductGroup struct {
     Tag       string
     KindCount int `toyorm:"column:COUNT(*)"`
}

// implement toyorm.tabler for custom table name  
func (p ProductGroup) TableName() string {
     return toyorm.ModelName(reflect.TypeOf(Product{}))
}
```

define struct with its preload data

```golang
type User struct {
     toyorm.ModelDefault
     Name    string `toyorm:"unique index"`
     Age     int
     Sex     string
     Detail  *UserDetail // UserDetail type has UserId field ,it match OneToOne auto-preload condition
     Friends []*User // Friends is slice object,and it element type have UserId field, it match OneToMany auto-preload condition 
     Blog    []Blog // same as Detail field, toyorm will preload it's data when call ToyBrick.Preload
}
```




