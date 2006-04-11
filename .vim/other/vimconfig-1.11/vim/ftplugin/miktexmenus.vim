"        File: miktexmacro2.vim
"      Author: Mikolaj Machowski <mikmach@wp.pl>
" Description: 
" 
" Installation:
"      History: pluginized by Srinath Avadhanula <srinath AT fastmail.fm>
"         TODO:
"=============================================================================

nmap <silent> <script> <plug> i
imap <silent> <script> <C-o><plug> <Nop>

" " the following 2 menus are supposed to be equivalent to each other according
" " to the docs, but only the first one works.
" vmenu Test1.Test <esc><plug><C-r>=TeX_itemize("itemize")<cr>
" amenu Test2.Test <plug><C-r>=TeX_itemize("itemize")<cr>

" MATH {{{1
" brackets and dollars {{{2
let pA = 'amenu <silent> 85 &Math.'
exe pA.'\\&[\ \\]                 <plug>\[\]<Left><Left>'
exe pA.'\\&(\ \\)                 <plug>\(\)<Left><Left>'
exe pA.'&$\                       <plug>$<tab>$$ $$'
exe pA.'-sepmath1- :'
" 2}}}
" MATH arrows {{{
let pA1 = pA."&Arrows."
exe pA1.'Leftarrow                <plug>\leftarrow '
exe pA1.'leftarrow                <plug>\leftarrow'
exe pA1.'longleftarrow            <plug>\longleftarrow '
exe pA1.'Leftarrow                <plug>\Leftarrow '
exe pA1.'Longleftarrow            <plug>\Longleftarrow '
exe pA1.'rightarrow               <plug>\rightarrow '
exe pA1.'longrightarrow           <plug>\longrightarrow '
exe pA1.'Rightarrow               <plug>\Rightarrow '
exe pA1.'Longrightarrow           <plug>\Longrightarrow '
exe pA1.'leftrightarrow           <plug>\leftrightarrow '
exe pA1.'longleftrightarrow       <plug>\longleftrightarrow '
exe pA1.'Leftrightarrow           <plug>\Leftrightarrow '
exe pA1.'Longleftrightarrow       <plug>\Longleftrightarrow '
exe pA1.'uparrow                  <plug>\uparrow '
exe pA1.'Uparrow                  <plug>\Uparrow '
exe pA1.'downarrow                <plug>\downarrow '
exe pA1.'Downarrow                <plug>\Downarrow '
exe pA1.'updownarrow              <plug>\updownarrow '
exe pA1.'Updownarrow              <plug>\Updownarrow '
exe pA1.'nearrow                  <plug>\nearrow '
exe pA1.'searrow                  <plug>\searrow '
exe pA1.'swarrow                  <plug>\swarrow '
exe pA1.'nwarrow                  <plug>\nwarrow '
exe pA1.'mapsto                   <plug>\mapsto '
exe pA1.'longmapsto               <plug>\longmapsto '
exe pA1.'hookleftarrow            <plug>\hookleftarrow '
exe pA1.'hookrightarrow           <plug>\hookrightarrow '
exe pA1.'leftharpoonup            <plug>\leftharpoonup '
exe pA1.'leftharpoondown          <plug>\leftharpoondown '
exe pA1.'rightharpoonup           <plug>\rightharpoonup '
exe pA1.'rightharpoondown         <plug>\rightharpoondown '
exe pA1.'rightleftharpoons        <plug>\rightleftharpoons '
exe pA1.'Leftarrow                <plug>\Leftarrow'
" }}}
" MATH nArrows {{{
let pA1a = pA."&nArrows."
exe pA1a.'nleftarrow              <plug>\nleftarrow '
exe pA1a.'nLeftarrow              <plug>\nLeftarrow '
exe pA1a.'nleftrightarrow         <plug>\nleftrightarrow '
exe pA1a.'nrightarrow             <plug>\nrightarrow '
exe pA1a.'nRightarrow             <plug>\nRightarrow '
" }}}
" MATH Fonts {{{
let pA2a = pA."&MathFonts."
exe pA2a.'mathbf{}                <plug><C-r>=TeX_PutText("\\mathbf{ää}«»")<cr>'
exe pA2a.'mathrm{}                <plug><C-r>=TeX_PutText("\\mathrm{ää}«»")<cr>'
exe pA2a.'mathsf{}                <plug><C-r>=TeX_PutText("\\mathsf{ää}«»")<cr>'
exe pA2a.'mathtt{}                <plug><C-r>=TeX_PutText("\\mathtt{ää}«»")<cr>'
exe pA2a.'mathit{}                <plug><C-r>=TeX_PutText("\\mathit{ää}«»")<cr>'
exe pA2a.'mathfrak{}              <plug><C-r>=TeX_PutText("\\mathfrak{ää}«»")<cr>'
exe pA2a.'mathcal{}               <plug><C-r>=TeX_PutText("\\mathcal{ää}«»")<cr>'
exe pA2a.'mathscr{}               <plug><C-r>=TeX_PutText("\\mathscr{ää}«»")<cr>'
exe pA2a.'mathbb{}                <plug><C-r>=TeX_PutText("\\mathbb{ää}«»")<cr>'
" }}}
" Greek Letters small {{{
let pA2 = pA."&Greek.&Small."
exe pA2.'alpha                    <plug>\alpha '
exe pA2.'beta                     <plug>\beta '
exe pA2.'gamma                    <plug>\gamma '
exe pA2.'delta                    <plug>\delta '
exe pA2.'epsilon                  <plug>\epsilon '
exe pA2.'varepsilon               <plug>\varepsilon '
exe pA2.'zeta                     <plug>\zeta '
exe pA2.'eta                      <plug>\eta '
exe pA2.'theta                    <plug>\theta '
exe pA2.'vartheta                 <plug>\vartheta '
exe pA2.'iota                     <plug>\iota '
exe pA2.'kappa                    <plug>\kappa '
exe pA2.'lambda                   <plug>\lambda '
exe pA2.'mu                       <plug>\mu '
exe pA2.'nu                       <plug>\nu '
exe pA2.'xi                       <plug>\xi '
exe pA2.'pi                       <plug>\pi '
exe pA2.'varpi                    <plug>\varpi '
exe pA2.'rho                      <plug>\rho '
exe pA2.'varrho                   <plug>\varrho '
exe pA2.'sigma                    <plug>\sigma '
exe pA2.'varsigma                 <plug>\varsigma '
exe pA2.'tau                      <plug>\tau '
exe pA2.'upsilon                  <plug>\upsilon '
exe pA2.'phi                      <plug>\phi '
exe pA2.'varphi                   <plug>\varphi '
exe pA2.'chi                      <plug>\chi '
exe pA2.'psi                      <plug>\psi '
exe pA2.'omega                    <plug>\omega '
" }}}
" Greek Letters big {{{
let pA3 = pA.'&Greek.&Big.' "TODO: dorobiæ inne wielkie litery greckie
exe pA3.'Gamma                    <plug>\Gamma '
exe pA3.'Delta                    <plug>\Delta '
exe pA3.'Theta                    <plug>\Theta '
exe pA3.'Lambda                   <plug>\Lambda '
exe pA3.'Xi                       <plug>\Xi '
exe pA3.'Pi                       <plug>\Pi '
exe pA3.'Sigma                    <plug>\Sigma '
exe pA3.'Upsilon                  <plug>\Upsilon '
exe pA3.'Upsilon                  <plug>\Upsilon '
exe pA3.'Phi                      <plug>\Phi '
exe pA3.'Psi                      <plug>\Psi '
exe pA3.'Omega                    <plug>\Omega '
" }}}
" BinaryRel1 {{{
let pA4 = pA."&BinaryRel1."  
exe pA4.'ll                       <plug>\ll '
exe pA4.'lll                      <plug>\lll '
exe pA4.'leqslant                 <plug>\leqslant '
exe pA4.'leq                      <plug>\leq '
exe pA4.'leqq                     <plug>\leqq '
exe pA4.'eqslantless              <plug>\eqslantless '
exe pA4.'lessdot                  <plug>\lessdot '
exe pA4.'prec                     <plug>\prec '
exe pA4.'preceq                   <plug>\preceq '
exe pA4.'preccurlyeq              <plug>\preccurlyeq '
exe pA4.'curlyeqprec              <plug>\curlyeqprec '
exe pA4.'lessim                   <plug>\lessim '
exe pA4.'lessapprox               <plug>\lessapprox '
exe pA4.'precsim                  <plug>\precsim '
exe pA4.'precapprox               <plug>\precapprox '
exe pA4.'in                       <plug>\in '
exe pA4.'subset                   <plug>\subset '
exe pA4.'Subset                   <plug>\Subset '
exe pA4.'subseteq                 <plug>\subseteq '
exe pA4.'subseteqq                <plug>\subseteqq '
exe pA4.'sqsubset                 <plug>\sqsubset '
exe pA4.'sqsubseteq               <plug>\sqsubseteq '
exe pA4.'smile                    <plug>\smile '
exe pA4.'smallsmile               <plug>\smallsmile '
exe pA4.'parallel                 <plug>\parallel '
exe pA4.'shortparallel            <plug>\shortparallel '
exe pA4.'dashv                    <plug>\dashv '
exe pA4.'vdash                    <plug>\vdash '
exe pA4.'vDash                    <plug>\vDash '
exe pA4.'models                   <plug>\models '
exe pA4.'therefore                <plug>\therefore '
exe pA4.'backepsilon              <plug>\backepsilon '
" }}}
" nBinaryRel1 {{{ 
let pA4a = pA."&nBinaryRel1."  
exe pA4a.'nless                   <plug>\nless '
exe pA4a.'nleqslant               <plug>\nleqslant '
exe pA4a.'nleq                    <plug>\nleq '
exe pA4a.'lneq                    <plug>\lneq '
exe pA4a.'nleqq                   <plug>\nleqq '
exe pA4a.'lneqq                   <plug>\lneqq '
exe pA4a.'lvertneqq               <plug>\lvertneqq '
exe pA4a.'nprec                   <plug>\nprec '
exe pA4a.'npreceq                 <plug>\npreceq '
exe pA4a.'precneqq                <plug>\precneqq '
exe pA4a.'lnsim                   <plug>\lnsim '
exe pA4a.'lnapprox                <plug>\lnapprox '
exe pA4a.'precnsim                <plug>\precnsim '
exe pA4a.'precnapprox             <plug>\precnapprox '
exe pA4a.'notin                   <plug>\notin '
exe pA4a.'nsubseteq               <plug>\nsubseteq '
exe pA4a.'varsubsetneq            <plug>\varsubsetneq '
exe pA4a.'subsetneq               <plug>\subsetneq '
exe pA4a.'nsubseteqq              <plug>\nsubseteqq '
exe pA4a.'varsubsetneqq           <plug>\varsubsetneqq '
exe pA4a.'subsetneqq              <plug>\subsetneqq '
exe pA4a.'nparallel               <plug>\nparallel '
exe pA4a.'nshortparallel          <plug>\nshortparallel '
exe pA4a.'nvdash                  <plug>\nvdash '
exe pA4a.'nvDash                  <plug>\nvDash '
" }}}
" BinaryRel2 {{{ 
let pA5 = pA."&BinaryRel2."  
exe pA5.'gg                       <plug>\gg '
exe pA5.'ggg                      <plug>\ggg '
exe pA5.'gggtr                    <plug>\gggtr '
exe pA5.'geqslant                 <plug>\geqslant '
exe pA5.'geq                      <plug>\geq '
exe pA5.'geqq                     <plug>\geqq '
exe pA5.'eqslantgtr               <plug>\eqslantgtr '
exe pA5.'gtrdot                   <plug>\gtrdot '
exe pA5.'succ                     <plug>\succ '
exe pA5.'succeq                   <plug>\succeq '
exe pA5.'succcurllyeq             <plug>\succcurllyeq '
exe pA5.'curlyeqsucc              <plug>\curlyeqsucc '
exe pA5.'gtrsim                   <plug>\gtrsim '
exe pA5.'gtrapprox                <plug>\gtrapprox '
exe pA5.'succsim                  <plug>\succsim '
exe pA5.'succapprox               <plug>\succapprox '
exe pA5.'ni                       <plug>\ni '
exe pA5.'owns                     <plug>\owns '
exe pA5.'supset                   <plug>\supset '
exe pA5.'Supset                   <plug>\Supset '
exe pA5.'supseteq                 <plug>\supseteq '
exe pA5.'supseteqq                <plug>\supseteqq '
exe pA5.'sqsupset                 <plug>\sqsupset '
exe pA5.'sqsupseteq               <plug>\sqsupseteq '
exe pA5.'frown                    <plug>\frown '
exe pA5.'smallfrown               <plug>\smallfrown '
exe pA5.'mid                      <plug>\mid '
exe pA5.'shortmid                 <plug>\shortmid '
exe pA5.'between                  <plug>\between '
exe pA5.'Vdash                    <plug>\Vdash '
exe pA5.'bowtie                   <plug>\bowtie '
exe pA5.'Join                     <plug>\Join '
exe pA5.'pitchfork                <plug>\pitchfork '
" }}}
" {{{ BinaryRel2
let pA5a = pA."n&BinaryRel2."  "TODO: dorobiæ logarytmy
exe pA5a.'ngtr                    <plug>\ngtr '
exe pA5a.'ngeqslant               <plug>\ngeqslant '
exe pA5a.'ngeq                    <plug>\ngeq '
exe pA5a.'gneq                    <plug>\gneq '
exe pA5a.'ngeqq                   <plug>\ngeqq '
exe pA5a.'gneqq                   <plug>\gneqq '
exe pA5a.'nsucc                   <plug>\nsucc '
exe pA5a.'nsucceq                 <plug>\nsucceq '
exe pA5a.'succneq                 <plug>\succneq '
exe pA5a.'gnsim                   <plug>\gnsim '
exe pA5a.'gnapprox                <plug>\gnapprox '
exe pA5a.'succnsim                <plug>\succnsim '
exe pA5a.'succnapprox             <plug>\succnapprox '
exe pA5a.'nsupseteq               <plug>\nsupseteq '
exe pA5a.'varsupsetneq            <plug>\varsupsetneq '
exe pA5a.'supsetneq               <plug>\supsetneq '
exe pA5a.'nsupseteqq              <plug>\nsupseteqq '
exe pA5a.'varsupsetneqq           <plug>\varsupsetneqq '
exe pA5a.'supsetneqq              <plug>\supsetneqq '
exe pA5a.'nmid                    <plug>\nmid '
exe pA5a.'nshortmid               <plug>\nshortmid '
exe pA5a.'nVdash                  <plug>\nVdash '
" }}}
" {{{ BinaryRel3
let pA6 = pA."&BinaryRel3."  
exe pA6.'doteq                    <plug>\doteq '
exe pA6.'circeq                   <plug>\circeq '
exe pA6.'eqcirc                   <plug>\eqcirc '
exe pA6.'risingdotseq             <plug>\risingdotseq '
exe pA6.'doteqdot                 <plug>\doteqdot '
exe pA6.'Doteq                    <plug>\Doteq '
exe pA6.'fallingdotseq            <plug>\fallingdotseq '
exe pA6.'triangleeq               <plug>\triangleeq '
exe pA6.'bumpeq                   <plug>\bumpeq '
exe pA6.'Bumpeq                   <plug>\Bumpeq '
exe pA6.'equiv                    <plug>\equiv '
exe pA6.'sim                      <plug>\sim '
exe pA6.'thicksim                 <plug>\thicksim '
exe pA6.'backsim                  <plug>\backsim '
exe pA6.'simeq                    <plug>\simeq '
exe pA6.'backsimeq                <plug>\backsimeq '
exe pA6.'cong                     <plug>\cong '
exe pA6.'approx                   <plug>\approx '
exe pA6.'thickapprox              <plug>\thickapprox '
exe pA6.'approxeq                 <plug>\approxeq '
exe pA6.'blacktriangleleft        <plug>\blacktriangleleft '
exe pA6.'vartriangleleft          <plug>\vartriangleleft '
exe pA6.'trianglelefteq           <plug>\trianglelefteq '
exe pA6.'blacktriangleright       <plug>\blacktriangleright '
exe pA6.'vartriangleright         <plug>\vartriangleright '
exe pA6.'trianglerighteq          <plug>\trianglerighteq '
exe pA6.'perp                     <plug>\perp '
exe pA6.'asymp                    <plug>\asymp '
exe pA6.'Vvdash                   <plug>\Vvdash '
exe pA6.'propto                   <plug>\propto '
exe pA6.'varpropto                <plug>\varpropto '
exe pA6.'because                  <plug>\because '
" }}}
" {{{ nBinaryRel3
let pA6a = pA."&nBinaryRel3."
exe pA6a.'neq                     <plug>\neq '
exe pA6a.'nsim                    <plug>\nsim '
exe pA6a.'ncong                   <plug>\ncong '
exe pA6a.'ntriangleleft           <plug>\ntriangleleft '
exe pA6a.'ntrianglelefteq         <plug>\ntrianglelefteq '
exe pA6a.'ntriangleright          <plug>\ntriangleright '
exe pA6a.'ntrianglerighteq        <plug>\ntrianglerighteq '
" }}}
" {{{ BinaryRel4
let pA7 = pA."&BinaryRel4."  
exe pA7.'lessgtr                  <plug>\lessgtr '
exe pA7.'gtrless                  <plug>\gtrless '
exe pA7.'lesseqgtr                <plug>\lesseqgtr '
exe pA7.'gtreqless                <plug>\gtreqless '
exe pA7.'lesseqqgtr               <plug>\lesseqqgtr '
exe pA7.'gtreqqless               <plug>\gtreqqless '
" }}}
" {{{ BigOp
let pA8a = pA."&BigOp."
exe pA8a.'limits                  <plug>\limits'
exe pA8a.'nolimits                <plug>\nolimits'
exe pA8a.'displaylimits           <plug>\displaylimits'
exe pA8a.'-seplimits- :'
exe pA8a.'bigcap                  <plug>\bigcap'
exe pA8a.'bigcup                  <plug>\bigcup'
exe pA8a.'bigodot                 <plug>\bigodot'
exe pA8a.'bigoplus                <plug>\bigoplus'
exe pA8a.'bigotimes               <plug>\bigotimes'
exe pA8a.'bigsqcup                <plug>\bigsqcup'
exe pA8a.'biguplus                <plug>\biguplus'
exe pA8a.'bigvee                  <plug>\bigvee'
exe pA8a.'bigwedge                <plug>\bigwedge'
exe pA8a.'coprod                  <plug>\coprod'
exe pA8a.'int                     <plug>\int'
exe pA8a.'oint                    <plug>\oint'
exe pA8a.'prod                    <plug>\prod'
exe pA8a.'sum                     <plug>\sum'
" }}}
" {{{ BinaryOp
let pA8 = pA."&BinaryOp."
exe pA8.'pm                       <plug>\pm '
exe pA8.'mp                       <plug>\mp '
exe pA8.'dotplus                  <plug>\dotplus '
exe pA8.'cdot                     <plug>\cdot '
exe pA8.'centerdot                <plug>\centerdot '
exe pA8.'times                    <plug>\times '
exe pA8.'ltimes                   <plug>\ltimes '
exe pA8.'rtimes                   <plug>\rtimes '
exe pA8.'leftthreetimes           <plug>\leftthreetimes '
exe pA8.'rightthreetimes          <plug>\rightthreetimes '
exe pA8.'div                      <plug>\div '
exe pA8.'divideontimes            <plug>\divideontimes '
exe pA8.'bmod                     <plug>\bmod '
exe pA8.'ast                      <plug>\ast '
exe pA8.'star                     <plug>\star '
exe pA8.'setminus                 <plug>\setminus '
exe pA8.'smallsetminus            <plug>\smallsetminus '
exe pA8.'diamond                  <plug>\diamond '
exe pA8.'wr                       <plug>\wr '
exe pA8.'intercal                 <plug>\intercal '
exe pA8.'circ                     <plug>\circ '
exe pA8.'bigcirc                  <plug>\bigcirc '
exe pA8.'bullet                   <plug>\bullet '
exe pA8.'cap                      <plug>\cap '
exe pA8.'Cap                      <plug>\Cap '
exe pA8.'cup                      <plug>\cup '
exe pA8.'Cup                      <plug>\Cup '
exe pA8.'sqcap                    <plug>\sqcap '
exe pA8.'sqcup                    <plug>\sqcup'
exe pA8.'amalg                    <plug>\amalg '
exe pA8.'uplus                    <plug>\uplus '
exe pA8.'triangleleft             <plug>\triangleleft '
exe pA8.'amalg                    <plug>\amalg '
exe pA8.'triangleright            <plug>\triangleright '
exe pA8.'bigtriangleup            <plug>\bigtriangleup '
exe pA8.'bigtriangledown          <plug>\bigtriangledown '
exe pA8.'vee                      <plug>\vee '
exe pA8.'veebar                   <plug>\veebar '
exe pA8.'curlyvee                 <plug>\curlyvee '
exe pA8.'wedge                    <plug>\wedge '
exe pA8.'barwedge                 <plug>\barwedge '
exe pA8.'doublebarwedge           <plug>\doublebarwedge '
exe pA8.'curlywedge               <plug>\curlywedge '
exe pA8.'oplus                    <plug>\oplus '
exe pA8.'ominus                   <plug>\ominus '
exe pA8.'otimes                   <plug>\otimes '
exe pA8.'oslash                   <plug>\oslash '
exe pA8.'boxplus                  <plug>\boxplus '
exe pA8.'boxminus                 <plug>\boxminus '
exe pA8.'boxtimes                 <plug>\boxtimes '
exe pA8.'boxdot                   <plug>\boxdot '
exe pA8.'odot                     <plug>\odot '
exe pA8.'circledast               <plug>\circledast '
exe pA8.'circleddash              <plug>\circleddash '
exe pA8.'circledcirc              <plug>\circledcirc '
exe pA8.'dagger                   <plug>\dagger '
exe pA8.'ddagger                  <plug>\ddagger '
exe pA8.'lhd                      <plug>\lhd '
exe pA8.'unlhd                    <plug>\unlhd '
exe pA8.'rhd                      <plug>\rhd '
exe pA8.'unrhd                    <plug>\unrhd '
" }}}
" {{{ Other1
let pA9 = pA."&Other1."
exe pA9.'hat                      <plug>\hat '
exe pA9.'check                    <plug>\check '
exe pA9.'grave                    <plug>\grave '
exe pA9.'acute                    <plug>\acute '
exe pA9.'dot                      <plug>\dot '
exe pA9.'ddot                     <plug>\ddot '
exe pA9.'tilde                    <plug>\tilde '
exe pA9.'breve                    <plug>\breve '
exe pA9.'bar                      <plug>\bar '
exe pA9.'vec                      <plug>\vec '
exe pA9.'aleph                    <plug>\aleph '
exe pA9.'hbar                     <plug>\hbar '
exe pA9.'imath                    <plug>\imath '
exe pA9.'jmath                    <plug>\jmath '
exe pA9.'ell                      <plug>\ell '
exe pA9.'wp                       <plug>\wp '
exe pA9.'Re                       <plug>\Re '
exe pA9.'Im                       <plug>\Im '
exe pA9.'partial                  <plug>\partial '
exe pA9.'infty                    <plug>\infty '
exe pA9.'prime                    <plug>\prime '
exe pA9.'emptyset                 <plug>\emptyset '
exe pA9.'nabla                    <plug>\nabla '
exe pA9.'surd                     <plug>\surd '
exe pA9.'top                      <plug>\top '
exe pA9.'bot                      <plug>\bot '
exe pA9.'angle                    <plug>\angle '
exe pA9.'triangle                 <plug>\triangle '
exe pA9.'backslash                <plug>\backslash '
exe pA9.'forall                   <plug>\forall '
exe pA9.'exists                   <plug>\exists '
exe pA9.'neg                      <plug>\neg '
exe pA9.'flat                     <plug>\flat '
exe pA9.'natural                  <plug>\natural '
exe pA9.'sharp                    <plug>\sharp '
exe pA9.'clubsuit                 <plug>\clubsuit '
exe pA9.'diamondsuit              <plug>\diamondsuit '
exe pA9.'heartsuit                <plug>\heartsuit '
exe pA9.'spadesuit                <plug>\spadesuit '
exe pA9.'S                        <plug>\S '
exe pA9.'P                        <plug>\P'
" }}}
" {{{ MathCreating
let pA10 = pA."&MathCreating."
exe pA10.'not                     <plug>\not'
exe pA10.'mkern                   <plug>\mkern'
exe pA10.'mathbin                 <plug>\mathbin'
exe pA10.'mathrel                 <plug>\mathrel'
exe pA10.'stackrel                <plug>\stackrel'
exe pA10.'mathord                 <plug>\mathord'
" }}}
" {{{ Styles
let pA11 = pA."&Styles."
exe pA11.'displaystyle            <plug>\displaystyle'
exe pA11.'textstyle               <plug>\textstyle'
exe pA11.'scritpstyle             <plug>\scritpstyle'
exe pA11.'scriptscriptstyle       <plug>\scriptscriptstyle'
" }}}
" {{{ MathDiacritics
let pA12 = pA."&MathDiacritics."
exe pA12.'acute{}                 <plug><C-r>=TeX_PutText("\\acute{ää}«»")<cr>'
exe pA12.'bar{}                   <plug><C-r>=TeX_PutText("\\bar{ää}«»")<cr>'
exe pA12.'breve{}                 <plug><C-r>=TeX_PutText("\\breve{ää}«»")<cr>'
exe pA12.'check{}                 <plug><C-r>=TeX_PutText("\\check{ää}«»")<cr>'
exe pA12.'ddot{}                  <plug><C-r>=TeX_PutText("\\ddot{ää}«»")<cr>'
exe pA12.'dot{}                   <plug><C-r>=TeX_PutText("\\dot{ää}«»")<cr>'
exe pA12.'grave{}                 <plug><C-r>=TeX_PutText("\\grave{ää}«»")<cr>'
exe pA12.'hat{}                   <plug><C-r>=TeX_PutText("\\hat{ää}«»")<cr>'
exe pA12.'tilde{}                 <plug><C-r>=TeX_PutText("\\tilde{ää}«»")<cr>'
exe pA12.'vec{}                   <plug><C-r>=TeX_PutText("\\vec{ää}«»")<cr>'
exe pA12.'widehat{}               <plug><C-r>=TeX_PutText("\\widehat{ää}«»")<cr>'
exe pA12.'widetilde{}             <plug><C-r>=TeX_PutText("\\widetilde{ää}«»")<cr>'
exe pA12.'imath                   <plug><C-r>=TeX_PutText("\\imath")<cr>'
exe pA12.'jmath                   <plug><C-r>=TeX_PutText("\\jmath")<cr>'
" }}}
" {{{ OverlineAndCo
let pA13 = pA."&OverlineAndCo."
exe pA13.'overline{}              <plug><C-r>=TeX_PutText("\\overline{}")<cr>'
exe pA13.'underline{}             <plug><C-r>=TeX_PutText("\\underline{}")<cr>'
exe pA13.'overrightarrow{}        <plug><C-r>=TeX_PutText("\\overrightarrow{}")<cr>'
exe pA13.'overleftarrow{}         <plug><C-r>=TeX_PutText("\\overleftarrow{}")<cr>'
exe pA13.'overbrace{}             <plug><C-r>=TeX_PutText("\\overbrace{}")<cr>'
exe pA13.'underbrace{}            <plug><C-r>=TeX_PutText("\\underbrace{}")<cr>'
" }}}
" {{{ Symbols1
let pA14a = pA."&Symbols1."
exe pA14a.'forall                 <plug>\forall '
exe pA14a.'exists                 <plug>\exists '
exe pA14a.'nexists                <plug>\nexists '
exe pA14a.'neg                    <plug>\neg '
exe pA14a.'top                    <plug>\top '
exe pA14a.'bot                    <plug>\bot '
exe pA14a.'emptyset               <plug>\emptyset '
exe pA14a.'varnothing             <plug>\varnothing '
exe pA14a.'infty                  <plug>\infty '
exe pA14a.'aleph                  <plug>\aleph '
exe pA14a.'beth                   <plug>\beth '
exe pA14a.'gimel                  <plug>\gimel '
exe pA14a.'daleth                 <plug>\daleth '
exe pA14a.'hbar                   <plug>\hbar '
exe pA14a.'hslash                 <plug>\hslash '
exe pA14a.'diagup                 <plug>\diagup '
exe pA14a.'vert                   <plug>\vert '
exe pA14a.'Vert                   <plug>\Vert '
exe pA14a.'backslash              <plug>\backslash '
exe pA14a.'diagdown               <plug>\diagdown '
exe pA14a.'Bbbk                   <plug>\Bbbk '
exe pA14a.'P                      <plug>\P '
exe pA14a.'S                      <plug>\S '
" }}}
" {{{ Symbols2
let pA14b = pA."&Symbols2."
exe pA14b.'#                      <plug>\# '
exe pA14b.'%                      <plug>\% '
exe pA14b.'_                      <plug>\_ '
exe pA14b.'$                      <plug>\$ '
exe pA14b.'&                      <plug>\& '
exe pA14b.'imath                  <plug>\imath '
exe pA14b.'jmath                  <plug>\jmath '
exe pA14b.'ell                    <plug>\ell '
exe pA14b.'wp                     <plug>\wp '
exe pA14b.'Re                     <plug>\Re '
exe pA14b.'Im                     <plug>\Im '
exe pA14b.'prime                  <plug>\prime '
exe pA14b.'backprime              <plug>\backprime '
exe pA14b.'nabla                  <plug>\nabla '
exe pA14b.'surd                   <plug>\surd '
exe pA14b.'flat                   <plug>\flat '
exe pA14b.'sharp                  <plug>\sharp '
exe pA14b.'natural                <plug>\natural '
exe pA14b.'eth                    <plug>\eth '
exe pA14b.'bigstar                <plug>\bigstar '
exe pA14b.'circledS               <plug>\circledS '
exe pA14b.'Finv                   <plug>\Finv '
exe pA14b.'dag                    <plug>\dag '
exe pA14b.'ddag                   <plug>\ddag '
" }}}
" {{{ Symbols3
let pA14c = pA."&Symbols3."
exe pA14c.'angle                  <plug>\angle '
exe pA14c.'measuredangle          <plug>\measuredangle '
exe pA14c.'sphericalangle         <plug>\sphericalangle '
exe pA14c.'spadesuit              <plug>\spadesuit '
exe pA14c.'heartsuit              <plug>\heartsuit '
exe pA14c.'diamondsuit            <plug>\diamondsuit '
exe pA14c.'clubsuit               <plug>\clubsuit '
exe pA14c.'lozenge                <plug>\lozenge '
exe pA14c.'blacklozenge           <plug>\blacklozenge '
exe pA14c.'Diamond                <plug>\Diamond '
exe pA14c.'triangle               <plug>\triangle '
exe pA14c.'vartriangle            <plug>\vartriangle '
exe pA14c.'blacktriangle          <plug>\blacktriangle '
exe pA14c.'triangledown           <plug>\triangledown '
exe pA14c.'blacktriangledown      <plug>\blacktriangledown '
exe pA14c.'Box                    <plug>\Box '
exe pA14c.'square                 <plug>\square '
exe pA14c.'blacksquare            <plug>\blacksquare '
exe pA14c.'complement             <plug>\complement '
exe pA14c.'mho                    <plug>\mho '
exe pA14c.'Game                   <plug>\Game '
exe pA14c.'partial                <plug>\partial '
exe pA14c.'smallint               <plug>\smallint '
" }}}
" {{{ Logic
let pA15 = pA."&Logic."
exe pA15.'lnot                    <plug>\lnot '
exe pA15.'lor                     <plug>\lor '
exe pA15.'land                    <plug>\land '
exe pA15.'implies                 <plug>\implies '
" }}}
" {{{ Limits1
let pA16 = pA."&Limits1."
exe pA16.'left                    <plug>\left'
exe pA16.'right                   <plug>\right'
exe pA16.'-sepbigl- :'
exe pA16.'bigl                    <plug>\bigl'
exe pA16.'Bigl                    <plug>\Bigl'
exe pA16.'biggl                   <plug>\biggl'
exe pA16.'Biggl                   <plug>\Biggl'
exe pA16.'-sepbigr- :'
exe pA16.'bigr                    <plug>\bigr'
exe pA16.'Bigr                    <plug>\Bigr'
exe pA16.'biggr                   <plug>\biggr'
exe pA16.'Biggr                   <plug>\Biggr'
exe pA16.'-sepbig- :'
exe pA16.'big                     <plug>\big'
exe pA16.'bigm                    <plug>\bigm'
exe pA16.'-sepfloor- :'
exe pA16.'lfloor                  <plug>\lfloor '
exe pA16.'lceil                   <plug>\lceil '
exe pA16.'rfloor                  <plug>\rfloor '
exe pA16.'rceil                   <plug>\rceil '
exe pA16.'-sepangle- :'
exe pA16.'langle                  <plug>\langle '
exe pA16.'rangle                  <plug>\rangle '
" }}}
" {{{ Limits2
let pA16a = pA."&Limits2."
exe pA16a.'ulcorner               <plug>\ulcorner '
exe pA16a.'urcorner               <plug>\urcorner '
exe pA16a.'llcorner               <plug>\llcorner '
exe pA16a.'rlcorner               <plug>\rlcorner '
exe pA16a.'-sepcorner- :'
exe pA16a.'vert                   <plug>\vert '
exe pA16a.'Vert                   <plug>\Vert '
exe pA16a.'uparrow                <plug>\uparrow '
exe pA16a.'Uparrow                <plug>\Uparrow '
exe pA16a.'downarrow              <plug>\downarrow '
exe pA16a.'Downarrow              <plug>\Downarrow '
exe pA16a.'updownarrow            <plug>\updownarrow '
exe pA16a.'Updownarrow            <plug>\Updownarrow '
exe pA16a.'lgroup                 <plug>\lgroup '
exe pA16a.'rgroup                 <plug>\rgroup '
exe pA16a.'lmoustache             <plug>\lmoustache '
exe pA16a.'rmoustache             <plug>\rmoustache '
exe pA16a.'arrowvert              <plug>\arrowvert '
exe pA16a.'Arrowvert              <plug>\Arrowvert '
exe pA16a.'bracevert              <plug>\bracevert '
" }}}
" 1}}}
" Dimensions {{{
let pB = 'amenu <silent> 87 &Dimensions.'
" {{{ Static1
let pB1 = pB.'&Static1.'
exe pB1.'arraycolsep           <plug>\arraycolsep'
exe pB1.'arrayrulewidth        <plug>\arrayrulewidth'
exe pB1.'bibindent             <plug>\bibindent'
exe pB1.'columnsep             <plug>\columnsep'
exe pB1.'columnseprule         <plug>\columnseprule'
exe pB1.'columnwidth           <plug>\columnwidth'
exe pB1.'doublerulesep         <plug>\doublerulesep'
exe pB1.'evensidemargin        <plug>\evensidemargin'
exe pB1.'fboxrule              <plug>\fboxrule'
exe pB1.'fboxsep               <plug>\fboxsep'
exe pB1.'footheight            <plug>\footheight'
exe pB1. 'footnotesep          <plug>\footnotesep'
exe pB1.'footskip              <plug>\footskip'
exe pB1.'headheight            <plug>\headheight'
exe pB1.'headsep               <plug>\headsep'
exe pB1.'itemindent            <plug>\itemindent'
exe pB1.'labelsep              <plug>\labelsep'
exe pB1.'labelwidth            <plug>\labelwidth'
exe pB1.'leftmargin            <plug>\leftmargin'
exe pB1.'leftmargini           <plug>\leftmargini'
exe pB1.'leftmarginii          <plug>\leftmarginii'
exe pB1.'leftmarginiii         <plug>\leftmarginiii'
exe pB1.'leftmarginiv          <plug>\leftmarginiv'
exe pB1.'leftmarginv           <plug>\leftmarginv'
exe pB1.'leftmarginvi          <plug>\leftmarginvi'
exe pB1.'linewidth             <plug>\linewidth'
exe pB1.'listparindent         <plug>\listparindent'
exe pB1.'marginparpush         <plug>\marginparpush'
exe pB1.'marginparsep          <plug>\marginparsep'
exe pB1.'marginparwidth        <plug>\marginparwidth'
exe pB1.'mathindent            <plug>\mathindent'
exe pB1.'oddsidemargin         <plug>\oddsidemargin'
" }}}
" {{{ Static2
let pB2 = pB.'&Static2.'
exe pB2.'paperheight           <plug>\paperheight'
exe pB2.'paperwidth            <plug>\paperwidth'
exe pB2.'parindent             <plug>\parindent'
exe pB2.'rightmargin           <plug>\rightmargin'
exe pB2.'tabbingsep            <plug>\tabbingsep'
exe pB2.'tabcolsep             <plug>\tabcolsep'
exe pB2.'textheight            <plug>\textheight'
exe pB2.'textwidth             <plug>\textwidth'
exe pB2.'topmargin             <plug>\topmargin'
exe pB2.'unitlength            <plug>\unitlength'
" }}}
" {{{ Dynamic
let pB3 = pB.'&Dynamic.'
exe pB3.'abovedisplayshortskip <plug>\abovedisplayshortskip'
exe pB3.'abovedisplayskip      <plug>\abovedisplayskip'
exe pB3.'baselineskip          <plug>\baselineskip'
exe pB3.'belowdisplayshortskip <plug>\belowdisplayshortskip'
exe pB3.'belowdisplayskip      <plug>\belowdisplayskip'
exe pB3.'dblfloatsep           <plug>\dblfloatsep'
exe pB3.'dbltextfloatsep       <plug>\dbltextfloatsep'
exe pB3.'floatsep              <plug>\floatsep'
exe pB3.'intextsep             <plug>\intextsep'
exe pB3.'itemsep               <plug>\itemsep'
exe pB3.'parsep                <plug>\parsep'
exe pB3.'parskip               <plug>\parskip'
exe pB3.'partopsep             <plug>\partopsep'
exe pB3.'textfloatsep          <plug>\textfloatsep'
exe pB3.'topsep                <plug>\topsep'
exe pB3.'topskip               <plug>\topskip'
" }}}
" {{{ Change
let pB4 = pB.'&Change.'
exe pB4.'setlength             <plug>\setlength'
exe pB4.'addtolength           <plug>\addtolength'
exe pB4.'settoheight           <plug>\settoheight'
exe pB4.'settowidth            <plug>\settowidth'
exe pB4.'settolength           <plug>\settolength'
" }}}
" }}}
" Counters {{{
let pC = 'amenu <silent> 87 &Counters.'
" {{{ Counters
let pC1 = pC.'&Counters.'
exe pC1.'bottomnumber     <plug>\bottomnumber'
exe pC1.'chapter          <plug>\chapter'
exe pC1.'dbltopnumber     <plug>\dbltopnumber'
exe pC1.'enumi            <plug>\enumi'
exe pC1.'enumii           <plug>\enumii'
exe pC1.'enumiii          <plug>\enumiii'
exe pC1.'enumiv           <plug>\enumiv'
exe pC1.'equation         <plug>\equation'
exe pC1.'figure           <plug>\figure'
exe pC1.'footnote         <plug>\footnote'
exe pC1.'mpfootnote       <plug>\mpfootnote'
exe pC1.'page             <plug>\page'
exe pC1.'paragraph        <plug>\paragraph'
exe pC1.'part             <plug>\part'
exe pC1.'secnumdepth      <plug>\secnumdepth'
exe pC1.'section          <plug>\section'
exe pC1.'subparagraph     <plug>\subparagraph'
exe pC1.'subsection       <plug>\subsection'
exe pC1.'subsubsection    <plug>\subsubsection'
exe pC1.'table            <plug>\table'
exe pC1.'tocdepth         <plug>\tocdepth'
exe pC1.'topnumber        <plug>\topnumber'
exe pC1.'totalnumber      <plug>\totalnumber'
" }}}
" {{{ theCounters
let pC2 = pC.'&theCounters.'
exe pC2.'thebottomnumber  <plug>\thebottomnumber'
exe pC2.'thechapter       <plug>\thechapter'
exe pC2.'thedbltopnumber  <plug>\thedbltopnumber'
exe pC2.'theenumi         <plug>\theenumi'
exe pC2.'theenumii        <plug>\theenumii'
exe pC2.'theenumiii       <plug>\theenumiii'
exe pC2.'theenumiv        <plug>\theenumiv'
exe pC2.'theequation      <plug>\theequation'
exe pC2.'thefigure        <plug>\thefigure'
exe pC2.'thefootnote      <plug>\thefootnote'
exe pC2.'thempfootnote    <plug>\thempfootnote'
exe pC2.'thepage          <plug>\thepage'
exe pC2.'theparagraph     <plug>\theparagraph'
exe pC2.'thepart          <plug>\thepart'
exe pC2.'thesecnumdepth   <plug>\thesecnumdepth'
exe pC2.'thesection       <plug>\thesection'
exe pC2.'thesubparagraph  <plug>\thesubparagraph'
exe pC2.'thesubsection    <plug>\thesubsection'
exe pC2.'thesubsubsection <plug>\thesubsubsection'
exe pC2.'thetable         <plug>\thetable'
exe pC2.'thetocdepth      <plug>\thetocdepth'
exe pC2.'thetopnumber     <plug>\thetopnumber'
exe pC2.'thetotalnumber   <plug>\thetotalnumber'
" }}}
" {{{ Type
let pC3 = pC.'&Type.'
exe pC3.'alph{}           <plug><C-r>=TeX_PutText("\\alph{ää}«»")<cr>'
exe pC3.'Alph{}           <plug><C-r>=TeX_PutText("\\Alph{ää}«»")<cr>'
exe pC3.'arabic{}         <plug><C-r>=TeX_PutText("\\arabic{ää}«»")<cr>'
exe pC3.'roman{}          <plug><C-r>=TeX_PutText("\\roman{ää}«»")<cr>'
exe pC3.'Roman{}          <plug><C-r>=TeX_PutText("\\Roman{ää}«»")<cr>'
" }}}
" }}}
" Fonts {{{
let pD = 'amenu <silent> 88 &Fonts.' "TODO: dorobiæ komendy steruj¹ce
" {{{ Family
let pD1 = pD.'&Family.'
exe pD1.'rmfamily        <plug><C-r>=TeX_PutText("\\rmfamily ")<cr>'
exe pD1.'sffamily        <plug><C-r>=TeX_PutText("\\sffamily ")<cr>'
exe pD1.'ttfamily        <plug><C-r>=TeX_PutText("\\ttfamily ")<cr>'
exe pD1.'textrm{}        <plug><C-r>=TeX_PutText("\\textrm{ää}«»")<cr>'
exe pD1.'textsf{}        <plug><C-r>=TeX_PutText("\\textsf{ää}«»")<cr>'
exe pD1.'texttt{}        <plug><C-r>=TeX_PutText("\\texttt{ää}«»")<cr>'
" }}}
" {{{ Series
let pD2 = pD.'&Series.'
exe pD2.'bfseries        <plug>\bfseries '
exe pD2.'mdseries        <plug>\mdseries '
exe pD2.'textbf{}        <plug><C-r>=TeX_PutText("\\textbf{ää}«»")<cr>'
exe pD2.'textmd{}        <plug><C-r>=TeX_PutText("\\textmd{ää}«»")<cr>'
" }}}
" {{{ S&hape.
let pD3 = pD.'S&hape.'
exe pD3.'itshape         <plug>\itshape '
exe pD3.'scshape         <plug>\scshape '
exe pD3.'slashape        <plug>\slashape '
exe pD3.'upshape         <plug>\upshape '
exe pD3.'textit{}        <plug><C-r>=TeX_PutText("\\textit{ää}«»")<cr>'
exe pD3.'textsc{}        <plug><C-r>=TeX_PutText("\\textsc{ää}«»")<cr>'
exe pD3.'textsl{}        <plug><C-r>=TeX_PutText("\\textsl{ää}«»")<cr>'
exe pD3.'textup{}        <plug><C-r>=TeX_PutText("\\textup{ää}«»")<cr>'
" }}}
" {{{ &Diacritics.
let pD4 = pD.'&Diacritics.'
exe pD4.'Acute           <plug><C-r>=TeX_PutText("\\\"{ää}«»")<cr>'
exe pD4.'Breve           <plug><C-r>=TeX_PutText("\\u{ää}«»")<cr>'
exe pD4.'Kó³ko           <plug><C-r>=TeX_PutText("\\r{ää}«»")<cr>'
exe pD4.'Daszek          <plug><C-r>=TeX_PutText("\\^{ää}«»")<cr>'
exe pD4.'Umlaut          <plug><C-r>=TeX_PutText("\\"{ää}«»")<cr>'
exe pD4.'HUmlaut         <plug><C-r>=TeX_PutText("\\H{ää}«»")<cr>'
exe pD4.'Grave           <plug><C-r>=TeX_PutText("\\`{ää}«»")<cr>'
exe pD4.'Szewron         <plug><C-r>=TeX_PutText("\\v{\ää}«»")<cr>'
exe pD4.'Makron          <plug><C-r>=TeX_PutText("\\={\ää}«»")<cr>'
exe pD4.'Tylda           <plug><C-r>=TeX_PutText("\\~{ää}«»")<cr>'
exe pD4.'Podkreœlenie    <plug><C-r>=TeX_PutText("\\b{ää}«»")<cr>'
exe pD4.'Cedilla         <plug><C-r>=TeX_PutText("\\c{ää}«»")<cr>'
exe pD4.'Kropka\ nad     <plug><C-r>=TeX_PutText("\\.{ää}«»")<cr>'
exe pD4.'Ligatura        <plug><C-r>=TeX_PutText("\\t{ää}«»")<cr>'
" }}}
" {{{ &Size.
let pD5 = pD.'&Size.'
exe pD5.'tiny            <plug>\tiny '
exe pD5.'scriptsize      <plug>\scriptsize '
exe pD5.'footnotesize    <plug>\footnotesize '
exe pD5.'small           <plug>\small '
exe pD5.'normalsize      <plug>\normalsize '
exe pD5.'large           <plug>\large '
exe pD5.'Large           <plug>\Large '
exe pD5.'LARGE           <plug>\LARGE '
exe pD5.'huge            <plug>\huge '
exe pD5.'Huge            <plug>\Huge '
" }}}
" {{{ &font.
let pD6 = pD.'&font.'
exe pD6.'fontencoding{}                    <plug><C-r>=TeX_PutText("\\fontencoding{ää}«»")<cr>'
exe pD6.'fontfamily{qtm}                   <plug><C-r>=TeX_PutText("\\fontfamily{ää}«»")<cr>'
exe pD6.'fontseries{m\ b\ bx\ sb\ c}       <plug><C-r>=TeX_PutText("\\fontseries{ää}«»")<cr>'
exe pD6.'fontshape{n\ it\ sl\ sc\ ui}      <plug><C-r>=TeX_PutText("\\fontshape{ää}«»")<cr>'
exe pD6.'fontsize{8}{10}                   <plug><C-r>=TeX_PutText("\\fontsize{ää}{«»}«»")<cr>'
exe pD6.'selectfont                        <plug><C-r>=TeX_PutText("\\selectfont ")<cr>'
" }}}
" }}}
" Environments {{{
" Lists {{{
let pE = 'amenu <silent> 89 &Environments.'
exe pE.'-sepenv0- :'
let pE1 = pE.'LISTS.'
exe pE1.'description<tab>EDE     <plug><C-r>=TeX_description("description")<cr>'
exe pE1.'enumerate<tab>EEN       <plug><C-r>=TeX_itemize("enumerate")<cr>'
exe pE1.'itemize<tab>EIT         <plug><C-R>=TeX_itemize("itemize")<cr>'
let pE2 = pE.'TABLES.'
exe pE2.'tabbing<tab>ETA         <plug><C-R>=TeX_env("tabbing")<CR>'
exe pE2.'table<tab>ETE           <plug><C-R>=TeX_table("table")<CR>'
exe pE2.'table*                  <plug><C-R>=TeX_table("table*")<CR>'
exe pE2.'table2                  <plug><C-R>=TeX_table2("table*")<CR>'
exe pE2.'tabular<tab>ETR         <plug><C-R>=TeX_tabular("tabular")<CR>'
exe pE2.'tabular*                <plug><C-R>=TeX_tabular("tabular*")<CR>'
" }}}
" }}}

