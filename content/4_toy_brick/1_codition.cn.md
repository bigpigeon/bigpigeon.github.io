+++
title = "Where条件"
description = "where usage"

+++

where 会删除旧的条件并创建新的

    brick.Where(<expr>, <Key>, [value])

whereGroup同上，它可以同时增加多个条件并用And/Or相连

    brick.WhereGroup(<expr>, <group>)

conditions也会把整个条件复制过来并删除旧的条件

    brick.Conditions(<toyorm.Search>)

可以使用And/Or方法去链接新的条件

    brick.Or().Condition(<expr>, <Key>, [value])
    brick.Or().ConditionGroup(<expr>, <group>)
    brick.And().Condition(<expr>, <Key>, [value])
    brick.And().ConditionGroup(<expr>, <group>)

And/Or方法 后置 conditions 将会使用And/Or方法去链接新的条件

    brick.Or().Conditions(<toyorm.Search>)
    brick.And().Conditions(<toyorm.Search>)

### 表达式和数据库的关系

SearchExpr        |  to sql      | example
------------------|--------------|:----------------
ExprAnd           | AND          | brick.WhereGroup(ExprAnd, Product{Name:"food one", Count: 4}) // WHERE name = "food one" AND Count = 4
ExprOr            | OR           | brick.WhereGroup(ExprOr, Product{Name:"food one", Count: 4}) // WHERE name = "food one" OR Count = "4"
ExprEqual         | =            | brick.Where(ExprEqual, OffsetOf(Product{}.Name), "food one") // WHERE name = "find one"
ExprNotEqual      | <>           | brick.Where(ExprNotEqual, OffsetOf(Product{}.Name), "food one") // WHERE name <> "find one"
ExprGreater       | >            | brick.Where(ExprGreater, OffsetOf(Product{}.Count), 3) // WHERE count > 3
ExprGreaterEqual  | >=           | brick.Where(ExprGreaterEqual, OffsetOf(Product{}.Count), 3) // WHERE count >= 3
ExprLess          | <            | brick.Where(ExprLess, OffsetOf(Product{}.Count), 3) // WHERE count < 3
ExprLessEqual     | <=           | brick.Where(ExprLessEqual, OffsetOf(Product{}.Count), 3) // WHERE count <= 3
ExprBetween       | Between      | brick.Where(ExprBetween, OffsetOf(Product{}.Count), [2]int{2,3}) // WHERE count BETWEEN 2 AND 3
ExprNotBetween    | NOT Between  | brick.Where(ExprNotBetween, OffsetOf(Product{}.Count), [2]int{2,3}) // WHERE count NOT BETWEEN 2 AND 3
ExprIn            | IN           | brick.Where(ExprIn, OffsetOf(Product{}.Count), []int{1, 2, 3}) // WHERE count IN (1,2,3)
ExprNotIn         | NOT IN       | brick.Where(ExprNotIn, OffsetOf(Product{}.Count), []int{1, 2, 3}) // WHERE count NOT IN (1,2,3)
ExprLike          | LIKE         | brick.Where(ExprLike, OffsetOf(Product{}.Name), "one") // WHERE name LIKE "one"
ExprNotLike       | NOT LIKE     | brick.Where(ExprNotLike, OffsetOf(Product{}.Name), "one") // WHERE name NOT LIKE "one"
ExprNull          | IS NULL      | brick.Where(ExprNull, OffsetOf(Product{}.DeletedAt)) // WHERE DeletedAt IS NULL
ExprNotNull       | IS NOT NULL  | brick.Where(ExprNotNull, OffsetOf(Product{}.DeletedAt)) // WHERE DeletedAt IS NOT NULL



limit & offset

```golang
brick := brick.Offset(2).Limit(2)
// LIMIT 2 OFFSET 2
```


order by

```golang
brick = brick.OrderBy(Offsetof(Product{}.Name))
// ORDER BY name
```

order by desc

```golang
brick = brick.OrderBy(brick.ToDesc(Offsetof(Product{}.Name)))
// ORDER BY name DESC
```

group by

```golang
// 定义用于group by 的结构体
type ProductGroup struct {
     Tag       string
     KindCount int `toyorm:"column:COUNT(*)"`
}

// implement toyorm.tabler for custom table name  
func (p ProductGroup) TableName() string {
     return toyorm.ModelName(reflect.TypeOf(Product{}))
}

...

var tab ProductGroup
brick := toy.Model(&tab).Debug().GroupBy(Offsetof(tab.Tag))
var data []ProductGroup
brick.Find(&data)
// SELECT tag,COUNT(*) FROM `product`   GROUP BY tag 
```
