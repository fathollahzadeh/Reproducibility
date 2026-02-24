
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    ra.DisplayName,
    ra.QuestionCount,
    ra.TotalBounty,
    r.PostId,
    r.Title,
    r.CreationDate,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(cr.CloseReasons, 'Not Closed') AS CloseReasons
FROM 
    RecentActivity ra
JOIN 
    RankedPosts r ON ra.UserId = r.OwnerUserId AND r.rn = 1
LEFT JOIN 
    PostCounts pc ON r.PostId = pc.PostId
LEFT JOIN 
    ClosedReasons cr ON r.PostId = cr.PostId
WHERE 
    ra.QuestionCount > 5
ORDER BY 
    ra.TotalBounty DESC, 
    ra.QuestionCount DESC;
