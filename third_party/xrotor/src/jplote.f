C***********************************************************************
C    Module:  jplote.f
C 
C    Copyright (C) 2011 Mark Drela 
C 
C    This program is free software; you can redistribute it and/or modify
C    it under the terms of the GNU General Public License as published by
C    the Free Software Foundation; either version 2 of the License, or
C    (at your option) any later version.
C
C    This program is distributed in the hope that it will be useful,
C    but WITHOUT ANY WARRANTY; without even the implied warranty of
C    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
C    GNU General Public License for more details.
C
C    You should have received a copy of the GNU General Public License
C    along with this program; if not, write to the Free Software
C    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
C***********************************************************************
      PROGRAM JPLOTE
C------------------------------------------------------
C     Plots an operating map of Pc vs 1/J with contours 
C     of efficiency and blade angle from subroutine JMAP
C
C     Can also overlay engine-characteristic curves.
C
C     Usage:  % jplote filename
C
C------------------------------------------------------
C
      PARAMETER (LX=71,KX=81)
      REAL EF(LX,KX), BE(LX,KX)
      REAL RJ(LX,KX), CP(LX,KX)
      REAL RJ0(LX), CP0(KX)
      INTEGER KLOW(LX), KUPP(LX)
      LOGICAL LABCON, YES
      CHARACTER*48 FNAME
      CHARACTER*32 NAME
      CHARACTER*4 DUMMY
C
      PARAMETER (IX=20)
      REAL RPM(IX), POWER(IX), RJI(IX), CPI(IX)
      REAL RJE(LX), CPE(LX)
C
      PI = 4.0*ATAN(1.0)
C
      WRITE(*,*) 
      WRITE(*,*) ' 1  Pc vs 1/J'
      WRITE(*,*) ' 2  Tc vs 1/J'
      WRITE(*,*) ' 3  Qc vs 1/J'
      WRITE(*,*) 
      CALL ASKI('Enter plot type^',ITYPE)
C
C---- plotting parameters
      CS  = 0.015        ! character height/SIZE
      PAR = 0.7          ! y-axis height/SIZE
C
C---- Plotting flag
      IDEV = 1   ! X11 window only
c     IDEV = 2   ! B&W PostScript output file only (no color)
c     IDEV = 3   ! both X11 and B&W PostScript file
c     IDEV = 4   ! Color PostScript output file only 
c     IDEV = 5   ! both X11 and Color PostScript file 
C
C---- Re-plotting flag (for hardcopy)
      IDEVRP = 2   ! B&W PostScript
c     IDEVRP = 4   ! Color PostScript
C
C---- PostScript output logical unit and file specification
      IPSLU = 0  ! output to file  plot.ps   on LU 4    (default case)
c     IPSLU = ?  ! output to file  plot?.ps  on LU 10+?
C
C---- screen fraction taken up by plot window upon opening
      SCRNFR = 0.60
C
C---- Default plot size in inches
C-    (Default plot window is 11.0 x 8.5)
      SIZE = 7.5
C
      CALL PLINITIALIZE
C
C---- set up color spectrum
      NCOLOR = 64
      CALL COLORSPECTRUMHUES(NCOLOR,'RYGCBM')
C
C
C---- axis tick mark increments for 1/J, Pc
      DRJ = 0.2
      DCP = 0.01
C
C---- grid increments for 1/J, Pc
      GRJ = 0.2
      GCP = 0.01
C
      CALL GETARG(1,FNAME)
      IF(FNAME(1:1).EQ.' ') CALL ASKS('Enter dump filename^',FNAME)
C
      OPEN(11,FILE=FNAME,STATUS='OLD',FORM='UNFORMATTED')
C
      READ(11) NAME
      READ(11) RE6, AMACH
      READ(11) NRJ, NCP
C
      IF(NRJ.GT.LX) WRITE(*,*) 'Array overflow.  Increase LX to ', NRJ
      IF(NCP.GT.KX) WRITE(*,*) 'Array overflow.  Increase KX to ', NCP
C
      READ(11) (KLOW(L),L=1,NRJ)
      READ(11) (KUPP(L),L=1,NRJ)
      READ(11) (RJ0(L),L=1,NRJ)
      READ(11) (CP0(K),K=1,NCP)
C
      DO 21 K=1, NCP
        READ(11) (EF(L,K),L=1,NRJ)
   21 CONTINUE
C
      DO 22 K=1, NCP
        READ(11) (BE(L,K),L=1,NRJ)
   22 CONTINUE
C
      CLOSE(11)
C
C---- fill rest of J and Pc arrays since CONPLT requires these to be 2-D
      DO 32 K=1, NCP
        DO 31 L=1, NRJ
C
C-------- set Pc from Cp
          PC = CP0(K) * (2.0/RJ0(L))**3 / PI
