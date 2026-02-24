WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
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
PostBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tr.PostId, 
    tr.Title, 
    tr.Score, 
    tr.ViewCount, 
    tr.AnswerCount, 
    tr.OwnerDisplayName, 
    pc.CommentCount, 
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount
FROM 
    TopRankedPosts tr
LEFT JOIN 
    PostComments pc ON tr.PostId = pc.PostId
LEFT JOIN 
    Users u ON tr.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    PostBadges pb ON u.Id = pb.UserId
ORDER BY 
    tr.Score DESC, tr.ViewCount DESC;