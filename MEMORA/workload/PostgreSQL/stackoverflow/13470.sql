
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        (COUNT(DISTINCT p.Id) + COUNT(DISTINCT c.Id) + COUNT(DISTINCT v.Id)) AS TotalEngagement
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    UserId,
    DisplayName,
    Reputation, 
    PostCount,
    CommentCount,
    VoteCount,
    TotalEngagement,
    RANK() OVER (ORDER BY TotalEngagement DESC) AS EngagementRank
FROM 
    UserEngagement
ORDER BY 
    TotalEngagement DESC;
