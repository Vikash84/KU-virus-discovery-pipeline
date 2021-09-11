nextflow.enable.dsl=2
include { qc_nanopore } from './modules/0_qc'
include { filter_nanopore } from './modules/1_filter'
include { reference_map_nanopore } from './modules/2_reference_map'
include { classify_reads } from './modules/3_classify_reads'
include { assemble_nanopore } from './modules/4_assemble'
include { polish } from './modules/4_2_polish'
include { analyze_contigs } from './modules/5_analyze_contigs'

if(params.help) {
    log.info ''
    log.info 'KU virus discovery pipeline - long read (Nanopore) version'
    log.info ''
    log.info 'Usage: '
    log.info '    nextflow run main.nf [options]'
    log.info ''
    log.info 'Script Options: '
    log.info '    --input        FILE    Path to FASTQ file'
    log.info '    --prefix        STR    Nickname given to sample'
    log.info '    --outdir         DIR      Name of output directory'
    log.info ''

    return
}

// workflow module
workflow {
    main:
        fastq = channel.fromPath(params.input, checkIfExists:true)

        // fastq quality control
        qc_nanopore(fastq)

        // filter too short/low quality and host-derived reads
        filtered = filter_nanopore(fastq)

        // reference mapping with provided virus sequence lists
        reference_map_nanopore(filtered)

        // read taxon classification
        classify_reads(filtered)

        // de novo assembly
        contigs = assemble(filtered)

        // post-assembly work
        polished_contigs = polish(contigs, fastq)

        // contigs homology search and functional analysis
        analyze_contigs(polished_contigs)
}