+++
menu = "main"
date = "2016-03-13T10:30:00+08:00"
title = "postgresql类型"
Description = ""
Tags = [
  "Development",
  "Postgresql",
]
Categories = [
  "开发",
]

+++

- postgresql支持的类型相当的多,配合postgresql的函数就已经可以满足很多业务的需求了

- 但是繁多的类型也导致了postgresql的学习成本和复杂度的问题

- 这里我来做个笔记简单讲讲postgresql的数据类型有哪些和如何用好这些类型

- PS:以下内容都基于postgresql 9.3

- TODO:有些类型的例子和介绍还没写完，以后再补上

<!--more-->
### 基本类型


| 名字          | 尺寸       | 描述                    |
| ------------- | ----------| ----------------------- |
| smallint      | 2bytes     | 小范围的整数            |
| integer       | 4bytes     | 典型整数                |
| bigint        | 8bytes     | 大范围的整数            |
| decimal       | 可变       | 用户指定空间,精确分数   |
| numeric       | 可变       | 用户指定空间的精确分数  |
| real          | 4bytes     | 不精确浮点数            |
| double-precision | 8bytes  | 不精确浮点数            |
| smallserial   | 2bytes     | 小范围自增整数          |
| serial        | 4bytes     | 普通范围自增整数        |
| bigserial     | 8bytes     | 大范围自增整数          |

### 金融类型

| 名字          | 尺寸       | 描述     |
| ------------- |:----------:| --------|
| money         | 8bytes     | 货币类型 |

### 字符类型

| 名字                             | 尺寸                 |
| -------------------------------- | ------------------- |
| character varying(n), varchar(n) | 限制内的可变长度类型 |
| character(n), char(n)            | 固定长度             |
| text                             | 可变长度             |

### 二进制类型

| 名字          | 尺寸       | 描述                    |
| ------------- |:----------:| ----------------------- |
| binary        | 1-4bytes   | 可变长度的二进制字符串  |

### 时间类型

| 名字                               | 尺寸       | 描述                    |
| ---------------------------------- |:----------:| ----------------------- |
| timestamp[p] [ without time zone ] | 8bytes     | 包含时间和日期但没时区  |
| timestamp[p] with time zone        | 8bytes     | 包含时间日期和时区      |
| date                               | 4bytes     | 日期                    |
| time [ without time zone ]         | 8bytes     | 不包括日期的时间，无时区 |
| time with time zone                | 12bytes    | 不包含日期的时间，有时区 |
| interval                           | 16bytes    | 时间区间                |

### 布尔类型

| 名字          | 尺寸      |
| ------------- | ---------:|
| boolean       | 1bytes    |

### 枚举类型


``` sql
# 创建一个枚举类型并作为person表的current_mood字段
CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');
CREATE TABLE person (
    name text,
    current_mood mood
);
INSERT INTO person VALUES ('Moe', 'happy');
SELECT * FROM person WHERE current_mood = 'happy';
 name | current_mood
------+--------------
 Moe  | happy
(1 row)
```

### 几何学图形类型

| 名字      | 尺寸         | 描述                                  |
| --------- |:------------:| -------------------------------------:|
| point     | 16bytes      | 平面坐标 (x, y)                       |
| line      | 32bytes      | 直线 ((x1,y1), (x2,y2))               |
| lseg      | 32bytes      | 线段 ((x1,y1), (x2,y2))               |
| box       | 32bytes      | 一个方形盒子 ((x1,y1), (x2,y2))       |
| path      | 16+16n bytes | 闭合路径(类似于多边形) ((x1,y1),...)  |
| path      | 16+16n bytes | 开放路径 [(x1,y1),...]                |
| polygon   | 40+16n bytes | 多边形（类似于闭合路径） ((x1,y1),...) |
| circle    | 24 bytes     | 圆 <(x,y),r>

### 网络地址类型

| 名字      | 尺寸          | 描述                                  |
| --------- |:-------------:| -------------------------------------:|
| cidr      | 7 or 19 bytes | ipv4或ipv6网络
| inet      | 7 or 19 bytes | ipv4或ipv6地址
| macaddr   | 6bytes        | MAC地址

### 比特类型

- 只接受2进制数
- 有2种模式 BIT(n) 和BIT VARYING(n)
官方例子:

``` sql
CREATE TABLE test (a BIT(3), b BIT VARYING(5));
INSERT INTO test VALUES (B'101', B'00');
INSERT INTO test VALUES (B'10', B'101');
ERROR:  bit string length 2 does not match type bit(3)
INSERT INTO test VALUES (B'10'::bit(3), B'101');
SELECT * FROM test;
  a  |  b
-----+-----
 101 | 00
 100 | 101
```

### 文本查询类型

- tsvector
- tsquery


### UUID 类型

- UUID 可用来作为唯一标识

