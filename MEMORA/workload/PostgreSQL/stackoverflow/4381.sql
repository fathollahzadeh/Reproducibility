WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM RankedPosts rp
    LEFT JOIN Badges b ON rp.PostId = b.UserId AND b.Class = 1
    WHERE rp.Rank <= 3
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        CASE 
            WHEN fp.UpVotes - fp.DownVotes > 0 THEN 'Positive'
            WHEN fp.UpVotes - fp.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral' 
        END AS Sentiment,
        fp.UserBadge
    FROM FilteredPosts fp
)
SELECT 
    fr.*,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fr.PostId AND v.VoteTypeId = 6) AS CloseVoteCount,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) FROM PostLinks pl WHERE pl.PostId = fr.PostId) AS RelatedPostCount
FROM FinalResults fr
ORDER BY fr.CreationDate DESC;
