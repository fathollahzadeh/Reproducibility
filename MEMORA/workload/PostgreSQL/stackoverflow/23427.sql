
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate > '2020-01-01'
),
PopularTags AS (
    SELECT
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        UNNEST(string_to_array(Tags, '><'))
    HAVING
        COUNT(*) >= 10
),
PostHistoryWithDetails AS (
    SELECT
        ph.PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRow
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        ph.CreationDate BETWEEN '2022-01-01' AND '2024-10-01 12:34:56'
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName,
    ph.HistoryType,
    ph.UserDisplayName AS Editor,
    ph.HistoryDate,
    ph.Comment,
    COALESCE((SELECT NULLIF(MIN(HistoryRow), 5) FROM PostHistoryWithDetails WHERE PostId = rp.PostId), 0) AS RelevantHistoryRow,
    CASE
        WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
        WHEN rp.DownVotes > rp.UpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    RankedPosts rp
LEFT JOIN
    PopularTags pt ON rp.Title ILIKE '%' || pt.TagName || '%'
LEFT JOIN
    PostHistoryWithDetails ph ON rp.PostId = ph.PostId
WHERE
    rp.RankByViews <= 10
ORDER BY
    rp.ViewCount DESC,
    rp.PostId;
