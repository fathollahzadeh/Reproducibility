
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        PositiveScorePosts,
        NegativeScorePosts,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.PositiveScorePosts,
    u.NegativeScorePosts,
    u.TotalBadges,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS TotalDownVotes
FROM 
    TopUsers u
LEFT JOIN 
    Votes v ON u.UserId = v.UserId
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, u.TotalPosts, u.Questions, u.Answers, u.PositiveScorePosts, u.NegativeScorePosts, u.TotalBadges, u.ReputationRank
ORDER BY 
    u.ReputationRank
LIMIT 10;
