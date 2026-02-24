WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(uc.Reputation, 0) AS UserReputation
    FROM
        Posts p
    LEFT JOIN
        Users uc ON p.OwnerUserId = uc.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserReputation
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 5
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        c.PostId
),
PostVotes AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.UserReputation,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    (COALESCE(pv.UpVotes, 0) - COALESCE(pv.DownVotes, 0)) AS NetVotes,
    CASE
        WHEN COALESCE(pv.UpVotes, 0) = 0 THEN 'No Upvotes'
        WHEN COALESCE(pv.DownVotes, 0) = 0 THEN 'No Downvotes'
        ELSE 'Mixed Voting'
    END AS VoteStatus,
    CASE
        WHEN tp.Score > 100 THEN 'Hot'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Warm'
        ELSE 'Cold'
    END AS PostHotness
FROM
    TopPosts tp
LEFT JOIN
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN
    PostVotes pv ON tp.PostId = pv.PostId
ORDER BY
    tp.UserReputation DESC,
    tp.Score DESC;