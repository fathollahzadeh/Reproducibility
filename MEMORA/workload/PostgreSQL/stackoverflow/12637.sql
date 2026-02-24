
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM
            Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE
        u.CreationDate >= '2020-01-01'
    GROUP BY
        u.Id, u.DisplayName
),
PostTypeStats AS (
    SELECT
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        PostTypes pt
    LEFT JOIN
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY
        pt.Id, pt.Name
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalViews,
    u.TotalScore,
    u.TotalComments,
    p.PostTypeId,
    p.PostTypeName,
    p.PostCount AS TypePostCount,
    p.TotalViews AS TypeTotalViews,
    p.TotalScore AS TypeTotalScore
FROM
    UserPostStats u
JOIN
    PostTypeStats p ON u.PostCount > 0
ORDER BY
    u.TotalScore DESC, p.TotalViews DESC;
