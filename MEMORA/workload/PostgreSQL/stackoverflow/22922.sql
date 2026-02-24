WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 AND p.Score > 0
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS PostCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS ClosedPostCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenedPostCount
    FROM
        PostHistory ph
    GROUP BY
        ph.UserId
)
SELECT
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.TotalBadges,
    us.TotalViews,
    COALESCE(p.Rank, 0) AS HighestRankPost,
    COALESCE(ph.PostCount, 0) AS TotalPostHistoryCount,
    COALESCE(ph.ClosedPostCount, 0) AS TotalClosedPosts,
    COALESCE(ph.ReopenedPostCount, 0) AS TotalReopenedPosts
FROM
    UserStats us
LEFT JOIN
    RankedPosts p ON us.UserId = p.OwnerUserId AND p.Rank = 1
LEFT JOIN
    PostHistorySummary ph ON us.UserId = ph.UserId
WHERE
    us.QuestionCount > 0
ORDER BY
    us.TotalViews DESC,
    us.QuestionCount DESC,
    us.TotalBadges DESC
LIMIT 100;
