
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalQuestions,
        COUNT(DISTINCT p.AcceptedAnswerId) AS TotalAcceptedAnswers
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    us.DisplayName, 
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    qt.TotalQuestions,
    qt.TotalAcceptedAnswers,
    pt.TagName
FROM 
    UserStatistics us
LEFT JOIN 
    QuestionStats qt ON us.UserId = qt.OwnerUserId
JOIN
    PopularTags pt ON pt.PostCount > 5 
WHERE 
    us.Reputation >= 1000 
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
