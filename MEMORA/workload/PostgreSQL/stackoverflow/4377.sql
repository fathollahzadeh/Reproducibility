WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalSummary AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        (COALESCE(pvs.UpVotes, 0) - COALESCE(pvs.DownVotes, 0)) AS NetVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteSummary pvs ON tp.PostId = pvs.PostId
)
SELECT 
    f.*,
    CASE 
        WHEN f.NetVotes > 10 THEN 'Highly Popular'
        WHEN f.NetVotes BETWEEN 1 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    FinalSummary f
ORDER BY 
    f.Score DESC, f.ViewCount DESC;