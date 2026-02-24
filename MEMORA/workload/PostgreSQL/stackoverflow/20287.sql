WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rnk
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(coalesce(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.CreationDate,
        vt.Name AS VoteType,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS rnk
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rv.VoteType
FROM 
    Users u
LEFT JOIN 
    TopUsers up ON u.Id = up.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rnk = 1
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId AND rv.rnk = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    up.TotalViews DESC NULLS LAST, 
    u.DisplayName;