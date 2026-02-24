WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - interval '1 year'
),

PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.RankScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 3 
),

PostVoteData AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)

SELECT 
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pd.TotalUpvotes,
    pd.TotalDownvotes,
    pp.CommentCount,
    COALESCE(cpr.ClosedReasons, 'Not Closed') AS ClosedReasons
FROM 
    PopularPosts pp
JOIN 
    PostVoteData pd ON pp.PostId = pd.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON pp.PostId = cpr.PostId
ORDER BY 
    pp.Score DESC, pp.CreationDate DESC
LIMIT 50;