#INputs to the Script
SampName="K$1"
####SampName='NoMaf'
INPT="chr21_K$1.pos"
####INPT='NoMaf.pos'

Plink_INPT_Files='AMP-AD_ROSMAP_forASSOC_21'

# ROWS IN THE MATRIX TO ANALYZE (FOR BATCHED RUNS)
BATCH_START=1
BATCH_END=$(wc -l $INPT | awk '{print $1 }')

# THIS IS DIRECTORY WHERE THE OUTPUT WILL GO:
mkdir --parents Scores/$SampName
OUTDIR=Scores/$SampName
UpperOutDir=Scores
# Loop through each gene expression phenotype in the batch
cat $INPT | awk -vs=$BATCH_START -ve=$BATCH_END 'NR > s && NR <= e' |  while read PARAM; do

	ENSG=`echo $PARAM | awk '{ print $2 }'`
	FILE=`echo $PARAM | awk '{ print $1 }'`
	#echo $FILE $ENSG
	#Make Scores
	Rscript ./utils/make_score.R $FILE > Temp.Score

	OUTFILE=$OUTDIR/$ENSG.Score
	./plink --bfile $Plink_INPT_Files --threads 8 --silent --score Temp.Score 1 2 4 --out $OUTFILE

	#Replace Socre with ENSG
	sed -i 's/SCORE/'$ENSG'/g' $OUTFILE.profile

done

#Clean-up Temp file
rm Temp.Score

#Collect Names of Files:
ls -ltr $OUTDIR | grep '.Score.profile' - | awk '{ print $9 }' - > Temp.Files
BATCH_START=0
BATCH_END==$(wc -l Temp.Files | awk '{print $1 }')
i=0
cat Temp.Files | awk -vs=$BATCH_START -ve=$BATCH_END 'NR > s && NR <= e' |  while read PARAM; do
	
File=$OUTDIR/$PARAM
#echo $File
	
if [[ $i == 0 ]]; then
i=1
awk '{ print $1"\t"$2"\t"$3"\t"$6 }' $File > $UpperOutDir/$SampName.Scores

else
awk '{ print $6 }' $File | paste $UpperOutDir/$SampName.Scores - > Temp.Scores
mv Temp.Scores $UpperOutDir/$SampName.Scores

fi
done
