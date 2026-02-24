
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount, u.Id
), AggregatedData AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 3 
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    ad.OwnerDisplayName,
    ad.TotalQuestions,
    ad.TotalScore,
    ad.AvgViewCount,
    ad.TotalComments,
    CASE 
        WHEN ad.TotalQuestions > 10 THEN 'High Contributor'
        WHEN ad.TotalQuestions BETWEEN 5 AND 10 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorCategory
FROM 
    AggregatedData ad
ORDER BY 
    ad.TotalScore DESC, ad.TotalQuestions DESC
LIMIT 50;
