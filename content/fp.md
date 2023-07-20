+++
title = "函数式编程——从入门到放弃思考"
description = ""
date = 2023-07-20 23:38:19+08:00
path = "fp"
[taxonomies]
tags = ["函数式编程", "lambda演算", "c++", "python", "monad"]
categories = ["blog"]
+++

公司内部分享的内容。更多的是当参考资料用

<!-- more -->

# 理论基础

这里不做过多深入，只介绍了要理解函数式编程需要的一些基本概念。

## λ 演算

包含

1. 建构 lambda 项
2. 对 lambda 项执行[归约](https://zh.wikipedia.org/wiki/%E6%AD%B8%E7%B4%84 "归约")的操作

### 建构 lambda 项的规则

1. `x` 变量
2. `(λx.M)` lambda 表达式,M 是一个 lambda 项,其中的 x 绑定为变量`x`
3. `(M N)` N 作为参数应用 M（M、N 是 lambda 项）

### 归约

#### α-变换

`(λx.M[x]) → (λy.M[y])`  
替换变量不影响函数表示,上面是同一函数

#### β-归约

`((λx.M) E) → (M[x:=E])`  
参数可代替绑定变量(约束：x 在 E 中为自由变量)

#### η-变换

有以上 2 条 lambda 演算就完备了，eta 变换是为了方便额外引入的。表示外延等价。  
两个函数，即使内部算法不一样，只要输入一样输出一样，那么外延等价，可以当成同一个函数。  
例如：`x:(x+2)*2`和`x:2x+4`虽然不是同个函数，但是外延等价，可以当成同一个东西

### 丘奇数

表达式阶数  
0: `lambda s z.z`  
1: `lambda s z.s z`  
2: `lambda s z.s (s z)`  
简单理解：  
0：`lambda s z.z` => `z` 就表示零  
1: `lambda s z.s z` => `lambda s.(lambda z.s z)` =>`s z` 表示后继（++操作符）,`0++`  
2: `lambda s z. s (s z)` => `s (s z)` 表示++2 次 `(0++)++`  

#### 加法运算

`let add = lambda s z x y.x s (y s z)`  
有 4 个参数，x y 分别为要相加的两个数，s z 推导数字用（还记得丘奇数怎么表示数的吗）  
柯里化一下  
`let add = lambda x y.(lambda s z.(x s (y s z)))`  
可以看出加法就是数字丘奇数形式去算 y 个 0 的后继再算 x 个后继得到。

### 布尔运算

类似于 `if condition then a else b` 的形式  
true: `lambda x y.x`  
false: `lambda x y.y`  
借用一般 FP 语言的绑定关键字`let`来表示条件判断：

```
let if_then_else = lambda condition when_true when_false.conditon when_true when_false
```

其他布尔运算  
与：`let and = lambda x y.x y false`  
或：`let or = lambda x y.x true y`  
非：`let not = lambda x.x false true`  

### 元组

元组的基本组成：  

```
pair   = λ a. λ b. λ f. f a b
first  = λ p. p (λ x. λ y. x)
second = λ p. p (λ x. λ y. y)
```

我们想要得到一个列表 [1, 2, 3, ...]  
就可以这样表示

```
pair 1 (pair 2 (pair 3 ...))
```

### Y Combinator(Y 组合子)

让 lambda 表达式支持递归  
`let Y = lambda y.(lambda x.y (x x)) (lambda x.y (x x))`   
起到的效果是`(Y Y) = Y (Y Y)`，它作用是返回自己应用自己的结果  
推广为`(Y F) = F (Y F)`  
例如，阶乘函数  
定义  
`let metafact = lambda fact.(lambda n.is_zero n 1 (mult n(fact (pred n))))`  
接收一个高阶函数 fact，结果为 fact 的应用。`(metafact fact) n = fact n`。fact 函数就是 metafact 的一个定点.把 metafact 应用回去可以得到  
`fact n = (metafact metafact) n`即我们需要的阶乘函数

### 尝试在实际编程语言中推导出 lambda 形式的阶乘

这里以 python 为例，c++当然也可以，就是写起来太繁琐，无效干扰符号较多。  
第一步，尝试写个正常的递归阶乘看看

```python
def fact(n):
    if n < 2 : return 1
    else: return n * fact(n-1)
print(fact(5))
```

第二步，因为 lambda 无法调用自己，添加一个参数，将自己传入调用。顺便也写成 Python 的 lambda 表达式形式

```python
fact = lambda itself, n: 1 if n < 2 else n * itself(itself, n-1)
print(fact(fact,5))
```

第三步，lambda 算子只接收一个参数，第二步的例子里接收了两个参数，这里就要做柯里化处理掉。

```python
fact = lambda itself : lambda n : 1 if n < 2 else n * itself(itself)(n-1)
print(fact(fact)(5))
```

第四步，整理一下，将阶乘相关的业务逻辑放到内层(这里的 lambda n)，尝试提取出递归通用形式

```python
fact = lambda h : lambda n : (lambda q : lambda n : 1 if n < 2 else n * q(n-1))(h(h))(n)
print(fact(fact)(5))
```

最后可以提取出 Y 组合子，利用 Y 组合子得到 fact 函数  
第四步的`lambda n`就是之前说的`metafact`,提取出来，外层就是 Y 组合子。最后代码还是  
Y(metafact)的形式

```python
Y = lambda f:(lambda h:lambda n: f(h(h))(n))(lambda i: lambda p:f(i(i))(p))
fact = Y(lambda f:lambda n: 1 if n < 2 else n * f(n-1))
print(fact(5))
```

有了统一形式后，要将阶乘换成其他算法就很简单了。例如改成从 0 到 n 的累加函数，那么只需要替换掉 Y 组合子应用的内容即可

```python
Y = lambda f:(lambda h:lambda n: f(h(h))(n))(lambda i: lambda p:f(i(i))(p))
acc = Y(lambda f:lambda n: 0 if n == 0 else n + f(n-1))
print(acc(100))
```

## S、K、I 组合子

S: `S = lambda x y z.(x z (y z))` 即函数的应用  
K: `K = lambda x.(lambda y.x)` 生成的是个常函数，应用到任何参数上只会返回 K 的第一个参数  
I: `I = lambda x.x`恒等组合子，返回自身  
实际上仅用 S 和 K 就能组合出所有的组合子（前面提过的外延等价，但表达式不一定一样）。  
如`I`就可以用`S K K x`获得;  
`Y`可以用`S S K (S (K (S S (S (S S K)))) K)`表示  
定义如下转换函数`C`可以将任意 lambda 表达式转换为 SKI 组合子表达式：

1. `C{x} = x`
2. `C{E1 E2} = C{E1} C{E2}`
3. `C{lambda x. E} = K C{E}`
4. `C{lambda x.x} = I`
5. `C{lambda x.E1 E2} = (S C{lambda x.E1} C{lambda x.E2})`
6. `C{lambda x.(lambda y.E)} = C{lambda x. C{lambda y.E}}`
   因此 SKI 组合子表达式也是图灵完备的计算系统.实际上也已经有以 SKI 系统为基础的编程语言了：  
   http://www.madore.org/~david/programs/unlambda/  
   和  
   https://tromp.github.io/cl/lazy-k.html  
   有兴趣的话可以点进去感受一下纯粹的 SKI 符号怎么组成可用的程序的（又一个 brainfuck 的感觉,当然 bf 是模拟图灵机，根基和这两个不一样）

## 加入类型(简单类型化 lambda 演算)

类型化 lambda 演算新增 `基类型` 的概念,`基类型`通常用小写希腊字母表示，因为不好打这里用大写英文字母代替  
N -> 自然数  
B -> 布尔值  
S -> 字符串  
我们使用箭头`->`表示`函数类型构造器`，如果一个函数接收一个类型 N，返回一个类型 N 的结果，那么可以用`N -> N`来表示。  
需要注意的是，函数类型符号是右结合的，即
`A -> B -> C`等价于`A -> (B -> C)`   
我们用`:`来表示 lambda 项对应的类型（很多编程语言的变量类型指定语法就是用的`:`大概就是从这里借鉴来的）。  
例如最简单的`lambda x:N.x`这里就表示`x`的类型为自然数 N lambda 表达式自己也有类型，`(lambda x.x):N->N`它的类型就是`N->N`多参数的情况呢？  
`lambda x:N, y:B.if y then x _ x else x`类型是`N->B->N`,我们柯里化一下：`lambda x:N.(lambda y:B.if y then x _ x else x)`,括号中部分是`B->N`,外面是`N->(括号中部分的类型)`。  
替换一下就是`N->(B->N)`,因为是右结合所以等价于`N->B->N`

### 代数数据类型(ADT)

#### 积类型

同时包含多个值的类型。
例：

```c++
struct Framebuffer {
	GLuint texture;
	GLuint fbo;
	Size size;
};
```

`Framebuffer`类型是`GLuint`、`GLuint`和`Size`的积,表示为`GLuint * GLuint * Size`

#### 和类型

表示类型是什么。和继承的概念类似。

```c++
struct Data {};
struct File : public Data {
	string fileName;
	size_t dataLength;
};
struct MemoryData : public Data {
	vector<uint8_t> data;
	size_t dataLength;
};
// 或者用std::variant也可以表示
using Data = std::variant<File, MemoryData>;
// 用 std::holds_alternative<File/MeomoryData>
// 来判断具体是什么类型
```

`Data`可能是文件数据`File`也可能是内存数据`MemoryData`，`Data`类型是`File`和`MemoryData`的和。即`string * size_t + vector<uint8_t> * size_t`

#### 代数数据类型

就是`和类型`和`积类型`构造出来的数据类型。代数指的就是`和`、`积`操作。  
例如布尔类型

```c++
struct Boolean {};
struct True : public Boolean {};
struct False : public Boolean {};
// 或者variant版本
using Boolean = std::variant<True, False>;
```

再比如表示自然数

```c++
struct N {};
struct Z : public N {}; // 零
struct S : public N { // 后继其他自然数
	S(Nat* v): value (v){} //构造函数
	Nat* value; // 值
};
```

和丘奇数类似的构造（其实是基于自然数皮亚诺构造，自然数 n 由比他小 1 的数+1 得到）  
比如要表示 3，那么就是 `auto three = new S(new S(new S(new Z())))`,零++3 次得到。  
如何构造一个链表？看过 SICP 的话应该马上能反应过来了，利用 cons 对构造出来。

```c++
template <typename T>
struct List {};

template <typename T>
struct Nil : public List<T> {};

template <typename T>
struct Cons : public List<T> {
    Cons(T v, List<T>* n) : value(v), next(n) {}
    T value;
    List<T>* next;
};
```

表示[1,2,3]那么就构造
`List<int>* list = new Cons<int>(1, new Cons<int>(2, new Cons<int>(3, new Nil<int>())))`

#### ADT 实际应用

很适合用来构造序列化用的数据结构

```c++
class JsonValue {};

class JsonBool : public JsonValue {
    bool value;
};

class JsonInt : public JsonValue {
    int value;
};

class JsonString : public JsonValue {
    std::string value;
};

class JsonArray : public JsonValue {
    std::list<JsonValue> value;
};

class JsonMap : public JsonValue {
    std::map<std::string, JsonValue*> value;
};
```

### 余代数数据结构

因为 ADT 是归纳构造出来的，无法用来表示无限大的树（链表也是一种特殊的树）或者循环图（循环链表也是一种特例）。  
比如构造一个包含无限个 1 的 list

```c++
List* list = new Cons(1, list);
```

这个编译不过，构造 list 用到了他自己。  
这个时候就要用到余代数数据结构,他是自顶向下和 ADT 相反的构造思路。实际使用中需要以惰性求值的方式来构造，因为不这么做一开始就会无限计算循环下去。  
那么无限链表怎么实现？

```c++
class InfIntList {
public:
    int head;
    std::function<InfIntList()> next;
    InfIntList(int _head, std::function<InfIntList()> _next) :
        head(_head),
        next(_next) {}
};
class Codata {
public:
    static InfIntList infAlt() {
        return InfIntList(1, [] () {
            return InfIntList(2, infAlt);
        });
    }
};

int main() {
    std::cout << Codata::infAlt().head << std::endl;
    std::cout << Codata::infAlt().next().head << std::endl;
    std::cout << Codata::infAlt().next().next().head << std::endl;
    return 0;
}
```

这个例子作用是生成一个无限 1、2 循环的链表，这里的 next 起惰性计算的作用。  
很容易发现，这样的用法在很多编程语言里面都有类似的东西，比如 python 的生成器..  
这样对这种无限长度的数据结构做变换也不是不能办到了（map、fold 等操作)

