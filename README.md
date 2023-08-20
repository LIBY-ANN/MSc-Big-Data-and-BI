# MSc-Big-Data-and-BI
COMPARISON OF LOGISTIC REGRESSION, SUPPORT VECTOR MACHINE 
AND spaCY algorithms for product matching.

ABSTRACT: Product matching is the process of using Natural Language Processing and 
machine learning techniques to identify identical products that are being sold across different 
websites, even though the product names may not be an exact match. This technique has a 
variety of uses in ecommerce, as it can help to identify the same item being sold in different 
places, even if the names are not quite the same. Product matching plays a vital role in the 
current industry as a key factor in providing a positive customer experience. It allows 
customers to find the products quickly and easily they need, reducing the time spent browsing 
and helping them find the perfect match for their needs. It also enables businesses to better 
market their products by understanding customer preferences, enabling them to tailor their 
offerings to meet the needs of their target audience. It helps businesses improve their 
efficiency by helping them focus on the products that are most likely to be successful.
In this paper, product match is tested using various machine learning algorithms to detect 
patterns and correlations between products to recommend products that customers may be 
interested in. The dataset used has Computer and Accessories products with their brands, 
titles, descriptions, specifications etc on both the left- and right-hand side which are subjected 
to comparison to predict the match. The dataset has a huge number of null values and invalid 
entries and hence choosing any random attribute to make the prediction does not provide an 
accurate result. Thus, product titles from the left- and right-hand side are considered, and
similarity measures such as levenshtein distance, hamming distance, jaro similarity and others 
are used to determine the degree of similarity or dissimilarity between them. The paper 
focuses on study of different algorithms and even though logistic regression was primarily 
focused and was considered to be suitable for product matching, on further investigation and 
study, Random Forest algorithm is found to be more precise in making the prediction and 
showed the best accuracy of 92.8% .
