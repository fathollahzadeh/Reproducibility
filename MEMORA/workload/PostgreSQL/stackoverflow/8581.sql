
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        UpVotesReceived, 
        DownVotesReceived, 
        TotalPosts, 
        TotalComments, 
        ReputationRank
    FROM 
        UserStats
    WHERE 
        ReputationRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
PostMetrics AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        Comments c ON pd.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pd.PostId = v.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.CreationDate, pd.ViewCount, pd.Score, pd.OwnerDisplayName
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation AS Reputation,
    pm.Title AS MostActivePost,
    pm.CommentCount AS TotalCommentsOnPost,
    pm.VoteCount AS TotalVotesOnPost,
    pm.CreationDate AS PostCreationDate,
    pm.ViewCount AS PostViewCount,
    pm.Score AS PostScore
FROM 
    TopUsers tu
JOIN 
    PostMetrics pm ON tu.DisplayName = pm.OwnerDisplayName
ORDER BY 
    tu.Reputation DESC, 
    pm.ViewCount DESC
LIMIT 5;
