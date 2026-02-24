
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        STRING_AGG(t.TagName, ', ') OVER (PARTITION BY p.Id) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 AND 
        p.LastActivityDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 0
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.GoldBadge, 0) AS GoldBadge,
    COALESCE(b.SilverBadge, 0) AS SilverBadge,
    COALESCE(b.BronzeBadge, 0) AS BronzeBadge,
    COALESCE(t.TotalScore, 0) AS TotalScore,
    COUNT(r.PostId) AS TotalPosts,
    SUM(r.UpVotes) AS TotalUpVotes,
    SUM(r.DownVotes) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    TopUsers t ON u.Id = t.OwnerUserId
LEFT JOIN 
    RankedPosts r ON r.OwnerUserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.Location, b.BadgeCount, b.GoldBadge, b.SilverBadge, b.BronzeBadge, t.TotalScore
ORDER BY 
    TotalScore DESC, u.Reputation DESC
LIMIT 10;
