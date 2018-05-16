+++
title = "Thread Safe"
+++

Thread safe if you comply with the following agreement

1. make sure **ToyBrick** object is read only, if you want to change it, create a new one

2. do not use **append** to change ToyBrick's slice data,use **make** and **copy** to clone new slice