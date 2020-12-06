SELECT id AS pay_dat, id AS pay_day1
  FROM (SELECT *
          FROM (SELECT ltrim(sys_connect_by_path(id, '; '), '; ') AS "ID"
                  FROM (SELECT id, lag(id) over(ORDER BY id_ord) AS id_1
                          FROM (SELECT DISTINCT TO_CHAR(pt.dat, 'dd.mm.yyyy') AS id, TRUNC(pt.dat) AS id_ord
                                  FROM srvdep        sd,
                                       patserv       ps,
                                       payserv       py,
                                       patient       p,
                                       payment_total pt
                                  WHERE TRUNC(pt.dat) BETWEEN :DATFROM AND :DATTO
  			        AND pt.patientid = :PATIENTID
                                   AND ps.srvdepid = sd.keyid
                                   AND ps.patientid = p.keyid
                                   AND ps.payservid = py.keyid
                                   AND py.payment_totalid = pt.keyid
                                   AND pt.luid IN
                                       (SELECT l.keyid
                                          FROM lu l
                                         WHERE l.tag = 24
                                           AND l.code IN (1, 2, 3, 21, 22, 23))
                                   AND py.pay_return_status IS NULL
                                 GROUP BY p.num,
                                          initcap(p.lastname || ' ' ||
                                                  p.firstname || ' ' ||
                                                  p.secondname),
                                          pt.dat))
                 start with id_1 IS NULL
                connect BY id_1 = prior id
                 ORDER BY 1 DESC)
         WHERE ROWNUM = 1)