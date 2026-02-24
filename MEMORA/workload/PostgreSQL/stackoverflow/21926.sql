
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.Reputation
),
PostHistoryCounts AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 END) AS TitleEditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (6, 9) THEN 1 END) AS TagEditCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
CloseReasonSummary AS (
    SELECT
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INTEGER)
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ua.UserId,
    ua.Reputation,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes,
    phc.EditCount,
    phc.TitleEditCount,
    phc.TagEditCount,
    crs.CloseReasons
FROM
    RankedPosts rp
LEFT JOIN
    UserActivity ua ON ua.UserId IN (SELECT ParentId FROM Posts WHERE Id = rp.PostId AND ParentId IS NOT NULL)
LEFT JOIN
    PostHistoryCounts phc ON rp.PostId = phc.PostId
LEFT JOIN
    CloseReasonSummary crs ON rp.PostId = crs.PostId
WHERE
    rp.Rank <= 10
    AND (ua.Reputation > 100 OR ua.VoteCount > 50)
    AND COALESCE(crs.CloseReasons, '') NOT LIKE '%Duplicate%'
ORDER BY
    rp.Score DESC, ua.Reputation DESC
LIMIT 100;
