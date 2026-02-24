
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        AVG(u.Reputation) AS AverageReputation
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
PopularTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AcceptedAnswers,
        ts.AverageReputation,
        ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM TagStatistics ts
    WHERE ts.PostCount > 0
),
MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(a.accepted, 0)) AS AcceptedAnswers,
        AVG(COALESCE(a.AvgScore, 0)) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS accepted,
            AVG(Score) AS AvgScore
        FROM Posts
        WHERE AcceptedAnswerId IS NOT NULL
        GROUP BY OwnerUserId
    ) a ON a.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
    ORDER BY TotalPosts DESC
    LIMIT 10
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.AcceptedAnswers,
    pt.AverageReputation,
    au.DisplayName AS ActiveUser,
    au.Reputation AS UserReputation,
    au.TotalPosts,
    au.AcceptedAnswers AS UserAcceptedAnswers,
    au.AvgPostScore
FROM PopularTags pt
CROSS JOIN MostActiveUsers au
WHERE pt.TagRank <= 10
ORDER BY pt.PostCount DESC, au.TotalPosts DESC;
