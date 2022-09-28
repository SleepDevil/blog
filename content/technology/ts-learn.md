---
title: "从0到1开始ts类型体操"
date: 2022-09-27T15:24:47+08:00
draft: false
---

让我们从一道题开始：[https://github.com/total-typescript/type-transformations-workshop/blob/main/src/06-challenges/34-get-dynamic-path-params.problem.ts](https://github.com/total-typescript/type-transformations-workshop/blob/main/src/06-challenges/34-get-dynamic-path-params.problem.ts)

```typescript
type UserPath = "/users/:id";

type ExtractPathParams = unknown;

Expect<Equal<ExtractPathParams<UserPath>, { id: string }>>;
```

看到这道题的时候，第一想法是通过模板字符串匹配拿到冒号后面部分作为 object 的 key，于是写出了如下代码：

```typescript
type ExtractPathParams<T> = T extends `${infer First}:${infer Last}`
  ? { Last: string }
  : never;
```

但是发现生成的对象 key 已经固定为`Last`了，所以给加了个中括号，`[Last]`，但是编辑器报错了：
![image.png](https://s2.loli.net/2022/09/27/qYlzQvh7ruJWnDE.png)
从这个报错里我们可以得到以下信息：

- `Last`是一个类型（type），而不是一个值（value）
- 对象中的 key 必须是一个值，且必须为 string | number | symbol

所以就引出了类型体操的基础知识——值和类型。

## 值和类型

在 typescript 中所有的变量初始都是值，例如我们定义一个对象：

```typescript
const obj = {
  name: "SleepDevil",
  age: 18,
};
```

这里的 obj 就是一个值，如果我们想获取到它的类型，可以使用`typeof`操作符，例如：`type ObjType = typeof obj`，通过编辑器的提示我们可以得知：

```typescript
type ObjType = {
  name: string;
  age: number;
};
```

从值转化成类型很简单，但是从类型转化成值就不容易了，例如上面的对象类型，一旦转化过后就没法转化回去了。但是对于字面量类型来说，我们可以通过`in`操作符生成它对应的值，所以文章开头的那道题最终的结果就是：

```typescript
type ExtractPathParams<T> = T extends `${infer First}:${infer Last}`
  ? { [K in Last]: string }
  : never;
```

我们接下来要做的类型体操，针对的都是类型，而不是值，理解了这一点之后，请接着往下看。

## 类型体操

所谓类型体操，就是从一个类型转化成另一个类型，这其中有简单的也有复杂的，但万变不离其宗，主要是通过以下类型操作符（type operator）来实现的
[https://www.typescriptlang.org/docs/handbook/2/types-from-types.html](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html)

### keyof

> keyof operator takes an object type and produces a string or numeric literal union of its keys.

`keyof`操作符接收一个对象类型并生成它所有的键的联合类型。这个操作符在我们后面结合`mapped types`时会用到。

### typeof

上面我们讲过的 typeof 就是第一个类型操作符了，在 ts 中，typeof 被重写了，不像 js 中对于基础类型会返回其类型，复杂类型会返回'object'。
对于`string`与`number`类型来说，typescript 又延伸出字面量类型（Literal Types），这里我们可以得知，只有字符串与数字类型有字面量类型，其余类型均没有。那么如何声明一个字面量类型呢？
第一种方法：通过类型声明强制表明

```typescript
let numberOne: "first" = "first";
numberOne = "second"; // Type '"second"' is not assignable to type '"first"'
```

这个时候变量`numberOne`就是一个字面量类型，仅可以被赋值为`'first'`，其余的字符串类型都不可以。而如果没有`: "first"`的类型声明，那么 typescript 会将变量`numberOne`作为 string 类型，所有的 string 类型都可以赋值给它。
另一种方法就是使用`const`来声明变量：

```typescript
const numberOne = "first";
type typeOfNumberOne = typeof numberOne; // type typeOfNumberOne = "first"
```

还可以通过`as const`也就是[const assertion](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-4.html#const-assertions)

```typescript
let numberOne = "first" as const;
// 或者let numberOne = <const>"first"，在tsx中不可以使用
```

理解了字面量类型后，再介绍一下基于字符串的字面量类型——模板字符串类型，类似 es6 新增的模板字符串的功能，通过`${type}`可以组合成字面量类型。举个例子：

```typescript
type Str1 = "Sleep";
type SD = `${Str1}_Devil`; // type SD = "Sleep_Devil"
```

而当模板字符串里的类型不是字符串，而是联合字符串时，生成的类型会自动遍历所有的取值，类似于分布式条件类型（[Distributive Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types)），举个例子：

```typescript
type Str1 = "Sleep" | "UnSleep";
type Str2 = "Devil" | "God";
type SD = `${Str1}_${Str2}`; // type SD = "Sleep_Devil" | "Sleep_God" | "UnSleep_Devil" | "UnSleep_God"
```

可以看到，会将联合类型中的每一种可能都组合并展示出来。

模板字符串的功能不仅仅可以用来组合新类型，也可以用来进行模式匹配修改已有字符串类型，看一下这个题目：

```typescript
type A = {
  aa: string;
  Bb: string;
  cc_Dd: string;
};

type B = {
  aa: string;
  bb: string;
  ccDd: string;
};

// 写一个CamelType将A转换成B
type CamelType<T> = unknown;
```

对于这种字符串变量的修改，我们可以通过模式匹配来创建匹配的类型并通过 ts 内置的对字符串类型进行操作的类型运算符进行操作。
首先，我们可以通过

```typescript
 type CamelType<T> = T extends `${infer LeftStr}_${infer RightStr}`; // tobeContinued
```

来获取到下划线左右两边的字符串，并分别取名为`LeftStr`与`RightStr`，
`extends`是 ts 中的 conditional type，类似编程语言中常见的三元运算符，接着来完善一下我们的类型：

```typescript
type CamelType<T> = T extends `${infer LeftStr}_${infer RightStr}`?`${LeftStr}${Capitalize<RightStr>}`;
```

`Capitalize`是 ts 内置的一个[Utility Type](#utility-types)，可以将字符串类型首字母大写，所以接下来我们只需要将`type A`中的每一个键都调用一下`CamelType`，值类型保持不变即可。
创建一个新的类型对象一般有两种方法，一是通过`Record<Keys, Type>`内置类型操作符并传入两个类型，分别当做键和值的类型，这里的`Keys`与`Type`不仅可以传基础类型如 string、number 等，也可以传 union、interface 等复杂类型。另一种方式则是通过`mapped types`来生成。这里的场景是通过 A 类型产生 B 类型，所以适用`mapped types`。于是我们更改下之前的代码：

```typescript
type CamelType<T> = {
  [K in keyof T as CamelCase<K & string>]: T[K];
};
type CamelCase<T extends string> =
  T extends `${infer LeftStr}_${infer RightStr}`
    ? `${LeftStr}${Capitalize<RightStr>}`
    : T;
```

这里的`CamelType`采用了`mapped types`，`K`即为我们传入的对象的键，我们知道，js 中对象的键的类型只可以为 string、number、symbol，所以这也是`K`的类型，而由于我们的`CamelCase`只接受 string 类型，所以我们通过`K & string`交叉类型，来将`K`的类型限制为 string 类型。这样我们就实现了一个简单的工具类型，作用是将一个对象类型中的键由下划线分隔改为小驼峰式。

### Indexed Access Types

索引访问类型，可以帮助我们查看某个对象类型上的某个指定的键所对应的类型，例如：

```typescript
type People = {
  age: number;
  gender: string;
};

type PGender = People["gender"]; // type PGender = string
```

索引访问类型也可以结合`keyof`操作符实现对象类型->联合类型的转化，看一下这个题目：

```typescript
interface Values {
  email: string;
  firstName: string;
  lastName: string;
}

type ValuesAsUnionOfTuples = unknown; // to be implemented

type tests = [
  Expect<
    Equal<
      ValuesAsUnionOfTuples,
      ["email", string] | ["firstName", string] | ["lastName", string]
    >
  >
];
```

要我们根据`Values`类型生成一个 union 类型，这个联合类型中每一个子项为数组，数组的第一项是`Values`的 key，第二项是 key 对应的类型，这时就需要用到索引访问类型加`keyof`操作符实现对象到联合类型的转化。

我们先根据`Values`对象生成一个新的对象类型，键还保持不变，值变为联合类型中的子项：

```typescript
type ValuesAsUnionOfTuples = {
  [K in keyof Values]: [K, Values[k]];
};

// type ValuesAsUnionOfTuples = {
//     email: ["email", string];
//     firstName: ["firstName", string];
//     lastName: ["lastName", string];
// }
```

最后我们通过索引访问类型结合`keyof`操作符即可生成由`ValuesAsUnionOfTuples`所有值类型组成的联合类型：

```typescript
type ValuesAsUnionOfTuples = {
  [V in keyof Values]: [V, Values[V]];
}[keyof Values];
```

## Utility Types

### Pick<Type, Keys>

当我们定义好一个完整的接口响应后，可能接口实际返回的只有其中的几个，这个时候可以通过`Pick`内置类型来实现，看源码可以得知，采用了`mapped types`映射类型，返回的是一个新的对象，包含了指定的键及其对应的值。

```typescript
type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
};
```

### Extract<Type, Union>

和`Pick`很类似，区别在于`Extract`常用于从联合类型中取指定的值，因为`Pick`只可以获取到对象类型中的键，而对于联合类型则无能为力。源码写的很简单：

```typescript
type Extract<T, U> = T extends U ? T : never;
```

但这其中隐藏了一个知识点——[Distributive Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types)，所谓的`Distributive Conditional Types`，就是当联合类型遇到条件类型时，会自动对所有可能进行遍历并求值，举个例子：

```typescript
type T0 = Extract<"a" | "b" | "c", "a" | "f">; // type T0 = "a"
```

可以看到，`Extract`类型的第一个参数为`"a" | "b" | "c"`，第二个参数为`"a" | "f"`，
带入到源码的话就是：

```typescript
type T0 = "a" | "b" | "c" extends "a" | "f" ? "a" | "b" | "c" : never;
```

如果我们按照普通的条件类型来看的话，`type T0`最终的结果只有可能是`"a" | "b" | "c"`或者是`never`，但是实际上并不是这样，这就是所谓的`Distributive Conditional Types`。

实际上，ts 会把联合类型中的每一个子项都分开一个一个执行条件类型判断，带入到代码中就是：

```typescript
"a" extends "a" ? "a" : never
"b" extends "a" ? "b" : never
"c" extends "a" ? "c" : never
"a" extends "f" ? "a" : never
"b" extends "f" ? "b" : never
"c" extends "f" ? "c" : never
```

最终可以看到，只有第一个符合条件，所以`T0`就为字面量类型`a`，如果有多个符合类型的，则是这多个组成的联合类型。

## 优雅的重写第三方库的类型定义

在 axios 的使用中，我个人经常喜欢在响应拦截器中提前返回 data，因为我们前后端约定好了状态码，这些都是在 data 中返回的，`AxiosResponse`中其余字段用不上，所以我会写如下的拦截器：

```typescript
axios.interceptors.response.use((res) => {
  res = res.data;
  return res;
});
```

但是作为一名合格的 ts 工程师，你会发现，在代码中使用的时候 ts 的类型推导并没有返回`AxiosResponse['data']`，而仍然是默认的返回值，让我们打开 axios 的类型定义：

```typescript
export class Axios {
  get<T = any, R = AxiosResponse<T>, D = any>(
    url: string,
    config?: AxiosRequestConfig<D>
  ): Promise<R>;
}
```

从 get 方法的定义我们可以看出，返回值是 Promise<AxiosResponse<T>>，这里的 T 也就是我们传给 axios.get 的第一个泛型，就是我们约定好的返回值。那么我们如何才能改变它的返回值来让它符合我们的拦截器所做的操作呢？

```typescript
import axios from "axios";

declare module "axios" {
  export interface Axios {
    get<T = any>(url: string, config?: AxiosRequestConfig): Promise<T>;
  }
}
```
我们可以新建一个`.d.ts`类型文件，通过`declare module "axios"`并导出我们自己的`Axios`对象类型来覆盖axios默认的类型，这样，返回值被我们修改为我们传入的第一个泛型类型了，不再是经过`AxiosResponse<T>`包裹之后的了，我们也就可以继续享受ts+编辑器带来的类型提示了~
