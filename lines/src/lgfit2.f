***********************
      SUBROUTINE LGFIT2
***********************
*     stripped version of von Meerwall's  program lgfit2.
*     for multiple gaussian fitting
*
*     ref : E von Meerwall (1975) Computer Physics Communications
*           vol 9, pp 117 - 128.
*
*     INPUT PARAMETERS :
*     SCALEFACTOR data must be >> 1 to get convergence, have been scaled
*                 up before call to LGFIT2
*     NPAR     number of spectral line parameters to be fitted (up to MAXPAR)
*     NP       number of points in spectrum (set to MAXDATA)
*     NC       number of constraints
*     MC       number of random parameter steps to test minimum (0-5)
*     NDROP    number of worst fitted data points to be ignored (0)
*     IFL      line type (unused- selects Lorentzian or Gaussian)
*     IFD      spectrum integration (unused)
*     IFBGS    background fit (set to 0 for baseline offset only)
*     TERM     tolerance level, 10**-3 < term < 10**-5
*     P(I)     line centroid in x units
*     P(I+1)   line height
*     P(I+2)   line fwhm in x units
*     X(I)     x value of spectrum point (abscissa)
*     Y(I)     y value of spectrum point (ordinate)
*     WT(I)    weight of spectrum point (deleted)
*
*     other subroutines called:
*     fdel
*
      IMPLICIT REAL*8 (A-H,O-Z)
*
      INTEGER*4 MAXLINESL            ! max number of gaussians to fit
      PARAMETER (MAXLINESL  = 50)    ! for local arrays
      INTEGER*4 A12(MAXLINESL*3)     ! local parameter on/off switch
*     local working arrays
      REAL*8    DELT(MAXLINESL*3+1)         
      REAL*8    DELT1(MAXLINESL*3+1)
      REAL*8    ERR(MAXLINESL*3+1)
*unused!      REAL*8    G(MAXLINESL+1)
      REAL*8    H(MAXLINESL*3+1,MAXLINESL*3+1)
      REAL*8    HPP(MAXLINESL*3+1)
      REAL*8    PS(MAXLINESL*3+1)
      REAL*8    PSAVE(MAXLINESL*3+1)
*
      INCLUDE 'lines.inc'
*
      DATA  ER / 6.0D0 /, FACTOR / 1.0645D0 /
*
      IF (DB) PRINT *,'in LGFIT2, NPAR = ',NPAR,' NP = ',NP,
     &    'FIXBASE=',FIXBASE
*
*     set number of random steps = MC = 2
      MC = 2
      NRS = MC + 2
*
*     set default constraints (to 'off') -added 96/12 alex
      DO I = 1,NPAR
          A12(I) = 1
      END DO
*
*     set tolerance level = TERM = 10**-4
      TERM = 1.0D-4
      NPA = NPAR + 1
*     set baseline to zero
      P(NPA) = 0.0D0
      DO 150 I = 1,NPA,1
          PSAVE(I) = P(I)
  150 CONTINUE
*
*     initial values for error matrix H
*     ---------------------------------
      CALL FDEL (DELT1,FX2)
      DO 210 I = 1,NPA,1
          DO 200 J = 1,NPA,1
              H(I,J) = 1.0D-10
  200     CONTINUE
  210 CONTINUE
*
      DO 220 N = 1,NPAR,3
*
*                 official version with N+2
*
C                  DUMMY = P(N+2) / DELT1(N)
*
*                 test version with N
*
                  DUMMY = P(N) / DELT1(N)
*
         H(N,N) = DABS(DUMMY) * 0.005D0
                      DUMMY = P(N+1) / DELT1(N+1)
         H(N+1,N+1) = DABS(DUMMY) * 0.005D0
                      DUMMY = P(N+2) / DELT1(N+2)
         H(N+2,N+2) = DABS(DUMMY) * 0.005D0
  220 CONTINUE
                   DUMMY = P(2) / DELT1(NPA)
      H(NPA,NPA) = DABS(DUMMY) * 0.005D0
