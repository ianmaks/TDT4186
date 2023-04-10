
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <testcase4>:

int global_array[16777216] = {0};
int global_var = 0;

void testcase4()
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 4 -----\n");
   c:	00001517          	auipc	a0,0x1
  10:	d4450513          	addi	a0,a0,-700 # d50 <malloc+0xee>
  14:	00001097          	auipc	ra,0x1
  18:	b90080e7          	jalr	-1136(ra) # ba4 <printf>
    printf("[prnt] v1 --> ");
  1c:	00001517          	auipc	a0,0x1
  20:	d5450513          	addi	a0,a0,-684 # d70 <malloc+0x10e>
  24:	00001097          	auipc	ra,0x1
  28:	b80080e7          	jalr	-1152(ra) # ba4 <printf>
    print_free_frame_cnt();
  2c:	00001097          	auipc	ra,0x1
  30:	898080e7          	jalr	-1896(ra) # 8c4 <pfreepages>

    if ((pid = fork()) == 0)
  34:	00000097          	auipc	ra,0x0
  38:	7c8080e7          	jalr	1992(ra) # 7fc <fork>
  3c:	c545                	beqz	a0,e4 <testcase4+0xe4>
  3e:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
  40:	00001517          	auipc	a0,0x1
  44:	e3050513          	addi	a0,a0,-464 # e70 <malloc+0x20e>
  48:	00001097          	auipc	ra,0x1
  4c:	b5c080e7          	jalr	-1188(ra) # ba4 <printf>
        print_free_frame_cnt();
  50:	00001097          	auipc	ra,0x1
  54:	874080e7          	jalr	-1932(ra) # 8c4 <pfreepages>

        global_array[0] = 111;
  58:	00002917          	auipc	s2,0x2
  5c:	fb890913          	addi	s2,s2,-72 # 2010 <global_array>
  60:	06f00793          	li	a5,111
  64:	00f92023          	sw	a5,0(s2)
        printf("[prnt] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
  68:	06f00593          	li	a1,111
  6c:	00001517          	auipc	a0,0x1
  70:	e1450513          	addi	a0,a0,-492 # e80 <malloc+0x21e>
  74:	00001097          	auipc	ra,0x1
  78:	b30080e7          	jalr	-1232(ra) # ba4 <printf>

        printf("[prnt] v3 --> ");
  7c:	00001517          	auipc	a0,0x1
  80:	e4c50513          	addi	a0,a0,-436 # ec8 <malloc+0x266>
  84:	00001097          	auipc	ra,0x1
  88:	b20080e7          	jalr	-1248(ra) # ba4 <printf>
        print_free_frame_cnt();
  8c:	00001097          	auipc	ra,0x1
  90:	838080e7          	jalr	-1992(ra) # 8c4 <pfreepages>
        printf("[prnt] pa3 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
  94:	4581                	li	a1,0
  96:	854a                	mv	a0,s2
  98:	00001097          	auipc	ra,0x1
  9c:	824080e7          	jalr	-2012(ra) # 8bc <va2pa>
  a0:	85aa                	mv	a1,a0
  a2:	00001517          	auipc	a0,0x1
  a6:	e3650513          	addi	a0,a0,-458 # ed8 <malloc+0x276>
  aa:	00001097          	auipc	ra,0x1
  ae:	afa080e7          	jalr	-1286(ra) # ba4 <printf>
    }

    if (wait(0) != pid)
  b2:	4501                	li	a0,0
  b4:	00000097          	auipc	ra,0x0
  b8:	758080e7          	jalr	1880(ra) # 80c <wait>
  bc:	10951263          	bne	a0,s1,1c0 <testcase4+0x1c0>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v7 --> ");
  c0:	00001517          	auipc	a0,0x1
  c4:	e4050513          	addi	a0,a0,-448 # f00 <malloc+0x29e>
  c8:	00001097          	auipc	ra,0x1
  cc:	adc080e7          	jalr	-1316(ra) # ba4 <printf>
    print_free_frame_cnt();
  d0:	00000097          	auipc	ra,0x0
  d4:	7f4080e7          	jalr	2036(ra) # 8c4 <pfreepages>
}
  d8:	60e2                	ld	ra,24(sp)
  da:	6442                	ld	s0,16(sp)
  dc:	64a2                	ld	s1,8(sp)
  de:	6902                	ld	s2,0(sp)
  e0:	6105                	addi	sp,sp,32
  e2:	8082                	ret
        sleep(50);
  e4:	03200513          	li	a0,50
  e8:	00000097          	auipc	ra,0x0
  ec:	7ac080e7          	jalr	1964(ra) # 894 <sleep>
        printf("[chld] pa1 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
  f0:	00002497          	auipc	s1,0x2
  f4:	f2048493          	addi	s1,s1,-224 # 2010 <global_array>
  f8:	4581                	li	a1,0
  fa:	8526                	mv	a0,s1
  fc:	00000097          	auipc	ra,0x0
 100:	7c0080e7          	jalr	1984(ra) # 8bc <va2pa>
 104:	85aa                	mv	a1,a0
 106:	00001517          	auipc	a0,0x1
 10a:	c7a50513          	addi	a0,a0,-902 # d80 <malloc+0x11e>
 10e:	00001097          	auipc	ra,0x1
 112:	a96080e7          	jalr	-1386(ra) # ba4 <printf>
        printf("[chld] v4 --> ");
 116:	00001517          	auipc	a0,0x1
 11a:	c8250513          	addi	a0,a0,-894 # d98 <malloc+0x136>
 11e:	00001097          	auipc	ra,0x1
 122:	a86080e7          	jalr	-1402(ra) # ba4 <printf>
        print_free_frame_cnt();
 126:	00000097          	auipc	ra,0x0
 12a:	79e080e7          	jalr	1950(ra) # 8c4 <pfreepages>
        global_array[0] = 222;
 12e:	0de00793          	li	a5,222
 132:	c09c                	sw	a5,0(s1)
        printf("[chld] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
 134:	0de00593          	li	a1,222
 138:	00001517          	auipc	a0,0x1
 13c:	c7050513          	addi	a0,a0,-912 # da8 <malloc+0x146>
 140:	00001097          	auipc	ra,0x1
 144:	a64080e7          	jalr	-1436(ra) # ba4 <printf>
        printf("[chld] pa2 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
 148:	4581                	li	a1,0
 14a:	8526                	mv	a0,s1
 14c:	00000097          	auipc	ra,0x0
 150:	770080e7          	jalr	1904(ra) # 8bc <va2pa>
 154:	85aa                	mv	a1,a0
 156:	00001517          	auipc	a0,0x1
 15a:	c9a50513          	addi	a0,a0,-870 # df0 <malloc+0x18e>
 15e:	00001097          	auipc	ra,0x1
 162:	a46080e7          	jalr	-1466(ra) # ba4 <printf>
        printf("[chld] v5 --> ");
 166:	00001517          	auipc	a0,0x1
 16a:	ca250513          	addi	a0,a0,-862 # e08 <malloc+0x1a6>
 16e:	00001097          	auipc	ra,0x1
 172:	a36080e7          	jalr	-1482(ra) # ba4 <printf>
        print_free_frame_cnt();
 176:	00000097          	auipc	ra,0x0
 17a:	74e080e7          	jalr	1870(ra) # 8c4 <pfreepages>
        global_array[2047] = 333;
 17e:	14d00793          	li	a5,333
 182:	00004717          	auipc	a4,0x4
 186:	e8f72523          	sw	a5,-374(a4) # 400c <global_array+0x1ffc>
        printf("[chld] modified two elements in the 2nd page, global_array[2047]=%d\n", global_array[2047]);
 18a:	14d00593          	li	a1,333
 18e:	00001517          	auipc	a0,0x1
 192:	c8a50513          	addi	a0,a0,-886 # e18 <malloc+0x1b6>
 196:	00001097          	auipc	ra,0x1
 19a:	a0e080e7          	jalr	-1522(ra) # ba4 <printf>
        printf("[chld] v6 --> ");
 19e:	00001517          	auipc	a0,0x1
 1a2:	cc250513          	addi	a0,a0,-830 # e60 <malloc+0x1fe>
 1a6:	00001097          	auipc	ra,0x1
 1aa:	9fe080e7          	jalr	-1538(ra) # ba4 <printf>
        print_free_frame_cnt();
 1ae:	00000097          	auipc	ra,0x0
 1b2:	716080e7          	jalr	1814(ra) # 8c4 <pfreepages>
        exit(0);
 1b6:	4501                	li	a0,0
 1b8:	00000097          	auipc	ra,0x0
 1bc:	64c080e7          	jalr	1612(ra) # 804 <exit>
        printf("wait() error!");
 1c0:	00001517          	auipc	a0,0x1
 1c4:	d3050513          	addi	a0,a0,-720 # ef0 <malloc+0x28e>
 1c8:	00001097          	auipc	ra,0x1
 1cc:	9dc080e7          	jalr	-1572(ra) # ba4 <printf>
        exit(1);
 1d0:	4505                	li	a0,1
 1d2:	00000097          	auipc	ra,0x0
 1d6:	632080e7          	jalr	1586(ra) # 804 <exit>

00000000000001da <testcase3>:

void testcase3()
{
 1da:	1101                	addi	sp,sp,-32
 1dc:	ec06                	sd	ra,24(sp)
 1de:	e822                	sd	s0,16(sp)
 1e0:	e426                	sd	s1,8(sp)
 1e2:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 3 -----\n");
 1e4:	00001517          	auipc	a0,0x1
 1e8:	d2c50513          	addi	a0,a0,-724 # f10 <malloc+0x2ae>
 1ec:	00001097          	auipc	ra,0x1
 1f0:	9b8080e7          	jalr	-1608(ra) # ba4 <printf>
    printf("[prnt] v1 --> ");
 1f4:	00001517          	auipc	a0,0x1
 1f8:	b7c50513          	addi	a0,a0,-1156 # d70 <malloc+0x10e>
 1fc:	00001097          	auipc	ra,0x1
 200:	9a8080e7          	jalr	-1624(ra) # ba4 <printf>
    print_free_frame_cnt();
 204:	00000097          	auipc	ra,0x0
 208:	6c0080e7          	jalr	1728(ra) # 8c4 <pfreepages>

    if ((pid = fork()) == 0)
 20c:	00000097          	auipc	ra,0x0
 210:	5f0080e7          	jalr	1520(ra) # 7fc <fork>
 214:	cd35                	beqz	a0,290 <testcase3+0xb6>
 216:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 218:	00001517          	auipc	a0,0x1
 21c:	c5850513          	addi	a0,a0,-936 # e70 <malloc+0x20e>
 220:	00001097          	auipc	ra,0x1
 224:	984080e7          	jalr	-1660(ra) # ba4 <printf>
        print_free_frame_cnt();
 228:	00000097          	auipc	ra,0x0
 22c:	69c080e7          	jalr	1692(ra) # 8c4 <pfreepages>

        printf("[prnt] read global_var, global_var=%d\n", global_var);
 230:	00002597          	auipc	a1,0x2
 234:	dd05a583          	lw	a1,-560(a1) # 2000 <global_var>
 238:	00001517          	auipc	a0,0x1
 23c:	d2850513          	addi	a0,a0,-728 # f60 <malloc+0x2fe>
 240:	00001097          	auipc	ra,0x1
 244:	964080e7          	jalr	-1692(ra) # ba4 <printf>

        printf("[prnt] v3 --> ");
 248:	00001517          	auipc	a0,0x1
 24c:	c8050513          	addi	a0,a0,-896 # ec8 <malloc+0x266>
 250:	00001097          	auipc	ra,0x1
 254:	954080e7          	jalr	-1708(ra) # ba4 <printf>
        print_free_frame_cnt();
 258:	00000097          	auipc	ra,0x0
 25c:	66c080e7          	jalr	1644(ra) # 8c4 <pfreepages>
    }

    if (wait(0) != pid)
 260:	4501                	li	a0,0
 262:	00000097          	auipc	ra,0x0
 266:	5aa080e7          	jalr	1450(ra) # 80c <wait>
 26a:	08951663          	bne	a0,s1,2f6 <testcase3+0x11c>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v6 --> ");
 26e:	00001517          	auipc	a0,0x1
 272:	d1a50513          	addi	a0,a0,-742 # f88 <malloc+0x326>
 276:	00001097          	auipc	ra,0x1
 27a:	92e080e7          	jalr	-1746(ra) # ba4 <printf>
    print_free_frame_cnt();
 27e:	00000097          	auipc	ra,0x0
 282:	646080e7          	jalr	1606(ra) # 8c4 <pfreepages>
}
 286:	60e2                	ld	ra,24(sp)
 288:	6442                	ld	s0,16(sp)
 28a:	64a2                	ld	s1,8(sp)
 28c:	6105                	addi	sp,sp,32
 28e:	8082                	ret
        sleep(50);
 290:	03200513          	li	a0,50
 294:	00000097          	auipc	ra,0x0
 298:	600080e7          	jalr	1536(ra) # 894 <sleep>
        printf("[chld] v4 --> ");
 29c:	00001517          	auipc	a0,0x1
 2a0:	afc50513          	addi	a0,a0,-1284 # d98 <malloc+0x136>
 2a4:	00001097          	auipc	ra,0x1
 2a8:	900080e7          	jalr	-1792(ra) # ba4 <printf>
        print_free_frame_cnt();
 2ac:	00000097          	auipc	ra,0x0
 2b0:	618080e7          	jalr	1560(ra) # 8c4 <pfreepages>
        global_var = 100;
 2b4:	06400793          	li	a5,100
 2b8:	00002717          	auipc	a4,0x2
 2bc:	d4f72423          	sw	a5,-696(a4) # 2000 <global_var>
        printf("[chld] modified global_var, global_var=%d\n", global_var);
 2c0:	06400593          	li	a1,100
 2c4:	00001517          	auipc	a0,0x1
 2c8:	c6c50513          	addi	a0,a0,-916 # f30 <malloc+0x2ce>
 2cc:	00001097          	auipc	ra,0x1
 2d0:	8d8080e7          	jalr	-1832(ra) # ba4 <printf>
        printf("[chld] v5 --> ");
 2d4:	00001517          	auipc	a0,0x1
 2d8:	b3450513          	addi	a0,a0,-1228 # e08 <malloc+0x1a6>
 2dc:	00001097          	auipc	ra,0x1
 2e0:	8c8080e7          	jalr	-1848(ra) # ba4 <printf>
        print_free_frame_cnt();
 2e4:	00000097          	auipc	ra,0x0
 2e8:	5e0080e7          	jalr	1504(ra) # 8c4 <pfreepages>
        exit(0);
 2ec:	4501                	li	a0,0
 2ee:	00000097          	auipc	ra,0x0
 2f2:	516080e7          	jalr	1302(ra) # 804 <exit>
        printf("wait() error!");
 2f6:	00001517          	auipc	a0,0x1
 2fa:	bfa50513          	addi	a0,a0,-1030 # ef0 <malloc+0x28e>
 2fe:	00001097          	auipc	ra,0x1
 302:	8a6080e7          	jalr	-1882(ra) # ba4 <printf>
        exit(1);
 306:	4505                	li	a0,1
 308:	00000097          	auipc	ra,0x0
 30c:	4fc080e7          	jalr	1276(ra) # 804 <exit>

0000000000000310 <testcase2>:

void testcase2()
{
 310:	1101                	addi	sp,sp,-32
 312:	ec06                	sd	ra,24(sp)
 314:	e822                	sd	s0,16(sp)
 316:	e426                	sd	s1,8(sp)
 318:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 2 -----\n");
 31a:	00001517          	auipc	a0,0x1
 31e:	c7e50513          	addi	a0,a0,-898 # f98 <malloc+0x336>
 322:	00001097          	auipc	ra,0x1
 326:	882080e7          	jalr	-1918(ra) # ba4 <printf>
    printf("[prnt] v1 --> ");
 32a:	00001517          	auipc	a0,0x1
 32e:	a4650513          	addi	a0,a0,-1466 # d70 <malloc+0x10e>
 332:	00001097          	auipc	ra,0x1
 336:	872080e7          	jalr	-1934(ra) # ba4 <printf>
    print_free_frame_cnt();
 33a:	00000097          	auipc	ra,0x0
 33e:	58a080e7          	jalr	1418(ra) # 8c4 <pfreepages>

    if ((pid = fork()) == 0)
 342:	00000097          	auipc	ra,0x0
 346:	4ba080e7          	jalr	1210(ra) # 7fc <fork>
 34a:	c531                	beqz	a0,396 <testcase2+0x86>
 34c:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 34e:	00001517          	auipc	a0,0x1
 352:	b2250513          	addi	a0,a0,-1246 # e70 <malloc+0x20e>
 356:	00001097          	auipc	ra,0x1
 35a:	84e080e7          	jalr	-1970(ra) # ba4 <printf>
        print_free_frame_cnt();
 35e:	00000097          	auipc	ra,0x0
 362:	566080e7          	jalr	1382(ra) # 8c4 <pfreepages>
    }

    if (wait(0) != pid)
 366:	4501                	li	a0,0
 368:	00000097          	auipc	ra,0x0
 36c:	4a4080e7          	jalr	1188(ra) # 80c <wait>
 370:	08951263          	bne	a0,s1,3f4 <testcase2+0xe4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v5 --> ");
 374:	00001517          	auipc	a0,0x1
 378:	c7c50513          	addi	a0,a0,-900 # ff0 <malloc+0x38e>
 37c:	00001097          	auipc	ra,0x1
 380:	828080e7          	jalr	-2008(ra) # ba4 <printf>
    print_free_frame_cnt();
 384:	00000097          	auipc	ra,0x0
 388:	540080e7          	jalr	1344(ra) # 8c4 <pfreepages>
}
 38c:	60e2                	ld	ra,24(sp)
 38e:	6442                	ld	s0,16(sp)
 390:	64a2                	ld	s1,8(sp)
 392:	6105                	addi	sp,sp,32
 394:	8082                	ret
        sleep(50);
 396:	03200513          	li	a0,50
 39a:	00000097          	auipc	ra,0x0
 39e:	4fa080e7          	jalr	1274(ra) # 894 <sleep>
        printf("[chld] v3 --> ");
 3a2:	00001517          	auipc	a0,0x1
 3a6:	c1650513          	addi	a0,a0,-1002 # fb8 <malloc+0x356>
 3aa:	00000097          	auipc	ra,0x0
 3ae:	7fa080e7          	jalr	2042(ra) # ba4 <printf>
        print_free_frame_cnt();
 3b2:	00000097          	auipc	ra,0x0
 3b6:	512080e7          	jalr	1298(ra) # 8c4 <pfreepages>
        printf("[chld] read global_var, global_var=%d\n", global_var);
 3ba:	00002597          	auipc	a1,0x2
 3be:	c465a583          	lw	a1,-954(a1) # 2000 <global_var>
 3c2:	00001517          	auipc	a0,0x1
 3c6:	c0650513          	addi	a0,a0,-1018 # fc8 <malloc+0x366>
 3ca:	00000097          	auipc	ra,0x0
 3ce:	7da080e7          	jalr	2010(ra) # ba4 <printf>
        printf("[chld] v4 --> ");
 3d2:	00001517          	auipc	a0,0x1
 3d6:	9c650513          	addi	a0,a0,-1594 # d98 <malloc+0x136>
 3da:	00000097          	auipc	ra,0x0
 3de:	7ca080e7          	jalr	1994(ra) # ba4 <printf>
        print_free_frame_cnt();
 3e2:	00000097          	auipc	ra,0x0
 3e6:	4e2080e7          	jalr	1250(ra) # 8c4 <pfreepages>
        exit(0);
 3ea:	4501                	li	a0,0
 3ec:	00000097          	auipc	ra,0x0
 3f0:	418080e7          	jalr	1048(ra) # 804 <exit>
        printf("wait() error!");
 3f4:	00001517          	auipc	a0,0x1
 3f8:	afc50513          	addi	a0,a0,-1284 # ef0 <malloc+0x28e>
 3fc:	00000097          	auipc	ra,0x0
 400:	7a8080e7          	jalr	1960(ra) # ba4 <printf>
        exit(1);
 404:	4505                	li	a0,1
 406:	00000097          	auipc	ra,0x0
 40a:	3fe080e7          	jalr	1022(ra) # 804 <exit>

000000000000040e <testcase1>:

void testcase1()
{
 40e:	1101                	addi	sp,sp,-32
 410:	ec06                	sd	ra,24(sp)
 412:	e822                	sd	s0,16(sp)
 414:	e426                	sd	s1,8(sp)
 416:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 1 -----\n");
 418:	00001517          	auipc	a0,0x1
 41c:	be850513          	addi	a0,a0,-1048 # 1000 <malloc+0x39e>
 420:	00000097          	auipc	ra,0x0
 424:	784080e7          	jalr	1924(ra) # ba4 <printf>
    printf("[prnt] v1 --> ");
 428:	00001517          	auipc	a0,0x1
 42c:	94850513          	addi	a0,a0,-1720 # d70 <malloc+0x10e>
 430:	00000097          	auipc	ra,0x0
 434:	774080e7          	jalr	1908(ra) # ba4 <printf>
    print_free_frame_cnt();
 438:	00000097          	auipc	ra,0x0
 43c:	48c080e7          	jalr	1164(ra) # 8c4 <pfreepages>

    if ((pid = fork()) == 0)
 440:	00000097          	auipc	ra,0x0
 444:	3bc080e7          	jalr	956(ra) # 7fc <fork>
 448:	c531                	beqz	a0,494 <testcase1+0x86>
 44a:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v3 --> ");
 44c:	00001517          	auipc	a0,0x1
 450:	a7c50513          	addi	a0,a0,-1412 # ec8 <malloc+0x266>
 454:	00000097          	auipc	ra,0x0
 458:	750080e7          	jalr	1872(ra) # ba4 <printf>
        print_free_frame_cnt();
 45c:	00000097          	auipc	ra,0x0
 460:	468080e7          	jalr	1128(ra) # 8c4 <pfreepages>
    }

    if (wait(0) != pid)
 464:	4501                	li	a0,0
 466:	00000097          	auipc	ra,0x0
 46a:	3a6080e7          	jalr	934(ra) # 80c <wait>
 46e:	04951a63          	bne	a0,s1,4c2 <testcase1+0xb4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v4 --> ");
 472:	00001517          	auipc	a0,0x1
 476:	bbe50513          	addi	a0,a0,-1090 # 1030 <malloc+0x3ce>
 47a:	00000097          	auipc	ra,0x0
 47e:	72a080e7          	jalr	1834(ra) # ba4 <printf>
    print_free_frame_cnt();
 482:	00000097          	auipc	ra,0x0
 486:	442080e7          	jalr	1090(ra) # 8c4 <pfreepages>
}
 48a:	60e2                	ld	ra,24(sp)
 48c:	6442                	ld	s0,16(sp)
 48e:	64a2                	ld	s1,8(sp)
 490:	6105                	addi	sp,sp,32
 492:	8082                	ret
        sleep(50);
 494:	03200513          	li	a0,50
 498:	00000097          	auipc	ra,0x0
 49c:	3fc080e7          	jalr	1020(ra) # 894 <sleep>
        printf("[chld] v2 --> ");
 4a0:	00001517          	auipc	a0,0x1
 4a4:	b8050513          	addi	a0,a0,-1152 # 1020 <malloc+0x3be>
 4a8:	00000097          	auipc	ra,0x0
 4ac:	6fc080e7          	jalr	1788(ra) # ba4 <printf>
        print_free_frame_cnt();
 4b0:	00000097          	auipc	ra,0x0
 4b4:	414080e7          	jalr	1044(ra) # 8c4 <pfreepages>
        exit(0);
 4b8:	4501                	li	a0,0
 4ba:	00000097          	auipc	ra,0x0
 4be:	34a080e7          	jalr	842(ra) # 804 <exit>
        printf("wait() error!");
 4c2:	00001517          	auipc	a0,0x1
 4c6:	a2e50513          	addi	a0,a0,-1490 # ef0 <malloc+0x28e>
 4ca:	00000097          	auipc	ra,0x0
 4ce:	6da080e7          	jalr	1754(ra) # ba4 <printf>
        exit(1);
 4d2:	4505                	li	a0,1
 4d4:	00000097          	auipc	ra,0x0
 4d8:	330080e7          	jalr	816(ra) # 804 <exit>

