WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounties,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalScore,
    RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
FROM 
    UserStats us 
ORDER BY 
    us.Reputation DESC;