# Horst

## description
```
They say 3 rounds is provably secure, right?

https://play.plaidctf.com/files/horst_1413814aa07a564df58dd90f700b2afd.tgz

Crypto (200 pts)
```


This [task](horst_1413814aa07a564df58dd90f700b2afd.tgz) is about a crypto-system related to Permutations of range(64).

We are given the [source code](horst.py) of the cryptosystem and [two known pairs](data.txt) of `(plaintext, ciphertext)` encrypted with the same key, and are required to find this key `k`.


## the group and operation
Looking at the source and doing some trial and error, we will see:
* `P * P.inv() == Permutation(range(64))`  [let's call it: I]
* `P * I == P`
* `I * P == P`
* `P * Q != Q * P`

So, we can view this as a [Group](https://en.wikipedia.org/wiki/Group_(mathematics)#Definition) with an operation `*`, and it satisfaces these properties:
* associativity? Yes. `P*(Q*S)` == `(P*Q)*S`
* identity element? Yes, I = range(64)
* inverse element? Yes, and we have the function to calculate it in the source.

About the operation `*`:
* conmutative? No. `P*Q != Q*P`. We can't reorder the operation factors.. :(

    And, therefore, we can't simplify `P*k.inv()*Q*k` as `P*Q`



## encryption function: analyzing and simplifying it
Looking at the encryption function, we can see that it is very similar to a Feistel Network (hence the name of the task, [Horst](https://en.wikipedia.org/wiki/Horst_Feistel)).

```python
    x, y = p00, p01
    for i in range(3):
        x, y = (y, x * k.inv() * y * k)
    c00, c01 = x,y
```

It has 3 rounds... Let's rewrite the output data using input data:

* ROUND 0 - `x0, y0 = p01, p00*k.inv()*p01*k`
* ROUND 1 - `x1, y1 = p00*k.inv()*p01*k, p01*k.inv()*p00*k.inv()*p01*k*k`
* ROUND 2 - `c00, c01 = p01*k.inv()*p00*k.inv()*p01*k*k, p00*k.inv()*p01*k*k.inv()*p01*k.inv()*p00*k.inv()*p01*k*k*k`

So:
* `c00 = p01*k.inv()*p00*k.inv()*p01*k*k`
* `c01 = p00*k.inv()*p01*k*k.inv()*p01*k.inv()*p00*k.inv()*p01*k*k*k`

Replacing at c01 `k*k.inv() == I` and replacing also c00 equality, and doing some allowed operations in this group:  
* `c01 = p00*k.inv()*p01*c00*k`

, after sorting it:  
* `k*p00.inv()*c01 == p01*c00*k`

Defining:
* `A = p00.inv()*c01`
* `B = p01*c00`

, lastly we have:
* `k*A = B*k`

, with A, B known permutations.

In fact we have two pairs `(A0, B0)` and `(A1, B1)` from pt/ct given data, both with same k. So:
* `k*A0 == B0*k`
* `k*A1 == B1*k`

## attack step 1: using fixed points to get one key value

Thinking at what `k*A == B*k` is, we can see that it is equivalent to:
```python
for i in xrange(N):
    assert A1[ k[i] ] == k[ B1[i] ]
    assert A0[ k[i] ] == k[ B0[i] ]
    assert A0[i] == k[ B0[k.inv()[i]] ]
    assert A1[i] == k[ B1[k.inv()[i]] ]
    assert A0[i] == (B0*k)[ k.inv()[i] ]
    assert A1[i] == (B1*k)[ k.inv()[i] ]
```

Looking at the first equation `A[k[i]] == k[B[i]]`, we found that if there is a _fixed point_ in B (point in which `B[i] == i`),
then there will be a fixed point in A, and this will give a known value [or a reduced list of possible values] in a position
[or reduced list of possible positions] of k.

Luckily, in this task, there is only one fixed point at B1 (and its corresponding fixed point in A1).
From this two fixed points, we already deduced a value of the key: k[29] = 58.

```python
## find fixed_points
fixed = [[], [], [], []]
for i in xrange(N):
    for pos,P in enumerate([A0, B0, A1, B1]):
        if P[i] == i:
            fixed[pos].append(i)

print("fixed points:", fixed)

#[[], [], [58], [29]]
# only one fixed point => we have a known value in k:
k_found[29] = 58
```

## attack step 2: remaining key values

Applying the first equation `A[k[i]] == k[B[i]]` to the other pt/ct data, we can found another key value,
and doing it recursively, we can populate all the key data from one known value.

For example, using the kwown value `k[29] = 58` and `(A0, B0)`:
```python

k[ B0.inv()[29] ] == A0.inv()[ k[29] ] == A0.inv()[58] == 40

, and so, we have deduced a new k value:

k[17] = 40

```


## final script
    
```python
from horst import *

# task: find k
k_found = [None]*N
# given plaintext, ciphertext pair
[((p01,p02),(c01,c02)), ((p11,p12),(c11,c12))] = eval(open("data.txt").read())

# auxiliar permutations
A0, B0 = p01.inv()*c02, p02*c01
A1, B1 = p11.inv()*c12, p12*c11

# we have a known value in k:
k_found[29] = 58

# from one key value, using the two pairs of pt/ct, populate key values
new_solved_counter = 1
old_solved_counter = 0
while (new_solved_counter - old_solved_counter):
    for j in xrange(N):
        if k_found[j] is not None:
            for A,B in [(A0, B0), (A1, B1)]:
                i = B.inv()[j]
                if k_found[i] is None:
                    k_found[i] = A.inv()[k_found[j]]
    old_solved_counter = new_solved_counter
    new_solved_counter = len([x for x in k_found if x is not None])


print("solved counter: %d" % new_solved_counter)
if new_solved_counter == N:
    print("found key: ", k_found)
    print "The flag is: PCTF{%s}" % sha1(str(Permutation(k_found))).hexdigest()
    k = Permutation(k_found)
    assert k*A0 == B0*k
    assert k*A1 == B1*k
else:
    print("found values: ", k_found)

'''
$ python2 horst_solve.py    
solved counter: 64
('found key: ', [59, 2, 50, 29, 55, 15, 43, 30, 27, 6, 57, 22, 7, 26, 3, 35, 24, 40, 53, 46, 49, 10, 16, 12, 41, 47, 60, 11, 51, 58, 4, 1, 56, 28, 52, 19, 39, 9, 33, 36, 37, 63, 14, 0, 61, 13, 25, 17, 8, 54, 44, 34, 18, 23, 48, 62, 32, 42, 20, 45, 31, 5, 38, 21])
The flag is: PCTF{69f4153d282560cdaab05e14c9f1b7e0a5cc74d1}
'''
```
