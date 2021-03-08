+++
Tags = [
  "algorithm",
  "python",
]
Categories = [
  "算法",
]
draft = true

Description = ""
date = "2017-03-30T10:50:00+08:00"
title = "梯度算法学习"
+++

### preload

有一个画图工具能更好更直观的发现算法的特征和规律


安装[matplotlib](http://matplotlib.org/users/installing.html)图形库


在使用图形库前必须先了解[numpy](https://docs.scipy.org/doc/numpy-dev/user/quickstart.html)

<!--more-->


### 源码

```python
import numpy as np
from mpl_toolkits.mplot3d import axes3d
import matplotlib.pyplot as plt


fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
# ax.set_zlim3d(0, 2500)


def get_gradient_descent_data(num):
    a = 1
    b = 3000
    x = y = np.linspace(-2, 3, num)
    X, Y = np.meshgrid(x, y)
    Z = (a-X)**2 + (Y-X**2)**2 * b

    return X, Y, Z


# Grab some test data.
X, Y, Z = get_gradient_descent_data(400)

# Plot a basic wireframe.
ax.plot_wireframe(X, Y, Z,rstride=10, cstride=10)
# ax.set_zlim(0, 1500)
plt.show()
```
