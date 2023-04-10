
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include <user/user.h>

int main(void) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    prcinf();
   8:	00000097          	auipc	ra,0x0
   c:	340080e7          	jalr	832(ra) # 348 <prcinf>
    return 0;
  10:	4501                	li	a0,0
  12:	60a2                	ld	ra,8(sp)
  14:	6402                	ld	s0,0(sp)
  16:	0141                	addi	sp,sp,16
  18:	8082                	ret

000000000000001a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  1a:	1141                	addi	sp,sp,-16
  1c:	e406                	sd	ra,8(sp)
  1e:	e022                	sd	s0,0(sp)
  20:	0800                	addi	s0,sp,16
  extern int main();
  main();
  22:	00000097          	auipc	ra,0x0
  26:	fde080e7          	jalr	-34(ra) # 0 <main>
  exit(0);
  2a:	4501                	li	a0,0
  2c:	00000097          	auipc	ra,0x0
  30:	274080e7          	jalr	628(ra) # 2a0 <exit>

0000000000000034 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  34:	1141                	addi	sp,sp,-16
  36:	e422                	sd	s0,8(sp)
  38:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  3a:	87aa                	mv	a5,a0
  3c:	0585                	addi	a1,a1,1
  3e:	0785                	addi	a5,a5,1
  40:	fff5c703          	lbu	a4,-1(a1)
  44:	fee78fa3          	sb	a4,-1(a5)
  48:	fb75                	bnez	a4,3c <strcpy+0x8>
    ;
  return os;
}
  4a:	6422                	ld	s0,8(sp)
  4c:	0141                	addi	sp,sp,16
  4e:	8082                	ret

0000000000000050 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  50:	1141                	addi	sp,sp,-16
  52:	e422                	sd	s0,8(sp)
  54:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  56:	00054783          	lbu	a5,0(a0)
  5a:	cb91                	beqz	a5,6e <strcmp+0x1e>
  5c:	0005c703          	lbu	a4,0(a1)
  60:	00f71763          	bne	a4,a5,6e <strcmp+0x1e>
    p++, q++;
  64:	0505                	addi	a0,a0,1
  66:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  68:	00054783          	lbu	a5,0(a0)
  6c:	fbe5                	bnez	a5,5c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  6e:	0005c503          	lbu	a0,0(a1)
}
  72:	40a7853b          	subw	a0,a5,a0
  76:	6422                	ld	s0,8(sp)
  78:	0141                	addi	sp,sp,16
  7a:	8082                	ret

000000000000007c <strlen>:

uint
strlen(const char *s)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  82:	00054783          	lbu	a5,0(a0)
  86:	cf91                	beqz	a5,a2 <strlen+0x26>
  88:	0505                	addi	a0,a0,1
  8a:	87aa                	mv	a5,a0
  8c:	86be                	mv	a3,a5
  8e:	0785                	addi	a5,a5,1
  90:	fff7c703          	lbu	a4,-1(a5)
  94:	ff65                	bnez	a4,8c <strlen+0x10>
  96:	40a6853b          	subw	a0,a3,a0
  9a:	2505                	addiw	a0,a0,1
    ;
  return n;
}
  9c:	6422                	ld	s0,8(sp)
  9e:	0141                	addi	sp,sp,16
  a0:	8082                	ret
  for(n = 0; s[n]; n++)
  a2:	4501                	li	a0,0
  a4:	bfe5                	j	9c <strlen+0x20>

00000000000000a6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  a6:	1141                	addi	sp,sp,-16
  a8:	e422                	sd	s0,8(sp)
  aa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ac:	ca19                	beqz	a2,c2 <memset+0x1c>
  ae:	87aa                	mv	a5,a0
  b0:	1602                	slli	a2,a2,0x20
  b2:	9201                	srli	a2,a2,0x20
  b4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  b8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  bc:	0785                	addi	a5,a5,1
  be:	fee79de3          	bne	a5,a4,b8 <memset+0x12>
  }
  return dst;
}
  c2:	6422                	ld	s0,8(sp)
  c4:	0141                	addi	sp,sp,16
  c6:	8082                	ret

00000000000000c8 <strchr>:

char*
strchr(const char *s, char c)
{
  c8:	1141                	addi	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	addi	s0,sp,16
  for(; *s; s++)
  ce:	00054783          	lbu	a5,0(a0)
  d2:	cb99                	beqz	a5,e8 <strchr+0x20>
    if(*s == c)
  d4:	00f58763          	beq	a1,a5,e2 <strchr+0x1a>
  for(; *s; s++)
  d8:	0505                	addi	a0,a0,1
  da:	00054783          	lbu	a5,0(a0)
  de:	fbfd                	bnez	a5,d4 <strchr+0xc>
      return (char*)s;
  return 0;
  e0:	4501                	li	a0,0
}
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	addi	sp,sp,16
  e6:	8082                	ret
  return 0;
  e8:	4501                	li	a0,0
  ea:	bfe5                	j	e2 <strchr+0x1a>

