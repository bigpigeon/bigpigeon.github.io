---
layout: post
title:  "如何在python上使用postgresql"
date:   2016-03-07 10:30:00
categories: 笔记 
excerpt: 简单介绍postgresql部署和psycopy的使用
---

- 本文使用的是postgresql 9.3 基于docker ubuntu

- 首先postgresql的安装,这里我使用了自己build一个Dockerfile
- 我的Dockerfile:

```bash
FROM ubuntu:latest
MAINTAINER bigpigeon <3283273530@qq.com>

RUN apt-get -yqq update
RUN apt-get install -y postgresql-9.3

USER postgres 
RUN touch /var/lib/postgresql/.psql_history 
RUN /etc/init.d/postgresql start &&\
    psql --command "ALTER USER postgres WITH SUPERUSER PASSWORD '123456';" &&\
    createdb -O postgres postgres
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf
	
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]

EXPOSE 5432
```

- 因为postgresql不能用root启动，所以我们要改用postgres帐户，该帐户是在postgresql安装时自动创建的

- build docker

```bash
docker build -t postgres:own .
```

- 跑一个docker 进程

```bash
docker run --name postgres -d -p 15432:5432 postgres:own 
```

- 进入该进程

```bash
docker exec -i -t postgres /bin/bash
```

- 之后来查看一下postgres启动的进程和端口


```bash
//在docker中比较环境干净，所以没必要用grep筛选
# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
postgres     1  0.0  2.0 244920 20576 ?        Ss   06:05   0:00 /usr/lib/postgresql/9.3/bin/postgres -D /var/lib/pos
postgres     9  0.0  0.3 244920  3456 ?        Ss   06:05   0:00 postgres: checkpointer process
postgres    10  0.0  0.4 244920  4608 ?        Ss   06:05   0:00 postgres: writer process
postgres    11  0.0  0.3 244920  3456 ?        Ss   06:05   0:00 postgres: wal writer process
postgres    12  0.0  0.5 245672  5904 ?        Ss   06:05   0:00 postgres: autovacuum launcher process
postgres    13  0.0  0.3 100596  3396 ?        Ss   06:05   0:00 postgres: stats collector process
postgres    14  0.0  0.3  18228  3228 ?        Ss   06:09   0:00 /bin/bash
postgres    22  0.0  0.2  15572  2084 ?        R+   06:14   0:00 ps aux
# netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.1:5432          0.0.0.0:*               LISTEN
tcp6       0      0 ::1:5432                :::*                    LISTEN
udp6       0      0 ::1:59218               ::1:59218               ESTABLISHED
Active UNIX domain sockets (servers and established)
Proto RefCnt Flags       Type       State         I-Node   Path
unix  2      [ ACC ]     STREAM     LISTENING     26950    /var/run/postgresql/.s.PGSQL.5432
```

### 连接控制台

- 用psql来连接postgresql服务端(记得第一时间改密码)

```bash
$ psql -U postgres -h 127.0.0.1 -p 15432
=# \password postgres
=# \q
```

- -U 指定登录用户 -d 指定数据库 -h -p 指定登录的主机和端口，更详细的参数可用--help查询

### 通过postgresql控制台创建用户



```bash
$ psql -U postgres -h 127.0.0.1 -p 15432
=# \password postgres
=# CREATE USER dbuser WITH PASSWORD 'password';
=# CREATE DATABASE exampledb OWNER dbuser;
=# GRANT ALL PRIVILEGES ON DATABASE exampledb to dbuser;
=# \q
```


### 数据库命令

