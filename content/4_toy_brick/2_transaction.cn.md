+++
title = "事务"
description = "transaction"
+++


开启一个事务

```golang
brick = brick.Begin()
```

回滚所有sql事件

```golang
err = brick.Rollback()
```

提交所有sql事件

```golang
err = brick.Commit()
```
