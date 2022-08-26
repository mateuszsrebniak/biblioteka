create or replace trigger t_abonament_id before insert on bibl_abonament 
for each row 
begin 
    :new.abn_id := seq_bibl_abonament.nextval; 
end; 
/

create or replace trigger t_autor_id before insert on bibl_autor 
for each row 
begin 
    :new.aut_id := seq_bibl_autor.nextval; 
end; 
/

create or replace trigger t_egzemplarze_id before insert on bibl_egzemplarze
for each row
begin
    :new.egz_id := seq_bibl_egzemplarze.nextval;
end;
/

create or replace trigger t_kary_id before insert on bibl_kary 
for each row 
begin 
    :new.kar_id := seq_bibl_kary.nextval; 
end; 
/

create or replace trigger t_klient_id before insert on bibl_klient 
for each row 
begin 
    :new.kl_id := seq_bibl_klient.nextval; 
end; 
/

create or replace trigger t_ksiazka_id before insert on bibl_ksiazka 
for each row 
begin 
    :new.ks_id := seq_bibl_ksiazka.nextval; 
end; 
/

create or replace trigger t_wydawnictwo_id before insert on bibl_wydawnictwo 
for each row 
begin 
    :new.wyd_id := seq_bibl_wydawnictwo.nextval; 
end;
/

create or replace trigger t_wypozyczenia_id before insert on bibl_wypozyczenia
for each row
begin
    :new.wyp_id := seq_bibl_wypozyczenie.nextval;
	:new.wyp_plan_data_zwr := :new.wyp_data + 30;
end;

-- trigger sprawdza, czy dany klient korzysta obecnie z abonamentu
create or replace trigger t_czy_ma_abonament before insert on bibl_abonament
for each row
declare
    v_data_do date;
begin
    select trunc(abn_data_do) into v_data_do
        from bibl_abonament where abn_id = :new.abn_id;
    if v_data_do >= trunc(current_date) then
        raise_application_error(-20100, 'Klient korzysta już z naszego abonamentu');
    end if;
end;
/
-- trigger wstawia okres abonamentu
create or replace trigger t_okres_abonamentu before insert or update on bibl_abonament
for each row
declare
    v_okres number;
begin
    select rab_okres into v_okres 
        from bibl_rodz_abnm where rab_kod = :new.abn_rab_kod;
    :new.abn_data_do := :new.abn_data_od + v_okres;
end;
/
-- trigger sprawdza, czy dany egzemplarz jest dostępny
create or replace trigger t_sprawdz_dostepnosc before insert on bibl_wypozyczenia
for each row
declare
v_id pls_integer;
v_data_zwrotu date;
begin
	select wyp_real_data_zwr into v_data_zwrotu
    from bibl_wypozyczenia
    where wyp_egz_id = :new.wyp_egz_id
    order by wyp_data desc
    fetch first 1 row only;
    if v_data_zwrotu is null then 
    raise_application_error(-20100, 'książka jest obecnie wypożyczona');
    end if;
exception
    when no_data_found then
	dbms_output.put_line('to pierwsze wypożyczenie tej książki');
end;
/
-- trigger wstawia rekord do tabeli bibl_kary, jeśli realna data zwrotu książki jest późniejsza niż planowana
create or replace trigger t_kara after insert or update on bibl_wypozyczenia
for each row
declare
G_KARA number := trunc(:new.wyp_real_data_zwr - :new.wyp_plan_data_zwr) * 2.99;
v_check number;
begin
    if :new.wyp_real_data_zwr > :new.wyp_plan_data_zwr then
        select kar_wyp_id into v_check from bibl_kary where kar_wyp_id = :new.wyp_id;
    end if;
    if v_check is not null then
        update bibl_kary set kar_kwota = G_KARA 
		where kar_wyp_id = v_check;
    end if;
exception
    when no_data_found then
        insert into bibl_kary (kar_wyp_id, kar_kwota) values
        (:new.wyp_id, G_KARA);
end;
