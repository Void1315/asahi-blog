---
title: "C++ 智能指针之引用计数"
description: "实现一个固定类(String)的引用计数类`StringRc`（不允许使用泛型，所以只能支持特定类型）。"
publishDate: "2024 05 31"
tags: ["C++", "智能指针", "引用计数"]
---


实现一个固定类(String)的引用计数类`StringRc`（不允许使用泛型，所以只能支持特定类型）。

`StringRc`的功能是通过引用计数来管理`String`的资源，所以`String`本身存在需要在堆上（不理解后面解释吧）。`StringRc`可以进行`clone`签出新的不可变引用（此处不可变引用为设计层面，实际代码中我们无法做到不可变）。

## 实现

### `String`类

设计一个`String`类，其中需要实现`String`类的析构、拷贝构造（深拷贝）。

```c++
// String.h 文件
class String{
  char* m_pBuffer = nullptr; // 字符串缓冲区
	int m_nLength = 0; // 字符串长度 字符串以'\0'结尾 字符串长度不包含\0
	int m_nBufferSize = 0; // 缓冲区大小
public:
	String();
  String(const char* str);
  ~String();
  String(const String& str);
  String(String&&); // 移动构造函数  
}
// String.cpp 文件
String::String() {
    m_pBuffer = new char[1];
    m_pBuffer[0] = '\0';
    m_nLength = 0;
    m_nBufferSize = 1;
}

String::String(const char* str) {
    m_nLength = strlen(str);
    m_nBufferSize = m_nLength + 1;
    m_pBuffer = new char[m_nBufferSize];
    strcpy_s(m_pBuffer, m_nBufferSize, str);
}

String::~String() {
    std::cout << "String的析构" << std::endl;
    if (m_pBuffer != nullptr) {
        delete[] m_pBuffer;
        m_pBuffer = nullptr;
    }
    m_nBufferSize = 0;
    m_nLength = 0;
}

String::String(const String& str) {
  std::cout << "String 拷贝构造(深拷贝)!" << std::endl;
    m_nLength = str.m_nLength;
    m_nBufferSize = str.m_nBufferSize;
    m_pBuffer = new char[m_nBufferSize];
    strcpy_s(m_pBuffer, m_nBufferSize, str.m_pBuffer);
}
```

**不要看代码，看我！**

没时间解释了，我们只看最重要的。

- `String`中定义一个字符串缓冲区`m_pBuffer`用来模拟管理一个堆内存。
- `String::String(const char* str)`是为了我们能从一个字符串字面值便捷的创建一个`String`对象。
- 析构和默认构造没什么好说的，创建和销毁我们没有做特别的事情。
- `String::String(const String& str)`我们定义了一个拷贝构造函数，它的作用是以`str`为原型，创建一个新的`String`对象，两者资源不共享。（将`str`中的资源，深拷贝到新的`String`对象）。

---

### `StringRc`类

`StringRc`的功能是持有一个`String`类的资源，并且能通过`clone`方法进行签出新的`StringRc`对象。

通过`StringRc A`对象签出的`StringRc B`对象，两者共同持有一个`String`对象的资源。在设计层面我们不对外提供这个`String`对象的成员（不`public`这个`String`对象成员），来达到`StringRc`为一个资源的多个不可变引用。

```c++
// StringRc.cpp
#include "StringRc.h"

StringRc::StringRc(String&& str) {
    strRef = new String(str); // 智能指针来管理堆内存 深拷贝String 目的是为了将String本身移动到堆
    strong_count = new uintmax_t(1); // 初始化引用计数
}

StringRc::~StringRc() {
    *strong_count = *strong_count - 1;
    if (*strong_count <= 0) {
        SAFA_DELETE(strong_count);
        SAFA_DELETE(strRef);
    }
}

StringRc::StringRc(const StringRc& origin) {
    // 浅拷贝 资源以及强引用计数器
    strong_count = origin.strong_count;
    *strong_count = *strong_count + 1;
    strRef = origin.strRef;
}

StringRc StringRc::clone(StringRc& strRc) {
    return StringRc(strRc); // 调用拷贝构造函数
}

uintmax_t StringRc::getStrongCountNum() {
    return *strong_count;
}

```



