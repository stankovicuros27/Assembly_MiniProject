! INIT SIMULATION
dc x.1, x.9996
dc x.0, x.9998
onkp false, x.1, x.1
onkp false, x.1, x.1
onkp true, x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
kpreg 1.1, r0, x.1
kpreg 1.1, r1, x.2
kpreg 1.1, r2, x.3
kpreg 1.1, r3, x.4
kpreg 1.1, r4, x.5
kpreg 1.1, r5, x.6
kpreg 1.1, r6, x.7
kpreg 1.1, r7, x.8
kpreg 2.1, r0, x.9
kpreg 2.1, r1, x.a
kpreg 2.1, r2, x.b
kpreg 2.1, r3, x.c
kpreg 2.1, r4, x.d
kpreg 2.1, r5, x.e
kpreg 2.1, r6, x.f
kpreg 2.1, r7, x.10
reg pc, x.4000
reg ivtp, x.4000
reg sp, x.9000
! /INIT SIMULATION

! ======================== Main Program ========================
org x.4000
! --------- Initializing IVT ---------
intd
clr r0
mvrir r0, ivtp 	! ivtp <= 0000h
ldimm x.500, r0
stmem x.0, r0 	! ivtp[0] <= 500h
ldimm x.1000, r0
stmem x.1, r0	! ivtp[1] <= 1000h
ldimm x.1500, r0
stmem x.2, r0	! ivtp[2] <= 1500h
ldimm x.2000, r0
stmem x.3, r0	! ivtp[3] <= 2000h
ldimm x.2500, r0
stmem x.4, r0	! ivtp[4] <= 2500h
ldimm x.3000, r0
stmem x.5, r0	! ivtp[5] <= 3000h
inte
! --------- /Initializing IVT --------

! --------- Reading Array A & B ---------
! Array A -> location 5000h, KP1.1 (Ready bit)
! Array B -> location 6000h, KP2.1 (Interrupts)
! 8h elements

! Starting KP1.1 (Ready bit)
ldimm x.5000, r0	! Pointer to Array A
ldimm x.8, r1	! Array A elem count
ldimm x.5, r3	
stmem x.f100, r3 	! Starting KP1.1 with flags 101

! Starting KP2.1 (Interrupt)
ldimm x.2, r3 	! IVT Entry no
stmem x.f202, r3	! KP2.1[entry] <= 2
ldimm x.6000, r4	! Pointer to Array B
ldimm x.9, r5 	! Array B elem count + 1 (for intr)
clr ra		! KP2.1 Load Semaphore <= 0
ldimm x.f, r3
stmem x.f200, r3	! Starting KP2.1 with flags 101

! Reading from KP1.1 using Ready bit
ldimm x.1, r3	! Mask for checking ready bit
wait1:	
	ldmem x.f101, rc	! Reading KP1.1 Ready bit
	and rc, rc, r3	! Mask
	beql wait1	! If ( !ready ) jmp wait1
! KP1.1 is ready here...
ldmem x.f103, r7	! raeding KP1.1 data
stri [r0], r7	! Array A[cnt] <= data
inc r0
dec r1
bneq wait1	! While cnt > 0, repeat

! Turn off KP1.1
clr r0
stmem x.f100, r0

! Waiting for KP2.1 to finish Array B input
ldimm x.1, r3	! Mask to check semaphore value
wait2:
	and ra, ra, r3	! Mask
	beql wait2	! If ( !semaphore ) jmp wait2
! --------- /Reading Array A & B ---------

! --------- Complementing Array A ----------
ldimm x.9, r0	! Counter + 1
ldimm x.4fff, ra	! Pointer to Array A
ldimm x.5fff, rb	! Pointer to Array B

iteratorCompl:
	ldimm x.1, r1	! Mask
	inc ra		! Next Array elem
	inc rb
	dec r0		! Decrement counter
	beql finishCompl	! if ( !cnt ) finish
	ldrid [rb]x.0, rc	
	and rf, r1, rc
	bneq iteratorCompl
	push ra
	jsr complement
	pop ra
	jmp iteratorCompl
