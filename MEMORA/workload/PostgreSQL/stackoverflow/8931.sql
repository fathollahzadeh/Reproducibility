WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostWithBadges AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Score,
        t.ViewCount,
        t.OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopPosts t
    LEFT JOIN 
        Badges b ON t.PostId = b.UserId
    GROUP BY 
        t.PostId, t.Title, t.Score, t.ViewCount, t.OwnerDisplayName
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    COALESCE(pb.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts p
LEFT JOIN 
    PostWithBadges pb ON p.PostId = pb.PostId
ORDER BY 
    p.Score DESC, p.ViewCount DESC;