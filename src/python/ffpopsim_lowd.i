/**
 * Copyright (c) 2012, Richard Neher, Fabio Zanini
 * All rights reserved.
 *
 * This file is part of FFPopSim.
 *
 * FFPopSim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FFPopSim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FFPopSim. If not, see <http://www.gnu.org/licenses/>.
 */

/* renames and ignores */
%ignore hypercube_lowd;
%ignore haploid_lowd_test;

/* additional helper functions */
%pythoncode {
def binarify(gt, L=0):
    '''Transform an integer into a binary sequence on the L hypercube.

    Parameters:
       - gt: integer representing a genotype
       - L: number of dimensions of the hypercube

    Returns:
       - genotype: bool vector representing the same genotype

    **Examples**:

    .. sourcecode:: ipython

       In [1]: binarify(3, 5)
       Out[1]: array([False, False, False,  True,  True], dtype=bool)

       In [2]: FFPopSim.binarify(0b11, 5)
       Out[2]: array([False, False, False,  True,  True], dtype=bool)       
    '''
    import numpy as np
    if not L:
        L=1
        while gt > ((1<<L) - 1):
            L += 1
    return np.array(map(lambda l: bool(gt&(1<<(L-l-1))),range(L)))


def integerify(b):
    '''Transform a binary sequence on the HC into an integer.

    Parameters:
       - b: bool vector representing a genotype

    Returns:
       - gt: integer representing the same genotype

    **Examples**:

    .. sourcecode:: ipython

       In [1]: integerify([False, True, True])
       Out[1]: 3
    '''
    import numpy as np
    L = len(b)
    a = [(1<<(L-l-1)) for l in xrange(L)]
    return np.dot(b,a)
}

/**** HAPLOID_LOWD ****/
%define DOCSTRING_HAPLOID_LOWD
"Class for low-dimensional population genetics (short genomes ~20 loci).

The class offers a number of functions, but an example will explain the basic idea::

    #####################################
    #   EXAMPLE SCRIPT                  #
    #####################################
    import numpy as np
    import matplotlib.pyplot as plt
    import FFPopSim as h
    
    c = h.haploid_lowd(5)               # 5 loci

    # initialize with 300 individuals with genotype 00000,
    # and 700 with genotype 00010
    c.set_genotypes([0, 2], [300, 700])
 
    # set an additive fitness landscape with these coefficients
    c.set_fitness_additive([0.02,0.03,0.04,0.02, -0.03])
    # Note: we are in the -/+ basis, so
    #        F[10000] - F[00000] = 2 * 0.02 
    # Hence the coefficients are half of the effect of mutation on fitness 

    c.evolve(100)                       # evolve for 100 generations
    c.plot_diversity_histogram()
    plt.show()
    #####################################
