
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c1010113          	addi	sp,sp,-1008 # 80008c10 <stack0>
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
    80000054:	a8070713          	addi	a4,a4,-1408 # 80008ad0 <timer_scratch>
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
    80000066:	11e78793          	addi	a5,a5,286 # 80006180 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd48bf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	eba78793          	addi	a5,a5,-326 # 80000f66 <main>
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
    8000012e:	652080e7          	jalr	1618(ra) # 8000277c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	792080e7          	jalr	1938(ra) # 800008cc <uartputc>
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
    80000188:	a8c50513          	addi	a0,a0,-1396 # 80010c10 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b3a080e7          	jalr	-1222(ra) # 80000cc6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	a7c48493          	addi	s1,s1,-1412 # 80010c10 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	b0c90913          	addi	s2,s2,-1268 # 80010ca8 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	a02080e7          	jalr	-1534(ra) # 80001bb6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	40a080e7          	jalr	1034(ra) # 800025c6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	154080e7          	jalr	340(ra) # 8000231e <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	a3270713          	addi	a4,a4,-1486 # 80010c10 <cons>
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
    80000214:	516080e7          	jalr	1302(ra) # 80002726 <either_copyout>
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
    8000022c:	9e850513          	addi	a0,a0,-1560 # 80010c10 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b4a080e7          	jalr	-1206(ra) # 80000d7a <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	9d250513          	addi	a0,a0,-1582 # 80010c10 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b34080e7          	jalr	-1228(ra) # 80000d7a <release>
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
    80000272:	a2f72d23          	sw	a5,-1478(a4) # 80010ca8 <cons+0x98>
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
    8000028c:	572080e7          	jalr	1394(ra) # 800007fa <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	560080e7          	jalr	1376(ra) # 800007fa <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	554080e7          	jalr	1364(ra) # 800007fa <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	54a080e7          	jalr	1354(ra) # 800007fa <uartputc_sync>
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
    800002cc:	94850513          	addi	a0,a0,-1720 # 80010c10 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	9f6080e7          	jalr	-1546(ra) # 80000cc6 <acquire>

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
    800002f2:	4e4080e7          	jalr	1252(ra) # 800027d2 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	91a50513          	addi	a0,a0,-1766 # 80010c10 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a7c080e7          	jalr	-1412(ra) # 80000d7a <release>
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
    8000031e:	8f670713          	addi	a4,a4,-1802 # 80010c10 <cons>
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
    80000348:	8cc78793          	addi	a5,a5,-1844 # 80010c10 <cons>
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
    80000376:	9367a783          	lw	a5,-1738(a5) # 80010ca8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	88a70713          	addi	a4,a4,-1910 # 80010c10 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	87a48493          	addi	s1,s1,-1926 # 80010c10 <cons>
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
    800003d2:	00011717          	auipc	a4,0x11
    800003d6:	83e70713          	addi	a4,a4,-1986 # 80010c10 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	8cf72423          	sw	a5,-1848(a4) # 80010cb0 <cons+0xa0>
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
    8000040e:	00011797          	auipc	a5,0x11
    80000412:	80278793          	addi	a5,a5,-2046 # 80010c10 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	86c7ad23          	sw	a2,-1926(a5) # 80010cac <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	86e50513          	addi	a0,a0,-1938 # 80010ca8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	f40080e7          	jalr	-192(ra) # 80002382 <wakeup>
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
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.1+0x18>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	7b450513          	addi	a0,a0,1972 # 80010c10 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	7d2080e7          	jalr	2002(ra) # 80000c36 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00029797          	auipc	a5,0x29
    80000478:	93478793          	addi	a5,a5,-1740 # 80028da8 <devsw>
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

    if (sign && (sign = xx < 0))
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
    do
    {
        buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

    if (sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
        buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
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
    while (--i >= 0)
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
    if (sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
        x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    8000053c:	711d                	addi	sp,sp,-96
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
    80000548:	e40c                	sd	a1,8(s0)
    8000054a:	e810                	sd	a2,16(s0)
    8000054c:	ec14                	sd	a3,24(s0)
    8000054e:	f018                	sd	a4,32(s0)
    80000550:	f41c                	sd	a5,40(s0)
    80000552:	03043823          	sd	a6,48(s0)
    80000556:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055a:	00010797          	auipc	a5,0x10
    8000055e:	7607ab23          	sw	zero,1910(a5) # 80010cd0 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ac650513          	addi	a0,a0,-1338 # 80008028 <__func__.1+0x20>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b0c50513          	addi	a0,a0,-1268 # 80008088 <digits+0x38>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	4ef72923          	sw	a5,1266(a4) # 80008a80 <panicked>
    for (;;)
    80000596:	a001                	j	80000596 <panic+0x5a>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	706dad83          	lw	s11,1798(s11) # 80010cd0 <pr+0x18>
    if (locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
    if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
    va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	14050f63          	beqz	a0,80000744 <printf+0x1ac>
    800005ea:	4981                	li	s3,0
        if (c != '%')
    800005ec:	02500a93          	li	s5,37
        switch (c)
    800005f0:	07000b93          	li	s7,112
    consputc('x');
    800005f4:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b17          	auipc	s6,0x8
    800005fa:	a5ab0b13          	addi	s6,s6,-1446 # 80008050 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	6b050513          	addi	a0,a0,1712 # 80010cb8 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	6b6080e7          	jalr	1718(ra) # 80000cc6 <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a1e50513          	addi	a0,a0,-1506 # 80008038 <__func__.1+0x30>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f1a080e7          	jalr	-230(ra) # 8000053c <panic>
            consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	c4e080e7          	jalr	-946(ra) # 80000278 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050463          	beqz	a0,80000744 <printf+0x1ac>
        if (c != '%')
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
        c = fmt[++i] & 0xff;
    80000644:	2985                	addiw	s3,s3,1
    80000646:	013a07b3          	add	a5,s4,s3
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000652:	cbed                	beqz	a5,80000744 <printf+0x1ac>
        switch (c)
    80000654:	05778a63          	beq	a5,s7,800006a8 <printf+0x110>
    80000658:	02fbf663          	bgeu	s7,a5,80000684 <printf+0xec>
    8000065c:	09978863          	beq	a5,s9,800006ec <printf+0x154>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79563          	bne	a5,a4,8000072e <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e1e080e7          	jalr	-482(ra) # 80000498 <printint>
            break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
        switch (c)
    80000684:	09578f63          	beq	a5,s5,80000722 <printf+0x18a>
    80000688:	0b879363          	bne	a5,s8,8000072e <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	dfa080e7          	jalr	-518(ra) # 80000498 <printint>
            break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bbc080e7          	jalr	-1092(ra) # 80000278 <consputc>
    consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bb0080e7          	jalr	-1104(ra) # 80000278 <consputc>
    800006d0:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c95793          	srli	a5,s2,0x3c
    800006d6:	97da                	add	a5,a5,s6
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b9c080e7          	jalr	-1124(ra) # 80000278 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0912                	slli	s2,s2,0x4
    800006e6:	34fd                	addiw	s1,s1,-1
    800006e8:	f4ed                	bnez	s1,800006d2 <printf+0x13a>
    800006ea:	b7a1                	j	80000632 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006ec:	f8843783          	ld	a5,-120(s0)
    800006f0:	00878713          	addi	a4,a5,8
    800006f4:	f8e43423          	sd	a4,-120(s0)
    800006f8:	6384                	ld	s1,0(a5)
    800006fa:	cc89                	beqz	s1,80000714 <printf+0x17c>
            for (; *s; s++)
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	d90d                	beqz	a0,80000632 <printf+0x9a>
                consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b76080e7          	jalr	-1162(ra) # 80000278 <consputc>
            for (; *s; s++)
    8000070a:	0485                	addi	s1,s1,1
    8000070c:	0004c503          	lbu	a0,0(s1)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x16a>
    80000712:	b705                	j	80000632 <printf+0x9a>
                s = "(null)";
    80000714:	00008497          	auipc	s1,0x8
    80000718:	91c48493          	addi	s1,s1,-1764 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x16a>
            consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b54080e7          	jalr	-1196(ra) # 80000278 <consputc>
            break;
    8000072c:	b719                	j	80000632 <printf+0x9a>
            consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b48080e7          	jalr	-1208(ra) # 80000278 <consputc>
            consputc(c);
    80000738:	8526                	mv	a0,s1
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b3e080e7          	jalr	-1218(ra) # 80000278 <consputc>
            break;
    80000742:	bdc5                	j	80000632 <printf+0x9a>
    if (locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1ce>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
        release(&pr.lock);
    80000766:	00010517          	auipc	a0,0x10
    8000076a:	55250513          	addi	a0,a0,1362 # 80010cb8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	60c080e7          	jalr	1548(ra) # 80000d7a <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b0>

0000000080000778 <printfinit>:
        ;
}

void printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000782:	00010497          	auipc	s1,0x10
    80000786:	53648493          	addi	s1,s1,1334 # 80010cb8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	4a2080e7          	jalr	1186(ra) # 80000c36 <initlock>
    pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	88e58593          	addi	a1,a1,-1906 # 80008068 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	4f650513          	addi	a0,a0,1270 # 80010cd8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	44c080e7          	jalr	1100(ra) # 80000c36 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	474080e7          	jalr	1140(ra) # 80000c7a <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	2727a783          	lw	a5,626(a5) # 80008a80 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dfe5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f513          	zext.b	a0,s1
    8000082c:	100007b7          	lui	a5,0x10000
    80000830:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	4e6080e7          	jalr	1254(ra) # 80000d1a <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008797          	auipc	a5,0x8
    8000084a:	2427b783          	ld	a5,578(a5) # 80008a88 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	24273703          	ld	a4,578(a4) # 80008a90 <uart_tx_w>
    80000856:	06f70a63          	beq	a4,a5,800008ca <uartstart+0x84>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	468a0a13          	addi	s4,s4,1128 # 80010cd8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	21048493          	addi	s1,s1,528 # 80008a88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	21098993          	addi	s3,s3,528 # 80008a90 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	02077713          	andi	a4,a4,32
    80000890:	c705                	beqz	a4,800008b8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f7f713          	andi	a4,a5,31
    80000896:	9752                	add	a4,a4,s4
    80000898:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000089c:	0785                	addi	a5,a5,1
    8000089e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	ae0080e7          	jalr	-1312(ra) # 80002382 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	609c                	ld	a5,0(s1)
    800008b0:	0009b703          	ld	a4,0(s3)
    800008b4:	fcf71ae3          	bne	a4,a5,80000888 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008de:	00010517          	auipc	a0,0x10
    800008e2:	3fa50513          	addi	a0,a0,1018 # 80010cd8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	3e0080e7          	jalr	992(ra) # 80000cc6 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1927a783          	lw	a5,402(a5) # 80008a80 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	19873703          	ld	a4,408(a4) # 80008a90 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1887b783          	ld	a5,392(a5) # 80008a88 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	3cc98993          	addi	s3,s3,972 # 80010cd8 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	17448493          	addi	s1,s1,372 # 80008a88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	17490913          	addi	s2,s2,372 # 80008a90 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	9f2080e7          	jalr	-1550(ra) # 8000231e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	39648493          	addi	s1,s1,918 # 80010cd8 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	12e7bd23          	sd	a4,314(a5) # 80008a90 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	412080e7          	jalr	1042(ra) # 80000d7a <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0xb4>

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb81                	beqz	a5,800009a2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000099c:	6422                	ld	s0,8(sp)
    8000099e:	0141                	addi	sp,sp,16
    800009a0:	8082                	ret
    return -1;
    800009a2:	557d                	li	a0,-1
    800009a4:	bfe5                	j	8000099c <uartgetc+0x1a>

00000000800009a6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009a6:	1101                	addi	sp,sp,-32
    800009a8:	ec06                	sd	ra,24(sp)
    800009aa:	e822                	sd	s0,16(sp)
    800009ac:	e426                	sd	s1,8(sp)
    800009ae:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b0:	54fd                	li	s1,-1
    800009b2:	a029                	j	800009bc <uartintr+0x16>
      break;
    consoleintr(c);
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	906080e7          	jalr	-1786(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009bc:	00000097          	auipc	ra,0x0
    800009c0:	fc6080e7          	jalr	-58(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009c4:	fe9518e3          	bne	a0,s1,800009b4 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009c8:	00010497          	auipc	s1,0x10
    800009cc:	31048493          	addi	s1,s1,784 # 80010cd8 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2f4080e7          	jalr	756(ra) # 80000cc6 <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	396080e7          	jalr	918(ra) # 80000d7a <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009f6:	7179                	addi	sp,sp,-48
    800009f8:	f406                	sd	ra,40(sp)
    800009fa:	f022                	sd	s0,32(sp)
    800009fc:	ec26                	sd	s1,24(sp)
    800009fe:	e84a                	sd	s2,16(sp)
    80000a00:	e44e                	sd	s3,8(sp)
    80000a02:	1800                	addi	s0,sp,48
    if (parefs[PTE2PPN(PA2PTE(pa))] > 1)
    80000a04:	00c55993          	srli	s3,a0,0xc
    80000a08:	00010797          	auipc	a5,0x10
    80000a0c:	32878793          	addi	a5,a5,808 # 80010d30 <parefs>
    80000a10:	97ce                	add	a5,a5,s3
    80000a12:	0007c703          	lbu	a4,0(a5)
    80000a16:	4785                	li	a5,1
    80000a18:	08e7e463          	bltu	a5,a4,80000aa0 <kfree+0xaa>
    80000a1c:	84aa                	mv	s1,a0
    80000a1e:	86aa                	mv	a3,a0
    {return;}
    if (MAX_PAGES != 0)
    80000a20:	00008797          	auipc	a5,0x8
    80000a24:	0807b783          	ld	a5,128(a5) # 80008aa0 <MAX_PAGES>
    80000a28:	c799                	beqz	a5,80000a36 <kfree+0x40>
        assert(FREE_PAGES < MAX_PAGES);
    80000a2a:	00008717          	auipc	a4,0x8
    80000a2e:	06e73703          	ld	a4,110(a4) # 80008a98 <FREE_PAGES>
    80000a32:	06f77e63          	bgeu	a4,a5,80000aae <kfree+0xb8>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a36:	03449793          	slli	a5,s1,0x34
    80000a3a:	e7c5                	bnez	a5,80000ae2 <kfree+0xec>
    80000a3c:	00029797          	auipc	a5,0x29
    80000a40:	50478793          	addi	a5,a5,1284 # 80029f40 <end>
    80000a44:	08f4ef63          	bltu	s1,a5,80000ae2 <kfree+0xec>
    80000a48:	47c5                	li	a5,17
    80000a4a:	07ee                	slli	a5,a5,0x1b
    80000a4c:	08f6fb63          	bgeu	a3,a5,80000ae2 <kfree+0xec>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a50:	6605                	lui	a2,0x1
    80000a52:	4585                	li	a1,1
    80000a54:	8526                	mv	a0,s1
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	36c080e7          	jalr	876(ra) # 80000dc2 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a5e:	00010917          	auipc	s2,0x10
    80000a62:	2b290913          	addi	s2,s2,690 # 80010d10 <kmem>
    80000a66:	854a                	mv	a0,s2
    80000a68:	00000097          	auipc	ra,0x0
    80000a6c:	25e080e7          	jalr	606(ra) # 80000cc6 <acquire>
    r->next = kmem.freelist;
    80000a70:	01893783          	ld	a5,24(s2)
    80000a74:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a76:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a7a:	00008717          	auipc	a4,0x8
    80000a7e:	01e70713          	addi	a4,a4,30 # 80008a98 <FREE_PAGES>
    80000a82:	631c                	ld	a5,0(a4)
    80000a84:	0785                	addi	a5,a5,1
    80000a86:	e31c                	sd	a5,0(a4)
    // if (MAX_PAGES != 0)
    //     assert(FREE_PAGES <= MAX_PAGES);
    release(&kmem.lock);
    80000a88:	854a                	mv	a0,s2
    80000a8a:	00000097          	auipc	ra,0x0
    80000a8e:	2f0080e7          	jalr	752(ra) # 80000d7a <release>
    parefs[PTE2PPN(PA2PTE(pa))] = 0;
    80000a92:	00010797          	auipc	a5,0x10
    80000a96:	29e78793          	addi	a5,a5,670 # 80010d30 <parefs>
    80000a9a:	97ce                	add	a5,a5,s3
    80000a9c:	00078023          	sb	zero,0(a5)
}
    80000aa0:	70a2                	ld	ra,40(sp)
    80000aa2:	7402                	ld	s0,32(sp)
    80000aa4:	64e2                	ld	s1,24(sp)
    80000aa6:	6942                	ld	s2,16(sp)
    80000aa8:	69a2                	ld	s3,8(sp)
    80000aaa:	6145                	addi	sp,sp,48
    80000aac:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000aae:	03c00693          	li	a3,60
    80000ab2:	00007617          	auipc	a2,0x7
    80000ab6:	55660613          	addi	a2,a2,1366 # 80008008 <__func__.1>
    80000aba:	00007597          	auipc	a1,0x7
    80000abe:	5b658593          	addi	a1,a1,1462 # 80008070 <digits+0x20>
    80000ac2:	00007517          	auipc	a0,0x7
    80000ac6:	5be50513          	addi	a0,a0,1470 # 80008080 <digits+0x30>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	ace080e7          	jalr	-1330(ra) # 80000598 <printf>
    80000ad2:	00007517          	auipc	a0,0x7
    80000ad6:	5be50513          	addi	a0,a0,1470 # 80008090 <digits+0x40>
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	a62080e7          	jalr	-1438(ra) # 8000053c <panic>
        panic("kfree");
    80000ae2:	00007517          	auipc	a0,0x7
    80000ae6:	5be50513          	addi	a0,a0,1470 # 800080a0 <digits+0x50>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	a52080e7          	jalr	-1454(ra) # 8000053c <panic>

0000000080000af2 <freerange>:
{
    80000af2:	7179                	addi	sp,sp,-48
    80000af4:	f406                	sd	ra,40(sp)
    80000af6:	f022                	sd	s0,32(sp)
    80000af8:	ec26                	sd	s1,24(sp)
    80000afa:	e84a                	sd	s2,16(sp)
    80000afc:	e44e                	sd	s3,8(sp)
    80000afe:	e052                	sd	s4,0(sp)
    80000b00:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000b02:	6785                	lui	a5,0x1
    80000b04:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b08:	00e504b3          	add	s1,a0,a4
    80000b0c:	777d                	lui	a4,0xfffff
    80000b0e:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b10:	94be                	add	s1,s1,a5
    80000b12:	0095ee63          	bltu	a1,s1,80000b2e <freerange+0x3c>
    80000b16:	892e                	mv	s2,a1
        kfree(p);
    80000b18:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b1a:	6985                	lui	s3,0x1
        kfree(p);
    80000b1c:	01448533          	add	a0,s1,s4
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	ed6080e7          	jalr	-298(ra) # 800009f6 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b28:	94ce                	add	s1,s1,s3
    80000b2a:	fe9979e3          	bgeu	s2,s1,80000b1c <freerange+0x2a>
}
    80000b2e:	70a2                	ld	ra,40(sp)
    80000b30:	7402                	ld	s0,32(sp)
    80000b32:	64e2                	ld	s1,24(sp)
    80000b34:	6942                	ld	s2,16(sp)
    80000b36:	69a2                	ld	s3,8(sp)
    80000b38:	6a02                	ld	s4,0(sp)
    80000b3a:	6145                	addi	sp,sp,48
    80000b3c:	8082                	ret

0000000080000b3e <kinit>:
{
    80000b3e:	1141                	addi	sp,sp,-16
    80000b40:	e406                	sd	ra,8(sp)
    80000b42:	e022                	sd	s0,0(sp)
    80000b44:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b46:	00007597          	auipc	a1,0x7
    80000b4a:	56258593          	addi	a1,a1,1378 # 800080a8 <digits+0x58>
    80000b4e:	00010517          	auipc	a0,0x10
    80000b52:	1c250513          	addi	a0,a0,450 # 80010d10 <kmem>
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	0e0080e7          	jalr	224(ra) # 80000c36 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b5e:	45c5                	li	a1,17
    80000b60:	05ee                	slli	a1,a1,0x1b
    80000b62:	00029517          	auipc	a0,0x29
    80000b66:	3de50513          	addi	a0,a0,990 # 80029f40 <end>
    80000b6a:	00000097          	auipc	ra,0x0
    80000b6e:	f88080e7          	jalr	-120(ra) # 80000af2 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b72:	00008797          	auipc	a5,0x8
    80000b76:	f267b783          	ld	a5,-218(a5) # 80008a98 <FREE_PAGES>
    80000b7a:	00008717          	auipc	a4,0x8
    80000b7e:	f2f73323          	sd	a5,-218(a4) # 80008aa0 <MAX_PAGES>
}
    80000b82:	60a2                	ld	ra,8(sp)
    80000b84:	6402                	ld	s0,0(sp)
    80000b86:	0141                	addi	sp,sp,16
    80000b88:	8082                	ret

0000000080000b8a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b94:	00008797          	auipc	a5,0x8
    80000b98:	f047b783          	ld	a5,-252(a5) # 80008a98 <FREE_PAGES>
    80000b9c:	cbb1                	beqz	a5,80000bf0 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b9e:	00010497          	auipc	s1,0x10
    80000ba2:	17248493          	addi	s1,s1,370 # 80010d10 <kmem>
    80000ba6:	8526                	mv	a0,s1
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	11e080e7          	jalr	286(ra) # 80000cc6 <acquire>
    r = kmem.freelist;
    80000bb0:	6c84                	ld	s1,24(s1)
    if (r)
    80000bb2:	c8ad                	beqz	s1,80000c24 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000bb4:	609c                	ld	a5,0(s1)
    80000bb6:	00010517          	auipc	a0,0x10
    80000bba:	15a50513          	addi	a0,a0,346 # 80010d10 <kmem>
    80000bbe:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	1ba080e7          	jalr	442(ra) # 80000d7a <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000bc8:	6605                	lui	a2,0x1
    80000bca:	4595                	li	a1,5
    80000bcc:	8526                	mv	a0,s1
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1f4080e7          	jalr	500(ra) # 80000dc2 <memset>
    FREE_PAGES--;
    80000bd6:	00008717          	auipc	a4,0x8
    80000bda:	ec270713          	addi	a4,a4,-318 # 80008a98 <FREE_PAGES>
    80000bde:	631c                	ld	a5,0(a4)
    80000be0:	17fd                	addi	a5,a5,-1
    80000be2:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000be4:	8526                	mv	a0,s1
    80000be6:	60e2                	ld	ra,24(sp)
    80000be8:	6442                	ld	s0,16(sp)
    80000bea:	64a2                	ld	s1,8(sp)
    80000bec:	6105                	addi	sp,sp,32
    80000bee:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bf0:	05700693          	li	a3,87
    80000bf4:	00007617          	auipc	a2,0x7
    80000bf8:	40c60613          	addi	a2,a2,1036 # 80008000 <etext>
    80000bfc:	00007597          	auipc	a1,0x7
    80000c00:	47458593          	addi	a1,a1,1140 # 80008070 <digits+0x20>
    80000c04:	00007517          	auipc	a0,0x7
    80000c08:	47c50513          	addi	a0,a0,1148 # 80008080 <digits+0x30>
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	98c080e7          	jalr	-1652(ra) # 80000598 <printf>
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	47c50513          	addi	a0,a0,1148 # 80008090 <digits+0x40>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	920080e7          	jalr	-1760(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000c24:	00010517          	auipc	a0,0x10
    80000c28:	0ec50513          	addi	a0,a0,236 # 80010d10 <kmem>
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	14e080e7          	jalr	334(ra) # 80000d7a <release>
    if (r)
    80000c34:	b74d                	j	80000bd6 <kalloc+0x4c>

0000000080000c36 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c36:	1141                	addi	sp,sp,-16
    80000c38:	e422                	sd	s0,8(sp)
    80000c3a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c3c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c3e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c42:	00053823          	sd	zero,16(a0)
}
    80000c46:	6422                	ld	s0,8(sp)
    80000c48:	0141                	addi	sp,sp,16
    80000c4a:	8082                	ret

0000000080000c4c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c4c:	411c                	lw	a5,0(a0)
    80000c4e:	e399                	bnez	a5,80000c54 <holding+0x8>
    80000c50:	4501                	li	a0,0
  return r;
}
    80000c52:	8082                	ret
{
    80000c54:	1101                	addi	sp,sp,-32
    80000c56:	ec06                	sd	ra,24(sp)
    80000c58:	e822                	sd	s0,16(sp)
    80000c5a:	e426                	sd	s1,8(sp)
    80000c5c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c5e:	6904                	ld	s1,16(a0)
    80000c60:	00001097          	auipc	ra,0x1
    80000c64:	f3a080e7          	jalr	-198(ra) # 80001b9a <mycpu>
    80000c68:	40a48533          	sub	a0,s1,a0
    80000c6c:	00153513          	seqz	a0,a0
}
    80000c70:	60e2                	ld	ra,24(sp)
    80000c72:	6442                	ld	s0,16(sp)
    80000c74:	64a2                	ld	s1,8(sp)
    80000c76:	6105                	addi	sp,sp,32
    80000c78:	8082                	ret

0000000080000c7a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c7a:	1101                	addi	sp,sp,-32
    80000c7c:	ec06                	sd	ra,24(sp)
    80000c7e:	e822                	sd	s0,16(sp)
    80000c80:	e426                	sd	s1,8(sp)
    80000c82:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c84:	100024f3          	csrr	s1,sstatus
    80000c88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c8e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	f08080e7          	jalr	-248(ra) # 80001b9a <mycpu>
    80000c9a:	5d3c                	lw	a5,120(a0)
    80000c9c:	cf89                	beqz	a5,80000cb6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c9e:	00001097          	auipc	ra,0x1
    80000ca2:	efc080e7          	jalr	-260(ra) # 80001b9a <mycpu>
    80000ca6:	5d3c                	lw	a5,120(a0)
    80000ca8:	2785                	addiw	a5,a5,1
    80000caa:	dd3c                	sw	a5,120(a0)
}
    80000cac:	60e2                	ld	ra,24(sp)
    80000cae:	6442                	ld	s0,16(sp)
    80000cb0:	64a2                	ld	s1,8(sp)
    80000cb2:	6105                	addi	sp,sp,32
    80000cb4:	8082                	ret
    mycpu()->intena = old;
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	ee4080e7          	jalr	-284(ra) # 80001b9a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cbe:	8085                	srli	s1,s1,0x1
    80000cc0:	8885                	andi	s1,s1,1
    80000cc2:	dd64                	sw	s1,124(a0)
    80000cc4:	bfe9                	j	80000c9e <push_off+0x24>

0000000080000cc6 <acquire>:
{
    80000cc6:	1101                	addi	sp,sp,-32
    80000cc8:	ec06                	sd	ra,24(sp)
    80000cca:	e822                	sd	s0,16(sp)
    80000ccc:	e426                	sd	s1,8(sp)
    80000cce:	1000                	addi	s0,sp,32
    80000cd0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	fa8080e7          	jalr	-88(ra) # 80000c7a <push_off>
  if(holding(lk))
    80000cda:	8526                	mv	a0,s1
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	f70080e7          	jalr	-144(ra) # 80000c4c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ce4:	4705                	li	a4,1
  if(holding(lk))
    80000ce6:	e115                	bnez	a0,80000d0a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ce8:	87ba                	mv	a5,a4
    80000cea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cee:	2781                	sext.w	a5,a5
    80000cf0:	ffe5                	bnez	a5,80000ce8 <acquire+0x22>
  __sync_synchronize();
    80000cf2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	ea4080e7          	jalr	-348(ra) # 80001b9a <mycpu>
    80000cfe:	e888                	sd	a0,16(s1)
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    panic("acquire");
    80000d0a:	00007517          	auipc	a0,0x7
    80000d0e:	3a650513          	addi	a0,a0,934 # 800080b0 <digits+0x60>
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	82a080e7          	jalr	-2006(ra) # 8000053c <panic>

0000000080000d1a <pop_off>:

void
pop_off(void)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e406                	sd	ra,8(sp)
    80000d1e:	e022                	sd	s0,0(sp)
    80000d20:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d22:	00001097          	auipc	ra,0x1
    80000d26:	e78080e7          	jalr	-392(ra) # 80001b9a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d2a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d2e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d30:	e78d                	bnez	a5,80000d5a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d32:	5d3c                	lw	a5,120(a0)
    80000d34:	02f05b63          	blez	a5,80000d6a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d38:	37fd                	addiw	a5,a5,-1
    80000d3a:	0007871b          	sext.w	a4,a5
    80000d3e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d40:	eb09                	bnez	a4,80000d52 <pop_off+0x38>
    80000d42:	5d7c                	lw	a5,124(a0)
    80000d44:	c799                	beqz	a5,80000d52 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d4a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d4e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d52:	60a2                	ld	ra,8(sp)
    80000d54:	6402                	ld	s0,0(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
    panic("pop_off - interruptible");
    80000d5a:	00007517          	auipc	a0,0x7
    80000d5e:	35e50513          	addi	a0,a0,862 # 800080b8 <digits+0x68>
    80000d62:	fffff097          	auipc	ra,0xfffff
    80000d66:	7da080e7          	jalr	2010(ra) # 8000053c <panic>
    panic("pop_off");
    80000d6a:	00007517          	auipc	a0,0x7
    80000d6e:	36650513          	addi	a0,a0,870 # 800080d0 <digits+0x80>
    80000d72:	fffff097          	auipc	ra,0xfffff
    80000d76:	7ca080e7          	jalr	1994(ra) # 8000053c <panic>

0000000080000d7a <release>:
{
    80000d7a:	1101                	addi	sp,sp,-32
    80000d7c:	ec06                	sd	ra,24(sp)
    80000d7e:	e822                	sd	s0,16(sp)
    80000d80:	e426                	sd	s1,8(sp)
    80000d82:	1000                	addi	s0,sp,32
    80000d84:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	ec6080e7          	jalr	-314(ra) # 80000c4c <holding>
    80000d8e:	c115                	beqz	a0,80000db2 <release+0x38>
  lk->cpu = 0;
    80000d90:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d94:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d98:	0f50000f          	fence	iorw,ow
    80000d9c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000da0:	00000097          	auipc	ra,0x0
    80000da4:	f7a080e7          	jalr	-134(ra) # 80000d1a <pop_off>
}
    80000da8:	60e2                	ld	ra,24(sp)
    80000daa:	6442                	ld	s0,16(sp)
    80000dac:	64a2                	ld	s1,8(sp)
    80000dae:	6105                	addi	sp,sp,32
    80000db0:	8082                	ret
    panic("release");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	32650513          	addi	a0,a0,806 # 800080d8 <digits+0x88>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	782080e7          	jalr	1922(ra) # 8000053c <panic>

0000000080000dc2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dc2:	1141                	addi	sp,sp,-16
    80000dc4:	e422                	sd	s0,8(sp)
    80000dc6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dc8:	ca19                	beqz	a2,80000dde <memset+0x1c>
    80000dca:	87aa                	mv	a5,a0
    80000dcc:	1602                	slli	a2,a2,0x20
    80000dce:	9201                	srli	a2,a2,0x20
    80000dd0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000dd4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dd8:	0785                	addi	a5,a5,1
    80000dda:	fee79de3          	bne	a5,a4,80000dd4 <memset+0x12>
  }
  return dst;
}
    80000dde:	6422                	ld	s0,8(sp)
    80000de0:	0141                	addi	sp,sp,16
    80000de2:	8082                	ret

0000000080000de4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000de4:	1141                	addi	sp,sp,-16
    80000de6:	e422                	sd	s0,8(sp)
    80000de8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dea:	ca05                	beqz	a2,80000e1a <memcmp+0x36>
    80000dec:	fff6069b          	addiw	a3,a2,-1
    80000df0:	1682                	slli	a3,a3,0x20
    80000df2:	9281                	srli	a3,a3,0x20
    80000df4:	0685                	addi	a3,a3,1
    80000df6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000df8:	00054783          	lbu	a5,0(a0)
    80000dfc:	0005c703          	lbu	a4,0(a1)
    80000e00:	00e79863          	bne	a5,a4,80000e10 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e04:	0505                	addi	a0,a0,1
    80000e06:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e08:	fed518e3          	bne	a0,a3,80000df8 <memcmp+0x14>
  }

  return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	a019                	j	80000e14 <memcmp+0x30>
      return *s1 - *s2;
    80000e10:	40e7853b          	subw	a0,a5,a4
}
    80000e14:	6422                	ld	s0,8(sp)
    80000e16:	0141                	addi	sp,sp,16
    80000e18:	8082                	ret
  return 0;
    80000e1a:	4501                	li	a0,0
    80000e1c:	bfe5                	j	80000e14 <memcmp+0x30>

0000000080000e1e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e1e:	1141                	addi	sp,sp,-16
    80000e20:	e422                	sd	s0,8(sp)
    80000e22:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e24:	c205                	beqz	a2,80000e44 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e26:	02a5e263          	bltu	a1,a0,80000e4a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e2a:	1602                	slli	a2,a2,0x20
    80000e2c:	9201                	srli	a2,a2,0x20
    80000e2e:	00c587b3          	add	a5,a1,a2
{
    80000e32:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e34:	0585                	addi	a1,a1,1
    80000e36:	0705                	addi	a4,a4,1
    80000e38:	fff5c683          	lbu	a3,-1(a1)
    80000e3c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e40:	fef59ae3          	bne	a1,a5,80000e34 <memmove+0x16>

  return dst;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret
  if(s < d && s + n > d){
    80000e4a:	02061693          	slli	a3,a2,0x20
    80000e4e:	9281                	srli	a3,a3,0x20
    80000e50:	00d58733          	add	a4,a1,a3
    80000e54:	fce57be3          	bgeu	a0,a4,80000e2a <memmove+0xc>
    d += n;
    80000e58:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e5a:	fff6079b          	addiw	a5,a2,-1
    80000e5e:	1782                	slli	a5,a5,0x20
    80000e60:	9381                	srli	a5,a5,0x20
    80000e62:	fff7c793          	not	a5,a5
    80000e66:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e68:	177d                	addi	a4,a4,-1
    80000e6a:	16fd                	addi	a3,a3,-1
    80000e6c:	00074603          	lbu	a2,0(a4)
    80000e70:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e74:	fee79ae3          	bne	a5,a4,80000e68 <memmove+0x4a>
    80000e78:	b7f1                	j	80000e44 <memmove+0x26>

0000000080000e7a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e406                	sd	ra,8(sp)
    80000e7e:	e022                	sd	s0,0(sp)
    80000e80:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e82:	00000097          	auipc	ra,0x0
    80000e86:	f9c080e7          	jalr	-100(ra) # 80000e1e <memmove>
}
    80000e8a:	60a2                	ld	ra,8(sp)
    80000e8c:	6402                	ld	s0,0(sp)
    80000e8e:	0141                	addi	sp,sp,16
    80000e90:	8082                	ret

0000000080000e92 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e92:	1141                	addi	sp,sp,-16
    80000e94:	e422                	sd	s0,8(sp)
    80000e96:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e98:	ce11                	beqz	a2,80000eb4 <strncmp+0x22>
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf89                	beqz	a5,80000eb8 <strncmp+0x26>
    80000ea0:	0005c703          	lbu	a4,0(a1)
    80000ea4:	00f71a63          	bne	a4,a5,80000eb8 <strncmp+0x26>
    n--, p++, q++;
    80000ea8:	367d                	addiw	a2,a2,-1
    80000eaa:	0505                	addi	a0,a0,1
    80000eac:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eae:	f675                	bnez	a2,80000e9a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000eb0:	4501                	li	a0,0
    80000eb2:	a809                	j	80000ec4 <strncmp+0x32>
    80000eb4:	4501                	li	a0,0
    80000eb6:	a039                	j	80000ec4 <strncmp+0x32>
  if(n == 0)
    80000eb8:	ca09                	beqz	a2,80000eca <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eba:	00054503          	lbu	a0,0(a0)
    80000ebe:	0005c783          	lbu	a5,0(a1)
    80000ec2:	9d1d                	subw	a0,a0,a5
}
    80000ec4:	6422                	ld	s0,8(sp)
    80000ec6:	0141                	addi	sp,sp,16
    80000ec8:	8082                	ret
    return 0;
    80000eca:	4501                	li	a0,0
    80000ecc:	bfe5                	j	80000ec4 <strncmp+0x32>

0000000080000ece <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e422                	sd	s0,8(sp)
    80000ed2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ed4:	87aa                	mv	a5,a0
    80000ed6:	86b2                	mv	a3,a2
    80000ed8:	367d                	addiw	a2,a2,-1
    80000eda:	00d05963          	blez	a3,80000eec <strncpy+0x1e>
    80000ede:	0785                	addi	a5,a5,1
    80000ee0:	0005c703          	lbu	a4,0(a1)
    80000ee4:	fee78fa3          	sb	a4,-1(a5)
    80000ee8:	0585                	addi	a1,a1,1
    80000eea:	f775                	bnez	a4,80000ed6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eec:	873e                	mv	a4,a5
    80000eee:	9fb5                	addw	a5,a5,a3
    80000ef0:	37fd                	addiw	a5,a5,-1
    80000ef2:	00c05963          	blez	a2,80000f04 <strncpy+0x36>
    *s++ = 0;
    80000ef6:	0705                	addi	a4,a4,1
    80000ef8:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000efc:	40e786bb          	subw	a3,a5,a4
    80000f00:	fed04be3          	bgtz	a3,80000ef6 <strncpy+0x28>
  return os;
}
    80000f04:	6422                	ld	s0,8(sp)
    80000f06:	0141                	addi	sp,sp,16
    80000f08:	8082                	ret

0000000080000f0a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f0a:	1141                	addi	sp,sp,-16
    80000f0c:	e422                	sd	s0,8(sp)
    80000f0e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f10:	02c05363          	blez	a2,80000f36 <safestrcpy+0x2c>
    80000f14:	fff6069b          	addiw	a3,a2,-1
    80000f18:	1682                	slli	a3,a3,0x20
    80000f1a:	9281                	srli	a3,a3,0x20
    80000f1c:	96ae                	add	a3,a3,a1
    80000f1e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f20:	00d58963          	beq	a1,a3,80000f32 <safestrcpy+0x28>
    80000f24:	0585                	addi	a1,a1,1
    80000f26:	0785                	addi	a5,a5,1
    80000f28:	fff5c703          	lbu	a4,-1(a1)
    80000f2c:	fee78fa3          	sb	a4,-1(a5)
    80000f30:	fb65                	bnez	a4,80000f20 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f32:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f36:	6422                	ld	s0,8(sp)
    80000f38:	0141                	addi	sp,sp,16
    80000f3a:	8082                	ret

0000000080000f3c <strlen>:

int
strlen(const char *s)
{
    80000f3c:	1141                	addi	sp,sp,-16
    80000f3e:	e422                	sd	s0,8(sp)
    80000f40:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f42:	00054783          	lbu	a5,0(a0)
    80000f46:	cf91                	beqz	a5,80000f62 <strlen+0x26>
    80000f48:	0505                	addi	a0,a0,1
    80000f4a:	87aa                	mv	a5,a0
    80000f4c:	86be                	mv	a3,a5
    80000f4e:	0785                	addi	a5,a5,1
    80000f50:	fff7c703          	lbu	a4,-1(a5)
    80000f54:	ff65                	bnez	a4,80000f4c <strlen+0x10>
    80000f56:	40a6853b          	subw	a0,a3,a0
    80000f5a:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f5c:	6422                	ld	s0,8(sp)
    80000f5e:	0141                	addi	sp,sp,16
    80000f60:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f62:	4501                	li	a0,0
    80000f64:	bfe5                	j	80000f5c <strlen+0x20>

0000000080000f66 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e406                	sd	ra,8(sp)
    80000f6a:	e022                	sd	s0,0(sp)
    80000f6c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	c1c080e7          	jalr	-996(ra) # 80001b8a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f76:	00008717          	auipc	a4,0x8
    80000f7a:	b3270713          	addi	a4,a4,-1230 # 80008aa8 <started>
  if(cpuid() == 0){
    80000f7e:	c139                	beqz	a0,80000fc4 <main+0x5e>
    while(started == 0)
    80000f80:	431c                	lw	a5,0(a4)
    80000f82:	2781                	sext.w	a5,a5
    80000f84:	dff5                	beqz	a5,80000f80 <main+0x1a>
      ;
    __sync_synchronize();
    80000f86:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	c00080e7          	jalr	-1024(ra) # 80001b8a <cpuid>
    80000f92:	85aa                	mv	a1,a0
    80000f94:	00007517          	auipc	a0,0x7
    80000f98:	16450513          	addi	a0,a0,356 # 800080f8 <digits+0xa8>
    80000f9c:	fffff097          	auipc	ra,0xfffff
    80000fa0:	5fc080e7          	jalr	1532(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000fa4:	00000097          	auipc	ra,0x0
    80000fa8:	0d8080e7          	jalr	216(ra) # 8000107c <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	ab2080e7          	jalr	-1358(ra) # 80002a5e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	20c080e7          	jalr	524(ra) # 800061c0 <plicinithart>
  }

  scheduler();        
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	240080e7          	jalr	576(ra) # 800021fc <scheduler>
    consoleinit();
    80000fc4:	fffff097          	auipc	ra,0xfffff
    80000fc8:	488080e7          	jalr	1160(ra) # 8000044c <consoleinit>
    printfinit();
    80000fcc:	fffff097          	auipc	ra,0xfffff
    80000fd0:	7ac080e7          	jalr	1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000fd4:	00007517          	auipc	a0,0x7
    80000fd8:	0b450513          	addi	a0,a0,180 # 80008088 <digits+0x38>
    80000fdc:	fffff097          	auipc	ra,0xfffff
    80000fe0:	5bc080e7          	jalr	1468(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0fc50513          	addi	a0,a0,252 # 800080e0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	5ac080e7          	jalr	1452(ra) # 80000598 <printf>
    printf("\n");
    80000ff4:	00007517          	auipc	a0,0x7
    80000ff8:	09450513          	addi	a0,a0,148 # 80008088 <digits+0x38>
    80000ffc:	fffff097          	auipc	ra,0xfffff
    80001000:	59c080e7          	jalr	1436(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80001004:	00000097          	auipc	ra,0x0
    80001008:	b3a080e7          	jalr	-1222(ra) # 80000b3e <kinit>
    kvminit();       // create kernel page table
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	326080e7          	jalr	806(ra) # 80001332 <kvminit>
    kvminithart();   // turn on paging
    80001014:	00000097          	auipc	ra,0x0
    80001018:	068080e7          	jalr	104(ra) # 8000107c <kvminithart>
    procinit();      // process table
    8000101c:	00001097          	auipc	ra,0x1
    80001020:	a96080e7          	jalr	-1386(ra) # 80001ab2 <procinit>
    trapinit();      // trap vectors
    80001024:	00002097          	auipc	ra,0x2
    80001028:	a12080e7          	jalr	-1518(ra) # 80002a36 <trapinit>
    trapinithart();  // install kernel trap vector
    8000102c:	00002097          	auipc	ra,0x2
    80001030:	a32080e7          	jalr	-1486(ra) # 80002a5e <trapinithart>
    plicinit();      // set up interrupt controller
    80001034:	00005097          	auipc	ra,0x5
    80001038:	176080e7          	jalr	374(ra) # 800061aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000103c:	00005097          	auipc	ra,0x5
    80001040:	184080e7          	jalr	388(ra) # 800061c0 <plicinithart>
    binit();         // buffer cache
    80001044:	00002097          	auipc	ra,0x2
    80001048:	37e080e7          	jalr	894(ra) # 800033c2 <binit>
    iinit();         // inode table
    8000104c:	00003097          	auipc	ra,0x3
    80001050:	a1c080e7          	jalr	-1508(ra) # 80003a68 <iinit>
    fileinit();      // file table
    80001054:	00004097          	auipc	ra,0x4
    80001058:	992080e7          	jalr	-1646(ra) # 800049e6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000105c:	00005097          	auipc	ra,0x5
    80001060:	26c080e7          	jalr	620(ra) # 800062c8 <virtio_disk_init>
    userinit();      // first user process
    80001064:	00001097          	auipc	ra,0x1
    80001068:	e2a080e7          	jalr	-470(ra) # 80001e8e <userinit>
    __sync_synchronize();
    8000106c:	0ff0000f          	fence
    started = 1;
    80001070:	4785                	li	a5,1
    80001072:	00008717          	auipc	a4,0x8
    80001076:	a2f72b23          	sw	a5,-1482(a4) # 80008aa8 <started>
    8000107a:	b789                	j	80000fbc <main+0x56>

000000008000107c <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000107c:	1141                	addi	sp,sp,-16
    8000107e:	e422                	sd	s0,8(sp)
    80001080:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001082:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001086:	00008797          	auipc	a5,0x8
    8000108a:	a2a7b783          	ld	a5,-1494(a5) # 80008ab0 <kernel_pagetable>
    8000108e:	83b1                	srli	a5,a5,0xc
    80001090:	577d                	li	a4,-1
    80001092:	177e                	slli	a4,a4,0x3f
    80001094:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001096:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000109a:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000109e:	6422                	ld	s0,8(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret

00000000800010a4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010a4:	7139                	addi	sp,sp,-64
    800010a6:	fc06                	sd	ra,56(sp)
    800010a8:	f822                	sd	s0,48(sp)
    800010aa:	f426                	sd	s1,40(sp)
    800010ac:	f04a                	sd	s2,32(sp)
    800010ae:	ec4e                	sd	s3,24(sp)
    800010b0:	e852                	sd	s4,16(sp)
    800010b2:	e456                	sd	s5,8(sp)
    800010b4:	e05a                	sd	s6,0(sp)
    800010b6:	0080                	addi	s0,sp,64
    800010b8:	84aa                	mv	s1,a0
    800010ba:	89ae                	mv	s3,a1
    800010bc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010be:	57fd                	li	a5,-1
    800010c0:	83e9                	srli	a5,a5,0x1a
    800010c2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010c4:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010c6:	04b7f263          	bgeu	a5,a1,8000110a <walk+0x66>
    panic("walk");
    800010ca:	00007517          	auipc	a0,0x7
    800010ce:	04650513          	addi	a0,a0,70 # 80008110 <digits+0xc0>
    800010d2:	fffff097          	auipc	ra,0xfffff
    800010d6:	46a080e7          	jalr	1130(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010da:	060a8663          	beqz	s5,80001146 <walk+0xa2>
    800010de:	00000097          	auipc	ra,0x0
    800010e2:	aac080e7          	jalr	-1364(ra) # 80000b8a <kalloc>
    800010e6:	84aa                	mv	s1,a0
    800010e8:	c529                	beqz	a0,80001132 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010ea:	6605                	lui	a2,0x1
    800010ec:	4581                	li	a1,0
    800010ee:	00000097          	auipc	ra,0x0
    800010f2:	cd4080e7          	jalr	-812(ra) # 80000dc2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010f6:	00c4d793          	srli	a5,s1,0xc
    800010fa:	07aa                	slli	a5,a5,0xa
    800010fc:	0017e793          	ori	a5,a5,1
    80001100:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001104:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd50b7>
    80001106:	036a0063          	beq	s4,s6,80001126 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000110a:	0149d933          	srl	s2,s3,s4
    8000110e:	1ff97913          	andi	s2,s2,511
    80001112:	090e                	slli	s2,s2,0x3
    80001114:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001116:	00093483          	ld	s1,0(s2)
    8000111a:	0014f793          	andi	a5,s1,1
    8000111e:	dfd5                	beqz	a5,800010da <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001120:	80a9                	srli	s1,s1,0xa
    80001122:	04b2                	slli	s1,s1,0xc
    80001124:	b7c5                	j	80001104 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001126:	00c9d513          	srli	a0,s3,0xc
    8000112a:	1ff57513          	andi	a0,a0,511
    8000112e:	050e                	slli	a0,a0,0x3
    80001130:	9526                	add	a0,a0,s1
}
    80001132:	70e2                	ld	ra,56(sp)
    80001134:	7442                	ld	s0,48(sp)
    80001136:	74a2                	ld	s1,40(sp)
    80001138:	7902                	ld	s2,32(sp)
    8000113a:	69e2                	ld	s3,24(sp)
    8000113c:	6a42                	ld	s4,16(sp)
    8000113e:	6aa2                	ld	s5,8(sp)
    80001140:	6b02                	ld	s6,0(sp)
    80001142:	6121                	addi	sp,sp,64
    80001144:	8082                	ret
        return 0;
    80001146:	4501                	li	a0,0
    80001148:	b7ed                	j	80001132 <walk+0x8e>

000000008000114a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000114a:	57fd                	li	a5,-1
    8000114c:	83e9                	srli	a5,a5,0x1a
    8000114e:	00b7f463          	bgeu	a5,a1,80001156 <walkaddr+0xc>
    return 0;
    80001152:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001154:	8082                	ret
{
    80001156:	1141                	addi	sp,sp,-16
    80001158:	e406                	sd	ra,8(sp)
    8000115a:	e022                	sd	s0,0(sp)
    8000115c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000115e:	4601                	li	a2,0
    80001160:	00000097          	auipc	ra,0x0
    80001164:	f44080e7          	jalr	-188(ra) # 800010a4 <walk>
  if(pte == 0)
    80001168:	c105                	beqz	a0,80001188 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000116a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000116c:	0117f693          	andi	a3,a5,17
    80001170:	4745                	li	a4,17
    return 0;
    80001172:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001174:	00e68663          	beq	a3,a4,80001180 <walkaddr+0x36>
}
    80001178:	60a2                	ld	ra,8(sp)
    8000117a:	6402                	ld	s0,0(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret
  pa = PTE2PA(*pte);
    80001180:	83a9                	srli	a5,a5,0xa
    80001182:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001186:	bfcd                	j	80001178 <walkaddr+0x2e>
    return 0;
    80001188:	4501                	li	a0,0
    8000118a:	b7fd                	j	80001178 <walkaddr+0x2e>

000000008000118c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000118c:	715d                	addi	sp,sp,-80
    8000118e:	e486                	sd	ra,72(sp)
    80001190:	e0a2                	sd	s0,64(sp)
    80001192:	fc26                	sd	s1,56(sp)
    80001194:	f84a                	sd	s2,48(sp)
    80001196:	f44e                	sd	s3,40(sp)
    80001198:	f052                	sd	s4,32(sp)
    8000119a:	ec56                	sd	s5,24(sp)
    8000119c:	e85a                	sd	s6,16(sp)
    8000119e:	e45e                	sd	s7,8(sp)
    800011a0:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011a2:	c639                	beqz	a2,800011f0 <mappages+0x64>
    800011a4:	8aaa                	mv	s5,a0
    800011a6:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011a8:	777d                	lui	a4,0xfffff
    800011aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ae:	fff58993          	addi	s3,a1,-1
    800011b2:	99b2                	add	s3,s3,a2
    800011b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b8:	893e                	mv	s2,a5
    800011ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011be:	6b85                	lui	s7,0x1
    800011c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c4:	4605                	li	a2,1
    800011c6:	85ca                	mv	a1,s2
    800011c8:	8556                	mv	a0,s5
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	eda080e7          	jalr	-294(ra) # 800010a4 <walk>
    800011d2:	cd1d                	beqz	a0,80001210 <mappages+0x84>
    if(*pte & PTE_V)
    800011d4:	611c                	ld	a5,0(a0)
    800011d6:	8b85                	andi	a5,a5,1
    800011d8:	e785                	bnez	a5,80001200 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011da:	80b1                	srli	s1,s1,0xc
    800011dc:	04aa                	slli	s1,s1,0xa
    800011de:	0164e4b3          	or	s1,s1,s6
    800011e2:	0014e493          	ori	s1,s1,1
    800011e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e8:	05390063          	beq	s2,s3,80001228 <mappages+0x9c>
    a += PGSIZE;
    800011ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ee:	bfc9                	j	800011c0 <mappages+0x34>
    panic("mappages: size");
    800011f0:	00007517          	auipc	a0,0x7
    800011f4:	f2850513          	addi	a0,a0,-216 # 80008118 <digits+0xc8>
    800011f8:	fffff097          	auipc	ra,0xfffff
    800011fc:	344080e7          	jalr	836(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001200:	00007517          	auipc	a0,0x7
    80001204:	f2850513          	addi	a0,a0,-216 # 80008128 <digits+0xd8>
    80001208:	fffff097          	auipc	ra,0xfffff
    8000120c:	334080e7          	jalr	820(ra) # 8000053c <panic>
      return -1;
    80001210:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001212:	60a6                	ld	ra,72(sp)
    80001214:	6406                	ld	s0,64(sp)
    80001216:	74e2                	ld	s1,56(sp)
    80001218:	7942                	ld	s2,48(sp)
    8000121a:	79a2                	ld	s3,40(sp)
    8000121c:	7a02                	ld	s4,32(sp)
    8000121e:	6ae2                	ld	s5,24(sp)
    80001220:	6b42                	ld	s6,16(sp)
    80001222:	6ba2                	ld	s7,8(sp)
    80001224:	6161                	addi	sp,sp,80
    80001226:	8082                	ret
  return 0;
    80001228:	4501                	li	a0,0
    8000122a:	b7e5                	j	80001212 <mappages+0x86>

000000008000122c <kvmmap>:
{
    8000122c:	1141                	addi	sp,sp,-16
    8000122e:	e406                	sd	ra,8(sp)
    80001230:	e022                	sd	s0,0(sp)
    80001232:	0800                	addi	s0,sp,16
    80001234:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001236:	86b2                	mv	a3,a2
    80001238:	863e                	mv	a2,a5
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f52080e7          	jalr	-174(ra) # 8000118c <mappages>
    80001242:	e509                	bnez	a0,8000124c <kvmmap+0x20>
}
    80001244:	60a2                	ld	ra,8(sp)
    80001246:	6402                	ld	s0,0(sp)
    80001248:	0141                	addi	sp,sp,16
    8000124a:	8082                	ret
    panic("kvmmap");
    8000124c:	00007517          	auipc	a0,0x7
    80001250:	eec50513          	addi	a0,a0,-276 # 80008138 <digits+0xe8>
    80001254:	fffff097          	auipc	ra,0xfffff
    80001258:	2e8080e7          	jalr	744(ra) # 8000053c <panic>

000000008000125c <kvmmake>:
{
    8000125c:	1101                	addi	sp,sp,-32
    8000125e:	ec06                	sd	ra,24(sp)
    80001260:	e822                	sd	s0,16(sp)
    80001262:	e426                	sd	s1,8(sp)
    80001264:	e04a                	sd	s2,0(sp)
    80001266:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	922080e7          	jalr	-1758(ra) # 80000b8a <kalloc>
    80001270:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001272:	6605                	lui	a2,0x1
    80001274:	4581                	li	a1,0
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	b4c080e7          	jalr	-1204(ra) # 80000dc2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000127e:	4719                	li	a4,6
    80001280:	6685                	lui	a3,0x1
    80001282:	10000637          	lui	a2,0x10000
    80001286:	100005b7          	lui	a1,0x10000
    8000128a:	8526                	mv	a0,s1
    8000128c:	00000097          	auipc	ra,0x0
    80001290:	fa0080e7          	jalr	-96(ra) # 8000122c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001294:	4719                	li	a4,6
    80001296:	6685                	lui	a3,0x1
    80001298:	10001637          	lui	a2,0x10001
    8000129c:	100015b7          	lui	a1,0x10001
    800012a0:	8526                	mv	a0,s1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f8a080e7          	jalr	-118(ra) # 8000122c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012aa:	4719                	li	a4,6
    800012ac:	004006b7          	lui	a3,0x400
    800012b0:	0c000637          	lui	a2,0xc000
    800012b4:	0c0005b7          	lui	a1,0xc000
    800012b8:	8526                	mv	a0,s1
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f72080e7          	jalr	-142(ra) # 8000122c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c2:	00007917          	auipc	s2,0x7
    800012c6:	d3e90913          	addi	s2,s2,-706 # 80008000 <etext>
    800012ca:	4729                	li	a4,10
    800012cc:	80007697          	auipc	a3,0x80007
    800012d0:	d3468693          	addi	a3,a3,-716 # 8000 <_entry-0x7fff8000>
    800012d4:	4605                	li	a2,1
    800012d6:	067e                	slli	a2,a2,0x1f
    800012d8:	85b2                	mv	a1,a2
    800012da:	8526                	mv	a0,s1
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	f50080e7          	jalr	-176(ra) # 8000122c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e4:	4719                	li	a4,6
    800012e6:	46c5                	li	a3,17
    800012e8:	06ee                	slli	a3,a3,0x1b
    800012ea:	412686b3          	sub	a3,a3,s2
    800012ee:	864a                	mv	a2,s2
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8526                	mv	a0,s1
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	f38080e7          	jalr	-200(ra) # 8000122c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fc:	4729                	li	a4,10
    800012fe:	6685                	lui	a3,0x1
    80001300:	00006617          	auipc	a2,0x6
    80001304:	d0060613          	addi	a2,a2,-768 # 80007000 <_trampoline>
    80001308:	040005b7          	lui	a1,0x4000
    8000130c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000130e:	05b2                	slli	a1,a1,0xc
    80001310:	8526                	mv	a0,s1
    80001312:	00000097          	auipc	ra,0x0
    80001316:	f1a080e7          	jalr	-230(ra) # 8000122c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000131a:	8526                	mv	a0,s1
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	700080e7          	jalr	1792(ra) # 80001a1c <proc_mapstacks>
}
    80001324:	8526                	mv	a0,s1
    80001326:	60e2                	ld	ra,24(sp)
    80001328:	6442                	ld	s0,16(sp)
    8000132a:	64a2                	ld	s1,8(sp)
    8000132c:	6902                	ld	s2,0(sp)
    8000132e:	6105                	addi	sp,sp,32
    80001330:	8082                	ret

0000000080001332 <kvminit>:
{
    80001332:	1141                	addi	sp,sp,-16
    80001334:	e406                	sd	ra,8(sp)
    80001336:	e022                	sd	s0,0(sp)
    80001338:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f22080e7          	jalr	-222(ra) # 8000125c <kvmmake>
    80001342:	00007797          	auipc	a5,0x7
    80001346:	76a7b723          	sd	a0,1902(a5) # 80008ab0 <kernel_pagetable>
}
    8000134a:	60a2                	ld	ra,8(sp)
    8000134c:	6402                	ld	s0,0(sp)
    8000134e:	0141                	addi	sp,sp,16
    80001350:	8082                	ret

0000000080001352 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001352:	715d                	addi	sp,sp,-80
    80001354:	e486                	sd	ra,72(sp)
    80001356:	e0a2                	sd	s0,64(sp)
    80001358:	fc26                	sd	s1,56(sp)
    8000135a:	f84a                	sd	s2,48(sp)
    8000135c:	f44e                	sd	s3,40(sp)
    8000135e:	f052                	sd	s4,32(sp)
    80001360:	ec56                	sd	s5,24(sp)
    80001362:	e85a                	sd	s6,16(sp)
    80001364:	e45e                	sd	s7,8(sp)
    80001366:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001368:	03459793          	slli	a5,a1,0x34
    8000136c:	e795                	bnez	a5,80001398 <uvmunmap+0x46>
    8000136e:	8a2a                	mv	s4,a0
    80001370:	892e                	mv	s2,a1
    80001372:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001374:	0632                	slli	a2,a2,0xc
    80001376:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000137a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137c:	6b05                	lui	s6,0x1
    8000137e:	0735e263          	bltu	a1,s3,800013e2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001382:	60a6                	ld	ra,72(sp)
    80001384:	6406                	ld	s0,64(sp)
    80001386:	74e2                	ld	s1,56(sp)
    80001388:	7942                	ld	s2,48(sp)
    8000138a:	79a2                	ld	s3,40(sp)
    8000138c:	7a02                	ld	s4,32(sp)
    8000138e:	6ae2                	ld	s5,24(sp)
    80001390:	6b42                	ld	s6,16(sp)
    80001392:	6ba2                	ld	s7,8(sp)
    80001394:	6161                	addi	sp,sp,80
    80001396:	8082                	ret
    panic("uvmunmap: not aligned");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	da850513          	addi	a0,a0,-600 # 80008140 <digits+0xf0>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	19c080e7          	jalr	412(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	db050513          	addi	a0,a0,-592 # 80008158 <digits+0x108>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	18c080e7          	jalr	396(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	db050513          	addi	a0,a0,-592 # 80008168 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17c080e7          	jalr	380(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	db850513          	addi	a0,a0,-584 # 80008180 <digits+0x130>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	16c080e7          	jalr	364(ra) # 8000053c <panic>
    *pte = 0;
    800013d8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013dc:	995a                	add	s2,s2,s6
    800013de:	fb3972e3          	bgeu	s2,s3,80001382 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e2:	4601                	li	a2,0
    800013e4:	85ca                	mv	a1,s2
    800013e6:	8552                	mv	a0,s4
    800013e8:	00000097          	auipc	ra,0x0
    800013ec:	cbc080e7          	jalr	-836(ra) # 800010a4 <walk>
    800013f0:	84aa                	mv	s1,a0
    800013f2:	d95d                	beqz	a0,800013a8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013f4:	6108                	ld	a0,0(a0)
    800013f6:	00157793          	andi	a5,a0,1
    800013fa:	dfdd                	beqz	a5,800013b8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013fc:	3ff57793          	andi	a5,a0,1023
    80001400:	fd7784e3          	beq	a5,s7,800013c8 <uvmunmap+0x76>
    if(do_free){
    80001404:	fc0a8ae3          	beqz	s5,800013d8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001408:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    8000140a:	0532                	slli	a0,a0,0xc
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	5ea080e7          	jalr	1514(ra) # 800009f6 <kfree>
    80001414:	b7d1                	j	800013d8 <uvmunmap+0x86>

0000000080001416 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001416:	1101                	addi	sp,sp,-32
    80001418:	ec06                	sd	ra,24(sp)
    8000141a:	e822                	sd	s0,16(sp)
    8000141c:	e426                	sd	s1,8(sp)
    8000141e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	76a080e7          	jalr	1898(ra) # 80000b8a <kalloc>
    80001428:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000142a:	c519                	beqz	a0,80001438 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000142c:	6605                	lui	a2,0x1
    8000142e:	4581                	li	a1,0
    80001430:	00000097          	auipc	ra,0x0
    80001434:	992080e7          	jalr	-1646(ra) # 80000dc2 <memset>
  return pagetable;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret

0000000080001444 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001444:	7179                	addi	sp,sp,-48
    80001446:	f406                	sd	ra,40(sp)
    80001448:	f022                	sd	s0,32(sp)
    8000144a:	ec26                	sd	s1,24(sp)
    8000144c:	e84a                	sd	s2,16(sp)
    8000144e:	e44e                	sd	s3,8(sp)
    80001450:	e052                	sd	s4,0(sp)
    80001452:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001454:	6785                	lui	a5,0x1
    80001456:	04f67863          	bgeu	a2,a5,800014a6 <uvmfirst+0x62>
    8000145a:	8a2a                	mv	s4,a0
    8000145c:	89ae                	mv	s3,a1
    8000145e:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	72a080e7          	jalr	1834(ra) # 80000b8a <kalloc>
    80001468:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	954080e7          	jalr	-1708(ra) # 80000dc2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001476:	4779                	li	a4,30
    80001478:	86ca                	mv	a3,s2
    8000147a:	6605                	lui	a2,0x1
    8000147c:	4581                	li	a1,0
    8000147e:	8552                	mv	a0,s4
    80001480:	00000097          	auipc	ra,0x0
    80001484:	d0c080e7          	jalr	-756(ra) # 8000118c <mappages>
  memmove(mem, src, sz);
    80001488:	8626                	mv	a2,s1
    8000148a:	85ce                	mv	a1,s3
    8000148c:	854a                	mv	a0,s2
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	990080e7          	jalr	-1648(ra) # 80000e1e <memmove>
}
    80001496:	70a2                	ld	ra,40(sp)
    80001498:	7402                	ld	s0,32(sp)
    8000149a:	64e2                	ld	s1,24(sp)
    8000149c:	6942                	ld	s2,16(sp)
    8000149e:	69a2                	ld	s3,8(sp)
    800014a0:	6a02                	ld	s4,0(sp)
    800014a2:	6145                	addi	sp,sp,48
    800014a4:	8082                	ret
    panic("uvmfirst: more than a page");
    800014a6:	00007517          	auipc	a0,0x7
    800014aa:	cf250513          	addi	a0,a0,-782 # 80008198 <digits+0x148>
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	08e080e7          	jalr	142(ra) # 8000053c <panic>

00000000800014b6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014b6:	1101                	addi	sp,sp,-32
    800014b8:	ec06                	sd	ra,24(sp)
    800014ba:	e822                	sd	s0,16(sp)
    800014bc:	e426                	sd	s1,8(sp)
    800014be:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014c0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014c2:	00b67d63          	bgeu	a2,a1,800014dc <uvmdealloc+0x26>
    800014c6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014c8:	6785                	lui	a5,0x1
    800014ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014cc:	00f60733          	add	a4,a2,a5
    800014d0:	76fd                	lui	a3,0xfffff
    800014d2:	8f75                	and	a4,a4,a3
    800014d4:	97ae                	add	a5,a5,a1
    800014d6:	8ff5                	and	a5,a5,a3
    800014d8:	00f76863          	bltu	a4,a5,800014e8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014dc:	8526                	mv	a0,s1
    800014de:	60e2                	ld	ra,24(sp)
    800014e0:	6442                	ld	s0,16(sp)
    800014e2:	64a2                	ld	s1,8(sp)
    800014e4:	6105                	addi	sp,sp,32
    800014e6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014e8:	8f99                	sub	a5,a5,a4
    800014ea:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ec:	4685                	li	a3,1
    800014ee:	0007861b          	sext.w	a2,a5
    800014f2:	85ba                	mv	a1,a4
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	e5e080e7          	jalr	-418(ra) # 80001352 <uvmunmap>
    800014fc:	b7c5                	j	800014dc <uvmdealloc+0x26>

00000000800014fe <uvmalloc>:
  if(newsz < oldsz)
    800014fe:	0ab66563          	bltu	a2,a1,800015a8 <uvmalloc+0xaa>
{
    80001502:	7139                	addi	sp,sp,-64
    80001504:	fc06                	sd	ra,56(sp)
    80001506:	f822                	sd	s0,48(sp)
    80001508:	f426                	sd	s1,40(sp)
    8000150a:	f04a                	sd	s2,32(sp)
    8000150c:	ec4e                	sd	s3,24(sp)
    8000150e:	e852                	sd	s4,16(sp)
    80001510:	e456                	sd	s5,8(sp)
    80001512:	e05a                	sd	s6,0(sp)
    80001514:	0080                	addi	s0,sp,64
    80001516:	8aaa                	mv	s5,a0
    80001518:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000151a:	6785                	lui	a5,0x1
    8000151c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000151e:	95be                	add	a1,a1,a5
    80001520:	77fd                	lui	a5,0xfffff
    80001522:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001526:	08c9f363          	bgeu	s3,a2,800015ac <uvmalloc+0xae>
    8000152a:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000152c:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	65a080e7          	jalr	1626(ra) # 80000b8a <kalloc>
    80001538:	84aa                	mv	s1,a0
    if(mem == 0){
    8000153a:	c51d                	beqz	a0,80001568 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	4581                	li	a1,0
    80001540:	00000097          	auipc	ra,0x0
    80001544:	882080e7          	jalr	-1918(ra) # 80000dc2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001548:	875a                	mv	a4,s6
    8000154a:	86a6                	mv	a3,s1
    8000154c:	6605                	lui	a2,0x1
    8000154e:	85ca                	mv	a1,s2
    80001550:	8556                	mv	a0,s5
    80001552:	00000097          	auipc	ra,0x0
    80001556:	c3a080e7          	jalr	-966(ra) # 8000118c <mappages>
    8000155a:	e90d                	bnez	a0,8000158c <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000155c:	6785                	lui	a5,0x1
    8000155e:	993e                	add	s2,s2,a5
    80001560:	fd4968e3          	bltu	s2,s4,80001530 <uvmalloc+0x32>
  return newsz;
    80001564:	8552                	mv	a0,s4
    80001566:	a809                	j	80001578 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001568:	864e                	mv	a2,s3
    8000156a:	85ca                	mv	a1,s2
    8000156c:	8556                	mv	a0,s5
    8000156e:	00000097          	auipc	ra,0x0
    80001572:	f48080e7          	jalr	-184(ra) # 800014b6 <uvmdealloc>
      return 0;
    80001576:	4501                	li	a0,0
}
    80001578:	70e2                	ld	ra,56(sp)
    8000157a:	7442                	ld	s0,48(sp)
    8000157c:	74a2                	ld	s1,40(sp)
    8000157e:	7902                	ld	s2,32(sp)
    80001580:	69e2                	ld	s3,24(sp)
    80001582:	6a42                	ld	s4,16(sp)
    80001584:	6aa2                	ld	s5,8(sp)
    80001586:	6b02                	ld	s6,0(sp)
    80001588:	6121                	addi	sp,sp,64
    8000158a:	8082                	ret
      kfree(mem);
    8000158c:	8526                	mv	a0,s1
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	468080e7          	jalr	1128(ra) # 800009f6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001596:	864e                	mv	a2,s3
    80001598:	85ca                	mv	a1,s2
    8000159a:	8556                	mv	a0,s5
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	f1a080e7          	jalr	-230(ra) # 800014b6 <uvmdealloc>
      return 0;
    800015a4:	4501                	li	a0,0
    800015a6:	bfc9                	j	80001578 <uvmalloc+0x7a>
    return oldsz;
    800015a8:	852e                	mv	a0,a1
}
    800015aa:	8082                	ret
  return newsz;
    800015ac:	8532                	mv	a0,a2
    800015ae:	b7e9                	j	80001578 <uvmalloc+0x7a>

00000000800015b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b0:	7179                	addi	sp,sp,-48
    800015b2:	f406                	sd	ra,40(sp)
    800015b4:	f022                	sd	s0,32(sp)
    800015b6:	ec26                	sd	s1,24(sp)
    800015b8:	e84a                	sd	s2,16(sp)
    800015ba:	e44e                	sd	s3,8(sp)
    800015bc:	e052                	sd	s4,0(sp)
    800015be:	1800                	addi	s0,sp,48
    800015c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c2:	84aa                	mv	s1,a0
    800015c4:	6905                	lui	s2,0x1
    800015c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c8:	4985                	li	s3,1
    800015ca:	a829                	j	800015e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015ce:	00c79513          	slli	a0,a5,0xc
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	fde080e7          	jalr	-34(ra) # 800015b0 <freewalk>
      pagetable[i] = 0;
    800015da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015de:	04a1                	addi	s1,s1,8
    800015e0:	03248163          	beq	s1,s2,80001602 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e6:	00f7f713          	andi	a4,a5,15
    800015ea:	ff3701e3          	beq	a4,s3,800015cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ee:	8b85                	andi	a5,a5,1
    800015f0:	d7fd                	beqz	a5,800015de <freewalk+0x2e>
      panic("freewalk: leaf");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bc650513          	addi	a0,a0,-1082 # 800081b8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f42080e7          	jalr	-190(ra) # 8000053c <panic>
    }
  }
  kfree((void *)pagetable);
    80001602:	8552                	mv	a0,s4
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3f2080e7          	jalr	1010(ra) # 800009f6 <kfree>
}
    8000160c:	70a2                	ld	ra,40(sp)
    8000160e:	7402                	ld	s0,32(sp)
    80001610:	64e2                	ld	s1,24(sp)
    80001612:	6942                	ld	s2,16(sp)
    80001614:	69a2                	ld	s3,8(sp)
    80001616:	6a02                	ld	s4,0(sp)
    80001618:	6145                	addi	sp,sp,48
    8000161a:	8082                	ret

000000008000161c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000161c:	1101                	addi	sp,sp,-32
    8000161e:	ec06                	sd	ra,24(sp)
    80001620:	e822                	sd	s0,16(sp)
    80001622:	e426                	sd	s1,8(sp)
    80001624:	1000                	addi	s0,sp,32
    80001626:	84aa                	mv	s1,a0
  if(sz > 0)
    80001628:	e999                	bnez	a1,8000163e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000162a:	8526                	mv	a0,s1
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	f84080e7          	jalr	-124(ra) # 800015b0 <freewalk>
}
    80001634:	60e2                	ld	ra,24(sp)
    80001636:	6442                	ld	s0,16(sp)
    80001638:	64a2                	ld	s1,8(sp)
    8000163a:	6105                	addi	sp,sp,32
    8000163c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000163e:	6785                	lui	a5,0x1
    80001640:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001642:	95be                	add	a1,a1,a5
    80001644:	4685                	li	a3,1
    80001646:	00c5d613          	srli	a2,a1,0xc
    8000164a:	4581                	li	a1,0
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	d06080e7          	jalr	-762(ra) # 80001352 <uvmunmap>
    80001654:	bfd9                	j	8000162a <uvmfree+0xe>

0000000080001656 <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001656:	ca7d                	beqz	a2,8000174c <uvmcopy+0xf6>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8aae                	mv	s5,a1
    80001674:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001676:	4901                	li	s2,0
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");

    
    parefs[PTE2PPN(*pte)] ++;
    80001678:	0000f997          	auipc	s3,0xf
    8000167c:	6b898993          	addi	s3,s3,1720 # 80010d30 <parefs>
    printf("uvmcopy: %d\n", parefs[PTE2PPN(*pte)]);
    80001680:	00007c17          	auipc	s8,0x7
    80001684:	b88c0c13          	addi	s8,s8,-1144 # 80008208 <digits+0x1b8>
    printf("ppn: %d\n", PTE2PPN(*pte));
    80001688:	00007b97          	auipc	s7,0x7
    8000168c:	b90b8b93          	addi	s7,s7,-1136 # 80008218 <digits+0x1c8>
    if((pte = walk(old, i, 0)) == 0)
    80001690:	4601                	li	a2,0
    80001692:	85ca                	mv	a1,s2
    80001694:	855a                	mv	a0,s6
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	a0e080e7          	jalr	-1522(ra) # 800010a4 <walk>
    8000169e:	84aa                	mv	s1,a0
    800016a0:	c125                	beqz	a0,80001700 <uvmcopy+0xaa>
    if((*pte & PTE_V) == 0)
    800016a2:	611c                	ld	a5,0(a0)
    800016a4:	0017f713          	andi	a4,a5,1
    800016a8:	c725                	beqz	a4,80001710 <uvmcopy+0xba>
    parefs[PTE2PPN(*pte)] ++;
    800016aa:	83a9                	srli	a5,a5,0xa
    800016ac:	97ce                	add	a5,a5,s3
    800016ae:	0007c703          	lbu	a4,0(a5)
    800016b2:	2705                	addiw	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd50c1>
    800016b4:	00e78023          	sb	a4,0(a5)
    printf("uvmcopy: %d\n", parefs[PTE2PPN(*pte)]);
    800016b8:	611c                	ld	a5,0(a0)
    800016ba:	83a9                	srli	a5,a5,0xa
    800016bc:	97ce                	add	a5,a5,s3
    800016be:	0007c583          	lbu	a1,0(a5)
    800016c2:	8562                	mv	a0,s8
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	ed4080e7          	jalr	-300(ra) # 80000598 <printf>
    printf("ppn: %d\n", PTE2PPN(*pte));
    800016cc:	608c                	ld	a1,0(s1)
    800016ce:	81a9                	srli	a1,a1,0xa
    800016d0:	855e                	mv	a0,s7
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	ec6080e7          	jalr	-314(ra) # 80000598 <printf>
    pa = PTE2PA(*pte);
    800016da:	6098                	ld	a4,0(s1)
    800016dc:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & 0x3FB;

    //ALLOCATES NEW MEMORY
    // if((mem = kalloc()) == 0)
    //   goto err;
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    800016e0:	3fb77713          	andi	a4,a4,1019
    800016e4:	06b2                	slli	a3,a3,0xc
    800016e6:	6605                	lui	a2,0x1
    800016e8:	85ca                	mv	a1,s2
    800016ea:	8556                	mv	a0,s5
    800016ec:	00000097          	auipc	ra,0x0
    800016f0:	aa0080e7          	jalr	-1376(ra) # 8000118c <mappages>
    800016f4:	e515                	bnez	a0,80001720 <uvmcopy+0xca>
  for(i = 0; i < sz; i += PGSIZE){
    800016f6:	6785                	lui	a5,0x1
    800016f8:	993e                	add	s2,s2,a5
    800016fa:	f9496be3          	bltu	s2,s4,80001690 <uvmcopy+0x3a>
    800016fe:	a81d                	j	80001734 <uvmcopy+0xde>
      panic("uvmcopy: pte should exist");
    80001700:	00007517          	auipc	a0,0x7
    80001704:	ac850513          	addi	a0,a0,-1336 # 800081c8 <digits+0x178>
    80001708:	fffff097          	auipc	ra,0xfffff
    8000170c:	e34080e7          	jalr	-460(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001710:	00007517          	auipc	a0,0x7
    80001714:	ad850513          	addi	a0,a0,-1320 # 800081e8 <digits+0x198>
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	e24080e7          	jalr	-476(ra) # 8000053c <panic>
  
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001720:	4685                	li	a3,1
    80001722:	00c95613          	srli	a2,s2,0xc
    80001726:	4581                	li	a1,0
    80001728:	8556                	mv	a0,s5
    8000172a:	00000097          	auipc	ra,0x0
    8000172e:	c28080e7          	jalr	-984(ra) # 80001352 <uvmunmap>
  return -1;
    80001732:	557d                	li	a0,-1
}
    80001734:	60a6                	ld	ra,72(sp)
    80001736:	6406                	ld	s0,64(sp)
    80001738:	74e2                	ld	s1,56(sp)
    8000173a:	7942                	ld	s2,48(sp)
    8000173c:	79a2                	ld	s3,40(sp)
    8000173e:	7a02                	ld	s4,32(sp)
    80001740:	6ae2                	ld	s5,24(sp)
    80001742:	6b42                	ld	s6,16(sp)
    80001744:	6ba2                	ld	s7,8(sp)
    80001746:	6c02                	ld	s8,0(sp)
    80001748:	6161                	addi	sp,sp,80
    8000174a:	8082                	ret
  return 0;
    8000174c:	4501                	li	a0,0
}
    8000174e:	8082                	ret

0000000080001750 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001750:	1141                	addi	sp,sp,-16
    80001752:	e406                	sd	ra,8(sp)
    80001754:	e022                	sd	s0,0(sp)
    80001756:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001758:	4601                	li	a2,0
    8000175a:	00000097          	auipc	ra,0x0
    8000175e:	94a080e7          	jalr	-1718(ra) # 800010a4 <walk>
  if(pte == 0)
    80001762:	c901                	beqz	a0,80001772 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001764:	611c                	ld	a5,0(a0)
    80001766:	9bbd                	andi	a5,a5,-17
    80001768:	e11c                	sd	a5,0(a0)
}
    8000176a:	60a2                	ld	ra,8(sp)
    8000176c:	6402                	ld	s0,0(sp)
    8000176e:	0141                	addi	sp,sp,16
    80001770:	8082                	ret
    panic("uvmclear");
    80001772:	00007517          	auipc	a0,0x7
    80001776:	ab650513          	addi	a0,a0,-1354 # 80008228 <digits+0x1d8>
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	dc2080e7          	jalr	-574(ra) # 8000053c <panic>

0000000080001782 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001782:	c6bd                	beqz	a3,800017f0 <copyout+0x6e>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	e062                	sd	s8,0(sp)
    8000179a:	0880                	addi	s0,sp,80
    8000179c:	8b2a                	mv	s6,a0
    8000179e:	8c2e                	mv	s8,a1
    800017a0:	8a32                	mv	s4,a2
    800017a2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017a4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017a6:	6a85                	lui	s5,0x1
    800017a8:	a015                	j	800017cc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017aa:	9562                	add	a0,a0,s8
    800017ac:	0004861b          	sext.w	a2,s1
    800017b0:	85d2                	mv	a1,s4
    800017b2:	41250533          	sub	a0,a0,s2
    800017b6:	fffff097          	auipc	ra,0xfffff
    800017ba:	668080e7          	jalr	1640(ra) # 80000e1e <memmove>
    // else
    // {
    //   memmove((void *)(pa0 + (dstva - va0)), src, n);
    // }

    len -= n;
    800017be:	409989b3          	sub	s3,s3,s1
    src += n;
    800017c2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017c4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017c8:	02098263          	beqz	s3,800017ec <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017cc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ca                	mv	a1,s2
    800017d2:	855a                	mv	a0,s6
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	976080e7          	jalr	-1674(ra) # 8000114a <walkaddr>
    if(pa0 == 0)
    800017dc:	cd01                	beqz	a0,800017f4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017de:	418904b3          	sub	s1,s2,s8
    800017e2:	94d6                	add	s1,s1,s5
    800017e4:	fc99f3e3          	bgeu	s3,s1,800017aa <copyout+0x28>
    800017e8:	84ce                	mv	s1,s3
    800017ea:	b7c1                	j	800017aa <copyout+0x28>
  }
  return 0;
    800017ec:	4501                	li	a0,0
    800017ee:	a021                	j	800017f6 <copyout+0x74>
    800017f0:	4501                	li	a0,0
}
    800017f2:	8082                	ret
      return -1;
    800017f4:	557d                	li	a0,-1
}
    800017f6:	60a6                	ld	ra,72(sp)
    800017f8:	6406                	ld	s0,64(sp)
    800017fa:	74e2                	ld	s1,56(sp)
    800017fc:	7942                	ld	s2,48(sp)
    800017fe:	79a2                	ld	s3,40(sp)
    80001800:	7a02                	ld	s4,32(sp)
    80001802:	6ae2                	ld	s5,24(sp)
    80001804:	6b42                	ld	s6,16(sp)
    80001806:	6ba2                	ld	s7,8(sp)
    80001808:	6c02                	ld	s8,0(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret

000000008000180e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000180e:	caa5                	beqz	a3,8000187e <copyin+0x70>
{
    80001810:	715d                	addi	sp,sp,-80
    80001812:	e486                	sd	ra,72(sp)
    80001814:	e0a2                	sd	s0,64(sp)
    80001816:	fc26                	sd	s1,56(sp)
    80001818:	f84a                	sd	s2,48(sp)
    8000181a:	f44e                	sd	s3,40(sp)
    8000181c:	f052                	sd	s4,32(sp)
    8000181e:	ec56                	sd	s5,24(sp)
    80001820:	e85a                	sd	s6,16(sp)
    80001822:	e45e                	sd	s7,8(sp)
    80001824:	e062                	sd	s8,0(sp)
    80001826:	0880                	addi	s0,sp,80
    80001828:	8b2a                	mv	s6,a0
    8000182a:	8a2e                	mv	s4,a1
    8000182c:	8c32                	mv	s8,a2
    8000182e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001830:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001832:	6a85                	lui	s5,0x1
    80001834:	a01d                	j	8000185a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001836:	018505b3          	add	a1,a0,s8
    8000183a:	0004861b          	sext.w	a2,s1
    8000183e:	412585b3          	sub	a1,a1,s2
    80001842:	8552                	mv	a0,s4
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	5da080e7          	jalr	1498(ra) # 80000e1e <memmove>

    len -= n;
    8000184c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001850:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001852:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001856:	02098263          	beqz	s3,8000187a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000185a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000185e:	85ca                	mv	a1,s2
    80001860:	855a                	mv	a0,s6
    80001862:	00000097          	auipc	ra,0x0
    80001866:	8e8080e7          	jalr	-1816(ra) # 8000114a <walkaddr>
    if(pa0 == 0)
    8000186a:	cd01                	beqz	a0,80001882 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000186c:	418904b3          	sub	s1,s2,s8
    80001870:	94d6                	add	s1,s1,s5
    80001872:	fc99f2e3          	bgeu	s3,s1,80001836 <copyin+0x28>
    80001876:	84ce                	mv	s1,s3
    80001878:	bf7d                	j	80001836 <copyin+0x28>
  }
  return 0;
    8000187a:	4501                	li	a0,0
    8000187c:	a021                	j	80001884 <copyin+0x76>
    8000187e:	4501                	li	a0,0
}
    80001880:	8082                	ret
      return -1;
    80001882:	557d                	li	a0,-1
}
    80001884:	60a6                	ld	ra,72(sp)
    80001886:	6406                	ld	s0,64(sp)
    80001888:	74e2                	ld	s1,56(sp)
    8000188a:	7942                	ld	s2,48(sp)
    8000188c:	79a2                	ld	s3,40(sp)
    8000188e:	7a02                	ld	s4,32(sp)
    80001890:	6ae2                	ld	s5,24(sp)
    80001892:	6b42                	ld	s6,16(sp)
    80001894:	6ba2                	ld	s7,8(sp)
    80001896:	6c02                	ld	s8,0(sp)
    80001898:	6161                	addi	sp,sp,80
    8000189a:	8082                	ret

000000008000189c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000189c:	c2dd                	beqz	a3,80001942 <copyinstr+0xa6>
{
    8000189e:	715d                	addi	sp,sp,-80
    800018a0:	e486                	sd	ra,72(sp)
    800018a2:	e0a2                	sd	s0,64(sp)
    800018a4:	fc26                	sd	s1,56(sp)
    800018a6:	f84a                	sd	s2,48(sp)
    800018a8:	f44e                	sd	s3,40(sp)
    800018aa:	f052                	sd	s4,32(sp)
    800018ac:	ec56                	sd	s5,24(sp)
    800018ae:	e85a                	sd	s6,16(sp)
    800018b0:	e45e                	sd	s7,8(sp)
    800018b2:	0880                	addi	s0,sp,80
    800018b4:	8a2a                	mv	s4,a0
    800018b6:	8b2e                	mv	s6,a1
    800018b8:	8bb2                	mv	s7,a2
    800018ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018be:	6985                	lui	s3,0x1
    800018c0:	a02d                	j	800018ea <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018c8:	37fd                	addiw	a5,a5,-1
    800018ca:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018ce:	60a6                	ld	ra,72(sp)
    800018d0:	6406                	ld	s0,64(sp)
    800018d2:	74e2                	ld	s1,56(sp)
    800018d4:	7942                	ld	s2,48(sp)
    800018d6:	79a2                	ld	s3,40(sp)
    800018d8:	7a02                	ld	s4,32(sp)
    800018da:	6ae2                	ld	s5,24(sp)
    800018dc:	6b42                	ld	s6,16(sp)
    800018de:	6ba2                	ld	s7,8(sp)
    800018e0:	6161                	addi	sp,sp,80
    800018e2:	8082                	ret
    srcva = va0 + PGSIZE;
    800018e4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018e8:	c8a9                	beqz	s1,8000193a <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800018ea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018ee:	85ca                	mv	a1,s2
    800018f0:	8552                	mv	a0,s4
    800018f2:	00000097          	auipc	ra,0x0
    800018f6:	858080e7          	jalr	-1960(ra) # 8000114a <walkaddr>
    if(pa0 == 0)
    800018fa:	c131                	beqz	a0,8000193e <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018fc:	417906b3          	sub	a3,s2,s7
    80001900:	96ce                	add	a3,a3,s3
    80001902:	00d4f363          	bgeu	s1,a3,80001908 <copyinstr+0x6c>
    80001906:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001908:	955e                	add	a0,a0,s7
    8000190a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000190e:	daf9                	beqz	a3,800018e4 <copyinstr+0x48>
    80001910:	87da                	mv	a5,s6
    80001912:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001914:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001918:	96da                	add	a3,a3,s6
    8000191a:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000191c:	00f60733          	add	a4,a2,a5
    80001920:	00074703          	lbu	a4,0(a4)
    80001924:	df59                	beqz	a4,800018c2 <copyinstr+0x26>
        *dst = *p;
    80001926:	00e78023          	sb	a4,0(a5)
      dst++;
    8000192a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000192c:	fed797e3          	bne	a5,a3,8000191a <copyinstr+0x7e>
    80001930:	14fd                	addi	s1,s1,-1
    80001932:	94c2                	add	s1,s1,a6
      --max;
    80001934:	8c8d                	sub	s1,s1,a1
      dst++;
    80001936:	8b3e                	mv	s6,a5
    80001938:	b775                	j	800018e4 <copyinstr+0x48>
    8000193a:	4781                	li	a5,0
    8000193c:	b771                	j	800018c8 <copyinstr+0x2c>
      return -1;
    8000193e:	557d                	li	a0,-1
    80001940:	b779                	j	800018ce <copyinstr+0x32>
  int got_null = 0;
    80001942:	4781                	li	a5,0
  if(got_null){
    80001944:	37fd                	addiw	a5,a5,-1
    80001946:	0007851b          	sext.w	a0,a5
}
    8000194a:	8082                	ret

000000008000194c <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    8000194c:	715d                	addi	sp,sp,-80
    8000194e:	e486                	sd	ra,72(sp)
    80001950:	e0a2                	sd	s0,64(sp)
    80001952:	fc26                	sd	s1,56(sp)
    80001954:	f84a                	sd	s2,48(sp)
    80001956:	f44e                	sd	s3,40(sp)
    80001958:	f052                	sd	s4,32(sp)
    8000195a:	ec56                	sd	s5,24(sp)
    8000195c:	e85a                	sd	s6,16(sp)
    8000195e:	e45e                	sd	s7,8(sp)
    80001960:	e062                	sd	s8,0(sp)
    80001962:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001964:	8792                	mv	a5,tp
    int id = r_tp();
    80001966:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001968:	00017a97          	auipc	s5,0x17
    8000196c:	3c8a8a93          	addi	s5,s5,968 # 80018d30 <cpus>
    80001970:	00779713          	slli	a4,a5,0x7
    80001974:	00ea86b3          	add	a3,s5,a4
    80001978:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffd50c0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    8000197c:	0721                	addi	a4,a4,8
    8000197e:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001980:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001982:	00007c17          	auipc	s8,0x7
    80001986:	086c0c13          	addi	s8,s8,134 # 80008a08 <sched_pointer>
    8000198a:	00000b97          	auipc	s7,0x0
    8000198e:	fc2b8b93          	addi	s7,s7,-62 # 8000194c <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001992:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001996:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000199a:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    8000199e:	00017497          	auipc	s1,0x17
    800019a2:	7c248493          	addi	s1,s1,1986 # 80019160 <proc>
            if (p->state == RUNNABLE)
    800019a6:	498d                	li	s3,3
                p->state = RUNNING;
    800019a8:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    800019aa:	0001da17          	auipc	s4,0x1d
    800019ae:	1b6a0a13          	addi	s4,s4,438 # 8001eb60 <tickslock>
    800019b2:	a81d                	j	800019e8 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	3c4080e7          	jalr	964(ra) # 80000d7a <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    800019be:	60a6                	ld	ra,72(sp)
    800019c0:	6406                	ld	s0,64(sp)
    800019c2:	74e2                	ld	s1,56(sp)
    800019c4:	7942                	ld	s2,48(sp)
    800019c6:	79a2                	ld	s3,40(sp)
    800019c8:	7a02                	ld	s4,32(sp)
    800019ca:	6ae2                	ld	s5,24(sp)
    800019cc:	6b42                	ld	s6,16(sp)
    800019ce:	6ba2                	ld	s7,8(sp)
    800019d0:	6c02                	ld	s8,0(sp)
    800019d2:	6161                	addi	sp,sp,80
    800019d4:	8082                	ret
            release(&p->lock);
    800019d6:	8526                	mv	a0,s1
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	3a2080e7          	jalr	930(ra) # 80000d7a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800019e0:	16848493          	addi	s1,s1,360
    800019e4:	fb4487e3          	beq	s1,s4,80001992 <rr_scheduler+0x46>
            acquire(&p->lock);
    800019e8:	8526                	mv	a0,s1
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	2dc080e7          	jalr	732(ra) # 80000cc6 <acquire>
            if (p->state == RUNNABLE)
    800019f2:	4c9c                	lw	a5,24(s1)
    800019f4:	ff3791e3          	bne	a5,s3,800019d6 <rr_scheduler+0x8a>
                p->state = RUNNING;
    800019f8:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    800019fc:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001a00:	06048593          	addi	a1,s1,96
    80001a04:	8556                	mv	a0,s5
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	fc6080e7          	jalr	-58(ra) # 800029cc <swtch>
                if (sched_pointer != &rr_scheduler)
    80001a0e:	000c3783          	ld	a5,0(s8)
    80001a12:	fb7791e3          	bne	a5,s7,800019b4 <rr_scheduler+0x68>
                c->proc = 0;
    80001a16:	00093023          	sd	zero,0(s2)
    80001a1a:	bf75                	j	800019d6 <rr_scheduler+0x8a>

0000000080001a1c <proc_mapstacks>:
{
    80001a1c:	7139                	addi	sp,sp,-64
    80001a1e:	fc06                	sd	ra,56(sp)
    80001a20:	f822                	sd	s0,48(sp)
    80001a22:	f426                	sd	s1,40(sp)
    80001a24:	f04a                	sd	s2,32(sp)
    80001a26:	ec4e                	sd	s3,24(sp)
    80001a28:	e852                	sd	s4,16(sp)
    80001a2a:	e456                	sd	s5,8(sp)
    80001a2c:	e05a                	sd	s6,0(sp)
    80001a2e:	0080                	addi	s0,sp,64
    80001a30:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	00017497          	auipc	s1,0x17
    80001a36:	72e48493          	addi	s1,s1,1838 # 80019160 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a3a:	8b26                	mv	s6,s1
    80001a3c:	00006a97          	auipc	s5,0x6
    80001a40:	5d4a8a93          	addi	s5,s5,1492 # 80008010 <__func__.1+0x8>
    80001a44:	04000937          	lui	s2,0x4000
    80001a48:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a4a:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a4c:	0001da17          	auipc	s4,0x1d
    80001a50:	114a0a13          	addi	s4,s4,276 # 8001eb60 <tickslock>
        char *pa = kalloc();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	136080e7          	jalr	310(ra) # 80000b8a <kalloc>
    80001a5c:	862a                	mv	a2,a0
        if (pa == 0)
    80001a5e:	c131                	beqz	a0,80001aa2 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a60:	416485b3          	sub	a1,s1,s6
    80001a64:	858d                	srai	a1,a1,0x3
    80001a66:	000ab783          	ld	a5,0(s5)
    80001a6a:	02f585b3          	mul	a1,a1,a5
    80001a6e:	2585                	addiw	a1,a1,1
    80001a70:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a74:	4719                	li	a4,6
    80001a76:	6685                	lui	a3,0x1
    80001a78:	40b905b3          	sub	a1,s2,a1
    80001a7c:	854e                	mv	a0,s3
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	7ae080e7          	jalr	1966(ra) # 8000122c <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a86:	16848493          	addi	s1,s1,360
    80001a8a:	fd4495e3          	bne	s1,s4,80001a54 <proc_mapstacks+0x38>
}
    80001a8e:	70e2                	ld	ra,56(sp)
    80001a90:	7442                	ld	s0,48(sp)
    80001a92:	74a2                	ld	s1,40(sp)
    80001a94:	7902                	ld	s2,32(sp)
    80001a96:	69e2                	ld	s3,24(sp)
    80001a98:	6a42                	ld	s4,16(sp)
    80001a9a:	6aa2                	ld	s5,8(sp)
    80001a9c:	6b02                	ld	s6,0(sp)
    80001a9e:	6121                	addi	sp,sp,64
    80001aa0:	8082                	ret
            panic("kalloc");
    80001aa2:	00006517          	auipc	a0,0x6
    80001aa6:	79650513          	addi	a0,a0,1942 # 80008238 <digits+0x1e8>
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	a92080e7          	jalr	-1390(ra) # 8000053c <panic>

0000000080001ab2 <procinit>:
{
    80001ab2:	7139                	addi	sp,sp,-64
    80001ab4:	fc06                	sd	ra,56(sp)
    80001ab6:	f822                	sd	s0,48(sp)
    80001ab8:	f426                	sd	s1,40(sp)
    80001aba:	f04a                	sd	s2,32(sp)
    80001abc:	ec4e                	sd	s3,24(sp)
    80001abe:	e852                	sd	s4,16(sp)
    80001ac0:	e456                	sd	s5,8(sp)
    80001ac2:	e05a                	sd	s6,0(sp)
    80001ac4:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001ac6:	00006597          	auipc	a1,0x6
    80001aca:	77a58593          	addi	a1,a1,1914 # 80008240 <digits+0x1f0>
    80001ace:	00017517          	auipc	a0,0x17
    80001ad2:	66250513          	addi	a0,a0,1634 # 80019130 <pid_lock>
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	160080e7          	jalr	352(ra) # 80000c36 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001ade:	00006597          	auipc	a1,0x6
    80001ae2:	76a58593          	addi	a1,a1,1898 # 80008248 <digits+0x1f8>
    80001ae6:	00017517          	auipc	a0,0x17
    80001aea:	66250513          	addi	a0,a0,1634 # 80019148 <wait_lock>
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	148080e7          	jalr	328(ra) # 80000c36 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	00017497          	auipc	s1,0x17
    80001afa:	66a48493          	addi	s1,s1,1642 # 80019160 <proc>
        initlock(&p->lock, "proc");
    80001afe:	00006b17          	auipc	s6,0x6
    80001b02:	75ab0b13          	addi	s6,s6,1882 # 80008258 <digits+0x208>
        p->kstack = KSTACK((int)(p - proc));
    80001b06:	8aa6                	mv	s5,s1
    80001b08:	00006a17          	auipc	s4,0x6
    80001b0c:	508a0a13          	addi	s4,s4,1288 # 80008010 <__func__.1+0x8>
    80001b10:	04000937          	lui	s2,0x4000
    80001b14:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b16:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b18:	0001d997          	auipc	s3,0x1d
    80001b1c:	04898993          	addi	s3,s3,72 # 8001eb60 <tickslock>
        initlock(&p->lock, "proc");
    80001b20:	85da                	mv	a1,s6
    80001b22:	8526                	mv	a0,s1
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	112080e7          	jalr	274(ra) # 80000c36 <initlock>
        p->state = UNUSED;
    80001b2c:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b30:	415487b3          	sub	a5,s1,s5
    80001b34:	878d                	srai	a5,a5,0x3
    80001b36:	000a3703          	ld	a4,0(s4)
    80001b3a:	02e787b3          	mul	a5,a5,a4
    80001b3e:	2785                	addiw	a5,a5,1
    80001b40:	00d7979b          	slliw	a5,a5,0xd
    80001b44:	40f907b3          	sub	a5,s2,a5
    80001b48:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b4a:	16848493          	addi	s1,s1,360
    80001b4e:	fd3499e3          	bne	s1,s3,80001b20 <procinit+0x6e>
}
    80001b52:	70e2                	ld	ra,56(sp)
    80001b54:	7442                	ld	s0,48(sp)
    80001b56:	74a2                	ld	s1,40(sp)
    80001b58:	7902                	ld	s2,32(sp)
    80001b5a:	69e2                	ld	s3,24(sp)
    80001b5c:	6a42                	ld	s4,16(sp)
    80001b5e:	6aa2                	ld	s5,8(sp)
    80001b60:	6b02                	ld	s6,0(sp)
    80001b62:	6121                	addi	sp,sp,64
    80001b64:	8082                	ret

0000000080001b66 <copy_array>:
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e422                	sd	s0,8(sp)
    80001b6a:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b6c:	00c05c63          	blez	a2,80001b84 <copy_array+0x1e>
    80001b70:	87aa                	mv	a5,a0
    80001b72:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001b74:	0007c703          	lbu	a4,0(a5)
    80001b78:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b7c:	0785                	addi	a5,a5,1
    80001b7e:	0585                	addi	a1,a1,1
    80001b80:	fea79ae3          	bne	a5,a0,80001b74 <copy_array+0xe>
}
    80001b84:	6422                	ld	s0,8(sp)
    80001b86:	0141                	addi	sp,sp,16
    80001b88:	8082                	ret

0000000080001b8a <cpuid>:
{
    80001b8a:	1141                	addi	sp,sp,-16
    80001b8c:	e422                	sd	s0,8(sp)
    80001b8e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b90:	8512                	mv	a0,tp
}
    80001b92:	2501                	sext.w	a0,a0
    80001b94:	6422                	ld	s0,8(sp)
    80001b96:	0141                	addi	sp,sp,16
    80001b98:	8082                	ret

0000000080001b9a <mycpu>:
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e422                	sd	s0,8(sp)
    80001b9e:	0800                	addi	s0,sp,16
    80001ba0:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001ba2:	2781                	sext.w	a5,a5
    80001ba4:	079e                	slli	a5,a5,0x7
}
    80001ba6:	00017517          	auipc	a0,0x17
    80001baa:	18a50513          	addi	a0,a0,394 # 80018d30 <cpus>
    80001bae:	953e                	add	a0,a0,a5
    80001bb0:	6422                	ld	s0,8(sp)
    80001bb2:	0141                	addi	sp,sp,16
    80001bb4:	8082                	ret

0000000080001bb6 <myproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	1000                	addi	s0,sp,32
    push_off();
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	0ba080e7          	jalr	186(ra) # 80000c7a <push_off>
    80001bc8:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001bca:	2781                	sext.w	a5,a5
    80001bcc:	079e                	slli	a5,a5,0x7
    80001bce:	00017717          	auipc	a4,0x17
    80001bd2:	16270713          	addi	a4,a4,354 # 80018d30 <cpus>
    80001bd6:	97ba                	add	a5,a5,a4
    80001bd8:	6384                	ld	s1,0(a5)
    pop_off();
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	140080e7          	jalr	320(ra) # 80000d1a <pop_off>
}
    80001be2:	8526                	mv	a0,s1
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret

0000000080001bee <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bee:	1141                	addi	sp,sp,-16
    80001bf0:	e406                	sd	ra,8(sp)
    80001bf2:	e022                	sd	s0,0(sp)
    80001bf4:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	fc0080e7          	jalr	-64(ra) # 80001bb6 <myproc>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	17c080e7          	jalr	380(ra) # 80000d7a <release>

    if (first)
    80001c06:	00007797          	auipc	a5,0x7
    80001c0a:	dfa7a783          	lw	a5,-518(a5) # 80008a00 <first.1>
    80001c0e:	eb89                	bnez	a5,80001c20 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c10:	00001097          	auipc	ra,0x1
    80001c14:	e66080e7          	jalr	-410(ra) # 80002a76 <usertrapret>
}
    80001c18:	60a2                	ld	ra,8(sp)
    80001c1a:	6402                	ld	s0,0(sp)
    80001c1c:	0141                	addi	sp,sp,16
    80001c1e:	8082                	ret
        first = 0;
    80001c20:	00007797          	auipc	a5,0x7
    80001c24:	de07a023          	sw	zero,-544(a5) # 80008a00 <first.1>
        fsinit(ROOTDEV);
    80001c28:	4505                	li	a0,1
    80001c2a:	00002097          	auipc	ra,0x2
    80001c2e:	dbe080e7          	jalr	-578(ra) # 800039e8 <fsinit>
    80001c32:	bff9                	j	80001c10 <forkret+0x22>

0000000080001c34 <allocpid>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c40:	00017917          	auipc	s2,0x17
    80001c44:	4f090913          	addi	s2,s2,1264 # 80019130 <pid_lock>
    80001c48:	854a                	mv	a0,s2
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	07c080e7          	jalr	124(ra) # 80000cc6 <acquire>
    pid = nextpid;
    80001c52:	00007797          	auipc	a5,0x7
    80001c56:	dbe78793          	addi	a5,a5,-578 # 80008a10 <nextpid>
    80001c5a:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c5c:	0014871b          	addiw	a4,s1,1
    80001c60:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c62:	854a                	mv	a0,s2
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	116080e7          	jalr	278(ra) # 80000d7a <release>
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret

0000000080001c7a <proc_pagetable>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	e04a                	sd	s2,0(sp)
    80001c84:	1000                	addi	s0,sp,32
    80001c86:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	78e080e7          	jalr	1934(ra) # 80001416 <uvmcreate>
    80001c90:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c92:	c121                	beqz	a0,80001cd2 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c94:	4729                	li	a4,10
    80001c96:	00005697          	auipc	a3,0x5
    80001c9a:	36a68693          	addi	a3,a3,874 # 80007000 <_trampoline>
    80001c9e:	6605                	lui	a2,0x1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	4e4080e7          	jalr	1252(ra) # 8000118c <mappages>
    80001cb0:	02054863          	bltz	a0,80001ce0 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb4:	4719                	li	a4,6
    80001cb6:	05893683          	ld	a3,88(s2)
    80001cba:	6605                	lui	a2,0x1
    80001cbc:	020005b7          	lui	a1,0x2000
    80001cc0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cc2:	05b6                	slli	a1,a1,0xd
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	4c6080e7          	jalr	1222(ra) # 8000118c <mappages>
    80001cce:	02054163          	bltz	a0,80001cf0 <proc_pagetable+0x76>
}
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6902                	ld	s2,0(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret
        uvmfree(pagetable, 0);
    80001ce0:	4581                	li	a1,0
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	938080e7          	jalr	-1736(ra) # 8000161c <uvmfree>
        return 0;
    80001cec:	4481                	li	s1,0
    80001cee:	b7d5                	j	80001cd2 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf0:	4681                	li	a3,0
    80001cf2:	4605                	li	a2,1
    80001cf4:	040005b7          	lui	a1,0x4000
    80001cf8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cfa:	05b2                	slli	a1,a1,0xc
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	654080e7          	jalr	1620(ra) # 80001352 <uvmunmap>
        uvmfree(pagetable, 0);
    80001d06:	4581                	li	a1,0
    80001d08:	8526                	mv	a0,s1
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	912080e7          	jalr	-1774(ra) # 8000161c <uvmfree>
        return 0;
    80001d12:	4481                	li	s1,0
    80001d14:	bf7d                	j	80001cd2 <proc_pagetable+0x58>

0000000080001d16 <proc_freepagetable>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	84aa                	mv	s1,a0
    80001d24:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d26:	4681                	li	a3,0
    80001d28:	4605                	li	a2,1
    80001d2a:	040005b7          	lui	a1,0x4000
    80001d2e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d30:	05b2                	slli	a1,a1,0xc
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	620080e7          	jalr	1568(ra) # 80001352 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d3a:	4681                	li	a3,0
    80001d3c:	4605                	li	a2,1
    80001d3e:	020005b7          	lui	a1,0x2000
    80001d42:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d44:	05b6                	slli	a1,a1,0xd
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	60a080e7          	jalr	1546(ra) # 80001352 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d50:	85ca                	mv	a1,s2
    80001d52:	8526                	mv	a0,s1
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	8c8080e7          	jalr	-1848(ra) # 8000161c <uvmfree>
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <freeproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	1000                	addi	s0,sp,32
    80001d72:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d74:	6d28                	ld	a0,88(a0)
    80001d76:	c509                	beqz	a0,80001d80 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	c7e080e7          	jalr	-898(ra) # 800009f6 <kfree>
    p->trapframe = 0;
    80001d80:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d84:	68a8                	ld	a0,80(s1)
    80001d86:	c511                	beqz	a0,80001d92 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d88:	64ac                	ld	a1,72(s1)
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	f8c080e7          	jalr	-116(ra) # 80001d16 <proc_freepagetable>
    p->pagetable = 0;
    80001d92:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d96:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d9a:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d9e:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001da2:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001da6:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001daa:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001dae:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001db2:	0004ac23          	sw	zero,24(s1)
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret

0000000080001dc0 <allocproc>:
{
    80001dc0:	1101                	addi	sp,sp,-32
    80001dc2:	ec06                	sd	ra,24(sp)
    80001dc4:	e822                	sd	s0,16(sp)
    80001dc6:	e426                	sd	s1,8(sp)
    80001dc8:	e04a                	sd	s2,0(sp)
    80001dca:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001dcc:	00017497          	auipc	s1,0x17
    80001dd0:	39448493          	addi	s1,s1,916 # 80019160 <proc>
    80001dd4:	0001d917          	auipc	s2,0x1d
    80001dd8:	d8c90913          	addi	s2,s2,-628 # 8001eb60 <tickslock>
        acquire(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	ee8080e7          	jalr	-280(ra) # 80000cc6 <acquire>
        if (p->state == UNUSED)
    80001de6:	4c9c                	lw	a5,24(s1)
    80001de8:	cf81                	beqz	a5,80001e00 <allocproc+0x40>
            release(&p->lock);
    80001dea:	8526                	mv	a0,s1
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	f8e080e7          	jalr	-114(ra) # 80000d7a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001df4:	16848493          	addi	s1,s1,360
    80001df8:	ff2492e3          	bne	s1,s2,80001ddc <allocproc+0x1c>
    return 0;
    80001dfc:	4481                	li	s1,0
    80001dfe:	a889                	j	80001e50 <allocproc+0x90>
    p->pid = allocpid();
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	e34080e7          	jalr	-460(ra) # 80001c34 <allocpid>
    80001e08:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e0a:	4785                	li	a5,1
    80001e0c:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	d7c080e7          	jalr	-644(ra) # 80000b8a <kalloc>
    80001e16:	892a                	mv	s2,a0
    80001e18:	eca8                	sd	a0,88(s1)
    80001e1a:	c131                	beqz	a0,80001e5e <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	e5c080e7          	jalr	-420(ra) # 80001c7a <proc_pagetable>
    80001e26:	892a                	mv	s2,a0
    80001e28:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e2a:	c531                	beqz	a0,80001e76 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e2c:	07000613          	li	a2,112
    80001e30:	4581                	li	a1,0
    80001e32:	06048513          	addi	a0,s1,96
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	f8c080e7          	jalr	-116(ra) # 80000dc2 <memset>
    p->context.ra = (uint64)forkret;
    80001e3e:	00000797          	auipc	a5,0x0
    80001e42:	db078793          	addi	a5,a5,-592 # 80001bee <forkret>
    80001e46:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e48:	60bc                	ld	a5,64(s1)
    80001e4a:	6705                	lui	a4,0x1
    80001e4c:	97ba                	add	a5,a5,a4
    80001e4e:	f4bc                	sd	a5,104(s1)
}
    80001e50:	8526                	mv	a0,s1
    80001e52:	60e2                	ld	ra,24(sp)
    80001e54:	6442                	ld	s0,16(sp)
    80001e56:	64a2                	ld	s1,8(sp)
    80001e58:	6902                	ld	s2,0(sp)
    80001e5a:	6105                	addi	sp,sp,32
    80001e5c:	8082                	ret
        freeproc(p);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	f08080e7          	jalr	-248(ra) # 80001d68 <freeproc>
        release(&p->lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	f10080e7          	jalr	-240(ra) # 80000d7a <release>
        return 0;
    80001e72:	84ca                	mv	s1,s2
    80001e74:	bff1                	j	80001e50 <allocproc+0x90>
        freeproc(p);
    80001e76:	8526                	mv	a0,s1
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	ef0080e7          	jalr	-272(ra) # 80001d68 <freeproc>
        release(&p->lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	ef8080e7          	jalr	-264(ra) # 80000d7a <release>
        return 0;
    80001e8a:	84ca                	mv	s1,s2
    80001e8c:	b7d1                	j	80001e50 <allocproc+0x90>

0000000080001e8e <userinit>:
{
    80001e8e:	1101                	addi	sp,sp,-32
    80001e90:	ec06                	sd	ra,24(sp)
    80001e92:	e822                	sd	s0,16(sp)
    80001e94:	e426                	sd	s1,8(sp)
    80001e96:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	f28080e7          	jalr	-216(ra) # 80001dc0 <allocproc>
    80001ea0:	84aa                	mv	s1,a0
    initproc = p;
    80001ea2:	00007797          	auipc	a5,0x7
    80001ea6:	c0a7bb23          	sd	a0,-1002(a5) # 80008ab8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eaa:	03400613          	li	a2,52
    80001eae:	00007597          	auipc	a1,0x7
    80001eb2:	b7258593          	addi	a1,a1,-1166 # 80008a20 <initcode>
    80001eb6:	6928                	ld	a0,80(a0)
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	58c080e7          	jalr	1420(ra) # 80001444 <uvmfirst>
    p->sz = PGSIZE;
    80001ec0:	6785                	lui	a5,0x1
    80001ec2:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001ec4:	6cb8                	ld	a4,88(s1)
    80001ec6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001eca:	6cb8                	ld	a4,88(s1)
    80001ecc:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ece:	4641                	li	a2,16
    80001ed0:	00006597          	auipc	a1,0x6
    80001ed4:	39058593          	addi	a1,a1,912 # 80008260 <digits+0x210>
    80001ed8:	15848513          	addi	a0,s1,344
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	02e080e7          	jalr	46(ra) # 80000f0a <safestrcpy>
    p->cwd = namei("/");
    80001ee4:	00006517          	auipc	a0,0x6
    80001ee8:	38c50513          	addi	a0,a0,908 # 80008270 <digits+0x220>
    80001eec:	00002097          	auipc	ra,0x2
    80001ef0:	51a080e7          	jalr	1306(ra) # 80004406 <namei>
    80001ef4:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ef8:	478d                	li	a5,3
    80001efa:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	e7c080e7          	jalr	-388(ra) # 80000d7a <release>
}
    80001f06:	60e2                	ld	ra,24(sp)
    80001f08:	6442                	ld	s0,16(sp)
    80001f0a:	64a2                	ld	s1,8(sp)
    80001f0c:	6105                	addi	sp,sp,32
    80001f0e:	8082                	ret

0000000080001f10 <growproc>:
{
    80001f10:	1101                	addi	sp,sp,-32
    80001f12:	ec06                	sd	ra,24(sp)
    80001f14:	e822                	sd	s0,16(sp)
    80001f16:	e426                	sd	s1,8(sp)
    80001f18:	e04a                	sd	s2,0(sp)
    80001f1a:	1000                	addi	s0,sp,32
    80001f1c:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	c98080e7          	jalr	-872(ra) # 80001bb6 <myproc>
    80001f26:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f28:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f2a:	01204c63          	bgtz	s2,80001f42 <growproc+0x32>
    else if (n < 0)
    80001f2e:	02094663          	bltz	s2,80001f5a <growproc+0x4a>
    p->sz = sz;
    80001f32:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f34:	4501                	li	a0,0
}
    80001f36:	60e2                	ld	ra,24(sp)
    80001f38:	6442                	ld	s0,16(sp)
    80001f3a:	64a2                	ld	s1,8(sp)
    80001f3c:	6902                	ld	s2,0(sp)
    80001f3e:	6105                	addi	sp,sp,32
    80001f40:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f42:	4691                	li	a3,4
    80001f44:	00b90633          	add	a2,s2,a1
    80001f48:	6928                	ld	a0,80(a0)
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	5b4080e7          	jalr	1460(ra) # 800014fe <uvmalloc>
    80001f52:	85aa                	mv	a1,a0
    80001f54:	fd79                	bnez	a0,80001f32 <growproc+0x22>
            return -1;
    80001f56:	557d                	li	a0,-1
    80001f58:	bff9                	j	80001f36 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f5a:	00b90633          	add	a2,s2,a1
    80001f5e:	6928                	ld	a0,80(a0)
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	556080e7          	jalr	1366(ra) # 800014b6 <uvmdealloc>
    80001f68:	85aa                	mv	a1,a0
    80001f6a:	b7e1                	j	80001f32 <growproc+0x22>

0000000080001f6c <ps>:
{
    80001f6c:	715d                	addi	sp,sp,-80
    80001f6e:	e486                	sd	ra,72(sp)
    80001f70:	e0a2                	sd	s0,64(sp)
    80001f72:	fc26                	sd	s1,56(sp)
    80001f74:	f84a                	sd	s2,48(sp)
    80001f76:	f44e                	sd	s3,40(sp)
    80001f78:	f052                	sd	s4,32(sp)
    80001f7a:	ec56                	sd	s5,24(sp)
    80001f7c:	e85a                	sd	s6,16(sp)
    80001f7e:	e45e                	sd	s7,8(sp)
    80001f80:	e062                	sd	s8,0(sp)
    80001f82:	0880                	addi	s0,sp,80
    80001f84:	84aa                	mv	s1,a0
    80001f86:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	c2e080e7          	jalr	-978(ra) # 80001bb6 <myproc>
    if (count == 0)
    80001f90:	120b8063          	beqz	s7,800020b0 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001f94:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f98:	003b951b          	slliw	a0,s7,0x3
    80001f9c:	0175053b          	addw	a0,a0,s7
    80001fa0:	0025151b          	slliw	a0,a0,0x2
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	f6c080e7          	jalr	-148(ra) # 80001f10 <growproc>
    80001fac:	10054463          	bltz	a0,800020b4 <ps+0x148>
    struct user_proc loc_result[count];
    80001fb0:	003b9a13          	slli	s4,s7,0x3
    80001fb4:	9a5e                	add	s4,s4,s7
    80001fb6:	0a0a                	slli	s4,s4,0x2
    80001fb8:	00fa0793          	addi	a5,s4,15
    80001fbc:	8391                	srli	a5,a5,0x4
    80001fbe:	0792                	slli	a5,a5,0x4
    80001fc0:	40f10133          	sub	sp,sp,a5
    80001fc4:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001fc6:	007e97b7          	lui	a5,0x7e9
    80001fca:	02f484b3          	mul	s1,s1,a5
    80001fce:	00017797          	auipc	a5,0x17
    80001fd2:	19278793          	addi	a5,a5,402 # 80019160 <proc>
    80001fd6:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001fd8:	0001d797          	auipc	a5,0x1d
    80001fdc:	b8878793          	addi	a5,a5,-1144 # 8001eb60 <tickslock>
    80001fe0:	0cf4fc63          	bgeu	s1,a5,800020b8 <ps+0x14c>
        if (localCount == count)
    80001fe4:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001fe8:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001fea:	8c3e                	mv	s8,a5
    80001fec:	a069                	j	80002076 <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80001fee:	00399793          	slli	a5,s3,0x3
    80001ff2:	97ce                	add	a5,a5,s3
    80001ff4:	078a                	slli	a5,a5,0x2
    80001ff6:	97d6                	add	a5,a5,s5
    80001ff8:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	d7c080e7          	jalr	-644(ra) # 80000d7a <release>
    if (localCount < count)
    80002006:	0179f963          	bgeu	s3,s7,80002018 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    8000200a:	00399793          	slli	a5,s3,0x3
    8000200e:	97ce                	add	a5,a5,s3
    80002010:	078a                	slli	a5,a5,0x2
    80002012:	97d6                	add	a5,a5,s5
    80002014:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80002018:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	b9c080e7          	jalr	-1124(ra) # 80001bb6 <myproc>
    80002022:	86d2                	mv	a3,s4
    80002024:	8656                	mv	a2,s5
    80002026:	85da                	mv	a1,s6
    80002028:	6928                	ld	a0,80(a0)
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	758080e7          	jalr	1880(ra) # 80001782 <copyout>
}
    80002032:	8526                	mv	a0,s1
    80002034:	fb040113          	addi	sp,s0,-80
    80002038:	60a6                	ld	ra,72(sp)
    8000203a:	6406                	ld	s0,64(sp)
    8000203c:	74e2                	ld	s1,56(sp)
    8000203e:	7942                	ld	s2,48(sp)
    80002040:	79a2                	ld	s3,40(sp)
    80002042:	7a02                	ld	s4,32(sp)
    80002044:	6ae2                	ld	s5,24(sp)
    80002046:	6b42                	ld	s6,16(sp)
    80002048:	6ba2                	ld	s7,8(sp)
    8000204a:	6c02                	ld	s8,0(sp)
    8000204c:	6161                	addi	sp,sp,80
    8000204e:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002050:	5b9c                	lw	a5,48(a5)
    80002052:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	d22080e7          	jalr	-734(ra) # 80000d7a <release>
        localCount++;
    80002060:	2985                	addiw	s3,s3,1
    80002062:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002066:	16848493          	addi	s1,s1,360
    8000206a:	f984fee3          	bgeu	s1,s8,80002006 <ps+0x9a>
        if (localCount == count)
    8000206e:	02490913          	addi	s2,s2,36
    80002072:	fb3b83e3          	beq	s7,s3,80002018 <ps+0xac>
        acquire(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c4e080e7          	jalr	-946(ra) # 80000cc6 <acquire>
        if (p->state == UNUSED)
    80002080:	4c9c                	lw	a5,24(s1)
    80002082:	d7b5                	beqz	a5,80001fee <ps+0x82>
        loc_result[localCount].state = p->state;
    80002084:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002088:	549c                	lw	a5,40(s1)
    8000208a:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000208e:	54dc                	lw	a5,44(s1)
    80002090:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002094:	589c                	lw	a5,48(s1)
    80002096:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000209a:	4641                	li	a2,16
    8000209c:	85ca                	mv	a1,s2
    8000209e:	15848513          	addi	a0,s1,344
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	ac4080e7          	jalr	-1340(ra) # 80001b66 <copy_array>
        if (p->parent != 0) // init
    800020aa:	7c9c                	ld	a5,56(s1)
    800020ac:	f3d5                	bnez	a5,80002050 <ps+0xe4>
    800020ae:	b765                	j	80002056 <ps+0xea>
        return result;
    800020b0:	4481                	li	s1,0
    800020b2:	b741                	j	80002032 <ps+0xc6>
        return result;
    800020b4:	4481                	li	s1,0
    800020b6:	bfb5                	j	80002032 <ps+0xc6>
        return result;
    800020b8:	4481                	li	s1,0
    800020ba:	bfa5                	j	80002032 <ps+0xc6>

00000000800020bc <fork>:
{
    800020bc:	7139                	addi	sp,sp,-64
    800020be:	fc06                	sd	ra,56(sp)
    800020c0:	f822                	sd	s0,48(sp)
    800020c2:	f426                	sd	s1,40(sp)
    800020c4:	f04a                	sd	s2,32(sp)
    800020c6:	ec4e                	sd	s3,24(sp)
    800020c8:	e852                	sd	s4,16(sp)
    800020ca:	e456                	sd	s5,8(sp)
    800020cc:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	ae8080e7          	jalr	-1304(ra) # 80001bb6 <myproc>
    800020d6:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	ce8080e7          	jalr	-792(ra) # 80001dc0 <allocproc>
    800020e0:	10050c63          	beqz	a0,800021f8 <fork+0x13c>
    800020e4:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800020e6:	048ab603          	ld	a2,72(s5)
    800020ea:	692c                	ld	a1,80(a0)
    800020ec:	050ab503          	ld	a0,80(s5)
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	566080e7          	jalr	1382(ra) # 80001656 <uvmcopy>
    800020f8:	04054863          	bltz	a0,80002148 <fork+0x8c>
    np->sz = p->sz;
    800020fc:	048ab783          	ld	a5,72(s5)
    80002100:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80002104:	058ab683          	ld	a3,88(s5)
    80002108:	87b6                	mv	a5,a3
    8000210a:	058a3703          	ld	a4,88(s4)
    8000210e:	12068693          	addi	a3,a3,288
    80002112:	0007b803          	ld	a6,0(a5)
    80002116:	6788                	ld	a0,8(a5)
    80002118:	6b8c                	ld	a1,16(a5)
    8000211a:	6f90                	ld	a2,24(a5)
    8000211c:	01073023          	sd	a6,0(a4)
    80002120:	e708                	sd	a0,8(a4)
    80002122:	eb0c                	sd	a1,16(a4)
    80002124:	ef10                	sd	a2,24(a4)
    80002126:	02078793          	addi	a5,a5,32
    8000212a:	02070713          	addi	a4,a4,32
    8000212e:	fed792e3          	bne	a5,a3,80002112 <fork+0x56>
    np->trapframe->a0 = 0;
    80002132:	058a3783          	ld	a5,88(s4)
    80002136:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000213a:	0d0a8493          	addi	s1,s5,208
    8000213e:	0d0a0913          	addi	s2,s4,208
    80002142:	150a8993          	addi	s3,s5,336
    80002146:	a00d                	j	80002168 <fork+0xac>
        freeproc(np);
    80002148:	8552                	mv	a0,s4
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	c1e080e7          	jalr	-994(ra) # 80001d68 <freeproc>
        release(&np->lock);
    80002152:	8552                	mv	a0,s4
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	c26080e7          	jalr	-986(ra) # 80000d7a <release>
        return -1;
    8000215c:	597d                	li	s2,-1
    8000215e:	a059                	j	800021e4 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002160:	04a1                	addi	s1,s1,8
    80002162:	0921                	addi	s2,s2,8
    80002164:	01348b63          	beq	s1,s3,8000217a <fork+0xbe>
        if (p->ofile[i])
    80002168:	6088                	ld	a0,0(s1)
    8000216a:	d97d                	beqz	a0,80002160 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000216c:	00003097          	auipc	ra,0x3
    80002170:	90c080e7          	jalr	-1780(ra) # 80004a78 <filedup>
    80002174:	00a93023          	sd	a0,0(s2)
    80002178:	b7e5                	j	80002160 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000217a:	150ab503          	ld	a0,336(s5)
    8000217e:	00002097          	auipc	ra,0x2
    80002182:	aa4080e7          	jalr	-1372(ra) # 80003c22 <idup>
    80002186:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000218a:	4641                	li	a2,16
    8000218c:	158a8593          	addi	a1,s5,344
    80002190:	158a0513          	addi	a0,s4,344
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	d76080e7          	jalr	-650(ra) # 80000f0a <safestrcpy>
    pid = np->pid;
    8000219c:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800021a0:	8552                	mv	a0,s4
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	bd8080e7          	jalr	-1064(ra) # 80000d7a <release>
    acquire(&wait_lock);
    800021aa:	00017497          	auipc	s1,0x17
    800021ae:	f9e48493          	addi	s1,s1,-98 # 80019148 <wait_lock>
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	b12080e7          	jalr	-1262(ra) # 80000cc6 <acquire>
    np->parent = p;
    800021bc:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	bb8080e7          	jalr	-1096(ra) # 80000d7a <release>
    acquire(&np->lock);
    800021ca:	8552                	mv	a0,s4
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	afa080e7          	jalr	-1286(ra) # 80000cc6 <acquire>
    np->state = RUNNABLE;
    800021d4:	478d                	li	a5,3
    800021d6:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800021da:	8552                	mv	a0,s4
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	b9e080e7          	jalr	-1122(ra) # 80000d7a <release>
}
    800021e4:	854a                	mv	a0,s2
    800021e6:	70e2                	ld	ra,56(sp)
    800021e8:	7442                	ld	s0,48(sp)
    800021ea:	74a2                	ld	s1,40(sp)
    800021ec:	7902                	ld	s2,32(sp)
    800021ee:	69e2                	ld	s3,24(sp)
    800021f0:	6a42                	ld	s4,16(sp)
    800021f2:	6aa2                	ld	s5,8(sp)
    800021f4:	6121                	addi	sp,sp,64
    800021f6:	8082                	ret
        return -1;
    800021f8:	597d                	li	s2,-1
    800021fa:	b7ed                	j	800021e4 <fork+0x128>

00000000800021fc <scheduler>:
{
    800021fc:	1101                	addi	sp,sp,-32
    800021fe:	ec06                	sd	ra,24(sp)
    80002200:	e822                	sd	s0,16(sp)
    80002202:	e426                	sd	s1,8(sp)
    80002204:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    80002206:	00007497          	auipc	s1,0x7
    8000220a:	80248493          	addi	s1,s1,-2046 # 80008a08 <sched_pointer>
    8000220e:	609c                	ld	a5,0(s1)
    80002210:	9782                	jalr	a5
    while (1)
    80002212:	bff5                	j	8000220e <scheduler+0x12>

0000000080002214 <sched>:
{
    80002214:	7179                	addi	sp,sp,-48
    80002216:	f406                	sd	ra,40(sp)
    80002218:	f022                	sd	s0,32(sp)
    8000221a:	ec26                	sd	s1,24(sp)
    8000221c:	e84a                	sd	s2,16(sp)
    8000221e:	e44e                	sd	s3,8(sp)
    80002220:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	994080e7          	jalr	-1644(ra) # 80001bb6 <myproc>
    8000222a:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a20080e7          	jalr	-1504(ra) # 80000c4c <holding>
    80002234:	c53d                	beqz	a0,800022a2 <sched+0x8e>
    80002236:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002238:	2781                	sext.w	a5,a5
    8000223a:	079e                	slli	a5,a5,0x7
    8000223c:	00017717          	auipc	a4,0x17
    80002240:	af470713          	addi	a4,a4,-1292 # 80018d30 <cpus>
    80002244:	97ba                	add	a5,a5,a4
    80002246:	5fb8                	lw	a4,120(a5)
    80002248:	4785                	li	a5,1
    8000224a:	06f71463          	bne	a4,a5,800022b2 <sched+0x9e>
    if (p->state == RUNNING)
    8000224e:	4c98                	lw	a4,24(s1)
    80002250:	4791                	li	a5,4
    80002252:	06f70863          	beq	a4,a5,800022c2 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002256:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000225a:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000225c:	ebbd                	bnez	a5,800022d2 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000225e:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002260:	00017917          	auipc	s2,0x17
    80002264:	ad090913          	addi	s2,s2,-1328 # 80018d30 <cpus>
    80002268:	2781                	sext.w	a5,a5
    8000226a:	079e                	slli	a5,a5,0x7
    8000226c:	97ca                	add	a5,a5,s2
    8000226e:	07c7a983          	lw	s3,124(a5)
    80002272:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002274:	2581                	sext.w	a1,a1
    80002276:	059e                	slli	a1,a1,0x7
    80002278:	05a1                	addi	a1,a1,8
    8000227a:	95ca                	add	a1,a1,s2
    8000227c:	06048513          	addi	a0,s1,96
    80002280:	00000097          	auipc	ra,0x0
    80002284:	74c080e7          	jalr	1868(ra) # 800029cc <swtch>
    80002288:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000228a:	2781                	sext.w	a5,a5
    8000228c:	079e                	slli	a5,a5,0x7
    8000228e:	993e                	add	s2,s2,a5
    80002290:	07392e23          	sw	s3,124(s2)
}
    80002294:	70a2                	ld	ra,40(sp)
    80002296:	7402                	ld	s0,32(sp)
    80002298:	64e2                	ld	s1,24(sp)
    8000229a:	6942                	ld	s2,16(sp)
    8000229c:	69a2                	ld	s3,8(sp)
    8000229e:	6145                	addi	sp,sp,48
    800022a0:	8082                	ret
        panic("sched p->lock");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	fd650513          	addi	a0,a0,-42 # 80008278 <digits+0x228>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	292080e7          	jalr	658(ra) # 8000053c <panic>
        panic("sched locks");
    800022b2:	00006517          	auipc	a0,0x6
    800022b6:	fd650513          	addi	a0,a0,-42 # 80008288 <digits+0x238>
    800022ba:	ffffe097          	auipc	ra,0xffffe
    800022be:	282080e7          	jalr	642(ra) # 8000053c <panic>
        panic("sched running");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	fd650513          	addi	a0,a0,-42 # 80008298 <digits+0x248>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	272080e7          	jalr	626(ra) # 8000053c <panic>
        panic("sched interruptible");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	fd650513          	addi	a0,a0,-42 # 800082a8 <digits+0x258>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	262080e7          	jalr	610(ra) # 8000053c <panic>

00000000800022e2 <yield>:
{
    800022e2:	1101                	addi	sp,sp,-32
    800022e4:	ec06                	sd	ra,24(sp)
    800022e6:	e822                	sd	s0,16(sp)
    800022e8:	e426                	sd	s1,8(sp)
    800022ea:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	8ca080e7          	jalr	-1846(ra) # 80001bb6 <myproc>
    800022f4:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	9d0080e7          	jalr	-1584(ra) # 80000cc6 <acquire>
    p->state = RUNNABLE;
    800022fe:	478d                	li	a5,3
    80002300:	cc9c                	sw	a5,24(s1)
    sched();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	f12080e7          	jalr	-238(ra) # 80002214 <sched>
    release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	a6e080e7          	jalr	-1426(ra) # 80000d7a <release>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000231e:	7179                	addi	sp,sp,-48
    80002320:	f406                	sd	ra,40(sp)
    80002322:	f022                	sd	s0,32(sp)
    80002324:	ec26                	sd	s1,24(sp)
    80002326:	e84a                	sd	s2,16(sp)
    80002328:	e44e                	sd	s3,8(sp)
    8000232a:	1800                	addi	s0,sp,48
    8000232c:	89aa                	mv	s3,a0
    8000232e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002330:	00000097          	auipc	ra,0x0
    80002334:	886080e7          	jalr	-1914(ra) # 80001bb6 <myproc>
    80002338:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	98c080e7          	jalr	-1652(ra) # 80000cc6 <acquire>
    release(lk);
    80002342:	854a                	mv	a0,s2
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	a36080e7          	jalr	-1482(ra) # 80000d7a <release>

    // Go to sleep.
    p->chan = chan;
    8000234c:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002350:	4789                	li	a5,2
    80002352:	cc9c                	sw	a5,24(s1)

    sched();
    80002354:	00000097          	auipc	ra,0x0
    80002358:	ec0080e7          	jalr	-320(ra) # 80002214 <sched>

    // Tidy up.
    p->chan = 0;
    8000235c:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	a18080e7          	jalr	-1512(ra) # 80000d7a <release>
    acquire(lk);
    8000236a:	854a                	mv	a0,s2
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	95a080e7          	jalr	-1702(ra) # 80000cc6 <acquire>
}
    80002374:	70a2                	ld	ra,40(sp)
    80002376:	7402                	ld	s0,32(sp)
    80002378:	64e2                	ld	s1,24(sp)
    8000237a:	6942                	ld	s2,16(sp)
    8000237c:	69a2                	ld	s3,8(sp)
    8000237e:	6145                	addi	sp,sp,48
    80002380:	8082                	ret

0000000080002382 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002382:	7139                	addi	sp,sp,-64
    80002384:	fc06                	sd	ra,56(sp)
    80002386:	f822                	sd	s0,48(sp)
    80002388:	f426                	sd	s1,40(sp)
    8000238a:	f04a                	sd	s2,32(sp)
    8000238c:	ec4e                	sd	s3,24(sp)
    8000238e:	e852                	sd	s4,16(sp)
    80002390:	e456                	sd	s5,8(sp)
    80002392:	0080                	addi	s0,sp,64
    80002394:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002396:	00017497          	auipc	s1,0x17
    8000239a:	dca48493          	addi	s1,s1,-566 # 80019160 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000239e:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023a0:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023a2:	0001c917          	auipc	s2,0x1c
    800023a6:	7be90913          	addi	s2,s2,1982 # 8001eb60 <tickslock>
    800023aa:	a811                	j	800023be <wakeup+0x3c>
            }
            release(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	9cc080e7          	jalr	-1588(ra) # 80000d7a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023b6:	16848493          	addi	s1,s1,360
    800023ba:	03248663          	beq	s1,s2,800023e6 <wakeup+0x64>
        if (p != myproc())
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	7f8080e7          	jalr	2040(ra) # 80001bb6 <myproc>
    800023c6:	fea488e3          	beq	s1,a0,800023b6 <wakeup+0x34>
            acquire(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8fa080e7          	jalr	-1798(ra) # 80000cc6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800023d4:	4c9c                	lw	a5,24(s1)
    800023d6:	fd379be3          	bne	a5,s3,800023ac <wakeup+0x2a>
    800023da:	709c                	ld	a5,32(s1)
    800023dc:	fd4798e3          	bne	a5,s4,800023ac <wakeup+0x2a>
                p->state = RUNNABLE;
    800023e0:	0154ac23          	sw	s5,24(s1)
    800023e4:	b7e1                	j	800023ac <wakeup+0x2a>
        }
    }
}
    800023e6:	70e2                	ld	ra,56(sp)
    800023e8:	7442                	ld	s0,48(sp)
    800023ea:	74a2                	ld	s1,40(sp)
    800023ec:	7902                	ld	s2,32(sp)
    800023ee:	69e2                	ld	s3,24(sp)
    800023f0:	6a42                	ld	s4,16(sp)
    800023f2:	6aa2                	ld	s5,8(sp)
    800023f4:	6121                	addi	sp,sp,64
    800023f6:	8082                	ret

00000000800023f8 <reparent>:
{
    800023f8:	7179                	addi	sp,sp,-48
    800023fa:	f406                	sd	ra,40(sp)
    800023fc:	f022                	sd	s0,32(sp)
    800023fe:	ec26                	sd	s1,24(sp)
    80002400:	e84a                	sd	s2,16(sp)
    80002402:	e44e                	sd	s3,8(sp)
    80002404:	e052                	sd	s4,0(sp)
    80002406:	1800                	addi	s0,sp,48
    80002408:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240a:	00017497          	auipc	s1,0x17
    8000240e:	d5648493          	addi	s1,s1,-682 # 80019160 <proc>
            pp->parent = initproc;
    80002412:	00006a17          	auipc	s4,0x6
    80002416:	6a6a0a13          	addi	s4,s4,1702 # 80008ab8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241a:	0001c997          	auipc	s3,0x1c
    8000241e:	74698993          	addi	s3,s3,1862 # 8001eb60 <tickslock>
    80002422:	a029                	j	8000242c <reparent+0x34>
    80002424:	16848493          	addi	s1,s1,360
    80002428:	01348d63          	beq	s1,s3,80002442 <reparent+0x4a>
        if (pp->parent == p)
    8000242c:	7c9c                	ld	a5,56(s1)
    8000242e:	ff279be3          	bne	a5,s2,80002424 <reparent+0x2c>
            pp->parent = initproc;
    80002432:	000a3503          	ld	a0,0(s4)
    80002436:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	f4a080e7          	jalr	-182(ra) # 80002382 <wakeup>
    80002440:	b7d5                	j	80002424 <reparent+0x2c>
}
    80002442:	70a2                	ld	ra,40(sp)
    80002444:	7402                	ld	s0,32(sp)
    80002446:	64e2                	ld	s1,24(sp)
    80002448:	6942                	ld	s2,16(sp)
    8000244a:	69a2                	ld	s3,8(sp)
    8000244c:	6a02                	ld	s4,0(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret

0000000080002452 <exit>:
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	752080e7          	jalr	1874(ra) # 80001bb6 <myproc>
    8000246c:	89aa                	mv	s3,a0
    if (p == initproc)
    8000246e:	00006797          	auipc	a5,0x6
    80002472:	64a7b783          	ld	a5,1610(a5) # 80008ab8 <initproc>
    80002476:	0d050493          	addi	s1,a0,208
    8000247a:	15050913          	addi	s2,a0,336
    8000247e:	02a79363          	bne	a5,a0,800024a4 <exit+0x52>
        panic("init exiting");
    80002482:	00006517          	auipc	a0,0x6
    80002486:	e3e50513          	addi	a0,a0,-450 # 800082c0 <digits+0x270>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	0b2080e7          	jalr	178(ra) # 8000053c <panic>
            fileclose(f);
    80002492:	00002097          	auipc	ra,0x2
    80002496:	638080e7          	jalr	1592(ra) # 80004aca <fileclose>
            p->ofile[fd] = 0;
    8000249a:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000249e:	04a1                	addi	s1,s1,8
    800024a0:	01248563          	beq	s1,s2,800024aa <exit+0x58>
        if (p->ofile[fd])
    800024a4:	6088                	ld	a0,0(s1)
    800024a6:	f575                	bnez	a0,80002492 <exit+0x40>
    800024a8:	bfdd                	j	8000249e <exit+0x4c>
    begin_op();
    800024aa:	00002097          	auipc	ra,0x2
    800024ae:	15c080e7          	jalr	348(ra) # 80004606 <begin_op>
    iput(p->cwd);
    800024b2:	1509b503          	ld	a0,336(s3)
    800024b6:	00002097          	auipc	ra,0x2
    800024ba:	964080e7          	jalr	-1692(ra) # 80003e1a <iput>
    end_op();
    800024be:	00002097          	auipc	ra,0x2
    800024c2:	1c2080e7          	jalr	450(ra) # 80004680 <end_op>
    p->cwd = 0;
    800024c6:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800024ca:	00017497          	auipc	s1,0x17
    800024ce:	c7e48493          	addi	s1,s1,-898 # 80019148 <wait_lock>
    800024d2:	8526                	mv	a0,s1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	7f2080e7          	jalr	2034(ra) # 80000cc6 <acquire>
    reparent(p);
    800024dc:	854e                	mv	a0,s3
    800024de:	00000097          	auipc	ra,0x0
    800024e2:	f1a080e7          	jalr	-230(ra) # 800023f8 <reparent>
    wakeup(p->parent);
    800024e6:	0389b503          	ld	a0,56(s3)
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	e98080e7          	jalr	-360(ra) # 80002382 <wakeup>
    acquire(&p->lock);
    800024f2:	854e                	mv	a0,s3
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7d2080e7          	jalr	2002(ra) # 80000cc6 <acquire>
    p->xstate = status;
    800024fc:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002500:	4795                	li	a5,5
    80002502:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002506:	8526                	mv	a0,s1
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	872080e7          	jalr	-1934(ra) # 80000d7a <release>
    sched();
    80002510:	00000097          	auipc	ra,0x0
    80002514:	d04080e7          	jalr	-764(ra) # 80002214 <sched>
    panic("zombie exit");
    80002518:	00006517          	auipc	a0,0x6
    8000251c:	db850513          	addi	a0,a0,-584 # 800082d0 <digits+0x280>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	01c080e7          	jalr	28(ra) # 8000053c <panic>

0000000080002528 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002528:	7179                	addi	sp,sp,-48
    8000252a:	f406                	sd	ra,40(sp)
    8000252c:	f022                	sd	s0,32(sp)
    8000252e:	ec26                	sd	s1,24(sp)
    80002530:	e84a                	sd	s2,16(sp)
    80002532:	e44e                	sd	s3,8(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002538:	00017497          	auipc	s1,0x17
    8000253c:	c2848493          	addi	s1,s1,-984 # 80019160 <proc>
    80002540:	0001c997          	auipc	s3,0x1c
    80002544:	62098993          	addi	s3,s3,1568 # 8001eb60 <tickslock>
    {
        acquire(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	77c080e7          	jalr	1916(ra) # 80000cc6 <acquire>
        if (p->pid == pid)
    80002552:	589c                	lw	a5,48(s1)
    80002554:	01278d63          	beq	a5,s2,8000256e <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	820080e7          	jalr	-2016(ra) # 80000d7a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002562:	16848493          	addi	s1,s1,360
    80002566:	ff3491e3          	bne	s1,s3,80002548 <kill+0x20>
    }
    return -1;
    8000256a:	557d                	li	a0,-1
    8000256c:	a829                	j	80002586 <kill+0x5e>
            p->killed = 1;
    8000256e:	4785                	li	a5,1
    80002570:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002572:	4c98                	lw	a4,24(s1)
    80002574:	4789                	li	a5,2
    80002576:	00f70f63          	beq	a4,a5,80002594 <kill+0x6c>
            release(&p->lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	7fe080e7          	jalr	2046(ra) # 80000d7a <release>
            return 0;
    80002584:	4501                	li	a0,0
}
    80002586:	70a2                	ld	ra,40(sp)
    80002588:	7402                	ld	s0,32(sp)
    8000258a:	64e2                	ld	s1,24(sp)
    8000258c:	6942                	ld	s2,16(sp)
    8000258e:	69a2                	ld	s3,8(sp)
    80002590:	6145                	addi	sp,sp,48
    80002592:	8082                	ret
                p->state = RUNNABLE;
    80002594:	478d                	li	a5,3
    80002596:	cc9c                	sw	a5,24(s1)
    80002598:	b7cd                	j	8000257a <kill+0x52>

000000008000259a <setkilled>:

void setkilled(struct proc *p)
{
    8000259a:	1101                	addi	sp,sp,-32
    8000259c:	ec06                	sd	ra,24(sp)
    8000259e:	e822                	sd	s0,16(sp)
    800025a0:	e426                	sd	s1,8(sp)
    800025a2:	1000                	addi	s0,sp,32
    800025a4:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	720080e7          	jalr	1824(ra) # 80000cc6 <acquire>
    p->killed = 1;
    800025ae:	4785                	li	a5,1
    800025b0:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	7c6080e7          	jalr	1990(ra) # 80000d7a <release>
}
    800025bc:	60e2                	ld	ra,24(sp)
    800025be:	6442                	ld	s0,16(sp)
    800025c0:	64a2                	ld	s1,8(sp)
    800025c2:	6105                	addi	sp,sp,32
    800025c4:	8082                	ret

00000000800025c6 <killed>:

int killed(struct proc *p)
{
    800025c6:	1101                	addi	sp,sp,-32
    800025c8:	ec06                	sd	ra,24(sp)
    800025ca:	e822                	sd	s0,16(sp)
    800025cc:	e426                	sd	s1,8(sp)
    800025ce:	e04a                	sd	s2,0(sp)
    800025d0:	1000                	addi	s0,sp,32
    800025d2:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6f2080e7          	jalr	1778(ra) # 80000cc6 <acquire>
    k = p->killed;
    800025dc:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	798080e7          	jalr	1944(ra) # 80000d7a <release>
    return k;
}
    800025ea:	854a                	mv	a0,s2
    800025ec:	60e2                	ld	ra,24(sp)
    800025ee:	6442                	ld	s0,16(sp)
    800025f0:	64a2                	ld	s1,8(sp)
    800025f2:	6902                	ld	s2,0(sp)
    800025f4:	6105                	addi	sp,sp,32
    800025f6:	8082                	ret

00000000800025f8 <wait>:
{
    800025f8:	715d                	addi	sp,sp,-80
    800025fa:	e486                	sd	ra,72(sp)
    800025fc:	e0a2                	sd	s0,64(sp)
    800025fe:	fc26                	sd	s1,56(sp)
    80002600:	f84a                	sd	s2,48(sp)
    80002602:	f44e                	sd	s3,40(sp)
    80002604:	f052                	sd	s4,32(sp)
    80002606:	ec56                	sd	s5,24(sp)
    80002608:	e85a                	sd	s6,16(sp)
    8000260a:	e45e                	sd	s7,8(sp)
    8000260c:	e062                	sd	s8,0(sp)
    8000260e:	0880                	addi	s0,sp,80
    80002610:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	5a4080e7          	jalr	1444(ra) # 80001bb6 <myproc>
    8000261a:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000261c:	00017517          	auipc	a0,0x17
    80002620:	b2c50513          	addi	a0,a0,-1236 # 80019148 <wait_lock>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	6a2080e7          	jalr	1698(ra) # 80000cc6 <acquire>
        havekids = 0;
    8000262c:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000262e:	4a15                	li	s4,5
                havekids = 1;
    80002630:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002632:	0001c997          	auipc	s3,0x1c
    80002636:	52e98993          	addi	s3,s3,1326 # 8001eb60 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000263a:	00017c17          	auipc	s8,0x17
    8000263e:	b0ec0c13          	addi	s8,s8,-1266 # 80019148 <wait_lock>
    80002642:	a0d1                	j	80002706 <wait+0x10e>
                    pid = pp->pid;
    80002644:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002648:	000b0e63          	beqz	s6,80002664 <wait+0x6c>
    8000264c:	4691                	li	a3,4
    8000264e:	02c48613          	addi	a2,s1,44
    80002652:	85da                	mv	a1,s6
    80002654:	05093503          	ld	a0,80(s2)
    80002658:	fffff097          	auipc	ra,0xfffff
    8000265c:	12a080e7          	jalr	298(ra) # 80001782 <copyout>
    80002660:	04054163          	bltz	a0,800026a2 <wait+0xaa>
                    freeproc(pp);
    80002664:	8526                	mv	a0,s1
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	702080e7          	jalr	1794(ra) # 80001d68 <freeproc>
                    release(&pp->lock);
    8000266e:	8526                	mv	a0,s1
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	70a080e7          	jalr	1802(ra) # 80000d7a <release>
                    release(&wait_lock);
    80002678:	00017517          	auipc	a0,0x17
    8000267c:	ad050513          	addi	a0,a0,-1328 # 80019148 <wait_lock>
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	6fa080e7          	jalr	1786(ra) # 80000d7a <release>
}
    80002688:	854e                	mv	a0,s3
    8000268a:	60a6                	ld	ra,72(sp)
    8000268c:	6406                	ld	s0,64(sp)
    8000268e:	74e2                	ld	s1,56(sp)
    80002690:	7942                	ld	s2,48(sp)
    80002692:	79a2                	ld	s3,40(sp)
    80002694:	7a02                	ld	s4,32(sp)
    80002696:	6ae2                	ld	s5,24(sp)
    80002698:	6b42                	ld	s6,16(sp)
    8000269a:	6ba2                	ld	s7,8(sp)
    8000269c:	6c02                	ld	s8,0(sp)
    8000269e:	6161                	addi	sp,sp,80
    800026a0:	8082                	ret
                        release(&pp->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	6d6080e7          	jalr	1750(ra) # 80000d7a <release>
                        release(&wait_lock);
    800026ac:	00017517          	auipc	a0,0x17
    800026b0:	a9c50513          	addi	a0,a0,-1380 # 80019148 <wait_lock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	6c6080e7          	jalr	1734(ra) # 80000d7a <release>
                        return -1;
    800026bc:	59fd                	li	s3,-1
    800026be:	b7e9                	j	80002688 <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c0:	16848493          	addi	s1,s1,360
    800026c4:	03348463          	beq	s1,s3,800026ec <wait+0xf4>
            if (pp->parent == p)
    800026c8:	7c9c                	ld	a5,56(s1)
    800026ca:	ff279be3          	bne	a5,s2,800026c0 <wait+0xc8>
                acquire(&pp->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5f6080e7          	jalr	1526(ra) # 80000cc6 <acquire>
                if (pp->state == ZOMBIE)
    800026d8:	4c9c                	lw	a5,24(s1)
    800026da:	f74785e3          	beq	a5,s4,80002644 <wait+0x4c>
                release(&pp->lock);
    800026de:	8526                	mv	a0,s1
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	69a080e7          	jalr	1690(ra) # 80000d7a <release>
                havekids = 1;
    800026e8:	8756                	mv	a4,s5
    800026ea:	bfd9                	j	800026c0 <wait+0xc8>
        if (!havekids || killed(p))
    800026ec:	c31d                	beqz	a4,80002712 <wait+0x11a>
    800026ee:	854a                	mv	a0,s2
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	ed6080e7          	jalr	-298(ra) # 800025c6 <killed>
    800026f8:	ed09                	bnez	a0,80002712 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026fa:	85e2                	mv	a1,s8
    800026fc:	854a                	mv	a0,s2
    800026fe:	00000097          	auipc	ra,0x0
    80002702:	c20080e7          	jalr	-992(ra) # 8000231e <sleep>
        havekids = 0;
    80002706:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002708:	00017497          	auipc	s1,0x17
    8000270c:	a5848493          	addi	s1,s1,-1448 # 80019160 <proc>
    80002710:	bf65                	j	800026c8 <wait+0xd0>
            release(&wait_lock);
    80002712:	00017517          	auipc	a0,0x17
    80002716:	a3650513          	addi	a0,a0,-1482 # 80019148 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	660080e7          	jalr	1632(ra) # 80000d7a <release>
            return -1;
    80002722:	59fd                	li	s3,-1
    80002724:	b795                	j	80002688 <wait+0x90>

0000000080002726 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002726:	7179                	addi	sp,sp,-48
    80002728:	f406                	sd	ra,40(sp)
    8000272a:	f022                	sd	s0,32(sp)
    8000272c:	ec26                	sd	s1,24(sp)
    8000272e:	e84a                	sd	s2,16(sp)
    80002730:	e44e                	sd	s3,8(sp)
    80002732:	e052                	sd	s4,0(sp)
    80002734:	1800                	addi	s0,sp,48
    80002736:	84aa                	mv	s1,a0
    80002738:	892e                	mv	s2,a1
    8000273a:	89b2                	mv	s3,a2
    8000273c:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	478080e7          	jalr	1144(ra) # 80001bb6 <myproc>
    if (user_dst)
    80002746:	c08d                	beqz	s1,80002768 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002748:	86d2                	mv	a3,s4
    8000274a:	864e                	mv	a2,s3
    8000274c:	85ca                	mv	a1,s2
    8000274e:	6928                	ld	a0,80(a0)
    80002750:	fffff097          	auipc	ra,0xfffff
    80002754:	032080e7          	jalr	50(ra) # 80001782 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002758:	70a2                	ld	ra,40(sp)
    8000275a:	7402                	ld	s0,32(sp)
    8000275c:	64e2                	ld	s1,24(sp)
    8000275e:	6942                	ld	s2,16(sp)
    80002760:	69a2                	ld	s3,8(sp)
    80002762:	6a02                	ld	s4,0(sp)
    80002764:	6145                	addi	sp,sp,48
    80002766:	8082                	ret
        memmove((char *)dst, src, len);
    80002768:	000a061b          	sext.w	a2,s4
    8000276c:	85ce                	mv	a1,s3
    8000276e:	854a                	mv	a0,s2
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	6ae080e7          	jalr	1710(ra) # 80000e1e <memmove>
        return 0;
    80002778:	8526                	mv	a0,s1
    8000277a:	bff9                	j	80002758 <either_copyout+0x32>

000000008000277c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000277c:	7179                	addi	sp,sp,-48
    8000277e:	f406                	sd	ra,40(sp)
    80002780:	f022                	sd	s0,32(sp)
    80002782:	ec26                	sd	s1,24(sp)
    80002784:	e84a                	sd	s2,16(sp)
    80002786:	e44e                	sd	s3,8(sp)
    80002788:	e052                	sd	s4,0(sp)
    8000278a:	1800                	addi	s0,sp,48
    8000278c:	892a                	mv	s2,a0
    8000278e:	84ae                	mv	s1,a1
    80002790:	89b2                	mv	s3,a2
    80002792:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002794:	fffff097          	auipc	ra,0xfffff
    80002798:	422080e7          	jalr	1058(ra) # 80001bb6 <myproc>
    if (user_src)
    8000279c:	c08d                	beqz	s1,800027be <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000279e:	86d2                	mv	a3,s4
    800027a0:	864e                	mv	a2,s3
    800027a2:	85ca                	mv	a1,s2
    800027a4:	6928                	ld	a0,80(a0)
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	068080e7          	jalr	104(ra) # 8000180e <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027ae:	70a2                	ld	ra,40(sp)
    800027b0:	7402                	ld	s0,32(sp)
    800027b2:	64e2                	ld	s1,24(sp)
    800027b4:	6942                	ld	s2,16(sp)
    800027b6:	69a2                	ld	s3,8(sp)
    800027b8:	6a02                	ld	s4,0(sp)
    800027ba:	6145                	addi	sp,sp,48
    800027bc:	8082                	ret
        memmove(dst, (char *)src, len);
    800027be:	000a061b          	sext.w	a2,s4
    800027c2:	85ce                	mv	a1,s3
    800027c4:	854a                	mv	a0,s2
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	658080e7          	jalr	1624(ra) # 80000e1e <memmove>
        return 0;
    800027ce:	8526                	mv	a0,s1
    800027d0:	bff9                	j	800027ae <either_copyin+0x32>

00000000800027d2 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027d2:	715d                	addi	sp,sp,-80
    800027d4:	e486                	sd	ra,72(sp)
    800027d6:	e0a2                	sd	s0,64(sp)
    800027d8:	fc26                	sd	s1,56(sp)
    800027da:	f84a                	sd	s2,48(sp)
    800027dc:	f44e                	sd	s3,40(sp)
    800027de:	f052                	sd	s4,32(sp)
    800027e0:	ec56                	sd	s5,24(sp)
    800027e2:	e85a                	sd	s6,16(sp)
    800027e4:	e45e                	sd	s7,8(sp)
    800027e6:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800027e8:	00006517          	auipc	a0,0x6
    800027ec:	8a050513          	addi	a0,a0,-1888 # 80008088 <digits+0x38>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	da8080e7          	jalr	-600(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027f8:	00017497          	auipc	s1,0x17
    800027fc:	ac048493          	addi	s1,s1,-1344 # 800192b8 <proc+0x158>
    80002800:	0001c917          	auipc	s2,0x1c
    80002804:	4b890913          	addi	s2,s2,1208 # 8001ecb8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002808:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000280a:	00006997          	auipc	s3,0x6
    8000280e:	ad698993          	addi	s3,s3,-1322 # 800082e0 <digits+0x290>
        printf("%d <%s %s", p->pid, state, p->name);
    80002812:	00006a97          	auipc	s5,0x6
    80002816:	ad6a8a93          	addi	s5,s5,-1322 # 800082e8 <digits+0x298>
        printf("\n");
    8000281a:	00006a17          	auipc	s4,0x6
    8000281e:	86ea0a13          	addi	s4,s4,-1938 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002822:	00006b97          	auipc	s7,0x6
    80002826:	beeb8b93          	addi	s7,s7,-1042 # 80008410 <states.0>
    8000282a:	a00d                	j	8000284c <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000282c:	ed86a583          	lw	a1,-296(a3)
    80002830:	8556                	mv	a0,s5
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	d66080e7          	jalr	-666(ra) # 80000598 <printf>
        printf("\n");
    8000283a:	8552                	mv	a0,s4
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d5c080e7          	jalr	-676(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002844:	16848493          	addi	s1,s1,360
    80002848:	03248263          	beq	s1,s2,8000286c <procdump+0x9a>
        if (p->state == UNUSED)
    8000284c:	86a6                	mv	a3,s1
    8000284e:	ec04a783          	lw	a5,-320(s1)
    80002852:	dbed                	beqz	a5,80002844 <procdump+0x72>
            state = "???";
    80002854:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002856:	fcfb6be3          	bltu	s6,a5,8000282c <procdump+0x5a>
    8000285a:	02079713          	slli	a4,a5,0x20
    8000285e:	01d75793          	srli	a5,a4,0x1d
    80002862:	97de                	add	a5,a5,s7
    80002864:	6390                	ld	a2,0(a5)
    80002866:	f279                	bnez	a2,8000282c <procdump+0x5a>
            state = "???";
    80002868:	864e                	mv	a2,s3
    8000286a:	b7c9                	j	8000282c <procdump+0x5a>
    }
}
    8000286c:	60a6                	ld	ra,72(sp)
    8000286e:	6406                	ld	s0,64(sp)
    80002870:	74e2                	ld	s1,56(sp)
    80002872:	7942                	ld	s2,48(sp)
    80002874:	79a2                	ld	s3,40(sp)
    80002876:	7a02                	ld	s4,32(sp)
    80002878:	6ae2                	ld	s5,24(sp)
    8000287a:	6b42                	ld	s6,16(sp)
    8000287c:	6ba2                	ld	s7,8(sp)
    8000287e:	6161                	addi	sp,sp,80
    80002880:	8082                	ret

0000000080002882 <schedls>:

void schedls()
{
    80002882:	1141                	addi	sp,sp,-16
    80002884:	e406                	sd	ra,8(sp)
    80002886:	e022                	sd	s0,0(sp)
    80002888:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	a6e50513          	addi	a0,a0,-1426 # 800082f8 <digits+0x2a8>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	d06080e7          	jalr	-762(ra) # 80000598 <printf>
    printf("====================================\n");
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	a8650513          	addi	a0,a0,-1402 # 80008320 <digits+0x2d0>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	cf6080e7          	jalr	-778(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800028aa:	00006717          	auipc	a4,0x6
    800028ae:	1be73703          	ld	a4,446(a4) # 80008a68 <available_schedulers+0x10>
    800028b2:	00006797          	auipc	a5,0x6
    800028b6:	1567b783          	ld	a5,342(a5) # 80008a08 <sched_pointer>
    800028ba:	04f70663          	beq	a4,a5,80002906 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800028be:	00006517          	auipc	a0,0x6
    800028c2:	a9250513          	addi	a0,a0,-1390 # 80008350 <digits+0x300>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	cd2080e7          	jalr	-814(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800028ce:	00006617          	auipc	a2,0x6
    800028d2:	1a262603          	lw	a2,418(a2) # 80008a70 <available_schedulers+0x18>
    800028d6:	00006597          	auipc	a1,0x6
    800028da:	18258593          	addi	a1,a1,386 # 80008a58 <available_schedulers>
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	a7a50513          	addi	a0,a0,-1414 # 80008358 <digits+0x308>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	cb2080e7          	jalr	-846(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	a7250513          	addi	a0,a0,-1422 # 80008360 <digits+0x310>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	ca2080e7          	jalr	-862(ra) # 80000598 <printf>
}
    800028fe:	60a2                	ld	ra,8(sp)
    80002900:	6402                	ld	s0,0(sp)
    80002902:	0141                	addi	sp,sp,16
    80002904:	8082                	ret
            printf("[*]\t");
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	a4250513          	addi	a0,a0,-1470 # 80008348 <digits+0x2f8>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c8a080e7          	jalr	-886(ra) # 80000598 <printf>
    80002916:	bf65                	j	800028ce <schedls+0x4c>

0000000080002918 <schedset>:

void schedset(int id)
{
    80002918:	1141                	addi	sp,sp,-16
    8000291a:	e406                	sd	ra,8(sp)
    8000291c:	e022                	sd	s0,0(sp)
    8000291e:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002920:	e90d                	bnez	a0,80002952 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002922:	00006797          	auipc	a5,0x6
    80002926:	1467b783          	ld	a5,326(a5) # 80008a68 <available_schedulers+0x10>
    8000292a:	00006717          	auipc	a4,0x6
    8000292e:	0cf73f23          	sd	a5,222(a4) # 80008a08 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002932:	00006597          	auipc	a1,0x6
    80002936:	12658593          	addi	a1,a1,294 # 80008a58 <available_schedulers>
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a6650513          	addi	a0,a0,-1434 # 800083a0 <digits+0x350>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	c56080e7          	jalr	-938(ra) # 80000598 <printf>
}
    8000294a:	60a2                	ld	ra,8(sp)
    8000294c:	6402                	ld	s0,0(sp)
    8000294e:	0141                	addi	sp,sp,16
    80002950:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002952:	00006517          	auipc	a0,0x6
    80002956:	a2650513          	addi	a0,a0,-1498 # 80008378 <digits+0x328>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	c3e080e7          	jalr	-962(ra) # 80000598 <printf>
        return;
    80002962:	b7e5                	j	8000294a <schedset+0x32>

0000000080002964 <proc_va2pa>:

uint64 proc_va2pa(uint64 va, int pid)
{   
    80002964:	1101                	addi	sp,sp,-32
    80002966:	ec06                	sd	ra,24(sp)
    80002968:	e822                	sd	s0,16(sp)
    8000296a:	e426                	sd	s1,8(sp)
    8000296c:	e04a                	sd	s2,0(sp)
    8000296e:	1000                	addi	s0,sp,32
    80002970:	892a                	mv	s2,a0
    80002972:	84ae                	mv	s1,a1
    printf("Executing proc.c va2pa\n");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a5450513          	addi	a0,a0,-1452 # 800083c8 <digits+0x378>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c1c080e7          	jalr	-996(ra) # 80000598 <printf>


    uint64 pa = 0x0;

    struct proc *p;
    if (pid < 0)
    80002984:	0004cf63          	bltz	s1,800029a2 <proc_va2pa+0x3e>
        pa = walkaddr(p->pagetable, va);
        return pa;
    }
    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->pid == pid)
    80002988:	00017797          	auipc	a5,0x17
    8000298c:	8087a783          	lw	a5,-2040(a5) # 80019190 <proc+0x30>
        {
            pa = walkaddr(p->pagetable, va);
            break;
        }
        return pa;
    80002990:	4501                	li	a0,0
        if (p->pid == pid)
    80002992:	02978363          	beq	a5,s1,800029b8 <proc_va2pa+0x54>
    }
    return pa;
}
    80002996:	60e2                	ld	ra,24(sp)
    80002998:	6442                	ld	s0,16(sp)
    8000299a:	64a2                	ld	s1,8(sp)
    8000299c:	6902                	ld	s2,0(sp)
    8000299e:	6105                	addi	sp,sp,32
    800029a0:	8082                	ret
        struct proc *p = myproc();
    800029a2:	fffff097          	auipc	ra,0xfffff
    800029a6:	214080e7          	jalr	532(ra) # 80001bb6 <myproc>
        pa = walkaddr(p->pagetable, va);
    800029aa:	85ca                	mv	a1,s2
    800029ac:	6928                	ld	a0,80(a0)
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	79c080e7          	jalr	1948(ra) # 8000114a <walkaddr>
        return pa;
    800029b6:	b7c5                	j	80002996 <proc_va2pa+0x32>
            pa = walkaddr(p->pagetable, va);
    800029b8:	85ca                	mv	a1,s2
    800029ba:	00016517          	auipc	a0,0x16
    800029be:	7f653503          	ld	a0,2038(a0) # 800191b0 <proc+0x50>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	788080e7          	jalr	1928(ra) # 8000114a <walkaddr>
    return pa;
    800029ca:	b7f1                	j	80002996 <proc_va2pa+0x32>

00000000800029cc <swtch>:
    800029cc:	00153023          	sd	ra,0(a0)
    800029d0:	00253423          	sd	sp,8(a0)
    800029d4:	e900                	sd	s0,16(a0)
    800029d6:	ed04                	sd	s1,24(a0)
    800029d8:	03253023          	sd	s2,32(a0)
    800029dc:	03353423          	sd	s3,40(a0)
    800029e0:	03453823          	sd	s4,48(a0)
    800029e4:	03553c23          	sd	s5,56(a0)
    800029e8:	05653023          	sd	s6,64(a0)
    800029ec:	05753423          	sd	s7,72(a0)
    800029f0:	05853823          	sd	s8,80(a0)
    800029f4:	05953c23          	sd	s9,88(a0)
    800029f8:	07a53023          	sd	s10,96(a0)
    800029fc:	07b53423          	sd	s11,104(a0)
    80002a00:	0005b083          	ld	ra,0(a1)
    80002a04:	0085b103          	ld	sp,8(a1)
    80002a08:	6980                	ld	s0,16(a1)
    80002a0a:	6d84                	ld	s1,24(a1)
    80002a0c:	0205b903          	ld	s2,32(a1)
    80002a10:	0285b983          	ld	s3,40(a1)
    80002a14:	0305ba03          	ld	s4,48(a1)
    80002a18:	0385ba83          	ld	s5,56(a1)
    80002a1c:	0405bb03          	ld	s6,64(a1)
    80002a20:	0485bb83          	ld	s7,72(a1)
    80002a24:	0505bc03          	ld	s8,80(a1)
    80002a28:	0585bc83          	ld	s9,88(a1)
    80002a2c:	0605bd03          	ld	s10,96(a1)
    80002a30:	0685bd83          	ld	s11,104(a1)
    80002a34:	8082                	ret

0000000080002a36 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a36:	1141                	addi	sp,sp,-16
    80002a38:	e406                	sd	ra,8(sp)
    80002a3a:	e022                	sd	s0,0(sp)
    80002a3c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a3e:	00006597          	auipc	a1,0x6
    80002a42:	a0258593          	addi	a1,a1,-1534 # 80008440 <states.0+0x30>
    80002a46:	0001c517          	auipc	a0,0x1c
    80002a4a:	11a50513          	addi	a0,a0,282 # 8001eb60 <tickslock>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	1e8080e7          	jalr	488(ra) # 80000c36 <initlock>
}
    80002a56:	60a2                	ld	ra,8(sp)
    80002a58:	6402                	ld	s0,0(sp)
    80002a5a:	0141                	addi	sp,sp,16
    80002a5c:	8082                	ret

0000000080002a5e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a5e:	1141                	addi	sp,sp,-16
    80002a60:	e422                	sd	s0,8(sp)
    80002a62:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a64:	00003797          	auipc	a5,0x3
    80002a68:	68c78793          	addi	a5,a5,1676 # 800060f0 <kernelvec>
    80002a6c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a70:	6422                	ld	s0,8(sp)
    80002a72:	0141                	addi	sp,sp,16
    80002a74:	8082                	ret

0000000080002a76 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a76:	1141                	addi	sp,sp,-16
    80002a78:	e406                	sd	ra,8(sp)
    80002a7a:	e022                	sd	s0,0(sp)
    80002a7c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	138080e7          	jalr	312(ra) # 80001bb6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a8a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a90:	00004697          	auipc	a3,0x4
    80002a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80002a98:	00004717          	auipc	a4,0x4
    80002a9c:	56870713          	addi	a4,a4,1384 # 80007000 <_trampoline>
    80002aa0:	8f15                	sub	a4,a4,a3
    80002aa2:	040007b7          	lui	a5,0x4000
    80002aa6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002aa8:	07b2                	slli	a5,a5,0xc
    80002aaa:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aac:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ab0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ab2:	18002673          	csrr	a2,satp
    80002ab6:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ab8:	6d30                	ld	a2,88(a0)
    80002aba:	6138                	ld	a4,64(a0)
    80002abc:	6585                	lui	a1,0x1
    80002abe:	972e                	add	a4,a4,a1
    80002ac0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ac2:	6d38                	ld	a4,88(a0)
    80002ac4:	00000617          	auipc	a2,0x0
    80002ac8:	13460613          	addi	a2,a2,308 # 80002bf8 <usertrap>
    80002acc:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ace:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ad0:	8612                	mv	a2,tp
    80002ad2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ad8:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002adc:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ae4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae6:	6f18                	ld	a4,24(a4)
    80002ae8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aec:	6928                	ld	a0,80(a0)
    80002aee:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002af0:	00004717          	auipc	a4,0x4
    80002af4:	5ac70713          	addi	a4,a4,1452 # 8000709c <userret>
    80002af8:	8f15                	sub	a4,a4,a3
    80002afa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002afc:	577d                	li	a4,-1
    80002afe:	177e                	slli	a4,a4,0x3f
    80002b00:	8d59                	or	a0,a0,a4
    80002b02:	9782                	jalr	a5
}
    80002b04:	60a2                	ld	ra,8(sp)
    80002b06:	6402                	ld	s0,0(sp)
    80002b08:	0141                	addi	sp,sp,16
    80002b0a:	8082                	ret

0000000080002b0c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b16:	0001c497          	auipc	s1,0x1c
    80002b1a:	04a48493          	addi	s1,s1,74 # 8001eb60 <tickslock>
    80002b1e:	8526                	mv	a0,s1
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	1a6080e7          	jalr	422(ra) # 80000cc6 <acquire>
  ticks++;
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	f9850513          	addi	a0,a0,-104 # 80008ac0 <ticks>
    80002b30:	411c                	lw	a5,0(a0)
    80002b32:	2785                	addiw	a5,a5,1
    80002b34:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	84c080e7          	jalr	-1972(ra) # 80002382 <wakeup>
  release(&tickslock);
    80002b3e:	8526                	mv	a0,s1
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	23a080e7          	jalr	570(ra) # 80000d7a <release>
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6105                	addi	sp,sp,32
    80002b50:	8082                	ret

0000000080002b52 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b52:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b56:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002b58:	0807df63          	bgez	a5,80002bf6 <devintr+0xa4>
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002b66:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002b6a:	46a5                	li	a3,9
    80002b6c:	00d70d63          	beq	a4,a3,80002b86 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002b70:	577d                	li	a4,-1
    80002b72:	177e                	slli	a4,a4,0x3f
    80002b74:	0705                	addi	a4,a4,1
    return 0;
    80002b76:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b78:	04e78e63          	beq	a5,a4,80002bd4 <devintr+0x82>
  }
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret
    int irq = plic_claim();
    80002b86:	00003097          	auipc	ra,0x3
    80002b8a:	672080e7          	jalr	1650(ra) # 800061f8 <plic_claim>
    80002b8e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b90:	47a9                	li	a5,10
    80002b92:	02f50763          	beq	a0,a5,80002bc0 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002b96:	4785                	li	a5,1
    80002b98:	02f50963          	beq	a0,a5,80002bca <devintr+0x78>
    return 1;
    80002b9c:	4505                	li	a0,1
    } else if(irq){
    80002b9e:	dcf9                	beqz	s1,80002b7c <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ba0:	85a6                	mv	a1,s1
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	8a650513          	addi	a0,a0,-1882 # 80008448 <states.0+0x38>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	9ee080e7          	jalr	-1554(ra) # 80000598 <printf>
      plic_complete(irq);
    80002bb2:	8526                	mv	a0,s1
    80002bb4:	00003097          	auipc	ra,0x3
    80002bb8:	668080e7          	jalr	1640(ra) # 8000621c <plic_complete>
    return 1;
    80002bbc:	4505                	li	a0,1
    80002bbe:	bf7d                	j	80002b7c <devintr+0x2a>
      uartintr();
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	de6080e7          	jalr	-538(ra) # 800009a6 <uartintr>
    if(irq)
    80002bc8:	b7ed                	j	80002bb2 <devintr+0x60>
      virtio_disk_intr();
    80002bca:	00004097          	auipc	ra,0x4
    80002bce:	b18080e7          	jalr	-1256(ra) # 800066e2 <virtio_disk_intr>
    if(irq)
    80002bd2:	b7c5                	j	80002bb2 <devintr+0x60>
    if(cpuid() == 0){
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	fb6080e7          	jalr	-74(ra) # 80001b8a <cpuid>
    80002bdc:	c901                	beqz	a0,80002bec <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bde:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002be2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002be4:	14479073          	csrw	sip,a5
    return 2;
    80002be8:	4509                	li	a0,2
    80002bea:	bf49                	j	80002b7c <devintr+0x2a>
      clockintr();
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	f20080e7          	jalr	-224(ra) # 80002b0c <clockintr>
    80002bf4:	b7ed                	j	80002bde <devintr+0x8c>
}
    80002bf6:	8082                	ret

0000000080002bf8 <usertrap>:
{
    80002bf8:	7139                	addi	sp,sp,-64
    80002bfa:	fc06                	sd	ra,56(sp)
    80002bfc:	f822                	sd	s0,48(sp)
    80002bfe:	f426                	sd	s1,40(sp)
    80002c00:	f04a                	sd	s2,32(sp)
    80002c02:	ec4e                	sd	s3,24(sp)
    80002c04:	e852                	sd	s4,16(sp)
    80002c06:	e456                	sd	s5,8(sp)
    80002c08:	e05a                	sd	s6,0(sp)
    80002c0a:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c10:	1007f793          	andi	a5,a5,256
    80002c14:	efb5                	bnez	a5,80002c90 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c16:	00003797          	auipc	a5,0x3
    80002c1a:	4da78793          	addi	a5,a5,1242 # 800060f0 <kernelvec>
    80002c1e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	f94080e7          	jalr	-108(ra) # 80001bb6 <myproc>
    80002c2a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c2c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2e:	14102773          	csrr	a4,sepc
    80002c32:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c34:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c38:	47a1                	li	a5,8
    80002c3a:	06f70363          	beq	a4,a5,80002ca0 <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	f14080e7          	jalr	-236(ra) # 80002b52 <devintr>
    80002c46:	892a                	mv	s2,a0
    80002c48:	1a051163          	bnez	a0,80002dea <usertrap+0x1f2>
    80002c4c:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) 
    80002c50:	47bd                	li	a5,15
    80002c52:	0af70563          	beq	a4,a5,80002cfc <usertrap+0x104>
    80002c56:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c5a:	5890                	lw	a2,48(s1)
    80002c5c:	00006517          	auipc	a0,0x6
    80002c60:	85450513          	addi	a0,a0,-1964 # 800084b0 <states.0+0xa0>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	934080e7          	jalr	-1740(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c70:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c74:	00006517          	auipc	a0,0x6
    80002c78:	86c50513          	addi	a0,a0,-1940 # 800084e0 <states.0+0xd0>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	91c080e7          	jalr	-1764(ra) # 80000598 <printf>
    setkilled(p);
    80002c84:	8526                	mv	a0,s1
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	914080e7          	jalr	-1772(ra) # 8000259a <setkilled>
    80002c8e:	a825                	j	80002cc6 <usertrap+0xce>
    panic("usertrap: not from user mode");
    80002c90:	00005517          	auipc	a0,0x5
    80002c94:	7d850513          	addi	a0,a0,2008 # 80008468 <states.0+0x58>
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	8a4080e7          	jalr	-1884(ra) # 8000053c <panic>
    if(killed(p))
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	926080e7          	jalr	-1754(ra) # 800025c6 <killed>
    80002ca8:	e521                	bnez	a0,80002cf0 <usertrap+0xf8>
    p->trapframe->epc += 4;
    80002caa:	6cb8                	ld	a4,88(s1)
    80002cac:	6f1c                	ld	a5,24(a4)
    80002cae:	0791                	addi	a5,a5,4
    80002cb0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cba:	10079073          	csrw	sstatus,a5
    syscall();
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	3a0080e7          	jalr	928(ra) # 8000305e <syscall>
  if(killed(p))
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	8fe080e7          	jalr	-1794(ra) # 800025c6 <killed>
    80002cd0:	12051463          	bnez	a0,80002df8 <usertrap+0x200>
  usertrapret();
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	da2080e7          	jalr	-606(ra) # 80002a76 <usertrapret>
}
    80002cdc:	70e2                	ld	ra,56(sp)
    80002cde:	7442                	ld	s0,48(sp)
    80002ce0:	74a2                	ld	s1,40(sp)
    80002ce2:	7902                	ld	s2,32(sp)
    80002ce4:	69e2                	ld	s3,24(sp)
    80002ce6:	6a42                	ld	s4,16(sp)
    80002ce8:	6aa2                	ld	s5,8(sp)
    80002cea:	6b02                	ld	s6,0(sp)
    80002cec:	6121                	addi	sp,sp,64
    80002cee:	8082                	ret
      exit(-1);
    80002cf0:	557d                	li	a0,-1
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	760080e7          	jalr	1888(ra) # 80002452 <exit>
    80002cfa:	bf45                	j	80002caa <usertrap+0xb2>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfc:	143029f3          	csrr	s3,stval
    pagetable_t pagetable = p->pagetable;
    80002d00:	0504ba83          	ld	s5,80(s1)
    pte_t *pte = walk(p->pagetable, va, 0);
    80002d04:	4601                	li	a2,0
    80002d06:	85ce                	mv	a1,s3
    80002d08:	8556                	mv	a0,s5
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	39a080e7          	jalr	922(ra) # 800010a4 <walk>
    80002d12:	892a                	mv	s2,a0
    *pte = (*pte >> 1) << 1;
    80002d14:	611c                	ld	a5,0(a0)
    80002d16:	9bf9                	andi	a5,a5,-2
    80002d18:	e11c                	sd	a5,0(a0)
    uint64 pa = PTE2PA(*pte);
    80002d1a:	00a7da13          	srli	s4,a5,0xa
    if(parefs[ppn] > 1) {
    80002d1e:	0000e717          	auipc	a4,0xe
    80002d22:	01270713          	addi	a4,a4,18 # 80010d30 <parefs>
    80002d26:	9752                	add	a4,a4,s4
    80002d28:	00074703          	lbu	a4,0(a4)
    80002d2c:	4685                	li	a3,1
    80002d2e:	00e6ec63          	bltu	a3,a4,80002d46 <usertrap+0x14e>
        *pte = *pte | PTE_W;
    80002d32:	0047e793          	ori	a5,a5,4
    80002d36:	e11c                	sd	a5,0(a0)
      *pte = *pte |PTE_V;
    80002d38:	00093783          	ld	a5,0(s2)
    80002d3c:	0017e793          	ori	a5,a5,1
    80002d40:	00f93023          	sd	a5,0(s2)
    80002d44:	b749                	j	80002cc6 <usertrap+0xce>
      parefs[ppn]--;
    80002d46:	0000e797          	auipc	a5,0xe
    80002d4a:	fea78793          	addi	a5,a5,-22 # 80010d30 <parefs>
    80002d4e:	97d2                	add	a5,a5,s4
    80002d50:	377d                	addiw	a4,a4,-1
    80002d52:	00e78023          	sb	a4,0(a5)
      char *mem = kalloc();
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	e34080e7          	jalr	-460(ra) # 80000b8a <kalloc>
    80002d5e:	8b2a                	mv	s6,a0
      if(mem == 0) {
    80002d60:	c929                	beqz	a0,80002db2 <usertrap+0x1ba>
      memmove(mem, (char*)pa, PGSIZE);
    80002d62:	6605                	lui	a2,0x1
    80002d64:	00ca1593          	slli	a1,s4,0xc
    80002d68:	855a                	mv	a0,s6
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	0b4080e7          	jalr	180(ra) # 80000e1e <memmove>
      if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U|PTE_V) != 0){
    80002d72:	477d                	li	a4,31
    80002d74:	86da                	mv	a3,s6
    80002d76:	6605                	lui	a2,0x1
    80002d78:	75fd                	lui	a1,0xfffff
    80002d7a:	00b9f5b3          	and	a1,s3,a1
    80002d7e:	68a8                	ld	a0,80(s1)
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	40c080e7          	jalr	1036(ra) # 8000118c <mappages>
    80002d88:	e139                	bnez	a0,80002dce <usertrap+0x1d6>
      parefs[PTE2PPN(*walk(pagetable, va, 0))] ++;
    80002d8a:	4601                	li	a2,0
    80002d8c:	85ce                	mv	a1,s3
    80002d8e:	8556                	mv	a0,s5
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	314080e7          	jalr	788(ra) # 800010a4 <walk>
    80002d98:	6118                	ld	a4,0(a0)
    80002d9a:	8329                	srli	a4,a4,0xa
    80002d9c:	0000e797          	auipc	a5,0xe
    80002da0:	f9478793          	addi	a5,a5,-108 # 80010d30 <parefs>
    80002da4:	97ba                	add	a5,a5,a4
    80002da6:	0007c703          	lbu	a4,0(a5)
    80002daa:	2705                	addiw	a4,a4,1
    80002dac:	00e78023          	sb	a4,0(a5)
    80002db0:	b761                	j	80002d38 <usertrap+0x140>
        printf("Kalloc failed\n");
    80002db2:	00005517          	auipc	a0,0x5
    80002db6:	6d650513          	addi	a0,a0,1750 # 80008488 <states.0+0x78>
    80002dba:	ffffd097          	auipc	ra,0xffffd
    80002dbe:	7de080e7          	jalr	2014(ra) # 80000598 <printf>
        exit(-1);
    80002dc2:	557d                	li	a0,-1
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	68e080e7          	jalr	1678(ra) # 80002452 <exit>
    80002dcc:	bf59                	j	80002d62 <usertrap+0x16a>
        printf("mappages failed\n");
    80002dce:	00005517          	auipc	a0,0x5
    80002dd2:	6ca50513          	addi	a0,a0,1738 # 80008498 <states.0+0x88>
    80002dd6:	ffffd097          	auipc	ra,0xffffd
    80002dda:	7c2080e7          	jalr	1986(ra) # 80000598 <printf>
        exit(-1);
    80002dde:	557d                	li	a0,-1
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	672080e7          	jalr	1650(ra) # 80002452 <exit>
    80002de8:	b74d                	j	80002d8a <usertrap+0x192>
  if(killed(p))
    80002dea:	8526                	mv	a0,s1
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	7da080e7          	jalr	2010(ra) # 800025c6 <killed>
    80002df4:	c901                	beqz	a0,80002e04 <usertrap+0x20c>
    80002df6:	a011                	j	80002dfa <usertrap+0x202>
    80002df8:	4901                	li	s2,0
    exit(-1);
    80002dfa:	557d                	li	a0,-1
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	656080e7          	jalr	1622(ra) # 80002452 <exit>
  if(which_dev == 2)
    80002e04:	4789                	li	a5,2
    80002e06:	ecf917e3          	bne	s2,a5,80002cd4 <usertrap+0xdc>
    yield();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	4d8080e7          	jalr	1240(ra) # 800022e2 <yield>
    80002e12:	b5c9                	j	80002cd4 <usertrap+0xdc>

0000000080002e14 <kerneltrap>:
{
    80002e14:	7179                	addi	sp,sp,-48
    80002e16:	f406                	sd	ra,40(sp)
    80002e18:	f022                	sd	s0,32(sp)
    80002e1a:	ec26                	sd	s1,24(sp)
    80002e1c:	e84a                	sd	s2,16(sp)
    80002e1e:	e44e                	sd	s3,8(sp)
    80002e20:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e22:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e26:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e2e:	1004f793          	andi	a5,s1,256
    80002e32:	cb85                	beqz	a5,80002e62 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e38:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e3a:	ef85                	bnez	a5,80002e72 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	d16080e7          	jalr	-746(ra) # 80002b52 <devintr>
    80002e44:	cd1d                	beqz	a0,80002e82 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e46:	4789                	li	a5,2
    80002e48:	06f50a63          	beq	a0,a5,80002ebc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e4c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e50:	10049073          	csrw	sstatus,s1
}
    80002e54:	70a2                	ld	ra,40(sp)
    80002e56:	7402                	ld	s0,32(sp)
    80002e58:	64e2                	ld	s1,24(sp)
    80002e5a:	6942                	ld	s2,16(sp)
    80002e5c:	69a2                	ld	s3,8(sp)
    80002e5e:	6145                	addi	sp,sp,48
    80002e60:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	69e50513          	addi	a0,a0,1694 # 80008500 <states.0+0xf0>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	6d2080e7          	jalr	1746(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	6b650513          	addi	a0,a0,1718 # 80008528 <states.0+0x118>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	6c2080e7          	jalr	1730(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e82:	85ce                	mv	a1,s3
    80002e84:	00005517          	auipc	a0,0x5
    80002e88:	6c450513          	addi	a0,a0,1732 # 80008548 <states.0+0x138>
    80002e8c:	ffffd097          	auipc	ra,0xffffd
    80002e90:	70c080e7          	jalr	1804(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e94:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e98:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	6bc50513          	addi	a0,a0,1724 # 80008558 <states.0+0x148>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	6f4080e7          	jalr	1780(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002eac:	00005517          	auipc	a0,0x5
    80002eb0:	6c450513          	addi	a0,a0,1732 # 80008570 <states.0+0x160>
    80002eb4:	ffffd097          	auipc	ra,0xffffd
    80002eb8:	688080e7          	jalr	1672(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	cfa080e7          	jalr	-774(ra) # 80001bb6 <myproc>
    80002ec4:	d541                	beqz	a0,80002e4c <kerneltrap+0x38>
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	cf0080e7          	jalr	-784(ra) # 80001bb6 <myproc>
    80002ece:	4d18                	lw	a4,24(a0)
    80002ed0:	4791                	li	a5,4
    80002ed2:	f6f71de3          	bne	a4,a5,80002e4c <kerneltrap+0x38>
    yield();
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	40c080e7          	jalr	1036(ra) # 800022e2 <yield>
    80002ede:	b7bd                	j	80002e4c <kerneltrap+0x38>

0000000080002ee0 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
    80002eea:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	cca080e7          	jalr	-822(ra) # 80001bb6 <myproc>
    switch (n)
    80002ef4:	4795                	li	a5,5
    80002ef6:	0497e163          	bltu	a5,s1,80002f38 <argraw+0x58>
    80002efa:	048a                	slli	s1,s1,0x2
    80002efc:	00005717          	auipc	a4,0x5
    80002f00:	6ac70713          	addi	a4,a4,1708 # 800085a8 <states.0+0x198>
    80002f04:	94ba                	add	s1,s1,a4
    80002f06:	409c                	lw	a5,0(s1)
    80002f08:	97ba                	add	a5,a5,a4
    80002f0a:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f0c:	6d3c                	ld	a5,88(a0)
    80002f0e:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	64a2                	ld	s1,8(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret
        return p->trapframe->a1;
    80002f1a:	6d3c                	ld	a5,88(a0)
    80002f1c:	7fa8                	ld	a0,120(a5)
    80002f1e:	bfcd                	j	80002f10 <argraw+0x30>
        return p->trapframe->a2;
    80002f20:	6d3c                	ld	a5,88(a0)
    80002f22:	63c8                	ld	a0,128(a5)
    80002f24:	b7f5                	j	80002f10 <argraw+0x30>
        return p->trapframe->a3;
    80002f26:	6d3c                	ld	a5,88(a0)
    80002f28:	67c8                	ld	a0,136(a5)
    80002f2a:	b7dd                	j	80002f10 <argraw+0x30>
        return p->trapframe->a4;
    80002f2c:	6d3c                	ld	a5,88(a0)
    80002f2e:	6bc8                	ld	a0,144(a5)
    80002f30:	b7c5                	j	80002f10 <argraw+0x30>
        return p->trapframe->a5;
    80002f32:	6d3c                	ld	a5,88(a0)
    80002f34:	6fc8                	ld	a0,152(a5)
    80002f36:	bfe9                	j	80002f10 <argraw+0x30>
    panic("argraw");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	64850513          	addi	a0,a0,1608 # 80008580 <states.0+0x170>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fc080e7          	jalr	1532(ra) # 8000053c <panic>

0000000080002f48 <fetchaddr>:
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	e426                	sd	s1,8(sp)
    80002f50:	e04a                	sd	s2,0(sp)
    80002f52:	1000                	addi	s0,sp,32
    80002f54:	84aa                	mv	s1,a0
    80002f56:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	c5e080e7          	jalr	-930(ra) # 80001bb6 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f60:	653c                	ld	a5,72(a0)
    80002f62:	02f4f863          	bgeu	s1,a5,80002f92 <fetchaddr+0x4a>
    80002f66:	00848713          	addi	a4,s1,8
    80002f6a:	02e7e663          	bltu	a5,a4,80002f96 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f6e:	46a1                	li	a3,8
    80002f70:	8626                	mv	a2,s1
    80002f72:	85ca                	mv	a1,s2
    80002f74:	6928                	ld	a0,80(a0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	898080e7          	jalr	-1896(ra) # 8000180e <copyin>
    80002f7e:	00a03533          	snez	a0,a0
    80002f82:	40a00533          	neg	a0,a0
}
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	64a2                	ld	s1,8(sp)
    80002f8c:	6902                	ld	s2,0(sp)
    80002f8e:	6105                	addi	sp,sp,32
    80002f90:	8082                	ret
        return -1;
    80002f92:	557d                	li	a0,-1
    80002f94:	bfcd                	j	80002f86 <fetchaddr+0x3e>
    80002f96:	557d                	li	a0,-1
    80002f98:	b7fd                	j	80002f86 <fetchaddr+0x3e>

0000000080002f9a <fetchstr>:
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	e44e                	sd	s3,8(sp)
    80002fa6:	1800                	addi	s0,sp,48
    80002fa8:	892a                	mv	s2,a0
    80002faa:	84ae                	mv	s1,a1
    80002fac:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	c08080e7          	jalr	-1016(ra) # 80001bb6 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fb6:	86ce                	mv	a3,s3
    80002fb8:	864a                	mv	a2,s2
    80002fba:	85a6                	mv	a1,s1
    80002fbc:	6928                	ld	a0,80(a0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	8de080e7          	jalr	-1826(ra) # 8000189c <copyinstr>
    80002fc6:	00054e63          	bltz	a0,80002fe2 <fetchstr+0x48>
    return strlen(buf);
    80002fca:	8526                	mv	a0,s1
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	f70080e7          	jalr	-144(ra) # 80000f3c <strlen>
}
    80002fd4:	70a2                	ld	ra,40(sp)
    80002fd6:	7402                	ld	s0,32(sp)
    80002fd8:	64e2                	ld	s1,24(sp)
    80002fda:	6942                	ld	s2,16(sp)
    80002fdc:	69a2                	ld	s3,8(sp)
    80002fde:	6145                	addi	sp,sp,48
    80002fe0:	8082                	ret
        return -1;
    80002fe2:	557d                	li	a0,-1
    80002fe4:	bfc5                	j	80002fd4 <fetchstr+0x3a>

0000000080002fe6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fe6:	1101                	addi	sp,sp,-32
    80002fe8:	ec06                	sd	ra,24(sp)
    80002fea:	e822                	sd	s0,16(sp)
    80002fec:	e426                	sd	s1,8(sp)
    80002fee:	1000                	addi	s0,sp,32
    80002ff0:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	eee080e7          	jalr	-274(ra) # 80002ee0 <argraw>
    80002ffa:	c088                	sw	a0,0(s1)
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	64a2                	ld	s1,8(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret

0000000080003006 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	e426                	sd	s1,8(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003012:	00000097          	auipc	ra,0x0
    80003016:	ece080e7          	jalr	-306(ra) # 80002ee0 <argraw>
    8000301a:	e088                	sd	a0,0(s1)
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6105                	addi	sp,sp,32
    80003024:	8082                	ret

0000000080003026 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003026:	7179                	addi	sp,sp,-48
    80003028:	f406                	sd	ra,40(sp)
    8000302a:	f022                	sd	s0,32(sp)
    8000302c:	ec26                	sd	s1,24(sp)
    8000302e:	e84a                	sd	s2,16(sp)
    80003030:	1800                	addi	s0,sp,48
    80003032:	84ae                	mv	s1,a1
    80003034:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003036:	fd840593          	addi	a1,s0,-40
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	fcc080e7          	jalr	-52(ra) # 80003006 <argaddr>
    return fetchstr(addr, buf, max);
    80003042:	864a                	mv	a2,s2
    80003044:	85a6                	mv	a1,s1
    80003046:	fd843503          	ld	a0,-40(s0)
    8000304a:	00000097          	auipc	ra,0x0
    8000304e:	f50080e7          	jalr	-176(ra) # 80002f9a <fetchstr>
}
    80003052:	70a2                	ld	ra,40(sp)
    80003054:	7402                	ld	s0,32(sp)
    80003056:	64e2                	ld	s1,24(sp)
    80003058:	6942                	ld	s2,16(sp)
    8000305a:	6145                	addi	sp,sp,48
    8000305c:	8082                	ret

000000008000305e <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	e04a                	sd	s2,0(sp)
    80003068:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	b4c080e7          	jalr	-1204(ra) # 80001bb6 <myproc>
    80003072:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003074:	05853903          	ld	s2,88(a0)
    80003078:	0a893783          	ld	a5,168(s2)
    8000307c:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003080:	37fd                	addiw	a5,a5,-1
    80003082:	4765                	li	a4,25
    80003084:	00f76f63          	bltu	a4,a5,800030a2 <syscall+0x44>
    80003088:	00369713          	slli	a4,a3,0x3
    8000308c:	00005797          	auipc	a5,0x5
    80003090:	53478793          	addi	a5,a5,1332 # 800085c0 <syscalls>
    80003094:	97ba                	add	a5,a5,a4
    80003096:	639c                	ld	a5,0(a5)
    80003098:	c789                	beqz	a5,800030a2 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000309a:	9782                	jalr	a5
    8000309c:	06a93823          	sd	a0,112(s2)
    800030a0:	a839                	j	800030be <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030a2:	15848613          	addi	a2,s1,344
    800030a6:	588c                	lw	a1,48(s1)
    800030a8:	00005517          	auipc	a0,0x5
    800030ac:	4e050513          	addi	a0,a0,1248 # 80008588 <states.0+0x178>
    800030b0:	ffffd097          	auipc	ra,0xffffd
    800030b4:	4e8080e7          	jalr	1256(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030b8:	6cbc                	ld	a5,88(s1)
    800030ba:	577d                	li	a4,-1
    800030bc:	fbb8                	sd	a4,112(a5)
    }
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6902                	ld	s2,0(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <sys_exit>:
extern struct proc proc[NPROC];
extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030d2:	fec40593          	addi	a1,s0,-20
    800030d6:	4501                	li	a0,0
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	f0e080e7          	jalr	-242(ra) # 80002fe6 <argint>
    exit(n);
    800030e0:	fec42503          	lw	a0,-20(s0)
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	36e080e7          	jalr	878(ra) # 80002452 <exit>
    return 0; // not reached
}
    800030ec:	4501                	li	a0,0
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030f6:	1141                	addi	sp,sp,-16
    800030f8:	e406                	sd	ra,8(sp)
    800030fa:	e022                	sd	s0,0(sp)
    800030fc:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030fe:	fffff097          	auipc	ra,0xfffff
    80003102:	ab8080e7          	jalr	-1352(ra) # 80001bb6 <myproc>
}
    80003106:	5908                	lw	a0,48(a0)
    80003108:	60a2                	ld	ra,8(sp)
    8000310a:	6402                	ld	s0,0(sp)
    8000310c:	0141                	addi	sp,sp,16
    8000310e:	8082                	ret

0000000080003110 <sys_fork>:

uint64
sys_fork(void)
{
    80003110:	1141                	addi	sp,sp,-16
    80003112:	e406                	sd	ra,8(sp)
    80003114:	e022                	sd	s0,0(sp)
    80003116:	0800                	addi	s0,sp,16
    return fork();
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	fa4080e7          	jalr	-92(ra) # 800020bc <fork>
}
    80003120:	60a2                	ld	ra,8(sp)
    80003122:	6402                	ld	s0,0(sp)
    80003124:	0141                	addi	sp,sp,16
    80003126:	8082                	ret

0000000080003128 <sys_wait>:

uint64
sys_wait(void)
{
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003130:	fe840593          	addi	a1,s0,-24
    80003134:	4501                	li	a0,0
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	ed0080e7          	jalr	-304(ra) # 80003006 <argaddr>
    return wait(p);
    8000313e:	fe843503          	ld	a0,-24(s0)
    80003142:	fffff097          	auipc	ra,0xfffff
    80003146:	4b6080e7          	jalr	1206(ra) # 800025f8 <wait>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret

0000000080003152 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003152:	7179                	addi	sp,sp,-48
    80003154:	f406                	sd	ra,40(sp)
    80003156:	f022                	sd	s0,32(sp)
    80003158:	ec26                	sd	s1,24(sp)
    8000315a:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000315c:	fdc40593          	addi	a1,s0,-36
    80003160:	4501                	li	a0,0
    80003162:	00000097          	auipc	ra,0x0
    80003166:	e84080e7          	jalr	-380(ra) # 80002fe6 <argint>
    addr = myproc()->sz;
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	a4c080e7          	jalr	-1460(ra) # 80001bb6 <myproc>
    80003172:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003174:	fdc42503          	lw	a0,-36(s0)
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	d98080e7          	jalr	-616(ra) # 80001f10 <growproc>
    80003180:	00054863          	bltz	a0,80003190 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003184:	8526                	mv	a0,s1
    80003186:	70a2                	ld	ra,40(sp)
    80003188:	7402                	ld	s0,32(sp)
    8000318a:	64e2                	ld	s1,24(sp)
    8000318c:	6145                	addi	sp,sp,48
    8000318e:	8082                	ret
        return -1;
    80003190:	54fd                	li	s1,-1
    80003192:	bfcd                	j	80003184 <sys_sbrk+0x32>

0000000080003194 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003194:	7139                	addi	sp,sp,-64
    80003196:	fc06                	sd	ra,56(sp)
    80003198:	f822                	sd	s0,48(sp)
    8000319a:	f426                	sd	s1,40(sp)
    8000319c:	f04a                	sd	s2,32(sp)
    8000319e:	ec4e                	sd	s3,24(sp)
    800031a0:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031a2:	fcc40593          	addi	a1,s0,-52
    800031a6:	4501                	li	a0,0
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	e3e080e7          	jalr	-450(ra) # 80002fe6 <argint>
    acquire(&tickslock);
    800031b0:	0001c517          	auipc	a0,0x1c
    800031b4:	9b050513          	addi	a0,a0,-1616 # 8001eb60 <tickslock>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	b0e080e7          	jalr	-1266(ra) # 80000cc6 <acquire>
    ticks0 = ticks;
    800031c0:	00006917          	auipc	s2,0x6
    800031c4:	90092903          	lw	s2,-1792(s2) # 80008ac0 <ticks>
    while (ticks - ticks0 < n)
    800031c8:	fcc42783          	lw	a5,-52(s0)
    800031cc:	cf9d                	beqz	a5,8000320a <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031ce:	0001c997          	auipc	s3,0x1c
    800031d2:	99298993          	addi	s3,s3,-1646 # 8001eb60 <tickslock>
    800031d6:	00006497          	auipc	s1,0x6
    800031da:	8ea48493          	addi	s1,s1,-1814 # 80008ac0 <ticks>
        if (killed(myproc()))
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	9d8080e7          	jalr	-1576(ra) # 80001bb6 <myproc>
    800031e6:	fffff097          	auipc	ra,0xfffff
    800031ea:	3e0080e7          	jalr	992(ra) # 800025c6 <killed>
    800031ee:	ed15                	bnez	a0,8000322a <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031f0:	85ce                	mv	a1,s3
    800031f2:	8526                	mv	a0,s1
    800031f4:	fffff097          	auipc	ra,0xfffff
    800031f8:	12a080e7          	jalr	298(ra) # 8000231e <sleep>
    while (ticks - ticks0 < n)
    800031fc:	409c                	lw	a5,0(s1)
    800031fe:	412787bb          	subw	a5,a5,s2
    80003202:	fcc42703          	lw	a4,-52(s0)
    80003206:	fce7ece3          	bltu	a5,a4,800031de <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000320a:	0001c517          	auipc	a0,0x1c
    8000320e:	95650513          	addi	a0,a0,-1706 # 8001eb60 <tickslock>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	b68080e7          	jalr	-1176(ra) # 80000d7a <release>
    return 0;
    8000321a:	4501                	li	a0,0
}
    8000321c:	70e2                	ld	ra,56(sp)
    8000321e:	7442                	ld	s0,48(sp)
    80003220:	74a2                	ld	s1,40(sp)
    80003222:	7902                	ld	s2,32(sp)
    80003224:	69e2                	ld	s3,24(sp)
    80003226:	6121                	addi	sp,sp,64
    80003228:	8082                	ret
            release(&tickslock);
    8000322a:	0001c517          	auipc	a0,0x1c
    8000322e:	93650513          	addi	a0,a0,-1738 # 8001eb60 <tickslock>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	b48080e7          	jalr	-1208(ra) # 80000d7a <release>
            return -1;
    8000323a:	557d                	li	a0,-1
    8000323c:	b7c5                	j	8000321c <sys_sleep+0x88>

000000008000323e <sys_kill>:

uint64
sys_kill(void)
{
    8000323e:	1101                	addi	sp,sp,-32
    80003240:	ec06                	sd	ra,24(sp)
    80003242:	e822                	sd	s0,16(sp)
    80003244:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003246:	fec40593          	addi	a1,s0,-20
    8000324a:	4501                	li	a0,0
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	d9a080e7          	jalr	-614(ra) # 80002fe6 <argint>
    return kill(pid);
    80003254:	fec42503          	lw	a0,-20(s0)
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	2d0080e7          	jalr	720(ra) # 80002528 <kill>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret

0000000080003268 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003272:	0001c517          	auipc	a0,0x1c
    80003276:	8ee50513          	addi	a0,a0,-1810 # 8001eb60 <tickslock>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a4c080e7          	jalr	-1460(ra) # 80000cc6 <acquire>
    xticks = ticks;
    80003282:	00006497          	auipc	s1,0x6
    80003286:	83e4a483          	lw	s1,-1986(s1) # 80008ac0 <ticks>
    release(&tickslock);
    8000328a:	0001c517          	auipc	a0,0x1c
    8000328e:	8d650513          	addi	a0,a0,-1834 # 8001eb60 <tickslock>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	ae8080e7          	jalr	-1304(ra) # 80000d7a <release>
    return xticks;
}
    8000329a:	02049513          	slli	a0,s1,0x20
    8000329e:	9101                	srli	a0,a0,0x20
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	64a2                	ld	s1,8(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret

00000000800032aa <sys_ps>:

void *
sys_ps(void)
{
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032b2:	fe042623          	sw	zero,-20(s0)
    800032b6:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032ba:	fec40593          	addi	a1,s0,-20
    800032be:	4501                	li	a0,0
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	d26080e7          	jalr	-730(ra) # 80002fe6 <argint>
    argint(1, &count);
    800032c8:	fe840593          	addi	a1,s0,-24
    800032cc:	4505                	li	a0,1
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	d18080e7          	jalr	-744(ra) # 80002fe6 <argint>
    return ps((uint8)start, (uint8)count);
    800032d6:	fe844583          	lbu	a1,-24(s0)
    800032da:	fec44503          	lbu	a0,-20(s0)
    800032de:	fffff097          	auipc	ra,0xfffff
    800032e2:	c8e080e7          	jalr	-882(ra) # 80001f6c <ps>
}
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret

00000000800032ee <sys_schedls>:

uint64 sys_schedls(void)
{
    800032ee:	1141                	addi	sp,sp,-16
    800032f0:	e406                	sd	ra,8(sp)
    800032f2:	e022                	sd	s0,0(sp)
    800032f4:	0800                	addi	s0,sp,16
    schedls();
    800032f6:	fffff097          	auipc	ra,0xfffff
    800032fa:	58c080e7          	jalr	1420(ra) # 80002882 <schedls>
    return 0;
}
    800032fe:	4501                	li	a0,0
    80003300:	60a2                	ld	ra,8(sp)
    80003302:	6402                	ld	s0,0(sp)
    80003304:	0141                	addi	sp,sp,16
    80003306:	8082                	ret

0000000080003308 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	1000                	addi	s0,sp,32
    int id = 0;
    80003310:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003314:	fec40593          	addi	a1,s0,-20
    80003318:	4501                	li	a0,0
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	ccc080e7          	jalr	-820(ra) # 80002fe6 <argint>
    schedset(id - 1);
    80003322:	fec42503          	lw	a0,-20(s0)
    80003326:	357d                	addiw	a0,a0,-1
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	5f0080e7          	jalr	1520(ra) # 80002918 <schedset>
    return 0;
}
    80003330:	4501                	li	a0,0
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <sys_va2pa>:

uint64 sys_va2pa(void)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	1000                	addi	s0,sp,32
    printf("Executing sysproc.c sys_va2pa\n");
    80003342:	00005517          	auipc	a0,0x5
    80003346:	35650513          	addi	a0,a0,854 # 80008698 <syscalls+0xd8>
    8000334a:	ffffd097          	auipc	ra,0xffffd
    8000334e:	24e080e7          	jalr	590(ra) # 80000598 <printf>

    int pid;
    argint(1, &pid);
    80003352:	fec40593          	addi	a1,s0,-20
    80003356:	4505                	li	a0,1
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	c8e080e7          	jalr	-882(ra) # 80002fe6 <argint>
    uint64 va;
    argaddr(0, &va);
    80003360:	fe040593          	addi	a1,s0,-32
    80003364:	4501                	li	a0,0
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	ca0080e7          	jalr	-864(ra) # 80003006 <argaddr>

    uint64 pa;

    
    if (pid) {
    8000336e:	fec42583          	lw	a1,-20(s0)
    80003372:	c999                	beqz	a1,80003388 <sys_va2pa+0x4e>
        pa = proc_va2pa(va, pid);
    80003374:	fe043503          	ld	a0,-32(s0)
    80003378:	fffff097          	auipc	ra,0xfffff
    8000337c:	5ec080e7          	jalr	1516(ra) # 80002964 <proc_va2pa>
    else {
        pa = proc_va2pa(va, -1);
    }
    //printf("%d\n", pa);
    return pa;
}
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	6105                	addi	sp,sp,32
    80003386:	8082                	ret
        pa = proc_va2pa(va, -1);
    80003388:	55fd                	li	a1,-1
    8000338a:	fe043503          	ld	a0,-32(s0)
    8000338e:	fffff097          	auipc	ra,0xfffff
    80003392:	5d6080e7          	jalr	1494(ra) # 80002964 <proc_va2pa>
    return pa;
    80003396:	b7ed                	j	80003380 <sys_va2pa+0x46>

0000000080003398 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003398:	1141                	addi	sp,sp,-16
    8000339a:	e406                	sd	ra,8(sp)
    8000339c:	e022                	sd	s0,0(sp)
    8000339e:	0800                	addi	s0,sp,16

    printf("%d\n", FREE_PAGES);
    800033a0:	00005597          	auipc	a1,0x5
    800033a4:	6f85b583          	ld	a1,1784(a1) # 80008a98 <FREE_PAGES>
    800033a8:	00005517          	auipc	a0,0x5
    800033ac:	1f850513          	addi	a0,a0,504 # 800085a0 <states.0+0x190>
    800033b0:	ffffd097          	auipc	ra,0xffffd
    800033b4:	1e8080e7          	jalr	488(ra) # 80000598 <printf>
    return 0;
    800033b8:	4501                	li	a0,0
    800033ba:	60a2                	ld	ra,8(sp)
    800033bc:	6402                	ld	s0,0(sp)
    800033be:	0141                	addi	sp,sp,16
    800033c0:	8082                	ret

00000000800033c2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033c2:	7179                	addi	sp,sp,-48
    800033c4:	f406                	sd	ra,40(sp)
    800033c6:	f022                	sd	s0,32(sp)
    800033c8:	ec26                	sd	s1,24(sp)
    800033ca:	e84a                	sd	s2,16(sp)
    800033cc:	e44e                	sd	s3,8(sp)
    800033ce:	e052                	sd	s4,0(sp)
    800033d0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033d2:	00005597          	auipc	a1,0x5
    800033d6:	2e658593          	addi	a1,a1,742 # 800086b8 <syscalls+0xf8>
    800033da:	0001b517          	auipc	a0,0x1b
    800033de:	79e50513          	addi	a0,a0,1950 # 8001eb78 <bcache>
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	854080e7          	jalr	-1964(ra) # 80000c36 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033ea:	00023797          	auipc	a5,0x23
    800033ee:	78e78793          	addi	a5,a5,1934 # 80026b78 <bcache+0x8000>
    800033f2:	00024717          	auipc	a4,0x24
    800033f6:	9ee70713          	addi	a4,a4,-1554 # 80026de0 <bcache+0x8268>
    800033fa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033fe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003402:	0001b497          	auipc	s1,0x1b
    80003406:	78e48493          	addi	s1,s1,1934 # 8001eb90 <bcache+0x18>
    b->next = bcache.head.next;
    8000340a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000340c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000340e:	00005a17          	auipc	s4,0x5
    80003412:	2b2a0a13          	addi	s4,s4,690 # 800086c0 <syscalls+0x100>
    b->next = bcache.head.next;
    80003416:	2b893783          	ld	a5,696(s2)
    8000341a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000341c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003420:	85d2                	mv	a1,s4
    80003422:	01048513          	addi	a0,s1,16
    80003426:	00001097          	auipc	ra,0x1
    8000342a:	496080e7          	jalr	1174(ra) # 800048bc <initsleeplock>
    bcache.head.next->prev = b;
    8000342e:	2b893783          	ld	a5,696(s2)
    80003432:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003434:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003438:	45848493          	addi	s1,s1,1112
    8000343c:	fd349de3          	bne	s1,s3,80003416 <binit+0x54>
  }
}
    80003440:	70a2                	ld	ra,40(sp)
    80003442:	7402                	ld	s0,32(sp)
    80003444:	64e2                	ld	s1,24(sp)
    80003446:	6942                	ld	s2,16(sp)
    80003448:	69a2                	ld	s3,8(sp)
    8000344a:	6a02                	ld	s4,0(sp)
    8000344c:	6145                	addi	sp,sp,48
    8000344e:	8082                	ret

0000000080003450 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003450:	7179                	addi	sp,sp,-48
    80003452:	f406                	sd	ra,40(sp)
    80003454:	f022                	sd	s0,32(sp)
    80003456:	ec26                	sd	s1,24(sp)
    80003458:	e84a                	sd	s2,16(sp)
    8000345a:	e44e                	sd	s3,8(sp)
    8000345c:	1800                	addi	s0,sp,48
    8000345e:	892a                	mv	s2,a0
    80003460:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003462:	0001b517          	auipc	a0,0x1b
    80003466:	71650513          	addi	a0,a0,1814 # 8001eb78 <bcache>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	85c080e7          	jalr	-1956(ra) # 80000cc6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003472:	00024497          	auipc	s1,0x24
    80003476:	9be4b483          	ld	s1,-1602(s1) # 80026e30 <bcache+0x82b8>
    8000347a:	00024797          	auipc	a5,0x24
    8000347e:	96678793          	addi	a5,a5,-1690 # 80026de0 <bcache+0x8268>
    80003482:	02f48f63          	beq	s1,a5,800034c0 <bread+0x70>
    80003486:	873e                	mv	a4,a5
    80003488:	a021                	j	80003490 <bread+0x40>
    8000348a:	68a4                	ld	s1,80(s1)
    8000348c:	02e48a63          	beq	s1,a4,800034c0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003490:	449c                	lw	a5,8(s1)
    80003492:	ff279ce3          	bne	a5,s2,8000348a <bread+0x3a>
    80003496:	44dc                	lw	a5,12(s1)
    80003498:	ff3799e3          	bne	a5,s3,8000348a <bread+0x3a>
      b->refcnt++;
    8000349c:	40bc                	lw	a5,64(s1)
    8000349e:	2785                	addiw	a5,a5,1
    800034a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034a2:	0001b517          	auipc	a0,0x1b
    800034a6:	6d650513          	addi	a0,a0,1750 # 8001eb78 <bcache>
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	8d0080e7          	jalr	-1840(ra) # 80000d7a <release>
      acquiresleep(&b->lock);
    800034b2:	01048513          	addi	a0,s1,16
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	440080e7          	jalr	1088(ra) # 800048f6 <acquiresleep>
      return b;
    800034be:	a8b9                	j	8000351c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c0:	00024497          	auipc	s1,0x24
    800034c4:	9684b483          	ld	s1,-1688(s1) # 80026e28 <bcache+0x82b0>
    800034c8:	00024797          	auipc	a5,0x24
    800034cc:	91878793          	addi	a5,a5,-1768 # 80026de0 <bcache+0x8268>
    800034d0:	00f48863          	beq	s1,a5,800034e0 <bread+0x90>
    800034d4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034d6:	40bc                	lw	a5,64(s1)
    800034d8:	cf81                	beqz	a5,800034f0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034da:	64a4                	ld	s1,72(s1)
    800034dc:	fee49de3          	bne	s1,a4,800034d6 <bread+0x86>
  panic("bget: no buffers");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	1e850513          	addi	a0,a0,488 # 800086c8 <syscalls+0x108>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	054080e7          	jalr	84(ra) # 8000053c <panic>
      b->dev = dev;
    800034f0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034f4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034fc:	4785                	li	a5,1
    800034fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003500:	0001b517          	auipc	a0,0x1b
    80003504:	67850513          	addi	a0,a0,1656 # 8001eb78 <bcache>
    80003508:	ffffe097          	auipc	ra,0xffffe
    8000350c:	872080e7          	jalr	-1934(ra) # 80000d7a <release>
      acquiresleep(&b->lock);
    80003510:	01048513          	addi	a0,s1,16
    80003514:	00001097          	auipc	ra,0x1
    80003518:	3e2080e7          	jalr	994(ra) # 800048f6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000351c:	409c                	lw	a5,0(s1)
    8000351e:	cb89                	beqz	a5,80003530 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003520:	8526                	mv	a0,s1
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003530:	4581                	li	a1,0
    80003532:	8526                	mv	a0,s1
    80003534:	00003097          	auipc	ra,0x3
    80003538:	f7e080e7          	jalr	-130(ra) # 800064b2 <virtio_disk_rw>
    b->valid = 1;
    8000353c:	4785                	li	a5,1
    8000353e:	c09c                	sw	a5,0(s1)
  return b;
    80003540:	b7c5                	j	80003520 <bread+0xd0>

0000000080003542 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003542:	1101                	addi	sp,sp,-32
    80003544:	ec06                	sd	ra,24(sp)
    80003546:	e822                	sd	s0,16(sp)
    80003548:	e426                	sd	s1,8(sp)
    8000354a:	1000                	addi	s0,sp,32
    8000354c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000354e:	0541                	addi	a0,a0,16
    80003550:	00001097          	auipc	ra,0x1
    80003554:	440080e7          	jalr	1088(ra) # 80004990 <holdingsleep>
    80003558:	cd01                	beqz	a0,80003570 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000355a:	4585                	li	a1,1
    8000355c:	8526                	mv	a0,s1
    8000355e:	00003097          	auipc	ra,0x3
    80003562:	f54080e7          	jalr	-172(ra) # 800064b2 <virtio_disk_rw>
}
    80003566:	60e2                	ld	ra,24(sp)
    80003568:	6442                	ld	s0,16(sp)
    8000356a:	64a2                	ld	s1,8(sp)
    8000356c:	6105                	addi	sp,sp,32
    8000356e:	8082                	ret
    panic("bwrite");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	17050513          	addi	a0,a0,368 # 800086e0 <syscalls+0x120>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fc4080e7          	jalr	-60(ra) # 8000053c <panic>

0000000080003580 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	e04a                	sd	s2,0(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000358e:	01050913          	addi	s2,a0,16
    80003592:	854a                	mv	a0,s2
    80003594:	00001097          	auipc	ra,0x1
    80003598:	3fc080e7          	jalr	1020(ra) # 80004990 <holdingsleep>
    8000359c:	c925                	beqz	a0,8000360c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	3ac080e7          	jalr	940(ra) # 8000494c <releasesleep>

  acquire(&bcache.lock);
    800035a8:	0001b517          	auipc	a0,0x1b
    800035ac:	5d050513          	addi	a0,a0,1488 # 8001eb78 <bcache>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	716080e7          	jalr	1814(ra) # 80000cc6 <acquire>
  b->refcnt--;
    800035b8:	40bc                	lw	a5,64(s1)
    800035ba:	37fd                	addiw	a5,a5,-1
    800035bc:	0007871b          	sext.w	a4,a5
    800035c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035c2:	e71d                	bnez	a4,800035f0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035c4:	68b8                	ld	a4,80(s1)
    800035c6:	64bc                	ld	a5,72(s1)
    800035c8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800035ca:	68b8                	ld	a4,80(s1)
    800035cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035ce:	00023797          	auipc	a5,0x23
    800035d2:	5aa78793          	addi	a5,a5,1450 # 80026b78 <bcache+0x8000>
    800035d6:	2b87b703          	ld	a4,696(a5)
    800035da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035dc:	00024717          	auipc	a4,0x24
    800035e0:	80470713          	addi	a4,a4,-2044 # 80026de0 <bcache+0x8268>
    800035e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035e6:	2b87b703          	ld	a4,696(a5)
    800035ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035f0:	0001b517          	auipc	a0,0x1b
    800035f4:	58850513          	addi	a0,a0,1416 # 8001eb78 <bcache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	782080e7          	jalr	1922(ra) # 80000d7a <release>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6902                	ld	s2,0(sp)
    80003608:	6105                	addi	sp,sp,32
    8000360a:	8082                	ret
    panic("brelse");
    8000360c:	00005517          	auipc	a0,0x5
    80003610:	0dc50513          	addi	a0,a0,220 # 800086e8 <syscalls+0x128>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	f28080e7          	jalr	-216(ra) # 8000053c <panic>

000000008000361c <bpin>:

void
bpin(struct buf *b) {
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003628:	0001b517          	auipc	a0,0x1b
    8000362c:	55050513          	addi	a0,a0,1360 # 8001eb78 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	696080e7          	jalr	1686(ra) # 80000cc6 <acquire>
  b->refcnt++;
    80003638:	40bc                	lw	a5,64(s1)
    8000363a:	2785                	addiw	a5,a5,1
    8000363c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000363e:	0001b517          	auipc	a0,0x1b
    80003642:	53a50513          	addi	a0,a0,1338 # 8001eb78 <bcache>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	734080e7          	jalr	1844(ra) # 80000d7a <release>
}
    8000364e:	60e2                	ld	ra,24(sp)
    80003650:	6442                	ld	s0,16(sp)
    80003652:	64a2                	ld	s1,8(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret

0000000080003658 <bunpin>:

void
bunpin(struct buf *b) {
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	1000                	addi	s0,sp,32
    80003662:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003664:	0001b517          	auipc	a0,0x1b
    80003668:	51450513          	addi	a0,a0,1300 # 8001eb78 <bcache>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	65a080e7          	jalr	1626(ra) # 80000cc6 <acquire>
  b->refcnt--;
    80003674:	40bc                	lw	a5,64(s1)
    80003676:	37fd                	addiw	a5,a5,-1
    80003678:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000367a:	0001b517          	auipc	a0,0x1b
    8000367e:	4fe50513          	addi	a0,a0,1278 # 8001eb78 <bcache>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	6f8080e7          	jalr	1784(ra) # 80000d7a <release>
}
    8000368a:	60e2                	ld	ra,24(sp)
    8000368c:	6442                	ld	s0,16(sp)
    8000368e:	64a2                	ld	s1,8(sp)
    80003690:	6105                	addi	sp,sp,32
    80003692:	8082                	ret

0000000080003694 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003694:	1101                	addi	sp,sp,-32
    80003696:	ec06                	sd	ra,24(sp)
    80003698:	e822                	sd	s0,16(sp)
    8000369a:	e426                	sd	s1,8(sp)
    8000369c:	e04a                	sd	s2,0(sp)
    8000369e:	1000                	addi	s0,sp,32
    800036a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036a2:	00d5d59b          	srliw	a1,a1,0xd
    800036a6:	00024797          	auipc	a5,0x24
    800036aa:	bae7a783          	lw	a5,-1106(a5) # 80027254 <sb+0x1c>
    800036ae:	9dbd                	addw	a1,a1,a5
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	da0080e7          	jalr	-608(ra) # 80003450 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036b8:	0074f713          	andi	a4,s1,7
    800036bc:	4785                	li	a5,1
    800036be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036c2:	14ce                	slli	s1,s1,0x33
    800036c4:	90d9                	srli	s1,s1,0x36
    800036c6:	00950733          	add	a4,a0,s1
    800036ca:	05874703          	lbu	a4,88(a4)
    800036ce:	00e7f6b3          	and	a3,a5,a4
    800036d2:	c69d                	beqz	a3,80003700 <bfree+0x6c>
    800036d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036d6:	94aa                	add	s1,s1,a0
    800036d8:	fff7c793          	not	a5,a5
    800036dc:	8f7d                	and	a4,a4,a5
    800036de:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	0f6080e7          	jalr	246(ra) # 800047d8 <log_write>
  brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	e94080e7          	jalr	-364(ra) # 80003580 <brelse>
}
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6902                	ld	s2,0(sp)
    800036fc:	6105                	addi	sp,sp,32
    800036fe:	8082                	ret
    panic("freeing free block");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	ff050513          	addi	a0,a0,-16 # 800086f0 <syscalls+0x130>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e34080e7          	jalr	-460(ra) # 8000053c <panic>

0000000080003710 <balloc>:
{
    80003710:	711d                	addi	sp,sp,-96
    80003712:	ec86                	sd	ra,88(sp)
    80003714:	e8a2                	sd	s0,80(sp)
    80003716:	e4a6                	sd	s1,72(sp)
    80003718:	e0ca                	sd	s2,64(sp)
    8000371a:	fc4e                	sd	s3,56(sp)
    8000371c:	f852                	sd	s4,48(sp)
    8000371e:	f456                	sd	s5,40(sp)
    80003720:	f05a                	sd	s6,32(sp)
    80003722:	ec5e                	sd	s7,24(sp)
    80003724:	e862                	sd	s8,16(sp)
    80003726:	e466                	sd	s9,8(sp)
    80003728:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000372a:	00024797          	auipc	a5,0x24
    8000372e:	b127a783          	lw	a5,-1262(a5) # 8002723c <sb+0x4>
    80003732:	cff5                	beqz	a5,8000382e <balloc+0x11e>
    80003734:	8baa                	mv	s7,a0
    80003736:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003738:	00024b17          	auipc	s6,0x24
    8000373c:	b00b0b13          	addi	s6,s6,-1280 # 80027238 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003740:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003742:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003744:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003746:	6c89                	lui	s9,0x2
    80003748:	a061                	j	800037d0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000374a:	97ca                	add	a5,a5,s2
    8000374c:	8e55                	or	a2,a2,a3
    8000374e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	084080e7          	jalr	132(ra) # 800047d8 <log_write>
        brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	e22080e7          	jalr	-478(ra) # 80003580 <brelse>
  bp = bread(dev, bno);
    80003766:	85a6                	mv	a1,s1
    80003768:	855e                	mv	a0,s7
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	ce6080e7          	jalr	-794(ra) # 80003450 <bread>
    80003772:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003774:	40000613          	li	a2,1024
    80003778:	4581                	li	a1,0
    8000377a:	05850513          	addi	a0,a0,88
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	644080e7          	jalr	1604(ra) # 80000dc2 <memset>
  log_write(bp);
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	050080e7          	jalr	80(ra) # 800047d8 <log_write>
  brelse(bp);
    80003790:	854a                	mv	a0,s2
    80003792:	00000097          	auipc	ra,0x0
    80003796:	dee080e7          	jalr	-530(ra) # 80003580 <brelse>
}
    8000379a:	8526                	mv	a0,s1
    8000379c:	60e6                	ld	ra,88(sp)
    8000379e:	6446                	ld	s0,80(sp)
    800037a0:	64a6                	ld	s1,72(sp)
    800037a2:	6906                	ld	s2,64(sp)
    800037a4:	79e2                	ld	s3,56(sp)
    800037a6:	7a42                	ld	s4,48(sp)
    800037a8:	7aa2                	ld	s5,40(sp)
    800037aa:	7b02                	ld	s6,32(sp)
    800037ac:	6be2                	ld	s7,24(sp)
    800037ae:	6c42                	ld	s8,16(sp)
    800037b0:	6ca2                	ld	s9,8(sp)
    800037b2:	6125                	addi	sp,sp,96
    800037b4:	8082                	ret
    brelse(bp);
    800037b6:	854a                	mv	a0,s2
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	dc8080e7          	jalr	-568(ra) # 80003580 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037c0:	015c87bb          	addw	a5,s9,s5
    800037c4:	00078a9b          	sext.w	s5,a5
    800037c8:	004b2703          	lw	a4,4(s6)
    800037cc:	06eaf163          	bgeu	s5,a4,8000382e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800037d0:	41fad79b          	sraiw	a5,s5,0x1f
    800037d4:	0137d79b          	srliw	a5,a5,0x13
    800037d8:	015787bb          	addw	a5,a5,s5
    800037dc:	40d7d79b          	sraiw	a5,a5,0xd
    800037e0:	01cb2583          	lw	a1,28(s6)
    800037e4:	9dbd                	addw	a1,a1,a5
    800037e6:	855e                	mv	a0,s7
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	c68080e7          	jalr	-920(ra) # 80003450 <bread>
    800037f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f2:	004b2503          	lw	a0,4(s6)
    800037f6:	000a849b          	sext.w	s1,s5
    800037fa:	8762                	mv	a4,s8
    800037fc:	faa4fde3          	bgeu	s1,a0,800037b6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003800:	00777693          	andi	a3,a4,7
    80003804:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003808:	41f7579b          	sraiw	a5,a4,0x1f
    8000380c:	01d7d79b          	srliw	a5,a5,0x1d
    80003810:	9fb9                	addw	a5,a5,a4
    80003812:	4037d79b          	sraiw	a5,a5,0x3
    80003816:	00f90633          	add	a2,s2,a5
    8000381a:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000381e:	00c6f5b3          	and	a1,a3,a2
    80003822:	d585                	beqz	a1,8000374a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003824:	2705                	addiw	a4,a4,1
    80003826:	2485                	addiw	s1,s1,1
    80003828:	fd471ae3          	bne	a4,s4,800037fc <balloc+0xec>
    8000382c:	b769                	j	800037b6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000382e:	00005517          	auipc	a0,0x5
    80003832:	eda50513          	addi	a0,a0,-294 # 80008708 <syscalls+0x148>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	d62080e7          	jalr	-670(ra) # 80000598 <printf>
  return 0;
    8000383e:	4481                	li	s1,0
    80003840:	bfa9                	j	8000379a <balloc+0x8a>

0000000080003842 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003842:	7179                	addi	sp,sp,-48
    80003844:	f406                	sd	ra,40(sp)
    80003846:	f022                	sd	s0,32(sp)
    80003848:	ec26                	sd	s1,24(sp)
    8000384a:	e84a                	sd	s2,16(sp)
    8000384c:	e44e                	sd	s3,8(sp)
    8000384e:	e052                	sd	s4,0(sp)
    80003850:	1800                	addi	s0,sp,48
    80003852:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003854:	47ad                	li	a5,11
    80003856:	02b7e863          	bltu	a5,a1,80003886 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000385a:	02059793          	slli	a5,a1,0x20
    8000385e:	01e7d593          	srli	a1,a5,0x1e
    80003862:	00b504b3          	add	s1,a0,a1
    80003866:	0504a903          	lw	s2,80(s1)
    8000386a:	06091e63          	bnez	s2,800038e6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000386e:	4108                	lw	a0,0(a0)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	ea0080e7          	jalr	-352(ra) # 80003710 <balloc>
    80003878:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000387c:	06090563          	beqz	s2,800038e6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003880:	0524a823          	sw	s2,80(s1)
    80003884:	a08d                	j	800038e6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003886:	ff45849b          	addiw	s1,a1,-12
    8000388a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000388e:	0ff00793          	li	a5,255
    80003892:	08e7e563          	bltu	a5,a4,8000391c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003896:	08052903          	lw	s2,128(a0)
    8000389a:	00091d63          	bnez	s2,800038b4 <bmap+0x72>
      addr = balloc(ip->dev);
    8000389e:	4108                	lw	a0,0(a0)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	e70080e7          	jalr	-400(ra) # 80003710 <balloc>
    800038a8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038ac:	02090d63          	beqz	s2,800038e6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038b0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038b4:	85ca                	mv	a1,s2
    800038b6:	0009a503          	lw	a0,0(s3)
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	b96080e7          	jalr	-1130(ra) # 80003450 <bread>
    800038c2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038c4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038c8:	02049713          	slli	a4,s1,0x20
    800038cc:	01e75593          	srli	a1,a4,0x1e
    800038d0:	00b784b3          	add	s1,a5,a1
    800038d4:	0004a903          	lw	s2,0(s1)
    800038d8:	02090063          	beqz	s2,800038f8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038dc:	8552                	mv	a0,s4
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	ca2080e7          	jalr	-862(ra) # 80003580 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038e6:	854a                	mv	a0,s2
    800038e8:	70a2                	ld	ra,40(sp)
    800038ea:	7402                	ld	s0,32(sp)
    800038ec:	64e2                	ld	s1,24(sp)
    800038ee:	6942                	ld	s2,16(sp)
    800038f0:	69a2                	ld	s3,8(sp)
    800038f2:	6a02                	ld	s4,0(sp)
    800038f4:	6145                	addi	sp,sp,48
    800038f6:	8082                	ret
      addr = balloc(ip->dev);
    800038f8:	0009a503          	lw	a0,0(s3)
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	e14080e7          	jalr	-492(ra) # 80003710 <balloc>
    80003904:	0005091b          	sext.w	s2,a0
      if(addr){
    80003908:	fc090ae3          	beqz	s2,800038dc <bmap+0x9a>
        a[bn] = addr;
    8000390c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003910:	8552                	mv	a0,s4
    80003912:	00001097          	auipc	ra,0x1
    80003916:	ec6080e7          	jalr	-314(ra) # 800047d8 <log_write>
    8000391a:	b7c9                	j	800038dc <bmap+0x9a>
  panic("bmap: out of range");
    8000391c:	00005517          	auipc	a0,0x5
    80003920:	e0450513          	addi	a0,a0,-508 # 80008720 <syscalls+0x160>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	c18080e7          	jalr	-1000(ra) # 8000053c <panic>

000000008000392c <iget>:
{
    8000392c:	7179                	addi	sp,sp,-48
    8000392e:	f406                	sd	ra,40(sp)
    80003930:	f022                	sd	s0,32(sp)
    80003932:	ec26                	sd	s1,24(sp)
    80003934:	e84a                	sd	s2,16(sp)
    80003936:	e44e                	sd	s3,8(sp)
    80003938:	e052                	sd	s4,0(sp)
    8000393a:	1800                	addi	s0,sp,48
    8000393c:	89aa                	mv	s3,a0
    8000393e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003940:	00024517          	auipc	a0,0x24
    80003944:	91850513          	addi	a0,a0,-1768 # 80027258 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	37e080e7          	jalr	894(ra) # 80000cc6 <acquire>
  empty = 0;
    80003950:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003952:	00024497          	auipc	s1,0x24
    80003956:	91e48493          	addi	s1,s1,-1762 # 80027270 <itable+0x18>
    8000395a:	00025697          	auipc	a3,0x25
    8000395e:	3a668693          	addi	a3,a3,934 # 80028d00 <log>
    80003962:	a039                	j	80003970 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003964:	02090b63          	beqz	s2,8000399a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003968:	08848493          	addi	s1,s1,136
    8000396c:	02d48a63          	beq	s1,a3,800039a0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003970:	449c                	lw	a5,8(s1)
    80003972:	fef059e3          	blez	a5,80003964 <iget+0x38>
    80003976:	4098                	lw	a4,0(s1)
    80003978:	ff3716e3          	bne	a4,s3,80003964 <iget+0x38>
    8000397c:	40d8                	lw	a4,4(s1)
    8000397e:	ff4713e3          	bne	a4,s4,80003964 <iget+0x38>
      ip->ref++;
    80003982:	2785                	addiw	a5,a5,1
    80003984:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003986:	00024517          	auipc	a0,0x24
    8000398a:	8d250513          	addi	a0,a0,-1838 # 80027258 <itable>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	3ec080e7          	jalr	1004(ra) # 80000d7a <release>
      return ip;
    80003996:	8926                	mv	s2,s1
    80003998:	a03d                	j	800039c6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399a:	f7f9                	bnez	a5,80003968 <iget+0x3c>
    8000399c:	8926                	mv	s2,s1
    8000399e:	b7e9                	j	80003968 <iget+0x3c>
  if(empty == 0)
    800039a0:	02090c63          	beqz	s2,800039d8 <iget+0xac>
  ip->dev = dev;
    800039a4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039a8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039ac:	4785                	li	a5,1
    800039ae:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039b2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039b6:	00024517          	auipc	a0,0x24
    800039ba:	8a250513          	addi	a0,a0,-1886 # 80027258 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	3bc080e7          	jalr	956(ra) # 80000d7a <release>
}
    800039c6:	854a                	mv	a0,s2
    800039c8:	70a2                	ld	ra,40(sp)
    800039ca:	7402                	ld	s0,32(sp)
    800039cc:	64e2                	ld	s1,24(sp)
    800039ce:	6942                	ld	s2,16(sp)
    800039d0:	69a2                	ld	s3,8(sp)
    800039d2:	6a02                	ld	s4,0(sp)
    800039d4:	6145                	addi	sp,sp,48
    800039d6:	8082                	ret
    panic("iget: no inodes");
    800039d8:	00005517          	auipc	a0,0x5
    800039dc:	d6050513          	addi	a0,a0,-672 # 80008738 <syscalls+0x178>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	b5c080e7          	jalr	-1188(ra) # 8000053c <panic>

00000000800039e8 <fsinit>:
fsinit(int dev) {
    800039e8:	7179                	addi	sp,sp,-48
    800039ea:	f406                	sd	ra,40(sp)
    800039ec:	f022                	sd	s0,32(sp)
    800039ee:	ec26                	sd	s1,24(sp)
    800039f0:	e84a                	sd	s2,16(sp)
    800039f2:	e44e                	sd	s3,8(sp)
    800039f4:	1800                	addi	s0,sp,48
    800039f6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039f8:	4585                	li	a1,1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	a56080e7          	jalr	-1450(ra) # 80003450 <bread>
    80003a02:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a04:	00024997          	auipc	s3,0x24
    80003a08:	83498993          	addi	s3,s3,-1996 # 80027238 <sb>
    80003a0c:	02000613          	li	a2,32
    80003a10:	05850593          	addi	a1,a0,88
    80003a14:	854e                	mv	a0,s3
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	408080e7          	jalr	1032(ra) # 80000e1e <memmove>
  brelse(bp);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	b60080e7          	jalr	-1184(ra) # 80003580 <brelse>
  if(sb.magic != FSMAGIC)
    80003a28:	0009a703          	lw	a4,0(s3)
    80003a2c:	102037b7          	lui	a5,0x10203
    80003a30:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a34:	02f71263          	bne	a4,a5,80003a58 <fsinit+0x70>
  initlog(dev, &sb);
    80003a38:	00024597          	auipc	a1,0x24
    80003a3c:	80058593          	addi	a1,a1,-2048 # 80027238 <sb>
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	b2c080e7          	jalr	-1236(ra) # 8000456e <initlog>
}
    80003a4a:	70a2                	ld	ra,40(sp)
    80003a4c:	7402                	ld	s0,32(sp)
    80003a4e:	64e2                	ld	s1,24(sp)
    80003a50:	6942                	ld	s2,16(sp)
    80003a52:	69a2                	ld	s3,8(sp)
    80003a54:	6145                	addi	sp,sp,48
    80003a56:	8082                	ret
    panic("invalid file system");
    80003a58:	00005517          	auipc	a0,0x5
    80003a5c:	cf050513          	addi	a0,a0,-784 # 80008748 <syscalls+0x188>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	adc080e7          	jalr	-1316(ra) # 8000053c <panic>

0000000080003a68 <iinit>:
{
    80003a68:	7179                	addi	sp,sp,-48
    80003a6a:	f406                	sd	ra,40(sp)
    80003a6c:	f022                	sd	s0,32(sp)
    80003a6e:	ec26                	sd	s1,24(sp)
    80003a70:	e84a                	sd	s2,16(sp)
    80003a72:	e44e                	sd	s3,8(sp)
    80003a74:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a76:	00005597          	auipc	a1,0x5
    80003a7a:	cea58593          	addi	a1,a1,-790 # 80008760 <syscalls+0x1a0>
    80003a7e:	00023517          	auipc	a0,0x23
    80003a82:	7da50513          	addi	a0,a0,2010 # 80027258 <itable>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	1b0080e7          	jalr	432(ra) # 80000c36 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a8e:	00023497          	auipc	s1,0x23
    80003a92:	7f248493          	addi	s1,s1,2034 # 80027280 <itable+0x28>
    80003a96:	00025997          	auipc	s3,0x25
    80003a9a:	27a98993          	addi	s3,s3,634 # 80028d10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a9e:	00005917          	auipc	s2,0x5
    80003aa2:	cca90913          	addi	s2,s2,-822 # 80008768 <syscalls+0x1a8>
    80003aa6:	85ca                	mv	a1,s2
    80003aa8:	8526                	mv	a0,s1
    80003aaa:	00001097          	auipc	ra,0x1
    80003aae:	e12080e7          	jalr	-494(ra) # 800048bc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ab2:	08848493          	addi	s1,s1,136
    80003ab6:	ff3498e3          	bne	s1,s3,80003aa6 <iinit+0x3e>
}
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6145                	addi	sp,sp,48
    80003ac6:	8082                	ret

0000000080003ac8 <ialloc>:
{
    80003ac8:	7139                	addi	sp,sp,-64
    80003aca:	fc06                	sd	ra,56(sp)
    80003acc:	f822                	sd	s0,48(sp)
    80003ace:	f426                	sd	s1,40(sp)
    80003ad0:	f04a                	sd	s2,32(sp)
    80003ad2:	ec4e                	sd	s3,24(sp)
    80003ad4:	e852                	sd	s4,16(sp)
    80003ad6:	e456                	sd	s5,8(sp)
    80003ad8:	e05a                	sd	s6,0(sp)
    80003ada:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003adc:	00023717          	auipc	a4,0x23
    80003ae0:	76872703          	lw	a4,1896(a4) # 80027244 <sb+0xc>
    80003ae4:	4785                	li	a5,1
    80003ae6:	04e7f863          	bgeu	a5,a4,80003b36 <ialloc+0x6e>
    80003aea:	8aaa                	mv	s5,a0
    80003aec:	8b2e                	mv	s6,a1
    80003aee:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003af0:	00023a17          	auipc	s4,0x23
    80003af4:	748a0a13          	addi	s4,s4,1864 # 80027238 <sb>
    80003af8:	00495593          	srli	a1,s2,0x4
    80003afc:	018a2783          	lw	a5,24(s4)
    80003b00:	9dbd                	addw	a1,a1,a5
    80003b02:	8556                	mv	a0,s5
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	94c080e7          	jalr	-1716(ra) # 80003450 <bread>
    80003b0c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b0e:	05850993          	addi	s3,a0,88
    80003b12:	00f97793          	andi	a5,s2,15
    80003b16:	079a                	slli	a5,a5,0x6
    80003b18:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b1a:	00099783          	lh	a5,0(s3)
    80003b1e:	cf9d                	beqz	a5,80003b5c <ialloc+0x94>
    brelse(bp);
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	a60080e7          	jalr	-1440(ra) # 80003580 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b28:	0905                	addi	s2,s2,1
    80003b2a:	00ca2703          	lw	a4,12(s4)
    80003b2e:	0009079b          	sext.w	a5,s2
    80003b32:	fce7e3e3          	bltu	a5,a4,80003af8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	c3a50513          	addi	a0,a0,-966 # 80008770 <syscalls+0x1b0>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	a5a080e7          	jalr	-1446(ra) # 80000598 <printf>
  return 0;
    80003b46:	4501                	li	a0,0
}
    80003b48:	70e2                	ld	ra,56(sp)
    80003b4a:	7442                	ld	s0,48(sp)
    80003b4c:	74a2                	ld	s1,40(sp)
    80003b4e:	7902                	ld	s2,32(sp)
    80003b50:	69e2                	ld	s3,24(sp)
    80003b52:	6a42                	ld	s4,16(sp)
    80003b54:	6aa2                	ld	s5,8(sp)
    80003b56:	6b02                	ld	s6,0(sp)
    80003b58:	6121                	addi	sp,sp,64
    80003b5a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b5c:	04000613          	li	a2,64
    80003b60:	4581                	li	a1,0
    80003b62:	854e                	mv	a0,s3
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	25e080e7          	jalr	606(ra) # 80000dc2 <memset>
      dip->type = type;
    80003b6c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b70:	8526                	mv	a0,s1
    80003b72:	00001097          	auipc	ra,0x1
    80003b76:	c66080e7          	jalr	-922(ra) # 800047d8 <log_write>
      brelse(bp);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	a04080e7          	jalr	-1532(ra) # 80003580 <brelse>
      return iget(dev, inum);
    80003b84:	0009059b          	sext.w	a1,s2
    80003b88:	8556                	mv	a0,s5
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	da2080e7          	jalr	-606(ra) # 8000392c <iget>
    80003b92:	bf5d                	j	80003b48 <ialloc+0x80>

0000000080003b94 <iupdate>:
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	e04a                	sd	s2,0(sp)
    80003b9e:	1000                	addi	s0,sp,32
    80003ba0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba2:	415c                	lw	a5,4(a0)
    80003ba4:	0047d79b          	srliw	a5,a5,0x4
    80003ba8:	00023597          	auipc	a1,0x23
    80003bac:	6a85a583          	lw	a1,1704(a1) # 80027250 <sb+0x18>
    80003bb0:	9dbd                	addw	a1,a1,a5
    80003bb2:	4108                	lw	a0,0(a0)
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	89c080e7          	jalr	-1892(ra) # 80003450 <bread>
    80003bbc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bbe:	05850793          	addi	a5,a0,88
    80003bc2:	40d8                	lw	a4,4(s1)
    80003bc4:	8b3d                	andi	a4,a4,15
    80003bc6:	071a                	slli	a4,a4,0x6
    80003bc8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003bca:	04449703          	lh	a4,68(s1)
    80003bce:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003bd2:	04649703          	lh	a4,70(s1)
    80003bd6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bda:	04849703          	lh	a4,72(s1)
    80003bde:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003be2:	04a49703          	lh	a4,74(s1)
    80003be6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bea:	44f8                	lw	a4,76(s1)
    80003bec:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bee:	03400613          	li	a2,52
    80003bf2:	05048593          	addi	a1,s1,80
    80003bf6:	00c78513          	addi	a0,a5,12
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	224080e7          	jalr	548(ra) # 80000e1e <memmove>
  log_write(bp);
    80003c02:	854a                	mv	a0,s2
    80003c04:	00001097          	auipc	ra,0x1
    80003c08:	bd4080e7          	jalr	-1068(ra) # 800047d8 <log_write>
  brelse(bp);
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	972080e7          	jalr	-1678(ra) # 80003580 <brelse>
}
    80003c16:	60e2                	ld	ra,24(sp)
    80003c18:	6442                	ld	s0,16(sp)
    80003c1a:	64a2                	ld	s1,8(sp)
    80003c1c:	6902                	ld	s2,0(sp)
    80003c1e:	6105                	addi	sp,sp,32
    80003c20:	8082                	ret

0000000080003c22 <idup>:
{
    80003c22:	1101                	addi	sp,sp,-32
    80003c24:	ec06                	sd	ra,24(sp)
    80003c26:	e822                	sd	s0,16(sp)
    80003c28:	e426                	sd	s1,8(sp)
    80003c2a:	1000                	addi	s0,sp,32
    80003c2c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c2e:	00023517          	auipc	a0,0x23
    80003c32:	62a50513          	addi	a0,a0,1578 # 80027258 <itable>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	090080e7          	jalr	144(ra) # 80000cc6 <acquire>
  ip->ref++;
    80003c3e:	449c                	lw	a5,8(s1)
    80003c40:	2785                	addiw	a5,a5,1
    80003c42:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c44:	00023517          	auipc	a0,0x23
    80003c48:	61450513          	addi	a0,a0,1556 # 80027258 <itable>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	12e080e7          	jalr	302(ra) # 80000d7a <release>
}
    80003c54:	8526                	mv	a0,s1
    80003c56:	60e2                	ld	ra,24(sp)
    80003c58:	6442                	ld	s0,16(sp)
    80003c5a:	64a2                	ld	s1,8(sp)
    80003c5c:	6105                	addi	sp,sp,32
    80003c5e:	8082                	ret

0000000080003c60 <ilock>:
{
    80003c60:	1101                	addi	sp,sp,-32
    80003c62:	ec06                	sd	ra,24(sp)
    80003c64:	e822                	sd	s0,16(sp)
    80003c66:	e426                	sd	s1,8(sp)
    80003c68:	e04a                	sd	s2,0(sp)
    80003c6a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c6c:	c115                	beqz	a0,80003c90 <ilock+0x30>
    80003c6e:	84aa                	mv	s1,a0
    80003c70:	451c                	lw	a5,8(a0)
    80003c72:	00f05f63          	blez	a5,80003c90 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c76:	0541                	addi	a0,a0,16
    80003c78:	00001097          	auipc	ra,0x1
    80003c7c:	c7e080e7          	jalr	-898(ra) # 800048f6 <acquiresleep>
  if(ip->valid == 0){
    80003c80:	40bc                	lw	a5,64(s1)
    80003c82:	cf99                	beqz	a5,80003ca0 <ilock+0x40>
}
    80003c84:	60e2                	ld	ra,24(sp)
    80003c86:	6442                	ld	s0,16(sp)
    80003c88:	64a2                	ld	s1,8(sp)
    80003c8a:	6902                	ld	s2,0(sp)
    80003c8c:	6105                	addi	sp,sp,32
    80003c8e:	8082                	ret
    panic("ilock");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	af850513          	addi	a0,a0,-1288 # 80008788 <syscalls+0x1c8>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8a4080e7          	jalr	-1884(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ca0:	40dc                	lw	a5,4(s1)
    80003ca2:	0047d79b          	srliw	a5,a5,0x4
    80003ca6:	00023597          	auipc	a1,0x23
    80003caa:	5aa5a583          	lw	a1,1450(a1) # 80027250 <sb+0x18>
    80003cae:	9dbd                	addw	a1,a1,a5
    80003cb0:	4088                	lw	a0,0(s1)
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	79e080e7          	jalr	1950(ra) # 80003450 <bread>
    80003cba:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cbc:	05850593          	addi	a1,a0,88
    80003cc0:	40dc                	lw	a5,4(s1)
    80003cc2:	8bbd                	andi	a5,a5,15
    80003cc4:	079a                	slli	a5,a5,0x6
    80003cc6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cc8:	00059783          	lh	a5,0(a1)
    80003ccc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cd0:	00259783          	lh	a5,2(a1)
    80003cd4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cd8:	00459783          	lh	a5,4(a1)
    80003cdc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ce0:	00659783          	lh	a5,6(a1)
    80003ce4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ce8:	459c                	lw	a5,8(a1)
    80003cea:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cec:	03400613          	li	a2,52
    80003cf0:	05b1                	addi	a1,a1,12
    80003cf2:	05048513          	addi	a0,s1,80
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	128080e7          	jalr	296(ra) # 80000e1e <memmove>
    brelse(bp);
    80003cfe:	854a                	mv	a0,s2
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	880080e7          	jalr	-1920(ra) # 80003580 <brelse>
    ip->valid = 1;
    80003d08:	4785                	li	a5,1
    80003d0a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d0c:	04449783          	lh	a5,68(s1)
    80003d10:	fbb5                	bnez	a5,80003c84 <ilock+0x24>
      panic("ilock: no type");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	a7e50513          	addi	a0,a0,-1410 # 80008790 <syscalls+0x1d0>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	822080e7          	jalr	-2014(ra) # 8000053c <panic>

0000000080003d22 <iunlock>:
{
    80003d22:	1101                	addi	sp,sp,-32
    80003d24:	ec06                	sd	ra,24(sp)
    80003d26:	e822                	sd	s0,16(sp)
    80003d28:	e426                	sd	s1,8(sp)
    80003d2a:	e04a                	sd	s2,0(sp)
    80003d2c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d2e:	c905                	beqz	a0,80003d5e <iunlock+0x3c>
    80003d30:	84aa                	mv	s1,a0
    80003d32:	01050913          	addi	s2,a0,16
    80003d36:	854a                	mv	a0,s2
    80003d38:	00001097          	auipc	ra,0x1
    80003d3c:	c58080e7          	jalr	-936(ra) # 80004990 <holdingsleep>
    80003d40:	cd19                	beqz	a0,80003d5e <iunlock+0x3c>
    80003d42:	449c                	lw	a5,8(s1)
    80003d44:	00f05d63          	blez	a5,80003d5e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d48:	854a                	mv	a0,s2
    80003d4a:	00001097          	auipc	ra,0x1
    80003d4e:	c02080e7          	jalr	-1022(ra) # 8000494c <releasesleep>
}
    80003d52:	60e2                	ld	ra,24(sp)
    80003d54:	6442                	ld	s0,16(sp)
    80003d56:	64a2                	ld	s1,8(sp)
    80003d58:	6902                	ld	s2,0(sp)
    80003d5a:	6105                	addi	sp,sp,32
    80003d5c:	8082                	ret
    panic("iunlock");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	a4250513          	addi	a0,a0,-1470 # 800087a0 <syscalls+0x1e0>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7d6080e7          	jalr	2006(ra) # 8000053c <panic>

0000000080003d6e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d6e:	7179                	addi	sp,sp,-48
    80003d70:	f406                	sd	ra,40(sp)
    80003d72:	f022                	sd	s0,32(sp)
    80003d74:	ec26                	sd	s1,24(sp)
    80003d76:	e84a                	sd	s2,16(sp)
    80003d78:	e44e                	sd	s3,8(sp)
    80003d7a:	e052                	sd	s4,0(sp)
    80003d7c:	1800                	addi	s0,sp,48
    80003d7e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d80:	05050493          	addi	s1,a0,80
    80003d84:	08050913          	addi	s2,a0,128
    80003d88:	a021                	j	80003d90 <itrunc+0x22>
    80003d8a:	0491                	addi	s1,s1,4
    80003d8c:	01248d63          	beq	s1,s2,80003da6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d90:	408c                	lw	a1,0(s1)
    80003d92:	dde5                	beqz	a1,80003d8a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d94:	0009a503          	lw	a0,0(s3)
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	8fc080e7          	jalr	-1796(ra) # 80003694 <bfree>
      ip->addrs[i] = 0;
    80003da0:	0004a023          	sw	zero,0(s1)
    80003da4:	b7dd                	j	80003d8a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003da6:	0809a583          	lw	a1,128(s3)
    80003daa:	e185                	bnez	a1,80003dca <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dac:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	de2080e7          	jalr	-542(ra) # 80003b94 <iupdate>
}
    80003dba:	70a2                	ld	ra,40(sp)
    80003dbc:	7402                	ld	s0,32(sp)
    80003dbe:	64e2                	ld	s1,24(sp)
    80003dc0:	6942                	ld	s2,16(sp)
    80003dc2:	69a2                	ld	s3,8(sp)
    80003dc4:	6a02                	ld	s4,0(sp)
    80003dc6:	6145                	addi	sp,sp,48
    80003dc8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dca:	0009a503          	lw	a0,0(s3)
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	682080e7          	jalr	1666(ra) # 80003450 <bread>
    80003dd6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dd8:	05850493          	addi	s1,a0,88
    80003ddc:	45850913          	addi	s2,a0,1112
    80003de0:	a021                	j	80003de8 <itrunc+0x7a>
    80003de2:	0491                	addi	s1,s1,4
    80003de4:	01248b63          	beq	s1,s2,80003dfa <itrunc+0x8c>
      if(a[j])
    80003de8:	408c                	lw	a1,0(s1)
    80003dea:	dde5                	beqz	a1,80003de2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dec:	0009a503          	lw	a0,0(s3)
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	8a4080e7          	jalr	-1884(ra) # 80003694 <bfree>
    80003df8:	b7ed                	j	80003de2 <itrunc+0x74>
    brelse(bp);
    80003dfa:	8552                	mv	a0,s4
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	784080e7          	jalr	1924(ra) # 80003580 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e04:	0809a583          	lw	a1,128(s3)
    80003e08:	0009a503          	lw	a0,0(s3)
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	888080e7          	jalr	-1912(ra) # 80003694 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e14:	0809a023          	sw	zero,128(s3)
    80003e18:	bf51                	j	80003dac <itrunc+0x3e>

0000000080003e1a <iput>:
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e28:	00023517          	auipc	a0,0x23
    80003e2c:	43050513          	addi	a0,a0,1072 # 80027258 <itable>
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	e96080e7          	jalr	-362(ra) # 80000cc6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e38:	4498                	lw	a4,8(s1)
    80003e3a:	4785                	li	a5,1
    80003e3c:	02f70363          	beq	a4,a5,80003e62 <iput+0x48>
  ip->ref--;
    80003e40:	449c                	lw	a5,8(s1)
    80003e42:	37fd                	addiw	a5,a5,-1
    80003e44:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e46:	00023517          	auipc	a0,0x23
    80003e4a:	41250513          	addi	a0,a0,1042 # 80027258 <itable>
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	f2c080e7          	jalr	-212(ra) # 80000d7a <release>
}
    80003e56:	60e2                	ld	ra,24(sp)
    80003e58:	6442                	ld	s0,16(sp)
    80003e5a:	64a2                	ld	s1,8(sp)
    80003e5c:	6902                	ld	s2,0(sp)
    80003e5e:	6105                	addi	sp,sp,32
    80003e60:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e62:	40bc                	lw	a5,64(s1)
    80003e64:	dff1                	beqz	a5,80003e40 <iput+0x26>
    80003e66:	04a49783          	lh	a5,74(s1)
    80003e6a:	fbf9                	bnez	a5,80003e40 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e6c:	01048913          	addi	s2,s1,16
    80003e70:	854a                	mv	a0,s2
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	a84080e7          	jalr	-1404(ra) # 800048f6 <acquiresleep>
    release(&itable.lock);
    80003e7a:	00023517          	auipc	a0,0x23
    80003e7e:	3de50513          	addi	a0,a0,990 # 80027258 <itable>
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	ef8080e7          	jalr	-264(ra) # 80000d7a <release>
    itrunc(ip);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	ee2080e7          	jalr	-286(ra) # 80003d6e <itrunc>
    ip->type = 0;
    80003e94:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	cfa080e7          	jalr	-774(ra) # 80003b94 <iupdate>
    ip->valid = 0;
    80003ea2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00001097          	auipc	ra,0x1
    80003eac:	aa4080e7          	jalr	-1372(ra) # 8000494c <releasesleep>
    acquire(&itable.lock);
    80003eb0:	00023517          	auipc	a0,0x23
    80003eb4:	3a850513          	addi	a0,a0,936 # 80027258 <itable>
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	e0e080e7          	jalr	-498(ra) # 80000cc6 <acquire>
    80003ec0:	b741                	j	80003e40 <iput+0x26>

0000000080003ec2 <iunlockput>:
{
    80003ec2:	1101                	addi	sp,sp,-32
    80003ec4:	ec06                	sd	ra,24(sp)
    80003ec6:	e822                	sd	s0,16(sp)
    80003ec8:	e426                	sd	s1,8(sp)
    80003eca:	1000                	addi	s0,sp,32
    80003ecc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	e54080e7          	jalr	-428(ra) # 80003d22 <iunlock>
  iput(ip);
    80003ed6:	8526                	mv	a0,s1
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	f42080e7          	jalr	-190(ra) # 80003e1a <iput>
}
    80003ee0:	60e2                	ld	ra,24(sp)
    80003ee2:	6442                	ld	s0,16(sp)
    80003ee4:	64a2                	ld	s1,8(sp)
    80003ee6:	6105                	addi	sp,sp,32
    80003ee8:	8082                	ret

0000000080003eea <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eea:	1141                	addi	sp,sp,-16
    80003eec:	e422                	sd	s0,8(sp)
    80003eee:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ef0:	411c                	lw	a5,0(a0)
    80003ef2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ef4:	415c                	lw	a5,4(a0)
    80003ef6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ef8:	04451783          	lh	a5,68(a0)
    80003efc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f00:	04a51783          	lh	a5,74(a0)
    80003f04:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f08:	04c56783          	lwu	a5,76(a0)
    80003f0c:	e99c                	sd	a5,16(a1)
}
    80003f0e:	6422                	ld	s0,8(sp)
    80003f10:	0141                	addi	sp,sp,16
    80003f12:	8082                	ret

0000000080003f14 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f14:	457c                	lw	a5,76(a0)
    80003f16:	0ed7e963          	bltu	a5,a3,80004008 <readi+0xf4>
{
    80003f1a:	7159                	addi	sp,sp,-112
    80003f1c:	f486                	sd	ra,104(sp)
    80003f1e:	f0a2                	sd	s0,96(sp)
    80003f20:	eca6                	sd	s1,88(sp)
    80003f22:	e8ca                	sd	s2,80(sp)
    80003f24:	e4ce                	sd	s3,72(sp)
    80003f26:	e0d2                	sd	s4,64(sp)
    80003f28:	fc56                	sd	s5,56(sp)
    80003f2a:	f85a                	sd	s6,48(sp)
    80003f2c:	f45e                	sd	s7,40(sp)
    80003f2e:	f062                	sd	s8,32(sp)
    80003f30:	ec66                	sd	s9,24(sp)
    80003f32:	e86a                	sd	s10,16(sp)
    80003f34:	e46e                	sd	s11,8(sp)
    80003f36:	1880                	addi	s0,sp,112
    80003f38:	8b2a                	mv	s6,a0
    80003f3a:	8bae                	mv	s7,a1
    80003f3c:	8a32                	mv	s4,a2
    80003f3e:	84b6                	mv	s1,a3
    80003f40:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f42:	9f35                	addw	a4,a4,a3
    return 0;
    80003f44:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f46:	0ad76063          	bltu	a4,a3,80003fe6 <readi+0xd2>
  if(off + n > ip->size)
    80003f4a:	00e7f463          	bgeu	a5,a4,80003f52 <readi+0x3e>
    n = ip->size - off;
    80003f4e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f52:	0a0a8963          	beqz	s5,80004004 <readi+0xf0>
    80003f56:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f58:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f5c:	5c7d                	li	s8,-1
    80003f5e:	a82d                	j	80003f98 <readi+0x84>
    80003f60:	020d1d93          	slli	s11,s10,0x20
    80003f64:	020ddd93          	srli	s11,s11,0x20
    80003f68:	05890613          	addi	a2,s2,88
    80003f6c:	86ee                	mv	a3,s11
    80003f6e:	963a                	add	a2,a2,a4
    80003f70:	85d2                	mv	a1,s4
    80003f72:	855e                	mv	a0,s7
    80003f74:	ffffe097          	auipc	ra,0xffffe
    80003f78:	7b2080e7          	jalr	1970(ra) # 80002726 <either_copyout>
    80003f7c:	05850d63          	beq	a0,s8,80003fd6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f80:	854a                	mv	a0,s2
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	5fe080e7          	jalr	1534(ra) # 80003580 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8a:	013d09bb          	addw	s3,s10,s3
    80003f8e:	009d04bb          	addw	s1,s10,s1
    80003f92:	9a6e                	add	s4,s4,s11
    80003f94:	0559f763          	bgeu	s3,s5,80003fe2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f98:	00a4d59b          	srliw	a1,s1,0xa
    80003f9c:	855a                	mv	a0,s6
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	8a4080e7          	jalr	-1884(ra) # 80003842 <bmap>
    80003fa6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003faa:	cd85                	beqz	a1,80003fe2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fac:	000b2503          	lw	a0,0(s6)
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	4a0080e7          	jalr	1184(ra) # 80003450 <bread>
    80003fb8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fba:	3ff4f713          	andi	a4,s1,1023
    80003fbe:	40ec87bb          	subw	a5,s9,a4
    80003fc2:	413a86bb          	subw	a3,s5,s3
    80003fc6:	8d3e                	mv	s10,a5
    80003fc8:	2781                	sext.w	a5,a5
    80003fca:	0006861b          	sext.w	a2,a3
    80003fce:	f8f679e3          	bgeu	a2,a5,80003f60 <readi+0x4c>
    80003fd2:	8d36                	mv	s10,a3
    80003fd4:	b771                	j	80003f60 <readi+0x4c>
      brelse(bp);
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	5a8080e7          	jalr	1448(ra) # 80003580 <brelse>
      tot = -1;
    80003fe0:	59fd                	li	s3,-1
  }
  return tot;
    80003fe2:	0009851b          	sext.w	a0,s3
}
    80003fe6:	70a6                	ld	ra,104(sp)
    80003fe8:	7406                	ld	s0,96(sp)
    80003fea:	64e6                	ld	s1,88(sp)
    80003fec:	6946                	ld	s2,80(sp)
    80003fee:	69a6                	ld	s3,72(sp)
    80003ff0:	6a06                	ld	s4,64(sp)
    80003ff2:	7ae2                	ld	s5,56(sp)
    80003ff4:	7b42                	ld	s6,48(sp)
    80003ff6:	7ba2                	ld	s7,40(sp)
    80003ff8:	7c02                	ld	s8,32(sp)
    80003ffa:	6ce2                	ld	s9,24(sp)
    80003ffc:	6d42                	ld	s10,16(sp)
    80003ffe:	6da2                	ld	s11,8(sp)
    80004000:	6165                	addi	sp,sp,112
    80004002:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004004:	89d6                	mv	s3,s5
    80004006:	bff1                	j	80003fe2 <readi+0xce>
    return 0;
    80004008:	4501                	li	a0,0
}
    8000400a:	8082                	ret

000000008000400c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000400c:	457c                	lw	a5,76(a0)
    8000400e:	10d7e863          	bltu	a5,a3,8000411e <writei+0x112>
{
    80004012:	7159                	addi	sp,sp,-112
    80004014:	f486                	sd	ra,104(sp)
    80004016:	f0a2                	sd	s0,96(sp)
    80004018:	eca6                	sd	s1,88(sp)
    8000401a:	e8ca                	sd	s2,80(sp)
    8000401c:	e4ce                	sd	s3,72(sp)
    8000401e:	e0d2                	sd	s4,64(sp)
    80004020:	fc56                	sd	s5,56(sp)
    80004022:	f85a                	sd	s6,48(sp)
    80004024:	f45e                	sd	s7,40(sp)
    80004026:	f062                	sd	s8,32(sp)
    80004028:	ec66                	sd	s9,24(sp)
    8000402a:	e86a                	sd	s10,16(sp)
    8000402c:	e46e                	sd	s11,8(sp)
    8000402e:	1880                	addi	s0,sp,112
    80004030:	8aaa                	mv	s5,a0
    80004032:	8bae                	mv	s7,a1
    80004034:	8a32                	mv	s4,a2
    80004036:	8936                	mv	s2,a3
    80004038:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000403a:	00e687bb          	addw	a5,a3,a4
    8000403e:	0ed7e263          	bltu	a5,a3,80004122 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004042:	00043737          	lui	a4,0x43
    80004046:	0ef76063          	bltu	a4,a5,80004126 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404a:	0c0b0863          	beqz	s6,8000411a <writei+0x10e>
    8000404e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004050:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004054:	5c7d                	li	s8,-1
    80004056:	a091                	j	8000409a <writei+0x8e>
    80004058:	020d1d93          	slli	s11,s10,0x20
    8000405c:	020ddd93          	srli	s11,s11,0x20
    80004060:	05848513          	addi	a0,s1,88
    80004064:	86ee                	mv	a3,s11
    80004066:	8652                	mv	a2,s4
    80004068:	85de                	mv	a1,s7
    8000406a:	953a                	add	a0,a0,a4
    8000406c:	ffffe097          	auipc	ra,0xffffe
    80004070:	710080e7          	jalr	1808(ra) # 8000277c <either_copyin>
    80004074:	07850263          	beq	a0,s8,800040d8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004078:	8526                	mv	a0,s1
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	75e080e7          	jalr	1886(ra) # 800047d8 <log_write>
    brelse(bp);
    80004082:	8526                	mv	a0,s1
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	4fc080e7          	jalr	1276(ra) # 80003580 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000408c:	013d09bb          	addw	s3,s10,s3
    80004090:	012d093b          	addw	s2,s10,s2
    80004094:	9a6e                	add	s4,s4,s11
    80004096:	0569f663          	bgeu	s3,s6,800040e2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000409a:	00a9559b          	srliw	a1,s2,0xa
    8000409e:	8556                	mv	a0,s5
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	7a2080e7          	jalr	1954(ra) # 80003842 <bmap>
    800040a8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040ac:	c99d                	beqz	a1,800040e2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040ae:	000aa503          	lw	a0,0(s5)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	39e080e7          	jalr	926(ra) # 80003450 <bread>
    800040ba:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040bc:	3ff97713          	andi	a4,s2,1023
    800040c0:	40ec87bb          	subw	a5,s9,a4
    800040c4:	413b06bb          	subw	a3,s6,s3
    800040c8:	8d3e                	mv	s10,a5
    800040ca:	2781                	sext.w	a5,a5
    800040cc:	0006861b          	sext.w	a2,a3
    800040d0:	f8f674e3          	bgeu	a2,a5,80004058 <writei+0x4c>
    800040d4:	8d36                	mv	s10,a3
    800040d6:	b749                	j	80004058 <writei+0x4c>
      brelse(bp);
    800040d8:	8526                	mv	a0,s1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	4a6080e7          	jalr	1190(ra) # 80003580 <brelse>
  }

  if(off > ip->size)
    800040e2:	04caa783          	lw	a5,76(s5)
    800040e6:	0127f463          	bgeu	a5,s2,800040ee <writei+0xe2>
    ip->size = off;
    800040ea:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040ee:	8556                	mv	a0,s5
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	aa4080e7          	jalr	-1372(ra) # 80003b94 <iupdate>

  return tot;
    800040f8:	0009851b          	sext.w	a0,s3
}
    800040fc:	70a6                	ld	ra,104(sp)
    800040fe:	7406                	ld	s0,96(sp)
    80004100:	64e6                	ld	s1,88(sp)
    80004102:	6946                	ld	s2,80(sp)
    80004104:	69a6                	ld	s3,72(sp)
    80004106:	6a06                	ld	s4,64(sp)
    80004108:	7ae2                	ld	s5,56(sp)
    8000410a:	7b42                	ld	s6,48(sp)
    8000410c:	7ba2                	ld	s7,40(sp)
    8000410e:	7c02                	ld	s8,32(sp)
    80004110:	6ce2                	ld	s9,24(sp)
    80004112:	6d42                	ld	s10,16(sp)
    80004114:	6da2                	ld	s11,8(sp)
    80004116:	6165                	addi	sp,sp,112
    80004118:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411a:	89da                	mv	s3,s6
    8000411c:	bfc9                	j	800040ee <writei+0xe2>
    return -1;
    8000411e:	557d                	li	a0,-1
}
    80004120:	8082                	ret
    return -1;
    80004122:	557d                	li	a0,-1
    80004124:	bfe1                	j	800040fc <writei+0xf0>
    return -1;
    80004126:	557d                	li	a0,-1
    80004128:	bfd1                	j	800040fc <writei+0xf0>

000000008000412a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000412a:	1141                	addi	sp,sp,-16
    8000412c:	e406                	sd	ra,8(sp)
    8000412e:	e022                	sd	s0,0(sp)
    80004130:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004132:	4639                	li	a2,14
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	d5e080e7          	jalr	-674(ra) # 80000e92 <strncmp>
}
    8000413c:	60a2                	ld	ra,8(sp)
    8000413e:	6402                	ld	s0,0(sp)
    80004140:	0141                	addi	sp,sp,16
    80004142:	8082                	ret

0000000080004144 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004144:	7139                	addi	sp,sp,-64
    80004146:	fc06                	sd	ra,56(sp)
    80004148:	f822                	sd	s0,48(sp)
    8000414a:	f426                	sd	s1,40(sp)
    8000414c:	f04a                	sd	s2,32(sp)
    8000414e:	ec4e                	sd	s3,24(sp)
    80004150:	e852                	sd	s4,16(sp)
    80004152:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004154:	04451703          	lh	a4,68(a0)
    80004158:	4785                	li	a5,1
    8000415a:	00f71a63          	bne	a4,a5,8000416e <dirlookup+0x2a>
    8000415e:	892a                	mv	s2,a0
    80004160:	89ae                	mv	s3,a1
    80004162:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004164:	457c                	lw	a5,76(a0)
    80004166:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004168:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416a:	e79d                	bnez	a5,80004198 <dirlookup+0x54>
    8000416c:	a8a5                	j	800041e4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000416e:	00004517          	auipc	a0,0x4
    80004172:	63a50513          	addi	a0,a0,1594 # 800087a8 <syscalls+0x1e8>
    80004176:	ffffc097          	auipc	ra,0xffffc
    8000417a:	3c6080e7          	jalr	966(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000417e:	00004517          	auipc	a0,0x4
    80004182:	64250513          	addi	a0,a0,1602 # 800087c0 <syscalls+0x200>
    80004186:	ffffc097          	auipc	ra,0xffffc
    8000418a:	3b6080e7          	jalr	950(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418e:	24c1                	addiw	s1,s1,16
    80004190:	04c92783          	lw	a5,76(s2)
    80004194:	04f4f763          	bgeu	s1,a5,800041e2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004198:	4741                	li	a4,16
    8000419a:	86a6                	mv	a3,s1
    8000419c:	fc040613          	addi	a2,s0,-64
    800041a0:	4581                	li	a1,0
    800041a2:	854a                	mv	a0,s2
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	d70080e7          	jalr	-656(ra) # 80003f14 <readi>
    800041ac:	47c1                	li	a5,16
    800041ae:	fcf518e3          	bne	a0,a5,8000417e <dirlookup+0x3a>
    if(de.inum == 0)
    800041b2:	fc045783          	lhu	a5,-64(s0)
    800041b6:	dfe1                	beqz	a5,8000418e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041b8:	fc240593          	addi	a1,s0,-62
    800041bc:	854e                	mv	a0,s3
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	f6c080e7          	jalr	-148(ra) # 8000412a <namecmp>
    800041c6:	f561                	bnez	a0,8000418e <dirlookup+0x4a>
      if(poff)
    800041c8:	000a0463          	beqz	s4,800041d0 <dirlookup+0x8c>
        *poff = off;
    800041cc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041d0:	fc045583          	lhu	a1,-64(s0)
    800041d4:	00092503          	lw	a0,0(s2)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	754080e7          	jalr	1876(ra) # 8000392c <iget>
    800041e0:	a011                	j	800041e4 <dirlookup+0xa0>
  return 0;
    800041e2:	4501                	li	a0,0
}
    800041e4:	70e2                	ld	ra,56(sp)
    800041e6:	7442                	ld	s0,48(sp)
    800041e8:	74a2                	ld	s1,40(sp)
    800041ea:	7902                	ld	s2,32(sp)
    800041ec:	69e2                	ld	s3,24(sp)
    800041ee:	6a42                	ld	s4,16(sp)
    800041f0:	6121                	addi	sp,sp,64
    800041f2:	8082                	ret

00000000800041f4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041f4:	711d                	addi	sp,sp,-96
    800041f6:	ec86                	sd	ra,88(sp)
    800041f8:	e8a2                	sd	s0,80(sp)
    800041fa:	e4a6                	sd	s1,72(sp)
    800041fc:	e0ca                	sd	s2,64(sp)
    800041fe:	fc4e                	sd	s3,56(sp)
    80004200:	f852                	sd	s4,48(sp)
    80004202:	f456                	sd	s5,40(sp)
    80004204:	f05a                	sd	s6,32(sp)
    80004206:	ec5e                	sd	s7,24(sp)
    80004208:	e862                	sd	s8,16(sp)
    8000420a:	e466                	sd	s9,8(sp)
    8000420c:	1080                	addi	s0,sp,96
    8000420e:	84aa                	mv	s1,a0
    80004210:	8b2e                	mv	s6,a1
    80004212:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004214:	00054703          	lbu	a4,0(a0)
    80004218:	02f00793          	li	a5,47
    8000421c:	02f70263          	beq	a4,a5,80004240 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004220:	ffffe097          	auipc	ra,0xffffe
    80004224:	996080e7          	jalr	-1642(ra) # 80001bb6 <myproc>
    80004228:	15053503          	ld	a0,336(a0)
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	9f6080e7          	jalr	-1546(ra) # 80003c22 <idup>
    80004234:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004236:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000423a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000423c:	4b85                	li	s7,1
    8000423e:	a875                	j	800042fa <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004240:	4585                	li	a1,1
    80004242:	4505                	li	a0,1
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	6e8080e7          	jalr	1768(ra) # 8000392c <iget>
    8000424c:	8a2a                	mv	s4,a0
    8000424e:	b7e5                	j	80004236 <namex+0x42>
      iunlockput(ip);
    80004250:	8552                	mv	a0,s4
    80004252:	00000097          	auipc	ra,0x0
    80004256:	c70080e7          	jalr	-912(ra) # 80003ec2 <iunlockput>
      return 0;
    8000425a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000425c:	8552                	mv	a0,s4
    8000425e:	60e6                	ld	ra,88(sp)
    80004260:	6446                	ld	s0,80(sp)
    80004262:	64a6                	ld	s1,72(sp)
    80004264:	6906                	ld	s2,64(sp)
    80004266:	79e2                	ld	s3,56(sp)
    80004268:	7a42                	ld	s4,48(sp)
    8000426a:	7aa2                	ld	s5,40(sp)
    8000426c:	7b02                	ld	s6,32(sp)
    8000426e:	6be2                	ld	s7,24(sp)
    80004270:	6c42                	ld	s8,16(sp)
    80004272:	6ca2                	ld	s9,8(sp)
    80004274:	6125                	addi	sp,sp,96
    80004276:	8082                	ret
      iunlock(ip);
    80004278:	8552                	mv	a0,s4
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	aa8080e7          	jalr	-1368(ra) # 80003d22 <iunlock>
      return ip;
    80004282:	bfe9                	j	8000425c <namex+0x68>
      iunlockput(ip);
    80004284:	8552                	mv	a0,s4
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	c3c080e7          	jalr	-964(ra) # 80003ec2 <iunlockput>
      return 0;
    8000428e:	8a4e                	mv	s4,s3
    80004290:	b7f1                	j	8000425c <namex+0x68>
  len = path - s;
    80004292:	40998633          	sub	a2,s3,s1
    80004296:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000429a:	099c5863          	bge	s8,s9,8000432a <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000429e:	4639                	li	a2,14
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8556                	mv	a0,s5
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	b7a080e7          	jalr	-1158(ra) # 80000e1e <memmove>
    800042ac:	84ce                	mv	s1,s3
  while(*path == '/')
    800042ae:	0004c783          	lbu	a5,0(s1)
    800042b2:	01279763          	bne	a5,s2,800042c0 <namex+0xcc>
    path++;
    800042b6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042b8:	0004c783          	lbu	a5,0(s1)
    800042bc:	ff278de3          	beq	a5,s2,800042b6 <namex+0xc2>
    ilock(ip);
    800042c0:	8552                	mv	a0,s4
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	99e080e7          	jalr	-1634(ra) # 80003c60 <ilock>
    if(ip->type != T_DIR){
    800042ca:	044a1783          	lh	a5,68(s4)
    800042ce:	f97791e3          	bne	a5,s7,80004250 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800042d2:	000b0563          	beqz	s6,800042dc <namex+0xe8>
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	dfd9                	beqz	a5,80004278 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042dc:	4601                	li	a2,0
    800042de:	85d6                	mv	a1,s5
    800042e0:	8552                	mv	a0,s4
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	e62080e7          	jalr	-414(ra) # 80004144 <dirlookup>
    800042ea:	89aa                	mv	s3,a0
    800042ec:	dd41                	beqz	a0,80004284 <namex+0x90>
    iunlockput(ip);
    800042ee:	8552                	mv	a0,s4
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	bd2080e7          	jalr	-1070(ra) # 80003ec2 <iunlockput>
    ip = next;
    800042f8:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042fa:	0004c783          	lbu	a5,0(s1)
    800042fe:	01279763          	bne	a5,s2,8000430c <namex+0x118>
    path++;
    80004302:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004304:	0004c783          	lbu	a5,0(s1)
    80004308:	ff278de3          	beq	a5,s2,80004302 <namex+0x10e>
  if(*path == 0)
    8000430c:	cb9d                	beqz	a5,80004342 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000430e:	0004c783          	lbu	a5,0(s1)
    80004312:	89a6                	mv	s3,s1
  len = path - s;
    80004314:	4c81                	li	s9,0
    80004316:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004318:	01278963          	beq	a5,s2,8000432a <namex+0x136>
    8000431c:	dbbd                	beqz	a5,80004292 <namex+0x9e>
    path++;
    8000431e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004320:	0009c783          	lbu	a5,0(s3)
    80004324:	ff279ce3          	bne	a5,s2,8000431c <namex+0x128>
    80004328:	b7ad                	j	80004292 <namex+0x9e>
    memmove(name, s, len);
    8000432a:	2601                	sext.w	a2,a2
    8000432c:	85a6                	mv	a1,s1
    8000432e:	8556                	mv	a0,s5
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	aee080e7          	jalr	-1298(ra) # 80000e1e <memmove>
    name[len] = 0;
    80004338:	9cd6                	add	s9,s9,s5
    8000433a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000433e:	84ce                	mv	s1,s3
    80004340:	b7bd                	j	800042ae <namex+0xba>
  if(nameiparent){
    80004342:	f00b0de3          	beqz	s6,8000425c <namex+0x68>
    iput(ip);
    80004346:	8552                	mv	a0,s4
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	ad2080e7          	jalr	-1326(ra) # 80003e1a <iput>
    return 0;
    80004350:	4a01                	li	s4,0
    80004352:	b729                	j	8000425c <namex+0x68>

0000000080004354 <dirlink>:
{
    80004354:	7139                	addi	sp,sp,-64
    80004356:	fc06                	sd	ra,56(sp)
    80004358:	f822                	sd	s0,48(sp)
    8000435a:	f426                	sd	s1,40(sp)
    8000435c:	f04a                	sd	s2,32(sp)
    8000435e:	ec4e                	sd	s3,24(sp)
    80004360:	e852                	sd	s4,16(sp)
    80004362:	0080                	addi	s0,sp,64
    80004364:	892a                	mv	s2,a0
    80004366:	8a2e                	mv	s4,a1
    80004368:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000436a:	4601                	li	a2,0
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	dd8080e7          	jalr	-552(ra) # 80004144 <dirlookup>
    80004374:	e93d                	bnez	a0,800043ea <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004376:	04c92483          	lw	s1,76(s2)
    8000437a:	c49d                	beqz	s1,800043a8 <dirlink+0x54>
    8000437c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000437e:	4741                	li	a4,16
    80004380:	86a6                	mv	a3,s1
    80004382:	fc040613          	addi	a2,s0,-64
    80004386:	4581                	li	a1,0
    80004388:	854a                	mv	a0,s2
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	b8a080e7          	jalr	-1142(ra) # 80003f14 <readi>
    80004392:	47c1                	li	a5,16
    80004394:	06f51163          	bne	a0,a5,800043f6 <dirlink+0xa2>
    if(de.inum == 0)
    80004398:	fc045783          	lhu	a5,-64(s0)
    8000439c:	c791                	beqz	a5,800043a8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000439e:	24c1                	addiw	s1,s1,16
    800043a0:	04c92783          	lw	a5,76(s2)
    800043a4:	fcf4ede3          	bltu	s1,a5,8000437e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043a8:	4639                	li	a2,14
    800043aa:	85d2                	mv	a1,s4
    800043ac:	fc240513          	addi	a0,s0,-62
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	b1e080e7          	jalr	-1250(ra) # 80000ece <strncpy>
  de.inum = inum;
    800043b8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043bc:	4741                	li	a4,16
    800043be:	86a6                	mv	a3,s1
    800043c0:	fc040613          	addi	a2,s0,-64
    800043c4:	4581                	li	a1,0
    800043c6:	854a                	mv	a0,s2
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	c44080e7          	jalr	-956(ra) # 8000400c <writei>
    800043d0:	1541                	addi	a0,a0,-16
    800043d2:	00a03533          	snez	a0,a0
    800043d6:	40a00533          	neg	a0,a0
}
    800043da:	70e2                	ld	ra,56(sp)
    800043dc:	7442                	ld	s0,48(sp)
    800043de:	74a2                	ld	s1,40(sp)
    800043e0:	7902                	ld	s2,32(sp)
    800043e2:	69e2                	ld	s3,24(sp)
    800043e4:	6a42                	ld	s4,16(sp)
    800043e6:	6121                	addi	sp,sp,64
    800043e8:	8082                	ret
    iput(ip);
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	a30080e7          	jalr	-1488(ra) # 80003e1a <iput>
    return -1;
    800043f2:	557d                	li	a0,-1
    800043f4:	b7dd                	j	800043da <dirlink+0x86>
      panic("dirlink read");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	3da50513          	addi	a0,a0,986 # 800087d0 <syscalls+0x210>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	13e080e7          	jalr	318(ra) # 8000053c <panic>

0000000080004406 <namei>:

struct inode*
namei(char *path)
{
    80004406:	1101                	addi	sp,sp,-32
    80004408:	ec06                	sd	ra,24(sp)
    8000440a:	e822                	sd	s0,16(sp)
    8000440c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000440e:	fe040613          	addi	a2,s0,-32
    80004412:	4581                	li	a1,0
    80004414:	00000097          	auipc	ra,0x0
    80004418:	de0080e7          	jalr	-544(ra) # 800041f4 <namex>
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	6105                	addi	sp,sp,32
    80004422:	8082                	ret

0000000080004424 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004424:	1141                	addi	sp,sp,-16
    80004426:	e406                	sd	ra,8(sp)
    80004428:	e022                	sd	s0,0(sp)
    8000442a:	0800                	addi	s0,sp,16
    8000442c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000442e:	4585                	li	a1,1
    80004430:	00000097          	auipc	ra,0x0
    80004434:	dc4080e7          	jalr	-572(ra) # 800041f4 <namex>
}
    80004438:	60a2                	ld	ra,8(sp)
    8000443a:	6402                	ld	s0,0(sp)
    8000443c:	0141                	addi	sp,sp,16
    8000443e:	8082                	ret

0000000080004440 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	e04a                	sd	s2,0(sp)
    8000444a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000444c:	00025917          	auipc	s2,0x25
    80004450:	8b490913          	addi	s2,s2,-1868 # 80028d00 <log>
    80004454:	01892583          	lw	a1,24(s2)
    80004458:	02892503          	lw	a0,40(s2)
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	ff4080e7          	jalr	-12(ra) # 80003450 <bread>
    80004464:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004466:	02c92603          	lw	a2,44(s2)
    8000446a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000446c:	00c05f63          	blez	a2,8000448a <write_head+0x4a>
    80004470:	00025717          	auipc	a4,0x25
    80004474:	8c070713          	addi	a4,a4,-1856 # 80028d30 <log+0x30>
    80004478:	87aa                	mv	a5,a0
    8000447a:	060a                	slli	a2,a2,0x2
    8000447c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000447e:	4314                	lw	a3,0(a4)
    80004480:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004482:	0711                	addi	a4,a4,4
    80004484:	0791                	addi	a5,a5,4
    80004486:	fec79ce3          	bne	a5,a2,8000447e <write_head+0x3e>
  }
  bwrite(buf);
    8000448a:	8526                	mv	a0,s1
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	0b6080e7          	jalr	182(ra) # 80003542 <bwrite>
  brelse(buf);
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	0ea080e7          	jalr	234(ra) # 80003580 <brelse>
}
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6902                	ld	s2,0(sp)
    800044a6:	6105                	addi	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044aa:	00025797          	auipc	a5,0x25
    800044ae:	8827a783          	lw	a5,-1918(a5) # 80028d2c <log+0x2c>
    800044b2:	0af05d63          	blez	a5,8000456c <install_trans+0xc2>
{
    800044b6:	7139                	addi	sp,sp,-64
    800044b8:	fc06                	sd	ra,56(sp)
    800044ba:	f822                	sd	s0,48(sp)
    800044bc:	f426                	sd	s1,40(sp)
    800044be:	f04a                	sd	s2,32(sp)
    800044c0:	ec4e                	sd	s3,24(sp)
    800044c2:	e852                	sd	s4,16(sp)
    800044c4:	e456                	sd	s5,8(sp)
    800044c6:	e05a                	sd	s6,0(sp)
    800044c8:	0080                	addi	s0,sp,64
    800044ca:	8b2a                	mv	s6,a0
    800044cc:	00025a97          	auipc	s5,0x25
    800044d0:	864a8a93          	addi	s5,s5,-1948 # 80028d30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d6:	00025997          	auipc	s3,0x25
    800044da:	82a98993          	addi	s3,s3,-2006 # 80028d00 <log>
    800044de:	a00d                	j	80004500 <install_trans+0x56>
    brelse(lbuf);
    800044e0:	854a                	mv	a0,s2
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	09e080e7          	jalr	158(ra) # 80003580 <brelse>
    brelse(dbuf);
    800044ea:	8526                	mv	a0,s1
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	094080e7          	jalr	148(ra) # 80003580 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f4:	2a05                	addiw	s4,s4,1
    800044f6:	0a91                	addi	s5,s5,4
    800044f8:	02c9a783          	lw	a5,44(s3)
    800044fc:	04fa5e63          	bge	s4,a5,80004558 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004500:	0189a583          	lw	a1,24(s3)
    80004504:	014585bb          	addw	a1,a1,s4
    80004508:	2585                	addiw	a1,a1,1
    8000450a:	0289a503          	lw	a0,40(s3)
    8000450e:	fffff097          	auipc	ra,0xfffff
    80004512:	f42080e7          	jalr	-190(ra) # 80003450 <bread>
    80004516:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004518:	000aa583          	lw	a1,0(s5)
    8000451c:	0289a503          	lw	a0,40(s3)
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	f30080e7          	jalr	-208(ra) # 80003450 <bread>
    80004528:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000452a:	40000613          	li	a2,1024
    8000452e:	05890593          	addi	a1,s2,88
    80004532:	05850513          	addi	a0,a0,88
    80004536:	ffffd097          	auipc	ra,0xffffd
    8000453a:	8e8080e7          	jalr	-1816(ra) # 80000e1e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	002080e7          	jalr	2(ra) # 80003542 <bwrite>
    if(recovering == 0)
    80004548:	f80b1ce3          	bnez	s6,800044e0 <install_trans+0x36>
      bunpin(dbuf);
    8000454c:	8526                	mv	a0,s1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	10a080e7          	jalr	266(ra) # 80003658 <bunpin>
    80004556:	b769                	j	800044e0 <install_trans+0x36>
}
    80004558:	70e2                	ld	ra,56(sp)
    8000455a:	7442                	ld	s0,48(sp)
    8000455c:	74a2                	ld	s1,40(sp)
    8000455e:	7902                	ld	s2,32(sp)
    80004560:	69e2                	ld	s3,24(sp)
    80004562:	6a42                	ld	s4,16(sp)
    80004564:	6aa2                	ld	s5,8(sp)
    80004566:	6b02                	ld	s6,0(sp)
    80004568:	6121                	addi	sp,sp,64
    8000456a:	8082                	ret
    8000456c:	8082                	ret

000000008000456e <initlog>:
{
    8000456e:	7179                	addi	sp,sp,-48
    80004570:	f406                	sd	ra,40(sp)
    80004572:	f022                	sd	s0,32(sp)
    80004574:	ec26                	sd	s1,24(sp)
    80004576:	e84a                	sd	s2,16(sp)
    80004578:	e44e                	sd	s3,8(sp)
    8000457a:	1800                	addi	s0,sp,48
    8000457c:	892a                	mv	s2,a0
    8000457e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004580:	00024497          	auipc	s1,0x24
    80004584:	78048493          	addi	s1,s1,1920 # 80028d00 <log>
    80004588:	00004597          	auipc	a1,0x4
    8000458c:	25858593          	addi	a1,a1,600 # 800087e0 <syscalls+0x220>
    80004590:	8526                	mv	a0,s1
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	6a4080e7          	jalr	1700(ra) # 80000c36 <initlock>
  log.start = sb->logstart;
    8000459a:	0149a583          	lw	a1,20(s3)
    8000459e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045a0:	0109a783          	lw	a5,16(s3)
    800045a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045aa:	854a                	mv	a0,s2
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	ea4080e7          	jalr	-348(ra) # 80003450 <bread>
  log.lh.n = lh->n;
    800045b4:	4d30                	lw	a2,88(a0)
    800045b6:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045b8:	00c05f63          	blez	a2,800045d6 <initlog+0x68>
    800045bc:	87aa                	mv	a5,a0
    800045be:	00024717          	auipc	a4,0x24
    800045c2:	77270713          	addi	a4,a4,1906 # 80028d30 <log+0x30>
    800045c6:	060a                	slli	a2,a2,0x2
    800045c8:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800045ca:	4ff4                	lw	a3,92(a5)
    800045cc:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045ce:	0791                	addi	a5,a5,4
    800045d0:	0711                	addi	a4,a4,4
    800045d2:	fec79ce3          	bne	a5,a2,800045ca <initlog+0x5c>
  brelse(buf);
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	faa080e7          	jalr	-86(ra) # 80003580 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045de:	4505                	li	a0,1
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	eca080e7          	jalr	-310(ra) # 800044aa <install_trans>
  log.lh.n = 0;
    800045e8:	00024797          	auipc	a5,0x24
    800045ec:	7407a223          	sw	zero,1860(a5) # 80028d2c <log+0x2c>
  write_head(); // clear the log
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	e50080e7          	jalr	-432(ra) # 80004440 <write_head>
}
    800045f8:	70a2                	ld	ra,40(sp)
    800045fa:	7402                	ld	s0,32(sp)
    800045fc:	64e2                	ld	s1,24(sp)
    800045fe:	6942                	ld	s2,16(sp)
    80004600:	69a2                	ld	s3,8(sp)
    80004602:	6145                	addi	sp,sp,48
    80004604:	8082                	ret

0000000080004606 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004612:	00024517          	auipc	a0,0x24
    80004616:	6ee50513          	addi	a0,a0,1774 # 80028d00 <log>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	6ac080e7          	jalr	1708(ra) # 80000cc6 <acquire>
  while(1){
    if(log.committing){
    80004622:	00024497          	auipc	s1,0x24
    80004626:	6de48493          	addi	s1,s1,1758 # 80028d00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000462a:	4979                	li	s2,30
    8000462c:	a039                	j	8000463a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000462e:	85a6                	mv	a1,s1
    80004630:	8526                	mv	a0,s1
    80004632:	ffffe097          	auipc	ra,0xffffe
    80004636:	cec080e7          	jalr	-788(ra) # 8000231e <sleep>
    if(log.committing){
    8000463a:	50dc                	lw	a5,36(s1)
    8000463c:	fbed                	bnez	a5,8000462e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000463e:	5098                	lw	a4,32(s1)
    80004640:	2705                	addiw	a4,a4,1
    80004642:	0027179b          	slliw	a5,a4,0x2
    80004646:	9fb9                	addw	a5,a5,a4
    80004648:	0017979b          	slliw	a5,a5,0x1
    8000464c:	54d4                	lw	a3,44(s1)
    8000464e:	9fb5                	addw	a5,a5,a3
    80004650:	00f95963          	bge	s2,a5,80004662 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004654:	85a6                	mv	a1,s1
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	cc6080e7          	jalr	-826(ra) # 8000231e <sleep>
    80004660:	bfe9                	j	8000463a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004662:	00024517          	auipc	a0,0x24
    80004666:	69e50513          	addi	a0,a0,1694 # 80028d00 <log>
    8000466a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	70e080e7          	jalr	1806(ra) # 80000d7a <release>
      break;
    }
  }
}
    80004674:	60e2                	ld	ra,24(sp)
    80004676:	6442                	ld	s0,16(sp)
    80004678:	64a2                	ld	s1,8(sp)
    8000467a:	6902                	ld	s2,0(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004680:	7139                	addi	sp,sp,-64
    80004682:	fc06                	sd	ra,56(sp)
    80004684:	f822                	sd	s0,48(sp)
    80004686:	f426                	sd	s1,40(sp)
    80004688:	f04a                	sd	s2,32(sp)
    8000468a:	ec4e                	sd	s3,24(sp)
    8000468c:	e852                	sd	s4,16(sp)
    8000468e:	e456                	sd	s5,8(sp)
    80004690:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004692:	00024497          	auipc	s1,0x24
    80004696:	66e48493          	addi	s1,s1,1646 # 80028d00 <log>
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	62a080e7          	jalr	1578(ra) # 80000cc6 <acquire>
  log.outstanding -= 1;
    800046a4:	509c                	lw	a5,32(s1)
    800046a6:	37fd                	addiw	a5,a5,-1
    800046a8:	0007891b          	sext.w	s2,a5
    800046ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046ae:	50dc                	lw	a5,36(s1)
    800046b0:	e7b9                	bnez	a5,800046fe <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046b2:	04091e63          	bnez	s2,8000470e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046b6:	00024497          	auipc	s1,0x24
    800046ba:	64a48493          	addi	s1,s1,1610 # 80028d00 <log>
    800046be:	4785                	li	a5,1
    800046c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046c2:	8526                	mv	a0,s1
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	6b6080e7          	jalr	1718(ra) # 80000d7a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046cc:	54dc                	lw	a5,44(s1)
    800046ce:	06f04763          	bgtz	a5,8000473c <end_op+0xbc>
    acquire(&log.lock);
    800046d2:	00024497          	auipc	s1,0x24
    800046d6:	62e48493          	addi	s1,s1,1582 # 80028d00 <log>
    800046da:	8526                	mv	a0,s1
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	5ea080e7          	jalr	1514(ra) # 80000cc6 <acquire>
    log.committing = 0;
    800046e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046e8:	8526                	mv	a0,s1
    800046ea:	ffffe097          	auipc	ra,0xffffe
    800046ee:	c98080e7          	jalr	-872(ra) # 80002382 <wakeup>
    release(&log.lock);
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	686080e7          	jalr	1670(ra) # 80000d7a <release>
}
    800046fc:	a03d                	j	8000472a <end_op+0xaa>
    panic("log.committing");
    800046fe:	00004517          	auipc	a0,0x4
    80004702:	0ea50513          	addi	a0,a0,234 # 800087e8 <syscalls+0x228>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	e36080e7          	jalr	-458(ra) # 8000053c <panic>
    wakeup(&log);
    8000470e:	00024497          	auipc	s1,0x24
    80004712:	5f248493          	addi	s1,s1,1522 # 80028d00 <log>
    80004716:	8526                	mv	a0,s1
    80004718:	ffffe097          	auipc	ra,0xffffe
    8000471c:	c6a080e7          	jalr	-918(ra) # 80002382 <wakeup>
  release(&log.lock);
    80004720:	8526                	mv	a0,s1
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	658080e7          	jalr	1624(ra) # 80000d7a <release>
}
    8000472a:	70e2                	ld	ra,56(sp)
    8000472c:	7442                	ld	s0,48(sp)
    8000472e:	74a2                	ld	s1,40(sp)
    80004730:	7902                	ld	s2,32(sp)
    80004732:	69e2                	ld	s3,24(sp)
    80004734:	6a42                	ld	s4,16(sp)
    80004736:	6aa2                	ld	s5,8(sp)
    80004738:	6121                	addi	sp,sp,64
    8000473a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000473c:	00024a97          	auipc	s5,0x24
    80004740:	5f4a8a93          	addi	s5,s5,1524 # 80028d30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004744:	00024a17          	auipc	s4,0x24
    80004748:	5bca0a13          	addi	s4,s4,1468 # 80028d00 <log>
    8000474c:	018a2583          	lw	a1,24(s4)
    80004750:	012585bb          	addw	a1,a1,s2
    80004754:	2585                	addiw	a1,a1,1
    80004756:	028a2503          	lw	a0,40(s4)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	cf6080e7          	jalr	-778(ra) # 80003450 <bread>
    80004762:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004764:	000aa583          	lw	a1,0(s5)
    80004768:	028a2503          	lw	a0,40(s4)
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	ce4080e7          	jalr	-796(ra) # 80003450 <bread>
    80004774:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004776:	40000613          	li	a2,1024
    8000477a:	05850593          	addi	a1,a0,88
    8000477e:	05848513          	addi	a0,s1,88
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	69c080e7          	jalr	1692(ra) # 80000e1e <memmove>
    bwrite(to);  // write the log
    8000478a:	8526                	mv	a0,s1
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	db6080e7          	jalr	-586(ra) # 80003542 <bwrite>
    brelse(from);
    80004794:	854e                	mv	a0,s3
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	dea080e7          	jalr	-534(ra) # 80003580 <brelse>
    brelse(to);
    8000479e:	8526                	mv	a0,s1
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	de0080e7          	jalr	-544(ra) # 80003580 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a8:	2905                	addiw	s2,s2,1
    800047aa:	0a91                	addi	s5,s5,4
    800047ac:	02ca2783          	lw	a5,44(s4)
    800047b0:	f8f94ee3          	blt	s2,a5,8000474c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	c8c080e7          	jalr	-884(ra) # 80004440 <write_head>
    install_trans(0); // Now install writes to home locations
    800047bc:	4501                	li	a0,0
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	cec080e7          	jalr	-788(ra) # 800044aa <install_trans>
    log.lh.n = 0;
    800047c6:	00024797          	auipc	a5,0x24
    800047ca:	5607a323          	sw	zero,1382(a5) # 80028d2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	c72080e7          	jalr	-910(ra) # 80004440 <write_head>
    800047d6:	bdf5                	j	800046d2 <end_op+0x52>

00000000800047d8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047d8:	1101                	addi	sp,sp,-32
    800047da:	ec06                	sd	ra,24(sp)
    800047dc:	e822                	sd	s0,16(sp)
    800047de:	e426                	sd	s1,8(sp)
    800047e0:	e04a                	sd	s2,0(sp)
    800047e2:	1000                	addi	s0,sp,32
    800047e4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047e6:	00024917          	auipc	s2,0x24
    800047ea:	51a90913          	addi	s2,s2,1306 # 80028d00 <log>
    800047ee:	854a                	mv	a0,s2
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	4d6080e7          	jalr	1238(ra) # 80000cc6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047f8:	02c92603          	lw	a2,44(s2)
    800047fc:	47f5                	li	a5,29
    800047fe:	06c7c563          	blt	a5,a2,80004868 <log_write+0x90>
    80004802:	00024797          	auipc	a5,0x24
    80004806:	51a7a783          	lw	a5,1306(a5) # 80028d1c <log+0x1c>
    8000480a:	37fd                	addiw	a5,a5,-1
    8000480c:	04f65e63          	bge	a2,a5,80004868 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004810:	00024797          	auipc	a5,0x24
    80004814:	5107a783          	lw	a5,1296(a5) # 80028d20 <log+0x20>
    80004818:	06f05063          	blez	a5,80004878 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000481c:	4781                	li	a5,0
    8000481e:	06c05563          	blez	a2,80004888 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004822:	44cc                	lw	a1,12(s1)
    80004824:	00024717          	auipc	a4,0x24
    80004828:	50c70713          	addi	a4,a4,1292 # 80028d30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000482c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000482e:	4314                	lw	a3,0(a4)
    80004830:	04b68c63          	beq	a3,a1,80004888 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004834:	2785                	addiw	a5,a5,1
    80004836:	0711                	addi	a4,a4,4
    80004838:	fef61be3          	bne	a2,a5,8000482e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000483c:	0621                	addi	a2,a2,8
    8000483e:	060a                	slli	a2,a2,0x2
    80004840:	00024797          	auipc	a5,0x24
    80004844:	4c078793          	addi	a5,a5,1216 # 80028d00 <log>
    80004848:	97b2                	add	a5,a5,a2
    8000484a:	44d8                	lw	a4,12(s1)
    8000484c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000484e:	8526                	mv	a0,s1
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	dcc080e7          	jalr	-564(ra) # 8000361c <bpin>
    log.lh.n++;
    80004858:	00024717          	auipc	a4,0x24
    8000485c:	4a870713          	addi	a4,a4,1192 # 80028d00 <log>
    80004860:	575c                	lw	a5,44(a4)
    80004862:	2785                	addiw	a5,a5,1
    80004864:	d75c                	sw	a5,44(a4)
    80004866:	a82d                	j	800048a0 <log_write+0xc8>
    panic("too big a transaction");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	f9050513          	addi	a0,a0,-112 # 800087f8 <syscalls+0x238>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	ccc080e7          	jalr	-820(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	f9850513          	addi	a0,a0,-104 # 80008810 <syscalls+0x250>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cbc080e7          	jalr	-836(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004888:	00878693          	addi	a3,a5,8
    8000488c:	068a                	slli	a3,a3,0x2
    8000488e:	00024717          	auipc	a4,0x24
    80004892:	47270713          	addi	a4,a4,1138 # 80028d00 <log>
    80004896:	9736                	add	a4,a4,a3
    80004898:	44d4                	lw	a3,12(s1)
    8000489a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000489c:	faf609e3          	beq	a2,a5,8000484e <log_write+0x76>
  }
  release(&log.lock);
    800048a0:	00024517          	auipc	a0,0x24
    800048a4:	46050513          	addi	a0,a0,1120 # 80028d00 <log>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	4d2080e7          	jalr	1234(ra) # 80000d7a <release>
}
    800048b0:	60e2                	ld	ra,24(sp)
    800048b2:	6442                	ld	s0,16(sp)
    800048b4:	64a2                	ld	s1,8(sp)
    800048b6:	6902                	ld	s2,0(sp)
    800048b8:	6105                	addi	sp,sp,32
    800048ba:	8082                	ret

00000000800048bc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048bc:	1101                	addi	sp,sp,-32
    800048be:	ec06                	sd	ra,24(sp)
    800048c0:	e822                	sd	s0,16(sp)
    800048c2:	e426                	sd	s1,8(sp)
    800048c4:	e04a                	sd	s2,0(sp)
    800048c6:	1000                	addi	s0,sp,32
    800048c8:	84aa                	mv	s1,a0
    800048ca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048cc:	00004597          	auipc	a1,0x4
    800048d0:	f6458593          	addi	a1,a1,-156 # 80008830 <syscalls+0x270>
    800048d4:	0521                	addi	a0,a0,8
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	360080e7          	jalr	864(ra) # 80000c36 <initlock>
  lk->name = name;
    800048de:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048e6:	0204a423          	sw	zero,40(s1)
}
    800048ea:	60e2                	ld	ra,24(sp)
    800048ec:	6442                	ld	s0,16(sp)
    800048ee:	64a2                	ld	s1,8(sp)
    800048f0:	6902                	ld	s2,0(sp)
    800048f2:	6105                	addi	sp,sp,32
    800048f4:	8082                	ret

00000000800048f6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	e04a                	sd	s2,0(sp)
    80004900:	1000                	addi	s0,sp,32
    80004902:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004904:	00850913          	addi	s2,a0,8
    80004908:	854a                	mv	a0,s2
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	3bc080e7          	jalr	956(ra) # 80000cc6 <acquire>
  while (lk->locked) {
    80004912:	409c                	lw	a5,0(s1)
    80004914:	cb89                	beqz	a5,80004926 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004916:	85ca                	mv	a1,s2
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffe097          	auipc	ra,0xffffe
    8000491e:	a04080e7          	jalr	-1532(ra) # 8000231e <sleep>
  while (lk->locked) {
    80004922:	409c                	lw	a5,0(s1)
    80004924:	fbed                	bnez	a5,80004916 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004926:	4785                	li	a5,1
    80004928:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000492a:	ffffd097          	auipc	ra,0xffffd
    8000492e:	28c080e7          	jalr	652(ra) # 80001bb6 <myproc>
    80004932:	591c                	lw	a5,48(a0)
    80004934:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004936:	854a                	mv	a0,s2
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	442080e7          	jalr	1090(ra) # 80000d7a <release>
}
    80004940:	60e2                	ld	ra,24(sp)
    80004942:	6442                	ld	s0,16(sp)
    80004944:	64a2                	ld	s1,8(sp)
    80004946:	6902                	ld	s2,0(sp)
    80004948:	6105                	addi	sp,sp,32
    8000494a:	8082                	ret

000000008000494c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000494c:	1101                	addi	sp,sp,-32
    8000494e:	ec06                	sd	ra,24(sp)
    80004950:	e822                	sd	s0,16(sp)
    80004952:	e426                	sd	s1,8(sp)
    80004954:	e04a                	sd	s2,0(sp)
    80004956:	1000                	addi	s0,sp,32
    80004958:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000495a:	00850913          	addi	s2,a0,8
    8000495e:	854a                	mv	a0,s2
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	366080e7          	jalr	870(ra) # 80000cc6 <acquire>
  lk->locked = 0;
    80004968:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000496c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004970:	8526                	mv	a0,s1
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	a10080e7          	jalr	-1520(ra) # 80002382 <wakeup>
  release(&lk->lk);
    8000497a:	854a                	mv	a0,s2
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	3fe080e7          	jalr	1022(ra) # 80000d7a <release>
}
    80004984:	60e2                	ld	ra,24(sp)
    80004986:	6442                	ld	s0,16(sp)
    80004988:	64a2                	ld	s1,8(sp)
    8000498a:	6902                	ld	s2,0(sp)
    8000498c:	6105                	addi	sp,sp,32
    8000498e:	8082                	ret

0000000080004990 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004990:	7179                	addi	sp,sp,-48
    80004992:	f406                	sd	ra,40(sp)
    80004994:	f022                	sd	s0,32(sp)
    80004996:	ec26                	sd	s1,24(sp)
    80004998:	e84a                	sd	s2,16(sp)
    8000499a:	e44e                	sd	s3,8(sp)
    8000499c:	1800                	addi	s0,sp,48
    8000499e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049a0:	00850913          	addi	s2,a0,8
    800049a4:	854a                	mv	a0,s2
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	320080e7          	jalr	800(ra) # 80000cc6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ae:	409c                	lw	a5,0(s1)
    800049b0:	ef99                	bnez	a5,800049ce <holdingsleep+0x3e>
    800049b2:	4481                	li	s1,0
  release(&lk->lk);
    800049b4:	854a                	mv	a0,s2
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	3c4080e7          	jalr	964(ra) # 80000d7a <release>
  return r;
}
    800049be:	8526                	mv	a0,s1
    800049c0:	70a2                	ld	ra,40(sp)
    800049c2:	7402                	ld	s0,32(sp)
    800049c4:	64e2                	ld	s1,24(sp)
    800049c6:	6942                	ld	s2,16(sp)
    800049c8:	69a2                	ld	s3,8(sp)
    800049ca:	6145                	addi	sp,sp,48
    800049cc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ce:	0284a983          	lw	s3,40(s1)
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	1e4080e7          	jalr	484(ra) # 80001bb6 <myproc>
    800049da:	5904                	lw	s1,48(a0)
    800049dc:	413484b3          	sub	s1,s1,s3
    800049e0:	0014b493          	seqz	s1,s1
    800049e4:	bfc1                	j	800049b4 <holdingsleep+0x24>

00000000800049e6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049e6:	1141                	addi	sp,sp,-16
    800049e8:	e406                	sd	ra,8(sp)
    800049ea:	e022                	sd	s0,0(sp)
    800049ec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049ee:	00004597          	auipc	a1,0x4
    800049f2:	e5258593          	addi	a1,a1,-430 # 80008840 <syscalls+0x280>
    800049f6:	00024517          	auipc	a0,0x24
    800049fa:	45250513          	addi	a0,a0,1106 # 80028e48 <ftable>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	238080e7          	jalr	568(ra) # 80000c36 <initlock>
}
    80004a06:	60a2                	ld	ra,8(sp)
    80004a08:	6402                	ld	s0,0(sp)
    80004a0a:	0141                	addi	sp,sp,16
    80004a0c:	8082                	ret

0000000080004a0e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a0e:	1101                	addi	sp,sp,-32
    80004a10:	ec06                	sd	ra,24(sp)
    80004a12:	e822                	sd	s0,16(sp)
    80004a14:	e426                	sd	s1,8(sp)
    80004a16:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a18:	00024517          	auipc	a0,0x24
    80004a1c:	43050513          	addi	a0,a0,1072 # 80028e48 <ftable>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	2a6080e7          	jalr	678(ra) # 80000cc6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a28:	00024497          	auipc	s1,0x24
    80004a2c:	43848493          	addi	s1,s1,1080 # 80028e60 <ftable+0x18>
    80004a30:	00025717          	auipc	a4,0x25
    80004a34:	3d070713          	addi	a4,a4,976 # 80029e00 <disk>
    if(f->ref == 0){
    80004a38:	40dc                	lw	a5,4(s1)
    80004a3a:	cf99                	beqz	a5,80004a58 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a3c:	02848493          	addi	s1,s1,40
    80004a40:	fee49ce3          	bne	s1,a4,80004a38 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a44:	00024517          	auipc	a0,0x24
    80004a48:	40450513          	addi	a0,a0,1028 # 80028e48 <ftable>
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	32e080e7          	jalr	814(ra) # 80000d7a <release>
  return 0;
    80004a54:	4481                	li	s1,0
    80004a56:	a819                	j	80004a6c <filealloc+0x5e>
      f->ref = 1;
    80004a58:	4785                	li	a5,1
    80004a5a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a5c:	00024517          	auipc	a0,0x24
    80004a60:	3ec50513          	addi	a0,a0,1004 # 80028e48 <ftable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	316080e7          	jalr	790(ra) # 80000d7a <release>
}
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	60e2                	ld	ra,24(sp)
    80004a70:	6442                	ld	s0,16(sp)
    80004a72:	64a2                	ld	s1,8(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret

0000000080004a78 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a78:	1101                	addi	sp,sp,-32
    80004a7a:	ec06                	sd	ra,24(sp)
    80004a7c:	e822                	sd	s0,16(sp)
    80004a7e:	e426                	sd	s1,8(sp)
    80004a80:	1000                	addi	s0,sp,32
    80004a82:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a84:	00024517          	auipc	a0,0x24
    80004a88:	3c450513          	addi	a0,a0,964 # 80028e48 <ftable>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	23a080e7          	jalr	570(ra) # 80000cc6 <acquire>
  if(f->ref < 1)
    80004a94:	40dc                	lw	a5,4(s1)
    80004a96:	02f05263          	blez	a5,80004aba <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a9a:	2785                	addiw	a5,a5,1
    80004a9c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a9e:	00024517          	auipc	a0,0x24
    80004aa2:	3aa50513          	addi	a0,a0,938 # 80028e48 <ftable>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	2d4080e7          	jalr	724(ra) # 80000d7a <release>
  return f;
}
    80004aae:	8526                	mv	a0,s1
    80004ab0:	60e2                	ld	ra,24(sp)
    80004ab2:	6442                	ld	s0,16(sp)
    80004ab4:	64a2                	ld	s1,8(sp)
    80004ab6:	6105                	addi	sp,sp,32
    80004ab8:	8082                	ret
    panic("filedup");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	d8e50513          	addi	a0,a0,-626 # 80008848 <syscalls+0x288>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a7a080e7          	jalr	-1414(ra) # 8000053c <panic>

0000000080004aca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004aca:	7139                	addi	sp,sp,-64
    80004acc:	fc06                	sd	ra,56(sp)
    80004ace:	f822                	sd	s0,48(sp)
    80004ad0:	f426                	sd	s1,40(sp)
    80004ad2:	f04a                	sd	s2,32(sp)
    80004ad4:	ec4e                	sd	s3,24(sp)
    80004ad6:	e852                	sd	s4,16(sp)
    80004ad8:	e456                	sd	s5,8(sp)
    80004ada:	0080                	addi	s0,sp,64
    80004adc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ade:	00024517          	auipc	a0,0x24
    80004ae2:	36a50513          	addi	a0,a0,874 # 80028e48 <ftable>
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	1e0080e7          	jalr	480(ra) # 80000cc6 <acquire>
  if(f->ref < 1)
    80004aee:	40dc                	lw	a5,4(s1)
    80004af0:	06f05163          	blez	a5,80004b52 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004af4:	37fd                	addiw	a5,a5,-1
    80004af6:	0007871b          	sext.w	a4,a5
    80004afa:	c0dc                	sw	a5,4(s1)
    80004afc:	06e04363          	bgtz	a4,80004b62 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b00:	0004a903          	lw	s2,0(s1)
    80004b04:	0094ca83          	lbu	s5,9(s1)
    80004b08:	0104ba03          	ld	s4,16(s1)
    80004b0c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b10:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b14:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b18:	00024517          	auipc	a0,0x24
    80004b1c:	33050513          	addi	a0,a0,816 # 80028e48 <ftable>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	25a080e7          	jalr	602(ra) # 80000d7a <release>

  if(ff.type == FD_PIPE){
    80004b28:	4785                	li	a5,1
    80004b2a:	04f90d63          	beq	s2,a5,80004b84 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b2e:	3979                	addiw	s2,s2,-2
    80004b30:	4785                	li	a5,1
    80004b32:	0527e063          	bltu	a5,s2,80004b72 <fileclose+0xa8>
    begin_op();
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	ad0080e7          	jalr	-1328(ra) # 80004606 <begin_op>
    iput(ff.ip);
    80004b3e:	854e                	mv	a0,s3
    80004b40:	fffff097          	auipc	ra,0xfffff
    80004b44:	2da080e7          	jalr	730(ra) # 80003e1a <iput>
    end_op();
    80004b48:	00000097          	auipc	ra,0x0
    80004b4c:	b38080e7          	jalr	-1224(ra) # 80004680 <end_op>
    80004b50:	a00d                	j	80004b72 <fileclose+0xa8>
    panic("fileclose");
    80004b52:	00004517          	auipc	a0,0x4
    80004b56:	cfe50513          	addi	a0,a0,-770 # 80008850 <syscalls+0x290>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9e2080e7          	jalr	-1566(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004b62:	00024517          	auipc	a0,0x24
    80004b66:	2e650513          	addi	a0,a0,742 # 80028e48 <ftable>
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	210080e7          	jalr	528(ra) # 80000d7a <release>
  }
}
    80004b72:	70e2                	ld	ra,56(sp)
    80004b74:	7442                	ld	s0,48(sp)
    80004b76:	74a2                	ld	s1,40(sp)
    80004b78:	7902                	ld	s2,32(sp)
    80004b7a:	69e2                	ld	s3,24(sp)
    80004b7c:	6a42                	ld	s4,16(sp)
    80004b7e:	6aa2                	ld	s5,8(sp)
    80004b80:	6121                	addi	sp,sp,64
    80004b82:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b84:	85d6                	mv	a1,s5
    80004b86:	8552                	mv	a0,s4
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	348080e7          	jalr	840(ra) # 80004ed0 <pipeclose>
    80004b90:	b7cd                	j	80004b72 <fileclose+0xa8>

0000000080004b92 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b92:	715d                	addi	sp,sp,-80
    80004b94:	e486                	sd	ra,72(sp)
    80004b96:	e0a2                	sd	s0,64(sp)
    80004b98:	fc26                	sd	s1,56(sp)
    80004b9a:	f84a                	sd	s2,48(sp)
    80004b9c:	f44e                	sd	s3,40(sp)
    80004b9e:	0880                	addi	s0,sp,80
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	012080e7          	jalr	18(ra) # 80001bb6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bac:	409c                	lw	a5,0(s1)
    80004bae:	37f9                	addiw	a5,a5,-2
    80004bb0:	4705                	li	a4,1
    80004bb2:	04f76763          	bltu	a4,a5,80004c00 <filestat+0x6e>
    80004bb6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bb8:	6c88                	ld	a0,24(s1)
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	0a6080e7          	jalr	166(ra) # 80003c60 <ilock>
    stati(f->ip, &st);
    80004bc2:	fb840593          	addi	a1,s0,-72
    80004bc6:	6c88                	ld	a0,24(s1)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	322080e7          	jalr	802(ra) # 80003eea <stati>
    iunlock(f->ip);
    80004bd0:	6c88                	ld	a0,24(s1)
    80004bd2:	fffff097          	auipc	ra,0xfffff
    80004bd6:	150080e7          	jalr	336(ra) # 80003d22 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bda:	46e1                	li	a3,24
    80004bdc:	fb840613          	addi	a2,s0,-72
    80004be0:	85ce                	mv	a1,s3
    80004be2:	05093503          	ld	a0,80(s2)
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	b9c080e7          	jalr	-1124(ra) # 80001782 <copyout>
    80004bee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bf2:	60a6                	ld	ra,72(sp)
    80004bf4:	6406                	ld	s0,64(sp)
    80004bf6:	74e2                	ld	s1,56(sp)
    80004bf8:	7942                	ld	s2,48(sp)
    80004bfa:	79a2                	ld	s3,40(sp)
    80004bfc:	6161                	addi	sp,sp,80
    80004bfe:	8082                	ret
  return -1;
    80004c00:	557d                	li	a0,-1
    80004c02:	bfc5                	j	80004bf2 <filestat+0x60>

0000000080004c04 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c04:	7179                	addi	sp,sp,-48
    80004c06:	f406                	sd	ra,40(sp)
    80004c08:	f022                	sd	s0,32(sp)
    80004c0a:	ec26                	sd	s1,24(sp)
    80004c0c:	e84a                	sd	s2,16(sp)
    80004c0e:	e44e                	sd	s3,8(sp)
    80004c10:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c12:	00854783          	lbu	a5,8(a0)
    80004c16:	c3d5                	beqz	a5,80004cba <fileread+0xb6>
    80004c18:	84aa                	mv	s1,a0
    80004c1a:	89ae                	mv	s3,a1
    80004c1c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c1e:	411c                	lw	a5,0(a0)
    80004c20:	4705                	li	a4,1
    80004c22:	04e78963          	beq	a5,a4,80004c74 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c26:	470d                	li	a4,3
    80004c28:	04e78d63          	beq	a5,a4,80004c82 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c2c:	4709                	li	a4,2
    80004c2e:	06e79e63          	bne	a5,a4,80004caa <fileread+0xa6>
    ilock(f->ip);
    80004c32:	6d08                	ld	a0,24(a0)
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	02c080e7          	jalr	44(ra) # 80003c60 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c3c:	874a                	mv	a4,s2
    80004c3e:	5094                	lw	a3,32(s1)
    80004c40:	864e                	mv	a2,s3
    80004c42:	4585                	li	a1,1
    80004c44:	6c88                	ld	a0,24(s1)
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	2ce080e7          	jalr	718(ra) # 80003f14 <readi>
    80004c4e:	892a                	mv	s2,a0
    80004c50:	00a05563          	blez	a0,80004c5a <fileread+0x56>
      f->off += r;
    80004c54:	509c                	lw	a5,32(s1)
    80004c56:	9fa9                	addw	a5,a5,a0
    80004c58:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c5a:	6c88                	ld	a0,24(s1)
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	0c6080e7          	jalr	198(ra) # 80003d22 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c64:	854a                	mv	a0,s2
    80004c66:	70a2                	ld	ra,40(sp)
    80004c68:	7402                	ld	s0,32(sp)
    80004c6a:	64e2                	ld	s1,24(sp)
    80004c6c:	6942                	ld	s2,16(sp)
    80004c6e:	69a2                	ld	s3,8(sp)
    80004c70:	6145                	addi	sp,sp,48
    80004c72:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c74:	6908                	ld	a0,16(a0)
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	3c2080e7          	jalr	962(ra) # 80005038 <piperead>
    80004c7e:	892a                	mv	s2,a0
    80004c80:	b7d5                	j	80004c64 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c82:	02451783          	lh	a5,36(a0)
    80004c86:	03079693          	slli	a3,a5,0x30
    80004c8a:	92c1                	srli	a3,a3,0x30
    80004c8c:	4725                	li	a4,9
    80004c8e:	02d76863          	bltu	a4,a3,80004cbe <fileread+0xba>
    80004c92:	0792                	slli	a5,a5,0x4
    80004c94:	00024717          	auipc	a4,0x24
    80004c98:	11470713          	addi	a4,a4,276 # 80028da8 <devsw>
    80004c9c:	97ba                	add	a5,a5,a4
    80004c9e:	639c                	ld	a5,0(a5)
    80004ca0:	c38d                	beqz	a5,80004cc2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ca2:	4505                	li	a0,1
    80004ca4:	9782                	jalr	a5
    80004ca6:	892a                	mv	s2,a0
    80004ca8:	bf75                	j	80004c64 <fileread+0x60>
    panic("fileread");
    80004caa:	00004517          	auipc	a0,0x4
    80004cae:	bb650513          	addi	a0,a0,-1098 # 80008860 <syscalls+0x2a0>
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	88a080e7          	jalr	-1910(ra) # 8000053c <panic>
    return -1;
    80004cba:	597d                	li	s2,-1
    80004cbc:	b765                	j	80004c64 <fileread+0x60>
      return -1;
    80004cbe:	597d                	li	s2,-1
    80004cc0:	b755                	j	80004c64 <fileread+0x60>
    80004cc2:	597d                	li	s2,-1
    80004cc4:	b745                	j	80004c64 <fileread+0x60>

0000000080004cc6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004cc6:	00954783          	lbu	a5,9(a0)
    80004cca:	10078e63          	beqz	a5,80004de6 <filewrite+0x120>
{
    80004cce:	715d                	addi	sp,sp,-80
    80004cd0:	e486                	sd	ra,72(sp)
    80004cd2:	e0a2                	sd	s0,64(sp)
    80004cd4:	fc26                	sd	s1,56(sp)
    80004cd6:	f84a                	sd	s2,48(sp)
    80004cd8:	f44e                	sd	s3,40(sp)
    80004cda:	f052                	sd	s4,32(sp)
    80004cdc:	ec56                	sd	s5,24(sp)
    80004cde:	e85a                	sd	s6,16(sp)
    80004ce0:	e45e                	sd	s7,8(sp)
    80004ce2:	e062                	sd	s8,0(sp)
    80004ce4:	0880                	addi	s0,sp,80
    80004ce6:	892a                	mv	s2,a0
    80004ce8:	8b2e                	mv	s6,a1
    80004cea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cec:	411c                	lw	a5,0(a0)
    80004cee:	4705                	li	a4,1
    80004cf0:	02e78263          	beq	a5,a4,80004d14 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf4:	470d                	li	a4,3
    80004cf6:	02e78563          	beq	a5,a4,80004d20 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cfa:	4709                	li	a4,2
    80004cfc:	0ce79d63          	bne	a5,a4,80004dd6 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d00:	0ac05b63          	blez	a2,80004db6 <filewrite+0xf0>
    int i = 0;
    80004d04:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004d06:	6b85                	lui	s7,0x1
    80004d08:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d0c:	6c05                	lui	s8,0x1
    80004d0e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d12:	a851                	j	80004da6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004d14:	6908                	ld	a0,16(a0)
    80004d16:	00000097          	auipc	ra,0x0
    80004d1a:	22a080e7          	jalr	554(ra) # 80004f40 <pipewrite>
    80004d1e:	a045                	j	80004dbe <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d20:	02451783          	lh	a5,36(a0)
    80004d24:	03079693          	slli	a3,a5,0x30
    80004d28:	92c1                	srli	a3,a3,0x30
    80004d2a:	4725                	li	a4,9
    80004d2c:	0ad76f63          	bltu	a4,a3,80004dea <filewrite+0x124>
    80004d30:	0792                	slli	a5,a5,0x4
    80004d32:	00024717          	auipc	a4,0x24
    80004d36:	07670713          	addi	a4,a4,118 # 80028da8 <devsw>
    80004d3a:	97ba                	add	a5,a5,a4
    80004d3c:	679c                	ld	a5,8(a5)
    80004d3e:	cbc5                	beqz	a5,80004dee <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004d40:	4505                	li	a0,1
    80004d42:	9782                	jalr	a5
    80004d44:	a8ad                	j	80004dbe <filewrite+0xf8>
      if(n1 > max)
    80004d46:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	8bc080e7          	jalr	-1860(ra) # 80004606 <begin_op>
      ilock(f->ip);
    80004d52:	01893503          	ld	a0,24(s2)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	f0a080e7          	jalr	-246(ra) # 80003c60 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d5e:	8756                	mv	a4,s5
    80004d60:	02092683          	lw	a3,32(s2)
    80004d64:	01698633          	add	a2,s3,s6
    80004d68:	4585                	li	a1,1
    80004d6a:	01893503          	ld	a0,24(s2)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	29e080e7          	jalr	670(ra) # 8000400c <writei>
    80004d76:	84aa                	mv	s1,a0
    80004d78:	00a05763          	blez	a0,80004d86 <filewrite+0xc0>
        f->off += r;
    80004d7c:	02092783          	lw	a5,32(s2)
    80004d80:	9fa9                	addw	a5,a5,a0
    80004d82:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d86:	01893503          	ld	a0,24(s2)
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	f98080e7          	jalr	-104(ra) # 80003d22 <iunlock>
      end_op();
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	8ee080e7          	jalr	-1810(ra) # 80004680 <end_op>

      if(r != n1){
    80004d9a:	009a9f63          	bne	s5,s1,80004db8 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d9e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004da2:	0149db63          	bge	s3,s4,80004db8 <filewrite+0xf2>
      int n1 = n - i;
    80004da6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004daa:	0004879b          	sext.w	a5,s1
    80004dae:	f8fbdce3          	bge	s7,a5,80004d46 <filewrite+0x80>
    80004db2:	84e2                	mv	s1,s8
    80004db4:	bf49                	j	80004d46 <filewrite+0x80>
    int i = 0;
    80004db6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004db8:	033a1d63          	bne	s4,s3,80004df2 <filewrite+0x12c>
    80004dbc:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dbe:	60a6                	ld	ra,72(sp)
    80004dc0:	6406                	ld	s0,64(sp)
    80004dc2:	74e2                	ld	s1,56(sp)
    80004dc4:	7942                	ld	s2,48(sp)
    80004dc6:	79a2                	ld	s3,40(sp)
    80004dc8:	7a02                	ld	s4,32(sp)
    80004dca:	6ae2                	ld	s5,24(sp)
    80004dcc:	6b42                	ld	s6,16(sp)
    80004dce:	6ba2                	ld	s7,8(sp)
    80004dd0:	6c02                	ld	s8,0(sp)
    80004dd2:	6161                	addi	sp,sp,80
    80004dd4:	8082                	ret
    panic("filewrite");
    80004dd6:	00004517          	auipc	a0,0x4
    80004dda:	a9a50513          	addi	a0,a0,-1382 # 80008870 <syscalls+0x2b0>
    80004dde:	ffffb097          	auipc	ra,0xffffb
    80004de2:	75e080e7          	jalr	1886(ra) # 8000053c <panic>
    return -1;
    80004de6:	557d                	li	a0,-1
}
    80004de8:	8082                	ret
      return -1;
    80004dea:	557d                	li	a0,-1
    80004dec:	bfc9                	j	80004dbe <filewrite+0xf8>
    80004dee:	557d                	li	a0,-1
    80004df0:	b7f9                	j	80004dbe <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004df2:	557d                	li	a0,-1
    80004df4:	b7e9                	j	80004dbe <filewrite+0xf8>

0000000080004df6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004df6:	7179                	addi	sp,sp,-48
    80004df8:	f406                	sd	ra,40(sp)
    80004dfa:	f022                	sd	s0,32(sp)
    80004dfc:	ec26                	sd	s1,24(sp)
    80004dfe:	e84a                	sd	s2,16(sp)
    80004e00:	e44e                	sd	s3,8(sp)
    80004e02:	e052                	sd	s4,0(sp)
    80004e04:	1800                	addi	s0,sp,48
    80004e06:	84aa                	mv	s1,a0
    80004e08:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e0a:	0005b023          	sd	zero,0(a1)
    80004e0e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e12:	00000097          	auipc	ra,0x0
    80004e16:	bfc080e7          	jalr	-1028(ra) # 80004a0e <filealloc>
    80004e1a:	e088                	sd	a0,0(s1)
    80004e1c:	c551                	beqz	a0,80004ea8 <pipealloc+0xb2>
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	bf0080e7          	jalr	-1040(ra) # 80004a0e <filealloc>
    80004e26:	00aa3023          	sd	a0,0(s4)
    80004e2a:	c92d                	beqz	a0,80004e9c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	d5e080e7          	jalr	-674(ra) # 80000b8a <kalloc>
    80004e34:	892a                	mv	s2,a0
    80004e36:	c125                	beqz	a0,80004e96 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e38:	4985                	li	s3,1
    80004e3a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e3e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e42:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e46:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e4a:	00004597          	auipc	a1,0x4
    80004e4e:	a3658593          	addi	a1,a1,-1482 # 80008880 <syscalls+0x2c0>
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	de4080e7          	jalr	-540(ra) # 80000c36 <initlock>
  (*f0)->type = FD_PIPE;
    80004e5a:	609c                	ld	a5,0(s1)
    80004e5c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e60:	609c                	ld	a5,0(s1)
    80004e62:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e66:	609c                	ld	a5,0(s1)
    80004e68:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e6c:	609c                	ld	a5,0(s1)
    80004e6e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e72:	000a3783          	ld	a5,0(s4)
    80004e76:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e7a:	000a3783          	ld	a5,0(s4)
    80004e7e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e82:	000a3783          	ld	a5,0(s4)
    80004e86:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e8a:	000a3783          	ld	a5,0(s4)
    80004e8e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e92:	4501                	li	a0,0
    80004e94:	a025                	j	80004ebc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e96:	6088                	ld	a0,0(s1)
    80004e98:	e501                	bnez	a0,80004ea0 <pipealloc+0xaa>
    80004e9a:	a039                	j	80004ea8 <pipealloc+0xb2>
    80004e9c:	6088                	ld	a0,0(s1)
    80004e9e:	c51d                	beqz	a0,80004ecc <pipealloc+0xd6>
    fileclose(*f0);
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	c2a080e7          	jalr	-982(ra) # 80004aca <fileclose>
  if(*f1)
    80004ea8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eac:	557d                	li	a0,-1
  if(*f1)
    80004eae:	c799                	beqz	a5,80004ebc <pipealloc+0xc6>
    fileclose(*f1);
    80004eb0:	853e                	mv	a0,a5
    80004eb2:	00000097          	auipc	ra,0x0
    80004eb6:	c18080e7          	jalr	-1000(ra) # 80004aca <fileclose>
  return -1;
    80004eba:	557d                	li	a0,-1
}
    80004ebc:	70a2                	ld	ra,40(sp)
    80004ebe:	7402                	ld	s0,32(sp)
    80004ec0:	64e2                	ld	s1,24(sp)
    80004ec2:	6942                	ld	s2,16(sp)
    80004ec4:	69a2                	ld	s3,8(sp)
    80004ec6:	6a02                	ld	s4,0(sp)
    80004ec8:	6145                	addi	sp,sp,48
    80004eca:	8082                	ret
  return -1;
    80004ecc:	557d                	li	a0,-1
    80004ece:	b7fd                	j	80004ebc <pipealloc+0xc6>

0000000080004ed0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ed0:	1101                	addi	sp,sp,-32
    80004ed2:	ec06                	sd	ra,24(sp)
    80004ed4:	e822                	sd	s0,16(sp)
    80004ed6:	e426                	sd	s1,8(sp)
    80004ed8:	e04a                	sd	s2,0(sp)
    80004eda:	1000                	addi	s0,sp,32
    80004edc:	84aa                	mv	s1,a0
    80004ede:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	de6080e7          	jalr	-538(ra) # 80000cc6 <acquire>
  if(writable){
    80004ee8:	02090d63          	beqz	s2,80004f22 <pipeclose+0x52>
    pi->writeopen = 0;
    80004eec:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ef0:	21848513          	addi	a0,s1,536
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	48e080e7          	jalr	1166(ra) # 80002382 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004efc:	2204b783          	ld	a5,544(s1)
    80004f00:	eb95                	bnez	a5,80004f34 <pipeclose+0x64>
    release(&pi->lock);
    80004f02:	8526                	mv	a0,s1
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	e76080e7          	jalr	-394(ra) # 80000d7a <release>
    kfree((char*)pi);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	ae8080e7          	jalr	-1304(ra) # 800009f6 <kfree>
  } else
    release(&pi->lock);
}
    80004f16:	60e2                	ld	ra,24(sp)
    80004f18:	6442                	ld	s0,16(sp)
    80004f1a:	64a2                	ld	s1,8(sp)
    80004f1c:	6902                	ld	s2,0(sp)
    80004f1e:	6105                	addi	sp,sp,32
    80004f20:	8082                	ret
    pi->readopen = 0;
    80004f22:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f26:	21c48513          	addi	a0,s1,540
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	458080e7          	jalr	1112(ra) # 80002382 <wakeup>
    80004f32:	b7e9                	j	80004efc <pipeclose+0x2c>
    release(&pi->lock);
    80004f34:	8526                	mv	a0,s1
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	e44080e7          	jalr	-444(ra) # 80000d7a <release>
}
    80004f3e:	bfe1                	j	80004f16 <pipeclose+0x46>

0000000080004f40 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f40:	711d                	addi	sp,sp,-96
    80004f42:	ec86                	sd	ra,88(sp)
    80004f44:	e8a2                	sd	s0,80(sp)
    80004f46:	e4a6                	sd	s1,72(sp)
    80004f48:	e0ca                	sd	s2,64(sp)
    80004f4a:	fc4e                	sd	s3,56(sp)
    80004f4c:	f852                	sd	s4,48(sp)
    80004f4e:	f456                	sd	s5,40(sp)
    80004f50:	f05a                	sd	s6,32(sp)
    80004f52:	ec5e                	sd	s7,24(sp)
    80004f54:	e862                	sd	s8,16(sp)
    80004f56:	1080                	addi	s0,sp,96
    80004f58:	84aa                	mv	s1,a0
    80004f5a:	8aae                	mv	s5,a1
    80004f5c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	c58080e7          	jalr	-936(ra) # 80001bb6 <myproc>
    80004f66:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	d5c080e7          	jalr	-676(ra) # 80000cc6 <acquire>
  while(i < n){
    80004f72:	0b405663          	blez	s4,8000501e <pipewrite+0xde>
  int i = 0;
    80004f76:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f78:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f7a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f7e:	21c48b93          	addi	s7,s1,540
    80004f82:	a089                	j	80004fc4 <pipewrite+0x84>
      release(&pi->lock);
    80004f84:	8526                	mv	a0,s1
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	df4080e7          	jalr	-524(ra) # 80000d7a <release>
      return -1;
    80004f8e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f90:	854a                	mv	a0,s2
    80004f92:	60e6                	ld	ra,88(sp)
    80004f94:	6446                	ld	s0,80(sp)
    80004f96:	64a6                	ld	s1,72(sp)
    80004f98:	6906                	ld	s2,64(sp)
    80004f9a:	79e2                	ld	s3,56(sp)
    80004f9c:	7a42                	ld	s4,48(sp)
    80004f9e:	7aa2                	ld	s5,40(sp)
    80004fa0:	7b02                	ld	s6,32(sp)
    80004fa2:	6be2                	ld	s7,24(sp)
    80004fa4:	6c42                	ld	s8,16(sp)
    80004fa6:	6125                	addi	sp,sp,96
    80004fa8:	8082                	ret
      wakeup(&pi->nread);
    80004faa:	8562                	mv	a0,s8
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	3d6080e7          	jalr	982(ra) # 80002382 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fb4:	85a6                	mv	a1,s1
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	366080e7          	jalr	870(ra) # 8000231e <sleep>
  while(i < n){
    80004fc0:	07495063          	bge	s2,s4,80005020 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fc4:	2204a783          	lw	a5,544(s1)
    80004fc8:	dfd5                	beqz	a5,80004f84 <pipewrite+0x44>
    80004fca:	854e                	mv	a0,s3
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	5fa080e7          	jalr	1530(ra) # 800025c6 <killed>
    80004fd4:	f945                	bnez	a0,80004f84 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fd6:	2184a783          	lw	a5,536(s1)
    80004fda:	21c4a703          	lw	a4,540(s1)
    80004fde:	2007879b          	addiw	a5,a5,512
    80004fe2:	fcf704e3          	beq	a4,a5,80004faa <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fe6:	4685                	li	a3,1
    80004fe8:	01590633          	add	a2,s2,s5
    80004fec:	faf40593          	addi	a1,s0,-81
    80004ff0:	0509b503          	ld	a0,80(s3)
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	81a080e7          	jalr	-2022(ra) # 8000180e <copyin>
    80004ffc:	03650263          	beq	a0,s6,80005020 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005000:	21c4a783          	lw	a5,540(s1)
    80005004:	0017871b          	addiw	a4,a5,1
    80005008:	20e4ae23          	sw	a4,540(s1)
    8000500c:	1ff7f793          	andi	a5,a5,511
    80005010:	97a6                	add	a5,a5,s1
    80005012:	faf44703          	lbu	a4,-81(s0)
    80005016:	00e78c23          	sb	a4,24(a5)
      i++;
    8000501a:	2905                	addiw	s2,s2,1
    8000501c:	b755                	j	80004fc0 <pipewrite+0x80>
  int i = 0;
    8000501e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005020:	21848513          	addi	a0,s1,536
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	35e080e7          	jalr	862(ra) # 80002382 <wakeup>
  release(&pi->lock);
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	d4c080e7          	jalr	-692(ra) # 80000d7a <release>
  return i;
    80005036:	bfa9                	j	80004f90 <pipewrite+0x50>

0000000080005038 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005038:	715d                	addi	sp,sp,-80
    8000503a:	e486                	sd	ra,72(sp)
    8000503c:	e0a2                	sd	s0,64(sp)
    8000503e:	fc26                	sd	s1,56(sp)
    80005040:	f84a                	sd	s2,48(sp)
    80005042:	f44e                	sd	s3,40(sp)
    80005044:	f052                	sd	s4,32(sp)
    80005046:	ec56                	sd	s5,24(sp)
    80005048:	e85a                	sd	s6,16(sp)
    8000504a:	0880                	addi	s0,sp,80
    8000504c:	84aa                	mv	s1,a0
    8000504e:	892e                	mv	s2,a1
    80005050:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	b64080e7          	jalr	-1180(ra) # 80001bb6 <myproc>
    8000505a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c68080e7          	jalr	-920(ra) # 80000cc6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005066:	2184a703          	lw	a4,536(s1)
    8000506a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000506e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005072:	02f71763          	bne	a4,a5,800050a0 <piperead+0x68>
    80005076:	2244a783          	lw	a5,548(s1)
    8000507a:	c39d                	beqz	a5,800050a0 <piperead+0x68>
    if(killed(pr)){
    8000507c:	8552                	mv	a0,s4
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	548080e7          	jalr	1352(ra) # 800025c6 <killed>
    80005086:	e949                	bnez	a0,80005118 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005088:	85a6                	mv	a1,s1
    8000508a:	854e                	mv	a0,s3
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	292080e7          	jalr	658(ra) # 8000231e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005094:	2184a703          	lw	a4,536(s1)
    80005098:	21c4a783          	lw	a5,540(s1)
    8000509c:	fcf70de3          	beq	a4,a5,80005076 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050a2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a4:	05505463          	blez	s5,800050ec <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800050a8:	2184a783          	lw	a5,536(s1)
    800050ac:	21c4a703          	lw	a4,540(s1)
    800050b0:	02f70e63          	beq	a4,a5,800050ec <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050b4:	0017871b          	addiw	a4,a5,1
    800050b8:	20e4ac23          	sw	a4,536(s1)
    800050bc:	1ff7f793          	andi	a5,a5,511
    800050c0:	97a6                	add	a5,a5,s1
    800050c2:	0187c783          	lbu	a5,24(a5)
    800050c6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ca:	4685                	li	a3,1
    800050cc:	fbf40613          	addi	a2,s0,-65
    800050d0:	85ca                	mv	a1,s2
    800050d2:	050a3503          	ld	a0,80(s4)
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	6ac080e7          	jalr	1708(ra) # 80001782 <copyout>
    800050de:	01650763          	beq	a0,s6,800050ec <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050e2:	2985                	addiw	s3,s3,1
    800050e4:	0905                	addi	s2,s2,1
    800050e6:	fd3a91e3          	bne	s5,s3,800050a8 <piperead+0x70>
    800050ea:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050ec:	21c48513          	addi	a0,s1,540
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	292080e7          	jalr	658(ra) # 80002382 <wakeup>
  release(&pi->lock);
    800050f8:	8526                	mv	a0,s1
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	c80080e7          	jalr	-896(ra) # 80000d7a <release>
  return i;
}
    80005102:	854e                	mv	a0,s3
    80005104:	60a6                	ld	ra,72(sp)
    80005106:	6406                	ld	s0,64(sp)
    80005108:	74e2                	ld	s1,56(sp)
    8000510a:	7942                	ld	s2,48(sp)
    8000510c:	79a2                	ld	s3,40(sp)
    8000510e:	7a02                	ld	s4,32(sp)
    80005110:	6ae2                	ld	s5,24(sp)
    80005112:	6b42                	ld	s6,16(sp)
    80005114:	6161                	addi	sp,sp,80
    80005116:	8082                	ret
      release(&pi->lock);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	c60080e7          	jalr	-928(ra) # 80000d7a <release>
      return -1;
    80005122:	59fd                	li	s3,-1
    80005124:	bff9                	j	80005102 <piperead+0xca>

0000000080005126 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005126:	1141                	addi	sp,sp,-16
    80005128:	e422                	sd	s0,8(sp)
    8000512a:	0800                	addi	s0,sp,16
    8000512c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000512e:	8905                	andi	a0,a0,1
    80005130:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005132:	8b89                	andi	a5,a5,2
    80005134:	c399                	beqz	a5,8000513a <flags2perm+0x14>
      perm |= PTE_W;
    80005136:	00456513          	ori	a0,a0,4
    return perm;
}
    8000513a:	6422                	ld	s0,8(sp)
    8000513c:	0141                	addi	sp,sp,16
    8000513e:	8082                	ret

0000000080005140 <exec>:

int
exec(char *path, char **argv)
{
    80005140:	df010113          	addi	sp,sp,-528
    80005144:	20113423          	sd	ra,520(sp)
    80005148:	20813023          	sd	s0,512(sp)
    8000514c:	ffa6                	sd	s1,504(sp)
    8000514e:	fbca                	sd	s2,496(sp)
    80005150:	f7ce                	sd	s3,488(sp)
    80005152:	f3d2                	sd	s4,480(sp)
    80005154:	efd6                	sd	s5,472(sp)
    80005156:	ebda                	sd	s6,464(sp)
    80005158:	e7de                	sd	s7,456(sp)
    8000515a:	e3e2                	sd	s8,448(sp)
    8000515c:	ff66                	sd	s9,440(sp)
    8000515e:	fb6a                	sd	s10,432(sp)
    80005160:	f76e                	sd	s11,424(sp)
    80005162:	0c00                	addi	s0,sp,528
    80005164:	892a                	mv	s2,a0
    80005166:	dea43c23          	sd	a0,-520(s0)
    8000516a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	a48080e7          	jalr	-1464(ra) # 80001bb6 <myproc>
    80005176:	84aa                	mv	s1,a0

  begin_op();
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	48e080e7          	jalr	1166(ra) # 80004606 <begin_op>

  if((ip = namei(path)) == 0){
    80005180:	854a                	mv	a0,s2
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	284080e7          	jalr	644(ra) # 80004406 <namei>
    8000518a:	c92d                	beqz	a0,800051fc <exec+0xbc>
    8000518c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	ad2080e7          	jalr	-1326(ra) # 80003c60 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005196:	04000713          	li	a4,64
    8000519a:	4681                	li	a3,0
    8000519c:	e5040613          	addi	a2,s0,-432
    800051a0:	4581                	li	a1,0
    800051a2:	8552                	mv	a0,s4
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	d70080e7          	jalr	-656(ra) # 80003f14 <readi>
    800051ac:	04000793          	li	a5,64
    800051b0:	00f51a63          	bne	a0,a5,800051c4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051b4:	e5042703          	lw	a4,-432(s0)
    800051b8:	464c47b7          	lui	a5,0x464c4
    800051bc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051c0:	04f70463          	beq	a4,a5,80005208 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051c4:	8552                	mv	a0,s4
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	cfc080e7          	jalr	-772(ra) # 80003ec2 <iunlockput>
    end_op();
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	4b2080e7          	jalr	1202(ra) # 80004680 <end_op>
  }
  return -1;
    800051d6:	557d                	li	a0,-1
}
    800051d8:	20813083          	ld	ra,520(sp)
    800051dc:	20013403          	ld	s0,512(sp)
    800051e0:	74fe                	ld	s1,504(sp)
    800051e2:	795e                	ld	s2,496(sp)
    800051e4:	79be                	ld	s3,488(sp)
    800051e6:	7a1e                	ld	s4,480(sp)
    800051e8:	6afe                	ld	s5,472(sp)
    800051ea:	6b5e                	ld	s6,464(sp)
    800051ec:	6bbe                	ld	s7,456(sp)
    800051ee:	6c1e                	ld	s8,448(sp)
    800051f0:	7cfa                	ld	s9,440(sp)
    800051f2:	7d5a                	ld	s10,432(sp)
    800051f4:	7dba                	ld	s11,424(sp)
    800051f6:	21010113          	addi	sp,sp,528
    800051fa:	8082                	ret
    end_op();
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	484080e7          	jalr	1156(ra) # 80004680 <end_op>
    return -1;
    80005204:	557d                	li	a0,-1
    80005206:	bfc9                	j	800051d8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	a70080e7          	jalr	-1424(ra) # 80001c7a <proc_pagetable>
    80005212:	8b2a                	mv	s6,a0
    80005214:	d945                	beqz	a0,800051c4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005216:	e7042d03          	lw	s10,-400(s0)
    8000521a:	e8845783          	lhu	a5,-376(s0)
    8000521e:	10078463          	beqz	a5,80005326 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005222:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005224:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005226:	6c85                	lui	s9,0x1
    80005228:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000522c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005230:	6a85                	lui	s5,0x1
    80005232:	a0b5                	j	8000529e <exec+0x15e>
      panic("loadseg: address should exist");
    80005234:	00003517          	auipc	a0,0x3
    80005238:	65450513          	addi	a0,a0,1620 # 80008888 <syscalls+0x2c8>
    8000523c:	ffffb097          	auipc	ra,0xffffb
    80005240:	300080e7          	jalr	768(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005244:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005246:	8726                	mv	a4,s1
    80005248:	012c06bb          	addw	a3,s8,s2
    8000524c:	4581                	li	a1,0
    8000524e:	8552                	mv	a0,s4
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	cc4080e7          	jalr	-828(ra) # 80003f14 <readi>
    80005258:	2501                	sext.w	a0,a0
    8000525a:	24a49863          	bne	s1,a0,800054aa <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000525e:	012a893b          	addw	s2,s5,s2
    80005262:	03397563          	bgeu	s2,s3,8000528c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005266:	02091593          	slli	a1,s2,0x20
    8000526a:	9181                	srli	a1,a1,0x20
    8000526c:	95de                	add	a1,a1,s7
    8000526e:	855a                	mv	a0,s6
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	eda080e7          	jalr	-294(ra) # 8000114a <walkaddr>
    80005278:	862a                	mv	a2,a0
    if(pa == 0)
    8000527a:	dd4d                	beqz	a0,80005234 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000527c:	412984bb          	subw	s1,s3,s2
    80005280:	0004879b          	sext.w	a5,s1
    80005284:	fcfcf0e3          	bgeu	s9,a5,80005244 <exec+0x104>
    80005288:	84d6                	mv	s1,s5
    8000528a:	bf6d                	j	80005244 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000528c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005290:	2d85                	addiw	s11,s11,1
    80005292:	038d0d1b          	addiw	s10,s10,56
    80005296:	e8845783          	lhu	a5,-376(s0)
    8000529a:	08fdd763          	bge	s11,a5,80005328 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000529e:	2d01                	sext.w	s10,s10
    800052a0:	03800713          	li	a4,56
    800052a4:	86ea                	mv	a3,s10
    800052a6:	e1840613          	addi	a2,s0,-488
    800052aa:	4581                	li	a1,0
    800052ac:	8552                	mv	a0,s4
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	c66080e7          	jalr	-922(ra) # 80003f14 <readi>
    800052b6:	03800793          	li	a5,56
    800052ba:	1ef51663          	bne	a0,a5,800054a6 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800052be:	e1842783          	lw	a5,-488(s0)
    800052c2:	4705                	li	a4,1
    800052c4:	fce796e3          	bne	a5,a4,80005290 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800052c8:	e4043483          	ld	s1,-448(s0)
    800052cc:	e3843783          	ld	a5,-456(s0)
    800052d0:	1ef4e863          	bltu	s1,a5,800054c0 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052d4:	e2843783          	ld	a5,-472(s0)
    800052d8:	94be                	add	s1,s1,a5
    800052da:	1ef4e663          	bltu	s1,a5,800054c6 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800052de:	df043703          	ld	a4,-528(s0)
    800052e2:	8ff9                	and	a5,a5,a4
    800052e4:	1e079463          	bnez	a5,800054cc <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e8:	e1c42503          	lw	a0,-484(s0)
    800052ec:	00000097          	auipc	ra,0x0
    800052f0:	e3a080e7          	jalr	-454(ra) # 80005126 <flags2perm>
    800052f4:	86aa                	mv	a3,a0
    800052f6:	8626                	mv	a2,s1
    800052f8:	85ca                	mv	a1,s2
    800052fa:	855a                	mv	a0,s6
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	202080e7          	jalr	514(ra) # 800014fe <uvmalloc>
    80005304:	e0a43423          	sd	a0,-504(s0)
    80005308:	1c050563          	beqz	a0,800054d2 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000530c:	e2843b83          	ld	s7,-472(s0)
    80005310:	e2042c03          	lw	s8,-480(s0)
    80005314:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005318:	00098463          	beqz	s3,80005320 <exec+0x1e0>
    8000531c:	4901                	li	s2,0
    8000531e:	b7a1                	j	80005266 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005320:	e0843903          	ld	s2,-504(s0)
    80005324:	b7b5                	j	80005290 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005326:	4901                	li	s2,0
  iunlockput(ip);
    80005328:	8552                	mv	a0,s4
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	b98080e7          	jalr	-1128(ra) # 80003ec2 <iunlockput>
  end_op();
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	34e080e7          	jalr	846(ra) # 80004680 <end_op>
  p = myproc();
    8000533a:	ffffd097          	auipc	ra,0xffffd
    8000533e:	87c080e7          	jalr	-1924(ra) # 80001bb6 <myproc>
    80005342:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005344:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005348:	6985                	lui	s3,0x1
    8000534a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000534c:	99ca                	add	s3,s3,s2
    8000534e:	77fd                	lui	a5,0xfffff
    80005350:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005354:	4691                	li	a3,4
    80005356:	6609                	lui	a2,0x2
    80005358:	964e                	add	a2,a2,s3
    8000535a:	85ce                	mv	a1,s3
    8000535c:	855a                	mv	a0,s6
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	1a0080e7          	jalr	416(ra) # 800014fe <uvmalloc>
    80005366:	892a                	mv	s2,a0
    80005368:	e0a43423          	sd	a0,-504(s0)
    8000536c:	e509                	bnez	a0,80005376 <exec+0x236>
  if(pagetable)
    8000536e:	e1343423          	sd	s3,-504(s0)
    80005372:	4a01                	li	s4,0
    80005374:	aa1d                	j	800054aa <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005376:	75f9                	lui	a1,0xffffe
    80005378:	95aa                	add	a1,a1,a0
    8000537a:	855a                	mv	a0,s6
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	3d4080e7          	jalr	980(ra) # 80001750 <uvmclear>
  stackbase = sp - PGSIZE;
    80005384:	7bfd                	lui	s7,0xfffff
    80005386:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005388:	e0043783          	ld	a5,-512(s0)
    8000538c:	6388                	ld	a0,0(a5)
    8000538e:	c52d                	beqz	a0,800053f8 <exec+0x2b8>
    80005390:	e9040993          	addi	s3,s0,-368
    80005394:	f9040c13          	addi	s8,s0,-112
    80005398:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000539a:	ffffc097          	auipc	ra,0xffffc
    8000539e:	ba2080e7          	jalr	-1118(ra) # 80000f3c <strlen>
    800053a2:	0015079b          	addiw	a5,a0,1
    800053a6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053aa:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053ae:	13796563          	bltu	s2,s7,800054d8 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053b2:	e0043d03          	ld	s10,-512(s0)
    800053b6:	000d3a03          	ld	s4,0(s10)
    800053ba:	8552                	mv	a0,s4
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	b80080e7          	jalr	-1152(ra) # 80000f3c <strlen>
    800053c4:	0015069b          	addiw	a3,a0,1
    800053c8:	8652                	mv	a2,s4
    800053ca:	85ca                	mv	a1,s2
    800053cc:	855a                	mv	a0,s6
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	3b4080e7          	jalr	948(ra) # 80001782 <copyout>
    800053d6:	10054363          	bltz	a0,800054dc <exec+0x39c>
    ustack[argc] = sp;
    800053da:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053de:	0485                	addi	s1,s1,1
    800053e0:	008d0793          	addi	a5,s10,8
    800053e4:	e0f43023          	sd	a5,-512(s0)
    800053e8:	008d3503          	ld	a0,8(s10)
    800053ec:	c909                	beqz	a0,800053fe <exec+0x2be>
    if(argc >= MAXARG)
    800053ee:	09a1                	addi	s3,s3,8
    800053f0:	fb8995e3          	bne	s3,s8,8000539a <exec+0x25a>
  ip = 0;
    800053f4:	4a01                	li	s4,0
    800053f6:	a855                	j	800054aa <exec+0x36a>
  sp = sz;
    800053f8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800053fc:	4481                	li	s1,0
  ustack[argc] = 0;
    800053fe:	00349793          	slli	a5,s1,0x3
    80005402:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd5050>
    80005406:	97a2                	add	a5,a5,s0
    80005408:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000540c:	00148693          	addi	a3,s1,1
    80005410:	068e                	slli	a3,a3,0x3
    80005412:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005416:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000541a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000541e:	f57968e3          	bltu	s2,s7,8000536e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005422:	e9040613          	addi	a2,s0,-368
    80005426:	85ca                	mv	a1,s2
    80005428:	855a                	mv	a0,s6
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	358080e7          	jalr	856(ra) # 80001782 <copyout>
    80005432:	0a054763          	bltz	a0,800054e0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005436:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000543a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000543e:	df843783          	ld	a5,-520(s0)
    80005442:	0007c703          	lbu	a4,0(a5)
    80005446:	cf11                	beqz	a4,80005462 <exec+0x322>
    80005448:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000544a:	02f00693          	li	a3,47
    8000544e:	a039                	j	8000545c <exec+0x31c>
      last = s+1;
    80005450:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005454:	0785                	addi	a5,a5,1
    80005456:	fff7c703          	lbu	a4,-1(a5)
    8000545a:	c701                	beqz	a4,80005462 <exec+0x322>
    if(*s == '/')
    8000545c:	fed71ce3          	bne	a4,a3,80005454 <exec+0x314>
    80005460:	bfc5                	j	80005450 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005462:	4641                	li	a2,16
    80005464:	df843583          	ld	a1,-520(s0)
    80005468:	158a8513          	addi	a0,s5,344
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	a9e080e7          	jalr	-1378(ra) # 80000f0a <safestrcpy>
  oldpagetable = p->pagetable;
    80005474:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005478:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000547c:	e0843783          	ld	a5,-504(s0)
    80005480:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005484:	058ab783          	ld	a5,88(s5)
    80005488:	e6843703          	ld	a4,-408(s0)
    8000548c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000548e:	058ab783          	ld	a5,88(s5)
    80005492:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005496:	85e6                	mv	a1,s9
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	87e080e7          	jalr	-1922(ra) # 80001d16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054a0:	0004851b          	sext.w	a0,s1
    800054a4:	bb15                	j	800051d8 <exec+0x98>
    800054a6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054aa:	e0843583          	ld	a1,-504(s0)
    800054ae:	855a                	mv	a0,s6
    800054b0:	ffffd097          	auipc	ra,0xffffd
    800054b4:	866080e7          	jalr	-1946(ra) # 80001d16 <proc_freepagetable>
  return -1;
    800054b8:	557d                	li	a0,-1
  if(ip){
    800054ba:	d00a0fe3          	beqz	s4,800051d8 <exec+0x98>
    800054be:	b319                	j	800051c4 <exec+0x84>
    800054c0:	e1243423          	sd	s2,-504(s0)
    800054c4:	b7dd                	j	800054aa <exec+0x36a>
    800054c6:	e1243423          	sd	s2,-504(s0)
    800054ca:	b7c5                	j	800054aa <exec+0x36a>
    800054cc:	e1243423          	sd	s2,-504(s0)
    800054d0:	bfe9                	j	800054aa <exec+0x36a>
    800054d2:	e1243423          	sd	s2,-504(s0)
    800054d6:	bfd1                	j	800054aa <exec+0x36a>
  ip = 0;
    800054d8:	4a01                	li	s4,0
    800054da:	bfc1                	j	800054aa <exec+0x36a>
    800054dc:	4a01                	li	s4,0
  if(pagetable)
    800054de:	b7f1                	j	800054aa <exec+0x36a>
  sz = sz1;
    800054e0:	e0843983          	ld	s3,-504(s0)
    800054e4:	b569                	j	8000536e <exec+0x22e>

00000000800054e6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054e6:	7179                	addi	sp,sp,-48
    800054e8:	f406                	sd	ra,40(sp)
    800054ea:	f022                	sd	s0,32(sp)
    800054ec:	ec26                	sd	s1,24(sp)
    800054ee:	e84a                	sd	s2,16(sp)
    800054f0:	1800                	addi	s0,sp,48
    800054f2:	892e                	mv	s2,a1
    800054f4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054f6:	fdc40593          	addi	a1,s0,-36
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	aec080e7          	jalr	-1300(ra) # 80002fe6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005502:	fdc42703          	lw	a4,-36(s0)
    80005506:	47bd                	li	a5,15
    80005508:	02e7eb63          	bltu	a5,a4,8000553e <argfd+0x58>
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	6aa080e7          	jalr	1706(ra) # 80001bb6 <myproc>
    80005514:	fdc42703          	lw	a4,-36(s0)
    80005518:	01a70793          	addi	a5,a4,26
    8000551c:	078e                	slli	a5,a5,0x3
    8000551e:	953e                	add	a0,a0,a5
    80005520:	611c                	ld	a5,0(a0)
    80005522:	c385                	beqz	a5,80005542 <argfd+0x5c>
    return -1;
  if(pfd)
    80005524:	00090463          	beqz	s2,8000552c <argfd+0x46>
    *pfd = fd;
    80005528:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000552c:	4501                	li	a0,0
  if(pf)
    8000552e:	c091                	beqz	s1,80005532 <argfd+0x4c>
    *pf = f;
    80005530:	e09c                	sd	a5,0(s1)
}
    80005532:	70a2                	ld	ra,40(sp)
    80005534:	7402                	ld	s0,32(sp)
    80005536:	64e2                	ld	s1,24(sp)
    80005538:	6942                	ld	s2,16(sp)
    8000553a:	6145                	addi	sp,sp,48
    8000553c:	8082                	ret
    return -1;
    8000553e:	557d                	li	a0,-1
    80005540:	bfcd                	j	80005532 <argfd+0x4c>
    80005542:	557d                	li	a0,-1
    80005544:	b7fd                	j	80005532 <argfd+0x4c>

0000000080005546 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005546:	1101                	addi	sp,sp,-32
    80005548:	ec06                	sd	ra,24(sp)
    8000554a:	e822                	sd	s0,16(sp)
    8000554c:	e426                	sd	s1,8(sp)
    8000554e:	1000                	addi	s0,sp,32
    80005550:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005552:	ffffc097          	auipc	ra,0xffffc
    80005556:	664080e7          	jalr	1636(ra) # 80001bb6 <myproc>
    8000555a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000555c:	0d050793          	addi	a5,a0,208
    80005560:	4501                	li	a0,0
    80005562:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005564:	6398                	ld	a4,0(a5)
    80005566:	cb19                	beqz	a4,8000557c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005568:	2505                	addiw	a0,a0,1
    8000556a:	07a1                	addi	a5,a5,8
    8000556c:	fed51ce3          	bne	a0,a3,80005564 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005570:	557d                	li	a0,-1
}
    80005572:	60e2                	ld	ra,24(sp)
    80005574:	6442                	ld	s0,16(sp)
    80005576:	64a2                	ld	s1,8(sp)
    80005578:	6105                	addi	sp,sp,32
    8000557a:	8082                	ret
      p->ofile[fd] = f;
    8000557c:	01a50793          	addi	a5,a0,26
    80005580:	078e                	slli	a5,a5,0x3
    80005582:	963e                	add	a2,a2,a5
    80005584:	e204                	sd	s1,0(a2)
      return fd;
    80005586:	b7f5                	j	80005572 <fdalloc+0x2c>

0000000080005588 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005588:	715d                	addi	sp,sp,-80
    8000558a:	e486                	sd	ra,72(sp)
    8000558c:	e0a2                	sd	s0,64(sp)
    8000558e:	fc26                	sd	s1,56(sp)
    80005590:	f84a                	sd	s2,48(sp)
    80005592:	f44e                	sd	s3,40(sp)
    80005594:	f052                	sd	s4,32(sp)
    80005596:	ec56                	sd	s5,24(sp)
    80005598:	e85a                	sd	s6,16(sp)
    8000559a:	0880                	addi	s0,sp,80
    8000559c:	8b2e                	mv	s6,a1
    8000559e:	89b2                	mv	s3,a2
    800055a0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055a2:	fb040593          	addi	a1,s0,-80
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	e7e080e7          	jalr	-386(ra) # 80004424 <nameiparent>
    800055ae:	84aa                	mv	s1,a0
    800055b0:	14050b63          	beqz	a0,80005706 <create+0x17e>
    return 0;

  ilock(dp);
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	6ac080e7          	jalr	1708(ra) # 80003c60 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055bc:	4601                	li	a2,0
    800055be:	fb040593          	addi	a1,s0,-80
    800055c2:	8526                	mv	a0,s1
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	b80080e7          	jalr	-1152(ra) # 80004144 <dirlookup>
    800055cc:	8aaa                	mv	s5,a0
    800055ce:	c921                	beqz	a0,8000561e <create+0x96>
    iunlockput(dp);
    800055d0:	8526                	mv	a0,s1
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	8f0080e7          	jalr	-1808(ra) # 80003ec2 <iunlockput>
    ilock(ip);
    800055da:	8556                	mv	a0,s5
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	684080e7          	jalr	1668(ra) # 80003c60 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055e4:	4789                	li	a5,2
    800055e6:	02fb1563          	bne	s6,a5,80005610 <create+0x88>
    800055ea:	044ad783          	lhu	a5,68(s5)
    800055ee:	37f9                	addiw	a5,a5,-2
    800055f0:	17c2                	slli	a5,a5,0x30
    800055f2:	93c1                	srli	a5,a5,0x30
    800055f4:	4705                	li	a4,1
    800055f6:	00f76d63          	bltu	a4,a5,80005610 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055fa:	8556                	mv	a0,s5
    800055fc:	60a6                	ld	ra,72(sp)
    800055fe:	6406                	ld	s0,64(sp)
    80005600:	74e2                	ld	s1,56(sp)
    80005602:	7942                	ld	s2,48(sp)
    80005604:	79a2                	ld	s3,40(sp)
    80005606:	7a02                	ld	s4,32(sp)
    80005608:	6ae2                	ld	s5,24(sp)
    8000560a:	6b42                	ld	s6,16(sp)
    8000560c:	6161                	addi	sp,sp,80
    8000560e:	8082                	ret
    iunlockput(ip);
    80005610:	8556                	mv	a0,s5
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	8b0080e7          	jalr	-1872(ra) # 80003ec2 <iunlockput>
    return 0;
    8000561a:	4a81                	li	s5,0
    8000561c:	bff9                	j	800055fa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000561e:	85da                	mv	a1,s6
    80005620:	4088                	lw	a0,0(s1)
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	4a6080e7          	jalr	1190(ra) # 80003ac8 <ialloc>
    8000562a:	8a2a                	mv	s4,a0
    8000562c:	c529                	beqz	a0,80005676 <create+0xee>
  ilock(ip);
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	632080e7          	jalr	1586(ra) # 80003c60 <ilock>
  ip->major = major;
    80005636:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000563a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000563e:	4905                	li	s2,1
    80005640:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005644:	8552                	mv	a0,s4
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	54e080e7          	jalr	1358(ra) # 80003b94 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000564e:	032b0b63          	beq	s6,s2,80005684 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005652:	004a2603          	lw	a2,4(s4)
    80005656:	fb040593          	addi	a1,s0,-80
    8000565a:	8526                	mv	a0,s1
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	cf8080e7          	jalr	-776(ra) # 80004354 <dirlink>
    80005664:	06054f63          	bltz	a0,800056e2 <create+0x15a>
  iunlockput(dp);
    80005668:	8526                	mv	a0,s1
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	858080e7          	jalr	-1960(ra) # 80003ec2 <iunlockput>
  return ip;
    80005672:	8ad2                	mv	s5,s4
    80005674:	b759                	j	800055fa <create+0x72>
    iunlockput(dp);
    80005676:	8526                	mv	a0,s1
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	84a080e7          	jalr	-1974(ra) # 80003ec2 <iunlockput>
    return 0;
    80005680:	8ad2                	mv	s5,s4
    80005682:	bfa5                	j	800055fa <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005684:	004a2603          	lw	a2,4(s4)
    80005688:	00003597          	auipc	a1,0x3
    8000568c:	22058593          	addi	a1,a1,544 # 800088a8 <syscalls+0x2e8>
    80005690:	8552                	mv	a0,s4
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	cc2080e7          	jalr	-830(ra) # 80004354 <dirlink>
    8000569a:	04054463          	bltz	a0,800056e2 <create+0x15a>
    8000569e:	40d0                	lw	a2,4(s1)
    800056a0:	00003597          	auipc	a1,0x3
    800056a4:	21058593          	addi	a1,a1,528 # 800088b0 <syscalls+0x2f0>
    800056a8:	8552                	mv	a0,s4
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	caa080e7          	jalr	-854(ra) # 80004354 <dirlink>
    800056b2:	02054863          	bltz	a0,800056e2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800056b6:	004a2603          	lw	a2,4(s4)
    800056ba:	fb040593          	addi	a1,s0,-80
    800056be:	8526                	mv	a0,s1
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	c94080e7          	jalr	-876(ra) # 80004354 <dirlink>
    800056c8:	00054d63          	bltz	a0,800056e2 <create+0x15a>
    dp->nlink++;  // for ".."
    800056cc:	04a4d783          	lhu	a5,74(s1)
    800056d0:	2785                	addiw	a5,a5,1
    800056d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	4bc080e7          	jalr	1212(ra) # 80003b94 <iupdate>
    800056e0:	b761                	j	80005668 <create+0xe0>
  ip->nlink = 0;
    800056e2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056e6:	8552                	mv	a0,s4
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	4ac080e7          	jalr	1196(ra) # 80003b94 <iupdate>
  iunlockput(ip);
    800056f0:	8552                	mv	a0,s4
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	7d0080e7          	jalr	2000(ra) # 80003ec2 <iunlockput>
  iunlockput(dp);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	7c6080e7          	jalr	1990(ra) # 80003ec2 <iunlockput>
  return 0;
    80005704:	bddd                	j	800055fa <create+0x72>
    return 0;
    80005706:	8aaa                	mv	s5,a0
    80005708:	bdcd                	j	800055fa <create+0x72>

000000008000570a <sys_dup>:
{
    8000570a:	7179                	addi	sp,sp,-48
    8000570c:	f406                	sd	ra,40(sp)
    8000570e:	f022                	sd	s0,32(sp)
    80005710:	ec26                	sd	s1,24(sp)
    80005712:	e84a                	sd	s2,16(sp)
    80005714:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005716:	fd840613          	addi	a2,s0,-40
    8000571a:	4581                	li	a1,0
    8000571c:	4501                	li	a0,0
    8000571e:	00000097          	auipc	ra,0x0
    80005722:	dc8080e7          	jalr	-568(ra) # 800054e6 <argfd>
    return -1;
    80005726:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005728:	02054363          	bltz	a0,8000574e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000572c:	fd843903          	ld	s2,-40(s0)
    80005730:	854a                	mv	a0,s2
    80005732:	00000097          	auipc	ra,0x0
    80005736:	e14080e7          	jalr	-492(ra) # 80005546 <fdalloc>
    8000573a:	84aa                	mv	s1,a0
    return -1;
    8000573c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000573e:	00054863          	bltz	a0,8000574e <sys_dup+0x44>
  filedup(f);
    80005742:	854a                	mv	a0,s2
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	334080e7          	jalr	820(ra) # 80004a78 <filedup>
  return fd;
    8000574c:	87a6                	mv	a5,s1
}
    8000574e:	853e                	mv	a0,a5
    80005750:	70a2                	ld	ra,40(sp)
    80005752:	7402                	ld	s0,32(sp)
    80005754:	64e2                	ld	s1,24(sp)
    80005756:	6942                	ld	s2,16(sp)
    80005758:	6145                	addi	sp,sp,48
    8000575a:	8082                	ret

000000008000575c <sys_read>:
{
    8000575c:	7179                	addi	sp,sp,-48
    8000575e:	f406                	sd	ra,40(sp)
    80005760:	f022                	sd	s0,32(sp)
    80005762:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005764:	fd840593          	addi	a1,s0,-40
    80005768:	4505                	li	a0,1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	89c080e7          	jalr	-1892(ra) # 80003006 <argaddr>
  argint(2, &n);
    80005772:	fe440593          	addi	a1,s0,-28
    80005776:	4509                	li	a0,2
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	86e080e7          	jalr	-1938(ra) # 80002fe6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005780:	fe840613          	addi	a2,s0,-24
    80005784:	4581                	li	a1,0
    80005786:	4501                	li	a0,0
    80005788:	00000097          	auipc	ra,0x0
    8000578c:	d5e080e7          	jalr	-674(ra) # 800054e6 <argfd>
    80005790:	87aa                	mv	a5,a0
    return -1;
    80005792:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005794:	0007cc63          	bltz	a5,800057ac <sys_read+0x50>
  return fileread(f, p, n);
    80005798:	fe442603          	lw	a2,-28(s0)
    8000579c:	fd843583          	ld	a1,-40(s0)
    800057a0:	fe843503          	ld	a0,-24(s0)
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	460080e7          	jalr	1120(ra) # 80004c04 <fileread>
}
    800057ac:	70a2                	ld	ra,40(sp)
    800057ae:	7402                	ld	s0,32(sp)
    800057b0:	6145                	addi	sp,sp,48
    800057b2:	8082                	ret

00000000800057b4 <sys_write>:
{
    800057b4:	7179                	addi	sp,sp,-48
    800057b6:	f406                	sd	ra,40(sp)
    800057b8:	f022                	sd	s0,32(sp)
    800057ba:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057bc:	fd840593          	addi	a1,s0,-40
    800057c0:	4505                	li	a0,1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	844080e7          	jalr	-1980(ra) # 80003006 <argaddr>
  argint(2, &n);
    800057ca:	fe440593          	addi	a1,s0,-28
    800057ce:	4509                	li	a0,2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	816080e7          	jalr	-2026(ra) # 80002fe6 <argint>
  if(argfd(0, 0, &f) < 0)
    800057d8:	fe840613          	addi	a2,s0,-24
    800057dc:	4581                	li	a1,0
    800057de:	4501                	li	a0,0
    800057e0:	00000097          	auipc	ra,0x0
    800057e4:	d06080e7          	jalr	-762(ra) # 800054e6 <argfd>
    800057e8:	87aa                	mv	a5,a0
    return -1;
    800057ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057ec:	0007cc63          	bltz	a5,80005804 <sys_write+0x50>
  return filewrite(f, p, n);
    800057f0:	fe442603          	lw	a2,-28(s0)
    800057f4:	fd843583          	ld	a1,-40(s0)
    800057f8:	fe843503          	ld	a0,-24(s0)
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	4ca080e7          	jalr	1226(ra) # 80004cc6 <filewrite>
}
    80005804:	70a2                	ld	ra,40(sp)
    80005806:	7402                	ld	s0,32(sp)
    80005808:	6145                	addi	sp,sp,48
    8000580a:	8082                	ret

000000008000580c <sys_close>:
{
    8000580c:	1101                	addi	sp,sp,-32
    8000580e:	ec06                	sd	ra,24(sp)
    80005810:	e822                	sd	s0,16(sp)
    80005812:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005814:	fe040613          	addi	a2,s0,-32
    80005818:	fec40593          	addi	a1,s0,-20
    8000581c:	4501                	li	a0,0
    8000581e:	00000097          	auipc	ra,0x0
    80005822:	cc8080e7          	jalr	-824(ra) # 800054e6 <argfd>
    return -1;
    80005826:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005828:	02054463          	bltz	a0,80005850 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000582c:	ffffc097          	auipc	ra,0xffffc
    80005830:	38a080e7          	jalr	906(ra) # 80001bb6 <myproc>
    80005834:	fec42783          	lw	a5,-20(s0)
    80005838:	07e9                	addi	a5,a5,26
    8000583a:	078e                	slli	a5,a5,0x3
    8000583c:	953e                	add	a0,a0,a5
    8000583e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005842:	fe043503          	ld	a0,-32(s0)
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	284080e7          	jalr	644(ra) # 80004aca <fileclose>
  return 0;
    8000584e:	4781                	li	a5,0
}
    80005850:	853e                	mv	a0,a5
    80005852:	60e2                	ld	ra,24(sp)
    80005854:	6442                	ld	s0,16(sp)
    80005856:	6105                	addi	sp,sp,32
    80005858:	8082                	ret

000000008000585a <sys_fstat>:
{
    8000585a:	1101                	addi	sp,sp,-32
    8000585c:	ec06                	sd	ra,24(sp)
    8000585e:	e822                	sd	s0,16(sp)
    80005860:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005862:	fe040593          	addi	a1,s0,-32
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	79e080e7          	jalr	1950(ra) # 80003006 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005870:	fe840613          	addi	a2,s0,-24
    80005874:	4581                	li	a1,0
    80005876:	4501                	li	a0,0
    80005878:	00000097          	auipc	ra,0x0
    8000587c:	c6e080e7          	jalr	-914(ra) # 800054e6 <argfd>
    80005880:	87aa                	mv	a5,a0
    return -1;
    80005882:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005884:	0007ca63          	bltz	a5,80005898 <sys_fstat+0x3e>
  return filestat(f, st);
    80005888:	fe043583          	ld	a1,-32(s0)
    8000588c:	fe843503          	ld	a0,-24(s0)
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	302080e7          	jalr	770(ra) # 80004b92 <filestat>
}
    80005898:	60e2                	ld	ra,24(sp)
    8000589a:	6442                	ld	s0,16(sp)
    8000589c:	6105                	addi	sp,sp,32
    8000589e:	8082                	ret

00000000800058a0 <sys_link>:
{
    800058a0:	7169                	addi	sp,sp,-304
    800058a2:	f606                	sd	ra,296(sp)
    800058a4:	f222                	sd	s0,288(sp)
    800058a6:	ee26                	sd	s1,280(sp)
    800058a8:	ea4a                	sd	s2,272(sp)
    800058aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ac:	08000613          	li	a2,128
    800058b0:	ed040593          	addi	a1,s0,-304
    800058b4:	4501                	li	a0,0
    800058b6:	ffffd097          	auipc	ra,0xffffd
    800058ba:	770080e7          	jalr	1904(ra) # 80003026 <argstr>
    return -1;
    800058be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c0:	10054e63          	bltz	a0,800059dc <sys_link+0x13c>
    800058c4:	08000613          	li	a2,128
    800058c8:	f5040593          	addi	a1,s0,-176
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	758080e7          	jalr	1880(ra) # 80003026 <argstr>
    return -1;
    800058d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d8:	10054263          	bltz	a0,800059dc <sys_link+0x13c>
  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	d2a080e7          	jalr	-726(ra) # 80004606 <begin_op>
  if((ip = namei(old)) == 0){
    800058e4:	ed040513          	addi	a0,s0,-304
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	b1e080e7          	jalr	-1250(ra) # 80004406 <namei>
    800058f0:	84aa                	mv	s1,a0
    800058f2:	c551                	beqz	a0,8000597e <sys_link+0xde>
  ilock(ip);
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	36c080e7          	jalr	876(ra) # 80003c60 <ilock>
  if(ip->type == T_DIR){
    800058fc:	04449703          	lh	a4,68(s1)
    80005900:	4785                	li	a5,1
    80005902:	08f70463          	beq	a4,a5,8000598a <sys_link+0xea>
  ip->nlink++;
    80005906:	04a4d783          	lhu	a5,74(s1)
    8000590a:	2785                	addiw	a5,a5,1
    8000590c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	282080e7          	jalr	642(ra) # 80003b94 <iupdate>
  iunlock(ip);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	406080e7          	jalr	1030(ra) # 80003d22 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005924:	fd040593          	addi	a1,s0,-48
    80005928:	f5040513          	addi	a0,s0,-176
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	af8080e7          	jalr	-1288(ra) # 80004424 <nameiparent>
    80005934:	892a                	mv	s2,a0
    80005936:	c935                	beqz	a0,800059aa <sys_link+0x10a>
  ilock(dp);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	328080e7          	jalr	808(ra) # 80003c60 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005940:	00092703          	lw	a4,0(s2)
    80005944:	409c                	lw	a5,0(s1)
    80005946:	04f71d63          	bne	a4,a5,800059a0 <sys_link+0x100>
    8000594a:	40d0                	lw	a2,4(s1)
    8000594c:	fd040593          	addi	a1,s0,-48
    80005950:	854a                	mv	a0,s2
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	a02080e7          	jalr	-1534(ra) # 80004354 <dirlink>
    8000595a:	04054363          	bltz	a0,800059a0 <sys_link+0x100>
  iunlockput(dp);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	562080e7          	jalr	1378(ra) # 80003ec2 <iunlockput>
  iput(ip);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	4b0080e7          	jalr	1200(ra) # 80003e1a <iput>
  end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	d0e080e7          	jalr	-754(ra) # 80004680 <end_op>
  return 0;
    8000597a:	4781                	li	a5,0
    8000597c:	a085                	j	800059dc <sys_link+0x13c>
    end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	d02080e7          	jalr	-766(ra) # 80004680 <end_op>
    return -1;
    80005986:	57fd                	li	a5,-1
    80005988:	a891                	j	800059dc <sys_link+0x13c>
    iunlockput(ip);
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	536080e7          	jalr	1334(ra) # 80003ec2 <iunlockput>
    end_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	cec080e7          	jalr	-788(ra) # 80004680 <end_op>
    return -1;
    8000599c:	57fd                	li	a5,-1
    8000599e:	a83d                	j	800059dc <sys_link+0x13c>
    iunlockput(dp);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	520080e7          	jalr	1312(ra) # 80003ec2 <iunlockput>
  ilock(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	2b4080e7          	jalr	692(ra) # 80003c60 <ilock>
  ip->nlink--;
    800059b4:	04a4d783          	lhu	a5,74(s1)
    800059b8:	37fd                	addiw	a5,a5,-1
    800059ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	1d4080e7          	jalr	468(ra) # 80003b94 <iupdate>
  iunlockput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	4f8080e7          	jalr	1272(ra) # 80003ec2 <iunlockput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	cae080e7          	jalr	-850(ra) # 80004680 <end_op>
  return -1;
    800059da:	57fd                	li	a5,-1
}
    800059dc:	853e                	mv	a0,a5
    800059de:	70b2                	ld	ra,296(sp)
    800059e0:	7412                	ld	s0,288(sp)
    800059e2:	64f2                	ld	s1,280(sp)
    800059e4:	6952                	ld	s2,272(sp)
    800059e6:	6155                	addi	sp,sp,304
    800059e8:	8082                	ret

00000000800059ea <sys_unlink>:
{
    800059ea:	7151                	addi	sp,sp,-240
    800059ec:	f586                	sd	ra,232(sp)
    800059ee:	f1a2                	sd	s0,224(sp)
    800059f0:	eda6                	sd	s1,216(sp)
    800059f2:	e9ca                	sd	s2,208(sp)
    800059f4:	e5ce                	sd	s3,200(sp)
    800059f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059f8:	08000613          	li	a2,128
    800059fc:	f3040593          	addi	a1,s0,-208
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	624080e7          	jalr	1572(ra) # 80003026 <argstr>
    80005a0a:	18054163          	bltz	a0,80005b8c <sys_unlink+0x1a2>
  begin_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	bf8080e7          	jalr	-1032(ra) # 80004606 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a16:	fb040593          	addi	a1,s0,-80
    80005a1a:	f3040513          	addi	a0,s0,-208
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	a06080e7          	jalr	-1530(ra) # 80004424 <nameiparent>
    80005a26:	84aa                	mv	s1,a0
    80005a28:	c979                	beqz	a0,80005afe <sys_unlink+0x114>
  ilock(dp);
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	236080e7          	jalr	566(ra) # 80003c60 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a32:	00003597          	auipc	a1,0x3
    80005a36:	e7658593          	addi	a1,a1,-394 # 800088a8 <syscalls+0x2e8>
    80005a3a:	fb040513          	addi	a0,s0,-80
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	6ec080e7          	jalr	1772(ra) # 8000412a <namecmp>
    80005a46:	14050a63          	beqz	a0,80005b9a <sys_unlink+0x1b0>
    80005a4a:	00003597          	auipc	a1,0x3
    80005a4e:	e6658593          	addi	a1,a1,-410 # 800088b0 <syscalls+0x2f0>
    80005a52:	fb040513          	addi	a0,s0,-80
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	6d4080e7          	jalr	1748(ra) # 8000412a <namecmp>
    80005a5e:	12050e63          	beqz	a0,80005b9a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a62:	f2c40613          	addi	a2,s0,-212
    80005a66:	fb040593          	addi	a1,s0,-80
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	6d8080e7          	jalr	1752(ra) # 80004144 <dirlookup>
    80005a74:	892a                	mv	s2,a0
    80005a76:	12050263          	beqz	a0,80005b9a <sys_unlink+0x1b0>
  ilock(ip);
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	1e6080e7          	jalr	486(ra) # 80003c60 <ilock>
  if(ip->nlink < 1)
    80005a82:	04a91783          	lh	a5,74(s2)
    80005a86:	08f05263          	blez	a5,80005b0a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a8a:	04491703          	lh	a4,68(s2)
    80005a8e:	4785                	li	a5,1
    80005a90:	08f70563          	beq	a4,a5,80005b1a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a94:	4641                	li	a2,16
    80005a96:	4581                	li	a1,0
    80005a98:	fc040513          	addi	a0,s0,-64
    80005a9c:	ffffb097          	auipc	ra,0xffffb
    80005aa0:	326080e7          	jalr	806(ra) # 80000dc2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aa4:	4741                	li	a4,16
    80005aa6:	f2c42683          	lw	a3,-212(s0)
    80005aaa:	fc040613          	addi	a2,s0,-64
    80005aae:	4581                	li	a1,0
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	55a080e7          	jalr	1370(ra) # 8000400c <writei>
    80005aba:	47c1                	li	a5,16
    80005abc:	0af51563          	bne	a0,a5,80005b66 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ac0:	04491703          	lh	a4,68(s2)
    80005ac4:	4785                	li	a5,1
    80005ac6:	0af70863          	beq	a4,a5,80005b76 <sys_unlink+0x18c>
  iunlockput(dp);
    80005aca:	8526                	mv	a0,s1
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	3f6080e7          	jalr	1014(ra) # 80003ec2 <iunlockput>
  ip->nlink--;
    80005ad4:	04a95783          	lhu	a5,74(s2)
    80005ad8:	37fd                	addiw	a5,a5,-1
    80005ada:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ade:	854a                	mv	a0,s2
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	0b4080e7          	jalr	180(ra) # 80003b94 <iupdate>
  iunlockput(ip);
    80005ae8:	854a                	mv	a0,s2
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	3d8080e7          	jalr	984(ra) # 80003ec2 <iunlockput>
  end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	b8e080e7          	jalr	-1138(ra) # 80004680 <end_op>
  return 0;
    80005afa:	4501                	li	a0,0
    80005afc:	a84d                	j	80005bae <sys_unlink+0x1c4>
    end_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	b82080e7          	jalr	-1150(ra) # 80004680 <end_op>
    return -1;
    80005b06:	557d                	li	a0,-1
    80005b08:	a05d                	j	80005bae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b0a:	00003517          	auipc	a0,0x3
    80005b0e:	dae50513          	addi	a0,a0,-594 # 800088b8 <syscalls+0x2f8>
    80005b12:	ffffb097          	auipc	ra,0xffffb
    80005b16:	a2a080e7          	jalr	-1494(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b1a:	04c92703          	lw	a4,76(s2)
    80005b1e:	02000793          	li	a5,32
    80005b22:	f6e7f9e3          	bgeu	a5,a4,80005a94 <sys_unlink+0xaa>
    80005b26:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b2a:	4741                	li	a4,16
    80005b2c:	86ce                	mv	a3,s3
    80005b2e:	f1840613          	addi	a2,s0,-232
    80005b32:	4581                	li	a1,0
    80005b34:	854a                	mv	a0,s2
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	3de080e7          	jalr	990(ra) # 80003f14 <readi>
    80005b3e:	47c1                	li	a5,16
    80005b40:	00f51b63          	bne	a0,a5,80005b56 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b44:	f1845783          	lhu	a5,-232(s0)
    80005b48:	e7a1                	bnez	a5,80005b90 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b4a:	29c1                	addiw	s3,s3,16
    80005b4c:	04c92783          	lw	a5,76(s2)
    80005b50:	fcf9ede3          	bltu	s3,a5,80005b2a <sys_unlink+0x140>
    80005b54:	b781                	j	80005a94 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b56:	00003517          	auipc	a0,0x3
    80005b5a:	d7a50513          	addi	a0,a0,-646 # 800088d0 <syscalls+0x310>
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	9de080e7          	jalr	-1570(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005b66:	00003517          	auipc	a0,0x3
    80005b6a:	d8250513          	addi	a0,a0,-638 # 800088e8 <syscalls+0x328>
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	9ce080e7          	jalr	-1586(ra) # 8000053c <panic>
    dp->nlink--;
    80005b76:	04a4d783          	lhu	a5,74(s1)
    80005b7a:	37fd                	addiw	a5,a5,-1
    80005b7c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b80:	8526                	mv	a0,s1
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	012080e7          	jalr	18(ra) # 80003b94 <iupdate>
    80005b8a:	b781                	j	80005aca <sys_unlink+0xe0>
    return -1;
    80005b8c:	557d                	li	a0,-1
    80005b8e:	a005                	j	80005bae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b90:	854a                	mv	a0,s2
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	330080e7          	jalr	816(ra) # 80003ec2 <iunlockput>
  iunlockput(dp);
    80005b9a:	8526                	mv	a0,s1
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	326080e7          	jalr	806(ra) # 80003ec2 <iunlockput>
  end_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	adc080e7          	jalr	-1316(ra) # 80004680 <end_op>
  return -1;
    80005bac:	557d                	li	a0,-1
}
    80005bae:	70ae                	ld	ra,232(sp)
    80005bb0:	740e                	ld	s0,224(sp)
    80005bb2:	64ee                	ld	s1,216(sp)
    80005bb4:	694e                	ld	s2,208(sp)
    80005bb6:	69ae                	ld	s3,200(sp)
    80005bb8:	616d                	addi	sp,sp,240
    80005bba:	8082                	ret

0000000080005bbc <sys_open>:

uint64
sys_open(void)
{
    80005bbc:	7131                	addi	sp,sp,-192
    80005bbe:	fd06                	sd	ra,184(sp)
    80005bc0:	f922                	sd	s0,176(sp)
    80005bc2:	f526                	sd	s1,168(sp)
    80005bc4:	f14a                	sd	s2,160(sp)
    80005bc6:	ed4e                	sd	s3,152(sp)
    80005bc8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005bca:	f4c40593          	addi	a1,s0,-180
    80005bce:	4505                	li	a0,1
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	416080e7          	jalr	1046(ra) # 80002fe6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bd8:	08000613          	li	a2,128
    80005bdc:	f5040593          	addi	a1,s0,-176
    80005be0:	4501                	li	a0,0
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	444080e7          	jalr	1092(ra) # 80003026 <argstr>
    80005bea:	87aa                	mv	a5,a0
    return -1;
    80005bec:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bee:	0a07c863          	bltz	a5,80005c9e <sys_open+0xe2>

  begin_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	a14080e7          	jalr	-1516(ra) # 80004606 <begin_op>

  if(omode & O_CREATE){
    80005bfa:	f4c42783          	lw	a5,-180(s0)
    80005bfe:	2007f793          	andi	a5,a5,512
    80005c02:	cbdd                	beqz	a5,80005cb8 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005c04:	4681                	li	a3,0
    80005c06:	4601                	li	a2,0
    80005c08:	4589                	li	a1,2
    80005c0a:	f5040513          	addi	a0,s0,-176
    80005c0e:	00000097          	auipc	ra,0x0
    80005c12:	97a080e7          	jalr	-1670(ra) # 80005588 <create>
    80005c16:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c18:	c951                	beqz	a0,80005cac <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c1a:	04449703          	lh	a4,68(s1)
    80005c1e:	478d                	li	a5,3
    80005c20:	00f71763          	bne	a4,a5,80005c2e <sys_open+0x72>
    80005c24:	0464d703          	lhu	a4,70(s1)
    80005c28:	47a5                	li	a5,9
    80005c2a:	0ce7ec63          	bltu	a5,a4,80005d02 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	de0080e7          	jalr	-544(ra) # 80004a0e <filealloc>
    80005c36:	892a                	mv	s2,a0
    80005c38:	c56d                	beqz	a0,80005d22 <sys_open+0x166>
    80005c3a:	00000097          	auipc	ra,0x0
    80005c3e:	90c080e7          	jalr	-1780(ra) # 80005546 <fdalloc>
    80005c42:	89aa                	mv	s3,a0
    80005c44:	0c054a63          	bltz	a0,80005d18 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c48:	04449703          	lh	a4,68(s1)
    80005c4c:	478d                	li	a5,3
    80005c4e:	0ef70563          	beq	a4,a5,80005d38 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c52:	4789                	li	a5,2
    80005c54:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005c58:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005c5c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005c60:	f4c42783          	lw	a5,-180(s0)
    80005c64:	0017c713          	xori	a4,a5,1
    80005c68:	8b05                	andi	a4,a4,1
    80005c6a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c6e:	0037f713          	andi	a4,a5,3
    80005c72:	00e03733          	snez	a4,a4
    80005c76:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c7a:	4007f793          	andi	a5,a5,1024
    80005c7e:	c791                	beqz	a5,80005c8a <sys_open+0xce>
    80005c80:	04449703          	lh	a4,68(s1)
    80005c84:	4789                	li	a5,2
    80005c86:	0cf70063          	beq	a4,a5,80005d46 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	096080e7          	jalr	150(ra) # 80003d22 <iunlock>
  end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	9ec080e7          	jalr	-1556(ra) # 80004680 <end_op>

  return fd;
    80005c9c:	854e                	mv	a0,s3
}
    80005c9e:	70ea                	ld	ra,184(sp)
    80005ca0:	744a                	ld	s0,176(sp)
    80005ca2:	74aa                	ld	s1,168(sp)
    80005ca4:	790a                	ld	s2,160(sp)
    80005ca6:	69ea                	ld	s3,152(sp)
    80005ca8:	6129                	addi	sp,sp,192
    80005caa:	8082                	ret
      end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	9d4080e7          	jalr	-1580(ra) # 80004680 <end_op>
      return -1;
    80005cb4:	557d                	li	a0,-1
    80005cb6:	b7e5                	j	80005c9e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005cb8:	f5040513          	addi	a0,s0,-176
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	74a080e7          	jalr	1866(ra) # 80004406 <namei>
    80005cc4:	84aa                	mv	s1,a0
    80005cc6:	c905                	beqz	a0,80005cf6 <sys_open+0x13a>
    ilock(ip);
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	f98080e7          	jalr	-104(ra) # 80003c60 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cd0:	04449703          	lh	a4,68(s1)
    80005cd4:	4785                	li	a5,1
    80005cd6:	f4f712e3          	bne	a4,a5,80005c1a <sys_open+0x5e>
    80005cda:	f4c42783          	lw	a5,-180(s0)
    80005cde:	dba1                	beqz	a5,80005c2e <sys_open+0x72>
      iunlockput(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	1e0080e7          	jalr	480(ra) # 80003ec2 <iunlockput>
      end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	996080e7          	jalr	-1642(ra) # 80004680 <end_op>
      return -1;
    80005cf2:	557d                	li	a0,-1
    80005cf4:	b76d                	j	80005c9e <sys_open+0xe2>
      end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	98a080e7          	jalr	-1654(ra) # 80004680 <end_op>
      return -1;
    80005cfe:	557d                	li	a0,-1
    80005d00:	bf79                	j	80005c9e <sys_open+0xe2>
    iunlockput(ip);
    80005d02:	8526                	mv	a0,s1
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	1be080e7          	jalr	446(ra) # 80003ec2 <iunlockput>
    end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	974080e7          	jalr	-1676(ra) # 80004680 <end_op>
    return -1;
    80005d14:	557d                	li	a0,-1
    80005d16:	b761                	j	80005c9e <sys_open+0xe2>
      fileclose(f);
    80005d18:	854a                	mv	a0,s2
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	db0080e7          	jalr	-592(ra) # 80004aca <fileclose>
    iunlockput(ip);
    80005d22:	8526                	mv	a0,s1
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	19e080e7          	jalr	414(ra) # 80003ec2 <iunlockput>
    end_op();
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	954080e7          	jalr	-1708(ra) # 80004680 <end_op>
    return -1;
    80005d34:	557d                	li	a0,-1
    80005d36:	b7a5                	j	80005c9e <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005d38:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005d3c:	04649783          	lh	a5,70(s1)
    80005d40:	02f91223          	sh	a5,36(s2)
    80005d44:	bf21                	j	80005c5c <sys_open+0xa0>
    itrunc(ip);
    80005d46:	8526                	mv	a0,s1
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	026080e7          	jalr	38(ra) # 80003d6e <itrunc>
    80005d50:	bf2d                	j	80005c8a <sys_open+0xce>

0000000080005d52 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d52:	7175                	addi	sp,sp,-144
    80005d54:	e506                	sd	ra,136(sp)
    80005d56:	e122                	sd	s0,128(sp)
    80005d58:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	8ac080e7          	jalr	-1876(ra) # 80004606 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d62:	08000613          	li	a2,128
    80005d66:	f7040593          	addi	a1,s0,-144
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	2ba080e7          	jalr	698(ra) # 80003026 <argstr>
    80005d74:	02054963          	bltz	a0,80005da6 <sys_mkdir+0x54>
    80005d78:	4681                	li	a3,0
    80005d7a:	4601                	li	a2,0
    80005d7c:	4585                	li	a1,1
    80005d7e:	f7040513          	addi	a0,s0,-144
    80005d82:	00000097          	auipc	ra,0x0
    80005d86:	806080e7          	jalr	-2042(ra) # 80005588 <create>
    80005d8a:	cd11                	beqz	a0,80005da6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	136080e7          	jalr	310(ra) # 80003ec2 <iunlockput>
  end_op();
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	8ec080e7          	jalr	-1812(ra) # 80004680 <end_op>
  return 0;
    80005d9c:	4501                	li	a0,0
}
    80005d9e:	60aa                	ld	ra,136(sp)
    80005da0:	640a                	ld	s0,128(sp)
    80005da2:	6149                	addi	sp,sp,144
    80005da4:	8082                	ret
    end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	8da080e7          	jalr	-1830(ra) # 80004680 <end_op>
    return -1;
    80005dae:	557d                	li	a0,-1
    80005db0:	b7fd                	j	80005d9e <sys_mkdir+0x4c>

0000000080005db2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005db2:	7135                	addi	sp,sp,-160
    80005db4:	ed06                	sd	ra,152(sp)
    80005db6:	e922                	sd	s0,144(sp)
    80005db8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	84c080e7          	jalr	-1972(ra) # 80004606 <begin_op>
  argint(1, &major);
    80005dc2:	f6c40593          	addi	a1,s0,-148
    80005dc6:	4505                	li	a0,1
    80005dc8:	ffffd097          	auipc	ra,0xffffd
    80005dcc:	21e080e7          	jalr	542(ra) # 80002fe6 <argint>
  argint(2, &minor);
    80005dd0:	f6840593          	addi	a1,s0,-152
    80005dd4:	4509                	li	a0,2
    80005dd6:	ffffd097          	auipc	ra,0xffffd
    80005dda:	210080e7          	jalr	528(ra) # 80002fe6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dde:	08000613          	li	a2,128
    80005de2:	f7040593          	addi	a1,s0,-144
    80005de6:	4501                	li	a0,0
    80005de8:	ffffd097          	auipc	ra,0xffffd
    80005dec:	23e080e7          	jalr	574(ra) # 80003026 <argstr>
    80005df0:	02054b63          	bltz	a0,80005e26 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005df4:	f6841683          	lh	a3,-152(s0)
    80005df8:	f6c41603          	lh	a2,-148(s0)
    80005dfc:	458d                	li	a1,3
    80005dfe:	f7040513          	addi	a0,s0,-144
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	786080e7          	jalr	1926(ra) # 80005588 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e0a:	cd11                	beqz	a0,80005e26 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	0b6080e7          	jalr	182(ra) # 80003ec2 <iunlockput>
  end_op();
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	86c080e7          	jalr	-1940(ra) # 80004680 <end_op>
  return 0;
    80005e1c:	4501                	li	a0,0
}
    80005e1e:	60ea                	ld	ra,152(sp)
    80005e20:	644a                	ld	s0,144(sp)
    80005e22:	610d                	addi	sp,sp,160
    80005e24:	8082                	ret
    end_op();
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	85a080e7          	jalr	-1958(ra) # 80004680 <end_op>
    return -1;
    80005e2e:	557d                	li	a0,-1
    80005e30:	b7fd                	j	80005e1e <sys_mknod+0x6c>

0000000080005e32 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e32:	7135                	addi	sp,sp,-160
    80005e34:	ed06                	sd	ra,152(sp)
    80005e36:	e922                	sd	s0,144(sp)
    80005e38:	e526                	sd	s1,136(sp)
    80005e3a:	e14a                	sd	s2,128(sp)
    80005e3c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e3e:	ffffc097          	auipc	ra,0xffffc
    80005e42:	d78080e7          	jalr	-648(ra) # 80001bb6 <myproc>
    80005e46:	892a                	mv	s2,a0
  
  begin_op();
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	7be080e7          	jalr	1982(ra) # 80004606 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e50:	08000613          	li	a2,128
    80005e54:	f6040593          	addi	a1,s0,-160
    80005e58:	4501                	li	a0,0
    80005e5a:	ffffd097          	auipc	ra,0xffffd
    80005e5e:	1cc080e7          	jalr	460(ra) # 80003026 <argstr>
    80005e62:	04054b63          	bltz	a0,80005eb8 <sys_chdir+0x86>
    80005e66:	f6040513          	addi	a0,s0,-160
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	59c080e7          	jalr	1436(ra) # 80004406 <namei>
    80005e72:	84aa                	mv	s1,a0
    80005e74:	c131                	beqz	a0,80005eb8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	dea080e7          	jalr	-534(ra) # 80003c60 <ilock>
  if(ip->type != T_DIR){
    80005e7e:	04449703          	lh	a4,68(s1)
    80005e82:	4785                	li	a5,1
    80005e84:	04f71063          	bne	a4,a5,80005ec4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e88:	8526                	mv	a0,s1
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	e98080e7          	jalr	-360(ra) # 80003d22 <iunlock>
  iput(p->cwd);
    80005e92:	15093503          	ld	a0,336(s2)
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	f84080e7          	jalr	-124(ra) # 80003e1a <iput>
  end_op();
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	7e2080e7          	jalr	2018(ra) # 80004680 <end_op>
  p->cwd = ip;
    80005ea6:	14993823          	sd	s1,336(s2)
  return 0;
    80005eaa:	4501                	li	a0,0
}
    80005eac:	60ea                	ld	ra,152(sp)
    80005eae:	644a                	ld	s0,144(sp)
    80005eb0:	64aa                	ld	s1,136(sp)
    80005eb2:	690a                	ld	s2,128(sp)
    80005eb4:	610d                	addi	sp,sp,160
    80005eb6:	8082                	ret
    end_op();
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	7c8080e7          	jalr	1992(ra) # 80004680 <end_op>
    return -1;
    80005ec0:	557d                	li	a0,-1
    80005ec2:	b7ed                	j	80005eac <sys_chdir+0x7a>
    iunlockput(ip);
    80005ec4:	8526                	mv	a0,s1
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	ffc080e7          	jalr	-4(ra) # 80003ec2 <iunlockput>
    end_op();
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	7b2080e7          	jalr	1970(ra) # 80004680 <end_op>
    return -1;
    80005ed6:	557d                	li	a0,-1
    80005ed8:	bfd1                	j	80005eac <sys_chdir+0x7a>

0000000080005eda <sys_exec>:

uint64
sys_exec(void)
{
    80005eda:	7121                	addi	sp,sp,-448
    80005edc:	ff06                	sd	ra,440(sp)
    80005ede:	fb22                	sd	s0,432(sp)
    80005ee0:	f726                	sd	s1,424(sp)
    80005ee2:	f34a                	sd	s2,416(sp)
    80005ee4:	ef4e                	sd	s3,408(sp)
    80005ee6:	eb52                	sd	s4,400(sp)
    80005ee8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005eea:	e4840593          	addi	a1,s0,-440
    80005eee:	4505                	li	a0,1
    80005ef0:	ffffd097          	auipc	ra,0xffffd
    80005ef4:	116080e7          	jalr	278(ra) # 80003006 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ef8:	08000613          	li	a2,128
    80005efc:	f5040593          	addi	a1,s0,-176
    80005f00:	4501                	li	a0,0
    80005f02:	ffffd097          	auipc	ra,0xffffd
    80005f06:	124080e7          	jalr	292(ra) # 80003026 <argstr>
    80005f0a:	87aa                	mv	a5,a0
    return -1;
    80005f0c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f0e:	0c07c263          	bltz	a5,80005fd2 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005f12:	10000613          	li	a2,256
    80005f16:	4581                	li	a1,0
    80005f18:	e5040513          	addi	a0,s0,-432
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	ea6080e7          	jalr	-346(ra) # 80000dc2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f24:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005f28:	89a6                	mv	s3,s1
    80005f2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f2c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f30:	00391513          	slli	a0,s2,0x3
    80005f34:	e4040593          	addi	a1,s0,-448
    80005f38:	e4843783          	ld	a5,-440(s0)
    80005f3c:	953e                	add	a0,a0,a5
    80005f3e:	ffffd097          	auipc	ra,0xffffd
    80005f42:	00a080e7          	jalr	10(ra) # 80002f48 <fetchaddr>
    80005f46:	02054a63          	bltz	a0,80005f7a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005f4a:	e4043783          	ld	a5,-448(s0)
    80005f4e:	c3b9                	beqz	a5,80005f94 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	c3a080e7          	jalr	-966(ra) # 80000b8a <kalloc>
    80005f58:	85aa                	mv	a1,a0
    80005f5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f5e:	cd11                	beqz	a0,80005f7a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f60:	6605                	lui	a2,0x1
    80005f62:	e4043503          	ld	a0,-448(s0)
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	034080e7          	jalr	52(ra) # 80002f9a <fetchstr>
    80005f6e:	00054663          	bltz	a0,80005f7a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005f72:	0905                	addi	s2,s2,1
    80005f74:	09a1                	addi	s3,s3,8
    80005f76:	fb491de3          	bne	s2,s4,80005f30 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f7a:	f5040913          	addi	s2,s0,-176
    80005f7e:	6088                	ld	a0,0(s1)
    80005f80:	c921                	beqz	a0,80005fd0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	a74080e7          	jalr	-1420(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8a:	04a1                	addi	s1,s1,8
    80005f8c:	ff2499e3          	bne	s1,s2,80005f7e <sys_exec+0xa4>
  return -1;
    80005f90:	557d                	li	a0,-1
    80005f92:	a081                	j	80005fd2 <sys_exec+0xf8>
      argv[i] = 0;
    80005f94:	0009079b          	sext.w	a5,s2
    80005f98:	078e                	slli	a5,a5,0x3
    80005f9a:	fd078793          	addi	a5,a5,-48
    80005f9e:	97a2                	add	a5,a5,s0
    80005fa0:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005fa4:	e5040593          	addi	a1,s0,-432
    80005fa8:	f5040513          	addi	a0,s0,-176
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	194080e7          	jalr	404(ra) # 80005140 <exec>
    80005fb4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb6:	f5040993          	addi	s3,s0,-176
    80005fba:	6088                	ld	a0,0(s1)
    80005fbc:	c901                	beqz	a0,80005fcc <sys_exec+0xf2>
    kfree(argv[i]);
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	a38080e7          	jalr	-1480(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc6:	04a1                	addi	s1,s1,8
    80005fc8:	ff3499e3          	bne	s1,s3,80005fba <sys_exec+0xe0>
  return ret;
    80005fcc:	854a                	mv	a0,s2
    80005fce:	a011                	j	80005fd2 <sys_exec+0xf8>
  return -1;
    80005fd0:	557d                	li	a0,-1
}
    80005fd2:	70fa                	ld	ra,440(sp)
    80005fd4:	745a                	ld	s0,432(sp)
    80005fd6:	74ba                	ld	s1,424(sp)
    80005fd8:	791a                	ld	s2,416(sp)
    80005fda:	69fa                	ld	s3,408(sp)
    80005fdc:	6a5a                	ld	s4,400(sp)
    80005fde:	6139                	addi	sp,sp,448
    80005fe0:	8082                	ret

0000000080005fe2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fe2:	7139                	addi	sp,sp,-64
    80005fe4:	fc06                	sd	ra,56(sp)
    80005fe6:	f822                	sd	s0,48(sp)
    80005fe8:	f426                	sd	s1,40(sp)
    80005fea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fec:	ffffc097          	auipc	ra,0xffffc
    80005ff0:	bca080e7          	jalr	-1078(ra) # 80001bb6 <myproc>
    80005ff4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ff6:	fd840593          	addi	a1,s0,-40
    80005ffa:	4501                	li	a0,0
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	00a080e7          	jalr	10(ra) # 80003006 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006004:	fc840593          	addi	a1,s0,-56
    80006008:	fd040513          	addi	a0,s0,-48
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	dea080e7          	jalr	-534(ra) # 80004df6 <pipealloc>
    return -1;
    80006014:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006016:	0c054463          	bltz	a0,800060de <sys_pipe+0xfc>
  fd0 = -1;
    8000601a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000601e:	fd043503          	ld	a0,-48(s0)
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	524080e7          	jalr	1316(ra) # 80005546 <fdalloc>
    8000602a:	fca42223          	sw	a0,-60(s0)
    8000602e:	08054b63          	bltz	a0,800060c4 <sys_pipe+0xe2>
    80006032:	fc843503          	ld	a0,-56(s0)
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	510080e7          	jalr	1296(ra) # 80005546 <fdalloc>
    8000603e:	fca42023          	sw	a0,-64(s0)
    80006042:	06054863          	bltz	a0,800060b2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006046:	4691                	li	a3,4
    80006048:	fc440613          	addi	a2,s0,-60
    8000604c:	fd843583          	ld	a1,-40(s0)
    80006050:	68a8                	ld	a0,80(s1)
    80006052:	ffffb097          	auipc	ra,0xffffb
    80006056:	730080e7          	jalr	1840(ra) # 80001782 <copyout>
    8000605a:	02054063          	bltz	a0,8000607a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000605e:	4691                	li	a3,4
    80006060:	fc040613          	addi	a2,s0,-64
    80006064:	fd843583          	ld	a1,-40(s0)
    80006068:	0591                	addi	a1,a1,4
    8000606a:	68a8                	ld	a0,80(s1)
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	716080e7          	jalr	1814(ra) # 80001782 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006074:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006076:	06055463          	bgez	a0,800060de <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000607a:	fc442783          	lw	a5,-60(s0)
    8000607e:	07e9                	addi	a5,a5,26
    80006080:	078e                	slli	a5,a5,0x3
    80006082:	97a6                	add	a5,a5,s1
    80006084:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006088:	fc042783          	lw	a5,-64(s0)
    8000608c:	07e9                	addi	a5,a5,26
    8000608e:	078e                	slli	a5,a5,0x3
    80006090:	94be                	add	s1,s1,a5
    80006092:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006096:	fd043503          	ld	a0,-48(s0)
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	a30080e7          	jalr	-1488(ra) # 80004aca <fileclose>
    fileclose(wf);
    800060a2:	fc843503          	ld	a0,-56(s0)
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	a24080e7          	jalr	-1500(ra) # 80004aca <fileclose>
    return -1;
    800060ae:	57fd                	li	a5,-1
    800060b0:	a03d                	j	800060de <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060b2:	fc442783          	lw	a5,-60(s0)
    800060b6:	0007c763          	bltz	a5,800060c4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060ba:	07e9                	addi	a5,a5,26
    800060bc:	078e                	slli	a5,a5,0x3
    800060be:	97a6                	add	a5,a5,s1
    800060c0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060c4:	fd043503          	ld	a0,-48(s0)
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	a02080e7          	jalr	-1534(ra) # 80004aca <fileclose>
    fileclose(wf);
    800060d0:	fc843503          	ld	a0,-56(s0)
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	9f6080e7          	jalr	-1546(ra) # 80004aca <fileclose>
    return -1;
    800060dc:	57fd                	li	a5,-1
}
    800060de:	853e                	mv	a0,a5
    800060e0:	70e2                	ld	ra,56(sp)
    800060e2:	7442                	ld	s0,48(sp)
    800060e4:	74a2                	ld	s1,40(sp)
    800060e6:	6121                	addi	sp,sp,64
    800060e8:	8082                	ret
    800060ea:	0000                	unimp
    800060ec:	0000                	unimp
	...

00000000800060f0 <kernelvec>:
    800060f0:	7111                	addi	sp,sp,-256
    800060f2:	e006                	sd	ra,0(sp)
    800060f4:	e40a                	sd	sp,8(sp)
    800060f6:	e80e                	sd	gp,16(sp)
    800060f8:	ec12                	sd	tp,24(sp)
    800060fa:	f016                	sd	t0,32(sp)
    800060fc:	f41a                	sd	t1,40(sp)
    800060fe:	f81e                	sd	t2,48(sp)
    80006100:	fc22                	sd	s0,56(sp)
    80006102:	e0a6                	sd	s1,64(sp)
    80006104:	e4aa                	sd	a0,72(sp)
    80006106:	e8ae                	sd	a1,80(sp)
    80006108:	ecb2                	sd	a2,88(sp)
    8000610a:	f0b6                	sd	a3,96(sp)
    8000610c:	f4ba                	sd	a4,104(sp)
    8000610e:	f8be                	sd	a5,112(sp)
    80006110:	fcc2                	sd	a6,120(sp)
    80006112:	e146                	sd	a7,128(sp)
    80006114:	e54a                	sd	s2,136(sp)
    80006116:	e94e                	sd	s3,144(sp)
    80006118:	ed52                	sd	s4,152(sp)
    8000611a:	f156                	sd	s5,160(sp)
    8000611c:	f55a                	sd	s6,168(sp)
    8000611e:	f95e                	sd	s7,176(sp)
    80006120:	fd62                	sd	s8,184(sp)
    80006122:	e1e6                	sd	s9,192(sp)
    80006124:	e5ea                	sd	s10,200(sp)
    80006126:	e9ee                	sd	s11,208(sp)
    80006128:	edf2                	sd	t3,216(sp)
    8000612a:	f1f6                	sd	t4,224(sp)
    8000612c:	f5fa                	sd	t5,232(sp)
    8000612e:	f9fe                	sd	t6,240(sp)
    80006130:	ce5fc0ef          	jal	ra,80002e14 <kerneltrap>
    80006134:	6082                	ld	ra,0(sp)
    80006136:	6122                	ld	sp,8(sp)
    80006138:	61c2                	ld	gp,16(sp)
    8000613a:	7282                	ld	t0,32(sp)
    8000613c:	7322                	ld	t1,40(sp)
    8000613e:	73c2                	ld	t2,48(sp)
    80006140:	7462                	ld	s0,56(sp)
    80006142:	6486                	ld	s1,64(sp)
    80006144:	6526                	ld	a0,72(sp)
    80006146:	65c6                	ld	a1,80(sp)
    80006148:	6666                	ld	a2,88(sp)
    8000614a:	7686                	ld	a3,96(sp)
    8000614c:	7726                	ld	a4,104(sp)
    8000614e:	77c6                	ld	a5,112(sp)
    80006150:	7866                	ld	a6,120(sp)
    80006152:	688a                	ld	a7,128(sp)
    80006154:	692a                	ld	s2,136(sp)
    80006156:	69ca                	ld	s3,144(sp)
    80006158:	6a6a                	ld	s4,152(sp)
    8000615a:	7a8a                	ld	s5,160(sp)
    8000615c:	7b2a                	ld	s6,168(sp)
    8000615e:	7bca                	ld	s7,176(sp)
    80006160:	7c6a                	ld	s8,184(sp)
    80006162:	6c8e                	ld	s9,192(sp)
    80006164:	6d2e                	ld	s10,200(sp)
    80006166:	6dce                	ld	s11,208(sp)
    80006168:	6e6e                	ld	t3,216(sp)
    8000616a:	7e8e                	ld	t4,224(sp)
    8000616c:	7f2e                	ld	t5,232(sp)
    8000616e:	7fce                	ld	t6,240(sp)
    80006170:	6111                	addi	sp,sp,256
    80006172:	10200073          	sret
    80006176:	00000013          	nop
    8000617a:	00000013          	nop
    8000617e:	0001                	nop

0000000080006180 <timervec>:
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	e10c                	sd	a1,0(a0)
    80006186:	e510                	sd	a2,8(a0)
    80006188:	e914                	sd	a3,16(a0)
    8000618a:	6d0c                	ld	a1,24(a0)
    8000618c:	7110                	ld	a2,32(a0)
    8000618e:	6194                	ld	a3,0(a1)
    80006190:	96b2                	add	a3,a3,a2
    80006192:	e194                	sd	a3,0(a1)
    80006194:	4589                	li	a1,2
    80006196:	14459073          	csrw	sip,a1
    8000619a:	6914                	ld	a3,16(a0)
    8000619c:	6510                	ld	a2,8(a0)
    8000619e:	610c                	ld	a1,0(a0)
    800061a0:	34051573          	csrrw	a0,mscratch,a0
    800061a4:	30200073          	mret
	...

00000000800061aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061aa:	1141                	addi	sp,sp,-16
    800061ac:	e422                	sd	s0,8(sp)
    800061ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061b0:	0c0007b7          	lui	a5,0xc000
    800061b4:	4705                	li	a4,1
    800061b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061b8:	c3d8                	sw	a4,4(a5)
}
    800061ba:	6422                	ld	s0,8(sp)
    800061bc:	0141                	addi	sp,sp,16
    800061be:	8082                	ret

00000000800061c0 <plicinithart>:

void
plicinithart(void)
{
    800061c0:	1141                	addi	sp,sp,-16
    800061c2:	e406                	sd	ra,8(sp)
    800061c4:	e022                	sd	s0,0(sp)
    800061c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	9c2080e7          	jalr	-1598(ra) # 80001b8a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061d0:	0085171b          	slliw	a4,a0,0x8
    800061d4:	0c0027b7          	lui	a5,0xc002
    800061d8:	97ba                	add	a5,a5,a4
    800061da:	40200713          	li	a4,1026
    800061de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061e2:	00d5151b          	slliw	a0,a0,0xd
    800061e6:	0c2017b7          	lui	a5,0xc201
    800061ea:	97aa                	add	a5,a5,a0
    800061ec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800061f0:	60a2                	ld	ra,8(sp)
    800061f2:	6402                	ld	s0,0(sp)
    800061f4:	0141                	addi	sp,sp,16
    800061f6:	8082                	ret

00000000800061f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061f8:	1141                	addi	sp,sp,-16
    800061fa:	e406                	sd	ra,8(sp)
    800061fc:	e022                	sd	s0,0(sp)
    800061fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006200:	ffffc097          	auipc	ra,0xffffc
    80006204:	98a080e7          	jalr	-1654(ra) # 80001b8a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006208:	00d5151b          	slliw	a0,a0,0xd
    8000620c:	0c2017b7          	lui	a5,0xc201
    80006210:	97aa                	add	a5,a5,a0
  return irq;
}
    80006212:	43c8                	lw	a0,4(a5)
    80006214:	60a2                	ld	ra,8(sp)
    80006216:	6402                	ld	s0,0(sp)
    80006218:	0141                	addi	sp,sp,16
    8000621a:	8082                	ret

000000008000621c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000621c:	1101                	addi	sp,sp,-32
    8000621e:	ec06                	sd	ra,24(sp)
    80006220:	e822                	sd	s0,16(sp)
    80006222:	e426                	sd	s1,8(sp)
    80006224:	1000                	addi	s0,sp,32
    80006226:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	962080e7          	jalr	-1694(ra) # 80001b8a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006230:	00d5151b          	slliw	a0,a0,0xd
    80006234:	0c2017b7          	lui	a5,0xc201
    80006238:	97aa                	add	a5,a5,a0
    8000623a:	c3c4                	sw	s1,4(a5)
}
    8000623c:	60e2                	ld	ra,24(sp)
    8000623e:	6442                	ld	s0,16(sp)
    80006240:	64a2                	ld	s1,8(sp)
    80006242:	6105                	addi	sp,sp,32
    80006244:	8082                	ret

0000000080006246 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006246:	1141                	addi	sp,sp,-16
    80006248:	e406                	sd	ra,8(sp)
    8000624a:	e022                	sd	s0,0(sp)
    8000624c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000624e:	479d                	li	a5,7
    80006250:	04a7cc63          	blt	a5,a0,800062a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006254:	00024797          	auipc	a5,0x24
    80006258:	bac78793          	addi	a5,a5,-1108 # 80029e00 <disk>
    8000625c:	97aa                	add	a5,a5,a0
    8000625e:	0187c783          	lbu	a5,24(a5)
    80006262:	ebb9                	bnez	a5,800062b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006264:	00451693          	slli	a3,a0,0x4
    80006268:	00024797          	auipc	a5,0x24
    8000626c:	b9878793          	addi	a5,a5,-1128 # 80029e00 <disk>
    80006270:	6398                	ld	a4,0(a5)
    80006272:	9736                	add	a4,a4,a3
    80006274:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006278:	6398                	ld	a4,0(a5)
    8000627a:	9736                	add	a4,a4,a3
    8000627c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006280:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006284:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	4705                	li	a4,1
    8000628c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006290:	00024517          	auipc	a0,0x24
    80006294:	b8850513          	addi	a0,a0,-1144 # 80029e18 <disk+0x18>
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	0ea080e7          	jalr	234(ra) # 80002382 <wakeup>
}
    800062a0:	60a2                	ld	ra,8(sp)
    800062a2:	6402                	ld	s0,0(sp)
    800062a4:	0141                	addi	sp,sp,16
    800062a6:	8082                	ret
    panic("free_desc 1");
    800062a8:	00002517          	auipc	a0,0x2
    800062ac:	65050513          	addi	a0,a0,1616 # 800088f8 <syscalls+0x338>
    800062b0:	ffffa097          	auipc	ra,0xffffa
    800062b4:	28c080e7          	jalr	652(ra) # 8000053c <panic>
    panic("free_desc 2");
    800062b8:	00002517          	auipc	a0,0x2
    800062bc:	65050513          	addi	a0,a0,1616 # 80008908 <syscalls+0x348>
    800062c0:	ffffa097          	auipc	ra,0xffffa
    800062c4:	27c080e7          	jalr	636(ra) # 8000053c <panic>

00000000800062c8 <virtio_disk_init>:
{
    800062c8:	1101                	addi	sp,sp,-32
    800062ca:	ec06                	sd	ra,24(sp)
    800062cc:	e822                	sd	s0,16(sp)
    800062ce:	e426                	sd	s1,8(sp)
    800062d0:	e04a                	sd	s2,0(sp)
    800062d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062d4:	00002597          	auipc	a1,0x2
    800062d8:	64458593          	addi	a1,a1,1604 # 80008918 <syscalls+0x358>
    800062dc:	00024517          	auipc	a0,0x24
    800062e0:	c4c50513          	addi	a0,a0,-948 # 80029f28 <disk+0x128>
    800062e4:	ffffb097          	auipc	ra,0xffffb
    800062e8:	952080e7          	jalr	-1710(ra) # 80000c36 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062ec:	100017b7          	lui	a5,0x10001
    800062f0:	4398                	lw	a4,0(a5)
    800062f2:	2701                	sext.w	a4,a4
    800062f4:	747277b7          	lui	a5,0x74727
    800062f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062fc:	14f71b63          	bne	a4,a5,80006452 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006300:	100017b7          	lui	a5,0x10001
    80006304:	43dc                	lw	a5,4(a5)
    80006306:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006308:	4709                	li	a4,2
    8000630a:	14e79463          	bne	a5,a4,80006452 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000630e:	100017b7          	lui	a5,0x10001
    80006312:	479c                	lw	a5,8(a5)
    80006314:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006316:	12e79e63          	bne	a5,a4,80006452 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000631a:	100017b7          	lui	a5,0x10001
    8000631e:	47d8                	lw	a4,12(a5)
    80006320:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006322:	554d47b7          	lui	a5,0x554d4
    80006326:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000632a:	12f71463          	bne	a4,a5,80006452 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000632e:	100017b7          	lui	a5,0x10001
    80006332:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006336:	4705                	li	a4,1
    80006338:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000633a:	470d                	li	a4,3
    8000633c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000633e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006340:	c7ffe6b7          	lui	a3,0xc7ffe
    80006344:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd481f>
    80006348:	8f75                	and	a4,a4,a3
    8000634a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000634c:	472d                	li	a4,11
    8000634e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006350:	5bbc                	lw	a5,112(a5)
    80006352:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006356:	8ba1                	andi	a5,a5,8
    80006358:	10078563          	beqz	a5,80006462 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000635c:	100017b7          	lui	a5,0x10001
    80006360:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006364:	43fc                	lw	a5,68(a5)
    80006366:	2781                	sext.w	a5,a5
    80006368:	10079563          	bnez	a5,80006472 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000636c:	100017b7          	lui	a5,0x10001
    80006370:	5bdc                	lw	a5,52(a5)
    80006372:	2781                	sext.w	a5,a5
  if(max == 0)
    80006374:	10078763          	beqz	a5,80006482 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006378:	471d                	li	a4,7
    8000637a:	10f77c63          	bgeu	a4,a5,80006492 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000637e:	ffffb097          	auipc	ra,0xffffb
    80006382:	80c080e7          	jalr	-2036(ra) # 80000b8a <kalloc>
    80006386:	00024497          	auipc	s1,0x24
    8000638a:	a7a48493          	addi	s1,s1,-1414 # 80029e00 <disk>
    8000638e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	7fa080e7          	jalr	2042(ra) # 80000b8a <kalloc>
    80006398:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	7f0080e7          	jalr	2032(ra) # 80000b8a <kalloc>
    800063a2:	87aa                	mv	a5,a0
    800063a4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063a6:	6088                	ld	a0,0(s1)
    800063a8:	cd6d                	beqz	a0,800064a2 <virtio_disk_init+0x1da>
    800063aa:	00024717          	auipc	a4,0x24
    800063ae:	a5e73703          	ld	a4,-1442(a4) # 80029e08 <disk+0x8>
    800063b2:	cb65                	beqz	a4,800064a2 <virtio_disk_init+0x1da>
    800063b4:	c7fd                	beqz	a5,800064a2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063b6:	6605                	lui	a2,0x1
    800063b8:	4581                	li	a1,0
    800063ba:	ffffb097          	auipc	ra,0xffffb
    800063be:	a08080e7          	jalr	-1528(ra) # 80000dc2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063c2:	00024497          	auipc	s1,0x24
    800063c6:	a3e48493          	addi	s1,s1,-1474 # 80029e00 <disk>
    800063ca:	6605                	lui	a2,0x1
    800063cc:	4581                	li	a1,0
    800063ce:	6488                	ld	a0,8(s1)
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	9f2080e7          	jalr	-1550(ra) # 80000dc2 <memset>
  memset(disk.used, 0, PGSIZE);
    800063d8:	6605                	lui	a2,0x1
    800063da:	4581                	li	a1,0
    800063dc:	6888                	ld	a0,16(s1)
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	9e4080e7          	jalr	-1564(ra) # 80000dc2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063e6:	100017b7          	lui	a5,0x10001
    800063ea:	4721                	li	a4,8
    800063ec:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063ee:	4098                	lw	a4,0(s1)
    800063f0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800063f4:	40d8                	lw	a4,4(s1)
    800063f6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800063fa:	6498                	ld	a4,8(s1)
    800063fc:	0007069b          	sext.w	a3,a4
    80006400:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006404:	9701                	srai	a4,a4,0x20
    80006406:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000640a:	6898                	ld	a4,16(s1)
    8000640c:	0007069b          	sext.w	a3,a4
    80006410:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006414:	9701                	srai	a4,a4,0x20
    80006416:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000641a:	4705                	li	a4,1
    8000641c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000641e:	00e48c23          	sb	a4,24(s1)
    80006422:	00e48ca3          	sb	a4,25(s1)
    80006426:	00e48d23          	sb	a4,26(s1)
    8000642a:	00e48da3          	sb	a4,27(s1)
    8000642e:	00e48e23          	sb	a4,28(s1)
    80006432:	00e48ea3          	sb	a4,29(s1)
    80006436:	00e48f23          	sb	a4,30(s1)
    8000643a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000643e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006442:	0727a823          	sw	s2,112(a5)
}
    80006446:	60e2                	ld	ra,24(sp)
    80006448:	6442                	ld	s0,16(sp)
    8000644a:	64a2                	ld	s1,8(sp)
    8000644c:	6902                	ld	s2,0(sp)
    8000644e:	6105                	addi	sp,sp,32
    80006450:	8082                	ret
    panic("could not find virtio disk");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	4d650513          	addi	a0,a0,1238 # 80008928 <syscalls+0x368>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e2080e7          	jalr	226(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	4e650513          	addi	a0,a0,1254 # 80008948 <syscalls+0x388>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d2080e7          	jalr	210(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	4f650513          	addi	a0,a0,1270 # 80008968 <syscalls+0x3a8>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c2080e7          	jalr	194(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	50650513          	addi	a0,a0,1286 # 80008988 <syscalls+0x3c8>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b2080e7          	jalr	178(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	51650513          	addi	a0,a0,1302 # 800089a8 <syscalls+0x3e8>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a2080e7          	jalr	162(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	52650513          	addi	a0,a0,1318 # 800089c8 <syscalls+0x408>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	092080e7          	jalr	146(ra) # 8000053c <panic>

00000000800064b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064b2:	7159                	addi	sp,sp,-112
    800064b4:	f486                	sd	ra,104(sp)
    800064b6:	f0a2                	sd	s0,96(sp)
    800064b8:	eca6                	sd	s1,88(sp)
    800064ba:	e8ca                	sd	s2,80(sp)
    800064bc:	e4ce                	sd	s3,72(sp)
    800064be:	e0d2                	sd	s4,64(sp)
    800064c0:	fc56                	sd	s5,56(sp)
    800064c2:	f85a                	sd	s6,48(sp)
    800064c4:	f45e                	sd	s7,40(sp)
    800064c6:	f062                	sd	s8,32(sp)
    800064c8:	ec66                	sd	s9,24(sp)
    800064ca:	e86a                	sd	s10,16(sp)
    800064cc:	1880                	addi	s0,sp,112
    800064ce:	8a2a                	mv	s4,a0
    800064d0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064d2:	00c52c83          	lw	s9,12(a0)
    800064d6:	001c9c9b          	slliw	s9,s9,0x1
    800064da:	1c82                	slli	s9,s9,0x20
    800064dc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064e0:	00024517          	auipc	a0,0x24
    800064e4:	a4850513          	addi	a0,a0,-1464 # 80029f28 <disk+0x128>
    800064e8:	ffffa097          	auipc	ra,0xffffa
    800064ec:	7de080e7          	jalr	2014(ra) # 80000cc6 <acquire>
  for(int i = 0; i < 3; i++){
    800064f0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800064f2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064f4:	00024b17          	auipc	s6,0x24
    800064f8:	90cb0b13          	addi	s6,s6,-1780 # 80029e00 <disk>
  for(int i = 0; i < 3; i++){
    800064fc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064fe:	00024c17          	auipc	s8,0x24
    80006502:	a2ac0c13          	addi	s8,s8,-1494 # 80029f28 <disk+0x128>
    80006506:	a095                	j	8000656a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006508:	00fb0733          	add	a4,s6,a5
    8000650c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006510:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006512:	0207c563          	bltz	a5,8000653c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006516:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006518:	0591                	addi	a1,a1,4
    8000651a:	05560d63          	beq	a2,s5,80006574 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000651e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006520:	00024717          	auipc	a4,0x24
    80006524:	8e070713          	addi	a4,a4,-1824 # 80029e00 <disk>
    80006528:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000652a:	01874683          	lbu	a3,24(a4)
    8000652e:	fee9                	bnez	a3,80006508 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006530:	2785                	addiw	a5,a5,1
    80006532:	0705                	addi	a4,a4,1
    80006534:	fe979be3          	bne	a5,s1,8000652a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006538:	57fd                	li	a5,-1
    8000653a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000653c:	00c05e63          	blez	a2,80006558 <virtio_disk_rw+0xa6>
    80006540:	060a                	slli	a2,a2,0x2
    80006542:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006546:	0009a503          	lw	a0,0(s3)
    8000654a:	00000097          	auipc	ra,0x0
    8000654e:	cfc080e7          	jalr	-772(ra) # 80006246 <free_desc>
      for(int j = 0; j < i; j++)
    80006552:	0991                	addi	s3,s3,4
    80006554:	ffa999e3          	bne	s3,s10,80006546 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006558:	85e2                	mv	a1,s8
    8000655a:	00024517          	auipc	a0,0x24
    8000655e:	8be50513          	addi	a0,a0,-1858 # 80029e18 <disk+0x18>
    80006562:	ffffc097          	auipc	ra,0xffffc
    80006566:	dbc080e7          	jalr	-580(ra) # 8000231e <sleep>
  for(int i = 0; i < 3; i++){
    8000656a:	f9040993          	addi	s3,s0,-112
{
    8000656e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006570:	864a                	mv	a2,s2
    80006572:	b775                	j	8000651e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006574:	f9042503          	lw	a0,-112(s0)
    80006578:	00a50713          	addi	a4,a0,10
    8000657c:	0712                	slli	a4,a4,0x4

  if(write)
    8000657e:	00024797          	auipc	a5,0x24
    80006582:	88278793          	addi	a5,a5,-1918 # 80029e00 <disk>
    80006586:	00e786b3          	add	a3,a5,a4
    8000658a:	01703633          	snez	a2,s7
    8000658e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006590:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006594:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006598:	f6070613          	addi	a2,a4,-160
    8000659c:	6394                	ld	a3,0(a5)
    8000659e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065a0:	00870593          	addi	a1,a4,8
    800065a4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065a6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065a8:	0007b803          	ld	a6,0(a5)
    800065ac:	9642                	add	a2,a2,a6
    800065ae:	46c1                	li	a3,16
    800065b0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065b2:	4585                	li	a1,1
    800065b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065b8:	f9442683          	lw	a3,-108(s0)
    800065bc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065c0:	0692                	slli	a3,a3,0x4
    800065c2:	9836                	add	a6,a6,a3
    800065c4:	058a0613          	addi	a2,s4,88
    800065c8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800065cc:	0007b803          	ld	a6,0(a5)
    800065d0:	96c2                	add	a3,a3,a6
    800065d2:	40000613          	li	a2,1024
    800065d6:	c690                	sw	a2,8(a3)
  if(write)
    800065d8:	001bb613          	seqz	a2,s7
    800065dc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065e0:	00166613          	ori	a2,a2,1
    800065e4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065e8:	f9842603          	lw	a2,-104(s0)
    800065ec:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065f0:	00250693          	addi	a3,a0,2
    800065f4:	0692                	slli	a3,a3,0x4
    800065f6:	96be                	add	a3,a3,a5
    800065f8:	58fd                	li	a7,-1
    800065fa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065fe:	0612                	slli	a2,a2,0x4
    80006600:	9832                	add	a6,a6,a2
    80006602:	f9070713          	addi	a4,a4,-112
    80006606:	973e                	add	a4,a4,a5
    80006608:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000660c:	6398                	ld	a4,0(a5)
    8000660e:	9732                	add	a4,a4,a2
    80006610:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006612:	4609                	li	a2,2
    80006614:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006618:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000661c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006620:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006624:	6794                	ld	a3,8(a5)
    80006626:	0026d703          	lhu	a4,2(a3)
    8000662a:	8b1d                	andi	a4,a4,7
    8000662c:	0706                	slli	a4,a4,0x1
    8000662e:	96ba                	add	a3,a3,a4
    80006630:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006634:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006638:	6798                	ld	a4,8(a5)
    8000663a:	00275783          	lhu	a5,2(a4)
    8000663e:	2785                	addiw	a5,a5,1
    80006640:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006644:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006648:	100017b7          	lui	a5,0x10001
    8000664c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006650:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006654:	00024917          	auipc	s2,0x24
    80006658:	8d490913          	addi	s2,s2,-1836 # 80029f28 <disk+0x128>
  while(b->disk == 1) {
    8000665c:	4485                	li	s1,1
    8000665e:	00b79c63          	bne	a5,a1,80006676 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006662:	85ca                	mv	a1,s2
    80006664:	8552                	mv	a0,s4
    80006666:	ffffc097          	auipc	ra,0xffffc
    8000666a:	cb8080e7          	jalr	-840(ra) # 8000231e <sleep>
  while(b->disk == 1) {
    8000666e:	004a2783          	lw	a5,4(s4)
    80006672:	fe9788e3          	beq	a5,s1,80006662 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006676:	f9042903          	lw	s2,-112(s0)
    8000667a:	00290713          	addi	a4,s2,2
    8000667e:	0712                	slli	a4,a4,0x4
    80006680:	00023797          	auipc	a5,0x23
    80006684:	78078793          	addi	a5,a5,1920 # 80029e00 <disk>
    80006688:	97ba                	add	a5,a5,a4
    8000668a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000668e:	00023997          	auipc	s3,0x23
    80006692:	77298993          	addi	s3,s3,1906 # 80029e00 <disk>
    80006696:	00491713          	slli	a4,s2,0x4
    8000669a:	0009b783          	ld	a5,0(s3)
    8000669e:	97ba                	add	a5,a5,a4
    800066a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066a4:	854a                	mv	a0,s2
    800066a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066aa:	00000097          	auipc	ra,0x0
    800066ae:	b9c080e7          	jalr	-1124(ra) # 80006246 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066b2:	8885                	andi	s1,s1,1
    800066b4:	f0ed                	bnez	s1,80006696 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066b6:	00024517          	auipc	a0,0x24
    800066ba:	87250513          	addi	a0,a0,-1934 # 80029f28 <disk+0x128>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	6bc080e7          	jalr	1724(ra) # 80000d7a <release>
}
    800066c6:	70a6                	ld	ra,104(sp)
    800066c8:	7406                	ld	s0,96(sp)
    800066ca:	64e6                	ld	s1,88(sp)
    800066cc:	6946                	ld	s2,80(sp)
    800066ce:	69a6                	ld	s3,72(sp)
    800066d0:	6a06                	ld	s4,64(sp)
    800066d2:	7ae2                	ld	s5,56(sp)
    800066d4:	7b42                	ld	s6,48(sp)
    800066d6:	7ba2                	ld	s7,40(sp)
    800066d8:	7c02                	ld	s8,32(sp)
    800066da:	6ce2                	ld	s9,24(sp)
    800066dc:	6d42                	ld	s10,16(sp)
    800066de:	6165                	addi	sp,sp,112
    800066e0:	8082                	ret

00000000800066e2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066e2:	1101                	addi	sp,sp,-32
    800066e4:	ec06                	sd	ra,24(sp)
    800066e6:	e822                	sd	s0,16(sp)
    800066e8:	e426                	sd	s1,8(sp)
    800066ea:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066ec:	00023497          	auipc	s1,0x23
    800066f0:	71448493          	addi	s1,s1,1812 # 80029e00 <disk>
    800066f4:	00024517          	auipc	a0,0x24
    800066f8:	83450513          	addi	a0,a0,-1996 # 80029f28 <disk+0x128>
    800066fc:	ffffa097          	auipc	ra,0xffffa
    80006700:	5ca080e7          	jalr	1482(ra) # 80000cc6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006704:	10001737          	lui	a4,0x10001
    80006708:	533c                	lw	a5,96(a4)
    8000670a:	8b8d                	andi	a5,a5,3
    8000670c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000670e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006712:	689c                	ld	a5,16(s1)
    80006714:	0204d703          	lhu	a4,32(s1)
    80006718:	0027d783          	lhu	a5,2(a5)
    8000671c:	04f70863          	beq	a4,a5,8000676c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006720:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006724:	6898                	ld	a4,16(s1)
    80006726:	0204d783          	lhu	a5,32(s1)
    8000672a:	8b9d                	andi	a5,a5,7
    8000672c:	078e                	slli	a5,a5,0x3
    8000672e:	97ba                	add	a5,a5,a4
    80006730:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006732:	00278713          	addi	a4,a5,2
    80006736:	0712                	slli	a4,a4,0x4
    80006738:	9726                	add	a4,a4,s1
    8000673a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000673e:	e721                	bnez	a4,80006786 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006740:	0789                	addi	a5,a5,2
    80006742:	0792                	slli	a5,a5,0x4
    80006744:	97a6                	add	a5,a5,s1
    80006746:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006748:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000674c:	ffffc097          	auipc	ra,0xffffc
    80006750:	c36080e7          	jalr	-970(ra) # 80002382 <wakeup>

    disk.used_idx += 1;
    80006754:	0204d783          	lhu	a5,32(s1)
    80006758:	2785                	addiw	a5,a5,1
    8000675a:	17c2                	slli	a5,a5,0x30
    8000675c:	93c1                	srli	a5,a5,0x30
    8000675e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006762:	6898                	ld	a4,16(s1)
    80006764:	00275703          	lhu	a4,2(a4)
    80006768:	faf71ce3          	bne	a4,a5,80006720 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000676c:	00023517          	auipc	a0,0x23
    80006770:	7bc50513          	addi	a0,a0,1980 # 80029f28 <disk+0x128>
    80006774:	ffffa097          	auipc	ra,0xffffa
    80006778:	606080e7          	jalr	1542(ra) # 80000d7a <release>
}
    8000677c:	60e2                	ld	ra,24(sp)
    8000677e:	6442                	ld	s0,16(sp)
    80006780:	64a2                	ld	s1,8(sp)
    80006782:	6105                	addi	sp,sp,32
    80006784:	8082                	ret
      panic("virtio_disk_intr status");
    80006786:	00002517          	auipc	a0,0x2
    8000678a:	25a50513          	addi	a0,a0,602 # 800089e0 <syscalls+0x420>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	dae080e7          	jalr	-594(ra) # 8000053c <panic>
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
