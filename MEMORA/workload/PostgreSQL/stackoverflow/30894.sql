
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS EditComments,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.DisplayName AS OwnerName,
        COALESCE(phe.EditComments, 'No edits') AS EditDetails,
        COALESCE(phe.EditCount, 0) AS TotalEdits
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistorySummary phe ON rp.PostId = phe.PostId
    WHERE 
        rp.Score > 100
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.OwnerName,
    hsp.EditDetails,
    hsp.TotalEdits,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    Votes v ON hsp.PostId = v.PostId
GROUP BY 
    hsp.PostId, hsp.Title, hsp.CreationDate, hsp.Score, hsp.ViewCount, hsp.OwnerName, hsp.EditDetails, hsp.TotalEdits
HAVING 
    COUNT(v.Id) > 5  
ORDER BY 
    hsp.Score DESC, 
    hsp.CreationDate DESC;
