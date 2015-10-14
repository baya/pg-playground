CREATE TABLE salaries (
  emp_name text PRIMARY KEY,
  salary integer NOT NULL
);

CREATE TABLE salary_change_log (
  changed_by text DEFAULT CURRENT_USER,
  changed_at timestamp DEFAULT CURRENT_TIMESTAMP,
  salary_op text,
  emp_name text,
  old_salary integer,
  new_salary integer
);

REVOKE ALL ON salary_change_log FROM PUBLIC;
-- GRANT ALL ON salary_change_log TO managers;


CREATE OR REPLACE FUNCTION log_salary_change () RETURNS trigger AS $$
  BEGIN
    IF TG_OP = 'INSERT' THEN
      INSERT INTO salary_change_log(salary_op, emp_name, new_salary)
      VALUES (TG_OP, NEW.emp_name, NEW.salary);
    ELSIF TG_OP = 'UPDATE' THEN INSERT INTO salary_change_log(salary_op, emp_name, old_salary, new_salary)
      VALUES (TG_OP, NEW.emp_name, OLD.salary, NEW.salary);
    ELSIF TG_OP = 'DELETE'   THEN
      INSERT INTO salary_change_log(salary_op, emp_name, old_salary)
      VALUES (TG_OP, NEW.emp_name, OLD.salary);
        END IF;
	RETURN NEW;
   END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_salary_change
AFTER INSERT OR UPDATE OR DELETE ON salaries
  FOR EACH ROW EXECUTE PROCEDURE log_salary_change ();


INSERT INTO salaries values('Bob', 1000);

UPDATE salaries set salary = 1100 where emp_name = 'Bob';

INSERT INTO salaries values('Mary', 1000);

UPDATE salaries set salary = salary * 200;

CREATE OR REPLACE FUNCTION get_salary(text)
RETURNS integer
AS $$
  INSERT INTO salary_change_log(salary_op, emp_name, new_salary)
  SELECT 'SELECT', emp_name, salary
    FROM salaries
    WHERE upper(emp_name) = upper($1)
      AND upper(emp_name) != upper(CURRENT_USER);
  SELECT salary FROM salaries WHERE upper(emp_name) = upper($1);
$$ LANGUAGE SQL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION set_salary(i_emp_name text, i_salary int)
RETURNS TEXT AS $$
DECLARE
  old_salary integer;
BEGIN
  SELECT salary INTO old_salary FROM salaries WHERE upper(emp_name) = upper(i_emp_name);
  IF NOT FOUND THEN
    INSERT INTO salaries VALUES(i_emp_name, i_salary);
    INSERT INTO salary_change_log(salary_op, emp_name, new_salary)
      VALUES ('INSERT', i_emp_name, i_salary);
      RETURN 'INSERTED USER ' || i_emp_name;
  ELSIF i_salary > 0 THEN
    UPDATE salaries SET salary = i_salary WHERE upper(emp_name) = upper(i_emp_name);
    INSERT INTO salary_change_log(salary_op, emp_name, old_salary, new_salary) VALUES('UPDATE', i_emp_name, old_salary, i_salary);
    RETURN 'UPDATED USER ' || i_emp_name;
  ELSE -- salary set to 0
    DELETE FROM salaries WHERE upper(emp_name) = upper(i_emp_name);
    INSERT INTO salary_change_log(salary_op, emp_name, old_salary) VALUES ('DELETE', i_emp_name, old_salary);
    RETURN 'DELETED USER ' || i_emp_name;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


DROP TRIGGER audit_salary_change ON salaries;

select set_salary('Fred', 750);

select set_salary('frank', 100);

select set_salary('marry', 0);

CREATE OR REPLACE FUNCTION uppercase_name ()
RETURNS trigger AS $$
  BEGIN
    NEW.emp_name = upper(NEW.emp_name);
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER uppercase_emp_name
BEFORE INSERT OR UPDATE OR DELETE ON salaries
  FOR EACH ROW EXECUTE PROCEDURE uppercase_name();


select set_salary('arnold', 80);

update salaries set emp_name = upper(emp_name) where not emp_name = upper(emp_name);

alter table salaries add constraint emp_name_must_be_uppercase CHECK (emp_name = upper(emp_name));
    