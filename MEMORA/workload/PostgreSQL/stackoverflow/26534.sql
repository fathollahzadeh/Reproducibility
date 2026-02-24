WITH TagCounts AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeScore,
        u.Reputation,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBadgeScore,
        ur.VoteCount,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.TotalBadgeScore DESC) AS UserRank
    FROM UserReputation ur
    WHERE ur.Reputation > 1000
),
FilteredTags AS (
    SELECT
        tc.TagName,
        tc.PostCount,
        tc.TotalViews,
        tc.TotalScore,
        tc.QuestionCount,
        tc.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY tc.TotalViews DESC) AS TagRank
    FROM TagCounts tc
)
SELECT 
    ft.TagName,
    ft.PostCount,
    ft.TotalViews,
    ft.TotalScore,
    ft.QuestionCount,
    ft.AnswerCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.TotalBadgeScore AS TopUserBadgeScore,
    tu.VoteCount AS TopUserVoteCount
FROM FilteredTags ft
JOIN TopUsers tu ON ft.QuestionCount > 0
WHERE ft.TagRank <= 10 AND tu.UserRank <= 5
ORDER BY ft.TotalViews DESC, tu.Reputation DESC;
