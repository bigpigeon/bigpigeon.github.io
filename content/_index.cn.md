+++
title = "Toyorm"
description = "powerful toyorm"
+++

## Toyorm

> 一个功能强大的go语言orm

### Overview

- 数据迁移 (CreateTable/DropTable)
- 操作数据 (Insert/Save/Update/Find/Delete)
- 预加载操作(BelongTo/OneToOne/OneToMany/ManyToMany mode)
- Join操作
- 事务
- 空值忽略 (toyorm允许你只忽略指定的空值)
- 字段绑定 (绑定后，操作表时只对绑定字段操作)
- 软删除 (更新 DeletedAt 字段值代替物理删除)
- Scope (自定义构建函数)
- 线程安全(但必须准守协定)
- 查询模板 (自定义你的查询/执行语句)
- 返回值和错误记录 (记录数据库的操作记录和返回的错误)
- 集合 (多数据库操作)
- toy-doctor(检查FieldSelection参数错误)

### Go 版本

version > 1.9

### 支持数据库

{{< button href="https://www.sqlite.org/" theme="info">}} sqlite3 {{< /button >}}
{{< button href="https://www.mysql.com/" theme="info">}} mysql {{< /button >}}
{{< button href="https://www.postgresql.org/" theme="info">}} postgresql {{< /button >}}






