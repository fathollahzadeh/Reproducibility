WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopComments AS (
    SELECT
        c.PostId,
        c.Text AS Comment,
        c.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM
        Comments c
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '60 days' AND
        ph.PostHistoryTypeId IN (10, 11, 12)  
),
FinalResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.NetVotes,
        tc.Comment AS LatestComment,
        ph.UserId AS HistoryUserId,
        ph.HistoryType,
        ph.CreationDate AS HistoryDate
    FROM
        RankedPosts rp
    LEFT JOIN
        TopComments tc ON rp.PostId = tc.PostId AND tc.CommentRank = 1
    LEFT JOIN
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE
        rp.Rank <= 5 
)
SELECT
    fr.PostId,
    fr.Title,
    fr.PostDate,
    fr.Score,
    fr.ViewCount,
    fr.Author,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.NetVotes,
    fr.LatestComment,
    COALESCE(fr.HistoryType, 'None') AS HistoryType,
    COALESCE(fr.HistoryDate, NULL) AS HistoryDate
FROM
    FinalResults fr
ORDER BY
    fr.Score DESC
LIMIT 100;