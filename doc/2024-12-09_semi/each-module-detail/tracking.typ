== Tracking

今回TrackingはFRPにしないが、FRPと連携して動く必要があるため、
後述するInputBridgeとOutputBridgeを用いて各モジュールに対する処理を置換した。

=== InputBridge

ネットワークへ渡すStreamSinkを持ち、
sendを行う関数群を用いてネットワークへの入力を行う。

```cpp
struct InputBridge {
  InputBridge();
  void doSomething(int value) { ssink_doSomething.send(value); }
  sodium::stream_sink<int> s_doSomething;
};

struct Outer {
  Outer(InputBridge ib) : ib(ib) {}
  void Run(void) {
    ...
    ib.doSomething();
    ...
  }
  InputBridge ib;
};

struct FRP {
  FRP(InputBridge ib) {
    ...
    auto s = ib.s_doSomething.map([](int x) { ... });
    ...
  }
};

struct System {
  System() {
    ...
    InputBridge ib;
    FRP frp{ib};
    ...
    Outer outer{ib};
    outer.Run();
    ...
  }
};
```

=== OutputBridge

ネットワークの出力ストリーム・セルをlistenし、
内部で変数を書き換えそれをゲッターを用いて取得する。

```cpp
struct OutputBridge {
  OutputBridge(sodium::stream<int> s, sodium::cell<int> c) {
    s.listen([](int x) { sv = x; });
    c.listen([](int x) { cv = x; });
  }
  int get_sv(void) { return sv; }
  int get_cv(void) { return cv; }
private:
  int sv, cv;
};

struct Outer {
  Outer(OutputBridge ob) : ob(ob) {}
  void Run(void) {
    ...
    auto sv = ob.get_sv();
    auto cv = ob.get_cv();
    ...
  }
  OutputBridge ob;
};

struct FRP {
  FRP() {}
  sodium::stream<int> s;
  sodium::cell<int> c;
};

struct System {
  System() {
    ...
    FRP frp{};
    OutputBridge ob{frp.s, frp.c};
    ...
    Outer outer{ob};
    outer.Run();
    ...
  }
};
```

