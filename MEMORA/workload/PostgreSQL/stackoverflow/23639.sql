
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id AND c.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'), 0) AS RecentCommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByCreation
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeCount,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),

AggregateStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        u.UserId,
        u.DisplayName,
        u.TotalBadgeCount,
        u.TotalVotes,
        u.PostCount,
        CASE 
            WHEN p.RecentCommentCount > 0 THEN 'Has Recent Comments'
            ELSE 'No Recent Comments'
        END AS CommentStatus
    FROM 
        RankedPosts p
    JOIN 
        UserStats u ON p.OwnerUserId = u.UserId
    WHERE 
        (u.TotalVotes > 10 OR u.TotalBadgeCount >= 2)
    ORDER BY 
        p.CreationDate DESC
    LIMIT 100
)

SELECT 
    a.PostId,
    a.Title,
    a.CreationDate,
    a.DisplayName,
    a.TotalBadgeCount,
    a.CommentStatus,
    LEAD(a.Title) OVER (ORDER BY a.CreationDate) AS NextPostTitle,
    DENSE_RANK() OVER (PARTITION BY a.Month ORDER BY a.CreationDate) AS PostRankInMonth
FROM 
    (SELECT 
        *,
        DATE_TRUNC('month', CreationDate) AS Month
    FROM 
        AggregateStats) a
WHERE 
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = a.UserId AND p.CreationDate < a.CreationDate) >= 2
OR 
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = a.UserId) = 0

ORDER BY 
    a.CreationDate DESC;