" TeX_PutText: returns the text along with required movement {{{
" 		for cursor placement.
function! TeX_PutText(text)
	return IMAP_PutTextWithMovement(a:text)
endfunction
" }}}

"this is for sections etc. {{{
"Shortcuts
function! TeX_r_title(structure)
	let title = getline(".")
	return TeX_structure(a:structure, title)
endfunction " }}}
"Shortcut  {{{
function! TeX_r_structure()
    let struc = getline(".")
    let title = input("Title? ")
    return TeX_structure(struc, title)
endfunction " }}}
" Menu {{{
function! TeX_structure(structure, title)
    if a:title == ""
        let ttitle = input("Title? ")
    else
        let ttitle = a:title
    endif
    let shorttitle =  input("Short title? ")
    let toc = input("Include in table of contents [y]/n ? ") "TODO: regexp to extract 1st letter?
    "Structure
    let sstructure = a:structure
    if strpart(sstructure, 0, 1) == "\\"
        let sstructure = strpart(a:structure, 1)
    endif
    let sstructure = substitute(sstructure, '.*',"\\L\\0", '')
    let sstructure = "\\".sstructure
    "TOC
    if ( toc == "" || toc == "y" )
        let toc = ""
    else
        let toc = "*"
    endif
    "Shorttitle
    if shorttitle != ""
        let shorttitle = '['.shorttitle.']'
    endif
    "Title
    let ttitle = '{'.ttitle.'}'
    "Happy end?
    return sstructure.toc.shorttitle.ttitle 