00000000000000ec <gets>:

char*
gets(char *buf, int max)
{
  ec:	711d                	addi	sp,sp,-96
  ee:	ec86                	sd	ra,88(sp)
  f0:	e8a2                	sd	s0,80(sp)
  f2:	e4a6                	sd	s1,72(sp)
  f4:	e0ca                	sd	s2,64(sp)
  f6:	fc4e                	sd	s3,56(sp)
  f8:	f852                	sd	s4,48(sp)
  fa:	f456                	sd	s5,40(sp)
  fc:	f05a                	sd	s6,32(sp)
  fe:	ec5e                	sd	s7,24(sp)
 100:	1080                	addi	s0,sp,96
 102:	8baa                	mv	s7,a0
 104:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 106:	892a                	mv	s2,a0
 108:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 10a:	4aa9                	li	s5,10
 10c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 10e:	89a6                	mv	s3,s1
 110:	2485                	addiw	s1,s1,1
 112:	0344d863          	bge	s1,s4,142 <gets+0x56>
    cc = read(0, &c, 1);
 116:	4605                	li	a2,1
 118:	faf40593          	addi	a1,s0,-81
 11c:	4501                	li	a0,0
 11e:	00000097          	auipc	ra,0x0
 122:	19a080e7          	jalr	410(ra) # 2b8 <read>
    if(cc < 1)
 126:	00a05e63          	blez	a0,142 <gets+0x56>
    buf[i++] = c;
 12a:	faf44783          	lbu	a5,-81(s0)
 12e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 132:	01578763          	beq	a5,s5,140 <gets+0x54>
 136:	0905                	addi	s2,s2,1
 138:	fd679be3          	bne	a5,s6,10e <gets+0x22>
  for(i=0; i+1 < max; ){
 13c:	89a6                	mv	s3,s1
 13e:	a011                	j	142 <gets+0x56>
 140:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 142:	99de                	add	s3,s3,s7
 144:	00098023          	sb	zero,0(s3)
  return buf;
}
 148:	855e                	mv	a0,s7
 14a:	60e6                	ld	ra,88(sp)
 14c:	6446                	ld	s0,80(sp)
 14e:	64a6                	ld	s1,72(sp)
 150:	6906                	ld	s2,64(sp)
 152:	79e2                	ld	s3,56(sp)
 154:	7a42                	ld	s4,48(sp)
 156:	7aa2                	ld	s5,40(sp)
 158:	7b02                	ld	s6,32(sp)
 15a:	6be2                	ld	s7,24(sp)
 15c:	6125                	addi	sp,sp,96
 15e:	8082                	ret

0000000000000160 <stat>:

int
stat(const char *n, struct stat *st)
{
 160:	1101                	addi	sp,sp,-32
 162:	ec06                	sd	ra,24(sp)
 164:	e822                	sd	s0,16(sp)
 166:	e426                	sd	s1,8(sp)
 168:	e04a                	sd	s2,0(sp)
 16a:	1000                	addi	s0,sp,32
 16c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 16e:	4581                	li	a1,0
 170:	00000097          	auipc	ra,0x0
 174:	170080e7          	jalr	368(ra) # 2e0 <open>
  if(fd < 0)
 178:	02054563          	bltz	a0,1a2 <stat+0x42>
 17c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 17e:	85ca                	mv	a1,s2
 180:	00000097          	auipc	ra,0x0
 184:	178080e7          	jalr	376(ra) # 2f8 <fstat>
 188:	892a                	mv	s2,a0
  close(fd);
 18a:	8526                	mv	a0,s1
 18c:	00000097          	auipc	ra,0x0
 190:	13c080e7          	jalr	316(ra) # 2c8 <close>
  return r;
}
 194:	854a                	mv	a0,s2
 196:	60e2                	ld	ra,24(sp)
 198:	6442                	ld	s0,16(sp)
 19a:	64a2                	ld	s1,8(sp)
 19c:	6902                	ld	s2,0(sp)
 19e:	6105                	addi	sp,sp,32
 1a0:	8082                	ret
    return -1;
 1a2:	597d                	li	s2,-1
 1a4:	bfc5                	j	194 <stat+0x34>

00000000000001a6 <atoi>:

int
atoi(const char *s)
{
 1a6:	1141                	addi	sp,sp,-16
 1a8:	e422                	sd	s0,8(sp)
 1aa:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ac:	00054683          	lbu	a3,0(a0)
 1b0:	fd06879b          	addiw	a5,a3,-48
 1b4:	0ff7f793          	zext.b	a5,a5
 1b8:	4625                	li	a2,9
 1ba:	02f66863          	bltu	a2,a5,1ea <atoi+0x44>
 1be:	872a                	mv	a4,a0
  n = 0;
 1c0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1c2:	0705                	addi	a4,a4,1
 1c4:	0025179b          	slliw	a5,a0,0x2
 1c8:	9fa9                	addw	a5,a5,a0
 1ca:	0017979b          	slliw	a5,a5,0x1
 1ce:	9fb5                	addw	a5,a5,a3
 1d0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1d4:	00074683          	lbu	a3,0(a4)
 1d8:	fd06879b          	addiw	a5,a3,-48
 1dc:	0ff7f793          	zext.b	a5,a5
 1e0:	fef671e3          	bgeu	a2,a5,1c2 <atoi+0x1c>
  return n;
}
 1e4:	6422                	ld	s0,8(sp)
 1e6:	0141                	addi	sp,sp,16
 1e8:	8082                	ret
  n = 0;
 1ea:	4501                	li	a0,0
 1ec:	bfe5                	j	1e4 <atoi+0x3e>

00000000000001ee <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1f4:	02b57463          	bgeu	a0,a1,21c <memmove+0x2e>
    while(n-- > 0)
 1f8:	00c05f63          	blez	a2,216 <memmove+0x28>
 1fc:	1602                	slli	a2,a2,0x20
 1fe:	9201                	srli	a2,a2,0x20
 200:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 204:	872a                	mv	a4,a0
      *dst++ = *src++;
 206:	0585                	addi	a1,a1,1
 208:	0705                	addi	a4,a4,1
 20a:	fff5c683          	lbu	a3,-1(a1)
 20e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 212:	fee79ae3          	bne	a5,a4,206 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 216:	6422                	ld	s0,8(sp)
 218:	0141                	addi	sp,sp,16
 21a:	8082                	ret
    dst += n;
 21c:	00c50733          	add	a4,a0,a2
    src += n;
 220:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 222:	fec05ae3          	blez	a2,216 <memmove+0x28>
 226:	fff6079b          	addiw	a5,a2,-1
 22a:	1782                	slli	a5,a5,0x20
 22c:	9381                	srli	a5,a5,0x20
 22e:	fff7c793          	not	a5,a5
 232:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 234:	15fd                	addi	a1,a1,-1
 236:	177d                	addi	a4,a4,-1
 238:	0005c683          	lbu	a3,0(a1)
 23c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 240:	fee79ae3          	bne	a5,a4,234 <memmove+0x46>
 244:	bfc9                	j	216 <memmove+0x28>

0000000000000246 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 246:	1141                	addi	sp,sp,-16
 248:	e422                	sd	s0,8(sp)
 24a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 24c:	ca05                	beqz	a2,27c <memcmp+0x36>
 24e:	fff6069b          	addiw	a3,a2,-1
 252:	1682                	slli	a3,a3,0x20
 254:	9281                	srli	a3,a3,0x20
 256:	0685                	addi	a3,a3,1
 258:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 25a:	00054783          	lbu	a5,0(a0)
 25e:	0005c703          	lbu	a4,0(a1)
 262:	00e79863          	bne	a5,a4,272 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 266:	0505                	addi	a0,a0,1
    p2++;
 268:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 26a:	fed518e3          	bne	a0,a3,25a <memcmp+0x14>
  }
  return 0;
 26e:	4501                	li	a0,0
 270:	a019                	j	276 <memcmp+0x30>
      return *p1 - *p2;
 272:	40e7853b          	subw	a0,a5,a4
}
 276:	6422                	ld	s0,8(sp)
 278:	0141                	addi	sp,sp,16
 27a:	8082                	ret
  return 0;
 27c:	4501                	li	a0,0
 27e:	bfe5                	j	276 <memcmp+0x30>