"
%enddef
%feature("autodoc", DOCSTRING_HAPLOID_LOWD) haploid_lowd;
%extend haploid_lowd {

/* constructor */
%define DOCSTRING_HAPLOID_LOWD_INIT
"Construct a low-dimensional population with certain parameters.

Parameters:
    - L : number of loci (at least 1)
    - rng_seed : seed for the random number generator    
"
%enddef
%feature("autodoc", DOCSTRING_HAPLOID_LOWD_INIT) haploid_lowd;
%exception haploid_lowd {
        try {
                $action
        } catch (int err) {
                PyErr_SetString(PyExc_ValueError,"Construction impossible. Please check input args.");
                SWIG_fail;
        }
}

/* string representations */
const char* __str__() {
        static char buffer[255];
        sprintf(buffer,"haploid_lowd: L = %d, N = %f", (int)$self->L(), $self->N());
        return &buffer[0];
}

const char* __repr__() {
        static char buffer[255];
        sprintf(buffer,"<haploid_lowd(%d, %g)>", (int)$self->L(), $self->N());
        return &buffer[0];
}

/* TODO: ignore hypercubes for now */
%ignore fitness;
%ignore population;

/* read/write attributes */
%feature("autodoc", "is the genome circular?") circular;
%feature("autodoc", "current carrying capacity of the environment") carrying_capacity;
%feature("autodoc", "outcrossing rate (probability of sexual reproduction per generation)") outcrossing_rate;

/* read only attributes */
%ignore L;
%ignore N;
%rename (_get_number_of_loci) get_number_of_loci;
%rename (_get_population_size) get_population_size;
%rename (_get_generation) get_generation;
%pythoncode {
L = property(_get_number_of_loci)
N = property(_get_population_size)
number_of_loci = property(_get_number_of_loci)
population_size = property(_get_population_size)
generation = property(_get_generation)
}
%feature("autodoc", "number of loci (read-only)") get_number_of_loci;
%feature("autodoc", "population size (read-only)") get_population_size;
%feature("autodoc", "current generation (read-only)") get_generation;

/* recombination model */
%rename (_get_recombination_model) get_recombination_model;
%rename (_set_recombination_model) set_recombination_model;
%pythoncode {
@property
def recombination_model(self):
    '''Model of recombination to use

    Available values:

       - FFPopSim.FREE_RECOMBINATION: free shuffling between parents
       - FFPopSim.CROSSOVERS: block recombination with crossover probability
       - FFPopSim.SINGLE_CROSSOVER: block recombination with crossover probability
    '''
    return self._get_recombination_model()


@recombination_model.setter
def recombination_model(self, value):
    err = self._set_recombination_model(value)
    if err == HG_BADARG:
        raise ValueError("Recombination model nor recognized.")
    elif err == HG_MEMERR:
        raise MemoryError("Unable to allocate/release memory for the recombination patterns.")


}

/* status function */
%pythoncode {
def status(self):
    '''Print a status list of the population parameters'''
    parameters = (('number of loci', 'L'),
                  ('circular', 'circular'),
                  ('population size', 'N'),
                  ('carrying capacity', 'carrying_capacity'),
                  ('generation', 'generation'),
                  ('outcrossing rate', 'outcrossing_rate'),
                  ('recombination model', 'recombination_model'),
                 )
    lenmax = max(map(lambda x: len(x[0]), parameters))

    for (strin, name) in parameters:
        par = getattr(self, name)
        # Recombination model needs a conversion
        # (a very frequently used one, to be honest)
        if strin == 'recombination model':
            if par == 0:
                par = 'FREE_RECOMBINATION'
            elif par == 1:
                par = 'SINGLE_CROSSOVER'
            else:
                par = 'CROSSOVERS'
        print ('{:<'+str(lenmax + 2)+'s}').format(strin)+'\t'+str(par)
}

/* initialize frequencies */
%ignore set_allele_frequencies;
int _set_allele_frequencies(int DIM1, double *IN_ARRAY1, unsigned long N) {return $self->set_allele_frequencies(IN_ARRAY1, N);}
%pythoncode {
def set_allele_frequencies(self, frequencies, N):
    '''Initialize the population in linkage equilibrium with specified allele frequencies.

    Parameters:
       - frequencies: an array of length L with all allele frequencies
       - N: set the population size and, if still unset, the carrying
         capacity to this value

    .. note:: the population size is only used for resampling and has therefore
              no effect on the speed of the simulation.
    '''
    if len(frequencies) != self.L:
        raise ValueError('The input array of allele frequencies has the wrong length.')
    if self._set_allele_frequencies(frequencies, N):
        raise RuntimeError('Error in the C++ function.')
}

/* initialize genotypes */
%ignore set_genotypes;
%apply (int DIM1, double* IN_ARRAY1) {(int len1, double* indices), (int len2, double* vals)};
int _set_genotypes(int len1, double* indices, int len2, double* vals) {
        vector<index_value_pair_t> gt;
        index_value_pair_t temp;
        for(size_t i = 0; i != (size_t)len1; i++) {
                temp.index = (int)indices[i];
                temp.val = vals[i];
                gt.push_back(temp);
        }
        return $self->set_genotypes(gt);
}
%clear (int len1, double* indices);
%clear (int len2, double* vals);
%pythoncode {
def set_genotypes(self, genotypes, counts):
    '''Initialize population with fixed counts for specific genotypes.

    Parameters:
       - genotypes: list of genotypes to set. Genotypes are specified as integers,
                    from 00...0 that is 0, up to 11...1 that is 2^L-1.
       - counts: list of counts for those genotypes

    .. note:: the population size and, if unset, the carrying capacity will be set as the sum of the counts.
    .. note:: you can use Python binary notation for the indices, e.g. 0b0110 is 6.
    '''
    import numpy as np
    genotypes = np.asarray(genotypes, float)
    counts = np.asarray(counts, float)
    if len(genotypes) != len(counts):
        raise ValueError('Indices and counts must have the same length')
    if self._set_genotypes(genotypes, counts):
        raise RuntimeError('Error in the C++ function.')
}

/* initialize wildtype */
%feature("autodoc",
"Initialize population of N individuals with the - allele at all loci (wildtype)

Parameters:
   - N: the number of individuals

.. note:: the carrying capacity is set to the same value if still unset.
") set_wildtype;

/* set recombination rates */
%rename (_set_recombination_rates) set_recombination_rates;
%typemap(in) double *rec_rates {
        /* Ensure input is a Python sequence */
        PyObject *tmplist = PySequence_Fast($input, "I expected a sequence");
        unsigned long L = PySequence_Length(tmplist);

        /* Get circular and L properties from the class (we are in the Python world here) */
        bool circular = (bool)PyInt_AsLong(PyObject_GetAttrString($self, "circular"));
        unsigned long Lint = PyInt_AsLong(PyObject_GetAttrString($self, "L"));

        /* Check lengths */
        if((!(circular)) && (L != Lint - 1)) {
                PyErr_SetString(PyExc_ValueError, "Expecting an array of length L-1.");
                SWIG_fail;
        }        
        if((circular) && (L != Lint)) {
                PyErr_SetString(PyExc_ValueError, "Expecting an array of length L.");
                SWIG_fail;
        } 

        /* Create C array from Python list */
        $1 = new double[L];
        double tmpdouble;
        for(size_t i=0; i < L; i++) {
                tmpdouble = (double)PyFloat_AsDouble(PySequence_Fast_GET_ITEM(tmplist, i));
                if (tmpdouble < 0) {
                        PyErr_SetString(PyExc_ValueError,"Expecting a sequence of positive floats");
                        SWIG_fail;
                }
                $1[i] = tmpdouble;
        }
}
%typemap(freearg) double *rec_rates {
  if($1) delete[] $1;
}
%pythoncode {
def set_recombination_rates(self, rates, model=None):
    '''Set the recombination rate(s).

Parameters:
    - rates: if a double, the recombination rate at between any two loci; if an array,
      the locus-specific recombination rates
    - model: the recombination model to use (CROSSOVERS or, for linear
      genomes, SINGLE_CROSSOVER)

.. note:: if locus-specific rates are specified, the array must have length
          (L-1) for linear chromosomes and length L for circular ones. The
          i-th element is the crossover rate between the i-th site and the
          (i+1)-th site.

.. note:: if the recombination model is not specified, the current model will be kept or,
          if the current model is FREE_RECOMBINATION, then CROSSOVERS will be set.
    '''

    import numpy as np

    # Default recombination model
    if model is None:
        if self.recombination_model != FREE_RECOMBINATION:
            model = self.recombination_model
        else:
            model = CROSSOVERS

    # Check whether the model makes sense
    if model == FREE_RECOMBINATION:
        raise ValueError("Cannot assign rates to free recombination!")
    if model not in (CROSSOVERS, SINGLE_CROSSOVER):
        raise ValueError("Model not recognized.")
    if (self.circular and (model == SINGLE_CROSSOVER)):
        raise ValueError("Single crossover not available for circular genomes.") 

    # Check whether the chromosome is circular
    if self.circular:
        len_rates = self.L
    else:
        len_rates = self.L - 1

    # Check whether the input argument is a list or a scalar
    if np.isscalar(rates):
        self._set_recombination_rates([rates] * len_rates, model)

    elif len(rates) != len_rates:
        raise ValueError("Expecting an array of length "+str(len_rates)+".")
    else:
        self._set_recombination_rates(rates, model)

}

/* mutation rate(s) */
%rename (_get_mutation_rate) get_mutation_rate;
%pythoncode {
def get_mutation_rates(self, locus=None, direction=None):
    '''Get one or several mutation rates.

Parameters:
    - locus: get only the mutation rate(s) of this locus
    - direction: get only the forward or backward mutation rate(s). This argument
                 is a Boolean, 0/False for forward rates, 1/True for backward rates.

Returns:
    - the mutation rate(s) requested

**Note**: if the mutation rates for all loci and/or directions are the same,
this function will try to be smart and give you the answer you are looking for.
In case of doubt, you will get a matrix (L x 2) with the full mutation rate
landscape.
    '''

    import numpy as np
    if locus is not None:
        if not np.isscalar(locus):
            raise TypeError('Please select a *single* locus or no locus at all.')
        if direction is not None:
            return self._get_mutation_rate(locus, direction)
        else:
            mrs = tuple([self._get_mutation_rate(locus, d) for d in [0,1]])
            if mrs[0] == mrs[1]:
                return mrs[0]
            else:
                return mrs
    else:
        if direction is not None:
            mrs = np.array([self._get_mutation_rate(l, direction) for l in xrange(self.L)])
            if len(np.unique(mrs)) == 1:
                return mrs[0]
            else:
                return mrs
        else:
            mrs = np.array([[self._get_mutation_rate(l, d) for l in xrange(self.L)] for d in [0,1]])
            if len(np.unique(mrs)) == 1:
                return mrs[0,0]
            else:
                return mrs
}

%ignore set_mutation_rates;
int _set_mutation_rates(double *IN_ARRAY2, int DIM1, int DIM2) {
        double ** mrs = new double*[2];
        for(size_t i = 0; i < 2; i++)
                mrs[i] = &(IN_ARRAY2[DIM2 * i]);
        int result = $self->set_mutation_rates(mrs);
        delete[] mrs;
        return result;
}
%pythoncode{        
def set_mutation_rates(self, rates, rates_back=None):
    '''Set the mutation rate(s).

Parameters:
    - rates:if a double, the mutation rate at any locus in both directions
      or, if rates_back is not None, only in the forward direction

      if a vector, the mutation rate is specified for each locus, the same
      in both directions or, if rates_back is not None, only in the
      forward direction

    - rates_back: mutation rate in the backward direction (global or
      locus-specific)
    '''

    import numpy as np
    L = self.L
    if np.isscalar(rates):
        if rates_back is None:
            ratesm = np.repeat(rates, L * 2).reshape(2,L)
        else:
            ratesm = np.vstack([np.repeat(rates, L), np.repeat(rates_back, L)])
    elif (np.rank(rates) != 1) or ((rates_back is not None) and (np.rank(rates_back) != 1)):
        raise ValueError('Please input one/two numbers or arrays.')
    else:
        if rates_back is None:
            ratesm = np.vstack([rates, rates])
        else:
            ratesm = np.vstack([rates, rates_back])

    if self._set_mutation_rates(ratesm):
        raise RuntimeError('Error in the C++ function.')
}

/* evolve */
%feature("autodoc",
"Evolve for some generations

Parameters:
    - gen: number of generations to evolve the population, defaults to one
") evolve;

%feature("autodoc",
"Evolve for some generations deterministically (skips the resampling)

Parameters:
    - gen: number of generations to evolve the population
") evolve_deterministic;

%feature("autodoc",
"Evolve for some generations without recombination

Parameters:
    - gen: number of generations to evolve the population
") evolve_norec;


/* genotype frequencies */
%pythoncode {
def get_genotype_frequencies(self):
    '''Get the frequency of each genotype.'''
    import numpy as np
    return np.array([self.get_genotype_frequency(l) for l in xrange(1<<self.L)])
}

%feature("autodoc",
"Get the frequency of a genotype

Parameters:
    - genotype: genotype, whose the frequency is to be returned

Returns:
    - the frequency of the genotype
") get_genotype_frequency;

/* allele frequencies */
%pythoncode {
def get_allele_frequencies(self):
    '''Get the frequencies of all + alleles'''
    import numpy as np
    return np.array([self.get_allele_frequency(l) for l in xrange(self.L)])
}

%feature("autodoc",
"Get the frequency of the + allele

Parameters:
    - locus: locus, at which the frequency of the + allele is to be computed

Returns:
    - the frequency of the + allele, :math:`\\nu_i := \\frac{1 + \\left<s_i\\right>}{2}`, where :math:`s_i \in \{-1, 1\}`.
") get_allele_frequency;

%feature("autodoc",
"Get the frequency of genotypes with the + allele at both loci.

Parameters:
    - locus1: first locus
    - locus2: second locus

Returns:
    - the joint frequency of the + alleles
") get_pair_frequency;

%feature("autodoc",
"Get chi of an allele in the -/+ basis

Parameters:
    - locus: locus whose chi is to be computed

Returns:
    - the chi of that allele, :math:`\\chi_i := \\left<s_i\\right>`, where :math:`s_i \in \{-1, 1\}`.
") get_chi;

%feature("autodoc",
"Get :math:`\\chi_{ij}`

Parameters:
    - locus1: first locus
    - locus2: second locus

Returns:
    - the linkage disequilibiurm between them, i.e. :math:`\\chi_{ij} := \\left<s_i s_j\\right> - \\chi_i \\cdot \\chi_j`.
") get_chi2;

%feature("autodoc",
"Get linkage disequilibrium

Parameters:
    - locus1: first locus
    - locus2: second locus

Returns:
    - the linkage disequilibiurm between them, i.e. :math:`D_{ij} := 1 / 4 \\left[\\left<s_i s_j\\right> - \\chi_i \\cdot \\chi_j\\right]`.
") get_LD;

%feature("autodoc",
"Get moment of two alleles in the -/+ basis

Parameters:
    - locus1: first locus
    - locus2: second locus

Returns:
    - the second moment, i.e. :math:`\\left<s_i s_j\\right>`, where :math:`s_i, s_j \in \{-1, 1\}`.
") get_moment;

/* random sampling */
%pythoncode {
def random_genomes(self, n_sample):
    '''Get random genomes according sampled from the population. 
    
    Parameters:
        - n_sample: number of random genomes to sample
    
    Returns:
        - integers corresponding to random genomes in the population.
    '''
    import numpy as np
    counts = np.random.multinomial(n_sample, self.get_genotype_frequencies())
    ind = counts.nonzero()[0]
    counts = counts[ind]
    sample = np.concatenate([np.repeat(ind[i], counts[i]) for i in xrange(len(ind))])
    np.random.shuffle(sample)
    return sample
}

/* get fitnesses of all individuals */
void _get_fitnesses(int DIM1, double* ARGOUT_ARRAY1) {
        for(size_t i=0; i < (size_t)DIM1; i++)
                ARGOUT_ARRAY1[i] = $self->get_fitness(i);
}
%pythoncode {
def get_fitnesses(self):
    '''Get the fitness of all possible genotypes.'''
    return self._get_fitnesses(1<<self.L)
}

%feature("autodoc",
"Get fitness values of a genotype

Parameters:
    - gt: genotype whose fitness is to be calculated. This can either be an integer or in binary format, e.g. 5 = 0b101 

Returns:
    - the fitness of that genotype.
") get_fitness;

/* divergence/diversity/fitness distributions and plot (full Python implementations) */
%pythoncode {
def get_fitness_histogram(self, n_sample=1000, **kwargs):
    '''Get the histogram of the fitness of a sample from the population.

    Parameters:
        - n_sample: number of individual to sample at random from the population. defaults to 1000

    Returns:
       - h: numpy.histogram of fitness in the population
    '''
    import numpy as np

    # Random sample
    gt = self.random_genomes(n_sample)

    # Calculate fitness
    fit = np.array([self.get_fitness(gt[i]) for i in xrange(n_sample)])

    return np.histogram(fit, **kwargs)


def plot_fitness_histogram(self, axis=None, n_sample=1000, **kwargs):
    '''Plot the histogram of the fitness of a sample from the population.

    Parameters:
        - axis: use an already existing axis for the plot
        - n_sample: number of individual to sample at random from the population. Defaults to 1000.
        - kwargs: further optional keyword arguments to numpy.histograms
    '''

    import numpy as np
    import matplotlib.pyplot as plt

    # Random sample
    gt = self.random_genomes(n_sample)

    # Calculate fitness
    fit = np.array([self.get_fitness(gt[i]) for i in xrange(n_sample)])

    # Plot
    if axis is None:
        fig = plt.figure()
        axis = fig.add_subplot(111)
        axis.set_title('Fitness histogram')
        axis.set_xlabel('Fitness')
    axis.hist(fit, **kwargs)


def get_divergence_statistics(self, n_sample=1000):
    '''Get the mean and variance of the divergence of a population sample -- same as mean and variance of allele frequencies.

    Parameters:
        - n_sample: number of individuals to sample at random from the population. defaults to 1000.

    Returns:
        - stat: structure with mean and variance of divergence in the population
    '''

    import numpy as np
    L = self.L

    # Random sample
    gt = self.random_genomes(n_sample)

    # Calculate divegence
    div = np.array([binarify(gt[i], L).sum() for i in xrange(n_sample)], int)

    return stat(div.mean(), div.var())


def get_divergence_histogram(self, bins=10, n_sample=1000, **kwargs):
    '''Get the histogram of the divergence of a population sample.

    Parameters:
        - bins: number of bins or list of bin edges (passed verbatim to numpy.histogram)
        - n_sample: number of individual to sample at random from the population, defaults to 1000.
        - kwargs: further optional keyword arguments to numpy.histograms

    Returns:
       - h: numpy.histogram of divergence in the population

    *Note*: to get a normalized histogram, use the *density* keyword.
    '''

    import numpy as np
    L = self.L

    # Random sample
    gt = self.random_genomes(n_sample)

    # Calculate divergence
    div = np.array([binarify(gt[i], L).sum() for i in xrange(n_sample)], int)

    return np.histogram(div, bins=bins, **kwargs)


def plot_divergence_histogram(self, axis=None, n_sample=1000, **kwargs):
    '''Plot the histogram of the divergence of a population sample.

    Parameters:
        - axis: use an already existing axis for the plot
        - n_sample: number of individual to sample at random from the population, defaults to 1000.
        - kwargs: further optional keyword arguments to numpy.histograms
    '''
    import numpy as np
    import matplotlib.pyplot as plt
    L = self.L

    # Random sample
    gt = self.random_genomes(n_sample)

    # Calculate divegence
    div = np.array([binarify(gt[i], L).sum() for i in xrange(n_sample)], int)

    # Plot
    if axis is None:
        fig = plt.figure()
        axis = fig.add_subplot(111)
        axis.set_title('Divergence histogram')
        axis.set_xlabel('Divergence')
    
    if 'bins' not in kwargs:
        kwargs['bins'] = np.arange(10) * max(1, (div.max() + 1 - div.min()) / 10) + div.min()
    axis.hist(div, **kwargs)


def get_diversity_statistics(self, n_sample=1000):
    '''Get the mean and variance of the diversity of a population sample

    Parameters:
        - n_sample: number of individual to sample at random from the population, defaults to 1000.

    Returns:
        - stat: structure with mean and variance of diversity in the population
    '''

    import numpy as np
    L = self.L

    # Random sample
    gt1 = self.random_genomes(n_sample)
    gt2 = self.random_genomes(n_sample)

    # Calculate diversity
    div = np.array([binarify(gt1[i] ^ gt2[i], L).sum() for i in xrange(n_sample)], int)

    return stat(div.mean(), div.var())


def get_diversity_histogram(self, bins=10, n_sample=1000, **kwargs):
    '''Get the histogram of the diversity in a sample from the population.

    Parameters:
        - bins: number of bins or list of bin edges (passed verbatim to numpy.histogram)
        - n_sample: number of individual to sample at random from the population, defaults to 1000.
        - kwargs: further optional keyword arguments to numpy.histograms

    Returns:
       - h: numpy.histogram of diversity in the population

    *Note*: to get a normalized histogram, use the *density* keyword.
    '''

    import numpy as np
    L = self.L

    # Random sample
    gt1 = self.random_genomes(n_sample)
    gt2 = self.random_genomes(n_sample)

    # Calculate diversity
    div = np.array([binarify(gt1[i] ^ gt2[i], L).sum() for i in xrange(n_sample)], int)

    # Calculate histogram
    return np.histogram(div, bins=bins, **kwargs)


def plot_diversity_histogram(self, axis=None, n_sample=1000, **kwargs):
    '''Plot the histogram of the diversity of a population sample.

    Parameters:
        - axis: use an already existing axis for the plot
        - n_sample: number of individual to sample at random from the population, defaults to 1000.
        - kwargs: further optional keyword arguments to numpy.histograms
    '''
    import numpy as np
    import matplotlib.pyplot as plt
    L = self.L

    # Random sample
    gt1 = self.random_genomes(n_sample)
    gt2 = self.random_genomes(n_sample)

    # Calculate diversity
    div = np.array([binarify(gt1[i] ^ gt2[i], L).sum() for i in xrange(n_sample)], int)

    # Plot
    if axis is None:
        fig = plt.figure()
        axis = fig.add_subplot(111)
        axis.set_title('Diversity histogram')
        axis.set_xlabel('Diversity')
    
    if 'bins' not in kwargs:
        kwargs['bins'] = np.arange(10) * max(1, (div.max() + 1 - div.min()) / 10) + div.min()
    axis.hist(div, **kwargs)
}

/* set fitness landscape */
%apply (int DIM1, double* IN_ARRAY1) {(int len1, double* indices), (int len2, double* vals)};
int _set_fitness_func(int len1, double* indices, int len2, double* vals) {
        vector<index_value_pair_t> iv;
        index_value_pair_t temp;
        for(size_t i = 0; i != (size_t)len1; i++) {
                temp.index = (int)indices[i];
                temp.val = vals[i];
                iv.push_back(temp);
        }
        return ($self->fitness).init_list(iv);
}
%clear (int len1, double* indices);
%clear (int len2, double* vals);
%pythoncode {
def set_fitness_function(self, genotypes, values):
    '''Set the fitness landscape for individual genotypes.

    Parameters:
       - genotypes: genotype to which the fitness values will be assigned. Genotypes are specified as integers,
                    from 00...0 that is 0, up to 11...1 that is 2^L-1.
       - values: fitness values to assign

    .. note:: you can use Python binary notation for the indices, e.g. 0b0110 is 6.
    '''
    import numpy as np
    genotypes = np.asarray(genotypes, float)
    values = np.asarray(values, float)
    if len(genotypes) != len(values):
        raise ValueError('Indices and values must have the same length')
    if self._set_fitness_func(genotypes, values):
        raise RuntimeError('Error in the C++ function.')
}

/* set additive fitness component */
%feature("autodoc",
"Set an additive fitness landscape. Coefficients obey +/- convention.

Parameters:
    - coefficients: array/list of additive fitness coefficients. It must have length L.
") set_fitness_additive;
%exception set_fitness_additive {
    $action
    if (PyErr_Occurred()) SWIG_fail;
}
void set_fitness_additive(int DIM1, double* IN_ARRAY1) {
        if(DIM1 != $self->L())
                PyErr_Format(PyExc_ValueError, "The array had a wrong length.");
        if (($self->fitness).additive(IN_ARRAY1))
                PyErr_Format(PyExc_RuntimeError, "Error in the C++ function.");
}

/* entropy */
%feature("autodoc",
"Get the genotype entropy of the population

.. note:: the genotype entropy is defined as :math:`-\\sum_{i=0}^{2^L} p_i \\log p_i`.
") genotype_entropy;
%feature("autodoc",
"get the allele entropy of the population

.. note:: the allele entropy is defined as :math:`-\\sum_{i=0}^{L} \\left[\\nu_i\log \\nu_i + (1-\\nu_i)\log(1-\\nu_i)\\right]`.
") allele_entropy;

/* ignore tests (they work by now) */
%ignore test_recombinant_distribution();
%ignore test_recombination(double *rec_rates);
%ignore mutation_drift_equilibrium(double** mutrates);
} /* extend haploid_lowd */
