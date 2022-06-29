# Pisq
## Jak aplikaci používat:
Demo je k nalezení na adrese [pisq.kmjec.cz](https://pisq.kmjec.cz). Veškeré informace pro uživatele
jsou k nalezení tam.

## Jak aplikaci lokálně spustit:
  * Stáhněte závislosti pomocí `mix deps.get`
  * Zažádejte o klíče k reCaptche u Googlu (potřeba zadat mezi povolené domény i `localhost`), backendový secret uložte v shellu do `RECAPTCHA_SECRET`, sitekey do `RECAPTCHA_SITEKEY`
  * Spusťte aplikaci pomocí `mix phx.server`

Na adrese [`localhost:4000`](http://localhost:4000) pak poběží aplikace.


## Další odkazy
  * Oficiální stránka Phoenixu: https://www.phoenixframework.org/
  * Github Phoenixu: https://github.com/phoenixframework/phoenix
