
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM
        Posts p
    WHERE
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    GROUP BY
        u.Id, u.DisplayName
),
RecentPostLinks AS (
    SELECT
        pl.PostId,
        pl.RelatedPostId
    FROM
        PostLinks pl
    WHERE
        pl.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10 
    GROUP BY
        ph.PostId
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalBounty,
    ups.TotalBadges,
    ups.TotalComments,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM
    UserStats ups
JOIN
    RankedPosts rp ON ups.UserId = rp.PostId
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN
    RecentPostLinks pl ON rp.PostId = pl.PostId
WHERE
    ups.TotalBadges > 0 AND
    rp.RankScore <= 5
GROUP BY
    ups.UserId, ups.DisplayName, ups.TotalBounty, ups.TotalBadges,
    ups.TotalComments, rp.Title, rp.CreationDate, rp.Score, 
    rp.ViewCount, rp.AnswerCount, rp.CommentCount, cp.CloseCount
ORDER BY
    rp.Score DESC, ups.TotalBounty DESC;
