WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pt.Name
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
CommentStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id
)
SELECT
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.AverageViewCount,
    ps.UniqueAuthors,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.TotalBadgeClass,
    cs.CommentCount
FROM
    PostStats ps
JOIN
    UserStats us ON us.Reputation > 1000
LEFT JOIN
    CommentStats cs ON cs.PostId = (
        SELECT MIN(Id)
        FROM Posts
        WHERE PostTypeId = (
            SELECT Id FROM PostTypes WHERE Name = ps.PostType
        )
        LIMIT 1
    )
ORDER BY
    ps.TotalPosts DESC;