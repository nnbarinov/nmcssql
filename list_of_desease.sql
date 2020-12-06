SELECT ROWNUM || ' из ' || a.qty, a.datds, a.code, a.text, a.dok
  FROM (SELECT b.qty, TRUNC(b.datds) AS datds, b.code, b.text, b.dok
          FROM (SELECT MIN(s.datds) AS datds, s.code, s.text, s.dok, s.qty
                  FROM (SELECT pd.dat AS datds,
                               ds.code AS code,
                               ds.text AS text,
                               COUNT(DISTINCT(ds.code)) over(PARTITION BY pd.patientid) AS qty,
                               FIRST_VALUE(fn_get_doc_sname_by_vis_id(pd.visitid)) over(PARTITION BY ds.code ORDER BY pd.dat) AS dok
                          FROM patdiag pd, diagnos ds
                         WHERE pd.diagid = ds.keyid
                           AND TRUNC(pd.dat) BETWEEN (SYSDATE - 1827) AND SYSDATE
                           AND fn_get_doc_sname_by_vis_id(pd.visitid) IS NOT NULL
   			AND ds.code NOT LIKE 'Z%'
 			AND pd.patientid = :PATIENT_ID) s 
	GROUP BY s.code, s.text, s.dok, s.qty) b
         ORDER BY (b.datds) DESC) a