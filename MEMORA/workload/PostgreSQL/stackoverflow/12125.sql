
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        MAX(p.LastActivityDate) AS LastActivityDate,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
Output AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.VoteCount,
        us.UserId,
        us.DisplayName AS UserName,
        us.Reputation,
        us.PostCount AS UserPostCount,
        us.TotalScore AS UserTotalScore,
        us.AvgViewCount AS UserAvgViewCount,
        ps.LastActivityDate
    FROM 
        PostStatistics ps
    JOIN 
        UserStatistics us ON ps.OwnerUserId = us.UserId
)
SELECT 
    *
FROM 
    Output
ORDER BY 
    CreationDate DESC;
