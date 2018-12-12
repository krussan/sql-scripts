@echo off
FOR /F %%A IN ('WMIC OS GET LocalDateTime ^| FINDSTR \.') DO @SET B=%%A

set logFileName=log/liquibase-%B:~0,4%-%B:~4,2%-%B:~6,2%-%B:~8,2%_%B:~10,2%.log

call ./liquibase-app/liquibase --logLevel=info --logFile=%logFileName% --changeLogFile=update.xml update

cat %logFileName%
