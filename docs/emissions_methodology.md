# Scope 3 emission calculation procedure
The Scope 3 upstream emissions were estimated based on Equation (1).

**Equation (1)**

$$Emissions^{S3}_t =
\sum_{i=1}^{N}
\sum_{c=1}^{C}
IM^{i,c}_{value,t} \, EF^{i,c}_t$$

where $Emissions_t^{S3}$ are import-related Scope 3 emissions (Mt CO2e) at the year t, C is the number of included imported product categories, $IM^{i,c}_{value,t}$ is the import value in EURm  of product $c$ from country $i$,
$EF^{i,c}_t$ is the emission factor (Mt CO2e  / EURm) associated with product category i from country c at the year t. Given the wide scope of imports, emission factors per weight or volume unit are not available.
Therefore, EXIOBASE emission factors per monetary unit had to be used. At the time this paper was written, EXIOBASE emission factors for year 2023 were not available. Therefore, the authors used the inflation-adjusted
2022 emission factor.

GHG emissions in EXIOBASE are expressed as CO₂ equivalents using 100-year global warming potentials (GWP100) based on the Intergovernmental Panel on Climate Change (IPCC) (2007).
The indicator includes major greenhouse gases such as CO₂, CH₄, N₂O, and, where relevant, fluorinated gases, following the Centre of Environmental Science – Leiden University (CML) (2001) life cycle impact assessment methodology.

**Table 1. Data sources for Scope 3 emissions calculation**
| Variable | Data source |
|-----------|-----------|
| Import values | World Integrated Trade Solution (WITS) database |
| Emission factors associated with imports | EXIOBASE 3 |

 
*Source: Own construction.*

EXIOBASE is a Multi-Regional Input-Output (MRIO) database. The emissions in EXIOBASE are estimated by linking sectoral activity data with emission factors compiled within the TEAM modelling framework.
The emission factors are assembled from several established sources, including international guidelines for greenhouse gas and air pollutant inventories and integrated assessment models. (Stadler et al. 2018).
The emission factors in MRIO databases, such as EXIOBASE, are commonly calculated using Equation (2).

**Equation (2)**

$$EF^{i,c}_t = Emissions^{i,c}_t/Output^{i,c}_t,	(C.2)$$

where $Emissions^{i,c}_t$ are value chain emissions associated with product $c$ from country $i$ and $Output^{i,c}_t$ is an output of goods $c$ from country $i$ in a monetary value. 

Certain adjustments were needed to accurately calculate Scope 3 emissions. First, the authors identified extreme outliers in the time series of emission factors that would materially distort calculated emissions
if left untreated. For example, in certain cases, the emission factor increased manifold year-on-year without any apparent economic rationale, leading the authors to believe that such a numerical increase does not
likely reflect a real technological change.

Extreme emission factors observed in MRIO databases may arise from several well-documented sources of uncertainty (see, for example, Lenzen (2010), Wilting (2012),
Schulte (2024)). First, emission inventories must be mapped onto MRIO sector classifications using correspondence tables and proxy data, which can lead to misallocation of emissions across sectors. Second,
MRIO tables integrate heterogeneous economic and environmental datasets and rely on balancing and estimation procedures, which introduce inconsistencies in technical coefficients, sectoral outputs, and emission factors.
These effects are most pronounced at the sectoral level, where MRIO estimates consistently show much higher uncertainty.

To account for implausibly high or low emissions factors, the authors employed an outlier-detection and imputation procedure. Outliers were detected in both emission factors and outputs, since underestimated outputs
can lead to inflated emission factors, and vice versa (see Eq. (C.2)). The first step in outlier detection was determining whether an emission factor or an output series is normally distributed using the 
Jarque-Bera test. From normally distributed time series, those that satisfied the condition in Equation (3) were flagged as outliers.

**Equation (3)**

$$|zscore(EF^{i,c}_t)| > 3$$

