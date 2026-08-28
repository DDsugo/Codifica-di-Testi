<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="tei">

  <xsl:output method="html" encoding="UTF-8" indent="yes" doctype-system="about:legacy-compat"/>

  <!-- VARIABILI GLOBALI -->

  <!-- $articoli: seleziona i 5 <div> articolo figli diretti di <body>,
       escludendo i 5 <div type="closer">. Usata nel sommario (nav) e
       nel ciclo principale (main). -->
  <xsl:variable name="articoli"
    select="//tei:body/tei:div[not(@type='closer')]"/>

  <!-- $ent: carica il file esterno entita_nominate.xml e punta
       direttamente al suo elemento radice <TEI>.
       Da qui si raggiungono: listPerson, listPlace, listOrg, listBibl, taxonomy. -->
  <xsl:variable name="ent" select="document('entita_nominate.xml')/tei:TEI"/>

  <!-- ═════════════════════════════════════════════════════════
       TEMPLATE AUSILIARIO «pagina»
       Riceve un blocco di testo ($n) e restituisce l'@xml:id
       del <pb> a cui quel blocco appartiene. Serve a smistare
       i paragrafi nella pagina corretta dentro render-pagina.
       ═════════════════════════════════════════════════════════ -->
  <xsl:template name="pagina">
    <xsl:param name="n" as="element()"/>
    <xsl:choose>
      <xsl:when test="$n/self::tei:cb">
        <xsl:value-of select="$n/preceding::tei:pb[1]/@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="lbRiferimento"
          select="if ($n//tei:lb) then ($n//tei:lb)[1]
                  else if ($n/descendant::*//tei:lb) then ($n/descendant::*//tei:lb)[1]
                  else ($n/preceding::tei:lb)[last()]"/>
        <xsl:value-of select="$lbRiferimento/preceding::tei:pb[1]/@xml:id"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ══════════════════════════════════════════════════════════
       TEMPLATE AUSILIARIO «classe»
       Riceve un elemento TEI inline ($e) e restituisce il nome
       della classe CSS corrispondente (es. "persona", "luogo",
       "opera"). Usato dal template text() mode="riga" per
       preservare la colorazione quando il for-each-group spezza
       un elemento marcato a cavallo di due righe.
       ══════════════════════════════════════════════════════════ -->
  <xsl:template name="classe">
    <xsl:param name="e" as="element()"/>
    <xsl:choose>
      <xsl:when test="$e/self::tei:persName">persona</xsl:when>
      <xsl:when test="$e/self::tei:placeName">luogo</xsl:when>
      <xsl:when test="$e/self::tei:orgName">organizzazione</xsl:when>
      <xsl:when test="$e/self::tei:title[@type='periodical']">periodico</xsl:when>
      <xsl:when test="$e/self::tei:title">opera</xsl:when>
      <xsl:when test="$e/self::tei:term[@type='theme']">tema</xsl:when>
      <xsl:when test="$e/self::tei:term">termine</xsl:when>
      <xsl:when test="$e/self::tei:foreign">straniero</xsl:when>
      <xsl:when test="$e/self::tei:hi[@rend='italic']">corsivo</xsl:when>
      <xsl:when test="$e/self::tei:distinct">espressione</xsl:when>
      <xsl:when test="$e/self::tei:name">nome</xsl:when>
      <xsl:when test="$e/self::tei:q">discorso-diretto</xsl:when>
      <xsl:when test="$e/self::tei:rs[@type='person']">persona</xsl:when>
      <xsl:when test="$e/self::tei:rs[@type='work']">opera</xsl:when>
      <xsl:when test="$e/self::tei:rs">testo</xsl:when>
      <xsl:otherwise>testo</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Template ausiliario «classeRiga»: costruisce la stringa delle classi CSS
       per uno <span> di riga. Parte sempre da "riga" e aggiunge classi opzionali
       in base alle direttive presenti in @rend di <lb>. -->
  <xsl:template name="classeRiga">
    <xsl:param name="rend"/>
    <xsl:text>riga</xsl:text>
    <xsl:if test="contains($rend,'align(center)')"> r-centro</xsl:if>
    <xsl:if test="contains($rend,'align(right)')"> r-destra</xsl:if>
    <xsl:if test="contains($rend,'align(left)')"> r-sinistra</xsl:if>
    <xsl:if test="contains($rend,'case(uppercase)')"> r-maiuscolo</xsl:if>
    <xsl:if test="contains($rend,'italic')"> r-corsivo</xsl:if>
    <xsl:if test="contains($rend,'first-line-indented')"> r-rientro</xsl:if>
  </xsl:template>

  <!-- ════════════════════════════════════════════════════════════════
       TEMPLATE RADICE (match="/")
       Punto di ingresso della trasformazione. Intercetta il nodo
       radice del documento XML e genera l'intera pagina HTML5:
         - <head> con titolo, CSS e preconnessioni Google Fonts
         - <header> con titolo della rivista e metadati bibliografici
         - <nav class="sommario"> con indice cliccabile degli articoli
         - <nav class="pagine"> con link a ciascun pannello-pagina
         - <aside class="legenda"> con le 10 voci di evidenziazione
         - <main> con una <section> per articolo, ciascuna contenente
           uno o più pannelli facsimile+testo (via render-pagina)
         - appendice entità nominate (da entita_nominate.xml)
         - <footer> e collegamento a script.js
       ════════════════════════════════════════════════════════════════ -->
  <xsl:template match="/">

    <html lang="it">

      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>
          <xsl:value-of select="//tei:titleStmt/tei:title"/> (edizione digitale)
        </title>
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="crossorigin"/>
        <link rel="stylesheet" href="style.css"/>
      </head>

      <body>

        <!-- Intestazione -->
        <header class="intestazione">
          <p class="occhiello">Edizione digitale image-based · TEI P5</p>
          <h1>La Farfalla</h1>
          <p class="sub">
            <xsl:for-each select="//tei:monogr/tei:imprint/tei:pubPlace">
              <xsl:if test="position() > 1">, </xsl:if>
              <xsl:value-of select="."/>
            </xsl:for-each>
            — volumi <xsl:value-of select="//tei:monogr/tei:biblScope[@unit='volume']"/>;
            fascicoli <xsl:value-of select="//tei:monogr/tei:biblScope[@unit='issue']"/>
          </p>
          <p class="firma-intestazione">
            codifica a cura di
            <xsl:for-each select="//tei:titleStmt/tei:respStmt/tei:name">
              <xsl:if test="position() > 1"> e </xsl:if>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </p>
        </header>

        <!-- Indice articoli -->
        <nav class="sommario" aria-label="Indice degli articoli">
          <h2>Sommario</h2>
          <ol>
            <xsl:for-each select="$articoli">
              <xsl:variable name="pos" select="position()"/>
              <xsl:variable name="artId" select="concat('articolo-', $pos)"/>
              <xsl:variable name="tipo" select="@type"/>
              <xsl:variable name="titolo" select="normalize-space(tei:head)"/>
              <xsl:variable name="autore"
                select="normalize-space(following-sibling::tei:div[@type='closer'][1]//tei:signed)"/>
              <xsl:variable name="pagina" select="tei:pb/@n"/>
              <li>
                <a href="#{$artId}">
                  <xsl:value-of select="$titolo"/>
                </a>
                <span class="info-articolo">
                  <xsl:value-of select="$autore"/>
                  <xsl:if test="$pagina"> — pag. <xsl:value-of select="$pagina"/></xsl:if>
                  <xsl:text> (</xsl:text><xsl:value-of select="$tipo"/><xsl:text>)</xsl:text>
                </span>
              </li>
            </xsl:for-each>
          </ol>
        </nav>

        <!-- Navigazione pagine -->
        <nav class="pagine" aria-label="Salta a una pagina">
          <span class="pagine-titolo">Pagine</span>
          <ul>
            <xsl:for-each select="//tei:pb">
              <li><a href="#pagina-{@n}-{generate-id(.)}"><xsl:value-of select="@n"/></a></li>
            </xsl:for-each>
          </ul>
        </nav>

        <!-- Legenda entità nominate -->
        <aside class="legenda" aria-label="Legenda delle entità nominate">
          <p class="legenda-titolo">Clicca unʼopzione per evidenziarla nel testo</p>
          <ul>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'persona'"/>
              <xsl:with-param name="et" select="'persName'"/>
              <xsl:with-param name="desc" select="'Persone'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'luogo'"/>
              <xsl:with-param name="et" select="'placeName'"/>
              <xsl:with-param name="desc" select="'Luoghi'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'organizzazione'"/>
              <xsl:with-param name="et" select="'orgName'"/>
              <xsl:with-param name="desc" select="'Organizzazioni'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'opera'"/>
              <xsl:with-param name="et" select="'title'"/>
              <xsl:with-param name="desc" select="'Titoli di opere'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'periodico'"/>
              <xsl:with-param name="et" select="'title type=&quot;periodical&quot;'"/>
              <xsl:with-param name="desc" select="'Periodici'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'termine'"/>
              <xsl:with-param name="et" select="'term'"/>
              <xsl:with-param name="desc" select="'Termini letterari'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'straniero'"/>
              <xsl:with-param name="et" select="'foreign'"/>
              <xsl:with-param name="desc" select="'Espressioni straniere'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'espressione'"/>
              <xsl:with-param name="et" select="'distinct'"/>
              <xsl:with-param name="desc" select="'Espressioni idiomatiche'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'corsivo'"/>
              <xsl:with-param name="et" select="'hi rend=&quot;italic&quot;'"/>
              <xsl:with-param name="desc" select="'Corsivi'"/>
            </xsl:call-template>
            <xsl:call-template name="voce-legenda">
              <xsl:with-param name="cls" select="'firma'"/>
              <xsl:with-param name="et" select="'signed'"/>
              <xsl:with-param name="desc" select="'Firme e chiuse'"/>
            </xsl:call-template>
          </ul>
          <div class="legenda-footer">
            <button type="button" class="legenda-reset">Azzera evidenziazioni</button>
            <p class="legenda-aiuto">Passa il cursore su una riga per vedere la zona corrispondente sulla pagina originale.</p>
          </div>
        </aside>

        <!-- Corpo principale -->
        <main>
          <xsl:for-each select="$articoli">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="artId" select="concat('articolo-', $pos)"/>
            <xsl:variable name="tipo" select="@type"/>
            <xsl:variable name="closerSeguente"
              select="following-sibling::tei:div[@type='closer'][1]"/>
            <xsl:variable name="articoloCorrente" select="."/>

            <section class="articolo-wrap" id="{$artId}">
              <p class="articolo-meta">
                <xsl:choose>
                  <xsl:when test="$tipo='recensione'">Recensione</xsl:when>
                  <xsl:when test="$tipo='articolo'">Articolo</xsl:when>
                  <xsl:when test="$tipo='bibliografia'">Bibliografia</xsl:when>
                  <xsl:otherwise><xsl:value-of select="$tipo"/></xsl:otherwise>
                </xsl:choose>
                <xsl:if test="@n"> — n. <xsl:value-of select="@n"/></xsl:if>
              </p>

              <!-- Per ogni pb dentro questo articolo, genera un pannello a 2 colonne (facsimile + trascrizione) -->
              <xsl:for-each select=".//tei:pb">
                <xsl:call-template name="render-pagina">
                  <xsl:with-param name="pb" select="."/>
                  <xsl:with-param name="articolo" select="$articoloCorrente"/>
                  <xsl:with-param name="closer" select="$closerSeguente"/>
                </xsl:call-template>
              </xsl:for-each>

            </section>
          </xsl:for-each>
        </main>

        <!-- ═══════════════════════════════════════════════════════════════
             APPENDICE ENTITÀ NOMINATE
             Richiama il template appendice-entita che genera una <section>
             con le voci di persone, luoghi, enti, opere e temi lette
             dal file esterno entita_nominate.xml.
             ═══════════════════════════════════════════════════════════════ -->
        <xsl:call-template name="appendice-entita"/>

        <!-- Footer -->
        <footer>
          <p>Edizione digitale realizzata per il corso di Codifica di Testi - Università di Pisa, a.a. 2025-2026.<br/>
             Fonte: progetto COVerLeSS (img.serverchroma.cnr.it); trasformazione eseguita tramite XSLT 2.0.
          </p>
        </footer>

        <script src="script.js"></script>

      </body>

    </html>

  </xsl:template>

  <!-- ══════════════════════════════════════════════════════════════
       TEMPLATE «render-pagina»
       Genera un <article class="pagina"> con due aree affiancate:
         1) FACSIMILE: immagine della pagina originale + zone calde
            posizionate in % sopra l'immagine, una per ogni <zone>
            della <surface> nel <facsimile>.
         2) TRASCRIZIONE: i blocchi di testo (head, p, cb, metamark,
            cit) che appartengono a questa pagina, determinati
            chiamando il template «pagina» per ciascun blocco e
            confrontando il risultato con $pageId.
       ══════════════════════════════════════════════════════════════ -->
  <xsl:template name="render-pagina">

    <xsl:param name="pb"/>
    <xsl:param name="articolo"/>
    <xsl:param name="closer"/>

    <!-- Variabili per collegare il <pb> alla <surface> nel <facsimile> e calcolare le coordinate -->
    <xsl:variable name="pageId" select="$pb/@xml:id"/>
    <xsl:variable name="facsId" select="substring-after($pb/@facs,'#')"/>
    <xsl:variable name="surface" select="root($pb)//tei:surface[@xml:id = $facsId]"/>
    <xsl:variable name="W" select="number(translate($surface/tei:graphic/@width,'px',''))"/>
    <xsl:variable name="H" select="number(translate($surface/tei:graphic/@height,'px',''))"/>

    <article class="pagina" id="pagina-{$pb/@n}-{generate-id($pb)}">

      <div class="facs">
        <div class="facs-inner">
          <img class="facs-img" src="{$surface/tei:graphic/@url}"
               alt="Pagina {$pb/@n} de La Farfalla"/>
          <xsl:if test="$W > 0 and $H > 0">
            <xsl:for-each select="$surface/tei:zone">
              <div class="zona-hot" data-zone="{@xml:id}"
                   data-coords="{@ulx},{@uly} → {@lrx},{@lry}"
                   style="left:{format-number(@ulx div $W*100,'0.##')}%;
                          top:{format-number(@uly div $H*100,'0.##')}%;
                          width:{format-number((@lrx - @ulx) div $W*100,'0.##')}%;
                          height:{format-number((@lry - @uly) div $H*100,'0.##')}%">
              </div>
            </xsl:for-each>
          </xsl:if>
        </div>
        <p class="facs-caption">
          <span class="facs-numPag">Pagina <xsl:value-of select="$pb/@n"/></span>
          <xsl:if test="$surface/tei:graphic/@width">
            <span class="facs-coords"
                  data-vuoto="{$surface/tei:graphic/@width} × {$surface/tei:graphic/@height}">
              <xsl:value-of select="$surface/tei:graphic/@width"/> × <xsl:value-of select="$surface/tei:graphic/@height"/>
            </span>
          </xsl:if>
        </p>
      </div>

      <!-- TRASCRIZIONE: seleziona tutti i blocchi significativi dell'articolo
           e per ciascuno chiama il template «pagina» per determinare a quale
           <pb> appartiene. Solo i blocchi che corrispondono a questa pagina
           ($pageId) vengono effettivamente processati. -->
      <div class="testo">
        <xsl:for-each select="$articolo//*[self::tei:head or self::tei:p
                              or (self::tei:cb and not(ancestor::tei:p))
                              or (self::tei:metamark and not(ancestor::tei:cit)) or self::tei:cit]">
          <xsl:variable name="paginaBlocco">
            <xsl:call-template name="pagina">
              <xsl:with-param name="n" select="."/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="$paginaBlocco = $pageId">
            <xsl:apply-templates select="."/>
          </xsl:if>
        </xsl:for-each>

        <!-- Blocchi del closer (signed, dateline) smistati per pagina -->
        <xsl:if test="$closer">
          <xsl:for-each select="$closer//*[self::tei:signed or self::tei:dateline]">
            <xsl:variable name="paginaCloser">
              <xsl:call-template name="pagina">
                <xsl:with-param name="n" select="."/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$paginaCloser = $pageId">
              <div class="chiusura">
                <xsl:apply-templates select="."/>
              </div>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </div>

    </article>

  </xsl:template>

  <!-- ═════════════════════════════════════════════════════════════════
       TEMPLATE PER BLOCCHI DI TESTO
       Ogni elemento TEI di livello blocco (cb, head, p, closer,
       signed, dateline, cit, quote, lg, l, metamark) ha un
       template dedicato che produce l'elemento HTML corrispondente.
       I template per head e p delegano al template «contenuto-blocco»
       per suddividere il contenuto in righe (<span class="riga">).
       ═════════════════════════════════════════════════════════════════ -->

  <!-- Banner "colonna N" per le pagine a due colonne -->
  <xsl:template match="tei:cb">
    <p class="colonna">colonna <xsl:value-of select="@n"/></p>
  </xsl:template>

  <!-- Titolo dell'articolo (<h2>), contenuto suddiviso in righe -->
  <xsl:template match="tei:head">
    <h2 class="blocco titolo"><xsl:call-template name="contenuto-blocco"/></h2>
  </xsl:template>

  <!-- Paragrafo, contenuto suddiviso in righe tramite contenuto-blocco -->
  <xsl:template match="tei:p">
    <p class="blocco"><xsl:call-template name="contenuto-blocco"/></p>
  </xsl:template>

  <!-- <div type="closer">: contenitore trasparente che non genera markup proprio.
       I suoi figli (signed, dateline) vengono processati dai rispettivi template,
       e il loro smistamento per pagina avviene dentro render-pagina -->
  <xsl:template match="tei:div[@type='closer']">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Firma dell'autore in fondo all'articolo -->
  <xsl:template match="tei:signed">
    <p class="blocco firma"><xsl:call-template name="contenuto-blocco"/></p>
  </xsl:template>

  <!-- Indicazione di luogo e data -->
  <xsl:template match="tei:dateline">
    <p class="blocco dateline"><xsl:call-template name="contenuto-blocco"/></p>
  </xsl:template>

  <!-- Citazione strutturata -->
  <xsl:template match="tei:cit">
    <blockquote class="citazione">
      <xsl:apply-templates select="tei:quote"/>
      <xsl:if test="tei:bibl">
        <cite class="bibl-cit">
          — <xsl:value-of select="normalize-space(tei:bibl)"/>
        </cite>
      </xsl:if>
    </blockquote>
  </xsl:template>

  <!-- Contenuto della citazione, dentro il <blockquote> generato da cit -->
  <xsl:template match="tei:quote">
    <div class="quote-inner">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- Gruppo di versi (stanza) -->
  <xsl:template match="tei:lg">
    <div class="stanza">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- Verso singolo -->
  <xsl:template match="tei:l">
    <xsl:variable name="lbVerso" select="tei:lb[1]"/>
    <span class="verso">
      <xsl:if test="$lbVerso/@facs">
        <xsl:attribute name="data-zone" select="substring-after($lbVerso/@facs, '#')"/>
      </xsl:if>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- Separatore decorativo nascosto agli screen reader con aria-hidden -->
  <xsl:template match="tei:metamark[@function='sectionDivider'][not(ancestor::tei:cit)]">
    <p class="separatore-decorativo" aria-hidden="true">
      <xsl:value-of select="normalize-space(.)"/>
    </p>
  </xsl:template>

  <!-- Metamark dentro cit: reso come span inline, non come <p> autonomo -->
  <xsl:template match="tei:metamark[ancestor::tei:cit]">
    <span class="separatore-decorativo" aria-hidden="true">
      <xsl:value-of select="normalize-space(.)"/>
    </span>
  </xsl:template>

  <!-- ═════════════════════════════════════════════════════════════════
       TEMPLATE «contenuto-blocco»
       Suddivide il contenuto di un blocco in righe e crea un
       gruppo per ogni riga della trascrizione.
       Ogni gruppo produce uno <span class="riga"> con:
         - data-zone = id della zona facsimile (dal @facs del <lb>),
           usato dal JavaScript per evidenziare la riga sull'immagine
         - classi CSS opzionali (r-centro, r-maiuscolo) da @rend
       Se il blocco non contiene <lb>, processa il contenuto senza
       raggruppamento.
       ═════════════════════════════════════════════════════════════════ -->
  <xsl:template name="contenuto-blocco">
    <xsl:choose>
      <xsl:when test=".//tei:lb">
        <xsl:variable name="rendBlocco" select="@rend"/>
        <xsl:for-each-group
            select="descendant::tei:lb | descendant::tei:cb
                    | descendant::node()[not(descendant::tei:lb or descendant::tei:cb)]
                                       [parent::*[descendant::tei:lb or descendant::tei:cb]]"
            group-starting-with="tei:lb | tei:cb">
          <xsl:variable name="lb" select="current-group()[1][self::tei:lb]"/>
          <xsl:variable name="cb" select="current-group()[1][self::tei:cb]"/>
          <xsl:choose>
            <!-- Gruppo iniziato da <cb>: emette solo il banner "colonna N" -->
            <xsl:when test="$cb">
              <span class="colonna">colonna <xsl:value-of select="$cb/@n"/></span>
            </xsl:when>
            <!-- Gruppo iniziato da <lb> (o contenuto non vuoto): genera uno <span class="riga"> -->
            <xsl:when test="$lb or normalize-space(string-join(current-group(),''))">
              <xsl:variable name="classeRigaCorrente">
                <xsl:choose>
                  <xsl:when test="$lb">
                    <xsl:call-template name="classeRiga">
                      <xsl:with-param name="rend" select="string-join(($rendBlocco, $lb/@rend), ' ')"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>riga</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <span class="{$classeRigaCorrente}">
                <xsl:if test="$lb/@facs">
                  <xsl:attribute name="data-zone" select="substring-after($lb/@facs,'#')"/>
                </xsl:if>
                <xsl:apply-templates select="current-group()[not(self::tei:lb)]" mode="riga"/>
              </span>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- MODE="riga": template attivati dentro i gruppi di contenuto-blocco.
       Gli elementi vengono delegati al proprio template senza mode. I nodi
       di testo vengono controllati: se il genitore è un elemento marcato,
       il testo viene avvolto in uno <span> con la classe CSS corretta, per
       preservare la colorazione anche quando il for-each-group ha spezzato
       l'elemento a cavallo di due righe. -->
  <xsl:template match="*" mode="riga">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <xsl:template match="text()" mode="riga">
    <xsl:variable name="genitoreInline" select="(
      parent::*[self::tei:title or self::tei:hi
                or self::tei:persName or self::tei:placeName
                or self::tei:orgName or self::tei:foreign
                or self::tei:term or self::tei:distinct
                or self::tei:name or self::tei:q or self::tei:rs]
      | parent::tei:w/parent::*[self::tei:title or self::tei:hi
                or self::tei:persName or self::tei:placeName
                or self::tei:orgName or self::tei:foreign
                or self::tei:term or self::tei:distinct
                or self::tei:name or self::tei:q or self::tei:rs]
    )[1]"/>
    <xsl:choose>
      <xsl:when test="$genitoreInline">
        <xsl:variable name="classeGenitore">
          <xsl:call-template name="classe">
            <xsl:with-param name="e" select="$genitoreInline"/>
          </xsl:call-template>
        </xsl:variable>
        <!-- Se il genitore ha @ref, ricrea un <a> con link all'appendice;
             altrimenti produce un semplice <span> con la classe CSS -->
        <xsl:variable name="refGenitore" select="$genitoreInline/@ref"/>
        <xsl:choose>
          <xsl:when test="contains($refGenitore, '#')">
            <a class="{$classeGenitore} int" href="#voce-{substring-after($refGenitore, '#')}">
              <xsl:value-of select="."/>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <span class="{$classeGenitore}">
              <xsl:value-of select="."/>
            </span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- <lb> soppresso intenzionalmente: il suo ruolo di delimitatore di riga
       è già stato consumato dal raggruppamento in contenuto-blocco.
       Senza questo template vuoto, la regola built-in di XSLT processerebbe i figli. -->
  <xsl:template match="tei:lb"/>

  <!-- ════════════════════════════════════════
       ELEMENTI INLINE — ENTITÀ NOMINATE
       Ogni tipo di entità delega al template
       «entita-inline» passando la classe CSS.
       ════════════════════════════════════════ -->

  <xsl:template match="tei:persName">
    <xsl:call-template name="entita-inline">
      <xsl:with-param name="cls" select="'persona'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:placeName">
    <xsl:call-template name="entita-inline">
      <xsl:with-param name="cls" select="'luogo'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:orgName">
    <xsl:call-template name="entita-inline">
      <xsl:with-param name="cls" select="'organizzazione'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:rs[@type='person']">
    <xsl:call-template name="entita-inline">
      <xsl:with-param name="cls">persona</xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:rs[@type='work']">
    <xsl:choose>
      <xsl:when test="contains(@ref, '#')">
        <a class="opera int" href="#voce-{substring-after(@ref,'#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><span class="opera"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:rs">
    <span class="testo"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- ═══════════════════════════════════════
       ENTITA-INLINE — LOGICA DI COLLEGAMENTO
       Gestisce l'unico pattern di @ref 
       ═══════════════════════════════════════ -->
  <xsl:template name="entita-inline">
    <xsl:param name="cls"/>
    <xsl:choose>
      <!-- Caso 1: riferimento a entita_nominate.xml#id -->
      <xsl:when test="contains(@ref,'entita_nominate.xml#')">
        <a class="{$cls} int" href="#voce-{substring-after(@ref,'#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <!-- Caso 2: nessun ref o formato non riconosciuto -->
      <xsl:otherwise><span class="{$cls}"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ════════════════════════════════════════════════════════════
       ALTRI ELEMENTI INLINE
       Titoli (opere e periodici), termini, parole straniere,
       espressioni idiomatiche, corsivi, testo incerto, discorso
       diretto. Ciascuno produce un <span> o <em> con classe CSS
       dedicata; quelli con @ref generano un <a> verso l'appendice.
       ════════════════════════════════════════════════════════════ -->

  <xsl:template match="tei:title[@type='periodical']">
    <xsl:choose>
      <xsl:when test="contains(@ref, '#')">
        <a class="periodico int" href="#voce-{substring-after(@ref,'#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><span class="periodico"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:title">
    <xsl:choose>
      <xsl:when test="contains(@ref, '#')">
        <a class="opera int" href="#voce-{substring-after(@ref,'#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><span class="opera"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:term[@type='theme']">
    <xsl:choose>
      <xsl:when test="contains(@ref, '#')">
        <a class="tema int" href="#voce-{substring-after(@ref,'#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><span class="tema"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:term"><span class="termine"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:foreign"><span class="straniero" title="lingua: {@xml:lang}"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:distinct"><span class="espressione" title="tipo: {@type}"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:name[@type='epithet'][@ref]">
    <xsl:call-template name="entita-inline">
      <xsl:with-param name="cls" select="'persona'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="tei:name"><span class="nome"><xsl:apply-templates/></span></xsl:template>

  <xsl:template match="tei:hi[@rend='italic']"><em class="corsivo"><xsl:apply-templates/></em></xsl:template>

  <xsl:template match="tei:unclear">
    <span class="testo-incerto" title="Lettura incerta: {normalize-space(.)} (certezza: {@cert})">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="tei:q"><span class="discorso-diretto"><xsl:apply-templates/></span></xsl:template>

  <!-- Elementi passanti (non aggiungono markup) -->
  <xsl:template match="tei:w"><xsl:apply-templates/></xsl:template>
  <xsl:template match="tei:bibl"><xsl:apply-templates/></xsl:template>
  <xsl:template match="tei:pb"/>

  <!-- Elementi di header e facsimile esclusi dal processing generico -->
  <xsl:template match="tei:teiHeader | tei:facsimile"/>

  <!-- ═══════════════════════════════════════════════════════════
       TEMPLATE «voce-legenda»
       Genera un <li> per la legenda laterale. Chiamato dal
       template radice (una per tipo di entità/markup).
       L'attributo data-target è usato dal JavaScript per
       attivare/disattivare l'evidenziazione nel testo.
       ═══════════════════════════════════════════════════════════ -->
  <xsl:template name="voce-legenda">
    <xsl:param name="cls"/>
    <xsl:param name="et"/>
    <xsl:param name="desc"/>
    <li class="leg-voce" data-target="show-{$cls}" tabindex="0">
      <span class="leg-sw {$cls}-sw"></span>
      <span class="leg-txt"><xsl:value-of select="$desc"/></span>
      <code class="leg-el">&lt;<xsl:value-of select="$et"/>&gt;</code>
    </li>
  </xsl:template>

  <!-- ═════════════════════════════════════════════════════════════
       TEMPLATE «appendice-entita»
       Genera la <section class="appendice"> in fondo alla pagina.
       Richiama «lista-entita» e «lista-temi» passando come $voci
       i nodi selezionati dalla variabile globale $ent. Ogni voce
       prodotta avrà id="voce-{xml:id}" corrispondente ai frammenti
       d'àncora usati nei link del testo.
       ═════════════════════════════════════════════════════════════ -->
  <xsl:template name="appendice-entita">
    <section class="appendice">
      <h2>Appendice — Entità nominate</h2>
      <p class="app-intro"> I nomi marcati nel testo rimandano alla voce corrispondente, dove disponibile.</p>

      <xsl:call-template name="lista-entita">
        <xsl:with-param name="voci" select="$ent//tei:listPerson/(tei:person|tei:personGrp)"/>
        <xsl:with-param name="tit" select="'Persone'"/>
        <xsl:with-param name="el" select="'persName'"/>
      </xsl:call-template>

      <xsl:call-template name="lista-entita">
        <xsl:with-param name="voci" select="$ent//tei:listPlace/tei:place"/>
        <xsl:with-param name="tit" select="'Luoghi'"/>
        <xsl:with-param name="el" select="'placeName'"/>
      </xsl:call-template>

      <xsl:call-template name="lista-entita">
        <xsl:with-param name="voci" select="$ent//tei:listOrg/tei:org"/>
        <xsl:with-param name="tit" select="'Enti e case editrici'"/>
        <xsl:with-param name="el" select="'orgName'"/>
      </xsl:call-template>

      <xsl:call-template name="lista-entita">
        <xsl:with-param name="voci" select="$ent//tei:listBibl[@type='opere']/tei:biblStruct"/>
        <xsl:with-param name="tit" select="'Opere citate'"/>
        <xsl:with-param name="el" select="'title'"/>
      </xsl:call-template>

      <xsl:call-template name="lista-temi">
        <xsl:with-param name="voci" select="$ent//tei:taxonomy/tei:category"/>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- ═══════════════════════════════════════════════════════════
       TEMPLATE «lista-entita»
       Template generico riusabile per generare una sotto-sezione
       dell'appendice. Riceve una sequenza di voci TEI ($voci),
       le ordina alfabeticamente per nome e per ciascuna genera
       un <li id="voce-{xml:id}"> contenente:
         - nome dell'entità
         - link esterno
         - nota descrittiva
         - dettagli specifici per tipo
       ═══════════════════════════════════════════════════════════ -->
  <xsl:template name="lista-entita">
    <xsl:param name="voci"/>
    <xsl:param name="tit"/>
    <xsl:param name="el"/>
    <xsl:if test="$voci">
      <div class="app-gruppo">
        <h3><xsl:value-of select="$tit"/>
          <span class="app-el"> &lt;<xsl:value-of select="$el"/>&gt;</span>
        </h3>
        <ul class="app-lista">
          <xsl:for-each select="$voci">
            <xsl:sort select="lower-case(normalize-space(
              if ($el='persName') then (.//tei:persName)[1]
              else if ($el='orgName') then (.//tei:orgName)[1]
              else if ($el='placeName') then (.//tei:placeName)[1]
              else (.//tei:title)[1]
            ))"/>

            <!-- Costruisce il nome della voce in base al tipo di entità ($el).
                 Per le persone: se ha uno pseudonimo, lo mostra come nome
                 principale con il nome reale tra parentesi; per <personGrp> senza
                 <persName> genera "Famiglia + cognome" -->
            <xsl:variable name="nome">
              <xsl:choose>
                <xsl:when test="$el = 'persName'">
                  <xsl:variable name="pn" select="(.//tei:persName)[1]"/>
                  <xsl:choose>
                    <xsl:when test="not($pn)">
                      <span class="app-nome-gruppo">
                        <xsl:text>Famiglia </xsl:text>
                        <xsl:value-of select="normalize-space(
                          if (self::tei:personGrp/@n) then concat(upper-case(substring(@xml:id,1,1)), substring(@xml:id,2))
                          else @xml:id
                        )"/>
                      </span>
                    </xsl:when>
                    <xsl:when test="$pn/tei:addName[@type='pseudonym']">
                      <span class="app-nome-principale">
                        <xsl:value-of select="$pn/tei:addName[@type='pseudonym']"/>
                      </span>
                      <span class="app-nome-reale">
                        <xsl:text> (</xsl:text>
                        <xsl:for-each select="$pn/tei:forename | $pn/tei:surname">
                          <xsl:if test="position() > 1"><xsl:text> </xsl:text></xsl:if>
                          <xsl:value-of select="."/>
                        </xsl:for-each>
                        <xsl:text>)</xsl:text>
                      </span>
                      <xsl:if test="$pn/tei:addName[@type='title']">
                        <span class="app-titolo-nobiliare">
                          <xsl:text>, </xsl:text>
                          <xsl:value-of select="$pn/tei:addName[@type='title']"/>
                        </span>
                      </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:for-each select="$pn/tei:forename | $pn/tei:surname | $pn/tei:roleName">
                        <xsl:if test="position() > 1"><xsl:text> </xsl:text></xsl:if>
                        <xsl:value-of select="."/>
                      </xsl:for-each>
                      <xsl:if test="$pn/tei:addName[@type='title']">
                        <span class="app-titolo-nobiliare">
                          <xsl:text>, </xsl:text>
                          <xsl:value-of select="$pn/tei:addName[@type='title']"/>
                        </span>
                      </xsl:if>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="$el = 'orgName'">
                  <xsl:value-of select="normalize-space((.//tei:orgName)[1])"/>
                </xsl:when>
                <xsl:when test="$el = 'placeName'">
                  <xsl:value-of select="normalize-space((.//tei:placeName)[1])"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="normalize-space((.//tei:title)[1])"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <!-- Cerca il primo URL disponibile tra ref/@target, @ref e idno[@type='VIAF'] -->
            <xsl:variable name="link"
              select="(.//tei:ref/@target[starts-with(.,'http')]
                       | .//*/@ref[starts-with(.,'http')]
                       | .//tei:idno[@type='VIAF'])[1]"/>

            <!-- Testo della prima <note> della voce, usato come tooltip e come testo visibile -->
            <xsl:variable name="nota" select="normalize-space(tei:note[1])"/>

            <li id="voce-{@xml:id}">
              <span class="app-nome" title="{$nota}"><xsl:copy-of select="$nome"/></span>

              <!-- Dettagli biografici per le persone -->
              <xsl:if test="$el = 'persName'">
                <xsl:if test="tei:birth/tei:date or tei:death/tei:date">
                  <span class="app-date">
                    (<xsl:value-of select="tei:birth/tei:date"/>–<xsl:value-of select="tei:death/tei:date"/>)
                  </span>
                </xsl:if>
                <xsl:if test=".//tei:persName/@type">
                  <span class="app-tipo">
                    <xsl:choose>
                      <xsl:when test=".//tei:persName/@type = 'real'">Personaggio storico</xsl:when>
                      <xsl:when test=".//tei:persName/@type = 'fictional'">Personaggio letterario</xsl:when>
                    </xsl:choose>
                  </span>
                </xsl:if>
              </xsl:if>

              <!-- Dettagli per i luoghi -->
              <xsl:if test="$el = 'placeName' and tei:country">
                <span class="app-paese"> — <xsl:value-of select="tei:country"/></span>
              </xsl:if>

              <!-- Dettagli bibliografici per le opere -->
              <xsl:if test="$el = 'title' and .//tei:monogr">
                <span class="app-biblio">
                  <xsl:value-of select="normalize-space(.//tei:monogr/tei:author)"/>
                  <xsl:if test=".//tei:monogr/tei:imprint/tei:publisher">
                    · <xsl:value-of select="normalize-space((.//tei:monogr/tei:imprint/tei:publisher)[1])"/>
                  </xsl:if>
                  <xsl:if test=".//tei:monogr/tei:imprint/tei:pubPlace">
                    , <xsl:value-of select="normalize-space(.//tei:monogr/tei:imprint/tei:pubPlace)"/>
                  </xsl:if>
                  <xsl:if test=".//tei:monogr/tei:imprint/tei:date">
                    (<xsl:value-of select=".//tei:monogr/tei:imprint/tei:date"/>)
                  </xsl:if>
                </span>
              </xsl:if>

              <!-- Link scheda esterna -->
              <xsl:if test="$link">
                <xsl:text> </xsl:text>
                <a class="app-ref" href="{$link}" target="_blank" rel="noopener">scheda ↗</a>
              </xsl:if>

              <!-- Nota descrittiva -->
              <xsl:if test="$nota">
                <span class="app-nota"><xsl:value-of select="$nota"/></span>
              </xsl:if>

              <!-- Sede dell'organizzazione -->
              <xsl:if test="$el = 'orgName' and tei:placeName">
                <span class="app-paese"> — <xsl:value-of select="normalize-space(tei:placeName)"/></span>
              </xsl:if>

              <!-- Descrizione per le organizzazioni -->
              <xsl:if test="$el = 'orgName' and tei:desc">
                <span class="app-desc"><xsl:value-of select="normalize-space(tei:desc)"/></span>
              </xsl:if>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ═════════════════════════════════════════════════════════
       TEMPLATE «lista-temi»
       Specifico per le <category> della <taxonomy> tematica.
       Per ogni categoria, il nome del tema è estratto da
       catDesc/term, e la descrizione è la porzione di catDesc
       dopo i due punti (substring-after).
       Le voci sono ordinate alfabeticamente per nome del tema.
       ═════════════════════════════════════════════════════════ -->
  <xsl:template name="lista-temi">
    <xsl:param name="voci"/>
    <xsl:if test="$voci">
      <div class="app-gruppo">
        <h3>Temi <span class="app-el">&lt;taxonomy&gt;</span></h3>
        <ul class="app-lista">
          <xsl:for-each select="$voci">
            <xsl:sort select="lower-case(normalize-space(tei:catDesc/tei:term))"/>
            <li id="voce-{@xml:id}">
              <span class="app-nome"><xsl:value-of select="normalize-space(tei:catDesc/tei:term)"/></span>
              <span class="app-nota"><xsl:value-of select="normalize-space(substring-after(tei:catDesc, ':'))"/></span>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>