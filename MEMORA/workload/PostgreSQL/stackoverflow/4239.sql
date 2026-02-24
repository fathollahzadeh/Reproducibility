
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        pvc.UpVotes,
        pvc.DownVotes,
        CASE 
            WHEN pvc.UpVotes + pvc.DownVotes > 0 
            THEN (CAST(pvc.UpVotes AS FLOAT) / (pvc.UpVotes + pvc.DownVotes)) * 100 
            ELSE 0 
        END AS UpVotePercentage
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.Id = pvc.PostId
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    pp.UpVotes,
    pp.DownVotes,
    pp.UpVotePercentage,
    COALESCE(ph.Comment, 'No comments') AS LastEditComment
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistory ph ON pp.Id = ph.PostId AND ph.PostHistoryTypeId = 24
ORDER BY 
    pp.ViewCount DESC
LIMIT 20;
