
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Body, p.Tags, p.OwnerUserId
), 
TopCommentedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Body,
        Tags,
        CommentCount,
        RANK() OVER (ORDER BY CommentCount DESC, Score DESC) AS CommentRank
    FROM 
        RankedPosts
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Body,
    tp.Tags,
    tp.CommentCount,
    tp.CommentRank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    b.Name AS BadgeName,
    pht.Name AS PostHistoryTypeName
FROM 
    TopCommentedPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Class = 1 
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    tp.CommentRank <= 10
ORDER BY 
    tp.CommentRank, tp.Score DESC;
