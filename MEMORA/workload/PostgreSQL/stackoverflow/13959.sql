WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation
    FROM 
        Users
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        p.PostCount,
        p.Questions,
        p.Answers,
        r.Reputation
    FROM 
        UserPostCounts p
    JOIN 
        UserReputation r ON p.OwnerUserId = r.UserId
    JOIN 
        Users u ON u.Id = p.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    Views,
    PostCount,
    Questions,
    Answers
FROM 
    UserActivity
ORDER BY 
    Reputation DESC, 
    PostCount DESC;