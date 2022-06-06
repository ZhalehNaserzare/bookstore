
/*********************************************************************/
/*
/* Filename: pk_print_bestellung
/* Package: Unit_Test_Frmwrk
/* Developer: ZHALEH NASERZARE
/* Description: Dies Package zeigt die Bstellungen von Kunde, als auch welches der Angestellter erstellt haben
/*
/*********************************************************************/

CREATE OR REPLACE PACKAGE print_bestellung AS

    PROCEDURE customer_order_all;
    PROCEDURE customer_order_by_id(
        v_order_id customer_order.customer_order_id%TYPE
    );
    PROCEDURE customer_order_by_person(
        v_customer_id customer_order.customer_id%TYPE
    );
    PROCEDURE customer_order_by_employee(
        v_employee customer_order.employee_id%TYPE
    );
END print_bestellung;
/

CREATE OR REPLACE PACKAGE BODY print_bestellung AS

    
    v_ErrorCode NUMBER;
    v_ErrorMsg VARCHAR2(200);

    PROCEDURE customer_order_by_id(
        v_order_id customer_order.customer_order_id%TYPE
    ) IS
        v_order customer_order%ROWTYPE;

        CURSOR GET_ITEMS IS
            SELECT c.quantity, a.article_id, a.name
            FROM CUSTOMER_ORDER__ARTICLE c
                INNER JOIN article a ON a.article_id = c.article_id
            WHERE customer_order_id = v_order_id;

    BEGIN
        SELECT * INTO v_order
        FROM customer_order
        WHERE customer_order_id = v_order_id;

        
        DBMS_OUTPUT.PUT_LINE('Bestellung #' || v_order.customer_order_id || ' vom ' || v_order.employee_order_date || ':');

        FOR v_oder_item IN GET_ITEMS
        LOOP
            DBMS_OUTPUT.PUT_LINE('.    ' || v_oder_item.quantity || ' mal <' || v_oder_item.article_id || '>  ' || v_oder_item.name);
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE;
    END;
    

    PROCEDURE customer_order_all
    IS
        CURSOR GET_ORDER_LIST IS
            SELECT * FROM customer_order;
    BEGIN

        FOR v_order IN GET_ORDER_LIST
        LOOP
            customer_order_by_id(v_order.customer_order_id);
            DBMS_OUTPUT.PUT_LINE(' ');
        END LOOP;
    END;

    
    PROCEDURE customer_order_by_person(
        v_customer_id customer_order.customer_id%TYPE
    ) IS
        CURSOR GET_ORDER_LIST IS
            SELECT * FROM customer_order
            WHERE customer_id = v_customer_id;
        
        v_person_name VARCHAR2(256);
    BEGIN

        SELECT name || ' ' || surname INTO v_person_name
        FROM person p
        INNER JOIN customer c USING (person_id)
        WHERE c.customer_id = v_customer_id;

        DBMS_OUTPUT.PUT_LINE('Bestellungen von ' || v_person_name);
        FOR v_order IN GET_ORDER_LIST
        LOOP
            customer_order_by_id(v_order.customer_order_id);
            DBMS_OUTPUT.PUT_LINE(' ');
        END LOOP;
    END;

    
    PROCEDURE customer_order_by_employee(
        v_employee customer_order.employee_id%TYPE
    ) IS
        CURSOR GET_ORDER_LIST IS
            SELECT * FROM customer_order
            WHERE employee_id = v_employee;
        
        v_person_name VARCHAR2(256);
    BEGIN

        SELECT name || ' ' || surname INTO v_person_name
        FROM person p
        INNER JOIN employee e USING (person_id)
        WHERE e.employee_id = v_employee;

        DBMS_OUTPUT.PUT_LINE('Bestellungen bearbeitet von ' || v_person_name);
        FOR v_order IN GET_ORDER_LIST
        LOOP
            customer_order_by_id(v_order.customer_order_id);
            DBMS_OUTPUT.PUT_LINE(' ');
        END LOOP;
    END;

       

-- EXCEPTION
--     WHEN OTHERS THEN
--         v_ErrorCode := SQLCODE;
--         v_ErrorMsg := substr(SQLERRM,1,200);
--         DBMS_OUTPUT.PUT_LINE('Es ist ein Fehler aufgetreten mit dem Code ' || v_ErrorCode || ' ! Der Fehler ist: ' || v_ErrorMsg);
--         RAISE;
END;
/ 

COMMIT; 