0000000000000280 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 280:	1141                	addi	sp,sp,-16
 282:	e406                	sd	ra,8(sp)
 284:	e022                	sd	s0,0(sp)
 286:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 288:	00000097          	auipc	ra,0x0
 28c:	f66080e7          	jalr	-154(ra) # 1ee <memmove>
}
 290:	60a2                	ld	ra,8(sp)
 292:	6402                	ld	s0,0(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret

0000000000000298 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 298:	4885                	li	a7,1
 ecall
 29a:	00000073          	ecall
 ret
 29e:	8082                	ret

00000000000002a0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2a0:	4889                	li	a7,2
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2a8:	488d                	li	a7,3
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2b0:	4891                	li	a7,4
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <read>:
.global read
read:
 li a7, SYS_read
 2b8:	4895                	li	a7,5
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <write>:
.global write
write:
 li a7, SYS_write
 2c0:	48c1                	li	a7,16
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <close>:
.global close
close:
 li a7, SYS_close
 2c8:	48d5                	li	a7,21
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2d0:	4899                	li	a7,6
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2d8:	489d                	li	a7,7
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <open>:
.global open
open:
 li a7, SYS_open
 2e0:	48bd                	li	a7,15
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2e8:	48c5                	li	a7,17
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2f0:	48c9                	li	a7,18
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2f8:	48a1                	li	a7,8
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <link>:
.global link
link:
 li a7, SYS_link
 300:	48cd                	li	a7,19
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 308:	48d1                	li	a7,20
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 310:	48a5                	li	a7,9
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <dup>:
.global dup
dup:
 li a7, SYS_dup
 318:	48a9                	li	a7,10
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 320:	48ad                	li	a7,11
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 328:	48b1                	li	a7,12
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 330:	48b5                	li	a7,13
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 338:	48b9                	li	a7,14
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <hello>:
.global hello
hello:
 li a7, SYS_hello
 340:	48d9                	li	a7,22
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <prcinf>:
.global prcinf
prcinf:
 li a7, SYS_prcinf
 348:	48dd                	li	a7,23
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 350:	1101                	addi	sp,sp,-32
 352:	ec06                	sd	ra,24(sp)
 354:	e822                	sd	s0,16(sp)
 356:	1000                	addi	s0,sp,32
 358:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 35c:	4605                	li	a2,1
 35e:	fef40593          	addi	a1,s0,-17
 362:	00000097          	auipc	ra,0x0
 366:	f5e080e7          	jalr	-162(ra) # 2c0 <write>
}
 36a:	60e2                	ld	ra,24(sp)
 36c:	6442                	ld	s0,16(sp)
 36e:	6105                	addi	sp,sp,32
 370:	8082                	ret

