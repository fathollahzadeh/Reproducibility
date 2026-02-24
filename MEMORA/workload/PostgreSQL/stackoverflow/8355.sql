WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
TagsWithCounts AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY
        t.Id, t.TagName
),
PostTypeHistories AS (
    SELECT
        ph.UserId,
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.UserId, ph.PostId
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    twc.TagId,
    twc.TagName,
    twc.PostCount,
    pth.EditCount,
    pth.LastEditDate,
    pth.EditTypes
FROM
    UserPostStats ups
LEFT JOIN
    TagsWithCounts twc ON ups.UserId = twc.TagId
LEFT JOIN
    PostTypeHistories pth ON ups.UserId = pth.UserId
ORDER BY
    ups.TotalScore DESC,
    ups.TotalPosts DESC;