endfunction " }}}
" sks for an environment and inserts \begin{...} and \end{...} commands {{{
function! TeX_ask_env()
    let env = input("Environment? ")
    call TeX_env(env)
endfunction " }}}
" this reads the current and creates an environment out if it {{{
" (this way you can use ins-completion)
function! TeX_read_env()
    let env = getline(".")
    normal ddk
    call TeX_env(env)
endfunction
" }}}
" common routine for all environments {{{
function! TeX_env(env)
    if (a:env=="figure" || a:env=="figure*" )
        return TeX_figure(a:env)
    elseif (a:env=="table" || a:env=="table*")
        return TeX_table(a:env)
    elseif (a:env=="tabular" || a:env=="tabular*" ||
           \a:env=="array" || a:env=="array*")
        return TeX_tabular(a:env,"")
    elseif (a:env=="eqnarray" || a:env=="equation*")
        return TeX_eqnarray(a:env)
    elseif (a:env=="list")
        return TeX_list(a:env)
    elseif (a:env=="itemize" || a:env=="theindex" ||
           \a:env=="trivlist" || a:env=="enumerate")
        return TeX_itemize(a:env)
    elseif (a:env=="description")
        return TeX_description(a:env)
    elseif (a:env=="document")
        return TeX_document(a:env)
    elseif (a:env=="minipage")
        return TeX_minipage(a:env)
    elseif (a:env=="thebibliography")
        return TeX_thebibliography(a:env)
    else
        return "\\begin{".a:env."}\<cr>ää\<cr>\\end{".a:env.'}«»'
    endif