### 单位半群

题外话：对群论感兴趣的话可以看看 https://www.zhihu.com/column/c_1317614473734565888 专栏中群论入门部分，相对来说通俗易懂

#### 半群

半群是一种代数结构，在集合  `A`  上包含一个将两个  `A`  的元素映射到  `A`  上的运算即  `<> : (A, A) -> A​` ，同时该运算满足**结合律**即  `(a <> b) <> c == a <> (b <> c)` ，那么代数结构  `{<>, A}`  就是一个半群。

比如在自然数集上的加法或者乘法可以构成一个半群，再比如字符串集上字符串的连接构成一个半群。

#### 单位半群(monoid)

单位半群是一种带单位元的半群，对于集合  `A`  上的半群  `{<>, A}` ， `A`  中的元素  `a`  使  `A`  中的所有元素  `x`  满足  `x <> a`  和  `a <> x`  都等于  `x`，则  `a`  就是  `{<>, A}`  上的单位元。

举个例子， `{+, 自然数集}`  的单位元就是 0 ， `{*, 自然数集}`  的单位元就是 1 ， `{+, 字符串集}`  的单位元就是空串  `""` 。
用代码表示像这样：

```c++
template <typename T>
class Monoid {
public:
    Monoid() {};
    virtual T empty() = 0; // 单位元
    virtual T append(T a, T b) = 0; // 操作（+/*之类的)
    T appends(const std::vector<T> &x) {
        return std::reduce(
            x.begin(), x.end(), empty(),
            std::bind(&Monoid<T>::append, this, std::placeholders::_1,
            std::placeholders::_2));
    }
};
```

