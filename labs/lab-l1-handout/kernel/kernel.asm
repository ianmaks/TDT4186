
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa010113          	addi	sp,sp,-1376 # 80008aa0 <stack0>
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
    80000054:	91070713          	addi	a4,a4,-1776 # 80008960 <timer_scratch>
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
    80000066:	bce78793          	addi	a5,a5,-1074 # 80005c30 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca2f>
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
int
consolewrite(int user_src, uint64 src, int n)
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

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	382080e7          	jalr	898(ra) # 800024ac <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
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
    80000188:	91c50513          	addi	a0,a0,-1764 # 80010aa0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	90c48493          	addi	s1,s1,-1780 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	99c90913          	addi	s2,s2,-1636 # 80010b38 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7f2080e7          	jalr	2034(ra) # 800019a6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	13a080e7          	jalr	314(ra) # 800022f6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	e84080e7          	jalr	-380(ra) # 8000204e <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8c270713          	addi	a4,a4,-1854 # 80010aa0 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	246080e7          	jalr	582(ra) # 80002456 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	87850513          	addi	a0,a0,-1928 # 80010aa0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	86250513          	addi	a0,a0,-1950 # 80010aa0 <cons>
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
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	8cf72523          	sw	a5,-1846(a4) # 80010b38 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
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
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	7d850513          	addi	a0,a0,2008 # 80010aa0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	214080e7          	jalr	532(ra) # 80002502 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7aa50513          	addi	a0,a0,1962 # 80010aa0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	78670713          	addi	a4,a4,1926 # 80010aa0 <cons>
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
    80000344:	00010797          	auipc	a5,0x10
    80000348:	75c78793          	addi	a5,a5,1884 # 80010aa0 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7c67a783          	lw	a5,1990(a5) # 80010b38 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	71a70713          	addi	a4,a4,1818 # 80010aa0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	70a48493          	addi	s1,s1,1802 # 80010aa0 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	6ce70713          	addi	a4,a4,1742 # 80010aa0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	74f72c23          	sw	a5,1880(a4) # 80010b40 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	69278793          	addi	a5,a5,1682 # 80010aa0 <cons>
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
    80000436:	70c7a523          	sw	a2,1802(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6fe50513          	addi	a0,a0,1790 # 80010b38 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	c70080e7          	jalr	-912(ra) # 800020b2 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	64450513          	addi	a0,a0,1604 # 80010aa0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00020797          	auipc	a5,0x20
    80000478:	7c478793          	addi	a5,a5,1988 # 80020c38 <devsw>
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
    8000054c:	6007ac23          	sw	zero,1560(a5) # 80010b60 <pr+0x18>
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
    80000580:	3af72223          	sw	a5,932(a4) # 80008920 <panicked>
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
    800005bc:	5a8dad83          	lw	s11,1448(s11) # 80010b60 <pr+0x18>
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
    800005fa:	55250513          	addi	a0,a0,1362 # 80010b48 <pr>
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
    80000758:	3f450513          	addi	a0,a0,1012 # 80010b48 <pr>
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
    80000774:	3d848493          	addi	s1,s1,984 # 80010b48 <pr>
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
    800007d4:	39850513          	addi	a0,a0,920 # 80010b68 <uart_tx_lock>
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
    80000800:	1247a783          	lw	a5,292(a5) # 80008920 <panicked>
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
    80000838:	0f47b783          	ld	a5,244(a5) # 80008928 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0f473703          	ld	a4,244(a4) # 80008930 <uart_tx_w>
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
    80000862:	30aa0a13          	addi	s4,s4,778 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0c248493          	addi	s1,s1,194 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0c298993          	addi	s3,s3,194 # 80008930 <uart_tx_w>
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
    80000894:	822080e7          	jalr	-2014(ra) # 800020b2 <wakeup>
    
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
    800008d0:	29c50513          	addi	a0,a0,668 # 80010b68 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0447a783          	lw	a5,68(a5) # 80008920 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	04a73703          	ld	a4,74(a4) # 80008930 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	03a7b783          	ld	a5,58(a5) # 80008928 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	26e98993          	addi	s3,s3,622 # 80010b68 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	02648493          	addi	s1,s1,38 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	02690913          	addi	s2,s2,38 # 80008930 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	734080e7          	jalr	1844(ra) # 8000204e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	23848493          	addi	s1,s1,568 # 80010b68 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fee7b623          	sd	a4,-20(a5) # 80008930 <uart_tx_w>
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
    800009ba:	1b248493          	addi	s1,s1,434 # 80010b68 <uart_tx_lock>
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
    800009fc:	3d878793          	addi	a5,a5,984 # 80021dd0 <end>
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
    80000a1c:	18890913          	addi	s2,s2,392 # 80010ba0 <kmem>
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
    80000aba:	0ea50513          	addi	a0,a0,234 # 80010ba0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	30650513          	addi	a0,a0,774 # 80021dd0 <end>
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
    80000af0:	0b448493          	addi	s1,s1,180 # 80010ba0 <kmem>
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
    80000b08:	09c50513          	addi	a0,a0,156 # 80010ba0 <kmem>
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
    80000b34:	07050513          	addi	a0,a0,112 # 80010ba0 <kmem>
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
    80000b70:	e1e080e7          	jalr	-482(ra) # 8000198a <mycpu>
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
    80000ba2:	dec080e7          	jalr	-532(ra) # 8000198a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	de0080e7          	jalr	-544(ra) # 8000198a <mycpu>
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
    80000bc6:	dc8080e7          	jalr	-568(ra) # 8000198a <mycpu>
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
    80000c06:	d88080e7          	jalr	-632(ra) # 8000198a <mycpu>
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
    80000c32:	d5c080e7          	jalr	-676(ra) # 8000198a <mycpu>
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
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd231>
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
    80000e7e:	b00080e7          	jalr	-1280(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	ab670713          	addi	a4,a4,-1354 # 80008938 <started>
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
    80000e9a:	ae4080e7          	jalr	-1308(ra) # 8000197a <cpuid>
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
    80000ebc:	83c080e7          	jalr	-1988(ra) # 800026f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	db0080e7          	jalr	-592(ra) # 80005c70 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fd4080e7          	jalr	-44(ra) # 80001e9c <scheduler>
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
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	79c080e7          	jalr	1948(ra) # 800026cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	7bc080e7          	jalr	1980(ra) # 800026f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d1a080e7          	jalr	-742(ra) # 80005c5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d28080e7          	jalr	-728(ra) # 80005c70 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f20080e7          	jalr	-224(ra) # 80002e70 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	5be080e7          	jalr	1470(ra) # 80003516 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	534080e7          	jalr	1332(ra) # 80004494 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e10080e7          	jalr	-496(ra) # 80005d78 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d0e080e7          	jalr	-754(ra) # 80001c7e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9af72d23          	sw	a5,-1606(a4) # 80008938 <started>
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
    80000f96:	9ae7b783          	ld	a5,-1618(a5) # 80008940 <kernel_pagetable>
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
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd227>
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
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
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
    80001252:	6ea7b923          	sd	a0,1778(a5) # 80008940 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd230>
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

0000000080001830 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
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
    80001844:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	7aa48493          	addi	s1,s1,1962 # 80010ff0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	addi	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001860:	00015a17          	auipc	s4,0x15
    80001864:	190a0a13          	addi	s4,s4,400 # 800169f0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if(pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	858d                	srai	a1,a1,0x3
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addiw	a1,a1,1
    80001884:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189a:	16848493          	addi	s1,s1,360
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	addi	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	addi	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018c6:	7139                	addi	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	addi	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	2de50513          	addi	a0,a0,734 # 80010bc0 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	addi	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	2de50513          	addi	a0,a0,734 # 80010bd8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	6e648493          	addi	s1,s1,1766 # 80010ff0 <proc>
      initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	addi	s6,s6,-1818 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	addi	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	00015997          	auipc	s3,0x15
    80001930:	0c498993          	addi	s3,s3,196 # 800169f0 <tickslock>
      initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
      p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	srai	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	16848493          	addi	s1,s1,360
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:

// Return this CPU's cpu struct. f
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
  return c;
}
    80001996:	0000f517          	auipc	a0,0xf
    8000199a:	25a50513          	addi	a0,a0,602 # 80010bf0 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d6080e7          	jalr	470(ra) # 80000b86 <push_off>
    800019b8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	0000f717          	auipc	a4,0xf
    800019c2:	20270713          	addi	a4,a4,514 # 80010bc0 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	25c080e7          	jalr	604(ra) # 80000c26 <pop_off>
  return p;
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	298080e7          	jalr	664(ra) # 80000c86 <release>

  if (first) {
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	eda7a783          	lw	a5,-294(a5) # 800088d0 <first.2>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	d0c080e7          	jalr	-756(ra) # 8000270c <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	ec07a023          	sw	zero,-320(a5) # 800088d0 <first.2>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	a7c080e7          	jalr	-1412(ra) # 80003496 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	0000f917          	auipc	s2,0xf
    80001a34:	19090913          	addi	s2,s2,400 # 80010bc0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e9278793          	addi	a5,a5,-366 # 800088d4 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	232080e7          	jalr	562(ra) # 80000c86 <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	addi	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	8aa080e7          	jalr	-1878(ra) # 80001322 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	addi	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a96:	05b2                	slli	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	600080e7          	jalr	1536(ra) # 80001098 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab2:	05b6                	slli	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5e2080e7          	jalr	1506(ra) # 80001098 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a54080e7          	jalr	-1452(ra) # 80001528 <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	770080e7          	jalr	1904(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a2e080e7          	jalr	-1490(ra) # 80001528 <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	73c080e7          	jalr	1852(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	726080e7          	jalr	1830(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9e4080e7          	jalr	-1564(ra) # 80001528 <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e7c080e7          	jalr	-388(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b9a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	0000f497          	auipc	s1,0xf
    80001bc0:	43448493          	addi	s1,s1,1076 # 80010ff0 <proc>
    80001bc4:	00015917          	auipc	s2,0x15
    80001bc8:	e2c90913          	addi	s2,s2,-468 # 800169f0 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	16848493          	addi	s1,s1,360
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a889                	j	80001c40 <allocproc+0x90>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bfa:	4785                	li	a5,1
    80001bfc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	ee4080e7          	jalr	-284(ra) # 80000ae2 <kalloc>
    80001c06:	892a                	mv	s2,a0
    80001c08:	eca8                	sd	a0,88(s1)
    80001c0a:	c131                	beqz	a0,80001c4e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	e5c080e7          	jalr	-420(ra) # 80001a6a <proc_pagetable>
    80001c16:	892a                	mv	s2,a0
    80001c18:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c1a:	c531                	beqz	a0,80001c66 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c1c:	07000613          	li	a2,112
    80001c20:	4581                	li	a1,0
    80001c22:	06048513          	addi	a0,s1,96
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	0a8080e7          	jalr	168(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c2e:	00000797          	auipc	a5,0x0
    80001c32:	db078793          	addi	a5,a5,-592 # 800019de <forkret>
    80001c36:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c38:	60bc                	ld	a5,64(s1)
    80001c3a:	6705                	lui	a4,0x1
    80001c3c:	97ba                	add	a5,a5,a4
    80001c3e:	f4bc                	sd	a5,104(s1)
}
    80001c40:	8526                	mv	a0,s1
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6902                	ld	s2,0(sp)
    80001c4a:	6105                	addi	sp,sp,32
    80001c4c:	8082                	ret
    freeproc(p);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	f08080e7          	jalr	-248(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	02c080e7          	jalr	44(ra) # 80000c86 <release>
    return 0;
    80001c62:	84ca                	mv	s1,s2
    80001c64:	bff1                	j	80001c40 <allocproc+0x90>
    freeproc(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	ef0080e7          	jalr	-272(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	014080e7          	jalr	20(ra) # 80000c86 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	b7d1                	j	80001c40 <allocproc+0x90>

0000000080001c7e <userinit>:
{
    80001c7e:	1101                	addi	sp,sp,-32
    80001c80:	ec06                	sd	ra,24(sp)
    80001c82:	e822                	sd	s0,16(sp)
    80001c84:	e426                	sd	s1,8(sp)
    80001c86:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	f28080e7          	jalr	-216(ra) # 80001bb0 <allocproc>
    80001c90:	84aa                	mv	s1,a0
  initproc = p;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	caa7bb23          	sd	a0,-842(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c9a:	03400613          	li	a2,52
    80001c9e:	00007597          	auipc	a1,0x7
    80001ca2:	c4258593          	addi	a1,a1,-958 # 800088e0 <initcode>
    80001ca6:	6928                	ld	a0,80(a0)
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	6a8080e7          	jalr	1704(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cb0:	6785                	lui	a5,0x1
    80001cb2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb4:	6cb8                	ld	a4,88(s1)
    80001cb6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cbe:	4641                	li	a2,16
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	54058593          	addi	a1,a1,1344 # 80008200 <digits+0x1c0>
    80001cc8:	15848513          	addi	a0,s1,344
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	14a080e7          	jalr	330(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cd4:	00006517          	auipc	a0,0x6
    80001cd8:	53c50513          	addi	a0,a0,1340 # 80008210 <digits+0x1d0>
    80001cdc:	00002097          	auipc	ra,0x2
    80001ce0:	1d8080e7          	jalr	472(ra) # 80003eb4 <namei>
    80001ce4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce8:	478d                	li	a5,3
    80001cea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	f98080e7          	jalr	-104(ra) # 80000c86 <release>
}
    80001cf6:	60e2                	ld	ra,24(sp)
    80001cf8:	6442                	ld	s0,16(sp)
    80001cfa:	64a2                	ld	s1,8(sp)
    80001cfc:	6105                	addi	sp,sp,32
    80001cfe:	8082                	ret

0000000080001d00 <growproc>:
{
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	e04a                	sd	s2,0(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	c98080e7          	jalr	-872(ra) # 800019a6 <myproc>
    80001d16:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d18:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d1a:	01204c63          	bgtz	s2,80001d32 <growproc+0x32>
  } else if(n < 0){
    80001d1e:	02094663          	bltz	s2,80001d4a <growproc+0x4a>
  p->sz = sz;
    80001d22:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d24:	4501                	li	a0,0
}
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d32:	4691                	li	a3,4
    80001d34:	00b90633          	add	a2,s2,a1
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6d0080e7          	jalr	1744(ra) # 8000140a <uvmalloc>
    80001d42:	85aa                	mv	a1,a0
    80001d44:	fd79                	bnez	a0,80001d22 <growproc+0x22>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bff9                	j	80001d26 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	00b90633          	add	a2,s2,a1
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	672080e7          	jalr	1650(ra) # 800013c2 <uvmdealloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	b7e1                	j	80001d22 <growproc+0x22>

0000000080001d5c <fork>:
{
    80001d5c:	7139                	addi	sp,sp,-64
    80001d5e:	fc06                	sd	ra,56(sp)
    80001d60:	f822                	sd	s0,48(sp)
    80001d62:	f426                	sd	s1,40(sp)
    80001d64:	f04a                	sd	s2,32(sp)
    80001d66:	ec4e                	sd	s3,24(sp)
    80001d68:	e852                	sd	s4,16(sp)
    80001d6a:	e456                	sd	s5,8(sp)
    80001d6c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	c38080e7          	jalr	-968(ra) # 800019a6 <myproc>
    80001d76:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	e38080e7          	jalr	-456(ra) # 80001bb0 <allocproc>
    80001d80:	10050c63          	beqz	a0,80001e98 <fork+0x13c>
    80001d84:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d86:	048ab603          	ld	a2,72(s5)
    80001d8a:	692c                	ld	a1,80(a0)
    80001d8c:	050ab503          	ld	a0,80(s5)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	7d2080e7          	jalr	2002(ra) # 80001562 <uvmcopy>
    80001d98:	04054863          	bltz	a0,80001de8 <fork+0x8c>
  np->sz = p->sz;
    80001d9c:	048ab783          	ld	a5,72(s5)
    80001da0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001da4:	058ab683          	ld	a3,88(s5)
    80001da8:	87b6                	mv	a5,a3
    80001daa:	058a3703          	ld	a4,88(s4)
    80001dae:	12068693          	addi	a3,a3,288
    80001db2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db6:	6788                	ld	a0,8(a5)
    80001db8:	6b8c                	ld	a1,16(a5)
    80001dba:	6f90                	ld	a2,24(a5)
    80001dbc:	01073023          	sd	a6,0(a4)
    80001dc0:	e708                	sd	a0,8(a4)
    80001dc2:	eb0c                	sd	a1,16(a4)
    80001dc4:	ef10                	sd	a2,24(a4)
    80001dc6:	02078793          	addi	a5,a5,32
    80001dca:	02070713          	addi	a4,a4,32
    80001dce:	fed792e3          	bne	a5,a3,80001db2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd2:	058a3783          	ld	a5,88(s4)
    80001dd6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dda:	0d0a8493          	addi	s1,s5,208
    80001dde:	0d0a0913          	addi	s2,s4,208
    80001de2:	150a8993          	addi	s3,s5,336
    80001de6:	a00d                	j	80001e08 <fork+0xac>
    freeproc(np);
    80001de8:	8552                	mv	a0,s4
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	d6e080e7          	jalr	-658(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001df2:	8552                	mv	a0,s4
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	e92080e7          	jalr	-366(ra) # 80000c86 <release>
    return -1;
    80001dfc:	597d                	li	s2,-1
    80001dfe:	a059                	j	80001e84 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e00:	04a1                	addi	s1,s1,8
    80001e02:	0921                	addi	s2,s2,8
    80001e04:	01348b63          	beq	s1,s3,80001e1a <fork+0xbe>
    if(p->ofile[i])
    80001e08:	6088                	ld	a0,0(s1)
    80001e0a:	d97d                	beqz	a0,80001e00 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0c:	00002097          	auipc	ra,0x2
    80001e10:	71a080e7          	jalr	1818(ra) # 80004526 <filedup>
    80001e14:	00a93023          	sd	a0,0(s2)
    80001e18:	b7e5                	j	80001e00 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e1a:	150ab503          	ld	a0,336(s5)
    80001e1e:	00002097          	auipc	ra,0x2
    80001e22:	8b2080e7          	jalr	-1870(ra) # 800036d0 <idup>
    80001e26:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	158a8593          	addi	a1,s5,344
    80001e30:	158a0513          	addi	a0,s4,344
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	fe2080e7          	jalr	-30(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e3c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e40:	8552                	mv	a0,s4
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e44080e7          	jalr	-444(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e4a:	0000f497          	auipc	s1,0xf
    80001e4e:	d8e48493          	addi	s1,s1,-626 # 80010bd8 <wait_lock>
    80001e52:	8526                	mv	a0,s1
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e5c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	d66080e7          	jalr	-666(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e74:	478d                	li	a5,3
    80001e76:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e7a:	8552                	mv	a0,s4
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0a080e7          	jalr	-502(ra) # 80000c86 <release>
}
    80001e84:	854a                	mv	a0,s2
    80001e86:	70e2                	ld	ra,56(sp)
    80001e88:	7442                	ld	s0,48(sp)
    80001e8a:	74a2                	ld	s1,40(sp)
    80001e8c:	7902                	ld	s2,32(sp)
    80001e8e:	69e2                	ld	s3,24(sp)
    80001e90:	6a42                	ld	s4,16(sp)
    80001e92:	6aa2                	ld	s5,8(sp)
    80001e94:	6121                	addi	sp,sp,64
    80001e96:	8082                	ret
    return -1;
    80001e98:	597d                	li	s2,-1
    80001e9a:	b7ed                	j	80001e84 <fork+0x128>

0000000080001e9c <scheduler>:
{
    80001e9c:	7139                	addi	sp,sp,-64
    80001e9e:	fc06                	sd	ra,56(sp)
    80001ea0:	f822                	sd	s0,48(sp)
    80001ea2:	f426                	sd	s1,40(sp)
    80001ea4:	f04a                	sd	s2,32(sp)
    80001ea6:	ec4e                	sd	s3,24(sp)
    80001ea8:	e852                	sd	s4,16(sp)
    80001eaa:	e456                	sd	s5,8(sp)
    80001eac:	e05a                	sd	s6,0(sp)
    80001eae:	0080                	addi	s0,sp,64
    80001eb0:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb4:	00779a93          	slli	s5,a5,0x7
    80001eb8:	0000f717          	auipc	a4,0xf
    80001ebc:	d0870713          	addi	a4,a4,-760 # 80010bc0 <pid_lock>
    80001ec0:	9756                	add	a4,a4,s5
    80001ec2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec6:	0000f717          	auipc	a4,0xf
    80001eca:	d3270713          	addi	a4,a4,-718 # 80010bf8 <cpus+0x8>
    80001ece:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed2:	4b11                	li	s6,4
        c->proc = p;
    80001ed4:	079e                	slli	a5,a5,0x7
    80001ed6:	0000fa17          	auipc	s4,0xf
    80001eda:	ceaa0a13          	addi	s4,s4,-790 # 80010bc0 <pid_lock>
    80001ede:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee0:	00015917          	auipc	s2,0x15
    80001ee4:	b1090913          	addi	s2,s2,-1264 # 800169f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eec:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef0:	10079073          	csrw	sstatus,a5
    80001ef4:	0000f497          	auipc	s1,0xf
    80001ef8:	0fc48493          	addi	s1,s1,252 # 80010ff0 <proc>
    80001efc:	a811                	j	80001f10 <scheduler+0x74>
      release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d86080e7          	jalr	-634(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	16848493          	addi	s1,s1,360
    80001f0c:	fd248ee3          	beq	s1,s2,80001ee8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	cc0080e7          	jalr	-832(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80001f1a:	4c9c                	lw	a5,24(s1)
    80001f1c:	ff3791e3          	bne	a5,s3,80001efe <scheduler+0x62>
        p->state = RUNNING;
    80001f20:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f24:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f28:	06048593          	addi	a1,s1,96
    80001f2c:	8556                	mv	a0,s5
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	734080e7          	jalr	1844(ra) # 80002662 <swtch>
        c->proc = 0;
    80001f36:	020a3823          	sd	zero,48(s4)
    80001f3a:	b7d1                	j	80001efe <scheduler+0x62>

0000000080001f3c <sched>:
{
    80001f3c:	7179                	addi	sp,sp,-48
    80001f3e:	f406                	sd	ra,40(sp)
    80001f40:	f022                	sd	s0,32(sp)
    80001f42:	ec26                	sd	s1,24(sp)
    80001f44:	e84a                	sd	s2,16(sp)
    80001f46:	e44e                	sd	s3,8(sp)
    80001f48:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	a5c080e7          	jalr	-1444(ra) # 800019a6 <myproc>
    80001f52:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c04080e7          	jalr	-1020(ra) # 80000b58 <holding>
    80001f5c:	c93d                	beqz	a0,80001fd2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f5e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f60:	2781                	sext.w	a5,a5
    80001f62:	079e                	slli	a5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	c5c70713          	addi	a4,a4,-932 # 80010bc0 <pid_lock>
    80001f6c:	97ba                	add	a5,a5,a4
    80001f6e:	0a87a703          	lw	a4,168(a5)
    80001f72:	4785                	li	a5,1
    80001f74:	06f71763          	bne	a4,a5,80001fe2 <sched+0xa6>
  if(p->state == RUNNING)
    80001f78:	4c98                	lw	a4,24(s1)
    80001f7a:	4791                	li	a5,4
    80001f7c:	06f70b63          	beq	a4,a5,80001ff2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f84:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f86:	efb5                	bnez	a5,80002002 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f88:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8a:	0000f917          	auipc	s2,0xf
    80001f8e:	c3690913          	addi	s2,s2,-970 # 80010bc0 <pid_lock>
    80001f92:	2781                	sext.w	a5,a5
    80001f94:	079e                	slli	a5,a5,0x7
    80001f96:	97ca                	add	a5,a5,s2
    80001f98:	0ac7a983          	lw	s3,172(a5)
    80001f9c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	0000f597          	auipc	a1,0xf
    80001fa6:	c5658593          	addi	a1,a1,-938 # 80010bf8 <cpus+0x8>
    80001faa:	95be                	add	a1,a1,a5
    80001fac:	06048513          	addi	a0,s1,96
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	6b2080e7          	jalr	1714(ra) # 80002662 <swtch>
    80001fb8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	993e                	add	s2,s2,a5
    80001fc0:	0b392623          	sw	s3,172(s2)
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6145                	addi	sp,sp,48
    80001fd0:	8082                	ret
    panic("sched p->lock");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	24650513          	addi	a0,a0,582 # 80008218 <digits+0x1d8>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	562080e7          	jalr	1378(ra) # 8000053c <panic>
    panic("sched locks");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	24650513          	addi	a0,a0,582 # 80008228 <digits+0x1e8>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	552080e7          	jalr	1362(ra) # 8000053c <panic>
    panic("sched running");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	24650513          	addi	a0,a0,582 # 80008238 <digits+0x1f8>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	542080e7          	jalr	1346(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	24650513          	addi	a0,a0,582 # 80008248 <digits+0x208>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	532080e7          	jalr	1330(ra) # 8000053c <panic>

0000000080002012 <yield>:
{
    80002012:	1101                	addi	sp,sp,-32
    80002014:	ec06                	sd	ra,24(sp)
    80002016:	e822                	sd	s0,16(sp)
    80002018:	e426                	sd	s1,8(sp)
    8000201a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	98a080e7          	jalr	-1654(ra) # 800019a6 <myproc>
    80002024:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	bac080e7          	jalr	-1108(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000202e:	478d                	li	a5,3
    80002030:	cc9c                	sw	a5,24(s1)
  sched();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	f0a080e7          	jalr	-246(ra) # 80001f3c <sched>
  release(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c4a080e7          	jalr	-950(ra) # 80000c86 <release>
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	addi	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000204e:	7179                	addi	sp,sp,-48
    80002050:	f406                	sd	ra,40(sp)
    80002052:	f022                	sd	s0,32(sp)
    80002054:	ec26                	sd	s1,24(sp)
    80002056:	e84a                	sd	s2,16(sp)
    80002058:	e44e                	sd	s3,8(sp)
    8000205a:	1800                	addi	s0,sp,48
    8000205c:	89aa                	mv	s3,a0
    8000205e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	946080e7          	jalr	-1722(ra) # 800019a6 <myproc>
    80002068:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b68080e7          	jalr	-1176(ra) # 80000bd2 <acquire>
  release(lk);
    80002072:	854a                	mv	a0,s2
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c12080e7          	jalr	-1006(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000207c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002080:	4789                	li	a5,2
    80002082:	cc9c                	sw	a5,24(s1)

  sched();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	eb8080e7          	jalr	-328(ra) # 80001f3c <sched>

  // Tidy up.
  p->chan = 0;
    8000208c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	bf4080e7          	jalr	-1036(ra) # 80000c86 <release>
  acquire(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b36080e7          	jalr	-1226(ra) # 80000bd2 <acquire>
}
    800020a4:	70a2                	ld	ra,40(sp)
    800020a6:	7402                	ld	s0,32(sp)
    800020a8:	64e2                	ld	s1,24(sp)
    800020aa:	6942                	ld	s2,16(sp)
    800020ac:	69a2                	ld	s3,8(sp)
    800020ae:	6145                	addi	sp,sp,48
    800020b0:	8082                	ret

00000000800020b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b2:	7139                	addi	sp,sp,-64
    800020b4:	fc06                	sd	ra,56(sp)
    800020b6:	f822                	sd	s0,48(sp)
    800020b8:	f426                	sd	s1,40(sp)
    800020ba:	f04a                	sd	s2,32(sp)
    800020bc:	ec4e                	sd	s3,24(sp)
    800020be:	e852                	sd	s4,16(sp)
    800020c0:	e456                	sd	s5,8(sp)
    800020c2:	0080                	addi	s0,sp,64
    800020c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020c6:	0000f497          	auipc	s1,0xf
    800020ca:	f2a48493          	addi	s1,s1,-214 # 80010ff0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ce:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d2:	00015917          	auipc	s2,0x15
    800020d6:	91e90913          	addi	s2,s2,-1762 # 800169f0 <tickslock>
    800020da:	a811                	j	800020ee <wakeup+0x3c>
      }
      release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	ba8080e7          	jalr	-1112(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	16848493          	addi	s1,s1,360
    800020ea:	03248663          	beq	s1,s2,80002116 <wakeup+0x64>
    if(p != myproc()){
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	8b8080e7          	jalr	-1864(ra) # 800019a6 <myproc>
    800020f6:	fea488e3          	beq	s1,a0,800020e6 <wakeup+0x34>
      acquire(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ad6080e7          	jalr	-1322(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002104:	4c9c                	lw	a5,24(s1)
    80002106:	fd379be3          	bne	a5,s3,800020dc <wakeup+0x2a>
    8000210a:	709c                	ld	a5,32(s1)
    8000210c:	fd4798e3          	bne	a5,s4,800020dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002110:	0154ac23          	sw	s5,24(s1)
    80002114:	b7e1                	j	800020dc <wakeup+0x2a>
    }
  }
}
    80002116:	70e2                	ld	ra,56(sp)
    80002118:	7442                	ld	s0,48(sp)
    8000211a:	74a2                	ld	s1,40(sp)
    8000211c:	7902                	ld	s2,32(sp)
    8000211e:	69e2                	ld	s3,24(sp)
    80002120:	6a42                	ld	s4,16(sp)
    80002122:	6aa2                	ld	s5,8(sp)
    80002124:	6121                	addi	sp,sp,64
    80002126:	8082                	ret

0000000080002128 <reparent>:
{
    80002128:	7179                	addi	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	e052                	sd	s4,0(sp)
    80002136:	1800                	addi	s0,sp,48
    80002138:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000213a:	0000f497          	auipc	s1,0xf
    8000213e:	eb648493          	addi	s1,s1,-330 # 80010ff0 <proc>
      pp->parent = initproc;
    80002142:	00007a17          	auipc	s4,0x7
    80002146:	806a0a13          	addi	s4,s4,-2042 # 80008948 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214a:	00015997          	auipc	s3,0x15
    8000214e:	8a698993          	addi	s3,s3,-1882 # 800169f0 <tickslock>
    80002152:	a029                	j	8000215c <reparent+0x34>
    80002154:	16848493          	addi	s1,s1,360
    80002158:	01348d63          	beq	s1,s3,80002172 <reparent+0x4a>
    if(pp->parent == p){
    8000215c:	7c9c                	ld	a5,56(s1)
    8000215e:	ff279be3          	bne	a5,s2,80002154 <reparent+0x2c>
      pp->parent = initproc;
    80002162:	000a3503          	ld	a0,0(s4)
    80002166:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	f4a080e7          	jalr	-182(ra) # 800020b2 <wakeup>
    80002170:	b7d5                	j	80002154 <reparent+0x2c>
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6a02                	ld	s4,0(sp)
    8000217e:	6145                	addi	sp,sp,48
    80002180:	8082                	ret

0000000080002182 <exit>:
{
    80002182:	7179                	addi	sp,sp,-48
    80002184:	f406                	sd	ra,40(sp)
    80002186:	f022                	sd	s0,32(sp)
    80002188:	ec26                	sd	s1,24(sp)
    8000218a:	e84a                	sd	s2,16(sp)
    8000218c:	e44e                	sd	s3,8(sp)
    8000218e:	e052                	sd	s4,0(sp)
    80002190:	1800                	addi	s0,sp,48
    80002192:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	812080e7          	jalr	-2030(ra) # 800019a6 <myproc>
    8000219c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000219e:	00006797          	auipc	a5,0x6
    800021a2:	7aa7b783          	ld	a5,1962(a5) # 80008948 <initproc>
    800021a6:	0d050493          	addi	s1,a0,208
    800021aa:	15050913          	addi	s2,a0,336
    800021ae:	02a79363          	bne	a5,a0,800021d4 <exit+0x52>
    panic("init exiting");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	0ae50513          	addi	a0,a0,174 # 80008260 <digits+0x220>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	382080e7          	jalr	898(ra) # 8000053c <panic>
      fileclose(f);
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	3b6080e7          	jalr	950(ra) # 80004578 <fileclose>
      p->ofile[fd] = 0;
    800021ca:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ce:	04a1                	addi	s1,s1,8
    800021d0:	01248563          	beq	s1,s2,800021da <exit+0x58>
    if(p->ofile[fd]){
    800021d4:	6088                	ld	a0,0(s1)
    800021d6:	f575                	bnez	a0,800021c2 <exit+0x40>
    800021d8:	bfdd                	j	800021ce <exit+0x4c>
  begin_op();
    800021da:	00002097          	auipc	ra,0x2
    800021de:	eda080e7          	jalr	-294(ra) # 800040b4 <begin_op>
  iput(p->cwd);
    800021e2:	1509b503          	ld	a0,336(s3)
    800021e6:	00001097          	auipc	ra,0x1
    800021ea:	6e2080e7          	jalr	1762(ra) # 800038c8 <iput>
  end_op();
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	f40080e7          	jalr	-192(ra) # 8000412e <end_op>
  p->cwd = 0;
    800021f6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	9de48493          	addi	s1,s1,-1570 # 80010bd8 <wait_lock>
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9ce080e7          	jalr	-1586(ra) # 80000bd2 <acquire>
  reparent(p);
    8000220c:	854e                	mv	a0,s3
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	f1a080e7          	jalr	-230(ra) # 80002128 <reparent>
  wakeup(p->parent);
    80002216:	0389b503          	ld	a0,56(s3)
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	e98080e7          	jalr	-360(ra) # 800020b2 <wakeup>
  acquire(&p->lock);
    80002222:	854e                	mv	a0,s3
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9ae080e7          	jalr	-1618(ra) # 80000bd2 <acquire>
  p->xstate = status;
    8000222c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002230:	4795                	li	a5,5
    80002232:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a4e080e7          	jalr	-1458(ra) # 80000c86 <release>
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	cfc080e7          	jalr	-772(ra) # 80001f3c <sched>
  panic("zombie exit");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	02850513          	addi	a0,a0,40 # 80008270 <digits+0x230>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>

0000000080002258 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	1800                	addi	s0,sp,48
    80002266:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	d8848493          	addi	s1,s1,-632 # 80010ff0 <proc>
    80002270:	00014997          	auipc	s3,0x14
    80002274:	78098993          	addi	s3,s3,1920 # 800169f0 <tickslock>
    acquire(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	958080e7          	jalr	-1704(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002282:	589c                	lw	a5,48(s1)
    80002284:	01278d63          	beq	a5,s2,8000229e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002292:	16848493          	addi	s1,s1,360
    80002296:	ff3491e3          	bne	s1,s3,80002278 <kill+0x20>
  }
  return -1;
    8000229a:	557d                	li	a0,-1
    8000229c:	a829                	j	800022b6 <kill+0x5e>
      p->killed = 1;
    8000229e:	4785                	li	a5,1
    800022a0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a2:	4c98                	lw	a4,24(s1)
    800022a4:	4789                	li	a5,2
    800022a6:	00f70f63          	beq	a4,a5,800022c4 <kill+0x6c>
      release(&p->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9da080e7          	jalr	-1574(ra) # 80000c86 <release>
      return 0;
    800022b4:	4501                	li	a0,0
}
    800022b6:	70a2                	ld	ra,40(sp)
    800022b8:	7402                	ld	s0,32(sp)
    800022ba:	64e2                	ld	s1,24(sp)
    800022bc:	6942                	ld	s2,16(sp)
    800022be:	69a2                	ld	s3,8(sp)
    800022c0:	6145                	addi	sp,sp,48
    800022c2:	8082                	ret
        p->state = RUNNABLE;
    800022c4:	478d                	li	a5,3
    800022c6:	cc9c                	sw	a5,24(s1)
    800022c8:	b7cd                	j	800022aa <kill+0x52>

00000000800022ca <setkilled>:

void
setkilled(struct proc *p)
{
    800022ca:	1101                	addi	sp,sp,-32
    800022cc:	ec06                	sd	ra,24(sp)
    800022ce:	e822                	sd	s0,16(sp)
    800022d0:	e426                	sd	s1,8(sp)
    800022d2:	1000                	addi	s0,sp,32
    800022d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	8fc080e7          	jalr	-1796(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800022de:	4785                	li	a5,1
    800022e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9a2080e7          	jalr	-1630(ra) # 80000c86 <release>
}
    800022ec:	60e2                	ld	ra,24(sp)
    800022ee:	6442                	ld	s0,16(sp)
    800022f0:	64a2                	ld	s1,8(sp)
    800022f2:	6105                	addi	sp,sp,32
    800022f4:	8082                	ret

00000000800022f6 <killed>:

int
killed(struct proc *p)
{
    800022f6:	1101                	addi	sp,sp,-32
    800022f8:	ec06                	sd	ra,24(sp)
    800022fa:	e822                	sd	s0,16(sp)
    800022fc:	e426                	sd	s1,8(sp)
    800022fe:	e04a                	sd	s2,0(sp)
    80002300:	1000                	addi	s0,sp,32
    80002302:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	8ce080e7          	jalr	-1842(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000230c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	974080e7          	jalr	-1676(ra) # 80000c86 <release>
  return k;
}
    8000231a:	854a                	mv	a0,s2
    8000231c:	60e2                	ld	ra,24(sp)
    8000231e:	6442                	ld	s0,16(sp)
    80002320:	64a2                	ld	s1,8(sp)
    80002322:	6902                	ld	s2,0(sp)
    80002324:	6105                	addi	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <wait>:
{
    80002328:	715d                	addi	sp,sp,-80
    8000232a:	e486                	sd	ra,72(sp)
    8000232c:	e0a2                	sd	s0,64(sp)
    8000232e:	fc26                	sd	s1,56(sp)
    80002330:	f84a                	sd	s2,48(sp)
    80002332:	f44e                	sd	s3,40(sp)
    80002334:	f052                	sd	s4,32(sp)
    80002336:	ec56                	sd	s5,24(sp)
    80002338:	e85a                	sd	s6,16(sp)
    8000233a:	e45e                	sd	s7,8(sp)
    8000233c:	e062                	sd	s8,0(sp)
    8000233e:	0880                	addi	s0,sp,80
    80002340:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	664080e7          	jalr	1636(ra) # 800019a6 <myproc>
    8000234a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000234c:	0000f517          	auipc	a0,0xf
    80002350:	88c50513          	addi	a0,a0,-1908 # 80010bd8 <wait_lock>
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87e080e7          	jalr	-1922(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000235c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000235e:	4a15                	li	s4,5
        havekids = 1;
    80002360:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002362:	00014997          	auipc	s3,0x14
    80002366:	68e98993          	addi	s3,s3,1678 # 800169f0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000236a:	0000fc17          	auipc	s8,0xf
    8000236e:	86ec0c13          	addi	s8,s8,-1938 # 80010bd8 <wait_lock>
    80002372:	a0d1                	j	80002436 <wait+0x10e>
          pid = pp->pid;
    80002374:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002378:	000b0e63          	beqz	s6,80002394 <wait+0x6c>
    8000237c:	4691                	li	a3,4
    8000237e:	02c48613          	addi	a2,s1,44
    80002382:	85da                	mv	a1,s6
    80002384:	05093503          	ld	a0,80(s2)
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	2de080e7          	jalr	734(ra) # 80001666 <copyout>
    80002390:	04054163          	bltz	a0,800023d2 <wait+0xaa>
          freeproc(pp);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	7c2080e7          	jalr	1986(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8e6080e7          	jalr	-1818(ra) # 80000c86 <release>
          release(&wait_lock);
    800023a8:	0000f517          	auipc	a0,0xf
    800023ac:	83050513          	addi	a0,a0,-2000 # 80010bd8 <wait_lock>
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8d6080e7          	jalr	-1834(ra) # 80000c86 <release>
}
    800023b8:	854e                	mv	a0,s3
    800023ba:	60a6                	ld	ra,72(sp)
    800023bc:	6406                	ld	s0,64(sp)
    800023be:	74e2                	ld	s1,56(sp)
    800023c0:	7942                	ld	s2,48(sp)
    800023c2:	79a2                	ld	s3,40(sp)
    800023c4:	7a02                	ld	s4,32(sp)
    800023c6:	6ae2                	ld	s5,24(sp)
    800023c8:	6b42                	ld	s6,16(sp)
    800023ca:	6ba2                	ld	s7,8(sp)
    800023cc:	6c02                	ld	s8,0(sp)
    800023ce:	6161                	addi	sp,sp,80
    800023d0:	8082                	ret
            release(&pp->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b2080e7          	jalr	-1870(ra) # 80000c86 <release>
            release(&wait_lock);
    800023dc:	0000e517          	auipc	a0,0xe
    800023e0:	7fc50513          	addi	a0,a0,2044 # 80010bd8 <wait_lock>
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a2080e7          	jalr	-1886(ra) # 80000c86 <release>
            return -1;
    800023ec:	59fd                	li	s3,-1
    800023ee:	b7e9                	j	800023b8 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	03348463          	beq	s1,s3,8000241c <wait+0xf4>
      if(pp->parent == p){
    800023f8:	7c9c                	ld	a5,56(s1)
    800023fa:	ff279be3          	bne	a5,s2,800023f0 <wait+0xc8>
        acquire(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	f74785e3          	beq	a5,s4,80002374 <wait+0x4c>
        release(&pp->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	876080e7          	jalr	-1930(ra) # 80000c86 <release>
        havekids = 1;
    80002418:	8756                	mv	a4,s5
    8000241a:	bfd9                	j	800023f0 <wait+0xc8>
    if(!havekids || killed(p)){
    8000241c:	c31d                	beqz	a4,80002442 <wait+0x11a>
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	ed6080e7          	jalr	-298(ra) # 800022f6 <killed>
    80002428:	ed09                	bnez	a0,80002442 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000242a:	85e2                	mv	a1,s8
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	c20080e7          	jalr	-992(ra) # 8000204e <sleep>
    havekids = 0;
    80002436:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	bb848493          	addi	s1,s1,-1096 # 80010ff0 <proc>
    80002440:	bf65                	j	800023f8 <wait+0xd0>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	79650513          	addi	a0,a0,1942 # 80010bd8 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	83c080e7          	jalr	-1988(ra) # 80000c86 <release>
      return -1;
    80002452:	59fd                	li	s3,-1
    80002454:	b795                	j	800023b8 <wait+0x90>

0000000080002456 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002456:	7179                	addi	sp,sp,-48
    80002458:	f406                	sd	ra,40(sp)
    8000245a:	f022                	sd	s0,32(sp)
    8000245c:	ec26                	sd	s1,24(sp)
    8000245e:	e84a                	sd	s2,16(sp)
    80002460:	e44e                	sd	s3,8(sp)
    80002462:	e052                	sd	s4,0(sp)
    80002464:	1800                	addi	s0,sp,48
    80002466:	84aa                	mv	s1,a0
    80002468:	892e                	mv	s2,a1
    8000246a:	89b2                	mv	s3,a2
    8000246c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	538080e7          	jalr	1336(ra) # 800019a6 <myproc>
  if(user_dst){
    80002476:	c08d                	beqz	s1,80002498 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002478:	86d2                	mv	a3,s4
    8000247a:	864e                	mv	a2,s3
    8000247c:	85ca                	mv	a1,s2
    8000247e:	6928                	ld	a0,80(a0)
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	1e6080e7          	jalr	486(ra) # 80001666 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6a02                	ld	s4,0(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
    memmove((char *)dst, src, len);
    80002498:	000a061b          	sext.w	a2,s4
    8000249c:	85ce                	mv	a1,s3
    8000249e:	854a                	mv	a0,s2
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	88a080e7          	jalr	-1910(ra) # 80000d2a <memmove>
    return 0;
    800024a8:	8526                	mv	a0,s1
    800024aa:	bff9                	j	80002488 <either_copyout+0x32>

00000000800024ac <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
    800024bc:	892a                	mv	s2,a0
    800024be:	84ae                	mv	s1,a1
    800024c0:	89b2                	mv	s3,a2
    800024c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	4e2080e7          	jalr	1250(ra) # 800019a6 <myproc>
  if(user_src){
    800024cc:	c08d                	beqz	s1,800024ee <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ce:	86d2                	mv	a3,s4
    800024d0:	864e                	mv	a2,s3
    800024d2:	85ca                	mv	a1,s2
    800024d4:	6928                	ld	a0,80(a0)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	21c080e7          	jalr	540(ra) # 800016f2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6a02                	ld	s4,0(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ee:	000a061b          	sext.w	a2,s4
    800024f2:	85ce                	mv	a1,s3
    800024f4:	854a                	mv	a0,s2
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	834080e7          	jalr	-1996(ra) # 80000d2a <memmove>
    return 0;
    800024fe:	8526                	mv	a0,s1
    80002500:	bff9                	j	800024de <either_copyin+0x32>

0000000080002502 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002502:	715d                	addi	sp,sp,-80
    80002504:	e486                	sd	ra,72(sp)
    80002506:	e0a2                	sd	s0,64(sp)
    80002508:	fc26                	sd	s1,56(sp)
    8000250a:	f84a                	sd	s2,48(sp)
    8000250c:	f44e                	sd	s3,40(sp)
    8000250e:	f052                	sd	s4,32(sp)
    80002510:	ec56                	sd	s5,24(sp)
    80002512:	e85a                	sd	s6,16(sp)
    80002514:	e45e                	sd	s7,8(sp)
    80002516:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002518:	00006517          	auipc	a0,0x6
    8000251c:	bb050513          	addi	a0,a0,-1104 # 800080c8 <digits+0x88>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	066080e7          	jalr	102(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002528:	0000f497          	auipc	s1,0xf
    8000252c:	c2048493          	addi	s1,s1,-992 # 80011148 <proc+0x158>
    80002530:	00014917          	auipc	s2,0x14
    80002534:	61890913          	addi	s2,s2,1560 # 80016b48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002538:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000253a:	00006997          	auipc	s3,0x6
    8000253e:	d4698993          	addi	s3,s3,-698 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002542:	00006a97          	auipc	s5,0x6
    80002546:	d46a8a93          	addi	s5,s5,-698 # 80008288 <digits+0x248>
    printf("\n");
    8000254a:	00006a17          	auipc	s4,0x6
    8000254e:	b7ea0a13          	addi	s4,s4,-1154 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002552:	00006b97          	auipc	s7,0x6
    80002556:	daeb8b93          	addi	s7,s7,-594 # 80008300 <states.1>
    8000255a:	a00d                	j	8000257c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255c:	ed86a583          	lw	a1,-296(a3)
    80002560:	8556                	mv	a0,s5
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	024080e7          	jalr	36(ra) # 80000586 <printf>
    printf("\n");
    8000256a:	8552                	mv	a0,s4
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	01a080e7          	jalr	26(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002574:	16848493          	addi	s1,s1,360
    80002578:	03248263          	beq	s1,s2,8000259c <procdump+0x9a>
    if(p->state == UNUSED)
    8000257c:	86a6                	mv	a3,s1
    8000257e:	ec04a783          	lw	a5,-320(s1)
    80002582:	dbed                	beqz	a5,80002574 <procdump+0x72>
      state = "???";
    80002584:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002586:	fcfb6be3          	bltu	s6,a5,8000255c <procdump+0x5a>
    8000258a:	02079713          	slli	a4,a5,0x20
    8000258e:	01d75793          	srli	a5,a4,0x1d
    80002592:	97de                	add	a5,a5,s7
    80002594:	6390                	ld	a2,0(a5)
    80002596:	f279                	bnez	a2,8000255c <procdump+0x5a>
      state = "???";
    80002598:	864e                	mv	a2,s3
    8000259a:	b7c9                	j	8000255c <procdump+0x5a>
  }
}
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6161                	addi	sp,sp,80
    800025b0:	8082                	ret

00000000800025b2 <procreturn>:

void
procreturn(void) 
{
    800025b2:	715d                	addi	sp,sp,-80
    800025b4:	e486                	sd	ra,72(sp)
    800025b6:	e0a2                	sd	s0,64(sp)
    800025b8:	fc26                	sd	s1,56(sp)
    800025ba:	f84a                	sd	s2,48(sp)
    800025bc:	f44e                	sd	s3,40(sp)
    800025be:	f052                	sd	s4,32(sp)
    800025c0:	ec56                	sd	s5,24(sp)
    800025c2:	e85a                	sd	s6,16(sp)
    800025c4:	e45e                	sd	s7,8(sp)
    800025c6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "5"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c8:	00006517          	auipc	a0,0x6
    800025cc:	b0050513          	addi	a0,a0,-1280 # 800080c8 <digits+0x88>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	fb6080e7          	jalr	-74(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d8:	0000f497          	auipc	s1,0xf
    800025dc:	b7048493          	addi	s1,s1,-1168 # 80011148 <proc+0x158>
    800025e0:	00014917          	auipc	s2,0x14
    800025e4:	56890913          	addi	s2,s2,1384 # 80016b48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025ea:	00006997          	auipc	s3,0x6
    800025ee:	c9698993          	addi	s3,s3,-874 # 80008280 <digits+0x240>

    printf("%s (%d): %s", p->name, p->pid, state);
    800025f2:	00006a97          	auipc	s5,0x6
    800025f6:	ca6a8a93          	addi	s5,s5,-858 # 80008298 <digits+0x258>
    printf("\n");
    800025fa:	00006a17          	auipc	s4,0x6
    800025fe:	acea0a13          	addi	s4,s4,-1330 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002602:	00006b97          	auipc	s7,0x6
    80002606:	cfeb8b93          	addi	s7,s7,-770 # 80008300 <states.1>
    8000260a:	a00d                	j	8000262c <procreturn+0x7a>
    printf("%s (%d): %s", p->name, p->pid, state);
    8000260c:	ed85a603          	lw	a2,-296(a1)
    80002610:	8556                	mv	a0,s5
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	f74080e7          	jalr	-140(ra) # 80000586 <printf>
    printf("\n");
    8000261a:	8552                	mv	a0,s4
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f6a080e7          	jalr	-150(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002624:	16848493          	addi	s1,s1,360
    80002628:	03248263          	beq	s1,s2,8000264c <procreturn+0x9a>
    if(p->state == UNUSED)
    8000262c:	85a6                	mv	a1,s1
    8000262e:	ec04a783          	lw	a5,-320(s1)
    80002632:	dbed                	beqz	a5,80002624 <procreturn+0x72>
      state = "???";
    80002634:	86ce                	mv	a3,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002636:	fcfb6be3          	bltu	s6,a5,8000260c <procreturn+0x5a>
    8000263a:	02079713          	slli	a4,a5,0x20
    8000263e:	01d75793          	srli	a5,a4,0x1d
    80002642:	97de                	add	a5,a5,s7
    80002644:	7b94                	ld	a3,48(a5)
    80002646:	f2f9                	bnez	a3,8000260c <procreturn+0x5a>
      state = "???";
    80002648:	86ce                	mv	a3,s3
    8000264a:	b7c9                	j	8000260c <procreturn+0x5a>
//states[p->state]-states[0]
  }



    8000264c:	60a6                	ld	ra,72(sp)
    8000264e:	6406                	ld	s0,64(sp)
    80002650:	74e2                	ld	s1,56(sp)
    80002652:	7942                	ld	s2,48(sp)
    80002654:	79a2                	ld	s3,40(sp)
    80002656:	7a02                	ld	s4,32(sp)
    80002658:	6ae2                	ld	s5,24(sp)
    8000265a:	6b42                	ld	s6,16(sp)
    8000265c:	6ba2                	ld	s7,8(sp)
    8000265e:	6161                	addi	sp,sp,80
    80002660:	8082                	ret

0000000080002662 <swtch>:
    80002662:	00153023          	sd	ra,0(a0)
    80002666:	00253423          	sd	sp,8(a0)
    8000266a:	e900                	sd	s0,16(a0)
    8000266c:	ed04                	sd	s1,24(a0)
    8000266e:	03253023          	sd	s2,32(a0)
    80002672:	03353423          	sd	s3,40(a0)
    80002676:	03453823          	sd	s4,48(a0)
    8000267a:	03553c23          	sd	s5,56(a0)
    8000267e:	05653023          	sd	s6,64(a0)
    80002682:	05753423          	sd	s7,72(a0)
    80002686:	05853823          	sd	s8,80(a0)
    8000268a:	05953c23          	sd	s9,88(a0)
    8000268e:	07a53023          	sd	s10,96(a0)
    80002692:	07b53423          	sd	s11,104(a0)
    80002696:	0005b083          	ld	ra,0(a1)
    8000269a:	0085b103          	ld	sp,8(a1)
    8000269e:	6980                	ld	s0,16(a1)
    800026a0:	6d84                	ld	s1,24(a1)
    800026a2:	0205b903          	ld	s2,32(a1)
    800026a6:	0285b983          	ld	s3,40(a1)
    800026aa:	0305ba03          	ld	s4,48(a1)
    800026ae:	0385ba83          	ld	s5,56(a1)
    800026b2:	0405bb03          	ld	s6,64(a1)
    800026b6:	0485bb83          	ld	s7,72(a1)
    800026ba:	0505bc03          	ld	s8,80(a1)
    800026be:	0585bc83          	ld	s9,88(a1)
    800026c2:	0605bd03          	ld	s10,96(a1)
    800026c6:	0685bd83          	ld	s11,104(a1)
    800026ca:	8082                	ret

00000000800026cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026cc:	1141                	addi	sp,sp,-16
    800026ce:	e406                	sd	ra,8(sp)
    800026d0:	e022                	sd	s0,0(sp)
    800026d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d4:	00006597          	auipc	a1,0x6
    800026d8:	c8c58593          	addi	a1,a1,-884 # 80008360 <states.0+0x30>
    800026dc:	00014517          	auipc	a0,0x14
    800026e0:	31450513          	addi	a0,a0,788 # 800169f0 <tickslock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	45e080e7          	jalr	1118(ra) # 80000b42 <initlock>
}
    800026ec:	60a2                	ld	ra,8(sp)
    800026ee:	6402                	ld	s0,0(sp)
    800026f0:	0141                	addi	sp,sp,16
    800026f2:	8082                	ret

00000000800026f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e422                	sd	s0,8(sp)
    800026f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	00003797          	auipc	a5,0x3
    800026fe:	4a678793          	addi	a5,a5,1190 # 80005ba0 <kernelvec>
    80002702:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002706:	6422                	ld	s0,8(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e406                	sd	ra,8(sp)
    80002710:	e022                	sd	s0,0(sp)
    80002712:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	292080e7          	jalr	658(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002720:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002722:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002726:	00005697          	auipc	a3,0x5
    8000272a:	8da68693          	addi	a3,a3,-1830 # 80007000 <_trampoline>
    8000272e:	00005717          	auipc	a4,0x5
    80002732:	8d270713          	addi	a4,a4,-1838 # 80007000 <_trampoline>
    80002736:	8f15                	sub	a4,a4,a3
    80002738:	040007b7          	lui	a5,0x4000
    8000273c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273e:	07b2                	slli	a5,a5,0xc
    80002740:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002742:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002748:	18002673          	csrr	a2,satp
    8000274c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274e:	6d30                	ld	a2,88(a0)
    80002750:	6138                	ld	a4,64(a0)
    80002752:	6585                	lui	a1,0x1
    80002754:	972e                	add	a4,a4,a1
    80002756:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	00000617          	auipc	a2,0x0
    8000275e:	13460613          	addi	a2,a2,308 # 8000288e <usertrap>
    80002762:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002764:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002766:	8612                	mv	a2,tp
    80002768:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002772:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002776:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000277c:	6f18                	ld	a4,24(a4)
    8000277e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002782:	6928                	ld	a0,80(a0)
    80002784:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002786:	00005717          	auipc	a4,0x5
    8000278a:	91670713          	addi	a4,a4,-1770 # 8000709c <userret>
    8000278e:	8f15                	sub	a4,a4,a3
    80002790:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002792:	577d                	li	a4,-1
    80002794:	177e                	slli	a4,a4,0x3f
    80002796:	8d59                	or	a0,a0,a4
    80002798:	9782                	jalr	a5
}
    8000279a:	60a2                	ld	ra,8(sp)
    8000279c:	6402                	ld	s0,0(sp)
    8000279e:	0141                	addi	sp,sp,16
    800027a0:	8082                	ret

00000000800027a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a2:	1101                	addi	sp,sp,-32
    800027a4:	ec06                	sd	ra,24(sp)
    800027a6:	e822                	sd	s0,16(sp)
    800027a8:	e426                	sd	s1,8(sp)
    800027aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ac:	00014497          	auipc	s1,0x14
    800027b0:	24448493          	addi	s1,s1,580 # 800169f0 <tickslock>
    800027b4:	8526                	mv	a0,s1
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	41c080e7          	jalr	1052(ra) # 80000bd2 <acquire>
  ticks++;
    800027be:	00006517          	auipc	a0,0x6
    800027c2:	19250513          	addi	a0,a0,402 # 80008950 <ticks>
    800027c6:	411c                	lw	a5,0(a0)
    800027c8:	2785                	addiw	a5,a5,1
    800027ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	8e6080e7          	jalr	-1818(ra) # 800020b2 <wakeup>
  release(&tickslock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4b0080e7          	jalr	1200(ra) # 80000c86 <release>
}
    800027de:	60e2                	ld	ra,24(sp)
    800027e0:	6442                	ld	s0,16(sp)
    800027e2:	64a2                	ld	s1,8(sp)
    800027e4:	6105                	addi	sp,sp,32
    800027e6:	8082                	ret

00000000800027e8 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e8:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027ec:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ee:	0807df63          	bgez	a5,8000288c <devintr+0xa4>
{
    800027f2:	1101                	addi	sp,sp,-32
    800027f4:	ec06                	sd	ra,24(sp)
    800027f6:	e822                	sd	s0,16(sp)
    800027f8:	e426                	sd	s1,8(sp)
    800027fa:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027fc:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002800:	46a5                	li	a3,9
    80002802:	00d70d63          	beq	a4,a3,8000281c <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002806:	577d                	li	a4,-1
    80002808:	177e                	slli	a4,a4,0x3f
    8000280a:	0705                	addi	a4,a4,1
    return 0;
    8000280c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280e:	04e78e63          	beq	a5,a4,8000286a <devintr+0x82>
  }
}
    80002812:	60e2                	ld	ra,24(sp)
    80002814:	6442                	ld	s0,16(sp)
    80002816:	64a2                	ld	s1,8(sp)
    80002818:	6105                	addi	sp,sp,32
    8000281a:	8082                	ret
    int irq = plic_claim();
    8000281c:	00003097          	auipc	ra,0x3
    80002820:	48c080e7          	jalr	1164(ra) # 80005ca8 <plic_claim>
    80002824:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002826:	47a9                	li	a5,10
    80002828:	02f50763          	beq	a0,a5,80002856 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    8000282c:	4785                	li	a5,1
    8000282e:	02f50963          	beq	a0,a5,80002860 <devintr+0x78>
    return 1;
    80002832:	4505                	li	a0,1
    } else if(irq){
    80002834:	dcf9                	beqz	s1,80002812 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002836:	85a6                	mv	a1,s1
    80002838:	00006517          	auipc	a0,0x6
    8000283c:	b3050513          	addi	a0,a0,-1232 # 80008368 <states.0+0x38>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	d46080e7          	jalr	-698(ra) # 80000586 <printf>
      plic_complete(irq);
    80002848:	8526                	mv	a0,s1
    8000284a:	00003097          	auipc	ra,0x3
    8000284e:	482080e7          	jalr	1154(ra) # 80005ccc <plic_complete>
    return 1;
    80002852:	4505                	li	a0,1
    80002854:	bf7d                	j	80002812 <devintr+0x2a>
      uartintr();
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	13e080e7          	jalr	318(ra) # 80000994 <uartintr>
    if(irq)
    8000285e:	b7ed                	j	80002848 <devintr+0x60>
      virtio_disk_intr();
    80002860:	00004097          	auipc	ra,0x4
    80002864:	932080e7          	jalr	-1742(ra) # 80006192 <virtio_disk_intr>
    if(irq)
    80002868:	b7c5                	j	80002848 <devintr+0x60>
    if(cpuid() == 0){
    8000286a:	fffff097          	auipc	ra,0xfffff
    8000286e:	110080e7          	jalr	272(ra) # 8000197a <cpuid>
    80002872:	c901                	beqz	a0,80002882 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002874:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002878:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287a:	14479073          	csrw	sip,a5
    return 2;
    8000287e:	4509                	li	a0,2
    80002880:	bf49                	j	80002812 <devintr+0x2a>
      clockintr();
    80002882:	00000097          	auipc	ra,0x0
    80002886:	f20080e7          	jalr	-224(ra) # 800027a2 <clockintr>
    8000288a:	b7ed                	j	80002874 <devintr+0x8c>
}
    8000288c:	8082                	ret

000000008000288e <usertrap>:
{
    8000288e:	1101                	addi	sp,sp,-32
    80002890:	ec06                	sd	ra,24(sp)
    80002892:	e822                	sd	s0,16(sp)
    80002894:	e426                	sd	s1,8(sp)
    80002896:	e04a                	sd	s2,0(sp)
    80002898:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289e:	1007f793          	andi	a5,a5,256
    800028a2:	e3b1                	bnez	a5,800028e6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00003797          	auipc	a5,0x3
    800028a8:	2fc78793          	addi	a5,a5,764 # 80005ba0 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	0f6080e7          	jalr	246(ra) # 800019a6 <myproc>
    800028b8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028bc:	14102773          	csrr	a4,sepc
    800028c0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c6:	47a1                	li	a5,8
    800028c8:	02f70763          	beq	a4,a5,800028f6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	f1c080e7          	jalr	-228(ra) # 800027e8 <devintr>
    800028d4:	892a                	mv	s2,a0
    800028d6:	c151                	beqz	a0,8000295a <usertrap+0xcc>
  if(killed(p))
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	a1c080e7          	jalr	-1508(ra) # 800022f6 <killed>
    800028e2:	c929                	beqz	a0,80002934 <usertrap+0xa6>
    800028e4:	a099                	j	8000292a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	aa250513          	addi	a0,a0,-1374 # 80008388 <states.0+0x58>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c4e080e7          	jalr	-946(ra) # 8000053c <panic>
    if(killed(p))
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	a00080e7          	jalr	-1536(ra) # 800022f6 <killed>
    800028fe:	e921                	bnez	a0,8000294e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002900:	6cb8                	ld	a4,88(s1)
    80002902:	6f1c                	ld	a5,24(a4)
    80002904:	0791                	addi	a5,a5,4
    80002906:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    syscall();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	2d4080e7          	jalr	724(ra) # 80002be8 <syscall>
  if(killed(p))
    8000291c:	8526                	mv	a0,s1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	9d8080e7          	jalr	-1576(ra) # 800022f6 <killed>
    80002926:	c911                	beqz	a0,8000293a <usertrap+0xac>
    80002928:	4901                	li	s2,0
    exit(-1);
    8000292a:	557d                	li	a0,-1
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	856080e7          	jalr	-1962(ra) # 80002182 <exit>
  if(which_dev == 2)
    80002934:	4789                	li	a5,2
    80002936:	04f90f63          	beq	s2,a5,80002994 <usertrap+0x106>
  usertrapret();
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	dd2080e7          	jalr	-558(ra) # 8000270c <usertrapret>
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6902                	ld	s2,0(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	00000097          	auipc	ra,0x0
    80002954:	832080e7          	jalr	-1998(ra) # 80002182 <exit>
    80002958:	b765                	j	80002900 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295e:	5890                	lw	a2,48(s1)
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a4850513          	addi	a0,a0,-1464 # 800083a8 <states.0+0x78>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c1e080e7          	jalr	-994(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002974:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a6050513          	addi	a0,a0,-1440 # 800083d8 <states.0+0xa8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c06080e7          	jalr	-1018(ra) # 80000586 <printf>
    setkilled(p);
    80002988:	8526                	mv	a0,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	940080e7          	jalr	-1728(ra) # 800022ca <setkilled>
    80002992:	b769                	j	8000291c <usertrap+0x8e>
    yield();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	67e080e7          	jalr	1662(ra) # 80002012 <yield>
    8000299c:	bf79                	j	8000293a <usertrap+0xac>

000000008000299e <kerneltrap>:
{
    8000299e:	7179                	addi	sp,sp,-48
    800029a0:	f406                	sd	ra,40(sp)
    800029a2:	f022                	sd	s0,32(sp)
    800029a4:	ec26                	sd	s1,24(sp)
    800029a6:	e84a                	sd	s2,16(sp)
    800029a8:	e44e                	sd	s3,8(sp)
    800029aa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029b8:	1004f793          	andi	a5,s1,256
    800029bc:	cb85                	beqz	a5,800029ec <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c4:	ef85                	bnez	a5,800029fc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	e22080e7          	jalr	-478(ra) # 800027e8 <devintr>
    800029ce:	cd1d                	beqz	a0,80002a0c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d0:	4789                	li	a5,2
    800029d2:	06f50a63          	beq	a0,a5,80002a46 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029da:	10049073          	csrw	sstatus,s1
}
    800029de:	70a2                	ld	ra,40(sp)
    800029e0:	7402                	ld	s0,32(sp)
    800029e2:	64e2                	ld	s1,24(sp)
    800029e4:	6942                	ld	s2,16(sp)
    800029e6:	69a2                	ld	s3,8(sp)
    800029e8:	6145                	addi	sp,sp,48
    800029ea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	a0c50513          	addi	a0,a0,-1524 # 800083f8 <states.0+0xc8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b48080e7          	jalr	-1208(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	a2450513          	addi	a0,a0,-1500 # 80008420 <states.0+0xf0>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b38080e7          	jalr	-1224(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002a0c:	85ce                	mv	a1,s3
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	a3250513          	addi	a0,a0,-1486 # 80008440 <states.0+0x110>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b70080e7          	jalr	-1168(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a22:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	a2a50513          	addi	a0,a0,-1494 # 80008450 <states.0+0x120>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b58080e7          	jalr	-1192(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	a3250513          	addi	a0,a0,-1486 # 80008468 <states.0+0x138>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	afe080e7          	jalr	-1282(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	f60080e7          	jalr	-160(ra) # 800019a6 <myproc>
    80002a4e:	d541                	beqz	a0,800029d6 <kerneltrap+0x38>
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	f56080e7          	jalr	-170(ra) # 800019a6 <myproc>
    80002a58:	4d18                	lw	a4,24(a0)
    80002a5a:	4791                	li	a5,4
    80002a5c:	f6f71de3          	bne	a4,a5,800029d6 <kerneltrap+0x38>
    yield();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	5b2080e7          	jalr	1458(ra) # 80002012 <yield>
    80002a68:	b7bd                	j	800029d6 <kerneltrap+0x38>

0000000080002a6a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a6a:	1101                	addi	sp,sp,-32
    80002a6c:	ec06                	sd	ra,24(sp)
    80002a6e:	e822                	sd	s0,16(sp)
    80002a70:	e426                	sd	s1,8(sp)
    80002a72:	1000                	addi	s0,sp,32
    80002a74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f30080e7          	jalr	-208(ra) # 800019a6 <myproc>
  switch (n) {
    80002a7e:	4795                	li	a5,5
    80002a80:	0497e163          	bltu	a5,s1,80002ac2 <argraw+0x58>
    80002a84:	048a                	slli	s1,s1,0x2
    80002a86:	00006717          	auipc	a4,0x6
    80002a8a:	a1a70713          	addi	a4,a4,-1510 # 800084a0 <states.0+0x170>
    80002a8e:	94ba                	add	s1,s1,a4
    80002a90:	409c                	lw	a5,0(s1)
    80002a92:	97ba                	add	a5,a5,a4
    80002a94:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a9a:	60e2                	ld	ra,24(sp)
    80002a9c:	6442                	ld	s0,16(sp)
    80002a9e:	64a2                	ld	s1,8(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret
    return p->trapframe->a1;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	7fa8                	ld	a0,120(a5)
    80002aa8:	bfcd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a2;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	63c8                	ld	a0,128(a5)
    80002aae:	b7f5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a3;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	67c8                	ld	a0,136(a5)
    80002ab4:	b7dd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a4;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	6bc8                	ld	a0,144(a5)
    80002aba:	b7c5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a5;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	6fc8                	ld	a0,152(a5)
    80002ac0:	bfe9                	j	80002a9a <argraw+0x30>
  panic("argraw");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	9b650513          	addi	a0,a0,-1610 # 80008478 <states.0+0x148>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a72080e7          	jalr	-1422(ra) # 8000053c <panic>

0000000080002ad2 <fetchaddr>:
{
    80002ad2:	1101                	addi	sp,sp,-32
    80002ad4:	ec06                	sd	ra,24(sp)
    80002ad6:	e822                	sd	s0,16(sp)
    80002ad8:	e426                	sd	s1,8(sp)
    80002ada:	e04a                	sd	s2,0(sp)
    80002adc:	1000                	addi	s0,sp,32
    80002ade:	84aa                	mv	s1,a0
    80002ae0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	ec4080e7          	jalr	-316(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aea:	653c                	ld	a5,72(a0)
    80002aec:	02f4f863          	bgeu	s1,a5,80002b1c <fetchaddr+0x4a>
    80002af0:	00848713          	addi	a4,s1,8
    80002af4:	02e7e663          	bltu	a5,a4,80002b20 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af8:	46a1                	li	a3,8
    80002afa:	8626                	mv	a2,s1
    80002afc:	85ca                	mv	a1,s2
    80002afe:	6928                	ld	a0,80(a0)
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	bf2080e7          	jalr	-1038(ra) # 800016f2 <copyin>
    80002b08:	00a03533          	snez	a0,a0
    80002b0c:	40a00533          	neg	a0,a0
}
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6902                	ld	s2,0(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
    return -1;
    80002b1c:	557d                	li	a0,-1
    80002b1e:	bfcd                	j	80002b10 <fetchaddr+0x3e>
    80002b20:	557d                	li	a0,-1
    80002b22:	b7fd                	j	80002b10 <fetchaddr+0x3e>

0000000080002b24 <fetchstr>:
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	e44e                	sd	s3,8(sp)
    80002b30:	1800                	addi	s0,sp,48
    80002b32:	892a                	mv	s2,a0
    80002b34:	84ae                	mv	s1,a1
    80002b36:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	e6e080e7          	jalr	-402(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b40:	86ce                	mv	a3,s3
    80002b42:	864a                	mv	a2,s2
    80002b44:	85a6                	mv	a1,s1
    80002b46:	6928                	ld	a0,80(a0)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	c38080e7          	jalr	-968(ra) # 80001780 <copyinstr>
    80002b50:	00054e63          	bltz	a0,80002b6c <fetchstr+0x48>
  return strlen(buf);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	2f2080e7          	jalr	754(ra) # 80000e48 <strlen>
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	69a2                	ld	s3,8(sp)
    80002b68:	6145                	addi	sp,sp,48
    80002b6a:	8082                	ret
    return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	bfc5                	j	80002b5e <fetchstr+0x3a>

0000000080002b70 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	eee080e7          	jalr	-274(ra) # 80002a6a <argraw>
    80002b84:	c088                	sw	a0,0(s1)
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret

0000000080002b90 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b90:	1101                	addi	sp,sp,-32
    80002b92:	ec06                	sd	ra,24(sp)
    80002b94:	e822                	sd	s0,16(sp)
    80002b96:	e426                	sd	s1,8(sp)
    80002b98:	1000                	addi	s0,sp,32
    80002b9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	ece080e7          	jalr	-306(ra) # 80002a6a <argraw>
    80002ba4:	e088                	sd	a0,0(s1)
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb0:	7179                	addi	sp,sp,-48
    80002bb2:	f406                	sd	ra,40(sp)
    80002bb4:	f022                	sd	s0,32(sp)
    80002bb6:	ec26                	sd	s1,24(sp)
    80002bb8:	e84a                	sd	s2,16(sp)
    80002bba:	1800                	addi	s0,sp,48
    80002bbc:	84ae                	mv	s1,a1
    80002bbe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc0:	fd840593          	addi	a1,s0,-40
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	fcc080e7          	jalr	-52(ra) # 80002b90 <argaddr>
  return fetchstr(addr, buf, max);
    80002bcc:	864a                	mv	a2,s2
    80002bce:	85a6                	mv	a1,s1
    80002bd0:	fd843503          	ld	a0,-40(s0)
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	f50080e7          	jalr	-176(ra) # 80002b24 <fetchstr>
}
    80002bdc:	70a2                	ld	ra,40(sp)
    80002bde:	7402                	ld	s0,32(sp)
    80002be0:	64e2                	ld	s1,24(sp)
    80002be2:	6942                	ld	s2,16(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret

0000000080002be8 <syscall>:
[SYS_prcinf]  sys_prcinf, // Added syscall for printing process info
};

void
syscall(void)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	e426                	sd	s1,8(sp)
    80002bf0:	e04a                	sd	s2,0(sp)
    80002bf2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	db2080e7          	jalr	-590(ra) # 800019a6 <myproc>
    80002bfc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfe:	05853903          	ld	s2,88(a0)
    80002c02:	0a893783          	ld	a5,168(s2)
    80002c06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c0a:	37fd                	addiw	a5,a5,-1
    80002c0c:	4759                	li	a4,22
    80002c0e:	00f76f63          	bltu	a4,a5,80002c2c <syscall+0x44>
    80002c12:	00369713          	slli	a4,a3,0x3
    80002c16:	00006797          	auipc	a5,0x6
    80002c1a:	8a278793          	addi	a5,a5,-1886 # 800084b8 <syscalls>
    80002c1e:	97ba                	add	a5,a5,a4
    80002c20:	639c                	ld	a5,0(a5)
    80002c22:	c789                	beqz	a5,80002c2c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c24:	9782                	jalr	a5
    80002c26:	06a93823          	sd	a0,112(s2)
    80002c2a:	a839                	j	80002c48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c2c:	15848613          	addi	a2,s1,344
    80002c30:	588c                	lw	a1,48(s1)
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	84e50513          	addi	a0,a0,-1970 # 80008480 <states.0+0x150>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	94c080e7          	jalr	-1716(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c42:	6cbc                	ld	a5,88(s1)
    80002c44:	577d                	li	a4,-1
    80002c46:	fbb8                	sd	a4,112(a5)
  }
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6902                	ld	s2,0(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c5c:	fec40593          	addi	a1,s0,-20
    80002c60:	4501                	li	a0,0
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	f0e080e7          	jalr	-242(ra) # 80002b70 <argint>
  exit(n);
    80002c6a:	fec42503          	lw	a0,-20(s0)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	514080e7          	jalr	1300(ra) # 80002182 <exit>
  return 0;  // not reached
}
    80002c76:	4501                	li	a0,0
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c80:	1141                	addi	sp,sp,-16
    80002c82:	e406                	sd	ra,8(sp)
    80002c84:	e022                	sd	s0,0(sp)
    80002c86:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	d1e080e7          	jalr	-738(ra) # 800019a6 <myproc>
}
    80002c90:	5908                	lw	a0,48(a0)
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <sys_fork>:

uint64
sys_fork(void)
{
    80002c9a:	1141                	addi	sp,sp,-16
    80002c9c:	e406                	sd	ra,8(sp)
    80002c9e:	e022                	sd	s0,0(sp)
    80002ca0:	0800                	addi	s0,sp,16
  return fork();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	0ba080e7          	jalr	186(ra) # 80001d5c <fork>
}
    80002caa:	60a2                	ld	ra,8(sp)
    80002cac:	6402                	ld	s0,0(sp)
    80002cae:	0141                	addi	sp,sp,16
    80002cb0:	8082                	ret

0000000080002cb2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cba:	fe840593          	addi	a1,s0,-24
    80002cbe:	4501                	li	a0,0
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	ed0080e7          	jalr	-304(ra) # 80002b90 <argaddr>
  return wait(p);
    80002cc8:	fe843503          	ld	a0,-24(s0)
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	65c080e7          	jalr	1628(ra) # 80002328 <wait>
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cdc:	7179                	addi	sp,sp,-48
    80002cde:	f406                	sd	ra,40(sp)
    80002ce0:	f022                	sd	s0,32(sp)
    80002ce2:	ec26                	sd	s1,24(sp)
    80002ce4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ce6:	fdc40593          	addi	a1,s0,-36
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e84080e7          	jalr	-380(ra) # 80002b70 <argint>
  addr = myproc()->sz;
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	cb2080e7          	jalr	-846(ra) # 800019a6 <myproc>
    80002cfc:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cfe:	fdc42503          	lw	a0,-36(s0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	ffe080e7          	jalr	-2(ra) # 80001d00 <growproc>
    80002d0a:	00054863          	bltz	a0,80002d1a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d0e:	8526                	mv	a0,s1
    80002d10:	70a2                	ld	ra,40(sp)
    80002d12:	7402                	ld	s0,32(sp)
    80002d14:	64e2                	ld	s1,24(sp)
    80002d16:	6145                	addi	sp,sp,48
    80002d18:	8082                	ret
    return -1;
    80002d1a:	54fd                	li	s1,-1
    80002d1c:	bfcd                	j	80002d0e <sys_sbrk+0x32>

0000000080002d1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d1e:	7139                	addi	sp,sp,-64
    80002d20:	fc06                	sd	ra,56(sp)
    80002d22:	f822                	sd	s0,48(sp)
    80002d24:	f426                	sd	s1,40(sp)
    80002d26:	f04a                	sd	s2,32(sp)
    80002d28:	ec4e                	sd	s3,24(sp)
    80002d2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d2c:	fcc40593          	addi	a1,s0,-52
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	e3e080e7          	jalr	-450(ra) # 80002b70 <argint>
  acquire(&tickslock);
    80002d3a:	00014517          	auipc	a0,0x14
    80002d3e:	cb650513          	addi	a0,a0,-842 # 800169f0 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	e90080e7          	jalr	-368(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002d4a:	00006917          	auipc	s2,0x6
    80002d4e:	c0692903          	lw	s2,-1018(s2) # 80008950 <ticks>
  while(ticks - ticks0 < n){
    80002d52:	fcc42783          	lw	a5,-52(s0)
    80002d56:	cf9d                	beqz	a5,80002d94 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d58:	00014997          	auipc	s3,0x14
    80002d5c:	c9898993          	addi	s3,s3,-872 # 800169f0 <tickslock>
    80002d60:	00006497          	auipc	s1,0x6
    80002d64:	bf048493          	addi	s1,s1,-1040 # 80008950 <ticks>
    if(killed(myproc())){
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	c3e080e7          	jalr	-962(ra) # 800019a6 <myproc>
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	586080e7          	jalr	1414(ra) # 800022f6 <killed>
    80002d78:	ed15                	bnez	a0,80002db4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d7a:	85ce                	mv	a1,s3
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	2d0080e7          	jalr	720(ra) # 8000204e <sleep>
  while(ticks - ticks0 < n){
    80002d86:	409c                	lw	a5,0(s1)
    80002d88:	412787bb          	subw	a5,a5,s2
    80002d8c:	fcc42703          	lw	a4,-52(s0)
    80002d90:	fce7ece3          	bltu	a5,a4,80002d68 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d94:	00014517          	auipc	a0,0x14
    80002d98:	c5c50513          	addi	a0,a0,-932 # 800169f0 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	eea080e7          	jalr	-278(ra) # 80000c86 <release>
  return 0;
    80002da4:	4501                	li	a0,0
}
    80002da6:	70e2                	ld	ra,56(sp)
    80002da8:	7442                	ld	s0,48(sp)
    80002daa:	74a2                	ld	s1,40(sp)
    80002dac:	7902                	ld	s2,32(sp)
    80002dae:	69e2                	ld	s3,24(sp)
    80002db0:	6121                	addi	sp,sp,64
    80002db2:	8082                	ret
      release(&tickslock);
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	c3c50513          	addi	a0,a0,-964 # 800169f0 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	eca080e7          	jalr	-310(ra) # 80000c86 <release>
      return -1;
    80002dc4:	557d                	li	a0,-1
    80002dc6:	b7c5                	j	80002da6 <sys_sleep+0x88>

0000000080002dc8 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dd0:	fec40593          	addi	a1,s0,-20
    80002dd4:	4501                	li	a0,0
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	d9a080e7          	jalr	-614(ra) # 80002b70 <argint>
  return kill(pid);
    80002dde:	fec42503          	lw	a0,-20(s0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	476080e7          	jalr	1142(ra) # 80002258 <kill>
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dfc:	00014517          	auipc	a0,0x14
    80002e00:	bf450513          	addi	a0,a0,-1036 # 800169f0 <tickslock>
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	dce080e7          	jalr	-562(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002e0c:	00006497          	auipc	s1,0x6
    80002e10:	b444a483          	lw	s1,-1212(s1) # 80008950 <ticks>
  release(&tickslock);
    80002e14:	00014517          	auipc	a0,0x14
    80002e18:	bdc50513          	addi	a0,a0,-1060 # 800169f0 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	e6a080e7          	jalr	-406(ra) # 80000c86 <release>
  return xticks;
}
    80002e24:	02049513          	slli	a0,s1,0x20
    80002e28:	9101                	srli	a0,a0,0x20
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <sys_hello>:

//Added function for printing with sys_hello function

uint64
sys_hello(void)
{
    80002e34:	1141                	addi	sp,sp,-16
    80002e36:	e406                	sd	ra,8(sp)
    80002e38:	e022                	sd	s0,0(sp)
    80002e3a:	0800                	addi	s0,sp,16
  printf("Hello world! \n");
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	73c50513          	addi	a0,a0,1852 # 80008578 <syscalls+0xc0>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	742080e7          	jalr	1858(ra) # 80000586 <printf>
  return 0;
}
    80002e4c:	4501                	li	a0,0
    80002e4e:	60a2                	ld	ra,8(sp)
    80002e50:	6402                	ld	s0,0(sp)
    80002e52:	0141                	addi	sp,sp,16
    80002e54:	8082                	ret

0000000080002e56 <sys_prcinf>:

uint64
sys_prcinf(void)
{
    80002e56:	1141                	addi	sp,sp,-16
    80002e58:	e406                	sd	ra,8(sp)
    80002e5a:	e022                	sd	s0,0(sp)
    80002e5c:	0800                	addi	s0,sp,16
  procreturn();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	754080e7          	jalr	1876(ra) # 800025b2 <procreturn>
  return 0;
    80002e66:	4501                	li	a0,0
    80002e68:	60a2                	ld	ra,8(sp)
    80002e6a:	6402                	ld	s0,0(sp)
    80002e6c:	0141                	addi	sp,sp,16
    80002e6e:	8082                	ret

0000000080002e70 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e70:	7179                	addi	sp,sp,-48
    80002e72:	f406                	sd	ra,40(sp)
    80002e74:	f022                	sd	s0,32(sp)
    80002e76:	ec26                	sd	s1,24(sp)
    80002e78:	e84a                	sd	s2,16(sp)
    80002e7a:	e44e                	sd	s3,8(sp)
    80002e7c:	e052                	sd	s4,0(sp)
    80002e7e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e80:	00005597          	auipc	a1,0x5
    80002e84:	70858593          	addi	a1,a1,1800 # 80008588 <syscalls+0xd0>
    80002e88:	00014517          	auipc	a0,0x14
    80002e8c:	b8050513          	addi	a0,a0,-1152 # 80016a08 <bcache>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	cb2080e7          	jalr	-846(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e98:	0001c797          	auipc	a5,0x1c
    80002e9c:	b7078793          	addi	a5,a5,-1168 # 8001ea08 <bcache+0x8000>
    80002ea0:	0001c717          	auipc	a4,0x1c
    80002ea4:	dd070713          	addi	a4,a4,-560 # 8001ec70 <bcache+0x8268>
    80002ea8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eac:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb0:	00014497          	auipc	s1,0x14
    80002eb4:	b7048493          	addi	s1,s1,-1168 # 80016a20 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eba:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ebc:	00005a17          	auipc	s4,0x5
    80002ec0:	6d4a0a13          	addi	s4,s4,1748 # 80008590 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002ec4:	2b893783          	ld	a5,696(s2)
    80002ec8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eca:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ece:	85d2                	mv	a1,s4
    80002ed0:	01048513          	addi	a0,s1,16
    80002ed4:	00001097          	auipc	ra,0x1
    80002ed8:	496080e7          	jalr	1174(ra) # 8000436a <initsleeplock>
    bcache.head.next->prev = b;
    80002edc:	2b893783          	ld	a5,696(s2)
    80002ee0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ee2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee6:	45848493          	addi	s1,s1,1112
    80002eea:	fd349de3          	bne	s1,s3,80002ec4 <binit+0x54>
  }
}
    80002eee:	70a2                	ld	ra,40(sp)
    80002ef0:	7402                	ld	s0,32(sp)
    80002ef2:	64e2                	ld	s1,24(sp)
    80002ef4:	6942                	ld	s2,16(sp)
    80002ef6:	69a2                	ld	s3,8(sp)
    80002ef8:	6a02                	ld	s4,0(sp)
    80002efa:	6145                	addi	sp,sp,48
    80002efc:	8082                	ret

0000000080002efe <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002efe:	7179                	addi	sp,sp,-48
    80002f00:	f406                	sd	ra,40(sp)
    80002f02:	f022                	sd	s0,32(sp)
    80002f04:	ec26                	sd	s1,24(sp)
    80002f06:	e84a                	sd	s2,16(sp)
    80002f08:	e44e                	sd	s3,8(sp)
    80002f0a:	1800                	addi	s0,sp,48
    80002f0c:	892a                	mv	s2,a0
    80002f0e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f10:	00014517          	auipc	a0,0x14
    80002f14:	af850513          	addi	a0,a0,-1288 # 80016a08 <bcache>
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	cba080e7          	jalr	-838(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f20:	0001c497          	auipc	s1,0x1c
    80002f24:	da04b483          	ld	s1,-608(s1) # 8001ecc0 <bcache+0x82b8>
    80002f28:	0001c797          	auipc	a5,0x1c
    80002f2c:	d4878793          	addi	a5,a5,-696 # 8001ec70 <bcache+0x8268>
    80002f30:	02f48f63          	beq	s1,a5,80002f6e <bread+0x70>
    80002f34:	873e                	mv	a4,a5
    80002f36:	a021                	j	80002f3e <bread+0x40>
    80002f38:	68a4                	ld	s1,80(s1)
    80002f3a:	02e48a63          	beq	s1,a4,80002f6e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f3e:	449c                	lw	a5,8(s1)
    80002f40:	ff279ce3          	bne	a5,s2,80002f38 <bread+0x3a>
    80002f44:	44dc                	lw	a5,12(s1)
    80002f46:	ff3799e3          	bne	a5,s3,80002f38 <bread+0x3a>
      b->refcnt++;
    80002f4a:	40bc                	lw	a5,64(s1)
    80002f4c:	2785                	addiw	a5,a5,1
    80002f4e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	ab850513          	addi	a0,a0,-1352 # 80016a08 <bcache>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	d2e080e7          	jalr	-722(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002f60:	01048513          	addi	a0,s1,16
    80002f64:	00001097          	auipc	ra,0x1
    80002f68:	440080e7          	jalr	1088(ra) # 800043a4 <acquiresleep>
      return b;
    80002f6c:	a8b9                	j	80002fca <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6e:	0001c497          	auipc	s1,0x1c
    80002f72:	d4a4b483          	ld	s1,-694(s1) # 8001ecb8 <bcache+0x82b0>
    80002f76:	0001c797          	auipc	a5,0x1c
    80002f7a:	cfa78793          	addi	a5,a5,-774 # 8001ec70 <bcache+0x8268>
    80002f7e:	00f48863          	beq	s1,a5,80002f8e <bread+0x90>
    80002f82:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	cf81                	beqz	a5,80002f9e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f88:	64a4                	ld	s1,72(s1)
    80002f8a:	fee49de3          	bne	s1,a4,80002f84 <bread+0x86>
  panic("bget: no buffers");
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	60a50513          	addi	a0,a0,1546 # 80008598 <syscalls+0xe0>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5a6080e7          	jalr	1446(ra) # 8000053c <panic>
      b->dev = dev;
    80002f9e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fa2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fa6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002faa:	4785                	li	a5,1
    80002fac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	a5a50513          	addi	a0,a0,-1446 # 80016a08 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	cd0080e7          	jalr	-816(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002fbe:	01048513          	addi	a0,s1,16
    80002fc2:	00001097          	auipc	ra,0x1
    80002fc6:	3e2080e7          	jalr	994(ra) # 800043a4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fca:	409c                	lw	a5,0(s1)
    80002fcc:	cb89                	beqz	a5,80002fde <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fce:	8526                	mv	a0,s1
    80002fd0:	70a2                	ld	ra,40(sp)
    80002fd2:	7402                	ld	s0,32(sp)
    80002fd4:	64e2                	ld	s1,24(sp)
    80002fd6:	6942                	ld	s2,16(sp)
    80002fd8:	69a2                	ld	s3,8(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fde:	4581                	li	a1,0
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	00003097          	auipc	ra,0x3
    80002fe6:	f80080e7          	jalr	-128(ra) # 80005f62 <virtio_disk_rw>
    b->valid = 1;
    80002fea:	4785                	li	a5,1
    80002fec:	c09c                	sw	a5,0(s1)
  return b;
    80002fee:	b7c5                	j	80002fce <bread+0xd0>

0000000080002ff0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	1000                	addi	s0,sp,32
    80002ffa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ffc:	0541                	addi	a0,a0,16
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	440080e7          	jalr	1088(ra) # 8000443e <holdingsleep>
    80003006:	cd01                	beqz	a0,8000301e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003008:	4585                	li	a1,1
    8000300a:	8526                	mv	a0,s1
    8000300c:	00003097          	auipc	ra,0x3
    80003010:	f56080e7          	jalr	-170(ra) # 80005f62 <virtio_disk_rw>
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret
    panic("bwrite");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	59250513          	addi	a0,a0,1426 # 800085b0 <syscalls+0xf8>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	516080e7          	jalr	1302(ra) # 8000053c <panic>

000000008000302e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	e04a                	sd	s2,0(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303c:	01050913          	addi	s2,a0,16
    80003040:	854a                	mv	a0,s2
    80003042:	00001097          	auipc	ra,0x1
    80003046:	3fc080e7          	jalr	1020(ra) # 8000443e <holdingsleep>
    8000304a:	c925                	beqz	a0,800030ba <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000304c:	854a                	mv	a0,s2
    8000304e:	00001097          	auipc	ra,0x1
    80003052:	3ac080e7          	jalr	940(ra) # 800043fa <releasesleep>

  acquire(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	9b250513          	addi	a0,a0,-1614 # 80016a08 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	b74080e7          	jalr	-1164(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003066:	40bc                	lw	a5,64(s1)
    80003068:	37fd                	addiw	a5,a5,-1
    8000306a:	0007871b          	sext.w	a4,a5
    8000306e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003070:	e71d                	bnez	a4,8000309e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003072:	68b8                	ld	a4,80(s1)
    80003074:	64bc                	ld	a5,72(s1)
    80003076:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003078:	68b8                	ld	a4,80(s1)
    8000307a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000307c:	0001c797          	auipc	a5,0x1c
    80003080:	98c78793          	addi	a5,a5,-1652 # 8001ea08 <bcache+0x8000>
    80003084:	2b87b703          	ld	a4,696(a5)
    80003088:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000308a:	0001c717          	auipc	a4,0x1c
    8000308e:	be670713          	addi	a4,a4,-1050 # 8001ec70 <bcache+0x8268>
    80003092:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003094:	2b87b703          	ld	a4,696(a5)
    80003098:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000309a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000309e:	00014517          	auipc	a0,0x14
    800030a2:	96a50513          	addi	a0,a0,-1686 # 80016a08 <bcache>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	be0080e7          	jalr	-1056(ra) # 80000c86 <release>
}
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6902                	ld	s2,0(sp)
    800030b6:	6105                	addi	sp,sp,32
    800030b8:	8082                	ret
    panic("brelse");
    800030ba:	00005517          	auipc	a0,0x5
    800030be:	4fe50513          	addi	a0,a0,1278 # 800085b8 <syscalls+0x100>
    800030c2:	ffffd097          	auipc	ra,0xffffd
    800030c6:	47a080e7          	jalr	1146(ra) # 8000053c <panic>

00000000800030ca <bpin>:

void
bpin(struct buf *b) {
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	93250513          	addi	a0,a0,-1742 # 80016a08 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	af4080e7          	jalr	-1292(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800030e6:	40bc                	lw	a5,64(s1)
    800030e8:	2785                	addiw	a5,a5,1
    800030ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	91c50513          	addi	a0,a0,-1764 # 80016a08 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	b92080e7          	jalr	-1134(ra) # 80000c86 <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <bunpin>:

void
bunpin(struct buf *b) {
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	8f650513          	addi	a0,a0,-1802 # 80016a08 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	ab8080e7          	jalr	-1352(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	37fd                	addiw	a5,a5,-1
    80003126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003128:	00014517          	auipc	a0,0x14
    8000312c:	8e050513          	addi	a0,a0,-1824 # 80016a08 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b56080e7          	jalr	-1194(ra) # 80000c86 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	e04a                	sd	s2,0(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003150:	00d5d59b          	srliw	a1,a1,0xd
    80003154:	0001c797          	auipc	a5,0x1c
    80003158:	f907a783          	lw	a5,-112(a5) # 8001f0e4 <sb+0x1c>
    8000315c:	9dbd                	addw	a1,a1,a5
    8000315e:	00000097          	auipc	ra,0x0
    80003162:	da0080e7          	jalr	-608(ra) # 80002efe <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003166:	0074f713          	andi	a4,s1,7
    8000316a:	4785                	li	a5,1
    8000316c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003170:	14ce                	slli	s1,s1,0x33
    80003172:	90d9                	srli	s1,s1,0x36
    80003174:	00950733          	add	a4,a0,s1
    80003178:	05874703          	lbu	a4,88(a4)
    8000317c:	00e7f6b3          	and	a3,a5,a4
    80003180:	c69d                	beqz	a3,800031ae <bfree+0x6c>
    80003182:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003184:	94aa                	add	s1,s1,a0
    80003186:	fff7c793          	not	a5,a5
    8000318a:	8f7d                	and	a4,a4,a5
    8000318c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003190:	00001097          	auipc	ra,0x1
    80003194:	0f6080e7          	jalr	246(ra) # 80004286 <log_write>
  brelse(bp);
    80003198:	854a                	mv	a0,s2
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	e94080e7          	jalr	-364(ra) # 8000302e <brelse>
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6902                	ld	s2,0(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret
    panic("freeing free block");
    800031ae:	00005517          	auipc	a0,0x5
    800031b2:	41250513          	addi	a0,a0,1042 # 800085c0 <syscalls+0x108>
    800031b6:	ffffd097          	auipc	ra,0xffffd
    800031ba:	386080e7          	jalr	902(ra) # 8000053c <panic>

00000000800031be <balloc>:
{
    800031be:	711d                	addi	sp,sp,-96
    800031c0:	ec86                	sd	ra,88(sp)
    800031c2:	e8a2                	sd	s0,80(sp)
    800031c4:	e4a6                	sd	s1,72(sp)
    800031c6:	e0ca                	sd	s2,64(sp)
    800031c8:	fc4e                	sd	s3,56(sp)
    800031ca:	f852                	sd	s4,48(sp)
    800031cc:	f456                	sd	s5,40(sp)
    800031ce:	f05a                	sd	s6,32(sp)
    800031d0:	ec5e                	sd	s7,24(sp)
    800031d2:	e862                	sd	s8,16(sp)
    800031d4:	e466                	sd	s9,8(sp)
    800031d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031d8:	0001c797          	auipc	a5,0x1c
    800031dc:	ef47a783          	lw	a5,-268(a5) # 8001f0cc <sb+0x4>
    800031e0:	cff5                	beqz	a5,800032dc <balloc+0x11e>
    800031e2:	8baa                	mv	s7,a0
    800031e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e6:	0001cb17          	auipc	s6,0x1c
    800031ea:	ee2b0b13          	addi	s6,s6,-286 # 8001f0c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f4:	6c89                	lui	s9,0x2
    800031f6:	a061                	j	8000327e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031f8:	97ca                	add	a5,a5,s2
    800031fa:	8e55                	or	a2,a2,a3
    800031fc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003200:	854a                	mv	a0,s2
    80003202:	00001097          	auipc	ra,0x1
    80003206:	084080e7          	jalr	132(ra) # 80004286 <log_write>
        brelse(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	e22080e7          	jalr	-478(ra) # 8000302e <brelse>
  bp = bread(dev, bno);
    80003214:	85a6                	mv	a1,s1
    80003216:	855e                	mv	a0,s7
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	ce6080e7          	jalr	-794(ra) # 80002efe <bread>
    80003220:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003222:	40000613          	li	a2,1024
    80003226:	4581                	li	a1,0
    80003228:	05850513          	addi	a0,a0,88
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	aa2080e7          	jalr	-1374(ra) # 80000cce <memset>
  log_write(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	050080e7          	jalr	80(ra) # 80004286 <log_write>
  brelse(bp);
    8000323e:	854a                	mv	a0,s2
    80003240:	00000097          	auipc	ra,0x0
    80003244:	dee080e7          	jalr	-530(ra) # 8000302e <brelse>
}
    80003248:	8526                	mv	a0,s1
    8000324a:	60e6                	ld	ra,88(sp)
    8000324c:	6446                	ld	s0,80(sp)
    8000324e:	64a6                	ld	s1,72(sp)
    80003250:	6906                	ld	s2,64(sp)
    80003252:	79e2                	ld	s3,56(sp)
    80003254:	7a42                	ld	s4,48(sp)
    80003256:	7aa2                	ld	s5,40(sp)
    80003258:	7b02                	ld	s6,32(sp)
    8000325a:	6be2                	ld	s7,24(sp)
    8000325c:	6c42                	ld	s8,16(sp)
    8000325e:	6ca2                	ld	s9,8(sp)
    80003260:	6125                	addi	sp,sp,96
    80003262:	8082                	ret
    brelse(bp);
    80003264:	854a                	mv	a0,s2
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	dc8080e7          	jalr	-568(ra) # 8000302e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000326e:	015c87bb          	addw	a5,s9,s5
    80003272:	00078a9b          	sext.w	s5,a5
    80003276:	004b2703          	lw	a4,4(s6)
    8000327a:	06eaf163          	bgeu	s5,a4,800032dc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000327e:	41fad79b          	sraiw	a5,s5,0x1f
    80003282:	0137d79b          	srliw	a5,a5,0x13
    80003286:	015787bb          	addw	a5,a5,s5
    8000328a:	40d7d79b          	sraiw	a5,a5,0xd
    8000328e:	01cb2583          	lw	a1,28(s6)
    80003292:	9dbd                	addw	a1,a1,a5
    80003294:	855e                	mv	a0,s7
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	c68080e7          	jalr	-920(ra) # 80002efe <bread>
    8000329e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a0:	004b2503          	lw	a0,4(s6)
    800032a4:	000a849b          	sext.w	s1,s5
    800032a8:	8762                	mv	a4,s8
    800032aa:	faa4fde3          	bgeu	s1,a0,80003264 <balloc+0xa6>
      m = 1 << (bi % 8);
    800032ae:	00777693          	andi	a3,a4,7
    800032b2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032b6:	41f7579b          	sraiw	a5,a4,0x1f
    800032ba:	01d7d79b          	srliw	a5,a5,0x1d
    800032be:	9fb9                	addw	a5,a5,a4
    800032c0:	4037d79b          	sraiw	a5,a5,0x3
    800032c4:	00f90633          	add	a2,s2,a5
    800032c8:	05864603          	lbu	a2,88(a2)
    800032cc:	00c6f5b3          	and	a1,a3,a2
    800032d0:	d585                	beqz	a1,800031f8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d2:	2705                	addiw	a4,a4,1
    800032d4:	2485                	addiw	s1,s1,1
    800032d6:	fd471ae3          	bne	a4,s4,800032aa <balloc+0xec>
    800032da:	b769                	j	80003264 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	2fc50513          	addi	a0,a0,764 # 800085d8 <syscalls+0x120>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	2a2080e7          	jalr	674(ra) # 80000586 <printf>
  return 0;
    800032ec:	4481                	li	s1,0
    800032ee:	bfa9                	j	80003248 <balloc+0x8a>

00000000800032f0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800032f0:	7179                	addi	sp,sp,-48
    800032f2:	f406                	sd	ra,40(sp)
    800032f4:	f022                	sd	s0,32(sp)
    800032f6:	ec26                	sd	s1,24(sp)
    800032f8:	e84a                	sd	s2,16(sp)
    800032fa:	e44e                	sd	s3,8(sp)
    800032fc:	e052                	sd	s4,0(sp)
    800032fe:	1800                	addi	s0,sp,48
    80003300:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003302:	47ad                	li	a5,11
    80003304:	02b7e863          	bltu	a5,a1,80003334 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003308:	02059793          	slli	a5,a1,0x20
    8000330c:	01e7d593          	srli	a1,a5,0x1e
    80003310:	00b504b3          	add	s1,a0,a1
    80003314:	0504a903          	lw	s2,80(s1)
    80003318:	06091e63          	bnez	s2,80003394 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000331c:	4108                	lw	a0,0(a0)
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	ea0080e7          	jalr	-352(ra) # 800031be <balloc>
    80003326:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000332a:	06090563          	beqz	s2,80003394 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000332e:	0524a823          	sw	s2,80(s1)
    80003332:	a08d                	j	80003394 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003334:	ff45849b          	addiw	s1,a1,-12
    80003338:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000333c:	0ff00793          	li	a5,255
    80003340:	08e7e563          	bltu	a5,a4,800033ca <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003344:	08052903          	lw	s2,128(a0)
    80003348:	00091d63          	bnez	s2,80003362 <bmap+0x72>
      addr = balloc(ip->dev);
    8000334c:	4108                	lw	a0,0(a0)
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e70080e7          	jalr	-400(ra) # 800031be <balloc>
    80003356:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000335a:	02090d63          	beqz	s2,80003394 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000335e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003362:	85ca                	mv	a1,s2
    80003364:	0009a503          	lw	a0,0(s3)
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	b96080e7          	jalr	-1130(ra) # 80002efe <bread>
    80003370:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003372:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003376:	02049713          	slli	a4,s1,0x20
    8000337a:	01e75593          	srli	a1,a4,0x1e
    8000337e:	00b784b3          	add	s1,a5,a1
    80003382:	0004a903          	lw	s2,0(s1)
    80003386:	02090063          	beqz	s2,800033a6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000338a:	8552                	mv	a0,s4
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	ca2080e7          	jalr	-862(ra) # 8000302e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003394:	854a                	mv	a0,s2
    80003396:	70a2                	ld	ra,40(sp)
    80003398:	7402                	ld	s0,32(sp)
    8000339a:	64e2                	ld	s1,24(sp)
    8000339c:	6942                	ld	s2,16(sp)
    8000339e:	69a2                	ld	s3,8(sp)
    800033a0:	6a02                	ld	s4,0(sp)
    800033a2:	6145                	addi	sp,sp,48
    800033a4:	8082                	ret
      addr = balloc(ip->dev);
    800033a6:	0009a503          	lw	a0,0(s3)
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e14080e7          	jalr	-492(ra) # 800031be <balloc>
    800033b2:	0005091b          	sext.w	s2,a0
      if(addr){
    800033b6:	fc090ae3          	beqz	s2,8000338a <bmap+0x9a>
        a[bn] = addr;
    800033ba:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033be:	8552                	mv	a0,s4
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	ec6080e7          	jalr	-314(ra) # 80004286 <log_write>
    800033c8:	b7c9                	j	8000338a <bmap+0x9a>
  panic("bmap: out of range");
    800033ca:	00005517          	auipc	a0,0x5
    800033ce:	22650513          	addi	a0,a0,550 # 800085f0 <syscalls+0x138>
    800033d2:	ffffd097          	auipc	ra,0xffffd
    800033d6:	16a080e7          	jalr	362(ra) # 8000053c <panic>

00000000800033da <iget>:
{
    800033da:	7179                	addi	sp,sp,-48
    800033dc:	f406                	sd	ra,40(sp)
    800033de:	f022                	sd	s0,32(sp)
    800033e0:	ec26                	sd	s1,24(sp)
    800033e2:	e84a                	sd	s2,16(sp)
    800033e4:	e44e                	sd	s3,8(sp)
    800033e6:	e052                	sd	s4,0(sp)
    800033e8:	1800                	addi	s0,sp,48
    800033ea:	89aa                	mv	s3,a0
    800033ec:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033ee:	0001c517          	auipc	a0,0x1c
    800033f2:	cfa50513          	addi	a0,a0,-774 # 8001f0e8 <itable>
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	7dc080e7          	jalr	2012(ra) # 80000bd2 <acquire>
  empty = 0;
    800033fe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003400:	0001c497          	auipc	s1,0x1c
    80003404:	d0048493          	addi	s1,s1,-768 # 8001f100 <itable+0x18>
    80003408:	0001d697          	auipc	a3,0x1d
    8000340c:	78868693          	addi	a3,a3,1928 # 80020b90 <log>
    80003410:	a039                	j	8000341e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003412:	02090b63          	beqz	s2,80003448 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003416:	08848493          	addi	s1,s1,136
    8000341a:	02d48a63          	beq	s1,a3,8000344e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000341e:	449c                	lw	a5,8(s1)
    80003420:	fef059e3          	blez	a5,80003412 <iget+0x38>
    80003424:	4098                	lw	a4,0(s1)
    80003426:	ff3716e3          	bne	a4,s3,80003412 <iget+0x38>
    8000342a:	40d8                	lw	a4,4(s1)
    8000342c:	ff4713e3          	bne	a4,s4,80003412 <iget+0x38>
      ip->ref++;
    80003430:	2785                	addiw	a5,a5,1
    80003432:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003434:	0001c517          	auipc	a0,0x1c
    80003438:	cb450513          	addi	a0,a0,-844 # 8001f0e8 <itable>
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	84a080e7          	jalr	-1974(ra) # 80000c86 <release>
      return ip;
    80003444:	8926                	mv	s2,s1
    80003446:	a03d                	j	80003474 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003448:	f7f9                	bnez	a5,80003416 <iget+0x3c>
    8000344a:	8926                	mv	s2,s1
    8000344c:	b7e9                	j	80003416 <iget+0x3c>
  if(empty == 0)
    8000344e:	02090c63          	beqz	s2,80003486 <iget+0xac>
  ip->dev = dev;
    80003452:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003456:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000345a:	4785                	li	a5,1
    8000345c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003460:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003464:	0001c517          	auipc	a0,0x1c
    80003468:	c8450513          	addi	a0,a0,-892 # 8001f0e8 <itable>
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	81a080e7          	jalr	-2022(ra) # 80000c86 <release>
}
    80003474:	854a                	mv	a0,s2
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6942                	ld	s2,16(sp)
    8000347e:	69a2                	ld	s3,8(sp)
    80003480:	6a02                	ld	s4,0(sp)
    80003482:	6145                	addi	sp,sp,48
    80003484:	8082                	ret
    panic("iget: no inodes");
    80003486:	00005517          	auipc	a0,0x5
    8000348a:	18250513          	addi	a0,a0,386 # 80008608 <syscalls+0x150>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	0ae080e7          	jalr	174(ra) # 8000053c <panic>

0000000080003496 <fsinit>:
fsinit(int dev) {
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	1800                	addi	s0,sp,48
    800034a4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034a6:	4585                	li	a1,1
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	a56080e7          	jalr	-1450(ra) # 80002efe <bread>
    800034b0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034b2:	0001c997          	auipc	s3,0x1c
    800034b6:	c1698993          	addi	s3,s3,-1002 # 8001f0c8 <sb>
    800034ba:	02000613          	li	a2,32
    800034be:	05850593          	addi	a1,a0,88
    800034c2:	854e                	mv	a0,s3
    800034c4:	ffffe097          	auipc	ra,0xffffe
    800034c8:	866080e7          	jalr	-1946(ra) # 80000d2a <memmove>
  brelse(bp);
    800034cc:	8526                	mv	a0,s1
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	b60080e7          	jalr	-1184(ra) # 8000302e <brelse>
  if(sb.magic != FSMAGIC)
    800034d6:	0009a703          	lw	a4,0(s3)
    800034da:	102037b7          	lui	a5,0x10203
    800034de:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034e2:	02f71263          	bne	a4,a5,80003506 <fsinit+0x70>
  initlog(dev, &sb);
    800034e6:	0001c597          	auipc	a1,0x1c
    800034ea:	be258593          	addi	a1,a1,-1054 # 8001f0c8 <sb>
    800034ee:	854a                	mv	a0,s2
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	b2c080e7          	jalr	-1236(ra) # 8000401c <initlog>
}
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6145                	addi	sp,sp,48
    80003504:	8082                	ret
    panic("invalid file system");
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	11250513          	addi	a0,a0,274 # 80008618 <syscalls+0x160>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	02e080e7          	jalr	46(ra) # 8000053c <panic>

0000000080003516 <iinit>:
{
    80003516:	7179                	addi	sp,sp,-48
    80003518:	f406                	sd	ra,40(sp)
    8000351a:	f022                	sd	s0,32(sp)
    8000351c:	ec26                	sd	s1,24(sp)
    8000351e:	e84a                	sd	s2,16(sp)
    80003520:	e44e                	sd	s3,8(sp)
    80003522:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003524:	00005597          	auipc	a1,0x5
    80003528:	10c58593          	addi	a1,a1,268 # 80008630 <syscalls+0x178>
    8000352c:	0001c517          	auipc	a0,0x1c
    80003530:	bbc50513          	addi	a0,a0,-1092 # 8001f0e8 <itable>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	60e080e7          	jalr	1550(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000353c:	0001c497          	auipc	s1,0x1c
    80003540:	bd448493          	addi	s1,s1,-1068 # 8001f110 <itable+0x28>
    80003544:	0001d997          	auipc	s3,0x1d
    80003548:	65c98993          	addi	s3,s3,1628 # 80020ba0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000354c:	00005917          	auipc	s2,0x5
    80003550:	0ec90913          	addi	s2,s2,236 # 80008638 <syscalls+0x180>
    80003554:	85ca                	mv	a1,s2
    80003556:	8526                	mv	a0,s1
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	e12080e7          	jalr	-494(ra) # 8000436a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003560:	08848493          	addi	s1,s1,136
    80003564:	ff3498e3          	bne	s1,s3,80003554 <iinit+0x3e>
}
    80003568:	70a2                	ld	ra,40(sp)
    8000356a:	7402                	ld	s0,32(sp)
    8000356c:	64e2                	ld	s1,24(sp)
    8000356e:	6942                	ld	s2,16(sp)
    80003570:	69a2                	ld	s3,8(sp)
    80003572:	6145                	addi	sp,sp,48
    80003574:	8082                	ret

0000000080003576 <ialloc>:
{
    80003576:	7139                	addi	sp,sp,-64
    80003578:	fc06                	sd	ra,56(sp)
    8000357a:	f822                	sd	s0,48(sp)
    8000357c:	f426                	sd	s1,40(sp)
    8000357e:	f04a                	sd	s2,32(sp)
    80003580:	ec4e                	sd	s3,24(sp)
    80003582:	e852                	sd	s4,16(sp)
    80003584:	e456                	sd	s5,8(sp)
    80003586:	e05a                	sd	s6,0(sp)
    80003588:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358a:	0001c717          	auipc	a4,0x1c
    8000358e:	b4a72703          	lw	a4,-1206(a4) # 8001f0d4 <sb+0xc>
    80003592:	4785                	li	a5,1
    80003594:	04e7f863          	bgeu	a5,a4,800035e4 <ialloc+0x6e>
    80003598:	8aaa                	mv	s5,a0
    8000359a:	8b2e                	mv	s6,a1
    8000359c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000359e:	0001ca17          	auipc	s4,0x1c
    800035a2:	b2aa0a13          	addi	s4,s4,-1238 # 8001f0c8 <sb>
    800035a6:	00495593          	srli	a1,s2,0x4
    800035aa:	018a2783          	lw	a5,24(s4)
    800035ae:	9dbd                	addw	a1,a1,a5
    800035b0:	8556                	mv	a0,s5
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	94c080e7          	jalr	-1716(ra) # 80002efe <bread>
    800035ba:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035bc:	05850993          	addi	s3,a0,88
    800035c0:	00f97793          	andi	a5,s2,15
    800035c4:	079a                	slli	a5,a5,0x6
    800035c6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035c8:	00099783          	lh	a5,0(s3)
    800035cc:	cf9d                	beqz	a5,8000360a <ialloc+0x94>
    brelse(bp);
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	a60080e7          	jalr	-1440(ra) # 8000302e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d6:	0905                	addi	s2,s2,1
    800035d8:	00ca2703          	lw	a4,12(s4)
    800035dc:	0009079b          	sext.w	a5,s2
    800035e0:	fce7e3e3          	bltu	a5,a4,800035a6 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800035e4:	00005517          	auipc	a0,0x5
    800035e8:	05c50513          	addi	a0,a0,92 # 80008640 <syscalls+0x188>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	f9a080e7          	jalr	-102(ra) # 80000586 <printf>
  return 0;
    800035f4:	4501                	li	a0,0
}
    800035f6:	70e2                	ld	ra,56(sp)
    800035f8:	7442                	ld	s0,48(sp)
    800035fa:	74a2                	ld	s1,40(sp)
    800035fc:	7902                	ld	s2,32(sp)
    800035fe:	69e2                	ld	s3,24(sp)
    80003600:	6a42                	ld	s4,16(sp)
    80003602:	6aa2                	ld	s5,8(sp)
    80003604:	6b02                	ld	s6,0(sp)
    80003606:	6121                	addi	sp,sp,64
    80003608:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000360a:	04000613          	li	a2,64
    8000360e:	4581                	li	a1,0
    80003610:	854e                	mv	a0,s3
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	6bc080e7          	jalr	1724(ra) # 80000cce <memset>
      dip->type = type;
    8000361a:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000361e:	8526                	mv	a0,s1
    80003620:	00001097          	auipc	ra,0x1
    80003624:	c66080e7          	jalr	-922(ra) # 80004286 <log_write>
      brelse(bp);
    80003628:	8526                	mv	a0,s1
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	a04080e7          	jalr	-1532(ra) # 8000302e <brelse>
      return iget(dev, inum);
    80003632:	0009059b          	sext.w	a1,s2
    80003636:	8556                	mv	a0,s5
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	da2080e7          	jalr	-606(ra) # 800033da <iget>
    80003640:	bf5d                	j	800035f6 <ialloc+0x80>

0000000080003642 <iupdate>:
{
    80003642:	1101                	addi	sp,sp,-32
    80003644:	ec06                	sd	ra,24(sp)
    80003646:	e822                	sd	s0,16(sp)
    80003648:	e426                	sd	s1,8(sp)
    8000364a:	e04a                	sd	s2,0(sp)
    8000364c:	1000                	addi	s0,sp,32
    8000364e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003650:	415c                	lw	a5,4(a0)
    80003652:	0047d79b          	srliw	a5,a5,0x4
    80003656:	0001c597          	auipc	a1,0x1c
    8000365a:	a8a5a583          	lw	a1,-1398(a1) # 8001f0e0 <sb+0x18>
    8000365e:	9dbd                	addw	a1,a1,a5
    80003660:	4108                	lw	a0,0(a0)
    80003662:	00000097          	auipc	ra,0x0
    80003666:	89c080e7          	jalr	-1892(ra) # 80002efe <bread>
    8000366a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366c:	05850793          	addi	a5,a0,88
    80003670:	40d8                	lw	a4,4(s1)
    80003672:	8b3d                	andi	a4,a4,15
    80003674:	071a                	slli	a4,a4,0x6
    80003676:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003678:	04449703          	lh	a4,68(s1)
    8000367c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003680:	04649703          	lh	a4,70(s1)
    80003684:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003688:	04849703          	lh	a4,72(s1)
    8000368c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003690:	04a49703          	lh	a4,74(s1)
    80003694:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003698:	44f8                	lw	a4,76(s1)
    8000369a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000369c:	03400613          	li	a2,52
    800036a0:	05048593          	addi	a1,s1,80
    800036a4:	00c78513          	addi	a0,a5,12
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	682080e7          	jalr	1666(ra) # 80000d2a <memmove>
  log_write(bp);
    800036b0:	854a                	mv	a0,s2
    800036b2:	00001097          	auipc	ra,0x1
    800036b6:	bd4080e7          	jalr	-1068(ra) # 80004286 <log_write>
  brelse(bp);
    800036ba:	854a                	mv	a0,s2
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	972080e7          	jalr	-1678(ra) # 8000302e <brelse>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6902                	ld	s2,0(sp)
    800036cc:	6105                	addi	sp,sp,32
    800036ce:	8082                	ret

00000000800036d0 <idup>:
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036dc:	0001c517          	auipc	a0,0x1c
    800036e0:	a0c50513          	addi	a0,a0,-1524 # 8001f0e8 <itable>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	4ee080e7          	jalr	1262(ra) # 80000bd2 <acquire>
  ip->ref++;
    800036ec:	449c                	lw	a5,8(s1)
    800036ee:	2785                	addiw	a5,a5,1
    800036f0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036f2:	0001c517          	auipc	a0,0x1c
    800036f6:	9f650513          	addi	a0,a0,-1546 # 8001f0e8 <itable>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	58c080e7          	jalr	1420(ra) # 80000c86 <release>
}
    80003702:	8526                	mv	a0,s1
    80003704:	60e2                	ld	ra,24(sp)
    80003706:	6442                	ld	s0,16(sp)
    80003708:	64a2                	ld	s1,8(sp)
    8000370a:	6105                	addi	sp,sp,32
    8000370c:	8082                	ret

000000008000370e <ilock>:
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	e04a                	sd	s2,0(sp)
    80003718:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000371a:	c115                	beqz	a0,8000373e <ilock+0x30>
    8000371c:	84aa                	mv	s1,a0
    8000371e:	451c                	lw	a5,8(a0)
    80003720:	00f05f63          	blez	a5,8000373e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003724:	0541                	addi	a0,a0,16
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	c7e080e7          	jalr	-898(ra) # 800043a4 <acquiresleep>
  if(ip->valid == 0){
    8000372e:	40bc                	lw	a5,64(s1)
    80003730:	cf99                	beqz	a5,8000374e <ilock+0x40>
}
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6902                	ld	s2,0(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret
    panic("ilock");
    8000373e:	00005517          	auipc	a0,0x5
    80003742:	f1a50513          	addi	a0,a0,-230 # 80008658 <syscalls+0x1a0>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	df6080e7          	jalr	-522(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000374e:	40dc                	lw	a5,4(s1)
    80003750:	0047d79b          	srliw	a5,a5,0x4
    80003754:	0001c597          	auipc	a1,0x1c
    80003758:	98c5a583          	lw	a1,-1652(a1) # 8001f0e0 <sb+0x18>
    8000375c:	9dbd                	addw	a1,a1,a5
    8000375e:	4088                	lw	a0,0(s1)
    80003760:	fffff097          	auipc	ra,0xfffff
    80003764:	79e080e7          	jalr	1950(ra) # 80002efe <bread>
    80003768:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000376a:	05850593          	addi	a1,a0,88
    8000376e:	40dc                	lw	a5,4(s1)
    80003770:	8bbd                	andi	a5,a5,15
    80003772:	079a                	slli	a5,a5,0x6
    80003774:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003776:	00059783          	lh	a5,0(a1)
    8000377a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000377e:	00259783          	lh	a5,2(a1)
    80003782:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003786:	00459783          	lh	a5,4(a1)
    8000378a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000378e:	00659783          	lh	a5,6(a1)
    80003792:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003796:	459c                	lw	a5,8(a1)
    80003798:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000379a:	03400613          	li	a2,52
    8000379e:	05b1                	addi	a1,a1,12
    800037a0:	05048513          	addi	a0,s1,80
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	586080e7          	jalr	1414(ra) # 80000d2a <memmove>
    brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	880080e7          	jalr	-1920(ra) # 8000302e <brelse>
    ip->valid = 1;
    800037b6:	4785                	li	a5,1
    800037b8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037ba:	04449783          	lh	a5,68(s1)
    800037be:	fbb5                	bnez	a5,80003732 <ilock+0x24>
      panic("ilock: no type");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	ea050513          	addi	a0,a0,-352 # 80008660 <syscalls+0x1a8>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d74080e7          	jalr	-652(ra) # 8000053c <panic>

00000000800037d0 <iunlock>:
{
    800037d0:	1101                	addi	sp,sp,-32
    800037d2:	ec06                	sd	ra,24(sp)
    800037d4:	e822                	sd	s0,16(sp)
    800037d6:	e426                	sd	s1,8(sp)
    800037d8:	e04a                	sd	s2,0(sp)
    800037da:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037dc:	c905                	beqz	a0,8000380c <iunlock+0x3c>
    800037de:	84aa                	mv	s1,a0
    800037e0:	01050913          	addi	s2,a0,16
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	c58080e7          	jalr	-936(ra) # 8000443e <holdingsleep>
    800037ee:	cd19                	beqz	a0,8000380c <iunlock+0x3c>
    800037f0:	449c                	lw	a5,8(s1)
    800037f2:	00f05d63          	blez	a5,8000380c <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	c02080e7          	jalr	-1022(ra) # 800043fa <releasesleep>
}
    80003800:	60e2                	ld	ra,24(sp)
    80003802:	6442                	ld	s0,16(sp)
    80003804:	64a2                	ld	s1,8(sp)
    80003806:	6902                	ld	s2,0(sp)
    80003808:	6105                	addi	sp,sp,32
    8000380a:	8082                	ret
    panic("iunlock");
    8000380c:	00005517          	auipc	a0,0x5
    80003810:	e6450513          	addi	a0,a0,-412 # 80008670 <syscalls+0x1b8>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	d28080e7          	jalr	-728(ra) # 8000053c <panic>

000000008000381c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000381c:	7179                	addi	sp,sp,-48
    8000381e:	f406                	sd	ra,40(sp)
    80003820:	f022                	sd	s0,32(sp)
    80003822:	ec26                	sd	s1,24(sp)
    80003824:	e84a                	sd	s2,16(sp)
    80003826:	e44e                	sd	s3,8(sp)
    80003828:	e052                	sd	s4,0(sp)
    8000382a:	1800                	addi	s0,sp,48
    8000382c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000382e:	05050493          	addi	s1,a0,80
    80003832:	08050913          	addi	s2,a0,128
    80003836:	a021                	j	8000383e <itrunc+0x22>
    80003838:	0491                	addi	s1,s1,4
    8000383a:	01248d63          	beq	s1,s2,80003854 <itrunc+0x38>
    if(ip->addrs[i]){
    8000383e:	408c                	lw	a1,0(s1)
    80003840:	dde5                	beqz	a1,80003838 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003842:	0009a503          	lw	a0,0(s3)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	8fc080e7          	jalr	-1796(ra) # 80003142 <bfree>
      ip->addrs[i] = 0;
    8000384e:	0004a023          	sw	zero,0(s1)
    80003852:	b7dd                	j	80003838 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003854:	0809a583          	lw	a1,128(s3)
    80003858:	e185                	bnez	a1,80003878 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000385a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000385e:	854e                	mv	a0,s3
    80003860:	00000097          	auipc	ra,0x0
    80003864:	de2080e7          	jalr	-542(ra) # 80003642 <iupdate>
}
    80003868:	70a2                	ld	ra,40(sp)
    8000386a:	7402                	ld	s0,32(sp)
    8000386c:	64e2                	ld	s1,24(sp)
    8000386e:	6942                	ld	s2,16(sp)
    80003870:	69a2                	ld	s3,8(sp)
    80003872:	6a02                	ld	s4,0(sp)
    80003874:	6145                	addi	sp,sp,48
    80003876:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003878:	0009a503          	lw	a0,0(s3)
    8000387c:	fffff097          	auipc	ra,0xfffff
    80003880:	682080e7          	jalr	1666(ra) # 80002efe <bread>
    80003884:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003886:	05850493          	addi	s1,a0,88
    8000388a:	45850913          	addi	s2,a0,1112
    8000388e:	a021                	j	80003896 <itrunc+0x7a>
    80003890:	0491                	addi	s1,s1,4
    80003892:	01248b63          	beq	s1,s2,800038a8 <itrunc+0x8c>
      if(a[j])
    80003896:	408c                	lw	a1,0(s1)
    80003898:	dde5                	beqz	a1,80003890 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000389a:	0009a503          	lw	a0,0(s3)
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	8a4080e7          	jalr	-1884(ra) # 80003142 <bfree>
    800038a6:	b7ed                	j	80003890 <itrunc+0x74>
    brelse(bp);
    800038a8:	8552                	mv	a0,s4
    800038aa:	fffff097          	auipc	ra,0xfffff
    800038ae:	784080e7          	jalr	1924(ra) # 8000302e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038b2:	0809a583          	lw	a1,128(s3)
    800038b6:	0009a503          	lw	a0,0(s3)
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	888080e7          	jalr	-1912(ra) # 80003142 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038c2:	0809a023          	sw	zero,128(s3)
    800038c6:	bf51                	j	8000385a <itrunc+0x3e>

00000000800038c8 <iput>:
{
    800038c8:	1101                	addi	sp,sp,-32
    800038ca:	ec06                	sd	ra,24(sp)
    800038cc:	e822                	sd	s0,16(sp)
    800038ce:	e426                	sd	s1,8(sp)
    800038d0:	e04a                	sd	s2,0(sp)
    800038d2:	1000                	addi	s0,sp,32
    800038d4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d6:	0001c517          	auipc	a0,0x1c
    800038da:	81250513          	addi	a0,a0,-2030 # 8001f0e8 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	2f4080e7          	jalr	756(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e6:	4498                	lw	a4,8(s1)
    800038e8:	4785                	li	a5,1
    800038ea:	02f70363          	beq	a4,a5,80003910 <iput+0x48>
  ip->ref--;
    800038ee:	449c                	lw	a5,8(s1)
    800038f0:	37fd                	addiw	a5,a5,-1
    800038f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f4:	0001b517          	auipc	a0,0x1b
    800038f8:	7f450513          	addi	a0,a0,2036 # 8001f0e8 <itable>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	38a080e7          	jalr	906(ra) # 80000c86 <release>
}
    80003904:	60e2                	ld	ra,24(sp)
    80003906:	6442                	ld	s0,16(sp)
    80003908:	64a2                	ld	s1,8(sp)
    8000390a:	6902                	ld	s2,0(sp)
    8000390c:	6105                	addi	sp,sp,32
    8000390e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003910:	40bc                	lw	a5,64(s1)
    80003912:	dff1                	beqz	a5,800038ee <iput+0x26>
    80003914:	04a49783          	lh	a5,74(s1)
    80003918:	fbf9                	bnez	a5,800038ee <iput+0x26>
    acquiresleep(&ip->lock);
    8000391a:	01048913          	addi	s2,s1,16
    8000391e:	854a                	mv	a0,s2
    80003920:	00001097          	auipc	ra,0x1
    80003924:	a84080e7          	jalr	-1404(ra) # 800043a4 <acquiresleep>
    release(&itable.lock);
    80003928:	0001b517          	auipc	a0,0x1b
    8000392c:	7c050513          	addi	a0,a0,1984 # 8001f0e8 <itable>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	356080e7          	jalr	854(ra) # 80000c86 <release>
    itrunc(ip);
    80003938:	8526                	mv	a0,s1
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	ee2080e7          	jalr	-286(ra) # 8000381c <itrunc>
    ip->type = 0;
    80003942:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003946:	8526                	mv	a0,s1
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	cfa080e7          	jalr	-774(ra) # 80003642 <iupdate>
    ip->valid = 0;
    80003950:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003954:	854a                	mv	a0,s2
    80003956:	00001097          	auipc	ra,0x1
    8000395a:	aa4080e7          	jalr	-1372(ra) # 800043fa <releasesleep>
    acquire(&itable.lock);
    8000395e:	0001b517          	auipc	a0,0x1b
    80003962:	78a50513          	addi	a0,a0,1930 # 8001f0e8 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	26c080e7          	jalr	620(ra) # 80000bd2 <acquire>
    8000396e:	b741                	j	800038ee <iput+0x26>

0000000080003970 <iunlockput>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	e54080e7          	jalr	-428(ra) # 800037d0 <iunlock>
  iput(ip);
    80003984:	8526                	mv	a0,s1
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	f42080e7          	jalr	-190(ra) # 800038c8 <iput>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret

0000000080003998 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003998:	1141                	addi	sp,sp,-16
    8000399a:	e422                	sd	s0,8(sp)
    8000399c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000399e:	411c                	lw	a5,0(a0)
    800039a0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039a2:	415c                	lw	a5,4(a0)
    800039a4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a6:	04451783          	lh	a5,68(a0)
    800039aa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ae:	04a51783          	lh	a5,74(a0)
    800039b2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b6:	04c56783          	lwu	a5,76(a0)
    800039ba:	e99c                	sd	a5,16(a1)
}
    800039bc:	6422                	ld	s0,8(sp)
    800039be:	0141                	addi	sp,sp,16
    800039c0:	8082                	ret

00000000800039c2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039c2:	457c                	lw	a5,76(a0)
    800039c4:	0ed7e963          	bltu	a5,a3,80003ab6 <readi+0xf4>
{
    800039c8:	7159                	addi	sp,sp,-112
    800039ca:	f486                	sd	ra,104(sp)
    800039cc:	f0a2                	sd	s0,96(sp)
    800039ce:	eca6                	sd	s1,88(sp)
    800039d0:	e8ca                	sd	s2,80(sp)
    800039d2:	e4ce                	sd	s3,72(sp)
    800039d4:	e0d2                	sd	s4,64(sp)
    800039d6:	fc56                	sd	s5,56(sp)
    800039d8:	f85a                	sd	s6,48(sp)
    800039da:	f45e                	sd	s7,40(sp)
    800039dc:	f062                	sd	s8,32(sp)
    800039de:	ec66                	sd	s9,24(sp)
    800039e0:	e86a                	sd	s10,16(sp)
    800039e2:	e46e                	sd	s11,8(sp)
    800039e4:	1880                	addi	s0,sp,112
    800039e6:	8b2a                	mv	s6,a0
    800039e8:	8bae                	mv	s7,a1
    800039ea:	8a32                	mv	s4,a2
    800039ec:	84b6                	mv	s1,a3
    800039ee:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800039f0:	9f35                	addw	a4,a4,a3
    return 0;
    800039f2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f4:	0ad76063          	bltu	a4,a3,80003a94 <readi+0xd2>
  if(off + n > ip->size)
    800039f8:	00e7f463          	bgeu	a5,a4,80003a00 <readi+0x3e>
    n = ip->size - off;
    800039fc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a00:	0a0a8963          	beqz	s5,80003ab2 <readi+0xf0>
    80003a04:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a06:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a0a:	5c7d                	li	s8,-1
    80003a0c:	a82d                	j	80003a46 <readi+0x84>
    80003a0e:	020d1d93          	slli	s11,s10,0x20
    80003a12:	020ddd93          	srli	s11,s11,0x20
    80003a16:	05890613          	addi	a2,s2,88
    80003a1a:	86ee                	mv	a3,s11
    80003a1c:	963a                	add	a2,a2,a4
    80003a1e:	85d2                	mv	a1,s4
    80003a20:	855e                	mv	a0,s7
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	a34080e7          	jalr	-1484(ra) # 80002456 <either_copyout>
    80003a2a:	05850d63          	beq	a0,s8,80003a84 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a2e:	854a                	mv	a0,s2
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	5fe080e7          	jalr	1534(ra) # 8000302e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a38:	013d09bb          	addw	s3,s10,s3
    80003a3c:	009d04bb          	addw	s1,s10,s1
    80003a40:	9a6e                	add	s4,s4,s11
    80003a42:	0559f763          	bgeu	s3,s5,80003a90 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a46:	00a4d59b          	srliw	a1,s1,0xa
    80003a4a:	855a                	mv	a0,s6
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	8a4080e7          	jalr	-1884(ra) # 800032f0 <bmap>
    80003a54:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a58:	cd85                	beqz	a1,80003a90 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a5a:	000b2503          	lw	a0,0(s6)
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	4a0080e7          	jalr	1184(ra) # 80002efe <bread>
    80003a66:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a68:	3ff4f713          	andi	a4,s1,1023
    80003a6c:	40ec87bb          	subw	a5,s9,a4
    80003a70:	413a86bb          	subw	a3,s5,s3
    80003a74:	8d3e                	mv	s10,a5
    80003a76:	2781                	sext.w	a5,a5
    80003a78:	0006861b          	sext.w	a2,a3
    80003a7c:	f8f679e3          	bgeu	a2,a5,80003a0e <readi+0x4c>
    80003a80:	8d36                	mv	s10,a3
    80003a82:	b771                	j	80003a0e <readi+0x4c>
      brelse(bp);
    80003a84:	854a                	mv	a0,s2
    80003a86:	fffff097          	auipc	ra,0xfffff
    80003a8a:	5a8080e7          	jalr	1448(ra) # 8000302e <brelse>
      tot = -1;
    80003a8e:	59fd                	li	s3,-1
  }
  return tot;
    80003a90:	0009851b          	sext.w	a0,s3
}
    80003a94:	70a6                	ld	ra,104(sp)
    80003a96:	7406                	ld	s0,96(sp)
    80003a98:	64e6                	ld	s1,88(sp)
    80003a9a:	6946                	ld	s2,80(sp)
    80003a9c:	69a6                	ld	s3,72(sp)
    80003a9e:	6a06                	ld	s4,64(sp)
    80003aa0:	7ae2                	ld	s5,56(sp)
    80003aa2:	7b42                	ld	s6,48(sp)
    80003aa4:	7ba2                	ld	s7,40(sp)
    80003aa6:	7c02                	ld	s8,32(sp)
    80003aa8:	6ce2                	ld	s9,24(sp)
    80003aaa:	6d42                	ld	s10,16(sp)
    80003aac:	6da2                	ld	s11,8(sp)
    80003aae:	6165                	addi	sp,sp,112
    80003ab0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab2:	89d6                	mv	s3,s5
    80003ab4:	bff1                	j	80003a90 <readi+0xce>
    return 0;
    80003ab6:	4501                	li	a0,0
}
    80003ab8:	8082                	ret

0000000080003aba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aba:	457c                	lw	a5,76(a0)
    80003abc:	10d7e863          	bltu	a5,a3,80003bcc <writei+0x112>
{
    80003ac0:	7159                	addi	sp,sp,-112
    80003ac2:	f486                	sd	ra,104(sp)
    80003ac4:	f0a2                	sd	s0,96(sp)
    80003ac6:	eca6                	sd	s1,88(sp)
    80003ac8:	e8ca                	sd	s2,80(sp)
    80003aca:	e4ce                	sd	s3,72(sp)
    80003acc:	e0d2                	sd	s4,64(sp)
    80003ace:	fc56                	sd	s5,56(sp)
    80003ad0:	f85a                	sd	s6,48(sp)
    80003ad2:	f45e                	sd	s7,40(sp)
    80003ad4:	f062                	sd	s8,32(sp)
    80003ad6:	ec66                	sd	s9,24(sp)
    80003ad8:	e86a                	sd	s10,16(sp)
    80003ada:	e46e                	sd	s11,8(sp)
    80003adc:	1880                	addi	s0,sp,112
    80003ade:	8aaa                	mv	s5,a0
    80003ae0:	8bae                	mv	s7,a1
    80003ae2:	8a32                	mv	s4,a2
    80003ae4:	8936                	mv	s2,a3
    80003ae6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ae8:	00e687bb          	addw	a5,a3,a4
    80003aec:	0ed7e263          	bltu	a5,a3,80003bd0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003af0:	00043737          	lui	a4,0x43
    80003af4:	0ef76063          	bltu	a4,a5,80003bd4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003af8:	0c0b0863          	beqz	s6,80003bc8 <writei+0x10e>
    80003afc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003afe:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b02:	5c7d                	li	s8,-1
    80003b04:	a091                	j	80003b48 <writei+0x8e>
    80003b06:	020d1d93          	slli	s11,s10,0x20
    80003b0a:	020ddd93          	srli	s11,s11,0x20
    80003b0e:	05848513          	addi	a0,s1,88
    80003b12:	86ee                	mv	a3,s11
    80003b14:	8652                	mv	a2,s4
    80003b16:	85de                	mv	a1,s7
    80003b18:	953a                	add	a0,a0,a4
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	992080e7          	jalr	-1646(ra) # 800024ac <either_copyin>
    80003b22:	07850263          	beq	a0,s8,80003b86 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b26:	8526                	mv	a0,s1
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	75e080e7          	jalr	1886(ra) # 80004286 <log_write>
    brelse(bp);
    80003b30:	8526                	mv	a0,s1
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	4fc080e7          	jalr	1276(ra) # 8000302e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3a:	013d09bb          	addw	s3,s10,s3
    80003b3e:	012d093b          	addw	s2,s10,s2
    80003b42:	9a6e                	add	s4,s4,s11
    80003b44:	0569f663          	bgeu	s3,s6,80003b90 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b48:	00a9559b          	srliw	a1,s2,0xa
    80003b4c:	8556                	mv	a0,s5
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	7a2080e7          	jalr	1954(ra) # 800032f0 <bmap>
    80003b56:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b5a:	c99d                	beqz	a1,80003b90 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b5c:	000aa503          	lw	a0,0(s5)
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	39e080e7          	jalr	926(ra) # 80002efe <bread>
    80003b68:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6a:	3ff97713          	andi	a4,s2,1023
    80003b6e:	40ec87bb          	subw	a5,s9,a4
    80003b72:	413b06bb          	subw	a3,s6,s3
    80003b76:	8d3e                	mv	s10,a5
    80003b78:	2781                	sext.w	a5,a5
    80003b7a:	0006861b          	sext.w	a2,a3
    80003b7e:	f8f674e3          	bgeu	a2,a5,80003b06 <writei+0x4c>
    80003b82:	8d36                	mv	s10,a3
    80003b84:	b749                	j	80003b06 <writei+0x4c>
      brelse(bp);
    80003b86:	8526                	mv	a0,s1
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	4a6080e7          	jalr	1190(ra) # 8000302e <brelse>
  }

  if(off > ip->size)
    80003b90:	04caa783          	lw	a5,76(s5)
    80003b94:	0127f463          	bgeu	a5,s2,80003b9c <writei+0xe2>
    ip->size = off;
    80003b98:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b9c:	8556                	mv	a0,s5
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	aa4080e7          	jalr	-1372(ra) # 80003642 <iupdate>

  return tot;
    80003ba6:	0009851b          	sext.w	a0,s3
}
    80003baa:	70a6                	ld	ra,104(sp)
    80003bac:	7406                	ld	s0,96(sp)
    80003bae:	64e6                	ld	s1,88(sp)
    80003bb0:	6946                	ld	s2,80(sp)
    80003bb2:	69a6                	ld	s3,72(sp)
    80003bb4:	6a06                	ld	s4,64(sp)
    80003bb6:	7ae2                	ld	s5,56(sp)
    80003bb8:	7b42                	ld	s6,48(sp)
    80003bba:	7ba2                	ld	s7,40(sp)
    80003bbc:	7c02                	ld	s8,32(sp)
    80003bbe:	6ce2                	ld	s9,24(sp)
    80003bc0:	6d42                	ld	s10,16(sp)
    80003bc2:	6da2                	ld	s11,8(sp)
    80003bc4:	6165                	addi	sp,sp,112
    80003bc6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc8:	89da                	mv	s3,s6
    80003bca:	bfc9                	j	80003b9c <writei+0xe2>
    return -1;
    80003bcc:	557d                	li	a0,-1
}
    80003bce:	8082                	ret
    return -1;
    80003bd0:	557d                	li	a0,-1
    80003bd2:	bfe1                	j	80003baa <writei+0xf0>
    return -1;
    80003bd4:	557d                	li	a0,-1
    80003bd6:	bfd1                	j	80003baa <writei+0xf0>

0000000080003bd8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bd8:	1141                	addi	sp,sp,-16
    80003bda:	e406                	sd	ra,8(sp)
    80003bdc:	e022                	sd	s0,0(sp)
    80003bde:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003be0:	4639                	li	a2,14
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	1bc080e7          	jalr	444(ra) # 80000d9e <strncmp>
}
    80003bea:	60a2                	ld	ra,8(sp)
    80003bec:	6402                	ld	s0,0(sp)
    80003bee:	0141                	addi	sp,sp,16
    80003bf0:	8082                	ret

0000000080003bf2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bf2:	7139                	addi	sp,sp,-64
    80003bf4:	fc06                	sd	ra,56(sp)
    80003bf6:	f822                	sd	s0,48(sp)
    80003bf8:	f426                	sd	s1,40(sp)
    80003bfa:	f04a                	sd	s2,32(sp)
    80003bfc:	ec4e                	sd	s3,24(sp)
    80003bfe:	e852                	sd	s4,16(sp)
    80003c00:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c02:	04451703          	lh	a4,68(a0)
    80003c06:	4785                	li	a5,1
    80003c08:	00f71a63          	bne	a4,a5,80003c1c <dirlookup+0x2a>
    80003c0c:	892a                	mv	s2,a0
    80003c0e:	89ae                	mv	s3,a1
    80003c10:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c12:	457c                	lw	a5,76(a0)
    80003c14:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c16:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c18:	e79d                	bnez	a5,80003c46 <dirlookup+0x54>
    80003c1a:	a8a5                	j	80003c92 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c1c:	00005517          	auipc	a0,0x5
    80003c20:	a5c50513          	addi	a0,a0,-1444 # 80008678 <syscalls+0x1c0>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	918080e7          	jalr	-1768(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	a6450513          	addi	a0,a0,-1436 # 80008690 <syscalls+0x1d8>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	908080e7          	jalr	-1784(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3c:	24c1                	addiw	s1,s1,16
    80003c3e:	04c92783          	lw	a5,76(s2)
    80003c42:	04f4f763          	bgeu	s1,a5,80003c90 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c46:	4741                	li	a4,16
    80003c48:	86a6                	mv	a3,s1
    80003c4a:	fc040613          	addi	a2,s0,-64
    80003c4e:	4581                	li	a1,0
    80003c50:	854a                	mv	a0,s2
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	d70080e7          	jalr	-656(ra) # 800039c2 <readi>
    80003c5a:	47c1                	li	a5,16
    80003c5c:	fcf518e3          	bne	a0,a5,80003c2c <dirlookup+0x3a>
    if(de.inum == 0)
    80003c60:	fc045783          	lhu	a5,-64(s0)
    80003c64:	dfe1                	beqz	a5,80003c3c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c66:	fc240593          	addi	a1,s0,-62
    80003c6a:	854e                	mv	a0,s3
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	f6c080e7          	jalr	-148(ra) # 80003bd8 <namecmp>
    80003c74:	f561                	bnez	a0,80003c3c <dirlookup+0x4a>
      if(poff)
    80003c76:	000a0463          	beqz	s4,80003c7e <dirlookup+0x8c>
        *poff = off;
    80003c7a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c7e:	fc045583          	lhu	a1,-64(s0)
    80003c82:	00092503          	lw	a0,0(s2)
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	754080e7          	jalr	1876(ra) # 800033da <iget>
    80003c8e:	a011                	j	80003c92 <dirlookup+0xa0>
  return 0;
    80003c90:	4501                	li	a0,0
}
    80003c92:	70e2                	ld	ra,56(sp)
    80003c94:	7442                	ld	s0,48(sp)
    80003c96:	74a2                	ld	s1,40(sp)
    80003c98:	7902                	ld	s2,32(sp)
    80003c9a:	69e2                	ld	s3,24(sp)
    80003c9c:	6a42                	ld	s4,16(sp)
    80003c9e:	6121                	addi	sp,sp,64
    80003ca0:	8082                	ret

0000000080003ca2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ca2:	711d                	addi	sp,sp,-96
    80003ca4:	ec86                	sd	ra,88(sp)
    80003ca6:	e8a2                	sd	s0,80(sp)
    80003ca8:	e4a6                	sd	s1,72(sp)
    80003caa:	e0ca                	sd	s2,64(sp)
    80003cac:	fc4e                	sd	s3,56(sp)
    80003cae:	f852                	sd	s4,48(sp)
    80003cb0:	f456                	sd	s5,40(sp)
    80003cb2:	f05a                	sd	s6,32(sp)
    80003cb4:	ec5e                	sd	s7,24(sp)
    80003cb6:	e862                	sd	s8,16(sp)
    80003cb8:	e466                	sd	s9,8(sp)
    80003cba:	1080                	addi	s0,sp,96
    80003cbc:	84aa                	mv	s1,a0
    80003cbe:	8b2e                	mv	s6,a1
    80003cc0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cc2:	00054703          	lbu	a4,0(a0)
    80003cc6:	02f00793          	li	a5,47
    80003cca:	02f70263          	beq	a4,a5,80003cee <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cce:	ffffe097          	auipc	ra,0xffffe
    80003cd2:	cd8080e7          	jalr	-808(ra) # 800019a6 <myproc>
    80003cd6:	15053503          	ld	a0,336(a0)
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	9f6080e7          	jalr	-1546(ra) # 800036d0 <idup>
    80003ce2:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ce4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ce8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cea:	4b85                	li	s7,1
    80003cec:	a875                	j	80003da8 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003cee:	4585                	li	a1,1
    80003cf0:	4505                	li	a0,1
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	6e8080e7          	jalr	1768(ra) # 800033da <iget>
    80003cfa:	8a2a                	mv	s4,a0
    80003cfc:	b7e5                	j	80003ce4 <namex+0x42>
      iunlockput(ip);
    80003cfe:	8552                	mv	a0,s4
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	c70080e7          	jalr	-912(ra) # 80003970 <iunlockput>
      return 0;
    80003d08:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d0a:	8552                	mv	a0,s4
    80003d0c:	60e6                	ld	ra,88(sp)
    80003d0e:	6446                	ld	s0,80(sp)
    80003d10:	64a6                	ld	s1,72(sp)
    80003d12:	6906                	ld	s2,64(sp)
    80003d14:	79e2                	ld	s3,56(sp)
    80003d16:	7a42                	ld	s4,48(sp)
    80003d18:	7aa2                	ld	s5,40(sp)
    80003d1a:	7b02                	ld	s6,32(sp)
    80003d1c:	6be2                	ld	s7,24(sp)
    80003d1e:	6c42                	ld	s8,16(sp)
    80003d20:	6ca2                	ld	s9,8(sp)
    80003d22:	6125                	addi	sp,sp,96
    80003d24:	8082                	ret
      iunlock(ip);
    80003d26:	8552                	mv	a0,s4
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	aa8080e7          	jalr	-1368(ra) # 800037d0 <iunlock>
      return ip;
    80003d30:	bfe9                	j	80003d0a <namex+0x68>
      iunlockput(ip);
    80003d32:	8552                	mv	a0,s4
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	c3c080e7          	jalr	-964(ra) # 80003970 <iunlockput>
      return 0;
    80003d3c:	8a4e                	mv	s4,s3
    80003d3e:	b7f1                	j	80003d0a <namex+0x68>
  len = path - s;
    80003d40:	40998633          	sub	a2,s3,s1
    80003d44:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d48:	099c5863          	bge	s8,s9,80003dd8 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d4c:	4639                	li	a2,14
    80003d4e:	85a6                	mv	a1,s1
    80003d50:	8556                	mv	a0,s5
    80003d52:	ffffd097          	auipc	ra,0xffffd
    80003d56:	fd8080e7          	jalr	-40(ra) # 80000d2a <memmove>
    80003d5a:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d5c:	0004c783          	lbu	a5,0(s1)
    80003d60:	01279763          	bne	a5,s2,80003d6e <namex+0xcc>
    path++;
    80003d64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d66:	0004c783          	lbu	a5,0(s1)
    80003d6a:	ff278de3          	beq	a5,s2,80003d64 <namex+0xc2>
    ilock(ip);
    80003d6e:	8552                	mv	a0,s4
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	99e080e7          	jalr	-1634(ra) # 8000370e <ilock>
    if(ip->type != T_DIR){
    80003d78:	044a1783          	lh	a5,68(s4)
    80003d7c:	f97791e3          	bne	a5,s7,80003cfe <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003d80:	000b0563          	beqz	s6,80003d8a <namex+0xe8>
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	dfd9                	beqz	a5,80003d26 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d8a:	4601                	li	a2,0
    80003d8c:	85d6                	mv	a1,s5
    80003d8e:	8552                	mv	a0,s4
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	e62080e7          	jalr	-414(ra) # 80003bf2 <dirlookup>
    80003d98:	89aa                	mv	s3,a0
    80003d9a:	dd41                	beqz	a0,80003d32 <namex+0x90>
    iunlockput(ip);
    80003d9c:	8552                	mv	a0,s4
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	bd2080e7          	jalr	-1070(ra) # 80003970 <iunlockput>
    ip = next;
    80003da6:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	01279763          	bne	a5,s2,80003dba <namex+0x118>
    path++;
    80003db0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db2:	0004c783          	lbu	a5,0(s1)
    80003db6:	ff278de3          	beq	a5,s2,80003db0 <namex+0x10e>
  if(*path == 0)
    80003dba:	cb9d                	beqz	a5,80003df0 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	89a6                	mv	s3,s1
  len = path - s;
    80003dc2:	4c81                	li	s9,0
    80003dc4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003dc6:	01278963          	beq	a5,s2,80003dd8 <namex+0x136>
    80003dca:	dbbd                	beqz	a5,80003d40 <namex+0x9e>
    path++;
    80003dcc:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dce:	0009c783          	lbu	a5,0(s3)
    80003dd2:	ff279ce3          	bne	a5,s2,80003dca <namex+0x128>
    80003dd6:	b7ad                	j	80003d40 <namex+0x9e>
    memmove(name, s, len);
    80003dd8:	2601                	sext.w	a2,a2
    80003dda:	85a6                	mv	a1,s1
    80003ddc:	8556                	mv	a0,s5
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	f4c080e7          	jalr	-180(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003de6:	9cd6                	add	s9,s9,s5
    80003de8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003dec:	84ce                	mv	s1,s3
    80003dee:	b7bd                	j	80003d5c <namex+0xba>
  if(nameiparent){
    80003df0:	f00b0de3          	beqz	s6,80003d0a <namex+0x68>
    iput(ip);
    80003df4:	8552                	mv	a0,s4
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	ad2080e7          	jalr	-1326(ra) # 800038c8 <iput>
    return 0;
    80003dfe:	4a01                	li	s4,0
    80003e00:	b729                	j	80003d0a <namex+0x68>

0000000080003e02 <dirlink>:
{
    80003e02:	7139                	addi	sp,sp,-64
    80003e04:	fc06                	sd	ra,56(sp)
    80003e06:	f822                	sd	s0,48(sp)
    80003e08:	f426                	sd	s1,40(sp)
    80003e0a:	f04a                	sd	s2,32(sp)
    80003e0c:	ec4e                	sd	s3,24(sp)
    80003e0e:	e852                	sd	s4,16(sp)
    80003e10:	0080                	addi	s0,sp,64
    80003e12:	892a                	mv	s2,a0
    80003e14:	8a2e                	mv	s4,a1
    80003e16:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e18:	4601                	li	a2,0
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	dd8080e7          	jalr	-552(ra) # 80003bf2 <dirlookup>
    80003e22:	e93d                	bnez	a0,80003e98 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e24:	04c92483          	lw	s1,76(s2)
    80003e28:	c49d                	beqz	s1,80003e56 <dirlink+0x54>
    80003e2a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2c:	4741                	li	a4,16
    80003e2e:	86a6                	mv	a3,s1
    80003e30:	fc040613          	addi	a2,s0,-64
    80003e34:	4581                	li	a1,0
    80003e36:	854a                	mv	a0,s2
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	b8a080e7          	jalr	-1142(ra) # 800039c2 <readi>
    80003e40:	47c1                	li	a5,16
    80003e42:	06f51163          	bne	a0,a5,80003ea4 <dirlink+0xa2>
    if(de.inum == 0)
    80003e46:	fc045783          	lhu	a5,-64(s0)
    80003e4a:	c791                	beqz	a5,80003e56 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4c:	24c1                	addiw	s1,s1,16
    80003e4e:	04c92783          	lw	a5,76(s2)
    80003e52:	fcf4ede3          	bltu	s1,a5,80003e2c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e56:	4639                	li	a2,14
    80003e58:	85d2                	mv	a1,s4
    80003e5a:	fc240513          	addi	a0,s0,-62
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	f7c080e7          	jalr	-132(ra) # 80000dda <strncpy>
  de.inum = inum;
    80003e66:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6a:	4741                	li	a4,16
    80003e6c:	86a6                	mv	a3,s1
    80003e6e:	fc040613          	addi	a2,s0,-64
    80003e72:	4581                	li	a1,0
    80003e74:	854a                	mv	a0,s2
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	c44080e7          	jalr	-956(ra) # 80003aba <writei>
    80003e7e:	1541                	addi	a0,a0,-16
    80003e80:	00a03533          	snez	a0,a0
    80003e84:	40a00533          	neg	a0,a0
}
    80003e88:	70e2                	ld	ra,56(sp)
    80003e8a:	7442                	ld	s0,48(sp)
    80003e8c:	74a2                	ld	s1,40(sp)
    80003e8e:	7902                	ld	s2,32(sp)
    80003e90:	69e2                	ld	s3,24(sp)
    80003e92:	6a42                	ld	s4,16(sp)
    80003e94:	6121                	addi	sp,sp,64
    80003e96:	8082                	ret
    iput(ip);
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	a30080e7          	jalr	-1488(ra) # 800038c8 <iput>
    return -1;
    80003ea0:	557d                	li	a0,-1
    80003ea2:	b7dd                	j	80003e88 <dirlink+0x86>
      panic("dirlink read");
    80003ea4:	00004517          	auipc	a0,0x4
    80003ea8:	7fc50513          	addi	a0,a0,2044 # 800086a0 <syscalls+0x1e8>
    80003eac:	ffffc097          	auipc	ra,0xffffc
    80003eb0:	690080e7          	jalr	1680(ra) # 8000053c <panic>

0000000080003eb4 <namei>:

struct inode*
namei(char *path)
{
    80003eb4:	1101                	addi	sp,sp,-32
    80003eb6:	ec06                	sd	ra,24(sp)
    80003eb8:	e822                	sd	s0,16(sp)
    80003eba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ebc:	fe040613          	addi	a2,s0,-32
    80003ec0:	4581                	li	a1,0
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	de0080e7          	jalr	-544(ra) # 80003ca2 <namex>
}
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	6105                	addi	sp,sp,32
    80003ed0:	8082                	ret

0000000080003ed2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed2:	1141                	addi	sp,sp,-16
    80003ed4:	e406                	sd	ra,8(sp)
    80003ed6:	e022                	sd	s0,0(sp)
    80003ed8:	0800                	addi	s0,sp,16
    80003eda:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003edc:	4585                	li	a1,1
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	dc4080e7          	jalr	-572(ra) # 80003ca2 <namex>
}
    80003ee6:	60a2                	ld	ra,8(sp)
    80003ee8:	6402                	ld	s0,0(sp)
    80003eea:	0141                	addi	sp,sp,16
    80003eec:	8082                	ret

0000000080003eee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eee:	1101                	addi	sp,sp,-32
    80003ef0:	ec06                	sd	ra,24(sp)
    80003ef2:	e822                	sd	s0,16(sp)
    80003ef4:	e426                	sd	s1,8(sp)
    80003ef6:	e04a                	sd	s2,0(sp)
    80003ef8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003efa:	0001d917          	auipc	s2,0x1d
    80003efe:	c9690913          	addi	s2,s2,-874 # 80020b90 <log>
    80003f02:	01892583          	lw	a1,24(s2)
    80003f06:	02892503          	lw	a0,40(s2)
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	ff4080e7          	jalr	-12(ra) # 80002efe <bread>
    80003f12:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f14:	02c92603          	lw	a2,44(s2)
    80003f18:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f1a:	00c05f63          	blez	a2,80003f38 <write_head+0x4a>
    80003f1e:	0001d717          	auipc	a4,0x1d
    80003f22:	ca270713          	addi	a4,a4,-862 # 80020bc0 <log+0x30>
    80003f26:	87aa                	mv	a5,a0
    80003f28:	060a                	slli	a2,a2,0x2
    80003f2a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f2c:	4314                	lw	a3,0(a4)
    80003f2e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f30:	0711                	addi	a4,a4,4
    80003f32:	0791                	addi	a5,a5,4
    80003f34:	fec79ce3          	bne	a5,a2,80003f2c <write_head+0x3e>
  }
  bwrite(buf);
    80003f38:	8526                	mv	a0,s1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	0b6080e7          	jalr	182(ra) # 80002ff0 <bwrite>
  brelse(buf);
    80003f42:	8526                	mv	a0,s1
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	0ea080e7          	jalr	234(ra) # 8000302e <brelse>
}
    80003f4c:	60e2                	ld	ra,24(sp)
    80003f4e:	6442                	ld	s0,16(sp)
    80003f50:	64a2                	ld	s1,8(sp)
    80003f52:	6902                	ld	s2,0(sp)
    80003f54:	6105                	addi	sp,sp,32
    80003f56:	8082                	ret

0000000080003f58 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f58:	0001d797          	auipc	a5,0x1d
    80003f5c:	c647a783          	lw	a5,-924(a5) # 80020bbc <log+0x2c>
    80003f60:	0af05d63          	blez	a5,8000401a <install_trans+0xc2>
{
    80003f64:	7139                	addi	sp,sp,-64
    80003f66:	fc06                	sd	ra,56(sp)
    80003f68:	f822                	sd	s0,48(sp)
    80003f6a:	f426                	sd	s1,40(sp)
    80003f6c:	f04a                	sd	s2,32(sp)
    80003f6e:	ec4e                	sd	s3,24(sp)
    80003f70:	e852                	sd	s4,16(sp)
    80003f72:	e456                	sd	s5,8(sp)
    80003f74:	e05a                	sd	s6,0(sp)
    80003f76:	0080                	addi	s0,sp,64
    80003f78:	8b2a                	mv	s6,a0
    80003f7a:	0001da97          	auipc	s5,0x1d
    80003f7e:	c46a8a93          	addi	s5,s5,-954 # 80020bc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f82:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f84:	0001d997          	auipc	s3,0x1d
    80003f88:	c0c98993          	addi	s3,s3,-1012 # 80020b90 <log>
    80003f8c:	a00d                	j	80003fae <install_trans+0x56>
    brelse(lbuf);
    80003f8e:	854a                	mv	a0,s2
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	09e080e7          	jalr	158(ra) # 8000302e <brelse>
    brelse(dbuf);
    80003f98:	8526                	mv	a0,s1
    80003f9a:	fffff097          	auipc	ra,0xfffff
    80003f9e:	094080e7          	jalr	148(ra) # 8000302e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa2:	2a05                	addiw	s4,s4,1
    80003fa4:	0a91                	addi	s5,s5,4
    80003fa6:	02c9a783          	lw	a5,44(s3)
    80003faa:	04fa5e63          	bge	s4,a5,80004006 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fae:	0189a583          	lw	a1,24(s3)
    80003fb2:	014585bb          	addw	a1,a1,s4
    80003fb6:	2585                	addiw	a1,a1,1
    80003fb8:	0289a503          	lw	a0,40(s3)
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	f42080e7          	jalr	-190(ra) # 80002efe <bread>
    80003fc4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fc6:	000aa583          	lw	a1,0(s5)
    80003fca:	0289a503          	lw	a0,40(s3)
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	f30080e7          	jalr	-208(ra) # 80002efe <bread>
    80003fd6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fd8:	40000613          	li	a2,1024
    80003fdc:	05890593          	addi	a1,s2,88
    80003fe0:	05850513          	addi	a0,a0,88
    80003fe4:	ffffd097          	auipc	ra,0xffffd
    80003fe8:	d46080e7          	jalr	-698(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	002080e7          	jalr	2(ra) # 80002ff0 <bwrite>
    if(recovering == 0)
    80003ff6:	f80b1ce3          	bnez	s6,80003f8e <install_trans+0x36>
      bunpin(dbuf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	10a080e7          	jalr	266(ra) # 80003106 <bunpin>
    80004004:	b769                	j	80003f8e <install_trans+0x36>
}
    80004006:	70e2                	ld	ra,56(sp)
    80004008:	7442                	ld	s0,48(sp)
    8000400a:	74a2                	ld	s1,40(sp)
    8000400c:	7902                	ld	s2,32(sp)
    8000400e:	69e2                	ld	s3,24(sp)
    80004010:	6a42                	ld	s4,16(sp)
    80004012:	6aa2                	ld	s5,8(sp)
    80004014:	6b02                	ld	s6,0(sp)
    80004016:	6121                	addi	sp,sp,64
    80004018:	8082                	ret
    8000401a:	8082                	ret

000000008000401c <initlog>:
{
    8000401c:	7179                	addi	sp,sp,-48
    8000401e:	f406                	sd	ra,40(sp)
    80004020:	f022                	sd	s0,32(sp)
    80004022:	ec26                	sd	s1,24(sp)
    80004024:	e84a                	sd	s2,16(sp)
    80004026:	e44e                	sd	s3,8(sp)
    80004028:	1800                	addi	s0,sp,48
    8000402a:	892a                	mv	s2,a0
    8000402c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000402e:	0001d497          	auipc	s1,0x1d
    80004032:	b6248493          	addi	s1,s1,-1182 # 80020b90 <log>
    80004036:	00004597          	auipc	a1,0x4
    8000403a:	67a58593          	addi	a1,a1,1658 # 800086b0 <syscalls+0x1f8>
    8000403e:	8526                	mv	a0,s1
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	b02080e7          	jalr	-1278(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004048:	0149a583          	lw	a1,20(s3)
    8000404c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000404e:	0109a783          	lw	a5,16(s3)
    80004052:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004054:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004058:	854a                	mv	a0,s2
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	ea4080e7          	jalr	-348(ra) # 80002efe <bread>
  log.lh.n = lh->n;
    80004062:	4d30                	lw	a2,88(a0)
    80004064:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004066:	00c05f63          	blez	a2,80004084 <initlog+0x68>
    8000406a:	87aa                	mv	a5,a0
    8000406c:	0001d717          	auipc	a4,0x1d
    80004070:	b5470713          	addi	a4,a4,-1196 # 80020bc0 <log+0x30>
    80004074:	060a                	slli	a2,a2,0x2
    80004076:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004078:	4ff4                	lw	a3,92(a5)
    8000407a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000407c:	0791                	addi	a5,a5,4
    8000407e:	0711                	addi	a4,a4,4
    80004080:	fec79ce3          	bne	a5,a2,80004078 <initlog+0x5c>
  brelse(buf);
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	faa080e7          	jalr	-86(ra) # 8000302e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000408c:	4505                	li	a0,1
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	eca080e7          	jalr	-310(ra) # 80003f58 <install_trans>
  log.lh.n = 0;
    80004096:	0001d797          	auipc	a5,0x1d
    8000409a:	b207a323          	sw	zero,-1242(a5) # 80020bbc <log+0x2c>
  write_head(); // clear the log
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	e50080e7          	jalr	-432(ra) # 80003eee <write_head>
}
    800040a6:	70a2                	ld	ra,40(sp)
    800040a8:	7402                	ld	s0,32(sp)
    800040aa:	64e2                	ld	s1,24(sp)
    800040ac:	6942                	ld	s2,16(sp)
    800040ae:	69a2                	ld	s3,8(sp)
    800040b0:	6145                	addi	sp,sp,48
    800040b2:	8082                	ret

00000000800040b4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b4:	1101                	addi	sp,sp,-32
    800040b6:	ec06                	sd	ra,24(sp)
    800040b8:	e822                	sd	s0,16(sp)
    800040ba:	e426                	sd	s1,8(sp)
    800040bc:	e04a                	sd	s2,0(sp)
    800040be:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040c0:	0001d517          	auipc	a0,0x1d
    800040c4:	ad050513          	addi	a0,a0,-1328 # 80020b90 <log>
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	b0a080e7          	jalr	-1270(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800040d0:	0001d497          	auipc	s1,0x1d
    800040d4:	ac048493          	addi	s1,s1,-1344 # 80020b90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d8:	4979                	li	s2,30
    800040da:	a039                	j	800040e8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040dc:	85a6                	mv	a1,s1
    800040de:	8526                	mv	a0,s1
    800040e0:	ffffe097          	auipc	ra,0xffffe
    800040e4:	f6e080e7          	jalr	-146(ra) # 8000204e <sleep>
    if(log.committing){
    800040e8:	50dc                	lw	a5,36(s1)
    800040ea:	fbed                	bnez	a5,800040dc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ec:	5098                	lw	a4,32(s1)
    800040ee:	2705                	addiw	a4,a4,1
    800040f0:	0027179b          	slliw	a5,a4,0x2
    800040f4:	9fb9                	addw	a5,a5,a4
    800040f6:	0017979b          	slliw	a5,a5,0x1
    800040fa:	54d4                	lw	a3,44(s1)
    800040fc:	9fb5                	addw	a5,a5,a3
    800040fe:	00f95963          	bge	s2,a5,80004110 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004102:	85a6                	mv	a1,s1
    80004104:	8526                	mv	a0,s1
    80004106:	ffffe097          	auipc	ra,0xffffe
    8000410a:	f48080e7          	jalr	-184(ra) # 8000204e <sleep>
    8000410e:	bfe9                	j	800040e8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004110:	0001d517          	auipc	a0,0x1d
    80004114:	a8050513          	addi	a0,a0,-1408 # 80020b90 <log>
    80004118:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	b6c080e7          	jalr	-1172(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004122:	60e2                	ld	ra,24(sp)
    80004124:	6442                	ld	s0,16(sp)
    80004126:	64a2                	ld	s1,8(sp)
    80004128:	6902                	ld	s2,0(sp)
    8000412a:	6105                	addi	sp,sp,32
    8000412c:	8082                	ret

000000008000412e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000412e:	7139                	addi	sp,sp,-64
    80004130:	fc06                	sd	ra,56(sp)
    80004132:	f822                	sd	s0,48(sp)
    80004134:	f426                	sd	s1,40(sp)
    80004136:	f04a                	sd	s2,32(sp)
    80004138:	ec4e                	sd	s3,24(sp)
    8000413a:	e852                	sd	s4,16(sp)
    8000413c:	e456                	sd	s5,8(sp)
    8000413e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004140:	0001d497          	auipc	s1,0x1d
    80004144:	a5048493          	addi	s1,s1,-1456 # 80020b90 <log>
    80004148:	8526                	mv	a0,s1
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	a88080e7          	jalr	-1400(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004152:	509c                	lw	a5,32(s1)
    80004154:	37fd                	addiw	a5,a5,-1
    80004156:	0007891b          	sext.w	s2,a5
    8000415a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000415c:	50dc                	lw	a5,36(s1)
    8000415e:	e7b9                	bnez	a5,800041ac <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004160:	04091e63          	bnez	s2,800041bc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004164:	0001d497          	auipc	s1,0x1d
    80004168:	a2c48493          	addi	s1,s1,-1492 # 80020b90 <log>
    8000416c:	4785                	li	a5,1
    8000416e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	b14080e7          	jalr	-1260(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417a:	54dc                	lw	a5,44(s1)
    8000417c:	06f04763          	bgtz	a5,800041ea <end_op+0xbc>
    acquire(&log.lock);
    80004180:	0001d497          	auipc	s1,0x1d
    80004184:	a1048493          	addi	s1,s1,-1520 # 80020b90 <log>
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	a48080e7          	jalr	-1464(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004192:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004196:	8526                	mv	a0,s1
    80004198:	ffffe097          	auipc	ra,0xffffe
    8000419c:	f1a080e7          	jalr	-230(ra) # 800020b2 <wakeup>
    release(&log.lock);
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	ae4080e7          	jalr	-1308(ra) # 80000c86 <release>
}
    800041aa:	a03d                	j	800041d8 <end_op+0xaa>
    panic("log.committing");
    800041ac:	00004517          	auipc	a0,0x4
    800041b0:	50c50513          	addi	a0,a0,1292 # 800086b8 <syscalls+0x200>
    800041b4:	ffffc097          	auipc	ra,0xffffc
    800041b8:	388080e7          	jalr	904(ra) # 8000053c <panic>
    wakeup(&log);
    800041bc:	0001d497          	auipc	s1,0x1d
    800041c0:	9d448493          	addi	s1,s1,-1580 # 80020b90 <log>
    800041c4:	8526                	mv	a0,s1
    800041c6:	ffffe097          	auipc	ra,0xffffe
    800041ca:	eec080e7          	jalr	-276(ra) # 800020b2 <wakeup>
  release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ab6080e7          	jalr	-1354(ra) # 80000c86 <release>
}
    800041d8:	70e2                	ld	ra,56(sp)
    800041da:	7442                	ld	s0,48(sp)
    800041dc:	74a2                	ld	s1,40(sp)
    800041de:	7902                	ld	s2,32(sp)
    800041e0:	69e2                	ld	s3,24(sp)
    800041e2:	6a42                	ld	s4,16(sp)
    800041e4:	6aa2                	ld	s5,8(sp)
    800041e6:	6121                	addi	sp,sp,64
    800041e8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ea:	0001da97          	auipc	s5,0x1d
    800041ee:	9d6a8a93          	addi	s5,s5,-1578 # 80020bc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f2:	0001da17          	auipc	s4,0x1d
    800041f6:	99ea0a13          	addi	s4,s4,-1634 # 80020b90 <log>
    800041fa:	018a2583          	lw	a1,24(s4)
    800041fe:	012585bb          	addw	a1,a1,s2
    80004202:	2585                	addiw	a1,a1,1
    80004204:	028a2503          	lw	a0,40(s4)
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	cf6080e7          	jalr	-778(ra) # 80002efe <bread>
    80004210:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004212:	000aa583          	lw	a1,0(s5)
    80004216:	028a2503          	lw	a0,40(s4)
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	ce4080e7          	jalr	-796(ra) # 80002efe <bread>
    80004222:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004224:	40000613          	li	a2,1024
    80004228:	05850593          	addi	a1,a0,88
    8000422c:	05848513          	addi	a0,s1,88
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	afa080e7          	jalr	-1286(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004238:	8526                	mv	a0,s1
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	db6080e7          	jalr	-586(ra) # 80002ff0 <bwrite>
    brelse(from);
    80004242:	854e                	mv	a0,s3
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	dea080e7          	jalr	-534(ra) # 8000302e <brelse>
    brelse(to);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	de0080e7          	jalr	-544(ra) # 8000302e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	2905                	addiw	s2,s2,1
    80004258:	0a91                	addi	s5,s5,4
    8000425a:	02ca2783          	lw	a5,44(s4)
    8000425e:	f8f94ee3          	blt	s2,a5,800041fa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004262:	00000097          	auipc	ra,0x0
    80004266:	c8c080e7          	jalr	-884(ra) # 80003eee <write_head>
    install_trans(0); // Now install writes to home locations
    8000426a:	4501                	li	a0,0
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	cec080e7          	jalr	-788(ra) # 80003f58 <install_trans>
    log.lh.n = 0;
    80004274:	0001d797          	auipc	a5,0x1d
    80004278:	9407a423          	sw	zero,-1720(a5) # 80020bbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c72080e7          	jalr	-910(ra) # 80003eee <write_head>
    80004284:	bdf5                	j	80004180 <end_op+0x52>

0000000080004286 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004286:	1101                	addi	sp,sp,-32
    80004288:	ec06                	sd	ra,24(sp)
    8000428a:	e822                	sd	s0,16(sp)
    8000428c:	e426                	sd	s1,8(sp)
    8000428e:	e04a                	sd	s2,0(sp)
    80004290:	1000                	addi	s0,sp,32
    80004292:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004294:	0001d917          	auipc	s2,0x1d
    80004298:	8fc90913          	addi	s2,s2,-1796 # 80020b90 <log>
    8000429c:	854a                	mv	a0,s2
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	934080e7          	jalr	-1740(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042a6:	02c92603          	lw	a2,44(s2)
    800042aa:	47f5                	li	a5,29
    800042ac:	06c7c563          	blt	a5,a2,80004316 <log_write+0x90>
    800042b0:	0001d797          	auipc	a5,0x1d
    800042b4:	8fc7a783          	lw	a5,-1796(a5) # 80020bac <log+0x1c>
    800042b8:	37fd                	addiw	a5,a5,-1
    800042ba:	04f65e63          	bge	a2,a5,80004316 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042be:	0001d797          	auipc	a5,0x1d
    800042c2:	8f27a783          	lw	a5,-1806(a5) # 80020bb0 <log+0x20>
    800042c6:	06f05063          	blez	a5,80004326 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ca:	4781                	li	a5,0
    800042cc:	06c05563          	blez	a2,80004336 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042d0:	44cc                	lw	a1,12(s1)
    800042d2:	0001d717          	auipc	a4,0x1d
    800042d6:	8ee70713          	addi	a4,a4,-1810 # 80020bc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042da:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042dc:	4314                	lw	a3,0(a4)
    800042de:	04b68c63          	beq	a3,a1,80004336 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	2785                	addiw	a5,a5,1
    800042e4:	0711                	addi	a4,a4,4
    800042e6:	fef61be3          	bne	a2,a5,800042dc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ea:	0621                	addi	a2,a2,8
    800042ec:	060a                	slli	a2,a2,0x2
    800042ee:	0001d797          	auipc	a5,0x1d
    800042f2:	8a278793          	addi	a5,a5,-1886 # 80020b90 <log>
    800042f6:	97b2                	add	a5,a5,a2
    800042f8:	44d8                	lw	a4,12(s1)
    800042fa:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	dcc080e7          	jalr	-564(ra) # 800030ca <bpin>
    log.lh.n++;
    80004306:	0001d717          	auipc	a4,0x1d
    8000430a:	88a70713          	addi	a4,a4,-1910 # 80020b90 <log>
    8000430e:	575c                	lw	a5,44(a4)
    80004310:	2785                	addiw	a5,a5,1
    80004312:	d75c                	sw	a5,44(a4)
    80004314:	a82d                	j	8000434e <log_write+0xc8>
    panic("too big a transaction");
    80004316:	00004517          	auipc	a0,0x4
    8000431a:	3b250513          	addi	a0,a0,946 # 800086c8 <syscalls+0x210>
    8000431e:	ffffc097          	auipc	ra,0xffffc
    80004322:	21e080e7          	jalr	542(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	3ba50513          	addi	a0,a0,954 # 800086e0 <syscalls+0x228>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	20e080e7          	jalr	526(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004336:	00878693          	addi	a3,a5,8
    8000433a:	068a                	slli	a3,a3,0x2
    8000433c:	0001d717          	auipc	a4,0x1d
    80004340:	85470713          	addi	a4,a4,-1964 # 80020b90 <log>
    80004344:	9736                	add	a4,a4,a3
    80004346:	44d4                	lw	a3,12(s1)
    80004348:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000434a:	faf609e3          	beq	a2,a5,800042fc <log_write+0x76>
  }
  release(&log.lock);
    8000434e:	0001d517          	auipc	a0,0x1d
    80004352:	84250513          	addi	a0,a0,-1982 # 80020b90 <log>
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	930080e7          	jalr	-1744(ra) # 80000c86 <release>
}
    8000435e:	60e2                	ld	ra,24(sp)
    80004360:	6442                	ld	s0,16(sp)
    80004362:	64a2                	ld	s1,8(sp)
    80004364:	6902                	ld	s2,0(sp)
    80004366:	6105                	addi	sp,sp,32
    80004368:	8082                	ret

000000008000436a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	addi	s0,sp,32
    80004376:	84aa                	mv	s1,a0
    80004378:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000437a:	00004597          	auipc	a1,0x4
    8000437e:	38658593          	addi	a1,a1,902 # 80008700 <syscalls+0x248>
    80004382:	0521                	addi	a0,a0,8
    80004384:	ffffc097          	auipc	ra,0xffffc
    80004388:	7be080e7          	jalr	1982(ra) # 80000b42 <initlock>
  lk->name = name;
    8000438c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004390:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004394:	0204a423          	sw	zero,40(s1)
}
    80004398:	60e2                	ld	ra,24(sp)
    8000439a:	6442                	ld	s0,16(sp)
    8000439c:	64a2                	ld	s1,8(sp)
    8000439e:	6902                	ld	s2,0(sp)
    800043a0:	6105                	addi	sp,sp,32
    800043a2:	8082                	ret

00000000800043a4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043a4:	1101                	addi	sp,sp,-32
    800043a6:	ec06                	sd	ra,24(sp)
    800043a8:	e822                	sd	s0,16(sp)
    800043aa:	e426                	sd	s1,8(sp)
    800043ac:	e04a                	sd	s2,0(sp)
    800043ae:	1000                	addi	s0,sp,32
    800043b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043b2:	00850913          	addi	s2,a0,8
    800043b6:	854a                	mv	a0,s2
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	81a080e7          	jalr	-2022(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800043c0:	409c                	lw	a5,0(s1)
    800043c2:	cb89                	beqz	a5,800043d4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043c4:	85ca                	mv	a1,s2
    800043c6:	8526                	mv	a0,s1
    800043c8:	ffffe097          	auipc	ra,0xffffe
    800043cc:	c86080e7          	jalr	-890(ra) # 8000204e <sleep>
  while (lk->locked) {
    800043d0:	409c                	lw	a5,0(s1)
    800043d2:	fbed                	bnez	a5,800043c4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043d4:	4785                	li	a5,1
    800043d6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	5ce080e7          	jalr	1486(ra) # 800019a6 <myproc>
    800043e0:	591c                	lw	a5,48(a0)
    800043e2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043e4:	854a                	mv	a0,s2
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8a0080e7          	jalr	-1888(ra) # 80000c86 <release>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043fa:	1101                	addi	sp,sp,-32
    800043fc:	ec06                	sd	ra,24(sp)
    800043fe:	e822                	sd	s0,16(sp)
    80004400:	e426                	sd	s1,8(sp)
    80004402:	e04a                	sd	s2,0(sp)
    80004404:	1000                	addi	s0,sp,32
    80004406:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004408:	00850913          	addi	s2,a0,8
    8000440c:	854a                	mv	a0,s2
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	7c4080e7          	jalr	1988(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004416:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000441a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffe097          	auipc	ra,0xffffe
    80004424:	c92080e7          	jalr	-878(ra) # 800020b2 <wakeup>
  release(&lk->lk);
    80004428:	854a                	mv	a0,s2
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	85c080e7          	jalr	-1956(ra) # 80000c86 <release>
}
    80004432:	60e2                	ld	ra,24(sp)
    80004434:	6442                	ld	s0,16(sp)
    80004436:	64a2                	ld	s1,8(sp)
    80004438:	6902                	ld	s2,0(sp)
    8000443a:	6105                	addi	sp,sp,32
    8000443c:	8082                	ret

000000008000443e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000443e:	7179                	addi	sp,sp,-48
    80004440:	f406                	sd	ra,40(sp)
    80004442:	f022                	sd	s0,32(sp)
    80004444:	ec26                	sd	s1,24(sp)
    80004446:	e84a                	sd	s2,16(sp)
    80004448:	e44e                	sd	s3,8(sp)
    8000444a:	1800                	addi	s0,sp,48
    8000444c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000444e:	00850913          	addi	s2,a0,8
    80004452:	854a                	mv	a0,s2
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	77e080e7          	jalr	1918(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000445c:	409c                	lw	a5,0(s1)
    8000445e:	ef99                	bnez	a5,8000447c <holdingsleep+0x3e>
    80004460:	4481                	li	s1,0
  release(&lk->lk);
    80004462:	854a                	mv	a0,s2
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	822080e7          	jalr	-2014(ra) # 80000c86 <release>
  return r;
}
    8000446c:	8526                	mv	a0,s1
    8000446e:	70a2                	ld	ra,40(sp)
    80004470:	7402                	ld	s0,32(sp)
    80004472:	64e2                	ld	s1,24(sp)
    80004474:	6942                	ld	s2,16(sp)
    80004476:	69a2                	ld	s3,8(sp)
    80004478:	6145                	addi	sp,sp,48
    8000447a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447c:	0284a983          	lw	s3,40(s1)
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	526080e7          	jalr	1318(ra) # 800019a6 <myproc>
    80004488:	5904                	lw	s1,48(a0)
    8000448a:	413484b3          	sub	s1,s1,s3
    8000448e:	0014b493          	seqz	s1,s1
    80004492:	bfc1                	j	80004462 <holdingsleep+0x24>

0000000080004494 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004494:	1141                	addi	sp,sp,-16
    80004496:	e406                	sd	ra,8(sp)
    80004498:	e022                	sd	s0,0(sp)
    8000449a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000449c:	00004597          	auipc	a1,0x4
    800044a0:	27458593          	addi	a1,a1,628 # 80008710 <syscalls+0x258>
    800044a4:	0001d517          	auipc	a0,0x1d
    800044a8:	83450513          	addi	a0,a0,-1996 # 80020cd8 <ftable>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	696080e7          	jalr	1686(ra) # 80000b42 <initlock>
}
    800044b4:	60a2                	ld	ra,8(sp)
    800044b6:	6402                	ld	s0,0(sp)
    800044b8:	0141                	addi	sp,sp,16
    800044ba:	8082                	ret

00000000800044bc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044c6:	0001d517          	auipc	a0,0x1d
    800044ca:	81250513          	addi	a0,a0,-2030 # 80020cd8 <ftable>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	704080e7          	jalr	1796(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044d6:	0001d497          	auipc	s1,0x1d
    800044da:	81a48493          	addi	s1,s1,-2022 # 80020cf0 <ftable+0x18>
    800044de:	0001d717          	auipc	a4,0x1d
    800044e2:	7b270713          	addi	a4,a4,1970 # 80021c90 <disk>
    if(f->ref == 0){
    800044e6:	40dc                	lw	a5,4(s1)
    800044e8:	cf99                	beqz	a5,80004506 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ea:	02848493          	addi	s1,s1,40
    800044ee:	fee49ce3          	bne	s1,a4,800044e6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044f2:	0001c517          	auipc	a0,0x1c
    800044f6:	7e650513          	addi	a0,a0,2022 # 80020cd8 <ftable>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	78c080e7          	jalr	1932(ra) # 80000c86 <release>
  return 0;
    80004502:	4481                	li	s1,0
    80004504:	a819                	j	8000451a <filealloc+0x5e>
      f->ref = 1;
    80004506:	4785                	li	a5,1
    80004508:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000450a:	0001c517          	auipc	a0,0x1c
    8000450e:	7ce50513          	addi	a0,a0,1998 # 80020cd8 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	774080e7          	jalr	1908(ra) # 80000c86 <release>
}
    8000451a:	8526                	mv	a0,s1
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6105                	addi	sp,sp,32
    80004524:	8082                	ret

0000000080004526 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004526:	1101                	addi	sp,sp,-32
    80004528:	ec06                	sd	ra,24(sp)
    8000452a:	e822                	sd	s0,16(sp)
    8000452c:	e426                	sd	s1,8(sp)
    8000452e:	1000                	addi	s0,sp,32
    80004530:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004532:	0001c517          	auipc	a0,0x1c
    80004536:	7a650513          	addi	a0,a0,1958 # 80020cd8 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	698080e7          	jalr	1688(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004542:	40dc                	lw	a5,4(s1)
    80004544:	02f05263          	blez	a5,80004568 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004548:	2785                	addiw	a5,a5,1
    8000454a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000454c:	0001c517          	auipc	a0,0x1c
    80004550:	78c50513          	addi	a0,a0,1932 # 80020cd8 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	732080e7          	jalr	1842(ra) # 80000c86 <release>
  return f;
}
    8000455c:	8526                	mv	a0,s1
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret
    panic("filedup");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	1b050513          	addi	a0,a0,432 # 80008718 <syscalls+0x260>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	fcc080e7          	jalr	-52(ra) # 8000053c <panic>

0000000080004578 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004578:	7139                	addi	sp,sp,-64
    8000457a:	fc06                	sd	ra,56(sp)
    8000457c:	f822                	sd	s0,48(sp)
    8000457e:	f426                	sd	s1,40(sp)
    80004580:	f04a                	sd	s2,32(sp)
    80004582:	ec4e                	sd	s3,24(sp)
    80004584:	e852                	sd	s4,16(sp)
    80004586:	e456                	sd	s5,8(sp)
    80004588:	0080                	addi	s0,sp,64
    8000458a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000458c:	0001c517          	auipc	a0,0x1c
    80004590:	74c50513          	addi	a0,a0,1868 # 80020cd8 <ftable>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	63e080e7          	jalr	1598(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000459c:	40dc                	lw	a5,4(s1)
    8000459e:	06f05163          	blez	a5,80004600 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045a2:	37fd                	addiw	a5,a5,-1
    800045a4:	0007871b          	sext.w	a4,a5
    800045a8:	c0dc                	sw	a5,4(s1)
    800045aa:	06e04363          	bgtz	a4,80004610 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ae:	0004a903          	lw	s2,0(s1)
    800045b2:	0094ca83          	lbu	s5,9(s1)
    800045b6:	0104ba03          	ld	s4,16(s1)
    800045ba:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045be:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045c2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045c6:	0001c517          	auipc	a0,0x1c
    800045ca:	71250513          	addi	a0,a0,1810 # 80020cd8 <ftable>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6b8080e7          	jalr	1720(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800045d6:	4785                	li	a5,1
    800045d8:	04f90d63          	beq	s2,a5,80004632 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045dc:	3979                	addiw	s2,s2,-2
    800045de:	4785                	li	a5,1
    800045e0:	0527e063          	bltu	a5,s2,80004620 <fileclose+0xa8>
    begin_op();
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	ad0080e7          	jalr	-1328(ra) # 800040b4 <begin_op>
    iput(ff.ip);
    800045ec:	854e                	mv	a0,s3
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	2da080e7          	jalr	730(ra) # 800038c8 <iput>
    end_op();
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	b38080e7          	jalr	-1224(ra) # 8000412e <end_op>
    800045fe:	a00d                	j	80004620 <fileclose+0xa8>
    panic("fileclose");
    80004600:	00004517          	auipc	a0,0x4
    80004604:	12050513          	addi	a0,a0,288 # 80008720 <syscalls+0x268>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	f34080e7          	jalr	-204(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004610:	0001c517          	auipc	a0,0x1c
    80004614:	6c850513          	addi	a0,a0,1736 # 80020cd8 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	66e080e7          	jalr	1646(ra) # 80000c86 <release>
  }
}
    80004620:	70e2                	ld	ra,56(sp)
    80004622:	7442                	ld	s0,48(sp)
    80004624:	74a2                	ld	s1,40(sp)
    80004626:	7902                	ld	s2,32(sp)
    80004628:	69e2                	ld	s3,24(sp)
    8000462a:	6a42                	ld	s4,16(sp)
    8000462c:	6aa2                	ld	s5,8(sp)
    8000462e:	6121                	addi	sp,sp,64
    80004630:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004632:	85d6                	mv	a1,s5
    80004634:	8552                	mv	a0,s4
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	348080e7          	jalr	840(ra) # 8000497e <pipeclose>
    8000463e:	b7cd                	j	80004620 <fileclose+0xa8>

0000000080004640 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004640:	715d                	addi	sp,sp,-80
    80004642:	e486                	sd	ra,72(sp)
    80004644:	e0a2                	sd	s0,64(sp)
    80004646:	fc26                	sd	s1,56(sp)
    80004648:	f84a                	sd	s2,48(sp)
    8000464a:	f44e                	sd	s3,40(sp)
    8000464c:	0880                	addi	s0,sp,80
    8000464e:	84aa                	mv	s1,a0
    80004650:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004652:	ffffd097          	auipc	ra,0xffffd
    80004656:	354080e7          	jalr	852(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000465a:	409c                	lw	a5,0(s1)
    8000465c:	37f9                	addiw	a5,a5,-2
    8000465e:	4705                	li	a4,1
    80004660:	04f76763          	bltu	a4,a5,800046ae <filestat+0x6e>
    80004664:	892a                	mv	s2,a0
    ilock(f->ip);
    80004666:	6c88                	ld	a0,24(s1)
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	0a6080e7          	jalr	166(ra) # 8000370e <ilock>
    stati(f->ip, &st);
    80004670:	fb840593          	addi	a1,s0,-72
    80004674:	6c88                	ld	a0,24(s1)
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	322080e7          	jalr	802(ra) # 80003998 <stati>
    iunlock(f->ip);
    8000467e:	6c88                	ld	a0,24(s1)
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	150080e7          	jalr	336(ra) # 800037d0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004688:	46e1                	li	a3,24
    8000468a:	fb840613          	addi	a2,s0,-72
    8000468e:	85ce                	mv	a1,s3
    80004690:	05093503          	ld	a0,80(s2)
    80004694:	ffffd097          	auipc	ra,0xffffd
    80004698:	fd2080e7          	jalr	-46(ra) # 80001666 <copyout>
    8000469c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a0:	60a6                	ld	ra,72(sp)
    800046a2:	6406                	ld	s0,64(sp)
    800046a4:	74e2                	ld	s1,56(sp)
    800046a6:	7942                	ld	s2,48(sp)
    800046a8:	79a2                	ld	s3,40(sp)
    800046aa:	6161                	addi	sp,sp,80
    800046ac:	8082                	ret
  return -1;
    800046ae:	557d                	li	a0,-1
    800046b0:	bfc5                	j	800046a0 <filestat+0x60>

00000000800046b2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046b2:	7179                	addi	sp,sp,-48
    800046b4:	f406                	sd	ra,40(sp)
    800046b6:	f022                	sd	s0,32(sp)
    800046b8:	ec26                	sd	s1,24(sp)
    800046ba:	e84a                	sd	s2,16(sp)
    800046bc:	e44e                	sd	s3,8(sp)
    800046be:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c0:	00854783          	lbu	a5,8(a0)
    800046c4:	c3d5                	beqz	a5,80004768 <fileread+0xb6>
    800046c6:	84aa                	mv	s1,a0
    800046c8:	89ae                	mv	s3,a1
    800046ca:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046cc:	411c                	lw	a5,0(a0)
    800046ce:	4705                	li	a4,1
    800046d0:	04e78963          	beq	a5,a4,80004722 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d4:	470d                	li	a4,3
    800046d6:	04e78d63          	beq	a5,a4,80004730 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046da:	4709                	li	a4,2
    800046dc:	06e79e63          	bne	a5,a4,80004758 <fileread+0xa6>
    ilock(f->ip);
    800046e0:	6d08                	ld	a0,24(a0)
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	02c080e7          	jalr	44(ra) # 8000370e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ea:	874a                	mv	a4,s2
    800046ec:	5094                	lw	a3,32(s1)
    800046ee:	864e                	mv	a2,s3
    800046f0:	4585                	li	a1,1
    800046f2:	6c88                	ld	a0,24(s1)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	2ce080e7          	jalr	718(ra) # 800039c2 <readi>
    800046fc:	892a                	mv	s2,a0
    800046fe:	00a05563          	blez	a0,80004708 <fileread+0x56>
      f->off += r;
    80004702:	509c                	lw	a5,32(s1)
    80004704:	9fa9                	addw	a5,a5,a0
    80004706:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	0c6080e7          	jalr	198(ra) # 800037d0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004712:	854a                	mv	a0,s2
    80004714:	70a2                	ld	ra,40(sp)
    80004716:	7402                	ld	s0,32(sp)
    80004718:	64e2                	ld	s1,24(sp)
    8000471a:	6942                	ld	s2,16(sp)
    8000471c:	69a2                	ld	s3,8(sp)
    8000471e:	6145                	addi	sp,sp,48
    80004720:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004722:	6908                	ld	a0,16(a0)
    80004724:	00000097          	auipc	ra,0x0
    80004728:	3c2080e7          	jalr	962(ra) # 80004ae6 <piperead>
    8000472c:	892a                	mv	s2,a0
    8000472e:	b7d5                	j	80004712 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004730:	02451783          	lh	a5,36(a0)
    80004734:	03079693          	slli	a3,a5,0x30
    80004738:	92c1                	srli	a3,a3,0x30
    8000473a:	4725                	li	a4,9
    8000473c:	02d76863          	bltu	a4,a3,8000476c <fileread+0xba>
    80004740:	0792                	slli	a5,a5,0x4
    80004742:	0001c717          	auipc	a4,0x1c
    80004746:	4f670713          	addi	a4,a4,1270 # 80020c38 <devsw>
    8000474a:	97ba                	add	a5,a5,a4
    8000474c:	639c                	ld	a5,0(a5)
    8000474e:	c38d                	beqz	a5,80004770 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004750:	4505                	li	a0,1
    80004752:	9782                	jalr	a5
    80004754:	892a                	mv	s2,a0
    80004756:	bf75                	j	80004712 <fileread+0x60>
    panic("fileread");
    80004758:	00004517          	auipc	a0,0x4
    8000475c:	fd850513          	addi	a0,a0,-40 # 80008730 <syscalls+0x278>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	ddc080e7          	jalr	-548(ra) # 8000053c <panic>
    return -1;
    80004768:	597d                	li	s2,-1
    8000476a:	b765                	j	80004712 <fileread+0x60>
      return -1;
    8000476c:	597d                	li	s2,-1
    8000476e:	b755                	j	80004712 <fileread+0x60>
    80004770:	597d                	li	s2,-1
    80004772:	b745                	j	80004712 <fileread+0x60>

0000000080004774 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004774:	00954783          	lbu	a5,9(a0)
    80004778:	10078e63          	beqz	a5,80004894 <filewrite+0x120>
{
    8000477c:	715d                	addi	sp,sp,-80
    8000477e:	e486                	sd	ra,72(sp)
    80004780:	e0a2                	sd	s0,64(sp)
    80004782:	fc26                	sd	s1,56(sp)
    80004784:	f84a                	sd	s2,48(sp)
    80004786:	f44e                	sd	s3,40(sp)
    80004788:	f052                	sd	s4,32(sp)
    8000478a:	ec56                	sd	s5,24(sp)
    8000478c:	e85a                	sd	s6,16(sp)
    8000478e:	e45e                	sd	s7,8(sp)
    80004790:	e062                	sd	s8,0(sp)
    80004792:	0880                	addi	s0,sp,80
    80004794:	892a                	mv	s2,a0
    80004796:	8b2e                	mv	s6,a1
    80004798:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479a:	411c                	lw	a5,0(a0)
    8000479c:	4705                	li	a4,1
    8000479e:	02e78263          	beq	a5,a4,800047c2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a2:	470d                	li	a4,3
    800047a4:	02e78563          	beq	a5,a4,800047ce <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a8:	4709                	li	a4,2
    800047aa:	0ce79d63          	bne	a5,a4,80004884 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ae:	0ac05b63          	blez	a2,80004864 <filewrite+0xf0>
    int i = 0;
    800047b2:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047b4:	6b85                	lui	s7,0x1
    800047b6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047ba:	6c05                	lui	s8,0x1
    800047bc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047c0:	a851                	j	80004854 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047c2:	6908                	ld	a0,16(a0)
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	22a080e7          	jalr	554(ra) # 800049ee <pipewrite>
    800047cc:	a045                	j	8000486c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047ce:	02451783          	lh	a5,36(a0)
    800047d2:	03079693          	slli	a3,a5,0x30
    800047d6:	92c1                	srli	a3,a3,0x30
    800047d8:	4725                	li	a4,9
    800047da:	0ad76f63          	bltu	a4,a3,80004898 <filewrite+0x124>
    800047de:	0792                	slli	a5,a5,0x4
    800047e0:	0001c717          	auipc	a4,0x1c
    800047e4:	45870713          	addi	a4,a4,1112 # 80020c38 <devsw>
    800047e8:	97ba                	add	a5,a5,a4
    800047ea:	679c                	ld	a5,8(a5)
    800047ec:	cbc5                	beqz	a5,8000489c <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800047ee:	4505                	li	a0,1
    800047f0:	9782                	jalr	a5
    800047f2:	a8ad                	j	8000486c <filewrite+0xf8>
      if(n1 > max)
    800047f4:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	8bc080e7          	jalr	-1860(ra) # 800040b4 <begin_op>
      ilock(f->ip);
    80004800:	01893503          	ld	a0,24(s2)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	f0a080e7          	jalr	-246(ra) # 8000370e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000480c:	8756                	mv	a4,s5
    8000480e:	02092683          	lw	a3,32(s2)
    80004812:	01698633          	add	a2,s3,s6
    80004816:	4585                	li	a1,1
    80004818:	01893503          	ld	a0,24(s2)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	29e080e7          	jalr	670(ra) # 80003aba <writei>
    80004824:	84aa                	mv	s1,a0
    80004826:	00a05763          	blez	a0,80004834 <filewrite+0xc0>
        f->off += r;
    8000482a:	02092783          	lw	a5,32(s2)
    8000482e:	9fa9                	addw	a5,a5,a0
    80004830:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004834:	01893503          	ld	a0,24(s2)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	f98080e7          	jalr	-104(ra) # 800037d0 <iunlock>
      end_op();
    80004840:	00000097          	auipc	ra,0x0
    80004844:	8ee080e7          	jalr	-1810(ra) # 8000412e <end_op>

      if(r != n1){
    80004848:	009a9f63          	bne	s5,s1,80004866 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    8000484c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004850:	0149db63          	bge	s3,s4,80004866 <filewrite+0xf2>
      int n1 = n - i;
    80004854:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004858:	0004879b          	sext.w	a5,s1
    8000485c:	f8fbdce3          	bge	s7,a5,800047f4 <filewrite+0x80>
    80004860:	84e2                	mv	s1,s8
    80004862:	bf49                	j	800047f4 <filewrite+0x80>
    int i = 0;
    80004864:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004866:	033a1d63          	bne	s4,s3,800048a0 <filewrite+0x12c>
    8000486a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000486c:	60a6                	ld	ra,72(sp)
    8000486e:	6406                	ld	s0,64(sp)
    80004870:	74e2                	ld	s1,56(sp)
    80004872:	7942                	ld	s2,48(sp)
    80004874:	79a2                	ld	s3,40(sp)
    80004876:	7a02                	ld	s4,32(sp)
    80004878:	6ae2                	ld	s5,24(sp)
    8000487a:	6b42                	ld	s6,16(sp)
    8000487c:	6ba2                	ld	s7,8(sp)
    8000487e:	6c02                	ld	s8,0(sp)
    80004880:	6161                	addi	sp,sp,80
    80004882:	8082                	ret
    panic("filewrite");
    80004884:	00004517          	auipc	a0,0x4
    80004888:	ebc50513          	addi	a0,a0,-324 # 80008740 <syscalls+0x288>
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	cb0080e7          	jalr	-848(ra) # 8000053c <panic>
    return -1;
    80004894:	557d                	li	a0,-1
}
    80004896:	8082                	ret
      return -1;
    80004898:	557d                	li	a0,-1
    8000489a:	bfc9                	j	8000486c <filewrite+0xf8>
    8000489c:	557d                	li	a0,-1
    8000489e:	b7f9                	j	8000486c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048a0:	557d                	li	a0,-1
    800048a2:	b7e9                	j	8000486c <filewrite+0xf8>

00000000800048a4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048a4:	7179                	addi	sp,sp,-48
    800048a6:	f406                	sd	ra,40(sp)
    800048a8:	f022                	sd	s0,32(sp)
    800048aa:	ec26                	sd	s1,24(sp)
    800048ac:	e84a                	sd	s2,16(sp)
    800048ae:	e44e                	sd	s3,8(sp)
    800048b0:	e052                	sd	s4,0(sp)
    800048b2:	1800                	addi	s0,sp,48
    800048b4:	84aa                	mv	s1,a0
    800048b6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048b8:	0005b023          	sd	zero,0(a1)
    800048bc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	bfc080e7          	jalr	-1028(ra) # 800044bc <filealloc>
    800048c8:	e088                	sd	a0,0(s1)
    800048ca:	c551                	beqz	a0,80004956 <pipealloc+0xb2>
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	bf0080e7          	jalr	-1040(ra) # 800044bc <filealloc>
    800048d4:	00aa3023          	sd	a0,0(s4)
    800048d8:	c92d                	beqz	a0,8000494a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	208080e7          	jalr	520(ra) # 80000ae2 <kalloc>
    800048e2:	892a                	mv	s2,a0
    800048e4:	c125                	beqz	a0,80004944 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048e6:	4985                	li	s3,1
    800048e8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048f0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048f4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048f8:	00004597          	auipc	a1,0x4
    800048fc:	e5858593          	addi	a1,a1,-424 # 80008750 <syscalls+0x298>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	242080e7          	jalr	578(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004908:	609c                	ld	a5,0(s1)
    8000490a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000490e:	609c                	ld	a5,0(s1)
    80004910:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004914:	609c                	ld	a5,0(s1)
    80004916:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000491a:	609c                	ld	a5,0(s1)
    8000491c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004920:	000a3783          	ld	a5,0(s4)
    80004924:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004928:	000a3783          	ld	a5,0(s4)
    8000492c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004930:	000a3783          	ld	a5,0(s4)
    80004934:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004938:	000a3783          	ld	a5,0(s4)
    8000493c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004940:	4501                	li	a0,0
    80004942:	a025                	j	8000496a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004944:	6088                	ld	a0,0(s1)
    80004946:	e501                	bnez	a0,8000494e <pipealloc+0xaa>
    80004948:	a039                	j	80004956 <pipealloc+0xb2>
    8000494a:	6088                	ld	a0,0(s1)
    8000494c:	c51d                	beqz	a0,8000497a <pipealloc+0xd6>
    fileclose(*f0);
    8000494e:	00000097          	auipc	ra,0x0
    80004952:	c2a080e7          	jalr	-982(ra) # 80004578 <fileclose>
  if(*f1)
    80004956:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000495a:	557d                	li	a0,-1
  if(*f1)
    8000495c:	c799                	beqz	a5,8000496a <pipealloc+0xc6>
    fileclose(*f1);
    8000495e:	853e                	mv	a0,a5
    80004960:	00000097          	auipc	ra,0x0
    80004964:	c18080e7          	jalr	-1000(ra) # 80004578 <fileclose>
  return -1;
    80004968:	557d                	li	a0,-1
}
    8000496a:	70a2                	ld	ra,40(sp)
    8000496c:	7402                	ld	s0,32(sp)
    8000496e:	64e2                	ld	s1,24(sp)
    80004970:	6942                	ld	s2,16(sp)
    80004972:	69a2                	ld	s3,8(sp)
    80004974:	6a02                	ld	s4,0(sp)
    80004976:	6145                	addi	sp,sp,48
    80004978:	8082                	ret
  return -1;
    8000497a:	557d                	li	a0,-1
    8000497c:	b7fd                	j	8000496a <pipealloc+0xc6>

000000008000497e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000497e:	1101                	addi	sp,sp,-32
    80004980:	ec06                	sd	ra,24(sp)
    80004982:	e822                	sd	s0,16(sp)
    80004984:	e426                	sd	s1,8(sp)
    80004986:	e04a                	sd	s2,0(sp)
    80004988:	1000                	addi	s0,sp,32
    8000498a:	84aa                	mv	s1,a0
    8000498c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	244080e7          	jalr	580(ra) # 80000bd2 <acquire>
  if(writable){
    80004996:	02090d63          	beqz	s2,800049d0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000499a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000499e:	21848513          	addi	a0,s1,536
    800049a2:	ffffd097          	auipc	ra,0xffffd
    800049a6:	710080e7          	jalr	1808(ra) # 800020b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049aa:	2204b783          	ld	a5,544(s1)
    800049ae:	eb95                	bnez	a5,800049e2 <pipeclose+0x64>
    release(&pi->lock);
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	2d4080e7          	jalr	724(ra) # 80000c86 <release>
    kfree((char*)pi);
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	028080e7          	jalr	40(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    800049c4:	60e2                	ld	ra,24(sp)
    800049c6:	6442                	ld	s0,16(sp)
    800049c8:	64a2                	ld	s1,8(sp)
    800049ca:	6902                	ld	s2,0(sp)
    800049cc:	6105                	addi	sp,sp,32
    800049ce:	8082                	ret
    pi->readopen = 0;
    800049d0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049d4:	21c48513          	addi	a0,s1,540
    800049d8:	ffffd097          	auipc	ra,0xffffd
    800049dc:	6da080e7          	jalr	1754(ra) # 800020b2 <wakeup>
    800049e0:	b7e9                	j	800049aa <pipeclose+0x2c>
    release(&pi->lock);
    800049e2:	8526                	mv	a0,s1
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	2a2080e7          	jalr	674(ra) # 80000c86 <release>
}
    800049ec:	bfe1                	j	800049c4 <pipeclose+0x46>

00000000800049ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049ee:	711d                	addi	sp,sp,-96
    800049f0:	ec86                	sd	ra,88(sp)
    800049f2:	e8a2                	sd	s0,80(sp)
    800049f4:	e4a6                	sd	s1,72(sp)
    800049f6:	e0ca                	sd	s2,64(sp)
    800049f8:	fc4e                	sd	s3,56(sp)
    800049fa:	f852                	sd	s4,48(sp)
    800049fc:	f456                	sd	s5,40(sp)
    800049fe:	f05a                	sd	s6,32(sp)
    80004a00:	ec5e                	sd	s7,24(sp)
    80004a02:	e862                	sd	s8,16(sp)
    80004a04:	1080                	addi	s0,sp,96
    80004a06:	84aa                	mv	s1,a0
    80004a08:	8aae                	mv	s5,a1
    80004a0a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a0c:	ffffd097          	auipc	ra,0xffffd
    80004a10:	f9a080e7          	jalr	-102(ra) # 800019a6 <myproc>
    80004a14:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	1ba080e7          	jalr	442(ra) # 80000bd2 <acquire>
  while(i < n){
    80004a20:	0b405663          	blez	s4,80004acc <pipewrite+0xde>
  int i = 0;
    80004a24:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a26:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a28:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a2c:	21c48b93          	addi	s7,s1,540
    80004a30:	a089                	j	80004a72 <pipewrite+0x84>
      release(&pi->lock);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	252080e7          	jalr	594(ra) # 80000c86 <release>
      return -1;
    80004a3c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a3e:	854a                	mv	a0,s2
    80004a40:	60e6                	ld	ra,88(sp)
    80004a42:	6446                	ld	s0,80(sp)
    80004a44:	64a6                	ld	s1,72(sp)
    80004a46:	6906                	ld	s2,64(sp)
    80004a48:	79e2                	ld	s3,56(sp)
    80004a4a:	7a42                	ld	s4,48(sp)
    80004a4c:	7aa2                	ld	s5,40(sp)
    80004a4e:	7b02                	ld	s6,32(sp)
    80004a50:	6be2                	ld	s7,24(sp)
    80004a52:	6c42                	ld	s8,16(sp)
    80004a54:	6125                	addi	sp,sp,96
    80004a56:	8082                	ret
      wakeup(&pi->nread);
    80004a58:	8562                	mv	a0,s8
    80004a5a:	ffffd097          	auipc	ra,0xffffd
    80004a5e:	658080e7          	jalr	1624(ra) # 800020b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a62:	85a6                	mv	a1,s1
    80004a64:	855e                	mv	a0,s7
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	5e8080e7          	jalr	1512(ra) # 8000204e <sleep>
  while(i < n){
    80004a6e:	07495063          	bge	s2,s4,80004ace <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a72:	2204a783          	lw	a5,544(s1)
    80004a76:	dfd5                	beqz	a5,80004a32 <pipewrite+0x44>
    80004a78:	854e                	mv	a0,s3
    80004a7a:	ffffe097          	auipc	ra,0xffffe
    80004a7e:	87c080e7          	jalr	-1924(ra) # 800022f6 <killed>
    80004a82:	f945                	bnez	a0,80004a32 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a84:	2184a783          	lw	a5,536(s1)
    80004a88:	21c4a703          	lw	a4,540(s1)
    80004a8c:	2007879b          	addiw	a5,a5,512
    80004a90:	fcf704e3          	beq	a4,a5,80004a58 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a94:	4685                	li	a3,1
    80004a96:	01590633          	add	a2,s2,s5
    80004a9a:	faf40593          	addi	a1,s0,-81
    80004a9e:	0509b503          	ld	a0,80(s3)
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	c50080e7          	jalr	-944(ra) # 800016f2 <copyin>
    80004aaa:	03650263          	beq	a0,s6,80004ace <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aae:	21c4a783          	lw	a5,540(s1)
    80004ab2:	0017871b          	addiw	a4,a5,1
    80004ab6:	20e4ae23          	sw	a4,540(s1)
    80004aba:	1ff7f793          	andi	a5,a5,511
    80004abe:	97a6                	add	a5,a5,s1
    80004ac0:	faf44703          	lbu	a4,-81(s0)
    80004ac4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ac8:	2905                	addiw	s2,s2,1
    80004aca:	b755                	j	80004a6e <pipewrite+0x80>
  int i = 0;
    80004acc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ace:	21848513          	addi	a0,s1,536
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	5e0080e7          	jalr	1504(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004ada:	8526                	mv	a0,s1
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1aa080e7          	jalr	426(ra) # 80000c86 <release>
  return i;
    80004ae4:	bfa9                	j	80004a3e <pipewrite+0x50>

0000000080004ae6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ae6:	715d                	addi	sp,sp,-80
    80004ae8:	e486                	sd	ra,72(sp)
    80004aea:	e0a2                	sd	s0,64(sp)
    80004aec:	fc26                	sd	s1,56(sp)
    80004aee:	f84a                	sd	s2,48(sp)
    80004af0:	f44e                	sd	s3,40(sp)
    80004af2:	f052                	sd	s4,32(sp)
    80004af4:	ec56                	sd	s5,24(sp)
    80004af6:	e85a                	sd	s6,16(sp)
    80004af8:	0880                	addi	s0,sp,80
    80004afa:	84aa                	mv	s1,a0
    80004afc:	892e                	mv	s2,a1
    80004afe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	ea6080e7          	jalr	-346(ra) # 800019a6 <myproc>
    80004b08:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	0c6080e7          	jalr	198(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b14:	2184a703          	lw	a4,536(s1)
    80004b18:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b1c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b20:	02f71763          	bne	a4,a5,80004b4e <piperead+0x68>
    80004b24:	2244a783          	lw	a5,548(s1)
    80004b28:	c39d                	beqz	a5,80004b4e <piperead+0x68>
    if(killed(pr)){
    80004b2a:	8552                	mv	a0,s4
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	7ca080e7          	jalr	1994(ra) # 800022f6 <killed>
    80004b34:	e949                	bnez	a0,80004bc6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b36:	85a6                	mv	a1,s1
    80004b38:	854e                	mv	a0,s3
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	514080e7          	jalr	1300(ra) # 8000204e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b42:	2184a703          	lw	a4,536(s1)
    80004b46:	21c4a783          	lw	a5,540(s1)
    80004b4a:	fcf70de3          	beq	a4,a5,80004b24 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b4e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b50:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b52:	05505463          	blez	s5,80004b9a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b56:	2184a783          	lw	a5,536(s1)
    80004b5a:	21c4a703          	lw	a4,540(s1)
    80004b5e:	02f70e63          	beq	a4,a5,80004b9a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b62:	0017871b          	addiw	a4,a5,1
    80004b66:	20e4ac23          	sw	a4,536(s1)
    80004b6a:	1ff7f793          	andi	a5,a5,511
    80004b6e:	97a6                	add	a5,a5,s1
    80004b70:	0187c783          	lbu	a5,24(a5)
    80004b74:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b78:	4685                	li	a3,1
    80004b7a:	fbf40613          	addi	a2,s0,-65
    80004b7e:	85ca                	mv	a1,s2
    80004b80:	050a3503          	ld	a0,80(s4)
    80004b84:	ffffd097          	auipc	ra,0xffffd
    80004b88:	ae2080e7          	jalr	-1310(ra) # 80001666 <copyout>
    80004b8c:	01650763          	beq	a0,s6,80004b9a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b90:	2985                	addiw	s3,s3,1
    80004b92:	0905                	addi	s2,s2,1
    80004b94:	fd3a91e3          	bne	s5,s3,80004b56 <piperead+0x70>
    80004b98:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b9a:	21c48513          	addi	a0,s1,540
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	514080e7          	jalr	1300(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	0de080e7          	jalr	222(ra) # 80000c86 <release>
  return i;
}
    80004bb0:	854e                	mv	a0,s3
    80004bb2:	60a6                	ld	ra,72(sp)
    80004bb4:	6406                	ld	s0,64(sp)
    80004bb6:	74e2                	ld	s1,56(sp)
    80004bb8:	7942                	ld	s2,48(sp)
    80004bba:	79a2                	ld	s3,40(sp)
    80004bbc:	7a02                	ld	s4,32(sp)
    80004bbe:	6ae2                	ld	s5,24(sp)
    80004bc0:	6b42                	ld	s6,16(sp)
    80004bc2:	6161                	addi	sp,sp,80
    80004bc4:	8082                	ret
      release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0be080e7          	jalr	190(ra) # 80000c86 <release>
      return -1;
    80004bd0:	59fd                	li	s3,-1
    80004bd2:	bff9                	j	80004bb0 <piperead+0xca>

0000000080004bd4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bd4:	1141                	addi	sp,sp,-16
    80004bd6:	e422                	sd	s0,8(sp)
    80004bd8:	0800                	addi	s0,sp,16
    80004bda:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bdc:	8905                	andi	a0,a0,1
    80004bde:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004be0:	8b89                	andi	a5,a5,2
    80004be2:	c399                	beqz	a5,80004be8 <flags2perm+0x14>
      perm |= PTE_W;
    80004be4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004be8:	6422                	ld	s0,8(sp)
    80004bea:	0141                	addi	sp,sp,16
    80004bec:	8082                	ret

0000000080004bee <exec>:

int
exec(char *path, char **argv)
{
    80004bee:	df010113          	addi	sp,sp,-528
    80004bf2:	20113423          	sd	ra,520(sp)
    80004bf6:	20813023          	sd	s0,512(sp)
    80004bfa:	ffa6                	sd	s1,504(sp)
    80004bfc:	fbca                	sd	s2,496(sp)
    80004bfe:	f7ce                	sd	s3,488(sp)
    80004c00:	f3d2                	sd	s4,480(sp)
    80004c02:	efd6                	sd	s5,472(sp)
    80004c04:	ebda                	sd	s6,464(sp)
    80004c06:	e7de                	sd	s7,456(sp)
    80004c08:	e3e2                	sd	s8,448(sp)
    80004c0a:	ff66                	sd	s9,440(sp)
    80004c0c:	fb6a                	sd	s10,432(sp)
    80004c0e:	f76e                	sd	s11,424(sp)
    80004c10:	0c00                	addi	s0,sp,528
    80004c12:	892a                	mv	s2,a0
    80004c14:	dea43c23          	sd	a0,-520(s0)
    80004c18:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	d8a080e7          	jalr	-630(ra) # 800019a6 <myproc>
    80004c24:	84aa                	mv	s1,a0

  begin_op();
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	48e080e7          	jalr	1166(ra) # 800040b4 <begin_op>

  if((ip = namei(path)) == 0){
    80004c2e:	854a                	mv	a0,s2
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	284080e7          	jalr	644(ra) # 80003eb4 <namei>
    80004c38:	c92d                	beqz	a0,80004caa <exec+0xbc>
    80004c3a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	ad2080e7          	jalr	-1326(ra) # 8000370e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c44:	04000713          	li	a4,64
    80004c48:	4681                	li	a3,0
    80004c4a:	e5040613          	addi	a2,s0,-432
    80004c4e:	4581                	li	a1,0
    80004c50:	8552                	mv	a0,s4
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	d70080e7          	jalr	-656(ra) # 800039c2 <readi>
    80004c5a:	04000793          	li	a5,64
    80004c5e:	00f51a63          	bne	a0,a5,80004c72 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c62:	e5042703          	lw	a4,-432(s0)
    80004c66:	464c47b7          	lui	a5,0x464c4
    80004c6a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c6e:	04f70463          	beq	a4,a5,80004cb6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c72:	8552                	mv	a0,s4
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	cfc080e7          	jalr	-772(ra) # 80003970 <iunlockput>
    end_op();
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	4b2080e7          	jalr	1202(ra) # 8000412e <end_op>
  }
  return -1;
    80004c84:	557d                	li	a0,-1
}
    80004c86:	20813083          	ld	ra,520(sp)
    80004c8a:	20013403          	ld	s0,512(sp)
    80004c8e:	74fe                	ld	s1,504(sp)
    80004c90:	795e                	ld	s2,496(sp)
    80004c92:	79be                	ld	s3,488(sp)
    80004c94:	7a1e                	ld	s4,480(sp)
    80004c96:	6afe                	ld	s5,472(sp)
    80004c98:	6b5e                	ld	s6,464(sp)
    80004c9a:	6bbe                	ld	s7,456(sp)
    80004c9c:	6c1e                	ld	s8,448(sp)
    80004c9e:	7cfa                	ld	s9,440(sp)
    80004ca0:	7d5a                	ld	s10,432(sp)
    80004ca2:	7dba                	ld	s11,424(sp)
    80004ca4:	21010113          	addi	sp,sp,528
    80004ca8:	8082                	ret
    end_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	484080e7          	jalr	1156(ra) # 8000412e <end_op>
    return -1;
    80004cb2:	557d                	li	a0,-1
    80004cb4:	bfc9                	j	80004c86 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	db2080e7          	jalr	-590(ra) # 80001a6a <proc_pagetable>
    80004cc0:	8b2a                	mv	s6,a0
    80004cc2:	d945                	beqz	a0,80004c72 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc4:	e7042d03          	lw	s10,-400(s0)
    80004cc8:	e8845783          	lhu	a5,-376(s0)
    80004ccc:	10078463          	beqz	a5,80004dd4 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cd0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cd4:	6c85                	lui	s9,0x1
    80004cd6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cda:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004cde:	6a85                	lui	s5,0x1
    80004ce0:	a0b5                	j	80004d4c <exec+0x15e>
      panic("loadseg: address should exist");
    80004ce2:	00004517          	auipc	a0,0x4
    80004ce6:	a7650513          	addi	a0,a0,-1418 # 80008758 <syscalls+0x2a0>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	852080e7          	jalr	-1966(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004cf2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cf4:	8726                	mv	a4,s1
    80004cf6:	012c06bb          	addw	a3,s8,s2
    80004cfa:	4581                	li	a1,0
    80004cfc:	8552                	mv	a0,s4
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	cc4080e7          	jalr	-828(ra) # 800039c2 <readi>
    80004d06:	2501                	sext.w	a0,a0
    80004d08:	24a49863          	bne	s1,a0,80004f58 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004d0c:	012a893b          	addw	s2,s5,s2
    80004d10:	03397563          	bgeu	s2,s3,80004d3a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d14:	02091593          	slli	a1,s2,0x20
    80004d18:	9181                	srli	a1,a1,0x20
    80004d1a:	95de                	add	a1,a1,s7
    80004d1c:	855a                	mv	a0,s6
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	338080e7          	jalr	824(ra) # 80001056 <walkaddr>
    80004d26:	862a                	mv	a2,a0
    if(pa == 0)
    80004d28:	dd4d                	beqz	a0,80004ce2 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d2a:	412984bb          	subw	s1,s3,s2
    80004d2e:	0004879b          	sext.w	a5,s1
    80004d32:	fcfcf0e3          	bgeu	s9,a5,80004cf2 <exec+0x104>
    80004d36:	84d6                	mv	s1,s5
    80004d38:	bf6d                	j	80004cf2 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d3a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d3e:	2d85                	addiw	s11,s11,1
    80004d40:	038d0d1b          	addiw	s10,s10,56
    80004d44:	e8845783          	lhu	a5,-376(s0)
    80004d48:	08fdd763          	bge	s11,a5,80004dd6 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d4c:	2d01                	sext.w	s10,s10
    80004d4e:	03800713          	li	a4,56
    80004d52:	86ea                	mv	a3,s10
    80004d54:	e1840613          	addi	a2,s0,-488
    80004d58:	4581                	li	a1,0
    80004d5a:	8552                	mv	a0,s4
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	c66080e7          	jalr	-922(ra) # 800039c2 <readi>
    80004d64:	03800793          	li	a5,56
    80004d68:	1ef51663          	bne	a0,a5,80004f54 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004d6c:	e1842783          	lw	a5,-488(s0)
    80004d70:	4705                	li	a4,1
    80004d72:	fce796e3          	bne	a5,a4,80004d3e <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004d76:	e4043483          	ld	s1,-448(s0)
    80004d7a:	e3843783          	ld	a5,-456(s0)
    80004d7e:	1ef4e863          	bltu	s1,a5,80004f6e <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004d82:	e2843783          	ld	a5,-472(s0)
    80004d86:	94be                	add	s1,s1,a5
    80004d88:	1ef4e663          	bltu	s1,a5,80004f74 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004d8c:	df043703          	ld	a4,-528(s0)
    80004d90:	8ff9                	and	a5,a5,a4
    80004d92:	1e079463          	bnez	a5,80004f7a <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d96:	e1c42503          	lw	a0,-484(s0)
    80004d9a:	00000097          	auipc	ra,0x0
    80004d9e:	e3a080e7          	jalr	-454(ra) # 80004bd4 <flags2perm>
    80004da2:	86aa                	mv	a3,a0
    80004da4:	8626                	mv	a2,s1
    80004da6:	85ca                	mv	a1,s2
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	660080e7          	jalr	1632(ra) # 8000140a <uvmalloc>
    80004db2:	e0a43423          	sd	a0,-504(s0)
    80004db6:	1c050563          	beqz	a0,80004f80 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dba:	e2843b83          	ld	s7,-472(s0)
    80004dbe:	e2042c03          	lw	s8,-480(s0)
    80004dc2:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004dc6:	00098463          	beqz	s3,80004dce <exec+0x1e0>
    80004dca:	4901                	li	s2,0
    80004dcc:	b7a1                	j	80004d14 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dce:	e0843903          	ld	s2,-504(s0)
    80004dd2:	b7b5                	j	80004d3e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dd4:	4901                	li	s2,0
  iunlockput(ip);
    80004dd6:	8552                	mv	a0,s4
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	b98080e7          	jalr	-1128(ra) # 80003970 <iunlockput>
  end_op();
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	34e080e7          	jalr	846(ra) # 8000412e <end_op>
  p = myproc();
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	bbe080e7          	jalr	-1090(ra) # 800019a6 <myproc>
    80004df0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004df6:	6985                	lui	s3,0x1
    80004df8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004dfa:	99ca                	add	s3,s3,s2
    80004dfc:	77fd                	lui	a5,0xfffff
    80004dfe:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e02:	4691                	li	a3,4
    80004e04:	6609                	lui	a2,0x2
    80004e06:	964e                	add	a2,a2,s3
    80004e08:	85ce                	mv	a1,s3
    80004e0a:	855a                	mv	a0,s6
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	5fe080e7          	jalr	1534(ra) # 8000140a <uvmalloc>
    80004e14:	892a                	mv	s2,a0
    80004e16:	e0a43423          	sd	a0,-504(s0)
    80004e1a:	e509                	bnez	a0,80004e24 <exec+0x236>
  if(pagetable)
    80004e1c:	e1343423          	sd	s3,-504(s0)
    80004e20:	4a01                	li	s4,0
    80004e22:	aa1d                	j	80004f58 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e24:	75f9                	lui	a1,0xffffe
    80004e26:	95aa                	add	a1,a1,a0
    80004e28:	855a                	mv	a0,s6
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	80a080e7          	jalr	-2038(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e32:	7bfd                	lui	s7,0xfffff
    80004e34:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e36:	e0043783          	ld	a5,-512(s0)
    80004e3a:	6388                	ld	a0,0(a5)
    80004e3c:	c52d                	beqz	a0,80004ea6 <exec+0x2b8>
    80004e3e:	e9040993          	addi	s3,s0,-368
    80004e42:	f9040c13          	addi	s8,s0,-112
    80004e46:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	000080e7          	jalr	ra # 80000e48 <strlen>
    80004e50:	0015079b          	addiw	a5,a0,1
    80004e54:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e58:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e5c:	13796563          	bltu	s2,s7,80004f86 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e60:	e0043d03          	ld	s10,-512(s0)
    80004e64:	000d3a03          	ld	s4,0(s10)
    80004e68:	8552                	mv	a0,s4
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	fde080e7          	jalr	-34(ra) # 80000e48 <strlen>
    80004e72:	0015069b          	addiw	a3,a0,1
    80004e76:	8652                	mv	a2,s4
    80004e78:	85ca                	mv	a1,s2
    80004e7a:	855a                	mv	a0,s6
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	7ea080e7          	jalr	2026(ra) # 80001666 <copyout>
    80004e84:	10054363          	bltz	a0,80004f8a <exec+0x39c>
    ustack[argc] = sp;
    80004e88:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e8c:	0485                	addi	s1,s1,1
    80004e8e:	008d0793          	addi	a5,s10,8
    80004e92:	e0f43023          	sd	a5,-512(s0)
    80004e96:	008d3503          	ld	a0,8(s10)
    80004e9a:	c909                	beqz	a0,80004eac <exec+0x2be>
    if(argc >= MAXARG)
    80004e9c:	09a1                	addi	s3,s3,8
    80004e9e:	fb8995e3          	bne	s3,s8,80004e48 <exec+0x25a>
  ip = 0;
    80004ea2:	4a01                	li	s4,0
    80004ea4:	a855                	j	80004f58 <exec+0x36a>
  sp = sz;
    80004ea6:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004eaa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eac:	00349793          	slli	a5,s1,0x3
    80004eb0:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd1c0>
    80004eb4:	97a2                	add	a5,a5,s0
    80004eb6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eba:	00148693          	addi	a3,s1,1
    80004ebe:	068e                	slli	a3,a3,0x3
    80004ec0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec4:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004ec8:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004ecc:	f57968e3          	bltu	s2,s7,80004e1c <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed0:	e9040613          	addi	a2,s0,-368
    80004ed4:	85ca                	mv	a1,s2
    80004ed6:	855a                	mv	a0,s6
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	78e080e7          	jalr	1934(ra) # 80001666 <copyout>
    80004ee0:	0a054763          	bltz	a0,80004f8e <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004ee4:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004ee8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eec:	df843783          	ld	a5,-520(s0)
    80004ef0:	0007c703          	lbu	a4,0(a5)
    80004ef4:	cf11                	beqz	a4,80004f10 <exec+0x322>
    80004ef6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ef8:	02f00693          	li	a3,47
    80004efc:	a039                	j	80004f0a <exec+0x31c>
      last = s+1;
    80004efe:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f02:	0785                	addi	a5,a5,1
    80004f04:	fff7c703          	lbu	a4,-1(a5)
    80004f08:	c701                	beqz	a4,80004f10 <exec+0x322>
    if(*s == '/')
    80004f0a:	fed71ce3          	bne	a4,a3,80004f02 <exec+0x314>
    80004f0e:	bfc5                	j	80004efe <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f10:	4641                	li	a2,16
    80004f12:	df843583          	ld	a1,-520(s0)
    80004f16:	158a8513          	addi	a0,s5,344
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	efc080e7          	jalr	-260(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f22:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f26:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f2a:	e0843783          	ld	a5,-504(s0)
    80004f2e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f32:	058ab783          	ld	a5,88(s5)
    80004f36:	e6843703          	ld	a4,-408(s0)
    80004f3a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3c:	058ab783          	ld	a5,88(s5)
    80004f40:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f44:	85e6                	mv	a1,s9
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	bc0080e7          	jalr	-1088(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f4e:	0004851b          	sext.w	a0,s1
    80004f52:	bb15                	j	80004c86 <exec+0x98>
    80004f54:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f58:	e0843583          	ld	a1,-504(s0)
    80004f5c:	855a                	mv	a0,s6
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	ba8080e7          	jalr	-1112(ra) # 80001b06 <proc_freepagetable>
  return -1;
    80004f66:	557d                	li	a0,-1
  if(ip){
    80004f68:	d00a0fe3          	beqz	s4,80004c86 <exec+0x98>
    80004f6c:	b319                	j	80004c72 <exec+0x84>
    80004f6e:	e1243423          	sd	s2,-504(s0)
    80004f72:	b7dd                	j	80004f58 <exec+0x36a>
    80004f74:	e1243423          	sd	s2,-504(s0)
    80004f78:	b7c5                	j	80004f58 <exec+0x36a>
    80004f7a:	e1243423          	sd	s2,-504(s0)
    80004f7e:	bfe9                	j	80004f58 <exec+0x36a>
    80004f80:	e1243423          	sd	s2,-504(s0)
    80004f84:	bfd1                	j	80004f58 <exec+0x36a>
  ip = 0;
    80004f86:	4a01                	li	s4,0
    80004f88:	bfc1                	j	80004f58 <exec+0x36a>
    80004f8a:	4a01                	li	s4,0
  if(pagetable)
    80004f8c:	b7f1                	j	80004f58 <exec+0x36a>
  sz = sz1;
    80004f8e:	e0843983          	ld	s3,-504(s0)
    80004f92:	b569                	j	80004e1c <exec+0x22e>

0000000080004f94 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f94:	7179                	addi	sp,sp,-48
    80004f96:	f406                	sd	ra,40(sp)
    80004f98:	f022                	sd	s0,32(sp)
    80004f9a:	ec26                	sd	s1,24(sp)
    80004f9c:	e84a                	sd	s2,16(sp)
    80004f9e:	1800                	addi	s0,sp,48
    80004fa0:	892e                	mv	s2,a1
    80004fa2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004fa4:	fdc40593          	addi	a1,s0,-36
    80004fa8:	ffffe097          	auipc	ra,0xffffe
    80004fac:	bc8080e7          	jalr	-1080(ra) # 80002b70 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fb0:	fdc42703          	lw	a4,-36(s0)
    80004fb4:	47bd                	li	a5,15
    80004fb6:	02e7eb63          	bltu	a5,a4,80004fec <argfd+0x58>
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	9ec080e7          	jalr	-1556(ra) # 800019a6 <myproc>
    80004fc2:	fdc42703          	lw	a4,-36(s0)
    80004fc6:	01a70793          	addi	a5,a4,26
    80004fca:	078e                	slli	a5,a5,0x3
    80004fcc:	953e                	add	a0,a0,a5
    80004fce:	611c                	ld	a5,0(a0)
    80004fd0:	c385                	beqz	a5,80004ff0 <argfd+0x5c>
    return -1;
  if(pfd)
    80004fd2:	00090463          	beqz	s2,80004fda <argfd+0x46>
    *pfd = fd;
    80004fd6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fda:	4501                	li	a0,0
  if(pf)
    80004fdc:	c091                	beqz	s1,80004fe0 <argfd+0x4c>
    *pf = f;
    80004fde:	e09c                	sd	a5,0(s1)
}
    80004fe0:	70a2                	ld	ra,40(sp)
    80004fe2:	7402                	ld	s0,32(sp)
    80004fe4:	64e2                	ld	s1,24(sp)
    80004fe6:	6942                	ld	s2,16(sp)
    80004fe8:	6145                	addi	sp,sp,48
    80004fea:	8082                	ret
    return -1;
    80004fec:	557d                	li	a0,-1
    80004fee:	bfcd                	j	80004fe0 <argfd+0x4c>
    80004ff0:	557d                	li	a0,-1
    80004ff2:	b7fd                	j	80004fe0 <argfd+0x4c>

0000000080004ff4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ff4:	1101                	addi	sp,sp,-32
    80004ff6:	ec06                	sd	ra,24(sp)
    80004ff8:	e822                	sd	s0,16(sp)
    80004ffa:	e426                	sd	s1,8(sp)
    80004ffc:	1000                	addi	s0,sp,32
    80004ffe:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	9a6080e7          	jalr	-1626(ra) # 800019a6 <myproc>
    80005008:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000500a:	0d050793          	addi	a5,a0,208
    8000500e:	4501                	li	a0,0
    80005010:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005012:	6398                	ld	a4,0(a5)
    80005014:	cb19                	beqz	a4,8000502a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005016:	2505                	addiw	a0,a0,1
    80005018:	07a1                	addi	a5,a5,8
    8000501a:	fed51ce3          	bne	a0,a3,80005012 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000501e:	557d                	li	a0,-1
}
    80005020:	60e2                	ld	ra,24(sp)
    80005022:	6442                	ld	s0,16(sp)
    80005024:	64a2                	ld	s1,8(sp)
    80005026:	6105                	addi	sp,sp,32
    80005028:	8082                	ret
      p->ofile[fd] = f;
    8000502a:	01a50793          	addi	a5,a0,26
    8000502e:	078e                	slli	a5,a5,0x3
    80005030:	963e                	add	a2,a2,a5
    80005032:	e204                	sd	s1,0(a2)
      return fd;
    80005034:	b7f5                	j	80005020 <fdalloc+0x2c>

0000000080005036 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005036:	715d                	addi	sp,sp,-80
    80005038:	e486                	sd	ra,72(sp)
    8000503a:	e0a2                	sd	s0,64(sp)
    8000503c:	fc26                	sd	s1,56(sp)
    8000503e:	f84a                	sd	s2,48(sp)
    80005040:	f44e                	sd	s3,40(sp)
    80005042:	f052                	sd	s4,32(sp)
    80005044:	ec56                	sd	s5,24(sp)
    80005046:	e85a                	sd	s6,16(sp)
    80005048:	0880                	addi	s0,sp,80
    8000504a:	8b2e                	mv	s6,a1
    8000504c:	89b2                	mv	s3,a2
    8000504e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005050:	fb040593          	addi	a1,s0,-80
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	e7e080e7          	jalr	-386(ra) # 80003ed2 <nameiparent>
    8000505c:	84aa                	mv	s1,a0
    8000505e:	14050b63          	beqz	a0,800051b4 <create+0x17e>
    return 0;

  ilock(dp);
    80005062:	ffffe097          	auipc	ra,0xffffe
    80005066:	6ac080e7          	jalr	1708(ra) # 8000370e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000506a:	4601                	li	a2,0
    8000506c:	fb040593          	addi	a1,s0,-80
    80005070:	8526                	mv	a0,s1
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	b80080e7          	jalr	-1152(ra) # 80003bf2 <dirlookup>
    8000507a:	8aaa                	mv	s5,a0
    8000507c:	c921                	beqz	a0,800050cc <create+0x96>
    iunlockput(dp);
    8000507e:	8526                	mv	a0,s1
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	8f0080e7          	jalr	-1808(ra) # 80003970 <iunlockput>
    ilock(ip);
    80005088:	8556                	mv	a0,s5
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	684080e7          	jalr	1668(ra) # 8000370e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005092:	4789                	li	a5,2
    80005094:	02fb1563          	bne	s6,a5,800050be <create+0x88>
    80005098:	044ad783          	lhu	a5,68(s5)
    8000509c:	37f9                	addiw	a5,a5,-2
    8000509e:	17c2                	slli	a5,a5,0x30
    800050a0:	93c1                	srli	a5,a5,0x30
    800050a2:	4705                	li	a4,1
    800050a4:	00f76d63          	bltu	a4,a5,800050be <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800050a8:	8556                	mv	a0,s5
    800050aa:	60a6                	ld	ra,72(sp)
    800050ac:	6406                	ld	s0,64(sp)
    800050ae:	74e2                	ld	s1,56(sp)
    800050b0:	7942                	ld	s2,48(sp)
    800050b2:	79a2                	ld	s3,40(sp)
    800050b4:	7a02                	ld	s4,32(sp)
    800050b6:	6ae2                	ld	s5,24(sp)
    800050b8:	6b42                	ld	s6,16(sp)
    800050ba:	6161                	addi	sp,sp,80
    800050bc:	8082                	ret
    iunlockput(ip);
    800050be:	8556                	mv	a0,s5
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	8b0080e7          	jalr	-1872(ra) # 80003970 <iunlockput>
    return 0;
    800050c8:	4a81                	li	s5,0
    800050ca:	bff9                	j	800050a8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050cc:	85da                	mv	a1,s6
    800050ce:	4088                	lw	a0,0(s1)
    800050d0:	ffffe097          	auipc	ra,0xffffe
    800050d4:	4a6080e7          	jalr	1190(ra) # 80003576 <ialloc>
    800050d8:	8a2a                	mv	s4,a0
    800050da:	c529                	beqz	a0,80005124 <create+0xee>
  ilock(ip);
    800050dc:	ffffe097          	auipc	ra,0xffffe
    800050e0:	632080e7          	jalr	1586(ra) # 8000370e <ilock>
  ip->major = major;
    800050e4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050e8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050ec:	4905                	li	s2,1
    800050ee:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050f2:	8552                	mv	a0,s4
    800050f4:	ffffe097          	auipc	ra,0xffffe
    800050f8:	54e080e7          	jalr	1358(ra) # 80003642 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050fc:	032b0b63          	beq	s6,s2,80005132 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005100:	004a2603          	lw	a2,4(s4)
    80005104:	fb040593          	addi	a1,s0,-80
    80005108:	8526                	mv	a0,s1
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	cf8080e7          	jalr	-776(ra) # 80003e02 <dirlink>
    80005112:	06054f63          	bltz	a0,80005190 <create+0x15a>
  iunlockput(dp);
    80005116:	8526                	mv	a0,s1
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	858080e7          	jalr	-1960(ra) # 80003970 <iunlockput>
  return ip;
    80005120:	8ad2                	mv	s5,s4
    80005122:	b759                	j	800050a8 <create+0x72>
    iunlockput(dp);
    80005124:	8526                	mv	a0,s1
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	84a080e7          	jalr	-1974(ra) # 80003970 <iunlockput>
    return 0;
    8000512e:	8ad2                	mv	s5,s4
    80005130:	bfa5                	j	800050a8 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005132:	004a2603          	lw	a2,4(s4)
    80005136:	00003597          	auipc	a1,0x3
    8000513a:	64258593          	addi	a1,a1,1602 # 80008778 <syscalls+0x2c0>
    8000513e:	8552                	mv	a0,s4
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	cc2080e7          	jalr	-830(ra) # 80003e02 <dirlink>
    80005148:	04054463          	bltz	a0,80005190 <create+0x15a>
    8000514c:	40d0                	lw	a2,4(s1)
    8000514e:	00003597          	auipc	a1,0x3
    80005152:	63258593          	addi	a1,a1,1586 # 80008780 <syscalls+0x2c8>
    80005156:	8552                	mv	a0,s4
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	caa080e7          	jalr	-854(ra) # 80003e02 <dirlink>
    80005160:	02054863          	bltz	a0,80005190 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005164:	004a2603          	lw	a2,4(s4)
    80005168:	fb040593          	addi	a1,s0,-80
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	c94080e7          	jalr	-876(ra) # 80003e02 <dirlink>
    80005176:	00054d63          	bltz	a0,80005190 <create+0x15a>
    dp->nlink++;  // for ".."
    8000517a:	04a4d783          	lhu	a5,74(s1)
    8000517e:	2785                	addiw	a5,a5,1
    80005180:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005184:	8526                	mv	a0,s1
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	4bc080e7          	jalr	1212(ra) # 80003642 <iupdate>
    8000518e:	b761                	j	80005116 <create+0xe0>
  ip->nlink = 0;
    80005190:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005194:	8552                	mv	a0,s4
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	4ac080e7          	jalr	1196(ra) # 80003642 <iupdate>
  iunlockput(ip);
    8000519e:	8552                	mv	a0,s4
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	7d0080e7          	jalr	2000(ra) # 80003970 <iunlockput>
  iunlockput(dp);
    800051a8:	8526                	mv	a0,s1
    800051aa:	ffffe097          	auipc	ra,0xffffe
    800051ae:	7c6080e7          	jalr	1990(ra) # 80003970 <iunlockput>
  return 0;
    800051b2:	bddd                	j	800050a8 <create+0x72>
    return 0;
    800051b4:	8aaa                	mv	s5,a0
    800051b6:	bdcd                	j	800050a8 <create+0x72>

00000000800051b8 <sys_dup>:
{
    800051b8:	7179                	addi	sp,sp,-48
    800051ba:	f406                	sd	ra,40(sp)
    800051bc:	f022                	sd	s0,32(sp)
    800051be:	ec26                	sd	s1,24(sp)
    800051c0:	e84a                	sd	s2,16(sp)
    800051c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051c4:	fd840613          	addi	a2,s0,-40
    800051c8:	4581                	li	a1,0
    800051ca:	4501                	li	a0,0
    800051cc:	00000097          	auipc	ra,0x0
    800051d0:	dc8080e7          	jalr	-568(ra) # 80004f94 <argfd>
    return -1;
    800051d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051d6:	02054363          	bltz	a0,800051fc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051da:	fd843903          	ld	s2,-40(s0)
    800051de:	854a                	mv	a0,s2
    800051e0:	00000097          	auipc	ra,0x0
    800051e4:	e14080e7          	jalr	-492(ra) # 80004ff4 <fdalloc>
    800051e8:	84aa                	mv	s1,a0
    return -1;
    800051ea:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ec:	00054863          	bltz	a0,800051fc <sys_dup+0x44>
  filedup(f);
    800051f0:	854a                	mv	a0,s2
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	334080e7          	jalr	820(ra) # 80004526 <filedup>
  return fd;
    800051fa:	87a6                	mv	a5,s1
}
    800051fc:	853e                	mv	a0,a5
    800051fe:	70a2                	ld	ra,40(sp)
    80005200:	7402                	ld	s0,32(sp)
    80005202:	64e2                	ld	s1,24(sp)
    80005204:	6942                	ld	s2,16(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret

000000008000520a <sys_read>:
{
    8000520a:	7179                	addi	sp,sp,-48
    8000520c:	f406                	sd	ra,40(sp)
    8000520e:	f022                	sd	s0,32(sp)
    80005210:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005212:	fd840593          	addi	a1,s0,-40
    80005216:	4505                	li	a0,1
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	978080e7          	jalr	-1672(ra) # 80002b90 <argaddr>
  argint(2, &n);
    80005220:	fe440593          	addi	a1,s0,-28
    80005224:	4509                	li	a0,2
    80005226:	ffffe097          	auipc	ra,0xffffe
    8000522a:	94a080e7          	jalr	-1718(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    8000522e:	fe840613          	addi	a2,s0,-24
    80005232:	4581                	li	a1,0
    80005234:	4501                	li	a0,0
    80005236:	00000097          	auipc	ra,0x0
    8000523a:	d5e080e7          	jalr	-674(ra) # 80004f94 <argfd>
    8000523e:	87aa                	mv	a5,a0
    return -1;
    80005240:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005242:	0007cc63          	bltz	a5,8000525a <sys_read+0x50>
  return fileread(f, p, n);
    80005246:	fe442603          	lw	a2,-28(s0)
    8000524a:	fd843583          	ld	a1,-40(s0)
    8000524e:	fe843503          	ld	a0,-24(s0)
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	460080e7          	jalr	1120(ra) # 800046b2 <fileread>
}
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	6145                	addi	sp,sp,48
    80005260:	8082                	ret

0000000080005262 <sys_write>:
{
    80005262:	7179                	addi	sp,sp,-48
    80005264:	f406                	sd	ra,40(sp)
    80005266:	f022                	sd	s0,32(sp)
    80005268:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000526a:	fd840593          	addi	a1,s0,-40
    8000526e:	4505                	li	a0,1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	920080e7          	jalr	-1760(ra) # 80002b90 <argaddr>
  argint(2, &n);
    80005278:	fe440593          	addi	a1,s0,-28
    8000527c:	4509                	li	a0,2
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	8f2080e7          	jalr	-1806(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    80005286:	fe840613          	addi	a2,s0,-24
    8000528a:	4581                	li	a1,0
    8000528c:	4501                	li	a0,0
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	d06080e7          	jalr	-762(ra) # 80004f94 <argfd>
    80005296:	87aa                	mv	a5,a0
    return -1;
    80005298:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000529a:	0007cc63          	bltz	a5,800052b2 <sys_write+0x50>
  return filewrite(f, p, n);
    8000529e:	fe442603          	lw	a2,-28(s0)
    800052a2:	fd843583          	ld	a1,-40(s0)
    800052a6:	fe843503          	ld	a0,-24(s0)
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	4ca080e7          	jalr	1226(ra) # 80004774 <filewrite>
}
    800052b2:	70a2                	ld	ra,40(sp)
    800052b4:	7402                	ld	s0,32(sp)
    800052b6:	6145                	addi	sp,sp,48
    800052b8:	8082                	ret

00000000800052ba <sys_close>:
{
    800052ba:	1101                	addi	sp,sp,-32
    800052bc:	ec06                	sd	ra,24(sp)
    800052be:	e822                	sd	s0,16(sp)
    800052c0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052c2:	fe040613          	addi	a2,s0,-32
    800052c6:	fec40593          	addi	a1,s0,-20
    800052ca:	4501                	li	a0,0
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	cc8080e7          	jalr	-824(ra) # 80004f94 <argfd>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052d6:	02054463          	bltz	a0,800052fe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	6cc080e7          	jalr	1740(ra) # 800019a6 <myproc>
    800052e2:	fec42783          	lw	a5,-20(s0)
    800052e6:	07e9                	addi	a5,a5,26
    800052e8:	078e                	slli	a5,a5,0x3
    800052ea:	953e                	add	a0,a0,a5
    800052ec:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052f0:	fe043503          	ld	a0,-32(s0)
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	284080e7          	jalr	644(ra) # 80004578 <fileclose>
  return 0;
    800052fc:	4781                	li	a5,0
}
    800052fe:	853e                	mv	a0,a5
    80005300:	60e2                	ld	ra,24(sp)
    80005302:	6442                	ld	s0,16(sp)
    80005304:	6105                	addi	sp,sp,32
    80005306:	8082                	ret

0000000080005308 <sys_fstat>:
{
    80005308:	1101                	addi	sp,sp,-32
    8000530a:	ec06                	sd	ra,24(sp)
    8000530c:	e822                	sd	s0,16(sp)
    8000530e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005310:	fe040593          	addi	a1,s0,-32
    80005314:	4505                	li	a0,1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	87a080e7          	jalr	-1926(ra) # 80002b90 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000531e:	fe840613          	addi	a2,s0,-24
    80005322:	4581                	li	a1,0
    80005324:	4501                	li	a0,0
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	c6e080e7          	jalr	-914(ra) # 80004f94 <argfd>
    8000532e:	87aa                	mv	a5,a0
    return -1;
    80005330:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005332:	0007ca63          	bltz	a5,80005346 <sys_fstat+0x3e>
  return filestat(f, st);
    80005336:	fe043583          	ld	a1,-32(s0)
    8000533a:	fe843503          	ld	a0,-24(s0)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	302080e7          	jalr	770(ra) # 80004640 <filestat>
}
    80005346:	60e2                	ld	ra,24(sp)
    80005348:	6442                	ld	s0,16(sp)
    8000534a:	6105                	addi	sp,sp,32
    8000534c:	8082                	ret

000000008000534e <sys_link>:
{
    8000534e:	7169                	addi	sp,sp,-304
    80005350:	f606                	sd	ra,296(sp)
    80005352:	f222                	sd	s0,288(sp)
    80005354:	ee26                	sd	s1,280(sp)
    80005356:	ea4a                	sd	s2,272(sp)
    80005358:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000535a:	08000613          	li	a2,128
    8000535e:	ed040593          	addi	a1,s0,-304
    80005362:	4501                	li	a0,0
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	84c080e7          	jalr	-1972(ra) # 80002bb0 <argstr>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536e:	10054e63          	bltz	a0,8000548a <sys_link+0x13c>
    80005372:	08000613          	li	a2,128
    80005376:	f5040593          	addi	a1,s0,-176
    8000537a:	4505                	li	a0,1
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	834080e7          	jalr	-1996(ra) # 80002bb0 <argstr>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005386:	10054263          	bltz	a0,8000548a <sys_link+0x13c>
  begin_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	d2a080e7          	jalr	-726(ra) # 800040b4 <begin_op>
  if((ip = namei(old)) == 0){
    80005392:	ed040513          	addi	a0,s0,-304
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	b1e080e7          	jalr	-1250(ra) # 80003eb4 <namei>
    8000539e:	84aa                	mv	s1,a0
    800053a0:	c551                	beqz	a0,8000542c <sys_link+0xde>
  ilock(ip);
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	36c080e7          	jalr	876(ra) # 8000370e <ilock>
  if(ip->type == T_DIR){
    800053aa:	04449703          	lh	a4,68(s1)
    800053ae:	4785                	li	a5,1
    800053b0:	08f70463          	beq	a4,a5,80005438 <sys_link+0xea>
  ip->nlink++;
    800053b4:	04a4d783          	lhu	a5,74(s1)
    800053b8:	2785                	addiw	a5,a5,1
    800053ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	282080e7          	jalr	642(ra) # 80003642 <iupdate>
  iunlock(ip);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	406080e7          	jalr	1030(ra) # 800037d0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053d2:	fd040593          	addi	a1,s0,-48
    800053d6:	f5040513          	addi	a0,s0,-176
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	af8080e7          	jalr	-1288(ra) # 80003ed2 <nameiparent>
    800053e2:	892a                	mv	s2,a0
    800053e4:	c935                	beqz	a0,80005458 <sys_link+0x10a>
  ilock(dp);
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	328080e7          	jalr	808(ra) # 8000370e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053ee:	00092703          	lw	a4,0(s2)
    800053f2:	409c                	lw	a5,0(s1)
    800053f4:	04f71d63          	bne	a4,a5,8000544e <sys_link+0x100>
    800053f8:	40d0                	lw	a2,4(s1)
    800053fa:	fd040593          	addi	a1,s0,-48
    800053fe:	854a                	mv	a0,s2
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	a02080e7          	jalr	-1534(ra) # 80003e02 <dirlink>
    80005408:	04054363          	bltz	a0,8000544e <sys_link+0x100>
  iunlockput(dp);
    8000540c:	854a                	mv	a0,s2
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	562080e7          	jalr	1378(ra) # 80003970 <iunlockput>
  iput(ip);
    80005416:	8526                	mv	a0,s1
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	4b0080e7          	jalr	1200(ra) # 800038c8 <iput>
  end_op();
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	d0e080e7          	jalr	-754(ra) # 8000412e <end_op>
  return 0;
    80005428:	4781                	li	a5,0
    8000542a:	a085                	j	8000548a <sys_link+0x13c>
    end_op();
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	d02080e7          	jalr	-766(ra) # 8000412e <end_op>
    return -1;
    80005434:	57fd                	li	a5,-1
    80005436:	a891                	j	8000548a <sys_link+0x13c>
    iunlockput(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	536080e7          	jalr	1334(ra) # 80003970 <iunlockput>
    end_op();
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	cec080e7          	jalr	-788(ra) # 8000412e <end_op>
    return -1;
    8000544a:	57fd                	li	a5,-1
    8000544c:	a83d                	j	8000548a <sys_link+0x13c>
    iunlockput(dp);
    8000544e:	854a                	mv	a0,s2
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	520080e7          	jalr	1312(ra) # 80003970 <iunlockput>
  ilock(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	2b4080e7          	jalr	692(ra) # 8000370e <ilock>
  ip->nlink--;
    80005462:	04a4d783          	lhu	a5,74(s1)
    80005466:	37fd                	addiw	a5,a5,-1
    80005468:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	1d4080e7          	jalr	468(ra) # 80003642 <iupdate>
  iunlockput(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	4f8080e7          	jalr	1272(ra) # 80003970 <iunlockput>
  end_op();
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	cae080e7          	jalr	-850(ra) # 8000412e <end_op>
  return -1;
    80005488:	57fd                	li	a5,-1
}
    8000548a:	853e                	mv	a0,a5
    8000548c:	70b2                	ld	ra,296(sp)
    8000548e:	7412                	ld	s0,288(sp)
    80005490:	64f2                	ld	s1,280(sp)
    80005492:	6952                	ld	s2,272(sp)
    80005494:	6155                	addi	sp,sp,304
    80005496:	8082                	ret

0000000080005498 <sys_unlink>:
{
    80005498:	7151                	addi	sp,sp,-240
    8000549a:	f586                	sd	ra,232(sp)
    8000549c:	f1a2                	sd	s0,224(sp)
    8000549e:	eda6                	sd	s1,216(sp)
    800054a0:	e9ca                	sd	s2,208(sp)
    800054a2:	e5ce                	sd	s3,200(sp)
    800054a4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054a6:	08000613          	li	a2,128
    800054aa:	f3040593          	addi	a1,s0,-208
    800054ae:	4501                	li	a0,0
    800054b0:	ffffd097          	auipc	ra,0xffffd
    800054b4:	700080e7          	jalr	1792(ra) # 80002bb0 <argstr>
    800054b8:	18054163          	bltz	a0,8000563a <sys_unlink+0x1a2>
  begin_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	bf8080e7          	jalr	-1032(ra) # 800040b4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054c4:	fb040593          	addi	a1,s0,-80
    800054c8:	f3040513          	addi	a0,s0,-208
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	a06080e7          	jalr	-1530(ra) # 80003ed2 <nameiparent>
    800054d4:	84aa                	mv	s1,a0
    800054d6:	c979                	beqz	a0,800055ac <sys_unlink+0x114>
  ilock(dp);
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	236080e7          	jalr	566(ra) # 8000370e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054e0:	00003597          	auipc	a1,0x3
    800054e4:	29858593          	addi	a1,a1,664 # 80008778 <syscalls+0x2c0>
    800054e8:	fb040513          	addi	a0,s0,-80
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	6ec080e7          	jalr	1772(ra) # 80003bd8 <namecmp>
    800054f4:	14050a63          	beqz	a0,80005648 <sys_unlink+0x1b0>
    800054f8:	00003597          	auipc	a1,0x3
    800054fc:	28858593          	addi	a1,a1,648 # 80008780 <syscalls+0x2c8>
    80005500:	fb040513          	addi	a0,s0,-80
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	6d4080e7          	jalr	1748(ra) # 80003bd8 <namecmp>
    8000550c:	12050e63          	beqz	a0,80005648 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005510:	f2c40613          	addi	a2,s0,-212
    80005514:	fb040593          	addi	a1,s0,-80
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	6d8080e7          	jalr	1752(ra) # 80003bf2 <dirlookup>
    80005522:	892a                	mv	s2,a0
    80005524:	12050263          	beqz	a0,80005648 <sys_unlink+0x1b0>
  ilock(ip);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	1e6080e7          	jalr	486(ra) # 8000370e <ilock>
  if(ip->nlink < 1)
    80005530:	04a91783          	lh	a5,74(s2)
    80005534:	08f05263          	blez	a5,800055b8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005538:	04491703          	lh	a4,68(s2)
    8000553c:	4785                	li	a5,1
    8000553e:	08f70563          	beq	a4,a5,800055c8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005542:	4641                	li	a2,16
    80005544:	4581                	li	a1,0
    80005546:	fc040513          	addi	a0,s0,-64
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	784080e7          	jalr	1924(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005552:	4741                	li	a4,16
    80005554:	f2c42683          	lw	a3,-212(s0)
    80005558:	fc040613          	addi	a2,s0,-64
    8000555c:	4581                	li	a1,0
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	55a080e7          	jalr	1370(ra) # 80003aba <writei>
    80005568:	47c1                	li	a5,16
    8000556a:	0af51563          	bne	a0,a5,80005614 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000556e:	04491703          	lh	a4,68(s2)
    80005572:	4785                	li	a5,1
    80005574:	0af70863          	beq	a4,a5,80005624 <sys_unlink+0x18c>
  iunlockput(dp);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	3f6080e7          	jalr	1014(ra) # 80003970 <iunlockput>
  ip->nlink--;
    80005582:	04a95783          	lhu	a5,74(s2)
    80005586:	37fd                	addiw	a5,a5,-1
    80005588:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000558c:	854a                	mv	a0,s2
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	0b4080e7          	jalr	180(ra) # 80003642 <iupdate>
  iunlockput(ip);
    80005596:	854a                	mv	a0,s2
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	3d8080e7          	jalr	984(ra) # 80003970 <iunlockput>
  end_op();
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	b8e080e7          	jalr	-1138(ra) # 8000412e <end_op>
  return 0;
    800055a8:	4501                	li	a0,0
    800055aa:	a84d                	j	8000565c <sys_unlink+0x1c4>
    end_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	b82080e7          	jalr	-1150(ra) # 8000412e <end_op>
    return -1;
    800055b4:	557d                	li	a0,-1
    800055b6:	a05d                	j	8000565c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055b8:	00003517          	auipc	a0,0x3
    800055bc:	1d050513          	addi	a0,a0,464 # 80008788 <syscalls+0x2d0>
    800055c0:	ffffb097          	auipc	ra,0xffffb
    800055c4:	f7c080e7          	jalr	-132(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055c8:	04c92703          	lw	a4,76(s2)
    800055cc:	02000793          	li	a5,32
    800055d0:	f6e7f9e3          	bgeu	a5,a4,80005542 <sys_unlink+0xaa>
    800055d4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d8:	4741                	li	a4,16
    800055da:	86ce                	mv	a3,s3
    800055dc:	f1840613          	addi	a2,s0,-232
    800055e0:	4581                	li	a1,0
    800055e2:	854a                	mv	a0,s2
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	3de080e7          	jalr	990(ra) # 800039c2 <readi>
    800055ec:	47c1                	li	a5,16
    800055ee:	00f51b63          	bne	a0,a5,80005604 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055f2:	f1845783          	lhu	a5,-232(s0)
    800055f6:	e7a1                	bnez	a5,8000563e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055f8:	29c1                	addiw	s3,s3,16
    800055fa:	04c92783          	lw	a5,76(s2)
    800055fe:	fcf9ede3          	bltu	s3,a5,800055d8 <sys_unlink+0x140>
    80005602:	b781                	j	80005542 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005604:	00003517          	auipc	a0,0x3
    80005608:	19c50513          	addi	a0,a0,412 # 800087a0 <syscalls+0x2e8>
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	f30080e7          	jalr	-208(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005614:	00003517          	auipc	a0,0x3
    80005618:	1a450513          	addi	a0,a0,420 # 800087b8 <syscalls+0x300>
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	f20080e7          	jalr	-224(ra) # 8000053c <panic>
    dp->nlink--;
    80005624:	04a4d783          	lhu	a5,74(s1)
    80005628:	37fd                	addiw	a5,a5,-1
    8000562a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	012080e7          	jalr	18(ra) # 80003642 <iupdate>
    80005638:	b781                	j	80005578 <sys_unlink+0xe0>
    return -1;
    8000563a:	557d                	li	a0,-1
    8000563c:	a005                	j	8000565c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	330080e7          	jalr	816(ra) # 80003970 <iunlockput>
  iunlockput(dp);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	326080e7          	jalr	806(ra) # 80003970 <iunlockput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	adc080e7          	jalr	-1316(ra) # 8000412e <end_op>
  return -1;
    8000565a:	557d                	li	a0,-1
}
    8000565c:	70ae                	ld	ra,232(sp)
    8000565e:	740e                	ld	s0,224(sp)
    80005660:	64ee                	ld	s1,216(sp)
    80005662:	694e                	ld	s2,208(sp)
    80005664:	69ae                	ld	s3,200(sp)
    80005666:	616d                	addi	sp,sp,240
    80005668:	8082                	ret

000000008000566a <sys_open>:

uint64
sys_open(void)
{
    8000566a:	7131                	addi	sp,sp,-192
    8000566c:	fd06                	sd	ra,184(sp)
    8000566e:	f922                	sd	s0,176(sp)
    80005670:	f526                	sd	s1,168(sp)
    80005672:	f14a                	sd	s2,160(sp)
    80005674:	ed4e                	sd	s3,152(sp)
    80005676:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005678:	f4c40593          	addi	a1,s0,-180
    8000567c:	4505                	li	a0,1
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	4f2080e7          	jalr	1266(ra) # 80002b70 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005686:	08000613          	li	a2,128
    8000568a:	f5040593          	addi	a1,s0,-176
    8000568e:	4501                	li	a0,0
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	520080e7          	jalr	1312(ra) # 80002bb0 <argstr>
    80005698:	87aa                	mv	a5,a0
    return -1;
    8000569a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000569c:	0a07c863          	bltz	a5,8000574c <sys_open+0xe2>

  begin_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	a14080e7          	jalr	-1516(ra) # 800040b4 <begin_op>

  if(omode & O_CREATE){
    800056a8:	f4c42783          	lw	a5,-180(s0)
    800056ac:	2007f793          	andi	a5,a5,512
    800056b0:	cbdd                	beqz	a5,80005766 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800056b2:	4681                	li	a3,0
    800056b4:	4601                	li	a2,0
    800056b6:	4589                	li	a1,2
    800056b8:	f5040513          	addi	a0,s0,-176
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	97a080e7          	jalr	-1670(ra) # 80005036 <create>
    800056c4:	84aa                	mv	s1,a0
    if(ip == 0){
    800056c6:	c951                	beqz	a0,8000575a <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056c8:	04449703          	lh	a4,68(s1)
    800056cc:	478d                	li	a5,3
    800056ce:	00f71763          	bne	a4,a5,800056dc <sys_open+0x72>
    800056d2:	0464d703          	lhu	a4,70(s1)
    800056d6:	47a5                	li	a5,9
    800056d8:	0ce7ec63          	bltu	a5,a4,800057b0 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	de0080e7          	jalr	-544(ra) # 800044bc <filealloc>
    800056e4:	892a                	mv	s2,a0
    800056e6:	c56d                	beqz	a0,800057d0 <sys_open+0x166>
    800056e8:	00000097          	auipc	ra,0x0
    800056ec:	90c080e7          	jalr	-1780(ra) # 80004ff4 <fdalloc>
    800056f0:	89aa                	mv	s3,a0
    800056f2:	0c054a63          	bltz	a0,800057c6 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056f6:	04449703          	lh	a4,68(s1)
    800056fa:	478d                	li	a5,3
    800056fc:	0ef70563          	beq	a4,a5,800057e6 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005700:	4789                	li	a5,2
    80005702:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005706:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000570a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000570e:	f4c42783          	lw	a5,-180(s0)
    80005712:	0017c713          	xori	a4,a5,1
    80005716:	8b05                	andi	a4,a4,1
    80005718:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000571c:	0037f713          	andi	a4,a5,3
    80005720:	00e03733          	snez	a4,a4
    80005724:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005728:	4007f793          	andi	a5,a5,1024
    8000572c:	c791                	beqz	a5,80005738 <sys_open+0xce>
    8000572e:	04449703          	lh	a4,68(s1)
    80005732:	4789                	li	a5,2
    80005734:	0cf70063          	beq	a4,a5,800057f4 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	096080e7          	jalr	150(ra) # 800037d0 <iunlock>
  end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	9ec080e7          	jalr	-1556(ra) # 8000412e <end_op>

  return fd;
    8000574a:	854e                	mv	a0,s3
}
    8000574c:	70ea                	ld	ra,184(sp)
    8000574e:	744a                	ld	s0,176(sp)
    80005750:	74aa                	ld	s1,168(sp)
    80005752:	790a                	ld	s2,160(sp)
    80005754:	69ea                	ld	s3,152(sp)
    80005756:	6129                	addi	sp,sp,192
    80005758:	8082                	ret
      end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	9d4080e7          	jalr	-1580(ra) # 8000412e <end_op>
      return -1;
    80005762:	557d                	li	a0,-1
    80005764:	b7e5                	j	8000574c <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005766:	f5040513          	addi	a0,s0,-176
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	74a080e7          	jalr	1866(ra) # 80003eb4 <namei>
    80005772:	84aa                	mv	s1,a0
    80005774:	c905                	beqz	a0,800057a4 <sys_open+0x13a>
    ilock(ip);
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	f98080e7          	jalr	-104(ra) # 8000370e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000577e:	04449703          	lh	a4,68(s1)
    80005782:	4785                	li	a5,1
    80005784:	f4f712e3          	bne	a4,a5,800056c8 <sys_open+0x5e>
    80005788:	f4c42783          	lw	a5,-180(s0)
    8000578c:	dba1                	beqz	a5,800056dc <sys_open+0x72>
      iunlockput(ip);
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	1e0080e7          	jalr	480(ra) # 80003970 <iunlockput>
      end_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	996080e7          	jalr	-1642(ra) # 8000412e <end_op>
      return -1;
    800057a0:	557d                	li	a0,-1
    800057a2:	b76d                	j	8000574c <sys_open+0xe2>
      end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	98a080e7          	jalr	-1654(ra) # 8000412e <end_op>
      return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	bf79                	j	8000574c <sys_open+0xe2>
    iunlockput(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	1be080e7          	jalr	446(ra) # 80003970 <iunlockput>
    end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	974080e7          	jalr	-1676(ra) # 8000412e <end_op>
    return -1;
    800057c2:	557d                	li	a0,-1
    800057c4:	b761                	j	8000574c <sys_open+0xe2>
      fileclose(f);
    800057c6:	854a                	mv	a0,s2
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	db0080e7          	jalr	-592(ra) # 80004578 <fileclose>
    iunlockput(ip);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	19e080e7          	jalr	414(ra) # 80003970 <iunlockput>
    end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	954080e7          	jalr	-1708(ra) # 8000412e <end_op>
    return -1;
    800057e2:	557d                	li	a0,-1
    800057e4:	b7a5                	j	8000574c <sys_open+0xe2>
    f->type = FD_DEVICE;
    800057e6:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800057ea:	04649783          	lh	a5,70(s1)
    800057ee:	02f91223          	sh	a5,36(s2)
    800057f2:	bf21                	j	8000570a <sys_open+0xa0>
    itrunc(ip);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	026080e7          	jalr	38(ra) # 8000381c <itrunc>
    800057fe:	bf2d                	j	80005738 <sys_open+0xce>

0000000080005800 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005800:	7175                	addi	sp,sp,-144
    80005802:	e506                	sd	ra,136(sp)
    80005804:	e122                	sd	s0,128(sp)
    80005806:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	8ac080e7          	jalr	-1876(ra) # 800040b4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005810:	08000613          	li	a2,128
    80005814:	f7040593          	addi	a1,s0,-144
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	396080e7          	jalr	918(ra) # 80002bb0 <argstr>
    80005822:	02054963          	bltz	a0,80005854 <sys_mkdir+0x54>
    80005826:	4681                	li	a3,0
    80005828:	4601                	li	a2,0
    8000582a:	4585                	li	a1,1
    8000582c:	f7040513          	addi	a0,s0,-144
    80005830:	00000097          	auipc	ra,0x0
    80005834:	806080e7          	jalr	-2042(ra) # 80005036 <create>
    80005838:	cd11                	beqz	a0,80005854 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	136080e7          	jalr	310(ra) # 80003970 <iunlockput>
  end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	8ec080e7          	jalr	-1812(ra) # 8000412e <end_op>
  return 0;
    8000584a:	4501                	li	a0,0
}
    8000584c:	60aa                	ld	ra,136(sp)
    8000584e:	640a                	ld	s0,128(sp)
    80005850:	6149                	addi	sp,sp,144
    80005852:	8082                	ret
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	8da080e7          	jalr	-1830(ra) # 8000412e <end_op>
    return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	b7fd                	j	8000584c <sys_mkdir+0x4c>

0000000080005860 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005860:	7135                	addi	sp,sp,-160
    80005862:	ed06                	sd	ra,152(sp)
    80005864:	e922                	sd	s0,144(sp)
    80005866:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	84c080e7          	jalr	-1972(ra) # 800040b4 <begin_op>
  argint(1, &major);
    80005870:	f6c40593          	addi	a1,s0,-148
    80005874:	4505                	li	a0,1
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	2fa080e7          	jalr	762(ra) # 80002b70 <argint>
  argint(2, &minor);
    8000587e:	f6840593          	addi	a1,s0,-152
    80005882:	4509                	li	a0,2
    80005884:	ffffd097          	auipc	ra,0xffffd
    80005888:	2ec080e7          	jalr	748(ra) # 80002b70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000588c:	08000613          	li	a2,128
    80005890:	f7040593          	addi	a1,s0,-144
    80005894:	4501                	li	a0,0
    80005896:	ffffd097          	auipc	ra,0xffffd
    8000589a:	31a080e7          	jalr	794(ra) # 80002bb0 <argstr>
    8000589e:	02054b63          	bltz	a0,800058d4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058a2:	f6841683          	lh	a3,-152(s0)
    800058a6:	f6c41603          	lh	a2,-148(s0)
    800058aa:	458d                	li	a1,3
    800058ac:	f7040513          	addi	a0,s0,-144
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	786080e7          	jalr	1926(ra) # 80005036 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058b8:	cd11                	beqz	a0,800058d4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	0b6080e7          	jalr	182(ra) # 80003970 <iunlockput>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	86c080e7          	jalr	-1940(ra) # 8000412e <end_op>
  return 0;
    800058ca:	4501                	li	a0,0
}
    800058cc:	60ea                	ld	ra,152(sp)
    800058ce:	644a                	ld	s0,144(sp)
    800058d0:	610d                	addi	sp,sp,160
    800058d2:	8082                	ret
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	85a080e7          	jalr	-1958(ra) # 8000412e <end_op>
    return -1;
    800058dc:	557d                	li	a0,-1
    800058de:	b7fd                	j	800058cc <sys_mknod+0x6c>

00000000800058e0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058e0:	7135                	addi	sp,sp,-160
    800058e2:	ed06                	sd	ra,152(sp)
    800058e4:	e922                	sd	s0,144(sp)
    800058e6:	e526                	sd	s1,136(sp)
    800058e8:	e14a                	sd	s2,128(sp)
    800058ea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058ec:	ffffc097          	auipc	ra,0xffffc
    800058f0:	0ba080e7          	jalr	186(ra) # 800019a6 <myproc>
    800058f4:	892a                	mv	s2,a0
  
  begin_op();
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	7be080e7          	jalr	1982(ra) # 800040b4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058fe:	08000613          	li	a2,128
    80005902:	f6040593          	addi	a1,s0,-160
    80005906:	4501                	li	a0,0
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	2a8080e7          	jalr	680(ra) # 80002bb0 <argstr>
    80005910:	04054b63          	bltz	a0,80005966 <sys_chdir+0x86>
    80005914:	f6040513          	addi	a0,s0,-160
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	59c080e7          	jalr	1436(ra) # 80003eb4 <namei>
    80005920:	84aa                	mv	s1,a0
    80005922:	c131                	beqz	a0,80005966 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	dea080e7          	jalr	-534(ra) # 8000370e <ilock>
  if(ip->type != T_DIR){
    8000592c:	04449703          	lh	a4,68(s1)
    80005930:	4785                	li	a5,1
    80005932:	04f71063          	bne	a4,a5,80005972 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	e98080e7          	jalr	-360(ra) # 800037d0 <iunlock>
  iput(p->cwd);
    80005940:	15093503          	ld	a0,336(s2)
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	f84080e7          	jalr	-124(ra) # 800038c8 <iput>
  end_op();
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	7e2080e7          	jalr	2018(ra) # 8000412e <end_op>
  p->cwd = ip;
    80005954:	14993823          	sd	s1,336(s2)
  return 0;
    80005958:	4501                	li	a0,0
}
    8000595a:	60ea                	ld	ra,152(sp)
    8000595c:	644a                	ld	s0,144(sp)
    8000595e:	64aa                	ld	s1,136(sp)
    80005960:	690a                	ld	s2,128(sp)
    80005962:	610d                	addi	sp,sp,160
    80005964:	8082                	ret
    end_op();
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	7c8080e7          	jalr	1992(ra) # 8000412e <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	b7ed                	j	8000595a <sys_chdir+0x7a>
    iunlockput(ip);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	ffc080e7          	jalr	-4(ra) # 80003970 <iunlockput>
    end_op();
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	7b2080e7          	jalr	1970(ra) # 8000412e <end_op>
    return -1;
    80005984:	557d                	li	a0,-1
    80005986:	bfd1                	j	8000595a <sys_chdir+0x7a>

0000000080005988 <sys_exec>:

uint64
sys_exec(void)
{
    80005988:	7121                	addi	sp,sp,-448
    8000598a:	ff06                	sd	ra,440(sp)
    8000598c:	fb22                	sd	s0,432(sp)
    8000598e:	f726                	sd	s1,424(sp)
    80005990:	f34a                	sd	s2,416(sp)
    80005992:	ef4e                	sd	s3,408(sp)
    80005994:	eb52                	sd	s4,400(sp)
    80005996:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005998:	e4840593          	addi	a1,s0,-440
    8000599c:	4505                	li	a0,1
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	1f2080e7          	jalr	498(ra) # 80002b90 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800059a6:	08000613          	li	a2,128
    800059aa:	f5040593          	addi	a1,s0,-176
    800059ae:	4501                	li	a0,0
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	200080e7          	jalr	512(ra) # 80002bb0 <argstr>
    800059b8:	87aa                	mv	a5,a0
    return -1;
    800059ba:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059bc:	0c07c263          	bltz	a5,80005a80 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    800059c0:	10000613          	li	a2,256
    800059c4:	4581                	li	a1,0
    800059c6:	e5040513          	addi	a0,s0,-432
    800059ca:	ffffb097          	auipc	ra,0xffffb
    800059ce:	304080e7          	jalr	772(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059d2:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800059d6:	89a6                	mv	s3,s1
    800059d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059da:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059de:	00391513          	slli	a0,s2,0x3
    800059e2:	e4040593          	addi	a1,s0,-448
    800059e6:	e4843783          	ld	a5,-440(s0)
    800059ea:	953e                	add	a0,a0,a5
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	0e6080e7          	jalr	230(ra) # 80002ad2 <fetchaddr>
    800059f4:	02054a63          	bltz	a0,80005a28 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800059f8:	e4043783          	ld	a5,-448(s0)
    800059fc:	c3b9                	beqz	a5,80005a42 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	0e4080e7          	jalr	228(ra) # 80000ae2 <kalloc>
    80005a06:	85aa                	mv	a1,a0
    80005a08:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a0e:	6605                	lui	a2,0x1
    80005a10:	e4043503          	ld	a0,-448(s0)
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	110080e7          	jalr	272(ra) # 80002b24 <fetchstr>
    80005a1c:	00054663          	bltz	a0,80005a28 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005a20:	0905                	addi	s2,s2,1
    80005a22:	09a1                	addi	s3,s3,8
    80005a24:	fb491de3          	bne	s2,s4,800059de <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a28:	f5040913          	addi	s2,s0,-176
    80005a2c:	6088                	ld	a0,0(s1)
    80005a2e:	c921                	beqz	a0,80005a7e <sys_exec+0xf6>
    kfree(argv[i]);
    80005a30:	ffffb097          	auipc	ra,0xffffb
    80005a34:	fb4080e7          	jalr	-76(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a38:	04a1                	addi	s1,s1,8
    80005a3a:	ff2499e3          	bne	s1,s2,80005a2c <sys_exec+0xa4>
  return -1;
    80005a3e:	557d                	li	a0,-1
    80005a40:	a081                	j	80005a80 <sys_exec+0xf8>
      argv[i] = 0;
    80005a42:	0009079b          	sext.w	a5,s2
    80005a46:	078e                	slli	a5,a5,0x3
    80005a48:	fd078793          	addi	a5,a5,-48
    80005a4c:	97a2                	add	a5,a5,s0
    80005a4e:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005a52:	e5040593          	addi	a1,s0,-432
    80005a56:	f5040513          	addi	a0,s0,-176
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	194080e7          	jalr	404(ra) # 80004bee <exec>
    80005a62:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a64:	f5040993          	addi	s3,s0,-176
    80005a68:	6088                	ld	a0,0(s1)
    80005a6a:	c901                	beqz	a0,80005a7a <sys_exec+0xf2>
    kfree(argv[i]);
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	f78080e7          	jalr	-136(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a74:	04a1                	addi	s1,s1,8
    80005a76:	ff3499e3          	bne	s1,s3,80005a68 <sys_exec+0xe0>
  return ret;
    80005a7a:	854a                	mv	a0,s2
    80005a7c:	a011                	j	80005a80 <sys_exec+0xf8>
  return -1;
    80005a7e:	557d                	li	a0,-1
}
    80005a80:	70fa                	ld	ra,440(sp)
    80005a82:	745a                	ld	s0,432(sp)
    80005a84:	74ba                	ld	s1,424(sp)
    80005a86:	791a                	ld	s2,416(sp)
    80005a88:	69fa                	ld	s3,408(sp)
    80005a8a:	6a5a                	ld	s4,400(sp)
    80005a8c:	6139                	addi	sp,sp,448
    80005a8e:	8082                	ret

0000000080005a90 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a90:	7139                	addi	sp,sp,-64
    80005a92:	fc06                	sd	ra,56(sp)
    80005a94:	f822                	sd	s0,48(sp)
    80005a96:	f426                	sd	s1,40(sp)
    80005a98:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	f0c080e7          	jalr	-244(ra) # 800019a6 <myproc>
    80005aa2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005aa4:	fd840593          	addi	a1,s0,-40
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	0e6080e7          	jalr	230(ra) # 80002b90 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ab2:	fc840593          	addi	a1,s0,-56
    80005ab6:	fd040513          	addi	a0,s0,-48
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	dea080e7          	jalr	-534(ra) # 800048a4 <pipealloc>
    return -1;
    80005ac2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ac4:	0c054463          	bltz	a0,80005b8c <sys_pipe+0xfc>
  fd0 = -1;
    80005ac8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005acc:	fd043503          	ld	a0,-48(s0)
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	524080e7          	jalr	1316(ra) # 80004ff4 <fdalloc>
    80005ad8:	fca42223          	sw	a0,-60(s0)
    80005adc:	08054b63          	bltz	a0,80005b72 <sys_pipe+0xe2>
    80005ae0:	fc843503          	ld	a0,-56(s0)
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	510080e7          	jalr	1296(ra) # 80004ff4 <fdalloc>
    80005aec:	fca42023          	sw	a0,-64(s0)
    80005af0:	06054863          	bltz	a0,80005b60 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005af4:	4691                	li	a3,4
    80005af6:	fc440613          	addi	a2,s0,-60
    80005afa:	fd843583          	ld	a1,-40(s0)
    80005afe:	68a8                	ld	a0,80(s1)
    80005b00:	ffffc097          	auipc	ra,0xffffc
    80005b04:	b66080e7          	jalr	-1178(ra) # 80001666 <copyout>
    80005b08:	02054063          	bltz	a0,80005b28 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b0c:	4691                	li	a3,4
    80005b0e:	fc040613          	addi	a2,s0,-64
    80005b12:	fd843583          	ld	a1,-40(s0)
    80005b16:	0591                	addi	a1,a1,4
    80005b18:	68a8                	ld	a0,80(s1)
    80005b1a:	ffffc097          	auipc	ra,0xffffc
    80005b1e:	b4c080e7          	jalr	-1204(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b22:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b24:	06055463          	bgez	a0,80005b8c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b28:	fc442783          	lw	a5,-60(s0)
    80005b2c:	07e9                	addi	a5,a5,26
    80005b2e:	078e                	slli	a5,a5,0x3
    80005b30:	97a6                	add	a5,a5,s1
    80005b32:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b36:	fc042783          	lw	a5,-64(s0)
    80005b3a:	07e9                	addi	a5,a5,26
    80005b3c:	078e                	slli	a5,a5,0x3
    80005b3e:	94be                	add	s1,s1,a5
    80005b40:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b44:	fd043503          	ld	a0,-48(s0)
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	a30080e7          	jalr	-1488(ra) # 80004578 <fileclose>
    fileclose(wf);
    80005b50:	fc843503          	ld	a0,-56(s0)
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	a24080e7          	jalr	-1500(ra) # 80004578 <fileclose>
    return -1;
    80005b5c:	57fd                	li	a5,-1
    80005b5e:	a03d                	j	80005b8c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b60:	fc442783          	lw	a5,-60(s0)
    80005b64:	0007c763          	bltz	a5,80005b72 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b68:	07e9                	addi	a5,a5,26
    80005b6a:	078e                	slli	a5,a5,0x3
    80005b6c:	97a6                	add	a5,a5,s1
    80005b6e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b72:	fd043503          	ld	a0,-48(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	a02080e7          	jalr	-1534(ra) # 80004578 <fileclose>
    fileclose(wf);
    80005b7e:	fc843503          	ld	a0,-56(s0)
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	9f6080e7          	jalr	-1546(ra) # 80004578 <fileclose>
    return -1;
    80005b8a:	57fd                	li	a5,-1
}
    80005b8c:	853e                	mv	a0,a5
    80005b8e:	70e2                	ld	ra,56(sp)
    80005b90:	7442                	ld	s0,48(sp)
    80005b92:	74a2                	ld	s1,40(sp)
    80005b94:	6121                	addi	sp,sp,64
    80005b96:	8082                	ret
	...

0000000080005ba0 <kernelvec>:
    80005ba0:	7111                	addi	sp,sp,-256
    80005ba2:	e006                	sd	ra,0(sp)
    80005ba4:	e40a                	sd	sp,8(sp)
    80005ba6:	e80e                	sd	gp,16(sp)
    80005ba8:	ec12                	sd	tp,24(sp)
    80005baa:	f016                	sd	t0,32(sp)
    80005bac:	f41a                	sd	t1,40(sp)
    80005bae:	f81e                	sd	t2,48(sp)
    80005bb0:	fc22                	sd	s0,56(sp)
    80005bb2:	e0a6                	sd	s1,64(sp)
    80005bb4:	e4aa                	sd	a0,72(sp)
    80005bb6:	e8ae                	sd	a1,80(sp)
    80005bb8:	ecb2                	sd	a2,88(sp)
    80005bba:	f0b6                	sd	a3,96(sp)
    80005bbc:	f4ba                	sd	a4,104(sp)
    80005bbe:	f8be                	sd	a5,112(sp)
    80005bc0:	fcc2                	sd	a6,120(sp)
    80005bc2:	e146                	sd	a7,128(sp)
    80005bc4:	e54a                	sd	s2,136(sp)
    80005bc6:	e94e                	sd	s3,144(sp)
    80005bc8:	ed52                	sd	s4,152(sp)
    80005bca:	f156                	sd	s5,160(sp)
    80005bcc:	f55a                	sd	s6,168(sp)
    80005bce:	f95e                	sd	s7,176(sp)
    80005bd0:	fd62                	sd	s8,184(sp)
    80005bd2:	e1e6                	sd	s9,192(sp)
    80005bd4:	e5ea                	sd	s10,200(sp)
    80005bd6:	e9ee                	sd	s11,208(sp)
    80005bd8:	edf2                	sd	t3,216(sp)
    80005bda:	f1f6                	sd	t4,224(sp)
    80005bdc:	f5fa                	sd	t5,232(sp)
    80005bde:	f9fe                	sd	t6,240(sp)
    80005be0:	dbffc0ef          	jal	ra,8000299e <kerneltrap>
    80005be4:	6082                	ld	ra,0(sp)
    80005be6:	6122                	ld	sp,8(sp)
    80005be8:	61c2                	ld	gp,16(sp)
    80005bea:	7282                	ld	t0,32(sp)
    80005bec:	7322                	ld	t1,40(sp)
    80005bee:	73c2                	ld	t2,48(sp)
    80005bf0:	7462                	ld	s0,56(sp)
    80005bf2:	6486                	ld	s1,64(sp)
    80005bf4:	6526                	ld	a0,72(sp)
    80005bf6:	65c6                	ld	a1,80(sp)
    80005bf8:	6666                	ld	a2,88(sp)
    80005bfa:	7686                	ld	a3,96(sp)
    80005bfc:	7726                	ld	a4,104(sp)
    80005bfe:	77c6                	ld	a5,112(sp)
    80005c00:	7866                	ld	a6,120(sp)
    80005c02:	688a                	ld	a7,128(sp)
    80005c04:	692a                	ld	s2,136(sp)
    80005c06:	69ca                	ld	s3,144(sp)
    80005c08:	6a6a                	ld	s4,152(sp)
    80005c0a:	7a8a                	ld	s5,160(sp)
    80005c0c:	7b2a                	ld	s6,168(sp)
    80005c0e:	7bca                	ld	s7,176(sp)
    80005c10:	7c6a                	ld	s8,184(sp)
    80005c12:	6c8e                	ld	s9,192(sp)
    80005c14:	6d2e                	ld	s10,200(sp)
    80005c16:	6dce                	ld	s11,208(sp)
    80005c18:	6e6e                	ld	t3,216(sp)
    80005c1a:	7e8e                	ld	t4,224(sp)
    80005c1c:	7f2e                	ld	t5,232(sp)
    80005c1e:	7fce                	ld	t6,240(sp)
    80005c20:	6111                	addi	sp,sp,256
    80005c22:	10200073          	sret
    80005c26:	00000013          	nop
    80005c2a:	00000013          	nop
    80005c2e:	0001                	nop

0000000080005c30 <timervec>:
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	e10c                	sd	a1,0(a0)
    80005c36:	e510                	sd	a2,8(a0)
    80005c38:	e914                	sd	a3,16(a0)
    80005c3a:	6d0c                	ld	a1,24(a0)
    80005c3c:	7110                	ld	a2,32(a0)
    80005c3e:	6194                	ld	a3,0(a1)
    80005c40:	96b2                	add	a3,a3,a2
    80005c42:	e194                	sd	a3,0(a1)
    80005c44:	4589                	li	a1,2
    80005c46:	14459073          	csrw	sip,a1
    80005c4a:	6914                	ld	a3,16(a0)
    80005c4c:	6510                	ld	a2,8(a0)
    80005c4e:	610c                	ld	a1,0(a0)
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	30200073          	mret
	...

0000000080005c5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c5a:	1141                	addi	sp,sp,-16
    80005c5c:	e422                	sd	s0,8(sp)
    80005c5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c60:	0c0007b7          	lui	a5,0xc000
    80005c64:	4705                	li	a4,1
    80005c66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c68:	c3d8                	sw	a4,4(a5)
}
    80005c6a:	6422                	ld	s0,8(sp)
    80005c6c:	0141                	addi	sp,sp,16
    80005c6e:	8082                	ret

0000000080005c70 <plicinithart>:

void
plicinithart(void)
{
    80005c70:	1141                	addi	sp,sp,-16
    80005c72:	e406                	sd	ra,8(sp)
    80005c74:	e022                	sd	s0,0(sp)
    80005c76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	d02080e7          	jalr	-766(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c80:	0085171b          	slliw	a4,a0,0x8
    80005c84:	0c0027b7          	lui	a5,0xc002
    80005c88:	97ba                	add	a5,a5,a4
    80005c8a:	40200713          	li	a4,1026
    80005c8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c92:	00d5151b          	slliw	a0,a0,0xd
    80005c96:	0c2017b7          	lui	a5,0xc201
    80005c9a:	97aa                	add	a5,a5,a0
    80005c9c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ca0:	60a2                	ld	ra,8(sp)
    80005ca2:	6402                	ld	s0,0(sp)
    80005ca4:	0141                	addi	sp,sp,16
    80005ca6:	8082                	ret

0000000080005ca8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ca8:	1141                	addi	sp,sp,-16
    80005caa:	e406                	sd	ra,8(sp)
    80005cac:	e022                	sd	s0,0(sp)
    80005cae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	cca080e7          	jalr	-822(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cb8:	00d5151b          	slliw	a0,a0,0xd
    80005cbc:	0c2017b7          	lui	a5,0xc201
    80005cc0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cc2:	43c8                	lw	a0,4(a5)
    80005cc4:	60a2                	ld	ra,8(sp)
    80005cc6:	6402                	ld	s0,0(sp)
    80005cc8:	0141                	addi	sp,sp,16
    80005cca:	8082                	ret

0000000080005ccc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ccc:	1101                	addi	sp,sp,-32
    80005cce:	ec06                	sd	ra,24(sp)
    80005cd0:	e822                	sd	s0,16(sp)
    80005cd2:	e426                	sd	s1,8(sp)
    80005cd4:	1000                	addi	s0,sp,32
    80005cd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	ca2080e7          	jalr	-862(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ce0:	00d5151b          	slliw	a0,a0,0xd
    80005ce4:	0c2017b7          	lui	a5,0xc201
    80005ce8:	97aa                	add	a5,a5,a0
    80005cea:	c3c4                	sw	s1,4(a5)
}
    80005cec:	60e2                	ld	ra,24(sp)
    80005cee:	6442                	ld	s0,16(sp)
    80005cf0:	64a2                	ld	s1,8(sp)
    80005cf2:	6105                	addi	sp,sp,32
    80005cf4:	8082                	ret

0000000080005cf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cf6:	1141                	addi	sp,sp,-16
    80005cf8:	e406                	sd	ra,8(sp)
    80005cfa:	e022                	sd	s0,0(sp)
    80005cfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cfe:	479d                	li	a5,7
    80005d00:	04a7cc63          	blt	a5,a0,80005d58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d04:	0001c797          	auipc	a5,0x1c
    80005d08:	f8c78793          	addi	a5,a5,-116 # 80021c90 <disk>
    80005d0c:	97aa                	add	a5,a5,a0
    80005d0e:	0187c783          	lbu	a5,24(a5)
    80005d12:	ebb9                	bnez	a5,80005d68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d14:	00451693          	slli	a3,a0,0x4
    80005d18:	0001c797          	auipc	a5,0x1c
    80005d1c:	f7878793          	addi	a5,a5,-136 # 80021c90 <disk>
    80005d20:	6398                	ld	a4,0(a5)
    80005d22:	9736                	add	a4,a4,a3
    80005d24:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d28:	6398                	ld	a4,0(a5)
    80005d2a:	9736                	add	a4,a4,a3
    80005d2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	4705                	li	a4,1
    80005d3c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005d40:	0001c517          	auipc	a0,0x1c
    80005d44:	f6850513          	addi	a0,a0,-152 # 80021ca8 <disk+0x18>
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	36a080e7          	jalr	874(ra) # 800020b2 <wakeup>
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret
    panic("free_desc 1");
    80005d58:	00003517          	auipc	a0,0x3
    80005d5c:	a7050513          	addi	a0,a0,-1424 # 800087c8 <syscalls+0x310>
    80005d60:	ffffa097          	auipc	ra,0xffffa
    80005d64:	7dc080e7          	jalr	2012(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005d68:	00003517          	auipc	a0,0x3
    80005d6c:	a7050513          	addi	a0,a0,-1424 # 800087d8 <syscalls+0x320>
    80005d70:	ffffa097          	auipc	ra,0xffffa
    80005d74:	7cc080e7          	jalr	1996(ra) # 8000053c <panic>

0000000080005d78 <virtio_disk_init>:
{
    80005d78:	1101                	addi	sp,sp,-32
    80005d7a:	ec06                	sd	ra,24(sp)
    80005d7c:	e822                	sd	s0,16(sp)
    80005d7e:	e426                	sd	s1,8(sp)
    80005d80:	e04a                	sd	s2,0(sp)
    80005d82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d84:	00003597          	auipc	a1,0x3
    80005d88:	a6458593          	addi	a1,a1,-1436 # 800087e8 <syscalls+0x330>
    80005d8c:	0001c517          	auipc	a0,0x1c
    80005d90:	02c50513          	addi	a0,a0,44 # 80021db8 <disk+0x128>
    80005d94:	ffffb097          	auipc	ra,0xffffb
    80005d98:	dae080e7          	jalr	-594(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d9c:	100017b7          	lui	a5,0x10001
    80005da0:	4398                	lw	a4,0(a5)
    80005da2:	2701                	sext.w	a4,a4
    80005da4:	747277b7          	lui	a5,0x74727
    80005da8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dac:	14f71b63          	bne	a4,a5,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005db0:	100017b7          	lui	a5,0x10001
    80005db4:	43dc                	lw	a5,4(a5)
    80005db6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db8:	4709                	li	a4,2
    80005dba:	14e79463          	bne	a5,a4,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	479c                	lw	a5,8(a5)
    80005dc4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005dc6:	12e79e63          	bne	a5,a4,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dca:	100017b7          	lui	a5,0x10001
    80005dce:	47d8                	lw	a4,12(a5)
    80005dd0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dd2:	554d47b7          	lui	a5,0x554d4
    80005dd6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dda:	12f71463          	bne	a4,a5,80005f02 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dde:	100017b7          	lui	a5,0x10001
    80005de2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de6:	4705                	li	a4,1
    80005de8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dea:	470d                	li	a4,3
    80005dec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005df0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005df4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc98f>
    80005df8:	8f75                	and	a4,a4,a3
    80005dfa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dfc:	472d                	li	a4,11
    80005dfe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e00:	5bbc                	lw	a5,112(a5)
    80005e02:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e06:	8ba1                	andi	a5,a5,8
    80005e08:	10078563          	beqz	a5,80005f12 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e14:	43fc                	lw	a5,68(a5)
    80005e16:	2781                	sext.w	a5,a5
    80005e18:	10079563          	bnez	a5,80005f22 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	5bdc                	lw	a5,52(a5)
    80005e22:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e24:	10078763          	beqz	a5,80005f32 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e28:	471d                	li	a4,7
    80005e2a:	10f77c63          	bgeu	a4,a5,80005f42 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	cb4080e7          	jalr	-844(ra) # 80000ae2 <kalloc>
    80005e36:	0001c497          	auipc	s1,0x1c
    80005e3a:	e5a48493          	addi	s1,s1,-422 # 80021c90 <disk>
    80005e3e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	ca2080e7          	jalr	-862(ra) # 80000ae2 <kalloc>
    80005e48:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	c98080e7          	jalr	-872(ra) # 80000ae2 <kalloc>
    80005e52:	87aa                	mv	a5,a0
    80005e54:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e56:	6088                	ld	a0,0(s1)
    80005e58:	cd6d                	beqz	a0,80005f52 <virtio_disk_init+0x1da>
    80005e5a:	0001c717          	auipc	a4,0x1c
    80005e5e:	e3e73703          	ld	a4,-450(a4) # 80021c98 <disk+0x8>
    80005e62:	cb65                	beqz	a4,80005f52 <virtio_disk_init+0x1da>
    80005e64:	c7fd                	beqz	a5,80005f52 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e66:	6605                	lui	a2,0x1
    80005e68:	4581                	li	a1,0
    80005e6a:	ffffb097          	auipc	ra,0xffffb
    80005e6e:	e64080e7          	jalr	-412(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e72:	0001c497          	auipc	s1,0x1c
    80005e76:	e1e48493          	addi	s1,s1,-482 # 80021c90 <disk>
    80005e7a:	6605                	lui	a2,0x1
    80005e7c:	4581                	li	a1,0
    80005e7e:	6488                	ld	a0,8(s1)
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	e4e080e7          	jalr	-434(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	4581                	li	a1,0
    80005e8c:	6888                	ld	a0,16(s1)
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	e40080e7          	jalr	-448(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	4721                	li	a4,8
    80005e9c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e9e:	4098                	lw	a4,0(s1)
    80005ea0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005ea4:	40d8                	lw	a4,4(s1)
    80005ea6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005eaa:	6498                	ld	a4,8(s1)
    80005eac:	0007069b          	sext.w	a3,a4
    80005eb0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005eb4:	9701                	srai	a4,a4,0x20
    80005eb6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005eba:	6898                	ld	a4,16(s1)
    80005ebc:	0007069b          	sext.w	a3,a4
    80005ec0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ec4:	9701                	srai	a4,a4,0x20
    80005ec6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eca:	4705                	li	a4,1
    80005ecc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005ece:	00e48c23          	sb	a4,24(s1)
    80005ed2:	00e48ca3          	sb	a4,25(s1)
    80005ed6:	00e48d23          	sb	a4,26(s1)
    80005eda:	00e48da3          	sb	a4,27(s1)
    80005ede:	00e48e23          	sb	a4,28(s1)
    80005ee2:	00e48ea3          	sb	a4,29(s1)
    80005ee6:	00e48f23          	sb	a4,30(s1)
    80005eea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005eee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef2:	0727a823          	sw	s2,112(a5)
}
    80005ef6:	60e2                	ld	ra,24(sp)
    80005ef8:	6442                	ld	s0,16(sp)
    80005efa:	64a2                	ld	s1,8(sp)
    80005efc:	6902                	ld	s2,0(sp)
    80005efe:	6105                	addi	sp,sp,32
    80005f00:	8082                	ret
    panic("could not find virtio disk");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	8f650513          	addi	a0,a0,-1802 # 800087f8 <syscalls+0x340>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	632080e7          	jalr	1586(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	90650513          	addi	a0,a0,-1786 # 80008818 <syscalls+0x360>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	622080e7          	jalr	1570(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	91650513          	addi	a0,a0,-1770 # 80008838 <syscalls+0x380>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	612080e7          	jalr	1554(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	92650513          	addi	a0,a0,-1754 # 80008858 <syscalls+0x3a0>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	602080e7          	jalr	1538(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	93650513          	addi	a0,a0,-1738 # 80008878 <syscalls+0x3c0>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f2080e7          	jalr	1522(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	94650513          	addi	a0,a0,-1722 # 80008898 <syscalls+0x3e0>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e2080e7          	jalr	1506(ra) # 8000053c <panic>

0000000080005f62 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f62:	7159                	addi	sp,sp,-112
    80005f64:	f486                	sd	ra,104(sp)
    80005f66:	f0a2                	sd	s0,96(sp)
    80005f68:	eca6                	sd	s1,88(sp)
    80005f6a:	e8ca                	sd	s2,80(sp)
    80005f6c:	e4ce                	sd	s3,72(sp)
    80005f6e:	e0d2                	sd	s4,64(sp)
    80005f70:	fc56                	sd	s5,56(sp)
    80005f72:	f85a                	sd	s6,48(sp)
    80005f74:	f45e                	sd	s7,40(sp)
    80005f76:	f062                	sd	s8,32(sp)
    80005f78:	ec66                	sd	s9,24(sp)
    80005f7a:	e86a                	sd	s10,16(sp)
    80005f7c:	1880                	addi	s0,sp,112
    80005f7e:	8a2a                	mv	s4,a0
    80005f80:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f82:	00c52c83          	lw	s9,12(a0)
    80005f86:	001c9c9b          	slliw	s9,s9,0x1
    80005f8a:	1c82                	slli	s9,s9,0x20
    80005f8c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f90:	0001c517          	auipc	a0,0x1c
    80005f94:	e2850513          	addi	a0,a0,-472 # 80021db8 <disk+0x128>
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	c3a080e7          	jalr	-966(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80005fa0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005fa2:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fa4:	0001cb17          	auipc	s6,0x1c
    80005fa8:	cecb0b13          	addi	s6,s6,-788 # 80021c90 <disk>
  for(int i = 0; i < 3; i++){
    80005fac:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fae:	0001cc17          	auipc	s8,0x1c
    80005fb2:	e0ac0c13          	addi	s8,s8,-502 # 80021db8 <disk+0x128>
    80005fb6:	a095                	j	8000601a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005fb8:	00fb0733          	add	a4,s6,a5
    80005fbc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fc0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005fc2:	0207c563          	bltz	a5,80005fec <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80005fc6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80005fc8:	0591                	addi	a1,a1,4
    80005fca:	05560d63          	beq	a2,s5,80006024 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005fce:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005fd0:	0001c717          	auipc	a4,0x1c
    80005fd4:	cc070713          	addi	a4,a4,-832 # 80021c90 <disk>
    80005fd8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005fda:	01874683          	lbu	a3,24(a4)
    80005fde:	fee9                	bnez	a3,80005fb8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80005fe0:	2785                	addiw	a5,a5,1
    80005fe2:	0705                	addi	a4,a4,1
    80005fe4:	fe979be3          	bne	a5,s1,80005fda <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80005fe8:	57fd                	li	a5,-1
    80005fea:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005fec:	00c05e63          	blez	a2,80006008 <virtio_disk_rw+0xa6>
    80005ff0:	060a                	slli	a2,a2,0x2
    80005ff2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005ff6:	0009a503          	lw	a0,0(s3)
    80005ffa:	00000097          	auipc	ra,0x0
    80005ffe:	cfc080e7          	jalr	-772(ra) # 80005cf6 <free_desc>
      for(int j = 0; j < i; j++)
    80006002:	0991                	addi	s3,s3,4
    80006004:	ffa999e3          	bne	s3,s10,80005ff6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	85e2                	mv	a1,s8
    8000600a:	0001c517          	auipc	a0,0x1c
    8000600e:	c9e50513          	addi	a0,a0,-866 # 80021ca8 <disk+0x18>
    80006012:	ffffc097          	auipc	ra,0xffffc
    80006016:	03c080e7          	jalr	60(ra) # 8000204e <sleep>
  for(int i = 0; i < 3; i++){
    8000601a:	f9040993          	addi	s3,s0,-112
{
    8000601e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006020:	864a                	mv	a2,s2
    80006022:	b775                	j	80005fce <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006024:	f9042503          	lw	a0,-112(s0)
    80006028:	00a50713          	addi	a4,a0,10
    8000602c:	0712                	slli	a4,a4,0x4

  if(write)
    8000602e:	0001c797          	auipc	a5,0x1c
    80006032:	c6278793          	addi	a5,a5,-926 # 80021c90 <disk>
    80006036:	00e786b3          	add	a3,a5,a4
    8000603a:	01703633          	snez	a2,s7
    8000603e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006040:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006044:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006048:	f6070613          	addi	a2,a4,-160
    8000604c:	6394                	ld	a3,0(a5)
    8000604e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006050:	00870593          	addi	a1,a4,8
    80006054:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006056:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006058:	0007b803          	ld	a6,0(a5)
    8000605c:	9642                	add	a2,a2,a6
    8000605e:	46c1                	li	a3,16
    80006060:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006062:	4585                	li	a1,1
    80006064:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006068:	f9442683          	lw	a3,-108(s0)
    8000606c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006070:	0692                	slli	a3,a3,0x4
    80006072:	9836                	add	a6,a6,a3
    80006074:	058a0613          	addi	a2,s4,88
    80006078:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000607c:	0007b803          	ld	a6,0(a5)
    80006080:	96c2                	add	a3,a3,a6
    80006082:	40000613          	li	a2,1024
    80006086:	c690                	sw	a2,8(a3)
  if(write)
    80006088:	001bb613          	seqz	a2,s7
    8000608c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006090:	00166613          	ori	a2,a2,1
    80006094:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006098:	f9842603          	lw	a2,-104(s0)
    8000609c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060a0:	00250693          	addi	a3,a0,2
    800060a4:	0692                	slli	a3,a3,0x4
    800060a6:	96be                	add	a3,a3,a5
    800060a8:	58fd                	li	a7,-1
    800060aa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060ae:	0612                	slli	a2,a2,0x4
    800060b0:	9832                	add	a6,a6,a2
    800060b2:	f9070713          	addi	a4,a4,-112
    800060b6:	973e                	add	a4,a4,a5
    800060b8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800060bc:	6398                	ld	a4,0(a5)
    800060be:	9732                	add	a4,a4,a2
    800060c0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060c2:	4609                	li	a2,2
    800060c4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800060c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060cc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800060d0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060d4:	6794                	ld	a3,8(a5)
    800060d6:	0026d703          	lhu	a4,2(a3)
    800060da:	8b1d                	andi	a4,a4,7
    800060dc:	0706                	slli	a4,a4,0x1
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800060e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060e8:	6798                	ld	a4,8(a5)
    800060ea:	00275783          	lhu	a5,2(a4)
    800060ee:	2785                	addiw	a5,a5,1
    800060f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006100:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006104:	0001c917          	auipc	s2,0x1c
    80006108:	cb490913          	addi	s2,s2,-844 # 80021db8 <disk+0x128>
  while(b->disk == 1) {
    8000610c:	4485                	li	s1,1
    8000610e:	00b79c63          	bne	a5,a1,80006126 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006112:	85ca                	mv	a1,s2
    80006114:	8552                	mv	a0,s4
    80006116:	ffffc097          	auipc	ra,0xffffc
    8000611a:	f38080e7          	jalr	-200(ra) # 8000204e <sleep>
  while(b->disk == 1) {
    8000611e:	004a2783          	lw	a5,4(s4)
    80006122:	fe9788e3          	beq	a5,s1,80006112 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006126:	f9042903          	lw	s2,-112(s0)
    8000612a:	00290713          	addi	a4,s2,2
    8000612e:	0712                	slli	a4,a4,0x4
    80006130:	0001c797          	auipc	a5,0x1c
    80006134:	b6078793          	addi	a5,a5,-1184 # 80021c90 <disk>
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000613e:	0001c997          	auipc	s3,0x1c
    80006142:	b5298993          	addi	s3,s3,-1198 # 80021c90 <disk>
    80006146:	00491713          	slli	a4,s2,0x4
    8000614a:	0009b783          	ld	a5,0(s3)
    8000614e:	97ba                	add	a5,a5,a4
    80006150:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006154:	854a                	mv	a0,s2
    80006156:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000615a:	00000097          	auipc	ra,0x0
    8000615e:	b9c080e7          	jalr	-1124(ra) # 80005cf6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006162:	8885                	andi	s1,s1,1
    80006164:	f0ed                	bnez	s1,80006146 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006166:	0001c517          	auipc	a0,0x1c
    8000616a:	c5250513          	addi	a0,a0,-942 # 80021db8 <disk+0x128>
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	b18080e7          	jalr	-1256(ra) # 80000c86 <release>
}
    80006176:	70a6                	ld	ra,104(sp)
    80006178:	7406                	ld	s0,96(sp)
    8000617a:	64e6                	ld	s1,88(sp)
    8000617c:	6946                	ld	s2,80(sp)
    8000617e:	69a6                	ld	s3,72(sp)
    80006180:	6a06                	ld	s4,64(sp)
    80006182:	7ae2                	ld	s5,56(sp)
    80006184:	7b42                	ld	s6,48(sp)
    80006186:	7ba2                	ld	s7,40(sp)
    80006188:	7c02                	ld	s8,32(sp)
    8000618a:	6ce2                	ld	s9,24(sp)
    8000618c:	6d42                	ld	s10,16(sp)
    8000618e:	6165                	addi	sp,sp,112
    80006190:	8082                	ret

0000000080006192 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006192:	1101                	addi	sp,sp,-32
    80006194:	ec06                	sd	ra,24(sp)
    80006196:	e822                	sd	s0,16(sp)
    80006198:	e426                	sd	s1,8(sp)
    8000619a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000619c:	0001c497          	auipc	s1,0x1c
    800061a0:	af448493          	addi	s1,s1,-1292 # 80021c90 <disk>
    800061a4:	0001c517          	auipc	a0,0x1c
    800061a8:	c1450513          	addi	a0,a0,-1004 # 80021db8 <disk+0x128>
    800061ac:	ffffb097          	auipc	ra,0xffffb
    800061b0:	a26080e7          	jalr	-1498(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061b4:	10001737          	lui	a4,0x10001
    800061b8:	533c                	lw	a5,96(a4)
    800061ba:	8b8d                	andi	a5,a5,3
    800061bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061c2:	689c                	ld	a5,16(s1)
    800061c4:	0204d703          	lhu	a4,32(s1)
    800061c8:	0027d783          	lhu	a5,2(a5)
    800061cc:	04f70863          	beq	a4,a5,8000621c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800061d0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061d4:	6898                	ld	a4,16(s1)
    800061d6:	0204d783          	lhu	a5,32(s1)
    800061da:	8b9d                	andi	a5,a5,7
    800061dc:	078e                	slli	a5,a5,0x3
    800061de:	97ba                	add	a5,a5,a4
    800061e0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061e2:	00278713          	addi	a4,a5,2
    800061e6:	0712                	slli	a4,a4,0x4
    800061e8:	9726                	add	a4,a4,s1
    800061ea:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800061ee:	e721                	bnez	a4,80006236 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061f0:	0789                	addi	a5,a5,2
    800061f2:	0792                	slli	a5,a5,0x4
    800061f4:	97a6                	add	a5,a5,s1
    800061f6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800061f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061fc:	ffffc097          	auipc	ra,0xffffc
    80006200:	eb6080e7          	jalr	-330(ra) # 800020b2 <wakeup>

    disk.used_idx += 1;
    80006204:	0204d783          	lhu	a5,32(s1)
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	17c2                	slli	a5,a5,0x30
    8000620c:	93c1                	srli	a5,a5,0x30
    8000620e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006212:	6898                	ld	a4,16(s1)
    80006214:	00275703          	lhu	a4,2(a4)
    80006218:	faf71ce3          	bne	a4,a5,800061d0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000621c:	0001c517          	auipc	a0,0x1c
    80006220:	b9c50513          	addi	a0,a0,-1124 # 80021db8 <disk+0x128>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	a62080e7          	jalr	-1438(ra) # 80000c86 <release>
}
    8000622c:	60e2                	ld	ra,24(sp)
    8000622e:	6442                	ld	s0,16(sp)
    80006230:	64a2                	ld	s1,8(sp)
    80006232:	6105                	addi	sp,sp,32
    80006234:	8082                	ret
      panic("virtio_disk_intr status");
    80006236:	00002517          	auipc	a0,0x2
    8000623a:	67a50513          	addi	a0,a0,1658 # 800088b0 <syscalls+0x3f8>
    8000623e:	ffffa097          	auipc	ra,0xffffa
    80006242:	2fe080e7          	jalr	766(ra) # 8000053c <panic>
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
