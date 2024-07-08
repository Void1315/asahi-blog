---
title: '（施工中）Rust实现自己的Future与runtime'
description: '使用标准提供的Context切换和Async/Await关键字，实现一个自己的调度器。调度器使用最基本的实现方案。'
publishDate: '2024 06 13'
tags: ['Rust', 'Async', 'Future']
---

## 什么是异步编程？

&ensp;&ensp;&ensp;&ensp;​异步编程允许我们在执行一块带有阻塞的代码时，无需等待阻塞完毕，就可以先行跳转其他代码块进行代码的执行。当阻塞恢复时，通过执行器的调度方案，在某一时刻（并不及时）回到之前被阻塞的代码块，进行继续执行。

![image-20240613180436685](https://qiniu.asahichyan33.top/images/image-20240613180436685.png)
&ensp;&ensp;&ensp;&ensp;通常来说异步编程是**并发编程**的范畴，而不是并行编程的范畴。异步编程的实现一般依赖于**协程**，所以异步编程往往并不依赖于内核和硬件的支持，更加依赖于协程的实现。反直觉的事情是，协程起源于汇编语言。

&ensp;&ensp;&ensp;&ensp;综上所述，异步编程可以依赖于第三方库，或者我们自己实现一个执行器，并在其中进行自己的调度，这在某些无法多线程的硬件环境中极为有用。

&ensp;&ensp;&ensp;&ensp;异步编程在使用中极为常见，所以大部分语言都会使用关键字来定义一个异步函数。通常这组关键字为`Async/Await`。

> 在Rust中，语言本身只为我们提供了Async/Await这组关键字。并不额外的为我们提供异步运行时，这导致我们想要使用异步时，需要额外的引入运行时库。

## 无栈协程

​&ensp;&ensp;&ensp;&ensp;协程是一种更轻量级的线程，协程的调度者（`executor` ）是线程中自行实现的一套调度机制运行者。对于系统内核的时间片调度，协程的实现往往采用更简单的方式，例如Golang中的有栈协程`goroutine`，和在前端广为人知的`Promise`。

​&ensp;&ensp;&ensp;&ensp;Javascript的协程是无栈协程，Golang的协程是有栈协程。

---

​&ensp;&ensp;&ensp;&ensp;有栈协程可以在任意函数中挂起，阻塞恢复时立即接着执行；有栈协程通过遇到阻塞时，将整条函数栈保存到一段空间中（也可能固定当前这段栈空间），并且保存寄存器值，当阻塞恢复时，从空间中恢复栈状态与寄存器状态。优点是任意函数中都可以开辟协程运行。而缺点正是需要资源保存栈、恢复栈。

​&ensp;&ensp;&ensp;&ensp;而无栈协程不能在任意函数中挂起，常见的实现，你只能在`async`函数中调用无阻塞的`await`过程。因为我们预设了在`async`的环境中执行异步，所以我们只需要保存`async`函数此时的上下文即可。上下文保存在全局线程区，当阻塞恢复的时候，无栈协程不像有栈协程一样恢复所有状态，而是通过状态机，直接执行接下来的程序语句。

​&ensp;&ensp;&ensp;&ensp;我们本文将注重无栈协程的实现，会从最基本的阻塞场景进行探究，我会尽力将一个协程执行器的构建过程讲清楚。

## 最简单的异步模型

​&ensp;&ensp;&ensp;&ensp;协程本身运行在单线程中，我们在实现或者模拟协程时，不能使用会导致线程阻塞的函数，例如：IO操作、Sleep、Socket、网络请求等等。这会导致线程本身阻塞，执行权无法交还给执行器。

​&ensp;&ensp;&ensp;&ensp;我们实现的简单的异步模型拥有一个执行器，执行器不断的循环推进阻塞的方法进行前进，当执行器中所有阻塞的方法全部执行完后，执行器将会结束。

```rust
pub fn collaborative_simulation01() {
    let mut task01 = task01();
    let mut task02 = task02();
    let mut task03 = task03();
    loop {
        let result01 = task01();
        let result02 = task02();
        let result03 = task03();
        if result01 && result02 && result03 {
            break;
        }
    }

    fn task01() -> impl FnMut() -> bool {
        let mut sum = 0;
        return move || match sum {
            10 => true,
            _ => {
                println!("task01: {}", sum);
                sum += 1;
                false
            }
        };
    }
    fn task02() -> impl FnMut() -> bool {
        let mut sum = 0;
        return move || match sum {
            20 => true,
            _ => {
                println!("task02: {}", sum);
                sum += 1;
                false
            }
        };
    }
    fn task03() -> impl FnMut() -> bool {
        let mut sum = 0;
        return move || match sum {
            30 => true,
            _ => {
                println!("task03: {}", sum);
                sum += 1;
                false
            }
        };
    }
}

```