00000000000004dc <main>:

int main(int argc, char *argv[])
{
 4dc:	1101                	addi	sp,sp,-32
 4de:	ec06                	sd	ra,24(sp)
 4e0:	e822                	sd	s0,16(sp)
 4e2:	e426                	sd	s1,8(sp)
 4e4:	1000                	addi	s0,sp,32
 4e6:	84ae                	mv	s1,a1
    if (argc < 2)
 4e8:	4785                	li	a5,1
 4ea:	02a7d863          	bge	a5,a0,51a <main+0x3e>
    {
        printf("Usage: cowtest test_id");
    }
    switch (atoi(argv[1]))
 4ee:	6488                	ld	a0,8(s1)
 4f0:	00000097          	auipc	ra,0x0
 4f4:	214080e7          	jalr	532(ra) # 704 <atoi>
 4f8:	478d                	li	a5,3
 4fa:	04f50c63          	beq	a0,a5,552 <main+0x76>
 4fe:	02a7c763          	blt	a5,a0,52c <main+0x50>
 502:	4785                	li	a5,1
 504:	02f50d63          	beq	a0,a5,53e <main+0x62>
 508:	4789                	li	a5,2
 50a:	04f51a63          	bne	a0,a5,55e <main+0x82>
    case 1:
        testcase1();
        break;

    case 2:
        testcase2();
 50e:	00000097          	auipc	ra,0x0
 512:	e02080e7          	jalr	-510(ra) # 310 <testcase2>

    default:
        printf("Error: No test with index %s", argv[1]);
        return 1;
    }
    return 0;
 516:	4501                	li	a0,0
        break;
 518:	a805                	j	548 <main+0x6c>
        printf("Usage: cowtest test_id");
 51a:	00001517          	auipc	a0,0x1
 51e:	b2650513          	addi	a0,a0,-1242 # 1040 <malloc+0x3de>
 522:	00000097          	auipc	ra,0x0
 526:	682080e7          	jalr	1666(ra) # ba4 <printf>
 52a:	b7d1                	j	4ee <main+0x12>
    switch (atoi(argv[1]))
 52c:	4791                	li	a5,4
 52e:	02f51863          	bne	a0,a5,55e <main+0x82>
        testcase4();
 532:	00000097          	auipc	ra,0x0
 536:	ace080e7          	jalr	-1330(ra) # 0 <testcase4>
    return 0;
 53a:	4501                	li	a0,0
        break;
 53c:	a031                	j	548 <main+0x6c>
        testcase1();
 53e:	00000097          	auipc	ra,0x0
 542:	ed0080e7          	jalr	-304(ra) # 40e <testcase1>
    return 0;
 546:	4501                	li	a0,0
 548:	60e2                	ld	ra,24(sp)
 54a:	6442                	ld	s0,16(sp)
 54c:	64a2                	ld	s1,8(sp)
 54e:	6105                	addi	sp,sp,32
 550:	8082                	ret
        testcase3();
 552:	00000097          	auipc	ra,0x0
 556:	c88080e7          	jalr	-888(ra) # 1da <testcase3>
    return 0;
 55a:	4501                	li	a0,0
        break;
 55c:	b7f5                	j	548 <main+0x6c>
        printf("Error: No test with index %s", argv[1]);
 55e:	648c                	ld	a1,8(s1)
 560:	00001517          	auipc	a0,0x1
 564:	af850513          	addi	a0,a0,-1288 # 1058 <malloc+0x3f6>
 568:	00000097          	auipc	ra,0x0
 56c:	63c080e7          	jalr	1596(ra) # ba4 <printf>
        return 1;
 570:	4505                	li	a0,1
 572:	bfd9                	j	548 <main+0x6c>

