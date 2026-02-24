
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NOT NULL THEN 'Known User' 
            ELSE 'Unknown User' 
        END AS UserType
    FROM 
        Users u
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.CommentCount,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pb.HighestBadgeClass, 0) AS HighestBadgeClass
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostBadges pb ON r.OwnerUserId = pb.UserId
)

SELECT 
    pd.PostId,
    pd.Title,
    ur.Reputation,
    ur.UserType,
    pd.CommentCount,
    pd.BadgeCount,
    pd.HighestBadgeClass,
    CASE 
        WHEN pd.CommentCount > 5 AND ur.Reputation > 100 THEN 'Popular Post by a Reputable User'
        ELSE 'Needs Improvement'
    END AS PostQuality
FROM 
    PostDetails pd
JOIN 
    UserReputation ur ON pd.OwnerUserId = ur.UserId
WHERE 
    pd.PostId IN (
        SELECT PostId
        FROM Posts
        WHERE Tags LIKE '%sql%'
    )
ORDER BY 
    pd.CommentCount DESC, ur.Reputation DESC;
