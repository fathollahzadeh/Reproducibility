WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AveragePostScore,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryChangeCount
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id
)

SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AveragePostScore,
    u.TotalViews,
    p.PostId,
    p.HistoryChangeCount
FROM
    UserPostStats u
JOIN
    PostHistoryStats p ON p.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = u.UserId
    )
ORDER BY
    u.TotalPosts DESC, u.TotalViews DESC;