WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageScore,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 0
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    ROUND(tt.AverageScore, 2) AS AverageScore,
    tt.Rank,
    tu.DisplayName AS TopUser
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tu.UserRank <= 5
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.Rank, tu.Reputation DESC;
