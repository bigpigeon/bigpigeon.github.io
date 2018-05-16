+++
title = "Engine"
description = "toyorm engine"
weight=2
alwaysopen = true
+++

toyorm need use ["database/sql"](https://golang.org/pkg/database/sql/) package to operation database


it's provides a generic interface around SQL (or SQL-like) databases.


this package must be used in conjunction with a [database driver](https://golang.org/s/sqldrivers)


toyorm only support following database driver, let's see how to use it 


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

{{% code theme="info" header="create Toy object" %}}
```golang
// if database is mysql, make sure your mysql have toyorm_example schema
toy, err = toyorm.Open("mysql", "root:@tcp(localhost:3306)/toyorm_example?charset=utf8&parseTime=True")
// if database is sqlite3
toy,err = toyorm.Open("sqlite3", "toyorm_test.db")
// when database is postgres
toy, err = toyorm.Open("postgres", "user=postgres dbname=toyorm sslmode=disable")
```
{{% /code %}}