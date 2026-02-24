
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.PostTypeId
),
TypeCount AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        SUM(ps.BadgeCount) AS TotalBadges
    FROM PostStats ps
    JOIN PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY pt.Name
)

SELECT 
    tc.PostType,
    tc.TotalPosts,
    tc.TotalComments,
    tc.TotalUpVotes,
    tc.TotalDownVotes,
    tc.TotalBadges
FROM TypeCount tc
ORDER BY tc.TotalPosts DESC;
