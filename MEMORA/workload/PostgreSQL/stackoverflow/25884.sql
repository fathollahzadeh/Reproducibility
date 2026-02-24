
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, u.DisplayName
),
LatestPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.Author,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 
),
PostScoreAnalysis AS (
    SELECT 
        lp.PostID,
        lp.Title,
        lp.CommentCount,
        CASE 
            WHEN lp.Score > 10 THEN 'High Score'
            WHEN lp.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        LatestPosts lp
)
SELECT 
    psa.ScoreCategory,
    COUNT(psa.PostID) AS NumberOfPosts,
    STRING_AGG(lp.Tags, ', ') AS AssociatedTags
FROM 
    PostScoreAnalysis psa
JOIN 
    LatestPosts lp ON psa.PostID = lp.PostID
GROUP BY 
    psa.ScoreCategory
ORDER BY 
    NumberOfPosts DESC;
