WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(pd.Score, 0)) AS TotalScore,
        SUM(COALESCE(pd.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(pd.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(pd.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(pd.DownVotes, 0)) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostDetails pd ON p.Id = pd.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    u.TotalViews,
    u.TotalComments,
    u.TotalUpVotes,
    u.TotalDownVotes,
    COALESCE(v.VoteCount, 0) AS TotalVotes
FROM UserPostStats u
LEFT JOIN UserVotes v ON u.UserId = v.UserId
ORDER BY u.TotalScore DESC, u.PostCount DESC
LIMIT 100;