我们的 CMTIKContainerFilter 其实也可以当成是个幺半群。  
id 是 nullptr, op 是 setFilter , 结果还是一个 CMTIKContainerFilter 的幺半群。  
示例：  
我们想要查找滤镜链中符合条件的第一个 Filter,可以这样实现

```c++
// 简化的CMTIKFilter类型
class CMTIKFilter {
public:
    CMTIKFilter(int id): mId(id){}
    CMTIKFilter* getFilter() { return mFilter; }
    int getId() { return mId; }
private:
    CMTIKFilter* mFilter = nullptr;
    int mId = 0;
};

class Query : public Monoid<CMTIKFilter*> {
public :
    Query(std::function<bool(CMTIKFilter*)> cond):mCond(cond) {}
    CMTIKFilter* empty() {
        return nullptr;
    }

    CMTIKFilter* append(CMTIKFilter* a, CMTIKFilter* b) {
        if (a && mCond(a)) { return a; }
        else if (b && mCond(b)) { return b; }
        else { return a; }
    }
private:
    std::function<bool(CMTIKFilter*)> mCond;
};

int main(void) {
    // 构造一个滤镜链
    std::vector<CMTIKFilter*> filters;
    for (int i = 1; i < 10; ++i) {
        filters.push_back(new CMTIKFilter(i));
    }
    CMTIKFilter* firstMatchMod3 = Query([](CMTIKFilter* f) { return f->getId() % 3 == 0; }).appends(filters);
    CMTIKFilter* firstMatchEq11 = Query([](CMTIKFilter* f) { return f->getId() == 11; }).appends(filters);
    if (!firstMatchMod3) {
        cout << "no filter matchs (id % 3 == 0)" <<endl;
    }
    else {
        cout << "filter id:" << firstMatchMod3->getId() << " matchs (id % 3 == 0)" << endl;
    }
    if (!firstMatchEq11) {
        cout << "no filter matchs (id == 11)" <<endl;
    }
    else {
        cout << "filter id:" << firstMatchEq11->getId() << " matchs (1d == 11)" << endl;
    }
    return 0;
}
```

