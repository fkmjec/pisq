# Pisq
Pisq je webová aplikace pro hraní piškvorek. Je napsána v jazyce Elixir ve frameworku Phoenix.

## Volba jazyka a nástrojů
Pro aplikaci jsem zvolil jazyk Elixir. Elixir je velmi příjemný pro psaní webových aplikací,
protože má k dispozici Erlangovský VM a nástroje z Erlangovského ekosystému, z nichž se některé mimořádně hodí.
(například práci s procesy a Erlang Term Storage, ale o tom dále).

Phoenix je pak framework pro psaní webových aplikací v Elixiru. Ve většině věcech se chová velmi podobně jako
například Django z prostředí jazyka Python. Navíc nabízí LiveView, což je způsob provázání frontendu a backendu
přes WebSockety.

### o LiveView
Zde se asi hodí něco napsat o LiveView a jeho fungování. Když na "živou" stránku přijde požadavek,
zavolá se nejdříve funkce `mount` na serveru (u nás v souboru `user_live.ex`). Data z ní se dodají
do šablony a ta se pošle na klienta. Následně se spustí live proces na serveru. Klient se s tímto
procesem propojí WebSocketem. Pak si přes tento WebSocket posílají informace a diffy o tom, co se změnilo.
Více je k nalezení na v [dokumentaci](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) frameworku Phoenix.

## Základní principy
Celá aplikace je postavena velmi jednoduše. Na hlavní stránku přijde uživatel a založí si hru.
V té chvíli se vytvoří pro hru objekt `Game`, který ji popisuje, a ten se uloží do tabulky v Erlang Term Storage(ETS).
ETS je in-memory databáze, která je navržena pro použití mnoha procesy najednou.
Zároveň se náhodně vygenerují ID pro hráče a pro pozorovatele. Do jiné tabulky v ETS se pak uloží mapování
těchto ID na herní ID (aby libovolný hráč neměl přístup do administrátorského rozhraní).
V `Game` jsou uložena ID hráčů a pozorovatele, stav herní plochy a čas založení hry.

Uživatel je pak přesměrován do administrátorského rozhraní, kde vidí 3 odkazy; jeden pro hráče za křížky, druhý pro hráče za kolečka a třetí pro pozorovatele. Každý odkaz je ve tvaru `DOMÉNA/play/id`, kde `id` jsou vygenerovaná ID. Odkaz hráče, za kterého chce hrát, si ponechá, další přepošle protihráči/pozorovatelům. Pak se může pomocí jednoho z odkazů přesunout do herního rozhraní, kde vidí herní plochu.

Jakmile se uživatel přesune do herního rozhraní, Phoenix vytvoří proces pro LiveView. Ten si udržuje stav 
v podobě objektu `Game` a reaguje na vstupy z frontendu.  Takový proces existuje separátně pro každého uživatele, stav sdílí pomocí ETS.

Hra skončí, jakmile jeden z hráčů položí 5 křížků nebo 5 koleček v řadě. Vítězství se kontroluje při každém tahu
kontrolou všech možných nových řad pěti symbolů, které procházejí právě položeným symbolem.

Aby počet her nerostl závratně a nám nedošla paměť, každá hra se po zhruba třech dnech z ETS vymaže. Vylepšení
do budoucna by mohlo být ukládání takových her do archivu do nějaké relační databáze.

## Rozdělení programu
Projekt je dělený na dvě základní části, `pisq` a `pisq_web`.

### `pisq`
V modulu `pisq` najdeme veškeré části backendu, které přímo nesouvisí
se zobrazováním obsahu uživateli. Nachází se zde modul `application.ex`, který
obsahuje entrypoint celé aplikace, ve kterém se spouští potřebné procesy.

Složka `utils`, obsahuje soubory s pomocnými funkcemi.
Soubor `game_utils.ex` obsahuje funkce pro manipulaci se samotnou hrou, ověřování
vítězství jednoho hráče a podobné. Soubor `storage_utils.ex` zajišťuje rozhraní pro ukládání
stavů hry, momentálně do ETS.

O `storage_utils` je důležité podotknout, že do tvoří rozhraní pro ukládání her, ale nijak nepředepisuje implementaci. Pokud bychom například chtěli hry ukládat do relační databáze, pak je to určitě možné, jen zachováme API a změníme
implementaci na pozadí.

Složka `workers` obsahuje jediný soubor; `game_cleaner.ex`. To je modul, který se stará o periodické promazávání her,
jakmile jim uběhne doba života. Modul se spouští jako proces v `application.ex`.

Soubor `game.ex` pak v sobě má definici herního objektu a funkci pro jeho vytvoření spolu s funkcí pro generování id
jednotlivých uživatelů a hry,


### `piqs_web`
Modul `pisq_web` obsahuje komponenty přímo vztažené k zobrazování obsahu uživateli. Jeho rozložení je podobné libovolnému
webovému frameworku, který se drží vzoru Model-View-Controller. Ve složce `controllers` najdeme `page_controller.ex` pro hlavní stránku (nedělá příliš mnoho zajímavého, nepotřebuje v podstatě žádná dynamická data) a `game_controller.ex` pro administrátorskou stránku hry. V `game_controller.ex` se navíc vytváří nová hra.

Ve složce `live` se nachází soubor `user_live.ex`, ve které jsou informace o LiveView procesu, který má na starosti hru,
a také samotná živá šablona. Proces si u sebe udržuje základní stav hry, který potřebuje pro zobrazování uživateli, a pokud se stane něco zajímavého (update herní plochy, vítězství jedné strany...), pak se doptá na stav hry v ETS a zaktualizuje ho u sebe i u klienta. Dalo by se říci, že v tomto souboru je těžiště celé aplikace. Dalším souborem ve složce je `game_board_component.ex`, který obsahuje šablonu pro samotnou komponentu herní plochy.

V `templates` jsou šablony pro jednotlivé stránky. Ve `views` se pak nachází jednotlivá view, které jsou ale v základním stavu a neměnily se. Jsou zodpovědná za správné renderování šablon.

V `router.ex` jsou pak definice jednotlivých adres a to, které view se má zavolat, pokud se uživatel dotáže na danou cestu.

### Frontend
Aplikace používá CSS framework Bulma, jehož barevná schémata přejímá.

## Možná vylepšení
Aplikace rozhodně není dokonalá. Zde jsou nějaké nápady, kterými by se dala aplikace vylepšit v případě dalšího vývoje
  - hraní proti počítači
  - ukládání stavu do databáze
  - replay hry tah po tahu
