merge into patient p
using (select distinct d.dated, p.keyid
from patient p, solution_dbf.deadppl d
where
 LOWER (d.fam) = LOWER(p.lastname) AND LOWER (d.im) = LOWER(p.firstname) AND LOWER(d.ot)= LOWER(p.secondname)
 AND TRUNC (d.dateb) = TRUNC (p.birthdate)) s
on (p.keyid = s.keyid)
when matched then update set p.death_dat = s.dated, p.areanum_lu_id = ''
