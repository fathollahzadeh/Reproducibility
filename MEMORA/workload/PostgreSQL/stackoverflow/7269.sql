
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= '2020-01-01' AND p.PostTypeId IN (1, 2) 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        TotalComments,
        UpVotes,
        DownVotes,
        Rank
    FROM
        RankedPosts
    WHERE
        Rank <= 5
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.TotalComments,
    tp.UpVotes,
    tp.DownVotes,
    CONCAT('Rank: ', CAST(tp.Rank AS VARCHAR)) AS PostRank,
    COALESCE((
        SELECT
            STRING_AGG(CONCAT(t.TagName, ' (' , t.Count , ')'), ', ')
        FROM
            Tags t
        WHERE
            t.ExcerptPostId = tp.PostId
    ), 'No Tags') AS AssociatedTags
FROM
    TopPosts tp
ORDER BY
    tp.Score DESC, tp.CreationDate DESC;
