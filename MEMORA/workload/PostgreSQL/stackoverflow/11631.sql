
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.LastAccessDate
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.CreationDate,
    us.LastAccessDate,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    ps.TotalScore,
    ps.TotalViews,
    ps.TotalComments
FROM UserStats us
LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.Reputation DESC, us.UserId;
