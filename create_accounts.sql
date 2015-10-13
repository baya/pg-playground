create table accounts
(
  id serial primary key,
  owner character(255) NOT NULL,
  balance numeric(9, 2)
)