finishCompl:	
! --------- /Complementing Array A ---------

! mem[9999h] = A[0]
ldimm x.5000, r0		
ldrid [r0]x.0, r1	
stmem x.9999, r1		

! --------- Copying Array A ---------
! Starting DMA1.4
ldimm x.5, r0		! IVT entry
stmem x.f0c2, r0

ldimm x.8, r2		! Element count
stmem x.f0c4, r2
ldimm x.5000, r3		! Source	Array location
stmem x.f0c5, r3
ldimm x.5100, r4		! Destination Array location
stmem x.f0c6, r4
clr ra	! DMA1.4 Semaphore

ldimm x.b6, r1	! Flags to start DMA1.4
stmem x.f0c0, r1	! Starting DMA1.4

ldimm x.1, r5	! Mask
wait3:
	and ra, ra, r5
	bneq wait3
! --------- /Copying Array A --------

! --------- Sending Array A to KP1.2 ---------
! Starting KP1.2 (Interrupt)
ldimm x.1, r3 	! IVT Entry no
stmem x.f142, r3	! KP1.2[entry] <= 1
ldimm x.5000, r4	! Pointer to Array A
ldimm x.9, r5 	! Array B elem count + 1 (for intr)
clr ra		! KP1.2 Load Semaphore <= 0
ldimm x.e, r3
stmem x.f140, r3	! Starting KP1.2 with flags 1110

! Waiting for KP2.1 to finish Array A output
ldimm x.1, r3	! Mask to check Semaphore value
wait4:	
	and ra, ra, r3	! Mask
	beql wait4	! If ( !ready ) jmp wait1

! --------- /Sending Array A to KP1.2 --------

! --------- mem[9999h] -> DMA1.2 ---------
! Starting DMA1.2
ldimm x.4, r0		! IVT entry
stmem x.f042, r0

ldimm x.1, r2		! Element count
stmem x.f044, r2
ldimm x.9999, r3		! Source	Array location
stmem x.f045, r3
clr ra	! DMA1.2 Semaphore

ldimm x.86, r1	! Flags to start DMA1.4
stmem x.f040, r1	! Starting DMA1.4

ldimm x.1, r5	! Mask
wait5:
	and ra, ra, r5
	bneq wait5
! --------- /mem[9999h] -> DMA1.2 --------

halt
! ======================== /Main Program =======================




! ========= Complement Subroutine =========
complement:
	pop r4	! PC
	pop r5
	ldrid [r5]x.0, r7
	ldimm x.f, r6
	xor r7, r7, r6
	stri [r5], r7
	push r5
	push r4
	rts
! ========= /Complement Subroutine ========



! ========= KP1.2 Interrupt routine =========
org x.1000 	! Interrupt ivtp[1]

dec r5		! decrement elem cnt
bneq transfer3
stmem x.f140, r5	! Turn off KP1.2
ldimm x.1, ra	! semaphore <= 1
jmp back3

transfer3: 
	ldrid [r4]x.0, rb
	stmem x.f143, rb
	inc r4

back3:	rti
! ========= /KP1.2 Interrupt routine ========

! ========= KP2.1 Interrupt routine =========
org x.1500 		! Interrupt ivtp[2]

dec r5			! decrement elem cnt
bneq transfer1
stmem x.f200, r5		! Turn off KP2.1
ldimm x.1, ra		! semaphore <= 1
jmp back1
transfer1: 
	ldmem x.f203, rb	! Reading KP2.1 Data
	stri [r4], rb	! Array B[cnt] <= Data
	inc r4
back1:	rti
! ========= /KP2.1 Interrupt routine ========

! ========= DMA1.2 Interrupt routine =========
org x.2500
push r0
ldimm x.1, ra
clr r0
stmem x.f040, r0
pop r0
rti
! ========= /DMA1.4 Interrupt routine ========

! ========= DMA1.4 Interrupt routine =========
org x.3000
push r0
ldimm x.1, ra
clr r0
stmem x.f0c0, r0
pop r0
rti
! ========= /DMA1.4 Interrupt routine ========