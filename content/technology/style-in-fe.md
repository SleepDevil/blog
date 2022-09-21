---
title: "前端工程化中的CSS解决方案"
date: 2022-09-21T10:44:14+08:00
draft: false
---

# CSS

作用：给 HTML 加样式，美化网页。
痛点：以前不支持变量，大量的样式无法复用。
不支持嵌套，需要写大量重复的选择器。
不支持自定义函数，无法通过函数复用逻辑。
没有一些复杂的数据结构，如列表等，不支持一些程序控制语句（if、for）等。
多人协作时，容易产生样式冲突、选择器污染等问题。  
解决方案：BEM、CSS-Modules、CSS-IN-JS
BEM，块（block）、元素（element）、修饰符（modifier）的简写，由 Yandex 团队提出的一种前端 CSS 命名方法论。

```css
.block__element--modifier {
  display: flex;
}
```

在 css-modules 出来之前，我们通过遵循 BEM 命名规范来解决团队间可能出现的 css 样式冲突。但明显，这会存在问题，有人会不遵守规范，只能靠自觉。并且同样有可能出现冲突，只是降低了可能性。
# CSS-Modules
规范：[https://github.com/css-modules/css-modules](https://github.com/css-modules/css-modules)

Css-loader 通过 mode 支持

[https://github.com/webpack-contrib/css-loader](https://github.com/webpack-contrib/css-loader)

## 使用之前：
我们只是简单的引入了 css 文件，它会经过 css-loader 处理，最终变成 html 中的 link 标签生效。
![image.png](https://s2.loli.net/2022/09/21/2GyaZMwI71JPgFv.png)
使用效果：和我们正常写 html、css 效果是一样的。
![2 _1_.png](https://s2.loli.net/2022/09/21/ivOTKUqyEekRna9.png)
## 使用之后：
使用方式：通过 default import 引入，css-loader 会识别并将这个变量变为一个 key-value 对象，使用的时候通过 styles[key]获得经过哈希之后的类名。
![3 _1_.png](https://s2.loli.net/2022/09/21/xYnAWvOMPum4jD7.png)
使用效果：
![4 _1_.png](https://s2.loli.net/2022/09/21/GPyNaQO8ewsV4dF.png)
当我们在控制台打印导入进来的 styles 后，可以发现，引入进来的就是一个键值对的 javascript 对象：
![5 _1_.png](https://s2.loli.net/2022/09/21/mfAMN45TkPJniCB.png)
所以它的原理就很简单了，就是根据 css 中的类名生成唯一的字符串来一一对应。当我们开启 css modules 后，相当于我们将所有的选择器都加上了:local 选择器，而 css loader 做的就是将所有带有:local 的选择器都生成唯一的 classname，以达到避免样式冲突的目的。
这里提一下，css-loader 使用了 PostCSS 进行类名的匹配，PostCSS 对于 CSS 就相当于 babel 之于 javascript，都是一个对于源代码进行词法分析生成抽象语法树（abstract syntax tree）的工具，并提供一系列的 util 来简化对 ast 的操作成本。所以同样的，也有对应的插件生态系统。https://github.com/madyankin/postcss-modules就做了同样的事情，只是css-loader有额外的功能，且适配webpack，所以cra采用了css-loader来支持css-modules。
## css-modules 的其他功能
有时，我们可能不想用局部样式，而想要写一些全局样式，这时候我们可以通过
`:global(// 选择器) {}` 来编写。这样，这段选择器就不会被转化。
```css
:global(.title) {
color: green;
}
```
可以通过 compose 来组合一些可复用的 css。

```scss
.className {
  color: green;
  background: red;
}

.otherClassName {
  composes: className className2 from "./another.css";
  color: yellow;
}
```

同时，css 近来也支持了自定义变量，css variable，通过--开头书写。它默认支持变量作用域，:root 中声明的变量自动拥有全局作用域。并且可以通过 JavaScript apisetProperty 来动态修改值。
# Vue scoped css
vue 自己开创了一套语法，SFC，single file component，所以在 css 模块化方面也给出了自己的解决方案：

```vue
<style scoped>
.logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
}
</style>
```

![6 _1_.png](https://s2.loli.net/2022/09/21/FABGexvwNrTfc2D.png)
可以看到，vue 另辟蹊径，通过在 dom 上添加额外的属性，并在 css 选择器上加上对应的属性选择器来做到样式隔离的效果。
# Less、Sass
两个用的比较多的 css 预处理器，给 css 加了很多特性，解决了之前说的 css 痛点。

- 支持自定义变量
- 支持嵌套书写样式
- 支持模块化，有利于拆分逻辑
- 支持 mixin 与自定义函数
- 支持流程控制，if、for 等
- 支持样式继承
- 有内置的一些工具函数，新增数据类型（List、Map 等）
  ## mixin与函数的区别
  mixin和函数很像，主要的区别在于 mixin 返回的是 css 代码，一行或者多行。而函数主要是返回一个变量，可以对这个变量进行操作，以用来对一些 css 变量进行复杂操作。在 sass 中，我们可以通过@mixin 来声明一个 mixin 并使用@include 来引用。
  ```scss
  @mixin reset-list {
    margin: 0;
    padding: 0;
    list-style: none;
  }
  @mixin horizontal-list {
    @include reset-list;
    li {
      display: inline-block;
      margin: {
        left: -2px;
        right: 2em;
      }
    }
  }
  nav ul {
    @include horizontal-list;
  }
  ```
  ```scss
  @function pow($base, $exponent) {
    $result: 1;
    @for $\_from 1 through $exponent {
      $result: $result \* $base;
    }
    @return $result;
  }
  .sidebar {
    float: left;
    margin-left: pow(4, 3) \* 1px;
  }
  ```

## 主要区别
less 中，所有变量的值是在编译完成后才确定的，也就是说生效的只有最后一次对变量的赋值。利用这个特性，less 就有了独特的 api——modifyVars，也就是 Arco 风格配置平台可视化修改组件样式的核心。通过 modifyVars({ '变量名': '新的变量值' })我们可以在运行时修改 less 变量而不用刷新页面，less 文件会自动重新编译并加载。
![7.gif](https://s2.loli.net/2022/09/21/iR6xzjHwL8WyDtK.gif)

但是 sass 却没有提供这样的 api，为啥，因为它们的变量在使用时是有区别的。下面看两个例子：
![8 _1_.png](https://s2.loli.net/2022/09/21/vzIkd8G7EqOLmfn.png)
![9 _1_.png](https://s2.loli.net/2022/09/21/Dg95Ku3netJACl4.png)

可以看到，在 less 中，变量只有最后一次的值生效了，而在之前使用该变量，获得的都是最终的值。在 sass 中则更符合我们的逻辑，使用的时候就是当前的值，修改一个变量，不会影响到修改之前的使用。再来看第二个例子，我们注释掉第一行代码：
![10 _1_.png](https://s2.loli.net/2022/09/21/QRifVU5Tk1vg8AM.png)
![11 _1_.png](https://s2.loli.net/2022/09/21/ucMPkTqrVitCRvX.png)

可以看到，less 还是可以正常编译的，而 sass 则更符合我们的编程习惯，抛出了错误。所以这也是为什么 less 可以提供 modifyVars 这个 api 的原因，因为无论它的变量中间被修改过多少次，最终生效的只有它最后的值。

那么如果我们要用 sass 的话，该怎么实现这个功能呢？可以通过在变量赋值后面添加!default 来表明该赋值语句为默认赋值，只有当该声明语句之前没有出现过对该变量的声明时才会生效，否则就使用该默认值。这样，如果我们想修改某个变量，只需要保证在!default 之前修改即可。

在 less 与 sass 中，变量都是有作用域的，定义的变量只在当前作用域有效，这一点和 js 是一致的。

less 官方提供了 js 版本的实现，Sass 一开始提供的是 ruby 版本，后来转为 dart 版本，同时也维护着一份 ts 版本，并发布为 npm 包。

# CSS-IN-JS
利用 JavaScript es6 中的模板字符串，使用 JavaScript 来编写样式，并直接转换成对应的 css，插入到 html 中。这一类框架中，比较经典的就是 styled-components 了，看一下他的 demo：

```jsx
const Title = styled.h1`
  font-size: 1.5em;
  text-align: center;
  color: palevioletred;
`;

// Create a Wrapper component that'll render a <section> tag with some styles
const Wrapper = styled.section`
  padding: 4em;
  background: papayawhip;
`;

function App() {
  return (
    <Wrapper>
      <Title>Hello World!</Title>
    </Wrapper>
  );
}

export default App;
```
这里的模板字符串写法很像我们在 react 中编写内敛样式的感觉，styled.h1 是一个函数，后面的 css 字符串则作为参数传递了进去，这是 es6 模板字符串提供的功能：
https://es6.ruanyifeng.com/#docs/string#%E6%A0%87%E7%AD%BE%E6%A8%A1%E6%9D%BF
随后将传入进去的参数转化为 css 代码，每一个组件会生成对应的一个 unique classname，这样就做到了样式的隔离，每一个编写的样式都默认是局部的。

![12 _1_.png](https://s2.loli.net/2022/09/21/iDEH7PUf9gosFwZ.png)
如果想编写一些全局 css 来覆盖默写样式，可以通过 `createGlobalStyleapi` 去创建。
```jsx
import { createGlobalStyle, ThemeProvider } from 'styled-components'
const GlobalStyle = createGlobalStyle` body { color: ${props => (props.whiteColor ? 'white' : 'black')}; font-family: ${props => props.theme.fontFamily}; }`
// later in your app
<ThemeProvider theme={{ fontFamily: 'Helvetica Neue' }}>
  <React.Fragment>
  <Navigation /> {/_ example of other top-level stuff _/}
  <GlobalStyle whiteColor />
  </React.Fragment>
</ThemeProvider>
```
可以看到，每一个函数返回的都是一个 React 自定义组件，所以在使用上还是有一定的学习成本的。但是由于他使用 JavaScript，所以我们可以享受到灵活的特性，这就像 jsx 与 vue template 的比较一样，可以使用到所有的 JavaScript 变量、特性。同时他也支持样式继承，避免了样式污染等问题。

再者，由于他将 js 与 css 写在了一起，对于开发者调试来说，就避免了来回跳转，在庞大的 css 文件中找到对应组件的样式等问题。当前组件的样式和组件的逻辑代码耦合在一起，增加了开发效率。
还有一个不怎么值得注意的点，如果你想使用 css-in-js 的地方是在某个 ui 组件的时候，别人可以直接引入而不需要再配置对应的 loader。这点在使用 sass、less 时有明显的区别，有时候我们的项目没有使用 less，但因为引用的第三方库用到了 less，所以我们也要配置 less-loader。

但是他也有缺点，以 styled-compoents 为代表的老一代 css-in-js 框架采用运行时生成 css link 并插入到 html 中，这中间全是 js 代码的加载与执行，而传统的方案则是对 css 提供增强功能，但最后都回归到 css 本身。在浏览器加载页面时，js 和 css 是可以同时加载并解析的，提升了页面性能，并且可以对静态资源做缓存，减少了页面刷新的开销。并且 styled-components 生成的 className 完全无意义，不像 css-modules 可以自定义 hash 规则，可能增加后期的维护成本。但上面说的都已经有了解决方案，例如自定义 className 前缀： styled.div.withConfig({ componentId: "prefix-button-container" }) 。运行时造成性能损耗的问题也有对应的解决方案：https://github.com/callstack/linaria，以及https://github.com/4Catalyzer/astroturf，在保留了css-in-js的便利的同时，解决了运行时性能问题。
## Css-in-js vs inline style
可以发现，css-in-js 乍一看似乎是回到了写 inline style 的时代，真的是这样吗？
Inline style 只支持写在当前元素上的属性，一些伪元素、伪类、媒体查询、复杂选择器都无法实现，需要额外编写 css 来实现。并且他最终是直接将 style 传递到了 dom 元素上，react 官方也是不建议我们这样，因为会有性能问题。
![13 _1_.png](https://s2.loli.net/2022/09/21/RjntCWKGQXMlakd.png)
而 css-in-js 则要强大的多，他是一个完整的 JavaScript 解决 css 的方案。他支持样式继承、嵌套，支持媒体查询、伪元素、伪类，支持样式覆盖，支持主题定制等等。
![14 _1_.png](https://s2.loli.net/2022/09/21/5LYTumJCQX1xvwV.png)
# Atomic Css
原子化 css，典型的代表有 TailwindCss、WindiCss 等。这类框架通过提供一系列简单类名来减少让你去写传统的 css。一个 class 代表一个 CSS 属性，是一种细粒度的 CSS 。下面是 TailwindCss 官网给出的示例，使用之前，传统的 css 写法：
![15 _1_.png](https://s2.loli.net/2022/09/21/iLwSOUnK1RWHkdP.png)

使用之后：
![16 _1_.png](https://s2.loli.net/2022/09/21/BVYGQnIx5zXJLAS.png)

可以看到，减少了很多的代码量。他给每一个类名的提供了对应的 css，例如 p-6 代表 padding: 1.5rem，px-6 代表水平方向（x 轴）的间距，也就是 padding-left 与 padding-right 分别为 1.5rem。
![17 _1_.png](https://s2.loli.net/2022/09/21/2HwnWvgA3s8k4Su.png)
如图是生成的 css。可如果我们只使用到了 w-20，他给我们产生了从 w-0 到 w-96 的 css 代码的话，那就会造成很大的 css 文件体积，这是不能容忍的。tailwind 在打包的时候会使用 PurgeCSS 来去除没有用到的 css 代码，压缩 css 文件体积。

![18 _1_.png](https://s2.loli.net/2022/09/21/FlreUMsfIXiEPYu.png)
这张图给出了如何做出一个响应式的页面，框架默认提供了以上尺寸，同时也支持自定义尺寸、设备类型，简化了我们传统要写媒体查询来做响应式的方法。同样，也可以通过 dark:来编写暗黑模式下的样式。
那么它有哪些优点呢：

- 不用自己去想 className 了，这解放了我们这些英语不好的人每次命名一个变量都要去翻译的劳动了，我们只管写样式。
- 支持自定义变量，这在我们需要配合某个设计规范的时候很有用。——tailwind.config.js
- 可以使用较少的代码来支持响应式、暗黑模式。
- 由于不用自定义 className，所以一定程度上避免了样式污染的问题。但是通过自定义变量仍然会存在这样的问题。
- 支持伪元素、伪类。
- 框架无关，上手简单，使用方便。
同时，近来流行的 headless ui 也给原子化 css 带来了很大一波机会。
当 ui 框架提供的默认配置不再满足用户需要的时候，一种做法是提供主题定制能力，类似于 Arco 的风格配置平台，将样式抽离成变量，给组件复用，以达到可定制的目的。这种做法耗时耗力，将实现的大部分成本都放在了组件库身上，并且大量的 css 变量很容易遗漏或使用地方出错。
而另一种方法就是 headless ui，组件库提供不带样式的组件，只实现了基本逻辑、功能，样式交给用户去自定义。这种做法就降低了组件库开发方的压力，让组件定制开发的成本全部交由使用者。https://github.com/tailwindlabs/headlessui，这个时候，原子化css的好处就逐渐的体现出来了。组件库只要提供一套基础能力的组件，并提供一套官方的样式，剩下的就交给开发者自定义了。

# 总结
原生 css 加 css modules 加 css 变量已经符合多人开发的标准了，使用起来简单方便，无额外学习成本，适合对样式要求不高的项目进行使用。而如果项目中需要大量使用到 css 的时候，就可以考虑 sass、less 等预处理器提供的强大功能，可以为我们减少很多无用代码的编写。国内估计是由于 antd 的原因，对 less 尤为偏爱，但 less 现在已经不维护了，并且功能上比 sass 要差上很多，所以我们可以看到，在 next.js、create-react-app 等常用脚手架中，都默认支持了 sass 但不支持 less，这对于国内 antd 等使用 less 作为样式选择的框架使用者来说多了一层配置。在国外，sass 则要火的多，很多出名的 css 框架都是用 sass 编写的，比如 bootstrap、foundation 等，sass 以前的 node-sass 在安装上很不方便，现在采用 dart 编写后，直接编译成 npm 包，就不存在这个问题了。以上都是在 css 的基础上做扩展，我们编写样式的时候还是在组件之外去编写，并通过类名对应。

而 css-in-js 与 atomic css 则都是在组件上编写样式，他们避免了我们开发时在 js 文件与 css 样式中来回跳转的问题，并且不用开发者去想类名，有一定的学习成本，但是对于开发者来说会很爽，可以提高开发效率。值得一提的是，material ui 采用的就是 css-in-js 的方案，默认是 emotion，也提供了 styled-components。

最终的技术选型，肯定是要根据团队成员风格以及开发的项目来综合考量的。以上的各种解决方案没有万金油，在不同场景下选用合适且适合团队的才是最好的。
