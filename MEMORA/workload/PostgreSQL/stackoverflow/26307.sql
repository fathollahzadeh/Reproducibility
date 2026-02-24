
WITH RecentQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        UNNEST(REGEXP_SPLIT_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),

HighReputationUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),

UserContributions AS (
    SELECT 
        u.UserId,
        COUNT(DISTINCT q.PostId) AS QuestionsAsked,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAwarded,
        COALESCE(SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        HighReputationUsers u
    LEFT JOIN 
        RecentQuestions q ON q.OwnerUserId = u.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.UserId AND v.PostId IN (SELECT PostId FROM RecentQuestions)
    GROUP BY 
        u.UserId
)

SELECT 
    u.DisplayName,
    q.PostId,
    q.Title,
    q.CreationDate,
    q.AnswerCount,
    uq.QuestionsAsked,
    uq.TotalBountyAwarded,
    uq.TotalVotes,
    q.Tags
FROM 
    RecentQuestions q
JOIN 
    UserContributions uq ON q.OwnerUserId = uq.UserId
JOIN 
    Users u ON u.Id = q.OwnerUserId
ORDER BY 
    uq.TotalVotes DESC, uq.TotalBountyAwarded DESC, q.CreationDate DESC
LIMIT 50;
