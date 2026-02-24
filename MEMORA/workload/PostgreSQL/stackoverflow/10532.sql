WITH QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Score AS QuestionScore,
        p.ViewCount AS QuestionViews,
        u.Reputation AS UserReputation
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
)


SELECT 
    COUNT(*) AS TotalQuestions,
    AVG(QuestionScore) AS AverageScore,
    AVG(QuestionViews) AS AverageViews,
    AVG(UserReputation) AS AverageUserReputation
FROM 
    QuestionStats;