+++
title = "Result"
+++

**use Report to view sql action**

report format

insert operation report

```golang
user := User{
    Detail: &UserDetail{
        MainPage: "some html code with you page",
        Extra:    Extra{"title": "my blog"},
    },
    Blog: []Blog{
        {Title: "how to write a blog", Content: "first ..."},
        {Title: "blog introduction", Content: "..."},
    },
    Friends: []*User{
        {
            Detail: &UserDetail{
                MainPage: "some html code with you page",
                Extra:    Extra{},
            },
            Blog: []Blog{
                {Title: "some python tech", Content: "first ..."},
                {Title: "my eleme_union_meal usage", Content: "..."},
            },
            Name: "fatpigeon",
            Age:  18,
            Sex:  "male",
        },
    },
    Name: "bigpigeon",
    Age:  18,
    Sex:  "male",
}
result, err = brick.Save(&user)
// error process ...
fmt.Printf("report:\n%s\n", result.Report())

/*
// [0, ] means affected the 0 element
// [0-0, ] means affected the 0 element the 0 sub element
report:
[0, ] INSERT INTO user(created_at,updated_at,deleted_at,name,age,sex) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.012285+08:00","2018-02-28T17:31:20.012285+08:00",null,"bigpigeon",18,"male"]
	preload Detail
	[0-, ] INSERT INTO user_detail(user_id,main_page,extra) VALUES(?,?,?)  args:[1,"some html code with you page",{"title":"my blog"}]
	preload Blog
	[0-0, ] INSERT INTO blog(created_at,updated_at,deleted_at,user_id,title,content) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.013968+08:00","2018-02-28T17:31:20.013968+08:00",null,1,"how to write a blog","first ..."]
	[0-1, ] INSERT INTO blog(created_at,updated_at,deleted_at,user_id,title,content) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.013968+08:00","2018-02-28T17:31:20.013968+08:00",null,1,"blog introduction","..."]
	preload Friends
	[0-0, ] INSERT INTO user(created_at,updated_at,deleted_at,name,age,sex) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.015207+08:00","2018-02-28T17:31:20.015207+08:00",null,"fatpigeon",18,"male"]
		preload Detail
		[0-0-, ] INSERT INTO user_detail(user_id,main_page,extra) VALUES(?,?,?)  args:[2,"some html code with you page",{}]
		preload Blog
		[0-0-0, ] INSERT INTO blog(created_at,updated_at,deleted_at,user_id,title,content) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.016389+08:00","2018-02-28T17:31:20.016389+08:00",null,2,"some python tech","first ..."]
		[0-0-1, ] INSERT INTO blog(created_at,updated_at,deleted_at,user_id,title,content) VALUES(?,?,?,?,?,?)  args:["2018-02-28T17:31:20.016389+08:00","2018-02-28T17:31:20.016389+08:00",null,2,"my eleme_union_meal usage","..."]
*/
```

find operation report

```golang
brick := brick.Preload(Offsetof(User{}.Friends)).
    Preload(Offsetof(User{}.Detail)).Enter().
    Preload(Offsetof(User{}.Blog)).Enter().
    Enter()
var users []User
result, err = brick.Find(&users)
// some error process
...
// print the report
fmt.Printf("report:\n%s\n", result.Report())

// report log
/*
report:
[0, 1, ] SELECT id,created_at,updated_at,deleted_at,name,age,sex FROM user WHERE deleted_at IS NULL  args:null
	preload Detail
	[0-, 1-, ] SELECT id,user_id,main_page,extra FROM user_detail WHERE user_id IN (?,?)  args:[2,1]
	preload Blog
	[0-0, 0-1, 1-0, 1-1, ] SELECT id,created_at,updated_at,deleted_at,user_id,title,content FROM blog WHERE deleted_at IS NULL AND user_id IN (?,?)  args:[1,2]
	preload Friends
	[0-0, ] SELECT id,created_at,updated_at,deleted_at,name,age,sex FROM user WHERE deleted_at IS NULL AND id IN (?)  args:[2]
		preload Detail
		[0-0-, ] SELECT id,user_id,main_page,extra FROM user_detail WHERE user_id IN (?)  args:[2]
		preload Blog
		[0-0-0, 0-0-1, ] SELECT id,created_at,updated_at,deleted_at,user_id,title,content FROM blog WHERE deleted_at IS NULL AND user_id IN (?)  args:[2]
*/

```


**use Err to view sql action error**

```golang
var users []struct {
    ID     uint32
    Age    bool
    Detail *UserDetail
    Blog   []Blog
}
result, err = brick.Find(&users)
if err != nil {
    panic(err)
}
if err := result.Err(); err != nil {
    fmt.Printf("error:\n%s\n", err)
}

/*
error:
SELECT id,age FROM user WHERE deleted_at IS NULL  args:null errors(
	[0]sql: Scan error on column index 1: sql/driver: couldn't convert "18" into type bool
	[1]sql: Scan error on column index 1: sql/driver: couldn't convert "18" into type bool
)
*/
```

