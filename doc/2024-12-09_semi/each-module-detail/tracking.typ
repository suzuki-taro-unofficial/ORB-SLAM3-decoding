== Tracking

今回TrackingはFRPにしないが、FRPと連携して動く必要があるため、
後述するInputBridgeとOutputBridgeを用いて各モジュールに対する処理を置換した。

置換した処理としては以下の通り

- TODO

=== InputBridge

ネットワークへ渡すStreamSinkを持ち、
sendを行う関数群を用いてネットワークへの入力を行う。

```cpp
struct InputBridge {
  InputBridge();
  void doSomething(int value) { ssink_doSomething.send(value); }
  sodium::stream<int> s_doSomething;
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
```


