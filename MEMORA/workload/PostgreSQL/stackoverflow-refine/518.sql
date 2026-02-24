WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pht.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        (COALESCE(pvc.UpVotes, 0) - COALESCE(pvc.DownVotes, 0)) AS NetVotes,
        COUNT(rph.PostId) AS RecentHistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
    WHERE 
        rp.Rank <= 3
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, pvc.UpVotes, pvc.DownVotes
)
SELECT 
    *,
    CASE 
        WHEN RecentHistoryCount > 0 THEN 'Has Recent Changes' 
        ELSE 'No Recent Changes' 
    END AS ChangeStatus
FROM 
    FinalResults
ORDER BY 
    NetVotes DESC, Score DESC, ViewCount DESC;