输出：

```
filter id:3 matchs (id % 3 == 0)
no filter matchs (id == 11)
```

### 高阶类型（Higher Kinded Type,HKT)

简单理解，将一个类型映射到另一个类型的类型。还记得前面的`函数类型构造器`吗  
例如`std::vector`,将`T`映射到`std::vector<T>`类型，表示为 `(T -> std::vector<T>)`  
对于`std::map`来说有两个泛型参数`std::map<T,U>`那么就是把这两个参数组合映射到新的特化 map 类型。

### 单子（Monad）

可以看成是一种容器，`Monad<T>`封装一个 T 类型在里面。包含两种操作

1. pure 输入 T 类型数据，将他封装到 Monad 中并返回 ，`T -> Monad<T>`  
2. flatMap 输入另一个`Monad<T>`和一个操作函数`F`，将输入经过 F 处理后串起来。  
   Monad 原先是范畴论的一个概念，后面被引入到计算机领域中，在 Haskell 里被发扬光大。

#### List Monad

`std::vector`就可以看成是一种`list monad`,

```c++
template <class T>
void printV(std::vector<T> v) {
    for (auto i : v) {
        cout << i <<" ";
    }
    cout << endl;
}

template <class T>
std::vector<T> pure(T v) {
	return {v};
}

template <class T>
std::vector<T> flatMap(std::vector<T> v, std::function<std::vector<T>(T)> f) {
    return std::accumulate(v.begin(), v.end(), std::vector<T>(), [f](std::vector<T> ret, T i) {
        auto maped = f(i);
        ret.insert(ret.end(), maped.begin(), maped.end());
        return ret;
    });
}

int main(void) {
    std::vector<int> v { 1,2,3,4,5};
    auto flatMapV = flatMap<int>(v, [](int i) {
        return std::vector<int>{ -i, i};
    });

    cout << "origin v:"; printV(v);
    cout << "flatMap v:"; printV(flatMapV);
    auto pure3 = pure(3);
    auto flatMap3 = flatMap<int>(pure3, [](int i) {
        return std::vector<int>{ -i, i};
    });
    cout << "origin pure3:"; printV(pure3);
    cout << "flatMap flatMap3:"; printV(flatMap3);
    return 0;
}
```

这里 flatMap 传入的操作把每个元素展开为正负 2 个数。结果就是把这些展开结果串起来。  
输出：

```
origin v:1 2 3 4 5
flatMap v:-1 1 -2 2 -3 3 -4 4 -5 5
origin pure3:3
flatMap flatMap3:-3 3
```

#### Maybe Monad

`std::optional`就可以看成一种`Maybe Monad`，它封装了个值，可能存在也可能不存在。  
既然 monad 可以透过容器直接对内部数据进行操作，那么我们就可以使所有的函数都返回`std::optional`对象，操作失败没有值，成功就有值，这样很容易处理失败的情况。  
只需要通过 monad 的 flatMap 操作就可以透明地直接操作原始对象了。  
如下例：我们可以通过 then 将所有操作串起来，不需要单独处理无效输入的情况

```c++
template <class T>
class Maybe : public std::optional<T> {
public:
    Maybe(T v) : std::optional<T>(v) {}
    Maybe(std::nullopt_t n) : std::optional<T>(n) {}
    static Maybe<T> pure(T v) {
        return Maybe(v);
    }
    Maybe<T> flatMap(Maybe<T> v, std::function<Maybe<T>(T)> f) {
        if (v) {
            return f(v.value());
        }
        return std::nullopt;
    }
    Maybe<T> then(std::function<Maybe<T>(T)> f) {
        ops.emplace_back(f);
        return *this;
    }
    Maybe<T> eval() {
        return std::accumulate(ops.begin(), ops.end(), *this, [this](Maybe<T> v, std::function<Maybe<T>(T)> f) {
            return flatMap(v, f);
        });
    }
private:
    std::vector<std::function<Maybe<T>(T)>> ops;
};

template <class T>
void printM(Maybe<T> v) {
    if (v) {
        cout << *v << endl;
    }
    else {
        cout << "nullopt" << endl;
    }
}

int main(void) {
    auto add1 = [](int i) {
        cout << "add1" <<endl;
        return Maybe<int>::pure(i+1);
    };
    auto nag = [](int i) {
        cout << "nag"<<endl;
        return Maybe<int>::pure(-i);
    };
    auto doFail = [](int i) {
        cout << "doFail" <<endl;
        return std::nullopt;
    };
    Maybe<int> result = Maybe<int>(3)
        .then(add1)
        .then(add1)
        .then(nag)
        .eval();
    cout << "result:";
    printM(result);
    Maybe<int> failResult = Maybe<int>(3)
        .then(add1)
        .then(doFail)
        .then(nag)
        .eval();
    cout << "fail result:";
    printM(failResult);
    return 0;
}

```