0000000000000574 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 574:	1141                	addi	sp,sp,-16
 576:	e406                	sd	ra,8(sp)
 578:	e022                	sd	s0,0(sp)
 57a:	0800                	addi	s0,sp,16
  extern int main();
  main();
 57c:	00000097          	auipc	ra,0x0
 580:	f60080e7          	jalr	-160(ra) # 4dc <main>
  exit(0);
 584:	4501                	li	a0,0
 586:	00000097          	auipc	ra,0x0
 58a:	27e080e7          	jalr	638(ra) # 804 <exit>

000000000000058e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 58e:	1141                	addi	sp,sp,-16
 590:	e422                	sd	s0,8(sp)
 592:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 594:	87aa                	mv	a5,a0
 596:	0585                	addi	a1,a1,1
 598:	0785                	addi	a5,a5,1
 59a:	fff5c703          	lbu	a4,-1(a1)
 59e:	fee78fa3          	sb	a4,-1(a5)
 5a2:	fb75                	bnez	a4,596 <strcpy+0x8>
    ;
  return os;
}
 5a4:	6422                	ld	s0,8(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret

00000000000005aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
 5aa:	1141                	addi	sp,sp,-16
 5ac:	e422                	sd	s0,8(sp)
 5ae:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 5b0:	00054783          	lbu	a5,0(a0)
 5b4:	cb91                	beqz	a5,5c8 <strcmp+0x1e>
 5b6:	0005c703          	lbu	a4,0(a1)
 5ba:	00f71763          	bne	a4,a5,5c8 <strcmp+0x1e>
    p++, q++;
 5be:	0505                	addi	a0,a0,1
 5c0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 5c2:	00054783          	lbu	a5,0(a0)
 5c6:	fbe5                	bnez	a5,5b6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 5c8:	0005c503          	lbu	a0,0(a1)
}
 5cc:	40a7853b          	subw	a0,a5,a0
 5d0:	6422                	ld	s0,8(sp)
 5d2:	0141                	addi	sp,sp,16
 5d4:	8082                	ret

