create or replace procedure get_uniq_oms_stom_error_check(p_date1 IN date,
                                                          p_date2 IN date,
                                                          rc1     IN OUT pkg_global.ref_cursor_type) AS
begin
  OPEN rc1 FOR
/* запрос к атблицам с стг*/
    with s AS
     (SELECT fn_pat_num_by_id(v.patientid) AS pnum,
             fn_pat_name_by_id(v.patientid) AS fio,
             smp.note AS stg_n,
             v.num AS visnum,
             TO_CHAR(v.dat, 'dd.mm.yyyy') AS visdat,
             TO_CHAR(smp.open_dat, 'dd.mm.yyyy') AS open_dat,
             TO_CHAR(smp.close_dat, 'dd.mm.yyyy') AS close_dat,
             smp.open_dat AS open_dat_d,
             smp.close_dat AS close_dat_d,
             dd.text AS doc,
             smp.keyid AS stkeyid,
             smp.mes_id,
             pd.keyid AS pdkeyid,
             (SELECT l.lcode FROM lu l WHERE l.keyid = v.caseresult2id) AS rescod,
             v.casetypeid AS zakr,
             v.vistype,
             v.patientid AS patid,
             v.visit_type_id AS tvis,
             v.keyid AS vkeyid,
             NVL(decode(NVL(v.rootid, 0),
                        0,
                        (SELECT MAX(vl.dat1)
                           FROM visit vl
                          WHERE vl.rootid = v.keyid),
                        1,
                        (SELECT MAX(vl.dat1)
                           FROM visit vl
                          WHERE vl.rootid = v.rootid)),
                 v.dat1) vmax
        FROM standard_model_patdiag smp,
             visit                  v,
             patdiag                pd,
             docdep                 dd,
             agr                    a
       WHERE pd.visitid = v.keyid
         AND smp.patdiag_id = pd.keyid
         AND dd.keyid = v.doctorid
         AND v.agrid = a.keyid
         AND a.finance = 5
         AND TRUNC(v.dat) BETWEEN p_date1 AND p_date2)

    SELECT 'Не закрыт СТГ в закрытом случае' AS etext,
           s.*
      FROM s
     WHERE s.zakr = 39243
       AND s.close_dat IS NULL
    UNION
    SELECT 'Не заполено поле "причина неполного оказания услуг" в СТГ при прерванном случае лечения' AS etext,
           s.*
      FROM s
     WHERE s.rescod IN ('302', '303')
       AND s.stg_n NOT IN (109, 110)
       AND NOT EXISTS (SELECT 1
              FROM solution_reg.form_result_sm_patdiag       rsp,
                   solution_reg.form_result_value_sm_patdiag vsm,
                   solution_form.form_item                   fi
             WHERE rsp.link_id = s.stkeyid
               AND vsm.form_result_id = rsp.id
               AND fi.id = vsm.form_item_id
               AND UPPER(fi.code) like UPPER('reason')
               AND length(NVL(vsm.text, '1')) > 1)
    UNION
    SELECT 'Для СТГ по неотложной помощи неправильно указана цель посещения' AS etext,
           s.*
      FROM s
     WHERE s.vistype <> 6
       AND s.stg_n IN ('81', '82')
    UNION
    SELECT 'СТГ 109 не применим вместе с СТГ 73, 74, 81-82, 83-98, 103-107, 108, 110' AS etext,
           s.*
      FROM s
     WHERE s.stg_n = '109'
       AND EXISTS (SELECT 1
              FROM standard_model_patdiag smp1
             WHERE smp1.patdiag_id = s.pdkeyid
               AND (smp1.note IN ('73', '74', '110') OR
                    to_number(smp1.note) BETWEEN 81 AND 98 OR
                    to_number(smp1.note) BETWEEN 103 AND 108))
    UNION
    SELECT 'Для СТГ c профилактической целью неправильно указана цель посещения' AS etext,
           s.*
      FROM s
     WHERE s.vistype not in ('2', '18')
       AND s.stg_n IN ('73',
                       '74',
                       '75',
                       '76',
                       '77',
                       '78',
                       '79',
                       '80',
                       '85',
                       '101',
                       '103',
                       '104',
                       '105',
                       '106',
                       '107')
    UNION
    SELECT 'Для СТГ по заболеванию неправильно указана цель посещения или указан разовый тип посещения' AS etext,
           s.*
      FROM s
     WHERE (s.vistype <> 1 OR s.tvis <> 87918000)
       AND s.stg_n NOT IN ('73',
                           '74',
                           '75',
                           '76',
                           '77',
                           '78',
                           '79',
                           '80',
                           '81',
                           '82',
                           '85',
                           '101',
                           '103',
                           '104',
                           '105',
                           '106',
                           '107',
                           '109',
                           '110',
                           '113')
    UNION
    SELECT 'Разные источники финансирования в рамках одного случая' AS etext,
           s.*
      FROM s
     WHERE PKG_STAT_VALIDATION.talon_oms_diff_fin(s.vkeyid) = 1
    UNION
    SELECT 'Введен доплатный СТГ без указания основного' AS etext,
           s.*
      FROM s
     WHERE s.stg_n IN ('109', '113')
       AND NOT EXISTS
     (SELECT 1
              FROM standard_model_patdiag smp1, visit v1, patdiag pd1
             WHERE pd1.visitid = v1.keyid
               AND smp1.patdiag_id = pd1.keyid
               AND smp1.note NOT IN ('109', '113')
               AND v1.num = s.visnum)
    UNION
    SELECT 'Некорректная дата закрытия СТГ' AS etext,
           s.*
      FROM s
     WHERE (TO_DATE(s.close_dat, 'dd.mm.yyyy') > TRUNC(s.vmax) OR
           TO_DATE(s.close_dat, 'dd.mm.yyyy') <
           TO_DATE(s.visdat, 'dd.mm.yyyy'))
       AND s.zakr = 39243
    UNION
    SELECT 'Закрыт доплатный СТГ без закрытия основного' AS etext,
           s.*
      FROM s
     WHERE s.stg_n IN ('109', '113') 
       AND s.close_dat is not null
       AND EXISTS
     (SELECT 1
              FROM standard_model_patdiag smp1, visit v1, patdiag pd1
             WHERE pd1.visitid = v1.keyid
               AND smp1.patdiag_id = pd1.keyid
               AND smp1.note NOT IN ('109', '113')
               AND v1.keyid = s.vkeyid
               AND smp1.close_dat IS NULL) 

    UNION
    SELECT 'СТГ не соответствует цели посещения' AS etext,
           s.*
      FROM s
      WHERE s.vistype not in ('2', '18')
      and s.stg_n in (/*'43',*/ 73/*, 28*/) /*поменял СТГ 100 на 43, т.к. 100 проходит с целью 1*/
      and not EXISTS (SELECT 1
                 FROM patserv ps 
              WHERE ps.visitid = s.vkeyid and ps.inv_status != 0)
 -- конец         
    UNION
    SELECT 'Дата начала СТГ позднее даты закрытия' AS etext,
           s.*
      FROM s
     WHERE trunc(s.close_dat_d) is not null
       AND trunc(s.open_dat_d) > trunc(s.close_dat_d)
    UNION
    SELECT 'У пациента уже есть 109 СТГ в текущем году, по правилам ОМС он оплачивается только 1 раз в год' AS etext,
           s.*
      FROM s
     WHERE s.stg_n = '109'
       AND EXISTS
     (SELECT 1
              FROM standard_model_patdiag smp1, visit v1, patdiag pd1
             WHERE pd1.visitid = v1.keyid
               AND v1.patientid = s.patid
               AND smp1.patdiag_id = pd1.keyid
               AND smp1.note = '109'
               AND TRUNC(v1.dat) > trunc(s.open_dat_d,'YEAR')
               AND trunc(v1.dat) < (s.visdat)
               AND v1.num <> s.visnum);
END;
