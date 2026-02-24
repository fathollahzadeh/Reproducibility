
WITH UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
), PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes - DownVotes AS NetScore,
        ROW_NUMBER() OVER (ORDER BY UpVotes - DownVotes DESC) AS Rank
    FROM UserScoreCTE
)
SELECT 
    pu.Rank,
    pu.DisplayName,
    pu.Reputation,
    pu.NetScore,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT p2.Id) AS AnswerCount
FROM PopularUsers pu
LEFT JOIN Badges b ON pu.UserId = b.UserId
LEFT JOIN Posts p ON pu.UserId = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN Posts p2 ON pu.UserId = p2.OwnerUserId AND p2.PostTypeId = 2
WHERE pu.Rank <= 10
GROUP BY pu.Rank, pu.DisplayName, pu.Reputation, pu.NetScore
ORDER BY pu.Rank;
