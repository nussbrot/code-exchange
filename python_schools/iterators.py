# the iterator protocol needs functions __iter__() and __next__()
class iterator_protocol(object):

    def __init__(self, *args):
        self._data = args
        self._idx = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self._idx < len(self._data):
            tmp = self._data[self._idx]
            self._idx += 1
            return tmp
        else:
            raise StopIteration

iterator = iterator_protocol(1, "Suppe", None, 3.12)

for item in iterator:
    print(item)


# the same iterator implemented as generator function
def generator(*args):
    for item in args:
        yield item

for item in generator(1, "Suppe", None, 3.12):
    print(item)


# Generators can also be created by putting list comprehensions in round brackets
print("\nSquares")
squares = (x*x for x in range(10))
for item in squares:
    print(item)


# iterators also work recursively.
# let's take a look at Guido's binary tree inorder traversal:
def inorder(t):
    if t:
        for x in inorder(t.left):
            yield x
        yield t.dat
        for x in inorder(t.right):
            yield x

class tree(object):
    def __init__(self, dat, left=None, right=None):
        self.dat = dat
        self.left = left
        self.right = right

# A small test tree:
#    10
#    /\
#   7  13
#  /\
# 5 9
my_tree = tree(10, tree(7, tree(5), tree(9)), tree(13))

print("\nBinary tree traversal")
for node in inorder(my_tree):
    print(node)
