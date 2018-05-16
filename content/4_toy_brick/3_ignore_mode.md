+++
title = "Ignore Zero Value"
+++

when I Update or Search with struct that have some zero value, did I update it ?


use IgnoreMode to differentiate what zero value should update

```golang
brick = brick.IgnoreMode(toyorm.Mode("Update"), toyorm.IgnoreZero ^ toyorm.IgnoreZeroLen)
// ignore all zeor value but excloud zero len slice
// now field = []int(nil) will ignore when update
// but field = []int{} will update when update
// now field = map[int]int(nil) will ignore when update
// but field = map[int]int{} will update when update
```

In default

Operation | Mode       | affect
----------|------------|--------
Insert    | IgnoreNo   | brick.Insert(<struct>)
Replace   | IgnoreNo   | brick.Replace(<struct>)
Condition | IgnoreZero | brick.WhereGroup(ExprAnd/ExprOr, <struct>)
Update    | IgnoreZero | brick.Update(<struct>)

**All of IgnoreMode**

mode              |  effective
------------------|---------------
IgnoreFalse       | ignore field type is bool and value is false
IgnoreZeroInt     | ignore field type is int/uint/uintptr(incloud their 16,32,64 bit type) and value is 0
IgnoreZeroFloat   | ignore field type is float32/float64 and value is 0.0
IgnoreZeroComplex | ignore field type is complex64/complex128 and value is 0 + 0i
IgnoreNilString   | ignore field type is string and value is ""
IgnoreNilPoint    | ignore field type is point/map/slice and value is nil
IgnoreZeroLen     | ignore field type is map/array/slice and len = 0
IgnoreNullStruct  | ignore field type is struct and value is zero value struct e.g type A struct{A string,B int}, A{"", 0} will be ignore
IgnoreNil         | ignore with IgnoreNilPoint and IgnoreZeroLen
IgnoreZero        | ignore all of the above