+++
title = "字段绑定"
+++

使用字段绑定方法去选择哪些字段会被接下来的操作用到


如果使用了字段绑定，IgnoreMode将失效


BindDefaultFields 工作与所有场景下

```golang
{
    var p Product
    result, err := brick.BindDefaultFields(Offsetof(p.Price), Offsetof(p.UpdatedAt)).Update(&Product{
        Price: 0,
    })
    // UPDATE `product` SET price=?,updated_at=?  WHERE deleted_at IS NULL  args:[0,"2018-05-14T12:16:21.731031534+08:00"] 
   // process error
   ...
}
var products []Product
result, err = brick.Find(&products)
// process error
...

for _, p := range products {
    fmt.Printf("product name %s, price %v\n", p.Name, p.Price)
}
```
