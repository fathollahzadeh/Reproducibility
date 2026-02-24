WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
    WHERE
        p.PostTypeId = 1 AND p.Score IS NOT NULL
),
RecentVotes AS (
    SELECT
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM
        Votes V
    WHERE
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY
        V.PostId
)
SELECT
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.ViewCount,
    COALESCE(RV.UpVotes, 0) AS UpVotes,
    COALESCE(RV.DownVotes, 0) AS DownVotes,
    RP.CreationDate,
    CASE
        WHEN RP.PostRank = 1 THEN 'Top Post'
        ELSE NULL
    END AS PostStatus
FROM
    RankedPosts RP
LEFT JOIN
    RecentVotes RV ON RP.Id = RV.PostId
WHERE
    RP.ViewCount > 1000
ORDER BY
    RP.Score DESC, RP.CreationDate DESC
LIMIT 50;