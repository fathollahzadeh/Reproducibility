WITH PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.Score
),
RankedPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        UpVotes,
        DownVotes,
        CommentCount,
        EditCount,
        RANK() OVER (ORDER BY Score DESC, UpVotes DESC) AS ScoreRank
    FROM
        PostMetrics
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.EditCount,
    CASE 
        WHEN rp.EditCount > 5 THEN 'Highly Edited'
        WHEN rp.EditCount BETWEEN 3 AND 5 THEN 'Moderately Edited'
        ELSE 'Slightly Edited'
    END AS EditStatus,
    CASE 
        WHEN rp.DownVotes > rp.UpVotes THEN 'More Downvotes than Upvotes'
        WHEN rp.UpVotes > rp.DownVotes THEN 'More Upvotes than Downvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM 
    RankedPosts rp
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    rp.Score DESC, rp.UpVotes DESC;