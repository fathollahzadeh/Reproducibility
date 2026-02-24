
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), UserPostStats AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotes,
        DownVotes,
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS ReputationRank
    FROM 
        UserReputation
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        BadgeCount, 
        UpVotes, 
        DownVotes, 
        PostCount, 
        TotalScore
    FROM 
        UserPostStats
    WHERE 
        ReputationRank <= 10
), PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.Id AS OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
    ORDER BY 
        p.ViewCount DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.BadgeCount AS TotalBadges,
    tu.UpVotes AS TotalUpVotes,
    tu.DownVotes AS TotalDownVotes,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViews,
    pp.AnswerCount AS PopularPostAnswers,
    pp.Score AS PopularPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    PopularPosts pp ON tu.UserId = pp.OwnerUserId
ORDER BY 
    tu.Reputation DESC;
