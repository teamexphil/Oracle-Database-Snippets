CREATE OR REPLACE PACKAGE P_BATCH_PROCESS AS 

  G_SHOW_DEBUG BOOLEAN := TRUE;
  PROCEDURE p_run_process(p_process_id number);
  
  PROCEDURE process1;
  PROCEDURE process2;
  PROCEDURE process3;

END P_BATCH_PROCESS;
/


CREATE OR REPLACE PACKAGE BODY P_BATCH_PROCESS AS

  PROCEDURE out(p_text varchar2) IS
  BEGIN
    IF G_SHOW_DEBUG THEN
      dbms_output.put_line(p_text);
    END IF;  
  END;
  
  PROCEDURE process1 IS
  BEGIN
    out('Running Process 1');
  END;  
  
  PROCEDURE process2 IS
    l_num number;
  BEGIN
    out('Running Process 2');
    l_num := 1/0;    
  END;
  
  PROCEDURE process3 IS
  BEGIN
    out('Running Process 3');
  END;
  
  PROCEDURE p_log_process(p_run_id number,
                          p_process_id number,
                          p_msg varchar2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;                        
  BEGIN
    INSERT INTO batch_process_log(run_id,process_id,what_happened)
    VALUES (p_run_id,p_process_id,p_msg);
    COMMIT;
  END;
  
  PROCEDURE p_run_process(p_process_id number) AS
    l_error varchar2(255);
    l_run_id number;
  BEGIN
    SELECT run_seq.nextval INTO l_run_id
    FROM DUAL;
    
    FOR process IN (select process_id,
                           process_name,
                           process_target
                    from batch_process 
                    where process_parent = (select process_id from batch_process where process_id = p_process_id)
                    order by process_order) LOOP
                    
      BEGIN              
        execute immediate ('BEGIN ' || process.process_target || '; END; ');
        p_log_process(l_run_id,process.process_id,'Success');
      EXCEPTION
        WHEN OTHERS THEN
          l_error := sqlerrm;
          p_log_process(l_run_id,process.process_id,l_error);
      END;   
      
    END LOOP;                
  END p_run_process;
  
END P_BATCH_PROCESS;
/
