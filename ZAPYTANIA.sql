/*ZAPYTANIA:
1. Ilość egzemplarzy dla danego autora
2. Największa częstotliwość publikowania książek
3. Dekady z największą liczbą książek
4. Dekady z największą liczbą książek dla danego wydawnictwa
5. Najczęściej wypożyczani autorzy*/

--1. Ilość egzemplarzy dla danego autora
select  
	aut_id, aut_imie||' '|| aut_nazwisko autor,
    sum(k.ks_liczba_egz)  licz_egz
from 
	bibl_ksiazka k
	join bibl_autor_ksiazka ka on k.ks_id = ka.ka_ks_id
	join bibl_autor a on ka.ka_aut_id = a.aut_id
group by 
	aut_id, 
	aut_imie, 
	aut_nazwisko
order by 
	licz_egz desc;

--2. Częstotliwość wydawania książek w okresie od debiutu do śmierci autora
with czestotliwosc_wyd as (
select 
	distinct a.aut_id,
    a.aut_imie||' '||a.aut_nazwisko autor,
    count(k.ks_id) over (partition by a.aut_id) liczba_ksiazek,
    a.aut_data_sm, min(k.ks_rok_wydania) over (partition by a.aut_id) pierwsza_ksiazka
from 
	bibl_autor a
	left join bibl_autor_ksiazka ka on a.aut_id = ka.ka_aut_id
	left join bibl_ksiazka k on ka.ka_ks_id = k.ks_id
order by 
	a.aut_id)

select 
	autor, 
	liczba_ksiazek, 
	pierwsza_ksiazka,
	round((extract(year from aut_data_sm) - pierwsza_ksiazka)/liczba_ksiazek, 2)  as czestotliwosc
from 
	czestotliwosc_wyd;

--3. Dekada z największą liczbą książek
select 
	substr(to_char(ks_rok_wydania),1,3)||'0-01-01' as poczatek_dekady,
	substr(to_char(ks_rok_wydania),1,3)||'9-12-31' as koniec_dekady,
	count(1) as liczba_ksiazek
from 
	bibl_ksiazka
group by 
	substr(to_char(ks_rok_wydania),1,3)
order by 
	liczba_ksiazek desc;

--4. Liczba wydanych ksiazek dla dekady i wydawnictwa
select 
    substr(to_char(ks_rok_wydania),1,3)||'0-01-01' as poczatek_dekady,
    substr(to_char(ks_rok_wydania),1,3)||'9-12-31' as koniec_dekady,
    ks_wyd_id,
    count(*) as liczba_ksiazek
from 
    bibl_ksiazka
group by 
    substr(to_char(ks_rok_wydania),1,3), 
	ks_wyd_id
order by 
	poczatek_dekady, 
	liczba_ksiazek desc;
	
--5. Najczęściej wypożyczani autorzy
select 
	distinct count(*) over(partition by k.ks_id) licz_wypozyczen, 
	k.ks_tytul
from 
	bibl_wypozyczenia w
	left join bibl_egzemplarze e on w.wyp_egz_id = e.egz_id
	left join bibl_ksiazka k on e.egz_ks_id = k.ks_id
order by 
	licz_wypozyczen desc;