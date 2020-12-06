create or replace view v_srv_oms_in_bill_all as
select
  -- данные по пациенту
   p.num as pnum,
   initcap(p.lastname || ' ' || p.firstname || ' ' || p.secondname) as pfio,
   p.keyid as pat_id,
   p.birthdate as birthdate,
   gsp_get_age_12_group(p.birthdate, i.dat) as age_gr,
   p.sex as psex,
   p.lives as lives,
   (select 1 from lu d where d.keyid = p.doc_id and d.code in (10, 11, 12)) as foreign_status, /* статус иностранца: в документе удостоверяющем личность стоит один из документов Иностранный паспорт
Свидительство иммигранта Вид на жительство  */
   --данные по счету
   b.buhcode as buhcode,
   b.enddat as benddate,
   b.dat    as bdate,
   b.final_pay_dat as bfindat,
   TO_NUMBER(TO_CHAR(b.enddat,'YYYY')) as byear,
   to_char(b.enddat, 'mmyyyy') as bill_month,
   a.typ as atype,
   --данные по услугам  в счетах
   i.keyid as ikeyid,
   i.agrid as agrid,
   i.dat   as i_dat,
   i.amount as iamount,
   sd.code as sdcode,
   sd.text as sdtext,
   (select  dd.status_dep from visit v, dep dd where v.keyid = ps.visitid and dd.keyid = v.dep1id) as status_dep,
   nvl(i.refuse_status, 0) as irefuse_status,
   ps.keyid as pskeyid,
   ps.dat as psdat,
   ps.policeid as pspoliceid,
   -- типы услуг для отчетов по поликлинике
   case
     when substr(sd.code, 1, 4) in ('3.44', '3.54', '3.85', '3.83', '3.68', '3.34', '3.35','3.120', '3.121') then 'obr'
     when substr(sd.code, 1, 4) in ('3.43', '3.67','3.118', '3.119') then 'emerg'
     when substr(sd.code, 1, 4) in ('3.66', '3.41', '3.51', '3.29', '3.18', '3.19', '3.23', '3.36', '3.37', '3.89', '3.25', '3.92', '3.91', '3.96', '3.97', '3.98', '3.99', '3.87', '3.116', '3.117') then 'prof'

     else 'other'
   end as srv_type,
 --  (select rk.name from infis.OMS79_RKUV3_RAZDEL rk where rk.code = substr(sd.code,1,4)) as rku_razdel_n,
   -- данные по посещениям
    ps.visitid as visitid,
   (select v.rootid from visit v where v.keyid = ps.visitid) as vrootid,
   (select nvl(v.dat1, v.dat) from visit v where v.keyid = ps.visitid) as vdat1,
   nvl((select d.out_status from visit v, dep d where v.keyid = ps.visitid and v.dep1id = d.keyid),-1) as out_status,
   /*количество койок-дней в стационаре*/
   (select decode(trunc(r.dat1)-trunc(po.dat), 0, 1, trunc(r.dat1)-trunc(po.dat)) from visit v, visit po, visit r, dep d
   where v.keyid = ps.visitid and po.vistype = 101 and po.keyid = v.rootid and r.vistype > 101 and r.rootid = v.rootid and r.dep1id = d.keyid and d.out_status = 1) as days,
   /*количество пациенто-дней в дневном стационаре*/
   (select count(DISTINCT vd.keyid) FROM visit_days vd, visit v WHERE v.keyid = ps.visitid and vd.visit_id = v.rootid) as ddays,
   (select count(DISTINCT vo.keyid) FROM visit vo, visit v WHERE v.keyid = ps.visitid and vo.num = v.num and v.num > 0) as vis_in_event,
   nvl((select v.vistype from visit v where v.keyid = ps.visitid),-1) as vistype,
   (select f.code from visit v, fcateg f where v.keyid = ps.visitid and v.profid = f.keyid) as profcode,
   (select f.text from visit v, fcateg f where v.keyid = ps.visitid and v.profid = f.keyid) as proftext,
   nvl((select l.lcode from visit v, lu l where v.keyid = ps.visitid and v.placeid = l.keyid), -1) as place_code,
   -- данные по отделению
   nvl((select d.keyid from visit v, docdep dd, dep d where v.keyid = ps.visitid and dd.keyid = v.doctorid and dd.depid = d.keyid), '-1') as dep_id,
   nvl((select d.text from visit v, docdep dd, dep d where v.keyid = ps.visitid and dd.keyid = v.doctorid and dd.depid = d.keyid), '-1') as dep_text,
   -- данные по врачу
   nvl((select dd.keyid from visit v, docdep dd where v.keyid = ps.visitid and dd.keyid = v.doctorid), 0) as doc_id,
   nvl((select dd.text from visit v, docdep dd where v.keyid = ps.visitid and dd.keyid = v.doctorid), 0) as doc_text,
   nvl((select dd.specid from visit v, docdep dd where v.keyid = ps.visitid and dd.keyid = v.doctorid), 0) as spc_id,
   nvl((select l.lcode from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.specid), '-1') as spc_code,
   nvl((select l.shorttext from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.specid),'-1') as spc_stext,
   nvl((select l.text from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.specid),'-1') as spc_text,
   fn_get_diag_code_by_type(ps.visitid,1) as ds_osn_code,
   fn_get_diag_name_by_type(ps.visitid,1) as ds_osn,
   nvl((select dd.positionid from visit v, docdep dd where v.keyid = ps.visitid and dd.keyid = v.doctorid), 0) as positionid,
   nvl((select l.lcode from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.positionid),'-1') as position_code,
   nvl((select l.shorttext from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.positionid),'-1') as position_stext,
   nvl((select l.text from visit v, docdep dd, lu l where v.keyid = ps.visitid and dd.keyid = v.doctorid and l.keyid = dd.positionid),'-1') as position_text,
   ps.qty as psqty
    from
   invoice i, agr a, patserv ps, srvdep sd, bill b, patient p
where
i.agrid = a.keyid
and i.billid = b.keyid
and i.patservid = ps.keyid
and i.patientid = p.keyid
and ps.srvdepid = sd.keyid
and a.finance = '5'
/*and a.keyid in (730, 689)*/ /*СОГАЗ, Капитал*/;
