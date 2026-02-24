WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        p.Score, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(c.Id) AS CommentCount, 
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        ur.Reputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        ra.CommentCount,
        ra.LastCommentDate,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS PostScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    WHERE 
        rp.RN = 1
)
SELECT 
    pd.PostId,
    pd.Reputation,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    pd.CommentCount,
    pd.LastCommentDate,
    pd.PostScoreCategory,
    CASE 
        WHEN pd.Reputation IS NULL THEN 'Unregistered User'
        WHEN pd.Reputation < 100 THEN 'Novice'
        WHEN pd.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2), 
        0) AS UpvoteCount,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = pd.PostId AND v.VoteTypeId = 3), 
        0) AS DownvoteCount
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.LastCommentDate DESC, 
    pd.Reputation DESC;