+++
title = "模板"
+++


使用 template 语句代替默认SQL语句


目前模板只支持 Insert/Save/Update/Find

##### 自定义插入

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

##### 自定义查找

```golang
var data Product
// if driver is mysql use "USE INDEX" replace "INDEXED BY"
result, err := brick.Template("SELECT $Columns FROM $ModelName INDEXED BY idx_product_name $Conditions").
    Where("=", Offsetof(Product{}.Name), "bag").Find(&data)
// SELECT id,created_at,updated_at,deleted_at,name,price,count,tag FROM product INDEXED BY idx_product_name  WHERE deleted_at IS NULL AND name = ? LIMIT 1  args:["bag"]
```


##### 自定义更新

set count = count + 2

```golang
result, err := brick.Template(fmt.Sprintf("UPDATE $ModelName SET $Values,$FN-Count = $0x%x + ? $Conditions", Offsetof(Product{}.Count)), 2).
	Where("=", Offsetof(Product{}.Name), "bag").Update(&Product{Price: 200})
// UPDATE product SET updated_at = ?,price = ?,count = count + ?  WHERE deleted_at IS NULL AND name = ?  args:["2018-04-01T17:50:35.205377+08:00",200,2,"bag"]
```

##### 占位符

以下占位符将会在模板中使用


2种字段相关占位符

1. $FN- 会把字段名转换成表字段名 e.g $FN-Name => name
2. $0x 会把字段偏移量转换成表字段名 e.g $0x58 => Count

action \\  placeholder | $ModelName | $Columns    | $Values                | $Conditions
-----------------------|------------|-------------|------------------| -----------|
Find                   | product    | id,data,... | -               |  WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Insert                 | product    | id,data,... | ?,?,...         | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Save                   | product    | id,data,... | ?,?,...           | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
Update                 | product    | id,data,... | id = ?,data = ?,...    | WHERE ... ORDER BY ... GROUP BY ... LIMIT ... OFFSET ...
