with r AS  (
SELECT 
v.dep_id AS dep_id
,SUM(v.qty * v.organ_qty) AS qty_all
,SUM(decode(v.finance, '1', 0, '2', 0, '3', 0, v.qty * v.organ_qty)) AS qty_fboms
,SUM(decode(v.finance, '1',v.qty * v.organ_qty, '2', v.qty * v.organ_qty, '3', v.qty * v.organ_qty, 0)) AS qty_no_fboms
 FROM V_RESEARCH_UNIQ_ALL V
	WHERE TRUNC(v.dat) BETWEEN TO_DATE('2020-07-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE('2020-07-26 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
          AND (REPLACE('''', '''') IS NULL OR v.research_typ_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.dep_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.typ_id1 IN (''))
          AND (REPLACE('', '''') IS NULL OR v.typ_id2 IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.done_doc_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.done_doc_id NOT IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.nurse_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.doc_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.agr_id IN (''))
          AND (REPLACE('''', '''') IS NULL OR v.finance IN (''))
   	 AND v.research_area_code = 1
   	 AND v.refusestatus = 0
GROUP BY v.dep_id),

d AS (SELECT d.rootid, d.keyid, d.text AS dtext FROM dep d WHERE d.status = 1)

SELECT t.deptext, SUM(t.qty_all) AS qty_all, SUM(t.qty_fboms) AS qty_fboms, SUM(t.qty_no_fboms) AS qty_no_fboms  FROM (
SELECT decode(level, 1, s.dtext , 2, s.dtext, 3, PRIOR s.dtext, prior s.dtext) AS deptext , s.qty_all, s.qty_fboms, s.qty_no_fboms FROM (
SELECT d.*, r.* FROM d LEFT OUTER JOIN r
ON d.keyid = r.dep_id
 ) s
start with s.rootid = 1
connect BY prior s.keyid = s.rootid
UNION 
SELECT 'Не указано' AS deptext,
r.qty_all, r.qty_fboms, r.qty_no_fboms 
 FROM r
WHERE r.dep_id IS NULL) t
WHERE t.qty_all IS NOT NULL
GROUP BY rollup(t.deptext) 
