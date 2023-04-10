
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5013103          	ld	sp,-1456(sp) # 80008a50 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	a6e70713          	addi	a4,a4,-1426 # 80008ac0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	16c78793          	addi	a5,a5,364 # 800061d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd48cf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	eda78793          	addi	a5,a5,-294 # 80000f88 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	690080e7          	jalr	1680(ra) # 800027bc <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
            break;
        uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	7a6080e7          	jalr	1958(ra) # 800008e2 <uartputc>
    for (i = 0; i < n; i++)
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000188:	00060b9b          	sext.w	s7,a2
    acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	a7450513          	addi	a0,a0,-1420 # 80010c00 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b4a080e7          	jalr	-1206(ra) # 80000cde <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	a6448493          	addi	s1,s1,-1436 # 80010c00 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	af290913          	addi	s2,s2,-1294 # 80010c98 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001ae:	4c91                	li	s9,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001b2:	4da9                	li	s11,10
    while (n > 0)
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
        while (cons.r == cons.w)
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
            if (killed(myproc()))
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	a36080e7          	jalr	-1482(ra) # 80001bfa <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	43a080e7          	jalr	1082(ra) # 80002606 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
            sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	184080e7          	jalr	388(ra) # 8000235e <sleep>
        while (cons.r == cons.w)
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
        if (c == C('D'))
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
        cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	550080e7          	jalr	1360(ra) # 80002766 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
        dst++;
    80000222:	0a85                	addi	s5,s5,1
        --n;
    80000224:	3a7d                	addiw	s4,s4,-1
        if (c == '\n')
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	9d650513          	addi	a0,a0,-1578 # 80010c00 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	b60080e7          	jalr	-1184(ra) # 80000d92 <release>

    return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
                release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	9c050513          	addi	a0,a0,-1600 # 80010c00 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	b4a080e7          	jalr	-1206(ra) # 80000d92 <release>
                return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
            if (n < target)
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
                cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	a2f72023          	sw	a5,-1504(a4) # 80010c98 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
        uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	576080e7          	jalr	1398(ra) # 80000808 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
        uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	564080e7          	jalr	1380(ra) # 80000808 <uartputc_sync>
        uartputc_sync(' ');
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	558080e7          	jalr	1368(ra) # 80000808 <uartputc_sync>
        uartputc_sync('\b');
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	54e080e7          	jalr	1358(ra) # 80000808 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	92e50513          	addi	a0,a0,-1746 # 80010c00 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	a04080e7          	jalr	-1532(ra) # 80000cde <acquire>

    switch (c)
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	51a080e7          	jalr	1306(ra) # 80002812 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	90050513          	addi	a0,a0,-1792 # 80010c00 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	a8a080e7          	jalr	-1398(ra) # 80000d92 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
    switch (c)
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000324:	00011717          	auipc	a4,0x11
    80000328:	8dc70713          	addi	a4,a4,-1828 # 80010c00 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
            consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	8b278793          	addi	a5,a5,-1870 # 80010c00 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	91c7a783          	lw	a5,-1764(a5) # 80010c98 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	87070713          	addi	a4,a4,-1936 # 80010c00 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	86048493          	addi	s1,s1,-1952 # 80010c00 <cons>
        while (cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
            cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
        while (cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	82470713          	addi	a4,a4,-2012 # 80010c00 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
            cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8af72723          	sw	a5,-1874(a4) # 80010ca0 <cons+0xa0>
            consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
            consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	7e878793          	addi	a5,a5,2024 # 80010c00 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	86c7a023          	sw	a2,-1952(a5) # 80010c9c <cons+0x9c>
                wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	85450513          	addi	a0,a0,-1964 # 80010c98 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	f76080e7          	jalr	-138(ra) # 800023c2 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bc258593          	addi	a1,a1,-1086 # 80008020 <__func__.1506+0x18>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	79a50513          	addi	a0,a0,1946 # 80010c00 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	7e0080e7          	jalr	2016(ra) # 80000c4e <initlock>

    uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	342080e7          	jalr	834(ra) # 800007b8 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    8000047e:	00029797          	auipc	a5,0x29
    80000482:	91a78793          	addi	a5,a5,-1766 # 80028d98 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
        x = -xx;
    else
        x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004bc:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b9060613          	addi	a2,a2,-1136 # 80008050 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

    if (sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
        buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
    while (--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
        x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
        x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    80000544:	711d                	addi	sp,sp,-96
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
    80000550:	e40c                	sd	a1,8(s0)
    80000552:	e810                	sd	a2,16(s0)
    80000554:	ec14                	sd	a3,24(s0)
    80000556:	f018                	sd	a4,32(s0)
    80000558:	f41c                	sd	a5,40(s0)
    8000055a:	03043823          	sd	a6,48(s0)
    8000055e:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    80000562:	00010797          	auipc	a5,0x10
    80000566:	7407af23          	sw	zero,1886(a5) # 80010cc0 <pr+0x18>
    printf("panic: ");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	abe50513          	addi	a0,a0,-1346 # 80008028 <__func__.1506+0x20>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	02e080e7          	jalr	46(ra) # 800005a0 <printf>
    printf(s);
    8000057a:	8526                	mv	a0,s1
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	024080e7          	jalr	36(ra) # 800005a0 <printf>
    printf("\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	b0450513          	addi	a0,a0,-1276 # 80008088 <digits+0x38>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	014080e7          	jalr	20(ra) # 800005a0 <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000594:	4785                	li	a5,1
    80000596:	00008717          	auipc	a4,0x8
    8000059a:	4cf72d23          	sw	a5,1242(a4) # 80008a70 <panicked>
    for (;;)
    8000059e:	a001                	j	8000059e <panic+0x5a>

00000000800005a0 <printf>:
{
    800005a0:	7131                	addi	sp,sp,-192
    800005a2:	fc86                	sd	ra,120(sp)
    800005a4:	f8a2                	sd	s0,112(sp)
    800005a6:	f4a6                	sd	s1,104(sp)
    800005a8:	f0ca                	sd	s2,96(sp)
    800005aa:	ecce                	sd	s3,88(sp)
    800005ac:	e8d2                	sd	s4,80(sp)
    800005ae:	e4d6                	sd	s5,72(sp)
    800005b0:	e0da                	sd	s6,64(sp)
    800005b2:	fc5e                	sd	s7,56(sp)
    800005b4:	f862                	sd	s8,48(sp)
    800005b6:	f466                	sd	s9,40(sp)
    800005b8:	f06a                	sd	s10,32(sp)
    800005ba:	ec6e                	sd	s11,24(sp)
    800005bc:	0100                	addi	s0,sp,128
    800005be:	8a2a                	mv	s4,a0
    800005c0:	e40c                	sd	a1,8(s0)
    800005c2:	e810                	sd	a2,16(s0)
    800005c4:	ec14                	sd	a3,24(s0)
    800005c6:	f018                	sd	a4,32(s0)
    800005c8:	f41c                	sd	a5,40(s0)
    800005ca:	03043823          	sd	a6,48(s0)
    800005ce:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005d2:	00010d97          	auipc	s11,0x10
    800005d6:	6eedad83          	lw	s11,1774(s11) # 80010cc0 <pr+0x18>
    if (locking)
    800005da:	020d9b63          	bnez	s11,80000610 <printf+0x70>
    if (fmt == 0)
    800005de:	040a0263          	beqz	s4,80000622 <printf+0x82>
    va_start(ap, fmt);
    800005e2:	00840793          	addi	a5,s0,8
    800005e6:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005ea:	000a4503          	lbu	a0,0(s4)
    800005ee:	16050263          	beqz	a0,80000752 <printf+0x1b2>
    800005f2:	4481                	li	s1,0
        if (c != '%')
    800005f4:	02500a93          	li	s5,37
        switch (c)
    800005f8:	07000b13          	li	s6,112
    consputc('x');
    800005fc:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fe:	00008b97          	auipc	s7,0x8
    80000602:	a52b8b93          	addi	s7,s7,-1454 # 80008050 <digits>
        switch (c)
    80000606:	07300c93          	li	s9,115
    8000060a:	06400c13          	li	s8,100
    8000060e:	a82d                	j	80000648 <printf+0xa8>
        acquire(&pr.lock);
    80000610:	00010517          	auipc	a0,0x10
    80000614:	69850513          	addi	a0,a0,1688 # 80010ca8 <pr>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	6c6080e7          	jalr	1734(ra) # 80000cde <acquire>
    80000620:	bf7d                	j	800005de <printf+0x3e>
        panic("null fmt");
    80000622:	00008517          	auipc	a0,0x8
    80000626:	a1650513          	addi	a0,a0,-1514 # 80008038 <__func__.1506+0x30>
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	f1a080e7          	jalr	-230(ra) # 80000544 <panic>
            consputc(c);
    80000632:	00000097          	auipc	ra,0x0
    80000636:	c50080e7          	jalr	-944(ra) # 80000282 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c503          	lbu	a0,0(a5)
    80000644:	10050763          	beqz	a0,80000752 <printf+0x1b2>
        if (c != '%')
    80000648:	ff5515e3          	bne	a0,s5,80000632 <printf+0x92>
        c = fmt[++i] & 0xff;
    8000064c:	2485                	addiw	s1,s1,1
    8000064e:	009a07b3          	add	a5,s4,s1
    80000652:	0007c783          	lbu	a5,0(a5)
    80000656:	0007891b          	sext.w	s2,a5
        if (c == 0)
    8000065a:	cfe5                	beqz	a5,80000752 <printf+0x1b2>
        switch (c)
    8000065c:	05678a63          	beq	a5,s6,800006b0 <printf+0x110>
    80000660:	02fb7663          	bgeu	s6,a5,8000068c <printf+0xec>
    80000664:	09978963          	beq	a5,s9,800006f6 <printf+0x156>
    80000668:	07800713          	li	a4,120
    8000066c:	0ce79863          	bne	a5,a4,8000073c <printf+0x19c>
            printint(va_arg(ap, int), 16, 1);
    80000670:	f8843783          	ld	a5,-120(s0)
    80000674:	00878713          	addi	a4,a5,8
    80000678:	f8e43423          	sd	a4,-120(s0)
    8000067c:	4605                	li	a2,1
    8000067e:	85ea                	mv	a1,s10
    80000680:	4388                	lw	a0,0(a5)
    80000682:	00000097          	auipc	ra,0x0
    80000686:	e20080e7          	jalr	-480(ra) # 800004a2 <printint>
            break;
    8000068a:	bf45                	j	8000063a <printf+0x9a>
        switch (c)
    8000068c:	0b578263          	beq	a5,s5,80000730 <printf+0x190>
    80000690:	0b879663          	bne	a5,s8,8000073c <printf+0x19c>
            printint(va_arg(ap, int), 10, 1);
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	4605                	li	a2,1
    800006a2:	45a9                	li	a1,10
    800006a4:	4388                	lw	a0,0(a5)
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	dfc080e7          	jalr	-516(ra) # 800004a2 <printint>
            break;
    800006ae:	b771                	j	8000063a <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006b0:	f8843783          	ld	a5,-120(s0)
    800006b4:	00878713          	addi	a4,a5,8
    800006b8:	f8e43423          	sd	a4,-120(s0)
    800006bc:	0007b983          	ld	s3,0(a5)
    consputc('0');
    800006c0:	03000513          	li	a0,48
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bbe080e7          	jalr	-1090(ra) # 80000282 <consputc>
    consputc('x');
    800006cc:	07800513          	li	a0,120
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb2080e7          	jalr	-1102(ra) # 80000282 <consputc>
    800006d8:	896a                	mv	s2,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006da:	03c9d793          	srli	a5,s3,0x3c
    800006de:	97de                	add	a5,a5,s7
    800006e0:	0007c503          	lbu	a0,0(a5)
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	b9e080e7          	jalr	-1122(ra) # 80000282 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ec:	0992                	slli	s3,s3,0x4
    800006ee:	397d                	addiw	s2,s2,-1
    800006f0:	fe0915e3          	bnez	s2,800006da <printf+0x13a>
    800006f4:	b799                	j	8000063a <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006f6:	f8843783          	ld	a5,-120(s0)
    800006fa:	00878713          	addi	a4,a5,8
    800006fe:	f8e43423          	sd	a4,-120(s0)
    80000702:	0007b903          	ld	s2,0(a5)
    80000706:	00090e63          	beqz	s2,80000722 <printf+0x182>
            for (; *s; s++)
    8000070a:	00094503          	lbu	a0,0(s2)
    8000070e:	d515                	beqz	a0,8000063a <printf+0x9a>
                consputc(*s);
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b72080e7          	jalr	-1166(ra) # 80000282 <consputc>
            for (; *s; s++)
    80000718:	0905                	addi	s2,s2,1
    8000071a:	00094503          	lbu	a0,0(s2)
    8000071e:	f96d                	bnez	a0,80000710 <printf+0x170>
    80000720:	bf29                	j	8000063a <printf+0x9a>
                s = "(null)";
    80000722:	00008917          	auipc	s2,0x8
    80000726:	90e90913          	addi	s2,s2,-1778 # 80008030 <__func__.1506+0x28>
            for (; *s; s++)
    8000072a:	02800513          	li	a0,40
    8000072e:	b7cd                	j	80000710 <printf+0x170>
            consputc('%');
    80000730:	8556                	mv	a0,s5
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b50080e7          	jalr	-1200(ra) # 80000282 <consputc>
            break;
    8000073a:	b701                	j	8000063a <printf+0x9a>
            consputc('%');
    8000073c:	8556                	mv	a0,s5
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b44080e7          	jalr	-1212(ra) # 80000282 <consputc>
            consputc(c);
    80000746:	854a                	mv	a0,s2
    80000748:	00000097          	auipc	ra,0x0
    8000074c:	b3a080e7          	jalr	-1222(ra) # 80000282 <consputc>
            break;
    80000750:	b5ed                	j	8000063a <printf+0x9a>
    if (locking)
    80000752:	020d9163          	bnez	s11,80000774 <printf+0x1d4>
}
    80000756:	70e6                	ld	ra,120(sp)
    80000758:	7446                	ld	s0,112(sp)
    8000075a:	74a6                	ld	s1,104(sp)
    8000075c:	7906                	ld	s2,96(sp)
    8000075e:	69e6                	ld	s3,88(sp)
    80000760:	6a46                	ld	s4,80(sp)
    80000762:	6aa6                	ld	s5,72(sp)
    80000764:	6b06                	ld	s6,64(sp)
    80000766:	7be2                	ld	s7,56(sp)
    80000768:	7c42                	ld	s8,48(sp)
    8000076a:	7ca2                	ld	s9,40(sp)
    8000076c:	7d02                	ld	s10,32(sp)
    8000076e:	6de2                	ld	s11,24(sp)
    80000770:	6129                	addi	sp,sp,192
    80000772:	8082                	ret
        release(&pr.lock);
    80000774:	00010517          	auipc	a0,0x10
    80000778:	53450513          	addi	a0,a0,1332 # 80010ca8 <pr>
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	616080e7          	jalr	1558(ra) # 80000d92 <release>
}
    80000784:	bfc9                	j	80000756 <printf+0x1b6>

0000000080000786 <printfinit>:
        ;
}

void printfinit(void)
{
    80000786:	1101                	addi	sp,sp,-32
    80000788:	ec06                	sd	ra,24(sp)
    8000078a:	e822                	sd	s0,16(sp)
    8000078c:	e426                	sd	s1,8(sp)
    8000078e:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000790:	00010497          	auipc	s1,0x10
    80000794:	51848493          	addi	s1,s1,1304 # 80010ca8 <pr>
    80000798:	00008597          	auipc	a1,0x8
    8000079c:	8b058593          	addi	a1,a1,-1872 # 80008048 <__func__.1506+0x40>
    800007a0:	8526                	mv	a0,s1
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	4ac080e7          	jalr	1196(ra) # 80000c4e <initlock>
    pr.locking = 1;
    800007aa:	4785                	li	a5,1
    800007ac:	cc9c                	sw	a5,24(s1)
}
    800007ae:	60e2                	ld	ra,24(sp)
    800007b0:	6442                	ld	s0,16(sp)
    800007b2:	64a2                	ld	s1,8(sp)
    800007b4:	6105                	addi	sp,sp,32
    800007b6:	8082                	ret

00000000800007b8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b8:	1141                	addi	sp,sp,-16
    800007ba:	e406                	sd	ra,8(sp)
    800007bc:	e022                	sd	s0,0(sp)
    800007be:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007c0:	100007b7          	lui	a5,0x10000
    800007c4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c8:	f8000713          	li	a4,-128
    800007cc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007d0:	470d                	li	a4,3
    800007d2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007da:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007de:	469d                	li	a3,7
    800007e0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007e4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e8:	00008597          	auipc	a1,0x8
    800007ec:	88058593          	addi	a1,a1,-1920 # 80008068 <digits+0x18>
    800007f0:	00010517          	auipc	a0,0x10
    800007f4:	4d850513          	addi	a0,a0,1240 # 80010cc8 <uart_tx_lock>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	456080e7          	jalr	1110(ra) # 80000c4e <initlock>
}
    80000800:	60a2                	ld	ra,8(sp)
    80000802:	6402                	ld	s0,0(sp)
    80000804:	0141                	addi	sp,sp,16
    80000806:	8082                	ret

0000000080000808 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000808:	1101                	addi	sp,sp,-32
    8000080a:	ec06                	sd	ra,24(sp)
    8000080c:	e822                	sd	s0,16(sp)
    8000080e:	e426                	sd	s1,8(sp)
    80000810:	1000                	addi	s0,sp,32
    80000812:	84aa                	mv	s1,a0
  push_off();
    80000814:	00000097          	auipc	ra,0x0
    80000818:	47e080e7          	jalr	1150(ra) # 80000c92 <push_off>

  if(panicked){
    8000081c:	00008797          	auipc	a5,0x8
    80000820:	2547a783          	lw	a5,596(a5) # 80008a70 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000824:	10000737          	lui	a4,0x10000
  if(panicked){
    80000828:	c391                	beqz	a5,8000082c <uartputc_sync+0x24>
    for(;;)
    8000082a:	a001                	j	8000082a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000082c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000830:	0ff7f793          	andi	a5,a5,255
    80000834:	0207f793          	andi	a5,a5,32
    80000838:	dbf5                	beqz	a5,8000082c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000083a:	0ff4f793          	andi	a5,s1,255
    8000083e:	10000737          	lui	a4,0x10000
    80000842:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	4ec080e7          	jalr	1260(ra) # 80000d32 <pop_off>
}
    8000084e:	60e2                	ld	ra,24(sp)
    80000850:	6442                	ld	s0,16(sp)
    80000852:	64a2                	ld	s1,8(sp)
    80000854:	6105                	addi	sp,sp,32
    80000856:	8082                	ret

0000000080000858 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000858:	00008717          	auipc	a4,0x8
    8000085c:	22073703          	ld	a4,544(a4) # 80008a78 <uart_tx_r>
    80000860:	00008797          	auipc	a5,0x8
    80000864:	2207b783          	ld	a5,544(a5) # 80008a80 <uart_tx_w>
    80000868:	06e78c63          	beq	a5,a4,800008e0 <uartstart+0x88>
{
    8000086c:	7139                	addi	sp,sp,-64
    8000086e:	fc06                	sd	ra,56(sp)
    80000870:	f822                	sd	s0,48(sp)
    80000872:	f426                	sd	s1,40(sp)
    80000874:	f04a                	sd	s2,32(sp)
    80000876:	ec4e                	sd	s3,24(sp)
    80000878:	e852                	sd	s4,16(sp)
    8000087a:	e456                	sd	s5,8(sp)
    8000087c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	00010a17          	auipc	s4,0x10
    80000886:	446a0a13          	addi	s4,s4,1094 # 80010cc8 <uart_tx_lock>
    uart_tx_r += 1;
    8000088a:	00008497          	auipc	s1,0x8
    8000088e:	1ee48493          	addi	s1,s1,494 # 80008a78 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000892:	00008997          	auipc	s3,0x8
    80000896:	1ee98993          	addi	s3,s3,494 # 80008a80 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000089a:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000089e:	0ff7f793          	andi	a5,a5,255
    800008a2:	0207f793          	andi	a5,a5,32
    800008a6:	c785                	beqz	a5,800008ce <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008a8:	01f77793          	andi	a5,a4,31
    800008ac:	97d2                	add	a5,a5,s4
    800008ae:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008b2:	0705                	addi	a4,a4,1
    800008b4:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b6:	8526                	mv	a0,s1
    800008b8:	00002097          	auipc	ra,0x2
    800008bc:	b0a080e7          	jalr	-1270(ra) # 800023c2 <wakeup>
    
    WriteReg(THR, c);
    800008c0:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c4:	6098                	ld	a4,0(s1)
    800008c6:	0009b783          	ld	a5,0(s3)
    800008ca:	fce798e3          	bne	a5,a4,8000089a <uartstart+0x42>
  }
}
    800008ce:	70e2                	ld	ra,56(sp)
    800008d0:	7442                	ld	s0,48(sp)
    800008d2:	74a2                	ld	s1,40(sp)
    800008d4:	7902                	ld	s2,32(sp)
    800008d6:	69e2                	ld	s3,24(sp)
    800008d8:	6a42                	ld	s4,16(sp)
    800008da:	6aa2                	ld	s5,8(sp)
    800008dc:	6121                	addi	sp,sp,64
    800008de:	8082                	ret
    800008e0:	8082                	ret

00000000800008e2 <uartputc>:
{
    800008e2:	7179                	addi	sp,sp,-48
    800008e4:	f406                	sd	ra,40(sp)
    800008e6:	f022                	sd	s0,32(sp)
    800008e8:	ec26                	sd	s1,24(sp)
    800008ea:	e84a                	sd	s2,16(sp)
    800008ec:	e44e                	sd	s3,8(sp)
    800008ee:	e052                	sd	s4,0(sp)
    800008f0:	1800                	addi	s0,sp,48
    800008f2:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f4:	00010517          	auipc	a0,0x10
    800008f8:	3d450513          	addi	a0,a0,980 # 80010cc8 <uart_tx_lock>
    800008fc:	00000097          	auipc	ra,0x0
    80000900:	3e2080e7          	jalr	994(ra) # 80000cde <acquire>
  if(panicked){
    80000904:	00008797          	auipc	a5,0x8
    80000908:	16c7a783          	lw	a5,364(a5) # 80008a70 <panicked>
    8000090c:	e7c9                	bnez	a5,80000996 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008797          	auipc	a5,0x8
    80000912:	1727b783          	ld	a5,370(a5) # 80008a80 <uart_tx_w>
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	16273703          	ld	a4,354(a4) # 80008a78 <uart_tx_r>
    8000091e:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000922:	00010a17          	auipc	s4,0x10
    80000926:	3a6a0a13          	addi	s4,s4,934 # 80010cc8 <uart_tx_lock>
    8000092a:	00008497          	auipc	s1,0x8
    8000092e:	14e48493          	addi	s1,s1,334 # 80008a78 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000932:	00008917          	auipc	s2,0x8
    80000936:	14e90913          	addi	s2,s2,334 # 80008a80 <uart_tx_w>
    8000093a:	00f71f63          	bne	a4,a5,80000958 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000093e:	85d2                	mv	a1,s4
    80000940:	8526                	mv	a0,s1
    80000942:	00002097          	auipc	ra,0x2
    80000946:	a1c080e7          	jalr	-1508(ra) # 8000235e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	00093783          	ld	a5,0(s2)
    8000094e:	6098                	ld	a4,0(s1)
    80000950:	02070713          	addi	a4,a4,32
    80000954:	fef705e3          	beq	a4,a5,8000093e <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000958:	00010497          	auipc	s1,0x10
    8000095c:	37048493          	addi	s1,s1,880 # 80010cc8 <uart_tx_lock>
    80000960:	01f7f713          	andi	a4,a5,31
    80000964:	9726                	add	a4,a4,s1
    80000966:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    8000096a:	0785                	addi	a5,a5,1
    8000096c:	00008717          	auipc	a4,0x8
    80000970:	10f73a23          	sd	a5,276(a4) # 80008a80 <uart_tx_w>
  uartstart();
    80000974:	00000097          	auipc	ra,0x0
    80000978:	ee4080e7          	jalr	-284(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    8000097c:	8526                	mv	a0,s1
    8000097e:	00000097          	auipc	ra,0x0
    80000982:	414080e7          	jalr	1044(ra) # 80000d92 <release>
}
    80000986:	70a2                	ld	ra,40(sp)
    80000988:	7402                	ld	s0,32(sp)
    8000098a:	64e2                	ld	s1,24(sp)
    8000098c:	6942                	ld	s2,16(sp)
    8000098e:	69a2                	ld	s3,8(sp)
    80000990:	6a02                	ld	s4,0(sp)
    80000992:	6145                	addi	sp,sp,48
    80000994:	8082                	ret
    for(;;)
    80000996:	a001                	j	80000996 <uartputc+0xb4>

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    int c = uartgetc();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	fcc080e7          	jalr	-52(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009d4:	00950763          	beq	a0,s1,800009e2 <uartintr+0x22>
      break;
    consoleintr(c);
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	8ec080e7          	jalr	-1812(ra) # 800002c4 <consoleintr>
  while(1){
    800009e0:	b7f5                	j	800009cc <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00010497          	auipc	s1,0x10
    800009e6:	2e648493          	addi	s1,s1,742 # 80010cc8 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2f2080e7          	jalr	754(ra) # 80000cde <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e64080e7          	jalr	-412(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	394080e7          	jalr	916(ra) # 80000d92 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a10:	7179                	addi	sp,sp,-48
    80000a12:	f406                	sd	ra,40(sp)
    80000a14:	f022                	sd	s0,32(sp)
    80000a16:	ec26                	sd	s1,24(sp)
    80000a18:	e84a                	sd	s2,16(sp)
    80000a1a:	e44e                	sd	s3,8(sp)
    80000a1c:	1800                	addi	s0,sp,48
    if(references[PTE2PPN(PA2PTE(pa))] > 1){
    80000a1e:	00c55993          	srli	s3,a0,0xc
    80000a22:	00010797          	auipc	a5,0x10
    80000a26:	2fe78793          	addi	a5,a5,766 # 80010d20 <references>
    80000a2a:	97ce                	add	a5,a5,s3
    80000a2c:	0007c703          	lbu	a4,0(a5)
    80000a30:	4785                	li	a5,1
    80000a32:	08e7e463          	bltu	a5,a4,80000aba <kfree+0xaa>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	86aa                	mv	a3,a0
        return;
    }

    if (MAX_PAGES != 0)
    80000a3a:	00008797          	auipc	a5,0x8
    80000a3e:	0567b783          	ld	a5,86(a5) # 80008a90 <MAX_PAGES>
    80000a42:	c799                	beqz	a5,80000a50 <kfree+0x40>
        assert(FREE_PAGES < MAX_PAGES);
    80000a44:	00008717          	auipc	a4,0x8
    80000a48:	04473703          	ld	a4,68(a4) # 80008a88 <FREE_PAGES>
    80000a4c:	06f77e63          	bgeu	a4,a5,80000ac8 <kfree+0xb8>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a50:	03449793          	slli	a5,s1,0x34
    80000a54:	e7c5                	bnez	a5,80000afc <kfree+0xec>
    80000a56:	00029797          	auipc	a5,0x29
    80000a5a:	4da78793          	addi	a5,a5,1242 # 80029f30 <end>
    80000a5e:	08f4ef63          	bltu	s1,a5,80000afc <kfree+0xec>
    80000a62:	47c5                	li	a5,17
    80000a64:	07ee                	slli	a5,a5,0x1b
    80000a66:	08f6fb63          	bgeu	a3,a5,80000afc <kfree+0xec>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a6a:	6605                	lui	a2,0x1
    80000a6c:	4585                	li	a1,1
    80000a6e:	8526                	mv	a0,s1
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	36a080e7          	jalr	874(ra) # 80000dda <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a78:	00010917          	auipc	s2,0x10
    80000a7c:	28890913          	addi	s2,s2,648 # 80010d00 <kmem>
    80000a80:	854a                	mv	a0,s2
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	25c080e7          	jalr	604(ra) # 80000cde <acquire>
    r->next = kmem.freelist;
    80000a8a:	01893783          	ld	a5,24(s2)
    80000a8e:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a90:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a94:	00008717          	auipc	a4,0x8
    80000a98:	ff470713          	addi	a4,a4,-12 # 80008a88 <FREE_PAGES>
    80000a9c:	631c                	ld	a5,0(a4)
    80000a9e:	0785                	addi	a5,a5,1
    80000aa0:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000aa2:	854a                	mv	a0,s2
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	2ee080e7          	jalr	750(ra) # 80000d92 <release>

    references[PTE2PPN(PA2PTE(pa))] = 0;
    80000aac:	00010797          	auipc	a5,0x10
    80000ab0:	27478793          	addi	a5,a5,628 # 80010d20 <references>
    80000ab4:	99be                	add	s3,s3,a5
    80000ab6:	00098023          	sb	zero,0(s3)
}
    80000aba:	70a2                	ld	ra,40(sp)
    80000abc:	7402                	ld	s0,32(sp)
    80000abe:	64e2                	ld	s1,24(sp)
    80000ac0:	6942                	ld	s2,16(sp)
    80000ac2:	69a2                	ld	s3,8(sp)
    80000ac4:	6145                	addi	sp,sp,48
    80000ac6:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000ac8:	03d00693          	li	a3,61
    80000acc:	00007617          	auipc	a2,0x7
    80000ad0:	53c60613          	addi	a2,a2,1340 # 80008008 <__func__.1506>
    80000ad4:	00007597          	auipc	a1,0x7
    80000ad8:	59c58593          	addi	a1,a1,1436 # 80008070 <digits+0x20>
    80000adc:	00007517          	auipc	a0,0x7
    80000ae0:	5a450513          	addi	a0,a0,1444 # 80008080 <digits+0x30>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	abc080e7          	jalr	-1348(ra) # 800005a0 <printf>
    80000aec:	00007517          	auipc	a0,0x7
    80000af0:	5a450513          	addi	a0,a0,1444 # 80008090 <digits+0x40>
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	a50080e7          	jalr	-1456(ra) # 80000544 <panic>
        panic("kfree");
    80000afc:	00007517          	auipc	a0,0x7
    80000b00:	5a450513          	addi	a0,a0,1444 # 800080a0 <digits+0x50>
    80000b04:	00000097          	auipc	ra,0x0
    80000b08:	a40080e7          	jalr	-1472(ra) # 80000544 <panic>

0000000080000b0c <freerange>:
{
    80000b0c:	7179                	addi	sp,sp,-48
    80000b0e:	f406                	sd	ra,40(sp)
    80000b10:	f022                	sd	s0,32(sp)
    80000b12:	ec26                	sd	s1,24(sp)
    80000b14:	e84a                	sd	s2,16(sp)
    80000b16:	e44e                	sd	s3,8(sp)
    80000b18:	e052                	sd	s4,0(sp)
    80000b1a:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000b1c:	6785                	lui	a5,0x1
    80000b1e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b22:	94aa                	add	s1,s1,a0
    80000b24:	757d                	lui	a0,0xfffff
    80000b26:	8ce9                	and	s1,s1,a0
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b28:	94be                	add	s1,s1,a5
    80000b2a:	0095ee63          	bltu	a1,s1,80000b46 <freerange+0x3a>
    80000b2e:	892e                	mv	s2,a1
        kfree(p);
    80000b30:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b32:	6985                	lui	s3,0x1
        kfree(p);
    80000b34:	01448533          	add	a0,s1,s4
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	ed8080e7          	jalr	-296(ra) # 80000a10 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b40:	94ce                	add	s1,s1,s3
    80000b42:	fe9979e3          	bgeu	s2,s1,80000b34 <freerange+0x28>
}
    80000b46:	70a2                	ld	ra,40(sp)
    80000b48:	7402                	ld	s0,32(sp)
    80000b4a:	64e2                	ld	s1,24(sp)
    80000b4c:	6942                	ld	s2,16(sp)
    80000b4e:	69a2                	ld	s3,8(sp)
    80000b50:	6a02                	ld	s4,0(sp)
    80000b52:	6145                	addi	sp,sp,48
    80000b54:	8082                	ret

0000000080000b56 <kinit>:
{
    80000b56:	1141                	addi	sp,sp,-16
    80000b58:	e406                	sd	ra,8(sp)
    80000b5a:	e022                	sd	s0,0(sp)
    80000b5c:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b5e:	00007597          	auipc	a1,0x7
    80000b62:	54a58593          	addi	a1,a1,1354 # 800080a8 <digits+0x58>
    80000b66:	00010517          	auipc	a0,0x10
    80000b6a:	19a50513          	addi	a0,a0,410 # 80010d00 <kmem>
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	0e0080e7          	jalr	224(ra) # 80000c4e <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b76:	45c5                	li	a1,17
    80000b78:	05ee                	slli	a1,a1,0x1b
    80000b7a:	00029517          	auipc	a0,0x29
    80000b7e:	3b650513          	addi	a0,a0,950 # 80029f30 <end>
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	f8a080e7          	jalr	-118(ra) # 80000b0c <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b8a:	00008797          	auipc	a5,0x8
    80000b8e:	efe7b783          	ld	a5,-258(a5) # 80008a88 <FREE_PAGES>
    80000b92:	00008717          	auipc	a4,0x8
    80000b96:	eef73f23          	sd	a5,-258(a4) # 80008a90 <MAX_PAGES>
}
    80000b9a:	60a2                	ld	ra,8(sp)
    80000b9c:	6402                	ld	s0,0(sp)
    80000b9e:	0141                	addi	sp,sp,16
    80000ba0:	8082                	ret

0000000080000ba2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ba2:	1101                	addi	sp,sp,-32
    80000ba4:	ec06                	sd	ra,24(sp)
    80000ba6:	e822                	sd	s0,16(sp)
    80000ba8:	e426                	sd	s1,8(sp)
    80000baa:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000bac:	00008797          	auipc	a5,0x8
    80000bb0:	edc7b783          	ld	a5,-292(a5) # 80008a88 <FREE_PAGES>
    80000bb4:	cbb1                	beqz	a5,80000c08 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000bb6:	00010497          	auipc	s1,0x10
    80000bba:	14a48493          	addi	s1,s1,330 # 80010d00 <kmem>
    80000bbe:	8526                	mv	a0,s1
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	11e080e7          	jalr	286(ra) # 80000cde <acquire>
    r = kmem.freelist;
    80000bc8:	6c84                	ld	s1,24(s1)
    if (r)
    80000bca:	c8ad                	beqz	s1,80000c3c <kalloc+0x9a>
        kmem.freelist = r->next;
    80000bcc:	609c                	ld	a5,0(s1)
    80000bce:	00010517          	auipc	a0,0x10
    80000bd2:	13250513          	addi	a0,a0,306 # 80010d00 <kmem>
    80000bd6:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	1ba080e7          	jalr	442(ra) # 80000d92 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000be0:	6605                	lui	a2,0x1
    80000be2:	4595                	li	a1,5
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	1f4080e7          	jalr	500(ra) # 80000dda <memset>
    FREE_PAGES--;
    80000bee:	00008717          	auipc	a4,0x8
    80000bf2:	e9a70713          	addi	a4,a4,-358 # 80008a88 <FREE_PAGES>
    80000bf6:	631c                	ld	a5,0(a4)
    80000bf8:	17fd                	addi	a5,a5,-1
    80000bfa:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bfc:	8526                	mv	a0,s1
    80000bfe:	60e2                	ld	ra,24(sp)
    80000c00:	6442                	ld	s0,16(sp)
    80000c02:	64a2                	ld	s1,8(sp)
    80000c04:	6105                	addi	sp,sp,32
    80000c06:	8082                	ret
    assert(FREE_PAGES > 0);
    80000c08:	05700693          	li	a3,87
    80000c0c:	00007617          	auipc	a2,0x7
    80000c10:	3f460613          	addi	a2,a2,1012 # 80008000 <etext>
    80000c14:	00007597          	auipc	a1,0x7
    80000c18:	45c58593          	addi	a1,a1,1116 # 80008070 <digits+0x20>
    80000c1c:	00007517          	auipc	a0,0x7
    80000c20:	46450513          	addi	a0,a0,1124 # 80008080 <digits+0x30>
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	97c080e7          	jalr	-1668(ra) # 800005a0 <printf>
    80000c2c:	00007517          	auipc	a0,0x7
    80000c30:	46450513          	addi	a0,a0,1124 # 80008090 <digits+0x40>
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	910080e7          	jalr	-1776(ra) # 80000544 <panic>
    release(&kmem.lock);
    80000c3c:	00010517          	auipc	a0,0x10
    80000c40:	0c450513          	addi	a0,a0,196 # 80010d00 <kmem>
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	14e080e7          	jalr	334(ra) # 80000d92 <release>
    if (r)
    80000c4c:	b74d                	j	80000bee <kalloc+0x4c>

0000000080000c4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c4e:	1141                	addi	sp,sp,-16
    80000c50:	e422                	sd	s0,8(sp)
    80000c52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c5a:	00053823          	sd	zero,16(a0)
}
    80000c5e:	6422                	ld	s0,8(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret

0000000080000c64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c64:	411c                	lw	a5,0(a0)
    80000c66:	e399                	bnez	a5,80000c6c <holding+0x8>
    80000c68:	4501                	li	a0,0
  return r;
}
    80000c6a:	8082                	ret
{
    80000c6c:	1101                	addi	sp,sp,-32
    80000c6e:	ec06                	sd	ra,24(sp)
    80000c70:	e822                	sd	s0,16(sp)
    80000c72:	e426                	sd	s1,8(sp)
    80000c74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c76:	6904                	ld	s1,16(a0)
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	f66080e7          	jalr	-154(ra) # 80001bde <mycpu>
    80000c80:	40a48533          	sub	a0,s1,a0
    80000c84:	00153513          	seqz	a0,a0
}
    80000c88:	60e2                	ld	ra,24(sp)
    80000c8a:	6442                	ld	s0,16(sp)
    80000c8c:	64a2                	ld	s1,8(sp)
    80000c8e:	6105                	addi	sp,sp,32
    80000c90:	8082                	ret

0000000080000c92 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c92:	1101                	addi	sp,sp,-32
    80000c94:	ec06                	sd	ra,24(sp)
    80000c96:	e822                	sd	s0,16(sp)
    80000c98:	e426                	sd	s1,8(sp)
    80000c9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100024f3          	csrr	s1,sstatus
    80000ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000caa:	00001097          	auipc	ra,0x1
    80000cae:	f34080e7          	jalr	-204(ra) # 80001bde <mycpu>
    80000cb2:	5d3c                	lw	a5,120(a0)
    80000cb4:	cf89                	beqz	a5,80000cce <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	f28080e7          	jalr	-216(ra) # 80001bde <mycpu>
    80000cbe:	5d3c                	lw	a5,120(a0)
    80000cc0:	2785                	addiw	a5,a5,1
    80000cc2:	dd3c                	sw	a5,120(a0)
}
    80000cc4:	60e2                	ld	ra,24(sp)
    80000cc6:	6442                	ld	s0,16(sp)
    80000cc8:	64a2                	ld	s1,8(sp)
    80000cca:	6105                	addi	sp,sp,32
    80000ccc:	8082                	ret
    mycpu()->intena = old;
    80000cce:	00001097          	auipc	ra,0x1
    80000cd2:	f10080e7          	jalr	-240(ra) # 80001bde <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cd6:	8085                	srli	s1,s1,0x1
    80000cd8:	8885                	andi	s1,s1,1
    80000cda:	dd64                	sw	s1,124(a0)
    80000cdc:	bfe9                	j	80000cb6 <push_off+0x24>

0000000080000cde <acquire>:
{
    80000cde:	1101                	addi	sp,sp,-32
    80000ce0:	ec06                	sd	ra,24(sp)
    80000ce2:	e822                	sd	s0,16(sp)
    80000ce4:	e426                	sd	s1,8(sp)
    80000ce6:	1000                	addi	s0,sp,32
    80000ce8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	fa8080e7          	jalr	-88(ra) # 80000c92 <push_off>
  if(holding(lk))
    80000cf2:	8526                	mv	a0,s1
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	f70080e7          	jalr	-144(ra) # 80000c64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cfc:	4705                	li	a4,1
  if(holding(lk))
    80000cfe:	e115                	bnez	a0,80000d22 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d00:	87ba                	mv	a5,a4
    80000d02:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d06:	2781                	sext.w	a5,a5
    80000d08:	ffe5                	bnez	a5,80000d00 <acquire+0x22>
  __sync_synchronize();
    80000d0a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d0e:	00001097          	auipc	ra,0x1
    80000d12:	ed0080e7          	jalr	-304(ra) # 80001bde <mycpu>
    80000d16:	e888                	sd	a0,16(s1)
}
    80000d18:	60e2                	ld	ra,24(sp)
    80000d1a:	6442                	ld	s0,16(sp)
    80000d1c:	64a2                	ld	s1,8(sp)
    80000d1e:	6105                	addi	sp,sp,32
    80000d20:	8082                	ret
    panic("acquire");
    80000d22:	00007517          	auipc	a0,0x7
    80000d26:	38e50513          	addi	a0,a0,910 # 800080b0 <digits+0x60>
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	81a080e7          	jalr	-2022(ra) # 80000544 <panic>

0000000080000d32 <pop_off>:

void
pop_off(void)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e406                	sd	ra,8(sp)
    80000d36:	e022                	sd	s0,0(sp)
    80000d38:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	ea4080e7          	jalr	-348(ra) # 80001bde <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d42:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d46:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d48:	e78d                	bnez	a5,80000d72 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d4a:	5d3c                	lw	a5,120(a0)
    80000d4c:	02f05b63          	blez	a5,80000d82 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d50:	37fd                	addiw	a5,a5,-1
    80000d52:	0007871b          	sext.w	a4,a5
    80000d56:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d58:	eb09                	bnez	a4,80000d6a <pop_off+0x38>
    80000d5a:	5d7c                	lw	a5,124(a0)
    80000d5c:	c799                	beqz	a5,80000d6a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d62:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d66:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d6a:	60a2                	ld	ra,8(sp)
    80000d6c:	6402                	ld	s0,0(sp)
    80000d6e:	0141                	addi	sp,sp,16
    80000d70:	8082                	ret
    panic("pop_off - interruptible");
    80000d72:	00007517          	auipc	a0,0x7
    80000d76:	34650513          	addi	a0,a0,838 # 800080b8 <digits+0x68>
    80000d7a:	fffff097          	auipc	ra,0xfffff
    80000d7e:	7ca080e7          	jalr	1994(ra) # 80000544 <panic>
    panic("pop_off");
    80000d82:	00007517          	auipc	a0,0x7
    80000d86:	34e50513          	addi	a0,a0,846 # 800080d0 <digits+0x80>
    80000d8a:	fffff097          	auipc	ra,0xfffff
    80000d8e:	7ba080e7          	jalr	1978(ra) # 80000544 <panic>

0000000080000d92 <release>:
{
    80000d92:	1101                	addi	sp,sp,-32
    80000d94:	ec06                	sd	ra,24(sp)
    80000d96:	e822                	sd	s0,16(sp)
    80000d98:	e426                	sd	s1,8(sp)
    80000d9a:	1000                	addi	s0,sp,32
    80000d9c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	ec6080e7          	jalr	-314(ra) # 80000c64 <holding>
    80000da6:	c115                	beqz	a0,80000dca <release+0x38>
  lk->cpu = 0;
    80000da8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dac:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000db0:	0f50000f          	fence	iorw,ow
    80000db4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000db8:	00000097          	auipc	ra,0x0
    80000dbc:	f7a080e7          	jalr	-134(ra) # 80000d32 <pop_off>
}
    80000dc0:	60e2                	ld	ra,24(sp)
    80000dc2:	6442                	ld	s0,16(sp)
    80000dc4:	64a2                	ld	s1,8(sp)
    80000dc6:	6105                	addi	sp,sp,32
    80000dc8:	8082                	ret
    panic("release");
    80000dca:	00007517          	auipc	a0,0x7
    80000dce:	30e50513          	addi	a0,a0,782 # 800080d8 <digits+0x88>
    80000dd2:	fffff097          	auipc	ra,0xfffff
    80000dd6:	772080e7          	jalr	1906(ra) # 80000544 <panic>

0000000080000dda <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000de0:	ce09                	beqz	a2,80000dfa <memset+0x20>
    80000de2:	87aa                	mv	a5,a0
    80000de4:	fff6071b          	addiw	a4,a2,-1
    80000de8:	1702                	slli	a4,a4,0x20
    80000dea:	9301                	srli	a4,a4,0x20
    80000dec:	0705                	addi	a4,a4,1
    80000dee:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000df0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000df4:	0785                	addi	a5,a5,1
    80000df6:	fee79de3          	bne	a5,a4,80000df0 <memset+0x16>
  }
  return dst;
}
    80000dfa:	6422                	ld	s0,8(sp)
    80000dfc:	0141                	addi	sp,sp,16
    80000dfe:	8082                	ret

0000000080000e00 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e00:	1141                	addi	sp,sp,-16
    80000e02:	e422                	sd	s0,8(sp)
    80000e04:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e06:	ca05                	beqz	a2,80000e36 <memcmp+0x36>
    80000e08:	fff6069b          	addiw	a3,a2,-1
    80000e0c:	1682                	slli	a3,a3,0x20
    80000e0e:	9281                	srli	a3,a3,0x20
    80000e10:	0685                	addi	a3,a3,1
    80000e12:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e14:	00054783          	lbu	a5,0(a0)
    80000e18:	0005c703          	lbu	a4,0(a1)
    80000e1c:	00e79863          	bne	a5,a4,80000e2c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e20:	0505                	addi	a0,a0,1
    80000e22:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e24:	fed518e3          	bne	a0,a3,80000e14 <memcmp+0x14>
  }

  return 0;
    80000e28:	4501                	li	a0,0
    80000e2a:	a019                	j	80000e30 <memcmp+0x30>
      return *s1 - *s2;
    80000e2c:	40e7853b          	subw	a0,a5,a4
}
    80000e30:	6422                	ld	s0,8(sp)
    80000e32:	0141                	addi	sp,sp,16
    80000e34:	8082                	ret
  return 0;
    80000e36:	4501                	li	a0,0
    80000e38:	bfe5                	j	80000e30 <memcmp+0x30>

0000000080000e3a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e40:	ca0d                	beqz	a2,80000e72 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e42:	00a5f963          	bgeu	a1,a0,80000e54 <memmove+0x1a>
    80000e46:	02061693          	slli	a3,a2,0x20
    80000e4a:	9281                	srli	a3,a3,0x20
    80000e4c:	00d58733          	add	a4,a1,a3
    80000e50:	02e56463          	bltu	a0,a4,80000e78 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e54:	fff6079b          	addiw	a5,a2,-1
    80000e58:	1782                	slli	a5,a5,0x20
    80000e5a:	9381                	srli	a5,a5,0x20
    80000e5c:	0785                	addi	a5,a5,1
    80000e5e:	97ae                	add	a5,a5,a1
    80000e60:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e62:	0585                	addi	a1,a1,1
    80000e64:	0705                	addi	a4,a4,1
    80000e66:	fff5c683          	lbu	a3,-1(a1)
    80000e6a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e6e:	fef59ae3          	bne	a1,a5,80000e62 <memmove+0x28>

  return dst;
}
    80000e72:	6422                	ld	s0,8(sp)
    80000e74:	0141                	addi	sp,sp,16
    80000e76:	8082                	ret
    d += n;
    80000e78:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e7a:	fff6079b          	addiw	a5,a2,-1
    80000e7e:	1782                	slli	a5,a5,0x20
    80000e80:	9381                	srli	a5,a5,0x20
    80000e82:	fff7c793          	not	a5,a5
    80000e86:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e88:	177d                	addi	a4,a4,-1
    80000e8a:	16fd                	addi	a3,a3,-1
    80000e8c:	00074603          	lbu	a2,0(a4)
    80000e90:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e94:	fef71ae3          	bne	a4,a5,80000e88 <memmove+0x4e>
    80000e98:	bfe9                	j	80000e72 <memmove+0x38>

0000000080000e9a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e9a:	1141                	addi	sp,sp,-16
    80000e9c:	e406                	sd	ra,8(sp)
    80000e9e:	e022                	sd	s0,0(sp)
    80000ea0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ea2:	00000097          	auipc	ra,0x0
    80000ea6:	f98080e7          	jalr	-104(ra) # 80000e3a <memmove>
}
    80000eaa:	60a2                	ld	ra,8(sp)
    80000eac:	6402                	ld	s0,0(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret

0000000080000eb2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e422                	sd	s0,8(sp)
    80000eb6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eb8:	ce11                	beqz	a2,80000ed4 <strncmp+0x22>
    80000eba:	00054783          	lbu	a5,0(a0)
    80000ebe:	cf89                	beqz	a5,80000ed8 <strncmp+0x26>
    80000ec0:	0005c703          	lbu	a4,0(a1)
    80000ec4:	00f71a63          	bne	a4,a5,80000ed8 <strncmp+0x26>
    n--, p++, q++;
    80000ec8:	367d                	addiw	a2,a2,-1
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ece:	f675                	bnez	a2,80000eba <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ed0:	4501                	li	a0,0
    80000ed2:	a809                	j	80000ee4 <strncmp+0x32>
    80000ed4:	4501                	li	a0,0
    80000ed6:	a039                	j	80000ee4 <strncmp+0x32>
  if(n == 0)
    80000ed8:	ca09                	beqz	a2,80000eea <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eda:	00054503          	lbu	a0,0(a0)
    80000ede:	0005c783          	lbu	a5,0(a1)
    80000ee2:	9d1d                	subw	a0,a0,a5
}
    80000ee4:	6422                	ld	s0,8(sp)
    80000ee6:	0141                	addi	sp,sp,16
    80000ee8:	8082                	ret
    return 0;
    80000eea:	4501                	li	a0,0
    80000eec:	bfe5                	j	80000ee4 <strncmp+0x32>

0000000080000eee <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef4:	872a                	mv	a4,a0
    80000ef6:	8832                	mv	a6,a2
    80000ef8:	367d                	addiw	a2,a2,-1
    80000efa:	01005963          	blez	a6,80000f0c <strncpy+0x1e>
    80000efe:	0705                	addi	a4,a4,1
    80000f00:	0005c783          	lbu	a5,0(a1)
    80000f04:	fef70fa3          	sb	a5,-1(a4)
    80000f08:	0585                	addi	a1,a1,1
    80000f0a:	f7f5                	bnez	a5,80000ef6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f0c:	00c05d63          	blez	a2,80000f26 <strncpy+0x38>
    80000f10:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f12:	0685                	addi	a3,a3,1
    80000f14:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f18:	fff6c793          	not	a5,a3
    80000f1c:	9fb9                	addw	a5,a5,a4
    80000f1e:	010787bb          	addw	a5,a5,a6
    80000f22:	fef048e3          	bgtz	a5,80000f12 <strncpy+0x24>
  return os;
}
    80000f26:	6422                	ld	s0,8(sp)
    80000f28:	0141                	addi	sp,sp,16
    80000f2a:	8082                	ret

0000000080000f2c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f2c:	1141                	addi	sp,sp,-16
    80000f2e:	e422                	sd	s0,8(sp)
    80000f30:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f32:	02c05363          	blez	a2,80000f58 <safestrcpy+0x2c>
    80000f36:	fff6069b          	addiw	a3,a2,-1
    80000f3a:	1682                	slli	a3,a3,0x20
    80000f3c:	9281                	srli	a3,a3,0x20
    80000f3e:	96ae                	add	a3,a3,a1
    80000f40:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f42:	00d58963          	beq	a1,a3,80000f54 <safestrcpy+0x28>
    80000f46:	0585                	addi	a1,a1,1
    80000f48:	0785                	addi	a5,a5,1
    80000f4a:	fff5c703          	lbu	a4,-1(a1)
    80000f4e:	fee78fa3          	sb	a4,-1(a5)
    80000f52:	fb65                	bnez	a4,80000f42 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f54:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f58:	6422                	ld	s0,8(sp)
    80000f5a:	0141                	addi	sp,sp,16
    80000f5c:	8082                	ret

0000000080000f5e <strlen>:

int
strlen(const char *s)
{
    80000f5e:	1141                	addi	sp,sp,-16
    80000f60:	e422                	sd	s0,8(sp)
    80000f62:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f64:	00054783          	lbu	a5,0(a0)
    80000f68:	cf91                	beqz	a5,80000f84 <strlen+0x26>
    80000f6a:	0505                	addi	a0,a0,1
    80000f6c:	87aa                	mv	a5,a0
    80000f6e:	4685                	li	a3,1
    80000f70:	9e89                	subw	a3,a3,a0
    80000f72:	00f6853b          	addw	a0,a3,a5
    80000f76:	0785                	addi	a5,a5,1
    80000f78:	fff7c703          	lbu	a4,-1(a5)
    80000f7c:	fb7d                	bnez	a4,80000f72 <strlen+0x14>
    ;
  return n;
}
    80000f7e:	6422                	ld	s0,8(sp)
    80000f80:	0141                	addi	sp,sp,16
    80000f82:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f84:	4501                	li	a0,0
    80000f86:	bfe5                	j	80000f7e <strlen+0x20>

0000000080000f88 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e406                	sd	ra,8(sp)
    80000f8c:	e022                	sd	s0,0(sp)
    80000f8e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	c3e080e7          	jalr	-962(ra) # 80001bce <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f98:	00008717          	auipc	a4,0x8
    80000f9c:	b0070713          	addi	a4,a4,-1280 # 80008a98 <started>
  if(cpuid() == 0){
    80000fa0:	c139                	beqz	a0,80000fe6 <main+0x5e>
    while(started == 0)
    80000fa2:	431c                	lw	a5,0(a4)
    80000fa4:	2781                	sext.w	a5,a5
    80000fa6:	dff5                	beqz	a5,80000fa2 <main+0x1a>
      ;
    __sync_synchronize();
    80000fa8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fac:	00001097          	auipc	ra,0x1
    80000fb0:	c22080e7          	jalr	-990(ra) # 80001bce <cpuid>
    80000fb4:	85aa                	mv	a1,a0
    80000fb6:	00007517          	auipc	a0,0x7
    80000fba:	14250513          	addi	a0,a0,322 # 800080f8 <digits+0xa8>
    80000fbe:	fffff097          	auipc	ra,0xfffff
    80000fc2:	5e2080e7          	jalr	1506(ra) # 800005a0 <printf>
    kvminithart();    // turn on paging
    80000fc6:	00000097          	auipc	ra,0x0
    80000fca:	0d8080e7          	jalr	216(ra) # 8000109e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	aa6080e7          	jalr	-1370(ra) # 80002a74 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	23a080e7          	jalr	570(ra) # 80006210 <plicinithart>
  }

  scheduler();        
    80000fde:	00001097          	auipc	ra,0x1
    80000fe2:	25e080e7          	jalr	606(ra) # 8000223c <scheduler>
    consoleinit();
    80000fe6:	fffff097          	auipc	ra,0xfffff
    80000fea:	470080e7          	jalr	1136(ra) # 80000456 <consoleinit>
    printfinit();
    80000fee:	fffff097          	auipc	ra,0xfffff
    80000ff2:	798080e7          	jalr	1944(ra) # 80000786 <printfinit>
    printf("\n");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	09250513          	addi	a0,a0,146 # 80008088 <digits+0x38>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	5a2080e7          	jalr	1442(ra) # 800005a0 <printf>
    printf("xv6 kernel is booting\n");
    80001006:	00007517          	auipc	a0,0x7
    8000100a:	0da50513          	addi	a0,a0,218 # 800080e0 <digits+0x90>
    8000100e:	fffff097          	auipc	ra,0xfffff
    80001012:	592080e7          	jalr	1426(ra) # 800005a0 <printf>
    printf("\n");
    80001016:	00007517          	auipc	a0,0x7
    8000101a:	07250513          	addi	a0,a0,114 # 80008088 <digits+0x38>
    8000101e:	fffff097          	auipc	ra,0xfffff
    80001022:	582080e7          	jalr	1410(ra) # 800005a0 <printf>
    kinit();         // physical page allocator
    80001026:	00000097          	auipc	ra,0x0
    8000102a:	b30080e7          	jalr	-1232(ra) # 80000b56 <kinit>
    kvminit();       // create kernel page table
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	326080e7          	jalr	806(ra) # 80001354 <kvminit>
    kvminithart();   // turn on paging
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	068080e7          	jalr	104(ra) # 8000109e <kvminithart>
    procinit();      // process table
    8000103e:	00001097          	auipc	ra,0x1
    80001042:	aae080e7          	jalr	-1362(ra) # 80001aec <procinit>
    trapinit();      // trap vectors
    80001046:	00002097          	auipc	ra,0x2
    8000104a:	a06080e7          	jalr	-1530(ra) # 80002a4c <trapinit>
    trapinithart();  // install kernel trap vector
    8000104e:	00002097          	auipc	ra,0x2
    80001052:	a26080e7          	jalr	-1498(ra) # 80002a74 <trapinithart>
    plicinit();      // set up interrupt controller
    80001056:	00005097          	auipc	ra,0x5
    8000105a:	1a4080e7          	jalr	420(ra) # 800061fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000105e:	00005097          	auipc	ra,0x5
    80001062:	1b2080e7          	jalr	434(ra) # 80006210 <plicinithart>
    binit();         // buffer cache
    80001066:	00002097          	auipc	ra,0x2
    8000106a:	36c080e7          	jalr	876(ra) # 800033d2 <binit>
    iinit();         // inode table
    8000106e:	00003097          	auipc	ra,0x3
    80001072:	a10080e7          	jalr	-1520(ra) # 80003a7e <iinit>
    fileinit();      // file table
    80001076:	00004097          	auipc	ra,0x4
    8000107a:	9ae080e7          	jalr	-1618(ra) # 80004a24 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000107e:	00005097          	auipc	ra,0x5
    80001082:	29a080e7          	jalr	666(ra) # 80006318 <virtio_disk_init>
    userinit();      // first user process
    80001086:	00001097          	auipc	ra,0x1
    8000108a:	e4c080e7          	jalr	-436(ra) # 80001ed2 <userinit>
    __sync_synchronize();
    8000108e:	0ff0000f          	fence
    started = 1;
    80001092:	4785                	li	a5,1
    80001094:	00008717          	auipc	a4,0x8
    80001098:	a0f72223          	sw	a5,-1532(a4) # 80008a98 <started>
    8000109c:	b789                	j	80000fde <main+0x56>

000000008000109e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e422                	sd	s0,8(sp)
    800010a2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010a4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010a8:	00008797          	auipc	a5,0x8
    800010ac:	9f87b783          	ld	a5,-1544(a5) # 80008aa0 <kernel_pagetable>
    800010b0:	83b1                	srli	a5,a5,0xc
    800010b2:	577d                	li	a4,-1
    800010b4:	177e                	slli	a4,a4,0x3f
    800010b6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010bc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010c0:	6422                	ld	s0,8(sp)
    800010c2:	0141                	addi	sp,sp,16
    800010c4:	8082                	ret

00000000800010c6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c6:	7139                	addi	sp,sp,-64
    800010c8:	fc06                	sd	ra,56(sp)
    800010ca:	f822                	sd	s0,48(sp)
    800010cc:	f426                	sd	s1,40(sp)
    800010ce:	f04a                	sd	s2,32(sp)
    800010d0:	ec4e                	sd	s3,24(sp)
    800010d2:	e852                	sd	s4,16(sp)
    800010d4:	e456                	sd	s5,8(sp)
    800010d6:	e05a                	sd	s6,0(sp)
    800010d8:	0080                	addi	s0,sp,64
    800010da:	84aa                	mv	s1,a0
    800010dc:	89ae                	mv	s3,a1
    800010de:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010e0:	57fd                	li	a5,-1
    800010e2:	83e9                	srli	a5,a5,0x1a
    800010e4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e6:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e8:	04b7f263          	bgeu	a5,a1,8000112c <walk+0x66>
    panic("walk");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	02450513          	addi	a0,a0,36 # 80008110 <digits+0xc0>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	450080e7          	jalr	1104(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010fc:	060a8663          	beqz	s5,80001168 <walk+0xa2>
    80001100:	00000097          	auipc	ra,0x0
    80001104:	aa2080e7          	jalr	-1374(ra) # 80000ba2 <kalloc>
    80001108:	84aa                	mv	s1,a0
    8000110a:	c529                	beqz	a0,80001154 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000110c:	6605                	lui	a2,0x1
    8000110e:	4581                	li	a1,0
    80001110:	00000097          	auipc	ra,0x0
    80001114:	cca080e7          	jalr	-822(ra) # 80000dda <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001118:	00c4d793          	srli	a5,s1,0xc
    8000111c:	07aa                	slli	a5,a5,0xa
    8000111e:	0017e793          	ori	a5,a5,1
    80001122:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001126:	3a5d                	addiw	s4,s4,-9
    80001128:	036a0063          	beq	s4,s6,80001148 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000112c:	0149d933          	srl	s2,s3,s4
    80001130:	1ff97913          	andi	s2,s2,511
    80001134:	090e                	slli	s2,s2,0x3
    80001136:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001138:	00093483          	ld	s1,0(s2)
    8000113c:	0014f793          	andi	a5,s1,1
    80001140:	dfd5                	beqz	a5,800010fc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001142:	80a9                	srli	s1,s1,0xa
    80001144:	04b2                	slli	s1,s1,0xc
    80001146:	b7c5                	j	80001126 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001148:	00c9d513          	srli	a0,s3,0xc
    8000114c:	1ff57513          	andi	a0,a0,511
    80001150:	050e                	slli	a0,a0,0x3
    80001152:	9526                	add	a0,a0,s1
}
    80001154:	70e2                	ld	ra,56(sp)
    80001156:	7442                	ld	s0,48(sp)
    80001158:	74a2                	ld	s1,40(sp)
    8000115a:	7902                	ld	s2,32(sp)
    8000115c:	69e2                	ld	s3,24(sp)
    8000115e:	6a42                	ld	s4,16(sp)
    80001160:	6aa2                	ld	s5,8(sp)
    80001162:	6b02                	ld	s6,0(sp)
    80001164:	6121                	addi	sp,sp,64
    80001166:	8082                	ret
        return 0;
    80001168:	4501                	li	a0,0
    8000116a:	b7ed                	j	80001154 <walk+0x8e>

000000008000116c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000116c:	57fd                	li	a5,-1
    8000116e:	83e9                	srli	a5,a5,0x1a
    80001170:	00b7f463          	bgeu	a5,a1,80001178 <walkaddr+0xc>
    return 0;
    80001174:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001176:	8082                	ret
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001180:	4601                	li	a2,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f44080e7          	jalr	-188(ra) # 800010c6 <walk>
  if(pte == 0)
    8000118a:	c105                	beqz	a0,800011aa <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000118c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000118e:	0117f693          	andi	a3,a5,17
    80001192:	4745                	li	a4,17
    return 0;
    80001194:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001196:	00e68663          	beq	a3,a4,800011a2 <walkaddr+0x36>
}
    8000119a:	60a2                	ld	ra,8(sp)
    8000119c:	6402                	ld	s0,0(sp)
    8000119e:	0141                	addi	sp,sp,16
    800011a0:	8082                	ret
  pa = PTE2PA(*pte);
    800011a2:	00a7d513          	srli	a0,a5,0xa
    800011a6:	0532                	slli	a0,a0,0xc
  return pa;
    800011a8:	bfcd                	j	8000119a <walkaddr+0x2e>
    return 0;
    800011aa:	4501                	li	a0,0
    800011ac:	b7fd                	j	8000119a <walkaddr+0x2e>

00000000800011ae <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ae:	715d                	addi	sp,sp,-80
    800011b0:	e486                	sd	ra,72(sp)
    800011b2:	e0a2                	sd	s0,64(sp)
    800011b4:	fc26                	sd	s1,56(sp)
    800011b6:	f84a                	sd	s2,48(sp)
    800011b8:	f44e                	sd	s3,40(sp)
    800011ba:	f052                	sd	s4,32(sp)
    800011bc:	ec56                	sd	s5,24(sp)
    800011be:	e85a                	sd	s6,16(sp)
    800011c0:	e45e                	sd	s7,8(sp)
    800011c2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011c4:	c205                	beqz	a2,800011e4 <mappages+0x36>
    800011c6:	8aaa                	mv	s5,a0
    800011c8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011ca:	77fd                	lui	a5,0xfffff
    800011cc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011d0:	15fd                	addi	a1,a1,-1
    800011d2:	00c589b3          	add	s3,a1,a2
    800011d6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011da:	8952                	mv	s2,s4
    800011dc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011e0:	6b85                	lui	s7,0x1
    800011e2:	a015                	j	80001206 <mappages+0x58>
    panic("mappages: size");
    800011e4:	00007517          	auipc	a0,0x7
    800011e8:	f3450513          	addi	a0,a0,-204 # 80008118 <digits+0xc8>
    800011ec:	fffff097          	auipc	ra,0xfffff
    800011f0:	358080e7          	jalr	856(ra) # 80000544 <panic>
      panic("mappages: remap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	f3450513          	addi	a0,a0,-204 # 80008128 <digits+0xd8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	348080e7          	jalr	840(ra) # 80000544 <panic>
    a += PGSIZE;
    80001204:	995e                	add	s2,s2,s7
  for(;;){
    80001206:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120a:	4605                	li	a2,1
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8556                	mv	a0,s5
    80001210:	00000097          	auipc	ra,0x0
    80001214:	eb6080e7          	jalr	-330(ra) # 800010c6 <walk>
    80001218:	cd19                	beqz	a0,80001236 <mappages+0x88>
    if(*pte & PTE_V)
    8000121a:	611c                	ld	a5,0(a0)
    8000121c:	8b85                	andi	a5,a5,1
    8000121e:	fbf9                	bnez	a5,800011f4 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001220:	80b1                	srli	s1,s1,0xc
    80001222:	04aa                	slli	s1,s1,0xa
    80001224:	0164e4b3          	or	s1,s1,s6
    80001228:	0014e493          	ori	s1,s1,1
    8000122c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000122e:	fd391be3          	bne	s2,s3,80001204 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001232:	4501                	li	a0,0
    80001234:	a011                	j	80001238 <mappages+0x8a>
      return -1;
    80001236:	557d                	li	a0,-1
}
    80001238:	60a6                	ld	ra,72(sp)
    8000123a:	6406                	ld	s0,64(sp)
    8000123c:	74e2                	ld	s1,56(sp)
    8000123e:	7942                	ld	s2,48(sp)
    80001240:	79a2                	ld	s3,40(sp)
    80001242:	7a02                	ld	s4,32(sp)
    80001244:	6ae2                	ld	s5,24(sp)
    80001246:	6b42                	ld	s6,16(sp)
    80001248:	6ba2                	ld	s7,8(sp)
    8000124a:	6161                	addi	sp,sp,80
    8000124c:	8082                	ret

000000008000124e <kvmmap>:
{
    8000124e:	1141                	addi	sp,sp,-16
    80001250:	e406                	sd	ra,8(sp)
    80001252:	e022                	sd	s0,0(sp)
    80001254:	0800                	addi	s0,sp,16
    80001256:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001258:	86b2                	mv	a3,a2
    8000125a:	863e                	mv	a2,a5
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f52080e7          	jalr	-174(ra) # 800011ae <mappages>
    80001264:	e509                	bnez	a0,8000126e <kvmmap+0x20>
}
    80001266:	60a2                	ld	ra,8(sp)
    80001268:	6402                	ld	s0,0(sp)
    8000126a:	0141                	addi	sp,sp,16
    8000126c:	8082                	ret
    panic("kvmmap");
    8000126e:	00007517          	auipc	a0,0x7
    80001272:	eca50513          	addi	a0,a0,-310 # 80008138 <digits+0xe8>
    80001276:	fffff097          	auipc	ra,0xfffff
    8000127a:	2ce080e7          	jalr	718(ra) # 80000544 <panic>

000000008000127e <kvmmake>:
{
    8000127e:	1101                	addi	sp,sp,-32
    80001280:	ec06                	sd	ra,24(sp)
    80001282:	e822                	sd	s0,16(sp)
    80001284:	e426                	sd	s1,8(sp)
    80001286:	e04a                	sd	s2,0(sp)
    80001288:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	918080e7          	jalr	-1768(ra) # 80000ba2 <kalloc>
    80001292:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001294:	6605                	lui	a2,0x1
    80001296:	4581                	li	a1,0
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	b42080e7          	jalr	-1214(ra) # 80000dda <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012a0:	4719                	li	a4,6
    800012a2:	6685                	lui	a3,0x1
    800012a4:	10000637          	lui	a2,0x10000
    800012a8:	100005b7          	lui	a1,0x10000
    800012ac:	8526                	mv	a0,s1
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	fa0080e7          	jalr	-96(ra) # 8000124e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b6:	4719                	li	a4,6
    800012b8:	6685                	lui	a3,0x1
    800012ba:	10001637          	lui	a2,0x10001
    800012be:	100015b7          	lui	a1,0x10001
    800012c2:	8526                	mv	a0,s1
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f8a080e7          	jalr	-118(ra) # 8000124e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012cc:	4719                	li	a4,6
    800012ce:	004006b7          	lui	a3,0x400
    800012d2:	0c000637          	lui	a2,0xc000
    800012d6:	0c0005b7          	lui	a1,0xc000
    800012da:	8526                	mv	a0,s1
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	f72080e7          	jalr	-142(ra) # 8000124e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e4:	00007917          	auipc	s2,0x7
    800012e8:	d1c90913          	addi	s2,s2,-740 # 80008000 <etext>
    800012ec:	4729                	li	a4,10
    800012ee:	80007697          	auipc	a3,0x80007
    800012f2:	d1268693          	addi	a3,a3,-750 # 8000 <_entry-0x7fff8000>
    800012f6:	4605                	li	a2,1
    800012f8:	067e                	slli	a2,a2,0x1f
    800012fa:	85b2                	mv	a1,a2
    800012fc:	8526                	mv	a0,s1
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	f50080e7          	jalr	-176(ra) # 8000124e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001306:	4719                	li	a4,6
    80001308:	46c5                	li	a3,17
    8000130a:	06ee                	slli	a3,a3,0x1b
    8000130c:	412686b3          	sub	a3,a3,s2
    80001310:	864a                	mv	a2,s2
    80001312:	85ca                	mv	a1,s2
    80001314:	8526                	mv	a0,s1
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f38080e7          	jalr	-200(ra) # 8000124e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131e:	4729                	li	a4,10
    80001320:	6685                	lui	a3,0x1
    80001322:	00006617          	auipc	a2,0x6
    80001326:	cde60613          	addi	a2,a2,-802 # 80007000 <_trampoline>
    8000132a:	040005b7          	lui	a1,0x4000
    8000132e:	15fd                	addi	a1,a1,-1
    80001330:	05b2                	slli	a1,a1,0xc
    80001332:	8526                	mv	a0,s1
    80001334:	00000097          	auipc	ra,0x0
    80001338:	f1a080e7          	jalr	-230(ra) # 8000124e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000133c:	8526                	mv	a0,s1
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	718080e7          	jalr	1816(ra) # 80001a56 <proc_mapstacks>
}
    80001346:	8526                	mv	a0,s1
    80001348:	60e2                	ld	ra,24(sp)
    8000134a:	6442                	ld	s0,16(sp)
    8000134c:	64a2                	ld	s1,8(sp)
    8000134e:	6902                	ld	s2,0(sp)
    80001350:	6105                	addi	sp,sp,32
    80001352:	8082                	ret

0000000080001354 <kvminit>:
{
    80001354:	1141                	addi	sp,sp,-16
    80001356:	e406                	sd	ra,8(sp)
    80001358:	e022                	sd	s0,0(sp)
    8000135a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	f22080e7          	jalr	-222(ra) # 8000127e <kvmmake>
    80001364:	00007797          	auipc	a5,0x7
    80001368:	72a7be23          	sd	a0,1852(a5) # 80008aa0 <kernel_pagetable>
}
    8000136c:	60a2                	ld	ra,8(sp)
    8000136e:	6402                	ld	s0,0(sp)
    80001370:	0141                	addi	sp,sp,16
    80001372:	8082                	ret

0000000080001374 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001374:	715d                	addi	sp,sp,-80
    80001376:	e486                	sd	ra,72(sp)
    80001378:	e0a2                	sd	s0,64(sp)
    8000137a:	fc26                	sd	s1,56(sp)
    8000137c:	f84a                	sd	s2,48(sp)
    8000137e:	f44e                	sd	s3,40(sp)
    80001380:	f052                	sd	s4,32(sp)
    80001382:	ec56                	sd	s5,24(sp)
    80001384:	e85a                	sd	s6,16(sp)
    80001386:	e45e                	sd	s7,8(sp)
    80001388:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000138a:	03459793          	slli	a5,a1,0x34
    8000138e:	e795                	bnez	a5,800013ba <uvmunmap+0x46>
    80001390:	8a2a                	mv	s4,a0
    80001392:	892e                	mv	s2,a1
    80001394:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001396:	0632                	slli	a2,a2,0xc
    80001398:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139e:	6b05                	lui	s6,0x1
    800013a0:	0735e863          	bltu	a1,s3,80001410 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013a4:	60a6                	ld	ra,72(sp)
    800013a6:	6406                	ld	s0,64(sp)
    800013a8:	74e2                	ld	s1,56(sp)
    800013aa:	7942                	ld	s2,48(sp)
    800013ac:	79a2                	ld	s3,40(sp)
    800013ae:	7a02                	ld	s4,32(sp)
    800013b0:	6ae2                	ld	s5,24(sp)
    800013b2:	6b42                	ld	s6,16(sp)
    800013b4:	6ba2                	ld	s7,8(sp)
    800013b6:	6161                	addi	sp,sp,80
    800013b8:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ba:	00007517          	auipc	a0,0x7
    800013be:	d8650513          	addi	a0,a0,-634 # 80008140 <digits+0xf0>
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	182080e7          	jalr	386(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x108>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	172080e7          	jalr	370(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d8e50513          	addi	a0,a0,-626 # 80008168 <digits+0x118>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	162080e7          	jalr	354(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800013ea:	00007517          	auipc	a0,0x7
    800013ee:	d9650513          	addi	a0,a0,-618 # 80008180 <digits+0x130>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	152080e7          	jalr	338(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800013fa:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013fc:	0532                	slli	a0,a0,0xc
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	612080e7          	jalr	1554(ra) # 80000a10 <kfree>
    *pte = 0;
    80001406:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000140a:	995a                	add	s2,s2,s6
    8000140c:	f9397ce3          	bgeu	s2,s3,800013a4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001410:	4601                	li	a2,0
    80001412:	85ca                	mv	a1,s2
    80001414:	8552                	mv	a0,s4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	cb0080e7          	jalr	-848(ra) # 800010c6 <walk>
    8000141e:	84aa                	mv	s1,a0
    80001420:	d54d                	beqz	a0,800013ca <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001422:	6108                	ld	a0,0(a0)
    80001424:	00157793          	andi	a5,a0,1
    80001428:	dbcd                	beqz	a5,800013da <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000142a:	3ff57793          	andi	a5,a0,1023
    8000142e:	fb778ee3          	beq	a5,s7,800013ea <uvmunmap+0x76>
    if(do_free){
    80001432:	fc0a8ae3          	beqz	s5,80001406 <uvmunmap+0x92>
    80001436:	b7d1                	j	800013fa <uvmunmap+0x86>

0000000080001438 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001438:	1101                	addi	sp,sp,-32
    8000143a:	ec06                	sd	ra,24(sp)
    8000143c:	e822                	sd	s0,16(sp)
    8000143e:	e426                	sd	s1,8(sp)
    80001440:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	760080e7          	jalr	1888(ra) # 80000ba2 <kalloc>
    8000144a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000144c:	c519                	beqz	a0,8000145a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	988080e7          	jalr	-1656(ra) # 80000dda <memset>
  return pagetable;
}
    8000145a:	8526                	mv	a0,s1
    8000145c:	60e2                	ld	ra,24(sp)
    8000145e:	6442                	ld	s0,16(sp)
    80001460:	64a2                	ld	s1,8(sp)
    80001462:	6105                	addi	sp,sp,32
    80001464:	8082                	ret

0000000080001466 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001466:	7179                	addi	sp,sp,-48
    80001468:	f406                	sd	ra,40(sp)
    8000146a:	f022                	sd	s0,32(sp)
    8000146c:	ec26                	sd	s1,24(sp)
    8000146e:	e84a                	sd	s2,16(sp)
    80001470:	e44e                	sd	s3,8(sp)
    80001472:	e052                	sd	s4,0(sp)
    80001474:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001476:	6785                	lui	a5,0x1
    80001478:	04f67863          	bgeu	a2,a5,800014c8 <uvmfirst+0x62>
    8000147c:	8a2a                	mv	s4,a0
    8000147e:	89ae                	mv	s3,a1
    80001480:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	720080e7          	jalr	1824(ra) # 80000ba2 <kalloc>
    8000148a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000148c:	6605                	lui	a2,0x1
    8000148e:	4581                	li	a1,0
    80001490:	00000097          	auipc	ra,0x0
    80001494:	94a080e7          	jalr	-1718(ra) # 80000dda <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001498:	4779                	li	a4,30
    8000149a:	86ca                	mv	a3,s2
    8000149c:	6605                	lui	a2,0x1
    8000149e:	4581                	li	a1,0
    800014a0:	8552                	mv	a0,s4
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	d0c080e7          	jalr	-756(ra) # 800011ae <mappages>
  memmove(mem, src, sz);
    800014aa:	8626                	mv	a2,s1
    800014ac:	85ce                	mv	a1,s3
    800014ae:	854a                	mv	a0,s2
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	98a080e7          	jalr	-1654(ra) # 80000e3a <memmove>
}
    800014b8:	70a2                	ld	ra,40(sp)
    800014ba:	7402                	ld	s0,32(sp)
    800014bc:	64e2                	ld	s1,24(sp)
    800014be:	6942                	ld	s2,16(sp)
    800014c0:	69a2                	ld	s3,8(sp)
    800014c2:	6a02                	ld	s4,0(sp)
    800014c4:	6145                	addi	sp,sp,48
    800014c6:	8082                	ret
    panic("uvmfirst: more than a page");
    800014c8:	00007517          	auipc	a0,0x7
    800014cc:	cd050513          	addi	a0,a0,-816 # 80008198 <digits+0x148>
    800014d0:	fffff097          	auipc	ra,0xfffff
    800014d4:	074080e7          	jalr	116(ra) # 80000544 <panic>

00000000800014d8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d8:	1101                	addi	sp,sp,-32
    800014da:	ec06                	sd	ra,24(sp)
    800014dc:	e822                	sd	s0,16(sp)
    800014de:	e426                	sd	s1,8(sp)
    800014e0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014e4:	00b67d63          	bgeu	a2,a1,800014fe <uvmdealloc+0x26>
    800014e8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ea:	6785                	lui	a5,0x1
    800014ec:	17fd                	addi	a5,a5,-1
    800014ee:	00f60733          	add	a4,a2,a5
    800014f2:	767d                	lui	a2,0xfffff
    800014f4:	8f71                	and	a4,a4,a2
    800014f6:	97ae                	add	a5,a5,a1
    800014f8:	8ff1                	and	a5,a5,a2
    800014fa:	00f76863          	bltu	a4,a5,8000150a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014fe:	8526                	mv	a0,s1
    80001500:	60e2                	ld	ra,24(sp)
    80001502:	6442                	ld	s0,16(sp)
    80001504:	64a2                	ld	s1,8(sp)
    80001506:	6105                	addi	sp,sp,32
    80001508:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000150a:	8f99                	sub	a5,a5,a4
    8000150c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000150e:	4685                	li	a3,1
    80001510:	0007861b          	sext.w	a2,a5
    80001514:	85ba                	mv	a1,a4
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	e5e080e7          	jalr	-418(ra) # 80001374 <uvmunmap>
    8000151e:	b7c5                	j	800014fe <uvmdealloc+0x26>

0000000080001520 <uvmalloc>:
  if(newsz < oldsz)
    80001520:	0ab66563          	bltu	a2,a1,800015ca <uvmalloc+0xaa>
{
    80001524:	7139                	addi	sp,sp,-64
    80001526:	fc06                	sd	ra,56(sp)
    80001528:	f822                	sd	s0,48(sp)
    8000152a:	f426                	sd	s1,40(sp)
    8000152c:	f04a                	sd	s2,32(sp)
    8000152e:	ec4e                	sd	s3,24(sp)
    80001530:	e852                	sd	s4,16(sp)
    80001532:	e456                	sd	s5,8(sp)
    80001534:	e05a                	sd	s6,0(sp)
    80001536:	0080                	addi	s0,sp,64
    80001538:	8aaa                	mv	s5,a0
    8000153a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000153c:	6985                	lui	s3,0x1
    8000153e:	19fd                	addi	s3,s3,-1
    80001540:	95ce                	add	a1,a1,s3
    80001542:	79fd                	lui	s3,0xfffff
    80001544:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001548:	08c9f363          	bgeu	s3,a2,800015ce <uvmalloc+0xae>
    8000154c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000154e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001552:	fffff097          	auipc	ra,0xfffff
    80001556:	650080e7          	jalr	1616(ra) # 80000ba2 <kalloc>
    8000155a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000155c:	c51d                	beqz	a0,8000158a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000155e:	6605                	lui	a2,0x1
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	878080e7          	jalr	-1928(ra) # 80000dda <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000156a:	875a                	mv	a4,s6
    8000156c:	86a6                	mv	a3,s1
    8000156e:	6605                	lui	a2,0x1
    80001570:	85ca                	mv	a1,s2
    80001572:	8556                	mv	a0,s5
    80001574:	00000097          	auipc	ra,0x0
    80001578:	c3a080e7          	jalr	-966(ra) # 800011ae <mappages>
    8000157c:	e90d                	bnez	a0,800015ae <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000157e:	6785                	lui	a5,0x1
    80001580:	993e                	add	s2,s2,a5
    80001582:	fd4968e3          	bltu	s2,s4,80001552 <uvmalloc+0x32>
  return newsz;
    80001586:	8552                	mv	a0,s4
    80001588:	a809                	j	8000159a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000158a:	864e                	mv	a2,s3
    8000158c:	85ca                	mv	a1,s2
    8000158e:	8556                	mv	a0,s5
    80001590:	00000097          	auipc	ra,0x0
    80001594:	f48080e7          	jalr	-184(ra) # 800014d8 <uvmdealloc>
      return 0;
    80001598:	4501                	li	a0,0
}
    8000159a:	70e2                	ld	ra,56(sp)
    8000159c:	7442                	ld	s0,48(sp)
    8000159e:	74a2                	ld	s1,40(sp)
    800015a0:	7902                	ld	s2,32(sp)
    800015a2:	69e2                	ld	s3,24(sp)
    800015a4:	6a42                	ld	s4,16(sp)
    800015a6:	6aa2                	ld	s5,8(sp)
    800015a8:	6b02                	ld	s6,0(sp)
    800015aa:	6121                	addi	sp,sp,64
    800015ac:	8082                	ret
      kfree(mem);
    800015ae:	8526                	mv	a0,s1
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	460080e7          	jalr	1120(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015b8:	864e                	mv	a2,s3
    800015ba:	85ca                	mv	a1,s2
    800015bc:	8556                	mv	a0,s5
    800015be:	00000097          	auipc	ra,0x0
    800015c2:	f1a080e7          	jalr	-230(ra) # 800014d8 <uvmdealloc>
      return 0;
    800015c6:	4501                	li	a0,0
    800015c8:	bfc9                	j	8000159a <uvmalloc+0x7a>
    return oldsz;
    800015ca:	852e                	mv	a0,a1
}
    800015cc:	8082                	ret
  return newsz;
    800015ce:	8532                	mv	a0,a2
    800015d0:	b7e9                	j	8000159a <uvmalloc+0x7a>

00000000800015d2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015d2:	7179                	addi	sp,sp,-48
    800015d4:	f406                	sd	ra,40(sp)
    800015d6:	f022                	sd	s0,32(sp)
    800015d8:	ec26                	sd	s1,24(sp)
    800015da:	e84a                	sd	s2,16(sp)
    800015dc:	e44e                	sd	s3,8(sp)
    800015de:	e052                	sd	s4,0(sp)
    800015e0:	1800                	addi	s0,sp,48
    800015e2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015e4:	84aa                	mv	s1,a0
    800015e6:	6905                	lui	s2,0x1
    800015e8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ea:	4985                	li	s3,1
    800015ec:	a821                	j	80001604 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ee:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015f0:	0532                	slli	a0,a0,0xc
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	fe0080e7          	jalr	-32(ra) # 800015d2 <freewalk>
      pagetable[i] = 0;
    800015fa:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015fe:	04a1                	addi	s1,s1,8
    80001600:	03248163          	beq	s1,s2,80001622 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001604:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001606:	00f57793          	andi	a5,a0,15
    8000160a:	ff3782e3          	beq	a5,s3,800015ee <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000160e:	8905                	andi	a0,a0,1
    80001610:	d57d                	beqz	a0,800015fe <freewalk+0x2c>
      panic("freewalk: leaf");
    80001612:	00007517          	auipc	a0,0x7
    80001616:	ba650513          	addi	a0,a0,-1114 # 800081b8 <digits+0x168>
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	f2a080e7          	jalr	-214(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    80001622:	8552                	mv	a0,s4
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	3ec080e7          	jalr	1004(ra) # 80000a10 <kfree>
}
    8000162c:	70a2                	ld	ra,40(sp)
    8000162e:	7402                	ld	s0,32(sp)
    80001630:	64e2                	ld	s1,24(sp)
    80001632:	6942                	ld	s2,16(sp)
    80001634:	69a2                	ld	s3,8(sp)
    80001636:	6a02                	ld	s4,0(sp)
    80001638:	6145                	addi	sp,sp,48
    8000163a:	8082                	ret

000000008000163c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000163c:	1101                	addi	sp,sp,-32
    8000163e:	ec06                	sd	ra,24(sp)
    80001640:	e822                	sd	s0,16(sp)
    80001642:	e426                	sd	s1,8(sp)
    80001644:	1000                	addi	s0,sp,32
    80001646:	84aa                	mv	s1,a0
  if(sz > 0)
    80001648:	e999                	bnez	a1,8000165e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000164a:	8526                	mv	a0,s1
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	f86080e7          	jalr	-122(ra) # 800015d2 <freewalk>
}
    80001654:	60e2                	ld	ra,24(sp)
    80001656:	6442                	ld	s0,16(sp)
    80001658:	64a2                	ld	s1,8(sp)
    8000165a:	6105                	addi	sp,sp,32
    8000165c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000165e:	6605                	lui	a2,0x1
    80001660:	167d                	addi	a2,a2,-1
    80001662:	962e                	add	a2,a2,a1
    80001664:	4685                	li	a3,1
    80001666:	8231                	srli	a2,a2,0xc
    80001668:	4581                	li	a1,0
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	d0a080e7          	jalr	-758(ra) # 80001374 <uvmunmap>
    80001672:	bfe1                	j	8000164a <uvmfree+0xe>

0000000080001674 <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001674:	10060863          	beqz	a2,80001784 <uvmcopy+0x110>
{
    80001678:	711d                	addi	sp,sp,-96
    8000167a:	ec86                	sd	ra,88(sp)
    8000167c:	e8a2                	sd	s0,80(sp)
    8000167e:	e4a6                	sd	s1,72(sp)
    80001680:	e0ca                	sd	s2,64(sp)
    80001682:	fc4e                	sd	s3,56(sp)
    80001684:	f852                	sd	s4,48(sp)
    80001686:	f456                	sd	s5,40(sp)
    80001688:	f05a                	sd	s6,32(sp)
    8000168a:	ec5e                	sd	s7,24(sp)
    8000168c:	e862                	sd	s8,16(sp)
    8000168e:	e466                	sd	s9,8(sp)
    80001690:	1080                	addi	s0,sp,96
    80001692:	8b2a                	mv	s6,a0
    80001694:	8aae                	mv	s5,a1
    80001696:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001698:	4901                	li	s2,0
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    

    references[PTE2PPN(*pte)] ++;
    8000169a:	0000f997          	auipc	s3,0xf
    8000169e:	68698993          	addi	s3,s3,1670 # 80010d20 <references>
    printf("uvmcopy: %d\n", references[PTE2PPN(*pte)]);
    800016a2:	00007c97          	auipc	s9,0x7
    800016a6:	b66c8c93          	addi	s9,s9,-1178 # 80008208 <digits+0x1b8>
    printf("ppn: %d\n", PTE2PPN(*pte));
    800016aa:	00007c17          	auipc	s8,0x7
    800016ae:	b6ec0c13          	addi	s8,s8,-1170 # 80008218 <digits+0x1c8>
    printf("pte: %d\n", *pte);
    800016b2:	00007b97          	auipc	s7,0x7
    800016b6:	b76b8b93          	addi	s7,s7,-1162 # 80008228 <digits+0x1d8>
    if((pte = walk(old, i, 0)) == 0)
    800016ba:	4601                	li	a2,0
    800016bc:	85ca                	mv	a1,s2
    800016be:	855a                	mv	a0,s6
    800016c0:	00000097          	auipc	ra,0x0
    800016c4:	a06080e7          	jalr	-1530(ra) # 800010c6 <walk>
    800016c8:	84aa                	mv	s1,a0
    800016ca:	c535                	beqz	a0,80001736 <uvmcopy+0xc2>
    if((*pte & PTE_V) == 0)
    800016cc:	611c                	ld	a5,0(a0)
    800016ce:	0017f713          	andi	a4,a5,1
    800016d2:	cb35                	beqz	a4,80001746 <uvmcopy+0xd2>
    references[PTE2PPN(*pte)] ++;
    800016d4:	83a9                	srli	a5,a5,0xa
    800016d6:	97ce                	add	a5,a5,s3
    800016d8:	0007c703          	lbu	a4,0(a5) # 1000 <_entry-0x7ffff000>
    800016dc:	2705                	addiw	a4,a4,1
    800016de:	00e78023          	sb	a4,0(a5)
    printf("uvmcopy: %d\n", references[PTE2PPN(*pte)]);
    800016e2:	611c                	ld	a5,0(a0)
    800016e4:	83a9                	srli	a5,a5,0xa
    800016e6:	97ce                	add	a5,a5,s3
    800016e8:	0007c583          	lbu	a1,0(a5)
    800016ec:	8566                	mv	a0,s9
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	eb2080e7          	jalr	-334(ra) # 800005a0 <printf>
    printf("ppn: %d\n", PTE2PPN(*pte));
    800016f6:	608c                	ld	a1,0(s1)
    800016f8:	81a9                	srli	a1,a1,0xa
    800016fa:	8562                	mv	a0,s8
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	ea4080e7          	jalr	-348(ra) # 800005a0 <printf>
    printf("pte: %d\n", *pte);
    80001704:	608c                	ld	a1,0(s1)
    80001706:	855e                	mv	a0,s7
    80001708:	fffff097          	auipc	ra,0xfffff
    8000170c:	e98080e7          	jalr	-360(ra) # 800005a0 <printf>
    pa = PTE2PA(*pte);
    80001710:	6098                	ld	a4,0(s1)
    80001712:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & 0x3FB;

    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80001716:	3fb77713          	andi	a4,a4,1019
    8000171a:	06b2                	slli	a3,a3,0xc
    8000171c:	6605                	lui	a2,0x1
    8000171e:	85ca                	mv	a1,s2
    80001720:	8556                	mv	a0,s5
    80001722:	00000097          	auipc	ra,0x0
    80001726:	a8c080e7          	jalr	-1396(ra) # 800011ae <mappages>
    8000172a:	e515                	bnez	a0,80001756 <uvmcopy+0xe2>
  for(i = 0; i < sz; i += PGSIZE){
    8000172c:	6785                	lui	a5,0x1
    8000172e:	993e                	add	s2,s2,a5
    80001730:	f94965e3          	bltu	s2,s4,800016ba <uvmcopy+0x46>
    80001734:	a81d                	j	8000176a <uvmcopy+0xf6>
      panic("uvmcopy: pte should exist");
    80001736:	00007517          	auipc	a0,0x7
    8000173a:	a9250513          	addi	a0,a0,-1390 # 800081c8 <digits+0x178>
    8000173e:	fffff097          	auipc	ra,0xfffff
    80001742:	e06080e7          	jalr	-506(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    80001746:	00007517          	auipc	a0,0x7
    8000174a:	aa250513          	addi	a0,a0,-1374 # 800081e8 <digits+0x198>
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	df6080e7          	jalr	-522(ra) # 80000544 <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001756:	4685                	li	a3,1
    80001758:	00c95613          	srli	a2,s2,0xc
    8000175c:	4581                	li	a1,0
    8000175e:	8556                	mv	a0,s5
    80001760:	00000097          	auipc	ra,0x0
    80001764:	c14080e7          	jalr	-1004(ra) # 80001374 <uvmunmap>
  return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60e6                	ld	ra,88(sp)
    8000176c:	6446                	ld	s0,80(sp)
    8000176e:	64a6                	ld	s1,72(sp)
    80001770:	6906                	ld	s2,64(sp)
    80001772:	79e2                	ld	s3,56(sp)
    80001774:	7a42                	ld	s4,48(sp)
    80001776:	7aa2                	ld	s5,40(sp)
    80001778:	7b02                	ld	s6,32(sp)
    8000177a:	6be2                	ld	s7,24(sp)
    8000177c:	6c42                	ld	s8,16(sp)
    8000177e:	6ca2                	ld	s9,8(sp)
    80001780:	6125                	addi	sp,sp,96
    80001782:	8082                	ret
  return 0;
    80001784:	4501                	li	a0,0
}
    80001786:	8082                	ret

0000000080001788 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001790:	4601                	li	a2,0
    80001792:	00000097          	auipc	ra,0x0
    80001796:	934080e7          	jalr	-1740(ra) # 800010c6 <walk>
  if(pte == 0)
    8000179a:	c901                	beqz	a0,800017aa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179c:	611c                	ld	a5,0(a0)
    8000179e:	9bbd                	andi	a5,a5,-17
    800017a0:	e11c                	sd	a5,0(a0)
}
    800017a2:	60a2                	ld	ra,8(sp)
    800017a4:	6402                	ld	s0,0(sp)
    800017a6:	0141                	addi	sp,sp,16
    800017a8:	8082                	ret
    panic("uvmclear");
    800017aa:	00007517          	auipc	a0,0x7
    800017ae:	a8e50513          	addi	a0,a0,-1394 # 80008238 <digits+0x1e8>
    800017b2:	fffff097          	auipc	ra,0xfffff
    800017b6:	d92080e7          	jalr	-622(ra) # 80000544 <panic>

00000000800017ba <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	c6bd                	beqz	a3,80001828 <copyout+0x6e>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8c2e                	mv	s8,a1
    800017d8:	8a32                	mv	s4,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a015                	j	80001804 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e2:	9562                	add	a0,a0,s8
    800017e4:	0004861b          	sext.w	a2,s1
    800017e8:	85d2                	mv	a1,s4
    800017ea:	41250533          	sub	a0,a0,s2
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	64c080e7          	jalr	1612(ra) # 80000e3a <memmove>

    len -= n;
    800017f6:	409989b3          	sub	s3,s3,s1
    src += n;
    800017fa:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017fc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001800:	02098263          	beqz	s3,80001824 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001804:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855a                	mv	a0,s6
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	960080e7          	jalr	-1696(ra) # 8000116c <walkaddr>
    if(pa0 == 0)
    80001814:	cd01                	beqz	a0,8000182c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001816:	418904b3          	sub	s1,s2,s8
    8000181a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000181c:	fc99f3e3          	bgeu	s3,s1,800017e2 <copyout+0x28>
    80001820:	84ce                	mv	s1,s3
    80001822:	b7c1                	j	800017e2 <copyout+0x28>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyout+0x74>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6c02                	ld	s8,0(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret

0000000080001846 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001846:	c6bd                	beqz	a3,800018b4 <copyin+0x6e>
{
    80001848:	715d                	addi	sp,sp,-80
    8000184a:	e486                	sd	ra,72(sp)
    8000184c:	e0a2                	sd	s0,64(sp)
    8000184e:	fc26                	sd	s1,56(sp)
    80001850:	f84a                	sd	s2,48(sp)
    80001852:	f44e                	sd	s3,40(sp)
    80001854:	f052                	sd	s4,32(sp)
    80001856:	ec56                	sd	s5,24(sp)
    80001858:	e85a                	sd	s6,16(sp)
    8000185a:	e45e                	sd	s7,8(sp)
    8000185c:	e062                	sd	s8,0(sp)
    8000185e:	0880                	addi	s0,sp,80
    80001860:	8b2a                	mv	s6,a0
    80001862:	8a2e                	mv	s4,a1
    80001864:	8c32                	mv	s8,a2
    80001866:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001868:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186a:	6a85                	lui	s5,0x1
    8000186c:	a015                	j	80001890 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186e:	9562                	add	a0,a0,s8
    80001870:	0004861b          	sext.w	a2,s1
    80001874:	412505b3          	sub	a1,a0,s2
    80001878:	8552                	mv	a0,s4
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	5c0080e7          	jalr	1472(ra) # 80000e3a <memmove>

    len -= n;
    80001882:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001886:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001888:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188c:	02098263          	beqz	s3,800018b0 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001890:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001894:	85ca                	mv	a1,s2
    80001896:	855a                	mv	a0,s6
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8d4080e7          	jalr	-1836(ra) # 8000116c <walkaddr>
    if(pa0 == 0)
    800018a0:	cd01                	beqz	a0,800018b8 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018a2:	418904b3          	sub	s1,s2,s8
    800018a6:	94d6                	add	s1,s1,s5
    if(n > len)
    800018a8:	fc99f3e3          	bgeu	s3,s1,8000186e <copyin+0x28>
    800018ac:	84ce                	mv	s1,s3
    800018ae:	b7c1                	j	8000186e <copyin+0x28>
  }
  return 0;
    800018b0:	4501                	li	a0,0
    800018b2:	a021                	j	800018ba <copyin+0x74>
    800018b4:	4501                	li	a0,0
}
    800018b6:	8082                	ret
      return -1;
    800018b8:	557d                	li	a0,-1
}
    800018ba:	60a6                	ld	ra,72(sp)
    800018bc:	6406                	ld	s0,64(sp)
    800018be:	74e2                	ld	s1,56(sp)
    800018c0:	7942                	ld	s2,48(sp)
    800018c2:	79a2                	ld	s3,40(sp)
    800018c4:	7a02                	ld	s4,32(sp)
    800018c6:	6ae2                	ld	s5,24(sp)
    800018c8:	6b42                	ld	s6,16(sp)
    800018ca:	6ba2                	ld	s7,8(sp)
    800018cc:	6c02                	ld	s8,0(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret

00000000800018d2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d2:	c6c5                	beqz	a3,8000197a <copyinstr+0xa8>
{
    800018d4:	715d                	addi	sp,sp,-80
    800018d6:	e486                	sd	ra,72(sp)
    800018d8:	e0a2                	sd	s0,64(sp)
    800018da:	fc26                	sd	s1,56(sp)
    800018dc:	f84a                	sd	s2,48(sp)
    800018de:	f44e                	sd	s3,40(sp)
    800018e0:	f052                	sd	s4,32(sp)
    800018e2:	ec56                	sd	s5,24(sp)
    800018e4:	e85a                	sd	s6,16(sp)
    800018e6:	e45e                	sd	s7,8(sp)
    800018e8:	0880                	addi	s0,sp,80
    800018ea:	8a2a                	mv	s4,a0
    800018ec:	8b2e                	mv	s6,a1
    800018ee:	8bb2                	mv	s7,a2
    800018f0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f4:	6985                	lui	s3,0x1
    800018f6:	a035                	j	80001922 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fe:	0017b793          	seqz	a5,a5
    80001902:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001906:	60a6                	ld	ra,72(sp)
    80001908:	6406                	ld	s0,64(sp)
    8000190a:	74e2                	ld	s1,56(sp)
    8000190c:	7942                	ld	s2,48(sp)
    8000190e:	79a2                	ld	s3,40(sp)
    80001910:	7a02                	ld	s4,32(sp)
    80001912:	6ae2                	ld	s5,24(sp)
    80001914:	6b42                	ld	s6,16(sp)
    80001916:	6ba2                	ld	s7,8(sp)
    80001918:	6161                	addi	sp,sp,80
    8000191a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001920:	c8a9                	beqz	s1,80001972 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001922:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001926:	85ca                	mv	a1,s2
    80001928:	8552                	mv	a0,s4
    8000192a:	00000097          	auipc	ra,0x0
    8000192e:	842080e7          	jalr	-1982(ra) # 8000116c <walkaddr>
    if(pa0 == 0)
    80001932:	c131                	beqz	a0,80001976 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001934:	41790833          	sub	a6,s2,s7
    80001938:	984e                	add	a6,a6,s3
    if(n > max)
    8000193a:	0104f363          	bgeu	s1,a6,80001940 <copyinstr+0x6e>
    8000193e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001940:	955e                	add	a0,a0,s7
    80001942:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001946:	fc080be3          	beqz	a6,8000191c <copyinstr+0x4a>
    8000194a:	985a                	add	a6,a6,s6
    8000194c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000194e:	41650633          	sub	a2,a0,s6
    80001952:	14fd                	addi	s1,s1,-1
    80001954:	9b26                	add	s6,s6,s1
    80001956:	00f60733          	add	a4,a2,a5
    8000195a:	00074703          	lbu	a4,0(a4)
    8000195e:	df49                	beqz	a4,800018f8 <copyinstr+0x26>
        *dst = *p;
    80001960:	00e78023          	sb	a4,0(a5)
      --max;
    80001964:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001968:	0785                	addi	a5,a5,1
    while(n > 0){
    8000196a:	ff0796e3          	bne	a5,a6,80001956 <copyinstr+0x84>
      dst++;
    8000196e:	8b42                	mv	s6,a6
    80001970:	b775                	j	8000191c <copyinstr+0x4a>
    80001972:	4781                	li	a5,0
    80001974:	b769                	j	800018fe <copyinstr+0x2c>
      return -1;
    80001976:	557d                	li	a0,-1
    80001978:	b779                	j	80001906 <copyinstr+0x34>
  int got_null = 0;
    8000197a:	4781                	li	a5,0
  if(got_null){
    8000197c:	0017b793          	seqz	a5,a5
    80001980:	40f00533          	neg	a0,a5
}
    80001984:	8082                	ret

0000000080001986 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001986:	715d                	addi	sp,sp,-80
    80001988:	e486                	sd	ra,72(sp)
    8000198a:	e0a2                	sd	s0,64(sp)
    8000198c:	fc26                	sd	s1,56(sp)
    8000198e:	f84a                	sd	s2,48(sp)
    80001990:	f44e                	sd	s3,40(sp)
    80001992:	f052                	sd	s4,32(sp)
    80001994:	ec56                	sd	s5,24(sp)
    80001996:	e85a                	sd	s6,16(sp)
    80001998:	e45e                	sd	s7,8(sp)
    8000199a:	e062                	sd	s8,0(sp)
    8000199c:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199e:	8912                	mv	s2,tp
    int id = r_tp();
    800019a0:	2901                	sext.w	s2,s2
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    800019a2:	00017a97          	auipc	s5,0x17
    800019a6:	37ea8a93          	addi	s5,s5,894 # 80018d20 <cpus>
    800019aa:	00791793          	slli	a5,s2,0x7
    800019ae:	00fa8733          	add	a4,s5,a5
    800019b2:	00073023          	sd	zero,0(a4)
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    800019b6:	07a1                	addi	a5,a5,8
    800019b8:	9abe                	add	s5,s5,a5
                c->proc = p;
    800019ba:	893a                	mv	s2,a4
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    800019bc:	00007c17          	auipc	s8,0x7
    800019c0:	01cc0c13          	addi	s8,s8,28 # 800089d8 <sched_pointer>
    800019c4:	00000b97          	auipc	s7,0x0
    800019c8:	fc2b8b93          	addi	s7,s7,-62 # 80001986 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800019d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800019d4:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    800019d8:	00017497          	auipc	s1,0x17
    800019dc:	77848493          	addi	s1,s1,1912 # 80019150 <proc>
            if (p->state == RUNNABLE)
    800019e0:	498d                	li	s3,3
                p->state = RUNNING;
    800019e2:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    800019e4:	0001da17          	auipc	s4,0x1d
    800019e8:	16ca0a13          	addi	s4,s4,364 # 8001eb50 <tickslock>
    800019ec:	a81d                	j	80001a22 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    800019ee:	8526                	mv	a0,s1
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	3a2080e7          	jalr	930(ra) # 80000d92 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    800019f8:	60a6                	ld	ra,72(sp)
    800019fa:	6406                	ld	s0,64(sp)
    800019fc:	74e2                	ld	s1,56(sp)
    800019fe:	7942                	ld	s2,48(sp)
    80001a00:	79a2                	ld	s3,40(sp)
    80001a02:	7a02                	ld	s4,32(sp)
    80001a04:	6ae2                	ld	s5,24(sp)
    80001a06:	6b42                	ld	s6,16(sp)
    80001a08:	6ba2                	ld	s7,8(sp)
    80001a0a:	6c02                	ld	s8,0(sp)
    80001a0c:	6161                	addi	sp,sp,80
    80001a0e:	8082                	ret
            release(&p->lock);
    80001a10:	8526                	mv	a0,s1
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	380080e7          	jalr	896(ra) # 80000d92 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a1a:	16848493          	addi	s1,s1,360
    80001a1e:	fb4487e3          	beq	s1,s4,800019cc <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a22:	8526                	mv	a0,s1
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	2ba080e7          	jalr	698(ra) # 80000cde <acquire>
            if (p->state == RUNNABLE)
    80001a2c:	4c9c                	lw	a5,24(s1)
    80001a2e:	ff3791e3          	bne	a5,s3,80001a10 <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001a32:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001a36:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001a3a:	06048593          	addi	a1,s1,96
    80001a3e:	8556                	mv	a0,s5
    80001a40:	00001097          	auipc	ra,0x1
    80001a44:	fa2080e7          	jalr	-94(ra) # 800029e2 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001a48:	000c3783          	ld	a5,0(s8)
    80001a4c:	fb7791e3          	bne	a5,s7,800019ee <rr_scheduler+0x68>
                c->proc = 0;
    80001a50:	00093023          	sd	zero,0(s2)
    80001a54:	bf75                	j	80001a10 <rr_scheduler+0x8a>

0000000080001a56 <proc_mapstacks>:
{
    80001a56:	7139                	addi	sp,sp,-64
    80001a58:	fc06                	sd	ra,56(sp)
    80001a5a:	f822                	sd	s0,48(sp)
    80001a5c:	f426                	sd	s1,40(sp)
    80001a5e:	f04a                	sd	s2,32(sp)
    80001a60:	ec4e                	sd	s3,24(sp)
    80001a62:	e852                	sd	s4,16(sp)
    80001a64:	e456                	sd	s5,8(sp)
    80001a66:	e05a                	sd	s6,0(sp)
    80001a68:	0080                	addi	s0,sp,64
    80001a6a:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a6c:	00017497          	auipc	s1,0x17
    80001a70:	6e448493          	addi	s1,s1,1764 # 80019150 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a74:	8b26                	mv	s6,s1
    80001a76:	00006a97          	auipc	s5,0x6
    80001a7a:	59aa8a93          	addi	s5,s5,1434 # 80008010 <__func__.1506+0x8>
    80001a7e:	04000937          	lui	s2,0x4000
    80001a82:	197d                	addi	s2,s2,-1
    80001a84:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a86:	0001da17          	auipc	s4,0x1d
    80001a8a:	0caa0a13          	addi	s4,s4,202 # 8001eb50 <tickslock>
        char *pa = kalloc();
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	114080e7          	jalr	276(ra) # 80000ba2 <kalloc>
    80001a96:	862a                	mv	a2,a0
        if (pa == 0)
    80001a98:	c131                	beqz	a0,80001adc <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a9a:	416485b3          	sub	a1,s1,s6
    80001a9e:	858d                	srai	a1,a1,0x3
    80001aa0:	000ab783          	ld	a5,0(s5)
    80001aa4:	02f585b3          	mul	a1,a1,a5
    80001aa8:	2585                	addiw	a1,a1,1
    80001aaa:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001aae:	4719                	li	a4,6
    80001ab0:	6685                	lui	a3,0x1
    80001ab2:	40b905b3          	sub	a1,s2,a1
    80001ab6:	854e                	mv	a0,s3
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	796080e7          	jalr	1942(ra) # 8000124e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ac0:	16848493          	addi	s1,s1,360
    80001ac4:	fd4495e3          	bne	s1,s4,80001a8e <proc_mapstacks+0x38>
}
    80001ac8:	70e2                	ld	ra,56(sp)
    80001aca:	7442                	ld	s0,48(sp)
    80001acc:	74a2                	ld	s1,40(sp)
    80001ace:	7902                	ld	s2,32(sp)
    80001ad0:	69e2                	ld	s3,24(sp)
    80001ad2:	6a42                	ld	s4,16(sp)
    80001ad4:	6aa2                	ld	s5,8(sp)
    80001ad6:	6b02                	ld	s6,0(sp)
    80001ad8:	6121                	addi	sp,sp,64
    80001ada:	8082                	ret
            panic("kalloc");
    80001adc:	00006517          	auipc	a0,0x6
    80001ae0:	76c50513          	addi	a0,a0,1900 # 80008248 <digits+0x1f8>
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	a60080e7          	jalr	-1440(ra) # 80000544 <panic>

0000000080001aec <procinit>:
{
    80001aec:	7139                	addi	sp,sp,-64
    80001aee:	fc06                	sd	ra,56(sp)
    80001af0:	f822                	sd	s0,48(sp)
    80001af2:	f426                	sd	s1,40(sp)
    80001af4:	f04a                	sd	s2,32(sp)
    80001af6:	ec4e                	sd	s3,24(sp)
    80001af8:	e852                	sd	s4,16(sp)
    80001afa:	e456                	sd	s5,8(sp)
    80001afc:	e05a                	sd	s6,0(sp)
    80001afe:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b00:	00006597          	auipc	a1,0x6
    80001b04:	75058593          	addi	a1,a1,1872 # 80008250 <digits+0x200>
    80001b08:	00017517          	auipc	a0,0x17
    80001b0c:	61850513          	addi	a0,a0,1560 # 80019120 <pid_lock>
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	13e080e7          	jalr	318(ra) # 80000c4e <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b18:	00006597          	auipc	a1,0x6
    80001b1c:	74058593          	addi	a1,a1,1856 # 80008258 <digits+0x208>
    80001b20:	00017517          	auipc	a0,0x17
    80001b24:	61850513          	addi	a0,a0,1560 # 80019138 <wait_lock>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	126080e7          	jalr	294(ra) # 80000c4e <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b30:	00017497          	auipc	s1,0x17
    80001b34:	62048493          	addi	s1,s1,1568 # 80019150 <proc>
        initlock(&p->lock, "proc");
    80001b38:	00006b17          	auipc	s6,0x6
    80001b3c:	730b0b13          	addi	s6,s6,1840 # 80008268 <digits+0x218>
        p->kstack = KSTACK((int)(p - proc));
    80001b40:	8aa6                	mv	s5,s1
    80001b42:	00006a17          	auipc	s4,0x6
    80001b46:	4cea0a13          	addi	s4,s4,1230 # 80008010 <__func__.1506+0x8>
    80001b4a:	04000937          	lui	s2,0x4000
    80001b4e:	197d                	addi	s2,s2,-1
    80001b50:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b52:	0001d997          	auipc	s3,0x1d
    80001b56:	ffe98993          	addi	s3,s3,-2 # 8001eb50 <tickslock>
        initlock(&p->lock, "proc");
    80001b5a:	85da                	mv	a1,s6
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	0f0080e7          	jalr	240(ra) # 80000c4e <initlock>
        p->state = UNUSED;
    80001b66:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b6a:	415487b3          	sub	a5,s1,s5
    80001b6e:	878d                	srai	a5,a5,0x3
    80001b70:	000a3703          	ld	a4,0(s4)
    80001b74:	02e787b3          	mul	a5,a5,a4
    80001b78:	2785                	addiw	a5,a5,1
    80001b7a:	00d7979b          	slliw	a5,a5,0xd
    80001b7e:	40f907b3          	sub	a5,s2,a5
    80001b82:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b84:	16848493          	addi	s1,s1,360
    80001b88:	fd3499e3          	bne	s1,s3,80001b5a <procinit+0x6e>
}
    80001b8c:	70e2                	ld	ra,56(sp)
    80001b8e:	7442                	ld	s0,48(sp)
    80001b90:	74a2                	ld	s1,40(sp)
    80001b92:	7902                	ld	s2,32(sp)
    80001b94:	69e2                	ld	s3,24(sp)
    80001b96:	6a42                	ld	s4,16(sp)
    80001b98:	6aa2                	ld	s5,8(sp)
    80001b9a:	6b02                	ld	s6,0(sp)
    80001b9c:	6121                	addi	sp,sp,64
    80001b9e:	8082                	ret

0000000080001ba0 <copy_array>:
{
    80001ba0:	1141                	addi	sp,sp,-16
    80001ba2:	e422                	sd	s0,8(sp)
    80001ba4:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001ba6:	02c05163          	blez	a2,80001bc8 <copy_array+0x28>
    80001baa:	87aa                	mv	a5,a0
    80001bac:	0505                	addi	a0,a0,1
    80001bae:	fff6069b          	addiw	a3,a2,-1
    80001bb2:	1682                	slli	a3,a3,0x20
    80001bb4:	9281                	srli	a3,a3,0x20
    80001bb6:	96aa                	add	a3,a3,a0
        dst[i] = src[i];
    80001bb8:	0007c703          	lbu	a4,0(a5)
    80001bbc:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001bc0:	0785                	addi	a5,a5,1
    80001bc2:	0585                	addi	a1,a1,1
    80001bc4:	fed79ae3          	bne	a5,a3,80001bb8 <copy_array+0x18>
}
    80001bc8:	6422                	ld	s0,8(sp)
    80001bca:	0141                	addi	sp,sp,16
    80001bcc:	8082                	ret

0000000080001bce <cpuid>:
{
    80001bce:	1141                	addi	sp,sp,-16
    80001bd0:	e422                	sd	s0,8(sp)
    80001bd2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd4:	8512                	mv	a0,tp
}
    80001bd6:	2501                	sext.w	a0,a0
    80001bd8:	6422                	ld	s0,8(sp)
    80001bda:	0141                	addi	sp,sp,16
    80001bdc:	8082                	ret

0000000080001bde <mycpu>:
{
    80001bde:	1141                	addi	sp,sp,-16
    80001be0:	e422                	sd	s0,8(sp)
    80001be2:	0800                	addi	s0,sp,16
    80001be4:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001be6:	2781                	sext.w	a5,a5
    80001be8:	079e                	slli	a5,a5,0x7
}
    80001bea:	00017517          	auipc	a0,0x17
    80001bee:	13650513          	addi	a0,a0,310 # 80018d20 <cpus>
    80001bf2:	953e                	add	a0,a0,a5
    80001bf4:	6422                	ld	s0,8(sp)
    80001bf6:	0141                	addi	sp,sp,16
    80001bf8:	8082                	ret

0000000080001bfa <myproc>:
{
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	1000                	addi	s0,sp,32
    push_off();
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	08e080e7          	jalr	142(ra) # 80000c92 <push_off>
    80001c0c:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c0e:	2781                	sext.w	a5,a5
    80001c10:	079e                	slli	a5,a5,0x7
    80001c12:	00017717          	auipc	a4,0x17
    80001c16:	10e70713          	addi	a4,a4,270 # 80018d20 <cpus>
    80001c1a:	97ba                	add	a5,a5,a4
    80001c1c:	6384                	ld	s1,0(a5)
    pop_off();
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	114080e7          	jalr	276(ra) # 80000d32 <pop_off>
}
    80001c26:	8526                	mv	a0,s1
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c32:	1141                	addi	sp,sp,-16
    80001c34:	e406                	sd	ra,8(sp)
    80001c36:	e022                	sd	s0,0(sp)
    80001c38:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	fc0080e7          	jalr	-64(ra) # 80001bfa <myproc>
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	150080e7          	jalr	336(ra) # 80000d92 <release>

    if (first)
    80001c4a:	00007797          	auipc	a5,0x7
    80001c4e:	d867a783          	lw	a5,-634(a5) # 800089d0 <first.1730>
    80001c52:	eb89                	bnez	a5,80001c64 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c54:	00001097          	auipc	ra,0x1
    80001c58:	e38080e7          	jalr	-456(ra) # 80002a8c <usertrapret>
}
    80001c5c:	60a2                	ld	ra,8(sp)
    80001c5e:	6402                	ld	s0,0(sp)
    80001c60:	0141                	addi	sp,sp,16
    80001c62:	8082                	ret
        first = 0;
    80001c64:	00007797          	auipc	a5,0x7
    80001c68:	d607a623          	sw	zero,-660(a5) # 800089d0 <first.1730>
        fsinit(ROOTDEV);
    80001c6c:	4505                	li	a0,1
    80001c6e:	00002097          	auipc	ra,0x2
    80001c72:	d90080e7          	jalr	-624(ra) # 800039fe <fsinit>
    80001c76:	bff9                	j	80001c54 <forkret+0x22>

0000000080001c78 <allocpid>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	e04a                	sd	s2,0(sp)
    80001c82:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c84:	00017917          	auipc	s2,0x17
    80001c88:	49c90913          	addi	s2,s2,1180 # 80019120 <pid_lock>
    80001c8c:	854a                	mv	a0,s2
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	050080e7          	jalr	80(ra) # 80000cde <acquire>
    pid = nextpid;
    80001c96:	00007797          	auipc	a5,0x7
    80001c9a:	d4a78793          	addi	a5,a5,-694 # 800089e0 <nextpid>
    80001c9e:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001ca0:	0014871b          	addiw	a4,s1,1
    80001ca4:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001ca6:	854a                	mv	a0,s2
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	0ea080e7          	jalr	234(ra) # 80000d92 <release>
}
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6902                	ld	s2,0(sp)
    80001cba:	6105                	addi	sp,sp,32
    80001cbc:	8082                	ret

0000000080001cbe <proc_pagetable>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	e04a                	sd	s2,0(sp)
    80001cc8:	1000                	addi	s0,sp,32
    80001cca:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	76c080e7          	jalr	1900(ra) # 80001438 <uvmcreate>
    80001cd4:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001cd6:	c121                	beqz	a0,80001d16 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cd8:	4729                	li	a4,10
    80001cda:	00005697          	auipc	a3,0x5
    80001cde:	32668693          	addi	a3,a3,806 # 80007000 <_trampoline>
    80001ce2:	6605                	lui	a2,0x1
    80001ce4:	040005b7          	lui	a1,0x4000
    80001ce8:	15fd                	addi	a1,a1,-1
    80001cea:	05b2                	slli	a1,a1,0xc
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	4c2080e7          	jalr	1218(ra) # 800011ae <mappages>
    80001cf4:	02054863          	bltz	a0,80001d24 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cf8:	4719                	li	a4,6
    80001cfa:	05893683          	ld	a3,88(s2)
    80001cfe:	6605                	lui	a2,0x1
    80001d00:	020005b7          	lui	a1,0x2000
    80001d04:	15fd                	addi	a1,a1,-1
    80001d06:	05b6                	slli	a1,a1,0xd
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	4a4080e7          	jalr	1188(ra) # 800011ae <mappages>
    80001d12:	02054163          	bltz	a0,80001d34 <proc_pagetable+0x76>
}
    80001d16:	8526                	mv	a0,s1
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6902                	ld	s2,0(sp)
    80001d20:	6105                	addi	sp,sp,32
    80001d22:	8082                	ret
        uvmfree(pagetable, 0);
    80001d24:	4581                	li	a1,0
    80001d26:	8526                	mv	a0,s1
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	914080e7          	jalr	-1772(ra) # 8000163c <uvmfree>
        return 0;
    80001d30:	4481                	li	s1,0
    80001d32:	b7d5                	j	80001d16 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d34:	4681                	li	a3,0
    80001d36:	4605                	li	a2,1
    80001d38:	040005b7          	lui	a1,0x4000
    80001d3c:	15fd                	addi	a1,a1,-1
    80001d3e:	05b2                	slli	a1,a1,0xc
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	632080e7          	jalr	1586(ra) # 80001374 <uvmunmap>
        uvmfree(pagetable, 0);
    80001d4a:	4581                	li	a1,0
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	8ee080e7          	jalr	-1810(ra) # 8000163c <uvmfree>
        return 0;
    80001d56:	4481                	li	s1,0
    80001d58:	bf7d                	j	80001d16 <proc_pagetable+0x58>

0000000080001d5a <proc_freepagetable>:
{
    80001d5a:	1101                	addi	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	e04a                	sd	s2,0(sp)
    80001d64:	1000                	addi	s0,sp,32
    80001d66:	84aa                	mv	s1,a0
    80001d68:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d6a:	4681                	li	a3,0
    80001d6c:	4605                	li	a2,1
    80001d6e:	040005b7          	lui	a1,0x4000
    80001d72:	15fd                	addi	a1,a1,-1
    80001d74:	05b2                	slli	a1,a1,0xc
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	5fe080e7          	jalr	1534(ra) # 80001374 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d7e:	4681                	li	a3,0
    80001d80:	4605                	li	a2,1
    80001d82:	020005b7          	lui	a1,0x2000
    80001d86:	15fd                	addi	a1,a1,-1
    80001d88:	05b6                	slli	a1,a1,0xd
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	5e8080e7          	jalr	1512(ra) # 80001374 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d94:	85ca                	mv	a1,s2
    80001d96:	8526                	mv	a0,s1
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	8a4080e7          	jalr	-1884(ra) # 8000163c <uvmfree>
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6902                	ld	s2,0(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <freeproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	1000                	addi	s0,sp,32
    80001db6:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001db8:	6d28                	ld	a0,88(a0)
    80001dba:	c509                	beqz	a0,80001dc4 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	c54080e7          	jalr	-940(ra) # 80000a10 <kfree>
    p->trapframe = 0;
    80001dc4:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001dc8:	68a8                	ld	a0,80(s1)
    80001dca:	c511                	beqz	a0,80001dd6 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001dcc:	64ac                	ld	a1,72(s1)
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	f8c080e7          	jalr	-116(ra) # 80001d5a <proc_freepagetable>
    p->pagetable = 0;
    80001dd6:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001dda:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001dde:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001de2:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001de6:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001dea:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001dee:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001df2:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001df6:	0004ac23          	sw	zero,24(s1)
}
    80001dfa:	60e2                	ld	ra,24(sp)
    80001dfc:	6442                	ld	s0,16(sp)
    80001dfe:	64a2                	ld	s1,8(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret

0000000080001e04 <allocproc>:
{
    80001e04:	1101                	addi	sp,sp,-32
    80001e06:	ec06                	sd	ra,24(sp)
    80001e08:	e822                	sd	s0,16(sp)
    80001e0a:	e426                	sd	s1,8(sp)
    80001e0c:	e04a                	sd	s2,0(sp)
    80001e0e:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e10:	00017497          	auipc	s1,0x17
    80001e14:	34048493          	addi	s1,s1,832 # 80019150 <proc>
    80001e18:	0001d917          	auipc	s2,0x1d
    80001e1c:	d3890913          	addi	s2,s2,-712 # 8001eb50 <tickslock>
        acquire(&p->lock);
    80001e20:	8526                	mv	a0,s1
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	ebc080e7          	jalr	-324(ra) # 80000cde <acquire>
        if (p->state == UNUSED)
    80001e2a:	4c9c                	lw	a5,24(s1)
    80001e2c:	cf81                	beqz	a5,80001e44 <allocproc+0x40>
            release(&p->lock);
    80001e2e:	8526                	mv	a0,s1
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	f62080e7          	jalr	-158(ra) # 80000d92 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e38:	16848493          	addi	s1,s1,360
    80001e3c:	ff2492e3          	bne	s1,s2,80001e20 <allocproc+0x1c>
    return 0;
    80001e40:	4481                	li	s1,0
    80001e42:	a889                	j	80001e94 <allocproc+0x90>
    p->pid = allocpid();
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	e34080e7          	jalr	-460(ra) # 80001c78 <allocpid>
    80001e4c:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e4e:	4785                	li	a5,1
    80001e50:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	d50080e7          	jalr	-688(ra) # 80000ba2 <kalloc>
    80001e5a:	892a                	mv	s2,a0
    80001e5c:	eca8                	sd	a0,88(s1)
    80001e5e:	c131                	beqz	a0,80001ea2 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001e60:	8526                	mv	a0,s1
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	e5c080e7          	jalr	-420(ra) # 80001cbe <proc_pagetable>
    80001e6a:	892a                	mv	s2,a0
    80001e6c:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e6e:	c531                	beqz	a0,80001eba <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e70:	07000613          	li	a2,112
    80001e74:	4581                	li	a1,0
    80001e76:	06048513          	addi	a0,s1,96
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f60080e7          	jalr	-160(ra) # 80000dda <memset>
    p->context.ra = (uint64)forkret;
    80001e82:	00000797          	auipc	a5,0x0
    80001e86:	db078793          	addi	a5,a5,-592 # 80001c32 <forkret>
    80001e8a:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e8c:	60bc                	ld	a5,64(s1)
    80001e8e:	6705                	lui	a4,0x1
    80001e90:	97ba                	add	a5,a5,a4
    80001e92:	f4bc                	sd	a5,104(s1)
}
    80001e94:	8526                	mv	a0,s1
    80001e96:	60e2                	ld	ra,24(sp)
    80001e98:	6442                	ld	s0,16(sp)
    80001e9a:	64a2                	ld	s1,8(sp)
    80001e9c:	6902                	ld	s2,0(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret
        freeproc(p);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	f08080e7          	jalr	-248(ra) # 80001dac <freeproc>
        release(&p->lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	ee4080e7          	jalr	-284(ra) # 80000d92 <release>
        return 0;
    80001eb6:	84ca                	mv	s1,s2
    80001eb8:	bff1                	j	80001e94 <allocproc+0x90>
        freeproc(p);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	ef0080e7          	jalr	-272(ra) # 80001dac <freeproc>
        release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	ecc080e7          	jalr	-308(ra) # 80000d92 <release>
        return 0;
    80001ece:	84ca                	mv	s1,s2
    80001ed0:	b7d1                	j	80001e94 <allocproc+0x90>

0000000080001ed2 <userinit>:
{
    80001ed2:	1101                	addi	sp,sp,-32
    80001ed4:	ec06                	sd	ra,24(sp)
    80001ed6:	e822                	sd	s0,16(sp)
    80001ed8:	e426                	sd	s1,8(sp)
    80001eda:	1000                	addi	s0,sp,32
    p = allocproc();
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	f28080e7          	jalr	-216(ra) # 80001e04 <allocproc>
    80001ee4:	84aa                	mv	s1,a0
    initproc = p;
    80001ee6:	00007797          	auipc	a5,0x7
    80001eea:	bca7b123          	sd	a0,-1086(a5) # 80008aa8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eee:	03400613          	li	a2,52
    80001ef2:	00007597          	auipc	a1,0x7
    80001ef6:	afe58593          	addi	a1,a1,-1282 # 800089f0 <initcode>
    80001efa:	6928                	ld	a0,80(a0)
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	56a080e7          	jalr	1386(ra) # 80001466 <uvmfirst>
    p->sz = PGSIZE;
    80001f04:	6785                	lui	a5,0x1
    80001f06:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f08:	6cb8                	ld	a4,88(s1)
    80001f0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f0e:	6cb8                	ld	a4,88(s1)
    80001f10:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f12:	4641                	li	a2,16
    80001f14:	00006597          	auipc	a1,0x6
    80001f18:	35c58593          	addi	a1,a1,860 # 80008270 <digits+0x220>
    80001f1c:	15848513          	addi	a0,s1,344
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	00c080e7          	jalr	12(ra) # 80000f2c <safestrcpy>
    p->cwd = namei("/");
    80001f28:	00006517          	auipc	a0,0x6
    80001f2c:	35850513          	addi	a0,a0,856 # 80008280 <digits+0x230>
    80001f30:	00002097          	auipc	ra,0x2
    80001f34:	4f0080e7          	jalr	1264(ra) # 80004420 <namei>
    80001f38:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f3c:	478d                	li	a5,3
    80001f3e:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	e50080e7          	jalr	-432(ra) # 80000d92 <release>
}
    80001f4a:	60e2                	ld	ra,24(sp)
    80001f4c:	6442                	ld	s0,16(sp)
    80001f4e:	64a2                	ld	s1,8(sp)
    80001f50:	6105                	addi	sp,sp,32
    80001f52:	8082                	ret

0000000080001f54 <growproc>:
{
    80001f54:	1101                	addi	sp,sp,-32
    80001f56:	ec06                	sd	ra,24(sp)
    80001f58:	e822                	sd	s0,16(sp)
    80001f5a:	e426                	sd	s1,8(sp)
    80001f5c:	e04a                	sd	s2,0(sp)
    80001f5e:	1000                	addi	s0,sp,32
    80001f60:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	c98080e7          	jalr	-872(ra) # 80001bfa <myproc>
    80001f6a:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f6c:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f6e:	01204c63          	bgtz	s2,80001f86 <growproc+0x32>
    else if (n < 0)
    80001f72:	02094663          	bltz	s2,80001f9e <growproc+0x4a>
    p->sz = sz;
    80001f76:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f78:	4501                	li	a0,0
}
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6902                	ld	s2,0(sp)
    80001f82:	6105                	addi	sp,sp,32
    80001f84:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f86:	4691                	li	a3,4
    80001f88:	00b90633          	add	a2,s2,a1
    80001f8c:	6928                	ld	a0,80(a0)
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	592080e7          	jalr	1426(ra) # 80001520 <uvmalloc>
    80001f96:	85aa                	mv	a1,a0
    80001f98:	fd79                	bnez	a0,80001f76 <growproc+0x22>
            return -1;
    80001f9a:	557d                	li	a0,-1
    80001f9c:	bff9                	j	80001f7a <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f9e:	00b90633          	add	a2,s2,a1
    80001fa2:	6928                	ld	a0,80(a0)
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	534080e7          	jalr	1332(ra) # 800014d8 <uvmdealloc>
    80001fac:	85aa                	mv	a1,a0
    80001fae:	b7e1                	j	80001f76 <growproc+0x22>

0000000080001fb0 <ps>:
{
    80001fb0:	715d                	addi	sp,sp,-80
    80001fb2:	e486                	sd	ra,72(sp)
    80001fb4:	e0a2                	sd	s0,64(sp)
    80001fb6:	fc26                	sd	s1,56(sp)
    80001fb8:	f84a                	sd	s2,48(sp)
    80001fba:	f44e                	sd	s3,40(sp)
    80001fbc:	f052                	sd	s4,32(sp)
    80001fbe:	ec56                	sd	s5,24(sp)
    80001fc0:	e85a                	sd	s6,16(sp)
    80001fc2:	e45e                	sd	s7,8(sp)
    80001fc4:	e062                	sd	s8,0(sp)
    80001fc6:	0880                	addi	s0,sp,80
    80001fc8:	84aa                	mv	s1,a0
    80001fca:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	c2e080e7          	jalr	-978(ra) # 80001bfa <myproc>
    if (count == 0)
    80001fd4:	120b8063          	beqz	s7,800020f4 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001fd8:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001fdc:	003b951b          	slliw	a0,s7,0x3
    80001fe0:	0175053b          	addw	a0,a0,s7
    80001fe4:	0025151b          	slliw	a0,a0,0x2
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	f6c080e7          	jalr	-148(ra) # 80001f54 <growproc>
    80001ff0:	10054463          	bltz	a0,800020f8 <ps+0x148>
    struct user_proc loc_result[count];
    80001ff4:	003b9a13          	slli	s4,s7,0x3
    80001ff8:	9a5e                	add	s4,s4,s7
    80001ffa:	0a0a                	slli	s4,s4,0x2
    80001ffc:	00fa0793          	addi	a5,s4,15
    80002000:	8391                	srli	a5,a5,0x4
    80002002:	0792                	slli	a5,a5,0x4
    80002004:	40f10133          	sub	sp,sp,a5
    80002008:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000200a:	007e9537          	lui	a0,0x7e9
    8000200e:	02a484b3          	mul	s1,s1,a0
    80002012:	00017797          	auipc	a5,0x17
    80002016:	13e78793          	addi	a5,a5,318 # 80019150 <proc>
    8000201a:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000201c:	0001d797          	auipc	a5,0x1d
    80002020:	b3478793          	addi	a5,a5,-1228 # 8001eb50 <tickslock>
    80002024:	0cf4fc63          	bgeu	s1,a5,800020fc <ps+0x14c>
    80002028:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000202c:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    8000202e:	8c3e                	mv	s8,a5
    80002030:	a051                	j	800020b4 <ps+0x104>
            loc_result[localCount].state = UNUSED;
    80002032:	00399793          	slli	a5,s3,0x3
    80002036:	97ce                	add	a5,a5,s3
    80002038:	078a                	slli	a5,a5,0x2
    8000203a:	97d6                	add	a5,a5,s5
    8000203c:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	d50080e7          	jalr	-688(ra) # 80000d92 <release>
    if (localCount < count)
    8000204a:	0179f963          	bgeu	s3,s7,8000205c <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    8000204e:	00399793          	slli	a5,s3,0x3
    80002052:	97ce                	add	a5,a5,s3
    80002054:	078a                	slli	a5,a5,0x2
    80002056:	97d6                	add	a5,a5,s5
    80002058:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000205c:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	b9c080e7          	jalr	-1124(ra) # 80001bfa <myproc>
    80002066:	86d2                	mv	a3,s4
    80002068:	8656                	mv	a2,s5
    8000206a:	85da                	mv	a1,s6
    8000206c:	6928                	ld	a0,80(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	74c080e7          	jalr	1868(ra) # 800017ba <copyout>
}
    80002076:	8526                	mv	a0,s1
    80002078:	fb040113          	addi	sp,s0,-80
    8000207c:	60a6                	ld	ra,72(sp)
    8000207e:	6406                	ld	s0,64(sp)
    80002080:	74e2                	ld	s1,56(sp)
    80002082:	7942                	ld	s2,48(sp)
    80002084:	79a2                	ld	s3,40(sp)
    80002086:	7a02                	ld	s4,32(sp)
    80002088:	6ae2                	ld	s5,24(sp)
    8000208a:	6b42                	ld	s6,16(sp)
    8000208c:	6ba2                	ld	s7,8(sp)
    8000208e:	6c02                	ld	s8,0(sp)
    80002090:	6161                	addi	sp,sp,80
    80002092:	8082                	ret
        release(&p->lock);
    80002094:	8526                	mv	a0,s1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	cfc080e7          	jalr	-772(ra) # 80000d92 <release>
        localCount++;
    8000209e:	2985                	addiw	s3,s3,1
    800020a0:	0ff9f993          	andi	s3,s3,255
    for (; p < &proc[NPROC]; p++)
    800020a4:	16848493          	addi	s1,s1,360
    800020a8:	fb84f1e3          	bgeu	s1,s8,8000204a <ps+0x9a>
        if (localCount == count)
    800020ac:	02490913          	addi	s2,s2,36
    800020b0:	fb3b86e3          	beq	s7,s3,8000205c <ps+0xac>
        acquire(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	c28080e7          	jalr	-984(ra) # 80000cde <acquire>
        if (p->state == UNUSED)
    800020be:	4c9c                	lw	a5,24(s1)
    800020c0:	dbad                	beqz	a5,80002032 <ps+0x82>
        loc_result[localCount].state = p->state;
    800020c2:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    800020c6:	549c                	lw	a5,40(s1)
    800020c8:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800020cc:	54dc                	lw	a5,44(s1)
    800020ce:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800020d2:	589c                	lw	a5,48(s1)
    800020d4:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800020d8:	4641                	li	a2,16
    800020da:	85ca                	mv	a1,s2
    800020dc:	15848513          	addi	a0,s1,344
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	ac0080e7          	jalr	-1344(ra) # 80001ba0 <copy_array>
        if (p->parent != 0) // init
    800020e8:	7c9c                	ld	a5,56(s1)
    800020ea:	d7cd                	beqz	a5,80002094 <ps+0xe4>
            loc_result[localCount].parent_id = p->parent->pid;
    800020ec:	5b9c                	lw	a5,48(a5)
    800020ee:	fef92e23          	sw	a5,-4(s2)
    800020f2:	b74d                	j	80002094 <ps+0xe4>
        return result;
    800020f4:	4481                	li	s1,0
    800020f6:	b741                	j	80002076 <ps+0xc6>
        return result;
    800020f8:	4481                	li	s1,0
    800020fa:	bfb5                	j	80002076 <ps+0xc6>
        return result;
    800020fc:	4481                	li	s1,0
    800020fe:	bfa5                	j	80002076 <ps+0xc6>

0000000080002100 <fork>:
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	e052                	sd	s4,0(sp)
    8000210e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	aea080e7          	jalr	-1302(ra) # 80001bfa <myproc>
    80002118:	892a                	mv	s2,a0
    if ((np = allocproc()) == 0)
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	cea080e7          	jalr	-790(ra) # 80001e04 <allocproc>
    80002122:	10050b63          	beqz	a0,80002238 <fork+0x138>
    80002126:	89aa                	mv	s3,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002128:	04893603          	ld	a2,72(s2)
    8000212c:	692c                	ld	a1,80(a0)
    8000212e:	05093503          	ld	a0,80(s2)
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	542080e7          	jalr	1346(ra) # 80001674 <uvmcopy>
    8000213a:	04054663          	bltz	a0,80002186 <fork+0x86>
    np->sz = p->sz;
    8000213e:	04893783          	ld	a5,72(s2)
    80002142:	04f9b423          	sd	a5,72(s3)
    *(np->trapframe) = *(p->trapframe);
    80002146:	05893683          	ld	a3,88(s2)
    8000214a:	87b6                	mv	a5,a3
    8000214c:	0589b703          	ld	a4,88(s3)
    80002150:	12068693          	addi	a3,a3,288
    80002154:	0007b803          	ld	a6,0(a5)
    80002158:	6788                	ld	a0,8(a5)
    8000215a:	6b8c                	ld	a1,16(a5)
    8000215c:	6f90                	ld	a2,24(a5)
    8000215e:	01073023          	sd	a6,0(a4)
    80002162:	e708                	sd	a0,8(a4)
    80002164:	eb0c                	sd	a1,16(a4)
    80002166:	ef10                	sd	a2,24(a4)
    80002168:	02078793          	addi	a5,a5,32
    8000216c:	02070713          	addi	a4,a4,32
    80002170:	fed792e3          	bne	a5,a3,80002154 <fork+0x54>
    np->trapframe->a0 = 0;
    80002174:	0589b783          	ld	a5,88(s3)
    80002178:	0607b823          	sd	zero,112(a5)
    8000217c:	0d000493          	li	s1,208
    for (i = 0; i < NOFILE; i++)
    80002180:	15000a13          	li	s4,336
    80002184:	a03d                	j	800021b2 <fork+0xb2>
        freeproc(np);
    80002186:	854e                	mv	a0,s3
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	c24080e7          	jalr	-988(ra) # 80001dac <freeproc>
        release(&np->lock);
    80002190:	854e                	mv	a0,s3
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	c00080e7          	jalr	-1024(ra) # 80000d92 <release>
        return -1;
    8000219a:	5a7d                	li	s4,-1
    8000219c:	a069                	j	80002226 <fork+0x126>
            np->ofile[i] = filedup(p->ofile[i]);
    8000219e:	00003097          	auipc	ra,0x3
    800021a2:	918080e7          	jalr	-1768(ra) # 80004ab6 <filedup>
    800021a6:	009987b3          	add	a5,s3,s1
    800021aa:	e388                	sd	a0,0(a5)
    for (i = 0; i < NOFILE; i++)
    800021ac:	04a1                	addi	s1,s1,8
    800021ae:	01448763          	beq	s1,s4,800021bc <fork+0xbc>
        if (p->ofile[i])
    800021b2:	009907b3          	add	a5,s2,s1
    800021b6:	6388                	ld	a0,0(a5)
    800021b8:	f17d                	bnez	a0,8000219e <fork+0x9e>
    800021ba:	bfcd                	j	800021ac <fork+0xac>
    np->cwd = idup(p->cwd);
    800021bc:	15093503          	ld	a0,336(s2)
    800021c0:	00002097          	auipc	ra,0x2
    800021c4:	a7c080e7          	jalr	-1412(ra) # 80003c3c <idup>
    800021c8:	14a9b823          	sd	a0,336(s3)
    safestrcpy(np->name, p->name, sizeof(p->name));
    800021cc:	4641                	li	a2,16
    800021ce:	15890593          	addi	a1,s2,344
    800021d2:	15898513          	addi	a0,s3,344
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	d56080e7          	jalr	-682(ra) # 80000f2c <safestrcpy>
    pid = np->pid;
    800021de:	0309aa03          	lw	s4,48(s3)
    release(&np->lock);
    800021e2:	854e                	mv	a0,s3
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	bae080e7          	jalr	-1106(ra) # 80000d92 <release>
    acquire(&wait_lock);
    800021ec:	00017497          	auipc	s1,0x17
    800021f0:	f4c48493          	addi	s1,s1,-180 # 80019138 <wait_lock>
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	ae8080e7          	jalr	-1304(ra) # 80000cde <acquire>
    np->parent = p;
    800021fe:	0329bc23          	sd	s2,56(s3)
    release(&wait_lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	b8e080e7          	jalr	-1138(ra) # 80000d92 <release>
    acquire(&np->lock);
    8000220c:	854e                	mv	a0,s3
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	ad0080e7          	jalr	-1328(ra) # 80000cde <acquire>
    np->state = RUNNABLE;
    80002216:	478d                	li	a5,3
    80002218:	00f9ac23          	sw	a5,24(s3)
    release(&np->lock);
    8000221c:	854e                	mv	a0,s3
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	b74080e7          	jalr	-1164(ra) # 80000d92 <release>
}
    80002226:	8552                	mv	a0,s4
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6a02                	ld	s4,0(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret
        return -1;
    80002238:	5a7d                	li	s4,-1
    8000223a:	b7f5                	j	80002226 <fork+0x126>

000000008000223c <scheduler>:
{
    8000223c:	1101                	addi	sp,sp,-32
    8000223e:	ec06                	sd	ra,24(sp)
    80002240:	e822                	sd	s0,16(sp)
    80002242:	e426                	sd	s1,8(sp)
    80002244:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    80002246:	00006497          	auipc	s1,0x6
    8000224a:	79248493          	addi	s1,s1,1938 # 800089d8 <sched_pointer>
    8000224e:	609c                	ld	a5,0(s1)
    80002250:	9782                	jalr	a5
    while (1)
    80002252:	bff5                	j	8000224e <scheduler+0x12>

0000000080002254 <sched>:
{
    80002254:	7179                	addi	sp,sp,-48
    80002256:	f406                	sd	ra,40(sp)
    80002258:	f022                	sd	s0,32(sp)
    8000225a:	ec26                	sd	s1,24(sp)
    8000225c:	e84a                	sd	s2,16(sp)
    8000225e:	e44e                	sd	s3,8(sp)
    80002260:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	998080e7          	jalr	-1640(ra) # 80001bfa <myproc>
    8000226a:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	9f8080e7          	jalr	-1544(ra) # 80000c64 <holding>
    80002274:	c53d                	beqz	a0,800022e2 <sched+0x8e>
    80002276:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002278:	2781                	sext.w	a5,a5
    8000227a:	079e                	slli	a5,a5,0x7
    8000227c:	00017717          	auipc	a4,0x17
    80002280:	aa470713          	addi	a4,a4,-1372 # 80018d20 <cpus>
    80002284:	97ba                	add	a5,a5,a4
    80002286:	5fb8                	lw	a4,120(a5)
    80002288:	4785                	li	a5,1
    8000228a:	06f71463          	bne	a4,a5,800022f2 <sched+0x9e>
    if (p->state == RUNNING)
    8000228e:	4c98                	lw	a4,24(s1)
    80002290:	4791                	li	a5,4
    80002292:	06f70863          	beq	a4,a5,80002302 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002296:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000229a:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000229c:	ebbd                	bnez	a5,80002312 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229e:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800022a0:	00017917          	auipc	s2,0x17
    800022a4:	a8090913          	addi	s2,s2,-1408 # 80018d20 <cpus>
    800022a8:	2781                	sext.w	a5,a5
    800022aa:	079e                	slli	a5,a5,0x7
    800022ac:	97ca                	add	a5,a5,s2
    800022ae:	07c7a983          	lw	s3,124(a5)
    800022b2:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800022b4:	2581                	sext.w	a1,a1
    800022b6:	059e                	slli	a1,a1,0x7
    800022b8:	05a1                	addi	a1,a1,8
    800022ba:	95ca                	add	a1,a1,s2
    800022bc:	06048513          	addi	a0,s1,96
    800022c0:	00000097          	auipc	ra,0x0
    800022c4:	722080e7          	jalr	1826(ra) # 800029e2 <swtch>
    800022c8:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022ca:	2781                	sext.w	a5,a5
    800022cc:	079e                	slli	a5,a5,0x7
    800022ce:	993e                	add	s2,s2,a5
    800022d0:	07392e23          	sw	s3,124(s2)
}
    800022d4:	70a2                	ld	ra,40(sp)
    800022d6:	7402                	ld	s0,32(sp)
    800022d8:	64e2                	ld	s1,24(sp)
    800022da:	6942                	ld	s2,16(sp)
    800022dc:	69a2                	ld	s3,8(sp)
    800022de:	6145                	addi	sp,sp,48
    800022e0:	8082                	ret
        panic("sched p->lock");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	fa650513          	addi	a0,a0,-90 # 80008288 <digits+0x238>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	25a080e7          	jalr	602(ra) # 80000544 <panic>
        panic("sched locks");
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	fa650513          	addi	a0,a0,-90 # 80008298 <digits+0x248>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	24a080e7          	jalr	586(ra) # 80000544 <panic>
        panic("sched running");
    80002302:	00006517          	auipc	a0,0x6
    80002306:	fa650513          	addi	a0,a0,-90 # 800082a8 <digits+0x258>
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	23a080e7          	jalr	570(ra) # 80000544 <panic>
        panic("sched interruptible");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	fa650513          	addi	a0,a0,-90 # 800082b8 <digits+0x268>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	22a080e7          	jalr	554(ra) # 80000544 <panic>

0000000080002322 <yield>:
{
    80002322:	1101                	addi	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	8ce080e7          	jalr	-1842(ra) # 80001bfa <myproc>
    80002334:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9a8080e7          	jalr	-1624(ra) # 80000cde <acquire>
    p->state = RUNNABLE;
    8000233e:	478d                	li	a5,3
    80002340:	cc9c                	sw	a5,24(s1)
    sched();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	f12080e7          	jalr	-238(ra) # 80002254 <sched>
    release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	a46080e7          	jalr	-1466(ra) # 80000d92 <release>
}
    80002354:	60e2                	ld	ra,24(sp)
    80002356:	6442                	ld	s0,16(sp)
    80002358:	64a2                	ld	s1,8(sp)
    8000235a:	6105                	addi	sp,sp,32
    8000235c:	8082                	ret

000000008000235e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000235e:	7179                	addi	sp,sp,-48
    80002360:	f406                	sd	ra,40(sp)
    80002362:	f022                	sd	s0,32(sp)
    80002364:	ec26                	sd	s1,24(sp)
    80002366:	e84a                	sd	s2,16(sp)
    80002368:	e44e                	sd	s3,8(sp)
    8000236a:	1800                	addi	s0,sp,48
    8000236c:	89aa                	mv	s3,a0
    8000236e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	88a080e7          	jalr	-1910(ra) # 80001bfa <myproc>
    80002378:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	964080e7          	jalr	-1692(ra) # 80000cde <acquire>
    release(lk);
    80002382:	854a                	mv	a0,s2
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	a0e080e7          	jalr	-1522(ra) # 80000d92 <release>

    // Go to sleep.
    p->chan = chan;
    8000238c:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002390:	4789                	li	a5,2
    80002392:	cc9c                	sw	a5,24(s1)

    sched();
    80002394:	00000097          	auipc	ra,0x0
    80002398:	ec0080e7          	jalr	-320(ra) # 80002254 <sched>

    // Tidy up.
    p->chan = 0;
    8000239c:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	9f0080e7          	jalr	-1552(ra) # 80000d92 <release>
    acquire(lk);
    800023aa:	854a                	mv	a0,s2
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	932080e7          	jalr	-1742(ra) # 80000cde <acquire>
}
    800023b4:	70a2                	ld	ra,40(sp)
    800023b6:	7402                	ld	s0,32(sp)
    800023b8:	64e2                	ld	s1,24(sp)
    800023ba:	6942                	ld	s2,16(sp)
    800023bc:	69a2                	ld	s3,8(sp)
    800023be:	6145                	addi	sp,sp,48
    800023c0:	8082                	ret

00000000800023c2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	0080                	addi	s0,sp,64
    800023d4:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800023d6:	00017497          	auipc	s1,0x17
    800023da:	d7a48493          	addi	s1,s1,-646 # 80019150 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800023de:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023e0:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023e2:	0001c917          	auipc	s2,0x1c
    800023e6:	76e90913          	addi	s2,s2,1902 # 8001eb50 <tickslock>
    800023ea:	a821                	j	80002402 <wakeup+0x40>
                p->state = RUNNABLE;
    800023ec:	0154ac23          	sw	s5,24(s1)
            }
            release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	9a0080e7          	jalr	-1632(ra) # 80000d92 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023fa:	16848493          	addi	s1,s1,360
    800023fe:	03248463          	beq	s1,s2,80002426 <wakeup+0x64>
        if (p != myproc())
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	7f8080e7          	jalr	2040(ra) # 80001bfa <myproc>
    8000240a:	fea488e3          	beq	s1,a0,800023fa <wakeup+0x38>
            acquire(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	8ce080e7          	jalr	-1842(ra) # 80000cde <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	fd379be3          	bne	a5,s3,800023f0 <wakeup+0x2e>
    8000241e:	709c                	ld	a5,32(s1)
    80002420:	fd4798e3          	bne	a5,s4,800023f0 <wakeup+0x2e>
    80002424:	b7e1                	j	800023ec <wakeup+0x2a>
        }
    }
}
    80002426:	70e2                	ld	ra,56(sp)
    80002428:	7442                	ld	s0,48(sp)
    8000242a:	74a2                	ld	s1,40(sp)
    8000242c:	7902                	ld	s2,32(sp)
    8000242e:	69e2                	ld	s3,24(sp)
    80002430:	6a42                	ld	s4,16(sp)
    80002432:	6aa2                	ld	s5,8(sp)
    80002434:	6121                	addi	sp,sp,64
    80002436:	8082                	ret

0000000080002438 <reparent>:
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	e052                	sd	s4,0(sp)
    80002446:	1800                	addi	s0,sp,48
    80002448:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000244a:	00017497          	auipc	s1,0x17
    8000244e:	d0648493          	addi	s1,s1,-762 # 80019150 <proc>
            pp->parent = initproc;
    80002452:	00006a17          	auipc	s4,0x6
    80002456:	656a0a13          	addi	s4,s4,1622 # 80008aa8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000245a:	0001c997          	auipc	s3,0x1c
    8000245e:	6f698993          	addi	s3,s3,1782 # 8001eb50 <tickslock>
    80002462:	a029                	j	8000246c <reparent+0x34>
    80002464:	16848493          	addi	s1,s1,360
    80002468:	01348d63          	beq	s1,s3,80002482 <reparent+0x4a>
        if (pp->parent == p)
    8000246c:	7c9c                	ld	a5,56(s1)
    8000246e:	ff279be3          	bne	a5,s2,80002464 <reparent+0x2c>
            pp->parent = initproc;
    80002472:	000a3503          	ld	a0,0(s4)
    80002476:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	f4a080e7          	jalr	-182(ra) # 800023c2 <wakeup>
    80002480:	b7d5                	j	80002464 <reparent+0x2c>
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret

0000000080002492 <exit>:
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	756080e7          	jalr	1878(ra) # 80001bfa <myproc>
    800024ac:	89aa                	mv	s3,a0
    if (p == initproc)
    800024ae:	00006797          	auipc	a5,0x6
    800024b2:	5fa7b783          	ld	a5,1530(a5) # 80008aa8 <initproc>
    800024b6:	0d050493          	addi	s1,a0,208
    800024ba:	15050913          	addi	s2,a0,336
    800024be:	02a79363          	bne	a5,a0,800024e4 <exit+0x52>
        panic("init exiting");
    800024c2:	00006517          	auipc	a0,0x6
    800024c6:	e0e50513          	addi	a0,a0,-498 # 800082d0 <digits+0x280>
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	07a080e7          	jalr	122(ra) # 80000544 <panic>
            fileclose(f);
    800024d2:	00002097          	auipc	ra,0x2
    800024d6:	636080e7          	jalr	1590(ra) # 80004b08 <fileclose>
            p->ofile[fd] = 0;
    800024da:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800024de:	04a1                	addi	s1,s1,8
    800024e0:	01248563          	beq	s1,s2,800024ea <exit+0x58>
        if (p->ofile[fd])
    800024e4:	6088                	ld	a0,0(s1)
    800024e6:	f575                	bnez	a0,800024d2 <exit+0x40>
    800024e8:	bfdd                	j	800024de <exit+0x4c>
    begin_op();
    800024ea:	00002097          	auipc	ra,0x2
    800024ee:	152080e7          	jalr	338(ra) # 8000463c <begin_op>
    iput(p->cwd);
    800024f2:	1509b503          	ld	a0,336(s3)
    800024f6:	00002097          	auipc	ra,0x2
    800024fa:	93e080e7          	jalr	-1730(ra) # 80003e34 <iput>
    end_op();
    800024fe:	00002097          	auipc	ra,0x2
    80002502:	1be080e7          	jalr	446(ra) # 800046bc <end_op>
    p->cwd = 0;
    80002506:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000250a:	00017497          	auipc	s1,0x17
    8000250e:	c2e48493          	addi	s1,s1,-978 # 80019138 <wait_lock>
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	7ca080e7          	jalr	1994(ra) # 80000cde <acquire>
    reparent(p);
    8000251c:	854e                	mv	a0,s3
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	f1a080e7          	jalr	-230(ra) # 80002438 <reparent>
    wakeup(p->parent);
    80002526:	0389b503          	ld	a0,56(s3)
    8000252a:	00000097          	auipc	ra,0x0
    8000252e:	e98080e7          	jalr	-360(ra) # 800023c2 <wakeup>
    acquire(&p->lock);
    80002532:	854e                	mv	a0,s3
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	7aa080e7          	jalr	1962(ra) # 80000cde <acquire>
    p->xstate = status;
    8000253c:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002540:	4795                	li	a5,5
    80002542:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002546:	8526                	mv	a0,s1
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	84a080e7          	jalr	-1974(ra) # 80000d92 <release>
    sched();
    80002550:	00000097          	auipc	ra,0x0
    80002554:	d04080e7          	jalr	-764(ra) # 80002254 <sched>
    panic("zombie exit");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	d8850513          	addi	a0,a0,-632 # 800082e0 <digits+0x290>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	fe4080e7          	jalr	-28(ra) # 80000544 <panic>

0000000080002568 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	1800                	addi	s0,sp,48
    80002576:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002578:	00017497          	auipc	s1,0x17
    8000257c:	bd848493          	addi	s1,s1,-1064 # 80019150 <proc>
    80002580:	0001c997          	auipc	s3,0x1c
    80002584:	5d098993          	addi	s3,s3,1488 # 8001eb50 <tickslock>
    {
        acquire(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	754080e7          	jalr	1876(ra) # 80000cde <acquire>
        if (p->pid == pid)
    80002592:	589c                	lw	a5,48(s1)
    80002594:	01278d63          	beq	a5,s2,800025ae <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	7f8080e7          	jalr	2040(ra) # 80000d92 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800025a2:	16848493          	addi	s1,s1,360
    800025a6:	ff3491e3          	bne	s1,s3,80002588 <kill+0x20>
    }
    return -1;
    800025aa:	557d                	li	a0,-1
    800025ac:	a829                	j	800025c6 <kill+0x5e>
            p->killed = 1;
    800025ae:	4785                	li	a5,1
    800025b0:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800025b2:	4c98                	lw	a4,24(s1)
    800025b4:	4789                	li	a5,2
    800025b6:	00f70f63          	beq	a4,a5,800025d4 <kill+0x6c>
            release(&p->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	7d6080e7          	jalr	2006(ra) # 80000d92 <release>
            return 0;
    800025c4:	4501                	li	a0,0
}
    800025c6:	70a2                	ld	ra,40(sp)
    800025c8:	7402                	ld	s0,32(sp)
    800025ca:	64e2                	ld	s1,24(sp)
    800025cc:	6942                	ld	s2,16(sp)
    800025ce:	69a2                	ld	s3,8(sp)
    800025d0:	6145                	addi	sp,sp,48
    800025d2:	8082                	ret
                p->state = RUNNABLE;
    800025d4:	478d                	li	a5,3
    800025d6:	cc9c                	sw	a5,24(s1)
    800025d8:	b7cd                	j	800025ba <kill+0x52>

00000000800025da <setkilled>:

void setkilled(struct proc *p)
{
    800025da:	1101                	addi	sp,sp,-32
    800025dc:	ec06                	sd	ra,24(sp)
    800025de:	e822                	sd	s0,16(sp)
    800025e0:	e426                	sd	s1,8(sp)
    800025e2:	1000                	addi	s0,sp,32
    800025e4:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6f8080e7          	jalr	1784(ra) # 80000cde <acquire>
    p->killed = 1;
    800025ee:	4785                	li	a5,1
    800025f0:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	79e080e7          	jalr	1950(ra) # 80000d92 <release>
}
    800025fc:	60e2                	ld	ra,24(sp)
    800025fe:	6442                	ld	s0,16(sp)
    80002600:	64a2                	ld	s1,8(sp)
    80002602:	6105                	addi	sp,sp,32
    80002604:	8082                	ret

0000000080002606 <killed>:

int killed(struct proc *p)
{
    80002606:	1101                	addi	sp,sp,-32
    80002608:	ec06                	sd	ra,24(sp)
    8000260a:	e822                	sd	s0,16(sp)
    8000260c:	e426                	sd	s1,8(sp)
    8000260e:	e04a                	sd	s2,0(sp)
    80002610:	1000                	addi	s0,sp,32
    80002612:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	6ca080e7          	jalr	1738(ra) # 80000cde <acquire>
    k = p->killed;
    8000261c:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	770080e7          	jalr	1904(ra) # 80000d92 <release>
    return k;
}
    8000262a:	854a                	mv	a0,s2
    8000262c:	60e2                	ld	ra,24(sp)
    8000262e:	6442                	ld	s0,16(sp)
    80002630:	64a2                	ld	s1,8(sp)
    80002632:	6902                	ld	s2,0(sp)
    80002634:	6105                	addi	sp,sp,32
    80002636:	8082                	ret

0000000080002638 <wait>:
{
    80002638:	715d                	addi	sp,sp,-80
    8000263a:	e486                	sd	ra,72(sp)
    8000263c:	e0a2                	sd	s0,64(sp)
    8000263e:	fc26                	sd	s1,56(sp)
    80002640:	f84a                	sd	s2,48(sp)
    80002642:	f44e                	sd	s3,40(sp)
    80002644:	f052                	sd	s4,32(sp)
    80002646:	ec56                	sd	s5,24(sp)
    80002648:	e85a                	sd	s6,16(sp)
    8000264a:	e45e                	sd	s7,8(sp)
    8000264c:	e062                	sd	s8,0(sp)
    8000264e:	0880                	addi	s0,sp,80
    80002650:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	5a8080e7          	jalr	1448(ra) # 80001bfa <myproc>
    8000265a:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000265c:	00017517          	auipc	a0,0x17
    80002660:	adc50513          	addi	a0,a0,-1316 # 80019138 <wait_lock>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	67a080e7          	jalr	1658(ra) # 80000cde <acquire>
        havekids = 0;
    8000266c:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000266e:	4a15                	li	s4,5
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002670:	0001c997          	auipc	s3,0x1c
    80002674:	4e098993          	addi	s3,s3,1248 # 8001eb50 <tickslock>
                havekids = 1;
    80002678:	4a85                	li	s5,1
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000267a:	00017c17          	auipc	s8,0x17
    8000267e:	abec0c13          	addi	s8,s8,-1346 # 80019138 <wait_lock>
        havekids = 0;
    80002682:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002684:	00017497          	auipc	s1,0x17
    80002688:	acc48493          	addi	s1,s1,-1332 # 80019150 <proc>
    8000268c:	a0bd                	j	800026fa <wait+0xc2>
                    pid = pp->pid;
    8000268e:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002692:	000b0e63          	beqz	s6,800026ae <wait+0x76>
    80002696:	4691                	li	a3,4
    80002698:	02c48613          	addi	a2,s1,44
    8000269c:	85da                	mv	a1,s6
    8000269e:	05093503          	ld	a0,80(s2)
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	118080e7          	jalr	280(ra) # 800017ba <copyout>
    800026aa:	02054563          	bltz	a0,800026d4 <wait+0x9c>
                    freeproc(pp);
    800026ae:	8526                	mv	a0,s1
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	6fc080e7          	jalr	1788(ra) # 80001dac <freeproc>
                    release(&pp->lock);
    800026b8:	8526                	mv	a0,s1
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	6d8080e7          	jalr	1752(ra) # 80000d92 <release>
                    release(&wait_lock);
    800026c2:	00017517          	auipc	a0,0x17
    800026c6:	a7650513          	addi	a0,a0,-1418 # 80019138 <wait_lock>
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	6c8080e7          	jalr	1736(ra) # 80000d92 <release>
                    return pid;
    800026d2:	a0b5                	j	8000273e <wait+0x106>
                        release(&pp->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	6bc080e7          	jalr	1724(ra) # 80000d92 <release>
                        release(&wait_lock);
    800026de:	00017517          	auipc	a0,0x17
    800026e2:	a5a50513          	addi	a0,a0,-1446 # 80019138 <wait_lock>
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	6ac080e7          	jalr	1708(ra) # 80000d92 <release>
                        return -1;
    800026ee:	59fd                	li	s3,-1
    800026f0:	a0b9                	j	8000273e <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f2:	16848493          	addi	s1,s1,360
    800026f6:	03348463          	beq	s1,s3,8000271e <wait+0xe6>
            if (pp->parent == p)
    800026fa:	7c9c                	ld	a5,56(s1)
    800026fc:	ff279be3          	bne	a5,s2,800026f2 <wait+0xba>
                acquire(&pp->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	5dc080e7          	jalr	1500(ra) # 80000cde <acquire>
                if (pp->state == ZOMBIE)
    8000270a:	4c9c                	lw	a5,24(s1)
    8000270c:	f94781e3          	beq	a5,s4,8000268e <wait+0x56>
                release(&pp->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	680080e7          	jalr	1664(ra) # 80000d92 <release>
                havekids = 1;
    8000271a:	8756                	mv	a4,s5
    8000271c:	bfd9                	j	800026f2 <wait+0xba>
        if (!havekids || killed(p))
    8000271e:	c719                	beqz	a4,8000272c <wait+0xf4>
    80002720:	854a                	mv	a0,s2
    80002722:	00000097          	auipc	ra,0x0
    80002726:	ee4080e7          	jalr	-284(ra) # 80002606 <killed>
    8000272a:	c51d                	beqz	a0,80002758 <wait+0x120>
            release(&wait_lock);
    8000272c:	00017517          	auipc	a0,0x17
    80002730:	a0c50513          	addi	a0,a0,-1524 # 80019138 <wait_lock>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	65e080e7          	jalr	1630(ra) # 80000d92 <release>
            return -1;
    8000273c:	59fd                	li	s3,-1
}
    8000273e:	854e                	mv	a0,s3
    80002740:	60a6                	ld	ra,72(sp)
    80002742:	6406                	ld	s0,64(sp)
    80002744:	74e2                	ld	s1,56(sp)
    80002746:	7942                	ld	s2,48(sp)
    80002748:	79a2                	ld	s3,40(sp)
    8000274a:	7a02                	ld	s4,32(sp)
    8000274c:	6ae2                	ld	s5,24(sp)
    8000274e:	6b42                	ld	s6,16(sp)
    80002750:	6ba2                	ld	s7,8(sp)
    80002752:	6c02                	ld	s8,0(sp)
    80002754:	6161                	addi	sp,sp,80
    80002756:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002758:	85e2                	mv	a1,s8
    8000275a:	854a                	mv	a0,s2
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	c02080e7          	jalr	-1022(ra) # 8000235e <sleep>
        havekids = 0;
    80002764:	bf39                	j	80002682 <wait+0x4a>

0000000080002766 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002766:	7179                	addi	sp,sp,-48
    80002768:	f406                	sd	ra,40(sp)
    8000276a:	f022                	sd	s0,32(sp)
    8000276c:	ec26                	sd	s1,24(sp)
    8000276e:	e84a                	sd	s2,16(sp)
    80002770:	e44e                	sd	s3,8(sp)
    80002772:	e052                	sd	s4,0(sp)
    80002774:	1800                	addi	s0,sp,48
    80002776:	84aa                	mv	s1,a0
    80002778:	892e                	mv	s2,a1
    8000277a:	89b2                	mv	s3,a2
    8000277c:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	47c080e7          	jalr	1148(ra) # 80001bfa <myproc>
    if (user_dst)
    80002786:	c08d                	beqz	s1,800027a8 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002788:	86d2                	mv	a3,s4
    8000278a:	864e                	mv	a2,s3
    8000278c:	85ca                	mv	a1,s2
    8000278e:	6928                	ld	a0,80(a0)
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	02a080e7          	jalr	42(ra) # 800017ba <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6a02                	ld	s4,0(sp)
    800027a4:	6145                	addi	sp,sp,48
    800027a6:	8082                	ret
        memmove((char *)dst, src, len);
    800027a8:	000a061b          	sext.w	a2,s4
    800027ac:	85ce                	mv	a1,s3
    800027ae:	854a                	mv	a0,s2
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	68a080e7          	jalr	1674(ra) # 80000e3a <memmove>
        return 0;
    800027b8:	8526                	mv	a0,s1
    800027ba:	bff9                	j	80002798 <either_copyout+0x32>

00000000800027bc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027bc:	7179                	addi	sp,sp,-48
    800027be:	f406                	sd	ra,40(sp)
    800027c0:	f022                	sd	s0,32(sp)
    800027c2:	ec26                	sd	s1,24(sp)
    800027c4:	e84a                	sd	s2,16(sp)
    800027c6:	e44e                	sd	s3,8(sp)
    800027c8:	e052                	sd	s4,0(sp)
    800027ca:	1800                	addi	s0,sp,48
    800027cc:	892a                	mv	s2,a0
    800027ce:	84ae                	mv	s1,a1
    800027d0:	89b2                	mv	s3,a2
    800027d2:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	426080e7          	jalr	1062(ra) # 80001bfa <myproc>
    if (user_src)
    800027dc:	c08d                	beqz	s1,800027fe <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027de:	86d2                	mv	a3,s4
    800027e0:	864e                	mv	a2,s3
    800027e2:	85ca                	mv	a1,s2
    800027e4:	6928                	ld	a0,80(a0)
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	060080e7          	jalr	96(ra) # 80001846 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027ee:	70a2                	ld	ra,40(sp)
    800027f0:	7402                	ld	s0,32(sp)
    800027f2:	64e2                	ld	s1,24(sp)
    800027f4:	6942                	ld	s2,16(sp)
    800027f6:	69a2                	ld	s3,8(sp)
    800027f8:	6a02                	ld	s4,0(sp)
    800027fa:	6145                	addi	sp,sp,48
    800027fc:	8082                	ret
        memmove(dst, (char *)src, len);
    800027fe:	000a061b          	sext.w	a2,s4
    80002802:	85ce                	mv	a1,s3
    80002804:	854a                	mv	a0,s2
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	634080e7          	jalr	1588(ra) # 80000e3a <memmove>
        return 0;
    8000280e:	8526                	mv	a0,s1
    80002810:	bff9                	j	800027ee <either_copyin+0x32>

0000000080002812 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002812:	715d                	addi	sp,sp,-80
    80002814:	e486                	sd	ra,72(sp)
    80002816:	e0a2                	sd	s0,64(sp)
    80002818:	fc26                	sd	s1,56(sp)
    8000281a:	f84a                	sd	s2,48(sp)
    8000281c:	f44e                	sd	s3,40(sp)
    8000281e:	f052                	sd	s4,32(sp)
    80002820:	ec56                	sd	s5,24(sp)
    80002822:	e85a                	sd	s6,16(sp)
    80002824:	e45e                	sd	s7,8(sp)
    80002826:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	86050513          	addi	a0,a0,-1952 # 80008088 <digits+0x38>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d70080e7          	jalr	-656(ra) # 800005a0 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002838:	00017497          	auipc	s1,0x17
    8000283c:	a7048493          	addi	s1,s1,-1424 # 800192a8 <proc+0x158>
    80002840:	0001c917          	auipc	s2,0x1c
    80002844:	46890913          	addi	s2,s2,1128 # 8001eca8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002848:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000284a:	00006997          	auipc	s3,0x6
    8000284e:	aa698993          	addi	s3,s3,-1370 # 800082f0 <digits+0x2a0>
        printf("%d <%s %s", p->pid, state, p->name);
    80002852:	00006a97          	auipc	s5,0x6
    80002856:	aa6a8a93          	addi	s5,s5,-1370 # 800082f8 <digits+0x2a8>
        printf("\n");
    8000285a:	00006a17          	auipc	s4,0x6
    8000285e:	82ea0a13          	addi	s4,s4,-2002 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002862:	00006b97          	auipc	s7,0x6
    80002866:	ba6b8b93          	addi	s7,s7,-1114 # 80008408 <states.1774>
    8000286a:	a00d                	j	8000288c <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000286c:	ed86a583          	lw	a1,-296(a3)
    80002870:	8556                	mv	a0,s5
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d2e080e7          	jalr	-722(ra) # 800005a0 <printf>
        printf("\n");
    8000287a:	8552                	mv	a0,s4
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	d24080e7          	jalr	-732(ra) # 800005a0 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002884:	16848493          	addi	s1,s1,360
    80002888:	03248163          	beq	s1,s2,800028aa <procdump+0x98>
        if (p->state == UNUSED)
    8000288c:	86a6                	mv	a3,s1
    8000288e:	ec04a783          	lw	a5,-320(s1)
    80002892:	dbed                	beqz	a5,80002884 <procdump+0x72>
            state = "???";
    80002894:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002896:	fcfb6be3          	bltu	s6,a5,8000286c <procdump+0x5a>
    8000289a:	1782                	slli	a5,a5,0x20
    8000289c:	9381                	srli	a5,a5,0x20
    8000289e:	078e                	slli	a5,a5,0x3
    800028a0:	97de                	add	a5,a5,s7
    800028a2:	6390                	ld	a2,0(a5)
    800028a4:	f661                	bnez	a2,8000286c <procdump+0x5a>
            state = "???";
    800028a6:	864e                	mv	a2,s3
    800028a8:	b7d1                	j	8000286c <procdump+0x5a>
    }
}
    800028aa:	60a6                	ld	ra,72(sp)
    800028ac:	6406                	ld	s0,64(sp)
    800028ae:	74e2                	ld	s1,56(sp)
    800028b0:	7942                	ld	s2,48(sp)
    800028b2:	79a2                	ld	s3,40(sp)
    800028b4:	7a02                	ld	s4,32(sp)
    800028b6:	6ae2                	ld	s5,24(sp)
    800028b8:	6b42                	ld	s6,16(sp)
    800028ba:	6ba2                	ld	s7,8(sp)
    800028bc:	6161                	addi	sp,sp,80
    800028be:	8082                	ret

00000000800028c0 <schedls>:

void schedls()
{
    800028c0:	1141                	addi	sp,sp,-16
    800028c2:	e406                	sd	ra,8(sp)
    800028c4:	e022                	sd	s0,0(sp)
    800028c6:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	a4050513          	addi	a0,a0,-1472 # 80008308 <digits+0x2b8>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cd0080e7          	jalr	-816(ra) # 800005a0 <printf>
    printf("====================================\n");
    800028d8:	00006517          	auipc	a0,0x6
    800028dc:	a5850513          	addi	a0,a0,-1448 # 80008330 <digits+0x2e0>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	cc0080e7          	jalr	-832(ra) # 800005a0 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800028e8:	00006717          	auipc	a4,0x6
    800028ec:	15073703          	ld	a4,336(a4) # 80008a38 <available_schedulers+0x10>
    800028f0:	00006797          	auipc	a5,0x6
    800028f4:	0e87b783          	ld	a5,232(a5) # 800089d8 <sched_pointer>
    800028f8:	04f70663          	beq	a4,a5,80002944 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a6450513          	addi	a0,a0,-1436 # 80008360 <digits+0x310>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c9c080e7          	jalr	-868(ra) # 800005a0 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    8000290c:	00006617          	auipc	a2,0x6
    80002910:	13462603          	lw	a2,308(a2) # 80008a40 <available_schedulers+0x18>
    80002914:	00006597          	auipc	a1,0x6
    80002918:	11458593          	addi	a1,a1,276 # 80008a28 <available_schedulers>
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a4c50513          	addi	a0,a0,-1460 # 80008368 <digits+0x318>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c7c080e7          	jalr	-900(ra) # 800005a0 <printf>
    }
    printf("\n*: current scheduler\n\n");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a4450513          	addi	a0,a0,-1468 # 80008370 <digits+0x320>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c6c080e7          	jalr	-916(ra) # 800005a0 <printf>
}
    8000293c:	60a2                	ld	ra,8(sp)
    8000293e:	6402                	ld	s0,0(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret
            printf("[*]\t");
    80002944:	00006517          	auipc	a0,0x6
    80002948:	a1450513          	addi	a0,a0,-1516 # 80008358 <digits+0x308>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c54080e7          	jalr	-940(ra) # 800005a0 <printf>
    80002954:	bf65                	j	8000290c <schedls+0x4c>

0000000080002956 <schedset>:

void schedset(int id)
{
    80002956:	1141                	addi	sp,sp,-16
    80002958:	e406                	sd	ra,8(sp)
    8000295a:	e022                	sd	s0,0(sp)
    8000295c:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    8000295e:	e90d                	bnez	a0,80002990 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002960:	00006797          	auipc	a5,0x6
    80002964:	0d87b783          	ld	a5,216(a5) # 80008a38 <available_schedulers+0x10>
    80002968:	00006717          	auipc	a4,0x6
    8000296c:	06f73823          	sd	a5,112(a4) # 800089d8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002970:	00006597          	auipc	a1,0x6
    80002974:	0b858593          	addi	a1,a1,184 # 80008a28 <available_schedulers>
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a3850513          	addi	a0,a0,-1480 # 800083b0 <digits+0x360>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c20080e7          	jalr	-992(ra) # 800005a0 <printf>
}
    80002988:	60a2                	ld	ra,8(sp)
    8000298a:	6402                	ld	s0,0(sp)
    8000298c:	0141                	addi	sp,sp,16
    8000298e:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002990:	00006517          	auipc	a0,0x6
    80002994:	9f850513          	addi	a0,a0,-1544 # 80008388 <digits+0x338>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	c08080e7          	jalr	-1016(ra) # 800005a0 <printf>
        return;
    800029a0:	b7e5                	j	80002988 <schedset+0x32>

00000000800029a2 <va2pa>:

    struct proc *p;
    uint64 pte;
    for (p = proc; p < &proc[NPROC]; p++){

        if (p->pid == *pid){
    800029a2:	6194                	ld	a3,0(a1)
    for (p = proc; p < &proc[NPROC]; p++){
    800029a4:	00016797          	auipc	a5,0x16
    800029a8:	7ac78793          	addi	a5,a5,1964 # 80019150 <proc>
    800029ac:	0001c617          	auipc	a2,0x1c
    800029b0:	1a460613          	addi	a2,a2,420 # 8001eb50 <tickslock>
        if (p->pid == *pid){
    800029b4:	5b98                	lw	a4,48(a5)
    800029b6:	00d70863          	beq	a4,a3,800029c6 <va2pa+0x24>
    for (p = proc; p < &proc[NPROC]; p++){
    800029ba:	16878793          	addi	a5,a5,360
    800029be:	fec79be3          	bne	a5,a2,800029b4 <va2pa+0x12>

            return pte;
        }
        
    }
    return 0;
    800029c2:	4501                	li	a0,0
    800029c4:	8082                	ret
va2pa(uint64 *va, uint64 *pid){
    800029c6:	1141                	addi	sp,sp,-16
    800029c8:	e406                	sd	ra,8(sp)
    800029ca:	e022                	sd	s0,0(sp)
    800029cc:	0800                	addi	s0,sp,16
            pte = walkaddr(p->pagetable, *va);
    800029ce:	610c                	ld	a1,0(a0)
    800029d0:	6ba8                	ld	a0,80(a5)
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	79a080e7          	jalr	1946(ra) # 8000116c <walkaddr>
    800029da:	60a2                	ld	ra,8(sp)
    800029dc:	6402                	ld	s0,0(sp)
    800029de:	0141                	addi	sp,sp,16
    800029e0:	8082                	ret

00000000800029e2 <swtch>:
    800029e2:	00153023          	sd	ra,0(a0)
    800029e6:	00253423          	sd	sp,8(a0)
    800029ea:	e900                	sd	s0,16(a0)
    800029ec:	ed04                	sd	s1,24(a0)
    800029ee:	03253023          	sd	s2,32(a0)
    800029f2:	03353423          	sd	s3,40(a0)
    800029f6:	03453823          	sd	s4,48(a0)
    800029fa:	03553c23          	sd	s5,56(a0)
    800029fe:	05653023          	sd	s6,64(a0)
    80002a02:	05753423          	sd	s7,72(a0)
    80002a06:	05853823          	sd	s8,80(a0)
    80002a0a:	05953c23          	sd	s9,88(a0)
    80002a0e:	07a53023          	sd	s10,96(a0)
    80002a12:	07b53423          	sd	s11,104(a0)
    80002a16:	0005b083          	ld	ra,0(a1)
    80002a1a:	0085b103          	ld	sp,8(a1)
    80002a1e:	6980                	ld	s0,16(a1)
    80002a20:	6d84                	ld	s1,24(a1)
    80002a22:	0205b903          	ld	s2,32(a1)
    80002a26:	0285b983          	ld	s3,40(a1)
    80002a2a:	0305ba03          	ld	s4,48(a1)
    80002a2e:	0385ba83          	ld	s5,56(a1)
    80002a32:	0405bb03          	ld	s6,64(a1)
    80002a36:	0485bb83          	ld	s7,72(a1)
    80002a3a:	0505bc03          	ld	s8,80(a1)
    80002a3e:	0585bc83          	ld	s9,88(a1)
    80002a42:	0605bd03          	ld	s10,96(a1)
    80002a46:	0685bd83          	ld	s11,104(a1)
    80002a4a:	8082                	ret

0000000080002a4c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a4c:	1141                	addi	sp,sp,-16
    80002a4e:	e406                	sd	ra,8(sp)
    80002a50:	e022                	sd	s0,0(sp)
    80002a52:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a54:	00006597          	auipc	a1,0x6
    80002a58:	9e458593          	addi	a1,a1,-1564 # 80008438 <states.1774+0x30>
    80002a5c:	0001c517          	auipc	a0,0x1c
    80002a60:	0f450513          	addi	a0,a0,244 # 8001eb50 <tickslock>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	1ea080e7          	jalr	490(ra) # 80000c4e <initlock>
}
    80002a6c:	60a2                	ld	ra,8(sp)
    80002a6e:	6402                	ld	s0,0(sp)
    80002a70:	0141                	addi	sp,sp,16
    80002a72:	8082                	ret

0000000080002a74 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a74:	1141                	addi	sp,sp,-16
    80002a76:	e422                	sd	s0,8(sp)
    80002a78:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a7a:	00003797          	auipc	a5,0x3
    80002a7e:	6c678793          	addi	a5,a5,1734 # 80006140 <kernelvec>
    80002a82:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a86:	6422                	ld	s0,8(sp)
    80002a88:	0141                	addi	sp,sp,16
    80002a8a:	8082                	ret

0000000080002a8c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a8c:	1141                	addi	sp,sp,-16
    80002a8e:	e406                	sd	ra,8(sp)
    80002a90:	e022                	sd	s0,0(sp)
    80002a92:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	166080e7          	jalr	358(ra) # 80001bfa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002aa0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002aa6:	00004617          	auipc	a2,0x4
    80002aaa:	55a60613          	addi	a2,a2,1370 # 80007000 <_trampoline>
    80002aae:	00004697          	auipc	a3,0x4
    80002ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80002ab6:	8e91                	sub	a3,a3,a2
    80002ab8:	040007b7          	lui	a5,0x4000
    80002abc:	17fd                	addi	a5,a5,-1
    80002abe:	07b2                	slli	a5,a5,0xc
    80002ac0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ac2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ac6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ac8:	180026f3          	csrr	a3,satp
    80002acc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ace:	6d38                	ld	a4,88(a0)
    80002ad0:	6134                	ld	a3,64(a0)
    80002ad2:	6585                	lui	a1,0x1
    80002ad4:	96ae                	add	a3,a3,a1
    80002ad6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ad8:	6d38                	ld	a4,88(a0)
    80002ada:	00000697          	auipc	a3,0x0
    80002ade:	13068693          	addi	a3,a3,304 # 80002c0a <usertrap>
    80002ae2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ae4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ae6:	8692                	mv	a3,tp
    80002ae8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aea:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002aee:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002af2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002afa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002afc:	6f18                	ld	a4,24(a4)
    80002afe:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b02:	6928                	ld	a0,80(a0)
    80002b04:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b06:	00004717          	auipc	a4,0x4
    80002b0a:	59670713          	addi	a4,a4,1430 # 8000709c <userret>
    80002b0e:	8f11                	sub	a4,a4,a2
    80002b10:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b12:	577d                	li	a4,-1
    80002b14:	177e                	slli	a4,a4,0x3f
    80002b16:	8d59                	or	a0,a0,a4
    80002b18:	9782                	jalr	a5
}
    80002b1a:	60a2                	ld	ra,8(sp)
    80002b1c:	6402                	ld	s0,0(sp)
    80002b1e:	0141                	addi	sp,sp,16
    80002b20:	8082                	ret

0000000080002b22 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b22:	1101                	addi	sp,sp,-32
    80002b24:	ec06                	sd	ra,24(sp)
    80002b26:	e822                	sd	s0,16(sp)
    80002b28:	e426                	sd	s1,8(sp)
    80002b2a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b2c:	0001c497          	auipc	s1,0x1c
    80002b30:	02448493          	addi	s1,s1,36 # 8001eb50 <tickslock>
    80002b34:	8526                	mv	a0,s1
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	1a8080e7          	jalr	424(ra) # 80000cde <acquire>
  ticks++;
    80002b3e:	00006517          	auipc	a0,0x6
    80002b42:	f7250513          	addi	a0,a0,-142 # 80008ab0 <ticks>
    80002b46:	411c                	lw	a5,0(a0)
    80002b48:	2785                	addiw	a5,a5,1
    80002b4a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	876080e7          	jalr	-1930(ra) # 800023c2 <wakeup>
  release(&tickslock);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	23c080e7          	jalr	572(ra) # 80000d92 <release>
}
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	64a2                	ld	s1,8(sp)
    80002b64:	6105                	addi	sp,sp,32
    80002b66:	8082                	ret

0000000080002b68 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b68:	1101                	addi	sp,sp,-32
    80002b6a:	ec06                	sd	ra,24(sp)
    80002b6c:	e822                	sd	s0,16(sp)
    80002b6e:	e426                	sd	s1,8(sp)
    80002b70:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b72:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b76:	00074d63          	bltz	a4,80002b90 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b7a:	57fd                	li	a5,-1
    80002b7c:	17fe                	slli	a5,a5,0x3f
    80002b7e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b80:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b82:	06f70363          	beq	a4,a5,80002be8 <devintr+0x80>
  }
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret
     (scause & 0xff) == 9){
    80002b90:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b94:	46a5                	li	a3,9
    80002b96:	fed792e3          	bne	a5,a3,80002b7a <devintr+0x12>
    int irq = plic_claim();
    80002b9a:	00003097          	auipc	ra,0x3
    80002b9e:	6ae080e7          	jalr	1710(ra) # 80006248 <plic_claim>
    80002ba2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ba4:	47a9                	li	a5,10
    80002ba6:	02f50763          	beq	a0,a5,80002bd4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002baa:	4785                	li	a5,1
    80002bac:	02f50963          	beq	a0,a5,80002bde <devintr+0x76>
    return 1;
    80002bb0:	4505                	li	a0,1
    } else if(irq){
    80002bb2:	d8f1                	beqz	s1,80002b86 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bb4:	85a6                	mv	a1,s1
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	88a50513          	addi	a0,a0,-1910 # 80008440 <states.1774+0x38>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9e2080e7          	jalr	-1566(ra) # 800005a0 <printf>
      plic_complete(irq);
    80002bc6:	8526                	mv	a0,s1
    80002bc8:	00003097          	auipc	ra,0x3
    80002bcc:	6a4080e7          	jalr	1700(ra) # 8000626c <plic_complete>
    return 1;
    80002bd0:	4505                	li	a0,1
    80002bd2:	bf55                	j	80002b86 <devintr+0x1e>
      uartintr();
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	dec080e7          	jalr	-532(ra) # 800009c0 <uartintr>
    80002bdc:	b7ed                	j	80002bc6 <devintr+0x5e>
      virtio_disk_intr();
    80002bde:	00004097          	auipc	ra,0x4
    80002be2:	bb8080e7          	jalr	-1096(ra) # 80006796 <virtio_disk_intr>
    80002be6:	b7c5                	j	80002bc6 <devintr+0x5e>
    if(cpuid() == 0){
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	fe6080e7          	jalr	-26(ra) # 80001bce <cpuid>
    80002bf0:	c901                	beqz	a0,80002c00 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bf2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bf6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bf8:	14479073          	csrw	sip,a5
    return 2;
    80002bfc:	4509                	li	a0,2
    80002bfe:	b761                	j	80002b86 <devintr+0x1e>
      clockintr();
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	f22080e7          	jalr	-222(ra) # 80002b22 <clockintr>
    80002c08:	b7ed                	j	80002bf2 <devintr+0x8a>

0000000080002c0a <usertrap>:
{
    80002c0a:	7139                	addi	sp,sp,-64
    80002c0c:	fc06                	sd	ra,56(sp)
    80002c0e:	f822                	sd	s0,48(sp)
    80002c10:	f426                	sd	s1,40(sp)
    80002c12:	f04a                	sd	s2,32(sp)
    80002c14:	ec4e                	sd	s3,24(sp)
    80002c16:	e852                	sd	s4,16(sp)
    80002c18:	e456                	sd	s5,8(sp)
    80002c1a:	e05a                	sd	s6,0(sp)
    80002c1c:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c22:	1007f793          	andi	a5,a5,256
    80002c26:	efb5                	bnez	a5,80002ca2 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c28:	00003797          	auipc	a5,0x3
    80002c2c:	51878793          	addi	a5,a5,1304 # 80006140 <kernelvec>
    80002c30:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	fc6080e7          	jalr	-58(ra) # 80001bfa <myproc>
    80002c3c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c3e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c40:	14102773          	csrr	a4,sepc
    80002c44:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c46:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c4a:	47a1                	li	a5,8
    80002c4c:	06f70363          	beq	a4,a5,80002cb2 <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	f18080e7          	jalr	-232(ra) # 80002b68 <devintr>
    80002c58:	892a                	mv	s2,a0
    80002c5a:	1a051263          	bnez	a0,80002dfe <usertrap+0x1f4>
    80002c5e:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) {
    80002c62:	47bd                	li	a5,15
    80002c64:	0af70563          	beq	a4,a5,80002d0e <usertrap+0x104>
    80002c68:	142025f3          	csrr	a1,scause
  printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c6c:	5890                	lw	a2,48(s1)
    80002c6e:	00006517          	auipc	a0,0x6
    80002c72:	83a50513          	addi	a0,a0,-1990 # 800084a8 <states.1774+0xa0>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	92a080e7          	jalr	-1750(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c82:	14302673          	csrr	a2,stval
  printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c86:	00006517          	auipc	a0,0x6
    80002c8a:	85250513          	addi	a0,a0,-1966 # 800084d8 <states.1774+0xd0>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	912080e7          	jalr	-1774(ra) # 800005a0 <printf>
  setkilled(p);
    80002c96:	8526                	mv	a0,s1
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	942080e7          	jalr	-1726(ra) # 800025da <setkilled>
    80002ca0:	a825                	j	80002cd8 <usertrap+0xce>
    panic("usertrap: not from user mode");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	7be50513          	addi	a0,a0,1982 # 80008460 <states.1774+0x58>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	89a080e7          	jalr	-1894(ra) # 80000544 <panic>
    if(killed(p))
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	954080e7          	jalr	-1708(ra) # 80002606 <killed>
    80002cba:	e521                	bnez	a0,80002d02 <usertrap+0xf8>
    p->trapframe->epc += 4;
    80002cbc:	6cb8                	ld	a4,88(s1)
    80002cbe:	6f1c                	ld	a5,24(a4)
    80002cc0:	0791                	addi	a5,a5,4
    80002cc2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cc8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ccc:	10079073          	csrw	sstatus,a5
    syscall();
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	3a2080e7          	jalr	930(ra) # 80003072 <syscall>
  if(killed(p))
    80002cd8:	8526                	mv	a0,s1
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	92c080e7          	jalr	-1748(ra) # 80002606 <killed>
    80002ce2:	12051563          	bnez	a0,80002e0c <usertrap+0x202>
  usertrapret();
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	da6080e7          	jalr	-602(ra) # 80002a8c <usertrapret>
}
    80002cee:	70e2                	ld	ra,56(sp)
    80002cf0:	7442                	ld	s0,48(sp)
    80002cf2:	74a2                	ld	s1,40(sp)
    80002cf4:	7902                	ld	s2,32(sp)
    80002cf6:	69e2                	ld	s3,24(sp)
    80002cf8:	6a42                	ld	s4,16(sp)
    80002cfa:	6aa2                	ld	s5,8(sp)
    80002cfc:	6b02                	ld	s6,0(sp)
    80002cfe:	6121                	addi	sp,sp,64
    80002d00:	8082                	ret
      exit(-1);
    80002d02:	557d                	li	a0,-1
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	78e080e7          	jalr	1934(ra) # 80002492 <exit>
    80002d0c:	bf45                	j	80002cbc <usertrap+0xb2>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d0e:	14302a73          	csrr	s4,stval
    pagetable_t pagetable = p->pagetable;
    80002d12:	0504b983          	ld	s3,80(s1)
    pte_t *pte = walk(pagetable, va, 0);
    80002d16:	4601                	li	a2,0
    80002d18:	85d2                	mv	a1,s4
    80002d1a:	854e                	mv	a0,s3
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	3aa080e7          	jalr	938(ra) # 800010c6 <walk>
    80002d24:	892a                	mv	s2,a0
    *pte = (*pte >> 1) << 1;
    80002d26:	611c                	ld	a5,0(a0)
    80002d28:	9bf9                	andi	a5,a5,-2
    80002d2a:	e11c                	sd	a5,0(a0)
    uint64 pa = PTE2PA(*pte);
    80002d2c:	00a7da93          	srli	s5,a5,0xa
    if(references[ppn] > 1){
    80002d30:	0000e717          	auipc	a4,0xe
    80002d34:	ff070713          	addi	a4,a4,-16 # 80010d20 <references>
    80002d38:	9756                	add	a4,a4,s5
    80002d3a:	00074703          	lbu	a4,0(a4)
    80002d3e:	4685                	li	a3,1
    80002d40:	00e6ec63          	bltu	a3,a4,80002d58 <usertrap+0x14e>
      *pte = *pte | PTE_W;
    80002d44:	0047e793          	ori	a5,a5,4
    80002d48:	e11c                	sd	a5,0(a0)
    *pte = *pte | PTE_V;
    80002d4a:	00093783          	ld	a5,0(s2)
    80002d4e:	0017e793          	ori	a5,a5,1
    80002d52:	00f93023          	sd	a5,0(s2)
    80002d56:	b749                	j	80002cd8 <usertrap+0xce>
      references[ppn] --;
    80002d58:	0000e797          	auipc	a5,0xe
    80002d5c:	fc878793          	addi	a5,a5,-56 # 80010d20 <references>
    80002d60:	97d6                	add	a5,a5,s5
    80002d62:	377d                	addiw	a4,a4,-1
    80002d64:	00e78023          	sb	a4,0(a5)
      char *mem = kalloc();
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	e3a080e7          	jalr	-454(ra) # 80000ba2 <kalloc>
    80002d70:	8b2a                	mv	s6,a0
      if(mem == 0){
    80002d72:	c931                	beqz	a0,80002dc6 <usertrap+0x1bc>
      memmove(mem, (char*)pa, PGSIZE);
    80002d74:	6605                	lui	a2,0x1
    80002d76:	00ca9593          	slli	a1,s5,0xc
    80002d7a:	855a                	mv	a0,s6
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	0be080e7          	jalr	190(ra) # 80000e3a <memmove>
      if(mappages(pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U|PTE_V) != 0){
    80002d84:	477d                	li	a4,31
    80002d86:	86da                	mv	a3,s6
    80002d88:	6605                	lui	a2,0x1
    80002d8a:	75fd                	lui	a1,0xfffff
    80002d8c:	00ba75b3          	and	a1,s4,a1
    80002d90:	854e                	mv	a0,s3
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	41c080e7          	jalr	1052(ra) # 800011ae <mappages>
    80002d9a:	e521                	bnez	a0,80002de2 <usertrap+0x1d8>
      references[PTE2PPN(*walk(pagetable, va, 0))] ++;
    80002d9c:	4601                	li	a2,0
    80002d9e:	85d2                	mv	a1,s4
    80002da0:	854e                	mv	a0,s3
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	324080e7          	jalr	804(ra) # 800010c6 <walk>
    80002daa:	611c                	ld	a5,0(a0)
    80002dac:	00a7d713          	srli	a4,a5,0xa
    80002db0:	0000e797          	auipc	a5,0xe
    80002db4:	f7078793          	addi	a5,a5,-144 # 80010d20 <references>
    80002db8:	97ba                	add	a5,a5,a4
    80002dba:	0007c703          	lbu	a4,0(a5)
    80002dbe:	2705                	addiw	a4,a4,1
    80002dc0:	00e78023          	sb	a4,0(a5)
    80002dc4:	b759                	j	80002d4a <usertrap+0x140>
        printf("kalloc failed\n");
    80002dc6:	00005517          	auipc	a0,0x5
    80002dca:	6ba50513          	addi	a0,a0,1722 # 80008480 <states.1774+0x78>
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	7d2080e7          	jalr	2002(ra) # 800005a0 <printf>
        exit(-1);
    80002dd6:	557d                	li	a0,-1
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	6ba080e7          	jalr	1722(ra) # 80002492 <exit>
    80002de0:	bf51                	j	80002d74 <usertrap+0x16a>
        printf("mappages failed\n");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	6ae50513          	addi	a0,a0,1710 # 80008490 <states.1774+0x88>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	7b6080e7          	jalr	1974(ra) # 800005a0 <printf>
        exit(-1);
    80002df2:	557d                	li	a0,-1
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	69e080e7          	jalr	1694(ra) # 80002492 <exit>
    80002dfc:	b745                	j	80002d9c <usertrap+0x192>
  if(killed(p))
    80002dfe:	8526                	mv	a0,s1
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	806080e7          	jalr	-2042(ra) # 80002606 <killed>
    80002e08:	c901                	beqz	a0,80002e18 <usertrap+0x20e>
    80002e0a:	a011                	j	80002e0e <usertrap+0x204>
    80002e0c:	4901                	li	s2,0
    exit(-1);
    80002e0e:	557d                	li	a0,-1
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	682080e7          	jalr	1666(ra) # 80002492 <exit>
  if(which_dev == 2)
    80002e18:	4789                	li	a5,2
    80002e1a:	ecf916e3          	bne	s2,a5,80002ce6 <usertrap+0xdc>
    yield();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	504080e7          	jalr	1284(ra) # 80002322 <yield>
    80002e26:	b5c1                	j	80002ce6 <usertrap+0xdc>

0000000080002e28 <kerneltrap>:
{
    80002e28:	7179                	addi	sp,sp,-48
    80002e2a:	f406                	sd	ra,40(sp)
    80002e2c:	f022                	sd	s0,32(sp)
    80002e2e:	ec26                	sd	s1,24(sp)
    80002e30:	e84a                	sd	s2,16(sp)
    80002e32:	e44e                	sd	s3,8(sp)
    80002e34:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e36:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e3a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e42:	1004f793          	andi	a5,s1,256
    80002e46:	cb85                	beqz	a5,80002e76 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e4c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e4e:	ef85                	bnez	a5,80002e86 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	d18080e7          	jalr	-744(ra) # 80002b68 <devintr>
    80002e58:	cd1d                	beqz	a0,80002e96 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e5a:	4789                	li	a5,2
    80002e5c:	06f50a63          	beq	a0,a5,80002ed0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e60:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e64:	10049073          	csrw	sstatus,s1
}
    80002e68:	70a2                	ld	ra,40(sp)
    80002e6a:	7402                	ld	s0,32(sp)
    80002e6c:	64e2                	ld	s1,24(sp)
    80002e6e:	6942                	ld	s2,16(sp)
    80002e70:	69a2                	ld	s3,8(sp)
    80002e72:	6145                	addi	sp,sp,48
    80002e74:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	68250513          	addi	a0,a0,1666 # 800084f8 <states.1774+0xf0>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	6c6080e7          	jalr	1734(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	69a50513          	addi	a0,a0,1690 # 80008520 <states.1774+0x118>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	6b6080e7          	jalr	1718(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002e96:	85ce                	mv	a1,s3
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	6a850513          	addi	a0,a0,1704 # 80008540 <states.1774+0x138>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	700080e7          	jalr	1792(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eac:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eb0:	00005517          	auipc	a0,0x5
    80002eb4:	6a050513          	addi	a0,a0,1696 # 80008550 <states.1774+0x148>
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	6e8080e7          	jalr	1768(ra) # 800005a0 <printf>
    panic("kerneltrap");
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	6a850513          	addi	a0,a0,1704 # 80008568 <states.1774+0x160>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	67c080e7          	jalr	1660(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	d2a080e7          	jalr	-726(ra) # 80001bfa <myproc>
    80002ed8:	d541                	beqz	a0,80002e60 <kerneltrap+0x38>
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	d20080e7          	jalr	-736(ra) # 80001bfa <myproc>
    80002ee2:	4d18                	lw	a4,24(a0)
    80002ee4:	4791                	li	a5,4
    80002ee6:	f6f71de3          	bne	a4,a5,80002e60 <kerneltrap+0x38>
    yield();
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	438080e7          	jalr	1080(ra) # 80002322 <yield>
    80002ef2:	b7bd                	j	80002e60 <kerneltrap+0x38>

0000000080002ef4 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	e426                	sd	s1,8(sp)
    80002efc:	1000                	addi	s0,sp,32
    80002efe:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	cfa080e7          	jalr	-774(ra) # 80001bfa <myproc>
    switch (n)
    80002f08:	4795                	li	a5,5
    80002f0a:	0497e163          	bltu	a5,s1,80002f4c <argraw+0x58>
    80002f0e:	048a                	slli	s1,s1,0x2
    80002f10:	00005717          	auipc	a4,0x5
    80002f14:	69070713          	addi	a4,a4,1680 # 800085a0 <states.1774+0x198>
    80002f18:	94ba                	add	s1,s1,a4
    80002f1a:	409c                	lw	a5,0(s1)
    80002f1c:	97ba                	add	a5,a5,a4
    80002f1e:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f20:	6d3c                	ld	a5,88(a0)
    80002f22:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret
        return p->trapframe->a1;
    80002f2e:	6d3c                	ld	a5,88(a0)
    80002f30:	7fa8                	ld	a0,120(a5)
    80002f32:	bfcd                	j	80002f24 <argraw+0x30>
        return p->trapframe->a2;
    80002f34:	6d3c                	ld	a5,88(a0)
    80002f36:	63c8                	ld	a0,128(a5)
    80002f38:	b7f5                	j	80002f24 <argraw+0x30>
        return p->trapframe->a3;
    80002f3a:	6d3c                	ld	a5,88(a0)
    80002f3c:	67c8                	ld	a0,136(a5)
    80002f3e:	b7dd                	j	80002f24 <argraw+0x30>
        return p->trapframe->a4;
    80002f40:	6d3c                	ld	a5,88(a0)
    80002f42:	6bc8                	ld	a0,144(a5)
    80002f44:	b7c5                	j	80002f24 <argraw+0x30>
        return p->trapframe->a5;
    80002f46:	6d3c                	ld	a5,88(a0)
    80002f48:	6fc8                	ld	a0,152(a5)
    80002f4a:	bfe9                	j	80002f24 <argraw+0x30>
    panic("argraw");
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	62c50513          	addi	a0,a0,1580 # 80008578 <states.1774+0x170>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5f0080e7          	jalr	1520(ra) # 80000544 <panic>

0000000080002f5c <fetchaddr>:
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	e426                	sd	s1,8(sp)
    80002f64:	e04a                	sd	s2,0(sp)
    80002f66:	1000                	addi	s0,sp,32
    80002f68:	84aa                	mv	s1,a0
    80002f6a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	c8e080e7          	jalr	-882(ra) # 80001bfa <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f74:	653c                	ld	a5,72(a0)
    80002f76:	02f4f863          	bgeu	s1,a5,80002fa6 <fetchaddr+0x4a>
    80002f7a:	00848713          	addi	a4,s1,8
    80002f7e:	02e7e663          	bltu	a5,a4,80002faa <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f82:	46a1                	li	a3,8
    80002f84:	8626                	mv	a2,s1
    80002f86:	85ca                	mv	a1,s2
    80002f88:	6928                	ld	a0,80(a0)
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	8bc080e7          	jalr	-1860(ra) # 80001846 <copyin>
    80002f92:	00a03533          	snez	a0,a0
    80002f96:	40a00533          	neg	a0,a0
}
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	64a2                	ld	s1,8(sp)
    80002fa0:	6902                	ld	s2,0(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret
        return -1;
    80002fa6:	557d                	li	a0,-1
    80002fa8:	bfcd                	j	80002f9a <fetchaddr+0x3e>
    80002faa:	557d                	li	a0,-1
    80002fac:	b7fd                	j	80002f9a <fetchaddr+0x3e>

0000000080002fae <fetchstr>:
{
    80002fae:	7179                	addi	sp,sp,-48
    80002fb0:	f406                	sd	ra,40(sp)
    80002fb2:	f022                	sd	s0,32(sp)
    80002fb4:	ec26                	sd	s1,24(sp)
    80002fb6:	e84a                	sd	s2,16(sp)
    80002fb8:	e44e                	sd	s3,8(sp)
    80002fba:	1800                	addi	s0,sp,48
    80002fbc:	892a                	mv	s2,a0
    80002fbe:	84ae                	mv	s1,a1
    80002fc0:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	c38080e7          	jalr	-968(ra) # 80001bfa <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fca:	86ce                	mv	a3,s3
    80002fcc:	864a                	mv	a2,s2
    80002fce:	85a6                	mv	a1,s1
    80002fd0:	6928                	ld	a0,80(a0)
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	900080e7          	jalr	-1792(ra) # 800018d2 <copyinstr>
    80002fda:	00054e63          	bltz	a0,80002ff6 <fetchstr+0x48>
    return strlen(buf);
    80002fde:	8526                	mv	a0,s1
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	f7e080e7          	jalr	-130(ra) # 80000f5e <strlen>
}
    80002fe8:	70a2                	ld	ra,40(sp)
    80002fea:	7402                	ld	s0,32(sp)
    80002fec:	64e2                	ld	s1,24(sp)
    80002fee:	6942                	ld	s2,16(sp)
    80002ff0:	69a2                	ld	s3,8(sp)
    80002ff2:	6145                	addi	sp,sp,48
    80002ff4:	8082                	ret
        return -1;
    80002ff6:	557d                	li	a0,-1
    80002ff8:	bfc5                	j	80002fe8 <fetchstr+0x3a>

0000000080002ffa <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	eee080e7          	jalr	-274(ra) # 80002ef4 <argraw>
    8000300e:	c088                	sw	a0,0(s1)
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	ece080e7          	jalr	-306(ra) # 80002ef4 <argraw>
    8000302e:	e088                	sd	a0,0(s1)
}
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	64a2                	ld	s1,8(sp)
    80003036:	6105                	addi	sp,sp,32
    80003038:	8082                	ret

000000008000303a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000303a:	7179                	addi	sp,sp,-48
    8000303c:	f406                	sd	ra,40(sp)
    8000303e:	f022                	sd	s0,32(sp)
    80003040:	ec26                	sd	s1,24(sp)
    80003042:	e84a                	sd	s2,16(sp)
    80003044:	1800                	addi	s0,sp,48
    80003046:	84ae                	mv	s1,a1
    80003048:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000304a:	fd840593          	addi	a1,s0,-40
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	fcc080e7          	jalr	-52(ra) # 8000301a <argaddr>
    return fetchstr(addr, buf, max);
    80003056:	864a                	mv	a2,s2
    80003058:	85a6                	mv	a1,s1
    8000305a:	fd843503          	ld	a0,-40(s0)
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	f50080e7          	jalr	-176(ra) # 80002fae <fetchstr>
}
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6942                	ld	s2,16(sp)
    8000306e:	6145                	addi	sp,sp,48
    80003070:	8082                	ret

0000000080003072 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	e04a                	sd	s2,0(sp)
    8000307c:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	b7c080e7          	jalr	-1156(ra) # 80001bfa <myproc>
    80003086:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003088:	05853903          	ld	s2,88(a0)
    8000308c:	0a893783          	ld	a5,168(s2)
    80003090:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003094:	37fd                	addiw	a5,a5,-1
    80003096:	4765                	li	a4,25
    80003098:	00f76f63          	bltu	a4,a5,800030b6 <syscall+0x44>
    8000309c:	00369713          	slli	a4,a3,0x3
    800030a0:	00005797          	auipc	a5,0x5
    800030a4:	51878793          	addi	a5,a5,1304 # 800085b8 <syscalls>
    800030a8:	97ba                	add	a5,a5,a4
    800030aa:	639c                	ld	a5,0(a5)
    800030ac:	c789                	beqz	a5,800030b6 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030ae:	9782                	jalr	a5
    800030b0:	06a93823          	sd	a0,112(s2)
    800030b4:	a839                	j	800030d2 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030b6:	15848613          	addi	a2,s1,344
    800030ba:	588c                	lw	a1,48(s1)
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	4c450513          	addi	a0,a0,1220 # 80008580 <states.1774+0x178>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	4dc080e7          	jalr	1244(ra) # 800005a0 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030cc:	6cbc                	ld	a5,88(s1)
    800030ce:	577d                	li	a4,-1
    800030d0:	fbb8                	sd	a4,112(a5)
    }
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6902                	ld	s2,0(sp)
    800030da:	6105                	addi	sp,sp,32
    800030dc:	8082                	ret

00000000800030de <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030e6:	fec40593          	addi	a1,s0,-20
    800030ea:	4501                	li	a0,0
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	f0e080e7          	jalr	-242(ra) # 80002ffa <argint>
    exit(n);
    800030f4:	fec42503          	lw	a0,-20(s0)
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	39a080e7          	jalr	922(ra) # 80002492 <exit>
    return 0; // not reached
}
    80003100:	4501                	li	a0,0
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000310a:	1141                	addi	sp,sp,-16
    8000310c:	e406                	sd	ra,8(sp)
    8000310e:	e022                	sd	s0,0(sp)
    80003110:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003112:	fffff097          	auipc	ra,0xfffff
    80003116:	ae8080e7          	jalr	-1304(ra) # 80001bfa <myproc>
}
    8000311a:	5908                	lw	a0,48(a0)
    8000311c:	60a2                	ld	ra,8(sp)
    8000311e:	6402                	ld	s0,0(sp)
    80003120:	0141                	addi	sp,sp,16
    80003122:	8082                	ret

0000000080003124 <sys_fork>:

uint64
sys_fork(void)
{
    80003124:	1141                	addi	sp,sp,-16
    80003126:	e406                	sd	ra,8(sp)
    80003128:	e022                	sd	s0,0(sp)
    8000312a:	0800                	addi	s0,sp,16
    return fork();
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	fd4080e7          	jalr	-44(ra) # 80002100 <fork>
}
    80003134:	60a2                	ld	ra,8(sp)
    80003136:	6402                	ld	s0,0(sp)
    80003138:	0141                	addi	sp,sp,16
    8000313a:	8082                	ret

000000008000313c <sys_wait>:

uint64
sys_wait(void)
{
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003144:	fe840593          	addi	a1,s0,-24
    80003148:	4501                	li	a0,0
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	ed0080e7          	jalr	-304(ra) # 8000301a <argaddr>
    return wait(p);
    80003152:	fe843503          	ld	a0,-24(s0)
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	4e2080e7          	jalr	1250(ra) # 80002638 <wait>
}
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003166:	7179                	addi	sp,sp,-48
    80003168:	f406                	sd	ra,40(sp)
    8000316a:	f022                	sd	s0,32(sp)
    8000316c:	ec26                	sd	s1,24(sp)
    8000316e:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003170:	fdc40593          	addi	a1,s0,-36
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	e84080e7          	jalr	-380(ra) # 80002ffa <argint>
    addr = myproc()->sz;
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	a7c080e7          	jalr	-1412(ra) # 80001bfa <myproc>
    80003186:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003188:	fdc42503          	lw	a0,-36(s0)
    8000318c:	fffff097          	auipc	ra,0xfffff
    80003190:	dc8080e7          	jalr	-568(ra) # 80001f54 <growproc>
    80003194:	00054863          	bltz	a0,800031a4 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003198:	8526                	mv	a0,s1
    8000319a:	70a2                	ld	ra,40(sp)
    8000319c:	7402                	ld	s0,32(sp)
    8000319e:	64e2                	ld	s1,24(sp)
    800031a0:	6145                	addi	sp,sp,48
    800031a2:	8082                	ret
        return -1;
    800031a4:	54fd                	li	s1,-1
    800031a6:	bfcd                	j	80003198 <sys_sbrk+0x32>

00000000800031a8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031a8:	7139                	addi	sp,sp,-64
    800031aa:	fc06                	sd	ra,56(sp)
    800031ac:	f822                	sd	s0,48(sp)
    800031ae:	f426                	sd	s1,40(sp)
    800031b0:	f04a                	sd	s2,32(sp)
    800031b2:	ec4e                	sd	s3,24(sp)
    800031b4:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031b6:	fcc40593          	addi	a1,s0,-52
    800031ba:	4501                	li	a0,0
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	e3e080e7          	jalr	-450(ra) # 80002ffa <argint>
    acquire(&tickslock);
    800031c4:	0001c517          	auipc	a0,0x1c
    800031c8:	98c50513          	addi	a0,a0,-1652 # 8001eb50 <tickslock>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	b12080e7          	jalr	-1262(ra) # 80000cde <acquire>
    ticks0 = ticks;
    800031d4:	00006917          	auipc	s2,0x6
    800031d8:	8dc92903          	lw	s2,-1828(s2) # 80008ab0 <ticks>
    while (ticks - ticks0 < n)
    800031dc:	fcc42783          	lw	a5,-52(s0)
    800031e0:	cf9d                	beqz	a5,8000321e <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031e2:	0001c997          	auipc	s3,0x1c
    800031e6:	96e98993          	addi	s3,s3,-1682 # 8001eb50 <tickslock>
    800031ea:	00006497          	auipc	s1,0x6
    800031ee:	8c648493          	addi	s1,s1,-1850 # 80008ab0 <ticks>
        if (killed(myproc()))
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	a08080e7          	jalr	-1528(ra) # 80001bfa <myproc>
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	40c080e7          	jalr	1036(ra) # 80002606 <killed>
    80003202:	ed15                	bnez	a0,8000323e <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003204:	85ce                	mv	a1,s3
    80003206:	8526                	mv	a0,s1
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	156080e7          	jalr	342(ra) # 8000235e <sleep>
    while (ticks - ticks0 < n)
    80003210:	409c                	lw	a5,0(s1)
    80003212:	412787bb          	subw	a5,a5,s2
    80003216:	fcc42703          	lw	a4,-52(s0)
    8000321a:	fce7ece3          	bltu	a5,a4,800031f2 <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000321e:	0001c517          	auipc	a0,0x1c
    80003222:	93250513          	addi	a0,a0,-1742 # 8001eb50 <tickslock>
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	b6c080e7          	jalr	-1172(ra) # 80000d92 <release>
    return 0;
    8000322e:	4501                	li	a0,0
}
    80003230:	70e2                	ld	ra,56(sp)
    80003232:	7442                	ld	s0,48(sp)
    80003234:	74a2                	ld	s1,40(sp)
    80003236:	7902                	ld	s2,32(sp)
    80003238:	69e2                	ld	s3,24(sp)
    8000323a:	6121                	addi	sp,sp,64
    8000323c:	8082                	ret
            release(&tickslock);
    8000323e:	0001c517          	auipc	a0,0x1c
    80003242:	91250513          	addi	a0,a0,-1774 # 8001eb50 <tickslock>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	b4c080e7          	jalr	-1204(ra) # 80000d92 <release>
            return -1;
    8000324e:	557d                	li	a0,-1
    80003250:	b7c5                	j	80003230 <sys_sleep+0x88>

0000000080003252 <sys_kill>:

uint64
sys_kill(void)
{
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000325a:	fec40593          	addi	a1,s0,-20
    8000325e:	4501                	li	a0,0
    80003260:	00000097          	auipc	ra,0x0
    80003264:	d9a080e7          	jalr	-614(ra) # 80002ffa <argint>
    return kill(pid);
    80003268:	fec42503          	lw	a0,-20(s0)
    8000326c:	fffff097          	auipc	ra,0xfffff
    80003270:	2fc080e7          	jalr	764(ra) # 80002568 <kill>
}
    80003274:	60e2                	ld	ra,24(sp)
    80003276:	6442                	ld	s0,16(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret

000000008000327c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000327c:	1101                	addi	sp,sp,-32
    8000327e:	ec06                	sd	ra,24(sp)
    80003280:	e822                	sd	s0,16(sp)
    80003282:	e426                	sd	s1,8(sp)
    80003284:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003286:	0001c517          	auipc	a0,0x1c
    8000328a:	8ca50513          	addi	a0,a0,-1846 # 8001eb50 <tickslock>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	a50080e7          	jalr	-1456(ra) # 80000cde <acquire>
    xticks = ticks;
    80003296:	00006497          	auipc	s1,0x6
    8000329a:	81a4a483          	lw	s1,-2022(s1) # 80008ab0 <ticks>
    release(&tickslock);
    8000329e:	0001c517          	auipc	a0,0x1c
    800032a2:	8b250513          	addi	a0,a0,-1870 # 8001eb50 <tickslock>
    800032a6:	ffffe097          	auipc	ra,0xffffe
    800032aa:	aec080e7          	jalr	-1300(ra) # 80000d92 <release>
    return xticks;
}
    800032ae:	02049513          	slli	a0,s1,0x20
    800032b2:	9101                	srli	a0,a0,0x20
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	64a2                	ld	s1,8(sp)
    800032ba:	6105                	addi	sp,sp,32
    800032bc:	8082                	ret

00000000800032be <sys_ps>:

void *
sys_ps(void)
{
    800032be:	1101                	addi	sp,sp,-32
    800032c0:	ec06                	sd	ra,24(sp)
    800032c2:	e822                	sd	s0,16(sp)
    800032c4:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032c6:	fe042623          	sw	zero,-20(s0)
    800032ca:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032ce:	fec40593          	addi	a1,s0,-20
    800032d2:	4501                	li	a0,0
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	d26080e7          	jalr	-730(ra) # 80002ffa <argint>
    argint(1, &count);
    800032dc:	fe840593          	addi	a1,s0,-24
    800032e0:	4505                	li	a0,1
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	d18080e7          	jalr	-744(ra) # 80002ffa <argint>
    return ps((uint8)start, (uint8)count);
    800032ea:	fe844583          	lbu	a1,-24(s0)
    800032ee:	fec44503          	lbu	a0,-20(s0)
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	cbe080e7          	jalr	-834(ra) # 80001fb0 <ps>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003302:	1141                	addi	sp,sp,-16
    80003304:	e406                	sd	ra,8(sp)
    80003306:	e022                	sd	s0,0(sp)
    80003308:	0800                	addi	s0,sp,16
    schedls();
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	5b6080e7          	jalr	1462(ra) # 800028c0 <schedls>
    return 0;
}
    80003312:	4501                	li	a0,0
    80003314:	60a2                	ld	ra,8(sp)
    80003316:	6402                	ld	s0,0(sp)
    80003318:	0141                	addi	sp,sp,16
    8000331a:	8082                	ret

000000008000331c <sys_schedset>:

uint64 sys_schedset(void)
{
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	1000                	addi	s0,sp,32
    int id = 0;
    80003324:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003328:	fec40593          	addi	a1,s0,-20
    8000332c:	4501                	li	a0,0
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	ccc080e7          	jalr	-820(ra) # 80002ffa <argint>
    schedset(id - 1);
    80003336:	fec42503          	lw	a0,-20(s0)
    8000333a:	357d                	addiw	a0,a0,-1
    8000333c:	fffff097          	auipc	ra,0xfffff
    80003340:	61a080e7          	jalr	1562(ra) # 80002956 <schedset>
    return 0;
}
    80003344:	4501                	li	a0,0
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	6105                	addi	sp,sp,32
    8000334c:	8082                	ret

000000008000334e <sys_va2pa>:

uint64 sys_va2pa(void)
{
    8000334e:	1101                	addi	sp,sp,-32
    80003350:	ec06                	sd	ra,24(sp)
    80003352:	e822                	sd	s0,16(sp)
    80003354:	1000                	addi	s0,sp,32
    uint64 va = 0;
    80003356:	fe043423          	sd	zero,-24(s0)
    uint64 pid = 0;
    8000335a:	fe043023          	sd	zero,-32(s0)
    argaddr(0, &va);
    8000335e:	fe840593          	addi	a1,s0,-24
    80003362:	4501                	li	a0,0
    80003364:	00000097          	auipc	ra,0x0
    80003368:	cb6080e7          	jalr	-842(ra) # 8000301a <argaddr>
    argaddr(1, &pid);
    8000336c:	fe040593          	addi	a1,s0,-32
    80003370:	4505                	li	a0,1
    80003372:	00000097          	auipc	ra,0x0
    80003376:	ca8080e7          	jalr	-856(ra) # 8000301a <argaddr>

    if(!pid) pid = myproc()->pid;
    8000337a:	fe043783          	ld	a5,-32(s0)
    8000337e:	cf89                	beqz	a5,80003398 <sys_va2pa+0x4a>

    return va2pa(&va, &pid);
    80003380:	fe040593          	addi	a1,s0,-32
    80003384:	fe840513          	addi	a0,s0,-24
    80003388:	fffff097          	auipc	ra,0xfffff
    8000338c:	61a080e7          	jalr	1562(ra) # 800029a2 <va2pa>

}
    80003390:	60e2                	ld	ra,24(sp)
    80003392:	6442                	ld	s0,16(sp)
    80003394:	6105                	addi	sp,sp,32
    80003396:	8082                	ret
    if(!pid) pid = myproc()->pid;
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	862080e7          	jalr	-1950(ra) # 80001bfa <myproc>
    800033a0:	591c                	lw	a5,48(a0)
    800033a2:	fef43023          	sd	a5,-32(s0)
    800033a6:	bfe9                	j	80003380 <sys_va2pa+0x32>

00000000800033a8 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800033a8:	1141                	addi	sp,sp,-16
    800033aa:	e406                	sd	ra,8(sp)
    800033ac:	e022                	sd	s0,0(sp)
    800033ae:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800033b0:	00005597          	auipc	a1,0x5
    800033b4:	6d85b583          	ld	a1,1752(a1) # 80008a88 <FREE_PAGES>
    800033b8:	00005517          	auipc	a0,0x5
    800033bc:	1e050513          	addi	a0,a0,480 # 80008598 <states.1774+0x190>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	1e0080e7          	jalr	480(ra) # 800005a0 <printf>
    return 0;
    800033c8:	4501                	li	a0,0
    800033ca:	60a2                	ld	ra,8(sp)
    800033cc:	6402                	ld	s0,0(sp)
    800033ce:	0141                	addi	sp,sp,16
    800033d0:	8082                	ret

00000000800033d2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033d2:	7179                	addi	sp,sp,-48
    800033d4:	f406                	sd	ra,40(sp)
    800033d6:	f022                	sd	s0,32(sp)
    800033d8:	ec26                	sd	s1,24(sp)
    800033da:	e84a                	sd	s2,16(sp)
    800033dc:	e44e                	sd	s3,8(sp)
    800033de:	e052                	sd	s4,0(sp)
    800033e0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033e2:	00005597          	auipc	a1,0x5
    800033e6:	2ae58593          	addi	a1,a1,686 # 80008690 <syscalls+0xd8>
    800033ea:	0001b517          	auipc	a0,0x1b
    800033ee:	77e50513          	addi	a0,a0,1918 # 8001eb68 <bcache>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	85c080e7          	jalr	-1956(ra) # 80000c4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033fa:	00023797          	auipc	a5,0x23
    800033fe:	76e78793          	addi	a5,a5,1902 # 80026b68 <bcache+0x8000>
    80003402:	00024717          	auipc	a4,0x24
    80003406:	9ce70713          	addi	a4,a4,-1586 # 80026dd0 <bcache+0x8268>
    8000340a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000340e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003412:	0001b497          	auipc	s1,0x1b
    80003416:	76e48493          	addi	s1,s1,1902 # 8001eb80 <bcache+0x18>
    b->next = bcache.head.next;
    8000341a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000341c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000341e:	00005a17          	auipc	s4,0x5
    80003422:	27aa0a13          	addi	s4,s4,634 # 80008698 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003426:	2b893783          	ld	a5,696(s2)
    8000342a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000342c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003430:	85d2                	mv	a1,s4
    80003432:	01048513          	addi	a0,s1,16
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	4c4080e7          	jalr	1220(ra) # 800048fa <initsleeplock>
    bcache.head.next->prev = b;
    8000343e:	2b893783          	ld	a5,696(s2)
    80003442:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003444:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003448:	45848493          	addi	s1,s1,1112
    8000344c:	fd349de3          	bne	s1,s3,80003426 <binit+0x54>
  }
}
    80003450:	70a2                	ld	ra,40(sp)
    80003452:	7402                	ld	s0,32(sp)
    80003454:	64e2                	ld	s1,24(sp)
    80003456:	6942                	ld	s2,16(sp)
    80003458:	69a2                	ld	s3,8(sp)
    8000345a:	6a02                	ld	s4,0(sp)
    8000345c:	6145                	addi	sp,sp,48
    8000345e:	8082                	ret

0000000080003460 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003460:	7179                	addi	sp,sp,-48
    80003462:	f406                	sd	ra,40(sp)
    80003464:	f022                	sd	s0,32(sp)
    80003466:	ec26                	sd	s1,24(sp)
    80003468:	e84a                	sd	s2,16(sp)
    8000346a:	e44e                	sd	s3,8(sp)
    8000346c:	1800                	addi	s0,sp,48
    8000346e:	89aa                	mv	s3,a0
    80003470:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003472:	0001b517          	auipc	a0,0x1b
    80003476:	6f650513          	addi	a0,a0,1782 # 8001eb68 <bcache>
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	864080e7          	jalr	-1948(ra) # 80000cde <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003482:	00024497          	auipc	s1,0x24
    80003486:	99e4b483          	ld	s1,-1634(s1) # 80026e20 <bcache+0x82b8>
    8000348a:	00024797          	auipc	a5,0x24
    8000348e:	94678793          	addi	a5,a5,-1722 # 80026dd0 <bcache+0x8268>
    80003492:	02f48f63          	beq	s1,a5,800034d0 <bread+0x70>
    80003496:	873e                	mv	a4,a5
    80003498:	a021                	j	800034a0 <bread+0x40>
    8000349a:	68a4                	ld	s1,80(s1)
    8000349c:	02e48a63          	beq	s1,a4,800034d0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034a0:	449c                	lw	a5,8(s1)
    800034a2:	ff379ce3          	bne	a5,s3,8000349a <bread+0x3a>
    800034a6:	44dc                	lw	a5,12(s1)
    800034a8:	ff2799e3          	bne	a5,s2,8000349a <bread+0x3a>
      b->refcnt++;
    800034ac:	40bc                	lw	a5,64(s1)
    800034ae:	2785                	addiw	a5,a5,1
    800034b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034b2:	0001b517          	auipc	a0,0x1b
    800034b6:	6b650513          	addi	a0,a0,1718 # 8001eb68 <bcache>
    800034ba:	ffffe097          	auipc	ra,0xffffe
    800034be:	8d8080e7          	jalr	-1832(ra) # 80000d92 <release>
      acquiresleep(&b->lock);
    800034c2:	01048513          	addi	a0,s1,16
    800034c6:	00001097          	auipc	ra,0x1
    800034ca:	46e080e7          	jalr	1134(ra) # 80004934 <acquiresleep>
      return b;
    800034ce:	a8b9                	j	8000352c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034d0:	00024497          	auipc	s1,0x24
    800034d4:	9484b483          	ld	s1,-1720(s1) # 80026e18 <bcache+0x82b0>
    800034d8:	00024797          	auipc	a5,0x24
    800034dc:	8f878793          	addi	a5,a5,-1800 # 80026dd0 <bcache+0x8268>
    800034e0:	00f48863          	beq	s1,a5,800034f0 <bread+0x90>
    800034e4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	cf81                	beqz	a5,80003500 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ea:	64a4                	ld	s1,72(s1)
    800034ec:	fee49de3          	bne	s1,a4,800034e6 <bread+0x86>
  panic("bget: no buffers");
    800034f0:	00005517          	auipc	a0,0x5
    800034f4:	1b050513          	addi	a0,a0,432 # 800086a0 <syscalls+0xe8>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	04c080e7          	jalr	76(ra) # 80000544 <panic>
      b->dev = dev;
    80003500:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003504:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003508:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000350c:	4785                	li	a5,1
    8000350e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003510:	0001b517          	auipc	a0,0x1b
    80003514:	65850513          	addi	a0,a0,1624 # 8001eb68 <bcache>
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	87a080e7          	jalr	-1926(ra) # 80000d92 <release>
      acquiresleep(&b->lock);
    80003520:	01048513          	addi	a0,s1,16
    80003524:	00001097          	auipc	ra,0x1
    80003528:	410080e7          	jalr	1040(ra) # 80004934 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000352c:	409c                	lw	a5,0(s1)
    8000352e:	cb89                	beqz	a5,80003540 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003530:	8526                	mv	a0,s1
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003540:	4581                	li	a1,0
    80003542:	8526                	mv	a0,s1
    80003544:	00003097          	auipc	ra,0x3
    80003548:	fc4080e7          	jalr	-60(ra) # 80006508 <virtio_disk_rw>
    b->valid = 1;
    8000354c:	4785                	li	a5,1
    8000354e:	c09c                	sw	a5,0(s1)
  return b;
    80003550:	b7c5                	j	80003530 <bread+0xd0>

0000000080003552 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003552:	1101                	addi	sp,sp,-32
    80003554:	ec06                	sd	ra,24(sp)
    80003556:	e822                	sd	s0,16(sp)
    80003558:	e426                	sd	s1,8(sp)
    8000355a:	1000                	addi	s0,sp,32
    8000355c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000355e:	0541                	addi	a0,a0,16
    80003560:	00001097          	auipc	ra,0x1
    80003564:	46e080e7          	jalr	1134(ra) # 800049ce <holdingsleep>
    80003568:	cd01                	beqz	a0,80003580 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000356a:	4585                	li	a1,1
    8000356c:	8526                	mv	a0,s1
    8000356e:	00003097          	auipc	ra,0x3
    80003572:	f9a080e7          	jalr	-102(ra) # 80006508 <virtio_disk_rw>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6105                	addi	sp,sp,32
    8000357e:	8082                	ret
    panic("bwrite");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	13850513          	addi	a0,a0,312 # 800086b8 <syscalls+0x100>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fbc080e7          	jalr	-68(ra) # 80000544 <panic>

0000000080003590 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	e04a                	sd	s2,0(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000359e:	01050913          	addi	s2,a0,16
    800035a2:	854a                	mv	a0,s2
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	42a080e7          	jalr	1066(ra) # 800049ce <holdingsleep>
    800035ac:	c92d                	beqz	a0,8000361e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035ae:	854a                	mv	a0,s2
    800035b0:	00001097          	auipc	ra,0x1
    800035b4:	3da080e7          	jalr	986(ra) # 8000498a <releasesleep>

  acquire(&bcache.lock);
    800035b8:	0001b517          	auipc	a0,0x1b
    800035bc:	5b050513          	addi	a0,a0,1456 # 8001eb68 <bcache>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	71e080e7          	jalr	1822(ra) # 80000cde <acquire>
  b->refcnt--;
    800035c8:	40bc                	lw	a5,64(s1)
    800035ca:	37fd                	addiw	a5,a5,-1
    800035cc:	0007871b          	sext.w	a4,a5
    800035d0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035d2:	eb05                	bnez	a4,80003602 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035d4:	68bc                	ld	a5,80(s1)
    800035d6:	64b8                	ld	a4,72(s1)
    800035d8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035da:	64bc                	ld	a5,72(s1)
    800035dc:	68b8                	ld	a4,80(s1)
    800035de:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035e0:	00023797          	auipc	a5,0x23
    800035e4:	58878793          	addi	a5,a5,1416 # 80026b68 <bcache+0x8000>
    800035e8:	2b87b703          	ld	a4,696(a5)
    800035ec:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035ee:	00023717          	auipc	a4,0x23
    800035f2:	7e270713          	addi	a4,a4,2018 # 80026dd0 <bcache+0x8268>
    800035f6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035f8:	2b87b703          	ld	a4,696(a5)
    800035fc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035fe:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003602:	0001b517          	auipc	a0,0x1b
    80003606:	56650513          	addi	a0,a0,1382 # 8001eb68 <bcache>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	788080e7          	jalr	1928(ra) # 80000d92 <release>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6902                	ld	s2,0(sp)
    8000361a:	6105                	addi	sp,sp,32
    8000361c:	8082                	ret
    panic("brelse");
    8000361e:	00005517          	auipc	a0,0x5
    80003622:	0a250513          	addi	a0,a0,162 # 800086c0 <syscalls+0x108>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	f1e080e7          	jalr	-226(ra) # 80000544 <panic>

000000008000362e <bpin>:

void
bpin(struct buf *b) {
    8000362e:	1101                	addi	sp,sp,-32
    80003630:	ec06                	sd	ra,24(sp)
    80003632:	e822                	sd	s0,16(sp)
    80003634:	e426                	sd	s1,8(sp)
    80003636:	1000                	addi	s0,sp,32
    80003638:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000363a:	0001b517          	auipc	a0,0x1b
    8000363e:	52e50513          	addi	a0,a0,1326 # 8001eb68 <bcache>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	69c080e7          	jalr	1692(ra) # 80000cde <acquire>
  b->refcnt++;
    8000364a:	40bc                	lw	a5,64(s1)
    8000364c:	2785                	addiw	a5,a5,1
    8000364e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003650:	0001b517          	auipc	a0,0x1b
    80003654:	51850513          	addi	a0,a0,1304 # 8001eb68 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	73a080e7          	jalr	1850(ra) # 80000d92 <release>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret

000000008000366a <bunpin>:

void
bunpin(struct buf *b) {
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	ec06                	sd	ra,24(sp)
    8000366e:	e822                	sd	s0,16(sp)
    80003670:	e426                	sd	s1,8(sp)
    80003672:	1000                	addi	s0,sp,32
    80003674:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003676:	0001b517          	auipc	a0,0x1b
    8000367a:	4f250513          	addi	a0,a0,1266 # 8001eb68 <bcache>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	660080e7          	jalr	1632(ra) # 80000cde <acquire>
  b->refcnt--;
    80003686:	40bc                	lw	a5,64(s1)
    80003688:	37fd                	addiw	a5,a5,-1
    8000368a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000368c:	0001b517          	auipc	a0,0x1b
    80003690:	4dc50513          	addi	a0,a0,1244 # 8001eb68 <bcache>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	6fe080e7          	jalr	1790(ra) # 80000d92 <release>
}
    8000369c:	60e2                	ld	ra,24(sp)
    8000369e:	6442                	ld	s0,16(sp)
    800036a0:	64a2                	ld	s1,8(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret

00000000800036a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036a6:	1101                	addi	sp,sp,-32
    800036a8:	ec06                	sd	ra,24(sp)
    800036aa:	e822                	sd	s0,16(sp)
    800036ac:	e426                	sd	s1,8(sp)
    800036ae:	e04a                	sd	s2,0(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036b4:	00d5d59b          	srliw	a1,a1,0xd
    800036b8:	00024797          	auipc	a5,0x24
    800036bc:	b8c7a783          	lw	a5,-1140(a5) # 80027244 <sb+0x1c>
    800036c0:	9dbd                	addw	a1,a1,a5
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	d9e080e7          	jalr	-610(ra) # 80003460 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036ca:	0074f713          	andi	a4,s1,7
    800036ce:	4785                	li	a5,1
    800036d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036d4:	14ce                	slli	s1,s1,0x33
    800036d6:	90d9                	srli	s1,s1,0x36
    800036d8:	00950733          	add	a4,a0,s1
    800036dc:	05874703          	lbu	a4,88(a4)
    800036e0:	00e7f6b3          	and	a3,a5,a4
    800036e4:	c69d                	beqz	a3,80003712 <bfree+0x6c>
    800036e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036e8:	94aa                	add	s1,s1,a0
    800036ea:	fff7c793          	not	a5,a5
    800036ee:	8ff9                	and	a5,a5,a4
    800036f0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	120080e7          	jalr	288(ra) # 80004814 <log_write>
  brelse(bp);
    800036fc:	854a                	mv	a0,s2
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	e92080e7          	jalr	-366(ra) # 80003590 <brelse>
}
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6902                	ld	s2,0(sp)
    8000370e:	6105                	addi	sp,sp,32
    80003710:	8082                	ret
    panic("freeing free block");
    80003712:	00005517          	auipc	a0,0x5
    80003716:	fb650513          	addi	a0,a0,-74 # 800086c8 <syscalls+0x110>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e2a080e7          	jalr	-470(ra) # 80000544 <panic>

0000000080003722 <balloc>:
{
    80003722:	711d                	addi	sp,sp,-96
    80003724:	ec86                	sd	ra,88(sp)
    80003726:	e8a2                	sd	s0,80(sp)
    80003728:	e4a6                	sd	s1,72(sp)
    8000372a:	e0ca                	sd	s2,64(sp)
    8000372c:	fc4e                	sd	s3,56(sp)
    8000372e:	f852                	sd	s4,48(sp)
    80003730:	f456                	sd	s5,40(sp)
    80003732:	f05a                	sd	s6,32(sp)
    80003734:	ec5e                	sd	s7,24(sp)
    80003736:	e862                	sd	s8,16(sp)
    80003738:	e466                	sd	s9,8(sp)
    8000373a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000373c:	00024797          	auipc	a5,0x24
    80003740:	af07a783          	lw	a5,-1296(a5) # 8002722c <sb+0x4>
    80003744:	10078163          	beqz	a5,80003846 <balloc+0x124>
    80003748:	8baa                	mv	s7,a0
    8000374a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000374c:	00024b17          	auipc	s6,0x24
    80003750:	adcb0b13          	addi	s6,s6,-1316 # 80027228 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003754:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003756:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003758:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000375a:	6c89                	lui	s9,0x2
    8000375c:	a061                	j	800037e4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000375e:	974a                	add	a4,a4,s2
    80003760:	8fd5                	or	a5,a5,a3
    80003762:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003766:	854a                	mv	a0,s2
    80003768:	00001097          	auipc	ra,0x1
    8000376c:	0ac080e7          	jalr	172(ra) # 80004814 <log_write>
        brelse(bp);
    80003770:	854a                	mv	a0,s2
    80003772:	00000097          	auipc	ra,0x0
    80003776:	e1e080e7          	jalr	-482(ra) # 80003590 <brelse>
  bp = bread(dev, bno);
    8000377a:	85a6                	mv	a1,s1
    8000377c:	855e                	mv	a0,s7
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	ce2080e7          	jalr	-798(ra) # 80003460 <bread>
    80003786:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003788:	40000613          	li	a2,1024
    8000378c:	4581                	li	a1,0
    8000378e:	05850513          	addi	a0,a0,88
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	648080e7          	jalr	1608(ra) # 80000dda <memset>
  log_write(bp);
    8000379a:	854a                	mv	a0,s2
    8000379c:	00001097          	auipc	ra,0x1
    800037a0:	078080e7          	jalr	120(ra) # 80004814 <log_write>
  brelse(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	dea080e7          	jalr	-534(ra) # 80003590 <brelse>
}
    800037ae:	8526                	mv	a0,s1
    800037b0:	60e6                	ld	ra,88(sp)
    800037b2:	6446                	ld	s0,80(sp)
    800037b4:	64a6                	ld	s1,72(sp)
    800037b6:	6906                	ld	s2,64(sp)
    800037b8:	79e2                	ld	s3,56(sp)
    800037ba:	7a42                	ld	s4,48(sp)
    800037bc:	7aa2                	ld	s5,40(sp)
    800037be:	7b02                	ld	s6,32(sp)
    800037c0:	6be2                	ld	s7,24(sp)
    800037c2:	6c42                	ld	s8,16(sp)
    800037c4:	6ca2                	ld	s9,8(sp)
    800037c6:	6125                	addi	sp,sp,96
    800037c8:	8082                	ret
    brelse(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	dc4080e7          	jalr	-572(ra) # 80003590 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037d4:	015c87bb          	addw	a5,s9,s5
    800037d8:	00078a9b          	sext.w	s5,a5
    800037dc:	004b2703          	lw	a4,4(s6)
    800037e0:	06eaf363          	bgeu	s5,a4,80003846 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800037e4:	41fad79b          	sraiw	a5,s5,0x1f
    800037e8:	0137d79b          	srliw	a5,a5,0x13
    800037ec:	015787bb          	addw	a5,a5,s5
    800037f0:	40d7d79b          	sraiw	a5,a5,0xd
    800037f4:	01cb2583          	lw	a1,28(s6)
    800037f8:	9dbd                	addw	a1,a1,a5
    800037fa:	855e                	mv	a0,s7
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	c64080e7          	jalr	-924(ra) # 80003460 <bread>
    80003804:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003806:	004b2503          	lw	a0,4(s6)
    8000380a:	000a849b          	sext.w	s1,s5
    8000380e:	8662                	mv	a2,s8
    80003810:	faa4fde3          	bgeu	s1,a0,800037ca <balloc+0xa8>
      m = 1 << (bi % 8);
    80003814:	41f6579b          	sraiw	a5,a2,0x1f
    80003818:	01d7d69b          	srliw	a3,a5,0x1d
    8000381c:	00c6873b          	addw	a4,a3,a2
    80003820:	00777793          	andi	a5,a4,7
    80003824:	9f95                	subw	a5,a5,a3
    80003826:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000382a:	4037571b          	sraiw	a4,a4,0x3
    8000382e:	00e906b3          	add	a3,s2,a4
    80003832:	0586c683          	lbu	a3,88(a3)
    80003836:	00d7f5b3          	and	a1,a5,a3
    8000383a:	d195                	beqz	a1,8000375e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000383c:	2605                	addiw	a2,a2,1
    8000383e:	2485                	addiw	s1,s1,1
    80003840:	fd4618e3          	bne	a2,s4,80003810 <balloc+0xee>
    80003844:	b759                	j	800037ca <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	e9a50513          	addi	a0,a0,-358 # 800086e0 <syscalls+0x128>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	d52080e7          	jalr	-686(ra) # 800005a0 <printf>
  return 0;
    80003856:	4481                	li	s1,0
    80003858:	bf99                	j	800037ae <balloc+0x8c>

000000008000385a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000385a:	7179                	addi	sp,sp,-48
    8000385c:	f406                	sd	ra,40(sp)
    8000385e:	f022                	sd	s0,32(sp)
    80003860:	ec26                	sd	s1,24(sp)
    80003862:	e84a                	sd	s2,16(sp)
    80003864:	e44e                	sd	s3,8(sp)
    80003866:	e052                	sd	s4,0(sp)
    80003868:	1800                	addi	s0,sp,48
    8000386a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000386c:	47ad                	li	a5,11
    8000386e:	02b7e763          	bltu	a5,a1,8000389c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003872:	02059493          	slli	s1,a1,0x20
    80003876:	9081                	srli	s1,s1,0x20
    80003878:	048a                	slli	s1,s1,0x2
    8000387a:	94aa                	add	s1,s1,a0
    8000387c:	0504a903          	lw	s2,80(s1)
    80003880:	06091e63          	bnez	s2,800038fc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003884:	4108                	lw	a0,0(a0)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	e9c080e7          	jalr	-356(ra) # 80003722 <balloc>
    8000388e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003892:	06090563          	beqz	s2,800038fc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003896:	0524a823          	sw	s2,80(s1)
    8000389a:	a08d                	j	800038fc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000389c:	ff45849b          	addiw	s1,a1,-12
    800038a0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038a4:	0ff00793          	li	a5,255
    800038a8:	08e7e563          	bltu	a5,a4,80003932 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800038ac:	08052903          	lw	s2,128(a0)
    800038b0:	00091d63          	bnez	s2,800038ca <bmap+0x70>
      addr = balloc(ip->dev);
    800038b4:	4108                	lw	a0,0(a0)
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	e6c080e7          	jalr	-404(ra) # 80003722 <balloc>
    800038be:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038c2:	02090d63          	beqz	s2,800038fc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038c6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038ca:	85ca                	mv	a1,s2
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	b90080e7          	jalr	-1136(ra) # 80003460 <bread>
    800038d8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038da:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038de:	02049593          	slli	a1,s1,0x20
    800038e2:	9181                	srli	a1,a1,0x20
    800038e4:	058a                	slli	a1,a1,0x2
    800038e6:	00b784b3          	add	s1,a5,a1
    800038ea:	0004a903          	lw	s2,0(s1)
    800038ee:	02090063          	beqz	s2,8000390e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038f2:	8552                	mv	a0,s4
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	c9c080e7          	jalr	-868(ra) # 80003590 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038fc:	854a                	mv	a0,s2
    800038fe:	70a2                	ld	ra,40(sp)
    80003900:	7402                	ld	s0,32(sp)
    80003902:	64e2                	ld	s1,24(sp)
    80003904:	6942                	ld	s2,16(sp)
    80003906:	69a2                	ld	s3,8(sp)
    80003908:	6a02                	ld	s4,0(sp)
    8000390a:	6145                	addi	sp,sp,48
    8000390c:	8082                	ret
      addr = balloc(ip->dev);
    8000390e:	0009a503          	lw	a0,0(s3)
    80003912:	00000097          	auipc	ra,0x0
    80003916:	e10080e7          	jalr	-496(ra) # 80003722 <balloc>
    8000391a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000391e:	fc090ae3          	beqz	s2,800038f2 <bmap+0x98>
        a[bn] = addr;
    80003922:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003926:	8552                	mv	a0,s4
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	eec080e7          	jalr	-276(ra) # 80004814 <log_write>
    80003930:	b7c9                	j	800038f2 <bmap+0x98>
  panic("bmap: out of range");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	dc650513          	addi	a0,a0,-570 # 800086f8 <syscalls+0x140>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c0a080e7          	jalr	-1014(ra) # 80000544 <panic>

0000000080003942 <iget>:
{
    80003942:	7179                	addi	sp,sp,-48
    80003944:	f406                	sd	ra,40(sp)
    80003946:	f022                	sd	s0,32(sp)
    80003948:	ec26                	sd	s1,24(sp)
    8000394a:	e84a                	sd	s2,16(sp)
    8000394c:	e44e                	sd	s3,8(sp)
    8000394e:	e052                	sd	s4,0(sp)
    80003950:	1800                	addi	s0,sp,48
    80003952:	89aa                	mv	s3,a0
    80003954:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003956:	00024517          	auipc	a0,0x24
    8000395a:	8f250513          	addi	a0,a0,-1806 # 80027248 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	380080e7          	jalr	896(ra) # 80000cde <acquire>
  empty = 0;
    80003966:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003968:	00024497          	auipc	s1,0x24
    8000396c:	8f848493          	addi	s1,s1,-1800 # 80027260 <itable+0x18>
    80003970:	00025697          	auipc	a3,0x25
    80003974:	38068693          	addi	a3,a3,896 # 80028cf0 <log>
    80003978:	a039                	j	80003986 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000397a:	02090b63          	beqz	s2,800039b0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000397e:	08848493          	addi	s1,s1,136
    80003982:	02d48a63          	beq	s1,a3,800039b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003986:	449c                	lw	a5,8(s1)
    80003988:	fef059e3          	blez	a5,8000397a <iget+0x38>
    8000398c:	4098                	lw	a4,0(s1)
    8000398e:	ff3716e3          	bne	a4,s3,8000397a <iget+0x38>
    80003992:	40d8                	lw	a4,4(s1)
    80003994:	ff4713e3          	bne	a4,s4,8000397a <iget+0x38>
      ip->ref++;
    80003998:	2785                	addiw	a5,a5,1
    8000399a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000399c:	00024517          	auipc	a0,0x24
    800039a0:	8ac50513          	addi	a0,a0,-1876 # 80027248 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	3ee080e7          	jalr	1006(ra) # 80000d92 <release>
      return ip;
    800039ac:	8926                	mv	s2,s1
    800039ae:	a03d                	j	800039dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039b0:	f7f9                	bnez	a5,8000397e <iget+0x3c>
    800039b2:	8926                	mv	s2,s1
    800039b4:	b7e9                	j	8000397e <iget+0x3c>
  if(empty == 0)
    800039b6:	02090c63          	beqz	s2,800039ee <iget+0xac>
  ip->dev = dev;
    800039ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039c2:	4785                	li	a5,1
    800039c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039c8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039cc:	00024517          	auipc	a0,0x24
    800039d0:	87c50513          	addi	a0,a0,-1924 # 80027248 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	3be080e7          	jalr	958(ra) # 80000d92 <release>
}
    800039dc:	854a                	mv	a0,s2
    800039de:	70a2                	ld	ra,40(sp)
    800039e0:	7402                	ld	s0,32(sp)
    800039e2:	64e2                	ld	s1,24(sp)
    800039e4:	6942                	ld	s2,16(sp)
    800039e6:	69a2                	ld	s3,8(sp)
    800039e8:	6a02                	ld	s4,0(sp)
    800039ea:	6145                	addi	sp,sp,48
    800039ec:	8082                	ret
    panic("iget: no inodes");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	d2250513          	addi	a0,a0,-734 # 80008710 <syscalls+0x158>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b4e080e7          	jalr	-1202(ra) # 80000544 <panic>

00000000800039fe <fsinit>:
fsinit(int dev) {
    800039fe:	7179                	addi	sp,sp,-48
    80003a00:	f406                	sd	ra,40(sp)
    80003a02:	f022                	sd	s0,32(sp)
    80003a04:	ec26                	sd	s1,24(sp)
    80003a06:	e84a                	sd	s2,16(sp)
    80003a08:	e44e                	sd	s3,8(sp)
    80003a0a:	1800                	addi	s0,sp,48
    80003a0c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a0e:	4585                	li	a1,1
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	a50080e7          	jalr	-1456(ra) # 80003460 <bread>
    80003a18:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a1a:	00024997          	auipc	s3,0x24
    80003a1e:	80e98993          	addi	s3,s3,-2034 # 80027228 <sb>
    80003a22:	02000613          	li	a2,32
    80003a26:	05850593          	addi	a1,a0,88
    80003a2a:	854e                	mv	a0,s3
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	40e080e7          	jalr	1038(ra) # 80000e3a <memmove>
  brelse(bp);
    80003a34:	8526                	mv	a0,s1
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	b5a080e7          	jalr	-1190(ra) # 80003590 <brelse>
  if(sb.magic != FSMAGIC)
    80003a3e:	0009a703          	lw	a4,0(s3)
    80003a42:	102037b7          	lui	a5,0x10203
    80003a46:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a4a:	02f71263          	bne	a4,a5,80003a6e <fsinit+0x70>
  initlog(dev, &sb);
    80003a4e:	00023597          	auipc	a1,0x23
    80003a52:	7da58593          	addi	a1,a1,2010 # 80027228 <sb>
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	b40080e7          	jalr	-1216(ra) # 80004598 <initlog>
}
    80003a60:	70a2                	ld	ra,40(sp)
    80003a62:	7402                	ld	s0,32(sp)
    80003a64:	64e2                	ld	s1,24(sp)
    80003a66:	6942                	ld	s2,16(sp)
    80003a68:	69a2                	ld	s3,8(sp)
    80003a6a:	6145                	addi	sp,sp,48
    80003a6c:	8082                	ret
    panic("invalid file system");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	cb250513          	addi	a0,a0,-846 # 80008720 <syscalls+0x168>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ace080e7          	jalr	-1330(ra) # 80000544 <panic>

0000000080003a7e <iinit>:
{
    80003a7e:	7179                	addi	sp,sp,-48
    80003a80:	f406                	sd	ra,40(sp)
    80003a82:	f022                	sd	s0,32(sp)
    80003a84:	ec26                	sd	s1,24(sp)
    80003a86:	e84a                	sd	s2,16(sp)
    80003a88:	e44e                	sd	s3,8(sp)
    80003a8a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a8c:	00005597          	auipc	a1,0x5
    80003a90:	cac58593          	addi	a1,a1,-852 # 80008738 <syscalls+0x180>
    80003a94:	00023517          	auipc	a0,0x23
    80003a98:	7b450513          	addi	a0,a0,1972 # 80027248 <itable>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	1b2080e7          	jalr	434(ra) # 80000c4e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003aa4:	00023497          	auipc	s1,0x23
    80003aa8:	7cc48493          	addi	s1,s1,1996 # 80027270 <itable+0x28>
    80003aac:	00025997          	auipc	s3,0x25
    80003ab0:	25498993          	addi	s3,s3,596 # 80028d00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ab4:	00005917          	auipc	s2,0x5
    80003ab8:	c8c90913          	addi	s2,s2,-884 # 80008740 <syscalls+0x188>
    80003abc:	85ca                	mv	a1,s2
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	e3a080e7          	jalr	-454(ra) # 800048fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ac8:	08848493          	addi	s1,s1,136
    80003acc:	ff3498e3          	bne	s1,s3,80003abc <iinit+0x3e>
}
    80003ad0:	70a2                	ld	ra,40(sp)
    80003ad2:	7402                	ld	s0,32(sp)
    80003ad4:	64e2                	ld	s1,24(sp)
    80003ad6:	6942                	ld	s2,16(sp)
    80003ad8:	69a2                	ld	s3,8(sp)
    80003ada:	6145                	addi	sp,sp,48
    80003adc:	8082                	ret

0000000080003ade <ialloc>:
{
    80003ade:	715d                	addi	sp,sp,-80
    80003ae0:	e486                	sd	ra,72(sp)
    80003ae2:	e0a2                	sd	s0,64(sp)
    80003ae4:	fc26                	sd	s1,56(sp)
    80003ae6:	f84a                	sd	s2,48(sp)
    80003ae8:	f44e                	sd	s3,40(sp)
    80003aea:	f052                	sd	s4,32(sp)
    80003aec:	ec56                	sd	s5,24(sp)
    80003aee:	e85a                	sd	s6,16(sp)
    80003af0:	e45e                	sd	s7,8(sp)
    80003af2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003af4:	00023717          	auipc	a4,0x23
    80003af8:	74072703          	lw	a4,1856(a4) # 80027234 <sb+0xc>
    80003afc:	4785                	li	a5,1
    80003afe:	04e7fa63          	bgeu	a5,a4,80003b52 <ialloc+0x74>
    80003b02:	8aaa                	mv	s5,a0
    80003b04:	8bae                	mv	s7,a1
    80003b06:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b08:	00023a17          	auipc	s4,0x23
    80003b0c:	720a0a13          	addi	s4,s4,1824 # 80027228 <sb>
    80003b10:	00048b1b          	sext.w	s6,s1
    80003b14:	0044d593          	srli	a1,s1,0x4
    80003b18:	018a2783          	lw	a5,24(s4)
    80003b1c:	9dbd                	addw	a1,a1,a5
    80003b1e:	8556                	mv	a0,s5
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	940080e7          	jalr	-1728(ra) # 80003460 <bread>
    80003b28:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b2a:	05850993          	addi	s3,a0,88
    80003b2e:	00f4f793          	andi	a5,s1,15
    80003b32:	079a                	slli	a5,a5,0x6
    80003b34:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b36:	00099783          	lh	a5,0(s3)
    80003b3a:	c3a1                	beqz	a5,80003b7a <ialloc+0x9c>
    brelse(bp);
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	a54080e7          	jalr	-1452(ra) # 80003590 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b44:	0485                	addi	s1,s1,1
    80003b46:	00ca2703          	lw	a4,12(s4)
    80003b4a:	0004879b          	sext.w	a5,s1
    80003b4e:	fce7e1e3          	bltu	a5,a4,80003b10 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b52:	00005517          	auipc	a0,0x5
    80003b56:	bf650513          	addi	a0,a0,-1034 # 80008748 <syscalls+0x190>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	a46080e7          	jalr	-1466(ra) # 800005a0 <printf>
  return 0;
    80003b62:	4501                	li	a0,0
}
    80003b64:	60a6                	ld	ra,72(sp)
    80003b66:	6406                	ld	s0,64(sp)
    80003b68:	74e2                	ld	s1,56(sp)
    80003b6a:	7942                	ld	s2,48(sp)
    80003b6c:	79a2                	ld	s3,40(sp)
    80003b6e:	7a02                	ld	s4,32(sp)
    80003b70:	6ae2                	ld	s5,24(sp)
    80003b72:	6b42                	ld	s6,16(sp)
    80003b74:	6ba2                	ld	s7,8(sp)
    80003b76:	6161                	addi	sp,sp,80
    80003b78:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b7a:	04000613          	li	a2,64
    80003b7e:	4581                	li	a1,0
    80003b80:	854e                	mv	a0,s3
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	258080e7          	jalr	600(ra) # 80000dda <memset>
      dip->type = type;
    80003b8a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	c84080e7          	jalr	-892(ra) # 80004814 <log_write>
      brelse(bp);
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	9f6080e7          	jalr	-1546(ra) # 80003590 <brelse>
      return iget(dev, inum);
    80003ba2:	85da                	mv	a1,s6
    80003ba4:	8556                	mv	a0,s5
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	d9c080e7          	jalr	-612(ra) # 80003942 <iget>
    80003bae:	bf5d                	j	80003b64 <ialloc+0x86>

0000000080003bb0 <iupdate>:
{
    80003bb0:	1101                	addi	sp,sp,-32
    80003bb2:	ec06                	sd	ra,24(sp)
    80003bb4:	e822                	sd	s0,16(sp)
    80003bb6:	e426                	sd	s1,8(sp)
    80003bb8:	e04a                	sd	s2,0(sp)
    80003bba:	1000                	addi	s0,sp,32
    80003bbc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bbe:	415c                	lw	a5,4(a0)
    80003bc0:	0047d79b          	srliw	a5,a5,0x4
    80003bc4:	00023597          	auipc	a1,0x23
    80003bc8:	67c5a583          	lw	a1,1660(a1) # 80027240 <sb+0x18>
    80003bcc:	9dbd                	addw	a1,a1,a5
    80003bce:	4108                	lw	a0,0(a0)
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	890080e7          	jalr	-1904(ra) # 80003460 <bread>
    80003bd8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bda:	05850793          	addi	a5,a0,88
    80003bde:	40c8                	lw	a0,4(s1)
    80003be0:	893d                	andi	a0,a0,15
    80003be2:	051a                	slli	a0,a0,0x6
    80003be4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003be6:	04449703          	lh	a4,68(s1)
    80003bea:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bee:	04649703          	lh	a4,70(s1)
    80003bf2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bf6:	04849703          	lh	a4,72(s1)
    80003bfa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bfe:	04a49703          	lh	a4,74(s1)
    80003c02:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c06:	44f8                	lw	a4,76(s1)
    80003c08:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c0a:	03400613          	li	a2,52
    80003c0e:	05048593          	addi	a1,s1,80
    80003c12:	0531                	addi	a0,a0,12
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	226080e7          	jalr	550(ra) # 80000e3a <memmove>
  log_write(bp);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	bf6080e7          	jalr	-1034(ra) # 80004814 <log_write>
  brelse(bp);
    80003c26:	854a                	mv	a0,s2
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	968080e7          	jalr	-1688(ra) # 80003590 <brelse>
}
    80003c30:	60e2                	ld	ra,24(sp)
    80003c32:	6442                	ld	s0,16(sp)
    80003c34:	64a2                	ld	s1,8(sp)
    80003c36:	6902                	ld	s2,0(sp)
    80003c38:	6105                	addi	sp,sp,32
    80003c3a:	8082                	ret

0000000080003c3c <idup>:
{
    80003c3c:	1101                	addi	sp,sp,-32
    80003c3e:	ec06                	sd	ra,24(sp)
    80003c40:	e822                	sd	s0,16(sp)
    80003c42:	e426                	sd	s1,8(sp)
    80003c44:	1000                	addi	s0,sp,32
    80003c46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c48:	00023517          	auipc	a0,0x23
    80003c4c:	60050513          	addi	a0,a0,1536 # 80027248 <itable>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	08e080e7          	jalr	142(ra) # 80000cde <acquire>
  ip->ref++;
    80003c58:	449c                	lw	a5,8(s1)
    80003c5a:	2785                	addiw	a5,a5,1
    80003c5c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c5e:	00023517          	auipc	a0,0x23
    80003c62:	5ea50513          	addi	a0,a0,1514 # 80027248 <itable>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	12c080e7          	jalr	300(ra) # 80000d92 <release>
}
    80003c6e:	8526                	mv	a0,s1
    80003c70:	60e2                	ld	ra,24(sp)
    80003c72:	6442                	ld	s0,16(sp)
    80003c74:	64a2                	ld	s1,8(sp)
    80003c76:	6105                	addi	sp,sp,32
    80003c78:	8082                	ret

0000000080003c7a <ilock>:
{
    80003c7a:	1101                	addi	sp,sp,-32
    80003c7c:	ec06                	sd	ra,24(sp)
    80003c7e:	e822                	sd	s0,16(sp)
    80003c80:	e426                	sd	s1,8(sp)
    80003c82:	e04a                	sd	s2,0(sp)
    80003c84:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c86:	c115                	beqz	a0,80003caa <ilock+0x30>
    80003c88:	84aa                	mv	s1,a0
    80003c8a:	451c                	lw	a5,8(a0)
    80003c8c:	00f05f63          	blez	a5,80003caa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c90:	0541                	addi	a0,a0,16
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	ca2080e7          	jalr	-862(ra) # 80004934 <acquiresleep>
  if(ip->valid == 0){
    80003c9a:	40bc                	lw	a5,64(s1)
    80003c9c:	cf99                	beqz	a5,80003cba <ilock+0x40>
}
    80003c9e:	60e2                	ld	ra,24(sp)
    80003ca0:	6442                	ld	s0,16(sp)
    80003ca2:	64a2                	ld	s1,8(sp)
    80003ca4:	6902                	ld	s2,0(sp)
    80003ca6:	6105                	addi	sp,sp,32
    80003ca8:	8082                	ret
    panic("ilock");
    80003caa:	00005517          	auipc	a0,0x5
    80003cae:	ab650513          	addi	a0,a0,-1354 # 80008760 <syscalls+0x1a8>
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	892080e7          	jalr	-1902(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cba:	40dc                	lw	a5,4(s1)
    80003cbc:	0047d79b          	srliw	a5,a5,0x4
    80003cc0:	00023597          	auipc	a1,0x23
    80003cc4:	5805a583          	lw	a1,1408(a1) # 80027240 <sb+0x18>
    80003cc8:	9dbd                	addw	a1,a1,a5
    80003cca:	4088                	lw	a0,0(s1)
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	794080e7          	jalr	1940(ra) # 80003460 <bread>
    80003cd4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cd6:	05850593          	addi	a1,a0,88
    80003cda:	40dc                	lw	a5,4(s1)
    80003cdc:	8bbd                	andi	a5,a5,15
    80003cde:	079a                	slli	a5,a5,0x6
    80003ce0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ce2:	00059783          	lh	a5,0(a1)
    80003ce6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cea:	00259783          	lh	a5,2(a1)
    80003cee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cf2:	00459783          	lh	a5,4(a1)
    80003cf6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cfa:	00659783          	lh	a5,6(a1)
    80003cfe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d02:	459c                	lw	a5,8(a1)
    80003d04:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d06:	03400613          	li	a2,52
    80003d0a:	05b1                	addi	a1,a1,12
    80003d0c:	05048513          	addi	a0,s1,80
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	12a080e7          	jalr	298(ra) # 80000e3a <memmove>
    brelse(bp);
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	876080e7          	jalr	-1930(ra) # 80003590 <brelse>
    ip->valid = 1;
    80003d22:	4785                	li	a5,1
    80003d24:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d26:	04449783          	lh	a5,68(s1)
    80003d2a:	fbb5                	bnez	a5,80003c9e <ilock+0x24>
      panic("ilock: no type");
    80003d2c:	00005517          	auipc	a0,0x5
    80003d30:	a3c50513          	addi	a0,a0,-1476 # 80008768 <syscalls+0x1b0>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	810080e7          	jalr	-2032(ra) # 80000544 <panic>

0000000080003d3c <iunlock>:
{
    80003d3c:	1101                	addi	sp,sp,-32
    80003d3e:	ec06                	sd	ra,24(sp)
    80003d40:	e822                	sd	s0,16(sp)
    80003d42:	e426                	sd	s1,8(sp)
    80003d44:	e04a                	sd	s2,0(sp)
    80003d46:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d48:	c905                	beqz	a0,80003d78 <iunlock+0x3c>
    80003d4a:	84aa                	mv	s1,a0
    80003d4c:	01050913          	addi	s2,a0,16
    80003d50:	854a                	mv	a0,s2
    80003d52:	00001097          	auipc	ra,0x1
    80003d56:	c7c080e7          	jalr	-900(ra) # 800049ce <holdingsleep>
    80003d5a:	cd19                	beqz	a0,80003d78 <iunlock+0x3c>
    80003d5c:	449c                	lw	a5,8(s1)
    80003d5e:	00f05d63          	blez	a5,80003d78 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d62:	854a                	mv	a0,s2
    80003d64:	00001097          	auipc	ra,0x1
    80003d68:	c26080e7          	jalr	-986(ra) # 8000498a <releasesleep>
}
    80003d6c:	60e2                	ld	ra,24(sp)
    80003d6e:	6442                	ld	s0,16(sp)
    80003d70:	64a2                	ld	s1,8(sp)
    80003d72:	6902                	ld	s2,0(sp)
    80003d74:	6105                	addi	sp,sp,32
    80003d76:	8082                	ret
    panic("iunlock");
    80003d78:	00005517          	auipc	a0,0x5
    80003d7c:	a0050513          	addi	a0,a0,-1536 # 80008778 <syscalls+0x1c0>
    80003d80:	ffffc097          	auipc	ra,0xffffc
    80003d84:	7c4080e7          	jalr	1988(ra) # 80000544 <panic>

0000000080003d88 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d88:	7179                	addi	sp,sp,-48
    80003d8a:	f406                	sd	ra,40(sp)
    80003d8c:	f022                	sd	s0,32(sp)
    80003d8e:	ec26                	sd	s1,24(sp)
    80003d90:	e84a                	sd	s2,16(sp)
    80003d92:	e44e                	sd	s3,8(sp)
    80003d94:	e052                	sd	s4,0(sp)
    80003d96:	1800                	addi	s0,sp,48
    80003d98:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d9a:	05050493          	addi	s1,a0,80
    80003d9e:	08050913          	addi	s2,a0,128
    80003da2:	a021                	j	80003daa <itrunc+0x22>
    80003da4:	0491                	addi	s1,s1,4
    80003da6:	01248d63          	beq	s1,s2,80003dc0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003daa:	408c                	lw	a1,0(s1)
    80003dac:	dde5                	beqz	a1,80003da4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dae:	0009a503          	lw	a0,0(s3)
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	8f4080e7          	jalr	-1804(ra) # 800036a6 <bfree>
      ip->addrs[i] = 0;
    80003dba:	0004a023          	sw	zero,0(s1)
    80003dbe:	b7dd                	j	80003da4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dc0:	0809a583          	lw	a1,128(s3)
    80003dc4:	e185                	bnez	a1,80003de4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dc6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	de4080e7          	jalr	-540(ra) # 80003bb0 <iupdate>
}
    80003dd4:	70a2                	ld	ra,40(sp)
    80003dd6:	7402                	ld	s0,32(sp)
    80003dd8:	64e2                	ld	s1,24(sp)
    80003dda:	6942                	ld	s2,16(sp)
    80003ddc:	69a2                	ld	s3,8(sp)
    80003dde:	6a02                	ld	s4,0(sp)
    80003de0:	6145                	addi	sp,sp,48
    80003de2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003de4:	0009a503          	lw	a0,0(s3)
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	678080e7          	jalr	1656(ra) # 80003460 <bread>
    80003df0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003df2:	05850493          	addi	s1,a0,88
    80003df6:	45850913          	addi	s2,a0,1112
    80003dfa:	a811                	j	80003e0e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003dfc:	0009a503          	lw	a0,0(s3)
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	8a6080e7          	jalr	-1882(ra) # 800036a6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e08:	0491                	addi	s1,s1,4
    80003e0a:	01248563          	beq	s1,s2,80003e14 <itrunc+0x8c>
      if(a[j])
    80003e0e:	408c                	lw	a1,0(s1)
    80003e10:	dde5                	beqz	a1,80003e08 <itrunc+0x80>
    80003e12:	b7ed                	j	80003dfc <itrunc+0x74>
    brelse(bp);
    80003e14:	8552                	mv	a0,s4
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	77a080e7          	jalr	1914(ra) # 80003590 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e1e:	0809a583          	lw	a1,128(s3)
    80003e22:	0009a503          	lw	a0,0(s3)
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	880080e7          	jalr	-1920(ra) # 800036a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e2e:	0809a023          	sw	zero,128(s3)
    80003e32:	bf51                	j	80003dc6 <itrunc+0x3e>

0000000080003e34 <iput>:
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	e426                	sd	s1,8(sp)
    80003e3c:	e04a                	sd	s2,0(sp)
    80003e3e:	1000                	addi	s0,sp,32
    80003e40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e42:	00023517          	auipc	a0,0x23
    80003e46:	40650513          	addi	a0,a0,1030 # 80027248 <itable>
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	e94080e7          	jalr	-364(ra) # 80000cde <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e52:	4498                	lw	a4,8(s1)
    80003e54:	4785                	li	a5,1
    80003e56:	02f70363          	beq	a4,a5,80003e7c <iput+0x48>
  ip->ref--;
    80003e5a:	449c                	lw	a5,8(s1)
    80003e5c:	37fd                	addiw	a5,a5,-1
    80003e5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e60:	00023517          	auipc	a0,0x23
    80003e64:	3e850513          	addi	a0,a0,1000 # 80027248 <itable>
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	f2a080e7          	jalr	-214(ra) # 80000d92 <release>
}
    80003e70:	60e2                	ld	ra,24(sp)
    80003e72:	6442                	ld	s0,16(sp)
    80003e74:	64a2                	ld	s1,8(sp)
    80003e76:	6902                	ld	s2,0(sp)
    80003e78:	6105                	addi	sp,sp,32
    80003e7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e7c:	40bc                	lw	a5,64(s1)
    80003e7e:	dff1                	beqz	a5,80003e5a <iput+0x26>
    80003e80:	04a49783          	lh	a5,74(s1)
    80003e84:	fbf9                	bnez	a5,80003e5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e86:	01048913          	addi	s2,s1,16
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00001097          	auipc	ra,0x1
    80003e90:	aa8080e7          	jalr	-1368(ra) # 80004934 <acquiresleep>
    release(&itable.lock);
    80003e94:	00023517          	auipc	a0,0x23
    80003e98:	3b450513          	addi	a0,a0,948 # 80027248 <itable>
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	ef6080e7          	jalr	-266(ra) # 80000d92 <release>
    itrunc(ip);
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	ee2080e7          	jalr	-286(ra) # 80003d88 <itrunc>
    ip->type = 0;
    80003eae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	cfc080e7          	jalr	-772(ra) # 80003bb0 <iupdate>
    ip->valid = 0;
    80003ebc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00001097          	auipc	ra,0x1
    80003ec6:	ac8080e7          	jalr	-1336(ra) # 8000498a <releasesleep>
    acquire(&itable.lock);
    80003eca:	00023517          	auipc	a0,0x23
    80003ece:	37e50513          	addi	a0,a0,894 # 80027248 <itable>
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	e0c080e7          	jalr	-500(ra) # 80000cde <acquire>
    80003eda:	b741                	j	80003e5a <iput+0x26>

0000000080003edc <iunlockput>:
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	e426                	sd	s1,8(sp)
    80003ee4:	1000                	addi	s0,sp,32
    80003ee6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	e54080e7          	jalr	-428(ra) # 80003d3c <iunlock>
  iput(ip);
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	f42080e7          	jalr	-190(ra) # 80003e34 <iput>
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6105                	addi	sp,sp,32
    80003f02:	8082                	ret

0000000080003f04 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f04:	1141                	addi	sp,sp,-16
    80003f06:	e422                	sd	s0,8(sp)
    80003f08:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f0a:	411c                	lw	a5,0(a0)
    80003f0c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f0e:	415c                	lw	a5,4(a0)
    80003f10:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f12:	04451783          	lh	a5,68(a0)
    80003f16:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f1a:	04a51783          	lh	a5,74(a0)
    80003f1e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f22:	04c56783          	lwu	a5,76(a0)
    80003f26:	e99c                	sd	a5,16(a1)
}
    80003f28:	6422                	ld	s0,8(sp)
    80003f2a:	0141                	addi	sp,sp,16
    80003f2c:	8082                	ret

0000000080003f2e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f2e:	457c                	lw	a5,76(a0)
    80003f30:	0ed7e963          	bltu	a5,a3,80004022 <readi+0xf4>
{
    80003f34:	7159                	addi	sp,sp,-112
    80003f36:	f486                	sd	ra,104(sp)
    80003f38:	f0a2                	sd	s0,96(sp)
    80003f3a:	eca6                	sd	s1,88(sp)
    80003f3c:	e8ca                	sd	s2,80(sp)
    80003f3e:	e4ce                	sd	s3,72(sp)
    80003f40:	e0d2                	sd	s4,64(sp)
    80003f42:	fc56                	sd	s5,56(sp)
    80003f44:	f85a                	sd	s6,48(sp)
    80003f46:	f45e                	sd	s7,40(sp)
    80003f48:	f062                	sd	s8,32(sp)
    80003f4a:	ec66                	sd	s9,24(sp)
    80003f4c:	e86a                	sd	s10,16(sp)
    80003f4e:	e46e                	sd	s11,8(sp)
    80003f50:	1880                	addi	s0,sp,112
    80003f52:	8b2a                	mv	s6,a0
    80003f54:	8bae                	mv	s7,a1
    80003f56:	8a32                	mv	s4,a2
    80003f58:	84b6                	mv	s1,a3
    80003f5a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f5c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f5e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f60:	0ad76063          	bltu	a4,a3,80004000 <readi+0xd2>
  if(off + n > ip->size)
    80003f64:	00e7f463          	bgeu	a5,a4,80003f6c <readi+0x3e>
    n = ip->size - off;
    80003f68:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f6c:	0a0a8963          	beqz	s5,8000401e <readi+0xf0>
    80003f70:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f72:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f76:	5c7d                	li	s8,-1
    80003f78:	a82d                	j	80003fb2 <readi+0x84>
    80003f7a:	020d1d93          	slli	s11,s10,0x20
    80003f7e:	020ddd93          	srli	s11,s11,0x20
    80003f82:	05890613          	addi	a2,s2,88
    80003f86:	86ee                	mv	a3,s11
    80003f88:	963a                	add	a2,a2,a4
    80003f8a:	85d2                	mv	a1,s4
    80003f8c:	855e                	mv	a0,s7
    80003f8e:	ffffe097          	auipc	ra,0xffffe
    80003f92:	7d8080e7          	jalr	2008(ra) # 80002766 <either_copyout>
    80003f96:	05850d63          	beq	a0,s8,80003ff0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	5f4080e7          	jalr	1524(ra) # 80003590 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa4:	013d09bb          	addw	s3,s10,s3
    80003fa8:	009d04bb          	addw	s1,s10,s1
    80003fac:	9a6e                	add	s4,s4,s11
    80003fae:	0559f763          	bgeu	s3,s5,80003ffc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fb2:	00a4d59b          	srliw	a1,s1,0xa
    80003fb6:	855a                	mv	a0,s6
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	8a2080e7          	jalr	-1886(ra) # 8000385a <bmap>
    80003fc0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fc4:	cd85                	beqz	a1,80003ffc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fc6:	000b2503          	lw	a0,0(s6)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	496080e7          	jalr	1174(ra) # 80003460 <bread>
    80003fd2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd4:	3ff4f713          	andi	a4,s1,1023
    80003fd8:	40ec87bb          	subw	a5,s9,a4
    80003fdc:	413a86bb          	subw	a3,s5,s3
    80003fe0:	8d3e                	mv	s10,a5
    80003fe2:	2781                	sext.w	a5,a5
    80003fe4:	0006861b          	sext.w	a2,a3
    80003fe8:	f8f679e3          	bgeu	a2,a5,80003f7a <readi+0x4c>
    80003fec:	8d36                	mv	s10,a3
    80003fee:	b771                	j	80003f7a <readi+0x4c>
      brelse(bp);
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	59e080e7          	jalr	1438(ra) # 80003590 <brelse>
      tot = -1;
    80003ffa:	59fd                	li	s3,-1
  }
  return tot;
    80003ffc:	0009851b          	sext.w	a0,s3
}
    80004000:	70a6                	ld	ra,104(sp)
    80004002:	7406                	ld	s0,96(sp)
    80004004:	64e6                	ld	s1,88(sp)
    80004006:	6946                	ld	s2,80(sp)
    80004008:	69a6                	ld	s3,72(sp)
    8000400a:	6a06                	ld	s4,64(sp)
    8000400c:	7ae2                	ld	s5,56(sp)
    8000400e:	7b42                	ld	s6,48(sp)
    80004010:	7ba2                	ld	s7,40(sp)
    80004012:	7c02                	ld	s8,32(sp)
    80004014:	6ce2                	ld	s9,24(sp)
    80004016:	6d42                	ld	s10,16(sp)
    80004018:	6da2                	ld	s11,8(sp)
    8000401a:	6165                	addi	sp,sp,112
    8000401c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000401e:	89d6                	mv	s3,s5
    80004020:	bff1                	j	80003ffc <readi+0xce>
    return 0;
    80004022:	4501                	li	a0,0
}
    80004024:	8082                	ret

0000000080004026 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004026:	457c                	lw	a5,76(a0)
    80004028:	10d7e863          	bltu	a5,a3,80004138 <writei+0x112>
{
    8000402c:	7159                	addi	sp,sp,-112
    8000402e:	f486                	sd	ra,104(sp)
    80004030:	f0a2                	sd	s0,96(sp)
    80004032:	eca6                	sd	s1,88(sp)
    80004034:	e8ca                	sd	s2,80(sp)
    80004036:	e4ce                	sd	s3,72(sp)
    80004038:	e0d2                	sd	s4,64(sp)
    8000403a:	fc56                	sd	s5,56(sp)
    8000403c:	f85a                	sd	s6,48(sp)
    8000403e:	f45e                	sd	s7,40(sp)
    80004040:	f062                	sd	s8,32(sp)
    80004042:	ec66                	sd	s9,24(sp)
    80004044:	e86a                	sd	s10,16(sp)
    80004046:	e46e                	sd	s11,8(sp)
    80004048:	1880                	addi	s0,sp,112
    8000404a:	8aaa                	mv	s5,a0
    8000404c:	8bae                	mv	s7,a1
    8000404e:	8a32                	mv	s4,a2
    80004050:	8936                	mv	s2,a3
    80004052:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004054:	00e687bb          	addw	a5,a3,a4
    80004058:	0ed7e263          	bltu	a5,a3,8000413c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000405c:	00043737          	lui	a4,0x43
    80004060:	0ef76063          	bltu	a4,a5,80004140 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004064:	0c0b0863          	beqz	s6,80004134 <writei+0x10e>
    80004068:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000406e:	5c7d                	li	s8,-1
    80004070:	a091                	j	800040b4 <writei+0x8e>
    80004072:	020d1d93          	slli	s11,s10,0x20
    80004076:	020ddd93          	srli	s11,s11,0x20
    8000407a:	05848513          	addi	a0,s1,88
    8000407e:	86ee                	mv	a3,s11
    80004080:	8652                	mv	a2,s4
    80004082:	85de                	mv	a1,s7
    80004084:	953a                	add	a0,a0,a4
    80004086:	ffffe097          	auipc	ra,0xffffe
    8000408a:	736080e7          	jalr	1846(ra) # 800027bc <either_copyin>
    8000408e:	07850263          	beq	a0,s8,800040f2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004092:	8526                	mv	a0,s1
    80004094:	00000097          	auipc	ra,0x0
    80004098:	780080e7          	jalr	1920(ra) # 80004814 <log_write>
    brelse(bp);
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	4f2080e7          	jalr	1266(ra) # 80003590 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040a6:	013d09bb          	addw	s3,s10,s3
    800040aa:	012d093b          	addw	s2,s10,s2
    800040ae:	9a6e                	add	s4,s4,s11
    800040b0:	0569f663          	bgeu	s3,s6,800040fc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040b4:	00a9559b          	srliw	a1,s2,0xa
    800040b8:	8556                	mv	a0,s5
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	7a0080e7          	jalr	1952(ra) # 8000385a <bmap>
    800040c2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040c6:	c99d                	beqz	a1,800040fc <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040c8:	000aa503          	lw	a0,0(s5)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	394080e7          	jalr	916(ra) # 80003460 <bread>
    800040d4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d6:	3ff97713          	andi	a4,s2,1023
    800040da:	40ec87bb          	subw	a5,s9,a4
    800040de:	413b06bb          	subw	a3,s6,s3
    800040e2:	8d3e                	mv	s10,a5
    800040e4:	2781                	sext.w	a5,a5
    800040e6:	0006861b          	sext.w	a2,a3
    800040ea:	f8f674e3          	bgeu	a2,a5,80004072 <writei+0x4c>
    800040ee:	8d36                	mv	s10,a3
    800040f0:	b749                	j	80004072 <writei+0x4c>
      brelse(bp);
    800040f2:	8526                	mv	a0,s1
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	49c080e7          	jalr	1180(ra) # 80003590 <brelse>
  }

  if(off > ip->size)
    800040fc:	04caa783          	lw	a5,76(s5)
    80004100:	0127f463          	bgeu	a5,s2,80004108 <writei+0xe2>
    ip->size = off;
    80004104:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004108:	8556                	mv	a0,s5
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	aa6080e7          	jalr	-1370(ra) # 80003bb0 <iupdate>

  return tot;
    80004112:	0009851b          	sext.w	a0,s3
}
    80004116:	70a6                	ld	ra,104(sp)
    80004118:	7406                	ld	s0,96(sp)
    8000411a:	64e6                	ld	s1,88(sp)
    8000411c:	6946                	ld	s2,80(sp)
    8000411e:	69a6                	ld	s3,72(sp)
    80004120:	6a06                	ld	s4,64(sp)
    80004122:	7ae2                	ld	s5,56(sp)
    80004124:	7b42                	ld	s6,48(sp)
    80004126:	7ba2                	ld	s7,40(sp)
    80004128:	7c02                	ld	s8,32(sp)
    8000412a:	6ce2                	ld	s9,24(sp)
    8000412c:	6d42                	ld	s10,16(sp)
    8000412e:	6da2                	ld	s11,8(sp)
    80004130:	6165                	addi	sp,sp,112
    80004132:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004134:	89da                	mv	s3,s6
    80004136:	bfc9                	j	80004108 <writei+0xe2>
    return -1;
    80004138:	557d                	li	a0,-1
}
    8000413a:	8082                	ret
    return -1;
    8000413c:	557d                	li	a0,-1
    8000413e:	bfe1                	j	80004116 <writei+0xf0>
    return -1;
    80004140:	557d                	li	a0,-1
    80004142:	bfd1                	j	80004116 <writei+0xf0>

0000000080004144 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004144:	1141                	addi	sp,sp,-16
    80004146:	e406                	sd	ra,8(sp)
    80004148:	e022                	sd	s0,0(sp)
    8000414a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000414c:	4639                	li	a2,14
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	d64080e7          	jalr	-668(ra) # 80000eb2 <strncmp>
}
    80004156:	60a2                	ld	ra,8(sp)
    80004158:	6402                	ld	s0,0(sp)
    8000415a:	0141                	addi	sp,sp,16
    8000415c:	8082                	ret

000000008000415e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000415e:	7139                	addi	sp,sp,-64
    80004160:	fc06                	sd	ra,56(sp)
    80004162:	f822                	sd	s0,48(sp)
    80004164:	f426                	sd	s1,40(sp)
    80004166:	f04a                	sd	s2,32(sp)
    80004168:	ec4e                	sd	s3,24(sp)
    8000416a:	e852                	sd	s4,16(sp)
    8000416c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000416e:	04451703          	lh	a4,68(a0)
    80004172:	4785                	li	a5,1
    80004174:	00f71a63          	bne	a4,a5,80004188 <dirlookup+0x2a>
    80004178:	892a                	mv	s2,a0
    8000417a:	89ae                	mv	s3,a1
    8000417c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000417e:	457c                	lw	a5,76(a0)
    80004180:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004182:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004184:	e79d                	bnez	a5,800041b2 <dirlookup+0x54>
    80004186:	a8a5                	j	800041fe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004188:	00004517          	auipc	a0,0x4
    8000418c:	5f850513          	addi	a0,a0,1528 # 80008780 <syscalls+0x1c8>
    80004190:	ffffc097          	auipc	ra,0xffffc
    80004194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004198:	00004517          	auipc	a0,0x4
    8000419c:	60050513          	addi	a0,a0,1536 # 80008798 <syscalls+0x1e0>
    800041a0:	ffffc097          	auipc	ra,0xffffc
    800041a4:	3a4080e7          	jalr	932(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a8:	24c1                	addiw	s1,s1,16
    800041aa:	04c92783          	lw	a5,76(s2)
    800041ae:	04f4f763          	bgeu	s1,a5,800041fc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041b2:	4741                	li	a4,16
    800041b4:	86a6                	mv	a3,s1
    800041b6:	fc040613          	addi	a2,s0,-64
    800041ba:	4581                	li	a1,0
    800041bc:	854a                	mv	a0,s2
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	d70080e7          	jalr	-656(ra) # 80003f2e <readi>
    800041c6:	47c1                	li	a5,16
    800041c8:	fcf518e3          	bne	a0,a5,80004198 <dirlookup+0x3a>
    if(de.inum == 0)
    800041cc:	fc045783          	lhu	a5,-64(s0)
    800041d0:	dfe1                	beqz	a5,800041a8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041d2:	fc240593          	addi	a1,s0,-62
    800041d6:	854e                	mv	a0,s3
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	f6c080e7          	jalr	-148(ra) # 80004144 <namecmp>
    800041e0:	f561                	bnez	a0,800041a8 <dirlookup+0x4a>
      if(poff)
    800041e2:	000a0463          	beqz	s4,800041ea <dirlookup+0x8c>
        *poff = off;
    800041e6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ea:	fc045583          	lhu	a1,-64(s0)
    800041ee:	00092503          	lw	a0,0(s2)
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	750080e7          	jalr	1872(ra) # 80003942 <iget>
    800041fa:	a011                	j	800041fe <dirlookup+0xa0>
  return 0;
    800041fc:	4501                	li	a0,0
}
    800041fe:	70e2                	ld	ra,56(sp)
    80004200:	7442                	ld	s0,48(sp)
    80004202:	74a2                	ld	s1,40(sp)
    80004204:	7902                	ld	s2,32(sp)
    80004206:	69e2                	ld	s3,24(sp)
    80004208:	6a42                	ld	s4,16(sp)
    8000420a:	6121                	addi	sp,sp,64
    8000420c:	8082                	ret

000000008000420e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000420e:	711d                	addi	sp,sp,-96
    80004210:	ec86                	sd	ra,88(sp)
    80004212:	e8a2                	sd	s0,80(sp)
    80004214:	e4a6                	sd	s1,72(sp)
    80004216:	e0ca                	sd	s2,64(sp)
    80004218:	fc4e                	sd	s3,56(sp)
    8000421a:	f852                	sd	s4,48(sp)
    8000421c:	f456                	sd	s5,40(sp)
    8000421e:	f05a                	sd	s6,32(sp)
    80004220:	ec5e                	sd	s7,24(sp)
    80004222:	e862                	sd	s8,16(sp)
    80004224:	e466                	sd	s9,8(sp)
    80004226:	1080                	addi	s0,sp,96
    80004228:	84aa                	mv	s1,a0
    8000422a:	8b2e                	mv	s6,a1
    8000422c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000422e:	00054703          	lbu	a4,0(a0)
    80004232:	02f00793          	li	a5,47
    80004236:	02f70363          	beq	a4,a5,8000425c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	9c0080e7          	jalr	-1600(ra) # 80001bfa <myproc>
    80004242:	15053503          	ld	a0,336(a0)
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	9f6080e7          	jalr	-1546(ra) # 80003c3c <idup>
    8000424e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004250:	02f00913          	li	s2,47
  len = path - s;
    80004254:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004256:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004258:	4c05                	li	s8,1
    8000425a:	a865                	j	80004312 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000425c:	4585                	li	a1,1
    8000425e:	4505                	li	a0,1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	6e2080e7          	jalr	1762(ra) # 80003942 <iget>
    80004268:	89aa                	mv	s3,a0
    8000426a:	b7dd                	j	80004250 <namex+0x42>
      iunlockput(ip);
    8000426c:	854e                	mv	a0,s3
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	c6e080e7          	jalr	-914(ra) # 80003edc <iunlockput>
      return 0;
    80004276:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004278:	854e                	mv	a0,s3
    8000427a:	60e6                	ld	ra,88(sp)
    8000427c:	6446                	ld	s0,80(sp)
    8000427e:	64a6                	ld	s1,72(sp)
    80004280:	6906                	ld	s2,64(sp)
    80004282:	79e2                	ld	s3,56(sp)
    80004284:	7a42                	ld	s4,48(sp)
    80004286:	7aa2                	ld	s5,40(sp)
    80004288:	7b02                	ld	s6,32(sp)
    8000428a:	6be2                	ld	s7,24(sp)
    8000428c:	6c42                	ld	s8,16(sp)
    8000428e:	6ca2                	ld	s9,8(sp)
    80004290:	6125                	addi	sp,sp,96
    80004292:	8082                	ret
      iunlock(ip);
    80004294:	854e                	mv	a0,s3
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	aa6080e7          	jalr	-1370(ra) # 80003d3c <iunlock>
      return ip;
    8000429e:	bfe9                	j	80004278 <namex+0x6a>
      iunlockput(ip);
    800042a0:	854e                	mv	a0,s3
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	c3a080e7          	jalr	-966(ra) # 80003edc <iunlockput>
      return 0;
    800042aa:	89d2                	mv	s3,s4
    800042ac:	b7f1                	j	80004278 <namex+0x6a>
  len = path - s;
    800042ae:	40b48633          	sub	a2,s1,a1
    800042b2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042b6:	094cd463          	bge	s9,s4,8000433e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042ba:	4639                	li	a2,14
    800042bc:	8556                	mv	a0,s5
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	b7c080e7          	jalr	-1156(ra) # 80000e3a <memmove>
  while(*path == '/')
    800042c6:	0004c783          	lbu	a5,0(s1)
    800042ca:	01279763          	bne	a5,s2,800042d8 <namex+0xca>
    path++;
    800042ce:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042d0:	0004c783          	lbu	a5,0(s1)
    800042d4:	ff278de3          	beq	a5,s2,800042ce <namex+0xc0>
    ilock(ip);
    800042d8:	854e                	mv	a0,s3
    800042da:	00000097          	auipc	ra,0x0
    800042de:	9a0080e7          	jalr	-1632(ra) # 80003c7a <ilock>
    if(ip->type != T_DIR){
    800042e2:	04499783          	lh	a5,68(s3)
    800042e6:	f98793e3          	bne	a5,s8,8000426c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ea:	000b0563          	beqz	s6,800042f4 <namex+0xe6>
    800042ee:	0004c783          	lbu	a5,0(s1)
    800042f2:	d3cd                	beqz	a5,80004294 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042f4:	865e                	mv	a2,s7
    800042f6:	85d6                	mv	a1,s5
    800042f8:	854e                	mv	a0,s3
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	e64080e7          	jalr	-412(ra) # 8000415e <dirlookup>
    80004302:	8a2a                	mv	s4,a0
    80004304:	dd51                	beqz	a0,800042a0 <namex+0x92>
    iunlockput(ip);
    80004306:	854e                	mv	a0,s3
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	bd4080e7          	jalr	-1068(ra) # 80003edc <iunlockput>
    ip = next;
    80004310:	89d2                	mv	s3,s4
  while(*path == '/')
    80004312:	0004c783          	lbu	a5,0(s1)
    80004316:	05279763          	bne	a5,s2,80004364 <namex+0x156>
    path++;
    8000431a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000431c:	0004c783          	lbu	a5,0(s1)
    80004320:	ff278de3          	beq	a5,s2,8000431a <namex+0x10c>
  if(*path == 0)
    80004324:	c79d                	beqz	a5,80004352 <namex+0x144>
    path++;
    80004326:	85a6                	mv	a1,s1
  len = path - s;
    80004328:	8a5e                	mv	s4,s7
    8000432a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000432c:	01278963          	beq	a5,s2,8000433e <namex+0x130>
    80004330:	dfbd                	beqz	a5,800042ae <namex+0xa0>
    path++;
    80004332:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004334:	0004c783          	lbu	a5,0(s1)
    80004338:	ff279ce3          	bne	a5,s2,80004330 <namex+0x122>
    8000433c:	bf8d                	j	800042ae <namex+0xa0>
    memmove(name, s, len);
    8000433e:	2601                	sext.w	a2,a2
    80004340:	8556                	mv	a0,s5
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	af8080e7          	jalr	-1288(ra) # 80000e3a <memmove>
    name[len] = 0;
    8000434a:	9a56                	add	s4,s4,s5
    8000434c:	000a0023          	sb	zero,0(s4)
    80004350:	bf9d                	j	800042c6 <namex+0xb8>
  if(nameiparent){
    80004352:	f20b03e3          	beqz	s6,80004278 <namex+0x6a>
    iput(ip);
    80004356:	854e                	mv	a0,s3
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	adc080e7          	jalr	-1316(ra) # 80003e34 <iput>
    return 0;
    80004360:	4981                	li	s3,0
    80004362:	bf19                	j	80004278 <namex+0x6a>
  if(*path == 0)
    80004364:	d7fd                	beqz	a5,80004352 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	85a6                	mv	a1,s1
    8000436c:	b7d1                	j	80004330 <namex+0x122>

000000008000436e <dirlink>:
{
    8000436e:	7139                	addi	sp,sp,-64
    80004370:	fc06                	sd	ra,56(sp)
    80004372:	f822                	sd	s0,48(sp)
    80004374:	f426                	sd	s1,40(sp)
    80004376:	f04a                	sd	s2,32(sp)
    80004378:	ec4e                	sd	s3,24(sp)
    8000437a:	e852                	sd	s4,16(sp)
    8000437c:	0080                	addi	s0,sp,64
    8000437e:	892a                	mv	s2,a0
    80004380:	8a2e                	mv	s4,a1
    80004382:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004384:	4601                	li	a2,0
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	dd8080e7          	jalr	-552(ra) # 8000415e <dirlookup>
    8000438e:	e93d                	bnez	a0,80004404 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004390:	04c92483          	lw	s1,76(s2)
    80004394:	c49d                	beqz	s1,800043c2 <dirlink+0x54>
    80004396:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004398:	4741                	li	a4,16
    8000439a:	86a6                	mv	a3,s1
    8000439c:	fc040613          	addi	a2,s0,-64
    800043a0:	4581                	li	a1,0
    800043a2:	854a                	mv	a0,s2
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	b8a080e7          	jalr	-1142(ra) # 80003f2e <readi>
    800043ac:	47c1                	li	a5,16
    800043ae:	06f51163          	bne	a0,a5,80004410 <dirlink+0xa2>
    if(de.inum == 0)
    800043b2:	fc045783          	lhu	a5,-64(s0)
    800043b6:	c791                	beqz	a5,800043c2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b8:	24c1                	addiw	s1,s1,16
    800043ba:	04c92783          	lw	a5,76(s2)
    800043be:	fcf4ede3          	bltu	s1,a5,80004398 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043c2:	4639                	li	a2,14
    800043c4:	85d2                	mv	a1,s4
    800043c6:	fc240513          	addi	a0,s0,-62
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	b24080e7          	jalr	-1244(ra) # 80000eee <strncpy>
  de.inum = inum;
    800043d2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043d6:	4741                	li	a4,16
    800043d8:	86a6                	mv	a3,s1
    800043da:	fc040613          	addi	a2,s0,-64
    800043de:	4581                	li	a1,0
    800043e0:	854a                	mv	a0,s2
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	c44080e7          	jalr	-956(ra) # 80004026 <writei>
    800043ea:	1541                	addi	a0,a0,-16
    800043ec:	00a03533          	snez	a0,a0
    800043f0:	40a00533          	neg	a0,a0
}
    800043f4:	70e2                	ld	ra,56(sp)
    800043f6:	7442                	ld	s0,48(sp)
    800043f8:	74a2                	ld	s1,40(sp)
    800043fa:	7902                	ld	s2,32(sp)
    800043fc:	69e2                	ld	s3,24(sp)
    800043fe:	6a42                	ld	s4,16(sp)
    80004400:	6121                	addi	sp,sp,64
    80004402:	8082                	ret
    iput(ip);
    80004404:	00000097          	auipc	ra,0x0
    80004408:	a30080e7          	jalr	-1488(ra) # 80003e34 <iput>
    return -1;
    8000440c:	557d                	li	a0,-1
    8000440e:	b7dd                	j	800043f4 <dirlink+0x86>
      panic("dirlink read");
    80004410:	00004517          	auipc	a0,0x4
    80004414:	39850513          	addi	a0,a0,920 # 800087a8 <syscalls+0x1f0>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	12c080e7          	jalr	300(ra) # 80000544 <panic>

0000000080004420 <namei>:

struct inode*
namei(char *path)
{
    80004420:	1101                	addi	sp,sp,-32
    80004422:	ec06                	sd	ra,24(sp)
    80004424:	e822                	sd	s0,16(sp)
    80004426:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004428:	fe040613          	addi	a2,s0,-32
    8000442c:	4581                	li	a1,0
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	de0080e7          	jalr	-544(ra) # 8000420e <namex>
}
    80004436:	60e2                	ld	ra,24(sp)
    80004438:	6442                	ld	s0,16(sp)
    8000443a:	6105                	addi	sp,sp,32
    8000443c:	8082                	ret

000000008000443e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000443e:	1141                	addi	sp,sp,-16
    80004440:	e406                	sd	ra,8(sp)
    80004442:	e022                	sd	s0,0(sp)
    80004444:	0800                	addi	s0,sp,16
    80004446:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004448:	4585                	li	a1,1
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	dc4080e7          	jalr	-572(ra) # 8000420e <namex>
}
    80004452:	60a2                	ld	ra,8(sp)
    80004454:	6402                	ld	s0,0(sp)
    80004456:	0141                	addi	sp,sp,16
    80004458:	8082                	ret

000000008000445a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000445a:	1101                	addi	sp,sp,-32
    8000445c:	ec06                	sd	ra,24(sp)
    8000445e:	e822                	sd	s0,16(sp)
    80004460:	e426                	sd	s1,8(sp)
    80004462:	e04a                	sd	s2,0(sp)
    80004464:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004466:	00025917          	auipc	s2,0x25
    8000446a:	88a90913          	addi	s2,s2,-1910 # 80028cf0 <log>
    8000446e:	01892583          	lw	a1,24(s2)
    80004472:	02892503          	lw	a0,40(s2)
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	fea080e7          	jalr	-22(ra) # 80003460 <bread>
    8000447e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004480:	02c92683          	lw	a3,44(s2)
    80004484:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004486:	02d05763          	blez	a3,800044b4 <write_head+0x5a>
    8000448a:	00025797          	auipc	a5,0x25
    8000448e:	89678793          	addi	a5,a5,-1898 # 80028d20 <log+0x30>
    80004492:	05c50713          	addi	a4,a0,92
    80004496:	36fd                	addiw	a3,a3,-1
    80004498:	1682                	slli	a3,a3,0x20
    8000449a:	9281                	srli	a3,a3,0x20
    8000449c:	068a                	slli	a3,a3,0x2
    8000449e:	00025617          	auipc	a2,0x25
    800044a2:	88660613          	addi	a2,a2,-1914 # 80028d24 <log+0x34>
    800044a6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044a8:	4390                	lw	a2,0(a5)
    800044aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044ac:	0791                	addi	a5,a5,4
    800044ae:	0711                	addi	a4,a4,4
    800044b0:	fed79ce3          	bne	a5,a3,800044a8 <write_head+0x4e>
  }
  bwrite(buf);
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	09c080e7          	jalr	156(ra) # 80003552 <bwrite>
  brelse(buf);
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	0d0080e7          	jalr	208(ra) # 80003590 <brelse>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret

00000000800044d4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d4:	00025797          	auipc	a5,0x25
    800044d8:	8487a783          	lw	a5,-1976(a5) # 80028d1c <log+0x2c>
    800044dc:	0af05d63          	blez	a5,80004596 <install_trans+0xc2>
{
    800044e0:	7139                	addi	sp,sp,-64
    800044e2:	fc06                	sd	ra,56(sp)
    800044e4:	f822                	sd	s0,48(sp)
    800044e6:	f426                	sd	s1,40(sp)
    800044e8:	f04a                	sd	s2,32(sp)
    800044ea:	ec4e                	sd	s3,24(sp)
    800044ec:	e852                	sd	s4,16(sp)
    800044ee:	e456                	sd	s5,8(sp)
    800044f0:	e05a                	sd	s6,0(sp)
    800044f2:	0080                	addi	s0,sp,64
    800044f4:	8b2a                	mv	s6,a0
    800044f6:	00025a97          	auipc	s5,0x25
    800044fa:	82aa8a93          	addi	s5,s5,-2006 # 80028d20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fe:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004500:	00024997          	auipc	s3,0x24
    80004504:	7f098993          	addi	s3,s3,2032 # 80028cf0 <log>
    80004508:	a035                	j	80004534 <install_trans+0x60>
      bunpin(dbuf);
    8000450a:	8526                	mv	a0,s1
    8000450c:	fffff097          	auipc	ra,0xfffff
    80004510:	15e080e7          	jalr	350(ra) # 8000366a <bunpin>
    brelse(lbuf);
    80004514:	854a                	mv	a0,s2
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	07a080e7          	jalr	122(ra) # 80003590 <brelse>
    brelse(dbuf);
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	070080e7          	jalr	112(ra) # 80003590 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004528:	2a05                	addiw	s4,s4,1
    8000452a:	0a91                	addi	s5,s5,4
    8000452c:	02c9a783          	lw	a5,44(s3)
    80004530:	04fa5963          	bge	s4,a5,80004582 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004534:	0189a583          	lw	a1,24(s3)
    80004538:	014585bb          	addw	a1,a1,s4
    8000453c:	2585                	addiw	a1,a1,1
    8000453e:	0289a503          	lw	a0,40(s3)
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	f1e080e7          	jalr	-226(ra) # 80003460 <bread>
    8000454a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000454c:	000aa583          	lw	a1,0(s5)
    80004550:	0289a503          	lw	a0,40(s3)
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	f0c080e7          	jalr	-244(ra) # 80003460 <bread>
    8000455c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000455e:	40000613          	li	a2,1024
    80004562:	05890593          	addi	a1,s2,88
    80004566:	05850513          	addi	a0,a0,88
    8000456a:	ffffd097          	auipc	ra,0xffffd
    8000456e:	8d0080e7          	jalr	-1840(ra) # 80000e3a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004572:	8526                	mv	a0,s1
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	fde080e7          	jalr	-34(ra) # 80003552 <bwrite>
    if(recovering == 0)
    8000457c:	f80b1ce3          	bnez	s6,80004514 <install_trans+0x40>
    80004580:	b769                	j	8000450a <install_trans+0x36>
}
    80004582:	70e2                	ld	ra,56(sp)
    80004584:	7442                	ld	s0,48(sp)
    80004586:	74a2                	ld	s1,40(sp)
    80004588:	7902                	ld	s2,32(sp)
    8000458a:	69e2                	ld	s3,24(sp)
    8000458c:	6a42                	ld	s4,16(sp)
    8000458e:	6aa2                	ld	s5,8(sp)
    80004590:	6b02                	ld	s6,0(sp)
    80004592:	6121                	addi	sp,sp,64
    80004594:	8082                	ret
    80004596:	8082                	ret

0000000080004598 <initlog>:
{
    80004598:	7179                	addi	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	e84a                	sd	s2,16(sp)
    800045a2:	e44e                	sd	s3,8(sp)
    800045a4:	1800                	addi	s0,sp,48
    800045a6:	892a                	mv	s2,a0
    800045a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045aa:	00024497          	auipc	s1,0x24
    800045ae:	74648493          	addi	s1,s1,1862 # 80028cf0 <log>
    800045b2:	00004597          	auipc	a1,0x4
    800045b6:	20658593          	addi	a1,a1,518 # 800087b8 <syscalls+0x200>
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	692080e7          	jalr	1682(ra) # 80000c4e <initlock>
  log.start = sb->logstart;
    800045c4:	0149a583          	lw	a1,20(s3)
    800045c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045ca:	0109a783          	lw	a5,16(s3)
    800045ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045d4:	854a                	mv	a0,s2
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	e8a080e7          	jalr	-374(ra) # 80003460 <bread>
  log.lh.n = lh->n;
    800045de:	4d3c                	lw	a5,88(a0)
    800045e0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045e2:	02f05563          	blez	a5,8000460c <initlog+0x74>
    800045e6:	05c50713          	addi	a4,a0,92
    800045ea:	00024697          	auipc	a3,0x24
    800045ee:	73668693          	addi	a3,a3,1846 # 80028d20 <log+0x30>
    800045f2:	37fd                	addiw	a5,a5,-1
    800045f4:	1782                	slli	a5,a5,0x20
    800045f6:	9381                	srli	a5,a5,0x20
    800045f8:	078a                	slli	a5,a5,0x2
    800045fa:	06050613          	addi	a2,a0,96
    800045fe:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004600:	4310                	lw	a2,0(a4)
    80004602:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004604:	0711                	addi	a4,a4,4
    80004606:	0691                	addi	a3,a3,4
    80004608:	fef71ce3          	bne	a4,a5,80004600 <initlog+0x68>
  brelse(buf);
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	f84080e7          	jalr	-124(ra) # 80003590 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004614:	4505                	li	a0,1
    80004616:	00000097          	auipc	ra,0x0
    8000461a:	ebe080e7          	jalr	-322(ra) # 800044d4 <install_trans>
  log.lh.n = 0;
    8000461e:	00024797          	auipc	a5,0x24
    80004622:	6e07af23          	sw	zero,1790(a5) # 80028d1c <log+0x2c>
  write_head(); // clear the log
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	e34080e7          	jalr	-460(ra) # 8000445a <write_head>
}
    8000462e:	70a2                	ld	ra,40(sp)
    80004630:	7402                	ld	s0,32(sp)
    80004632:	64e2                	ld	s1,24(sp)
    80004634:	6942                	ld	s2,16(sp)
    80004636:	69a2                	ld	s3,8(sp)
    80004638:	6145                	addi	sp,sp,48
    8000463a:	8082                	ret

000000008000463c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000463c:	1101                	addi	sp,sp,-32
    8000463e:	ec06                	sd	ra,24(sp)
    80004640:	e822                	sd	s0,16(sp)
    80004642:	e426                	sd	s1,8(sp)
    80004644:	e04a                	sd	s2,0(sp)
    80004646:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004648:	00024517          	auipc	a0,0x24
    8000464c:	6a850513          	addi	a0,a0,1704 # 80028cf0 <log>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	68e080e7          	jalr	1678(ra) # 80000cde <acquire>
  while(1){
    if(log.committing){
    80004658:	00024497          	auipc	s1,0x24
    8000465c:	69848493          	addi	s1,s1,1688 # 80028cf0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004660:	4979                	li	s2,30
    80004662:	a039                	j	80004670 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004664:	85a6                	mv	a1,s1
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	cf6080e7          	jalr	-778(ra) # 8000235e <sleep>
    if(log.committing){
    80004670:	50dc                	lw	a5,36(s1)
    80004672:	fbed                	bnez	a5,80004664 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004674:	509c                	lw	a5,32(s1)
    80004676:	0017871b          	addiw	a4,a5,1
    8000467a:	0007069b          	sext.w	a3,a4
    8000467e:	0027179b          	slliw	a5,a4,0x2
    80004682:	9fb9                	addw	a5,a5,a4
    80004684:	0017979b          	slliw	a5,a5,0x1
    80004688:	54d8                	lw	a4,44(s1)
    8000468a:	9fb9                	addw	a5,a5,a4
    8000468c:	00f95963          	bge	s2,a5,8000469e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004690:	85a6                	mv	a1,s1
    80004692:	8526                	mv	a0,s1
    80004694:	ffffe097          	auipc	ra,0xffffe
    80004698:	cca080e7          	jalr	-822(ra) # 8000235e <sleep>
    8000469c:	bfd1                	j	80004670 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000469e:	00024517          	auipc	a0,0x24
    800046a2:	65250513          	addi	a0,a0,1618 # 80028cf0 <log>
    800046a6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	6ea080e7          	jalr	1770(ra) # 80000d92 <release>
      break;
    }
  }
}
    800046b0:	60e2                	ld	ra,24(sp)
    800046b2:	6442                	ld	s0,16(sp)
    800046b4:	64a2                	ld	s1,8(sp)
    800046b6:	6902                	ld	s2,0(sp)
    800046b8:	6105                	addi	sp,sp,32
    800046ba:	8082                	ret

00000000800046bc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046bc:	7139                	addi	sp,sp,-64
    800046be:	fc06                	sd	ra,56(sp)
    800046c0:	f822                	sd	s0,48(sp)
    800046c2:	f426                	sd	s1,40(sp)
    800046c4:	f04a                	sd	s2,32(sp)
    800046c6:	ec4e                	sd	s3,24(sp)
    800046c8:	e852                	sd	s4,16(sp)
    800046ca:	e456                	sd	s5,8(sp)
    800046cc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046ce:	00024497          	auipc	s1,0x24
    800046d2:	62248493          	addi	s1,s1,1570 # 80028cf0 <log>
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	606080e7          	jalr	1542(ra) # 80000cde <acquire>
  log.outstanding -= 1;
    800046e0:	509c                	lw	a5,32(s1)
    800046e2:	37fd                	addiw	a5,a5,-1
    800046e4:	0007891b          	sext.w	s2,a5
    800046e8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046ea:	50dc                	lw	a5,36(s1)
    800046ec:	efb9                	bnez	a5,8000474a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ee:	06091663          	bnez	s2,8000475a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046f2:	00024497          	auipc	s1,0x24
    800046f6:	5fe48493          	addi	s1,s1,1534 # 80028cf0 <log>
    800046fa:	4785                	li	a5,1
    800046fc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046fe:	8526                	mv	a0,s1
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	692080e7          	jalr	1682(ra) # 80000d92 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004708:	54dc                	lw	a5,44(s1)
    8000470a:	06f04763          	bgtz	a5,80004778 <end_op+0xbc>
    acquire(&log.lock);
    8000470e:	00024497          	auipc	s1,0x24
    80004712:	5e248493          	addi	s1,s1,1506 # 80028cf0 <log>
    80004716:	8526                	mv	a0,s1
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	5c6080e7          	jalr	1478(ra) # 80000cde <acquire>
    log.committing = 0;
    80004720:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004724:	8526                	mv	a0,s1
    80004726:	ffffe097          	auipc	ra,0xffffe
    8000472a:	c9c080e7          	jalr	-868(ra) # 800023c2 <wakeup>
    release(&log.lock);
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	662080e7          	jalr	1634(ra) # 80000d92 <release>
}
    80004738:	70e2                	ld	ra,56(sp)
    8000473a:	7442                	ld	s0,48(sp)
    8000473c:	74a2                	ld	s1,40(sp)
    8000473e:	7902                	ld	s2,32(sp)
    80004740:	69e2                	ld	s3,24(sp)
    80004742:	6a42                	ld	s4,16(sp)
    80004744:	6aa2                	ld	s5,8(sp)
    80004746:	6121                	addi	sp,sp,64
    80004748:	8082                	ret
    panic("log.committing");
    8000474a:	00004517          	auipc	a0,0x4
    8000474e:	07650513          	addi	a0,a0,118 # 800087c0 <syscalls+0x208>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	df2080e7          	jalr	-526(ra) # 80000544 <panic>
    wakeup(&log);
    8000475a:	00024497          	auipc	s1,0x24
    8000475e:	59648493          	addi	s1,s1,1430 # 80028cf0 <log>
    80004762:	8526                	mv	a0,s1
    80004764:	ffffe097          	auipc	ra,0xffffe
    80004768:	c5e080e7          	jalr	-930(ra) # 800023c2 <wakeup>
  release(&log.lock);
    8000476c:	8526                	mv	a0,s1
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	624080e7          	jalr	1572(ra) # 80000d92 <release>
  if(do_commit){
    80004776:	b7c9                	j	80004738 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004778:	00024a97          	auipc	s5,0x24
    8000477c:	5a8a8a93          	addi	s5,s5,1448 # 80028d20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004780:	00024a17          	auipc	s4,0x24
    80004784:	570a0a13          	addi	s4,s4,1392 # 80028cf0 <log>
    80004788:	018a2583          	lw	a1,24(s4)
    8000478c:	012585bb          	addw	a1,a1,s2
    80004790:	2585                	addiw	a1,a1,1
    80004792:	028a2503          	lw	a0,40(s4)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	cca080e7          	jalr	-822(ra) # 80003460 <bread>
    8000479e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047a0:	000aa583          	lw	a1,0(s5)
    800047a4:	028a2503          	lw	a0,40(s4)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	cb8080e7          	jalr	-840(ra) # 80003460 <bread>
    800047b0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047b2:	40000613          	li	a2,1024
    800047b6:	05850593          	addi	a1,a0,88
    800047ba:	05848513          	addi	a0,s1,88
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	67c080e7          	jalr	1660(ra) # 80000e3a <memmove>
    bwrite(to);  // write the log
    800047c6:	8526                	mv	a0,s1
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	d8a080e7          	jalr	-630(ra) # 80003552 <bwrite>
    brelse(from);
    800047d0:	854e                	mv	a0,s3
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	dbe080e7          	jalr	-578(ra) # 80003590 <brelse>
    brelse(to);
    800047da:	8526                	mv	a0,s1
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	db4080e7          	jalr	-588(ra) # 80003590 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e4:	2905                	addiw	s2,s2,1
    800047e6:	0a91                	addi	s5,s5,4
    800047e8:	02ca2783          	lw	a5,44(s4)
    800047ec:	f8f94ee3          	blt	s2,a5,80004788 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	c6a080e7          	jalr	-918(ra) # 8000445a <write_head>
    install_trans(0); // Now install writes to home locations
    800047f8:	4501                	li	a0,0
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	cda080e7          	jalr	-806(ra) # 800044d4 <install_trans>
    log.lh.n = 0;
    80004802:	00024797          	auipc	a5,0x24
    80004806:	5007ad23          	sw	zero,1306(a5) # 80028d1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	c50080e7          	jalr	-944(ra) # 8000445a <write_head>
    80004812:	bdf5                	j	8000470e <end_op+0x52>

0000000080004814 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	e04a                	sd	s2,0(sp)
    8000481e:	1000                	addi	s0,sp,32
    80004820:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004822:	00024917          	auipc	s2,0x24
    80004826:	4ce90913          	addi	s2,s2,1230 # 80028cf0 <log>
    8000482a:	854a                	mv	a0,s2
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	4b2080e7          	jalr	1202(ra) # 80000cde <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004834:	02c92603          	lw	a2,44(s2)
    80004838:	47f5                	li	a5,29
    8000483a:	06c7c563          	blt	a5,a2,800048a4 <log_write+0x90>
    8000483e:	00024797          	auipc	a5,0x24
    80004842:	4ce7a783          	lw	a5,1230(a5) # 80028d0c <log+0x1c>
    80004846:	37fd                	addiw	a5,a5,-1
    80004848:	04f65e63          	bge	a2,a5,800048a4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000484c:	00024797          	auipc	a5,0x24
    80004850:	4c47a783          	lw	a5,1220(a5) # 80028d10 <log+0x20>
    80004854:	06f05063          	blez	a5,800048b4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004858:	4781                	li	a5,0
    8000485a:	06c05563          	blez	a2,800048c4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000485e:	44cc                	lw	a1,12(s1)
    80004860:	00024717          	auipc	a4,0x24
    80004864:	4c070713          	addi	a4,a4,1216 # 80028d20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004868:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000486a:	4314                	lw	a3,0(a4)
    8000486c:	04b68c63          	beq	a3,a1,800048c4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004870:	2785                	addiw	a5,a5,1
    80004872:	0711                	addi	a4,a4,4
    80004874:	fef61be3          	bne	a2,a5,8000486a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004878:	0621                	addi	a2,a2,8
    8000487a:	060a                	slli	a2,a2,0x2
    8000487c:	00024797          	auipc	a5,0x24
    80004880:	47478793          	addi	a5,a5,1140 # 80028cf0 <log>
    80004884:	963e                	add	a2,a2,a5
    80004886:	44dc                	lw	a5,12(s1)
    80004888:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000488a:	8526                	mv	a0,s1
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	da2080e7          	jalr	-606(ra) # 8000362e <bpin>
    log.lh.n++;
    80004894:	00024717          	auipc	a4,0x24
    80004898:	45c70713          	addi	a4,a4,1116 # 80028cf0 <log>
    8000489c:	575c                	lw	a5,44(a4)
    8000489e:	2785                	addiw	a5,a5,1
    800048a0:	d75c                	sw	a5,44(a4)
    800048a2:	a835                	j	800048de <log_write+0xca>
    panic("too big a transaction");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	f2c50513          	addi	a0,a0,-212 # 800087d0 <syscalls+0x218>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c98080e7          	jalr	-872(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	f3450513          	addi	a0,a0,-204 # 800087e8 <syscalls+0x230>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c88080e7          	jalr	-888(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800048c4:	00878713          	addi	a4,a5,8
    800048c8:	00271693          	slli	a3,a4,0x2
    800048cc:	00024717          	auipc	a4,0x24
    800048d0:	42470713          	addi	a4,a4,1060 # 80028cf0 <log>
    800048d4:	9736                	add	a4,a4,a3
    800048d6:	44d4                	lw	a3,12(s1)
    800048d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048da:	faf608e3          	beq	a2,a5,8000488a <log_write+0x76>
  }
  release(&log.lock);
    800048de:	00024517          	auipc	a0,0x24
    800048e2:	41250513          	addi	a0,a0,1042 # 80028cf0 <log>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	4ac080e7          	jalr	1196(ra) # 80000d92 <release>
}
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6902                	ld	s2,0(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret

00000000800048fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048fa:	1101                	addi	sp,sp,-32
    800048fc:	ec06                	sd	ra,24(sp)
    800048fe:	e822                	sd	s0,16(sp)
    80004900:	e426                	sd	s1,8(sp)
    80004902:	e04a                	sd	s2,0(sp)
    80004904:	1000                	addi	s0,sp,32
    80004906:	84aa                	mv	s1,a0
    80004908:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000490a:	00004597          	auipc	a1,0x4
    8000490e:	efe58593          	addi	a1,a1,-258 # 80008808 <syscalls+0x250>
    80004912:	0521                	addi	a0,a0,8
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	33a080e7          	jalr	826(ra) # 80000c4e <initlock>
  lk->name = name;
    8000491c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004920:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004924:	0204a423          	sw	zero,40(s1)
}
    80004928:	60e2                	ld	ra,24(sp)
    8000492a:	6442                	ld	s0,16(sp)
    8000492c:	64a2                	ld	s1,8(sp)
    8000492e:	6902                	ld	s2,0(sp)
    80004930:	6105                	addi	sp,sp,32
    80004932:	8082                	ret

0000000080004934 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004934:	1101                	addi	sp,sp,-32
    80004936:	ec06                	sd	ra,24(sp)
    80004938:	e822                	sd	s0,16(sp)
    8000493a:	e426                	sd	s1,8(sp)
    8000493c:	e04a                	sd	s2,0(sp)
    8000493e:	1000                	addi	s0,sp,32
    80004940:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004942:	00850913          	addi	s2,a0,8
    80004946:	854a                	mv	a0,s2
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	396080e7          	jalr	918(ra) # 80000cde <acquire>
  while (lk->locked) {
    80004950:	409c                	lw	a5,0(s1)
    80004952:	cb89                	beqz	a5,80004964 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004954:	85ca                	mv	a1,s2
    80004956:	8526                	mv	a0,s1
    80004958:	ffffe097          	auipc	ra,0xffffe
    8000495c:	a06080e7          	jalr	-1530(ra) # 8000235e <sleep>
  while (lk->locked) {
    80004960:	409c                	lw	a5,0(s1)
    80004962:	fbed                	bnez	a5,80004954 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004964:	4785                	li	a5,1
    80004966:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004968:	ffffd097          	auipc	ra,0xffffd
    8000496c:	292080e7          	jalr	658(ra) # 80001bfa <myproc>
    80004970:	591c                	lw	a5,48(a0)
    80004972:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004974:	854a                	mv	a0,s2
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	41c080e7          	jalr	1052(ra) # 80000d92 <release>
}
    8000497e:	60e2                	ld	ra,24(sp)
    80004980:	6442                	ld	s0,16(sp)
    80004982:	64a2                	ld	s1,8(sp)
    80004984:	6902                	ld	s2,0(sp)
    80004986:	6105                	addi	sp,sp,32
    80004988:	8082                	ret

000000008000498a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000498a:	1101                	addi	sp,sp,-32
    8000498c:	ec06                	sd	ra,24(sp)
    8000498e:	e822                	sd	s0,16(sp)
    80004990:	e426                	sd	s1,8(sp)
    80004992:	e04a                	sd	s2,0(sp)
    80004994:	1000                	addi	s0,sp,32
    80004996:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004998:	00850913          	addi	s2,a0,8
    8000499c:	854a                	mv	a0,s2
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	340080e7          	jalr	832(ra) # 80000cde <acquire>
  lk->locked = 0;
    800049a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffe097          	auipc	ra,0xffffe
    800049b4:	a12080e7          	jalr	-1518(ra) # 800023c2 <wakeup>
  release(&lk->lk);
    800049b8:	854a                	mv	a0,s2
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	3d8080e7          	jalr	984(ra) # 80000d92 <release>
}
    800049c2:	60e2                	ld	ra,24(sp)
    800049c4:	6442                	ld	s0,16(sp)
    800049c6:	64a2                	ld	s1,8(sp)
    800049c8:	6902                	ld	s2,0(sp)
    800049ca:	6105                	addi	sp,sp,32
    800049cc:	8082                	ret

00000000800049ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049ce:	7179                	addi	sp,sp,-48
    800049d0:	f406                	sd	ra,40(sp)
    800049d2:	f022                	sd	s0,32(sp)
    800049d4:	ec26                	sd	s1,24(sp)
    800049d6:	e84a                	sd	s2,16(sp)
    800049d8:	e44e                	sd	s3,8(sp)
    800049da:	1800                	addi	s0,sp,48
    800049dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049de:	00850913          	addi	s2,a0,8
    800049e2:	854a                	mv	a0,s2
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	2fa080e7          	jalr	762(ra) # 80000cde <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ec:	409c                	lw	a5,0(s1)
    800049ee:	ef99                	bnez	a5,80004a0c <holdingsleep+0x3e>
    800049f0:	4481                	li	s1,0
  release(&lk->lk);
    800049f2:	854a                	mv	a0,s2
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	39e080e7          	jalr	926(ra) # 80000d92 <release>
  return r;
}
    800049fc:	8526                	mv	a0,s1
    800049fe:	70a2                	ld	ra,40(sp)
    80004a00:	7402                	ld	s0,32(sp)
    80004a02:	64e2                	ld	s1,24(sp)
    80004a04:	6942                	ld	s2,16(sp)
    80004a06:	69a2                	ld	s3,8(sp)
    80004a08:	6145                	addi	sp,sp,48
    80004a0a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a0c:	0284a983          	lw	s3,40(s1)
    80004a10:	ffffd097          	auipc	ra,0xffffd
    80004a14:	1ea080e7          	jalr	490(ra) # 80001bfa <myproc>
    80004a18:	5904                	lw	s1,48(a0)
    80004a1a:	413484b3          	sub	s1,s1,s3
    80004a1e:	0014b493          	seqz	s1,s1
    80004a22:	bfc1                	j	800049f2 <holdingsleep+0x24>

0000000080004a24 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a24:	1141                	addi	sp,sp,-16
    80004a26:	e406                	sd	ra,8(sp)
    80004a28:	e022                	sd	s0,0(sp)
    80004a2a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a2c:	00004597          	auipc	a1,0x4
    80004a30:	dec58593          	addi	a1,a1,-532 # 80008818 <syscalls+0x260>
    80004a34:	00024517          	auipc	a0,0x24
    80004a38:	40450513          	addi	a0,a0,1028 # 80028e38 <ftable>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	212080e7          	jalr	530(ra) # 80000c4e <initlock>
}
    80004a44:	60a2                	ld	ra,8(sp)
    80004a46:	6402                	ld	s0,0(sp)
    80004a48:	0141                	addi	sp,sp,16
    80004a4a:	8082                	ret

0000000080004a4c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a4c:	1101                	addi	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a56:	00024517          	auipc	a0,0x24
    80004a5a:	3e250513          	addi	a0,a0,994 # 80028e38 <ftable>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	280080e7          	jalr	640(ra) # 80000cde <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a66:	00024497          	auipc	s1,0x24
    80004a6a:	3ea48493          	addi	s1,s1,1002 # 80028e50 <ftable+0x18>
    80004a6e:	00025717          	auipc	a4,0x25
    80004a72:	38270713          	addi	a4,a4,898 # 80029df0 <disk>
    if(f->ref == 0){
    80004a76:	40dc                	lw	a5,4(s1)
    80004a78:	cf99                	beqz	a5,80004a96 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a7a:	02848493          	addi	s1,s1,40
    80004a7e:	fee49ce3          	bne	s1,a4,80004a76 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a82:	00024517          	auipc	a0,0x24
    80004a86:	3b650513          	addi	a0,a0,950 # 80028e38 <ftable>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	308080e7          	jalr	776(ra) # 80000d92 <release>
  return 0;
    80004a92:	4481                	li	s1,0
    80004a94:	a819                	j	80004aaa <filealloc+0x5e>
      f->ref = 1;
    80004a96:	4785                	li	a5,1
    80004a98:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a9a:	00024517          	auipc	a0,0x24
    80004a9e:	39e50513          	addi	a0,a0,926 # 80028e38 <ftable>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	2f0080e7          	jalr	752(ra) # 80000d92 <release>
}
    80004aaa:	8526                	mv	a0,s1
    80004aac:	60e2                	ld	ra,24(sp)
    80004aae:	6442                	ld	s0,16(sp)
    80004ab0:	64a2                	ld	s1,8(sp)
    80004ab2:	6105                	addi	sp,sp,32
    80004ab4:	8082                	ret

0000000080004ab6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ab6:	1101                	addi	sp,sp,-32
    80004ab8:	ec06                	sd	ra,24(sp)
    80004aba:	e822                	sd	s0,16(sp)
    80004abc:	e426                	sd	s1,8(sp)
    80004abe:	1000                	addi	s0,sp,32
    80004ac0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ac2:	00024517          	auipc	a0,0x24
    80004ac6:	37650513          	addi	a0,a0,886 # 80028e38 <ftable>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	214080e7          	jalr	532(ra) # 80000cde <acquire>
  if(f->ref < 1)
    80004ad2:	40dc                	lw	a5,4(s1)
    80004ad4:	02f05263          	blez	a5,80004af8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ad8:	2785                	addiw	a5,a5,1
    80004ada:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004adc:	00024517          	auipc	a0,0x24
    80004ae0:	35c50513          	addi	a0,a0,860 # 80028e38 <ftable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	2ae080e7          	jalr	686(ra) # 80000d92 <release>
  return f;
}
    80004aec:	8526                	mv	a0,s1
    80004aee:	60e2                	ld	ra,24(sp)
    80004af0:	6442                	ld	s0,16(sp)
    80004af2:	64a2                	ld	s1,8(sp)
    80004af4:	6105                	addi	sp,sp,32
    80004af6:	8082                	ret
    panic("filedup");
    80004af8:	00004517          	auipc	a0,0x4
    80004afc:	d2850513          	addi	a0,a0,-728 # 80008820 <syscalls+0x268>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	a44080e7          	jalr	-1468(ra) # 80000544 <panic>

0000000080004b08 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b08:	7139                	addi	sp,sp,-64
    80004b0a:	fc06                	sd	ra,56(sp)
    80004b0c:	f822                	sd	s0,48(sp)
    80004b0e:	f426                	sd	s1,40(sp)
    80004b10:	f04a                	sd	s2,32(sp)
    80004b12:	ec4e                	sd	s3,24(sp)
    80004b14:	e852                	sd	s4,16(sp)
    80004b16:	e456                	sd	s5,8(sp)
    80004b18:	0080                	addi	s0,sp,64
    80004b1a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b1c:	00024517          	auipc	a0,0x24
    80004b20:	31c50513          	addi	a0,a0,796 # 80028e38 <ftable>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	1ba080e7          	jalr	442(ra) # 80000cde <acquire>
  if(f->ref < 1)
    80004b2c:	40dc                	lw	a5,4(s1)
    80004b2e:	06f05163          	blez	a5,80004b90 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b32:	37fd                	addiw	a5,a5,-1
    80004b34:	0007871b          	sext.w	a4,a5
    80004b38:	c0dc                	sw	a5,4(s1)
    80004b3a:	06e04363          	bgtz	a4,80004ba0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b3e:	0004a903          	lw	s2,0(s1)
    80004b42:	0094ca83          	lbu	s5,9(s1)
    80004b46:	0104ba03          	ld	s4,16(s1)
    80004b4a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b4e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b52:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b56:	00024517          	auipc	a0,0x24
    80004b5a:	2e250513          	addi	a0,a0,738 # 80028e38 <ftable>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	234080e7          	jalr	564(ra) # 80000d92 <release>

  if(ff.type == FD_PIPE){
    80004b66:	4785                	li	a5,1
    80004b68:	04f90d63          	beq	s2,a5,80004bc2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b6c:	3979                	addiw	s2,s2,-2
    80004b6e:	4785                	li	a5,1
    80004b70:	0527e063          	bltu	a5,s2,80004bb0 <fileclose+0xa8>
    begin_op();
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	ac8080e7          	jalr	-1336(ra) # 8000463c <begin_op>
    iput(ff.ip);
    80004b7c:	854e                	mv	a0,s3
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	2b6080e7          	jalr	694(ra) # 80003e34 <iput>
    end_op();
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	b36080e7          	jalr	-1226(ra) # 800046bc <end_op>
    80004b8e:	a00d                	j	80004bb0 <fileclose+0xa8>
    panic("fileclose");
    80004b90:	00004517          	auipc	a0,0x4
    80004b94:	c9850513          	addi	a0,a0,-872 # 80008828 <syscalls+0x270>
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	9ac080e7          	jalr	-1620(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004ba0:	00024517          	auipc	a0,0x24
    80004ba4:	29850513          	addi	a0,a0,664 # 80028e38 <ftable>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	1ea080e7          	jalr	490(ra) # 80000d92 <release>
  }
}
    80004bb0:	70e2                	ld	ra,56(sp)
    80004bb2:	7442                	ld	s0,48(sp)
    80004bb4:	74a2                	ld	s1,40(sp)
    80004bb6:	7902                	ld	s2,32(sp)
    80004bb8:	69e2                	ld	s3,24(sp)
    80004bba:	6a42                	ld	s4,16(sp)
    80004bbc:	6aa2                	ld	s5,8(sp)
    80004bbe:	6121                	addi	sp,sp,64
    80004bc0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bc2:	85d6                	mv	a1,s5
    80004bc4:	8552                	mv	a0,s4
    80004bc6:	00000097          	auipc	ra,0x0
    80004bca:	34c080e7          	jalr	844(ra) # 80004f12 <pipeclose>
    80004bce:	b7cd                	j	80004bb0 <fileclose+0xa8>

0000000080004bd0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bd0:	715d                	addi	sp,sp,-80
    80004bd2:	e486                	sd	ra,72(sp)
    80004bd4:	e0a2                	sd	s0,64(sp)
    80004bd6:	fc26                	sd	s1,56(sp)
    80004bd8:	f84a                	sd	s2,48(sp)
    80004bda:	f44e                	sd	s3,40(sp)
    80004bdc:	0880                	addi	s0,sp,80
    80004bde:	84aa                	mv	s1,a0
    80004be0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	018080e7          	jalr	24(ra) # 80001bfa <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bea:	409c                	lw	a5,0(s1)
    80004bec:	37f9                	addiw	a5,a5,-2
    80004bee:	4705                	li	a4,1
    80004bf0:	04f76763          	bltu	a4,a5,80004c3e <filestat+0x6e>
    80004bf4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bf6:	6c88                	ld	a0,24(s1)
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	082080e7          	jalr	130(ra) # 80003c7a <ilock>
    stati(f->ip, &st);
    80004c00:	fb840593          	addi	a1,s0,-72
    80004c04:	6c88                	ld	a0,24(s1)
    80004c06:	fffff097          	auipc	ra,0xfffff
    80004c0a:	2fe080e7          	jalr	766(ra) # 80003f04 <stati>
    iunlock(f->ip);
    80004c0e:	6c88                	ld	a0,24(s1)
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	12c080e7          	jalr	300(ra) # 80003d3c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c18:	46e1                	li	a3,24
    80004c1a:	fb840613          	addi	a2,s0,-72
    80004c1e:	85ce                	mv	a1,s3
    80004c20:	05093503          	ld	a0,80(s2)
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	b96080e7          	jalr	-1130(ra) # 800017ba <copyout>
    80004c2c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c30:	60a6                	ld	ra,72(sp)
    80004c32:	6406                	ld	s0,64(sp)
    80004c34:	74e2                	ld	s1,56(sp)
    80004c36:	7942                	ld	s2,48(sp)
    80004c38:	79a2                	ld	s3,40(sp)
    80004c3a:	6161                	addi	sp,sp,80
    80004c3c:	8082                	ret
  return -1;
    80004c3e:	557d                	li	a0,-1
    80004c40:	bfc5                	j	80004c30 <filestat+0x60>

0000000080004c42 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c42:	7179                	addi	sp,sp,-48
    80004c44:	f406                	sd	ra,40(sp)
    80004c46:	f022                	sd	s0,32(sp)
    80004c48:	ec26                	sd	s1,24(sp)
    80004c4a:	e84a                	sd	s2,16(sp)
    80004c4c:	e44e                	sd	s3,8(sp)
    80004c4e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c50:	00854783          	lbu	a5,8(a0)
    80004c54:	c3d5                	beqz	a5,80004cf8 <fileread+0xb6>
    80004c56:	84aa                	mv	s1,a0
    80004c58:	89ae                	mv	s3,a1
    80004c5a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c5c:	411c                	lw	a5,0(a0)
    80004c5e:	4705                	li	a4,1
    80004c60:	04e78963          	beq	a5,a4,80004cb2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c64:	470d                	li	a4,3
    80004c66:	04e78d63          	beq	a5,a4,80004cc0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c6a:	4709                	li	a4,2
    80004c6c:	06e79e63          	bne	a5,a4,80004ce8 <fileread+0xa6>
    ilock(f->ip);
    80004c70:	6d08                	ld	a0,24(a0)
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	008080e7          	jalr	8(ra) # 80003c7a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c7a:	874a                	mv	a4,s2
    80004c7c:	5094                	lw	a3,32(s1)
    80004c7e:	864e                	mv	a2,s3
    80004c80:	4585                	li	a1,1
    80004c82:	6c88                	ld	a0,24(s1)
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	2aa080e7          	jalr	682(ra) # 80003f2e <readi>
    80004c8c:	892a                	mv	s2,a0
    80004c8e:	00a05563          	blez	a0,80004c98 <fileread+0x56>
      f->off += r;
    80004c92:	509c                	lw	a5,32(s1)
    80004c94:	9fa9                	addw	a5,a5,a0
    80004c96:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c98:	6c88                	ld	a0,24(s1)
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	0a2080e7          	jalr	162(ra) # 80003d3c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	70a2                	ld	ra,40(sp)
    80004ca6:	7402                	ld	s0,32(sp)
    80004ca8:	64e2                	ld	s1,24(sp)
    80004caa:	6942                	ld	s2,16(sp)
    80004cac:	69a2                	ld	s3,8(sp)
    80004cae:	6145                	addi	sp,sp,48
    80004cb0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cb2:	6908                	ld	a0,16(a0)
    80004cb4:	00000097          	auipc	ra,0x0
    80004cb8:	3ce080e7          	jalr	974(ra) # 80005082 <piperead>
    80004cbc:	892a                	mv	s2,a0
    80004cbe:	b7d5                	j	80004ca2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cc0:	02451783          	lh	a5,36(a0)
    80004cc4:	03079693          	slli	a3,a5,0x30
    80004cc8:	92c1                	srli	a3,a3,0x30
    80004cca:	4725                	li	a4,9
    80004ccc:	02d76863          	bltu	a4,a3,80004cfc <fileread+0xba>
    80004cd0:	0792                	slli	a5,a5,0x4
    80004cd2:	00024717          	auipc	a4,0x24
    80004cd6:	0c670713          	addi	a4,a4,198 # 80028d98 <devsw>
    80004cda:	97ba                	add	a5,a5,a4
    80004cdc:	639c                	ld	a5,0(a5)
    80004cde:	c38d                	beqz	a5,80004d00 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ce0:	4505                	li	a0,1
    80004ce2:	9782                	jalr	a5
    80004ce4:	892a                	mv	s2,a0
    80004ce6:	bf75                	j	80004ca2 <fileread+0x60>
    panic("fileread");
    80004ce8:	00004517          	auipc	a0,0x4
    80004cec:	b5050513          	addi	a0,a0,-1200 # 80008838 <syscalls+0x280>
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	854080e7          	jalr	-1964(ra) # 80000544 <panic>
    return -1;
    80004cf8:	597d                	li	s2,-1
    80004cfa:	b765                	j	80004ca2 <fileread+0x60>
      return -1;
    80004cfc:	597d                	li	s2,-1
    80004cfe:	b755                	j	80004ca2 <fileread+0x60>
    80004d00:	597d                	li	s2,-1
    80004d02:	b745                	j	80004ca2 <fileread+0x60>

0000000080004d04 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d04:	715d                	addi	sp,sp,-80
    80004d06:	e486                	sd	ra,72(sp)
    80004d08:	e0a2                	sd	s0,64(sp)
    80004d0a:	fc26                	sd	s1,56(sp)
    80004d0c:	f84a                	sd	s2,48(sp)
    80004d0e:	f44e                	sd	s3,40(sp)
    80004d10:	f052                	sd	s4,32(sp)
    80004d12:	ec56                	sd	s5,24(sp)
    80004d14:	e85a                	sd	s6,16(sp)
    80004d16:	e45e                	sd	s7,8(sp)
    80004d18:	e062                	sd	s8,0(sp)
    80004d1a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d1c:	00954783          	lbu	a5,9(a0)
    80004d20:	10078663          	beqz	a5,80004e2c <filewrite+0x128>
    80004d24:	892a                	mv	s2,a0
    80004d26:	8aae                	mv	s5,a1
    80004d28:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d2a:	411c                	lw	a5,0(a0)
    80004d2c:	4705                	li	a4,1
    80004d2e:	02e78263          	beq	a5,a4,80004d52 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d32:	470d                	li	a4,3
    80004d34:	02e78663          	beq	a5,a4,80004d60 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d38:	4709                	li	a4,2
    80004d3a:	0ee79163          	bne	a5,a4,80004e1c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d3e:	0ac05d63          	blez	a2,80004df8 <filewrite+0xf4>
    int i = 0;
    80004d42:	4981                	li	s3,0
    80004d44:	6b05                	lui	s6,0x1
    80004d46:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d4a:	6b85                	lui	s7,0x1
    80004d4c:	c00b8b9b          	addiw	s7,s7,-1024
    80004d50:	a861                	j	80004de8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d52:	6908                	ld	a0,16(a0)
    80004d54:	00000097          	auipc	ra,0x0
    80004d58:	22e080e7          	jalr	558(ra) # 80004f82 <pipewrite>
    80004d5c:	8a2a                	mv	s4,a0
    80004d5e:	a045                	j	80004dfe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d60:	02451783          	lh	a5,36(a0)
    80004d64:	03079693          	slli	a3,a5,0x30
    80004d68:	92c1                	srli	a3,a3,0x30
    80004d6a:	4725                	li	a4,9
    80004d6c:	0cd76263          	bltu	a4,a3,80004e30 <filewrite+0x12c>
    80004d70:	0792                	slli	a5,a5,0x4
    80004d72:	00024717          	auipc	a4,0x24
    80004d76:	02670713          	addi	a4,a4,38 # 80028d98 <devsw>
    80004d7a:	97ba                	add	a5,a5,a4
    80004d7c:	679c                	ld	a5,8(a5)
    80004d7e:	cbdd                	beqz	a5,80004e34 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d80:	4505                	li	a0,1
    80004d82:	9782                	jalr	a5
    80004d84:	8a2a                	mv	s4,a0
    80004d86:	a8a5                	j	80004dfe <filewrite+0xfa>
    80004d88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	8b0080e7          	jalr	-1872(ra) # 8000463c <begin_op>
      ilock(f->ip);
    80004d94:	01893503          	ld	a0,24(s2)
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	ee2080e7          	jalr	-286(ra) # 80003c7a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004da0:	8762                	mv	a4,s8
    80004da2:	02092683          	lw	a3,32(s2)
    80004da6:	01598633          	add	a2,s3,s5
    80004daa:	4585                	li	a1,1
    80004dac:	01893503          	ld	a0,24(s2)
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	276080e7          	jalr	630(ra) # 80004026 <writei>
    80004db8:	84aa                	mv	s1,a0
    80004dba:	00a05763          	blez	a0,80004dc8 <filewrite+0xc4>
        f->off += r;
    80004dbe:	02092783          	lw	a5,32(s2)
    80004dc2:	9fa9                	addw	a5,a5,a0
    80004dc4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dc8:	01893503          	ld	a0,24(s2)
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	f70080e7          	jalr	-144(ra) # 80003d3c <iunlock>
      end_op();
    80004dd4:	00000097          	auipc	ra,0x0
    80004dd8:	8e8080e7          	jalr	-1816(ra) # 800046bc <end_op>

      if(r != n1){
    80004ddc:	009c1f63          	bne	s8,s1,80004dfa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004de0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004de4:	0149db63          	bge	s3,s4,80004dfa <filewrite+0xf6>
      int n1 = n - i;
    80004de8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dec:	84be                	mv	s1,a5
    80004dee:	2781                	sext.w	a5,a5
    80004df0:	f8fb5ce3          	bge	s6,a5,80004d88 <filewrite+0x84>
    80004df4:	84de                	mv	s1,s7
    80004df6:	bf49                	j	80004d88 <filewrite+0x84>
    int i = 0;
    80004df8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dfa:	013a1f63          	bne	s4,s3,80004e18 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dfe:	8552                	mv	a0,s4
    80004e00:	60a6                	ld	ra,72(sp)
    80004e02:	6406                	ld	s0,64(sp)
    80004e04:	74e2                	ld	s1,56(sp)
    80004e06:	7942                	ld	s2,48(sp)
    80004e08:	79a2                	ld	s3,40(sp)
    80004e0a:	7a02                	ld	s4,32(sp)
    80004e0c:	6ae2                	ld	s5,24(sp)
    80004e0e:	6b42                	ld	s6,16(sp)
    80004e10:	6ba2                	ld	s7,8(sp)
    80004e12:	6c02                	ld	s8,0(sp)
    80004e14:	6161                	addi	sp,sp,80
    80004e16:	8082                	ret
    ret = (i == n ? n : -1);
    80004e18:	5a7d                	li	s4,-1
    80004e1a:	b7d5                	j	80004dfe <filewrite+0xfa>
    panic("filewrite");
    80004e1c:	00004517          	auipc	a0,0x4
    80004e20:	a2c50513          	addi	a0,a0,-1492 # 80008848 <syscalls+0x290>
    80004e24:	ffffb097          	auipc	ra,0xffffb
    80004e28:	720080e7          	jalr	1824(ra) # 80000544 <panic>
    return -1;
    80004e2c:	5a7d                	li	s4,-1
    80004e2e:	bfc1                	j	80004dfe <filewrite+0xfa>
      return -1;
    80004e30:	5a7d                	li	s4,-1
    80004e32:	b7f1                	j	80004dfe <filewrite+0xfa>
    80004e34:	5a7d                	li	s4,-1
    80004e36:	b7e1                	j	80004dfe <filewrite+0xfa>

0000000080004e38 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e38:	7179                	addi	sp,sp,-48
    80004e3a:	f406                	sd	ra,40(sp)
    80004e3c:	f022                	sd	s0,32(sp)
    80004e3e:	ec26                	sd	s1,24(sp)
    80004e40:	e84a                	sd	s2,16(sp)
    80004e42:	e44e                	sd	s3,8(sp)
    80004e44:	e052                	sd	s4,0(sp)
    80004e46:	1800                	addi	s0,sp,48
    80004e48:	84aa                	mv	s1,a0
    80004e4a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e4c:	0005b023          	sd	zero,0(a1)
    80004e50:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e54:	00000097          	auipc	ra,0x0
    80004e58:	bf8080e7          	jalr	-1032(ra) # 80004a4c <filealloc>
    80004e5c:	e088                	sd	a0,0(s1)
    80004e5e:	c551                	beqz	a0,80004eea <pipealloc+0xb2>
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	bec080e7          	jalr	-1044(ra) # 80004a4c <filealloc>
    80004e68:	00aa3023          	sd	a0,0(s4)
    80004e6c:	c92d                	beqz	a0,80004ede <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	d34080e7          	jalr	-716(ra) # 80000ba2 <kalloc>
    80004e76:	892a                	mv	s2,a0
    80004e78:	c125                	beqz	a0,80004ed8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e7a:	4985                	li	s3,1
    80004e7c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e80:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e84:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e88:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e8c:	00004597          	auipc	a1,0x4
    80004e90:	9cc58593          	addi	a1,a1,-1588 # 80008858 <syscalls+0x2a0>
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	dba080e7          	jalr	-582(ra) # 80000c4e <initlock>
  (*f0)->type = FD_PIPE;
    80004e9c:	609c                	ld	a5,0(s1)
    80004e9e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ea2:	609c                	ld	a5,0(s1)
    80004ea4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ea8:	609c                	ld	a5,0(s1)
    80004eaa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004eae:	609c                	ld	a5,0(s1)
    80004eb0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004eb4:	000a3783          	ld	a5,0(s4)
    80004eb8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ebc:	000a3783          	ld	a5,0(s4)
    80004ec0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ec4:	000a3783          	ld	a5,0(s4)
    80004ec8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ecc:	000a3783          	ld	a5,0(s4)
    80004ed0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ed4:	4501                	li	a0,0
    80004ed6:	a025                	j	80004efe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ed8:	6088                	ld	a0,0(s1)
    80004eda:	e501                	bnez	a0,80004ee2 <pipealloc+0xaa>
    80004edc:	a039                	j	80004eea <pipealloc+0xb2>
    80004ede:	6088                	ld	a0,0(s1)
    80004ee0:	c51d                	beqz	a0,80004f0e <pipealloc+0xd6>
    fileclose(*f0);
    80004ee2:	00000097          	auipc	ra,0x0
    80004ee6:	c26080e7          	jalr	-986(ra) # 80004b08 <fileclose>
  if(*f1)
    80004eea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eee:	557d                	li	a0,-1
  if(*f1)
    80004ef0:	c799                	beqz	a5,80004efe <pipealloc+0xc6>
    fileclose(*f1);
    80004ef2:	853e                	mv	a0,a5
    80004ef4:	00000097          	auipc	ra,0x0
    80004ef8:	c14080e7          	jalr	-1004(ra) # 80004b08 <fileclose>
  return -1;
    80004efc:	557d                	li	a0,-1
}
    80004efe:	70a2                	ld	ra,40(sp)
    80004f00:	7402                	ld	s0,32(sp)
    80004f02:	64e2                	ld	s1,24(sp)
    80004f04:	6942                	ld	s2,16(sp)
    80004f06:	69a2                	ld	s3,8(sp)
    80004f08:	6a02                	ld	s4,0(sp)
    80004f0a:	6145                	addi	sp,sp,48
    80004f0c:	8082                	ret
  return -1;
    80004f0e:	557d                	li	a0,-1
    80004f10:	b7fd                	j	80004efe <pipealloc+0xc6>

0000000080004f12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f12:	1101                	addi	sp,sp,-32
    80004f14:	ec06                	sd	ra,24(sp)
    80004f16:	e822                	sd	s0,16(sp)
    80004f18:	e426                	sd	s1,8(sp)
    80004f1a:	e04a                	sd	s2,0(sp)
    80004f1c:	1000                	addi	s0,sp,32
    80004f1e:	84aa                	mv	s1,a0
    80004f20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	dbc080e7          	jalr	-580(ra) # 80000cde <acquire>
  if(writable){
    80004f2a:	02090d63          	beqz	s2,80004f64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f2e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f32:	21848513          	addi	a0,s1,536
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	48c080e7          	jalr	1164(ra) # 800023c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f3e:	2204b783          	ld	a5,544(s1)
    80004f42:	eb95                	bnez	a5,80004f76 <pipeclose+0x64>
    release(&pi->lock);
    80004f44:	8526                	mv	a0,s1
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	e4c080e7          	jalr	-436(ra) # 80000d92 <release>
    kfree((char*)pi);
    80004f4e:	8526                	mv	a0,s1
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	ac0080e7          	jalr	-1344(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004f58:	60e2                	ld	ra,24(sp)
    80004f5a:	6442                	ld	s0,16(sp)
    80004f5c:	64a2                	ld	s1,8(sp)
    80004f5e:	6902                	ld	s2,0(sp)
    80004f60:	6105                	addi	sp,sp,32
    80004f62:	8082                	ret
    pi->readopen = 0;
    80004f64:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f68:	21c48513          	addi	a0,s1,540
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	456080e7          	jalr	1110(ra) # 800023c2 <wakeup>
    80004f74:	b7e9                	j	80004f3e <pipeclose+0x2c>
    release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	e1a080e7          	jalr	-486(ra) # 80000d92 <release>
}
    80004f80:	bfe1                	j	80004f58 <pipeclose+0x46>

0000000080004f82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f82:	7159                	addi	sp,sp,-112
    80004f84:	f486                	sd	ra,104(sp)
    80004f86:	f0a2                	sd	s0,96(sp)
    80004f88:	eca6                	sd	s1,88(sp)
    80004f8a:	e8ca                	sd	s2,80(sp)
    80004f8c:	e4ce                	sd	s3,72(sp)
    80004f8e:	e0d2                	sd	s4,64(sp)
    80004f90:	fc56                	sd	s5,56(sp)
    80004f92:	f85a                	sd	s6,48(sp)
    80004f94:	f45e                	sd	s7,40(sp)
    80004f96:	f062                	sd	s8,32(sp)
    80004f98:	ec66                	sd	s9,24(sp)
    80004f9a:	1880                	addi	s0,sp,112
    80004f9c:	84aa                	mv	s1,a0
    80004f9e:	8aae                	mv	s5,a1
    80004fa0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	c58080e7          	jalr	-936(ra) # 80001bfa <myproc>
    80004faa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fac:	8526                	mv	a0,s1
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	d30080e7          	jalr	-720(ra) # 80000cde <acquire>
  while(i < n){
    80004fb6:	0d405463          	blez	s4,8000507e <pipewrite+0xfc>
    80004fba:	8ba6                	mv	s7,s1
  int i = 0;
    80004fbc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fbe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fc0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fc4:	21c48c13          	addi	s8,s1,540
    80004fc8:	a08d                	j	8000502a <pipewrite+0xa8>
      release(&pi->lock);
    80004fca:	8526                	mv	a0,s1
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	dc6080e7          	jalr	-570(ra) # 80000d92 <release>
      return -1;
    80004fd4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fd6:	854a                	mv	a0,s2
    80004fd8:	70a6                	ld	ra,104(sp)
    80004fda:	7406                	ld	s0,96(sp)
    80004fdc:	64e6                	ld	s1,88(sp)
    80004fde:	6946                	ld	s2,80(sp)
    80004fe0:	69a6                	ld	s3,72(sp)
    80004fe2:	6a06                	ld	s4,64(sp)
    80004fe4:	7ae2                	ld	s5,56(sp)
    80004fe6:	7b42                	ld	s6,48(sp)
    80004fe8:	7ba2                	ld	s7,40(sp)
    80004fea:	7c02                	ld	s8,32(sp)
    80004fec:	6ce2                	ld	s9,24(sp)
    80004fee:	6165                	addi	sp,sp,112
    80004ff0:	8082                	ret
      wakeup(&pi->nread);
    80004ff2:	8566                	mv	a0,s9
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	3ce080e7          	jalr	974(ra) # 800023c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ffc:	85de                	mv	a1,s7
    80004ffe:	8562                	mv	a0,s8
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	35e080e7          	jalr	862(ra) # 8000235e <sleep>
    80005008:	a839                	j	80005026 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000500a:	21c4a783          	lw	a5,540(s1)
    8000500e:	0017871b          	addiw	a4,a5,1
    80005012:	20e4ae23          	sw	a4,540(s1)
    80005016:	1ff7f793          	andi	a5,a5,511
    8000501a:	97a6                	add	a5,a5,s1
    8000501c:	f9f44703          	lbu	a4,-97(s0)
    80005020:	00e78c23          	sb	a4,24(a5)
      i++;
    80005024:	2905                	addiw	s2,s2,1
  while(i < n){
    80005026:	05495063          	bge	s2,s4,80005066 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    8000502a:	2204a783          	lw	a5,544(s1)
    8000502e:	dfd1                	beqz	a5,80004fca <pipewrite+0x48>
    80005030:	854e                	mv	a0,s3
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	5d4080e7          	jalr	1492(ra) # 80002606 <killed>
    8000503a:	f941                	bnez	a0,80004fca <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000503c:	2184a783          	lw	a5,536(s1)
    80005040:	21c4a703          	lw	a4,540(s1)
    80005044:	2007879b          	addiw	a5,a5,512
    80005048:	faf705e3          	beq	a4,a5,80004ff2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000504c:	4685                	li	a3,1
    8000504e:	01590633          	add	a2,s2,s5
    80005052:	f9f40593          	addi	a1,s0,-97
    80005056:	0509b503          	ld	a0,80(s3)
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	7ec080e7          	jalr	2028(ra) # 80001846 <copyin>
    80005062:	fb6514e3          	bne	a0,s6,8000500a <pipewrite+0x88>
  wakeup(&pi->nread);
    80005066:	21848513          	addi	a0,s1,536
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	358080e7          	jalr	856(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80005072:	8526                	mv	a0,s1
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	d1e080e7          	jalr	-738(ra) # 80000d92 <release>
  return i;
    8000507c:	bfa9                	j	80004fd6 <pipewrite+0x54>
  int i = 0;
    8000507e:	4901                	li	s2,0
    80005080:	b7dd                	j	80005066 <pipewrite+0xe4>

0000000080005082 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005082:	715d                	addi	sp,sp,-80
    80005084:	e486                	sd	ra,72(sp)
    80005086:	e0a2                	sd	s0,64(sp)
    80005088:	fc26                	sd	s1,56(sp)
    8000508a:	f84a                	sd	s2,48(sp)
    8000508c:	f44e                	sd	s3,40(sp)
    8000508e:	f052                	sd	s4,32(sp)
    80005090:	ec56                	sd	s5,24(sp)
    80005092:	e85a                	sd	s6,16(sp)
    80005094:	0880                	addi	s0,sp,80
    80005096:	84aa                	mv	s1,a0
    80005098:	892e                	mv	s2,a1
    8000509a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	b5e080e7          	jalr	-1186(ra) # 80001bfa <myproc>
    800050a4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050a6:	8b26                	mv	s6,s1
    800050a8:	8526                	mv	a0,s1
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	c34080e7          	jalr	-972(ra) # 80000cde <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050b2:	2184a703          	lw	a4,536(s1)
    800050b6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050ba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050be:	02f71763          	bne	a4,a5,800050ec <piperead+0x6a>
    800050c2:	2244a783          	lw	a5,548(s1)
    800050c6:	c39d                	beqz	a5,800050ec <piperead+0x6a>
    if(killed(pr)){
    800050c8:	8552                	mv	a0,s4
    800050ca:	ffffd097          	auipc	ra,0xffffd
    800050ce:	53c080e7          	jalr	1340(ra) # 80002606 <killed>
    800050d2:	e941                	bnez	a0,80005162 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d4:	85da                	mv	a1,s6
    800050d6:	854e                	mv	a0,s3
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	286080e7          	jalr	646(ra) # 8000235e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050e0:	2184a703          	lw	a4,536(s1)
    800050e4:	21c4a783          	lw	a5,540(s1)
    800050e8:	fcf70de3          	beq	a4,a5,800050c2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ec:	09505263          	blez	s5,80005170 <piperead+0xee>
    800050f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050f2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050f4:	2184a783          	lw	a5,536(s1)
    800050f8:	21c4a703          	lw	a4,540(s1)
    800050fc:	02f70d63          	beq	a4,a5,80005136 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005100:	0017871b          	addiw	a4,a5,1
    80005104:	20e4ac23          	sw	a4,536(s1)
    80005108:	1ff7f793          	andi	a5,a5,511
    8000510c:	97a6                	add	a5,a5,s1
    8000510e:	0187c783          	lbu	a5,24(a5)
    80005112:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005116:	4685                	li	a3,1
    80005118:	fbf40613          	addi	a2,s0,-65
    8000511c:	85ca                	mv	a1,s2
    8000511e:	050a3503          	ld	a0,80(s4)
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	698080e7          	jalr	1688(ra) # 800017ba <copyout>
    8000512a:	01650663          	beq	a0,s6,80005136 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000512e:	2985                	addiw	s3,s3,1
    80005130:	0905                	addi	s2,s2,1
    80005132:	fd3a91e3          	bne	s5,s3,800050f4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005136:	21c48513          	addi	a0,s1,540
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	288080e7          	jalr	648(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	c4e080e7          	jalr	-946(ra) # 80000d92 <release>
  return i;
}
    8000514c:	854e                	mv	a0,s3
    8000514e:	60a6                	ld	ra,72(sp)
    80005150:	6406                	ld	s0,64(sp)
    80005152:	74e2                	ld	s1,56(sp)
    80005154:	7942                	ld	s2,48(sp)
    80005156:	79a2                	ld	s3,40(sp)
    80005158:	7a02                	ld	s4,32(sp)
    8000515a:	6ae2                	ld	s5,24(sp)
    8000515c:	6b42                	ld	s6,16(sp)
    8000515e:	6161                	addi	sp,sp,80
    80005160:	8082                	ret
      release(&pi->lock);
    80005162:	8526                	mv	a0,s1
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	c2e080e7          	jalr	-978(ra) # 80000d92 <release>
      return -1;
    8000516c:	59fd                	li	s3,-1
    8000516e:	bff9                	j	8000514c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005170:	4981                	li	s3,0
    80005172:	b7d1                	j	80005136 <piperead+0xb4>

0000000080005174 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005174:	1141                	addi	sp,sp,-16
    80005176:	e422                	sd	s0,8(sp)
    80005178:	0800                	addi	s0,sp,16
    8000517a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000517c:	8905                	andi	a0,a0,1
    8000517e:	c111                	beqz	a0,80005182 <flags2perm+0xe>
      perm = PTE_X;
    80005180:	4521                	li	a0,8
    if(flags & 0x2)
    80005182:	8b89                	andi	a5,a5,2
    80005184:	c399                	beqz	a5,8000518a <flags2perm+0x16>
      perm |= PTE_W;
    80005186:	00456513          	ori	a0,a0,4
    return perm;
}
    8000518a:	6422                	ld	s0,8(sp)
    8000518c:	0141                	addi	sp,sp,16
    8000518e:	8082                	ret

0000000080005190 <exec>:

int
exec(char *path, char **argv)
{
    80005190:	df010113          	addi	sp,sp,-528
    80005194:	20113423          	sd	ra,520(sp)
    80005198:	20813023          	sd	s0,512(sp)
    8000519c:	ffa6                	sd	s1,504(sp)
    8000519e:	fbca                	sd	s2,496(sp)
    800051a0:	f7ce                	sd	s3,488(sp)
    800051a2:	f3d2                	sd	s4,480(sp)
    800051a4:	efd6                	sd	s5,472(sp)
    800051a6:	ebda                	sd	s6,464(sp)
    800051a8:	e7de                	sd	s7,456(sp)
    800051aa:	e3e2                	sd	s8,448(sp)
    800051ac:	ff66                	sd	s9,440(sp)
    800051ae:	fb6a                	sd	s10,432(sp)
    800051b0:	f76e                	sd	s11,424(sp)
    800051b2:	0c00                	addi	s0,sp,528
    800051b4:	84aa                	mv	s1,a0
    800051b6:	dea43c23          	sd	a0,-520(s0)
    800051ba:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051be:	ffffd097          	auipc	ra,0xffffd
    800051c2:	a3c080e7          	jalr	-1476(ra) # 80001bfa <myproc>
    800051c6:	892a                	mv	s2,a0

  begin_op();
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	474080e7          	jalr	1140(ra) # 8000463c <begin_op>

  if((ip = namei(path)) == 0){
    800051d0:	8526                	mv	a0,s1
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	24e080e7          	jalr	590(ra) # 80004420 <namei>
    800051da:	c92d                	beqz	a0,8000524c <exec+0xbc>
    800051dc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	a9c080e7          	jalr	-1380(ra) # 80003c7a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051e6:	04000713          	li	a4,64
    800051ea:	4681                	li	a3,0
    800051ec:	e5040613          	addi	a2,s0,-432
    800051f0:	4581                	li	a1,0
    800051f2:	8526                	mv	a0,s1
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	d3a080e7          	jalr	-710(ra) # 80003f2e <readi>
    800051fc:	04000793          	li	a5,64
    80005200:	00f51a63          	bne	a0,a5,80005214 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005204:	e5042703          	lw	a4,-432(s0)
    80005208:	464c47b7          	lui	a5,0x464c4
    8000520c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005210:	04f70463          	beq	a4,a5,80005258 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005214:	8526                	mv	a0,s1
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	cc6080e7          	jalr	-826(ra) # 80003edc <iunlockput>
    end_op();
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	49e080e7          	jalr	1182(ra) # 800046bc <end_op>
  }
  return -1;
    80005226:	557d                	li	a0,-1
}
    80005228:	20813083          	ld	ra,520(sp)
    8000522c:	20013403          	ld	s0,512(sp)
    80005230:	74fe                	ld	s1,504(sp)
    80005232:	795e                	ld	s2,496(sp)
    80005234:	79be                	ld	s3,488(sp)
    80005236:	7a1e                	ld	s4,480(sp)
    80005238:	6afe                	ld	s5,472(sp)
    8000523a:	6b5e                	ld	s6,464(sp)
    8000523c:	6bbe                	ld	s7,456(sp)
    8000523e:	6c1e                	ld	s8,448(sp)
    80005240:	7cfa                	ld	s9,440(sp)
    80005242:	7d5a                	ld	s10,432(sp)
    80005244:	7dba                	ld	s11,424(sp)
    80005246:	21010113          	addi	sp,sp,528
    8000524a:	8082                	ret
    end_op();
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	470080e7          	jalr	1136(ra) # 800046bc <end_op>
    return -1;
    80005254:	557d                	li	a0,-1
    80005256:	bfc9                	j	80005228 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005258:	854a                	mv	a0,s2
    8000525a:	ffffd097          	auipc	ra,0xffffd
    8000525e:	a64080e7          	jalr	-1436(ra) # 80001cbe <proc_pagetable>
    80005262:	8baa                	mv	s7,a0
    80005264:	d945                	beqz	a0,80005214 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005266:	e7042983          	lw	s3,-400(s0)
    8000526a:	e8845783          	lhu	a5,-376(s0)
    8000526e:	c7ad                	beqz	a5,800052d8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005270:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005272:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005274:	6c85                	lui	s9,0x1
    80005276:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000527a:	def43823          	sd	a5,-528(s0)
    8000527e:	ac0d                	j	800054b0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005280:	00003517          	auipc	a0,0x3
    80005284:	5e050513          	addi	a0,a0,1504 # 80008860 <syscalls+0x2a8>
    80005288:	ffffb097          	auipc	ra,0xffffb
    8000528c:	2bc080e7          	jalr	700(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005290:	8756                	mv	a4,s5
    80005292:	012d86bb          	addw	a3,s11,s2
    80005296:	4581                	li	a1,0
    80005298:	8526                	mv	a0,s1
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	c94080e7          	jalr	-876(ra) # 80003f2e <readi>
    800052a2:	2501                	sext.w	a0,a0
    800052a4:	1aaa9a63          	bne	s5,a0,80005458 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800052a8:	6785                	lui	a5,0x1
    800052aa:	0127893b          	addw	s2,a5,s2
    800052ae:	77fd                	lui	a5,0xfffff
    800052b0:	01478a3b          	addw	s4,a5,s4
    800052b4:	1f897563          	bgeu	s2,s8,8000549e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800052b8:	02091593          	slli	a1,s2,0x20
    800052bc:	9181                	srli	a1,a1,0x20
    800052be:	95ea                	add	a1,a1,s10
    800052c0:	855e                	mv	a0,s7
    800052c2:	ffffc097          	auipc	ra,0xffffc
    800052c6:	eaa080e7          	jalr	-342(ra) # 8000116c <walkaddr>
    800052ca:	862a                	mv	a2,a0
    if(pa == 0)
    800052cc:	d955                	beqz	a0,80005280 <exec+0xf0>
      n = PGSIZE;
    800052ce:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052d0:	fd9a70e3          	bgeu	s4,s9,80005290 <exec+0x100>
      n = sz - i;
    800052d4:	8ad2                	mv	s5,s4
    800052d6:	bf6d                	j	80005290 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052d8:	4a01                	li	s4,0
  iunlockput(ip);
    800052da:	8526                	mv	a0,s1
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	c00080e7          	jalr	-1024(ra) # 80003edc <iunlockput>
  end_op();
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	3d8080e7          	jalr	984(ra) # 800046bc <end_op>
  p = myproc();
    800052ec:	ffffd097          	auipc	ra,0xffffd
    800052f0:	90e080e7          	jalr	-1778(ra) # 80001bfa <myproc>
    800052f4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052f6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052fa:	6785                	lui	a5,0x1
    800052fc:	17fd                	addi	a5,a5,-1
    800052fe:	9a3e                	add	s4,s4,a5
    80005300:	757d                	lui	a0,0xfffff
    80005302:	00aa77b3          	and	a5,s4,a0
    80005306:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000530a:	4691                	li	a3,4
    8000530c:	6609                	lui	a2,0x2
    8000530e:	963e                	add	a2,a2,a5
    80005310:	85be                	mv	a1,a5
    80005312:	855e                	mv	a0,s7
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	20c080e7          	jalr	524(ra) # 80001520 <uvmalloc>
    8000531c:	8b2a                	mv	s6,a0
  ip = 0;
    8000531e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005320:	12050c63          	beqz	a0,80005458 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005324:	75f9                	lui	a1,0xffffe
    80005326:	95aa                	add	a1,a1,a0
    80005328:	855e                	mv	a0,s7
    8000532a:	ffffc097          	auipc	ra,0xffffc
    8000532e:	45e080e7          	jalr	1118(ra) # 80001788 <uvmclear>
  stackbase = sp - PGSIZE;
    80005332:	7c7d                	lui	s8,0xfffff
    80005334:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005336:	e0043783          	ld	a5,-512(s0)
    8000533a:	6388                	ld	a0,0(a5)
    8000533c:	c535                	beqz	a0,800053a8 <exec+0x218>
    8000533e:	e9040993          	addi	s3,s0,-368
    80005342:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005346:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	c16080e7          	jalr	-1002(ra) # 80000f5e <strlen>
    80005350:	2505                	addiw	a0,a0,1
    80005352:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005356:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000535a:	13896663          	bltu	s2,s8,80005486 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000535e:	e0043d83          	ld	s11,-512(s0)
    80005362:	000dba03          	ld	s4,0(s11)
    80005366:	8552                	mv	a0,s4
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	bf6080e7          	jalr	-1034(ra) # 80000f5e <strlen>
    80005370:	0015069b          	addiw	a3,a0,1
    80005374:	8652                	mv	a2,s4
    80005376:	85ca                	mv	a1,s2
    80005378:	855e                	mv	a0,s7
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	440080e7          	jalr	1088(ra) # 800017ba <copyout>
    80005382:	10054663          	bltz	a0,8000548e <exec+0x2fe>
    ustack[argc] = sp;
    80005386:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000538a:	0485                	addi	s1,s1,1
    8000538c:	008d8793          	addi	a5,s11,8
    80005390:	e0f43023          	sd	a5,-512(s0)
    80005394:	008db503          	ld	a0,8(s11)
    80005398:	c911                	beqz	a0,800053ac <exec+0x21c>
    if(argc >= MAXARG)
    8000539a:	09a1                	addi	s3,s3,8
    8000539c:	fb3c96e3          	bne	s9,s3,80005348 <exec+0x1b8>
  sz = sz1;
    800053a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053a4:	4481                	li	s1,0
    800053a6:	a84d                	j	80005458 <exec+0x2c8>
  sp = sz;
    800053a8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800053ac:	00349793          	slli	a5,s1,0x3
    800053b0:	f9040713          	addi	a4,s0,-112
    800053b4:	97ba                	add	a5,a5,a4
    800053b6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053ba:	00148693          	addi	a3,s1,1
    800053be:	068e                	slli	a3,a3,0x3
    800053c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053c8:	01897663          	bgeu	s2,s8,800053d4 <exec+0x244>
  sz = sz1;
    800053cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d0:	4481                	li	s1,0
    800053d2:	a059                	j	80005458 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053d4:	e9040613          	addi	a2,s0,-368
    800053d8:	85ca                	mv	a1,s2
    800053da:	855e                	mv	a0,s7
    800053dc:	ffffc097          	auipc	ra,0xffffc
    800053e0:	3de080e7          	jalr	990(ra) # 800017ba <copyout>
    800053e4:	0a054963          	bltz	a0,80005496 <exec+0x306>
  p->trapframe->a1 = sp;
    800053e8:	058ab783          	ld	a5,88(s5)
    800053ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053f0:	df843783          	ld	a5,-520(s0)
    800053f4:	0007c703          	lbu	a4,0(a5)
    800053f8:	cf11                	beqz	a4,80005414 <exec+0x284>
    800053fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053fc:	02f00693          	li	a3,47
    80005400:	a039                	j	8000540e <exec+0x27e>
      last = s+1;
    80005402:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005406:	0785                	addi	a5,a5,1
    80005408:	fff7c703          	lbu	a4,-1(a5)
    8000540c:	c701                	beqz	a4,80005414 <exec+0x284>
    if(*s == '/')
    8000540e:	fed71ce3          	bne	a4,a3,80005406 <exec+0x276>
    80005412:	bfc5                	j	80005402 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005414:	4641                	li	a2,16
    80005416:	df843583          	ld	a1,-520(s0)
    8000541a:	158a8513          	addi	a0,s5,344
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	b0e080e7          	jalr	-1266(ra) # 80000f2c <safestrcpy>
  oldpagetable = p->pagetable;
    80005426:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000542a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000542e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005432:	058ab783          	ld	a5,88(s5)
    80005436:	e6843703          	ld	a4,-408(s0)
    8000543a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000543c:	058ab783          	ld	a5,88(s5)
    80005440:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005444:	85ea                	mv	a1,s10
    80005446:	ffffd097          	auipc	ra,0xffffd
    8000544a:	914080e7          	jalr	-1772(ra) # 80001d5a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000544e:	0004851b          	sext.w	a0,s1
    80005452:	bbd9                	j	80005228 <exec+0x98>
    80005454:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005458:	e0843583          	ld	a1,-504(s0)
    8000545c:	855e                	mv	a0,s7
    8000545e:	ffffd097          	auipc	ra,0xffffd
    80005462:	8fc080e7          	jalr	-1796(ra) # 80001d5a <proc_freepagetable>
  if(ip){
    80005466:	da0497e3          	bnez	s1,80005214 <exec+0x84>
  return -1;
    8000546a:	557d                	li	a0,-1
    8000546c:	bb75                	j	80005228 <exec+0x98>
    8000546e:	e1443423          	sd	s4,-504(s0)
    80005472:	b7dd                	j	80005458 <exec+0x2c8>
    80005474:	e1443423          	sd	s4,-504(s0)
    80005478:	b7c5                	j	80005458 <exec+0x2c8>
    8000547a:	e1443423          	sd	s4,-504(s0)
    8000547e:	bfe9                	j	80005458 <exec+0x2c8>
    80005480:	e1443423          	sd	s4,-504(s0)
    80005484:	bfd1                	j	80005458 <exec+0x2c8>
  sz = sz1;
    80005486:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000548a:	4481                	li	s1,0
    8000548c:	b7f1                	j	80005458 <exec+0x2c8>
  sz = sz1;
    8000548e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005492:	4481                	li	s1,0
    80005494:	b7d1                	j	80005458 <exec+0x2c8>
  sz = sz1;
    80005496:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000549a:	4481                	li	s1,0
    8000549c:	bf75                	j	80005458 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000549e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054a2:	2b05                	addiw	s6,s6,1
    800054a4:	0389899b          	addiw	s3,s3,56
    800054a8:	e8845783          	lhu	a5,-376(s0)
    800054ac:	e2fb57e3          	bge	s6,a5,800052da <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054b0:	2981                	sext.w	s3,s3
    800054b2:	03800713          	li	a4,56
    800054b6:	86ce                	mv	a3,s3
    800054b8:	e1840613          	addi	a2,s0,-488
    800054bc:	4581                	li	a1,0
    800054be:	8526                	mv	a0,s1
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	a6e080e7          	jalr	-1426(ra) # 80003f2e <readi>
    800054c8:	03800793          	li	a5,56
    800054cc:	f8f514e3          	bne	a0,a5,80005454 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800054d0:	e1842783          	lw	a5,-488(s0)
    800054d4:	4705                	li	a4,1
    800054d6:	fce796e3          	bne	a5,a4,800054a2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800054da:	e4043903          	ld	s2,-448(s0)
    800054de:	e3843783          	ld	a5,-456(s0)
    800054e2:	f8f966e3          	bltu	s2,a5,8000546e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054e6:	e2843783          	ld	a5,-472(s0)
    800054ea:	993e                	add	s2,s2,a5
    800054ec:	f8f964e3          	bltu	s2,a5,80005474 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800054f0:	df043703          	ld	a4,-528(s0)
    800054f4:	8ff9                	and	a5,a5,a4
    800054f6:	f3d1                	bnez	a5,8000547a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054f8:	e1c42503          	lw	a0,-484(s0)
    800054fc:	00000097          	auipc	ra,0x0
    80005500:	c78080e7          	jalr	-904(ra) # 80005174 <flags2perm>
    80005504:	86aa                	mv	a3,a0
    80005506:	864a                	mv	a2,s2
    80005508:	85d2                	mv	a1,s4
    8000550a:	855e                	mv	a0,s7
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	014080e7          	jalr	20(ra) # 80001520 <uvmalloc>
    80005514:	e0a43423          	sd	a0,-504(s0)
    80005518:	d525                	beqz	a0,80005480 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000551a:	e2843d03          	ld	s10,-472(s0)
    8000551e:	e2042d83          	lw	s11,-480(s0)
    80005522:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005526:	f60c0ce3          	beqz	s8,8000549e <exec+0x30e>
    8000552a:	8a62                	mv	s4,s8
    8000552c:	4901                	li	s2,0
    8000552e:	b369                	j	800052b8 <exec+0x128>

0000000080005530 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005530:	7179                	addi	sp,sp,-48
    80005532:	f406                	sd	ra,40(sp)
    80005534:	f022                	sd	s0,32(sp)
    80005536:	ec26                	sd	s1,24(sp)
    80005538:	e84a                	sd	s2,16(sp)
    8000553a:	1800                	addi	s0,sp,48
    8000553c:	892e                	mv	s2,a1
    8000553e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005540:	fdc40593          	addi	a1,s0,-36
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	ab6080e7          	jalr	-1354(ra) # 80002ffa <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000554c:	fdc42703          	lw	a4,-36(s0)
    80005550:	47bd                	li	a5,15
    80005552:	02e7eb63          	bltu	a5,a4,80005588 <argfd+0x58>
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	6a4080e7          	jalr	1700(ra) # 80001bfa <myproc>
    8000555e:	fdc42703          	lw	a4,-36(s0)
    80005562:	01a70793          	addi	a5,a4,26
    80005566:	078e                	slli	a5,a5,0x3
    80005568:	953e                	add	a0,a0,a5
    8000556a:	611c                	ld	a5,0(a0)
    8000556c:	c385                	beqz	a5,8000558c <argfd+0x5c>
    return -1;
  if(pfd)
    8000556e:	00090463          	beqz	s2,80005576 <argfd+0x46>
    *pfd = fd;
    80005572:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005576:	4501                	li	a0,0
  if(pf)
    80005578:	c091                	beqz	s1,8000557c <argfd+0x4c>
    *pf = f;
    8000557a:	e09c                	sd	a5,0(s1)
}
    8000557c:	70a2                	ld	ra,40(sp)
    8000557e:	7402                	ld	s0,32(sp)
    80005580:	64e2                	ld	s1,24(sp)
    80005582:	6942                	ld	s2,16(sp)
    80005584:	6145                	addi	sp,sp,48
    80005586:	8082                	ret
    return -1;
    80005588:	557d                	li	a0,-1
    8000558a:	bfcd                	j	8000557c <argfd+0x4c>
    8000558c:	557d                	li	a0,-1
    8000558e:	b7fd                	j	8000557c <argfd+0x4c>

0000000080005590 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005590:	1101                	addi	sp,sp,-32
    80005592:	ec06                	sd	ra,24(sp)
    80005594:	e822                	sd	s0,16(sp)
    80005596:	e426                	sd	s1,8(sp)
    80005598:	1000                	addi	s0,sp,32
    8000559a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	65e080e7          	jalr	1630(ra) # 80001bfa <myproc>
    800055a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055a6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd51a0>
    800055aa:	4501                	li	a0,0
    800055ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055ae:	6398                	ld	a4,0(a5)
    800055b0:	cb19                	beqz	a4,800055c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055b2:	2505                	addiw	a0,a0,1
    800055b4:	07a1                	addi	a5,a5,8
    800055b6:	fed51ce3          	bne	a0,a3,800055ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055ba:	557d                	li	a0,-1
}
    800055bc:	60e2                	ld	ra,24(sp)
    800055be:	6442                	ld	s0,16(sp)
    800055c0:	64a2                	ld	s1,8(sp)
    800055c2:	6105                	addi	sp,sp,32
    800055c4:	8082                	ret
      p->ofile[fd] = f;
    800055c6:	01a50793          	addi	a5,a0,26
    800055ca:	078e                	slli	a5,a5,0x3
    800055cc:	963e                	add	a2,a2,a5
    800055ce:	e204                	sd	s1,0(a2)
      return fd;
    800055d0:	b7f5                	j	800055bc <fdalloc+0x2c>

00000000800055d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055d2:	715d                	addi	sp,sp,-80
    800055d4:	e486                	sd	ra,72(sp)
    800055d6:	e0a2                	sd	s0,64(sp)
    800055d8:	fc26                	sd	s1,56(sp)
    800055da:	f84a                	sd	s2,48(sp)
    800055dc:	f44e                	sd	s3,40(sp)
    800055de:	f052                	sd	s4,32(sp)
    800055e0:	ec56                	sd	s5,24(sp)
    800055e2:	e85a                	sd	s6,16(sp)
    800055e4:	0880                	addi	s0,sp,80
    800055e6:	8b2e                	mv	s6,a1
    800055e8:	89b2                	mv	s3,a2
    800055ea:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055ec:	fb040593          	addi	a1,s0,-80
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	e4e080e7          	jalr	-434(ra) # 8000443e <nameiparent>
    800055f8:	84aa                	mv	s1,a0
    800055fa:	16050063          	beqz	a0,8000575a <create+0x188>
    return 0;

  ilock(dp);
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	67c080e7          	jalr	1660(ra) # 80003c7a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005606:	4601                	li	a2,0
    80005608:	fb040593          	addi	a1,s0,-80
    8000560c:	8526                	mv	a0,s1
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	b50080e7          	jalr	-1200(ra) # 8000415e <dirlookup>
    80005616:	8aaa                	mv	s5,a0
    80005618:	c931                	beqz	a0,8000566c <create+0x9a>
    iunlockput(dp);
    8000561a:	8526                	mv	a0,s1
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	8c0080e7          	jalr	-1856(ra) # 80003edc <iunlockput>
    ilock(ip);
    80005624:	8556                	mv	a0,s5
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	654080e7          	jalr	1620(ra) # 80003c7a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000562e:	000b059b          	sext.w	a1,s6
    80005632:	4789                	li	a5,2
    80005634:	02f59563          	bne	a1,a5,8000565e <create+0x8c>
    80005638:	044ad783          	lhu	a5,68(s5)
    8000563c:	37f9                	addiw	a5,a5,-2
    8000563e:	17c2                	slli	a5,a5,0x30
    80005640:	93c1                	srli	a5,a5,0x30
    80005642:	4705                	li	a4,1
    80005644:	00f76d63          	bltu	a4,a5,8000565e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005648:	8556                	mv	a0,s5
    8000564a:	60a6                	ld	ra,72(sp)
    8000564c:	6406                	ld	s0,64(sp)
    8000564e:	74e2                	ld	s1,56(sp)
    80005650:	7942                	ld	s2,48(sp)
    80005652:	79a2                	ld	s3,40(sp)
    80005654:	7a02                	ld	s4,32(sp)
    80005656:	6ae2                	ld	s5,24(sp)
    80005658:	6b42                	ld	s6,16(sp)
    8000565a:	6161                	addi	sp,sp,80
    8000565c:	8082                	ret
    iunlockput(ip);
    8000565e:	8556                	mv	a0,s5
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	87c080e7          	jalr	-1924(ra) # 80003edc <iunlockput>
    return 0;
    80005668:	4a81                	li	s5,0
    8000566a:	bff9                	j	80005648 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000566c:	85da                	mv	a1,s6
    8000566e:	4088                	lw	a0,0(s1)
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	46e080e7          	jalr	1134(ra) # 80003ade <ialloc>
    80005678:	8a2a                	mv	s4,a0
    8000567a:	c921                	beqz	a0,800056ca <create+0xf8>
  ilock(ip);
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	5fe080e7          	jalr	1534(ra) # 80003c7a <ilock>
  ip->major = major;
    80005684:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005688:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000568c:	4785                	li	a5,1
    8000568e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005692:	8552                	mv	a0,s4
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	51c080e7          	jalr	1308(ra) # 80003bb0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000569c:	000b059b          	sext.w	a1,s6
    800056a0:	4785                	li	a5,1
    800056a2:	02f58b63          	beq	a1,a5,800056d8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800056a6:	004a2603          	lw	a2,4(s4)
    800056aa:	fb040593          	addi	a1,s0,-80
    800056ae:	8526                	mv	a0,s1
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	cbe080e7          	jalr	-834(ra) # 8000436e <dirlink>
    800056b8:	06054f63          	bltz	a0,80005736 <create+0x164>
  iunlockput(dp);
    800056bc:	8526                	mv	a0,s1
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	81e080e7          	jalr	-2018(ra) # 80003edc <iunlockput>
  return ip;
    800056c6:	8ad2                	mv	s5,s4
    800056c8:	b741                	j	80005648 <create+0x76>
    iunlockput(dp);
    800056ca:	8526                	mv	a0,s1
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	810080e7          	jalr	-2032(ra) # 80003edc <iunlockput>
    return 0;
    800056d4:	8ad2                	mv	s5,s4
    800056d6:	bf8d                	j	80005648 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056d8:	004a2603          	lw	a2,4(s4)
    800056dc:	00003597          	auipc	a1,0x3
    800056e0:	1a458593          	addi	a1,a1,420 # 80008880 <syscalls+0x2c8>
    800056e4:	8552                	mv	a0,s4
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	c88080e7          	jalr	-888(ra) # 8000436e <dirlink>
    800056ee:	04054463          	bltz	a0,80005736 <create+0x164>
    800056f2:	40d0                	lw	a2,4(s1)
    800056f4:	00003597          	auipc	a1,0x3
    800056f8:	19458593          	addi	a1,a1,404 # 80008888 <syscalls+0x2d0>
    800056fc:	8552                	mv	a0,s4
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	c70080e7          	jalr	-912(ra) # 8000436e <dirlink>
    80005706:	02054863          	bltz	a0,80005736 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000570a:	004a2603          	lw	a2,4(s4)
    8000570e:	fb040593          	addi	a1,s0,-80
    80005712:	8526                	mv	a0,s1
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	c5a080e7          	jalr	-934(ra) # 8000436e <dirlink>
    8000571c:	00054d63          	bltz	a0,80005736 <create+0x164>
    dp->nlink++;  // for ".."
    80005720:	04a4d783          	lhu	a5,74(s1)
    80005724:	2785                	addiw	a5,a5,1
    80005726:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	484080e7          	jalr	1156(ra) # 80003bb0 <iupdate>
    80005734:	b761                	j	800056bc <create+0xea>
  ip->nlink = 0;
    80005736:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000573a:	8552                	mv	a0,s4
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	474080e7          	jalr	1140(ra) # 80003bb0 <iupdate>
  iunlockput(ip);
    80005744:	8552                	mv	a0,s4
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	796080e7          	jalr	1942(ra) # 80003edc <iunlockput>
  iunlockput(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	78c080e7          	jalr	1932(ra) # 80003edc <iunlockput>
  return 0;
    80005758:	bdc5                	j	80005648 <create+0x76>
    return 0;
    8000575a:	8aaa                	mv	s5,a0
    8000575c:	b5f5                	j	80005648 <create+0x76>

000000008000575e <sys_dup>:
{
    8000575e:	7179                	addi	sp,sp,-48
    80005760:	f406                	sd	ra,40(sp)
    80005762:	f022                	sd	s0,32(sp)
    80005764:	ec26                	sd	s1,24(sp)
    80005766:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005768:	fd840613          	addi	a2,s0,-40
    8000576c:	4581                	li	a1,0
    8000576e:	4501                	li	a0,0
    80005770:	00000097          	auipc	ra,0x0
    80005774:	dc0080e7          	jalr	-576(ra) # 80005530 <argfd>
    return -1;
    80005778:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000577a:	02054363          	bltz	a0,800057a0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000577e:	fd843503          	ld	a0,-40(s0)
    80005782:	00000097          	auipc	ra,0x0
    80005786:	e0e080e7          	jalr	-498(ra) # 80005590 <fdalloc>
    8000578a:	84aa                	mv	s1,a0
    return -1;
    8000578c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000578e:	00054963          	bltz	a0,800057a0 <sys_dup+0x42>
  filedup(f);
    80005792:	fd843503          	ld	a0,-40(s0)
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	320080e7          	jalr	800(ra) # 80004ab6 <filedup>
  return fd;
    8000579e:	87a6                	mv	a5,s1
}
    800057a0:	853e                	mv	a0,a5
    800057a2:	70a2                	ld	ra,40(sp)
    800057a4:	7402                	ld	s0,32(sp)
    800057a6:	64e2                	ld	s1,24(sp)
    800057a8:	6145                	addi	sp,sp,48
    800057aa:	8082                	ret

00000000800057ac <sys_read>:
{
    800057ac:	7179                	addi	sp,sp,-48
    800057ae:	f406                	sd	ra,40(sp)
    800057b0:	f022                	sd	s0,32(sp)
    800057b2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057b4:	fd840593          	addi	a1,s0,-40
    800057b8:	4505                	li	a0,1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	860080e7          	jalr	-1952(ra) # 8000301a <argaddr>
  argint(2, &n);
    800057c2:	fe440593          	addi	a1,s0,-28
    800057c6:	4509                	li	a0,2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	832080e7          	jalr	-1998(ra) # 80002ffa <argint>
  if(argfd(0, 0, &f) < 0)
    800057d0:	fe840613          	addi	a2,s0,-24
    800057d4:	4581                	li	a1,0
    800057d6:	4501                	li	a0,0
    800057d8:	00000097          	auipc	ra,0x0
    800057dc:	d58080e7          	jalr	-680(ra) # 80005530 <argfd>
    800057e0:	87aa                	mv	a5,a0
    return -1;
    800057e2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057e4:	0007cc63          	bltz	a5,800057fc <sys_read+0x50>
  return fileread(f, p, n);
    800057e8:	fe442603          	lw	a2,-28(s0)
    800057ec:	fd843583          	ld	a1,-40(s0)
    800057f0:	fe843503          	ld	a0,-24(s0)
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	44e080e7          	jalr	1102(ra) # 80004c42 <fileread>
}
    800057fc:	70a2                	ld	ra,40(sp)
    800057fe:	7402                	ld	s0,32(sp)
    80005800:	6145                	addi	sp,sp,48
    80005802:	8082                	ret

0000000080005804 <sys_write>:
{
    80005804:	7179                	addi	sp,sp,-48
    80005806:	f406                	sd	ra,40(sp)
    80005808:	f022                	sd	s0,32(sp)
    8000580a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000580c:	fd840593          	addi	a1,s0,-40
    80005810:	4505                	li	a0,1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	808080e7          	jalr	-2040(ra) # 8000301a <argaddr>
  argint(2, &n);
    8000581a:	fe440593          	addi	a1,s0,-28
    8000581e:	4509                	li	a0,2
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	7da080e7          	jalr	2010(ra) # 80002ffa <argint>
  if(argfd(0, 0, &f) < 0)
    80005828:	fe840613          	addi	a2,s0,-24
    8000582c:	4581                	li	a1,0
    8000582e:	4501                	li	a0,0
    80005830:	00000097          	auipc	ra,0x0
    80005834:	d00080e7          	jalr	-768(ra) # 80005530 <argfd>
    80005838:	87aa                	mv	a5,a0
    return -1;
    8000583a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000583c:	0007cc63          	bltz	a5,80005854 <sys_write+0x50>
  return filewrite(f, p, n);
    80005840:	fe442603          	lw	a2,-28(s0)
    80005844:	fd843583          	ld	a1,-40(s0)
    80005848:	fe843503          	ld	a0,-24(s0)
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	4b8080e7          	jalr	1208(ra) # 80004d04 <filewrite>
}
    80005854:	70a2                	ld	ra,40(sp)
    80005856:	7402                	ld	s0,32(sp)
    80005858:	6145                	addi	sp,sp,48
    8000585a:	8082                	ret

000000008000585c <sys_close>:
{
    8000585c:	1101                	addi	sp,sp,-32
    8000585e:	ec06                	sd	ra,24(sp)
    80005860:	e822                	sd	s0,16(sp)
    80005862:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005864:	fe040613          	addi	a2,s0,-32
    80005868:	fec40593          	addi	a1,s0,-20
    8000586c:	4501                	li	a0,0
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	cc2080e7          	jalr	-830(ra) # 80005530 <argfd>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005878:	02054463          	bltz	a0,800058a0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	37e080e7          	jalr	894(ra) # 80001bfa <myproc>
    80005884:	fec42783          	lw	a5,-20(s0)
    80005888:	07e9                	addi	a5,a5,26
    8000588a:	078e                	slli	a5,a5,0x3
    8000588c:	97aa                	add	a5,a5,a0
    8000588e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005892:	fe043503          	ld	a0,-32(s0)
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	272080e7          	jalr	626(ra) # 80004b08 <fileclose>
  return 0;
    8000589e:	4781                	li	a5,0
}
    800058a0:	853e                	mv	a0,a5
    800058a2:	60e2                	ld	ra,24(sp)
    800058a4:	6442                	ld	s0,16(sp)
    800058a6:	6105                	addi	sp,sp,32
    800058a8:	8082                	ret

00000000800058aa <sys_fstat>:
{
    800058aa:	1101                	addi	sp,sp,-32
    800058ac:	ec06                	sd	ra,24(sp)
    800058ae:	e822                	sd	s0,16(sp)
    800058b0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058b2:	fe040593          	addi	a1,s0,-32
    800058b6:	4505                	li	a0,1
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	762080e7          	jalr	1890(ra) # 8000301a <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058c0:	fe840613          	addi	a2,s0,-24
    800058c4:	4581                	li	a1,0
    800058c6:	4501                	li	a0,0
    800058c8:	00000097          	auipc	ra,0x0
    800058cc:	c68080e7          	jalr	-920(ra) # 80005530 <argfd>
    800058d0:	87aa                	mv	a5,a0
    return -1;
    800058d2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058d4:	0007ca63          	bltz	a5,800058e8 <sys_fstat+0x3e>
  return filestat(f, st);
    800058d8:	fe043583          	ld	a1,-32(s0)
    800058dc:	fe843503          	ld	a0,-24(s0)
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	2f0080e7          	jalr	752(ra) # 80004bd0 <filestat>
}
    800058e8:	60e2                	ld	ra,24(sp)
    800058ea:	6442                	ld	s0,16(sp)
    800058ec:	6105                	addi	sp,sp,32
    800058ee:	8082                	ret

00000000800058f0 <sys_link>:
{
    800058f0:	7169                	addi	sp,sp,-304
    800058f2:	f606                	sd	ra,296(sp)
    800058f4:	f222                	sd	s0,288(sp)
    800058f6:	ee26                	sd	s1,280(sp)
    800058f8:	ea4a                	sd	s2,272(sp)
    800058fa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fc:	08000613          	li	a2,128
    80005900:	ed040593          	addi	a1,s0,-304
    80005904:	4501                	li	a0,0
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	734080e7          	jalr	1844(ra) # 8000303a <argstr>
    return -1;
    8000590e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005910:	10054e63          	bltz	a0,80005a2c <sys_link+0x13c>
    80005914:	08000613          	li	a2,128
    80005918:	f5040593          	addi	a1,s0,-176
    8000591c:	4505                	li	a0,1
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	71c080e7          	jalr	1820(ra) # 8000303a <argstr>
    return -1;
    80005926:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005928:	10054263          	bltz	a0,80005a2c <sys_link+0x13c>
  begin_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	d10080e7          	jalr	-752(ra) # 8000463c <begin_op>
  if((ip = namei(old)) == 0){
    80005934:	ed040513          	addi	a0,s0,-304
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	ae8080e7          	jalr	-1304(ra) # 80004420 <namei>
    80005940:	84aa                	mv	s1,a0
    80005942:	c551                	beqz	a0,800059ce <sys_link+0xde>
  ilock(ip);
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	336080e7          	jalr	822(ra) # 80003c7a <ilock>
  if(ip->type == T_DIR){
    8000594c:	04449703          	lh	a4,68(s1)
    80005950:	4785                	li	a5,1
    80005952:	08f70463          	beq	a4,a5,800059da <sys_link+0xea>
  ip->nlink++;
    80005956:	04a4d783          	lhu	a5,74(s1)
    8000595a:	2785                	addiw	a5,a5,1
    8000595c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	24e080e7          	jalr	590(ra) # 80003bb0 <iupdate>
  iunlock(ip);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	3d0080e7          	jalr	976(ra) # 80003d3c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005974:	fd040593          	addi	a1,s0,-48
    80005978:	f5040513          	addi	a0,s0,-176
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	ac2080e7          	jalr	-1342(ra) # 8000443e <nameiparent>
    80005984:	892a                	mv	s2,a0
    80005986:	c935                	beqz	a0,800059fa <sys_link+0x10a>
  ilock(dp);
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	2f2080e7          	jalr	754(ra) # 80003c7a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005990:	00092703          	lw	a4,0(s2)
    80005994:	409c                	lw	a5,0(s1)
    80005996:	04f71d63          	bne	a4,a5,800059f0 <sys_link+0x100>
    8000599a:	40d0                	lw	a2,4(s1)
    8000599c:	fd040593          	addi	a1,s0,-48
    800059a0:	854a                	mv	a0,s2
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	9cc080e7          	jalr	-1588(ra) # 8000436e <dirlink>
    800059aa:	04054363          	bltz	a0,800059f0 <sys_link+0x100>
  iunlockput(dp);
    800059ae:	854a                	mv	a0,s2
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	52c080e7          	jalr	1324(ra) # 80003edc <iunlockput>
  iput(ip);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	47a080e7          	jalr	1146(ra) # 80003e34 <iput>
  end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	cfa080e7          	jalr	-774(ra) # 800046bc <end_op>
  return 0;
    800059ca:	4781                	li	a5,0
    800059cc:	a085                	j	80005a2c <sys_link+0x13c>
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	cee080e7          	jalr	-786(ra) # 800046bc <end_op>
    return -1;
    800059d6:	57fd                	li	a5,-1
    800059d8:	a891                	j	80005a2c <sys_link+0x13c>
    iunlockput(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	500080e7          	jalr	1280(ra) # 80003edc <iunlockput>
    end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	cd8080e7          	jalr	-808(ra) # 800046bc <end_op>
    return -1;
    800059ec:	57fd                	li	a5,-1
    800059ee:	a83d                	j	80005a2c <sys_link+0x13c>
    iunlockput(dp);
    800059f0:	854a                	mv	a0,s2
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	4ea080e7          	jalr	1258(ra) # 80003edc <iunlockput>
  ilock(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	27e080e7          	jalr	638(ra) # 80003c7a <ilock>
  ip->nlink--;
    80005a04:	04a4d783          	lhu	a5,74(s1)
    80005a08:	37fd                	addiw	a5,a5,-1
    80005a0a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	1a0080e7          	jalr	416(ra) # 80003bb0 <iupdate>
  iunlockput(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	4c2080e7          	jalr	1218(ra) # 80003edc <iunlockput>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	c9a080e7          	jalr	-870(ra) # 800046bc <end_op>
  return -1;
    80005a2a:	57fd                	li	a5,-1
}
    80005a2c:	853e                	mv	a0,a5
    80005a2e:	70b2                	ld	ra,296(sp)
    80005a30:	7412                	ld	s0,288(sp)
    80005a32:	64f2                	ld	s1,280(sp)
    80005a34:	6952                	ld	s2,272(sp)
    80005a36:	6155                	addi	sp,sp,304
    80005a38:	8082                	ret

0000000080005a3a <sys_unlink>:
{
    80005a3a:	7151                	addi	sp,sp,-240
    80005a3c:	f586                	sd	ra,232(sp)
    80005a3e:	f1a2                	sd	s0,224(sp)
    80005a40:	eda6                	sd	s1,216(sp)
    80005a42:	e9ca                	sd	s2,208(sp)
    80005a44:	e5ce                	sd	s3,200(sp)
    80005a46:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a48:	08000613          	li	a2,128
    80005a4c:	f3040593          	addi	a1,s0,-208
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	5e8080e7          	jalr	1512(ra) # 8000303a <argstr>
    80005a5a:	18054163          	bltz	a0,80005bdc <sys_unlink+0x1a2>
  begin_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	bde080e7          	jalr	-1058(ra) # 8000463c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a66:	fb040593          	addi	a1,s0,-80
    80005a6a:	f3040513          	addi	a0,s0,-208
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	9d0080e7          	jalr	-1584(ra) # 8000443e <nameiparent>
    80005a76:	84aa                	mv	s1,a0
    80005a78:	c979                	beqz	a0,80005b4e <sys_unlink+0x114>
  ilock(dp);
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	200080e7          	jalr	512(ra) # 80003c7a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a82:	00003597          	auipc	a1,0x3
    80005a86:	dfe58593          	addi	a1,a1,-514 # 80008880 <syscalls+0x2c8>
    80005a8a:	fb040513          	addi	a0,s0,-80
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	6b6080e7          	jalr	1718(ra) # 80004144 <namecmp>
    80005a96:	14050a63          	beqz	a0,80005bea <sys_unlink+0x1b0>
    80005a9a:	00003597          	auipc	a1,0x3
    80005a9e:	dee58593          	addi	a1,a1,-530 # 80008888 <syscalls+0x2d0>
    80005aa2:	fb040513          	addi	a0,s0,-80
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	69e080e7          	jalr	1694(ra) # 80004144 <namecmp>
    80005aae:	12050e63          	beqz	a0,80005bea <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ab2:	f2c40613          	addi	a2,s0,-212
    80005ab6:	fb040593          	addi	a1,s0,-80
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	6a2080e7          	jalr	1698(ra) # 8000415e <dirlookup>
    80005ac4:	892a                	mv	s2,a0
    80005ac6:	12050263          	beqz	a0,80005bea <sys_unlink+0x1b0>
  ilock(ip);
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	1b0080e7          	jalr	432(ra) # 80003c7a <ilock>
  if(ip->nlink < 1)
    80005ad2:	04a91783          	lh	a5,74(s2)
    80005ad6:	08f05263          	blez	a5,80005b5a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ada:	04491703          	lh	a4,68(s2)
    80005ade:	4785                	li	a5,1
    80005ae0:	08f70563          	beq	a4,a5,80005b6a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ae4:	4641                	li	a2,16
    80005ae6:	4581                	li	a1,0
    80005ae8:	fc040513          	addi	a0,s0,-64
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	2ee080e7          	jalr	750(ra) # 80000dda <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005af4:	4741                	li	a4,16
    80005af6:	f2c42683          	lw	a3,-212(s0)
    80005afa:	fc040613          	addi	a2,s0,-64
    80005afe:	4581                	li	a1,0
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	524080e7          	jalr	1316(ra) # 80004026 <writei>
    80005b0a:	47c1                	li	a5,16
    80005b0c:	0af51563          	bne	a0,a5,80005bb6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b10:	04491703          	lh	a4,68(s2)
    80005b14:	4785                	li	a5,1
    80005b16:	0af70863          	beq	a4,a5,80005bc6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	3c0080e7          	jalr	960(ra) # 80003edc <iunlockput>
  ip->nlink--;
    80005b24:	04a95783          	lhu	a5,74(s2)
    80005b28:	37fd                	addiw	a5,a5,-1
    80005b2a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b2e:	854a                	mv	a0,s2
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	080080e7          	jalr	128(ra) # 80003bb0 <iupdate>
  iunlockput(ip);
    80005b38:	854a                	mv	a0,s2
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	3a2080e7          	jalr	930(ra) # 80003edc <iunlockput>
  end_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	b7a080e7          	jalr	-1158(ra) # 800046bc <end_op>
  return 0;
    80005b4a:	4501                	li	a0,0
    80005b4c:	a84d                	j	80005bfe <sys_unlink+0x1c4>
    end_op();
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	b6e080e7          	jalr	-1170(ra) # 800046bc <end_op>
    return -1;
    80005b56:	557d                	li	a0,-1
    80005b58:	a05d                	j	80005bfe <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b5a:	00003517          	auipc	a0,0x3
    80005b5e:	d3650513          	addi	a0,a0,-714 # 80008890 <syscalls+0x2d8>
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	9e2080e7          	jalr	-1566(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b6a:	04c92703          	lw	a4,76(s2)
    80005b6e:	02000793          	li	a5,32
    80005b72:	f6e7f9e3          	bgeu	a5,a4,80005ae4 <sys_unlink+0xaa>
    80005b76:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b7a:	4741                	li	a4,16
    80005b7c:	86ce                	mv	a3,s3
    80005b7e:	f1840613          	addi	a2,s0,-232
    80005b82:	4581                	li	a1,0
    80005b84:	854a                	mv	a0,s2
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	3a8080e7          	jalr	936(ra) # 80003f2e <readi>
    80005b8e:	47c1                	li	a5,16
    80005b90:	00f51b63          	bne	a0,a5,80005ba6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b94:	f1845783          	lhu	a5,-232(s0)
    80005b98:	e7a1                	bnez	a5,80005be0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b9a:	29c1                	addiw	s3,s3,16
    80005b9c:	04c92783          	lw	a5,76(s2)
    80005ba0:	fcf9ede3          	bltu	s3,a5,80005b7a <sys_unlink+0x140>
    80005ba4:	b781                	j	80005ae4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ba6:	00003517          	auipc	a0,0x3
    80005baa:	d0250513          	addi	a0,a0,-766 # 800088a8 <syscalls+0x2f0>
    80005bae:	ffffb097          	auipc	ra,0xffffb
    80005bb2:	996080e7          	jalr	-1642(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005bb6:	00003517          	auipc	a0,0x3
    80005bba:	d0a50513          	addi	a0,a0,-758 # 800088c0 <syscalls+0x308>
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	986080e7          	jalr	-1658(ra) # 80000544 <panic>
    dp->nlink--;
    80005bc6:	04a4d783          	lhu	a5,74(s1)
    80005bca:	37fd                	addiw	a5,a5,-1
    80005bcc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	fde080e7          	jalr	-34(ra) # 80003bb0 <iupdate>
    80005bda:	b781                	j	80005b1a <sys_unlink+0xe0>
    return -1;
    80005bdc:	557d                	li	a0,-1
    80005bde:	a005                	j	80005bfe <sys_unlink+0x1c4>
    iunlockput(ip);
    80005be0:	854a                	mv	a0,s2
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	2fa080e7          	jalr	762(ra) # 80003edc <iunlockput>
  iunlockput(dp);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	2f0080e7          	jalr	752(ra) # 80003edc <iunlockput>
  end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	ac8080e7          	jalr	-1336(ra) # 800046bc <end_op>
  return -1;
    80005bfc:	557d                	li	a0,-1
}
    80005bfe:	70ae                	ld	ra,232(sp)
    80005c00:	740e                	ld	s0,224(sp)
    80005c02:	64ee                	ld	s1,216(sp)
    80005c04:	694e                	ld	s2,208(sp)
    80005c06:	69ae                	ld	s3,200(sp)
    80005c08:	616d                	addi	sp,sp,240
    80005c0a:	8082                	ret

0000000080005c0c <sys_open>:

uint64
sys_open(void)
{
    80005c0c:	7131                	addi	sp,sp,-192
    80005c0e:	fd06                	sd	ra,184(sp)
    80005c10:	f922                	sd	s0,176(sp)
    80005c12:	f526                	sd	s1,168(sp)
    80005c14:	f14a                	sd	s2,160(sp)
    80005c16:	ed4e                	sd	s3,152(sp)
    80005c18:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c1a:	f4c40593          	addi	a1,s0,-180
    80005c1e:	4505                	li	a0,1
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	3da080e7          	jalr	986(ra) # 80002ffa <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c28:	08000613          	li	a2,128
    80005c2c:	f5040593          	addi	a1,s0,-176
    80005c30:	4501                	li	a0,0
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	408080e7          	jalr	1032(ra) # 8000303a <argstr>
    80005c3a:	87aa                	mv	a5,a0
    return -1;
    80005c3c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c3e:	0a07c963          	bltz	a5,80005cf0 <sys_open+0xe4>

  begin_op();
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	9fa080e7          	jalr	-1542(ra) # 8000463c <begin_op>

  if(omode & O_CREATE){
    80005c4a:	f4c42783          	lw	a5,-180(s0)
    80005c4e:	2007f793          	andi	a5,a5,512
    80005c52:	cfc5                	beqz	a5,80005d0a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c54:	4681                	li	a3,0
    80005c56:	4601                	li	a2,0
    80005c58:	4589                	li	a1,2
    80005c5a:	f5040513          	addi	a0,s0,-176
    80005c5e:	00000097          	auipc	ra,0x0
    80005c62:	974080e7          	jalr	-1676(ra) # 800055d2 <create>
    80005c66:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c68:	c959                	beqz	a0,80005cfe <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c6a:	04449703          	lh	a4,68(s1)
    80005c6e:	478d                	li	a5,3
    80005c70:	00f71763          	bne	a4,a5,80005c7e <sys_open+0x72>
    80005c74:	0464d703          	lhu	a4,70(s1)
    80005c78:	47a5                	li	a5,9
    80005c7a:	0ce7ed63          	bltu	a5,a4,80005d54 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	dce080e7          	jalr	-562(ra) # 80004a4c <filealloc>
    80005c86:	89aa                	mv	s3,a0
    80005c88:	10050363          	beqz	a0,80005d8e <sys_open+0x182>
    80005c8c:	00000097          	auipc	ra,0x0
    80005c90:	904080e7          	jalr	-1788(ra) # 80005590 <fdalloc>
    80005c94:	892a                	mv	s2,a0
    80005c96:	0e054763          	bltz	a0,80005d84 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c9a:	04449703          	lh	a4,68(s1)
    80005c9e:	478d                	li	a5,3
    80005ca0:	0cf70563          	beq	a4,a5,80005d6a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ca4:	4789                	li	a5,2
    80005ca6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005caa:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cae:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cb2:	f4c42783          	lw	a5,-180(s0)
    80005cb6:	0017c713          	xori	a4,a5,1
    80005cba:	8b05                	andi	a4,a4,1
    80005cbc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cc0:	0037f713          	andi	a4,a5,3
    80005cc4:	00e03733          	snez	a4,a4
    80005cc8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ccc:	4007f793          	andi	a5,a5,1024
    80005cd0:	c791                	beqz	a5,80005cdc <sys_open+0xd0>
    80005cd2:	04449703          	lh	a4,68(s1)
    80005cd6:	4789                	li	a5,2
    80005cd8:	0af70063          	beq	a4,a5,80005d78 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	05e080e7          	jalr	94(ra) # 80003d3c <iunlock>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	9d6080e7          	jalr	-1578(ra) # 800046bc <end_op>

  return fd;
    80005cee:	854a                	mv	a0,s2
}
    80005cf0:	70ea                	ld	ra,184(sp)
    80005cf2:	744a                	ld	s0,176(sp)
    80005cf4:	74aa                	ld	s1,168(sp)
    80005cf6:	790a                	ld	s2,160(sp)
    80005cf8:	69ea                	ld	s3,152(sp)
    80005cfa:	6129                	addi	sp,sp,192
    80005cfc:	8082                	ret
      end_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	9be080e7          	jalr	-1602(ra) # 800046bc <end_op>
      return -1;
    80005d06:	557d                	li	a0,-1
    80005d08:	b7e5                	j	80005cf0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d0a:	f5040513          	addi	a0,s0,-176
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	712080e7          	jalr	1810(ra) # 80004420 <namei>
    80005d16:	84aa                	mv	s1,a0
    80005d18:	c905                	beqz	a0,80005d48 <sys_open+0x13c>
    ilock(ip);
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	f60080e7          	jalr	-160(ra) # 80003c7a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d22:	04449703          	lh	a4,68(s1)
    80005d26:	4785                	li	a5,1
    80005d28:	f4f711e3          	bne	a4,a5,80005c6a <sys_open+0x5e>
    80005d2c:	f4c42783          	lw	a5,-180(s0)
    80005d30:	d7b9                	beqz	a5,80005c7e <sys_open+0x72>
      iunlockput(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	1a8080e7          	jalr	424(ra) # 80003edc <iunlockput>
      end_op();
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	980080e7          	jalr	-1664(ra) # 800046bc <end_op>
      return -1;
    80005d44:	557d                	li	a0,-1
    80005d46:	b76d                	j	80005cf0 <sys_open+0xe4>
      end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	974080e7          	jalr	-1676(ra) # 800046bc <end_op>
      return -1;
    80005d50:	557d                	li	a0,-1
    80005d52:	bf79                	j	80005cf0 <sys_open+0xe4>
    iunlockput(ip);
    80005d54:	8526                	mv	a0,s1
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	186080e7          	jalr	390(ra) # 80003edc <iunlockput>
    end_op();
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	95e080e7          	jalr	-1698(ra) # 800046bc <end_op>
    return -1;
    80005d66:	557d                	li	a0,-1
    80005d68:	b761                	j	80005cf0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d6a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d6e:	04649783          	lh	a5,70(s1)
    80005d72:	02f99223          	sh	a5,36(s3)
    80005d76:	bf25                	j	80005cae <sys_open+0xa2>
    itrunc(ip);
    80005d78:	8526                	mv	a0,s1
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	00e080e7          	jalr	14(ra) # 80003d88 <itrunc>
    80005d82:	bfa9                	j	80005cdc <sys_open+0xd0>
      fileclose(f);
    80005d84:	854e                	mv	a0,s3
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	d82080e7          	jalr	-638(ra) # 80004b08 <fileclose>
    iunlockput(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	14c080e7          	jalr	332(ra) # 80003edc <iunlockput>
    end_op();
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	924080e7          	jalr	-1756(ra) # 800046bc <end_op>
    return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	b7b9                	j	80005cf0 <sys_open+0xe4>

0000000080005da4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005da4:	7175                	addi	sp,sp,-144
    80005da6:	e506                	sd	ra,136(sp)
    80005da8:	e122                	sd	s0,128(sp)
    80005daa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	890080e7          	jalr	-1904(ra) # 8000463c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005db4:	08000613          	li	a2,128
    80005db8:	f7040593          	addi	a1,s0,-144
    80005dbc:	4501                	li	a0,0
    80005dbe:	ffffd097          	auipc	ra,0xffffd
    80005dc2:	27c080e7          	jalr	636(ra) # 8000303a <argstr>
    80005dc6:	02054963          	bltz	a0,80005df8 <sys_mkdir+0x54>
    80005dca:	4681                	li	a3,0
    80005dcc:	4601                	li	a2,0
    80005dce:	4585                	li	a1,1
    80005dd0:	f7040513          	addi	a0,s0,-144
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	7fe080e7          	jalr	2046(ra) # 800055d2 <create>
    80005ddc:	cd11                	beqz	a0,80005df8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	0fe080e7          	jalr	254(ra) # 80003edc <iunlockput>
  end_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	8d6080e7          	jalr	-1834(ra) # 800046bc <end_op>
  return 0;
    80005dee:	4501                	li	a0,0
}
    80005df0:	60aa                	ld	ra,136(sp)
    80005df2:	640a                	ld	s0,128(sp)
    80005df4:	6149                	addi	sp,sp,144
    80005df6:	8082                	ret
    end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	8c4080e7          	jalr	-1852(ra) # 800046bc <end_op>
    return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	b7fd                	j	80005df0 <sys_mkdir+0x4c>

0000000080005e04 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e04:	7135                	addi	sp,sp,-160
    80005e06:	ed06                	sd	ra,152(sp)
    80005e08:	e922                	sd	s0,144(sp)
    80005e0a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	830080e7          	jalr	-2000(ra) # 8000463c <begin_op>
  argint(1, &major);
    80005e14:	f6c40593          	addi	a1,s0,-148
    80005e18:	4505                	li	a0,1
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	1e0080e7          	jalr	480(ra) # 80002ffa <argint>
  argint(2, &minor);
    80005e22:	f6840593          	addi	a1,s0,-152
    80005e26:	4509                	li	a0,2
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	1d2080e7          	jalr	466(ra) # 80002ffa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e30:	08000613          	li	a2,128
    80005e34:	f7040593          	addi	a1,s0,-144
    80005e38:	4501                	li	a0,0
    80005e3a:	ffffd097          	auipc	ra,0xffffd
    80005e3e:	200080e7          	jalr	512(ra) # 8000303a <argstr>
    80005e42:	02054b63          	bltz	a0,80005e78 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e46:	f6841683          	lh	a3,-152(s0)
    80005e4a:	f6c41603          	lh	a2,-148(s0)
    80005e4e:	458d                	li	a1,3
    80005e50:	f7040513          	addi	a0,s0,-144
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	77e080e7          	jalr	1918(ra) # 800055d2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e5c:	cd11                	beqz	a0,80005e78 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	07e080e7          	jalr	126(ra) # 80003edc <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	856080e7          	jalr	-1962(ra) # 800046bc <end_op>
  return 0;
    80005e6e:	4501                	li	a0,0
}
    80005e70:	60ea                	ld	ra,152(sp)
    80005e72:	644a                	ld	s0,144(sp)
    80005e74:	610d                	addi	sp,sp,160
    80005e76:	8082                	ret
    end_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	844080e7          	jalr	-1980(ra) # 800046bc <end_op>
    return -1;
    80005e80:	557d                	li	a0,-1
    80005e82:	b7fd                	j	80005e70 <sys_mknod+0x6c>

0000000080005e84 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e84:	7135                	addi	sp,sp,-160
    80005e86:	ed06                	sd	ra,152(sp)
    80005e88:	e922                	sd	s0,144(sp)
    80005e8a:	e526                	sd	s1,136(sp)
    80005e8c:	e14a                	sd	s2,128(sp)
    80005e8e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	d6a080e7          	jalr	-662(ra) # 80001bfa <myproc>
    80005e98:	892a                	mv	s2,a0
  
  begin_op();
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	7a2080e7          	jalr	1954(ra) # 8000463c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ea2:	08000613          	li	a2,128
    80005ea6:	f6040593          	addi	a1,s0,-160
    80005eaa:	4501                	li	a0,0
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	18e080e7          	jalr	398(ra) # 8000303a <argstr>
    80005eb4:	04054b63          	bltz	a0,80005f0a <sys_chdir+0x86>
    80005eb8:	f6040513          	addi	a0,s0,-160
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	564080e7          	jalr	1380(ra) # 80004420 <namei>
    80005ec4:	84aa                	mv	s1,a0
    80005ec6:	c131                	beqz	a0,80005f0a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	db2080e7          	jalr	-590(ra) # 80003c7a <ilock>
  if(ip->type != T_DIR){
    80005ed0:	04449703          	lh	a4,68(s1)
    80005ed4:	4785                	li	a5,1
    80005ed6:	04f71063          	bne	a4,a5,80005f16 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	e60080e7          	jalr	-416(ra) # 80003d3c <iunlock>
  iput(p->cwd);
    80005ee4:	15093503          	ld	a0,336(s2)
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	f4c080e7          	jalr	-180(ra) # 80003e34 <iput>
  end_op();
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	7cc080e7          	jalr	1996(ra) # 800046bc <end_op>
  p->cwd = ip;
    80005ef8:	14993823          	sd	s1,336(s2)
  return 0;
    80005efc:	4501                	li	a0,0
}
    80005efe:	60ea                	ld	ra,152(sp)
    80005f00:	644a                	ld	s0,144(sp)
    80005f02:	64aa                	ld	s1,136(sp)
    80005f04:	690a                	ld	s2,128(sp)
    80005f06:	610d                	addi	sp,sp,160
    80005f08:	8082                	ret
    end_op();
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	7b2080e7          	jalr	1970(ra) # 800046bc <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	b7ed                	j	80005efe <sys_chdir+0x7a>
    iunlockput(ip);
    80005f16:	8526                	mv	a0,s1
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	fc4080e7          	jalr	-60(ra) # 80003edc <iunlockput>
    end_op();
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	79c080e7          	jalr	1948(ra) # 800046bc <end_op>
    return -1;
    80005f28:	557d                	li	a0,-1
    80005f2a:	bfd1                	j	80005efe <sys_chdir+0x7a>

0000000080005f2c <sys_exec>:

uint64
sys_exec(void)
{
    80005f2c:	7145                	addi	sp,sp,-464
    80005f2e:	e786                	sd	ra,456(sp)
    80005f30:	e3a2                	sd	s0,448(sp)
    80005f32:	ff26                	sd	s1,440(sp)
    80005f34:	fb4a                	sd	s2,432(sp)
    80005f36:	f74e                	sd	s3,424(sp)
    80005f38:	f352                	sd	s4,416(sp)
    80005f3a:	ef56                	sd	s5,408(sp)
    80005f3c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f3e:	e3840593          	addi	a1,s0,-456
    80005f42:	4505                	li	a0,1
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	0d6080e7          	jalr	214(ra) # 8000301a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f4c:	08000613          	li	a2,128
    80005f50:	f4040593          	addi	a1,s0,-192
    80005f54:	4501                	li	a0,0
    80005f56:	ffffd097          	auipc	ra,0xffffd
    80005f5a:	0e4080e7          	jalr	228(ra) # 8000303a <argstr>
    80005f5e:	87aa                	mv	a5,a0
    return -1;
    80005f60:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f62:	0c07c263          	bltz	a5,80006026 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f66:	10000613          	li	a2,256
    80005f6a:	4581                	li	a1,0
    80005f6c:	e4040513          	addi	a0,s0,-448
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	e6a080e7          	jalr	-406(ra) # 80000dda <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f7c:	89a6                	mv	s3,s1
    80005f7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f80:	02000a13          	li	s4,32
    80005f84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f88:	00391513          	slli	a0,s2,0x3
    80005f8c:	e3040593          	addi	a1,s0,-464
    80005f90:	e3843783          	ld	a5,-456(s0)
    80005f94:	953e                	add	a0,a0,a5
    80005f96:	ffffd097          	auipc	ra,0xffffd
    80005f9a:	fc6080e7          	jalr	-58(ra) # 80002f5c <fetchaddr>
    80005f9e:	02054a63          	bltz	a0,80005fd2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005fa2:	e3043783          	ld	a5,-464(s0)
    80005fa6:	c3b9                	beqz	a5,80005fec <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fa8:	ffffb097          	auipc	ra,0xffffb
    80005fac:	bfa080e7          	jalr	-1030(ra) # 80000ba2 <kalloc>
    80005fb0:	85aa                	mv	a1,a0
    80005fb2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fb6:	cd11                	beqz	a0,80005fd2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fb8:	6605                	lui	a2,0x1
    80005fba:	e3043503          	ld	a0,-464(s0)
    80005fbe:	ffffd097          	auipc	ra,0xffffd
    80005fc2:	ff0080e7          	jalr	-16(ra) # 80002fae <fetchstr>
    80005fc6:	00054663          	bltz	a0,80005fd2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005fca:	0905                	addi	s2,s2,1
    80005fcc:	09a1                	addi	s3,s3,8
    80005fce:	fb491be3          	bne	s2,s4,80005f84 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd2:	10048913          	addi	s2,s1,256
    80005fd6:	6088                	ld	a0,0(s1)
    80005fd8:	c531                	beqz	a0,80006024 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	a36080e7          	jalr	-1482(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe2:	04a1                	addi	s1,s1,8
    80005fe4:	ff2499e3          	bne	s1,s2,80005fd6 <sys_exec+0xaa>
  return -1;
    80005fe8:	557d                	li	a0,-1
    80005fea:	a835                	j	80006026 <sys_exec+0xfa>
      argv[i] = 0;
    80005fec:	0a8e                	slli	s5,s5,0x3
    80005fee:	fc040793          	addi	a5,s0,-64
    80005ff2:	9abe                	add	s5,s5,a5
    80005ff4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ff8:	e4040593          	addi	a1,s0,-448
    80005ffc:	f4040513          	addi	a0,s0,-192
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	190080e7          	jalr	400(ra) # 80005190 <exec>
    80006008:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600a:	10048993          	addi	s3,s1,256
    8000600e:	6088                	ld	a0,0(s1)
    80006010:	c901                	beqz	a0,80006020 <sys_exec+0xf4>
    kfree(argv[i]);
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	9fe080e7          	jalr	-1538(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601a:	04a1                	addi	s1,s1,8
    8000601c:	ff3499e3          	bne	s1,s3,8000600e <sys_exec+0xe2>
  return ret;
    80006020:	854a                	mv	a0,s2
    80006022:	a011                	j	80006026 <sys_exec+0xfa>
  return -1;
    80006024:	557d                	li	a0,-1
}
    80006026:	60be                	ld	ra,456(sp)
    80006028:	641e                	ld	s0,448(sp)
    8000602a:	74fa                	ld	s1,440(sp)
    8000602c:	795a                	ld	s2,432(sp)
    8000602e:	79ba                	ld	s3,424(sp)
    80006030:	7a1a                	ld	s4,416(sp)
    80006032:	6afa                	ld	s5,408(sp)
    80006034:	6179                	addi	sp,sp,464
    80006036:	8082                	ret

0000000080006038 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006038:	7139                	addi	sp,sp,-64
    8000603a:	fc06                	sd	ra,56(sp)
    8000603c:	f822                	sd	s0,48(sp)
    8000603e:	f426                	sd	s1,40(sp)
    80006040:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	bb8080e7          	jalr	-1096(ra) # 80001bfa <myproc>
    8000604a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000604c:	fd840593          	addi	a1,s0,-40
    80006050:	4501                	li	a0,0
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	fc8080e7          	jalr	-56(ra) # 8000301a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000605a:	fc840593          	addi	a1,s0,-56
    8000605e:	fd040513          	addi	a0,s0,-48
    80006062:	fffff097          	auipc	ra,0xfffff
    80006066:	dd6080e7          	jalr	-554(ra) # 80004e38 <pipealloc>
    return -1;
    8000606a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000606c:	0c054463          	bltz	a0,80006134 <sys_pipe+0xfc>
  fd0 = -1;
    80006070:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006074:	fd043503          	ld	a0,-48(s0)
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	518080e7          	jalr	1304(ra) # 80005590 <fdalloc>
    80006080:	fca42223          	sw	a0,-60(s0)
    80006084:	08054b63          	bltz	a0,8000611a <sys_pipe+0xe2>
    80006088:	fc843503          	ld	a0,-56(s0)
    8000608c:	fffff097          	auipc	ra,0xfffff
    80006090:	504080e7          	jalr	1284(ra) # 80005590 <fdalloc>
    80006094:	fca42023          	sw	a0,-64(s0)
    80006098:	06054863          	bltz	a0,80006108 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000609c:	4691                	li	a3,4
    8000609e:	fc440613          	addi	a2,s0,-60
    800060a2:	fd843583          	ld	a1,-40(s0)
    800060a6:	68a8                	ld	a0,80(s1)
    800060a8:	ffffb097          	auipc	ra,0xffffb
    800060ac:	712080e7          	jalr	1810(ra) # 800017ba <copyout>
    800060b0:	02054063          	bltz	a0,800060d0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060b4:	4691                	li	a3,4
    800060b6:	fc040613          	addi	a2,s0,-64
    800060ba:	fd843583          	ld	a1,-40(s0)
    800060be:	0591                	addi	a1,a1,4
    800060c0:	68a8                	ld	a0,80(s1)
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	6f8080e7          	jalr	1784(ra) # 800017ba <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060ca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060cc:	06055463          	bgez	a0,80006134 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060d0:	fc442783          	lw	a5,-60(s0)
    800060d4:	07e9                	addi	a5,a5,26
    800060d6:	078e                	slli	a5,a5,0x3
    800060d8:	97a6                	add	a5,a5,s1
    800060da:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060de:	fc042503          	lw	a0,-64(s0)
    800060e2:	0569                	addi	a0,a0,26
    800060e4:	050e                	slli	a0,a0,0x3
    800060e6:	94aa                	add	s1,s1,a0
    800060e8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060ec:	fd043503          	ld	a0,-48(s0)
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	a18080e7          	jalr	-1512(ra) # 80004b08 <fileclose>
    fileclose(wf);
    800060f8:	fc843503          	ld	a0,-56(s0)
    800060fc:	fffff097          	auipc	ra,0xfffff
    80006100:	a0c080e7          	jalr	-1524(ra) # 80004b08 <fileclose>
    return -1;
    80006104:	57fd                	li	a5,-1
    80006106:	a03d                	j	80006134 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006108:	fc442783          	lw	a5,-60(s0)
    8000610c:	0007c763          	bltz	a5,8000611a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006110:	07e9                	addi	a5,a5,26
    80006112:	078e                	slli	a5,a5,0x3
    80006114:	94be                	add	s1,s1,a5
    80006116:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000611a:	fd043503          	ld	a0,-48(s0)
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	9ea080e7          	jalr	-1558(ra) # 80004b08 <fileclose>
    fileclose(wf);
    80006126:	fc843503          	ld	a0,-56(s0)
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	9de080e7          	jalr	-1570(ra) # 80004b08 <fileclose>
    return -1;
    80006132:	57fd                	li	a5,-1
}
    80006134:	853e                	mv	a0,a5
    80006136:	70e2                	ld	ra,56(sp)
    80006138:	7442                	ld	s0,48(sp)
    8000613a:	74a2                	ld	s1,40(sp)
    8000613c:	6121                	addi	sp,sp,64
    8000613e:	8082                	ret

0000000080006140 <kernelvec>:
    80006140:	7111                	addi	sp,sp,-256
    80006142:	e006                	sd	ra,0(sp)
    80006144:	e40a                	sd	sp,8(sp)
    80006146:	e80e                	sd	gp,16(sp)
    80006148:	ec12                	sd	tp,24(sp)
    8000614a:	f016                	sd	t0,32(sp)
    8000614c:	f41a                	sd	t1,40(sp)
    8000614e:	f81e                	sd	t2,48(sp)
    80006150:	fc22                	sd	s0,56(sp)
    80006152:	e0a6                	sd	s1,64(sp)
    80006154:	e4aa                	sd	a0,72(sp)
    80006156:	e8ae                	sd	a1,80(sp)
    80006158:	ecb2                	sd	a2,88(sp)
    8000615a:	f0b6                	sd	a3,96(sp)
    8000615c:	f4ba                	sd	a4,104(sp)
    8000615e:	f8be                	sd	a5,112(sp)
    80006160:	fcc2                	sd	a6,120(sp)
    80006162:	e146                	sd	a7,128(sp)
    80006164:	e54a                	sd	s2,136(sp)
    80006166:	e94e                	sd	s3,144(sp)
    80006168:	ed52                	sd	s4,152(sp)
    8000616a:	f156                	sd	s5,160(sp)
    8000616c:	f55a                	sd	s6,168(sp)
    8000616e:	f95e                	sd	s7,176(sp)
    80006170:	fd62                	sd	s8,184(sp)
    80006172:	e1e6                	sd	s9,192(sp)
    80006174:	e5ea                	sd	s10,200(sp)
    80006176:	e9ee                	sd	s11,208(sp)
    80006178:	edf2                	sd	t3,216(sp)
    8000617a:	f1f6                	sd	t4,224(sp)
    8000617c:	f5fa                	sd	t5,232(sp)
    8000617e:	f9fe                	sd	t6,240(sp)
    80006180:	ca9fc0ef          	jal	ra,80002e28 <kerneltrap>
    80006184:	6082                	ld	ra,0(sp)
    80006186:	6122                	ld	sp,8(sp)
    80006188:	61c2                	ld	gp,16(sp)
    8000618a:	7282                	ld	t0,32(sp)
    8000618c:	7322                	ld	t1,40(sp)
    8000618e:	73c2                	ld	t2,48(sp)
    80006190:	7462                	ld	s0,56(sp)
    80006192:	6486                	ld	s1,64(sp)
    80006194:	6526                	ld	a0,72(sp)
    80006196:	65c6                	ld	a1,80(sp)
    80006198:	6666                	ld	a2,88(sp)
    8000619a:	7686                	ld	a3,96(sp)
    8000619c:	7726                	ld	a4,104(sp)
    8000619e:	77c6                	ld	a5,112(sp)
    800061a0:	7866                	ld	a6,120(sp)
    800061a2:	688a                	ld	a7,128(sp)
    800061a4:	692a                	ld	s2,136(sp)
    800061a6:	69ca                	ld	s3,144(sp)
    800061a8:	6a6a                	ld	s4,152(sp)
    800061aa:	7a8a                	ld	s5,160(sp)
    800061ac:	7b2a                	ld	s6,168(sp)
    800061ae:	7bca                	ld	s7,176(sp)
    800061b0:	7c6a                	ld	s8,184(sp)
    800061b2:	6c8e                	ld	s9,192(sp)
    800061b4:	6d2e                	ld	s10,200(sp)
    800061b6:	6dce                	ld	s11,208(sp)
    800061b8:	6e6e                	ld	t3,216(sp)
    800061ba:	7e8e                	ld	t4,224(sp)
    800061bc:	7f2e                	ld	t5,232(sp)
    800061be:	7fce                	ld	t6,240(sp)
    800061c0:	6111                	addi	sp,sp,256
    800061c2:	10200073          	sret
    800061c6:	00000013          	nop
    800061ca:	00000013          	nop
    800061ce:	0001                	nop

00000000800061d0 <timervec>:
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	e10c                	sd	a1,0(a0)
    800061d6:	e510                	sd	a2,8(a0)
    800061d8:	e914                	sd	a3,16(a0)
    800061da:	6d0c                	ld	a1,24(a0)
    800061dc:	7110                	ld	a2,32(a0)
    800061de:	6194                	ld	a3,0(a1)
    800061e0:	96b2                	add	a3,a3,a2
    800061e2:	e194                	sd	a3,0(a1)
    800061e4:	4589                	li	a1,2
    800061e6:	14459073          	csrw	sip,a1
    800061ea:	6914                	ld	a3,16(a0)
    800061ec:	6510                	ld	a2,8(a0)
    800061ee:	610c                	ld	a1,0(a0)
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	30200073          	mret
	...

00000000800061fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061fa:	1141                	addi	sp,sp,-16
    800061fc:	e422                	sd	s0,8(sp)
    800061fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006200:	0c0007b7          	lui	a5,0xc000
    80006204:	4705                	li	a4,1
    80006206:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006208:	c3d8                	sw	a4,4(a5)
}
    8000620a:	6422                	ld	s0,8(sp)
    8000620c:	0141                	addi	sp,sp,16
    8000620e:	8082                	ret

0000000080006210 <plicinithart>:

void
plicinithart(void)
{
    80006210:	1141                	addi	sp,sp,-16
    80006212:	e406                	sd	ra,8(sp)
    80006214:	e022                	sd	s0,0(sp)
    80006216:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	9b6080e7          	jalr	-1610(ra) # 80001bce <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006220:	0085171b          	slliw	a4,a0,0x8
    80006224:	0c0027b7          	lui	a5,0xc002
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	40200713          	li	a4,1026
    8000622e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006232:	00d5151b          	slliw	a0,a0,0xd
    80006236:	0c2017b7          	lui	a5,0xc201
    8000623a:	953e                	add	a0,a0,a5
    8000623c:	00052023          	sw	zero,0(a0)
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret

0000000080006248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006248:	1141                	addi	sp,sp,-16
    8000624a:	e406                	sd	ra,8(sp)
    8000624c:	e022                	sd	s0,0(sp)
    8000624e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006250:	ffffc097          	auipc	ra,0xffffc
    80006254:	97e080e7          	jalr	-1666(ra) # 80001bce <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006258:	00d5179b          	slliw	a5,a0,0xd
    8000625c:	0c201537          	lui	a0,0xc201
    80006260:	953e                	add	a0,a0,a5
  return irq;
}
    80006262:	4148                	lw	a0,4(a0)
    80006264:	60a2                	ld	ra,8(sp)
    80006266:	6402                	ld	s0,0(sp)
    80006268:	0141                	addi	sp,sp,16
    8000626a:	8082                	ret

000000008000626c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	1000                	addi	s0,sp,32
    80006276:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	956080e7          	jalr	-1706(ra) # 80001bce <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006280:	00d5151b          	slliw	a0,a0,0xd
    80006284:	0c2017b7          	lui	a5,0xc201
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	c3c4                	sw	s1,4(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret

0000000080006296 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006296:	1141                	addi	sp,sp,-16
    80006298:	e406                	sd	ra,8(sp)
    8000629a:	e022                	sd	s0,0(sp)
    8000629c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000629e:	479d                	li	a5,7
    800062a0:	04a7cc63          	blt	a5,a0,800062f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062a4:	00024797          	auipc	a5,0x24
    800062a8:	b4c78793          	addi	a5,a5,-1204 # 80029df0 <disk>
    800062ac:	97aa                	add	a5,a5,a0
    800062ae:	0187c783          	lbu	a5,24(a5)
    800062b2:	ebb9                	bnez	a5,80006308 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062b4:	00451613          	slli	a2,a0,0x4
    800062b8:	00024797          	auipc	a5,0x24
    800062bc:	b3878793          	addi	a5,a5,-1224 # 80029df0 <disk>
    800062c0:	6394                	ld	a3,0(a5)
    800062c2:	96b2                	add	a3,a3,a2
    800062c4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062c8:	6398                	ld	a4,0(a5)
    800062ca:	9732                	add	a4,a4,a2
    800062cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062d8:	953e                	add	a0,a0,a5
    800062da:	4785                	li	a5,1
    800062dc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800062e0:	00024517          	auipc	a0,0x24
    800062e4:	b2850513          	addi	a0,a0,-1240 # 80029e08 <disk+0x18>
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	0da080e7          	jalr	218(ra) # 800023c2 <wakeup>
}
    800062f0:	60a2                	ld	ra,8(sp)
    800062f2:	6402                	ld	s0,0(sp)
    800062f4:	0141                	addi	sp,sp,16
    800062f6:	8082                	ret
    panic("free_desc 1");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	5d850513          	addi	a0,a0,1496 # 800088d0 <syscalls+0x318>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	244080e7          	jalr	580(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006308:	00002517          	auipc	a0,0x2
    8000630c:	5d850513          	addi	a0,a0,1496 # 800088e0 <syscalls+0x328>
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	234080e7          	jalr	564(ra) # 80000544 <panic>

0000000080006318 <virtio_disk_init>:
{
    80006318:	1101                	addi	sp,sp,-32
    8000631a:	ec06                	sd	ra,24(sp)
    8000631c:	e822                	sd	s0,16(sp)
    8000631e:	e426                	sd	s1,8(sp)
    80006320:	e04a                	sd	s2,0(sp)
    80006322:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006324:	00002597          	auipc	a1,0x2
    80006328:	5cc58593          	addi	a1,a1,1484 # 800088f0 <syscalls+0x338>
    8000632c:	00024517          	auipc	a0,0x24
    80006330:	bec50513          	addi	a0,a0,-1044 # 80029f18 <disk+0x128>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	91a080e7          	jalr	-1766(ra) # 80000c4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	4398                	lw	a4,0(a5)
    80006342:	2701                	sext.w	a4,a4
    80006344:	747277b7          	lui	a5,0x74727
    80006348:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000634c:	14f71e63          	bne	a4,a5,800064a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006350:	100017b7          	lui	a5,0x10001
    80006354:	43dc                	lw	a5,4(a5)
    80006356:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006358:	4709                	li	a4,2
    8000635a:	14e79763          	bne	a5,a4,800064a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000635e:	100017b7          	lui	a5,0x10001
    80006362:	479c                	lw	a5,8(a5)
    80006364:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006366:	14e79163          	bne	a5,a4,800064a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000636a:	100017b7          	lui	a5,0x10001
    8000636e:	47d8                	lw	a4,12(a5)
    80006370:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006372:	554d47b7          	lui	a5,0x554d4
    80006376:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000637a:	12f71763          	bne	a4,a5,800064a8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000637e:	100017b7          	lui	a5,0x10001
    80006382:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006386:	4705                	li	a4,1
    80006388:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638a:	470d                	li	a4,3
    8000638c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000638e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006390:	c7ffe737          	lui	a4,0xc7ffe
    80006394:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd482f>
    80006398:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000639a:	2701                	sext.w	a4,a4
    8000639c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000639e:	472d                	li	a4,11
    800063a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063a2:	0707a903          	lw	s2,112(a5)
    800063a6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063a8:	00897793          	andi	a5,s2,8
    800063ac:	10078663          	beqz	a5,800064b8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063b0:	100017b7          	lui	a5,0x10001
    800063b4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063b8:	43fc                	lw	a5,68(a5)
    800063ba:	2781                	sext.w	a5,a5
    800063bc:	10079663          	bnez	a5,800064c8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063c0:	100017b7          	lui	a5,0x10001
    800063c4:	5bdc                	lw	a5,52(a5)
    800063c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063c8:	10078863          	beqz	a5,800064d8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800063cc:	471d                	li	a4,7
    800063ce:	10f77d63          	bgeu	a4,a5,800064e8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800063d2:	ffffa097          	auipc	ra,0xffffa
    800063d6:	7d0080e7          	jalr	2000(ra) # 80000ba2 <kalloc>
    800063da:	00024497          	auipc	s1,0x24
    800063de:	a1648493          	addi	s1,s1,-1514 # 80029df0 <disk>
    800063e2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063e4:	ffffa097          	auipc	ra,0xffffa
    800063e8:	7be080e7          	jalr	1982(ra) # 80000ba2 <kalloc>
    800063ec:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	7b4080e7          	jalr	1972(ra) # 80000ba2 <kalloc>
    800063f6:	87aa                	mv	a5,a0
    800063f8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063fa:	6088                	ld	a0,0(s1)
    800063fc:	cd75                	beqz	a0,800064f8 <virtio_disk_init+0x1e0>
    800063fe:	00024717          	auipc	a4,0x24
    80006402:	9fa73703          	ld	a4,-1542(a4) # 80029df8 <disk+0x8>
    80006406:	cb6d                	beqz	a4,800064f8 <virtio_disk_init+0x1e0>
    80006408:	cbe5                	beqz	a5,800064f8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000640a:	6605                	lui	a2,0x1
    8000640c:	4581                	li	a1,0
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	9cc080e7          	jalr	-1588(ra) # 80000dda <memset>
  memset(disk.avail, 0, PGSIZE);
    80006416:	00024497          	auipc	s1,0x24
    8000641a:	9da48493          	addi	s1,s1,-1574 # 80029df0 <disk>
    8000641e:	6605                	lui	a2,0x1
    80006420:	4581                	li	a1,0
    80006422:	6488                	ld	a0,8(s1)
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	9b6080e7          	jalr	-1610(ra) # 80000dda <memset>
  memset(disk.used, 0, PGSIZE);
    8000642c:	6605                	lui	a2,0x1
    8000642e:	4581                	li	a1,0
    80006430:	6888                	ld	a0,16(s1)
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	9a8080e7          	jalr	-1624(ra) # 80000dda <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000643a:	100017b7          	lui	a5,0x10001
    8000643e:	4721                	li	a4,8
    80006440:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006442:	4098                	lw	a4,0(s1)
    80006444:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006448:	40d8                	lw	a4,4(s1)
    8000644a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000644e:	6498                	ld	a4,8(s1)
    80006450:	0007069b          	sext.w	a3,a4
    80006454:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006458:	9701                	srai	a4,a4,0x20
    8000645a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000645e:	6898                	ld	a4,16(s1)
    80006460:	0007069b          	sext.w	a3,a4
    80006464:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006468:	9701                	srai	a4,a4,0x20
    8000646a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000646e:	4685                	li	a3,1
    80006470:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006472:	4705                	li	a4,1
    80006474:	00d48c23          	sb	a3,24(s1)
    80006478:	00e48ca3          	sb	a4,25(s1)
    8000647c:	00e48d23          	sb	a4,26(s1)
    80006480:	00e48da3          	sb	a4,27(s1)
    80006484:	00e48e23          	sb	a4,28(s1)
    80006488:	00e48ea3          	sb	a4,29(s1)
    8000648c:	00e48f23          	sb	a4,30(s1)
    80006490:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006494:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006498:	0727a823          	sw	s2,112(a5)
}
    8000649c:	60e2                	ld	ra,24(sp)
    8000649e:	6442                	ld	s0,16(sp)
    800064a0:	64a2                	ld	s1,8(sp)
    800064a2:	6902                	ld	s2,0(sp)
    800064a4:	6105                	addi	sp,sp,32
    800064a6:	8082                	ret
    panic("could not find virtio disk");
    800064a8:	00002517          	auipc	a0,0x2
    800064ac:	45850513          	addi	a0,a0,1112 # 80008900 <syscalls+0x348>
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	094080e7          	jalr	148(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	46850513          	addi	a0,a0,1128 # 80008920 <syscalls+0x368>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	084080e7          	jalr	132(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	47850513          	addi	a0,a0,1144 # 80008940 <syscalls+0x388>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	074080e7          	jalr	116(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800064d8:	00002517          	auipc	a0,0x2
    800064dc:	48850513          	addi	a0,a0,1160 # 80008960 <syscalls+0x3a8>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	064080e7          	jalr	100(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800064e8:	00002517          	auipc	a0,0x2
    800064ec:	49850513          	addi	a0,a0,1176 # 80008980 <syscalls+0x3c8>
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	054080e7          	jalr	84(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800064f8:	00002517          	auipc	a0,0x2
    800064fc:	4a850513          	addi	a0,a0,1192 # 800089a0 <syscalls+0x3e8>
    80006500:	ffffa097          	auipc	ra,0xffffa
    80006504:	044080e7          	jalr	68(ra) # 80000544 <panic>

0000000080006508 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006508:	7159                	addi	sp,sp,-112
    8000650a:	f486                	sd	ra,104(sp)
    8000650c:	f0a2                	sd	s0,96(sp)
    8000650e:	eca6                	sd	s1,88(sp)
    80006510:	e8ca                	sd	s2,80(sp)
    80006512:	e4ce                	sd	s3,72(sp)
    80006514:	e0d2                	sd	s4,64(sp)
    80006516:	fc56                	sd	s5,56(sp)
    80006518:	f85a                	sd	s6,48(sp)
    8000651a:	f45e                	sd	s7,40(sp)
    8000651c:	f062                	sd	s8,32(sp)
    8000651e:	ec66                	sd	s9,24(sp)
    80006520:	e86a                	sd	s10,16(sp)
    80006522:	1880                	addi	s0,sp,112
    80006524:	892a                	mv	s2,a0
    80006526:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006528:	00c52c83          	lw	s9,12(a0)
    8000652c:	001c9c9b          	slliw	s9,s9,0x1
    80006530:	1c82                	slli	s9,s9,0x20
    80006532:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006536:	00024517          	auipc	a0,0x24
    8000653a:	9e250513          	addi	a0,a0,-1566 # 80029f18 <disk+0x128>
    8000653e:	ffffa097          	auipc	ra,0xffffa
    80006542:	7a0080e7          	jalr	1952(ra) # 80000cde <acquire>
  for(int i = 0; i < 3; i++){
    80006546:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006548:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000654a:	00024b17          	auipc	s6,0x24
    8000654e:	8a6b0b13          	addi	s6,s6,-1882 # 80029df0 <disk>
  for(int i = 0; i < 3; i++){
    80006552:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006554:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006556:	00024c17          	auipc	s8,0x24
    8000655a:	9c2c0c13          	addi	s8,s8,-1598 # 80029f18 <disk+0x128>
    8000655e:	a8b5                	j	800065da <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006560:	00fb06b3          	add	a3,s6,a5
    80006564:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006568:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000656a:	0207c563          	bltz	a5,80006594 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000656e:	2485                	addiw	s1,s1,1
    80006570:	0711                	addi	a4,a4,4
    80006572:	1f548a63          	beq	s1,s5,80006766 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006576:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006578:	00024697          	auipc	a3,0x24
    8000657c:	87868693          	addi	a3,a3,-1928 # 80029df0 <disk>
    80006580:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006582:	0186c583          	lbu	a1,24(a3)
    80006586:	fde9                	bnez	a1,80006560 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006588:	2785                	addiw	a5,a5,1
    8000658a:	0685                	addi	a3,a3,1
    8000658c:	ff779be3          	bne	a5,s7,80006582 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006590:	57fd                	li	a5,-1
    80006592:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006594:	02905a63          	blez	s1,800065c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006598:	f9042503          	lw	a0,-112(s0)
    8000659c:	00000097          	auipc	ra,0x0
    800065a0:	cfa080e7          	jalr	-774(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    800065a4:	4785                	li	a5,1
    800065a6:	0297d163          	bge	a5,s1,800065c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800065aa:	f9442503          	lw	a0,-108(s0)
    800065ae:	00000097          	auipc	ra,0x0
    800065b2:	ce8080e7          	jalr	-792(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    800065b6:	4789                	li	a5,2
    800065b8:	0097d863          	bge	a5,s1,800065c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800065bc:	f9842503          	lw	a0,-104(s0)
    800065c0:	00000097          	auipc	ra,0x0
    800065c4:	cd6080e7          	jalr	-810(ra) # 80006296 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065c8:	85e2                	mv	a1,s8
    800065ca:	00024517          	auipc	a0,0x24
    800065ce:	83e50513          	addi	a0,a0,-1986 # 80029e08 <disk+0x18>
    800065d2:	ffffc097          	auipc	ra,0xffffc
    800065d6:	d8c080e7          	jalr	-628(ra) # 8000235e <sleep>
  for(int i = 0; i < 3; i++){
    800065da:	f9040713          	addi	a4,s0,-112
    800065de:	84ce                	mv	s1,s3
    800065e0:	bf59                	j	80006576 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065e2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800065e6:	00479693          	slli	a3,a5,0x4
    800065ea:	00024797          	auipc	a5,0x24
    800065ee:	80678793          	addi	a5,a5,-2042 # 80029df0 <disk>
    800065f2:	97b6                	add	a5,a5,a3
    800065f4:	4685                	li	a3,1
    800065f6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065f8:	00023597          	auipc	a1,0x23
    800065fc:	7f858593          	addi	a1,a1,2040 # 80029df0 <disk>
    80006600:	00a60793          	addi	a5,a2,10
    80006604:	0792                	slli	a5,a5,0x4
    80006606:	97ae                	add	a5,a5,a1
    80006608:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000660c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006610:	f6070693          	addi	a3,a4,-160
    80006614:	619c                	ld	a5,0(a1)
    80006616:	97b6                	add	a5,a5,a3
    80006618:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000661a:	6188                	ld	a0,0(a1)
    8000661c:	96aa                	add	a3,a3,a0
    8000661e:	47c1                	li	a5,16
    80006620:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006622:	4785                	li	a5,1
    80006624:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006628:	f9442783          	lw	a5,-108(s0)
    8000662c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006630:	0792                	slli	a5,a5,0x4
    80006632:	953e                	add	a0,a0,a5
    80006634:	05890693          	addi	a3,s2,88
    80006638:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000663a:	6188                	ld	a0,0(a1)
    8000663c:	97aa                	add	a5,a5,a0
    8000663e:	40000693          	li	a3,1024
    80006642:	c794                	sw	a3,8(a5)
  if(write)
    80006644:	100d0d63          	beqz	s10,8000675e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006648:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000664c:	00c7d683          	lhu	a3,12(a5)
    80006650:	0016e693          	ori	a3,a3,1
    80006654:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006658:	f9842583          	lw	a1,-104(s0)
    8000665c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006660:	00023697          	auipc	a3,0x23
    80006664:	79068693          	addi	a3,a3,1936 # 80029df0 <disk>
    80006668:	00260793          	addi	a5,a2,2
    8000666c:	0792                	slli	a5,a5,0x4
    8000666e:	97b6                	add	a5,a5,a3
    80006670:	587d                	li	a6,-1
    80006672:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006676:	0592                	slli	a1,a1,0x4
    80006678:	952e                	add	a0,a0,a1
    8000667a:	f9070713          	addi	a4,a4,-112
    8000667e:	9736                	add	a4,a4,a3
    80006680:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006682:	6298                	ld	a4,0(a3)
    80006684:	972e                	add	a4,a4,a1
    80006686:	4585                	li	a1,1
    80006688:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000668a:	4509                	li	a0,2
    8000668c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006690:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006694:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006698:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000669c:	6698                	ld	a4,8(a3)
    8000669e:	00275783          	lhu	a5,2(a4)
    800066a2:	8b9d                	andi	a5,a5,7
    800066a4:	0786                	slli	a5,a5,0x1
    800066a6:	97ba                	add	a5,a5,a4
    800066a8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800066ac:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066b0:	6698                	ld	a4,8(a3)
    800066b2:	00275783          	lhu	a5,2(a4)
    800066b6:	2785                	addiw	a5,a5,1
    800066b8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066bc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066c0:	100017b7          	lui	a5,0x10001
    800066c4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066c8:	00492703          	lw	a4,4(s2)
    800066cc:	4785                	li	a5,1
    800066ce:	02f71163          	bne	a4,a5,800066f0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800066d2:	00024997          	auipc	s3,0x24
    800066d6:	84698993          	addi	s3,s3,-1978 # 80029f18 <disk+0x128>
  while(b->disk == 1) {
    800066da:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066dc:	85ce                	mv	a1,s3
    800066de:	854a                	mv	a0,s2
    800066e0:	ffffc097          	auipc	ra,0xffffc
    800066e4:	c7e080e7          	jalr	-898(ra) # 8000235e <sleep>
  while(b->disk == 1) {
    800066e8:	00492783          	lw	a5,4(s2)
    800066ec:	fe9788e3          	beq	a5,s1,800066dc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800066f0:	f9042903          	lw	s2,-112(s0)
    800066f4:	00290793          	addi	a5,s2,2
    800066f8:	00479713          	slli	a4,a5,0x4
    800066fc:	00023797          	auipc	a5,0x23
    80006700:	6f478793          	addi	a5,a5,1780 # 80029df0 <disk>
    80006704:	97ba                	add	a5,a5,a4
    80006706:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000670a:	00023997          	auipc	s3,0x23
    8000670e:	6e698993          	addi	s3,s3,1766 # 80029df0 <disk>
    80006712:	00491713          	slli	a4,s2,0x4
    80006716:	0009b783          	ld	a5,0(s3)
    8000671a:	97ba                	add	a5,a5,a4
    8000671c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006720:	854a                	mv	a0,s2
    80006722:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006726:	00000097          	auipc	ra,0x0
    8000672a:	b70080e7          	jalr	-1168(ra) # 80006296 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000672e:	8885                	andi	s1,s1,1
    80006730:	f0ed                	bnez	s1,80006712 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006732:	00023517          	auipc	a0,0x23
    80006736:	7e650513          	addi	a0,a0,2022 # 80029f18 <disk+0x128>
    8000673a:	ffffa097          	auipc	ra,0xffffa
    8000673e:	658080e7          	jalr	1624(ra) # 80000d92 <release>
}
    80006742:	70a6                	ld	ra,104(sp)
    80006744:	7406                	ld	s0,96(sp)
    80006746:	64e6                	ld	s1,88(sp)
    80006748:	6946                	ld	s2,80(sp)
    8000674a:	69a6                	ld	s3,72(sp)
    8000674c:	6a06                	ld	s4,64(sp)
    8000674e:	7ae2                	ld	s5,56(sp)
    80006750:	7b42                	ld	s6,48(sp)
    80006752:	7ba2                	ld	s7,40(sp)
    80006754:	7c02                	ld	s8,32(sp)
    80006756:	6ce2                	ld	s9,24(sp)
    80006758:	6d42                	ld	s10,16(sp)
    8000675a:	6165                	addi	sp,sp,112
    8000675c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000675e:	4689                	li	a3,2
    80006760:	00d79623          	sh	a3,12(a5)
    80006764:	b5e5                	j	8000664c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006766:	f9042603          	lw	a2,-112(s0)
    8000676a:	00a60713          	addi	a4,a2,10
    8000676e:	0712                	slli	a4,a4,0x4
    80006770:	00023517          	auipc	a0,0x23
    80006774:	68850513          	addi	a0,a0,1672 # 80029df8 <disk+0x8>
    80006778:	953a                	add	a0,a0,a4
  if(write)
    8000677a:	e60d14e3          	bnez	s10,800065e2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000677e:	00a60793          	addi	a5,a2,10
    80006782:	00479693          	slli	a3,a5,0x4
    80006786:	00023797          	auipc	a5,0x23
    8000678a:	66a78793          	addi	a5,a5,1642 # 80029df0 <disk>
    8000678e:	97b6                	add	a5,a5,a3
    80006790:	0007a423          	sw	zero,8(a5)
    80006794:	b595                	j	800065f8 <virtio_disk_rw+0xf0>

0000000080006796 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006796:	1101                	addi	sp,sp,-32
    80006798:	ec06                	sd	ra,24(sp)
    8000679a:	e822                	sd	s0,16(sp)
    8000679c:	e426                	sd	s1,8(sp)
    8000679e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067a0:	00023497          	auipc	s1,0x23
    800067a4:	65048493          	addi	s1,s1,1616 # 80029df0 <disk>
    800067a8:	00023517          	auipc	a0,0x23
    800067ac:	77050513          	addi	a0,a0,1904 # 80029f18 <disk+0x128>
    800067b0:	ffffa097          	auipc	ra,0xffffa
    800067b4:	52e080e7          	jalr	1326(ra) # 80000cde <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067b8:	10001737          	lui	a4,0x10001
    800067bc:	533c                	lw	a5,96(a4)
    800067be:	8b8d                	andi	a5,a5,3
    800067c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067c6:	689c                	ld	a5,16(s1)
    800067c8:	0204d703          	lhu	a4,32(s1)
    800067cc:	0027d783          	lhu	a5,2(a5)
    800067d0:	04f70863          	beq	a4,a5,80006820 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067d4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067d8:	6898                	ld	a4,16(s1)
    800067da:	0204d783          	lhu	a5,32(s1)
    800067de:	8b9d                	andi	a5,a5,7
    800067e0:	078e                	slli	a5,a5,0x3
    800067e2:	97ba                	add	a5,a5,a4
    800067e4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067e6:	00278713          	addi	a4,a5,2
    800067ea:	0712                	slli	a4,a4,0x4
    800067ec:	9726                	add	a4,a4,s1
    800067ee:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800067f2:	e721                	bnez	a4,8000683a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067f4:	0789                	addi	a5,a5,2
    800067f6:	0792                	slli	a5,a5,0x4
    800067f8:	97a6                	add	a5,a5,s1
    800067fa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800067fc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006800:	ffffc097          	auipc	ra,0xffffc
    80006804:	bc2080e7          	jalr	-1086(ra) # 800023c2 <wakeup>

    disk.used_idx += 1;
    80006808:	0204d783          	lhu	a5,32(s1)
    8000680c:	2785                	addiw	a5,a5,1
    8000680e:	17c2                	slli	a5,a5,0x30
    80006810:	93c1                	srli	a5,a5,0x30
    80006812:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006816:	6898                	ld	a4,16(s1)
    80006818:	00275703          	lhu	a4,2(a4)
    8000681c:	faf71ce3          	bne	a4,a5,800067d4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006820:	00023517          	auipc	a0,0x23
    80006824:	6f850513          	addi	a0,a0,1784 # 80029f18 <disk+0x128>
    80006828:	ffffa097          	auipc	ra,0xffffa
    8000682c:	56a080e7          	jalr	1386(ra) # 80000d92 <release>
}
    80006830:	60e2                	ld	ra,24(sp)
    80006832:	6442                	ld	s0,16(sp)
    80006834:	64a2                	ld	s1,8(sp)
    80006836:	6105                	addi	sp,sp,32
    80006838:	8082                	ret
      panic("virtio_disk_intr status");
    8000683a:	00002517          	auipc	a0,0x2
    8000683e:	17e50513          	addi	a0,a0,382 # 800089b8 <syscalls+0x400>
    80006842:	ffffa097          	auipc	ra,0xffffa
    80006846:	d02080e7          	jalr	-766(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
