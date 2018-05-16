+++
title = "Scope"
+++

使用 scope 创建一个自定义的构建函数


```golang
// desc 所有 order by 字段
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