输出：

```
add1
add1
nag
result:-5
add1
doFail
fail result:nullopt
```

### 状态单子

类似于状态机，输入一个状态返回一个状态，通过状态的转移来进行计算。可以不使用变量而计算出结果。  
参考：https://wiki.haskell.org/State_Monad  
我们实现一下上面 wiki 里的例 1，输入字符串，得到游戏分数

```c++
// <值，状态>
template <class T, class S>
class State {
public:
    using StateData = std::pair<T, S>;
    std::function<StateData(S)> runState;
public:
    State(){}
    State(decltype(runState) f):runState(f) {};
    // 单子基本操作
    State pure(T value) const {
        return State([value](S s) {
            return StateData{value, s};
        });
    }
    State flatMap(State ma, std::function<State(T)> f) const {
        return State([ma, f](S s) {
            StateData ns = ma.runState(s);
            return f(ns.first).runState(ns.second);
        });
    }
    // 状态单子相关，具体作用看haskell文档
    State get() {
        return State([](S s) -> StateData {
            return {s, s};
        });
    }
    State put(S s) const {
        return State([s](S v) {
            return StateData(v, s);
        });
    }
    State modify(std::function<S(S)> f) {
        return State([f](S s) -> StateData {
            return {s, f(s)};
        });
    }
};

// 尝试实现haskell状态单子wiki的示例
// 输入字符串包含a,b,c 3种状态，a分数+1，b分数-1，c切换游戏开关
using GameState = std::pair<bool, int>; // 定义状态，<游戏开关，分数>
State<GameState, GameState> playGame(std::string input) {
    State<GameState, GameState> s;
    // 输入处理完了，返回分数
    if (input.empty()) {
        return s.flatMap(s.get(), [s](GameState x) ->State<GameState, GameState> {
            return s.pure({x.first, x.second});
        });
    }
    // 还有输入，递归处理
    char head = input[0];
    std::string tail = input.substr(1);
    return s.flatMap(s.get(), [head, tail, s](GameState gs) -> State<GameState, GameState> {
            auto toNext = [tail](GameState) {
                return playGame(tail);
            };
            if (head == 'a' && gs.first) {
                return s.flatMap(s.put({gs.first, gs.second +1}), toNext);
            }
            else if (head == 'b' && gs.first) {
                return s.flatMap(s.put({gs.first, gs.second -1}), toNext);
            }
            else if (head == 'c') {
                return s.flatMap(s.put({!gs.first, gs.second}), toNext);
            }
            else {
                return s.flatMap(s.put({gs.first, gs.second}), toNext);
            }
        });
}

int main(void) {
    // 初始状态，初始游戏关、分数0
    GameState initGameState = {false, 0};
    cout << "ab result:" << playGame("ab").runState(initGameState).first.second <<endl;
    cout << "ca result:" << playGame("ca").runState(initGameState).first.second <<endl;
    cout << "cabca result:" << playGame("cabca").runState(initGameState).first.second <<endl;
    return 0;
}
```

输出：

```
ab result:0
ca result:1
cabca result:0
```

可以看到整个程序没有用到任何`变量`，全靠 playGame 的状态转移得到最后结果。  
这样不会用到全局关联的状态，调试起来也很简单。  
进一步 🤔，这跟我们的 xx 滤镜是不是很像，都是输入一堆步骤，一步一步应用下去得到最终结果，那么我们的 xx 滤镜是否也能用这种方式实现。

### CPS(续体传递风格)

简单说明就是，函数可以拆成每一个步骤单独一个函数，入参是前一步的结果，输出结果给下一步的形式。这就是异步回调的思想。实际上 C++20 的协程就是这么一个设计思路。  
如下例，func、func2、func3 是外延等价的

```c++
int func(int i ) {
    int ret = i;
    i += 1;
    i = -i;
    i *= 2;
    return i;
}

int func2(int i) {
    auto add1 = [](int i) { return i+1; };
    auto nag = [](int i) { return -i; };
    auto muti2 = [](int i) { return i*2; };
    return muti2(nag(add1(i)));
}

int func3(int i) {
    auto muti2 = [](int i) { return i*2; };
    auto nag = [muti2](int i) { return muti2(-i); };
    auto add1 = [nag](int i) { return nag(i+1); };
    return add1(i);
}

int main(void) {
    cout << "func(3):" << func(3) <<endl;
    cout << "func2(3):" << func2(3) <<endl;
    cout << "func3(3):" << func3(3) <<endl;
    return 0;
}
```

输出：

```
func(3):-8
func2(3):-8
func3(3):-8
```

我们可以按照这种风格实现一个 try-catch-final 流程

