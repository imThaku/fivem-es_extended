# fivem-es_extended
FiveM Essential Extended

![screenshot](http://gta-metropolis.ml/Files/Image/Acceuil.jpg)

You need essentialmode and es_admin activated

Add support for accounts (bank / black money) you can also add others accounts

Add support for inventory (press F5 ingame) => Players can now remove items from inventory

Add support for jobs

Loadouts are saved in database and restored on spawn

Positions are saved in database and restored on spawn

Wiki => https://github.com/indilo53/fivem-es_extended/wiki

--- INSTALL ---

Make sure you have essentialmode and es_admin loaded before es_extended

1) Import es_extended.sql in your database
2) Copy folders in cfx-server/ressources

Since commit https://github.com/indilo53/fivem-es_extended/commit/12b16323c5ebd4226aa518ac3953b4c94e94e332 you have to add a 'name' column default to '' (empty string)

if you are juste installing es_extended from scratch you can skip this step, it is included in es_extended.sql

```
ALTER TABLE `users` 

ADD COLUMN `name` VARCHAR(255) NULL DEFAULT '' AFTER `money`;
```

--- Additionnal notes --

You can add other types of accounts in es_extended/config.lua
You have to add account icons in html/img/accounts

SCRIPT NOT COMPATIBLE WITH [Pole-emploi] because it conflicts with some SQL columns

ALL SCRIPT RELATED TO ES_EXTENDED ARE IN ALPHA VERSION AND NEED MORE TESTING

PLEASE REPORT ANY BUG => OPEN ISSUE ON GITHUB
