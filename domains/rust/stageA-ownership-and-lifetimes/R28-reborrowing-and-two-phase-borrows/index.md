# R28: 重借用（Reborrowing）与两阶段借用：`&mut *r` 解引用与方法调用隐式升级

> **适合人群**：被「不能多次可变借用」报错困扰、想搞懂多层借用本质的开发者 · **预计耗时**：25 分钟

---

## 💡 1. 生活物理比喻：临时转借阅览证与原证冻结

为什么 `&mut T` 不能 Copy，但在调用 `fn update(r: &mut T)` 时原变量之后还能继续用？

```
+-------------------------------------------------------------------------+
| 🎫 场景: 独占阅览证 (`&mut T`) 临时开出「子副证」                         |
| · 你持有一张唯一的独占图书阅览证（`&mut Book`）；                          |
| · 助教需要临时借用 1 分钟查验（函数调用）；                                |
| · Rust 并不是把你的主证永久送给他（Move），而是隐式为你开出一张「临时副证」；|
| · 在副证生效的 1 分钟内，你的主证处于「严格冻结」状态（不可读写）；        |
| · 助教归还副证后，你的主证「瞬间解冻」，恢复完全独占权！                   |
+-------------------------------------------------------------------------+
```

---

## 🛠️ 2. 完整可运行代码：体会重借用与解冻过程

```rust
fn assistant_modify(doc: &mut String) {
    doc.push_str(" · 助教已审阅");
}

fn main() {
    let mut document = String::from("《Rust 架构指南》");

    let main_ref = &mut document; // 持有主证

    // 1. 开出临时副证传给助教 (重借用 &mut *main_ref)
    assistant_modify(main_ref);

    // 2. 助教归还副证，主证解冻，继续使用
    main_ref.push_str(" · 主编终审通过");
    println!("最终文稿: {}", main_ref);
}
```

### 预期输出：
```text
最终文稿: 《Rust 架构指南》 · 助教已审阅 · 主编终审通过
```

---

## 💥 3. 故意写错：在副证生效期间试图使用主证 (E0499 报错医生)

如果我们试图在副证生效期间强行去使用主证：

```rust
fn main() {
    let mut score = 100;
    let main_ref = &mut score;

    let sub_ref = &mut *main_ref; // 开出副证

    *main_ref += 10; // 💥 主证还在冻结期，试图强行修改！
    *sub_ref += 5;
}
```

### 真实报错现场：
```text
error[E0499]: cannot borrow `*main_ref` as mutable more than once at a time
 --> src/main.rs:6:5
  |
4 |     let sub_ref = &mut *main_ref;
  |                   -------------- first mutable borrow occurs here
5 | 
6 |     *main_ref += 10;
  |     ^^^^^^^^^ second mutable borrow occurs here
7 |     *sub_ref += 5;
  |     ------------- first borrow later used here
```

### 👨‍⚕️ 医生人话诊断与解药：
- **人话翻译**：`sub_ref` 正在拿着副证办事呢，此时主证处于严格冻结状态，绝不允许同时修改！
- **修复方案**：等 `sub_ref` 使用完毕离开生命周期后，再使用 `main_ref`。

---

## 🔬 4. 底层内存物理真实现场

Rust 2018 引入的**两阶段借用（Two-Phase Borrows）**允许 `vec.push(vec.len())` 这种代码通过编译：
1. 阶段 1（预留期 Reservation）：`&mut vec` 仅登记指针而不激活独占锁；
2. 阶段 2（只读执行）：评估参数 `vec.len()`；
3. 阶段 3（激活期 Activation）：正式独占写入。

---

## 🎯 5. 动手通关小实验 (Micro-Quest)

请修改下面的代码，调整使用时序使程序成功编译并打印出 `累计总分: 120`：

```rust
fn main() {
    let mut score = 100;
    let main_ref = &mut score;

    {
        let sub_ref = &mut *main_ref;
        *sub_ref += 10;
    } // sub_ref 在此归还副证，主证解冻

    *main_ref += 10; // 主证解冻后修改
    println!("累计总分: {}", main_ref);
}
```
