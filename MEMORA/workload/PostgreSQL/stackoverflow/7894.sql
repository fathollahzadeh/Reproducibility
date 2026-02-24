WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT CASE WHEN p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN p.Id END) AS RecentPostsCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
EffectiveUserActivity AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        Upvotes,
        Downvotes,
        RecentPostsCount,
        MaxReputation,
        (QuestionCount + AnswerCount) AS TotalPosts,
        (Upvotes - Downvotes) AS NetVotes
    FROM 
        UserActivity
)
SELECT 
    eua.DisplayName,
    eua.TotalPosts,
    eua.NetVotes,
    eua.MaxReputation,
    CASE 
        WHEN eua.MaxReputation > 2000 THEN 'Expert'
        WHEN eua.MaxReputation BETWEEN 1000 AND 2000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    EffectiveUserActivity eua
WHERE 
    eua.RecentPostsCount > 0
ORDER BY 
    eua.MaxReputation DESC, 
    eua.TotalPosts DESC
LIMIT 10;