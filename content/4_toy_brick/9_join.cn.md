+++
title = "Join"
+++


是用Join查询可以保证所有记录都只需要一条查询

##### Model Define

使用join的tag声明关联关联字段, join tag 的值必须和容器字段的名一样

```golang
type Extra map[string]interface{}

func (e *Extra) Scan(value interface{}) error {
	switch v := value.(type) {
	case string:
		return json.Unmarshal([]byte(v), e)
	case []byte:
		return json.Unmarshal(v, e)
	default:
		return errors.New("not support type")
	}
}

func (e Extra) Value() (driver.Value, error) {
	return json.Marshal(e)
}

type Color struct {
	Name string `toyorm:"primary key;join:ColorDetail"`
	Code int32
}

type Comment struct {
	toyorm.ModelDefault
	ProductDetailProductID uint32 `toyorm:"index"`
	Data                   string `toyorm:"type:VARCHAR(1024)"`
}

type ProductDetail struct {
	ProductID  uint32 `toyorm:"primary key;join:Detail"`
	Title      string
	CustomPage string `toyorm:"type:text"`
	Extra      Extra  `toyorm:"type:VARCHAR(2048)"`
	Color      string `toyorm:"join:ColorDetail"`
	ColorJoin  Color  `toyorm:"alias:ColorDetail"`
	Comment    []Comment
}

type Product struct {
	ID        uint32     `toyorm:"primary key;auto_increment;join:Detail"`
	CreatedAt time.Time  `toyorm:"NULL"`
	DeletedAt *time.Time `toyorm:"NULL"`
	Name      string
	Count     int
	Price     float64
	Detail    *ProductDetail
}
```

##### Join in Find

使用Swap方法可以回到上一个ToyBrick，和Preload中的Enter类似

```golang
brick := toy.Model(&tab).Debug().
    Join(Offsetof(tab.Detail)).
    Join(Offsetof(detailTab.ColorJoin)).Swap().Swap()
var scanData []Product
result, err = brick.Find(&scanData)
// SELECT m.id,m.created_at,m.deleted_at,m.name,m.count,m.price,m_0.product_id,m_0.title,m_0.custom_page,m_0.extra,m_0.color,m_0_0.name,m_0_0.code FROM `product` as `m` JOIN `product_detail` AS `m_0` ON m.id = m_0.product_id JOIN `color` AS `m_0_0` ON m_0.color = m_0_0.name   WHERE m.deleted_at IS NULL
```

使用Join交换当前的Model并增加一些Where条件

```golang
// where Product.Name = "clean stick" or Color.Name = "black"
brick := toy.Model(&tab).Debug().Where("=", Offsetof(tab.Name), "clean stick").
    Join(Offsetof(tab.Detail)).
    Join(Offsetof(detailTab.ColorJoin)).Or().Condition("=", Offsetof(colorTab.Name), "black").
    Swap().Swap()
var scanData []Product
result, err = brick.Find(&scanData)
// SELECT m.id,m.created_at,m.deleted_at,m.name,m.count,m.price,m_0.product_id,m_0.title,m_0.custom_page,m_0.extra,m_0.color,m_0_0.name,m_0_0.code FROM `product` as `m` JOIN `product_detail` AS `m_0` ON m.id = m_0.product_id JOIN `color` AS `m_0_0` ON m_0.color = m_0_0.name   WHERE m.deleted_at IS NULL AND (m.name = ? OR m_0_0.name = ?)  args:["clean stick","black"]
```

增加一些OrderBy

```golang
// where Product.Name = "clean stick" or Color.Name = "black"
brick := toy.Model(&tab).Debug().
    Join(Offsetof(tab.Detail)).
    Join(Offsetof(detailTab.ColorJoin)).OrderBy(Offsetof(colorTab.Name)).
    Swap().Swap()
var scanData []Product
result, err = brick.Find(&scanData)
// SELECT m.id,m.created_at,m.deleted_at,m.name,m.count,m.price,m_0.product_id,m_0.title,m_0.custom_page,m_0.extra,m_0.color,m_0_0.name,m_0_0.code FROM `product` as `m` JOIN `product_detail` AS `m_0` ON m.id = m_0.product_id JOIN `color` AS `m_0_0` ON m_0.color = m_0_0.name   WHERE m.deleted_at IS NULL ORDER BY m_0_0.name
```

也可以使用GroupBy，这里不做演示了

##### Preload On Join

Preload 方法也可以工作在Join之下，这2个方法是对称的

```golang
brick := toy.Model(&tab).Debug().
    Join(Offsetof(tab.Detail)).Preload(Offsetof(detailTab.Comment)).Enter().
    Join(Offsetof(detailTab.ColorJoin)).Swap().Swap()
var scanData []Product
result, err = brick.Find(&scanData)
// SELECT m.id,m.created_at,m.deleted_at,m.name,m.count,m.price,m_0.product_id,m_0.title,m_0.custom_page,m_0.extra,m_0.color,m_0_0.name,m_0_0.code FROM `product` as `m` JOIN `product_detail` AS `m_0` ON m.id = m_0.product_id JOIN `color` AS `m_0_0` ON m_0.color = m_0_0.name   WHERE m.deleted_at IS NULL
// SELECT id,created_at,updated_at,deleted_at,product_detail_product_id,data FROM `comment`   WHERE deleted_at IS NULL AND product_detail_product_id IN (?,?,?)  args:[1,2,3]
```