endfunction
" }}}
" special treatment for `itemize', `enumerate', `theindex', `trivlist' {{{
function! TeX_itemize(env)
	let rhs = "\\begin{".a:env."}\<cr>\\item ää\<cr>\\end{".a:env."}«»"
	return TeX_PutText(rhs)
endfunction " }}}
" special treatment for `description' {{{
function! TeX_description(env)
	let itlabel = input("(Optional) Item label? ")
	if (itlabel != "")
		let itlabel = '['.itlabel.']'
	endif
	let rhs = "\\begin{".a:env."}\<cr>\\item".itlabel." ää\<cr>\\end{".a:env."}«»"
	return TeX_PutText(rhs)
endfunction " }}}
" special treatment for `figure' {{{
function! TeX_figure(env)
    let flto = input("Float to (htbp)? ")
    "let pos = input("Position (htbp)? ")
    let caption = input("Caption? ")
    let center = input("Center (y/n)? ")
    " confirm is also possible, but I don't like it (in a terminal)
    "let center = confirm("Center?","&yes\n&no")
    let label = input('Label (for use with \ref)? ')
    " additional to AUC TeX since my pics are usually external files
    let pic = input("Name of Pic-File? ")
    "
    " what should hapen if flto is empty? default values? nothing?
    put ='\begin{'.a:env.'}['.flto.']'
    put ='\end{'.a:env.'}'
    normal k
    if (center == "y")
        put ='    \begin{center}'
        put ='    \end{center}'
        normal m'
        normal k
    endif
    if (pic != "")
        put ='        \input{'.pic.'}'
    endif
    if (caption != "")
        put ='        \caption{'.caption.'}'
    endif
    if (label != "")
        put ='        \label{'.label.'}'
    endif
    normal ''