C
          IF(ITYPE.EQ.1) THEN
           CP(L,K) = PC
          ELSE IF(ITYPE.EQ.2) THEN
           CP(L,K) = PC * EF(L,K)
          ELSE
           CP(L,K) = PC * (RJ0(L)/PI)
          ENDIF
C
C-------- set 1/J
          RJ(L,K) = 1.0/RJ0(L)
C
   31   CONTINUE
   32 CONTINUE
C
C---- set plot axis limits
      RJTOP = 1.0/RJ0(1)
      RJAV = 0.5*(RJ0(1) + RJ0(NRJ))
      PCTOP = CP0(NCP) * (2.0/RJAV)**3 / PI
C
      CPTOP = PCTOP
C
      IF(ITYPE.EQ.1) THEN
       CPTOP = PCTOP
      ELSE IF(ITYPE.EQ.2) THEN
       CPTOP = PCTOP
      ELSE
       CPTOP = PCTOP * (RJ0(1)/PI)
      ENDIF
C

      RJLAX = DRJ * FLOAT( INT(RJTOP/DRJ + 1.1) )
      CPLAX = DCP * FLOAT( INT(CPTOP/DCP + 1.8) )
C
C
C---- find max and min beta, efficiency
      EFMAX = -1.0E9
      EFMIN = +1.0E9
      BEMAX = -1.0E9
      BEMIN = +1.0E9
      DO 30 L=1, NRJ
        DO 310 K=1, NCP
          IF(K.GE.KLOW(L) .AND. K.LE.KUPP(L)) THEN
           EFMAX = MAX( EFMAX , EF(L,K) )
           EFMIN = MIN( EFMIN , EF(L,K) )
           BEMAX = MAX( BEMAX , BE(L,K) )
           BEMIN = MIN( BEMIN , BE(L,K) )
          ENDIF
  310   CONTINUE
   30 CONTINUE
C
C
      CALL PLOPEN(SCRNFR,IPSLU,IDEV)
      CALL NEWFACTOR(SIZE)
      CALL PLOTABS(0.75,0.75,-3)
C
C---- set plot scale weights for J and Cp
      RJWT = 1.0/RJLAX
      CPWT = PAR/CPLAX
C
C---- J axis
      CALL NEWPEN(2)
      CALL PLOT(0.0,0.0,3)
      CALL PLOT(1.0,0.0,2)
C
C---- tick marks
      NT = INT(RJLAX/DRJ)
      DO 51 IT=1, NT
        RJT = DRJ*FLOAT(IT)
        CALL PLOT(RJWT*RJT,-.2*CS,3)
        CALL PLOT(RJWT*RJT,0.2*CS,2)
        CALL PLNUMB(RJWT*RJT-1.5*CS,-2.0*CS,CS,RJT,0.0,1)
   51 CONTINUE
C
      CALL NEWPEN(3)
      XPLT = RJWT*DRJ*(FLOAT((3*NT)/4) + 0.5) - 1.6*CS
      YPLT = -4.0*CS
      CALL PLCHAR(XPLT,YPLT,1.3*CS,'1/J',0.0,3)
C
C---- Cp axis
      CALL NEWPEN(2)
      CALL PLOT(0.0,0.0,3)
      CALL PLOT(0.0,PAR,2)
C
C---- tick marks
      NT = INT(CPLAX/DCP)
      DO 53 IT=0, NT
        CPN = DCP*FLOAT(IT)
        CALL PLOT(-.2*CS,CPWT*CPN,3)
        CALL PLOT(0.2*CS,CPWT*CPN,2)
        CALL PLNUMB(-4.5*CS,CPWT*CPN-0.5*CS,CS,CPN,0.0,2)
   53 CONTINUE
C
      CALL NEWPEN(3)
      XPLT = -5.0*CS
      YPLT = CPWT*DCP*(FLOAT((3*NT)/4) + 0.5) - 0.6*CS
      IF(ITYPE.EQ.1) THEN
        CALL PLCHAR(XPLT       ,YPLT       ,1.3*CS,'P',0.0,1)
      ELSE IF(ITYPE.EQ.2) THEN
        CALL PLCHAR(XPLT       ,YPLT       ,1.3*CS,'T',0.0,1)
      ELSE
        CALL PLCHAR(XPLT       ,YPLT       ,1.3*CS,'Q',0.0,1)
      ENDIF
      CALL PLCHAR(XPLT+1.1*CS,YPLT-0.2*CS,1.0*CS,'c',0.0,1)
C
C---- plot propeller name in upper left corner of plot 
      CALL NEWPEN(3)
      XPLT = 1.5*CS
      YPLT = PAR + 4.0*CS
