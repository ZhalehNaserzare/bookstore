/************************************************************************/
/**
/** Function: get_popularity_score
/** out: i_i_score wir brechnen von der gesamten Bestellung und gesamtverkauft des Artikels eine Bewertung die als beliebtesten score des Artikels gerechnet wird
/** In: v_article_id  -the id of the article to search for(Artikel_id wird als Parameter gegeben wurden)
/** Returns: popularity score (i_i_score)
/** Developer: Zhaleh Naserzare
/** Description: Diese Prozedur wird ausgeführt, wenn die beliebtesten Artikel oder CDs der Filiale angezeigt werden sollen.
/**
/************************************************************************/

-- Idee: Nur die 200 Bestellungen berücksichtigen. Oder: Nur die Bestellungen des letzten Monats
CREATE OR REPLACE
FUNCTION f_get_popularity_score_i(v_article_id article.article_id%TYPE)
RETURN NUMBER
IS
	i_i_score NUMBER;
BEGIN
	SELECT SUM(quantity) INTO i_i_score
	FROM (
		SELECT quantity
		FROM BILL__ARTICLE
		WHERE article_id = v_article_id
		UNION
		SELECT quantity
		FROM CUSTOMER_ORDER__ARTICLE
		WHERE article_id = v_article_id
	);
	RETURN i_i_score;
END;
/
-- SELECT get_order_count('946-2-476-12345-1') FROM DUAL;

/************************************************************************/
/**
/** Procedure print_popular_articles
/** Developer: Zhaleh Naserzare
/** Description: Diese Prozedur wird ausgeführt, wenn die beliebtesten Artikeln mit deren Rankordnung der Filiale angezeigt werden sollen.
/**
/************************************************************************/
CREATE OR REPLACE PROCEDURE sp_print_popular_articles
AS
	CURSOR GET_POPULAR_ARTICLE IS 
		SELECT article_id, name, f_get_popularity_score_i(article_id) AS popularity
		FROM article 
		ORDER BY get_popularity_score(article_id) DESC;
BEGIN
	FOR v_article IN GET_POPULAR_ARTICLE
    LOOP
        DBMS_OUTPUT.PUT_LINE(GET_POPULAR_ARTICLE%ROWCOUNT || ': ' || v_article.popularity ||' ' || v_article.name || ' (' || v_article.publication_year || ')');
    END LOOP;
END;

set serveroutput on;


BEGIN
	get_popular_articles();
END;
/

/************************************************************************/
/**
/** Function: f_get_bill_price_i
/** In: v_bill_id – the id of the bill to search for
/** Returns: the Social Security Number for the employee
/** Developer: Zhaleh Naserzare
/** Description: Diese Prozedur wird ausgeführt, wenn die beliebtesten Artikel oder CDs der Filiale angezeigt werden sollen.
/**
/************************************************************************/

CREATE OR REPLACE
FUNCTION f_get_bill_price_i(v_bill_id bill.bill_id%TYPE)
RETURN NUMBER
IS
	i_i_sum bill__article.price%TYPE;

BEGIN
	SELECT SUM(quantity * price) INTO i_i_sum
	FROM bill__article
	WHERE bill_id = v_bill_id;

	RETURN i_i_sum;
END;
/

/*********************************************************************/
/**
/** View: bill_view
/** Developer: ZHALEH NASERZARE
/** Description: Die Tabele zeigt,die Anzahl der Artikeln, deren gesamt kosten, die Angestellte welche die Rechnung erstellt haben.
/**
/*********************************************************************/ 

CREATE OR REPLACE VIEW bill_view AS
    SELECT
		b.buy_date,
		b.bill_id,
		(SELECT SUM(quantity) FROM bill__article WHERE bill_id = b.bill_id) AS article_count,
		f_get_bill_price_i(b.bill_id) AS total_price,
		pe.name || ' ' || pe.surname AS employee,
		pc.name || ' ' || pc.surname AS customer
	FROM bill b
	LEFT JOIN customer c USING(customer_id)
	LEFT JOIN person pc ON c.person_id = pc.person_id
	LEFT JOIN employee e USING (employee_id)
	LEFT JOIN person pe ON e.person_id = pe.person_id
	ORDER BY b.buy_date DESC;

	