*
      DO 230 J = 1,NPA,1
         IF (DABS(DELT1(J)) .LT. 5.0D-3) H(J,J) = 5.0D-4
  230 CONTINUE
*
*
*   Constraint input and preparation 96/12 alex
*
       NC=0
       DO I=1,NPAR
          A12(I) = A12IN(I)
          IF (DB) THEN
             PRINT *,'A12(',I,')= ',A12(I)
          END IF
       END DO
*
*      count the constraints 96/12 alex
       DO I=1,NPAR
            IF (A12(I) .EQ. 0) NC=NC+1
       END DO
*
*     Build constraint info into matrix H  96/12 alex
*
      DO J = 1,NPAR
         IF (A12(J) .EQ. 0) THEN
*           set the appropriate row in H to zero 96/12 alex
*
*           (this isn't what the original lgfit2 did. It had a more
*           complex constraining system. This just ensures that the
*           appropriate parameter doesn't get modified)
            DO I = 1,NPAR
               H(I,J) = 0
            END DO
         END IF
      END DO
*
*      baseline constraint input, based on alex mods to lgfit2/lines
      IF (FIXBASE) THEN
          DO I = 1, NPA
              H(I,NPA) = 0
          END DO
      END IF
*
*     print out input parameter values
*     --------------------------------
*     KK IS NUMBER OF STEPS TAKEN FOR FIT CYCLE
      KK = 0
      NH = 0
      RMSERR = DSQRT( FX2 / (NP - NPAR) )
      PRINT 2400
 2400 FORMAT(/' Initial entries :')
      PRINT 2450, NH, KK, RMSERR
      PRINT 2470, KK
      DO 250 I = 1,NPAR,3
         PRINT 2500, P(I), P(I+1)/SCALEFACTOR, P(I+2)
C        PRINT 2550, DELT1(I), DELT1(I+1), DELT1(I+2)
  250 CONTINUE
c2550 FORMAT(6X,'+-',2X,3(F12.6,3X))
      PRINT 2600
 2600 FORMAT(/' Iterative fit :')
      FMIN = FX2
      DO 270 I = 1,NPA,1
         ERR(I) = H(I,I)
         PS(I) = P(I)
  270 CONTINUE
*
*     FITTING PROCEDURE
      FY = FX2
*
*     LOOP OVER FIT CYCLES
*     --------------------
      DO 490 NH = 1,NRS,1
         KK = 0
         IF (NH .EQ. 1) GO TO 350
*
            FY = FMIN
            IF (NH .LE. 2) GO TO 350
*
               NHM2 = NH - 2
               PRINT 3100, NHM2
 3100          FORMAT(/' Random step',I3,' :')
*
*              random step
*              -----------
               CQ = 5 * NH / NPA
               CQ = 1.0 + DSQRT(CQ)
               DO 320 I = 1,NPAR,3
*                 ensure no overflow of sine argument ...
                  FACTOR = DMIN1( 400D0*CQ*P(I) , 16383D0 )
*                 make sure constrained parameters aren't changed
                  IF (A12(I) .NE. 0)
     &             P(I) = PS(I) + 0.02D0*CQ*PS(I+2)*DSIN(FACTOR)
                  FACTOR = DMIN1( 500D0*CQ*P(I+1) , 16383D0 )
                  IF (A12(I+1) .NE. 0)
     &             P(I+1) = PS(I+1) + 0.02D0*CQ*PS(I+1)*DSIN(FACTOR)
                  FACTOR = DMIN1( 600d0*CQ*P(I+2) , 16383D0 )
                  IF (A12(I+2) .NE. 0)
     &             P(I+2) = PS(I+2) + 0.03D0*CQ*PS(I+2)*DSIN(FACTOR)
  320          CONTINUE
               FACTOR = DMIN1( 300D0*CQ*P(NPA) , 16383D0 )
*              if fixed baseline then do not change it
               IF (FIXBASE) THEN
                   P(NPA) = 0
               ELSE
                   P(NPA) = PS(NPA) + 0.02D0 * CQ * PS(2)*DSIN(FACTOR)
               END IF
               IF (NC .EQ. 0) GO TO 8761 
*
 8761          CALL FDEL (DELT1,FX2)
*
  350    KK = KK + 1
*
*        go to new minimum
*        -----------------
         DO 360 K = 1,NPA,1
            HPP(K) = 0.0D0
            DO 355 I = 1,NPA,1
               HPP(K) = HPP(K) + H(K,I)*DELT1(I)
  355       CONTINUE
  360    CONTINUE
         DO 365 I = 1,NPA,1
*           constraint check
            IF (A12(I) .NE. 0)
     &       P(I) = P(I) - HPP(I)
  365    CONTINUE
*        constrain baseline
         IF (FIXBASE) THEN
            P(NPA) = 0
         END IF                      
*
*        calculation of closeness to minimum
*        -----------------------------------
         FB = FY
         CALL FDEL (DELT,FY)
         IF (FY .GE. FMIN) GO TO 380
            FMIN = FY
            DO 370 I = 1,NPA,1
               ERR(I) = H(I,I)
               PS(I) = P(I)
  370       CONTINUE
  380    DO 390 K = 1,NPA,1
            HP(K) = 0.0D0
            DO 385 I = 1,NPA,1
               HP(K) = HP(K) + H(K,I)*DELT(I)
  385       CONTINUE
  390    CONTINUE
         EM = 0.0D0
         EN = 0.0D0
         DO 395 J = 1,NPA,1
            EN = EN + DELT(J)*HP(J)
            EM = EM + DELT(J)*HPP(J)
  395    CONTINUE
*
*        coefficient for updating H
*        --------------------------
         A1 = -EN / (ER - 1.0D0)
         A2 =  EN / (ER + 1.0D0)
         A3 =  ER * A2
         A4 = -ER * A1
         IF (EM .GE. A1)  GO TO 401
            CF = 1.0D0 / (EM - EN)
            GO TO 410
  401    IF (EM .GT. A2)  GO TO 402
            CF = 1.0D0 / (ER*EN) - 1.0D0 / EN
            GO TO 410
  402    IF (EM .GT. A3)  GO TO 403
            CF = (EN - 2.0D0*EM) / (EN*(EM - EN))
            GO TO 410
  403    IF (EM .GT. A4)  GO TO 404
            CF = (ER - 1.0D0) / EN
            GO TO 410
  404    CF = 1.0D0 / (EM - EN)
*
*        new H
*        -----
  410    DO 420 I = 1,NPA,1
            DELT1(I) = DELT(I)
            ISET = I
            DO 415 J = 1,ISET,1
               H(J,I) = H(I,J) + HP(I) * HP(J) * CF
               H(I,J) = H(J,I)
  415       CONTINUE
*           setting the appropriate row of the new H to zero as before
            DO J = 1,NPAR
*              constraint check
               IF (A12(J) .EQ. 0) THEN
                  DO K = 1,NPAR
                     H(K,J) = 0
                  END DO
               END IF
            END DO
  420    CONTINUE
*        baseline constraint - set row of H to zero
         IF (FIXBASE) THEN
             DO K = 1, NPA
                 H(K,NPA) = 0
             END DO
         END IF
         
*
*         end of iteration - termination tests
*         ------------------------------------
          NPX = NPA - NC + 3
          IF (NH .EQ. NRS .AND. KK .EQ. NPA .AND. EN .GE. TERM)
     *         NPX = NPX + 4
          IF (NPX .GT. 54) NPX = 54
          IF (EN .GT. TERM .AND. KK .LE. NPX)  GO TO 350
          IF (NH .EQ. 1 .AND. KK .LE. 7)  GO TO 350
*
*        end of cycle
*        ------------
         RMSERR = DSQRT ( FMIN / (NP - NPAR) )
         PRINT 2450, NH, KK, RMSERR/SCALEFACTOR
 2450    FORMAT(/' Cycle',I3,' took',I3,' steps. ',
     *          'Residual RMS error is',F12.6)
         IF (NH .EQ. NRS) GOTO 490
*
*        end of fit
*        ----------
         PRINT 2470, KK
         FB = FMIN
         DO 450 I = 1,NPAR,3
            PRINT 2500, PS(I), PS(I+1)/SCALEFACTOR, PS(I+2)
  450    CONTINUE
 2500    FORMAT( 8X,3(F12.6,3X))
         PRINT 2505, PS(NPA)
 2505    FORMAT(3X,'Baseline at ',F12.6)
  490 CONTINUE
*
*     final values, tables, plots
*     ---------------------------
      DO 510 I = 1,NPA,1
         P(I) = PS(I)
  510 CONTINUE
      BGS = P(NPA)
      DO 520 I = 3,NPAR,3
         IF (P(I) .LT. 0.0D0) P(I) = -P(I)
  520 CONTINUE
      NTOT = (NPA + 2) * NRS
      PRINT 2470, NTOT
 2470 FORMAT(' Step',I3,2X,'Position',8X,'Height',8X,'Width')
      DO 530 I = 1,NPAR,3
         PRINT 2500, P(I), P(I+1)/SCALEFACTOR, P(I+2)
  530 CONTINUE
      PRINT 2505, P(NPA)
*
*     final parameters and uncertainties,
*     real and fractional line intensities
*     ------------------------------------
      DO 550 I = 1,NPA,1
         DUMMY = ERR(I)
         HP(I) = DSQRT(DUMMY)
  550 CONTINUE
      A = 0.0D0
      DO 560 I = 1,NPAR,3
         PS(I) = P(I+1) * P(I+2) * FACTOR
         A = A + PS(I)
  560 CONTINUE
      PRINT 5600
 5600 FORMAT(/' FINAL PARAMETERS')
      NLINE = 0
      DO 570 I = 1,NPAR,3
         B = PS(I) / A
         NLINE = NLINE + 1
         PRINT 5700, NLINE, P(I), HP(I), 
     &               P(I+1)/SCALEFACTOR, HP(I+1)/SCALEFACTOR,
     *               P(I+2), HP(I+2), 
     &               PS(I)/SCALEFACTOR, B
  570 CONTINUE
 5700 FORMAT (' LINE',I3,'  Position',F14.6,' +- ',F12.6/
     *        9X,' Height',F16.6,' +- ',F12.6/
     *        9X,' Width',F17.6,' +- ',F12.6/
     *        9X,' Direct and fractional intensities ',E12.6,1X,1PE12.6)
      PRINT 5750, P(NPA)/SCALEFACTOR, HP(NPA)/SCALEFACTOR
 5750 FORMAT (9X,' Baseline at ',F12.6,' +- ',F12.6)
*
*     point by point table of values and fit
*     --------------------------------------
*     SMSQDV IS THE SUMS OF THE SQUARES OF THE DEVIATIONS
      SMSQDV = 0.0
      DO 585 I = 1,NP,1
         Z = BGS
         DO 580 K = 1,NPAR,3
*           gaussian function
            DUMMY = ((X(I) - P(K)) / P(K+2))**2 * (-2.7726D0)
            Z = Z + P(K+1) * DEXP(DUMMY)
  580    CONTINUE
         Z1 = Z - Y(I)
         Z12 = Z1 * Z1
         GX  = GX + Z1
*
*        store fitted gaussians and residue for plotting
         GAUS(I) = Z
         RES(I)  = (Y(I) - Z)
         SMSQDV = SMSQDV + RES(I)**2
  585 CONTINUE
      RETURN
*
      END
*
*********