00000000000005d6 <strlen>:

uint
strlen(const char *s)
{
 5d6:	1141                	addi	sp,sp,-16
 5d8:	e422                	sd	s0,8(sp)
 5da:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 5dc:	00054783          	lbu	a5,0(a0)
 5e0:	cf91                	beqz	a5,5fc <strlen+0x26>
 5e2:	0505                	addi	a0,a0,1
 5e4:	87aa                	mv	a5,a0
 5e6:	4685                	li	a3,1
 5e8:	9e89                	subw	a3,a3,a0
 5ea:	00f6853b          	addw	a0,a3,a5
 5ee:	0785                	addi	a5,a5,1
 5f0:	fff7c703          	lbu	a4,-1(a5)
 5f4:	fb7d                	bnez	a4,5ea <strlen+0x14>
    ;
  return n;
}
 5f6:	6422                	ld	s0,8(sp)
 5f8:	0141                	addi	sp,sp,16
 5fa:	8082                	ret
  for(n = 0; s[n]; n++)
 5fc:	4501                	li	a0,0
 5fe:	bfe5                	j	5f6 <strlen+0x20>

0000000000000600 <memset>:

void*
memset(void *dst, int c, uint n)
{
 600:	1141                	addi	sp,sp,-16
 602:	e422                	sd	s0,8(sp)
 604:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 606:	ce09                	beqz	a2,620 <memset+0x20>
 608:	87aa                	mv	a5,a0
 60a:	fff6071b          	addiw	a4,a2,-1
 60e:	1702                	slli	a4,a4,0x20
 610:	9301                	srli	a4,a4,0x20
 612:	0705                	addi	a4,a4,1
 614:	972a                	add	a4,a4,a0
    cdst[i] = c;
 616:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 61a:	0785                	addi	a5,a5,1
 61c:	fee79de3          	bne	a5,a4,616 <memset+0x16>
  }
  return dst;
}
 620:	6422                	ld	s0,8(sp)
 622:	0141                	addi	sp,sp,16
 624:	8082                	ret

0000000000000626 <strchr>:

char*
strchr(const char *s, char c)
{
 626:	1141                	addi	sp,sp,-16
 628:	e422                	sd	s0,8(sp)
 62a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 62c:	00054783          	lbu	a5,0(a0)
 630:	cb99                	beqz	a5,646 <strchr+0x20>
    if(*s == c)
 632:	00f58763          	beq	a1,a5,640 <strchr+0x1a>
  for(; *s; s++)
 636:	0505                	addi	a0,a0,1
 638:	00054783          	lbu	a5,0(a0)
 63c:	fbfd                	bnez	a5,632 <strchr+0xc>
      return (char*)s;
  return 0;
 63e:	4501                	li	a0,0
}
 640:	6422                	ld	s0,8(sp)
 642:	0141                	addi	sp,sp,16
 644:	8082                	ret
  return 0;
 646:	4501                	li	a0,0
 648:	bfe5                	j	640 <strchr+0x1a>

000000000000064a <gets>:

