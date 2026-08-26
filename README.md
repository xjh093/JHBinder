# JHBinder
轻量级 KVO + UIControl 数据绑定库（链式 DSL）

---

# 绑定链（Chain）
一条链由若干"节点（Node）"组成，共享同一个广播组（Group）。

链内任意节点感知到值变化，就向组内其余节点广播新值。

