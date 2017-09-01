---
vim: wrap linebreak nolist formatoptions-=t spelllang=cs
---

Vývoj paralelních programů přináší mnoho problémů.
Důvodem je, že vyžaduje rozvažování nad interakcemi vláken a bezpečností komunikace.
Testování v tomto případě příliš nepomáhá, protože není dostatečně silné na odhalení chyb závislých na plánováním procesů.
Situace je dále komplikována moderním hardware, který používá relaxovanou paměť: instrukce mohou být přeuspořádány a operace s pamětí mohou být pozdrženy vlivem cache pamětí.
Následkem je, že obecně používaný a přirozený náhled na paralelizmus jakožto na prokládání vláken není dostatečný.
Přesto je tento model používán nejen programátory ale i mnohými nástroji na analýzu programů.
Další komplikaci představuje to, že různý hardware používá různé paměťové modely a tedy má jiné možnosti přeuspořádávání instrukcí.

Tyto teze dizertační práce se proto zaměřují na problém analýzy paralelních programů běžících na procesorech s relaxovaným paměťovým modelem.
V prvních částech je prezentován souhrn existujících popisů paměťových modelů a přístupů k analýze programů zohledňující paměťové modely.
Práce dále popisuje mé cíle pro doktorské studium, které spočívají v navržení metod pro efektivní analýzu programů v programovacích jazycích C a C++ běžících na hardware s relaxovaným paměťovým modelem.
Navržené techniky by měly být použitelné pro jednotkové testování paralelních synchronizačních primitiv, datových struktura a algoritmů.
Všechny techniky by také měly být implementovány v nástroji DIVINE.
Závěrem práce shrnuje mé dosavadní výsledky.
