
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikiExcerptCount,
        SUM(CASE WHEN p.PostTypeId = 5 THEN 1 ELSE 0 END) AS TagWikiCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation
    FROM 
        Users
),
AggregatedData AS (
    SELECT 
        u.UserId,
        ur.Reputation,
        u.PostCount,
        u.QuestionCount,
        u.AnswerCount,
        u.WikiCount,
        u.TagWikiExcerptCount,
        u.TagWikiCount,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserPosts u
    JOIN 
        UserReputation ur ON u.UserId = ur.UserId
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount,
    TagWikiExcerptCount,
    TagWikiCount,
    ReputationRank
FROM 
    AggregatedData
ORDER BY 
    ReputationRank
FETCH FIRST 100 ROWS ONLY;
