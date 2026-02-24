WITH UserPostActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(c.Id) AS TotalComments
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS TotalPostHistories,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalPostClosures,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalPostReopenings
    FROM
        PostHistory ph
    GROUP BY
        ph.UserId
)

SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalViews,
    u.TotalComments,
    pht.TotalPostHistories,
    pht.TotalPostClosures,
    pht.TotalPostReopenings
FROM
    UserPostActivity u
LEFT JOIN
    PostHistorySummary pht ON u.UserId = pht.UserId
ORDER BY
    u.TotalScore DESC, u.TotalPosts DESC;