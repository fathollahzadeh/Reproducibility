WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        u.DisplayName,
        upc.UserId,
        upc.PostCount,
        upc.QuestionCount,
        upc.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY upc.PostCount DESC) AS Rank
    FROM 
        UserPostCounts upc
    JOIN 
        Users u ON upc.UserId = u.Id
)

SELECT 
    t.DisplayName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10;