CREATE TABLE words
(
  word character varying(10) NOT NULL
);


INSERT INTO words(word) VALUES ('Abracadabr');
INSERT INTO words(word) VALUES ('Great');
INSERT INTO words(word) VALUES ('Barter');
INSERT INTO words(word) VALUES ('Revolver');

CREATE OR REPLACE FUNCTION reversed_vowels(word text)
RETURNS text AS $$
vowels = [c for c in word.lower() if c in 'aeiou']
vowels.reverse()
return ''.join(vowels)
$$ LANGUAGE plpythonu IMMUTABLE;  