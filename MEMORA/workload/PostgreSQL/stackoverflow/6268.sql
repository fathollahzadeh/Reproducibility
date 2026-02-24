WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
TopScoringPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentsCount AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        tsp.PostId,
        tsp.Title,
        tsp.Owner,
        tsp.CreationDate,
        tsp.Score,
        COALESCE(cc.TotalComments, 0) AS CommentCount
    FROM 
        TopScoringPosts tsp
    LEFT JOIN 
        CommentsCount cc ON tsp.PostId = cc.PostId
)
SELECT 
    pd.Title,
    pd.Owner,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    EXTRACT(YEAR FROM pd.CreationDate) AS PostYear
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 10;
