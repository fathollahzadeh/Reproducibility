
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RN
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT r.RelatedPostId) AS TotalRelatedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostLinks r ON p.Id = r.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasonStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS integer) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
PostsWithDetails AS (
    SELECT 
        p.*,
        u.DisplayName AS OwnerName,
        COALESCE(cr.CloseCount, 0) AS CloseCount,
        COALESCE(cr.CloseReasons, 'N/A') AS CloseReasons,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(cm.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        CloseReasonStats cr ON p.Id = cr.PostId
    LEFT JOIN 
        Comments cm ON p.Id = cm.PostId
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, p.CreationDate, 
        u.DisplayName, cr.CloseCount, cr.CloseReasons
)
SELECT 
    pd.Title,
    pd.Body,
    pd.OwnerName,
    pd.CreationDate,
    pd.CloseCount,
    pd.CloseReasons,
    us.Upvotes,
    us.Downvotes,
    us.TotalPosts,
    us.TotalRelatedPosts,
    ph.CreationDate AS HistoryDate,
    u.DisplayName AS EditedBy
FROM 
    PostsWithDetails pd
LEFT JOIN 
    RecursivePostHistory ph ON pd.Id = ph.PostId AND ph.RN = 1
JOIN 
    UserStats us ON pd.OwnerUserId = us.UserId
LEFT JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    pd.PostRank <= 3  
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;
