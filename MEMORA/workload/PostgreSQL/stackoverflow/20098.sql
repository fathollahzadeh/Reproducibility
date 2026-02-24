WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM
        Posts p
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1 
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
), ClosingReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
)

SELECT
    up.UserId,
    up.Reputation,
    up.TotalPosts,
    up.PositivePosts,
    up.NegativePosts,
    COALESCE(rp.PostId, 0) AS TopPostId,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.ViewCount, 0) AS TopPostViewCount,
    COALESCE(rp.BadgeName, 'No Badge') AS Badge,
    cr.CloseReasons,
    cr.LastCloseDate
FROM
    UserStats up
LEFT JOIN
    RankedPosts rp ON up.UserId = rp.Rank
LEFT JOIN
    ClosingReasons cr ON rp.PostId = cr.PostId
WHERE
    up.Reputation > 1000
AND
    up.TotalPosts > 5
ORDER BY
    up.Reputation DESC,
    up.PositivePosts DESC;