char*
gets(char *buf, int max)
{
 64a:	711d                	addi	sp,sp,-96
 64c:	ec86                	sd	ra,88(sp)
 64e:	e8a2                	sd	s0,80(sp)
 650:	e4a6                	sd	s1,72(sp)
 652:	e0ca                	sd	s2,64(sp)
 654:	fc4e                	sd	s3,56(sp)
 656:	f852                	sd	s4,48(sp)
 658:	f456                	sd	s5,40(sp)
 65a:	f05a                	sd	s6,32(sp)
 65c:	ec5e                	sd	s7,24(sp)
 65e:	1080                	addi	s0,sp,96
 660:	8baa                	mv	s7,a0
 662:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 664:	892a                	mv	s2,a0
 666:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 668:	4aa9                	li	s5,10
 66a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 66c:	89a6                	mv	s3,s1
 66e:	2485                	addiw	s1,s1,1
 670:	0344d863          	bge	s1,s4,6a0 <gets+0x56>
    cc = read(0, &c, 1);
 674:	4605                	li	a2,1
 676:	faf40593          	addi	a1,s0,-81
 67a:	4501                	li	a0,0
 67c:	00000097          	auipc	ra,0x0
 680:	1a0080e7          	jalr	416(ra) # 81c <read>
    if(cc < 1)
 684:	00a05e63          	blez	a0,6a0 <gets+0x56>
    buf[i++] = c;
 688:	faf44783          	lbu	a5,-81(s0)
 68c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 690:	01578763          	beq	a5,s5,69e <gets+0x54>
 694:	0905                	addi	s2,s2,1
 696:	fd679be3          	bne	a5,s6,66c <gets+0x22>
  for(i=0; i+1 < max; ){
 69a:	89a6                	mv	s3,s1
 69c:	a011                	j	6a0 <gets+0x56>
 69e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 6a0:	99de                	add	s3,s3,s7
 6a2:	00098023          	sb	zero,0(s3)
  return buf;
}
 6a6:	855e                	mv	a0,s7
 6a8:	60e6                	ld	ra,88(sp)
 6aa:	6446                	ld	s0,80(sp)
 6ac:	64a6                	ld	s1,72(sp)
 6ae:	6906                	ld	s2,64(sp)
 6b0:	79e2                	ld	s3,56(sp)
 6b2:	7a42                	ld	s4,48(sp)
 6b4:	7aa2                	ld	s5,40(sp)
 6b6:	7b02                	ld	s6,32(sp)
 6b8:	6be2                	ld	s7,24(sp)
 6ba:	6125                	addi	sp,sp,96
 6bc:	8082                	ret

00000000000006be <stat>:

int
stat(const char *n, struct stat *st)
{
 6be:	1101                	addi	sp,sp,-32
 6c0:	ec06                	sd	ra,24(sp)
 6c2:	e822                	sd	s0,16(sp)
 6c4:	e426                	sd	s1,8(sp)
 6c6:	e04a                	sd	s2,0(sp)
 6c8:	1000                	addi	s0,sp,32
 6ca:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 6cc:	4581                	li	a1,0
 6ce:	00000097          	auipc	ra,0x0
 6d2:	176080e7          	jalr	374(ra) # 844 <open>
  if(fd < 0)
 6d6:	02054563          	bltz	a0,700 <stat+0x42>
 6da:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 6dc:	85ca                	mv	a1,s2
 6de:	00000097          	auipc	ra,0x0
 6e2:	17e080e7          	jalr	382(ra) # 85c <fstat>
 6e6:	892a                	mv	s2,a0
  close(fd);
 6e8:	8526                	mv	a0,s1
 6ea:	00000097          	auipc	ra,0x0
 6ee:	142080e7          	jalr	322(ra) # 82c <close>
  return r;
}
 6f2:	854a                	mv	a0,s2
 6f4:	60e2                	ld	ra,24(sp)
 6f6:	6442                	ld	s0,16(sp)
 6f8:	64a2                	ld	s1,8(sp)
 6fa:	6902                	ld	s2,0(sp)
 6fc:	6105                	addi	sp,sp,32
 6fe:	8082                	ret
    return -1;
 700:	597d                	li	s2,-1
 702:	bfc5                	j	6f2 <stat+0x34>

0000000000000704 <atoi>:

int
atoi(const char *s)
{
 704:	1141                	addi	sp,sp,-16
 706:	e422                	sd	s0,8(sp)
 708:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 70a:	00054603          	lbu	a2,0(a0)
 70e:	fd06079b          	addiw	a5,a2,-48
 712:	0ff7f793          	andi	a5,a5,255
 716:	4725                	li	a4,9
 718:	02f76963          	bltu	a4,a5,74a <atoi+0x46>
 71c:	86aa                	mv	a3,a0
  n = 0;
 71e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 720:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 722:	0685                	addi	a3,a3,1
 724:	0025179b          	slliw	a5,a0,0x2
 728:	9fa9                	addw	a5,a5,a0
 72a:	0017979b          	slliw	a5,a5,0x1
 72e:	9fb1                	addw	a5,a5,a2
 730:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 734:	0006c603          	lbu	a2,0(a3)
 738:	fd06071b          	addiw	a4,a2,-48
 73c:	0ff77713          	andi	a4,a4,255
 740:	fee5f1e3          	bgeu	a1,a4,722 <atoi+0x1e>
  return n;
}
 744:	6422                	ld	s0,8(sp)
 746:	0141                	addi	sp,sp,16
 748:	8082                	ret
  n = 0;
 74a:	4501                	li	a0,0
 74c:	bfe5                	j	744 <atoi+0x40>

000000000000074e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 74e:	1141                	addi	sp,sp,-16
 750:	e422                	sd	s0,8(sp)
 752:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 754:	02b57663          	bgeu	a0,a1,780 <memmove+0x32>
    while(n-- > 0)
 758:	02c05163          	blez	a2,77a <memmove+0x2c>
 75c:	fff6079b          	addiw	a5,a2,-1
 760:	1782                	slli	a5,a5,0x20
 762:	9381                	srli	a5,a5,0x20
 764:	0785                	addi	a5,a5,1
 766:	97aa                	add	a5,a5,a0
  dst = vdst;
 768:	872a                	mv	a4,a0
      *dst++ = *src++;
 76a:	0585                	addi	a1,a1,1
 76c:	0705                	addi	a4,a4,1
 76e:	fff5c683          	lbu	a3,-1(a1)
 772:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 776:	fee79ae3          	bne	a5,a4,76a <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 77a:	6422                	ld	s0,8(sp)
 77c:	0141                	addi	sp,sp,16
 77e:	8082                	ret
    dst += n;
 780:	00c50733          	add	a4,a0,a2
    src += n;
 784:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 786:	fec05ae3          	blez	a2,77a <memmove+0x2c>
 78a:	fff6079b          	addiw	a5,a2,-1
 78e:	1782                	slli	a5,a5,0x20
 790:	9381                	srli	a5,a5,0x20
 792:	fff7c793          	not	a5,a5
 796:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 798:	15fd                	addi	a1,a1,-1
 79a:	177d                	addi	a4,a4,-1
 79c:	0005c683          	lbu	a3,0(a1)
 7a0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 7a4:	fee79ae3          	bne	a5,a4,798 <memmove+0x4a>
 7a8:	bfc9                	j	77a <memmove+0x2c>

00000000000007aa <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 7aa:	1141                	addi	sp,sp,-16
 7ac:	e422                	sd	s0,8(sp)
 7ae:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 7b0:	ca05                	beqz	a2,7e0 <memcmp+0x36>
 7b2:	fff6069b          	addiw	a3,a2,-1
 7b6:	1682                	slli	a3,a3,0x20
 7b8:	9281                	srli	a3,a3,0x20
 7ba:	0685                	addi	a3,a3,1
 7bc:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 7be:	00054783          	lbu	a5,0(a0)
 7c2:	0005c703          	lbu	a4,0(a1)
 7c6:	00e79863          	bne	a5,a4,7d6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 7ca:	0505                	addi	a0,a0,1
    p2++;
 7cc:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 7ce:	fed518e3          	bne	a0,a3,7be <memcmp+0x14>
  }
  return 0;
 7d2:	4501                	li	a0,0
 7d4:	a019                	j	7da <memcmp+0x30>
      return *p1 - *p2;
 7d6:	40e7853b          	subw	a0,a5,a4
}
 7da:	6422                	ld	s0,8(sp)
 7dc:	0141                	addi	sp,sp,16
 7de:	8082                	ret
  return 0;
 7e0:	4501                	li	a0,0
 7e2:	bfe5                	j	7da <memcmp+0x30>

00000000000007e4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 7e4:	1141                	addi	sp,sp,-16
 7e6:	e406                	sd	ra,8(sp)
 7e8:	e022                	sd	s0,0(sp)
 7ea:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 7ec:	00000097          	auipc	ra,0x0
 7f0:	f62080e7          	jalr	-158(ra) # 74e <memmove>
}
 7f4:	60a2                	ld	ra,8(sp)
 7f6:	6402                	ld	s0,0(sp)
 7f8:	0141                	addi	sp,sp,16
 7fa:	8082                	ret

00000000000007fc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7fc:	4885                	li	a7,1
 ecall
 7fe:	00000073          	ecall
 ret
 802:	8082                	ret

0000000000000804 <exit>:
.global exit
exit:
 li a7, SYS_exit
 804:	4889                	li	a7,2
 ecall
 806:	00000073          	ecall
 ret
 80a:	8082                	ret

000000000000080c <wait>:
.global wait
wait:
 li a7, SYS_wait
 80c:	488d                	li	a7,3
 ecall
 80e:	00000073          	ecall
 ret
 812:	8082                	ret

0000000000000814 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 814:	4891                	li	a7,4
 ecall
 816:	00000073          	ecall
 ret
 81a:	8082                	ret

000000000000081c <read>:
.global read
read:
 li a7, SYS_read
 81c:	4895                	li	a7,5
 ecall
 81e:	00000073          	ecall
 ret
 822:	8082                	ret

0000000000000824 <write>:
.global write
write:
 li a7, SYS_write
 824:	48c1                	li	a7,16
 ecall
 826:	00000073          	ecall
 ret
 82a:	8082                	ret

000000000000082c <close>:
.global close
close:
 li a7, SYS_close
 82c:	48d5                	li	a7,21
 ecall
 82e:	00000073          	ecall
 ret
 832:	8082                	ret

