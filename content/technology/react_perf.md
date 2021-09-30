---
title: "记一次react网络请求优化+上传组件极致体验优化"
date: 2021-09-30T19:27:18+08:00
draft: false
---

# 记一次react网络请求优化+上传组件极致体验优化

## 一：网络请求优化

本次做的是一个素材库组件，这里面涉及到网路请求的其实就三个地方：

+ 全部图片tab
+ 最近使用tab
+ 上传图片后再次拉取全部图片tab数据

由于该组件为独立组件，并且需要有分页功能，所以本次数据请求不是在点击按钮之后发送，而是通过`useEffect`监听当前页码，当页码改变时拉取当前tab下的数据。关键代码如下：

```
useEffect(() => {
  loadData(); // 加载数据
}, [currentAllPage]); // 当前页码
```



这里就延伸出了第一个部分的网络优化：useState生成的变量初始值为`undefined`，随后会被赋值为我们传入的初始值。所以这里会发现，两个tab会发出四次网络请求，每一个tab会重复发出一次请求，这一次就是我们的`currentAllPage`从`undefined`变为初始值第一页即`1`时所发出的。这里一开始困扰了我很久，后来debug之后才知道是这里出了问题。解决方法：如果我们可以获取到`currentAllPage`变量变化之前的值，并判断；如果它是undefined，则说明它还没有初始化完成，则此时return，不发起网络请求。那么问题就来到了如何在`useEffect`中获取到依赖数组变化之前的值。我们都知道，当写class组件时，可以很方便的通过``getSnapshotBeforeUpdate``和``getDerivedStateFromProps``生命周期来获取变化之前以及变化之后的值。而到了函数式组件时，该怎么办呢？答案就是`hooks`。hooks本质上解决的问题就是函数式组件没有办法像class组件一样保存状态，有了hooks，我们就可以保存组件更新之前的状态，直接上代码：

```typescript
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  });

  return ref.current;
}

const prevState = usePrevious(value); // 使用方法
```

思路是：通过`useRef` hook来保存该变量，并通过`useEffect`监听，每当value发生变化，则改变ref.current内容为最新的value。而由于useEffect内部执行的代码是异步的，所以return出去的`ref.current`为变化之前的值。这里其实同样可以使用`useState`来进行保存，但是缺点是会多发生一次组件的重绘（虽然可以通过别的手段来进行优化，但是没有必要），造成性能下降。有了`usePrevious`这个自定义hook，我们就可以获取变化之前变量的值了，那么我们的网络请求也就可以避免浪费了，直接上代码：

```typescript
const prevAllPage = usePrevious<number>(currentAllPage);

useEffect(() => {
	if (typeof prevAllPage === 'undefined') {
		// 此时变量为初始化阶段
    return;
  }
  loadData(); // 加载数据
}, [currentAllPage]); // 当前页码
```

这样就避免了两次无效的网络请求。

你以为这就完了吗？不，还没完。

回到我们一开始的业务需求：

可以看到，有一个经常使用的tab。当我们从全部图片中选择了几张插入到我们的编辑器后，这几张插入的图片就应该出现在经常使用tab下，也就是说，经常使用tab在每一次modal打开后，都需要拉取最新的数据，而全部图片则不用。你可能觉得这很简单啊，直接监听modal的visible，为true的时候拉取一下不就行了吗？上代码：

```
const [shouldReloadRecentlyUsed, setShouldReloadRecentlyUsed] = useState<boolean>(false);

useEffect(() => {
  if (props.visible === true) {
    // 仅当可见时更改数据，触发useEffect，从而更新最近使用数据
    setShouldReloadRecentlyUsed(prev => !prev);
    setShowTime(prev => prev + 1);
  }
}, [modalVisible]);

const prevShouldReloadRecently = usePrevious<boolean>(shouldReloadRecentlyUsed);

useEffect(() => {
  if (typeof prevShouldReloadRecently === 'undefined') {
    return;
  }
  loadRecentlyUsedMedia();
  setSelectedItem({});
  setSelectedArr([]);
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [shouldReloadRecentlyUsed]);
```

确实很简单，但是有一个小问题：当第一次打开时，loadData函数会一次性请求两个tab的数据，而同样会触发shouldReloadRecentlyUsed，也就是我们又多请求了一次最近使用tab下的资源。解决方法，添加一个showTime变量用来记录页面展示的次数，当该组件第一次展示时，return即可，这里代码较为简单，可以自行实现。总结了一下，重复的网络请求主要原因为useEffect使用不当导致，一旦依赖数组里变量过多，或useEffect过多，则会让人摸不清头脑。

顺带提一下，最近学习mobx库时发现这样做分页会比监听页码变化后再回掉中拉取数据会更好，作者的原话为：

> Reacting to state changes is always better then acting on state changes.

这其实也是符合hooks与react的理念的，声明式编程、declarative，确实妙啊！

## 二：上传体验优化

由于上传图片可以多选，当用户选多张的时候，如果没有反馈的话体验会很差。这里简单说一下解决方案。

分两种情况：

+ 当前在第一页：

  在第一页的时候，上传体验是最好的，也是工作量最大的地方。方案是，在前面添加上传文件数量的占位骨架图并添加spin加载动画，当加载完成后替换掉对应图片并toast提示上传成功。这里由于我们已经通过骨架图来实现加载loading，所以在上传完之后不用再去拉取后端数据。随之而来的问题有两个：

  + 分页后计算上传成功的数量，并手动改变total变量。
  + 每一页只能有固定数量的图片，需要手动pop掉后面相同数量的图片，才能达到效果上一致。

+ 当前在非第一页，此时则无需做任何操作，展示一个全局的loading，然后再文件全部上传完成后再刷新当前页码数据。



本次组件库的开发是第一次使用typescript + hooks来进行较为复杂组件的开发。在上传优化那一部分，涉及到了对一个复杂数组的细粒度更新，一开始是通过深拷贝一个本地数组再对本地数组进行更新，后来发现会被react的batchUpdate给合并，从而达不到一个一个从loading为true变为false。然后改为通过传入函数的方式来获取之前的状态并通过map手动修改。后续了解到可以通过引入mobx、immer等库来实现。当然，这些都是后话了。这篇文章一开始是有图片的，但是图片保存在公司电脑上忘记拷贝了，所以就没了。。。

