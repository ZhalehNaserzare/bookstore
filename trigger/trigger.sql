/*********************************************************************/
/**
/** Trigger: tr_br_tu_ti_stock
/** Type: Before row
/** Type Extension: UPDATE OR INSERT
/** Developer: ZHALEH NASERZARE
/** Description: befor update ckeck if new quntity is not zero and during insert check if article id in this table exists when ja user should use update
/**
/*********************************************************************/

CREATE OR REPLACE TRIGGER tr_br_tu_ti_stock
BEFORE UPDATE OR INSERT ON stock
FOR EACH ROW
DECLARE
    i_count NUMBER;
BEGIN
    IF (:NEW.quantity <= 0) THEN
        raise_application_error(-20020, 'Quantity kann nicht <= 0 sein');
    END IF;

    IF INSERTING THEN
        SELECT COUNT(*) INTO i_count FROM stock WHERE article_id = :NEW.article_id;

        IF (i_count > 0) THEN -- useless, nur für schönene Errors (da unique constraint)
            raise_application_error(-20020, 'Bereits im Stock - bitte Update statt Insert verwenden');
        END IF;
    END IF;

END;
/


-- INSERT INTO STOCK (article_id, quantity) VALUES ('946-2-476-12345-1', 0);
-- INSERT INTO STOCK (article_id, quantity) VALUES ('946-2-476-12345-1', 4);
-- INSERT INTO STOCK (article_id, quantity) VALUES ('946-2-476-12345-1', 4);



/*********************************************************************/
/**
/** Trigger: tr_br_i_CustomerOrderArticle
/** Type: Before row
/** Type Extension: insert or update
/** Developer: Daniel Santa
/** Description: When inserting Data in the Customer_Order_Article table, 
/** makes sure the ID of the Article or the Customer exists, 
/** and that there's enough amount of the Article in the Stock table
/**
/*********************************************************************/

CREATE OR REPLACE TRIGGER tr_br_i_CustomerOrderArticle
before insert or update on CUSTOMER_ORDER__ARTICLE
for each row
declare
  i_help1 number;
  i_help2 number;
  i_help3 number;
  x_not_enough_articles exception;
  x_no_article_found exception;
  x_No_Customer_Order_ID_found exception;
begin 
	select count(*) into i_help3 from customer_order where Customer_Order_ID = :New.Customer_Order_ID;
	if i_help3 = 0 then
 		 raise x_No_Customer_Order_ID_found;
	end if; -- Useless, da constraint foreign key (außer für schönere Fehlermeldungen)
  
	select count(*) into i_help2 from article where Article_ID = :New.Article_Id;
	if i_help2 = 0 then
 		 raise x_no_article_found;
	end if; -- Useless, da constraint foreign key (außer für schönere Fehlermeldungen)
	
	select quantity into i_help1 from stock where Article_ID = :New.Article_Id;
  if i_help1 - :New.Quantity < 0 then
    raise x_not_enough_articles;
  end if; 
	
	exception
	when x_not_enough_articles then
 		raise_application_error(-10000,'not_enough_articles');
 	when x_no_article_found then
 		raise_application_error(-10001,'no_article_found');
 	when x_No_Customer_Order_ID_found then
 		raise_application_error(-10002,'No_Customer_Order_ID_found');
end;
/



/*********************************************************************/
/**
/** Trigger: tr_br_i_EmployeeOrderArticle
/** Type: Before row
/** Type Extension: insert or update
/** Developer: Daniel Santa
/** Description: When inserting data in the Employee_Order_Article table,
/** makes sure the Employee and the Article exist, and if the amount of Article in the Stock table is enough, 
/** uses the sp_UpdateStock to update the Stock of the certain Article,
/**  or gives an error message if the amount is not enough
/**
/*********************************************************************/

CREATE OR REPLACE TRIGGER tr_br_i_EmployeeOrderArticle
before insert or update on EMPLOYEE_ORDER__ARTICLE
for each row
declare
  i_help1 number;
  i_help2 number;
  i_help3 number;
  x_not_enough_articles exception;
  x_no_article_found exception;
  x_No_Customer_Order_ID_found exception;
begin 
	select count(*) into i_help3 from Employee_Order where Employee_Order_ID = :New.Employee_Order_ID;
	if i_help3 = 0 then
 		 raise x_No_Customer_Order_ID_found;
	end if; -- Useless, da constraint foreign key (außer für schönere Fehlermeldungen)
  
	select count(*) into i_help2 from article where Article_ID = :New.Article_Id;
	if i_help2 = 0 then
 		 raise x_no_article_found;
	end if; -- Useless, da constraint foreign key (außer für schönere Fehlermeldungen)
	
	select quantity into i_help1 from stock where Article_ID = :New.Article_Id;
  if i_help1 - :New.Quantity < 0 then
    raise x_not_enough_articles;
  end if; 
	
	sp_UpdateStock(:New.Article_ID, :New.Quantity);

	exception
	when x_not_enough_articles then
 		raise_application_error(-10000,'not_enough_articles');
 	when x_no_article_found then
 		raise_application_error(-10001,'no_article_found');
 	when x_No_Customer_Order_ID_found then
 		raise_application_error(-10002,'No_Customer_Order_ID_found');
end;
/
/*********************************************************************
/**
/** Trigger: tr_br_i_event
/** Type: Before row
/** Type Extension: insert
/** Developer: Maria Rostami Gohardani
/** Description: check before insert if in this date an event exists or not
/**
/*********************************************************************/
create or replace trigger tr_br_i_event
before 
insert on event
for each row
declare
n_event number :=0 ;
n_err_code number;
v_err_msg varchar2(200); 
x_event_exist exception;
    begin
            select count(*)into n_event from event e where e.to_char(START_DATE,'YYYY/MM/DD') = :new.to_char(START_DATE,'YYYY/MM/DD');
            
            if n_event <> 0 then
            raise x_event_exist;
            
            else 
             dbms_output.put_line('Is ok');
            end if;
            
    
    exception
        when x_event_exist then
              dbms_output.put_line('There is already an event in this date');
              
    when others then
        n_err_code := sqlcode;
        v_err_msg := sqlerrm;
        dbms_output.put_line('Errorcode: ' || n_err_code ||' - Errormessage: ' || v_err_msg);
end;
/
/*********************************************************************
/**
/** Trigger: tr_br_d_address
/** Type: Before row
/** Type Extension: delete 
/** Developer: Bahareh Vahidtaleghani
/** Description: checks if there is a publisher with this address id.
/**
/*********************************************************************/
create or replace trigger tr_br_d_address
before 
delete on address
for each row
declare
n_publisher_id number :=0 ;
n_address_id number := 0;
n_err_code number;
v_err_msg varchar2(200);
x_id_not_exist exception;
x_id_exist_publisher exception;
    begin
            select count(*) into n_address_id from address where address_id = :new.address_id;
            
            if n_address_id = 0 then 
                raise x_id_not_exist;
                
            else
             
                 select count(*) into n_publisher_id from Publisher where address_id = :new.address_id;
                        
                      if n_publisher_id = 0 then 
                          dbms_output.put_line('IS OK');
                        
                            else
                                raise x_id_exist_publisher;   

                     end if;
            end if;
                
                
    exception
        when x_id_not_exist then
              dbms_output.put_line('This id does not exist');
            
        when x_id_exist_publisher then 
            dbms_output.put_line('There is a publisher with this address id');
              
    when others then
        n_err_code := sqlcode;
        v_err_msg := sqlerrm;
        dbms_output.put_line('Errorcode: ' || n_err_code ||' - Errormessage: ' || v_err_msg);
end;
/