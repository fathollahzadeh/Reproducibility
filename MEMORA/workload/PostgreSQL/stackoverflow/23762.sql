
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) AS SilverBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS ActivityCount,
        MAX(CreationDate) AS LastActivity
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(ua.Reputation, 0) AS UserReputation,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        COALESCE(pa.ActivityCount, 0) AS ActivityCount,
        rp.ViewCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        UserReputation ua ON rp.OwnerUserId = ua.UserId
    LEFT JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UserReputation,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    pd.ActivityCount,
    pd.ViewCount,
    CASE 
        WHEN pd.ViewCount > 100 THEN 'Popular' 
        ELSE 'Less Popular' 
    END AS Popularity,
    CASE 
        WHEN pd.UserReputation > 1000 THEN 'Respected User' 
        ELSE 'New User' 
    END AS UserStatus
FROM 
    PostDetails pd
WHERE 
    (pd.UserReputation >= 500 OR pd.ActivityCount > 5)
    AND pd.CreationDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
ORDER BY 
    pd.ViewCount DESC, pd.ActivityCount DESC;
