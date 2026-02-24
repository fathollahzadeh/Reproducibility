
WITH UserReputation AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS ReputationChange
    FROM 
        Votes
    GROUP BY 
        UserId
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ur.Upvotes,
        ur.Downvotes,
        ur.ReputationChange,
        COUNT(DISTINCT pd.PostId) AS TotalPosts,
        SUM(pd.Score) AS TotalScore,
        COALESCE(SUM(pd.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(pd.ClosedCount), 0) AS TotalClosed,
        COALESCE(SUM(pd.ReopenedCount), 0) AS TotalReopened
    FROM 
        Users u
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN 
        PostDetails pd ON u.Id = pd.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, ur.Upvotes, ur.Downvotes, ur.ReputationChange
)

SELECT 
    us.UserId, 
    us.DisplayName, 
    us.Reputation, 
    us.TotalPosts, 
    us.TotalScore, 
    us.TotalComments, 
    us.TotalClosed, 
    us.TotalReopened
FROM 
    UserStats us
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.TotalScore DESC
LIMIT 10;
