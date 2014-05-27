# Surveyor Warehouse

Surveyor Warehouse allows you to extract and transform the responses from 
surveyor response sets into an alternate database table structure. This 
can be generally helpful for querying surveyor responses within a table
structure of one's choice.

The alternate database table structure is defined by adding a
`:data_export_identifier` attribute to each question with the 
format "table.column" (e.g. 'subjects.name').

## Example

Given the survey:
```
  q 'What is your name?', :data_export_identifier => 'subjects.name'
  a :string

  q 'What is your age?', :data_export_identifier => 'subjects.age'
  a :integer

  q 'What is your gender?', :pick => :one, :data_export_identifier => 'subjects.gender'
  a 'Male', :reference_identifier => "male"
  a 'Female', :reference_identifier => "female"

  q 'Which brand of shoes do you wear?', :pick => :any, :data_export_identifier => 'subjects.shoes'
  a 'Nike', :reference_identifier => 'nike'
  a 'Adidas', :reference_identifier => 'adidas'
  a 'None', :omit, :reference_identifier => 'none'

  repeater 'List all your siblings' do
    q 'Name', :data_export_identifier => 'siblings.name' 
    a :string
  end
```

Responses would be transformed into:

```
  db=# select * from subjects;
    name   | age | gender |     shoes     | access_code |      id
  ---------+-----+--------+---------------+-------------+--------------
   raphael |  18 | male   | {nike,adidas} | QUhwHtMPyQ  | QUhwHtMPyQ.0
   Stephen |  50 | male   | {none}        | zZu1OV1hmw  | zZu1OV1hmw.0
  (2 rows)

  db=# select * from siblings;
       name     | access_code |      id
  --------------+-------------+--------------
   leonardo     | QUhwHtMPyQ  | QUhwHtMPyQ.0
   michelangelo | QUhwHtMPyQ  | QUhwHtMPyQ.1
   elizabeth    | zZu1OV1hmw  | zZu1OV1hmw.0
   james        | zZu1OV1hmw  | zZu1OV1hmw.1
  (4 rows)
```


## Getting Started

1. Survey questions must have data_export_identifiers with the 
   format "table.column" (e.g. 'subjects.name')
2. Take the survey
3. `bundle exec rake surveyor:warehouse`
4. Query the results



## Limitations

* Currently only works with PostgresSQL