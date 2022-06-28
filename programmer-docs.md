# Pisq
Pisq je webová aplikace pro hraní piškvorek. Je napsána v jazyce Elixir ve frameworku Phoenix.

## Volba jazyka a nástrojů
Pro aplikaci jsem volil jazyk Elixir. Elixir je velmi příjemný pro psaní webových aplikací,
protože má k dispozici Erlangovský VM a nástroje z Erlangovského ekosystému, z nichž se některé mimořádně hodí.
(například práci s procesy a Erlang Term Storage, ale o tom dále).

Phoenix je pak framework pro psaní webových aplikací v Elixiru. Ve většině věcech se chová velmi podobně jako
například Django. Navíc nabízí LiveView, což je integrovaný způsob provázání frontendu a backendu.

### o LiveView
Zde se asi hodí něco napsat o LiveView a jeho fungování. Když na "živou" stránku přijde request,
zavolá se nejdříve funkce `mount` na serveru (u nás v souboru `user_live.ex`). Data z ní se dodají
do šablony a ta se pošle na klienta. Následně se spustí live proces na serveru. Klient se s tímto
procesem propojí WebSocketem. Následně si přes tento WebSocket posílají informace a diffy o tom, co se změnilo.
Více je k nalezení na v [dokumentaci](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) frameworku Phoenix.

## Základní principy
Celá aplikace je postavena velmi jednoduše. Na hlavní stránku přijde uživatel a založí si hru.
V té chvíli se vytvoří pro hru objekt, který ji bude popisovat, a ten se uloží. Uživatel dostane
3 odkazy; jeden pro hráče za křížky, druhý pro hráče za kolečka a třetí pro pozorovatele.
Každý odkaz je ve tvaru `DOMÉNA/play/id`, kde `id` jsou generována náhodně podle v podstatě libovolného
vzoru (momentálně to jsou dostatečně velká náhodná čísla). Odkaz hráče, za kterého chce hrát, si ponechá,
další přepošle protihráči/pozorovatelům. Pak se může přesunout do herního rozhraní, kde už vidí herní plochu.

Jakmile se uživatel přesune na herní plochu, Phoenix vytvoří proces pro LiveView. Ten si udržuje stav a reaguje
na vstupy z frontendu. V jeho stavu je například to, co je na herní ploše, jestli už někdo vyhrál nebo jestli
je hráč aktuálně na tahu. Takový proces existuje separátně pro každého uživatele, stav sdílí pomocí Erlang Term Storage,
což je in-memory databáze, která je navržena pro využití několika procesy současně.

Hra skončí, jakmile jeden z hráčů položí 5 křížků nebo 5 koleček v řadě. Vítězství se kontroluje při každém tahu
kontrolou všech možných nových řad pěti symbolů, které procházejí právě položeným symbolem.

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

O `storage_utils` je důležité podotknout, že do budoucna tvoří rozhraní pro ukládání her, ale nijak nepředepisuje implementaci. Pokud bychom například chtěli hry ukládat do databáze, pak je to určitě možné, jen zachováme API a změníme
implementaci na pozadí.

Soubor `game.ex` pak v sobě má definici herního objektu a funkci pro jeho vytvoření spolu s funkcí pro generování id
jednotlivých uživatelů a hry,

### `piqs_web`
Modul `pisq_web` obsahuje komponenty přímo vztažené k zobrazování obsahu uživateli. Jeho rozložení je podobné libovolnému
webovému frameworku, který se drží vzoru Model-View-Controller. Ve složce `controllers` najdeme `page_controller.ex` pro hlavní stránku (nedělá příliš mnoho zajímavého, nepotřebuje v podstatě žádná dynamická data) a `game_controller.ex` pro administrátorskou stránku hry. V `game_controller.ex` se navíc vytváří nová hra.

Ve složce `live` se nachází soubor `user_live.ex`, ve které jsou informace o LiveView procesu, který má na starosti hru,
a také samotná živá šablona. Proces si u sebe udržuje základní stav hry, který potřebuje pro zobrazování uživateli, a pokud se stane něco zajímavého
(update herní plochy, vítězství jedné strany...), pak se doptá na stav hry a zaktualizuje ho u sebe i u klienta. Dalo by se říci, že v tomto
souboru je těžiště celé aplikace. Dalším souborem ve složce je `game_board_component.ex`, který obsahuje šablonu pro samotnou komponentu herní plochy.

V `templates` jsou šablony pro jednotlivé stránky. Ve `views` se pak nachází jednotlivá view, které jsou ale v základním stavu a neměnily se. Jsou zodpovědná za správné renderování šablon.

V `router.ex` jsou pak definice jednotlivých adres a to, které view se má zavolat, pokud se uživatel dotáže na danou cestu.

### Frontend
Aplikace používá CSS framework Bulma, jehož barevná schémata přejímá.

## Možná vylepšení
Aplikace rozhodně není dokonalá. Zde jsou nějaké nápady, kterými by se dala aplikace vylepšit v případě dalšího vývoje
  - hraní proti počítači
  - ukládání stavu do databáze
  - replay hry
