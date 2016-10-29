+++
Description = ""
Tags = [
  "Development",
  "golang",
]
Categories = [
  "开发",
]
menu = "main"
date = "2016-10-12T11:43:37+08:00"
title = "从jekyll到hugo，搬运经验总结"
+++
因为我对新技术的热爱和向往，我选择博客从jekyll换成hugo了，本来是想记录一下他们之间区别，搬运完才发现它们在功能上竟然是如此的相识,所以我只能讲jekyll如何搬运到hugo.


hugo和jekyll一样也是静态页面框架，有着和jekyll相似文件结构和配置方法，不过hugo有着更快的生成速度和更好的markdown引擎，支持toml,yaml,json配置文件格式，hugo又从hexo中借鉴了不少特性,比如live reload。而且hugo是go开发的，模板语法中能找到go语言的影子，这也是我使用它的主要原因。

<!--more-->
### 如何安装
先下载[go](https://golang.org/dl/)，然后配置GOPATH环境变量，通过**go get**命令下载的包都会放到GOPATH中，在GOPATH中的包也可以被其他包import


然后配置PATH,这样通过go安装的命令可以被直接执行

    export PATH=$GOPATH/bin:$PATH

安装[hugo](https://github.com/spf13/hugo)

    go get -v github.com/spf13/hugo

如果下载超时可以尝试挂代理，设置http_proxy和https_proxy就可以使用http(s)代理,如果是socket代理，建议用[delegate](http://www.delegate.org/delegate/)转成http(s)代理

### 创建第一个博客
hugo可以通过下面的命令快速构建一个hugo的文件结构

```bash
$ hugo new site firstblog
Congratulations! Your new Hugo site is created in "/data/work/firstblog".

Just a few more steps and you’re ready to go:

1. Download a theme into the same-named folder.
   Choose a theme from https://themes.gohugo.io/, or
   create your own with the "hugo new theme <THEMENAME>" command.
2. Perhaps you want to add some content. You can add single files
   with "hugo new <SECTIONNAME>/<FILENAME>.<FORMAT>".
3. Start the built-in live server via "hugo server".

Visit https://gohugo.io/ for quickstart guide and full documentation.
```

查看文件结构

```bash
$ tree firstblog
firstblog/
├── archetypes
├── config.toml
├── content
├── data
├── layouts
├── static
└── themes

6 directories, 1 file
```
下面来看看各个文件夹的作用

- **archetypes**: 允许自定义post front matter(就是见面开头+++那部分)，并且会在hugo new 时给默认值

- **config.toml**: 主配置文件，hugo也支持也可以使用yaml和json格式，不过默认以config.toml为主配置文件

- **content**: 博客的文章，关于，demo等内容都放在这个目录下，使用**hugo new**命令创建的文件会存放在这个目录下，你可以定义不同的子目录作为sections,文章的默认sections是post

- **data**: 这个目录存放一个用于生成网站的数据，你可以使用YAML,JSON或者TOML格式

- **layouts**: 用来存放html模板，这些模板将决定你网页的布局，更详细的内容可以查看[templates](https://gohugo.io/templates/overview/)章节

- **static**: 存放网站静态文件的目录，在网站生成后会将该目录的文件放到网站的根目录下，不要和content下的文件有重名

- **themes**: 存放主题，建议用主题来决定网站的风格样式，网站只存放内容

然后按照提示我们去https://themes.gohugo.io/ 找一个主题，并把它下载到
themes目录中

```bash
$ cd firstblog/themes
$ git clone https://github.com/fredrikloch/hugo-uno.git
```

修改config.toml

```config
$ cd firstblog
firstblog/$ cat config.toml
baseurl = "http://replace-this-with-your-hugo-site.com/"
title = "My blog"
languageCode = "en-us"
theme = "hugo-uno"
```

创建一篇新的文章

```bash
$ cd firstblog
$ hugo new post/start.md
/data/work/firstblog/content/post/start.md created
```

在content文件夹中找到你刚刚创建的markdown文件然后编辑，编辑好后就可以通过**hugo server**运行了，然后在本地访问http://localhost:1313/ 就可以看到你的网站了

```bash
$ cd firstblog
$ hugo server
Started building sites ...
Built site for language en:
0 draft content
0 future content
0 expired content
1 pages created
0 non-page files copied
0 paginator pages created
2 categories created
2 tags created
total in 34 ms
Watching for changes in /data/work/firstblog/{data,content,layouts,static,themes}
Serving pages from memory
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

### 常见问题

#### **分页问题**

在模板中使用.Paginate，该页面就会被自动分页
比如:
```html
    <!--拿到当前分页-->
    {{ $paginator := .Paginate (where .Data.Pages "Section" "post") }}
    ...
    <!--读取分页内容-->
    {{ range $paginator.Pages }}

        {{ .Render "summary"}}
    ...
    {{ end }}
    ...
    <!--增加翻页按钮-->
    {{ if $paginator.HasPrev}}
    <a href="{{ $paginator.Prev.URL }}">上一页</a>
    {{ else }}
    <a></a>
    {{ end }}
    <a href="{{ .Site.BaseURL }}/post/">归档</a>
    {{ if $paginator.HasNext }}
    <a href="{{ $paginator.Next.URL }}">下一页</a>
    {{ else }}
    <a></a>
    {{ end }}
```
默认分页的对象数是10，可以通过在config中定义Paginate去改变分页数

#### **额外的页面**

为了让我的demo页面和文章页面分离开来，需要用到section这个功能，在上面的模板可以看到**where .Data.Pages "Section" "post"**，这个语句就是取所有页面中section位post的页面，那么问题来了:

1. 如何判断这个页面是属于那个section
2. 如何为section添加展示页该如何做


**如何判断这个页面是属于那个section**

比如我们一开始的是用**hugo new post/start.md**创建页面的section就是post


也就是在content中的子文件夹名就是section名，比如我要在网站增加一个名为demo的section


    hugo new mysection/first.md

这时访问**http://localhost:1313/mysection/first**就可以看到该页面了，这个页面是由layouts/_default/single.html模板渲染的，如果你想自定义渲染的模板可以新增layouts/mysection/single.html作为mysection单页的渲染模板


**如何为section添加展示页该如何做**

在layouts/section/中添加一个html模板，模板名必须和section名一致,比如我们为mysection添加一个展示页

```bash
cat >> layouts/section/mysection.html <<EOF
{{ partial "head.html" . }}
    <!--拿到当前分页-->
    {{ $paginator := .Paginate (where .Data.Pages "Section" "mysection") }}
    ...
    <!--读取分页内容-->
    {{ range $paginator.Pages }}

        {{ .Render "summary"}}
    ...
    {{ end }}
    ...
    <!--增加翻页按钮-->
    {{ if $paginator.HasPrev}}
    <a href="{{ $paginator.Prev.URL }}">上一页</a>
    {{ else }}
    <a></a>
    {{ end }}
    <a href="{{ .Site.BaseURL }}/post/">归档</a>
    {{ if $paginator.HasNext }}
    <a href="{{ $paginator.Next.URL }}">下一页</a>
    {{ else }}
    <a></a>
    {{ end }}
EOF
```

这样访问**http://localhost:1313/mysection**  就可以看到展示页了


hugo还有一个summary的功能，可以让你把单页的部分内容放入展示页渲染，添加一个layouts/模板名/summary.html的模板，然后像上面的例子中那样使用**{{ .Render "summary"}}**就可以把容内渲染进展示页中

**关于template如何使用你可以查看[官方文档](https://gohugo.io/templates/overview/)**


