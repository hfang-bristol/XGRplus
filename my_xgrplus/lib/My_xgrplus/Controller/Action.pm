package My_xgrplus::Controller::Action;
use My_xgrplus::Controller::Utils;
use Mojo::Base 'Mojolicious::Controller';
use JSON;
use LWP::Simple;
use List::Util qw( min max sum );
use POSIX qw(strftime);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

# Render template "dcGO_sitemap.html.ep"
# Render template "dcGO_hie.html.ep"
sub index {
	my $c = shift;
  	
  	
  	##########################
	## Ontology Information
	my %task_name = (
		"EAgene" => 'Enrichment Analyser (Genes)',
		"EAsnp" => 'Enrichment Analyser (SNPs)',
		"EAregion" => 'Enrichment Analyser (Genomic Regions)',
		"EAdomain" => 'Enrichment Analyser (Protein Domains)',
		"SAgene" => 'Subnetwork Analyser (Genes)',
		"SAsnp" => 'Subnetwork Analyser (SNPs)',
		"SAregion" => 'Subnetwork Analyser (Genomic Regions)',
	);
	my %task_des = (
		"EAgene" => 'Enrichment analysis for genes using ontologies',
		"EAsnp" => 'SNPs linked to genes for enrichment analysis',
		"EAregion" => 'Genomic regions linked to genes for enrichment analysis',
		"EAdomain" => 'Enrichment analysis for protein domains using ontologies',
		"SAgene" => 'Subnetwork analysis for gene-level summary data',
		"SAsnp" => 'SNPs linked to genes for subnetwork analysis',
		"SAregion" => 'Genomic regions linked to genes for subnetwork analysis',
	);
	
	# json_task
	my @data_task;
	foreach my $id (keys %task_name) {
		my $rec;
		$rec->{id}=$id;
		$rec->{name}=$task_name{$id};
		$rec->{description}=$task_des{$id};
			
		push @data_task,$rec;
	}
	print STDERR scalar(@data_task)."\n";
	$c->stash(json_task => encode_json(\@data_task));
  	##########################
  	
  	
  	$c->render();
}

sub booklet {
  	my $c = shift;
	$c->redirect_to("/dcGObooklet/index.html");
}

