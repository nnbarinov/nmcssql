create or replace procedure pr_update_for_doctor_change(p_partcode in varchar2,
                                                        p_date     in date default (sysdate + 1)) AS
  /*процедура заменяет поля в протоколе карточки пацинета по всему участку для передачи пациентов по нему в РПН, когда меняется врач*/
begin
  for rc in (select p.keyid as pkeyid
               from solution_med.patient p, solution_med.lu l
              where p.areanum_lu_id = l.keyid
                and l.code = p_partcode)

   loop

    delete from solution_reg.form_result_value_patcard fv
     where fv.id in (select f2.id
                       from solution_reg.form_result_value_patcard f2,
                            solution_reg.form_result_patcard       f1
                      where f2.form_result_id = f1.id
                        and f2.form_item_id in (10063000, 10064000) /* записи смены врача или участка, дата направления*/
                        and f1.patient_id in (rc.pkeyid));

    insert into solution_reg.form_result_value_patcard fv
      select solution_reg.s_form_result_value_patcard.nextval * 1000,
             -1,
             sysdate,
             -1,
             sysdate,
             f1.id,
             10064000,
             15820000, -- form_value_id = 15820000 смена врача или участка
             'Смена врача или участка',
             null,
             null,
             to_clob('Смена врача или участка')
        from solution_reg.form_result_patcard f1
       where f1.patient_id in (rc.pkeyid);

    insert into solution_reg.form_result_value_patcard fv
      select solution_reg.s_form_result_value_patcard.nextval * 1000,
             -1,
             sysdate,
             -1,
             sysdate,
             f1.id,
             10063000,
             null,
             to_char(p_date, 'dd.mm.yyyy'), --to_char(sysdate + 1, 'dd.mm.yyyy'),
             null,
             null,
             to_clob(to_char(p_date, 'dd.mm.yyyy'))
        from solution_reg.form_result_patcard f1
       where f1.patient_id in (rc.pkeyid);
  end loop;
end;
