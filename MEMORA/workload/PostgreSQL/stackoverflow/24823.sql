WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
PostVotes AS (
    SELECT
        v.PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        v.PostId, vt.Name
),
FilteredPostVotes AS (
    SELECT
        pv.PostId,
        SUM(CASE WHEN pv.VoteType = 'UpMod' THEN pv.VoteCount ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN pv.VoteType = 'DownMod' THEN pv.VoteCount ELSE 0 END) AS DownVotes
    FROM
        PostVotes pv
    GROUP BY
        pv.PostId
),
TopRatedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.TotalCount,
        COALESCE(fp.UpVotes, 0) AS UpVotes,
        COALESCE(fp.DownVotes, 0) AS DownVotes
    FROM
        RankedPosts rp
    LEFT JOIN
        FilteredPostVotes fp ON rp.PostId = fp.PostId
    WHERE
        rp.rn <= 5
)
SELECT
    trp.PostId,
    trp.Title,
    trp.TotalCount,
    trp.UpVotes,
    trp.DownVotes,
    CASE
        WHEN trp.UpVotes + trp.DownVotes > 0 THEN
            ROUND((trp.UpVotes * 1.0 / (trp.UpVotes + trp.DownVotes)) * 100, 2)
        ELSE 0
    END AS UpVotePercentage,
    CASE
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = trp.PostId AND ph.PostHistoryTypeId = 10) THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM
    TopRatedPosts trp
ORDER BY
    trp.UpVotes DESC NULLS LAST,
    trp.DownVotes ASC NULLS FIRST;