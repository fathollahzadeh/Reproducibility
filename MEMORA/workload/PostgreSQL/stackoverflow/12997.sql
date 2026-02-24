
WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
        LEFT JOIN Users u ON u.Id = p.OwnerUserId
    GROUP BY
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        AVG(COALESCE(u.Reputation, 0)) AS AverageReputation
    FROM
        Users u
        LEFT JOIN Posts p ON p.OwnerUserId = u.Id
        LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
)

SELECT 
    ps.OwnerDisplayName,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ua.PostCount AS UserPostCount,
    ua.TotalViews AS UserTotalViews,
    ua.TotalBadges AS UserTotalBadges,
    ua.AverageReputation AS UserAverageReputation
FROM 
    PostStatistics ps
JOIN 
    UserActivity ua ON ps.OwnerDisplayName = ua.DisplayName
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;
