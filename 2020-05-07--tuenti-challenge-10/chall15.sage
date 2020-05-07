#!/usr/bin/env sage
'''
calculates crc32 of a large sparse file using sagemath's magic
for python2 based sage

coded after tuenti programming contest
https://contest.tuenti.net/Challenges?id=15
'''

k1.<y> = GF(2^33, 'y')
modulo = k1.fetch_int(0x104C11DB7)
k2.<x> = GF(2^32, 'x', modulo)

def crc32(length, bytes):
    '''
    length: total length. number of total bytes
    bytes: bytes different from \x00: [(pos1, byte1), (pos2, byte2), ...]
    '''
    # construct pol: reverse bits
    pol = 0
    for pos, byte in bytes:
        #reverse bits in each byte
        byte_rev = int( bin(byte)[2:].zfill(8)[::-1], 2)
        # reverse bytes order
        pos_n = length-pos-1
        pol += k2.fetch_int(byte_rev)*x^(8*pos_n)

    #prologue: add 32 zeroes to rigth and xor with 0xffffffff to left
    pol *= x^32
    pol +=  k2.fetch_int(0xffffffff)*x^(8*length)

    crc = pol.integer_representation()

    #epilogue: reverse 32 bits and xor
    crc = int(bin(crc)[2:].zfill(32)[::-1], 2)
    crc ^^= 0xffffffff

    return crc.hex().zfill(8)
    

if __name__ == '__main__':
    import sys, os

    while True:
        try:
            f, n = sys.stdin.readline().strip().split(' ')
        except:
            break
        n = int(n)
        sz = os.path.getsize('animals/%s' % f)
        bytes = []
        print('%s %d: %s' % (f, 0, crc32(sz, bytes)))
        for i in xrange(n):
            pos, byte = map(int, sys.stdin.readline().strip().split(' '))
            bytes = [(l + 1 if pos <= l else l, c) for l, c in bytes]
            sz += 1
            bytes.append( (pos, byte) )
            print('%s %d: %s' % (f, i+1, crc32(sz, bytes)))
            
