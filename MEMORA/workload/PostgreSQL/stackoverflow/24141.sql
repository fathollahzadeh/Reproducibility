WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)), 0) AS TotalBounty
    FROM 
        Posts p
    WHERE 
        p.Score > 0
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.TotalBounty) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostCount,
        TotalViews,
        TotalComments,
        TotalBountyEarned,
        RANK() OVER (ORDER BY TotalBountyEarned DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.PostCount,
    u.TotalViews,
    u.TotalComments,
    u.TotalBountyEarned
FROM 
    TopUsers u
WHERE 
    (u.UserRank <= 10 
     OR (u.TotalViews IS NULL AND u.PostCount < 5))
ORDER BY 
    u.UserRank, u.TotalBountyEarned DESC;