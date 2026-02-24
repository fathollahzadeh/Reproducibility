
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalScore,
        RANK() OVER (ORDER BY ua.TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 5
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.ScoreRank,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    re.Id AS RecommendedUserId,
    re.DisplayName AS RecommendedUserDisplayName
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    Users re ON tu.UserId <> re.Id AND re.Reputation > 1000 AND re.Location IS NOT NULL
WHERE 
    EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId)
ORDER BY 
    tu.ScoreRank, rp.CreationDate DESC
LIMIT 50 OFFSET 0;
