
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, U.DisplayName
),

DetailedPosts AS (
    SELECT
        rp.*,
        CASE 
            WHEN (rp.UpVotes + rp.DownVotes) = 0 THEN 0
            ELSE ROUND((CAST(rp.UpVotes AS NUMERIC) / NULLIF(rp.UpVotes + rp.DownVotes, 0)) * 100, 2)
        END AS UpVotePercentage
    FROM
        RankedPosts rp
)

SELECT
    dp.PostId,
    dp.Title,
    dp.CreationDate,
    dp.Score,
    dp.ViewCount,
    dp.OwnerDisplayName,
    dp.UpVotes,
    dp.DownVotes,
    dp.UpVotePercentage,
    pht.Name AS PostHistoryType,
    COALESCE(ph.Comment, 'No comments') AS UserComment
FROM
    DetailedPosts dp
LEFT JOIN
    (SELECT 
         PostId, 
         MAX(CreationDate) AS LatestChangeDate
     FROM 
         PostHistory 
     GROUP BY 
         PostId
    ) recent_ph ON dp.PostId = recent_ph.PostId
LEFT JOIN 
    PostHistory ph ON recent_ph.PostId = ph.PostId AND recent_ph.LatestChangeDate = ph.CreationDate
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE
    dp.rn = 1
ORDER BY
    dp.UpVotePercentage DESC,
    dp.Score DESC;