0000000000000372 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 372:	7139                	addi	sp,sp,-64
 374:	fc06                	sd	ra,56(sp)
 376:	f822                	sd	s0,48(sp)
 378:	f426                	sd	s1,40(sp)
 37a:	f04a                	sd	s2,32(sp)
 37c:	ec4e                	sd	s3,24(sp)
 37e:	0080                	addi	s0,sp,64
 380:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 382:	c299                	beqz	a3,388 <printint+0x16>
 384:	0805c963          	bltz	a1,416 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 388:	2581                	sext.w	a1,a1
  neg = 0;
 38a:	4881                	li	a7,0
 38c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 390:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 392:	2601                	sext.w	a2,a2
 394:	00000517          	auipc	a0,0x0
 398:	48c50513          	addi	a0,a0,1164 # 820 <digits>
 39c:	883a                	mv	a6,a4
 39e:	2705                	addiw	a4,a4,1
 3a0:	02c5f7bb          	remuw	a5,a1,a2
 3a4:	1782                	slli	a5,a5,0x20
 3a6:	9381                	srli	a5,a5,0x20
 3a8:	97aa                	add	a5,a5,a0
 3aa:	0007c783          	lbu	a5,0(a5)
 3ae:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3b2:	0005879b          	sext.w	a5,a1
 3b6:	02c5d5bb          	divuw	a1,a1,a2
 3ba:	0685                	addi	a3,a3,1
 3bc:	fec7f0e3          	bgeu	a5,a2,39c <printint+0x2a>
  if(neg)
 3c0:	00088c63          	beqz	a7,3d8 <printint+0x66>
    buf[i++] = '-';
 3c4:	fd070793          	addi	a5,a4,-48
 3c8:	00878733          	add	a4,a5,s0
 3cc:	02d00793          	li	a5,45
 3d0:	fef70823          	sb	a5,-16(a4)
 3d4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3d8:	02e05863          	blez	a4,408 <printint+0x96>
 3dc:	fc040793          	addi	a5,s0,-64
 3e0:	00e78933          	add	s2,a5,a4
 3e4:	fff78993          	addi	s3,a5,-1
 3e8:	99ba                	add	s3,s3,a4
 3ea:	377d                	addiw	a4,a4,-1
 3ec:	1702                	slli	a4,a4,0x20
 3ee:	9301                	srli	a4,a4,0x20
 3f0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3f4:	fff94583          	lbu	a1,-1(s2)
 3f8:	8526                	mv	a0,s1
 3fa:	00000097          	auipc	ra,0x0
 3fe:	f56080e7          	jalr	-170(ra) # 350 <putc>
  while(--i >= 0)
 402:	197d                	addi	s2,s2,-1
 404:	ff3918e3          	bne	s2,s3,3f4 <printint+0x82>
}
 408:	70e2                	ld	ra,56(sp)
 40a:	7442                	ld	s0,48(sp)
 40c:	74a2                	ld	s1,40(sp)
 40e:	7902                	ld	s2,32(sp)
 410:	69e2                	ld	s3,24(sp)
 412:	6121                	addi	sp,sp,64
 414:	8082                	ret
    x = -xx;
 416:	40b005bb          	negw	a1,a1
    neg = 1;
 41a:	4885                	li	a7,1
    x = -xx;
 41c:	bf85                	j	38c <printint+0x1a>

