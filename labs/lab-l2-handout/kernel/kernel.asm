
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b5010113          	addi	sp,sp,-1200 # 80008b50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9c070713          	addi	a4,a4,-1600 # 80008a10 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	08e78793          	addi	a5,a5,142 # 800060f0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc77f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	718080e7          	jalr	1816(ra) # 80002842 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000180:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	9cc50513          	addi	a0,a0,-1588 # 80010b50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	9bc48493          	addi	s1,s1,-1604 # 80010b50 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	a4c90913          	addi	s2,s2,-1460 # 80010be8 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	ac8080e7          	jalr	-1336(ra) # 80001c7c <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	4d0080e7          	jalr	1232(ra) # 8000268c <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	21a080e7          	jalr	538(ra) # 800023e4 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	97270713          	addi	a4,a4,-1678 # 80010b50 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

        if (c == C('D'))
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5dc080e7          	jalr	1500(ra) # 800027ec <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
            break;

        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1

        if (c == '\n')
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	92850513          	addi	a0,a0,-1752 # 80010b50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	91250513          	addi	a0,a0,-1774 # 80010b50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
                return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
            if (n < target)
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
                cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	96f72d23          	sw	a5,-1670(a4) # 80010be8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
        uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	88850513          	addi	a0,a0,-1912 # 80010b50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

    switch (c)
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	5aa080e7          	jalr	1450(ra) # 80002898 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	85a50513          	addi	a0,a0,-1958 # 80010b50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
    switch (c)
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	83670713          	addi	a4,a4,-1994 # 80010b50 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
            consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	80c78793          	addi	a5,a5,-2036 # 80010b50 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8767a783          	lw	a5,-1930(a5) # 80010be8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	7ca70713          	addi	a4,a4,1994 # 80010b50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	7ba48493          	addi	s1,s1,1978 # 80010b50 <cons>
        while (cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
        while (cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	77e70713          	addi	a4,a4,1918 # 80010b50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	80f72423          	sw	a5,-2040(a4) # 80010bf0 <cons+0xa0>
            consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
            consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	74278793          	addi	a5,a5,1858 # 80010b50 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	7ac7ad23          	sw	a2,1978(a5) # 80010bec <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	7ae50513          	addi	a0,a0,1966 # 80010be8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	006080e7          	jalr	6(ra) # 80002448 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	6f450513          	addi	a0,a0,1780 # 80010b50 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	a7478793          	addi	a5,a5,-1420 # 80020ee8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	6c07a423          	sw	zero,1736(a5) # 80010c10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	44f72a23          	sw	a5,1108(a4) # 800089d0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	658dad83          	lw	s11,1624(s11) # 80010c10 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	60250513          	addi	a0,a0,1538 # 80010bf8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	4a450513          	addi	a0,a0,1188 # 80010bf8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	48848493          	addi	s1,s1,1160 # 80010bf8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	44850513          	addi	a0,a0,1096 # 80010c18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	1d47a783          	lw	a5,468(a5) # 800089d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	1a47b783          	ld	a5,420(a5) # 800089d8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	1a473703          	ld	a4,420(a4) # 800089e0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	3baa0a13          	addi	s4,s4,954 # 80010c18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	17248493          	addi	s1,s1,370 # 800089d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	17298993          	addi	s3,s3,370 # 800089e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	bb8080e7          	jalr	-1096(ra) # 80002448 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	34c50513          	addi	a0,a0,844 # 80010c18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0f47a783          	lw	a5,244(a5) # 800089d0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	0fa73703          	ld	a4,250(a4) # 800089e0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	0ea7b783          	ld	a5,234(a5) # 800089d8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	31e98993          	addi	s3,s3,798 # 80010c18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	0d648493          	addi	s1,s1,214 # 800089d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	0d690913          	addi	s2,s2,214 # 800089e0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	aca080e7          	jalr	-1334(ra) # 800023e4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	2e848493          	addi	s1,s1,744 # 80010c18 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	08e7be23          	sd	a4,156(a5) # 800089e0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	26248493          	addi	s1,s1,610 # 80010c18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	68878793          	addi	a5,a5,1672 # 80022080 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	23890913          	addi	s2,s2,568 # 80010c50 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	19a50513          	addi	a0,a0,410 # 80010c50 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	5b650513          	addi	a0,a0,1462 # 80022080 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	16448493          	addi	s1,s1,356 # 80010c50 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	14c50513          	addi	a0,a0,332 # 80010c50 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	12050513          	addi	a0,a0,288 # 80010c50 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	0f4080e7          	jalr	244(ra) # 80001c60 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	0c2080e7          	jalr	194(ra) # 80001c60 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	0b6080e7          	jalr	182(ra) # 80001c60 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	09e080e7          	jalr	158(ra) # 80001c60 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	05e080e7          	jalr	94(ra) # 80001c60 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	addi	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	032080e7          	jalr	50(ra) # 80001c60 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	addi	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	addi	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	addi	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	slli	a2,a2,0x20
    80000d38:	9201                	srli	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	addi	a1,a1,1
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcf81>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	slli	a3,a2,0x20
    80000d5a:	9281                	srli	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addiw	a5,a2,-1
    80000d6a:	1782                	slli	a5,a5,0x20
    80000d6c:	9381                	srli	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	addi	a4,a4,-1
    80000d76:	16fd                	addi	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addiw	a2,a2,-1
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addiw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	addi	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	addi	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	dd6080e7          	jalr	-554(ra) # 80001c50 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	b6670713          	addi	a4,a4,-1178 # 800089e8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	dba080e7          	jalr	-582(ra) # 80001c50 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	cae080e7          	jalr	-850(ra) # 80002b66 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	270080e7          	jalr	624(ra) # 80006130 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	3fa080e7          	jalr	1018(ra) # 800022c2 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	c50080e7          	jalr	-944(ra) # 80001b78 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	c0e080e7          	jalr	-1010(ra) # 80002b3e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	c2e080e7          	jalr	-978(ra) # 80002b66 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	1da080e7          	jalr	474(ra) # 8000611a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	1e8080e7          	jalr	488(ra) # 80006130 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3e6080e7          	jalr	998(ra) # 80003336 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a84080e7          	jalr	-1404(ra) # 800039dc <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	9fa080e7          	jalr	-1542(ra) # 8000495a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	2d0080e7          	jalr	720(ra) # 80006238 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	fe4080e7          	jalr	-28(ra) # 80001f54 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	a6f72523          	sw	a5,-1430(a4) # 800089e8 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	a5e7b783          	ld	a5,-1442(a5) # 800089f0 <kernel_pagetable>
    80000f9a:	83b1                	srli	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	slli	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	addi	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	addi	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srli	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	addi	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srli	a5,s1,0xc
    80001006:	07aa                	slli	a5,a5,0xa
    80001008:	0017e793          	ori	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcf77>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	andi	s2,s2,511
    8000101e:	090e                	slli	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	andi	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srli	s1,s1,0xa
    8000102e:	04b2                	slli	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srli	a0,s3,0xc
    80001036:	1ff57513          	andi	a0,a0,511
    8000103a:	050e                	slli	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	addi	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srli	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	addi	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	andi	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	addi	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srli	a5,a5,0xa
    8000108e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	addi	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	addi	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	andi	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srli	s1,s1,0xc
    800010e8:	04aa                	slli	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	ori	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	addi	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	addi	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	addi	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	addi	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	addi	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	addi	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	addi	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	addi	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	addi	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	addi	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	slli	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	slli	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	addi	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	slli	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00001097          	auipc	ra,0x1
    8000122c:	8ba080e7          	jalr	-1862(ra) # 80001ae2 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	addi	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	addi	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	7aa7b123          	sd	a0,1954(a5) # 800089f0 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	addi	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	addi	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	slli	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	slli	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	addi	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	addi	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	addi	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	addi	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	addi	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	andi	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	andi	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	slli	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	addi	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	addi	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	addi	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	addi	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	addi	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	addi	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	addi	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	addi	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	addi	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	addi	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	addi	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	addi	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	slli	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	addi	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	andi	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	andi	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	addi	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	addi	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	addi	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	addi	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srli	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	addi	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	addi	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	andi	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srli	a1,a4,0xa
    8000159e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	addi	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	addi	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srli	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	addi	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	addi	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	andi	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	addi	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	addi	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	addi	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	addi	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	addi	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	addi	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	addi	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addiw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	addi	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcf80>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	addi	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001830:	7139                	addi	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80001844:	8792                	mv	a5,tp
    int id = r_tp();
    80001846:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001848:	0000fa97          	auipc	s5,0xf
    8000184c:	428a8a93          	addi	s5,s5,1064 # 80010c70 <cpus>
    80001850:	00779713          	slli	a4,a5,0x7
    80001854:	00ea86b3          	add	a3,s5,a4
    80001858:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdcf80>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000185c:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001860:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001864:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001868:	0721                	addi	a4,a4,8
    8000186a:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000186c:	00010497          	auipc	s1,0x10
    80001870:	83448493          	addi	s1,s1,-1996 # 800110a0 <proc>
        if (p->state == RUNNABLE)
    80001874:	498d                	li	s3,3
            p->state = RUNNING;
    80001876:	4b11                	li	s6,4
            c->proc = p;
    80001878:	079e                	slli	a5,a5,0x7
    8000187a:	0000fa17          	auipc	s4,0xf
    8000187e:	3f6a0a13          	addi	s4,s4,1014 # 80010c70 <cpus>
    80001882:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001884:	00015917          	auipc	s2,0x15
    80001888:	41c90913          	addi	s2,s2,1052 # 80016ca0 <tickslock>
    8000188c:	a811                	j	800018a0 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    8000188e:	8526                	mv	a0,s1
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	3f6080e7          	jalr	1014(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001898:	17048493          	addi	s1,s1,368
    8000189c:	03248863          	beq	s1,s2,800018cc <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018a0:	8526                	mv	a0,s1
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	330080e7          	jalr	816(ra) # 80000bd2 <acquire>
        if (p->state == RUNNABLE)
    800018aa:	4c9c                	lw	a5,24(s1)
    800018ac:	ff3791e3          	bne	a5,s3,8000188e <rr_scheduler+0x5e>
            p->state = RUNNING;
    800018b0:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018b4:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018b8:	06848593          	addi	a1,s1,104
    800018bc:	8556                	mv	a0,s5
    800018be:	00001097          	auipc	ra,0x1
    800018c2:	216080e7          	jalr	534(ra) # 80002ad4 <swtch>
            c->proc = 0;
    800018c6:	000a3023          	sd	zero,0(s4)
    800018ca:	b7d1                	j	8000188e <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018cc:	70e2                	ld	ra,56(sp)
    800018ce:	7442                	ld	s0,48(sp)
    800018d0:	74a2                	ld	s1,40(sp)
    800018d2:	7902                	ld	s2,32(sp)
    800018d4:	69e2                	ld	s3,24(sp)
    800018d6:	6a42                	ld	s4,16(sp)
    800018d8:	6aa2                	ld	s5,8(sp)
    800018da:	6b02                	ld	s6,0(sp)
    800018dc:	6121                	addi	sp,sp,64
    800018de:	8082                	ret

00000000800018e0 <mlfq_scheduler>:
int ticksize1 = 3;
int ticksize2 = 6;
int ticksize3 = 9;

void mlfq_scheduler(void)
{
    800018e0:	711d                	addi	sp,sp,-96
    800018e2:	ec86                	sd	ra,88(sp)
    800018e4:	e8a2                	sd	s0,80(sp)
    800018e6:	e4a6                	sd	s1,72(sp)
    800018e8:	e0ca                	sd	s2,64(sp)
    800018ea:	fc4e                	sd	s3,56(sp)
    800018ec:	f852                	sd	s4,48(sp)
    800018ee:	f456                	sd	s5,40(sp)
    800018f0:	f05a                	sd	s6,32(sp)
    800018f2:	ec5e                	sd	s7,24(sp)
    800018f4:	e862                	sd	s8,16(sp)
    800018f6:	e466                	sd	s9,8(sp)
    800018f8:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    800018fa:	8a92                	mv	s5,tp
    int id = r_tp();
    800018fc:	2a81                	sext.w	s5,s5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    800018fe:	0000fa17          	auipc	s4,0xf
    80001902:	372a0a13          	addi	s4,s4,882 # 80010c70 <cpus>
    80001906:	007a9793          	slli	a5,s5,0x7
    8000190a:	00fa0733          	add	a4,s4,a5
    8000190e:	00073023          	sd	zero,0(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001912:	10002773          	csrr	a4,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001916:	00276713          	ori	a4,a4,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000191a:	10071073          	csrw	sstatus,a4
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    8000191e:	07a1                	addi	a5,a5,8
    80001920:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++) {
    80001922:	0000f497          	auipc	s1,0xf
    80001926:	77e48493          	addi	s1,s1,1918 # 800110a0 <proc>
        if (p->state == RUNNABLE && p->priority == 1) {
    8000192a:	498d                	li	s3,3
    8000192c:	4b05                	li	s6,1
            p->state = RUNNING;
    8000192e:	4c91                	li	s9,4
            c->proc = p;
    80001930:	007a9793          	slli	a5,s5,0x7
    80001934:	0000fb97          	auipc	s7,0xf
    80001938:	33cb8b93          	addi	s7,s7,828 # 80010c70 <cpus>
    8000193c:	9bbe                	add	s7,s7,a5
            p->runticks += 1;
            if (p->runticks == ticksize1) {
    8000193e:	00007c17          	auipc	s8,0x7
    80001942:	ffec0c13          	addi	s8,s8,-2 # 8000893c <ticksize1>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001946:	00015917          	auipc	s2,0x15
    8000194a:	35a90913          	addi	s2,s2,858 # 80016ca0 <tickslock>
    8000194e:	a821                	j	80001966 <mlfq_scheduler+0x86>
                p->runticks = 0;
                p->priority = 2;
            // Process is done running for now.
            // It should have changed its p->state before coming back.
            }
            c->proc = 0;
    80001950:	000bb023          	sd	zero,0(s7)
        }
        release(&p->lock);
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	330080e7          	jalr	816(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000195e:	17048493          	addi	s1,s1,368
    80001962:	05248663          	beq	s1,s2,800019ae <mlfq_scheduler+0xce>
        acquire(&p->lock);  
    80001966:	8526                	mv	a0,s1
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	26a080e7          	jalr	618(ra) # 80000bd2 <acquire>
        if (p->state == RUNNABLE && p->priority == 1) {
    80001970:	4c9c                	lw	a5,24(s1)
    80001972:	ff3791e3          	bne	a5,s3,80001954 <mlfq_scheduler+0x74>
    80001976:	5c9c                	lw	a5,56(s1)
    80001978:	fd679ee3          	bne	a5,s6,80001954 <mlfq_scheduler+0x74>
            p->state = RUNNING;
    8000197c:	0194ac23          	sw	s9,24(s1)
            c->proc = p;
    80001980:	009bb023          	sd	s1,0(s7)
            swtch(&c->context, &p->context);
    80001984:	06848593          	addi	a1,s1,104
    80001988:	8552                	mv	a0,s4
    8000198a:	00001097          	auipc	ra,0x1
    8000198e:	14a080e7          	jalr	330(ra) # 80002ad4 <swtch>
            p->runticks += 1;
    80001992:	58dc                	lw	a5,52(s1)
    80001994:	2785                	addiw	a5,a5,1
    80001996:	0007871b          	sext.w	a4,a5
    8000199a:	d8dc                	sw	a5,52(s1)
            if (p->runticks == ticksize1) {
    8000199c:	000c2783          	lw	a5,0(s8)
    800019a0:	fae798e3          	bne	a5,a4,80001950 <mlfq_scheduler+0x70>
                p->runticks = 0;
    800019a4:	0204aa23          	sw	zero,52(s1)
                p->priority = 2;
    800019a8:	4789                	li	a5,2
    800019aa:	dc9c                	sw	a5,56(s1)
    800019ac:	b755                	j	80001950 <mlfq_scheduler+0x70>
    }
    for (p = proc; p < &proc[NPROC]; p++) {
    800019ae:	0000f497          	auipc	s1,0xf
    800019b2:	6f248493          	addi	s1,s1,1778 # 800110a0 <proc>
        acquire(&p->lock);  
        if (p->state == RUNNABLE && p->priority == 2) {
    800019b6:	490d                	li	s2,3
    800019b8:	4b09                	li	s6,2
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
    800019ba:	4c91                	li	s9,4
            c->proc = p;
    800019bc:	007a9793          	slli	a5,s5,0x7
    800019c0:	0000fb97          	auipc	s7,0xf
    800019c4:	2b0b8b93          	addi	s7,s7,688 # 80010c70 <cpus>
    800019c8:	9bbe                	add	s7,s7,a5
            swtch(&c->context, &p->context);
            p->runticks += 1;
            if (p->runticks == ticksize2) {
    800019ca:	00007c17          	auipc	s8,0x7
    800019ce:	f6ec0c13          	addi	s8,s8,-146 # 80008938 <ticksize2>
    for (p = proc; p < &proc[NPROC]; p++) {
    800019d2:	00015997          	auipc	s3,0x15
    800019d6:	2ce98993          	addi	s3,s3,718 # 80016ca0 <tickslock>
    800019da:	a821                	j	800019f2 <mlfq_scheduler+0x112>
                p->runticks = 0;
                p->priority = 3;
            // Process is done running for now.
            // It should have changed its p->state before coming back.
            }
            c->proc = 0;
    800019dc:	000bb023          	sd	zero,0(s7)
        }
        release(&p->lock);
    800019e0:	8526                	mv	a0,s1
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	2a4080e7          	jalr	676(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800019ea:	17048493          	addi	s1,s1,368
    800019ee:	05348663          	beq	s1,s3,80001a3a <mlfq_scheduler+0x15a>
        acquire(&p->lock);  
    800019f2:	8526                	mv	a0,s1
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	1de080e7          	jalr	478(ra) # 80000bd2 <acquire>
        if (p->state == RUNNABLE && p->priority == 2) {
    800019fc:	4c9c                	lw	a5,24(s1)
    800019fe:	ff2791e3          	bne	a5,s2,800019e0 <mlfq_scheduler+0x100>
    80001a02:	5c9c                	lw	a5,56(s1)
    80001a04:	fd679ee3          	bne	a5,s6,800019e0 <mlfq_scheduler+0x100>
            p->state = RUNNING;
    80001a08:	0194ac23          	sw	s9,24(s1)
            c->proc = p;
    80001a0c:	009bb023          	sd	s1,0(s7)
            swtch(&c->context, &p->context);
    80001a10:	06848593          	addi	a1,s1,104
    80001a14:	8552                	mv	a0,s4
    80001a16:	00001097          	auipc	ra,0x1
    80001a1a:	0be080e7          	jalr	190(ra) # 80002ad4 <swtch>
            p->runticks += 1;
    80001a1e:	58dc                	lw	a5,52(s1)
    80001a20:	2785                	addiw	a5,a5,1
    80001a22:	0007871b          	sext.w	a4,a5
    80001a26:	d8dc                	sw	a5,52(s1)
            if (p->runticks == ticksize2) {
    80001a28:	000c2783          	lw	a5,0(s8)
    80001a2c:	fae798e3          	bne	a5,a4,800019dc <mlfq_scheduler+0xfc>
                p->runticks = 0;
    80001a30:	0204aa23          	sw	zero,52(s1)
                p->priority = 3;
    80001a34:	0324ac23          	sw	s2,56(s1)
    80001a38:	b755                	j	800019dc <mlfq_scheduler+0xfc>
    }
    for (p = proc; p < &proc[NPROC]; p++) {
    80001a3a:	0000f497          	auipc	s1,0xf
    80001a3e:	66648493          	addi	s1,s1,1638 # 800110a0 <proc>
        acquire(&p->lock);  
        if (p->state == RUNNABLE && p->priority == 3) {
    80001a42:	490d                	li	s2,3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
    80001a44:	4b91                	li	s7,4
            c->proc = p;
    80001a46:	007a9793          	slli	a5,s5,0x7
    80001a4a:	0000fa97          	auipc	s5,0xf
    80001a4e:	226a8a93          	addi	s5,s5,550 # 80010c70 <cpus>
    80001a52:	9abe                	add	s5,s5,a5
            swtch(&c->context, &p->context);
            p->runticks += 1;
            if (p->ctime == ticksize3) {
    80001a54:	00007b17          	auipc	s6,0x7
    80001a58:	ee0b0b13          	addi	s6,s6,-288 # 80008934 <ticksize3>
                p->runticks = 0;
                p->priority = 1;
    80001a5c:	4c05                	li	s8,1
    for (p = proc; p < &proc[NPROC]; p++) {
    80001a5e:	00015997          	auipc	s3,0x15
    80001a62:	24298993          	addi	s3,s3,578 # 80016ca0 <tickslock>
    80001a66:	a821                	j	80001a7e <mlfq_scheduler+0x19e>
                p->ctime = 0;
            // Process is done running for now.
            // It should have changed its p->state before coming back.
            }
            c->proc = 0;
    80001a68:	000ab023          	sd	zero,0(s5)
        }
        release(&p->lock);
    80001a6c:	8526                	mv	a0,s1
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	218080e7          	jalr	536(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001a76:	17048493          	addi	s1,s1,368
    80001a7a:	05348763          	beq	s1,s3,80001ac8 <mlfq_scheduler+0x1e8>
        acquire(&p->lock);  
    80001a7e:	8526                	mv	a0,s1
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	152080e7          	jalr	338(ra) # 80000bd2 <acquire>
        if (p->state == RUNNABLE && p->priority == 3) {
    80001a88:	4c9c                	lw	a5,24(s1)
    80001a8a:	ff2791e3          	bne	a5,s2,80001a6c <mlfq_scheduler+0x18c>
    80001a8e:	5c9c                	lw	a5,56(s1)
    80001a90:	fd279ee3          	bne	a5,s2,80001a6c <mlfq_scheduler+0x18c>
            p->state = RUNNING;
    80001a94:	0174ac23          	sw	s7,24(s1)
            c->proc = p;
    80001a98:	009ab023          	sd	s1,0(s5)
            swtch(&c->context, &p->context);
    80001a9c:	06848593          	addi	a1,s1,104
    80001aa0:	8552                	mv	a0,s4
    80001aa2:	00001097          	auipc	ra,0x1
    80001aa6:	032080e7          	jalr	50(ra) # 80002ad4 <swtch>
            p->runticks += 1;
    80001aaa:	58dc                	lw	a5,52(s1)
    80001aac:	2785                	addiw	a5,a5,1
    80001aae:	d8dc                	sw	a5,52(s1)
            if (p->ctime == ticksize3) {
    80001ab0:	5cd8                	lw	a4,60(s1)
    80001ab2:	000b2783          	lw	a5,0(s6)
    80001ab6:	faf719e3          	bne	a4,a5,80001a68 <mlfq_scheduler+0x188>
                p->runticks = 0;
    80001aba:	0204aa23          	sw	zero,52(s1)
                p->priority = 1;
    80001abe:	0384ac23          	sw	s8,56(s1)
                p->ctime = 0;
    80001ac2:	0204ae23          	sw	zero,60(s1)
    80001ac6:	b74d                	j	80001a68 <mlfq_scheduler+0x188>
    }
}
    80001ac8:	60e6                	ld	ra,88(sp)
    80001aca:	6446                	ld	s0,80(sp)
    80001acc:	64a6                	ld	s1,72(sp)
    80001ace:	6906                	ld	s2,64(sp)
    80001ad0:	79e2                	ld	s3,56(sp)
    80001ad2:	7a42                	ld	s4,48(sp)
    80001ad4:	7aa2                	ld	s5,40(sp)
    80001ad6:	7b02                	ld	s6,32(sp)
    80001ad8:	6be2                	ld	s7,24(sp)
    80001ada:	6c42                	ld	s8,16(sp)
    80001adc:	6ca2                	ld	s9,8(sp)
    80001ade:	6125                	addi	sp,sp,96
    80001ae0:	8082                	ret

0000000080001ae2 <proc_mapstacks>:
{
    80001ae2:	7139                	addi	sp,sp,-64
    80001ae4:	fc06                	sd	ra,56(sp)
    80001ae6:	f822                	sd	s0,48(sp)
    80001ae8:	f426                	sd	s1,40(sp)
    80001aea:	f04a                	sd	s2,32(sp)
    80001aec:	ec4e                	sd	s3,24(sp)
    80001aee:	e852                	sd	s4,16(sp)
    80001af0:	e456                	sd	s5,8(sp)
    80001af2:	e05a                	sd	s6,0(sp)
    80001af4:	0080                	addi	s0,sp,64
    80001af6:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001af8:	0000f497          	auipc	s1,0xf
    80001afc:	5a848493          	addi	s1,s1,1448 # 800110a0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b00:	8b26                	mv	s6,s1
    80001b02:	00006a97          	auipc	s5,0x6
    80001b06:	4fea8a93          	addi	s5,s5,1278 # 80008000 <etext>
    80001b0a:	04000937          	lui	s2,0x4000
    80001b0e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b12:	00015a17          	auipc	s4,0x15
    80001b16:	18ea0a13          	addi	s4,s4,398 # 80016ca0 <tickslock>
        char *pa = kalloc();
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	fc8080e7          	jalr	-56(ra) # 80000ae2 <kalloc>
    80001b22:	862a                	mv	a2,a0
        if (pa == 0)
    80001b24:	c131                	beqz	a0,80001b68 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b26:	416485b3          	sub	a1,s1,s6
    80001b2a:	8591                	srai	a1,a1,0x4
    80001b2c:	000ab783          	ld	a5,0(s5)
    80001b30:	02f585b3          	mul	a1,a1,a5
    80001b34:	2585                	addiw	a1,a1,1
    80001b36:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b3a:	4719                	li	a4,6
    80001b3c:	6685                	lui	a3,0x1
    80001b3e:	40b905b3          	sub	a1,s2,a1
    80001b42:	854e                	mv	a0,s3
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	5f4080e7          	jalr	1524(ra) # 80001138 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b4c:	17048493          	addi	s1,s1,368
    80001b50:	fd4495e3          	bne	s1,s4,80001b1a <proc_mapstacks+0x38>
}
    80001b54:	70e2                	ld	ra,56(sp)
    80001b56:	7442                	ld	s0,48(sp)
    80001b58:	74a2                	ld	s1,40(sp)
    80001b5a:	7902                	ld	s2,32(sp)
    80001b5c:	69e2                	ld	s3,24(sp)
    80001b5e:	6a42                	ld	s4,16(sp)
    80001b60:	6aa2                	ld	s5,8(sp)
    80001b62:	6b02                	ld	s6,0(sp)
    80001b64:	6121                	addi	sp,sp,64
    80001b66:	8082                	ret
            panic("kalloc");
    80001b68:	00006517          	auipc	a0,0x6
    80001b6c:	67050513          	addi	a0,a0,1648 # 800081d8 <digits+0x198>
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	9cc080e7          	jalr	-1588(ra) # 8000053c <panic>

0000000080001b78 <procinit>:
{
    80001b78:	7139                	addi	sp,sp,-64
    80001b7a:	fc06                	sd	ra,56(sp)
    80001b7c:	f822                	sd	s0,48(sp)
    80001b7e:	f426                	sd	s1,40(sp)
    80001b80:	f04a                	sd	s2,32(sp)
    80001b82:	ec4e                	sd	s3,24(sp)
    80001b84:	e852                	sd	s4,16(sp)
    80001b86:	e456                	sd	s5,8(sp)
    80001b88:	e05a                	sd	s6,0(sp)
    80001b8a:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b8c:	00006597          	auipc	a1,0x6
    80001b90:	65458593          	addi	a1,a1,1620 # 800081e0 <digits+0x1a0>
    80001b94:	0000f517          	auipc	a0,0xf
    80001b98:	4dc50513          	addi	a0,a0,1244 # 80011070 <pid_lock>
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	fa6080e7          	jalr	-90(ra) # 80000b42 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001ba4:	00006597          	auipc	a1,0x6
    80001ba8:	64458593          	addi	a1,a1,1604 # 800081e8 <digits+0x1a8>
    80001bac:	0000f517          	auipc	a0,0xf
    80001bb0:	4dc50513          	addi	a0,a0,1244 # 80011088 <wait_lock>
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	f8e080e7          	jalr	-114(ra) # 80000b42 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001bbc:	0000f497          	auipc	s1,0xf
    80001bc0:	4e448493          	addi	s1,s1,1252 # 800110a0 <proc>
        initlock(&p->lock, "proc");
    80001bc4:	00006b17          	auipc	s6,0x6
    80001bc8:	634b0b13          	addi	s6,s6,1588 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    80001bcc:	8aa6                	mv	s5,s1
    80001bce:	00006a17          	auipc	s4,0x6
    80001bd2:	432a0a13          	addi	s4,s4,1074 # 80008000 <etext>
    80001bd6:	04000937          	lui	s2,0x4000
    80001bda:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bdc:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001bde:	00015997          	auipc	s3,0x15
    80001be2:	0c298993          	addi	s3,s3,194 # 80016ca0 <tickslock>
        initlock(&p->lock, "proc");
    80001be6:	85da                	mv	a1,s6
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	f58080e7          	jalr	-168(ra) # 80000b42 <initlock>
        p->state = UNUSED;
    80001bf2:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001bf6:	415487b3          	sub	a5,s1,s5
    80001bfa:	8791                	srai	a5,a5,0x4
    80001bfc:	000a3703          	ld	a4,0(s4)
    80001c00:	02e787b3          	mul	a5,a5,a4
    80001c04:	2785                	addiw	a5,a5,1
    80001c06:	00d7979b          	slliw	a5,a5,0xd
    80001c0a:	40f907b3          	sub	a5,s2,a5
    80001c0e:	e4bc                	sd	a5,72(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c10:	17048493          	addi	s1,s1,368
    80001c14:	fd3499e3          	bne	s1,s3,80001be6 <procinit+0x6e>
}
    80001c18:	70e2                	ld	ra,56(sp)
    80001c1a:	7442                	ld	s0,48(sp)
    80001c1c:	74a2                	ld	s1,40(sp)
    80001c1e:	7902                	ld	s2,32(sp)
    80001c20:	69e2                	ld	s3,24(sp)
    80001c22:	6a42                	ld	s4,16(sp)
    80001c24:	6aa2                	ld	s5,8(sp)
    80001c26:	6b02                	ld	s6,0(sp)
    80001c28:	6121                	addi	sp,sp,64
    80001c2a:	8082                	ret

0000000080001c2c <copy_array>:
{
    80001c2c:	1141                	addi	sp,sp,-16
    80001c2e:	e422                	sd	s0,8(sp)
    80001c30:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c32:	00c05c63          	blez	a2,80001c4a <copy_array+0x1e>
    80001c36:	87aa                	mv	a5,a0
    80001c38:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001c3a:	0007c703          	lbu	a4,0(a5)
    80001c3e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c42:	0785                	addi	a5,a5,1
    80001c44:	0585                	addi	a1,a1,1
    80001c46:	fea79ae3          	bne	a5,a0,80001c3a <copy_array+0xe>
}
    80001c4a:	6422                	ld	s0,8(sp)
    80001c4c:	0141                	addi	sp,sp,16
    80001c4e:	8082                	ret

0000000080001c50 <cpuid>:
{
    80001c50:	1141                	addi	sp,sp,-16
    80001c52:	e422                	sd	s0,8(sp)
    80001c54:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c56:	8512                	mv	a0,tp
}
    80001c58:	2501                	sext.w	a0,a0
    80001c5a:	6422                	ld	s0,8(sp)
    80001c5c:	0141                	addi	sp,sp,16
    80001c5e:	8082                	ret

0000000080001c60 <mycpu>:
{
    80001c60:	1141                	addi	sp,sp,-16
    80001c62:	e422                	sd	s0,8(sp)
    80001c64:	0800                	addi	s0,sp,16
    80001c66:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001c68:	2781                	sext.w	a5,a5
    80001c6a:	079e                	slli	a5,a5,0x7
}
    80001c6c:	0000f517          	auipc	a0,0xf
    80001c70:	00450513          	addi	a0,a0,4 # 80010c70 <cpus>
    80001c74:	953e                	add	a0,a0,a5
    80001c76:	6422                	ld	s0,8(sp)
    80001c78:	0141                	addi	sp,sp,16
    80001c7a:	8082                	ret

0000000080001c7c <myproc>:
{
    80001c7c:	1101                	addi	sp,sp,-32
    80001c7e:	ec06                	sd	ra,24(sp)
    80001c80:	e822                	sd	s0,16(sp)
    80001c82:	e426                	sd	s1,8(sp)
    80001c84:	1000                	addi	s0,sp,32
    push_off();
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	f00080e7          	jalr	-256(ra) # 80000b86 <push_off>
    80001c8e:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c90:	2781                	sext.w	a5,a5
    80001c92:	079e                	slli	a5,a5,0x7
    80001c94:	0000f717          	auipc	a4,0xf
    80001c98:	fdc70713          	addi	a4,a4,-36 # 80010c70 <cpus>
    80001c9c:	97ba                	add	a5,a5,a4
    80001c9e:	6384                	ld	s1,0(a5)
    pop_off();
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	f86080e7          	jalr	-122(ra) # 80000c26 <pop_off>
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret

0000000080001cb4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001cb4:	1141                	addi	sp,sp,-16
    80001cb6:	e406                	sd	ra,8(sp)
    80001cb8:	e022                	sd	s0,0(sp)
    80001cba:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	fc0080e7          	jalr	-64(ra) # 80001c7c <myproc>
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fc2080e7          	jalr	-62(ra) # 80000c86 <release>

    if (first)
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	c647a783          	lw	a5,-924(a5) # 80008930 <first.1>
    80001cd4:	eb89                	bnez	a5,80001ce6 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001cd6:	00001097          	auipc	ra,0x1
    80001cda:	ea8080e7          	jalr	-344(ra) # 80002b7e <usertrapret>
}
    80001cde:	60a2                	ld	ra,8(sp)
    80001ce0:	6402                	ld	s0,0(sp)
    80001ce2:	0141                	addi	sp,sp,16
    80001ce4:	8082                	ret
        first = 0;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	c407a523          	sw	zero,-950(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001cee:	4505                	li	a0,1
    80001cf0:	00002097          	auipc	ra,0x2
    80001cf4:	c6c080e7          	jalr	-916(ra) # 8000395c <fsinit>
    80001cf8:	bff9                	j	80001cd6 <forkret+0x22>

0000000080001cfa <allocpid>:
{
    80001cfa:	1101                	addi	sp,sp,-32
    80001cfc:	ec06                	sd	ra,24(sp)
    80001cfe:	e822                	sd	s0,16(sp)
    80001d00:	e426                	sd	s1,8(sp)
    80001d02:	e04a                	sd	s2,0(sp)
    80001d04:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d06:	0000f917          	auipc	s2,0xf
    80001d0a:	36a90913          	addi	s2,s2,874 # 80011070 <pid_lock>
    80001d0e:	854a                	mv	a0,s2
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	ec2080e7          	jalr	-318(ra) # 80000bd2 <acquire>
    pid = nextpid;
    80001d18:	00007797          	auipc	a5,0x7
    80001d1c:	c3078793          	addi	a5,a5,-976 # 80008948 <nextpid>
    80001d20:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d22:	0014871b          	addiw	a4,s1,1
    80001d26:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d28:	854a                	mv	a0,s2
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	f5c080e7          	jalr	-164(ra) # 80000c86 <release>
}
    80001d32:	8526                	mv	a0,s1
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6902                	ld	s2,0(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret

0000000080001d40 <proc_pagetable>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	e04a                	sd	s2,0(sp)
    80001d4a:	1000                	addi	s0,sp,32
    80001d4c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	5d4080e7          	jalr	1492(ra) # 80001322 <uvmcreate>
    80001d56:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d58:	c121                	beqz	a0,80001d98 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d5a:	4729                	li	a4,10
    80001d5c:	00005697          	auipc	a3,0x5
    80001d60:	2a468693          	addi	a3,a3,676 # 80007000 <_trampoline>
    80001d64:	6605                	lui	a2,0x1
    80001d66:	040005b7          	lui	a1,0x4000
    80001d6a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d6c:	05b2                	slli	a1,a1,0xc
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	32a080e7          	jalr	810(ra) # 80001098 <mappages>
    80001d76:	02054863          	bltz	a0,80001da6 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d7a:	4719                	li	a4,6
    80001d7c:	06093683          	ld	a3,96(s2)
    80001d80:	6605                	lui	a2,0x1
    80001d82:	020005b7          	lui	a1,0x2000
    80001d86:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d88:	05b6                	slli	a1,a1,0xd
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	30c080e7          	jalr	780(ra) # 80001098 <mappages>
    80001d94:	02054163          	bltz	a0,80001db6 <proc_pagetable+0x76>
}
    80001d98:	8526                	mv	a0,s1
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6902                	ld	s2,0(sp)
    80001da2:	6105                	addi	sp,sp,32
    80001da4:	8082                	ret
        uvmfree(pagetable, 0);
    80001da6:	4581                	li	a1,0
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	77e080e7          	jalr	1918(ra) # 80001528 <uvmfree>
        return 0;
    80001db2:	4481                	li	s1,0
    80001db4:	b7d5                	j	80001d98 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001db6:	4681                	li	a3,0
    80001db8:	4605                	li	a2,1
    80001dba:	040005b7          	lui	a1,0x4000
    80001dbe:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dc0:	05b2                	slli	a1,a1,0xc
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	49a080e7          	jalr	1178(ra) # 8000125e <uvmunmap>
        uvmfree(pagetable, 0);
    80001dcc:	4581                	li	a1,0
    80001dce:	8526                	mv	a0,s1
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	758080e7          	jalr	1880(ra) # 80001528 <uvmfree>
        return 0;
    80001dd8:	4481                	li	s1,0
    80001dda:	bf7d                	j	80001d98 <proc_pagetable+0x58>

0000000080001ddc <proc_freepagetable>:
{
    80001ddc:	1101                	addi	sp,sp,-32
    80001dde:	ec06                	sd	ra,24(sp)
    80001de0:	e822                	sd	s0,16(sp)
    80001de2:	e426                	sd	s1,8(sp)
    80001de4:	e04a                	sd	s2,0(sp)
    80001de6:	1000                	addi	s0,sp,32
    80001de8:	84aa                	mv	s1,a0
    80001dea:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dec:	4681                	li	a3,0
    80001dee:	4605                	li	a2,1
    80001df0:	040005b7          	lui	a1,0x4000
    80001df4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001df6:	05b2                	slli	a1,a1,0xc
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	466080e7          	jalr	1126(ra) # 8000125e <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e00:	4681                	li	a3,0
    80001e02:	4605                	li	a2,1
    80001e04:	020005b7          	lui	a1,0x2000
    80001e08:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e0a:	05b6                	slli	a1,a1,0xd
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	450080e7          	jalr	1104(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, sz);
    80001e16:	85ca                	mv	a1,s2
    80001e18:	8526                	mv	a0,s1
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	70e080e7          	jalr	1806(ra) # 80001528 <uvmfree>
}
    80001e22:	60e2                	ld	ra,24(sp)
    80001e24:	6442                	ld	s0,16(sp)
    80001e26:	64a2                	ld	s1,8(sp)
    80001e28:	6902                	ld	s2,0(sp)
    80001e2a:	6105                	addi	sp,sp,32
    80001e2c:	8082                	ret

0000000080001e2e <freeproc>:
{
    80001e2e:	1101                	addi	sp,sp,-32
    80001e30:	ec06                	sd	ra,24(sp)
    80001e32:	e822                	sd	s0,16(sp)
    80001e34:	e426                	sd	s1,8(sp)
    80001e36:	1000                	addi	s0,sp,32
    80001e38:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e3a:	7128                	ld	a0,96(a0)
    80001e3c:	c509                	beqz	a0,80001e46 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	ba6080e7          	jalr	-1114(ra) # 800009e4 <kfree>
    p->trapframe = 0;
    80001e46:	0604b023          	sd	zero,96(s1)
    if (p->pagetable)
    80001e4a:	6ca8                	ld	a0,88(s1)
    80001e4c:	c511                	beqz	a0,80001e58 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e4e:	68ac                	ld	a1,80(s1)
    80001e50:	00000097          	auipc	ra,0x0
    80001e54:	f8c080e7          	jalr	-116(ra) # 80001ddc <proc_freepagetable>
    p->pagetable = 0;
    80001e58:	0404bc23          	sd	zero,88(s1)
    p->sz = 0;
    80001e5c:	0404b823          	sd	zero,80(s1)
    p->pid = 0;
    80001e60:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e64:	0404b023          	sd	zero,64(s1)
    p->name[0] = 0;
    80001e68:	16048023          	sb	zero,352(s1)
    p->chan = 0;
    80001e6c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e70:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e74:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e78:	0004ac23          	sw	zero,24(s1)
}
    80001e7c:	60e2                	ld	ra,24(sp)
    80001e7e:	6442                	ld	s0,16(sp)
    80001e80:	64a2                	ld	s1,8(sp)
    80001e82:	6105                	addi	sp,sp,32
    80001e84:	8082                	ret

0000000080001e86 <allocproc>:
{
    80001e86:	1101                	addi	sp,sp,-32
    80001e88:	ec06                	sd	ra,24(sp)
    80001e8a:	e822                	sd	s0,16(sp)
    80001e8c:	e426                	sd	s1,8(sp)
    80001e8e:	e04a                	sd	s2,0(sp)
    80001e90:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e92:	0000f497          	auipc	s1,0xf
    80001e96:	20e48493          	addi	s1,s1,526 # 800110a0 <proc>
    80001e9a:	00015917          	auipc	s2,0x15
    80001e9e:	e0690913          	addi	s2,s2,-506 # 80016ca0 <tickslock>
        acquire(&p->lock);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d2e080e7          	jalr	-722(ra) # 80000bd2 <acquire>
        if (p->state == UNUSED)
    80001eac:	4c9c                	lw	a5,24(s1)
    80001eae:	cf81                	beqz	a5,80001ec6 <allocproc+0x40>
            release(&p->lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dd4080e7          	jalr	-556(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001eba:	17048493          	addi	s1,s1,368
    80001ebe:	ff2492e3          	bne	s1,s2,80001ea2 <allocproc+0x1c>
    return 0;
    80001ec2:	4481                	li	s1,0
    80001ec4:	a889                	j	80001f16 <allocproc+0x90>
    p->pid = allocpid();
    80001ec6:	00000097          	auipc	ra,0x0
    80001eca:	e34080e7          	jalr	-460(ra) # 80001cfa <allocpid>
    80001ece:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001ed0:	4785                	li	a5,1
    80001ed2:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	c0e080e7          	jalr	-1010(ra) # 80000ae2 <kalloc>
    80001edc:	892a                	mv	s2,a0
    80001ede:	f0a8                	sd	a0,96(s1)
    80001ee0:	c131                	beqz	a0,80001f24 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001ee2:	8526                	mv	a0,s1
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	e5c080e7          	jalr	-420(ra) # 80001d40 <proc_pagetable>
    80001eec:	892a                	mv	s2,a0
    80001eee:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    80001ef0:	c531                	beqz	a0,80001f3c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001ef2:	07000613          	li	a2,112
    80001ef6:	4581                	li	a1,0
    80001ef8:	06848513          	addi	a0,s1,104
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	dd2080e7          	jalr	-558(ra) # 80000cce <memset>
    p->context.ra = (uint64)forkret;
    80001f04:	00000797          	auipc	a5,0x0
    80001f08:	db078793          	addi	a5,a5,-592 # 80001cb4 <forkret>
    80001f0c:	f4bc                	sd	a5,104(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f0e:	64bc                	ld	a5,72(s1)
    80001f10:	6705                	lui	a4,0x1
    80001f12:	97ba                	add	a5,a5,a4
    80001f14:	f8bc                	sd	a5,112(s1)
}
    80001f16:	8526                	mv	a0,s1
    80001f18:	60e2                	ld	ra,24(sp)
    80001f1a:	6442                	ld	s0,16(sp)
    80001f1c:	64a2                	ld	s1,8(sp)
    80001f1e:	6902                	ld	s2,0(sp)
    80001f20:	6105                	addi	sp,sp,32
    80001f22:	8082                	ret
        freeproc(p);
    80001f24:	8526                	mv	a0,s1
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	f08080e7          	jalr	-248(ra) # 80001e2e <freeproc>
        release(&p->lock);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	d56080e7          	jalr	-682(ra) # 80000c86 <release>
        return 0;
    80001f38:	84ca                	mv	s1,s2
    80001f3a:	bff1                	j	80001f16 <allocproc+0x90>
        freeproc(p);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	ef0080e7          	jalr	-272(ra) # 80001e2e <freeproc>
        release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d3e080e7          	jalr	-706(ra) # 80000c86 <release>
        return 0;
    80001f50:	84ca                	mv	s1,s2
    80001f52:	b7d1                	j	80001f16 <allocproc+0x90>

0000000080001f54 <userinit>:
{
    80001f54:	1101                	addi	sp,sp,-32
    80001f56:	ec06                	sd	ra,24(sp)
    80001f58:	e822                	sd	s0,16(sp)
    80001f5a:	e426                	sd	s1,8(sp)
    80001f5c:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	f28080e7          	jalr	-216(ra) # 80001e86 <allocproc>
    80001f66:	84aa                	mv	s1,a0
    initproc = p;
    80001f68:	00007797          	auipc	a5,0x7
    80001f6c:	a8a7b823          	sd	a0,-1392(a5) # 800089f8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f70:	03400613          	li	a2,52
    80001f74:	00007597          	auipc	a1,0x7
    80001f78:	9dc58593          	addi	a1,a1,-1572 # 80008950 <initcode>
    80001f7c:	6d28                	ld	a0,88(a0)
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	3d2080e7          	jalr	978(ra) # 80001350 <uvmfirst>
    p->sz = PGSIZE;
    80001f86:	6785                	lui	a5,0x1
    80001f88:	e8bc                	sd	a5,80(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f8a:	70b8                	ld	a4,96(s1)
    80001f8c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f90:	70b8                	ld	a4,96(s1)
    80001f92:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f94:	4641                	li	a2,16
    80001f96:	00006597          	auipc	a1,0x6
    80001f9a:	26a58593          	addi	a1,a1,618 # 80008200 <digits+0x1c0>
    80001f9e:	16048513          	addi	a0,s1,352
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	e74080e7          	jalr	-396(ra) # 80000e16 <safestrcpy>
    p->cwd = namei("/");
    80001faa:	00006517          	auipc	a0,0x6
    80001fae:	26650513          	addi	a0,a0,614 # 80008210 <digits+0x1d0>
    80001fb2:	00002097          	auipc	ra,0x2
    80001fb6:	3c8080e7          	jalr	968(ra) # 8000437a <namei>
    80001fba:	14a4bc23          	sd	a0,344(s1)
    p->state = RUNNABLE;
    80001fbe:	478d                	li	a5,3
    80001fc0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cc2080e7          	jalr	-830(ra) # 80000c86 <release>
}
    80001fcc:	60e2                	ld	ra,24(sp)
    80001fce:	6442                	ld	s0,16(sp)
    80001fd0:	64a2                	ld	s1,8(sp)
    80001fd2:	6105                	addi	sp,sp,32
    80001fd4:	8082                	ret

0000000080001fd6 <growproc>:
{
    80001fd6:	1101                	addi	sp,sp,-32
    80001fd8:	ec06                	sd	ra,24(sp)
    80001fda:	e822                	sd	s0,16(sp)
    80001fdc:	e426                	sd	s1,8(sp)
    80001fde:	e04a                	sd	s2,0(sp)
    80001fe0:	1000                	addi	s0,sp,32
    80001fe2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	c98080e7          	jalr	-872(ra) # 80001c7c <myproc>
    80001fec:	84aa                	mv	s1,a0
    sz = p->sz;
    80001fee:	692c                	ld	a1,80(a0)
    if (n > 0)
    80001ff0:	01204c63          	bgtz	s2,80002008 <growproc+0x32>
    else if (n < 0)
    80001ff4:	02094663          	bltz	s2,80002020 <growproc+0x4a>
    p->sz = sz;
    80001ff8:	e8ac                	sd	a1,80(s1)
    return 0;
    80001ffa:	4501                	li	a0,0
}
    80001ffc:	60e2                	ld	ra,24(sp)
    80001ffe:	6442                	ld	s0,16(sp)
    80002000:	64a2                	ld	s1,8(sp)
    80002002:	6902                	ld	s2,0(sp)
    80002004:	6105                	addi	sp,sp,32
    80002006:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002008:	4691                	li	a3,4
    8000200a:	00b90633          	add	a2,s2,a1
    8000200e:	6d28                	ld	a0,88(a0)
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	3fa080e7          	jalr	1018(ra) # 8000140a <uvmalloc>
    80002018:	85aa                	mv	a1,a0
    8000201a:	fd79                	bnez	a0,80001ff8 <growproc+0x22>
            return -1;
    8000201c:	557d                	li	a0,-1
    8000201e:	bff9                	j	80001ffc <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002020:	00b90633          	add	a2,s2,a1
    80002024:	6d28                	ld	a0,88(a0)
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	39c080e7          	jalr	924(ra) # 800013c2 <uvmdealloc>
    8000202e:	85aa                	mv	a1,a0
    80002030:	b7e1                	j	80001ff8 <growproc+0x22>

0000000080002032 <ps>:
{
    80002032:	715d                	addi	sp,sp,-80
    80002034:	e486                	sd	ra,72(sp)
    80002036:	e0a2                	sd	s0,64(sp)
    80002038:	fc26                	sd	s1,56(sp)
    8000203a:	f84a                	sd	s2,48(sp)
    8000203c:	f44e                	sd	s3,40(sp)
    8000203e:	f052                	sd	s4,32(sp)
    80002040:	ec56                	sd	s5,24(sp)
    80002042:	e85a                	sd	s6,16(sp)
    80002044:	e45e                	sd	s7,8(sp)
    80002046:	e062                	sd	s8,0(sp)
    80002048:	0880                	addi	s0,sp,80
    8000204a:	84aa                	mv	s1,a0
    8000204c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	c2e080e7          	jalr	-978(ra) # 80001c7c <myproc>
    if (count == 0)
    80002056:	120b8063          	beqz	s7,80002176 <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000205a:	05053b03          	ld	s6,80(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    8000205e:	003b951b          	slliw	a0,s7,0x3
    80002062:	0175053b          	addw	a0,a0,s7
    80002066:	0025151b          	slliw	a0,a0,0x2
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	f6c080e7          	jalr	-148(ra) # 80001fd6 <growproc>
    80002072:	10054463          	bltz	a0,8000217a <ps+0x148>
    struct user_proc loc_result[count];
    80002076:	003b9a13          	slli	s4,s7,0x3
    8000207a:	9a5e                	add	s4,s4,s7
    8000207c:	0a0a                	slli	s4,s4,0x2
    8000207e:	00fa0793          	addi	a5,s4,15
    80002082:	8391                	srli	a5,a5,0x4
    80002084:	0792                	slli	a5,a5,0x4
    80002086:	40f10133          	sub	sp,sp,a5
    8000208a:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000208c:	008447b7          	lui	a5,0x844
    80002090:	02f484b3          	mul	s1,s1,a5
    80002094:	0000f797          	auipc	a5,0xf
    80002098:	00c78793          	addi	a5,a5,12 # 800110a0 <proc>
    8000209c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000209e:	00015797          	auipc	a5,0x15
    800020a2:	c0278793          	addi	a5,a5,-1022 # 80016ca0 <tickslock>
    800020a6:	0cf4fc63          	bgeu	s1,a5,8000217e <ps+0x14c>
        if (localCount == count)
    800020aa:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020ae:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020b0:	8c3e                	mv	s8,a5
    800020b2:	a069                	j	8000213c <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800020b4:	00399793          	slli	a5,s3,0x3
    800020b8:	97ce                	add	a5,a5,s3
    800020ba:	078a                	slli	a5,a5,0x2
    800020bc:	97d6                	add	a5,a5,s5
    800020be:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	bc2080e7          	jalr	-1086(ra) # 80000c86 <release>
    if (localCount < count)
    800020cc:	0179f963          	bgeu	s3,s7,800020de <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020d0:	00399793          	slli	a5,s3,0x3
    800020d4:	97ce                	add	a5,a5,s3
    800020d6:	078a                	slli	a5,a5,0x2
    800020d8:	97d6                	add	a5,a5,s5
    800020da:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020de:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	b9c080e7          	jalr	-1124(ra) # 80001c7c <myproc>
    800020e8:	86d2                	mv	a3,s4
    800020ea:	8656                	mv	a2,s5
    800020ec:	85da                	mv	a1,s6
    800020ee:	6d28                	ld	a0,88(a0)
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	576080e7          	jalr	1398(ra) # 80001666 <copyout>
}
    800020f8:	8526                	mv	a0,s1
    800020fa:	fb040113          	addi	sp,s0,-80
    800020fe:	60a6                	ld	ra,72(sp)
    80002100:	6406                	ld	s0,64(sp)
    80002102:	74e2                	ld	s1,56(sp)
    80002104:	7942                	ld	s2,48(sp)
    80002106:	79a2                	ld	s3,40(sp)
    80002108:	7a02                	ld	s4,32(sp)
    8000210a:	6ae2                	ld	s5,24(sp)
    8000210c:	6b42                	ld	s6,16(sp)
    8000210e:	6ba2                	ld	s7,8(sp)
    80002110:	6c02                	ld	s8,0(sp)
    80002112:	6161                	addi	sp,sp,80
    80002114:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002116:	5b9c                	lw	a5,48(a5)
    80002118:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b68080e7          	jalr	-1176(ra) # 80000c86 <release>
        localCount++;
    80002126:	2985                	addiw	s3,s3,1
    80002128:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000212c:	17048493          	addi	s1,s1,368
    80002130:	f984fee3          	bgeu	s1,s8,800020cc <ps+0x9a>
        if (localCount == count)
    80002134:	02490913          	addi	s2,s2,36
    80002138:	fb3b83e3          	beq	s7,s3,800020de <ps+0xac>
        acquire(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	a94080e7          	jalr	-1388(ra) # 80000bd2 <acquire>
        if (p->state == UNUSED)
    80002146:	4c9c                	lw	a5,24(s1)
    80002148:	d7b5                	beqz	a5,800020b4 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000214a:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000214e:	549c                	lw	a5,40(s1)
    80002150:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002154:	54dc                	lw	a5,44(s1)
    80002156:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000215a:	589c                	lw	a5,48(s1)
    8000215c:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002160:	4641                	li	a2,16
    80002162:	85ca                	mv	a1,s2
    80002164:	16048513          	addi	a0,s1,352
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	ac4080e7          	jalr	-1340(ra) # 80001c2c <copy_array>
        if (p->parent != 0) // init
    80002170:	60bc                	ld	a5,64(s1)
    80002172:	f3d5                	bnez	a5,80002116 <ps+0xe4>
    80002174:	b765                	j	8000211c <ps+0xea>
        return result;
    80002176:	4481                	li	s1,0
    80002178:	b741                	j	800020f8 <ps+0xc6>
        return result;
    8000217a:	4481                	li	s1,0
    8000217c:	bfb5                	j	800020f8 <ps+0xc6>
        return result;
    8000217e:	4481                	li	s1,0
    80002180:	bfa5                	j	800020f8 <ps+0xc6>

0000000080002182 <fork>:
{
    80002182:	7139                	addi	sp,sp,-64
    80002184:	fc06                	sd	ra,56(sp)
    80002186:	f822                	sd	s0,48(sp)
    80002188:	f426                	sd	s1,40(sp)
    8000218a:	f04a                	sd	s2,32(sp)
    8000218c:	ec4e                	sd	s3,24(sp)
    8000218e:	e852                	sd	s4,16(sp)
    80002190:	e456                	sd	s5,8(sp)
    80002192:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	ae8080e7          	jalr	-1304(ra) # 80001c7c <myproc>
    8000219c:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	ce8080e7          	jalr	-792(ra) # 80001e86 <allocproc>
    800021a6:	10050c63          	beqz	a0,800022be <fork+0x13c>
    800021aa:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021ac:	050ab603          	ld	a2,80(s5)
    800021b0:	6d2c                	ld	a1,88(a0)
    800021b2:	058ab503          	ld	a0,88(s5)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	3ac080e7          	jalr	940(ra) # 80001562 <uvmcopy>
    800021be:	04054863          	bltz	a0,8000220e <fork+0x8c>
    np->sz = p->sz;
    800021c2:	050ab783          	ld	a5,80(s5)
    800021c6:	04fa3823          	sd	a5,80(s4)
    *(np->trapframe) = *(p->trapframe);
    800021ca:	060ab683          	ld	a3,96(s5)
    800021ce:	87b6                	mv	a5,a3
    800021d0:	060a3703          	ld	a4,96(s4)
    800021d4:	12068693          	addi	a3,a3,288
    800021d8:	0007b803          	ld	a6,0(a5)
    800021dc:	6788                	ld	a0,8(a5)
    800021de:	6b8c                	ld	a1,16(a5)
    800021e0:	6f90                	ld	a2,24(a5)
    800021e2:	01073023          	sd	a6,0(a4)
    800021e6:	e708                	sd	a0,8(a4)
    800021e8:	eb0c                	sd	a1,16(a4)
    800021ea:	ef10                	sd	a2,24(a4)
    800021ec:	02078793          	addi	a5,a5,32
    800021f0:	02070713          	addi	a4,a4,32
    800021f4:	fed792e3          	bne	a5,a3,800021d8 <fork+0x56>
    np->trapframe->a0 = 0;
    800021f8:	060a3783          	ld	a5,96(s4)
    800021fc:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002200:	0d8a8493          	addi	s1,s5,216
    80002204:	0d8a0913          	addi	s2,s4,216
    80002208:	158a8993          	addi	s3,s5,344
    8000220c:	a00d                	j	8000222e <fork+0xac>
        freeproc(np);
    8000220e:	8552                	mv	a0,s4
    80002210:	00000097          	auipc	ra,0x0
    80002214:	c1e080e7          	jalr	-994(ra) # 80001e2e <freeproc>
        release(&np->lock);
    80002218:	8552                	mv	a0,s4
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a6c080e7          	jalr	-1428(ra) # 80000c86 <release>
        return -1;
    80002222:	597d                	li	s2,-1
    80002224:	a059                	j	800022aa <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002226:	04a1                	addi	s1,s1,8
    80002228:	0921                	addi	s2,s2,8
    8000222a:	01348b63          	beq	s1,s3,80002240 <fork+0xbe>
        if (p->ofile[i])
    8000222e:	6088                	ld	a0,0(s1)
    80002230:	d97d                	beqz	a0,80002226 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002232:	00002097          	auipc	ra,0x2
    80002236:	7ba080e7          	jalr	1978(ra) # 800049ec <filedup>
    8000223a:	00a93023          	sd	a0,0(s2)
    8000223e:	b7e5                	j	80002226 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002240:	158ab503          	ld	a0,344(s5)
    80002244:	00002097          	auipc	ra,0x2
    80002248:	952080e7          	jalr	-1710(ra) # 80003b96 <idup>
    8000224c:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002250:	4641                	li	a2,16
    80002252:	160a8593          	addi	a1,s5,352
    80002256:	160a0513          	addi	a0,s4,352
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	bbc080e7          	jalr	-1092(ra) # 80000e16 <safestrcpy>
    pid = np->pid;
    80002262:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002266:	8552                	mv	a0,s4
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a1e080e7          	jalr	-1506(ra) # 80000c86 <release>
    acquire(&wait_lock);
    80002270:	0000f497          	auipc	s1,0xf
    80002274:	e1848493          	addi	s1,s1,-488 # 80011088 <wait_lock>
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	958080e7          	jalr	-1704(ra) # 80000bd2 <acquire>
    np->parent = p;
    80002282:	055a3023          	sd	s5,64(s4)
    release(&wait_lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	9fe080e7          	jalr	-1538(ra) # 80000c86 <release>
    acquire(&np->lock);
    80002290:	8552                	mv	a0,s4
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	940080e7          	jalr	-1728(ra) # 80000bd2 <acquire>
    np->state = RUNNABLE;
    8000229a:	478d                	li	a5,3
    8000229c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022a0:	8552                	mv	a0,s4
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9e4080e7          	jalr	-1564(ra) # 80000c86 <release>
}
    800022aa:	854a                	mv	a0,s2
    800022ac:	70e2                	ld	ra,56(sp)
    800022ae:	7442                	ld	s0,48(sp)
    800022b0:	74a2                	ld	s1,40(sp)
    800022b2:	7902                	ld	s2,32(sp)
    800022b4:	69e2                	ld	s3,24(sp)
    800022b6:	6a42                	ld	s4,16(sp)
    800022b8:	6aa2                	ld	s5,8(sp)
    800022ba:	6121                	addi	sp,sp,64
    800022bc:	8082                	ret
        return -1;
    800022be:	597d                	li	s2,-1
    800022c0:	b7ed                	j	800022aa <fork+0x128>

00000000800022c2 <scheduler>:
{
    800022c2:	1101                	addi	sp,sp,-32
    800022c4:	ec06                	sd	ra,24(sp)
    800022c6:	e822                	sd	s0,16(sp)
    800022c8:	e426                	sd	s1,8(sp)
    800022ca:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022cc:	00006497          	auipc	s1,0x6
    800022d0:	67448493          	addi	s1,s1,1652 # 80008940 <sched_pointer>
    800022d4:	609c                	ld	a5,0(s1)
    800022d6:	9782                	jalr	a5
    while (1)
    800022d8:	bff5                	j	800022d4 <scheduler+0x12>

00000000800022da <sched>:
{
    800022da:	7179                	addi	sp,sp,-48
    800022dc:	f406                	sd	ra,40(sp)
    800022de:	f022                	sd	s0,32(sp)
    800022e0:	ec26                	sd	s1,24(sp)
    800022e2:	e84a                	sd	s2,16(sp)
    800022e4:	e44e                	sd	s3,8(sp)
    800022e6:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	994080e7          	jalr	-1644(ra) # 80001c7c <myproc>
    800022f0:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	866080e7          	jalr	-1946(ra) # 80000b58 <holding>
    800022fa:	c53d                	beqz	a0,80002368 <sched+0x8e>
    800022fc:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022fe:	2781                	sext.w	a5,a5
    80002300:	079e                	slli	a5,a5,0x7
    80002302:	0000f717          	auipc	a4,0xf
    80002306:	96e70713          	addi	a4,a4,-1682 # 80010c70 <cpus>
    8000230a:	97ba                	add	a5,a5,a4
    8000230c:	5fb8                	lw	a4,120(a5)
    8000230e:	4785                	li	a5,1
    80002310:	06f71463          	bne	a4,a5,80002378 <sched+0x9e>
    if (p->state == RUNNING)
    80002314:	4c98                	lw	a4,24(s1)
    80002316:	4791                	li	a5,4
    80002318:	06f70863          	beq	a4,a5,80002388 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002320:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002322:	ebbd                	bnez	a5,80002398 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002324:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002326:	0000f917          	auipc	s2,0xf
    8000232a:	94a90913          	addi	s2,s2,-1718 # 80010c70 <cpus>
    8000232e:	2781                	sext.w	a5,a5
    80002330:	079e                	slli	a5,a5,0x7
    80002332:	97ca                	add	a5,a5,s2
    80002334:	07c7a983          	lw	s3,124(a5)
    80002338:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000233a:	2581                	sext.w	a1,a1
    8000233c:	059e                	slli	a1,a1,0x7
    8000233e:	05a1                	addi	a1,a1,8
    80002340:	95ca                	add	a1,a1,s2
    80002342:	06848513          	addi	a0,s1,104
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	78e080e7          	jalr	1934(ra) # 80002ad4 <swtch>
    8000234e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002350:	2781                	sext.w	a5,a5
    80002352:	079e                	slli	a5,a5,0x7
    80002354:	993e                	add	s2,s2,a5
    80002356:	07392e23          	sw	s3,124(s2)
}
    8000235a:	70a2                	ld	ra,40(sp)
    8000235c:	7402                	ld	s0,32(sp)
    8000235e:	64e2                	ld	s1,24(sp)
    80002360:	6942                	ld	s2,16(sp)
    80002362:	69a2                	ld	s3,8(sp)
    80002364:	6145                	addi	sp,sp,48
    80002366:	8082                	ret
        panic("sched p->lock");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	eb050513          	addi	a0,a0,-336 # 80008218 <digits+0x1d8>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1cc080e7          	jalr	460(ra) # 8000053c <panic>
        panic("sched locks");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	eb050513          	addi	a0,a0,-336 # 80008228 <digits+0x1e8>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1bc080e7          	jalr	444(ra) # 8000053c <panic>
        panic("sched running");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	eb050513          	addi	a0,a0,-336 # 80008238 <digits+0x1f8>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1ac080e7          	jalr	428(ra) # 8000053c <panic>
        panic("sched interruptible");
    80002398:	00006517          	auipc	a0,0x6
    8000239c:	eb050513          	addi	a0,a0,-336 # 80008248 <digits+0x208>
    800023a0:	ffffe097          	auipc	ra,0xffffe
    800023a4:	19c080e7          	jalr	412(ra) # 8000053c <panic>

00000000800023a8 <yield>:
{
    800023a8:	1101                	addi	sp,sp,-32
    800023aa:	ec06                	sd	ra,24(sp)
    800023ac:	e822                	sd	s0,16(sp)
    800023ae:	e426                	sd	s1,8(sp)
    800023b0:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	8ca080e7          	jalr	-1846(ra) # 80001c7c <myproc>
    800023ba:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	816080e7          	jalr	-2026(ra) # 80000bd2 <acquire>
    p->state = RUNNABLE;
    800023c4:	478d                	li	a5,3
    800023c6:	cc9c                	sw	a5,24(s1)
    sched();
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	f12080e7          	jalr	-238(ra) # 800022da <sched>
    release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b4080e7          	jalr	-1868(ra) # 80000c86 <release>
}
    800023da:	60e2                	ld	ra,24(sp)
    800023dc:	6442                	ld	s0,16(sp)
    800023de:	64a2                	ld	s1,8(sp)
    800023e0:	6105                	addi	sp,sp,32
    800023e2:	8082                	ret

00000000800023e4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023e4:	7179                	addi	sp,sp,-48
    800023e6:	f406                	sd	ra,40(sp)
    800023e8:	f022                	sd	s0,32(sp)
    800023ea:	ec26                	sd	s1,24(sp)
    800023ec:	e84a                	sd	s2,16(sp)
    800023ee:	e44e                	sd	s3,8(sp)
    800023f0:	1800                	addi	s0,sp,48
    800023f2:	89aa                	mv	s3,a0
    800023f4:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023f6:	00000097          	auipc	ra,0x0
    800023fa:	886080e7          	jalr	-1914(ra) # 80001c7c <myproc>
    800023fe:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
    release(lk);
    80002408:	854a                	mv	a0,s2
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	87c080e7          	jalr	-1924(ra) # 80000c86 <release>

    // Go to sleep.
    p->chan = chan;
    80002412:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002416:	4789                	li	a5,2
    80002418:	cc9c                	sw	a5,24(s1)

    sched();
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	ec0080e7          	jalr	-320(ra) # 800022da <sched>

    // Tidy up.
    p->chan = 0;
    80002422:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	85e080e7          	jalr	-1954(ra) # 80000c86 <release>
    acquire(lk);
    80002430:	854a                	mv	a0,s2
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	7a0080e7          	jalr	1952(ra) # 80000bd2 <acquire>
}
    8000243a:	70a2                	ld	ra,40(sp)
    8000243c:	7402                	ld	s0,32(sp)
    8000243e:	64e2                	ld	s1,24(sp)
    80002440:	6942                	ld	s2,16(sp)
    80002442:	69a2                	ld	s3,8(sp)
    80002444:	6145                	addi	sp,sp,48
    80002446:	8082                	ret

0000000080002448 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002448:	7139                	addi	sp,sp,-64
    8000244a:	fc06                	sd	ra,56(sp)
    8000244c:	f822                	sd	s0,48(sp)
    8000244e:	f426                	sd	s1,40(sp)
    80002450:	f04a                	sd	s2,32(sp)
    80002452:	ec4e                	sd	s3,24(sp)
    80002454:	e852                	sd	s4,16(sp)
    80002456:	e456                	sd	s5,8(sp)
    80002458:	0080                	addi	s0,sp,64
    8000245a:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000245c:	0000f497          	auipc	s1,0xf
    80002460:	c4448493          	addi	s1,s1,-956 # 800110a0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002464:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002466:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002468:	00015917          	auipc	s2,0x15
    8000246c:	83890913          	addi	s2,s2,-1992 # 80016ca0 <tickslock>
    80002470:	a811                	j	80002484 <wakeup+0x3c>
            }
            release(&p->lock);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	812080e7          	jalr	-2030(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000247c:	17048493          	addi	s1,s1,368
    80002480:	03248663          	beq	s1,s2,800024ac <wakeup+0x64>
        if (p != myproc())
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	7f8080e7          	jalr	2040(ra) # 80001c7c <myproc>
    8000248c:	fea488e3          	beq	s1,a0,8000247c <wakeup+0x34>
            acquire(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	740080e7          	jalr	1856(ra) # 80000bd2 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000249a:	4c9c                	lw	a5,24(s1)
    8000249c:	fd379be3          	bne	a5,s3,80002472 <wakeup+0x2a>
    800024a0:	709c                	ld	a5,32(s1)
    800024a2:	fd4798e3          	bne	a5,s4,80002472 <wakeup+0x2a>
                p->state = RUNNABLE;
    800024a6:	0154ac23          	sw	s5,24(s1)
    800024aa:	b7e1                	j	80002472 <wakeup+0x2a>
        }
    }
}
    800024ac:	70e2                	ld	ra,56(sp)
    800024ae:	7442                	ld	s0,48(sp)
    800024b0:	74a2                	ld	s1,40(sp)
    800024b2:	7902                	ld	s2,32(sp)
    800024b4:	69e2                	ld	s3,24(sp)
    800024b6:	6a42                	ld	s4,16(sp)
    800024b8:	6aa2                	ld	s5,8(sp)
    800024ba:	6121                	addi	sp,sp,64
    800024bc:	8082                	ret

00000000800024be <reparent>:
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d0:	0000f497          	auipc	s1,0xf
    800024d4:	bd048493          	addi	s1,s1,-1072 # 800110a0 <proc>
            pp->parent = initproc;
    800024d8:	00006a17          	auipc	s4,0x6
    800024dc:	520a0a13          	addi	s4,s4,1312 # 800089f8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024e0:	00014997          	auipc	s3,0x14
    800024e4:	7c098993          	addi	s3,s3,1984 # 80016ca0 <tickslock>
    800024e8:	a029                	j	800024f2 <reparent+0x34>
    800024ea:	17048493          	addi	s1,s1,368
    800024ee:	01348d63          	beq	s1,s3,80002508 <reparent+0x4a>
        if (pp->parent == p)
    800024f2:	60bc                	ld	a5,64(s1)
    800024f4:	ff279be3          	bne	a5,s2,800024ea <reparent+0x2c>
            pp->parent = initproc;
    800024f8:	000a3503          	ld	a0,0(s4)
    800024fc:	e0a8                	sd	a0,64(s1)
            wakeup(initproc);
    800024fe:	00000097          	auipc	ra,0x0
    80002502:	f4a080e7          	jalr	-182(ra) # 80002448 <wakeup>
    80002506:	b7d5                	j	800024ea <reparent+0x2c>
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6a02                	ld	s4,0(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret

0000000080002518 <exit>:
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	e052                	sd	s4,0(sp)
    80002526:	1800                	addi	s0,sp,48
    80002528:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	752080e7          	jalr	1874(ra) # 80001c7c <myproc>
    80002532:	89aa                	mv	s3,a0
    if (p == initproc)
    80002534:	00006797          	auipc	a5,0x6
    80002538:	4c47b783          	ld	a5,1220(a5) # 800089f8 <initproc>
    8000253c:	0d850493          	addi	s1,a0,216
    80002540:	15850913          	addi	s2,a0,344
    80002544:	02a79363          	bne	a5,a0,8000256a <exit+0x52>
        panic("init exiting");
    80002548:	00006517          	auipc	a0,0x6
    8000254c:	d1850513          	addi	a0,a0,-744 # 80008260 <digits+0x220>
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	fec080e7          	jalr	-20(ra) # 8000053c <panic>
            fileclose(f);
    80002558:	00002097          	auipc	ra,0x2
    8000255c:	4e6080e7          	jalr	1254(ra) # 80004a3e <fileclose>
            p->ofile[fd] = 0;
    80002560:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002564:	04a1                	addi	s1,s1,8
    80002566:	01248563          	beq	s1,s2,80002570 <exit+0x58>
        if (p->ofile[fd])
    8000256a:	6088                	ld	a0,0(s1)
    8000256c:	f575                	bnez	a0,80002558 <exit+0x40>
    8000256e:	bfdd                	j	80002564 <exit+0x4c>
    begin_op();
    80002570:	00002097          	auipc	ra,0x2
    80002574:	00a080e7          	jalr	10(ra) # 8000457a <begin_op>
    iput(p->cwd);
    80002578:	1589b503          	ld	a0,344(s3)
    8000257c:	00002097          	auipc	ra,0x2
    80002580:	812080e7          	jalr	-2030(ra) # 80003d8e <iput>
    end_op();
    80002584:	00002097          	auipc	ra,0x2
    80002588:	070080e7          	jalr	112(ra) # 800045f4 <end_op>
    p->cwd = 0;
    8000258c:	1409bc23          	sd	zero,344(s3)
    acquire(&wait_lock);
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	af848493          	addi	s1,s1,-1288 # 80011088 <wait_lock>
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	638080e7          	jalr	1592(ra) # 80000bd2 <acquire>
    reparent(p);
    800025a2:	854e                	mv	a0,s3
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	f1a080e7          	jalr	-230(ra) # 800024be <reparent>
    wakeup(p->parent);
    800025ac:	0409b503          	ld	a0,64(s3)
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	e98080e7          	jalr	-360(ra) # 80002448 <wakeup>
    acquire(&p->lock);
    800025b8:	854e                	mv	a0,s3
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	618080e7          	jalr	1560(ra) # 80000bd2 <acquire>
    p->xstate = status;
    800025c2:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025c6:	4795                	li	a5,5
    800025c8:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6b8080e7          	jalr	1720(ra) # 80000c86 <release>
    sched();
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	d04080e7          	jalr	-764(ra) # 800022da <sched>
    panic("zombie exit");
    800025de:	00006517          	auipc	a0,0x6
    800025e2:	c9250513          	addi	a0,a0,-878 # 80008270 <digits+0x230>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	f56080e7          	jalr	-170(ra) # 8000053c <panic>

00000000800025ee <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	1800                	addi	s0,sp,48
    800025fc:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025fe:	0000f497          	auipc	s1,0xf
    80002602:	aa248493          	addi	s1,s1,-1374 # 800110a0 <proc>
    80002606:	00014997          	auipc	s3,0x14
    8000260a:	69a98993          	addi	s3,s3,1690 # 80016ca0 <tickslock>
    {
        acquire(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5c2080e7          	jalr	1474(ra) # 80000bd2 <acquire>
        if (p->pid == pid)
    80002618:	589c                	lw	a5,48(s1)
    8000261a:	01278d63          	beq	a5,s2,80002634 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	666080e7          	jalr	1638(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002628:	17048493          	addi	s1,s1,368
    8000262c:	ff3491e3          	bne	s1,s3,8000260e <kill+0x20>
    }
    return -1;
    80002630:	557d                	li	a0,-1
    80002632:	a829                	j	8000264c <kill+0x5e>
            p->killed = 1;
    80002634:	4785                	li	a5,1
    80002636:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002638:	4c98                	lw	a4,24(s1)
    8000263a:	4789                	li	a5,2
    8000263c:	00f70f63          	beq	a4,a5,8000265a <kill+0x6c>
            release(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	644080e7          	jalr	1604(ra) # 80000c86 <release>
            return 0;
    8000264a:	4501                	li	a0,0
}
    8000264c:	70a2                	ld	ra,40(sp)
    8000264e:	7402                	ld	s0,32(sp)
    80002650:	64e2                	ld	s1,24(sp)
    80002652:	6942                	ld	s2,16(sp)
    80002654:	69a2                	ld	s3,8(sp)
    80002656:	6145                	addi	sp,sp,48
    80002658:	8082                	ret
                p->state = RUNNABLE;
    8000265a:	478d                	li	a5,3
    8000265c:	cc9c                	sw	a5,24(s1)
    8000265e:	b7cd                	j	80002640 <kill+0x52>

0000000080002660 <setkilled>:

void setkilled(struct proc *p)
{
    80002660:	1101                	addi	sp,sp,-32
    80002662:	ec06                	sd	ra,24(sp)
    80002664:	e822                	sd	s0,16(sp)
    80002666:	e426                	sd	s1,8(sp)
    80002668:	1000                	addi	s0,sp,32
    8000266a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	566080e7          	jalr	1382(ra) # 80000bd2 <acquire>
    p->killed = 1;
    80002674:	4785                	li	a5,1
    80002676:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	60c080e7          	jalr	1548(ra) # 80000c86 <release>
}
    80002682:	60e2                	ld	ra,24(sp)
    80002684:	6442                	ld	s0,16(sp)
    80002686:	64a2                	ld	s1,8(sp)
    80002688:	6105                	addi	sp,sp,32
    8000268a:	8082                	ret

000000008000268c <killed>:

int killed(struct proc *p)
{
    8000268c:	1101                	addi	sp,sp,-32
    8000268e:	ec06                	sd	ra,24(sp)
    80002690:	e822                	sd	s0,16(sp)
    80002692:	e426                	sd	s1,8(sp)
    80002694:	e04a                	sd	s2,0(sp)
    80002696:	1000                	addi	s0,sp,32
    80002698:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	538080e7          	jalr	1336(ra) # 80000bd2 <acquire>
    k = p->killed;
    800026a2:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5de080e7          	jalr	1502(ra) # 80000c86 <release>
    return k;
}
    800026b0:	854a                	mv	a0,s2
    800026b2:	60e2                	ld	ra,24(sp)
    800026b4:	6442                	ld	s0,16(sp)
    800026b6:	64a2                	ld	s1,8(sp)
    800026b8:	6902                	ld	s2,0(sp)
    800026ba:	6105                	addi	sp,sp,32
    800026bc:	8082                	ret

00000000800026be <wait>:
{
    800026be:	715d                	addi	sp,sp,-80
    800026c0:	e486                	sd	ra,72(sp)
    800026c2:	e0a2                	sd	s0,64(sp)
    800026c4:	fc26                	sd	s1,56(sp)
    800026c6:	f84a                	sd	s2,48(sp)
    800026c8:	f44e                	sd	s3,40(sp)
    800026ca:	f052                	sd	s4,32(sp)
    800026cc:	ec56                	sd	s5,24(sp)
    800026ce:	e85a                	sd	s6,16(sp)
    800026d0:	e45e                	sd	s7,8(sp)
    800026d2:	e062                	sd	s8,0(sp)
    800026d4:	0880                	addi	s0,sp,80
    800026d6:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	5a4080e7          	jalr	1444(ra) # 80001c7c <myproc>
    800026e0:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026e2:	0000f517          	auipc	a0,0xf
    800026e6:	9a650513          	addi	a0,a0,-1626 # 80011088 <wait_lock>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	4e8080e7          	jalr	1256(ra) # 80000bd2 <acquire>
        havekids = 0;
    800026f2:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026f4:	4a15                	li	s4,5
                havekids = 1;
    800026f6:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f8:	00014997          	auipc	s3,0x14
    800026fc:	5a898993          	addi	s3,s3,1448 # 80016ca0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002700:	0000fc17          	auipc	s8,0xf
    80002704:	988c0c13          	addi	s8,s8,-1656 # 80011088 <wait_lock>
    80002708:	a0d1                	j	800027cc <wait+0x10e>
                    pid = pp->pid;
    8000270a:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000270e:	000b0e63          	beqz	s6,8000272a <wait+0x6c>
    80002712:	4691                	li	a3,4
    80002714:	02c48613          	addi	a2,s1,44
    80002718:	85da                	mv	a1,s6
    8000271a:	05893503          	ld	a0,88(s2)
    8000271e:	fffff097          	auipc	ra,0xfffff
    80002722:	f48080e7          	jalr	-184(ra) # 80001666 <copyout>
    80002726:	04054163          	bltz	a0,80002768 <wait+0xaa>
                    freeproc(pp);
    8000272a:	8526                	mv	a0,s1
    8000272c:	fffff097          	auipc	ra,0xfffff
    80002730:	702080e7          	jalr	1794(ra) # 80001e2e <freeproc>
                    release(&pp->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	550080e7          	jalr	1360(ra) # 80000c86 <release>
                    release(&wait_lock);
    8000273e:	0000f517          	auipc	a0,0xf
    80002742:	94a50513          	addi	a0,a0,-1718 # 80011088 <wait_lock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	540080e7          	jalr	1344(ra) # 80000c86 <release>
}
    8000274e:	854e                	mv	a0,s3
    80002750:	60a6                	ld	ra,72(sp)
    80002752:	6406                	ld	s0,64(sp)
    80002754:	74e2                	ld	s1,56(sp)
    80002756:	7942                	ld	s2,48(sp)
    80002758:	79a2                	ld	s3,40(sp)
    8000275a:	7a02                	ld	s4,32(sp)
    8000275c:	6ae2                	ld	s5,24(sp)
    8000275e:	6b42                	ld	s6,16(sp)
    80002760:	6ba2                	ld	s7,8(sp)
    80002762:	6c02                	ld	s8,0(sp)
    80002764:	6161                	addi	sp,sp,80
    80002766:	8082                	ret
                        release(&pp->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	51c080e7          	jalr	1308(ra) # 80000c86 <release>
                        release(&wait_lock);
    80002772:	0000f517          	auipc	a0,0xf
    80002776:	91650513          	addi	a0,a0,-1770 # 80011088 <wait_lock>
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	50c080e7          	jalr	1292(ra) # 80000c86 <release>
                        return -1;
    80002782:	59fd                	li	s3,-1
    80002784:	b7e9                	j	8000274e <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002786:	17048493          	addi	s1,s1,368
    8000278a:	03348463          	beq	s1,s3,800027b2 <wait+0xf4>
            if (pp->parent == p)
    8000278e:	60bc                	ld	a5,64(s1)
    80002790:	ff279be3          	bne	a5,s2,80002786 <wait+0xc8>
                acquire(&pp->lock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	43c080e7          	jalr	1084(ra) # 80000bd2 <acquire>
                if (pp->state == ZOMBIE)
    8000279e:	4c9c                	lw	a5,24(s1)
    800027a0:	f74785e3          	beq	a5,s4,8000270a <wait+0x4c>
                release(&pp->lock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4e0080e7          	jalr	1248(ra) # 80000c86 <release>
                havekids = 1;
    800027ae:	8756                	mv	a4,s5
    800027b0:	bfd9                	j	80002786 <wait+0xc8>
        if (!havekids || killed(p))
    800027b2:	c31d                	beqz	a4,800027d8 <wait+0x11a>
    800027b4:	854a                	mv	a0,s2
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	ed6080e7          	jalr	-298(ra) # 8000268c <killed>
    800027be:	ed09                	bnez	a0,800027d8 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027c0:	85e2                	mv	a1,s8
    800027c2:	854a                	mv	a0,s2
    800027c4:	00000097          	auipc	ra,0x0
    800027c8:	c20080e7          	jalr	-992(ra) # 800023e4 <sleep>
        havekids = 0;
    800027cc:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027ce:	0000f497          	auipc	s1,0xf
    800027d2:	8d248493          	addi	s1,s1,-1838 # 800110a0 <proc>
    800027d6:	bf65                	j	8000278e <wait+0xd0>
            release(&wait_lock);
    800027d8:	0000f517          	auipc	a0,0xf
    800027dc:	8b050513          	addi	a0,a0,-1872 # 80011088 <wait_lock>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4a6080e7          	jalr	1190(ra) # 80000c86 <release>
            return -1;
    800027e8:	59fd                	li	s3,-1
    800027ea:	b795                	j	8000274e <wait+0x90>

00000000800027ec <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ec:	7179                	addi	sp,sp,-48
    800027ee:	f406                	sd	ra,40(sp)
    800027f0:	f022                	sd	s0,32(sp)
    800027f2:	ec26                	sd	s1,24(sp)
    800027f4:	e84a                	sd	s2,16(sp)
    800027f6:	e44e                	sd	s3,8(sp)
    800027f8:	e052                	sd	s4,0(sp)
    800027fa:	1800                	addi	s0,sp,48
    800027fc:	84aa                	mv	s1,a0
    800027fe:	892e                	mv	s2,a1
    80002800:	89b2                	mv	s3,a2
    80002802:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	478080e7          	jalr	1144(ra) # 80001c7c <myproc>
    if (user_dst)
    8000280c:	c08d                	beqz	s1,8000282e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000280e:	86d2                	mv	a3,s4
    80002810:	864e                	mv	a2,s3
    80002812:	85ca                	mv	a1,s2
    80002814:	6d28                	ld	a0,88(a0)
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	e50080e7          	jalr	-432(ra) # 80001666 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000281e:	70a2                	ld	ra,40(sp)
    80002820:	7402                	ld	s0,32(sp)
    80002822:	64e2                	ld	s1,24(sp)
    80002824:	6942                	ld	s2,16(sp)
    80002826:	69a2                	ld	s3,8(sp)
    80002828:	6a02                	ld	s4,0(sp)
    8000282a:	6145                	addi	sp,sp,48
    8000282c:	8082                	ret
        memmove((char *)dst, src, len);
    8000282e:	000a061b          	sext.w	a2,s4
    80002832:	85ce                	mv	a1,s3
    80002834:	854a                	mv	a0,s2
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	4f4080e7          	jalr	1268(ra) # 80000d2a <memmove>
        return 0;
    8000283e:	8526                	mv	a0,s1
    80002840:	bff9                	j	8000281e <either_copyout+0x32>

0000000080002842 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002842:	7179                	addi	sp,sp,-48
    80002844:	f406                	sd	ra,40(sp)
    80002846:	f022                	sd	s0,32(sp)
    80002848:	ec26                	sd	s1,24(sp)
    8000284a:	e84a                	sd	s2,16(sp)
    8000284c:	e44e                	sd	s3,8(sp)
    8000284e:	e052                	sd	s4,0(sp)
    80002850:	1800                	addi	s0,sp,48
    80002852:	892a                	mv	s2,a0
    80002854:	84ae                	mv	s1,a1
    80002856:	89b2                	mv	s3,a2
    80002858:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	422080e7          	jalr	1058(ra) # 80001c7c <myproc>
    if (user_src)
    80002862:	c08d                	beqz	s1,80002884 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002864:	86d2                	mv	a3,s4
    80002866:	864e                	mv	a2,s3
    80002868:	85ca                	mv	a1,s2
    8000286a:	6d28                	ld	a0,88(a0)
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	e86080e7          	jalr	-378(ra) # 800016f2 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002874:	70a2                	ld	ra,40(sp)
    80002876:	7402                	ld	s0,32(sp)
    80002878:	64e2                	ld	s1,24(sp)
    8000287a:	6942                	ld	s2,16(sp)
    8000287c:	69a2                	ld	s3,8(sp)
    8000287e:	6a02                	ld	s4,0(sp)
    80002880:	6145                	addi	sp,sp,48
    80002882:	8082                	ret
        memmove(dst, (char *)src, len);
    80002884:	000a061b          	sext.w	a2,s4
    80002888:	85ce                	mv	a1,s3
    8000288a:	854a                	mv	a0,s2
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	49e080e7          	jalr	1182(ra) # 80000d2a <memmove>
        return 0;
    80002894:	8526                	mv	a0,s1
    80002896:	bff9                	j	80002874 <either_copyin+0x32>

0000000080002898 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002898:	715d                	addi	sp,sp,-80
    8000289a:	e486                	sd	ra,72(sp)
    8000289c:	e0a2                	sd	s0,64(sp)
    8000289e:	fc26                	sd	s1,56(sp)
    800028a0:	f84a                	sd	s2,48(sp)
    800028a2:	f44e                	sd	s3,40(sp)
    800028a4:	f052                	sd	s4,32(sp)
    800028a6:	ec56                	sd	s5,24(sp)
    800028a8:	e85a                	sd	s6,16(sp)
    800028aa:	e45e                	sd	s7,8(sp)
    800028ac:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	81a50513          	addi	a0,a0,-2022 # 800080c8 <digits+0x88>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cd0080e7          	jalr	-816(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028be:	0000f497          	auipc	s1,0xf
    800028c2:	94248493          	addi	s1,s1,-1726 # 80011200 <proc+0x160>
    800028c6:	00014917          	auipc	s2,0x14
    800028ca:	53a90913          	addi	s2,s2,1338 # 80016e00 <bcache+0x148>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ce:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028d0:	00006997          	auipc	s3,0x6
    800028d4:	9b098993          	addi	s3,s3,-1616 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    800028d8:	00006a97          	auipc	s5,0x6
    800028dc:	9b0a8a93          	addi	s5,s5,-1616 # 80008288 <digits+0x248>
        printf("\n");
    800028e0:	00005a17          	auipc	s4,0x5
    800028e4:	7e8a0a13          	addi	s4,s4,2024 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e8:	00006b97          	auipc	s7,0x6
    800028ec:	ab0b8b93          	addi	s7,s7,-1360 # 80008398 <states.0>
    800028f0:	a00d                	j	80002912 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028f2:	ed06a583          	lw	a1,-304(a3)
    800028f6:	8556                	mv	a0,s5
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c8e080e7          	jalr	-882(ra) # 80000586 <printf>
        printf("\n");
    80002900:	8552                	mv	a0,s4
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c84080e7          	jalr	-892(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000290a:	17048493          	addi	s1,s1,368
    8000290e:	03248263          	beq	s1,s2,80002932 <procdump+0x9a>
        if (p->state == UNUSED)
    80002912:	86a6                	mv	a3,s1
    80002914:	eb84a783          	lw	a5,-328(s1)
    80002918:	dbed                	beqz	a5,8000290a <procdump+0x72>
            state = "???";
    8000291a:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000291c:	fcfb6be3          	bltu	s6,a5,800028f2 <procdump+0x5a>
    80002920:	02079713          	slli	a4,a5,0x20
    80002924:	01d75793          	srli	a5,a4,0x1d
    80002928:	97de                	add	a5,a5,s7
    8000292a:	6390                	ld	a2,0(a5)
    8000292c:	f279                	bnez	a2,800028f2 <procdump+0x5a>
            state = "???";
    8000292e:	864e                	mv	a2,s3
    80002930:	b7c9                	j	800028f2 <procdump+0x5a>
    }
}
    80002932:	60a6                	ld	ra,72(sp)
    80002934:	6406                	ld	s0,64(sp)
    80002936:	74e2                	ld	s1,56(sp)
    80002938:	7942                	ld	s2,48(sp)
    8000293a:	79a2                	ld	s3,40(sp)
    8000293c:	7a02                	ld	s4,32(sp)
    8000293e:	6ae2                	ld	s5,24(sp)
    80002940:	6b42                	ld	s6,16(sp)
    80002942:	6ba2                	ld	s7,8(sp)
    80002944:	6161                	addi	sp,sp,80
    80002946:	8082                	ret

0000000080002948 <schedls>:

void schedls()
{
    80002948:	1101                	addi	sp,sp,-32
    8000294a:	ec06                	sd	ra,24(sp)
    8000294c:	e822                	sd	s0,16(sp)
    8000294e:	e426                	sd	s1,8(sp)
    80002950:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002952:	00006517          	auipc	a0,0x6
    80002956:	94650513          	addi	a0,a0,-1722 # 80008298 <digits+0x258>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	c2c080e7          	jalr	-980(ra) # 80000586 <printf>
    printf("====================================\n");
    80002962:	00006517          	auipc	a0,0x6
    80002966:	95e50513          	addi	a0,a0,-1698 # 800082c0 <digits+0x280>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c1c080e7          	jalr	-996(ra) # 80000586 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002972:	00006717          	auipc	a4,0x6
    80002976:	02673703          	ld	a4,38(a4) # 80008998 <available_schedulers+0x10>
    8000297a:	00006797          	auipc	a5,0x6
    8000297e:	fc67b783          	ld	a5,-58(a5) # 80008940 <sched_pointer>
    80002982:	08f70763          	beq	a4,a5,80002a10 <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	96250513          	addi	a0,a0,-1694 # 800082e8 <digits+0x2a8>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	bf8080e7          	jalr	-1032(ra) # 80000586 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002996:	00006497          	auipc	s1,0x6
    8000299a:	fba48493          	addi	s1,s1,-70 # 80008950 <initcode>
    8000299e:	48b0                	lw	a2,80(s1)
    800029a0:	00006597          	auipc	a1,0x6
    800029a4:	fe858593          	addi	a1,a1,-24 # 80008988 <available_schedulers>
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	95050513          	addi	a0,a0,-1712 # 800082f8 <digits+0x2b8>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bd6080e7          	jalr	-1066(ra) # 80000586 <printf>
        if (available_schedulers[i].impl == sched_pointer)
    800029b8:	74b8                	ld	a4,104(s1)
    800029ba:	00006797          	auipc	a5,0x6
    800029be:	f867b783          	ld	a5,-122(a5) # 80008940 <sched_pointer>
    800029c2:	06f70063          	beq	a4,a5,80002a22 <schedls+0xda>
            printf("   \t");
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	92250513          	addi	a0,a0,-1758 # 800082e8 <digits+0x2a8>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	bb8080e7          	jalr	-1096(ra) # 80000586 <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800029d6:	00006617          	auipc	a2,0x6
    800029da:	fea62603          	lw	a2,-22(a2) # 800089c0 <available_schedulers+0x38>
    800029de:	00006597          	auipc	a1,0x6
    800029e2:	fca58593          	addi	a1,a1,-54 # 800089a8 <available_schedulers+0x20>
    800029e6:	00006517          	auipc	a0,0x6
    800029ea:	91250513          	addi	a0,a0,-1774 # 800082f8 <digits+0x2b8>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b98080e7          	jalr	-1128(ra) # 80000586 <printf>
    }
    printf("\n*: current scheduler\n\n");
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	90a50513          	addi	a0,a0,-1782 # 80008300 <digits+0x2c0>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b88080e7          	jalr	-1144(ra) # 80000586 <printf>
}
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	64a2                	ld	s1,8(sp)
    80002a0c:	6105                	addi	sp,sp,32
    80002a0e:	8082                	ret
            printf("[*]\t");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	8e050513          	addi	a0,a0,-1824 # 800082f0 <digits+0x2b0>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b6e080e7          	jalr	-1170(ra) # 80000586 <printf>
    80002a20:	bf9d                	j	80002996 <schedls+0x4e>
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	8ce50513          	addi	a0,a0,-1842 # 800082f0 <digits+0x2b0>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b5c080e7          	jalr	-1188(ra) # 80000586 <printf>
    80002a32:	b755                	j	800029d6 <schedls+0x8e>

0000000080002a34 <schedset>:


void schedset(int id)
{
    80002a34:	7179                	addi	sp,sp,-48
    80002a36:	f406                	sd	ra,40(sp)
    80002a38:	f022                	sd	s0,32(sp)
    80002a3a:	ec26                	sd	s1,24(sp)
    80002a3c:	e84a                	sd	s2,16(sp)
    80002a3e:	e44e                	sd	s3,8(sp)
    80002a40:	1800                	addi	s0,sp,48
    if (id < 0 || SCHEDC <= id)
    80002a42:	4705                	li	a4,1
    80002a44:	06a76f63          	bltu	a4,a0,80002ac2 <schedset+0x8e>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a48:	00551793          	slli	a5,a0,0x5
    80002a4c:	00006717          	auipc	a4,0x6
    80002a50:	f0470713          	addi	a4,a4,-252 # 80008950 <initcode>
    80002a54:	973e                	add	a4,a4,a5
    80002a56:	6738                	ld	a4,72(a4)
    80002a58:	00006697          	auipc	a3,0x6
    80002a5c:	eee6b423          	sd	a4,-280(a3) # 80008940 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a60:	00006597          	auipc	a1,0x6
    80002a64:	f2858593          	addi	a1,a1,-216 # 80008988 <available_schedulers>
    80002a68:	95be                	add	a1,a1,a5
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	8d650513          	addi	a0,a0,-1834 # 80008340 <digits+0x300>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b14080e7          	jalr	-1260(ra) # 80000586 <printf>

    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
    80002a7a:	0000e497          	auipc	s1,0xe
    80002a7e:	62648493          	addi	s1,s1,1574 # 800110a0 <proc>
        acquire(&p->lock);
        p->runticks = 0;
        p->priority = 1;
    80002a82:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++) {
    80002a84:	00014917          	auipc	s2,0x14
    80002a88:	21c90913          	addi	s2,s2,540 # 80016ca0 <tickslock>
        acquire(&p->lock);
    80002a8c:	8526                	mv	a0,s1
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	144080e7          	jalr	324(ra) # 80000bd2 <acquire>
        p->runticks = 0;
    80002a96:	0204aa23          	sw	zero,52(s1)
        p->priority = 1;
    80002a9a:	0334ac23          	sw	s3,56(s1)
        p->ctime = 0;
    80002a9e:	0204ae23          	sw	zero,60(s1)
        release(&p->lock);    
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	1e2080e7          	jalr	482(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002aac:	17048493          	addi	s1,s1,368
    80002ab0:	fd249ee3          	bne	s1,s2,80002a8c <schedset+0x58>
    }
    
    
    80002ab4:	70a2                	ld	ra,40(sp)
    80002ab6:	7402                	ld	s0,32(sp)
    80002ab8:	64e2                	ld	s1,24(sp)
    80002aba:	6942                	ld	s2,16(sp)
    80002abc:	69a2                	ld	s3,8(sp)
    80002abe:	6145                	addi	sp,sp,48
    80002ac0:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	85650513          	addi	a0,a0,-1962 # 80008318 <digits+0x2d8>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	abc080e7          	jalr	-1348(ra) # 80000586 <printf>
        return;
    80002ad2:	b7cd                	j	80002ab4 <schedset+0x80>

0000000080002ad4 <swtch>:
    80002ad4:	00153023          	sd	ra,0(a0)
    80002ad8:	00253423          	sd	sp,8(a0)
    80002adc:	e900                	sd	s0,16(a0)
    80002ade:	ed04                	sd	s1,24(a0)
    80002ae0:	03253023          	sd	s2,32(a0)
    80002ae4:	03353423          	sd	s3,40(a0)
    80002ae8:	03453823          	sd	s4,48(a0)
    80002aec:	03553c23          	sd	s5,56(a0)
    80002af0:	05653023          	sd	s6,64(a0)
    80002af4:	05753423          	sd	s7,72(a0)
    80002af8:	05853823          	sd	s8,80(a0)
    80002afc:	05953c23          	sd	s9,88(a0)
    80002b00:	07a53023          	sd	s10,96(a0)
    80002b04:	07b53423          	sd	s11,104(a0)
    80002b08:	0005b083          	ld	ra,0(a1)
    80002b0c:	0085b103          	ld	sp,8(a1)
    80002b10:	6980                	ld	s0,16(a1)
    80002b12:	6d84                	ld	s1,24(a1)
    80002b14:	0205b903          	ld	s2,32(a1)
    80002b18:	0285b983          	ld	s3,40(a1)
    80002b1c:	0305ba03          	ld	s4,48(a1)
    80002b20:	0385ba83          	ld	s5,56(a1)
    80002b24:	0405bb03          	ld	s6,64(a1)
    80002b28:	0485bb83          	ld	s7,72(a1)
    80002b2c:	0505bc03          	ld	s8,80(a1)
    80002b30:	0585bc83          	ld	s9,88(a1)
    80002b34:	0605bd03          	ld	s10,96(a1)
    80002b38:	0685bd83          	ld	s11,104(a1)
    80002b3c:	8082                	ret

0000000080002b3e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b3e:	1141                	addi	sp,sp,-16
    80002b40:	e406                	sd	ra,8(sp)
    80002b42:	e022                	sd	s0,0(sp)
    80002b44:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b46:	00006597          	auipc	a1,0x6
    80002b4a:	88258593          	addi	a1,a1,-1918 # 800083c8 <states.0+0x30>
    80002b4e:	00014517          	auipc	a0,0x14
    80002b52:	15250513          	addi	a0,a0,338 # 80016ca0 <tickslock>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	fec080e7          	jalr	-20(ra) # 80000b42 <initlock>
}
    80002b5e:	60a2                	ld	ra,8(sp)
    80002b60:	6402                	ld	s0,0(sp)
    80002b62:	0141                	addi	sp,sp,16
    80002b64:	8082                	ret

0000000080002b66 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b66:	1141                	addi	sp,sp,-16
    80002b68:	e422                	sd	s0,8(sp)
    80002b6a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6c:	00003797          	auipc	a5,0x3
    80002b70:	4f478793          	addi	a5,a5,1268 # 80006060 <kernelvec>
    80002b74:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b78:	6422                	ld	s0,8(sp)
    80002b7a:	0141                	addi	sp,sp,16
    80002b7c:	8082                	ret

0000000080002b7e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b7e:	1141                	addi	sp,sp,-16
    80002b80:	e406                	sd	ra,8(sp)
    80002b82:	e022                	sd	s0,0(sp)
    80002b84:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	0f6080e7          	jalr	246(ra) # 80001c7c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b94:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b98:	00004697          	auipc	a3,0x4
    80002b9c:	46868693          	addi	a3,a3,1128 # 80007000 <_trampoline>
    80002ba0:	00004717          	auipc	a4,0x4
    80002ba4:	46070713          	addi	a4,a4,1120 # 80007000 <_trampoline>
    80002ba8:	8f15                	sub	a4,a4,a3
    80002baa:	040007b7          	lui	a5,0x4000
    80002bae:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bb0:	07b2                	slli	a5,a5,0xc
    80002bb2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb4:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bb8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bba:	18002673          	csrr	a2,satp
    80002bbe:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bc0:	7130                	ld	a2,96(a0)
    80002bc2:	6538                	ld	a4,72(a0)
    80002bc4:	6585                	lui	a1,0x1
    80002bc6:	972e                	add	a4,a4,a1
    80002bc8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bca:	7138                	ld	a4,96(a0)
    80002bcc:	00000617          	auipc	a2,0x0
    80002bd0:	13460613          	addi	a2,a2,308 # 80002d00 <usertrap>
    80002bd4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bd6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bd8:	8612                	mv	a2,tp
    80002bda:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002be0:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002be4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bec:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bee:	6f18                	ld	a4,24(a4)
    80002bf0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bf4:	6d28                	ld	a0,88(a0)
    80002bf6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002bf8:	00004717          	auipc	a4,0x4
    80002bfc:	4a470713          	addi	a4,a4,1188 # 8000709c <userret>
    80002c00:	8f15                	sub	a4,a4,a3
    80002c02:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c04:	577d                	li	a4,-1
    80002c06:	177e                	slli	a4,a4,0x3f
    80002c08:	8d59                	or	a0,a0,a4
    80002c0a:	9782                	jalr	a5
}
    80002c0c:	60a2                	ld	ra,8(sp)
    80002c0e:	6402                	ld	s0,0(sp)
    80002c10:	0141                	addi	sp,sp,16
    80002c12:	8082                	ret

0000000080002c14 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	e426                	sd	s1,8(sp)
    80002c1c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c1e:	00014497          	auipc	s1,0x14
    80002c22:	08248493          	addi	s1,s1,130 # 80016ca0 <tickslock>
    80002c26:	8526                	mv	a0,s1
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	faa080e7          	jalr	-86(ra) # 80000bd2 <acquire>
  ticks++;
    80002c30:	00006517          	auipc	a0,0x6
    80002c34:	dd050513          	addi	a0,a0,-560 # 80008a00 <ticks>
    80002c38:	411c                	lw	a5,0(a0)
    80002c3a:	2785                	addiw	a5,a5,1
    80002c3c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	80a080e7          	jalr	-2038(ra) # 80002448 <wakeup>
  release(&tickslock);
    80002c46:	8526                	mv	a0,s1
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	03e080e7          	jalr	62(ra) # 80000c86 <release>
}
    80002c50:	60e2                	ld	ra,24(sp)
    80002c52:	6442                	ld	s0,16(sp)
    80002c54:	64a2                	ld	s1,8(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret

0000000080002c5a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5a:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c5e:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002c60:	0807df63          	bgez	a5,80002cfe <devintr+0xa4>
{
    80002c64:	1101                	addi	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002c6e:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002c72:	46a5                	li	a3,9
    80002c74:	00d70d63          	beq	a4,a3,80002c8e <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002c78:	577d                	li	a4,-1
    80002c7a:	177e                	slli	a4,a4,0x3f
    80002c7c:	0705                	addi	a4,a4,1
    return 0;
    80002c7e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c80:	04e78e63          	beq	a5,a4,80002cdc <devintr+0x82>
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6105                	addi	sp,sp,32
    80002c8c:	8082                	ret
    int irq = plic_claim();
    80002c8e:	00003097          	auipc	ra,0x3
    80002c92:	4da080e7          	jalr	1242(ra) # 80006168 <plic_claim>
    80002c96:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c98:	47a9                	li	a5,10
    80002c9a:	02f50763          	beq	a0,a5,80002cc8 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002c9e:	4785                	li	a5,1
    80002ca0:	02f50963          	beq	a0,a5,80002cd2 <devintr+0x78>
    return 1;
    80002ca4:	4505                	li	a0,1
    } else if(irq){
    80002ca6:	dcf9                	beqz	s1,80002c84 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ca8:	85a6                	mv	a1,s1
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	72650513          	addi	a0,a0,1830 # 800083d0 <states.0+0x38>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8d4080e7          	jalr	-1836(ra) # 80000586 <printf>
      plic_complete(irq);
    80002cba:	8526                	mv	a0,s1
    80002cbc:	00003097          	auipc	ra,0x3
    80002cc0:	4d0080e7          	jalr	1232(ra) # 8000618c <plic_complete>
    return 1;
    80002cc4:	4505                	li	a0,1
    80002cc6:	bf7d                	j	80002c84 <devintr+0x2a>
      uartintr();
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	ccc080e7          	jalr	-820(ra) # 80000994 <uartintr>
    if(irq)
    80002cd0:	b7ed                	j	80002cba <devintr+0x60>
      virtio_disk_intr();
    80002cd2:	00004097          	auipc	ra,0x4
    80002cd6:	980080e7          	jalr	-1664(ra) # 80006652 <virtio_disk_intr>
    if(irq)
    80002cda:	b7c5                	j	80002cba <devintr+0x60>
    if(cpuid() == 0){
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	f74080e7          	jalr	-140(ra) # 80001c50 <cpuid>
    80002ce4:	c901                	beqz	a0,80002cf4 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ce6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cec:	14479073          	csrw	sip,a5
    return 2;
    80002cf0:	4509                	li	a0,2
    80002cf2:	bf49                	j	80002c84 <devintr+0x2a>
      clockintr();
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	f20080e7          	jalr	-224(ra) # 80002c14 <clockintr>
    80002cfc:	b7ed                	j	80002ce6 <devintr+0x8c>
}
    80002cfe:	8082                	ret

0000000080002d00 <usertrap>:
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	e426                	sd	s1,8(sp)
    80002d08:	e04a                	sd	s2,0(sp)
    80002d0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d10:	1007f793          	andi	a5,a5,256
    80002d14:	e3b1                	bnez	a5,80002d58 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d16:	00003797          	auipc	a5,0x3
    80002d1a:	34a78793          	addi	a5,a5,842 # 80006060 <kernelvec>
    80002d1e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	f5a080e7          	jalr	-166(ra) # 80001c7c <myproc>
    80002d2a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d2c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2e:	14102773          	csrr	a4,sepc
    80002d32:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d34:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d38:	47a1                	li	a5,8
    80002d3a:	02f70763          	beq	a4,a5,80002d68 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	f1c080e7          	jalr	-228(ra) # 80002c5a <devintr>
    80002d46:	892a                	mv	s2,a0
    80002d48:	c151                	beqz	a0,80002dcc <usertrap+0xcc>
  if(killed(p))
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	940080e7          	jalr	-1728(ra) # 8000268c <killed>
    80002d54:	c929                	beqz	a0,80002da6 <usertrap+0xa6>
    80002d56:	a099                	j	80002d9c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002d58:	00005517          	auipc	a0,0x5
    80002d5c:	69850513          	addi	a0,a0,1688 # 800083f0 <states.0+0x58>
    80002d60:	ffffd097          	auipc	ra,0xffffd
    80002d64:	7dc080e7          	jalr	2012(ra) # 8000053c <panic>
    if(killed(p))
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	924080e7          	jalr	-1756(ra) # 8000268c <killed>
    80002d70:	e921                	bnez	a0,80002dc0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002d72:	70b8                	ld	a4,96(s1)
    80002d74:	6f1c                	ld	a5,24(a4)
    80002d76:	0791                	addi	a5,a5,4
    80002d78:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d7e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d82:	10079073          	csrw	sstatus,a5
    syscall();
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	2d4080e7          	jalr	724(ra) # 8000305a <syscall>
  if(killed(p))
    80002d8e:	8526                	mv	a0,s1
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	8fc080e7          	jalr	-1796(ra) # 8000268c <killed>
    80002d98:	c911                	beqz	a0,80002dac <usertrap+0xac>
    80002d9a:	4901                	li	s2,0
    exit(-1);
    80002d9c:	557d                	li	a0,-1
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	77a080e7          	jalr	1914(ra) # 80002518 <exit>
  if(which_dev == 2)
    80002da6:	4789                	li	a5,2
    80002da8:	04f90f63          	beq	s2,a5,80002e06 <usertrap+0x106>
  usertrapret();
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	dd2080e7          	jalr	-558(ra) # 80002b7e <usertrapret>
}
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	64a2                	ld	s1,8(sp)
    80002dba:	6902                	ld	s2,0(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret
      exit(-1);
    80002dc0:	557d                	li	a0,-1
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	756080e7          	jalr	1878(ra) # 80002518 <exit>
    80002dca:	b765                	j	80002d72 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dcc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dd0:	5890                	lw	a2,48(s1)
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	63e50513          	addi	a0,a0,1598 # 80008410 <states.0+0x78>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	7ac080e7          	jalr	1964(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002de6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dea:	00005517          	auipc	a0,0x5
    80002dee:	65650513          	addi	a0,a0,1622 # 80008440 <states.0+0xa8>
    80002df2:	ffffd097          	auipc	ra,0xffffd
    80002df6:	794080e7          	jalr	1940(ra) # 80000586 <printf>
    setkilled(p);
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	864080e7          	jalr	-1948(ra) # 80002660 <setkilled>
    80002e04:	b769                	j	80002d8e <usertrap+0x8e>
    yield();
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	5a2080e7          	jalr	1442(ra) # 800023a8 <yield>
    80002e0e:	bf79                	j	80002dac <usertrap+0xac>

0000000080002e10 <kerneltrap>:
{
    80002e10:	7179                	addi	sp,sp,-48
    80002e12:	f406                	sd	ra,40(sp)
    80002e14:	f022                	sd	s0,32(sp)
    80002e16:	ec26                	sd	s1,24(sp)
    80002e18:	e84a                	sd	s2,16(sp)
    80002e1a:	e44e                	sd	s3,8(sp)
    80002e1c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e1e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e22:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e26:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e2a:	1004f793          	andi	a5,s1,256
    80002e2e:	cb85                	beqz	a5,80002e5e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e30:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e34:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e36:	ef85                	bnez	a5,80002e6e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	e22080e7          	jalr	-478(ra) # 80002c5a <devintr>
    80002e40:	cd1d                	beqz	a0,80002e7e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e42:	4789                	li	a5,2
    80002e44:	06f50a63          	beq	a0,a5,80002eb8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e48:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e4c:	10049073          	csrw	sstatus,s1
}
    80002e50:	70a2                	ld	ra,40(sp)
    80002e52:	7402                	ld	s0,32(sp)
    80002e54:	64e2                	ld	s1,24(sp)
    80002e56:	6942                	ld	s2,16(sp)
    80002e58:	69a2                	ld	s3,8(sp)
    80002e5a:	6145                	addi	sp,sp,48
    80002e5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	60250513          	addi	a0,a0,1538 # 80008460 <states.0+0xc8>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	6d6080e7          	jalr	1750(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	61a50513          	addi	a0,a0,1562 # 80008488 <states.0+0xf0>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	6c6080e7          	jalr	1734(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e7e:	85ce                	mv	a1,s3
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	62850513          	addi	a0,a0,1576 # 800084a8 <states.0+0x110>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	6fe080e7          	jalr	1790(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	62050513          	addi	a0,a0,1568 # 800084b8 <states.0+0x120>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	6e6080e7          	jalr	1766(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	62850513          	addi	a0,a0,1576 # 800084d0 <states.0+0x138>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	68c080e7          	jalr	1676(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	dc4080e7          	jalr	-572(ra) # 80001c7c <myproc>
    80002ec0:	d541                	beqz	a0,80002e48 <kerneltrap+0x38>
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	dba080e7          	jalr	-582(ra) # 80001c7c <myproc>
    80002eca:	4d18                	lw	a4,24(a0)
    80002ecc:	4791                	li	a5,4
    80002ece:	f6f71de3          	bne	a4,a5,80002e48 <kerneltrap+0x38>
    yield();
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	4d6080e7          	jalr	1238(ra) # 800023a8 <yield>
    80002eda:	b7bd                	j	80002e48 <kerneltrap+0x38>

0000000080002edc <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	1000                	addi	s0,sp,32
    80002ee6:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	d94080e7          	jalr	-620(ra) # 80001c7c <myproc>
    switch (n)
    80002ef0:	4795                	li	a5,5
    80002ef2:	0497e163          	bltu	a5,s1,80002f34 <argraw+0x58>
    80002ef6:	048a                	slli	s1,s1,0x2
    80002ef8:	00005717          	auipc	a4,0x5
    80002efc:	61070713          	addi	a4,a4,1552 # 80008508 <states.0+0x170>
    80002f00:	94ba                	add	s1,s1,a4
    80002f02:	409c                	lw	a5,0(s1)
    80002f04:	97ba                	add	a5,a5,a4
    80002f06:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f08:	713c                	ld	a5,96(a0)
    80002f0a:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f0c:	60e2                	ld	ra,24(sp)
    80002f0e:	6442                	ld	s0,16(sp)
    80002f10:	64a2                	ld	s1,8(sp)
    80002f12:	6105                	addi	sp,sp,32
    80002f14:	8082                	ret
        return p->trapframe->a1;
    80002f16:	713c                	ld	a5,96(a0)
    80002f18:	7fa8                	ld	a0,120(a5)
    80002f1a:	bfcd                	j	80002f0c <argraw+0x30>
        return p->trapframe->a2;
    80002f1c:	713c                	ld	a5,96(a0)
    80002f1e:	63c8                	ld	a0,128(a5)
    80002f20:	b7f5                	j	80002f0c <argraw+0x30>
        return p->trapframe->a3;
    80002f22:	713c                	ld	a5,96(a0)
    80002f24:	67c8                	ld	a0,136(a5)
    80002f26:	b7dd                	j	80002f0c <argraw+0x30>
        return p->trapframe->a4;
    80002f28:	713c                	ld	a5,96(a0)
    80002f2a:	6bc8                	ld	a0,144(a5)
    80002f2c:	b7c5                	j	80002f0c <argraw+0x30>
        return p->trapframe->a5;
    80002f2e:	713c                	ld	a5,96(a0)
    80002f30:	6fc8                	ld	a0,152(a5)
    80002f32:	bfe9                	j	80002f0c <argraw+0x30>
    panic("argraw");
    80002f34:	00005517          	auipc	a0,0x5
    80002f38:	5ac50513          	addi	a0,a0,1452 # 800084e0 <states.0+0x148>
    80002f3c:	ffffd097          	auipc	ra,0xffffd
    80002f40:	600080e7          	jalr	1536(ra) # 8000053c <panic>

0000000080002f44 <fetchaddr>:
{
    80002f44:	1101                	addi	sp,sp,-32
    80002f46:	ec06                	sd	ra,24(sp)
    80002f48:	e822                	sd	s0,16(sp)
    80002f4a:	e426                	sd	s1,8(sp)
    80002f4c:	e04a                	sd	s2,0(sp)
    80002f4e:	1000                	addi	s0,sp,32
    80002f50:	84aa                	mv	s1,a0
    80002f52:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	d28080e7          	jalr	-728(ra) # 80001c7c <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f5c:	693c                	ld	a5,80(a0)
    80002f5e:	02f4f863          	bgeu	s1,a5,80002f8e <fetchaddr+0x4a>
    80002f62:	00848713          	addi	a4,s1,8
    80002f66:	02e7e663          	bltu	a5,a4,80002f92 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f6a:	46a1                	li	a3,8
    80002f6c:	8626                	mv	a2,s1
    80002f6e:	85ca                	mv	a1,s2
    80002f70:	6d28                	ld	a0,88(a0)
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	780080e7          	jalr	1920(ra) # 800016f2 <copyin>
    80002f7a:	00a03533          	snez	a0,a0
    80002f7e:	40a00533          	neg	a0,a0
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	64a2                	ld	s1,8(sp)
    80002f88:	6902                	ld	s2,0(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret
        return -1;
    80002f8e:	557d                	li	a0,-1
    80002f90:	bfcd                	j	80002f82 <fetchaddr+0x3e>
    80002f92:	557d                	li	a0,-1
    80002f94:	b7fd                	j	80002f82 <fetchaddr+0x3e>

0000000080002f96 <fetchstr>:
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	892a                	mv	s2,a0
    80002fa6:	84ae                	mv	s1,a1
    80002fa8:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	cd2080e7          	jalr	-814(ra) # 80001c7c <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fb2:	86ce                	mv	a3,s3
    80002fb4:	864a                	mv	a2,s2
    80002fb6:	85a6                	mv	a1,s1
    80002fb8:	6d28                	ld	a0,88(a0)
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	7c6080e7          	jalr	1990(ra) # 80001780 <copyinstr>
    80002fc2:	00054e63          	bltz	a0,80002fde <fetchstr+0x48>
    return strlen(buf);
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	e80080e7          	jalr	-384(ra) # 80000e48 <strlen>
}
    80002fd0:	70a2                	ld	ra,40(sp)
    80002fd2:	7402                	ld	s0,32(sp)
    80002fd4:	64e2                	ld	s1,24(sp)
    80002fd6:	6942                	ld	s2,16(sp)
    80002fd8:	69a2                	ld	s3,8(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret
        return -1;
    80002fde:	557d                	li	a0,-1
    80002fe0:	bfc5                	j	80002fd0 <fetchstr+0x3a>

0000000080002fe2 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	1000                	addi	s0,sp,32
    80002fec:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	eee080e7          	jalr	-274(ra) # 80002edc <argraw>
    80002ff6:	c088                	sw	a0,0(s1)
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	64a2                	ld	s1,8(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret

0000000080003002 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	ece080e7          	jalr	-306(ra) # 80002edc <argraw>
    80003016:	e088                	sd	a0,0(s1)
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003022:	7179                	addi	sp,sp,-48
    80003024:	f406                	sd	ra,40(sp)
    80003026:	f022                	sd	s0,32(sp)
    80003028:	ec26                	sd	s1,24(sp)
    8000302a:	e84a                	sd	s2,16(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	84ae                	mv	s1,a1
    80003030:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003032:	fd840593          	addi	a1,s0,-40
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	fcc080e7          	jalr	-52(ra) # 80003002 <argaddr>
    return fetchstr(addr, buf, max);
    8000303e:	864a                	mv	a2,s2
    80003040:	85a6                	mv	a1,s1
    80003042:	fd843503          	ld	a0,-40(s0)
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	f50080e7          	jalr	-176(ra) # 80002f96 <fetchstr>
}
    8000304e:	70a2                	ld	ra,40(sp)
    80003050:	7402                	ld	s0,32(sp)
    80003052:	64e2                	ld	s1,24(sp)
    80003054:	6942                	ld	s2,16(sp)
    80003056:	6145                	addi	sp,sp,48
    80003058:	8082                	ret

000000008000305a <syscall>:
    [SYS_schedls] sys_schedls,
    [SYS_schedset] sys_schedset,
};

void syscall(void)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	e04a                	sd	s2,0(sp)
    80003064:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	c16080e7          	jalr	-1002(ra) # 80001c7c <myproc>
    8000306e:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003070:	06053903          	ld	s2,96(a0)
    80003074:	0a893783          	ld	a5,168(s2)
    80003078:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000307c:	37fd                	addiw	a5,a5,-1
    8000307e:	475d                	li	a4,23
    80003080:	00f76f63          	bltu	a4,a5,8000309e <syscall+0x44>
    80003084:	00369713          	slli	a4,a3,0x3
    80003088:	00005797          	auipc	a5,0x5
    8000308c:	49878793          	addi	a5,a5,1176 # 80008520 <syscalls>
    80003090:	97ba                	add	a5,a5,a4
    80003092:	639c                	ld	a5,0(a5)
    80003094:	c789                	beqz	a5,8000309e <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80003096:	9782                	jalr	a5
    80003098:	06a93823          	sd	a0,112(s2)
    8000309c:	a839                	j	800030ba <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    8000309e:	16048613          	addi	a2,s1,352
    800030a2:	588c                	lw	a1,48(s1)
    800030a4:	00005517          	auipc	a0,0x5
    800030a8:	44450513          	addi	a0,a0,1092 # 800084e8 <states.0+0x150>
    800030ac:	ffffd097          	auipc	ra,0xffffd
    800030b0:	4da080e7          	jalr	1242(ra) # 80000586 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030b4:	70bc                	ld	a5,96(s1)
    800030b6:	577d                	li	a4,-1
    800030b8:	fbb8                	sd	a4,112(a5)
    }
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6902                	ld	s2,0(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030ce:	fec40593          	addi	a1,s0,-20
    800030d2:	4501                	li	a0,0
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	f0e080e7          	jalr	-242(ra) # 80002fe2 <argint>
    exit(n);
    800030dc:	fec42503          	lw	a0,-20(s0)
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	438080e7          	jalr	1080(ra) # 80002518 <exit>
    return 0; // not reached
}
    800030e8:	4501                	li	a0,0
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030f2:	1141                	addi	sp,sp,-16
    800030f4:	e406                	sd	ra,8(sp)
    800030f6:	e022                	sd	s0,0(sp)
    800030f8:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	b82080e7          	jalr	-1150(ra) # 80001c7c <myproc>
}
    80003102:	5908                	lw	a0,48(a0)
    80003104:	60a2                	ld	ra,8(sp)
    80003106:	6402                	ld	s0,0(sp)
    80003108:	0141                	addi	sp,sp,16
    8000310a:	8082                	ret

000000008000310c <sys_fork>:

uint64
sys_fork(void)
{
    8000310c:	1141                	addi	sp,sp,-16
    8000310e:	e406                	sd	ra,8(sp)
    80003110:	e022                	sd	s0,0(sp)
    80003112:	0800                	addi	s0,sp,16
    return fork();
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	06e080e7          	jalr	110(ra) # 80002182 <fork>
}
    8000311c:	60a2                	ld	ra,8(sp)
    8000311e:	6402                	ld	s0,0(sp)
    80003120:	0141                	addi	sp,sp,16
    80003122:	8082                	ret

0000000080003124 <sys_wait>:

uint64
sys_wait(void)
{
    80003124:	1101                	addi	sp,sp,-32
    80003126:	ec06                	sd	ra,24(sp)
    80003128:	e822                	sd	s0,16(sp)
    8000312a:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000312c:	fe840593          	addi	a1,s0,-24
    80003130:	4501                	li	a0,0
    80003132:	00000097          	auipc	ra,0x0
    80003136:	ed0080e7          	jalr	-304(ra) # 80003002 <argaddr>
    return wait(p);
    8000313a:	fe843503          	ld	a0,-24(s0)
    8000313e:	fffff097          	auipc	ra,0xfffff
    80003142:	580080e7          	jalr	1408(ra) # 800026be <wait>
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000314e:	7179                	addi	sp,sp,-48
    80003150:	f406                	sd	ra,40(sp)
    80003152:	f022                	sd	s0,32(sp)
    80003154:	ec26                	sd	s1,24(sp)
    80003156:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003158:	fdc40593          	addi	a1,s0,-36
    8000315c:	4501                	li	a0,0
    8000315e:	00000097          	auipc	ra,0x0
    80003162:	e84080e7          	jalr	-380(ra) # 80002fe2 <argint>
    addr = myproc()->sz;
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	b16080e7          	jalr	-1258(ra) # 80001c7c <myproc>
    8000316e:	6924                	ld	s1,80(a0)
    if (growproc(n) < 0)
    80003170:	fdc42503          	lw	a0,-36(s0)
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	e62080e7          	jalr	-414(ra) # 80001fd6 <growproc>
    8000317c:	00054863          	bltz	a0,8000318c <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003180:	8526                	mv	a0,s1
    80003182:	70a2                	ld	ra,40(sp)
    80003184:	7402                	ld	s0,32(sp)
    80003186:	64e2                	ld	s1,24(sp)
    80003188:	6145                	addi	sp,sp,48
    8000318a:	8082                	ret
        return -1;
    8000318c:	54fd                	li	s1,-1
    8000318e:	bfcd                	j	80003180 <sys_sbrk+0x32>

0000000080003190 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003190:	7139                	addi	sp,sp,-64
    80003192:	fc06                	sd	ra,56(sp)
    80003194:	f822                	sd	s0,48(sp)
    80003196:	f426                	sd	s1,40(sp)
    80003198:	f04a                	sd	s2,32(sp)
    8000319a:	ec4e                	sd	s3,24(sp)
    8000319c:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    8000319e:	fcc40593          	addi	a1,s0,-52
    800031a2:	4501                	li	a0,0
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	e3e080e7          	jalr	-450(ra) # 80002fe2 <argint>
    acquire(&tickslock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	af450513          	addi	a0,a0,-1292 # 80016ca0 <tickslock>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a1e080e7          	jalr	-1506(ra) # 80000bd2 <acquire>
    ticks0 = ticks;
    800031bc:	00006917          	auipc	s2,0x6
    800031c0:	84492903          	lw	s2,-1980(s2) # 80008a00 <ticks>
    while (ticks - ticks0 < n)
    800031c4:	fcc42783          	lw	a5,-52(s0)
    800031c8:	cf9d                	beqz	a5,80003206 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031ca:	00014997          	auipc	s3,0x14
    800031ce:	ad698993          	addi	s3,s3,-1322 # 80016ca0 <tickslock>
    800031d2:	00006497          	auipc	s1,0x6
    800031d6:	82e48493          	addi	s1,s1,-2002 # 80008a00 <ticks>
        if (killed(myproc()))
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	aa2080e7          	jalr	-1374(ra) # 80001c7c <myproc>
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	4aa080e7          	jalr	1194(ra) # 8000268c <killed>
    800031ea:	ed15                	bnez	a0,80003226 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031ec:	85ce                	mv	a1,s3
    800031ee:	8526                	mv	a0,s1
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	1f4080e7          	jalr	500(ra) # 800023e4 <sleep>
    while (ticks - ticks0 < n)
    800031f8:	409c                	lw	a5,0(s1)
    800031fa:	412787bb          	subw	a5,a5,s2
    800031fe:	fcc42703          	lw	a4,-52(s0)
    80003202:	fce7ece3          	bltu	a5,a4,800031da <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003206:	00014517          	auipc	a0,0x14
    8000320a:	a9a50513          	addi	a0,a0,-1382 # 80016ca0 <tickslock>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a78080e7          	jalr	-1416(ra) # 80000c86 <release>
    return 0;
    80003216:	4501                	li	a0,0
}
    80003218:	70e2                	ld	ra,56(sp)
    8000321a:	7442                	ld	s0,48(sp)
    8000321c:	74a2                	ld	s1,40(sp)
    8000321e:	7902                	ld	s2,32(sp)
    80003220:	69e2                	ld	s3,24(sp)
    80003222:	6121                	addi	sp,sp,64
    80003224:	8082                	ret
            release(&tickslock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	a7a50513          	addi	a0,a0,-1414 # 80016ca0 <tickslock>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	a58080e7          	jalr	-1448(ra) # 80000c86 <release>
            return -1;
    80003236:	557d                	li	a0,-1
    80003238:	b7c5                	j	80003218 <sys_sleep+0x88>

000000008000323a <sys_kill>:

uint64
sys_kill(void)
{
    8000323a:	1101                	addi	sp,sp,-32
    8000323c:	ec06                	sd	ra,24(sp)
    8000323e:	e822                	sd	s0,16(sp)
    80003240:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003242:	fec40593          	addi	a1,s0,-20
    80003246:	4501                	li	a0,0
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	d9a080e7          	jalr	-614(ra) # 80002fe2 <argint>
    return kill(pid);
    80003250:	fec42503          	lw	a0,-20(s0)
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	39a080e7          	jalr	922(ra) # 800025ee <kill>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	6105                	addi	sp,sp,32
    80003262:	8082                	ret

0000000080003264 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	e426                	sd	s1,8(sp)
    8000326c:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    8000326e:	00014517          	auipc	a0,0x14
    80003272:	a3250513          	addi	a0,a0,-1486 # 80016ca0 <tickslock>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	95c080e7          	jalr	-1700(ra) # 80000bd2 <acquire>
    xticks = ticks;
    8000327e:	00005497          	auipc	s1,0x5
    80003282:	7824a483          	lw	s1,1922(s1) # 80008a00 <ticks>
    release(&tickslock);
    80003286:	00014517          	auipc	a0,0x14
    8000328a:	a1a50513          	addi	a0,a0,-1510 # 80016ca0 <tickslock>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	9f8080e7          	jalr	-1544(ra) # 80000c86 <release>
    return xticks;
}
    80003296:	02049513          	slli	a0,s1,0x20
    8000329a:	9101                	srli	a0,a0,0x20
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret

00000000800032a6 <sys_ps>:

void *
sys_ps(void)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032ae:	fe042623          	sw	zero,-20(s0)
    800032b2:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032b6:	fec40593          	addi	a1,s0,-20
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	d26080e7          	jalr	-730(ra) # 80002fe2 <argint>
    argint(1, &count);
    800032c4:	fe840593          	addi	a1,s0,-24
    800032c8:	4505                	li	a0,1
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	d18080e7          	jalr	-744(ra) # 80002fe2 <argint>
    return ps((uint8)start, (uint8)count);
    800032d2:	fe844583          	lbu	a1,-24(s0)
    800032d6:	fec44503          	lbu	a0,-20(s0)
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	d58080e7          	jalr	-680(ra) # 80002032 <ps>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <sys_schedls>:

uint64 sys_schedls(void)
{
    800032ea:	1141                	addi	sp,sp,-16
    800032ec:	e406                	sd	ra,8(sp)
    800032ee:	e022                	sd	s0,0(sp)
    800032f0:	0800                	addi	s0,sp,16
    schedls();
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	656080e7          	jalr	1622(ra) # 80002948 <schedls>
    return 0;
}
    800032fa:	4501                	li	a0,0
    800032fc:	60a2                	ld	ra,8(sp)
    800032fe:	6402                	ld	s0,0(sp)
    80003300:	0141                	addi	sp,sp,16
    80003302:	8082                	ret

0000000080003304 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003304:	1101                	addi	sp,sp,-32
    80003306:	ec06                	sd	ra,24(sp)
    80003308:	e822                	sd	s0,16(sp)
    8000330a:	1000                	addi	s0,sp,32
    int id = 0;
    8000330c:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003310:	fec40593          	addi	a1,s0,-20
    80003314:	4501                	li	a0,0
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	ccc080e7          	jalr	-820(ra) # 80002fe2 <argint>
    schedset(id - 1);
    8000331e:	fec42503          	lw	a0,-20(s0)
    80003322:	357d                	addiw	a0,a0,-1
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	710080e7          	jalr	1808(ra) # 80002a34 <schedset>
    return 0;
    8000332c:	4501                	li	a0,0
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret

0000000080003336 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	e052                	sd	s4,0(sp)
    80003344:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003346:	00005597          	auipc	a1,0x5
    8000334a:	2a258593          	addi	a1,a1,674 # 800085e8 <syscalls+0xc8>
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	96a50513          	addi	a0,a0,-1686 # 80016cb8 <bcache>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	7ec080e7          	jalr	2028(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000335e:	0001c797          	auipc	a5,0x1c
    80003362:	95a78793          	addi	a5,a5,-1702 # 8001ecb8 <bcache+0x8000>
    80003366:	0001c717          	auipc	a4,0x1c
    8000336a:	bba70713          	addi	a4,a4,-1094 # 8001ef20 <bcache+0x8268>
    8000336e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003372:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003376:	00014497          	auipc	s1,0x14
    8000337a:	95a48493          	addi	s1,s1,-1702 # 80016cd0 <bcache+0x18>
    b->next = bcache.head.next;
    8000337e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003380:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003382:	00005a17          	auipc	s4,0x5
    80003386:	26ea0a13          	addi	s4,s4,622 # 800085f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000338a:	2b893783          	ld	a5,696(s2)
    8000338e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003390:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003394:	85d2                	mv	a1,s4
    80003396:	01048513          	addi	a0,s1,16
    8000339a:	00001097          	auipc	ra,0x1
    8000339e:	496080e7          	jalr	1174(ra) # 80004830 <initsleeplock>
    bcache.head.next->prev = b;
    800033a2:	2b893783          	ld	a5,696(s2)
    800033a6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033a8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ac:	45848493          	addi	s1,s1,1112
    800033b0:	fd349de3          	bne	s1,s3,8000338a <binit+0x54>
  }
}
    800033b4:	70a2                	ld	ra,40(sp)
    800033b6:	7402                	ld	s0,32(sp)
    800033b8:	64e2                	ld	s1,24(sp)
    800033ba:	6942                	ld	s2,16(sp)
    800033bc:	69a2                	ld	s3,8(sp)
    800033be:	6a02                	ld	s4,0(sp)
    800033c0:	6145                	addi	sp,sp,48
    800033c2:	8082                	ret

00000000800033c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	e84a                	sd	s2,16(sp)
    800033ce:	e44e                	sd	s3,8(sp)
    800033d0:	1800                	addi	s0,sp,48
    800033d2:	892a                	mv	s2,a0
    800033d4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	8e250513          	addi	a0,a0,-1822 # 80016cb8 <bcache>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	7f4080e7          	jalr	2036(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033e6:	0001c497          	auipc	s1,0x1c
    800033ea:	b8a4b483          	ld	s1,-1142(s1) # 8001ef70 <bcache+0x82b8>
    800033ee:	0001c797          	auipc	a5,0x1c
    800033f2:	b3278793          	addi	a5,a5,-1230 # 8001ef20 <bcache+0x8268>
    800033f6:	02f48f63          	beq	s1,a5,80003434 <bread+0x70>
    800033fa:	873e                	mv	a4,a5
    800033fc:	a021                	j	80003404 <bread+0x40>
    800033fe:	68a4                	ld	s1,80(s1)
    80003400:	02e48a63          	beq	s1,a4,80003434 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003404:	449c                	lw	a5,8(s1)
    80003406:	ff279ce3          	bne	a5,s2,800033fe <bread+0x3a>
    8000340a:	44dc                	lw	a5,12(s1)
    8000340c:	ff3799e3          	bne	a5,s3,800033fe <bread+0x3a>
      b->refcnt++;
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	2785                	addiw	a5,a5,1
    80003414:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	8a250513          	addi	a0,a0,-1886 # 80016cb8 <bcache>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	868080e7          	jalr	-1944(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003426:	01048513          	addi	a0,s1,16
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	440080e7          	jalr	1088(ra) # 8000486a <acquiresleep>
      return b;
    80003432:	a8b9                	j	80003490 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003434:	0001c497          	auipc	s1,0x1c
    80003438:	b344b483          	ld	s1,-1228(s1) # 8001ef68 <bcache+0x82b0>
    8000343c:	0001c797          	auipc	a5,0x1c
    80003440:	ae478793          	addi	a5,a5,-1308 # 8001ef20 <bcache+0x8268>
    80003444:	00f48863          	beq	s1,a5,80003454 <bread+0x90>
    80003448:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000344a:	40bc                	lw	a5,64(s1)
    8000344c:	cf81                	beqz	a5,80003464 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000344e:	64a4                	ld	s1,72(s1)
    80003450:	fee49de3          	bne	s1,a4,8000344a <bread+0x86>
  panic("bget: no buffers");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	1a450513          	addi	a0,a0,420 # 800085f8 <syscalls+0xd8>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0e0080e7          	jalr	224(ra) # 8000053c <panic>
      b->dev = dev;
    80003464:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003468:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000346c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003470:	4785                	li	a5,1
    80003472:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003474:	00014517          	auipc	a0,0x14
    80003478:	84450513          	addi	a0,a0,-1980 # 80016cb8 <bcache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	80a080e7          	jalr	-2038(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003484:	01048513          	addi	a0,s1,16
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	3e2080e7          	jalr	994(ra) # 8000486a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003490:	409c                	lw	a5,0(s1)
    80003492:	cb89                	beqz	a5,800034a4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003494:	8526                	mv	a0,s1
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6942                	ld	s2,16(sp)
    8000349e:	69a2                	ld	s3,8(sp)
    800034a0:	6145                	addi	sp,sp,48
    800034a2:	8082                	ret
    virtio_disk_rw(b, 0);
    800034a4:	4581                	li	a1,0
    800034a6:	8526                	mv	a0,s1
    800034a8:	00003097          	auipc	ra,0x3
    800034ac:	f7a080e7          	jalr	-134(ra) # 80006422 <virtio_disk_rw>
    b->valid = 1;
    800034b0:	4785                	li	a5,1
    800034b2:	c09c                	sw	a5,0(s1)
  return b;
    800034b4:	b7c5                	j	80003494 <bread+0xd0>

00000000800034b6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c2:	0541                	addi	a0,a0,16
    800034c4:	00001097          	auipc	ra,0x1
    800034c8:	440080e7          	jalr	1088(ra) # 80004904 <holdingsleep>
    800034cc:	cd01                	beqz	a0,800034e4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034ce:	4585                	li	a1,1
    800034d0:	8526                	mv	a0,s1
    800034d2:	00003097          	auipc	ra,0x3
    800034d6:	f50080e7          	jalr	-176(ra) # 80006422 <virtio_disk_rw>
}
    800034da:	60e2                	ld	ra,24(sp)
    800034dc:	6442                	ld	s0,16(sp)
    800034de:	64a2                	ld	s1,8(sp)
    800034e0:	6105                	addi	sp,sp,32
    800034e2:	8082                	ret
    panic("bwrite");
    800034e4:	00005517          	auipc	a0,0x5
    800034e8:	12c50513          	addi	a0,a0,300 # 80008610 <syscalls+0xf0>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	050080e7          	jalr	80(ra) # 8000053c <panic>

00000000800034f4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034f4:	1101                	addi	sp,sp,-32
    800034f6:	ec06                	sd	ra,24(sp)
    800034f8:	e822                	sd	s0,16(sp)
    800034fa:	e426                	sd	s1,8(sp)
    800034fc:	e04a                	sd	s2,0(sp)
    800034fe:	1000                	addi	s0,sp,32
    80003500:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003502:	01050913          	addi	s2,a0,16
    80003506:	854a                	mv	a0,s2
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	3fc080e7          	jalr	1020(ra) # 80004904 <holdingsleep>
    80003510:	c925                	beqz	a0,80003580 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003512:	854a                	mv	a0,s2
    80003514:	00001097          	auipc	ra,0x1
    80003518:	3ac080e7          	jalr	940(ra) # 800048c0 <releasesleep>

  acquire(&bcache.lock);
    8000351c:	00013517          	auipc	a0,0x13
    80003520:	79c50513          	addi	a0,a0,1948 # 80016cb8 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6ae080e7          	jalr	1710(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000352c:	40bc                	lw	a5,64(s1)
    8000352e:	37fd                	addiw	a5,a5,-1
    80003530:	0007871b          	sext.w	a4,a5
    80003534:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003536:	e71d                	bnez	a4,80003564 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003538:	68b8                	ld	a4,80(s1)
    8000353a:	64bc                	ld	a5,72(s1)
    8000353c:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000353e:	68b8                	ld	a4,80(s1)
    80003540:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003542:	0001b797          	auipc	a5,0x1b
    80003546:	77678793          	addi	a5,a5,1910 # 8001ecb8 <bcache+0x8000>
    8000354a:	2b87b703          	ld	a4,696(a5)
    8000354e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003550:	0001c717          	auipc	a4,0x1c
    80003554:	9d070713          	addi	a4,a4,-1584 # 8001ef20 <bcache+0x8268>
    80003558:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000355a:	2b87b703          	ld	a4,696(a5)
    8000355e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003560:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003564:	00013517          	auipc	a0,0x13
    80003568:	75450513          	addi	a0,a0,1876 # 80016cb8 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	71a080e7          	jalr	1818(ra) # 80000c86 <release>
}
    80003574:	60e2                	ld	ra,24(sp)
    80003576:	6442                	ld	s0,16(sp)
    80003578:	64a2                	ld	s1,8(sp)
    8000357a:	6902                	ld	s2,0(sp)
    8000357c:	6105                	addi	sp,sp,32
    8000357e:	8082                	ret
    panic("brelse");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	09850513          	addi	a0,a0,152 # 80008618 <syscalls+0xf8>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fb4080e7          	jalr	-76(ra) # 8000053c <panic>

0000000080003590 <bpin>:

void
bpin(struct buf *b) {
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	1000                	addi	s0,sp,32
    8000359a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000359c:	00013517          	auipc	a0,0x13
    800035a0:	71c50513          	addi	a0,a0,1820 # 80016cb8 <bcache>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	62e080e7          	jalr	1582(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800035ac:	40bc                	lw	a5,64(s1)
    800035ae:	2785                	addiw	a5,a5,1
    800035b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b2:	00013517          	auipc	a0,0x13
    800035b6:	70650513          	addi	a0,a0,1798 # 80016cb8 <bcache>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	6cc080e7          	jalr	1740(ra) # 80000c86 <release>
}
    800035c2:	60e2                	ld	ra,24(sp)
    800035c4:	6442                	ld	s0,16(sp)
    800035c6:	64a2                	ld	s1,8(sp)
    800035c8:	6105                	addi	sp,sp,32
    800035ca:	8082                	ret

00000000800035cc <bunpin>:

void
bunpin(struct buf *b) {
    800035cc:	1101                	addi	sp,sp,-32
    800035ce:	ec06                	sd	ra,24(sp)
    800035d0:	e822                	sd	s0,16(sp)
    800035d2:	e426                	sd	s1,8(sp)
    800035d4:	1000                	addi	s0,sp,32
    800035d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035d8:	00013517          	auipc	a0,0x13
    800035dc:	6e050513          	addi	a0,a0,1760 # 80016cb8 <bcache>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	5f2080e7          	jalr	1522(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800035e8:	40bc                	lw	a5,64(s1)
    800035ea:	37fd                	addiw	a5,a5,-1
    800035ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035ee:	00013517          	auipc	a0,0x13
    800035f2:	6ca50513          	addi	a0,a0,1738 # 80016cb8 <bcache>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	690080e7          	jalr	1680(ra) # 80000c86 <release>
}
    800035fe:	60e2                	ld	ra,24(sp)
    80003600:	6442                	ld	s0,16(sp)
    80003602:	64a2                	ld	s1,8(sp)
    80003604:	6105                	addi	sp,sp,32
    80003606:	8082                	ret

0000000080003608 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	e426                	sd	s1,8(sp)
    80003610:	e04a                	sd	s2,0(sp)
    80003612:	1000                	addi	s0,sp,32
    80003614:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003616:	00d5d59b          	srliw	a1,a1,0xd
    8000361a:	0001c797          	auipc	a5,0x1c
    8000361e:	d7a7a783          	lw	a5,-646(a5) # 8001f394 <sb+0x1c>
    80003622:	9dbd                	addw	a1,a1,a5
    80003624:	00000097          	auipc	ra,0x0
    80003628:	da0080e7          	jalr	-608(ra) # 800033c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000362c:	0074f713          	andi	a4,s1,7
    80003630:	4785                	li	a5,1
    80003632:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003636:	14ce                	slli	s1,s1,0x33
    80003638:	90d9                	srli	s1,s1,0x36
    8000363a:	00950733          	add	a4,a0,s1
    8000363e:	05874703          	lbu	a4,88(a4)
    80003642:	00e7f6b3          	and	a3,a5,a4
    80003646:	c69d                	beqz	a3,80003674 <bfree+0x6c>
    80003648:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000364a:	94aa                	add	s1,s1,a0
    8000364c:	fff7c793          	not	a5,a5
    80003650:	8f7d                	and	a4,a4,a5
    80003652:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003656:	00001097          	auipc	ra,0x1
    8000365a:	0f6080e7          	jalr	246(ra) # 8000474c <log_write>
  brelse(bp);
    8000365e:	854a                	mv	a0,s2
    80003660:	00000097          	auipc	ra,0x0
    80003664:	e94080e7          	jalr	-364(ra) # 800034f4 <brelse>
}
    80003668:	60e2                	ld	ra,24(sp)
    8000366a:	6442                	ld	s0,16(sp)
    8000366c:	64a2                	ld	s1,8(sp)
    8000366e:	6902                	ld	s2,0(sp)
    80003670:	6105                	addi	sp,sp,32
    80003672:	8082                	ret
    panic("freeing free block");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	fac50513          	addi	a0,a0,-84 # 80008620 <syscalls+0x100>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec0080e7          	jalr	-320(ra) # 8000053c <panic>

0000000080003684 <balloc>:
{
    80003684:	711d                	addi	sp,sp,-96
    80003686:	ec86                	sd	ra,88(sp)
    80003688:	e8a2                	sd	s0,80(sp)
    8000368a:	e4a6                	sd	s1,72(sp)
    8000368c:	e0ca                	sd	s2,64(sp)
    8000368e:	fc4e                	sd	s3,56(sp)
    80003690:	f852                	sd	s4,48(sp)
    80003692:	f456                	sd	s5,40(sp)
    80003694:	f05a                	sd	s6,32(sp)
    80003696:	ec5e                	sd	s7,24(sp)
    80003698:	e862                	sd	s8,16(sp)
    8000369a:	e466                	sd	s9,8(sp)
    8000369c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000369e:	0001c797          	auipc	a5,0x1c
    800036a2:	cde7a783          	lw	a5,-802(a5) # 8001f37c <sb+0x4>
    800036a6:	cff5                	beqz	a5,800037a2 <balloc+0x11e>
    800036a8:	8baa                	mv	s7,a0
    800036aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036ac:	0001cb17          	auipc	s6,0x1c
    800036b0:	cccb0b13          	addi	s6,s6,-820 # 8001f378 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036ba:	6c89                	lui	s9,0x2
    800036bc:	a061                	j	80003744 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036be:	97ca                	add	a5,a5,s2
    800036c0:	8e55                	or	a2,a2,a3
    800036c2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	084080e7          	jalr	132(ra) # 8000474c <log_write>
        brelse(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	e22080e7          	jalr	-478(ra) # 800034f4 <brelse>
  bp = bread(dev, bno);
    800036da:	85a6                	mv	a1,s1
    800036dc:	855e                	mv	a0,s7
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	ce6080e7          	jalr	-794(ra) # 800033c4 <bread>
    800036e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036e8:	40000613          	li	a2,1024
    800036ec:	4581                	li	a1,0
    800036ee:	05850513          	addi	a0,a0,88
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	5dc080e7          	jalr	1500(ra) # 80000cce <memset>
  log_write(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	050080e7          	jalr	80(ra) # 8000474c <log_write>
  brelse(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	dee080e7          	jalr	-530(ra) # 800034f4 <brelse>
}
    8000370e:	8526                	mv	a0,s1
    80003710:	60e6                	ld	ra,88(sp)
    80003712:	6446                	ld	s0,80(sp)
    80003714:	64a6                	ld	s1,72(sp)
    80003716:	6906                	ld	s2,64(sp)
    80003718:	79e2                	ld	s3,56(sp)
    8000371a:	7a42                	ld	s4,48(sp)
    8000371c:	7aa2                	ld	s5,40(sp)
    8000371e:	7b02                	ld	s6,32(sp)
    80003720:	6be2                	ld	s7,24(sp)
    80003722:	6c42                	ld	s8,16(sp)
    80003724:	6ca2                	ld	s9,8(sp)
    80003726:	6125                	addi	sp,sp,96
    80003728:	8082                	ret
    brelse(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	dc8080e7          	jalr	-568(ra) # 800034f4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003734:	015c87bb          	addw	a5,s9,s5
    80003738:	00078a9b          	sext.w	s5,a5
    8000373c:	004b2703          	lw	a4,4(s6)
    80003740:	06eaf163          	bgeu	s5,a4,800037a2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003744:	41fad79b          	sraiw	a5,s5,0x1f
    80003748:	0137d79b          	srliw	a5,a5,0x13
    8000374c:	015787bb          	addw	a5,a5,s5
    80003750:	40d7d79b          	sraiw	a5,a5,0xd
    80003754:	01cb2583          	lw	a1,28(s6)
    80003758:	9dbd                	addw	a1,a1,a5
    8000375a:	855e                	mv	a0,s7
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	c68080e7          	jalr	-920(ra) # 800033c4 <bread>
    80003764:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003766:	004b2503          	lw	a0,4(s6)
    8000376a:	000a849b          	sext.w	s1,s5
    8000376e:	8762                	mv	a4,s8
    80003770:	faa4fde3          	bgeu	s1,a0,8000372a <balloc+0xa6>
      m = 1 << (bi % 8);
    80003774:	00777693          	andi	a3,a4,7
    80003778:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000377c:	41f7579b          	sraiw	a5,a4,0x1f
    80003780:	01d7d79b          	srliw	a5,a5,0x1d
    80003784:	9fb9                	addw	a5,a5,a4
    80003786:	4037d79b          	sraiw	a5,a5,0x3
    8000378a:	00f90633          	add	a2,s2,a5
    8000378e:	05864603          	lbu	a2,88(a2)
    80003792:	00c6f5b3          	and	a1,a3,a2
    80003796:	d585                	beqz	a1,800036be <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003798:	2705                	addiw	a4,a4,1
    8000379a:	2485                	addiw	s1,s1,1
    8000379c:	fd471ae3          	bne	a4,s4,80003770 <balloc+0xec>
    800037a0:	b769                	j	8000372a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	e9650513          	addi	a0,a0,-362 # 80008638 <syscalls+0x118>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	ddc080e7          	jalr	-548(ra) # 80000586 <printf>
  return 0;
    800037b2:	4481                	li	s1,0
    800037b4:	bfa9                	j	8000370e <balloc+0x8a>

00000000800037b6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037b6:	7179                	addi	sp,sp,-48
    800037b8:	f406                	sd	ra,40(sp)
    800037ba:	f022                	sd	s0,32(sp)
    800037bc:	ec26                	sd	s1,24(sp)
    800037be:	e84a                	sd	s2,16(sp)
    800037c0:	e44e                	sd	s3,8(sp)
    800037c2:	e052                	sd	s4,0(sp)
    800037c4:	1800                	addi	s0,sp,48
    800037c6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037c8:	47ad                	li	a5,11
    800037ca:	02b7e863          	bltu	a5,a1,800037fa <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037ce:	02059793          	slli	a5,a1,0x20
    800037d2:	01e7d593          	srli	a1,a5,0x1e
    800037d6:	00b504b3          	add	s1,a0,a1
    800037da:	0504a903          	lw	s2,80(s1)
    800037de:	06091e63          	bnez	s2,8000385a <bmap+0xa4>
      addr = balloc(ip->dev);
    800037e2:	4108                	lw	a0,0(a0)
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	ea0080e7          	jalr	-352(ra) # 80003684 <balloc>
    800037ec:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037f0:	06090563          	beqz	s2,8000385a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037f4:	0524a823          	sw	s2,80(s1)
    800037f8:	a08d                	j	8000385a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037fa:	ff45849b          	addiw	s1,a1,-12
    800037fe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003802:	0ff00793          	li	a5,255
    80003806:	08e7e563          	bltu	a5,a4,80003890 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000380a:	08052903          	lw	s2,128(a0)
    8000380e:	00091d63          	bnez	s2,80003828 <bmap+0x72>
      addr = balloc(ip->dev);
    80003812:	4108                	lw	a0,0(a0)
    80003814:	00000097          	auipc	ra,0x0
    80003818:	e70080e7          	jalr	-400(ra) # 80003684 <balloc>
    8000381c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003820:	02090d63          	beqz	s2,8000385a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003824:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003828:	85ca                	mv	a1,s2
    8000382a:	0009a503          	lw	a0,0(s3)
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	b96080e7          	jalr	-1130(ra) # 800033c4 <bread>
    80003836:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003838:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000383c:	02049713          	slli	a4,s1,0x20
    80003840:	01e75593          	srli	a1,a4,0x1e
    80003844:	00b784b3          	add	s1,a5,a1
    80003848:	0004a903          	lw	s2,0(s1)
    8000384c:	02090063          	beqz	s2,8000386c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003850:	8552                	mv	a0,s4
    80003852:	00000097          	auipc	ra,0x0
    80003856:	ca2080e7          	jalr	-862(ra) # 800034f4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000385a:	854a                	mv	a0,s2
    8000385c:	70a2                	ld	ra,40(sp)
    8000385e:	7402                	ld	s0,32(sp)
    80003860:	64e2                	ld	s1,24(sp)
    80003862:	6942                	ld	s2,16(sp)
    80003864:	69a2                	ld	s3,8(sp)
    80003866:	6a02                	ld	s4,0(sp)
    80003868:	6145                	addi	sp,sp,48
    8000386a:	8082                	ret
      addr = balloc(ip->dev);
    8000386c:	0009a503          	lw	a0,0(s3)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	e14080e7          	jalr	-492(ra) # 80003684 <balloc>
    80003878:	0005091b          	sext.w	s2,a0
      if(addr){
    8000387c:	fc090ae3          	beqz	s2,80003850 <bmap+0x9a>
        a[bn] = addr;
    80003880:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003884:	8552                	mv	a0,s4
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	ec6080e7          	jalr	-314(ra) # 8000474c <log_write>
    8000388e:	b7c9                	j	80003850 <bmap+0x9a>
  panic("bmap: out of range");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	dc050513          	addi	a0,a0,-576 # 80008650 <syscalls+0x130>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	ca4080e7          	jalr	-860(ra) # 8000053c <panic>

00000000800038a0 <iget>:
{
    800038a0:	7179                	addi	sp,sp,-48
    800038a2:	f406                	sd	ra,40(sp)
    800038a4:	f022                	sd	s0,32(sp)
    800038a6:	ec26                	sd	s1,24(sp)
    800038a8:	e84a                	sd	s2,16(sp)
    800038aa:	e44e                	sd	s3,8(sp)
    800038ac:	e052                	sd	s4,0(sp)
    800038ae:	1800                	addi	s0,sp,48
    800038b0:	89aa                	mv	s3,a0
    800038b2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038b4:	0001c517          	auipc	a0,0x1c
    800038b8:	ae450513          	addi	a0,a0,-1308 # 8001f398 <itable>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	316080e7          	jalr	790(ra) # 80000bd2 <acquire>
  empty = 0;
    800038c4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038c6:	0001c497          	auipc	s1,0x1c
    800038ca:	aea48493          	addi	s1,s1,-1302 # 8001f3b0 <itable+0x18>
    800038ce:	0001d697          	auipc	a3,0x1d
    800038d2:	57268693          	addi	a3,a3,1394 # 80020e40 <log>
    800038d6:	a039                	j	800038e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d8:	02090b63          	beqz	s2,8000390e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038dc:	08848493          	addi	s1,s1,136
    800038e0:	02d48a63          	beq	s1,a3,80003914 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038e4:	449c                	lw	a5,8(s1)
    800038e6:	fef059e3          	blez	a5,800038d8 <iget+0x38>
    800038ea:	4098                	lw	a4,0(s1)
    800038ec:	ff3716e3          	bne	a4,s3,800038d8 <iget+0x38>
    800038f0:	40d8                	lw	a4,4(s1)
    800038f2:	ff4713e3          	bne	a4,s4,800038d8 <iget+0x38>
      ip->ref++;
    800038f6:	2785                	addiw	a5,a5,1
    800038f8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038fa:	0001c517          	auipc	a0,0x1c
    800038fe:	a9e50513          	addi	a0,a0,-1378 # 8001f398 <itable>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	384080e7          	jalr	900(ra) # 80000c86 <release>
      return ip;
    8000390a:	8926                	mv	s2,s1
    8000390c:	a03d                	j	8000393a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000390e:	f7f9                	bnez	a5,800038dc <iget+0x3c>
    80003910:	8926                	mv	s2,s1
    80003912:	b7e9                	j	800038dc <iget+0x3c>
  if(empty == 0)
    80003914:	02090c63          	beqz	s2,8000394c <iget+0xac>
  ip->dev = dev;
    80003918:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000391c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003920:	4785                	li	a5,1
    80003922:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003926:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	a6e50513          	addi	a0,a0,-1426 # 8001f398 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	354080e7          	jalr	852(ra) # 80000c86 <release>
}
    8000393a:	854a                	mv	a0,s2
    8000393c:	70a2                	ld	ra,40(sp)
    8000393e:	7402                	ld	s0,32(sp)
    80003940:	64e2                	ld	s1,24(sp)
    80003942:	6942                	ld	s2,16(sp)
    80003944:	69a2                	ld	s3,8(sp)
    80003946:	6a02                	ld	s4,0(sp)
    80003948:	6145                	addi	sp,sp,48
    8000394a:	8082                	ret
    panic("iget: no inodes");
    8000394c:	00005517          	auipc	a0,0x5
    80003950:	d1c50513          	addi	a0,a0,-740 # 80008668 <syscalls+0x148>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	be8080e7          	jalr	-1048(ra) # 8000053c <panic>

000000008000395c <fsinit>:
fsinit(int dev) {
    8000395c:	7179                	addi	sp,sp,-48
    8000395e:	f406                	sd	ra,40(sp)
    80003960:	f022                	sd	s0,32(sp)
    80003962:	ec26                	sd	s1,24(sp)
    80003964:	e84a                	sd	s2,16(sp)
    80003966:	e44e                	sd	s3,8(sp)
    80003968:	1800                	addi	s0,sp,48
    8000396a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000396c:	4585                	li	a1,1
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	a56080e7          	jalr	-1450(ra) # 800033c4 <bread>
    80003976:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003978:	0001c997          	auipc	s3,0x1c
    8000397c:	a0098993          	addi	s3,s3,-1536 # 8001f378 <sb>
    80003980:	02000613          	li	a2,32
    80003984:	05850593          	addi	a1,a0,88
    80003988:	854e                	mv	a0,s3
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	3a0080e7          	jalr	928(ra) # 80000d2a <memmove>
  brelse(bp);
    80003992:	8526                	mv	a0,s1
    80003994:	00000097          	auipc	ra,0x0
    80003998:	b60080e7          	jalr	-1184(ra) # 800034f4 <brelse>
  if(sb.magic != FSMAGIC)
    8000399c:	0009a703          	lw	a4,0(s3)
    800039a0:	102037b7          	lui	a5,0x10203
    800039a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039a8:	02f71263          	bne	a4,a5,800039cc <fsinit+0x70>
  initlog(dev, &sb);
    800039ac:	0001c597          	auipc	a1,0x1c
    800039b0:	9cc58593          	addi	a1,a1,-1588 # 8001f378 <sb>
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	b2c080e7          	jalr	-1236(ra) # 800044e2 <initlog>
}
    800039be:	70a2                	ld	ra,40(sp)
    800039c0:	7402                	ld	s0,32(sp)
    800039c2:	64e2                	ld	s1,24(sp)
    800039c4:	6942                	ld	s2,16(sp)
    800039c6:	69a2                	ld	s3,8(sp)
    800039c8:	6145                	addi	sp,sp,48
    800039ca:	8082                	ret
    panic("invalid file system");
    800039cc:	00005517          	auipc	a0,0x5
    800039d0:	cac50513          	addi	a0,a0,-852 # 80008678 <syscalls+0x158>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	b68080e7          	jalr	-1176(ra) # 8000053c <panic>

00000000800039dc <iinit>:
{
    800039dc:	7179                	addi	sp,sp,-48
    800039de:	f406                	sd	ra,40(sp)
    800039e0:	f022                	sd	s0,32(sp)
    800039e2:	ec26                	sd	s1,24(sp)
    800039e4:	e84a                	sd	s2,16(sp)
    800039e6:	e44e                	sd	s3,8(sp)
    800039e8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039ea:	00005597          	auipc	a1,0x5
    800039ee:	ca658593          	addi	a1,a1,-858 # 80008690 <syscalls+0x170>
    800039f2:	0001c517          	auipc	a0,0x1c
    800039f6:	9a650513          	addi	a0,a0,-1626 # 8001f398 <itable>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	148080e7          	jalr	328(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a02:	0001c497          	auipc	s1,0x1c
    80003a06:	9be48493          	addi	s1,s1,-1602 # 8001f3c0 <itable+0x28>
    80003a0a:	0001d997          	auipc	s3,0x1d
    80003a0e:	44698993          	addi	s3,s3,1094 # 80020e50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a12:	00005917          	auipc	s2,0x5
    80003a16:	c8690913          	addi	s2,s2,-890 # 80008698 <syscalls+0x178>
    80003a1a:	85ca                	mv	a1,s2
    80003a1c:	8526                	mv	a0,s1
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	e12080e7          	jalr	-494(ra) # 80004830 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a26:	08848493          	addi	s1,s1,136
    80003a2a:	ff3498e3          	bne	s1,s3,80003a1a <iinit+0x3e>
}
    80003a2e:	70a2                	ld	ra,40(sp)
    80003a30:	7402                	ld	s0,32(sp)
    80003a32:	64e2                	ld	s1,24(sp)
    80003a34:	6942                	ld	s2,16(sp)
    80003a36:	69a2                	ld	s3,8(sp)
    80003a38:	6145                	addi	sp,sp,48
    80003a3a:	8082                	ret

0000000080003a3c <ialloc>:
{
    80003a3c:	7139                	addi	sp,sp,-64
    80003a3e:	fc06                	sd	ra,56(sp)
    80003a40:	f822                	sd	s0,48(sp)
    80003a42:	f426                	sd	s1,40(sp)
    80003a44:	f04a                	sd	s2,32(sp)
    80003a46:	ec4e                	sd	s3,24(sp)
    80003a48:	e852                	sd	s4,16(sp)
    80003a4a:	e456                	sd	s5,8(sp)
    80003a4c:	e05a                	sd	s6,0(sp)
    80003a4e:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a50:	0001c717          	auipc	a4,0x1c
    80003a54:	93472703          	lw	a4,-1740(a4) # 8001f384 <sb+0xc>
    80003a58:	4785                	li	a5,1
    80003a5a:	04e7f863          	bgeu	a5,a4,80003aaa <ialloc+0x6e>
    80003a5e:	8aaa                	mv	s5,a0
    80003a60:	8b2e                	mv	s6,a1
    80003a62:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a64:	0001ca17          	auipc	s4,0x1c
    80003a68:	914a0a13          	addi	s4,s4,-1772 # 8001f378 <sb>
    80003a6c:	00495593          	srli	a1,s2,0x4
    80003a70:	018a2783          	lw	a5,24(s4)
    80003a74:	9dbd                	addw	a1,a1,a5
    80003a76:	8556                	mv	a0,s5
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	94c080e7          	jalr	-1716(ra) # 800033c4 <bread>
    80003a80:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a82:	05850993          	addi	s3,a0,88
    80003a86:	00f97793          	andi	a5,s2,15
    80003a8a:	079a                	slli	a5,a5,0x6
    80003a8c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a8e:	00099783          	lh	a5,0(s3)
    80003a92:	cf9d                	beqz	a5,80003ad0 <ialloc+0x94>
    brelse(bp);
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	a60080e7          	jalr	-1440(ra) # 800034f4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a9c:	0905                	addi	s2,s2,1
    80003a9e:	00ca2703          	lw	a4,12(s4)
    80003aa2:	0009079b          	sext.w	a5,s2
    80003aa6:	fce7e3e3          	bltu	a5,a4,80003a6c <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003aaa:	00005517          	auipc	a0,0x5
    80003aae:	bf650513          	addi	a0,a0,-1034 # 800086a0 <syscalls+0x180>
    80003ab2:	ffffd097          	auipc	ra,0xffffd
    80003ab6:	ad4080e7          	jalr	-1324(ra) # 80000586 <printf>
  return 0;
    80003aba:	4501                	li	a0,0
}
    80003abc:	70e2                	ld	ra,56(sp)
    80003abe:	7442                	ld	s0,48(sp)
    80003ac0:	74a2                	ld	s1,40(sp)
    80003ac2:	7902                	ld	s2,32(sp)
    80003ac4:	69e2                	ld	s3,24(sp)
    80003ac6:	6a42                	ld	s4,16(sp)
    80003ac8:	6aa2                	ld	s5,8(sp)
    80003aca:	6b02                	ld	s6,0(sp)
    80003acc:	6121                	addi	sp,sp,64
    80003ace:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ad0:	04000613          	li	a2,64
    80003ad4:	4581                	li	a1,0
    80003ad6:	854e                	mv	a0,s3
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	1f6080e7          	jalr	502(ra) # 80000cce <memset>
      dip->type = type;
    80003ae0:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ae4:	8526                	mv	a0,s1
    80003ae6:	00001097          	auipc	ra,0x1
    80003aea:	c66080e7          	jalr	-922(ra) # 8000474c <log_write>
      brelse(bp);
    80003aee:	8526                	mv	a0,s1
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	a04080e7          	jalr	-1532(ra) # 800034f4 <brelse>
      return iget(dev, inum);
    80003af8:	0009059b          	sext.w	a1,s2
    80003afc:	8556                	mv	a0,s5
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	da2080e7          	jalr	-606(ra) # 800038a0 <iget>
    80003b06:	bf5d                	j	80003abc <ialloc+0x80>

0000000080003b08 <iupdate>:
{
    80003b08:	1101                	addi	sp,sp,-32
    80003b0a:	ec06                	sd	ra,24(sp)
    80003b0c:	e822                	sd	s0,16(sp)
    80003b0e:	e426                	sd	s1,8(sp)
    80003b10:	e04a                	sd	s2,0(sp)
    80003b12:	1000                	addi	s0,sp,32
    80003b14:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b16:	415c                	lw	a5,4(a0)
    80003b18:	0047d79b          	srliw	a5,a5,0x4
    80003b1c:	0001c597          	auipc	a1,0x1c
    80003b20:	8745a583          	lw	a1,-1932(a1) # 8001f390 <sb+0x18>
    80003b24:	9dbd                	addw	a1,a1,a5
    80003b26:	4108                	lw	a0,0(a0)
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	89c080e7          	jalr	-1892(ra) # 800033c4 <bread>
    80003b30:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b32:	05850793          	addi	a5,a0,88
    80003b36:	40d8                	lw	a4,4(s1)
    80003b38:	8b3d                	andi	a4,a4,15
    80003b3a:	071a                	slli	a4,a4,0x6
    80003b3c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b3e:	04449703          	lh	a4,68(s1)
    80003b42:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b46:	04649703          	lh	a4,70(s1)
    80003b4a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b4e:	04849703          	lh	a4,72(s1)
    80003b52:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b56:	04a49703          	lh	a4,74(s1)
    80003b5a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b5e:	44f8                	lw	a4,76(s1)
    80003b60:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b62:	03400613          	li	a2,52
    80003b66:	05048593          	addi	a1,s1,80
    80003b6a:	00c78513          	addi	a0,a5,12
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	1bc080e7          	jalr	444(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b76:	854a                	mv	a0,s2
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	bd4080e7          	jalr	-1068(ra) # 8000474c <log_write>
  brelse(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	972080e7          	jalr	-1678(ra) # 800034f4 <brelse>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6902                	ld	s2,0(sp)
    80003b92:	6105                	addi	sp,sp,32
    80003b94:	8082                	ret

0000000080003b96 <idup>:
{
    80003b96:	1101                	addi	sp,sp,-32
    80003b98:	ec06                	sd	ra,24(sp)
    80003b9a:	e822                	sd	s0,16(sp)
    80003b9c:	e426                	sd	s1,8(sp)
    80003b9e:	1000                	addi	s0,sp,32
    80003ba0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ba2:	0001b517          	auipc	a0,0x1b
    80003ba6:	7f650513          	addi	a0,a0,2038 # 8001f398 <itable>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	028080e7          	jalr	40(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003bb2:	449c                	lw	a5,8(s1)
    80003bb4:	2785                	addiw	a5,a5,1
    80003bb6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bb8:	0001b517          	auipc	a0,0x1b
    80003bbc:	7e050513          	addi	a0,a0,2016 # 8001f398 <itable>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	0c6080e7          	jalr	198(ra) # 80000c86 <release>
}
    80003bc8:	8526                	mv	a0,s1
    80003bca:	60e2                	ld	ra,24(sp)
    80003bcc:	6442                	ld	s0,16(sp)
    80003bce:	64a2                	ld	s1,8(sp)
    80003bd0:	6105                	addi	sp,sp,32
    80003bd2:	8082                	ret

0000000080003bd4 <ilock>:
{
    80003bd4:	1101                	addi	sp,sp,-32
    80003bd6:	ec06                	sd	ra,24(sp)
    80003bd8:	e822                	sd	s0,16(sp)
    80003bda:	e426                	sd	s1,8(sp)
    80003bdc:	e04a                	sd	s2,0(sp)
    80003bde:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003be0:	c115                	beqz	a0,80003c04 <ilock+0x30>
    80003be2:	84aa                	mv	s1,a0
    80003be4:	451c                	lw	a5,8(a0)
    80003be6:	00f05f63          	blez	a5,80003c04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bea:	0541                	addi	a0,a0,16
    80003bec:	00001097          	auipc	ra,0x1
    80003bf0:	c7e080e7          	jalr	-898(ra) # 8000486a <acquiresleep>
  if(ip->valid == 0){
    80003bf4:	40bc                	lw	a5,64(s1)
    80003bf6:	cf99                	beqz	a5,80003c14 <ilock+0x40>
}
    80003bf8:	60e2                	ld	ra,24(sp)
    80003bfa:	6442                	ld	s0,16(sp)
    80003bfc:	64a2                	ld	s1,8(sp)
    80003bfe:	6902                	ld	s2,0(sp)
    80003c00:	6105                	addi	sp,sp,32
    80003c02:	8082                	ret
    panic("ilock");
    80003c04:	00005517          	auipc	a0,0x5
    80003c08:	ab450513          	addi	a0,a0,-1356 # 800086b8 <syscalls+0x198>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	930080e7          	jalr	-1744(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c14:	40dc                	lw	a5,4(s1)
    80003c16:	0047d79b          	srliw	a5,a5,0x4
    80003c1a:	0001b597          	auipc	a1,0x1b
    80003c1e:	7765a583          	lw	a1,1910(a1) # 8001f390 <sb+0x18>
    80003c22:	9dbd                	addw	a1,a1,a5
    80003c24:	4088                	lw	a0,0(s1)
    80003c26:	fffff097          	auipc	ra,0xfffff
    80003c2a:	79e080e7          	jalr	1950(ra) # 800033c4 <bread>
    80003c2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c30:	05850593          	addi	a1,a0,88
    80003c34:	40dc                	lw	a5,4(s1)
    80003c36:	8bbd                	andi	a5,a5,15
    80003c38:	079a                	slli	a5,a5,0x6
    80003c3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c3c:	00059783          	lh	a5,0(a1)
    80003c40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c44:	00259783          	lh	a5,2(a1)
    80003c48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c4c:	00459783          	lh	a5,4(a1)
    80003c50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c54:	00659783          	lh	a5,6(a1)
    80003c58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c5c:	459c                	lw	a5,8(a1)
    80003c5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c60:	03400613          	li	a2,52
    80003c64:	05b1                	addi	a1,a1,12
    80003c66:	05048513          	addi	a0,s1,80
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	0c0080e7          	jalr	192(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c72:	854a                	mv	a0,s2
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	880080e7          	jalr	-1920(ra) # 800034f4 <brelse>
    ip->valid = 1;
    80003c7c:	4785                	li	a5,1
    80003c7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c80:	04449783          	lh	a5,68(s1)
    80003c84:	fbb5                	bnez	a5,80003bf8 <ilock+0x24>
      panic("ilock: no type");
    80003c86:	00005517          	auipc	a0,0x5
    80003c8a:	a3a50513          	addi	a0,a0,-1478 # 800086c0 <syscalls+0x1a0>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	8ae080e7          	jalr	-1874(ra) # 8000053c <panic>

0000000080003c96 <iunlock>:
{
    80003c96:	1101                	addi	sp,sp,-32
    80003c98:	ec06                	sd	ra,24(sp)
    80003c9a:	e822                	sd	s0,16(sp)
    80003c9c:	e426                	sd	s1,8(sp)
    80003c9e:	e04a                	sd	s2,0(sp)
    80003ca0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ca2:	c905                	beqz	a0,80003cd2 <iunlock+0x3c>
    80003ca4:	84aa                	mv	s1,a0
    80003ca6:	01050913          	addi	s2,a0,16
    80003caa:	854a                	mv	a0,s2
    80003cac:	00001097          	auipc	ra,0x1
    80003cb0:	c58080e7          	jalr	-936(ra) # 80004904 <holdingsleep>
    80003cb4:	cd19                	beqz	a0,80003cd2 <iunlock+0x3c>
    80003cb6:	449c                	lw	a5,8(s1)
    80003cb8:	00f05d63          	blez	a5,80003cd2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cbc:	854a                	mv	a0,s2
    80003cbe:	00001097          	auipc	ra,0x1
    80003cc2:	c02080e7          	jalr	-1022(ra) # 800048c0 <releasesleep>
}
    80003cc6:	60e2                	ld	ra,24(sp)
    80003cc8:	6442                	ld	s0,16(sp)
    80003cca:	64a2                	ld	s1,8(sp)
    80003ccc:	6902                	ld	s2,0(sp)
    80003cce:	6105                	addi	sp,sp,32
    80003cd0:	8082                	ret
    panic("iunlock");
    80003cd2:	00005517          	auipc	a0,0x5
    80003cd6:	9fe50513          	addi	a0,a0,-1538 # 800086d0 <syscalls+0x1b0>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	862080e7          	jalr	-1950(ra) # 8000053c <panic>

0000000080003ce2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ce2:	7179                	addi	sp,sp,-48
    80003ce4:	f406                	sd	ra,40(sp)
    80003ce6:	f022                	sd	s0,32(sp)
    80003ce8:	ec26                	sd	s1,24(sp)
    80003cea:	e84a                	sd	s2,16(sp)
    80003cec:	e44e                	sd	s3,8(sp)
    80003cee:	e052                	sd	s4,0(sp)
    80003cf0:	1800                	addi	s0,sp,48
    80003cf2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cf4:	05050493          	addi	s1,a0,80
    80003cf8:	08050913          	addi	s2,a0,128
    80003cfc:	a021                	j	80003d04 <itrunc+0x22>
    80003cfe:	0491                	addi	s1,s1,4
    80003d00:	01248d63          	beq	s1,s2,80003d1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003d04:	408c                	lw	a1,0(s1)
    80003d06:	dde5                	beqz	a1,80003cfe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d08:	0009a503          	lw	a0,0(s3)
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	8fc080e7          	jalr	-1796(ra) # 80003608 <bfree>
      ip->addrs[i] = 0;
    80003d14:	0004a023          	sw	zero,0(s1)
    80003d18:	b7dd                	j	80003cfe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d1a:	0809a583          	lw	a1,128(s3)
    80003d1e:	e185                	bnez	a1,80003d3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	de2080e7          	jalr	-542(ra) # 80003b08 <iupdate>
}
    80003d2e:	70a2                	ld	ra,40(sp)
    80003d30:	7402                	ld	s0,32(sp)
    80003d32:	64e2                	ld	s1,24(sp)
    80003d34:	6942                	ld	s2,16(sp)
    80003d36:	69a2                	ld	s3,8(sp)
    80003d38:	6a02                	ld	s4,0(sp)
    80003d3a:	6145                	addi	sp,sp,48
    80003d3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d3e:	0009a503          	lw	a0,0(s3)
    80003d42:	fffff097          	auipc	ra,0xfffff
    80003d46:	682080e7          	jalr	1666(ra) # 800033c4 <bread>
    80003d4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d4c:	05850493          	addi	s1,a0,88
    80003d50:	45850913          	addi	s2,a0,1112
    80003d54:	a021                	j	80003d5c <itrunc+0x7a>
    80003d56:	0491                	addi	s1,s1,4
    80003d58:	01248b63          	beq	s1,s2,80003d6e <itrunc+0x8c>
      if(a[j])
    80003d5c:	408c                	lw	a1,0(s1)
    80003d5e:	dde5                	beqz	a1,80003d56 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d60:	0009a503          	lw	a0,0(s3)
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	8a4080e7          	jalr	-1884(ra) # 80003608 <bfree>
    80003d6c:	b7ed                	j	80003d56 <itrunc+0x74>
    brelse(bp);
    80003d6e:	8552                	mv	a0,s4
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	784080e7          	jalr	1924(ra) # 800034f4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d78:	0809a583          	lw	a1,128(s3)
    80003d7c:	0009a503          	lw	a0,0(s3)
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	888080e7          	jalr	-1912(ra) # 80003608 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d88:	0809a023          	sw	zero,128(s3)
    80003d8c:	bf51                	j	80003d20 <itrunc+0x3e>

0000000080003d8e <iput>:
{
    80003d8e:	1101                	addi	sp,sp,-32
    80003d90:	ec06                	sd	ra,24(sp)
    80003d92:	e822                	sd	s0,16(sp)
    80003d94:	e426                	sd	s1,8(sp)
    80003d96:	e04a                	sd	s2,0(sp)
    80003d98:	1000                	addi	s0,sp,32
    80003d9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d9c:	0001b517          	auipc	a0,0x1b
    80003da0:	5fc50513          	addi	a0,a0,1532 # 8001f398 <itable>
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	e2e080e7          	jalr	-466(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dac:	4498                	lw	a4,8(s1)
    80003dae:	4785                	li	a5,1
    80003db0:	02f70363          	beq	a4,a5,80003dd6 <iput+0x48>
  ip->ref--;
    80003db4:	449c                	lw	a5,8(s1)
    80003db6:	37fd                	addiw	a5,a5,-1
    80003db8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dba:	0001b517          	auipc	a0,0x1b
    80003dbe:	5de50513          	addi	a0,a0,1502 # 8001f398 <itable>
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	ec4080e7          	jalr	-316(ra) # 80000c86 <release>
}
    80003dca:	60e2                	ld	ra,24(sp)
    80003dcc:	6442                	ld	s0,16(sp)
    80003dce:	64a2                	ld	s1,8(sp)
    80003dd0:	6902                	ld	s2,0(sp)
    80003dd2:	6105                	addi	sp,sp,32
    80003dd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dd6:	40bc                	lw	a5,64(s1)
    80003dd8:	dff1                	beqz	a5,80003db4 <iput+0x26>
    80003dda:	04a49783          	lh	a5,74(s1)
    80003dde:	fbf9                	bnez	a5,80003db4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003de0:	01048913          	addi	s2,s1,16
    80003de4:	854a                	mv	a0,s2
    80003de6:	00001097          	auipc	ra,0x1
    80003dea:	a84080e7          	jalr	-1404(ra) # 8000486a <acquiresleep>
    release(&itable.lock);
    80003dee:	0001b517          	auipc	a0,0x1b
    80003df2:	5aa50513          	addi	a0,a0,1450 # 8001f398 <itable>
    80003df6:	ffffd097          	auipc	ra,0xffffd
    80003dfa:	e90080e7          	jalr	-368(ra) # 80000c86 <release>
    itrunc(ip);
    80003dfe:	8526                	mv	a0,s1
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	ee2080e7          	jalr	-286(ra) # 80003ce2 <itrunc>
    ip->type = 0;
    80003e08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	cfa080e7          	jalr	-774(ra) # 80003b08 <iupdate>
    ip->valid = 0;
    80003e16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e1a:	854a                	mv	a0,s2
    80003e1c:	00001097          	auipc	ra,0x1
    80003e20:	aa4080e7          	jalr	-1372(ra) # 800048c0 <releasesleep>
    acquire(&itable.lock);
    80003e24:	0001b517          	auipc	a0,0x1b
    80003e28:	57450513          	addi	a0,a0,1396 # 8001f398 <itable>
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	da6080e7          	jalr	-602(ra) # 80000bd2 <acquire>
    80003e34:	b741                	j	80003db4 <iput+0x26>

0000000080003e36 <iunlockput>:
{
    80003e36:	1101                	addi	sp,sp,-32
    80003e38:	ec06                	sd	ra,24(sp)
    80003e3a:	e822                	sd	s0,16(sp)
    80003e3c:	e426                	sd	s1,8(sp)
    80003e3e:	1000                	addi	s0,sp,32
    80003e40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	e54080e7          	jalr	-428(ra) # 80003c96 <iunlock>
  iput(ip);
    80003e4a:	8526                	mv	a0,s1
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	f42080e7          	jalr	-190(ra) # 80003d8e <iput>
}
    80003e54:	60e2                	ld	ra,24(sp)
    80003e56:	6442                	ld	s0,16(sp)
    80003e58:	64a2                	ld	s1,8(sp)
    80003e5a:	6105                	addi	sp,sp,32
    80003e5c:	8082                	ret

0000000080003e5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e5e:	1141                	addi	sp,sp,-16
    80003e60:	e422                	sd	s0,8(sp)
    80003e62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e64:	411c                	lw	a5,0(a0)
    80003e66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e68:	415c                	lw	a5,4(a0)
    80003e6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e6c:	04451783          	lh	a5,68(a0)
    80003e70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e74:	04a51783          	lh	a5,74(a0)
    80003e78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e7c:	04c56783          	lwu	a5,76(a0)
    80003e80:	e99c                	sd	a5,16(a1)
}
    80003e82:	6422                	ld	s0,8(sp)
    80003e84:	0141                	addi	sp,sp,16
    80003e86:	8082                	ret

0000000080003e88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e88:	457c                	lw	a5,76(a0)
    80003e8a:	0ed7e963          	bltu	a5,a3,80003f7c <readi+0xf4>
{
    80003e8e:	7159                	addi	sp,sp,-112
    80003e90:	f486                	sd	ra,104(sp)
    80003e92:	f0a2                	sd	s0,96(sp)
    80003e94:	eca6                	sd	s1,88(sp)
    80003e96:	e8ca                	sd	s2,80(sp)
    80003e98:	e4ce                	sd	s3,72(sp)
    80003e9a:	e0d2                	sd	s4,64(sp)
    80003e9c:	fc56                	sd	s5,56(sp)
    80003e9e:	f85a                	sd	s6,48(sp)
    80003ea0:	f45e                	sd	s7,40(sp)
    80003ea2:	f062                	sd	s8,32(sp)
    80003ea4:	ec66                	sd	s9,24(sp)
    80003ea6:	e86a                	sd	s10,16(sp)
    80003ea8:	e46e                	sd	s11,8(sp)
    80003eaa:	1880                	addi	s0,sp,112
    80003eac:	8b2a                	mv	s6,a0
    80003eae:	8bae                	mv	s7,a1
    80003eb0:	8a32                	mv	s4,a2
    80003eb2:	84b6                	mv	s1,a3
    80003eb4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003eb6:	9f35                	addw	a4,a4,a3
    return 0;
    80003eb8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003eba:	0ad76063          	bltu	a4,a3,80003f5a <readi+0xd2>
  if(off + n > ip->size)
    80003ebe:	00e7f463          	bgeu	a5,a4,80003ec6 <readi+0x3e>
    n = ip->size - off;
    80003ec2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec6:	0a0a8963          	beqz	s5,80003f78 <readi+0xf0>
    80003eca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ecc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ed0:	5c7d                	li	s8,-1
    80003ed2:	a82d                	j	80003f0c <readi+0x84>
    80003ed4:	020d1d93          	slli	s11,s10,0x20
    80003ed8:	020ddd93          	srli	s11,s11,0x20
    80003edc:	05890613          	addi	a2,s2,88
    80003ee0:	86ee                	mv	a3,s11
    80003ee2:	963a                	add	a2,a2,a4
    80003ee4:	85d2                	mv	a1,s4
    80003ee6:	855e                	mv	a0,s7
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	904080e7          	jalr	-1788(ra) # 800027ec <either_copyout>
    80003ef0:	05850d63          	beq	a0,s8,80003f4a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	5fe080e7          	jalr	1534(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003efe:	013d09bb          	addw	s3,s10,s3
    80003f02:	009d04bb          	addw	s1,s10,s1
    80003f06:	9a6e                	add	s4,s4,s11
    80003f08:	0559f763          	bgeu	s3,s5,80003f56 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f0c:	00a4d59b          	srliw	a1,s1,0xa
    80003f10:	855a                	mv	a0,s6
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	8a4080e7          	jalr	-1884(ra) # 800037b6 <bmap>
    80003f1a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f1e:	cd85                	beqz	a1,80003f56 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f20:	000b2503          	lw	a0,0(s6)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	4a0080e7          	jalr	1184(ra) # 800033c4 <bread>
    80003f2c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2e:	3ff4f713          	andi	a4,s1,1023
    80003f32:	40ec87bb          	subw	a5,s9,a4
    80003f36:	413a86bb          	subw	a3,s5,s3
    80003f3a:	8d3e                	mv	s10,a5
    80003f3c:	2781                	sext.w	a5,a5
    80003f3e:	0006861b          	sext.w	a2,a3
    80003f42:	f8f679e3          	bgeu	a2,a5,80003ed4 <readi+0x4c>
    80003f46:	8d36                	mv	s10,a3
    80003f48:	b771                	j	80003ed4 <readi+0x4c>
      brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	5a8080e7          	jalr	1448(ra) # 800034f4 <brelse>
      tot = -1;
    80003f54:	59fd                	li	s3,-1
  }
  return tot;
    80003f56:	0009851b          	sext.w	a0,s3
}
    80003f5a:	70a6                	ld	ra,104(sp)
    80003f5c:	7406                	ld	s0,96(sp)
    80003f5e:	64e6                	ld	s1,88(sp)
    80003f60:	6946                	ld	s2,80(sp)
    80003f62:	69a6                	ld	s3,72(sp)
    80003f64:	6a06                	ld	s4,64(sp)
    80003f66:	7ae2                	ld	s5,56(sp)
    80003f68:	7b42                	ld	s6,48(sp)
    80003f6a:	7ba2                	ld	s7,40(sp)
    80003f6c:	7c02                	ld	s8,32(sp)
    80003f6e:	6ce2                	ld	s9,24(sp)
    80003f70:	6d42                	ld	s10,16(sp)
    80003f72:	6da2                	ld	s11,8(sp)
    80003f74:	6165                	addi	sp,sp,112
    80003f76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f78:	89d6                	mv	s3,s5
    80003f7a:	bff1                	j	80003f56 <readi+0xce>
    return 0;
    80003f7c:	4501                	li	a0,0
}
    80003f7e:	8082                	ret

0000000080003f80 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f80:	457c                	lw	a5,76(a0)
    80003f82:	10d7e863          	bltu	a5,a3,80004092 <writei+0x112>
{
    80003f86:	7159                	addi	sp,sp,-112
    80003f88:	f486                	sd	ra,104(sp)
    80003f8a:	f0a2                	sd	s0,96(sp)
    80003f8c:	eca6                	sd	s1,88(sp)
    80003f8e:	e8ca                	sd	s2,80(sp)
    80003f90:	e4ce                	sd	s3,72(sp)
    80003f92:	e0d2                	sd	s4,64(sp)
    80003f94:	fc56                	sd	s5,56(sp)
    80003f96:	f85a                	sd	s6,48(sp)
    80003f98:	f45e                	sd	s7,40(sp)
    80003f9a:	f062                	sd	s8,32(sp)
    80003f9c:	ec66                	sd	s9,24(sp)
    80003f9e:	e86a                	sd	s10,16(sp)
    80003fa0:	e46e                	sd	s11,8(sp)
    80003fa2:	1880                	addi	s0,sp,112
    80003fa4:	8aaa                	mv	s5,a0
    80003fa6:	8bae                	mv	s7,a1
    80003fa8:	8a32                	mv	s4,a2
    80003faa:	8936                	mv	s2,a3
    80003fac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fae:	00e687bb          	addw	a5,a3,a4
    80003fb2:	0ed7e263          	bltu	a5,a3,80004096 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fb6:	00043737          	lui	a4,0x43
    80003fba:	0ef76063          	bltu	a4,a5,8000409a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbe:	0c0b0863          	beqz	s6,8000408e <writei+0x10e>
    80003fc2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fc8:	5c7d                	li	s8,-1
    80003fca:	a091                	j	8000400e <writei+0x8e>
    80003fcc:	020d1d93          	slli	s11,s10,0x20
    80003fd0:	020ddd93          	srli	s11,s11,0x20
    80003fd4:	05848513          	addi	a0,s1,88
    80003fd8:	86ee                	mv	a3,s11
    80003fda:	8652                	mv	a2,s4
    80003fdc:	85de                	mv	a1,s7
    80003fde:	953a                	add	a0,a0,a4
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	862080e7          	jalr	-1950(ra) # 80002842 <either_copyin>
    80003fe8:	07850263          	beq	a0,s8,8000404c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fec:	8526                	mv	a0,s1
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	75e080e7          	jalr	1886(ra) # 8000474c <log_write>
    brelse(bp);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	4fc080e7          	jalr	1276(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004000:	013d09bb          	addw	s3,s10,s3
    80004004:	012d093b          	addw	s2,s10,s2
    80004008:	9a6e                	add	s4,s4,s11
    8000400a:	0569f663          	bgeu	s3,s6,80004056 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000400e:	00a9559b          	srliw	a1,s2,0xa
    80004012:	8556                	mv	a0,s5
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	7a2080e7          	jalr	1954(ra) # 800037b6 <bmap>
    8000401c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004020:	c99d                	beqz	a1,80004056 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004022:	000aa503          	lw	a0,0(s5)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	39e080e7          	jalr	926(ra) # 800033c4 <bread>
    8000402e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004030:	3ff97713          	andi	a4,s2,1023
    80004034:	40ec87bb          	subw	a5,s9,a4
    80004038:	413b06bb          	subw	a3,s6,s3
    8000403c:	8d3e                	mv	s10,a5
    8000403e:	2781                	sext.w	a5,a5
    80004040:	0006861b          	sext.w	a2,a3
    80004044:	f8f674e3          	bgeu	a2,a5,80003fcc <writei+0x4c>
    80004048:	8d36                	mv	s10,a3
    8000404a:	b749                	j	80003fcc <writei+0x4c>
      brelse(bp);
    8000404c:	8526                	mv	a0,s1
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	4a6080e7          	jalr	1190(ra) # 800034f4 <brelse>
  }

  if(off > ip->size)
    80004056:	04caa783          	lw	a5,76(s5)
    8000405a:	0127f463          	bgeu	a5,s2,80004062 <writei+0xe2>
    ip->size = off;
    8000405e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004062:	8556                	mv	a0,s5
    80004064:	00000097          	auipc	ra,0x0
    80004068:	aa4080e7          	jalr	-1372(ra) # 80003b08 <iupdate>

  return tot;
    8000406c:	0009851b          	sext.w	a0,s3
}
    80004070:	70a6                	ld	ra,104(sp)
    80004072:	7406                	ld	s0,96(sp)
    80004074:	64e6                	ld	s1,88(sp)
    80004076:	6946                	ld	s2,80(sp)
    80004078:	69a6                	ld	s3,72(sp)
    8000407a:	6a06                	ld	s4,64(sp)
    8000407c:	7ae2                	ld	s5,56(sp)
    8000407e:	7b42                	ld	s6,48(sp)
    80004080:	7ba2                	ld	s7,40(sp)
    80004082:	7c02                	ld	s8,32(sp)
    80004084:	6ce2                	ld	s9,24(sp)
    80004086:	6d42                	ld	s10,16(sp)
    80004088:	6da2                	ld	s11,8(sp)
    8000408a:	6165                	addi	sp,sp,112
    8000408c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000408e:	89da                	mv	s3,s6
    80004090:	bfc9                	j	80004062 <writei+0xe2>
    return -1;
    80004092:	557d                	li	a0,-1
}
    80004094:	8082                	ret
    return -1;
    80004096:	557d                	li	a0,-1
    80004098:	bfe1                	j	80004070 <writei+0xf0>
    return -1;
    8000409a:	557d                	li	a0,-1
    8000409c:	bfd1                	j	80004070 <writei+0xf0>

000000008000409e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000409e:	1141                	addi	sp,sp,-16
    800040a0:	e406                	sd	ra,8(sp)
    800040a2:	e022                	sd	s0,0(sp)
    800040a4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040a6:	4639                	li	a2,14
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	cf6080e7          	jalr	-778(ra) # 80000d9e <strncmp>
}
    800040b0:	60a2                	ld	ra,8(sp)
    800040b2:	6402                	ld	s0,0(sp)
    800040b4:	0141                	addi	sp,sp,16
    800040b6:	8082                	ret

00000000800040b8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040b8:	7139                	addi	sp,sp,-64
    800040ba:	fc06                	sd	ra,56(sp)
    800040bc:	f822                	sd	s0,48(sp)
    800040be:	f426                	sd	s1,40(sp)
    800040c0:	f04a                	sd	s2,32(sp)
    800040c2:	ec4e                	sd	s3,24(sp)
    800040c4:	e852                	sd	s4,16(sp)
    800040c6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040c8:	04451703          	lh	a4,68(a0)
    800040cc:	4785                	li	a5,1
    800040ce:	00f71a63          	bne	a4,a5,800040e2 <dirlookup+0x2a>
    800040d2:	892a                	mv	s2,a0
    800040d4:	89ae                	mv	s3,a1
    800040d6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d8:	457c                	lw	a5,76(a0)
    800040da:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040dc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040de:	e79d                	bnez	a5,8000410c <dirlookup+0x54>
    800040e0:	a8a5                	j	80004158 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040e2:	00004517          	auipc	a0,0x4
    800040e6:	5f650513          	addi	a0,a0,1526 # 800086d8 <syscalls+0x1b8>
    800040ea:	ffffc097          	auipc	ra,0xffffc
    800040ee:	452080e7          	jalr	1106(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040f2:	00004517          	auipc	a0,0x4
    800040f6:	5fe50513          	addi	a0,a0,1534 # 800086f0 <syscalls+0x1d0>
    800040fa:	ffffc097          	auipc	ra,0xffffc
    800040fe:	442080e7          	jalr	1090(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004102:	24c1                	addiw	s1,s1,16
    80004104:	04c92783          	lw	a5,76(s2)
    80004108:	04f4f763          	bgeu	s1,a5,80004156 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410c:	4741                	li	a4,16
    8000410e:	86a6                	mv	a3,s1
    80004110:	fc040613          	addi	a2,s0,-64
    80004114:	4581                	li	a1,0
    80004116:	854a                	mv	a0,s2
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	d70080e7          	jalr	-656(ra) # 80003e88 <readi>
    80004120:	47c1                	li	a5,16
    80004122:	fcf518e3          	bne	a0,a5,800040f2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004126:	fc045783          	lhu	a5,-64(s0)
    8000412a:	dfe1                	beqz	a5,80004102 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000412c:	fc240593          	addi	a1,s0,-62
    80004130:	854e                	mv	a0,s3
    80004132:	00000097          	auipc	ra,0x0
    80004136:	f6c080e7          	jalr	-148(ra) # 8000409e <namecmp>
    8000413a:	f561                	bnez	a0,80004102 <dirlookup+0x4a>
      if(poff)
    8000413c:	000a0463          	beqz	s4,80004144 <dirlookup+0x8c>
        *poff = off;
    80004140:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004144:	fc045583          	lhu	a1,-64(s0)
    80004148:	00092503          	lw	a0,0(s2)
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	754080e7          	jalr	1876(ra) # 800038a0 <iget>
    80004154:	a011                	j	80004158 <dirlookup+0xa0>
  return 0;
    80004156:	4501                	li	a0,0
}
    80004158:	70e2                	ld	ra,56(sp)
    8000415a:	7442                	ld	s0,48(sp)
    8000415c:	74a2                	ld	s1,40(sp)
    8000415e:	7902                	ld	s2,32(sp)
    80004160:	69e2                	ld	s3,24(sp)
    80004162:	6a42                	ld	s4,16(sp)
    80004164:	6121                	addi	sp,sp,64
    80004166:	8082                	ret

0000000080004168 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004168:	711d                	addi	sp,sp,-96
    8000416a:	ec86                	sd	ra,88(sp)
    8000416c:	e8a2                	sd	s0,80(sp)
    8000416e:	e4a6                	sd	s1,72(sp)
    80004170:	e0ca                	sd	s2,64(sp)
    80004172:	fc4e                	sd	s3,56(sp)
    80004174:	f852                	sd	s4,48(sp)
    80004176:	f456                	sd	s5,40(sp)
    80004178:	f05a                	sd	s6,32(sp)
    8000417a:	ec5e                	sd	s7,24(sp)
    8000417c:	e862                	sd	s8,16(sp)
    8000417e:	e466                	sd	s9,8(sp)
    80004180:	1080                	addi	s0,sp,96
    80004182:	84aa                	mv	s1,a0
    80004184:	8b2e                	mv	s6,a1
    80004186:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004188:	00054703          	lbu	a4,0(a0)
    8000418c:	02f00793          	li	a5,47
    80004190:	02f70263          	beq	a4,a5,800041b4 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004194:	ffffe097          	auipc	ra,0xffffe
    80004198:	ae8080e7          	jalr	-1304(ra) # 80001c7c <myproc>
    8000419c:	15853503          	ld	a0,344(a0)
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	9f6080e7          	jalr	-1546(ra) # 80003b96 <idup>
    800041a8:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041aa:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041ae:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041b0:	4b85                	li	s7,1
    800041b2:	a875                	j	8000426e <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800041b4:	4585                	li	a1,1
    800041b6:	4505                	li	a0,1
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	6e8080e7          	jalr	1768(ra) # 800038a0 <iget>
    800041c0:	8a2a                	mv	s4,a0
    800041c2:	b7e5                	j	800041aa <namex+0x42>
      iunlockput(ip);
    800041c4:	8552                	mv	a0,s4
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	c70080e7          	jalr	-912(ra) # 80003e36 <iunlockput>
      return 0;
    800041ce:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041d0:	8552                	mv	a0,s4
    800041d2:	60e6                	ld	ra,88(sp)
    800041d4:	6446                	ld	s0,80(sp)
    800041d6:	64a6                	ld	s1,72(sp)
    800041d8:	6906                	ld	s2,64(sp)
    800041da:	79e2                	ld	s3,56(sp)
    800041dc:	7a42                	ld	s4,48(sp)
    800041de:	7aa2                	ld	s5,40(sp)
    800041e0:	7b02                	ld	s6,32(sp)
    800041e2:	6be2                	ld	s7,24(sp)
    800041e4:	6c42                	ld	s8,16(sp)
    800041e6:	6ca2                	ld	s9,8(sp)
    800041e8:	6125                	addi	sp,sp,96
    800041ea:	8082                	ret
      iunlock(ip);
    800041ec:	8552                	mv	a0,s4
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	aa8080e7          	jalr	-1368(ra) # 80003c96 <iunlock>
      return ip;
    800041f6:	bfe9                	j	800041d0 <namex+0x68>
      iunlockput(ip);
    800041f8:	8552                	mv	a0,s4
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	c3c080e7          	jalr	-964(ra) # 80003e36 <iunlockput>
      return 0;
    80004202:	8a4e                	mv	s4,s3
    80004204:	b7f1                	j	800041d0 <namex+0x68>
  len = path - s;
    80004206:	40998633          	sub	a2,s3,s1
    8000420a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000420e:	099c5863          	bge	s8,s9,8000429e <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004212:	4639                	li	a2,14
    80004214:	85a6                	mv	a1,s1
    80004216:	8556                	mv	a0,s5
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	b12080e7          	jalr	-1262(ra) # 80000d2a <memmove>
    80004220:	84ce                	mv	s1,s3
  while(*path == '/')
    80004222:	0004c783          	lbu	a5,0(s1)
    80004226:	01279763          	bne	a5,s2,80004234 <namex+0xcc>
    path++;
    8000422a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	ff278de3          	beq	a5,s2,8000422a <namex+0xc2>
    ilock(ip);
    80004234:	8552                	mv	a0,s4
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	99e080e7          	jalr	-1634(ra) # 80003bd4 <ilock>
    if(ip->type != T_DIR){
    8000423e:	044a1783          	lh	a5,68(s4)
    80004242:	f97791e3          	bne	a5,s7,800041c4 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004246:	000b0563          	beqz	s6,80004250 <namex+0xe8>
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	dfd9                	beqz	a5,800041ec <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004250:	4601                	li	a2,0
    80004252:	85d6                	mv	a1,s5
    80004254:	8552                	mv	a0,s4
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	e62080e7          	jalr	-414(ra) # 800040b8 <dirlookup>
    8000425e:	89aa                	mv	s3,a0
    80004260:	dd41                	beqz	a0,800041f8 <namex+0x90>
    iunlockput(ip);
    80004262:	8552                	mv	a0,s4
    80004264:	00000097          	auipc	ra,0x0
    80004268:	bd2080e7          	jalr	-1070(ra) # 80003e36 <iunlockput>
    ip = next;
    8000426c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000426e:	0004c783          	lbu	a5,0(s1)
    80004272:	01279763          	bne	a5,s2,80004280 <namex+0x118>
    path++;
    80004276:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	ff278de3          	beq	a5,s2,80004276 <namex+0x10e>
  if(*path == 0)
    80004280:	cb9d                	beqz	a5,800042b6 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	89a6                	mv	s3,s1
  len = path - s;
    80004288:	4c81                	li	s9,0
    8000428a:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000428c:	01278963          	beq	a5,s2,8000429e <namex+0x136>
    80004290:	dbbd                	beqz	a5,80004206 <namex+0x9e>
    path++;
    80004292:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004294:	0009c783          	lbu	a5,0(s3)
    80004298:	ff279ce3          	bne	a5,s2,80004290 <namex+0x128>
    8000429c:	b7ad                	j	80004206 <namex+0x9e>
    memmove(name, s, len);
    8000429e:	2601                	sext.w	a2,a2
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8556                	mv	a0,s5
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	a86080e7          	jalr	-1402(ra) # 80000d2a <memmove>
    name[len] = 0;
    800042ac:	9cd6                	add	s9,s9,s5
    800042ae:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042b2:	84ce                	mv	s1,s3
    800042b4:	b7bd                	j	80004222 <namex+0xba>
  if(nameiparent){
    800042b6:	f00b0de3          	beqz	s6,800041d0 <namex+0x68>
    iput(ip);
    800042ba:	8552                	mv	a0,s4
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	ad2080e7          	jalr	-1326(ra) # 80003d8e <iput>
    return 0;
    800042c4:	4a01                	li	s4,0
    800042c6:	b729                	j	800041d0 <namex+0x68>

00000000800042c8 <dirlink>:
{
    800042c8:	7139                	addi	sp,sp,-64
    800042ca:	fc06                	sd	ra,56(sp)
    800042cc:	f822                	sd	s0,48(sp)
    800042ce:	f426                	sd	s1,40(sp)
    800042d0:	f04a                	sd	s2,32(sp)
    800042d2:	ec4e                	sd	s3,24(sp)
    800042d4:	e852                	sd	s4,16(sp)
    800042d6:	0080                	addi	s0,sp,64
    800042d8:	892a                	mv	s2,a0
    800042da:	8a2e                	mv	s4,a1
    800042dc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042de:	4601                	li	a2,0
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	dd8080e7          	jalr	-552(ra) # 800040b8 <dirlookup>
    800042e8:	e93d                	bnez	a0,8000435e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ea:	04c92483          	lw	s1,76(s2)
    800042ee:	c49d                	beqz	s1,8000431c <dirlink+0x54>
    800042f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f2:	4741                	li	a4,16
    800042f4:	86a6                	mv	a3,s1
    800042f6:	fc040613          	addi	a2,s0,-64
    800042fa:	4581                	li	a1,0
    800042fc:	854a                	mv	a0,s2
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	b8a080e7          	jalr	-1142(ra) # 80003e88 <readi>
    80004306:	47c1                	li	a5,16
    80004308:	06f51163          	bne	a0,a5,8000436a <dirlink+0xa2>
    if(de.inum == 0)
    8000430c:	fc045783          	lhu	a5,-64(s0)
    80004310:	c791                	beqz	a5,8000431c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004312:	24c1                	addiw	s1,s1,16
    80004314:	04c92783          	lw	a5,76(s2)
    80004318:	fcf4ede3          	bltu	s1,a5,800042f2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000431c:	4639                	li	a2,14
    8000431e:	85d2                	mv	a1,s4
    80004320:	fc240513          	addi	a0,s0,-62
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	ab6080e7          	jalr	-1354(ra) # 80000dda <strncpy>
  de.inum = inum;
    8000432c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004330:	4741                	li	a4,16
    80004332:	86a6                	mv	a3,s1
    80004334:	fc040613          	addi	a2,s0,-64
    80004338:	4581                	li	a1,0
    8000433a:	854a                	mv	a0,s2
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	c44080e7          	jalr	-956(ra) # 80003f80 <writei>
    80004344:	1541                	addi	a0,a0,-16
    80004346:	00a03533          	snez	a0,a0
    8000434a:	40a00533          	neg	a0,a0
}
    8000434e:	70e2                	ld	ra,56(sp)
    80004350:	7442                	ld	s0,48(sp)
    80004352:	74a2                	ld	s1,40(sp)
    80004354:	7902                	ld	s2,32(sp)
    80004356:	69e2                	ld	s3,24(sp)
    80004358:	6a42                	ld	s4,16(sp)
    8000435a:	6121                	addi	sp,sp,64
    8000435c:	8082                	ret
    iput(ip);
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	a30080e7          	jalr	-1488(ra) # 80003d8e <iput>
    return -1;
    80004366:	557d                	li	a0,-1
    80004368:	b7dd                	j	8000434e <dirlink+0x86>
      panic("dirlink read");
    8000436a:	00004517          	auipc	a0,0x4
    8000436e:	39650513          	addi	a0,a0,918 # 80008700 <syscalls+0x1e0>
    80004372:	ffffc097          	auipc	ra,0xffffc
    80004376:	1ca080e7          	jalr	458(ra) # 8000053c <panic>

000000008000437a <namei>:

struct inode*
namei(char *path)
{
    8000437a:	1101                	addi	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004382:	fe040613          	addi	a2,s0,-32
    80004386:	4581                	li	a1,0
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	de0080e7          	jalr	-544(ra) # 80004168 <namex>
}
    80004390:	60e2                	ld	ra,24(sp)
    80004392:	6442                	ld	s0,16(sp)
    80004394:	6105                	addi	sp,sp,32
    80004396:	8082                	ret

0000000080004398 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004398:	1141                	addi	sp,sp,-16
    8000439a:	e406                	sd	ra,8(sp)
    8000439c:	e022                	sd	s0,0(sp)
    8000439e:	0800                	addi	s0,sp,16
    800043a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043a2:	4585                	li	a1,1
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	dc4080e7          	jalr	-572(ra) # 80004168 <namex>
}
    800043ac:	60a2                	ld	ra,8(sp)
    800043ae:	6402                	ld	s0,0(sp)
    800043b0:	0141                	addi	sp,sp,16
    800043b2:	8082                	ret

00000000800043b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043b4:	1101                	addi	sp,sp,-32
    800043b6:	ec06                	sd	ra,24(sp)
    800043b8:	e822                	sd	s0,16(sp)
    800043ba:	e426                	sd	s1,8(sp)
    800043bc:	e04a                	sd	s2,0(sp)
    800043be:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043c0:	0001d917          	auipc	s2,0x1d
    800043c4:	a8090913          	addi	s2,s2,-1408 # 80020e40 <log>
    800043c8:	01892583          	lw	a1,24(s2)
    800043cc:	02892503          	lw	a0,40(s2)
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	ff4080e7          	jalr	-12(ra) # 800033c4 <bread>
    800043d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043da:	02c92603          	lw	a2,44(s2)
    800043de:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043e0:	00c05f63          	blez	a2,800043fe <write_head+0x4a>
    800043e4:	0001d717          	auipc	a4,0x1d
    800043e8:	a8c70713          	addi	a4,a4,-1396 # 80020e70 <log+0x30>
    800043ec:	87aa                	mv	a5,a0
    800043ee:	060a                	slli	a2,a2,0x2
    800043f0:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043f2:	4314                	lw	a3,0(a4)
    800043f4:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800043f6:	0711                	addi	a4,a4,4
    800043f8:	0791                	addi	a5,a5,4
    800043fa:	fec79ce3          	bne	a5,a2,800043f2 <write_head+0x3e>
  }
  bwrite(buf);
    800043fe:	8526                	mv	a0,s1
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	0b6080e7          	jalr	182(ra) # 800034b6 <bwrite>
  brelse(buf);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	0ea080e7          	jalr	234(ra) # 800034f4 <brelse>
}
    80004412:	60e2                	ld	ra,24(sp)
    80004414:	6442                	ld	s0,16(sp)
    80004416:	64a2                	ld	s1,8(sp)
    80004418:	6902                	ld	s2,0(sp)
    8000441a:	6105                	addi	sp,sp,32
    8000441c:	8082                	ret

000000008000441e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000441e:	0001d797          	auipc	a5,0x1d
    80004422:	a4e7a783          	lw	a5,-1458(a5) # 80020e6c <log+0x2c>
    80004426:	0af05d63          	blez	a5,800044e0 <install_trans+0xc2>
{
    8000442a:	7139                	addi	sp,sp,-64
    8000442c:	fc06                	sd	ra,56(sp)
    8000442e:	f822                	sd	s0,48(sp)
    80004430:	f426                	sd	s1,40(sp)
    80004432:	f04a                	sd	s2,32(sp)
    80004434:	ec4e                	sd	s3,24(sp)
    80004436:	e852                	sd	s4,16(sp)
    80004438:	e456                	sd	s5,8(sp)
    8000443a:	e05a                	sd	s6,0(sp)
    8000443c:	0080                	addi	s0,sp,64
    8000443e:	8b2a                	mv	s6,a0
    80004440:	0001da97          	auipc	s5,0x1d
    80004444:	a30a8a93          	addi	s5,s5,-1488 # 80020e70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004448:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000444a:	0001d997          	auipc	s3,0x1d
    8000444e:	9f698993          	addi	s3,s3,-1546 # 80020e40 <log>
    80004452:	a00d                	j	80004474 <install_trans+0x56>
    brelse(lbuf);
    80004454:	854a                	mv	a0,s2
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	09e080e7          	jalr	158(ra) # 800034f4 <brelse>
    brelse(dbuf);
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	094080e7          	jalr	148(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004468:	2a05                	addiw	s4,s4,1
    8000446a:	0a91                	addi	s5,s5,4
    8000446c:	02c9a783          	lw	a5,44(s3)
    80004470:	04fa5e63          	bge	s4,a5,800044cc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004474:	0189a583          	lw	a1,24(s3)
    80004478:	014585bb          	addw	a1,a1,s4
    8000447c:	2585                	addiw	a1,a1,1
    8000447e:	0289a503          	lw	a0,40(s3)
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	f42080e7          	jalr	-190(ra) # 800033c4 <bread>
    8000448a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000448c:	000aa583          	lw	a1,0(s5)
    80004490:	0289a503          	lw	a0,40(s3)
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	f30080e7          	jalr	-208(ra) # 800033c4 <bread>
    8000449c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000449e:	40000613          	li	a2,1024
    800044a2:	05890593          	addi	a1,s2,88
    800044a6:	05850513          	addi	a0,a0,88
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	880080e7          	jalr	-1920(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044b2:	8526                	mv	a0,s1
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	002080e7          	jalr	2(ra) # 800034b6 <bwrite>
    if(recovering == 0)
    800044bc:	f80b1ce3          	bnez	s6,80004454 <install_trans+0x36>
      bunpin(dbuf);
    800044c0:	8526                	mv	a0,s1
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	10a080e7          	jalr	266(ra) # 800035cc <bunpin>
    800044ca:	b769                	j	80004454 <install_trans+0x36>
}
    800044cc:	70e2                	ld	ra,56(sp)
    800044ce:	7442                	ld	s0,48(sp)
    800044d0:	74a2                	ld	s1,40(sp)
    800044d2:	7902                	ld	s2,32(sp)
    800044d4:	69e2                	ld	s3,24(sp)
    800044d6:	6a42                	ld	s4,16(sp)
    800044d8:	6aa2                	ld	s5,8(sp)
    800044da:	6b02                	ld	s6,0(sp)
    800044dc:	6121                	addi	sp,sp,64
    800044de:	8082                	ret
    800044e0:	8082                	ret

00000000800044e2 <initlog>:
{
    800044e2:	7179                	addi	sp,sp,-48
    800044e4:	f406                	sd	ra,40(sp)
    800044e6:	f022                	sd	s0,32(sp)
    800044e8:	ec26                	sd	s1,24(sp)
    800044ea:	e84a                	sd	s2,16(sp)
    800044ec:	e44e                	sd	s3,8(sp)
    800044ee:	1800                	addi	s0,sp,48
    800044f0:	892a                	mv	s2,a0
    800044f2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044f4:	0001d497          	auipc	s1,0x1d
    800044f8:	94c48493          	addi	s1,s1,-1716 # 80020e40 <log>
    800044fc:	00004597          	auipc	a1,0x4
    80004500:	21458593          	addi	a1,a1,532 # 80008710 <syscalls+0x1f0>
    80004504:	8526                	mv	a0,s1
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	63c080e7          	jalr	1596(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    8000450e:	0149a583          	lw	a1,20(s3)
    80004512:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004514:	0109a783          	lw	a5,16(s3)
    80004518:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000451a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000451e:	854a                	mv	a0,s2
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	ea4080e7          	jalr	-348(ra) # 800033c4 <bread>
  log.lh.n = lh->n;
    80004528:	4d30                	lw	a2,88(a0)
    8000452a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000452c:	00c05f63          	blez	a2,8000454a <initlog+0x68>
    80004530:	87aa                	mv	a5,a0
    80004532:	0001d717          	auipc	a4,0x1d
    80004536:	93e70713          	addi	a4,a4,-1730 # 80020e70 <log+0x30>
    8000453a:	060a                	slli	a2,a2,0x2
    8000453c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000453e:	4ff4                	lw	a3,92(a5)
    80004540:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004542:	0791                	addi	a5,a5,4
    80004544:	0711                	addi	a4,a4,4
    80004546:	fec79ce3          	bne	a5,a2,8000453e <initlog+0x5c>
  brelse(buf);
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	faa080e7          	jalr	-86(ra) # 800034f4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004552:	4505                	li	a0,1
    80004554:	00000097          	auipc	ra,0x0
    80004558:	eca080e7          	jalr	-310(ra) # 8000441e <install_trans>
  log.lh.n = 0;
    8000455c:	0001d797          	auipc	a5,0x1d
    80004560:	9007a823          	sw	zero,-1776(a5) # 80020e6c <log+0x2c>
  write_head(); // clear the log
    80004564:	00000097          	auipc	ra,0x0
    80004568:	e50080e7          	jalr	-432(ra) # 800043b4 <write_head>
}
    8000456c:	70a2                	ld	ra,40(sp)
    8000456e:	7402                	ld	s0,32(sp)
    80004570:	64e2                	ld	s1,24(sp)
    80004572:	6942                	ld	s2,16(sp)
    80004574:	69a2                	ld	s3,8(sp)
    80004576:	6145                	addi	sp,sp,48
    80004578:	8082                	ret

000000008000457a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	e04a                	sd	s2,0(sp)
    80004584:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	8ba50513          	addi	a0,a0,-1862 # 80020e40 <log>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	644080e7          	jalr	1604(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004596:	0001d497          	auipc	s1,0x1d
    8000459a:	8aa48493          	addi	s1,s1,-1878 # 80020e40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000459e:	4979                	li	s2,30
    800045a0:	a039                	j	800045ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800045a2:	85a6                	mv	a1,s1
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffe097          	auipc	ra,0xffffe
    800045aa:	e3e080e7          	jalr	-450(ra) # 800023e4 <sleep>
    if(log.committing){
    800045ae:	50dc                	lw	a5,36(s1)
    800045b0:	fbed                	bnez	a5,800045a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045b2:	5098                	lw	a4,32(s1)
    800045b4:	2705                	addiw	a4,a4,1
    800045b6:	0027179b          	slliw	a5,a4,0x2
    800045ba:	9fb9                	addw	a5,a5,a4
    800045bc:	0017979b          	slliw	a5,a5,0x1
    800045c0:	54d4                	lw	a3,44(s1)
    800045c2:	9fb5                	addw	a5,a5,a3
    800045c4:	00f95963          	bge	s2,a5,800045d6 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045c8:	85a6                	mv	a1,s1
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	e18080e7          	jalr	-488(ra) # 800023e4 <sleep>
    800045d4:	bfe9                	j	800045ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045d6:	0001d517          	auipc	a0,0x1d
    800045da:	86a50513          	addi	a0,a0,-1942 # 80020e40 <log>
    800045de:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6a6080e7          	jalr	1702(ra) # 80000c86 <release>
      break;
    }
  }
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6902                	ld	s2,0(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045f4:	7139                	addi	sp,sp,-64
    800045f6:	fc06                	sd	ra,56(sp)
    800045f8:	f822                	sd	s0,48(sp)
    800045fa:	f426                	sd	s1,40(sp)
    800045fc:	f04a                	sd	s2,32(sp)
    800045fe:	ec4e                	sd	s3,24(sp)
    80004600:	e852                	sd	s4,16(sp)
    80004602:	e456                	sd	s5,8(sp)
    80004604:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004606:	0001d497          	auipc	s1,0x1d
    8000460a:	83a48493          	addi	s1,s1,-1990 # 80020e40 <log>
    8000460e:	8526                	mv	a0,s1
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5c2080e7          	jalr	1474(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004618:	509c                	lw	a5,32(s1)
    8000461a:	37fd                	addiw	a5,a5,-1
    8000461c:	0007891b          	sext.w	s2,a5
    80004620:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004622:	50dc                	lw	a5,36(s1)
    80004624:	e7b9                	bnez	a5,80004672 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004626:	04091e63          	bnez	s2,80004682 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000462a:	0001d497          	auipc	s1,0x1d
    8000462e:	81648493          	addi	s1,s1,-2026 # 80020e40 <log>
    80004632:	4785                	li	a5,1
    80004634:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004636:	8526                	mv	a0,s1
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	64e080e7          	jalr	1614(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004640:	54dc                	lw	a5,44(s1)
    80004642:	06f04763          	bgtz	a5,800046b0 <end_op+0xbc>
    acquire(&log.lock);
    80004646:	0001c497          	auipc	s1,0x1c
    8000464a:	7fa48493          	addi	s1,s1,2042 # 80020e40 <log>
    8000464e:	8526                	mv	a0,s1
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	582080e7          	jalr	1410(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004658:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000465c:	8526                	mv	a0,s1
    8000465e:	ffffe097          	auipc	ra,0xffffe
    80004662:	dea080e7          	jalr	-534(ra) # 80002448 <wakeup>
    release(&log.lock);
    80004666:	8526                	mv	a0,s1
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	61e080e7          	jalr	1566(ra) # 80000c86 <release>
}
    80004670:	a03d                	j	8000469e <end_op+0xaa>
    panic("log.committing");
    80004672:	00004517          	auipc	a0,0x4
    80004676:	0a650513          	addi	a0,a0,166 # 80008718 <syscalls+0x1f8>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	ec2080e7          	jalr	-318(ra) # 8000053c <panic>
    wakeup(&log);
    80004682:	0001c497          	auipc	s1,0x1c
    80004686:	7be48493          	addi	s1,s1,1982 # 80020e40 <log>
    8000468a:	8526                	mv	a0,s1
    8000468c:	ffffe097          	auipc	ra,0xffffe
    80004690:	dbc080e7          	jalr	-580(ra) # 80002448 <wakeup>
  release(&log.lock);
    80004694:	8526                	mv	a0,s1
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	5f0080e7          	jalr	1520(ra) # 80000c86 <release>
}
    8000469e:	70e2                	ld	ra,56(sp)
    800046a0:	7442                	ld	s0,48(sp)
    800046a2:	74a2                	ld	s1,40(sp)
    800046a4:	7902                	ld	s2,32(sp)
    800046a6:	69e2                	ld	s3,24(sp)
    800046a8:	6a42                	ld	s4,16(sp)
    800046aa:	6aa2                	ld	s5,8(sp)
    800046ac:	6121                	addi	sp,sp,64
    800046ae:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b0:	0001ca97          	auipc	s5,0x1c
    800046b4:	7c0a8a93          	addi	s5,s5,1984 # 80020e70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046b8:	0001ca17          	auipc	s4,0x1c
    800046bc:	788a0a13          	addi	s4,s4,1928 # 80020e40 <log>
    800046c0:	018a2583          	lw	a1,24(s4)
    800046c4:	012585bb          	addw	a1,a1,s2
    800046c8:	2585                	addiw	a1,a1,1
    800046ca:	028a2503          	lw	a0,40(s4)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	cf6080e7          	jalr	-778(ra) # 800033c4 <bread>
    800046d6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046d8:	000aa583          	lw	a1,0(s5)
    800046dc:	028a2503          	lw	a0,40(s4)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	ce4080e7          	jalr	-796(ra) # 800033c4 <bread>
    800046e8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046ea:	40000613          	li	a2,1024
    800046ee:	05850593          	addi	a1,a0,88
    800046f2:	05848513          	addi	a0,s1,88
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	634080e7          	jalr	1588(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800046fe:	8526                	mv	a0,s1
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	db6080e7          	jalr	-586(ra) # 800034b6 <bwrite>
    brelse(from);
    80004708:	854e                	mv	a0,s3
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	dea080e7          	jalr	-534(ra) # 800034f4 <brelse>
    brelse(to);
    80004712:	8526                	mv	a0,s1
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	de0080e7          	jalr	-544(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000471c:	2905                	addiw	s2,s2,1
    8000471e:	0a91                	addi	s5,s5,4
    80004720:	02ca2783          	lw	a5,44(s4)
    80004724:	f8f94ee3          	blt	s2,a5,800046c0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	c8c080e7          	jalr	-884(ra) # 800043b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004730:	4501                	li	a0,0
    80004732:	00000097          	auipc	ra,0x0
    80004736:	cec080e7          	jalr	-788(ra) # 8000441e <install_trans>
    log.lh.n = 0;
    8000473a:	0001c797          	auipc	a5,0x1c
    8000473e:	7207a923          	sw	zero,1842(a5) # 80020e6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004742:	00000097          	auipc	ra,0x0
    80004746:	c72080e7          	jalr	-910(ra) # 800043b4 <write_head>
    8000474a:	bdf5                	j	80004646 <end_op+0x52>

000000008000474c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	e04a                	sd	s2,0(sp)
    80004756:	1000                	addi	s0,sp,32
    80004758:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000475a:	0001c917          	auipc	s2,0x1c
    8000475e:	6e690913          	addi	s2,s2,1766 # 80020e40 <log>
    80004762:	854a                	mv	a0,s2
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	46e080e7          	jalr	1134(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000476c:	02c92603          	lw	a2,44(s2)
    80004770:	47f5                	li	a5,29
    80004772:	06c7c563          	blt	a5,a2,800047dc <log_write+0x90>
    80004776:	0001c797          	auipc	a5,0x1c
    8000477a:	6e67a783          	lw	a5,1766(a5) # 80020e5c <log+0x1c>
    8000477e:	37fd                	addiw	a5,a5,-1
    80004780:	04f65e63          	bge	a2,a5,800047dc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004784:	0001c797          	auipc	a5,0x1c
    80004788:	6dc7a783          	lw	a5,1756(a5) # 80020e60 <log+0x20>
    8000478c:	06f05063          	blez	a5,800047ec <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004790:	4781                	li	a5,0
    80004792:	06c05563          	blez	a2,800047fc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004796:	44cc                	lw	a1,12(s1)
    80004798:	0001c717          	auipc	a4,0x1c
    8000479c:	6d870713          	addi	a4,a4,1752 # 80020e70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047a0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047a2:	4314                	lw	a3,0(a4)
    800047a4:	04b68c63          	beq	a3,a1,800047fc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047a8:	2785                	addiw	a5,a5,1
    800047aa:	0711                	addi	a4,a4,4
    800047ac:	fef61be3          	bne	a2,a5,800047a2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047b0:	0621                	addi	a2,a2,8
    800047b2:	060a                	slli	a2,a2,0x2
    800047b4:	0001c797          	auipc	a5,0x1c
    800047b8:	68c78793          	addi	a5,a5,1676 # 80020e40 <log>
    800047bc:	97b2                	add	a5,a5,a2
    800047be:	44d8                	lw	a4,12(s1)
    800047c0:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047c2:	8526                	mv	a0,s1
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	dcc080e7          	jalr	-564(ra) # 80003590 <bpin>
    log.lh.n++;
    800047cc:	0001c717          	auipc	a4,0x1c
    800047d0:	67470713          	addi	a4,a4,1652 # 80020e40 <log>
    800047d4:	575c                	lw	a5,44(a4)
    800047d6:	2785                	addiw	a5,a5,1
    800047d8:	d75c                	sw	a5,44(a4)
    800047da:	a82d                	j	80004814 <log_write+0xc8>
    panic("too big a transaction");
    800047dc:	00004517          	auipc	a0,0x4
    800047e0:	f4c50513          	addi	a0,a0,-180 # 80008728 <syscalls+0x208>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	d58080e7          	jalr	-680(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	f5450513          	addi	a0,a0,-172 # 80008740 <syscalls+0x220>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d48080e7          	jalr	-696(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800047fc:	00878693          	addi	a3,a5,8
    80004800:	068a                	slli	a3,a3,0x2
    80004802:	0001c717          	auipc	a4,0x1c
    80004806:	63e70713          	addi	a4,a4,1598 # 80020e40 <log>
    8000480a:	9736                	add	a4,a4,a3
    8000480c:	44d4                	lw	a3,12(s1)
    8000480e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004810:	faf609e3          	beq	a2,a5,800047c2 <log_write+0x76>
  }
  release(&log.lock);
    80004814:	0001c517          	auipc	a0,0x1c
    80004818:	62c50513          	addi	a0,a0,1580 # 80020e40 <log>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	46a080e7          	jalr	1130(ra) # 80000c86 <release>
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004830:	1101                	addi	sp,sp,-32
    80004832:	ec06                	sd	ra,24(sp)
    80004834:	e822                	sd	s0,16(sp)
    80004836:	e426                	sd	s1,8(sp)
    80004838:	e04a                	sd	s2,0(sp)
    8000483a:	1000                	addi	s0,sp,32
    8000483c:	84aa                	mv	s1,a0
    8000483e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004840:	00004597          	auipc	a1,0x4
    80004844:	f2058593          	addi	a1,a1,-224 # 80008760 <syscalls+0x240>
    80004848:	0521                	addi	a0,a0,8
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	2f8080e7          	jalr	760(ra) # 80000b42 <initlock>
  lk->name = name;
    80004852:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004856:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000485a:	0204a423          	sw	zero,40(s1)
}
    8000485e:	60e2                	ld	ra,24(sp)
    80004860:	6442                	ld	s0,16(sp)
    80004862:	64a2                	ld	s1,8(sp)
    80004864:	6902                	ld	s2,0(sp)
    80004866:	6105                	addi	sp,sp,32
    80004868:	8082                	ret

000000008000486a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000486a:	1101                	addi	sp,sp,-32
    8000486c:	ec06                	sd	ra,24(sp)
    8000486e:	e822                	sd	s0,16(sp)
    80004870:	e426                	sd	s1,8(sp)
    80004872:	e04a                	sd	s2,0(sp)
    80004874:	1000                	addi	s0,sp,32
    80004876:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004878:	00850913          	addi	s2,a0,8
    8000487c:	854a                	mv	a0,s2
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	354080e7          	jalr	852(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004886:	409c                	lw	a5,0(s1)
    80004888:	cb89                	beqz	a5,8000489a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000488a:	85ca                	mv	a1,s2
    8000488c:	8526                	mv	a0,s1
    8000488e:	ffffe097          	auipc	ra,0xffffe
    80004892:	b56080e7          	jalr	-1194(ra) # 800023e4 <sleep>
  while (lk->locked) {
    80004896:	409c                	lw	a5,0(s1)
    80004898:	fbed                	bnez	a5,8000488a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000489a:	4785                	li	a5,1
    8000489c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000489e:	ffffd097          	auipc	ra,0xffffd
    800048a2:	3de080e7          	jalr	990(ra) # 80001c7c <myproc>
    800048a6:	591c                	lw	a5,48(a0)
    800048a8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048aa:	854a                	mv	a0,s2
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3da080e7          	jalr	986(ra) # 80000c86 <release>
}
    800048b4:	60e2                	ld	ra,24(sp)
    800048b6:	6442                	ld	s0,16(sp)
    800048b8:	64a2                	ld	s1,8(sp)
    800048ba:	6902                	ld	s2,0(sp)
    800048bc:	6105                	addi	sp,sp,32
    800048be:	8082                	ret

00000000800048c0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048c0:	1101                	addi	sp,sp,-32
    800048c2:	ec06                	sd	ra,24(sp)
    800048c4:	e822                	sd	s0,16(sp)
    800048c6:	e426                	sd	s1,8(sp)
    800048c8:	e04a                	sd	s2,0(sp)
    800048ca:	1000                	addi	s0,sp,32
    800048cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ce:	00850913          	addi	s2,a0,8
    800048d2:	854a                	mv	a0,s2
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800048dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048e0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048e4:	8526                	mv	a0,s1
    800048e6:	ffffe097          	auipc	ra,0xffffe
    800048ea:	b62080e7          	jalr	-1182(ra) # 80002448 <wakeup>
  release(&lk->lk);
    800048ee:	854a                	mv	a0,s2
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	396080e7          	jalr	918(ra) # 80000c86 <release>
}
    800048f8:	60e2                	ld	ra,24(sp)
    800048fa:	6442                	ld	s0,16(sp)
    800048fc:	64a2                	ld	s1,8(sp)
    800048fe:	6902                	ld	s2,0(sp)
    80004900:	6105                	addi	sp,sp,32
    80004902:	8082                	ret

0000000080004904 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004904:	7179                	addi	sp,sp,-48
    80004906:	f406                	sd	ra,40(sp)
    80004908:	f022                	sd	s0,32(sp)
    8000490a:	ec26                	sd	s1,24(sp)
    8000490c:	e84a                	sd	s2,16(sp)
    8000490e:	e44e                	sd	s3,8(sp)
    80004910:	1800                	addi	s0,sp,48
    80004912:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004914:	00850913          	addi	s2,a0,8
    80004918:	854a                	mv	a0,s2
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	2b8080e7          	jalr	696(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004922:	409c                	lw	a5,0(s1)
    80004924:	ef99                	bnez	a5,80004942 <holdingsleep+0x3e>
    80004926:	4481                	li	s1,0
  release(&lk->lk);
    80004928:	854a                	mv	a0,s2
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	35c080e7          	jalr	860(ra) # 80000c86 <release>
  return r;
}
    80004932:	8526                	mv	a0,s1
    80004934:	70a2                	ld	ra,40(sp)
    80004936:	7402                	ld	s0,32(sp)
    80004938:	64e2                	ld	s1,24(sp)
    8000493a:	6942                	ld	s2,16(sp)
    8000493c:	69a2                	ld	s3,8(sp)
    8000493e:	6145                	addi	sp,sp,48
    80004940:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004942:	0284a983          	lw	s3,40(s1)
    80004946:	ffffd097          	auipc	ra,0xffffd
    8000494a:	336080e7          	jalr	822(ra) # 80001c7c <myproc>
    8000494e:	5904                	lw	s1,48(a0)
    80004950:	413484b3          	sub	s1,s1,s3
    80004954:	0014b493          	seqz	s1,s1
    80004958:	bfc1                	j	80004928 <holdingsleep+0x24>

000000008000495a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000495a:	1141                	addi	sp,sp,-16
    8000495c:	e406                	sd	ra,8(sp)
    8000495e:	e022                	sd	s0,0(sp)
    80004960:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004962:	00004597          	auipc	a1,0x4
    80004966:	e0e58593          	addi	a1,a1,-498 # 80008770 <syscalls+0x250>
    8000496a:	0001c517          	auipc	a0,0x1c
    8000496e:	61e50513          	addi	a0,a0,1566 # 80020f88 <ftable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	1d0080e7          	jalr	464(ra) # 80000b42 <initlock>
}
    8000497a:	60a2                	ld	ra,8(sp)
    8000497c:	6402                	ld	s0,0(sp)
    8000497e:	0141                	addi	sp,sp,16
    80004980:	8082                	ret

0000000080004982 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004982:	1101                	addi	sp,sp,-32
    80004984:	ec06                	sd	ra,24(sp)
    80004986:	e822                	sd	s0,16(sp)
    80004988:	e426                	sd	s1,8(sp)
    8000498a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000498c:	0001c517          	auipc	a0,0x1c
    80004990:	5fc50513          	addi	a0,a0,1532 # 80020f88 <ftable>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	23e080e7          	jalr	574(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000499c:	0001c497          	auipc	s1,0x1c
    800049a0:	60448493          	addi	s1,s1,1540 # 80020fa0 <ftable+0x18>
    800049a4:	0001d717          	auipc	a4,0x1d
    800049a8:	59c70713          	addi	a4,a4,1436 # 80021f40 <disk>
    if(f->ref == 0){
    800049ac:	40dc                	lw	a5,4(s1)
    800049ae:	cf99                	beqz	a5,800049cc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049b0:	02848493          	addi	s1,s1,40
    800049b4:	fee49ce3          	bne	s1,a4,800049ac <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049b8:	0001c517          	auipc	a0,0x1c
    800049bc:	5d050513          	addi	a0,a0,1488 # 80020f88 <ftable>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	2c6080e7          	jalr	710(ra) # 80000c86 <release>
  return 0;
    800049c8:	4481                	li	s1,0
    800049ca:	a819                	j	800049e0 <filealloc+0x5e>
      f->ref = 1;
    800049cc:	4785                	li	a5,1
    800049ce:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049d0:	0001c517          	auipc	a0,0x1c
    800049d4:	5b850513          	addi	a0,a0,1464 # 80020f88 <ftable>
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	2ae080e7          	jalr	686(ra) # 80000c86 <release>
}
    800049e0:	8526                	mv	a0,s1
    800049e2:	60e2                	ld	ra,24(sp)
    800049e4:	6442                	ld	s0,16(sp)
    800049e6:	64a2                	ld	s1,8(sp)
    800049e8:	6105                	addi	sp,sp,32
    800049ea:	8082                	ret

00000000800049ec <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049ec:	1101                	addi	sp,sp,-32
    800049ee:	ec06                	sd	ra,24(sp)
    800049f0:	e822                	sd	s0,16(sp)
    800049f2:	e426                	sd	s1,8(sp)
    800049f4:	1000                	addi	s0,sp,32
    800049f6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049f8:	0001c517          	auipc	a0,0x1c
    800049fc:	59050513          	addi	a0,a0,1424 # 80020f88 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	1d2080e7          	jalr	466(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a08:	40dc                	lw	a5,4(s1)
    80004a0a:	02f05263          	blez	a5,80004a2e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a0e:	2785                	addiw	a5,a5,1
    80004a10:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a12:	0001c517          	auipc	a0,0x1c
    80004a16:	57650513          	addi	a0,a0,1398 # 80020f88 <ftable>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	26c080e7          	jalr	620(ra) # 80000c86 <release>
  return f;
}
    80004a22:	8526                	mv	a0,s1
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6105                	addi	sp,sp,32
    80004a2c:	8082                	ret
    panic("filedup");
    80004a2e:	00004517          	auipc	a0,0x4
    80004a32:	d4a50513          	addi	a0,a0,-694 # 80008778 <syscalls+0x258>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	b06080e7          	jalr	-1274(ra) # 8000053c <panic>

0000000080004a3e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a3e:	7139                	addi	sp,sp,-64
    80004a40:	fc06                	sd	ra,56(sp)
    80004a42:	f822                	sd	s0,48(sp)
    80004a44:	f426                	sd	s1,40(sp)
    80004a46:	f04a                	sd	s2,32(sp)
    80004a48:	ec4e                	sd	s3,24(sp)
    80004a4a:	e852                	sd	s4,16(sp)
    80004a4c:	e456                	sd	s5,8(sp)
    80004a4e:	0080                	addi	s0,sp,64
    80004a50:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a52:	0001c517          	auipc	a0,0x1c
    80004a56:	53650513          	addi	a0,a0,1334 # 80020f88 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	178080e7          	jalr	376(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a62:	40dc                	lw	a5,4(s1)
    80004a64:	06f05163          	blez	a5,80004ac6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a68:	37fd                	addiw	a5,a5,-1
    80004a6a:	0007871b          	sext.w	a4,a5
    80004a6e:	c0dc                	sw	a5,4(s1)
    80004a70:	06e04363          	bgtz	a4,80004ad6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a74:	0004a903          	lw	s2,0(s1)
    80004a78:	0094ca83          	lbu	s5,9(s1)
    80004a7c:	0104ba03          	ld	s4,16(s1)
    80004a80:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a84:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a88:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a8c:	0001c517          	auipc	a0,0x1c
    80004a90:	4fc50513          	addi	a0,a0,1276 # 80020f88 <ftable>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	1f2080e7          	jalr	498(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004a9c:	4785                	li	a5,1
    80004a9e:	04f90d63          	beq	s2,a5,80004af8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004aa2:	3979                	addiw	s2,s2,-2
    80004aa4:	4785                	li	a5,1
    80004aa6:	0527e063          	bltu	a5,s2,80004ae6 <fileclose+0xa8>
    begin_op();
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	ad0080e7          	jalr	-1328(ra) # 8000457a <begin_op>
    iput(ff.ip);
    80004ab2:	854e                	mv	a0,s3
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	2da080e7          	jalr	730(ra) # 80003d8e <iput>
    end_op();
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	b38080e7          	jalr	-1224(ra) # 800045f4 <end_op>
    80004ac4:	a00d                	j	80004ae6 <fileclose+0xa8>
    panic("fileclose");
    80004ac6:	00004517          	auipc	a0,0x4
    80004aca:	cba50513          	addi	a0,a0,-838 # 80008780 <syscalls+0x260>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	a6e080e7          	jalr	-1426(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004ad6:	0001c517          	auipc	a0,0x1c
    80004ada:	4b250513          	addi	a0,a0,1202 # 80020f88 <ftable>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1a8080e7          	jalr	424(ra) # 80000c86 <release>
  }
}
    80004ae6:	70e2                	ld	ra,56(sp)
    80004ae8:	7442                	ld	s0,48(sp)
    80004aea:	74a2                	ld	s1,40(sp)
    80004aec:	7902                	ld	s2,32(sp)
    80004aee:	69e2                	ld	s3,24(sp)
    80004af0:	6a42                	ld	s4,16(sp)
    80004af2:	6aa2                	ld	s5,8(sp)
    80004af4:	6121                	addi	sp,sp,64
    80004af6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004af8:	85d6                	mv	a1,s5
    80004afa:	8552                	mv	a0,s4
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	348080e7          	jalr	840(ra) # 80004e44 <pipeclose>
    80004b04:	b7cd                	j	80004ae6 <fileclose+0xa8>

0000000080004b06 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b06:	715d                	addi	sp,sp,-80
    80004b08:	e486                	sd	ra,72(sp)
    80004b0a:	e0a2                	sd	s0,64(sp)
    80004b0c:	fc26                	sd	s1,56(sp)
    80004b0e:	f84a                	sd	s2,48(sp)
    80004b10:	f44e                	sd	s3,40(sp)
    80004b12:	0880                	addi	s0,sp,80
    80004b14:	84aa                	mv	s1,a0
    80004b16:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b18:	ffffd097          	auipc	ra,0xffffd
    80004b1c:	164080e7          	jalr	356(ra) # 80001c7c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b20:	409c                	lw	a5,0(s1)
    80004b22:	37f9                	addiw	a5,a5,-2
    80004b24:	4705                	li	a4,1
    80004b26:	04f76763          	bltu	a4,a5,80004b74 <filestat+0x6e>
    80004b2a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b2c:	6c88                	ld	a0,24(s1)
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	0a6080e7          	jalr	166(ra) # 80003bd4 <ilock>
    stati(f->ip, &st);
    80004b36:	fb840593          	addi	a1,s0,-72
    80004b3a:	6c88                	ld	a0,24(s1)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	322080e7          	jalr	802(ra) # 80003e5e <stati>
    iunlock(f->ip);
    80004b44:	6c88                	ld	a0,24(s1)
    80004b46:	fffff097          	auipc	ra,0xfffff
    80004b4a:	150080e7          	jalr	336(ra) # 80003c96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b4e:	46e1                	li	a3,24
    80004b50:	fb840613          	addi	a2,s0,-72
    80004b54:	85ce                	mv	a1,s3
    80004b56:	05893503          	ld	a0,88(s2)
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	b0c080e7          	jalr	-1268(ra) # 80001666 <copyout>
    80004b62:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b66:	60a6                	ld	ra,72(sp)
    80004b68:	6406                	ld	s0,64(sp)
    80004b6a:	74e2                	ld	s1,56(sp)
    80004b6c:	7942                	ld	s2,48(sp)
    80004b6e:	79a2                	ld	s3,40(sp)
    80004b70:	6161                	addi	sp,sp,80
    80004b72:	8082                	ret
  return -1;
    80004b74:	557d                	li	a0,-1
    80004b76:	bfc5                	j	80004b66 <filestat+0x60>

0000000080004b78 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b78:	7179                	addi	sp,sp,-48
    80004b7a:	f406                	sd	ra,40(sp)
    80004b7c:	f022                	sd	s0,32(sp)
    80004b7e:	ec26                	sd	s1,24(sp)
    80004b80:	e84a                	sd	s2,16(sp)
    80004b82:	e44e                	sd	s3,8(sp)
    80004b84:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b86:	00854783          	lbu	a5,8(a0)
    80004b8a:	c3d5                	beqz	a5,80004c2e <fileread+0xb6>
    80004b8c:	84aa                	mv	s1,a0
    80004b8e:	89ae                	mv	s3,a1
    80004b90:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b92:	411c                	lw	a5,0(a0)
    80004b94:	4705                	li	a4,1
    80004b96:	04e78963          	beq	a5,a4,80004be8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b9a:	470d                	li	a4,3
    80004b9c:	04e78d63          	beq	a5,a4,80004bf6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ba0:	4709                	li	a4,2
    80004ba2:	06e79e63          	bne	a5,a4,80004c1e <fileread+0xa6>
    ilock(f->ip);
    80004ba6:	6d08                	ld	a0,24(a0)
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	02c080e7          	jalr	44(ra) # 80003bd4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bb0:	874a                	mv	a4,s2
    80004bb2:	5094                	lw	a3,32(s1)
    80004bb4:	864e                	mv	a2,s3
    80004bb6:	4585                	li	a1,1
    80004bb8:	6c88                	ld	a0,24(s1)
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	2ce080e7          	jalr	718(ra) # 80003e88 <readi>
    80004bc2:	892a                	mv	s2,a0
    80004bc4:	00a05563          	blez	a0,80004bce <fileread+0x56>
      f->off += r;
    80004bc8:	509c                	lw	a5,32(s1)
    80004bca:	9fa9                	addw	a5,a5,a0
    80004bcc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bce:	6c88                	ld	a0,24(s1)
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	0c6080e7          	jalr	198(ra) # 80003c96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bd8:	854a                	mv	a0,s2
    80004bda:	70a2                	ld	ra,40(sp)
    80004bdc:	7402                	ld	s0,32(sp)
    80004bde:	64e2                	ld	s1,24(sp)
    80004be0:	6942                	ld	s2,16(sp)
    80004be2:	69a2                	ld	s3,8(sp)
    80004be4:	6145                	addi	sp,sp,48
    80004be6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004be8:	6908                	ld	a0,16(a0)
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	3c2080e7          	jalr	962(ra) # 80004fac <piperead>
    80004bf2:	892a                	mv	s2,a0
    80004bf4:	b7d5                	j	80004bd8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bf6:	02451783          	lh	a5,36(a0)
    80004bfa:	03079693          	slli	a3,a5,0x30
    80004bfe:	92c1                	srli	a3,a3,0x30
    80004c00:	4725                	li	a4,9
    80004c02:	02d76863          	bltu	a4,a3,80004c32 <fileread+0xba>
    80004c06:	0792                	slli	a5,a5,0x4
    80004c08:	0001c717          	auipc	a4,0x1c
    80004c0c:	2e070713          	addi	a4,a4,736 # 80020ee8 <devsw>
    80004c10:	97ba                	add	a5,a5,a4
    80004c12:	639c                	ld	a5,0(a5)
    80004c14:	c38d                	beqz	a5,80004c36 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c16:	4505                	li	a0,1
    80004c18:	9782                	jalr	a5
    80004c1a:	892a                	mv	s2,a0
    80004c1c:	bf75                	j	80004bd8 <fileread+0x60>
    panic("fileread");
    80004c1e:	00004517          	auipc	a0,0x4
    80004c22:	b7250513          	addi	a0,a0,-1166 # 80008790 <syscalls+0x270>
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	916080e7          	jalr	-1770(ra) # 8000053c <panic>
    return -1;
    80004c2e:	597d                	li	s2,-1
    80004c30:	b765                	j	80004bd8 <fileread+0x60>
      return -1;
    80004c32:	597d                	li	s2,-1
    80004c34:	b755                	j	80004bd8 <fileread+0x60>
    80004c36:	597d                	li	s2,-1
    80004c38:	b745                	j	80004bd8 <fileread+0x60>

0000000080004c3a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c3a:	00954783          	lbu	a5,9(a0)
    80004c3e:	10078e63          	beqz	a5,80004d5a <filewrite+0x120>
{
    80004c42:	715d                	addi	sp,sp,-80
    80004c44:	e486                	sd	ra,72(sp)
    80004c46:	e0a2                	sd	s0,64(sp)
    80004c48:	fc26                	sd	s1,56(sp)
    80004c4a:	f84a                	sd	s2,48(sp)
    80004c4c:	f44e                	sd	s3,40(sp)
    80004c4e:	f052                	sd	s4,32(sp)
    80004c50:	ec56                	sd	s5,24(sp)
    80004c52:	e85a                	sd	s6,16(sp)
    80004c54:	e45e                	sd	s7,8(sp)
    80004c56:	e062                	sd	s8,0(sp)
    80004c58:	0880                	addi	s0,sp,80
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	8b2e                	mv	s6,a1
    80004c5e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c60:	411c                	lw	a5,0(a0)
    80004c62:	4705                	li	a4,1
    80004c64:	02e78263          	beq	a5,a4,80004c88 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c68:	470d                	li	a4,3
    80004c6a:	02e78563          	beq	a5,a4,80004c94 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c6e:	4709                	li	a4,2
    80004c70:	0ce79d63          	bne	a5,a4,80004d4a <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c74:	0ac05b63          	blez	a2,80004d2a <filewrite+0xf0>
    int i = 0;
    80004c78:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c7a:	6b85                	lui	s7,0x1
    80004c7c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c80:	6c05                	lui	s8,0x1
    80004c82:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c86:	a851                	j	80004d1a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c88:	6908                	ld	a0,16(a0)
    80004c8a:	00000097          	auipc	ra,0x0
    80004c8e:	22a080e7          	jalr	554(ra) # 80004eb4 <pipewrite>
    80004c92:	a045                	j	80004d32 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c94:	02451783          	lh	a5,36(a0)
    80004c98:	03079693          	slli	a3,a5,0x30
    80004c9c:	92c1                	srli	a3,a3,0x30
    80004c9e:	4725                	li	a4,9
    80004ca0:	0ad76f63          	bltu	a4,a3,80004d5e <filewrite+0x124>
    80004ca4:	0792                	slli	a5,a5,0x4
    80004ca6:	0001c717          	auipc	a4,0x1c
    80004caa:	24270713          	addi	a4,a4,578 # 80020ee8 <devsw>
    80004cae:	97ba                	add	a5,a5,a4
    80004cb0:	679c                	ld	a5,8(a5)
    80004cb2:	cbc5                	beqz	a5,80004d62 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004cb4:	4505                	li	a0,1
    80004cb6:	9782                	jalr	a5
    80004cb8:	a8ad                	j	80004d32 <filewrite+0xf8>
      if(n1 > max)
    80004cba:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004cbe:	00000097          	auipc	ra,0x0
    80004cc2:	8bc080e7          	jalr	-1860(ra) # 8000457a <begin_op>
      ilock(f->ip);
    80004cc6:	01893503          	ld	a0,24(s2)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	f0a080e7          	jalr	-246(ra) # 80003bd4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cd2:	8756                	mv	a4,s5
    80004cd4:	02092683          	lw	a3,32(s2)
    80004cd8:	01698633          	add	a2,s3,s6
    80004cdc:	4585                	li	a1,1
    80004cde:	01893503          	ld	a0,24(s2)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	29e080e7          	jalr	670(ra) # 80003f80 <writei>
    80004cea:	84aa                	mv	s1,a0
    80004cec:	00a05763          	blez	a0,80004cfa <filewrite+0xc0>
        f->off += r;
    80004cf0:	02092783          	lw	a5,32(s2)
    80004cf4:	9fa9                	addw	a5,a5,a0
    80004cf6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cfa:	01893503          	ld	a0,24(s2)
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	f98080e7          	jalr	-104(ra) # 80003c96 <iunlock>
      end_op();
    80004d06:	00000097          	auipc	ra,0x0
    80004d0a:	8ee080e7          	jalr	-1810(ra) # 800045f4 <end_op>

      if(r != n1){
    80004d0e:	009a9f63          	bne	s5,s1,80004d2c <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d12:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d16:	0149db63          	bge	s3,s4,80004d2c <filewrite+0xf2>
      int n1 = n - i;
    80004d1a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d1e:	0004879b          	sext.w	a5,s1
    80004d22:	f8fbdce3          	bge	s7,a5,80004cba <filewrite+0x80>
    80004d26:	84e2                	mv	s1,s8
    80004d28:	bf49                	j	80004cba <filewrite+0x80>
    int i = 0;
    80004d2a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d2c:	033a1d63          	bne	s4,s3,80004d66 <filewrite+0x12c>
    80004d30:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d32:	60a6                	ld	ra,72(sp)
    80004d34:	6406                	ld	s0,64(sp)
    80004d36:	74e2                	ld	s1,56(sp)
    80004d38:	7942                	ld	s2,48(sp)
    80004d3a:	79a2                	ld	s3,40(sp)
    80004d3c:	7a02                	ld	s4,32(sp)
    80004d3e:	6ae2                	ld	s5,24(sp)
    80004d40:	6b42                	ld	s6,16(sp)
    80004d42:	6ba2                	ld	s7,8(sp)
    80004d44:	6c02                	ld	s8,0(sp)
    80004d46:	6161                	addi	sp,sp,80
    80004d48:	8082                	ret
    panic("filewrite");
    80004d4a:	00004517          	auipc	a0,0x4
    80004d4e:	a5650513          	addi	a0,a0,-1450 # 800087a0 <syscalls+0x280>
    80004d52:	ffffb097          	auipc	ra,0xffffb
    80004d56:	7ea080e7          	jalr	2026(ra) # 8000053c <panic>
    return -1;
    80004d5a:	557d                	li	a0,-1
}
    80004d5c:	8082                	ret
      return -1;
    80004d5e:	557d                	li	a0,-1
    80004d60:	bfc9                	j	80004d32 <filewrite+0xf8>
    80004d62:	557d                	li	a0,-1
    80004d64:	b7f9                	j	80004d32 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d66:	557d                	li	a0,-1
    80004d68:	b7e9                	j	80004d32 <filewrite+0xf8>

0000000080004d6a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d6a:	7179                	addi	sp,sp,-48
    80004d6c:	f406                	sd	ra,40(sp)
    80004d6e:	f022                	sd	s0,32(sp)
    80004d70:	ec26                	sd	s1,24(sp)
    80004d72:	e84a                	sd	s2,16(sp)
    80004d74:	e44e                	sd	s3,8(sp)
    80004d76:	e052                	sd	s4,0(sp)
    80004d78:	1800                	addi	s0,sp,48
    80004d7a:	84aa                	mv	s1,a0
    80004d7c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d7e:	0005b023          	sd	zero,0(a1)
    80004d82:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d86:	00000097          	auipc	ra,0x0
    80004d8a:	bfc080e7          	jalr	-1028(ra) # 80004982 <filealloc>
    80004d8e:	e088                	sd	a0,0(s1)
    80004d90:	c551                	beqz	a0,80004e1c <pipealloc+0xb2>
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	bf0080e7          	jalr	-1040(ra) # 80004982 <filealloc>
    80004d9a:	00aa3023          	sd	a0,0(s4)
    80004d9e:	c92d                	beqz	a0,80004e10 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	d42080e7          	jalr	-702(ra) # 80000ae2 <kalloc>
    80004da8:	892a                	mv	s2,a0
    80004daa:	c125                	beqz	a0,80004e0a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dac:	4985                	li	s3,1
    80004dae:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004db2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004db6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dba:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dbe:	00004597          	auipc	a1,0x4
    80004dc2:	9f258593          	addi	a1,a1,-1550 # 800087b0 <syscalls+0x290>
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	d7c080e7          	jalr	-644(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004dce:	609c                	ld	a5,0(s1)
    80004dd0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dd4:	609c                	ld	a5,0(s1)
    80004dd6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dda:	609c                	ld	a5,0(s1)
    80004ddc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004de0:	609c                	ld	a5,0(s1)
    80004de2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004de6:	000a3783          	ld	a5,0(s4)
    80004dea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dee:	000a3783          	ld	a5,0(s4)
    80004df2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004df6:	000a3783          	ld	a5,0(s4)
    80004dfa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dfe:	000a3783          	ld	a5,0(s4)
    80004e02:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e06:	4501                	li	a0,0
    80004e08:	a025                	j	80004e30 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e0a:	6088                	ld	a0,0(s1)
    80004e0c:	e501                	bnez	a0,80004e14 <pipealloc+0xaa>
    80004e0e:	a039                	j	80004e1c <pipealloc+0xb2>
    80004e10:	6088                	ld	a0,0(s1)
    80004e12:	c51d                	beqz	a0,80004e40 <pipealloc+0xd6>
    fileclose(*f0);
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	c2a080e7          	jalr	-982(ra) # 80004a3e <fileclose>
  if(*f1)
    80004e1c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e20:	557d                	li	a0,-1
  if(*f1)
    80004e22:	c799                	beqz	a5,80004e30 <pipealloc+0xc6>
    fileclose(*f1);
    80004e24:	853e                	mv	a0,a5
    80004e26:	00000097          	auipc	ra,0x0
    80004e2a:	c18080e7          	jalr	-1000(ra) # 80004a3e <fileclose>
  return -1;
    80004e2e:	557d                	li	a0,-1
}
    80004e30:	70a2                	ld	ra,40(sp)
    80004e32:	7402                	ld	s0,32(sp)
    80004e34:	64e2                	ld	s1,24(sp)
    80004e36:	6942                	ld	s2,16(sp)
    80004e38:	69a2                	ld	s3,8(sp)
    80004e3a:	6a02                	ld	s4,0(sp)
    80004e3c:	6145                	addi	sp,sp,48
    80004e3e:	8082                	ret
  return -1;
    80004e40:	557d                	li	a0,-1
    80004e42:	b7fd                	j	80004e30 <pipealloc+0xc6>

0000000080004e44 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e44:	1101                	addi	sp,sp,-32
    80004e46:	ec06                	sd	ra,24(sp)
    80004e48:	e822                	sd	s0,16(sp)
    80004e4a:	e426                	sd	s1,8(sp)
    80004e4c:	e04a                	sd	s2,0(sp)
    80004e4e:	1000                	addi	s0,sp,32
    80004e50:	84aa                	mv	s1,a0
    80004e52:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
  if(writable){
    80004e5c:	02090d63          	beqz	s2,80004e96 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e60:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e64:	21848513          	addi	a0,s1,536
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	5e0080e7          	jalr	1504(ra) # 80002448 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e70:	2204b783          	ld	a5,544(s1)
    80004e74:	eb95                	bnez	a5,80004ea8 <pipeclose+0x64>
    release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	e0e080e7          	jalr	-498(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004e80:	8526                	mv	a0,s1
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	b62080e7          	jalr	-1182(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e8a:	60e2                	ld	ra,24(sp)
    80004e8c:	6442                	ld	s0,16(sp)
    80004e8e:	64a2                	ld	s1,8(sp)
    80004e90:	6902                	ld	s2,0(sp)
    80004e92:	6105                	addi	sp,sp,32
    80004e94:	8082                	ret
    pi->readopen = 0;
    80004e96:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e9a:	21c48513          	addi	a0,s1,540
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	5aa080e7          	jalr	1450(ra) # 80002448 <wakeup>
    80004ea6:	b7e9                	j	80004e70 <pipeclose+0x2c>
    release(&pi->lock);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	ddc080e7          	jalr	-548(ra) # 80000c86 <release>
}
    80004eb2:	bfe1                	j	80004e8a <pipeclose+0x46>

0000000080004eb4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eb4:	711d                	addi	sp,sp,-96
    80004eb6:	ec86                	sd	ra,88(sp)
    80004eb8:	e8a2                	sd	s0,80(sp)
    80004eba:	e4a6                	sd	s1,72(sp)
    80004ebc:	e0ca                	sd	s2,64(sp)
    80004ebe:	fc4e                	sd	s3,56(sp)
    80004ec0:	f852                	sd	s4,48(sp)
    80004ec2:	f456                	sd	s5,40(sp)
    80004ec4:	f05a                	sd	s6,32(sp)
    80004ec6:	ec5e                	sd	s7,24(sp)
    80004ec8:	e862                	sd	s8,16(sp)
    80004eca:	1080                	addi	s0,sp,96
    80004ecc:	84aa                	mv	s1,a0
    80004ece:	8aae                	mv	s5,a1
    80004ed0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ed2:	ffffd097          	auipc	ra,0xffffd
    80004ed6:	daa080e7          	jalr	-598(ra) # 80001c7c <myproc>
    80004eda:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	cf4080e7          	jalr	-780(ra) # 80000bd2 <acquire>
  while(i < n){
    80004ee6:	0b405663          	blez	s4,80004f92 <pipewrite+0xde>
  int i = 0;
    80004eea:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eec:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eee:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ef2:	21c48b93          	addi	s7,s1,540
    80004ef6:	a089                	j	80004f38 <pipewrite+0x84>
      release(&pi->lock);
    80004ef8:	8526                	mv	a0,s1
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	d8c080e7          	jalr	-628(ra) # 80000c86 <release>
      return -1;
    80004f02:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f04:	854a                	mv	a0,s2
    80004f06:	60e6                	ld	ra,88(sp)
    80004f08:	6446                	ld	s0,80(sp)
    80004f0a:	64a6                	ld	s1,72(sp)
    80004f0c:	6906                	ld	s2,64(sp)
    80004f0e:	79e2                	ld	s3,56(sp)
    80004f10:	7a42                	ld	s4,48(sp)
    80004f12:	7aa2                	ld	s5,40(sp)
    80004f14:	7b02                	ld	s6,32(sp)
    80004f16:	6be2                	ld	s7,24(sp)
    80004f18:	6c42                	ld	s8,16(sp)
    80004f1a:	6125                	addi	sp,sp,96
    80004f1c:	8082                	ret
      wakeup(&pi->nread);
    80004f1e:	8562                	mv	a0,s8
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	528080e7          	jalr	1320(ra) # 80002448 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f28:	85a6                	mv	a1,s1
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	4b8080e7          	jalr	1208(ra) # 800023e4 <sleep>
  while(i < n){
    80004f34:	07495063          	bge	s2,s4,80004f94 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f38:	2204a783          	lw	a5,544(s1)
    80004f3c:	dfd5                	beqz	a5,80004ef8 <pipewrite+0x44>
    80004f3e:	854e                	mv	a0,s3
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	74c080e7          	jalr	1868(ra) # 8000268c <killed>
    80004f48:	f945                	bnez	a0,80004ef8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f4a:	2184a783          	lw	a5,536(s1)
    80004f4e:	21c4a703          	lw	a4,540(s1)
    80004f52:	2007879b          	addiw	a5,a5,512
    80004f56:	fcf704e3          	beq	a4,a5,80004f1e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f5a:	4685                	li	a3,1
    80004f5c:	01590633          	add	a2,s2,s5
    80004f60:	faf40593          	addi	a1,s0,-81
    80004f64:	0589b503          	ld	a0,88(s3)
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	78a080e7          	jalr	1930(ra) # 800016f2 <copyin>
    80004f70:	03650263          	beq	a0,s6,80004f94 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f74:	21c4a783          	lw	a5,540(s1)
    80004f78:	0017871b          	addiw	a4,a5,1
    80004f7c:	20e4ae23          	sw	a4,540(s1)
    80004f80:	1ff7f793          	andi	a5,a5,511
    80004f84:	97a6                	add	a5,a5,s1
    80004f86:	faf44703          	lbu	a4,-81(s0)
    80004f8a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f8e:	2905                	addiw	s2,s2,1
    80004f90:	b755                	j	80004f34 <pipewrite+0x80>
  int i = 0;
    80004f92:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f94:	21848513          	addi	a0,s1,536
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	4b0080e7          	jalr	1200(ra) # 80002448 <wakeup>
  release(&pi->lock);
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	ce4080e7          	jalr	-796(ra) # 80000c86 <release>
  return i;
    80004faa:	bfa9                	j	80004f04 <pipewrite+0x50>

0000000080004fac <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fac:	715d                	addi	sp,sp,-80
    80004fae:	e486                	sd	ra,72(sp)
    80004fb0:	e0a2                	sd	s0,64(sp)
    80004fb2:	fc26                	sd	s1,56(sp)
    80004fb4:	f84a                	sd	s2,48(sp)
    80004fb6:	f44e                	sd	s3,40(sp)
    80004fb8:	f052                	sd	s4,32(sp)
    80004fba:	ec56                	sd	s5,24(sp)
    80004fbc:	e85a                	sd	s6,16(sp)
    80004fbe:	0880                	addi	s0,sp,80
    80004fc0:	84aa                	mv	s1,a0
    80004fc2:	892e                	mv	s2,a1
    80004fc4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	cb6080e7          	jalr	-842(ra) # 80001c7c <myproc>
    80004fce:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	c00080e7          	jalr	-1024(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	2184a703          	lw	a4,536(s1)
    80004fde:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe6:	02f71763          	bne	a4,a5,80005014 <piperead+0x68>
    80004fea:	2244a783          	lw	a5,548(s1)
    80004fee:	c39d                	beqz	a5,80005014 <piperead+0x68>
    if(killed(pr)){
    80004ff0:	8552                	mv	a0,s4
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	69a080e7          	jalr	1690(ra) # 8000268c <killed>
    80004ffa:	e949                	bnez	a0,8000508c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ffc:	85a6                	mv	a1,s1
    80004ffe:	854e                	mv	a0,s3
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	3e4080e7          	jalr	996(ra) # 800023e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005008:	2184a703          	lw	a4,536(s1)
    8000500c:	21c4a783          	lw	a5,540(s1)
    80005010:	fcf70de3          	beq	a4,a5,80004fea <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005014:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005016:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005018:	05505463          	blez	s5,80005060 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000501c:	2184a783          	lw	a5,536(s1)
    80005020:	21c4a703          	lw	a4,540(s1)
    80005024:	02f70e63          	beq	a4,a5,80005060 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005028:	0017871b          	addiw	a4,a5,1
    8000502c:	20e4ac23          	sw	a4,536(s1)
    80005030:	1ff7f793          	andi	a5,a5,511
    80005034:	97a6                	add	a5,a5,s1
    80005036:	0187c783          	lbu	a5,24(a5)
    8000503a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503e:	4685                	li	a3,1
    80005040:	fbf40613          	addi	a2,s0,-65
    80005044:	85ca                	mv	a1,s2
    80005046:	058a3503          	ld	a0,88(s4)
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	61c080e7          	jalr	1564(ra) # 80001666 <copyout>
    80005052:	01650763          	beq	a0,s6,80005060 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005056:	2985                	addiw	s3,s3,1
    80005058:	0905                	addi	s2,s2,1
    8000505a:	fd3a91e3          	bne	s5,s3,8000501c <piperead+0x70>
    8000505e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005060:	21c48513          	addi	a0,s1,540
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	3e4080e7          	jalr	996(ra) # 80002448 <wakeup>
  release(&pi->lock);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	c18080e7          	jalr	-1000(ra) # 80000c86 <release>
  return i;
}
    80005076:	854e                	mv	a0,s3
    80005078:	60a6                	ld	ra,72(sp)
    8000507a:	6406                	ld	s0,64(sp)
    8000507c:	74e2                	ld	s1,56(sp)
    8000507e:	7942                	ld	s2,48(sp)
    80005080:	79a2                	ld	s3,40(sp)
    80005082:	7a02                	ld	s4,32(sp)
    80005084:	6ae2                	ld	s5,24(sp)
    80005086:	6b42                	ld	s6,16(sp)
    80005088:	6161                	addi	sp,sp,80
    8000508a:	8082                	ret
      release(&pi->lock);
    8000508c:	8526                	mv	a0,s1
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	bf8080e7          	jalr	-1032(ra) # 80000c86 <release>
      return -1;
    80005096:	59fd                	li	s3,-1
    80005098:	bff9                	j	80005076 <piperead+0xca>

000000008000509a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000509a:	1141                	addi	sp,sp,-16
    8000509c:	e422                	sd	s0,8(sp)
    8000509e:	0800                	addi	s0,sp,16
    800050a0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050a2:	8905                	andi	a0,a0,1
    800050a4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800050a6:	8b89                	andi	a5,a5,2
    800050a8:	c399                	beqz	a5,800050ae <flags2perm+0x14>
      perm |= PTE_W;
    800050aa:	00456513          	ori	a0,a0,4
    return perm;
}
    800050ae:	6422                	ld	s0,8(sp)
    800050b0:	0141                	addi	sp,sp,16
    800050b2:	8082                	ret

00000000800050b4 <exec>:

int
exec(char *path, char **argv)
{
    800050b4:	df010113          	addi	sp,sp,-528
    800050b8:	20113423          	sd	ra,520(sp)
    800050bc:	20813023          	sd	s0,512(sp)
    800050c0:	ffa6                	sd	s1,504(sp)
    800050c2:	fbca                	sd	s2,496(sp)
    800050c4:	f7ce                	sd	s3,488(sp)
    800050c6:	f3d2                	sd	s4,480(sp)
    800050c8:	efd6                	sd	s5,472(sp)
    800050ca:	ebda                	sd	s6,464(sp)
    800050cc:	e7de                	sd	s7,456(sp)
    800050ce:	e3e2                	sd	s8,448(sp)
    800050d0:	ff66                	sd	s9,440(sp)
    800050d2:	fb6a                	sd	s10,432(sp)
    800050d4:	f76e                	sd	s11,424(sp)
    800050d6:	0c00                	addi	s0,sp,528
    800050d8:	892a                	mv	s2,a0
    800050da:	dea43c23          	sd	a0,-520(s0)
    800050de:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	b9a080e7          	jalr	-1126(ra) # 80001c7c <myproc>
    800050ea:	84aa                	mv	s1,a0

  begin_op();
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	48e080e7          	jalr	1166(ra) # 8000457a <begin_op>

  if((ip = namei(path)) == 0){
    800050f4:	854a                	mv	a0,s2
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	284080e7          	jalr	644(ra) # 8000437a <namei>
    800050fe:	c92d                	beqz	a0,80005170 <exec+0xbc>
    80005100:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	ad2080e7          	jalr	-1326(ra) # 80003bd4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000510a:	04000713          	li	a4,64
    8000510e:	4681                	li	a3,0
    80005110:	e5040613          	addi	a2,s0,-432
    80005114:	4581                	li	a1,0
    80005116:	8552                	mv	a0,s4
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	d70080e7          	jalr	-656(ra) # 80003e88 <readi>
    80005120:	04000793          	li	a5,64
    80005124:	00f51a63          	bne	a0,a5,80005138 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005128:	e5042703          	lw	a4,-432(s0)
    8000512c:	464c47b7          	lui	a5,0x464c4
    80005130:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005134:	04f70463          	beq	a4,a5,8000517c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005138:	8552                	mv	a0,s4
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	cfc080e7          	jalr	-772(ra) # 80003e36 <iunlockput>
    end_op();
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	4b2080e7          	jalr	1202(ra) # 800045f4 <end_op>
  }
  return -1;
    8000514a:	557d                	li	a0,-1
}
    8000514c:	20813083          	ld	ra,520(sp)
    80005150:	20013403          	ld	s0,512(sp)
    80005154:	74fe                	ld	s1,504(sp)
    80005156:	795e                	ld	s2,496(sp)
    80005158:	79be                	ld	s3,488(sp)
    8000515a:	7a1e                	ld	s4,480(sp)
    8000515c:	6afe                	ld	s5,472(sp)
    8000515e:	6b5e                	ld	s6,464(sp)
    80005160:	6bbe                	ld	s7,456(sp)
    80005162:	6c1e                	ld	s8,448(sp)
    80005164:	7cfa                	ld	s9,440(sp)
    80005166:	7d5a                	ld	s10,432(sp)
    80005168:	7dba                	ld	s11,424(sp)
    8000516a:	21010113          	addi	sp,sp,528
    8000516e:	8082                	ret
    end_op();
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	484080e7          	jalr	1156(ra) # 800045f4 <end_op>
    return -1;
    80005178:	557d                	li	a0,-1
    8000517a:	bfc9                	j	8000514c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000517c:	8526                	mv	a0,s1
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	bc2080e7          	jalr	-1086(ra) # 80001d40 <proc_pagetable>
    80005186:	8b2a                	mv	s6,a0
    80005188:	d945                	beqz	a0,80005138 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000518a:	e7042d03          	lw	s10,-400(s0)
    8000518e:	e8845783          	lhu	a5,-376(s0)
    80005192:	10078463          	beqz	a5,8000529a <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005196:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005198:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000519a:	6c85                	lui	s9,0x1
    8000519c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051a0:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800051a4:	6a85                	lui	s5,0x1
    800051a6:	a0b5                	j	80005212 <exec+0x15e>
      panic("loadseg: address should exist");
    800051a8:	00003517          	auipc	a0,0x3
    800051ac:	61050513          	addi	a0,a0,1552 # 800087b8 <syscalls+0x298>
    800051b0:	ffffb097          	auipc	ra,0xffffb
    800051b4:	38c080e7          	jalr	908(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800051b8:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051ba:	8726                	mv	a4,s1
    800051bc:	012c06bb          	addw	a3,s8,s2
    800051c0:	4581                	li	a1,0
    800051c2:	8552                	mv	a0,s4
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	cc4080e7          	jalr	-828(ra) # 80003e88 <readi>
    800051cc:	2501                	sext.w	a0,a0
    800051ce:	24a49863          	bne	s1,a0,8000541e <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051d2:	012a893b          	addw	s2,s5,s2
    800051d6:	03397563          	bgeu	s2,s3,80005200 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800051da:	02091593          	slli	a1,s2,0x20
    800051de:	9181                	srli	a1,a1,0x20
    800051e0:	95de                	add	a1,a1,s7
    800051e2:	855a                	mv	a0,s6
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	e72080e7          	jalr	-398(ra) # 80001056 <walkaddr>
    800051ec:	862a                	mv	a2,a0
    if(pa == 0)
    800051ee:	dd4d                	beqz	a0,800051a8 <exec+0xf4>
    if(sz - i < PGSIZE)
    800051f0:	412984bb          	subw	s1,s3,s2
    800051f4:	0004879b          	sext.w	a5,s1
    800051f8:	fcfcf0e3          	bgeu	s9,a5,800051b8 <exec+0x104>
    800051fc:	84d6                	mv	s1,s5
    800051fe:	bf6d                	j	800051b8 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005200:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005204:	2d85                	addiw	s11,s11,1
    80005206:	038d0d1b          	addiw	s10,s10,56
    8000520a:	e8845783          	lhu	a5,-376(s0)
    8000520e:	08fdd763          	bge	s11,a5,8000529c <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005212:	2d01                	sext.w	s10,s10
    80005214:	03800713          	li	a4,56
    80005218:	86ea                	mv	a3,s10
    8000521a:	e1840613          	addi	a2,s0,-488
    8000521e:	4581                	li	a1,0
    80005220:	8552                	mv	a0,s4
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	c66080e7          	jalr	-922(ra) # 80003e88 <readi>
    8000522a:	03800793          	li	a5,56
    8000522e:	1ef51663          	bne	a0,a5,8000541a <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005232:	e1842783          	lw	a5,-488(s0)
    80005236:	4705                	li	a4,1
    80005238:	fce796e3          	bne	a5,a4,80005204 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000523c:	e4043483          	ld	s1,-448(s0)
    80005240:	e3843783          	ld	a5,-456(s0)
    80005244:	1ef4e863          	bltu	s1,a5,80005434 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005248:	e2843783          	ld	a5,-472(s0)
    8000524c:	94be                	add	s1,s1,a5
    8000524e:	1ef4e663          	bltu	s1,a5,8000543a <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005252:	df043703          	ld	a4,-528(s0)
    80005256:	8ff9                	and	a5,a5,a4
    80005258:	1e079463          	bnez	a5,80005440 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000525c:	e1c42503          	lw	a0,-484(s0)
    80005260:	00000097          	auipc	ra,0x0
    80005264:	e3a080e7          	jalr	-454(ra) # 8000509a <flags2perm>
    80005268:	86aa                	mv	a3,a0
    8000526a:	8626                	mv	a2,s1
    8000526c:	85ca                	mv	a1,s2
    8000526e:	855a                	mv	a0,s6
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	19a080e7          	jalr	410(ra) # 8000140a <uvmalloc>
    80005278:	e0a43423          	sd	a0,-504(s0)
    8000527c:	1c050563          	beqz	a0,80005446 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005280:	e2843b83          	ld	s7,-472(s0)
    80005284:	e2042c03          	lw	s8,-480(s0)
    80005288:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000528c:	00098463          	beqz	s3,80005294 <exec+0x1e0>
    80005290:	4901                	li	s2,0
    80005292:	b7a1                	j	800051da <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005294:	e0843903          	ld	s2,-504(s0)
    80005298:	b7b5                	j	80005204 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000529a:	4901                	li	s2,0
  iunlockput(ip);
    8000529c:	8552                	mv	a0,s4
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	b98080e7          	jalr	-1128(ra) # 80003e36 <iunlockput>
  end_op();
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	34e080e7          	jalr	846(ra) # 800045f4 <end_op>
  p = myproc();
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	9ce080e7          	jalr	-1586(ra) # 80001c7c <myproc>
    800052b6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052b8:	05053c83          	ld	s9,80(a0)
  sz = PGROUNDUP(sz);
    800052bc:	6985                	lui	s3,0x1
    800052be:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800052c0:	99ca                	add	s3,s3,s2
    800052c2:	77fd                	lui	a5,0xfffff
    800052c4:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052c8:	4691                	li	a3,4
    800052ca:	6609                	lui	a2,0x2
    800052cc:	964e                	add	a2,a2,s3
    800052ce:	85ce                	mv	a1,s3
    800052d0:	855a                	mv	a0,s6
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	138080e7          	jalr	312(ra) # 8000140a <uvmalloc>
    800052da:	892a                	mv	s2,a0
    800052dc:	e0a43423          	sd	a0,-504(s0)
    800052e0:	e509                	bnez	a0,800052ea <exec+0x236>
  if(pagetable)
    800052e2:	e1343423          	sd	s3,-504(s0)
    800052e6:	4a01                	li	s4,0
    800052e8:	aa1d                	j	8000541e <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052ea:	75f9                	lui	a1,0xffffe
    800052ec:	95aa                	add	a1,a1,a0
    800052ee:	855a                	mv	a0,s6
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	344080e7          	jalr	836(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800052f8:	7bfd                	lui	s7,0xfffff
    800052fa:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800052fc:	e0043783          	ld	a5,-512(s0)
    80005300:	6388                	ld	a0,0(a5)
    80005302:	c52d                	beqz	a0,8000536c <exec+0x2b8>
    80005304:	e9040993          	addi	s3,s0,-368
    80005308:	f9040c13          	addi	s8,s0,-112
    8000530c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	b3a080e7          	jalr	-1222(ra) # 80000e48 <strlen>
    80005316:	0015079b          	addiw	a5,a0,1
    8000531a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000531e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005322:	13796563          	bltu	s2,s7,8000544c <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005326:	e0043d03          	ld	s10,-512(s0)
    8000532a:	000d3a03          	ld	s4,0(s10)
    8000532e:	8552                	mv	a0,s4
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	b18080e7          	jalr	-1256(ra) # 80000e48 <strlen>
    80005338:	0015069b          	addiw	a3,a0,1
    8000533c:	8652                	mv	a2,s4
    8000533e:	85ca                	mv	a1,s2
    80005340:	855a                	mv	a0,s6
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	324080e7          	jalr	804(ra) # 80001666 <copyout>
    8000534a:	10054363          	bltz	a0,80005450 <exec+0x39c>
    ustack[argc] = sp;
    8000534e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005352:	0485                	addi	s1,s1,1
    80005354:	008d0793          	addi	a5,s10,8
    80005358:	e0f43023          	sd	a5,-512(s0)
    8000535c:	008d3503          	ld	a0,8(s10)
    80005360:	c909                	beqz	a0,80005372 <exec+0x2be>
    if(argc >= MAXARG)
    80005362:	09a1                	addi	s3,s3,8
    80005364:	fb8995e3          	bne	s3,s8,8000530e <exec+0x25a>
  ip = 0;
    80005368:	4a01                	li	s4,0
    8000536a:	a855                	j	8000541e <exec+0x36a>
  sp = sz;
    8000536c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005370:	4481                	li	s1,0
  ustack[argc] = 0;
    80005372:	00349793          	slli	a5,s1,0x3
    80005376:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcf10>
    8000537a:	97a2                	add	a5,a5,s0
    8000537c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005380:	00148693          	addi	a3,s1,1
    80005384:	068e                	slli	a3,a3,0x3
    80005386:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000538a:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000538e:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005392:	f57968e3          	bltu	s2,s7,800052e2 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005396:	e9040613          	addi	a2,s0,-368
    8000539a:	85ca                	mv	a1,s2
    8000539c:	855a                	mv	a0,s6
    8000539e:	ffffc097          	auipc	ra,0xffffc
    800053a2:	2c8080e7          	jalr	712(ra) # 80001666 <copyout>
    800053a6:	0a054763          	bltz	a0,80005454 <exec+0x3a0>
  p->trapframe->a1 = sp;
    800053aa:	060ab783          	ld	a5,96(s5) # 1060 <_entry-0x7fffefa0>
    800053ae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053b2:	df843783          	ld	a5,-520(s0)
    800053b6:	0007c703          	lbu	a4,0(a5)
    800053ba:	cf11                	beqz	a4,800053d6 <exec+0x322>
    800053bc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053be:	02f00693          	li	a3,47
    800053c2:	a039                	j	800053d0 <exec+0x31c>
      last = s+1;
    800053c4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053c8:	0785                	addi	a5,a5,1
    800053ca:	fff7c703          	lbu	a4,-1(a5)
    800053ce:	c701                	beqz	a4,800053d6 <exec+0x322>
    if(*s == '/')
    800053d0:	fed71ce3          	bne	a4,a3,800053c8 <exec+0x314>
    800053d4:	bfc5                	j	800053c4 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053d6:	4641                	li	a2,16
    800053d8:	df843583          	ld	a1,-520(s0)
    800053dc:	160a8513          	addi	a0,s5,352
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	a36080e7          	jalr	-1482(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053e8:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800053ec:	056abc23          	sd	s6,88(s5)
  p->sz = sz;
    800053f0:	e0843783          	ld	a5,-504(s0)
    800053f4:	04fab823          	sd	a5,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053f8:	060ab783          	ld	a5,96(s5)
    800053fc:	e6843703          	ld	a4,-408(s0)
    80005400:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005402:	060ab783          	ld	a5,96(s5)
    80005406:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000540a:	85e6                	mv	a1,s9
    8000540c:	ffffd097          	auipc	ra,0xffffd
    80005410:	9d0080e7          	jalr	-1584(ra) # 80001ddc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005414:	0004851b          	sext.w	a0,s1
    80005418:	bb15                	j	8000514c <exec+0x98>
    8000541a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000541e:	e0843583          	ld	a1,-504(s0)
    80005422:	855a                	mv	a0,s6
    80005424:	ffffd097          	auipc	ra,0xffffd
    80005428:	9b8080e7          	jalr	-1608(ra) # 80001ddc <proc_freepagetable>
  return -1;
    8000542c:	557d                	li	a0,-1
  if(ip){
    8000542e:	d00a0fe3          	beqz	s4,8000514c <exec+0x98>
    80005432:	b319                	j	80005138 <exec+0x84>
    80005434:	e1243423          	sd	s2,-504(s0)
    80005438:	b7dd                	j	8000541e <exec+0x36a>
    8000543a:	e1243423          	sd	s2,-504(s0)
    8000543e:	b7c5                	j	8000541e <exec+0x36a>
    80005440:	e1243423          	sd	s2,-504(s0)
    80005444:	bfe9                	j	8000541e <exec+0x36a>
    80005446:	e1243423          	sd	s2,-504(s0)
    8000544a:	bfd1                	j	8000541e <exec+0x36a>
  ip = 0;
    8000544c:	4a01                	li	s4,0
    8000544e:	bfc1                	j	8000541e <exec+0x36a>
    80005450:	4a01                	li	s4,0
  if(pagetable)
    80005452:	b7f1                	j	8000541e <exec+0x36a>
  sz = sz1;
    80005454:	e0843983          	ld	s3,-504(s0)
    80005458:	b569                	j	800052e2 <exec+0x22e>

000000008000545a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000545a:	7179                	addi	sp,sp,-48
    8000545c:	f406                	sd	ra,40(sp)
    8000545e:	f022                	sd	s0,32(sp)
    80005460:	ec26                	sd	s1,24(sp)
    80005462:	e84a                	sd	s2,16(sp)
    80005464:	1800                	addi	s0,sp,48
    80005466:	892e                	mv	s2,a1
    80005468:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000546a:	fdc40593          	addi	a1,s0,-36
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	b74080e7          	jalr	-1164(ra) # 80002fe2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005476:	fdc42703          	lw	a4,-36(s0)
    8000547a:	47bd                	li	a5,15
    8000547c:	02e7eb63          	bltu	a5,a4,800054b2 <argfd+0x58>
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	7fc080e7          	jalr	2044(ra) # 80001c7c <myproc>
    80005488:	fdc42703          	lw	a4,-36(s0)
    8000548c:	01a70793          	addi	a5,a4,26
    80005490:	078e                	slli	a5,a5,0x3
    80005492:	953e                	add	a0,a0,a5
    80005494:	651c                	ld	a5,8(a0)
    80005496:	c385                	beqz	a5,800054b6 <argfd+0x5c>
    return -1;
  if(pfd)
    80005498:	00090463          	beqz	s2,800054a0 <argfd+0x46>
    *pfd = fd;
    8000549c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054a0:	4501                	li	a0,0
  if(pf)
    800054a2:	c091                	beqz	s1,800054a6 <argfd+0x4c>
    *pf = f;
    800054a4:	e09c                	sd	a5,0(s1)
}
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	64e2                	ld	s1,24(sp)
    800054ac:	6942                	ld	s2,16(sp)
    800054ae:	6145                	addi	sp,sp,48
    800054b0:	8082                	ret
    return -1;
    800054b2:	557d                	li	a0,-1
    800054b4:	bfcd                	j	800054a6 <argfd+0x4c>
    800054b6:	557d                	li	a0,-1
    800054b8:	b7fd                	j	800054a6 <argfd+0x4c>

00000000800054ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054ba:	1101                	addi	sp,sp,-32
    800054bc:	ec06                	sd	ra,24(sp)
    800054be:	e822                	sd	s0,16(sp)
    800054c0:	e426                	sd	s1,8(sp)
    800054c2:	1000                	addi	s0,sp,32
    800054c4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	7b6080e7          	jalr	1974(ra) # 80001c7c <myproc>
    800054ce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054d0:	0d850793          	addi	a5,a0,216
    800054d4:	4501                	li	a0,0
    800054d6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054d8:	6398                	ld	a4,0(a5)
    800054da:	cb19                	beqz	a4,800054f0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054dc:	2505                	addiw	a0,a0,1
    800054de:	07a1                	addi	a5,a5,8
    800054e0:	fed51ce3          	bne	a0,a3,800054d8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054e4:	557d                	li	a0,-1
}
    800054e6:	60e2                	ld	ra,24(sp)
    800054e8:	6442                	ld	s0,16(sp)
    800054ea:	64a2                	ld	s1,8(sp)
    800054ec:	6105                	addi	sp,sp,32
    800054ee:	8082                	ret
      p->ofile[fd] = f;
    800054f0:	01a50793          	addi	a5,a0,26
    800054f4:	078e                	slli	a5,a5,0x3
    800054f6:	963e                	add	a2,a2,a5
    800054f8:	e604                	sd	s1,8(a2)
      return fd;
    800054fa:	b7f5                	j	800054e6 <fdalloc+0x2c>

00000000800054fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054fc:	715d                	addi	sp,sp,-80
    800054fe:	e486                	sd	ra,72(sp)
    80005500:	e0a2                	sd	s0,64(sp)
    80005502:	fc26                	sd	s1,56(sp)
    80005504:	f84a                	sd	s2,48(sp)
    80005506:	f44e                	sd	s3,40(sp)
    80005508:	f052                	sd	s4,32(sp)
    8000550a:	ec56                	sd	s5,24(sp)
    8000550c:	e85a                	sd	s6,16(sp)
    8000550e:	0880                	addi	s0,sp,80
    80005510:	8b2e                	mv	s6,a1
    80005512:	89b2                	mv	s3,a2
    80005514:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005516:	fb040593          	addi	a1,s0,-80
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	e7e080e7          	jalr	-386(ra) # 80004398 <nameiparent>
    80005522:	84aa                	mv	s1,a0
    80005524:	14050b63          	beqz	a0,8000567a <create+0x17e>
    return 0;

  ilock(dp);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	6ac080e7          	jalr	1708(ra) # 80003bd4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005530:	4601                	li	a2,0
    80005532:	fb040593          	addi	a1,s0,-80
    80005536:	8526                	mv	a0,s1
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	b80080e7          	jalr	-1152(ra) # 800040b8 <dirlookup>
    80005540:	8aaa                	mv	s5,a0
    80005542:	c921                	beqz	a0,80005592 <create+0x96>
    iunlockput(dp);
    80005544:	8526                	mv	a0,s1
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	8f0080e7          	jalr	-1808(ra) # 80003e36 <iunlockput>
    ilock(ip);
    8000554e:	8556                	mv	a0,s5
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	684080e7          	jalr	1668(ra) # 80003bd4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005558:	4789                	li	a5,2
    8000555a:	02fb1563          	bne	s6,a5,80005584 <create+0x88>
    8000555e:	044ad783          	lhu	a5,68(s5)
    80005562:	37f9                	addiw	a5,a5,-2
    80005564:	17c2                	slli	a5,a5,0x30
    80005566:	93c1                	srli	a5,a5,0x30
    80005568:	4705                	li	a4,1
    8000556a:	00f76d63          	bltu	a4,a5,80005584 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000556e:	8556                	mv	a0,s5
    80005570:	60a6                	ld	ra,72(sp)
    80005572:	6406                	ld	s0,64(sp)
    80005574:	74e2                	ld	s1,56(sp)
    80005576:	7942                	ld	s2,48(sp)
    80005578:	79a2                	ld	s3,40(sp)
    8000557a:	7a02                	ld	s4,32(sp)
    8000557c:	6ae2                	ld	s5,24(sp)
    8000557e:	6b42                	ld	s6,16(sp)
    80005580:	6161                	addi	sp,sp,80
    80005582:	8082                	ret
    iunlockput(ip);
    80005584:	8556                	mv	a0,s5
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	8b0080e7          	jalr	-1872(ra) # 80003e36 <iunlockput>
    return 0;
    8000558e:	4a81                	li	s5,0
    80005590:	bff9                	j	8000556e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005592:	85da                	mv	a1,s6
    80005594:	4088                	lw	a0,0(s1)
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	4a6080e7          	jalr	1190(ra) # 80003a3c <ialloc>
    8000559e:	8a2a                	mv	s4,a0
    800055a0:	c529                	beqz	a0,800055ea <create+0xee>
  ilock(ip);
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	632080e7          	jalr	1586(ra) # 80003bd4 <ilock>
  ip->major = major;
    800055aa:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055ae:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055b2:	4905                	li	s2,1
    800055b4:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055b8:	8552                	mv	a0,s4
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	54e080e7          	jalr	1358(ra) # 80003b08 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055c2:	032b0b63          	beq	s6,s2,800055f8 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055c6:	004a2603          	lw	a2,4(s4)
    800055ca:	fb040593          	addi	a1,s0,-80
    800055ce:	8526                	mv	a0,s1
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	cf8080e7          	jalr	-776(ra) # 800042c8 <dirlink>
    800055d8:	06054f63          	bltz	a0,80005656 <create+0x15a>
  iunlockput(dp);
    800055dc:	8526                	mv	a0,s1
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	858080e7          	jalr	-1960(ra) # 80003e36 <iunlockput>
  return ip;
    800055e6:	8ad2                	mv	s5,s4
    800055e8:	b759                	j	8000556e <create+0x72>
    iunlockput(dp);
    800055ea:	8526                	mv	a0,s1
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	84a080e7          	jalr	-1974(ra) # 80003e36 <iunlockput>
    return 0;
    800055f4:	8ad2                	mv	s5,s4
    800055f6:	bfa5                	j	8000556e <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055f8:	004a2603          	lw	a2,4(s4)
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	1dc58593          	addi	a1,a1,476 # 800087d8 <syscalls+0x2b8>
    80005604:	8552                	mv	a0,s4
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	cc2080e7          	jalr	-830(ra) # 800042c8 <dirlink>
    8000560e:	04054463          	bltz	a0,80005656 <create+0x15a>
    80005612:	40d0                	lw	a2,4(s1)
    80005614:	00003597          	auipc	a1,0x3
    80005618:	1cc58593          	addi	a1,a1,460 # 800087e0 <syscalls+0x2c0>
    8000561c:	8552                	mv	a0,s4
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	caa080e7          	jalr	-854(ra) # 800042c8 <dirlink>
    80005626:	02054863          	bltz	a0,80005656 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000562a:	004a2603          	lw	a2,4(s4)
    8000562e:	fb040593          	addi	a1,s0,-80
    80005632:	8526                	mv	a0,s1
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	c94080e7          	jalr	-876(ra) # 800042c8 <dirlink>
    8000563c:	00054d63          	bltz	a0,80005656 <create+0x15a>
    dp->nlink++;  // for ".."
    80005640:	04a4d783          	lhu	a5,74(s1)
    80005644:	2785                	addiw	a5,a5,1
    80005646:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	4bc080e7          	jalr	1212(ra) # 80003b08 <iupdate>
    80005654:	b761                	j	800055dc <create+0xe0>
  ip->nlink = 0;
    80005656:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000565a:	8552                	mv	a0,s4
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	4ac080e7          	jalr	1196(ra) # 80003b08 <iupdate>
  iunlockput(ip);
    80005664:	8552                	mv	a0,s4
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	7d0080e7          	jalr	2000(ra) # 80003e36 <iunlockput>
  iunlockput(dp);
    8000566e:	8526                	mv	a0,s1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	7c6080e7          	jalr	1990(ra) # 80003e36 <iunlockput>
  return 0;
    80005678:	bddd                	j	8000556e <create+0x72>
    return 0;
    8000567a:	8aaa                	mv	s5,a0
    8000567c:	bdcd                	j	8000556e <create+0x72>

000000008000567e <sys_dup>:
{
    8000567e:	7179                	addi	sp,sp,-48
    80005680:	f406                	sd	ra,40(sp)
    80005682:	f022                	sd	s0,32(sp)
    80005684:	ec26                	sd	s1,24(sp)
    80005686:	e84a                	sd	s2,16(sp)
    80005688:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000568a:	fd840613          	addi	a2,s0,-40
    8000568e:	4581                	li	a1,0
    80005690:	4501                	li	a0,0
    80005692:	00000097          	auipc	ra,0x0
    80005696:	dc8080e7          	jalr	-568(ra) # 8000545a <argfd>
    return -1;
    8000569a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000569c:	02054363          	bltz	a0,800056c2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800056a0:	fd843903          	ld	s2,-40(s0)
    800056a4:	854a                	mv	a0,s2
    800056a6:	00000097          	auipc	ra,0x0
    800056aa:	e14080e7          	jalr	-492(ra) # 800054ba <fdalloc>
    800056ae:	84aa                	mv	s1,a0
    return -1;
    800056b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056b2:	00054863          	bltz	a0,800056c2 <sys_dup+0x44>
  filedup(f);
    800056b6:	854a                	mv	a0,s2
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	334080e7          	jalr	820(ra) # 800049ec <filedup>
  return fd;
    800056c0:	87a6                	mv	a5,s1
}
    800056c2:	853e                	mv	a0,a5
    800056c4:	70a2                	ld	ra,40(sp)
    800056c6:	7402                	ld	s0,32(sp)
    800056c8:	64e2                	ld	s1,24(sp)
    800056ca:	6942                	ld	s2,16(sp)
    800056cc:	6145                	addi	sp,sp,48
    800056ce:	8082                	ret

00000000800056d0 <sys_read>:
{
    800056d0:	7179                	addi	sp,sp,-48
    800056d2:	f406                	sd	ra,40(sp)
    800056d4:	f022                	sd	s0,32(sp)
    800056d6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056d8:	fd840593          	addi	a1,s0,-40
    800056dc:	4505                	li	a0,1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	924080e7          	jalr	-1756(ra) # 80003002 <argaddr>
  argint(2, &n);
    800056e6:	fe440593          	addi	a1,s0,-28
    800056ea:	4509                	li	a0,2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	8f6080e7          	jalr	-1802(ra) # 80002fe2 <argint>
  if(argfd(0, 0, &f) < 0)
    800056f4:	fe840613          	addi	a2,s0,-24
    800056f8:	4581                	li	a1,0
    800056fa:	4501                	li	a0,0
    800056fc:	00000097          	auipc	ra,0x0
    80005700:	d5e080e7          	jalr	-674(ra) # 8000545a <argfd>
    80005704:	87aa                	mv	a5,a0
    return -1;
    80005706:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005708:	0007cc63          	bltz	a5,80005720 <sys_read+0x50>
  return fileread(f, p, n);
    8000570c:	fe442603          	lw	a2,-28(s0)
    80005710:	fd843583          	ld	a1,-40(s0)
    80005714:	fe843503          	ld	a0,-24(s0)
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	460080e7          	jalr	1120(ra) # 80004b78 <fileread>
}
    80005720:	70a2                	ld	ra,40(sp)
    80005722:	7402                	ld	s0,32(sp)
    80005724:	6145                	addi	sp,sp,48
    80005726:	8082                	ret

0000000080005728 <sys_write>:
{
    80005728:	7179                	addi	sp,sp,-48
    8000572a:	f406                	sd	ra,40(sp)
    8000572c:	f022                	sd	s0,32(sp)
    8000572e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005730:	fd840593          	addi	a1,s0,-40
    80005734:	4505                	li	a0,1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	8cc080e7          	jalr	-1844(ra) # 80003002 <argaddr>
  argint(2, &n);
    8000573e:	fe440593          	addi	a1,s0,-28
    80005742:	4509                	li	a0,2
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	89e080e7          	jalr	-1890(ra) # 80002fe2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000574c:	fe840613          	addi	a2,s0,-24
    80005750:	4581                	li	a1,0
    80005752:	4501                	li	a0,0
    80005754:	00000097          	auipc	ra,0x0
    80005758:	d06080e7          	jalr	-762(ra) # 8000545a <argfd>
    8000575c:	87aa                	mv	a5,a0
    return -1;
    8000575e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005760:	0007cc63          	bltz	a5,80005778 <sys_write+0x50>
  return filewrite(f, p, n);
    80005764:	fe442603          	lw	a2,-28(s0)
    80005768:	fd843583          	ld	a1,-40(s0)
    8000576c:	fe843503          	ld	a0,-24(s0)
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	4ca080e7          	jalr	1226(ra) # 80004c3a <filewrite>
}
    80005778:	70a2                	ld	ra,40(sp)
    8000577a:	7402                	ld	s0,32(sp)
    8000577c:	6145                	addi	sp,sp,48
    8000577e:	8082                	ret

0000000080005780 <sys_close>:
{
    80005780:	1101                	addi	sp,sp,-32
    80005782:	ec06                	sd	ra,24(sp)
    80005784:	e822                	sd	s0,16(sp)
    80005786:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005788:	fe040613          	addi	a2,s0,-32
    8000578c:	fec40593          	addi	a1,s0,-20
    80005790:	4501                	li	a0,0
    80005792:	00000097          	auipc	ra,0x0
    80005796:	cc8080e7          	jalr	-824(ra) # 8000545a <argfd>
    return -1;
    8000579a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000579c:	02054463          	bltz	a0,800057c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057a0:	ffffc097          	auipc	ra,0xffffc
    800057a4:	4dc080e7          	jalr	1244(ra) # 80001c7c <myproc>
    800057a8:	fec42783          	lw	a5,-20(s0)
    800057ac:	07e9                	addi	a5,a5,26
    800057ae:	078e                	slli	a5,a5,0x3
    800057b0:	953e                	add	a0,a0,a5
    800057b2:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800057b6:	fe043503          	ld	a0,-32(s0)
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	284080e7          	jalr	644(ra) # 80004a3e <fileclose>
  return 0;
    800057c2:	4781                	li	a5,0
}
    800057c4:	853e                	mv	a0,a5
    800057c6:	60e2                	ld	ra,24(sp)
    800057c8:	6442                	ld	s0,16(sp)
    800057ca:	6105                	addi	sp,sp,32
    800057cc:	8082                	ret

00000000800057ce <sys_fstat>:
{
    800057ce:	1101                	addi	sp,sp,-32
    800057d0:	ec06                	sd	ra,24(sp)
    800057d2:	e822                	sd	s0,16(sp)
    800057d4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057d6:	fe040593          	addi	a1,s0,-32
    800057da:	4505                	li	a0,1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	826080e7          	jalr	-2010(ra) # 80003002 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057e4:	fe840613          	addi	a2,s0,-24
    800057e8:	4581                	li	a1,0
    800057ea:	4501                	li	a0,0
    800057ec:	00000097          	auipc	ra,0x0
    800057f0:	c6e080e7          	jalr	-914(ra) # 8000545a <argfd>
    800057f4:	87aa                	mv	a5,a0
    return -1;
    800057f6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057f8:	0007ca63          	bltz	a5,8000580c <sys_fstat+0x3e>
  return filestat(f, st);
    800057fc:	fe043583          	ld	a1,-32(s0)
    80005800:	fe843503          	ld	a0,-24(s0)
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	302080e7          	jalr	770(ra) # 80004b06 <filestat>
}
    8000580c:	60e2                	ld	ra,24(sp)
    8000580e:	6442                	ld	s0,16(sp)
    80005810:	6105                	addi	sp,sp,32
    80005812:	8082                	ret

0000000080005814 <sys_link>:
{
    80005814:	7169                	addi	sp,sp,-304
    80005816:	f606                	sd	ra,296(sp)
    80005818:	f222                	sd	s0,288(sp)
    8000581a:	ee26                	sd	s1,280(sp)
    8000581c:	ea4a                	sd	s2,272(sp)
    8000581e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005820:	08000613          	li	a2,128
    80005824:	ed040593          	addi	a1,s0,-304
    80005828:	4501                	li	a0,0
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	7f8080e7          	jalr	2040(ra) # 80003022 <argstr>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005834:	10054e63          	bltz	a0,80005950 <sys_link+0x13c>
    80005838:	08000613          	li	a2,128
    8000583c:	f5040593          	addi	a1,s0,-176
    80005840:	4505                	li	a0,1
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	7e0080e7          	jalr	2016(ra) # 80003022 <argstr>
    return -1;
    8000584a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584c:	10054263          	bltz	a0,80005950 <sys_link+0x13c>
  begin_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	d2a080e7          	jalr	-726(ra) # 8000457a <begin_op>
  if((ip = namei(old)) == 0){
    80005858:	ed040513          	addi	a0,s0,-304
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	b1e080e7          	jalr	-1250(ra) # 8000437a <namei>
    80005864:	84aa                	mv	s1,a0
    80005866:	c551                	beqz	a0,800058f2 <sys_link+0xde>
  ilock(ip);
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	36c080e7          	jalr	876(ra) # 80003bd4 <ilock>
  if(ip->type == T_DIR){
    80005870:	04449703          	lh	a4,68(s1)
    80005874:	4785                	li	a5,1
    80005876:	08f70463          	beq	a4,a5,800058fe <sys_link+0xea>
  ip->nlink++;
    8000587a:	04a4d783          	lhu	a5,74(s1)
    8000587e:	2785                	addiw	a5,a5,1
    80005880:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	282080e7          	jalr	642(ra) # 80003b08 <iupdate>
  iunlock(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	406080e7          	jalr	1030(ra) # 80003c96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005898:	fd040593          	addi	a1,s0,-48
    8000589c:	f5040513          	addi	a0,s0,-176
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	af8080e7          	jalr	-1288(ra) # 80004398 <nameiparent>
    800058a8:	892a                	mv	s2,a0
    800058aa:	c935                	beqz	a0,8000591e <sys_link+0x10a>
  ilock(dp);
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	328080e7          	jalr	808(ra) # 80003bd4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058b4:	00092703          	lw	a4,0(s2)
    800058b8:	409c                	lw	a5,0(s1)
    800058ba:	04f71d63          	bne	a4,a5,80005914 <sys_link+0x100>
    800058be:	40d0                	lw	a2,4(s1)
    800058c0:	fd040593          	addi	a1,s0,-48
    800058c4:	854a                	mv	a0,s2
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	a02080e7          	jalr	-1534(ra) # 800042c8 <dirlink>
    800058ce:	04054363          	bltz	a0,80005914 <sys_link+0x100>
  iunlockput(dp);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	562080e7          	jalr	1378(ra) # 80003e36 <iunlockput>
  iput(ip);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	4b0080e7          	jalr	1200(ra) # 80003d8e <iput>
  end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	d0e080e7          	jalr	-754(ra) # 800045f4 <end_op>
  return 0;
    800058ee:	4781                	li	a5,0
    800058f0:	a085                	j	80005950 <sys_link+0x13c>
    end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	d02080e7          	jalr	-766(ra) # 800045f4 <end_op>
    return -1;
    800058fa:	57fd                	li	a5,-1
    800058fc:	a891                	j	80005950 <sys_link+0x13c>
    iunlockput(ip);
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	536080e7          	jalr	1334(ra) # 80003e36 <iunlockput>
    end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	cec080e7          	jalr	-788(ra) # 800045f4 <end_op>
    return -1;
    80005910:	57fd                	li	a5,-1
    80005912:	a83d                	j	80005950 <sys_link+0x13c>
    iunlockput(dp);
    80005914:	854a                	mv	a0,s2
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	520080e7          	jalr	1312(ra) # 80003e36 <iunlockput>
  ilock(ip);
    8000591e:	8526                	mv	a0,s1
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	2b4080e7          	jalr	692(ra) # 80003bd4 <ilock>
  ip->nlink--;
    80005928:	04a4d783          	lhu	a5,74(s1)
    8000592c:	37fd                	addiw	a5,a5,-1
    8000592e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	1d4080e7          	jalr	468(ra) # 80003b08 <iupdate>
  iunlockput(ip);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	4f8080e7          	jalr	1272(ra) # 80003e36 <iunlockput>
  end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	cae080e7          	jalr	-850(ra) # 800045f4 <end_op>
  return -1;
    8000594e:	57fd                	li	a5,-1
}
    80005950:	853e                	mv	a0,a5
    80005952:	70b2                	ld	ra,296(sp)
    80005954:	7412                	ld	s0,288(sp)
    80005956:	64f2                	ld	s1,280(sp)
    80005958:	6952                	ld	s2,272(sp)
    8000595a:	6155                	addi	sp,sp,304
    8000595c:	8082                	ret

000000008000595e <sys_unlink>:
{
    8000595e:	7151                	addi	sp,sp,-240
    80005960:	f586                	sd	ra,232(sp)
    80005962:	f1a2                	sd	s0,224(sp)
    80005964:	eda6                	sd	s1,216(sp)
    80005966:	e9ca                	sd	s2,208(sp)
    80005968:	e5ce                	sd	s3,200(sp)
    8000596a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000596c:	08000613          	li	a2,128
    80005970:	f3040593          	addi	a1,s0,-208
    80005974:	4501                	li	a0,0
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	6ac080e7          	jalr	1708(ra) # 80003022 <argstr>
    8000597e:	18054163          	bltz	a0,80005b00 <sys_unlink+0x1a2>
  begin_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	bf8080e7          	jalr	-1032(ra) # 8000457a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000598a:	fb040593          	addi	a1,s0,-80
    8000598e:	f3040513          	addi	a0,s0,-208
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	a06080e7          	jalr	-1530(ra) # 80004398 <nameiparent>
    8000599a:	84aa                	mv	s1,a0
    8000599c:	c979                	beqz	a0,80005a72 <sys_unlink+0x114>
  ilock(dp);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	236080e7          	jalr	566(ra) # 80003bd4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059a6:	00003597          	auipc	a1,0x3
    800059aa:	e3258593          	addi	a1,a1,-462 # 800087d8 <syscalls+0x2b8>
    800059ae:	fb040513          	addi	a0,s0,-80
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	6ec080e7          	jalr	1772(ra) # 8000409e <namecmp>
    800059ba:	14050a63          	beqz	a0,80005b0e <sys_unlink+0x1b0>
    800059be:	00003597          	auipc	a1,0x3
    800059c2:	e2258593          	addi	a1,a1,-478 # 800087e0 <syscalls+0x2c0>
    800059c6:	fb040513          	addi	a0,s0,-80
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	6d4080e7          	jalr	1748(ra) # 8000409e <namecmp>
    800059d2:	12050e63          	beqz	a0,80005b0e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059d6:	f2c40613          	addi	a2,s0,-212
    800059da:	fb040593          	addi	a1,s0,-80
    800059de:	8526                	mv	a0,s1
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	6d8080e7          	jalr	1752(ra) # 800040b8 <dirlookup>
    800059e8:	892a                	mv	s2,a0
    800059ea:	12050263          	beqz	a0,80005b0e <sys_unlink+0x1b0>
  ilock(ip);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	1e6080e7          	jalr	486(ra) # 80003bd4 <ilock>
  if(ip->nlink < 1)
    800059f6:	04a91783          	lh	a5,74(s2)
    800059fa:	08f05263          	blez	a5,80005a7e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059fe:	04491703          	lh	a4,68(s2)
    80005a02:	4785                	li	a5,1
    80005a04:	08f70563          	beq	a4,a5,80005a8e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a08:	4641                	li	a2,16
    80005a0a:	4581                	li	a1,0
    80005a0c:	fc040513          	addi	a0,s0,-64
    80005a10:	ffffb097          	auipc	ra,0xffffb
    80005a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a18:	4741                	li	a4,16
    80005a1a:	f2c42683          	lw	a3,-212(s0)
    80005a1e:	fc040613          	addi	a2,s0,-64
    80005a22:	4581                	li	a1,0
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	55a080e7          	jalr	1370(ra) # 80003f80 <writei>
    80005a2e:	47c1                	li	a5,16
    80005a30:	0af51563          	bne	a0,a5,80005ada <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a34:	04491703          	lh	a4,68(s2)
    80005a38:	4785                	li	a5,1
    80005a3a:	0af70863          	beq	a4,a5,80005aea <sys_unlink+0x18c>
  iunlockput(dp);
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	3f6080e7          	jalr	1014(ra) # 80003e36 <iunlockput>
  ip->nlink--;
    80005a48:	04a95783          	lhu	a5,74(s2)
    80005a4c:	37fd                	addiw	a5,a5,-1
    80005a4e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a52:	854a                	mv	a0,s2
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	0b4080e7          	jalr	180(ra) # 80003b08 <iupdate>
  iunlockput(ip);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	3d8080e7          	jalr	984(ra) # 80003e36 <iunlockput>
  end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	b8e080e7          	jalr	-1138(ra) # 800045f4 <end_op>
  return 0;
    80005a6e:	4501                	li	a0,0
    80005a70:	a84d                	j	80005b22 <sys_unlink+0x1c4>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	b82080e7          	jalr	-1150(ra) # 800045f4 <end_op>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	a05d                	j	80005b22 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a7e:	00003517          	auipc	a0,0x3
    80005a82:	d6a50513          	addi	a0,a0,-662 # 800087e8 <syscalls+0x2c8>
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	ab6080e7          	jalr	-1354(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a8e:	04c92703          	lw	a4,76(s2)
    80005a92:	02000793          	li	a5,32
    80005a96:	f6e7f9e3          	bgeu	a5,a4,80005a08 <sys_unlink+0xaa>
    80005a9a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a9e:	4741                	li	a4,16
    80005aa0:	86ce                	mv	a3,s3
    80005aa2:	f1840613          	addi	a2,s0,-232
    80005aa6:	4581                	li	a1,0
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	3de080e7          	jalr	990(ra) # 80003e88 <readi>
    80005ab2:	47c1                	li	a5,16
    80005ab4:	00f51b63          	bne	a0,a5,80005aca <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ab8:	f1845783          	lhu	a5,-232(s0)
    80005abc:	e7a1                	bnez	a5,80005b04 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005abe:	29c1                	addiw	s3,s3,16
    80005ac0:	04c92783          	lw	a5,76(s2)
    80005ac4:	fcf9ede3          	bltu	s3,a5,80005a9e <sys_unlink+0x140>
    80005ac8:	b781                	j	80005a08 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005aca:	00003517          	auipc	a0,0x3
    80005ace:	d3650513          	addi	a0,a0,-714 # 80008800 <syscalls+0x2e0>
    80005ad2:	ffffb097          	auipc	ra,0xffffb
    80005ad6:	a6a080e7          	jalr	-1430(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ada:	00003517          	auipc	a0,0x3
    80005ade:	d3e50513          	addi	a0,a0,-706 # 80008818 <syscalls+0x2f8>
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	a5a080e7          	jalr	-1446(ra) # 8000053c <panic>
    dp->nlink--;
    80005aea:	04a4d783          	lhu	a5,74(s1)
    80005aee:	37fd                	addiw	a5,a5,-1
    80005af0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005af4:	8526                	mv	a0,s1
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	012080e7          	jalr	18(ra) # 80003b08 <iupdate>
    80005afe:	b781                	j	80005a3e <sys_unlink+0xe0>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	a005                	j	80005b22 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b04:	854a                	mv	a0,s2
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	330080e7          	jalr	816(ra) # 80003e36 <iunlockput>
  iunlockput(dp);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	326080e7          	jalr	806(ra) # 80003e36 <iunlockput>
  end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	adc080e7          	jalr	-1316(ra) # 800045f4 <end_op>
  return -1;
    80005b20:	557d                	li	a0,-1
}
    80005b22:	70ae                	ld	ra,232(sp)
    80005b24:	740e                	ld	s0,224(sp)
    80005b26:	64ee                	ld	s1,216(sp)
    80005b28:	694e                	ld	s2,208(sp)
    80005b2a:	69ae                	ld	s3,200(sp)
    80005b2c:	616d                	addi	sp,sp,240
    80005b2e:	8082                	ret

0000000080005b30 <sys_open>:

uint64
sys_open(void)
{
    80005b30:	7131                	addi	sp,sp,-192
    80005b32:	fd06                	sd	ra,184(sp)
    80005b34:	f922                	sd	s0,176(sp)
    80005b36:	f526                	sd	s1,168(sp)
    80005b38:	f14a                	sd	s2,160(sp)
    80005b3a:	ed4e                	sd	s3,152(sp)
    80005b3c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b3e:	f4c40593          	addi	a1,s0,-180
    80005b42:	4505                	li	a0,1
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	49e080e7          	jalr	1182(ra) # 80002fe2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b4c:	08000613          	li	a2,128
    80005b50:	f5040593          	addi	a1,s0,-176
    80005b54:	4501                	li	a0,0
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	4cc080e7          	jalr	1228(ra) # 80003022 <argstr>
    80005b5e:	87aa                	mv	a5,a0
    return -1;
    80005b60:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b62:	0a07c863          	bltz	a5,80005c12 <sys_open+0xe2>

  begin_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	a14080e7          	jalr	-1516(ra) # 8000457a <begin_op>

  if(omode & O_CREATE){
    80005b6e:	f4c42783          	lw	a5,-180(s0)
    80005b72:	2007f793          	andi	a5,a5,512
    80005b76:	cbdd                	beqz	a5,80005c2c <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b78:	4681                	li	a3,0
    80005b7a:	4601                	li	a2,0
    80005b7c:	4589                	li	a1,2
    80005b7e:	f5040513          	addi	a0,s0,-176
    80005b82:	00000097          	auipc	ra,0x0
    80005b86:	97a080e7          	jalr	-1670(ra) # 800054fc <create>
    80005b8a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b8c:	c951                	beqz	a0,80005c20 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b8e:	04449703          	lh	a4,68(s1)
    80005b92:	478d                	li	a5,3
    80005b94:	00f71763          	bne	a4,a5,80005ba2 <sys_open+0x72>
    80005b98:	0464d703          	lhu	a4,70(s1)
    80005b9c:	47a5                	li	a5,9
    80005b9e:	0ce7ec63          	bltu	a5,a4,80005c76 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	de0080e7          	jalr	-544(ra) # 80004982 <filealloc>
    80005baa:	892a                	mv	s2,a0
    80005bac:	c56d                	beqz	a0,80005c96 <sys_open+0x166>
    80005bae:	00000097          	auipc	ra,0x0
    80005bb2:	90c080e7          	jalr	-1780(ra) # 800054ba <fdalloc>
    80005bb6:	89aa                	mv	s3,a0
    80005bb8:	0c054a63          	bltz	a0,80005c8c <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bbc:	04449703          	lh	a4,68(s1)
    80005bc0:	478d                	li	a5,3
    80005bc2:	0ef70563          	beq	a4,a5,80005cac <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bc6:	4789                	li	a5,2
    80005bc8:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005bcc:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005bd0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005bd4:	f4c42783          	lw	a5,-180(s0)
    80005bd8:	0017c713          	xori	a4,a5,1
    80005bdc:	8b05                	andi	a4,a4,1
    80005bde:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005be2:	0037f713          	andi	a4,a5,3
    80005be6:	00e03733          	snez	a4,a4
    80005bea:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bee:	4007f793          	andi	a5,a5,1024
    80005bf2:	c791                	beqz	a5,80005bfe <sys_open+0xce>
    80005bf4:	04449703          	lh	a4,68(s1)
    80005bf8:	4789                	li	a5,2
    80005bfa:	0cf70063          	beq	a4,a5,80005cba <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	096080e7          	jalr	150(ra) # 80003c96 <iunlock>
  end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	9ec080e7          	jalr	-1556(ra) # 800045f4 <end_op>

  return fd;
    80005c10:	854e                	mv	a0,s3
}
    80005c12:	70ea                	ld	ra,184(sp)
    80005c14:	744a                	ld	s0,176(sp)
    80005c16:	74aa                	ld	s1,168(sp)
    80005c18:	790a                	ld	s2,160(sp)
    80005c1a:	69ea                	ld	s3,152(sp)
    80005c1c:	6129                	addi	sp,sp,192
    80005c1e:	8082                	ret
      end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	9d4080e7          	jalr	-1580(ra) # 800045f4 <end_op>
      return -1;
    80005c28:	557d                	li	a0,-1
    80005c2a:	b7e5                	j	80005c12 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c2c:	f5040513          	addi	a0,s0,-176
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	74a080e7          	jalr	1866(ra) # 8000437a <namei>
    80005c38:	84aa                	mv	s1,a0
    80005c3a:	c905                	beqz	a0,80005c6a <sys_open+0x13a>
    ilock(ip);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	f98080e7          	jalr	-104(ra) # 80003bd4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c44:	04449703          	lh	a4,68(s1)
    80005c48:	4785                	li	a5,1
    80005c4a:	f4f712e3          	bne	a4,a5,80005b8e <sys_open+0x5e>
    80005c4e:	f4c42783          	lw	a5,-180(s0)
    80005c52:	dba1                	beqz	a5,80005ba2 <sys_open+0x72>
      iunlockput(ip);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	1e0080e7          	jalr	480(ra) # 80003e36 <iunlockput>
      end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	996080e7          	jalr	-1642(ra) # 800045f4 <end_op>
      return -1;
    80005c66:	557d                	li	a0,-1
    80005c68:	b76d                	j	80005c12 <sys_open+0xe2>
      end_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	98a080e7          	jalr	-1654(ra) # 800045f4 <end_op>
      return -1;
    80005c72:	557d                	li	a0,-1
    80005c74:	bf79                	j	80005c12 <sys_open+0xe2>
    iunlockput(ip);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	1be080e7          	jalr	446(ra) # 80003e36 <iunlockput>
    end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	974080e7          	jalr	-1676(ra) # 800045f4 <end_op>
    return -1;
    80005c88:	557d                	li	a0,-1
    80005c8a:	b761                	j	80005c12 <sys_open+0xe2>
      fileclose(f);
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	db0080e7          	jalr	-592(ra) # 80004a3e <fileclose>
    iunlockput(ip);
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	19e080e7          	jalr	414(ra) # 80003e36 <iunlockput>
    end_op();
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	954080e7          	jalr	-1708(ra) # 800045f4 <end_op>
    return -1;
    80005ca8:	557d                	li	a0,-1
    80005caa:	b7a5                	j	80005c12 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005cac:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005cb0:	04649783          	lh	a5,70(s1)
    80005cb4:	02f91223          	sh	a5,36(s2)
    80005cb8:	bf21                	j	80005bd0 <sys_open+0xa0>
    itrunc(ip);
    80005cba:	8526                	mv	a0,s1
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	026080e7          	jalr	38(ra) # 80003ce2 <itrunc>
    80005cc4:	bf2d                	j	80005bfe <sys_open+0xce>

0000000080005cc6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cc6:	7175                	addi	sp,sp,-144
    80005cc8:	e506                	sd	ra,136(sp)
    80005cca:	e122                	sd	s0,128(sp)
    80005ccc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	8ac080e7          	jalr	-1876(ra) # 8000457a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cd6:	08000613          	li	a2,128
    80005cda:	f7040593          	addi	a1,s0,-144
    80005cde:	4501                	li	a0,0
    80005ce0:	ffffd097          	auipc	ra,0xffffd
    80005ce4:	342080e7          	jalr	834(ra) # 80003022 <argstr>
    80005ce8:	02054963          	bltz	a0,80005d1a <sys_mkdir+0x54>
    80005cec:	4681                	li	a3,0
    80005cee:	4601                	li	a2,0
    80005cf0:	4585                	li	a1,1
    80005cf2:	f7040513          	addi	a0,s0,-144
    80005cf6:	00000097          	auipc	ra,0x0
    80005cfa:	806080e7          	jalr	-2042(ra) # 800054fc <create>
    80005cfe:	cd11                	beqz	a0,80005d1a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	136080e7          	jalr	310(ra) # 80003e36 <iunlockput>
  end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	8ec080e7          	jalr	-1812(ra) # 800045f4 <end_op>
  return 0;
    80005d10:	4501                	li	a0,0
}
    80005d12:	60aa                	ld	ra,136(sp)
    80005d14:	640a                	ld	s0,128(sp)
    80005d16:	6149                	addi	sp,sp,144
    80005d18:	8082                	ret
    end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	8da080e7          	jalr	-1830(ra) # 800045f4 <end_op>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	b7fd                	j	80005d12 <sys_mkdir+0x4c>

0000000080005d26 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d26:	7135                	addi	sp,sp,-160
    80005d28:	ed06                	sd	ra,152(sp)
    80005d2a:	e922                	sd	s0,144(sp)
    80005d2c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	84c080e7          	jalr	-1972(ra) # 8000457a <begin_op>
  argint(1, &major);
    80005d36:	f6c40593          	addi	a1,s0,-148
    80005d3a:	4505                	li	a0,1
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	2a6080e7          	jalr	678(ra) # 80002fe2 <argint>
  argint(2, &minor);
    80005d44:	f6840593          	addi	a1,s0,-152
    80005d48:	4509                	li	a0,2
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	298080e7          	jalr	664(ra) # 80002fe2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d52:	08000613          	li	a2,128
    80005d56:	f7040593          	addi	a1,s0,-144
    80005d5a:	4501                	li	a0,0
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	2c6080e7          	jalr	710(ra) # 80003022 <argstr>
    80005d64:	02054b63          	bltz	a0,80005d9a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d68:	f6841683          	lh	a3,-152(s0)
    80005d6c:	f6c41603          	lh	a2,-148(s0)
    80005d70:	458d                	li	a1,3
    80005d72:	f7040513          	addi	a0,s0,-144
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	786080e7          	jalr	1926(ra) # 800054fc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d7e:	cd11                	beqz	a0,80005d9a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	0b6080e7          	jalr	182(ra) # 80003e36 <iunlockput>
  end_op();
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	86c080e7          	jalr	-1940(ra) # 800045f4 <end_op>
  return 0;
    80005d90:	4501                	li	a0,0
}
    80005d92:	60ea                	ld	ra,152(sp)
    80005d94:	644a                	ld	s0,144(sp)
    80005d96:	610d                	addi	sp,sp,160
    80005d98:	8082                	ret
    end_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	85a080e7          	jalr	-1958(ra) # 800045f4 <end_op>
    return -1;
    80005da2:	557d                	li	a0,-1
    80005da4:	b7fd                	j	80005d92 <sys_mknod+0x6c>

0000000080005da6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005da6:	7135                	addi	sp,sp,-160
    80005da8:	ed06                	sd	ra,152(sp)
    80005daa:	e922                	sd	s0,144(sp)
    80005dac:	e526                	sd	s1,136(sp)
    80005dae:	e14a                	sd	s2,128(sp)
    80005db0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	eca080e7          	jalr	-310(ra) # 80001c7c <myproc>
    80005dba:	892a                	mv	s2,a0
  
  begin_op();
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	7be080e7          	jalr	1982(ra) # 8000457a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dc4:	08000613          	li	a2,128
    80005dc8:	f6040593          	addi	a1,s0,-160
    80005dcc:	4501                	li	a0,0
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	254080e7          	jalr	596(ra) # 80003022 <argstr>
    80005dd6:	04054b63          	bltz	a0,80005e2c <sys_chdir+0x86>
    80005dda:	f6040513          	addi	a0,s0,-160
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	59c080e7          	jalr	1436(ra) # 8000437a <namei>
    80005de6:	84aa                	mv	s1,a0
    80005de8:	c131                	beqz	a0,80005e2c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	dea080e7          	jalr	-534(ra) # 80003bd4 <ilock>
  if(ip->type != T_DIR){
    80005df2:	04449703          	lh	a4,68(s1)
    80005df6:	4785                	li	a5,1
    80005df8:	04f71063          	bne	a4,a5,80005e38 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	e98080e7          	jalr	-360(ra) # 80003c96 <iunlock>
  iput(p->cwd);
    80005e06:	15893503          	ld	a0,344(s2)
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	f84080e7          	jalr	-124(ra) # 80003d8e <iput>
  end_op();
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	7e2080e7          	jalr	2018(ra) # 800045f4 <end_op>
  p->cwd = ip;
    80005e1a:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e1e:	4501                	li	a0,0
}
    80005e20:	60ea                	ld	ra,152(sp)
    80005e22:	644a                	ld	s0,144(sp)
    80005e24:	64aa                	ld	s1,136(sp)
    80005e26:	690a                	ld	s2,128(sp)
    80005e28:	610d                	addi	sp,sp,160
    80005e2a:	8082                	ret
    end_op();
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	7c8080e7          	jalr	1992(ra) # 800045f4 <end_op>
    return -1;
    80005e34:	557d                	li	a0,-1
    80005e36:	b7ed                	j	80005e20 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e38:	8526                	mv	a0,s1
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	ffc080e7          	jalr	-4(ra) # 80003e36 <iunlockput>
    end_op();
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	7b2080e7          	jalr	1970(ra) # 800045f4 <end_op>
    return -1;
    80005e4a:	557d                	li	a0,-1
    80005e4c:	bfd1                	j	80005e20 <sys_chdir+0x7a>

0000000080005e4e <sys_exec>:

uint64
sys_exec(void)
{
    80005e4e:	7121                	addi	sp,sp,-448
    80005e50:	ff06                	sd	ra,440(sp)
    80005e52:	fb22                	sd	s0,432(sp)
    80005e54:	f726                	sd	s1,424(sp)
    80005e56:	f34a                	sd	s2,416(sp)
    80005e58:	ef4e                	sd	s3,408(sp)
    80005e5a:	eb52                	sd	s4,400(sp)
    80005e5c:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e5e:	e4840593          	addi	a1,s0,-440
    80005e62:	4505                	li	a0,1
    80005e64:	ffffd097          	auipc	ra,0xffffd
    80005e68:	19e080e7          	jalr	414(ra) # 80003002 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e6c:	08000613          	li	a2,128
    80005e70:	f5040593          	addi	a1,s0,-176
    80005e74:	4501                	li	a0,0
    80005e76:	ffffd097          	auipc	ra,0xffffd
    80005e7a:	1ac080e7          	jalr	428(ra) # 80003022 <argstr>
    80005e7e:	87aa                	mv	a5,a0
    return -1;
    80005e80:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e82:	0c07c263          	bltz	a5,80005f46 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e86:	10000613          	li	a2,256
    80005e8a:	4581                	li	a1,0
    80005e8c:	e5040513          	addi	a0,s0,-432
    80005e90:	ffffb097          	auipc	ra,0xffffb
    80005e94:	e3e080e7          	jalr	-450(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e98:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005e9c:	89a6                	mv	s3,s1
    80005e9e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ea0:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ea4:	00391513          	slli	a0,s2,0x3
    80005ea8:	e4040593          	addi	a1,s0,-448
    80005eac:	e4843783          	ld	a5,-440(s0)
    80005eb0:	953e                	add	a0,a0,a5
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	092080e7          	jalr	146(ra) # 80002f44 <fetchaddr>
    80005eba:	02054a63          	bltz	a0,80005eee <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ebe:	e4043783          	ld	a5,-448(s0)
    80005ec2:	c3b9                	beqz	a5,80005f08 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ec4:	ffffb097          	auipc	ra,0xffffb
    80005ec8:	c1e080e7          	jalr	-994(ra) # 80000ae2 <kalloc>
    80005ecc:	85aa                	mv	a1,a0
    80005ece:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ed2:	cd11                	beqz	a0,80005eee <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ed4:	6605                	lui	a2,0x1
    80005ed6:	e4043503          	ld	a0,-448(s0)
    80005eda:	ffffd097          	auipc	ra,0xffffd
    80005ede:	0bc080e7          	jalr	188(ra) # 80002f96 <fetchstr>
    80005ee2:	00054663          	bltz	a0,80005eee <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ee6:	0905                	addi	s2,s2,1
    80005ee8:	09a1                	addi	s3,s3,8
    80005eea:	fb491de3          	bne	s2,s4,80005ea4 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eee:	f5040913          	addi	s2,s0,-176
    80005ef2:	6088                	ld	a0,0(s1)
    80005ef4:	c921                	beqz	a0,80005f44 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ef6:	ffffb097          	auipc	ra,0xffffb
    80005efa:	aee080e7          	jalr	-1298(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efe:	04a1                	addi	s1,s1,8
    80005f00:	ff2499e3          	bne	s1,s2,80005ef2 <sys_exec+0xa4>
  return -1;
    80005f04:	557d                	li	a0,-1
    80005f06:	a081                	j	80005f46 <sys_exec+0xf8>
      argv[i] = 0;
    80005f08:	0009079b          	sext.w	a5,s2
    80005f0c:	078e                	slli	a5,a5,0x3
    80005f0e:	fd078793          	addi	a5,a5,-48
    80005f12:	97a2                	add	a5,a5,s0
    80005f14:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f18:	e5040593          	addi	a1,s0,-432
    80005f1c:	f5040513          	addi	a0,s0,-176
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	194080e7          	jalr	404(ra) # 800050b4 <exec>
    80005f28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f2a:	f5040993          	addi	s3,s0,-176
    80005f2e:	6088                	ld	a0,0(s1)
    80005f30:	c901                	beqz	a0,80005f40 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	ab2080e7          	jalr	-1358(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f3a:	04a1                	addi	s1,s1,8
    80005f3c:	ff3499e3          	bne	s1,s3,80005f2e <sys_exec+0xe0>
  return ret;
    80005f40:	854a                	mv	a0,s2
    80005f42:	a011                	j	80005f46 <sys_exec+0xf8>
  return -1;
    80005f44:	557d                	li	a0,-1
}
    80005f46:	70fa                	ld	ra,440(sp)
    80005f48:	745a                	ld	s0,432(sp)
    80005f4a:	74ba                	ld	s1,424(sp)
    80005f4c:	791a                	ld	s2,416(sp)
    80005f4e:	69fa                	ld	s3,408(sp)
    80005f50:	6a5a                	ld	s4,400(sp)
    80005f52:	6139                	addi	sp,sp,448
    80005f54:	8082                	ret

0000000080005f56 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f56:	7139                	addi	sp,sp,-64
    80005f58:	fc06                	sd	ra,56(sp)
    80005f5a:	f822                	sd	s0,48(sp)
    80005f5c:	f426                	sd	s1,40(sp)
    80005f5e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f60:	ffffc097          	auipc	ra,0xffffc
    80005f64:	d1c080e7          	jalr	-740(ra) # 80001c7c <myproc>
    80005f68:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f6a:	fd840593          	addi	a1,s0,-40
    80005f6e:	4501                	li	a0,0
    80005f70:	ffffd097          	auipc	ra,0xffffd
    80005f74:	092080e7          	jalr	146(ra) # 80003002 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f78:	fc840593          	addi	a1,s0,-56
    80005f7c:	fd040513          	addi	a0,s0,-48
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	dea080e7          	jalr	-534(ra) # 80004d6a <pipealloc>
    return -1;
    80005f88:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f8a:	0c054463          	bltz	a0,80006052 <sys_pipe+0xfc>
  fd0 = -1;
    80005f8e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f92:	fd043503          	ld	a0,-48(s0)
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	524080e7          	jalr	1316(ra) # 800054ba <fdalloc>
    80005f9e:	fca42223          	sw	a0,-60(s0)
    80005fa2:	08054b63          	bltz	a0,80006038 <sys_pipe+0xe2>
    80005fa6:	fc843503          	ld	a0,-56(s0)
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	510080e7          	jalr	1296(ra) # 800054ba <fdalloc>
    80005fb2:	fca42023          	sw	a0,-64(s0)
    80005fb6:	06054863          	bltz	a0,80006026 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fba:	4691                	li	a3,4
    80005fbc:	fc440613          	addi	a2,s0,-60
    80005fc0:	fd843583          	ld	a1,-40(s0)
    80005fc4:	6ca8                	ld	a0,88(s1)
    80005fc6:	ffffb097          	auipc	ra,0xffffb
    80005fca:	6a0080e7          	jalr	1696(ra) # 80001666 <copyout>
    80005fce:	02054063          	bltz	a0,80005fee <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fd2:	4691                	li	a3,4
    80005fd4:	fc040613          	addi	a2,s0,-64
    80005fd8:	fd843583          	ld	a1,-40(s0)
    80005fdc:	0591                	addi	a1,a1,4
    80005fde:	6ca8                	ld	a0,88(s1)
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	686080e7          	jalr	1670(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fe8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fea:	06055463          	bgez	a0,80006052 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fee:	fc442783          	lw	a5,-60(s0)
    80005ff2:	07e9                	addi	a5,a5,26
    80005ff4:	078e                	slli	a5,a5,0x3
    80005ff6:	97a6                	add	a5,a5,s1
    80005ff8:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005ffc:	fc042783          	lw	a5,-64(s0)
    80006000:	07e9                	addi	a5,a5,26
    80006002:	078e                	slli	a5,a5,0x3
    80006004:	94be                	add	s1,s1,a5
    80006006:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    8000600a:	fd043503          	ld	a0,-48(s0)
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	a30080e7          	jalr	-1488(ra) # 80004a3e <fileclose>
    fileclose(wf);
    80006016:	fc843503          	ld	a0,-56(s0)
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	a24080e7          	jalr	-1500(ra) # 80004a3e <fileclose>
    return -1;
    80006022:	57fd                	li	a5,-1
    80006024:	a03d                	j	80006052 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006026:	fc442783          	lw	a5,-60(s0)
    8000602a:	0007c763          	bltz	a5,80006038 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000602e:	07e9                	addi	a5,a5,26
    80006030:	078e                	slli	a5,a5,0x3
    80006032:	97a6                	add	a5,a5,s1
    80006034:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80006038:	fd043503          	ld	a0,-48(s0)
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	a02080e7          	jalr	-1534(ra) # 80004a3e <fileclose>
    fileclose(wf);
    80006044:	fc843503          	ld	a0,-56(s0)
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	9f6080e7          	jalr	-1546(ra) # 80004a3e <fileclose>
    return -1;
    80006050:	57fd                	li	a5,-1
}
    80006052:	853e                	mv	a0,a5
    80006054:	70e2                	ld	ra,56(sp)
    80006056:	7442                	ld	s0,48(sp)
    80006058:	74a2                	ld	s1,40(sp)
    8000605a:	6121                	addi	sp,sp,64
    8000605c:	8082                	ret
	...

0000000080006060 <kernelvec>:
    80006060:	7111                	addi	sp,sp,-256
    80006062:	e006                	sd	ra,0(sp)
    80006064:	e40a                	sd	sp,8(sp)
    80006066:	e80e                	sd	gp,16(sp)
    80006068:	ec12                	sd	tp,24(sp)
    8000606a:	f016                	sd	t0,32(sp)
    8000606c:	f41a                	sd	t1,40(sp)
    8000606e:	f81e                	sd	t2,48(sp)
    80006070:	fc22                	sd	s0,56(sp)
    80006072:	e0a6                	sd	s1,64(sp)
    80006074:	e4aa                	sd	a0,72(sp)
    80006076:	e8ae                	sd	a1,80(sp)
    80006078:	ecb2                	sd	a2,88(sp)
    8000607a:	f0b6                	sd	a3,96(sp)
    8000607c:	f4ba                	sd	a4,104(sp)
    8000607e:	f8be                	sd	a5,112(sp)
    80006080:	fcc2                	sd	a6,120(sp)
    80006082:	e146                	sd	a7,128(sp)
    80006084:	e54a                	sd	s2,136(sp)
    80006086:	e94e                	sd	s3,144(sp)
    80006088:	ed52                	sd	s4,152(sp)
    8000608a:	f156                	sd	s5,160(sp)
    8000608c:	f55a                	sd	s6,168(sp)
    8000608e:	f95e                	sd	s7,176(sp)
    80006090:	fd62                	sd	s8,184(sp)
    80006092:	e1e6                	sd	s9,192(sp)
    80006094:	e5ea                	sd	s10,200(sp)
    80006096:	e9ee                	sd	s11,208(sp)
    80006098:	edf2                	sd	t3,216(sp)
    8000609a:	f1f6                	sd	t4,224(sp)
    8000609c:	f5fa                	sd	t5,232(sp)
    8000609e:	f9fe                	sd	t6,240(sp)
    800060a0:	d71fc0ef          	jal	ra,80002e10 <kerneltrap>
    800060a4:	6082                	ld	ra,0(sp)
    800060a6:	6122                	ld	sp,8(sp)
    800060a8:	61c2                	ld	gp,16(sp)
    800060aa:	7282                	ld	t0,32(sp)
    800060ac:	7322                	ld	t1,40(sp)
    800060ae:	73c2                	ld	t2,48(sp)
    800060b0:	7462                	ld	s0,56(sp)
    800060b2:	6486                	ld	s1,64(sp)
    800060b4:	6526                	ld	a0,72(sp)
    800060b6:	65c6                	ld	a1,80(sp)
    800060b8:	6666                	ld	a2,88(sp)
    800060ba:	7686                	ld	a3,96(sp)
    800060bc:	7726                	ld	a4,104(sp)
    800060be:	77c6                	ld	a5,112(sp)
    800060c0:	7866                	ld	a6,120(sp)
    800060c2:	688a                	ld	a7,128(sp)
    800060c4:	692a                	ld	s2,136(sp)
    800060c6:	69ca                	ld	s3,144(sp)
    800060c8:	6a6a                	ld	s4,152(sp)
    800060ca:	7a8a                	ld	s5,160(sp)
    800060cc:	7b2a                	ld	s6,168(sp)
    800060ce:	7bca                	ld	s7,176(sp)
    800060d0:	7c6a                	ld	s8,184(sp)
    800060d2:	6c8e                	ld	s9,192(sp)
    800060d4:	6d2e                	ld	s10,200(sp)
    800060d6:	6dce                	ld	s11,208(sp)
    800060d8:	6e6e                	ld	t3,216(sp)
    800060da:	7e8e                	ld	t4,224(sp)
    800060dc:	7f2e                	ld	t5,232(sp)
    800060de:	7fce                	ld	t6,240(sp)
    800060e0:	6111                	addi	sp,sp,256
    800060e2:	10200073          	sret
    800060e6:	00000013          	nop
    800060ea:	00000013          	nop
    800060ee:	0001                	nop

00000000800060f0 <timervec>:
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	e10c                	sd	a1,0(a0)
    800060f6:	e510                	sd	a2,8(a0)
    800060f8:	e914                	sd	a3,16(a0)
    800060fa:	6d0c                	ld	a1,24(a0)
    800060fc:	7110                	ld	a2,32(a0)
    800060fe:	6194                	ld	a3,0(a1)
    80006100:	96b2                	add	a3,a3,a2
    80006102:	e194                	sd	a3,0(a1)
    80006104:	4589                	li	a1,2
    80006106:	14459073          	csrw	sip,a1
    8000610a:	6914                	ld	a3,16(a0)
    8000610c:	6510                	ld	a2,8(a0)
    8000610e:	610c                	ld	a1,0(a0)
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	30200073          	mret
	...

000000008000611a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000611a:	1141                	addi	sp,sp,-16
    8000611c:	e422                	sd	s0,8(sp)
    8000611e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006120:	0c0007b7          	lui	a5,0xc000
    80006124:	4705                	li	a4,1
    80006126:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006128:	c3d8                	sw	a4,4(a5)
}
    8000612a:	6422                	ld	s0,8(sp)
    8000612c:	0141                	addi	sp,sp,16
    8000612e:	8082                	ret

0000000080006130 <plicinithart>:

void
plicinithart(void)
{
    80006130:	1141                	addi	sp,sp,-16
    80006132:	e406                	sd	ra,8(sp)
    80006134:	e022                	sd	s0,0(sp)
    80006136:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	b18080e7          	jalr	-1256(ra) # 80001c50 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006140:	0085171b          	slliw	a4,a0,0x8
    80006144:	0c0027b7          	lui	a5,0xc002
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	40200713          	li	a4,1026
    8000614e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006152:	00d5151b          	slliw	a0,a0,0xd
    80006156:	0c2017b7          	lui	a5,0xc201
    8000615a:	97aa                	add	a5,a5,a0
    8000615c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006160:	60a2                	ld	ra,8(sp)
    80006162:	6402                	ld	s0,0(sp)
    80006164:	0141                	addi	sp,sp,16
    80006166:	8082                	ret

0000000080006168 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006168:	1141                	addi	sp,sp,-16
    8000616a:	e406                	sd	ra,8(sp)
    8000616c:	e022                	sd	s0,0(sp)
    8000616e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006170:	ffffc097          	auipc	ra,0xffffc
    80006174:	ae0080e7          	jalr	-1312(ra) # 80001c50 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006178:	00d5151b          	slliw	a0,a0,0xd
    8000617c:	0c2017b7          	lui	a5,0xc201
    80006180:	97aa                	add	a5,a5,a0
  return irq;
}
    80006182:	43c8                	lw	a0,4(a5)
    80006184:	60a2                	ld	ra,8(sp)
    80006186:	6402                	ld	s0,0(sp)
    80006188:	0141                	addi	sp,sp,16
    8000618a:	8082                	ret

000000008000618c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000618c:	1101                	addi	sp,sp,-32
    8000618e:	ec06                	sd	ra,24(sp)
    80006190:	e822                	sd	s0,16(sp)
    80006192:	e426                	sd	s1,8(sp)
    80006194:	1000                	addi	s0,sp,32
    80006196:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	ab8080e7          	jalr	-1352(ra) # 80001c50 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061a0:	00d5151b          	slliw	a0,a0,0xd
    800061a4:	0c2017b7          	lui	a5,0xc201
    800061a8:	97aa                	add	a5,a5,a0
    800061aa:	c3c4                	sw	s1,4(a5)
}
    800061ac:	60e2                	ld	ra,24(sp)
    800061ae:	6442                	ld	s0,16(sp)
    800061b0:	64a2                	ld	s1,8(sp)
    800061b2:	6105                	addi	sp,sp,32
    800061b4:	8082                	ret

00000000800061b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061b6:	1141                	addi	sp,sp,-16
    800061b8:	e406                	sd	ra,8(sp)
    800061ba:	e022                	sd	s0,0(sp)
    800061bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061be:	479d                	li	a5,7
    800061c0:	04a7cc63          	blt	a5,a0,80006218 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061c4:	0001c797          	auipc	a5,0x1c
    800061c8:	d7c78793          	addi	a5,a5,-644 # 80021f40 <disk>
    800061cc:	97aa                	add	a5,a5,a0
    800061ce:	0187c783          	lbu	a5,24(a5)
    800061d2:	ebb9                	bnez	a5,80006228 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061d4:	00451693          	slli	a3,a0,0x4
    800061d8:	0001c797          	auipc	a5,0x1c
    800061dc:	d6878793          	addi	a5,a5,-664 # 80021f40 <disk>
    800061e0:	6398                	ld	a4,0(a5)
    800061e2:	9736                	add	a4,a4,a3
    800061e4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061e8:	6398                	ld	a4,0(a5)
    800061ea:	9736                	add	a4,a4,a3
    800061ec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061f0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061f4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061f8:	97aa                	add	a5,a5,a0
    800061fa:	4705                	li	a4,1
    800061fc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006200:	0001c517          	auipc	a0,0x1c
    80006204:	d5850513          	addi	a0,a0,-680 # 80021f58 <disk+0x18>
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	240080e7          	jalr	576(ra) # 80002448 <wakeup>
}
    80006210:	60a2                	ld	ra,8(sp)
    80006212:	6402                	ld	s0,0(sp)
    80006214:	0141                	addi	sp,sp,16
    80006216:	8082                	ret
    panic("free_desc 1");
    80006218:	00002517          	auipc	a0,0x2
    8000621c:	61050513          	addi	a0,a0,1552 # 80008828 <syscalls+0x308>
    80006220:	ffffa097          	auipc	ra,0xffffa
    80006224:	31c080e7          	jalr	796(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	61050513          	addi	a0,a0,1552 # 80008838 <syscalls+0x318>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	30c080e7          	jalr	780(ra) # 8000053c <panic>

0000000080006238 <virtio_disk_init>:
{
    80006238:	1101                	addi	sp,sp,-32
    8000623a:	ec06                	sd	ra,24(sp)
    8000623c:	e822                	sd	s0,16(sp)
    8000623e:	e426                	sd	s1,8(sp)
    80006240:	e04a                	sd	s2,0(sp)
    80006242:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006244:	00002597          	auipc	a1,0x2
    80006248:	60458593          	addi	a1,a1,1540 # 80008848 <syscalls+0x328>
    8000624c:	0001c517          	auipc	a0,0x1c
    80006250:	e1c50513          	addi	a0,a0,-484 # 80022068 <disk+0x128>
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	8ee080e7          	jalr	-1810(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	4398                	lw	a4,0(a5)
    80006262:	2701                	sext.w	a4,a4
    80006264:	747277b7          	lui	a5,0x74727
    80006268:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000626c:	14f71b63          	bne	a4,a5,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006270:	100017b7          	lui	a5,0x10001
    80006274:	43dc                	lw	a5,4(a5)
    80006276:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006278:	4709                	li	a4,2
    8000627a:	14e79463          	bne	a5,a4,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000627e:	100017b7          	lui	a5,0x10001
    80006282:	479c                	lw	a5,8(a5)
    80006284:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006286:	12e79e63          	bne	a5,a4,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000628a:	100017b7          	lui	a5,0x10001
    8000628e:	47d8                	lw	a4,12(a5)
    80006290:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006292:	554d47b7          	lui	a5,0x554d4
    80006296:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000629a:	12f71463          	bne	a4,a5,800063c2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a6:	4705                	li	a4,1
    800062a8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062aa:	470d                	li	a4,3
    800062ac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062ae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062b0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062b4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc6df>
    800062b8:	8f75                	and	a4,a4,a3
    800062ba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062bc:	472d                	li	a4,11
    800062be:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062c0:	5bbc                	lw	a5,112(a5)
    800062c2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062c6:	8ba1                	andi	a5,a5,8
    800062c8:	10078563          	beqz	a5,800063d2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062d4:	43fc                	lw	a5,68(a5)
    800062d6:	2781                	sext.w	a5,a5
    800062d8:	10079563          	bnez	a5,800063e2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062dc:	100017b7          	lui	a5,0x10001
    800062e0:	5bdc                	lw	a5,52(a5)
    800062e2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062e4:	10078763          	beqz	a5,800063f2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062e8:	471d                	li	a4,7
    800062ea:	10f77c63          	bgeu	a4,a5,80006402 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	7f4080e7          	jalr	2036(ra) # 80000ae2 <kalloc>
    800062f6:	0001c497          	auipc	s1,0x1c
    800062fa:	c4a48493          	addi	s1,s1,-950 # 80021f40 <disk>
    800062fe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	7e2080e7          	jalr	2018(ra) # 80000ae2 <kalloc>
    80006308:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	7d8080e7          	jalr	2008(ra) # 80000ae2 <kalloc>
    80006312:	87aa                	mv	a5,a0
    80006314:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006316:	6088                	ld	a0,0(s1)
    80006318:	cd6d                	beqz	a0,80006412 <virtio_disk_init+0x1da>
    8000631a:	0001c717          	auipc	a4,0x1c
    8000631e:	c2e73703          	ld	a4,-978(a4) # 80021f48 <disk+0x8>
    80006322:	cb65                	beqz	a4,80006412 <virtio_disk_init+0x1da>
    80006324:	c7fd                	beqz	a5,80006412 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006326:	6605                	lui	a2,0x1
    80006328:	4581                	li	a1,0
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	9a4080e7          	jalr	-1628(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006332:	0001c497          	auipc	s1,0x1c
    80006336:	c0e48493          	addi	s1,s1,-1010 # 80021f40 <disk>
    8000633a:	6605                	lui	a2,0x1
    8000633c:	4581                	li	a1,0
    8000633e:	6488                	ld	a0,8(s1)
    80006340:	ffffb097          	auipc	ra,0xffffb
    80006344:	98e080e7          	jalr	-1650(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006348:	6605                	lui	a2,0x1
    8000634a:	4581                	li	a1,0
    8000634c:	6888                	ld	a0,16(s1)
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	980080e7          	jalr	-1664(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006356:	100017b7          	lui	a5,0x10001
    8000635a:	4721                	li	a4,8
    8000635c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000635e:	4098                	lw	a4,0(s1)
    80006360:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006364:	40d8                	lw	a4,4(s1)
    80006366:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000636a:	6498                	ld	a4,8(s1)
    8000636c:	0007069b          	sext.w	a3,a4
    80006370:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006374:	9701                	srai	a4,a4,0x20
    80006376:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000637a:	6898                	ld	a4,16(s1)
    8000637c:	0007069b          	sext.w	a3,a4
    80006380:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006384:	9701                	srai	a4,a4,0x20
    80006386:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000638a:	4705                	li	a4,1
    8000638c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000638e:	00e48c23          	sb	a4,24(s1)
    80006392:	00e48ca3          	sb	a4,25(s1)
    80006396:	00e48d23          	sb	a4,26(s1)
    8000639a:	00e48da3          	sb	a4,27(s1)
    8000639e:	00e48e23          	sb	a4,28(s1)
    800063a2:	00e48ea3          	sb	a4,29(s1)
    800063a6:	00e48f23          	sb	a4,30(s1)
    800063aa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063ae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b2:	0727a823          	sw	s2,112(a5)
}
    800063b6:	60e2                	ld	ra,24(sp)
    800063b8:	6442                	ld	s0,16(sp)
    800063ba:	64a2                	ld	s1,8(sp)
    800063bc:	6902                	ld	s2,0(sp)
    800063be:	6105                	addi	sp,sp,32
    800063c0:	8082                	ret
    panic("could not find virtio disk");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	49650513          	addi	a0,a0,1174 # 80008858 <syscalls+0x338>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	172080e7          	jalr	370(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	4a650513          	addi	a0,a0,1190 # 80008878 <syscalls+0x358>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	4b650513          	addi	a0,a0,1206 # 80008898 <syscalls+0x378>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	4c650513          	addi	a0,a0,1222 # 800088b8 <syscalls+0x398>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	4d650513          	addi	a0,a0,1238 # 800088d8 <syscalls+0x3b8>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	4e650513          	addi	a0,a0,1254 # 800088f8 <syscalls+0x3d8>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>

0000000080006422 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006422:	7159                	addi	sp,sp,-112
    80006424:	f486                	sd	ra,104(sp)
    80006426:	f0a2                	sd	s0,96(sp)
    80006428:	eca6                	sd	s1,88(sp)
    8000642a:	e8ca                	sd	s2,80(sp)
    8000642c:	e4ce                	sd	s3,72(sp)
    8000642e:	e0d2                	sd	s4,64(sp)
    80006430:	fc56                	sd	s5,56(sp)
    80006432:	f85a                	sd	s6,48(sp)
    80006434:	f45e                	sd	s7,40(sp)
    80006436:	f062                	sd	s8,32(sp)
    80006438:	ec66                	sd	s9,24(sp)
    8000643a:	e86a                	sd	s10,16(sp)
    8000643c:	1880                	addi	s0,sp,112
    8000643e:	8a2a                	mv	s4,a0
    80006440:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006442:	00c52c83          	lw	s9,12(a0)
    80006446:	001c9c9b          	slliw	s9,s9,0x1
    8000644a:	1c82                	slli	s9,s9,0x20
    8000644c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006450:	0001c517          	auipc	a0,0x1c
    80006454:	c1850513          	addi	a0,a0,-1000 # 80022068 <disk+0x128>
    80006458:	ffffa097          	auipc	ra,0xffffa
    8000645c:	77a080e7          	jalr	1914(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006460:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006462:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006464:	0001cb17          	auipc	s6,0x1c
    80006468:	adcb0b13          	addi	s6,s6,-1316 # 80021f40 <disk>
  for(int i = 0; i < 3; i++){
    8000646c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000646e:	0001cc17          	auipc	s8,0x1c
    80006472:	bfac0c13          	addi	s8,s8,-1030 # 80022068 <disk+0x128>
    80006476:	a095                	j	800064da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006478:	00fb0733          	add	a4,s6,a5
    8000647c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006480:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006482:	0207c563          	bltz	a5,800064ac <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006486:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006488:	0591                	addi	a1,a1,4
    8000648a:	05560d63          	beq	a2,s5,800064e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000648e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006490:	0001c717          	auipc	a4,0x1c
    80006494:	ab070713          	addi	a4,a4,-1360 # 80021f40 <disk>
    80006498:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000649a:	01874683          	lbu	a3,24(a4)
    8000649e:	fee9                	bnez	a3,80006478 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064a0:	2785                	addiw	a5,a5,1
    800064a2:	0705                	addi	a4,a4,1
    800064a4:	fe979be3          	bne	a5,s1,8000649a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064a8:	57fd                	li	a5,-1
    800064aa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064ac:	00c05e63          	blez	a2,800064c8 <virtio_disk_rw+0xa6>
    800064b0:	060a                	slli	a2,a2,0x2
    800064b2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064b6:	0009a503          	lw	a0,0(s3)
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	cfc080e7          	jalr	-772(ra) # 800061b6 <free_desc>
      for(int j = 0; j < i; j++)
    800064c2:	0991                	addi	s3,s3,4
    800064c4:	ffa999e3          	bne	s3,s10,800064b6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064c8:	85e2                	mv	a1,s8
    800064ca:	0001c517          	auipc	a0,0x1c
    800064ce:	a8e50513          	addi	a0,a0,-1394 # 80021f58 <disk+0x18>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	f12080e7          	jalr	-238(ra) # 800023e4 <sleep>
  for(int i = 0; i < 3; i++){
    800064da:	f9040993          	addi	s3,s0,-112
{
    800064de:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064e0:	864a                	mv	a2,s2
    800064e2:	b775                	j	8000648e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064e4:	f9042503          	lw	a0,-112(s0)
    800064e8:	00a50713          	addi	a4,a0,10
    800064ec:	0712                	slli	a4,a4,0x4

  if(write)
    800064ee:	0001c797          	auipc	a5,0x1c
    800064f2:	a5278793          	addi	a5,a5,-1454 # 80021f40 <disk>
    800064f6:	00e786b3          	add	a3,a5,a4
    800064fa:	01703633          	snez	a2,s7
    800064fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006500:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006504:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006508:	f6070613          	addi	a2,a4,-160
    8000650c:	6394                	ld	a3,0(a5)
    8000650e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006510:	00870593          	addi	a1,a4,8
    80006514:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006516:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006518:	0007b803          	ld	a6,0(a5)
    8000651c:	9642                	add	a2,a2,a6
    8000651e:	46c1                	li	a3,16
    80006520:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006522:	4585                	li	a1,1
    80006524:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006528:	f9442683          	lw	a3,-108(s0)
    8000652c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006530:	0692                	slli	a3,a3,0x4
    80006532:	9836                	add	a6,a6,a3
    80006534:	058a0613          	addi	a2,s4,88
    80006538:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000653c:	0007b803          	ld	a6,0(a5)
    80006540:	96c2                	add	a3,a3,a6
    80006542:	40000613          	li	a2,1024
    80006546:	c690                	sw	a2,8(a3)
  if(write)
    80006548:	001bb613          	seqz	a2,s7
    8000654c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006550:	00166613          	ori	a2,a2,1
    80006554:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006558:	f9842603          	lw	a2,-104(s0)
    8000655c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006560:	00250693          	addi	a3,a0,2
    80006564:	0692                	slli	a3,a3,0x4
    80006566:	96be                	add	a3,a3,a5
    80006568:	58fd                	li	a7,-1
    8000656a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000656e:	0612                	slli	a2,a2,0x4
    80006570:	9832                	add	a6,a6,a2
    80006572:	f9070713          	addi	a4,a4,-112
    80006576:	973e                	add	a4,a4,a5
    80006578:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000657c:	6398                	ld	a4,0(a5)
    8000657e:	9732                	add	a4,a4,a2
    80006580:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006582:	4609                	li	a2,2
    80006584:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006588:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000658c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006590:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006594:	6794                	ld	a3,8(a5)
    80006596:	0026d703          	lhu	a4,2(a3)
    8000659a:	8b1d                	andi	a4,a4,7
    8000659c:	0706                	slli	a4,a4,0x1
    8000659e:	96ba                	add	a3,a3,a4
    800065a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065a8:	6798                	ld	a4,8(a5)
    800065aa:	00275783          	lhu	a5,2(a4)
    800065ae:	2785                	addiw	a5,a5,1
    800065b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065b8:	100017b7          	lui	a5,0x10001
    800065bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065c0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065c4:	0001c917          	auipc	s2,0x1c
    800065c8:	aa490913          	addi	s2,s2,-1372 # 80022068 <disk+0x128>
  while(b->disk == 1) {
    800065cc:	4485                	li	s1,1
    800065ce:	00b79c63          	bne	a5,a1,800065e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065d2:	85ca                	mv	a1,s2
    800065d4:	8552                	mv	a0,s4
    800065d6:	ffffc097          	auipc	ra,0xffffc
    800065da:	e0e080e7          	jalr	-498(ra) # 800023e4 <sleep>
  while(b->disk == 1) {
    800065de:	004a2783          	lw	a5,4(s4)
    800065e2:	fe9788e3          	beq	a5,s1,800065d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065e6:	f9042903          	lw	s2,-112(s0)
    800065ea:	00290713          	addi	a4,s2,2
    800065ee:	0712                	slli	a4,a4,0x4
    800065f0:	0001c797          	auipc	a5,0x1c
    800065f4:	95078793          	addi	a5,a5,-1712 # 80021f40 <disk>
    800065f8:	97ba                	add	a5,a5,a4
    800065fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065fe:	0001c997          	auipc	s3,0x1c
    80006602:	94298993          	addi	s3,s3,-1726 # 80021f40 <disk>
    80006606:	00491713          	slli	a4,s2,0x4
    8000660a:	0009b783          	ld	a5,0(s3)
    8000660e:	97ba                	add	a5,a5,a4
    80006610:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006614:	854a                	mv	a0,s2
    80006616:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000661a:	00000097          	auipc	ra,0x0
    8000661e:	b9c080e7          	jalr	-1124(ra) # 800061b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006622:	8885                	andi	s1,s1,1
    80006624:	f0ed                	bnez	s1,80006606 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006626:	0001c517          	auipc	a0,0x1c
    8000662a:	a4250513          	addi	a0,a0,-1470 # 80022068 <disk+0x128>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	658080e7          	jalr	1624(ra) # 80000c86 <release>
}
    80006636:	70a6                	ld	ra,104(sp)
    80006638:	7406                	ld	s0,96(sp)
    8000663a:	64e6                	ld	s1,88(sp)
    8000663c:	6946                	ld	s2,80(sp)
    8000663e:	69a6                	ld	s3,72(sp)
    80006640:	6a06                	ld	s4,64(sp)
    80006642:	7ae2                	ld	s5,56(sp)
    80006644:	7b42                	ld	s6,48(sp)
    80006646:	7ba2                	ld	s7,40(sp)
    80006648:	7c02                	ld	s8,32(sp)
    8000664a:	6ce2                	ld	s9,24(sp)
    8000664c:	6d42                	ld	s10,16(sp)
    8000664e:	6165                	addi	sp,sp,112
    80006650:	8082                	ret

0000000080006652 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006652:	1101                	addi	sp,sp,-32
    80006654:	ec06                	sd	ra,24(sp)
    80006656:	e822                	sd	s0,16(sp)
    80006658:	e426                	sd	s1,8(sp)
    8000665a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000665c:	0001c497          	auipc	s1,0x1c
    80006660:	8e448493          	addi	s1,s1,-1820 # 80021f40 <disk>
    80006664:	0001c517          	auipc	a0,0x1c
    80006668:	a0450513          	addi	a0,a0,-1532 # 80022068 <disk+0x128>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	566080e7          	jalr	1382(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006674:	10001737          	lui	a4,0x10001
    80006678:	533c                	lw	a5,96(a4)
    8000667a:	8b8d                	andi	a5,a5,3
    8000667c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000667e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006682:	689c                	ld	a5,16(s1)
    80006684:	0204d703          	lhu	a4,32(s1)
    80006688:	0027d783          	lhu	a5,2(a5)
    8000668c:	04f70863          	beq	a4,a5,800066dc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006690:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006694:	6898                	ld	a4,16(s1)
    80006696:	0204d783          	lhu	a5,32(s1)
    8000669a:	8b9d                	andi	a5,a5,7
    8000669c:	078e                	slli	a5,a5,0x3
    8000669e:	97ba                	add	a5,a5,a4
    800066a0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066a2:	00278713          	addi	a4,a5,2
    800066a6:	0712                	slli	a4,a4,0x4
    800066a8:	9726                	add	a4,a4,s1
    800066aa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066ae:	e721                	bnez	a4,800066f6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066b0:	0789                	addi	a5,a5,2
    800066b2:	0792                	slli	a5,a5,0x4
    800066b4:	97a6                	add	a5,a5,s1
    800066b6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066bc:	ffffc097          	auipc	ra,0xffffc
    800066c0:	d8c080e7          	jalr	-628(ra) # 80002448 <wakeup>

    disk.used_idx += 1;
    800066c4:	0204d783          	lhu	a5,32(s1)
    800066c8:	2785                	addiw	a5,a5,1
    800066ca:	17c2                	slli	a5,a5,0x30
    800066cc:	93c1                	srli	a5,a5,0x30
    800066ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066d2:	6898                	ld	a4,16(s1)
    800066d4:	00275703          	lhu	a4,2(a4)
    800066d8:	faf71ce3          	bne	a4,a5,80006690 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066dc:	0001c517          	auipc	a0,0x1c
    800066e0:	98c50513          	addi	a0,a0,-1652 # 80022068 <disk+0x128>
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	5a2080e7          	jalr	1442(ra) # 80000c86 <release>
}
    800066ec:	60e2                	ld	ra,24(sp)
    800066ee:	6442                	ld	s0,16(sp)
    800066f0:	64a2                	ld	s1,8(sp)
    800066f2:	6105                	addi	sp,sp,32
    800066f4:	8082                	ret
      panic("virtio_disk_intr status");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	21a50513          	addi	a0,a0,538 # 80008910 <syscalls+0x3f0>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e3e080e7          	jalr	-450(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
