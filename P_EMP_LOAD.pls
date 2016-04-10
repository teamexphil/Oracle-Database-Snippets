CREATE OR REPLACE PACKAGE P_EMP_LOAD AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
  PROCEDURE load_emps;
END P_EMP_LOAD;
/


CREATE OR REPLACE PACKAGE BODY P_EMP_LOAD AS

  /* External table and directory
  CREATE DIRECTORY LOAD_DIR AS 'C:\temp\oracle_dir';
  
  CREATE TABLE "HR"."EMP_TEMP" 
   (	"FIRST_NAME" VARCHAR(15 BYTE), 
	"LAST_NAME" VARCHAR(20 BYTE), 
	"SALARY" VARCHAR(15 BYTE), 
	"DEPARTMENT_ID" VARCHAR(6 BYTE)
   ) 
   ORGANIZATION EXTERNAL 
    ( TYPE ORACLE_LOADER
      DEFAULT DIRECTORY "LOAD_DIR"
      ACCESS PARAMETERS
      ( FIELDS TERMINATED BY ';'    )
      LOCATION
       ( 'employees.txt'
       )
    );
    */
  PROCEDURE out (p_txt varchar2) IS
  BEGIN
    dbms_output.put_line(p_txt);
  END out;
  
  FUNCTION emp_exists(p_first_name varchar2,
                      p_last_name varchar2) RETURN BOOLEAN IS
  BEGIN
  
    out('Checking if emp already loaded');
    FOR i IN (SELECT 'x'
              FROM employees
              WHERE first_name = p_first_name
              AND last_name = p_last_name) LOOP
      out('Exists, ignore record');        
      RETURN TRUE;          
    END LOOP;     
    out('New Emp, loading...');
    RETURN FALSE;
  END emp_exists;                    
      
  FUNCTION salary_valid(p_salary varchar2) RETURN BOOLEAN IS
    l_number NUMBER;
  BEGIN
    out('Validating salary');
    l_number := to_char(p_salary);
    IF l_number >0 THEN
      out('Salary valid');
      RETURN TRUE;
    ELSE
      out('salary numeric, but invalid: '||p_salary);
      RETURN FALSE;
    END IF;  
  EXCEPTION
    WHEN VALUE_ERROR THEN
      out('Salary not numeric: '||p_salary);
      RETURN FALSE;
  END;
  
  FUNCTION department_exists(p_department_id varchar2, p_name out varchar2) RETURN BOOLEAN IS
  BEGIN
    out('Checking department');
    FOR i IN (SELECT department_name name
              FROM departments
              WHERE department_id = p_department_id) LOOP
      out('Fetching department: '||i.name);        
      p_name := i.name;
      RETURN TRUE;
    END LOOP;
    RETURN FALSE;
  END department_exists;
  
  PROCEDURE load_record(p_emp employees%ROWTYPE) IS
  BEGIN
    out('saving emp');
    
    INSERT INTO employees (employee_id,
                           first_name,
                           last_name,
                           email,
                           phone_number,
                           hire_date,
                           job_id,
                           salary,
                           commission_pct,
                           manager_id,
                           department_id) 
    VALUES                (emp_seq.nextval, -- employee_id,
                           p_emp.first_name,
                           p_emp.last_name,
                           p_emp.first_name||'.'||p_emp.last_name||'@company.com', --email,
                           null, --phone_number,
                           sysdate, --hire_date,
                           'IT_PROG', --job_id,
                           p_emp.salary, --salary,
                           null, --commision_pct,
                           null, --manager_id,
                           p_emp.department_id); --department_id);        
  EXCEPTION
    WHEN OTHERS THEN
      out(dbms_utility.format_error_backtrace);
      out('Failed to load employee');
      raise;
  END load_record;
  
  PROCEDURE load_emps AS
    l_dept_name departments.department_name%TYPE;
    l_emp_rec employees%ROWTYPE;
    l_rec_count NUMBER :=0;
  BEGIN
    out('Starting emp load...');
    
    FOR r_emp IN (SELECT first_name,
                         last_name,
                         salary,
                         department_id
                  FROM   emp_temp) LOOP
                  
      out('Got emp '||r_emp.first_name||' '||r_emp.last_name||' '||r_emp.salary||' '||r_emp.department_id);              
      
      l_rec_count:=l_rec_count+1;
      
      IF emp_exists(r_emp.first_name, r_emp.last_name) THEN
        out('Emp exists, skip');
        CONTINUE;
      END IF;
      
      IF NOT salary_valid(r_emp.salary) THEN
        out('Salary not valid, skip');
        CONTINUE;
      END IF;
      
      IF NOT department_exists(r_emp.department_id, l_dept_name) THEN
        out('Department doesnt exist, skip');
        CONTINUE;
      END IF;
      
      l_emp_rec.first_name := r_emp.first_name;
      l_emp_rec.last_name := r_emp.last_name;
      l_emp_rec.salary := r_emp.salary;
      l_emp_rec.department_id := r_emp.department_id;
      
      load_record(l_emp_rec);
      
      COMMIT;
    END LOOP;
    
    out('Completed file load');
  END load_emps;

END P_EMP_LOAD;
/
