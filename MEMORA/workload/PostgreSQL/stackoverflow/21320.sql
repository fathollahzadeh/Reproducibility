
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,  
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(rp.Rank, 0) AS PostRank,
        COALESCE(cp.CloseReasons, 'Not Closed') AS PostCloseReasons,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    GROUP BY 
        p.Id, rp.Rank, cp.CloseReasons
)
SELECT 
    d.PostId,
    d.Title,
    d.PostRank,
    d.PostCloseReasons,
    d.CommentCount,
    d.LastCommentDate,
    u.DisplayName AS MostActiveUser,
    u.PostCount AS UserPostCount,
    u.UpVotesCount,
    u.TotalBounty
FROM 
    PostDetails d
JOIN 
    MostActiveUsers u ON d.PostRank = 1
WHERE 
    (d.LastCommentDate IS NULL OR d.LastCommentDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY')
ORDER BY 
    d.PostRank DESC, 
    d.CommentCount DESC, 
    d.LastCommentDate DESC
LIMIT 10;
