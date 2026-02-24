WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END) AS Favorites,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN v.VoteTypeId = 7 THEN 1 ELSE 0 END) AS ReopenVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseReasons,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS TotalDeleteUndeleteEvents
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.OwnerUserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.UpVotes) AS TotalUpVotes,
    SUM(ps.DownVotes) AS TotalDownVotes,
    SUM(ps.Favorites) AS TotalFavorites,
    SUM(ps.CloseVotes) AS TotalCloseVotes,
    SUM(ps.ReopenVotes) AS TotalReopenVotes,
    SUM(ps.TotalCloseReasons) AS TotalCloseReasons,
    SUM(ps.TotalDeleteUndeleteEvents) AS TotalDeleteUndeleteEvents
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON ps.OwnerUserId = u.Id
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 100;