---
title: "Vscode AutoReveal开启node_modules文件"
date: 2022-12-29T16:50:51+08:00
draft: false
---

最近在vscode中查看项目中依赖的一些文件源代码时，突然发现vscode左侧的文件资源管理器不会在自动定位到node_modules里的文件。
![](https://s3.bmp.ovh/imgs/2022/12/29/d44bee73a63c139c.gif)
这对于我来说是不太习惯的，因为我经常会去看一些node_modules里的源代码，并且要根据左侧的文件资源管理器定位到当前浏览的文件所在的具体位置，去查看他的一些目录结构、其余源代码等。想到最近vscode自动更新了一次版本，于是去vscode的[版本更新文档](https://code.visualstudio.com/updates/v1_74)去看了一下，[第一个highlight](https://code.visualstudio.com/updates/v1_74#_custom-explorer-autoreveal-logic)就是我这次遇到的问题。

通过描述可以看出，这次的vscode添加了如下的默认配置到settings.json中：
```json
{
  "explorer.autoRevealExclude": {
    "**/node_modules": true,
    "**/bower_components": true
  }
}
```
可以看到，他将node_modules下的文件关闭了autoReveal这个功能，也就是左侧文件浏览器自动定位到当前浏览代码的文件位置。找到了问题之后，我们打开我们的vscode配置文件，关闭node_modules的这行配置即可：
```json
{
  "explorer.autoRevealExclude": {
    "**/node_modules": false
  }
}
```


从这一个小问题其实可以引发我们对软件开发流程的一个思考，一个大型、有着较大用户量的软件肯定是经常会有更新迭代的，包括bug修复、功能升级等等，这中间有很多的流程与规范。对于我这次遇到的情况来说，一个软件的更新迭代必须要配以相应的说明文档，必须要包括这次更新所带来的全部影响。这样才不会让用户在更新软件过后遇到新的功能一脸懵逼。