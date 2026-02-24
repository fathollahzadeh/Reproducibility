
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.Score IS NOT NULL 
        AND p.OwnerUserId IS NOT NULL 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
LatestPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
PostStatus AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastActionDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FinalAggregation AS (
    SELECT 
        lp.PostID,
        lp.Title,
        lp.CreationDate,
        lp.Score,
        lp.CommentCount,
        lp.UpVotes,
        lp.DownVotes,
        ps.HistoryTypes,
        ps.LastActionDate,
        ps.CloseReopenCount
    FROM 
        LatestPosts lp
    LEFT JOIN 
        PostStatus ps ON lp.PostID = ps.PostId
)
SELECT 
    fa.*, 
    CASE 
        WHEN fa.CloseReopenCount > 5 THEN 'Frequently Closed and Reopened'
        WHEN fa.UpVotes > fa.DownVotes THEN 'Generally Popular'
        ELSE 'Needs Attention'
    END AS PostAssessment,
    COALESCE(NULLIF(fa.Title, ''), 'No Title') AS SafeTitle
FROM 
    FinalAggregation fa
ORDER BY 
    fa.CreationDate DESC;