```c++
class TryCatch {
    std::function<void(std::exception& e)> mOnCatch;
public:
    void cTry(std::function<void(std::function<void()>)> body,
            std::function<void(std::exception&, std::function<void()>)> onCatch,
            std::function<void()> onNext
            ) {
        mOnCatch = std::bind(onCatch, std::placeholders::_1, onNext);
        body(onNext);
    }
    void cThrow(std::exception& e) {
        mOnCatch(e);
    }
};

void func(int i) {
    TryCatch t;
    t.cTry(
            // try
            [i,&t](std::function<void()> next) {
                cout << "try" <<endl;
                if (i == 0) {
                    auto e = std::range_error("counld not be 0");
                    t.cThrow(e);
                } else {
                    cout << "i="<< i<<endl;
                    next();
                }
            },
            // catch
            [](std::exception&e, std::function<void()> next ) {
                cout << "catch:" << e.what() << endl;
                next();
            },
            // final
            []() {
                cout << "final" << endl;
            }
        );
}

int main(void) {
    func(0);
    cout << "---\n";
    func(100);
    return 0;
}
```

输出：

```
try
catch:counld not be 0
final
---
try
i=100
final
```

# 用在实际编程上的特性

## 惰性求值

顾名思义，仅在需要的时候才执行计算。例如。  
一个 list [1,2,3,4,5]先做 x2 操作->[2,4,6,8,10]然后再取前 2 个 take 2->[2,4]  
非惰性求值情况，需要 list[1,2,3,4,5]里面所有元素都做 x2 操作，然后再取前 2 个，而惰性求值情况下可以在 take2 时分别触发 1 的 x2 和 2 的 x2 只计算这两个元素。  
这样甚至可以构造出无限序列来做后续操作，有点 python 中生成器的感觉。  
在 rust 中的容器操作(or java8 的 stream)其实也有惰性计算的影子。例如我们对一个序列进行 map/reduce 等操作后，实际上获取到的是一个惰性求值表达式，想要转成`Vec`等容器则需要调用  例如`collect<Vec>`这样的方法去触发计算真正生成出包含所有结果的 Vec 对象。

## 纯函数

lambda 表达式本身不存在变量概念，所有函数都是纯函数，即确定输入那么对应输出就是唯一确定的，不被环境所影响，并且也不带副作用，不会影响到环境中的其他元素。  
这样的特性带来的好处有：

1.  所有输入输出都是固定的，那么单元测试就很好做，不需要考虑到各种各样环境组合的影响。
2.  在并发编程情况下无敌。因为并发编程下最大的问题是由于数据共享带来的数据竞争问题。都使用纯函数的情况下就不存在数据竞争问题，可以充分的利用处理器多核特性并发处理计算。  
    又有。例如 c++的 stl 里`std::reduce`等算法，提供了参数可以使用并行版本的算法，因为是对序列应用一个 lambda 函数，每个元素之间的运算没有依赖关系，也可以很好的利用这个特性做并行计算优化。

### 高阶函数实现缓存

耗时的计算可以使用缓存来减少重复计算量。  
如下例，实现了个斐波那契数列计算函数和缓存函数。  
顺便还写了个计算时间的封装，最后调用的这个函数在基本斐波那契数列计算的基础上，叠加了缓存和计算耗时的能力。

```c++
uint64_t fib(uint64_t i) {
    if (i == 0) { return 0; }
    else if (i == 1) { return 1; }
    else {
        return fib(i-1) + fib(i-2);
    }
}
auto cache(std::function<uint64_t(uint64_t)> cal, std::map<uint64_t, u_int64_t> cacheMap) {
    auto cachedCal = [&cacheMap, cal](int64_t i) {
        if (auto it = cacheMap.find(i); it != cacheMap.end()) {
            cout << "cached "<< i <<"->"<<it->second<<endl;
            return it->second;
        }
        else {
            uint64_t ret = cal(i);
            cacheMap[i] = ret;
            cout << "push cache "<< i <<"->"<<ret<<endl;
            return ret;
        }
    };
    return cachedCal;
}

template<class F>
auto timeIt(F fn) {
    auto ret = [fn](uint64_t i) {
        auto start = std::chrono::steady_clock::now();
        auto ret = fn(i);
        auto end = std::chrono::steady_clock::now();
        auto dur = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
        cout << "fn(" << i<< ") cost " << dur << "ms" <<endl;
        return ret;
    };
    return ret;
}

int main(void) {
    std::map<uint64_t, uint64_t> cacheMap;
    auto cachedFib = timeIt(cache(fib, cacheMap));
    cout << cachedFib(35) << endl;
    cout << cachedFib(35) << endl;
    return 0;
}
```

输出如下：

```
push cache 35->9227465
fn(35) cost 95ms
9227465
cached 35->9227465
fn(35) cost 0ms
9227465
```

可以看到第二次计算基本不耗时了。  
再例如：  
业务中常见的失败重试。定义一个 retry，接受要重试的操作和重试次数、重试间隔。  
使用时组合起来得到一个自动带有重试功能的原功能函数。

```c++
char* doSomething() {
    static int i = 0;
    if (i == 3) {
        return "success";
    }
    i++;
    return nullptr;
}

template<class F>
auto retry(F f, size_t count, int waitTime) {
    return [count, waitTime, f] {
        char* ret = nullptr;
        size_t cnt = count;
        while(cnt > 0) {
            ret = f();
            if (!ret) {
                cout << "failed. wait for "<< waitTime<<"ms to retry" << endl;
                std::this_thread::sleep_for(std::chrono::milliseconds(waitTime));
                cnt--;
            } else {
                return ret;
            }
        }
        return ret;
    };
}

int main(void) {
    auto getResult = retry(doSomething, 5, 100);
    cout << getResult() << endl;
    return 0;
}
```

