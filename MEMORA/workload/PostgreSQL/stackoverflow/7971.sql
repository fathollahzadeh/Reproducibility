WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.CreationDate,
    trp.ViewCount,
    trp.OwnerDisplayName,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore
FROM 
    TopRankedPosts trp
LEFT JOIN 
    CommentStatistics cs ON trp.PostId = cs.PostId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;