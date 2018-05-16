+++
title = "类型转换"
description = "how to connection database"
weight=2
+++


如果sql类型为空，toyorm在操作操作数据库时会忽略它


你可以使用 **\<type:sql_type\>** tag去声明字段的 sql 类型


下面这些go类型会自动声明它的sql类型


Go Type | sql type
:--------|:-----------
bool    | BOOLEAN
int8,int16,int32,uint8,uint16,uint32| INTEGER
int64,uint64,int,uint| BIGINT
float32,float64| FLOAT
string  | VARCHAR(255)
time.Time | TIMESTAMP
[]byte    | VARCHAR(255)
sql.NullBool | BOOLEAN
sql.NullInt64 | BIGINT
sql.NullFloat64 | FLOAT
sql.NullString | VARCHAR(255)
sql.RawBytes | VARCHAR(255)