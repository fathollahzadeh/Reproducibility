
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 5
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    pvc.UpVotes,
    pvc.DownVotes,
    (pvc.UpVotes - pvc.DownVotes) AS NetVotes,
    (tp.ViewCount / NULLIF((pvc.UpVotes + pvc.DownVotes), 0)) AS EngagementRatio
FROM 
    TopPosts tp
JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY 
    EngagementRatio DESC;