endfunction " }}}
" special treatment for `table2' {{{
function! TeX_table2(env)
	let ret = "\\begin{".a:env."}[«float (f l t o)»]\<cr>"

    let center = input("Center (y/n)? ", "y")

    " confirm is also possible, but I don't like it (in a terminal)
    "let center = confirm("Center?","&yes\n&no")
    if (center == "y")
        let ret=ret."\\begin{center}\<cr>"
    endif

    let ret = ret."\\begin{tabular}[«position»]{«format»}\<cr>"
	let ret = ret."«table elements»\<cr>"
	let ret = ret."\\end{tabular}\<cr>"

    if (center == "y")
        let ret=ret."\\end{center}\<cr>"
    endif

    let ret=ret."\\caption{«caption text»}\<cr>"
    let ret=ret."\\label{«label text»}\<cr>"
    let ret=ret."\\end{".a:env.'}«»'
	return IMAP_PutTextWithMovement(ret)
endfunction " }}}
" special treatment for `table' {{{
function! TeX_table(env)
    let flto = input("Float to (htbp)? ")
    let caption = input("Caption? ")
    let center = input("Center (y/n)? ")
    " confirm is also possible, but I don't like it (in a terminal)
    "let center = confirm("Center?","&yes\n&no")
    let label = input('Label (for use with \ref)? ')
    " TODO what should hapen if flto is empty? default values? nothing?
    let ret="\\begin{".a:env.'}['.flto.']'
    if (center == "y")
        let ret=ret."\<cr>\\begin{center}"
    endif
    let foo = "\<cr>\\begin{tabular}"
    let pos = input("(Optional) Position (t b)? ")
    if (pos!="")
        let foo = foo.'['.pos.']'
    endif
    let format = input("Format  ( l r c p{width} | @{text} )? ")
    let ret = ret.foo.'{'.format."}\<cr>ää\<cr>\\end{tabular}«»\<cr>"
    if (center == "y")
        let ret=ret."\\end{center}\<cr>"
    endif
    if (caption != "")
        let ret=ret."\\caption{".caption."}\<cr>"
    endif
    if (label != "")
        let ret=ret."\\label{".label."}\<cr>"
    endif
    let ret=ret."\\end{".a:env.'}«»'
	return TeX_PutText(ret)
