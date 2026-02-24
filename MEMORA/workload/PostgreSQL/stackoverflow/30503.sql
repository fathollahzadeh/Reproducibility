
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS Author, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= '2023-01-01'
),

PostClosureHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate, 
        cr.Name AS CloseReasonName, 
        ph.UserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),

PostVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    rp.Author, 
    ph.ClosedDate, 
    ph.CloseReasonName,
    COALESCE(v.VoteScore, 0) AS VoteScore,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews
FROM 
    RankedPosts rp
LEFT JOIN 
    PostClosureHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostVotes v ON rp.PostId = v.PostId
LEFT JOIN 
    TagStats ts ON ts.PostCount > 2
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
