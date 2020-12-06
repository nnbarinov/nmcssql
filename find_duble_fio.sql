SELECT * FROM (
SELECT  MAX (UPPER(r.lastname)) fam1
      , MIN (UPPER(p.lastname)) fam2
      , UPPER (r.firstname) name1
      , UPPER (p.firstname) name2
      , UPPER (r.secondname) sname1
      , UPPER (p.secondname) sname2
      , utl_match.edit_distance(UPPER(p.lastname),UPPER(r.lastname)) dif 
      , utl_match.jaro_winkler_similarity(UPPER(p.lastname),UPPER(r.lastname)) pct
      , TRUNC(p.birthdate) bdate
      , 'Фамилия' errorplace
FROM patient r, patient p
WHERE UPPER(r.firstname) = UPPER(p.firstname)
      AND UPPER(r.secondname) = UPPER(p.secondname)
      AND TRUNC(r.birthdate) = TRUNC(p.birthdate)
      GROUP BY UPPER (r.firstname), UPPER (p.firstname), UPPER (r.secondname), UPPER (p.secondname), 
       utl_match.edit_distance(UPPER(p.lastname),UPPER(r.lastname)), 
       utl_match.jaro_winkler_similarity(UPPER(p.lastname),UPPER(r.lastname)),
       TRUNC(p.birthdate) , 'Фамилия' 
UNION 
SELECT  (UPPER(r.lastname)) fam1
      , (UPPER(p.lastname)) fam2
      , MAX (UPPER(r.firstname)) name1
      , MIN (UPPER(p.firstname)) name2
      , UPPER (r.secondname) sname1
      , UPPER (p.secondname) sname2
      , utl_match.edit_distance(UPPER(p.firstname),UPPER(r.firstname)) dif 
      , utl_match.jaro_winkler_similarity(UPPER(p.firstname),UPPER(r.firstname)) pct
      , TRUNC(p.birthdate) bdate
      , 'имя' errorplace
FROM patient r, patient p
WHERE UPPER(r.lastname) = UPPER(p.lastname)
      AND UPPER(r.secondname) = UPPER(p.secondname)
      AND TRUNC(r.birthdate) = TRUNC(p.birthdate)
GROUP BY UPPER(r.lastname)
      , UPPER(p.lastname)
      , UPPER (r.secondname)
      , UPPER (p.secondname)
      , utl_match.edit_distance(UPPER(p.firstname),UPPER(r.firstname)) 
      , utl_match.jaro_winkler_similarity(UPPER(p.firstname),UPPER(r.firstname))
     , TRUNC(p.birthdate) 
      , 'имя'
UNION 
SELECT  (UPPER(r.lastname)) fam1
      , (UPPER(p.lastname)) fam2
      , (UPPER(r.firstname)) name1
      , UPPER(p.firstname) name2
      , MAX (UPPER (r.secondname)) sname1
      , MIN (UPPER (p.secondname)) sname2
      , utl_match.edit_distance(UPPER(p.secondname),UPPER(r.secondname)) dif 
      , utl_match.jaro_winkler_similarity(UPPER(p.secondname),UPPER(r.secondname)) pct
      , TRUNC(p.birthdate) bdate
      , 'отчество' errorplace
FROM patient r, patient p
WHERE UPPER(r.lastname) = UPPER(p.lastname)
      AND UPPER(r.firstname) = UPPER(p.firstname)
      AND TRUNC(r.birthdate) = TRUNC(p.birthdate)
GROUP BY UPPER(r.lastname)
      , UPPER (p.lastname)
      , UPPER (r.firstname)
      , UPPER (p.firstname)
      , utl_match.edit_distance(UPPER(p.secondname),UPPER(r.secondname)) 
      , utl_match.jaro_winkler_similarity(UPPER(p.secondname),UPPER(r.secondname))
      , TRUNC(p.birthdate)
      , 'отчество'     
      )
      WHERE (dif =1 OR (dif IN (2) AND  pct > 85))