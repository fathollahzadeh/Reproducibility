
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS Deletions,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
), PopularityMetrics AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        CommentCount,
        Upvotes,
        Downvotes,
        Deletions,
        (Upvotes - Downvotes) AS VoteNet,
        CASE 
            WHEN (Upvotes - Downvotes) > 0 THEN 'Positive'
            WHEN (Upvotes - Downvotes) < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        PostRank
    FROM 
        RankedPosts
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Author,
    pm.CreationDate,
    pm.CommentCount,
    pm.Upvotes,
    pm.Downvotes,
    pm.Deletions,
    pm.VoteNet,
    pm.Sentiment
FROM 
    PopularityMetrics pm
WHERE 
    pm.PostRank <= 5  
ORDER BY 
    pm.CreationDate DESC;