### XML 类型
xml data是用来存储xml格式的数据的，用text领域来存xml数据，想要使用该数据类型需要在安装时 configure --with-libxml
- xml用text领域来存xml数据

### json格式
json 也是用text来存储, 但json数据类型的好处在存储时会进行检测，保证每一个值都是一个有效的json值，它还能相对的支持一些函数
在用json时最好保证数据的编码和postgresql的一致

### 数组类型
演示创建一个带数组类型的表:

``` sql
CREATE TABLE sal_emp (
    name            text,
    pay_by_quarter  integer[],
    schedule        text[][]
);
```

插入数据

``` sql
INSERT INTO sal_emp
    VALUES ('Bill',
    '{10000, 10000, 10000, 10000}',
    '\{\{"meeting", "lunch"\}, \{"training", "presentation"\}\}');

INSERT INTO sal_emp
    VALUES ('Carol',
    '{20000, 25000, 25000, 25000}',
    '\{\{"breakfast", "consulting"\}, {"meeting", "lunch"\}\}');
```

查询数据

``` sql
SELECT * FROM sal_emp;
 name  |      pay_by_quarter       |                 schedule
-------+---------------------------+-------------------------------------------
 Bill  | {10000,10000,10000,10000} | \{\{meeting,lunch\},\{training,presentation\}\}
 Carol | {20000,25000,25000,25000} | \{\{breakfast,consulting\},\{meeting,lunch\}\}
(2 rows)
```



多重数据的尺寸必须是相同的，一个错误的例子

``` sql
INSERT INTO sal_emp
    VALUES ('Bill',
    '{10000, 10000, 10000, 10000}',
    '\{\{"meeting", "lunch"\}, \{"meeting"\}\}');
ERROR:  multidimensional arrays must have array expressions with matching dimensions
```

也可以使用 ARRAY构造语法

``` sql
INSERT INTO sal_emp
    VALUES ('Bill',
    ARRAY[10000, 10000, 10000, 10000],
    ARRAY[['meeting', 'lunch'], ['training', 'presentation']]);

INSERT INTO sal_emp
    VALUES ('Carol',
    ARRAY[20000, 25000, 25000, 25000],
    ARRAY[['breakfast', 'consulting'], ['meeting', 'lunch']]);
```

查询pay\_by\_quarter的第一个值和第二个值不相等的条目的名字


这里要注意 array的索引是从1开始的

``` sql
SELECT name FROM sal_emp WHERE pay_by_quarter[1] <> pay_by_quarter[2];
```

查询pay\_by\_quarter的第三个值

``` sql
SELECT pay_by_quarter[3] FROM sal_emp;
 pay_by_quarter
----------------
          10000
          25000
(2 rows)
```

查询schedule的多个值
> 这里注意postgresql的array中的切片和其他语言的也是不同的，它会返回[n:m]中的值并包括m的值
> 多重数组切片要全是切片不能[2][1:2]这种写法，而[1:2][2]这种写法会自动转成[1:2][1:2]

``` sql
SELECT schedule[1:2][1:1] FROM sal_emp WHERE name = 'Bill';
        schedule
-------------------------
 \{\{breakfast\},\{meeting\}\}
(1 row)

```

使用postgresql的内置函数查看某条数据的数组的长度

``` sql
SELECT array_dims(schedule) FROM sal_emp WHERE name = 'Carol';
 array_dims
------------
 [1:2][1:2]
(1 row)
```

可以使用array_upper和array_lower查看数组索引的最大值和最小值

```
SELECT array_upper(schedule, 1) FROM sal_emp WHERE name = 'Carol';

 array_upper
-------------
           2
(1 row)
```

array_length函数则是查看数组长度和上面那几类函数的使用方法一样


array_prepend/array_append 在数组前/后面加入元素


### **array_cat:**

|| 或修饰符 也能用于SELECT ，比如

``` sql
SELECT pay_by_quarter[1:2] || pay_by_quarter[4],name FROM sal_emp
      ?column?       |   name
---------------------+----------
 {10000,10000,10000} | Bill
 {27000,27000,25000} | Carol
(2 rows)

```

**修改数组**

语法和SELECT中的差不多

``` sql
# 在数组第1和第2元素之间插入数据
# 和查询一样，array的索引是从1开始的
UPDATE sal_emp SET pay_by_quarter[1:2] = '{27000,27000}'
    WHERE name = 'Carol';
UPDATE 1
SELECT pay_by_quarter FROM sal_emp WHERE name = 'Carol';
      pay_by_quarter
---------------------------
 {27000,27000,25000,25000}
(1 row)


```

ANY 和 ALL 语法