000000000000041e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 41e:	715d                	addi	sp,sp,-80
 420:	e486                	sd	ra,72(sp)
 422:	e0a2                	sd	s0,64(sp)
 424:	fc26                	sd	s1,56(sp)
 426:	f84a                	sd	s2,48(sp)
 428:	f44e                	sd	s3,40(sp)
 42a:	f052                	sd	s4,32(sp)
 42c:	ec56                	sd	s5,24(sp)
 42e:	e85a                	sd	s6,16(sp)
 430:	e45e                	sd	s7,8(sp)
 432:	e062                	sd	s8,0(sp)
 434:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 436:	0005c903          	lbu	s2,0(a1)
 43a:	18090c63          	beqz	s2,5d2 <vprintf+0x1b4>
 43e:	8aaa                	mv	s5,a0
 440:	8bb2                	mv	s7,a2
 442:	00158493          	addi	s1,a1,1
  state = 0;
 446:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 448:	02500a13          	li	s4,37
 44c:	4b55                	li	s6,21
 44e:	a839                	j	46c <vprintf+0x4e>
        putc(fd, c);
 450:	85ca                	mv	a1,s2
 452:	8556                	mv	a0,s5
 454:	00000097          	auipc	ra,0x0
 458:	efc080e7          	jalr	-260(ra) # 350 <putc>
 45c:	a019                	j	462 <vprintf+0x44>
    } else if(state == '%'){
 45e:	01498d63          	beq	s3,s4,478 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 462:	0485                	addi	s1,s1,1
 464:	fff4c903          	lbu	s2,-1(s1)
 468:	16090563          	beqz	s2,5d2 <vprintf+0x1b4>
    if(state == 0){
 46c:	fe0999e3          	bnez	s3,45e <vprintf+0x40>
      if(c == '%'){
 470:	ff4910e3          	bne	s2,s4,450 <vprintf+0x32>
        state = '%';
 474:	89d2                	mv	s3,s4
 476:	b7f5                	j	462 <vprintf+0x44>
      if(c == 'd'){
 478:	13490263          	beq	s2,s4,59c <vprintf+0x17e>
 47c:	f9d9079b          	addiw	a5,s2,-99
 480:	0ff7f793          	zext.b	a5,a5
 484:	12fb6563          	bltu	s6,a5,5ae <vprintf+0x190>
 488:	f9d9079b          	addiw	a5,s2,-99
 48c:	0ff7f713          	zext.b	a4,a5
 490:	10eb6f63          	bltu	s6,a4,5ae <vprintf+0x190>
 494:	00271793          	slli	a5,a4,0x2
 498:	00000717          	auipc	a4,0x0
 49c:	33070713          	addi	a4,a4,816 # 7c8 <malloc+0xf8>
 4a0:	97ba                	add	a5,a5,a4
 4a2:	439c                	lw	a5,0(a5)
 4a4:	97ba                	add	a5,a5,a4
 4a6:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4a8:	008b8913          	addi	s2,s7,8
 4ac:	4685                	li	a3,1
 4ae:	4629                	li	a2,10
 4b0:	000ba583          	lw	a1,0(s7)
 4b4:	8556                	mv	a0,s5
 4b6:	00000097          	auipc	ra,0x0
 4ba:	ebc080e7          	jalr	-324(ra) # 372 <printint>
 4be:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4c0:	4981                	li	s3,0
 4c2:	b745                	j	462 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4c4:	008b8913          	addi	s2,s7,8
 4c8:	4681                	li	a3,0
 4ca:	4629                	li	a2,10
 4cc:	000ba583          	lw	a1,0(s7)
 4d0:	8556                	mv	a0,s5
 4d2:	00000097          	auipc	ra,0x0
 4d6:	ea0080e7          	jalr	-352(ra) # 372 <printint>
 4da:	8bca                	mv	s7,s2
      state = 0;
 4dc:	4981                	li	s3,0
 4de:	b751                	j	462 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 4e0:	008b8913          	addi	s2,s7,8
 4e4:	4681                	li	a3,0
 4e6:	4641                	li	a2,16
 4e8:	000ba583          	lw	a1,0(s7)
 4ec:	8556                	mv	a0,s5
 4ee:	00000097          	auipc	ra,0x0
 4f2:	e84080e7          	jalr	-380(ra) # 372 <printint>
 4f6:	8bca                	mv	s7,s2
      state = 0;
 4f8:	4981                	li	s3,0
 4fa:	b7a5                	j	462 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 4fc:	008b8c13          	addi	s8,s7,8
 500:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 504:	03000593          	li	a1,48
 508:	8556                	mv	a0,s5
 50a:	00000097          	auipc	ra,0x0
 50e:	e46080e7          	jalr	-442(ra) # 350 <putc>
  putc(fd, 'x');
 512:	07800593          	li	a1,120
 516:	8556                	mv	a0,s5
 518:	00000097          	auipc	ra,0x0
 51c:	e38080e7          	jalr	-456(ra) # 350 <putc>
 520:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 522:	00000b97          	auipc	s7,0x0
 526:	2feb8b93          	addi	s7,s7,766 # 820 <digits>
 52a:	03c9d793          	srli	a5,s3,0x3c
 52e:	97de                	add	a5,a5,s7
 530:	0007c583          	lbu	a1,0(a5)
 534:	8556                	mv	a0,s5
 536:	00000097          	auipc	ra,0x0
 53a:	e1a080e7          	jalr	-486(ra) # 350 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 53e:	0992                	slli	s3,s3,0x4
 540:	397d                	addiw	s2,s2,-1
 542:	fe0914e3          	bnez	s2,52a <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 546:	8be2                	mv	s7,s8
      state = 0;
 548:	4981                	li	s3,0
 54a:	bf21                	j	462 <vprintf+0x44>
        s = va_arg(ap, char*);
 54c:	008b8993          	addi	s3,s7,8
 550:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 554:	02090163          	beqz	s2,576 <vprintf+0x158>
        while(*s != 0){
 558:	00094583          	lbu	a1,0(s2)
 55c:	c9a5                	beqz	a1,5cc <vprintf+0x1ae>
          putc(fd, *s);
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	df0080e7          	jalr	-528(ra) # 350 <putc>
          s++;
 568:	0905                	addi	s2,s2,1
        while(*s != 0){
 56a:	00094583          	lbu	a1,0(s2)
 56e:	f9e5                	bnez	a1,55e <vprintf+0x140>
        s = va_arg(ap, char*);
 570:	8bce                	mv	s7,s3
      state = 0;
 572:	4981                	li	s3,0
 574:	b5fd                	j	462 <vprintf+0x44>
          s = "(null)";
 576:	00000917          	auipc	s2,0x0
 57a:	24a90913          	addi	s2,s2,586 # 7c0 <malloc+0xf0>
        while(*s != 0){
 57e:	02800593          	li	a1,40
 582:	bff1                	j	55e <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 584:	008b8913          	addi	s2,s7,8
 588:	000bc583          	lbu	a1,0(s7)
 58c:	8556                	mv	a0,s5
 58e:	00000097          	auipc	ra,0x0
 592:	dc2080e7          	jalr	-574(ra) # 350 <putc>
 596:	8bca                	mv	s7,s2
      state = 0;
 598:	4981                	li	s3,0
 59a:	b5e1                	j	462 <vprintf+0x44>
        putc(fd, c);
 59c:	02500593          	li	a1,37
 5a0:	8556                	mv	a0,s5
 5a2:	00000097          	auipc	ra,0x0
 5a6:	dae080e7          	jalr	-594(ra) # 350 <putc>
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	bd5d                	j	462 <vprintf+0x44>
        putc(fd, '%');
 5ae:	02500593          	li	a1,37
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	d9c080e7          	jalr	-612(ra) # 350 <putc>
        putc(fd, c);
 5bc:	85ca                	mv	a1,s2
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	d90080e7          	jalr	-624(ra) # 350 <putc>
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	bd61                	j	462 <vprintf+0x44>
        s = va_arg(ap, char*);
 5cc:	8bce                	mv	s7,s3
      state = 0;
 5ce:	4981                	li	s3,0
 5d0:	bd49                	j	462 <vprintf+0x44>
    }
  }
}
 5d2:	60a6                	ld	ra,72(sp)
 5d4:	6406                	ld	s0,64(sp)
 5d6:	74e2                	ld	s1,56(sp)
 5d8:	7942                	ld	s2,48(sp)
 5da:	79a2                	ld	s3,40(sp)
 5dc:	7a02                	ld	s4,32(sp)
 5de:	6ae2                	ld	s5,24(sp)
 5e0:	6b42                	ld	s6,16(sp)
 5e2:	6ba2                	ld	s7,8(sp)
 5e4:	6c02                	ld	s8,0(sp)
 5e6:	6161                	addi	sp,sp,80
 5e8:	8082                	ret

00000000000005ea <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5ea:	715d                	addi	sp,sp,-80
 5ec:	ec06                	sd	ra,24(sp)
 5ee:	e822                	sd	s0,16(sp)
 5f0:	1000                	addi	s0,sp,32
 5f2:	e010                	sd	a2,0(s0)
 5f4:	e414                	sd	a3,8(s0)
 5f6:	e818                	sd	a4,16(s0)
 5f8:	ec1c                	sd	a5,24(s0)
 5fa:	03043023          	sd	a6,32(s0)
 5fe:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 602:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 606:	8622                	mv	a2,s0
 608:	00000097          	auipc	ra,0x0
 60c:	e16080e7          	jalr	-490(ra) # 41e <vprintf>
}
 610:	60e2                	ld	ra,24(sp)
 612:	6442                	ld	s0,16(sp)
 614:	6161                	addi	sp,sp,80
 616:	8082                	ret

0000000000000618 <printf>:

void
printf(const char *fmt, ...)
{
 618:	711d                	addi	sp,sp,-96
 61a:	ec06                	sd	ra,24(sp)
 61c:	e822                	sd	s0,16(sp)
 61e:	1000                	addi	s0,sp,32
 620:	e40c                	sd	a1,8(s0)
 622:	e810                	sd	a2,16(s0)
 624:	ec14                	sd	a3,24(s0)
 626:	f018                	sd	a4,32(s0)
 628:	f41c                	sd	a5,40(s0)
 62a:	03043823          	sd	a6,48(s0)
 62e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 632:	00840613          	addi	a2,s0,8
 636:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 63a:	85aa                	mv	a1,a0
 63c:	4505                	li	a0,1
 63e:	00000097          	auipc	ra,0x0
 642:	de0080e7          	jalr	-544(ra) # 41e <vprintf>
}
 646:	60e2                	ld	ra,24(sp)
 648:	6442                	ld	s0,16(sp)
 64a:	6125                	addi	sp,sp,96
 64c:	8082                	ret

000000000000064e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 64e:	1141                	addi	sp,sp,-16
 650:	e422                	sd	s0,8(sp)
 652:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 654:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 658:	00001797          	auipc	a5,0x1
 65c:	9a87b783          	ld	a5,-1624(a5) # 1000 <freep>
 660:	a02d                	j	68a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 662:	4618                	lw	a4,8(a2)
 664:	9f2d                	addw	a4,a4,a1
 666:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 66a:	6398                	ld	a4,0(a5)
 66c:	6310                	ld	a2,0(a4)
 66e:	a83d                	j	6ac <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 670:	ff852703          	lw	a4,-8(a0)
 674:	9f31                	addw	a4,a4,a2
 676:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 678:	ff053683          	ld	a3,-16(a0)
 67c:	a091                	j	6c0 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 67e:	6398                	ld	a4,0(a5)
 680:	00e7e463          	bltu	a5,a4,688 <free+0x3a>
 684:	00e6ea63          	bltu	a3,a4,698 <free+0x4a>
{
 688:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 68a:	fed7fae3          	bgeu	a5,a3,67e <free+0x30>
 68e:	6398                	ld	a4,0(a5)
 690:	00e6e463          	bltu	a3,a4,698 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 694:	fee7eae3          	bltu	a5,a4,688 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 698:	ff852583          	lw	a1,-8(a0)
 69c:	6390                	ld	a2,0(a5)
 69e:	02059813          	slli	a6,a1,0x20
 6a2:	01c85713          	srli	a4,a6,0x1c
 6a6:	9736                	add	a4,a4,a3
 6a8:	fae60de3          	beq	a2,a4,662 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6ac:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6b0:	4790                	lw	a2,8(a5)
 6b2:	02061593          	slli	a1,a2,0x20
 6b6:	01c5d713          	srli	a4,a1,0x1c
 6ba:	973e                	add	a4,a4,a5
 6bc:	fae68ae3          	beq	a3,a4,670 <free+0x22>
    p->s.ptr = bp->s.ptr;
 6c0:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6c2:	00001717          	auipc	a4,0x1
 6c6:	92f73f23          	sd	a5,-1730(a4) # 1000 <freep>
}
 6ca:	6422                	ld	s0,8(sp)
 6cc:	0141                	addi	sp,sp,16
 6ce:	8082                	ret

00000000000006d0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6d0:	7139                	addi	sp,sp,-64
 6d2:	fc06                	sd	ra,56(sp)
 6d4:	f822                	sd	s0,48(sp)
 6d6:	f426                	sd	s1,40(sp)
 6d8:	f04a                	sd	s2,32(sp)
 6da:	ec4e                	sd	s3,24(sp)
 6dc:	e852                	sd	s4,16(sp)
 6de:	e456                	sd	s5,8(sp)
 6e0:	e05a                	sd	s6,0(sp)
 6e2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6e4:	02051493          	slli	s1,a0,0x20
 6e8:	9081                	srli	s1,s1,0x20
 6ea:	04bd                	addi	s1,s1,15
 6ec:	8091                	srli	s1,s1,0x4
 6ee:	0014899b          	addiw	s3,s1,1
 6f2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6f4:	00001517          	auipc	a0,0x1
 6f8:	90c53503          	ld	a0,-1780(a0) # 1000 <freep>
 6fc:	c515                	beqz	a0,728 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6fe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 700:	4798                	lw	a4,8(a5)
 702:	02977f63          	bgeu	a4,s1,740 <malloc+0x70>
  if(nu < 4096)
 706:	8a4e                	mv	s4,s3
 708:	0009871b          	sext.w	a4,s3
 70c:	6685                	lui	a3,0x1
 70e:	00d77363          	bgeu	a4,a3,714 <malloc+0x44>
 712:	6a05                	lui	s4,0x1
 714:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 718:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 71c:	00001917          	auipc	s2,0x1
 720:	8e490913          	addi	s2,s2,-1820 # 1000 <freep>
  if(p == (char*)-1)
 724:	5afd                	li	s5,-1
 726:	a895                	j	79a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 728:	00001797          	auipc	a5,0x1
 72c:	8e878793          	addi	a5,a5,-1816 # 1010 <base>
 730:	00001717          	auipc	a4,0x1
 734:	8cf73823          	sd	a5,-1840(a4) # 1000 <freep>
 738:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 73a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 73e:	b7e1                	j	706 <malloc+0x36>
      if(p->s.size == nunits)
 740:	02e48c63          	beq	s1,a4,778 <malloc+0xa8>
        p->s.size -= nunits;
 744:	4137073b          	subw	a4,a4,s3
 748:	c798                	sw	a4,8(a5)
        p += p->s.size;
 74a:	02071693          	slli	a3,a4,0x20
 74e:	01c6d713          	srli	a4,a3,0x1c
 752:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 754:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 758:	00001717          	auipc	a4,0x1
 75c:	8aa73423          	sd	a0,-1880(a4) # 1000 <freep>
      return (void*)(p + 1);
 760:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 764:	70e2                	ld	ra,56(sp)
 766:	7442                	ld	s0,48(sp)
 768:	74a2                	ld	s1,40(sp)
 76a:	7902                	ld	s2,32(sp)
 76c:	69e2                	ld	s3,24(sp)
 76e:	6a42                	ld	s4,16(sp)
 770:	6aa2                	ld	s5,8(sp)
 772:	6b02                	ld	s6,0(sp)
 774:	6121                	addi	sp,sp,64
 776:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 778:	6398                	ld	a4,0(a5)
 77a:	e118                	sd	a4,0(a0)
 77c:	bff1                	j	758 <malloc+0x88>
  hp->s.size = nu;
 77e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 782:	0541                	addi	a0,a0,16
 784:	00000097          	auipc	ra,0x0
 788:	eca080e7          	jalr	-310(ra) # 64e <free>
  return freep;
 78c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 790:	d971                	beqz	a0,764 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 792:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 794:	4798                	lw	a4,8(a5)
 796:	fa9775e3          	bgeu	a4,s1,740 <malloc+0x70>
    if(p == freep)
 79a:	00093703          	ld	a4,0(s2)
 79e:	853e                	mv	a0,a5
 7a0:	fef719e3          	bne	a4,a5,792 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7a4:	8552                	mv	a0,s4
 7a6:	00000097          	auipc	ra,0x0
 7aa:	b82080e7          	jalr	-1150(ra) # 328 <sbrk>
  if(p == (char*)-1)
 7ae:	fd5518e3          	bne	a0,s5,77e <malloc+0xae>
        return 0;
 7b2:	4501                	li	a0,0
 7b4:	bf45                	j	764 <malloc+0x94>
