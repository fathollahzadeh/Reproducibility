
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, PostCount, TotalUpVotes, TotalDownVotes, AvgPostScore
    FROM UserEngagement
    WHERE UserRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        pct.PostedBy AS UserId
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    JOIN (
        SELECT OwnerUserId AS PostedBy, Id
        FROM Posts
        WHERE PostTypeId = 1 AND CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    ) pct ON p.OwnerUserId = pct.PostedBy
)
SELECT 
    ue.DisplayName,
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    ue.TotalUpVotes - ue.TotalDownVotes AS NetVotes,
    ue.AvgPostScore
FROM TopUsers ue
JOIN PostDetails pd ON ue.UserId = pd.UserId
ORDER BY NetVotes DESC, pd.ViewCount DESC;
