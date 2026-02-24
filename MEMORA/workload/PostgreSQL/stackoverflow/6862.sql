
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostType,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON rp.AcceptedAnswerId = b.UserId
    LEFT JOIN 
        Users u ON rp.AcceptedAnswerId = u.Id
)
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Score, 
    ViewCount, 
    CommentCount, 
    VoteCount, 
    Rank, 
    PostType, 
    OwnerDisplayName, 
    BadgeCount
FROM 
    TopPosts
WHERE 
    Rank <= 10
ORDER BY 
    PostType, Score DESC;
