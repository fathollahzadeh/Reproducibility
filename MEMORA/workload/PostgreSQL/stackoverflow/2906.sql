WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Rank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.Rank <= 5 AND rp.Score > 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No badges') AS BadgeNames,
    CASE 
        WHEN fp.CommentCount = 0 THEN 'No comments'
        WHEN fp.CommentCount <= 5 THEN 'Few comments'
        ELSE 'Many comments'
    END AS CommentDifficulty,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive feedback'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative feedback'
        ELSE 'Neutral feedback'
    END AS VoteSentiment
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
ORDER BY fp.Score DESC, fp.CreationDate DESC
LIMIT 50;
