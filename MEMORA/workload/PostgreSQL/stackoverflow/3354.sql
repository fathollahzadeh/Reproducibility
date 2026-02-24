
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking
    FROM 
        Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        ur.UserId,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        AVG(ps.NetVotes) AS AverageNetVotes,
        MAX(ps.NetVotes) AS HighestNetVotes
    FROM 
        UserReputation ur
    JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
    GROUP BY 
        ur.UserId
)
SELECT 
    ua.UserId,
    ua.TotalPosts,
    ua.TotalComments,
    ua.AverageNetVotes,
    ua.HighestNetVotes,
    ur.Ranking
FROM 
    UserActivity ua
JOIN 
    UserReputation ur ON ua.UserId = ur.UserId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ur.Ranking ASC,
    ua.TotalComments DESC
FETCH FIRST 10 ROWS ONLY;
