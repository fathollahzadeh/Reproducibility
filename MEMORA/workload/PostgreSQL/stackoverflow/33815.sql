
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Title,
        p.Tags,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.PositivePosts,
        ua.NegativePosts,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.PostCount > 0
)
SELECT 
    pu.OwnerUserId AS PostOwner,
    pu.PostId,
    pu.Title,
    pu.CreationDate,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.PostCount AS TotalPosts,
    tu.PositivePosts AS UpVotes,
    tu.NegativePosts AS DownVotes
FROM 
    RankedPosts pu
JOIN 
    TopUsers tu ON pu.OwnerUserId = tu.UserId
WHERE 
    pu.rn = 1
    AND pu.Score >= 5
    AND tu.UserRank <= 10
ORDER BY 
    tu.Reputation DESC, pu.CreationDate DESC;
