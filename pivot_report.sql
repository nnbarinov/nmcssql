SELECT * FROM 
(
SELECT DISTINCT
substr(sd.code,6)  AS code_usl
,sd.text AS code_text
,decode(v.prof_short, 'Орто', 'Травм-орт', 'Травма', 'Травм-орт', v.prof_short) AS prof
,v.rootid AS PAT_ALL
FROM srvdep sd, patserv ps, V_VISIT_COME_OUT_SMKC V
     WHERE  TRUNC (v.dat1) BETWEEN :DATE1 AND :DATE2
     AND ps.AGRID IN (689,696,730,714,2815000)
     AND sd.keyid = ps.srvdepid
     AND v.keyid = ps.visitid
     AND sd.code NOT LIKE '1.13.%'
     AND (REPLACE(:DEP, '''') IS NULL OR v.depprofid IN (:DEP))
     AND (REPLACE(':PROF', '''') IS NULL OR v.profid IN (:PROF))
     AND (REPLACE(:BILL, '''') IS NULL OR (SELECT 1 FROM invoice i WHERE i.patservid=ps.keyid AND NVL(I.BILLID,0)<>0
     AND NVL(I.REFUSE_STATUS,0)=0) IN (:BILL))
) 
pivot
(
COUNT(pat_all)
FOR prof IN (
'Гинек'  gyn,
'Кар'    kard,
'ЛОР'    lor,
'Нев'    nev,
'Онко'   onk,
'Травм-орт' tor,
'Пед' ped,
'Рад' rad,
'Реаб' rea,
'СтЧЛХ' clx,
'Тер' ter,
'Уролог' uro,
'Хир' surg,
'ХирСос' ksurg,
'Эндокр' endo,
'ДКар' dkar,
'Пульм' pulm )
) 
ORDER BY code_text