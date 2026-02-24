WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment = CAST(c.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pp.UpVotes, 0) AS UpVotes,
        COALESCE(pp.DownVotes, 0) AS DownVotes,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        cp.CloseDate,
        cp.CloseReason,
        rp.OwnerDisplayName,
        CASE
            WHEN rp.ViewCount > 100 THEN 'Popular'
            WHEN rp.Rank = 1 THEN 'Most Recent'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pp ON rp.PostId = pp.PostId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    UpVotes,
    DownVotes,
    CommentCount,
    CloseDate,
    CloseReason,
    OwnerDisplayName,
    PostCategory,
    CASE 
        WHEN CloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FinalResults
WHERE 
    (UpVotes - DownVotes) > 5 
ORDER BY 
    Score DESC, CreationDate DESC;