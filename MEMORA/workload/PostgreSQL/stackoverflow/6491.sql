WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  
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
    tr.CreationDate,
    tr.Score,
    tr.ViewCount,
    tr.AnswerCount,
    tr.OwnerDisplayName,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pb.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    TopRatedPosts tr
LEFT JOIN 
    PostComments pc ON tr.PostId = pc.PostId
LEFT JOIN 
    PostBadges pb ON tr.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = pb.UserId)
ORDER BY 
    tr.Score DESC, tr.CreationDate ASC;