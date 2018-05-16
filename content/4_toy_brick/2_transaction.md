+++
title = "Transaction"
description = "transaction"
+++


start a transaction

```golang
brick = brick.Begin()
```

rollback all sql action

```golang
err = brick.Rollback()
```

commit all sql action

```golang
err = brick.Commit()
```
