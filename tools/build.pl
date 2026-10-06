#!/usr/bin/env perl
# Генератор статических страниц сайта ГРЕЙТ ТАЙ СПА.
# Запуск из корня проекта:  perl tools/build.pl
# Читает data/*.json и data/pages/*.html, пишет *.html в корень.
use strict; use warnings; use utf8;
use JSON::PP; use File::Basename; use Cwd qw(abs_path);
binmode STDOUT, ':encoding(UTF-8)';

my $ROOT = dirname(dirname(abs_path($0)));
chdir $ROOT or die;

sub slurp { my $p = shift; open my $f, '<:encoding(UTF-8)', $p or die "$p: $!"; local $/; my $s = <$f>; close $f; $s }
sub spit  { my ($p, $s) = @_; open my $f, '>:encoding(UTF-8)', $p or die "$p: $!"; print $f $s; close $f; print "  → $p\n" }
sub json  { JSON::PP->new->utf8(0)->decode(slurp(shift)) }
sub esc   { my $s = shift // ''; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g; $s }
sub attr  { esc(shift) }
sub nl2br { my $s = esc(shift); $s =~ s/\r//g; $s =~ s/\n+/<br>/g; $s }
sub tidy  { my $s = shift // ''; $s =~ s/\r//g; $s =~ s/[ \t]+/ /g; $s =~ s/ *\n */\n/g; $s =~ s/\n{2,}/\n/g; $s =~ s/^\s+|\s+$//g; $s }

my $promos   = json('data/promos.json');
my $price    = json('data/price.json');
my $masters  = json('data/masters.json');
my $gallery  = json('data/gallery.json');
my $articles = json('data/articles.json');

# ------------------------------------------------------------------ константы
my %SITE = (
  name    => 'ГРЕЙТ ТАЙ СПА',
  city    => 'Пенза',
  email   => 'spa58spa@yandex.ru',
  vk      => 'https://vk.com/great_thai_spa',
  inst    => 'https://www.instagram.com/grand_thai_penza',
  yclients=> 'https://o3509.yclients.ru/',
  # три метки: Лозицкой, Кижеватова, Пушкина (координаты с текущего сайта)
  map     => 'https://yandex.ru/map-widget/v1/?lang=ru_RU&ll=44.98,53.196&z=12&pt=44.948472,53.224147,pm2dom~44.981162,53.165982,pm2dom~45.007412,53.196687,pm2dom',
);
my @PHONES = (
  { show => '+7 (960) 328-78-78', tel => '+79603287878', lbl => 'Мобильный' },
  { show => '39-20-30',           tel => '+78412392030', lbl => 'Городской' },
  { show => '31-00-03',           tel => '+78412310003', lbl => 'Городской' },
);
my @BRANCHES = (
  { id => 'kizhevatova', name => 'Кижеватова', addr => 'ул. Кижеватова, д. 21', note => 'вход с торца справа', ip => 'ИП Ширикова М.Н.',   map => 'https://yandex.ru/maps/?pt=44.981162,53.165982&z=17&l=map' },
  { id => 'lozickoy',    name => 'Лозицкой',   addr => 'ул. Лозицкой, д. 6',    note => '1 этаж',              ip => 'ИП Ширикова М.Н.',   map => 'https://yandex.ru/maps/?pt=44.948472,53.224147&z=17&l=map' },
  { id => 'pushkina',    name => 'Пушкина',    addr => 'ул. Пушкина, д. 11',    note => 'вход с торца слева',  ip => 'ИП Курченкова О.А.', map => 'https://yandex.ru/maps/?pt=45.007412,53.196687&z=17&l=map' },
);
my %BRANCH_BY_NAME = map { $_->{name} => $_ } @BRANCHES;
my @NAV = (
  ['about.html',        'О нас'],
  ['price.html',        'Прайс'],
  ['masters.html',      'Мастера'],
  ['certificates.html', 'Сертификаты'],
  [$SITE{yclients},     'Эл. сертификаты', 1],
  ['contacts.html',     'Контакты'],
  ['articles.html',     'Статьи'],
  ['franchise.html',    'Франшиза'],
);
my @HERO = (
  { img => 'njqb38jnnxm5bxdfta362lpzl1i7nob2.jpg', cap => 'ГРЕЙТ ТАЙ СПА — это место, где стоит оказаться!' },
  { img => 'y7cawxhd1nhq0hkeokc2pn0pv6otel40.jpg', cap => 'Погрузитесь в гостеприимную и уютную атмосферу Королевства Таиланд' },
  { img => 'nghhhri3uv7561w2pfrc1vyl9idvy6bp.jpg', cap => 'Ощутите на себе неповторимый эффект уникальных тайских техник' },
  { img => 'b2w7ikykbwzftqz0hquymowl236d1ku3.jpg', cap => 'Добро пожаловать в восхитительный мир гармонии и блаженства' },
);

# ------------------------------------------------------------------ иконки
my %I = (
  phone => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/></svg>',
  pin   => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>',
  arrow => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>',
  check => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>',
  gift  => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 12v10H4V12"/><path d="M2 7h20v5H2z"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>',
  percent=> '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M19 5 5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/></svg>',
  lotus => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21c-4 0-9-3-9-8 3 0 5 1 6.5 3C8 12 9 7 12 3c3 4 4 9 2.5 13C16 14 18 13 21 13c0 5-5 8-9 8z"/><path d="M12 21c-2-2-3-5-3-8"/><path d="M12 21c2-2 3-5 3-8"/></svg>',
  award => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="9" r="6"/><path d="M8.5 14 7 22l5-3 5 3-1.5-8"/></svg>',
  crown => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="m3 8 4 4 5-7 5 7 4-4-2 11H5z"/><path d="M5 21h14"/></svg>',
  vk    => '<svg viewBox="0 0 24 24"><path d="M13.2 18.6c-6.6 0-10.4-4.5-10.5-12h3.3c.1 5.5 2.5 7.8 4.4 8.3V6.6h3.1v4.7c1.9-.2 3.9-2.3 4.6-4.7h3.1c-.5 2.9-2.7 5.1-4.2 6 1.5.7 4 2.6 4.9 6h-3.4c-.7-2.3-2.6-4.1-5-4.3v4.3h-.3z"/></svg>',
  inst  => '<svg viewBox="0 0 24 24"><path d="M12 2.2c3.2 0 3.6 0 4.8.1 1.2.1 1.8.2 2.2.4.6.2 1 .5 1.4.9.4.4.7.8.9 1.4.2.4.4 1 .4 2.2.1 1.3.1 1.6.1 4.8s0 3.6-.1 4.8c-.1 1.2-.2 1.8-.4 2.2-.2.6-.5 1-.9 1.4-.4.4-.8.7-1.4.9-.4.2-1 .4-2.2.4-1.3.1-1.6.1-4.8.1s-3.6 0-4.8-.1c-1.2-.1-1.8-.2-2.2-.4-.6-.2-1-.5-1.4-.9-.4-.4-.7-.8-.9-1.4-.2-.4-.4-1-.4-2.2-.1-1.3-.1-1.6-.1-4.8s0-3.6.1-4.8c.1-1.2.2-1.8.4-2.2.2-.6.5-1 .9-1.4.4-.4.8-.7 1.4-.9.4-.2 1-.4 2.2-.4 1.3-.1 1.6-.1 4.8-.1M12 0C8.7 0 8.3 0 7.1.1 5.8.1 4.9.3 4.1.6c-.8.3-1.5.7-2.1 1.4C1.3 2.6.9 3.3.6 4.1.3 4.9.1 5.8.1 7.1 0 8.3 0 8.7 0 12s0 3.7.1 4.9c.1 1.3.3 2.2.6 2.9.3.8.7 1.5 1.4 2.1.7.7 1.3 1.1 2.1 1.4.8.3 1.6.5 2.9.6 1.2.1 1.6.1 4.9.1s3.7 0 4.9-.1c1.3-.1 2.2-.3 2.9-.6.8-.3 1.5-.7 2.1-1.4.7-.7 1.1-1.3 1.4-2.1.3-.8.5-1.6.6-2.9.1-1.2.1-1.6.1-4.9s0-3.7-.1-4.9c-.1-1.3-.3-2.2-.6-2.9-.3-.8-.7-1.5-1.4-2.1-.7-.7-1.3-1.1-2.1-1.4-.8-.3-1.6-.5-2.9-.6C15.7 0 15.3 0 12 0zm0 5.8a6.2 6.2 0 1 0 0 12.4 6.2 6.2 0 0 0 0-12.4zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.4-11.8a1.4 1.4 0 1 0 0 2.9 1.4 1.4 0 0 0 0-2.9z"/></svg>',
  mail  => '<svg viewBox="0 0 24 24"><path d="M20 4H4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2zm-.4 2L12 11.6 4.4 6h15.2zM4 18V7.9l8 6 8-6V18H4z"/></svg>',
);

# ------------------------------------------------------------------ общие блоки
sub header_html {
  my ($active) = @_;
  my $nav = join '', map {
    my ($href, $label, $ext) = @$_;
    my $cls = ($active && $href eq $active) ? ' class="is-active"' : '';
    my $extra = $ext ? ' target="_blank" rel="noopener"' : '';
    qq{<a href="$href"$cls$extra>$label</a>}
  } @NAV;
  my $opts = join '', map { qq{<option value="$_->{id}">$_->{name}</option>} } @BRANCHES;
  my $sel = qq{<div class="branch"><select data-branch-select aria-label="Филиал"><option value="">Все филиалы</option>$opts</select></div>};
  my $p = $PHONES[0];
  return <<HTML;
<div class="notice">Уважаемые гости! Сеть центров тайского SPA «ГРЕЙТ ТАЙ СПА» не предоставляет медицинских услуг.</div>
<header class="header">
  <div class="wrap header__in">
    <a href="index.html" class="logo" aria-label="$SITE{name}"><img src="assets/img/logo.png" alt="$SITE{name}"></a>
    <nav class="nav" aria-label="Основное меню">$nav</nav>
    <div class="header__right">
      $sel
      <a class="header__phone" href="tel:$p->{tel}">$I{phone}<span>$p->{show}</span></a>
      <a class="btn btn--primary btn--sm" href="#" data-book>Записаться</a>
      <button class="burger" data-menu-open aria-label="Открыть меню"><span></span></button>
    </div>
  </div>
</header>
<div class="mobile-menu" aria-hidden="true">
  <div class="mobile-menu__top">
    <a href="index.html" class="logo"><img src="assets/img/logo.png" alt="$SITE{name}"></a>
    <button class="close-x" data-menu-close aria-label="Закрыть меню">✕</button>
  </div>
  <nav>$nav</nav>
  <div class="mobile-menu__contacts">
    $sel
    @{[ join '', map { qq{<a href="tel:$_->{tel}">$_->{show}</a>} } @PHONES ]}
    <a class="btn btn--primary" href="#" data-book data-menu-close>Записаться</a>
  </div>
</div>
HTML
}

sub footer_html {
  my $nav = join '', map { my ($h,$l,$e)=@$_; my $x=$e?' target="_blank" rel="noopener"':''; qq{<li><a href="$h"$x>$l</a></li>} } @NAV;
  my $addr = join '', map { qq{<li>$_->{addr}</li>} } @BRANCHES;
  my $ph = join '', map { qq{<li><a class="footer__phone" href="tel:$_->{tel}">$_->{show}</a></li>} } @PHONES;
  my $year = (localtime)[5] + 1900;
  return <<HTML;
<footer class="footer">
  <div class="wrap">
    <div class="footer__grid">
      <div>
        <a href="index.html" class="logo"><img src="assets/img/logo.png" alt="$SITE{name}"></a>
        <p style="margin-top:18px">Сеть центров тайского SPA в Пензе. Настоящие тайские практики в исполнении дипломированных мастеров из Королевства Таиланд.</p>
        <div class="soc">
          <a href="$SITE{vk}" target="_blank" rel="noopener" aria-label="ВКонтакте">$I{vk}</a>
          <a href="$SITE{inst}" target="_blank" rel="noopener" aria-label="Instagram">$I{inst}</a>
          <a href="mailto:$SITE{email}" aria-label="Написать на почту">$I{mail}</a>
        </div>
      </div>
      <div><h4>Меню</h4><ul>$nav</ul></div>
      <div><h4>Салоны в Пензе</h4><ul>$addr<li style="margin-top:14px"><a href="mailto:$SITE{email}">$SITE{email}</a></li></ul></div>
      <div><h4>Телефоны</h4><ul>$ph</ul><a class="btn btn--gold btn--sm" href="#" data-book style="margin-top:8px">Записаться</a></div>
    </div>
    <div class="footer__bottom">
      <span>© $year салон «$SITE{name}». На сайте используются cookie-файлы.</span>
      <a href="personal.html">Согласие на обработку персональных данных</a>
    </div>
  </div>
</footer>
HTML
}

sub booking_modal {
  my $chips = join '', map { qq{<label><input type="radio" name="branch" value="$_->{id}"><span>$_->{name}</span></label>} } @BRANCHES;
  my $m = join '', map { my $n = esc($_->{name}); qq{<option value="$n">$n</option>} } @$masters;
  return <<HTML;
<div class="modal" id="booking" role="dialog" aria-modal="true" aria-labelledby="booking-title">
  <div class="modal__box">
    <button class="close-x modal__close" data-modal-close aria-label="Закрыть">✕</button>
    <h3 id="booking-title">Записаться</h3>
    <p class="sub">Оставьте контакты — администратор перезвонит, подберёт программу и подтвердит время.</p>
    <form class="form" novalidate>
      <input type="hidden" name="program" value="">
      <div class="form__row">
        <div class="field"><label>Ваше имя</label><input type="text" name="name" placeholder="Как к вам обращаться" required></div>
        <div class="field"><label>Телефон</label><input type="tel" name="phone" placeholder="+7 (___) ___-__-__" required></div>
      </div>
      <div class="form__row">
        <div class="field"><label>Дата</label><input type="date" name="date"></div>
        <div class="field"><label>Время</label><input type="time" name="time"></div>
      </div>
      <div class="field"><label>Филиал</label><div class="chips">$chips</div></div>
      <div class="field"><label>Мастер (по желанию)</label><select name="master"><option value="">Любой свободный мастер</option>$m</select></div>
      <label class="check"><input type="checkbox" name="agree" required><span>Согласен(на) на обработку <a href="personal.html" target="_blank">персональных данных</a></span></label>
      <button class="btn btn--primary btn--block" type="submit">Забронировать</button>
      <p class="form__alt">Или запишитесь сами через <a href="$SITE{yclients}" target="_blank" rel="noopener">онлайн-запись</a></p>
    </form>
    <div class="form-success">
      <i>$I{check}</i>
      <h3>Заявка принята</h3>
      <p class="muted">Наш администратор свяжется с вами в ближайшее время.</p>
      <button class="btn btn--dark btn--sm" data-modal-close>Закрыть</button>
    </div>
  </div>
</div>
HTML
}

sub lightbox_html { <<HTML }
<div class="lightbox" aria-hidden="true">
  <button class="lb-close" aria-label="Закрыть">✕</button>
  <button class="lb-prev" aria-label="Назад">‹</button>
  <img src="" alt="">
  <button class="lb-next" aria-label="Вперёд">›</button>
  <div class="lb-count"></div>
</div>
HTML

sub fab_html { my $p = $PHONES[0]; <<HTML }
<div class="fab">
  <a class="fab__phone" href="tel:$p->{tel}" aria-label="Позвонить">$I{phone}</a>
  <a class="btn btn--primary" href="#" data-book>Записаться</a>
</div>
HTML

sub cta_html { <<HTML }
<section class="section--tight"><div class="wrap">
  <div class="cta reveal">
    <div>
      <div class="eyebrow">Запись</div>
      <h2>Подарите себе час настоящего Таиланда</h2>
      <p>Позвоните или оставьте заявку — подберём программу и мастера под ваше настроение.</p>
    </div>
    <div class="cta__actions">
      <a class="btn btn--light" href="tel:$PHONES[0]{tel}">$I{phone} $PHONES[0]{show}</a>
      <a class="btn btn--primary" href="#" data-book>Записаться</a>
    </div>
  </div>
</div></section>
HTML

sub layout {
  my (%a) = @_;
  my $desc = esc($a{desc} // 'Тайский массаж и SPA-программы в Пензе. Сеть центров тайского SPA ГРЕЙТ ТАЙ СПА: три салона, мастера из Таиланда, подарочные сертификаты.');
  my $title = esc($a{title});
  return <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<meta name="description" content="$desc">
<link rel="icon" href="assets/img/favicon.ico">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=El+Messiri:wght@500;600;700&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
@{[ header_html($a{active}) ]}
<main>
$a{body}
</main>
@{[ $a{no_cta} ? '' : cta_html() ]}
@{[ footer_html() ]}
@{[ booking_modal() ]}
@{[ lightbox_html() ]}
@{[ fab_html() ]}
<script src="assets/js/main.js"></script>
</body>
</html>
HTML
}

sub page_head {
  my ($title, $lead, $crumb) = @_;
  $crumb //= $title;
  my $l = $lead ? qq{<p class="lead">$lead</p>} : '';
  return qq{<section class="page-head"><div class="wrap"><div class="crumbs"><a href="index.html">Главная</a><span>$crumb</span></div><h1>$title</h1>$l</div></section>};
}

# ------------------------------------------------------------------ карточки
sub split_branch_title {
  my $t = shift;
  for my $b (@BRANCHES) { if ($t =~ s/\s+на\s+\Q$b->{name}\E\s*$//) { return ($t, $b) } }
  return ($t, undef);
}
sub price_card {
  my ($it) = @_;
  my ($title, $br) = split_branch_title($it->{title});
  $title =~ s/[«"]\s*$//; $title =~ s/"/»/ if $title =~ /«[^»]*"$/;
  my $badge = $br ? qq{<span class="price-card__branch">$br->{name}</span>} : '';
  my $data  = $br ? qq{ data-branch="$br->{id}"} : '';
  my $price = nl2br(tidy($it->{price}));
  my $text  = esc(tidy($it->{text}));
  my $more  = length($it->{text}) > 150 ? qq{<button class="price-card__more" data-toggle-card>Подробнее</button>} : '';
  my $book  = attr($it->{title});
  return <<HTML;
<article class="price-card reveal"$data>
  <div class="price-card__img"><img src="assets/img/$it->{img}" alt="@{[attr($title)]}" loading="lazy"></div>
  <div class="price-card__body">
    $badge
    <h3>@{[esc($title)]}</h3>
    <p class="price-card__text">$text</p>
    $more
    <div class="price-card__foot">
      <div class="price-card__price">$price</div>
      <a class="btn btn--dark btn--sm" href="#" data-book="$book">Записаться</a>
    </div>
  </div>
</article>
HTML
}
sub price_tabs {
  my ($limit, $sticky) = @_;
  my @cats = grep { $_->{name} ne 'Акции' } @$price;
  my $btns = join '', map { my $c = $cats[$_]; qq{<button class="@{[$_==0?'is-active':'']}">$c->{name}</button>} } 0..$#cats;
  my $panels = '';
  for my $k (0..$#cats) {
    my @items = @{$cats[$k]{items}};
    my $total = scalar @items;
    @items = @items[0..$limit-1] if $limit && $total > $limit;
    my $cards = join '', map { price_card($_) } @items;
    my $more = ($limit && $total > $limit) ? qq{<div class="price-more"><a class="btn btn--ghost" href="price.html">Смотреть все программы раздела ($total) $I{arrow}</a></div>} : '';
    $panels .= qq{<div class="tab-panel @{[$k==0?'is-active':'']}" id="cat-$k"><div class="price-grid">$cards</div>$more</div>};
  }
  my $st = $sticky ? ' tabs--sticky' : '';
  return qq{<div data-tabs><div class="tabs$st" role="tablist">$btns</div>$panels</div>};
}
sub promo_card {
  my ($p, $tag) = @_;
  my $t = tidy($p->{text});
  my ($main, $fine) = ($t, '');
  if ($t =~ /^(.*?)\n?(\*.*)$/s) { ($main, $fine) = ($1, $2) }
  $main =~ s/^\s+|\s+$//g; $fine =~ s/^\s+|\s+$//g; $fine =~ s/\n/ /g;
  my $title = ucfirst(lc $p->{title}); $title =~ s/\b(vip|спа|spa)\b/uc $1/ge; $title =~ s/\bдень рождения\b/День Рождения/i; $title =~ s/ - / — /g;
  my $f = $fine ? qq{<p class="promo__fine">@{[esc($fine)]}</p>} : '';
  return <<HTML;
<article class="promo reveal">
  <div class="promo__img"><img src="assets/img/$p->{img}" alt="@{[attr($title)]}" loading="lazy"><span class="promo__tag">$tag</span></div>
  <div class="promo__body">
    <h3>@{[esc($title)]}</h3>
    <p class="promo__text">@{[esc($main)]}</p>
    $f
    <a class="btn btn--primary btn--sm" href="#" data-book="@{[attr($p->{title})]}">Забронировать</a>
  </div>
</article>
HTML
}
sub master_card {
  my ($m) = @_;
  my $t = tidy($m->{text});
  my $salon;
  if ($t =~ s/\n?Работает в салоне на (\S+?)\.?\s*$//) { $salon = $1 }
  elsif ($t =~ s/\n?Работает в салоне на (\S+?)\.?(\n|$)/$2/) { $salon = $1 }
  my $badge = $salon ? qq{<span class="master__badge">$I{pin} Салон на $salon</span>} : '';
  my $more  = length($t) > 160 ? qq{<button class="price-card__more" data-toggle-card>Подробнее</button>} : '';
  return <<HTML;
<article class="master reveal">
  <div class="master__img"><img src="assets/img/$m->{img}" alt="@{[attr($m->{name})]}" loading="lazy"></div>
  <div class="master__body">
    <h3>@{[esc($m->{name})]}</h3>
    $badge
    <p class="master__text">@{[esc($t)]}</p>
    $more
    <div class="master__foot"><a class="btn btn--dark btn--sm" href="#" data-book="@{[attr($m->{name})]}">Записаться к мастеру</a></div>
  </div>
</article>
HTML
}
sub branch_cards {
  my $n = 0;
  return join '', map { $n++; <<HTML } @BRANCHES;
<div class="branch-card reveal" data-branch-card="$_->{id}">
  <span class="branch-card__num">0$n</span>
  <h3>Салон на $_->{name}</h3>
  <address>$SITE{city}, $_->{addr}<br><span class="muted small">$_->{note}</span></address>
  <span class="ip">$_->{ip}</span>
  <div class="branch-card__links">
    <a class="btn btn--primary btn--sm" href="#" data-book>Записаться</a>
    <a class="btn btn--ghost btn--sm" href="$_->{map}" target="_blank" rel="noopener">$I{pin} На карте</a>
  </div>
</div>
HTML
}
sub phones_strip {
  my $ph = join '', map { qq{<div><span class="lbl">$_->{lbl}</span><a href="tel:$_->{tel}">$_->{show}</a></div>} } @PHONES;
  return qq{<div class="phones reveal">$ph<div class="spacer"></div><div><span class="lbl">Почта</span><a href="mailto:$SITE{email}">$SITE{email}</a></div></div>};
}
sub map_html { qq{<div class="map reveal"><iframe src="$SITE{map}" title="Салоны ГРЕЙТ ТАЙ СПА на карте" loading="lazy" allowfullscreen></iframe></div>} }
sub contacts_block {
  return qq{<div class="contacts-grid">@{[branch_cards()]}</div>@{[phones_strip()]}@{[map_html()]}};
}

# Оборачивает «голый» текст на верхнем уровне фрагмента в <p>.
sub wrap_loose {
  my $h = shift;
  my @tok = $h =~ /(<[^>]+>|[^<]+)/g;
  my ($out, $buf, $depth) = ('', '', 0);
  my $blk = qr/^(p|h[1-6]|ul|ol|li|table|tr|td|th|tbody|thead|details|summary|blockquote)$/i;
  my $flush = sub {
    if ($buf =~ /\S/) { my $plain = $buf; $plain =~ s/<[^>]+>//g; $out .= ($plain =~ /\S/) ? "<p>$buf</p>\n" : $buf }
    else { $out .= $buf }
    $buf = '';
  };
  for my $t (@tok) {
    if ($t =~ /^<\/?(\w+)/ && $1 =~ $blk) {
      $flush->() if $depth == 0;
      $depth += ($t =~ /^<\//) ? -1 : 1;
      $depth = 0 if $depth < 0;
      $out .= $t;
    } elsif ($depth == 0) { $buf .= $t } else { $out .= $t }
  }
  $flush->();
  $out =~ s/<p>\s*<br>/<p>/g; $out =~ s/<br>\s*<\/p>/<\/p>/g;
  $out;
}

# ================================================================== ГЛАВНАЯ
{
  my $slides = join '', map { my $k=$_; my $s=$HERO[$k]; qq{<img src="assets/img/$s->{img}" alt="" class="@{[$k==0?'is-active':'']}"@{[$k?' loading="lazy"':'']}>} } 0..$#HERO;
  my $caps   = join '', map { qq{<span>@{[esc($_->{cap})]}</span>} } @HERO;
  my $dots   = join '', map { qq{<button class="@{[$_==0?'is-active':'']}" aria-label="Фото @{[$_+1]}"></button>} } 0..$#HERO;
  my @tags   = ('Для двоих', 'Новым гостям', 'Сезонная', 'Абонементы', 'Будни', 'Именинникам');
  my $promos_html = join '', map { promo_card($promos->[$_], $tags[$_] // 'Акция') } 0..$#$promos;

  my $gal_btns = join '', map { qq{<button class="@{[$_==0?'is-active':'']}">$gallery->[$_]{name}</button>} } 0..$#$gallery;
  my $gal_panels = '';
  for my $k (0..$#$gallery) {
    my @im = @{$gallery->[$k]{images}};
    my $links = join '', map { my $h = $_ >= 9 ? ' is-hidden' : ''; qq{<a href="assets/img/$im[$_]" class="reveal$h"><img src="assets/img/$im[$_]" alt="$gallery->[$k]{name}" loading="lazy"></a>} } 0..$#im;
    my $more = @im > 9 ? qq{<div class="price-more"><button class="btn btn--ghost" data-gallery-more>Показать ещё @{[@im-9]} фото</button></div>} : '';
    $gal_panels .= qq{<div class="tab-panel @{[$k==0?'is-active':'']}"><div class="gallery">$links</div>$more</div>};
  }

  my $body = <<HTML;
<section class="hero">
  <div class="wrap hero__grid">
    <div class="reveal is-in">
      <div class="eyebrow">Сеть центров тайского SPA · Пенза</div>
      <h1>Место, где <em>стоит оказаться</em></h1>
      <p class="lead">Настоящие тайские практики в исполнении дипломированных мастеров из Королевства Таиланд. Три салона в Пензе, премиальный сервис и атмосфера, в которую хочется возвращаться.</p>
      <div class="hero__cta">
        <a class="btn btn--primary" href="#" data-book>Записаться</a>
        <a class="btn btn--ghost" href="#price">Смотреть прайс $I{arrow}</a>
      </div>
      <div class="hero__facts">
        <div><b>3</b><span>салона в Пензе</span></div>
        <div><b>с 2016</b><span>года с вами</span></div>
        <div><b>@{[scalar @$masters]}</b><span>мастеров из Таиланда</span></div>
      </div>
    </div>
    <div class="hero__media">
      <div class="hero__photo">$slides<div class="hero__dots">$dots</div><div class="hero__caption">$caps</div></div>
      <a class="hero__badge hero__badge--top" href="certificates.html"><i>$I{gift}</i><div><b>Подарочные сертификаты</b><span>от 3 000 ₽, действуют 365 дней</span></div></a>
      <a class="hero__badge" href="#" data-book="Скидка на первый визит"><i>$I{percent}</i><div><b>Скидка 700 ₽</b><span>на первый визит в ГРЕЙТ ТАЙ СПА</span></div></a>
    </div>
  </div>
</section>

<section class="section" id="promo">
  <div class="wrap">
    <div class="section-head reveal">
      <div><div class="eyebrow">Специальные предложения</div><h2>Акции</h2></div>
      <p>Скидки для новых гостей, именинников и тех, кто любит отдыхать в будни. Акции не суммируются между собой.</p>
    </div>
    <div class="promo-grid">$promos_html</div>
  </div>
</section>

<section class="section section--sand" id="about">
  <div class="wrap about">
    <div class="about__media reveal">
      <div class="main"><img src="assets/img/aba.jpg" alt="Интерьер ГРЕЙТ ТАЙ СПА" loading="lazy"></div>
      <div class="second"><img src="assets/img/about.jpg" alt="Тайский массаж" loading="lazy"></div>
    </div>
    <div class="reveal">
      <div class="eyebrow">О нас</div>
      <h2>ГРЕЙТ ТАЙ СПА — это</h2>
      <div class="features">
        <div class="feature"><i>$I{lotus}</i><div><h4>Настоящие тайские практики</h4><p>Нашей гордостью являются древние тайские практики. С их помощью наши мастера помогут вам отдохнуть телом и душой.</p></div></div>
        <div class="feature"><i>$I{award}</i><div><h4>Специалисты высокого уровня</h4><p>У нас работают только высококвалифицированные специалисты из Королевства Таиланд. Все они прошли обучение в лучших школах и имеют подтверждающие сертификаты.</p></div></div>
        <div class="feature"><i>$I{crown}</i><div><h4>Салон премиум-класса</h4><p>Высокий уровень сервиса и индивидуальный подход — то, чего заслуживают наши гости. Сделайте любой свой день особенным.</p></div></div>
      </div>
      <a class="btn btn--dark" href="about.html">Подробнее о нас $I{arrow}</a>
    </div>
  </div>
</section>

<section class="section" id="price">
  <div class="wrap">
    <div class="section-head reveal">
      <div><div class="eyebrow">Программы и цены</div><h2>Прайс</h2></div>
      <p>Оздоровление, релаксация, SPA-ритуалы для одного и для двоих, программы для детей и для лица. Выберите филиал в шапке сайта, чтобы видеть цены именно для него.</p>
    </div>
    @{[ price_tabs(6, 0) ]}
    <div class="price-more" style="margin-top:36px"><a class="btn btn--primary" href="price.html">Открыть полный прайс $I{arrow}</a></div>
  </div>
</section>

<section class="section section--sand" id="gallery">
  <div class="wrap">
    <div class="section-head reveal">
      <div><div class="eyebrow">Фотогалерея</div><h2>Атмосфера наших салонов</h2></div>
      <p>Интерьеры, мастера за работой и номера для SPA-программ.</p>
    </div>
    <div data-tabs><div class="tabs">$gal_btns</div>$gal_panels</div>
  </div>
</section>

<section class="section" id="contacts">
  <div class="wrap">
    <div class="section-head reveal">
      <div><div class="eyebrow">Контакты</div><h2>Три салона в Пензе</h2></div>
      <p>Выберите ближайший салон, позвоните или оставьте заявку — администратор подберёт удобное время.</p>
    </div>
    @{[ contacts_block() ]}
  </div>
</section>
HTML
  spit('index.html', layout(title => 'Тайский массаж в Пензе — ГРЕЙТ ТАЙ СПА', active => 'index.html', body => $body));
}

# ================================================================== ПРАЙС
{
  my $body = page_head('Прайс', 'Все программы и цены сети ГРЕЙТ ТАЙ СПА. Для программ, которые отличаются по салонам, цена указана для каждого филиала — выберите свой в шапке сайта.');
  $body .= qq{<section class="section--tight"><div class="wrap">@{[ price_tabs(0, 1) ]}</div></section>};
  spit('price.html', layout(title => 'Прайс — ГРЕЙТ ТАЙ СПА, Пенза', active => 'price.html', body => $body, desc => 'Цены на тайский массаж и SPA-программы в Пензе: оздоровление, релаксация, силовые ойл-техники, SPA для одного и для двоих, программы для детей и для лица.'));
}

# ================================================================== МАСТЕРА
{
  my $cards = join '', map { master_card($_) } @$masters;
  my $body = page_head('Мастера', 'Все наши мастера — дипломированные специалисты из Королевства Таиланд с опытом работы от 8 лет. Каждая по-своему чувствует тело: выберите «свою» и запишитесь именно к ней.');
  $body .= qq{<section class="section--tight"><div class="wrap"><div class="masters-grid">$cards</div></div></section>};
  spit('masters.html', layout(title => 'Мастера — ГРЕЙТ ТАЙ СПА, Пенза', active => 'masters.html', body => $body, desc => 'Тайские мастера сети ГРЕЙТ ТАЙ СПА в Пензе: опыт, специализация, в каком салоне работают. Запись к конкретному мастеру.'));
}

# ================================================================== О НАС
{
  my $frag = slurp('data/pages/about.html');
  my ($intro, $offer) = split /(?=<h2>Договор-оферта)/, $frag, 2;
  $intro =~ s/<img[^>]*>//g; $intro = wrap_loose($intro);
  $offer //= ''; $offer =~ s/^<h2>.*?<\/h2>//s; $offer = wrap_loose($offer);
  # нумерованные пункты оферты как подзаголовки
  $offer =~ s/<p>\s*(\d+\.\s+[^<\d][^<]{0,80})\s*<\/p>/<h3>$1<\/h3>/g;
  my $body = page_head('О нас', 'Сеть центров тайского SPA в Пензе с 2016 года: три салона, мастера из Королевства Таиланд и сервис премиум-класса.');
  $body .= <<HTML;
<section class="section--tight"><div class="wrap">
  <div class="two-col">
    <div class="prose reveal">$intro</div>
    <div class="about__media reveal" style="max-width:520px">
      <div class="main"><img src="assets/img/about.jpg" alt="Тайский массаж в ГРЕЙТ ТАЙ СПА" loading="lazy"></div>
      <div class="second"><img src="assets/img/aba.jpg" alt="Интерьер салона" loading="lazy"></div>
    </div>
  </div>
  <div class="stats reveal">
    <div class="stat"><b>2016</b><span>год открытия первого салона в Пензе</span></div>
    <div class="stat"><b>3</b><span>салона в сети</span></div>
    <div class="stat"><b>@{[scalar @$masters]}</b><span>дипломированных мастеров из Таиланда</span></div>
    <div class="stat"><b>10+</b><span>лет опыта у каждого мастера</span></div>
  </div>
  <div class="features" style="grid-template-columns:repeat(3,1fr);gap:28px;margin:0 0 56px">
    <div class="feature reveal"><i>$I{lotus}</i><div><h4>Настоящие тайские практики</h4><p>Древние техники, передающиеся из поколения в поколение, помогут отдохнуть телом и душой.</p></div></div>
    <div class="feature reveal"><i>$I{award}</i><div><h4>Специалисты высокого уровня</h4><p>Все мастера прошли обучение в лучших школах Таиланда и имеют подтверждающие сертификаты.</p></div></div>
    <div class="feature reveal"><i>$I{crown}</i><div><h4>Салон премиум-класса</h4><p>Высокий уровень сервиса и индивидуальный подход к каждому гостю.</p></div></div>
  </div>
  <details class="acc reveal"><summary>Договор-оферта на оказание SPA-услуг</summary><div class="acc__body legal prose prose--wide">$offer</div></details>
</div></section>
<style>\@media (max-width:860px){.features[style]{grid-template-columns:1fr!important}}</style>
HTML
  spit('about.html', layout(title => 'О нас — ГРЕЙТ ТАЙ СПА, Пенза', active => 'about.html', body => $body));
}

# ================================================================== СЕРТИФИКАТЫ
{
  my $frag = slurp('data/pages/certificates.html');
  my ($intro, $rest) = split /(?=<h2>Поздравляем)/, $frag, 2;
  my ($rules, $abon) = split /(?=<h2>Правила использования абонементов)/, ($rest // ''), 2;
  $intro =~ s/<img[^>]*>//g; $intro =~ s/^\s*(<br>)?\s*//; $intro =~ s/\s*(<br>|\n)+\s*/<\/p><p>/g; $intro = wrap_loose("<p>$intro</p>");
  for ($rules, $abon) { next unless defined; s/^<h2>.*?<\/h2>//s; $_ = wrap_loose($_) }
  $abon //= '';
  my $body = page_head('Подарочные сертификаты', 'Лучший подарок на все значимые события — сертификат ГРЕЙТ ТАЙ СПА. Гарантированно нужный, красиво оформленный, действует 365 дней во всех салонах сети.');
  $body .= <<HTML;
<section class="section--tight"><div class="wrap">
  <div class="two-col two-col--aside">
    <div>
      <div class="prose reveal">$intro</div>
      <h3 style="margin-top:12px">Номиналы сертификатов</h3>
      <div class="nominals reveal">@{[ join '', map { qq{<span>$_ ₽</span>} } ('3 000','5 000','10 000','15 000','25 000','50 000') ]}</div>
      <details class="acc reveal"><summary>Правила использования подарочных сертификатов</summary><div class="acc__body legal prose prose--wide">$rules</div></details>
      <details class="acc reveal"><summary>Правила использования абонементов</summary><div class="acc__body legal prose prose--wide">$abon</div></details>
    </div>
    <aside class="sticky-aside">
      <div class="aside-card reveal" style="padding:0;overflow:hidden"><img src="assets/img/418e31md21ha8xjrdh212icibz62vdt2.png" alt="Подарочный сертификат ГРЕЙТ ТАЙ СПА" style="width:100%"></div>
      <div class="aside-card reveal">
        <h3>Электронный сертификат</h3>
        <p>Оформите онлайн за пару минут — письмо с сертификатом придёт на почту, его достаточно распечатать или показать с телефона.</p>
        <a class="btn btn--primary btn--block" href="$SITE{yclients}" target="_blank" rel="noopener">Купить онлайн $I{arrow}</a>
      </div>
      <div class="aside-card reveal">
        <h3>Заказать по телефону</h3>
        <p>Или приобретите сертификат в любом салоне сети.</p>
        @{[ join '', map { qq{<a class="btn btn--ghost btn--sm" href="tel:$_->{tel}" style="margin:4px 6px 4px 0">$_->{show}</a>} } @PHONES ]}
      </div>
    </aside>
  </div>
</div></section>
HTML
  spit('certificates.html', layout(title => 'Подарочные сертификаты — ГРЕЙТ ТАЙ СПА, Пенза', active => 'certificates.html', body => $body, desc => 'Подарочные сертификаты на тайский массаж и SPA в Пензе номиналом от 3 000 до 50 000 ₽. Электронные сертификаты онлайн. Правила использования сертификатов и абонементов.'));
}

# ================================================================== КОНТАКТЫ
{
  my $body = page_head('Контакты', 'Три салона в Пензе. Позвоните, напишите или оставьте заявку — администратор подберёт удобное время и мастера.');
  $body .= qq{<section class="section--tight"><div class="wrap">@{[ contacts_block() ]}</div></section>};
  spit('contacts.html', layout(title => 'Контакты — ГРЕЙТ ТАЙ СПА, Пенза', active => 'contacts.html', body => $body, desc => 'Адреса и телефоны салонов ГРЕЙТ ТАЙ СПА в Пензе: ул. Кижеватова 21, ул. Лозицкой 6, ул. Пушкина 11.'));
}

# ================================================================== СТАТЬИ
{
  my $n = 0;
  my $cards = join '', map { $n++; my $num = sprintf '%02d', $n; <<HTML } @$articles;
<a class="article reveal" href="https://massage58.ru$_->{url}" target="_blank" rel="noopener">
  <span class="article__num">$num</span>
  <h3>@{[esc($_->{title})]}</h3>
  <p>@{[esc(tidy($_->{text}))]}</p>
  <span class="article__more">Читать статью $I{arrow}</span>
</a>
HTML
  my $body = page_head('Статьи', 'О тайском массаже, SPA-ритуалах и о том, как получить от отдыха максимум.');
  $body .= qq{<section class="section--tight"><div class="wrap"><div class="articles-grid">$cards</div></div></section>};
  spit('articles.html', layout(title => 'Статьи — ГРЕЙТ ТАЙ СПА, Пенза', active => 'articles.html', body => $body, desc => 'Статьи о тайском массаже и SPA: польза, техники, подготовка к сеансу, подарочные сертификаты.'));
}

# ================================================================== ФРАНШИЗА
{
  my $frag = slurp('data/pages/franchise.html');
  $frag =~ s/^\s*<img[^>]*>//s;                           # первое фото уходит в шапку
  $frag =~ s/<h2>Привлекательные условия[^<]*<\/h2>\s*//; # дублирует подзаголовок
  $frag = wrap_loose($frag);
  $frag =~ s/(<h2>Калькулятор франшизы:?<\/h2>\s*)<ul>/$1<ul class="fr-calc">/;
  $frag =~ s/(<h2>Рекомендуемые города[^<]*<\/h2>\s*)<ul>/$1<ul class="cities">/;
  $frag =~ s/(<h2>Поэтапное описание[^<]*<\/h2>\s*)<ul>/$1<ul class="steps">/;
  $frag =~ s/<h2>Требованиям к помещениям<\/h2>/<h2>Требования к помещениям<\/h2>/;
  my $body = page_head('Франшиза', 'Привлекательные условия открытия SPA-центра «ГРЕЙТ ТАЙ СПА»: готовая модель бизнеса, помощь с подбором мастеров из Таиланда и комплексная поддержка.');
  $body .= <<HTML;
<section class="section--tight"><div class="wrap">
  <div class="photo-strip reveal">
    <div><img src="assets/img/fr13.jpg" alt="" loading="lazy"></div>
    <div><img src="assets/img/fr5.JPG" alt="" loading="lazy"></div>
    <div><img src="assets/img/fr9.JPG" alt="" loading="lazy"></div>
  </div>
  <div class="two-col two-col--aside">
    <div class="prose reveal">$frag</div>
    <aside class="sticky-aside">
      <div class="aside-card reveal">
        <h3>Связь с нами</h3>
        <p>Расскажите о себе и городе — мы ответим и пришлём презентацию франшизы.</p>
        <form class="form" data-demo-form novalidate>
          <div class="form__fields" style="display:grid;gap:12px">
            <div class="field"><label>Ваше имя</label><input type="text" name="name" required></div>
            <div class="field"><label>Ваш e-mail</label><input type="email" name="email" required></div>
            <div class="field"><label>Сообщение</label><textarea name="message"></textarea></div>
            <label class="check"><input type="checkbox" required><span>Согласен(на) на обработку <a href="personal.html" target="_blank">персональных данных</a></span></label>
            <button class="btn btn--primary btn--block" type="submit">Отправить</button>
          </div>
          <div class="form-success"><i>$I{check}</i><h3>Спасибо!</h3><p class="muted">Мы свяжемся с вами по указанной почте.</p></div>
        </form>
      </div>
    </aside>
  </div>
</div></section>
HTML
  spit('franchise.html', layout(title => 'Франшиза — ГРЕЙТ ТАЙ СПА', active => 'franchise.html', body => $body, desc => 'Франшиза сети центров тайского SPA ГРЕЙТ ТАЙ СПА: условия, инвестиции, этапы открытия, поддержка.'));
}

# ================================================================== ПЕРСОНАЛЬНЫЕ ДАННЫЕ
{
  my $frag = slurp('data/pages/personal.html');
  $frag =~ s/^\s*<h2>[^<]*<\/h2>//s;
  $frag = wrap_loose($frag);
  $frag =~ s/<p>\s*(\d+\.\s+[^<\d][^<]{0,90})\s*<\/p>/<h3>$1<\/h3>/g;
  my $body = page_head('Согласие на обработку персональных данных', 'Политика конфиденциальности сайта massage58.ru.', 'Персональные данные');
  $body .= qq{<section class="section--tight"><div class="wrap"><div class="prose legal reveal">$frag</div></div></section>};
  spit('personal.html', layout(title => 'Согласие на обработку персональных данных — ГРЕЙТ ТАЙ СПА', active => '', body => $body, no_cta => 1));
}

print "Готово.\n";