0000000000000834 <kill>:
.global kill
kill:
 li a7, SYS_kill
 834:	4899                	li	a7,6
 ecall
 836:	00000073          	ecall
 ret
 83a:	8082                	ret

000000000000083c <exec>:
.global exec
exec:
 li a7, SYS_exec
 83c:	489d                	li	a7,7
 ecall
 83e:	00000073          	ecall
 ret
 842:	8082                	ret

0000000000000844 <open>:
.global open
open:
 li a7, SYS_open
 844:	48bd                	li	a7,15
 ecall
 846:	00000073          	ecall
 ret
 84a:	8082                	ret

000000000000084c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 84c:	48c5                	li	a7,17
 ecall
 84e:	00000073          	ecall
 ret
 852:	8082                	ret

0000000000000854 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 854:	48c9                	li	a7,18
 ecall
 856:	00000073          	ecall
 ret
 85a:	8082                	ret

000000000000085c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 85c:	48a1                	li	a7,8
 ecall
 85e:	00000073          	ecall
 ret
 862:	8082                	ret

0000000000000864 <link>:
.global link
link:
 li a7, SYS_link
 864:	48cd                	li	a7,19
 ecall
 866:	00000073          	ecall
 ret
 86a:	8082                	ret

000000000000086c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 86c:	48d1                	li	a7,20
 ecall
 86e:	00000073          	ecall
 ret
 872:	8082                	ret

0000000000000874 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 874:	48a5                	li	a7,9
 ecall
 876:	00000073          	ecall
 ret
 87a:	8082                	ret

000000000000087c <dup>:
.global dup
dup:
 li a7, SYS_dup
 87c:	48a9                	li	a7,10
 ecall
 87e:	00000073          	ecall
 ret
 882:	8082                	ret

0000000000000884 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 884:	48ad                	li	a7,11
 ecall
 886:	00000073          	ecall
 ret
 88a:	8082                	ret

000000000000088c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 88c:	48b1                	li	a7,12
 ecall
 88e:	00000073          	ecall
 ret
 892:	8082                	ret

0000000000000894 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 894:	48b5                	li	a7,13
 ecall
 896:	00000073          	ecall
 ret
 89a:	8082                	ret

000000000000089c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 89c:	48b9                	li	a7,14
 ecall
 89e:	00000073          	ecall
 ret
 8a2:	8082                	ret

00000000000008a4 <ps>:
.global ps
ps:
 li a7, SYS_ps
 8a4:	48d9                	li	a7,22
 ecall
 8a6:	00000073          	ecall
 ret
 8aa:	8082                	ret

00000000000008ac <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 8ac:	48dd                	li	a7,23
 ecall
 8ae:	00000073          	ecall
 ret
 8b2:	8082                	ret

00000000000008b4 <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 8b4:	48e1                	li	a7,24
 ecall
 8b6:	00000073          	ecall
 ret
 8ba:	8082                	ret

00000000000008bc <va2pa>:
.global va2pa
va2pa:
 li a7, SYS_va2pa
 8bc:	48e9                	li	a7,26
 ecall
 8be:	00000073          	ecall
 ret
 8c2:	8082                	ret

00000000000008c4 <pfreepages>:
.global pfreepages
pfreepages:
 li a7, SYS_pfreepages
 8c4:	48e5                	li	a7,25
 ecall
 8c6:	00000073          	ecall
 ret
 8ca:	8082                	ret

00000000000008cc <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 8cc:	1101                	addi	sp,sp,-32
 8ce:	ec06                	sd	ra,24(sp)
 8d0:	e822                	sd	s0,16(sp)
 8d2:	1000                	addi	s0,sp,32
 8d4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 8d8:	4605                	li	a2,1
 8da:	fef40593          	addi	a1,s0,-17
 8de:	00000097          	auipc	ra,0x0
 8e2:	f46080e7          	jalr	-186(ra) # 824 <write>
}
 8e6:	60e2                	ld	ra,24(sp)
 8e8:	6442                	ld	s0,16(sp)
 8ea:	6105                	addi	sp,sp,32
 8ec:	8082                	ret

00000000000008ee <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 8ee:	7139                	addi	sp,sp,-64
 8f0:	fc06                	sd	ra,56(sp)
 8f2:	f822                	sd	s0,48(sp)
 8f4:	f426                	sd	s1,40(sp)
 8f6:	f04a                	sd	s2,32(sp)
 8f8:	ec4e                	sd	s3,24(sp)
 8fa:	0080                	addi	s0,sp,64
 8fc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 8fe:	c299                	beqz	a3,904 <printint+0x16>
 900:	0805c863          	bltz	a1,990 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 904:	2581                	sext.w	a1,a1
  neg = 0;
 906:	4881                	li	a7,0
 908:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 90c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 90e:	2601                	sext.w	a2,a2
 910:	00000517          	auipc	a0,0x0
 914:	77050513          	addi	a0,a0,1904 # 1080 <digits>
 918:	883a                	mv	a6,a4
 91a:	2705                	addiw	a4,a4,1
 91c:	02c5f7bb          	remuw	a5,a1,a2
 920:	1782                	slli	a5,a5,0x20
 922:	9381                	srli	a5,a5,0x20
 924:	97aa                	add	a5,a5,a0
 926:	0007c783          	lbu	a5,0(a5)
 92a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 92e:	0005879b          	sext.w	a5,a1
 932:	02c5d5bb          	divuw	a1,a1,a2
 936:	0685                	addi	a3,a3,1
 938:	fec7f0e3          	bgeu	a5,a2,918 <printint+0x2a>
  if(neg)
 93c:	00088b63          	beqz	a7,952 <printint+0x64>
    buf[i++] = '-';
 940:	fd040793          	addi	a5,s0,-48
 944:	973e                	add	a4,a4,a5
 946:	02d00793          	li	a5,45
 94a:	fef70823          	sb	a5,-16(a4)
 94e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 952:	02e05863          	blez	a4,982 <printint+0x94>
 956:	fc040793          	addi	a5,s0,-64
 95a:	00e78933          	add	s2,a5,a4
 95e:	fff78993          	addi	s3,a5,-1
 962:	99ba                	add	s3,s3,a4
 964:	377d                	addiw	a4,a4,-1
 966:	1702                	slli	a4,a4,0x20
 968:	9301                	srli	a4,a4,0x20
 96a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 96e:	fff94583          	lbu	a1,-1(s2)
 972:	8526                	mv	a0,s1
 974:	00000097          	auipc	ra,0x0
 978:	f58080e7          	jalr	-168(ra) # 8cc <putc>
  while(--i >= 0)
 97c:	197d                	addi	s2,s2,-1
 97e:	ff3918e3          	bne	s2,s3,96e <printint+0x80>
}
 982:	70e2                	ld	ra,56(sp)
 984:	7442                	ld	s0,48(sp)
 986:	74a2                	ld	s1,40(sp)
 988:	7902                	ld	s2,32(sp)
 98a:	69e2                	ld	s3,24(sp)
 98c:	6121                	addi	sp,sp,64
 98e:	8082                	ret
    x = -xx;
 990:	40b005bb          	negw	a1,a1
    neg = 1;
 994:	4885                	li	a7,1
    x = -xx;
 996:	bf8d                	j	908 <printint+0x1a>

