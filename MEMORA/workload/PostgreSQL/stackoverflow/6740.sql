
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
),
MostCommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    mcp.PostId,
    mcp.Title,
    mcp.OwnerDisplayName,
    mcp.CreationDate,
    mcp.Score,
    mcp.CommentCount,
    COALESCE(pvc.VoteCount, 0) AS VoteCount
FROM 
    MostCommentedPosts mcp
LEFT JOIN 
    PostVoteCounts pvc ON mcp.PostId = pvc.PostId
ORDER BY 
    mcp.Score DESC, mcp.CommentCount DESC, mcp.CreationDate DESC
LIMIT 10;
