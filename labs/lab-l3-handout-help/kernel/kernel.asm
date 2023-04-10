
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c5010113          	addi	sp,sp,-944 # 80008c50 <stack0>
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
    asm volatile("csrr %0, mhartid"
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
    80000054:	ac070713          	addi	a4,a4,-1344 # 80008b10 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void
w_mscratch(uint64 x)
{
    asm volatile("csrw mscratch, %0"
    8000005e:	34071073          	csrw	mscratch,a4
    asm volatile("csrw mtvec, %0"
    80000062:	00006797          	auipc	a5,0x6
    80000066:	23e78793          	addi	a5,a5,574 # 800062a0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
    asm volatile("csrr %0, mstatus"
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
    asm volatile("csrw mstatus, %0"
    80000076:	30079073          	csrw	mstatus,a5
    asm volatile("csrr %0, mie"
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
    asm volatile("csrw mie, %0"
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
    asm volatile("csrr %0, mstatus"
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fecc87f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
    asm volatile("csrw mstatus, %0"
    800000a8:	30079073          	csrw	mstatus,a5
    asm volatile("csrw mepc, %0"
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e8278793          	addi	a5,a5,-382 # 80000f2e <main>
    800000b4:	34179073          	csrw	mepc,a5
    asm volatile("csrw satp, %0"
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
    asm volatile("csrw medeleg, %0"
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
    asm volatile("csrw mideleg, %0"
    800000c6:	30379073          	csrw	mideleg,a5
    asm volatile("csrr %0, sie"
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
    asm volatile("csrw sie, %0"
    800000d2:	10479073          	csrw	sie,a5
    asm volatile("csrw pmpaddr0, %0"
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
    asm volatile("csrw pmpcfg0, %0"
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
    asm volatile("csrr %0, mhartid"
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void
w_tp(uint64 x)
{
    asm volatile("mv tp, %0"
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
    8000012e:	766080e7          	jalr	1894(ra) # 80002890 <either_copyin>
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
    80000188:	acc50513          	addi	a0,a0,-1332 # 80010c50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b02080e7          	jalr	-1278(ra) # 80000c8e <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	abc48493          	addi	s1,s1,-1348 # 80010c50 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	b4c90913          	addi	s2,s2,-1204 # 80010ce8 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	b16080e7          	jalr	-1258(ra) # 80001cca <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	51e080e7          	jalr	1310(ra) # 800026da <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	268080e7          	jalr	616(ra) # 80002432 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	a7270713          	addi	a4,a4,-1422 # 80010c50 <cons>
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
    80000214:	62a080e7          	jalr	1578(ra) # 8000283a <either_copyout>
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
    8000022c:	a2850513          	addi	a0,a0,-1496 # 80010c50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b12080e7          	jalr	-1262(ra) # 80000d42 <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	a1250513          	addi	a0,a0,-1518 # 80010c50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	afc080e7          	jalr	-1284(ra) # 80000d42 <release>
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
    80000272:	a6f72d23          	sw	a5,-1414(a4) # 80010ce8 <cons+0x98>
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
    800002cc:	98850513          	addi	a0,a0,-1656 # 80010c50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	9be080e7          	jalr	-1602(ra) # 80000c8e <acquire>

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
    800002f2:	5f8080e7          	jalr	1528(ra) # 800028e6 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	95a50513          	addi	a0,a0,-1702 # 80010c50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a44080e7          	jalr	-1468(ra) # 80000d42 <release>
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
    8000031e:	93670713          	addi	a4,a4,-1738 # 80010c50 <cons>
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
    80000348:	90c78793          	addi	a5,a5,-1780 # 80010c50 <cons>
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
    80000376:	9767a783          	lw	a5,-1674(a5) # 80010ce8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	8ca70713          	addi	a4,a4,-1846 # 80010c50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	8ba48493          	addi	s1,s1,-1862 # 80010c50 <cons>
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
    800003d6:	87e70713          	addi	a4,a4,-1922 # 80010c50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	90f72423          	sw	a5,-1784(a4) # 80010cf0 <cons+0xa0>
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
    80000412:	84278793          	addi	a5,a5,-1982 # 80010c50 <cons>
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
    80000436:	8ac7ad23          	sw	a2,-1862(a5) # 80010cec <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	8ae50513          	addi	a0,a0,-1874 # 80010ce8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	054080e7          	jalr	84(ra) # 80002496 <wakeup>
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
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.0+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	7f450513          	addi	a0,a0,2036 # 80010c50 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	79a080e7          	jalr	1946(ra) # 80000bfe <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00131797          	auipc	a5,0x131
    80000478:	97478793          	addi	a5,a5,-1676 # 80130de8 <devsw>
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
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
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
    8000054c:	7c07a423          	sw	zero,1992(a5) # 80010d10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ad850513          	addi	a0,a0,-1320 # 80008028 <__func__.0+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	f9650513          	addi	a0,a0,-106 # 80008500 <states.0+0x80>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	54f72223          	sw	a5,1348(a4) # 80008ac0 <panicked>
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
    800005bc:	758dad83          	lw	s11,1880(s11) # 80010d10 <pr+0x18>
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
    800005e8:	a6cb0b13          	addi	s6,s6,-1428 # 80008050 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	70250513          	addi	a0,a0,1794 # 80010cf8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	690080e7          	jalr	1680(ra) # 80000c8e <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a3050513          	addi	a0,a0,-1488 # 80008038 <__func__.0+0x28>
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
    80000706:	92e48493          	addi	s1,s1,-1746 # 80008030 <__func__.0+0x20>
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
    80000758:	5a450513          	addi	a0,a0,1444 # 80010cf8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	5e6080e7          	jalr	1510(ra) # 80000d42 <release>
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
    80000774:	58848493          	addi	s1,s1,1416 # 80010cf8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8d058593          	addi	a1,a1,-1840 # 80008048 <__func__.0+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	47c080e7          	jalr	1148(ra) # 80000bfe <initlock>
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
    800007cc:	8a058593          	addi	a1,a1,-1888 # 80008068 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	54850513          	addi	a0,a0,1352 # 80010d18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	426080e7          	jalr	1062(ra) # 80000bfe <initlock>
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
    800007f8:	44e080e7          	jalr	1102(ra) # 80000c42 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	2c47a783          	lw	a5,708(a5) # 80008ac0 <panicked>
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
    80000826:	4c0080e7          	jalr	1216(ra) # 80000ce2 <pop_off>
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
    80000838:	2947b783          	ld	a5,660(a5) # 80008ac8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	29473703          	ld	a4,660(a4) # 80008ad0 <uart_tx_w>
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
    80000862:	4baa0a13          	addi	s4,s4,1210 # 80010d18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	26248493          	addi	s1,s1,610 # 80008ac8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	26298993          	addi	s3,s3,610 # 80008ad0 <uart_tx_w>
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
    80000894:	c06080e7          	jalr	-1018(ra) # 80002496 <wakeup>
    
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
    800008d0:	44c50513          	addi	a0,a0,1100 # 80010d18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	3ba080e7          	jalr	954(ra) # 80000c8e <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	1e47a783          	lw	a5,484(a5) # 80008ac0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	1ea73703          	ld	a4,490(a4) # 80008ad0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1da7b783          	ld	a5,474(a5) # 80008ac8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	41e98993          	addi	s3,s3,1054 # 80010d18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	1c648493          	addi	s1,s1,454 # 80008ac8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	1c690913          	addi	s2,s2,454 # 80008ad0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	b18080e7          	jalr	-1256(ra) # 80002432 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	3e848493          	addi	s1,s1,1000 # 80010d18 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	18e7b623          	sd	a4,396(a5) # 80008ad0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	3ec080e7          	jalr	1004(ra) # 80000d42 <release>
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
    800009ba:	36248493          	addi	s1,s1,866 # 80010d18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	2ce080e7          	jalr	718(ra) # 80000c8e <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	370080e7          	jalr	880(ra) # 80000d42 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
    
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	efa5                	bnez	a5,80000a6c <kfree+0x88>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00131797          	auipc	a5,0x131
    800009fc:	58878793          	addi	a5,a5,1416 # 80131f80 <end>
    80000a00:	06f56663          	bltu	a0,a5,80000a6c <kfree+0x88>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	06f57263          	bgeu	a0,a5,80000a6c <kfree+0x88>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	37a080e7          	jalr	890(ra) # 80000d8a <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	33890913          	addi	s2,s2,824 # 80010d50 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	26c080e7          	jalr	620(ra) # 80000c8e <acquire>
    r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a34:	00008717          	auipc	a4,0x8
    80000a38:	0a470713          	addi	a4,a4,164 # 80008ad8 <FREE_PAGES>
    80000a3c:	631c                	ld	a5,0(a4)
    80000a3e:	0785                	addi	a5,a5,1
    80000a40:	e31c                	sd	a5,0(a4)
    if (MAX_PAGES != 0)
    80000a42:	00008717          	auipc	a4,0x8
    80000a46:	09e73703          	ld	a4,158(a4) # 80008ae0 <MAX_PAGES>
    80000a4a:	c319                	beqz	a4,80000a50 <kfree+0x6c>
        assert(FREE_PAGES <= MAX_PAGES);
    80000a4c:	02f76863          	bltu	a4,a5,80000a7c <kfree+0x98>
    release(&kmem.lock);
    80000a50:	00010517          	auipc	a0,0x10
    80000a54:	30050513          	addi	a0,a0,768 # 80010d50 <kmem>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	2ea080e7          	jalr	746(ra) # 80000d42 <release>
}
    80000a60:	60e2                	ld	ra,24(sp)
    80000a62:	6442                	ld	s0,16(sp)
    80000a64:	64a2                	ld	s1,8(sp)
    80000a66:	6902                	ld	s2,0(sp)
    80000a68:	6105                	addi	sp,sp,32
    80000a6a:	8082                	ret
        panic("kfree");
    80000a6c:	00007517          	auipc	a0,0x7
    80000a70:	60450513          	addi	a0,a0,1540 # 80008070 <digits+0x20>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	ac8080e7          	jalr	-1336(ra) # 8000053c <panic>
        assert(FREE_PAGES <= MAX_PAGES);
    80000a7c:	04600693          	li	a3,70
    80000a80:	00007617          	auipc	a2,0x7
    80000a84:	58860613          	addi	a2,a2,1416 # 80008008 <__func__.1>
    80000a88:	00007597          	auipc	a1,0x7
    80000a8c:	5f058593          	addi	a1,a1,1520 # 80008078 <digits+0x28>
    80000a90:	00007517          	auipc	a0,0x7
    80000a94:	5f850513          	addi	a0,a0,1528 # 80008088 <digits+0x38>
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	aee080e7          	jalr	-1298(ra) # 80000586 <printf>
    80000aa0:	00007517          	auipc	a0,0x7
    80000aa4:	5f850513          	addi	a0,a0,1528 # 80008098 <digits+0x48>
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	a94080e7          	jalr	-1388(ra) # 8000053c <panic>

0000000080000ab0 <freerange>:
{
    80000ab0:	7179                	addi	sp,sp,-48
    80000ab2:	f406                	sd	ra,40(sp)
    80000ab4:	f022                	sd	s0,32(sp)
    80000ab6:	ec26                	sd	s1,24(sp)
    80000ab8:	e84a                	sd	s2,16(sp)
    80000aba:	e44e                	sd	s3,8(sp)
    80000abc:	e052                	sd	s4,0(sp)
    80000abe:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ac0:	6785                	lui	a5,0x1
    80000ac2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ac6:	00e504b3          	add	s1,a0,a4
    80000aca:	777d                	lui	a4,0xfffff
    80000acc:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ace:	94be                	add	s1,s1,a5
    80000ad0:	0095ee63          	bltu	a1,s1,80000aec <freerange+0x3c>
    80000ad4:	892e                	mv	s2,a1
        kfree(p);
    80000ad6:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ad8:	6985                	lui	s3,0x1
        kfree(p);
    80000ada:	01448533          	add	a0,s1,s4
    80000ade:	00000097          	auipc	ra,0x0
    80000ae2:	f06080e7          	jalr	-250(ra) # 800009e4 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae6:	94ce                	add	s1,s1,s3
    80000ae8:	fe9979e3          	bgeu	s2,s1,80000ada <freerange+0x2a>
}
    80000aec:	70a2                	ld	ra,40(sp)
    80000aee:	7402                	ld	s0,32(sp)
    80000af0:	64e2                	ld	s1,24(sp)
    80000af2:	6942                	ld	s2,16(sp)
    80000af4:	69a2                	ld	s3,8(sp)
    80000af6:	6a02                	ld	s4,0(sp)
    80000af8:	6145                	addi	sp,sp,48
    80000afa:	8082                	ret

0000000080000afc <kinit>:
{
    80000afc:	1141                	addi	sp,sp,-16
    80000afe:	e406                	sd	ra,8(sp)
    80000b00:	e022                	sd	s0,0(sp)
    80000b02:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b04:	00007597          	auipc	a1,0x7
    80000b08:	5a458593          	addi	a1,a1,1444 # 800080a8 <digits+0x58>
    80000b0c:	00010517          	auipc	a0,0x10
    80000b10:	24450513          	addi	a0,a0,580 # 80010d50 <kmem>
    80000b14:	00000097          	auipc	ra,0x0
    80000b18:	0ea080e7          	jalr	234(ra) # 80000bfe <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b1c:	45c5                	li	a1,17
    80000b1e:	05ee                	slli	a1,a1,0x1b
    80000b20:	00131517          	auipc	a0,0x131
    80000b24:	46050513          	addi	a0,a0,1120 # 80131f80 <end>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	f88080e7          	jalr	-120(ra) # 80000ab0 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b30:	00008797          	auipc	a5,0x8
    80000b34:	fa87b783          	ld	a5,-88(a5) # 80008ad8 <FREE_PAGES>
    80000b38:	00008717          	auipc	a4,0x8
    80000b3c:	faf73423          	sd	a5,-88(a4) # 80008ae0 <MAX_PAGES>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
// Sets ref count to 1 for newly allocated page
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b52:	00008797          	auipc	a5,0x8
    80000b56:	f867b783          	ld	a5,-122(a5) # 80008ad8 <FREE_PAGES>
    80000b5a:	cfb9                	beqz	a5,80000bb8 <kalloc+0x70>
    struct run *r;

    acquire(&kmem.lock);
    80000b5c:	00010497          	auipc	s1,0x10
    80000b60:	1f448493          	addi	s1,s1,500 # 80010d50 <kmem>
    80000b64:	8526                	mv	a0,s1
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	128080e7          	jalr	296(ra) # 80000c8e <acquire>
    r = kmem.freelist;
    80000b6e:	6c84                	ld	s1,24(s1)
    if (r)
    80000b70:	ccb5                	beqz	s1,80000bec <kalloc+0xa4>
        kmem.freelist = r->next;
    80000b72:	609c                	ld	a5,0(s1)
    80000b74:	00010517          	auipc	a0,0x10
    80000b78:	1dc50513          	addi	a0,a0,476 # 80010d50 <kmem>
    80000b7c:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	1c4080e7          	jalr	452(ra) # 80000d42 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000b86:	6605                	lui	a2,0x1
    80000b88:	4595                	li	a1,5
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	1fe080e7          	jalr	510(ra) # 80000d8a <memset>
    inc_ref(r);
    80000b94:	8526                	mv	a0,s1
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	832080e7          	jalr	-1998(ra) # 800013c8 <inc_ref>
    FREE_PAGES--;
    80000b9e:	00008717          	auipc	a4,0x8
    80000ba2:	f3a70713          	addi	a4,a4,-198 # 80008ad8 <FREE_PAGES>
    80000ba6:	631c                	ld	a5,0(a4)
    80000ba8:	17fd                	addi	a5,a5,-1
    80000baa:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bac:	8526                	mv	a0,s1
    80000bae:	60e2                	ld	ra,24(sp)
    80000bb0:	6442                	ld	s0,16(sp)
    80000bb2:	64a2                	ld	s1,8(sp)
    80000bb4:	6105                	addi	sp,sp,32
    80000bb6:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bb8:	05100693          	li	a3,81
    80000bbc:	00007617          	auipc	a2,0x7
    80000bc0:	44460613          	addi	a2,a2,1092 # 80008000 <etext>
    80000bc4:	00007597          	auipc	a1,0x7
    80000bc8:	4b458593          	addi	a1,a1,1204 # 80008078 <digits+0x28>
    80000bcc:	00007517          	auipc	a0,0x7
    80000bd0:	4bc50513          	addi	a0,a0,1212 # 80008088 <digits+0x38>
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	9b2080e7          	jalr	-1614(ra) # 80000586 <printf>
    80000bdc:	00007517          	auipc	a0,0x7
    80000be0:	4bc50513          	addi	a0,a0,1212 # 80008098 <digits+0x48>
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	958080e7          	jalr	-1704(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000bec:	00010517          	auipc	a0,0x10
    80000bf0:	16450513          	addi	a0,a0,356 # 80010d50 <kmem>
    80000bf4:	00000097          	auipc	ra,0x0
    80000bf8:	14e080e7          	jalr	334(ra) # 80000d42 <release>
    if (r)
    80000bfc:	bf61                	j	80000b94 <kalloc+0x4c>

0000000080000bfe <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bfe:	1141                	addi	sp,sp,-16
    80000c00:	e422                	sd	s0,8(sp)
    80000c02:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c04:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c06:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c0a:	00053823          	sd	zero,16(a0)
}
    80000c0e:	6422                	ld	s0,8(sp)
    80000c10:	0141                	addi	sp,sp,16
    80000c12:	8082                	ret

0000000080000c14 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c14:	411c                	lw	a5,0(a0)
    80000c16:	e399                	bnez	a5,80000c1c <holding+0x8>
    80000c18:	4501                	li	a0,0
  return r;
}
    80000c1a:	8082                	ret
{
    80000c1c:	1101                	addi	sp,sp,-32
    80000c1e:	ec06                	sd	ra,24(sp)
    80000c20:	e822                	sd	s0,16(sp)
    80000c22:	e426                	sd	s1,8(sp)
    80000c24:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c26:	6904                	ld	s1,16(a0)
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	086080e7          	jalr	134(ra) # 80001cae <mycpu>
    80000c30:	40a48533          	sub	a0,s1,a0
    80000c34:	00153513          	seqz	a0,a0
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret

0000000080000c42 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c42:	1101                	addi	sp,sp,-32
    80000c44:	ec06                	sd	ra,24(sp)
    80000c46:	e822                	sd	s0,16(sp)
    80000c48:	e426                	sd	s1,8(sp)
    80000c4a:	1000                	addi	s0,sp,32
    asm volatile("csrr %0, sstatus"
    80000c4c:	100024f3          	csrr	s1,sstatus
    80000c50:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c54:	9bf5                	andi	a5,a5,-3
    asm volatile("csrw sstatus, %0"
    80000c56:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	054080e7          	jalr	84(ra) # 80001cae <mycpu>
    80000c62:	5d3c                	lw	a5,120(a0)
    80000c64:	cf89                	beqz	a5,80000c7e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c66:	00001097          	auipc	ra,0x1
    80000c6a:	048080e7          	jalr	72(ra) # 80001cae <mycpu>
    80000c6e:	5d3c                	lw	a5,120(a0)
    80000c70:	2785                	addiw	a5,a5,1
    80000c72:	dd3c                	sw	a5,120(a0)
}
    80000c74:	60e2                	ld	ra,24(sp)
    80000c76:	6442                	ld	s0,16(sp)
    80000c78:	64a2                	ld	s1,8(sp)
    80000c7a:	6105                	addi	sp,sp,32
    80000c7c:	8082                	ret
    mycpu()->intena = old;
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	030080e7          	jalr	48(ra) # 80001cae <mycpu>
    return (x & SSTATUS_SIE) != 0;
    80000c86:	8085                	srli	s1,s1,0x1
    80000c88:	8885                	andi	s1,s1,1
    80000c8a:	dd64                	sw	s1,124(a0)
    80000c8c:	bfe9                	j	80000c66 <push_off+0x24>

0000000080000c8e <acquire>:
{
    80000c8e:	1101                	addi	sp,sp,-32
    80000c90:	ec06                	sd	ra,24(sp)
    80000c92:	e822                	sd	s0,16(sp)
    80000c94:	e426                	sd	s1,8(sp)
    80000c96:	1000                	addi	s0,sp,32
    80000c98:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	fa8080e7          	jalr	-88(ra) # 80000c42 <push_off>
  if(holding(lk))
    80000ca2:	8526                	mv	a0,s1
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	f70080e7          	jalr	-144(ra) # 80000c14 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cac:	4705                	li	a4,1
  if(holding(lk))
    80000cae:	e115                	bnez	a0,80000cd2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb0:	87ba                	mv	a5,a4
    80000cb2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cb6:	2781                	sext.w	a5,a5
    80000cb8:	ffe5                	bnez	a5,80000cb0 <acquire+0x22>
  __sync_synchronize();
    80000cba:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	ff0080e7          	jalr	-16(ra) # 80001cae <mycpu>
    80000cc6:	e888                	sd	a0,16(s1)
}
    80000cc8:	60e2                	ld	ra,24(sp)
    80000cca:	6442                	ld	s0,16(sp)
    80000ccc:	64a2                	ld	s1,8(sp)
    80000cce:	6105                	addi	sp,sp,32
    80000cd0:	8082                	ret
    panic("acquire");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3de50513          	addi	a0,a0,990 # 800080b0 <digits+0x60>
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	862080e7          	jalr	-1950(ra) # 8000053c <panic>

0000000080000ce2 <pop_off>:

void
pop_off(void)
{
    80000ce2:	1141                	addi	sp,sp,-16
    80000ce4:	e406                	sd	ra,8(sp)
    80000ce6:	e022                	sd	s0,0(sp)
    80000ce8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cea:	00001097          	auipc	ra,0x1
    80000cee:	fc4080e7          	jalr	-60(ra) # 80001cae <mycpu>
    asm volatile("csrr %0, sstatus"
    80000cf2:	100027f3          	csrr	a5,sstatus
    return (x & SSTATUS_SIE) != 0;
    80000cf6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cf8:	e78d                	bnez	a5,80000d22 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cfa:	5d3c                	lw	a5,120(a0)
    80000cfc:	02f05b63          	blez	a5,80000d32 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d00:	37fd                	addiw	a5,a5,-1
    80000d02:	0007871b          	sext.w	a4,a5
    80000d06:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d08:	eb09                	bnez	a4,80000d1a <pop_off+0x38>
    80000d0a:	5d7c                	lw	a5,124(a0)
    80000d0c:	c799                	beqz	a5,80000d1a <pop_off+0x38>
    asm volatile("csrr %0, sstatus"
    80000d0e:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d12:	0027e793          	ori	a5,a5,2
    asm volatile("csrw sstatus, %0"
    80000d16:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d1a:	60a2                	ld	ra,8(sp)
    80000d1c:	6402                	ld	s0,0(sp)
    80000d1e:	0141                	addi	sp,sp,16
    80000d20:	8082                	ret
    panic("pop_off - interruptible");
    80000d22:	00007517          	auipc	a0,0x7
    80000d26:	39650513          	addi	a0,a0,918 # 800080b8 <digits+0x68>
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	812080e7          	jalr	-2030(ra) # 8000053c <panic>
    panic("pop_off");
    80000d32:	00007517          	auipc	a0,0x7
    80000d36:	39e50513          	addi	a0,a0,926 # 800080d0 <digits+0x80>
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	802080e7          	jalr	-2046(ra) # 8000053c <panic>

0000000080000d42 <release>:
{
    80000d42:	1101                	addi	sp,sp,-32
    80000d44:	ec06                	sd	ra,24(sp)
    80000d46:	e822                	sd	s0,16(sp)
    80000d48:	e426                	sd	s1,8(sp)
    80000d4a:	1000                	addi	s0,sp,32
    80000d4c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d4e:	00000097          	auipc	ra,0x0
    80000d52:	ec6080e7          	jalr	-314(ra) # 80000c14 <holding>
    80000d56:	c115                	beqz	a0,80000d7a <release+0x38>
  lk->cpu = 0;
    80000d58:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d5c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d60:	0f50000f          	fence	iorw,ow
    80000d64:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d68:	00000097          	auipc	ra,0x0
    80000d6c:	f7a080e7          	jalr	-134(ra) # 80000ce2 <pop_off>
}
    80000d70:	60e2                	ld	ra,24(sp)
    80000d72:	6442                	ld	s0,16(sp)
    80000d74:	64a2                	ld	s1,8(sp)
    80000d76:	6105                	addi	sp,sp,32
    80000d78:	8082                	ret
    panic("release");
    80000d7a:	00007517          	auipc	a0,0x7
    80000d7e:	35e50513          	addi	a0,a0,862 # 800080d8 <digits+0x88>
    80000d82:	fffff097          	auipc	ra,0xfffff
    80000d86:	7ba080e7          	jalr	1978(ra) # 8000053c <panic>

0000000080000d8a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e422                	sd	s0,8(sp)
    80000d8e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d90:	ca19                	beqz	a2,80000da6 <memset+0x1c>
    80000d92:	87aa                	mv	a5,a0
    80000d94:	1602                	slli	a2,a2,0x20
    80000d96:	9201                	srli	a2,a2,0x20
    80000d98:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d9c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000da0:	0785                	addi	a5,a5,1
    80000da2:	fee79de3          	bne	a5,a4,80000d9c <memset+0x12>
  }
  return dst;
}
    80000da6:	6422                	ld	s0,8(sp)
    80000da8:	0141                	addi	sp,sp,16
    80000daa:	8082                	ret

0000000080000dac <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dac:	1141                	addi	sp,sp,-16
    80000dae:	e422                	sd	s0,8(sp)
    80000db0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000db2:	ca05                	beqz	a2,80000de2 <memcmp+0x36>
    80000db4:	fff6069b          	addiw	a3,a2,-1
    80000db8:	1682                	slli	a3,a3,0x20
    80000dba:	9281                	srli	a3,a3,0x20
    80000dbc:	0685                	addi	a3,a3,1
    80000dbe:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	0005c703          	lbu	a4,0(a1)
    80000dc8:	00e79863          	bne	a5,a4,80000dd8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dcc:	0505                	addi	a0,a0,1
    80000dce:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dd0:	fed518e3          	bne	a0,a3,80000dc0 <memcmp+0x14>
  }

  return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	a019                	j	80000ddc <memcmp+0x30>
      return *s1 - *s2;
    80000dd8:	40e7853b          	subw	a0,a5,a4
}
    80000ddc:	6422                	ld	s0,8(sp)
    80000dde:	0141                	addi	sp,sp,16
    80000de0:	8082                	ret
  return 0;
    80000de2:	4501                	li	a0,0
    80000de4:	bfe5                	j	80000ddc <memcmp+0x30>

0000000080000de6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000de6:	1141                	addi	sp,sp,-16
    80000de8:	e422                	sd	s0,8(sp)
    80000dea:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dec:	c205                	beqz	a2,80000e0c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dee:	02a5e263          	bltu	a1,a0,80000e12 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000df2:	1602                	slli	a2,a2,0x20
    80000df4:	9201                	srli	a2,a2,0x20
    80000df6:	00c587b3          	add	a5,a1,a2
{
    80000dfa:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dfc:	0585                	addi	a1,a1,1
    80000dfe:	0705                	addi	a4,a4,1
    80000e00:	fff5c683          	lbu	a3,-1(a1)
    80000e04:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e08:	fef59ae3          	bne	a1,a5,80000dfc <memmove+0x16>

  return dst;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret
  if(s < d && s + n > d){
    80000e12:	02061693          	slli	a3,a2,0x20
    80000e16:	9281                	srli	a3,a3,0x20
    80000e18:	00d58733          	add	a4,a1,a3
    80000e1c:	fce57be3          	bgeu	a0,a4,80000df2 <memmove+0xc>
    d += n;
    80000e20:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e22:	fff6079b          	addiw	a5,a2,-1
    80000e26:	1782                	slli	a5,a5,0x20
    80000e28:	9381                	srli	a5,a5,0x20
    80000e2a:	fff7c793          	not	a5,a5
    80000e2e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e30:	177d                	addi	a4,a4,-1
    80000e32:	16fd                	addi	a3,a3,-1
    80000e34:	00074603          	lbu	a2,0(a4)
    80000e38:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e3c:	fee79ae3          	bne	a5,a4,80000e30 <memmove+0x4a>
    80000e40:	b7f1                	j	80000e0c <memmove+0x26>

0000000080000e42 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e406                	sd	ra,8(sp)
    80000e46:	e022                	sd	s0,0(sp)
    80000e48:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e4a:	00000097          	auipc	ra,0x0
    80000e4e:	f9c080e7          	jalr	-100(ra) # 80000de6 <memmove>
}
    80000e52:	60a2                	ld	ra,8(sp)
    80000e54:	6402                	ld	s0,0(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e60:	ce11                	beqz	a2,80000e7c <strncmp+0x22>
    80000e62:	00054783          	lbu	a5,0(a0)
    80000e66:	cf89                	beqz	a5,80000e80 <strncmp+0x26>
    80000e68:	0005c703          	lbu	a4,0(a1)
    80000e6c:	00f71a63          	bne	a4,a5,80000e80 <strncmp+0x26>
    n--, p++, q++;
    80000e70:	367d                	addiw	a2,a2,-1
    80000e72:	0505                	addi	a0,a0,1
    80000e74:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e76:	f675                	bnez	a2,80000e62 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e78:	4501                	li	a0,0
    80000e7a:	a809                	j	80000e8c <strncmp+0x32>
    80000e7c:	4501                	li	a0,0
    80000e7e:	a039                	j	80000e8c <strncmp+0x32>
  if(n == 0)
    80000e80:	ca09                	beqz	a2,80000e92 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e82:	00054503          	lbu	a0,0(a0)
    80000e86:	0005c783          	lbu	a5,0(a1)
    80000e8a:	9d1d                	subw	a0,a0,a5
}
    80000e8c:	6422                	ld	s0,8(sp)
    80000e8e:	0141                	addi	sp,sp,16
    80000e90:	8082                	ret
    return 0;
    80000e92:	4501                	li	a0,0
    80000e94:	bfe5                	j	80000e8c <strncmp+0x32>

0000000080000e96 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e96:	1141                	addi	sp,sp,-16
    80000e98:	e422                	sd	s0,8(sp)
    80000e9a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e9c:	87aa                	mv	a5,a0
    80000e9e:	86b2                	mv	a3,a2
    80000ea0:	367d                	addiw	a2,a2,-1
    80000ea2:	00d05963          	blez	a3,80000eb4 <strncpy+0x1e>
    80000ea6:	0785                	addi	a5,a5,1
    80000ea8:	0005c703          	lbu	a4,0(a1)
    80000eac:	fee78fa3          	sb	a4,-1(a5)
    80000eb0:	0585                	addi	a1,a1,1
    80000eb2:	f775                	bnez	a4,80000e9e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eb4:	873e                	mv	a4,a5
    80000eb6:	9fb5                	addw	a5,a5,a3
    80000eb8:	37fd                	addiw	a5,a5,-1
    80000eba:	00c05963          	blez	a2,80000ecc <strncpy+0x36>
    *s++ = 0;
    80000ebe:	0705                	addi	a4,a4,1
    80000ec0:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000ec4:	40e786bb          	subw	a3,a5,a4
    80000ec8:	fed04be3          	bgtz	a3,80000ebe <strncpy+0x28>
  return os;
}
    80000ecc:	6422                	ld	s0,8(sp)
    80000ece:	0141                	addi	sp,sp,16
    80000ed0:	8082                	ret

0000000080000ed2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e422                	sd	s0,8(sp)
    80000ed6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ed8:	02c05363          	blez	a2,80000efe <safestrcpy+0x2c>
    80000edc:	fff6069b          	addiw	a3,a2,-1
    80000ee0:	1682                	slli	a3,a3,0x20
    80000ee2:	9281                	srli	a3,a3,0x20
    80000ee4:	96ae                	add	a3,a3,a1
    80000ee6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ee8:	00d58963          	beq	a1,a3,80000efa <safestrcpy+0x28>
    80000eec:	0585                	addi	a1,a1,1
    80000eee:	0785                	addi	a5,a5,1
    80000ef0:	fff5c703          	lbu	a4,-1(a1)
    80000ef4:	fee78fa3          	sb	a4,-1(a5)
    80000ef8:	fb65                	bnez	a4,80000ee8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000efa:	00078023          	sb	zero,0(a5)
  return os;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret

0000000080000f04 <strlen>:

int
strlen(const char *s)
{
    80000f04:	1141                	addi	sp,sp,-16
    80000f06:	e422                	sd	s0,8(sp)
    80000f08:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f0a:	00054783          	lbu	a5,0(a0)
    80000f0e:	cf91                	beqz	a5,80000f2a <strlen+0x26>
    80000f10:	0505                	addi	a0,a0,1
    80000f12:	87aa                	mv	a5,a0
    80000f14:	86be                	mv	a3,a5
    80000f16:	0785                	addi	a5,a5,1
    80000f18:	fff7c703          	lbu	a4,-1(a5)
    80000f1c:	ff65                	bnez	a4,80000f14 <strlen+0x10>
    80000f1e:	40a6853b          	subw	a0,a3,a0
    80000f22:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f24:	6422                	ld	s0,8(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f2a:	4501                	li	a0,0
    80000f2c:	bfe5                	j	80000f24 <strlen+0x20>

0000000080000f2e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f2e:	1141                	addi	sp,sp,-16
    80000f30:	e406                	sd	ra,8(sp)
    80000f32:	e022                	sd	s0,0(sp)
    80000f34:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	d68080e7          	jalr	-664(ra) # 80001c9e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f3e:	00008717          	auipc	a4,0x8
    80000f42:	baa70713          	addi	a4,a4,-1110 # 80008ae8 <started>
  if(cpuid() == 0){
    80000f46:	c139                	beqz	a0,80000f8c <main+0x5e>
    while(started == 0)
    80000f48:	431c                	lw	a5,0(a4)
    80000f4a:	2781                	sext.w	a5,a5
    80000f4c:	dff5                	beqz	a5,80000f48 <main+0x1a>
      ;
    __sync_synchronize();
    80000f4e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	d4c080e7          	jalr	-692(ra) # 80001c9e <cpuid>
    80000f5a:	85aa                	mv	a1,a0
    80000f5c:	00007517          	auipc	a0,0x7
    80000f60:	19c50513          	addi	a0,a0,412 # 800080f8 <digits+0xa8>
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	622080e7          	jalr	1570(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	0d8080e7          	jalr	216(ra) # 80001044 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	c38080e7          	jalr	-968(ra) # 80002bac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f7c:	00005097          	auipc	ra,0x5
    80000f80:	364080e7          	jalr	868(ra) # 800062e0 <plicinithart>
  }

  scheduler();        
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	38c080e7          	jalr	908(ra) # 80002310 <scheduler>
    consoleinit();
    80000f8c:	fffff097          	auipc	ra,0xfffff
    80000f90:	4c0080e7          	jalr	1216(ra) # 8000044c <consoleinit>
    printfinit();
    80000f94:	fffff097          	auipc	ra,0xfffff
    80000f98:	7d2080e7          	jalr	2002(ra) # 80000766 <printfinit>
    printf("\n");
    80000f9c:	00007517          	auipc	a0,0x7
    80000fa0:	56450513          	addi	a0,a0,1380 # 80008500 <states.0+0x80>
    80000fa4:	fffff097          	auipc	ra,0xfffff
    80000fa8:	5e2080e7          	jalr	1506(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000fac:	00007517          	auipc	a0,0x7
    80000fb0:	13450513          	addi	a0,a0,308 # 800080e0 <digits+0x90>
    80000fb4:	fffff097          	auipc	ra,0xfffff
    80000fb8:	5d2080e7          	jalr	1490(ra) # 80000586 <printf>
    printf("\n");
    80000fbc:	00007517          	auipc	a0,0x7
    80000fc0:	54450513          	addi	a0,a0,1348 # 80008500 <states.0+0x80>
    80000fc4:	fffff097          	auipc	ra,0xfffff
    80000fc8:	5c2080e7          	jalr	1474(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	b30080e7          	jalr	-1232(ra) # 80000afc <kinit>
    kvminit();       // create kernel page table
    80000fd4:	00000097          	auipc	ra,0x0
    80000fd8:	334080e7          	jalr	820(ra) # 80001308 <kvminit>
    kvminithart();   // turn on paging
    80000fdc:	00000097          	auipc	ra,0x0
    80000fe0:	068080e7          	jalr	104(ra) # 80001044 <kvminithart>
    procinit();      // process table
    80000fe4:	00001097          	auipc	ra,0x1
    80000fe8:	be2080e7          	jalr	-1054(ra) # 80001bc6 <procinit>
    trapinit();      // trap vectors
    80000fec:	00002097          	auipc	ra,0x2
    80000ff0:	b98080e7          	jalr	-1128(ra) # 80002b84 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff4:	00002097          	auipc	ra,0x2
    80000ff8:	bb8080e7          	jalr	-1096(ra) # 80002bac <trapinithart>
    plicinit();      // set up interrupt controller
    80000ffc:	00005097          	auipc	ra,0x5
    80001000:	2ce080e7          	jalr	718(ra) # 800062ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001004:	00005097          	auipc	ra,0x5
    80001008:	2dc080e7          	jalr	732(ra) # 800062e0 <plicinithart>
    binit();         // buffer cache
    8000100c:	00002097          	auipc	ra,0x2
    80001010:	4d2080e7          	jalr	1234(ra) # 800034de <binit>
    iinit();         // inode table
    80001014:	00003097          	auipc	ra,0x3
    80001018:	b70080e7          	jalr	-1168(ra) # 80003b84 <iinit>
    fileinit();      // file table
    8000101c:	00004097          	auipc	ra,0x4
    80001020:	ae6080e7          	jalr	-1306(ra) # 80004b02 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001024:	00005097          	auipc	ra,0x5
    80001028:	3c4080e7          	jalr	964(ra) # 800063e8 <virtio_disk_init>
    userinit();      // first user process
    8000102c:	00001097          	auipc	ra,0x1
    80001030:	f76080e7          	jalr	-138(ra) # 80001fa2 <userinit>
    __sync_synchronize();
    80001034:	0ff0000f          	fence
    started = 1;
    80001038:	4785                	li	a5,1
    8000103a:	00008717          	auipc	a4,0x8
    8000103e:	aaf72723          	sw	a5,-1362(a4) # 80008ae8 <started>
    80001042:	b789                	j	80000f84 <main+0x56>

0000000080001044 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80001044:	1141                	addi	sp,sp,-16
    80001046:	e422                	sd	s0,8(sp)
    80001048:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
    // the zero, zero means flush all TLB entries.
    asm volatile("sfence.vma zero, zero");
    8000104a:	12000073          	sfence.vma
    // wait for any previous writes to the page table memory to finish.
    sfence_vma();

    w_satp(MAKE_SATP(kernel_pagetable));
    8000104e:	00008797          	auipc	a5,0x8
    80001052:	aa27b783          	ld	a5,-1374(a5) # 80008af0 <kernel_pagetable>
    80001056:	83b1                	srli	a5,a5,0xc
    80001058:	577d                	li	a4,-1
    8000105a:	177e                	slli	a4,a4,0x3f
    8000105c:	8fd9                	or	a5,a5,a4
    asm volatile("csrw satp, %0"
    8000105e:	18079073          	csrw	satp,a5
    asm volatile("sfence.vma zero, zero");
    80001062:	12000073          	sfence.vma

    // flush stale entries from the TLB.
    sfence_vma();
}
    80001066:	6422                	ld	s0,8(sp)
    80001068:	0141                	addi	sp,sp,16
    8000106a:	8082                	ret

000000008000106c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000106c:	7139                	addi	sp,sp,-64
    8000106e:	fc06                	sd	ra,56(sp)
    80001070:	f822                	sd	s0,48(sp)
    80001072:	f426                	sd	s1,40(sp)
    80001074:	f04a                	sd	s2,32(sp)
    80001076:	ec4e                	sd	s3,24(sp)
    80001078:	e852                	sd	s4,16(sp)
    8000107a:	e456                	sd	s5,8(sp)
    8000107c:	e05a                	sd	s6,0(sp)
    8000107e:	0080                	addi	s0,sp,64
    80001080:	84aa                	mv	s1,a0
    80001082:	89ae                	mv	s3,a1
    80001084:	8ab2                	mv	s5,a2
    if (va >= MAXVA)
    80001086:	57fd                	li	a5,-1
    80001088:	83e9                	srli	a5,a5,0x1a
    8000108a:	4a79                	li	s4,30
        panic("walk");

    for (int level = 2; level > 0; level--)
    8000108c:	4b31                	li	s6,12
    if (va >= MAXVA)
    8000108e:	04b7f263          	bgeu	a5,a1,800010d2 <walk+0x66>
        panic("walk");
    80001092:	00007517          	auipc	a0,0x7
    80001096:	07e50513          	addi	a0,a0,126 # 80008110 <digits+0xc0>
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	4a2080e7          	jalr	1186(ra) # 8000053c <panic>
        {
            pagetable = (pagetable_t)PTE2PA(*pte);
        }
        else
        {
            if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800010a2:	060a8663          	beqz	s5,8000110e <walk+0xa2>
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	aa2080e7          	jalr	-1374(ra) # 80000b48 <kalloc>
    800010ae:	84aa                	mv	s1,a0
    800010b0:	c529                	beqz	a0,800010fa <walk+0x8e>
                return 0;
            memset(pagetable, 0, PGSIZE);
    800010b2:	6605                	lui	a2,0x1
    800010b4:	4581                	li	a1,0
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	cd4080e7          	jalr	-812(ra) # 80000d8a <memset>
            *pte = PA2PTE(pagetable) | PTE_V;
    800010be:	00c4d793          	srli	a5,s1,0xc
    800010c2:	07aa                	slli	a5,a5,0xa
    800010c4:	0017e793          	ori	a5,a5,1
    800010c8:	00f93023          	sd	a5,0(s2)
    for (int level = 2; level > 0; level--)
    800010cc:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fecd077>
    800010ce:	036a0063          	beq	s4,s6,800010ee <walk+0x82>
        pte_t *pte = &pagetable[PX(level, va)];
    800010d2:	0149d933          	srl	s2,s3,s4
    800010d6:	1ff97913          	andi	s2,s2,511
    800010da:	090e                	slli	s2,s2,0x3
    800010dc:	9926                	add	s2,s2,s1
        if (*pte & PTE_V)
    800010de:	00093483          	ld	s1,0(s2)
    800010e2:	0014f793          	andi	a5,s1,1
    800010e6:	dfd5                	beqz	a5,800010a2 <walk+0x36>
            pagetable = (pagetable_t)PTE2PA(*pte);
    800010e8:	80a9                	srli	s1,s1,0xa
    800010ea:	04b2                	slli	s1,s1,0xc
    800010ec:	b7c5                	j	800010cc <walk+0x60>
        }
    }
    return &pagetable[PX(0, va)];
    800010ee:	00c9d513          	srli	a0,s3,0xc
    800010f2:	1ff57513          	andi	a0,a0,511
    800010f6:	050e                	slli	a0,a0,0x3
    800010f8:	9526                	add	a0,a0,s1
}
    800010fa:	70e2                	ld	ra,56(sp)
    800010fc:	7442                	ld	s0,48(sp)
    800010fe:	74a2                	ld	s1,40(sp)
    80001100:	7902                	ld	s2,32(sp)
    80001102:	69e2                	ld	s3,24(sp)
    80001104:	6a42                	ld	s4,16(sp)
    80001106:	6aa2                	ld	s5,8(sp)
    80001108:	6b02                	ld	s6,0(sp)
    8000110a:	6121                	addi	sp,sp,64
    8000110c:	8082                	ret
                return 0;
    8000110e:	4501                	li	a0,0
    80001110:	b7ed                	j	800010fa <walk+0x8e>

0000000080001112 <walkaddrf>:
walkaddrf(pagetable_t pagetable, uint64 va, uint64 *flags)
{
    pte_t *pte;
    uint64 pa;

    if (va >= MAXVA)
    80001112:	57fd                	li	a5,-1
    80001114:	83e9                	srli	a5,a5,0x1a
    80001116:	00b7f463          	bgeu	a5,a1,8000111e <walkaddrf+0xc>
        return 0;
    8000111a:	4501                	li	a0,0
    if (flags != 0)
    {
        *flags = PTE_FLAGS(*pte);
    }
    return pa;
}
    8000111c:	8082                	ret
{
    8000111e:	1101                	addi	sp,sp,-32
    80001120:	ec06                	sd	ra,24(sp)
    80001122:	e822                	sd	s0,16(sp)
    80001124:	e426                	sd	s1,8(sp)
    80001126:	1000                	addi	s0,sp,32
    80001128:	84b2                	mv	s1,a2
    pte = walk(pagetable, va, 0);
    8000112a:	4601                	li	a2,0
    8000112c:	00000097          	auipc	ra,0x0
    80001130:	f40080e7          	jalr	-192(ra) # 8000106c <walk>
    if (pte == 0)
    80001134:	c50d                	beqz	a0,8000115e <walkaddrf+0x4c>
    if ((*pte & PTE_V) == 0)
    80001136:	611c                	ld	a5,0(a0)
    if ((*pte & PTE_U) == 0)
    80001138:	0117f693          	andi	a3,a5,17
    8000113c:	4745                	li	a4,17
        return 0;
    8000113e:	4501                	li	a0,0
    if ((*pte & PTE_U) == 0)
    80001140:	00e68763          	beq	a3,a4,8000114e <walkaddrf+0x3c>
}
    80001144:	60e2                	ld	ra,24(sp)
    80001146:	6442                	ld	s0,16(sp)
    80001148:	64a2                	ld	s1,8(sp)
    8000114a:	6105                	addi	sp,sp,32
    8000114c:	8082                	ret
    pa = PTE2PA(*pte);
    8000114e:	00a7d513          	srli	a0,a5,0xa
    80001152:	0532                	slli	a0,a0,0xc
    if (flags != 0)
    80001154:	d8e5                	beqz	s1,80001144 <walkaddrf+0x32>
        *flags = PTE_FLAGS(*pte);
    80001156:	3ff7f793          	andi	a5,a5,1023
    8000115a:	e09c                	sd	a5,0(s1)
    8000115c:	b7e5                	j	80001144 <walkaddrf+0x32>
        return 0;
    8000115e:	4501                	li	a0,0
    80001160:	b7d5                	j	80001144 <walkaddrf+0x32>

0000000080001162 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001162:	715d                	addi	sp,sp,-80
    80001164:	e486                	sd	ra,72(sp)
    80001166:	e0a2                	sd	s0,64(sp)
    80001168:	fc26                	sd	s1,56(sp)
    8000116a:	f84a                	sd	s2,48(sp)
    8000116c:	f44e                	sd	s3,40(sp)
    8000116e:	f052                	sd	s4,32(sp)
    80001170:	ec56                	sd	s5,24(sp)
    80001172:	e85a                	sd	s6,16(sp)
    80001174:	e45e                	sd	s7,8(sp)
    80001176:	0880                	addi	s0,sp,80
    uint64 a, last;
    pte_t *pte;

    if (size == 0)
    80001178:	c639                	beqz	a2,800011c6 <mappages+0x64>
    8000117a:	8aaa                	mv	s5,a0
    8000117c:	8b3a                	mv	s6,a4
        panic("mappages: size");

    a = PGROUNDDOWN(va);
    8000117e:	777d                	lui	a4,0xfffff
    80001180:	00e5f7b3          	and	a5,a1,a4
    last = PGROUNDDOWN(va + size - 1);
    80001184:	fff58993          	addi	s3,a1,-1
    80001188:	99b2                	add	s3,s3,a2
    8000118a:	00e9f9b3          	and	s3,s3,a4
    a = PGROUNDDOWN(va);
    8000118e:	893e                	mv	s2,a5
    80001190:	40f68a33          	sub	s4,a3,a5
        if (*pte & PTE_V)
            panic("mappages: remap");
        *pte = PA2PTE(pa) | perm | PTE_V;
        if (a == last)
            break;
        a += PGSIZE;
    80001194:	6b85                	lui	s7,0x1
    80001196:	012a04b3          	add	s1,s4,s2
        if ((pte = walk(pagetable, a, 1)) == 0)
    8000119a:	4605                	li	a2,1
    8000119c:	85ca                	mv	a1,s2
    8000119e:	8556                	mv	a0,s5
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	ecc080e7          	jalr	-308(ra) # 8000106c <walk>
    800011a8:	cd1d                	beqz	a0,800011e6 <mappages+0x84>
        if (*pte & PTE_V)
    800011aa:	611c                	ld	a5,0(a0)
    800011ac:	8b85                	andi	a5,a5,1
    800011ae:	e785                	bnez	a5,800011d6 <mappages+0x74>
        *pte = PA2PTE(pa) | perm | PTE_V;
    800011b0:	80b1                	srli	s1,s1,0xc
    800011b2:	04aa                	slli	s1,s1,0xa
    800011b4:	0164e4b3          	or	s1,s1,s6
    800011b8:	0014e493          	ori	s1,s1,1
    800011bc:	e104                	sd	s1,0(a0)
        if (a == last)
    800011be:	05390063          	beq	s2,s3,800011fe <mappages+0x9c>
        a += PGSIZE;
    800011c2:	995e                	add	s2,s2,s7
        if ((pte = walk(pagetable, a, 1)) == 0)
    800011c4:	bfc9                	j	80001196 <mappages+0x34>
        panic("mappages: size");
    800011c6:	00007517          	auipc	a0,0x7
    800011ca:	f5250513          	addi	a0,a0,-174 # 80008118 <digits+0xc8>
    800011ce:	fffff097          	auipc	ra,0xfffff
    800011d2:	36e080e7          	jalr	878(ra) # 8000053c <panic>
            panic("mappages: remap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f5250513          	addi	a0,a0,-174 # 80008128 <digits+0xd8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	35e080e7          	jalr	862(ra) # 8000053c <panic>
            return -1;
    800011e6:	557d                	li	a0,-1
        pa += PGSIZE;
    }
    return 0;
}
    800011e8:	60a6                	ld	ra,72(sp)
    800011ea:	6406                	ld	s0,64(sp)
    800011ec:	74e2                	ld	s1,56(sp)
    800011ee:	7942                	ld	s2,48(sp)
    800011f0:	79a2                	ld	s3,40(sp)
    800011f2:	7a02                	ld	s4,32(sp)
    800011f4:	6ae2                	ld	s5,24(sp)
    800011f6:	6b42                	ld	s6,16(sp)
    800011f8:	6ba2                	ld	s7,8(sp)
    800011fa:	6161                	addi	sp,sp,80
    800011fc:	8082                	ret
    return 0;
    800011fe:	4501                	li	a0,0
    80001200:	b7e5                	j	800011e8 <mappages+0x86>

0000000080001202 <kvmmap>:
{
    80001202:	1141                	addi	sp,sp,-16
    80001204:	e406                	sd	ra,8(sp)
    80001206:	e022                	sd	s0,0(sp)
    80001208:	0800                	addi	s0,sp,16
    8000120a:	87b6                	mv	a5,a3
    if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000120c:	86b2                	mv	a3,a2
    8000120e:	863e                	mv	a2,a5
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f52080e7          	jalr	-174(ra) # 80001162 <mappages>
    80001218:	e509                	bnez	a0,80001222 <kvmmap+0x20>
}
    8000121a:	60a2                	ld	ra,8(sp)
    8000121c:	6402                	ld	s0,0(sp)
    8000121e:	0141                	addi	sp,sp,16
    80001220:	8082                	ret
        panic("kvmmap");
    80001222:	00007517          	auipc	a0,0x7
    80001226:	f1650513          	addi	a0,a0,-234 # 80008138 <digits+0xe8>
    8000122a:	fffff097          	auipc	ra,0xfffff
    8000122e:	312080e7          	jalr	786(ra) # 8000053c <panic>

0000000080001232 <kvmmake>:
{
    80001232:	1101                	addi	sp,sp,-32
    80001234:	ec06                	sd	ra,24(sp)
    80001236:	e822                	sd	s0,16(sp)
    80001238:	e426                	sd	s1,8(sp)
    8000123a:	e04a                	sd	s2,0(sp)
    8000123c:	1000                	addi	s0,sp,32
    kpgtbl = (pagetable_t)kalloc();
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	90a080e7          	jalr	-1782(ra) # 80000b48 <kalloc>
    80001246:	84aa                	mv	s1,a0
    memset(kpgtbl, 0, PGSIZE);
    80001248:	6605                	lui	a2,0x1
    8000124a:	4581                	li	a1,0
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	b3e080e7          	jalr	-1218(ra) # 80000d8a <memset>
    kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001254:	4719                	li	a4,6
    80001256:	6685                	lui	a3,0x1
    80001258:	10000637          	lui	a2,0x10000
    8000125c:	100005b7          	lui	a1,0x10000
    80001260:	8526                	mv	a0,s1
    80001262:	00000097          	auipc	ra,0x0
    80001266:	fa0080e7          	jalr	-96(ra) # 80001202 <kvmmap>
    kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000126a:	4719                	li	a4,6
    8000126c:	6685                	lui	a3,0x1
    8000126e:	10001637          	lui	a2,0x10001
    80001272:	100015b7          	lui	a1,0x10001
    80001276:	8526                	mv	a0,s1
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	f8a080e7          	jalr	-118(ra) # 80001202 <kvmmap>
    kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001280:	4719                	li	a4,6
    80001282:	004006b7          	lui	a3,0x400
    80001286:	0c000637          	lui	a2,0xc000
    8000128a:	0c0005b7          	lui	a1,0xc000
    8000128e:	8526                	mv	a0,s1
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f72080e7          	jalr	-142(ra) # 80001202 <kvmmap>
    kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80001298:	00007917          	auipc	s2,0x7
    8000129c:	d6890913          	addi	s2,s2,-664 # 80008000 <etext>
    800012a0:	4729                	li	a4,10
    800012a2:	80007697          	auipc	a3,0x80007
    800012a6:	d5e68693          	addi	a3,a3,-674 # 8000 <_entry-0x7fff8000>
    800012aa:	4605                	li	a2,1
    800012ac:	067e                	slli	a2,a2,0x1f
    800012ae:	85b2                	mv	a1,a2
    800012b0:	8526                	mv	a0,s1
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f50080e7          	jalr	-176(ra) # 80001202 <kvmmap>
    kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800012ba:	4719                	li	a4,6
    800012bc:	46c5                	li	a3,17
    800012be:	06ee                	slli	a3,a3,0x1b
    800012c0:	412686b3          	sub	a3,a3,s2
    800012c4:	864a                	mv	a2,s2
    800012c6:	85ca                	mv	a1,s2
    800012c8:	8526                	mv	a0,s1
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	f38080e7          	jalr	-200(ra) # 80001202 <kvmmap>
    kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d2:	4729                	li	a4,10
    800012d4:	6685                	lui	a3,0x1
    800012d6:	00006617          	auipc	a2,0x6
    800012da:	d2a60613          	addi	a2,a2,-726 # 80007000 <_trampoline>
    800012de:	040005b7          	lui	a1,0x4000
    800012e2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e4:	05b2                	slli	a1,a1,0xc
    800012e6:	8526                	mv	a0,s1
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f1a080e7          	jalr	-230(ra) # 80001202 <kvmmap>
    proc_mapstacks(kpgtbl);
    800012f0:	8526                	mv	a0,s1
    800012f2:	00001097          	auipc	ra,0x1
    800012f6:	83e080e7          	jalr	-1986(ra) # 80001b30 <proc_mapstacks>
}
    800012fa:	8526                	mv	a0,s1
    800012fc:	60e2                	ld	ra,24(sp)
    800012fe:	6442                	ld	s0,16(sp)
    80001300:	64a2                	ld	s1,8(sp)
    80001302:	6902                	ld	s2,0(sp)
    80001304:	6105                	addi	sp,sp,32
    80001306:	8082                	ret

0000000080001308 <kvminit>:
{
    80001308:	1141                	addi	sp,sp,-16
    8000130a:	e406                	sd	ra,8(sp)
    8000130c:	e022                	sd	s0,0(sp)
    8000130e:	0800                	addi	s0,sp,16
    kernel_pagetable = kvmmake();
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f22080e7          	jalr	-222(ra) # 80001232 <kvmmake>
    80001318:	00007797          	auipc	a5,0x7
    8000131c:	7ca7bc23          	sd	a0,2008(a5) # 80008af0 <kernel_pagetable>
}
    80001320:	60a2                	ld	ra,8(sp)
    80001322:	6402                	ld	s0,0(sp)
    80001324:	0141                	addi	sp,sp,16
    80001326:	8082                	ret

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
    pagetable_t pagetable;
    pagetable = (pagetable_t)kalloc();
    80001332:	00000097          	auipc	ra,0x0
    80001336:	816080e7          	jalr	-2026(ra) # 80000b48 <kalloc>
    8000133a:	84aa                	mv	s1,a0
    if (pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
        return 0;
    memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	a48080e7          	jalr	-1464(ra) # 80000d8a <memset>
    return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
    char *mem;

    if (sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
        panic("uvmfirst: more than a page");
    mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	7d6080e7          	jalr	2006(ra) # 80000b48 <kalloc>
    8000137a:	892a                	mv	s2,a0
    memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	a0a080e7          	jalr	-1526(ra) # 80000d8a <memset>
    mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	dd0080e7          	jalr	-560(ra) # 80001162 <mappages>
    memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	a46080e7          	jalr	-1466(ra) # 80000de6 <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
        panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d8850513          	addi	a0,a0,-632 # 80008140 <digits+0xf0>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17c080e7          	jalr	380(ra) # 8000053c <panic>

00000000800013c8 <inc_ref>:
        uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    freewalk(pagetable);
}

void inc_ref(void *pa)
{
    800013c8:	1141                	addi	sp,sp,-16
    800013ca:	e422                	sd	s0,8(sp)
    800013cc:	0800                	addi	s0,sp,16
    int index = PAIDX(pa);
    800013ce:	47c5                	li	a5,17
    800013d0:	07ee                	slli	a5,a5,0x1b
    800013d2:	40a78533          	sub	a0,a5,a0
    800013d6:	43f55793          	srai	a5,a0,0x3f
    800013da:	17d2                	slli	a5,a5,0x34
    800013dc:	93d1                	srli	a5,a5,0x34
    800013de:	97aa                	add	a5,a5,a0
    800013e0:	87b1                	srai	a5,a5,0xc
    800013e2:	2781                	sext.w	a5,a5
    // we have at most 64 processes right now, so we do not consider overrun of an int
    parefcount[index]++;
    800013e4:	0786                	slli	a5,a5,0x1
    800013e6:	00010717          	auipc	a4,0x10
    800013ea:	98a70713          	addi	a4,a4,-1654 # 80010d70 <parefcount>
    800013ee:	97ba                	add	a5,a5,a4
    800013f0:	0007d703          	lhu	a4,0(a5) # 1000 <_entry-0x7ffff000>
    800013f4:	2705                	addiw	a4,a4,1
    800013f6:	00e79023          	sh	a4,0(a5)
}
    800013fa:	6422                	ld	s0,8(sp)
    800013fc:	0141                	addi	sp,sp,16
    800013fe:	8082                	ret

0000000080001400 <dec_ref>:
 * if this was the last reference.
 *
 * @param pa The physical address of the page
 */
void dec_ref(void *pa)
{
    80001400:	1141                	addi	sp,sp,-16
    80001402:	e406                	sd	ra,8(sp)
    80001404:	e022                	sd	s0,0(sp)
    80001406:	0800                	addi	s0,sp,16
    int index = PAIDX(pa);
    80001408:	47c5                	li	a5,17
    8000140a:	07ee                	slli	a5,a5,0x1b
    8000140c:	8f89                	sub	a5,a5,a0
    8000140e:	43f7d613          	srai	a2,a5,0x3f
    80001412:	1652                	slli	a2,a2,0x34
    80001414:	9251                	srli	a2,a2,0x34
    80001416:	963e                	add	a2,a2,a5
    80001418:	8631                	srai	a2,a2,0xc
    8000141a:	2601                	sext.w	a2,a2
    if (parefcount[index] <= 0)
    8000141c:	00161713          	slli	a4,a2,0x1
    80001420:	00010797          	auipc	a5,0x10
    80001424:	95078793          	addi	a5,a5,-1712 # 80010d70 <parefcount>
    80001428:	97ba                	add	a5,a5,a4
    8000142a:	0007d783          	lhu	a5,0(a5)
    8000142e:	c38d                	beqz	a5,80001450 <dec_ref+0x50>
    {
        printf("0x%x @ %d is already freed", pa, index);
        panic("Can't decrease ref counter for freed page");
    }
    parefcount[index]--;
    80001430:	37fd                	addiw	a5,a5,-1
    80001432:	17c2                	slli	a5,a5,0x30
    80001434:	93c1                	srli	a5,a5,0x30
    80001436:	0606                	slli	a2,a2,0x1
    80001438:	00010717          	auipc	a4,0x10
    8000143c:	93870713          	addi	a4,a4,-1736 # 80010d70 <parefcount>
    80001440:	9732                	add	a4,a4,a2
    80001442:	00f71023          	sh	a5,0(a4)
    if (parefcount[index] == 0)
    80001446:	c795                	beqz	a5,80001472 <dec_ref+0x72>
    {
        kfree(pa);
    }
}
    80001448:	60a2                	ld	ra,8(sp)
    8000144a:	6402                	ld	s0,0(sp)
    8000144c:	0141                	addi	sp,sp,16
    8000144e:	8082                	ret
        printf("0x%x @ %d is already freed", pa, index);
    80001450:	85aa                	mv	a1,a0
    80001452:	00007517          	auipc	a0,0x7
    80001456:	d0e50513          	addi	a0,a0,-754 # 80008160 <digits+0x110>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	12c080e7          	jalr	300(ra) # 80000586 <printf>
        panic("Can't decrease ref counter for freed page");
    80001462:	00007517          	auipc	a0,0x7
    80001466:	d1e50513          	addi	a0,a0,-738 # 80008180 <digits+0x130>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	0d2080e7          	jalr	210(ra) # 8000053c <panic>
        kfree(pa);
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	572080e7          	jalr	1394(ra) # 800009e4 <kfree>
}
    8000147a:	b7f9                	j	80001448 <dec_ref+0x48>

000000008000147c <uvmunmap>:
{
    8000147c:	715d                	addi	sp,sp,-80
    8000147e:	e486                	sd	ra,72(sp)
    80001480:	e0a2                	sd	s0,64(sp)
    80001482:	fc26                	sd	s1,56(sp)
    80001484:	f84a                	sd	s2,48(sp)
    80001486:	f44e                	sd	s3,40(sp)
    80001488:	f052                	sd	s4,32(sp)
    8000148a:	ec56                	sd	s5,24(sp)
    8000148c:	e85a                	sd	s6,16(sp)
    8000148e:	e45e                	sd	s7,8(sp)
    80001490:	0880                	addi	s0,sp,80
    if ((va % PGSIZE) != 0)
    80001492:	03459793          	slli	a5,a1,0x34
    80001496:	e795                	bnez	a5,800014c2 <uvmunmap+0x46>
    80001498:	8a2a                	mv	s4,a0
    8000149a:	892e                	mv	s2,a1
    8000149c:	8ab6                	mv	s5,a3
    for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000149e:	0632                	slli	a2,a2,0xc
    800014a0:	00b609b3          	add	s3,a2,a1
        if (PTE_FLAGS(*pte) == PTE_V)
    800014a4:	4b85                	li	s7,1
    for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800014a6:	6b05                	lui	s6,0x1
    800014a8:	0735e263          	bltu	a1,s3,8000150c <uvmunmap+0x90>
}
    800014ac:	60a6                	ld	ra,72(sp)
    800014ae:	6406                	ld	s0,64(sp)
    800014b0:	74e2                	ld	s1,56(sp)
    800014b2:	7942                	ld	s2,48(sp)
    800014b4:	79a2                	ld	s3,40(sp)
    800014b6:	7a02                	ld	s4,32(sp)
    800014b8:	6ae2                	ld	s5,24(sp)
    800014ba:	6b42                	ld	s6,16(sp)
    800014bc:	6ba2                	ld	s7,8(sp)
    800014be:	6161                	addi	sp,sp,80
    800014c0:	8082                	ret
        panic("uvmunmap: not aligned");
    800014c2:	00007517          	auipc	a0,0x7
    800014c6:	cee50513          	addi	a0,a0,-786 # 800081b0 <digits+0x160>
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	072080e7          	jalr	114(ra) # 8000053c <panic>
            panic("uvmunmap: walk");
    800014d2:	00007517          	auipc	a0,0x7
    800014d6:	cf650513          	addi	a0,a0,-778 # 800081c8 <digits+0x178>
    800014da:	fffff097          	auipc	ra,0xfffff
    800014de:	062080e7          	jalr	98(ra) # 8000053c <panic>
            panic("uvmunmap: not mapped");
    800014e2:	00007517          	auipc	a0,0x7
    800014e6:	cf650513          	addi	a0,a0,-778 # 800081d8 <digits+0x188>
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	052080e7          	jalr	82(ra) # 8000053c <panic>
            panic("uvmunmap: not a leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	cfe50513          	addi	a0,a0,-770 # 800081f0 <digits+0x1a0>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	042080e7          	jalr	66(ra) # 8000053c <panic>
        *pte = 0;
    80001502:	0004b023          	sd	zero,0(s1)
    for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001506:	995a                	add	s2,s2,s6
    80001508:	fb3972e3          	bgeu	s2,s3,800014ac <uvmunmap+0x30>
        if ((pte = walk(pagetable, a, 0)) == 0)
    8000150c:	4601                	li	a2,0
    8000150e:	85ca                	mv	a1,s2
    80001510:	8552                	mv	a0,s4
    80001512:	00000097          	auipc	ra,0x0
    80001516:	b5a080e7          	jalr	-1190(ra) # 8000106c <walk>
    8000151a:	84aa                	mv	s1,a0
    8000151c:	d95d                	beqz	a0,800014d2 <uvmunmap+0x56>
        if ((*pte & PTE_V) == 0)
    8000151e:	6108                	ld	a0,0(a0)
    80001520:	00157793          	andi	a5,a0,1
    80001524:	dfdd                	beqz	a5,800014e2 <uvmunmap+0x66>
        if (PTE_FLAGS(*pte) == PTE_V)
    80001526:	3ff57793          	andi	a5,a0,1023
    8000152a:	fd7784e3          	beq	a5,s7,800014f2 <uvmunmap+0x76>
        if (do_free)
    8000152e:	fc0a8ae3          	beqz	s5,80001502 <uvmunmap+0x86>
            uint64 pa = PTE2PA(*pte);
    80001532:	8129                	srli	a0,a0,0xa
            dec_ref((void *)pa);
    80001534:	0532                	slli	a0,a0,0xc
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	eca080e7          	jalr	-310(ra) # 80001400 <dec_ref>
    8000153e:	b7d1                	j	80001502 <uvmunmap+0x86>

0000000080001540 <uvmdealloc>:
{
    80001540:	1101                	addi	sp,sp,-32
    80001542:	ec06                	sd	ra,24(sp)
    80001544:	e822                	sd	s0,16(sp)
    80001546:	e426                	sd	s1,8(sp)
    80001548:	1000                	addi	s0,sp,32
        return oldsz;
    8000154a:	84ae                	mv	s1,a1
    if (newsz >= oldsz)
    8000154c:	00b67d63          	bgeu	a2,a1,80001566 <uvmdealloc+0x26>
    80001550:	84b2                	mv	s1,a2
    if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001552:	6785                	lui	a5,0x1
    80001554:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001556:	00f60733          	add	a4,a2,a5
    8000155a:	76fd                	lui	a3,0xfffff
    8000155c:	8f75                	and	a4,a4,a3
    8000155e:	97ae                	add	a5,a5,a1
    80001560:	8ff5                	and	a5,a5,a3
    80001562:	00f76863          	bltu	a4,a5,80001572 <uvmdealloc+0x32>
}
    80001566:	8526                	mv	a0,s1
    80001568:	60e2                	ld	ra,24(sp)
    8000156a:	6442                	ld	s0,16(sp)
    8000156c:	64a2                	ld	s1,8(sp)
    8000156e:	6105                	addi	sp,sp,32
    80001570:	8082                	ret
        int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001572:	8f99                	sub	a5,a5,a4
    80001574:	83b1                	srli	a5,a5,0xc
        uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001576:	4685                	li	a3,1
    80001578:	0007861b          	sext.w	a2,a5
    8000157c:	85ba                	mv	a1,a4
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	efe080e7          	jalr	-258(ra) # 8000147c <uvmunmap>
    80001586:	b7c5                	j	80001566 <uvmdealloc+0x26>

0000000080001588 <uvmalloc>:
    if (newsz < oldsz)
    80001588:	0ab66563          	bltu	a2,a1,80001632 <uvmalloc+0xaa>
{
    8000158c:	7139                	addi	sp,sp,-64
    8000158e:	fc06                	sd	ra,56(sp)
    80001590:	f822                	sd	s0,48(sp)
    80001592:	f426                	sd	s1,40(sp)
    80001594:	f04a                	sd	s2,32(sp)
    80001596:	ec4e                	sd	s3,24(sp)
    80001598:	e852                	sd	s4,16(sp)
    8000159a:	e456                	sd	s5,8(sp)
    8000159c:	e05a                	sd	s6,0(sp)
    8000159e:	0080                	addi	s0,sp,64
    800015a0:	8aaa                	mv	s5,a0
    800015a2:	8a32                	mv	s4,a2
    oldsz = PGROUNDUP(oldsz);
    800015a4:	6785                	lui	a5,0x1
    800015a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015a8:	95be                	add	a1,a1,a5
    800015aa:	77fd                	lui	a5,0xfffff
    800015ac:	00f5f9b3          	and	s3,a1,a5
    for (a = oldsz; a < newsz; a += PGSIZE)
    800015b0:	08c9f363          	bgeu	s3,a2,80001636 <uvmalloc+0xae>
    800015b4:	894e                	mv	s2,s3
        if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015b6:	0126eb13          	ori	s6,a3,18
        mem = kalloc();
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	58e080e7          	jalr	1422(ra) # 80000b48 <kalloc>
    800015c2:	84aa                	mv	s1,a0
        if (mem == 0)
    800015c4:	c51d                	beqz	a0,800015f2 <uvmalloc+0x6a>
        memset(mem, 0, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	4581                	li	a1,0
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	7c0080e7          	jalr	1984(ra) # 80000d8a <memset>
        if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015d2:	875a                	mv	a4,s6
    800015d4:	86a6                	mv	a3,s1
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ca                	mv	a1,s2
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	b86080e7          	jalr	-1146(ra) # 80001162 <mappages>
    800015e4:	e90d                	bnez	a0,80001616 <uvmalloc+0x8e>
    for (a = oldsz; a < newsz; a += PGSIZE)
    800015e6:	6785                	lui	a5,0x1
    800015e8:	993e                	add	s2,s2,a5
    800015ea:	fd4968e3          	bltu	s2,s4,800015ba <uvmalloc+0x32>
    return newsz;
    800015ee:	8552                	mv	a0,s4
    800015f0:	a809                	j	80001602 <uvmalloc+0x7a>
            uvmdealloc(pagetable, a, oldsz);
    800015f2:	864e                	mv	a2,s3
    800015f4:	85ca                	mv	a1,s2
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	f48080e7          	jalr	-184(ra) # 80001540 <uvmdealloc>
            return 0;
    80001600:	4501                	li	a0,0
}
    80001602:	70e2                	ld	ra,56(sp)
    80001604:	7442                	ld	s0,48(sp)
    80001606:	74a2                	ld	s1,40(sp)
    80001608:	7902                	ld	s2,32(sp)
    8000160a:	69e2                	ld	s3,24(sp)
    8000160c:	6a42                	ld	s4,16(sp)
    8000160e:	6aa2                	ld	s5,8(sp)
    80001610:	6b02                	ld	s6,0(sp)
    80001612:	6121                	addi	sp,sp,64
    80001614:	8082                	ret
            dec_ref(mem);
    80001616:	8526                	mv	a0,s1
    80001618:	00000097          	auipc	ra,0x0
    8000161c:	de8080e7          	jalr	-536(ra) # 80001400 <dec_ref>
            uvmdealloc(pagetable, a, oldsz);
    80001620:	864e                	mv	a2,s3
    80001622:	85ca                	mv	a1,s2
    80001624:	8556                	mv	a0,s5
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	f1a080e7          	jalr	-230(ra) # 80001540 <uvmdealloc>
            return 0;
    8000162e:	4501                	li	a0,0
    80001630:	bfc9                	j	80001602 <uvmalloc+0x7a>
        return oldsz;
    80001632:	852e                	mv	a0,a1
}
    80001634:	8082                	ret
    return newsz;
    80001636:	8532                	mv	a0,a2
    80001638:	b7e9                	j	80001602 <uvmalloc+0x7a>

000000008000163a <freewalk>:
{
    8000163a:	7179                	addi	sp,sp,-48
    8000163c:	f406                	sd	ra,40(sp)
    8000163e:	f022                	sd	s0,32(sp)
    80001640:	ec26                	sd	s1,24(sp)
    80001642:	e84a                	sd	s2,16(sp)
    80001644:	e44e                	sd	s3,8(sp)
    80001646:	e052                	sd	s4,0(sp)
    80001648:	1800                	addi	s0,sp,48
    8000164a:	8a2a                	mv	s4,a0
    for (int i = 0; i < 512; i++)
    8000164c:	84aa                	mv	s1,a0
    8000164e:	6905                	lui	s2,0x1
    80001650:	992a                	add	s2,s2,a0
        if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001652:	4985                	li	s3,1
    80001654:	a829                	j	8000166e <freewalk+0x34>
            uint64 child = PTE2PA(pte);
    80001656:	83a9                	srli	a5,a5,0xa
            freewalk((pagetable_t)child);
    80001658:	00c79513          	slli	a0,a5,0xc
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	fde080e7          	jalr	-34(ra) # 8000163a <freewalk>
            pagetable[i] = 0;
    80001664:	0004b023          	sd	zero,0(s1)
    for (int i = 0; i < 512; i++)
    80001668:	04a1                	addi	s1,s1,8
    8000166a:	03248163          	beq	s1,s2,8000168c <freewalk+0x52>
        pte_t pte = pagetable[i];
    8000166e:	609c                	ld	a5,0(s1)
        if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001670:	00f7f713          	andi	a4,a5,15
    80001674:	ff3701e3          	beq	a4,s3,80001656 <freewalk+0x1c>
        else if (pte & PTE_V)
    80001678:	8b85                	andi	a5,a5,1
    8000167a:	d7fd                	beqz	a5,80001668 <freewalk+0x2e>
            panic("freewalk: leaf");
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	b8c50513          	addi	a0,a0,-1140 # 80008208 <digits+0x1b8>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	eb8080e7          	jalr	-328(ra) # 8000053c <panic>
    dec_ref((void *)pagetable);
    8000168c:	8552                	mv	a0,s4
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	d72080e7          	jalr	-654(ra) # 80001400 <dec_ref>
}
    80001696:	70a2                	ld	ra,40(sp)
    80001698:	7402                	ld	s0,32(sp)
    8000169a:	64e2                	ld	s1,24(sp)
    8000169c:	6942                	ld	s2,16(sp)
    8000169e:	69a2                	ld	s3,8(sp)
    800016a0:	6a02                	ld	s4,0(sp)
    800016a2:	6145                	addi	sp,sp,48
    800016a4:	8082                	ret

00000000800016a6 <uvmfree>:
{
    800016a6:	1101                	addi	sp,sp,-32
    800016a8:	ec06                	sd	ra,24(sp)
    800016aa:	e822                	sd	s0,16(sp)
    800016ac:	e426                	sd	s1,8(sp)
    800016ae:	1000                	addi	s0,sp,32
    800016b0:	84aa                	mv	s1,a0
    if (sz > 0)
    800016b2:	e999                	bnez	a1,800016c8 <uvmfree+0x22>
    freewalk(pagetable);
    800016b4:	8526                	mv	a0,s1
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	f84080e7          	jalr	-124(ra) # 8000163a <freewalk>
}
    800016be:	60e2                	ld	ra,24(sp)
    800016c0:	6442                	ld	s0,16(sp)
    800016c2:	64a2                	ld	s1,8(sp)
    800016c4:	6105                	addi	sp,sp,32
    800016c6:	8082                	ret
        uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800016c8:	6785                	lui	a5,0x1
    800016ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016cc:	95be                	add	a1,a1,a5
    800016ce:	4685                	li	a3,1
    800016d0:	00c5d613          	srli	a2,a1,0xc
    800016d4:	4581                	li	a1,0
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	da6080e7          	jalr	-602(ra) # 8000147c <uvmunmap>
    800016de:	bfd9                	j	800016b4 <uvmfree+0xe>

00000000800016e0 <uvmcopy>:
{
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE)
    800016e0:	ce61                	beqz	a2,800017b8 <uvmcopy+0xd8>
{
    800016e2:	7139                	addi	sp,sp,-64
    800016e4:	fc06                	sd	ra,56(sp)
    800016e6:	f822                	sd	s0,48(sp)
    800016e8:	f426                	sd	s1,40(sp)
    800016ea:	f04a                	sd	s2,32(sp)
    800016ec:	ec4e                	sd	s3,24(sp)
    800016ee:	e852                	sd	s4,16(sp)
    800016f0:	e456                	sd	s5,8(sp)
    800016f2:	e05a                	sd	s6,0(sp)
    800016f4:	0080                	addi	s0,sp,64
    800016f6:	8a2a                	mv	s4,a0
    800016f8:	8aae                	mv	s5,a1
    800016fa:	8b32                	mv	s6,a2
    for (i = 0; i < sz; i += PGSIZE)
    800016fc:	4901                	li	s2,0
    {
        if ((pte = walk(old, i, 0)) == 0)
    800016fe:	4601                	li	a2,0
    80001700:	85ca                	mv	a1,s2
    80001702:	8552                	mv	a0,s4
    80001704:	00000097          	auipc	ra,0x0
    80001708:	968080e7          	jalr	-1688(ra) # 8000106c <walk>
    8000170c:	c135                	beqz	a0,80001770 <uvmcopy+0x90>
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0)
    8000170e:	6118                	ld	a4,0(a0)
    80001710:	00177793          	andi	a5,a4,1
    80001714:	c7b5                	beqz	a5,80001780 <uvmcopy+0xa0>
            panic("uvmcopy: page not present");
        pa = PTE2PA(*pte);
    80001716:	00a75993          	srli	s3,a4,0xa
    8000171a:	09b2                	slli	s3,s3,0xc
        flags = PTE_FLAGS(*pte);
        flags &= (~PTE_W);
    8000171c:	3fb77713          	andi	a4,a4,1019
        flags |= PTE_COW;

        // map pages to child
        if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001720:	02076493          	ori	s1,a4,32
    80001724:	8726                	mv	a4,s1
    80001726:	86ce                	mv	a3,s3
    80001728:	6605                	lui	a2,0x1
    8000172a:	85ca                	mv	a1,s2
    8000172c:	8556                	mv	a0,s5
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	a34080e7          	jalr	-1484(ra) # 80001162 <mappages>
    80001736:	ed29                	bnez	a0,80001790 <uvmcopy+0xb0>
        {
            goto err;
        }

        inc_ref((void *) pa);
    80001738:	854e                	mv	a0,s3
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	c8e080e7          	jalr	-882(ra) # 800013c8 <inc_ref>
        uvmunmap(old, i, 1, 0); // we are handling only one page - so only remove that mapping
    80001742:	4681                	li	a3,0
    80001744:	4605                	li	a2,1
    80001746:	85ca                	mv	a1,s2
    80001748:	8552                	mv	a0,s4
    8000174a:	00000097          	auipc	ra,0x0
    8000174e:	d32080e7          	jalr	-718(ra) # 8000147c <uvmunmap>
        if (mappages(old, i, PGSIZE, pa, flags) != 0)
    80001752:	8726                	mv	a4,s1
    80001754:	86ce                	mv	a3,s3
    80001756:	6605                	lui	a2,0x1
    80001758:	85ca                	mv	a1,s2
    8000175a:	8552                	mv	a0,s4
    8000175c:	00000097          	auipc	ra,0x0
    80001760:	a06080e7          	jalr	-1530(ra) # 80001162 <mappages>
    80001764:	e515                	bnez	a0,80001790 <uvmcopy+0xb0>
    for (i = 0; i < sz; i += PGSIZE)
    80001766:	6785                	lui	a5,0x1
    80001768:	993e                	add	s2,s2,a5
    8000176a:	f9696ae3          	bltu	s2,s6,800016fe <uvmcopy+0x1e>
    8000176e:	a81d                	j	800017a4 <uvmcopy+0xc4>
            panic("uvmcopy: pte should exist");
    80001770:	00007517          	auipc	a0,0x7
    80001774:	aa850513          	addi	a0,a0,-1368 # 80008218 <digits+0x1c8>
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	dc4080e7          	jalr	-572(ra) # 8000053c <panic>
            panic("uvmcopy: page not present");
    80001780:	00007517          	auipc	a0,0x7
    80001784:	ab850513          	addi	a0,a0,-1352 # 80008238 <digits+0x1e8>
    80001788:	fffff097          	auipc	ra,0xfffff
    8000178c:	db4080e7          	jalr	-588(ra) # 8000053c <panic>
            goto err;
    }
    return 0;

err:
    uvmunmap(new, 0, i / PGSIZE, 1);
    80001790:	4685                	li	a3,1
    80001792:	00c95613          	srli	a2,s2,0xc
    80001796:	4581                	li	a1,0
    80001798:	8556                	mv	a0,s5
    8000179a:	00000097          	auipc	ra,0x0
    8000179e:	ce2080e7          	jalr	-798(ra) # 8000147c <uvmunmap>
    return -1;
    800017a2:	557d                	li	a0,-1
}
    800017a4:	70e2                	ld	ra,56(sp)
    800017a6:	7442                	ld	s0,48(sp)
    800017a8:	74a2                	ld	s1,40(sp)
    800017aa:	7902                	ld	s2,32(sp)
    800017ac:	69e2                	ld	s3,24(sp)
    800017ae:	6a42                	ld	s4,16(sp)
    800017b0:	6aa2                	ld	s5,8(sp)
    800017b2:	6b02                	ld	s6,0(sp)
    800017b4:	6121                	addi	sp,sp,64
    800017b6:	8082                	ret
    return 0;
    800017b8:	4501                	li	a0,0
}
    800017ba:	8082                	ret

00000000800017bc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    800017bc:	1141                	addi	sp,sp,-16
    800017be:	e406                	sd	ra,8(sp)
    800017c0:	e022                	sd	s0,0(sp)
    800017c2:	0800                	addi	s0,sp,16
    pte_t *pte;

    pte = walk(pagetable, va, 0);
    800017c4:	4601                	li	a2,0
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	8a6080e7          	jalr	-1882(ra) # 8000106c <walk>
    if (pte == 0)
    800017ce:	c901                	beqz	a0,800017de <uvmclear+0x22>
        panic("uvmclear");
    *pte &= ~PTE_U;
    800017d0:	611c                	ld	a5,0(a0)
    800017d2:	9bbd                	andi	a5,a5,-17
    800017d4:	e11c                	sd	a5,0(a0)
}
    800017d6:	60a2                	ld	ra,8(sp)
    800017d8:	6402                	ld	s0,0(sp)
    800017da:	0141                	addi	sp,sp,16
    800017dc:	8082                	ret
        panic("uvmclear");
    800017de:	00007517          	auipc	a0,0x7
    800017e2:	a7a50513          	addi	a0,a0,-1414 # 80008258 <digits+0x208>
    800017e6:	fffff097          	auipc	ra,0xfffff
    800017ea:	d56080e7          	jalr	-682(ra) # 8000053c <panic>

00000000800017ee <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    uint64 n, va0, pa0, pf0;

    while (len > 0)
    800017ee:	10068763          	beqz	a3,800018fc <copyout+0x10e>
{
    800017f2:	7159                	addi	sp,sp,-112
    800017f4:	f486                	sd	ra,104(sp)
    800017f6:	f0a2                	sd	s0,96(sp)
    800017f8:	eca6                	sd	s1,88(sp)
    800017fa:	e8ca                	sd	s2,80(sp)
    800017fc:	e4ce                	sd	s3,72(sp)
    800017fe:	e0d2                	sd	s4,64(sp)
    80001800:	fc56                	sd	s5,56(sp)
    80001802:	f85a                	sd	s6,48(sp)
    80001804:	f45e                	sd	s7,40(sp)
    80001806:	f062                	sd	s8,32(sp)
    80001808:	ec66                	sd	s9,24(sp)
    8000180a:	e86a                	sd	s10,16(sp)
    8000180c:	1880                	addi	s0,sp,112
    8000180e:	8c2a                	mv	s8,a0
    80001810:	8b2e                	mv	s6,a1
    80001812:	8cb2                	mv	s9,a2
    80001814:	8ab6                	mv	s5,a3
    {
        va0 = PGROUNDDOWN(dstva);
    80001816:	7d7d                	lui	s10,0xfffff
        pa0 = walkaddrf(pagetable, va0, &pf0);
        if (pa0 == 0)
            return -1;
        n = PGSIZE - (dstva - va0);
    80001818:	6b85                	lui	s7,0x1
    8000181a:	a099                	j	80001860 <copyout+0x72>
        if (n > len)
            n = len;
        if (pf0 & PTE_COW)
    8000181c:	f9843983          	ld	s3,-104(s0)
    80001820:	0209f793          	andi	a5,s3,32
    80001824:	cfd5                	beqz	a5,800018e0 <copyout+0xf2>
        {
            assert(!(pf0 & PTE_W));
    80001826:	0049f793          	andi	a5,s3,4
    8000182a:	efb1                	bnez	a5,80001886 <copyout+0x98>
            uvmunmap(pagetable, va0, 1, 1);
    8000182c:	4685                	li	a3,1
    8000182e:	4605                	li	a2,1
    80001830:	85d2                	mv	a1,s4
    80001832:	8562                	mv	a0,s8
    80001834:	00000097          	auipc	ra,0x0
    80001838:	c48080e7          	jalr	-952(ra) # 8000147c <uvmunmap>
            if (mappages(pagetable, va0, PGSIZE, pa0, pf0) != 0)
    8000183c:	0009871b          	sext.w	a4,s3
    80001840:	86ca                	mv	a3,s2
    80001842:	865e                	mv	a2,s7
    80001844:	85d2                	mv	a1,s4
    80001846:	8562                	mv	a0,s8
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	91a080e7          	jalr	-1766(ra) # 80001162 <mappages>
    80001850:	e52d                	bnez	a0,800018ba <copyout+0xcc>
        }
        else
        {
            memmove((void *)(pa0 + (dstva - va0)), src, n);
        }
        len -= n;
    80001852:	409a8ab3          	sub	s5,s5,s1
        src += n;
    80001856:	9ca6                	add	s9,s9,s1
        dstva = va0 + PGSIZE;
    80001858:	017a0b33          	add	s6,s4,s7
    while (len > 0)
    8000185c:	080a8e63          	beqz	s5,800018f8 <copyout+0x10a>
        va0 = PGROUNDDOWN(dstva);
    80001860:	01ab7a33          	and	s4,s6,s10
        pa0 = walkaddrf(pagetable, va0, &pf0);
    80001864:	f9840613          	addi	a2,s0,-104
    80001868:	85d2                	mv	a1,s4
    8000186a:	8562                	mv	a0,s8
    8000186c:	00000097          	auipc	ra,0x0
    80001870:	8a6080e7          	jalr	-1882(ra) # 80001112 <walkaddrf>
    80001874:	892a                	mv	s2,a0
        if (pa0 == 0)
    80001876:	c549                	beqz	a0,80001900 <copyout+0x112>
        n = PGSIZE - (dstva - va0);
    80001878:	416a04b3          	sub	s1,s4,s6
    8000187c:	94de                	add	s1,s1,s7
    8000187e:	f89affe3          	bgeu	s5,s1,8000181c <copyout+0x2e>
    80001882:	84d6                	mv	s1,s5
    80001884:	bf61                	j	8000181c <copyout+0x2e>
            assert(!(pf0 & PTE_W));
    80001886:	1a100693          	li	a3,417
    8000188a:	00006617          	auipc	a2,0x6
    8000188e:	78660613          	addi	a2,a2,1926 # 80008010 <__func__.0>
    80001892:	00007597          	auipc	a1,0x7
    80001896:	9d658593          	addi	a1,a1,-1578 # 80008268 <digits+0x218>
    8000189a:	00006517          	auipc	a0,0x6
    8000189e:	7ee50513          	addi	a0,a0,2030 # 80008088 <digits+0x38>
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	ce4080e7          	jalr	-796(ra) # 80000586 <printf>
    800018aa:	00006517          	auipc	a0,0x6
    800018ae:	7ee50513          	addi	a0,a0,2030 # 80008098 <digits+0x48>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c8a080e7          	jalr	-886(ra) # 8000053c <panic>
                printf("Mapping 0x%x to 0x%x in pt %d", pa0, va0, pagetable);
    800018ba:	86e2                	mv	a3,s8
    800018bc:	8652                	mv	a2,s4
    800018be:	85ca                	mv	a1,s2
    800018c0:	00007517          	auipc	a0,0x7
    800018c4:	9b850513          	addi	a0,a0,-1608 # 80008278 <digits+0x228>
    800018c8:	fffff097          	auipc	ra,0xfffff
    800018cc:	cbe080e7          	jalr	-834(ra) # 80000586 <printf>
                panic("Couldn't map cow page to user process.");
    800018d0:	00007517          	auipc	a0,0x7
    800018d4:	9c850513          	addi	a0,a0,-1592 # 80008298 <digits+0x248>
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	c64080e7          	jalr	-924(ra) # 8000053c <panic>
            memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018e0:	01690533          	add	a0,s2,s6
    800018e4:	0004861b          	sext.w	a2,s1
    800018e8:	85e6                	mv	a1,s9
    800018ea:	41450533          	sub	a0,a0,s4
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	4f8080e7          	jalr	1272(ra) # 80000de6 <memmove>
    800018f6:	bfb1                	j	80001852 <copyout+0x64>
    }
    return 0;
    800018f8:	4501                	li	a0,0
    800018fa:	a021                	j	80001902 <copyout+0x114>
    800018fc:	4501                	li	a0,0
}
    800018fe:	8082                	ret
            return -1;
    80001900:	557d                	li	a0,-1
}
    80001902:	70a6                	ld	ra,104(sp)
    80001904:	7406                	ld	s0,96(sp)
    80001906:	64e6                	ld	s1,88(sp)
    80001908:	6946                	ld	s2,80(sp)
    8000190a:	69a6                	ld	s3,72(sp)
    8000190c:	6a06                	ld	s4,64(sp)
    8000190e:	7ae2                	ld	s5,56(sp)
    80001910:	7b42                	ld	s6,48(sp)
    80001912:	7ba2                	ld	s7,40(sp)
    80001914:	7c02                	ld	s8,32(sp)
    80001916:	6ce2                	ld	s9,24(sp)
    80001918:	6d42                	ld	s10,16(sp)
    8000191a:	6165                	addi	sp,sp,112
    8000191c:	8082                	ret

000000008000191e <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    uint64 n, va0, pa0;

    while (len > 0)
    8000191e:	caad                	beqz	a3,80001990 <copyin+0x72>
{
    80001920:	715d                	addi	sp,sp,-80
    80001922:	e486                	sd	ra,72(sp)
    80001924:	e0a2                	sd	s0,64(sp)
    80001926:	fc26                	sd	s1,56(sp)
    80001928:	f84a                	sd	s2,48(sp)
    8000192a:	f44e                	sd	s3,40(sp)
    8000192c:	f052                	sd	s4,32(sp)
    8000192e:	ec56                	sd	s5,24(sp)
    80001930:	e85a                	sd	s6,16(sp)
    80001932:	e45e                	sd	s7,8(sp)
    80001934:	e062                	sd	s8,0(sp)
    80001936:	0880                	addi	s0,sp,80
    80001938:	8b2a                	mv	s6,a0
    8000193a:	8a2e                	mv	s4,a1
    8000193c:	8c32                	mv	s8,a2
    8000193e:	89b6                	mv	s3,a3
    {
        va0 = PGROUNDDOWN(srcva);
    80001940:	7bfd                	lui	s7,0xfffff
        pa0 = walkaddr(pagetable, va0);
        if (pa0 == 0)
            return -1;
        n = PGSIZE - (srcva - va0);
    80001942:	6a85                	lui	s5,0x1
    80001944:	a01d                	j	8000196a <copyin+0x4c>
        if (n > len)
            n = len;
        memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001946:	018505b3          	add	a1,a0,s8
    8000194a:	0004861b          	sext.w	a2,s1
    8000194e:	412585b3          	sub	a1,a1,s2
    80001952:	8552                	mv	a0,s4
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	492080e7          	jalr	1170(ra) # 80000de6 <memmove>

        len -= n;
    8000195c:	409989b3          	sub	s3,s3,s1
        dst += n;
    80001960:	9a26                	add	s4,s4,s1
        srcva = va0 + PGSIZE;
    80001962:	01590c33          	add	s8,s2,s5
    while (len > 0)
    80001966:	02098363          	beqz	s3,8000198c <copyin+0x6e>
        va0 = PGROUNDDOWN(srcva);
    8000196a:	017c7933          	and	s2,s8,s7
        pa0 = walkaddr(pagetable, va0);
    8000196e:	4601                	li	a2,0
    80001970:	85ca                	mv	a1,s2
    80001972:	855a                	mv	a0,s6
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	79e080e7          	jalr	1950(ra) # 80001112 <walkaddrf>
        if (pa0 == 0)
    8000197c:	cd01                	beqz	a0,80001994 <copyin+0x76>
        n = PGSIZE - (srcva - va0);
    8000197e:	418904b3          	sub	s1,s2,s8
    80001982:	94d6                	add	s1,s1,s5
    80001984:	fc99f1e3          	bgeu	s3,s1,80001946 <copyin+0x28>
    80001988:	84ce                	mv	s1,s3
    8000198a:	bf75                	j	80001946 <copyin+0x28>
    }
    return 0;
    8000198c:	4501                	li	a0,0
    8000198e:	a021                	j	80001996 <copyin+0x78>
    80001990:	4501                	li	a0,0
}
    80001992:	8082                	ret
            return -1;
    80001994:	557d                	li	a0,-1
}
    80001996:	60a6                	ld	ra,72(sp)
    80001998:	6406                	ld	s0,64(sp)
    8000199a:	74e2                	ld	s1,56(sp)
    8000199c:	7942                	ld	s2,48(sp)
    8000199e:	79a2                	ld	s3,40(sp)
    800019a0:	7a02                	ld	s4,32(sp)
    800019a2:	6ae2                	ld	s5,24(sp)
    800019a4:	6b42                	ld	s6,16(sp)
    800019a6:	6ba2                	ld	s7,8(sp)
    800019a8:	6c02                	ld	s8,0(sp)
    800019aa:	6161                	addi	sp,sp,80
    800019ac:	8082                	ret

00000000800019ae <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    uint64 n, va0, pa0;
    int got_null = 0;

    while (got_null == 0 && max > 0)
    800019ae:	c6c5                	beqz	a3,80001a56 <copyinstr+0xa8>
{
    800019b0:	715d                	addi	sp,sp,-80
    800019b2:	e486                	sd	ra,72(sp)
    800019b4:	e0a2                	sd	s0,64(sp)
    800019b6:	fc26                	sd	s1,56(sp)
    800019b8:	f84a                	sd	s2,48(sp)
    800019ba:	f44e                	sd	s3,40(sp)
    800019bc:	f052                	sd	s4,32(sp)
    800019be:	ec56                	sd	s5,24(sp)
    800019c0:	e85a                	sd	s6,16(sp)
    800019c2:	e45e                	sd	s7,8(sp)
    800019c4:	0880                	addi	s0,sp,80
    800019c6:	8a2a                	mv	s4,a0
    800019c8:	8b2e                	mv	s6,a1
    800019ca:	8bb2                	mv	s7,a2
    800019cc:	84b6                	mv	s1,a3
    {
        va0 = PGROUNDDOWN(srcva);
    800019ce:	7afd                	lui	s5,0xfffff
        pa0 = walkaddr(pagetable, va0);
        if (pa0 == 0)
            return -1;
        n = PGSIZE - (srcva - va0);
    800019d0:	6985                	lui	s3,0x1
    800019d2:	a02d                	j	800019fc <copyinstr+0x4e>
        char *p = (char *)(pa0 + (srcva - va0));
        while (n > 0)
        {
            if (*p == '\0')
            {
                *dst = '\0';
    800019d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019d8:	4785                	li	a5,1
            dst++;
        }

        srcva = va0 + PGSIZE;
    }
    if (got_null)
    800019da:	37fd                	addiw	a5,a5,-1
    800019dc:	0007851b          	sext.w	a0,a5
    }
    else
    {
        return -1;
    }
}
    800019e0:	60a6                	ld	ra,72(sp)
    800019e2:	6406                	ld	s0,64(sp)
    800019e4:	74e2                	ld	s1,56(sp)
    800019e6:	7942                	ld	s2,48(sp)
    800019e8:	79a2                	ld	s3,40(sp)
    800019ea:	7a02                	ld	s4,32(sp)
    800019ec:	6ae2                	ld	s5,24(sp)
    800019ee:	6b42                	ld	s6,16(sp)
    800019f0:	6ba2                	ld	s7,8(sp)
    800019f2:	6161                	addi	sp,sp,80
    800019f4:	8082                	ret
        srcva = va0 + PGSIZE;
    800019f6:	01390bb3          	add	s7,s2,s3
    while (got_null == 0 && max > 0)
    800019fa:	c8b1                	beqz	s1,80001a4e <copyinstr+0xa0>
        va0 = PGROUNDDOWN(srcva);
    800019fc:	015bf933          	and	s2,s7,s5
        pa0 = walkaddr(pagetable, va0);
    80001a00:	4601                	li	a2,0
    80001a02:	85ca                	mv	a1,s2
    80001a04:	8552                	mv	a0,s4
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	70c080e7          	jalr	1804(ra) # 80001112 <walkaddrf>
        if (pa0 == 0)
    80001a0e:	c131                	beqz	a0,80001a52 <copyinstr+0xa4>
        n = PGSIZE - (srcva - va0);
    80001a10:	417906b3          	sub	a3,s2,s7
    80001a14:	96ce                	add	a3,a3,s3
    80001a16:	00d4f363          	bgeu	s1,a3,80001a1c <copyinstr+0x6e>
    80001a1a:	86a6                	mv	a3,s1
        char *p = (char *)(pa0 + (srcva - va0));
    80001a1c:	955e                	add	a0,a0,s7
    80001a1e:	41250533          	sub	a0,a0,s2
        while (n > 0)
    80001a22:	daf1                	beqz	a3,800019f6 <copyinstr+0x48>
    80001a24:	87da                	mv	a5,s6
    80001a26:	885a                	mv	a6,s6
            if (*p == '\0')
    80001a28:	41650633          	sub	a2,a0,s6
        while (n > 0)
    80001a2c:	96da                	add	a3,a3,s6
    80001a2e:	85be                	mv	a1,a5
            if (*p == '\0')
    80001a30:	00f60733          	add	a4,a2,a5
    80001a34:	00074703          	lbu	a4,0(a4)
    80001a38:	df51                	beqz	a4,800019d4 <copyinstr+0x26>
                *dst = *p;
    80001a3a:	00e78023          	sb	a4,0(a5)
            dst++;
    80001a3e:	0785                	addi	a5,a5,1
        while (n > 0)
    80001a40:	fed797e3          	bne	a5,a3,80001a2e <copyinstr+0x80>
    80001a44:	14fd                	addi	s1,s1,-1
    80001a46:	94c2                	add	s1,s1,a6
            --max;
    80001a48:	8c8d                	sub	s1,s1,a1
            dst++;
    80001a4a:	8b3e                	mv	s6,a5
    80001a4c:	b76d                	j	800019f6 <copyinstr+0x48>
    80001a4e:	4781                	li	a5,0
    80001a50:	b769                	j	800019da <copyinstr+0x2c>
            return -1;
    80001a52:	557d                	li	a0,-1
    80001a54:	b771                	j	800019e0 <copyinstr+0x32>
    int got_null = 0;
    80001a56:	4781                	li	a5,0
    if (got_null)
    80001a58:	37fd                	addiw	a5,a5,-1
    80001a5a:	0007851b          	sext.w	a0,a5
}
    80001a5e:	8082                	ret

0000000080001a60 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001a60:	715d                	addi	sp,sp,-80
    80001a62:	e486                	sd	ra,72(sp)
    80001a64:	e0a2                	sd	s0,64(sp)
    80001a66:	fc26                	sd	s1,56(sp)
    80001a68:	f84a                	sd	s2,48(sp)
    80001a6a:	f44e                	sd	s3,40(sp)
    80001a6c:	f052                	sd	s4,32(sp)
    80001a6e:	ec56                	sd	s5,24(sp)
    80001a70:	e85a                	sd	s6,16(sp)
    80001a72:	e45e                	sd	s7,8(sp)
    80001a74:	e062                	sd	s8,0(sp)
    80001a76:	0880                	addi	s0,sp,80
    asm volatile("mv %0, tp"
    80001a78:	8792                	mv	a5,tp
    int id = r_tp();
    80001a7a:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001a7c:	0011fa97          	auipc	s5,0x11f
    80001a80:	2f4a8a93          	addi	s5,s5,756 # 80120d70 <cpus>
    80001a84:	00779713          	slli	a4,a5,0x7
    80001a88:	00ea86b3          	add	a3,s5,a4
    80001a8c:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fecd080>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001a90:	0721                	addi	a4,a4,8
    80001a92:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001a94:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001a96:	00007c17          	auipc	s8,0x7
    80001a9a:	fb2c0c13          	addi	s8,s8,-78 # 80008a48 <sched_pointer>
    80001a9e:	00000b97          	auipc	s7,0x0
    80001aa2:	fc2b8b93          	addi	s7,s7,-62 # 80001a60 <rr_scheduler>
    asm volatile("csrr %0, sstatus"
    80001aa6:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001aaa:	0027e793          	ori	a5,a5,2
    asm volatile("csrw sstatus, %0"
    80001aae:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001ab2:	0011f497          	auipc	s1,0x11f
    80001ab6:	6ee48493          	addi	s1,s1,1774 # 801211a0 <proc>
            if (p->state == RUNNABLE)
    80001aba:	498d                	li	s3,3
                p->state = RUNNING;
    80001abc:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001abe:	00125a17          	auipc	s4,0x125
    80001ac2:	0e2a0a13          	addi	s4,s4,226 # 80126ba0 <tickslock>
    80001ac6:	a81d                	j	80001afc <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001ac8:	8526                	mv	a0,s1
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	278080e7          	jalr	632(ra) # 80000d42 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001ad2:	60a6                	ld	ra,72(sp)
    80001ad4:	6406                	ld	s0,64(sp)
    80001ad6:	74e2                	ld	s1,56(sp)
    80001ad8:	7942                	ld	s2,48(sp)
    80001ada:	79a2                	ld	s3,40(sp)
    80001adc:	7a02                	ld	s4,32(sp)
    80001ade:	6ae2                	ld	s5,24(sp)
    80001ae0:	6b42                	ld	s6,16(sp)
    80001ae2:	6ba2                	ld	s7,8(sp)
    80001ae4:	6c02                	ld	s8,0(sp)
    80001ae6:	6161                	addi	sp,sp,80
    80001ae8:	8082                	ret
            release(&p->lock);
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	256080e7          	jalr	598(ra) # 80000d42 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001af4:	16848493          	addi	s1,s1,360
    80001af8:	fb4487e3          	beq	s1,s4,80001aa6 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001afc:	8526                	mv	a0,s1
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	190080e7          	jalr	400(ra) # 80000c8e <acquire>
            if (p->state == RUNNABLE)
    80001b06:	4c9c                	lw	a5,24(s1)
    80001b08:	ff3791e3          	bne	a5,s3,80001aea <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001b0c:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001b10:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001b14:	06048593          	addi	a1,s1,96
    80001b18:	8556                	mv	a0,s5
    80001b1a:	00001097          	auipc	ra,0x1
    80001b1e:	000080e7          	jalr	ra # 80002b1a <swtch>
                if (sched_pointer != &rr_scheduler)
    80001b22:	000c3783          	ld	a5,0(s8)
    80001b26:	fb7791e3          	bne	a5,s7,80001ac8 <rr_scheduler+0x68>
                c->proc = 0;
    80001b2a:	00093023          	sd	zero,0(s2)
    80001b2e:	bf75                	j	80001aea <rr_scheduler+0x8a>

0000000080001b30 <proc_mapstacks>:
{
    80001b30:	7139                	addi	sp,sp,-64
    80001b32:	fc06                	sd	ra,56(sp)
    80001b34:	f822                	sd	s0,48(sp)
    80001b36:	f426                	sd	s1,40(sp)
    80001b38:	f04a                	sd	s2,32(sp)
    80001b3a:	ec4e                	sd	s3,24(sp)
    80001b3c:	e852                	sd	s4,16(sp)
    80001b3e:	e456                	sd	s5,8(sp)
    80001b40:	e05a                	sd	s6,0(sp)
    80001b42:	0080                	addi	s0,sp,64
    80001b44:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001b46:	0011f497          	auipc	s1,0x11f
    80001b4a:	65a48493          	addi	s1,s1,1626 # 801211a0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b4e:	8b26                	mv	s6,s1
    80001b50:	00006a97          	auipc	s5,0x6
    80001b54:	4c8a8a93          	addi	s5,s5,1224 # 80008018 <__func__.0+0x8>
    80001b58:	04000937          	lui	s2,0x4000
    80001b5c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b5e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b60:	00125a17          	auipc	s4,0x125
    80001b64:	040a0a13          	addi	s4,s4,64 # 80126ba0 <tickslock>
        char *pa = kalloc();
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	fe0080e7          	jalr	-32(ra) # 80000b48 <kalloc>
    80001b70:	862a                	mv	a2,a0
        if (pa == 0)
    80001b72:	c131                	beqz	a0,80001bb6 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b74:	416485b3          	sub	a1,s1,s6
    80001b78:	858d                	srai	a1,a1,0x3
    80001b7a:	000ab783          	ld	a5,0(s5)
    80001b7e:	02f585b3          	mul	a1,a1,a5
    80001b82:	2585                	addiw	a1,a1,1
    80001b84:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b88:	4719                	li	a4,6
    80001b8a:	6685                	lui	a3,0x1
    80001b8c:	40b905b3          	sub	a1,s2,a1
    80001b90:	854e                	mv	a0,s3
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	670080e7          	jalr	1648(ra) # 80001202 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b9a:	16848493          	addi	s1,s1,360
    80001b9e:	fd4495e3          	bne	s1,s4,80001b68 <proc_mapstacks+0x38>
}
    80001ba2:	70e2                	ld	ra,56(sp)
    80001ba4:	7442                	ld	s0,48(sp)
    80001ba6:	74a2                	ld	s1,40(sp)
    80001ba8:	7902                	ld	s2,32(sp)
    80001baa:	69e2                	ld	s3,24(sp)
    80001bac:	6a42                	ld	s4,16(sp)
    80001bae:	6aa2                	ld	s5,8(sp)
    80001bb0:	6b02                	ld	s6,0(sp)
    80001bb2:	6121                	addi	sp,sp,64
    80001bb4:	8082                	ret
            panic("kalloc");
    80001bb6:	00006517          	auipc	a0,0x6
    80001bba:	70a50513          	addi	a0,a0,1802 # 800082c0 <digits+0x270>
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	97e080e7          	jalr	-1666(ra) # 8000053c <panic>

0000000080001bc6 <procinit>:
{
    80001bc6:	7139                	addi	sp,sp,-64
    80001bc8:	fc06                	sd	ra,56(sp)
    80001bca:	f822                	sd	s0,48(sp)
    80001bcc:	f426                	sd	s1,40(sp)
    80001bce:	f04a                	sd	s2,32(sp)
    80001bd0:	ec4e                	sd	s3,24(sp)
    80001bd2:	e852                	sd	s4,16(sp)
    80001bd4:	e456                	sd	s5,8(sp)
    80001bd6:	e05a                	sd	s6,0(sp)
    80001bd8:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001bda:	00006597          	auipc	a1,0x6
    80001bde:	6ee58593          	addi	a1,a1,1774 # 800082c8 <digits+0x278>
    80001be2:	0011f517          	auipc	a0,0x11f
    80001be6:	58e50513          	addi	a0,a0,1422 # 80121170 <pid_lock>
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	014080e7          	jalr	20(ra) # 80000bfe <initlock>
    initlock(&wait_lock, "wait_lock");
    80001bf2:	00006597          	auipc	a1,0x6
    80001bf6:	6de58593          	addi	a1,a1,1758 # 800082d0 <digits+0x280>
    80001bfa:	0011f517          	auipc	a0,0x11f
    80001bfe:	58e50513          	addi	a0,a0,1422 # 80121188 <wait_lock>
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	ffc080e7          	jalr	-4(ra) # 80000bfe <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c0a:	0011f497          	auipc	s1,0x11f
    80001c0e:	59648493          	addi	s1,s1,1430 # 801211a0 <proc>
        initlock(&p->lock, "proc");
    80001c12:	00006b17          	auipc	s6,0x6
    80001c16:	6ceb0b13          	addi	s6,s6,1742 # 800082e0 <digits+0x290>
        p->kstack = KSTACK((int)(p - proc));
    80001c1a:	8aa6                	mv	s5,s1
    80001c1c:	00006a17          	auipc	s4,0x6
    80001c20:	3fca0a13          	addi	s4,s4,1020 # 80008018 <__func__.0+0x8>
    80001c24:	04000937          	lui	s2,0x4000
    80001c28:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c2a:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c2c:	00125997          	auipc	s3,0x125
    80001c30:	f7498993          	addi	s3,s3,-140 # 80126ba0 <tickslock>
        initlock(&p->lock, "proc");
    80001c34:	85da                	mv	a1,s6
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	fc6080e7          	jalr	-58(ra) # 80000bfe <initlock>
        p->state = UNUSED;
    80001c40:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001c44:	415487b3          	sub	a5,s1,s5
    80001c48:	878d                	srai	a5,a5,0x3
    80001c4a:	000a3703          	ld	a4,0(s4)
    80001c4e:	02e787b3          	mul	a5,a5,a4
    80001c52:	2785                	addiw	a5,a5,1
    80001c54:	00d7979b          	slliw	a5,a5,0xd
    80001c58:	40f907b3          	sub	a5,s2,a5
    80001c5c:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c5e:	16848493          	addi	s1,s1,360
    80001c62:	fd3499e3          	bne	s1,s3,80001c34 <procinit+0x6e>
}
    80001c66:	70e2                	ld	ra,56(sp)
    80001c68:	7442                	ld	s0,48(sp)
    80001c6a:	74a2                	ld	s1,40(sp)
    80001c6c:	7902                	ld	s2,32(sp)
    80001c6e:	69e2                	ld	s3,24(sp)
    80001c70:	6a42                	ld	s4,16(sp)
    80001c72:	6aa2                	ld	s5,8(sp)
    80001c74:	6b02                	ld	s6,0(sp)
    80001c76:	6121                	addi	sp,sp,64
    80001c78:	8082                	ret

0000000080001c7a <copy_array>:
{
    80001c7a:	1141                	addi	sp,sp,-16
    80001c7c:	e422                	sd	s0,8(sp)
    80001c7e:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c80:	00c05c63          	blez	a2,80001c98 <copy_array+0x1e>
    80001c84:	87aa                	mv	a5,a0
    80001c86:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001c88:	0007c703          	lbu	a4,0(a5)
    80001c8c:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c90:	0785                	addi	a5,a5,1
    80001c92:	0585                	addi	a1,a1,1
    80001c94:	fea79ae3          	bne	a5,a0,80001c88 <copy_array+0xe>
}
    80001c98:	6422                	ld	s0,8(sp)
    80001c9a:	0141                	addi	sp,sp,16
    80001c9c:	8082                	ret

0000000080001c9e <cpuid>:
{
    80001c9e:	1141                	addi	sp,sp,-16
    80001ca0:	e422                	sd	s0,8(sp)
    80001ca2:	0800                	addi	s0,sp,16
    asm volatile("mv %0, tp"
    80001ca4:	8512                	mv	a0,tp
}
    80001ca6:	2501                	sext.w	a0,a0
    80001ca8:	6422                	ld	s0,8(sp)
    80001caa:	0141                	addi	sp,sp,16
    80001cac:	8082                	ret

0000000080001cae <mycpu>:
{
    80001cae:	1141                	addi	sp,sp,-16
    80001cb0:	e422                	sd	s0,8(sp)
    80001cb2:	0800                	addi	s0,sp,16
    80001cb4:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001cb6:	2781                	sext.w	a5,a5
    80001cb8:	079e                	slli	a5,a5,0x7
}
    80001cba:	0011f517          	auipc	a0,0x11f
    80001cbe:	0b650513          	addi	a0,a0,182 # 80120d70 <cpus>
    80001cc2:	953e                	add	a0,a0,a5
    80001cc4:	6422                	ld	s0,8(sp)
    80001cc6:	0141                	addi	sp,sp,16
    80001cc8:	8082                	ret

0000000080001cca <myproc>:
{
    80001cca:	1101                	addi	sp,sp,-32
    80001ccc:	ec06                	sd	ra,24(sp)
    80001cce:	e822                	sd	s0,16(sp)
    80001cd0:	e426                	sd	s1,8(sp)
    80001cd2:	1000                	addi	s0,sp,32
    push_off();
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	f6e080e7          	jalr	-146(ra) # 80000c42 <push_off>
    80001cdc:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001cde:	2781                	sext.w	a5,a5
    80001ce0:	079e                	slli	a5,a5,0x7
    80001ce2:	0011f717          	auipc	a4,0x11f
    80001ce6:	08e70713          	addi	a4,a4,142 # 80120d70 <cpus>
    80001cea:	97ba                	add	a5,a5,a4
    80001cec:	6384                	ld	s1,0(a5)
    pop_off();
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	ff4080e7          	jalr	-12(ra) # 80000ce2 <pop_off>
}
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	60e2                	ld	ra,24(sp)
    80001cfa:	6442                	ld	s0,16(sp)
    80001cfc:	64a2                	ld	s1,8(sp)
    80001cfe:	6105                	addi	sp,sp,32
    80001d00:	8082                	ret

0000000080001d02 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d02:	1141                	addi	sp,sp,-16
    80001d04:	e406                	sd	ra,8(sp)
    80001d06:	e022                	sd	s0,0(sp)
    80001d08:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	fc0080e7          	jalr	-64(ra) # 80001cca <myproc>
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	030080e7          	jalr	48(ra) # 80000d42 <release>

    if (first)
    80001d1a:	00007797          	auipc	a5,0x7
    80001d1e:	d267a783          	lw	a5,-730(a5) # 80008a40 <first.1>
    80001d22:	eb89                	bnez	a5,80001d34 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001d24:	00001097          	auipc	ra,0x1
    80001d28:	ea0080e7          	jalr	-352(ra) # 80002bc4 <usertrapret>
}
    80001d2c:	60a2                	ld	ra,8(sp)
    80001d2e:	6402                	ld	s0,0(sp)
    80001d30:	0141                	addi	sp,sp,16
    80001d32:	8082                	ret
        first = 0;
    80001d34:	00007797          	auipc	a5,0x7
    80001d38:	d007a623          	sw	zero,-756(a5) # 80008a40 <first.1>
        fsinit(ROOTDEV);
    80001d3c:	4505                	li	a0,1
    80001d3e:	00002097          	auipc	ra,0x2
    80001d42:	dc6080e7          	jalr	-570(ra) # 80003b04 <fsinit>
    80001d46:	bff9                	j	80001d24 <forkret+0x22>

0000000080001d48 <allocpid>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	e04a                	sd	s2,0(sp)
    80001d52:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d54:	0011f917          	auipc	s2,0x11f
    80001d58:	41c90913          	addi	s2,s2,1052 # 80121170 <pid_lock>
    80001d5c:	854a                	mv	a0,s2
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	f30080e7          	jalr	-208(ra) # 80000c8e <acquire>
    pid = nextpid;
    80001d66:	00007797          	auipc	a5,0x7
    80001d6a:	cea78793          	addi	a5,a5,-790 # 80008a50 <nextpid>
    80001d6e:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d70:	0014871b          	addiw	a4,s1,1
    80001d74:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d76:	854a                	mv	a0,s2
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	fca080e7          	jalr	-54(ra) # 80000d42 <release>
}
    80001d80:	8526                	mv	a0,s1
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6902                	ld	s2,0(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <proc_pagetable>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    80001d9a:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	58c080e7          	jalr	1420(ra) # 80001328 <uvmcreate>
    80001da4:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001da6:	c121                	beqz	a0,80001de6 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001da8:	4729                	li	a4,10
    80001daa:	00005697          	auipc	a3,0x5
    80001dae:	25668693          	addi	a3,a3,598 # 80007000 <_trampoline>
    80001db2:	6605                	lui	a2,0x1
    80001db4:	040005b7          	lui	a1,0x4000
    80001db8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dba:	05b2                	slli	a1,a1,0xc
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	3a6080e7          	jalr	934(ra) # 80001162 <mappages>
    80001dc4:	02054863          	bltz	a0,80001df4 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dc8:	4719                	li	a4,6
    80001dca:	05893683          	ld	a3,88(s2)
    80001dce:	6605                	lui	a2,0x1
    80001dd0:	020005b7          	lui	a1,0x2000
    80001dd4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dd6:	05b6                	slli	a1,a1,0xd
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	388080e7          	jalr	904(ra) # 80001162 <mappages>
    80001de2:	02054163          	bltz	a0,80001e04 <proc_pagetable+0x76>
}
    80001de6:	8526                	mv	a0,s1
    80001de8:	60e2                	ld	ra,24(sp)
    80001dea:	6442                	ld	s0,16(sp)
    80001dec:	64a2                	ld	s1,8(sp)
    80001dee:	6902                	ld	s2,0(sp)
    80001df0:	6105                	addi	sp,sp,32
    80001df2:	8082                	ret
        uvmfree(pagetable, 0);
    80001df4:	4581                	li	a1,0
    80001df6:	8526                	mv	a0,s1
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	8ae080e7          	jalr	-1874(ra) # 800016a6 <uvmfree>
        return 0;
    80001e00:	4481                	li	s1,0
    80001e02:	b7d5                	j	80001de6 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e04:	4681                	li	a3,0
    80001e06:	4605                	li	a2,1
    80001e08:	040005b7          	lui	a1,0x4000
    80001e0c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e0e:	05b2                	slli	a1,a1,0xc
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	66a080e7          	jalr	1642(ra) # 8000147c <uvmunmap>
        uvmfree(pagetable, 0);
    80001e1a:	4581                	li	a1,0
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	888080e7          	jalr	-1912(ra) # 800016a6 <uvmfree>
        return 0;
    80001e26:	4481                	li	s1,0
    80001e28:	bf7d                	j	80001de6 <proc_pagetable+0x58>

0000000080001e2a <proc_freepagetable>:
{
    80001e2a:	1101                	addi	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	addi	s0,sp,32
    80001e36:	84aa                	mv	s1,a0
    80001e38:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e3a:	4681                	li	a3,0
    80001e3c:	4605                	li	a2,1
    80001e3e:	040005b7          	lui	a1,0x4000
    80001e42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e44:	05b2                	slli	a1,a1,0xc
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	636080e7          	jalr	1590(ra) # 8000147c <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e4e:	4681                	li	a3,0
    80001e50:	4605                	li	a2,1
    80001e52:	020005b7          	lui	a1,0x2000
    80001e56:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e58:	05b6                	slli	a1,a1,0xd
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	620080e7          	jalr	1568(ra) # 8000147c <uvmunmap>
    uvmfree(pagetable, sz);
    80001e64:	85ca                	mv	a1,s2
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	83e080e7          	jalr	-1986(ra) # 800016a6 <uvmfree>
}
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6902                	ld	s2,0(sp)
    80001e78:	6105                	addi	sp,sp,32
    80001e7a:	8082                	ret

0000000080001e7c <freeproc>:
{
    80001e7c:	1101                	addi	sp,sp,-32
    80001e7e:	ec06                	sd	ra,24(sp)
    80001e80:	e822                	sd	s0,16(sp)
    80001e82:	e426                	sd	s1,8(sp)
    80001e84:	1000                	addi	s0,sp,32
    80001e86:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e88:	6d28                	ld	a0,88(a0)
    80001e8a:	c509                	beqz	a0,80001e94 <freeproc+0x18>
        dec_ref((void *)p->trapframe);
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	574080e7          	jalr	1396(ra) # 80001400 <dec_ref>
    p->trapframe = 0;
    80001e94:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e98:	68a8                	ld	a0,80(s1)
    80001e9a:	c511                	beqz	a0,80001ea6 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e9c:	64ac                	ld	a1,72(s1)
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	f8c080e7          	jalr	-116(ra) # 80001e2a <proc_freepagetable>
    p->pagetable = 0;
    80001ea6:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001eaa:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001eae:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001eb2:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001eb6:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001eba:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001ebe:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001ec2:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001ec6:	0004ac23          	sw	zero,24(s1)
}
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6105                	addi	sp,sp,32
    80001ed2:	8082                	ret

0000000080001ed4 <allocproc>:
{
    80001ed4:	1101                	addi	sp,sp,-32
    80001ed6:	ec06                	sd	ra,24(sp)
    80001ed8:	e822                	sd	s0,16(sp)
    80001eda:	e426                	sd	s1,8(sp)
    80001edc:	e04a                	sd	s2,0(sp)
    80001ede:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001ee0:	0011f497          	auipc	s1,0x11f
    80001ee4:	2c048493          	addi	s1,s1,704 # 801211a0 <proc>
    80001ee8:	00125917          	auipc	s2,0x125
    80001eec:	cb890913          	addi	s2,s2,-840 # 80126ba0 <tickslock>
        acquire(&p->lock);
    80001ef0:	8526                	mv	a0,s1
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	d9c080e7          	jalr	-612(ra) # 80000c8e <acquire>
        if (p->state == UNUSED)
    80001efa:	4c9c                	lw	a5,24(s1)
    80001efc:	cf81                	beqz	a5,80001f14 <allocproc+0x40>
            release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	e42080e7          	jalr	-446(ra) # 80000d42 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f08:	16848493          	addi	s1,s1,360
    80001f0c:	ff2492e3          	bne	s1,s2,80001ef0 <allocproc+0x1c>
    return 0;
    80001f10:	4481                	li	s1,0
    80001f12:	a889                	j	80001f64 <allocproc+0x90>
    p->pid = allocpid();
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	e34080e7          	jalr	-460(ra) # 80001d48 <allocpid>
    80001f1c:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001f1e:	4785                	li	a5,1
    80001f20:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	c26080e7          	jalr	-986(ra) # 80000b48 <kalloc>
    80001f2a:	892a                	mv	s2,a0
    80001f2c:	eca8                	sd	a0,88(s1)
    80001f2e:	c131                	beqz	a0,80001f72 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001f30:	8526                	mv	a0,s1
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	e5c080e7          	jalr	-420(ra) # 80001d8e <proc_pagetable>
    80001f3a:	892a                	mv	s2,a0
    80001f3c:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001f3e:	c531                	beqz	a0,80001f8a <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001f40:	07000613          	li	a2,112
    80001f44:	4581                	li	a1,0
    80001f46:	06048513          	addi	a0,s1,96
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	e40080e7          	jalr	-448(ra) # 80000d8a <memset>
    p->context.ra = (uint64)forkret;
    80001f52:	00000797          	auipc	a5,0x0
    80001f56:	db078793          	addi	a5,a5,-592 # 80001d02 <forkret>
    80001f5a:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f5c:	60bc                	ld	a5,64(s1)
    80001f5e:	6705                	lui	a4,0x1
    80001f60:	97ba                	add	a5,a5,a4
    80001f62:	f4bc                	sd	a5,104(s1)
}
    80001f64:	8526                	mv	a0,s1
    80001f66:	60e2                	ld	ra,24(sp)
    80001f68:	6442                	ld	s0,16(sp)
    80001f6a:	64a2                	ld	s1,8(sp)
    80001f6c:	6902                	ld	s2,0(sp)
    80001f6e:	6105                	addi	sp,sp,32
    80001f70:	8082                	ret
        freeproc(p);
    80001f72:	8526                	mv	a0,s1
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	f08080e7          	jalr	-248(ra) # 80001e7c <freeproc>
        release(&p->lock);
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	dc4080e7          	jalr	-572(ra) # 80000d42 <release>
        return 0;
    80001f86:	84ca                	mv	s1,s2
    80001f88:	bff1                	j	80001f64 <allocproc+0x90>
        freeproc(p);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	ef0080e7          	jalr	-272(ra) # 80001e7c <freeproc>
        release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	dac080e7          	jalr	-596(ra) # 80000d42 <release>
        return 0;
    80001f9e:	84ca                	mv	s1,s2
    80001fa0:	b7d1                	j	80001f64 <allocproc+0x90>

0000000080001fa2 <userinit>:
{
    80001fa2:	1101                	addi	sp,sp,-32
    80001fa4:	ec06                	sd	ra,24(sp)
    80001fa6:	e822                	sd	s0,16(sp)
    80001fa8:	e426                	sd	s1,8(sp)
    80001faa:	1000                	addi	s0,sp,32
    p = allocproc();
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	f28080e7          	jalr	-216(ra) # 80001ed4 <allocproc>
    80001fb4:	84aa                	mv	s1,a0
    initproc = p;
    80001fb6:	00007797          	auipc	a5,0x7
    80001fba:	b4a7b123          	sd	a0,-1214(a5) # 80008af8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001fbe:	03400613          	li	a2,52
    80001fc2:	00007597          	auipc	a1,0x7
    80001fc6:	a9e58593          	addi	a1,a1,-1378 # 80008a60 <initcode>
    80001fca:	6928                	ld	a0,80(a0)
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	38a080e7          	jalr	906(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001fd4:	6785                	lui	a5,0x1
    80001fd6:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001fd8:	6cb8                	ld	a4,88(s1)
    80001fda:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001fde:	6cb8                	ld	a4,88(s1)
    80001fe0:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fe2:	4641                	li	a2,16
    80001fe4:	00006597          	auipc	a1,0x6
    80001fe8:	30458593          	addi	a1,a1,772 # 800082e8 <digits+0x298>
    80001fec:	15848513          	addi	a0,s1,344
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	ee2080e7          	jalr	-286(ra) # 80000ed2 <safestrcpy>
    p->cwd = namei("/");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	30050513          	addi	a0,a0,768 # 800082f8 <digits+0x2a8>
    80002000:	00002097          	auipc	ra,0x2
    80002004:	522080e7          	jalr	1314(ra) # 80004522 <namei>
    80002008:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    8000200c:	478d                	li	a5,3
    8000200e:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80002010:	8526                	mv	a0,s1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	d30080e7          	jalr	-720(ra) # 80000d42 <release>
}
    8000201a:	60e2                	ld	ra,24(sp)
    8000201c:	6442                	ld	s0,16(sp)
    8000201e:	64a2                	ld	s1,8(sp)
    80002020:	6105                	addi	sp,sp,32
    80002022:	8082                	ret

0000000080002024 <growproc>:
{
    80002024:	1101                	addi	sp,sp,-32
    80002026:	ec06                	sd	ra,24(sp)
    80002028:	e822                	sd	s0,16(sp)
    8000202a:	e426                	sd	s1,8(sp)
    8000202c:	e04a                	sd	s2,0(sp)
    8000202e:	1000                	addi	s0,sp,32
    80002030:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	c98080e7          	jalr	-872(ra) # 80001cca <myproc>
    8000203a:	84aa                	mv	s1,a0
    sz = p->sz;
    8000203c:	652c                	ld	a1,72(a0)
    if (n > 0)
    8000203e:	01204c63          	bgtz	s2,80002056 <growproc+0x32>
    else if (n < 0)
    80002042:	02094663          	bltz	s2,8000206e <growproc+0x4a>
    p->sz = sz;
    80002046:	e4ac                	sd	a1,72(s1)
    return 0;
    80002048:	4501                	li	a0,0
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6902                	ld	s2,0(sp)
    80002052:	6105                	addi	sp,sp,32
    80002054:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002056:	4691                	li	a3,4
    80002058:	00b90633          	add	a2,s2,a1
    8000205c:	6928                	ld	a0,80(a0)
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	52a080e7          	jalr	1322(ra) # 80001588 <uvmalloc>
    80002066:	85aa                	mv	a1,a0
    80002068:	fd79                	bnez	a0,80002046 <growproc+0x22>
            return -1;
    8000206a:	557d                	li	a0,-1
    8000206c:	bff9                	j	8000204a <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000206e:	00b90633          	add	a2,s2,a1
    80002072:	6928                	ld	a0,80(a0)
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	4cc080e7          	jalr	1228(ra) # 80001540 <uvmdealloc>
    8000207c:	85aa                	mv	a1,a0
    8000207e:	b7e1                	j	80002046 <growproc+0x22>

0000000080002080 <ps>:
{
    80002080:	715d                	addi	sp,sp,-80
    80002082:	e486                	sd	ra,72(sp)
    80002084:	e0a2                	sd	s0,64(sp)
    80002086:	fc26                	sd	s1,56(sp)
    80002088:	f84a                	sd	s2,48(sp)
    8000208a:	f44e                	sd	s3,40(sp)
    8000208c:	f052                	sd	s4,32(sp)
    8000208e:	ec56                	sd	s5,24(sp)
    80002090:	e85a                	sd	s6,16(sp)
    80002092:	e45e                	sd	s7,8(sp)
    80002094:	e062                	sd	s8,0(sp)
    80002096:	0880                	addi	s0,sp,80
    80002098:	84aa                	mv	s1,a0
    8000209a:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	c2e080e7          	jalr	-978(ra) # 80001cca <myproc>
    if (count == 0)
    800020a4:	120b8063          	beqz	s7,800021c4 <ps+0x144>
    void *result = (void *)myproc()->sz;
    800020a8:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    800020ac:	003b951b          	slliw	a0,s7,0x3
    800020b0:	0175053b          	addw	a0,a0,s7
    800020b4:	0025151b          	slliw	a0,a0,0x2
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	f6c080e7          	jalr	-148(ra) # 80002024 <growproc>
    800020c0:	10054463          	bltz	a0,800021c8 <ps+0x148>
    struct user_proc loc_result[count];
    800020c4:	003b9a13          	slli	s4,s7,0x3
    800020c8:	9a5e                	add	s4,s4,s7
    800020ca:	0a0a                	slli	s4,s4,0x2
    800020cc:	00fa0793          	addi	a5,s4,15
    800020d0:	8391                	srli	a5,a5,0x4
    800020d2:	0792                	slli	a5,a5,0x4
    800020d4:	40f10133          	sub	sp,sp,a5
    800020d8:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    800020da:	007e97b7          	lui	a5,0x7e9
    800020de:	02f484b3          	mul	s1,s1,a5
    800020e2:	0011f797          	auipc	a5,0x11f
    800020e6:	0be78793          	addi	a5,a5,190 # 801211a0 <proc>
    800020ea:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    800020ec:	00125797          	auipc	a5,0x125
    800020f0:	ab478793          	addi	a5,a5,-1356 # 80126ba0 <tickslock>
    800020f4:	0cf4fc63          	bgeu	s1,a5,800021cc <ps+0x14c>
        if (localCount == count)
    800020f8:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020fc:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020fe:	8c3e                	mv	s8,a5
    80002100:	a069                	j	8000218a <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80002102:	00399793          	slli	a5,s3,0x3
    80002106:	97ce                	add	a5,a5,s3
    80002108:	078a                	slli	a5,a5,0x2
    8000210a:	97d6                	add	a5,a5,s5
    8000210c:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	c30080e7          	jalr	-976(ra) # 80000d42 <release>
    if (localCount < count)
    8000211a:	0179f963          	bgeu	s3,s7,8000212c <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    8000211e:	00399793          	slli	a5,s3,0x3
    80002122:	97ce                	add	a5,a5,s3
    80002124:	078a                	slli	a5,a5,0x2
    80002126:	97d6                	add	a5,a5,s5
    80002128:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000212c:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	b9c080e7          	jalr	-1124(ra) # 80001cca <myproc>
    80002136:	86d2                	mv	a3,s4
    80002138:	8656                	mv	a2,s5
    8000213a:	85da                	mv	a1,s6
    8000213c:	6928                	ld	a0,80(a0)
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	6b0080e7          	jalr	1712(ra) # 800017ee <copyout>
}
    80002146:	8526                	mv	a0,s1
    80002148:	fb040113          	addi	sp,s0,-80
    8000214c:	60a6                	ld	ra,72(sp)
    8000214e:	6406                	ld	s0,64(sp)
    80002150:	74e2                	ld	s1,56(sp)
    80002152:	7942                	ld	s2,48(sp)
    80002154:	79a2                	ld	s3,40(sp)
    80002156:	7a02                	ld	s4,32(sp)
    80002158:	6ae2                	ld	s5,24(sp)
    8000215a:	6b42                	ld	s6,16(sp)
    8000215c:	6ba2                	ld	s7,8(sp)
    8000215e:	6c02                	ld	s8,0(sp)
    80002160:	6161                	addi	sp,sp,80
    80002162:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002164:	5b9c                	lw	a5,48(a5)
    80002166:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	bd6080e7          	jalr	-1066(ra) # 80000d42 <release>
        localCount++;
    80002174:	2985                	addiw	s3,s3,1
    80002176:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000217a:	16848493          	addi	s1,s1,360
    8000217e:	f984fee3          	bgeu	s1,s8,8000211a <ps+0x9a>
        if (localCount == count)
    80002182:	02490913          	addi	s2,s2,36
    80002186:	fb3b83e3          	beq	s7,s3,8000212c <ps+0xac>
        acquire(&p->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b02080e7          	jalr	-1278(ra) # 80000c8e <acquire>
        if (p->state == UNUSED)
    80002194:	4c9c                	lw	a5,24(s1)
    80002196:	d7b5                	beqz	a5,80002102 <ps+0x82>
        loc_result[localCount].state = p->state;
    80002198:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000219c:	549c                	lw	a5,40(s1)
    8000219e:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800021a2:	54dc                	lw	a5,44(s1)
    800021a4:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800021a8:	589c                	lw	a5,48(s1)
    800021aa:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800021ae:	4641                	li	a2,16
    800021b0:	85ca                	mv	a1,s2
    800021b2:	15848513          	addi	a0,s1,344
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	ac4080e7          	jalr	-1340(ra) # 80001c7a <copy_array>
        if (p->parent != 0) // init
    800021be:	7c9c                	ld	a5,56(s1)
    800021c0:	f3d5                	bnez	a5,80002164 <ps+0xe4>
    800021c2:	b765                	j	8000216a <ps+0xea>
        return result;
    800021c4:	4481                	li	s1,0
    800021c6:	b741                	j	80002146 <ps+0xc6>
        return result;
    800021c8:	4481                	li	s1,0
    800021ca:	bfb5                	j	80002146 <ps+0xc6>
        return result;
    800021cc:	4481                	li	s1,0
    800021ce:	bfa5                	j	80002146 <ps+0xc6>

00000000800021d0 <fork>:
{
    800021d0:	7139                	addi	sp,sp,-64
    800021d2:	fc06                	sd	ra,56(sp)
    800021d4:	f822                	sd	s0,48(sp)
    800021d6:	f426                	sd	s1,40(sp)
    800021d8:	f04a                	sd	s2,32(sp)
    800021da:	ec4e                	sd	s3,24(sp)
    800021dc:	e852                	sd	s4,16(sp)
    800021de:	e456                	sd	s5,8(sp)
    800021e0:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	ae8080e7          	jalr	-1304(ra) # 80001cca <myproc>
    800021ea:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	ce8080e7          	jalr	-792(ra) # 80001ed4 <allocproc>
    800021f4:	10050c63          	beqz	a0,8000230c <fork+0x13c>
    800021f8:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021fa:	048ab603          	ld	a2,72(s5)
    800021fe:	692c                	ld	a1,80(a0)
    80002200:	050ab503          	ld	a0,80(s5)
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	4dc080e7          	jalr	1244(ra) # 800016e0 <uvmcopy>
    8000220c:	04054863          	bltz	a0,8000225c <fork+0x8c>
    np->sz = p->sz;
    80002210:	048ab783          	ld	a5,72(s5)
    80002214:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80002218:	058ab683          	ld	a3,88(s5)
    8000221c:	87b6                	mv	a5,a3
    8000221e:	058a3703          	ld	a4,88(s4)
    80002222:	12068693          	addi	a3,a3,288
    80002226:	0007b803          	ld	a6,0(a5)
    8000222a:	6788                	ld	a0,8(a5)
    8000222c:	6b8c                	ld	a1,16(a5)
    8000222e:	6f90                	ld	a2,24(a5)
    80002230:	01073023          	sd	a6,0(a4)
    80002234:	e708                	sd	a0,8(a4)
    80002236:	eb0c                	sd	a1,16(a4)
    80002238:	ef10                	sd	a2,24(a4)
    8000223a:	02078793          	addi	a5,a5,32
    8000223e:	02070713          	addi	a4,a4,32
    80002242:	fed792e3          	bne	a5,a3,80002226 <fork+0x56>
    np->trapframe->a0 = 0;
    80002246:	058a3783          	ld	a5,88(s4)
    8000224a:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000224e:	0d0a8493          	addi	s1,s5,208
    80002252:	0d0a0913          	addi	s2,s4,208
    80002256:	150a8993          	addi	s3,s5,336
    8000225a:	a00d                	j	8000227c <fork+0xac>
        freeproc(np);
    8000225c:	8552                	mv	a0,s4
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	c1e080e7          	jalr	-994(ra) # 80001e7c <freeproc>
        release(&np->lock);
    80002266:	8552                	mv	a0,s4
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	ada080e7          	jalr	-1318(ra) # 80000d42 <release>
        return -1;
    80002270:	597d                	li	s2,-1
    80002272:	a059                	j	800022f8 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002274:	04a1                	addi	s1,s1,8
    80002276:	0921                	addi	s2,s2,8
    80002278:	01348b63          	beq	s1,s3,8000228e <fork+0xbe>
        if (p->ofile[i])
    8000227c:	6088                	ld	a0,0(s1)
    8000227e:	d97d                	beqz	a0,80002274 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002280:	00003097          	auipc	ra,0x3
    80002284:	914080e7          	jalr	-1772(ra) # 80004b94 <filedup>
    80002288:	00a93023          	sd	a0,0(s2)
    8000228c:	b7e5                	j	80002274 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000228e:	150ab503          	ld	a0,336(s5)
    80002292:	00002097          	auipc	ra,0x2
    80002296:	aac080e7          	jalr	-1364(ra) # 80003d3e <idup>
    8000229a:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000229e:	4641                	li	a2,16
    800022a0:	158a8593          	addi	a1,s5,344
    800022a4:	158a0513          	addi	a0,s4,344
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	c2a080e7          	jalr	-982(ra) # 80000ed2 <safestrcpy>
    pid = np->pid;
    800022b0:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800022b4:	8552                	mv	a0,s4
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	a8c080e7          	jalr	-1396(ra) # 80000d42 <release>
    acquire(&wait_lock);
    800022be:	0011f497          	auipc	s1,0x11f
    800022c2:	eca48493          	addi	s1,s1,-310 # 80121188 <wait_lock>
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9c6080e7          	jalr	-1594(ra) # 80000c8e <acquire>
    np->parent = p;
    800022d0:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	a6c080e7          	jalr	-1428(ra) # 80000d42 <release>
    acquire(&np->lock);
    800022de:	8552                	mv	a0,s4
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9ae080e7          	jalr	-1618(ra) # 80000c8e <acquire>
    np->state = RUNNABLE;
    800022e8:	478d                	li	a5,3
    800022ea:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022ee:	8552                	mv	a0,s4
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	a52080e7          	jalr	-1454(ra) # 80000d42 <release>
}
    800022f8:	854a                	mv	a0,s2
    800022fa:	70e2                	ld	ra,56(sp)
    800022fc:	7442                	ld	s0,48(sp)
    800022fe:	74a2                	ld	s1,40(sp)
    80002300:	7902                	ld	s2,32(sp)
    80002302:	69e2                	ld	s3,24(sp)
    80002304:	6a42                	ld	s4,16(sp)
    80002306:	6aa2                	ld	s5,8(sp)
    80002308:	6121                	addi	sp,sp,64
    8000230a:	8082                	ret
        return -1;
    8000230c:	597d                	li	s2,-1
    8000230e:	b7ed                	j	800022f8 <fork+0x128>

0000000080002310 <scheduler>:
{
    80002310:	1101                	addi	sp,sp,-32
    80002312:	ec06                	sd	ra,24(sp)
    80002314:	e822                	sd	s0,16(sp)
    80002316:	e426                	sd	s1,8(sp)
    80002318:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    8000231a:	00006497          	auipc	s1,0x6
    8000231e:	72e48493          	addi	s1,s1,1838 # 80008a48 <sched_pointer>
    80002322:	609c                	ld	a5,0(s1)
    80002324:	9782                	jalr	a5
    while (1)
    80002326:	bff5                	j	80002322 <scheduler+0x12>

0000000080002328 <sched>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	994080e7          	jalr	-1644(ra) # 80001cca <myproc>
    8000233e:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8d4080e7          	jalr	-1836(ra) # 80000c14 <holding>
    80002348:	c53d                	beqz	a0,800023b6 <sched+0x8e>
    8000234a:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000234c:	2781                	sext.w	a5,a5
    8000234e:	079e                	slli	a5,a5,0x7
    80002350:	0011f717          	auipc	a4,0x11f
    80002354:	a2070713          	addi	a4,a4,-1504 # 80120d70 <cpus>
    80002358:	97ba                	add	a5,a5,a4
    8000235a:	5fb8                	lw	a4,120(a5)
    8000235c:	4785                	li	a5,1
    8000235e:	06f71463          	bne	a4,a5,800023c6 <sched+0x9e>
    if (p->state == RUNNING)
    80002362:	4c98                	lw	a4,24(s1)
    80002364:	4791                	li	a5,4
    80002366:	06f70863          	beq	a4,a5,800023d6 <sched+0xae>
    asm volatile("csrr %0, sstatus"
    8000236a:	100027f3          	csrr	a5,sstatus
    return (x & SSTATUS_SIE) != 0;
    8000236e:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002370:	ebbd                	bnez	a5,800023e6 <sched+0xbe>
    asm volatile("mv %0, tp"
    80002372:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002374:	0011f917          	auipc	s2,0x11f
    80002378:	9fc90913          	addi	s2,s2,-1540 # 80120d70 <cpus>
    8000237c:	2781                	sext.w	a5,a5
    8000237e:	079e                	slli	a5,a5,0x7
    80002380:	97ca                	add	a5,a5,s2
    80002382:	07c7a983          	lw	s3,124(a5)
    80002386:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002388:	2581                	sext.w	a1,a1
    8000238a:	059e                	slli	a1,a1,0x7
    8000238c:	05a1                	addi	a1,a1,8
    8000238e:	95ca                	add	a1,a1,s2
    80002390:	06048513          	addi	a0,s1,96
    80002394:	00000097          	auipc	ra,0x0
    80002398:	786080e7          	jalr	1926(ra) # 80002b1a <swtch>
    8000239c:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000239e:	2781                	sext.w	a5,a5
    800023a0:	079e                	slli	a5,a5,0x7
    800023a2:	993e                	add	s2,s2,a5
    800023a4:	07392e23          	sw	s3,124(s2)
}
    800023a8:	70a2                	ld	ra,40(sp)
    800023aa:	7402                	ld	s0,32(sp)
    800023ac:	64e2                	ld	s1,24(sp)
    800023ae:	6942                	ld	s2,16(sp)
    800023b0:	69a2                	ld	s3,8(sp)
    800023b2:	6145                	addi	sp,sp,48
    800023b4:	8082                	ret
        panic("sched p->lock");
    800023b6:	00006517          	auipc	a0,0x6
    800023ba:	f4a50513          	addi	a0,a0,-182 # 80008300 <digits+0x2b0>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	17e080e7          	jalr	382(ra) # 8000053c <panic>
        panic("sched locks");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	f4a50513          	addi	a0,a0,-182 # 80008310 <digits+0x2c0>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	16e080e7          	jalr	366(ra) # 8000053c <panic>
        panic("sched running");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	f4a50513          	addi	a0,a0,-182 # 80008320 <digits+0x2d0>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	15e080e7          	jalr	350(ra) # 8000053c <panic>
        panic("sched interruptible");
    800023e6:	00006517          	auipc	a0,0x6
    800023ea:	f4a50513          	addi	a0,a0,-182 # 80008330 <digits+0x2e0>
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	14e080e7          	jalr	334(ra) # 8000053c <panic>

00000000800023f6 <yield>:
{
    800023f6:	1101                	addi	sp,sp,-32
    800023f8:	ec06                	sd	ra,24(sp)
    800023fa:	e822                	sd	s0,16(sp)
    800023fc:	e426                	sd	s1,8(sp)
    800023fe:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002400:	00000097          	auipc	ra,0x0
    80002404:	8ca080e7          	jalr	-1846(ra) # 80001cca <myproc>
    80002408:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	884080e7          	jalr	-1916(ra) # 80000c8e <acquire>
    p->state = RUNNABLE;
    80002412:	478d                	li	a5,3
    80002414:	cc9c                	sw	a5,24(s1)
    sched();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	f12080e7          	jalr	-238(ra) # 80002328 <sched>
    release(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	922080e7          	jalr	-1758(ra) # 80000d42 <release>
}
    80002428:	60e2                	ld	ra,24(sp)
    8000242a:	6442                	ld	s0,16(sp)
    8000242c:	64a2                	ld	s1,8(sp)
    8000242e:	6105                	addi	sp,sp,32
    80002430:	8082                	ret

0000000080002432 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	1800                	addi	s0,sp,48
    80002440:	89aa                	mv	s3,a0
    80002442:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002444:	00000097          	auipc	ra,0x0
    80002448:	886080e7          	jalr	-1914(ra) # 80001cca <myproc>
    8000244c:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	840080e7          	jalr	-1984(ra) # 80000c8e <acquire>
    release(lk);
    80002456:	854a                	mv	a0,s2
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	8ea080e7          	jalr	-1814(ra) # 80000d42 <release>

    // Go to sleep.
    p->chan = chan;
    80002460:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002464:	4789                	li	a5,2
    80002466:	cc9c                	sw	a5,24(s1)

    sched();
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	ec0080e7          	jalr	-320(ra) # 80002328 <sched>

    // Tidy up.
    p->chan = 0;
    80002470:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	8cc080e7          	jalr	-1844(ra) # 80000d42 <release>
    acquire(lk);
    8000247e:	854a                	mv	a0,s2
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	80e080e7          	jalr	-2034(ra) # 80000c8e <acquire>
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret

0000000080002496 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002496:	7139                	addi	sp,sp,-64
    80002498:	fc06                	sd	ra,56(sp)
    8000249a:	f822                	sd	s0,48(sp)
    8000249c:	f426                	sd	s1,40(sp)
    8000249e:	f04a                	sd	s2,32(sp)
    800024a0:	ec4e                	sd	s3,24(sp)
    800024a2:	e852                	sd	s4,16(sp)
    800024a4:	e456                	sd	s5,8(sp)
    800024a6:	0080                	addi	s0,sp,64
    800024a8:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024aa:	0011f497          	auipc	s1,0x11f
    800024ae:	cf648493          	addi	s1,s1,-778 # 801211a0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800024b2:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800024b4:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800024b6:	00124917          	auipc	s2,0x124
    800024ba:	6ea90913          	addi	s2,s2,1770 # 80126ba0 <tickslock>
    800024be:	a811                	j	800024d2 <wakeup+0x3c>
            }
            release(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	880080e7          	jalr	-1920(ra) # 80000d42 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024ca:	16848493          	addi	s1,s1,360
    800024ce:	03248663          	beq	s1,s2,800024fa <wakeup+0x64>
        if (p != myproc())
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	7f8080e7          	jalr	2040(ra) # 80001cca <myproc>
    800024da:	fea488e3          	beq	s1,a0,800024ca <wakeup+0x34>
            acquire(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7ae080e7          	jalr	1966(ra) # 80000c8e <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800024e8:	4c9c                	lw	a5,24(s1)
    800024ea:	fd379be3          	bne	a5,s3,800024c0 <wakeup+0x2a>
    800024ee:	709c                	ld	a5,32(s1)
    800024f0:	fd4798e3          	bne	a5,s4,800024c0 <wakeup+0x2a>
                p->state = RUNNABLE;
    800024f4:	0154ac23          	sw	s5,24(s1)
    800024f8:	b7e1                	j	800024c0 <wakeup+0x2a>
        }
    }
}
    800024fa:	70e2                	ld	ra,56(sp)
    800024fc:	7442                	ld	s0,48(sp)
    800024fe:	74a2                	ld	s1,40(sp)
    80002500:	7902                	ld	s2,32(sp)
    80002502:	69e2                	ld	s3,24(sp)
    80002504:	6a42                	ld	s4,16(sp)
    80002506:	6aa2                	ld	s5,8(sp)
    80002508:	6121                	addi	sp,sp,64
    8000250a:	8082                	ret

000000008000250c <reparent>:
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000251e:	0011f497          	auipc	s1,0x11f
    80002522:	c8248493          	addi	s1,s1,-894 # 801211a0 <proc>
            pp->parent = initproc;
    80002526:	00006a17          	auipc	s4,0x6
    8000252a:	5d2a0a13          	addi	s4,s4,1490 # 80008af8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000252e:	00124997          	auipc	s3,0x124
    80002532:	67298993          	addi	s3,s3,1650 # 80126ba0 <tickslock>
    80002536:	a029                	j	80002540 <reparent+0x34>
    80002538:	16848493          	addi	s1,s1,360
    8000253c:	01348d63          	beq	s1,s3,80002556 <reparent+0x4a>
        if (pp->parent == p)
    80002540:	7c9c                	ld	a5,56(s1)
    80002542:	ff279be3          	bne	a5,s2,80002538 <reparent+0x2c>
            pp->parent = initproc;
    80002546:	000a3503          	ld	a0,0(s4)
    8000254a:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	f4a080e7          	jalr	-182(ra) # 80002496 <wakeup>
    80002554:	b7d5                	j	80002538 <reparent+0x2c>
}
    80002556:	70a2                	ld	ra,40(sp)
    80002558:	7402                	ld	s0,32(sp)
    8000255a:	64e2                	ld	s1,24(sp)
    8000255c:	6942                	ld	s2,16(sp)
    8000255e:	69a2                	ld	s3,8(sp)
    80002560:	6a02                	ld	s4,0(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret

0000000080002566 <exit>:
{
    80002566:	7179                	addi	sp,sp,-48
    80002568:	f406                	sd	ra,40(sp)
    8000256a:	f022                	sd	s0,32(sp)
    8000256c:	ec26                	sd	s1,24(sp)
    8000256e:	e84a                	sd	s2,16(sp)
    80002570:	e44e                	sd	s3,8(sp)
    80002572:	e052                	sd	s4,0(sp)
    80002574:	1800                	addi	s0,sp,48
    80002576:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	752080e7          	jalr	1874(ra) # 80001cca <myproc>
    80002580:	89aa                	mv	s3,a0
    if (p == initproc)
    80002582:	00006797          	auipc	a5,0x6
    80002586:	5767b783          	ld	a5,1398(a5) # 80008af8 <initproc>
    8000258a:	0d050493          	addi	s1,a0,208
    8000258e:	15050913          	addi	s2,a0,336
    80002592:	02a79363          	bne	a5,a0,800025b8 <exit+0x52>
        panic("init exiting");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	db250513          	addi	a0,a0,-590 # 80008348 <digits+0x2f8>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	f9e080e7          	jalr	-98(ra) # 8000053c <panic>
            fileclose(f);
    800025a6:	00002097          	auipc	ra,0x2
    800025aa:	640080e7          	jalr	1600(ra) # 80004be6 <fileclose>
            p->ofile[fd] = 0;
    800025ae:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800025b2:	04a1                	addi	s1,s1,8
    800025b4:	01248563          	beq	s1,s2,800025be <exit+0x58>
        if (p->ofile[fd])
    800025b8:	6088                	ld	a0,0(s1)
    800025ba:	f575                	bnez	a0,800025a6 <exit+0x40>
    800025bc:	bfdd                	j	800025b2 <exit+0x4c>
    begin_op();
    800025be:	00002097          	auipc	ra,0x2
    800025c2:	164080e7          	jalr	356(ra) # 80004722 <begin_op>
    iput(p->cwd);
    800025c6:	1509b503          	ld	a0,336(s3)
    800025ca:	00002097          	auipc	ra,0x2
    800025ce:	96c080e7          	jalr	-1684(ra) # 80003f36 <iput>
    end_op();
    800025d2:	00002097          	auipc	ra,0x2
    800025d6:	1ca080e7          	jalr	458(ra) # 8000479c <end_op>
    p->cwd = 0;
    800025da:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800025de:	0011f497          	auipc	s1,0x11f
    800025e2:	baa48493          	addi	s1,s1,-1110 # 80121188 <wait_lock>
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	6a6080e7          	jalr	1702(ra) # 80000c8e <acquire>
    reparent(p);
    800025f0:	854e                	mv	a0,s3
    800025f2:	00000097          	auipc	ra,0x0
    800025f6:	f1a080e7          	jalr	-230(ra) # 8000250c <reparent>
    wakeup(p->parent);
    800025fa:	0389b503          	ld	a0,56(s3)
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	e98080e7          	jalr	-360(ra) # 80002496 <wakeup>
    acquire(&p->lock);
    80002606:	854e                	mv	a0,s3
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	686080e7          	jalr	1670(ra) # 80000c8e <acquire>
    p->xstate = status;
    80002610:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002614:	4795                	li	a5,5
    80002616:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	726080e7          	jalr	1830(ra) # 80000d42 <release>
    sched();
    80002624:	00000097          	auipc	ra,0x0
    80002628:	d04080e7          	jalr	-764(ra) # 80002328 <sched>
    panic("zombie exit");
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	d2c50513          	addi	a0,a0,-724 # 80008358 <digits+0x308>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f08080e7          	jalr	-248(ra) # 8000053c <panic>

000000008000263c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000263c:	7179                	addi	sp,sp,-48
    8000263e:	f406                	sd	ra,40(sp)
    80002640:	f022                	sd	s0,32(sp)
    80002642:	ec26                	sd	s1,24(sp)
    80002644:	e84a                	sd	s2,16(sp)
    80002646:	e44e                	sd	s3,8(sp)
    80002648:	1800                	addi	s0,sp,48
    8000264a:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000264c:	0011f497          	auipc	s1,0x11f
    80002650:	b5448493          	addi	s1,s1,-1196 # 801211a0 <proc>
    80002654:	00124997          	auipc	s3,0x124
    80002658:	54c98993          	addi	s3,s3,1356 # 80126ba0 <tickslock>
    {
        acquire(&p->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	630080e7          	jalr	1584(ra) # 80000c8e <acquire>
        if (p->pid == pid)
    80002666:	589c                	lw	a5,48(s1)
    80002668:	01278d63          	beq	a5,s2,80002682 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	6d4080e7          	jalr	1748(ra) # 80000d42 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002676:	16848493          	addi	s1,s1,360
    8000267a:	ff3491e3          	bne	s1,s3,8000265c <kill+0x20>
    }
    return -1;
    8000267e:	557d                	li	a0,-1
    80002680:	a829                	j	8000269a <kill+0x5e>
            p->killed = 1;
    80002682:	4785                	li	a5,1
    80002684:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002686:	4c98                	lw	a4,24(s1)
    80002688:	4789                	li	a5,2
    8000268a:	00f70f63          	beq	a4,a5,800026a8 <kill+0x6c>
            release(&p->lock);
    8000268e:	8526                	mv	a0,s1
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	6b2080e7          	jalr	1714(ra) # 80000d42 <release>
            return 0;
    80002698:	4501                	li	a0,0
}
    8000269a:	70a2                	ld	ra,40(sp)
    8000269c:	7402                	ld	s0,32(sp)
    8000269e:	64e2                	ld	s1,24(sp)
    800026a0:	6942                	ld	s2,16(sp)
    800026a2:	69a2                	ld	s3,8(sp)
    800026a4:	6145                	addi	sp,sp,48
    800026a6:	8082                	ret
                p->state = RUNNABLE;
    800026a8:	478d                	li	a5,3
    800026aa:	cc9c                	sw	a5,24(s1)
    800026ac:	b7cd                	j	8000268e <kill+0x52>

00000000800026ae <setkilled>:

void setkilled(struct proc *p)
{
    800026ae:	1101                	addi	sp,sp,-32
    800026b0:	ec06                	sd	ra,24(sp)
    800026b2:	e822                	sd	s0,16(sp)
    800026b4:	e426                	sd	s1,8(sp)
    800026b6:	1000                	addi	s0,sp,32
    800026b8:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	5d4080e7          	jalr	1492(ra) # 80000c8e <acquire>
    p->killed = 1;
    800026c2:	4785                	li	a5,1
    800026c4:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026c6:	8526                	mv	a0,s1
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	67a080e7          	jalr	1658(ra) # 80000d42 <release>
}
    800026d0:	60e2                	ld	ra,24(sp)
    800026d2:	6442                	ld	s0,16(sp)
    800026d4:	64a2                	ld	s1,8(sp)
    800026d6:	6105                	addi	sp,sp,32
    800026d8:	8082                	ret

00000000800026da <killed>:

int killed(struct proc *p)
{
    800026da:	1101                	addi	sp,sp,-32
    800026dc:	ec06                	sd	ra,24(sp)
    800026de:	e822                	sd	s0,16(sp)
    800026e0:	e426                	sd	s1,8(sp)
    800026e2:	e04a                	sd	s2,0(sp)
    800026e4:	1000                	addi	s0,sp,32
    800026e6:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5a6080e7          	jalr	1446(ra) # 80000c8e <acquire>
    k = p->killed;
    800026f0:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	64c080e7          	jalr	1612(ra) # 80000d42 <release>
    return k;
}
    800026fe:	854a                	mv	a0,s2
    80002700:	60e2                	ld	ra,24(sp)
    80002702:	6442                	ld	s0,16(sp)
    80002704:	64a2                	ld	s1,8(sp)
    80002706:	6902                	ld	s2,0(sp)
    80002708:	6105                	addi	sp,sp,32
    8000270a:	8082                	ret

000000008000270c <wait>:
{
    8000270c:	715d                	addi	sp,sp,-80
    8000270e:	e486                	sd	ra,72(sp)
    80002710:	e0a2                	sd	s0,64(sp)
    80002712:	fc26                	sd	s1,56(sp)
    80002714:	f84a                	sd	s2,48(sp)
    80002716:	f44e                	sd	s3,40(sp)
    80002718:	f052                	sd	s4,32(sp)
    8000271a:	ec56                	sd	s5,24(sp)
    8000271c:	e85a                	sd	s6,16(sp)
    8000271e:	e45e                	sd	s7,8(sp)
    80002720:	e062                	sd	s8,0(sp)
    80002722:	0880                	addi	s0,sp,80
    80002724:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	5a4080e7          	jalr	1444(ra) # 80001cca <myproc>
    8000272e:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002730:	0011f517          	auipc	a0,0x11f
    80002734:	a5850513          	addi	a0,a0,-1448 # 80121188 <wait_lock>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	556080e7          	jalr	1366(ra) # 80000c8e <acquire>
        havekids = 0;
    80002740:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002742:	4a15                	li	s4,5
                havekids = 1;
    80002744:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002746:	00124997          	auipc	s3,0x124
    8000274a:	45a98993          	addi	s3,s3,1114 # 80126ba0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000274e:	0011fc17          	auipc	s8,0x11f
    80002752:	a3ac0c13          	addi	s8,s8,-1478 # 80121188 <wait_lock>
    80002756:	a0d1                	j	8000281a <wait+0x10e>
                    pid = pp->pid;
    80002758:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000275c:	000b0e63          	beqz	s6,80002778 <wait+0x6c>
    80002760:	4691                	li	a3,4
    80002762:	02c48613          	addi	a2,s1,44
    80002766:	85da                	mv	a1,s6
    80002768:	05093503          	ld	a0,80(s2)
    8000276c:	fffff097          	auipc	ra,0xfffff
    80002770:	082080e7          	jalr	130(ra) # 800017ee <copyout>
    80002774:	04054163          	bltz	a0,800027b6 <wait+0xaa>
                    freeproc(pp);
    80002778:	8526                	mv	a0,s1
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	702080e7          	jalr	1794(ra) # 80001e7c <freeproc>
                    release(&pp->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	5be080e7          	jalr	1470(ra) # 80000d42 <release>
                    release(&wait_lock);
    8000278c:	0011f517          	auipc	a0,0x11f
    80002790:	9fc50513          	addi	a0,a0,-1540 # 80121188 <wait_lock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	5ae080e7          	jalr	1454(ra) # 80000d42 <release>
}
    8000279c:	854e                	mv	a0,s3
    8000279e:	60a6                	ld	ra,72(sp)
    800027a0:	6406                	ld	s0,64(sp)
    800027a2:	74e2                	ld	s1,56(sp)
    800027a4:	7942                	ld	s2,48(sp)
    800027a6:	79a2                	ld	s3,40(sp)
    800027a8:	7a02                	ld	s4,32(sp)
    800027aa:	6ae2                	ld	s5,24(sp)
    800027ac:	6b42                	ld	s6,16(sp)
    800027ae:	6ba2                	ld	s7,8(sp)
    800027b0:	6c02                	ld	s8,0(sp)
    800027b2:	6161                	addi	sp,sp,80
    800027b4:	8082                	ret
                        release(&pp->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	58a080e7          	jalr	1418(ra) # 80000d42 <release>
                        release(&wait_lock);
    800027c0:	0011f517          	auipc	a0,0x11f
    800027c4:	9c850513          	addi	a0,a0,-1592 # 80121188 <wait_lock>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	57a080e7          	jalr	1402(ra) # 80000d42 <release>
                        return -1;
    800027d0:	59fd                	li	s3,-1
    800027d2:	b7e9                	j	8000279c <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027d4:	16848493          	addi	s1,s1,360
    800027d8:	03348463          	beq	s1,s3,80002800 <wait+0xf4>
            if (pp->parent == p)
    800027dc:	7c9c                	ld	a5,56(s1)
    800027de:	ff279be3          	bne	a5,s2,800027d4 <wait+0xc8>
                acquire(&pp->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4aa080e7          	jalr	1194(ra) # 80000c8e <acquire>
                if (pp->state == ZOMBIE)
    800027ec:	4c9c                	lw	a5,24(s1)
    800027ee:	f74785e3          	beq	a5,s4,80002758 <wait+0x4c>
                release(&pp->lock);
    800027f2:	8526                	mv	a0,s1
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	54e080e7          	jalr	1358(ra) # 80000d42 <release>
                havekids = 1;
    800027fc:	8756                	mv	a4,s5
    800027fe:	bfd9                	j	800027d4 <wait+0xc8>
        if (!havekids || killed(p))
    80002800:	c31d                	beqz	a4,80002826 <wait+0x11a>
    80002802:	854a                	mv	a0,s2
    80002804:	00000097          	auipc	ra,0x0
    80002808:	ed6080e7          	jalr	-298(ra) # 800026da <killed>
    8000280c:	ed09                	bnez	a0,80002826 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000280e:	85e2                	mv	a1,s8
    80002810:	854a                	mv	a0,s2
    80002812:	00000097          	auipc	ra,0x0
    80002816:	c20080e7          	jalr	-992(ra) # 80002432 <sleep>
        havekids = 0;
    8000281a:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000281c:	0011f497          	auipc	s1,0x11f
    80002820:	98448493          	addi	s1,s1,-1660 # 801211a0 <proc>
    80002824:	bf65                	j	800027dc <wait+0xd0>
            release(&wait_lock);
    80002826:	0011f517          	auipc	a0,0x11f
    8000282a:	96250513          	addi	a0,a0,-1694 # 80121188 <wait_lock>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	514080e7          	jalr	1300(ra) # 80000d42 <release>
            return -1;
    80002836:	59fd                	li	s3,-1
    80002838:	b795                	j	8000279c <wait+0x90>

000000008000283a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000283a:	7179                	addi	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	addi	s0,sp,48
    8000284a:	84aa                	mv	s1,a0
    8000284c:	892e                	mv	s2,a1
    8000284e:	89b2                	mv	s3,a2
    80002850:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	478080e7          	jalr	1144(ra) # 80001cca <myproc>
    if (user_dst)
    8000285a:	c08d                	beqz	s1,8000287c <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000285c:	86d2                	mv	a3,s4
    8000285e:	864e                	mv	a2,s3
    80002860:	85ca                	mv	a1,s2
    80002862:	6928                	ld	a0,80(a0)
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	f8a080e7          	jalr	-118(ra) # 800017ee <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000286c:	70a2                	ld	ra,40(sp)
    8000286e:	7402                	ld	s0,32(sp)
    80002870:	64e2                	ld	s1,24(sp)
    80002872:	6942                	ld	s2,16(sp)
    80002874:	69a2                	ld	s3,8(sp)
    80002876:	6a02                	ld	s4,0(sp)
    80002878:	6145                	addi	sp,sp,48
    8000287a:	8082                	ret
        memmove((char *)dst, src, len);
    8000287c:	000a061b          	sext.w	a2,s4
    80002880:	85ce                	mv	a1,s3
    80002882:	854a                	mv	a0,s2
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	562080e7          	jalr	1378(ra) # 80000de6 <memmove>
        return 0;
    8000288c:	8526                	mv	a0,s1
    8000288e:	bff9                	j	8000286c <either_copyout+0x32>

0000000080002890 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002890:	7179                	addi	sp,sp,-48
    80002892:	f406                	sd	ra,40(sp)
    80002894:	f022                	sd	s0,32(sp)
    80002896:	ec26                	sd	s1,24(sp)
    80002898:	e84a                	sd	s2,16(sp)
    8000289a:	e44e                	sd	s3,8(sp)
    8000289c:	e052                	sd	s4,0(sp)
    8000289e:	1800                	addi	s0,sp,48
    800028a0:	892a                	mv	s2,a0
    800028a2:	84ae                	mv	s1,a1
    800028a4:	89b2                	mv	s3,a2
    800028a6:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	422080e7          	jalr	1058(ra) # 80001cca <myproc>
    if (user_src)
    800028b0:	c08d                	beqz	s1,800028d2 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800028b2:	86d2                	mv	a3,s4
    800028b4:	864e                	mv	a2,s3
    800028b6:	85ca                	mv	a1,s2
    800028b8:	6928                	ld	a0,80(a0)
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	064080e7          	jalr	100(ra) # 8000191e <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028c2:	70a2                	ld	ra,40(sp)
    800028c4:	7402                	ld	s0,32(sp)
    800028c6:	64e2                	ld	s1,24(sp)
    800028c8:	6942                	ld	s2,16(sp)
    800028ca:	69a2                	ld	s3,8(sp)
    800028cc:	6a02                	ld	s4,0(sp)
    800028ce:	6145                	addi	sp,sp,48
    800028d0:	8082                	ret
        memmove(dst, (char *)src, len);
    800028d2:	000a061b          	sext.w	a2,s4
    800028d6:	85ce                	mv	a1,s3
    800028d8:	854a                	mv	a0,s2
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	50c080e7          	jalr	1292(ra) # 80000de6 <memmove>
        return 0;
    800028e2:	8526                	mv	a0,s1
    800028e4:	bff9                	j	800028c2 <either_copyin+0x32>

00000000800028e6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028e6:	715d                	addi	sp,sp,-80
    800028e8:	e486                	sd	ra,72(sp)
    800028ea:	e0a2                	sd	s0,64(sp)
    800028ec:	fc26                	sd	s1,56(sp)
    800028ee:	f84a                	sd	s2,48(sp)
    800028f0:	f44e                	sd	s3,40(sp)
    800028f2:	f052                	sd	s4,32(sp)
    800028f4:	ec56                	sd	s5,24(sp)
    800028f6:	e85a                	sd	s6,16(sp)
    800028f8:	e45e                	sd	s7,8(sp)
    800028fa:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	c0450513          	addi	a0,a0,-1020 # 80008500 <states.0+0x80>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c82080e7          	jalr	-894(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000290c:	0011f497          	auipc	s1,0x11f
    80002910:	9ec48493          	addi	s1,s1,-1556 # 801212f8 <proc+0x158>
    80002914:	00124917          	auipc	s2,0x124
    80002918:	3e490913          	addi	s2,s2,996 # 80126cf8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000291c:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000291e:	00006997          	auipc	s3,0x6
    80002922:	a4a98993          	addi	s3,s3,-1462 # 80008368 <digits+0x318>
        printf("%d <%s %s", p->pid, state, p->name);
    80002926:	00006a97          	auipc	s5,0x6
    8000292a:	a4aa8a93          	addi	s5,s5,-1462 # 80008370 <digits+0x320>
        printf("\n");
    8000292e:	00006a17          	auipc	s4,0x6
    80002932:	bd2a0a13          	addi	s4,s4,-1070 # 80008500 <states.0+0x80>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002936:	00006b97          	auipc	s7,0x6
    8000293a:	b4ab8b93          	addi	s7,s7,-1206 # 80008480 <states.0>
    8000293e:	a00d                	j	80002960 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002940:	ed86a583          	lw	a1,-296(a3)
    80002944:	8556                	mv	a0,s5
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c40080e7          	jalr	-960(ra) # 80000586 <printf>
        printf("\n");
    8000294e:	8552                	mv	a0,s4
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c36080e7          	jalr	-970(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002958:	16848493          	addi	s1,s1,360
    8000295c:	03248263          	beq	s1,s2,80002980 <procdump+0x9a>
        if (p->state == UNUSED)
    80002960:	86a6                	mv	a3,s1
    80002962:	ec04a783          	lw	a5,-320(s1)
    80002966:	dbed                	beqz	a5,80002958 <procdump+0x72>
            state = "???";
    80002968:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000296a:	fcfb6be3          	bltu	s6,a5,80002940 <procdump+0x5a>
    8000296e:	02079713          	slli	a4,a5,0x20
    80002972:	01d75793          	srli	a5,a4,0x1d
    80002976:	97de                	add	a5,a5,s7
    80002978:	6390                	ld	a2,0(a5)
    8000297a:	f279                	bnez	a2,80002940 <procdump+0x5a>
            state = "???";
    8000297c:	864e                	mv	a2,s3
    8000297e:	b7c9                	j	80002940 <procdump+0x5a>
    }
}
    80002980:	60a6                	ld	ra,72(sp)
    80002982:	6406                	ld	s0,64(sp)
    80002984:	74e2                	ld	s1,56(sp)
    80002986:	7942                	ld	s2,48(sp)
    80002988:	79a2                	ld	s3,40(sp)
    8000298a:	7a02                	ld	s4,32(sp)
    8000298c:	6ae2                	ld	s5,24(sp)
    8000298e:	6b42                	ld	s6,16(sp)
    80002990:	6ba2                	ld	s7,8(sp)
    80002992:	6161                	addi	sp,sp,80
    80002994:	8082                	ret

0000000080002996 <schedls>:

void schedls()
{
    80002996:	1141                	addi	sp,sp,-16
    80002998:	e406                	sd	ra,8(sp)
    8000299a:	e022                	sd	s0,0(sp)
    8000299c:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	9e250513          	addi	a0,a0,-1566 # 80008380 <digits+0x330>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	be0080e7          	jalr	-1056(ra) # 80000586 <printf>
    printf("====================================\n");
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	9fa50513          	addi	a0,a0,-1542 # 800083a8 <digits+0x358>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	bd0080e7          	jalr	-1072(ra) # 80000586 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029be:	00006717          	auipc	a4,0x6
    800029c2:	0ea73703          	ld	a4,234(a4) # 80008aa8 <available_schedulers+0x10>
    800029c6:	00006797          	auipc	a5,0x6
    800029ca:	0827b783          	ld	a5,130(a5) # 80008a48 <sched_pointer>
    800029ce:	04f70663          	beq	a4,a5,80002a1a <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	a0650513          	addi	a0,a0,-1530 # 800083d8 <digits+0x388>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	bac080e7          	jalr	-1108(ra) # 80000586 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800029e2:	00006617          	auipc	a2,0x6
    800029e6:	0ce62603          	lw	a2,206(a2) # 80008ab0 <available_schedulers+0x18>
    800029ea:	00006597          	auipc	a1,0x6
    800029ee:	0ae58593          	addi	a1,a1,174 # 80008a98 <available_schedulers>
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9ee50513          	addi	a0,a0,-1554 # 800083e0 <digits+0x390>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b8c080e7          	jalr	-1140(ra) # 80000586 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	9e650513          	addi	a0,a0,-1562 # 800083e8 <digits+0x398>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7c080e7          	jalr	-1156(ra) # 80000586 <printf>
}
    80002a12:	60a2                	ld	ra,8(sp)
    80002a14:	6402                	ld	s0,0(sp)
    80002a16:	0141                	addi	sp,sp,16
    80002a18:	8082                	ret
            printf("[*]\t");
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	9b650513          	addi	a0,a0,-1610 # 800083d0 <digits+0x380>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b64080e7          	jalr	-1180(ra) # 80000586 <printf>
    80002a2a:	bf65                	j	800029e2 <schedls+0x4c>

0000000080002a2c <schedset>:

void schedset(int id)
{
    80002a2c:	1141                	addi	sp,sp,-16
    80002a2e:	e406                	sd	ra,8(sp)
    80002a30:	e022                	sd	s0,0(sp)
    80002a32:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002a34:	e90d                	bnez	a0,80002a66 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a36:	00006797          	auipc	a5,0x6
    80002a3a:	0727b783          	ld	a5,114(a5) # 80008aa8 <available_schedulers+0x10>
    80002a3e:	00006717          	auipc	a4,0x6
    80002a42:	00f73523          	sd	a5,10(a4) # 80008a48 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a46:	00006597          	auipc	a1,0x6
    80002a4a:	05258593          	addi	a1,a1,82 # 80008a98 <available_schedulers>
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	9da50513          	addi	a0,a0,-1574 # 80008428 <digits+0x3d8>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	b30080e7          	jalr	-1232(ra) # 80000586 <printf>
}
    80002a5e:	60a2                	ld	ra,8(sp)
    80002a60:	6402                	ld	s0,0(sp)
    80002a62:	0141                	addi	sp,sp,16
    80002a64:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	99a50513          	addi	a0,a0,-1638 # 80008400 <digits+0x3b0>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	b18080e7          	jalr	-1256(ra) # 80000586 <printf>
        return;
    80002a76:	b7e5                	j	80002a5e <schedset+0x32>

0000000080002a78 <proc_va2pa>:

uint64 proc_va2pa(uint64 vaddr, int pid)
{
    80002a78:	7179                	addi	sp,sp,-48
    80002a7a:	f406                	sd	ra,40(sp)
    80002a7c:	f022                	sd	s0,32(sp)
    80002a7e:	ec26                	sd	s1,24(sp)
    80002a80:	e84a                	sd	s2,16(sp)
    80002a82:	e44e                	sd	s3,8(sp)
    80002a84:	e052                	sd	s4,0(sp)
    80002a86:	1800                	addi	s0,sp,48
    80002a88:	8a2a                	mv	s4,a0
    80002a8a:	892e                	mv	s2,a1
    pagetable_t pt = myproc()->pagetable;
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	23e080e7          	jalr	574(ra) # 80001cca <myproc>
    80002a94:	05053983          	ld	s3,80(a0)
    if (pid > 0)
    80002a98:	05205a63          	blez	s2,80002aec <proc_va2pa+0x74>
    {
        struct proc *p;
        for (p = proc; p < &proc[NPROC]; p++)
    80002a9c:	0011e497          	auipc	s1,0x11e
    80002aa0:	70448493          	addi	s1,s1,1796 # 801211a0 <proc>
    80002aa4:	00124997          	auipc	s3,0x124
    80002aa8:	0fc98993          	addi	s3,s3,252 # 80126ba0 <tickslock>
        {
            acquire(&p->lock);
    80002aac:	8526                	mv	a0,s1
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	1e0080e7          	jalr	480(ra) # 80000c8e <acquire>
            if (p->pid == pid)
    80002ab6:	589c                	lw	a5,48(s1)
    80002ab8:	01278d63          	beq	a5,s2,80002ad2 <proc_va2pa+0x5a>
            {
                pt = p->pagetable;
                release(&p->lock);
                break;
            }
            release(&p->lock);
    80002abc:	8526                	mv	a0,s1
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	284080e7          	jalr	644(ra) # 80000d42 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002ac6:	16848493          	addi	s1,s1,360
    80002aca:	ff3491e3          	bne	s1,s3,80002aac <proc_va2pa+0x34>
        }
        if (p == &proc[NPROC])
        {
            return 0; // proc not found
    80002ace:	4501                	li	a0,0
    80002ad0:	a81d                	j	80002b06 <proc_va2pa+0x8e>
                pt = p->pagetable;
    80002ad2:	0504b983          	ld	s3,80(s1)
                release(&p->lock);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	26a080e7          	jalr	618(ra) # 80000d42 <release>
        if (p == &proc[NPROC])
    80002ae0:	00124797          	auipc	a5,0x124
    80002ae4:	0c078793          	addi	a5,a5,192 # 80126ba0 <tickslock>
    80002ae8:	02f48763          	beq	s1,a5,80002b16 <proc_va2pa+0x9e>
        }
    }
    uint64 pa = walkaddr(pt, vaddr);
    80002aec:	4601                	li	a2,0
    80002aee:	85d2                	mv	a1,s4
    80002af0:	854e                	mv	a0,s3
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	620080e7          	jalr	1568(ra) # 80001112 <walkaddrf>
    if (pa != 0)
    80002afa:	c511                	beqz	a0,80002b06 <proc_va2pa+0x8e>
    {
        pa |= (0xFFF & vaddr); // add offset to the physical address
    80002afc:	1a52                	slli	s4,s4,0x34
    80002afe:	034a5a13          	srli	s4,s4,0x34
    80002b02:	01456533          	or	a0,a0,s4
    }
    return pa;
    80002b06:	70a2                	ld	ra,40(sp)
    80002b08:	7402                	ld	s0,32(sp)
    80002b0a:	64e2                	ld	s1,24(sp)
    80002b0c:	6942                	ld	s2,16(sp)
    80002b0e:	69a2                	ld	s3,8(sp)
    80002b10:	6a02                	ld	s4,0(sp)
    80002b12:	6145                	addi	sp,sp,48
    80002b14:	8082                	ret
            return 0; // proc not found
    80002b16:	4501                	li	a0,0
    80002b18:	b7fd                	j	80002b06 <proc_va2pa+0x8e>

0000000080002b1a <swtch>:
    80002b1a:	00153023          	sd	ra,0(a0)
    80002b1e:	00253423          	sd	sp,8(a0)
    80002b22:	e900                	sd	s0,16(a0)
    80002b24:	ed04                	sd	s1,24(a0)
    80002b26:	03253023          	sd	s2,32(a0)
    80002b2a:	03353423          	sd	s3,40(a0)
    80002b2e:	03453823          	sd	s4,48(a0)
    80002b32:	03553c23          	sd	s5,56(a0)
    80002b36:	05653023          	sd	s6,64(a0)
    80002b3a:	05753423          	sd	s7,72(a0)
    80002b3e:	05853823          	sd	s8,80(a0)
    80002b42:	05953c23          	sd	s9,88(a0)
    80002b46:	07a53023          	sd	s10,96(a0)
    80002b4a:	07b53423          	sd	s11,104(a0)
    80002b4e:	0005b083          	ld	ra,0(a1)
    80002b52:	0085b103          	ld	sp,8(a1)
    80002b56:	6980                	ld	s0,16(a1)
    80002b58:	6d84                	ld	s1,24(a1)
    80002b5a:	0205b903          	ld	s2,32(a1)
    80002b5e:	0285b983          	ld	s3,40(a1)
    80002b62:	0305ba03          	ld	s4,48(a1)
    80002b66:	0385ba83          	ld	s5,56(a1)
    80002b6a:	0405bb03          	ld	s6,64(a1)
    80002b6e:	0485bb83          	ld	s7,72(a1)
    80002b72:	0505bc03          	ld	s8,80(a1)
    80002b76:	0585bc83          	ld	s9,88(a1)
    80002b7a:	0605bd03          	ld	s10,96(a1)
    80002b7e:	0685bd83          	ld	s11,104(a1)
    80002b82:	8082                	ret

0000000080002b84 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b84:	1141                	addi	sp,sp,-16
    80002b86:	e406                	sd	ra,8(sp)
    80002b88:	e022                	sd	s0,0(sp)
    80002b8a:	0800                	addi	s0,sp,16
    initlock(&tickslock, "time");
    80002b8c:	00006597          	auipc	a1,0x6
    80002b90:	92458593          	addi	a1,a1,-1756 # 800084b0 <states.0+0x30>
    80002b94:	00124517          	auipc	a0,0x124
    80002b98:	00c50513          	addi	a0,a0,12 # 80126ba0 <tickslock>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	062080e7          	jalr	98(ra) # 80000bfe <initlock>
}
    80002ba4:	60a2                	ld	ra,8(sp)
    80002ba6:	6402                	ld	s0,0(sp)
    80002ba8:	0141                	addi	sp,sp,16
    80002baa:	8082                	ret

0000000080002bac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e422                	sd	s0,8(sp)
    80002bb0:	0800                	addi	s0,sp,16
    asm volatile("csrw stvec, %0"
    80002bb2:	00003797          	auipc	a5,0x3
    80002bb6:	65e78793          	addi	a5,a5,1630 # 80006210 <kernelvec>
    80002bba:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    80002bbe:	6422                	ld	s0,8(sp)
    80002bc0:	0141                	addi	sp,sp,16
    80002bc2:	8082                	ret

0000000080002bc4 <usertrapret>:
}
//
// return to user space
//
void usertrapret(void)
{
    80002bc4:	1141                	addi	sp,sp,-16
    80002bc6:	e406                	sd	ra,8(sp)
    80002bc8:	e022                	sd	s0,0(sp)
    80002bca:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	0fe080e7          	jalr	254(ra) # 80001cca <myproc>
    asm volatile("csrr %0, sstatus"
    80002bd4:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd8:	9bf5                	andi	a5,a5,-3
    asm volatile("csrw sstatus, %0"
    80002bda:	10079073          	csrw	sstatus,a5
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bde:	00004697          	auipc	a3,0x4
    80002be2:	42268693          	addi	a3,a3,1058 # 80007000 <_trampoline>
    80002be6:	00004717          	auipc	a4,0x4
    80002bea:	41a70713          	addi	a4,a4,1050 # 80007000 <_trampoline>
    80002bee:	8f15                	sub	a4,a4,a3
    80002bf0:	040007b7          	lui	a5,0x4000
    80002bf4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bf6:	07b2                	slli	a5,a5,0xc
    80002bf8:	973e                	add	a4,a4,a5
    asm volatile("csrw stvec, %0"
    80002bfa:	10571073          	csrw	stvec,a4
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfe:	6d38                	ld	a4,88(a0)
    asm volatile("csrr %0, satp"
    80002c00:	18002673          	csrr	a2,satp
    80002c04:	e310                	sd	a2,0(a4)
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c06:	6d30                	ld	a2,88(a0)
    80002c08:	6138                	ld	a4,64(a0)
    80002c0a:	6585                	lui	a1,0x1
    80002c0c:	972e                	add	a4,a4,a1
    80002c0e:	e618                	sd	a4,8(a2)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80002c10:	6d38                	ld	a4,88(a0)
    80002c12:	00000617          	auipc	a2,0x0
    80002c16:	13460613          	addi	a2,a2,308 # 80002d46 <usertrap>
    80002c1a:	eb10                	sd	a2,16(a4)
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c1c:	6d38                	ld	a4,88(a0)
    asm volatile("mv %0, tp"
    80002c1e:	8612                	mv	a2,tp
    80002c20:	f310                	sd	a2,32(a4)
    asm volatile("csrr %0, sstatus"
    80002c22:	10002773          	csrr	a4,sstatus
    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c26:	eff77713          	andi	a4,a4,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c2a:	02076713          	ori	a4,a4,32
    asm volatile("csrw sstatus, %0"
    80002c2e:	10071073          	csrw	sstatus,a4
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);
    80002c32:	6d38                	ld	a4,88(a0)
    asm volatile("csrw sepc, %0"
    80002c34:	6f18                	ld	a4,24(a4)
    80002c36:	14171073          	csrw	sepc,a4

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);
    80002c3a:	6928                	ld	a0,80(a0)
    80002c3c:	8131                	srli	a0,a0,0xc

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c3e:	00004717          	auipc	a4,0x4
    80002c42:	45e70713          	addi	a4,a4,1118 # 8000709c <userret>
    80002c46:	8f15                	sub	a4,a4,a3
    80002c48:	97ba                	add	a5,a5,a4
    ((void (*)(uint64))trampoline_userret)(satp);
    80002c4a:	577d                	li	a4,-1
    80002c4c:	177e                	slli	a4,a4,0x3f
    80002c4e:	8d59                	or	a0,a0,a4
    80002c50:	9782                	jalr	a5
}
    80002c52:	60a2                	ld	ra,8(sp)
    80002c54:	6402                	ld	s0,0(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <clockintr>:
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    80002c64:	00124497          	auipc	s1,0x124
    80002c68:	f3c48493          	addi	s1,s1,-196 # 80126ba0 <tickslock>
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	020080e7          	jalr	32(ra) # 80000c8e <acquire>
    ticks++;
    80002c76:	00006517          	auipc	a0,0x6
    80002c7a:	e8a50513          	addi	a0,a0,-374 # 80008b00 <ticks>
    80002c7e:	411c                	lw	a5,0(a0)
    80002c80:	2785                	addiw	a5,a5,1
    80002c82:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	812080e7          	jalr	-2030(ra) # 80002496 <wakeup>
    release(&tickslock);
    80002c8c:	8526                	mv	a0,s1
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	0b4080e7          	jalr	180(ra) # 80000d42 <release>
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <devintr>:
    asm volatile("csrr %0, scause"
    80002ca0:	142027f3          	csrr	a5,scause

        return 2;
    }
    else
    {
        return 0;
    80002ca4:	4501                	li	a0,0
    if ((scause & 0x8000000000000000L) &&
    80002ca6:	0807df63          	bgez	a5,80002d44 <devintr+0xa4>
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
        (scause & 0xff) == 9)
    80002cb4:	0ff7f713          	zext.b	a4,a5
    if ((scause & 0x8000000000000000L) &&
    80002cb8:	46a5                	li	a3,9
    80002cba:	00d70d63          	beq	a4,a3,80002cd4 <devintr+0x34>
    else if (scause == 0x8000000000000001L)
    80002cbe:	577d                	li	a4,-1
    80002cc0:	177e                	slli	a4,a4,0x3f
    80002cc2:	0705                	addi	a4,a4,1
        return 0;
    80002cc4:	4501                	li	a0,0
    else if (scause == 0x8000000000000001L)
    80002cc6:	04e78e63          	beq	a5,a4,80002d22 <devintr+0x82>
    }
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret
        int irq = plic_claim();
    80002cd4:	00003097          	auipc	ra,0x3
    80002cd8:	644080e7          	jalr	1604(ra) # 80006318 <plic_claim>
    80002cdc:	84aa                	mv	s1,a0
        if (irq == UART0_IRQ)
    80002cde:	47a9                	li	a5,10
    80002ce0:	02f50763          	beq	a0,a5,80002d0e <devintr+0x6e>
        else if (irq == VIRTIO0_IRQ)
    80002ce4:	4785                	li	a5,1
    80002ce6:	02f50963          	beq	a0,a5,80002d18 <devintr+0x78>
        return 1;
    80002cea:	4505                	li	a0,1
        else if (irq)
    80002cec:	dcf9                	beqz	s1,80002cca <devintr+0x2a>
            printf("unexpected interrupt irq=%d\n", irq);
    80002cee:	85a6                	mv	a1,s1
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	7c850513          	addi	a0,a0,1992 # 800084b8 <states.0+0x38>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	88e080e7          	jalr	-1906(ra) # 80000586 <printf>
            plic_complete(irq);
    80002d00:	8526                	mv	a0,s1
    80002d02:	00003097          	auipc	ra,0x3
    80002d06:	63a080e7          	jalr	1594(ra) # 8000633c <plic_complete>
        return 1;
    80002d0a:	4505                	li	a0,1
    80002d0c:	bf7d                	j	80002cca <devintr+0x2a>
            uartintr();
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	c86080e7          	jalr	-890(ra) # 80000994 <uartintr>
        if (irq)
    80002d16:	b7ed                	j	80002d00 <devintr+0x60>
            virtio_disk_intr();
    80002d18:	00004097          	auipc	ra,0x4
    80002d1c:	aea080e7          	jalr	-1302(ra) # 80006802 <virtio_disk_intr>
        if (irq)
    80002d20:	b7c5                	j	80002d00 <devintr+0x60>
        if (cpuid() == 0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	f7c080e7          	jalr	-132(ra) # 80001c9e <cpuid>
    80002d2a:	c901                	beqz	a0,80002d3a <devintr+0x9a>
    asm volatile("csrr %0, sip"
    80002d2c:	144027f3          	csrr	a5,sip
        w_sip(r_sip() & ~2);
    80002d30:	9bf5                	andi	a5,a5,-3
    asm volatile("csrw sip, %0"
    80002d32:	14479073          	csrw	sip,a5
        return 2;
    80002d36:	4509                	li	a0,2
    80002d38:	bf49                	j	80002cca <devintr+0x2a>
            clockintr();
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	f20080e7          	jalr	-224(ra) # 80002c5a <clockintr>
    80002d42:	b7ed                	j	80002d2c <devintr+0x8c>
}
    80002d44:	8082                	ret

0000000080002d46 <usertrap>:
{
    80002d46:	7139                	addi	sp,sp,-64
    80002d48:	fc06                	sd	ra,56(sp)
    80002d4a:	f822                	sd	s0,48(sp)
    80002d4c:	f426                	sd	s1,40(sp)
    80002d4e:	f04a                	sd	s2,32(sp)
    80002d50:	ec4e                	sd	s3,24(sp)
    80002d52:	e852                	sd	s4,16(sp)
    80002d54:	e456                	sd	s5,8(sp)
    80002d56:	0080                	addi	s0,sp,64
    asm volatile("csrr %0, sstatus"
    80002d58:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d5c:	1007f793          	andi	a5,a5,256
    80002d60:	efb5                	bnez	a5,80002ddc <usertrap+0x96>
    asm volatile("csrw stvec, %0"
    80002d62:	00003797          	auipc	a5,0x3
    80002d66:	4ae78793          	addi	a5,a5,1198 # 80006210 <kernelvec>
    80002d6a:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	f5c080e7          	jalr	-164(ra) # 80001cca <myproc>
    80002d76:	84aa                	mv	s1,a0
    p->trapframe->epc = r_sepc();
    80002d78:	6d3c                	ld	a5,88(a0)
    asm volatile("csrr %0, sepc"
    80002d7a:	14102773          	csrr	a4,sepc
    80002d7e:	ef98                	sd	a4,24(a5)
    asm volatile("csrr %0, scause"
    80002d80:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    80002d84:	47a1                	li	a5,8
    80002d86:	06f70363          	beq	a4,a5,80002dec <usertrap+0xa6>
    else if ((which_dev = devintr()) != 0)
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	f16080e7          	jalr	-234(ra) # 80002ca0 <devintr>
    80002d92:	892a                	mv	s2,a0
    80002d94:	18051663          	bnez	a0,80002f20 <usertrap+0x1da>
    80002d98:	14202773          	csrr	a4,scause
    else if (r_scause() == 15)
    80002d9c:	47bd                	li	a5,15
    80002d9e:	0af70463          	beq	a4,a5,80002e46 <usertrap+0x100>
    80002da2:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002da6:	5890                	lw	a2,48(s1)
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	77050513          	addi	a0,a0,1904 # 80008518 <states.0+0x98>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	7d6080e7          	jalr	2006(ra) # 80000586 <printf>
    asm volatile("csrr %0, sepc"
    80002db8:	141025f3          	csrr	a1,sepc
    asm volatile("csrr %0, stval"
    80002dbc:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	78850513          	addi	a0,a0,1928 # 80008548 <states.0+0xc8>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	7be080e7          	jalr	1982(ra) # 80000586 <printf>
        setkilled(p);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	8dc080e7          	jalr	-1828(ra) # 800026ae <setkilled>
    80002dda:	a825                	j	80002e12 <usertrap+0xcc>
        panic("usertrap: not from user mode");
    80002ddc:	00005517          	auipc	a0,0x5
    80002de0:	6fc50513          	addi	a0,a0,1788 # 800084d8 <states.0+0x58>
    80002de4:	ffffd097          	auipc	ra,0xffffd
    80002de8:	758080e7          	jalr	1880(ra) # 8000053c <panic>
        if (killed(p))
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	8ee080e7          	jalr	-1810(ra) # 800026da <killed>
    80002df4:	e139                	bnez	a0,80002e3a <usertrap+0xf4>
        p->trapframe->epc += 4;
    80002df6:	6cb8                	ld	a4,88(s1)
    80002df8:	6f1c                	ld	a5,24(a4)
    80002dfa:	0791                	addi	a5,a5,4
    80002dfc:	ef1c                	sd	a5,24(a4)
    asm volatile("csrr %0, sstatus"
    80002dfe:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e02:	0027e793          	ori	a5,a5,2
    asm volatile("csrw sstatus, %0"
    80002e06:	10079073          	csrw	sstatus,a5
        syscall();
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	38a080e7          	jalr	906(ra) # 80003194 <syscall>
    if (killed(p))
    80002e12:	8526                	mv	a0,s1
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	8c6080e7          	jalr	-1850(ra) # 800026da <killed>
    80002e1c:	10051963          	bnez	a0,80002f2e <usertrap+0x1e8>
    usertrapret();
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	da4080e7          	jalr	-604(ra) # 80002bc4 <usertrapret>
}
    80002e28:	70e2                	ld	ra,56(sp)
    80002e2a:	7442                	ld	s0,48(sp)
    80002e2c:	74a2                	ld	s1,40(sp)
    80002e2e:	7902                	ld	s2,32(sp)
    80002e30:	69e2                	ld	s3,24(sp)
    80002e32:	6a42                	ld	s4,16(sp)
    80002e34:	6aa2                	ld	s5,8(sp)
    80002e36:	6121                	addi	sp,sp,64
    80002e38:	8082                	ret
            exit(-1);
    80002e3a:	557d                	li	a0,-1
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	72a080e7          	jalr	1834(ra) # 80002566 <exit>
    80002e44:	bf4d                	j	80002df6 <usertrap+0xb0>
    asm volatile("csrr %0, stval"
    80002e46:	143029f3          	csrr	s3,stval
        uint64 vba = PGROUNDDOWN(r_stval()); // get virtual base address of page
    80002e4a:	77fd                	lui	a5,0xfffff
    80002e4c:	00f9f9b3          	and	s3,s3,a5
        pte = walk(p->pagetable, vba, 0); // don't allocate
    80002e50:	4601                	li	a2,0
    80002e52:	85ce                	mv	a1,s3
    80002e54:	68a8                	ld	a0,80(s1)
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	216080e7          	jalr	534(ra) # 8000106c <walk>
    80002e5e:	892a                	mv	s2,a0
        if (pte == 0)
    80002e60:	c915                	beqz	a0,80002e94 <usertrap+0x14e>
        if ((*pte & PTE_V) && (*pte & PTE_U) && (*pte & PTE_COW) && (*pte & (PTE_R | PTE_X)))
    80002e62:	00093a03          	ld	s4,0(s2)
    80002e66:	031a7713          	andi	a4,s4,49
    80002e6a:	03100793          	li	a5,49
    80002e6e:	00f71563          	bne	a4,a5,80002e78 <usertrap+0x132>
    80002e72:	00aa7793          	andi	a5,s4,10
    80002e76:	ef8d                	bnez	a5,80002eb0 <usertrap+0x16a>
            printf("SEGFAULT");
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	69050513          	addi	a0,a0,1680 # 80008508 <states.0+0x88>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	706080e7          	jalr	1798(ra) # 80000586 <printf>
            setkilled(p);
    80002e88:	8526                	mv	a0,s1
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	824080e7          	jalr	-2012(ra) # 800026ae <setkilled>
    80002e92:	b741                	j	80002e12 <usertrap+0xcc>
            printf("SEGFAULT\n");
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	66450513          	addi	a0,a0,1636 # 800084f8 <states.0+0x78>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6ea080e7          	jalr	1770(ra) # 80000586 <printf>
            setkilled(p);
    80002ea4:	8526                	mv	a0,s1
    80002ea6:	00000097          	auipc	ra,0x0
    80002eaa:	808080e7          	jalr	-2040(ra) # 800026ae <setkilled>
    80002eae:	bf55                	j	80002e62 <usertrap+0x11c>
            void *mem = kalloc();
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	c98080e7          	jalr	-872(ra) # 80000b48 <kalloc>
    80002eb8:	8aaa                	mv	s5,a0
            void *pa = (void *)PTE2PA(*pte);
    80002eba:	00093903          	ld	s2,0(s2)
    80002ebe:	00a95913          	srli	s2,s2,0xa
    80002ec2:	0932                	slli	s2,s2,0xc
            memmove(mem, pa, PGSIZE);
    80002ec4:	6605                	lui	a2,0x1
    80002ec6:	85ca                	mv	a1,s2
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	f1e080e7          	jalr	-226(ra) # 80000de6 <memmove>
            uvmunmap(p->pagetable, vba, 1, 0);
    80002ed0:	4681                	li	a3,0
    80002ed2:	4605                	li	a2,1
    80002ed4:	85ce                	mv	a1,s3
    80002ed6:	68a8                	ld	a0,80(s1)
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	5a4080e7          	jalr	1444(ra) # 8000147c <uvmunmap>
            dec_ref(pa);
    80002ee0:	854a                	mv	a0,s2
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	51e080e7          	jalr	1310(ra) # 80001400 <dec_ref>
            flags &= (~PTE_COW);
    80002eea:	3dfa7713          	andi	a4,s4,991
            if (mappages(p->pagetable, vba, PGSIZE, (uint64)mem, flags) != 0)
    80002eee:	00476713          	ori	a4,a4,4
    80002ef2:	86d6                	mv	a3,s5
    80002ef4:	6605                	lui	a2,0x1
    80002ef6:	85ce                	mv	a1,s3
    80002ef8:	68a8                	ld	a0,80(s1)
    80002efa:	ffffe097          	auipc	ra,0xffffe
    80002efe:	268080e7          	jalr	616(ra) # 80001162 <mappages>
    80002f02:	d901                	beqz	a0,80002e12 <usertrap+0xcc>
                setkilled(p);
    80002f04:	8526                	mv	a0,s1
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	7a8080e7          	jalr	1960(ra) # 800026ae <setkilled>
                printf("SEGFAULT");
    80002f0e:	00005517          	auipc	a0,0x5
    80002f12:	5fa50513          	addi	a0,a0,1530 # 80008508 <states.0+0x88>
    80002f16:	ffffd097          	auipc	ra,0xffffd
    80002f1a:	670080e7          	jalr	1648(ra) # 80000586 <printf>
    80002f1e:	bdd5                	j	80002e12 <usertrap+0xcc>
    if (killed(p))
    80002f20:	8526                	mv	a0,s1
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	7b8080e7          	jalr	1976(ra) # 800026da <killed>
    80002f2a:	c901                	beqz	a0,80002f3a <usertrap+0x1f4>
    80002f2c:	a011                	j	80002f30 <usertrap+0x1ea>
    80002f2e:	4901                	li	s2,0
        exit(-1);
    80002f30:	557d                	li	a0,-1
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	634080e7          	jalr	1588(ra) # 80002566 <exit>
    if (which_dev == 2)
    80002f3a:	4789                	li	a5,2
    80002f3c:	eef912e3          	bne	s2,a5,80002e20 <usertrap+0xda>
        yield();
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	4b6080e7          	jalr	1206(ra) # 800023f6 <yield>
    80002f48:	bde1                	j	80002e20 <usertrap+0xda>

0000000080002f4a <kerneltrap>:
{
    80002f4a:	7179                	addi	sp,sp,-48
    80002f4c:	f406                	sd	ra,40(sp)
    80002f4e:	f022                	sd	s0,32(sp)
    80002f50:	ec26                	sd	s1,24(sp)
    80002f52:	e84a                	sd	s2,16(sp)
    80002f54:	e44e                	sd	s3,8(sp)
    80002f56:	1800                	addi	s0,sp,48
    asm volatile("csrr %0, sepc"
    80002f58:	14102973          	csrr	s2,sepc
    asm volatile("csrr %0, sstatus"
    80002f5c:	100024f3          	csrr	s1,sstatus
    asm volatile("csrr %0, scause"
    80002f60:	142029f3          	csrr	s3,scause
    if ((sstatus & SSTATUS_SPP) == 0)
    80002f64:	1004f793          	andi	a5,s1,256
    80002f68:	cb85                	beqz	a5,80002f98 <kerneltrap+0x4e>
    asm volatile("csrr %0, sstatus"
    80002f6a:	100027f3          	csrr	a5,sstatus
    return (x & SSTATUS_SIE) != 0;
    80002f6e:	8b89                	andi	a5,a5,2
    if (intr_get() != 0)
    80002f70:	ef85                	bnez	a5,80002fa8 <kerneltrap+0x5e>
    if ((which_dev = devintr()) == 0)
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	d2e080e7          	jalr	-722(ra) # 80002ca0 <devintr>
    80002f7a:	cd1d                	beqz	a0,80002fb8 <kerneltrap+0x6e>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f7c:	4789                	li	a5,2
    80002f7e:	06f50a63          	beq	a0,a5,80002ff2 <kerneltrap+0xa8>
    asm volatile("csrw sepc, %0"
    80002f82:	14191073          	csrw	sepc,s2
    asm volatile("csrw sstatus, %0"
    80002f86:	10049073          	csrw	sstatus,s1
}
    80002f8a:	70a2                	ld	ra,40(sp)
    80002f8c:	7402                	ld	s0,32(sp)
    80002f8e:	64e2                	ld	s1,24(sp)
    80002f90:	6942                	ld	s2,16(sp)
    80002f92:	69a2                	ld	s3,8(sp)
    80002f94:	6145                	addi	sp,sp,48
    80002f96:	8082                	ret
        panic("kerneltrap: not from supervisor mode");
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	5d050513          	addi	a0,a0,1488 # 80008568 <states.0+0xe8>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	59c080e7          	jalr	1436(ra) # 8000053c <panic>
        panic("kerneltrap: interrupts enabled");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	5e850513          	addi	a0,a0,1512 # 80008590 <states.0+0x110>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	58c080e7          	jalr	1420(ra) # 8000053c <panic>
        printf("scause %p\n", scause);
    80002fb8:	85ce                	mv	a1,s3
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	5f650513          	addi	a0,a0,1526 # 800085b0 <states.0+0x130>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	5c4080e7          	jalr	1476(ra) # 80000586 <printf>
    asm volatile("csrr %0, sepc"
    80002fca:	141025f3          	csrr	a1,sepc
    asm volatile("csrr %0, stval"
    80002fce:	14302673          	csrr	a2,stval
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	5ee50513          	addi	a0,a0,1518 # 800085c0 <states.0+0x140>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5ac080e7          	jalr	1452(ra) # 80000586 <printf>
        panic("kerneltrap");
    80002fe2:	00005517          	auipc	a0,0x5
    80002fe6:	5f650513          	addi	a0,a0,1526 # 800085d8 <states.0+0x158>
    80002fea:	ffffd097          	auipc	ra,0xffffd
    80002fee:	552080e7          	jalr	1362(ra) # 8000053c <panic>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	cd8080e7          	jalr	-808(ra) # 80001cca <myproc>
    80002ffa:	d541                	beqz	a0,80002f82 <kerneltrap+0x38>
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	cce080e7          	jalr	-818(ra) # 80001cca <myproc>
    80003004:	4d18                	lw	a4,24(a0)
    80003006:	4791                	li	a5,4
    80003008:	f6f71de3          	bne	a4,a5,80002f82 <kerneltrap+0x38>
        yield();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	3ea080e7          	jalr	1002(ra) # 800023f6 <yield>
    80003014:	b7bd                	j	80002f82 <kerneltrap+0x38>

0000000080003016 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	ca8080e7          	jalr	-856(ra) # 80001cca <myproc>
    switch (n)
    8000302a:	4795                	li	a5,5
    8000302c:	0497e163          	bltu	a5,s1,8000306e <argraw+0x58>
    80003030:	048a                	slli	s1,s1,0x2
    80003032:	00005717          	auipc	a4,0x5
    80003036:	5de70713          	addi	a4,a4,1502 # 80008610 <states.0+0x190>
    8000303a:	94ba                	add	s1,s1,a4
    8000303c:	409c                	lw	a5,0(s1)
    8000303e:	97ba                	add	a5,a5,a4
    80003040:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80003042:	6d3c                	ld	a5,88(a0)
    80003044:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret
        return p->trapframe->a1;
    80003050:	6d3c                	ld	a5,88(a0)
    80003052:	7fa8                	ld	a0,120(a5)
    80003054:	bfcd                	j	80003046 <argraw+0x30>
        return p->trapframe->a2;
    80003056:	6d3c                	ld	a5,88(a0)
    80003058:	63c8                	ld	a0,128(a5)
    8000305a:	b7f5                	j	80003046 <argraw+0x30>
        return p->trapframe->a3;
    8000305c:	6d3c                	ld	a5,88(a0)
    8000305e:	67c8                	ld	a0,136(a5)
    80003060:	b7dd                	j	80003046 <argraw+0x30>
        return p->trapframe->a4;
    80003062:	6d3c                	ld	a5,88(a0)
    80003064:	6bc8                	ld	a0,144(a5)
    80003066:	b7c5                	j	80003046 <argraw+0x30>
        return p->trapframe->a5;
    80003068:	6d3c                	ld	a5,88(a0)
    8000306a:	6fc8                	ld	a0,152(a5)
    8000306c:	bfe9                	j	80003046 <argraw+0x30>
    panic("argraw");
    8000306e:	00005517          	auipc	a0,0x5
    80003072:	57a50513          	addi	a0,a0,1402 # 800085e8 <states.0+0x168>
    80003076:	ffffd097          	auipc	ra,0xffffd
    8000307a:	4c6080e7          	jalr	1222(ra) # 8000053c <panic>

000000008000307e <fetchaddr>:
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	e426                	sd	s1,8(sp)
    80003086:	e04a                	sd	s2,0(sp)
    80003088:	1000                	addi	s0,sp,32
    8000308a:	84aa                	mv	s1,a0
    8000308c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	c3c080e7          	jalr	-964(ra) # 80001cca <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003096:	653c                	ld	a5,72(a0)
    80003098:	02f4f863          	bgeu	s1,a5,800030c8 <fetchaddr+0x4a>
    8000309c:	00848713          	addi	a4,s1,8
    800030a0:	02e7e663          	bltu	a5,a4,800030cc <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030a4:	46a1                	li	a3,8
    800030a6:	8626                	mv	a2,s1
    800030a8:	85ca                	mv	a1,s2
    800030aa:	6928                	ld	a0,80(a0)
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	872080e7          	jalr	-1934(ra) # 8000191e <copyin>
    800030b4:	00a03533          	snez	a0,a0
    800030b8:	40a00533          	neg	a0,a0
}
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6902                	ld	s2,0(sp)
    800030c4:	6105                	addi	sp,sp,32
    800030c6:	8082                	ret
        return -1;
    800030c8:	557d                	li	a0,-1
    800030ca:	bfcd                	j	800030bc <fetchaddr+0x3e>
    800030cc:	557d                	li	a0,-1
    800030ce:	b7fd                	j	800030bc <fetchaddr+0x3e>

00000000800030d0 <fetchstr>:
{
    800030d0:	7179                	addi	sp,sp,-48
    800030d2:	f406                	sd	ra,40(sp)
    800030d4:	f022                	sd	s0,32(sp)
    800030d6:	ec26                	sd	s1,24(sp)
    800030d8:	e84a                	sd	s2,16(sp)
    800030da:	e44e                	sd	s3,8(sp)
    800030dc:	1800                	addi	s0,sp,48
    800030de:	892a                	mv	s2,a0
    800030e0:	84ae                	mv	s1,a1
    800030e2:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	be6080e7          	jalr	-1050(ra) # 80001cca <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800030ec:	86ce                	mv	a3,s3
    800030ee:	864a                	mv	a2,s2
    800030f0:	85a6                	mv	a1,s1
    800030f2:	6928                	ld	a0,80(a0)
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	8ba080e7          	jalr	-1862(ra) # 800019ae <copyinstr>
    800030fc:	00054e63          	bltz	a0,80003118 <fetchstr+0x48>
    return strlen(buf);
    80003100:	8526                	mv	a0,s1
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	e02080e7          	jalr	-510(ra) # 80000f04 <strlen>
}
    8000310a:	70a2                	ld	ra,40(sp)
    8000310c:	7402                	ld	s0,32(sp)
    8000310e:	64e2                	ld	s1,24(sp)
    80003110:	6942                	ld	s2,16(sp)
    80003112:	69a2                	ld	s3,8(sp)
    80003114:	6145                	addi	sp,sp,48
    80003116:	8082                	ret
        return -1;
    80003118:	557d                	li	a0,-1
    8000311a:	bfc5                	j	8000310a <fetchstr+0x3a>

000000008000311c <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000311c:	1101                	addi	sp,sp,-32
    8000311e:	ec06                	sd	ra,24(sp)
    80003120:	e822                	sd	s0,16(sp)
    80003122:	e426                	sd	s1,8(sp)
    80003124:	1000                	addi	s0,sp,32
    80003126:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	eee080e7          	jalr	-274(ra) # 80003016 <argraw>
    80003130:	c088                	sw	a0,0(s1)
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret

000000008000313c <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	1000                	addi	s0,sp,32
    80003146:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	ece080e7          	jalr	-306(ra) # 80003016 <argraw>
    80003150:	e088                	sd	a0,0(s1)
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000315c:	7179                	addi	sp,sp,-48
    8000315e:	f406                	sd	ra,40(sp)
    80003160:	f022                	sd	s0,32(sp)
    80003162:	ec26                	sd	s1,24(sp)
    80003164:	e84a                	sd	s2,16(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	84ae                	mv	s1,a1
    8000316a:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000316c:	fd840593          	addi	a1,s0,-40
    80003170:	00000097          	auipc	ra,0x0
    80003174:	fcc080e7          	jalr	-52(ra) # 8000313c <argaddr>
    return fetchstr(addr, buf, max);
    80003178:	864a                	mv	a2,s2
    8000317a:	85a6                	mv	a1,s1
    8000317c:	fd843503          	ld	a0,-40(s0)
    80003180:	00000097          	auipc	ra,0x0
    80003184:	f50080e7          	jalr	-176(ra) # 800030d0 <fetchstr>
}
    80003188:	70a2                	ld	ra,40(sp)
    8000318a:	7402                	ld	s0,32(sp)
    8000318c:	64e2                	ld	s1,24(sp)
    8000318e:	6942                	ld	s2,16(sp)
    80003190:	6145                	addi	sp,sp,48
    80003192:	8082                	ret

0000000080003194 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003194:	1101                	addi	sp,sp,-32
    80003196:	ec06                	sd	ra,24(sp)
    80003198:	e822                	sd	s0,16(sp)
    8000319a:	e426                	sd	s1,8(sp)
    8000319c:	e04a                	sd	s2,0(sp)
    8000319e:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	b2a080e7          	jalr	-1238(ra) # 80001cca <myproc>
    800031a8:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800031aa:	05853903          	ld	s2,88(a0)
    800031ae:	0a893783          	ld	a5,168(s2)
    800031b2:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800031b6:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7fecd07f>
    800031b8:	4765                	li	a4,25
    800031ba:	00f76f63          	bltu	a4,a5,800031d8 <syscall+0x44>
    800031be:	00369713          	slli	a4,a3,0x3
    800031c2:	00005797          	auipc	a5,0x5
    800031c6:	46678793          	addi	a5,a5,1126 # 80008628 <syscalls>
    800031ca:	97ba                	add	a5,a5,a4
    800031cc:	639c                	ld	a5,0(a5)
    800031ce:	c789                	beqz	a5,800031d8 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800031d0:	9782                	jalr	a5
    800031d2:	06a93823          	sd	a0,112(s2)
    800031d6:	a839                	j	800031f4 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800031d8:	15848613          	addi	a2,s1,344
    800031dc:	588c                	lw	a1,48(s1)
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	41250513          	addi	a0,a0,1042 # 800085f0 <states.0+0x170>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	3a0080e7          	jalr	928(ra) # 80000586 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800031ee:	6cbc                	ld	a5,88(s1)
    800031f0:	577d                	li	a4,-1
    800031f2:	fbb8                	sd	a4,112(a5)
    }
}
    800031f4:	60e2                	ld	ra,24(sp)
    800031f6:	6442                	ld	s0,16(sp)
    800031f8:	64a2                	ld	s1,8(sp)
    800031fa:	6902                	ld	s2,0(sp)
    800031fc:	6105                	addi	sp,sp,32
    800031fe:	8082                	ret

0000000080003200 <sys_exit>:
extern struct proc proc[NPROC];
extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80003200:	1101                	addi	sp,sp,-32
    80003202:	ec06                	sd	ra,24(sp)
    80003204:	e822                	sd	s0,16(sp)
    80003206:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003208:	fec40593          	addi	a1,s0,-20
    8000320c:	4501                	li	a0,0
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	f0e080e7          	jalr	-242(ra) # 8000311c <argint>
    exit(n);
    80003216:	fec42503          	lw	a0,-20(s0)
    8000321a:	fffff097          	auipc	ra,0xfffff
    8000321e:	34c080e7          	jalr	844(ra) # 80002566 <exit>
    return 0; // not reached
}
    80003222:	4501                	li	a0,0
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000322c:	1141                	addi	sp,sp,-16
    8000322e:	e406                	sd	ra,8(sp)
    80003230:	e022                	sd	s0,0(sp)
    80003232:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	a96080e7          	jalr	-1386(ra) # 80001cca <myproc>
}
    8000323c:	5908                	lw	a0,48(a0)
    8000323e:	60a2                	ld	ra,8(sp)
    80003240:	6402                	ld	s0,0(sp)
    80003242:	0141                	addi	sp,sp,16
    80003244:	8082                	ret

0000000080003246 <sys_fork>:

uint64
sys_fork(void)
{
    80003246:	1141                	addi	sp,sp,-16
    80003248:	e406                	sd	ra,8(sp)
    8000324a:	e022                	sd	s0,0(sp)
    8000324c:	0800                	addi	s0,sp,16
    return fork();
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	f82080e7          	jalr	-126(ra) # 800021d0 <fork>
}
    80003256:	60a2                	ld	ra,8(sp)
    80003258:	6402                	ld	s0,0(sp)
    8000325a:	0141                	addi	sp,sp,16
    8000325c:	8082                	ret

000000008000325e <sys_wait>:

uint64
sys_wait(void)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003266:	fe840593          	addi	a1,s0,-24
    8000326a:	4501                	li	a0,0
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	ed0080e7          	jalr	-304(ra) # 8000313c <argaddr>
    return wait(p);
    80003274:	fe843503          	ld	a0,-24(s0)
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	494080e7          	jalr	1172(ra) # 8000270c <wait>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret

0000000080003288 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003288:	7179                	addi	sp,sp,-48
    8000328a:	f406                	sd	ra,40(sp)
    8000328c:	f022                	sd	s0,32(sp)
    8000328e:	ec26                	sd	s1,24(sp)
    80003290:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003292:	fdc40593          	addi	a1,s0,-36
    80003296:	4501                	li	a0,0
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	e84080e7          	jalr	-380(ra) # 8000311c <argint>
    addr = myproc()->sz;
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	a2a080e7          	jalr	-1494(ra) # 80001cca <myproc>
    800032a8:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800032aa:	fdc42503          	lw	a0,-36(s0)
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	d76080e7          	jalr	-650(ra) # 80002024 <growproc>
    800032b6:	00054863          	bltz	a0,800032c6 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800032ba:	8526                	mv	a0,s1
    800032bc:	70a2                	ld	ra,40(sp)
    800032be:	7402                	ld	s0,32(sp)
    800032c0:	64e2                	ld	s1,24(sp)
    800032c2:	6145                	addi	sp,sp,48
    800032c4:	8082                	ret
        return -1;
    800032c6:	54fd                	li	s1,-1
    800032c8:	bfcd                	j	800032ba <sys_sbrk+0x32>

00000000800032ca <sys_sleep>:

uint64
sys_sleep(void)
{
    800032ca:	7139                	addi	sp,sp,-64
    800032cc:	fc06                	sd	ra,56(sp)
    800032ce:	f822                	sd	s0,48(sp)
    800032d0:	f426                	sd	s1,40(sp)
    800032d2:	f04a                	sd	s2,32(sp)
    800032d4:	ec4e                	sd	s3,24(sp)
    800032d6:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800032d8:	fcc40593          	addi	a1,s0,-52
    800032dc:	4501                	li	a0,0
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	e3e080e7          	jalr	-450(ra) # 8000311c <argint>
    acquire(&tickslock);
    800032e6:	00124517          	auipc	a0,0x124
    800032ea:	8ba50513          	addi	a0,a0,-1862 # 80126ba0 <tickslock>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	9a0080e7          	jalr	-1632(ra) # 80000c8e <acquire>
    ticks0 = ticks;
    800032f6:	00006917          	auipc	s2,0x6
    800032fa:	80a92903          	lw	s2,-2038(s2) # 80008b00 <ticks>
    while (ticks - ticks0 < n)
    800032fe:	fcc42783          	lw	a5,-52(s0)
    80003302:	cf9d                	beqz	a5,80003340 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003304:	00124997          	auipc	s3,0x124
    80003308:	89c98993          	addi	s3,s3,-1892 # 80126ba0 <tickslock>
    8000330c:	00005497          	auipc	s1,0x5
    80003310:	7f448493          	addi	s1,s1,2036 # 80008b00 <ticks>
        if (killed(myproc()))
    80003314:	fffff097          	auipc	ra,0xfffff
    80003318:	9b6080e7          	jalr	-1610(ra) # 80001cca <myproc>
    8000331c:	fffff097          	auipc	ra,0xfffff
    80003320:	3be080e7          	jalr	958(ra) # 800026da <killed>
    80003324:	ed15                	bnez	a0,80003360 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003326:	85ce                	mv	a1,s3
    80003328:	8526                	mv	a0,s1
    8000332a:	fffff097          	auipc	ra,0xfffff
    8000332e:	108080e7          	jalr	264(ra) # 80002432 <sleep>
    while (ticks - ticks0 < n)
    80003332:	409c                	lw	a5,0(s1)
    80003334:	412787bb          	subw	a5,a5,s2
    80003338:	fcc42703          	lw	a4,-52(s0)
    8000333c:	fce7ece3          	bltu	a5,a4,80003314 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003340:	00124517          	auipc	a0,0x124
    80003344:	86050513          	addi	a0,a0,-1952 # 80126ba0 <tickslock>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	9fa080e7          	jalr	-1542(ra) # 80000d42 <release>
    return 0;
    80003350:	4501                	li	a0,0
}
    80003352:	70e2                	ld	ra,56(sp)
    80003354:	7442                	ld	s0,48(sp)
    80003356:	74a2                	ld	s1,40(sp)
    80003358:	7902                	ld	s2,32(sp)
    8000335a:	69e2                	ld	s3,24(sp)
    8000335c:	6121                	addi	sp,sp,64
    8000335e:	8082                	ret
            release(&tickslock);
    80003360:	00124517          	auipc	a0,0x124
    80003364:	84050513          	addi	a0,a0,-1984 # 80126ba0 <tickslock>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	9da080e7          	jalr	-1574(ra) # 80000d42 <release>
            return -1;
    80003370:	557d                	li	a0,-1
    80003372:	b7c5                	j	80003352 <sys_sleep+0x88>

0000000080003374 <sys_kill>:

uint64
sys_kill(void)
{
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000337c:	fec40593          	addi	a1,s0,-20
    80003380:	4501                	li	a0,0
    80003382:	00000097          	auipc	ra,0x0
    80003386:	d9a080e7          	jalr	-614(ra) # 8000311c <argint>
    return kill(pid);
    8000338a:	fec42503          	lw	a0,-20(s0)
    8000338e:	fffff097          	auipc	ra,0xfffff
    80003392:	2ae080e7          	jalr	686(ra) # 8000263c <kill>
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	6105                	addi	sp,sp,32
    8000339c:	8082                	ret

000000008000339e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000339e:	1101                	addi	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	e426                	sd	s1,8(sp)
    800033a6:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800033a8:	00123517          	auipc	a0,0x123
    800033ac:	7f850513          	addi	a0,a0,2040 # 80126ba0 <tickslock>
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	8de080e7          	jalr	-1826(ra) # 80000c8e <acquire>
    xticks = ticks;
    800033b8:	00005497          	auipc	s1,0x5
    800033bc:	7484a483          	lw	s1,1864(s1) # 80008b00 <ticks>
    release(&tickslock);
    800033c0:	00123517          	auipc	a0,0x123
    800033c4:	7e050513          	addi	a0,a0,2016 # 80126ba0 <tickslock>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	97a080e7          	jalr	-1670(ra) # 80000d42 <release>
    return xticks;
}
    800033d0:	02049513          	slli	a0,s1,0x20
    800033d4:	9101                	srli	a0,a0,0x20
    800033d6:	60e2                	ld	ra,24(sp)
    800033d8:	6442                	ld	s0,16(sp)
    800033da:	64a2                	ld	s1,8(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret

00000000800033e0 <sys_ps>:

void *
sys_ps(void)
{
    800033e0:	1101                	addi	sp,sp,-32
    800033e2:	ec06                	sd	ra,24(sp)
    800033e4:	e822                	sd	s0,16(sp)
    800033e6:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800033e8:	fe042623          	sw	zero,-20(s0)
    800033ec:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800033f0:	fec40593          	addi	a1,s0,-20
    800033f4:	4501                	li	a0,0
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	d26080e7          	jalr	-730(ra) # 8000311c <argint>
    argint(1, &count);
    800033fe:	fe840593          	addi	a1,s0,-24
    80003402:	4505                	li	a0,1
    80003404:	00000097          	auipc	ra,0x0
    80003408:	d18080e7          	jalr	-744(ra) # 8000311c <argint>
    return ps((uint8)start, (uint8)count);
    8000340c:	fe844583          	lbu	a1,-24(s0)
    80003410:	fec44503          	lbu	a0,-20(s0)
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	c6c080e7          	jalr	-916(ra) # 80002080 <ps>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	6105                	addi	sp,sp,32
    80003422:	8082                	ret

0000000080003424 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003424:	1141                	addi	sp,sp,-16
    80003426:	e406                	sd	ra,8(sp)
    80003428:	e022                	sd	s0,0(sp)
    8000342a:	0800                	addi	s0,sp,16
    schedls();
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	56a080e7          	jalr	1386(ra) # 80002996 <schedls>
    return 0;
}
    80003434:	4501                	li	a0,0
    80003436:	60a2                	ld	ra,8(sp)
    80003438:	6402                	ld	s0,0(sp)
    8000343a:	0141                	addi	sp,sp,16
    8000343c:	8082                	ret

000000008000343e <sys_schedset>:

uint64 sys_schedset(void)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	1000                	addi	s0,sp,32
    int id = 0;
    80003446:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000344a:	fec40593          	addi	a1,s0,-20
    8000344e:	4501                	li	a0,0
    80003450:	00000097          	auipc	ra,0x0
    80003454:	ccc080e7          	jalr	-820(ra) # 8000311c <argint>
    schedset(id - 1);
    80003458:	fec42503          	lw	a0,-20(s0)
    8000345c:	357d                	addiw	a0,a0,-1
    8000345e:	fffff097          	auipc	ra,0xfffff
    80003462:	5ce080e7          	jalr	1486(ra) # 80002a2c <schedset>
    return 0;
}
    80003466:	4501                	li	a0,0
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	6105                	addi	sp,sp,32
    8000346e:	8082                	ret

0000000080003470 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	1000                	addi	s0,sp,32
    uint64 vaddr = 0;
    80003478:	fe043423          	sd	zero,-24(s0)
    int pid = 0;
    8000347c:	fe042223          	sw	zero,-28(s0)
    argaddr(0, &vaddr);
    80003480:	fe840593          	addi	a1,s0,-24
    80003484:	4501                	li	a0,0
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	cb6080e7          	jalr	-842(ra) # 8000313c <argaddr>
    argint(1, &pid);
    8000348e:	fe440593          	addi	a1,s0,-28
    80003492:	4505                	li	a0,1
    80003494:	00000097          	auipc	ra,0x0
    80003498:	c88080e7          	jalr	-888(ra) # 8000311c <argint>
    return proc_va2pa(vaddr, pid);
    8000349c:	fe442583          	lw	a1,-28(s0)
    800034a0:	fe843503          	ld	a0,-24(s0)
    800034a4:	fffff097          	auipc	ra,0xfffff
    800034a8:	5d4080e7          	jalr	1492(ra) # 80002a78 <proc_va2pa>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret

00000000800034b4 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800034b4:	1141                	addi	sp,sp,-16
    800034b6:	e406                	sd	ra,8(sp)
    800034b8:	e022                	sd	s0,0(sp)
    800034ba:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800034bc:	00005597          	auipc	a1,0x5
    800034c0:	61c5b583          	ld	a1,1564(a1) # 80008ad8 <FREE_PAGES>
    800034c4:	00005517          	auipc	a0,0x5
    800034c8:	14450513          	addi	a0,a0,324 # 80008608 <states.0+0x188>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	0ba080e7          	jalr	186(ra) # 80000586 <printf>
    return 0;
    800034d4:	4501                	li	a0,0
    800034d6:	60a2                	ld	ra,8(sp)
    800034d8:	6402                	ld	s0,0(sp)
    800034da:	0141                	addi	sp,sp,16
    800034dc:	8082                	ret

00000000800034de <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034de:	7179                	addi	sp,sp,-48
    800034e0:	f406                	sd	ra,40(sp)
    800034e2:	f022                	sd	s0,32(sp)
    800034e4:	ec26                	sd	s1,24(sp)
    800034e6:	e84a                	sd	s2,16(sp)
    800034e8:	e44e                	sd	s3,8(sp)
    800034ea:	e052                	sd	s4,0(sp)
    800034ec:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034ee:	00005597          	auipc	a1,0x5
    800034f2:	21258593          	addi	a1,a1,530 # 80008700 <syscalls+0xd8>
    800034f6:	00123517          	auipc	a0,0x123
    800034fa:	6c250513          	addi	a0,a0,1730 # 80126bb8 <bcache>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	700080e7          	jalr	1792(ra) # 80000bfe <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003506:	0012b797          	auipc	a5,0x12b
    8000350a:	6b278793          	addi	a5,a5,1714 # 8012ebb8 <bcache+0x8000>
    8000350e:	0012c717          	auipc	a4,0x12c
    80003512:	91270713          	addi	a4,a4,-1774 # 8012ee20 <bcache+0x8268>
    80003516:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000351a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000351e:	00123497          	auipc	s1,0x123
    80003522:	6b248493          	addi	s1,s1,1714 # 80126bd0 <bcache+0x18>
    b->next = bcache.head.next;
    80003526:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003528:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000352a:	00005a17          	auipc	s4,0x5
    8000352e:	1dea0a13          	addi	s4,s4,478 # 80008708 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003532:	2b893783          	ld	a5,696(s2)
    80003536:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003538:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000353c:	85d2                	mv	a1,s4
    8000353e:	01048513          	addi	a0,s1,16
    80003542:	00001097          	auipc	ra,0x1
    80003546:	496080e7          	jalr	1174(ra) # 800049d8 <initsleeplock>
    bcache.head.next->prev = b;
    8000354a:	2b893783          	ld	a5,696(s2)
    8000354e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003550:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003554:	45848493          	addi	s1,s1,1112
    80003558:	fd349de3          	bne	s1,s3,80003532 <binit+0x54>
  }
}
    8000355c:	70a2                	ld	ra,40(sp)
    8000355e:	7402                	ld	s0,32(sp)
    80003560:	64e2                	ld	s1,24(sp)
    80003562:	6942                	ld	s2,16(sp)
    80003564:	69a2                	ld	s3,8(sp)
    80003566:	6a02                	ld	s4,0(sp)
    80003568:	6145                	addi	sp,sp,48
    8000356a:	8082                	ret

000000008000356c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000356c:	7179                	addi	sp,sp,-48
    8000356e:	f406                	sd	ra,40(sp)
    80003570:	f022                	sd	s0,32(sp)
    80003572:	ec26                	sd	s1,24(sp)
    80003574:	e84a                	sd	s2,16(sp)
    80003576:	e44e                	sd	s3,8(sp)
    80003578:	1800                	addi	s0,sp,48
    8000357a:	892a                	mv	s2,a0
    8000357c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000357e:	00123517          	auipc	a0,0x123
    80003582:	63a50513          	addi	a0,a0,1594 # 80126bb8 <bcache>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	708080e7          	jalr	1800(ra) # 80000c8e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000358e:	0012c497          	auipc	s1,0x12c
    80003592:	8e24b483          	ld	s1,-1822(s1) # 8012ee70 <bcache+0x82b8>
    80003596:	0012c797          	auipc	a5,0x12c
    8000359a:	88a78793          	addi	a5,a5,-1910 # 8012ee20 <bcache+0x8268>
    8000359e:	02f48f63          	beq	s1,a5,800035dc <bread+0x70>
    800035a2:	873e                	mv	a4,a5
    800035a4:	a021                	j	800035ac <bread+0x40>
    800035a6:	68a4                	ld	s1,80(s1)
    800035a8:	02e48a63          	beq	s1,a4,800035dc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035ac:	449c                	lw	a5,8(s1)
    800035ae:	ff279ce3          	bne	a5,s2,800035a6 <bread+0x3a>
    800035b2:	44dc                	lw	a5,12(s1)
    800035b4:	ff3799e3          	bne	a5,s3,800035a6 <bread+0x3a>
      b->refcnt++;
    800035b8:	40bc                	lw	a5,64(s1)
    800035ba:	2785                	addiw	a5,a5,1
    800035bc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035be:	00123517          	auipc	a0,0x123
    800035c2:	5fa50513          	addi	a0,a0,1530 # 80126bb8 <bcache>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	77c080e7          	jalr	1916(ra) # 80000d42 <release>
      acquiresleep(&b->lock);
    800035ce:	01048513          	addi	a0,s1,16
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	440080e7          	jalr	1088(ra) # 80004a12 <acquiresleep>
      return b;
    800035da:	a8b9                	j	80003638 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035dc:	0012c497          	auipc	s1,0x12c
    800035e0:	88c4b483          	ld	s1,-1908(s1) # 8012ee68 <bcache+0x82b0>
    800035e4:	0012c797          	auipc	a5,0x12c
    800035e8:	83c78793          	addi	a5,a5,-1988 # 8012ee20 <bcache+0x8268>
    800035ec:	00f48863          	beq	s1,a5,800035fc <bread+0x90>
    800035f0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035f2:	40bc                	lw	a5,64(s1)
    800035f4:	cf81                	beqz	a5,8000360c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035f6:	64a4                	ld	s1,72(s1)
    800035f8:	fee49de3          	bne	s1,a4,800035f2 <bread+0x86>
  panic("bget: no buffers");
    800035fc:	00005517          	auipc	a0,0x5
    80003600:	11450513          	addi	a0,a0,276 # 80008710 <syscalls+0xe8>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	f38080e7          	jalr	-200(ra) # 8000053c <panic>
      b->dev = dev;
    8000360c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003610:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003614:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003618:	4785                	li	a5,1
    8000361a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000361c:	00123517          	auipc	a0,0x123
    80003620:	59c50513          	addi	a0,a0,1436 # 80126bb8 <bcache>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	71e080e7          	jalr	1822(ra) # 80000d42 <release>
      acquiresleep(&b->lock);
    8000362c:	01048513          	addi	a0,s1,16
    80003630:	00001097          	auipc	ra,0x1
    80003634:	3e2080e7          	jalr	994(ra) # 80004a12 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003638:	409c                	lw	a5,0(s1)
    8000363a:	cb89                	beqz	a5,8000364c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000363c:	8526                	mv	a0,s1
    8000363e:	70a2                	ld	ra,40(sp)
    80003640:	7402                	ld	s0,32(sp)
    80003642:	64e2                	ld	s1,24(sp)
    80003644:	6942                	ld	s2,16(sp)
    80003646:	69a2                	ld	s3,8(sp)
    80003648:	6145                	addi	sp,sp,48
    8000364a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000364c:	4581                	li	a1,0
    8000364e:	8526                	mv	a0,s1
    80003650:	00003097          	auipc	ra,0x3
    80003654:	f82080e7          	jalr	-126(ra) # 800065d2 <virtio_disk_rw>
    b->valid = 1;
    80003658:	4785                	li	a5,1
    8000365a:	c09c                	sw	a5,0(s1)
  return b;
    8000365c:	b7c5                	j	8000363c <bread+0xd0>

000000008000365e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000365e:	1101                	addi	sp,sp,-32
    80003660:	ec06                	sd	ra,24(sp)
    80003662:	e822                	sd	s0,16(sp)
    80003664:	e426                	sd	s1,8(sp)
    80003666:	1000                	addi	s0,sp,32
    80003668:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000366a:	0541                	addi	a0,a0,16
    8000366c:	00001097          	auipc	ra,0x1
    80003670:	440080e7          	jalr	1088(ra) # 80004aac <holdingsleep>
    80003674:	cd01                	beqz	a0,8000368c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003676:	4585                	li	a1,1
    80003678:	8526                	mv	a0,s1
    8000367a:	00003097          	auipc	ra,0x3
    8000367e:	f58080e7          	jalr	-168(ra) # 800065d2 <virtio_disk_rw>
}
    80003682:	60e2                	ld	ra,24(sp)
    80003684:	6442                	ld	s0,16(sp)
    80003686:	64a2                	ld	s1,8(sp)
    80003688:	6105                	addi	sp,sp,32
    8000368a:	8082                	ret
    panic("bwrite");
    8000368c:	00005517          	auipc	a0,0x5
    80003690:	09c50513          	addi	a0,a0,156 # 80008728 <syscalls+0x100>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	ea8080e7          	jalr	-344(ra) # 8000053c <panic>

000000008000369c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	e04a                	sd	s2,0(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036aa:	01050913          	addi	s2,a0,16
    800036ae:	854a                	mv	a0,s2
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	3fc080e7          	jalr	1020(ra) # 80004aac <holdingsleep>
    800036b8:	c925                	beqz	a0,80003728 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800036ba:	854a                	mv	a0,s2
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	3ac080e7          	jalr	940(ra) # 80004a68 <releasesleep>

  acquire(&bcache.lock);
    800036c4:	00123517          	auipc	a0,0x123
    800036c8:	4f450513          	addi	a0,a0,1268 # 80126bb8 <bcache>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	5c2080e7          	jalr	1474(ra) # 80000c8e <acquire>
  b->refcnt--;
    800036d4:	40bc                	lw	a5,64(s1)
    800036d6:	37fd                	addiw	a5,a5,-1
    800036d8:	0007871b          	sext.w	a4,a5
    800036dc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036de:	e71d                	bnez	a4,8000370c <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036e0:	68b8                	ld	a4,80(s1)
    800036e2:	64bc                	ld	a5,72(s1)
    800036e4:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800036e6:	68b8                	ld	a4,80(s1)
    800036e8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036ea:	0012b797          	auipc	a5,0x12b
    800036ee:	4ce78793          	addi	a5,a5,1230 # 8012ebb8 <bcache+0x8000>
    800036f2:	2b87b703          	ld	a4,696(a5)
    800036f6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036f8:	0012b717          	auipc	a4,0x12b
    800036fc:	72870713          	addi	a4,a4,1832 # 8012ee20 <bcache+0x8268>
    80003700:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003702:	2b87b703          	ld	a4,696(a5)
    80003706:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003708:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000370c:	00123517          	auipc	a0,0x123
    80003710:	4ac50513          	addi	a0,a0,1196 # 80126bb8 <bcache>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	62e080e7          	jalr	1582(ra) # 80000d42 <release>
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6902                	ld	s2,0(sp)
    80003724:	6105                	addi	sp,sp,32
    80003726:	8082                	ret
    panic("brelse");
    80003728:	00005517          	auipc	a0,0x5
    8000372c:	00850513          	addi	a0,a0,8 # 80008730 <syscalls+0x108>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	e0c080e7          	jalr	-500(ra) # 8000053c <panic>

0000000080003738 <bpin>:

void
bpin(struct buf *b) {
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003744:	00123517          	auipc	a0,0x123
    80003748:	47450513          	addi	a0,a0,1140 # 80126bb8 <bcache>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	542080e7          	jalr	1346(ra) # 80000c8e <acquire>
  b->refcnt++;
    80003754:	40bc                	lw	a5,64(s1)
    80003756:	2785                	addiw	a5,a5,1
    80003758:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000375a:	00123517          	auipc	a0,0x123
    8000375e:	45e50513          	addi	a0,a0,1118 # 80126bb8 <bcache>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	5e0080e7          	jalr	1504(ra) # 80000d42 <release>
}
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	64a2                	ld	s1,8(sp)
    80003770:	6105                	addi	sp,sp,32
    80003772:	8082                	ret

0000000080003774 <bunpin>:

void
bunpin(struct buf *b) {
    80003774:	1101                	addi	sp,sp,-32
    80003776:	ec06                	sd	ra,24(sp)
    80003778:	e822                	sd	s0,16(sp)
    8000377a:	e426                	sd	s1,8(sp)
    8000377c:	1000                	addi	s0,sp,32
    8000377e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003780:	00123517          	auipc	a0,0x123
    80003784:	43850513          	addi	a0,a0,1080 # 80126bb8 <bcache>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	506080e7          	jalr	1286(ra) # 80000c8e <acquire>
  b->refcnt--;
    80003790:	40bc                	lw	a5,64(s1)
    80003792:	37fd                	addiw	a5,a5,-1
    80003794:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003796:	00123517          	auipc	a0,0x123
    8000379a:	42250513          	addi	a0,a0,1058 # 80126bb8 <bcache>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	5a4080e7          	jalr	1444(ra) # 80000d42 <release>
}
    800037a6:	60e2                	ld	ra,24(sp)
    800037a8:	6442                	ld	s0,16(sp)
    800037aa:	64a2                	ld	s1,8(sp)
    800037ac:	6105                	addi	sp,sp,32
    800037ae:	8082                	ret

00000000800037b0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	e04a                	sd	s2,0(sp)
    800037ba:	1000                	addi	s0,sp,32
    800037bc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037be:	00d5d59b          	srliw	a1,a1,0xd
    800037c2:	0012c797          	auipc	a5,0x12c
    800037c6:	ad27a783          	lw	a5,-1326(a5) # 8012f294 <sb+0x1c>
    800037ca:	9dbd                	addw	a1,a1,a5
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	da0080e7          	jalr	-608(ra) # 8000356c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037d4:	0074f713          	andi	a4,s1,7
    800037d8:	4785                	li	a5,1
    800037da:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037de:	14ce                	slli	s1,s1,0x33
    800037e0:	90d9                	srli	s1,s1,0x36
    800037e2:	00950733          	add	a4,a0,s1
    800037e6:	05874703          	lbu	a4,88(a4)
    800037ea:	00e7f6b3          	and	a3,a5,a4
    800037ee:	c69d                	beqz	a3,8000381c <bfree+0x6c>
    800037f0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037f2:	94aa                	add	s1,s1,a0
    800037f4:	fff7c793          	not	a5,a5
    800037f8:	8f7d                	and	a4,a4,a5
    800037fa:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037fe:	00001097          	auipc	ra,0x1
    80003802:	0f6080e7          	jalr	246(ra) # 800048f4 <log_write>
  brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e94080e7          	jalr	-364(ra) # 8000369c <brelse>
}
    80003810:	60e2                	ld	ra,24(sp)
    80003812:	6442                	ld	s0,16(sp)
    80003814:	64a2                	ld	s1,8(sp)
    80003816:	6902                	ld	s2,0(sp)
    80003818:	6105                	addi	sp,sp,32
    8000381a:	8082                	ret
    panic("freeing free block");
    8000381c:	00005517          	auipc	a0,0x5
    80003820:	f1c50513          	addi	a0,a0,-228 # 80008738 <syscalls+0x110>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d18080e7          	jalr	-744(ra) # 8000053c <panic>

000000008000382c <balloc>:
{
    8000382c:	711d                	addi	sp,sp,-96
    8000382e:	ec86                	sd	ra,88(sp)
    80003830:	e8a2                	sd	s0,80(sp)
    80003832:	e4a6                	sd	s1,72(sp)
    80003834:	e0ca                	sd	s2,64(sp)
    80003836:	fc4e                	sd	s3,56(sp)
    80003838:	f852                	sd	s4,48(sp)
    8000383a:	f456                	sd	s5,40(sp)
    8000383c:	f05a                	sd	s6,32(sp)
    8000383e:	ec5e                	sd	s7,24(sp)
    80003840:	e862                	sd	s8,16(sp)
    80003842:	e466                	sd	s9,8(sp)
    80003844:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003846:	0012c797          	auipc	a5,0x12c
    8000384a:	a367a783          	lw	a5,-1482(a5) # 8012f27c <sb+0x4>
    8000384e:	cff5                	beqz	a5,8000394a <balloc+0x11e>
    80003850:	8baa                	mv	s7,a0
    80003852:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003854:	0012cb17          	auipc	s6,0x12c
    80003858:	a24b0b13          	addi	s6,s6,-1500 # 8012f278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000385e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003860:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003862:	6c89                	lui	s9,0x2
    80003864:	a061                	j	800038ec <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003866:	97ca                	add	a5,a5,s2
    80003868:	8e55                	or	a2,a2,a3
    8000386a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00001097          	auipc	ra,0x1
    80003874:	084080e7          	jalr	132(ra) # 800048f4 <log_write>
        brelse(bp);
    80003878:	854a                	mv	a0,s2
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	e22080e7          	jalr	-478(ra) # 8000369c <brelse>
  bp = bread(dev, bno);
    80003882:	85a6                	mv	a1,s1
    80003884:	855e                	mv	a0,s7
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	ce6080e7          	jalr	-794(ra) # 8000356c <bread>
    8000388e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003890:	40000613          	li	a2,1024
    80003894:	4581                	li	a1,0
    80003896:	05850513          	addi	a0,a0,88
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	4f0080e7          	jalr	1264(ra) # 80000d8a <memset>
  log_write(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	050080e7          	jalr	80(ra) # 800048f4 <log_write>
  brelse(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	dee080e7          	jalr	-530(ra) # 8000369c <brelse>
}
    800038b6:	8526                	mv	a0,s1
    800038b8:	60e6                	ld	ra,88(sp)
    800038ba:	6446                	ld	s0,80(sp)
    800038bc:	64a6                	ld	s1,72(sp)
    800038be:	6906                	ld	s2,64(sp)
    800038c0:	79e2                	ld	s3,56(sp)
    800038c2:	7a42                	ld	s4,48(sp)
    800038c4:	7aa2                	ld	s5,40(sp)
    800038c6:	7b02                	ld	s6,32(sp)
    800038c8:	6be2                	ld	s7,24(sp)
    800038ca:	6c42                	ld	s8,16(sp)
    800038cc:	6ca2                	ld	s9,8(sp)
    800038ce:	6125                	addi	sp,sp,96
    800038d0:	8082                	ret
    brelse(bp);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	dc8080e7          	jalr	-568(ra) # 8000369c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038dc:	015c87bb          	addw	a5,s9,s5
    800038e0:	00078a9b          	sext.w	s5,a5
    800038e4:	004b2703          	lw	a4,4(s6)
    800038e8:	06eaf163          	bgeu	s5,a4,8000394a <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800038ec:	41fad79b          	sraiw	a5,s5,0x1f
    800038f0:	0137d79b          	srliw	a5,a5,0x13
    800038f4:	015787bb          	addw	a5,a5,s5
    800038f8:	40d7d79b          	sraiw	a5,a5,0xd
    800038fc:	01cb2583          	lw	a1,28(s6)
    80003900:	9dbd                	addw	a1,a1,a5
    80003902:	855e                	mv	a0,s7
    80003904:	00000097          	auipc	ra,0x0
    80003908:	c68080e7          	jalr	-920(ra) # 8000356c <bread>
    8000390c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000390e:	004b2503          	lw	a0,4(s6)
    80003912:	000a849b          	sext.w	s1,s5
    80003916:	8762                	mv	a4,s8
    80003918:	faa4fde3          	bgeu	s1,a0,800038d2 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000391c:	00777693          	andi	a3,a4,7
    80003920:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003924:	41f7579b          	sraiw	a5,a4,0x1f
    80003928:	01d7d79b          	srliw	a5,a5,0x1d
    8000392c:	9fb9                	addw	a5,a5,a4
    8000392e:	4037d79b          	sraiw	a5,a5,0x3
    80003932:	00f90633          	add	a2,s2,a5
    80003936:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000393a:	00c6f5b3          	and	a1,a3,a2
    8000393e:	d585                	beqz	a1,80003866 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003940:	2705                	addiw	a4,a4,1
    80003942:	2485                	addiw	s1,s1,1
    80003944:	fd471ae3          	bne	a4,s4,80003918 <balloc+0xec>
    80003948:	b769                	j	800038d2 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000394a:	00005517          	auipc	a0,0x5
    8000394e:	e0650513          	addi	a0,a0,-506 # 80008750 <syscalls+0x128>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	c34080e7          	jalr	-972(ra) # 80000586 <printf>
  return 0;
    8000395a:	4481                	li	s1,0
    8000395c:	bfa9                	j	800038b6 <balloc+0x8a>

000000008000395e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000395e:	7179                	addi	sp,sp,-48
    80003960:	f406                	sd	ra,40(sp)
    80003962:	f022                	sd	s0,32(sp)
    80003964:	ec26                	sd	s1,24(sp)
    80003966:	e84a                	sd	s2,16(sp)
    80003968:	e44e                	sd	s3,8(sp)
    8000396a:	e052                	sd	s4,0(sp)
    8000396c:	1800                	addi	s0,sp,48
    8000396e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003970:	47ad                	li	a5,11
    80003972:	02b7e863          	bltu	a5,a1,800039a2 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003976:	02059793          	slli	a5,a1,0x20
    8000397a:	01e7d593          	srli	a1,a5,0x1e
    8000397e:	00b504b3          	add	s1,a0,a1
    80003982:	0504a903          	lw	s2,80(s1)
    80003986:	06091e63          	bnez	s2,80003a02 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000398a:	4108                	lw	a0,0(a0)
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	ea0080e7          	jalr	-352(ra) # 8000382c <balloc>
    80003994:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003998:	06090563          	beqz	s2,80003a02 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000399c:	0524a823          	sw	s2,80(s1)
    800039a0:	a08d                	j	80003a02 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039a2:	ff45849b          	addiw	s1,a1,-12
    800039a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039aa:	0ff00793          	li	a5,255
    800039ae:	08e7e563          	bltu	a5,a4,80003a38 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039b2:	08052903          	lw	s2,128(a0)
    800039b6:	00091d63          	bnez	s2,800039d0 <bmap+0x72>
      addr = balloc(ip->dev);
    800039ba:	4108                	lw	a0,0(a0)
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	e70080e7          	jalr	-400(ra) # 8000382c <balloc>
    800039c4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039c8:	02090d63          	beqz	s2,80003a02 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039cc:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039d0:	85ca                	mv	a1,s2
    800039d2:	0009a503          	lw	a0,0(s3)
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	b96080e7          	jalr	-1130(ra) # 8000356c <bread>
    800039de:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039e0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039e4:	02049713          	slli	a4,s1,0x20
    800039e8:	01e75593          	srli	a1,a4,0x1e
    800039ec:	00b784b3          	add	s1,a5,a1
    800039f0:	0004a903          	lw	s2,0(s1)
    800039f4:	02090063          	beqz	s2,80003a14 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039f8:	8552                	mv	a0,s4
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	ca2080e7          	jalr	-862(ra) # 8000369c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a02:	854a                	mv	a0,s2
    80003a04:	70a2                	ld	ra,40(sp)
    80003a06:	7402                	ld	s0,32(sp)
    80003a08:	64e2                	ld	s1,24(sp)
    80003a0a:	6942                	ld	s2,16(sp)
    80003a0c:	69a2                	ld	s3,8(sp)
    80003a0e:	6a02                	ld	s4,0(sp)
    80003a10:	6145                	addi	sp,sp,48
    80003a12:	8082                	ret
      addr = balloc(ip->dev);
    80003a14:	0009a503          	lw	a0,0(s3)
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	e14080e7          	jalr	-492(ra) # 8000382c <balloc>
    80003a20:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a24:	fc090ae3          	beqz	s2,800039f8 <bmap+0x9a>
        a[bn] = addr;
    80003a28:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a2c:	8552                	mv	a0,s4
    80003a2e:	00001097          	auipc	ra,0x1
    80003a32:	ec6080e7          	jalr	-314(ra) # 800048f4 <log_write>
    80003a36:	b7c9                	j	800039f8 <bmap+0x9a>
  panic("bmap: out of range");
    80003a38:	00005517          	auipc	a0,0x5
    80003a3c:	d3050513          	addi	a0,a0,-720 # 80008768 <syscalls+0x140>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	afc080e7          	jalr	-1284(ra) # 8000053c <panic>

0000000080003a48 <iget>:
{
    80003a48:	7179                	addi	sp,sp,-48
    80003a4a:	f406                	sd	ra,40(sp)
    80003a4c:	f022                	sd	s0,32(sp)
    80003a4e:	ec26                	sd	s1,24(sp)
    80003a50:	e84a                	sd	s2,16(sp)
    80003a52:	e44e                	sd	s3,8(sp)
    80003a54:	e052                	sd	s4,0(sp)
    80003a56:	1800                	addi	s0,sp,48
    80003a58:	89aa                	mv	s3,a0
    80003a5a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a5c:	0012c517          	auipc	a0,0x12c
    80003a60:	83c50513          	addi	a0,a0,-1988 # 8012f298 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	22a080e7          	jalr	554(ra) # 80000c8e <acquire>
  empty = 0;
    80003a6c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a6e:	0012c497          	auipc	s1,0x12c
    80003a72:	84248493          	addi	s1,s1,-1982 # 8012f2b0 <itable+0x18>
    80003a76:	0012d697          	auipc	a3,0x12d
    80003a7a:	2ca68693          	addi	a3,a3,714 # 80130d40 <log>
    80003a7e:	a039                	j	80003a8c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a80:	02090b63          	beqz	s2,80003ab6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a84:	08848493          	addi	s1,s1,136
    80003a88:	02d48a63          	beq	s1,a3,80003abc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a8c:	449c                	lw	a5,8(s1)
    80003a8e:	fef059e3          	blez	a5,80003a80 <iget+0x38>
    80003a92:	4098                	lw	a4,0(s1)
    80003a94:	ff3716e3          	bne	a4,s3,80003a80 <iget+0x38>
    80003a98:	40d8                	lw	a4,4(s1)
    80003a9a:	ff4713e3          	bne	a4,s4,80003a80 <iget+0x38>
      ip->ref++;
    80003a9e:	2785                	addiw	a5,a5,1
    80003aa0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003aa2:	0012b517          	auipc	a0,0x12b
    80003aa6:	7f650513          	addi	a0,a0,2038 # 8012f298 <itable>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	298080e7          	jalr	664(ra) # 80000d42 <release>
      return ip;
    80003ab2:	8926                	mv	s2,s1
    80003ab4:	a03d                	j	80003ae2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab6:	f7f9                	bnez	a5,80003a84 <iget+0x3c>
    80003ab8:	8926                	mv	s2,s1
    80003aba:	b7e9                	j	80003a84 <iget+0x3c>
  if(empty == 0)
    80003abc:	02090c63          	beqz	s2,80003af4 <iget+0xac>
  ip->dev = dev;
    80003ac0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ac4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ac8:	4785                	li	a5,1
    80003aca:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ace:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ad2:	0012b517          	auipc	a0,0x12b
    80003ad6:	7c650513          	addi	a0,a0,1990 # 8012f298 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	268080e7          	jalr	616(ra) # 80000d42 <release>
}
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	70a2                	ld	ra,40(sp)
    80003ae6:	7402                	ld	s0,32(sp)
    80003ae8:	64e2                	ld	s1,24(sp)
    80003aea:	6942                	ld	s2,16(sp)
    80003aec:	69a2                	ld	s3,8(sp)
    80003aee:	6a02                	ld	s4,0(sp)
    80003af0:	6145                	addi	sp,sp,48
    80003af2:	8082                	ret
    panic("iget: no inodes");
    80003af4:	00005517          	auipc	a0,0x5
    80003af8:	c8c50513          	addi	a0,a0,-884 # 80008780 <syscalls+0x158>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	a40080e7          	jalr	-1472(ra) # 8000053c <panic>

0000000080003b04 <fsinit>:
fsinit(int dev) {
    80003b04:	7179                	addi	sp,sp,-48
    80003b06:	f406                	sd	ra,40(sp)
    80003b08:	f022                	sd	s0,32(sp)
    80003b0a:	ec26                	sd	s1,24(sp)
    80003b0c:	e84a                	sd	s2,16(sp)
    80003b0e:	e44e                	sd	s3,8(sp)
    80003b10:	1800                	addi	s0,sp,48
    80003b12:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b14:	4585                	li	a1,1
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	a56080e7          	jalr	-1450(ra) # 8000356c <bread>
    80003b1e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b20:	0012b997          	auipc	s3,0x12b
    80003b24:	75898993          	addi	s3,s3,1880 # 8012f278 <sb>
    80003b28:	02000613          	li	a2,32
    80003b2c:	05850593          	addi	a1,a0,88
    80003b30:	854e                	mv	a0,s3
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	2b4080e7          	jalr	692(ra) # 80000de6 <memmove>
  brelse(bp);
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	b60080e7          	jalr	-1184(ra) # 8000369c <brelse>
  if(sb.magic != FSMAGIC)
    80003b44:	0009a703          	lw	a4,0(s3)
    80003b48:	102037b7          	lui	a5,0x10203
    80003b4c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b50:	02f71263          	bne	a4,a5,80003b74 <fsinit+0x70>
  initlog(dev, &sb);
    80003b54:	0012b597          	auipc	a1,0x12b
    80003b58:	72458593          	addi	a1,a1,1828 # 8012f278 <sb>
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	b2c080e7          	jalr	-1236(ra) # 8000468a <initlog>
}
    80003b66:	70a2                	ld	ra,40(sp)
    80003b68:	7402                	ld	s0,32(sp)
    80003b6a:	64e2                	ld	s1,24(sp)
    80003b6c:	6942                	ld	s2,16(sp)
    80003b6e:	69a2                	ld	s3,8(sp)
    80003b70:	6145                	addi	sp,sp,48
    80003b72:	8082                	ret
    panic("invalid file system");
    80003b74:	00005517          	auipc	a0,0x5
    80003b78:	c1c50513          	addi	a0,a0,-996 # 80008790 <syscalls+0x168>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	9c0080e7          	jalr	-1600(ra) # 8000053c <panic>

0000000080003b84 <iinit>:
{
    80003b84:	7179                	addi	sp,sp,-48
    80003b86:	f406                	sd	ra,40(sp)
    80003b88:	f022                	sd	s0,32(sp)
    80003b8a:	ec26                	sd	s1,24(sp)
    80003b8c:	e84a                	sd	s2,16(sp)
    80003b8e:	e44e                	sd	s3,8(sp)
    80003b90:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b92:	00005597          	auipc	a1,0x5
    80003b96:	c1658593          	addi	a1,a1,-1002 # 800087a8 <syscalls+0x180>
    80003b9a:	0012b517          	auipc	a0,0x12b
    80003b9e:	6fe50513          	addi	a0,a0,1790 # 8012f298 <itable>
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	05c080e7          	jalr	92(ra) # 80000bfe <initlock>
  for(i = 0; i < NINODE; i++) {
    80003baa:	0012b497          	auipc	s1,0x12b
    80003bae:	71648493          	addi	s1,s1,1814 # 8012f2c0 <itable+0x28>
    80003bb2:	0012d997          	auipc	s3,0x12d
    80003bb6:	19e98993          	addi	s3,s3,414 # 80130d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bba:	00005917          	auipc	s2,0x5
    80003bbe:	bf690913          	addi	s2,s2,-1034 # 800087b0 <syscalls+0x188>
    80003bc2:	85ca                	mv	a1,s2
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	e12080e7          	jalr	-494(ra) # 800049d8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bce:	08848493          	addi	s1,s1,136
    80003bd2:	ff3498e3          	bne	s1,s3,80003bc2 <iinit+0x3e>
}
    80003bd6:	70a2                	ld	ra,40(sp)
    80003bd8:	7402                	ld	s0,32(sp)
    80003bda:	64e2                	ld	s1,24(sp)
    80003bdc:	6942                	ld	s2,16(sp)
    80003bde:	69a2                	ld	s3,8(sp)
    80003be0:	6145                	addi	sp,sp,48
    80003be2:	8082                	ret

0000000080003be4 <ialloc>:
{
    80003be4:	7139                	addi	sp,sp,-64
    80003be6:	fc06                	sd	ra,56(sp)
    80003be8:	f822                	sd	s0,48(sp)
    80003bea:	f426                	sd	s1,40(sp)
    80003bec:	f04a                	sd	s2,32(sp)
    80003bee:	ec4e                	sd	s3,24(sp)
    80003bf0:	e852                	sd	s4,16(sp)
    80003bf2:	e456                	sd	s5,8(sp)
    80003bf4:	e05a                	sd	s6,0(sp)
    80003bf6:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bf8:	0012b717          	auipc	a4,0x12b
    80003bfc:	68c72703          	lw	a4,1676(a4) # 8012f284 <sb+0xc>
    80003c00:	4785                	li	a5,1
    80003c02:	04e7f863          	bgeu	a5,a4,80003c52 <ialloc+0x6e>
    80003c06:	8aaa                	mv	s5,a0
    80003c08:	8b2e                	mv	s6,a1
    80003c0a:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c0c:	0012ba17          	auipc	s4,0x12b
    80003c10:	66ca0a13          	addi	s4,s4,1644 # 8012f278 <sb>
    80003c14:	00495593          	srli	a1,s2,0x4
    80003c18:	018a2783          	lw	a5,24(s4)
    80003c1c:	9dbd                	addw	a1,a1,a5
    80003c1e:	8556                	mv	a0,s5
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	94c080e7          	jalr	-1716(ra) # 8000356c <bread>
    80003c28:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c2a:	05850993          	addi	s3,a0,88
    80003c2e:	00f97793          	andi	a5,s2,15
    80003c32:	079a                	slli	a5,a5,0x6
    80003c34:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c36:	00099783          	lh	a5,0(s3)
    80003c3a:	cf9d                	beqz	a5,80003c78 <ialloc+0x94>
    brelse(bp);
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	a60080e7          	jalr	-1440(ra) # 8000369c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c44:	0905                	addi	s2,s2,1
    80003c46:	00ca2703          	lw	a4,12(s4)
    80003c4a:	0009079b          	sext.w	a5,s2
    80003c4e:	fce7e3e3          	bltu	a5,a4,80003c14 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003c52:	00005517          	auipc	a0,0x5
    80003c56:	b6650513          	addi	a0,a0,-1178 # 800087b8 <syscalls+0x190>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	92c080e7          	jalr	-1748(ra) # 80000586 <printf>
  return 0;
    80003c62:	4501                	li	a0,0
}
    80003c64:	70e2                	ld	ra,56(sp)
    80003c66:	7442                	ld	s0,48(sp)
    80003c68:	74a2                	ld	s1,40(sp)
    80003c6a:	7902                	ld	s2,32(sp)
    80003c6c:	69e2                	ld	s3,24(sp)
    80003c6e:	6a42                	ld	s4,16(sp)
    80003c70:	6aa2                	ld	s5,8(sp)
    80003c72:	6b02                	ld	s6,0(sp)
    80003c74:	6121                	addi	sp,sp,64
    80003c76:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c78:	04000613          	li	a2,64
    80003c7c:	4581                	li	a1,0
    80003c7e:	854e                	mv	a0,s3
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	10a080e7          	jalr	266(ra) # 80000d8a <memset>
      dip->type = type;
    80003c88:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c8c:	8526                	mv	a0,s1
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	c66080e7          	jalr	-922(ra) # 800048f4 <log_write>
      brelse(bp);
    80003c96:	8526                	mv	a0,s1
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	a04080e7          	jalr	-1532(ra) # 8000369c <brelse>
      return iget(dev, inum);
    80003ca0:	0009059b          	sext.w	a1,s2
    80003ca4:	8556                	mv	a0,s5
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	da2080e7          	jalr	-606(ra) # 80003a48 <iget>
    80003cae:	bf5d                	j	80003c64 <ialloc+0x80>

0000000080003cb0 <iupdate>:
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	e04a                	sd	s2,0(sp)
    80003cba:	1000                	addi	s0,sp,32
    80003cbc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cbe:	415c                	lw	a5,4(a0)
    80003cc0:	0047d79b          	srliw	a5,a5,0x4
    80003cc4:	0012b597          	auipc	a1,0x12b
    80003cc8:	5cc5a583          	lw	a1,1484(a1) # 8012f290 <sb+0x18>
    80003ccc:	9dbd                	addw	a1,a1,a5
    80003cce:	4108                	lw	a0,0(a0)
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	89c080e7          	jalr	-1892(ra) # 8000356c <bread>
    80003cd8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cda:	05850793          	addi	a5,a0,88
    80003cde:	40d8                	lw	a4,4(s1)
    80003ce0:	8b3d                	andi	a4,a4,15
    80003ce2:	071a                	slli	a4,a4,0x6
    80003ce4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003ce6:	04449703          	lh	a4,68(s1)
    80003cea:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003cee:	04649703          	lh	a4,70(s1)
    80003cf2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003cf6:	04849703          	lh	a4,72(s1)
    80003cfa:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003cfe:	04a49703          	lh	a4,74(s1)
    80003d02:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d06:	44f8                	lw	a4,76(s1)
    80003d08:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d0a:	03400613          	li	a2,52
    80003d0e:	05048593          	addi	a1,s1,80
    80003d12:	00c78513          	addi	a0,a5,12
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	0d0080e7          	jalr	208(ra) # 80000de6 <memmove>
  log_write(bp);
    80003d1e:	854a                	mv	a0,s2
    80003d20:	00001097          	auipc	ra,0x1
    80003d24:	bd4080e7          	jalr	-1068(ra) # 800048f4 <log_write>
  brelse(bp);
    80003d28:	854a                	mv	a0,s2
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	972080e7          	jalr	-1678(ra) # 8000369c <brelse>
}
    80003d32:	60e2                	ld	ra,24(sp)
    80003d34:	6442                	ld	s0,16(sp)
    80003d36:	64a2                	ld	s1,8(sp)
    80003d38:	6902                	ld	s2,0(sp)
    80003d3a:	6105                	addi	sp,sp,32
    80003d3c:	8082                	ret

0000000080003d3e <idup>:
{
    80003d3e:	1101                	addi	sp,sp,-32
    80003d40:	ec06                	sd	ra,24(sp)
    80003d42:	e822                	sd	s0,16(sp)
    80003d44:	e426                	sd	s1,8(sp)
    80003d46:	1000                	addi	s0,sp,32
    80003d48:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d4a:	0012b517          	auipc	a0,0x12b
    80003d4e:	54e50513          	addi	a0,a0,1358 # 8012f298 <itable>
    80003d52:	ffffd097          	auipc	ra,0xffffd
    80003d56:	f3c080e7          	jalr	-196(ra) # 80000c8e <acquire>
  ip->ref++;
    80003d5a:	449c                	lw	a5,8(s1)
    80003d5c:	2785                	addiw	a5,a5,1
    80003d5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d60:	0012b517          	auipc	a0,0x12b
    80003d64:	53850513          	addi	a0,a0,1336 # 8012f298 <itable>
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	fda080e7          	jalr	-38(ra) # 80000d42 <release>
}
    80003d70:	8526                	mv	a0,s1
    80003d72:	60e2                	ld	ra,24(sp)
    80003d74:	6442                	ld	s0,16(sp)
    80003d76:	64a2                	ld	s1,8(sp)
    80003d78:	6105                	addi	sp,sp,32
    80003d7a:	8082                	ret

0000000080003d7c <ilock>:
{
    80003d7c:	1101                	addi	sp,sp,-32
    80003d7e:	ec06                	sd	ra,24(sp)
    80003d80:	e822                	sd	s0,16(sp)
    80003d82:	e426                	sd	s1,8(sp)
    80003d84:	e04a                	sd	s2,0(sp)
    80003d86:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d88:	c115                	beqz	a0,80003dac <ilock+0x30>
    80003d8a:	84aa                	mv	s1,a0
    80003d8c:	451c                	lw	a5,8(a0)
    80003d8e:	00f05f63          	blez	a5,80003dac <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d92:	0541                	addi	a0,a0,16
    80003d94:	00001097          	auipc	ra,0x1
    80003d98:	c7e080e7          	jalr	-898(ra) # 80004a12 <acquiresleep>
  if(ip->valid == 0){
    80003d9c:	40bc                	lw	a5,64(s1)
    80003d9e:	cf99                	beqz	a5,80003dbc <ilock+0x40>
}
    80003da0:	60e2                	ld	ra,24(sp)
    80003da2:	6442                	ld	s0,16(sp)
    80003da4:	64a2                	ld	s1,8(sp)
    80003da6:	6902                	ld	s2,0(sp)
    80003da8:	6105                	addi	sp,sp,32
    80003daa:	8082                	ret
    panic("ilock");
    80003dac:	00005517          	auipc	a0,0x5
    80003db0:	a2450513          	addi	a0,a0,-1500 # 800087d0 <syscalls+0x1a8>
    80003db4:	ffffc097          	auipc	ra,0xffffc
    80003db8:	788080e7          	jalr	1928(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dbc:	40dc                	lw	a5,4(s1)
    80003dbe:	0047d79b          	srliw	a5,a5,0x4
    80003dc2:	0012b597          	auipc	a1,0x12b
    80003dc6:	4ce5a583          	lw	a1,1230(a1) # 8012f290 <sb+0x18>
    80003dca:	9dbd                	addw	a1,a1,a5
    80003dcc:	4088                	lw	a0,0(s1)
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	79e080e7          	jalr	1950(ra) # 8000356c <bread>
    80003dd6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dd8:	05850593          	addi	a1,a0,88
    80003ddc:	40dc                	lw	a5,4(s1)
    80003dde:	8bbd                	andi	a5,a5,15
    80003de0:	079a                	slli	a5,a5,0x6
    80003de2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003de4:	00059783          	lh	a5,0(a1)
    80003de8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dec:	00259783          	lh	a5,2(a1)
    80003df0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003df4:	00459783          	lh	a5,4(a1)
    80003df8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dfc:	00659783          	lh	a5,6(a1)
    80003e00:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e04:	459c                	lw	a5,8(a1)
    80003e06:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e08:	03400613          	li	a2,52
    80003e0c:	05b1                	addi	a1,a1,12
    80003e0e:	05048513          	addi	a0,s1,80
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	fd4080e7          	jalr	-44(ra) # 80000de6 <memmove>
    brelse(bp);
    80003e1a:	854a                	mv	a0,s2
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	880080e7          	jalr	-1920(ra) # 8000369c <brelse>
    ip->valid = 1;
    80003e24:	4785                	li	a5,1
    80003e26:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e28:	04449783          	lh	a5,68(s1)
    80003e2c:	fbb5                	bnez	a5,80003da0 <ilock+0x24>
      panic("ilock: no type");
    80003e2e:	00005517          	auipc	a0,0x5
    80003e32:	9aa50513          	addi	a0,a0,-1622 # 800087d8 <syscalls+0x1b0>
    80003e36:	ffffc097          	auipc	ra,0xffffc
    80003e3a:	706080e7          	jalr	1798(ra) # 8000053c <panic>

0000000080003e3e <iunlock>:
{
    80003e3e:	1101                	addi	sp,sp,-32
    80003e40:	ec06                	sd	ra,24(sp)
    80003e42:	e822                	sd	s0,16(sp)
    80003e44:	e426                	sd	s1,8(sp)
    80003e46:	e04a                	sd	s2,0(sp)
    80003e48:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e4a:	c905                	beqz	a0,80003e7a <iunlock+0x3c>
    80003e4c:	84aa                	mv	s1,a0
    80003e4e:	01050913          	addi	s2,a0,16
    80003e52:	854a                	mv	a0,s2
    80003e54:	00001097          	auipc	ra,0x1
    80003e58:	c58080e7          	jalr	-936(ra) # 80004aac <holdingsleep>
    80003e5c:	cd19                	beqz	a0,80003e7a <iunlock+0x3c>
    80003e5e:	449c                	lw	a5,8(s1)
    80003e60:	00f05d63          	blez	a5,80003e7a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e64:	854a                	mv	a0,s2
    80003e66:	00001097          	auipc	ra,0x1
    80003e6a:	c02080e7          	jalr	-1022(ra) # 80004a68 <releasesleep>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret
    panic("iunlock");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	96e50513          	addi	a0,a0,-1682 # 800087e8 <syscalls+0x1c0>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6ba080e7          	jalr	1722(ra) # 8000053c <panic>

0000000080003e8a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e8a:	7179                	addi	sp,sp,-48
    80003e8c:	f406                	sd	ra,40(sp)
    80003e8e:	f022                	sd	s0,32(sp)
    80003e90:	ec26                	sd	s1,24(sp)
    80003e92:	e84a                	sd	s2,16(sp)
    80003e94:	e44e                	sd	s3,8(sp)
    80003e96:	e052                	sd	s4,0(sp)
    80003e98:	1800                	addi	s0,sp,48
    80003e9a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e9c:	05050493          	addi	s1,a0,80
    80003ea0:	08050913          	addi	s2,a0,128
    80003ea4:	a021                	j	80003eac <itrunc+0x22>
    80003ea6:	0491                	addi	s1,s1,4
    80003ea8:	01248d63          	beq	s1,s2,80003ec2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003eac:	408c                	lw	a1,0(s1)
    80003eae:	dde5                	beqz	a1,80003ea6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003eb0:	0009a503          	lw	a0,0(s3)
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	8fc080e7          	jalr	-1796(ra) # 800037b0 <bfree>
      ip->addrs[i] = 0;
    80003ebc:	0004a023          	sw	zero,0(s1)
    80003ec0:	b7dd                	j	80003ea6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ec2:	0809a583          	lw	a1,128(s3)
    80003ec6:	e185                	bnez	a1,80003ee6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ec8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ecc:	854e                	mv	a0,s3
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	de2080e7          	jalr	-542(ra) # 80003cb0 <iupdate>
}
    80003ed6:	70a2                	ld	ra,40(sp)
    80003ed8:	7402                	ld	s0,32(sp)
    80003eda:	64e2                	ld	s1,24(sp)
    80003edc:	6942                	ld	s2,16(sp)
    80003ede:	69a2                	ld	s3,8(sp)
    80003ee0:	6a02                	ld	s4,0(sp)
    80003ee2:	6145                	addi	sp,sp,48
    80003ee4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ee6:	0009a503          	lw	a0,0(s3)
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	682080e7          	jalr	1666(ra) # 8000356c <bread>
    80003ef2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ef4:	05850493          	addi	s1,a0,88
    80003ef8:	45850913          	addi	s2,a0,1112
    80003efc:	a021                	j	80003f04 <itrunc+0x7a>
    80003efe:	0491                	addi	s1,s1,4
    80003f00:	01248b63          	beq	s1,s2,80003f16 <itrunc+0x8c>
      if(a[j])
    80003f04:	408c                	lw	a1,0(s1)
    80003f06:	dde5                	beqz	a1,80003efe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f08:	0009a503          	lw	a0,0(s3)
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	8a4080e7          	jalr	-1884(ra) # 800037b0 <bfree>
    80003f14:	b7ed                	j	80003efe <itrunc+0x74>
    brelse(bp);
    80003f16:	8552                	mv	a0,s4
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	784080e7          	jalr	1924(ra) # 8000369c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f20:	0809a583          	lw	a1,128(s3)
    80003f24:	0009a503          	lw	a0,0(s3)
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	888080e7          	jalr	-1912(ra) # 800037b0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f30:	0809a023          	sw	zero,128(s3)
    80003f34:	bf51                	j	80003ec8 <itrunc+0x3e>

0000000080003f36 <iput>:
{
    80003f36:	1101                	addi	sp,sp,-32
    80003f38:	ec06                	sd	ra,24(sp)
    80003f3a:	e822                	sd	s0,16(sp)
    80003f3c:	e426                	sd	s1,8(sp)
    80003f3e:	e04a                	sd	s2,0(sp)
    80003f40:	1000                	addi	s0,sp,32
    80003f42:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f44:	0012b517          	auipc	a0,0x12b
    80003f48:	35450513          	addi	a0,a0,852 # 8012f298 <itable>
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	d42080e7          	jalr	-702(ra) # 80000c8e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f54:	4498                	lw	a4,8(s1)
    80003f56:	4785                	li	a5,1
    80003f58:	02f70363          	beq	a4,a5,80003f7e <iput+0x48>
  ip->ref--;
    80003f5c:	449c                	lw	a5,8(s1)
    80003f5e:	37fd                	addiw	a5,a5,-1
    80003f60:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f62:	0012b517          	auipc	a0,0x12b
    80003f66:	33650513          	addi	a0,a0,822 # 8012f298 <itable>
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	dd8080e7          	jalr	-552(ra) # 80000d42 <release>
}
    80003f72:	60e2                	ld	ra,24(sp)
    80003f74:	6442                	ld	s0,16(sp)
    80003f76:	64a2                	ld	s1,8(sp)
    80003f78:	6902                	ld	s2,0(sp)
    80003f7a:	6105                	addi	sp,sp,32
    80003f7c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f7e:	40bc                	lw	a5,64(s1)
    80003f80:	dff1                	beqz	a5,80003f5c <iput+0x26>
    80003f82:	04a49783          	lh	a5,74(s1)
    80003f86:	fbf9                	bnez	a5,80003f5c <iput+0x26>
    acquiresleep(&ip->lock);
    80003f88:	01048913          	addi	s2,s1,16
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	00001097          	auipc	ra,0x1
    80003f92:	a84080e7          	jalr	-1404(ra) # 80004a12 <acquiresleep>
    release(&itable.lock);
    80003f96:	0012b517          	auipc	a0,0x12b
    80003f9a:	30250513          	addi	a0,a0,770 # 8012f298 <itable>
    80003f9e:	ffffd097          	auipc	ra,0xffffd
    80003fa2:	da4080e7          	jalr	-604(ra) # 80000d42 <release>
    itrunc(ip);
    80003fa6:	8526                	mv	a0,s1
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	ee2080e7          	jalr	-286(ra) # 80003e8a <itrunc>
    ip->type = 0;
    80003fb0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fb4:	8526                	mv	a0,s1
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	cfa080e7          	jalr	-774(ra) # 80003cb0 <iupdate>
    ip->valid = 0;
    80003fbe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	00001097          	auipc	ra,0x1
    80003fc8:	aa4080e7          	jalr	-1372(ra) # 80004a68 <releasesleep>
    acquire(&itable.lock);
    80003fcc:	0012b517          	auipc	a0,0x12b
    80003fd0:	2cc50513          	addi	a0,a0,716 # 8012f298 <itable>
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	cba080e7          	jalr	-838(ra) # 80000c8e <acquire>
    80003fdc:	b741                	j	80003f5c <iput+0x26>

0000000080003fde <iunlockput>:
{
    80003fde:	1101                	addi	sp,sp,-32
    80003fe0:	ec06                	sd	ra,24(sp)
    80003fe2:	e822                	sd	s0,16(sp)
    80003fe4:	e426                	sd	s1,8(sp)
    80003fe6:	1000                	addi	s0,sp,32
    80003fe8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	e54080e7          	jalr	-428(ra) # 80003e3e <iunlock>
  iput(ip);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	f42080e7          	jalr	-190(ra) # 80003f36 <iput>
}
    80003ffc:	60e2                	ld	ra,24(sp)
    80003ffe:	6442                	ld	s0,16(sp)
    80004000:	64a2                	ld	s1,8(sp)
    80004002:	6105                	addi	sp,sp,32
    80004004:	8082                	ret

0000000080004006 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004006:	1141                	addi	sp,sp,-16
    80004008:	e422                	sd	s0,8(sp)
    8000400a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000400c:	411c                	lw	a5,0(a0)
    8000400e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004010:	415c                	lw	a5,4(a0)
    80004012:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004014:	04451783          	lh	a5,68(a0)
    80004018:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000401c:	04a51783          	lh	a5,74(a0)
    80004020:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004024:	04c56783          	lwu	a5,76(a0)
    80004028:	e99c                	sd	a5,16(a1)
}
    8000402a:	6422                	ld	s0,8(sp)
    8000402c:	0141                	addi	sp,sp,16
    8000402e:	8082                	ret

0000000080004030 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004030:	457c                	lw	a5,76(a0)
    80004032:	0ed7e963          	bltu	a5,a3,80004124 <readi+0xf4>
{
    80004036:	7159                	addi	sp,sp,-112
    80004038:	f486                	sd	ra,104(sp)
    8000403a:	f0a2                	sd	s0,96(sp)
    8000403c:	eca6                	sd	s1,88(sp)
    8000403e:	e8ca                	sd	s2,80(sp)
    80004040:	e4ce                	sd	s3,72(sp)
    80004042:	e0d2                	sd	s4,64(sp)
    80004044:	fc56                	sd	s5,56(sp)
    80004046:	f85a                	sd	s6,48(sp)
    80004048:	f45e                	sd	s7,40(sp)
    8000404a:	f062                	sd	s8,32(sp)
    8000404c:	ec66                	sd	s9,24(sp)
    8000404e:	e86a                	sd	s10,16(sp)
    80004050:	e46e                	sd	s11,8(sp)
    80004052:	1880                	addi	s0,sp,112
    80004054:	8b2a                	mv	s6,a0
    80004056:	8bae                	mv	s7,a1
    80004058:	8a32                	mv	s4,a2
    8000405a:	84b6                	mv	s1,a3
    8000405c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000405e:	9f35                	addw	a4,a4,a3
    return 0;
    80004060:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004062:	0ad76063          	bltu	a4,a3,80004102 <readi+0xd2>
  if(off + n > ip->size)
    80004066:	00e7f463          	bgeu	a5,a4,8000406e <readi+0x3e>
    n = ip->size - off;
    8000406a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000406e:	0a0a8963          	beqz	s5,80004120 <readi+0xf0>
    80004072:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004074:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004078:	5c7d                	li	s8,-1
    8000407a:	a82d                	j	800040b4 <readi+0x84>
    8000407c:	020d1d93          	slli	s11,s10,0x20
    80004080:	020ddd93          	srli	s11,s11,0x20
    80004084:	05890613          	addi	a2,s2,88
    80004088:	86ee                	mv	a3,s11
    8000408a:	963a                	add	a2,a2,a4
    8000408c:	85d2                	mv	a1,s4
    8000408e:	855e                	mv	a0,s7
    80004090:	ffffe097          	auipc	ra,0xffffe
    80004094:	7aa080e7          	jalr	1962(ra) # 8000283a <either_copyout>
    80004098:	05850d63          	beq	a0,s8,800040f2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000409c:	854a                	mv	a0,s2
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	5fe080e7          	jalr	1534(ra) # 8000369c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a6:	013d09bb          	addw	s3,s10,s3
    800040aa:	009d04bb          	addw	s1,s10,s1
    800040ae:	9a6e                	add	s4,s4,s11
    800040b0:	0559f763          	bgeu	s3,s5,800040fe <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040b4:	00a4d59b          	srliw	a1,s1,0xa
    800040b8:	855a                	mv	a0,s6
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	8a4080e7          	jalr	-1884(ra) # 8000395e <bmap>
    800040c2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040c6:	cd85                	beqz	a1,800040fe <readi+0xce>
    bp = bread(ip->dev, addr);
    800040c8:	000b2503          	lw	a0,0(s6)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	4a0080e7          	jalr	1184(ra) # 8000356c <bread>
    800040d4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d6:	3ff4f713          	andi	a4,s1,1023
    800040da:	40ec87bb          	subw	a5,s9,a4
    800040de:	413a86bb          	subw	a3,s5,s3
    800040e2:	8d3e                	mv	s10,a5
    800040e4:	2781                	sext.w	a5,a5
    800040e6:	0006861b          	sext.w	a2,a3
    800040ea:	f8f679e3          	bgeu	a2,a5,8000407c <readi+0x4c>
    800040ee:	8d36                	mv	s10,a3
    800040f0:	b771                	j	8000407c <readi+0x4c>
      brelse(bp);
    800040f2:	854a                	mv	a0,s2
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	5a8080e7          	jalr	1448(ra) # 8000369c <brelse>
      tot = -1;
    800040fc:	59fd                	li	s3,-1
  }
  return tot;
    800040fe:	0009851b          	sext.w	a0,s3
}
    80004102:	70a6                	ld	ra,104(sp)
    80004104:	7406                	ld	s0,96(sp)
    80004106:	64e6                	ld	s1,88(sp)
    80004108:	6946                	ld	s2,80(sp)
    8000410a:	69a6                	ld	s3,72(sp)
    8000410c:	6a06                	ld	s4,64(sp)
    8000410e:	7ae2                	ld	s5,56(sp)
    80004110:	7b42                	ld	s6,48(sp)
    80004112:	7ba2                	ld	s7,40(sp)
    80004114:	7c02                	ld	s8,32(sp)
    80004116:	6ce2                	ld	s9,24(sp)
    80004118:	6d42                	ld	s10,16(sp)
    8000411a:	6da2                	ld	s11,8(sp)
    8000411c:	6165                	addi	sp,sp,112
    8000411e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004120:	89d6                	mv	s3,s5
    80004122:	bff1                	j	800040fe <readi+0xce>
    return 0;
    80004124:	4501                	li	a0,0
}
    80004126:	8082                	ret

0000000080004128 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004128:	457c                	lw	a5,76(a0)
    8000412a:	10d7e863          	bltu	a5,a3,8000423a <writei+0x112>
{
    8000412e:	7159                	addi	sp,sp,-112
    80004130:	f486                	sd	ra,104(sp)
    80004132:	f0a2                	sd	s0,96(sp)
    80004134:	eca6                	sd	s1,88(sp)
    80004136:	e8ca                	sd	s2,80(sp)
    80004138:	e4ce                	sd	s3,72(sp)
    8000413a:	e0d2                	sd	s4,64(sp)
    8000413c:	fc56                	sd	s5,56(sp)
    8000413e:	f85a                	sd	s6,48(sp)
    80004140:	f45e                	sd	s7,40(sp)
    80004142:	f062                	sd	s8,32(sp)
    80004144:	ec66                	sd	s9,24(sp)
    80004146:	e86a                	sd	s10,16(sp)
    80004148:	e46e                	sd	s11,8(sp)
    8000414a:	1880                	addi	s0,sp,112
    8000414c:	8aaa                	mv	s5,a0
    8000414e:	8bae                	mv	s7,a1
    80004150:	8a32                	mv	s4,a2
    80004152:	8936                	mv	s2,a3
    80004154:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004156:	00e687bb          	addw	a5,a3,a4
    8000415a:	0ed7e263          	bltu	a5,a3,8000423e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000415e:	00043737          	lui	a4,0x43
    80004162:	0ef76063          	bltu	a4,a5,80004242 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004166:	0c0b0863          	beqz	s6,80004236 <writei+0x10e>
    8000416a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000416c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004170:	5c7d                	li	s8,-1
    80004172:	a091                	j	800041b6 <writei+0x8e>
    80004174:	020d1d93          	slli	s11,s10,0x20
    80004178:	020ddd93          	srli	s11,s11,0x20
    8000417c:	05848513          	addi	a0,s1,88
    80004180:	86ee                	mv	a3,s11
    80004182:	8652                	mv	a2,s4
    80004184:	85de                	mv	a1,s7
    80004186:	953a                	add	a0,a0,a4
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	708080e7          	jalr	1800(ra) # 80002890 <either_copyin>
    80004190:	07850263          	beq	a0,s8,800041f4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004194:	8526                	mv	a0,s1
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	75e080e7          	jalr	1886(ra) # 800048f4 <log_write>
    brelse(bp);
    8000419e:	8526                	mv	a0,s1
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	4fc080e7          	jalr	1276(ra) # 8000369c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a8:	013d09bb          	addw	s3,s10,s3
    800041ac:	012d093b          	addw	s2,s10,s2
    800041b0:	9a6e                	add	s4,s4,s11
    800041b2:	0569f663          	bgeu	s3,s6,800041fe <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041b6:	00a9559b          	srliw	a1,s2,0xa
    800041ba:	8556                	mv	a0,s5
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	7a2080e7          	jalr	1954(ra) # 8000395e <bmap>
    800041c4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041c8:	c99d                	beqz	a1,800041fe <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041ca:	000aa503          	lw	a0,0(s5)
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	39e080e7          	jalr	926(ra) # 8000356c <bread>
    800041d6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d8:	3ff97713          	andi	a4,s2,1023
    800041dc:	40ec87bb          	subw	a5,s9,a4
    800041e0:	413b06bb          	subw	a3,s6,s3
    800041e4:	8d3e                	mv	s10,a5
    800041e6:	2781                	sext.w	a5,a5
    800041e8:	0006861b          	sext.w	a2,a3
    800041ec:	f8f674e3          	bgeu	a2,a5,80004174 <writei+0x4c>
    800041f0:	8d36                	mv	s10,a3
    800041f2:	b749                	j	80004174 <writei+0x4c>
      brelse(bp);
    800041f4:	8526                	mv	a0,s1
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	4a6080e7          	jalr	1190(ra) # 8000369c <brelse>
  }

  if(off > ip->size)
    800041fe:	04caa783          	lw	a5,76(s5)
    80004202:	0127f463          	bgeu	a5,s2,8000420a <writei+0xe2>
    ip->size = off;
    80004206:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000420a:	8556                	mv	a0,s5
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	aa4080e7          	jalr	-1372(ra) # 80003cb0 <iupdate>

  return tot;
    80004214:	0009851b          	sext.w	a0,s3
}
    80004218:	70a6                	ld	ra,104(sp)
    8000421a:	7406                	ld	s0,96(sp)
    8000421c:	64e6                	ld	s1,88(sp)
    8000421e:	6946                	ld	s2,80(sp)
    80004220:	69a6                	ld	s3,72(sp)
    80004222:	6a06                	ld	s4,64(sp)
    80004224:	7ae2                	ld	s5,56(sp)
    80004226:	7b42                	ld	s6,48(sp)
    80004228:	7ba2                	ld	s7,40(sp)
    8000422a:	7c02                	ld	s8,32(sp)
    8000422c:	6ce2                	ld	s9,24(sp)
    8000422e:	6d42                	ld	s10,16(sp)
    80004230:	6da2                	ld	s11,8(sp)
    80004232:	6165                	addi	sp,sp,112
    80004234:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004236:	89da                	mv	s3,s6
    80004238:	bfc9                	j	8000420a <writei+0xe2>
    return -1;
    8000423a:	557d                	li	a0,-1
}
    8000423c:	8082                	ret
    return -1;
    8000423e:	557d                	li	a0,-1
    80004240:	bfe1                	j	80004218 <writei+0xf0>
    return -1;
    80004242:	557d                	li	a0,-1
    80004244:	bfd1                	j	80004218 <writei+0xf0>

0000000080004246 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004246:	1141                	addi	sp,sp,-16
    80004248:	e406                	sd	ra,8(sp)
    8000424a:	e022                	sd	s0,0(sp)
    8000424c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000424e:	4639                	li	a2,14
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	c0a080e7          	jalr	-1014(ra) # 80000e5a <strncmp>
}
    80004258:	60a2                	ld	ra,8(sp)
    8000425a:	6402                	ld	s0,0(sp)
    8000425c:	0141                	addi	sp,sp,16
    8000425e:	8082                	ret

0000000080004260 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004260:	7139                	addi	sp,sp,-64
    80004262:	fc06                	sd	ra,56(sp)
    80004264:	f822                	sd	s0,48(sp)
    80004266:	f426                	sd	s1,40(sp)
    80004268:	f04a                	sd	s2,32(sp)
    8000426a:	ec4e                	sd	s3,24(sp)
    8000426c:	e852                	sd	s4,16(sp)
    8000426e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004270:	04451703          	lh	a4,68(a0)
    80004274:	4785                	li	a5,1
    80004276:	00f71a63          	bne	a4,a5,8000428a <dirlookup+0x2a>
    8000427a:	892a                	mv	s2,a0
    8000427c:	89ae                	mv	s3,a1
    8000427e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004280:	457c                	lw	a5,76(a0)
    80004282:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004284:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004286:	e79d                	bnez	a5,800042b4 <dirlookup+0x54>
    80004288:	a8a5                	j	80004300 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000428a:	00004517          	auipc	a0,0x4
    8000428e:	56650513          	addi	a0,a0,1382 # 800087f0 <syscalls+0x1c8>
    80004292:	ffffc097          	auipc	ra,0xffffc
    80004296:	2aa080e7          	jalr	682(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	56e50513          	addi	a0,a0,1390 # 80008808 <syscalls+0x1e0>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	29a080e7          	jalr	666(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042aa:	24c1                	addiw	s1,s1,16
    800042ac:	04c92783          	lw	a5,76(s2)
    800042b0:	04f4f763          	bgeu	s1,a5,800042fe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b4:	4741                	li	a4,16
    800042b6:	86a6                	mv	a3,s1
    800042b8:	fc040613          	addi	a2,s0,-64
    800042bc:	4581                	li	a1,0
    800042be:	854a                	mv	a0,s2
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	d70080e7          	jalr	-656(ra) # 80004030 <readi>
    800042c8:	47c1                	li	a5,16
    800042ca:	fcf518e3          	bne	a0,a5,8000429a <dirlookup+0x3a>
    if(de.inum == 0)
    800042ce:	fc045783          	lhu	a5,-64(s0)
    800042d2:	dfe1                	beqz	a5,800042aa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042d4:	fc240593          	addi	a1,s0,-62
    800042d8:	854e                	mv	a0,s3
    800042da:	00000097          	auipc	ra,0x0
    800042de:	f6c080e7          	jalr	-148(ra) # 80004246 <namecmp>
    800042e2:	f561                	bnez	a0,800042aa <dirlookup+0x4a>
      if(poff)
    800042e4:	000a0463          	beqz	s4,800042ec <dirlookup+0x8c>
        *poff = off;
    800042e8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042ec:	fc045583          	lhu	a1,-64(s0)
    800042f0:	00092503          	lw	a0,0(s2)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	754080e7          	jalr	1876(ra) # 80003a48 <iget>
    800042fc:	a011                	j	80004300 <dirlookup+0xa0>
  return 0;
    800042fe:	4501                	li	a0,0
}
    80004300:	70e2                	ld	ra,56(sp)
    80004302:	7442                	ld	s0,48(sp)
    80004304:	74a2                	ld	s1,40(sp)
    80004306:	7902                	ld	s2,32(sp)
    80004308:	69e2                	ld	s3,24(sp)
    8000430a:	6a42                	ld	s4,16(sp)
    8000430c:	6121                	addi	sp,sp,64
    8000430e:	8082                	ret

0000000080004310 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004310:	711d                	addi	sp,sp,-96
    80004312:	ec86                	sd	ra,88(sp)
    80004314:	e8a2                	sd	s0,80(sp)
    80004316:	e4a6                	sd	s1,72(sp)
    80004318:	e0ca                	sd	s2,64(sp)
    8000431a:	fc4e                	sd	s3,56(sp)
    8000431c:	f852                	sd	s4,48(sp)
    8000431e:	f456                	sd	s5,40(sp)
    80004320:	f05a                	sd	s6,32(sp)
    80004322:	ec5e                	sd	s7,24(sp)
    80004324:	e862                	sd	s8,16(sp)
    80004326:	e466                	sd	s9,8(sp)
    80004328:	1080                	addi	s0,sp,96
    8000432a:	84aa                	mv	s1,a0
    8000432c:	8b2e                	mv	s6,a1
    8000432e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004330:	00054703          	lbu	a4,0(a0)
    80004334:	02f00793          	li	a5,47
    80004338:	02f70263          	beq	a4,a5,8000435c <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000433c:	ffffe097          	auipc	ra,0xffffe
    80004340:	98e080e7          	jalr	-1650(ra) # 80001cca <myproc>
    80004344:	15053503          	ld	a0,336(a0)
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	9f6080e7          	jalr	-1546(ra) # 80003d3e <idup>
    80004350:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004352:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004356:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004358:	4b85                	li	s7,1
    8000435a:	a875                	j	80004416 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000435c:	4585                	li	a1,1
    8000435e:	4505                	li	a0,1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	6e8080e7          	jalr	1768(ra) # 80003a48 <iget>
    80004368:	8a2a                	mv	s4,a0
    8000436a:	b7e5                	j	80004352 <namex+0x42>
      iunlockput(ip);
    8000436c:	8552                	mv	a0,s4
    8000436e:	00000097          	auipc	ra,0x0
    80004372:	c70080e7          	jalr	-912(ra) # 80003fde <iunlockput>
      return 0;
    80004376:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004378:	8552                	mv	a0,s4
    8000437a:	60e6                	ld	ra,88(sp)
    8000437c:	6446                	ld	s0,80(sp)
    8000437e:	64a6                	ld	s1,72(sp)
    80004380:	6906                	ld	s2,64(sp)
    80004382:	79e2                	ld	s3,56(sp)
    80004384:	7a42                	ld	s4,48(sp)
    80004386:	7aa2                	ld	s5,40(sp)
    80004388:	7b02                	ld	s6,32(sp)
    8000438a:	6be2                	ld	s7,24(sp)
    8000438c:	6c42                	ld	s8,16(sp)
    8000438e:	6ca2                	ld	s9,8(sp)
    80004390:	6125                	addi	sp,sp,96
    80004392:	8082                	ret
      iunlock(ip);
    80004394:	8552                	mv	a0,s4
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	aa8080e7          	jalr	-1368(ra) # 80003e3e <iunlock>
      return ip;
    8000439e:	bfe9                	j	80004378 <namex+0x68>
      iunlockput(ip);
    800043a0:	8552                	mv	a0,s4
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	c3c080e7          	jalr	-964(ra) # 80003fde <iunlockput>
      return 0;
    800043aa:	8a4e                	mv	s4,s3
    800043ac:	b7f1                	j	80004378 <namex+0x68>
  len = path - s;
    800043ae:	40998633          	sub	a2,s3,s1
    800043b2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043b6:	099c5863          	bge	s8,s9,80004446 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800043ba:	4639                	li	a2,14
    800043bc:	85a6                	mv	a1,s1
    800043be:	8556                	mv	a0,s5
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	a26080e7          	jalr	-1498(ra) # 80000de6 <memmove>
    800043c8:	84ce                	mv	s1,s3
  while(*path == '/')
    800043ca:	0004c783          	lbu	a5,0(s1)
    800043ce:	01279763          	bne	a5,s2,800043dc <namex+0xcc>
    path++;
    800043d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043d4:	0004c783          	lbu	a5,0(s1)
    800043d8:	ff278de3          	beq	a5,s2,800043d2 <namex+0xc2>
    ilock(ip);
    800043dc:	8552                	mv	a0,s4
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	99e080e7          	jalr	-1634(ra) # 80003d7c <ilock>
    if(ip->type != T_DIR){
    800043e6:	044a1783          	lh	a5,68(s4)
    800043ea:	f97791e3          	bne	a5,s7,8000436c <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800043ee:	000b0563          	beqz	s6,800043f8 <namex+0xe8>
    800043f2:	0004c783          	lbu	a5,0(s1)
    800043f6:	dfd9                	beqz	a5,80004394 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043f8:	4601                	li	a2,0
    800043fa:	85d6                	mv	a1,s5
    800043fc:	8552                	mv	a0,s4
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	e62080e7          	jalr	-414(ra) # 80004260 <dirlookup>
    80004406:	89aa                	mv	s3,a0
    80004408:	dd41                	beqz	a0,800043a0 <namex+0x90>
    iunlockput(ip);
    8000440a:	8552                	mv	a0,s4
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	bd2080e7          	jalr	-1070(ra) # 80003fde <iunlockput>
    ip = next;
    80004414:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004416:	0004c783          	lbu	a5,0(s1)
    8000441a:	01279763          	bne	a5,s2,80004428 <namex+0x118>
    path++;
    8000441e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004420:	0004c783          	lbu	a5,0(s1)
    80004424:	ff278de3          	beq	a5,s2,8000441e <namex+0x10e>
  if(*path == 0)
    80004428:	cb9d                	beqz	a5,8000445e <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000442a:	0004c783          	lbu	a5,0(s1)
    8000442e:	89a6                	mv	s3,s1
  len = path - s;
    80004430:	4c81                	li	s9,0
    80004432:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004434:	01278963          	beq	a5,s2,80004446 <namex+0x136>
    80004438:	dbbd                	beqz	a5,800043ae <namex+0x9e>
    path++;
    8000443a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000443c:	0009c783          	lbu	a5,0(s3)
    80004440:	ff279ce3          	bne	a5,s2,80004438 <namex+0x128>
    80004444:	b7ad                	j	800043ae <namex+0x9e>
    memmove(name, s, len);
    80004446:	2601                	sext.w	a2,a2
    80004448:	85a6                	mv	a1,s1
    8000444a:	8556                	mv	a0,s5
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	99a080e7          	jalr	-1638(ra) # 80000de6 <memmove>
    name[len] = 0;
    80004454:	9cd6                	add	s9,s9,s5
    80004456:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000445a:	84ce                	mv	s1,s3
    8000445c:	b7bd                	j	800043ca <namex+0xba>
  if(nameiparent){
    8000445e:	f00b0de3          	beqz	s6,80004378 <namex+0x68>
    iput(ip);
    80004462:	8552                	mv	a0,s4
    80004464:	00000097          	auipc	ra,0x0
    80004468:	ad2080e7          	jalr	-1326(ra) # 80003f36 <iput>
    return 0;
    8000446c:	4a01                	li	s4,0
    8000446e:	b729                	j	80004378 <namex+0x68>

0000000080004470 <dirlink>:
{
    80004470:	7139                	addi	sp,sp,-64
    80004472:	fc06                	sd	ra,56(sp)
    80004474:	f822                	sd	s0,48(sp)
    80004476:	f426                	sd	s1,40(sp)
    80004478:	f04a                	sd	s2,32(sp)
    8000447a:	ec4e                	sd	s3,24(sp)
    8000447c:	e852                	sd	s4,16(sp)
    8000447e:	0080                	addi	s0,sp,64
    80004480:	892a                	mv	s2,a0
    80004482:	8a2e                	mv	s4,a1
    80004484:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004486:	4601                	li	a2,0
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	dd8080e7          	jalr	-552(ra) # 80004260 <dirlookup>
    80004490:	e93d                	bnez	a0,80004506 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004492:	04c92483          	lw	s1,76(s2)
    80004496:	c49d                	beqz	s1,800044c4 <dirlink+0x54>
    80004498:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000449a:	4741                	li	a4,16
    8000449c:	86a6                	mv	a3,s1
    8000449e:	fc040613          	addi	a2,s0,-64
    800044a2:	4581                	li	a1,0
    800044a4:	854a                	mv	a0,s2
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	b8a080e7          	jalr	-1142(ra) # 80004030 <readi>
    800044ae:	47c1                	li	a5,16
    800044b0:	06f51163          	bne	a0,a5,80004512 <dirlink+0xa2>
    if(de.inum == 0)
    800044b4:	fc045783          	lhu	a5,-64(s0)
    800044b8:	c791                	beqz	a5,800044c4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ba:	24c1                	addiw	s1,s1,16
    800044bc:	04c92783          	lw	a5,76(s2)
    800044c0:	fcf4ede3          	bltu	s1,a5,8000449a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044c4:	4639                	li	a2,14
    800044c6:	85d2                	mv	a1,s4
    800044c8:	fc240513          	addi	a0,s0,-62
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	9ca080e7          	jalr	-1590(ra) # 80000e96 <strncpy>
  de.inum = inum;
    800044d4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d8:	4741                	li	a4,16
    800044da:	86a6                	mv	a3,s1
    800044dc:	fc040613          	addi	a2,s0,-64
    800044e0:	4581                	li	a1,0
    800044e2:	854a                	mv	a0,s2
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	c44080e7          	jalr	-956(ra) # 80004128 <writei>
    800044ec:	1541                	addi	a0,a0,-16
    800044ee:	00a03533          	snez	a0,a0
    800044f2:	40a00533          	neg	a0,a0
}
    800044f6:	70e2                	ld	ra,56(sp)
    800044f8:	7442                	ld	s0,48(sp)
    800044fa:	74a2                	ld	s1,40(sp)
    800044fc:	7902                	ld	s2,32(sp)
    800044fe:	69e2                	ld	s3,24(sp)
    80004500:	6a42                	ld	s4,16(sp)
    80004502:	6121                	addi	sp,sp,64
    80004504:	8082                	ret
    iput(ip);
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	a30080e7          	jalr	-1488(ra) # 80003f36 <iput>
    return -1;
    8000450e:	557d                	li	a0,-1
    80004510:	b7dd                	j	800044f6 <dirlink+0x86>
      panic("dirlink read");
    80004512:	00004517          	auipc	a0,0x4
    80004516:	30650513          	addi	a0,a0,774 # 80008818 <syscalls+0x1f0>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	022080e7          	jalr	34(ra) # 8000053c <panic>

0000000080004522 <namei>:

struct inode*
namei(char *path)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000452a:	fe040613          	addi	a2,s0,-32
    8000452e:	4581                	li	a1,0
    80004530:	00000097          	auipc	ra,0x0
    80004534:	de0080e7          	jalr	-544(ra) # 80004310 <namex>
}
    80004538:	60e2                	ld	ra,24(sp)
    8000453a:	6442                	ld	s0,16(sp)
    8000453c:	6105                	addi	sp,sp,32
    8000453e:	8082                	ret

0000000080004540 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004540:	1141                	addi	sp,sp,-16
    80004542:	e406                	sd	ra,8(sp)
    80004544:	e022                	sd	s0,0(sp)
    80004546:	0800                	addi	s0,sp,16
    80004548:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000454a:	4585                	li	a1,1
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	dc4080e7          	jalr	-572(ra) # 80004310 <namex>
}
    80004554:	60a2                	ld	ra,8(sp)
    80004556:	6402                	ld	s0,0(sp)
    80004558:	0141                	addi	sp,sp,16
    8000455a:	8082                	ret

000000008000455c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000455c:	1101                	addi	sp,sp,-32
    8000455e:	ec06                	sd	ra,24(sp)
    80004560:	e822                	sd	s0,16(sp)
    80004562:	e426                	sd	s1,8(sp)
    80004564:	e04a                	sd	s2,0(sp)
    80004566:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004568:	0012c917          	auipc	s2,0x12c
    8000456c:	7d890913          	addi	s2,s2,2008 # 80130d40 <log>
    80004570:	01892583          	lw	a1,24(s2)
    80004574:	02892503          	lw	a0,40(s2)
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	ff4080e7          	jalr	-12(ra) # 8000356c <bread>
    80004580:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004582:	02c92603          	lw	a2,44(s2)
    80004586:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004588:	00c05f63          	blez	a2,800045a6 <write_head+0x4a>
    8000458c:	0012c717          	auipc	a4,0x12c
    80004590:	7e470713          	addi	a4,a4,2020 # 80130d70 <log+0x30>
    80004594:	87aa                	mv	a5,a0
    80004596:	060a                	slli	a2,a2,0x2
    80004598:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000459a:	4314                	lw	a3,0(a4)
    8000459c:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000459e:	0711                	addi	a4,a4,4
    800045a0:	0791                	addi	a5,a5,4
    800045a2:	fec79ce3          	bne	a5,a2,8000459a <write_head+0x3e>
  }
  bwrite(buf);
    800045a6:	8526                	mv	a0,s1
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	0b6080e7          	jalr	182(ra) # 8000365e <bwrite>
  brelse(buf);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	0ea080e7          	jalr	234(ra) # 8000369c <brelse>
}
    800045ba:	60e2                	ld	ra,24(sp)
    800045bc:	6442                	ld	s0,16(sp)
    800045be:	64a2                	ld	s1,8(sp)
    800045c0:	6902                	ld	s2,0(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret

00000000800045c6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c6:	0012c797          	auipc	a5,0x12c
    800045ca:	7a67a783          	lw	a5,1958(a5) # 80130d6c <log+0x2c>
    800045ce:	0af05d63          	blez	a5,80004688 <install_trans+0xc2>
{
    800045d2:	7139                	addi	sp,sp,-64
    800045d4:	fc06                	sd	ra,56(sp)
    800045d6:	f822                	sd	s0,48(sp)
    800045d8:	f426                	sd	s1,40(sp)
    800045da:	f04a                	sd	s2,32(sp)
    800045dc:	ec4e                	sd	s3,24(sp)
    800045de:	e852                	sd	s4,16(sp)
    800045e0:	e456                	sd	s5,8(sp)
    800045e2:	e05a                	sd	s6,0(sp)
    800045e4:	0080                	addi	s0,sp,64
    800045e6:	8b2a                	mv	s6,a0
    800045e8:	0012ca97          	auipc	s5,0x12c
    800045ec:	788a8a93          	addi	s5,s5,1928 # 80130d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045f2:	0012c997          	auipc	s3,0x12c
    800045f6:	74e98993          	addi	s3,s3,1870 # 80130d40 <log>
    800045fa:	a00d                	j	8000461c <install_trans+0x56>
    brelse(lbuf);
    800045fc:	854a                	mv	a0,s2
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	09e080e7          	jalr	158(ra) # 8000369c <brelse>
    brelse(dbuf);
    80004606:	8526                	mv	a0,s1
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	094080e7          	jalr	148(ra) # 8000369c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004610:	2a05                	addiw	s4,s4,1
    80004612:	0a91                	addi	s5,s5,4
    80004614:	02c9a783          	lw	a5,44(s3)
    80004618:	04fa5e63          	bge	s4,a5,80004674 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000461c:	0189a583          	lw	a1,24(s3)
    80004620:	014585bb          	addw	a1,a1,s4
    80004624:	2585                	addiw	a1,a1,1
    80004626:	0289a503          	lw	a0,40(s3)
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	f42080e7          	jalr	-190(ra) # 8000356c <bread>
    80004632:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004634:	000aa583          	lw	a1,0(s5)
    80004638:	0289a503          	lw	a0,40(s3)
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	f30080e7          	jalr	-208(ra) # 8000356c <bread>
    80004644:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004646:	40000613          	li	a2,1024
    8000464a:	05890593          	addi	a1,s2,88
    8000464e:	05850513          	addi	a0,a0,88
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	794080e7          	jalr	1940(ra) # 80000de6 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000465a:	8526                	mv	a0,s1
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	002080e7          	jalr	2(ra) # 8000365e <bwrite>
    if(recovering == 0)
    80004664:	f80b1ce3          	bnez	s6,800045fc <install_trans+0x36>
      bunpin(dbuf);
    80004668:	8526                	mv	a0,s1
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	10a080e7          	jalr	266(ra) # 80003774 <bunpin>
    80004672:	b769                	j	800045fc <install_trans+0x36>
}
    80004674:	70e2                	ld	ra,56(sp)
    80004676:	7442                	ld	s0,48(sp)
    80004678:	74a2                	ld	s1,40(sp)
    8000467a:	7902                	ld	s2,32(sp)
    8000467c:	69e2                	ld	s3,24(sp)
    8000467e:	6a42                	ld	s4,16(sp)
    80004680:	6aa2                	ld	s5,8(sp)
    80004682:	6b02                	ld	s6,0(sp)
    80004684:	6121                	addi	sp,sp,64
    80004686:	8082                	ret
    80004688:	8082                	ret

000000008000468a <initlog>:
{
    8000468a:	7179                	addi	sp,sp,-48
    8000468c:	f406                	sd	ra,40(sp)
    8000468e:	f022                	sd	s0,32(sp)
    80004690:	ec26                	sd	s1,24(sp)
    80004692:	e84a                	sd	s2,16(sp)
    80004694:	e44e                	sd	s3,8(sp)
    80004696:	1800                	addi	s0,sp,48
    80004698:	892a                	mv	s2,a0
    8000469a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000469c:	0012c497          	auipc	s1,0x12c
    800046a0:	6a448493          	addi	s1,s1,1700 # 80130d40 <log>
    800046a4:	00004597          	auipc	a1,0x4
    800046a8:	18458593          	addi	a1,a1,388 # 80008828 <syscalls+0x200>
    800046ac:	8526                	mv	a0,s1
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	550080e7          	jalr	1360(ra) # 80000bfe <initlock>
  log.start = sb->logstart;
    800046b6:	0149a583          	lw	a1,20(s3)
    800046ba:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046bc:	0109a783          	lw	a5,16(s3)
    800046c0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046c2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046c6:	854a                	mv	a0,s2
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	ea4080e7          	jalr	-348(ra) # 8000356c <bread>
  log.lh.n = lh->n;
    800046d0:	4d30                	lw	a2,88(a0)
    800046d2:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046d4:	00c05f63          	blez	a2,800046f2 <initlog+0x68>
    800046d8:	87aa                	mv	a5,a0
    800046da:	0012c717          	auipc	a4,0x12c
    800046de:	69670713          	addi	a4,a4,1686 # 80130d70 <log+0x30>
    800046e2:	060a                	slli	a2,a2,0x2
    800046e4:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800046e6:	4ff4                	lw	a3,92(a5)
    800046e8:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046ea:	0791                	addi	a5,a5,4
    800046ec:	0711                	addi	a4,a4,4
    800046ee:	fec79ce3          	bne	a5,a2,800046e6 <initlog+0x5c>
  brelse(buf);
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	faa080e7          	jalr	-86(ra) # 8000369c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046fa:	4505                	li	a0,1
    800046fc:	00000097          	auipc	ra,0x0
    80004700:	eca080e7          	jalr	-310(ra) # 800045c6 <install_trans>
  log.lh.n = 0;
    80004704:	0012c797          	auipc	a5,0x12c
    80004708:	6607a423          	sw	zero,1640(a5) # 80130d6c <log+0x2c>
  write_head(); // clear the log
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	e50080e7          	jalr	-432(ra) # 8000455c <write_head>
}
    80004714:	70a2                	ld	ra,40(sp)
    80004716:	7402                	ld	s0,32(sp)
    80004718:	64e2                	ld	s1,24(sp)
    8000471a:	6942                	ld	s2,16(sp)
    8000471c:	69a2                	ld	s3,8(sp)
    8000471e:	6145                	addi	sp,sp,48
    80004720:	8082                	ret

0000000080004722 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004722:	1101                	addi	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	e04a                	sd	s2,0(sp)
    8000472c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000472e:	0012c517          	auipc	a0,0x12c
    80004732:	61250513          	addi	a0,a0,1554 # 80130d40 <log>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	558080e7          	jalr	1368(ra) # 80000c8e <acquire>
  while(1){
    if(log.committing){
    8000473e:	0012c497          	auipc	s1,0x12c
    80004742:	60248493          	addi	s1,s1,1538 # 80130d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004746:	4979                	li	s2,30
    80004748:	a039                	j	80004756 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000474a:	85a6                	mv	a1,s1
    8000474c:	8526                	mv	a0,s1
    8000474e:	ffffe097          	auipc	ra,0xffffe
    80004752:	ce4080e7          	jalr	-796(ra) # 80002432 <sleep>
    if(log.committing){
    80004756:	50dc                	lw	a5,36(s1)
    80004758:	fbed                	bnez	a5,8000474a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000475a:	5098                	lw	a4,32(s1)
    8000475c:	2705                	addiw	a4,a4,1
    8000475e:	0027179b          	slliw	a5,a4,0x2
    80004762:	9fb9                	addw	a5,a5,a4
    80004764:	0017979b          	slliw	a5,a5,0x1
    80004768:	54d4                	lw	a3,44(s1)
    8000476a:	9fb5                	addw	a5,a5,a3
    8000476c:	00f95963          	bge	s2,a5,8000477e <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004770:	85a6                	mv	a1,s1
    80004772:	8526                	mv	a0,s1
    80004774:	ffffe097          	auipc	ra,0xffffe
    80004778:	cbe080e7          	jalr	-834(ra) # 80002432 <sleep>
    8000477c:	bfe9                	j	80004756 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000477e:	0012c517          	auipc	a0,0x12c
    80004782:	5c250513          	addi	a0,a0,1474 # 80130d40 <log>
    80004786:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	5ba080e7          	jalr	1466(ra) # 80000d42 <release>
      break;
    }
  }
}
    80004790:	60e2                	ld	ra,24(sp)
    80004792:	6442                	ld	s0,16(sp)
    80004794:	64a2                	ld	s1,8(sp)
    80004796:	6902                	ld	s2,0(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret

000000008000479c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000479c:	7139                	addi	sp,sp,-64
    8000479e:	fc06                	sd	ra,56(sp)
    800047a0:	f822                	sd	s0,48(sp)
    800047a2:	f426                	sd	s1,40(sp)
    800047a4:	f04a                	sd	s2,32(sp)
    800047a6:	ec4e                	sd	s3,24(sp)
    800047a8:	e852                	sd	s4,16(sp)
    800047aa:	e456                	sd	s5,8(sp)
    800047ac:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047ae:	0012c497          	auipc	s1,0x12c
    800047b2:	59248493          	addi	s1,s1,1426 # 80130d40 <log>
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4d6080e7          	jalr	1238(ra) # 80000c8e <acquire>
  log.outstanding -= 1;
    800047c0:	509c                	lw	a5,32(s1)
    800047c2:	37fd                	addiw	a5,a5,-1
    800047c4:	0007891b          	sext.w	s2,a5
    800047c8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047ca:	50dc                	lw	a5,36(s1)
    800047cc:	e7b9                	bnez	a5,8000481a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047ce:	04091e63          	bnez	s2,8000482a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047d2:	0012c497          	auipc	s1,0x12c
    800047d6:	56e48493          	addi	s1,s1,1390 # 80130d40 <log>
    800047da:	4785                	li	a5,1
    800047dc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047de:	8526                	mv	a0,s1
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	562080e7          	jalr	1378(ra) # 80000d42 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047e8:	54dc                	lw	a5,44(s1)
    800047ea:	06f04763          	bgtz	a5,80004858 <end_op+0xbc>
    acquire(&log.lock);
    800047ee:	0012c497          	auipc	s1,0x12c
    800047f2:	55248493          	addi	s1,s1,1362 # 80130d40 <log>
    800047f6:	8526                	mv	a0,s1
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	496080e7          	jalr	1174(ra) # 80000c8e <acquire>
    log.committing = 0;
    80004800:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	c90080e7          	jalr	-880(ra) # 80002496 <wakeup>
    release(&log.lock);
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	532080e7          	jalr	1330(ra) # 80000d42 <release>
}
    80004818:	a03d                	j	80004846 <end_op+0xaa>
    panic("log.committing");
    8000481a:	00004517          	auipc	a0,0x4
    8000481e:	01650513          	addi	a0,a0,22 # 80008830 <syscalls+0x208>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	d1a080e7          	jalr	-742(ra) # 8000053c <panic>
    wakeup(&log);
    8000482a:	0012c497          	auipc	s1,0x12c
    8000482e:	51648493          	addi	s1,s1,1302 # 80130d40 <log>
    80004832:	8526                	mv	a0,s1
    80004834:	ffffe097          	auipc	ra,0xffffe
    80004838:	c62080e7          	jalr	-926(ra) # 80002496 <wakeup>
  release(&log.lock);
    8000483c:	8526                	mv	a0,s1
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	504080e7          	jalr	1284(ra) # 80000d42 <release>
}
    80004846:	70e2                	ld	ra,56(sp)
    80004848:	7442                	ld	s0,48(sp)
    8000484a:	74a2                	ld	s1,40(sp)
    8000484c:	7902                	ld	s2,32(sp)
    8000484e:	69e2                	ld	s3,24(sp)
    80004850:	6a42                	ld	s4,16(sp)
    80004852:	6aa2                	ld	s5,8(sp)
    80004854:	6121                	addi	sp,sp,64
    80004856:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004858:	0012ca97          	auipc	s5,0x12c
    8000485c:	518a8a93          	addi	s5,s5,1304 # 80130d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004860:	0012ca17          	auipc	s4,0x12c
    80004864:	4e0a0a13          	addi	s4,s4,1248 # 80130d40 <log>
    80004868:	018a2583          	lw	a1,24(s4)
    8000486c:	012585bb          	addw	a1,a1,s2
    80004870:	2585                	addiw	a1,a1,1
    80004872:	028a2503          	lw	a0,40(s4)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	cf6080e7          	jalr	-778(ra) # 8000356c <bread>
    8000487e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004880:	000aa583          	lw	a1,0(s5)
    80004884:	028a2503          	lw	a0,40(s4)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	ce4080e7          	jalr	-796(ra) # 8000356c <bread>
    80004890:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004892:	40000613          	li	a2,1024
    80004896:	05850593          	addi	a1,a0,88
    8000489a:	05848513          	addi	a0,s1,88
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	548080e7          	jalr	1352(ra) # 80000de6 <memmove>
    bwrite(to);  // write the log
    800048a6:	8526                	mv	a0,s1
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	db6080e7          	jalr	-586(ra) # 8000365e <bwrite>
    brelse(from);
    800048b0:	854e                	mv	a0,s3
    800048b2:	fffff097          	auipc	ra,0xfffff
    800048b6:	dea080e7          	jalr	-534(ra) # 8000369c <brelse>
    brelse(to);
    800048ba:	8526                	mv	a0,s1
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	de0080e7          	jalr	-544(ra) # 8000369c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c4:	2905                	addiw	s2,s2,1
    800048c6:	0a91                	addi	s5,s5,4
    800048c8:	02ca2783          	lw	a5,44(s4)
    800048cc:	f8f94ee3          	blt	s2,a5,80004868 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	c8c080e7          	jalr	-884(ra) # 8000455c <write_head>
    install_trans(0); // Now install writes to home locations
    800048d8:	4501                	li	a0,0
    800048da:	00000097          	auipc	ra,0x0
    800048de:	cec080e7          	jalr	-788(ra) # 800045c6 <install_trans>
    log.lh.n = 0;
    800048e2:	0012c797          	auipc	a5,0x12c
    800048e6:	4807a523          	sw	zero,1162(a5) # 80130d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	c72080e7          	jalr	-910(ra) # 8000455c <write_head>
    800048f2:	bdf5                	j	800047ee <end_op+0x52>

00000000800048f4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048f4:	1101                	addi	sp,sp,-32
    800048f6:	ec06                	sd	ra,24(sp)
    800048f8:	e822                	sd	s0,16(sp)
    800048fa:	e426                	sd	s1,8(sp)
    800048fc:	e04a                	sd	s2,0(sp)
    800048fe:	1000                	addi	s0,sp,32
    80004900:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004902:	0012c917          	auipc	s2,0x12c
    80004906:	43e90913          	addi	s2,s2,1086 # 80130d40 <log>
    8000490a:	854a                	mv	a0,s2
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	382080e7          	jalr	898(ra) # 80000c8e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004914:	02c92603          	lw	a2,44(s2)
    80004918:	47f5                	li	a5,29
    8000491a:	06c7c563          	blt	a5,a2,80004984 <log_write+0x90>
    8000491e:	0012c797          	auipc	a5,0x12c
    80004922:	43e7a783          	lw	a5,1086(a5) # 80130d5c <log+0x1c>
    80004926:	37fd                	addiw	a5,a5,-1
    80004928:	04f65e63          	bge	a2,a5,80004984 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000492c:	0012c797          	auipc	a5,0x12c
    80004930:	4347a783          	lw	a5,1076(a5) # 80130d60 <log+0x20>
    80004934:	06f05063          	blez	a5,80004994 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004938:	4781                	li	a5,0
    8000493a:	06c05563          	blez	a2,800049a4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000493e:	44cc                	lw	a1,12(s1)
    80004940:	0012c717          	auipc	a4,0x12c
    80004944:	43070713          	addi	a4,a4,1072 # 80130d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004948:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000494a:	4314                	lw	a3,0(a4)
    8000494c:	04b68c63          	beq	a3,a1,800049a4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004950:	2785                	addiw	a5,a5,1
    80004952:	0711                	addi	a4,a4,4
    80004954:	fef61be3          	bne	a2,a5,8000494a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004958:	0621                	addi	a2,a2,8
    8000495a:	060a                	slli	a2,a2,0x2
    8000495c:	0012c797          	auipc	a5,0x12c
    80004960:	3e478793          	addi	a5,a5,996 # 80130d40 <log>
    80004964:	97b2                	add	a5,a5,a2
    80004966:	44d8                	lw	a4,12(s1)
    80004968:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000496a:	8526                	mv	a0,s1
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	dcc080e7          	jalr	-564(ra) # 80003738 <bpin>
    log.lh.n++;
    80004974:	0012c717          	auipc	a4,0x12c
    80004978:	3cc70713          	addi	a4,a4,972 # 80130d40 <log>
    8000497c:	575c                	lw	a5,44(a4)
    8000497e:	2785                	addiw	a5,a5,1
    80004980:	d75c                	sw	a5,44(a4)
    80004982:	a82d                	j	800049bc <log_write+0xc8>
    panic("too big a transaction");
    80004984:	00004517          	auipc	a0,0x4
    80004988:	ebc50513          	addi	a0,a0,-324 # 80008840 <syscalls+0x218>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	bb0080e7          	jalr	-1104(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004994:	00004517          	auipc	a0,0x4
    80004998:	ec450513          	addi	a0,a0,-316 # 80008858 <syscalls+0x230>
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	ba0080e7          	jalr	-1120(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800049a4:	00878693          	addi	a3,a5,8
    800049a8:	068a                	slli	a3,a3,0x2
    800049aa:	0012c717          	auipc	a4,0x12c
    800049ae:	39670713          	addi	a4,a4,918 # 80130d40 <log>
    800049b2:	9736                	add	a4,a4,a3
    800049b4:	44d4                	lw	a3,12(s1)
    800049b6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049b8:	faf609e3          	beq	a2,a5,8000496a <log_write+0x76>
  }
  release(&log.lock);
    800049bc:	0012c517          	auipc	a0,0x12c
    800049c0:	38450513          	addi	a0,a0,900 # 80130d40 <log>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	37e080e7          	jalr	894(ra) # 80000d42 <release>
}
    800049cc:	60e2                	ld	ra,24(sp)
    800049ce:	6442                	ld	s0,16(sp)
    800049d0:	64a2                	ld	s1,8(sp)
    800049d2:	6902                	ld	s2,0(sp)
    800049d4:	6105                	addi	sp,sp,32
    800049d6:	8082                	ret

00000000800049d8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049d8:	1101                	addi	sp,sp,-32
    800049da:	ec06                	sd	ra,24(sp)
    800049dc:	e822                	sd	s0,16(sp)
    800049de:	e426                	sd	s1,8(sp)
    800049e0:	e04a                	sd	s2,0(sp)
    800049e2:	1000                	addi	s0,sp,32
    800049e4:	84aa                	mv	s1,a0
    800049e6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049e8:	00004597          	auipc	a1,0x4
    800049ec:	e9058593          	addi	a1,a1,-368 # 80008878 <syscalls+0x250>
    800049f0:	0521                	addi	a0,a0,8
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	20c080e7          	jalr	524(ra) # 80000bfe <initlock>
  lk->name = name;
    800049fa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a02:	0204a423          	sw	zero,40(s1)
}
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6902                	ld	s2,0(sp)
    80004a0e:	6105                	addi	sp,sp,32
    80004a10:	8082                	ret

0000000080004a12 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a20:	00850913          	addi	s2,a0,8
    80004a24:	854a                	mv	a0,s2
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	268080e7          	jalr	616(ra) # 80000c8e <acquire>
  while (lk->locked) {
    80004a2e:	409c                	lw	a5,0(s1)
    80004a30:	cb89                	beqz	a5,80004a42 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a32:	85ca                	mv	a1,s2
    80004a34:	8526                	mv	a0,s1
    80004a36:	ffffe097          	auipc	ra,0xffffe
    80004a3a:	9fc080e7          	jalr	-1540(ra) # 80002432 <sleep>
  while (lk->locked) {
    80004a3e:	409c                	lw	a5,0(s1)
    80004a40:	fbed                	bnez	a5,80004a32 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a42:	4785                	li	a5,1
    80004a44:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a46:	ffffd097          	auipc	ra,0xffffd
    80004a4a:	284080e7          	jalr	644(ra) # 80001cca <myproc>
    80004a4e:	591c                	lw	a5,48(a0)
    80004a50:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a52:	854a                	mv	a0,s2
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	2ee080e7          	jalr	750(ra) # 80000d42 <release>
}
    80004a5c:	60e2                	ld	ra,24(sp)
    80004a5e:	6442                	ld	s0,16(sp)
    80004a60:	64a2                	ld	s1,8(sp)
    80004a62:	6902                	ld	s2,0(sp)
    80004a64:	6105                	addi	sp,sp,32
    80004a66:	8082                	ret

0000000080004a68 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a68:	1101                	addi	sp,sp,-32
    80004a6a:	ec06                	sd	ra,24(sp)
    80004a6c:	e822                	sd	s0,16(sp)
    80004a6e:	e426                	sd	s1,8(sp)
    80004a70:	e04a                	sd	s2,0(sp)
    80004a72:	1000                	addi	s0,sp,32
    80004a74:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a76:	00850913          	addi	s2,a0,8
    80004a7a:	854a                	mv	a0,s2
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	212080e7          	jalr	530(ra) # 80000c8e <acquire>
  lk->locked = 0;
    80004a84:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a88:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	ffffe097          	auipc	ra,0xffffe
    80004a92:	a08080e7          	jalr	-1528(ra) # 80002496 <wakeup>
  release(&lk->lk);
    80004a96:	854a                	mv	a0,s2
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	2aa080e7          	jalr	682(ra) # 80000d42 <release>
}
    80004aa0:	60e2                	ld	ra,24(sp)
    80004aa2:	6442                	ld	s0,16(sp)
    80004aa4:	64a2                	ld	s1,8(sp)
    80004aa6:	6902                	ld	s2,0(sp)
    80004aa8:	6105                	addi	sp,sp,32
    80004aaa:	8082                	ret

0000000080004aac <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aac:	7179                	addi	sp,sp,-48
    80004aae:	f406                	sd	ra,40(sp)
    80004ab0:	f022                	sd	s0,32(sp)
    80004ab2:	ec26                	sd	s1,24(sp)
    80004ab4:	e84a                	sd	s2,16(sp)
    80004ab6:	e44e                	sd	s3,8(sp)
    80004ab8:	1800                	addi	s0,sp,48
    80004aba:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004abc:	00850913          	addi	s2,a0,8
    80004ac0:	854a                	mv	a0,s2
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	1cc080e7          	jalr	460(ra) # 80000c8e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aca:	409c                	lw	a5,0(s1)
    80004acc:	ef99                	bnez	a5,80004aea <holdingsleep+0x3e>
    80004ace:	4481                	li	s1,0
  release(&lk->lk);
    80004ad0:	854a                	mv	a0,s2
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	270080e7          	jalr	624(ra) # 80000d42 <release>
  return r;
}
    80004ada:	8526                	mv	a0,s1
    80004adc:	70a2                	ld	ra,40(sp)
    80004ade:	7402                	ld	s0,32(sp)
    80004ae0:	64e2                	ld	s1,24(sp)
    80004ae2:	6942                	ld	s2,16(sp)
    80004ae4:	69a2                	ld	s3,8(sp)
    80004ae6:	6145                	addi	sp,sp,48
    80004ae8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aea:	0284a983          	lw	s3,40(s1)
    80004aee:	ffffd097          	auipc	ra,0xffffd
    80004af2:	1dc080e7          	jalr	476(ra) # 80001cca <myproc>
    80004af6:	5904                	lw	s1,48(a0)
    80004af8:	413484b3          	sub	s1,s1,s3
    80004afc:	0014b493          	seqz	s1,s1
    80004b00:	bfc1                	j	80004ad0 <holdingsleep+0x24>

0000000080004b02 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b02:	1141                	addi	sp,sp,-16
    80004b04:	e406                	sd	ra,8(sp)
    80004b06:	e022                	sd	s0,0(sp)
    80004b08:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b0a:	00004597          	auipc	a1,0x4
    80004b0e:	d7e58593          	addi	a1,a1,-642 # 80008888 <syscalls+0x260>
    80004b12:	0012c517          	auipc	a0,0x12c
    80004b16:	37650513          	addi	a0,a0,886 # 80130e88 <ftable>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	0e4080e7          	jalr	228(ra) # 80000bfe <initlock>
}
    80004b22:	60a2                	ld	ra,8(sp)
    80004b24:	6402                	ld	s0,0(sp)
    80004b26:	0141                	addi	sp,sp,16
    80004b28:	8082                	ret

0000000080004b2a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b2a:	1101                	addi	sp,sp,-32
    80004b2c:	ec06                	sd	ra,24(sp)
    80004b2e:	e822                	sd	s0,16(sp)
    80004b30:	e426                	sd	s1,8(sp)
    80004b32:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b34:	0012c517          	auipc	a0,0x12c
    80004b38:	35450513          	addi	a0,a0,852 # 80130e88 <ftable>
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	152080e7          	jalr	338(ra) # 80000c8e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b44:	0012c497          	auipc	s1,0x12c
    80004b48:	35c48493          	addi	s1,s1,860 # 80130ea0 <ftable+0x18>
    80004b4c:	0012d717          	auipc	a4,0x12d
    80004b50:	2f470713          	addi	a4,a4,756 # 80131e40 <disk>
    if(f->ref == 0){
    80004b54:	40dc                	lw	a5,4(s1)
    80004b56:	cf99                	beqz	a5,80004b74 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b58:	02848493          	addi	s1,s1,40
    80004b5c:	fee49ce3          	bne	s1,a4,80004b54 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b60:	0012c517          	auipc	a0,0x12c
    80004b64:	32850513          	addi	a0,a0,808 # 80130e88 <ftable>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	1da080e7          	jalr	474(ra) # 80000d42 <release>
  return 0;
    80004b70:	4481                	li	s1,0
    80004b72:	a819                	j	80004b88 <filealloc+0x5e>
      f->ref = 1;
    80004b74:	4785                	li	a5,1
    80004b76:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b78:	0012c517          	auipc	a0,0x12c
    80004b7c:	31050513          	addi	a0,a0,784 # 80130e88 <ftable>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	1c2080e7          	jalr	450(ra) # 80000d42 <release>
}
    80004b88:	8526                	mv	a0,s1
    80004b8a:	60e2                	ld	ra,24(sp)
    80004b8c:	6442                	ld	s0,16(sp)
    80004b8e:	64a2                	ld	s1,8(sp)
    80004b90:	6105                	addi	sp,sp,32
    80004b92:	8082                	ret

0000000080004b94 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b94:	1101                	addi	sp,sp,-32
    80004b96:	ec06                	sd	ra,24(sp)
    80004b98:	e822                	sd	s0,16(sp)
    80004b9a:	e426                	sd	s1,8(sp)
    80004b9c:	1000                	addi	s0,sp,32
    80004b9e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ba0:	0012c517          	auipc	a0,0x12c
    80004ba4:	2e850513          	addi	a0,a0,744 # 80130e88 <ftable>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	0e6080e7          	jalr	230(ra) # 80000c8e <acquire>
  if(f->ref < 1)
    80004bb0:	40dc                	lw	a5,4(s1)
    80004bb2:	02f05263          	blez	a5,80004bd6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bb6:	2785                	addiw	a5,a5,1
    80004bb8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bba:	0012c517          	auipc	a0,0x12c
    80004bbe:	2ce50513          	addi	a0,a0,718 # 80130e88 <ftable>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	180080e7          	jalr	384(ra) # 80000d42 <release>
  return f;
}
    80004bca:	8526                	mv	a0,s1
    80004bcc:	60e2                	ld	ra,24(sp)
    80004bce:	6442                	ld	s0,16(sp)
    80004bd0:	64a2                	ld	s1,8(sp)
    80004bd2:	6105                	addi	sp,sp,32
    80004bd4:	8082                	ret
    panic("filedup");
    80004bd6:	00004517          	auipc	a0,0x4
    80004bda:	cba50513          	addi	a0,a0,-838 # 80008890 <syscalls+0x268>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	95e080e7          	jalr	-1698(ra) # 8000053c <panic>

0000000080004be6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004be6:	7139                	addi	sp,sp,-64
    80004be8:	fc06                	sd	ra,56(sp)
    80004bea:	f822                	sd	s0,48(sp)
    80004bec:	f426                	sd	s1,40(sp)
    80004bee:	f04a                	sd	s2,32(sp)
    80004bf0:	ec4e                	sd	s3,24(sp)
    80004bf2:	e852                	sd	s4,16(sp)
    80004bf4:	e456                	sd	s5,8(sp)
    80004bf6:	0080                	addi	s0,sp,64
    80004bf8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bfa:	0012c517          	auipc	a0,0x12c
    80004bfe:	28e50513          	addi	a0,a0,654 # 80130e88 <ftable>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	08c080e7          	jalr	140(ra) # 80000c8e <acquire>
  if(f->ref < 1)
    80004c0a:	40dc                	lw	a5,4(s1)
    80004c0c:	06f05163          	blez	a5,80004c6e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c10:	37fd                	addiw	a5,a5,-1
    80004c12:	0007871b          	sext.w	a4,a5
    80004c16:	c0dc                	sw	a5,4(s1)
    80004c18:	06e04363          	bgtz	a4,80004c7e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c1c:	0004a903          	lw	s2,0(s1)
    80004c20:	0094ca83          	lbu	s5,9(s1)
    80004c24:	0104ba03          	ld	s4,16(s1)
    80004c28:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c2c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c30:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c34:	0012c517          	auipc	a0,0x12c
    80004c38:	25450513          	addi	a0,a0,596 # 80130e88 <ftable>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	106080e7          	jalr	262(ra) # 80000d42 <release>

  if(ff.type == FD_PIPE){
    80004c44:	4785                	li	a5,1
    80004c46:	04f90d63          	beq	s2,a5,80004ca0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c4a:	3979                	addiw	s2,s2,-2
    80004c4c:	4785                	li	a5,1
    80004c4e:	0527e063          	bltu	a5,s2,80004c8e <fileclose+0xa8>
    begin_op();
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	ad0080e7          	jalr	-1328(ra) # 80004722 <begin_op>
    iput(ff.ip);
    80004c5a:	854e                	mv	a0,s3
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	2da080e7          	jalr	730(ra) # 80003f36 <iput>
    end_op();
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	b38080e7          	jalr	-1224(ra) # 8000479c <end_op>
    80004c6c:	a00d                	j	80004c8e <fileclose+0xa8>
    panic("fileclose");
    80004c6e:	00004517          	auipc	a0,0x4
    80004c72:	c2a50513          	addi	a0,a0,-982 # 80008898 <syscalls+0x270>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	8c6080e7          	jalr	-1850(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004c7e:	0012c517          	auipc	a0,0x12c
    80004c82:	20a50513          	addi	a0,a0,522 # 80130e88 <ftable>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	0bc080e7          	jalr	188(ra) # 80000d42 <release>
  }
}
    80004c8e:	70e2                	ld	ra,56(sp)
    80004c90:	7442                	ld	s0,48(sp)
    80004c92:	74a2                	ld	s1,40(sp)
    80004c94:	7902                	ld	s2,32(sp)
    80004c96:	69e2                	ld	s3,24(sp)
    80004c98:	6a42                	ld	s4,16(sp)
    80004c9a:	6aa2                	ld	s5,8(sp)
    80004c9c:	6121                	addi	sp,sp,64
    80004c9e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ca0:	85d6                	mv	a1,s5
    80004ca2:	8552                	mv	a0,s4
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	348080e7          	jalr	840(ra) # 80004fec <pipeclose>
    80004cac:	b7cd                	j	80004c8e <fileclose+0xa8>

0000000080004cae <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004cae:	715d                	addi	sp,sp,-80
    80004cb0:	e486                	sd	ra,72(sp)
    80004cb2:	e0a2                	sd	s0,64(sp)
    80004cb4:	fc26                	sd	s1,56(sp)
    80004cb6:	f84a                	sd	s2,48(sp)
    80004cb8:	f44e                	sd	s3,40(sp)
    80004cba:	0880                	addi	s0,sp,80
    80004cbc:	84aa                	mv	s1,a0
    80004cbe:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	00a080e7          	jalr	10(ra) # 80001cca <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cc8:	409c                	lw	a5,0(s1)
    80004cca:	37f9                	addiw	a5,a5,-2
    80004ccc:	4705                	li	a4,1
    80004cce:	04f76763          	bltu	a4,a5,80004d1c <filestat+0x6e>
    80004cd2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cd4:	6c88                	ld	a0,24(s1)
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	0a6080e7          	jalr	166(ra) # 80003d7c <ilock>
    stati(f->ip, &st);
    80004cde:	fb840593          	addi	a1,s0,-72
    80004ce2:	6c88                	ld	a0,24(s1)
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	322080e7          	jalr	802(ra) # 80004006 <stati>
    iunlock(f->ip);
    80004cec:	6c88                	ld	a0,24(s1)
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	150080e7          	jalr	336(ra) # 80003e3e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cf6:	46e1                	li	a3,24
    80004cf8:	fb840613          	addi	a2,s0,-72
    80004cfc:	85ce                	mv	a1,s3
    80004cfe:	05093503          	ld	a0,80(s2)
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	aec080e7          	jalr	-1300(ra) # 800017ee <copyout>
    80004d0a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d0e:	60a6                	ld	ra,72(sp)
    80004d10:	6406                	ld	s0,64(sp)
    80004d12:	74e2                	ld	s1,56(sp)
    80004d14:	7942                	ld	s2,48(sp)
    80004d16:	79a2                	ld	s3,40(sp)
    80004d18:	6161                	addi	sp,sp,80
    80004d1a:	8082                	ret
  return -1;
    80004d1c:	557d                	li	a0,-1
    80004d1e:	bfc5                	j	80004d0e <filestat+0x60>

0000000080004d20 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d20:	7179                	addi	sp,sp,-48
    80004d22:	f406                	sd	ra,40(sp)
    80004d24:	f022                	sd	s0,32(sp)
    80004d26:	ec26                	sd	s1,24(sp)
    80004d28:	e84a                	sd	s2,16(sp)
    80004d2a:	e44e                	sd	s3,8(sp)
    80004d2c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d2e:	00854783          	lbu	a5,8(a0)
    80004d32:	c3d5                	beqz	a5,80004dd6 <fileread+0xb6>
    80004d34:	84aa                	mv	s1,a0
    80004d36:	89ae                	mv	s3,a1
    80004d38:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d3a:	411c                	lw	a5,0(a0)
    80004d3c:	4705                	li	a4,1
    80004d3e:	04e78963          	beq	a5,a4,80004d90 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d42:	470d                	li	a4,3
    80004d44:	04e78d63          	beq	a5,a4,80004d9e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d48:	4709                	li	a4,2
    80004d4a:	06e79e63          	bne	a5,a4,80004dc6 <fileread+0xa6>
    ilock(f->ip);
    80004d4e:	6d08                	ld	a0,24(a0)
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	02c080e7          	jalr	44(ra) # 80003d7c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d58:	874a                	mv	a4,s2
    80004d5a:	5094                	lw	a3,32(s1)
    80004d5c:	864e                	mv	a2,s3
    80004d5e:	4585                	li	a1,1
    80004d60:	6c88                	ld	a0,24(s1)
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	2ce080e7          	jalr	718(ra) # 80004030 <readi>
    80004d6a:	892a                	mv	s2,a0
    80004d6c:	00a05563          	blez	a0,80004d76 <fileread+0x56>
      f->off += r;
    80004d70:	509c                	lw	a5,32(s1)
    80004d72:	9fa9                	addw	a5,a5,a0
    80004d74:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d76:	6c88                	ld	a0,24(s1)
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	0c6080e7          	jalr	198(ra) # 80003e3e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d80:	854a                	mv	a0,s2
    80004d82:	70a2                	ld	ra,40(sp)
    80004d84:	7402                	ld	s0,32(sp)
    80004d86:	64e2                	ld	s1,24(sp)
    80004d88:	6942                	ld	s2,16(sp)
    80004d8a:	69a2                	ld	s3,8(sp)
    80004d8c:	6145                	addi	sp,sp,48
    80004d8e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d90:	6908                	ld	a0,16(a0)
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	3c2080e7          	jalr	962(ra) # 80005154 <piperead>
    80004d9a:	892a                	mv	s2,a0
    80004d9c:	b7d5                	j	80004d80 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d9e:	02451783          	lh	a5,36(a0)
    80004da2:	03079693          	slli	a3,a5,0x30
    80004da6:	92c1                	srli	a3,a3,0x30
    80004da8:	4725                	li	a4,9
    80004daa:	02d76863          	bltu	a4,a3,80004dda <fileread+0xba>
    80004dae:	0792                	slli	a5,a5,0x4
    80004db0:	0012c717          	auipc	a4,0x12c
    80004db4:	03870713          	addi	a4,a4,56 # 80130de8 <devsw>
    80004db8:	97ba                	add	a5,a5,a4
    80004dba:	639c                	ld	a5,0(a5)
    80004dbc:	c38d                	beqz	a5,80004dde <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004dbe:	4505                	li	a0,1
    80004dc0:	9782                	jalr	a5
    80004dc2:	892a                	mv	s2,a0
    80004dc4:	bf75                	j	80004d80 <fileread+0x60>
    panic("fileread");
    80004dc6:	00004517          	auipc	a0,0x4
    80004dca:	ae250513          	addi	a0,a0,-1310 # 800088a8 <syscalls+0x280>
    80004dce:	ffffb097          	auipc	ra,0xffffb
    80004dd2:	76e080e7          	jalr	1902(ra) # 8000053c <panic>
    return -1;
    80004dd6:	597d                	li	s2,-1
    80004dd8:	b765                	j	80004d80 <fileread+0x60>
      return -1;
    80004dda:	597d                	li	s2,-1
    80004ddc:	b755                	j	80004d80 <fileread+0x60>
    80004dde:	597d                	li	s2,-1
    80004de0:	b745                	j	80004d80 <fileread+0x60>

0000000080004de2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004de2:	00954783          	lbu	a5,9(a0)
    80004de6:	10078e63          	beqz	a5,80004f02 <filewrite+0x120>
{
    80004dea:	715d                	addi	sp,sp,-80
    80004dec:	e486                	sd	ra,72(sp)
    80004dee:	e0a2                	sd	s0,64(sp)
    80004df0:	fc26                	sd	s1,56(sp)
    80004df2:	f84a                	sd	s2,48(sp)
    80004df4:	f44e                	sd	s3,40(sp)
    80004df6:	f052                	sd	s4,32(sp)
    80004df8:	ec56                	sd	s5,24(sp)
    80004dfa:	e85a                	sd	s6,16(sp)
    80004dfc:	e45e                	sd	s7,8(sp)
    80004dfe:	e062                	sd	s8,0(sp)
    80004e00:	0880                	addi	s0,sp,80
    80004e02:	892a                	mv	s2,a0
    80004e04:	8b2e                	mv	s6,a1
    80004e06:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e08:	411c                	lw	a5,0(a0)
    80004e0a:	4705                	li	a4,1
    80004e0c:	02e78263          	beq	a5,a4,80004e30 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e10:	470d                	li	a4,3
    80004e12:	02e78563          	beq	a5,a4,80004e3c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e16:	4709                	li	a4,2
    80004e18:	0ce79d63          	bne	a5,a4,80004ef2 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e1c:	0ac05b63          	blez	a2,80004ed2 <filewrite+0xf0>
    int i = 0;
    80004e20:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e22:	6b85                	lui	s7,0x1
    80004e24:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e28:	6c05                	lui	s8,0x1
    80004e2a:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e2e:	a851                	j	80004ec2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e30:	6908                	ld	a0,16(a0)
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	22a080e7          	jalr	554(ra) # 8000505c <pipewrite>
    80004e3a:	a045                	j	80004eda <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e3c:	02451783          	lh	a5,36(a0)
    80004e40:	03079693          	slli	a3,a5,0x30
    80004e44:	92c1                	srli	a3,a3,0x30
    80004e46:	4725                	li	a4,9
    80004e48:	0ad76f63          	bltu	a4,a3,80004f06 <filewrite+0x124>
    80004e4c:	0792                	slli	a5,a5,0x4
    80004e4e:	0012c717          	auipc	a4,0x12c
    80004e52:	f9a70713          	addi	a4,a4,-102 # 80130de8 <devsw>
    80004e56:	97ba                	add	a5,a5,a4
    80004e58:	679c                	ld	a5,8(a5)
    80004e5a:	cbc5                	beqz	a5,80004f0a <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e5c:	4505                	li	a0,1
    80004e5e:	9782                	jalr	a5
    80004e60:	a8ad                	j	80004eda <filewrite+0xf8>
      if(n1 > max)
    80004e62:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e66:	00000097          	auipc	ra,0x0
    80004e6a:	8bc080e7          	jalr	-1860(ra) # 80004722 <begin_op>
      ilock(f->ip);
    80004e6e:	01893503          	ld	a0,24(s2)
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	f0a080e7          	jalr	-246(ra) # 80003d7c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e7a:	8756                	mv	a4,s5
    80004e7c:	02092683          	lw	a3,32(s2)
    80004e80:	01698633          	add	a2,s3,s6
    80004e84:	4585                	li	a1,1
    80004e86:	01893503          	ld	a0,24(s2)
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	29e080e7          	jalr	670(ra) # 80004128 <writei>
    80004e92:	84aa                	mv	s1,a0
    80004e94:	00a05763          	blez	a0,80004ea2 <filewrite+0xc0>
        f->off += r;
    80004e98:	02092783          	lw	a5,32(s2)
    80004e9c:	9fa9                	addw	a5,a5,a0
    80004e9e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ea2:	01893503          	ld	a0,24(s2)
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	f98080e7          	jalr	-104(ra) # 80003e3e <iunlock>
      end_op();
    80004eae:	00000097          	auipc	ra,0x0
    80004eb2:	8ee080e7          	jalr	-1810(ra) # 8000479c <end_op>

      if(r != n1){
    80004eb6:	009a9f63          	bne	s5,s1,80004ed4 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004eba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ebe:	0149db63          	bge	s3,s4,80004ed4 <filewrite+0xf2>
      int n1 = n - i;
    80004ec2:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004ec6:	0004879b          	sext.w	a5,s1
    80004eca:	f8fbdce3          	bge	s7,a5,80004e62 <filewrite+0x80>
    80004ece:	84e2                	mv	s1,s8
    80004ed0:	bf49                	j	80004e62 <filewrite+0x80>
    int i = 0;
    80004ed2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ed4:	033a1d63          	bne	s4,s3,80004f0e <filewrite+0x12c>
    80004ed8:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004eda:	60a6                	ld	ra,72(sp)
    80004edc:	6406                	ld	s0,64(sp)
    80004ede:	74e2                	ld	s1,56(sp)
    80004ee0:	7942                	ld	s2,48(sp)
    80004ee2:	79a2                	ld	s3,40(sp)
    80004ee4:	7a02                	ld	s4,32(sp)
    80004ee6:	6ae2                	ld	s5,24(sp)
    80004ee8:	6b42                	ld	s6,16(sp)
    80004eea:	6ba2                	ld	s7,8(sp)
    80004eec:	6c02                	ld	s8,0(sp)
    80004eee:	6161                	addi	sp,sp,80
    80004ef0:	8082                	ret
    panic("filewrite");
    80004ef2:	00004517          	auipc	a0,0x4
    80004ef6:	9c650513          	addi	a0,a0,-1594 # 800088b8 <syscalls+0x290>
    80004efa:	ffffb097          	auipc	ra,0xffffb
    80004efe:	642080e7          	jalr	1602(ra) # 8000053c <panic>
    return -1;
    80004f02:	557d                	li	a0,-1
}
    80004f04:	8082                	ret
      return -1;
    80004f06:	557d                	li	a0,-1
    80004f08:	bfc9                	j	80004eda <filewrite+0xf8>
    80004f0a:	557d                	li	a0,-1
    80004f0c:	b7f9                	j	80004eda <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004f0e:	557d                	li	a0,-1
    80004f10:	b7e9                	j	80004eda <filewrite+0xf8>

0000000080004f12 <pipealloc>:
    int readopen;  // read fd is still open
    int writeopen; // write fd is still open
};

int pipealloc(struct file **f0, struct file **f1)
{
    80004f12:	7179                	addi	sp,sp,-48
    80004f14:	f406                	sd	ra,40(sp)
    80004f16:	f022                	sd	s0,32(sp)
    80004f18:	ec26                	sd	s1,24(sp)
    80004f1a:	e84a                	sd	s2,16(sp)
    80004f1c:	e44e                	sd	s3,8(sp)
    80004f1e:	e052                	sd	s4,0(sp)
    80004f20:	1800                	addi	s0,sp,48
    80004f22:	84aa                	mv	s1,a0
    80004f24:	8a2e                	mv	s4,a1
    struct pipe *pi;

    pi = 0;
    *f0 = *f1 = 0;
    80004f26:	0005b023          	sd	zero,0(a1)
    80004f2a:	00053023          	sd	zero,0(a0)
    if ((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f2e:	00000097          	auipc	ra,0x0
    80004f32:	bfc080e7          	jalr	-1028(ra) # 80004b2a <filealloc>
    80004f36:	e088                	sd	a0,0(s1)
    80004f38:	c551                	beqz	a0,80004fc4 <pipealloc+0xb2>
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	bf0080e7          	jalr	-1040(ra) # 80004b2a <filealloc>
    80004f42:	00aa3023          	sd	a0,0(s4)
    80004f46:	c92d                	beqz	a0,80004fb8 <pipealloc+0xa6>
        goto bad;
    if ((pi = (struct pipe *)kalloc()) == 0)
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	c00080e7          	jalr	-1024(ra) # 80000b48 <kalloc>
    80004f50:	892a                	mv	s2,a0
    80004f52:	c125                	beqz	a0,80004fb2 <pipealloc+0xa0>
        goto bad;
    pi->readopen = 1;
    80004f54:	4985                	li	s3,1
    80004f56:	23352023          	sw	s3,544(a0)
    pi->writeopen = 1;
    80004f5a:	23352223          	sw	s3,548(a0)
    pi->nwrite = 0;
    80004f5e:	20052e23          	sw	zero,540(a0)
    pi->nread = 0;
    80004f62:	20052c23          	sw	zero,536(a0)
    initlock(&pi->lock, "pipe");
    80004f66:	00004597          	auipc	a1,0x4
    80004f6a:	96258593          	addi	a1,a1,-1694 # 800088c8 <syscalls+0x2a0>
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	c90080e7          	jalr	-880(ra) # 80000bfe <initlock>
    (*f0)->type = FD_PIPE;
    80004f76:	609c                	ld	a5,0(s1)
    80004f78:	0137a023          	sw	s3,0(a5)
    (*f0)->readable = 1;
    80004f7c:	609c                	ld	a5,0(s1)
    80004f7e:	01378423          	sb	s3,8(a5)
    (*f0)->writable = 0;
    80004f82:	609c                	ld	a5,0(s1)
    80004f84:	000784a3          	sb	zero,9(a5)
    (*f0)->pipe = pi;
    80004f88:	609c                	ld	a5,0(s1)
    80004f8a:	0127b823          	sd	s2,16(a5)
    (*f1)->type = FD_PIPE;
    80004f8e:	000a3783          	ld	a5,0(s4)
    80004f92:	0137a023          	sw	s3,0(a5)
    (*f1)->readable = 0;
    80004f96:	000a3783          	ld	a5,0(s4)
    80004f9a:	00078423          	sb	zero,8(a5)
    (*f1)->writable = 1;
    80004f9e:	000a3783          	ld	a5,0(s4)
    80004fa2:	013784a3          	sb	s3,9(a5)
    (*f1)->pipe = pi;
    80004fa6:	000a3783          	ld	a5,0(s4)
    80004faa:	0127b823          	sd	s2,16(a5)
    return 0;
    80004fae:	4501                	li	a0,0
    80004fb0:	a025                	j	80004fd8 <pipealloc+0xc6>

bad:
    if (pi)
        dec_ref((char *)pi);
    if (*f0)
    80004fb2:	6088                	ld	a0,0(s1)
    80004fb4:	e501                	bnez	a0,80004fbc <pipealloc+0xaa>
    80004fb6:	a039                	j	80004fc4 <pipealloc+0xb2>
    80004fb8:	6088                	ld	a0,0(s1)
    80004fba:	c51d                	beqz	a0,80004fe8 <pipealloc+0xd6>
        fileclose(*f0);
    80004fbc:	00000097          	auipc	ra,0x0
    80004fc0:	c2a080e7          	jalr	-982(ra) # 80004be6 <fileclose>
    if (*f1)
    80004fc4:	000a3783          	ld	a5,0(s4)
        fileclose(*f1);
    return -1;
    80004fc8:	557d                	li	a0,-1
    if (*f1)
    80004fca:	c799                	beqz	a5,80004fd8 <pipealloc+0xc6>
        fileclose(*f1);
    80004fcc:	853e                	mv	a0,a5
    80004fce:	00000097          	auipc	ra,0x0
    80004fd2:	c18080e7          	jalr	-1000(ra) # 80004be6 <fileclose>
    return -1;
    80004fd6:	557d                	li	a0,-1
}
    80004fd8:	70a2                	ld	ra,40(sp)
    80004fda:	7402                	ld	s0,32(sp)
    80004fdc:	64e2                	ld	s1,24(sp)
    80004fde:	6942                	ld	s2,16(sp)
    80004fe0:	69a2                	ld	s3,8(sp)
    80004fe2:	6a02                	ld	s4,0(sp)
    80004fe4:	6145                	addi	sp,sp,48
    80004fe6:	8082                	ret
    return -1;
    80004fe8:	557d                	li	a0,-1
    80004fea:	b7fd                	j	80004fd8 <pipealloc+0xc6>

0000000080004fec <pipeclose>:

void pipeclose(struct pipe *pi, int writable)
{
    80004fec:	1101                	addi	sp,sp,-32
    80004fee:	ec06                	sd	ra,24(sp)
    80004ff0:	e822                	sd	s0,16(sp)
    80004ff2:	e426                	sd	s1,8(sp)
    80004ff4:	e04a                	sd	s2,0(sp)
    80004ff6:	1000                	addi	s0,sp,32
    80004ff8:	84aa                	mv	s1,a0
    80004ffa:	892e                	mv	s2,a1
    acquire(&pi->lock);
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	c92080e7          	jalr	-878(ra) # 80000c8e <acquire>
    if (writable)
    80005004:	02090d63          	beqz	s2,8000503e <pipeclose+0x52>
    {
        pi->writeopen = 0;
    80005008:	2204a223          	sw	zero,548(s1)
        wakeup(&pi->nread);
    8000500c:	21848513          	addi	a0,s1,536
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	486080e7          	jalr	1158(ra) # 80002496 <wakeup>
    else
    {
        pi->readopen = 0;
        wakeup(&pi->nwrite);
    }
    if (pi->readopen == 0 && pi->writeopen == 0)
    80005018:	2204b783          	ld	a5,544(s1)
    8000501c:	eb95                	bnez	a5,80005050 <pipeclose+0x64>
    {
        release(&pi->lock);
    8000501e:	8526                	mv	a0,s1
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	d22080e7          	jalr	-734(ra) # 80000d42 <release>
        dec_ref((char *)pi);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	3d6080e7          	jalr	982(ra) # 80001400 <dec_ref>
    }
    else
        release(&pi->lock);
}
    80005032:	60e2                	ld	ra,24(sp)
    80005034:	6442                	ld	s0,16(sp)
    80005036:	64a2                	ld	s1,8(sp)
    80005038:	6902                	ld	s2,0(sp)
    8000503a:	6105                	addi	sp,sp,32
    8000503c:	8082                	ret
        pi->readopen = 0;
    8000503e:	2204a023          	sw	zero,544(s1)
        wakeup(&pi->nwrite);
    80005042:	21c48513          	addi	a0,s1,540
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	450080e7          	jalr	1104(ra) # 80002496 <wakeup>
    8000504e:	b7e9                	j	80005018 <pipeclose+0x2c>
        release(&pi->lock);
    80005050:	8526                	mv	a0,s1
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	cf0080e7          	jalr	-784(ra) # 80000d42 <release>
}
    8000505a:	bfe1                	j	80005032 <pipeclose+0x46>

000000008000505c <pipewrite>:

int pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000505c:	711d                	addi	sp,sp,-96
    8000505e:	ec86                	sd	ra,88(sp)
    80005060:	e8a2                	sd	s0,80(sp)
    80005062:	e4a6                	sd	s1,72(sp)
    80005064:	e0ca                	sd	s2,64(sp)
    80005066:	fc4e                	sd	s3,56(sp)
    80005068:	f852                	sd	s4,48(sp)
    8000506a:	f456                	sd	s5,40(sp)
    8000506c:	f05a                	sd	s6,32(sp)
    8000506e:	ec5e                	sd	s7,24(sp)
    80005070:	e862                	sd	s8,16(sp)
    80005072:	1080                	addi	s0,sp,96
    80005074:	84aa                	mv	s1,a0
    80005076:	8aae                	mv	s5,a1
    80005078:	8a32                	mv	s4,a2
    int i = 0;
    struct proc *pr = myproc();
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	c50080e7          	jalr	-944(ra) # 80001cca <myproc>
    80005082:	89aa                	mv	s3,a0

    acquire(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c08080e7          	jalr	-1016(ra) # 80000c8e <acquire>
    while (i < n)
    8000508e:	0b405663          	blez	s4,8000513a <pipewrite+0xde>
    int i = 0;
    80005092:	4901                	li	s2,0
            sleep(&pi->nwrite, &pi->lock);
        }
        else
        {
            char ch;
            if (copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005094:	5b7d                	li	s6,-1
            wakeup(&pi->nread);
    80005096:	21848c13          	addi	s8,s1,536
            sleep(&pi->nwrite, &pi->lock);
    8000509a:	21c48b93          	addi	s7,s1,540
    8000509e:	a089                	j	800050e0 <pipewrite+0x84>
            release(&pi->lock);
    800050a0:	8526                	mv	a0,s1
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	ca0080e7          	jalr	-864(ra) # 80000d42 <release>
            return -1;
    800050aa:	597d                	li	s2,-1
    }
    wakeup(&pi->nread);
    release(&pi->lock);

    return i;
}
    800050ac:	854a                	mv	a0,s2
    800050ae:	60e6                	ld	ra,88(sp)
    800050b0:	6446                	ld	s0,80(sp)
    800050b2:	64a6                	ld	s1,72(sp)
    800050b4:	6906                	ld	s2,64(sp)
    800050b6:	79e2                	ld	s3,56(sp)
    800050b8:	7a42                	ld	s4,48(sp)
    800050ba:	7aa2                	ld	s5,40(sp)
    800050bc:	7b02                	ld	s6,32(sp)
    800050be:	6be2                	ld	s7,24(sp)
    800050c0:	6c42                	ld	s8,16(sp)
    800050c2:	6125                	addi	sp,sp,96
    800050c4:	8082                	ret
            wakeup(&pi->nread);
    800050c6:	8562                	mv	a0,s8
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	3ce080e7          	jalr	974(ra) # 80002496 <wakeup>
            sleep(&pi->nwrite, &pi->lock);
    800050d0:	85a6                	mv	a1,s1
    800050d2:	855e                	mv	a0,s7
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	35e080e7          	jalr	862(ra) # 80002432 <sleep>
    while (i < n)
    800050dc:	07495063          	bge	s2,s4,8000513c <pipewrite+0xe0>
        if (pi->readopen == 0 || killed(pr))
    800050e0:	2204a783          	lw	a5,544(s1)
    800050e4:	dfd5                	beqz	a5,800050a0 <pipewrite+0x44>
    800050e6:	854e                	mv	a0,s3
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	5f2080e7          	jalr	1522(ra) # 800026da <killed>
    800050f0:	f945                	bnez	a0,800050a0 <pipewrite+0x44>
        if (pi->nwrite == pi->nread + PIPESIZE)
    800050f2:	2184a783          	lw	a5,536(s1)
    800050f6:	21c4a703          	lw	a4,540(s1)
    800050fa:	2007879b          	addiw	a5,a5,512
    800050fe:	fcf704e3          	beq	a4,a5,800050c6 <pipewrite+0x6a>
            if (copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005102:	4685                	li	a3,1
    80005104:	01590633          	add	a2,s2,s5
    80005108:	faf40593          	addi	a1,s0,-81
    8000510c:	0509b503          	ld	a0,80(s3)
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	80e080e7          	jalr	-2034(ra) # 8000191e <copyin>
    80005118:	03650263          	beq	a0,s6,8000513c <pipewrite+0xe0>
            pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000511c:	21c4a783          	lw	a5,540(s1)
    80005120:	0017871b          	addiw	a4,a5,1
    80005124:	20e4ae23          	sw	a4,540(s1)
    80005128:	1ff7f793          	andi	a5,a5,511
    8000512c:	97a6                	add	a5,a5,s1
    8000512e:	faf44703          	lbu	a4,-81(s0)
    80005132:	00e78c23          	sb	a4,24(a5)
            i++;
    80005136:	2905                	addiw	s2,s2,1
    80005138:	b755                	j	800050dc <pipewrite+0x80>
    int i = 0;
    8000513a:	4901                	li	s2,0
    wakeup(&pi->nread);
    8000513c:	21848513          	addi	a0,s1,536
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	356080e7          	jalr	854(ra) # 80002496 <wakeup>
    release(&pi->lock);
    80005148:	8526                	mv	a0,s1
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	bf8080e7          	jalr	-1032(ra) # 80000d42 <release>
    return i;
    80005152:	bfa9                	j	800050ac <pipewrite+0x50>

0000000080005154 <piperead>:

int piperead(struct pipe *pi, uint64 addr, int n)
{
    80005154:	715d                	addi	sp,sp,-80
    80005156:	e486                	sd	ra,72(sp)
    80005158:	e0a2                	sd	s0,64(sp)
    8000515a:	fc26                	sd	s1,56(sp)
    8000515c:	f84a                	sd	s2,48(sp)
    8000515e:	f44e                	sd	s3,40(sp)
    80005160:	f052                	sd	s4,32(sp)
    80005162:	ec56                	sd	s5,24(sp)
    80005164:	e85a                	sd	s6,16(sp)
    80005166:	0880                	addi	s0,sp,80
    80005168:	84aa                	mv	s1,a0
    8000516a:	892e                	mv	s2,a1
    8000516c:	8ab2                	mv	s5,a2
    int i;
    struct proc *pr = myproc();
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	b5c080e7          	jalr	-1188(ra) # 80001cca <myproc>
    80005176:	8a2a                	mv	s4,a0
    char ch;

    acquire(&pi->lock);
    80005178:	8526                	mv	a0,s1
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	b14080e7          	jalr	-1260(ra) # 80000c8e <acquire>
    while (pi->nread == pi->nwrite && pi->writeopen)
    80005182:	2184a703          	lw	a4,536(s1)
    80005186:	21c4a783          	lw	a5,540(s1)
        if (killed(pr))
        {
            release(&pi->lock);
            return -1;
        }
        sleep(&pi->nread, &pi->lock); // DOC: piperead-sleep
    8000518a:	21848993          	addi	s3,s1,536
    while (pi->nread == pi->nwrite && pi->writeopen)
    8000518e:	02f71763          	bne	a4,a5,800051bc <piperead+0x68>
    80005192:	2244a783          	lw	a5,548(s1)
    80005196:	c39d                	beqz	a5,800051bc <piperead+0x68>
        if (killed(pr))
    80005198:	8552                	mv	a0,s4
    8000519a:	ffffd097          	auipc	ra,0xffffd
    8000519e:	540080e7          	jalr	1344(ra) # 800026da <killed>
    800051a2:	e949                	bnez	a0,80005234 <piperead+0xe0>
        sleep(&pi->nread, &pi->lock); // DOC: piperead-sleep
    800051a4:	85a6                	mv	a1,s1
    800051a6:	854e                	mv	a0,s3
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	28a080e7          	jalr	650(ra) # 80002432 <sleep>
    while (pi->nread == pi->nwrite && pi->writeopen)
    800051b0:	2184a703          	lw	a4,536(s1)
    800051b4:	21c4a783          	lw	a5,540(s1)
    800051b8:	fcf70de3          	beq	a4,a5,80005192 <piperead+0x3e>
    }
    for (i = 0; i < n; i++)
    800051bc:	4981                	li	s3,0
    { // DOC: piperead-copy
        if (pi->nread == pi->nwrite)
            break;
        ch = pi->data[pi->nread++ % PIPESIZE];
        if (copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051be:	5b7d                	li	s6,-1
    for (i = 0; i < n; i++)
    800051c0:	05505463          	blez	s5,80005208 <piperead+0xb4>
        if (pi->nread == pi->nwrite)
    800051c4:	2184a783          	lw	a5,536(s1)
    800051c8:	21c4a703          	lw	a4,540(s1)
    800051cc:	02f70e63          	beq	a4,a5,80005208 <piperead+0xb4>
        ch = pi->data[pi->nread++ % PIPESIZE];
    800051d0:	0017871b          	addiw	a4,a5,1
    800051d4:	20e4ac23          	sw	a4,536(s1)
    800051d8:	1ff7f793          	andi	a5,a5,511
    800051dc:	97a6                	add	a5,a5,s1
    800051de:	0187c783          	lbu	a5,24(a5)
    800051e2:	faf40fa3          	sb	a5,-65(s0)
        if (copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051e6:	4685                	li	a3,1
    800051e8:	fbf40613          	addi	a2,s0,-65
    800051ec:	85ca                	mv	a1,s2
    800051ee:	050a3503          	ld	a0,80(s4)
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	5fc080e7          	jalr	1532(ra) # 800017ee <copyout>
    800051fa:	01650763          	beq	a0,s6,80005208 <piperead+0xb4>
    for (i = 0; i < n; i++)
    800051fe:	2985                	addiw	s3,s3,1
    80005200:	0905                	addi	s2,s2,1
    80005202:	fd3a91e3          	bne	s5,s3,800051c4 <piperead+0x70>
    80005206:	89d6                	mv	s3,s5
            break;
    }
    wakeup(&pi->nwrite); // DOC: piperead-wakeup
    80005208:	21c48513          	addi	a0,s1,540
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	28a080e7          	jalr	650(ra) # 80002496 <wakeup>
    release(&pi->lock);
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	b2c080e7          	jalr	-1236(ra) # 80000d42 <release>
    return i;
}
    8000521e:	854e                	mv	a0,s3
    80005220:	60a6                	ld	ra,72(sp)
    80005222:	6406                	ld	s0,64(sp)
    80005224:	74e2                	ld	s1,56(sp)
    80005226:	7942                	ld	s2,48(sp)
    80005228:	79a2                	ld	s3,40(sp)
    8000522a:	7a02                	ld	s4,32(sp)
    8000522c:	6ae2                	ld	s5,24(sp)
    8000522e:	6b42                	ld	s6,16(sp)
    80005230:	6161                	addi	sp,sp,80
    80005232:	8082                	ret
            release(&pi->lock);
    80005234:	8526                	mv	a0,s1
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	b0c080e7          	jalr	-1268(ra) # 80000d42 <release>
            return -1;
    8000523e:	59fd                	li	s3,-1
    80005240:	bff9                	j	8000521e <piperead+0xca>

0000000080005242 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005242:	1141                	addi	sp,sp,-16
    80005244:	e422                	sd	s0,8(sp)
    80005246:	0800                	addi	s0,sp,16
    80005248:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000524a:	8905                	andi	a0,a0,1
    8000524c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000524e:	8b89                	andi	a5,a5,2
    80005250:	c399                	beqz	a5,80005256 <flags2perm+0x14>
      perm |= PTE_W;
    80005252:	00456513          	ori	a0,a0,4
    return perm;
}
    80005256:	6422                	ld	s0,8(sp)
    80005258:	0141                	addi	sp,sp,16
    8000525a:	8082                	ret

000000008000525c <exec>:

int
exec(char *path, char **argv)
{
    8000525c:	df010113          	addi	sp,sp,-528
    80005260:	20113423          	sd	ra,520(sp)
    80005264:	20813023          	sd	s0,512(sp)
    80005268:	ffa6                	sd	s1,504(sp)
    8000526a:	fbca                	sd	s2,496(sp)
    8000526c:	f7ce                	sd	s3,488(sp)
    8000526e:	f3d2                	sd	s4,480(sp)
    80005270:	efd6                	sd	s5,472(sp)
    80005272:	ebda                	sd	s6,464(sp)
    80005274:	e7de                	sd	s7,456(sp)
    80005276:	e3e2                	sd	s8,448(sp)
    80005278:	ff66                	sd	s9,440(sp)
    8000527a:	fb6a                	sd	s10,432(sp)
    8000527c:	f76e                	sd	s11,424(sp)
    8000527e:	0c00                	addi	s0,sp,528
    80005280:	892a                	mv	s2,a0
    80005282:	dea43c23          	sd	a0,-520(s0)
    80005286:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000528a:	ffffd097          	auipc	ra,0xffffd
    8000528e:	a40080e7          	jalr	-1472(ra) # 80001cca <myproc>
    80005292:	84aa                	mv	s1,a0

  begin_op();
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	48e080e7          	jalr	1166(ra) # 80004722 <begin_op>

  if((ip = namei(path)) == 0){
    8000529c:	854a                	mv	a0,s2
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	284080e7          	jalr	644(ra) # 80004522 <namei>
    800052a6:	c92d                	beqz	a0,80005318 <exec+0xbc>
    800052a8:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	ad2080e7          	jalr	-1326(ra) # 80003d7c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052b2:	04000713          	li	a4,64
    800052b6:	4681                	li	a3,0
    800052b8:	e5040613          	addi	a2,s0,-432
    800052bc:	4581                	li	a1,0
    800052be:	8552                	mv	a0,s4
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	d70080e7          	jalr	-656(ra) # 80004030 <readi>
    800052c8:	04000793          	li	a5,64
    800052cc:	00f51a63          	bne	a0,a5,800052e0 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052d0:	e5042703          	lw	a4,-432(s0)
    800052d4:	464c47b7          	lui	a5,0x464c4
    800052d8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052dc:	04f70463          	beq	a4,a5,80005324 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052e0:	8552                	mv	a0,s4
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	cfc080e7          	jalr	-772(ra) # 80003fde <iunlockput>
    end_op();
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	4b2080e7          	jalr	1202(ra) # 8000479c <end_op>
  }
  return -1;
    800052f2:	557d                	li	a0,-1
}
    800052f4:	20813083          	ld	ra,520(sp)
    800052f8:	20013403          	ld	s0,512(sp)
    800052fc:	74fe                	ld	s1,504(sp)
    800052fe:	795e                	ld	s2,496(sp)
    80005300:	79be                	ld	s3,488(sp)
    80005302:	7a1e                	ld	s4,480(sp)
    80005304:	6afe                	ld	s5,472(sp)
    80005306:	6b5e                	ld	s6,464(sp)
    80005308:	6bbe                	ld	s7,456(sp)
    8000530a:	6c1e                	ld	s8,448(sp)
    8000530c:	7cfa                	ld	s9,440(sp)
    8000530e:	7d5a                	ld	s10,432(sp)
    80005310:	7dba                	ld	s11,424(sp)
    80005312:	21010113          	addi	sp,sp,528
    80005316:	8082                	ret
    end_op();
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	484080e7          	jalr	1156(ra) # 8000479c <end_op>
    return -1;
    80005320:	557d                	li	a0,-1
    80005322:	bfc9                	j	800052f4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005324:	8526                	mv	a0,s1
    80005326:	ffffd097          	auipc	ra,0xffffd
    8000532a:	a68080e7          	jalr	-1432(ra) # 80001d8e <proc_pagetable>
    8000532e:	8b2a                	mv	s6,a0
    80005330:	d945                	beqz	a0,800052e0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005332:	e7042d03          	lw	s10,-400(s0)
    80005336:	e8845783          	lhu	a5,-376(s0)
    8000533a:	10078563          	beqz	a5,80005444 <exec+0x1e8>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000533e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005340:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005342:	6c85                	lui	s9,0x1
    80005344:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005348:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000534c:	6a85                	lui	s5,0x1
    8000534e:	a0bd                	j	800053bc <exec+0x160>
      panic("loadseg: address should exist");
    80005350:	00003517          	auipc	a0,0x3
    80005354:	58050513          	addi	a0,a0,1408 # 800088d0 <syscalls+0x2a8>
    80005358:	ffffb097          	auipc	ra,0xffffb
    8000535c:	1e4080e7          	jalr	484(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005360:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005362:	8726                	mv	a4,s1
    80005364:	012c06bb          	addw	a3,s8,s2
    80005368:	4581                	li	a1,0
    8000536a:	8552                	mv	a0,s4
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	cc4080e7          	jalr	-828(ra) # 80004030 <readi>
    80005374:	2501                	sext.w	a0,a0
    80005376:	24a49963          	bne	s1,a0,800055c8 <exec+0x36c>
  for(i = 0; i < sz; i += PGSIZE){
    8000537a:	012a893b          	addw	s2,s5,s2
    8000537e:	03397663          	bgeu	s2,s3,800053aa <exec+0x14e>
    pa = walkaddr(pagetable, va + i);
    80005382:	02091593          	slli	a1,s2,0x20
    80005386:	9181                	srli	a1,a1,0x20
    80005388:	4601                	li	a2,0
    8000538a:	95de                	add	a1,a1,s7
    8000538c:	855a                	mv	a0,s6
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	d84080e7          	jalr	-636(ra) # 80001112 <walkaddrf>
    80005396:	862a                	mv	a2,a0
    if(pa == 0)
    80005398:	dd45                	beqz	a0,80005350 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000539a:	412984bb          	subw	s1,s3,s2
    8000539e:	0004879b          	sext.w	a5,s1
    800053a2:	fafcffe3          	bgeu	s9,a5,80005360 <exec+0x104>
    800053a6:	84d6                	mv	s1,s5
    800053a8:	bf65                	j	80005360 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053aa:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ae:	2d85                	addiw	s11,s11,1
    800053b0:	038d0d1b          	addiw	s10,s10,56 # fffffffffffff038 <end+0xffffffff7fecd0b8>
    800053b4:	e8845783          	lhu	a5,-376(s0)
    800053b8:	08fdd763          	bge	s11,a5,80005446 <exec+0x1ea>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053bc:	2d01                	sext.w	s10,s10
    800053be:	03800713          	li	a4,56
    800053c2:	86ea                	mv	a3,s10
    800053c4:	e1840613          	addi	a2,s0,-488
    800053c8:	4581                	li	a1,0
    800053ca:	8552                	mv	a0,s4
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	c64080e7          	jalr	-924(ra) # 80004030 <readi>
    800053d4:	03800793          	li	a5,56
    800053d8:	1ef51663          	bne	a0,a5,800055c4 <exec+0x368>
    if(ph.type != ELF_PROG_LOAD)
    800053dc:	e1842783          	lw	a5,-488(s0)
    800053e0:	4705                	li	a4,1
    800053e2:	fce796e3          	bne	a5,a4,800053ae <exec+0x152>
    if(ph.memsz < ph.filesz)
    800053e6:	e4043483          	ld	s1,-448(s0)
    800053ea:	e3843783          	ld	a5,-456(s0)
    800053ee:	1ef4e863          	bltu	s1,a5,800055de <exec+0x382>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053f2:	e2843783          	ld	a5,-472(s0)
    800053f6:	94be                	add	s1,s1,a5
    800053f8:	1ef4e663          	bltu	s1,a5,800055e4 <exec+0x388>
    if(ph.vaddr % PGSIZE != 0)
    800053fc:	df043703          	ld	a4,-528(s0)
    80005400:	8ff9                	and	a5,a5,a4
    80005402:	1e079463          	bnez	a5,800055ea <exec+0x38e>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005406:	e1c42503          	lw	a0,-484(s0)
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	e38080e7          	jalr	-456(ra) # 80005242 <flags2perm>
    80005412:	86aa                	mv	a3,a0
    80005414:	8626                	mv	a2,s1
    80005416:	85ca                	mv	a1,s2
    80005418:	855a                	mv	a0,s6
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	16e080e7          	jalr	366(ra) # 80001588 <uvmalloc>
    80005422:	e0a43423          	sd	a0,-504(s0)
    80005426:	1c050563          	beqz	a0,800055f0 <exec+0x394>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000542a:	e2843b83          	ld	s7,-472(s0)
    8000542e:	e2042c03          	lw	s8,-480(s0)
    80005432:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005436:	00098463          	beqz	s3,8000543e <exec+0x1e2>
    8000543a:	4901                	li	s2,0
    8000543c:	b799                	j	80005382 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000543e:	e0843903          	ld	s2,-504(s0)
    80005442:	b7b5                	j	800053ae <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005444:	4901                	li	s2,0
  iunlockput(ip);
    80005446:	8552                	mv	a0,s4
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	b96080e7          	jalr	-1130(ra) # 80003fde <iunlockput>
  end_op();
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	34c080e7          	jalr	844(ra) # 8000479c <end_op>
  p = myproc();
    80005458:	ffffd097          	auipc	ra,0xffffd
    8000545c:	872080e7          	jalr	-1934(ra) # 80001cca <myproc>
    80005460:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005462:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005466:	6985                	lui	s3,0x1
    80005468:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000546a:	99ca                	add	s3,s3,s2
    8000546c:	77fd                	lui	a5,0xfffff
    8000546e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005472:	4691                	li	a3,4
    80005474:	6609                	lui	a2,0x2
    80005476:	964e                	add	a2,a2,s3
    80005478:	85ce                	mv	a1,s3
    8000547a:	855a                	mv	a0,s6
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	10c080e7          	jalr	268(ra) # 80001588 <uvmalloc>
    80005484:	892a                	mv	s2,a0
    80005486:	e0a43423          	sd	a0,-504(s0)
    8000548a:	e509                	bnez	a0,80005494 <exec+0x238>
  if(pagetable)
    8000548c:	e1343423          	sd	s3,-504(s0)
    80005490:	4a01                	li	s4,0
    80005492:	aa1d                	j	800055c8 <exec+0x36c>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005494:	75f9                	lui	a1,0xffffe
    80005496:	95aa                	add	a1,a1,a0
    80005498:	855a                	mv	a0,s6
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	322080e7          	jalr	802(ra) # 800017bc <uvmclear>
  stackbase = sp - PGSIZE;
    800054a2:	7bfd                	lui	s7,0xfffff
    800054a4:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800054a6:	e0043783          	ld	a5,-512(s0)
    800054aa:	6388                	ld	a0,0(a5)
    800054ac:	c52d                	beqz	a0,80005516 <exec+0x2ba>
    800054ae:	e9040993          	addi	s3,s0,-368
    800054b2:	f9040c13          	addi	s8,s0,-112
    800054b6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054b8:	ffffc097          	auipc	ra,0xffffc
    800054bc:	a4c080e7          	jalr	-1460(ra) # 80000f04 <strlen>
    800054c0:	0015079b          	addiw	a5,a0,1
    800054c4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054c8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054cc:	13796563          	bltu	s2,s7,800055f6 <exec+0x39a>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054d0:	e0043d03          	ld	s10,-512(s0)
    800054d4:	000d3a03          	ld	s4,0(s10)
    800054d8:	8552                	mv	a0,s4
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	a2a080e7          	jalr	-1494(ra) # 80000f04 <strlen>
    800054e2:	0015069b          	addiw	a3,a0,1
    800054e6:	8652                	mv	a2,s4
    800054e8:	85ca                	mv	a1,s2
    800054ea:	855a                	mv	a0,s6
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	302080e7          	jalr	770(ra) # 800017ee <copyout>
    800054f4:	10054363          	bltz	a0,800055fa <exec+0x39e>
    ustack[argc] = sp;
    800054f8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054fc:	0485                	addi	s1,s1,1
    800054fe:	008d0793          	addi	a5,s10,8
    80005502:	e0f43023          	sd	a5,-512(s0)
    80005506:	008d3503          	ld	a0,8(s10)
    8000550a:	c909                	beqz	a0,8000551c <exec+0x2c0>
    if(argc >= MAXARG)
    8000550c:	09a1                	addi	s3,s3,8
    8000550e:	fb8995e3          	bne	s3,s8,800054b8 <exec+0x25c>
  ip = 0;
    80005512:	4a01                	li	s4,0
    80005514:	a855                	j	800055c8 <exec+0x36c>
  sp = sz;
    80005516:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000551a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000551c:	00349793          	slli	a5,s1,0x3
    80005520:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fecd010>
    80005524:	97a2                	add	a5,a5,s0
    80005526:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000552a:	00148693          	addi	a3,s1,1
    8000552e:	068e                	slli	a3,a3,0x3
    80005530:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005534:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005538:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000553c:	f57968e3          	bltu	s2,s7,8000548c <exec+0x230>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005540:	e9040613          	addi	a2,s0,-368
    80005544:	85ca                	mv	a1,s2
    80005546:	855a                	mv	a0,s6
    80005548:	ffffc097          	auipc	ra,0xffffc
    8000554c:	2a6080e7          	jalr	678(ra) # 800017ee <copyout>
    80005550:	0a054763          	bltz	a0,800055fe <exec+0x3a2>
  p->trapframe->a1 = sp;
    80005554:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005558:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000555c:	df843783          	ld	a5,-520(s0)
    80005560:	0007c703          	lbu	a4,0(a5)
    80005564:	cf11                	beqz	a4,80005580 <exec+0x324>
    80005566:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005568:	02f00693          	li	a3,47
    8000556c:	a039                	j	8000557a <exec+0x31e>
      last = s+1;
    8000556e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005572:	0785                	addi	a5,a5,1
    80005574:	fff7c703          	lbu	a4,-1(a5)
    80005578:	c701                	beqz	a4,80005580 <exec+0x324>
    if(*s == '/')
    8000557a:	fed71ce3          	bne	a4,a3,80005572 <exec+0x316>
    8000557e:	bfc5                	j	8000556e <exec+0x312>
  safestrcpy(p->name, last, sizeof(p->name));
    80005580:	4641                	li	a2,16
    80005582:	df843583          	ld	a1,-520(s0)
    80005586:	158a8513          	addi	a0,s5,344
    8000558a:	ffffc097          	auipc	ra,0xffffc
    8000558e:	948080e7          	jalr	-1720(ra) # 80000ed2 <safestrcpy>
  oldpagetable = p->pagetable;
    80005592:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005596:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000559a:	e0843783          	ld	a5,-504(s0)
    8000559e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055a2:	058ab783          	ld	a5,88(s5)
    800055a6:	e6843703          	ld	a4,-408(s0)
    800055aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055ac:	058ab783          	ld	a5,88(s5)
    800055b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055b4:	85e6                	mv	a1,s9
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	874080e7          	jalr	-1932(ra) # 80001e2a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055be:	0004851b          	sext.w	a0,s1
    800055c2:	bb0d                	j	800052f4 <exec+0x98>
    800055c4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055c8:	e0843583          	ld	a1,-504(s0)
    800055cc:	855a                	mv	a0,s6
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	85c080e7          	jalr	-1956(ra) # 80001e2a <proc_freepagetable>
  return -1;
    800055d6:	557d                	li	a0,-1
  if(ip){
    800055d8:	d00a0ee3          	beqz	s4,800052f4 <exec+0x98>
    800055dc:	b311                	j	800052e0 <exec+0x84>
    800055de:	e1243423          	sd	s2,-504(s0)
    800055e2:	b7dd                	j	800055c8 <exec+0x36c>
    800055e4:	e1243423          	sd	s2,-504(s0)
    800055e8:	b7c5                	j	800055c8 <exec+0x36c>
    800055ea:	e1243423          	sd	s2,-504(s0)
    800055ee:	bfe9                	j	800055c8 <exec+0x36c>
    800055f0:	e1243423          	sd	s2,-504(s0)
    800055f4:	bfd1                	j	800055c8 <exec+0x36c>
  ip = 0;
    800055f6:	4a01                	li	s4,0
    800055f8:	bfc1                	j	800055c8 <exec+0x36c>
    800055fa:	4a01                	li	s4,0
  if(pagetable)
    800055fc:	b7f1                	j	800055c8 <exec+0x36c>
  sz = sz1;
    800055fe:	e0843983          	ld	s3,-504(s0)
    80005602:	b569                	j	8000548c <exec+0x230>

0000000080005604 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005604:	7179                	addi	sp,sp,-48
    80005606:	f406                	sd	ra,40(sp)
    80005608:	f022                	sd	s0,32(sp)
    8000560a:	ec26                	sd	s1,24(sp)
    8000560c:	e84a                	sd	s2,16(sp)
    8000560e:	1800                	addi	s0,sp,48
    80005610:	892e                	mv	s2,a1
    80005612:	84b2                	mv	s1,a2
    int fd;
    struct file *f;

    argint(n, &fd);
    80005614:	fdc40593          	addi	a1,s0,-36
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	b04080e7          	jalr	-1276(ra) # 8000311c <argint>
    if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    80005620:	fdc42703          	lw	a4,-36(s0)
    80005624:	47bd                	li	a5,15
    80005626:	02e7eb63          	bltu	a5,a4,8000565c <argfd+0x58>
    8000562a:	ffffc097          	auipc	ra,0xffffc
    8000562e:	6a0080e7          	jalr	1696(ra) # 80001cca <myproc>
    80005632:	fdc42703          	lw	a4,-36(s0)
    80005636:	01a70793          	addi	a5,a4,26
    8000563a:	078e                	slli	a5,a5,0x3
    8000563c:	953e                	add	a0,a0,a5
    8000563e:	611c                	ld	a5,0(a0)
    80005640:	c385                	beqz	a5,80005660 <argfd+0x5c>
        return -1;
    if (pfd)
    80005642:	00090463          	beqz	s2,8000564a <argfd+0x46>
        *pfd = fd;
    80005646:	00e92023          	sw	a4,0(s2)
    if (pf)
        *pf = f;
    return 0;
    8000564a:	4501                	li	a0,0
    if (pf)
    8000564c:	c091                	beqz	s1,80005650 <argfd+0x4c>
        *pf = f;
    8000564e:	e09c                	sd	a5,0(s1)
}
    80005650:	70a2                	ld	ra,40(sp)
    80005652:	7402                	ld	s0,32(sp)
    80005654:	64e2                	ld	s1,24(sp)
    80005656:	6942                	ld	s2,16(sp)
    80005658:	6145                	addi	sp,sp,48
    8000565a:	8082                	ret
        return -1;
    8000565c:	557d                	li	a0,-1
    8000565e:	bfcd                	j	80005650 <argfd+0x4c>
    80005660:	557d                	li	a0,-1
    80005662:	b7fd                	j	80005650 <argfd+0x4c>

0000000080005664 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005664:	1101                	addi	sp,sp,-32
    80005666:	ec06                	sd	ra,24(sp)
    80005668:	e822                	sd	s0,16(sp)
    8000566a:	e426                	sd	s1,8(sp)
    8000566c:	1000                	addi	s0,sp,32
    8000566e:	84aa                	mv	s1,a0
    int fd;
    struct proc *p = myproc();
    80005670:	ffffc097          	auipc	ra,0xffffc
    80005674:	65a080e7          	jalr	1626(ra) # 80001cca <myproc>
    80005678:	862a                	mv	a2,a0

    for (fd = 0; fd < NOFILE; fd++)
    8000567a:	0d050793          	addi	a5,a0,208
    8000567e:	4501                	li	a0,0
    80005680:	46c1                	li	a3,16
    {
        if (p->ofile[fd] == 0)
    80005682:	6398                	ld	a4,0(a5)
    80005684:	cb19                	beqz	a4,8000569a <fdalloc+0x36>
    for (fd = 0; fd < NOFILE; fd++)
    80005686:	2505                	addiw	a0,a0,1
    80005688:	07a1                	addi	a5,a5,8
    8000568a:	fed51ce3          	bne	a0,a3,80005682 <fdalloc+0x1e>
        {
            p->ofile[fd] = f;
            return fd;
        }
    }
    return -1;
    8000568e:	557d                	li	a0,-1
}
    80005690:	60e2                	ld	ra,24(sp)
    80005692:	6442                	ld	s0,16(sp)
    80005694:	64a2                	ld	s1,8(sp)
    80005696:	6105                	addi	sp,sp,32
    80005698:	8082                	ret
            p->ofile[fd] = f;
    8000569a:	01a50793          	addi	a5,a0,26
    8000569e:	078e                	slli	a5,a5,0x3
    800056a0:	963e                	add	a2,a2,a5
    800056a2:	e204                	sd	s1,0(a2)
            return fd;
    800056a4:	b7f5                	j	80005690 <fdalloc+0x2c>

00000000800056a6 <create>:
    return -1;
}

static struct inode *
create(char *path, short type, short major, short minor)
{
    800056a6:	715d                	addi	sp,sp,-80
    800056a8:	e486                	sd	ra,72(sp)
    800056aa:	e0a2                	sd	s0,64(sp)
    800056ac:	fc26                	sd	s1,56(sp)
    800056ae:	f84a                	sd	s2,48(sp)
    800056b0:	f44e                	sd	s3,40(sp)
    800056b2:	f052                	sd	s4,32(sp)
    800056b4:	ec56                	sd	s5,24(sp)
    800056b6:	e85a                	sd	s6,16(sp)
    800056b8:	0880                	addi	s0,sp,80
    800056ba:	8b2e                	mv	s6,a1
    800056bc:	89b2                	mv	s3,a2
    800056be:	8936                	mv	s2,a3
    struct inode *ip, *dp;
    char name[DIRSIZ];

    if ((dp = nameiparent(path, name)) == 0)
    800056c0:	fb040593          	addi	a1,s0,-80
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	e7c080e7          	jalr	-388(ra) # 80004540 <nameiparent>
    800056cc:	84aa                	mv	s1,a0
    800056ce:	14050b63          	beqz	a0,80005824 <create+0x17e>
        return 0;

    ilock(dp);
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	6aa080e7          	jalr	1706(ra) # 80003d7c <ilock>

    if ((ip = dirlookup(dp, name, 0)) != 0)
    800056da:	4601                	li	a2,0
    800056dc:	fb040593          	addi	a1,s0,-80
    800056e0:	8526                	mv	a0,s1
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	b7e080e7          	jalr	-1154(ra) # 80004260 <dirlookup>
    800056ea:	8aaa                	mv	s5,a0
    800056ec:	c921                	beqz	a0,8000573c <create+0x96>
    {
        iunlockput(dp);
    800056ee:	8526                	mv	a0,s1
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	8ee080e7          	jalr	-1810(ra) # 80003fde <iunlockput>
        ilock(ip);
    800056f8:	8556                	mv	a0,s5
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	682080e7          	jalr	1666(ra) # 80003d7c <ilock>
        if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005702:	4789                	li	a5,2
    80005704:	02fb1563          	bne	s6,a5,8000572e <create+0x88>
    80005708:	044ad783          	lhu	a5,68(s5)
    8000570c:	37f9                	addiw	a5,a5,-2
    8000570e:	17c2                	slli	a5,a5,0x30
    80005710:	93c1                	srli	a5,a5,0x30
    80005712:	4705                	li	a4,1
    80005714:	00f76d63          	bltu	a4,a5,8000572e <create+0x88>
    ip->nlink = 0;
    iupdate(ip);
    iunlockput(ip);
    iunlockput(dp);
    return 0;
}
    80005718:	8556                	mv	a0,s5
    8000571a:	60a6                	ld	ra,72(sp)
    8000571c:	6406                	ld	s0,64(sp)
    8000571e:	74e2                	ld	s1,56(sp)
    80005720:	7942                	ld	s2,48(sp)
    80005722:	79a2                	ld	s3,40(sp)
    80005724:	7a02                	ld	s4,32(sp)
    80005726:	6ae2                	ld	s5,24(sp)
    80005728:	6b42                	ld	s6,16(sp)
    8000572a:	6161                	addi	sp,sp,80
    8000572c:	8082                	ret
        iunlockput(ip);
    8000572e:	8556                	mv	a0,s5
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	8ae080e7          	jalr	-1874(ra) # 80003fde <iunlockput>
        return 0;
    80005738:	4a81                	li	s5,0
    8000573a:	bff9                	j	80005718 <create+0x72>
    if ((ip = ialloc(dp->dev, type)) == 0)
    8000573c:	85da                	mv	a1,s6
    8000573e:	4088                	lw	a0,0(s1)
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	4a4080e7          	jalr	1188(ra) # 80003be4 <ialloc>
    80005748:	8a2a                	mv	s4,a0
    8000574a:	c529                	beqz	a0,80005794 <create+0xee>
    ilock(ip);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	630080e7          	jalr	1584(ra) # 80003d7c <ilock>
    ip->major = major;
    80005754:	053a1323          	sh	s3,70(s4)
    ip->minor = minor;
    80005758:	052a1423          	sh	s2,72(s4)
    ip->nlink = 1;
    8000575c:	4905                	li	s2,1
    8000575e:	052a1523          	sh	s2,74(s4)
    iupdate(ip);
    80005762:	8552                	mv	a0,s4
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	54c080e7          	jalr	1356(ra) # 80003cb0 <iupdate>
    if (type == T_DIR)
    8000576c:	032b0b63          	beq	s6,s2,800057a2 <create+0xfc>
    if (dirlink(dp, name, ip->inum) < 0)
    80005770:	004a2603          	lw	a2,4(s4)
    80005774:	fb040593          	addi	a1,s0,-80
    80005778:	8526                	mv	a0,s1
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	cf6080e7          	jalr	-778(ra) # 80004470 <dirlink>
    80005782:	06054f63          	bltz	a0,80005800 <create+0x15a>
    iunlockput(dp);
    80005786:	8526                	mv	a0,s1
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	856080e7          	jalr	-1962(ra) # 80003fde <iunlockput>
    return ip;
    80005790:	8ad2                	mv	s5,s4
    80005792:	b759                	j	80005718 <create+0x72>
        iunlockput(dp);
    80005794:	8526                	mv	a0,s1
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	848080e7          	jalr	-1976(ra) # 80003fde <iunlockput>
        return 0;
    8000579e:	8ad2                	mv	s5,s4
    800057a0:	bfa5                	j	80005718 <create+0x72>
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057a2:	004a2603          	lw	a2,4(s4)
    800057a6:	00003597          	auipc	a1,0x3
    800057aa:	14a58593          	addi	a1,a1,330 # 800088f0 <syscalls+0x2c8>
    800057ae:	8552                	mv	a0,s4
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	cc0080e7          	jalr	-832(ra) # 80004470 <dirlink>
    800057b8:	04054463          	bltz	a0,80005800 <create+0x15a>
    800057bc:	40d0                	lw	a2,4(s1)
    800057be:	00003597          	auipc	a1,0x3
    800057c2:	13a58593          	addi	a1,a1,314 # 800088f8 <syscalls+0x2d0>
    800057c6:	8552                	mv	a0,s4
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	ca8080e7          	jalr	-856(ra) # 80004470 <dirlink>
    800057d0:	02054863          	bltz	a0,80005800 <create+0x15a>
    if (dirlink(dp, name, ip->inum) < 0)
    800057d4:	004a2603          	lw	a2,4(s4)
    800057d8:	fb040593          	addi	a1,s0,-80
    800057dc:	8526                	mv	a0,s1
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	c92080e7          	jalr	-878(ra) # 80004470 <dirlink>
    800057e6:	00054d63          	bltz	a0,80005800 <create+0x15a>
        dp->nlink++; // for ".."
    800057ea:	04a4d783          	lhu	a5,74(s1)
    800057ee:	2785                	addiw	a5,a5,1
    800057f0:	04f49523          	sh	a5,74(s1)
        iupdate(dp);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	4ba080e7          	jalr	1210(ra) # 80003cb0 <iupdate>
    800057fe:	b761                	j	80005786 <create+0xe0>
    ip->nlink = 0;
    80005800:	040a1523          	sh	zero,74(s4)
    iupdate(ip);
    80005804:	8552                	mv	a0,s4
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	4aa080e7          	jalr	1194(ra) # 80003cb0 <iupdate>
    iunlockput(ip);
    8000580e:	8552                	mv	a0,s4
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	7ce080e7          	jalr	1998(ra) # 80003fde <iunlockput>
    iunlockput(dp);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	7c4080e7          	jalr	1988(ra) # 80003fde <iunlockput>
    return 0;
    80005822:	bddd                	j	80005718 <create+0x72>
        return 0;
    80005824:	8aaa                	mv	s5,a0
    80005826:	bdcd                	j	80005718 <create+0x72>

0000000080005828 <sys_dup>:
{
    80005828:	7179                	addi	sp,sp,-48
    8000582a:	f406                	sd	ra,40(sp)
    8000582c:	f022                	sd	s0,32(sp)
    8000582e:	ec26                	sd	s1,24(sp)
    80005830:	e84a                	sd	s2,16(sp)
    80005832:	1800                	addi	s0,sp,48
    if (argfd(0, 0, &f) < 0)
    80005834:	fd840613          	addi	a2,s0,-40
    80005838:	4581                	li	a1,0
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	dc8080e7          	jalr	-568(ra) # 80005604 <argfd>
        return -1;
    80005844:	57fd                	li	a5,-1
    if (argfd(0, 0, &f) < 0)
    80005846:	02054363          	bltz	a0,8000586c <sys_dup+0x44>
    if ((fd = fdalloc(f)) < 0)
    8000584a:	fd843903          	ld	s2,-40(s0)
    8000584e:	854a                	mv	a0,s2
    80005850:	00000097          	auipc	ra,0x0
    80005854:	e14080e7          	jalr	-492(ra) # 80005664 <fdalloc>
    80005858:	84aa                	mv	s1,a0
        return -1;
    8000585a:	57fd                	li	a5,-1
    if ((fd = fdalloc(f)) < 0)
    8000585c:	00054863          	bltz	a0,8000586c <sys_dup+0x44>
    filedup(f);
    80005860:	854a                	mv	a0,s2
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	332080e7          	jalr	818(ra) # 80004b94 <filedup>
    return fd;
    8000586a:	87a6                	mv	a5,s1
}
    8000586c:	853e                	mv	a0,a5
    8000586e:	70a2                	ld	ra,40(sp)
    80005870:	7402                	ld	s0,32(sp)
    80005872:	64e2                	ld	s1,24(sp)
    80005874:	6942                	ld	s2,16(sp)
    80005876:	6145                	addi	sp,sp,48
    80005878:	8082                	ret

000000008000587a <sys_read>:
{
    8000587a:	7179                	addi	sp,sp,-48
    8000587c:	f406                	sd	ra,40(sp)
    8000587e:	f022                	sd	s0,32(sp)
    80005880:	1800                	addi	s0,sp,48
    argaddr(1, &p);
    80005882:	fd840593          	addi	a1,s0,-40
    80005886:	4505                	li	a0,1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	8b4080e7          	jalr	-1868(ra) # 8000313c <argaddr>
    argint(2, &n);
    80005890:	fe440593          	addi	a1,s0,-28
    80005894:	4509                	li	a0,2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	886080e7          	jalr	-1914(ra) # 8000311c <argint>
    if (argfd(0, 0, &f) < 0)
    8000589e:	fe840613          	addi	a2,s0,-24
    800058a2:	4581                	li	a1,0
    800058a4:	4501                	li	a0,0
    800058a6:	00000097          	auipc	ra,0x0
    800058aa:	d5e080e7          	jalr	-674(ra) # 80005604 <argfd>
    800058ae:	87aa                	mv	a5,a0
        return -1;
    800058b0:	557d                	li	a0,-1
    if (argfd(0, 0, &f) < 0)
    800058b2:	0007cc63          	bltz	a5,800058ca <sys_read+0x50>
    return fileread(f, p, n);
    800058b6:	fe442603          	lw	a2,-28(s0)
    800058ba:	fd843583          	ld	a1,-40(s0)
    800058be:	fe843503          	ld	a0,-24(s0)
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	45e080e7          	jalr	1118(ra) # 80004d20 <fileread>
}
    800058ca:	70a2                	ld	ra,40(sp)
    800058cc:	7402                	ld	s0,32(sp)
    800058ce:	6145                	addi	sp,sp,48
    800058d0:	8082                	ret

00000000800058d2 <sys_write>:
{
    800058d2:	7179                	addi	sp,sp,-48
    800058d4:	f406                	sd	ra,40(sp)
    800058d6:	f022                	sd	s0,32(sp)
    800058d8:	1800                	addi	s0,sp,48
    argaddr(1, &p);
    800058da:	fd840593          	addi	a1,s0,-40
    800058de:	4505                	li	a0,1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	85c080e7          	jalr	-1956(ra) # 8000313c <argaddr>
    argint(2, &n);
    800058e8:	fe440593          	addi	a1,s0,-28
    800058ec:	4509                	li	a0,2
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	82e080e7          	jalr	-2002(ra) # 8000311c <argint>
    if (argfd(0, 0, &f) < 0)
    800058f6:	fe840613          	addi	a2,s0,-24
    800058fa:	4581                	li	a1,0
    800058fc:	4501                	li	a0,0
    800058fe:	00000097          	auipc	ra,0x0
    80005902:	d06080e7          	jalr	-762(ra) # 80005604 <argfd>
    80005906:	87aa                	mv	a5,a0
        return -1;
    80005908:	557d                	li	a0,-1
    if (argfd(0, 0, &f) < 0)
    8000590a:	0007cc63          	bltz	a5,80005922 <sys_write+0x50>
    return filewrite(f, p, n);
    8000590e:	fe442603          	lw	a2,-28(s0)
    80005912:	fd843583          	ld	a1,-40(s0)
    80005916:	fe843503          	ld	a0,-24(s0)
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	4c8080e7          	jalr	1224(ra) # 80004de2 <filewrite>
}
    80005922:	70a2                	ld	ra,40(sp)
    80005924:	7402                	ld	s0,32(sp)
    80005926:	6145                	addi	sp,sp,48
    80005928:	8082                	ret

000000008000592a <sys_close>:
{
    8000592a:	1101                	addi	sp,sp,-32
    8000592c:	ec06                	sd	ra,24(sp)
    8000592e:	e822                	sd	s0,16(sp)
    80005930:	1000                	addi	s0,sp,32
    if (argfd(0, &fd, &f) < 0)
    80005932:	fe040613          	addi	a2,s0,-32
    80005936:	fec40593          	addi	a1,s0,-20
    8000593a:	4501                	li	a0,0
    8000593c:	00000097          	auipc	ra,0x0
    80005940:	cc8080e7          	jalr	-824(ra) # 80005604 <argfd>
        return -1;
    80005944:	57fd                	li	a5,-1
    if (argfd(0, &fd, &f) < 0)
    80005946:	02054463          	bltz	a0,8000596e <sys_close+0x44>
    myproc()->ofile[fd] = 0;
    8000594a:	ffffc097          	auipc	ra,0xffffc
    8000594e:	380080e7          	jalr	896(ra) # 80001cca <myproc>
    80005952:	fec42783          	lw	a5,-20(s0)
    80005956:	07e9                	addi	a5,a5,26
    80005958:	078e                	slli	a5,a5,0x3
    8000595a:	953e                	add	a0,a0,a5
    8000595c:	00053023          	sd	zero,0(a0)
    fileclose(f);
    80005960:	fe043503          	ld	a0,-32(s0)
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	282080e7          	jalr	642(ra) # 80004be6 <fileclose>
    return 0;
    8000596c:	4781                	li	a5,0
}
    8000596e:	853e                	mv	a0,a5
    80005970:	60e2                	ld	ra,24(sp)
    80005972:	6442                	ld	s0,16(sp)
    80005974:	6105                	addi	sp,sp,32
    80005976:	8082                	ret

0000000080005978 <sys_fstat>:
{
    80005978:	1101                	addi	sp,sp,-32
    8000597a:	ec06                	sd	ra,24(sp)
    8000597c:	e822                	sd	s0,16(sp)
    8000597e:	1000                	addi	s0,sp,32
    argaddr(1, &st);
    80005980:	fe040593          	addi	a1,s0,-32
    80005984:	4505                	li	a0,1
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	7b6080e7          	jalr	1974(ra) # 8000313c <argaddr>
    if (argfd(0, 0, &f) < 0)
    8000598e:	fe840613          	addi	a2,s0,-24
    80005992:	4581                	li	a1,0
    80005994:	4501                	li	a0,0
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	c6e080e7          	jalr	-914(ra) # 80005604 <argfd>
    8000599e:	87aa                	mv	a5,a0
        return -1;
    800059a0:	557d                	li	a0,-1
    if (argfd(0, 0, &f) < 0)
    800059a2:	0007ca63          	bltz	a5,800059b6 <sys_fstat+0x3e>
    return filestat(f, st);
    800059a6:	fe043583          	ld	a1,-32(s0)
    800059aa:	fe843503          	ld	a0,-24(s0)
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	300080e7          	jalr	768(ra) # 80004cae <filestat>
}
    800059b6:	60e2                	ld	ra,24(sp)
    800059b8:	6442                	ld	s0,16(sp)
    800059ba:	6105                	addi	sp,sp,32
    800059bc:	8082                	ret

00000000800059be <sys_link>:
{
    800059be:	7169                	addi	sp,sp,-304
    800059c0:	f606                	sd	ra,296(sp)
    800059c2:	f222                	sd	s0,288(sp)
    800059c4:	ee26                	sd	s1,280(sp)
    800059c6:	ea4a                	sd	s2,272(sp)
    800059c8:	1a00                	addi	s0,sp,304
    if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ca:	08000613          	li	a2,128
    800059ce:	ed040593          	addi	a1,s0,-304
    800059d2:	4501                	li	a0,0
    800059d4:	ffffd097          	auipc	ra,0xffffd
    800059d8:	788080e7          	jalr	1928(ra) # 8000315c <argstr>
        return -1;
    800059dc:	57fd                	li	a5,-1
    if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059de:	10054e63          	bltz	a0,80005afa <sys_link+0x13c>
    800059e2:	08000613          	li	a2,128
    800059e6:	f5040593          	addi	a1,s0,-176
    800059ea:	4505                	li	a0,1
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	770080e7          	jalr	1904(ra) # 8000315c <argstr>
        return -1;
    800059f4:	57fd                	li	a5,-1
    if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059f6:	10054263          	bltz	a0,80005afa <sys_link+0x13c>
    begin_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	d28080e7          	jalr	-728(ra) # 80004722 <begin_op>
    if ((ip = namei(old)) == 0)
    80005a02:	ed040513          	addi	a0,s0,-304
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	b1c080e7          	jalr	-1252(ra) # 80004522 <namei>
    80005a0e:	84aa                	mv	s1,a0
    80005a10:	c551                	beqz	a0,80005a9c <sys_link+0xde>
    ilock(ip);
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	36a080e7          	jalr	874(ra) # 80003d7c <ilock>
    if (ip->type == T_DIR)
    80005a1a:	04449703          	lh	a4,68(s1)
    80005a1e:	4785                	li	a5,1
    80005a20:	08f70463          	beq	a4,a5,80005aa8 <sys_link+0xea>
    ip->nlink++;
    80005a24:	04a4d783          	lhu	a5,74(s1)
    80005a28:	2785                	addiw	a5,a5,1
    80005a2a:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	280080e7          	jalr	640(ra) # 80003cb0 <iupdate>
    iunlock(ip);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	404080e7          	jalr	1028(ra) # 80003e3e <iunlock>
    if ((dp = nameiparent(new, name)) == 0)
    80005a42:	fd040593          	addi	a1,s0,-48
    80005a46:	f5040513          	addi	a0,s0,-176
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	af6080e7          	jalr	-1290(ra) # 80004540 <nameiparent>
    80005a52:	892a                	mv	s2,a0
    80005a54:	c935                	beqz	a0,80005ac8 <sys_link+0x10a>
    ilock(dp);
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	326080e7          	jalr	806(ra) # 80003d7c <ilock>
    if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0)
    80005a5e:	00092703          	lw	a4,0(s2)
    80005a62:	409c                	lw	a5,0(s1)
    80005a64:	04f71d63          	bne	a4,a5,80005abe <sys_link+0x100>
    80005a68:	40d0                	lw	a2,4(s1)
    80005a6a:	fd040593          	addi	a1,s0,-48
    80005a6e:	854a                	mv	a0,s2
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	a00080e7          	jalr	-1536(ra) # 80004470 <dirlink>
    80005a78:	04054363          	bltz	a0,80005abe <sys_link+0x100>
    iunlockput(dp);
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	560080e7          	jalr	1376(ra) # 80003fde <iunlockput>
    iput(ip);
    80005a86:	8526                	mv	a0,s1
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	4ae080e7          	jalr	1198(ra) # 80003f36 <iput>
    end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	d0c080e7          	jalr	-756(ra) # 8000479c <end_op>
    return 0;
    80005a98:	4781                	li	a5,0
    80005a9a:	a085                	j	80005afa <sys_link+0x13c>
        end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	d00080e7          	jalr	-768(ra) # 8000479c <end_op>
        return -1;
    80005aa4:	57fd                	li	a5,-1
    80005aa6:	a891                	j	80005afa <sys_link+0x13c>
        iunlockput(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	534080e7          	jalr	1332(ra) # 80003fde <iunlockput>
        end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	cea080e7          	jalr	-790(ra) # 8000479c <end_op>
        return -1;
    80005aba:	57fd                	li	a5,-1
    80005abc:	a83d                	j	80005afa <sys_link+0x13c>
        iunlockput(dp);
    80005abe:	854a                	mv	a0,s2
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	51e080e7          	jalr	1310(ra) # 80003fde <iunlockput>
    ilock(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	2b2080e7          	jalr	690(ra) # 80003d7c <ilock>
    ip->nlink--;
    80005ad2:	04a4d783          	lhu	a5,74(s1)
    80005ad6:	37fd                	addiw	a5,a5,-1
    80005ad8:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80005adc:	8526                	mv	a0,s1
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	1d2080e7          	jalr	466(ra) # 80003cb0 <iupdate>
    iunlockput(ip);
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	4f6080e7          	jalr	1270(ra) # 80003fde <iunlockput>
    end_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	cac080e7          	jalr	-852(ra) # 8000479c <end_op>
    return -1;
    80005af8:	57fd                	li	a5,-1
}
    80005afa:	853e                	mv	a0,a5
    80005afc:	70b2                	ld	ra,296(sp)
    80005afe:	7412                	ld	s0,288(sp)
    80005b00:	64f2                	ld	s1,280(sp)
    80005b02:	6952                	ld	s2,272(sp)
    80005b04:	6155                	addi	sp,sp,304
    80005b06:	8082                	ret

0000000080005b08 <sys_unlink>:
{
    80005b08:	7151                	addi	sp,sp,-240
    80005b0a:	f586                	sd	ra,232(sp)
    80005b0c:	f1a2                	sd	s0,224(sp)
    80005b0e:	eda6                	sd	s1,216(sp)
    80005b10:	e9ca                	sd	s2,208(sp)
    80005b12:	e5ce                	sd	s3,200(sp)
    80005b14:	1980                	addi	s0,sp,240
    if (argstr(0, path, MAXPATH) < 0)
    80005b16:	08000613          	li	a2,128
    80005b1a:	f3040593          	addi	a1,s0,-208
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	63c080e7          	jalr	1596(ra) # 8000315c <argstr>
    80005b28:	18054163          	bltz	a0,80005caa <sys_unlink+0x1a2>
    begin_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	bf6080e7          	jalr	-1034(ra) # 80004722 <begin_op>
    if ((dp = nameiparent(path, name)) == 0)
    80005b34:	fb040593          	addi	a1,s0,-80
    80005b38:	f3040513          	addi	a0,s0,-208
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	a04080e7          	jalr	-1532(ra) # 80004540 <nameiparent>
    80005b44:	84aa                	mv	s1,a0
    80005b46:	c979                	beqz	a0,80005c1c <sys_unlink+0x114>
    ilock(dp);
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	234080e7          	jalr	564(ra) # 80003d7c <ilock>
    if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b50:	00003597          	auipc	a1,0x3
    80005b54:	da058593          	addi	a1,a1,-608 # 800088f0 <syscalls+0x2c8>
    80005b58:	fb040513          	addi	a0,s0,-80
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	6ea080e7          	jalr	1770(ra) # 80004246 <namecmp>
    80005b64:	14050a63          	beqz	a0,80005cb8 <sys_unlink+0x1b0>
    80005b68:	00003597          	auipc	a1,0x3
    80005b6c:	d9058593          	addi	a1,a1,-624 # 800088f8 <syscalls+0x2d0>
    80005b70:	fb040513          	addi	a0,s0,-80
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	6d2080e7          	jalr	1746(ra) # 80004246 <namecmp>
    80005b7c:	12050e63          	beqz	a0,80005cb8 <sys_unlink+0x1b0>
    if ((ip = dirlookup(dp, name, &off)) == 0)
    80005b80:	f2c40613          	addi	a2,s0,-212
    80005b84:	fb040593          	addi	a1,s0,-80
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	6d6080e7          	jalr	1750(ra) # 80004260 <dirlookup>
    80005b92:	892a                	mv	s2,a0
    80005b94:	12050263          	beqz	a0,80005cb8 <sys_unlink+0x1b0>
    ilock(ip);
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	1e4080e7          	jalr	484(ra) # 80003d7c <ilock>
    if (ip->nlink < 1)
    80005ba0:	04a91783          	lh	a5,74(s2)
    80005ba4:	08f05263          	blez	a5,80005c28 <sys_unlink+0x120>
    if (ip->type == T_DIR && !isdirempty(ip))
    80005ba8:	04491703          	lh	a4,68(s2)
    80005bac:	4785                	li	a5,1
    80005bae:	08f70563          	beq	a4,a5,80005c38 <sys_unlink+0x130>
    memset(&de, 0, sizeof(de));
    80005bb2:	4641                	li	a2,16
    80005bb4:	4581                	li	a1,0
    80005bb6:	fc040513          	addi	a0,s0,-64
    80005bba:	ffffb097          	auipc	ra,0xffffb
    80005bbe:	1d0080e7          	jalr	464(ra) # 80000d8a <memset>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bc2:	4741                	li	a4,16
    80005bc4:	f2c42683          	lw	a3,-212(s0)
    80005bc8:	fc040613          	addi	a2,s0,-64
    80005bcc:	4581                	li	a1,0
    80005bce:	8526                	mv	a0,s1
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	558080e7          	jalr	1368(ra) # 80004128 <writei>
    80005bd8:	47c1                	li	a5,16
    80005bda:	0af51563          	bne	a0,a5,80005c84 <sys_unlink+0x17c>
    if (ip->type == T_DIR)
    80005bde:	04491703          	lh	a4,68(s2)
    80005be2:	4785                	li	a5,1
    80005be4:	0af70863          	beq	a4,a5,80005c94 <sys_unlink+0x18c>
    iunlockput(dp);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	3f4080e7          	jalr	1012(ra) # 80003fde <iunlockput>
    ip->nlink--;
    80005bf2:	04a95783          	lhu	a5,74(s2)
    80005bf6:	37fd                	addiw	a5,a5,-1
    80005bf8:	04f91523          	sh	a5,74(s2)
    iupdate(ip);
    80005bfc:	854a                	mv	a0,s2
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	0b2080e7          	jalr	178(ra) # 80003cb0 <iupdate>
    iunlockput(ip);
    80005c06:	854a                	mv	a0,s2
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	3d6080e7          	jalr	982(ra) # 80003fde <iunlockput>
    end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	b8c080e7          	jalr	-1140(ra) # 8000479c <end_op>
    return 0;
    80005c18:	4501                	li	a0,0
    80005c1a:	a84d                	j	80005ccc <sys_unlink+0x1c4>
        end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	b80080e7          	jalr	-1152(ra) # 8000479c <end_op>
        return -1;
    80005c24:	557d                	li	a0,-1
    80005c26:	a05d                	j	80005ccc <sys_unlink+0x1c4>
        panic("unlink: nlink < 1");
    80005c28:	00003517          	auipc	a0,0x3
    80005c2c:	cd850513          	addi	a0,a0,-808 # 80008900 <syscalls+0x2d8>
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	90c080e7          	jalr	-1780(ra) # 8000053c <panic>
    for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005c38:	04c92703          	lw	a4,76(s2)
    80005c3c:	02000793          	li	a5,32
    80005c40:	f6e7f9e3          	bgeu	a5,a4,80005bb2 <sys_unlink+0xaa>
    80005c44:	02000993          	li	s3,32
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c48:	4741                	li	a4,16
    80005c4a:	86ce                	mv	a3,s3
    80005c4c:	f1840613          	addi	a2,s0,-232
    80005c50:	4581                	li	a1,0
    80005c52:	854a                	mv	a0,s2
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	3dc080e7          	jalr	988(ra) # 80004030 <readi>
    80005c5c:	47c1                	li	a5,16
    80005c5e:	00f51b63          	bne	a0,a5,80005c74 <sys_unlink+0x16c>
        if (de.inum != 0)
    80005c62:	f1845783          	lhu	a5,-232(s0)
    80005c66:	e7a1                	bnez	a5,80005cae <sys_unlink+0x1a6>
    for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005c68:	29c1                	addiw	s3,s3,16
    80005c6a:	04c92783          	lw	a5,76(s2)
    80005c6e:	fcf9ede3          	bltu	s3,a5,80005c48 <sys_unlink+0x140>
    80005c72:	b781                	j	80005bb2 <sys_unlink+0xaa>
            panic("isdirempty: readi");
    80005c74:	00003517          	auipc	a0,0x3
    80005c78:	ca450513          	addi	a0,a0,-860 # 80008918 <syscalls+0x2f0>
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	8c0080e7          	jalr	-1856(ra) # 8000053c <panic>
        panic("unlink: writei");
    80005c84:	00003517          	auipc	a0,0x3
    80005c88:	cac50513          	addi	a0,a0,-852 # 80008930 <syscalls+0x308>
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	8b0080e7          	jalr	-1872(ra) # 8000053c <panic>
        dp->nlink--;
    80005c94:	04a4d783          	lhu	a5,74(s1)
    80005c98:	37fd                	addiw	a5,a5,-1
    80005c9a:	04f49523          	sh	a5,74(s1)
        iupdate(dp);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	010080e7          	jalr	16(ra) # 80003cb0 <iupdate>
    80005ca8:	b781                	j	80005be8 <sys_unlink+0xe0>
        return -1;
    80005caa:	557d                	li	a0,-1
    80005cac:	a005                	j	80005ccc <sys_unlink+0x1c4>
        iunlockput(ip);
    80005cae:	854a                	mv	a0,s2
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	32e080e7          	jalr	814(ra) # 80003fde <iunlockput>
    iunlockput(dp);
    80005cb8:	8526                	mv	a0,s1
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	324080e7          	jalr	804(ra) # 80003fde <iunlockput>
    end_op();
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	ada080e7          	jalr	-1318(ra) # 8000479c <end_op>
    return -1;
    80005cca:	557d                	li	a0,-1
}
    80005ccc:	70ae                	ld	ra,232(sp)
    80005cce:	740e                	ld	s0,224(sp)
    80005cd0:	64ee                	ld	s1,216(sp)
    80005cd2:	694e                	ld	s2,208(sp)
    80005cd4:	69ae                	ld	s3,200(sp)
    80005cd6:	616d                	addi	sp,sp,240
    80005cd8:	8082                	ret

0000000080005cda <sys_open>:

uint64
sys_open(void)
{
    80005cda:	7131                	addi	sp,sp,-192
    80005cdc:	fd06                	sd	ra,184(sp)
    80005cde:	f922                	sd	s0,176(sp)
    80005ce0:	f526                	sd	s1,168(sp)
    80005ce2:	f14a                	sd	s2,160(sp)
    80005ce4:	ed4e                	sd	s3,152(sp)
    80005ce6:	0180                	addi	s0,sp,192
    int fd, omode;
    struct file *f;
    struct inode *ip;
    int n;

    argint(1, &omode);
    80005ce8:	f4c40593          	addi	a1,s0,-180
    80005cec:	4505                	li	a0,1
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	42e080e7          	jalr	1070(ra) # 8000311c <argint>
    if ((n = argstr(0, path, MAXPATH)) < 0)
    80005cf6:	08000613          	li	a2,128
    80005cfa:	f5040593          	addi	a1,s0,-176
    80005cfe:	4501                	li	a0,0
    80005d00:	ffffd097          	auipc	ra,0xffffd
    80005d04:	45c080e7          	jalr	1116(ra) # 8000315c <argstr>
    80005d08:	87aa                	mv	a5,a0
        return -1;
    80005d0a:	557d                	li	a0,-1
    if ((n = argstr(0, path, MAXPATH)) < 0)
    80005d0c:	0a07c863          	bltz	a5,80005dbc <sys_open+0xe2>

    begin_op();
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	a12080e7          	jalr	-1518(ra) # 80004722 <begin_op>

    if (omode & O_CREATE)
    80005d18:	f4c42783          	lw	a5,-180(s0)
    80005d1c:	2007f793          	andi	a5,a5,512
    80005d20:	cbdd                	beqz	a5,80005dd6 <sys_open+0xfc>
    {
        ip = create(path, T_FILE, 0, 0);
    80005d22:	4681                	li	a3,0
    80005d24:	4601                	li	a2,0
    80005d26:	4589                	li	a1,2
    80005d28:	f5040513          	addi	a0,s0,-176
    80005d2c:	00000097          	auipc	ra,0x0
    80005d30:	97a080e7          	jalr	-1670(ra) # 800056a6 <create>
    80005d34:	84aa                	mv	s1,a0
        if (ip == 0)
    80005d36:	c951                	beqz	a0,80005dca <sys_open+0xf0>
            end_op();
            return -1;
        }
    }

    if (ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV))
    80005d38:	04449703          	lh	a4,68(s1)
    80005d3c:	478d                	li	a5,3
    80005d3e:	00f71763          	bne	a4,a5,80005d4c <sys_open+0x72>
    80005d42:	0464d703          	lhu	a4,70(s1)
    80005d46:	47a5                	li	a5,9
    80005d48:	0ce7ec63          	bltu	a5,a4,80005e20 <sys_open+0x146>
        iunlockput(ip);
        end_op();
        return -1;
    }

    if ((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0)
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	dde080e7          	jalr	-546(ra) # 80004b2a <filealloc>
    80005d54:	892a                	mv	s2,a0
    80005d56:	c56d                	beqz	a0,80005e40 <sys_open+0x166>
    80005d58:	00000097          	auipc	ra,0x0
    80005d5c:	90c080e7          	jalr	-1780(ra) # 80005664 <fdalloc>
    80005d60:	89aa                	mv	s3,a0
    80005d62:	0c054a63          	bltz	a0,80005e36 <sys_open+0x15c>
        iunlockput(ip);
        end_op();
        return -1;
    }

    if (ip->type == T_DEVICE)
    80005d66:	04449703          	lh	a4,68(s1)
    80005d6a:	478d                	li	a5,3
    80005d6c:	0ef70563          	beq	a4,a5,80005e56 <sys_open+0x17c>
        f->type = FD_DEVICE;
        f->major = ip->major;
    }
    else
    {
        f->type = FD_INODE;
    80005d70:	4789                	li	a5,2
    80005d72:	00f92023          	sw	a5,0(s2)
        f->off = 0;
    80005d76:	02092023          	sw	zero,32(s2)
    }
    f->ip = ip;
    80005d7a:	00993c23          	sd	s1,24(s2)
    f->readable = !(omode & O_WRONLY);
    80005d7e:	f4c42783          	lw	a5,-180(s0)
    80005d82:	0017c713          	xori	a4,a5,1
    80005d86:	8b05                	andi	a4,a4,1
    80005d88:	00e90423          	sb	a4,8(s2)
    f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d8c:	0037f713          	andi	a4,a5,3
    80005d90:	00e03733          	snez	a4,a4
    80005d94:	00e904a3          	sb	a4,9(s2)

    if ((omode & O_TRUNC) && ip->type == T_FILE)
    80005d98:	4007f793          	andi	a5,a5,1024
    80005d9c:	c791                	beqz	a5,80005da8 <sys_open+0xce>
    80005d9e:	04449703          	lh	a4,68(s1)
    80005da2:	4789                	li	a5,2
    80005da4:	0cf70063          	beq	a4,a5,80005e64 <sys_open+0x18a>
    {
        itrunc(ip);
    }

    iunlock(ip);
    80005da8:	8526                	mv	a0,s1
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	094080e7          	jalr	148(ra) # 80003e3e <iunlock>
    end_op();
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	9ea080e7          	jalr	-1558(ra) # 8000479c <end_op>

    return fd;
    80005dba:	854e                	mv	a0,s3
}
    80005dbc:	70ea                	ld	ra,184(sp)
    80005dbe:	744a                	ld	s0,176(sp)
    80005dc0:	74aa                	ld	s1,168(sp)
    80005dc2:	790a                	ld	s2,160(sp)
    80005dc4:	69ea                	ld	s3,152(sp)
    80005dc6:	6129                	addi	sp,sp,192
    80005dc8:	8082                	ret
            end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	9d2080e7          	jalr	-1582(ra) # 8000479c <end_op>
            return -1;
    80005dd2:	557d                	li	a0,-1
    80005dd4:	b7e5                	j	80005dbc <sys_open+0xe2>
        if ((ip = namei(path)) == 0)
    80005dd6:	f5040513          	addi	a0,s0,-176
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	748080e7          	jalr	1864(ra) # 80004522 <namei>
    80005de2:	84aa                	mv	s1,a0
    80005de4:	c905                	beqz	a0,80005e14 <sys_open+0x13a>
        ilock(ip);
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	f96080e7          	jalr	-106(ra) # 80003d7c <ilock>
        if (ip->type == T_DIR && omode != O_RDONLY)
    80005dee:	04449703          	lh	a4,68(s1)
    80005df2:	4785                	li	a5,1
    80005df4:	f4f712e3          	bne	a4,a5,80005d38 <sys_open+0x5e>
    80005df8:	f4c42783          	lw	a5,-180(s0)
    80005dfc:	dba1                	beqz	a5,80005d4c <sys_open+0x72>
            iunlockput(ip);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	1de080e7          	jalr	478(ra) # 80003fde <iunlockput>
            end_op();
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	994080e7          	jalr	-1644(ra) # 8000479c <end_op>
            return -1;
    80005e10:	557d                	li	a0,-1
    80005e12:	b76d                	j	80005dbc <sys_open+0xe2>
            end_op();
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	988080e7          	jalr	-1656(ra) # 8000479c <end_op>
            return -1;
    80005e1c:	557d                	li	a0,-1
    80005e1e:	bf79                	j	80005dbc <sys_open+0xe2>
        iunlockput(ip);
    80005e20:	8526                	mv	a0,s1
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	1bc080e7          	jalr	444(ra) # 80003fde <iunlockput>
        end_op();
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	972080e7          	jalr	-1678(ra) # 8000479c <end_op>
        return -1;
    80005e32:	557d                	li	a0,-1
    80005e34:	b761                	j	80005dbc <sys_open+0xe2>
            fileclose(f);
    80005e36:	854a                	mv	a0,s2
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	dae080e7          	jalr	-594(ra) # 80004be6 <fileclose>
        iunlockput(ip);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	19c080e7          	jalr	412(ra) # 80003fde <iunlockput>
        end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	952080e7          	jalr	-1710(ra) # 8000479c <end_op>
        return -1;
    80005e52:	557d                	li	a0,-1
    80005e54:	b7a5                	j	80005dbc <sys_open+0xe2>
        f->type = FD_DEVICE;
    80005e56:	00f92023          	sw	a5,0(s2)
        f->major = ip->major;
    80005e5a:	04649783          	lh	a5,70(s1)
    80005e5e:	02f91223          	sh	a5,36(s2)
    80005e62:	bf21                	j	80005d7a <sys_open+0xa0>
        itrunc(ip);
    80005e64:	8526                	mv	a0,s1
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	024080e7          	jalr	36(ra) # 80003e8a <itrunc>
    80005e6e:	bf2d                	j	80005da8 <sys_open+0xce>

0000000080005e70 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e70:	7175                	addi	sp,sp,-144
    80005e72:	e506                	sd	ra,136(sp)
    80005e74:	e122                	sd	s0,128(sp)
    80005e76:	0900                	addi	s0,sp,144
    char path[MAXPATH];
    struct inode *ip;

    begin_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	8aa080e7          	jalr	-1878(ra) # 80004722 <begin_op>
    if (argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
    80005e80:	08000613          	li	a2,128
    80005e84:	f7040593          	addi	a1,s0,-144
    80005e88:	4501                	li	a0,0
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	2d2080e7          	jalr	722(ra) # 8000315c <argstr>
    80005e92:	02054963          	bltz	a0,80005ec4 <sys_mkdir+0x54>
    80005e96:	4681                	li	a3,0
    80005e98:	4601                	li	a2,0
    80005e9a:	4585                	li	a1,1
    80005e9c:	f7040513          	addi	a0,s0,-144
    80005ea0:	00000097          	auipc	ra,0x0
    80005ea4:	806080e7          	jalr	-2042(ra) # 800056a6 <create>
    80005ea8:	cd11                	beqz	a0,80005ec4 <sys_mkdir+0x54>
    {
        end_op();
        return -1;
    }
    iunlockput(ip);
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	134080e7          	jalr	308(ra) # 80003fde <iunlockput>
    end_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	8ea080e7          	jalr	-1814(ra) # 8000479c <end_op>
    return 0;
    80005eba:	4501                	li	a0,0
}
    80005ebc:	60aa                	ld	ra,136(sp)
    80005ebe:	640a                	ld	s0,128(sp)
    80005ec0:	6149                	addi	sp,sp,144
    80005ec2:	8082                	ret
        end_op();
    80005ec4:	fffff097          	auipc	ra,0xfffff
    80005ec8:	8d8080e7          	jalr	-1832(ra) # 8000479c <end_op>
        return -1;
    80005ecc:	557d                	li	a0,-1
    80005ece:	b7fd                	j	80005ebc <sys_mkdir+0x4c>

0000000080005ed0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ed0:	7135                	addi	sp,sp,-160
    80005ed2:	ed06                	sd	ra,152(sp)
    80005ed4:	e922                	sd	s0,144(sp)
    80005ed6:	1100                	addi	s0,sp,160
    struct inode *ip;
    char path[MAXPATH];
    int major, minor;

    begin_op();
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	84a080e7          	jalr	-1974(ra) # 80004722 <begin_op>
    argint(1, &major);
    80005ee0:	f6c40593          	addi	a1,s0,-148
    80005ee4:	4505                	li	a0,1
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	236080e7          	jalr	566(ra) # 8000311c <argint>
    argint(2, &minor);
    80005eee:	f6840593          	addi	a1,s0,-152
    80005ef2:	4509                	li	a0,2
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	228080e7          	jalr	552(ra) # 8000311c <argint>
    if ((argstr(0, path, MAXPATH)) < 0 ||
    80005efc:	08000613          	li	a2,128
    80005f00:	f7040593          	addi	a1,s0,-144
    80005f04:	4501                	li	a0,0
    80005f06:	ffffd097          	auipc	ra,0xffffd
    80005f0a:	256080e7          	jalr	598(ra) # 8000315c <argstr>
    80005f0e:	02054b63          	bltz	a0,80005f44 <sys_mknod+0x74>
        (ip = create(path, T_DEVICE, major, minor)) == 0)
    80005f12:	f6841683          	lh	a3,-152(s0)
    80005f16:	f6c41603          	lh	a2,-148(s0)
    80005f1a:	458d                	li	a1,3
    80005f1c:	f7040513          	addi	a0,s0,-144
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	786080e7          	jalr	1926(ra) # 800056a6 <create>
    if ((argstr(0, path, MAXPATH)) < 0 ||
    80005f28:	cd11                	beqz	a0,80005f44 <sys_mknod+0x74>
    {
        end_op();
        return -1;
    }
    iunlockput(ip);
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	0b4080e7          	jalr	180(ra) # 80003fde <iunlockput>
    end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	86a080e7          	jalr	-1942(ra) # 8000479c <end_op>
    return 0;
    80005f3a:	4501                	li	a0,0
}
    80005f3c:	60ea                	ld	ra,152(sp)
    80005f3e:	644a                	ld	s0,144(sp)
    80005f40:	610d                	addi	sp,sp,160
    80005f42:	8082                	ret
        end_op();
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	858080e7          	jalr	-1960(ra) # 8000479c <end_op>
        return -1;
    80005f4c:	557d                	li	a0,-1
    80005f4e:	b7fd                	j	80005f3c <sys_mknod+0x6c>

0000000080005f50 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f50:	7135                	addi	sp,sp,-160
    80005f52:	ed06                	sd	ra,152(sp)
    80005f54:	e922                	sd	s0,144(sp)
    80005f56:	e526                	sd	s1,136(sp)
    80005f58:	e14a                	sd	s2,128(sp)
    80005f5a:	1100                	addi	s0,sp,160
    char path[MAXPATH];
    struct inode *ip;
    struct proc *p = myproc();
    80005f5c:	ffffc097          	auipc	ra,0xffffc
    80005f60:	d6e080e7          	jalr	-658(ra) # 80001cca <myproc>
    80005f64:	892a                	mv	s2,a0

    begin_op();
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	7bc080e7          	jalr	1980(ra) # 80004722 <begin_op>
    if (argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0)
    80005f6e:	08000613          	li	a2,128
    80005f72:	f6040593          	addi	a1,s0,-160
    80005f76:	4501                	li	a0,0
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	1e4080e7          	jalr	484(ra) # 8000315c <argstr>
    80005f80:	04054b63          	bltz	a0,80005fd6 <sys_chdir+0x86>
    80005f84:	f6040513          	addi	a0,s0,-160
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	59a080e7          	jalr	1434(ra) # 80004522 <namei>
    80005f90:	84aa                	mv	s1,a0
    80005f92:	c131                	beqz	a0,80005fd6 <sys_chdir+0x86>
    {
        end_op();
        return -1;
    }
    ilock(ip);
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	de8080e7          	jalr	-536(ra) # 80003d7c <ilock>
    if (ip->type != T_DIR)
    80005f9c:	04449703          	lh	a4,68(s1)
    80005fa0:	4785                	li	a5,1
    80005fa2:	04f71063          	bne	a4,a5,80005fe2 <sys_chdir+0x92>
    {
        iunlockput(ip);
        end_op();
        return -1;
    }
    iunlock(ip);
    80005fa6:	8526                	mv	a0,s1
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	e96080e7          	jalr	-362(ra) # 80003e3e <iunlock>
    iput(p->cwd);
    80005fb0:	15093503          	ld	a0,336(s2)
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	f82080e7          	jalr	-126(ra) # 80003f36 <iput>
    end_op();
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	7e0080e7          	jalr	2016(ra) # 8000479c <end_op>
    p->cwd = ip;
    80005fc4:	14993823          	sd	s1,336(s2)
    return 0;
    80005fc8:	4501                	li	a0,0
}
    80005fca:	60ea                	ld	ra,152(sp)
    80005fcc:	644a                	ld	s0,144(sp)
    80005fce:	64aa                	ld	s1,136(sp)
    80005fd0:	690a                	ld	s2,128(sp)
    80005fd2:	610d                	addi	sp,sp,160
    80005fd4:	8082                	ret
        end_op();
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	7c6080e7          	jalr	1990(ra) # 8000479c <end_op>
        return -1;
    80005fde:	557d                	li	a0,-1
    80005fe0:	b7ed                	j	80005fca <sys_chdir+0x7a>
        iunlockput(ip);
    80005fe2:	8526                	mv	a0,s1
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	ffa080e7          	jalr	-6(ra) # 80003fde <iunlockput>
        end_op();
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	7b0080e7          	jalr	1968(ra) # 8000479c <end_op>
        return -1;
    80005ff4:	557d                	li	a0,-1
    80005ff6:	bfd1                	j	80005fca <sys_chdir+0x7a>

0000000080005ff8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ff8:	7121                	addi	sp,sp,-448
    80005ffa:	ff06                	sd	ra,440(sp)
    80005ffc:	fb22                	sd	s0,432(sp)
    80005ffe:	f726                	sd	s1,424(sp)
    80006000:	f34a                	sd	s2,416(sp)
    80006002:	ef4e                	sd	s3,408(sp)
    80006004:	eb52                	sd	s4,400(sp)
    80006006:	0380                	addi	s0,sp,448
    char path[MAXPATH], *argv[MAXARG];
    int i;
    uint64 uargv, uarg;

    argaddr(1, &uargv);
    80006008:	e4840593          	addi	a1,s0,-440
    8000600c:	4505                	li	a0,1
    8000600e:	ffffd097          	auipc	ra,0xffffd
    80006012:	12e080e7          	jalr	302(ra) # 8000313c <argaddr>
    if (argstr(0, path, MAXPATH) < 0)
    80006016:	08000613          	li	a2,128
    8000601a:	f5040593          	addi	a1,s0,-176
    8000601e:	4501                	li	a0,0
    80006020:	ffffd097          	auipc	ra,0xffffd
    80006024:	13c080e7          	jalr	316(ra) # 8000315c <argstr>
    80006028:	87aa                	mv	a5,a0
    {
        return -1;
    8000602a:	557d                	li	a0,-1
    if (argstr(0, path, MAXPATH) < 0)
    8000602c:	0c07c263          	bltz	a5,800060f0 <sys_exec+0xf8>
    }
    memset(argv, 0, sizeof(argv));
    80006030:	10000613          	li	a2,256
    80006034:	4581                	li	a1,0
    80006036:	e5040513          	addi	a0,s0,-432
    8000603a:	ffffb097          	auipc	ra,0xffffb
    8000603e:	d50080e7          	jalr	-688(ra) # 80000d8a <memset>
    for (i = 0;; i++)
    {
        if (i >= NELEM(argv))
    80006042:	e5040493          	addi	s1,s0,-432
    memset(argv, 0, sizeof(argv));
    80006046:	89a6                	mv	s3,s1
    80006048:	4901                	li	s2,0
        if (i >= NELEM(argv))
    8000604a:	02000a13          	li	s4,32
        {
            goto bad;
        }
        if (fetchaddr(uargv + sizeof(uint64) * i, (uint64 *)&uarg) < 0)
    8000604e:	00391513          	slli	a0,s2,0x3
    80006052:	e4040593          	addi	a1,s0,-448
    80006056:	e4843783          	ld	a5,-440(s0)
    8000605a:	953e                	add	a0,a0,a5
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	022080e7          	jalr	34(ra) # 8000307e <fetchaddr>
    80006064:	02054a63          	bltz	a0,80006098 <sys_exec+0xa0>
        {
            goto bad;
        }
        if (uarg == 0)
    80006068:	e4043783          	ld	a5,-448(s0)
    8000606c:	c3b9                	beqz	a5,800060b2 <sys_exec+0xba>
        {
            argv[i] = 0;
            break;
        }
        argv[i] = kalloc();
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	ada080e7          	jalr	-1318(ra) # 80000b48 <kalloc>
    80006076:	85aa                	mv	a1,a0
    80006078:	00a9b023          	sd	a0,0(s3)
        if (argv[i] == 0)
    8000607c:	cd11                	beqz	a0,80006098 <sys_exec+0xa0>
            goto bad;
        if (fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000607e:	6605                	lui	a2,0x1
    80006080:	e4043503          	ld	a0,-448(s0)
    80006084:	ffffd097          	auipc	ra,0xffffd
    80006088:	04c080e7          	jalr	76(ra) # 800030d0 <fetchstr>
    8000608c:	00054663          	bltz	a0,80006098 <sys_exec+0xa0>
        if (i >= NELEM(argv))
    80006090:	0905                	addi	s2,s2,1
    80006092:	09a1                	addi	s3,s3,8
    80006094:	fb491de3          	bne	s2,s4,8000604e <sys_exec+0x56>
        dec_ref(argv[i]);

    return ret;

bad:
    for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006098:	f5040913          	addi	s2,s0,-176
    8000609c:	6088                	ld	a0,0(s1)
    8000609e:	c921                	beqz	a0,800060ee <sys_exec+0xf6>
        dec_ref(argv[i]);
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	360080e7          	jalr	864(ra) # 80001400 <dec_ref>
    for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a8:	04a1                	addi	s1,s1,8
    800060aa:	ff2499e3          	bne	s1,s2,8000609c <sys_exec+0xa4>
    return -1;
    800060ae:	557d                	li	a0,-1
    800060b0:	a081                	j	800060f0 <sys_exec+0xf8>
            argv[i] = 0;
    800060b2:	0009079b          	sext.w	a5,s2
    800060b6:	078e                	slli	a5,a5,0x3
    800060b8:	fd078793          	addi	a5,a5,-48
    800060bc:	97a2                	add	a5,a5,s0
    800060be:	e807b023          	sd	zero,-384(a5)
    int ret = exec(path, argv);
    800060c2:	e5040593          	addi	a1,s0,-432
    800060c6:	f5040513          	addi	a0,s0,-176
    800060ca:	fffff097          	auipc	ra,0xfffff
    800060ce:	192080e7          	jalr	402(ra) # 8000525c <exec>
    800060d2:	892a                	mv	s2,a0
    for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d4:	f5040993          	addi	s3,s0,-176
    800060d8:	6088                	ld	a0,0(s1)
    800060da:	c901                	beqz	a0,800060ea <sys_exec+0xf2>
        dec_ref(argv[i]);
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	324080e7          	jalr	804(ra) # 80001400 <dec_ref>
    for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060e4:	04a1                	addi	s1,s1,8
    800060e6:	ff3499e3          	bne	s1,s3,800060d8 <sys_exec+0xe0>
    return ret;
    800060ea:	854a                	mv	a0,s2
    800060ec:	a011                	j	800060f0 <sys_exec+0xf8>
    return -1;
    800060ee:	557d                	li	a0,-1
}
    800060f0:	70fa                	ld	ra,440(sp)
    800060f2:	745a                	ld	s0,432(sp)
    800060f4:	74ba                	ld	s1,424(sp)
    800060f6:	791a                	ld	s2,416(sp)
    800060f8:	69fa                	ld	s3,408(sp)
    800060fa:	6a5a                	ld	s4,400(sp)
    800060fc:	6139                	addi	sp,sp,448
    800060fe:	8082                	ret

0000000080006100 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006100:	7139                	addi	sp,sp,-64
    80006102:	fc06                	sd	ra,56(sp)
    80006104:	f822                	sd	s0,48(sp)
    80006106:	f426                	sd	s1,40(sp)
    80006108:	0080                	addi	s0,sp,64
    uint64 fdarray; // user pointer to array of two integers
    struct file *rf, *wf;
    int fd0, fd1;
    struct proc *p = myproc();
    8000610a:	ffffc097          	auipc	ra,0xffffc
    8000610e:	bc0080e7          	jalr	-1088(ra) # 80001cca <myproc>
    80006112:	84aa                	mv	s1,a0

    argaddr(0, &fdarray);
    80006114:	fd840593          	addi	a1,s0,-40
    80006118:	4501                	li	a0,0
    8000611a:	ffffd097          	auipc	ra,0xffffd
    8000611e:	022080e7          	jalr	34(ra) # 8000313c <argaddr>
    if (pipealloc(&rf, &wf) < 0)
    80006122:	fc840593          	addi	a1,s0,-56
    80006126:	fd040513          	addi	a0,s0,-48
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	de8080e7          	jalr	-536(ra) # 80004f12 <pipealloc>
        return -1;
    80006132:	57fd                	li	a5,-1
    if (pipealloc(&rf, &wf) < 0)
    80006134:	0c054463          	bltz	a0,800061fc <sys_pipe+0xfc>
    fd0 = -1;
    80006138:	fcf42223          	sw	a5,-60(s0)
    if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0)
    8000613c:	fd043503          	ld	a0,-48(s0)
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	524080e7          	jalr	1316(ra) # 80005664 <fdalloc>
    80006148:	fca42223          	sw	a0,-60(s0)
    8000614c:	08054b63          	bltz	a0,800061e2 <sys_pipe+0xe2>
    80006150:	fc843503          	ld	a0,-56(s0)
    80006154:	fffff097          	auipc	ra,0xfffff
    80006158:	510080e7          	jalr	1296(ra) # 80005664 <fdalloc>
    8000615c:	fca42023          	sw	a0,-64(s0)
    80006160:	06054863          	bltz	a0,800061d0 <sys_pipe+0xd0>
            p->ofile[fd0] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80006164:	4691                	li	a3,4
    80006166:	fc440613          	addi	a2,s0,-60
    8000616a:	fd843583          	ld	a1,-40(s0)
    8000616e:	68a8                	ld	a0,80(s1)
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	67e080e7          	jalr	1662(ra) # 800017ee <copyout>
    80006178:	02054063          	bltz	a0,80006198 <sys_pipe+0x98>
        copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0)
    8000617c:	4691                	li	a3,4
    8000617e:	fc040613          	addi	a2,s0,-64
    80006182:	fd843583          	ld	a1,-40(s0)
    80006186:	0591                	addi	a1,a1,4
    80006188:	68a8                	ld	a0,80(s1)
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	664080e7          	jalr	1636(ra) # 800017ee <copyout>
        p->ofile[fd1] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    return 0;
    80006192:	4781                	li	a5,0
    if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80006194:	06055463          	bgez	a0,800061fc <sys_pipe+0xfc>
        p->ofile[fd0] = 0;
    80006198:	fc442783          	lw	a5,-60(s0)
    8000619c:	07e9                	addi	a5,a5,26
    8000619e:	078e                	slli	a5,a5,0x3
    800061a0:	97a6                	add	a5,a5,s1
    800061a2:	0007b023          	sd	zero,0(a5)
        p->ofile[fd1] = 0;
    800061a6:	fc042783          	lw	a5,-64(s0)
    800061aa:	07e9                	addi	a5,a5,26
    800061ac:	078e                	slli	a5,a5,0x3
    800061ae:	94be                	add	s1,s1,a5
    800061b0:	0004b023          	sd	zero,0(s1)
        fileclose(rf);
    800061b4:	fd043503          	ld	a0,-48(s0)
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	a2e080e7          	jalr	-1490(ra) # 80004be6 <fileclose>
        fileclose(wf);
    800061c0:	fc843503          	ld	a0,-56(s0)
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	a22080e7          	jalr	-1502(ra) # 80004be6 <fileclose>
        return -1;
    800061cc:	57fd                	li	a5,-1
    800061ce:	a03d                	j	800061fc <sys_pipe+0xfc>
        if (fd0 >= 0)
    800061d0:	fc442783          	lw	a5,-60(s0)
    800061d4:	0007c763          	bltz	a5,800061e2 <sys_pipe+0xe2>
            p->ofile[fd0] = 0;
    800061d8:	07e9                	addi	a5,a5,26
    800061da:	078e                	slli	a5,a5,0x3
    800061dc:	97a6                	add	a5,a5,s1
    800061de:	0007b023          	sd	zero,0(a5)
        fileclose(rf);
    800061e2:	fd043503          	ld	a0,-48(s0)
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	a00080e7          	jalr	-1536(ra) # 80004be6 <fileclose>
        fileclose(wf);
    800061ee:	fc843503          	ld	a0,-56(s0)
    800061f2:	fffff097          	auipc	ra,0xfffff
    800061f6:	9f4080e7          	jalr	-1548(ra) # 80004be6 <fileclose>
        return -1;
    800061fa:	57fd                	li	a5,-1
}
    800061fc:	853e                	mv	a0,a5
    800061fe:	70e2                	ld	ra,56(sp)
    80006200:	7442                	ld	s0,48(sp)
    80006202:	74a2                	ld	s1,40(sp)
    80006204:	6121                	addi	sp,sp,64
    80006206:	8082                	ret
	...

0000000080006210 <kernelvec>:
    80006210:	7111                	addi	sp,sp,-256
    80006212:	e006                	sd	ra,0(sp)
    80006214:	e40a                	sd	sp,8(sp)
    80006216:	e80e                	sd	gp,16(sp)
    80006218:	ec12                	sd	tp,24(sp)
    8000621a:	f016                	sd	t0,32(sp)
    8000621c:	f41a                	sd	t1,40(sp)
    8000621e:	f81e                	sd	t2,48(sp)
    80006220:	fc22                	sd	s0,56(sp)
    80006222:	e0a6                	sd	s1,64(sp)
    80006224:	e4aa                	sd	a0,72(sp)
    80006226:	e8ae                	sd	a1,80(sp)
    80006228:	ecb2                	sd	a2,88(sp)
    8000622a:	f0b6                	sd	a3,96(sp)
    8000622c:	f4ba                	sd	a4,104(sp)
    8000622e:	f8be                	sd	a5,112(sp)
    80006230:	fcc2                	sd	a6,120(sp)
    80006232:	e146                	sd	a7,128(sp)
    80006234:	e54a                	sd	s2,136(sp)
    80006236:	e94e                	sd	s3,144(sp)
    80006238:	ed52                	sd	s4,152(sp)
    8000623a:	f156                	sd	s5,160(sp)
    8000623c:	f55a                	sd	s6,168(sp)
    8000623e:	f95e                	sd	s7,176(sp)
    80006240:	fd62                	sd	s8,184(sp)
    80006242:	e1e6                	sd	s9,192(sp)
    80006244:	e5ea                	sd	s10,200(sp)
    80006246:	e9ee                	sd	s11,208(sp)
    80006248:	edf2                	sd	t3,216(sp)
    8000624a:	f1f6                	sd	t4,224(sp)
    8000624c:	f5fa                	sd	t5,232(sp)
    8000624e:	f9fe                	sd	t6,240(sp)
    80006250:	cfbfc0ef          	jal	ra,80002f4a <kerneltrap>
    80006254:	6082                	ld	ra,0(sp)
    80006256:	6122                	ld	sp,8(sp)
    80006258:	61c2                	ld	gp,16(sp)
    8000625a:	7282                	ld	t0,32(sp)
    8000625c:	7322                	ld	t1,40(sp)
    8000625e:	73c2                	ld	t2,48(sp)
    80006260:	7462                	ld	s0,56(sp)
    80006262:	6486                	ld	s1,64(sp)
    80006264:	6526                	ld	a0,72(sp)
    80006266:	65c6                	ld	a1,80(sp)
    80006268:	6666                	ld	a2,88(sp)
    8000626a:	7686                	ld	a3,96(sp)
    8000626c:	7726                	ld	a4,104(sp)
    8000626e:	77c6                	ld	a5,112(sp)
    80006270:	7866                	ld	a6,120(sp)
    80006272:	688a                	ld	a7,128(sp)
    80006274:	692a                	ld	s2,136(sp)
    80006276:	69ca                	ld	s3,144(sp)
    80006278:	6a6a                	ld	s4,152(sp)
    8000627a:	7a8a                	ld	s5,160(sp)
    8000627c:	7b2a                	ld	s6,168(sp)
    8000627e:	7bca                	ld	s7,176(sp)
    80006280:	7c6a                	ld	s8,184(sp)
    80006282:	6c8e                	ld	s9,192(sp)
    80006284:	6d2e                	ld	s10,200(sp)
    80006286:	6dce                	ld	s11,208(sp)
    80006288:	6e6e                	ld	t3,216(sp)
    8000628a:	7e8e                	ld	t4,224(sp)
    8000628c:	7f2e                	ld	t5,232(sp)
    8000628e:	7fce                	ld	t6,240(sp)
    80006290:	6111                	addi	sp,sp,256
    80006292:	10200073          	sret
    80006296:	00000013          	nop
    8000629a:	00000013          	nop
    8000629e:	0001                	nop

00000000800062a0 <timervec>:
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	e10c                	sd	a1,0(a0)
    800062a6:	e510                	sd	a2,8(a0)
    800062a8:	e914                	sd	a3,16(a0)
    800062aa:	6d0c                	ld	a1,24(a0)
    800062ac:	7110                	ld	a2,32(a0)
    800062ae:	6194                	ld	a3,0(a1)
    800062b0:	96b2                	add	a3,a3,a2
    800062b2:	e194                	sd	a3,0(a1)
    800062b4:	4589                	li	a1,2
    800062b6:	14459073          	csrw	sip,a1
    800062ba:	6914                	ld	a3,16(a0)
    800062bc:	6510                	ld	a2,8(a0)
    800062be:	610c                	ld	a1,0(a0)
    800062c0:	34051573          	csrrw	a0,mscratch,a0
    800062c4:	30200073          	mret
	...

00000000800062ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ca:	1141                	addi	sp,sp,-16
    800062cc:	e422                	sd	s0,8(sp)
    800062ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062d0:	0c0007b7          	lui	a5,0xc000
    800062d4:	4705                	li	a4,1
    800062d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062d8:	c3d8                	sw	a4,4(a5)
}
    800062da:	6422                	ld	s0,8(sp)
    800062dc:	0141                	addi	sp,sp,16
    800062de:	8082                	ret

00000000800062e0 <plicinithart>:

void
plicinithart(void)
{
    800062e0:	1141                	addi	sp,sp,-16
    800062e2:	e406                	sd	ra,8(sp)
    800062e4:	e022                	sd	s0,0(sp)
    800062e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	9b6080e7          	jalr	-1610(ra) # 80001c9e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062f0:	0085171b          	slliw	a4,a0,0x8
    800062f4:	0c0027b7          	lui	a5,0xc002
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	40200713          	li	a4,1026
    800062fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006302:	00d5151b          	slliw	a0,a0,0xd
    80006306:	0c2017b7          	lui	a5,0xc201
    8000630a:	97aa                	add	a5,a5,a0
    8000630c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006310:	60a2                	ld	ra,8(sp)
    80006312:	6402                	ld	s0,0(sp)
    80006314:	0141                	addi	sp,sp,16
    80006316:	8082                	ret

0000000080006318 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006318:	1141                	addi	sp,sp,-16
    8000631a:	e406                	sd	ra,8(sp)
    8000631c:	e022                	sd	s0,0(sp)
    8000631e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006320:	ffffc097          	auipc	ra,0xffffc
    80006324:	97e080e7          	jalr	-1666(ra) # 80001c9e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006328:	00d5151b          	slliw	a0,a0,0xd
    8000632c:	0c2017b7          	lui	a5,0xc201
    80006330:	97aa                	add	a5,a5,a0
  return irq;
}
    80006332:	43c8                	lw	a0,4(a5)
    80006334:	60a2                	ld	ra,8(sp)
    80006336:	6402                	ld	s0,0(sp)
    80006338:	0141                	addi	sp,sp,16
    8000633a:	8082                	ret

000000008000633c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000633c:	1101                	addi	sp,sp,-32
    8000633e:	ec06                	sd	ra,24(sp)
    80006340:	e822                	sd	s0,16(sp)
    80006342:	e426                	sd	s1,8(sp)
    80006344:	1000                	addi	s0,sp,32
    80006346:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006348:	ffffc097          	auipc	ra,0xffffc
    8000634c:	956080e7          	jalr	-1706(ra) # 80001c9e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006350:	00d5151b          	slliw	a0,a0,0xd
    80006354:	0c2017b7          	lui	a5,0xc201
    80006358:	97aa                	add	a5,a5,a0
    8000635a:	c3c4                	sw	s1,4(a5)
}
    8000635c:	60e2                	ld	ra,24(sp)
    8000635e:	6442                	ld	s0,16(sp)
    80006360:	64a2                	ld	s1,8(sp)
    80006362:	6105                	addi	sp,sp,32
    80006364:	8082                	ret

0000000080006366 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006366:	1141                	addi	sp,sp,-16
    80006368:	e406                	sd	ra,8(sp)
    8000636a:	e022                	sd	s0,0(sp)
    8000636c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000636e:	479d                	li	a5,7
    80006370:	04a7cc63          	blt	a5,a0,800063c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006374:	0012c797          	auipc	a5,0x12c
    80006378:	acc78793          	addi	a5,a5,-1332 # 80131e40 <disk>
    8000637c:	97aa                	add	a5,a5,a0
    8000637e:	0187c783          	lbu	a5,24(a5)
    80006382:	ebb9                	bnez	a5,800063d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006384:	00451693          	slli	a3,a0,0x4
    80006388:	0012c797          	auipc	a5,0x12c
    8000638c:	ab878793          	addi	a5,a5,-1352 # 80131e40 <disk>
    80006390:	6398                	ld	a4,0(a5)
    80006392:	9736                	add	a4,a4,a3
    80006394:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006398:	6398                	ld	a4,0(a5)
    8000639a:	9736                	add	a4,a4,a3
    8000639c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063a8:	97aa                	add	a5,a5,a0
    800063aa:	4705                	li	a4,1
    800063ac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063b0:	0012c517          	auipc	a0,0x12c
    800063b4:	aa850513          	addi	a0,a0,-1368 # 80131e58 <disk+0x18>
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	0de080e7          	jalr	222(ra) # 80002496 <wakeup>
}
    800063c0:	60a2                	ld	ra,8(sp)
    800063c2:	6402                	ld	s0,0(sp)
    800063c4:	0141                	addi	sp,sp,16
    800063c6:	8082                	ret
    panic("free_desc 1");
    800063c8:	00002517          	auipc	a0,0x2
    800063cc:	57850513          	addi	a0,a0,1400 # 80008940 <syscalls+0x318>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	16c080e7          	jalr	364(ra) # 8000053c <panic>
    panic("free_desc 2");
    800063d8:	00002517          	auipc	a0,0x2
    800063dc:	57850513          	addi	a0,a0,1400 # 80008950 <syscalls+0x328>
    800063e0:	ffffa097          	auipc	ra,0xffffa
    800063e4:	15c080e7          	jalr	348(ra) # 8000053c <panic>

00000000800063e8 <virtio_disk_init>:
{
    800063e8:	1101                	addi	sp,sp,-32
    800063ea:	ec06                	sd	ra,24(sp)
    800063ec:	e822                	sd	s0,16(sp)
    800063ee:	e426                	sd	s1,8(sp)
    800063f0:	e04a                	sd	s2,0(sp)
    800063f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063f4:	00002597          	auipc	a1,0x2
    800063f8:	56c58593          	addi	a1,a1,1388 # 80008960 <syscalls+0x338>
    800063fc:	0012c517          	auipc	a0,0x12c
    80006400:	b6c50513          	addi	a0,a0,-1172 # 80131f68 <disk+0x128>
    80006404:	ffffa097          	auipc	ra,0xffffa
    80006408:	7fa080e7          	jalr	2042(ra) # 80000bfe <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000640c:	100017b7          	lui	a5,0x10001
    80006410:	4398                	lw	a4,0(a5)
    80006412:	2701                	sext.w	a4,a4
    80006414:	747277b7          	lui	a5,0x74727
    80006418:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000641c:	14f71b63          	bne	a4,a5,80006572 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006420:	100017b7          	lui	a5,0x10001
    80006424:	43dc                	lw	a5,4(a5)
    80006426:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006428:	4709                	li	a4,2
    8000642a:	14e79463          	bne	a5,a4,80006572 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000642e:	100017b7          	lui	a5,0x10001
    80006432:	479c                	lw	a5,8(a5)
    80006434:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006436:	12e79e63          	bne	a5,a4,80006572 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000643a:	100017b7          	lui	a5,0x10001
    8000643e:	47d8                	lw	a4,12(a5)
    80006440:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006442:	554d47b7          	lui	a5,0x554d4
    80006446:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000644a:	12f71463          	bne	a4,a5,80006572 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644e:	100017b7          	lui	a5,0x10001
    80006452:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006456:	4705                	li	a4,1
    80006458:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000645a:	470d                	li	a4,3
    8000645c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000645e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006460:	c7ffe6b7          	lui	a3,0xc7ffe
    80006464:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47ecc7df>
    80006468:	8f75                	and	a4,a4,a3
    8000646a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646c:	472d                	li	a4,11
    8000646e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006470:	5bbc                	lw	a5,112(a5)
    80006472:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006476:	8ba1                	andi	a5,a5,8
    80006478:	10078563          	beqz	a5,80006582 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000647c:	100017b7          	lui	a5,0x10001
    80006480:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006484:	43fc                	lw	a5,68(a5)
    80006486:	2781                	sext.w	a5,a5
    80006488:	10079563          	bnez	a5,80006592 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000648c:	100017b7          	lui	a5,0x10001
    80006490:	5bdc                	lw	a5,52(a5)
    80006492:	2781                	sext.w	a5,a5
  if(max == 0)
    80006494:	10078763          	beqz	a5,800065a2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006498:	471d                	li	a4,7
    8000649a:	10f77c63          	bgeu	a4,a5,800065b2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	6aa080e7          	jalr	1706(ra) # 80000b48 <kalloc>
    800064a6:	0012c497          	auipc	s1,0x12c
    800064aa:	99a48493          	addi	s1,s1,-1638 # 80131e40 <disk>
    800064ae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	698080e7          	jalr	1688(ra) # 80000b48 <kalloc>
    800064b8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	68e080e7          	jalr	1678(ra) # 80000b48 <kalloc>
    800064c2:	87aa                	mv	a5,a0
    800064c4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064c6:	6088                	ld	a0,0(s1)
    800064c8:	cd6d                	beqz	a0,800065c2 <virtio_disk_init+0x1da>
    800064ca:	0012c717          	auipc	a4,0x12c
    800064ce:	97e73703          	ld	a4,-1666(a4) # 80131e48 <disk+0x8>
    800064d2:	cb65                	beqz	a4,800065c2 <virtio_disk_init+0x1da>
    800064d4:	c7fd                	beqz	a5,800065c2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800064d6:	6605                	lui	a2,0x1
    800064d8:	4581                	li	a1,0
    800064da:	ffffb097          	auipc	ra,0xffffb
    800064de:	8b0080e7          	jalr	-1872(ra) # 80000d8a <memset>
  memset(disk.avail, 0, PGSIZE);
    800064e2:	0012c497          	auipc	s1,0x12c
    800064e6:	95e48493          	addi	s1,s1,-1698 # 80131e40 <disk>
    800064ea:	6605                	lui	a2,0x1
    800064ec:	4581                	li	a1,0
    800064ee:	6488                	ld	a0,8(s1)
    800064f0:	ffffb097          	auipc	ra,0xffffb
    800064f4:	89a080e7          	jalr	-1894(ra) # 80000d8a <memset>
  memset(disk.used, 0, PGSIZE);
    800064f8:	6605                	lui	a2,0x1
    800064fa:	4581                	li	a1,0
    800064fc:	6888                	ld	a0,16(s1)
    800064fe:	ffffb097          	auipc	ra,0xffffb
    80006502:	88c080e7          	jalr	-1908(ra) # 80000d8a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006506:	100017b7          	lui	a5,0x10001
    8000650a:	4721                	li	a4,8
    8000650c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000650e:	4098                	lw	a4,0(s1)
    80006510:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006514:	40d8                	lw	a4,4(s1)
    80006516:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000651a:	6498                	ld	a4,8(s1)
    8000651c:	0007069b          	sext.w	a3,a4
    80006520:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006524:	9701                	srai	a4,a4,0x20
    80006526:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000652a:	6898                	ld	a4,16(s1)
    8000652c:	0007069b          	sext.w	a3,a4
    80006530:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006534:	9701                	srai	a4,a4,0x20
    80006536:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000653a:	4705                	li	a4,1
    8000653c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000653e:	00e48c23          	sb	a4,24(s1)
    80006542:	00e48ca3          	sb	a4,25(s1)
    80006546:	00e48d23          	sb	a4,26(s1)
    8000654a:	00e48da3          	sb	a4,27(s1)
    8000654e:	00e48e23          	sb	a4,28(s1)
    80006552:	00e48ea3          	sb	a4,29(s1)
    80006556:	00e48f23          	sb	a4,30(s1)
    8000655a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000655e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006562:	0727a823          	sw	s2,112(a5)
}
    80006566:	60e2                	ld	ra,24(sp)
    80006568:	6442                	ld	s0,16(sp)
    8000656a:	64a2                	ld	s1,8(sp)
    8000656c:	6902                	ld	s2,0(sp)
    8000656e:	6105                	addi	sp,sp,32
    80006570:	8082                	ret
    panic("could not find virtio disk");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	3fe50513          	addi	a0,a0,1022 # 80008970 <syscalls+0x348>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc2080e7          	jalr	-62(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	40e50513          	addi	a0,a0,1038 # 80008990 <syscalls+0x368>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb2080e7          	jalr	-78(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006592:	00002517          	auipc	a0,0x2
    80006596:	41e50513          	addi	a0,a0,1054 # 800089b0 <syscalls+0x388>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	fa2080e7          	jalr	-94(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	42e50513          	addi	a0,a0,1070 # 800089d0 <syscalls+0x3a8>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f92080e7          	jalr	-110(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	43e50513          	addi	a0,a0,1086 # 800089f0 <syscalls+0x3c8>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	44e50513          	addi	a0,a0,1102 # 80008a10 <syscalls+0x3e8>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>

00000000800065d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d2:	7159                	addi	sp,sp,-112
    800065d4:	f486                	sd	ra,104(sp)
    800065d6:	f0a2                	sd	s0,96(sp)
    800065d8:	eca6                	sd	s1,88(sp)
    800065da:	e8ca                	sd	s2,80(sp)
    800065dc:	e4ce                	sd	s3,72(sp)
    800065de:	e0d2                	sd	s4,64(sp)
    800065e0:	fc56                	sd	s5,56(sp)
    800065e2:	f85a                	sd	s6,48(sp)
    800065e4:	f45e                	sd	s7,40(sp)
    800065e6:	f062                	sd	s8,32(sp)
    800065e8:	ec66                	sd	s9,24(sp)
    800065ea:	e86a                	sd	s10,16(sp)
    800065ec:	1880                	addi	s0,sp,112
    800065ee:	8a2a                	mv	s4,a0
    800065f0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f2:	00c52c83          	lw	s9,12(a0)
    800065f6:	001c9c9b          	slliw	s9,s9,0x1
    800065fa:	1c82                	slli	s9,s9,0x20
    800065fc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006600:	0012c517          	auipc	a0,0x12c
    80006604:	96850513          	addi	a0,a0,-1688 # 80131f68 <disk+0x128>
    80006608:	ffffa097          	auipc	ra,0xffffa
    8000660c:	686080e7          	jalr	1670(ra) # 80000c8e <acquire>
  for(int i = 0; i < 3; i++){
    80006610:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006612:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006614:	0012cb17          	auipc	s6,0x12c
    80006618:	82cb0b13          	addi	s6,s6,-2004 # 80131e40 <disk>
  for(int i = 0; i < 3; i++){
    8000661c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000661e:	0012cc17          	auipc	s8,0x12c
    80006622:	94ac0c13          	addi	s8,s8,-1718 # 80131f68 <disk+0x128>
    80006626:	a095                	j	8000668a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006628:	00fb0733          	add	a4,s6,a5
    8000662c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006630:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006632:	0207c563          	bltz	a5,8000665c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006636:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006638:	0591                	addi	a1,a1,4
    8000663a:	05560d63          	beq	a2,s5,80006694 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000663e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006640:	0012c717          	auipc	a4,0x12c
    80006644:	80070713          	addi	a4,a4,-2048 # 80131e40 <disk>
    80006648:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000664a:	01874683          	lbu	a3,24(a4)
    8000664e:	fee9                	bnez	a3,80006628 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006650:	2785                	addiw	a5,a5,1
    80006652:	0705                	addi	a4,a4,1
    80006654:	fe979be3          	bne	a5,s1,8000664a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006658:	57fd                	li	a5,-1
    8000665a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000665c:	00c05e63          	blez	a2,80006678 <virtio_disk_rw+0xa6>
    80006660:	060a                	slli	a2,a2,0x2
    80006662:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006666:	0009a503          	lw	a0,0(s3)
    8000666a:	00000097          	auipc	ra,0x0
    8000666e:	cfc080e7          	jalr	-772(ra) # 80006366 <free_desc>
      for(int j = 0; j < i; j++)
    80006672:	0991                	addi	s3,s3,4
    80006674:	ffa999e3          	bne	s3,s10,80006666 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006678:	85e2                	mv	a1,s8
    8000667a:	0012b517          	auipc	a0,0x12b
    8000667e:	7de50513          	addi	a0,a0,2014 # 80131e58 <disk+0x18>
    80006682:	ffffc097          	auipc	ra,0xffffc
    80006686:	db0080e7          	jalr	-592(ra) # 80002432 <sleep>
  for(int i = 0; i < 3; i++){
    8000668a:	f9040993          	addi	s3,s0,-112
{
    8000668e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006690:	864a                	mv	a2,s2
    80006692:	b775                	j	8000663e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006694:	f9042503          	lw	a0,-112(s0)
    80006698:	00a50713          	addi	a4,a0,10
    8000669c:	0712                	slli	a4,a4,0x4

  if(write)
    8000669e:	0012b797          	auipc	a5,0x12b
    800066a2:	7a278793          	addi	a5,a5,1954 # 80131e40 <disk>
    800066a6:	00e786b3          	add	a3,a5,a4
    800066aa:	01703633          	snez	a2,s7
    800066ae:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066b0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066b4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066b8:	f6070613          	addi	a2,a4,-160
    800066bc:	6394                	ld	a3,0(a5)
    800066be:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066c0:	00870593          	addi	a1,a4,8
    800066c4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066c6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066c8:	0007b803          	ld	a6,0(a5)
    800066cc:	9642                	add	a2,a2,a6
    800066ce:	46c1                	li	a3,16
    800066d0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066d2:	4585                	li	a1,1
    800066d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800066d8:	f9442683          	lw	a3,-108(s0)
    800066dc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066e0:	0692                	slli	a3,a3,0x4
    800066e2:	9836                	add	a6,a6,a3
    800066e4:	058a0613          	addi	a2,s4,88
    800066e8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800066ec:	0007b803          	ld	a6,0(a5)
    800066f0:	96c2                	add	a3,a3,a6
    800066f2:	40000613          	li	a2,1024
    800066f6:	c690                	sw	a2,8(a3)
  if(write)
    800066f8:	001bb613          	seqz	a2,s7
    800066fc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006700:	00166613          	ori	a2,a2,1
    80006704:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006708:	f9842603          	lw	a2,-104(s0)
    8000670c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006710:	00250693          	addi	a3,a0,2
    80006714:	0692                	slli	a3,a3,0x4
    80006716:	96be                	add	a3,a3,a5
    80006718:	58fd                	li	a7,-1
    8000671a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000671e:	0612                	slli	a2,a2,0x4
    80006720:	9832                	add	a6,a6,a2
    80006722:	f9070713          	addi	a4,a4,-112
    80006726:	973e                	add	a4,a4,a5
    80006728:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000672c:	6398                	ld	a4,0(a5)
    8000672e:	9732                	add	a4,a4,a2
    80006730:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006732:	4609                	li	a2,2
    80006734:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006738:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000673c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006740:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006744:	6794                	ld	a3,8(a5)
    80006746:	0026d703          	lhu	a4,2(a3)
    8000674a:	8b1d                	andi	a4,a4,7
    8000674c:	0706                	slli	a4,a4,0x1
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006754:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006758:	6798                	ld	a4,8(a5)
    8000675a:	00275783          	lhu	a5,2(a4)
    8000675e:	2785                	addiw	a5,a5,1
    80006760:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006764:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006768:	100017b7          	lui	a5,0x10001
    8000676c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006770:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006774:	0012b917          	auipc	s2,0x12b
    80006778:	7f490913          	addi	s2,s2,2036 # 80131f68 <disk+0x128>
  while(b->disk == 1) {
    8000677c:	4485                	li	s1,1
    8000677e:	00b79c63          	bne	a5,a1,80006796 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006782:	85ca                	mv	a1,s2
    80006784:	8552                	mv	a0,s4
    80006786:	ffffc097          	auipc	ra,0xffffc
    8000678a:	cac080e7          	jalr	-852(ra) # 80002432 <sleep>
  while(b->disk == 1) {
    8000678e:	004a2783          	lw	a5,4(s4)
    80006792:	fe9788e3          	beq	a5,s1,80006782 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006796:	f9042903          	lw	s2,-112(s0)
    8000679a:	00290713          	addi	a4,s2,2
    8000679e:	0712                	slli	a4,a4,0x4
    800067a0:	0012b797          	auipc	a5,0x12b
    800067a4:	6a078793          	addi	a5,a5,1696 # 80131e40 <disk>
    800067a8:	97ba                	add	a5,a5,a4
    800067aa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067ae:	0012b997          	auipc	s3,0x12b
    800067b2:	69298993          	addi	s3,s3,1682 # 80131e40 <disk>
    800067b6:	00491713          	slli	a4,s2,0x4
    800067ba:	0009b783          	ld	a5,0(s3)
    800067be:	97ba                	add	a5,a5,a4
    800067c0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067c4:	854a                	mv	a0,s2
    800067c6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ca:	00000097          	auipc	ra,0x0
    800067ce:	b9c080e7          	jalr	-1124(ra) # 80006366 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067d2:	8885                	andi	s1,s1,1
    800067d4:	f0ed                	bnez	s1,800067b6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067d6:	0012b517          	auipc	a0,0x12b
    800067da:	79250513          	addi	a0,a0,1938 # 80131f68 <disk+0x128>
    800067de:	ffffa097          	auipc	ra,0xffffa
    800067e2:	564080e7          	jalr	1380(ra) # 80000d42 <release>
}
    800067e6:	70a6                	ld	ra,104(sp)
    800067e8:	7406                	ld	s0,96(sp)
    800067ea:	64e6                	ld	s1,88(sp)
    800067ec:	6946                	ld	s2,80(sp)
    800067ee:	69a6                	ld	s3,72(sp)
    800067f0:	6a06                	ld	s4,64(sp)
    800067f2:	7ae2                	ld	s5,56(sp)
    800067f4:	7b42                	ld	s6,48(sp)
    800067f6:	7ba2                	ld	s7,40(sp)
    800067f8:	7c02                	ld	s8,32(sp)
    800067fa:	6ce2                	ld	s9,24(sp)
    800067fc:	6d42                	ld	s10,16(sp)
    800067fe:	6165                	addi	sp,sp,112
    80006800:	8082                	ret

0000000080006802 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006802:	1101                	addi	sp,sp,-32
    80006804:	ec06                	sd	ra,24(sp)
    80006806:	e822                	sd	s0,16(sp)
    80006808:	e426                	sd	s1,8(sp)
    8000680a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000680c:	0012b497          	auipc	s1,0x12b
    80006810:	63448493          	addi	s1,s1,1588 # 80131e40 <disk>
    80006814:	0012b517          	auipc	a0,0x12b
    80006818:	75450513          	addi	a0,a0,1876 # 80131f68 <disk+0x128>
    8000681c:	ffffa097          	auipc	ra,0xffffa
    80006820:	472080e7          	jalr	1138(ra) # 80000c8e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006824:	10001737          	lui	a4,0x10001
    80006828:	533c                	lw	a5,96(a4)
    8000682a:	8b8d                	andi	a5,a5,3
    8000682c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000682e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006832:	689c                	ld	a5,16(s1)
    80006834:	0204d703          	lhu	a4,32(s1)
    80006838:	0027d783          	lhu	a5,2(a5)
    8000683c:	04f70863          	beq	a4,a5,8000688c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006840:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006844:	6898                	ld	a4,16(s1)
    80006846:	0204d783          	lhu	a5,32(s1)
    8000684a:	8b9d                	andi	a5,a5,7
    8000684c:	078e                	slli	a5,a5,0x3
    8000684e:	97ba                	add	a5,a5,a4
    80006850:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006852:	00278713          	addi	a4,a5,2
    80006856:	0712                	slli	a4,a4,0x4
    80006858:	9726                	add	a4,a4,s1
    8000685a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000685e:	e721                	bnez	a4,800068a6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006860:	0789                	addi	a5,a5,2
    80006862:	0792                	slli	a5,a5,0x4
    80006864:	97a6                	add	a5,a5,s1
    80006866:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006868:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000686c:	ffffc097          	auipc	ra,0xffffc
    80006870:	c2a080e7          	jalr	-982(ra) # 80002496 <wakeup>

    disk.used_idx += 1;
    80006874:	0204d783          	lhu	a5,32(s1)
    80006878:	2785                	addiw	a5,a5,1
    8000687a:	17c2                	slli	a5,a5,0x30
    8000687c:	93c1                	srli	a5,a5,0x30
    8000687e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006882:	6898                	ld	a4,16(s1)
    80006884:	00275703          	lhu	a4,2(a4)
    80006888:	faf71ce3          	bne	a4,a5,80006840 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000688c:	0012b517          	auipc	a0,0x12b
    80006890:	6dc50513          	addi	a0,a0,1756 # 80131f68 <disk+0x128>
    80006894:	ffffa097          	auipc	ra,0xffffa
    80006898:	4ae080e7          	jalr	1198(ra) # 80000d42 <release>
}
    8000689c:	60e2                	ld	ra,24(sp)
    8000689e:	6442                	ld	s0,16(sp)
    800068a0:	64a2                	ld	s1,8(sp)
    800068a2:	6105                	addi	sp,sp,32
    800068a4:	8082                	ret
      panic("virtio_disk_intr status");
    800068a6:	00002517          	auipc	a0,0x2
    800068aa:	18250513          	addi	a0,a0,386 # 80008a28 <syscalls+0x400>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	c8e080e7          	jalr	-882(ra) # 8000053c <panic>
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
