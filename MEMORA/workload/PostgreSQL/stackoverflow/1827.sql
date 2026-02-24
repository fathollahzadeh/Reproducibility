WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Upvotes,
        rp.Downvotes,
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        us.Reputation,
        CASE 
            WHEN rp.Upvotes - rp.Downvotes > 0 THEN 'Positive'
            WHEN rp.Upvotes - rp.Downvotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteStatus
    FROM RankedPosts rp
    JOIN UserStats us ON rp.OwnerUserId = us.UserId
    WHERE rp.rn <= 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Upvotes,
    fp.Downvotes,
    fp.DisplayName,
    fp.BadgeCount,
    fp.Reputation,
    fp.VoteStatus,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = fp.PostId) THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus
FROM FilteredPosts fp
ORDER BY fp.Reputation DESC, fp.Upvotes DESC;