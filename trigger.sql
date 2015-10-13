CREATE TABLE fruits_in_stock (
  name text PRIMARY KEY,
  in_stock integer NOT NULL,
  reserved integer NOT NULL DEFAULT 0,
  CHECK (in_stock between 0 and 1000),
  CHECK (reserved <= in_stock)
)

CREATE TABLE fruit_offer (
  offer_id serial PRIMARY KEY,
  recipient_name text,
  offer_date timestamp default current_timestamp,
  fruit_name text REFERENCES fruits_in_stock,
  offered_amount integer
);

CREATE OR REPLACE FUNCTION reserve_stock_on_offer () RETURNS trigger
AS $$
  BEGIN
    IF TG_OP = 'INSERT' THEN
       UPDATE fruits_in_stock
       SET reserved = reserved + NEW.offered_amount
       WHERE name = NEW.fruit_name;
    ELSIF TG_OP = 'UPDATE' THEN
       UPDATE fruits_in_stock
         SET reserved = reserved - OLD.offered_amount + NEW.offered_amount
       WHERE name = NEW.fruit_name;
    ELSIF TG_OP = 'DELETE' THEN
       UPDATE fruits_in_stock
         SET reserved = reserved - OLD.offered_amount
         WHERE name = OLD.fruit_name;
	 END IF;
	 RETURN NEW;
   END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER manage_reserve_on_offer_change
AFTER INSERT OR UPDATE OR DELETE ON fruit_offer
  FOR EACH ROW EXECUTE PROCEDURE reserve_stock_on_offer();

INSERT INTO fruits_in_stock(name, in_stock) values ('APPLE', 500);
INSERT INTO fruits_in_stock(name, in_stock) values ('ORANGE', 500);

INSERT INTO fruit_offer(recipient_name, fruit_name, offered_amount) VALUES ('Bob', 'APPLE', 100);

UPDATE fruit_offer SET offered_amount = 115 WHERE offer_id = 3;

SELECT * FROM fruits_in_stock;


UPDATE fruits_in_stock SET in_stock = 200 WHERE name = 'APPLE';


DELETE FROM fruit_offer WHERE offer_id = 3;