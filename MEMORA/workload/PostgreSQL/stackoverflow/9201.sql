
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate > '2023-01-01'
), 
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
), 
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        pvc.UpVotes,
        pvc.DownVotes,
        (COALESCE(pvc.UpVotes, 0) - COALESCE(pvc.DownVotes, 0)) AS NetVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
)
SELECT 
    pd.Title, 
    pd.OwnerDisplayName, 
    pd.CreationDate, 
    pd.Score, 
    pd.ViewCount, 
    pd.UpVotes,
    pd.DownVotes,
    pd.NetVotes
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
