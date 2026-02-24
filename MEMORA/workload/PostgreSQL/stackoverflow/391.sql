
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.Score) > 10
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1  
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.UserId,
        STRING_AGG(ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS int) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.UserId
)

SELECT 
    p.Title, 
    p.CreationDate,
    u.DisplayName AS Owner,
    COUNT(c.Id) AS CommentCount,
    COALESCE(b.BadgeName, 'No Badge') AS Badge,
    CASE 
        WHEN r.PostRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    ARRAY_AGG(DISTINCT cp.CloseReasons) AS ReasonsForClosure
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    UserWithBadges b ON u.Id = b.UserId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    r.PostRank <= 10
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName, b.BadgeName, r.PostRank
ORDER BY 
    p.CreationDate DESC;
