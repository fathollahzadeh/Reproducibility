WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE 
                WHEN b.Class = 1 THEN 3
                WHEN b.Class = 2 THEN 2
                WHEN b.Class = 3 THEN 1
                ELSE 0
            END) AS TotalBadgePoints,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CommentCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
CriticalPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        COALESCE(cc.TotalComments, 0) AS CommentCount,
        CASE 
            WHEN cc.TotalComments > 5 THEN 'Active'
            ELSE 'Inactive'
        END AS EngagementStatus,
        ur.TotalBadgePoints
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        CommentCount cc ON rp.PostId = cc.PostId
    WHERE 
        rp.PostRank = 1 
        AND rp.Title NOT LIKE '%[closed]%'
        AND ur.TotalBadgePoints > 5
)
SELECT 
    cp.Title AS InterestingQuestion,
    u.DisplayName,
    u.Reputation,
    cp.CommentCount,
    cp.TotalBadgePoints,
    CASE 
        WHEN cp.CommentCount IS NULL THEN 'Comments not available'
        ELSE CAST(cp.CommentCount AS VARCHAR)
    END AS CommentCountString,
    CASE 
        WHEN cp.EngagementStatus = 'Active' THEN 'This question is actively engaged!'
        ELSE 'This question could use some interaction.'
    END AS EngagementMessage
FROM 
    CriticalPosts cp
JOIN 
    Users u ON cp.OwnerUserId = u.Id
ORDER BY 
    cp.TotalBadgePoints DESC, cp.CommentCount DESC
LIMIT 10;