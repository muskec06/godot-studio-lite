# Godot Studio Lite

Godot 4 ile oyun yapmak için yalın bir Claude Code kurulumu. Tek kişi ya da
küçük bir ekip için tasarlandı: 11 agent, 15 komut, 7 hook, isteğe bağlı mobil
ve analitik profilleri, bulut CI. Görselleri Claude SVG olarak çizer ($0); ses ve
müzik fal.ai ile üretilir.

[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
reposundan ilham alır; onun en iyi fikirlerini (dosyada tutulan oturum durumu,
okuma bekçisi, "çalıştır ve bak" kuralı, Godot 4.5–4.7 API referansı) alıp
geri kalanını sadeleştirir.

## Neden daha yalın?

| | Claude Code Game Studios | Godot Studio Lite |
|---|---|---|
| Motor | Godot, Unity, Unreal | Yalnızca Godot 4 |
| Agent | 49 | 8 çekirdek + 2 opsiyonel |
| Komut (skill) | 74 | 14 + 1 referans skill'i |
| `.claude` markdown toplamı | ~3 MB | ~107 KB |
| Her oturumda yüklenen context | ~9k token | **~1.5k token** (`tools/selftest.sh` ölçer; MCP araç tanımları hariç) |
| Ayar | `rigor` + 6 alt ayar + yerel override zinciri | Tek ayar: `mode: jam \| project` |
| Python | Gerekli (yoksa sessizce varsayılana düşer) | Gerekmez; bash yeter, jq varsa kullanılır |
| Godot 3 sözdizimi kontrolü | Prompt metni | Her `.gd` yazımından sonra hook ile |

Komutların hepsi `disable-model-invocation: true` ile tanımlı: açıklamaları
context'e yüklenmez, yalnızca siz `/komut` yazınca devreye girer.

## Kurulum

Gerekenler: [Claude Code](https://code.claude.com/docs/en/overview),
[Godot 4.7](https://godotengine.org/download), bash (Windows'ta Git Bash),
git, curl. jq isteğe bağlı. Görsel/ses üretimi için kredi yüklenmiş bir
[fal.ai](https://fal.ai) hesabı.

1. Bu klasörü oyununuzun klasörü olarak kopyalayın, isterseniz `git init`.
2. Claude Code'u **bu klasörün kökünde** başlatın (`claude`). Alt klasörde
   başlatırsanız hook'lar ve izin kuralları yüklenmez.
3. Claude Code `.mcp.json` içindeki `fal` sunucusunu onaylamanızı ister;
   onaylayın. Sonra `/mcp` → `fal` → tarayıcıda giriş yapın. API anahtarı
   gerekmez, hiçbir dosyaya yazılmaz.
4. `/start` yazın: oyunun adını, modu, Godot'nun yolunu ve varlık bütçesini
   sorar, `game/project.godot` dosyasını oluşturur, yardımcı scriptleri kurar,
   isterseniz gdUnit4'ü indirir.

Kurulumu doğrulamak için: `bash tools/selftest.sh`

## Çalışma döngüsü

```
/brief → /art-style → /plan → ( [/asset] → /story → [/review] → /done )* → /playtest → /release
```

1. **`/brief`** — bir sayfalık oyun özeti: pillar'lar, core loop, kapsam ve
   özellikle **kapsam dışı** listesi.
2. **`/art-style`** — görsel stili bir kez sabitler: 4 konsept üretir, siz
   birini seçersiniz; o görsel, ondan çıkarılan palet ve stil prompt'u bundan
   sonraki her üretimde referans olur (~$0.4–0.8).
3. **`/plan`** — brief'i küçük, test edilebilir story'lere böler
   (`docs/backlog.md`). Her story gereken görsel ve sesleri `Assets:` satırında listeler.
4. **`/asset`** — story'nin varlıklarını maliyet tahmini ve onayınızla
   üretir. Atlanabilir: kod geçici placeholder'larla ilerler, gerçek dosya
   aynı yola gelince kod değişmeden yerine oturur.
5. **`/story`** — sıradaki story'yi `gdscript-dev` agent'ına verir. Agent ayrı
   context'te çalışır, ana oturum temiz kalır.
6. **`/review`** — `project` modunda zorunlu: salt okunur `reviewer` agent'ı
   değişikliği temiz bir gözle inceler.
7. **`/done`** — testleri çalıştırır, oyunu çalıştırıp ekran görüntüsü alır,
   kabul kriterlerini ve varlık kayıtlarını kontrol eder. Hepsi geçerse story kapanır.

## Modlar

| | `jam` (varsayılan) | `project` |
|---|---|---|
| Ne zaman | İlk oyun, game jam, < 4 hafta | Ticari ya da uzun proje |
| Review | İsteğe bağlı | Her story'de zorunlu |
| ADR | Gerekmez | Birden fazla sistemi etkileyen kararlarda |
| Test | İsteğe bağlı | Oyun mantığı için zorunlu |
| "Çalıştır ve bak" | Zorunlu | Zorunlu |

Mod `project.yaml` içinde `mode:` satırıyla değişir.

## Komutlar

| Komut | Ne yapar |
|---|---|
| `/start` | İlk kurulum |
| `/brief [fikir]` | Oyun özetini yazar ya da günceller |
| `/art-style [fikir]` | Görsel stili, paleti ve referans görselleri sabitler |
| `/asset [S-NNN \| açıklama]` | fal.ai ile görsel/ses üretir (önce maliyet + onay) |
| `/plan [özellik]` | Story'leri backlog'a ekler |
| `/story [S-NNN]` | Bir story'yi uygular |
| `/review [S-NNN]` | Bağımsız kod incelemesi |
| `/done [S-NNN]` | Doğrular ve kapatır |
| `/adr [soru]` | Teknik karar + kayıt (`docs/adr/`) |
| `/prototype [soru]` | `game/prototypes/` içinde atılacak deneme |
| `/playtest [notlar]` | Playtest gözlemlerini backlog'a dönüştürür |
| `/bug [açıklama]` | Hata kaydı + düzeltme story'si |
| `/scope [kalan süre]` | Neyin kesileceğini önerir |
| `/release [sürüm]` | Export ve sürüm kontrol listesi (yüklemez); mobilde Android/Play Console listesi |
| `/localize [setup\|extract\|translate\|check\|store]` | Metinleri anahtarlara taşır, eksik çevirileri doldurur, yer tutucu ve font kontrolü, mağaza metni |
| `/monetize` *(mobil profil)* | Reklam ve satın alma sağlayıcısını seçer, gerçek adaptörleri ve story'leri planlar |
| `/metrics [setup\|report\|provider]` *(analitik profili)* | Bölüm olaylarını oyuna bağlar, playtest loglarından bölüm hunisi çıkarır, ayar story'leri önerir |

## Agent'lar

| Agent | Görev | Model |
|---|---|---|
| `gdscript-dev` | Story'yi uygular: kod, sahne, test | oturum modeli |
| `reviewer` | Salt okunur kod incelemesi | sonnet |
| `architect` | Sistemler arası kararlar, ADR (kod yazmaz) | opus |
| `designer` | Mekanik, sayılar, denge (yalnızca `docs/`) | sonnet |
| `qa` | Test yazar, hata yeniden üretir | sonnet |
| `shader-vfx` | Shader, parçacık, görsel efekt | sonnet |
| `godot-docs` | Hızlı ve ucuz API doğrulama | haiku |
| `vector-artist` | Görselleri token'lardan SVG olarak çizer, önizlemeye bakar, derler ($0). Kod yazmaz | oturum modeli |
| `artist` | fal.ai ile ses efekti ve müzik; vektörün yetmediği görseller (ressamsı, fotoğrafik, piksel art). Kod yazmaz | sonnet |
| `writer` *(ops.)* | Diyalog, metin, lore | sonnet |
| `audio` *(ops.)* | Ses listesi, bus, mix (üretimi `artist` yapar) | sonnet |

Agent'lar kullanıcıyla doğrudan konuşmaz; sonucu sabit bir rapor formatında
ana oturuma döner. Belirsizlikte `BLOCKED: <soru>` dönerler, tahmin etmezler.

## Hook'lar

| Olay | Hook | İşlevi |
|---|---|---|
| Oturum başı | `session-start.sh` | Checkpoint'i ve aktif story'yi context'e ekler; eksik kurulumu bildirir |
| Compaction öncesi | `pre-compact.sh` | Compaction'ı durum günlüğüne yazar |
| Okuma öncesi | `read-guard.sh` | `docs/` ve `production/` içinde 40 KB üstü dosyanın tamamının okunmasını engeller, başlıkları döndürür |
| Yazma sonrası | `gd-check.sh` | `.gd` dosyalarında 17 Godot 3 kalıbını yakalar; Godot kuruluysa parse kontrolü yapar |
| fal çağrısı öncesi/sonrası | `fal-budget.sh` | Listede olmayan modeli ve bütçeyi aşacak çağrıyı engeller; her çağrıyı tahmini maliyetiyle `production/asset-ledger.tsv`'ye yazar |
| SVG yazma sonrası | `svg-guard.sh` | Godot'nun çizemediği SVG öğelerini (yazı, filtre, stil, animasyon, dış görsel) engeller; token dışı renklerde uyarır |
| Tur sonu | `session-stop.sh` | Story sürerken checkpoint 20 dakikadan eskiyse Claude'dan bir kez güncellemesini ister |

## Mobil profil

`/start` sırasında "mobil" seçilince ya da elle
`bash tools/apply-profile.sh mobile portrait` (veya `landscape`) ile açılır.
Masaüstü projelerine hiçbir şey eklemez; kural ve komutlar yalnızca bu
profil açıkken context'e girer.

| Ne eklenir | Ne işe yarar |
|---|---|
| Proje ayarları | 720×1280 dikey (ya da 1280×720 yatay), `expand` en-boy oranı (her telefonda tam ekran), Compatibility renderer, ETC2/ASTC doku sıkıştırma, fareyle dokunma emülasyonu, geri tuşunun oyunu kapatmaması |
| `App` autoload | Android geri tuşu, arka plana geçme/dönme sinyalleri (kayıt için), güvenli alan (çentik, hareket çubuğu), titreşim |
| `SafeAreaContainer` | HUD ve menüleri çentik/kenar altına girmekten korur |
| `Ads` ve `Purchases` autoload'ları | Reklam ve satın alma için tek giriş noktası; şimdilik **sahte (mock) altyapıyla** çalışır, böylece oyun editörde ve testlerde reklam ağı olmadan oynanır. Gerçek sağlayıcı `/monetize` ile arkasına takılır, oyun kodu değişmez |
| `AdsPolicy` | Geçiş reklamı kuralları: 5. bölümden önce yok, 3 bölümde bir, 60 sn arayla, "reklamları kaldır" alınınca hiç |
| gdUnit4 testleri | Reklam kuralları, ödüllü reklam, satın alma, geri yükleme, kalıcılık (15 test) |
| `.claude/rules/mobile.md` | Dokunma hedefi ≥ 48 px, güvenli alan, yaşam döngüsü, performans, metin boyutu, reklam yerleşimi kuralları |
| `/monetize` | AdMob ve Google Play Billing eklentilerini ADR ile seçer, kurulumda yönlendirir, gerçek API'yi eklentinin kendi dosyalarından öğrenip adaptör story'lerini planlar |
| `/done` ve `/release` | Dokunma/his story'leri için gerçek telefonda onay; Android export, keystore, ikonlar, gizlilik politikası, veri güvenliği formu, 12 test kullanıcısı × 14 gün kapalı test listesi |
| `artist` | Uygulama ikonu (192, 512, adaptif 432 ön/arka plan) ve mağaza görseli (1024×500) tarifleri |

`.gitignore` imza anahtarlarını (`*.keystore`, `*.jks`) ve `builds/` klasörünü
dışarıda tutar. Anahtarı kaybetmek uygulamayı güncelleyememek demektir:
yedekleyin, repoya koymayın.

## Vektör varlıklar (Claude çizer, $0)

Düz, illüstrasyon ya da geometrik bir stilde görseller Claude tarafından SVG
olarak çizilir; Godot SVG'yi doğrudan içe aktarır.

- **Tasarım token'ları** (`game/assets/_style/tokens.json`): bütün renkler tek
  dosyada. Şablonlar (`game/assets/_src/**/*.svg.tpl`) renkleri `{{token}}`
  olarak kullanır.
- **`bash tools/svg-build.sh`:** şablonları `game/assets/` altındaki SVG'lere
  derler, kontrol eder, ASSETS.md'ye `claude-vector` olarak yazar ve aynı
  renklerden `DesignTokens` GDScript sınıfını üretir. Bir rengi değiştirip
  yeniden derlemek bütün görselleri ve koddaki renkleri günceller.
- **`bash tools/svg-check.sh`** ve **`svg-guard` hook'u:** Godot'nun SVG
  motorunun (ThorVG) çizemediklerini engeller: `<text>`, filtreler, `<style>`,
  animasyon, dış görseller. Yazı ya Godot'da Label ile çizilir ya da (logo
  gibi) yola çevrilir.
- **`bash tools/svg-render.sh <svg> [png] [genişlik]`:** Godot'nun kendi SVG
  motoruyla PNG üretir. Claude önizlemeye bakar; mağaza ikonları da buradan çıkar.
- **`bash tools/build-theme.sh`:** token'lardan Godot teması (buton, panel,
  etiket); **`bash tools/install-fonts.sh`:** Baloo 2 ve Rubik (SIL OFL).
- `/asset` her varlık için yolu seçer: **vektör** ($0, varsayılan), **kod**
  (tema, shader, parçacık, Tween) ya da **fal** (ses, müzik, ressamsı/gerçekçi görsel).

### Çay Ocağı sanat kiti (`cay-ocagi-art`)

Tanıtım videosunun çizim kodundan birebir çevrildi:
`bash tools/apply-profile.sh cay-ocagi-art && bash tools/svg-build.sh`

| Grup | İçerik |
|---|---|
| Bardak | arka ton, sıvı maskesi, silindir gölgesi, ön kontur/parlama, tabak (aynı tuvalde, üst üste hizalı) |
| Semboller | 8 renk körü sembolü (yaprak, damla, çiçek, dal, kalp, elma, yıldız, çekirdek); beyaz çizilir, Godot'da renklenir |
| Dekor | semaver + demlik, küp şeker, buhar kıvrımı |
| Arayüz | geri al, +1 bardak, göz ikonları; çini şeridi; öğretici el |
| Arka plan | kafe tezgâhı 720×1600 |
| Marka | logo (Baloo 2'den yola çevrilmiş), uygulama ikonu 512, uyarlanabilir ikon 432 ön/arka plan, mağaza görseli 1024×500 |
| Kod | `GlassView`: bardağı katmanlarıyla kurar, sıvıyı bardağa kırpar, eğilince sıvıyı yatay tutar, renk körü sembollerini gösterir (gdUnit4 testleriyle) |
| Doküman | `docs/art-style.md` (renkler, ölçüler, kurallar), `docs/motion-recipes.md` (videodaki dökme, demlenme, buhar, şeker yağmuru zamanlamalarının Tween karşılıkları ve videodaki doğrulanmış bölümler) |

## Görsel ve ses üretimi (fal.ai)

| Varlık | Model | Fiyat (5 Kas 2026) | Ne kadar iyi |
|---|---|---|---|
| Karakter, obje, ikon, UI parçası | `fal-ai/nano-banana-2/edit` + stil referansları | $0.08 / görsel | İyi |
| Kritik görseller | `fal-ai/nano-banana-pro/edit` | $0.15 / görsel | İyi |
| Arka plan, parallax katmanı | `fal-ai/nano-banana-2` | $0.08 (2K: ×1.5) | İyi |
| Şeffaf arka plan | `fal-ai/bria/background/remove` | $0.018 / görsel | İyi |
| Animasyon kareleri (2–4) | Görsel modeli + temel sprite referansı | görsel başına | Zayıf: gözle kontrol |
| Tile | Görsel modeli | görsel başına | Deneysel: kenarları kontrol |
| Ses efekti | `fal-ai/elevenlabs/sound-effects/v2` | $0.002 / saniye | İyi |
| Döngü müziği | `fal-ai/minimax-music/v2.6` | $0.15 / parça | İyi; döngü geçişini dinleyin |
| Uzun müzik | `fal-ai/elevenlabs/music` | ~$0.6–0.8 / dakika | İyi |

- **Kurallar kodla uygulanır.** İzinli modeller `tools/fal-models.tsv`
  dosyasında; hepsi fal sayfasında "Commercial use" etiketli. Listede olmayan
  model ve `asset_budget_usd` sınırını aşacak çağrı hook tarafından engellenir.
  Ücretli çağrılar izin listesinde değildir: Claude Code her birinden önce sorar.
- **Piksel art işleme Godot ile yapılır** (`tools/godot/image_tool.gd`):
  kırpma, alan ortalamasıyla küçültme, sert alfa, palete indirgeme, paleti
  stil görselinden çıkarma, sprite sheet bölme. Python veya ImageMagick gerekmez.
- **Her dosyanın kaydı tutulur.** `tools/import-asset.sh` dosyayı indirir,
  orijinalini `game/assets/_raw/` içinde saklar (yeniden işlemek ücretsizdir),
  `game/assets/ASSETS.md` dosyasına model, prompt ve maliyet satırı yazar.
- **Harcama:** `bash tools/fal-cost.sh` (tahmini; gerçek fatura
  [fal.ai/dashboard/usage](https://fal.ai/dashboard/usage) üzerindedir).
- fal çıktıları sunucuda ~7 gün tutulur ve bu sürede linki bilen erişebilir;
  araç bu yüzden her çıktıyı hemen indirir.
- Mağazalar (ör. Steam) yapay zekâ ile üretilmiş içeriği beyan etmenizi
  ister; `/release` ASSETS.md'den bu beyanı taslak olarak hazırlar.

## Analitik (profil)

`bash tools/apply-profile.sh analytics` ya da `/metrics setup`.

- **`Analytics` autoload'ı:** `level_started / level_completed / level_failed`
  ve serbest `event()` çağrıları. Debug sürümlerde her oturum
  `user://analytics/` altına bir JSON-lines dosyası yazar; uzak sunucu yoktur.
  Rastgele bir kurulum kimliği dışında kişisel veri tutmaz, ayarlardan
  kapatılabilir. Mobil profil yüklüyse reklam ve satın almalar da otomatik
  olarak kaydedilir.
- **`bash tools/funnel.sh <klasör>`:** playtest loglarından bölüm hunisi:
  her bölümde kaç oyuncu başladı ve bitirdi, tamamlama oranı, ortalama
  süre, oyuncu başına başarısızlık ve ilk bölümden bu bölüme ulaşma oranı.
- **`/metrics report`:** tabloyu okur, zorluk sıçramalarını ve en büyük
  kaybı sayılarla gösterir, değiştirilecek değeri adıyla söyleyen ayar
  story'leri önerir. `/metrics provider` ileride GameAnalytics/Firebase
  gibi uzak bir servisi aynı arayüzün arkasına bağlar.

## Bulut CI (GitHub Actions)

Klasör bir GitHub reposuna gönderildiğinde kendiliğinden çalışır; kendi
bilgisayarınızın açık olması gerekmez.

| İş akışı | Ne zaman | Ne yapar |
|---|---|---|
| `ci.yml` | Her push ve pull request | Self-test, yerelleştirme kontrolü; `game/project.godot` varsa Godot 4.7.2'yi indirir, projeyi içe aktarır, **tüm scriptleri parse eder**, gdUnit4 testlerini koşar, hata olursa logları ekler |
| `android.yml` | Elle (Actions → Run workflow) ve `v*` etiketlerinde | Export şablonlarıyla Android debug build'i; `ANDROID_KEYSTORE_*` secret'ları varsa imzalı release build'i. Çıktılar indirilebilir artifact olur |

- Godot sürümü iş akışlarındaki `GODOT_VERSION` satırında; kullandığınız
  sürümle aynı tutun.
- `android.yml` deneysel: commit edilmiş bir `game/export_presets.cfg`
  ister. Godot şifreleri ayrı bir dosyada tuttuğu için bu dosyayı commit
  etmek güvenli. İlk çalıştırmanın logunu birlikte kontrol edelim.
- GitHub'ın ücretsiz planında özel repolar için aylık bir dakika kotası var;
  Android build'lerini bu yüzden elle tetiklenir yaptım.
- Yerelde aynı kontroller: `bash tools/parse-all.sh`, `bash tools/run-tests.sh`.

## Erişilebilirlik

- **`.claude/rules/accessibility.md`:** renk tek başına bilgi taşımaz,
  metin boyutu ve kontrast, yanıp sönme sınırı, hızlı dokunma zorunluluğu
  yok, her önemli sesin görsel karşılığı var, ve her oyunda bir ayarlar
  ekranı (renk körü modu, metin boyutu, hareketi azalt, titreşim, ses).
- **`bash tools/colorblind.sh palette`:** oyun renklerinden
  (`_style/gameplay_colors.hex`) hangi çiftlerin protanopi, döteranopi ya
  da tritanopide birbirine karıştığını ΔE değeriyle listeler.
- **`bash tools/colorblind.sh image <ekran.png>`:** ekran görüntüsünün üç
  renk körlüğü simülasyonunu üretir (Machado 2009); `/done` bunlara bakar.
- `/art-style` oyun renklerini bu kontrolden geçirir, `/plan` ilk planına
  ayarlar story'sini ekler, `/done` her görsel story'de kontrol yapar.

## Yerelleştirme

- Metinler tek bir CSV'de: `game/locale/strings.csv` (`keys,en,tr`). Dil
  listesi `project.yaml` içindeki `languages` satırında; varsayılan
  İngilizce + Türkçe, ilk dil kaynak dil.
- **`bash tools/l10n.sh setup`:** CSV'yi oluşturur, çevirileri Godot'ya
  kaydeder. **`bash tools/l10n.sh check`:** eksik dil sütunu, boş hücre,
  diller arası yer tutucu (`%d`, `{name}`) uyuşmazlığı, kodda kullanılıp
  CSV'de olmayan anahtar, sabit yazılmış metin. CI bunu her push'ta çalıştırır.
- **`/localize`:** sabit metinleri anahtara taşır, eksik çevirileri `writer`
  ile doldurur (Türkçe için sen/siz, İ/ı kuralları), font ve taşma
  kontrolü yapar, mağaza metnini iki dilde yazar.

## Dosya yapısı

```
CLAUDE.md               Claude'un her oturumda okuduğu kurallar (< 80 satır)
project.yaml            Sürüm, mod, test aracı, Godot yolu, sanat stili, varlık bütçesi
.mcp.json               fal.ai MCP sunucusu (OAuth; anahtar içermez)
docs/art-style.md       Stil prompt'u, boyutlar, palet, referanslar
docs/brief.md           Oyun özeti
docs/backlog.md         Tüm story'ler ve durumları
docs/adr/               Mimari kararlar
docs/playtests/         Playtest notları
production/state.md     Oturum checkpoint'i (Claude'un hafızası)
production/evidence/    Story kapanış ekran görüntüleri
production/asset-ledger.tsv  Her fal çağrısı ve tahmini maliyeti
game/                   Godot projesi (scenes, scripts, tests, addons)
game/assets/            sprites, ui, backgrounds, tiles, sfx, music, _style, _raw
game/assets/ASSETS.md   Her varlığın kaynağı, prompt'u, maliyeti
tools/                  Kurulum, test, ekran görüntüsü, varlık, selftest scriptleri
tools/fal-models.tsv    İzinli fal modelleri ve fiyatları
tools/profiles/mobile/  Mobil profil (apply-profile.sh ile kurulur)
tools/profiles/analytics/  Analitik profili
tools/profiles/cay-ocagi-art/  Çay Ocağı sanat kiti (SVG şablonları, token'lar, GlassView)
game/assets/_style/tokens.json  Tasarım token'ları (renkler)
game/assets/_src/       Vektör şablonları (*.svg.tpl); derlenmiş SVG'ler game/assets/ altında
game/locale/strings.csv Tüm diller için oyuncuya görünen metinler
.github/workflows/      Bulut CI: ci.yml (testler), android.yml (build)
```

## Bağlam (context) yönetimi

- **Hafıza dosyadadır, sohbette değil.** `production/state.md` içindeki
  CHECKPOINT bloğu her story ve kararda üzerine yazılır; her yeni oturumda ve
  compaction sonrasında otomatik yüklenir. `/clear` korkusuz kullanılabilir.
- **Bir story = bir agent context'i.** Uygulama ayrı context'te yapılır; ana
  oturum yalnızca seçer, doğrular ve kaydeder.
- **Kurallar yalnızca gerektiğinde yüklenir.** `.claude/rules/` dosyaları
  `paths:` ile kapsamlıdır; örneğin test kuralları yalnızca `game/tests/` ile
  çalışılırken yüklenir. Godot API referansı da `.gd`/`.tscn` dosyalarıyla
  çalışılırken devreye girer.

## Bilinen sınırlar

- Godot'ya bağlı scriptler (`parse_check.gd`, `screenshot.gd`,
  `run-tests.sh`, `setup-godot.sh`) Godot 4.7 için yazıldı; ilk kullanımda
  çıktılarını kontrol edin. Hook'lar ve selftest otomatik test edilmiştir.
- `screenshot.sh` ekranı olan bir bilgisayar ister; sunucuda çalışmaz ve
  `/done` bu durumda ekran görüntüsünü sizden ister.
- Export presetleri ve imzalama ayarlarını Claude yazmaz; `/release` sizi
  yönlendirir.
- C# desteklenir ama Godot 3 kontrolü ve referans GDScript odaklıdır.
- fal entegrasyonu canlı bir hesapla denenmedi. Bütçe hook'u ve içe aktarma
  script'i test edildi; ilk `/art-style` çalıştırmasında MCP araç adlarını ve
  çıktıları kontrol edin. fal MCP aracının parametre adları değişirse bütçe
  tahmini adet/süreyi okuyamayabilir (o durumda tek görsel / 10 saniye varsayar).
- `image_tool.gd` gerçek Godot ile çalıştırılmadı; ilk kullanımda çıktısına bakın.
- Mobil profildeki GDScript dosyaları ve testleri Godot'da çalıştırılmadı
  (Godot 3 kontrolünden geçti, ayar adları Godot 4.7 kaynak dokümanından
  doğrulandı). Profili uyguladıktan sonra ilk iş `bash tools/run-tests.sh`.
- Sanat kitinin SVG'leri tarayıcıda render edilip gözle kontrol edildi;
  Godot'nun SVG motoru (ThorVG) aynı alt kümeyi destekliyor ama ilk
  derlemede `tools/svg-render.sh` ile bir kez bakın. `GlassView`,
  `build_theme.gd` ve `image_tool svg` Godot ile çalıştırılmadı.
- Analitik scriptleri, renk körlüğü araçları ve CI'daki Godot adımları da
  Godot ile çalıştırılmadı; CI'ın ilk çalıştırması bunları gerçek Godot
  4.7.2 üzerinde sınar. `funnel.sh`, `l10n.sh` ve profil kurulumu test edildi.
- Gerçek reklam ve satın alma adaptörleri hazır gelmez: eklentilerin API'si
  sürümden sürüme değiştiği için `/monetize` bunları kurulu eklentinin kendi
  dosyalarına bakarak yazdırır. iOS henüz kapsanmıyor.
- Fiyatlar değişir: `artist` her toplu üretimden önce fal'dan güncel fiyatı
  sorar ve `tools/fal-models.tsv`'yi günceller.

## Lisans

MIT. `.claude/skills/godot-api/` ve `tools/godot/parse_check.gd`, Claude Code
Game Studios'tan (MIT, © 2026 Donchitos) uyarlanmıştır. fal.ai ile üretilen
varlıkların kullanımı her modelin kendi lisansına ve
[fal.ai kullanım şartlarına](https://fal.ai/legal/terms-of-service) tabidir. Sanat kitindeki logo
yazısı Baloo 2 (SIL Open Font License 1.1) harflerinden yola çevrilmiştir.
