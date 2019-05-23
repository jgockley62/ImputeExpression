# ImputeExpression
Vignette on how to Impute Gene Expression 

## Pull the LDRef Panel
mkdir LDREF . 
cd LDREF/ . 
wget https://data.broadinstitute.org/alkesgroup/FUSION/LDREF.tar.bz2 . 
tar xjvf LDREF.tar.bz2   
cd ..  
  
## Pull the Weights
mkdir Weights . 
aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Chr21_Weights_K9/ALL/ Weights/ --recursive . 

## Pull Ref Data
aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Genotype_Imputed1000G/Binary_Cleaned/chr21/ . --recursive . 
aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Total_IDs.txt .  

## Process Variants and Run Base Association
./plink --bfile AMP-AD_ROSMAP_Rush-Broad_AffymetrixGenechip6_Imputed_chr21_ReNamed --extract LDREF/1000G.EUR.21.bim --make-bed --out foo

## Filt for INDV.
./plink --bfile foo --threads 8 --keep Total_IDs.txt --indiv-sort f Total_IDs.txt --make-bed --out AMP-AD_ROSMAP_forASSOC_21

rm foo.*
./plink --bfile AMP-AD_ROSMAP_forASSOC_21 --assoc --out Chr21_Test_Assoc

## Pull ldsc
git clone https://github.com/bulik/ldsc.git
python ldsc/munge_sumstats.py --sumstats Chr21_Test_Assoc.assoc --out  Chr21_Test_Assoc --N $(grep -v 'CHR' Chr21_Test_Assoc.assoc | wc -l)


## Run Fusion.Assoc:
gunzip Chr21_Test_Assoc.sumstats.gz

## Make The Position File
ls -ltr Weights/ENSG00000*.RDat | awk '{ print $9 }' > K9.lst

aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Make_PositionFile.py .

mkdir GenePos_Files
aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Training_CV_Groups/GenePos_Files/ GenePos_Files/ --recursive
aws s3 cp s3://jkg-s3-synapseencryptedexternalbucket-zszdd03ghnb2/ROSMAP/Score_Impute.sh Score_Impute.sh


python Make_PositionFile.py -GA GenePos_Files/Chr21.txt -WL K9.lst -P Weights/ -T .wgt.RDat -C 21 -o chr21_K9.pos

Rscript /fusion_twas-master/FUSION.assoc_test.R --sumstats Chr21_Test_Assoc.sumstats --weights chr21_K9.pos --weights_dir ./ --ref_ld_chr /fusion_twas-master/LDREF/1000G.EUR. --chr 21 --out K9.chr21.dat

source Score_Impute.sh 9

## Collect Outputs
mkdir Impute
mv Scores/K9.Scores Impute/
mv K9.lst Impute/
mv chr21_K9.pos Impute/
mv K9.chr21.dat Impute/
cp Chr21_Test_Assoc.sumstats Impute/Chr21_Test_Assoc.sumstats
cp Chr21_Test_Assoc.log Impute/Chr21_Test_Assoc.log
cp Chr21_Test_Assoc.assoc Impute/Chr21_Test_Assoc.assoc
