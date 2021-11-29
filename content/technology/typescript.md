---
title: "Typescript学习笔记"
date: 2021-10-13T20:27:53+08:00
draft: false
---

最近对typescript十分着迷，找到一个很好的开源项目：[type-challenges](https://github.com/type-challenges/type-challenges)，本篇文章用来记录其中学习到的知识点。

# Exclude工具类实现

通过翻阅源码我们很容易看出实现代码：

```typescript
/**
 * Exclude from T those types that are assignable to U
 */
type Exclude<T, U> = T extends U ? never : T;
```

但是这里面设计到的知识点还是不少的。

+ conditional type

  `extends`关键字一般用在声明一个子类，而在类型编程中，可以用来继承一个interface。而这里的extends使用到了条件类型的判断，官网上是这样说的：

  > When the type on the left of the `extends` is assignable to the one on the right, then you’ll get the type in the first branch (the “true” branch); otherwise you’ll get the type in the latter branch (the “false” branch).

  即当extends左边为右边的子类型（可以赋值给右边的类型）时，则为true，返回第一个值，否则返回第二个值。

+ Distributive Conditional Types

  当我们测试我们的Exclude工具类型时：

  ```typescript
  type Test = Exclude<'a' | 'b', 'a'> // type Test = "b"
  ```

  这时候可以看出，Test的类型为`"b"`，`'a' | 'b'`是不可以赋值给右边的`'a'`类型的，按理论上来说Test会返回第一个类型，也就是`'a' | 'b'`，但是并不是这样的。这里就涉及到了第二个知识点，当conditional type遇到联合类型（union type）时会触发distributive conditional types，即每一个联合类型里的类型都会进行一次条件判断，所以上面的类型判断逻辑实际是：

  ```typescript
  type Test = 
    | ('a' extends 'a' ? never : T) // never
    | ('b' extends 'a' ? never : T) // 'b'
  ```

  所以最终，Test的类型为`'b'`。

参考：[typescript内置Exclude怎么去理解?](https://segmentfault.com/q/1010000021544352)

[Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html)

# keyof

