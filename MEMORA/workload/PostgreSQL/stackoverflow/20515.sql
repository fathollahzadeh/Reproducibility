
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS rank,
        p.OwnerUserId
    FROM
        Posts p
    WHERE
        p.Score > 0
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostHistoryAggregates AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
UserActivity AS (
    SELECT
        u.Id,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ub.BadgeCount,
    ub.BadgeNames,
    pha.ClosedDate,
    pha.ReopenedDate,
    pha.DeleteCount,
    ua.UpVotesReceived,
    ua.DownVotesReceived,
    CASE
        WHEN rp.ViewCount > 100 THEN 'Highly Viewed'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory
FROM
    RankedPosts rp
LEFT JOIN
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN
    PostHistoryAggregates pha ON pha.PostId = rp.PostId
LEFT JOIN
    UserActivity ua ON ua.Id = rp.OwnerUserId
WHERE
    rp.rank <= 5
ORDER BY
    rp.ViewCount DESC, rp.Score DESC
FETCH FIRST 1000 ROWS ONLY;
