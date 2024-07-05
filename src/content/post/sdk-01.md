---
title: "Windows SDK 01笔记"
description: "简单了解Windows SDK的标准入口程序，并学习Windows.h头文件中定义的各种宏定义。观察入口程序入参内存，以及完成实验。"
publishDate: "2024 07 05"
tags: ["C++", "Windows SDK"]
---

## Windows桌面程序

**通过空项目创建**

![image-20240705162749414](https://qiniu.asahichyan33.top/images/image-20240705162749414.png)

- `WINAPI`，一个调用约定宏

  ![image-20240705162540949](https://qiniu.asahichyan33.top/images/image-20240705162540949.png)

- `TEXT`是，`Windows SDK`中的兼容字符集宏，等价于`_T(xxx)`宏。
- `WinMain`是窗口程序的入口函数，等价于C标准中的`int main()`函数。

**`WinMain`的函数签名**

```cpp
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow);
```

- `__stdcall`调用约定，被调用者清理堆栈、参数入栈顺序从右至左。
- `WinMain`函数名，`Win32`窗口程序调用规范定义。
- `HINSTANCE`，`Handel Instance`句柄实例，窗口句柄对象。
- `hInstance`是 实例的句柄*或模块的句柄。 当可执行文件加载到内存中时，操作系统使用此值来标识可执行文件或 EXE。 某些 Windows 函数需要实例句柄，例如加载图标或位图。
  - 在程序中，关闭**随机基址**后，`hInstance`的值，统一为`0x00400000`，表示程序内存的首地址。![image-20240705163746082](https://qiniu.asahichyan33.top/images/image-20240705163746082.png)
- `hPrevInstance`没有任何意义。 它在 16 位 Windows 中使用，但现在始终为零。
- `pCmdLine`以 Unicode 字符串的形式包含命令行参数。
- `nCmdShow`是一个标志，指示主应用程序窗口是最小化、最大化还是正常显示。



**关于`pCmdLine`参数**

​	通过配置调试环境中的参数，可以观察到参数字符串是如何存在的。

![image-20240705164218529](https://qiniu.asahichyan33.top/images/image-20240705164218529.png)



![image-20240705164246464](https://qiniu.asahichyan33.top/images/image-20240705164246464.png)

**关于`nCmdShow`参数**

​	根据`Stack OverFlow`中的回答:

> The value of the `nCmdShow` parameter will be one of the constants specified in [`ShowWindow`](http://msdn.microsoft.com/en-us/library/windows/desktop/ms633548(v=vs.85).aspx)'s API reference. It can be set by another process or system launching your application via [`CreateProcess`](http://msdn.microsoft.com/en-us/library/windows/desktop/ms682425(v=vs.85).aspx). The [`STARTUPINFO`](http://msdn.microsoft.com/en-us/library/windows/desktop/ms686331(v=vs.85).aspx) struct that can optionally be passed to `CreateProcess` contains a `wShowWindow` member variable that will get passed to `WinMain` through the `nCmdShow` parameter.</br>`nCmdShow` 参数的值将是 `ShowWindow` 的 API 参考中指定的常量之一。它可以由通过 `CreateProcess` 启动您的应用程序的另一个进程或系统来设置。可以选择传递给 `CreateProcess` 的 `STARTUPINFO` 结构包含一个 `wShowWindow` 成员变量，该变量将通过 `nCmdShow` 参数。

- 此参数通过`CreateProcess`创建时，进行传参。

## 作业

**不使用头文件，创建弹窗**

```cpp
#pragma comment(lib, "user32.lib")

#define WINAPI __stdcall
#define HWND void*
#define LPCWSTR const wchar_t*
#define UINT unsigned int
#define MB_OK 0x00000000L
#define NULL 0

// 导入MessageBox函数的地址
extern "C" __declspec(dllimport) int __stdcall MessageBoxW(void* hWnd, const wchar_t* lpText, const wchar_t* lpCaption, unsigned int uType);

//int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
//{
//    MessageBox(NULL, TEXT("Hello World!"), TEXT("Hello World!"), MB_OK);
//    return 0;
//}

int main() {
    MessageBoxW(NULL, L"Hello World!", L"Hello World!", MB_OK);
    return 0;
}
```

​	主要思路是通过，让程序静态加载`user32.dll`动态运行库，将`MessageBoxW`函数链接到程序中，进行手工调用。类似的方法也可以动态加载`DLL`文件，获取函数地址，通过函数指针调用的方式。此处不赘叙。
