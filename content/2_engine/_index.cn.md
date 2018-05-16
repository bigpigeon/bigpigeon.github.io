+++
title = "引擎"
description = "如何创建一个Toy对象"
weight=2
alwaysopen = true
+++

toyorm 需要使用 ["database/sql"](https://golang.org/pkg/database/sql/) 库去操作数据库


它为SQL(或者 类SQL)数据库提供了一个通用的接口


所以这个库必须和以下库一并使用[database driver](https://golang.org/s/sqldrivers)


而toyorm 只支持以下几种 database driver, 让我们看看如何使用它


{{% code theme="info" header="import driver" %}}
```golang
// if database is mysql 
_ "github.com/go-sql-driver/mysql"
// if database is sqlite3
_ "github.com/mattn/go-sqlite3"
// when database is postgres
_ "github.com/lib/pq"
```
{{% /code %}}

{{% code theme="info" header="创建Toy对象" %}}
```golang
// if database is mysql, make sure your mysql have toyorm_example schema
toy, err = toyorm.Open("mysql", "root:@tcp(localhost:3306)/toyorm_example?charset=utf8&parseTime=True")
// if database is sqlite3
toy,err = toyorm.Open("sqlite3", "toyorm_test.db")
// when database is postgres
toy, err = toyorm.Open("postgres", "user=postgres dbname=toyorm sslmode=disable")
```
{{% /code %}}