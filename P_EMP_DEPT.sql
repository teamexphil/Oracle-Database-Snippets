CREATE OR REPLACE PACKAGE P_EMP_DEPT AS 

  PROCEDURE p_ins_emp(p_EMPLOYEE_ID number,
                      p_FIRST_NAME varchar2,
                      p_LAST_NAME varchar2,
                      p_EMAIL varchar2,
                      p_PHONE_NUMBER varchar2,
                      p_HIRE_DATE date,
                      p_JOB_ID varchar2,
                      p_SALARY number,
                      p_DEPARTMENT_NAME varchar2);
  
  PROCEDURE p_get_emps;
  
  G_SHOW_DEBUG BOOLEAN := TRUE;                    

END P_EMP_DEPT;
/


CREATE OR REPLACE PACKAGE BODY P_EMP_DEPT AS

  PROCEDURE out(p_text varchar2) IS
  BEGIN
    IF G_SHOW_DEBUG THEN
      dbms_output.put_line(p_text);
    END IF;  
  END;
  
  FUNCTION get_department_id(p_dept departments.department_name%TYPE) RETURN departments.department_id%TYPE IS
    CURSOR c_dept_id IS
    SELECT department_id
    FROM departments
    WHERE department_name = p_dept;
    
    l_dept_id departments.department_id%TYPE;
  BEGIN
    OPEN c_dept_id;
    FETCH c_dept_id INTO l_dept_id;
    IF c_dept_id%NOTFOUND THEN
      out('Dept id not found for '||p_dept);
    ELSE  
      out('Dept id '||l_dept_id||' for '||p_dept);
    END IF;
    CLOSE c_dept_id;
    RETURN l_dept_id;
  END;
  
  PROCEDURE p_get_emps IS
    TYPE employee_tab IS TABLE OF employees%rowtype
    INDEX BY PLS_INTEGER;
    l_emp_tab employee_tab;
  BEGIN
    SELECT *
    BULK COLLECT INTO l_emp_tab
    FROM employees;
    
    FOR idx IN 1..l_emp_tab.count LOOP
      out('Employee: ' ||l_emp_tab(idx).first_name||':'||l_emp_tab(idx).last_name);
    END LOOP;
  END p_get_emps;
  
  PROCEDURE p_ins_emp(p_EMPLOYEE_ID number,
                      p_FIRST_NAME varchar2,
                      p_LAST_NAME varchar2,
                      p_EMAIL varchar2,
                      p_PHONE_NUMBER varchar2,
                      p_HIRE_DATE date,
                      p_JOB_ID varchar2,
                      p_SALARY number,
                      p_DEPARTMENT_NAME varchar2) IS
                      
    l_department_id employees.department_id%TYPE;                    
  BEGIN
    out('Creating employee...');
    
    out('Fetching Department');
    l_department_id := get_department_id(p_department_name);
    
    INSERT INTO employees (EMPLOYEE_ID
                          ,FIRST_NAME
                          ,LAST_NAME
                          ,EMAIL
                          ,PHONE_NUMBER
                          ,HIRE_DATE
                          ,JOB_ID
                          ,SALARY
                          ,COMMISSION_PCT
                          ,MANAGER_ID
                          ,DEPARTMENT_ID)
    VALUES (p_employee_id,
            p_first_name,
            p_last_name,
            p_email,
            p_phone_number,
            p_hire_date,
            p_job_id,
            p_salary,
            null, -- commision
            null, -- manager_id
            l_department_id);
    out('created employee ok');        
  EXCEPTION
    WHEN dup_val_on_index THEN
      out('Cannot insert employee with duplicate id: '||p_employee_id);
  END p_ins_emp;

END P_EMP_DEPT;
/
