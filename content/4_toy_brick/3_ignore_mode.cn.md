+++
title = "空值忽略"
+++


当我使用struct参数去Update或Where操作是，是否应该忽略它的空值？


使用 IgnoreMode方法去确认哪些空值需要被更新

```golang
brick = brick.IgnoreMode(toyorm.Mode("Update"), toyorm.IgnoreZero ^ toyorm.IgnoreZeroLen)
// 忽略所有空值但不包括len为0的容器
// []int(nil) 字段会被忽略
// []int{} 字段不会被忽略
// map[int]int(nil) 字段会被忽略
// map[int]int{} 字段不会被忽略
```

默认空值忽略模式

Operation | Mode       | affect
----------|------------|--------
Insert    | IgnoreNo   | brick.Insert(<struct>)
Replace   | IgnoreNo   | brick.Replace(<struct>)
Condition | IgnoreZero | brick.WhereGroup(ExprAnd/ExprOr, <struct>)
Update    | IgnoreZero | brick.Update(<struct>)

**所有空值忽略模式**

mode              |  effective
------------------|---------------
IgnoreFalse       | 忽略所有bool类型中的false
IgnoreZeroInt     | 忽略所有int/uint/uintptr(incloud their 16,32,64 bit type)中的0
IgnoreZeroFloat   | 忽略所有float32/float64 类型中的0.0
IgnoreZeroComplex | 忽略所有complex64/complex128 中的0 + 0i
IgnoreNilString   | 忽略所有string类型中的 ""
IgnoreNilPoint    | 忽略所有 point/map/slice类型中的nil
IgnoreZeroLen     | 忽略所有 map/array/slice类型中的len=0的值
IgnoreNullStruct  | 忽略所有 struct 中的空结构体 e.g type A struct{A string,B int}, A{"", 0} 将被忽略
IgnoreNil         | 忽略 IgnoreNilPoint 和 IgnoreZeroLen
IgnoreZero        | 忽略以上所有模式