WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RowNum
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.Reputation) AS Reputation
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),

ClosedPosts AS (
    SELECT
        ph.PostId,
        p.Title,
        COUNT(*) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId, p.Title
),

CombinedStats AS (
    SELECT
        p.PostId,
        p.Title,
        p.Score,
        u.UserId,
        u.Reputation,
        u.TotalBounty,
        u.CommentCount,
        COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount
    FROM
        RankedPosts p
    JOIN UserActivity u ON p.PostId = u.UserId
    LEFT JOIN ClosedPosts cp ON p.PostId = cp.PostId
    WHERE 
        p.RowNum <= 10
)

SELECT
    cs.PostId,
    cs.Title,
    cs.Score,
    cs.Reputation,
    cs.TotalBounty,
    cs.CommentCount,
    cs.CloseVoteCount,
    CASE
        WHEN cs.CloseVoteCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE
        WHEN cs.Score IS NULL THEN 'No Score Available'
        ELSE (
            SELECT
                STRING_AGG(CAST(t.TagName AS VARCHAR), ', ')
            FROM
                Posts p
            JOIN Tags t ON t.ExcerptPostId = p.Id
            WHERE
                p.Id = cs.PostId
        )
    END AS AssociatedTags
FROM
    CombinedStats cs
ORDER BY
    cs.Score DESC, cs.Reputation DESC;