``` sql
//先加一条数据
INSERT INTO sal_emp VALUES('bigpigeo', ARRAY[10000,20000,30000,40000], ARRAY[['cookie', 'html', 'head'], ['jia', 'the', 'nine']]);
INSERT 0 1
SELECT * FROM sal_emp WHERE 10000 = ANY (pay_by_quarter);
   name   |      pay_by_quarter       |                 schedule
----------+---------------------------+------------------------------------------
 Bill     | {10000,10000,10000,10000} | \{\{breakfast,consulting},\{meeting,lunch\}\}
 bigpigeo | {10000,20000,30000,40000} | \{\{cookie,html,head\},\{jia,the,nine\}\}

SELECT * FROM sal_emp WHERE 10000 = ALL (pay_by_quarter);
 name |      pay_by_quarter       |                 schedule
------+---------------------------+------------------------------------------
 Bill | {10000,10000,10000,10000} | \{\{breakfast,consulting\},\{meeting,lunch\}\}
(1 row)

```


### 组合类型
postgresql 还支持组合类型个人感觉这种比JSON类型好，因为JSON相当于是弱类型的数据，不能很好的对数据做类型检查，使用时容易出问题


**首先是创建复合类型**

``` sql
CREATE TYPE complex AS (
    r       double precision,
    i       double precision
);

CREATE TYPE inventory_item AS (
    name            text,
    supplier_id     integer,
    price           numeric
);
```

然后是包含复合类型的表

``` sql
CREATE TABLE on_hand (
    item      inventory_item,
    count     integer
);

INSERT INTO on_hand VALUES (ROW('fuzzy dice', 42, 1.99), 1000);
```

*当你创建一个表的同时也会创建一个和表名一样的复合类型*


**写入复合类型表达式**

有2种写入方式:

    '(val1, val2, ...)'


或ROW语法

    ROW(val1, val2, ...)



**访问复合类型**

访问复合类型的成员必须带括号

``` sql
# 查询价格大于9.99的数据
SELECT (item).name FROM on_hand WHERE (item).price > 9.99;
```

使用函数访问也一样

``` bash
SELECT (my_func(...)).field FROM ...
```

**修改复合类型**

Insert一个复合类型

``` sql
INSERT INTO on_hand (item) VALUES(('fat pigeon', 43, 2.1));
INSERT 0 1
SELECT * FROM on_hand WHERE (item).name = 'fat pigeon';
         item          | count
-----------------------+-------
 ("fat pigeon",43,2.1) |
(1 row)

```

Update一个复合类型

``` sql
UPDATE on_hand SET item = ROW('fuzzy dice', 42, 2.99) WHERE (item).name = 'fuzzy dice';
UPDATE 1
SELECT * FROM on_hand WHERE (item).name = 'fuzzy dice';
          item          | count
------------------------+-------
 ("fuzzy dice",42,2.99) |  1000
(1 row)
```

Update复合类型中子域的值

``` sql
UPDATE on_hand SET item.price = 2.5 WHERE (item).name = 'fuzzy dice';
UPDATE 1
SELECT * FROM on_hand WHERE item.name = 'fuzzy dice';
                                    ^
postgres=# SELECT * FROM on_hand WHERE (item).name = 'fuzzy dice';
         item          | count
-----------------------+-------
 ("fuzzy dice",42,2.5) |  1000
(1 row)

```


### Range类型
range类型可以表示一个值的范围，比如tsrange 可以表示timestamp 的范围


以下是postgresSQL内置的range类型，你也可以[自定义](http://www.postgresql.org/docs/9.3/static/sql-createtype.html)

| 名字       | 描述                            |
| ---------- |--------------------------------:|
| int4range  | 表示整数的范围
| int8range  | 表示大整数的范围
| numrange   | 表示numeric的范围
| tsrange    | 表示为没有时区的timestamp的范围
| tstzrange  | 表示为有时区的timestamp的范围
| daterange  | 表示日期的范围



@>和*的注解可以查[官方文档](http://www.postgresql.org/docs/9.3/static/functions-range.html#RANGE-OPERATORS-TABLE)

``` sql
CREATE TABLE reservation (room int, during tsrange);
INSERT INTO reservation VALUES
    (1108, '[2010-01-01 14:30, 2010-01-01 15:30)');


SELECT * FROM reservation WHERE during @> '2010-01-01 14:50'::timestamp;
 room |                    during
------+-----------------------------------------------
 1108 | ["2010-01-01 14:30:00","2010-01-01 15:30:00")
(1 row)

--下面就是一些官方例子，自己也可以发挥想象力去尝试一下

-- Overlaps
SELECT numrange(11.1, 22.2) && numrange(20.0, 30.0);

-- Extract the upper bound
SELECT upper(int8range(15, 25));

-- Compute the intersection
SELECT int4range(10, 20) * int4range(15, 25);

-- Is the range empty?
SELECT isempty(numrange(1, 5));
```

**构造一个range类型**

首先range类型有2种表示范围的符号


    []表示包含范围符
    ()表示不包含范围符


然后是range类型也可其他类型一下可以字符串构造


    'SELECT '[3,7)'::int4range;'


或者是构造函数构造


    SELECT numrange(1.0, 14.0, '(]');