输出：

```
failed. wait for 100ms to retry
failed. wait for 100ms to retry
failed. wait for 100ms to retry
success
```

通过这种方式实现了非侵入式的功能扩充。每个函数只需要实现自己该做的事就好，需要定制就交给其他函数去做，最后再组合在一起。

### Monad

抹平类型、延迟计算  
`CMTIKContainerFilter`就可以看成是一个 Monad，将贴纸、视频、序列帧等封装在里面，在拼图中统一只对 container 进行处理即可，不需要关注实际上他的具体类型不需要特殊处理。  
并且只有在调用 container 的`doFilterEffect`时才会调用内部实际 filter 的`doFilterEffect`进行计算。  
monad 还可以将非纯函数转为纯函数进行组合计算，只有在最后惰性计算触发时才真正会导致实际的副作用产生。  
例：

```c++
int addRandom(int i) {
    std::random_device dev;
    std::mt19937 rng(dev());
    std::uniform_int_distribution<std::mt19937::result_type> dist100(1,100);
    return i + dist100(rng);
}

int addThree(int i) {
    return i + 3;
}

class Monad : public std::vector<std::function<int(int)>> {
public:
    Monad(std::function<int(int)> v) { emplace_back(v); }
    Monad() {  }
    static Monad pure(std::function<int(int)> v) { return {v}; }
    Monad then(Monad v) {
        auto ret = *this;
        ret.insert(std::end(ret), v.begin(), v.end());
        return ret;
    }
    static Monad flatMap(Monad v, std::function<Monad(std::function<int(int)>)> f) {
        if (v.empty()) {
            return v;
        }
        else {
            auto head = v.front();
            auto maped = f(head);
            auto tail = Monad();
            tail.insert(tail.end(), v.begin()+1, v.end());
            auto restMaped = flatMap(tail, f);
            maped.insert(maped.end(), restMaped.begin(), restMaped.end());
            return maped;
        }
    }
                  
    int eval(int i) {
        return std::accumulate(std::begin(*this), std::end(*this), i, [](int a, std::function<int(int)> f){
             return f(a);
        });
    }

};

int main(void) {
    auto addTripleThree = Monad(addThree).then(Monad(addThree)).then(Monad(addThree));
    auto addTripleThreeAddRandom = addTripleThree.then(Monad(addRandom)); // 这里tripleThreeAddRandom是确定的，类型是个函数,then过程是纯的
    // 利用flatMap可以实现AOP，这里注入一个打印每一步结果的操作
    auto printStep = Monad::flatMap(addTripleThreeAddRandom, [](std::function<int(int)> f) {
        return Monad::pure([f](int i){
            int ret = f(i);
            cout << "step result:" << ret << endl;
            return ret;
        });
    });
    cout << "addTripleThree:"<< addTripleThree.eval(100) << endl;
    cout << "tripleThreeAddRandom:" << addTripleThreeAddRandom.eval(100) << endl; // 这里调用eval的时候才真正执行副作用
    cout << "addTripleThree:"<< addTripleThree.eval(100) << endl;
    cout << "tripleThreeAddRandom:" << addTripleThreeAddRandom.eval(100) << endl;
    cout << "printStep:"<< printStep.eval(100) << endl;
    return 0;
}
```

输出

```
addTripleThree:109
tripleThreeAddRandom:190
addTripleThree:109
tripleThreeAddRandom:145
printStep:step result:103
step result:106
step result:109
step result:202
202
```

这里把非纯函数 addRandom 封装到 Monad 中，处理过程始终是纯的，没有随机情况没有副作用。只有最后.eval()的时候才真正执行非纯部分。  
monad 还有很多其他类型：Maybe 单子、List 单子、IO 单子、Writer 单子

### 函数响应式编程

相关资料：https://reactivex.io/  
提供了个类似于 linq 的观察者模式框架。各个语言实现：RxCpp,RxJava,RxSwift  
核心是关注数据流，以函数式编程的思想将多个纯函数组合起来,以提高代码可读性可维护性的方式处理业务逻辑。  
c++20 的 ranges 提供了类似的接口，但缺少任务调度部分，如果有需要可能需要基于 c++20 的协程框架自行实现。  

### 其他

当然实际应用的时候也不需要严格按照 lambda 演算的规则去应用。这样往往会有效率问题。  
例如我们进行数值计算就没必要用丘奇数计算，使用丘奇数计算的话数值有多大就要计算几次，效率很低。我们大可以利用外延等价特性使用普通计算函数替代。

## 通往黑魔法世界的门缝

C++有个很强大的部分，模板。  
我们思考，模板是图灵完备的，并且模板做计算的元函数都是纯函数。那么有没有可能在 c++的模板上实现一套 monad 呢？  
要在模板上实现计算，就要把一切都以类型的形式表示。函数就要实现为一个高阶类型，模板参数就是函数调用的入参。

