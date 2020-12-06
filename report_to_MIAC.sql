create or replace procedure get_oms_monitor_miac_2019(p_date1 IN date,
                                                   p_date2 IN date,
                                                  /* p_agrid in number,*/
                                                   p_agrid in VARCHAR2,
                                                   rc1 IN OUT pkg_global.ref_cursor_type)
-- отчет по услугам
AS
begin
OPEN rc1 FOR

with x as
 (select t.visitid,
         t.sdcode,
         t.pat_id,
         t.ikeyid,
         t.vrootid,
         substr(t.sdcode, 1, 4) as rz_code,
         t.spc_code,
         t.days,
         t.sdtext,
         t.ddays,
         t.vis_in_event,
         t.out_status,
         t.bill_month,
         t.profcode,
         t.vistype,
         t.place_code,
         t.proftext,
         t.iamount
    from V_SRV_OMS_IN_BILL_ALL t
   where trunc(t.benddate) between p_date1 and p_date2
  /*  and trunc(t.bdate) between to_date('01.02.2019','dd.mm.yyyy') and to_date('09.01.2020','dd.mm.yyyy')*/
  /* and (REPLACE(p_agrid, '''') IS NULL OR t.agrid IN (p_agrid))*/
   AND (REPLACE(p_agrid, '''') IS NULL OR t.agrid IN ((SELECT (column_value).getnumberval() AS keyid FROM xmltable(p_agrid))))
   and t.irefuse_status = 0)

-- Профилактические посщения, всего
select '100' as sortcode,
       'Посещения с профилактической целью, всего' as text,
       count(distinct(decode(x.rz_code,
                             '3.87', null,
                             '3.19', null,
                             x.visitid)))
                             +
       count(distinct(decode(x.sdcode,'3.19.47',x.visitid
                                      ,'3.19.48',x.visitid
                                      ,'3.19.49',x.visitid
                                      ,null
                                                       )))
                              as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
      
  from x
 where (x.rz_code in /*посещения с проф и иными целями, ДВН, ДДУ, Осмотры детей 514Н, осмотры взрослых по приказу 1011Н, СТГ профцели, посещения по ДН, ДВН */
       ('3.41', '3.51', '3.18', '3.36'/*, '3.19'*/, '3.23', '3.25', '3.87', '3.29', '3.66', '3.89', '3.92', '3.91', '3.96', '3.97', '3.98', '3.99')
   or x.sdcode in ('3.19.47','3.19.48','3.19.49')) /*25.11.2019 добавил or x.sdcode in ('3.19.47','3.19.47','3.19.42')*/
   union 
  select '102' as sortcode,
       'В том числе: посещения профилактические по подушевому нормативу' as text,
      count(distinct(x.visitid)) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code = '3.51'
  union 
  select '104' as sortcode,
       'В том числе: посещения профилактические по тарифу за посещение (без стоматологических)' as text,
       count(distinct(x.visitid)) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code = '3.41'
  union 
 select '107' as sortcode,
       'В том числе: посещения стоматологические с профилактической целью' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       count(distinct(x.visitid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.66'
     union 
  select '108' as sortcode,
       'В том числе: посещения профилактические законченного случая 2 этапа диспансеризации взрослого населения' as text,
     /* count(distinct(x.visitid)) as qty,*/
      count(distinct(decode(x.sdcode,'3.19.47',x.visitid
                                      ,'3.19.48',x.visitid
                                      ,'3.19.49',x.visitid
                                      ,null
                                                       ))) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code = '3.19' /*должны входить только ВОП, терапевт участковый, терапевт*/
  /* x.sdcode in ('3.19.47','3.19.48','3.19.49')*/ /*25.11.2019*/
  union 
  select '110' as sortcode,
       'Проведение профилактических медицинских осмотров' as text,
       count(distinct(decode(x.rz_code,
                             '3.87',
                             null,
                             x.visitid))) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code in ('3.91', '3.92', '3.18', '3.36', '3.29', '3.89', '3.23', '3.25', '3.96', '3.97')
  union 
 select '113' as sortcode,
       'диспансеризация взрослого населения(случаи) Всего' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.18', '3.36', '3.96', '3.89')
  union 
 select '114' as sortcode,
       'диспансеризация взрослого населения(случаи) [Приказ 869Н]' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.18', '3.36')
   union 
 select '115' as sortcode,
       'диспансеризация взрослого населения(случаи) [Приказ 124Н]' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.96')
  union 
 select '116' as sortcode,
       'диспансеризация определенных групп взрослого населения с периодичностью проведения 1 раз в 2 года с проведением маммографии (случаи)' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.sdcode = '3.89.1'
    union 
 select '118' as sortcode,
       'диспансеризация определенных групп взрослого населения с периодичностью проведения 1 раз в 2 года с исследованием кала на скрытую кровь (случаи)' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.sdcode = '3.89.2'  
   union 
 select '120' as sortcode,
       'профилактические осмотры взрослого населения Всего' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.29', '3.97')
  union
  select '121' as sortcode,
       'профилактические осмотры взрослого населения [Приказ 1011Н]' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.29')
  union
  select '122' as sortcode,
       'профилактические осмотры взрослого населения [Приказ 124Н]' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in ('3.97')
    union 
 select '123' as sortcode,
       'диспансеризация детей-сирот и детей, оставшихся без попечения родителей, в том числе усыновленных (удочеренных)' as text,
       count(distinct(x.visitid)) as qty,
       0 as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.23'
     union 
 select '124' as sortcode,
       'профилактические осмотры несовершеннолетних' as text,
     --  round(count(distinct(x.visitid))*1.56, 0) as qty,
     --  count(distinct(x.visitid)) as day_in_case,
       count(distinct(x.visitid)) as qty,
       round(count(distinct(x.visitid))*1.56, 0) as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.25'
      union 
  select '125' as sortcode,
       'посещения профилактические по подушевому нормативу, диспансерное наблюдение' as text,
      count(distinct(x.visitid)) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code = '3.92'
   union 
  select '126' as sortcode,
       'посещения профилактические по тарифу за посещение (без стоматологических), диспансерное наблюдение' as text,
       count(distinct(x.visitid)) as qty,
      0 as day_in_case,
      0 as usl_qty,
      sum(x.iamount) iamount
  from x
 where x.rz_code = '3.91'
 
  union 
 select '130' as sortcode,
       'Посещения по неотложной медицинской помощи (вкл стоматологические)'as text,
       count(distinct(x.visitid)) as qty,
       0  as day_in_case,
       0  as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.43', '3.67')
 union all
 select decode(rz_code,'3.43','133',
                       '3.67','135') as sortcode,
       decode(rz_code,'3.43', 'посещения по неотложной медицинской помощи ',
                      '3.67', 'посещения стоматологические по неотложной медицинской помощи ')
       as text,
       count(distinct(x.visitid)) as qty,
       0  as day_in_case,
       0  as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.43', '3.67')
 group by decode(rz_code,'3.43','133',
                         '3.67','135'),
          decode(rz_code,'3.43', 'посещения по неотложной медицинской помощи ',
                         '3.67', 'посещения стоматологические по неотложной медицинской помощи ')
 
 union 
 select '140' as sortcode,
       'Обращения в связи с заболеваниями (вкл стоматологические)' as text,
       count(distinct(decode(x.rz_code, '3.68', x.pat_id || x.spc_code || x.bill_month, '3.83', x.pat_id || x.spc_code || x.bill_month, x.visitid))) as qty,
       count(distinct(decode(x.rz_code, '3.44', null, '3.54', null, x.visitid))) +  /*посещения в составе обращений СТГ и беременным*/
       SUM(decode(x.rz_code, '3.44', x.vis_in_event, '3.54', x.vis_in_event)) as day_in_case,    /*посещения в обычных обращениях*/
       0 as usl_qty, /*количестов услуг СТГ обращений*/
       sum(x.iamount) iamount
  from x
 where  /*обращения, услуги при постановке на учет по беременности и 3 триместру беременных, СТГ обращения*/
     x.rz_code in ('3.44', '3.54', '3.34', '3.85', '3.68', '3.83')
  union 
 select '144' as sortcode,
       'В том числе: обращения по тарифу' as text,
       count(distinct(x.visitid)) as qty,
       SUM(decode(x.rz_code, '3.44', x.vis_in_event)) +  count(distinct(decode(x.rz_code, '3.44', null, x.visitid))) as day_in_case,
       0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in ('3.44', '3.34', '3.85')
   union 
 select '146' as sortcode,
       'В том числе: обращения по подушевому финансированию' as text,
       count(distinct(x.visitid)) as qty,
        SUM(x.vis_in_event) as day_in_case,
      0  as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.54'
    union all
 select '148' as sortcode,
       'В том числе: Стоматология - обращения' as text,
        count(distinct(x.pat_id || x.spc_code || x.bill_month)) as qty,
        count(distinct(x.visitid)) as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in('3.68', '3.83')
 union 
 select decode(grouping(to_char(200 + x.profcode)), 1 , '200', to_char(200 + x.profcode)),
        decode(grouping('ДС профиль: ' || x.proftext), 1, 'Медицинская помощь в условиях дневного стационара (случаи лечения заболевания)', 'ДС профиль: ' || x.proftext),
        count(distinct(x.vrootid)) as qty ,
        sum(x.ddays) as day_in_case,
        0 as qty,
       sum(x.iamount) iamount
    from x where x.rz_code in('2.34', '2.36', '2.46')
    group by rollup(to_char(200 + x.profcode), 'ДС профиль: ' || x.proftext)
    having(to_char(200 + x.profcode) is null or 'ДС профиль: ' || x.proftext is not null)
 union 
  select '300' as sortcode,
       'Медицинская помощь в условиях круглосуточного стационара (всего случаев госпитализации)' as text,
        count(distinct(x.vrootid)) as qty,
        sum(decode(x.out_status, 1, x.days, 0)) as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code like '1.%'
 union 
  select '310' as sortcode,
       'Медицинская помощь в условиях круглосуточного стационара (случаи госпитализации без ВМП, реабилитации и онкологии)' as text,
        count(distinct(x.vrootid)) as qty,
        sum(decode(x.out_status, 1, x.days, 0)) as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in ('1.20', '1.22', '1.32')
  union 
  select '312' as sortcode,
       'Случаи госпитализации по профилю онкология' as text,
        count(distinct(x.vrootid)) as qty,
        sum(decode(x.out_status, 1, x.days, 0)) as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '1.35'
  union 
  select '320' as sortcode,
       'Медицинская помощь в условиях круглосуточного стационара (случаи госпитализации с использованием ВМП)'  as text,
        count(distinct(x.visitid)) as qty,
        sum(decode(x.out_status, 1, x.days, 0)) as day_in_case,
        0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '1.19'
   union 
  select '330' as sortcode,
        'Медицинская помощь в условиях круглосуточного стационара (случаи госпитализации по медицинской реабилитации)'  as text,
        count(distinct(x.visitid)) as qty,
        sum(decode(x.out_status, 1, x.days, 0)) as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code in ('1.31', '1.30', '1.33')
 union 
  select decode(x.rz_code, '3.93','400',
                        '3.94','401',
                        '415' ) as sortcode,
         decode(x.rz_code, '3.93', 'Компьютерная томография',
                           '3.94', 'Магнитно-резонансная томография',
                           'Сцинтиграфические исследования') as text,
         0 as qty,
         0 as day_in_case,
         count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
 from x where x.rz_code in ('3.93', '3.94', '3.40')
 group by decode(x.rz_code, '3.93','400',
                        '3.94','401',
                        '415' ),
          decode(x.rz_code, '3.93', 'Компьютерная томография',
                            '3.94', 'Магнитно-резонансная томография',
                            'Сцинтиграфические исследования')
   union 
  select '430' as sortcode,
        'Стоматология: доплатные СТГ'  as text,
        0 as qty,
        0 as day_in_case,
        count(distinct(x.ikeyid)) as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.77'
     union 
  select '440' as sortcode,
        'Постановка на диспансерный учет по беременности'  as text,
        count(distinct(x.visitid)) as qty,
        count(distinct(x.visitid)) as day_in_case,
        0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.34' or x.sdcode in('3.44.2.2', '3.44.2.24')
      union 
  select '450' as sortcode,
        'Обращение в связи с проведением обследования в III триместре '  as text,
        count(distinct(x.visitid)) as qty,
        count(distinct(x.visitid)) as day_in_case,
        0 as usl_qty,
       sum(x.iamount) iamount
  from x
 where x.rz_code = '3.85' or x.sdcode in('3.44.64', '3.44.64.04')
  union all
      select decode(rz_code,'3.44','500',
                          '3.54','502',
                          '3.41','514',
                          '3.51','506',
                          '3.43','520') as sortcode,
          decode(rz_code,'3.44', 'Фельдшер: обращения',
                          '3.54','Фельдшер: обращения',
                          '3.41','Фельдшер: посещение с профилактическими и иными целями',
                          '3.51','Фельдшер: посещение с профилактическими и иными целями',
                          '3.43','Фельдшер: посещения при оказании медицинской помощи в неотложной форме')
       as text,
       count(distinct(x.visitid)) as qty,
       SUM(decode(x.rz_code, '3.44', x.vis_in_event, '3.54', x.vis_in_event, 0))  as day_in_case,
      0  as usl_qty,
       sum(x.iamount) iamount
  from x
 where lower(x.sdtext) like '%фельдшер%' and x.rz_code in('3.44', '3.54', '3.41', '3.51', '3.43')
 group by decode(rz_code,'3.44','500',
                          '3.54','502',
                          '3.41','514',
                          '3.51','506',
                          '3.43','520'),
          decode(rz_code,'3.44', 'Фельдшер: обращения',
                          '3.54','Фельдшер: обращения',
                          '3.41','Фельдшер: посещение с профилактическими и иными целями',
                          '3.51','Фельдшер: посещение с профилактическими и иными целями',
                          '3.43','Фельдшер: посещения при оказании медицинской помощи в неотложной форме')
 union 
 select '550' as  sortcode,
       'Разовые посещения по поводу заболеваний на дому' as text,
        count(distinct(x.visitid)) as qty,
        0 as day_in_case,
        0 as usl_qty,
       sum(x.iamount) iamount
from x where  x.rz_code in('3.41', '3.51', '3.43') and x.vistype in (1,6) and x.place_code in (2,5)
union all
select '560' as  sortcode,
       'в т.числе при оказании медицинской помощи в неотложной форме' as text,
        count(distinct(x.visitid)) as qty,
        0 as day_in_case,
        0 as usl_qty,
       sum(x.iamount) iamount
from x where x.rz_code = '3.43' and x.place_code in (2,5)
;
end;
