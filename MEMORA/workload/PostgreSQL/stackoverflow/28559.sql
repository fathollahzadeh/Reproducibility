
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UserCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.Score,
        t.TagName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE p.ViewCount > 1000
    ORDER BY p.Score DESC
    LIMIT 10
),
PostHistoryAnalysis AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name) AS ChangeTypes
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY p.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AcceptedAnswerCount,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.UserCount AS TagUserCount,
    php.PostId,
    php.Title AS PopularPostTitle,
    php.OwnerName,
    php.Score AS PopularPostScore,
    pha.EditCount AS TotalEdits,
    pha.ChangeTypes
FROM UserPostStats ups
LEFT JOIN TagStats ts ON ts.UserCount > 5
LEFT JOIN PopularPosts php ON php.OwnerName = ups.DisplayName
LEFT JOIN PostHistoryAnalysis pha ON pha.PostId = php.PostId
WHERE ups.TotalPosts > 50
ORDER BY ups.DisplayName DESC, ts.PostCount DESC;
