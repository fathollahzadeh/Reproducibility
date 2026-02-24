WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
LatestEdits AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS EditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.TotalBadges,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    le.EditDate
FROM
    UserStats us
JOIN
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN
    LatestEdits le ON rp.Id = le.PostId
WHERE
    us.Reputation > 100
ORDER BY
    us.TotalPosts DESC, us.Reputation DESC;