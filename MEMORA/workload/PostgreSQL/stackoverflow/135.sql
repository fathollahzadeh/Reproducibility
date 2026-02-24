WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
VoteStatistics AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastEditDate,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.QuestionCount,
    ur.AnswerCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    pd.PostId,
    pd.Title,
    pd.LastEditDate,
    pd.CommentCount,
    ROW_NUMBER() OVER (PARTITION BY ur.UserId ORDER BY pd.LastEditDate DESC) AS RowNum
FROM UserReputation ur
LEFT JOIN VoteStatistics vs ON ur.UserId = vs.UserId
LEFT JOIN PostDetails pd ON ur.UserId = pd.PostId
WHERE ur.Reputation > 1000 
AND (pd.CommentCount > 5 OR pd.CommentCount IS NULL)
ORDER BY ur.Reputation DESC, UpVotes DESC
LIMIT 50;
