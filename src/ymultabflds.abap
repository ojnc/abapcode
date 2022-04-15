*&---------------------------------------------------------------------*
*& Report  YMULTABFLDS                                                 *
*& Output Table Fields to a List                                       *
*&---------------------------------------------------------------------*

REPORT  ymultabflds NO STANDARD PAGE HEADING LINE-SIZE 255
LINE-COUNT 60
MESSAGE-ID ym.

TABLES: dd02l, dd02t, dd03l, dd03t, dd04t.

DATA: BEGIN OF mytable,
  tabname  LIKE dd02l-tabname,
  as4local LIKE dd02l-as4local,
  as4vers  LIKE dd02l-as4vers,
  ddtext   LIKE dd02t-ddtext,
END OF mytable.

*Internal table to upload data into
DATA: BEGIN OF i_datatab OCCURS 0,
  thetable TYPE String,
END OF i_datatab.

DATA: wline TYPE char200.

**Use this block to declare PARAMETERS and SELECT-OPTIONS
PARAMETERS: p_infile LIKE rlgrap-filename MEMORY ID m01 OBLIGATORY.

**Use this EVENT to initialize the SELECTION-SCREEN variables
INITIALIZATION.

**Use this EVENT to validate SELECTION-SCREEN
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infile.
CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
EXPORTING
  MASK      = '*.txt'
  STATIC    = 'X'
CHANGING
  file_name = p_infile.

**Use this EVENT to Select, Process the data
START-OF-SELECTION.
PERFORM f_process_data.

**Use this Event to display data
END-OF-SELECTION.

PERFORM f_display_data.


*&---------------------------------------------------------------------*
*&      Form  F_PROCESS_DATA
*&---------------------------------------------------------------------*
FORM f_process_data .

  DATA: l_file    TYPE string.

  MOVE p_infile TO l_file.

  CALL FUNCTION 'GUI_UPLOAD'
  EXPORTING
    filename                = l_file
    filetype                = 'ASC'
  TABLES
    data_tab                = i_datatab
  EXCEPTIONS
    file_open_error         = 1
    file_read_error         = 2
    no_batch                = 3
    gui_refuse_filetransfer = 4
    invalid_type            = 5
    no_authority            = 6
    unknown_error           = 7
    bad_data_format         = 8
    header_not_allowed      = 9
    separator_not_allowed   = 10
    header_too_long         = 11
    unknown_dp_error        = 12
    access_denied           = 13
    dp_out_of_memory        = 14
    disk_full               = 15
    dp_timeout              = 16
    OTHERS                  = 17.

  IF sy-subrc <> 0.
    MESSAGE e011.
  ENDIF.


ENDFORM.                    " F_PROCESS_DATA

*&---------------------------------------------------------------------*
*&      Form  F_DISPLAY_DATA
*&---------------------------------------------------------------------*
FORM f_display_data.

  LOOP AT i_datatab.

    CLEAR mytable.

    SELECT SINGLE tabname as4local as4vers
    INTO CORRESPONDING FIELDS OF mytable FROM dd03l
    WHERE tabname = i_datatab-thetable.

    SELECT SINGLE ddtext
    INTO CORRESPONDING FIELDS OF mytable FROM dd02t
    WHERE tabname = i_datatab-thetable
    AND ddlanguage = 'E'.

    "    WRITE: / 'B# ', 4 i_datatab-thetable, 14 mytable-as4local,
    "             16 mytable-as4vers, 21 mytable-ddtext.
    WRITE: / 'B# ', 4 i_datatab-thetable, 35 mytable-ddtext.

    SELECT *
    FROM dd03l
    WHERE tabname = mytable-tabname
    AND as4local = mytable-as4local
    AND as4vers = mytable-as4vers
    ORDER BY POSITION.

*  B# DD03L                          Table Fields
*  TABNAME     TABNAME  X DD02L      C 000030  00           CHAR Table Name
*  FIELDNAME   FIELDNAMEX            C 000030  00           CHAR Field Name
*  KEYFLAG     KEYFLAG               C 000001  00           CHAR Identifies a key field of a table
*  ROLLNAME    ROLLNAME   DD04L      C 000030  00           CHAR Data element (semantic domain)
*  CHECKTABLE  CHECKTABL             C 000030  00           CHAR Check table name of the foreign key
*  INTTYPE     INTTYPE               C 000001  00           CHAR ABAP data type (C,D,N,...)
*  INTLEN      INTLEN                N 000006  00           NUMC Internal Length in Bytes
*  REFTABLE    REFTABLE              C 000030  00           CHAR Reference Table for Field
*  DATATYPE    DATATYPE_             C 000004  00           CHAR Data Type in ABAP Dictionary
*  LENG        DDLENG                N 000006  00           NUMC Length (No. of Characters)
*  DECIMALS    DECIMALS              N 000006  00           NUMC Number of Decimal Places
*  E# DD03L                          Table Fields

      IF dd03l-keyflag IS INITIAL.
        MOVE '.' TO dd03l-keyflag.
      ENDIF.

*      WRITE: / dd03l-fieldname, 11 dd03l-keyflag, 13 dd03l-rollname,
*      24 dd03l-checktable, 35 dd03l-inttype, 37 dd03l-leng ,
*      45 dd03l-decimals, 47 dd03l-reftable, 58 dd03l-datatype.

      CLEAR dd03t-ddtext.

      SELECT SINGLE ddtext
      INTO dd03t-ddtext
      FROM dd03t
      WHERE tabname  = mytable-tabname
      AND fieldname  = dd03l-fieldname
      AND as4local   = mytable-as4local
      AND ddlanguage = 'E'.

      IF dd03t-ddtext IS INITIAL.
        SELECT SINGLE ddtext
        INTO dd03t-ddtext
        FROM dd04t
        WHERE rollname  = dd03l-rollname
        AND as4local  = mytable-as4local
        AND as4vers    = mytable-as4vers
        AND ddlanguage = 'E'.
      ENDIF.

*      WRITE: 63 dd04t-ddtext.

      CONCATENATE dd03l-fieldname dd03l-rollname dd03l-keyflag dd03l-checktable
      dd03l-inttype dd03l-leng dd03l-DECIMALS
      dd03l-reftable dd03l-datatype dd03t-ddtext INTO wline SEPARATED BY '  '.

      WRITE wline.

    ENDSELECT.

*    WRITE: / 'E# ', 4 mytable-tabname, 14 mytable-as4local,
*             16 mytable-as4vers, 21 mytable-ddtext.

    WRITE: / 'E# ', 4 mytable-tabname, 35 mytable-ddtext.

    WRITE: / '---------------------------------------------',
    '---------------------------------------------'.
  ENDLOOP.

ENDFORM.                    " F_DISPLAY_DATA