
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Tags
),
HighScoringPosts AS (
    SELECT 
        rp.*,
        (UpVotes - DownVotes) AS NetScore,
        ROW_NUMBER() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS Rank
    FROM RecentPosts rp
    WHERE (UpVotes - DownVotes) > 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount 
        FROM Badges 
        GROUP BY UserId
    ) b ON p.OwnerUserId = b.UserId
)
SELECT 
    dp.Title,
    dp.CreationDate,
    dp.PostType,
    dp.TotalComments,
    dp.BadgeCount,
    hs.UpVotes,
    hs.DownVotes,
    hs.NetScore
FROM PostDetails dp
JOIN HighScoringPosts hs ON dp.PostId = hs.PostId
WHERE dp.BadgeCount > 0
ORDER BY hs.NetScore DESC
LIMIT 10;
