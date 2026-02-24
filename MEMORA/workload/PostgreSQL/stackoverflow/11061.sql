
WITH PostAggregates AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(b.Id) AS BadgeCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        p.Id, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount
),
UserPerformance AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(pa.Score) AS TotalScore,
        SUM(pa.ViewCount) AS TotalViews,
        SUM(pa.CommentCount) AS TotalComments,
        SUM(pa.UpVoteCount) AS TotalUpVotes,
        SUM(pa.DownVoteCount) AS TotalDownVotes,
        SUM(pa.BadgeCount) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        PostAggregates pa ON u.Id = pa.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    UserId,
    DisplayName,
    TotalScore,
    TotalViews,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalBadges
FROM
    UserPerformance
ORDER BY
    TotalScore DESC, TotalViews DESC;
