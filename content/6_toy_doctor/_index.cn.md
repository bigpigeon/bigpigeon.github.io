+++
title = "toy-doctor"
weight=6
+++

一个参数检查工具

### Example

main.go中的代码

```golang
package main

import (
	"github.com/bigpigeon/toyorm"
	. "unsafe"
)

type Detail struct {
	ID        uint32 `toyorm:"primary key;auto_increment"`
	ProductID uint32 `toyorm:"index"`
	Name      string
}

type Product struct {
	toyorm.ModelDefault
	Name   string `toyorm:"index"`
	Detail *Detail
}

func main() {
	toy, err := toyorm.Open("sqlite3", "")
	if err != nil {
		panic(err)
	}
	brick := toy.Model(&Product{})
	// to preload detail
	brick = brick.OrderBy(Offsetof(Product{}.CreatedAt)).Preload(Offsetof(Product{}.Detail)).Enter()
	var tab []Product
	result, err := brick.Find(&tab)
	if err != nil {
		panic(err)
	}
	if err := result.Err();err != nil {
		// sql error record it
	}
	// have error
	brick = brick.OrderBy(Offsetof(Detail{}.Name))
	result, err = brick.Find(&tab)
	if err != nil {
		panic(err)
	}
	if err := result.Err();err != nil {
		// sql error record it
	}
}
```

使用 toy-doctor 去检查它的错误

    toy-doctor main.go
	// Output:
	// main.go:37:33 type must same as main.go:20:6

生成 coverprofile

    toy-doctor -coverprofile=a.out main.go
    // view corverage in browser
    go tool cover -html=a.out


