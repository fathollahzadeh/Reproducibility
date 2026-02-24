
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(rb.TopPostCount, 0) AS TopPostCount
    FROM 
        Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN (
        SELECT 
            rp.OwnerUserId,
            COUNT(*) AS TopPostCount
        FROM 
            RankedPosts rp
        WHERE 
            rp.PostRank = 1
        GROUP BY 
            rp.OwnerUserId
    ) rb ON u.Id = rb.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    COALESCE(SUM(pv.UpVotes) - SUM(pv.DownVotes), 0) AS NetVotes,
    COUNT(rp.PostId) AS TotalPosts,
    MAX(rp.ViewCount) AS MostViewedPost
FROM 
    UserStatistics us
LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    us.BadgeCount > 0
GROUP BY 
    us.UserId, us.DisplayName, us.BadgeCount
HAVING 
    COUNT(rp.PostId) > 5
ORDER BY 
    MostViewedPost DESC
LIMIT 10;
