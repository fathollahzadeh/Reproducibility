
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS RankScore
    FROM 
        RankedPosts
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    COALESCE(ph.CommentsEdited, 0) AS CommentsEdited,
    COALESCE(ph.PostsClosed, 0) AS PostsClosed
FROM 
    TopPosts t
LEFT JOIN (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS CommentsEdited,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS PostsClosed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
) ph ON t.PostId = ph.PostId
WHERE 
    t.RankScore <= 10
ORDER BY 
    t.Score DESC, t.CommentCount DESC;
