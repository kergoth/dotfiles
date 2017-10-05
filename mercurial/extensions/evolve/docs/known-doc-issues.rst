.. Copyright © 2017 Pierre-Yves David <pierre-yves.david@octobus.net>

==============================================
Known limitations of the current documentation
==============================================

Features not covered by tutorials
=================================

Some of the *newer* features of evolution might not be reflected in the
documentation yet. You can directly check the inline documentation of the
extension itself for fresher details using `hg help -e evolve`.

Known undocumented features are:

 * `hg prev`,
 * `hg next`,
 * `hg next --evolve`,
 * `hg evolve --rev`,
 * `hg evolve --list`,
 * `hg obslog`,
 * `hg split`,
 * `hg metaedit`,
 * `hg touch`,
 * `hg amend --extract`,
 * `hg pdiff`,
 * `hg pstatus`,
 * `hg amend -i`,
 * various topic related elements (in particular `hg stack`),

Unreferenced Documents
======================

There are documents with content not linked in the flow of the main
documentation. Some might be outdated and some are too fresh to be integrated in
the main flow yet.

.. toctree::
   :maxdepth: 1

   evolve-faq
   evolve-good-practice
   obs-terms
   tutorials/topic-tutorial
   tutorials/tutorial
