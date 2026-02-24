
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
MostCommentedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        Rank
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 0
)
SELECT 
    mcp.PostId,
    mcp.Title,
    mcp.Score,
    mcp.CreationDate,
    mcp.ViewCount,
    mcp.OwnerDisplayName,
    mcp.CommentCount,
    COUNT(DISTINCT pht.UserId) AS EditCount,
    STRING_AGG(DISTINCT pht.Comment, '; ') AS EditComments
FROM 
    MostCommentedPosts mcp
LEFT JOIN 
    PostHistory pht ON mcp.PostId = pht.PostId AND pht.PostHistoryTypeId IN (4, 5, 6, 24) 
GROUP BY 
    mcp.PostId, mcp.Title, mcp.Score, mcp.CreationDate, mcp.ViewCount, mcp.OwnerDisplayName, mcp.CommentCount, mcp.Rank
ORDER BY 
    mcp.Rank;
