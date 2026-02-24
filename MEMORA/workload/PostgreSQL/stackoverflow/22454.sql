
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MIN(c.CreationDate) AS FirstCommentDate,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.FirstCommentDate, DATE '1900-01-01') AS FirstCommentDate,
        COALESCE(pc.LastCommentDate, DATE '1900-01-01') AS LastCommentDate,
        u.Reputation AS UserReputation,
        NULLIF(u.Reputation, 0) AS NonZeroReputation 
    FROM 
        Posts p
    LEFT JOIN 
        PostComments pc ON p.Id = pc.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    rp.Title,
    rp.Score,
    rp.PostRank,
    pa.CommentCount,
    pa.FirstCommentDate,
    pa.LastCommentDate,
    COALESCE(ur.Reputation, 0) AS OwnerReputation,
    CASE 
        WHEN pa.NonZeroReputation IS NULL THEN 'No reputation'
        WHEN pa.UserReputation > 1000 THEN 'Experienced'
        ELSE 'New User' 
    END AS UserStatus,
    CASE 
        WHEN pa.CommentCount > 0 THEN 'Active Discussion'
        ELSE 'No Comments Yet' 
    END AS CommentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, pa.FirstCommentDate ASC
LIMIT 10;