# Render template "dcGO_level_domain.html.ep"
sub dcGO_level_domain {
	my $c = shift;

	my $level= $c->param("level");
	my $domain= $c->param("domain") || 53118;
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOdb');
	my $sth;
	
	##############
	# http://127.0.0.1:3080/dcGO/fa/53118
	# http://127.0.0.1:3080/dcGO/sf/53098
	# http://127.0.0.1:3080/dcGO/pfam/PF00001
	# http://127.0.0.1:3080/dcGO/interpro/IPR000001
	my $domain_data; # reference or ''
	my $json = ""; # json or ''
	##############
	
	## Ontology Information
	my %OBO_INFO = (
		"GOBP" => 'Gene Ontology Biological Process (GOBP)',
		"GOCC" => 'Gene Ontology Cellular Component (GOCC)',
		"GOMF" => 'Gene Ontology Molecular Function (GOMF)',
		"HPO" => 'Human Phenotype Ontology (HPO)',
		"MPO" => 'Mammalian Phenotype Ontology (MPO)',
		"WPO" => 'Worm Phenotype Ontology (WPO)',
		"FPO" => 'Fly Phenotype Ontology (FPO)',
		"FAN" => 'Fly Anatomy (FAN)',
		"ZAN" => 'Zebrafish Anatomy (ZAN)',
		"APO" => 'Arabidopsis Plant Ontology (APO)',
		"DO" => 'Disease Ontology (DO)',
		"EFO" => 'Experimental Factor Ontology (EFO)',
		"DGIdb" => 'DGIdb druggable categories (DGIdb)',
		"Bucket" => 'Target tractability buckets (Bucket)',
		"KEGG" => 'KEGG pathways (KEGG)',
		"REACTOME" => 'REACTOME pathways (REACTOME)',
		"PANTHER" => 'PANTHER pathways (PANTHER)',
		"WKPATH" => 'WiKiPathway pathways (WKPATH)',
		"MITOPATH" => "MitoPathway pathways (MITOPATH)",
		"CTF" => 'ENRICHR Consensus TFs (CTF)',
		"TRRUST" => 'TRRUST TFs (TRRUST)',
		"MSIGDB" => 'MSIGDB Hallmarks (MSIGDB)',
	);
	## Level Information
	my %LVL_INFO = (
		"sf" => 'SCOP superfamily',
		"fa" => 'SCOP family',
		"pfam" => 'Pfam family',
		"interpro" => 'InterPro family',
	);
	
	if($level eq "sf" or $level eq "fa"){
		#SELECT id,description FROM scop_info WHERE level="sf" AND id=158235;
		$sth = $dbh->prepare( 'SELECT id,description FROM scop_info WHERE level=? AND id=?;' );
		$sth->execute($level,$domain);
		if($sth->rows > 0){
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$LVL_INFO{$level};
			$domain_data->{scop}="";
			if($level eq "sf"){
				#SELECT parent,child FROM scop_hie WHERE parent=46785;
				my $sth1 = $dbh->prepare( 'SELECT parent,child FROM scop_hie WHERE parent=?;' );
				$sth1->execute($domain);
				if($sth1->rows > 0){
					while (my @row = $sth1->fetchrow_array) {
						$domain_data->{scop}.="<a href='/dcGO/fa/".$row[1]."'><i class='fa fa-diamond 1x'></i>&nbsp;".$row[1]."</a> | ";
					}
					$domain_data->{scop}=~s/ \| $//g;
				}
				$sth1->finish();
			}elsif($level eq "fa"){
				#SELECT parent,child FROM scop_hie WHERE child=158236;
				my $sth1 = $dbh->prepare( 'SELECT parent,child FROM scop_hie WHERE child=?;' );
				$sth1->execute($domain);
				if($sth1->rows > 0){
					while (my @row = $sth1->fetchrow_array) {
						$domain_data->{scop}.="<a href='/dcGO/fa/".$row[0]."'><i class='fa fa-diamond 1x'></i>&nbsp;".$row[0]."</a> | ";
					}
					$domain_data->{scop}=~s/ \| $//g;
				}
				$sth1->finish();
			}
		}else{
			$domain_data="";
		}
		$sth->finish();
	
	}elsif($level eq "pfam"){
		#SELECT id,description FROM pfam_info WHERE id="PF00096";
		$sth = $dbh->prepare( 'SELECT id,description FROM pfam_info WHERE id=?;' );
		$sth->execute($domain);
		if($sth->rows > 0){
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$LVL_INFO{$level};
		}else{
			$domain_data="";
		}
		$sth->finish();
		
	}elsif($level eq "interpro"){
		#SELECT id,description FROM interpro_info WHERE id="IPR000001";
		$sth = $dbh->prepare( 'SELECT id,description FROM interpro_info WHERE id=?;' );
		$sth->execute($domain);
		if($sth->rows > 0){
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$LVL_INFO{$level};
		}else{
			$domain_data="";
		}
		$sth->finish();
		
	}
	$c->stash(domain_data => $domain_data);
	
	
	#SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.parent AS parent FROM des, hie WHERE hie.id=des.id AND des.id=53118;
	
	if($level eq "sf" or $level eq "fa"){
		#SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_scop as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id=158236 AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;
		$sth = $dbh->prepare('SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_scop as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id=? AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;');
		$sth->execute($domain);
		
	}elsif($level eq "pfam"){
		#SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_pfam as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id='PF00001' AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;
		$sth = $dbh->prepare('SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_pfam as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id=? AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;');
		$sth->execute($domain);
		
	}elsif($level eq "interpro"){
		#SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_interpro as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id='IPR000001' AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;
		$sth = $dbh->prepare('SELECT a.domain_id AS did, b.obo AS obo, b.id AS oid, b.name AS oname, a.ascore AS score FROM mapping_interpro as a, term_info as b WHERE a.obo=b.obo AND a.term_id=b.id AND a.domain_id=? AND a.term_id!="root" ORDER BY b.obo ASC, a.ascore DESC;');
		$sth->execute($domain);
		
	}

	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{did}=$row[0];
			$rec->{obo}=$row[1];
			$rec->{obo_info}=$OBO_INFO{$row[1]};
			$rec->{oid}="<a href='/dcGO/".$row[1]."/".$row[2]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[2];
			$rec->{oname}=$row[3];
			$rec->{score}=$row[4];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno => $json);
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "dcGO_obo_term.html.ep"
sub dcGO_obo_term {
	my $c = shift;

	my $obo= $c->param("obo");
	my $term= $c->param("term") || "GO:0008150";
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOdb');
	my $sth;
	
	##############
	# http://127.0.0.1:3080/dcGO/GOBP/GO:0002376
	# http://127.0.0.1:3080/dcGO/PANTHER/P00011
	my $term_data; # reference or ''
	my $json = ""; # json or ''
	##############
		
	## Ontology Information
	my %OBO_INFO = (
		"GOBP" => 'Gene Ontology Biological Process (GOBP)',
		"GOCC" => 'Gene Ontology Cellular Component (GOCC)',
		"GOMF" => 'Gene Ontology Molecular Function (GOMF)',
		"HPO" => 'Human Phenotype Ontology (HPO)',
		"MPO" => 'Mammalian Phenotype Ontology (MPO)',
		"WPO" => 'Worm Phenotype Ontology (WPO)',
		"FPO" => 'Fly Phenotype Ontology (FPO)',
		"FAN" => 'Fly Anatomy (FAN)',
		"ZAN" => 'Zebrafish Anatomy (ZAN)',
		"APO" => 'Arabidopsis Plant Ontology (APO)',
		"DO" => 'Disease Ontology (DO)',
		"EFO" => 'Experimental Factor Ontology (EFO)',
		"DGIdb" => 'DGIdb druggable categories (DGIdb)',
		"Bucket" => 'Target tractability buckets (Bucket)',
		"KEGG" => 'KEGG pathways (KEGG)',
		"REACTOME" => 'REACTOME pathways (REACTOME)',
		"PANTHER" => 'PANTHER pathways (PANTHER)',
		"WKPATH" => 'WiKiPathway pathways (WKPATH)',
		"MITOPATH" => "MitoPathway pathways (MITOPATH)",
		"CTF" => 'ENRICHR Consensus TFs (CTF)',
		"TRRUST" => 'TRRUST TFs (TRRUST)',
		"MSIGDB" => 'MSIGDB Hallmarks (MSIGDB)',
	);
	## Level Information
	my %LVL_INFO = (
		"sf" => 'SCOP superfamily',
		"fa" => 'SCOP family',
		"pfam" => 'Pfam family',
		"interpro" => 'InterPro family',
	);


	if(exists($OBO_INFO{$obo})){
		#SELECT id,name FROM term_info WHERE obo="Bucket" AND id="AB:1";
		$sth = $dbh->prepare( 'SELECT id,name FROM term_info WHERE obo=? AND id=?;' );
		$sth->execute($obo,$term);
		$term_data=$sth->fetchrow_hashref;
		$term_data->{obo}=$obo;
		$term_data->{obo_info}=$OBO_INFO{$obo};
		if(!$term_data->{id}){
			#return $c->reply->not_found;
			$term_data="";
		}
		$sth->finish();
		
	}
	$c->stash(term_data => $term_data);
	
	################
	# scop
	################
	#SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_scop as a, scop_info as b WHERE a.domain_id=b.id AND a.obo="GOBP" AND a.term_id="GO:0002376" ORDER BY b.level ASC, a.ascore DESC;
	
	#SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_scop as a, scop_info as b WHERE a.domain_id=b.id AND a.obo="FPO" AND a.term_id="FBcv:0000347" ORDER BY b.level ASC, a.ascore DESC;
	
	$sth = $dbh->prepare('SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_scop as a, scop_info as b WHERE a.domain_id=b.id AND a.obo=? AND a.term_id=? ORDER BY b.level ASC, a.ascore DESC;');
	$sth->execute($obo,$term);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{oid}=$term;
			$rec->{dlvl}=$LVL_INFO{$row[0]};
			$rec->{did}="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-diamond fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
			$rec->{ddes}=$row[2];
			$rec->{score}=$row[3];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_scop => $json);


	################
	# pfam
	################
	#SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_pfam as a, pfam_info as b WHERE a.domain_id=b.id AND a.obo="GOBP" AND a.term_id="GO:0002376" ORDER BY b.level ASC, a.ascore DESC;
	
	#SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_pfam as a, pfam_info as b WHERE a.domain_id=b.id AND a.obo="FPO" AND a.term_id="FBcv:0000347" ORDER BY b.level ASC, a.ascore DESC;
	
	$sth = $dbh->prepare('SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_pfam as a, pfam_info as b WHERE a.domain_id=b.id AND a.obo=? AND a.term_id=? ORDER BY b.level ASC, a.ascore DESC;');
	$sth->execute($obo,$term);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{oid}=$term;
			$rec->{dlvl}=$LVL_INFO{$row[0]};
			$rec->{did}="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-diamond fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
			$rec->{ddes}=$row[2];
			$rec->{score}=$row[3];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_pfam => $json);
	
	
	################
	# interpro
	################
	#SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_interpro as a, interpro_info as b WHERE a.domain_id=b.id AND a.obo="PANTHER" AND a.term_id="P00011" ORDER BY b.level ASC, a.ascore DESC;
	
	$sth = $dbh->prepare('SELECT b.level AS dlvl, b.id AS did, b.description AS ddes, a.ascore AS score FROM mapping_interpro as a, interpro_info as b WHERE a.domain_id=b.id AND a.obo=? AND a.term_id=? ORDER BY b.level ASC, a.ascore DESC;');
	$sth->execute($obo,$term);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{oid}=$term;
			$rec->{dlvl}=$LVL_INFO{$row[0]};
			$rec->{did}="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-diamond fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
			$rec->{ddes}=$row[2];
			$rec->{score}=$row[3];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_interpro => $json);
	
	
	################
	# crosslink
	################
	my @crosslink;
	$json = "";
	
	#SELECT a.source_id AS query, a.target AS obo, a.target_id AS oid, b.name AS oname, a.zscore AS zscore, a.adjp AS fdr FROM crosslink as a, term_info as b WHERE a.target=b.obo AND a.target_id=b.id AND a.source="DO" AND a.source_id="DOID:0014667" ORDER BY obo ASC, zscore DESC;
	$sth = $dbh->prepare('SELECT a.source_id AS query, a.target AS obo, a.target_id AS oid, b.name AS oname, a.zscore AS zscore, a.adjp AS fdr FROM crosslink as a, term_info as b WHERE a.target=b.obo AND a.target_id=b.id AND a.source=? AND a.source_id=? ORDER BY obo ASC, zscore DESC;');
	$sth->execute($obo,$term);
	if($sth->rows > 0){
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{query}=$row[0];
			$rec->{obo}=$row[1];
			$rec->{obo_info}=$OBO_INFO{$row[1]};
			$rec->{oid}="<a href='/dcGO/".$row[1]."/".$row[2]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[2];
			#$rec->{oid}=$row[2];
			$rec->{oname}=$row[3];
			$rec->{zscore}=$row[4];
			$rec->{fdr}=$row[5];
			
			push @crosslink,$rec;
		}
	}
	$sth->finish();
	
	# SELECT a.target_id AS query, a.source AS obo, a.source_id AS oid, b.name AS oname, a.zscore AS zscore, a.adjp AS fdr FROM Table_crosslink as a, Table_term_info as b WHERE a.source=b.obo AND a.source_id=b.id AND a.target="HPO" AND a.target_id="HP:0001939" ORDER BY obo ASC, zscore DESC;
	$sth = $dbh->prepare('SELECT a.target_id AS query, a.source AS obo, a.source_id AS oid, b.name AS oname, a.zscore AS zscore, a.adjp AS fdr FROM crosslink as a, term_info as b WHERE a.source=b.obo AND a.source_id=b.id AND a.target=? AND a.target_id=? ORDER BY obo ASC, zscore DESC;');
	$sth->execute($obo,$term);
	if($sth->rows > 0){
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{query}=$row[0];
			$rec->{obo}=$row[1];
			$rec->{obo_info}=$OBO_INFO{$row[1]};
			$rec->{oid}="<a href='/dcGO/".$row[1]."/".$row[2]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[2];
			#$rec->{oid}=$row[2];
			$rec->{oname}=$row[3];
			$rec->{zscore}=$row[4];
			$rec->{fdr}=$row[5];
			
			push @crosslink,$rec;
		}
	}
	$sth->finish();

	print STDERR scalar(@crosslink)."\n";
	if(scalar(@crosslink) > 0){
		$json = encode_json(\@crosslink);
	}
	$c->stash(rec_crosslink => $json);
	
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "dcGO_hie_obo_term.html.ep"
sub dcGO_hie_obo_term {
	my $c = shift;

	my $obo= $c->param("obo");
	my $term= $c->param("term") || "root";
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOdb');
	my $sth;
	
	## Ontology Information
	my %OBO_INFO = (
		"GOBP" => 'Gene Ontology Biological Process (GOBP)',
		"GOCC" => 'Gene Ontology Cellular Component (GOCC)',
		"GOMF" => 'Gene Ontology Molecular Function (GOMF)',
		"HPO" => 'Human Phenotype Ontology (HPO)',
		"MPO" => 'Mammalian Phenotype Ontology (MPO)',
		"WPO" => 'Worm Phenotype Ontology (WPO)',
		"FPO" => 'Fly Phenotype Ontology (FPO)',
		"FAN" => 'Fly Anatomy (FAN)',
		"ZAN" => 'Zebrafish Anatomy (ZAN)',
		"APO" => 'Arabidopsis Plant Ontology (APO)',
		"DO" => 'Disease Ontology (DO)',
		"EFO" => 'Experimental Factor Ontology (EFO)',
		"DGIdb" => 'DGIdb druggable categories (DGIdb)',
		"Bucket" => 'Target tractability buckets (Bucket)',
		"KEGG" => 'KEGG pathways (KEGG)',
		"REACTOME" => 'REACTOME pathways (REACTOME)',
		"PANTHER" => 'PANTHER pathways (PANTHER)',
		"WKPATH" => 'WiKiPathway pathways (WKPATH)',
		"MITOPATH" => "MitoPathway pathways (MITOPATH)",
		"CTF" => 'ENRICHR Consensus TFs (CTF)',
		"TRRUST" => 'TRRUST TFs (TRRUST)',
		"MSIGDB" => 'MSIGDB Hallmarks (MSIGDB)',
	);

	# http://127.0.0.1:3080/dcGO/hie/GOBP/root

	##########
	## rec_term
	## rec_term_child
	
	my $term_data;
	my $json = "";
	
	if($obo eq 'KEGG' or $obo eq 'MSIGDB' or $obo eq 'DGIdb' or $obo eq 'PANTHER' or $obo eq 'WKPATH' or $obo eq 'CTF' or $obo eq 'TRRUST'){
		if($term eq 'root'){
		
			$term_data->{obo}=$OBO_INFO{$obo};
			$term_data->{id}=$term;
			$term_data->{name}=$term;
		
			#SELECT obo,id,name FROM term_info WHERE obo="KEGG" limit 10;
			$sth = $dbh->prepare( 'SELECT obo,id,name FROM term_info WHERE obo=?;' );
			$sth->execute($obo);
			if($sth->rows > 0){
				my @data;
				while (my @row = $sth->fetchrow_array) {
					my $rec;
					$rec->{obo}=$row[0];
					$rec->{id}=$row[1];
					$rec->{name}=$row[2];
					
					my $hie="<i class='fa fa-sitemap fa-1x'></i>&nbsp;&nbsp;";
					$rec->{hie}=$hie;
					
					my $anno="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
					$rec->{anno}=$anno;
					
					#my $hie_anno="<i class='fa fa-sitemap fa-1x'></i>&nbsp;&nbsp;|&nbsp;&nbsp;"."<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>";
					#$rec->{hie_anno}=$hie_anno;
					
					push @data,$rec;
				}
				$term_data->{children}=scalar(@data);
				print STDERR scalar(@data)."\n";
				$json = encode_json(\@data);
		
			}
			$sth->finish();

		}else{
			$term_data="";
		}
		
	}else{
	
		if(exists($OBO_INFO{$obo})){
		
			if($term eq 'root'){
				#SELECT DISTINCT a.obo as obo, a.parent as id, b.name as name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.parent=b.id AND a.obo="MITOPATH" AND a.root="yes";
				
				#SELECT * FROM term_hie as a WHERE a.obo="MITOPATH";
				
				$sth = $dbh->prepare( 'SELECT DISTINCT a.obo as obo, a.parent as id, b.name as name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.parent=b.id AND a.obo=? AND a.root="yes";' );
				$sth->execute($obo);
				if($sth->rows > 0){
					$term_data=$sth->fetchrow_hashref;
					$term_data->{obo}=$OBO_INFO{$obo};
				}else{
					$term_data="";
				}
				$sth->finish();
			
				#SELECT a.obo,a.child,b.name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.child=b.id AND a.obo="GOBP" AND a.root="yes";
				$sth = $dbh->prepare( 'SELECT a.obo,a.child,b.name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.child=b.id AND a.obo=? AND a.root="yes";' );
				$sth->execute($obo);
				if($sth->rows > 0){
					my @data;
					while (my @row = $sth->fetchrow_array) {
						my $rec;
						$rec->{obo}=$row[0];
						$rec->{id}=$row[1];
						$rec->{name}=$row[2];
					
						my $hie="<a href='/dcGO/hie/".$row[0]."/".$row[1]."'<i class='fa fa-sitemap fa-1x'></i></a>&nbsp;&nbsp;";
						$rec->{hie}=$hie;
					
						my $anno="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
						$rec->{anno}=$anno;
			
						push @data,$rec;
					}
					$term_data->{children}=scalar(@data);
					print STDERR scalar(@data)."\n";
					$json = encode_json(\@data);
		
				}
				$sth->finish();
			
			}else{
				#SELECT DISTINCT obo, id, name FROM term_info WHERE obo="GOBP" AND id="GO:0007339";
				$sth = $dbh->prepare( 'SELECT obo, id, name FROM term_info WHERE obo=? AND id=?;' );
				$sth->execute($obo,$term);
				if($sth->rows > 0){
					$term_data=$sth->fetchrow_hashref;
					$term_data->{obo}=$OBO_INFO{$obo};
				}else{
					$term_data="";
				}
				$sth->finish();

				#SELECT a.obo,a.child,b.name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.child=b.id AND a.obo="GOBP" AND a.parent="GO:0001892";
				$sth = $dbh->prepare( 'SELECT a.obo,a.child,b.name FROM term_hie as a, term_info as b WHERE a.obo=b.obo AND a.child=b.id AND a.obo=? AND a.parent=?;' );
				$sth->execute($obo,$term);
				if($sth->rows > 0){
					my @data;
					while (my @row = $sth->fetchrow_array) {
						my $rec;
						$rec->{obo}=$row[0];
						$rec->{id}=$row[1];
						$rec->{name}=$row[2];
					
						my $hie="<a href='/dcGO/hie/".$row[0]."/".$row[1]."'><i class='fa fa-sitemap fa-1x'></i></a>&nbsp;&nbsp;";
						$rec->{hie}=$hie;
					
						my $anno="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'><i class='fa fa-text-width fa-1x'></i></a>&nbsp;&nbsp;".$row[1];
						$rec->{anno}=$anno;
						
						push @data,$rec;
					}
					$term_data->{children}=scalar(@data);
					print STDERR scalar(@data)."\n";
					$json = encode_json(\@data);
		
				}
				$sth->finish();
			
			}
		
		}
	
	}

	$c->stash(term_data => $term_data);
	$c->stash(rec_term_child => $json);

	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "EAdomain.html.ep"
sub EAdomain {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
	my $domain_type = $c->param('domain_type') || 'pfam'; # by default: pfam
  	my $domainlist = $c->param('domainlist');
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $FDR_cutoff = $c->param('FDR_cutoff') || 0.05;
	my $min_overlap = $c->param('min_overlap') || 5;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($domainlist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Domains.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'EAdomain.Domains.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'EAdomain.Domains.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $domainlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/00*
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", domain.type="", obo="", FDR.cutoff="", min.overlap="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		library(tidyverse)
		
		domain.type <- "pfam"
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAdomain_Pfam.txt"
		
		domain.type <- "sf"
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAdomain_SF.txt"
		
		data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
		FDR.cutoff <- 1
		min.overlap <- 3
		obo <- "GOMF"
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
	
	if(FDR.cutoff == "NULL"){
		FDR.cutoff <- 1
	}else{
		FDR.cutoff <- as.numeric(FDR.cutoff)
	}
	
	min.overlap <- as.numeric(min.overlap)

	set <- oRDS(str_c("dcGOdb.SET.", domain.type, "2", obo), placeholder=placeholder)
	background <- set$domain_info %>% pull(id)
	eset <- oSEA(data, set, background, test="fisher", min.overlap=min.overlap)

	if(class(eset)=="eSET"){
		# *_enrichment.txt
		df_eTerm <- eset %>% oSEAextract() %>% filter(adjp < FDR.cutoff)
		df_eTerm %>% write_delim(output.file, delim="\t")
		
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAdomain_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(id)) %>% oSEAdotplot(FDR.cutoff=0.05, label.top=5, size.title="Number of domains", label.direction.y=c("left","right","none")[3], colors=c("#95c11f","#026634"))
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		#output.file.dotplot.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAdomain_enrichment_dotplot.pdf"
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		
		# Forest plot
		if(1){
			message(sprintf("Drawing forest (%s) ...", as.character(Sys.time())), appendLF=TRUE)
			#zlim <- c(0, -log10(df_eTerm$adjp) %>% max() %>% ceiling())
			zlim <- c(0, -log10(df_eTerm$adjp) %>% quantile(0.95) %>% ceiling())
			gp_forest <- df_eTerm %>% mutate(name=str_c(id)) %>% oSEAforest(top=10, colormap="spectral.top", color.title=expression(-log[10]("FDR")), zlim=zlim, legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1], size.title="Number\nof domains", wrap.width=50)		
			output.file.forestplot.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			#output.file.forest.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAdomain_enrichment_forestplot.pdf"
			ggsave(output.file.forestplot.pdf, gp_forest, device=cairo_pdf, width=5, height=3.5)
			output.file.forestplot.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forestplot.png, gp_forest, type="cairo", width=5, height=3.5)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/pier_app/public
		## but outputs at public/tmp/eV2CG.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$data_input <- set$domain_info %>% select(id,level,description) %>% semi_join(tibble(id=data), by="id") %>% set_names(c("Identifier","Level","Description"))
		ls_rmd$min_overlap <- min.overlap
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		ls_rmd$pdf_forestplot <- gsub("public/", "", output.file.forestplot.pdf, perl=T)
		ls_rmd$png_forestplot <- gsub("public/", "", output.file.forestplot.png, perl=T)
		
		output_dir <- gsub("EAdomain.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_EAdomain.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", domain.type=\"$domain_type\", obo=\"$obo\", FDR.cutoff=\"$FDR_cutoff\", min.overlap=\"$min_overlap\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- EAdomain: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_EAdomain.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_EAdomain.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_EAdomain (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_EAdomain.html";
			#public/tmp/digit16_RMD_EAdomain.html
			print STDERR "RMD_EAdomain (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_EAdomain.html
				print STDERR "RMD_EAdomain (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "EAgene.html.ep"
sub EAgene {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $genelist = $c->param('genelist');
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $FDR_cutoff = $c->param('FDR_cutoff') || 0.05;
	my $min_overlap = $c->param('min_overlap') || 5;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($genelist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Genes.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'EAgene.Genes.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'EAgene.Genes.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $genelist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", obo="", FDR.cutoff="", min.overlap="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		library(tidyverse)
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAgene.txt"
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAgene_PMID29121237GenAge.txt"
		
		data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
		FDR.cutoff <- 1
		min.overlap <- 3
		obo <- "MDODD"
		
		obo <- "MitoPathway"
		obo <- "IDPO"
		obo <- "KEGGEnvironmentalOrganismal"
		
		
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
	
	if(FDR.cutoff == "NULL"){
		FDR.cutoff <- 1
	}else{
		FDR.cutoff <- as.numeric(FDR.cutoff)
	}
	
	min.overlap <- as.numeric(min.overlap)

	set <- oRDS(str_c("org.Hs.eg", obo), placeholder=placeholder)
	background <- set$info %>% pull(member) %>% unlist() %>% unique()
	eset <- oSEA(data, set, background, test="fisher", min.overlap=min.overlap)

	if(class(eset)=="eSET"){
		# *_enrichment.txt
		df_eTerm <- eset %>% oSEAextract() %>% filter(adjp < FDR.cutoff)		
		####################
		if(nrow(df_eTerm)==0){
			return(NULL)
		}else{
			df_eTerm %>% write_delim(output.file, delim="\t")
		}
		####################
				
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAgene_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAdotplot(FDR.cutoff=0.05, label.top=5, size.title="Number of genes", label.direction.y=c("left","right","none")[3], colors=c("#95c11f","#026634"))
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		#output.file.dotplot.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAgene_enrichment_dotplot.pdf"
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		
		# Forest plot
		if(1){
			message(sprintf("Drawing forest (%s) ...", as.character(Sys.time())), appendLF=TRUE)
			#zlim <- c(0, -log10(df_eTerm$adjp) %>% max() %>% ceiling())
			zlim <- c(0, -log10(df_eTerm$adjp) %>% quantile(0.95) %>% ceiling())
			gp_forest <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAforest(top=10, colormap="spectral.top", color.title=expression(-log[10]("FDR")), zlim=zlim, legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1], size.title="Number\nof genes", wrap.width=50)
			output.file.forestplot.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			#output.file.forest.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAgene_enrichment_forestplot.pdf"
			ggsave(output.file.forestplot.pdf, gp_forest, device=cairo_pdf, width=5, height=3.5)
			output.file.forestplot.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forestplot.png, gp_forest, type="cairo", width=5, height=3.5)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		gene_info <- oRDS("org.Hs.eg", placeholder=placeholder)
		ls_rmd$data_input <- gene_info$info %>% select(Symbol,description) %>% semi_join(tibble(Symbol=data), by="Symbol") %>% transmute(Genes=Symbol, Description=description)
		ls_rmd$min_overlap <- min.overlap
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		ls_rmd$pdf_forestplot <- gsub("public/", "", output.file.forestplot.pdf, perl=T)
		ls_rmd$png_forestplot <- gsub("public/", "", output.file.forestplot.png, perl=T)
		
		output_dir <- gsub("EAgene.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_EAgene.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", obo=\"$obo\", FDR.cutoff=\"$FDR_cutoff\", min.overlap=\"$min_overlap\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- EAgene: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_EAgene.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_EAgene.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_EAgene (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_EAgene.html";
			#public/tmp/digit16_RMD_EAgene.html
			print STDERR "RMD_EAgene (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_EAgene.html
				print STDERR "RMD_EAgene (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "SAgene.html.ep"
sub SAgene {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $genelist = $c->param('genelist');
  	my $network = $c->param('network') || 'STRING_high'; # by default: STRING_highest
	my $subnet_size = $c->param('subnet_size') || 30;
	my $subnet_sig = $c->param('subnet_sig') || 'yes';
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($genelist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;
		
		my $input_filename=$tmpFolder.'/'.'data.Genes.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'SAgene.Genes.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'SAgene.Genes.'.$digit16.'.r';
	
		my $my_input;
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $genelist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", network="", subnet.size="", subnet.sig="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		library(tidyverse)
		library(igraph)
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_SAgene_PMID27863249hORG.txt"
		data <- read_delim(input.file, delim=" ") %>% as.data.frame() %>% select(1:2)
		network <- "STRING_high"
		subnet.size <- 30
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2)
	
	subnet.size <- as.numeric(subnet.size)
	
	message(sprintf("Performing subnetwork analysis restricted to %d network genes (%s) ...", subnet.size, as.character(Sys.time())), appendLF=TRUE)
	ig <- oDefineNet(network=network, STRING.only=c("experimental_score","database_score"), placeholder=placeholder)
	ig2 <- oNetInduce(ig, nodes_query=V(ig)$name, largest.comp=T) %>% as.undirected()
	
	df_data <- tibble(name=data[,1], pvalue=data[,2]) %>% as.data.frame()
	subg <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder)

	if(vcount(subg)>0){
	
		vec <- V(subg)$significance %>% as.numeric()
		vec[vec==0] <- min(vec[vec!=0])
		V(subg)$logP <- -log10(vec)
	
		subg <- subg %>% oLayout(c("layout_with_kk","graphlayouts.layout_with_stress")[2])
		
		df_subg <- subg %>% oIG2TB("nodes") %>% transmute(Genes=name, Pvalue=as.numeric(significance), Description=description) %>% arrange(Pvalue)
		
		vec <- df_subg$Pvalue
		vec[vec==0] <- min(vec[vec!=0])
		vec <- -log10(vec)
		if(max(vec)<20){
			zlim <- c(0, ceiling(max(vec)))
		}else{
			zlim <- c(0, floor(max(vec)/10)*10)
		}
		
		gp_rating <- oGGnetwork(g=subg, node.label="name", node.label.size=3, node.label.color="black", node.label.alpha=0.95, node.label.padding=0.5, node.label.arrow=0, node.label.force=0.4, node.shape=19, node.xcoord="xcoord", node.ycoord="ycoord", node.color="logP", node.color.title=expression(-log[10]("pvalue")), colormap="spectral.top", zlim=zlim, node.size.range=5, title="", edge.color="steelblue4", edge.color.alpha=0.5, edge.size=0.3, edge.curve=0.05)
		
		
		# *_crosstalk.txt
		df_subg %>% write_delim(output.file, delim="\t")
		# *_crosstalk.xlsx
		output.file.crosstalk <- gsub(".txt$", "_crosstalk.xlsx", output.file, perl=T)
		df_subg %>% openxlsx::write.xlsx(output.file.crosstalk)

		# *_crosstalk.pdf *_crosstalk.png
		output.file.crosstalk.pdf <- gsub(".txt$", "_crosstalk.pdf", output.file, perl=T)
		ggsave(output.file.crosstalk.pdf, gp_rating, device=cairo_pdf, width=6, height=6)
		output.file.crosstalk.png <- gsub(".txt$", "_crosstalk.png", output.file, perl=T)
		ggsave(output.file.crosstalk.png, gp_rating, type="cairo", width=6, height=6)
		
		combinedP <- 1
		if(subnet.sig=="yes"){
			subg.sig <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder, test.permutation=T, num.permutation=10, respect=c("none","degree")[2], aggregateBy="fishers")
			combinedP <- signif(subg.sig$combinedP, digits=2)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/PiER-site/pier_app/public
		## but outputs at public/tmp/SAgene.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		gene_info <- oRDS("org.Hs.eg", placeholder=placeholder)
		ls_rmd$data_input <- gene_info$info %>% select(Symbol,description) %>% inner_join(df_data, by=c("Symbol"="name")) %>% transmute(Genes=Symbol, Pvalue=pvalue, Description=description) %>% arrange(Genes)
		ls_rmd$vcount <- nrow(df_subg)
		ls_rmd$combinedP <- combinedP
		ls_rmd$xlsx_crosstalk <- gsub("public/", "", output.file.crosstalk, perl=T)
		ls_rmd$pdf_crosstalk <- gsub("public/", "", output.file.crosstalk.pdf, perl=T)
		ls_rmd$png_crosstalk <- gsub("public/", "", output.file.crosstalk.png, perl=T)
		
		output_dir <- gsub("SAgene.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_SAgene.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(igraph)

# galahad
vec <- list.files(path='/home/hfang/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", network=\"$network\", subnet.size=\"$subnet_size\", subnet.sig=\"$subnet_sig\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- SAgene: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_SAgene.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_SAgene.html";
			#public/tmp/RMD_SAgene.html	
			print STDERR "RMD_SAgene (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_SAgene.html";
			#public/tmp/digit16_RMD_SAgene.html
			print STDERR "RMD_SAgene (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_SAgene.html
				print STDERR "RMD_SAgene (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "SAsnp.html.ep"
sub SAsnp {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $snplist = $c->param('snplist');
  	my $population = $c->param('pop') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	my $network = $c->param('network') || 'STRING_high'; # by default: STRING_highest
	my $subnet_size = $c->param('subnet_size') || 30;
	my $subnet_sig = $c->param('subnet_sig') || 'yes';
  	
	my $significance_threshold = $c->param('significance_threshold') || 0.05;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($snplist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.SNPs.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'SAsnp.SNPs.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'SAsnp.SNPs.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $snplist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", population="", crosslink="", significance.threshold="", network="", subnet.size="", subnet.sig="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		library(tidyverse)
		library(GenomicRanges)
		library(igraph)
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAsnp.txt"
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAsnp_IND.txt"
		
		#####################
		# for eg_SAregion.txt
		data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2)
		GR.SNP <- oRDS("dbSNP_Common", placeholder=placeholder)
		ind <- match(data$snp, names(GR.SNP))
		gr <- GR.SNP[ind[!is.na(ind)]]
		df_gr <- gr %>% as.data.frame() %>% as_tibble(rownames="snp") %>% transmute(snp,region=str_c(seqnames,":",start,"-",end))
		df_gr %>% inner_join(data, by="snp") %>% select(region,pvalue) %>% write_delim("~/Sites/XGR/XGRplus-site/app/examples/eg_SAregion.txt", delim="\t")
		#####################
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAsnp_IND.txt"
		data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2)
		
		LD.customised <- oRDS("GWAS_LD.EUR", placeholder=placeholder) %>% as.data.frame()
		significance.threshold=5e-5
		distance.max=20000
		relative.importance=c(1/3,1/3,1/3)
		
		crosslink <- "pQTL_Plasma"
		crosslink <- "PCHiC_PMID27863249_Activated_total_CD4_T_cells"
		crosslink <- "proximity_20000"
		
		network <- "STRING_high"
		network <- "KEGG"
		subnet.size <- 30
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2) %>% set_names("snp","pvalue")
	
	if(significance.threshold == "NULL"){
		significance.threshold <- NULL
	}else{
		significance.threshold <- as.numeric(significance.threshold)
	}
	
	if(population=="NA"){
		LD.customised <- NULL
	}else{
		LD.customised <- oRDS(str_c("GWAS_LD.", population), placeholder=placeholder) %>% as.data.frame()
	}
	
	relative.importance <- c(0,0,0)
	include.QTL <- NULL
	include.RGB <- NULL
	if(str_detect(crosslink, "proximity")){
		relative.importance <- c(1,0,0)
		distance.max <- str_replace_all(crosslink, "proximity_", "") %>% as.numeric()
	}else if(str_detect(crosslink, "QTL")){
		relative.importance <- c(0,1,0)
		include.QTL <- crosslink
	}else if(str_detect(crosslink, "PCHiC")){
		relative.importance <- c(0,0,1)
		include.RGB <- crosslink
	}
	
	#GR.SNP <- oRDS("dbSNP_GWAS", placeholder=placeholder)
	GR.SNP <- oRDS("dbSNP_Common", placeholder=placeholder)
	GR.Gene <- oRDS("UCSC_knownGene", placeholder=placeholder)
	
	xGene <- oSNP2xGenes(data, score.cap=100, LD.customised=LD.customised, significance.threshold=significance.threshold, distance.max=distance.max, decay.kernel="constant", GR.SNP=GR.SNP, GR.Gene=GR.Gene, include.QTL=include.QTL, include.RGB=include.RGB, relative.importance=relative.importance, placeholder=placeholder)
	
	subnet.size <- as.numeric(subnet.size)
	
	message(sprintf("Performing subnetwork analysis restricted to %d network genes (%s) ...", subnet.size, as.character(Sys.time())), appendLF=TRUE)
	ig <- oDefineNet(network=network, STRING.only=c("experimental_score","database_score"), placeholder=placeholder)
	ig2 <- oNetInduce(ig, nodes_query=V(ig)$name, largest.comp=T) %>% as.undirected()
	
	df_data <- tibble(name=xGene$xGene$Gene, pvalue=10^(-xGene$xGene$LScore)) %>% as.data.frame()
	subg <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder)

	if(vcount(subg)>0){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(Gene,SNP,SNP_type=ifelse(SNP_Flag=="Lead","Input","LD"),Evidence=Context)
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)

		vec <- V(subg)$significance %>% as.numeric()
		vec[vec==0] <- min(vec[vec!=0])
		V(subg)$logP <- -log10(vec)

		subg <- subg %>% oLayout(c("layout_with_kk","graphlayouts.layout_with_stress")[2])
		
		df_subg <- subg %>% oIG2TB("nodes") %>% transmute(Genes=name, Pvalue=as.numeric(significance), Description=description) %>% arrange(Pvalue)
		
		gp_rating <- oGGnetwork(g=subg, node.label="name", node.label.size=3, node.label.color="black", node.label.alpha=0.95, node.label.padding=0.5, node.label.arrow=0, node.label.force=0.4, node.shape=19, node.xcoord="xcoord", node.ycoord="ycoord", node.color="logP", node.color.title="Linked\ngene\nscores", colormap="spectral.top", zlim=c(0,10), node.size.range=5, title="", edge.color="steelblue4", edge.color.alpha=0.5, edge.size=0.3, edge.curve=0.05)
		
		
		# *_crosstalk.txt
		df_subg %>% write_delim(output.file, delim="\t")
		# *_crosstalk.xlsx
		output.file.crosstalk <- gsub(".txt$", "_crosstalk.xlsx", output.file, perl=T)
		df_subg %>% openxlsx::write.xlsx(output.file.crosstalk)

		# *_crosstalk.pdf *_crosstalk.png
		output.file.crosstalk.pdf <- gsub(".txt$", "_crosstalk.pdf", output.file, perl=T)
		ggsave(output.file.crosstalk.pdf, gp_rating, device=cairo_pdf, width=6, height=6)
		output.file.crosstalk.png <- gsub(".txt$", "_crosstalk.png", output.file, perl=T)
		ggsave(output.file.crosstalk.png, gp_rating, type="cairo", width=6, height=6)
		
		combinedP <- 1
		if(subnet.sig=="yes"){
			subg.sig <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder, test.permutation=T, num.permutation=10, respect=c("none","degree")[2], aggregateBy="fishers")
			combinedP <- signif(subg.sig$combinedP, digits=2)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD %s %f (%s) ...", subnet.sig, combinedP, as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ind <- match(data$snp, names(GR.SNP))
		ls_rmd$data_input <- tibble(SNPs=data$snp[!is.na(ind)], Pvalue=data$pvalue[!is.na(ind)], GR.SNP[ind[!is.na(ind)]] %>% as.data.frame() %>% as_tibble() %>% transmute(Locus=str_c(seqnames,":",start,"-",end)))
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)
		ls_rmd$vcount <- nrow(df_subg)
		ls_rmd$combinedP <- combinedP
		ls_rmd$xlsx_crosstalk <- gsub("public/", "", output.file.crosstalk, perl=T)
		ls_rmd$pdf_crosstalk <- gsub("public/", "", output.file.crosstalk.pdf, perl=T)
		ls_rmd$png_crosstalk <- gsub("public/", "", output.file.crosstalk.png, perl=T)
		
		output_dir <- gsub("SAsnp.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_SAsnp.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)
library(igraph)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", population=\"$population\", crosslink=\"$crosslink\", significance.threshold=\"$significance_threshold\", network=\"$network\", subnet.size=\"$subnet_size\", subnet.sig=\"$subnet_sig\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- SAsnp: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_SAsnp.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_SAsnp.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_SAsnp (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_SAsnp.html";
			#public/tmp/digit16_RMD_SAsnp.html
			print STDERR "RMD_SAsnp (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_SAsnp.html
				print STDERR "RMD_SAsnp (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "EAsnp.html.ep"
sub EAsnp {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $snplist = $c->param('snplist');
  	my $population = $c->param('pop') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $significance_threshold = $c->param('significance_threshold') || 0.05;
	my $FDR_cutoff = $c->param('FDR_cutoff') || 0.05;
	my $min_overlap = $c->param('min_overlap') || 5;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($snplist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.SNPs.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'EAsnp.SNPs.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'EAsnp.SNPs.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $snplist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", population="", crosslink="", significance.threshold="", obo="", FDR.cutoff="", min.overlap="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		library(tidyverse)
		library(GenomicRanges)
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAsnp.txt"
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAsnp_IND.txt"
		
		data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2)
		
		LD.customised <- oRDS("GWAS_LD.EUR", placeholder=placeholder) %>% as.data.frame()
		significance.threshold <- 5e-5
		distance.max <- 2000
		relative.importance <- c(1/3,1/3,1/3)
		
		crosslink <- "pQTL_Plasma"
		crosslink <- "PCHiC_PMID27863249_Activated_total_CD4_T_cells"
		
		FDR.cutoff <- 0.05
		min.overlap <- 3
		obo <- "GOMF"
		
		obo <- "KEGGEnvironmentalOrganismal"
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2) %>% set_names("snp","pvalue")
	
	if(significance.threshold == "NULL"){
		significance.threshold <- 1
	}else{
		significance.threshold <- as.numeric(significance.threshold)
	}
	
	if(FDR.cutoff == "NULL"){
		FDR.cutoff <- 1
	}else{
		FDR.cutoff <- as.numeric(FDR.cutoff)
	}
	
	if(population=="NA"){
		LD.customised <- NULL
	}else{
		LD.customised <- oRDS(str_c("GWAS_LD.", population), placeholder=placeholder) %>% as.data.frame()
	}
	
	relative.importance <- c(0,0,0)
	include.QTL <- NULL
	include.RGB <- NULL
	if(str_detect(crosslink, "proximity")){
		relative.importance <- c(1,0,0)
		distance.max <- str_replace_all(crosslink, "proximity_", "") %>% as.numeric()
	}else if(str_detect(crosslink, "QTL")){
		relative.importance <- c(0,1,0)
		include.QTL <- crosslink
	}else if(str_detect(crosslink, "PCHiC")){
		relative.importance <- c(0,0,1)
		include.RGB <- crosslink
	}
	
	GR.SNP <- oRDS("dbSNP_Common", placeholder=placeholder)
	GR.Gene <- oRDS("UCSC_knownGene", placeholder=placeholder)
	
	xGene <- oSNP2xGenes(data, score.cap=100, LD.customised=LD.customised, significance.threshold=significance.threshold, distance.max=distance.max, decay.kernel="constant", GR.SNP=GR.SNP, GR.Gene=GR.Gene, include.QTL=include.QTL, include.RGB=include.RGB, relative.importance=relative.importance, placeholder=placeholder)
	
	min.overlap <- as.numeric(min.overlap)
	set <- oRDS(str_c("org.Hs.eg", obo), placeholder=placeholder)
	background <- set$info %>% pull(member) %>% unlist() %>% unique()
	eset <- oSEA(xGene$xGene %>% pull(Gene), set, background, test="fisher", min.overlap=min.overlap)

	if(class(eset)=="eSET"){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(SNP,SNP_type=ifelse(SNP_Flag=="Lead","Input","LD"),Gene,Evidence=Context)
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)

		# *_enrichment.txt
		df_eTerm <- eset %>% oSEAextract() %>% filter(adjp < FDR.cutoff)
		####################
		if(nrow(df_eTerm)==0){
			return(NULL)
		}else{
			df_eTerm %>% write_delim(output.file, delim="\t")
		}
		####################
		
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAsnp_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAdotplot(FDR.cutoff=0.05, label.top=5, size.title="Number of genes", label.direction.y=c("left","right","none")[3], colors=c("#95c11f","#026634"))
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		#output.file.dotplot.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAsnp_enrichment_dotplot.pdf"
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		
		# Forest plot
		if(1){
			message(sprintf("Drawing forest (%s) ...", as.character(Sys.time())), appendLF=TRUE)
			#zlim <- c(0, -log10(df_eTerm$adjp) %>% max() %>% ceiling())
			zlim <- c(0, -log10(df_eTerm$adjp) %>% quantile(0.95) %>% ceiling())
			gp_forest <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAforest(top=10, colormap="spectral.top", color.title=expression(-log[10]("FDR")), zlim=zlim, legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1], size.title="Number\nof genes", wrap.width=50)
			output.file.forestplot.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			#output.file.forest.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAsnp_enrichment_forestplot.pdf"
			ggsave(output.file.forestplot.pdf, gp_forest, device=cairo_pdf, width=5, height=3.5)
			output.file.forestplot.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forestplot.png, gp_forest, type="cairo", width=5, height=3.5)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ind <- match(data$snp, names(GR.SNP))
		ls_rmd$data_input <- tibble(SNPs=data$snp[!is.na(ind)], Pvalue=data$pvalue[!is.na(ind)], GR.SNP[ind[!is.na(ind)]] %>% as.data.frame() %>% as_tibble() %>% transmute(Locus=str_c(seqnames,":",start,"-",end)))
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)
		ls_rmd$min_overlap <- min.overlap
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		ls_rmd$pdf_forestplot <- gsub("public/", "", output.file.forestplot.pdf, perl=T)
		ls_rmd$png_forestplot <- gsub("public/", "", output.file.forestplot.png, perl=T)
		
		output_dir <- gsub("EAsnp.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_EAsnp.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", population=\"$population\", crosslink=\"$crosslink\", significance.threshold=\"$significance_threshold\", obo=\"$obo\", FDR.cutoff=\"$FDR_cutoff\", min.overlap=\"$min_overlap\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- EAsnp: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_EAsnp.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_EAsnp.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_EAsnp (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_EAsnp.html";
			#public/tmp/digit16_RMD_EAsnp.html
			print STDERR "RMD_EAsnp (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_EAsnp.html
				print STDERR "RMD_EAsnp (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "EAregion.html.ep"
sub EAregion {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $regionlist = $c->param('regionlist');
  	my $build_conversion = $c->param('build') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $FDR_cutoff = $c->param('FDR_cutoff') || 0.05;
	my $min_overlap = $c->param('min_overlap') || 5;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($regionlist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Regions.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'EAregion.Regions.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'EAregion.Regions.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $regionlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", build.conversion="", crosslink="", obo="", FDR.cutoff="", min.overlap="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		library(tidyverse)
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		#####################
		# for eg_EAregion_PMID35751107TableS2.txt
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_SAregion_PMID35751107TableS2.txt"
		res <- read_delim(input.file, delim="\t") %>% filter(padj<0.05) %>% mutate(chr=str_replace_all(region,":.*","")) %>% mutate(start=str_replace_all(region,".*:|-.*","") %>% as.numeric()) %>% mutate(end=str_replace_all(region,".*-","") %>% as.numeric())
		res %>% select(chr,start,end) %>% write_delim("~/Sites/XGR/XGRplus-site/app/examples/eg_EAregion_PMID35751107TableS2.txt", delim="\t")
		#####################
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_EAregion_PMID35751107TableS2.txt"
		data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:3)
		
		format <- "data.frame"
		build.conversion <- c(NA,"hg38.to.hg19","hg18.to.hg19")
		
		crosslink <- "proximity_20000"
		crosslink <- "RGB.PCHiC_PMID27863249"
		FDR.cutoff <- 0.05
		min.overlap <- 3
		obo <- "GOMF"

	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:3) %>% set_names("chr","start","end")
	
	if(FDR.cutoff == "NULL"){
		FDR.cutoff <- 1
	}else{
		FDR.cutoff <- as.numeric(FDR.cutoff)
	}
	
	if(str_detect(crosslink, "proximity")){
		nearby.distance.max <- str_replace_all(crosslink, "proximity_", "") %>% as.numeric()
		crosslink <- "nearby"
	}
	
	# replace RGB_PCHiC_ with RGB.PCHiC_
	crosslink <- str_replace_all(crosslink, "RGB_", "RGB.")
	
	xGene <- oGR2xGenes(data, format="data.frame", build.conversion=build.conversion, crosslink=crosslink, nearby.distance.max=nearby.distance.max, nearby.decay.kernel="constant", placeholder=placeholder)
	
	min.overlap <- as.numeric(min.overlap)
	set <- oRDS(str_c("org.Hs.eg", obo), placeholder=placeholder)
	background <- set$info %>% pull(member) %>% unlist() %>% unique()
	eset <- oSEA(xGene$xGene %>% pull(Gene), set, background, test="fisher", min.overlap=min.overlap)

	if(class(eset)=="eSET"){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(dGR,GR,Gene,Evidence=Context)
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)

		# *_enrichment.txt
		df_eTerm <- eset %>% oSEAextract() %>% filter(adjp < FDR.cutoff)
		df_eTerm %>% write_delim(output.file, delim="\t")
		
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAregion_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAdotplot(FDR.cutoff=0.05, label.top=5, size.title="Number of genes", label.direction.y=c("left","right","none")[3], colors=c("#95c11f","#026634"))
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		#output.file.dotplot.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAregion_enrichment_dotplot.pdf"
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		
		# Forest plot
		if(1){
			message(sprintf("Drawing forest (%s) ...", as.character(Sys.time())), appendLF=TRUE)
			#zlim <- c(0, -log10(df_eTerm$adjp) %>% max() %>% ceiling())
			zlim <- c(0, -log10(df_eTerm$adjp) %>% quantile(0.95) %>% ceiling())
			gp_forest <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAforest(top=10, colormap="spectral.top", color.title=expression(-log[10]("FDR")), zlim=zlim, legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1], size.title="Number\nof genes", wrap.width=50)		
			output.file.forestplot.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			#output.file.forest.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/EAregion_enrichment_forestplot.pdf"
			ggsave(output.file.forestplot.pdf, gp_forest, device=cairo_pdf, width=5, height=3.5)
			output.file.forestplot.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forestplot.png, gp_forest, type="cairo", width=5, height=3.5)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.Regions.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$data_input <- xGene$GR
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)
		ls_rmd$min_overlap <- min.overlap
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		ls_rmd$pdf_forestplot <- gsub("public/", "", output.file.forestplot.pdf, perl=T)
		ls_rmd$png_forestplot <- gsub("public/", "", output.file.forestplot.png, perl=T)
		
		output_dir <- gsub("EAregion.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_EAregion.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", build.conversion=\"$build_conversion\", crosslink=\"$crosslink\", obo=\"$obo\", FDR.cutoff=\"$FDR_cutoff\", min.overlap=\"$min_overlap\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- EAregion: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_EAregion.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_EAregion.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_EAregion (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_EAregion.html";
			#public/tmp/digit16_RMD_EAregion.html
			print STDERR "RMD_EAregion (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_EAregion.html
				print STDERR "RMD_EAregion (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "SAregion.html.ep"
sub SAregion {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $regionlist = $c->param('regionlist');
  	my $build_conversion = $c->param('build') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	my $network = $c->param('network') || 'STRING_high'; # by default: STRING_highest
	my $subnet_size = $c->param('subnet_size') || 30;
	my $subnet_sig = $c->param('subnet_sig') || 'yes';
  	
	my $significance_threshold = $c->param('significance_threshold') || 0.05;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($regionlist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Regions.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'SAregion.Regions.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'SAregion.Regions.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $regionlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openxgr'){
			# mac
			#$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openxgr";
		}elsif(-e '/var/www/html/bigdata_openxgr'){
			# huawei
			#$placeholder="/var/www/bigdata_fdb";
			$placeholder="/var/www/html/bigdata_openxgr";
		}elsif(-e '/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS'){
			# www.genomicsummary.com
			$placeholder="/data/archive/ULTRADDR/create_ultraDDR_database/dir_output_RDS";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", significance.threshold="", build.conversion="", crosslink="", network="", subnet.size="", subnet.sig="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		library(tidyverse)
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openxgr"
		
		guid=NULL
		verbose=TRUE
		
		input.file <- "~/Sites/XGR/XGRplus-site/app/examples/eg_SAregion_PMID35751107TableS2.txt"
		data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2)
		
		format <- "data.frame"
		build.conversion <- c(NA,"hg38.to.hg19","hg18.to.hg19")
		
		significance.threshold=5e-2
		significance.threshold=NULL
		
		crosslink <- "proximity_20000"
		crosslink <- "RGB.PCHiC_PMID27863249_Combined"
		crosslink <- "RGB_ABC_Encode_Combined"
		network <- "STRING_high"
		subnet.size <- 30

	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame() %>% select(1:2) %>% set_names("region","pvalue]")
	
	if(significance.threshold == "NULL"){
		significance.threshold <- NULL
	}else{
		significance.threshold <- as.numeric(significance.threshold)
	}
	
	if(str_detect(crosslink, "proximity")){
		nearby.distance.max <- str_replace_all(crosslink, "proximity_", "") %>% as.numeric()
		crosslink <- "nearby"
	}
	
	# replace RGB_PCHiC_ with RGB.PCHiC_
	crosslink <- str_replace_all(crosslink, "RGB_", "RGB.")
	
	xGene <- oGR2xGeneScores(data, significance.threshold=significance.threshold, build.conversion=build.conversion, crosslink=crosslink, nearby.distance.max=nearby.distance.max, nearby.decay.kernel="constant", placeholder=placeholder)
	
	subnet.size <- as.numeric(subnet.size)
	
	message(sprintf("Performing subnetwork analysis restricted to %d network genes (%s) ...", subnet.size, as.character(Sys.time())), appendLF=TRUE)
	ig <- oDefineNet(network=network, STRING.only=c("experimental_score","database_score"), placeholder=placeholder)
	ig2 <- oNetInduce(ig, nodes_query=V(ig)$name, largest.comp=T) %>% as.undirected()
	
	df_data <- tibble(name=xGene$xGene$Gene, pvalue=10^(-xGene$xGene$GScore)) %>% as.data.frame()
	subg <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder)

	if(vcount(subg)>0){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(dGR,GR,Gene,Evidence=Context)
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)

		vec <- V(subg)$significance %>% as.numeric()
		vec[vec==0] <- min(vec[vec!=0])
		V(subg)$logP <- -log10(vec)
	
		subg <- subg %>% oLayout(c("layout_with_kk","graphlayouts.layout_with_stress")[2])
		
		df_subg <- subg %>% oIG2TB("nodes") %>% transmute(Genes=name, Pvalue=as.numeric(significance), Description=description) %>% arrange(Pvalue)
		
		gp_rating <- oGGnetwork(g=subg, node.label="name", node.label.size=3, node.label.color="black", node.label.alpha=0.95, node.label.padding=0.5, node.label.arrow=0, node.label.force=0.4, node.shape=19, node.xcoord="xcoord", node.ycoord="ycoord", node.color="logP", node.color.title="Linked\ngene\nscores", colormap="spectral.top", zlim=c(0,10), node.size.range=5, title="", edge.color="steelblue4", edge.color.alpha=0.5, edge.size=0.3, edge.curve=0.05)
		
		
		# *_crosstalk.txt
		df_subg %>% write_delim(output.file, delim="\t")
		# *_crosstalk.xlsx
		output.file.crosstalk <- gsub(".txt$", "_crosstalk.xlsx", output.file, perl=T)
		df_subg %>% openxlsx::write.xlsx(output.file.crosstalk)

		# *_crosstalk.pdf *_crosstalk.png
		output.file.crosstalk.pdf <- gsub(".txt$", "_crosstalk.pdf", output.file, perl=T)
		ggsave(output.file.crosstalk.pdf, gp_rating, device=cairo_pdf, width=6, height=6)
		output.file.crosstalk.png <- gsub(".txt$", "_crosstalk.png", output.file, perl=T)
		ggsave(output.file.crosstalk.png, gp_rating, type="cairo", width=6, height=6)
		
		combinedP <- 1
		if(subnet.sig=="yes"){
			subg.sig <- oSubneterGenes(df_data, network=NA, network.customised=ig2, subnet.size=subnet.size, placeholder=placeholder, test.permutation=T, num.permutation=10, respect=c("none","degree")[2], aggregateBy="fishers")
			combinedP <- signif(subg.sig$combinedP, digits=2)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.Regions.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD %s %f (%s) ...", subnet.sig, combinedP, as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$data_input <- xGene$GR
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)
		ls_rmd$vcount <- nrow(df_subg)
		ls_rmd$combinedP <- combinedP
		ls_rmd$xlsx_crosstalk <- gsub("public/", "", output.file.crosstalk, perl=T)
		ls_rmd$pdf_crosstalk <- gsub("public/", "", output.file.crosstalk.pdf, perl=T)
		ls_rmd$png_crosstalk <- gsub("public/", "", output.file.crosstalk.png, perl=T)
		
		output_dir <- gsub("SAregion.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_SAregion.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)
library(igraph)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
#vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenXGR/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", significance.threshold=\"$significance_threshold\", build.conversion=\"$build_conversion\", crosslink=\"$crosslink\", network=\"$network\", subnet.size=\"$subnet_size\", subnet.sig=\"$subnet_sig\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- SAregion: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_SAregion.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_SAregion.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_SAregion (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_SAregion.html";
			#public/tmp/digit16_RMD_SAregion.html
			print STDERR "RMD_SAregion (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_SAregion.html
				print STDERR "RMD_SAregion (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "dcGO_crosslink.html.ep"
sub dcGO_crosslink {
  	my $c = shift;
	
	################################
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	################################
		
	my $obo= $c->param("obo");
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOdb');
	my $sth;
	
	##########
	## rec_obo
	my %obo;
	$sth = $dbh->prepare('select distinct source,target from crosslink;');
	$sth->execute();
	if($sth->rows > 0){
		while (my @row = $sth->fetchrow_array) {
			$obo{$row[0]}=1;
			$obo{$row[1]}=1;
		}
	}
	$sth->finish();
	print STDERR "obo: ".scalar(keys %obo)."\n";
	$c->stash(rec_obo => \%obo);
	
	
	##########
	## rec_term
	my @term;
	#select a.source,a.source_id,b.name from crosslink as a, term_info as b where a.source=b.obo and a.source_id=b.id and a.source="EFO" limit 10;
	$sth = $dbh->prepare('select a.source,a.source_id,b.name from crosslink as a, term_info as b where a.source=b.obo and a.source_id=b.id;');
	$sth->execute();
	if($sth->rows > 0){
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{obo}=$row[0];
			$rec->{oid}=$row[1];
			$rec->{oname}=$row[2];
			
			push @term,$rec;
		}
	}
	$sth->finish();
	
	#select a.target,a.target_id,b.name from crosslink as a, term_info as b where a.target=b.obo and a.target_id=b.id and a.target="DO" limit 10;
	$sth = $dbh->prepare('select a.target,a.target_id,b.name from crosslink as a, term_info as b where a.target=b.obo and a.target_id=b.id;');
	$sth->execute();
	if($sth->rows > 0){
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{obo}=$row[0];
			$rec->{oid}=$row[1];
			$rec->{oname}=$row[2];
			
			push @term,$rec;
		}
	}
	$sth->finish();
	print STDERR "term: ".scalar(@term)."\n";
	$c->stash(rec_term => \@term);

	##########
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->stash(obo => $obo);
	
  	$c->render();
}


sub dcGO_hie {
	my $c = shift;
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOdb');
	my $sth;
	
	my %hie;
	$sth = $dbh->prepare('select obo,count(id) from term_info group by obo;');
	$sth->execute();
	if($sth->rows>0){
		while (my @row = $sth->fetchrow_array) {
			$hie{$row[0]}=$row[1];
		}
	}
	$sth->finish();
	print STDERR "hie: ".scalar(keys %hie)."\n";
	$c->stash(rec_hie => \%hie);
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
  	$c->render();
}


sub def_ont_did {
	my $c = shift;
	
	my $def= $c->param("def");
	my $ont= $c->param("ont");
	my $did= $c->param("did") || 53118;
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGO');
	my $sth;
	
	my $domain_data="";
	
	if($def eq "fa" or $def eq "sf"){
		if($def eq "fa"){
			$sth = $dbh->prepare( 'SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.parent AS parent FROM des, hie WHERE hie.id=des.id AND des.id=?;' );
			$sth->execute($did);
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$def;
			$domain_data->{scop}="";
			if(!$domain_data->{id}){
				return $c->reply->not_found;
			}else{
				my %pc;
				foreach my $val (split(/,/,$domain_data->{parent})){
					$pc{$val}{$did}=1;
					$domain_data->{scop}.="<a href='/dcGO/sf/$ont/".$val."' target='_blank'><i class='fa fa-diamond'></i>&nbsp;".$val."</a>, ";
				}
				$domain_data->{pc}=\%pc;
				$domain_data->{scop}=~s/, $//g;
			}
			$sth->finish();
			
		}elsif($def eq "sf"){
			$sth = $dbh->prepare( 'SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.children AS children FROM des, hie WHERE hie.id=des.id AND des.id=?;' );
			$sth->execute($did);
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$def;
			$domain_data->{scop}="";
			if(!$domain_data->{id}){
				return $c->reply->not_found;
			}else{
				my %pc;
				foreach my $val (split(/,/,$domain_data->{children})){
					$pc{$did}{$val}=1;
					$domain_data->{scop}.="<a href='/dcGO/fa/$ont/".$val."' target='_blank'><i class='fa fa-diamond'></i>&nbsp;".$val."</a>, ";
				}
				$domain_data->{pc}=\%pc;
				$domain_data->{scop}=~s/, $//g;
			}
			$sth->finish();
			
		}
	}
	$c->stash(domain_data => $domain_data);
	
	## for order and ROOT
	my %OBO_ORDER = (
		'DO' => 1,
		'HP' => 2,
		'MP' => 3,
		'WP' => 4,
		'YP' => 5,
		'FP' => 6,
		'FA' => 7,
		'ZA' => 8,
		'XA' => 9,
		'AP' => 10,
		'EC' => 11,
		'DB' => 12,
		'KW' => 13,
		'UP' => 14,
		'CD' => 15,
		'CC' => 16,
	);
	
	
	if($ont eq "GO" and ($def eq "sf" or $def eq "fa" or $def eq "pfam")){
		if($def eq "sf" or $def eq "fa"){
			#$sth = $dbh->prepare('SELECT id AS did, CONCAT("GO:",go) AS ont, all_fdr_min AS fdr, all_hscore_max AS score FROM GO_mapping WHERE level="fa" AND all_fdr_min IS NOT NULL and all_hscore_max IS NOT NULL AND id=?;');
			
			# http://127.0.0.1:3010/dcGO/fa/GO/53118
			# http://127.0.0.1:3010/dcGO/sf/GO/53098
			
			$sth = $dbh->prepare('SELECT a.id AS did, CONCAT("GO:",a.go) AS oid, a.all_fdr_min AS fdr, a.all_hscore_max AS score, b.classification AS dcla, b.description AS ddes, c.name as oname, c.namespace as onamespace FROM GO_mapping as a, des as b, GO_info as c WHERE a.level=? AND a.all_fdr_min IS NOT NULL and a.all_hscore_max IS NOT NULL AND a.id=? AND a.id=b.id AND a.go=c.go;');
			$sth->execute($def,$did);
		
		}elsif($def eq "pfam"){
			
			# http://127.0.0.1:3010/dcGO/pfam/GO/PF07830
			
			$sth = $dbh->prepare('SELECT a.supradomain AS did, a.id AS oid, a.fdr_min AS fdr, a.hscore_max AS score, b.id AS dcla, b.description AS ddes, c.name as oname, c.namespace as onamespace FROM OBO_mapping as a, PFAM_info as b, OBO_info as c WHERE a.obo="GO" AND a.inherited_from !="" AND a.supradomain=? AND a.supradomain=b.acc AND a.id=c.id;');
			$sth->execute($did);
			
		}
		
	}elsif(exists($OBO_ORDER{$ont}) and ($def eq "sf" or $def eq "fa")){
		if($def eq "sf" or $def eq "fa"){
			# http://127.0.0.1:3010/dcGO/sf/AP/144122
			
			$sth = $dbh->prepare('SELECT a.id AS did, a.po AS oid, a.all_fdr_min AS fdr, a.all_hscore_max AS score, b.classification AS dcla, b.description AS ddes, c.name as oname, c.namespace as onamespace FROM PO_mapping as a, des as b, PO_info as c WHERE a.level=? AND a.all_fdr_min IS NOT NULL and a.all_hscore_max IS NOT NULL AND a.id=? AND a.id=b.id AND a.po=c.po AND a.obo=?;');
			$sth->execute($def,$did,$ont);
		}
		
	}
	
	#SELECT a.id AS did, a.po AS oid, a.all_fdr_min AS fdr, a.all_hscore_max AS score, b.classification AS dcla, b.description AS ddes, c.name as oname, c.namespace as onamespace FROM PO_mapping as a, des as b, PO_info as c WHERE a.level='sf' AND a.all_fdr_min IS NOT NULL and a.all_hscore_max IS NOT NULL AND a.id=144122 AND a.id=b.id AND a.po=c.po AND a.obo='AP';
	
	my $json = "";
	if($sth->rows==0){
		return $c->reply->not_found;
	}else{
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{did}=$row[0];
			$rec->{oid}=$row[1];
			$rec->{fdr}=$row[2];
			$rec->{score}=$row[3];
			$rec->{dcla}=$row[4];
			$rec->{ddes}=$row[5];
			$rec->{oname}=$row[6];
			$rec->{onamespace}=$row[7];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno => $json);
	
	#My_xgrplus::Controller::Utils::export_to_file("a.json", $json);
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


sub dcGO_level_domain_1 {
	my $c = shift;

	my $level= $c->param("level");
	my $domain= $c->param("domain") || 53118;
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOR');
	my $sth;
	
	## Ontology Information
	my %OBO_INFO = (
		"DO" => 'Disease Ontology (DO)',
		"GOBP" => 'Gene Ontology Biological Process (GOBP)',
		"GOCC" => 'Gene Ontology Cellular Component (GOCC)',
		"GOMF" => 'Gene Ontology Molecular Function (GOMF)',
		"HPO" => 'Human Phenotype Ontology (HPO)',
		"MPO" => 'Mammalian Phenotype Ontology (MPO)',
	);
	## Level Information
	my %LVL_INFO = (
		"SCOPsf" => 'SCOP superfamily',
		"SCOPfa" => 'SCOP family',
		"Pfam" => 'Pfam family',
		"InterPro" => 'InterPro family',
	);
	
	my $domain_data="";
	
	if($level eq "SCOPsf" or $level eq "SCOPfa"){
		if($level eq "SCOPfa"){
			$sth = $dbh->prepare( 'SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.parent AS parent FROM des, hie WHERE hie.id=des.id AND des.id=?;' );
			$sth->execute($domain);
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$LVL_INFO{$level};
			$domain_data->{scop}="";
			if(!$domain_data->{id}){
				return $c->reply->not_found;
			}else{
				foreach my $val (split(/,/,$domain_data->{parent})){
					$domain_data->{scop}.="<a href='/dcGO/SCOPsf/".$val."' target='_blank'><i class='fa fa-diamond'></i>&nbsp;".$val."</a>, ";
				}
				$domain_data->{scop}=~s/, $//g;
			}
			$sth->finish();
			
		}elsif($level eq "SCOPsf"){
			$sth = $dbh->prepare( 'SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.children AS children FROM des, hie WHERE hie.id=des.id AND des.id=?;' );
			$sth->execute($domain);
			$domain_data=$sth->fetchrow_hashref;
			$domain_data->{level}=$LVL_INFO{$level};
			$domain_data->{scop}="";
			if(!$domain_data->{id}){
				return $c->reply->not_found;
			}else{
				foreach my $val (split(/,/,$domain_data->{children})){
					$domain_data->{scop}.="<a href='/dcGO/SCOPfa/".$val."' target='_blank'><i class='fa fa-diamond'></i>&nbsp;".$val."</a>, ";
				}
				$domain_data->{scop}=~s/, $//g;
			}
			$sth->finish();
			
		}
	
	}elsif($level eq "Pfam" or $level eq "InterPro"){
		$sth = $dbh->prepare( 'SELECT id,description FROM Table_domain WHERE level=? AND id=?;' );
		$sth->execute($level,$domain);
		$domain_data=$sth->fetchrow_hashref;
		$domain_data->{level}=$LVL_INFO{$level};
		if(!$domain_data->{id}){
			return $c->reply->not_found;
		}
		$sth->finish();
		
	}
	$c->stash(domain_data => $domain_data);
	

	
	# http://127.0.0.1:3010/dcGO/SCOPfa/53118
	# http://127.0.0.1:3010/dcGO/SCOPsf/53098
	# http://127.0.0.1:3010/dcGO/Pfam/PF07830
	
	#SELECT des.id AS id, des.description AS description, des.classification AS classification, hie.parent AS parent FROM des, hie WHERE hie.id=des.id AND des.id=53118;
	#SELECT c.id AS did, c.description AS ddes, b.obo AS obo, b.id AS oid, b.name AS oname, a.score AS score FROM Table_mapping as a, Table_term as b, Table_domain as c WHERE a.term=b.id AND a.id=c.id AND c.level='SCOPfa' AND a.id=53118 ORDER BY obo ASC, score DESC;
	
	$sth = $dbh->prepare('SELECT c.id AS did, c.description AS ddes, b.obo AS obo, b.id AS oid, b.name AS oname, a.score AS score FROM Table_mapping as a, Table_term as b, Table_domain as c WHERE a.term=b.id AND a.id=c.id AND c.level=? AND a.id=? ORDER BY obo ASC, score DESC;');
	$sth->execute($level,$domain);
	my $json = "";
	if($sth->rows==0){
		return $c->reply->not_found;
	}else{
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{did}=$row[0];
			$rec->{ddes}=$row[1];
			$rec->{obo}=$row[2];
			$rec->{oid}="<a href='/dcGO/".$row[2]."/".$row[3]."' target='_blank'>&nbsp;".$row[3]."</a>";
			$rec->{oname}=$row[4];
			$rec->{score}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno => $json);
	
	#My_xgrplus::Controller::Utils::export_to_file("a.json", $json);
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


sub dcGO_obo_term_1 {
	my $c = shift;

	my $obo= $c->param("obo");
	my $term= $c->param("term") || "GO:0008150";
	
	my $dbh = My_xgrplus::Controller::Utils::DBConnect('dcGOR');
	my $sth;
	
	## Ontology Information
	my %OBO_INFO = (
		"DO" => 'Disease Ontology (DO)',
		"GOBP" => 'Gene Ontology Biological Process (GOBP)',
		"GOCC" => 'Gene Ontology Cellular Component (GOCC)',
		"GOMF" => 'Gene Ontology Molecular Function (GOMF)',
		"HPO" => 'Human Phenotype Ontology (HPO)',
		"MPO" => 'Mammalian Phenotype Ontology (MPO)',
	);
	## Level Information
	my %LVL_INFO = (
		"SCOPsf" => 'SCOP superfamily',
		"SCOPfa" => 'SCOP family',
		"Pfam" => 'Pfam family',
		"InterPro" => 'InterPro family',
	);

	my $term_data="";
	
	if(exists($OBO_INFO{$obo})){
		$sth = $dbh->prepare( 'SELECT id,name FROM Table_term WHERE obo=? AND id=?;' );
		$sth->execute($obo,$term);
		$term_data=$sth->fetchrow_hashref;
		$term_data->{obo}=$OBO_INFO{$obo};
		if(!$term_data->{id}){
			return $c->reply->not_found;
		}
		$sth->finish();
		
	}
	$c->stash(term_data => $term_data);
	
	# http://127.0.0.1:3010/dcGO/GOBP/GO:0002376
	
	# SELECT c.level AS dlvl, c.id AS did, c.description AS ddes, b.id AS oid, b.name AS oname, a.score AS score FROM Table_mapping as a, Table_term as b, Table_domain as c WHERE a.term=b.id AND a.id=c.id AND b.obo="GOBP" AND b.id="GO:0002376" ORDER BY level ASC, score DESC;
	
	$sth = $dbh->prepare('SELECT c.level AS dlvl, c.id AS did, c.description AS ddes, b.id AS oid, b.name AS oname, a.score AS score FROM Table_mapping as a, Table_term as b, Table_domain as c WHERE a.term=b.id AND a.id=c.id AND b.obo=? AND b.id=? ORDER BY level ASC, score DESC;');
	$sth->execute($obo,$term);
	my $json = "";
	if($sth->rows==0){
		return $c->reply->not_found;
	}else{
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{dlvl}=$LVL_INFO{$row[0]};
			$rec->{did}="<a href='/dcGO/".$row[0]."/".$row[1]."' target='_blank'>&nbsp;".$row[1]."</a>";
			$rec->{ddes}=$row[2];
			$rec->{oid}=$row[3];
			$rec->{oname}=$row[4];
			$rec->{score}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno => $json);
	
	#My_xgrplus::Controller::Utils::export_to_file("a.json", $json);
	
	My_xgrplus::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "dcGO_enrichment.html.ep"
sub dcGO_enrichment_1 {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "IP address: $ip\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
	my $domain_type = $c->param('domain_type') || 'Pfam'; # by default: Pfam
  	my $domainlist = $c->param('domainlist');
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $significance_threshold = $c->param('significance_threshold') || 0.05;
	my $min_overlap = $c->param('min_overlap') || 5;
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($domainlist)){
		my $tmpFolder = $My_xgrplus::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Domains.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'enrichment.Domains.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'enrichment.Domains.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $domainlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_xgrplus::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_fdb'){
			# mac
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_fdb";
		}elsif(-e '/var/www/bigdata_fdb'){
			# huawei
			$placeholder="/var/www/bigdata_fdb";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/00*
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", domain.type="", obo="", significance.threshold="", min.overlap="", placeholder="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/XGRplus-site
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		input.file <- "~/Sites/XGR/XGRplus-site/my_dcgo/public/app/examples/Pfam.txt"
		data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
		significance.threshold <- 0.05
		min.overlap <- 3
		domain.type <- "Pfam"
		obo <- "GOMF"
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t", col_names=F) %>% as.data.frame() %>% pull(1)
	
	if(significance.threshold == "NULL"){
		significance.threshold <- 1
	}else{
		significance.threshold <- as.numeric(significance.threshold)
	}
	
	min.overlap <- as.numeric(min.overlap)

	set <- oRDS(str_c("dcGOR.SET.", domain.type, "2", obo), placeholder=placeholder)
	#background <- set$info %>% unnest(member) %>% distinct(member) %>% pull(member) %>% unique()
	background <- set$domain_info %>% pull(id)
	eset <- oSEA(data, set, background, test="fisher", min.overlap=min.overlap)

	if(class(eset)=="eSET"){
		# *_enrichment.txt
		df_eTerm <- eset %>% oSEAextract() %>% filter(adjp < significance.threshold)
		df_eTerm %>% write_delim(output.file, delim="\t")
		
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/XGRplus-site/app/examples/dcGO_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(id," (",name,")")) %>% oSEAdotplot(label.top=5, size.title="Number of domains")		
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		#output.file.dotplot.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/dcGO_enrichment_dotplot.pdf"
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		# Forest plot
		if(0){
			gp_forest <- df_eTerm %>% mutate(name=str_c(id," (",name,")")) %>% oSEAforest(top=10, colormap="ggplot2.top", legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1])		
			output.file.forest.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			#output.file.forest.pdf <-  "/Users/hfang/Sites/XGR/XGRplus-site/app/examples/dcGO_enrichment_forest.pdf"
			ggsave(output.file.forest.pdf, gp_forest, device=cairo_pdf, width=5, height=4)
			output.file.forest.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forest.png, gp_forest, type="cairo", width=5, height=4)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/pier_app/public
		## but outputs at public/tmp/eV2CG.SNPs.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$data_input <- set$domain_info %>% semi_join(tibble(id=data), by="id") %>% set_names(c("Identifier","Level","Description"))
		ls_rmd$min_overlap <- min.overlap
		
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		
		output_dir <- gsub("enrichment.*", "", output.file, perl=T)
		
		## rmarkdown
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_enrichment.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[2], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)

# huawei
vec <- list.files(path='/root/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
vec <- list.files(path='/Users/hfang/Sites/XGR/Fang/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", domain.type=\"$domain_type\", obo=\"$obo\", significance.threshold=\"$significance_threshold\", min.overlap=\"$min_overlap\", placeholder=\"$placeholder\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- dcGO_enrichment: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_xgrplus::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_enrichment.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_enrichment.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_enrichment (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_enrichment.html";
			#public/tmp/digit16_RMD_enrichment.html
			print STDERR "RMD_enrichment (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_enrichment.html
				print STDERR "RMD_enrichment (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


1;
