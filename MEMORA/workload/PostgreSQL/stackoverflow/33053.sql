
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostVoteDetails AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS DeletionVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
    pvd.UpVotes,
    pvd.DownVotes,
    pvd.DeletionVotes,
    CASE
        WHEN rp.ViewCount > 1000 THEN 'Popular'
        WHEN rp.Score > 50 THEN 'Highly Voted'
        ELSE 'Regular'
    END AS PostType,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts p2 WHERE p2.AcceptedAnswerId = rp.PostId) THEN 'Answered'
        ELSE 'Unanswered'
    END AS AnswerStatus
FROM RankedPosts rp
LEFT JOIN Users u ON rp.PostId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostVoteDetails pvd ON rp.PostId = pvd.PostId
WHERE rp.Rank <= 10
ORDER BY rp.Score DESC, rp.CreationDate DESC;
