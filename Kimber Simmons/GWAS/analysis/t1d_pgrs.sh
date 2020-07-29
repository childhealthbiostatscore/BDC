#!/bin/bash
cd /Users/timvigers/Documents/OneDrive\ -\ The\ University\ of\ Colorado\ Denver/simmons/x
# Merge Kimber's data with biobank
plink --bfile Simmons_passed_qc --bmerge Simmons_071520 --make-bed --out qc/first_merge
# Exclude problem variants - flipping did not seem to fix this issue
plink --bfile Simmons_passed_qc --make-bed --out qc/Simmons_passed_qc_trimmed --exclude qc/first_merge-merge.missnp
plink --bfile Simmons_071520 --make-bed --out qc/Simmons_071520_trimmed --exclude qc/first_merge-merge.missnp
# Merge again
plink --bfile qc/Simmons_passed_qc_trimmed --bmerge qc/Simmons_071520_trimmed --make-bed --out qc/biobank_simmons_merge
# Add 1000 genomes data
plink --bfile qc/biobank_simmons_merge --bmerge /Users/timvigers/Documents/Work/GWAS/G1K/Phase3/merged/all_phase3_qc --allow-extra-chr --make-bed --out qc/second_merge
# Exclude problem variants - flipping did not seem to fix this issue either
plink --bfile qc/biobank_simmons_merge --make-bed --out qc/biobank_simmons_merge_trimmed --exclude qc/second_merge-merge.missnp --allow-extra-chr
plink --bfile /Users/timvigers/Documents/Work/GWAS/G1K/Phase3/merged/all_phase3_qc --make-bed --out qc/all_phase3_trimmed --exclude qc/second_merge-merge.missnp --allow-extra-chr
# Merge again
plink --bfile qc/biobank_simmons_merge --bmerge qc/all_phase3_trimmed --allow-extra-chr --make-bed --out qc/biobank_simmons_1kg_merge
# QC merged file again
plink2 --bfile qc/biobank_simmons_1kg_merge --autosome-xy --geno 0.02 --make-bed --out qc/biobank_simmons_1kg_merge
plink2 --bfile qc/biobank_simmons_1kg_merge --mind 0.02 --make-bed --out qc/biobank_simmons_1kg_merge
plink2 --bfile qc/biobank_simmons_1kg_merge --maf 0.05 --make-bed --out qc/biobank_simmons_1kg_merge
plink2 --bfile qc/biobank_simmons_1kg_merge --hwe 1e-10 --make-bed --out qc/biobank_simmons_1kg_merge_final
# Kinship check - none (good!)
plink2 --bfile qc/biobank_simmons_1kg_merge --make-king-table --king-table-filter 0.354
# Prune
plink2 --bfile qc/biobank_simmons_1kg_merge --indep-pairwise 50 5 0.2 --out qc/mergeSNP
plink --bfile qc/biobank_simmons_1kg_merge --extract qc/mergeSNP.prune.in --make-bed --out analysis/final_merge
# Delete temp files 
rm qc/biobank_simmons_1kg_merge.bed~ qc/biobank_simmons_1kg_merge.bim~ qc/biobank_simmons_1kg_merge.fam~
# PCA for population stratification
plink2 --bfile analysis/final_merge --pca --out analysis/PCA
plink2 --bfile analysis/final_merge --mds --out analysis/MDS