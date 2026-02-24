WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.CreationDate, 
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostWithComments AS (
    SELECT 
        tsp.PostId, 
        tsp.Title, 
        tsp.Score, 
        tsp.CreationDate, 
        tsp.OwnerDisplayName, 
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopScoringPosts tsp
    LEFT JOIN 
        PostComments pc ON tsp.PostId = pc.PostId
)
SELECT 
    pwc.PostId, 
    pwc.Title, 
    pwc.Score, 
    pwc.CreationDate, 
    pwc.OwnerDisplayName, 
    pwc.CommentCount
FROM 
    PostWithComments pwc
ORDER BY 
    pwc.Score DESC, pwc.CreationDate DESC;