```c++
// 实现流程控制
template <bool Cond, typename Then, typename Else>
struct IfThenElse;

template <typename Then, typename Else>
struct IfThenElse<true, Then, Else> {
    using value = Then;
};

template <typename Then, typename Else>
struct IfThenElse<false, Then, Else> {
    using value = Else;
};

// monad,以tag表示具体类型
template <typename Tag>
struct Monad;

// 错误类型
template <typename T>
struct MError;

// 实现默认的Monad操作，默认有个Fail实现
template <class Tag>
struct MDefault{
    struct Fail {
        template <typename T>
        using  value = typename MError<T>::failed;
    };
};

// 以ADT方式实现一个列表
struct Nil;
template <typename H, typename T>
struct Cons {
    using car = H;
    using cdr = T;
    template <typename A>
    struct Append {
        using value = Cons<H, typename T::template Append<A>::value>;
    };
    template <>
    struct Append<Nil> {
        using value = Cons<H, T>;
    };
    template <typename L>
    struct AppendList {
        using value = Cons<H, typename T::template AppendList<L>::value>;
    };
    template <>
    struct AppendList<Nil> {
        using value = Cons<H, T>;
    };
};
// 空列表情况
template <>
struct Cons<Nil, Nil> {
    using car = Nil;
    using cdr = Nil;
    template <typename A>
    struct Append {
        using value = Cons<A, Nil>;
    };
    template <typename L>
    struct AppendList {
        using value = L;
    };
};

template <typename H>
struct Cons<H, Nil> {
    using car = H;
    using cdr = Nil;
    template <typename A>
    struct Append {
        using value = Cons<H, Cons<A, Nil>>;
    };
    template <typename L>
    struct AppendList {
        using value = Cons<H, L>;
    };
};
// 表示整数类型
template <int N>
struct Int {
    enum {
        value = N,
    };
};

// 实现一个list monad
struct ListTag;
template <>
struct Monad<ListTag> : MDefault<ListTag> {
    // a -> m a
    template <typename T>
    struct Pure {
        using value = Cons<T, Nil>;
    };
    // m a -> (a -> m b) -> m b
    template <typename T, template <typename> class F>
    struct FlatMap {
        // 如果T有值
        // 返回 F(head).appendList(Flatmap(tail, F))
        // 否则直接返回T，终止递归
        using value = typename F<typename T::car>::value::
                          template AppendList<
                              typename FlatMap<
                                  typename T::cdr, F
                              >::value
                          >::value;
        // 使用IfThenElse需要把car和cdr改成lazy，嵌套层数太深不好理解先按正常模板方式处理
        //using value = typename IfThenElse<std::is_same<T, Nil>::value,
        //        // 结束情况，返回F(T)
        //        typename F<typename T::car>::value,
        //        // 有值情况，递归
        //        typename F<typename T::car>::value::template AppendList<typename FlatMap<typename T::cdr, F>::value>::value
        //        >::value;
    };
    template <template <typename> class F>
    struct FlatMap<Nil, F> {
        using value = Nil;
    };
};

// 辅助输出函数
template <typename T>
void printList() {
    using carType = typename T::car;
    cout << carType::value << ", ";
    if constexpr (!std::is_same_v<typename T::cdr, Nil>) {
        printList<typename T::cdr>();
    }
}

// 和前面的list monad例子一样，每个元素展开为 [ -i, i ]
template <typename T>
struct Func {
    using value = typename IfThenElse<std::is_same<T, Nil>::value, Nil, Cons<Int<-T::value>, Cons<T, Nil>>>::value;
};

int main(void) {
    // 构造初始列表 [1, 2, 3, 4, 5]
    using initList = Cons<Int<1>, Cons<Int<2>, Cons<Int<3>, Cons<Int<4>, Cons<Int<5>, Nil>>>>>;
    // 测试构造的列表是否正常
    using testList = Cons<Int<6>, Cons<Int<7>, Cons<Int<8>, Cons<Int<9>, Cons<Int<10>, Nil>>>>>;
    using testAppend = initList::Append<Int<6>>::value::Append<Int<7>>::value::Append<Int<8>>::value;
    using testAppendList = initList::AppendList<testList>::value;
    cout << "testAppend:";
    printList<testAppend>();
    cout << endl;
    cout << "testAppendList:";
    printList<testAppendList>();
    cout << endl;
    // 同之前list monad的测试
    cout << "initList:";
    printList<initList>();
    cout << endl;
    // 应用FlatMap
    using finalList = Monad<ListTag>::FlatMap<initList,  Func>::value;
    cout << "finalList:";
    printList<finalList>();
    cout << endl;
    return 0;
}
```

输出：

```
testAppend:1, 2, 3, 4, 5, 6, 7, 8,
testAppendList:1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
initList:1, 2, 3, 4, 5,
finalList:-1, 1, -2, 2, -3, 3, -4, 4, -5, 5,
```

和之前 list monad 的输出结果一样。证明了使用 c++模板也能基于 monad 实现各种各样的功能。  
C++的黑魔法：模板元编程 这么神奇，那么哪里可以学到呢？ 
**前面的区域以后再来探索吧**

# 参考资料

https://cgnail.github.io/academic/lambda-1/  
https://zh.wikipedia.org/zh-sg/%CE%9B%E6%BC%94%E7%AE%97  
https://magic.huohuo.moe/  
想要更详细的纯数学概念和更多数学证明可以看专栏：
https://zhuanlan.zhihu.com/lambda-calculus  
https://www.sciencedirect.com/science/article/pii/S0167642313000051
