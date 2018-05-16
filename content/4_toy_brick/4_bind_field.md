+++
title = "Bind Field"
+++

use bind fields method to rule which field in sql operation


if bind fields, skill IgnoreMode 


BindDefaultFields work on all Mode 

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

