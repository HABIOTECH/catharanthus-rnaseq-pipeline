--------------------------------------------------------------------------------
 STEP 9 - EXTRACT DEG SEQUENCES (PYTHON)
--------------------------------------------------------------------------------
Pulls each DEG's nucleotide sequence from the genome FASTA using GFF
coordinates, writes them to FASTA, and exports a summary spreadsheet.

NOTE: the parser reads GFF3-style key=value attributes. If your file is GTF
(key "value"), adjust the attribute parsing accordingly.

import pandas as pd
from Bio import SeqIO

# --- Paths to your files ---
gff_file     = 'path_to_your_file.gff'
genome_fasta = 'path_to_your_genome.fasta'
deg_file     = 'path_to_deg_results.txt'

# --- Read DEG results ---
deg_df    = pd.read_csv(deg_file, sep='\t')
deg_genes = set(deg_df['gene_id'].tolist())

# --- Parse GFF to map locus_tags to gene information ---
gene_info = {}
with open(gff_file, 'r') as gff:
    for line in gff:
        if line.startswith('#'):
            continue
        parts = line.strip().split('\t')
        if parts[2] == 'gene':
            attributes = parts[8]
            attr_dict = {key: value.strip('"') for key, value in
                         (item.split('=') for item in attributes.split(';') if '=' in item)}
            locus_tag = attr_dict.get('locus_tag')
            product   = attr_dict.get('product', 'hypothetical protein')
            if locus_tag in deg_genes:
                gene_info[locus_tag] = {
                    'seqid':  parts[0],
                    'start':  int(parts[3]),
                    'end':    int(parts[4]),
                    'strand': parts[6],
                    'product': product
                }

# --- Extract sequences from genome FASTA ---
sequences = {}
for record in SeqIO.parse(genome_fasta, 'fasta'):
    for locus_tag, info in gene_info.items():
        if record.id == info['seqid']:
            gene_seq = record.seq[info['start'] - 1:info['end']]
            if info['strand'] == '-':
                gene_seq = gene_seq.reverse_complement()
            sequences[locus_tag] = gene_seq

# --- Write sequences to FASTA ---
with open('deg_sequences.fasta', 'w') as fasta_out:
    for locus_tag, seq in sequences.items():
        fasta_out.write(f'>{locus_tag} {gene_info[locus_tag]["product"]}\n{seq}\n')

# --- Prepare Excel summary ---
excel_data = [{
    'gene_id': locus_tag,
    'product': info['product'],
    'length':  len(sequences[locus_tag])
} for locus_tag, info in gene_info.items()]

pd.DataFrame(excel_data).to_excel('gene_info.xlsx', index=False)
