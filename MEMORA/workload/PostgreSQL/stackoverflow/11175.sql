WITH PerformanceBenchmark AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(v.CreationDate - p.CreationDate) AS AvgTimeToVote
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    TotalViews,
    QuestionCount,
    AnswerCount,
    AvgTimeToVote
FROM 
    PerformanceBenchmark
ORDER BY 
    Reputation DESC, PostCount DESC;
