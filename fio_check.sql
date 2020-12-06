  function identity_fio_check_po (p_rootid in number) return number as
  firstname_l varchar2(60);
  lastname_l varchar2(60);
  secondname_l varchar2(60);
  begin

    select p.lastname, p.firstname, p.secondname
    into  firstname_l,  lastname_l, secondname_l
    from  patient p, visit v
    where v.patientid = p.keyid
    and v.keyid = p_rootid;

    if
      (   nvl(regexp_replace(firstname_l, '[^а-я-]*'),0) <> nvl(regexp_replace(firstname_l, '*[ ]*'),0)
      or  nvl(regexp_replace(lastname_l, '[^А-я]*'),0) <> nvl(regexp_replace(lastname_l, '*[ ]*'),0)
      or (nvl(regexp_replace(secondname_l , '[^а-я-]*'),0) <> nvl(regexp_replace(secondname_l, '*[ ]*'),0) and secondname_l is not null)
      )
           then
       return 1;
    else
       return 0;
    end if;

  end identity_fio_check_po;