```bash
# psql -U dbuser -d exampledb -h 127.0.0.1 -p 15432
// \password [username]: 修改[某用户]密码,只有超级用户才可以改其他人的密码
=> \password
Enter new password:
Enter it again:

// \encoding [ENCODING]: 显示[修改]客户端的编码
=> \encoding
UTF8

// \h [NAME]: 查看 所有[某条] SQL命令的解释，比如\h select。
=> \h select
Command:     SELECT
Description: retrieve rows from a table or view
Syntax:
[ WITH [ RECURSIVE ] with_query [, ...] ]
...
// \l [PATTERN]: 列出所有[某条] 数据库
=> \l
                             List of databases
   Name    |  Owner   | Encoding  | Collate | Ctype |   Access privileges
-----------+----------+-----------+---------+-------+-----------------------
 exampledb | dbuser   | SQL_ASCII | C       | C     | =Tc/dbuser           +
           |          |           |         |       | dbuser=CTc/dbuser
 postgres  | postgres | SQL_ASCII | C       | C     |
 template0 | postgres | SQL_ASCII | C       | C     | =c/postgres          +
           |          |           |         |       | postgres=CTc/postgres
 template1 | postgres | SQL_ASCII | C       | C     | =c/postgres          +
           |          |           |         |       | postgres=CTc/postgres
(4 rows)

// \c [database_name]：连接其他数据库。
=> \c postgres
SSL connection (cipher: DHE-RSA-AES256-GCM-SHA384, bits: 256)
You are now connected to database "postgres" as user "dbuser".

// \d [table_name]：列出所有[某一张]表格的结构。
// 因为目前还没建表，所以只有一句告警
=> \d
No relations found.
// \du[+] [PATTERN]：列出所有[某]用户。
=> \du
                             List of roles
 Role name |                   Attributes                   | Member of
-----------+------------------------------------------------+-----------
 dbuser    |                                                | {}
 postgres  | Superuser, Create role, Create DB, Replication | {}

// \conninfo：列出当前数据库和连接的信息。
=> \conninfo
You are connected to database "postgres" as user "dbuser" on host "127.0.0.1" at port "15432".
SSL connection (cipher: DHE-RSA-AES256-GCM-SHA384, bits: 256)

// 更多命令可以通过\?查看
=> \?
...
```


### 数据库操作

- 语法和mysql相似,可通过\h去查看
- 下面我将操作数据库语法去建表，插数据等操作

```bash
=> CREATE TABLE user_person(name VARCHAR(20), entry DATE);
CREATE TABLE
=> INSERT INTO user_person(name, entry) VALUES('jia', '2016-2-28');
INSERT 0 1
=> ALTER TABLE user_person ADD job VARCHAR(100);
ALTER TABLE
=> INSERT INTO user_person(name, entry) VALUES('jib', '2016-2-29');
INSERT 0 1
=> UPDATE user_person set job = 'backend develop' WHERE name = 'jia';
UPDATE 1
=> UPDATE user_person set job = 'frontend develop' WHERE name = 'jib';
UPDATE 1
=> ALTER TABLE user_person ALTER COLUMN job SET NOT NULL ;
ALTER TABLE
=> INSERT INTO user_person(name, entry) VALUES('jic', '2016-3-1');
ERROR:  null value in column "job" violates not-null constraint
DETAIL:  Failing row contains (jic, 2016-03-01, null).
=> SELECT * FROM user_person;
 name |   entry    |       job
------+------------+------------------
 jia  | 2016-02-28 | backend develop
 jib  | 2016-02-29 | frontend develop
(2 rows)
```

### 如何在python上操作postgresql

- [官网wiki](https://wiki.postgresql.org/wiki/Python) 给出了6种python 版本的客户端
- 我这里用的是[Psycopg2](http://initd.org/psycopg/docs/)因为它是这6个客户端中唯二使用LGPL许可证的，并且最近还有更新维护

- 第一部分 安装


ubuntu:

> 只需要apt-get install python-psycopg2就ok

windows:

> pip install psycopg2

> 官网建议用easy_install 但这种安装方法在import是会提示缺少DLL

- 第二部分 操作数据库

```python
>>> import psycopg2
>>> import datetime

# 连接数据库
>>> conn = psycopg2.connect(
    host="192.168.56.102",
    port="15432",
    password='passwd',
    dbname="exampledb",
    user="dbuser"
)
# 创建一个游标去执行数据库操作
>>> cur = conn.cursor()

# 插入一条数据到user_person表
>>> cur.execute(
    "INSERT INTO user_person(name, entry, job) VALUES (%s, %s, %s)",
    ("jic", datetime.date(2016, 3, 1), "full-stack develop")
)

# 执行查询语句
>>> cur.execute("SELECT * FROM user_person;")

# 把查询的结果取出来
>>> cur.fetchall()
[('jia', datetime.date(2016, 2, 28), 'backend develop'), ('jib', datetime.date(2016, 2, 29), 'frontend develop'), ('jic', datetime.date(2016, 3, 1), 'full-stack develop')]

# 确保所有命令执行完成
>>> conn.commit()

# 关闭游标和数据库连接
>>> cur.close()
>>> conn.close()
```


- 上面就是一次完整的数据库操作流程,这里有几点需要注意:
    - execute的 VALUES 后面必须使用(%s,...)的格式
    - VALUES后面的占位符支持 (%(name)s,...) 参数则为{'name': value,...}这种格式,这样可以保证不用在输入重复的参数
    - 占位符必须是 %s，不能是%d 或%f
    - 参数的数据结构必须是list或tuple


- Python类型和SQL类型对照
http://initd.org/psycopg/docs/usage.html#adaptation-of-python-values-to-sql-types