```c++
// StringRc.h
#pragma once
#include "String.h"
#include <cstdint>
#define SAFA_DELETE(x) if(x!=nullptr){delete x;}
/*
引用计数增加:
1. 新建Rc的时候(new的时候).
2. clone的时候. 实际上使用的是Rc的拷贝构造函数 在拷贝构造中增加引用计数

*/

class StringRc {
private:
    uintmax_t* strong_count = nullptr; // 强引用计数
    String* strRef = nullptr;
public:
    StringRc(String&& str); // 移动构造一个引用计数器 强制资源丢到堆上
    ~StringRc();
    StringRc(const StringRc& origin); // 拷贝构造

    static StringRc clone(StringRc& strRc);
    uintmax_t getStrongCountNum();

};


```

**解析**

- 我们定义了一个公共构造方法`StringRc::StringRc(String&& str)`。
  - 为什么我们要使用`String`的右值引用来构造`StringRc`？答：因为在设计上，我们希望`StringRc`获取这个`String`的所有权，也就是将原来的`String`变为只有`StringRc`对象持有，所以我们需要用显式的右值引用来告诉开发者，我们需要你资源的所有权。这样我们在各个`StringRc`的对象之间共享`String`资源的时候不会发生：
    - `String`资源的意外释放。（不转移所有权时，有没有可能有一个逻辑去主动释放`String`所持有的资源？有可能！）
    - `String`资源的意外修改。（理由同上，我们无法保证不存在外部的修改。我们不希望有外部的修改，因为这对于`StringRc`来说是一个黑盒操作，我们的所有引用计数指向的资源被意外的修改，这是反直觉的。）
  - 我们在构造中使用了`String(str)`来深拷贝这个资源，目的是为了将`String`本身移动到堆，因为我们并不清楚这个资源本身是存在堆还是栈，如果是栈，那么这个资源会被栈主动回收。当`String`本身被回收时，如果我们的`StringRc`没有被回收，就会出现悬垂引用。
    - 我们用生命周期来解释这个操作。因为`StringRc`来保存`String`的引用，所以`String`本身一定要比所有的`StringRc`活得更久！生命周期的重要规则：被引用者的生命周期一定要大于等于（或者不小于）引用者本身的生命周期。在实际应用中，我们不清楚`StringRc`本身的生命周期，它有可能要跨多个函数，所以一定要保证`String`不会被意外释放！
- 接下来看我们的`static StringRc clone(StringRc& strRc);`方法。
  - `clone`是一个静态，设计目的是为了以`StringRc& strRc`这个智能指针为源，签出一个新的`StringRc`对象，让这两个`StringRc`同时指向一个`String`资源对象。
  - 在`clone`中，我们使用了拷贝构造方法`StringRc(const StringRc& origin);`，新签出的`StringRc`对象，浅拷贝`strong_count`和`strRef`，并使得`strong_count`强引用计数器进行增加1。
- 最后我们看智能指针对象的析构方法`~StringRc();`。
  - 析构方法很好理解，每当一个`StringRc`对象进行析构的时候，我们会通过减少它们公共的强引用计数器来进行无损耗析构。最终在所有引用都被销毁时（强引用计数器为0），手动执行资源`String`的析构，来释放堆内存。