0000000000000998 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 998:	7119                	addi	sp,sp,-128
 99a:	fc86                	sd	ra,120(sp)
 99c:	f8a2                	sd	s0,112(sp)
 99e:	f4a6                	sd	s1,104(sp)
 9a0:	f0ca                	sd	s2,96(sp)
 9a2:	ecce                	sd	s3,88(sp)
 9a4:	e8d2                	sd	s4,80(sp)
 9a6:	e4d6                	sd	s5,72(sp)
 9a8:	e0da                	sd	s6,64(sp)
 9aa:	fc5e                	sd	s7,56(sp)
 9ac:	f862                	sd	s8,48(sp)
 9ae:	f466                	sd	s9,40(sp)
 9b0:	f06a                	sd	s10,32(sp)
 9b2:	ec6e                	sd	s11,24(sp)
 9b4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 9b6:	0005c903          	lbu	s2,0(a1)
 9ba:	18090f63          	beqz	s2,b58 <vprintf+0x1c0>
 9be:	8aaa                	mv	s5,a0
 9c0:	8b32                	mv	s6,a2
 9c2:	00158493          	addi	s1,a1,1
  state = 0;
 9c6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 9c8:	02500a13          	li	s4,37
      if(c == 'd'){
 9cc:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 9d0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 9d4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 9d8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9dc:	00000b97          	auipc	s7,0x0
 9e0:	6a4b8b93          	addi	s7,s7,1700 # 1080 <digits>
 9e4:	a839                	j	a02 <vprintf+0x6a>
        putc(fd, c);
 9e6:	85ca                	mv	a1,s2
 9e8:	8556                	mv	a0,s5
 9ea:	00000097          	auipc	ra,0x0
 9ee:	ee2080e7          	jalr	-286(ra) # 8cc <putc>
 9f2:	a019                	j	9f8 <vprintf+0x60>
    } else if(state == '%'){
 9f4:	01498f63          	beq	s3,s4,a12 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 9f8:	0485                	addi	s1,s1,1
 9fa:	fff4c903          	lbu	s2,-1(s1)
 9fe:	14090d63          	beqz	s2,b58 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 a02:	0009079b          	sext.w	a5,s2
    if(state == 0){
 a06:	fe0997e3          	bnez	s3,9f4 <vprintf+0x5c>
      if(c == '%'){
 a0a:	fd479ee3          	bne	a5,s4,9e6 <vprintf+0x4e>
        state = '%';
 a0e:	89be                	mv	s3,a5
 a10:	b7e5                	j	9f8 <vprintf+0x60>
      if(c == 'd'){
 a12:	05878063          	beq	a5,s8,a52 <vprintf+0xba>
      } else if(c == 'l') {
 a16:	05978c63          	beq	a5,s9,a6e <vprintf+0xd6>
      } else if(c == 'x') {
 a1a:	07a78863          	beq	a5,s10,a8a <vprintf+0xf2>
      } else if(c == 'p') {
 a1e:	09b78463          	beq	a5,s11,aa6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 a22:	07300713          	li	a4,115
 a26:	0ce78663          	beq	a5,a4,af2 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 a2a:	06300713          	li	a4,99
 a2e:	0ee78e63          	beq	a5,a4,b2a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 a32:	11478863          	beq	a5,s4,b42 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 a36:	85d2                	mv	a1,s4
 a38:	8556                	mv	a0,s5
 a3a:	00000097          	auipc	ra,0x0
 a3e:	e92080e7          	jalr	-366(ra) # 8cc <putc>
        putc(fd, c);
 a42:	85ca                	mv	a1,s2
 a44:	8556                	mv	a0,s5
 a46:	00000097          	auipc	ra,0x0
 a4a:	e86080e7          	jalr	-378(ra) # 8cc <putc>
      }
      state = 0;
 a4e:	4981                	li	s3,0
 a50:	b765                	j	9f8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 a52:	008b0913          	addi	s2,s6,8
 a56:	4685                	li	a3,1
 a58:	4629                	li	a2,10
 a5a:	000b2583          	lw	a1,0(s6)
 a5e:	8556                	mv	a0,s5
 a60:	00000097          	auipc	ra,0x0
 a64:	e8e080e7          	jalr	-370(ra) # 8ee <printint>
 a68:	8b4a                	mv	s6,s2
      state = 0;
 a6a:	4981                	li	s3,0
 a6c:	b771                	j	9f8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a6e:	008b0913          	addi	s2,s6,8
 a72:	4681                	li	a3,0
 a74:	4629                	li	a2,10
 a76:	000b2583          	lw	a1,0(s6)
 a7a:	8556                	mv	a0,s5
 a7c:	00000097          	auipc	ra,0x0
 a80:	e72080e7          	jalr	-398(ra) # 8ee <printint>
 a84:	8b4a                	mv	s6,s2
      state = 0;
 a86:	4981                	li	s3,0
 a88:	bf85                	j	9f8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a8a:	008b0913          	addi	s2,s6,8
 a8e:	4681                	li	a3,0
 a90:	4641                	li	a2,16
 a92:	000b2583          	lw	a1,0(s6)
 a96:	8556                	mv	a0,s5
 a98:	00000097          	auipc	ra,0x0
 a9c:	e56080e7          	jalr	-426(ra) # 8ee <printint>
 aa0:	8b4a                	mv	s6,s2
      state = 0;
 aa2:	4981                	li	s3,0
 aa4:	bf91                	j	9f8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 aa6:	008b0793          	addi	a5,s6,8
 aaa:	f8f43423          	sd	a5,-120(s0)
 aae:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 ab2:	03000593          	li	a1,48
 ab6:	8556                	mv	a0,s5
 ab8:	00000097          	auipc	ra,0x0
 abc:	e14080e7          	jalr	-492(ra) # 8cc <putc>
  putc(fd, 'x');
 ac0:	85ea                	mv	a1,s10
 ac2:	8556                	mv	a0,s5
 ac4:	00000097          	auipc	ra,0x0
 ac8:	e08080e7          	jalr	-504(ra) # 8cc <putc>
 acc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 ace:	03c9d793          	srli	a5,s3,0x3c
 ad2:	97de                	add	a5,a5,s7
 ad4:	0007c583          	lbu	a1,0(a5)
 ad8:	8556                	mv	a0,s5
 ada:	00000097          	auipc	ra,0x0
 ade:	df2080e7          	jalr	-526(ra) # 8cc <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 ae2:	0992                	slli	s3,s3,0x4
 ae4:	397d                	addiw	s2,s2,-1
 ae6:	fe0914e3          	bnez	s2,ace <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 aea:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 aee:	4981                	li	s3,0
 af0:	b721                	j	9f8 <vprintf+0x60>
        s = va_arg(ap, char*);
 af2:	008b0993          	addi	s3,s6,8
 af6:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 afa:	02090163          	beqz	s2,b1c <vprintf+0x184>
        while(*s != 0){
 afe:	00094583          	lbu	a1,0(s2)
 b02:	c9a1                	beqz	a1,b52 <vprintf+0x1ba>
          putc(fd, *s);
 b04:	8556                	mv	a0,s5
 b06:	00000097          	auipc	ra,0x0
 b0a:	dc6080e7          	jalr	-570(ra) # 8cc <putc>
          s++;
 b0e:	0905                	addi	s2,s2,1
        while(*s != 0){
 b10:	00094583          	lbu	a1,0(s2)
 b14:	f9e5                	bnez	a1,b04 <vprintf+0x16c>
        s = va_arg(ap, char*);
 b16:	8b4e                	mv	s6,s3
      state = 0;
 b18:	4981                	li	s3,0
 b1a:	bdf9                	j	9f8 <vprintf+0x60>
          s = "(null)";
 b1c:	00000917          	auipc	s2,0x0
 b20:	55c90913          	addi	s2,s2,1372 # 1078 <malloc+0x416>
        while(*s != 0){
 b24:	02800593          	li	a1,40
 b28:	bff1                	j	b04 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 b2a:	008b0913          	addi	s2,s6,8
 b2e:	000b4583          	lbu	a1,0(s6)
 b32:	8556                	mv	a0,s5
 b34:	00000097          	auipc	ra,0x0
 b38:	d98080e7          	jalr	-616(ra) # 8cc <putc>
 b3c:	8b4a                	mv	s6,s2
      state = 0;
 b3e:	4981                	li	s3,0
 b40:	bd65                	j	9f8 <vprintf+0x60>
        putc(fd, c);
 b42:	85d2                	mv	a1,s4
 b44:	8556                	mv	a0,s5
 b46:	00000097          	auipc	ra,0x0
 b4a:	d86080e7          	jalr	-634(ra) # 8cc <putc>
      state = 0;
 b4e:	4981                	li	s3,0
 b50:	b565                	j	9f8 <vprintf+0x60>
        s = va_arg(ap, char*);
 b52:	8b4e                	mv	s6,s3
      state = 0;
 b54:	4981                	li	s3,0
 b56:	b54d                	j	9f8 <vprintf+0x60>
    }
  }
}
 b58:	70e6                	ld	ra,120(sp)
 b5a:	7446                	ld	s0,112(sp)
 b5c:	74a6                	ld	s1,104(sp)
 b5e:	7906                	ld	s2,96(sp)
 b60:	69e6                	ld	s3,88(sp)
 b62:	6a46                	ld	s4,80(sp)
 b64:	6aa6                	ld	s5,72(sp)
 b66:	6b06                	ld	s6,64(sp)
 b68:	7be2                	ld	s7,56(sp)
 b6a:	7c42                	ld	s8,48(sp)
 b6c:	7ca2                	ld	s9,40(sp)
 b6e:	7d02                	ld	s10,32(sp)
 b70:	6de2                	ld	s11,24(sp)
 b72:	6109                	addi	sp,sp,128
 b74:	8082                	ret

0000000000000b76 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b76:	715d                	addi	sp,sp,-80
 b78:	ec06                	sd	ra,24(sp)
 b7a:	e822                	sd	s0,16(sp)
 b7c:	1000                	addi	s0,sp,32
 b7e:	e010                	sd	a2,0(s0)
 b80:	e414                	sd	a3,8(s0)
 b82:	e818                	sd	a4,16(s0)
 b84:	ec1c                	sd	a5,24(s0)
 b86:	03043023          	sd	a6,32(s0)
 b8a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b8e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b92:	8622                	mv	a2,s0
 b94:	00000097          	auipc	ra,0x0
 b98:	e04080e7          	jalr	-508(ra) # 998 <vprintf>
}
 b9c:	60e2                	ld	ra,24(sp)
 b9e:	6442                	ld	s0,16(sp)
 ba0:	6161                	addi	sp,sp,80
 ba2:	8082                	ret

0000000000000ba4 <printf>:

void
printf(const char *fmt, ...)
{
 ba4:	711d                	addi	sp,sp,-96
 ba6:	ec06                	sd	ra,24(sp)
 ba8:	e822                	sd	s0,16(sp)
 baa:	1000                	addi	s0,sp,32
 bac:	e40c                	sd	a1,8(s0)
 bae:	e810                	sd	a2,16(s0)
 bb0:	ec14                	sd	a3,24(s0)
 bb2:	f018                	sd	a4,32(s0)
 bb4:	f41c                	sd	a5,40(s0)
 bb6:	03043823          	sd	a6,48(s0)
 bba:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 bbe:	00840613          	addi	a2,s0,8
 bc2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 bc6:	85aa                	mv	a1,a0
 bc8:	4505                	li	a0,1
 bca:	00000097          	auipc	ra,0x0
 bce:	dce080e7          	jalr	-562(ra) # 998 <vprintf>
}
 bd2:	60e2                	ld	ra,24(sp)
 bd4:	6442                	ld	s0,16(sp)
 bd6:	6125                	addi	sp,sp,96
 bd8:	8082                	ret

0000000000000bda <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 bda:	1141                	addi	sp,sp,-16
 bdc:	e422                	sd	s0,8(sp)
 bde:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 be0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 be4:	00001797          	auipc	a5,0x1
 be8:	4247b783          	ld	a5,1060(a5) # 2008 <freep>
 bec:	a805                	j	c1c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 bee:	4618                	lw	a4,8(a2)
 bf0:	9db9                	addw	a1,a1,a4
 bf2:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 bf6:	6398                	ld	a4,0(a5)
 bf8:	6318                	ld	a4,0(a4)
 bfa:	fee53823          	sd	a4,-16(a0)
 bfe:	a091                	j	c42 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 c00:	ff852703          	lw	a4,-8(a0)
 c04:	9e39                	addw	a2,a2,a4
 c06:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 c08:	ff053703          	ld	a4,-16(a0)
 c0c:	e398                	sd	a4,0(a5)
 c0e:	a099                	j	c54 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c10:	6398                	ld	a4,0(a5)
 c12:	00e7e463          	bltu	a5,a4,c1a <free+0x40>
 c16:	00e6ea63          	bltu	a3,a4,c2a <free+0x50>
{
 c1a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 c1c:	fed7fae3          	bgeu	a5,a3,c10 <free+0x36>
 c20:	6398                	ld	a4,0(a5)
 c22:	00e6e463          	bltu	a3,a4,c2a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c26:	fee7eae3          	bltu	a5,a4,c1a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 c2a:	ff852583          	lw	a1,-8(a0)
 c2e:	6390                	ld	a2,0(a5)
 c30:	02059713          	slli	a4,a1,0x20
 c34:	9301                	srli	a4,a4,0x20
 c36:	0712                	slli	a4,a4,0x4
 c38:	9736                	add	a4,a4,a3
 c3a:	fae60ae3          	beq	a2,a4,bee <free+0x14>
    bp->s.ptr = p->s.ptr;
 c3e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c42:	4790                	lw	a2,8(a5)
 c44:	02061713          	slli	a4,a2,0x20
 c48:	9301                	srli	a4,a4,0x20
 c4a:	0712                	slli	a4,a4,0x4
 c4c:	973e                	add	a4,a4,a5
 c4e:	fae689e3          	beq	a3,a4,c00 <free+0x26>
  } else
    p->s.ptr = bp;
 c52:	e394                	sd	a3,0(a5)
  freep = p;
 c54:	00001717          	auipc	a4,0x1
 c58:	3af73a23          	sd	a5,948(a4) # 2008 <freep>
}
 c5c:	6422                	ld	s0,8(sp)
 c5e:	0141                	addi	sp,sp,16
 c60:	8082                	ret

0000000000000c62 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c62:	7139                	addi	sp,sp,-64
 c64:	fc06                	sd	ra,56(sp)
 c66:	f822                	sd	s0,48(sp)
 c68:	f426                	sd	s1,40(sp)
 c6a:	f04a                	sd	s2,32(sp)
 c6c:	ec4e                	sd	s3,24(sp)
 c6e:	e852                	sd	s4,16(sp)
 c70:	e456                	sd	s5,8(sp)
 c72:	e05a                	sd	s6,0(sp)
 c74:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c76:	02051493          	slli	s1,a0,0x20
 c7a:	9081                	srli	s1,s1,0x20
 c7c:	04bd                	addi	s1,s1,15
 c7e:	8091                	srli	s1,s1,0x4
 c80:	0014899b          	addiw	s3,s1,1
 c84:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c86:	00001517          	auipc	a0,0x1
 c8a:	38253503          	ld	a0,898(a0) # 2008 <freep>
 c8e:	c515                	beqz	a0,cba <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c90:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c92:	4798                	lw	a4,8(a5)
 c94:	02977f63          	bgeu	a4,s1,cd2 <malloc+0x70>
 c98:	8a4e                	mv	s4,s3
 c9a:	0009871b          	sext.w	a4,s3
 c9e:	6685                	lui	a3,0x1
 ca0:	00d77363          	bgeu	a4,a3,ca6 <malloc+0x44>
 ca4:	6a05                	lui	s4,0x1
 ca6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 caa:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 cae:	00001917          	auipc	s2,0x1
 cb2:	35a90913          	addi	s2,s2,858 # 2008 <freep>
  if(p == (char*)-1)
 cb6:	5afd                	li	s5,-1
 cb8:	a88d                	j	d2a <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 cba:	04001797          	auipc	a5,0x4001
 cbe:	35678793          	addi	a5,a5,854 # 4002010 <base>
 cc2:	00001717          	auipc	a4,0x1
 cc6:	34f73323          	sd	a5,838(a4) # 2008 <freep>
 cca:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 ccc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 cd0:	b7e1                	j	c98 <malloc+0x36>
      if(p->s.size == nunits)
 cd2:	02e48b63          	beq	s1,a4,d08 <malloc+0xa6>
        p->s.size -= nunits;
 cd6:	4137073b          	subw	a4,a4,s3
 cda:	c798                	sw	a4,8(a5)
        p += p->s.size;
 cdc:	1702                	slli	a4,a4,0x20
 cde:	9301                	srli	a4,a4,0x20
 ce0:	0712                	slli	a4,a4,0x4
 ce2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ce4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ce8:	00001717          	auipc	a4,0x1
 cec:	32a73023          	sd	a0,800(a4) # 2008 <freep>
      return (void*)(p + 1);
 cf0:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 cf4:	70e2                	ld	ra,56(sp)
 cf6:	7442                	ld	s0,48(sp)
 cf8:	74a2                	ld	s1,40(sp)
 cfa:	7902                	ld	s2,32(sp)
 cfc:	69e2                	ld	s3,24(sp)
 cfe:	6a42                	ld	s4,16(sp)
 d00:	6aa2                	ld	s5,8(sp)
 d02:	6b02                	ld	s6,0(sp)
 d04:	6121                	addi	sp,sp,64
 d06:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 d08:	6398                	ld	a4,0(a5)
 d0a:	e118                	sd	a4,0(a0)
 d0c:	bff1                	j	ce8 <malloc+0x86>
  hp->s.size = nu;
 d0e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 d12:	0541                	addi	a0,a0,16
 d14:	00000097          	auipc	ra,0x0
 d18:	ec6080e7          	jalr	-314(ra) # bda <free>
  return freep;
 d1c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 d20:	d971                	beqz	a0,cf4 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 d22:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 d24:	4798                	lw	a4,8(a5)
 d26:	fa9776e3          	bgeu	a4,s1,cd2 <malloc+0x70>
    if(p == freep)
 d2a:	00093703          	ld	a4,0(s2)
 d2e:	853e                	mv	a0,a5
 d30:	fef719e3          	bne	a4,a5,d22 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 d34:	8552                	mv	a0,s4
 d36:	00000097          	auipc	ra,0x0
 d3a:	b56080e7          	jalr	-1194(ra) # 88c <sbrk>
  if(p == (char*)-1)
 d3e:	fd5518e3          	bne	a0,s5,d0e <malloc+0xac>
        return 0;
 d42:	4501                	li	a0,0
 d44:	bf45                	j	cf4 <malloc+0x92>
