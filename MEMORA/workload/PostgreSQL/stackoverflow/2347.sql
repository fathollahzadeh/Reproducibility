
WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
), 
UserPostInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ur.ReputationRank,
    upi.PostCount,
    upi.TotalScore,
    pp.Title AS PopularPostTitle,
    pp.NetVotes
FROM 
    UserRankings ur
JOIN 
    UserPostInfo upi ON ur.UserId = upi.UserId
LEFT JOIN 
    PopularPosts pp ON upi.UserId = pp.OwnerUserId
WHERE 
    (upi.PostCount > 5 OR ur.Reputation > 100)
    AND pp.NetVotes > 10
ORDER BY 
    ur.Reputation DESC, pp.NetVotes DESC
LIMIT 10;
