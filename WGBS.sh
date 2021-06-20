#!/usr/bin/bash

help() {
    echo "Usage:"
    echo "test.sh [-f forward_fq] [-r reverse_fq] [-g reference]"
    echo "Description:"
    echo "-f forward_fq,the path of forward_fq,fq.gz also can be use."
    echo "-r reverse_fq,the path of reverse_fq,fq.gz also can be use."
    echo "-n sample name"
    echo "-g the path of reference genome"
    
    exit -1
}

while getopts 'f:r:n:g:' OPT; do
    case $OPT in
        f) forward_fq="$OPTARG";;
        r) reverse_fq="$OPTARG";;
        n) sample_name="$OPTARG";;
        g) reference="$OPTARG";;
        h) help;;
        ?) help;;
    esac
done

if [ -z $forward_fq ] || [ -z $reverse_fq ] || [ -z $reference ]; then
  echo 'error,need args'
  help
  exit
fi

## creat folder

#folder=(rawdata fastqc cutadapt trim mapping call_site conversion_rate_call_site  conversion_rate_mapping)
for  i in ${folder[*]} ; do
  if [ ! -d ../$i ]; then
    mkdir ../$i
    echo creat $i
  fi
done


## 去接头前指控
# fastqc -o ../fastqc $forward_fq $reverse_fq

cutadapt -j 2 -a AGATCGGAAGAG -A AGATCGGAAGAG -o ../cutadapt/${samplename}_cuta_1.fq.gz -p ../cutadapt/${samplename}_cuta_2.fq.gz  $forward_fq $reverse_fq

trimmomatic PE -phred33 ../cutadapt/${samplename}_cuta_1.fq.gz ../cutadapt/${samplename}_cuta_2.fq.gz  ../trim/${samplename}_trim_1.fq.gz ../trim/${samplename}_unpair_1.fq.gz  ../trim/${samplename}_trim_2.fq.gz ../trim/${samplename}_unpair_2.fq.gz LEADING:20 TRAILING:20 SLIDINGWINDOW:4:20 MINLEN:35

## 去接头后指控
fastqc -t 3  -o ../fastqc ../trim/${samplename}_trim_1.fq.gz ../trim/${samplename}_trim_2.fq.gz

## 先计算转化率
bismark --genome /public1/home/sc60357/reference/lambda/ -1 ../trim/${samplename}_trim_1.fq.gz -2 ../trim/${samplename}_trim_2.fq.gz --path_to_bowtie2 /public1/home/sc60357/miniconda3/envs/python3/bin/  -o ../conversion_rate_mapping 

deduplicate_bismark --paired --outfile ${samplename}  --output_dir  ../conversion_rate_mapping  ../conversion_rate_mapping/${samplename}_trim_1_bismark_bt2_pe.bam

bismark_methylation_extractor --paired-end --comprehensive --output  ../conversion_rate_call_site --bedGraph --cytosine_report --genome_folder  /public1/home/sc60357/reference/lambda/ ../conversion_rate_mapping/${samplename}.deduplicated.bam


## 比对去重call位点
bismark --genome /public1/home/sc60357/reference/human/GRCh38.p13_Release_36  -1 ../trim/${samplename}_trim_1.fq.gz -2 ../trim/${samplename}_trim_2.fq.gz --path_to_bowtie2 /public1/home/sc60357/miniconda3/envs/python3/bin/  -o ../mapping 

deduplicate_bismark --paired --outfile ${samplename}  --output_dir  ../mapping  ../mapping/${samplename}_trim_1_bismark_bt2_pe.bam

bismark_methylation_extractor --paired-end --comprehensive --output  ../call_site  --bedGraph --cytosine_report --genome_folder  /public1/home/sc60357/reference/human/GRCh38.p13_Release_36  ../mapping/${samplename}.deduplicated.bam
