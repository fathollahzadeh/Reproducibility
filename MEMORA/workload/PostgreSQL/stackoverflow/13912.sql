WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBountyAmount,
        MAX(p.CreationDate) AS LastActivityDate,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    LEFT JOIN
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY
        p.Id, p.Title
),

UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Views) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
)

SELECT
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.AvgBountyAmount,
    ps.LastActivityDate,
    ps.HistoryCount,
    us.UserId,
    us.DisplayName,
    us.AvgReputation,
    us.BadgeCount,
    us.TotalViews
FROM
    PostStats ps
JOIN
    Users u ON u.Id = ps.PostId
JOIN
    UserStats us ON us.UserId = u.Id
ORDER BY
    ps.LastActivityDate DESC;