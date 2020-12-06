SELECT v.mkb_group_code1
,v.mkb_group_name,v.mkb_group_code
,v.mkb_text1,v.mkb_code1
       ,COUNT (DISTINCT v.rootid) AS out_qty 
       ,SUM (v.days) AS days_qty 
       ,round (STDDEV_POP(v.days),1) AS std_qty 
       ,round (SUM(v.days)/COUNT(DISTINCT v.rootid),1) AS average_qty
FROM V_VISIT_COME_OUT_DIAG_sem v
WHERE TRUNC( v.dat1 ) BETWEEN :DAT1 AND :DAT2
          AND (REPLACE(':DEP', '''') IS NULL OR v.depid IN (:DEP))
          AND (REPLACE(':DPROF', '''') IS NULL OR v.depprofid IN (:DPROF))
          AND (REPLACE(':FINANCE', '''') IS NULL OR v.finance IN (:FINANCE))
          AND (REPLACE(':PROF', '''') IS NULL OR v.profid IN (:PROF))
          AND (REPLACE(':DOC', '''') IS NULL OR v.doctorid IN (:DOC))
          AND (REPLACE(:SEAMAN, '''') IS NULL OR v.seaman_code IN (:SEAMAN))
          AND (REPLACE(':LPU', '''') IS NULL OR v.lpu IN (:LPU))
          AND (REPLACE(':PART', '''') IS NULL OR v.part IN (:PART))
          AND (REPLACE(:PENS, '''') IS NULL OR v.pens_status IN (:PENS))
AND (REPLACE(:SEX, '''') IS NULL OR v.sex_num IN (:SEX))
AND (REPLACE(:AGE1, '''') IS NULL OR v.ageout >= (:AGE1))
AND (REPLACE(:AGE2, '''') IS NULL OR v.ageout < (:AGE2))
 AND (REPLACE(:PLAN_TYPE, '''') IS NULL OR v.typ IN (:PLAN_TYPE))
AND v.status_dep_from NOT IN (301, 302, 303)	--без дневного стационара
AND v.status_dep_out <> 203
AND v.diagtype = 1
GROUP BY rollup((v.mkb_group_code1,V.mkb_group_code1_sort), (v.mkb_group_code,v.mkb_group_name),(v.mkb_text1,v.mkb_code1))
ORDER BY V.mkb_group_code1_sort,v.mkb_group_code,v.mkb_code1