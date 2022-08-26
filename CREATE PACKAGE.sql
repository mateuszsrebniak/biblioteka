create or replace package bibl_pck_dodaj as
-- procedura zastępująca funkcję dbms_output.putline(), jako parametr przyjmuje tekst, który ma zastać wyświetlony
procedure pisz(txt varchar2);
-- dodaje nową książkę, a w tym również autora oraz rekord do tabeli bibl_autor_ksiazka
procedure dodaj_ksiazke(
        p_tytul               varchar2
    ,   p_rok_wydania         number
    ,   p_isbn                varchar2
    ,   p_id_wydawnictwa      number
    ,   p_id_autora           number default null
    ,   p_imie_autora         varchar2 default null
    ,   p_nazwisko_autora     varchar2 default null
    ,   p_data_urodzenia      date default null
    ,   p_data_smierci        date default null
    ,   p_plec                varchar2 default null
    );
procedure dodaj_klienta(
        p_imie              varchar2
    ,   p_nazwisko          varchar2
    ,   p_plec              varchar2
    ,   p_data_urodzenia    date
    ,   p_ab_data_od        date default null
    ,   p_ab_rodzaj         varchar2 default null
    );
end bibl_pck_dodaj;
/

create or replace package body bibl_pck_dodaj as
procedure pisz(txt varchar2) as
begin
    dbms_output.put_line(txt);
end;
procedure dodaj_ksiazke(
        p_tytul               varchar2
    ,   p_rok_wydania         number
    ,   p_isbn                varchar2
    ,   p_id_wydawnictwa      number
    ,   p_id_autora           number default null
    ,   p_imie_autora         varchar2 default null
    ,   p_nazwisko_autora     varchar2 default null
    ,   p_data_urodzenia      date default null
    ,   p_data_smierci        date default null
    ,   p_plec                varchar2 default null
    ) as 
v_id_ksiazki 	number;
v_id_autora 	number;
begin
    if p_id_autora is null then
        if p_nazwisko_autora is null then
            raise_application_error(-20001, 'podaj istniejące id lub wprowadź nowego autora - podaj nazwisko');
        elsif p_data_urodzenia is null then
            raise_application_error(-20002, 'podaj istniejące id lub wprowadź nowego autora - podaj datę urodzenia');
        elsif p_plec is null then
            raise_application_error(-20003, 'podaj istniejące id lub wprowadź nowego autora - podaj płeć');
        else
            insert into bibl_autor(aut_imie, aut_nazwisko, aut_data_ur, aut_data_sm, aut_plec)
                values(p_imie_autora, p_nazwisko_autora, p_data_urodzenia, p_data_smierci, p_plec)
			returning aut_id into v_id_autora;
            pisz('dodano autora');
			
        end if;
    end if;
    insert into bibl_ksiazka(ks_tytul, ks_rok_wydania, ks_isbn, ks_wyd_id)
        values(p_tytul, p_rok_wydania, p_isbn, p_id_wydawnictwa)
        returning ks_id into v_id_ksiazki;
    pisz('dodano książkę');
    
    if p_id_autora is null then
		insert into bibl_autor_ksiazka(ka_aut_id, ka_ks_id)
			values(v_id_autora, v_id_ksiazki);
	else insert into bibl_autor_ksiazka(ka_aut_id, ka_ks_id)
			values(p_id_autora, v_id_ksiazki);
    end if;
end;
procedure dodaj_klienta(
        p_imie              varchar2
    ,   p_nazwisko          varchar2
    ,   p_plec              varchar2
    ,   p_data_urodzenia    date
    ,   p_ab_data_od        date default null
    ,   p_ab_rodzaj         varchar2 default null
    ) 
as
v_id_klienta number;
begin
    insert into bibl_klient(kl_imie, kl_nazwisko, kl_plec, kl_data_ur)
        values(p_imie, p_nazwisko, p_plec, p_data_urodzenia)
    returning kl_id into v_id_klienta;
    pisz('dodano klienta');
    if p_ab_data_od is null then
        pisz('dodano klienta bez abonamentu');
    else insert into bibl_abonament(abn_data_od, abn_kl_id, abn_rab_kod)
        values(p_ab_data_od, v_id_klienta, p_ab_rodzaj);
        pisz('dodano klienta oraz abonament');
    end if;
end;
end bibl_pck_dodaj
-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
create or replace package bibl_pck_generuj as
-- generuje wypożyczenie z datą systemu; nie przyjmuje parametrów
procedure generuj_wyp;
-- generuje abonament z datą systemu; nie przyjmuje parametrów
procedure generuj_abnm;
end bibl_pck_generuj;
/
create or replace package body bibl_pck_generuj as
procedure generuj_wyp as
v_klient number;
v_ksiazka number;
begin
    select *  into v_klient, v_ksiazka from
    (
        select kl_id from bibl_klient 
        where kl_id in (   select abn_kl_id
                                from bibl_abonament
                                where abn_data_do >= trunc(current_date))
        order by dbms_random.value() fetch first 1 row only
    ),
    (
        select egz_id from bibl_egzemplarze
        where egz_id not in (   select wyp_egz_id
                                from bibl_wypozyczenia
                                where wyp_real_data_zwr is null)
        order by dbms_random.value() fetch first 1 row only
    );
    
    insert into bibl_wypozyczenia(wyp_kl_id, wyp_egz_id, wyp_data)
        values(v_klient, v_ksiazka, current_date);
    dbms_output.put_line('wypożyczono książkę');
end generuj_wyp;
-------------------------------------------------------
-------------------------------------------------------
procedure generuj_abnm as
v_klient number;
v_rodzaj varchar2(3 char);
begin
	select * into v_klient, v_rodzaj from
	(
		select kl_id from bibl_klient
		where kl_id not in (	select abn_kl_id
									from bibl_abonament
									where abn_data_do >= trunc(current_date)
								)
		order by dbms_random.value() fetch first 1 row only
	),
	(
		select rab_kod from bibl_rodz_abnm
		order by dbms_random.value() fetch first 1 row only
	);
	insert into bibl_abonament(abn_data_od, abn_kl_id, abn_rab_kod)
		values(current_date, v_klient, v_rodzaj);
end generuj_abnm;
end bibl_pck_generuj;