C---- move title and specs up to clear the contour labels  HHY 11/98
      YPLT = YPLT + 3.5*CS
      CALL PLCHAR(XPLT,YPLT,1.4*CS,NAME,0.0,31)
C
C---- plot Mach number and Reynolds number
      YPLT = YPLT - 2.5*CS
      CALL PLCHAR(XPLT           ,YPLT,1.2*CS,'Mach/J = ',0.0,9)
      CALL PLNUMB(XPLT+9.0*1.2*CS,YPLT,1.2*CS,AMACH,0.0,3)
C
      XPLT = XPLT + 16.0*1.2*CS
      CALL PLCHAR(XPLT,YPLT,1.2*CS,'Re/J = ',0.0,7)
      CALL PLNUMB(XPLT+ 7.0*1.2*CS,YPLT       ,1.2*CS,RE6    ,0.0,3)
      CALL PLCHAR(XPLT+12.0*1.2*CS,YPLT       ,1.2*CS,'   10',0.0,5)
      CALL PLMATH(XPLT+12.0*1.2*CS,YPLT       ,1.2*CS,' #   ',0.0,5)
      CALL PLCHAR(XPLT+17.0*1.2*CS,YPLT+0.5*CS,0.9*CS,'6'    ,0.0,1)
C
      CALL PLFLUSH
C
      WRITE(*,*) ' '
      WRITE(*,*) 'Efficiency   min, max:', EFMIN, EFMAX
      WRITE(*,*) 'Blade angle  min, max:', BEMIN, BEMAX
      WRITE(*,*) ' '
C
  800 CONTINUE
      WRITE(*,*) ' '
      CALL ASKR('Enter lowest efficiency contour level^',EFLOW)
      CALL ASKR('Enter efficiency contour level increment^',DEF)
      CALL ASKI('Enter contour line thickness (1-5)^',LPEN)
      CALL ASKL('Add numerical labels to contours ?^',LABCON)
C
C**** plot contours of equal efficiency
C
      CALL NEWPEN(LPEN)
C
C---- go over efficiency contour levels
      DO 60 IEF = 0, 12345
C
C------ set efficiency contour level
        EFCON = EFLOW + DEF*FLOAT(IEF)
C
C------ skip out if outside upper limit
        IF(EFCON.GT.EFMAX) GO TO 61
C
        CALL CONPLT(LX,KX,NRJ,NCP,RJ,CP,KLOW,KUPP,
     &              EF,EFCON,0.0,0.0,RJWT,CPWT)
C
C------ draw label contours on right edge (left physically)
        IF(LABCON) 
     &   CALL CONLAB(LX,KX,NRJ,NCP,RJ,CP,
     &               EF,EFCON,0.0,0.0,RJWT,CPWT,0.8*CS,2,2)
C
C------ draw label contours on top edge
        IF(LABCON) 
     &   CALL CONLAB(LX,KX,NRJ,NCP,RJ,CP,
     &               EF,EFCON,0.0,0.0,RJWT,CPWT,0.8*CS,2,3)
C
   60 CONTINUE
   61 CONTINUE
C
      CALL PLFLUSH
C
      CALL ASKL('Add more efficiency contours ?^',YES)
      IF(YES) GO TO 800
C
C
  900 CONTINUE
      WRITE(*,*)
      CALL ASKR('Enter largest blade angle contour level^',BEHIH)
      CALL ASKR('Enter blade angle contour level decrement^',DBE)
      CALL ASKI('Enter contour line thickness (1-5)^',LPEN)
      CALL ASKL('Add numerical labels to contours ?^',LABCON)
C
      DBE = ABS(DBE)
C
C**** plot contours of equal blade angle
C
      CALL NEWPEN(LPEN)
C
C---- go over blade angle contour levels
      NBE = INT(BEHIH/DBE) + 1
      DO 80 IBE = 0, NBE
C
        BECON = BEHIH - DBE*FLOAT(IBE)
C
C------ skip out if below lower limit
        IF(BECON.LT.BEMIN) GO TO 81
C
        CALL CONPLT(LX,KX,NRJ,NCP,RJ,CP,KLOW,KUPP,
     &              BE,BECON,0.0,0.0,RJWT,CPWT)
C
C------ draw contour labels on right edge
        IF(LABCON) 
     &   CALL CONLAB(LX,KX,NRJ,NCP,RJ,CP,
     &               BE,BECON,0.0,0.0,RJWT,CPWT,0.8*CS,-1,2)
C
C------ draw contour labels on bottom edge
        IF(LABCON) 
     &   CALL CONLAB(LX,KX,NRJ,NCP,RJ,CP,
     &               BE,BECON,0.0,0.0,RJWT,CPWT,0.8*CS,-1,1)
   80 CONTINUE
   81 CONTINUE
