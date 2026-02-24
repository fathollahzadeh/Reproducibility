
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.Location,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.Location
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostsCount,
        ur.Upvotes,
        ur.Downvotes,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostsCount > 0
),
PostAndHistory AS (
    SELECT 
        pp.Title, 
        pp.CreationDate, 
        pp.Score, 
        ph.CreationDate AS HistoryDate, 
        ph.Comment,
        PHT.Name AS HistoryType,
        pp.OwnerUserId
    FROM 
        RankedPosts pp
    JOIN 
        PostHistory ph ON pp.PostId = ph.PostId
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        pp.Rank = 1
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostsCount,
    tu.Upvotes,
    tu.Downvotes,
    pah.Title,
    pah.CreationDate,
    pah.Score,
    pah.HistoryDate,
    pah.Comment,
    pah.HistoryType
FROM 
    TopUsers tu
JOIN 
    PostAndHistory pah ON tu.UserId = pah.OwnerUserId
ORDER BY 
    tu.UserRank, pah.Score DESC;
