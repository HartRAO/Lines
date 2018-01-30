***********************
      SUBROUTINE GCPARM (ERROR)
***********************
*     get parameters for gain curve polynomial as function of hour angle
*
*     CMDP command parameters used:
*     1 = command mnemonic GCP
*     2 = position or SHOW or CLEAR or coefficient 0
*     3 = coefficient 1 etc
*
*     other subroutines called:
*     none
*
      IMPLICIT  NONE
      INTEGER   ERROR           ! output error status
      INTEGER   I               ! loop index
      INTEGER   IOS             ! file error check
      INTEGER   NCH             ! no. characters in buffer
      INTEGER   NCHAR           ! external function
*
      INCLUDE 'lines.inc'
*
      IF (DB) PRINT *,'in MGPARM'
      ERROR = 0
*
      IF (NCMD .GE. 2) CALL UPCASE (CMDP(2))
*
*     see if the CLEAR command has been given
      IF (CMDP(2)(1:5) .EQ. 'CLEAR') NGCC = 0
*
      IF (NCMD .EQ. 1 .OR.
     &    NCMD .EQ. 2 .AND. CMDP(2)(1:4) .EQ. 'SHOW') THEN
*
          WRITE (BUF,*) 'Gain correction coefficients:'
          PRINT *,BUF(1:NCHAR(BUF))
          IF (WRITELOG) WRITE (LOGWRTUNIT,*) BUF(1:NCHAR(BUF))
*
          IF (NGCC .GT. 0) THEN
              DO I = 1, NGCC
*                 write out the coefficient
                  WRITE (BUF,'(A,I1, 1X,E16.8)') 'HA**',I-1,GCC(I)
                  NCH = NCHAR(BUF)
                  PRINT *,BUF(1:NCH)
                  IF (WRITELOG) WRITE (LOGWRTUNIT,*) BUF(1:NCH)
              END DO
          ELSE
              PRINT *,'none'
          END IF
      END IF
*
      IF (CMDP(2)(1:4) .EQ. 'SHOW' .OR.
     &    CMDP(2)(1:5) .EQ. 'CLEAR') RETURN
*
*
      IF (NCMD .GE. 3) THEN
*         read the coefficients from the command line buffer
          NGCC = 0
          DO I = 2, NCMD
              READ (CMDP(I),*,IOSTAT=IOS,ERR=210) GCC(NGCC+1)
  210         IF (IOS .NE. 0) THEN
                  PRINT 2005, CMDP(2)(1:NCHAR(CMDP(2)))
                  ERROR = IOS
                  RETURN
              END IF
              NGCC = NGCC + 1
          END DO
      ELSE
*         read the coefficients entered by the user at the prompt
          NGCC = 0
          DO I = 1, MAXCMDPARMS - 1
              GCC(I) = -1D0
          END DO
          DO WHILE (GCC(NGCC+1) .NE. 0D0)
              PRINT '(A,I1,A$)',' Gain corr coeff for HA**',NGCC,'? '
              READ '(A)', BUF
              READ (BUF,*,ERR=250,IOSTAT=IOS) GCC(NGCC+1)
  250         IF (IOS .NE. 0) THEN
                  PRINT 2005,BUF(1:NCHAR(BUF))
                  ERROR = IOS
                  RETURN
              END IF
              IF (GCC(NGCC+1) .NE. 0D0) NGCC = NGCC + 1
          END DO 
      END IF
      RETURN
*
 2005 FORMAT ('illegal: ',A)
      END 
*********