WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*)
             FROM Votes v
             WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(
            (SELECT COUNT(*)
             FROM Votes v
             WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
),

PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),

ClosedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        hp.HistoryDate AS LastClosedDate,
        hp.PostHistoryTypeId AS LastAction
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCTE hp ON rp.PostId = hp.PostId AND hp.HistoryRank = 1
    WHERE 
        rp.Rank <= 5  
),

PostScoreReview AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.Owner,
        cp.CreationDate,
        cp.LastClosedDate,
        cp.LastAction,
        (cp.LastClosedDate IS NOT NULL) AS IsClosed,
        CASE 
            WHEN cp.LastAction = 10 THEN 'Closed' 
            WHEN cp.LastAction = 11 THEN 'Reopened' 
            ELSE 'N/A' 
        END AS CurrentState
    FROM 
        ClosedPosts cp
)

SELECT 
    psr.PostId,
    psr.Title,
    psr.Owner,
    psr.CreationDate,
    psr.LastClosedDate,
    psr.CurrentState,
    COALESCE(rp.UpVotes, 0) AS PostUpVotes,
    COALESCE(rp.DownVotes, 0) AS PostDownVotes,
    CASE 
        WHEN psr.IsClosed THEN 'This post is currently closed.'
        ELSE 'This post is open for interaction.'
    END AS InteractionStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = psr.PostId) AS CommentCount
FROM 
    PostScoreReview psr
LEFT JOIN 
    RankedPosts rp ON psr.PostId = rp.PostId
WHERE 
    psr.LastClosedDate IS NULL OR psr.LastClosedDate >= cast('2024-10-01' as date) - INTERVAL '1 week'
ORDER BY 
    psr.CreationDate DESC NULLS LAST;