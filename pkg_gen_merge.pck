CREATE OR REPLACE PACKAGE pkg_gen_merge IS

   FUNCTION fn_replace_badness( pv_string IN VARCHAR2,
                                pv_remove_chr10s IN VARCHAR2 DEFAULT 'N' ) RETURN VARCHAR2;

   FUNCTION fn_format_clob( pv_string IN CLOB,
                                pv_remove_chr10s IN VARCHAR2 DEFAULT 'N' ) RETURN CLOB;

   PROCEDURE sp_gen_merge(pv_tab_name IN VARCHAR2,
                          pv_override_uk IN VARCHAR2 DEFAULT NULL,
                          pv_restrict_uk IN VARCHAR2 DEFAULT NULL,
                          pv_flatten_row IN VARCHAR2 DEFAULT 'N');

END pkg_gen_merge;
/
CREATE OR REPLACE PACKAGE BODY pkg_gen_merge IS

   g_date_format VARCHAR2(50):='DD-MON-YYYY';

   FUNCTION fn_compress_spaces( pv_string IN CLOB) RETURN CLOB IS

      lv_retval   CLOB;
      lv_buf      CLOB;
   BEGIN

      lv_retval := pv_string;
      lv_buf := REPLACE( pv_string, '  ', ' ');

      WHILE lv_buf != lv_retval
        LOOP
        lv_retval := lv_buf;
        lv_buf := REPLACE( lv_retval, '  ', ' ');
      END LOOP;

      RETURN lv_retval;

   END fn_compress_spaces;

   FUNCTION fn_escape_chars( pv_string IN CLOB) RETURN CLOB IS

      lv_retval   CLOB;
   BEGIN

      lv_retval := REPLACE( pv_string, chr(39),'''||CHR(39)||''');
      lv_retval := REPLACE( lv_retval, chr(10),' ');
      lv_retval := REPLACE( lv_retval, chr(13),' ');

      RETURN fn_compress_spaces(lv_retval);

   END fn_escape_chars;

   FUNCTION fn_chop_string(pv_string IN CLOB)
      RETURN CLOB IS

      lv_retval CLOB := '';
      lv_buf CLOB := '';
      lv_cnt NUMBER :=0;

      STRING_LEN NUMBER := 1500;

   BEGIN

      lv_buf := substr(STR1 => pv_string, POS => (lv_cnt * STRING_LEN)+1, LEN => STRING_LEN);

      IF length(lv_buf) = STRING_LEN THEN

        WHILE length(lv_buf) = STRING_LEN
        LOOP

          lv_cnt := lv_cnt + 1;
          lv_retval := lv_retval || ' to_clob(''' || fn_escape_chars(lv_buf) || ''') || ';
          lv_buf := substr(STR1 => pv_string, POS => (lv_cnt * STRING_LEN)+1, LEN => STRING_LEN);

        END LOOP;

        IF length(lv_buf) > 0 THEN
          lv_retval := lv_retval || ' to_clob(''' || fn_escape_chars(lv_buf) || ''') ';
        ELSE
          lv_retval := lv_retval || ' to_clob(''' || fn_escape_chars(' ') || ''') ';
        END IF;

      ELSE

        lv_retval := lv_retval || ' to_clob(''' || fn_escape_chars(pv_string) || ''') ';

      END IF;

      RETURN lv_retval;

   END fn_chop_string;

   FUNCTION fn_format_clob( pv_string IN CLOB,
                                pv_remove_chr10s IN VARCHAR2 DEFAULT 'N' ) RETURN CLOB IS

      lv_retval   CLOB;
   BEGIN


      lv_retval := REPLACE(REPLACE(fn_chop_string(pv_string),
                                   chr(10),' '),
                                   chr(13),' ');

      RETURN lv_retval;

   END fn_format_clob;

   FUNCTION fn_replace_badness( pv_string IN VARCHAR2,
                                pv_remove_chr10s IN VARCHAR2 DEFAULT 'N' ) RETURN VARCHAR2 IS

      lv_retval   VARCHAR2(32000);
   BEGIN

      lv_retval :=
       REPLACE( REPLACE( REPLACE( pv_string, chr(39),'''||CHR(39)||'''),
                                             chr(10),'''||CHR(10)||'''),
                                             chr(13),'''||CHR(13)||''');


      IF length(lv_retval) > 2000 THEN
         IF pv_remove_chr10s = 'Y' THEN
            lv_retval := REPLACE(REPLACE( lv_retval, '''||CHR(10)||''',' '),'   ',' ');
         ELSE
            lv_retval := REPLACE(lv_retval,'   ',' ');
         END IF;
      END IF;

      RETURN lv_retval;

   END fn_replace_badness;

   PROCEDURE sp_gen_merge(pv_tab_name IN VARCHAR2,
                          pv_override_uk IN VARCHAR2 DEFAULT NULL,
                          pv_restrict_uk IN VARCHAR2 DEFAULT NULL,
                          pv_flatten_row IN VARCHAR2 DEFAULT 'N' ) IS

      TYPE ltyp_ref_cursor IS REF CURSOR;
      lcur_ge_data   ltyp_ref_cursor;

      lb_first      BOOLEAN;
      lv_extract    VARCHAR2(32000);
      lv_datastring VARCHAR2(32000);
      lv_key_name   VARCHAR2(400);

      CURSOR lc_get_columns(cpv_tab_name IN VARCHAR2) IS
      SELECT utc.column_name,
             utc.data_type
      FROM   user_tab_columns utc
      WHERE  utc.table_name = upper(cpv_tab_name)
      ORDER BY utc.column_id;

      CURSOR lc_get_key_cols(cpv_tab_name IN VARCHAR2,
                             cpv_key_name IN VARCHAR2) IS
      SELECT ucc.column_name
      FROM user_cons_columns ucc
      WHERE ucc.table_name = upper(cpv_tab_name)
      AND ucc.constraint_name = cpv_key_name
      ORDER BY ucc.position;

      CURSOR lc_get_non_keys(cpv_tab_name IN VARCHAR2,
                             cpv_key_name IN VARCHAR2) IS
      SELECT utc.column_name
      FROM   user_tab_columns utc
      WHERE  utc.table_name = upper(cpv_tab_name)
      MINUS
      SELECT ucc.column_name
      FROM user_cons_columns ucc
      WHERE ucc.table_name = upper(cpv_tab_name)
      AND ucc.constraint_name = cpv_key_name;

      PROCEDURE pl( pv_text IN VARCHAR2) IS
      BEGIN
         dbms_output.put_line(pv_text);
      END;


   BEGIN

      IF pv_override_uk IS NOT NULL THEN
         lv_key_name := upper(pv_override_uk);
      ELSE
         lv_key_name := upper(pv_tab_name) || '_PK';
      END IF;

      pl('MERGE INTO ' || pv_tab_name || ' trg USING ' || chr(10) || '( ' );

      lv_extract := 'SELECT ';

      lb_first := TRUE;

      <<col_loop>>
      FOR lr_col IN lc_get_columns(pv_tab_name) LOOP


         IF lb_first THEN

            IF lr_col.data_type IN ('NUMBER') THEN
               lv_extract := lv_extract || ' ''SELECT   '' || nvl(to_char(drv.' || lower(lr_col.column_name) || '),''NULL'') || '' ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSIF lr_col.data_type IN ('DATE') THEN
               lv_extract := lv_extract || ' ''SELECT   to_date('''''' || nvl(to_char(drv.' || lower(lr_col.column_name) || ','''||g_date_format||'''),NULL) || '''''','''''||g_date_format||''''') ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSIF lr_col.data_type IN ('CLOB') THEN
               lv_extract := lv_extract || ' ''SELECT   '' || pkg_gen_merge.fn_format_clob(drv.' || lower(lr_col.column_name) || ','''||pv_flatten_row||''')|| '' ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSE
               lv_extract := lv_extract || ' ''SELECT   '''''' || pkg_gen_merge.fn_replace_badness(drv.' || lower(lr_col.column_name) || ','''||pv_flatten_row||''')|| '''''' ' || lower(lr_col.column_name) || '''' || CHR(10);
            END IF;
            lb_first := FALSE;

         ELSE

            IF lr_col.data_type IN ('NUMBER') THEN
               lv_extract := lv_extract || ' || '',   '' || nvl(to_char(drv.' || lower(lr_col.column_name) || '),''NULL'') || '' ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSIF lr_col.data_type IN ('DATE') THEN
               lv_extract := lv_extract || ' || '',   to_date('''''' || nvl(to_char(drv.' || lower(lr_col.column_name) || ','''||g_date_format||'''),NULL) || '''''','''''||g_date_format||''''') ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSIF lr_col.data_type IN ('CLOB') THEN
               lv_extract := lv_extract || ' || '',   '' || pkg_gen_merge.fn_format_clob(drv.' || lower(lr_col.column_name) || ','''||pv_flatten_row||''')|| '' ' || lower(lr_col.column_name) || '''' || CHR(10);
            ELSE
               lv_extract := lv_extract || ' || '',   '''''' || pkg_gen_merge.fn_replace_badness(drv.' || lower(lr_col.column_name) || ','''||pv_flatten_row||''')|| '''''' ' || lower(lr_col.column_name) || '''' || CHR(10);
            END IF;

         END IF;

      END LOOP col_loop;

      lv_extract := lv_extract || ' from ' || pv_tab_name || ' drv';

      IF pv_restrict_uk IS NOT NULL THEN
         lv_extract := lv_extract || ' where ' || pv_restrict_uk || ' ';
      END IF;

      lb_first := TRUE;

      OPEN lcur_ge_data FOR lv_extract;

      <<ge_data_loop>>
      LOOP

         FETCH lcur_ge_data INTO lv_datastring;
         EXIT WHEN lcur_ge_data%NOTFOUND;

         IF lb_first THEN
            lb_first := FALSE;
            pl(lv_datastring || ' FROM dual ');
         ELSE
            pl('UNION ALL');
            pl(lv_datastring || ' FROM dual ');
         END IF;

      END LOOP ge_data_loop;

      CLOSE lcur_ge_data;

      lb_first := TRUE;
      <<key_loop>>
      FOR lr_key IN lc_get_key_cols(pv_tab_name,lv_key_name) LOOP

         IF lb_first THEN
            pl(') src ON ( src.' || lr_key.column_name || ' = trg.' || lr_key.column_name);
            lb_first := FALSE;
         ELSE
            pl('   AND src.' || lr_key.column_name || ' = trg.' || lr_key.column_name);
         END IF;

      END LOOP key_loop;

      pl(' )');

      lb_first := TRUE;

      <<nokey_loop>>
      FOR lr_key IN lc_get_non_keys(pv_tab_name,lv_key_name) LOOP

         IF lb_first THEN
            pl(' WHEN MATCHED THEN UPDATE SET ');
            pl('    trg.' || lower(lr_key.column_name) || ' = src.' || lower(lr_key.column_name) );
            lb_first := FALSE;
         ELSE
            pl('   ,trg.' || lower(lr_key.column_name) || ' = src.' || lower(lr_key.column_name) );
         END IF;

      END LOOP nokey_loop;

      pl('WHEN NOT MATCHED THEN INSERT ( ');

      lb_first := TRUE;

      <<col2_loop>>
      FOR lr_key IN lc_get_columns(pv_tab_name) LOOP

         IF lb_first THEN
            pl('    ' || lower(lr_key.column_name));
            lb_first := FALSE;
         ELSE
            pl('   ,' || lower(lr_key.column_name));
         END IF;

      END LOOP col2_loop;

      pl(' ) VALUES ( ');

      lb_first := TRUE;

      <<col3_loop>>
      FOR lr_key IN lc_get_columns(pv_tab_name) LOOP

         IF lb_first THEN
            pl('    src.' || lower(lr_key.column_name));
            lb_first := FALSE;
         ELSE
            pl('   ,src.' || lower(lr_key.column_name));
         END IF;

      END LOOP col3_loop;

      pl(')');
      pl('/');

   END sp_gen_merge;

END pkg_gen_merge;
/
