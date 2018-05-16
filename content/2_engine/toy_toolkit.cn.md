+++
title = "toy工具"
description = ""
weight=1
+++

#### SetDebug

设置默认的Debug模式

```golang
	toy.SetDebug(true) // 设置默认debug模式
	brick := toy.Model(&User{}) // 现在这个ToyBrick对象的debug为true
	
```