endfunction " }}}
" special treatment for `tabular' and `array' {{{
function! TeX_tabular(env)
    let foo = '\begin{'.a:env.'}'
    let pos = input("(Optional) Position (t b)? ")
    if (pos!="")
        let foo = foo.'['.pos.']'
    endif
    let format = input("Format  ( l r c p{width} | @{text} )? ")
    return TeX_PutText(foo.'{'.format."}\<cr>ää\<cr>\\end{".a:env.'}«»')
endfunction " }}}
" special treatment for `eqnarray' and `equation' {{{
function! TeX_eqnarray(env)
    let label = input("Label? ")
    put ='\begin{'.a:env.'}'
    if (label != "")
        put ='    \label{'.label.'}'
    endif
    put ='\end{'.a:env.'}'
    normal O
endfunction " }}}
" special treatment for `list' (unlike AUC TeX) {{{
function! TeX_list(env)
    let label = input("Label (for \item)? ")
    let foo ='\begin{'.a:env.'}'
    if (label != "")
        let foo = foo.'{'.label.'}'
        let addcmd = input("Additional commands? ")
        if (addcmd != "")
            let foo = foo.'{'.addcmd.'}'
        endif
    endif
    put =foo
    put ='\end{'.a:env.'}'
    normal k
    put ='    \item'
