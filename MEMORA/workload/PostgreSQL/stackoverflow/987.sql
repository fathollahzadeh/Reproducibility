
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount
    FROM Users u
    INNER JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(p.Id) > 10
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostHistoryType
    FROM PostHistory ph
    INNER JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        COALESCE(cps.CreationDate, NULL) AS LastClosedDate,
        u.DisplayName AS ActiveUser
    FROM PostStats ps
    LEFT JOIN ClosedPostStats cps ON ps.PostId = cps.PostId
    LEFT JOIN MostActiveUsers u ON ps.UpVotes > 0 
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CommentCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.LastClosedDate,
    COALESCE(fs.ActiveUser, 'N/A') AS ActiveUserDetails,
    CASE 
        WHEN fs.UpVotes - fs.DownVotes > 0 THEN 'Positive'
        WHEN fs.UpVotes - fs.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM FinalStats fs
WHERE fs.CommentCount > 5 
ORDER BY fs.UpVotes DESC, fs.DownVotes ASC;