where $zscore(EF^{i,c}_t)$ is a z-score of the emission factor associated with product category $i$ from country $c$. For emission factors and outputs that are not normally distributed,
outliers were identified using Equation (4), as described by Tukey (1977).

**Equation (4)**

$$EF^{i,c}_t < Q1(EF^{i,c})-α1.5IQR(EF^{i,c})$$
or
$$EF^{i,c}_t > Q3(EF^{i,c})+α1.5IQR(EF^{i,c})$$

where $Q1(EF^{i,c})$ and $Q3(EF^{i,c})$ are the 1st and 3rd quartiles of the emission factor associated with product category i from country c, α is a constant symbolising a numerator of a standard threshold in
such outlier detection metric 1.5, and $IQR(EF^{i,c})$ is the inter-quartile range of the emission factor associated with goods category $i$ from country $c$. $α$ levels 1, 2, and 4 were tested.
All $α$ levels led to estimated Scope 3 emissions that were not materially different. Consequently, the authors chose the value 4 to flag only extreme outliers.
A lower $α$ could lead to over-imputation in the following step.

Outliers were imputed by replacing high values with the 95th percentile and low values with the 5th percentile calculated from the distribution of non-outlying observations within the respective series.
However, not all detected outliers were automatically imputed. In the emission factor series containing a single outlier, the value was always imputed. In series with two to six outliers, all outliers were
imputed only if the corresponding output values were also flagged as outliers (i.e., when an implausibly high emission factor coincided with an implausibly low output value, or vice versa).
Otherwise, only isolated outliers were imputed. In series with more than six outliers, the imputation was limited to isolated outliers.

The second issue was negative emission factors, even though there was no indication that those specific sectors were involved in carbon reduction or capture. If these negative emission factors remained
after the outlier treatment, they were replaced by a mean of non-negative values within the given goods category and country.

The import statistics use the HS6 classification, while EXIOBASE uses its own classification. Therefore, the HS6 categories had to be mapped to the EXIOBASE categories. The same issue applies to countries:
while import statistics include all origin countries, EXIOBASE does not contain all countries; therefore, certain countries had to be classified as Rest of the world – Europe, etc.

The product mapping was performed using a combination of converting the HS6 classification to ISIC, which is quite close but not entirely consistent with EXIOBASE, and manual mapping.
Due to the time-consuming nature of the semi-manual mapping, only the 60 highest-emission intensive sectors and the 200 sectors with the highest imports were included. This ensures coverage of 64-78% of
total imports, depending on the year. Focusing on the sectors with the largest expected impact on emissions is consistent with the GHG Protocol (2011, p. 60), which states that, with regard to Scope 3,
“achieving  100 percent completeness may not be feasible” and that “companies may find that based on initial estimates,  some Scope 3 activities are expected to be insignificant  in size
(compared to the company’s other sources of  emissions) and that for these activities, the ability to  collect data and influence GHG reductions is limited.”

Accordingly, the estimated upstream Scope 3 series should be interpreted as covering the economically and environmentally material share of non-energy imports rather than as an exhaustive inventory of
every imported product category.
The third issue concerned zero emission factors for product categories with non-zero imports into the Czech Republic. This situation may arise for two main reasons. First, an imperfect correspondence between HS6 trade categories and the sectoral classification used in EXIOBASE. Second, it may reflect how re-exports are treated in MRIO databases. In EXIOBASE, emission factors are set to zero for goods with zero domestic production in a given country. However, situations arise in which a country does not produce a particular good domestically but imports it and subsequently re-exports it to the Czech Republic. In such cases, assigning a zero emission factor would imply that the imported goods are associated with no emissions, even though they were produced elsewhere. To avoid underestimating embodied emissions, these zero emission factors were replaced with the cross-country average for the corresponding product and year. Table 9 summarises the number of adjusted emission factors.

**Table 2. Emission factor adjustment statistics**
 
