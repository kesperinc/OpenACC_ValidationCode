#ifndef T1
!T1:runtime,data,executable-data,async,construct-independent,V:2.5-2.7
      LOGICAL FUNCTION test1()
        USE OPENACC
        IMPLICIT NONE
        INCLUDE "acc_testsuite.Fh"
        INTEGER :: x !Iterators
        REAL(8),DIMENSION(LOOPCOUNT):: a, b, c, d, e, f !Data
        REAL(8) :: RAND
        INTEGER :: errors = 0

        !Initilization
        SEEDDIM(1) = 1
#       ifdef SEED
        SEEDDIM(1) = SEED
#       endif
        CALL RANDOM_SEED(PUT=SEEDDIM)
        CALL RANDOM_NUMBER(a)
        CALL RANDOM_NUMBER(b)
        c = 0
        CALL RANDOM_NUMBER(d)
        CALL RANDOM_NUMBER(e)
        f = 0

        !$acc enter data create(c(1:LOOPCOUNT), f(1:LOOPCOUNT))

        !$acc data copyin(a(1:LOOPCOUNT), b(1:LOOPCOUNT), d(1:LOOPCOUNT), e(1:LOOPCOUNT)) present(c(1:LOOPCOUNT), f(1:LOOPCOUNT))
          !$acc parallel async(1)
            !$acc loop
            DO x = 1, LOOPCOUNT
              c(x) = a(x) + b(x)
            END DO
          !$acc end parallel
          !$acc parallel async(2)
            !$acc loop
            DO x = 1, LOOPCOUNT
              f(x) = d(x) + e(x)
            END DO
          !$acc end parallel
          CALL acc_copyout_async(c(1:LOOPCOUNT), 1)
          CALL acc_copyout_async(f(1:LOOPCOUNT), 2)
        !$acc end data
        !$acc wait
        DO x = 1, LOOPCOUNT
          IF (abs(c(x) - (a(x) + b(x))) .gt. PRECISION) THEN
            errors = errors + 1
          END IF
          IF (abs(f(x) - (d(x) + e(x))) .gt. PRECISION) THEN
            errors = errors + 1
          END IF
        END DO
        IF (errors .eq. 0) THEN
          test1 = .FALSE.
        ELSE
          test1 = .TRUE.
        END IF
      END
#endif

      PROGRAM main
      IMPLICIT NONE
      INTEGER :: failcode, testrun
      LOGICAL :: failed
      INCLUDE "acc_testsuite.Fh"
      !Conditionally define test functions
#ifndef T1
      LOGICAL :: test1
#endif
      failcode = 0
      failed = .FALSE.

#ifndef T1
      DO testrun = 1, NUM_TEST_CALLS
        failed = failed .or. test1()
      END DO
      IF (failed) THEN
        failcode = failcode + 2 ** 0
        failed = .FALSE.
      END IF
#endif

      CALL EXIT (failcode)
      END PROGRAM

