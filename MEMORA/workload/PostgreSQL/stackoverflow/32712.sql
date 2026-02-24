WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.AcceptedAnswerId
),

UserAggregate AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= cast('2024-10-01' as date) - INTERVAL '90 days'
    GROUP BY 
        u.Id
)

SELECT 
    up.UserId,
    up.TotalUpVotes,
    up.TotalDownVotes,
    up.BadgeCount,
    up.PostCount,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.RankScore,
    COALESCE(cu.Username, 'No Comments') AS MostActiveCommenter,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    UserAggregate up
LEFT JOIN 
    RankedPosts rp ON up.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = rp.PostId
    )
LEFT JOIN 
    (SELECT 
        p.Id, 
        u.DisplayName AS Username, 
        COUNT(c.Id) AS CommentCount 
     FROM 
        Posts p
     JOIN 
        Comments c ON p.Id = c.PostId
     JOIN 
        Users u ON c.UserId = u.Id
     GROUP BY 
        p.Id, u.DisplayName
     ORDER BY 
        CommentCount DESC
     LIMIT 1) cu ON rp.PostId = cu.Id
WHERE 
    up.TotalUpVotes > 0
ORDER BY 
    up.TotalUpVotes DESC, rp.RankScore
LIMIT 50;