
WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(u.DisplayName, ', ') AS TopUsers
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagStats
)
SELECT 
    tt.TagId,
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.TotalViews,
    tt.AverageScore,
    tt.Rank,
    ph.UserDisplayName AS MostRecentEditor,
    MAX(ph.CreationDate) AS MostRecentEditDate
FROM TopTags tt
LEFT JOIN PostHistory ph ON ph.PostId IN (
    SELECT p.Id FROM Posts p 
    WHERE p.Tags LIKE CONCAT('%', tt.TagName, '%')
) 
GROUP BY tt.TagId, tt.TagName, tt.PostCount, tt.QuestionCount, tt.AnswerCount, tt.TotalViews, tt.AverageScore, ph.UserDisplayName, tt.Rank
HAVING tt.Rank <= 10
ORDER BY tt.Rank;
