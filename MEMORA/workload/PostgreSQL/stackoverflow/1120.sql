
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    GROUP BY v.PostId
),
PostInteractions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ud.DisplayName,
        ud.Reputation,
        ud.BadgeCount,
        COALESCE(pvs.Upvotes, 0) AS Upvotes,
        COALESCE(pvs.Downvotes, 0) AS Downvotes,
        rp.RankScore
    FROM RankedPosts rp
    JOIN UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.DisplayName,
    p.Reputation,
    p.BadgeCount,
    p.Upvotes,
    p.Downvotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId) AS CommentCount,
    CASE 
        WHEN p.RankScore = 1 THEN 'Top Post'
        WHEN p.RankScore < 4 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM PostInteractions p
WHERE p.Reputation > 1000
ORDER BY p.Score DESC, p.ViewCount DESC
LIMIT 100;
