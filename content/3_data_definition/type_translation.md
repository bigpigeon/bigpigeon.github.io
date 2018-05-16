+++
title = "Type Translate"
description = "how to connection database"
weight=2
+++


if sql type is null, toyorm will ignore it in Sql Operation


you can use **\<type:sql_type\>** tag to declaration field sql type


the following Go type will auto declaration it's sql type


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