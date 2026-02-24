
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS Score,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
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
        Score,
        TotalPosts,
        TotalBadges,
        RANK() OVER (ORDER BY Score DESC, Reputation DESC) AS UserRank
    FROM 
        UserScores
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(AVG(CASE WHEN c.UserId IS NOT NULL THEN c.Score END), 0) AS AverageCommentScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.Score AS UserScore,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.AverageCommentScore,
    ps.TotalComments,
    ra.ChangeCount AS RecentChanges
FROM 
    TopUsers tu
LEFT JOIN 
    PostStatistics ps ON tu.UserId = ps.PostId
LEFT JOIN 
    RecentActivities ra ON ps.PostId = ra.PostId AND tu.UserId = ra.UserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank, ps.ViewCount DESC;
