
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN up.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN down.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Votes up ON u.Id = up.UserId AND up.VoteTypeId = 2
    LEFT JOIN Votes down ON u.Id = down.UserId AND down.VoteTypeId = 3
    GROUP BY u.Id, u.Reputation
),
InterestingPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        ur.Reputation,
        (ur.TotalUpVotes - ur.TotalDownVotes) AS VoteBalance
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.CommentCount > 5 AND ur.Reputation > 100
)
SELECT 
    ip.PostId,
    ip.Title,
    ip.CreationDate,
    ip.CommentCount,
    ip.Reputation,
    ip.VoteBalance,
    CASE 
        WHEN ip.VoteBalance > 0 THEN 'Popular'
        WHEN ip.VoteBalance < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS PopularityStatus
FROM InterestingPosts ip
WHERE ip.VoteBalance IS NOT NULL
ORDER BY ip.VoteBalance DESC, ip.CommentCount DESC
LIMIT 10;
