---
title: "Windows SDK 02笔记"
description: "学习创建一个Win32窗口程序的SOP。使用C++与Visual Studio 2022编写一个最小的窗口程序，并添加基本的消息处理函数。"
publishDate: "2024 07 05"
tags: ["C++", "Windows SDK"]
---

## 创建窗口程序

​	`Win32`的窗口程序的创建，总体来说也遵循最简单的流程：`创建窗口`->`显示窗口`。与`Java`不同的是，需要对窗口进行显示的事件处理。官方称之为*绑定窗口过程*

> 进程必须先注册窗口类，然后才能创建该类的窗口。 注册窗口类会将窗口过程、类样式和其他类属性与类名相关联。 当进程在 [**CreateWindow 或 CreateWindowEx**](https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-createwindowa) 函数中指定类名时，系统将创建一个窗口，其中包含与该类名关联的窗口过程、样式和其他属性。

![image-20240707123701666](https://qiniu.asahichyan33.top/images/image-20240707123701666.png)

**1. 创建窗口类**

​	使用官方提供的`RegisterClass`方法进行窗口类的创建。

```c++
TOM RegisterClassW([in] const WNDCLASSA *lpWndClass); // RegisterClass的函数签名，RegisterClass是一个宏根据字符集不同分为：RegisterClassA与RegisterClassW
```

​	`RegisterClassW`需要一个`WNDCLASSA`窗口类对象。

```c++
typedef struct tagWNDCLASSA {
  UINT      style;
  WNDPROC   lpfnWndProc;
  int       cbClsExtra;
  int       cbWndExtra;
  HINSTANCE hInstance;
  HICON     hIcon;
  HCURSOR   hCursor;
  HBRUSH    hbrBackground;
  LPCSTR    lpszMenuName;
  LPCSTR    lpszClassName;
} WNDCLASSA, *PWNDCLASSA, *NPWNDCLASSA, *LPWNDCLASSA;
```

- `style`窗口样式，按位设置的预定义值，可以控制如：禁用右上角最大化/最小化按钮、响应式重绘等。https://learn.microsoft.com/en-us/windows/win32/winmsg/window-class-styles#constants
- `lpfnWndProc`窗口过程函数指针。
- `cbClsExtra`在窗口类结构之后分配的额外字节数。系统将字节初始化为零。
- `cbWndExtra`在窗口实例之后分配的额外字节数。系统将字节初始化为零。
- `hInstance`包含该类的窗口过程的实例的句柄。
- `hIcon`类图标的句柄。该成员必须是图标资源的句柄。如果该成员为NULL，则系统提供默认图标。
- `hCursor`类光标的句柄。该成员必须是游标资源的句柄。如果该成员为 NULL，则每当鼠标移入应用程序窗口时，应用程序都必须显式设置光标形状。
- `hbrBackground`类背景画笔的句柄。该成员可以是用于绘制背景的物理画笔的句柄，也可以是颜色值。颜色值必须是以下标准系统颜色之一（必须将值 1 添加到所选颜色）。
- `lpszMenuName`类菜单的资源名称，该名称出现在资源文件中。如果使用整数来标识菜单，请使用 `MAKEINTRESOURCE` 宏。如果该成员为NULL，则属于该类的窗口没有默认菜单。
- `lpszClassName`指向空终止字符串的指针或者是一个原子。如果此参数是原子，则它必须是先前调用 `RegisterClass` 或 `RegisterClassEx` 函数创建的类原子。原子必须位于 `lpszClassName` 的低位字中；高位字必须为零。

---

我们创建一个最小的类模板

```c++
  WNDCLASS wc = { 0 };
  wc.lpfnWndProc = DefWindowProc; // 先给定默认的窗口过程处理
  wc.hInstance = hInstance;
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
  wc.lpszClassName = L"myWindowClass"; // 唯一标识 窗口类名

```

**2. 创建窗口对象**

使用官方提供的`CreateWindow`函数进行创建窗口。

```c++
HWND hwnd = CreateWindow(
    L"myWindowClass", // 刚才设置的唯一类名标识
    L"Hello, World!", // 窗口标题
    WS_OVERLAPPEDWINDOW, // 
    CW_USEDEFAULT, CW_USEDEFAULT,
    CW_USEDEFAULT, CW_USEDEFAULT,
    NULL,
    NULL,
    hInstance,
    NULL
);
```



**3/4. 显示窗口&更新窗口**

```c++
    // 3. 显示窗口
    ShowWindow(hwnd, nCmdShow);

    // 4. 更新窗口
    UpdateWindow(hwnd);
```

**5. 设置消息循环**

```c++
    while (true) {
        MSG msg;
        bool ret = GetMessageW(&msg, NULL, 0, 0);
        if (!ret) {
            return 0;
        }
        DispatchMessageW(&msg); // 派发消息
    }
```

**6. 定义过程函数，并绑定**

```c++
// 6. 实现窗口消息处理函数
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CLOSE:
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

// 修改创建窗口类的地方
wc.lpfnWndProc = WndProc; // 设置为自己的过程函数
```



**完整代码**

```c++
#include <Windows.h>
void ShowErr() {
    LPVOID lpMsgBuf;
    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        GetLastError(),
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
        (LPTSTR)&lpMsgBuf,
        0,
        NULL
    );
    MessageBox(NULL, (LPCTSTR)lpMsgBuf, L"Error", MB_OK | MB_ICONINFORMATION);
    LocalFree(lpMsgBuf);
}

// 6. 实现窗口消息处理函数
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CLOSE:
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}


// winmain函数

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // 1. 注册窗口类
    WNDCLASS wc = { 0 };
    //wc.lpfnWndProc = WndProc; // 绑定窗口消息处理函数 （窗口过程）
    wc.lpfnWndProc = DefWindowProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"myWindowClass"; // 唯一标识 窗口类名

    // 2. 创建窗口

    if (!RegisterClass(&wc)) ShowErr();

    HWND hwnd = CreateWindow(
        L"myWindowClass",
        L"Hello, World!",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        CW_USEDEFAULT, CW_USEDEFAULT,
        NULL,
        NULL,
        hInstance,
        NULL
    );

    // 3. 显示窗口
    ShowWindow(hwnd, nCmdShow);

    // 4. 更新窗口
    UpdateWindow(hwnd);

    // 5. 消息循环
    while (true) {
        MSG msg;
        bool ret = GetMessageW(&msg, NULL, 0, 0);
        if (!ret) {
            return 0;
        }
        DispatchMessageW(&msg);
    }
    return 0;
}
```

### 作业1

> 左键按下创建新窗口，点击X，关闭窗口，当只剩最后一个窗口的时候，退出进程。

​	核心思路是，通过一个`set`容器来管理所有创建的窗口，当处理关闭窗口事件时，通过判断容器中是否存在窗口，来决定是否发送关闭进程的事件消息。

```c++
#include "HomeWork01.h"

static std::set<HWND> g_hwnds;

LRESULT CALLBACK HomeWork01::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CLOSE:
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY:
        {
            g_hwnds.erase(hwnd);
            if (g_hwnds.empty()) {
                PostQuitMessage(0);
            }
        }
        break;

        case WM_LBUTTONDOWN:
        {
            auto newHwnd = CreateWindow(
                HOMEWORK01_CLASS_NAME, HOMEWORK01_CLASS_NAME, WS_OVERLAPPEDWINDOW,
                CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                NULL, NULL, NULL, NULL);
            ShowWindow(newHwnd, SW_SHOWDEFAULT);
            UpdateWindow(newHwnd);
            g_hwnds.insert(newHwnd);
        }
        break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

void HomeWork01::run(HINSTANCE hInstance) {
    WNDCLASS wc = { 0 };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = HOMEWORK01_CLASS_NAME;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    auto ret = RegisterClass(&wc);
    if (!ret) {
        MessageBox(NULL, L"RegisterClass Failed", L"Error", MB_OK);
        return;
    }

    HWND hwnd = CreateWindow(
        wc.lpszClassName, HOMEWORK01_CLASS_NAME, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL, NULL, hInstance, NULL);

    if (!hwnd) {
        MessageBox(NULL, L"CreateWindow Failed", L"Error", MB_OK);
        return;
    }
    g_hwnds.insert(hwnd);

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);
    while (true) {
        MSG msg;
        if (!GetMessage(&msg, NULL, 0, 0)) {
            break;
        }
        DispatchMessage(&msg);
    }
    return;
}
```



### 作业2

> 左键按下创建新窗口，点击X，关闭窗口，当点击第一个窗口的时候，退出进程

​	核心思路是通过保存第一个窗口的句柄。当关闭窗口事件发生时，判断发生事件的窗口是否为第一个窗口句柄，如果是，则发送关闭进程的事件来退出程序。

```c++
#include "HomeWork02.h"

static HWND firsetWindow = 0;

LRESULT CALLBACK HomeWork02::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE:
            break;
        case WM_LBUTTONDOWN:
        {
            auto newHwnd = CreateWindow(
                L"HomeWork02", L"HomeWork02", WS_OVERLAPPEDWINDOW,
                CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                NULL, NULL, NULL, NULL);
            ShowWindow(newHwnd, SW_SHOWDEFAULT);
            UpdateWindow(newHwnd);
        }
        break;
        case WM_CLOSE:
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY:
            if (firsetWindow == hwnd) {
                PostQuitMessage(0);
            }
            break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

void HomeWork02::run(HINSTANCE hInstance) {
    WNDCLASS wc = { 0 };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"HomeWork02";
    RegisterClass(&wc);

    HWND hwnd = CreateWindow(wc.lpszClassName, L"HomeWork02", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT
        , 0, 0, hInstance, 0);
    firsetWindow = hwnd;
    ShowWindow(hwnd, SW_SHOW);

    MSG msg = { 0 };
    while (true) {
        if (GetMessage(&msg, 0, 0, 0)) {
            DispatchMessage(&msg);
        }
        else {
            break;
        }
    }
    return;
}
```

