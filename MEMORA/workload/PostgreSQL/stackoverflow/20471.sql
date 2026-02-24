
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosingActions,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(ps.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(ps.DownVoteCount), 0) AS TotalDownVotes,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        MAX(ps.PostRank) AS HighestPostRank
    FROM 
        Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalComments,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalPosts,
    CASE 
        WHEN u.TotalPosts = 0 THEN NULL 
        ELSE ROUND((CAST(u.TotalUpVotes AS FLOAT) / NULLIF(u.TotalPosts, 0)) * 100, 2) 
    END AS UpVotePercentage,
    CASE 
        WHEN u.Reputation >= 1000 THEN 'Veteran' 
        WHEN u.Reputation >= 100 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS UserLevel,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.UserId = u.UserId AND ph.PostHistoryTypeId IN (10, 11)) 
        THEN 'Has closed posts' 
        ELSE 'No closing action' 
    END AS ClosingActionStatus
FROM 
    UserStats u
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    u.TotalUpVotes DESC, 
    u.TotalComments DESC, 
    u.TotalPosts DESC;
