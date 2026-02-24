WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(bp.Score), 0) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts bp ON u.Id = bp.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalScore,
        us.BadgeCount,
        DENSE_RANK() OVER (ORDER BY us.Reputation DESC, us.TotalScore DESC) AS UserRank
    FROM UserStats us
    WHERE us.Reputation IS NOT NULL
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.TotalScore,
    tp.BadgeCount,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM TopUsers tp
LEFT JOIN RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE tp.UserRank <= 10
ORDER BY tp.Reputation DESC, rp.Score DESC NULLS LAST;