endfunction " }}}
" special treatment for `itemize', `enumerate', `theindex', `trivlist' {{{
function! TeX_itemize2(env)
	let rhs = "\\begin{".a:env."}\<cr>\\item ää\<cr>\\end{".a:env."}"
	return TeX_PutText(rhs)
endfunction " }}}
" special treatment for `itemize', `enumerate', `theindex', `trivlist' {{{
function! TeX_itemize(env)
    put ='\begin{'.a:env.'}'
    put ='\end{'.a:env.'}'
    normal k
    put ='    \item'
endfunction " }}}
" special treatment for `description' {{{
function! TeX_description2(env)
    let itlabel = input("(Optional) Item label? ")
    if (itlabel != "")
        let itlabel = '['.itlabel.']'
    endif
	let rhs = "\\begin{".a:env."}\<cr>\\item".itlabel." ää\<cr>\\end{".a:env."}"
	return TeX_PutText(rhs)
endfunction " }}}
" special treatment for `description' {{{
function! TeX_description(env)
    put ='\begin{'.a:env.'}'
    put ='\end{'.a:env.'}'
    normal k
    let itlabel = input("(Optional) Item label? ")
    if (itlabel == "")
        put ='    \item'
    else
        put ='    \item['.itlabel.']'
    endif
endfunction " }}}
" special treatment for `document' {{{
function! TeX_document(env)
    let dstyle = input("Document style (article mwart report mwrep book mwbk)? ")
    let opts = input("(Optional) Options? ")
    let foo = '\documentclass'
    if (opts=="")
        let foo = foo.'{'.dstyle.'}'
    else
        let foo = foo.'['.opts.']'.'{'.dstyle.'}'
    endif
  put = '%& --translate-file=cp1250pl'
    put =foo
    put =''
    put ='\begin{document}'
    put =''
    put ='\end{document}'
    normal kk
endfunction " }}}
" special treatment for `minipage' {{{
function! TeX_minipage(env)
    let foo = '\begin{minipage}'
    let pos = input("(Optional) Position (t b)? ")
    let width = input("Width? ")
    if (pos=="")
        let foo = foo.'{'.width.'}'
    else
        let  foo = foo.'['.pos.']{'.width.'}'
    endif
    put =foo
    put ='\end{minipage}'
    normal k
endfunction " }}}
" special treatment for `thebibliography' {{{
function! TeX_thebibliography(env)
    let foo = '\begin{thebibliography}'
    " AUC TeX: "Label for BibItem: 99"
    let indent = input("Indent for BibItem? ")
    let foo = foo.'{'.indent.'}'
    let biblabel = input("(Optional) Bibitem label? ")
    let key = input("Add key? ")
    let bar = '    \bibitem'
    if (biblabel!="")
        let bar = bar.'['.biblabel.']'
    endif
    let bar = bar.'{'.key.'}'
    put =foo
    put =bar
    put ='\end{thebibliography}'
    normal k
endfunction " }}}

" vim:fdm=marker
