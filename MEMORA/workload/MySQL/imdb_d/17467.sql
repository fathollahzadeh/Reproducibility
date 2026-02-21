select min(n.name) as of_person,
       min(t.title) as biography_movie
from aka_name as an,
     cast_info as ci,
     info_type as it,
     link_type as lt,
     movie_link as ml,
     name as n,
     person_info as pi,
     title as t
where it.info ='mini biography'
  and lt.link ='features'
  and (n.gender='m'
       or (n.gender = 'f'
           and n.name like 'b%'))
  and pi.note ='volker boehm'
  and n.id = an.person_id
  and n.id = pi.person_id
  and ci.person_id = n.id
  and t.id = ci.movie_id
  and ml.linked_movie_id = t.id
  and lt.id = ml.link_type_id
  and it.id = pi.info_type_id
  and pi.person_id = an.person_id
  and pi.person_id = ci.person_id
  and an.person_id = ci.person_id
  and ci.movie_id = ml.linked_movie_id
  and t.production_year between 1953  and 2006
and an.name like '%y%'
and n.name_pcode_cf between 'f'  and 'x';