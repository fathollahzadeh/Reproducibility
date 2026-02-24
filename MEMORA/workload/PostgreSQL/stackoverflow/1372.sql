WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        crt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalPostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        cpd.CloseDate,
        cpd.CloseReason,
        CASE 
            WHEN cpd.CloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.Id = pvs.PostId
    LEFT JOIN 
        ClosedPostDetails cpd ON rp.Id = cpd.PostId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    CloseDate,
    CloseReason,
    PostStatus
FROM 
    FinalPostStats
ORDER BY 
    Score DESC, CreationDate ASC
LIMIT 10
OFFSET 0;