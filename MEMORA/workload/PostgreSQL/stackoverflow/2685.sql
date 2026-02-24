WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
    HAVING COUNT(DISTINCT c.Id) > 0
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    JOIN UserReputation ur ON b.UserId = ur.Id
    WHERE ur.ReputationRank <= 100
    GROUP BY b.UserId
)
SELECT 
    pp.Title,
    pp.Score,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.CommentCount,
    tb.BadgeCount,
    tb.BadgeNames,
    CASE 
        WHEN pp.UpVoteCount > pp.DownVoteCount THEN 'More Upvotes'
        WHEN pp.UpVoteCount < pp.DownVoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteStatus,
    CASE 
        WHEN tb.BadgeCount IS NOT NULL THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM PopularPosts pp
LEFT JOIN TopBadges tb ON pp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = tb.UserId)
ORDER BY pp.Score DESC, pp.CommentCount DESC;