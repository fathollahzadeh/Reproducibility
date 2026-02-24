WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RankDate
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score
    FROM
        RankedPosts rp
    WHERE
        rp.RankScore <= 10
),
PostVoteDetails AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),
PostCommentCount AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        c.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    COALESCE(pvd.UpVotes, 0) AS UpVotes,
    COALESCE(pvd.DownVotes, 0) AS DownVotes,
    COALESCE(pcc.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN COALESCE(pvd.UpVotes, 0) > COALESCE(pvd.DownVotes, 0) THEN 'Positive Feedback'
        WHEN COALESCE(pvd.UpVotes, 0) < COALESCE(pvd.DownVotes, 0) THEN 'Negative Feedback'
        ELSE 'No Feedback'
    END AS Feedback,
    CASE
        WHEN tp.ViewCount IS NULL THEN 'No views recorded'
        WHEN tp.ViewCount > 1000 THEN 'Highly Viewed'
        ELSE 'Moderately Viewed'
    END AS ViewClassification
FROM
    TopPosts tp
LEFT JOIN
    PostVoteDetails pvd ON tp.PostId = pvd.PostId
LEFT JOIN
    PostCommentCount pcc ON tp.PostId = pcc.PostId
WHERE
    EXISTS (
        SELECT 1
        FROM PostHistory ph
        WHERE ph.PostId = tp.PostId
        AND ph.PostHistoryTypeId IN (10, 11)
        AND ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 month'
    )
ORDER BY
    tp.ViewCount DESC, tp.Score DESC;