| Statistic | Number of series | Percentage out of the total number of series |
|-----------|----------------:|---------------------------------------------:|
| Total used EXIOBASE emission factors | 3,330 | 100.00% |
| Emission factors with outliers | 506 | 15.20% |
| Of which: 1 outlier | 267 | 8.02% |
| Of which: 2-6 outliers | 239 | 7.18% |
| Of which: >6 outliers | 0 | 0.00% |
| Negative emission factors | 5 | 0.15% |
| Zero emission factors associated with products with non-zero import | 325 | 9.76% |
| Total adjusted emission factors | 682 | 20.48% |

 
*Source: Own construction.*

 ## References
GHG PROTOCOL, 2011. Corporate Value Chain (Scope 3) Accounting and Reporting Standard [online]. report. Washington, DC: WRI and WBCSD. Retrieved from: https://ghgprotocol.org/corporate-value-chain-scope-3-standard

GORRÉE, Marieke, HEIJUNGS, Reinout, HUPPES, Gjalt, KLEIJN, René, DE KONING, Arjan, VAN OERS, Lauran, WEGENER SLEESWIHK, Anneke, SUH, Sangwon and UDO DE HAES, Helias A., 2001. Life Cycle Assessment. An Operational Guide to the ISO Standards. [online]. Leiden: Centre of Environmental Science – Leiden University. Retrieved from: https://www.universiteitleiden.nl/binaries/content/assets/science/cml/publicaties_pdf/new-dutch-lca-guide/part1.pdf

INTERGOVERNMENTAL PANEL ON CLIMATE CHANGE (IPCC), 2007. Climate change 2007: the physical science basis: contribution of Working Group I to the Fourth Assessment Report of the Intergovernmental Panel on Climate Change [online]. Cambridge ; New York: Cambridge University Press. ISBN 978-0-521-88009-1. Retrieved from: https://www.ipcc.ch/report/ar4/wg1/

LENZEN, Manfred, WOOD, Richard and WIEDMANN, Thomas, 2010. Uncertainty Analysis for Multi-Region Input–Output Models – a Case Study of the UK’s Carbon Footprint. Economic Systems Research. Vol. 22, no. 1, pp. 43–63. https://doi.org/10.1080/09535311003661226. 

SCHULTE, Simon, JAKOBS, Arthur and PAULIUK, Stefan, 2024. Estimating the uncertainty of the greenhouse gas emission accounts in global multi-regional input–output analysis. Earth System Science Data. Vol. 16, no. 6, pp. 2669–2700. https://doi.org/10.5194/essd-16-2669-2024.

STADLER, Konstantin, WOOD, Richard, BULAVSKAYA, Tatyana, SÖDERSTEN, Carl‐Johan, SIMAS, Moana, SCHMIDT, Sarah, USUBIAGA, Arkaitz, ACOSTA‐FERNÁNDEZ, José, KUENEN, Jeroen, BRUCKNER, Martin, GILJUM, Stefan, LUTTER, Stephan, MERCIAI, Stefano, SCHMIDT, Jannick H., THEURL, Michaela C., PLUTZAR, Christoph, KASTNER, Thomas, EISENMENGER, Nina, ERB, Karl‐Heinz, DE KONING, Arjan and TUKKER, Arnold, 2018. EXIOBASE 3: Developing a Time Series of Detailed Environmentally Extended Multi‐Regional Input‐Output Tables. Journal of Industrial Ecology. Vol. 22, no. 3, pp. 502–515. https://doi.org/10.1111/jiec.12715.

TUKEY, John W., 1977. Exploratory data analysis [online]. Reading, Mass. : Addison-Wesley Pub. Co. ISBN 978-0-201-07616-5. Retrieved from: http://archive.org/details/exploratorydataa0000tuke_7616 [accessed 30 March 2026]. 

WILTING, Harry C., 2012. Sensitivity and Uncertainty Analysis in MRIO Modelling; Some Empirical Results with Regard to the Dutch Carbon Footprint. Economic Systems Research. Vol. 24, no. 2, pp. 141–171. https://doi.org/10.1080/09535314.2011.628302.