/*********************************************************************/
/**
/** View: employee_order_view
/** Developer: ZHALEH NASERZARE
/** Description: Die Tabele zeigt,wann der Angestellte wie viele Artikl von welcher Firma bestellt hat.
/**
/*********************************************************************/ 

CREATE OR REPLACE VIEW employee_order_view AS
	SELECT
		eo.order_date,
		eo.employee_order_id,
		eo.company_name,
		(SELECT SUM(quantity) FROM employee_order__article WHERE employee_order_id = eo.employee_order_id) AS article_count,
		pe.name || ' ' || pe.surname AS employee

	FROM employee_order eo
	LEFT JOIN employee e USING (employee_id)
	LEFT JOIN person pe USING(person_id)
	ORDER BY eo.order_date DESC;

/************************************************************************/
/**
/** View: in_stock_view 
/** Developer: Zhaleh Naserzare
/** Description: Die Table zeigt,alles was in der Filiale vorhanden ist.
/**
/************************************************************************/

CREATE OR REPLACE VIEW in_stock_view AS
    SELECT s.article_id, s.quantity, a.name, a.publication_year
		FROM stock s
		INNER JOIN article a ON s.article_id = a.article_id;

/*********************************************************************/
/**
/** Procedure sp_publisher_name
/** Out: 
/** In: v_name_in – article name.
/** Developer: Maria Rostami Gohardani
/** Description: shows the article publisher
/**
/*********************************************************************/
create or replace PROCEDURE sp_publisher_name(v_name_in in article.name%type)
IS
cursor cur_publisher_name is 
select name from publisher 
join article using(publisher_id) 
where article.name=v_name_in;

cv_publisher_name cur_publisher_name%rowtype;
n_publisher number :=1;
n_err_code number;
v_err_msg varchar2(200);
begin

dbms_output.put_line('publisher:');
dbms_output.put_line('----------------------');

   open cur_publisher_name;
    loop
        fetch cur_publisher_name into cv_publisher_name;
        exit when cur_publisher_name%notfound;
        
         dbms_output.put_line(n_publisher || cv_publisher_name);
         n_publisher := n_publisher +1;
        
        
    end loop;
    close cur_publisher_name;

    exception
	  when no_data_found then
        dbms_output.put_line('This book name does not exist ');
        raise;
        
    when others then
     n_err_code := sqlcode;
     v_err_msg := sqlerrm;
     dbms_output.put_line('Errorcode: ' || n_err_code ||' - Errormessage: ' || v_err_msg);

end;
/
/*********************************************************************/
/**
/** Function: f_name_v
/** In: v_name_in – publisher name
/** Returns: article number per publisher
/** Developer: Bahareh Vahidtaleghani
/** Description: shows the number of articles for a particular publisher 
/**
/*********************************************************************/
create or replace function f_name_v (v_name_in in publisher.name%type)
return varchar2
IS
n_article number;
n_err_code number;
v_err_msg varchar2(200);
begin

    select count(*)into n_article from article 
    join publisher using(publisher_id)
    where publisher.name = v_name_in;
    
    return n_article;
    

    exception
        when no_data_found then
        return 'This publisher name does not exist ';
     
     when others then
     n_err_code := sqlcode;
     v_err_msg := sqlerrm;
     dbms_output.put_line('Errorcode: ' || n_err_code ||' - Errormessage: ' || v_err_msg);
  
    
end;
/
/*********************************************************************/
/**
/** Table: year_sales
/** Developer: Maria Rostami Gohardani
/** Description: a view of sale on a particular year 
/**
/*********************************************************************/
create VIEW year_sales AS 
select a.article_id,a.name,a.price,c.quantity,c2.employee_order_date from article a
join customer_order__article c on a.article_id = c.article_id
join customer_order c2 on c.customer_order_id = c2.customer_order_id
where c2.employee_order_date between '01.01.20' and '30.12.20'
order by c2.employee_order_date;


select * from year_sales;

/*********************************************************************/
/**
/** Table: book_author
/** Developer: Bahareh Vahidtaleghani
/** Description: a view of auther of book
/**
/*********************************************************************/
create VIEW book_author AS 
select a.article_id,a.name as book_name,p.name,p.surname,a.publication_year from article a
join author a2 on a.person_id = a2.person_id
join person p on p.person_id = a2.person_id
order by a.name;


select * from book_author;
