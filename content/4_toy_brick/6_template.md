+++
title = "Template"
+++



use template exec to replace default exec


now template only support Insert/Save/Update/Find

##### Custom insert

```golang
data := Product{
    Name:  "bag",
    Price: 9999,
    Count: 2,
    Tag:   "container",
}
result, err := brick.Template("INSERT INTO $ModelName($Columns) Values($Values)").Insert(&data)
// INSERT INTO product(created_at,updated_at,deleted_at,name,price,count,tag) Values(?,?,?,?,?,?,?) args:["2018-04-01T17:05:48.927499+08:00","2018-04-01T17:05:48.927499+08:00",null,"bag",9999,2,"container"]
```

##### Custom find

```golang
var data Product
// if driver is mysql use "USE INDEX" replace "INDEXED BY"
result, err := brick.Template("SELECT $Columns FROM $ModelName INDEXED BY idx_product_name $Conditions").
    Where("=", Offsetof(Product{}.Name), "bag").Find(&data)
// SELECT id,created_at,updated_at,deleted_at,name,price,count,tag FROM product INDEXED BY idx_product_name  WHERE deleted_at IS NULL AND name = ? LIMIT 1  args:["bag"]
```


##### Custom update

set count = count + 2

```golang
result, err := brick.Template(fmt.Sprintf("UPDATE $ModelName SET $Values,$FN-Count = $0x%x + ? $Conditions", Offsetof(Product{}.Count)), 2).
	Where("=", Offsetof(Product{}.Name), "bag").Update(&Product{Price: 200})
// UPDATE product SET updated_at = ?,price = ?,count = count + ?  WHERE deleted_at IS NULL AND name = ?  args:["2018-04-01T17:50:35.205377+08:00",200,2,"bag"]
```

##### Placeholder

follower placeholder use in template example


two "field replace" placeholder

1. $FN- will convert struct field name to table field name e.g $FN-Name => name
2. $0x will convert struct field offset to table field name e.g $0x58 => Count

action \\  placeholder | $ModelName | $Columns    | $Values                | $Conditions
-----------------------|------------|-------------|------------------| -----------|
Find                   | product    | id,data,... | -               |  WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Insert                 | product    | id,data,... | ?,?,...         | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Save                   | product    | id,data,... | ?,?,...           | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Update                 | product    | id,data,... | id = ?,data = ?,...    | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
