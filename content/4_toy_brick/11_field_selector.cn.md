+++
title = "字段选择器"
+++

toyorm 支持多种方式去获取Model的字段：通过struct,字段名或者字段偏移量


你可以通过任意一种方式去获取它 e.g

{{% code theme="info" header="insert" %}}
```golang
// use struct
// insert with struct
product := Product{
	Name: "sth",
	Price: 22,
}
brick.Insert(&product)
// or insert with name map
product := map[string]interface{}{
	"Name": "sth",
	"Price": 22,
}
brick.Insert(&product)
// or insert with offsetof map, in this method, you need import "unsafe" to get it's Offsetof function
product := map[uintptr]interface{}{
	Offsetof(Product{}.Name): "sth",
	Offsetof(Product{}.Price): 22,
}
brick.Insert(&product)
```
{{% /code %}}

{{% code theme="info" header="where" %}}
```golang
// select field with name string
brick = brick.Where(">", "Price", 22)
// select field with with offsetof, you need import "unsafe" to get it's Offsetof function
brick = brick.Where(">", Offsetof(Product{}.Price), 22)
```
{{% /code %}}

数据操作支持的字段

operation  \\  selector | OffsetOf | Name string | map\[OffsetOf\]interface{} | map\[string\]interface{} | struct |
--------------------|----------|-----------------|--------------------------------|--------------------------|--------|
Update              | no       | no              | yes                            | yes                      | yes
Insert              | no       | no              | yes                            | yes                      | yes
Save                | no       | no              | yes                            | yes                      | yes
Where & Conditions  | yes      | yes             | no                             | no                       | no
WhereGroup & ConditionGroup | no |  no           | yes                            | yes                      | yes
BindFields          | yes      | yes             | no                             | no                       | no
Preload & Custom Preload | yes | yes             | no                             | no                       | no
OrderBy             | yes      | yes             | no                             | no                       | no
Find                | no       | no              | no                             | no                       | yes
