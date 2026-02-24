WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM RankedPosts rp
    WHERE rp.Rank <= 5 
),
PostInteraction AS (
    SELECT
        fp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount 
    FROM FilteredPosts fp
    LEFT JOIN Comments c ON fp.PostId = c.PostId
    LEFT JOIN Votes v ON fp.PostId = v.PostId
    GROUP BY fp.PostId
)
SELECT
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Tags,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    (pi.UpVoteCount - pi.DownVoteCount) AS NetVotes
FROM FilteredPosts fp
JOIN PostInteraction pi ON fp.PostId = pi.PostId
ORDER BY fp.Score DESC, fp.CreationDate DESC;