![image-20240523192541075](https://raw.githubusercontent.com/Void1315/cpslwd872s/dev/img/20240523192543.png)

----

### `main`函数开用！

```c++
// main.cpp
#include <iostream>
#include "String.h"
#include "StringRc.h"
int main() {
    using namespace std; // 养成良好习惯 不要扩大你所使用的命名空间范围
    StringRc strRc(std::move(String("Hello World!"))); // 创建一个String资源，并使用此资源初始化引用计数智能指针
    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl; // 看一眼计数

    StringRc strRc2 = StringRc::clone(strRc); // 签出一个
    // 看一下他们两个的强引用计数器
    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl;
    cout << "strRc2.getStrongCountNum: " << strRc2.getStrongCountNum() << endl;

    return 0;
}
```

![image-20240523193918978](https://raw.githubusercontent.com/Void1315/cpslwd872s/dev/img/20240523193919.png)

内存就不看了吧，相信你已经人机合一，代码眼上走，内存心中留。

---

## 冒充写时拷贝

这章已经难以实现了，为什么？

理想情况下我们应该这么使用`LazyCopy`对象:

```c++
int main(){
  StringRc strRc1 = StringRc(LazyCopy(String("Hello World!")));
  // LazyCopy 需要智能解引用
  strRc1.get_mut().concat('A');
  // strRc1.get_mut() 得到的是LazyCopy对象
  // LazyCopy需要实现智能解引用 重载*运算符，所以对LazyCopy对象 .运算 得到的应该是String对象
  return 0;
}
```



- 如果我们托管一个`LazyCopy`类用来包裹`String`，那么我们的`StringRc`必须接受一个泛型`T where LatyCopy||String`，泛型`T`必须接收`LazyCopy`或者`String`两个不同对象，不使用泛型语法的情况下，我们很难实现。使用c语法强转？算了吧我不想写屎山。
- 不允许使用重载，不允许使用泛型。`man what can i say!`

综上所述，我们如果想将写时拷贝与`String`解耦实现。那么我们必须在可以重载、泛型的情况下。所以，我们现在只能冒充一下写时拷贝。



```c++
// StringRc.cpp
// 为我们的StringRc类新增一个get_mut_rc方法
StringRc StringRc::get_mut_rc() {
    *strong_count = *strong_count - 1; // 原来的引用计数减一
    strRef = new String(*strRef); // 深拷贝出来
    strong_count = new uintmax_t(1); // 创建新的引用计数
    return *this;
}
```

- `get_mut_rc`方法将此`StringRc`对象从此计数中移除，并创建新的计数。同时深拷贝`String`资源对象，实现资源完全分离。

```c++
// main.cpp
#include <iostream>
#include "String.h"
#include "StringRc.h"
int main() {
    using namespace std;
    StringRc strRc(std::move(String("Hello World!")));
    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl;
    cout << endl;

    StringRc strRc2 = StringRc::clone(strRc);

    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl;
    cout << "strRc2.getStrongCountNum: " << strRc2.getStrongCountNum() << endl;
    cout << endl;


    strRc2 = strRc2.get_mut_rc(); // 深拷贝出来一个引用计数器 变相的实现了lazyCopy吧 手动的

    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl;
    cout << "strRc2.getStrongCountNum: " << strRc2.getStrongCountNum() << endl;
    cout << endl;


    StringRc strRc3 = StringRc::clone(strRc2);

    cout << "strRc.getStrongCountNum: " << strRc.getStrongCountNum() << endl;
    cout << "strRc2.getStrongCountNum: " << strRc2.getStrongCountNum() << endl;
    cout << "strRc3.getStrongCountNum: " << strRc3.getStrongCountNum() << endl;
    cout << endl;


    return 0;
}

```

![image-20240523201454830](https://raw.githubusercontent.com/Void1315/cpslwd872s/dev/img/20240523201455.png)

上面的代码也好理解。

- 我们先通过`strRc`创建了一个引用计数。并`clone`出来一个`strRc2`此时，两者的引用计数都为2，且指向同一资源。
- 执行`strRc2.get_mut_rc()`方法，将`strRc2`从原有的引用计数中移除，并创建新的引用计数和资源。此时`strRc`和`strRc2`的引用计数都为1（但不是同一个引用计数器）。
- 通过`strRc2`签出`strRc3`，此时`strRc2`和`strRc3`引用计数都为2，并且指向同一个`String`资源。而`strRc`引用计数不变，仍为`1`。
- 最后，所有的引用计数都被栈回收，`strRc`的`String`资源和`strRc2、strRc3`的`String`资源都被回收，执行两次`String`的析构方法。

写前豪言壮语，写的时候才意识到没法使用泛型和运算符重载，只能悻悻而归。