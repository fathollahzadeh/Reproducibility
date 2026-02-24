
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
)
SELECT 
    t.PostId,
    t.Title,
    t.Body,
    t.Tags,
    t.CreationDate,
    t.ViewCount,
    t.OwnerDisplayName,
    t.CommentCount,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount, 
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END), 0) AS DeleteCount, 
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END), 0) AS EditCount  
FROM 
    TopPosts t
LEFT JOIN 
    PostHistory ph ON t.PostId = ph.PostId
GROUP BY 
    t.PostId, t.Title, t.Body, t.Tags, t.CreationDate, t.ViewCount, t.OwnerDisplayName, t.CommentCount
ORDER BY 
    t.ViewCount DESC;
