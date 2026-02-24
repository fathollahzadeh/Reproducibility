WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

FilteredPosts AS (
    SELECT
        r.*,
        CASE 
            WHEN r.RankScore <= 5 THEN 'Top'
            WHEN r.RankScore <= 10 THEN 'Moderate'
            ELSE 'Low'
        END AS ScoreCategory,
        (CASE 
            WHEN r.CommentCount = 0 THEN 'No Comments'
            WHEN r.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
            ELSE 'Many Comments'
        END) AS CommentCategory
    FROM
        RankedPosts r
    WHERE
        r.ViewCount > 50
)

SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.ScoreCategory,
    fp.CommentCategory,
    CONCAT('Votes: ', COALESCE(fp.UpVoteCount, 0), ' up, ', COALESCE(fp.DownVoteCount, 0), ' down') AS VoteSummary,
    (SELECT STRING_AGG(tag.TagName, ', ')
     FROM Tags tag
     WHERE tag.WikiPostId = fp.PostId) AS TagsList,
    CASE
        WHEN EXISTS (SELECT 1 
                     FROM PostHistory ph
                     JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
                     WHERE ph.PostId = fp.PostId AND pht.Name = 'Post Closed') THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM
    FilteredPosts fp
WHERE
    fp.Score > 0
ORDER BY
    fp.Score DESC NULLS LAST,
    fp.ViewCount DESC NULLS LAST;