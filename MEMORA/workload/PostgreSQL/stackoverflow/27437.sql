
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId, p.Score, p.ViewCount, p.Tags, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(p.Score) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    p.PostId,
    p.Title,
    p.AcceptedAnswerId,
    p.Score AS PostScore,
    p.ViewCount,
    p.CreationDate,
    p.CommentCount,
    u.AvgPostScore,
    u.TotalViews
FROM 
    UserStats u
JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId
WHERE 
    p.PostRank <= 5 
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC;
