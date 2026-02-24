WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount 
         FROM Votes 
         WHERE VoteTypeId = 2 
         GROUP BY PostId) v ON p.Id = v.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AvgReputation,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    COALESCE(ph.PostHistoryTypeId, 0) AS LastActionType,
    ROW_NUMBER() OVER (PARTITION BY ups.UserId ORDER BY ps.CreationDate DESC) AS PostRank
FROM 
    UserPostStats ups
INNER JOIN 
    PostStats ps ON ups.UserId = ps.OwnerUserId
LEFT JOIN 
    (SELECT 
        PostId, 
        MAX(PostHistoryTypeId) AS PostHistoryTypeId
     FROM 
        PostHistory 
     GROUP BY 
        PostId) ph ON ps.PostId = ph.PostId
WHERE 
    ups.AvgReputation > 100
ORDER BY 
    ups.TotalPosts DESC, ps.CreationDate DESC;
