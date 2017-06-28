import sys

from RegisterAddressVisitor import RegisterAddressVisitor
from BlockSizeVisitor import BlockSizeVisitor

RegisterAddressVisitor.parse_file(sys.argv[1])
v= BlockSizeVisitor.parse_file(sys.argv[1])
print(v.dict)
