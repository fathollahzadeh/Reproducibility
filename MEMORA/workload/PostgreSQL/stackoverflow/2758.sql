
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
), HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.Score,
        pt.Name AS PostTypeName,
        CASE 
            WHEN rp.Score > 10 THEN 'High'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    WHERE 
        rp.rn = 1
), AggregateData AS (
    SELECT 
        hsp.ScoreCategory,
        COUNT(*) AS TotalPosts,
        AVG(hsp.CommentCount) AS AvgComments
    FROM 
        HighScorePosts hsp
    GROUP BY 
        hsp.ScoreCategory
)

SELECT 
    ad.ScoreCategory,
    ad.TotalPosts,
    ad.AvgComments,
    CASE 
        WHEN ad.TotalPosts > 50 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityIndicator
FROM 
    AggregateData ad
ORDER BY 
    ad.TotalPosts DESC;
