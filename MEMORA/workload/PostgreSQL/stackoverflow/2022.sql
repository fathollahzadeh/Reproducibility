WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.Id IS NOT NULL THEN p.Id END) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopContributors AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.TotalScore,
        us.PostCount,
        us.BadgeCount,
        RANK() OVER (ORDER BY us.TotalScore DESC, us.Reputation DESC) AS UserRank
    FROM 
        UserStatistics us
)
SELECT 
    tc.UserId,
    tc.Reputation,
    tc.TotalScore,
    tc.PostCount,
    tc.BadgeCount,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.PostRank
FROM 
    TopContributors tc
LEFT JOIN 
    RankedPosts rp ON tc.UserId = rp.OwnerUserId
WHERE 
    tc.UserRank <= 10
ORDER BY 
    tc.TotalScore DESC, rp.Score DESC;