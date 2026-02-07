H DFTACTGRP(*NO) BNDDIR('QSys.Lib/QSYS.BNDDIR')
     H OPTION(*SRCSTMT:*NODEBUGIO)
     
     // File Definition
     FEMPLOYEEMASTER IF   E           K DISK
     F                                 RENAME(EMPLOYEEMASTER:EMPREC)
     FEMPLOYEEMASTER UF   E           K DISK
     F                                 RENAME(EMPLOYEEMASTER:EMPUPD)
     
     // Data Structures
     D EmpDS           DS           QUALIFIED
     D  CustId                      10A
     D  RecordContent             1024A
     D  RecordCount                5I 0
     D  RowNum                      5I 0
     
     D DupArray        S                   DIM(9999)
     D                                     QUALIFIED
     D  CustId                      10A
     D  Count                        5I 0
     D  Displayed                     1A
     
     // Work Variables
     D DupCount        S              5I 0
     D TotalDups       S              5I 0
     D i               S              5I 0
     D j               S              5I 0
     D k               S              5I 0
     D Found           S               N
     D DeleteConfirm   S              1A
     D DeleteCount     S              5I 0
     D FirstRecord     S               N   INZ(*ON)
     
     /FREE
     
       EXSR DisplayHeader;
       
       EXSR FindDuplicates;
       
       IF DupCount > 0;
         EXSR DisplayDuplicates;
         EXSR DeleteDuplicates;
       ELSE;
         DSPLY 'No Duplicate Records Found in Employee Master';
       ENDIF;
       
       EVAL *INLR = *ON;
       RETURN;
     
       // ============================================================
       // Subroutine: Display Header
       // ============================================================
       BEGSR DisplayHeader;
         DSPLY *BLANK;
         DSPLY '====================================';
         DSPLY 'DUPLICATE RECORD FINDER - EMPLOYEE';
         DSPLY '====================================';
         DSPLY *BLANK;
       ENDSR;
     
       // ============================================================
       // Subroutine: Find Duplicates Based on Customer ID
       // ============================================================
       BEGSR FindDuplicates;
         
         DSPLY 'Scanning for Duplicate Customer IDs...';
         DupCount = 0;
         TotalDups = 0;
         
         // Reset file pointer
         SETLL *START EMPLOYEEMASTER;
         
         // Read all records
         DOW READE EMPREC;
           
           // Check if this Customer ID already exists in DupArray
           Found = *OFF;
           i = 1;
           
           DOW i <= DupCount;
             IF DupArray(i).CustId = EMPREC.CustId;
               // Duplicate found
               DupArray(i).Count = DupArray(i).Count + 1;
               TotalDups = TotalDups + 1;
               Found = *ON;
               LEAVE;
             ENDIF;
             i = i + 1;
           ENDDO;
           
           // If not found in array, add it
           IF NOT Found AND DupCount < 9999;
             DupCount = DupCount + 1;
             DupArray(DupCount).CustId = EMPREC.CustId;
             DupArray(DupCount).Count = 1;
             DupArray(DupCount).Displayed = 'N';
           ENDIF;
           
         ENDDO;
         
         // Keep only records with duplicates (Count > 1)
         k = 0;
         FOR i = 1 TO DupCount;
           IF DupArray(i).Count > 1;
             k = k + 1;
             IF k < i;
               DupArray(k) = DupArray(i);
             ENDIF;
           ENDIF;
         ENDFOR;
         DupCount = k;
         
       ENDSR;
     
       // ============================================================
       // Subroutine: Display Duplicate Records on Screen
       // ============================================================
       BEGSR DisplayDuplicates;
         
         DSPLY *BLANK;
         DSPLY 'DUPLICATE RECORDS FOUND: ' + %CHAR(DupCount);
         DSPLY '========================================';
         DSPLY *BLANK;
         
         FirstRecord = *ON;
         
         FOR i = 1 TO DupCount;
           
           DSPLY 'Customer ID: ' + DupArray(i).CustId + 
                 ' | Occurrences: ' + %CHAR(DupArray(i).Count);
           DSPLY '----------------------------------------';
           
           // Display all records with this Customer ID
           SETLL (DupArray(i).CustId) EMPLOYEEMASTER;
           
           k = 0;
           DOW READE EMPREC;
             IF EMPREC.CustId <> DupArray(i).CustId;
               LEAVE;
             ENDIF;
             
             k = k + 1;
             DSPLY '  Record ' + %CHAR(k) + ':';
             
             // Display key fields (adjust field names to your file structure)
             DSPLY '    Customer ID: ' + EMPREC.CustId;
             
             // Add more field displays as needed based on your file structure
             // DSPLY '    Employee Name: ' + EMPREC.EmpName;
             // DSPLY '    Salary: ' + %CHAR(EMPREC.Salary);
             // DSPLY '    Department: ' + EMPREC.Department;
             
             DSPLY *BLANK;
           ENDDO;
           
           DSPLY *BLANK;
         ENDFOR;
         
       ENDSR;
     
       // ============================================================
       // Subroutine: Delete Duplicate Records
       // ============================================================
       BEGSR DeleteDuplicates;
         
         DSPLY *BLANK;
         DSPLY '========================================';
         DSPLY 'Delete duplicate records? (Y/N)';
         ACCEPT DeleteConfirm;
         
         IF DeleteConfirm = 'Y' OR DeleteConfirm = 'y';
           
           DeleteCount = 0;
           
           FOR i = 1 TO DupCount;
             
             // Get all records with this Customer ID
             SETLL (DupArray(i).CustId) EMPLOYEEMASTER;
             
             k = 0;
             DOW READE EMPUPD;
               IF EMPUPD.CustId <> DupArray(i).CustId;
                 LEAVE;
               ENDIF;
               
               k = k + 1;
               
               // Keep first record, delete duplicates
               IF k > 1;
                 DELETE EMPUPD;
                 DeleteCount = DeleteCount + 1;
                 DSPLY 'Deleted: ' + EMPUPD.CustId + ' (Record ' + 
                       %CHAR(k) + ')';
               ENDIF;
             ENDDO;
           ENDFOR;
           
           DSPLY *BLANK;
           DSPLY 'Total Records Deleted: ' + %CHAR(DeleteCount);
           DSPLY 'Duplicate Cleanup Complete!';
           
         ELSE;
           DSPLY 'Delete operation cancelled.';
         ENDIF;
       ENDSR;
     
     /END-FREE
