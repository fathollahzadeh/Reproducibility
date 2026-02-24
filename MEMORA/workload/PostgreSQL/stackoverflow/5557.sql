WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        OwnerDisplayName,
        UpVotes,
        DownVotes
    FROM
        RankedPosts
    WHERE
        TagRank <= 5
)
SELECT
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    tp.OwnerDisplayName,
    tp.UpVotes,
    tp.DownVotes,
    ph.Comment AS HistoryComment,
    ph.CreationDate AS HistoryDate,
    pht.Name AS HistoryType
FROM
    TopPosts tp
LEFT JOIN
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY
    tp.Score DESC, tp.CreationDate DESC;