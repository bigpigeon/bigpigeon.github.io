+++
title = "Scope"
+++

use scope to make custom build


```golang
// desc all order by fields
brick.Scope(func(t *ToyBrick) *ToyBrick{

    newOrderBy := make([]*ModelFields, len(t.orderBy))
    for i, f := range t.orderBy {
        newOrderBy = append(newOrderBy, t.ToDesc(f))
    }
    newt := *t
    newt.orderBy = newOrderBy
    return &newt
})
```