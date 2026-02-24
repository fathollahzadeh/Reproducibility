
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.UserId IS NOT NULL, FALSE)::INTEGER) AS TotalVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalVotes,
        us.GoldBadges,
        us.SilverBadges,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 5
)
SELECT 
    rus.DisplayName,
    rus.Reputation,
    rus.TotalPosts,
    rus.TotalVotes,
    rus.GoldBadges,
    rus.SilverBadges,
    COALESCE(c.Title, 'No Closed Posts') AS LastClosedPost,
    COALESCE(c.LastClosedDate::TEXT, 'N/A') AS ClosedDate
FROM 
    TopUsers rus
LEFT JOIN 
    ClosedPosts c ON rus.UserId = c.OwnerUserId
WHERE 
    rus.Rank <= 10
ORDER BY 
    rus.Reputation DESC;
