WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopAnsweredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AnswerCount,
        p.Score,
        (
            SELECT 
                COUNT(c.Id) 
            FROM 
                Comments c 
            WHERE 
                c.PostId = p.Id
        ) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.AnswerCount > 0
    ORDER BY 
        p.AnswerCount DESC
    LIMIT 10
)
SELECT 
    r.Title AS QuestionTitle,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    r.Score AS QuestionScore,
    COALESCE(tap.CommentCount, 0) AS TotalComments,
    tap.AnswerCount AS TotalAnswers,
    us.QuestionCount AS UserQuestionCount,
    us.TotalScore AS UserTotalScore
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    TopAnsweredPosts tap ON tap.Id = r.Id
JOIN 
    UserStats us ON us.UserId = r.OwnerUserId
WHERE 
    r.Rank = 1
ORDER BY 
    r.Score DESC
LIMIT 20;