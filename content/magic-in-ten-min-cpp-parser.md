+++
title = "C++实现10分鈡魔法parser"
description = ""
date = 2025-10-20 10:44:22+08:00
path = "magic-in-ten-min-cpp-parser"
[taxonomies]
tags = ["c++", "magic", "函数式编程", "monad"]
categories = ["blog"]
+++

十分鈡魔法中2个parser部分其他语言都没实现：https://magic.huohuo.moe/html/ParserM.html https://magic.huohuo.moe/html/Parsec.html  
自己试着用c++实现一下。  
<!-- more -->

原版省略的不少内容，理解起来稍微费劲。应该是参考的这两份文章实现的，可以前置先了解一下：https://people.cs.nott.ac.uk/pszgmh/monparsing.pdf https://people.cs.nott.ac.uk/pszgmh/pearl.pdf

# 解析器单子

属于一种函数生成器，生成的函数输入待解析内容，返回(结果, 剩余待解析内容)  
类似于这样的函数签名:

```c++
template <class T>
std::option<std::pair<T, std::string_view>> parse(std::string_view);
```

C++不需要HKT包装一层,原java实现是monad持有一个parser对象用来执行。  
这里就直接在parser monad里面带个可执行对象用来执行  


最终实现如下：  

```c++
#include <optional>
#include <functional>
#include <utility>
#include <vector>
#include <string_view>
#include <iostream>

template <class T>
using Maybe = std::optional<T>;

template <class T>
class Parser {
public:
    Parser() = delete;
    Parser(std::function<Maybe<std::pair<T, std::string_view>>(std::string_view)> action): op(action) {
    }
    ~Parser() {
    }

    Maybe<std::pair<T, std::string_view>> run(std::string_view s) const {
        return op(s);
    }

    // 封装值内容到Parser中
    static Parser<T> pure(T value) {
        Parser<T> p([value] (std::string_view res) -> Maybe<std::pair<T, std::string_view>> {
            Maybe<std::pair<T, std::string_view>> ret({value, res});
            return ret;
        });
        return p;
    }

    static Parser<T> fail() {
        Parser<T> p([] (std::string_view) {
            return std::nullopt;
        });
        return p;
    }

    // 本身内容叠加输入操作
    template <class U>
    Parser<U> flatMap(std::function<Parser<U>(T)> f) const {
        Parser<U> parser([self=*this, f](std::string_view s) -> Maybe<std::pair<U, std::string_view>> {
            auto res = self.run(s);
            if (!res) {
                return std::nullopt;
            }

            Parser<U> next = f(res->first);
            return next.run(res->second);
        });
        return parser;
    }

    template <class U>
    Parser<U> map(std::function<U(T)> f) {
        return flatMap<U>([f](T x) {
            return Parser<U>::pure(f(x));
        });
    }

    template <class U, class V>
    Parser<V> combine(Parser<U> p, std::function<V(T, U)> f) const {
        return flatMap<V>([=] (T a) {
            return p.template flatMap<V>([=] (U b) {
                return Parser<V>::pure(f(a,b));
            });
        });
    }

    template <class U>
    Parser<T> skip(Parser<U> p) const {
        return combine<U, T>(p, [](T a, U) {
            return a;
        });
    }

    template <class U>
    Parser<U> use(Parser<U> p) const {
        return combine<U, U>(p, [](T, U b) {
            return b;
        });
    }

    // or居然是keyword
    Parser<T> or_(Parser<T> p) const {
        Parser<T> parser([self=*this, p](std::string_view s) -> Maybe<std::pair<T, std::string_view>> {
            auto res = self.run(s);
            if (res) {
                return res;
            } else {
                return p.run(s);
            }
        });
        return parser;
    }

    Parser<std::vector<T>> many() const {
        Parser<std::vector<T>> parser([self=*this](std::string_view s) -> Maybe<std::pair<std::vector<T>, std::string_view>> {
            auto res = self.run(s);
            if (!res) {
                return std::make_pair(std::vector<T>(), s);
            }

            // 递归处理剩余部分
            auto many_parser = self.many();
            auto rs = many_parser.run(res->second);
            if (rs) {
                std::vector<T> values = rs->first;
                values.insert(values.begin(), res->first);
                return std::make_pair(values, rs->second);
            }

            std::vector<T> values;
            values.insert(values.begin(), res->first);
            return std::make_pair(values, res->second);
        });
        return parser;
    }

    // many1
    Parser<std::vector<T>> some() const {
        return flatMap<std::vector<T>>([self=*this](T x) {
            auto many_parser = self.many();
            return many_parser.template flatMap<std::vector<T>>([x](std::vector<T> xs) {
                xs.insert(xs.begin(), x);
                return Parser<std::vector<T>>::pure(xs);
            });
        });
    }

private:
    std::function<Maybe<std::pair<T, std::string_view>>(std::string_view)> op;
};

int main() {
    Parser<char> id([](std::string_view s) -> Maybe<std::pair<char, std::string_view>> {
        if (s.empty()) {
            return std::nullopt;
        } else {
            return std::make_pair(s.front(), s.substr(1));
        }
    });

    auto pred = [id](std::function<bool(char)> f) {
        return id.flatMap<char>([f](char c) -> Parser<char> {
            if (f(c)) {
                return Parser<char>::pure(c);
            } else {
                return Parser<char>::fail();
            }
        });
    };

    auto character = [pred](char x) {
        return pred([x](char c) {
            return c == x;
        });
    };

    Parser<int> digit = pred([](char c) {
        return c >= '0' && c <= '9';
    }).flatMap<int>([](char c) {
        return Parser<int>::pure(c-'0');
    });

    Parser<int> nat = digit.some().map<int>([](std::vector<int> xs) {
        int ret = 0;
        for (auto x: xs) {
            ret = ret * 10 + x;
        }
        return ret;
    });

    Parser<int> integer = (character('-').use(nat).map<int>([](int i) {
        return -i;
    })).or_(nat);

    Parser<double> real = (integer.combine<double, double>(
        // 解析小数部分
        character('.')
        .use(digit.some())
        .map<double>([](std::vector<int> xs) {
            double ans = 0, base = 0.1;
            for (int i : xs) {
                ans += base * i;
                base *= 0.1;
            }
            return ans;
        }),
        // 整数和小数部分相加
        [](int a, double b) {
            double ret = fabs(a) + b;
            if (a < 0) {
                ret = -ret;
            }
            return ret;
        }))
        // 纯整数情况
        .or_(integer.map<double>([](int i) { return i;}));

    auto digitRes = digit.run("996");
    if (digitRes) {
        std::cout << "(" << typeid(digitRes->first).name() << ":" << digitRes->first << "," << digitRes->second << ")" << std::endl;
    }

    auto natRes = nat.run("1234");
    if (natRes) {
        std::cout << "(" << typeid(natRes->first).name() << ":" <<natRes->first << "," << natRes->second << ")" << std::endl;
    }

    auto integerRes = integer.run("-4321qwerty");
    if (integerRes) {
        std::cout << "(" << typeid(integerRes->first).name() << ":" <<integerRes->first << "," << integerRes->second << ")" << std::endl;
    }

    auto realRes = real.run("-114.514");
    if (realRes) {
        std::cout << "(" << typeid(realRes->first).name() << ":" <<realRes->first << "," << realRes->second << ")" << std::endl;
    }

    return 0;
}

```

输出：  

```
(i:9,96)
(i:1234,)
(i:-4321,qwerty)
(d:-114.514,)
```

@