C
      CALL PLFLUSH
C
      CALL ASKL('Add more blade angle contours ?^',YES)
      IF(YES) GO TO 900
C
      CALL ASKL('Overlay grid ?^',YES)
      IF(YES) THEN
       CALL NEWPEN(1)
       RJMIN = MIN(RJ(1,1),RJ(1,NCP),RJ(NRJ,1),RJ(NRJ,NCP))
       CPMIN = MIN(CP(1,1),CP(1,NCP),CP(NRJ,1),CP(NRJ,NCP))
       RJMAX = MAX(RJ(1,1),RJ(1,NCP),RJ(NRJ,1),RJ(NRJ,NCP))
       CPMAX = MAX(CP(1,1),CP(1,NCP),CP(NRJ,1),CP(NRJ,NCP))
       RJMAX = MIN(RJMAX,RJLAX)
       CPMAX = MIN(CPMAX,CPLAX)
       X0 = RJWT*DRJ*FLOAT( INT(RJMIN/DRJ + 0.01) )
       Y0 = CPWT*DCP*FLOAT( INT(CPMIN/DCP + 0.01) )
C
       DXG = RJWT*GRJ
       DYG = CPWT*GCP
       NXG = INT( (RJMAX-RJMIN)/GRJ + 0.01 )
       NYG = INT( (CPMAX-CPMIN)/GCP + 0.01 )
       CALL PLGRID(X0,Y0, NXG,DXG, NYG,DYG, -30584)
       CALL PLFLUSH
      ENDIF
C
      DO 950 IENG=1, 12345
C
      CALL ASKS('Enter engine data filename^',FNAME)
      OPEN(2,FILE=FNAME,STATUS='OLD',ERR=990)
      READ(2,1000) DUMMY
 1000 FORMAT(A4)
      DO 90 I=1, IX
        READ(2,*,END=91) RPM(I), POWER(I)
 90   CONTINUE
 91   N = I-1
      CLOSE(2)
C
      IF(IENG.EQ.1) THEN
       WRITE(*,*) 'Enter rho, V, R, gear'
       READ (*,*) RHO, V, R, GEAR
      ENDIF
C
      DO 93 I=1, N
        PC  = POWER(I)/(0.5*RHO*V**3 * PI*R**2)
        ADV = V / (R * RPM(I)*PI/30.0 / GEAR )
C
        RJI(I) = 1.0/(PI*ADV)
C
        IF(ITYPE.EQ.1) THEN
          CPI(I) = PC
        ELSE IF(ITYPE.EQ.2) THEN
C
          DO 931 K=NCP-1, 1, -1
            IF(PC/((2.0/(PI*ADV))**3 / PI)  .GE. CP0(K)) GO TO 932
 931      CONTINUE
          NPTS = I-1
          GO TO 94
C
 932      CONTINUE
          FRK = (PC/((2.0/(PI*ADV))**3 / PI) - CP0(K))
     &        / (                   CP0(K+1) - CP0(K))
C
          DO 935 L=NRJ-1, 1, -1
            IF(PI*ADV .GE. RJ0(L)) GO TO 936
 935      CONTINUE
          NPTS = I-1
          GO TO 94
C
 936      CONTINUE
          FRL  = (PI*ADV - RJ0(L)) / (RJ0(L+1) - RJ0(L))
C
          EFLO = EF(L  ,K) + FRK*(EF(L  ,K+1)-EF(L  ,K))
          EFLP = EF(L+1,K) + FRK*(EF(L+1,K+1)-EF(L+1,K))
          EFF = EFLO + FRL*(EFLP-EFLO)
C
          CPI(I) = PC * EFF
        ELSE
          CPI(I) = PC * ADV
        ENDIF
C
        WRITE(*,*) K, L, FRK, FRL
        WRITE(*,*) EF(L,K+1), EF(L+1,K+1)
        WRITE(*,*) EF(L,K  ), EF(L+1,K  )


        WRITE(*,*) ' Pc, V/wR, eff: ', PC, ADV, EFF
 93   CONTINUE
      NPTS = N
C
 94   CONTINUE
C
      CALL NEWPEN(5)
      CALL XYLINE(NPTS,RJI,CPI,0.0,RJWT,0.0,CPWT,2)
      CALL XYSYMB(NPTS,RJI,CPI,0.0,RJWT,0.0,CPWT,0.8*CS,IENG)
      CALL PLFLUSH
C
 950  CONTINUE
C
 990  CALL ANNOT(1.2*CS)
C
      CALL ASKL('Hardcopy current plot ?^',YES)
      IF(YES) THEN
       CALL PLEND
       CALL REPLOT(IDEVRP)
      ENDIF
C
      CALL PLCLOSE
      STOP
      END ! JPLOT



